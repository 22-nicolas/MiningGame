local LootNotifications = {}
LootNotifications.__index = LootNotifications

function LootNotifications.new(playerUI)
	
	local self = {}
	setmetatable(self, LootNotifications)
	
	self.Instance = playerUI.DefaultGui:WaitForChild("lootNotifications")
	self.notificationsList = {}
	self.playerUI = playerUI
	
	return self
end

function LootNotifications:addNotification(id, item, deltaAmount)
	local found = false
	--If item already exists, update notification
	for i, existingItem in pairs(self.notificationsList) do
		if existingItem.id == id then
			table.remove(self.notificationsList, i)
			existingItem.amount += deltaAmount
			existingItem.tick = tick()
			task.delay(5, function()
				self:removeNotification(existingItem)
			end)
			table.insert(self.notificationsList, existingItem)
			found = true
			break
		end
	end

	--Else create a new notification
	if not found then
		item.amount = deltaAmount
		item.id = id
		item.tick = tick()
		task.delay(5, function()
			self:removeNotification(item)
		end)
		table.insert(self.notificationsList, item)
	end

	self:update()
end

function LootNotifications:removeNotification(item)
	local index = table.find(self.notificationsList, item)
	if not index then return end
	if tick() - item.tick >= 5 then
		table.remove(self.notificationsList, index)
		self:update()
	end
end

function LootNotifications:update()
	local children = self.Instance:GetChildren()
	for _, child in pairs(children) do
		if child.ClassName ~= "UIListLayout" then 
			child:Destroy()
		end
	end

	for i, item in pairs(self.notificationsList) do
		self:initNotificationUI(i, item)
	end
end

function LootNotifications:initNotificationUI(i, item)
	local button = Instance.new("TextButton")
	button.Text = ""
	button.LayoutOrder = i
	button.Size = UDim2.new(0, 200, 0, 20)
	button.BackgroundTransparency = 1
	button.Parent = self.Instance

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

	local color = Color3.new(1, 1, 1)
	local prefix
	if item.amount <= 0 then
		color = Color3.fromRGB(170, 0, 0)
		prefix = "-"
	else
		color = Color3.fromRGB(0, 170, 0)
		prefix = "+"
	end
	local textLabel = Instance.new("TextLabel")
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextColor3 = color
	textLabel.FontFace.Weight = Enum.FontWeight.Bold
	textLabel.BackgroundTransparency = 1
	textLabel.Name = item.displayName
	textLabel.Text = prefix..tostring(item.amount).." "..item.displayName
	textLabel.Position = UDim2.new(0.3, 0, 0, 0)
	textLabel.Size = UDim2.new(0.7, 0, 1, 0)
	textLabel.LayoutOrder = 2
	textLabel.Parent = button

	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.new(0, 0, 0)
	textStroke.Parent = textLabel

	return button
end

return LootNotifications
