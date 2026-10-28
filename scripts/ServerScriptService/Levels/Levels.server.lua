local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelManager = require(ReplicatedStorage:WaitForChild("LevelManager"))
local LevelDataStore = DataStoreService:GetDataStore("PlayerLevels_v3")
local ModifierDataStore = DataStoreService:GetDataStore("PlayerModifiers_v1")

local levelUpdateRemote = ReplicatedStorage:FindFirstChild("LevelUpdate")
if not levelUpdateRemote then
	levelUpdateRemote = Instance.new("RemoteEvent")
	levelUpdateRemote.Name = "LevelUpdate"
	levelUpdateRemote.Parent = ReplicatedStorage
end

local ServerStorage = game:GetService("ServerStorage")
local levelChangedEvent = ServerStorage:FindFirstChild("LevelChanged")
if not levelChangedEvent then
	levelChangedEvent = Instance.new("BindableEvent")
	levelChangedEvent.Name = "LevelChanged"
	levelChangedEvent.Parent = ServerStorage
end

local player = Players:GetPlayerFromCharacter(script.Parent)
local character = script.Parent

local levelValue = Instance.new("IntValue")
levelValue.Name = "Level"
levelValue.Value = 1
levelValue.Parent = character

local xpValue = Instance.new("IntValue")
xpValue.Name = "XP"
xpValue.Value = 0
xpValue.Parent = character

local addXPEvent = Instance.new("BindableEvent")
addXPEvent.Name = "AddXP"
addXPEvent.Parent = character

local kaijuName = "Unknown"
local kaijuValue = character:FindFirstChild("Kaiju")
if kaijuValue and kaijuValue:IsA("StringValue") then
	kaijuName = kaijuValue.Value
end

local hitDebounce = {}

local cachedData = nil
local dataDirty = false
local lastSaveTime = 0
local SAVE_INTERVAL = 15
local playerModifiers = {Damage = 0, Health = 0, Regen = 0, Speed = 0}

local MULTIPLIERS = {
	Damage = 0.1,
	Health = 0.1,
	Regen = 0.15,
	Speed = 0.05,
}

local MINILLA_MULTIPLIERS = {
	Damage = 0.15,
	Health = 0.15,
	Regen = 0.3,
	Speed = 0.055,
}

local fullPlayerData = nil

local function getPlayerData(p)
	if cachedData then
		return cachedData
	end

	local success, data = pcall(function()
		return LevelDataStore:GetAsync("Player_" .. p.UserId)
	end)

	if success and data and type(data) == "table" then
		fullPlayerData = data
		if data[kaijuName] then
			cachedData = data[kaijuName]
			if not cachedData.usedSkillPoints then
				cachedData.usedSkillPoints = 0
			end
		else
			cachedData = { level = 1, xp = 0, usedSkillPoints = 0 }
			fullPlayerData[kaijuName] = cachedData
		end
	else
		fullPlayerData = {}
		cachedData = { level = 1, xp = 0, usedSkillPoints = 0 }
		fullPlayerData[kaijuName] = cachedData
	end
	return cachedData
end

local function savePlayerData(p)
	if not fullPlayerData then return end

	fullPlayerData[kaijuName] = cachedData
	pcall(function()
		LevelDataStore:SetAsync("Player_" .. p.UserId, fullPlayerData)
	end)
	lastSaveTime = tick()
	dataDirty = false
end

local function applyHPBonus(level, fullHeal)
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	
	if character:GetAttribute("BossMode") then return end

	local baseMaxHP = humanoid:GetAttribute("BaseMaxHP")
	if not baseMaxHP then
		baseMaxHP = humanoid.MaxHealth
		humanoid:SetAttribute("BaseMaxHP", baseMaxHP)
	end

	local mults = (kaijuName == "MINILLA") and MINILLA_MULTIPLIERS or MULTIPLIERS
	local healthMult = 1 + (playerModifiers.Health or 0) * mults.Health
	local newMaxHP = math.floor(baseMaxHP * healthMult)
	humanoid.MaxHealth = newMaxHP

	
	if fullHeal then
		humanoid.Health = newMaxHP
	end
end

local function updateLeaderstatLevel(lvl)
	if not player then return end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local levelStat = leaderstats:FindFirstChild("Level")
		if levelStat then
			levelStat.Value = lvl
		end
	end
end

local function addXP(amount)
	if not player then return end

	local data = getPlayerData(player)
	local oldLevel = data.level
	local xpNeeded = LevelManager.GetXPForNextLevel(data.level, kaijuName)

	data.xp = data.xp + amount

	local leveledUp = false
	while data.xp >= xpNeeded and data.level < LevelManager.GetMaxLevel(kaijuName) do
		data.xp = data.xp - xpNeeded
		data.level = data.level + 1
		leveledUp = true
		xpNeeded = LevelManager.GetXPForNextLevel(data.level, kaijuName)
	end

	if data.level >= LevelManager.GetMaxLevel(kaijuName) then
		data.xp = 0
	end

	if levelValue and levelValue.Parent then
		levelValue.Value = data.level
	end
	if xpValue and xpValue.Parent then
		xpValue.Value = data.xp
	end

	if data.level ~= oldLevel then
		updateLeaderstatLevel(data.level)
	end

	if leveledUp then
		local levelUpTemplate = ReplicatedStorage:FindFirstChild("LevelUp")
		if levelUpTemplate then
			local targetPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
			if targetPart then
				local effectClone = levelUpTemplate:Clone()
				effectClone.Visible = true
				effectClone.Parent = targetPart
				for _, child in ipairs(effectClone:GetChildren()) do
					if child:IsA("ParticleEmitter") then
						child.Enabled = true
					end
				end
				local function fadeOut(effect)
					if not effect or effect:GetAttribute("Fading") then return end
					effect:SetAttribute("Fading", true)
					local life = 0.5
					for _, d in ipairs(effect:GetDescendants()) do
						if d:IsA("ParticleEmitter") then
							d.Rate = 0
							d.Enabled = false
							life = math.max(life, d.Lifetime.Max)
						end
					end
					task.delay(life + 0.25, function()
						pcall(function() effect:Destroy() end)
					end)
				end
				task.delay(2, function() fadeOut(effectClone) end)
				targetPart.Destroying:Connect(function()
					if effectClone.Parent ~= targetPart or effectClone:GetAttribute("Fading") then return end
					pcall(function()
						local ghost = Instance.new("Part")
						ghost.Anchored = true
						ghost.CanCollide = false
						ghost.CanQuery = false
						ghost.CanTouch = false
						ghost.Transparency = 1
						ghost.Size = Vector3.new(0.2, 0.2, 0.2)
						ghost.CFrame = targetPart.CFrame
						ghost.Parent = workspace
						effectClone.Parent = ghost
						fadeOut(effectClone)
						game:GetService("Debris"):AddItem(ghost, 12)
					end)
				end)
			end
		end
	end

	levelUpdateRemote:FireClient(player, {
		kaiju = kaijuName,
		level = data.level,
		xp = data.xp,
		xpNeeded = LevelManager.GetXPForNextLevel(data.level, kaijuName),
		levelUp = leveledUp
	})

	if leveledUp then
		levelChangedEvent:Fire(player.UserId, kaijuName, data.level)
	end

	dataDirty = true
end

addXPEvent.Event:Connect(function(amount)
	addXP(amount)
end)

local function isHitboxPart(partName)
	local lowerName = string.lower(partName)
	return lowerName:find("hitbox") or lowerName:find("beam") or lowerName:find("blast")
end

local function getPlayerFromPart(part)
	local char = part.Parent
	if char then
		return Players:GetPlayerFromCharacter(char)
	end
	return nil
end

local cachedHitboxes = {}

local function refreshHitboxCache()
	table.clear(cachedHitboxes)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") and isHitboxPart(descendant.Name) then
			table.insert(cachedHitboxes, descendant)
		end
	end
end

refreshHitboxCache()

character.DescendantAdded:Connect(function(desc)
	if desc:IsA("BasePart") and isHitboxPart(desc.Name) then
		table.insert(cachedHitboxes, desc)
	end
end)

character.DescendantRemoving:Connect(function(desc)
	for i, v in ipairs(cachedHitboxes) do
		if v == desc then
			table.remove(cachedHitboxes, i)
			break
		end
	end
end)

local overlapParams = OverlapParams.new()
overlapParams.FilterDescendantsInstances = {character}
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

local function startDetection()
	while character and character.Parent do
		task.wait(0.5)

		for _, hitbox in ipairs(cachedHitboxes) do
			if hitbox and hitbox.Parent then
				local touchingParts = workspace:GetPartsInPart(hitbox, overlapParams)

				for _, part in ipairs(touchingParts) do
					local hitPlayer = getPlayerFromPart(part)

					if hitPlayer and hitPlayer ~= player then
						local hitKey = hitbox.Name .. "_" .. hitPlayer.Name

						if not hitDebounce[hitKey] then
							hitDebounce[hitKey] = true

							
							local attackerLevel = levelValue and levelValue.Value or 1
							local targetChar = hitPlayer.Character
							local targetLevelVal = targetChar and targetChar:FindFirstChild("Level")
							local targetLevel = targetLevelVal and targetLevelVal.Value or 1

							if not (attackerLevel > 10 and targetLevel < 10) then
								addXP(math.random(10, 20))
							end

							task.delay(0.5, function()
								hitDebounce[hitKey] = nil
							end)
						end
					end
				end
			end
		end

		if dataDirty and (tick() - lastSaveTime) >= SAVE_INTERVAL then
			if cachedData then
				savePlayerData(player)
			end
		end
	end

	if dataDirty and cachedData and player then
		savePlayerData(player)
	end
end

local function initialize()
	if not player then return end

	local data = getPlayerData(player)

	if levelValue and levelValue.Parent then
		levelValue.Value = data.level
	end
	if xpValue and xpValue.Parent then
		xpValue.Value = data.xp
	end

	updateLeaderstatLevel(data.level)

	local modSuccess, modData = pcall(function()
		return ModifierDataStore:GetAsync("Player_" .. player.UserId)
	end)

	if modSuccess and modData and type(modData) == "table" and modData[kaijuName] then
		playerModifiers = modData[kaijuName]
		playerModifiers.Damage = playerModifiers.Damage or 0
		playerModifiers.Health = playerModifiers.Health or 0
		playerModifiers.Regen = playerModifiers.Regen or 0
		playerModifiers.Speed = playerModifiers.Speed or 0
	else
		playerModifiers = {Damage = 0, Health = 0, Regen = 0, Speed = 0}
	end

	character:SetAttribute("RegenModifier", playerModifiers.Regen or 0)

	local stats = character:FindFirstChild("Stats")
	if stats then
		---------------------------------------------------------
		-- NEW: Select correct multiplier table for Kaiju
		---------------------------------------------------------
		local mults = (kaijuName == "MINILLA") and MINILLA_MULTIPLIERS or MULTIPLIERS

		local damageMult = 1 + (playerModifiers.Damage or 0) * mults.Damage
		local regenMult = 1 + (playerModifiers.Regen or 0) * mults.Regen
		local speedMult = 1 + (playerModifiers.Speed or 0) * mults.Speed

		local dmg1 = stats:FindFirstChild("DMG1")
		if dmg1 then dmg1.Value = dmg1.Value * damageMult end
		local dmg2 = stats:FindFirstChild("DMG2")
		if dmg2 then dmg2.Value = dmg2.Value * damageMult end
		local dmg3 = stats:FindFirstChild("DMG3")
		if dmg3 then dmg3.Value = dmg3.Value * damageMult end

		local gpa = stats:FindFirstChild("GPA")
		if gpa then gpa.Value = gpa.Value * regenMult end

		local ws = stats:FindFirstChild("WS")
		if ws then ws.Value = ws.Value * speedMult end
		local ss = stats:FindFirstChild("SS")
		if ss then ss.Value = ss.Value * speedMult end
		local swimSpeed = stats:FindFirstChild("SwimSpeed")
		if swimSpeed then swimSpeed.Value = swimSpeed.Value * speedMult end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and ws then
			humanoid.WalkSpeed = ws.Value
		end
	end

	task.wait(0.1)
	applyHPBonus(data.level, true)

	levelUpdateRemote:FireClient(player, {
		kaiju = kaijuName,
		level = data.level,
		xp = data.xp,
		xpNeeded = LevelManager.GetXPForNextLevel(data.level, kaijuName),
		levelUp = false
	})
end

task.spawn(startDetection)

task.spawn(initialize)
