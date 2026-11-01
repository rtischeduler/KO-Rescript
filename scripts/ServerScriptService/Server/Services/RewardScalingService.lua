local Players = game:GetService("Players")

local RewardScalingService = { Name = "RewardScaling" }

function RewardScalingService.compute(ratio, attackerStarter, victimStarter, isKill, cfg)
	local function taper(zeroAt)
		if ratio <= cfg.FullUntil then
			return 1
		end
		return math.clamp(1 - (ratio - cfg.FullUntil) / (zeroAt - cfg.FullUntil), 0, 1)
	end
	local gcells = taper(cfg.GCellsZeroAt)
	local xp = taper(cfg.XpZeroAt)
	if victimStarter and not attackerStarter then
		gcells = 0
		xp = isKill and 0 or math.min(xp, cfg.StarterXp)
	end
	return gcells, xp
end

function RewardScalingService:Init()
	local cfg = require(script:FindFirstAncestor("Server").Config).RewardScaling
	local free = {}
	for _, name in ipairs(cfg.FreeMorphs) do
		free[name] = true
	end

	local function isStarter(character)
		local value = character:FindFirstChild("Kaiju")
		return value ~= nil and value:IsA("StringValue") and free[value.Value] == true
	end

	_G.RewardScale = function(attacker, victimCharacter, isKill)
		if typeof(attacker) ~= "Instance" or typeof(victimCharacter) ~= "Instance" then
			return 1, 1
		end
		local victimPlayer = Players:GetPlayerFromCharacter(victimCharacter)
		local attackerCharacter = attacker.Character
		if not victimPlayer or not attackerCharacter or victimPlayer == attacker then
			return 1, 1
		end
		if attackerCharacter:GetAttribute("BossMode") or victimCharacter:GetAttribute("BossMode") then
			return 1, 1
		end
		local attackerHumanoid = attackerCharacter:FindFirstChildOfClass("Humanoid")
		local victimHumanoid = victimCharacter:FindFirstChildOfClass("Humanoid")
		if not attackerHumanoid or not victimHumanoid then
			return 1, 1
		end
		local ratio = attackerHumanoid.MaxHealth / math.max(victimHumanoid.MaxHealth, 1)
		return RewardScalingService.compute(ratio, isStarter(attackerCharacter), isStarter(victimCharacter), isKill == true, cfg)
	end
end

return RewardScalingService
