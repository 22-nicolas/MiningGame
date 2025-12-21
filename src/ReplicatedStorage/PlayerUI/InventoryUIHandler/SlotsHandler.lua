local slotClick = game.ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("slotClick")

local SlotsHandler = {
	clearImg = "rbxassetid://18662154",
	slotTexture = "rbxassetid://117373957075527",
	defaultSlotColor = Color3.fromRGB(116, 116, 122),
	slotTransparency = 0.8,
}

--ITEMS INVENTORY SLOT
local slot = {}
slot.__index = slot

function SlotsHandler.newSlot(playerUI, ItemsInv, layoutOrderIndex: number)
	local self = {}
	setmetatable(self, slot)

	local slot = Instance.new("ImageButton")
	slot.Image = SlotsHandler.slotTexture
	slot.Size = UDim2.new(0.2, -7, 0, 0)
	slot.LayoutOrder = layoutOrderIndex
	slot.Name = "slot"
	slot.ZIndex = 10

	local UIAspectRatio = Instance.new("UIAspectRatioConstraint")
	UIAspectRatio.AspectRatio = 1
	UIAspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
	UIAspectRatio.DominantAxis = Enum.DominantAxis.Width
	UIAspectRatio.Parent = slot

	local UIGradient = Instance.new("UIGradient")
	UIGradient.Color = ColorSequence.new(SlotsHandler.defaultSlotColor)
	UIGradient.Transparency = NumberSequence.new(SlotsHandler.slotTransparency)
	UIGradient.Parent = slot

	local ImageLabel = Instance.new("ImageLabel")
	ImageLabel.Image = SlotsHandler.clearImg
	ImageLabel.Size = UDim2.new(1, 0, 1, 0)
	ImageLabel.BackgroundTransparency = 1
	ImageLabel.Active = false
	ImageLabel.Parent = slot

	local amountDisplay = Instance.new("TextLabel")
	amountDisplay.Name = "amountDisplay"
	amountDisplay.Text = "0"
	amountDisplay.Size = UDim2.new(0.2, 0, 0.2, 0)
	amountDisplay.Position = UDim2.new(0, 0, 0, 0)
	amountDisplay.Visible = false
	amountDisplay.Parent = slot

	slot.Parent = ItemsInv.ItemContainer

	self.Instance = slot
	self.type = "items"
	self.slotNum = layoutOrderIndex

	self.Instance.MouseButton1Click:Connect(function()
		slotClick:FireServer(self:getItem(), self.type, self.slotNum)
	end)

	self.Instance.InputChanged:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			local item = self:getItem()
			if not item then
				return
			end
			ItemsInv.tooltip:show(item)
		end
	end)

	self.Instance.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			local item = self:getItem()
			if not item then
				return
			end
			ItemsInv.tooltip:hide()
		end
	end)

	return self
end

function slot:getItem()
	return self.item
end

function slot:setItem(item)
	local itemImg = self.Instance:FindFirstChildOfClass("ImageLabel")
	local UIGradient = self.Instance:FindFirstChildOfClass("UIGradient")
	local amountDisplay = self.Instance:FindFirstChild("amountDisplay")

	if not item then
		itemImg.Image = SlotsHandler.clearImg
		UIGradient.Color = ColorSequence.new(SlotsHandler.defaultSlotColor)
		amountDisplay.Text = "0"
		amountDisplay.Visible = false
	else
		itemImg.Image = item.img
		UIGradient.Color = ColorSequence.new(item.rarity)
		amountDisplay.Text = tostring(item.amount)
		if item.amount > 1 then
			amountDisplay.Visible = true
		end
	end

	self.item = item
end

--HOTBAR SLOT
local hotbarSlot = {}
hotbarSlot.__index = hotbarSlot

function SlotsHandler.newHotbarSlot(playerUI, UIelement: ImageButton)
	local self = {}
	setmetatable(self, hotbarSlot)

	self.Instance = UIelement
	self.slotNum = UIelement.LayoutOrder
	self.playerUI = playerUI
	self.type = "hotbar"

	self.Instance.MouseButton1Click:Connect(function()
		slotClick:FireServer(self:getItem(), self.type, self.slotNum)
	end)

	return self
end

function hotbarSlot:setItem(item)
	local itemImg = self.Instance:FindFirstChildOfClass("ImageLabel")
	local UIGradient = self.Instance:FindFirstChildOfClass("UIGradient")
	local amountDisplay = self.Instance:FindFirstChild("amountDisplay")

	if not item then
		itemImg.Image = SlotsHandler.clearImg
		UIGradient.Color = ColorSequence.new(SlotsHandler.defaultSlotColor)
		amountDisplay.Text = "0"
		amountDisplay.Visible = false
	else
		itemImg.Image = item.img
		UIGradient.Color = ColorSequence.new(item.rarity)
		amountDisplay.Text = tostring(item.amount)
		if item.amount > 1 then
			amountDisplay.Visible = true
		end
	end

	self.item = item
end

function hotbarSlot:getItem()
	return self.item
end

return SlotsHandler
