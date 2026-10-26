
local Regen = {}

function Regen.Init()
	local Players = game:GetService("Players")

	local HEAL_DELAY = 20
	local HEAL_INTERVAL = 3
	local BASE_REGEN_PERCENT = 0.01015
	local REGEN_PER_POINT = 0.15

	local charState = {}

	local function setupCharacter(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		local state = {
			lastDamageTime = 0,
			previousHealth = humanoid.Health,
		}
		charState[character] = state

		humanoid.HealthChanged:Connect(function(newHealth)
			if state.previousHealth and newHealth < state.previousHealth then
				state.lastDamageTime = tick()
			end
			state.previousHealth = newHealth
		end)

		task.spawn(function()
			while character and not character.Parent do
				task.wait(0.5)
			end

			while character and character.Parent and humanoid and humanoid.Health > 0 do
				task.wait(HEAL_INTERVAL)

				if humanoid.Health < humanoid.MaxHealth and not character:GetAttribute("BossMode") then
					local timeSinceDamage = tick() - state.lastDamageTime
					if timeSinceDamage >= HEAL_DELAY then
						local regenPoints = character:GetAttribute("RegenModifier") or 0
						local regenMult = 1 + (regenPoints * REGEN_PER_POINT)
						local healAmount = humanoid.MaxHealth * BASE_REGEN_PERCENT * regenMult
						humanoid.Health = math.min(humanoid.Health + healAmount, humanoid.MaxHealth)
					end
				end
			end
		end)

		character.AncestryChanged:Connect(function(_, parent)
			if not parent then
				charState[character] = nil
			end
		end)
	end

	local function onPlayerAdded(player)
		player.CharacterAdded:Connect(setupCharacter)
		if player.Character then
			setupCharacter(player.Character)
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
end

return Regen