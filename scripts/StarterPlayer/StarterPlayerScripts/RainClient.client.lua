local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local rainTemplate = ReplicatedStorage:WaitForChild("Rain")
local toggleEvent = ReplicatedStorage:WaitForChild("ToggleRain")

local rainClone = nil
local renderConn = nil

local RAIN_OFFSET = Vector3.new(0, 60, 0)

local function startRain()
	if rainClone then return end

	rainClone = rainTemplate:Clone()
	rainClone.Parent = Workspace
	for _, child in rainClone:GetChildren() do
		if child:IsA("ParticleEmitter") then
			child.Enabled = true
		end
	end


	local sound = rainClone:FindFirstChild("Raining")
	if sound then
		sound:Play()
	end
	renderConn = RunService.RenderStepped:Connect(function()
		if not rainClone or not rainClone.Parent then
			renderConn:Disconnect()
			renderConn = nil
			return
		end

		local camera = Workspace.CurrentCamera
		if camera then
			rainClone.CFrame = CFrame.new(camera.CFrame.Position + RAIN_OFFSET)
		end
	end)
end

local function stopRain()
	if renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end

	if rainClone then
		local sound = rainClone:FindFirstChild("Raining")
		if sound then
			sound:Stop()
		end

		rainClone.Parent = nil
		rainClone = nil
	end
end

toggleEvent.OnClientEvent:Connect(function(isRaining)
	if isRaining then
		startRain()
	else
		stopRain()
	end
end)
