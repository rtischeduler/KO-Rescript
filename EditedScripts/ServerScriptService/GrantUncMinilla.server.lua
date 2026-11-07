local Players = game:GetService("Players")

local GRANTS = {
	[string.lower("25X_Rock")] = { "UNCMINILLA", "UNC MINILLA" },
}

local WAIT_LIMIT = 90

local function grant(player)
	local kaijuNames = GRANTS[string.lower(player.Name)]
	if not kaijuNames then
		return
	end
	local waited = 0
	while type(_G.AdminGiveKaiju) ~= "function" and waited < WAIT_LIMIT and player.Parent == Players do
		task.wait(1)
		waited += 1
	end
	if type(_G.AdminGiveKaiju) ~= "function" or player.Parent ~= Players then
		warn("[grant] AdminGiveKaiju unavailable for " .. player.Name)
		return
	end
	for _, kaijuName in ipairs(kaijuNames) do
		local ok, result = pcall(_G.AdminGiveKaiju, player, kaijuName)
		if ok and result then
			return
		end
	end
	warn("[grant] Could not grant kaiju to " .. player.Name)
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(grant, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(grant, player)
end
