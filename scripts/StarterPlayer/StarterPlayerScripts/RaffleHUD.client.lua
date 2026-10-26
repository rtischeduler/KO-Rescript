local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local raffleEvent = ReplicatedStorage:WaitForChild("RaffleEvent")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RaffleHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Enabled = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.5
backdrop.Parent = screenGui

local card = Instance.new("Frame")
card.Size = UDim2.new(0, 500, 0, 200)
card.Position = UDim2.new(0.5, -250, 0.5, -100)
card.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
card.BorderSizePixel = 0
card.Parent = backdrop

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = card

local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Color = Color3.fromRGB(255, 215, 0)
stroke.Parent = card

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, 0, 0, 50)
titleText.Position = UDim2.new(0, 0, 0, 15)
titleText.BackgroundTransparency = 1
titleText.Text = "RAFFLE"
titleText.TextColor3 = Color3.fromRGB(255, 215, 0)
titleText.TextScaled = true
titleText.Font = Enum.Font.GothamBlack
titleText.Parent = card

local nameText = Instance.new("TextLabel")
nameText.Size = UDim2.new(1, -20, 0, 80)
nameText.Position = UDim2.new(0, 10, 0, 70)
nameText.BackgroundTransparency = 1
nameText.Text = ""
nameText.TextColor3 = Color3.fromRGB(255, 255, 255)
nameText.TextScaled = true
nameText.Font = Enum.Font.GothamBold
nameText.Parent = card

local winnerStroke = Instance.new("UIStroke")
winnerStroke.Thickness = 2
winnerStroke.Color = Color3.fromRGB(255, 215, 0)
winnerStroke.Parent = nameText

local isRunning = false

raffleEvent.OnClientEvent:Connect(function(names, winnerName)
	if isRunning then return end
	isRunning = true
	
	screenGui.Enabled = true
	nameText.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameText.Text = ""
	
	if #names < 2 then
		nameText.Text = winnerName .. " is the winner!"
		nameText.TextColor3 = Color3.fromRGB(255, 215, 0)
		task.wait(6)
		screenGui.Enabled = false
		isRunning = false
		return
	end
	
	
	
	local totalDuration = 4.5
	local elapsed = 0
	local interval = 0.04
	local lastIndex = 0
	
	task.spawn(function()
		while elapsed < totalDuration do
			lastIndex = lastIndex + 1
			if lastIndex > #names then lastIndex = 1 end
			nameText.Text = names[lastIndex]
			
			task.wait(interval)
			elapsed = elapsed + interval
			
			
			local progress = elapsed / totalDuration
			interval = 0.04 + (progress * progress) * 0.35
		end
		
		
		nameText.Text = winnerName
		nameText.TextColor3 = Color3.fromRGB(255, 215, 0)
		
		
		for i = 1, 3 do
			nameText.TextSize = 60
			task.wait(0.15)
			nameText.TextSize = 50
			task.wait(0.15)
		end
		
		nameText.Text = winnerName .. " is the winner!"
		nameText.TextColor3 = Color3.fromRGB(255, 215, 0)
		
		task.wait(5)
		screenGui.Enabled = false
		isRunning = false
	end)
end)
