local InventoryUIHandler = {}

--Services
local RunService = game:GetService("RunService")

--Modules
local Bag = require(script:WaitForChild("Bag"))
local ItemsInv = require(script:WaitForChild("ItemsInv"))
local Equipment = require(script:WaitForChild("Equipment"))
local CursorItem = require(script:WaitForChild("CursorItem"))
local Crafting = require(script:WaitForChild("Crafting"))

local InventoryUI = {}
InventoryUI.__index = InventoryUI
function InventoryUIHandler.new(PlayerUI: table)
	local self = {}
	setmetatable(self, InventoryUI)

	self.mouse = PlayerUI.mouse
	self.player = PlayerUI.player

	--INVENTORY GUI
	self.InventoryGui = PlayerUI.Instance:WaitForChild("InventoryGui")
	self.InventoryGui.Changed:Connect(function(property)
		if property == "Enabled" then
			self:FireInventoryEnabledChanged()
		end
	end)
	self.OnInventoryEnabledChanged = {}
	self.InventoryFrame = self.InventoryGui:WaitForChild("Inventory")
	--init inventory btn
	self.InvBtn = PlayerUI.DefaultGui:WaitForChild("ImageButton")
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

	--TOP BAR
	self.TopBar = self.InventoryFrame:WaitForChild("TopBar")
	self.RightTabs = self.TopBar:WaitForChild("RightTabs")
	self.LeftTabs = self.TopBar:WaitForChild("LeftTabs")

	--CURSOR ITEM
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

	--HOTBAR GUI
	self.HotbarGui = PlayerUI.Instance:WaitForChild("Hotbar")
	self.HotbarFrame = self.HotbarGui:WaitForChild("hotbar")
	self:ConnectToInventoryEnabledChanged(function(enabled)
		self.HotbarGui.Enabled = not enabled
	end)

	--BAG
	self.Bag = Bag.new(self)
	self.BagBtn = self.RightTabs:WaitForChild("Bag")

	--ITEMSINV
	self.ItemsInv = ItemsInv.new(PlayerUI, self)
	self.ItemsBtn = self.RightTabs:WaitForChild("Items")

	--EQUIPMENT
	self.Equipment = Equipment.new(self)
	self.EquipmentBtn = self.LeftTabs:WaitForChild("Equipment")

	--CRAFTING
	self.Crafting = Crafting.new(self, PlayerUI)
	self.CraftingBtn = self.LeftTabs:WaitForChild("Crafting")

	self:setUpTabs()

	InventoryUIHandler[self.player.UserId] = self

	return self
end

--- Returns the InventoryUI for the given player.
--- @overload fun(userId: number)
function InventoryUIHandler.getInventoryUI(userId: number, timeout: number)
	timeout = timeout or 5
	local start = os.clock()

	while not InventoryUIHandler[userId] do
		if os.clock() - start > timeout then
			warn("[InventoryUIHandler] Timed out waiting for InventoryUI of:", userId)
			return nil
		end
		task.wait()
	end

	return InventoryUIHandler[userId]
end

--- Connect a function to fire when the Inventory's Enabled property changed.
function InventoryUI:ConnectToInventoryEnabledChanged(func)
	table.insert(self.OnInventoryEnabledChanged, func)
end

--- Disconnect a function from the Inventory changed event.
function InventoryUI:DisconnectFromInventoryEnabledChanged(func)
	local index = table.find(self.OnInventoryEnabledChanged, func)
	if not index then
		return
	end
	table.remove(self.OnInventoryEnabledChanged, func)
end

--- Fire the Inventory's Enabled property changed event.
function InventoryUI:FireInventoryEnabledChanged()
	for _, func in pairs(self.OnInventoryEnabledChanged) do
		func(self.InventoryGui.Enabled)
	end
end

function InventoryUI:resizeCursorItem()
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

function InventoryUI:setUpTabs()
	self.BagBtn.MouseButton1Click:Connect(function()
		self.Bag.Instance.Visible = true
		self.ItemsInv.Instance.Visible = false
		self.cursorItem:cancel()
	end)

	self.ItemsBtn.MouseButton1Click:Connect(function()
		self.Bag.Instance.Visible = false
		self.ItemsInv.Instance.Visible = true
	end)

	self.EquipmentBtn.MouseButton1Click:Connect(function()
		self.Equipment.Instance.Visible = true
		self.Crafting.Instance.Visible = false
	end)

	self.CraftingBtn.MouseButton1Click:Connect(function()
		self.Equipment.Instance.Visible = false
		self.Crafting.Instance.Visible = true
		self.cursorItem:cancel()
	end)
end

return InventoryUIHandler
