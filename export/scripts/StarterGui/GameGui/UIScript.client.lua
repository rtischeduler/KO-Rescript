local toggleableFrames = {
	"LightingFX",
	"Colors",
	"ResetStats",
	"BuyGCellWindow",
	"Relic"
}

local function hideAllFramesExcept(exceptFrame)
	for _, frameName in ipairs(toggleableFrames) do
		local frame = script.Parent.MainFrame.Interface:FindFirstChild(frameName)
		if frame and frameName ~= exceptFrame then
			frame.Visible = false
		end
	end
end

script.Parent.MainFrame.Interface.LightingEffects.mouseButton1Click:Connect(function()
	hideAllFramesExcept("LightingFX")
	if script.Parent.MainFrame.Interface.LightingFX.Visible == true then
		script.Parent.MainFrame.Interface.LightingFX.Visible = false
	else
		script.Parent.MainFrame.Interface.LightingFX.Visible = true
	end
end)

script.Parent.MainFrame.Interface.Reset.mouseButton1Click:Connect(function()
	hideAllFramesExcept("ResetStats")
	if script.Parent.MainFrame.Interface.ResetStats.Visible == true then
		script.Parent.MainFrame.Interface.ResetStats.Visible = false
	else
		script.Parent.MainFrame.Interface.ResetStats.Visible = true
	end
end)

script.Parent.MainFrame.Interface.BuyGCells.mouseButton1Click:Connect(function()
	hideAllFramesExcept("BuyGCellWindow")
	if script.Parent.MainFrame.Interface.BuyGCellWindow.Visible == true then
		script.Parent.MainFrame.Interface.BuyGCellWindow.Visible = false
	else
		script.Parent.MainFrame.Interface.BuyGCellWindow.Visible = true
	end
end)

function playClickSound()
	local clickSound = script.Parent:FindFirstChild("Button")
	if clickSound then
		clickSound:Play()
	end
end

for _, descendant in script.Parent:GetDescendants() do
	if descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
		descendant.MouseButton1Click:Connect(playClickSound)
	end
end

local function getGCellsValue()
	local player = game.Players.LocalPlayer
	if not player then return nil end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return nil end

	local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
	if gcells then
		return gcells.Value
	end
	return nil
end

local function getCharacterStats()
	local player = game.Players.LocalPlayer
	if not player then return nil end

	local character = player.Character
	if not character then return nil end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local stats = character:FindFirstChild("Stats")

	return {
		health = humanoid and humanoid.Health or nil,
		maxHealth = humanoid and humanoid.MaxHealth or nil,
		walkSpeed = humanoid and humanoid.WalkSpeed or nil,
		dmg = stats and stats:FindFirstChild("DMG1") and stats.DMG1.Value or nil,
		defense = stats and stats:FindFirstChild("Defense") and stats.Defense.Value or nil
	}
end

local function getLevelAndXP()
	local player = game.Players.LocalPlayer
	if not player then return nil, nil end

	local character = player.Character
	if not character then return nil, nil end

	local levelVal = character:FindFirstChild("Level")
	local xpVal = character:FindFirstChild("XP")

	return levelVal and levelVal.Value or nil, xpVal and xpVal.Value or nil
end

local LevelManager = require(game.ReplicatedStorage:WaitForChild("LevelManager"))

local function getKaijuName()
	local player = game.Players.LocalPlayer
	if not player then return nil end
	local character = player.Character
	if not character then return nil end
	local kaijuVal = character:FindFirstChild("Kaiju")
	if kaijuVal and kaijuVal:IsA("StringValue") then
		return kaijuVal.Value
	end
	return nil
end

while task.wait(0.8) do

	local gcellsValue = getGCellsValue()
	if gcellsValue then
		script.Parent.MainFrame.Interface.GCells.Text = "GCells: "..tostring(gcellsValue)
	end

	local stats = getCharacterStats()
	if stats then
		if stats.health and stats.maxHealth then
			script.Parent.MainFrame.Interface.Stats.HP.TextLabel.Text = tostring(math.floor(stats.health))

			local bars = script.Parent.MainFrame.Interface:FindFirstChild("Bars")
			if bars then
				local healthBar = bars:FindFirstChild("HealthBar")
				if healthBar then
					local fill = healthBar:FindFirstChild("Fill")
					local text = healthBar:FindFirstChild("Text")
					local healthPct = math.clamp(stats.health / stats.maxHealth, 0, 1)
					if fill then
						fill.Size = UDim2.new(healthPct, 0, 1, 0)
					end
					if text then
						text.Text = "HP: " .. tostring(math.floor(stats.health)) .. "/" .. tostring(math.floor(stats.maxHealth))
					end
				end
			end
		end
		if stats.walkSpeed then
			script.Parent.MainFrame.Interface.Stats2.Speed.TextLabel.Text = tostring(stats.walkSpeed)
		end
		if stats.dmg then
			script.Parent.MainFrame.Interface.Stats2.DMG.TextLabel.Text = tostring(stats.dmg)
		end
		if stats.defense then
			script.Parent.MainFrame.Interface.Stats2.Defense.TextLabel.Text = tostring(stats.defense)
		end
	end

	local level, xp = getLevelAndXP()
	local kaijuName = getKaijuName()
	local maxLevel = LevelManager.GetMaxLevel(kaijuName)
	local isMaxed = level and level >= maxLevel
	if level then
		local xpNeeded = LevelManager.GetXPForNextLevel(level, kaijuName)

		if isMaxed then
			script.Parent.MainFrame.Interface.Level.Text = "Level "..tostring(level).." (MAX)"
		else
			script.Parent.MainFrame.Interface.Level.Text = "Level: "..tostring(level)
		end

		local bars = script.Parent.MainFrame.Interface:FindFirstChild("Bars")
		if bars then
			local levelBar = bars:FindFirstChild("LevelBar")
			if levelBar then
				local fill = levelBar:FindFirstChild("Fill")
				local text = levelBar:FindFirstChild("Text")
				if isMaxed then
					if fill then
						fill.Size = UDim2.new(1, 0, 1, 0)
					end
					if text then
						text.Text = "Lvl. " .. tostring(level) .. " (MAX)"
					end
				else
					if fill and xpNeeded > 0 then
						local xpPct = math.clamp((xp or 0) / xpNeeded, 0, 1)
						fill.Size = UDim2.new(xpPct, 0, 1, 0)
					end
					if text then
						text.Text = "Lvl. " .. tostring(level) .. " (" .. tostring(xp or 0) .. "/" .. tostring(xpNeeded) .. ")"
					end
				end
			end
		end
	end
	if xp then
		if level and isMaxed then
			script.Parent.MainFrame.Interface.XP.Text = "XP: MAX"
		else
			script.Parent.MainFrame.Interface.XP.Text = "XP: "..tostring(xp)
		end
	end
end
