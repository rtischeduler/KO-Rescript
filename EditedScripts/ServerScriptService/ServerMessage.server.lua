local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ALLOWED = {
	[string.lower("L0tzie")] = true,
	[string.lower("DenisTheCheeseKing")] = true,
	[string.lower("DandyDandicusDancif")] = true,
	[string.lower("25X_Rock")] = true,
}
local MAX_LENGTH = 200

local sendEvent = ReplicatedStorage:FindFirstChild("ServerMessageSend")
if not sendEvent then
	sendEvent = Instance.new("RemoteEvent")
	sendEvent.Name = "ServerMessageSend"
	sendEvent.Parent = ReplicatedStorage
end

local showEvent = ReplicatedStorage:FindFirstChild("ServerMessageShow")
if not showEvent then
	showEvent = Instance.new("RemoteEvent")
	showEvent.Name = "ServerMessageShow"
	showEvent.Parent = ReplicatedStorage
end

local lastSent = {}

local MAX_NAME_LENGTH = 32
local idCache = {}
local PROTECTED_NAME = "l0tzie"

local function normalizeName(name)
	local lowered = string.lower(name)
	lowered = lowered:gsub("[^%w]", "")
	lowered = lowered:gsub("0", "o")
	lowered = lowered:gsub("[1i]", "l")
	return lowered
end

local PROTECTED_KEY = normalizeName(PROTECTED_NAME)

local function isProtectedName(name)
	return string.find(normalizeName(name), PROTECTED_KEY, 1, true) ~= nil
end

local function lookupUserId(name)
	local key = string.lower(name)
	if idCache[key] ~= nil then
		return idCache[key] or 0
	end
	local ok, result = pcall(function()
		return Players:GetUserIdFromNameAsync(name)
	end)
	if ok and type(result) == "number" then
		idCache[key] = result
		return result
	end
	idCache[key] = false
	return 0
end

sendEvent.OnServerEvent:Connect(function(player, text, customName)
	if not ALLOWED[string.lower(player.Name)] then
		return
	end
	if typeof(text) ~= "string" then
		return
	end
	text = text:sub(1, MAX_LENGTH)
	if text:match("^%s*$") then
		return
	end
	local now = os.clock()
	if lastSent[player] and now - lastSent[player] < 1 then
		return
	end
	lastSent[player] = now

	if typeof(customName) == "string" then
		customName = customName:gsub("^%s+", ""):gsub("%s+$", "")
		customName = customName:sub(1, MAX_NAME_LENGTH)
		if customName ~= "" then
			if isProtectedName(customName) and string.lower(player.Name) ~= PROTECTED_NAME then
				showEvent:FireClient(player, "System", 0, "That display name is not allowed.", true)
				return
			end
			showEvent:FireAllClients(customName, lookupUserId(customName), text, true)
			return
		end
	end

	showEvent:FireAllClients(player.Name, player.UserId, text, false)
end)

Players.PlayerRemoving:Connect(function(player)
	lastSent[player] = nil
end)
