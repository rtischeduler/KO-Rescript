local KOSettings = {}

local ACTIONS = {
	{ id = "Attack1", label = "Attack 1", default = "One" },
	{ id = "Attack2", label = "Attack 2", default = "Two" },
	{ id = "Attack3", label = "Attack 3", default = "Three" },
	{ id = "Attack4", label = "Attack 4", default = "Four" },
	{ id = "Roar1", label = "Roar 1", default = "R" },
	{ id = "Roar2", label = "Roar 2", default = "T" },
	{ id = "Fly", label = "Toggle flight", default = "F" },
	{ id = "Ascend", label = "Fly up", default = "Q" },
	{ id = "Descend", label = "Fly down", default = "E" },
	{ id = "Sprint", label = "Sprint", default = "LeftShift" },
}

local SLOTS = { Attack1 = 1, Attack2 = 2, Attack3 = 3, Attack4 = 4, Roar1 = 5, Roar2 = 6 }

local CHOICES = {
	Graphics = { "Auto", "High", "Medium", "Low", "Lowest" },
	DayNight = { "Auto", "Day", "Night" },
}

local DEFAULTS = {
	Graphics = "Auto",
	DayNight = "Auto",
	Rain = true,
	MasterVolume = 1,
	MusicVolume = 1,
	SoundVolume = 1,
	FootstepVolume = 1,
	UnderwaterMuffle = true,
	DamageIndicator = true,
	GCellIndicator = true,
	XPIndicator = true,
	CandyIndicator = true,
}
for _, action in ipairs(ACTIONS) do
	DEFAULTS["Key_" .. action.id] = action.default
end

local BLOCKED_KEYS = { Unknown = true, Escape = true }

local current = table.clone(DEFAULTS)
local listeners = {}
local rebindUntil = 0

local function validKey(name)
	if type(name) ~= "string" or BLOCKED_KEYS[name] then
		return false
	end
	local ok, item = pcall(function()
		return Enum.KeyCode[name]
	end)
	return ok and item ~= nil
end

local function fire(name)
	for _, fn in ipairs(listeners) do
		task.spawn(fn, name, current[name])
	end
end

function KOSettings.Validate(name, value)
	local default = DEFAULTS[name]
	if default == nil then
		return nil
	end
	if type(default) == "boolean" then
		if type(value) == "boolean" then
			return value
		end
		return nil
	end
	if type(default) == "number" then
		if type(value) ~= "number" or value ~= value then
			return nil
		end
		return math.floor(math.clamp(value, 0, 1) * 100 + 0.5) / 100
	end
	if CHOICES[name] then
		return table.find(CHOICES[name], value) and value or nil
	end
	return validKey(value) and value or nil
end

function KOSettings.Defaults()
	return table.clone(DEFAULTS)
end

function KOSettings.Actions()
	return ACTIONS
end

function KOSettings.Choices(name)
	return CHOICES[name]
end

function KOSettings.Get(name)
	return current[name]
end

function KOSettings.All()
	return table.clone(current)
end

function KOSettings.Set(name, value)
	local clean = KOSettings.Validate(name, value)
	if clean == nil then
		return false
	end
	if current[name] ~= clean then
		current[name] = clean
		fire(name)
	end
	return true
end

function KOSettings.SetKey(action, keyName)
	local name = "Key_" .. tostring(action)
	if DEFAULTS[name] == nil or not validKey(keyName) then
		return nil
	end
	local old = current[name]
	if old == keyName then
		return {}
	end
	local changed = { name }
	for _, other in ipairs(ACTIONS) do
		local otherName = "Key_" .. other.id
		if otherName ~= name and current[otherName] == keyName then
			current[otherName] = old
			table.insert(changed, otherName)
			fire(otherName)
		end
	end
	current[name] = keyName
	fire(name)
	return changed
end

function KOSettings.Load(saved)
	if type(saved) ~= "table" then
		return
	end
	for name in pairs(DEFAULTS) do
		local clean = KOSettings.Validate(name, saved[name])
		if clean ~= nil and current[name] ~= clean then
			current[name] = clean
			fire(name)
		end
	end
end

function KOSettings.Reset()
	for name, value in pairs(DEFAULTS) do
		if current[name] ~= value then
			current[name] = value
			fire(name)
		end
	end
end

function KOSettings.OnChanged(fn)
	table.insert(listeners, fn)
end

function KOSettings.KeyCode(action)
	return Enum.KeyCode[current["Key_" .. action]]
end

function KOSettings.SlotForKey(keyCode)
	for action, slot in pairs(SLOTS) do
		if current["Key_" .. action] == keyCode.Name then
			return slot
		end
	end
	return nil
end

function KOSettings.SetRebinding(on)
	rebindUntil = on and math.huge or os.clock() + 0.25
end

function KOSettings.IsRebinding()
	return os.clock() < rebindUntil
end

return KOSettings
