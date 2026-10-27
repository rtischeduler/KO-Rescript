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

	fovValue.Changed:Connect(function()
		saveRemote:InvokeServer(fovValue.Value)
	end)

	local savedFOV = saveRemote:InvokeServer()

	local function applyFOV()
		local camera = Workspace.CurrentCamera
		if camera and savedFOV then
			camera.FieldOfView = savedFOV

			local clampedNumber = math.clamp(savedFOV, cfg.MinFov, cfg.MaxFov)
			local calculatedSize = (clampedNumber - cfg.MinFov) / (cfg.MaxFov - cfg.MinFov)
			fovSlider.Size = UDim2.fromScale(calculatedSize, 1)
			fovShowcase.Text = tostring(savedFOV)
		end
	end

	applyFOV()

	player.CharacterAdded:Connect(function()
		task.wait()
		applyFOV()
	end)
end

return SettingsController
