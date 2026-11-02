local LevelManager = {}

local KAIJU_MAX_LEVELS = {
	["CIVILIAN [FREE]"] = 1000,
	["MINILLA"] = 1000,
	["RED"] = 666,
}

local DEFAULT_MAX_LEVEL = 100
local LEGACY_XP_STEP = 32
local XP_SCALE = 5
local XP_STEP = LEGACY_XP_STEP * XP_SCALE

LevelManager.XP_VERSION = 2

local function xpForLevel(level, kaijuName, step)
	if level <= 1 then return 0 end

	if kaijuName == "MINILLA" then
		if level == 801 then
			return 1234567
		elseif level >= 901 and level <= 999 then
			return step * (level - 1) * 6.78125
		elseif level == 1000 then
			return 34567890
		end
	end

	return step * (level - 1)
end

function LevelManager.GetXPForLevel(level, kaijuName)
	return xpForLevel(level, kaijuName, XP_STEP)
end

function LevelManager.GetLegacyXPForLevel(level, kaijuName)
	return xpForLevel(level, kaijuName, LEGACY_XP_STEP)
end

function LevelManager.GetMaxLevel(kaijuName)
	if kaijuName and KAIJU_MAX_LEVELS[kaijuName] then
		return KAIJU_MAX_LEVELS[kaijuName]
	end
	return DEFAULT_MAX_LEVEL
end

function LevelManager.GetLegacyTotalXP(level, xp, kaijuName)
	local total = xp or 0
	for l = 2, level or 1 do
		total = total + LevelManager.GetLegacyXPForLevel(l, kaijuName)
	end
	return total
end

function LevelManager.GetLevelAndXPFromTotal(totalXP, kaijuName)
	local maxLevel = LevelManager.GetMaxLevel(kaijuName)
	local level = 1
	local remaining = totalXP

	for l = 2, maxLevel do
		local required = LevelManager.GetXPForLevel(l, kaijuName)
		if remaining >= required then
			remaining = remaining - required
			level = l
		else
			break
		end
	end

	if level >= maxLevel then
		remaining = 0
	end

	return level, remaining
end

function LevelManager.MigrateEntry(name, entry)
	if type(entry) ~= "table" or entry.xpVersion == LevelManager.XP_VERSION then return false end
	local total = LevelManager.GetLegacyTotalXP(entry.level or 1, entry.xp or 0, name)
	local lvl, rem = LevelManager.GetLevelAndXPFromTotal(total, name)
	entry.level = lvl
	entry.xp = math.floor(rem)
	entry.xpVersion = LevelManager.XP_VERSION
	return true
end

function LevelManager.GetLevelFromXP(totalXP, kaijuName)
	local level = LevelManager.GetLevelAndXPFromTotal(totalXP, kaijuName)
	return level
end

function LevelManager.GetXPForNextLevel(currentLevel, kaijuName)
	local maxLevel = LevelManager.GetMaxLevel(kaijuName)
	local nextLevel = currentLevel + 1

	if nextLevel > maxLevel then
		return LevelManager.GetXPForLevel(maxLevel, kaijuName)
	end

	return LevelManager.GetXPForLevel(nextLevel, kaijuName)
end

return LevelManager
