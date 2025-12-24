local Utils = require(game.ReplicatedStorage:WaitForChild("Utils"))
local Items = require(game.ReplicatedStorage:WaitForChild("Items"))
local DropHandler = require(game.ServerScriptService:WaitForChild("DropHandler"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local ItemModels = ServerStorage:WaitForChild("ItemModels")
local bagUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("bagUpdate")
local invUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("invUpdate")
local equipmentUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("equipmentUpdate")
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
	self.inventory = {
		bag = {},
		items = {},
		equipment = {
			hotbar = {},
		},
		cursorItem = { value = nil, key = "cursorItem" },
	}
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

	self:giveItem("admin_pick", 2)
	self:giveItem("rookie_pickaxe", 2)
	self:giveItem("stackableTestItem", 3)

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

	if not slotItem and not cursorItem.value then
		return
	end

	local slotContainer = customPlayer:getContainerFromId(slotType)

	if not cursorItem.value then
		--"Pick up" item
		cursorItem.value = slotItem
		customPlayer:removeItem(slotContainer, slotNum, slotItem.amount, false)
	elseif not slotItem and cursorItem.value then
		--Set item
		customPlayer:addItemTo(slotType, cursorItem.value, slotNum, false)
		cursorItem.value = nil
	elseif slotItem and cursorItem.value then
		--Swap
		local cachedItem = cursorItem.value
		cursorItem.value = slotItem
		customPlayer:removeItem(slotContainer, slotNum, slotItem.amount, false) --remove is required, because addItemTo doesn't override it just adds for items inventory
		customPlayer:addItemTo(slotType, cachedItem, slotNum, false)
	end

	cursorUpdate:FireClient(player, customPlayer.inventory.cursorItem.value)
	invUpdate:FireClient(player, customPlayer.inventory.items)
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

dropItem.OnServerEvent:Connect(function(player, item)
	local customPlayer = CustomPlayers.getPlayer(player)
	if not customPlayer then
		return
	end
	if not customPlayer:hasItem(item) then
		warn(
			"[CustomPlayers] Client tried dropping item they don't have. Player: " .. tostring(player.UserId) .. ".",
			debug.traceback()
		)
		return
	end

	if not item.amount then
		item.amount = 1
	end

	--prioritize cursor item
	if Utils.matchTables(item, customPlayer.inventory.cursorItem.value) then
		customPlayer.inventory.cursorItem.value = nil
		cursorUpdate:FireClient(player, customPlayer.inventory.cursorItem.value)
	else
		customPlayer:removeItem(item)
	end
	lootNotification:FireClient(player, item, -item.amount)

	--drop logic
	local character = player.Character
	if not character then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	DropHandler.dropItem(hrp, item)
end)

equipHotbarSlot.OnServerEvent:Connect(function(player, slotNum)
	local customPlayer = CustomPlayers.getPlayer(player)
	if not customPlayer then
		return
	end

	customPlayer:equipHotbarSlot(slotNum)
end)

function customPlayer:getContainerFromId(id: string)
	return Utils.findKeyInNestedTable(self.inventory, id)
end

function customPlayer:addItemTo(containerId: string, item: table, slotNum: number, updateClient: boolean)
	if not Utils.checkValue(containerId, "string", "[CustomPlayers]") then
		return
	end

	if not Utils.checkValue(item, "table", "[CustomPlayers]") then
		return
	end

	if updateClient == nil then
		updateClient = true
	end

	local container = self:getContainerFromId(containerId)

	if not container then
		warn("[CustomPlayers] No container found with id: " .. tostring(containerId))
		return
	end

	if containerId == "cursorItem" then
		container.value = item
	elseif containerId == "items" then
		self:giveItem(item, nil, updateClient)
	else
		container[tostring(slotNum)] = item
		--[[update hotbar
		if containerId == "hotbar" then
			
		end]]
	end

	if not updateClient then
		return
	end
	invUpdate:FireClient(self.player, self.inventory.items)
	self:updateEquipment()
	cursorUpdate:FireClient(self.player, self.inventory.cursorItem.value)
end

function customPlayer:updateEquipment()
	self:equipHotbarSlot(self.equipedHotbarSlot)
	equipmentUpdate:FireClient(self.player, self.inventory.equipment)
end

function customPlayer:equipHotbarSlot(slotNum: number, waitForChar: boolean)
	if waitForChar == nil then
		waitForChar = false
	end

	self.equipedHotbarSlot = slotNum

	local item = self.inventory.equipment.hotbar[tostring(slotNum)]

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
function customPlayer:giveItem(id: string, amount: number, updateClient: boolean)
	if updateClient == nil then
		updateClient = true
	end

	-- Assign item data according to args passed
	local item
	if typeof(id) == "string" then
		item = Items.getItemById(id)
		item.amount = amount
	else
		item = id
		amount = item.amount
	end

	if not item then
		warn(
			"[CustomPlayers] Error"
				.. "No item for id: "
				.. tostring(id)
				.. ". while trying to give an item to player "
				.. tostring(self.player.UserId),
			debug.traceback()
		)
		return
	end

	--Depending on if the item is a material or not, it will be stored in a different table and handeld differently.
	if not Items.materials[item.id] then
		if #self.inventory.items + item.amount ~= self.stats.invSlots then
			--check if item stacks
			if item.stackable then
				--find item in itemsInv
				local found = false
				for invId, invItem in pairs(self.inventory.items) do
					if invId == item.id then
						invItem.amount += item.amount --add to existing value
						found = true
						break
					end
				end
				--if didn't already exist add
				if not found then
					item.amount = item.amount
					table.insert(self.inventory.items, item)
				end
			else
				--if doesnt stack add one by one
				for i = 1, item.amount do
					local singleAmountItem = table.clone(item)
					singleAmountItem.amount = 1
					table.insert(self.inventory.items, singleAmountItem)
				end
			end
		else
			--drop
		end
		if updateClient then
			invUpdate:FireClient(self.player, self.inventory.items)
		end
	else
		if self.inventory.bag[item.id] then
			self.inventory.bag[item.id].amount += item.amount
		else
			self.inventory.bag[item.id] = item
		end
		if updateClient then
			bagUpdate:FireClient(self.player, self.inventory.bag)
		end
	end

	if updateClient then
		lootNotification:FireClient(self.player, item, amount)
	end
end

--- Removes an item from the player's inventory.
--- @overload fun(item: table)
function customPlayer:removeItem(origin: table, pos: number, amount: number, updateClient: boolean)
	if not self:hasItem(origin[tostring(pos)], amount) and not self:hasItem(origin[pos], amount) then
		warn("[CustomPlayers] Tried removing item that player doesn't have.", debug.traceback())
		return
	end

	if updateClient == nil then
		updateClient = true
	end

	if not origin.rarity then
		-- Case 1: removeItem(origin, pos)
		if Utils.isArray(origin) then
			if origin[pos].amount <= amount then
				table.remove(origin, pos)
			else
				origin[pos].amount -= amount
			end
		else
			if origin[tostring(pos)].amount <= amount then
				origin[tostring(pos)] = nil
			else
				origin[tostring(pos)].amount -= amount
			end
		end

		if not updateClient then
			return
		end
		invUpdate:FireClient(self.player, self.inventory.items)
		self:updateEquipment()
		cursorUpdate:FireClient(self.player, self.inventory.cursorItem.value)
	else
		-- Case 2: removeItem(item)
		local item = origin
		local pos, origin = self:hasItem(item)
		if not pos then
			warn(
				"[CustomPlayers] Client tried removing item he does not poses. Player: " .. tostring(self.player.UserId),
				debug.traceback()
			)
			return
		end
		self:removeItem(origin, pos, item.amount, updateClient)
	end
end

--- Finds item in inventory. If amount is given only return true if that amount is of items is present.
--- @overload fun(item: table)
function customPlayer:hasItem(item: table, amount: number)
	if not item then
		return false
	end

	for k, v in pairs(self.inventory) do
		if v.id == item.id and v.amount >= amount then
			return true
		end

		-- Recurse into nested tables
		if typeof(v) == "table" then
			local found = Utils.findValueInNestedTable(v, item)
			if found ~= nil then
				return found --true
			end
		end
	end

	return false
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
	self.customPlayer = customPlayer
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
	self.customPlayer.weakSpot = nil
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
