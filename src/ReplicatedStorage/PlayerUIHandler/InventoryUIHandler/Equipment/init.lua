local Equipment = {
	equipedHotbarSlotScale = 1.2,
}

local Utils = require(game.ReplicatedStorage:WaitForChild("Utils"))
local SlotsHandler = require(
	game.ReplicatedStorage
		:WaitForChild("PlayerUIHandler")
		:WaitForChild("InventoryUIHandler")
		:WaitForChild("SlotsHandler")
)
local Hotbar = require(script:WaitForChild("Hotbar"))

local equipHotbarSlot = game.ReplicatedStorage:WaitForChild("Inventory"):WaitForChild("equipHotbarSlot")

Equipment.__index = Equipment
function Equipment.new(InventoryUI)
	local self = {}
	setmetatable(self, Equipment)

	self.InventoryUI = InventoryUI
	self.Instance = InventoryUI.InventoryFrame:WaitForChild("Equipment")
	self.char_preview = self.Instance:WaitForChild("char_preview")
	self.ArmorFrame = self.Instance:WaitForChild("armor")
	self.AccessoriesFrame = self.Instance:WaitForChild("accessories")

	self.slots = {
		helmet = SlotsHandler.newSlot(InventoryUI, self.ArmorFrame.helmet, { type = "equipmentHelmet" }),
		chestplate = SlotsHandler.newSlot(InventoryUI, self.ArmorFrame.chestplate, { type = "equipmentChestplate" }),
		leggings = SlotsHandler.newSlot(InventoryUI, self.ArmorFrame.leggings, { type = "equipmentLeggings" }),
		boots = SlotsHandler.newSlot(InventoryUI, self.ArmorFrame.boots, { type = "equipmentBoots" }),
		necklace = SlotsHandler.newSlot(InventoryUI, self.AccessoriesFrame.necklace, { type = "equipmentNecklace" }),
		ring = SlotsHandler.newSlot(InventoryUI, self.AccessoriesFrame.ring, { type = "equipmentRing" }),
		belt = SlotsHandler.newSlot(InventoryUI, self.AccessoriesFrame.belt, { type = "equipmentBelt" }),
		gloves = SlotsHandler.newSlot(InventoryUI, self.AccessoriesFrame.gloves, { type = "equipmentGloves" }),
	}

	self.Hotbar = Hotbar.initHotbar(InventoryUI, self)

	self:initCharPreiview()

	return self
end

function Equipment:initHotbarSlots()
	-- hotbar slots displayed in equipment
	self.EquipmentHotbarSlots = {}
	for i = 1, SlotsHandler.HotbarSize, 1 do
		table.insert(
			self.EquipmentHotbarSlots,
			SlotsHandler.newSlot(
				self.InventoryUI,
				self.EquipmentHotbarFrame,
				i,
				SlotsHandler.hotbarSlotTypes.EquipmentHotbarSlot,
				SlotsHandler.HotbarSize
			)
		)
	end

	-- hotbar slots displayed at the bottom of the screen
	self.HotbarSlots = {}
	for i = 1, SlotsHandler.HotbarSize, 1 do
		table.insert(
			self.HotbarSlots,
			SlotsHandler.newSlot(
				self.InventoryUI,
				self.HotbarFrame,
				i,
				SlotsHandler.hotbarSlotTypes.HotbarSlot,
				SlotsHandler.HotbarSize
			)
		)
	end
end

function Equipment:update(item, containerId)
	if not containerId then
		return
	end

	--format container id (example: "equipmentHelmet" -> "helmet")
	containerId = string.lower(string.sub(containerId, string.len("equipment") + 1, string.len(containerId)))

	self.slots[containerId]:setItem(item)
end

function Equipment:equipHotbarSlot(slotNum: number)
	equipHotbarSlot:FireServer(slotNum)

	for i, slot in pairs(self.HotbarSlots) do
		if i == slotNum then
			slot.Instance.UIScale.Scale = Equipment.equipedHotbarSlotScale
		else
			slot.Instance.UIScale.Scale = 1
		end
	end
end

function Equipment:initCharPreiview()
	--[=[
		Character Viewport
		Realtime viewing oneself in a GUI window, including tools

		boatbomber, 2/17/19 (Updated: 6/13/2021)
	--]=]

	-- Settings
	local OFFSET = CFrame.new(0, 2, -6)

	-- Services
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")

	-- Objects
	local Player = self.InventoryUI.player
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local ViewPort = self.Instance:FindFirstChild("char_preview")
	local Camera = Instance.new("Camera")

	--print(ViewPort, Player, Character, Camera)

	ViewPort.CurrentCamera = Camera

	local ValidClasses = {
		["MeshPart"] = true,
		["Part"] = true,
		["Accoutrement"] = true,
		["Pants"] = true,
		["Shirt"] = true,
		["Humanoid"] = true,
	}

	local RenderObjects = table.create(25)

	local function RemoveObject(Object)
		local Clone = RenderObjects[Object]
		if not Clone then
			return nil
		end

		RenderObjects[Object] = nil
		if Clone.Parent:IsA("Accoutrement") then
			Clone.Parent:Destroy()
		else
			Clone:Destroy()
		end

		--print("Removed",Object)
	end

	local function AddObject(Object)
		if not ValidClasses[Object.ClassName] then
			return nil
		end

		-- Create clone, regardless of Archivable
		local a = Object.Archivable
		Object.Archivable = true
		local RenderClone = Object:Clone()
		Object.Archivable = a

		if Object.ClassName == "MeshPart" or Object.ClassName == "Part" then
			RenderObjects[Object] = RenderClone
		elseif Object:IsA("Accoutrement") then
			RenderObjects[Object.Handle] = RenderClone.Handle
		elseif Object.ClassName == "Humanoid" then
			--Disable all states. We only want it for clothing wrapping.
			RenderClone:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			RenderClone:SetStateEnabled(Enum.HumanoidStateType.Running, false)
			RenderClone:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
			RenderClone:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
			RenderClone:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
			RenderClone:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			RenderClone:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
			RenderClone:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			RenderClone:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
			RenderClone:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
			RenderClone:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
			RenderClone:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
			RenderClone:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
			RenderClone:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
			RenderClone:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
			RenderClone:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
			RenderClone.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end

		--print("Added",Object)

		return RenderClone
	end

	RunService.Heartbeat:Connect(function()
		if (not Character:FindFirstChild("HumanoidRootPart")) or not ViewPort.Visible then
			return nil
		end

		-- Update camera
		Camera.CFrame = CFrame.new(
			Character.HumanoidRootPart.CFrame:ToWorldSpace(OFFSET).Position,
			Character.HumanoidRootPart.Position
		)

		-- Update objects
		for Original, Clone in pairs(RenderObjects) do
			if Original and Original.Parent then
				Clone.CFrame = Original.CFrame
			else
				RemoveObject(Original)
			end
		end
	end)

	--Let the world load before starting
	wait(1)

	local function HandleChar()
		--warn("Handle char")

		table.clear(RenderObjects)
		local lastChar = ViewPort:FindFirstChildOfClass("Model")
		if lastChar then
			lastChar:Destroy()
		end

		local Viewmodel = Instance.new("Model")
		Viewmodel.Name = "PlayerViewmodel"
		Viewmodel.Parent = ViewPort

		local CharObjects = Character:GetDescendants()
		for i, Object in pairs(CharObjects) do
			local RenderClone = AddObject(Object)
			if RenderClone then
				RenderClone.Parent = Viewmodel
			end
		end

		Character.DescendantAdded:Connect(function(NewObject)
			local RenderClone = AddObject(NewObject)
			if RenderClone then
				RenderClone.Parent = Viewmodel
			end
		end)
		Character.DescendantRemoving:Connect(function(OldObject)
			RemoveObject(OldObject)
		end)
	end

	--Render the character

	Player.CharacterAdded:Connect(function(NewCharacter)
		wait(0.25) -- wait for character to finish loading
		Character = NewCharacter

		HandleChar()
	end)

	HandleChar()
end

return Equipment
