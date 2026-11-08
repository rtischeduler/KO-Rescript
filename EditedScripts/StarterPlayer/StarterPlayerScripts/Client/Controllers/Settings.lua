local SettingsController = { Name = "Settings" }

function SettingsController:Start()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Workspace = game:GetService("Workspace")
	local cfg = require(script:FindFirstAncestor("Client").Config).Settings

	local player = Players.LocalPlayer
	local saveRemote = ReplicatedStorage:WaitForChild("GetSettingsData")

	local settingsGui = player.PlayerGui:WaitForChild("NEWMenu"):FindFirstChild("Settings"):FindFirstChild("SettingsPanel")
	local fovValue = settingsGui:FindFirstChild("FOVUpdater"):FindFirstChild("FOV")
	local fovShowcase = settingsGui:FindFirstChild("FOVText")
	local fovSlider = settingsGui:FindFirstChild("FOVBack"):FindFirstChild("FOVFront")

	local currentFOV = saveRemote:InvokeServer()
	local lastSaved = currentFOV
	local saveQueued = false

	local function toFov(raw)
		return math.clamp(math.round(raw > 10 and raw or raw * 100), cfg.MinFov, cfg.MaxFov)
	end

	local function showFOV(fov)
		local camera = Workspace.CurrentCamera
		if camera then
			camera.FieldOfView = fov
		end
		fovSlider.Size = UDim2.fromScale((fov - cfg.MinFov) / (cfg.MaxFov - cfg.MinFov), 1)
		fovShowcase.Text = tostring(fov)
	end

	fovValue.Changed:Connect(function()
		currentFOV = toFov(fovValue.Value)
		showFOV(currentFOV)
		if currentFOV == lastSaved or saveQueued then
			return
		end
		saveQueued = true
		task.delay(0.5, function()
			saveQueued = false
			lastSaved = currentFOV
			saveRemote:InvokeServer(currentFOV)
		end)
	end)

	if type(currentFOV) == "number" then
		currentFOV = toFov(currentFOV)
		showFOV(currentFOV)
		fovValue.Value = currentFOV / 100
	end

	player.CharacterAdded:Connect(function()
		task.wait()
		if type(currentFOV) == "number" then
			showFOV(currentFOV)
		end
	end)
end

return SettingsController
