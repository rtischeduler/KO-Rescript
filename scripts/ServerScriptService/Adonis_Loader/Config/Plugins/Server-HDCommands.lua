--[[
	Custom commands migrated from HD Admin (Workspace.HD Admin.Config.Commands.Server).
	Original HD Admin ranks mapped: Rank 3 -> HeadAdmins, Rank 2 -> Admins.
--]]

return function(Vargs)
	local server, service = Vargs.Server, Vargs.Service

	-- Adonis passes player args as raw strings (e.g. "me", "all", "PlayerName",
	-- "Player1,Player2"). They must be resolved with Adonis's own GetPlayers,
	-- which understands all of its player selectors. This helper also tolerates
	-- being handed a Player instance or a table of Players just in case.
	local function getTargets(plr, arg)
		local targets = {}
		if type(arg) == "string" then
			local ok, result = pcall(service.GetPlayers, plr, arg)
			if ok and type(result) == "table" then
				for _, v in ipairs(result) do
					if typeof(v) == "Instance" and v:IsA("Player") then
						table.insert(targets, v)
					end
				end
			end
		elseif typeof(arg) == "Instance" and arg:IsA("Player") then
			table.insert(targets, arg)
		elseif type(arg) == "table" then
			for _, v in ipairs(arg) do
				if typeof(v) == "Instance" and v:IsA("Player") then
					table.insert(targets, v)
				end
			end
		end
		return targets
	end

	-- Joins args from index 2 onward so multi-word input works
	-- (e.g. "Godzilla In Hell", "DMG1 900").
	local function joinArgs(args)
		local parts = {}
		for i = 2, #args do
			table.insert(parts, tostring(args[i]))
		end
		return table.concat(parts, " ")
	end

	server.Commands.hd_xp = {
		Prefix = server.Settings.Prefix;
		Commands = {"xp"};
		Args = {"player", "amount"};
		Description = "Give XP to a player for testing levels";
		Category = "Custom";
		Hidden = false;
		Fun = false;
		AdminLevel = "HeadAdmins";
		Function = function(plr, args)
			local amount = tonumber(args[2])
			if not amount then return end

			for _, target in ipairs(getTargets(plr, args[1])) do
				if target and target.Character then
					local addXP = target.Character:FindFirstChild("AddXP")
					if addXP and addXP:IsA("BindableEvent") then
						addXP:Fire(amount)
					end
				end
			end
		end
	}

	server.Commands.hd_boss = {
		Prefix = server.Settings.Prefix;
		Commands = {"Boss"};
		Args = {"player"};
		Description = "Become the Boss with 20,000 HP, 1.5x speed, and a red title. Top damage dealer wins when the boss falls!";
		Category = "Custom";
		Hidden = false;
		Fun = false;
		AdminLevel = "HeadAdmins";
		Function = function(plr, args)
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local bossEvent = ReplicatedStorage:FindFirstChild("BossEvent")
			if not bossEvent then return end

			local targetPlayers = getTargets(plr, args[1])
			if #targetPlayers == 0 then return end

			if _G.BossSystem and _G.BossSystem.cleanup then
				_G.BossSystem.cleanup()
			end

			local bossPlayer = targetPlayers[1]
			local character = bossPlayer.Character
			if not character then return end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end

			local originalMaxHealth = humanoid.MaxHealth
			local originalWalkSpeed = humanoid.WalkSpeed

			local oldCustomMaxHealth = character:GetAttribute("CustomMaxHealth")
			character:SetAttribute("CustomMaxHealth", nil)

			character:SetAttribute("BossMode", true)
			humanoid.MaxHealth = 1
			humanoid.Health = 1
			humanoid.WalkSpeed = originalWalkSpeed * 1.5

			local billboard = Instance.new("BillboardGui")
			billboard.Name = "BossTitle"
			billboard.Size = UDim2.new(0, 500, 0, 60)
			billboard.StudsOffset = Vector3.new(0, 10, 0)
			billboard.AlwaysOnTop = true
			billboard.MaxDistance = math.huge

			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, 0, 1, 0)
			title.BackgroundTransparency = 1
			title.Text = "BOSS: " .. bossPlayer.DisplayName
			title.TextColor3 = Color3.fromRGB(255, 0, 0)
			title.TextScaled = true
			title.Font = Enum.Font.GothamBlack
			title.Parent = billboard

			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 3
			stroke.Color = Color3.fromRGB(0, 0, 0)
			stroke.Parent = title

			billboard.Parent = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart") or character

			bossEvent:FireAllClients("start", bossPlayer.Name)

			local bossState = {
				bossPlayer = bossPlayer,
				bossCharacter = character,
				active = true,
			}

			local damageSnapshot = nil
			local healthConn
			healthConn = humanoid.HealthChanged:Connect(function(health)
				if health <= 0 then
					local log = _G.CombatDamageLog
					if log and log[character] then
						damageSnapshot = {}
						for k, v in pairs(log[character]) do
								damageSnapshot[k] = v
						end
					end
				end
			end)

			task.spawn(function()
				while bossState.active and character and character.Parent and humanoid and humanoid.Health > 0 do
					task.wait(0.5)
					if not bossState.active then break end
					local damageLog = _G.CombatDamageLog
					if damageLog and damageLog[character] then
						local topPlayer = nil
						local topDamage = 0
						local totalDamage = 0
						for attacker, damage in pairs(damageLog[character]) do
								totalDamage = totalDamage + damage
							if damage > topDamage then
									topDamage = damage
								topPlayer = attacker
							end
						end
						if topPlayer and totalDamage > 0 then
							local percentage = math.floor((topDamage / totalDamage) * 100)
							bossEvent:FireAllClients("update", topPlayer.Name, percentage)
						else
							bossEvent:FireAllClients("update", "None", 0)
						end
					else
						bossEvent:FireAllClients("update", "None", 0)
					end
				end
			end)

			local deathConn
			deathConn = humanoid.Died:Connect(function()
				bossState.active = false

				local winnerName = "Nobody"
				if damageSnapshot then
					local topPlayer = nil
					local topDamage = 0
					for attacker, damage in pairs(damageSnapshot) do
						if damage > topDamage then
							topDamage = damage
							topPlayer = attacker
					end
					end
					if topPlayer then
						winnerName = topPlayer.Name
					end
				end

				bossEvent:FireAllClients("end", winnerName)

				character:SetAttribute("BossMode", false)
				if billboard and billboard.Parent then
					billboard.Parent = nil
				end
				if healthConn then healthConn:Disconnect() end
				if deathConn then deathConn:Disconnect() end

				_G.BossSystem = nil
			end)

			local ancestryConn
			ancestryConn = character.AncestryChanged:Connect(function(_, parent)
				if not parent and bossState.active then
					bossState.active = false
					bossEvent:FireAllClients("end", "Nobody")
				if healthConn then healthConn:Disconnect() end
					if deathConn then deathConn:Disconnect() end
					if ancestryConn then ancestryConn:Disconnect() end
					if billboard and billboard.Parent then billboard.Parent = nil end
					_G.BossSystem = nil
				end
			end)

			bossState.cleanup = function()
				bossState.active = false
				if character and character.Parent then
					character:SetAttribute("BossMode", false)
					local hum = character:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.MaxHealth = originalMaxHealth
						hum.WalkSpeed = originalWalkSpeed

						if oldCustomMaxHealth then
							character:SetAttribute("CustomMaxHealth", oldCustomMaxHealth)
						end
					end
				end
				if billboard and billboard.Parent then billboard.Parent = nil end
				if healthConn then healthConn:Disconnect() end
				if deathConn then deathConn:Disconnect() end
				if ancestryConn then ancestryConn:Disconnect() end
				bossEvent:FireAllClients("end", "Nobody")
			end

			_G.BossSystem = bossState
		end
	}

	server.Commands.hd_studioinsert = {
		Prefix = server.Settings.Prefix;
		Commands = {"StudioInsert", "insertmodel", "loadmodel"};
		Args = {"assetId"};
		Description = "Insert a model from the Roblox marketplace by Asset ID";
		Category = "Custom";
		Hidden = false;
		Fun = false;
		AdminLevel = "HeadAdmins";
		Function = function(plr, args)
			local InsertService = game:GetService("InsertService")
			local assetId = tonumber(args[1])
			if not assetId then
				warn("StudioInsert: invalid asset ID provided")
				return
			end

			local success, result = pcall(function()
				return InsertService:LoadAsset(assetId)
			end)

			if not success or not result then
				warn("StudioInsert failed for asset ID " .. tostring(assetId) .. ": " .. tostring(result))
				return
			end

			result.Parent = workspace

			local spawnCFrame = nil
			local character = plr.Character

			if character then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then
					hrp = character.PrimaryPart
				end
				if not hrp then
					for _, descendant in ipairs(character:GetDescendants()) do
						if descendant:IsA("BasePart") then
							hrp = descendant
							break
						end
					end
				end
				if hrp then
					spawnCFrame = hrp.CFrame * CFrame.new(0, 0, -10)
				else
					spawnCFrame = character:GetPivot() * CFrame.new(0, 0, -10)
				end
			end

			if not spawnCFrame then
				local spawnPoints = workspace:FindFirstChild("SpawnPoints")
				if spawnPoints then
					for _, spawn in ipairs(spawnPoints:GetChildren()) do
						if spawn:IsA("BasePart") then
							spawnCFrame = spawn.CFrame * CFrame.new(0, 5, -10)
							break
						end
					end
				end
			end

			if not spawnCFrame then
				spawnCFrame = CFrame.new(0, 10, 0)
			end

			result:PivotTo(spawnCFrame)
			print("StudioInsert: successfully inserted asset " .. tostring(assetId) .. " at " .. tostring(spawnCFrame.Position))
		end
	}

	server.Commands.hd_health = {
		Prefix = server.Settings.Prefix;
		Commands = {"health", "SetHealth", "kaijuhealth", "maxhealth", "setmaxhealth"};
		Args = {"player", "amount"};
		Description = "Set a player's MaxHealth and Health (no cap - works for kaiju with health above 10k)";
		Category = "Custom";
		Hidden = false;
		Fun = false;
		AdminLevel = "HeadAdmins";
		Function = function(plr, args)
			local amount = tonumber(args[2])
			if not amount then return end
			amount = math.max(1, math.floor(amount))

			for _, target in ipairs(getTargets(plr, args[1])) do
				if target.Character then
					local character = target.Character
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						character:SetAttribute("CustomMaxHealth", amount)
						humanoid.MaxHealth = amount
						humanoid.Health = amount

						local stats = character:FindFirstChild("Stats")
						if stats then
							local maxHP = stats:FindFirstChild("MaxHP")
							if maxHP and maxHP:IsA("ValueBase") then
								maxHP.Value = amount
							end
						end

						character:SetAttribute("BaseMaxHP", amount)
					end
				end
			end
		end
	}

	server.Commands.hd_gcells = {
		Prefix = server.Settings.Prefix;
		Commands = {"gcells", "givegcells", "addgcells"};
		Args = {"player", "amount"};
		Description = "Give GCells to a player (e.g. :gcells all 1000 or :gcells me 500)";
		Category = "Custom";
		Hidden = false;
		Fun = false;
		AdminLevel = "HeadAdmins";
		Function = function(plr, args)
			local amount = tonumber(args[2])
			if not amount then return end
			amount = math.floor(amount)

			for _, target in ipairs(getTargets(plr, args[1])) do
				local leaderstats = target:FindFirstChild("leaderstats")
				if not leaderstats then continue end
				local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
				if gcells and gcells:IsA("ValueBase") then
					-- This command is HeadAdmin+, so authorized admins bypass
					-- the GCellGuard anti-cheat entirely for a short window.
					if type(_G.GCellGuardBypass) == "function" then
						_G.GCellGuardBypass(gcells, 5)
					end
					gcells.Value = gcells.Value + amount
					print("[gcells] Gave " .. amount .. " GCells to " .. target.Name .. " (new total: " .. gcells.Value .. ")")
				end
			end
		end
	}

	server.Commands.hd_candy = {
		Prefix = server.Settings.Prefix;
		Commands = {"candy", "givecandy", "addcandy", "removecandy"};
		Args = {"player", "amount"};
		Description = "Give or remove Candy from a player (e.g. :candy all 1000 to give, :candy me -500 to remove)";
		Category = "Custom";
		Hidden = false;
		Fun = false;
		AdminLevel = "HeadAdmins";
		Function = function(plr, args)
			local amount = tonumber(args[2])
			if not amount then return end
			amount = math.floor(amount)

			for _, target in ipairs(getTargets(plr, args[1])) do
				-- HeadAdmin+ bypass: AdminCandy ignores the seasonal
				-- award check and applies the change directly, then saves.
				if type(_G.AdminCandy) == "function" then
					local ok, newTotal = _G.AdminCandy(target, amount)
					if ok then
						print("[candy] " .. (amount >= 0 and "Gave " or "Removed ") .. math.abs(amount) .. " Candy " .. (amount >= 0 and "to " or "from ") .. target.Name .. " (new total: " .. tostring(newTotal) .. ")")
					end
				else
					-- Fallback if CandyService hasn't initialized yet
					local leaderstats = target:FindFirstChild("leaderstats")
					if not leaderstats then continue end
					local candy = leaderstats:FindFirstChild("Candy")
					if candy and candy:IsA("ValueBase") then
						candy.Value = math.max(candy.Value + amount, 0)
						target:SetAttribute("Candy", candy.Value)
						print("[candy] Set " .. target.Name .. " Candy to " .. candy.Value .. " (fallback path)")
					end
				end
			end
		end
	}

	server.Commands.hd_givekaiju = {
		Prefix = server.Settings.Prefix;
		Commands = {"givekaiju"};
		Args = {"player", "kaijuName"};
		Description = "Give a kaiju to a player for free (e.g. :givekaiju me Godzilla In Hell). Not case sensitive.";
		Category = "Custom";
		Hidden = false;
		Fun = false;
		AdminLevel = "HeadAdmins";
		Function = function(plr, args)
			-- Join remaining args so multi-word kaiju names work (e.g. "Godzilla In Hell")
			local kaijuName = joinArgs(args)
			if kaijuName == "" then return end

			for _, target in ipairs(getTargets(plr, args[1])) do
				if type(_G.AdminGiveKaiju) == "function" then
					local ok, result = _G.AdminGiveKaiju(target, kaijuName)
					if ok then
						print("[givekaiju] Gave " .. tostring(result) .. " to " .. target.Name)
					else
						warn("[givekaiju] Failed for " .. target.Name .. ": " .. tostring(result))
					end
				else
					warn("[givekaiju] Data module not loaded yet")
				end
			end
		end
	}

	server.Commands.hd_removekaiju = {
		Prefix = server.Settings.Prefix;
		Commands = {"removekaiju", "takekaiju", "revokekaiju"};
		Args = {"player", "kaijuName"};
		Description = "Remove a kaiju from a player so they must buy it again (e.g. :removekaiju others Gigan). Not case sensitive.";
		Category = "Custom";
		Hidden = false;
		Fun = false;
		AdminLevel = "HeadAdmins";
		Function = function(plr, args)
			-- Join remaining args so multi-word kaiju names work (e.g. "Godzilla In Hell")
			local kaijuName = joinArgs(args)
			if kaijuName == "" then return end

			for _, target in ipairs(getTargets(plr, args[1])) do
				if type(_G.AdminRemoveKaiju) == "function" then
					local removed, result = _G.AdminRemoveKaiju(target, kaijuName)
					if removed then
						print("[removekaiju] Removed " .. tostring(result) .. " from " .. target.Name)
					elseif result then
						print("[removekaiju] " .. target.Name .. " did not own " .. tostring(result))
					end
				else
					warn("[removekaiju] Data module not loaded yet")
				end
			end
		end
	}

	server.Commands.hd_raffle = {
		Prefix = server.Settings.Prefix;
		Commands = {"Raffle"};
		Args = {};
		Description = "Runs a raffle that cycles through all players and picks a random winner!";
		Category = "Custom";
		Hidden = false;
		Fun = true;
		AdminLevel = "HeadAdmins";
		Function = function(plr, args)
			local Players = game:GetService("Players")
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local raffleEvent = ReplicatedStorage:FindFirstChild("RaffleEvent")
			if not raffleEvent then return end

			local allPlayers = Players:GetPlayers()
			if #allPlayers < 2 then return end

			local names = {}
			for _, p in ipairs(allPlayers) do
				table.insert(names, p.Name)
			end

			local winner = allPlayers[math.random(1, #allPlayers)]
			raffleEvent:FireAllClients(names, winner.Name)
		end
	}

	server.Commands.hd_playereliminator = {
		Prefix = server.Settings.Prefix;
		Commands = {"PlayerEliminator", "eliminator", "battleroyale"};
		Args = {"string"};
		Description = "Battle royale mode: locks server to Admin+ only and kicks players on kaiju death. Toggle with on/off.";
		Category = "Custom";
		Hidden = false;
		Fun = false;
		AdminLevel = "HeadAdmins";
		Function = function(plr, args)
			local arg = string.lower(tostring(args[1] or ""))

			if arg == "on" then
				_G.PlayerEliminatorActive = true
				print("PlayerEliminator ACTIVATED! Server is now in battle royale mode.")
				local popupEvent = game.ReplicatedStorage:FindFirstChild("EliminatorPopup")
				if popupEvent then
					popupEvent:FireAllClients("Eliminator activated", "green")
				end
			elseif arg == "off" then
				_G.PlayerEliminatorActive = false
				print("PlayerEliminator DEACTIVATED. Server is back to normal.")
				local popupEvent = game.ReplicatedStorage:FindFirstChild("EliminatorPopup")
				if popupEvent then
					popupEvent:FireAllClients("Eliminator Deactivated", "red")
				end
			else
				warn("Usage: :PlayerEliminator on|off")
			end
		end
	}

	server.Commands.hd_snap = {
		Prefix = server.Settings.Prefix;
		Commands = {"Snap", "snapfade", "disintegrate"};
		Args = {"player"};
		Description = "Fades the target's character to invisible over 5 seconds, plays a sound, then deals 100M damage.";
		Category = "Custom";
		Hidden = false;
		Fun = false;
		AdminLevel = "HeadAdmins";
		Function = function(plr, args)
			for _, target in ipairs(getTargets(plr, args[1])) do
				local character = target.Character
				if not character then continue end
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if not humanoid or humanoid.Health <= 0 then continue end

				local parts = {}
				for _, descendant in ipairs(character:GetDescendants()) do
					if descendant:IsA("BasePart") or descendant:IsA("Decal") then
						table.insert(parts, {instance = descendant, original = descendant.Transparency})
					end
				end

				local hrp = character:FindFirstChild("HumanoidRootPart")
				local soundParent = hrp or character:FindFirstChildWhichIsA("BasePart") or character
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxassetid://75827577587368"
				sound.Volume = 10
				sound.Parent = soundParent
				sound:Play()

				local duration = 5
				local steps = 60
				local stepDuration = duration / steps

				task.spawn(function()
					for i = 1, steps do
					local alpha = i / steps
					for _, partInfo in ipairs(parts) do
						if partInfo.instance and partInfo.instance.Parent then
							partInfo.instance.Transparency = partInfo.original + (1 - partInfo.original) * alpha
						end
					end
					task.wait(stepDuration)
					end

					for _, partInfo in ipairs(parts) do
						if partInfo.instance and partInfo.instance.Parent then
							partInfo.instance.Transparency = 1
						end
					end

					if humanoid and humanoid.Health > 0 then
						humanoid:TakeDamage(100000000)
					end

					task.wait(10)
					if sound and sound.Parent then
						sound:Destroy()
					end
				end)
			end
		end
	}

	server.Commands.hd_kaijusize = {
		Prefix = server.Settings.Prefix;
		Commands = {"KaijuSize", "kaijuscale", "morphsize", "morphscale"};
		Args = {"player", "scale"};
		Description = "Scale your kaiju morph to a specified size (e.g. :KaijuSize me 2)";
		Category = "Custom";
		Hidden = false;
		Fun = false;
		AdminLevel = "Admins";
		Function = function(plr, args)
			local scale = tonumber(args[2])
			if not scale then return end
			scale = math.clamp(scale, 0.1, 100)

			for _, target in ipairs(getTargets(plr, args[1])) do
				local character = target.Character
				if not character then continue end

				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if not humanoid then continue end

				local previous = character:GetAttribute("KaijuScale") or 1
				character:SetAttribute("KaijuScale", scale)
				character:ScaleTo(scale)

				local ratio = scale / previous
				local stats = character:FindFirstChild("Stats")
				if stats then
					for _, statName in ipairs({"WS", "SS", "SwimSpeed"}) do
						local stat = stats:FindFirstChild(statName)
						if stat and stat:IsA("ValueBase") and typeof(stat.Value) == "number" then
							stat.Value = stat.Value * ratio
						end
					end
				end
				humanoid.WalkSpeed = humanoid.WalkSpeed * ratio
			end
		end
	}

	server.Commands.hd_changestat = {
		Prefix = server.Settings.Prefix;
		Commands = {"ChangeStat", "kaijustat", "changestat"};
		Args = {"player", "stat"};
		Description = "Change the stats of one of your kaiju! (e.g. :kaijustat me DMG1 900)";
		Category = "Custom";
		Hidden = false;
		Fun = false;
		AdminLevel = "Admins";
		Function = function(plr, args)
			local combinedText = joinArgs(args)
			if not combinedText or combinedText == "" then return end

			local statName, damageString = string.match(combinedText, "(%S+)%s+(%S+)")
			if not statName or not damageString then
				print("Error: Make sure to type both the stat name and a number!")
				return
			end

			local damage = tonumber(damageString)
			if not damage then return end

			for _, target in ipairs(getTargets(plr, args[1])) do
				local character = target.Character
				if not character then continue end

				local statsFolder = character:FindFirstChild("Stats")
				if not statsFolder then continue end

				-- Case-insensitive loop to match "dmg1" with "DMG1"
				local attackObject = nil
				for _, child in ipairs(statsFolder:GetChildren()) do
					if string.lower(child.Name) == string.lower(statName) then
						attackObject = child
						break
					end
				end

				if attackObject and attackObject:IsA("ValueBase") then
					attackObject.Value = damage
					print("Changed " .. attackObject.Name .. " value to " .. tostring(damage))
				end
			end
		end
	}

	server.Commands.hd_dmgstat = {
		Prefix = server.Settings.Prefix;
		Commands = {"DMGStat", "dmgstat"};
		Args = {"player", "stat"};
		Description = "Change a kaiju damage stat! (e.g. :dmgstat me DMG1 500)";
		Category = "Custom";
		Hidden = false;
		Fun = false;
		AdminLevel = "Admins";
		Function = function(plr, args)
			local combinedText = joinArgs(args)
			if not combinedText or combinedText == "" then return end

			local statName, damageString = string.match(combinedText, "(%S+)%s+(%S+)")
			if not statName or not damageString then
					print("Error: Make sure to type both the stat name and a number! (e.g. :dmgstat me DMG1 500)")
				return
			end

			local damage = tonumber(damageString)
			if not damage then return end

			-- Only allow DMG stats to be changed with this command
			if not string.match(string.upper(statName), "^DMG%d*$") then
				print("Error: Only DMG stats can be changed with dmgstat (e.g. DMG1, DMG2)")
				return
			end

			for _, target in ipairs(getTargets(plr, args[1])) do
				local character = target.Character
				if not character then continue end

				local statsFolder = character:FindFirstChild("Stats")
				if not statsFolder then continue end

				local attackObject = nil
				for _, child in ipairs(statsFolder:GetChildren()) do
					if string.lower(child.Name) == string.lower(statName) then
						attackObject = child
					break
					end
				end

				if attackObject and attackObject:IsA("ValueBase") then
					attackObject.Value = damage
					print("Changed " .. attackObject.Name .. " value to " .. tostring(damage))
				end
			end
		end
	}

	server.Commands.hd_dmg1stat = {
		Prefix = server.Settings.Prefix;
		Commands = {"DMG1Stat", "dmg1stat"};
		Args = {"player", "amount"};
		Description = "Set your kaiju's first attack damage! (e.g. :dmg1stat me 500)";
		Category = "Custom";
		Hidden = false;
		Fun = false;
		AdminLevel = "Admins";
		Function = function(plr, args)
			local damage = tonumber(args[2])
			if not damage then
				print("Error: Make sure to type a number! (e.g. :dmg1stat me 500)")
				return
			end

			for _, target in ipairs(getTargets(plr, args[1])) do
				local character = target.Character
				if not character then continue end

				local statsFolder = character:FindFirstChild("Stats")
				if not statsFolder then continue end

				local attackObject = statsFolder:FindFirstChild("DMG1")
				if attackObject and attackObject:IsA("ValueBase") then
					attackObject.Value = damage
					print("Changed " .. attackObject.Name .. " value to " .. tostring(damage))
				end
			end
		end
	}

	server.Commands.hd_dmg2stat = {
		Prefix = server.Settings.Prefix;
		Commands = {"DMG2Stat", "dmg2stat"};
		Args = {"player", "amount"};
		Description = "Set your kaiju's second attack damage! (e.g. :dmg2stat me 40)";
		Category = "Custom";
		Hidden = false;
		Fun = false;
		AdminLevel = "Admins";
		Function = function(plr, args)
			local damage = tonumber(args[2])
			if not damage then
				print("Error: Make sure to type a number! (e.g. :dmg2stat me 40)")
				return
			end

			for _, target in ipairs(getTargets(plr, args[1])) do
				local character = target.Character
				if not character then continue end

				local statsFolder = character:FindFirstChild("Stats")
				if not statsFolder then continue end

				local attackObject = statsFolder:FindFirstChild("DMG2")
				if attackObject and attackObject:IsA("ValueBase") then
					attackObject.Value = damage
					print("Changed " .. attackObject.Name .. " value to " .. tostring(damage))
				end
			end
		end
	}

	-- DMG3Stat through DMG6Stat: same behavior as DMG1Stat/DMG2Stat,
		-- generated in a loop since they only differ by stat name.
		for statIndex = 3, 6 do
			local statName = "DMG" .. statIndex
			server.Commands["hd_dmg" .. statIndex .. "stat"] = {
				Prefix = server.Settings.Prefix;
				Commands = {statName .. "Stat", string.lower(statName) .. "stat"};
				Args = {"player", "amount"};
				Description = "Set your kaiju's attack " .. statIndex .. " damage! (e.g. :dmg" .. statIndex .. "stat me 40)";
				Category = "Custom";
				Hidden = false;
				Fun = false;
				AdminLevel = "Admins";
				Function = function(plr, args)
					local damage = tonumber(args[2])
					if not damage then
						print("Error: Make sure to type a number! (e.g. :dmg" .. statIndex .. "stat me 40)")
						return
					end

					for _, target in ipairs(getTargets(plr, args[1])) do
						local character = target.Character
						if not character then continue end

						local statsFolder = character:FindFirstChild("Stats")
						if not statsFolder then continue end

						local attackObject = statsFolder:FindFirstChild(statName)
						if attackObject and attackObject:IsA("ValueBase") then
							attackObject.Value = damage
							print("Changed " .. attackObject.Name .. " value to " .. tostring(damage))
						end
					end
				end
			}
		end
end