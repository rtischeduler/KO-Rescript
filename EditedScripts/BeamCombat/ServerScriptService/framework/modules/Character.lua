
local Character = {}

function Character.Init()
	
	local GamepassWhitelist = {
		[274893778] = true
	}

	local function initLoad()
		local Players = game:GetService("Players")
		Players.CharacterAutoLoads = false
	end


	local function initMorph()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local ServerScriptService = game:GetService("ServerScriptService")
		if ServerScriptService:FindFirstChild("MorphBootstrap") or ServerScriptService:GetAttribute("MorphBootstrapActive") then return end


		local morphReady = ReplicatedStorage:FindFirstChild("MorphReady")
		if morphReady and not morphReady:IsA("BoolValue") then
			morphReady:Destroy()
			morphReady = nil
		end
		if not morphReady then
			morphReady = Instance.new("BoolValue")
			morphReady.Name = "MorphReady"
			morphReady.Parent = ReplicatedStorage
		end
		morphReady.Value = false
		morphReady:SetAttribute("Error", nil)

		local morphSupplies = ReplicatedStorage:FindFirstChild("MorphSupplies")
		if not morphSupplies then
			morphSupplies = Instance.new("Folder")
			morphSupplies.Name = "MorphSupplies"
			morphSupplies.Parent = ReplicatedStorage
		end
		local eventsFolder = morphSupplies:FindFirstChild("Events")
		if not eventsFolder then
			eventsFolder = Instance.new("Folder")
			eventsFolder.Name = "Events"
			eventsFolder.Parent = morphSupplies
		end
		local event = eventsFolder:FindFirstChild("Fire")
		if event and not event:IsA("RemoteEvent") then
			event:Destroy()
			event = nil
		end
		if not event then
			event = Instance.new("RemoteEvent")
			event.Name = "Fire"
			event.Parent = eventsFolder
		end

		local securityOk, SecurityPolicy = pcall(function()
			return require(ServerScriptService:WaitForChild("SecurityPolicy", 10))
		end)
		if not securityOk or type(SecurityPolicy) ~= "table" or type(SecurityPolicy.CanUseMorph) ~= "function" then
			local errorText = "SecurityPolicy could not be loaded"
			if not securityOk then errorText = tostring(SecurityPolicy) end
			morphReady:SetAttribute("Error", errorText)
			warn("[Character] " .. errorText)
			return
		end

		local morphResultEvent = ReplicatedStorage:FindFirstChild("MorphResult")
		if morphResultEvent and not morphResultEvent:IsA("RemoteEvent") then
			morphResultEvent:Destroy()
			morphResultEvent = nil
		end
		if not morphResultEvent then
			morphResultEvent = Instance.new("RemoteEvent")
			morphResultEvent.Name = "MorphResult"
			morphResultEvent.Parent = ReplicatedStorage
		end

		local TANK_SPAWN_MORPHS = {
			["MILITARY TANK [FREE]"] = true,
			["F16C [FREE]"] = true,
		}

		local RESTRICTED_KAIJU = {
			[string.lower("EVOLVED GOJIRA")] = true,
			[string.lower("D.E.M.O.N")] = true,
			[string.lower("Homelander")] = true,
			[string.lower("d")] = true,
			[string.lower("A-train")] = true,
			[string.lower("e")] = true,
			[string.lower("MG21")] = true,
		}

		local ALLOWED_PLAYERS = {
			[string.lower("AthosGame2023")] = true,
			[string.lower("mr_bolde2")] = true,
			[string.lower("DenisTheCheeseKing")] = true,
			[string.lower("BlueEnderCookie_2")] = true,
		}

		event.OnServerEvent:Connect(function(player, selectedCreature)
			local ok, err = pcall(function()
				local morphFolder = ReplicatedStorage:FindFirstChild("MorphSupplies")
				morphFolder = morphFolder and morphFolder:FindFirstChild("Morphs")
				if type(selectedCreature) == "string" and morphFolder then
					selectedCreature = morphFolder:FindFirstChild(selectedCreature, true)
				end
				if typeof(selectedCreature) ~= "Instance" or not selectedCreature:IsA("Model") then
					morphResultEvent:FireClient(player, false, "Invalid morph")
					return
				end
				if not SecurityPolicy.CanUseMorph(player, selectedCreature) then
					warn("[SecurityPolicy] Rejected unauthorized morph request from " .. player.Name)
					morphResultEvent:FireClient(player, false, "You do not own this kaiju")
					return
				end
				local controlTemplate = ReplicatedStorage:FindFirstChild("PlayerScripts")
				controlTemplate = controlTemplate and controlTemplate:FindFirstChild("Control")
				if not controlTemplate then
					morphResultEvent:FireClient(player, false, "Control script missing")
					return
				end

				if selectedCreature and RESTRICTED_KAIJU[string.lower(selectedCreature.Name)] then
					if not ALLOWED_PLAYERS[string.lower(player.Name)] then
						player:Kick("You cannot use this kaiju.")
						return
					end
				end

				local newModel = selectedCreature:Clone()
				local oldCharacter = player.Character

				for _, desc in ipairs(newModel:GetDescendants()) do
					if desc:IsA("BasePart") then
						desc:SetAttribute("OriginalColor", desc.Color)
						desc:SetAttribute("OriginalMaterial", desc.Material.Name)
					end
				end

				newModel.Name = player.Name

				if not newModel.PrimaryPart then
					local hrp = newModel:FindFirstChild("HumanoidRootPart")
					if hrp then
						newModel.PrimaryPart = hrp
					end
				end

				local Control = controlTemplate:Clone()
				Control.Disabled = true
				Control.Parent = newModel

				local KaijuName = Instance.new("StringValue")
				KaijuName.Parent = newModel
				KaijuName.Name = "Kaiju"
				KaijuName.Value = selectedCreature.Name

				local clonedLevelsScript
				local LevelsScript = ServerScriptService:FindFirstChild("Levels") and ServerScriptService.Levels:FindFirstChild("Levels")
				if LevelsScript then
					clonedLevelsScript = LevelsScript:Clone()
					clonedLevelsScript.Disabled = true
					clonedLevelsScript.Parent = newModel
				end

				local spawnCFrame = nil
				local morphName = selectedCreature.Name

				if TANK_SPAWN_MORPHS[morphName] then
					local tankSpawns = workspace:FindFirstChild("TankSpawns")
					if tankSpawns then
						local spawns = tankSpawns:GetChildren()
						if #spawns > 0 then
							local randomSpawn = spawns[math.random(1, #spawns)]
							if randomSpawn:IsA("BasePart") then
								spawnCFrame = randomSpawn.CFrame + Vector3.new(0, 10, 0)
							end
						end
					end
				end

				if not spawnCFrame then
					local spawnPoints = workspace:FindFirstChild("SpawnPoints")
					if spawnPoints then
						local spawns = spawnPoints:GetChildren()
						if #spawns > 0 then
							local randomSpawn = spawns[math.random(1, #spawns)]
							if randomSpawn:IsA("BasePart") then
								spawnCFrame = randomSpawn.CFrame + Vector3.new(0, 50, 0)
							end
						end
					end
				end

				if spawnCFrame then
					newModel:PivotTo(spawnCFrame)
				end

				newModel.Parent = game.Workspace
				player.Character = newModel
				if oldCharacter and oldCharacter.Parent then
					oldCharacter:Destroy()
				end
				Control.Disabled = false
				if clonedLevelsScript then
					clonedLevelsScript.Disabled = false
				end

				local humanoid = newModel:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
					humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				end

				morphResultEvent:FireClient(player, true, selectedCreature.Name)
				print("Successfully morphed the player!")
			end)
			if not ok then
				warn("[Character] Morph failed: " .. tostring(err))
				morphResultEvent:FireClient(player, false, "Server morph error: " .. tostring(err))
			end
		end)
	end



	local function initCleanup()
		local Players = game:GetService("Players")

		local function onCharacterAdded(character)
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then
				humanoid = character:WaitForChild("Humanoid", 5)
				if not humanoid then return end
			end

			humanoid.Died:Connect(function()
				task.wait(4)
				if character and character.Parent then
					for _, desc in ipairs(character:GetDescendants()) do
						if desc:IsA("BasePart") then
							desc.CanTouch = false
							desc.CanQuery = false
							desc.Transparency = 1
						elseif desc:IsA("ParticleEmitter") or desc:IsA("Fire") or desc:IsA("Smoke") or desc:IsA("Trail") or desc:IsA("Beam") then
							desc.Enabled = false
						end
					end
				end
			end)
		end

		local function onPlayerAdded(player)
			player.CharacterAdded:Connect(onCharacterAdded)
		end

		Players.PlayerAdded:Connect(onPlayerAdded)

		for _, player in Players:GetPlayers() do
			onPlayerAdded(player)
		end
	end


	local function initBlood()
		local Players = game:GetService("Players")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local Workspace = game:GetService("Workspace")

		Workspace.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("BasePart") and descendant.Name == "AttackHitbox" and descendant:GetAttribute("MeleeHit") then
				local attackerChar = descendant.Parent
				if attackerChar then
					attackerChar:SetAttribute("MeleeHit", true)
					task.delay(0.6, function()
						if attackerChar and attackerChar.Parent then
							attackerChar:SetAttribute("MeleeHit", nil)
						end
					end)
				end
			end
		end)

		for _, descendant in ipairs(Workspace:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant.Name == "AttackHitbox" and descendant:GetAttribute("MeleeHit") then
				local attackerChar = descendant.Parent
				if attackerChar then
					attackerChar:SetAttribute("MeleeHit", true)
					task.delay(0.6, function()
						if attackerChar and attackerChar.Parent then
							attackerChar:SetAttribute("MeleeHit", nil)
						end
					end)
				end
			end
		end

		local function spawnBlood(character)
			local bloodTemplate = ReplicatedStorage:FindFirstChild("Blood")
			if not bloodTemplate then return end

			local targetPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
			if not targetPart then return end

			local bloodClone = bloodTemplate:Clone()
			bloodClone.CFrame = CFrame.new(0, 0, 0)
			bloodClone.Visible = true
			bloodClone.Parent = targetPart
			for _, child in ipairs(bloodClone:GetChildren()) do
				if child:IsA("ParticleEmitter") then
					child.Enabled = true
				end
			end
			task.delay(0.7, function()
				if bloodClone and bloodClone.Parent then
					for _, child in ipairs(bloodClone:GetChildren()) do
						if child:IsA("ParticleEmitter") then
							child.Rate = 0
						end
					end
					task.delay(1, function()
						if bloodClone and bloodClone.Parent then
							bloodClone.Parent = nil
						end
					end)
				end
			end)
		end

		local function monitorCharacter(character)
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end

			local prevHealth = humanoid.Health

			humanoid.HealthChanged:Connect(function(newHealth)
				if newHealth >= prevHealth then
					prevHealth = newHealth
					return
				end

				prevHealth = newHealth

				local creator = humanoid:FindFirstChild("creator")
				if not creator or not creator.Value then return end

				local attackerPlayer = creator.Value
				if not attackerPlayer or not attackerPlayer:IsA("Player") then return end

				local attackerChar = attackerPlayer.Character
				if not attackerChar then return end

				if attackerChar:GetAttribute("MeleeHit") then
					spawnBlood(character)
				end
			end)
		end

		local function onPlayerAdded(player)
			player.CharacterAdded:Connect(monitorCharacter)
			if player.Character then
				monitorCharacter(player.Character)
			end
		end

		Players.PlayerAdded:Connect(onPlayerAdded)
		for _, player in ipairs(Players:GetPlayers()) do
			onPlayerAdded(player)
		end
	end





	local function initTags()
		local Players = game:GetService("Players")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")

		local TAG_TEMPLATE = ReplicatedStorage:FindFirstChild("Tag")

		local function getLevelValue(player, character)
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local lvl = leaderstats:FindFirstChild("Level")
				if lvl then return lvl end
			end
			if character then
				local lvl = character:FindFirstChild("Level")
				if lvl then return lvl end
			end
			return nil
		end

		local function giveTag(player)
			local character = player.Character
			if not character then return end

			local head = character:FindFirstChild("Head")
			if not head then return end

			local existingTag = head:FindFirstChild("Tag")
			if existingTag then existingTag.Parent = nil end

			if not TAG_TEMPLATE then return end

			local tag = TAG_TEMPLATE:Clone()
			tag.Name = "Tag"
			tag.Parent = head

			local nameLabel = tag:FindFirstChild("Name")
			if nameLabel then
				nameLabel.Text = player.DisplayName
			end

			local levelLabel = tag:FindFirstChild("Level")
			if levelLabel then
				local levelVal = getLevelValue(player, character)
				levelLabel.Text = "Level " .. tostring(levelVal and levelVal.Value or 1)

				if levelVal then
					levelVal.Changed:Connect(function(newVal)
						if tag.Parent then
							levelLabel.Text = "Level " .. tostring(newVal)
						end
					end)
				end

				character.ChildAdded:Connect(function(child)
					if child.Name == "Level" and child:IsA("IntValue") then
						levelLabel.Text = "Level " .. tostring(child.Value)
						child.Changed:Connect(function(newVal)
							if tag.Parent then
								levelLabel.Text = "Level " .. tostring(newVal)
							end
						end)
					end

					local leaderstats = player:FindFirstChild("leaderstats")
					if leaderstats and child.Parent == leaderstats and child.Name == "Level" then
						levelLabel.Text = "Level " .. tostring(child.Value)
						child.Changed:Connect(function(newVal)
							if tag.Parent then
								levelLabel.Text = "Level " .. tostring(newVal)
							end
						end)
					end
				end)
			end

			local hpLabel = tag:FindFirstChild("HP")
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if hpLabel and humanoid then
				hpLabel.Text = "HP - " .. tostring(math.floor(humanoid.Health))
				humanoid.HealthChanged:Connect(function(newHealth)
					if tag.Parent then
						hpLabel.Text = "HP - " .. tostring(math.floor(newHealth))
					end
				end)
			end

			if humanoid then
				humanoid.Died:Connect(function()
					tag.Parent = nil
				end)
			end
		end

		local function onPlayerAdded(player)
			player.CharacterAdded:Connect(function()
				task.wait(0.1)
				giveTag(player)
			end)

			if player.Character then
				task.wait(0.1)
				giveTag(player)
			end
		end

		Players.PlayerAdded:Connect(onPlayerAdded)

		for _, player in ipairs(Players:GetPlayers()) do
			onPlayerAdded(player)
		end
	end


	local function initHealthDisplay()
		local Players = game:GetService("Players")

		local setHumanoids = {}
		local teleportedPlayers = {}

		local healthTemplate = game.ReplicatedStorage.MorphSupplies.Morphs:FindFirstChild("GOJIRA [FREE]")
		if healthTemplate then
			local characterScripts = healthTemplate:FindFirstChild("CharacterScripts")
			if characterScripts then
				local sounds = characterScripts:FindFirstChild("Sounds")
				if sounds then
					healthTemplate = sounds:FindFirstChild("Health")
				end
			end
		end

		local function createHealthGui()
			local billboardGui = Instance.new("BillboardGui")
			billboardGui.Name = "Health"
			billboardGui.Size = UDim2.new(0, 100, 0, 50)
			billboardGui.StudsOffset = Vector3.new(0, 3, 0)
			billboardGui.AlwaysOnTop = true
			billboardGui.MaxDistance = 150

			local label = Instance.new("TextLabel")
			label.Name = "Label"
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 0.8
			label.BackgroundColor3 = Color3.fromRGB(115, 115, 115)
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextScaled = true
			label.TextStrokeTransparency = 0
			label.TextStrokeColor3 = Color3.new(0, 0, 0)
			label.Text = "HP - 100"
			label.Parent = billboardGui

			return billboardGui
		end

		local function updateHealthDisplay(character)
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end

			local head = character:FindFirstChild("FakeHead") or character:FindFirstChild("Fakehead") or character:FindFirstChild("Head")
			if not head then return end

			local healthGui = head:FindFirstChild("Health")
			if not healthGui then
				if healthTemplate then
					healthGui = healthTemplate:Clone()
					healthGui.Parent = head
				else
					healthGui = createHealthGui()
					healthGui.Parent = head
				end

				local player = Players:GetPlayerFromCharacter(character)
				if player and not teleportedPlayers[player] then
					teleportedPlayers[player] = true

					local spawnPoints = game.Workspace:FindFirstChild("SpawnPoints")
					if spawnPoints then
						local spawns = spawnPoints:GetChildren()
						if #spawns > 0 then
							local randomSpawn = spawns[math.random(1, #spawns)]
							if randomSpawn:IsA("BasePart") then
								character:PivotTo(randomSpawn.CFrame + Vector3.new(0, 3, 0))
							end
						end
					end
				end
			end

			local label = healthGui:FindFirstChild("Label")
			if label then
				label.Text = "HP - " .. math.floor(humanoid.Health)
			end
		end

		local function setupCharacter(character)
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then return end

			if not setHumanoids[humanoid] then
				local stats = character:FindFirstChild("Stats")
				if stats then
					local maxHP = stats:FindFirstChild("MaxHP")
					if maxHP and maxHP:IsA("ValueBase") then
						humanoid.MaxHealth = maxHP.Value
						humanoid.Health = maxHP.Value
						setHumanoids[humanoid] = true
					end
				end
			end

			updateHealthDisplay(character)

			humanoid.HealthChanged:Connect(function()
				updateHealthDisplay(character)
			end)

			task.spawn(function()
				while character and character.Parent do
					task.wait(0.5)
					updateHealthDisplay(character)
				end
			end)
		end

		local function onPlayerAdded(player)
			player.CharacterAdded:Connect(function(character)
				setupCharacter(character)
			end)

			if player.Character then
				setupCharacter(player.Character)
			end
		end

		for _, player in Players:GetPlayers() do
			onPlayerAdded(player)
		end

		Players.PlayerAdded:Connect(onPlayerAdded)
	end


	task.spawn(initLoad)
	task.spawn(initMorph)
	task.spawn(initCleanup)
	task.spawn(initBlood)
	task.spawn(initTags)
	task.spawn(initHealthDisplay)
end

return Character