local names = { One = true, Two = true, Three = true, Four = true, R = true, T = true, F = true, Q = true, E = true, LeftShift = true, G = true, Unknown = true, Escape = true }
local KeyCode = setmetatable({}, {
	__index = function(_, key)
		if names[key] then
			return { Name = key }
		end
		error("not a keycode")
	end,
})
_G.Enum = { KeyCode = KeyCode }
Enum = _G.Enum

local K = require("../EditedScripts/ReplicatedStorage/KOSettings")

local function check(cond, msg)
	if not cond then
		error("FAIL: " .. msg, 2)
	end
end

check(K.Validate("Rain", true) == true and K.Validate("Rain", "x") == nil, "boolean validation")
check(K.Validate("MasterVolume", 2) == 1 and K.Validate("MasterVolume", -1) == 0, "volume clamp")
check(K.Validate("MusicVolume", 0.123) == 0.12, "volume rounding")
check(K.Validate("FootstepVolume", 5) == 1 and K.Validate("FootstepVolume", 0.456) == 0.46, "footstep volume")
check(K.Validate("UnderwaterMuffle", false) == false and K.Validate("UnderwaterMuffle", 1) == nil, "muffle toggle")
check(K.Validate("Graphics", "Low") == "Low" and K.Validate("Graphics", "Ultra") == nil, "choice validation")
check(K.Validate("Key_Fly", "G") == "G" and K.Validate("Key_Fly", "Escape") == nil and K.Validate("Key_Fly", "Nope") == nil, "key validation")
check(K.Validate("Missing", true) == nil, "unknown name")

check(K.SlotForKey({ Name = "R" }) == 5 and K.SlotForKey({ Name = "Two" }) == 2, "default slots")
local changed = K.SetKey("Attack1", "R")
check(#changed == 2 and K.Get("Key_Attack1") == "R" and K.Get("Key_Roar1") == "One", "swap on conflict")
check(K.SlotForKey({ Name = "R" }) == 1 and K.SlotForKey({ Name = "One" }) == 5, "slots follow rebinding")
check(K.SetKey("Attack1", "Escape") == nil, "escape rejected")

K.Load({ Rain = false, MusicVolume = 0.5, Graphics = "bad", Key_Sprint = "G" })
check(K.Get("Rain") == false and K.Get("MusicVolume") == 0.5 and K.Get("Graphics") == "Auto" and K.Get("Key_Sprint") == "G", "load keeps only valid values")

K.Reset()
local defaults = K.Defaults()
for name, value in pairs(defaults) do
	check(K.Get(name) == value, "reset " .. name)
end

K.SetRebinding(true)
check(K.IsRebinding(), "rebinding on")
K.SetRebinding(false)

print("KOSettings tests passed")
