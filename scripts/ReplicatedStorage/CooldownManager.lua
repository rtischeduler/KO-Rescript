local Players = game:GetService("Players")

local CooldownManager = {}

local cooldowns = {}

local COOLDOWN_DURATIONS = {
	Attack1 = 1,
	Attack2 = 2,
	Attack3 = 1,
	Attack4 = 1,
	Roar1 = 2,
	Roar2 = 2,
	Sprint = 0.5,
}

local ATTACK_DURATIONS = {
	Attack1 = 1,
	Attack2 = 5,
	Attack3 = 1,
	Attack4 = 1,
	Roar1 = 3,
	Roar2 = 3,
}

local COMBAT_ABILITIES = {
	Attack1 = true, Attack2 = true, Attack3 = true, Attack4 = true,
	Roar1 = true, Roar2 = true,
}

local attackDurationEnd = 0

local NAME_MAP = {
	Attack = "Attack1", Attack1Event = "Attack1",
	Beam = "Attack2", Attack2Event = "Attack2",
	Attack3 = "Attack3", Attack3Event = "Attack3",
	Attack4 = "Attack4", Attack4Event = "Attack4",
	Roar1 = "Roar1", Roar1Event = "Roar1",
	Roar2 = "Roar2", Roar2Event = "Roar2",
	Sprint = "Sprint",
}

local REVERSE_NAME_MAP = {}
for eventName, canonicalName in pairs(NAME_MAP) do
	REVERSE_NAME_MAP[canonicalName] = REVERSE_NAME_MAP[canonicalName] or {}
	table.insert(REVERSE_NAME_MAP[canonicalName], eventName)
end

function CooldownManager.normalize(name)
	return NAME_MAP[name] or name
end

local function getAttributeDuration(abilityName)
	local player = Players.LocalPlayer
	if not player then return nil end

	local character = player.Character
	if not character then return nil end

	local charScripts = character:FindFirstChild("CharacterScripts")
	if not charScripts then return nil end

	local possibleNames = REVERSE_NAME_MAP[abilityName]
	if not possibleNames then return nil end

	for _, eventName in ipairs(possibleNames) do
		local event = charScripts:FindFirstChild(eventName)
		if event and event:IsA("RemoteEvent") then
			local attr = event:GetAttribute("CooldownDuration")
			if attr then return attr end
		end
	end

	local animEvents = charScripts:FindFirstChild("AnimEvents")
	if animEvents then
		for _, eventName in ipairs(possibleNames) do
			local event = animEvents:FindFirstChild(eventName)
			if event and event:IsA("RemoteEvent") then
				local attr = event:GetAttribute("CooldownDuration")
				if attr then return attr end
			end
		end
	end

	return nil
end

function CooldownManager.isInAttackDuration()
	return os.clock() < attackDurationEnd
end

function CooldownManager.canUse(abilityName)
	abilityName = CooldownManager.normalize(abilityName)

	local endTime = cooldowns[abilityName]
	if endTime and os.clock() < endTime then
		return false
	end

	if COMBAT_ABILITIES[abilityName] and CooldownManager.isInAttackDuration() then
		return false
	end
	return true
end

function CooldownManager.start(abilityName, duration)
	abilityName = CooldownManager.normalize(abilityName)

	local actualDuration = getAttributeDuration(abilityName) or duration or COOLDOWN_DURATIONS[abilityName] or 2
	cooldowns[abilityName] = os.clock() + actualDuration
end

function CooldownManager.getRemaining(abilityName)
	abilityName = CooldownManager.normalize(abilityName)
	local endTime = cooldowns[abilityName]
	if endTime and os.clock() < endTime then
		return endTime - os.clock()
	end
	return 0
end

local function getAttributeAttackDuration(abilityName)
	local player = Players.LocalPlayer
	if not player then return nil end

	local character = player.Character
	if not character then return nil end

	local charScripts = character:FindFirstChild("CharacterScripts")
	if not charScripts then return nil end

	local possibleNames = REVERSE_NAME_MAP[abilityName]
	if not possibleNames then return nil end

	for _, eventName in ipairs(possibleNames) do
		local event = charScripts:FindFirstChild(eventName)
		if event and event:IsA("RemoteEvent") then
			local attr = event:GetAttribute("AttackDuration")
			if attr then return attr end
		end
	end

	local animEvents = charScripts:FindFirstChild("AnimEvents")
	if animEvents then
		for _, eventName in ipairs(possibleNames) do
			local event = animEvents:FindFirstChild(eventName)
			if event and event:IsA("RemoteEvent") then
				local attr = event:GetAttribute("AttackDuration")
				if attr then return attr end
			end
		end
	end

	return nil
end

function CooldownManager.startAttackDuration(abilityName)
	abilityName = CooldownManager.normalize(abilityName)
	if not COMBAT_ABILITIES[abilityName] then return end
	local duration = getAttributeAttackDuration(abilityName) or ATTACK_DURATIONS[abilityName] or 1
	attackDurationEnd = os.clock() + duration
end

function CooldownManager.getAttackDuration(abilityName)
	abilityName = CooldownManager.normalize(abilityName)
	local attrDuration = getAttributeAttackDuration(abilityName)
	if attrDuration then
		return attrDuration
	end
	return ATTACK_DURATIONS[abilityName] or 1
end

function CooldownManager.getDuration(abilityName)
	abilityName = CooldownManager.normalize(abilityName)
	local attrDuration = getAttributeDuration(abilityName)
	if attrDuration then
		return attrDuration
	end
	return COOLDOWN_DURATIONS[abilityName] or 2
end

function CooldownManager.reset()
	for key in pairs(cooldowns) do
		cooldowns[key] = nil
	end
	attackDurationEnd = 0
end

return CooldownManager
