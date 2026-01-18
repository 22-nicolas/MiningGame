local CustomPlayers
local RunService = game:GetService("RunService")

local DropHandler = {
	baseTrancparency = 0.6,
	fadeOutTime = 0.3,
	despawnTime = 300,
}

local itemBox = {}
itemBox.__index = itemBox

--- Drops the specified item from the given origin.
--- @overload fun(origin: any, item: table)
function DropHandler.dropItem(origin: any, item: table, amount: number)
	if amount then
		item.amount = amount
	end

	local itemBox = DropHandler.initItemBox(item)

	itemBox.Part.CFrame = origin.CFrame * CFrame.new(0, 0, -3)
	itemBox.Part.AssemblyLinearVelocity = origin.CFrame.LookVector * 20 + Vector3.new(0, 10, 0)
	itemBox.DisplayPart.CFrame = itemBox.Part.CFrame

	itemBox.Part.Parent = workspace
end

--- Initialize item box.
function DropHandler.initItemBox(item: table)
	local self = {}
	setmetatable(self, itemBox)

	self.Item = item

	local amountText = ""
	if item.amount > 1 then
		amountText = " x" .. tostring(item.amount)
	end

	--part
	local Part = Instance.new("Part")
	Part.Size = Vector3.new(1, 1, 1)
	Part.Anchored = false
	Part.Transparency = DropHandler.baseTrancparency
	Part.Material = Enum.Material.Foil
	Part.Color = self.Item.rarity
	self.Part = Part

	--DisplayPart
	local DisplayPart = Instance.new("Part")
	DisplayPart.Size = Vector3.new(1, 1, 0.001)
	DisplayPart.Anchored = false
	DisplayPart.Massless = true
	DisplayPart.Transparency = 1
	DisplayPart.Parent = Part
	self.DisplayPart = DisplayPart

	--Gui
	local frontGui = Instance.new("SurfaceGui")
	local backGui = Instance.new("SurfaceGui")
	backGui.Face = Enum.NormalId.Back
	local frontImgLabel = Instance.new("ImageLabel")
	frontImgLabel.Image = self.Item.img
	frontImgLabel.Size = UDim2.new(1, 0, 1, 0)
	frontImgLabel.BackgroundTransparency = 1
	local backImgLabel = frontImgLabel:Clone()
	frontImgLabel.Parent = frontGui
	backImgLabel.Parent = backGui
	frontGui.Parent = DisplayPart
	backGui.Parent = DisplayPart
	self.frontImgLabel = frontImgLabel
	self.backImgLabel = backImgLabel

	--Weld
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = DisplayPart
	weld.Part1 = Part
	weld.Parent = Part

	--proximity prompt
	local Prompt = Instance.new("ProximityPrompt")
	Prompt.ActionText = self.Item.displayName .. amountText
	Prompt.ObjectText = "pick up"
	Prompt.MaxActivationDistance = 5
	Prompt.Parent = Part
	self.Prompt = Prompt
	--pick up behaviour
	Prompt.Triggered:Connect(function(player)
		self:pickUp(player)
	end)

	task.delay(DropHandler.despawnTime, function()
		self:delete()
	end)

	return self
end

--- Pick up behaviour.
function itemBox:pickUp(player)
	if not CustomPlayers then
		CustomPlayers = require(game.ServerScriptService:WaitForChild("CustomPlayers"))
	end

	local customPlayer = CustomPlayers.getPlayer(player)
	if not customPlayer then
		return
	end

	self:delete()
	customPlayer:giveItem(self.Item, true)
end

--- Delete item box.
function itemBox:delete()
	--disconnect player interaction
	self.Prompt:Destroy()

	--animation
	local fadeOutConnection
	local time = 0
	fadeOutConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
		time += deltaTime
		local progress = math.min(1, time / DropHandler.fadeOutTime)

		self.Part.Transparency = DropHandler.baseTrancparency + (1 - DropHandler.baseTrancparency) * progress
		self.frontImgLabel.ImageTransparency = progress
		self.backImgLabel.ImageTransparency = progress

		if progress == 1 then
			fadeOutConnection:Disconnect()
			self.Part:Destroy() -- remove from workspace
		end
	end)
end

return DropHandler
