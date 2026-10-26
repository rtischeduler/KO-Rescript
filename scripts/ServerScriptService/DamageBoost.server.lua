local Players = game:GetService("Players")

local BOOST_KAIJU = {
	[string.lower("GOJIRA [FREE]")] = true,
	[string.lower("SHIN FORM 2 [FREE]")] = true,
	[string.lower("SHIN FORM 3")] = true,
	[string.lower("ANGUIRUS [FREE]")] = true,
}

local HEALTH_THRESHOLD = 0.25
local DMG_STAT_NAMES = {"DMG1", "DMG2", "DMG3", "DMG4"}

local boostedChars = {}

local function setupBoostMonitor(character)
	local kaijuVal = character:FindFirstChild("Kaiju")
	if not kaijuVal then
		local tryCount = 0
		while not kaijuVal and tryCount < 20 do
			task.wait(0.1)
			if not character or not character.Parent then return end
			kaijuVal = character:FindFirstChild("Kaiju")
			tryCount = tryCount + 1
		end
	end
	if not kaijuVal or not kaijuVal:IsA("StringValue") then return end

	print("[DamageBoost] Detected kaiju: " .. kaijuVal.Value)

	if not BOOST_KAIJU[string.lower(kaijuVal.Value)] then return end

	print("[DamageBoost] " .. kaijuVal.Value .. " is in the boost list! Setting up health monitor.")

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local stats = character:FindFirstChild("Stats")
	if not stats then return end

	local originalDMG = {}
	for _, statName in ipairs(DMG_STAT_NAMES) do
		local stat = stats:FindFirstChild(statName)
		if stat and stat:IsA("NumberValue") then
			originalDMG[statName] = stat.Value
		end
	end

	if next(originalDMG) == nil then
		print("[DamageBoost] WARNING: No DMG stats found for " .. kaijuVal.Value)
		return
	end

	print("[DamageBoost] Stored original DMG: DMG1=" .. tostring(originalDMG.DMG1) .. " DMG2=" .. tostring(originalDMG.DMG2) .. " DMG3=" .. tostring(originalDMG.DMG3))

	local function applyBoost()
		if boostedChars[character] then return end
		boostedChars[character] = true

		for statName, origVal in pairs(originalDMG) do
			local stat = stats:FindFirstChild(statName)
			if stat and stat:IsA("NumberValue") then
				stat.Value = origVal * 2
			end
		end
		print("[DamageBoost] " .. kaijuVal.Value .. " below 25% HP - damage doubled! DMG1 now: " .. tostring(stats.DMG1.Value))
	end

	local function removeBoost()
		if not boostedChars[character] then return end
		boostedChars[character] = nil

		for statName, origVal in pairs(originalDMG) do
			local stat = stats:FindFirstChild(statName)
			if stat and stat:IsA("NumberValue") then
				stat.Value = origVal
			end
		end
		print("[DamageBoost] " .. kaijuVal.Value .. " healed above 25% HP - damage reverted.")
	end

	local function checkHealth(newHealth)
		if not character or not character.Parent then return end
		if humanoid.Health <= 0 then return end

		local maxHP = humanoid.MaxHealth
		if maxHP <= 0 then return end

		local threshold = maxHP * HEALTH_THRESHOLD

		if newHealth <= threshold then
			applyBoost()
		else
			removeBoost()
		end
	end

	task.wait(2)
	if character and character.Parent and humanoid.Health > 0 then
		print("[DamageBoost] Initial check: HP=" .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth))
		checkHealth(humanoid.Health)
	end

	humanoid.HealthChanged:Connect(checkHealth)

	character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			boostedChars[character] = nil
		end
	end)
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		task.spawn(function()
			setupBoostMonitor(character)
		end)
	end)

	if player.Character then
		task.spawn(function()
			setupBoostMonitor(player.Character)
		end)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

print("[DamageBoost] Server script loaded. Monitoring: Gojira, Shin Form 2, Shin Form 3, Anguirus")