
local Data = {}

function Data.Init()
	
	local GamepassWhitelist = {
		[274893778] = true
	}
	
	local function initOwnership()
		local DataStoreService = game:GetService("DataStoreService")
		local Players = game:GetService("Players")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local Lighting = game:GetService("Lighting")
		local MarketplaceService = game:GetService("MarketplaceService")

		local KaijuDataStore = DataStoreService:GetDataStore("Ownership")
		local LevelDataStore = DataStoreService:GetDataStore("PlayerLevels_v3")
		local KaijusUnused = Lighting:FindFirstChild("KaijusUnused")
		if not KaijusUnused then
			warn("KaijusUnused not found in Lighting at script start - will retry on demand")
		end
		local Morphs = ReplicatedStorage:FindFirstChild("MorphSupplies")
		if Morphs then Morphs = Morphs:FindFirstChild("Morphs") end
		local CandyConfig = require(ReplicatedStorage:WaitForChild("CandyConfig"))

		local playerKaijus = {}

		local getOwnershipEvent = Instance.new("RemoteFunction")
		getOwnershipEvent.Name = "GetKaijuOwnership"
		getOwnershipEvent.Parent = ReplicatedStorage

		local buyKaijuEvent = Instance.new("RemoteEvent")
		buyKaijuEvent.Name = "BuyKaiju"
		buyKaijuEvent.Parent = ReplicatedStorage

		local nameMapping = {
			["Godzilla2014"] = "GODZILLA 2014",
			["TitanusGhidorah"] = "TITANUS GHIDORAH",
			["Godzilla2019"] = "TITANUS GOJIRA",
			["F16C"] = "F16C [FREE]",
			["Mosura"] = "TITANUS MOSURA",
			["Behemoth"] = "TITANUS BEHEMOTH",
			["Gigan"] = "GIGAN",
			["Anguirus"] = "ANGUIRUS [FREE]",
			["Biollante"] = "BIOLLANTE",
			["Burning"] = "BURNING GODZILLA",
			["FinalWars"] = "FINAL WARS GODZILLA",
			["Heisei"] = "HEISEI GODZILLA",
			["KamataKun"] = "SHIN FORM 2 [FREE]",
			["KingGhidorah"] = "KING GHIDORAH",
			["MaleMuto"] = "MALE MUTO",
			["Mothra"] = "MOTHRA",
			["Rodan"] = "TITANUS RODAN",
			["Shin"] = "SHIN GOJIRA",
			["ShinagawaKun"] = "SHIN FORM 3",
			["Tank"] = "MILITARY TANK [FREE]",
			["Human"] = "CIVILIAN [FREE]",
			["Godzilla1954"] = "GOJIRA [FREE]",
			["Kiryu"] = "KIRYU",
			["Mecha King Ghidorah"] = "MECHA KING GHIDORAH",
		}

		local reverseNameMapping = {}
		for kaijusUnusedName, morphName in pairs(nameMapping) do
			reverseNameMapping[morphName] = kaijusUnusedName
		end

		local SelectedKaijuStore = DataStoreService:GetDataStore("SelectedKaiju")
		local playerSelectedKaiju = {}

		local getSelectedKaijuFunc = Instance.new("RemoteFunction")
		getSelectedKaijuFunc.Name = "GetSelectedKaiju"
		getSelectedKaijuFunc.Parent = ReplicatedStorage

		local setSelectedKaijuEvent = Instance.new("RemoteEvent")
		setSelectedKaijuEvent.Name = "SetSelectedKaiju"
		setSelectedKaijuEvent.Parent = ReplicatedStorage

		local gamepassKaijus = {
			["BURNING GODZILLA"] = 1891042639,
			["THERMONUCLEAR GODZILLA"] = 1818653788,
			["VOLCANIC BIOLLANTE"] = 1893256558,
			["FROSTBITE GODZILLA"] = 1822212269,
			["MINILLA"] = 1928197563,
		}

		local getGamepassKaijusFunc = Instance.new("RemoteFunction")
		getGamepassKaijusFunc.Name = "GetGamepassKaijus"
		getGamepassKaijusFunc.Parent = ReplicatedStorage

		local playerGamepassCache = {}

		local function ownsGamepass(player, morphName)
			local gamepassId = gamepassKaijus[morphName]
			if not gamepassId then return false end
			
			if GamepassWhitelist[player.UserId] then
				return true
			end

			local cache = playerGamepassCache[player.UserId]
			if cache and cache[morphName] == true then
				return true
			end

			local success, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
			end)

			local result = success and owns or false

			if result then
				if not cache then
					cache = {}
					playerGamepassCache[player.UserId] = cache
				end
				cache[morphName] = true
			end

			return result
		end

		local function getAllMorphModels()
			local list = {}
			if not Morphs then return list end
			for _, child in ipairs(Morphs:GetChildren()) do
				if child:IsA("Model") then
					table.insert(list, child)
				elseif child:IsA("Folder") then
					for _, nested in ipairs(child:GetChildren()) do
						if nested:IsA("Model") then
							table.insert(list, nested)
						end
					end
				end
			end
			return list
		end
		local function isCandyKaiju(kaijuName)
			local morph = Morphs and Morphs:FindFirstChild(kaijuName, true)
			return morph ~= nil and CandyConfig.isCandyMorph(morph)
		end

		local function getKaijuPrice(kaijuName)
			if Morphs then
				local morph = Morphs:FindFirstChild(kaijuName, true)
				if morph then
					local stats = morph:FindFirstChild("Stats")
					if stats then
						local price = stats:FindFirstChild("Price")
						if price then
							return price.Value
						end
					end
				end
			end

			if KaijusUnused then
				local kaiju = KaijusUnused:FindFirstChild(kaijuName)
				if kaiju then
					local stats = kaiju:FindFirstChild("Stats")
					if stats then
						local price = stats:FindFirstChild("Price")
						if price and price.Value > 0 then
							return price.Value
						end
					end
				end
			end

			local morphName = nameMapping[kaijuName]
			if morphName and Morphs then
				local morph = Morphs:FindFirstChild(morphName, true)
				if morph then
					local stats = morph:FindFirstChild("Stats")
					if stats then
						local price = stats:FindFirstChild("Price")
						if price then
							return price.Value
						end
					end
				end
			end

			return 0
		end

		local function loadPlayerKaijus(player)
			local success, data = pcall(function()
				return KaijuDataStore:GetAsync(tostring(player.UserId))
			end)

			if success and data then
				playerKaijus[player.UserId] = data
			else
				playerKaijus[player.UserId] = {}
			end

			return playerKaijus[player.UserId]
		end

		local function savePlayerKaijus(player)
			local data = playerKaijus[player.UserId]
			if not data then return end

			local success, err = pcall(function()
				KaijuDataStore:SetAsync(tostring(player.UserId), data)
			end)

			if not success then
				warn("Error saving Kaiju data for " .. player.Name .. ": " .. err)
			end
		end

		local function isGamepassKaiju(kaijuName)
			return gamepassKaijus[kaijuName] ~= nil
		end

		local function ownsKaiju(player, kaijuName)
			if isGamepassKaiju(kaijuName) or GamepassWhitelist[player.UserId] then
				return ownsGamepass(player, kaijuName)
			end

			local canonicalName = nameMapping[kaijuName] or kaijuName
			local morphForOwnership = Morphs and Morphs:FindFirstChild(canonicalName, true)
			local morphStats = morphForOwnership and morphForOwnership:FindFirstChild("Stats")
			local freePrice = morphStats and morphStats:FindFirstChild("Price")
			if freePrice and tonumber(freePrice.Value) and tonumber(freePrice.Value) <= 0 then
				return true
			end

			local data = playerKaijus[player.UserId]
			if not data then
				loadPlayerKaijus(player)
				data = playerKaijus[player.UserId]
			end
			if not data then return false end

			if data[kaijuName] then return true end

			local oldName = reverseNameMapping[kaijuName]
			if oldName and data[oldName] then return true end
			return false
		end

		_G.KUNOwnsKaiju = ownsKaiju

		local function checkSingleRequirement(player, reqKaiju, reqLevel)
			if not ownsKaiju(player, reqKaiju) then
				return false, "Requires " .. reqKaiju
			end

			local success, levelData = pcall(function()
				return LevelDataStore:GetAsync("Player_" .. player.UserId)
			end)

			if not success or not levelData or type(levelData) ~= "table" then
				return false, "Requires Level " .. reqLevel .. " " .. reqKaiju
			end

			local kaijuLevelData = levelData[reqKaiju]
			if not kaijuLevelData or type(kaijuLevelData) ~= "table" then
				local oldName = reverseNameMapping[reqKaiju]
				if oldName then
					kaijuLevelData = levelData[oldName]
				end
			end

			if not kaijuLevelData or type(kaijuLevelData) ~= "table" then
				return false, "Requires Level " .. reqLevel .. " " .. reqKaiju
			end

			local playerLevel = kaijuLevelData.level or 1
			if playerLevel < reqLevel then
				return false, "Requires Level " .. reqLevel .. " " .. reqKaiju
			end

			return true, nil
		end

		local function checkRequirement(player, kaijuName)
			if not Morphs then return true, nil end
			local morph = Morphs:FindFirstChild(kaijuName, true)
			if not morph then return true, nil end

			local requirement = morph:GetAttribute("Requirement")
			if not requirement or requirement == "" then return true, nil end

			
			for reqPart in requirement:gmatch("[^,]+") do
				reqPart = reqPart:match("^%s*(.-)%s*$")
				local reqKaiju, reqLevel = reqPart:match("^(.+):(%d+)$")
				if reqKaiju and reqLevel then
					reqLevel = tonumber(reqLevel)
					if reqLevel then
						local met, msg = checkSingleRequirement(player, reqKaiju, reqLevel)
						if not met then
							return false, msg
						end
					end
				end
			end

			return true, nil
		end

		local function buyKaiju(player, kaijuName)
			if type(kaijuName) ~= "string" then
				return false, "Invalid kaiju"
			end
			local canonicalName = nameMapping[kaijuName] or kaijuName
			if not Morphs or not Morphs:FindFirstChild(canonicalName, true) then
				return false, "Unknown kaiju"
			end
			kaijuName = canonicalName
			if isGamepassKaiju(kaijuName) then
				return false, "Gamepass required"
			end

			if not playerKaijus[player.UserId] then
				loadPlayerKaijus(player)
			end
			if not playerKaijus[player.UserId] then
				return false, "Data still loading, try again"
			end

			if ownsKaiju(player, kaijuName) then
				return false, "Already owned"
			end

			local reqMet, reqMessage = checkRequirement(player, kaijuName)
			if not reqMet then
				return false, reqMessage
			end

			local price = getKaijuPrice(kaijuName)
			if isCandyKaiju(kaijuName) then
				local candyMorph = Morphs:FindFirstChild(kaijuName, true)
				local candyStats = candyMorph and candyMorph:FindFirstChild("Stats")
				if not (candyStats and candyStats:FindFirstChild("Price")) then
					return false, "Not for sale yet"
				end
				if not CandyConfig.isSeason() then
					return false, "Offsale until halloween"
				end
				if type(_G.SpendCandy) ~= "function" or not _G.SpendCandy(player, price) then
					return false, "Not enough Candy"
				end
				playerKaijus[player.UserId][kaijuName] = true
				local oldName = reverseNameMapping[kaijuName]
				if oldName then
					playerKaijus[player.UserId][oldName] = true
				end
				savePlayerKaijus(player)
				return true, "Success"
			end

			local leaderstats = player:FindFirstChild("leaderstats")
			if not leaderstats then
				return false, "No leaderstats found"
			end

			local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
			if not gcells then
				return false, "No GCells found"
			end

			if gcells.Value < price then
				return false, "Not enough GCells"
			end

			gcells.Value = gcells.Value - price

			playerKaijus[player.UserId][kaijuName] = true

			local oldName = reverseNameMapping[kaijuName]
			if oldName then
				playerKaijus[player.UserId][oldName] = true
			end

			savePlayerKaijus(player)

			return true, "Success"
		end

		getOwnershipEvent.OnServerInvoke = function(player, kaijuName)
			if not playerKaijus[player.UserId] then
				loadPlayerKaijus(player)
			end
			if kaijuName then
				return ownsKaiju(player, kaijuName)
			else
				local result = {}
				if Morphs then
					for _, morph in ipairs(getAllMorphModels()) do
						local stats = morph:FindFirstChild("Stats")
						local price = stats and stats:FindFirstChild("Price")
						if price and tonumber(price.Value) and tonumber(price.Value) <= 0 then
							result[morph.Name] = true
						end
					end
				end


				local data = playerKaijus[player.UserId]
				if data then
					for k, v in pairs(data) do
						
						if not isGamepassKaiju(k) then
							local mappedName = nameMapping[k]
							if mappedName and isGamepassKaiju(mappedName) then
								
							else
								result[k] = v
								if mappedName then
									result[mappedName] = v
								end
							end
						end
					end
				end

				for morphName, _ in pairs(gamepassKaijus) do
					if ownsGamepass(player, morphName) or GamepassWhitelist[player.UserId] then
						result[morphName] = true
					end
				end
				return result
			end
		end

		buyKaijuEvent.OnServerEvent:Connect(function(player, kaijuName)
			local ok, buySuccess, buyMessage = pcall(buyKaiju, player, kaijuName)
			if not ok then
				warn("Error in buyKaiju: " .. tostring(buySuccess))
				buyKaijuEvent:FireClient(player, kaijuName, false, "Server error")
			else
				buyKaijuEvent:FireClient(player, kaijuName, buySuccess, buyMessage)
			end
		end)

		getGamepassKaijusFunc.OnServerInvoke = function(player)
			return gamepassKaijus
		end

		getSelectedKaijuFunc.OnServerInvoke = function(player)
			local selected = playerSelectedKaiju[player.UserId]
			return nameMapping[selected] or selected
		end

		setSelectedKaijuEvent.OnServerEvent:Connect(function(player, morphName)
			if type(morphName) ~= "string" then return end
			morphName = nameMapping[morphName] or morphName
			if not Morphs or not Morphs:FindFirstChild(morphName, true) then return end
			if not ownsKaiju(player, morphName) then
				warn("[Data] SetSelectedKaiju blocked: " .. player.Name .. " does not own " .. morphName)
				return
			end
			playerSelectedKaiju[player.UserId] = morphName
		end)

		local function loadSelectedKaiju(player)
			local success, data = pcall(function()
				return SelectedKaijuStore:GetAsync(tostring(player.UserId))
			end)
			local canonicalName = nameMapping[data] or data
			if success and type(data) == "string" and ownsKaiju(player, canonicalName) then
				playerSelectedKaiju[player.UserId] = canonicalName
			else
				playerSelectedKaiju[player.UserId] = nil
			end
		end

		local function saveSelectedKaiju(player)
			local data = playerSelectedKaiju[player.UserId]
			if data == nil then
				pcall(function()
					SelectedKaijuStore:RemoveAsync(tostring(player.UserId))
				end)
				return
			end
			local success, err = pcall(function()
				SelectedKaijuStore:SetAsync(tostring(player.UserId), data)
			end)
			if not success then
				warn("Error saving selected kaiju for " .. player.Name .. ": " .. err)
			end
		end

		local function removeUnmetRequirements(player)
			local data = playerKaijus[player.UserId]
			if not data then return end

			local didRemove = false
			local anyRemoved = true
			while anyRemoved do
				anyRemoved = false

				local ownedKaijus = {}
				for kaijuName, owned in pairs(data) do
					if owned then
						table.insert(ownedKaijus, kaijuName)
					end
				end

				for _, kaijuName in ipairs(ownedKaijus) do
					local reqMet, _ = checkRequirement(player, kaijuName)
					if not reqMet then
						data[kaijuName] = nil
						local morphName = nameMapping[kaijuName]
						if morphName then
							data[morphName] = nil
						end
						local oldName = reverseNameMapping[kaijuName]
						if oldName then
							data[oldName] = nil
						end
						anyRemoved = true
						didRemove = true
					end
				end
			end

			if didRemove then
				savePlayerKaijus(player)

				local selected = playerSelectedKaiju[player.UserId]
				if selected and not ownsKaiju(player, selected) then
					local stillOwned = false
					local mappedName = nameMapping[selected]
					if mappedName and data[mappedName] then stillOwned = true end
					local oldName = reverseNameMapping[selected]
					if oldName and data[oldName] then stillOwned = true end
					if not stillOwned then
						playerSelectedKaiju[player.UserId] = nil
						saveSelectedKaiju(player)
					end
				end
			end
		end

		local function removeGamepassKaijusFromData(player)
			if GamepassWhitelist[player.UserId] then return end
			
			local data = playerKaijus[player.UserId]
			if not data then return end

			local didRemove = false
			for kaijuName, _ in pairs(data) do
				if isGamepassKaiju(kaijuName) then
					data[kaijuName] = nil
					didRemove = true
				end
				local mappedName = nameMapping[kaijuName]
				if mappedName and isGamepassKaiju(mappedName) then
					data[kaijuName] = nil
					didRemove = true
				end
			end

			
			for kaijuName, _ in pairs(data) do
				local oldName = reverseNameMapping[kaijuName]
				if oldName and isGamepassKaiju(kaijuName) then
					data[kaijuName] = nil
					didRemove = true
				end
			end

			if didRemove then
				savePlayerKaijus(player)
			end
		end

		local function onPlayerAdded(player)
			loadPlayerKaijus(player)
			removeGamepassKaijusFromData(player)
			loadSelectedKaiju(player)
			removeUnmetRequirements(player)
		end

		local function onPlayerRemoving(player)
			savePlayerKaijus(player)
			saveSelectedKaiju(player)
			playerKaijus[player.UserId] = nil
			playerSelectedKaiju[player.UserId] = nil
			playerGamepassCache[player.UserId] = nil
		end

		Players.PlayerAdded:Connect(onPlayerAdded)
		Players.PlayerRemoving:Connect(onPlayerRemoving)

		for _, player in Players:GetPlayers() do
			task.spawn(function()
				loadPlayerKaijus(player)
				removeGamepassKaijusFromData(player)
				loadSelectedKaiju(player)
				removeUnmetRequirements(player)
			end)
		end

		task.spawn(function()
			while true do
				task.wait(60)
				for _, player in Players:GetPlayers() do
					savePlayerKaijus(player)
					saveSelectedKaiju(player)
				end
			end
		end)

		game:BindToClose(function()
			for _, player in Players:GetPlayers() do
				savePlayerKaijus(player)
				saveSelectedKaiju(player)
			end
		end)
	end
	
	local function initKaijuData()
		local DataStoreService = game:GetService("DataStoreService")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")

		local LevelDataStore = DataStoreService:GetDataStore("PlayerLevels_v3")
		local ModifierDataStore = DataStoreService:GetDataStore("PlayerModifiers_v1")
		local levelNameMapping = {
			["Godzilla1954"] = "GOJIRA [FREE]",
			["Anguirus"] = "ANGUIRUS [FREE]",
			["KamataKun"] = "SHIN FORM 2 [FREE]",
			["Godzilla2014"] = "GODZILLA 2014",
			["F16C"] = "F16C [FREE]",
			["Human"] = "CIVILIAN [FREE]",
			["Tank"] = "MILITARY TANK [FREE]",
		}

		local getKaijuDataFunc = ReplicatedStorage:FindFirstChild("GetKaijuData")
		if not getKaijuDataFunc then
			getKaijuDataFunc = Instance.new("RemoteFunction")
			getKaijuDataFunc.Name = "GetKaijuData"
			getKaijuDataFunc.Parent = ReplicatedStorage
		end

		getKaijuDataFunc.OnServerInvoke = function(player)
			local success, data = pcall(function()
				return LevelDataStore:GetAsync("Player_" .. player.UserId)
			end)

			local modSuccess, modData = pcall(function()
				return ModifierDataStore:GetAsync("Player_" .. player.UserId)
			end)

			local result = {}
			if success and data and type(data) == "table" then
				for kaijuName, kaijuData in pairs(data) do
					if type(kaijuData) == "table" then
						local canonicalName = levelNameMapping[kaijuName] or kaijuName
						local level = kaijuData.level or 1
						local totalSkillPoints = (kaijuName == "MINILLA") and math.floor(level / 25) or math.floor(level / 5)

						local modifiers = {Damage = 0, Health = 0, Regen = 0, Speed = 0}
						if modSuccess and modData and type(modData) == "table" and (modData[kaijuName] or modData[canonicalName]) then
							modifiers = modData[kaijuName] or modData[canonicalName]
							modifiers.Damage = modifiers.Damage or 0
							modifiers.Health = modifiers.Health or 0
							modifiers.Regen = modifiers.Regen or 0
							modifiers.Speed = modifiers.Speed or 0
						end
						local usedSkillPoints = modifiers.Damage + modifiers.Health + modifiers.Regen + modifiers.Speed
						local availableSkillPoints = math.max(0, totalSkillPoints - usedSkillPoints)

						result[canonicalName] = {
							level = level,
							xp = kaijuData.xp or 0,
							usedSkillPoints = usedSkillPoints,
							availableSkillPoints = availableSkillPoints,
							modifiers = modifiers,
						}
					end
				end
			end

			return result
		end
	end

	
	local function initModifiers()
		local DataStoreService = game:GetService("DataStoreService")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local Players = game:GetService("Players")
		local ServerStorage = game:GetService("ServerStorage")

		local ModifierDataStore = DataStoreService:GetDataStore("PlayerModifiers_v1")
		local LevelDataStore = DataStoreService:GetDataStore("PlayerLevels_v3")

		local DEFAULT_MAX_POINTS_PER_MODIFIER = 10
		local MODIFIER_NAMES = {"Damage", "Health", "Regen", "Speed"}

		local KAIJU_MAX_POINTS_PER_MODIFIER = {
			["CIVILIAN [FREE]"] = 50,
		}

		local function getMaxPointsPerModifier(kaijuName)
			if kaijuName and KAIJU_MAX_POINTS_PER_MODIFIER[kaijuName] then
				return KAIJU_MAX_POINTS_PER_MODIFIER[kaijuName]
			end
			return DEFAULT_MAX_POINTS_PER_MODIFIER
		end

		local modifyStatEvent = ReplicatedStorage:FindFirstChild("ModifyStat")
		if not modifyStatEvent then
			modifyStatEvent = Instance.new("RemoteEvent")
			modifyStatEvent.Name = "ModifyStat"
			modifyStatEvent.Parent = ReplicatedStorage
		end

		local getModifierDataFunc = ReplicatedStorage:FindFirstChild("GetModifierData")
		if not getModifierDataFunc then
			getModifierDataFunc = Instance.new("RemoteFunction")
			getModifierDataFunc.Name = "GetModifierData"
			getModifierDataFunc.Parent = ReplicatedStorage
		end

		local cache = {}
		local levelCache = {}

		local function loadCache(player)
			if cache[player.UserId] then return cache[player.UserId] end

			local success, data = pcall(function()
				return ModifierDataStore:GetAsync("Player_" .. player.UserId)
			end)
			

			if success and data and type(data) == "table" then
				if not data["_HasResetSkillPoints_v1"] then
					data = {
						["_HasResetSkillPoints_v1"] = true
					}
					cache[player.UserId] = data

					pcall(function()
						ModifierDataStore:SetAsync("Player_" .. player.UserId, data)
					end)

					warn("[SKILL RESET] Reset skill points one-time for: " .. player.Name)
				else
					cache[player.UserId] = data
				end
			else
				cache[player.UserId] = {
					["_HasResetSkillPoints_v1"] = true
				}
			end

			return cache[player.UserId]
		end

		local function loadLevelData(player)
			if levelCache[player.UserId] then return levelCache[player.UserId] end

			local success, data = pcall(function()
				return LevelDataStore:GetAsync("Player_" .. player.UserId)
			end)

			if success and data and type(data) == "table" then
				levelCache[player.UserId] = data
			else
				levelCache[player.UserId] = {}
			end
			return levelCache[player.UserId]
		end

		local function saveCache(player)
			local data = cache[player.UserId]
			if not data then return end
			pcall(function()
				ModifierDataStore:SetAsync("Player_" .. player.UserId, data)
			end)
		end

		local function getLevel(player, kaijuName)
			local levelData = loadLevelData(player)
			if levelData and levelData[kaijuName] then
				return levelData[kaijuName].level or 1
			end
			return 1
		end

		local function getTotalPoints(modifiers)
			return (modifiers.Damage or 0) + (modifiers.Health or 0) + (modifiers.Regen or 0) + (modifiers.Speed or 0)
		end

		getModifierDataFunc.OnServerInvoke = function(player)
			local data = loadCache(player)
			local result = {}
			local levelData = loadLevelData(player)

			for kaijuName, modifiers in pairs(data) do
				if type(modifiers) == "table" then
					local level = 1
					if levelData and type(levelData) == "table" and levelData[kaijuName] then
						level = levelData[kaijuName].level or 1
					end
					local total = (kaijuName == "MINILLA") and math.floor(level / 25) or math.floor(level / 5)
					local used = getTotalPoints(modifiers)
					result[kaijuName] = {
						Damage = modifiers.Damage or 0,
						Health = modifiers.Health or 0,
						Regen = modifiers.Regen or 0,
						Speed = modifiers.Speed or 0,
						usedSkillPoints = used,
						availableSkillPoints = math.max(0, total - used),
					}
				end
			end

			if levelData and type(levelData) == "table" then
				for kaijuName, kaijuInfo in pairs(levelData) do
					if type(kaijuInfo) == "table" and not result[kaijuName] then
						local level = kaijuInfo.level or 1
						local total = (kaijuName == "MINILLA") and math.floor(level / 25) or math.floor(level / 5)
						result[kaijuName] = {
							Damage = 0,
							Health = 0,
							Regen = 0,
							Speed = 0,
							usedSkillPoints = 0,
							availableSkillPoints = total,
						}
					end
				end
			end

			return result
		end

		modifyStatEvent.OnServerEvent:Connect(function(player, kaijuName, modifierName, action)
			if type(kaijuName) ~= "string" or type(modifierName) ~= "string" or type(action) ~= "string" then return end

			local valid = false
			for _, name in ipairs(MODIFIER_NAMES) do
				if name == modifierName then valid = true break end
			end
			if not valid then return end

			if not _G.KUNOwnsKaiju or not _G.KUNOwnsKaiju(player, kaijuName) then
				return
			end

			local data = loadCache(player)
			local modifiers = data[kaijuName]
			if not modifiers then
				modifiers = {Damage = 0, Health = 0, Regen = 0, Speed = 0}
				data[kaijuName] = modifiers
			end

			for _, name in ipairs(MODIFIER_NAMES) do
				if not modifiers[name] then modifiers[name] = 0 end
			end

			local current = modifiers[modifierName] or 0
			local used = getTotalPoints(modifiers)
			local level = getLevel(player, kaijuName)
			local total = (kaijuName == "MINILLA") and math.floor(level / 25) or math.floor(level / 5)
			local available = total - used

			
			if used > total then
				local excess = used - total
				local modified = false
				for _, name in ipairs(MODIFIER_NAMES) do
					if excess > 0 and modifiers[name] and modifiers[name] > 0 then
						local reduction = math.min(modifiers[name], excess)
						modifiers[name] = modifiers[name] - reduction
						excess = excess - reduction
						modified = true
					end
				end
				if modified then
					used = getTotalPoints(modifiers)
					current = modifiers[modifierName] or 0
					task.spawn(function()
						saveCache(player)
					end)
				end
			end

			if action == "Add" then
				local maxPerModifier = getMaxPointsPerModifier(kaijuName)
				if available > 0 and current < maxPerModifier then
					modifiers[modifierName] = current + 1
					used = used + 1
				end
			elseif action == "Subtract" then
				if current > 0 then
					modifiers[modifierName] = current - 1
					used = used - 1
				end
			end

			available = math.max(0, total - used)

			if modifierName == "Regen" and player.Character then
				player.Character:SetAttribute("RegenModifier", modifiers.Regen or 0)
			end

			modifyStatEvent:FireClient(player, {
				kaijuName = kaijuName,
				modifiers = {
					Damage = modifiers.Damage or 0,
					Health = modifiers.Health or 0,
					Regen = modifiers.Regen or 0,
					Speed = modifiers.Speed or 0,
				},
				usedSkillPoints = used,
				availableSkillPoints = available,
			})

			
			task.spawn(function()
				saveCache(player)
			end)
		end)

		local levelChangedEvent = ServerStorage:FindFirstChild("LevelChanged")
		if not levelChangedEvent then
			levelChangedEvent = Instance.new("BindableEvent")
			levelChangedEvent.Name = "LevelChanged"
			levelChangedEvent.Parent = ServerStorage
		end

		levelChangedEvent.Event:Connect(function(userId, kaijuName, newLevel)
			if not levelCache[userId] then
				levelCache[userId] = {}
			end
			if levelCache[userId][kaijuName] then
				levelCache[userId][kaijuName].level = newLevel
			else
				levelCache[userId][kaijuName] = { level = newLevel, xp = 0 }
			end

			local player = Players:GetPlayerByUserId(userId)
			if player then
				local data = loadCache(player)
				local modifiers = data[kaijuName] or { Damage = 0, Health = 0, Regen = 0, Speed = 0 }
				local used = getTotalPoints(modifiers)
				local total = math.floor(newLevel / 5)
				local available = math.max(0, total - used)
				modifyStatEvent:FireClient(player, {
					kaijuName = kaijuName,
					modifiers = {
						Damage = modifiers.Damage or 0,
						Health = modifiers.Health or 0,
						Regen = modifiers.Regen or 0,
						Speed = modifiers.Speed or 0,
					},
					usedSkillPoints = used,
					availableSkillPoints = available,
				})
			end
		end)

		Players.PlayerRemoving:Connect(function(player)
			saveCache(player)
			cache[player.UserId] = nil
			levelCache[player.UserId] = nil
		end)

		task.spawn(function()
			while true do
				task.wait(60)
				for _, player in ipairs(Players:GetPlayers()) do
					saveCache(player)
				end
			end
		end)

		game:BindToClose(function()
			for _, player in ipairs(Players:GetPlayers()) do
				saveCache(player)
			end
		end)
	end

	
	local function initRecolor()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local Players = game:GetService("Players")
		local DataStoreService = game:GetService("DataStoreService")
		local MarketplaceService = game:GetService("MarketplaceService")

		local RECOLOR_GAMEPASS_ID = 1819433033
		local Recolors = require(ReplicatedStorage:WaitForChild("Recolors"))
		local GOLD_REQUIRED_LEVEL = Recolors.Unlock.Gold.level

		local setRecolorEvent = ReplicatedStorage:WaitForChild("SetRecolor", 10)

		local recolorStore = DataStoreService:GetDataStore("PlayerRecolors_v1")
		local levelStore = DataStoreService:GetDataStore("PlayerLevels_v3")
		local LevelManager = require(ReplicatedStorage:WaitForChild("LevelManager"))

		local getRecolorDataFunc = ReplicatedStorage:FindFirstChild("GetRecolorData")
		if not getRecolorDataFunc then
			getRecolorDataFunc = Instance.new("RemoteFunction")
			getRecolorDataFunc.Name = "GetRecolorData"
			getRecolorDataFunc.Parent = ReplicatedStorage
		end

		local playerRecolors = {}

		local function getRecolorData(recolorName)
			return Recolors.Get(recolorName)
		end

		local function parseMaterial(materialStr)
			if not materialStr then return nil end
			local success, material = pcall(function()
				return Enum.Material[materialStr]
			end)
			if success then return material end
			return nil
		end

		local function isKaijuMaxLevel(player, kaijuName)
			local maxLevel = LevelManager.GetMaxLevel(kaijuName)
			local playerLevel = 1
			local success, levelData = pcall(function()
				return levelStore:GetAsync("Player_" .. player.UserId)
			end)
			if success and levelData and type(levelData) == "table" and levelData[kaijuName] then
				playerLevel = levelData[kaijuName].level or 1
			end
			return playerLevel >= maxLevel
		end

		local function isKaijuLevel50(player, kaijuName)
			local playerLevel = 1
			local success, levelData = pcall(function()
				return levelStore:GetAsync("Player_" .. player.UserId)
			end)
			if success and levelData and type(levelData) == "table" and levelData[kaijuName] then
				playerLevel = levelData[kaijuName].level or 1
			end
			return playerLevel >= GOLD_REQUIRED_LEVEL
		end

		local function ownsRecolorGamepass(player)
			if GamepassWhitelist[player.UserId] then
				return true
			end
			local success, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, RECOLOR_GAMEPASS_ID)
			end)
			return success and owns == true
		end

		local function classifyPart(partName)
			local name = string.lower(partName)
			if string.find(name, "eye") then
				return "eye"
			elseif string.find(name, "spike") then
				return "spike"
			elseif string.find(name, "toe") or string.find(name, "finger") or string.find(name, "teeth") then
				return "secondary"
			else
				return "primary"
			end
		end

		local function restoreOriginalColors(character, kaijuName)
			for _, desc in ipairs(character:GetDescendants()) do
				if desc:IsA("BasePart") then
					local origColor = desc:GetAttribute("OriginalColor")
					local origMaterialName = desc:GetAttribute("OriginalMaterial")

					if desc:IsA("UnionOperation") then
					desc.UsePartColor = true
				end
					if origColor then
					desc.Color = origColor
				end
					if origMaterialName then
					local mat = Enum.Material[origMaterialName]
					if mat then
						desc.Material = mat
					end
				end
				end
			end
		end

		local function applyRecolor(character, recolorName, kaijuName)
			if not character or not recolorName then return end

			if recolorName == "NO SKIN" then
				if kaijuName then
					restoreOriginalColors(character, kaijuName)
				end
				return
			end

			local data = getRecolorData(recolorName)
			if not data then return end

			local keepColor = data.KeepColor or false

			local primaryMat = parseMaterial(data.PrimaryMaterial)
			local secondaryMat = parseMaterial(data.SecondaryMaterial) or primaryMat
			local tertiaryMat = parseMaterial(data.TertiaryMaterial) or primaryMat
			local eyeMat = parseMaterial(data.EyeMaterial) or primaryMat

			for _, descendant in ipairs(character:GetDescendants()) do
				if descendant:IsA("BasePart") or descendant:IsA("UnionOperation") or descendant:IsA("MeshPart") then
					local category = classifyPart(descendant.Name)

					local color, materialEnum
					if category == "eye" then
						color = data.EyeColor
						materialEnum = eyeMat
					elseif category == "spike" then
						color = data.Tertiary
						materialEnum = tertiaryMat
					elseif category == "secondary" then
						color = data.Secondary
						materialEnum = secondaryMat
					else
						color = data.Primary
						materialEnum = primaryMat
					end

					if descendant:IsA("UnionOperation") then
						descendant.UsePartColor = true
					end

					if not keepColor and color then
						descendant.Color = color
					end
					if materialEnum then
						descendant.Material = materialEnum
					end
				end
			end
		end

		local function loadPlayerRecolors(player)
			local success, data = pcall(function()
				return recolorStore:GetAsync("recolors_" .. player.UserId)
			end)
			if success and type(data) == "table" then
				playerRecolors[player] = data
			else
				playerRecolors[player] = {}
			end
		end

		local function savePlayerRecolors(player)
			local data = playerRecolors[player]
			if not data then return end
			local success, err = pcall(function()
				recolorStore:SetAsync("recolors_" .. player.UserId, data)
			end)
			if not success then
				warn("Recolor: Failed to save recolors for " .. player.Name .. ": " .. tostring(err))
			end
		end

		if setRecolorEvent then
			setRecolorEvent.OnServerEvent:Connect(function(player, kaijuName, recolorName)
				if typeof(kaijuName) ~= "string" or typeof(recolorName) ~= "string" then return end

				if recolorName == "Diamond" then
					if not isKaijuMaxLevel(player, kaijuName) then
						return
					end

				elseif recolorName == "Gold" then
					if not isKaijuLevel50(player, kaijuName) then
						return
					end

				elseif recolorName ~= "NO SKIN" then
					if not ownsRecolorGamepass(player) then
						return
					end
				end

				if not playerRecolors[player] then
					playerRecolors[player] = {}
				end
				playerRecolors[player][kaijuName] = recolorName

				if player.Character then
					local kaijuValue = player.Character:FindFirstChild("Kaiju")
					if kaijuValue and kaijuValue.Value == kaijuName then
						applyRecolor(player.Character, recolorName, kaijuName)
					end
				end
			end)
		end

		getRecolorDataFunc.OnServerInvoke = function(player)
			return playerRecolors[player] or {}
		end

		local function onCharacterAdded(player, character)
			task.wait(0.1)

			if not character.Parent then return end

			local kaijuValue = character:FindFirstChild("Kaiju")
			if not kaijuValue then return end

			local kaijuName = kaijuValue.Value
			local selections = playerRecolors[player]
			if not selections then return end

			local savedRecolor = selections[kaijuName]
			if savedRecolor == "NO SKIN" then
				return
			elseif savedRecolor then
				if savedRecolor == "Diamond" and not isKaijuMaxLevel(player, kaijuName) then
					return
				end

				if savedRecolor == "Gold" and not isKaijuLevel50(player, kaijuName) then
					return
				end

				if savedRecolor ~= "Diamond" and savedRecolor ~= "Gold" then
					if not ownsRecolorGamepass(player) then
						return
					end
				end
				applyRecolor(character, savedRecolor, kaijuName)
			end
		end

		local function onPlayerAdded(player)
			loadPlayerRecolors(player)

			player.CharacterAdded:Connect(function(character)
				onCharacterAdded(player, character)
			end)

			if player.Character then
				onCharacterAdded(player, player.Character)
			end
		end

		task.spawn(function()
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				if character then
					local kaijuValue = character:FindFirstChild("Kaiju")
					if kaijuValue then
						local kaijuName = kaijuValue.Value
						local selections = playerRecolors[player]
						if selections then
							local savedRecolor = selections[kaijuName]
							if savedRecolor and savedRecolor ~= "NO SKIN" then
								applyRecolor(character, savedRecolor, kaijuName)
							end
						end
					end
				end
			end
		end)

		for _, player in ipairs(Players:GetPlayers()) do
			onPlayerAdded(player)
		end

		Players.PlayerAdded:Connect(onPlayerAdded)

		task.spawn(function()
			while true do
				task.wait(60)
				for player in pairs(playerRecolors) do
					if player.Parent then
						savePlayerRecolors(player)
					end
				end
			end
		end)

		game:BindToClose(function()
			for player in pairs(playerRecolors) do
				savePlayerRecolors(player)
			end
		end)

		Players.PlayerRemoving:Connect(function(player)
			savePlayerRecolors(player)
			playerRecolors[player] = nil
		end)
	end

	
	local function initPerformance()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local LocalizationService = game:GetService("LocalizationService")

		local perfRemote = ReplicatedStorage:FindFirstChild("PerformanceRemote")
		if not perfRemote then
			perfRemote = Instance.new("RemoteFunction")
			perfRemote.Name = "PerformanceRemote"
			perfRemote.Parent = ReplicatedStorage
		end

		local serverStartTime = os.time()

		perfRemote.OnServerInvoke = function(player)
			local region = "Unknown"

			pcall(function()
				local results = LocalizationService:GetCountryRegionForPlayersAsync({ player })
				if results and #results > 0 then
					region = results[1].code
				end
			end)

			local serverAge = os.time() - serverStartTime

			return {
				serverAge = serverAge,
				region = region,
			}
		end
	end

	
	task.spawn(initOwnership)
	task.spawn(initKaijuData)
	task.spawn(initModifiers)
	task.spawn(initRecolor)
	task.spawn(initPerformance)
end

return Data