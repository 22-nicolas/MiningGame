local InventoryUIHandler = {}

--Services
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

--Modules
local Utils = require(ReplicatedStorage:WaitForChild("Utils"))

local LootNotifications = require(script:WaitForChild("LootNotifications"))
local Bag = require(script:WaitForChild("Bag"))
local ItemsInv = require(script:WaitForChild("ItemsInv"))
local Equipment = require(script:WaitForChild("Equipment"))
local CursorItem = require(script:WaitForChild("CursorItem"))

local playerUI = {}
playerUI.__index = playerUI
function InventoryUIHandler.initPlayerUI(player: Player, mouse: PlayerMouse)
	if not Utils.checkValue(player, "Player", "[CustomPlayers]") then
		return
	end
	if not Utils.checkValue(mouse, "PlayerMouse", "[InventoryHandler]") then
		return
	end

	local self = {}
	setmetatable(self, playerUI)

	self.mouse = mouse
	self.player = player

	--REQUEST PLAYER STATS
	self.stats = self:reqStats()

	-- Disable the default backpack (hotbar)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	--DEFAULT GUI
	self.DefaultGui = player.PlayerGui:WaitForChild("DefaultGui")
	self.lootNotifications = LootNotifications.new(self)

	--HOTBAR GUI
	self.HotbarGui = player.PlayerGui:WaitForChild("Hotbar")
	self.HotbarFrame = self.HotbarGui:WaitForChild("hotbar")

	--INVENTORY GUI
	self.InventoryGui = player.PlayerGui:WaitForChild("InventoryGui")
	self.InventoryGui.Changed:Connect(function(property)
		if property == "Enabled" then
			self.HotbarGui.Enabled = not self.InventoryGui.Enabled
		end
	end)
	self.InventoryFrame = self.InventoryGui:WaitForChild("Inventory")
	--init inventory btn
	self.InvBtn = self.DefaultGui:WaitForChild("ImageButton")
	self.InvBtn.Activated:Connect(function()
		self.InventoryGui.Enabled = not self.InventoryGui.Enabled
		--if closed cancel cursorItem
		if not self.InventoryGui.Enabled then
			self.cursorItem:cancel()
		end
	end)

	self.InventoryFrame.Changed:Connect(function(property)
		if property == "AbsoluteSize" then
			self:resizeCursorItem()
		end
	end)

	self.TopBar = self.InventoryFrame:WaitForChild("TopBar")
	self.TabsFrame = self.TopBar:WaitForChild("Tabs")

	self.cursorItem = CursorItem.new(self)

	RunService.Heartbeat:Connect(function()
		local UIelement = self.cursorItem.Instance
		UIelement.Position = UDim2.new(
			0,
			self.mouse.X - UIelement.AbsoluteSize.X / 2 - self.InventoryFrame.AbsolutePosition.X,
			0,
			self.mouse.Y - UIelement.AbsoluteSize.Y / 2 - self.InventoryFrame.AbsolutePosition.Y
		)
	end)

	--BAG
	self.Bag = Bag.new(self)
	self.BagBtn = self.TabsFrame:WaitForChild("Bag")

	--ITEMSINV
	self.ItemsInv = ItemsInv.new(self)
	self.ItemsBtn = self.TabsFrame:WaitForChild("Items")

	--EQUIPMENT
	self.Equipment = Equipment.new(self)

	self:setUpTabs()

	InventoryUIHandler[self.player.UserId] = self

	return self
end

--- Returns the playerUI for the given player.
function InventoryUIHandler.getPlayerUI(UserId: number)
	if not Utils.checkValue(UserId, "number", "[InventoryUIHandler]") then
		return
	end

	local playerUI = InventoryUIHandler[UserId]
	
	if not playerUI then
		warn("[InventoryUIHandler] The requested PlayerUI doesn't exist. The PlayerUI might not be initialized yet. Player: " .. tostring(UserId) .. ".", debug.traceback())
	end

	return playerUI
end

local reqStats = ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("reqStats")
function playerUI:reqStats()
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

function playerUI:resizeCursorItem()
	local timeout = 5
	local init = false
	for i = 0, timeout do
		if self.ItemsInv and self.ItemsInv.Slots and self.ItemsInv.Slots[1] then
			init = true
			break
		end
		wait(1)
	end

	if not init then
		warn("[InventoryUIHandler] Timedout while waiting for slots of player: " .. tostring(self.player.UserId) .. ".")
		return
	end

	self.cursorItem.Instance.Size =
		UDim2.fromOffset(self.ItemsInv.Slots[1].Instance.AbsoluteSize.X, self.ItemsInv.Slots[1].Instance.AbsoluteSize.Y)
end

function playerUI:setUpTabs()
	self.BagBtn.MouseButton1Click:Connect(function()
		self.Bag.Instance.Visible = true
		self.ItemsInv.Instance.Visible = false
		self.cursorItem:cancel()
	end)

	self.ItemsBtn.MouseButton1Click:Connect(function()
		self.Bag.Instance.Visible = false
		self.ItemsInv.Instance.Visible = true
	end)
end

return InventoryUIHandler
