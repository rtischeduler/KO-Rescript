local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

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

local BASE_HEAL_AMOUNT = 125

local ACTIVE_COLOR = Color3.fromRGB(116, 125, 255)
local INACTIVE_COLOR = Color3.new(0.816, 0.816, 0.816)

local KAIJU_MAX_POINTS_PER_MODIFIER = {
	["CIVILIAN [FREE]"] = 50,
}
local DEFAULT_MAX_POINTS_PER_MODIFIER = 10

local function getMaxPointsPerModifier(morphName)
	if morphName and KAIJU_MAX_POINTS_PER_MODIFIER[morphName] then
		return KAIJU_MAX_POINTS_PER_MODIFIER[morphName]
	end
	return DEFAULT_MAX_POINTS_PER_MODIFIER
end

local modifiersFrame = script.Parent
local skillPointsFrame = modifiersFrame.Parent
local statsFrame = skillPointsFrame.Parent
local skillPointsTxt = statsFrame:FindFirstChild("SkillPointsTxt")

local modifierFrames = {
	Damage = modifiersFrame:FindFirstChild("Damage"),
	Health = modifiersFrame:FindFirstChild("Health"),
	Regen = modifiersFrame:FindFirstChild("Regen"),
	Speed = modifiersFrame:FindFirstChild("Speed"),
}

local statLabelNames = {
	Damage = {"Attack1Stat", "Attack2Stat", "Attack3Stat"},
	Health = {"HealthStat"},
	Regen = {"ChargeStat", "RegenStat"},
	Speed = {"WalkStat", "SwimStat", "SprintStat"},
}

local morphStatNames = {
	Damage = {"DMG1", "DMG2", "DMG3"},
	Health = {"MaxHP"},
	Regen = {"GPA", "HEAL_AMOUNT"},
	Speed = {"WS", "SwimSpeed", "SS"},
}

local modifyStatEvent
local getModifierDataFunc
local connectedModifyRemote = nil
local function refreshModifierRemotes()
	modifyStatEvent = ReplicatedStorage:FindFirstChild("ModifyStat")
	getModifierDataFunc = ReplicatedStorage:FindFirstChild("GetModifierData")
end
refreshModifierRemotes()

local currentMorphName = nil
local LEGACY_MORPH_NAMES = {
	["Godzilla1954"] = "GOJIRA [FREE]",
	["Anguirus"] = "ANGUIRUS [FREE]",
	["KamataKun"] = "SHIN FORM 2 [FREE]",
}
local function getModifierEntry(data, morphName)
	if not data or not morphName then return nil end
	if data[morphName] then return data[morphName] end
	for oldName, currentName in pairs(LEGACY_MORPH_NAMES) do
		if currentName == morphName and data[oldName] then return data[oldName] end
	end
	return nil
end
local modifierData = {Damage = 0, Health = 0, Regen = 0, Speed = 0}
local availableSkillPoints = 0
local baseStats = {}

local function formatStat(value)
	local rounded = math.round(value * 100) / 100
	if rounded == math.floor(rounded) then
		return tostring(math.floor(rounded))
	else
		return tostring(rounded)
	end
end

local function fetchBaseStats(morphName)
	baseStats = {}
	local morphs = ReplicatedStorage:FindFirstChild("MorphSupplies")
	if morphs then morphs = morphs:FindFirstChild("Morphs") end
	if not morphs then return end

	local morphModel = morphs:FindFirstChild(morphName, true)
	if not morphModel then return end

	local stats = morphModel:FindFirstChild("Stats")
	if not stats then return end

	for _, child in ipairs(stats:GetChildren()) do
		if child:IsA("NumberValue") or child:IsA("IntValue") then
			baseStats[child.Name] = child.Value
		end
	end
end

local function getStatValue(modifierName, labelIndex)
	local statName = morphStatNames[modifierName][labelIndex]
	if statName == "HEAL_AMOUNT" then
		return BASE_HEAL_AMOUNT
	end
	return baseStats[statName]
end

local function getMultipliedStat(modifierName, labelIndex)
	local original = getStatValue(modifierName, labelIndex)
	if not original then return nil end
	local statName = morphStatNames[modifierName][labelIndex]

	if statName == "HEAL_AMOUNT" then
		return original
	end

	local points = modifierData[modifierName] or 0
	local mult
	if currentMorphName == "MINILLA" then
		mult = 1 + points * MINILLA_MULTIPLIERS[modifierName]
	else
		mult = 1 + points * MULTIPLIERS[modifierName]
	end
	return original * mult
end

local function getMaxedStat(modifierName, labelIndex)
	local original = getStatValue(modifierName, labelIndex)
	if not original then return nil end
	local statName = morphStatNames[modifierName][labelIndex]
	
	if statName == "HEAL_AMOUNT" then
		return original
	end
	local maxPoints = getMaxPointsPerModifier(currentMorphName)
	local mult
	if currentMorphName == "MINILLA" then
		mult = 1 + maxPoints * MINILLA_MULTIPLIERS[modifierName]
	else
		mult = 1 + maxPoints * MULTIPLIERS[modifierName]
	end
	return original * mult
end

local function updateModifierUI(modifierName)
	local frame = modifierFrames[modifierName]
	if not frame then return end

	local points = modifierData[modifierName] or 0

	local bar = frame:FindFirstChild("Bar")
	if bar then
		local maxPerMod = getMaxPointsPerModifier(currentMorphName)
		local pointsPerSegment = maxPerMod / 10
		for i = 1, 10 do
			local segment = bar:FindFirstChild(tostring(i))
			if segment then
				if points > (i - 1) * pointsPerSegment then
					segment.BackgroundColor3 = ACTIVE_COLOR
				else
					segment.BackgroundColor3 = INACTIVE_COLOR
				end
			end
		end
	end

	local labelNames = statLabelNames[modifierName]
	for i, labelName in ipairs(labelNames) do
		local label = frame:FindFirstChild(labelName)
		if label then
			local original = getStatValue(modifierName, i)
			if original then
				local multiplied = getMultipliedStat(modifierName, i)
				local maxed = getMaxedStat(modifierName, i)
				label.Text = formatStat(multiplied) .. "/" .. formatStat(maxed)
			else
				label.Text = "N/A"
			end
		end
	end
end

local function refreshUI()
	for _, modifierName in ipairs({"Damage", "Health", "Regen", "Speed"}) do
		updateModifierUI(modifierName)
	end
	if skillPointsTxt then
		skillPointsTxt.Text = "Skill Points: " .. tostring(math.max(0, availableSkillPoints))
	end
end

local function fetchModifierData()
	if not getModifierDataFunc then return end
	local success, data = pcall(function()
		return getModifierDataFunc:InvokeServer()
	end)
	if success and type(data) == "table" then
		local kaijuData = getModifierEntry(data, currentMorphName)
		if kaijuData then
			modifierData = {
				Damage = kaijuData.Damage or 0,
				Health = kaijuData.Health or 0,
				Regen = kaijuData.Regen or 0,
				Speed = kaijuData.Speed or 0,
			}
			availableSkillPoints = math.max(0, kaijuData.availableSkillPoints or 0)
		else
			modifierData = {Damage = 0, Health = 0, Regen = 0, Speed = 0}
			availableSkillPoints = 0
		end
		refreshUI()
	else

		modifierData = {Damage = 0, Health = 0, Regen = 0, Speed = 0}
		availableSkillPoints = 0
		refreshUI()
	end
end

for _, modifierName in ipairs({"Damage", "Health", "Regen", "Speed"}) do
	local frame = modifierFrames[modifierName]
	if frame then
		local addBtn = frame:FindFirstChild("Add")
		local subBtn = frame:FindFirstChild("Subtract")

		if addBtn then
			addBtn.MouseButton1Click:Connect(function()
				if not currentMorphName then return end
				if availableSkillPoints <= 0 then return end
				if (modifierData[modifierName] or 0) >= getMaxPointsPerModifier(currentMorphName) then return end
				
				modifierData[modifierName] = (modifierData[modifierName] or 0) + 1
				availableSkillPoints = availableSkillPoints - 1
				refreshUI()
				if modifyStatEvent then
					modifyStatEvent:FireServer(currentMorphName, modifierName, "Add")
				end
			end)
		end

		if subBtn then
			subBtn.MouseButton1Click:Connect(function()
				if not currentMorphName then return end
				if (modifierData[modifierName] or 0) <= 0 then return end
				
				modifierData[modifierName] = (modifierData[modifierName] or 0) - 1
				availableSkillPoints = availableSkillPoints + 1
				refreshUI()
				if modifyStatEvent then
					modifyStatEvent:FireServer(currentMorphName, modifierName, "Subtract")
				end
			end)
		end
	end
end

local function connectModifyRemote()
	refreshModifierRemotes()
	if modifyStatEvent and modifyStatEvent ~= connectedModifyRemote then
		connectedModifyRemote = modifyStatEvent
		modifyStatEvent.OnClientEvent:Connect(function(data)
			if data and data.kaijuName == currentMorphName then
				modifierData = data.modifiers or {Damage = 0, Health = 0, Regen = 0, Speed = 0}
				availableSkillPoints = math.max(0, data.availableSkillPoints or 0)
				refreshUI()
			end
		end)
	end
end
connectModifyRemote()
ReplicatedStorage.ChildAdded:Connect(function(child)
	if child.Name == "ModifyStat" or child.Name == "GetModifierData" then
		connectModifyRemote()
		if currentMorphName then fetchModifierData() end
	end
end)
task.spawn(function()
	for _ = 1, 60 do
		connectModifyRemote()
		if getModifierDataFunc and currentMorphName then fetchModifierData() end
		if modifyStatEvent and getModifierDataFunc then break end
		task.wait(1)
	end
end)

if statsFrame then
	statsFrame:GetAttributeChangedSignal("CurrentMorph"):Connect(function()
		currentMorphName = statsFrame:GetAttribute("CurrentMorph")
		if currentMorphName then
			fetchBaseStats(currentMorphName)
			fetchModifierData()
		end
	end)

	currentMorphName = statsFrame:GetAttribute("CurrentMorph")
	if currentMorphName then
		fetchBaseStats(currentMorphName)
		fetchModifierData()
	end
end
