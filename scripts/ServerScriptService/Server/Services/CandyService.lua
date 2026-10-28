local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local CandyConfig = require(ReplicatedStorage:WaitForChild("CandyConfig"))

local STORE_NAME = "Candy_v1"
local ATTRIBUTE = "Candy"
local AUTOSAVE_INTERVAL = 120
local RETRIES = 3

local CandyService = { Name = "Candy" }

local store
local loaded = {}
local busy = {}

local function storeKey(player)
	return "Player_" .. player.UserId
end

local function balance(player)
	return math.max(math.floor(tonumber(player:GetAttribute(ATTRIBUTE)) or 0), 0)
end

local function load(player)
	if not store then
		return
	end
	local value
	for attempt = 1, RETRIES do
		local ok, result = pcall(store.GetAsync, store, storeKey(player))
		if ok then
			value = math.max(math.floor(tonumber(result) or 0), 0)
			break
		end
		task.wait(attempt)
	end
	if value == nil or not player.Parent then
		return
	end
	player:SetAttribute(ATTRIBUTE, value)
	loaded[player] = true
end

local function save(player)
	if not store or not loaded[player] or busy[player] then
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
		if not loaded[player] or not CandyConfig.isSeason() then
			return 0
		end
		local amount = CandyConfig.candyForHealth(maxHealth)
		if amount <= 0 then
			return 0
		end
		player:SetAttribute(ATTRIBUTE, balance(player) + amount)
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
		if amount < 0 or not loaded[player] then
			return false
		end
		if amount == 0 then
			return true
		end
		local current = balance(player)
		if current < amount then
			return false
		end
		player:SetAttribute(ATTRIBUTE, current - amount)
		task.spawn(save, player)
		return true
	end

	Players.PlayerAdded:Connect(function(player)
		task.spawn(load, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		saveNow(player)
		loaded[player] = nil
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
