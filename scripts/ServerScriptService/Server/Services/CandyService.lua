local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local CandyConfig = require(ReplicatedStorage:WaitForChild("CandyConfig"))

local STORE_NAME = "Candy_v1"
local ATTRIBUTE = "Candy"
local STAT_NAME = "Candy"
local AUTOSAVE_INTERVAL = 120
local RETRIES = 3
local LOAD_RETRY_INTERVAL = 30
local LOAD_RETRY_LIMIT = 10

local CandyService = { Name = "Candy" }

local store
local ready = {}
local synced = {}
local delta = {}
local busy = {}

local function storeKey(player)
	return "Player_" .. player.UserId
end

local function balance(player)
	return math.max(math.floor(tonumber(player:GetAttribute(ATTRIBUTE)) or 0), 0)
end

local function getStat(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	local stat = leaderstats:FindFirstChild(STAT_NAME)
	if not stat then
		stat = Instance.new("IntValue")
		stat.Name = STAT_NAME
		stat.Value = balance(player)
		stat.Parent = leaderstats
	end
	return stat
end

local function setBalance(player, value)
	value = math.max(math.floor(value), 0)
	player:SetAttribute(ATTRIBUTE, value)
	getStat(player).Value = value
end

local function fetch(player)
	if not store then
		return nil
	end
	for attempt = 1, RETRIES do
		local ok, result = pcall(store.GetAsync, store, storeKey(player))
		if ok then
			return math.max(math.floor(tonumber(result) or 0), 0)
		end
		task.wait(attempt)
	end
	return nil
end

local function save(player)
	if not store or not synced[player] or busy[player] then
		return
	end
	busy[player] = true
	local amount = balance(player)
	for attempt = 1, RETRIES do
		if pcall(store.SetAsync, store, storeKey(player), amount) then
			break
		end
		task.wait(attempt)
	end
	busy[player] = nil
end

local function saveNow(player)
	while busy[player] do
		task.wait(0.1)
	end
	save(player)
end

local function load(player)
	local value = fetch(player)
	if not player.Parent then
		return
	end
	if value ~= nil then
		setBalance(player, value)
		synced[player] = true
		ready[player] = true
		return
	end
	delta[player] = 0
	synced[player] = false
	ready[player] = true
	warn("[Candy] DataStore unavailable for " .. player.Name .. ", Candy will not save until it reconnects")
	for _ = 1, LOAD_RETRY_LIMIT do
		task.wait(LOAD_RETRY_INTERVAL)
		if not player.Parent then
			return
		end
		local stored = fetch(player)
		if stored ~= nil then
			setBalance(player, stored + (delta[player] or 0))
			synced[player] = true
			save(player)
			return
		end
	end
end

local function track(player)
	getStat(player)
	task.spawn(load, player)
end

function CandyService:Init()
	local ok, result = pcall(DataStoreService.GetDataStore, DataStoreService, STORE_NAME)
	if ok then
		store = result
	end

	_G.GetCandy = function(player)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			return 0
		end
		return balance(player)
	end

	_G.AwardCandy = function(player, maxHealth, at)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			return 0
		end
		if not ready[player] or not CandyConfig.isSeason() then
			return 0
		end
		local amount = CandyConfig.candyForHealth(maxHealth)
		if amount <= 0 then
			return 0
		end
		setBalance(player, balance(player) + amount)
		if not synced[player] then
			delta[player] = (delta[player] or 0) + amount
		end
		if _G.ShowIndicator then
			_G.ShowIndicator(player, 0, 0, 0, at, amount)
		end
		return amount
	end

	_G.SpendCandy = function(player, amount)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			return false
		end
		amount = math.floor(tonumber(amount) or -1)
		if amount < 0 or not synced[player] then
			return false
		end
		if amount == 0 then
			return true
		end
		local current = balance(player)
		if current < amount then
			return false
		end
		setBalance(player, current - amount)
		task.spawn(save, player)
		return true
	end

	Players.PlayerAdded:Connect(track)
	for _, player in Players:GetPlayers() do
		track(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		saveNow(player)
		ready[player] = nil
		synced[player] = nil
		delta[player] = nil
		busy[player] = nil
	end)
end

function CandyService:Start()
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for _, player in Players:GetPlayers() do
				task.spawn(save, player)
			end
		end
	end)

	game:BindToClose(function()
		local remaining = 0
		for _, player in Players:GetPlayers() do
			remaining += 1
			task.spawn(function()
				saveNow(player)
				remaining -= 1
			end)
		end
		local deadline = os.clock() + 25
		while remaining > 0 and os.clock() < deadline do
			task.wait(0.2)
		end
	end)
end

return CandyService
