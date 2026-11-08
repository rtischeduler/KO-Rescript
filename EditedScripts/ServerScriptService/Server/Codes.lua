local Codes = {}

Codes.Rewards = {
	WELCOME = { GCells = 100, Message = "Welcome! You received 100 G-Cells." },
}

function Codes.normalize(text)
	if type(text) ~= "string" or #text > 40 then
		return nil
	end
	local cleaned = text:gsub("%s", ""):upper()
	return cleaned ~= "" and cleaned or nil
end

function Codes.grant(player, reward)
	local given = false
	if reward.GCells then
		local stats = player:FindFirstChild("leaderstats")
		local gcells = stats and (stats:FindFirstChild("GCells") or stats:FindFirstChild("gcells"))
		if gcells and gcells:IsA("IntValue") then
			if _G.GCellGuardAllow then
				_G.GCellGuardAllow(gcells, reward.GCells)
			end
			gcells.Value += reward.GCells
			given = true
		end
	end
	if reward.XP then
		local character = player.Character
		local addXP = character and character:FindFirstChild("AddXP")
		if addXP and addXP:IsA("BindableEvent") then
			addXP:Fire(reward.XP)
			given = true
		end
	end
	return given
end

return Codes
