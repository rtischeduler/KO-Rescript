local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_NAME = "RewardIndicator"
local FLUSH_INTERVAL = 0.25

local IndicatorService = { Name = "Indicators" }

local pending = {}
local stamps = setmetatable({}, { __mode = "k" })
local remote

local function ownHead(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and (root.Position + Vector3.new(0, 4, 0)) or nil
end

local function resolve(at, player)
	if typeof(at) == "Vector3" then
		return at
	end
	if typeof(at) == "Instance" then
		if at:IsA("Humanoid") then
			at = at.Parent
		end
		if at and at:IsA("BasePart") then
			return at.Position
		end
		if at and at:IsA("Model") then
			local ok, cframe, size = pcall(at.GetBoundingBox, at)
			if ok then
				return cframe.Position + Vector3.new(0, size.Y * 0.35, 0)
			end
		end
	end
	return ownHead(player)
end

local function flush()
	for player, bucket in pending do
		pending[player] = nil
		if player.Parent and remote then
			for _, entry in bucket do
				local position = resolve(entry.at, player)
				if position then
					remote:FireClient(player, position, entry.damage, entry.gcells, entry.xp, entry.candy)
				end
			end
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

	_G.ShowIndicator = function(player, damage, gcells, xp, at, candy)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			return
		end
		damage = math.max(tonumber(damage) or 0, 0)
		gcells = math.max(tonumber(gcells) or 0, 0)
		xp = math.max(tonumber(xp) or 0, 0)
		candy = math.max(tonumber(candy) or 0, 0)
		if damage + gcells + xp + candy <= 0 then
			return
		end
		if damage > 0 and typeof(at) == "Instance" then
			local model = at:IsA("Humanoid") and at.Parent or at
			local mine = stamps[player]
			if not mine then
				mine = setmetatable({}, { __mode = "k" })
				stamps[player] = mine
			end
			mine[model] = os.clock()
		end
		local key = at
		if key == nil then
			key = "self"
		end
		local bucket = pending[player]
		if not bucket then
			bucket = {}
			pending[player] = bucket
		end
		local entry = bucket[key]
		if not entry then
			entry = { at = at, damage = 0, gcells = 0, xp = 0, candy = 0 }
			bucket[key] = entry
		end
		entry.damage += damage
		entry.gcells += gcells
		entry.xp += xp
		entry.candy += candy
	end

	_G.WasIndicated = function(player, at, window)
		local mine = stamps[player]
		if not mine or typeof(at) ~= "Instance" then
			return false
		end
		local model = at:IsA("Humanoid") and at.Parent or at
		local stamp = mine[model]
		return stamp ~= nil and os.clock() - stamp <= (window or 0.5)
	end

	Players.PlayerRemoving:Connect(function(player)
		pending[player] = nil
		stamps[player] = nil
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
