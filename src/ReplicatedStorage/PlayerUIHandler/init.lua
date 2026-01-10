local PlayerUIHandler = {}

--Modules
local InventoryUIHandler = require(script:WaitForChild("InventoryUIHandler"))
local Utils = require(game.ReplicatedStorage:WaitForChild("Utils"))
local LootNotifications = require(script:WaitForChild("LootNotifications"))

--Services
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Remote Events
local reqStats = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("reqStats")

local PlayerUI = {}
PlayerUI.__index = PlayerUI

function PlayerUIHandler.new(player: Player, mouse: PlayerMouse)
	if
		not Utils.checkValue(player, "Player", "[PlayerUIHandler]")
		or not Utils.checkValue(mouse, "PlayerMouse", "[PlayerUIHandler]")
	then
		return
	end

	local self = {}
	setmetatable(self, PlayerUI)

	self.player = player
	self.Instance = player.PlayerGui
	self.mouse = mouse

	--REQUEST PLAYER STATS
	self.stats = self:reqStats()

	-- Disable the default backpack (hotbar)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	--DEFAULT GUI
	self.DefaultGui = self.Instance:WaitForChild("DefaultGui")
	self.lootNotifications = LootNotifications.new(self)

	--INVENTORY GUI
	self.InventoryUI = InventoryUIHandler.new(self)

	--FreeCursor
	local FreeCursor = Instance.new("ScreenGui")
	FreeCursor.Name = "FreeCursor"
	FreeCursor.Enabled = false
	local ModalButton = Instance.new("TextButton")
	ModalButton.Name = "ModalButton"
	ModalButton.Modal = true
	ModalButton.Size = UDim2.new(0, 0, 0, 0)
	ModalButton.Position = UDim2.new(0, 0, 0, 0)
	ModalButton.Parent = FreeCursor
	FreeCursor.Parent = self.Instance
	self.FreeCursor = FreeCursor
	self.InventoryUI:ConnectToInventoryEnabledChanged(function(enabled)
		self.FreeCursor.Enabled = enabled
	end)

	PlayerUIHandler[self.player.UserId] = self

	return self
end

--- Gets the PlayerUI.
--- @param timeout? number
function PlayerUIHandler.getPlayerUI(userId: number, timeout: number)
	timeout = timeout or 5
	local start = os.clock()

	while not PlayerUIHandler[userId] do
		if os.clock() - start > timeout then
			warn("[PlayerUIHandler] Timed out waiting for InventoryUI of:", userId)
			return nil
		end
		task.wait()
	end

	return PlayerUIHandler[userId]
end

function PlayerUI:reqStats()
	reqStats:FireServer()
	local received = nil
	local connection
	connection = reqStats.OnClientEvent:Connect(function(response)
		received = response
		connection:Disconnect()
	end)
	for i = 0, 5 do
		if received then
			break
		end

		task.wait(1)
	end
	if not received then
		warn(
			"[InventoryUIHandler] Timed out while waiting for customPlayer data. Player: "
				.. tostring(self.player.UserId)
				.. "."
		) --might want to kick player in the future
	else
		return received
	end
end

return PlayerUIHandler
