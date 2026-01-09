local create = game.ReplicatedStorage:WaitForChild("Mining"):WaitForChild("weak spot"):WaitForChild("createWeakSpot")
local delete = game.ReplicatedStorage:WaitForChild("Mining"):WaitForChild("weak spot"):WaitForChild("deleteWeakSpot")
local lineAnim = game.ReplicatedStorage:WaitForChild("Mining"):WaitForChild("weak spot"):WaitForChild("lineAnimation")
local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local weakSpot

create.OnClientEvent:Connect(function(weakSpotData: table)
	weakSpot = Instance.new("Part")
	for key, value in pairs(weakSpotData) do
		pcall(function()
			weakSpot[key] = value
		end)
	end
end)

delete.OnClientEvent:Connect(function()
	if not weakSpot then
		warn("Weak spot not found wasnt created yet cant delete", debug.traceback("", 2))
		return
	end

	weakSpot:Destroy()
end)

lineAnim.OnClientEvent:Connect(function(pos0, pos1)
	-- create the beam part
	local beamPart = Instance.new("Part")
	beamPart.Anchored = true
	beamPart.CanCollide = false
	beamPart.Shape = Enum.PartType.Cylinder
	beamPart.Transparency = 1 -- fully invisible (SurfaceGuis will still show!)
	beamPart.Size = Vector3.new(0.1, 0.1, (pos0 - pos1).Magnitude)
	beamPart.CFrame = CFrame.new(pos0, pos1) * CFrame.new(0, 0, -beamPart.Size.Z / 2) -- position + rotation
	beamPart.Parent = workspace

	-- put SurfaceGuis on each face
	for _, face in Enum.NormalId:GetEnumItems() do
		local surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Face = face
		surfaceGui.Adornee = beamPart
		surfaceGui.AlwaysOnTop = true
		surfaceGui.Parent = beamPart
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.Parent = surfaceGui
	end

	-- animate movement
	local t = 1
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		t += deltaTime
		local distance = pos0 - pos1
		local dir = distance.Unit
		local step = dir * 0.15 * math.pow(t, 2)

		if distance.Magnitude <= step.Magnitude then
			-- clean up
			beamPart:Destroy()
			connection:Disconnect()
			return
		end

		pos0 = pos0 - step
		-- recompute beamPart’s position/rotation/size
		beamPart.Size = Vector3.new(0.1, 0.1, (pos0 - pos1).Magnitude)
		beamPart.CFrame = CFrame.new(pos0, pos1) * CFrame.new(0, 0, -beamPart.Size.Z / 2)
	end)
end)

--[[
local part0
local part1
lineAnim.OnClientEvent:Connect(function(pos0, pos1)
	--Parts
	part0 = Instance.new("Part")
	--part0.CanQuery = false
	part0.CanCollide = false
	part0.Anchored = true
	part0.Transparency = 1
	part0.Position = pos0
	part0.Size = Vector3.new(0.5,0.5,0.5)
	part0.Parent = workspace

	part1 = Instance.new("Part")
	--part1.CanQuery = false
	part1.CanCollide = false
	part1.Anchored = true
	part1.Transparency = 1
	part1.Position = pos1
	part0.Size = Vector3.new(0.5,0.5,0.5)
	part1.Parent = workspace


	--Attachments
	local att0 = Instance.new("Attachment", part0)
	local att1 = Instance.new("Attachment", part1)


	--beam
	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.FaceCamera = true
	beam.Width0 = 0.1
	beam.Width1 = 0.1
	beam.ZOffset = 1.1
	beam.Parent = workspace

	part0.Position = pos0
	part1.Position = pos1

	local t = 1
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		t += deltaTime
		local distance = part0.Position - part1.Position
		local dir = distance.Unit
		local step = dir * 0.15 * math.pow(t,2)

		if distance.Magnitude <= step.Magnitude then
			--clean up
			beam:Destroy()
			part0:Destroy()
			part1:Destroy()
			connection:Disconnect()
			return
		end

		part0.Position = part0.Position - step
	end)
end)
]]
