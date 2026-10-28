local lvl = script.Parent:FindFirstChild("Level")
if not lvl then return end

local canFly = script.Parent.Parent:FindFirstChild("canFly")
local characterName = "MINILLA"
local character = script.Parent.Parent
local nameAttribute = character:GetAttribute("KaijuName")

local kStats = script.Parent.Parent:FindFirstChild("Stats")
if not kStats then return end

local scratchDamage = kStats:FindFirstChild("DMG1")
local biteDamage = kStats:FindFirstChild("DMG2")
local healthStat = kStats:FindFirstChild("HP")
local maxHealthStat = kStats:FindFirstChild("MaxHP")
local walkSpeedStat = kStats:FindFirstChild("WS")
local flySpeedStat = kStats:FindFirstChild("SS")

if nameAttribute and nameAttribute ~= characterName then return end

if lvl then
	if lvl >= 1000 then
		canFly.Value = true
		
		scratchDamage.Value = 1420
		biteDamage.Value = 1640
		healthStat.Value = 14400
		maxHealthStat.Value = 14400
		walkSpeedStat.Value = 54
		flySpeedStat.Value = 240
	else
		canFly = false
	end
end