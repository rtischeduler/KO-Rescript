local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

repeat task.wait()
	Camera.CameraType = Enum.CameraType.Scriptable
until Camera.CameraType == Enum.CameraType.Scriptable

local camPoints = workspace:WaitForChild("CamPoints")
local menuCam = camPoints:WaitForChild("Menu")
Camera.CFrame = menuCam.CFrame

local MainFrame = script.Parent:WaitForChild("MainFrame")
local Selection = MainFrame:WaitForChild("Selection")
local StatsWindow = Selection:WaitForChild("StatsWindow")
local PlayButton = StatsWindow:WaitForChild("Play")

PlayButton.MouseButton1Click:Connect(function()
	Camera.CameraType = Enum.CameraType.Custom
end)
