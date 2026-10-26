local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local blindEvent = ReplicatedStorage:WaitForChild("BlindPulse")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local isBlind = false

blindEvent.OnClientEvent:Connect(function()
	if isBlind then return end
	isBlind = true

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BlindOverlay"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 9999
	screenGui.Parent = playerGui

	local blackFrame = Instance.new("Frame")
	blackFrame.Size = UDim2.new(1, 0, 1, 0)
	blackFrame.Position = UDim2.new(0, 0, 0, 0)
	blackFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	blackFrame.BorderSizePixel = 0
	blackFrame.Parent = screenGui
	
	task.wait(5)

	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(blackFrame, tweenInfo, { BackgroundTransparency = 1 })
	tween:Play()
	tween.Completed:Wait()

	screenGui:Destroy()
	isBlind = false
end)