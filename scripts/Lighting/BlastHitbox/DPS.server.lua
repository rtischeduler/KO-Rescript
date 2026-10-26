local Players = game:GetService("Players")

function onTouched(part)
	local character = part.Parent
	local h = character:FindFirstChild("Humanoid")

	if h ~= nil then

		local playerNameValue = script.Parent:FindFirstChild("PlayerName")
		if playerNameValue and playerNameValue:IsA("StringValue") then
			local playerToIgnore = Players:FindFirstChild(playerNameValue.Value)
			if playerToIgnore then
				local playerCharacter = playerToIgnore.Character
				if playerCharacter and character == playerCharacter then

					return
				end
			end
		end

		h.Health = h.Health - 2

		local morph = script.Parent
		local attacker = Players:GetPlayerFromCharacter(morph)
		if attacker then
			h:SetAttribute("LastDPSAttacker", attacker.UserId)
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
