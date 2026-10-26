local LevelGuard = {}

local Players = game:GetService("Players")

local LEVEL_THRESHOLD = 10

function LevelGuard.getLevel(character)
	if typeof(character) == "Instance" and character:IsA("Player") then
		character = character.Character
	end
	if not character then return nil end
	local levelVal = character:FindFirstChild("Level")
	if levelVal and levelVal:IsA("IntValue") then
		return levelVal.Value
	end
	return nil
end

function LevelGuard.canAttack(attackerPlayer, targetPlayer)
	if not attackerPlayer or not targetPlayer then return true end
	local attackerChar = attackerPlayer.Character
	local targetChar = targetPlayer.Character
	if not attackerChar or not targetChar then return true end
	local attackerLevel = LevelGuard.getLevel(attackerChar)
	local targetLevel = LevelGuard.getLevel(targetChar)
	if not attackerLevel or not targetLevel then return true end
	if attackerLevel > LEVEL_THRESHOLD and targetLevel < LEVEL_THRESHOLD then
		return false
	end
	return true
end

function LevelGuard.shouldTargetGainXP(attackerLevel, targetLevel)
	if not attackerLevel or not targetLevel then return false end
	return attackerLevel <= LEVEL_THRESHOLD and targetLevel <= LEVEL_THRESHOLD
end

function LevelGuard.shouldAttackerGainXP(attackerLevel, targetLevel)
	if not attackerLevel or not targetLevel then return true end
	return not (attackerLevel > LEVEL_THRESHOLD and targetLevel < LEVEL_THRESHOLD)
end

LevelGuard.THRESHOLD = LEVEL_THRESHOLD

return LevelGuard