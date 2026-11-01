local HudController = { Name = "Hud" }

local function startBossHud(cfg)
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
			task.delay(cfg.BossEndSeconds, function()
				if sessionToken == myToken then
					screenGui.Enabled = false
				end
			end)
		end
	end)
end

local function startRaffleHud()
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
		if isRunning then
			return
		end
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
				if lastIndex > #names then
					lastIndex = 1
				end
				nameText.Text = names[lastIndex]

				task.wait(interval)
				elapsed = elapsed + interval

				local progress = elapsed / totalDuration
				interval = 0.04 + (progress * progress) * 0.35
			end

			nameText.Text = winnerName
			nameText.TextColor3 = Color3.fromRGB(255, 215, 0)

			for _ = 1, 3 do
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
end

local function startBlindEffect(cfg)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local TweenService = game:GetService("TweenService")
	local Players = game:GetService("Players")

	local blindEvent = ReplicatedStorage:WaitForChild("BlindPulse")
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local isBlind = false

	blindEvent.OnClientEvent:Connect(function()
		if isBlind then
			return
		end
		isBlind = true

		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "BlindOverlay"
		screenGui.IgnoreGuiInset = true
		screenGui.ResetOnSpawn = false
		screenGui.DisplayOrder = 9999
		screenGui.Parent = playerGui

		local flashFrame = Instance.new("Frame")
		flashFrame.Size = UDim2.new(1, 0, 1, 0)
		flashFrame.Position = UDim2.new(0, 0, 0, 0)
		flashFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		flashFrame.BorderSizePixel = 0
		flashFrame.Parent = screenGui

		task.wait(cfg.BlindHoldSeconds)

		local tweenInfo = TweenInfo.new(cfg.BlindFadeSeconds, Enum.EasingStyle.Linear)
		local tween = TweenService:Create(flashFrame, tweenInfo, { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()

		screenGui:Destroy()
		isBlind = false
	end)
end

local function startHideOwnTag()
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer

	local function hideTagIfMatch(instance)
		if instance.Name == "Tag" and instance:IsA("BillboardGui") then
			instance.Enabled = false
		end
	end

	local function hideOwnTag(character)
		for _, descendant in character:GetDescendants() do
			hideTagIfMatch(descendant)
		end

		character.DescendantAdded:Connect(hideTagIfMatch)
	end

	localPlayer.CharacterAdded:Connect(function(character)
		hideOwnTag(character)
	end)

	if localPlayer.Character then
		hideOwnTag(localPlayer.Character)
	end
end

function HudController:Start()
	local framework = script:FindFirstAncestor("Client")
	local cfg = require(framework.Config).Hud
	local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Util"))
	local log = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Logger")).new("Hud")

	Util.spawn(log, "BossHud", startBossHud, cfg)
	Util.spawn(log, "RaffleHud", startRaffleHud)
	Util.spawn(log, "BlindEffect", startBlindEffect, cfg)
	Util.spawn(log, "HideOwnTag", startHideOwnTag)
end

return HudController
