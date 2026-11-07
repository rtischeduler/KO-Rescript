local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local ALLOWED = "L0tzie"
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

sendEvent.OnServerEvent:Connect(function(player, text)
	if player.Name ~= ALLOWED then
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

	local ok, result = pcall(function()
		local filtered = TextService:FilterStringAsync(text, player.UserId)
		return filtered:GetNonChatStringForBroadcastAsync()
	end)
	if not ok or typeof(result) ~= "string" then
		return
	end

	showEvent:FireAllClients(player.Name, player.UserId, result)
end)

Players.PlayerRemoving:Connect(function(player)
	lastSent[player] = nil
end)
