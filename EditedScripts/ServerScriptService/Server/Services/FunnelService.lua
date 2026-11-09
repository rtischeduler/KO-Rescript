local FunnelService = { Name = "Funnel" }

function FunnelService:Init()
	local Players = game:GetService("Players")
	local HttpService = game:GetService("HttpService")
	local AnalyticsService = game:GetService("AnalyticsService")

	local MILESTONES = { 100, 500, 1000, 2500, 5000, 10000 }
	local sessions = setmetatable({}, { __mode = "k" })
	local done = setmetatable({}, { __mode = "k" })

	local function once(player, key)
		local set = done[player]
		if not set then
			set = {}
			done[player] = set
		end
		if set[key] then
			return false
		end
		set[key] = true
		return true
	end

	local function sessionId(player, funnel)
		local byFunnel = sessions[player]
		if not byFunnel then
			byFunnel = {}
			sessions[player] = byFunnel
		end
		if not byFunnel[funnel] then
			byFunnel[funnel] = HttpService:GenerateGUID(false)
		end
		return byFunnel[funnel]
	end

	local function onboarding(player, step, name)
		if once(player, "Onboarding" .. step) then
			pcall(function()
				AnalyticsService:LogOnboardingFunnelStepEvent(player, step, name)
			end)
		end
	end

	local function funnel(player, funnelName, step, name, fields)
		pcall(function()
			AnalyticsService:LogFunnelStepEvent(player, funnelName, sessionId(player, funnelName), step, name, fields)
		end)
	end

	_G.LogFunnel = function(player, funnelName, step, name, fields)
		if typeof(player) == "Instance" and player:IsA("Player") then
			funnel(player, funnelName, step, name, fields)
		end
	end

	_G.LogShopPurchase = function(player, itemName, success, reason)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			return
		end
		local fields = { [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = tostring(itemName) }
		funnel(player, "Shop", 1, "Purchase Attempt", fields)
		if success then
			funnel(player, "Shop", 2, "Purchase Success", fields)
		else
			fields[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = tostring(reason)
			funnel(player, "Shop", 1, "Purchase Attempt", fields)
		end
		sessions[player] = nil
	end

	local function watchGCells(player)
		local leaderstats = player:WaitForChild("leaderstats", 60)
		local gcells = leaderstats and (leaderstats:WaitForChild("GCells", 10) or leaderstats:FindFirstChild("gcells"))
		if not gcells then
			return
		end
		task.wait(10)
		local last = gcells.Value
		gcells.Changed:Connect(function(value)
			if value > last then
				onboarding(player, 4, "First GCells Earned")
				for index, milestone in ipairs(MILESTONES) do
					if last < milestone and value >= milestone and once(player, "Milestone" .. milestone) then
						funnel(player, "Progression", index, "GCells " .. milestone)
					end
				end
			end
			last = value
		end)
	end

	local function watchCharacter(player, character)
		onboarding(player, 2, "Character Loaded")
		local function check()
			if character:FindFirstChild("Kaiju") then
				onboarding(player, 3, "Kaiju Selected")
				return true
			end
			return false
		end
		if not check() then
			local connection
			connection = character.ChildAdded:Connect(function()
				if check() then
					connection:Disconnect()
				end
			end)
		end
	end

	local function onPlayer(player)
		onboarding(player, 1, "Joined")
		task.spawn(watchGCells, player)
		task.delay(300, function()
			if player.Parent then
				onboarding(player, 5, "Played 5 Minutes")
			end
		end)
		player.CharacterAdded:Connect(function(character)
			watchCharacter(player, character)
		end)
		if player.Character then
			watchCharacter(player, player.Character)
		end
	end

	Players.PlayerAdded:Connect(onPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayer, player)
	end
end

return FunnelService
