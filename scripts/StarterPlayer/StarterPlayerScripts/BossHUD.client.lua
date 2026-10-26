local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local bossEvent = ReplicatedStorage:WaitForChild("BossEvent")


local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BossHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Enabled = false
screenGui.Parent = player:WaitForChild("PlayerGui")


local container = Instance.new("Frame")
container.Size = UDim2.new(0, 700, 0, 50)
container.Position = UDim2.new(0.5, -350, 0, 10)
container.BackgroundTransparency = 1
container.Parent = screenGui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 20)
layout.Parent = container


local greenText = Instance.new("TextLabel")
greenText.Size = UDim2.new(0, 400, 0, 50)
greenText.BackgroundTransparency = 1
greenText.Text = ""
greenText.TextColor3 = Color3.fromRGB(0, 255, 85)
greenText.TextScaled = true
greenText.Font = Enum.Font.GothamBold
greenText.TextXAlignment = Enum.TextXAlignment.Center
greenText.Parent = container

local greenStroke = Instance.new("UIStroke")
greenStroke.Thickness = 2
greenStroke.Color = Color3.fromRGB(0, 0, 0)
greenStroke.Parent = greenText


local goldText = Instance.new("TextLabel")
goldText.Size = UDim2.new(0, 280, 0, 50)
goldText.BackgroundTransparency = 1
goldText.Text = ""
goldText.TextColor3 = Color3.fromRGB(255, 215, 0)
goldText.TextScaled = true
goldText.Font = Enum.Font.GothamBold
goldText.TextXAlignment = Enum.TextXAlignment.Left
goldText.Parent = container

local goldStroke = Instance.new("UIStroke")
goldStroke.Thickness = 2
goldStroke.Color = Color3.fromRGB(0, 0, 0)
goldStroke.Parent = goldText

local sessionToken = 0

bossEvent.OnClientEvent:Connect(function(action, ...)
	if action == "start" then
		sessionToken = sessionToken + 1
		local bossName = ...
		greenText.Text = bossName .. " is now the boss!"
		goldText.Text = "Top Damage Dealer: None"
		screenGui.Enabled = true
	elseif action == "update" then
		local playerName, percentage = ...
		if playerName == "None" or playerName == nil then
			goldText.Text = "Top Damage Dealer: None"
		else
			goldText.Text = "Top Damage Dealer: " .. tostring(playerName) .. " (" .. tostring(percentage) .. "%)"
		end
	elseif action == "end" then
		sessionToken = sessionToken + 1
		local myToken = sessionToken
		local winnerName = ...
		greenText.Text = "The boss has been defeated, " .. tostring(winnerName) .. " has won with the most damage!"
		goldText.Text = ""
		task.delay(10, function()
			if sessionToken == myToken then
				screenGui.Enabled = false
			end
		end)
	end
end)
