local Players = game:GetService("Players")
local player = Players.LocalPlayer

local replicatedStorage = game:GetService("ReplicatedStorage")
local saveRemote = replicatedStorage:WaitForChild("GetSettingsData")

local playerGUI = player.PlayerGui
local settingsGui = playerGUI:WaitForChild("NEWMenu"):FindFirstChild("Settings"):FindFirstChild("SettingsPanel")
local fovValue = settingsGui:FindFirstChild("FOVUpdater"):FindFirstChild("FOV")
local fovShowcase = settingsGui:FindFirstChild("FOVText")

local fovSlider = settingsGui:FindFirstChild("FOVBack"):FindFirstChild("FOVFront")

local fov = game.Workspace.CurrentCamera.FieldOfView

local function sendToServer()
	saveRemote:InvokeServer(fovValue.Value)
end

fovValue.Changed:Connect(function()
	sendToServer()	
end)

local savedFOV = saveRemote:InvokeServer()

local function applyFOV()
	local camera = game.Workspace.CurrentCamera
	if camera and savedFOV then
		camera.FieldOfView = savedFOV
		
		local clampedNumber = math.clamp(savedFOV, 70, 120)
		local calculatedSize = (clampedNumber - 70) / (120 - 70)
		fovSlider.Size = UDim2.fromScale(calculatedSize,1)
		fovShowcase.Text = tostring(savedFOV)
	end
end

applyFOV()

player.CharacterAdded:Connect(function()
	task.wait()
	applyFOV()
end)