local Players = game:GetService("Players")
local CustomPlayers = require(game.ServerScriptService:WaitForChild("CustomPlayers"))

function onPlayerJoin(player)
	CustomPlayers.newPlayer(player)
end

Players.PlayerAdded:Connect(onPlayerJoin)