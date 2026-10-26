
local main = _G.HDAdminMain
local settings = main.settings




local module = {
	
	
	
	{
		Name = "xp";
		Aliases = {};
		Prefixes = {};
		Rank = 3; 
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "Give XP to a player for testing levels";
		Contributors = {};
		
		Args = {
			"player";
			"amount";
		};
		Function = function(speaker, args)
			
			_G.XP_CMD_DEBUG = {
				args1_type = type(args[1]),
				args1_tostring = tostring(args[1]),
				args2_type = type(args[2]),
				args2_tostring = tostring(args[2]),
				speaker = tostring(speaker),
			}

			local amount = tonumber(args[2])
			if not amount then
				_G.XP_CMD_DEBUG.result = "amount is nil"
				return
			end

			local targetPlayers = {}
			local players = args[1]
			if type(players) == "table" then
				for _, v in ipairs(players) do
					table.insert(targetPlayers, v)
				end
			elseif typeof(players) == "Instance" and players:IsA("Player") then
				table.insert(targetPlayers, players)
			end

			_G.XP_CMD_DEBUG.target_count = #targetPlayers

			for _, plr in ipairs(targetPlayers) do
				if plr and plr.Character then
					local addXP = plr.Character:FindFirstChild("AddXP")
					if addXP and addXP:IsA("BindableEvent") then
						addXP:Fire(amount)
						_G.XP_CMD_DEBUG.result = "Fired AddXP for " .. tostring(plr) .. " amount " .. amount
					else
					_G.XP_CMD_DEBUG.result = "No AddXP on " .. tostring(plr)
				end
				else
					_G.XP_CMD_DEBUG.result = "No character for " .. tostring(plr)
				end
			end
		end;
		
	};
	
	{
		Name = "Boss";
		Aliases = {};
		Prefixes = {};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "Become the Boss with 20,000 HP, 1.5x speed, and a red title. Top damage dealer wins when the boss falls!";
		Contributors = {};
		
		Args = {
			"player";
		};
		Function = function(speaker, args)
			local Players = game:GetService("Players")
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local bossEvent = ReplicatedStorage:FindFirstChild("BossEvent")
			if not bossEvent then return end
			
			local targetPlayers = {}
			local players = args[1]
			if type(players) == "table" then
				for _, v in ipairs(players) do
					table.insert(targetPlayers, v)
				end
			elseif typeof(players) == "Instance" and players:IsA("Player") then
				table.insert(targetPlayers, players)
			end
			
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
			humanoid.MaxHealth = 20000
			humanoid.Health = 20000
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
			humanoid.HealthChanged:Connect(function(health)
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
		end;
	};
	
	{
		Name = "StudioInsert";
		Aliases = {"insertmodel", "loadmodel"};
		Prefixes = {};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "Insert a model from the Roblox marketplace by Asset ID";
		Contributors = {};
		
		Args = {
			"assetId";
		};
		Function = function(speaker, args)
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
			local character = speaker.Character
			
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
		end;
		
	};
	
	{
		Name = "health";
		Aliases = {"SetHealth", "kaijuhealth", "maxhealth", "setmaxhealth"};
		Prefixes = {};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "Set a player's MaxHealth and Health (no cap - works for kaiju with health above 10k)";
		Contributors = {};
		
		Args = {
			"player";
			"amount";
		};
		Function = function(speaker, args)
			local targetPlayers = {}
			local players = args[1]
			if type(players) == "table" then
				for _, v in ipairs(players) do
					table.insert(targetPlayers, v)
				end
			elseif typeof(players) == "Instance" and players:IsA("Player") then
				table.insert(targetPlayers, players)
			end
			
			local amount = tonumber(args[2])
			if not amount then return end
			amount = math.max(1, math.floor(amount))
			
			for _, plr in ipairs(targetPlayers) do
				if plr.Character then
					local character = plr.Character
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
		end;
		
	};
	
	{
		Name = "Raffle";
		Aliases = {};
		Prefixes = {};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "Runs a raffle that cycles through all players and picks a random winner!";
		Contributors = {};
		
		Args = {};
		Function = function(speaker, args)
			local Players = game:GetService("Players")
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local raffleEvent = ReplicatedStorage:FindFirstChild("RaffleEvent")
			if not raffleEvent then return end
			
			local allPlayers = Players:GetPlayers()
			if #allPlayers < 2 then return end
			
			local names = {}
			for _, plr in ipairs(allPlayers) do
				table.insert(names, plr.Name)
			end
			
			local winner = allPlayers[math.random(1, #allPlayers)]
			raffleEvent:FireAllClients(names, winner.Name)
		end;
	};
	
	{
		Name = "PlayerEliminator";
		Aliases = {"eliminator", "battleroyale"};
		Prefixes = {};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "Battle royale mode: locks server to Admin+ only and kicks players on kaiju death. Toggle with on/off.";
		Contributors = {};
		
		Args = {
			"string";
		};
		Function = function(speaker, args)
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
				warn("Usage: ;PlayerEliminator on|off")
			end
		end;
		
	};

	{
		Name = "Snap";
		Aliases = {"snapfade", "disintegrate"};
		Prefixes = {};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "Fades the target's character to invisible over 5 seconds, plays a sound, then deals 100M damage.";
		Contributors = {};
		
		Args = {
			"player";
		};
		Function = function(speaker, args)
			local targetPlayers = {}
			local players = args[1]
			if type(players) == "table" then
				for _, v in ipairs(players) do
					table.insert(targetPlayers, v)
				end
			elseif typeof(players) == "Instance" and players:IsA("Player") then
				table.insert(targetPlayers, players)
			end
			
			for _, plr in ipairs(targetPlayers) do
				local character = plr.Character
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
		end;
		
	};

	{
		Name = "KaijuSize";
		Aliases = {"kaijuscale", "morphsize", "morphscale"};
		Prefixes = {};
		Rank = 2;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "Scale your kaiju morph to a specified size (e.g. ;KaijuSize me 2)";
		Contributors = {};

		Args = {
			"player";
			"scale";
		};
		Function = function(speaker, args)
			local targetPlayers = {}
			local players = args[1]
			if type(players) == "table" then
				for _, v in ipairs(players) do
					table.insert(targetPlayers, v)
				end
			elseif typeof(players) == "Instance" and players:IsA("Player") then
				table.insert(targetPlayers, players)
			end

			local scale = tonumber(args[2])
			if not scale then return end
			scale = math.clamp(scale, 0.1, 100)

			for _, plr in ipairs(targetPlayers) do
				local character = plr.Character
				if not character then continue end

				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if not humanoid then continue end

				character:ScaleTo(scale)
				character:SetAttribute("KaijuScale", scale)
			end
		end;

	};
	
	{
		Name = "ChangeStat";
		Aliases = {"kaijustat", "changestat"};
		Prefixes = {};
		Rank = 2;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "Change the stats of one of your kaiju! (e.g. ;kaijustat me DMG1 900)";
		Contributors = {};

		Args = {
			"player";
			"string"; 
		};
		Function = function(speaker, args)
			local targetPlayers = {}
			local players = args[1]
			if type(players) == "table" then
				for _, v in ipairs(players) do
					table.insert(targetPlayers, v)
				end
			elseif typeof(players) == "Instance" and players:IsA("Player") then
				table.insert(targetPlayers, players)
			end

			local combinedText = args[2]
			if not combinedText then return end


			local statName, damageString = string.match(combinedText, "(%S+)%s+(%S+)")
			if not statName or not damageString then 
				print("Error: Make sure to type both the stat name and a number!")
				return 
			end

			local damage = tonumber(damageString)
			if not damage then return end


			for _, plr in ipairs(targetPlayers) do
				local character = plr.Character
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
		end;
	};

};



return module
