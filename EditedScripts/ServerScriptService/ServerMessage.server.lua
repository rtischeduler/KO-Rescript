local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ALLOWED = {
	[string.lower("L0tzie")] = true,
	[string.lower("DenisTheCheeseKing")] = true,
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

sendEvent.OnServerEvent:Connect(function(player, text)
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

	showEvent:FireAllClients(player.Name, player.UserId, text)
end)

Players.PlayerRemoving:Connect(function(player)
	lastSent[player] = nil
end)
