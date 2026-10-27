local EliminatorService = { Name = "Eliminator" }

function EliminatorService.entryMatches(entry, playerName, userId)
	if type(entry) == "string" and entry ~= "" then
		return string.lower(playerName) == string.lower(entry)
	elseif type(entry) == "number" and entry > 0 then
		return userId == entry
	end
	return false
end

function EliminatorService:Init()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local framework = script:FindFirstAncestor("Server")
	local PlayerHooks = require(framework.Core.PlayerHooks)
	local Logger = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Logger"))
	local cfg = require(framework.Config).Eliminator
	local log = Logger.new("Eliminator")

	local adminRankNames = {}
	for _, name in ipairs(cfg.AdminRankNames) do
		adminRankNames[name] = true
	end

	local function isAdmin(player)
		local main = _G.HDAdminMain
		if not main then
			return false
		end

		if type(main.GetRank) == "function" then
			local success, rank = pcall(main.GetRank, main, player)
			if success and type(rank) == "number" then
				return rank >= cfg.MinAdminRank
			end
		end

		local settings = main.settings
		if not (settings and settings.Ranks) then
			return false
		end

		for _, rankData in ipairs(settings.Ranks) do
			local rankLevel = rankData[1]
			if rankLevel >= cfg.MinAdminRank and rankData[3] then
				for i = 1, #rankData[3], 2 do
					if EliminatorService.entryMatches(rankData[3][i], player.Name, player.UserId) then
						return true
					end
				end
			end
		end

		if settings.Groups then
			for groupId, ranks in pairs(settings.Groups) do
				if type(groupId) == "number" and groupId > 0 then
					local okIn, inGroup = pcall(player.IsInGroupAsync, player, groupId)
					if okIn and inGroup then
						local playerRank
						for groupRank, rankName in pairs(ranks) do
							if adminRankNames[rankName] and type(groupRank) == "number" and groupRank > 0 then
								if playerRank == nil then
									local okRank, value = pcall(player.GetRankInGroupAsync, player, groupId)
									playerRank = okRank and value or false
								end
								if playerRank and playerRank >= groupRank then
									return true
								end
							end
						end
					end
				end
			end
		end

		return false
	end

	PlayerHooks.OnPlayer(function(player)
		if not _G.PlayerEliminatorActive then
			return
		end
		task.wait(cfg.JoinCheckDelay)
		if not player or not player.Parent then
			return
		end
		if not isAdmin(player) then
			player:Kick("Server is in Player Eliminator mode. Only Admin+ can join.")
		end
	end)

	PlayerHooks.OnCharacter(function(player, character)
		local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
		if not humanoid then
			return
		end
		humanoid.Died:Connect(function()
			if not _G.PlayerEliminatorActive then
				return
			end
			if not character:FindFirstChild("Kaiju") then
				return
			end
			task.wait(cfg.DeathKickDelay)
			if player and player.Parent then
				local popup = ReplicatedStorage:FindFirstChild("EliminatorPopup")
				if popup then
					popup:FireAllClients(player.Name .. " Has been eliminated.", "red")
				end
				player:Kick("You were eliminated! Better luck next time.")
			end
		end)
	end)

	log:info("Monitoring")
end

return EliminatorService
