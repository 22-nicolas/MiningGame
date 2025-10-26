local BagTooltip = {}

local Utils = require(game.ReplicatedStorage:WaitForChild("Utils"))
local Items = require(game.ReplicatedStorage:WaitForChild("Items"))

local RunService = game:GetService("RunService")

BagTooltip.__index = BagTooltip
function BagTooltip.new(Bag)

	local self = {}
	setmetatable(self, BagTooltip)

	self.Instance = Bag.Instance:WaitForChild("tooltip")
	self.heartbeat = RunService.Heartbeat:Connect(function()
		self:updatePos()
	end)
	self.Bag = Bag
	self.playerUI = Bag.playerUI

	return self
end

function BagTooltip:updatePos()
	local playerUI = self.playerUI
	local BagInstance = self.Bag.Instance
	self.Instance.Position = UDim2.new(0, playerUI.mouse.X - BagInstance.AbsolutePosition.X + 14, 0, playerUI.mouse.Y - BagInstance.AbsolutePosition.Y + 10)
end

function BagTooltip:show(id: string) 
	if not Utils.checkValue(id, "string", "[InventoryHandler]") then return end

	local item = Items.getItemById(id)

	if not item then
		warn("[InventoryHandler] Error: No item data for player: "..tostring(self.playerUI.player.UserId)..". While trying to show BagTooltip")
		return	
	end



	self.Instance.description.Text = item.description
	self.Instance.Visible = not self.Instance.Visible
end

function BagTooltip:hide()
	self.Instance.Visible = not self.Instance.Visible
end

return BagTooltip
