local Players = game:GetService("Players")

local CooldownManager = {}

local cooldowns = {}
local attackDurationEnd = 0

local COOLDOWN_DURATIONS = {
	Attack1 = 1, Attack2 = 2, Attack3 = 1, Attack4 = 1,
	Roar1 = 2, Roar2 = 2, Sprint = 0.5,
}

local ATTACK_DURATIONS = {
	Attack1 = 1, Attack2 = 5, Attack3 = 1, Attack4 = 1,
	Roar1 = 3, Roar2 = 3,
}

local COMBAT_ABILITIES = {
	Attack1 = true, Attack2 = true, Attack3 = true, Attack4 = true,
	Roar1 = true, Roar2 = true,
}

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
	local list = REVERSE_NAME_MAP[canonicalName]
	if not list then
		list = {}
		REVERSE_NAME_MAP[canonicalName] = list
	end
	table.insert(list, eventName)
end

function CooldownManager.normalize(name)
	return NAME_MAP[name] or name
end

local function readAttribute(abilityName, attributeName)
	local ok, result = pcall(function()
		local player = Players.LocalPlayer
		local character = player and player.Character
		local charScripts = character and character:FindFirstChild("CharacterScripts")
		local names = REVERSE_NAME_MAP[abilityName]
		if not charScripts or not names then
			return nil
		end
		local containers = { charScripts }
		local animEvents = charScripts:FindFirstChild("AnimEvents")
		if animEvents then
			table.insert(containers, animEvents)
		end
		for _, container in ipairs(containers) do
			for _, eventName in ipairs(names) do
				local event = container:FindFirstChild(eventName)
				if event and event:IsA("RemoteEvent") then
					local value = event:GetAttribute(attributeName)
					if value ~= nil then
						return value
					end
				end
			end
		end
		return nil
	end)
	if ok then
		return result
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
	local actual = readAttribute(abilityName, "CooldownDuration") or duration or COOLDOWN_DURATIONS[abilityName] or 2
	cooldowns[abilityName] = os.clock() + actual
end

function CooldownManager.getRemaining(abilityName)
	abilityName = CooldownManager.normalize(abilityName)
	local endTime = cooldowns[abilityName]
	if endTime and os.clock() < endTime then
		return endTime - os.clock()
	end
	return 0
end

function CooldownManager.getAttackDuration(abilityName)
	abilityName = CooldownManager.normalize(abilityName)
	return readAttribute(abilityName, "AttackDuration") or ATTACK_DURATIONS[abilityName] or 1
end

function CooldownManager.startAttackDuration(abilityName)
	abilityName = CooldownManager.normalize(abilityName)
	if not COMBAT_ABILITIES[abilityName] then
		return
	end
	attackDurationEnd = os.clock() + CooldownManager.getAttackDuration(abilityName)
end

function CooldownManager.getDuration(abilityName)
	abilityName = CooldownManager.normalize(abilityName)
	return readAttribute(abilityName, "CooldownDuration") or COOLDOWN_DURATIONS[abilityName] or 2
end

function CooldownManager.reset()
	table.clear(cooldowns)
	attackDurationEnd = 0
end

return CooldownManager
