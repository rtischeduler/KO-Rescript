local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local debounce = {}

function onTouched(part)
	local h = part.Parent:findFirstChild("Humanoid")
	if h~=nil then
		local char = h.Parent
		if debounce[char] then return end
		local morph = script.Parent.Parent.Parent
		local selfAttacker = Players:GetPlayerFromCharacter(morph)
		if selfAttacker and char == selfAttacker.Character then return end
		debounce[char] = true
		task.delay(0.5, function()
			debounce[char] = nil
		end)
            local attacker = Players:GetPlayerFromCharacter(morph)
            local damageMultiplier = 1
            h.Health = h.Health - (0.9 * damageMultiplier)

		local morph = script.Parent.Parent.Parent
		local attacker = Players:GetPlayerFromCharacter(morph)
		if attacker then
			h:SetAttribute("LastDPSAttacker", attacker.UserId)
			local leaderstats = attacker:FindFirstChild("leaderstats")
			if leaderstats then
				local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
				if gcells and gcells:IsA("IntValue") then
					if _G.GCellGuardAllow then _G.GCellGuardAllow(gcells, 0.2) end
					gcells.Value = gcells.Value + 0.2
				end
			end
		end
	end
end

script.Parent.Touched:connect(onTouched)
