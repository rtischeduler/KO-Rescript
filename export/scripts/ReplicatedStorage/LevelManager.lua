--[[local LevelManager = {}

local ABSOLUTE_MAX_LEVEL = 1000

local KAIJU_MAX_LEVELS = {
	["CIVILIAN [FREE]"] = 1000,
	["MINILLA"] = 200,
	["RED"] = 666,
}

local DEFAULT_MAX_LEVEL = 100

local XP_PER_LEVEL = {}

XP_PER_LEVEL[1] = 0
for level = 2, ABSOLUTE_MAX_LEVEL do
	XP_PER_LEVEL[level] = 32 * (level - 1)
end

function LevelManager.GetLevelFromXP(totalXP, kaijuName)
	local maxLevel = LevelManager.GetMaxLevel(kaijuName)
	local level = 1
	local remaining = totalXP
	for l = 2, maxLevel do
		if remaining >= XP_PER_LEVEL[l] then
			remaining = remaining - XP_PER_LEVEL[l]
			level = l
		else
			break
		end
	end
	return level
end

function LevelManager.GetXPForNextLevel(currentLevel, kaijuName)
	local maxLevel = LevelManager.GetMaxLevel(kaijuName)
	local nextLevel = currentLevel + 1
	if nextLevel > maxLevel then
		return XP_PER_LEVEL[maxLevel]
	end
	if XP_PER_LEVEL[nextLevel] then
		return XP_PER_LEVEL[nextLevel]
	end
	return XP_PER_LEVEL[maxLevel]
end

function LevelManager.GetXPForLevel(level)
	return XP_PER_LEVEL[level] or 0
end

function LevelManager.GetMaxLevel(kaijuName)
	if kaijuName and KAIJU_MAX_LEVELS[kaijuName] then
		return KAIJU_MAX_LEVELS[kaijuName]
	end
	return DEFAULT_MAX_LEVEL
end

return LevelManager]]

--FOR LEVEL 1000 MINILLA
local LevelManager = {}

local ABSOLUTE_MAX_LEVEL = 1000

local KAIJU_MAX_LEVELS = {
	["CIVILIAN [FREE]"] = 1000,
	["MINILLA"] = 1000,
	["RED"] = 666,
}

local DEFAULT_MAX_LEVEL = 100

function LevelManager.GetXPForLevel(level, kaijuName)
	if level <= 1 then return 0 end

	-- Minilla Custom Rules
	if kaijuName == "MINILLA" then
		if level == 801 then
			return 1234567
		elseif level >= 901 and level <= 999 then
			local baseXP = 32 * (level - 1)
			return baseXP * 6.78125
		elseif level == 1000 then
			return 34567890
		end
	end

	return 32 * (level - 1)
end

function LevelManager.GetLevelFromXP(totalXP, kaijuName)
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

function LevelManager.GetMaxLevel(kaijuName)
	if kaijuName and KAIJU_MAX_LEVELS[kaijuName] then
		return KAIJU_MAX_LEVELS[kaijuName]
	end
	return DEFAULT_MAX_LEVEL
end

return LevelManager
