local Bag = {}
Bag.__index = Bag

local Items = require(game.ReplicatedStorage:WaitForChild("Items"))
local BagTooltip = require(script:WaitForChild("BagTooltip"))

function Bag.new(InventoryUI)
	local self = {}
	setmetatable(self, Bag)

	self.Instance = InventoryUI.InventoryFrame:WaitForChild("Bag")
	self.ItemContainer = self.Instance:WaitForChild("items")
	self.InventoryUI = InventoryUI
	self.tooltip = BagTooltip.new(self)

	return self
end

function Bag:update(bagData)
	local children = self.ItemContainer:GetChildren()
	for _, child in pairs(children) do
		if child.ClassName ~= "UIListLayout" then
			child:Destroy()
		end
	end

	for id, item in pairs(bagData) do
		local button = self:initItemUI(id, item.amount)
		button.MouseEnter:Connect(function()
			self.tooltip:show(id)
			self:highlightButton(button)
		end)

		button.MouseLeave:Connect(function()
			self.tooltip:hide()
			self:dehighlightButton(button)
		end)
	end
end

function Bag:initItemUI(id, amount)
	local item = Items.getItemById(id)

	if not item then
		warn(
			"[InventoryHandler] Error: No item data for player: "
				.. tostring(self.InventoryUI.player.UserId)
				.. ". While trying to add item to bag"
		)
		return
	end

	item.amount = amount

	local button = Instance.new("TextButton")
	button.Text = ""
	button.Size = UDim2.new(1, 0, 0, 20)
	button.BackgroundColor = BrickColor.Black()
	button.BackgroundTransparency = 1

	local UiListLayout = Instance.new("UIListLayout")
	UiListLayout.FillDirection = Enum.FillDirection.Horizontal
	UiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UiListLayout.Wraps = false
	UiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	UiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	UiListLayout.Parent = button

	local img = Instance.new("ImageLabel")
	img.Image = item.img
	img.Size = UDim2.new(0, 0, 1, 0)
	img.BackgroundTransparency = 1
	img.LayoutOrder = 1
	img.Parent = button

	local aspectRatio = Instance.new("UIAspectRatioConstraint")
	aspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
	aspectRatio.DominantAxis = Enum.DominantAxis.Height
	aspectRatio.AspectRatio = 1
	aspectRatio.Parent = img

	local textLabel = Instance.new("TextLabel")
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextColor3 = item.rarity
	textLabel.FontFace.Weight = Enum.FontWeight.Bold
	textLabel.BackgroundTransparency = 1
	textLabel.Name = item.displayName
	textLabel.Text = tostring(item.amount) .. "x " .. id
	textLabel.Position = UDim2.new(0.3, 0, 0, 0)
	textLabel.Size = UDim2.new(0.7, 0, 1, 0)
	textLabel.LayoutOrder = 2
	textLabel.Parent = button

	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.new(0, 0, 0)
	textStroke.Parent = textLabel

	button.Parent = self.ItemContainer

	return button
end

function Bag:highlightButton(button: TextButton)
	button.BackgroundTransparency = 0.9
end

function Bag:dehighlightButton(button: TextButton)
	button.BackgroundTransparency = 1
end

return Bag
