local roblox = require("@lune/roblox")
local values = require("./values")

local function make(class, name, parent)
	local i = roblox.Instance.new(class)
	i.Name = name
	i.Parent = parent
	return i
end

local root = make("Folder", "root")
local cs = make("Folder", "CharacterScripts", make("Folder", "K", root))
local beam = make("RemoteEvent", "Beam", cs)
beam:SetAttribute("AttackType", "Beam")
beam:SetAttribute("BeamDuration", 2)
make("RemoteEvent", "Roar1", cs)
local stats = make("Folder", "Stats", root.K)
local ws = make("NumberValue", "WS", stats)
ws.Value = 8

local r = values.apply(root, {
	{ path = "K/CharacterScripts/Beam", attributes = { AttackType = "Melee", AttackName = "X" }, remove_attributes = { "BeamDuration" } },
	{ path = "K/CharacterScripts/Roar1", delete = true },
	{ path = "K/Stats/WS", properties = { Value = 23 } },
	{ path = "K/Nope" },
})

assert(beam:GetAttribute("AttackType") == "Melee")
assert(beam:GetAttribute("AttackName") == "X")
assert(beam:GetAttribute("BeamDuration") == nil)
assert(cs:FindFirstChild("Roar1") == nil)
assert(ws.Value == 23)
assert(#r.changed == 3 and #r.missing == 1 and #r.errors == 0)
assert(r.deletedClasses.RemoteEvent == 1)

local r2 = values.apply(root, {
	{ path = "K/CharacterScripts/Beam", attributes = { AttackType = "Melee" } },
	{ path = "K/Stats/WS", properties = { Value = 23 } },
})
assert(#r2.changed == 0 and #r2.unchanged == 2)
print("values tests passed")
