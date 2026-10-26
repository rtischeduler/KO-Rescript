




local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local eliminatorPopupEvent = ReplicatedStorage:FindFirstChild("EliminatorPopup")


local main
local maxWaits = 0
while not main and maxWaits < 60 do
	main = _G.HDAdminMain
	if not main then
		task.wait(1)
		maxWaits = maxWaits + 1
	end
end


local function isAdmin(player)
	if main then
		
		if type(main.GetRank) == "function" then
			local success, rank = pcall(main.GetRank, main, player)
			if success and type(rank) == "number" then
				return rank >= 2
			end
		end

		
		local settings = main.settings
		if settings and settings.Ranks then
			for _, rankData in ipairs(settings.Ranks) do
				local rankLevel = rankData[1]
				if rankLevel >= 2 and rankData[3] then
					for i = 1, #rankData[3], 2 do
						local nameOrId = rankData[3][i]
						if type(nameOrId) == "string" and nameOrId ~= "" then
							if string.lower(player.Name) == string.lower(nameOrId) then
								return true
							end
						elseif type(nameOrId) == "number" and nameOrId > 0 then
							if player.UserId == nameOrId then
								return true
							end
						end
					end
				end
			end

			
			if settings.Groups then
				for groupId, ranks in pairs(settings.Groups) do
					if type(groupId) == "number" and groupId > 0 then
						local success, inGroup = pcall(function()
							return player:IsInGroupAsync(groupId)
						end)
						if success and inGroup then
							for groupRank, rankName in pairs(ranks) do
								if (rankName == "Admin" or rankName == "HeadAdmin" or rankName == "Owner") and type(groupRank) == "number" and groupRank > 0 then
									local s2, playerGroupRank = pcall(function()
										return player:GetRankInGroupAsync(groupId)
									end)
									if s2 and playerGroupRank >= groupRank then
										return true
									end
								end
							end
						end
					end
				end
			end
		end
	end

	return false
end


local function setupCharacter(player, character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid then return end
	end

	humanoid.Died:Connect(function()
		if not _G.PlayerEliminatorActive then return end

		
		
		local kaijuVal = character:FindFirstChild("Kaiju")
		if kaijuVal then
			task.wait(1) 
			if player and player.Parent then
				
				if eliminatorPopupEvent then
					eliminatorPopupEvent:FireAllClients(player.Name .. " Has been eliminated.", "red")
				end
				player:Kick("You were eliminated! Better luck next time.")
			end
		end
	end)
end


local function onPlayerAdded(player)
	
	if _G.PlayerEliminatorActive then
		task.wait(2) 
		if not player or not player.Parent then return end
		if not isAdmin(player) then
			player:Kick("Server is in Player Eliminator mode. Only Admin+ can join.")
			return
		end
	end

	
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)

	if player.Character then
		setupCharacter(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

print("[PlayerEliminator] Server script loaded and monitoring.")