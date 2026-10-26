local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DamageMultiplierPerLevel = ReplicatedStorage:WaitForChild("DamageMultiplierPerLevel")

function onTouched(part)
	local h = part.Parent:findFirstChild("Humanoid")
	if h~=nil then
		local morph = script.Parent.Parent.Parent
            local attacker = Players:GetPlayerFromCharacter(morph)
            local damageMultiplier = 1
            if attacker and attacker.Character then
                local levelValue = attacker.Character:FindFirstChild("Level")
                local level = levelValue and levelValue.Value or 1
                local multiplierPerLevel = DamageMultiplierPerLevel.Value
                damageMultiplier = multiplierPerLevel ^ (level - 1)
            end
            h.Health = h.Health - (2 * damageMultiplier)

		local morph = script.Parent.Parent.Parent
		local attacker = Players:GetPlayerFromCharacter(morph)
		if attacker then
			local leaderstats = attacker:FindFirstChild("leaderstats")
			if leaderstats then
				local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
				if gcells and gcells:IsA("IntValue") then
					if _G.GCellGuardAllow then _G.GCellGuardAllow(gcells, 2) end
					gcells.Value = gcells.Value + 2
				end
			end
		end
	end
end

script.Parent.Touched:connect(onTouched)
