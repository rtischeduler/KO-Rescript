local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local levelUpdateRemote = ReplicatedStorage:WaitForChild("LevelUpdate")

local levelLabel = script.Parent:FindFirstChild("Level")
local xpLabel = script.Parent:FindFirstChild("XP")

local bars = script.Parent:FindFirstChild("Bars")
local levelBar = bars and bars:FindFirstChild("LevelBar")
local levelBarFill = levelBar and levelBar:FindFirstChild("Fill")
local levelBarText = levelBar and levelBar:FindFirstChild("Text")

local currentKaiju = nil
local currentLevel = 1
local currentXP = 0
local currentXPNeeded = 0

local LevelManager = require(ReplicatedStorage:WaitForChild("LevelManager"))

local function getMaxLevel()
	return LevelManager.GetMaxLevel(currentKaiju)
end

local function updateDisplay()
	local maxLevel = getMaxLevel()
	local isMaxed = currentLevel >= maxLevel

	if levelLabel then
		if isMaxed then
			levelLabel.Text = "Level " .. tostring(currentLevel) .. " (MAX)"
		else
			levelLabel.Text = "Level: " .. tostring(currentLevel)
		end
	end
	if xpLabel then
		if isMaxed then
			xpLabel.Text = "XP: MAX"
		else
			xpLabel.Text = "XP: " .. tostring(currentXP)
		end
	end

	if levelBarFill then
		if isMaxed then
			levelBarFill.Size = UDim2.new(1, 0, 1, 0)
		else
			local xpNeeded = currentXPNeeded
			if xpNeeded <= 0 then
				xpNeeded = LevelManager.GetXPForNextLevel(currentLevel, currentKaiju)
			end
			if xpNeeded > 0 then
				local xpPct = math.clamp(currentXP / xpNeeded, 0, 1)
				levelBarFill.Size = UDim2.new(xpPct, 0, 1, 0)
			end
		end
	end
	if levelBarText then
		if isMaxed then
			levelBarText.Text = "Lvl. " .. tostring(currentLevel) .. " (MAX)"
		else
			local xpNeeded = currentXPNeeded
			if xpNeeded <= 0 then
				xpNeeded = LevelManager.GetXPForNextLevel(currentLevel, currentKaiju)
			end
			levelBarText.Text = "Lvl. " .. tostring(currentLevel) .. " (" .. tostring(currentXP) .. "/" .. tostring(xpNeeded) .. ")"
		end
	end
end
levelUpdateRemote.OnClientEvent:Connect(function(data)
	if data then
		currentKaiju = data.kaiju
		currentLevel = data.level
		currentXP = data.xp
		currentXPNeeded = data.xpNeeded or 0

		updateDisplay()

		if data.levelUp then

			print("LEVEL UP! Now level", currentLevel)
		end
	end
end)

local function checkForKaiju()
	local character = player.Character
	if character then
		local kaijuString = character:FindFirstChild("Kaiju")
		if kaijuString and kaijuString:IsA("StringValue") then
			currentKaiju = kaijuString.Value
		end
	end
end

player.CharacterAdded:Connect(function(character)
	character.ChildAdded:Connect(function(child)
		if child.Name == "Kaiju" and child:IsA("StringValue") then
			currentKaiju = child.Value
		end
	end)

	checkForKaiju()
end)

if player.Character then
	checkForKaiju()
end

updateDisplay()
