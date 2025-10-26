local Utils = require(game.ReplicatedStorage:WaitForChild("Utils"))
local Items = require(game.ReplicatedStorage:WaitForChild("Items"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HTTPService = game:GetService("HttpService")

local bagUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("bagUpdate")
local invUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("invUpdate")
local equipmentUpdate = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("equipmentUpdate")
local lootNotification = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("lootNotification")
local equipedHotbar = game.ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("equipedHotbar")
local reqStats = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("reqStats")

local CustomPlayers = {}
local customPlayer = {}

customPlayer.__index = customPlayer

function CustomPlayers.newPlayer(player: Player)
	
	if not Utils.checkValue(player, "Player", "[CustomPlayers]") then return end
	
	
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
			hotbar = {}
		}
	}
	self.weakSpot = nil
	self.result = nil
	self.mouseRay = nil
	self.miningData = {
		time = 0,
		tool = nil
	}
	
	local MouseRayRequest = game.ReplicatedStorage:WaitForChild("MouseRayRequest")
	MouseRayRequest.OnServerEvent:Connect(function(player, mouseRay)
		if player == self.player then
			self.mouseRay = mouseRay
		end
	end)
	
	CustomPlayers[player.UserId] = self
	
	self:giveItem("admin_pick")
	self:giveItem("rookie_pickaxe")
	return self
end

function CustomPlayers.getPlayer(player: Player)
	if not Utils.checkValue(player, "Player", "[CustomPlayers]") then
		return
	end
	
	return CustomPlayers[player.UserId]
end


reqStats.OnServerEvent:Connect(function(player)
	local customPlayer = CustomPlayers.getPlayer(player)
	if not customPlayer then
		warn("[CustomPlayers] Client requested invalid custom player. Player: "..tostring(player.UserId))
		return
	end
	
	reqStats:FireClient(player, customPlayer.stats)
end)

equipedHotbar.OnServerEvent:Connect(function(player, item, slotNum)
	local customPlayer = CustomPlayers.getPlayer(player)
	if not customPlayer then
		warn("[CustomPlayers] Client requested invalid custom player. Player: "..tostring(player.UserId))
		return
	end
	
	customPlayer:setHotbarSlot(item, slotNum)
end)

function customPlayer:setHotbarSlot(item, slotNum)
	if item and typeof(item) ~= "table" then
		warn("[CustomPlayers] "..typeof(item).." is not a valid type for item")
		return
	end
	if not Utils.checkValue(slotNum, "number", "[CustomPlayers]") then return end
	
	local pos, origin = self:hasItem(item)
	if not pos then
		warn("[CustomPlayers] Client tried equiping item he does not poses. Player: "..tostring(self.player.UserId))
		return	
	end


	--table.insert(self.inventory.equipment.hotbar, item)
	if not self.inventory.equipment.hotbar[slotNum] then
		--removes Item from previous slot
		if Utils.isArray(origin) then 
			table.remove(origin, pos)
		else
			origin[pos] = nil
		end
		
		self.inventory.equipment.hotbar[slotNum] = item
	else

	end


	invUpdate:FireClient(self.player, self.inventory.items)
	local equipDataJSON = HTTPService:JSONEncode(self.inventory.equipment)
	
	equipmentUpdate:FireClient(self.player, self.inventory.equipment)
	--
end

--Unelegant aproach due to being hardcoded!!! Might want to change later.
function customPlayer:hasItem(item)
	for i = 1, #self.inventory.items do
		if Utils.matchTables(self.inventory.items[i], item) then
			return i, self.inventory.items
		end
	end
	
	for i, hotbarItem in pairs(self.inventory.equipment.hotbar) do
		if Utils.matchTables(hotbarItem, item) then
			return i, self.inventory.equipment.hotbar
		end
	end
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

function customPlayer:giveItem(id: string, amount: number)
	if not Utils.checkValue(id, "string", "[CustomPlayers]") then return end
	
	if not amount  then
		amount = 1
	end
	
	local item = Items.getItemById(id)

	if not item then
		warn("[CustomPlayers] Error".."No item for id: "..tostring(id)..". while trying to give an item to player "..tostring(self.player.UserId))
		return
	end
	
	--Depending on if the item is a material or not, it will be stored in a different table and handeld differently.
	if not Items.materials[id] then
		for i = 1, amount do
			if #self.inventory.items ~= self.stats.invSlots then
				item.id = id
				table.insert(self.inventory.items, item)
				invUpdate:FireClient(self.player, self.inventory.items)
			end
		end
		
	else
		if self.inventory.bag[id] then
			self.inventory.bag[id].amount += amount
		else
			self.inventory.bag[id] = item
		end
		
		bagUpdate:FireClient(self.player, self.inventory.bag)
	end
	
	lootNotification:FireClient(self.player, id, item, amount)
end




--WEAK SPOT

local weakSpot = {}

weakSpot.__index = weakSpot

function CustomPlayers.newWeakSpot(Node: Node, customPlayer, result: RaycastResult, hitResult: RaycastResult)
	if not Utils.checkValue(result, "RaycastResult", "[MiningHandler]") then return end

	local self =  {}
	setmetatable(self, weakSpot)

	self.Position = result.Position
	self.Parent = Node.instance
	self.Name = "weakSpot"
	self.Size = Vector3.new(1,1,1)
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
	local lineAnim = game.ReplicatedStorage:FindFirstChild("Mining"):FindFirstChild("weak spot"):FindFirstChild("lineAnimation")
	lineAnim:FireClient(customPlayer.player, hitResult.Position, customPlayer.weakSpot.Position)
end

function weakSpot:deleteWeakSpot()
	self.raycastCopy:Destroy()
	local deleteWeakSpot = game.ReplicatedStorage:WaitForChild("Mining"):WaitForChild("weak spot"):WaitForChild("deleteWeakSpot")
	deleteWeakSpot:FireClient(self.Player)
	self.customPlayer.weakSpot = nil
end

function weakSpot:createRaycastCopy()
	local copy = Instance.new("Part")
	copy.Size = Vector3.new(1,1,1)
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
