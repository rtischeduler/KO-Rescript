local HealthService = { Name = "Health" }

function HealthService.regenAmount(maxHealth, regenPoints, cfg)
	local multiplier = 1 + ((regenPoints or 0) * cfg.RegenPerPoint)
	return maxHealth * cfg.RegenBasePercent * multiplier
end

function HealthService.canRegen(health, maxHealth, bossMode, lastDamage, now, delay)
	if health >= maxHealth or bossMode then
		return false
	end
	if lastDamage == nil then
		return true
	end
	return (now - lastDamage) >= delay
end

function HealthService:Init()
	local framework = script:FindFirstAncestor("Server")
	local PlayerHooks = require(framework.Core.PlayerHooks)
	local cfg = require(framework.Config).Health

	local function enforceMaxHealth(character, humanoid)
		local enforcing = false
		humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
			local customMax = character:GetAttribute("CustomMaxHealth")
			if customMax and not enforcing and humanoid.MaxHealth ~= customMax then
				enforcing = true
				humanoid.MaxHealth = customMax
				if humanoid.Health > customMax then
					humanoid.Health = customMax
				end
				enforcing = false
			end
		end)
	end

	local function startRegen(character, humanoid)
		local lastDamage = nil
		local previousHealth = humanoid.Health

		humanoid.HealthChanged:Connect(function(newHealth)
			if previousHealth and newHealth < previousHealth then
				lastDamage = os.clock()
			end
			previousHealth = newHealth
		end)

		task.spawn(function()
			local waited = 0
			while character and not character.Parent and waited < cfg.CharacterParentTimeout do
				task.wait(0.5)
				waited += 0.5
			end

			while character and character.Parent and humanoid and humanoid.Health > 0 do
				task.wait(cfg.RegenInterval)
				if
					HealthService.canRegen(
						humanoid.Health,
						humanoid.MaxHealth,
						character:GetAttribute("BossMode"),
						lastDamage,
						os.clock(),
						cfg.RegenDelay
					)
				then
					local heal = HealthService.regenAmount(humanoid.MaxHealth, character:GetAttribute("RegenModifier"), cfg)
					humanoid.Health = math.min(humanoid.Health + heal, humanoid.MaxHealth)
				end
			end
		end)
	end

	PlayerHooks.OnCharacter(function(_, character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		enforceMaxHealth(character, humanoid)
		startRegen(character, humanoid)
	end)
end

return HealthService
