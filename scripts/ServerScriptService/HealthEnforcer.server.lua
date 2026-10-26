local Players = game:GetService("Players")




local function setupCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

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

local function setupPlayer(player)
	player.CharacterAdded:Connect(setupCharacter)
	if player.Character then
		setupCharacter(player.Character)
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)