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
			showEvent:FireAllClients(customName, 0, text, true)
			return
		end
	end

	showEvent:FireAllClients(player.Name, player.UserId, text, false)
end)

Players.PlayerRemoving:Connect(function(player)
	lastSent[player] = nil
end)
