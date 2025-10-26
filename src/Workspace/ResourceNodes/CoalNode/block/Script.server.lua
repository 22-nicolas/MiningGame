local MiningHandler = require(game.ServerScriptService:WaitForChild("MiningHandler"))

local startedMining = game.ReplicatedStorage:WaitForChild("Mining"):WaitForChild("MineRequest")
local stopedMining = game.ReplicatedStorage:WaitForChild("Mining"):WaitForChild("StopMining")

local this = script.Parent
local target

local node = MiningHandler.newNode(this)

if not node then return end

startedMining.OnServerEvent:Connect(function(player, target: Instance, tool)
	if target ~= node.instance then return end
	node:addMiningPlayer(player, tool)
end)

stopedMining.OnServerEvent:Connect(function(player, target, tool)
	if target ~= node.instance then return end
	node:removeMiningPlayer(player)
end)



