local PlayerHooks = {}

local playerHandlers = {}
local characterHandlers = {}
local removingHandlers = {}
local tracked = setmetatable({}, { __mode = "k" })
local connected = false

local function run(handler, ...)
	task.spawn(function(...)
		local ok, err = pcall(handler, ...)
		if not ok then
			warn("[PlayerHooks] handler error: " .. tostring(err))
		end
	end, ...)
end

local function trackPlayer(player)
	if tracked[player] then
		return
	end
	tracked[player] = true
	player.CharacterAdded:Connect(function(character)
		for _, handler in ipairs(characterHandlers) do
			run(handler, player, character)
		end
	end)
end

local function connect()
	if connected then
		return
	end
	connected = true
	local Players = game:GetService("Players")
	Players.PlayerAdded:Connect(function(player)
		trackPlayer(player)
		for _, handler in ipairs(playerHandlers) do
			run(handler, player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		for _, handler in ipairs(removingHandlers) do
			run(handler, player)
		end
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		trackPlayer(player)
	end
end

function PlayerHooks.OnPlayer(handler)
	connect()
	table.insert(playerHandlers, handler)
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		run(handler, player)
	end
end

function PlayerHooks.OnCharacter(handler)
	connect()
	table.insert(characterHandlers, handler)
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		if player.Character then
			run(handler, player, player.Character)
		end
	end
end

function PlayerHooks.OnRemoving(handler)
	connect()
	table.insert(removingHandlers, handler)
end

return PlayerHooks
