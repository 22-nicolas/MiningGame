local Utils = require(game.ReplicatedStorage:WaitForChild("Utils"))
local slotClick = game.ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("slotClick")

local SlotsHandler = {
	clearImg = "rbxassetid://18662154",
	slotTexture = "rbxassetid://117373957075527",
	defaultSlotColor = Color3.fromRGB(116, 116, 122),
	slotTransparency = 0.8,
	hotbarSlotTypes = {
		EquipmentHotbarSlot = "EquipmentHotbarSlot",
		HotbarSlot = "HotbarSlot"
	},
	HotbarSize = 6
}

--ITEMS INVENTORY SLOT
local slot = {}
slot.__index = slot

function SlotsHandler.newSlot(playerUI: table, parent: UIBase, layoutOrderIndex: number, type: string, rowSize: number)
	local self = {}
	setmetatable(self, slot)

	local slot = Instance.new("ImageButton")
	slot.Image = SlotsHandler.slotTexture
	slot.Size = UDim2.new(1/rowSize, -7, 0, 0)
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

	if type == "HotbarSlot" then
		local scale = Instance.new("UIScale")
		if layoutOrderIndex == 1 then
			scale.Scale = 1.2
		else
			scale.Scale = 1
		end
		scale.Parent = slot
	end

	slot.Parent = parent

	self.Instance = slot
	if string.find(string.lower(type), "hotbar") then
		self.type = "hotbar"
	else
		self.type = type		
	end
	self.slotNum = layoutOrderIndex

	if type == "HotbarSlot" then
		return self
	end

	self.Instance.MouseButton1Click:Connect(function()
		slotClick:FireServer(self:getItem(), self.type, self.slotNum)
	end)

	self.Instance.InputChanged:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			local item = self:getItem()
			if not item then
				return
			end
			playerUI.ItemsInv.tooltip:show(item)
		end
	end)

	self.Instance.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			local item = self:getItem()
			if not item then
				return
			end
			playerUI.ItemsInv.tooltip:hide()
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

return SlotsHandler