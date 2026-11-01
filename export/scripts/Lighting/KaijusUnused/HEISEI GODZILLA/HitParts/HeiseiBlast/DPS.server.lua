local Players = game:GetService("Players")

function onTouched(part)

	if not script.Parent:GetAttribute("BlastActive") then
		return
	end

	local h = part.Parent:findFirstChild("Humanoid")
	if h ~= nil then

		local playerNameValue = script.Parent:FindFirstChild("PlayerName")
		if playerNameValue then
			local touchedPlayer = Players:GetPlayerFromCharacter(part.Parent)
			if touchedPlayer and touchedPlayer.Name == playerNameValue.Value then
				return
			end
		end

		h.Health = h.Health - 1

		local morph = script.Parent.Parent.Parent
		local attacker = Players:GetPlayerFromCharacter(morph)
		if attacker then
			local leaderstats = attacker:FindFirstChild("leaderstats")
			if leaderstats then
				local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
				if gcells and gcells:IsA("IntValue") then
					if _G.GCellGuardAllow then _G.GCellGuardAllow(gcells, 0.9) end
					gcells.Value = gcells.Value + 0.9
				end
			end
		end
	end
end

script.Parent.Touched:connect(onTouched)
