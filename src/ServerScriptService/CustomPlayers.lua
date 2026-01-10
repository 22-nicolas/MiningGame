local Utils = require(game.ReplicatedStorage:WaitForChild("Utils"))
local Items = require(game.ReplicatedStorage:WaitForChild("Items"))
local DropHandler = require(game.ServerScriptService:WaitForChild("DropHandler"))
local StorageHandler = require(game.ServerScriptService:WaitForChild("StorageHandler"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local ItemModels = ServerStorage:WaitForChild("ItemModels")
local bagUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("bagUpdate")
local invUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("invUpdate")
local hotbarUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("hotbarUpdate")
local cursorUpdate = game.ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("cursorUpdate")
local cancelCursorItem = game.ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("cancelCursorItem")
local lootNotification = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("lootNotification")
local slotClick = game.ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("slotClick")
local dropItem = game.ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("dropItem")
local equipHotbarSlot = game.ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("equipHotbarSlot")
local reqStats = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("reqStats")

local CustomPlayers = {}
local customPlayer = {}

customPlayer.__index = customPlayer

function CustomPlayers.newPlayer(player: Player)
	if not Utils.checkValue(player, "Player", "[CustomPlayers]") then
		return
	end

	local self = {}
	setmetatable(self, customPlayer)

	self.player = player
	self.stats = {}
	self.stats.miningXP = 0
	self.stats.fortune = 0
	self.stats.miningSpeed = 0
	self.stats.weakSpotBonusMultiplier = 1
	self.stats.invSlots = 35
	self.stats.HotbarSize = 6
	self.inventory = StorageHandler.new()
	self.inventory:newContainer("bag", nil, StorageHandler.ContainerTypes.array)
	self.inventory:newContainer("items", nil, StorageHandler.ContainerTypes.array)
	self.inventory:newContainer("hotbar", self.stats.HotbarSize, StorageHandler.ContainerTypes.dictionary)
	self.inventory:newContainer("cursorItem", 1)
	--[[
	self.inventory = {
		bag = {},
		items = {},
		equipment = {
			hotbar = {},
		},
		cursorItem = { value = nil, key = "cursorItem" },
	}]]
	self.weakSpot = nil
	self.result = nil
	self.mouseRay = nil
	self.miningData = {
		time = 0,
		tool = nil,
	}

	local MouseRayRequest = game.ReplicatedStorage:WaitForChild("MouseRayRequest")
	MouseRayRequest.OnServerEvent:Connect(function(player, mouseRay)
		if player == self.player then
			self.mouseRay = mouseRay
		end
	end)

	CustomPlayers[player.UserId] = self

	self:giveItem("admin_pick", 2, true)
	self:giveItem("rookie_pickaxe", 2, true)
	self:giveItem("stackableTestItem", 3, true)

	self:equipHotbarSlot(1, true)
	return self
end

function CustomPlayers.getPlayer(player: Player)
	if not Utils.checkValue(player, "Player", "[CustomPlayers]") then
		return
	end

	local customPlayer = CustomPlayers[player.UserId]
	if not customPlayer then
		warn("[CustomPlayers] Client requested invalid custom player. Player: " .. tostring(player.UserId))
		return
	end
	return customPlayer
end

reqStats.OnServerEvent:Connect(function(player)
	local customPlayer = CustomPlayers.getPlayer(player)
	if not customPlayer then
		return
	end

	reqStats:FireClient(player, customPlayer.stats)
end)

slotClick.OnServerEvent:Connect(function(player, slotItem, slotType, slotNum)
	local customPlayer = CustomPlayers.getPlayer(player)
	if not customPlayer then
		return
	end

	local cursorItem = customPlayer.inventory.cursorItem

	if not slotItem and not cursorItem.contents then
		return
	end
	local slotContainer = customPlayer.inventory[slotType] --customPlayer:getContainerFromId(slotType)
	if not cursorItem.contents then
		--"Pick up" item
		StorageHandler.transferItem(slotContainer, slotNum, cursorItem, 1)
	elseif not slotItem and cursorItem.contents then
		--Set item
		StorageHandler.transferItem(cursorItem, 1, slotContainer, slotNum, cursorItem.contents.amount)
	elseif slotItem and cursorItem.contents then
		--Swap
		StorageHandler.swapItems(slotContainer, slotNum, cursorItem, 1)
	end

	cursorUpdate:FireClient(player, customPlayer.inventory.cursorItem.contents)
	invUpdate:FireClient(player, customPlayer.inventory.items.contents)
	customPlayer:updateEquipment()
end)

cancelCursorItem.OnServerEvent:Connect(function(player)
	local customPlayer = CustomPlayers.getPlayer(player)
	if not customPlayer then
		return
	end

	local cursorItem = customPlayer.inventory.cursorItem

	if not cursorItem.value then
		return
	end

	customPlayer:giveItem(cursorItem.value)
	cursorItem.value = nil

	cursorUpdate:FireClient(player, cursorItem.value)
end)

dropItem.OnServerEvent:Connect(function(player, originKey, pos, amount)
	local customPlayer = CustomPlayers.getPlayer(player)
	if not customPlayer then
		return
	end

	local item = customPlayer.inventory[originKey]:get(pos)
	if not item then
		return
	end

	local itemToDrop = table.clone(item)
	itemToDrop.amount = amount

	--remove item data from inventory
	customPlayer:removeItemAt(originKey, pos, amount, true)
	customPlayer:updateInventoryUI()

	--loot drop logic
	local character = player.Character
	if not character then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	DropHandler.dropItem(hrp, itemToDrop)
end)

equipHotbarSlot.OnServerEvent:Connect(function(player, slotNum)
	local customPlayer = CustomPlayers.getPlayer(player)
	if not customPlayer then
		return
	end

	customPlayer:equipHotbarSlot(slotNum)
end)

function customPlayer:updateInventoryUI()
	invUpdate:FireClient(self.player, self.inventory.items.contents)
	self:updateEquipment()
	cursorUpdate:FireClient(self.player, self.inventory.cursorItem.contents)
end

function customPlayer:updateEquipment()
	self:equipHotbarSlot(self.equipedHotbarSlot)
	hotbarUpdate:FireClient(self.player, self.inventory.hotbar.contents)
end

function customPlayer:equipHotbarSlot(slotNum: number, waitForChar: boolean)
	if waitForChar == nil then
		waitForChar = false
	end

	self.equipedHotbarSlot = slotNum

	local item = self.inventory.hotbar.contents[tostring(slotNum)]

	--check if item changed
	if Utils.matchTables(item, self.lastEquipedItem) or self.lastEquipedItem == item then
		return
	end

	--store item
	self.lastEquipedItem = item

	-- remove prevItem
	local character = self.player.Character
	if not character and waitForChar then
		character = workspace:WaitForChild(self.player.Name)
	elseif not character then
		return
	end
	local prevItem = self.player.Character:FindFirstChildOfClass("Tool")
	if prevItem then
		prevItem:Destroy()
	end

	-- if slot has item then equip
	if item then
		local itemModel = Utils.findKeyInNestedTable(ItemModels, item.id)
		if not itemModel then
			warn("[CustomPlayers] No item model found for item: " .. tostring(item.id), debug.traceback())
			return
		end

		itemModel = itemModel:Clone()
		itemModel.Name = item.displayName
		itemModel:SetAttribute("id", item.id)

		local MiningToolScript = ServerScriptService.MiningHandler.MiningToolScript:Clone()
		MiningToolScript.Parent = itemModel

		itemModel.Parent = self.player.Character
	end
end

--- Gives the specified item to the player.
--- @overload fun(item: table)
--- @overload fun(item: table, fireLootNotification: boolean)
--- @overload fun(id: string, amount: number)
function customPlayer:giveItem(id: string, amount: number, fireLootNotification: boolean)
	local item
	if typeof(id) == "string" then
		item = Items.getItemById(id)
	else
		item = id
	end

	if typeof(amount) == "boolean" then
		fireLootNotification = amount
		amount = nil
	end

	if not amount then
		amount = item.amount
	end

	self.inventory.items:addItem(item, amount)

	self:updateInventoryUI()

	if not fireLootNotification then
		return
	end

	lootNotification:FireClient(self.player, item, amount)
end

--- @class RemoveItemOptions
--- @field force boolean
--- @field fireLootNotification boolean

--- Removes the given item from the player's inventory.
--- @overload fun(item: table, amount?: number, options?: RemoveItemOptions)
--- @param options? RemoveItemOptions
--- @param amount? number
function customPlayer:removeItem(itemId: string, amount: number, options: table)
	options = options or {}
	if not Utils.checkValue(options, "table", "[CustomPlayers]") then
		return
	end
	local force = options.force
	local fireLootNotification = options.fireLootNotification

	self.inventory:removeItem(itemId, amount, force)

	self:updateInventoryUI()

	if not fireLootNotification then
		return
	end

	lootNotification:FireClient(self.player, itemId, -amount)
end

--- Removes an item from the player's inventory at the given position.
---@param fireLootNotification? boolean
function customPlayer:removeItemAt(origin: string, pos: number, amount: number, fireLootNotification: boolean)
	local item = self.inventory[origin]:get(pos)
	self.inventory[origin]:removeItemAt(pos, amount)

	self:updateInventoryUI()

	if not fireLootNotification then
		return
	end

	lootNotification:FireClient(self.player, item, -amount)
end

--- Finds item in inventory. If amount is given only return true if that amount is of items is present.
--- @overload fun(itemId: table)
function customPlayer:hasItem(item: table)
	return self.inventory:containsItem(item)
end

function customPlayer:getMouseRay()
	return self.mouseRay
end

function customPlayer:addXP(amount: number)
	if not Utils.checkValue(amount, "number", "[CustomPlayers]") then
		return
	end

	self.stats.miningXP += amount
end

--WEAK SPOT

local weakSpot = {}

weakSpot.__index = weakSpot

function CustomPlayers.newWeakSpot(Node: Node, customPlayer, result: RaycastResult, hitResult: RaycastResult)
	if not Utils.checkValue(result, "RaycastResult", "[MiningHandler]") then
		return
	end

	local self = {}
	setmetatable(self, weakSpot)

	self.Position = result.Position
	self.Parent = Node.instance
	self.Name = "weakSpot"
	self.Size = Vector3.new(1, 1, 1)
	self.BrickColor = BrickColor.new("Cyan")
	self.Transparency = 0.5
	self.Shape = Enum.PartType.Ball
	self.Anchored = true
	self.CanCollide = false
	self.Player = customPlayer.player
	self.raycastCopy = self:createRaycastCopy()
	self.Material = Enum.Material.Plastic

	local createWeakSpot = game.ReplicatedStorage.Mining:FindFirstChild("weak spot").createWeakSpot
	createWeakSpot:FireClient(self.Player, self)

	customPlayer.weakSpot = self
	customPlayer.result = nil

	--ANIMATION
	local lineAnim =
		game.ReplicatedStorage:FindFirstChild("Mining"):FindFirstChild("weak spot"):FindFirstChild("lineAnimation")
	lineAnim:FireClient(customPlayer.player, hitResult.Position, customPlayer.weakSpot.Position)
end

function weakSpot:deleteWeakSpot()
	self.raycastCopy:Destroy()
	local deleteWeakSpot =
		game.ReplicatedStorage:WaitForChild("Mining"):WaitForChild("weak spot"):WaitForChild("deleteWeakSpot")
	deleteWeakSpot:FireClient(self.Player)

	local customPlayer = CustomPlayers.getPlayer(self.Player)
	customPlayer.weakSpot = nil
end

function weakSpot:createRaycastCopy()
	local copy = Instance.new("Part")
	copy.Size = Vector3.new(1, 1, 1)
	copy.Shape = Enum.PartType.Ball
	copy.Anchored = true
	copy.CanCollide = false
	copy.CanQuery = true
	copy.Transparency = 1
	copy.Position = self.Position
	copy.Parent = self.Parent
	copy.Name = "raycastCopy"
	return copy
end

return CustomPlayers
