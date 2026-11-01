local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local PlayerDataStore = DataStoreService:GetDataStore("PlayerData")

local playerData = {}

local function savePlayerData(player)
	local data = playerData[player.UserId]
	if not data then return end

	local success, err = pcall(function()
		PlayerDataStore:SetAsync(tostring(player.UserId), {
			Coins = data.Coins.Value,
			Kills = data.Kills.Value,
		})
	end)

	if success then
		print("Saved data for " .. player.Name .. ": " .. data.Coins.Value .. " GCells, " .. data.Kills.Value .. " Kills")
	else
		warn("Error saving data for " .. player.Name .. ": " .. err)
	end
end

local function loadPlayerData(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local function getStat(name, defaultValue)
		local value = leaderstats:FindFirstChild(name)
		if not value then
			value = Instance.new("IntValue")
			value.Name = name
			value.Value = defaultValue
			value.Parent = leaderstats
		end
		return value
	end

	local coins = getStat("GCells", 0)
	local kills = getStat("Kills", 0)
	local level = getStat("Level", 1)

	local success, data = pcall(function()
		return PlayerDataStore:GetAsync(tostring(player.UserId))
	end)

	if success and data then
		if data.Coins then
			coins.Value = data.Coins
		end
		if data.Kills then
			kills.Value = data.Kills
		end
		print("Loaded " .. coins.Value .. " GCells and " .. kills.Value .. " Kills for " .. player.Name)
	end

	playerData[player.UserId] = { Coins = coins, Kills = kills, Level = level }

	return coins, kills
end

local boundLevelValues = {}

local function bindCharacterLevel(player, character)
	local characterLevel = character and (character:FindFirstChild("Level") or character:WaitForChild("Level", 10))
	local leaderstats = player:FindFirstChild("leaderstats")
	local levelStat = leaderstats and leaderstats:FindFirstChild("Level")
	if not characterLevel or not levelStat or not characterLevel:IsA("IntValue") then return end

	local function sync(value)
		if levelStat.Parent then levelStat.Value = value end
	end
	sync(characterLevel.Value)
	if not boundLevelValues[characterLevel] then
		boundLevelValues[characterLevel] = true
		characterLevel.Changed:Connect(sync)
	end
end

local function hookPlayerLevel(player)
	if player:GetAttribute("LeaderboardLevelHooked") then return end
	player:SetAttribute("LeaderboardLevelHooked", true)
	player.CharacterAdded:Connect(function(character)
		task.spawn(bindCharacterLevel, player, character)
	end)
	if player.Character then
		task.spawn(bindCharacterLevel, player, player.Character)
	end
end

local function onPlayerAdded(player)
	loadPlayerData(player)
	hookPlayerLevel(player)
end

local function onPlayerRemoving(player)
	savePlayerData(player)
	playerData[player.UserId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	task.spawn(function()
		loadPlayerData(player)
	end)
end

task.spawn(function()
	while true do
		task.wait(60)
		for _, player in Players:GetPlayers() do
			savePlayerData(player)
		end
	end
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		savePlayerData(player)
	end
end)
