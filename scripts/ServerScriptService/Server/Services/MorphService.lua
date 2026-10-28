local MorphService = { Name = "Morph" }

function MorphService:Init()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")
	local Workspace = game:GetService("Workspace")

	local framework = script:FindFirstAncestor("Server")
	local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Util"))
	local Logger = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Logger"))
	local cfg = require(framework.Config).Morph
	local log = Logger.new("Morph")

	if ServerScriptService:GetAttribute("MorphBootstrapActive") then
		error("MorphBootstrapActive already set by another script; not registering a second morph handler")
	end
	ServerScriptService:SetAttribute("MorphBootstrapActive", true)

	local morphReady = Util.getOrCreate(ReplicatedStorage, "BoolValue", "MorphReady")
	morphReady.Value = false
	morphReady:SetAttribute("Error", nil)

	local morphSupplies = Util.getOrCreate(ReplicatedStorage, "Folder", "MorphSupplies")
	local events = Util.getOrCreate(morphSupplies, "Folder", "Events")
	local fireEvent = Util.getOrCreate(events, "RemoteEvent", "Fire")
	local morphResult = Util.getOrCreate(ReplicatedStorage, "RemoteEvent", "MorphResult")

	local securityOk, SecurityPolicy = pcall(function()
		return require(ServerScriptService:WaitForChild("SecurityPolicy", 10))
	end)
	if not securityOk or type(SecurityPolicy) ~= "table" or type(SecurityPolicy.CanUseMorph) ~= "function" then
		local reason = securityOk and "SecurityPolicy.CanUseMorph is missing" or tostring(SecurityPolicy)
		morphReady:SetAttribute("Error", reason)
		error(reason)
	end

	local tankSpawnMorphs = {}
	for _, name in ipairs(cfg.TankSpawnMorphs) do
		tankSpawnMorphs[name] = true
	end
	local restrictedKaiju = Util.lowerSet(cfg.RestrictedKaiju)
	local allowedPlayers = Util.lowerSet(cfg.AllowedPlayers)
	local allowedUserIds = {}
	for _, id in ipairs(cfg.AllowedUserIds) do
		allowedUserIds[id] = true
	end

	local function fail(player, message)
		morphResult:FireClient(player, false, nil, message)
	end

	local function pickSpawnCFrame(morphName)
		local isTank = tankSpawnMorphs[morphName] == true
		local folder = Workspace:FindFirstChild(isTank and "TankSpawns" or "SpawnPoints")
		if not folder then
			return nil
		end
		local points = folder:GetChildren()
		local point = #points > 0 and points[math.random(1, #points)] or nil
		if point and point:IsA("BasePart") then
			return point.CFrame + Vector3.new(0, isTank and cfg.TankSpawnHeight or cfg.SpawnHeight, 0)
		end
		return nil
	end

	fireEvent.OnServerEvent:Connect(function(player, selectedCreature)
		local ok, err = pcall(function()
			local morphs = morphSupplies:FindFirstChild("Morphs")
			if type(selectedCreature) == "string" and morphs then
				selectedCreature = morphs:FindFirstChild(selectedCreature, true)
			end
			if typeof(selectedCreature) ~= "Instance" or not selectedCreature:IsA("Model") then
				fail(player, "Invalid morph")
				return
			end
			if not SecurityPolicy.CanUseMorph(player, selectedCreature) then
				fail(player, "You do not own this kaiju")
				return
			end
			if
				restrictedKaiju[string.lower(selectedCreature.Name)]
				and not (allowedPlayers[string.lower(player.Name)] or allowedUserIds[player.UserId])
			then
				player:Kick("You cannot use this kaiju.")
				return
			end

			local controlTemplate = ReplicatedStorage:FindFirstChild("PlayerScripts")
			controlTemplate = controlTemplate and controlTemplate:FindFirstChild("Control")
			if not controlTemplate then
				fail(player, "Control script missing")
				return
			end

			local newModel = selectedCreature:Clone()
			local oldCharacter = player.Character
			for _, descendant in ipairs(newModel:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant:SetAttribute("OriginalColor", descendant.Color)
					descendant:SetAttribute("OriginalMaterial", descendant.Material.Name)
				end
			end
			newModel.Name = player.Name
			if not newModel.PrimaryPart then
				local root = newModel:FindFirstChild("HumanoidRootPart")
				if root then
					newModel.PrimaryPart = root
				end
			end

			local control = controlTemplate:Clone()
			control.Disabled = true
			control.Parent = newModel

			local kaijuName = Instance.new("StringValue")
			kaijuName.Name = "Kaiju"
			kaijuName.Value = selectedCreature.Name
			kaijuName.Parent = newModel

			local levelsFolder = ServerScriptService:FindFirstChild("Levels")
			local levelsTemplate = levelsFolder and levelsFolder:FindFirstChild("Levels")
			local levelsScript
			if levelsTemplate then
				levelsScript = levelsTemplate:Clone()
				levelsScript.Disabled = true
				levelsScript.Parent = newModel
			end

			local spawnCFrame = pickSpawnCFrame(selectedCreature.Name)
			if spawnCFrame then
				newModel:PivotTo(spawnCFrame)
			end

			newModel.Parent = Workspace
			player.Character = newModel
			if oldCharacter and oldCharacter.Parent then
				oldCharacter:Destroy()
			end
			control.Disabled = false
			if levelsScript then
				levelsScript.Disabled = false
			end

			local humanoid = newModel:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
				humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			end
			morphResult:FireClient(player, true, selectedCreature.Name, nil)
			log:info("Morphed " .. player.Name .. " into " .. selectedCreature.Name)
		end)
		if not ok then
			log:warn("Morph failed: " .. tostring(err))
			fail(player, "Server morph error: " .. tostring(err))
		end
	end)

	morphReady.Value = true
	log:info("Morph server ready")
end

return MorphService
