local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_NAME = "RewardIndicator"
local FLUSH_INTERVAL = 0.2

local IndicatorService = { Name = "Indicators" }

local pending = {}
local remote

local function flush()
	for player, entry in pending do
		pending[player] = nil
		if player.Parent and remote then
			remote:FireClient(player, entry.damage, entry.gcells, entry.xp)
		end
	end
end

function IndicatorService:Init()
	remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = REMOTE_NAME
		remote.Parent = ReplicatedStorage
	end

	_G.ShowIndicator = function(player, damage, gcells, xp)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			return
		end
		damage = math.max(tonumber(damage) or 0, 0)
		gcells = math.max(tonumber(gcells) or 0, 0)
		xp = math.max(tonumber(xp) or 0, 0)
		if damage + gcells + xp <= 0 then
			return
		end
		local entry = pending[player]
		if not entry then
			entry = { damage = 0, gcells = 0, xp = 0 }
			pending[player] = entry
		end
		entry.damage += damage
		entry.gcells += gcells
		entry.xp += xp
	end

	Players.PlayerRemoving:Connect(function(player)
		pending[player] = nil
	end)
end

function IndicatorService:Start()
	task.spawn(function()
		while true do
			task.wait(FLUSH_INTERVAL)
			flush()
		end
	end)
end

return IndicatorService
