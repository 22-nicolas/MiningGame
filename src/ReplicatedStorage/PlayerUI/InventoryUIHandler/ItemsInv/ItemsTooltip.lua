local ItemsTooltip = {
	itemStats = {
		miningSpeed = "mining speed",
		miningFortune = "mining fortune",
		swingRange = "swing range",
		breakingPower = "breaking power",
		npcSell = "npc sell",
	},
}

local Utils = require(game.ReplicatedStorage:WaitForChild("Utils"))
local Items = require(game.ReplicatedStorage:WaitForChild("Items"))

local RunService = game:GetService("RunService")

ItemsTooltip.__index = ItemsTooltip
function ItemsTooltip.new(ItemsInv)
	local self = {}
	setmetatable(self, ItemsTooltip)

	self.Instance = ItemsInv.Instance:WaitForChild("tooltip")
	self.heartbeat = RunService.Heartbeat:Connect(function()
		self:updatePos()
	end)
	self.ItemsInv = ItemsInv
	self.playerUI = ItemsInv.playerUI
	self.statsFrame = self.Instance:WaitForChild("stats")
	self.statsPool = self:initStatsPool()
	self.itemData = nil

	return self
end

function ItemsTooltip:initStatsPool()
	local statsPool = {}
	for id, displayName in pairs(ItemsTooltip.itemStats) do
		local stat = Instance.new("Frame")
		stat.BackgroundTransparency = 1
		stat.Size = UDim2.new(0, 0, 0, 0)
		stat.AutomaticSize = Enum.AutomaticSize.XY
		stat.Name = id
		stat.Visible = false

		local UIListLayout = Instance.new("UIListLayout")
		UIListLayout.FillDirection = Enum.FillDirection.Horizontal
		UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.Padding = UDim.new(0, 2)
		UIListLayout.Parent = stat

		local statName = Instance.new("TextLabel")
		statName.LayoutOrder = 1
		statName.BackgroundTransparency = 1
		statName.Size = UDim2.new(0, 0, 0, 0)
		statName.AutomaticSize = Enum.AutomaticSize.XY
		statName.TextSize = 14
		statName.TextColor3 = Color3.fromRGB(159, 159, 159)
		statName.Text = displayName .. ":"
		statName.Font = Enum.Font.SourceSansBold
		--statName.FontFace.Bold = true
		statName.Name = "statName"
		statName.Parent = stat

		local statValue = Instance.new("TextLabel")
		statValue.LayoutOrder = 2
		statValue.BackgroundTransparency = 1
		statValue.Size = UDim2.new(0, 0, 0, 0)
		statValue.AutomaticSize = Enum.AutomaticSize.XY
		statValue.TextSize = 14
		statValue.TextColor3 = Color3.fromRGB(159, 159, 159)
		statValue.Text = ""
		statValue.Font = Enum.Font.SourceSansBold
		--statValue.FontFace.Bold = true
		statValue.Name = "statValue"
		statValue.Parent = stat

		stat.Parent = self.statsFrame
		statsPool[id] = stat
	end

	return statsPool
end

function ItemsTooltip:updatePos()
	local playerUI = self.playerUI
	local ItemsInvInstance = self.ItemsInv.Instance
	self.Instance.Position = UDim2.new(
		0,
		playerUI.mouse.X - ItemsInvInstance.AbsolutePosition.X + 14,
		0,
		playerUI.mouse.Y - ItemsInvInstance.AbsolutePosition.Y + 10
	)
end

function ItemsTooltip:show(item)
	if self.playerUI.cursorItem.itemData then
		return
	end
	if self.itemData == item then
		return
	end

	self.itemData = item
	self.Instance.description.Text = item.description
	self.Instance.displayName.Text = item.displayName
	self.Instance.displayName.TextColor3 = item.rarity
	for _, stat in pairs(self.statsPool) do
		stat.Visible = false
	end
	if item.displayedStats then
		for i = 1, #item.displayedStats do
			local stat = self.statsPool[item.displayedStats[i]]
			stat.statValue.Text = item[item.displayedStats[i]]
			stat.Visible = true
		end
	end
	self.Instance.Visible = true
end

function ItemsTooltip:hide()
	self.itemData = nil
	self.Instance.Visible = false
end

return ItemsTooltip
