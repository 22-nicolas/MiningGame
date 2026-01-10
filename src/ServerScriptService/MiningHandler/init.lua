local Utils = require(game.ReplicatedStorage:WaitForChild("Utils"))
local Items = require(game.ReplicatedStorage:WaitForChild("Items"))
local RunService = game:GetService("RunService")
local stopedMining = game.ReplicatedStorage:WaitForChild("Mining"):WaitForChild("StopMining")
local CustomPlayers = require(game.ServerScriptService:WaitForChild("CustomPlayers"))

local MiningHandler = {
	rarity_influence = 1,
	baseDrops = 1,
	plusDropsPerFortune = 1,
	weakSpotBonus = 10,

	nodes = {},

	--ATRIBUTES FOR ORES
	coal = {
		regenTime = 10, --10s
		regenRate = 2, --2s
		maxHealth = 10,
		toughness = 1,
		miningDifficulty = 0.05,
		xp = 1.5,
		dropTable = {
			stone = 4,
			coal = 1,
		},
	},
}

local Node = {}

Node.__index = Node

function MiningHandler.newNode(ResourceNode: Part)
	--ERROR CATHING/HANDLING
	if not Utils.checkValue(ResourceNode, "Part", "[MiningHandler]", true) then
		return
	end

	local self = {}
	setmetatable(self, Node)

	local ore = ResourceNode.Parent:GetAttribute("ore")

	--create random ID
	local id
	while true do
		id = tostring(math.random())
		id = string.sub(id, 3, #id)
		if not MiningHandler.nodes[id] then
			break
		end
	end

	--ATTRIBUTES
	self.instance = ResourceNode
	self.oreData = MiningHandler[ore]
	self.maxHealth = self.oreData.maxHealth
	self.health = self.maxHealth
	self.miningPlayers = {}
	self.time = 0
	self.id = id

	MiningHandler.nodes[id] = self
	return self
end

function MiningHandler.getNode(block: Part)
	if not Utils.checkValue(block, "Part", "[MiningHandler]", true) then
		return
	end
	for id, node in pairs(MiningHandler.nodes) do
		if node.instance == block then
			return node
		end
	end
end

function MiningHandler.centralizedMiningLoop(deltaTime)
	for id, node in pairs(MiningHandler.nodes) do
		if Utils.tableLength(node.miningPlayers) ~= 0 then
			node.time = 0
			for i = 1, #node.miningPlayers do
				node:mine(node.miningPlayers[i], deltaTime)
			end
		else
			node:regen(deltaTime)
		end
		--print("health: "..tostring(node.health).." deltaTime: "..tostring(node.time))
	end
end

RunService.Heartbeat:Connect(MiningHandler.centralizedMiningLoop)

function Node:addMiningPlayer(player: Player, tool: Tool, wasMining: boolean)
	--ERROR CATHING/HANDLING
	if not Utils.checkValue(player, "Player", "[MiningHandler]", true) then
		return
	end
	if not Utils.checkValue(tool, "Tool", "[MiningHandler]", true) then
		return
	end

	if not wasMining then
		wasMining = false
	end

	local customPlayer = CustomPlayers.getPlayer(player)

	local toolId = tool:GetAttribute("id")
	local toolExists = Items.miningTools[toolId] ~= nil

	if not toolExists then
		warn("[MiningHandler] Tool: " .. Utils.getPath(tool) .. " is not a valid mining tool")
		return
	end

	local toolData = Items.miningTools[toolId]
	toolData.id = toolId

	for key, value in pairs(toolData) do
		if value == nil then
			warn("[MiningHandler] Tool attribute '" .. key .. "' is nil for tool: " .. Utils.getPath(tool))
			return
		end
	end

	customPlayer.miningData = {
		time = 0,
		tool = tool,
		wasMining = wasMining,
	}

	table.insert(self.miningPlayers, player)
end

function Node:removeMiningPlayer(player: Player)
	if not Utils.checkValue(player, "Player", "[MiningHandler]", true) then
		return
	end

	for i = 1, #self.miningPlayers do
		if self.miningPlayers[i] == player then
			table.remove(self.miningPlayers, i)
			local customPlayer = CustomPlayers.getPlayer(player)
			if customPlayer.weakSpot then
				customPlayer.weakSpot:deleteWeakSpot()
			end
			customPlayer.result = nil
			stopedMining:FireClient(player)
			break
		end
	end
end

function Node:mine(player: Player, deltaTime: number)
	if not Utils.checkValue(player, "Player", "[MiningHandler]", true) then
		return
	end

	local customPlayer = CustomPlayers.getPlayer(player)
	local tool = customPlayer.miningData.tool
	local toolId = tool:GetAttribute("id")
	local toolData = Items.miningTools[toolId]

	customPlayer.miningData.time += deltaTime

	if self.health == 0 then
		self:removeMiningPlayer(player)
		return
	end

	--check for already existing weakspot if so delete existing
	--this part could potentially be obselete and never actually fire
	if customPlayer.weakSpot and customPlayer.weakSpot.Parent ~= self.instance then
		customPlayer.result = nil
		customPlayer.weakSpot:deleteWeakSpot()
	end

	--tries to find a random hit for weak spot
	if not customPlayer.result then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { self.instance }

		--ups the tries to compensate
		local tries
		if customPlayer.miningData.wasMining then
			tries = 100
		end

		customPlayer.result = self:camCast(customPlayer.mouseRay, params, toolData.swingRange, tries)
		if not customPlayer.result and customPlayer.miningData.wasMining then
			warn("camCast() timed out => no weak spot created for player: " .. player.UserId)
		end
	end

	local totalSpeed = toolData.miningSpeed + customPlayer.stats.miningSpeed
	local mineRate = 0.9886 * math.pow(2.718, -0.002 * totalSpeed) + self.oreData.miningDifficulty

	if customPlayer.miningData.wasMining then
		customPlayer.miningData.time = mineRate
		customPlayer.miningData.wasMining = false
	end

	if customPlayer.miningData.time >= mineRate then
		customPlayer.miningData.time -= mineRate

		--Health
		self.health = math.max(0, self.health - 1)

		--CHECK FOR HIT
		local hitResult =
			MiningHandler.checkHit(player, { game.Workspace.ResourceNodes:GetChildren() }, toolData.swingRange)
		if not hitResult then
			self:removeMiningPlayer(player)
			return
		end
		if
			hitResult.Instance ~= self.instance
			and (not customPlayer.weakSpot or hitResult.Instance ~= customPlayer.weakSpot.raycastCopy)
		then
			self:removeMiningPlayer(player) --WARNING: Node:removeMiningPlayer(player) failing could be potentialy game breaking and should be handled properly in the future

			--Because of the raycast params being ResourceNodes and because we already checked for no results the player must be looking at a new node.
			--update to new node and ping client.
			local node = MiningHandler.getNode(hitResult.Instance)
			node:addMiningPlayer(player, tool, true)
			local NewTarget = game.ReplicatedStorage:FindFirstChild("Mining"):FindFirstChild("NewTarget")
			NewTarget:FireClient(player, node.instance)
			return
		end

		--IF WEAK SPOT HIT
		local weakSpotBonus = 0
		if customPlayer.weakSpot and hitResult.Instance == customPlayer.weakSpot.raycastCopy then
			weakSpotBonus = MiningHandler.weakSpotBonus * customPlayer.stats.weakSpotBonusMultiplier -- activate weak spot bonus
			customPlayer.weakSpot:deleteWeakSpot()

			--creates next one if result
			if customPlayer.result and 0 < self.health then
				CustomPlayers.newWeakSpot(self, customPlayer, customPlayer.result, hitResult)
			end
		end

		--create weak spot
		if 0 < self.health then
			if customPlayer.result and not customPlayer.weakSpot then
				CustomPlayers.newWeakSpot(self, customPlayer, customPlayer.result, hitResult)
			end

			if not customPlayer.weakSpot then
				warn("[MiningHandler] camCast/result timed out failed to create weak spot.")
			end
		end

		--Particles
		local ParticleEmitter
		local ParticlePart
		local success, err = pcall(function()
			ParticlePart = workspace.ResourceNodes.particles.particlePart:Clone()
			ParticlePart.Parent = self.instance
			ParticleEmitter = ParticlePart.ParticleEmitter
		end)

		if err then
			warn("[MiningHandler] Failed to find ParticleEmitter of Node: " .. Utils.getPath(self.instance))
			return
		end

		ParticlePart.Position = hitResult.Position
		ParticleEmitter.Enabled = true

		task.delay(0.5, function()
			ParticleEmitter.Enabled = false
			task.delay(0.5, function()
				ParticlePart:Destroy()
			end)
		end)

		--Sound
		if string.lower(toolData.type) == "pickaxe" then
			local index = math.random(1, 4)
			local soundName = "Pickaxe Strike 0" .. tostring(index)
			local Sound = workspace.ResourceNodes.sfx.pickaxe:FindFirstChild(soundName)

			Sound:Play()
		end

		--Player rewards

		--XP
		customPlayer:addXP(self.oreData.xp)

		--Items

		local totalFortune = toolData.miningFortune + customPlayer.stats.fortune + weakSpotBonus
		local trueFortune = math.log(0.9 * totalFortune + 200, 1.8) - 9.0141
		local adjustedTable = MiningHandler.getAdjustedTable(self.oreData.dropTable, trueFortune)
		local loot = MiningHandler.dropLoot(adjustedTable, trueFortune)
		for _, item in pairs(loot) do
			customPlayer:giveItem(item, 1, true)
		end

		--Destroy on health = 0
		if self.health == 0 then
			self.instance.BrickColor = BrickColor.new("Grey")
			if customPlayer.weakSpot then
				customPlayer.weakSpot:deleteWeakSpot()
			end
		end
	end
end

function Node:regen(deltaTime: number)
	if self.health == self.maxHealth then
		return
	end

	self.time += deltaTime

	if not (self.oreData.regenTime <= self.time) then
		return
	end

	if not (self.oreData.regenTime + self.oreData.regenRate <= self.time) then
		return
	end

	self.time -= self.oreData.regenRate

	self.health = math.min(self.maxHealth, self.health + 1)

	if self.health > 0 then
		self.instance.BrickColor = BrickColor.new("Black")
	end
end

function Node:camCast(mouseRay: Ray, rayParams: RaycastParams, swingRange: number, tries: number, angle: number)
	if not Utils.checkValue(mouseRay, "Ray", "[Utils]") then
		return
	end
	if not Utils.checkValue(rayParams, "RaycastParams", "[Utils]") then
		return
	end
	if not Utils.checkValue(swingRange, "number", "[Utils]") then
		return
	end

	if not tries then
		tries = 10
	end
	if not angle then
		angle = 45
	end

	local origin = mouseRay.Origin
	local camDirection = mouseRay.Direction.Unit

	local Buffer = 10

	for i = 1, tries do
		-- Pick random rotation around axis
		local theta = math.random() * 2 * math.pi
		-- Pick random tilt from center (smaller bias than uniform sphere)
		local z = math.cos(angle * math.random())
		local r = math.sqrt(1 - z * z)

		local x = r * math.cos(theta)
		local y = r * math.sin(theta)

		-- Build a random vector in local cone space (pointing along +Z)
		local localDir = Vector3.new(x, y, z)

		-- Rotate localDir so +Z aligns with 'direction'
		local up = Vector3.new(0, 1, 0)
		if math.abs(camDirection:Dot(up)) > 0.999 then
			up = Vector3.new(1, 0, 0) -- avoid gimbal lock if pointing straight up
		end

		local right = camDirection:Cross(up).Unit
		local newUp = right:Cross(camDirection).Unit

		-- Convert to world space
		local direction = (right * localDir.X + newUp * localDir.Y + camDirection * localDir.Z).Unit

		local result = workspace:Raycast(origin, direction * (swingRange + Buffer), rayParams)
		if result then
			return result
		end
	end
end

function MiningHandler.getAdjustedTable(dropTable: table, fortune: number)
	if not Utils.checkValue(dropTable, "table", "[MiningHandler]") then
		return
	end

	if not Utils.checkValue(fortune, "number", "[MiningHandler]") then
		return
	end

	if Utils.tableLength(dropTable) == 0 then
		warn("[MiningHandler] parsed dropTable has no entries", debug.traceback("", 2))
		return
	end

	local adjustedTable = table.clone(dropTable)

	local max_w = 0
	for drop, w in pairs(dropTable) do
		max_w += w
	end

	for drop, w in pairs(dropTable) do
		local rarity_factor = max_w / w
		adjustedTable[drop] = w + fortune * math.pow(rarity_factor, MiningHandler.rarity_influence)
	end

	return adjustedTable
end

function MiningHandler.dropLoot(dropTable: table, fortune: number)
	if not Utils.checkValue(dropTable, "table", "[MiningHandler]") then
		return
	end

	if not Utils.checkValue(fortune, "number", "[MiningHandler]") then
		return
	end

	if Utils.tableLength(dropTable) == 0 then
		warn("[MiningHandler] parsed dropTable has no entries", debug.traceback("", 2))
		return
	end

	local dropsAmount = MiningHandler.baseDrops + math.floor(fortune / MiningHandler.plusDropsPerFortune)
	local loot = {}
	for i = 1, dropsAmount do
		local item = Utils.weightedRndPick(dropTable)
		if not item then
			warn("[MiningHandler] failed to pick a random item from dropTable", debug.traceback("", 2))
			return
		end
		table.insert(loot, item)
	end

	return loot
end

function MiningHandler.checkHit(player: Player, targets: table, swingRange: number)
	--if not Utils.checkValue(params, "RaycastParams", "[Utils]", true) then return end
	if not Utils.checkValue(player, "Player", "[Utils]", true) then
		return
	end
	if not Utils.checkValue(swingRange, "number", "[Utils]", true) then
		return
	end

	local mouseUnityRay = CustomPlayers.getPlayer(player):getMouseRay()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = targets

	local result = workspace:Raycast(mouseUnityRay.Origin, mouseUnityRay.Direction * swingRange, params)
	--if not result then return false end
	return result
	--[[if result.Instance == target then
		return true
	end]]
end

return MiningHandler
