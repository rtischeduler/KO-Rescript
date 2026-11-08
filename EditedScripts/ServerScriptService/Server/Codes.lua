local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Codes = {}

local COOLDOWN = 1
local REMOTE_NAME = "RedeemCode"

Codes.Rewards = {
	WELCOME = { GCells = 100 },
	LOTSZILLA = { GCells = 7000, Levels = 5 },
}

local lastTry = {}

local function commas(n)
	local text = tostring(math.floor(n))
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

function Codes.normalize(text)
	if type(text) ~= "string" or #text > 40 then
		return nil
	end
	local cleaned = text:gsub("%s", ""):upper()
	return cleaned ~= "" and cleaned or nil
end

local function getGCells(player)
	local stats = player:FindFirstChild("leaderstats")
	local gcells = stats and (stats:FindFirstChild("GCells") or stats:FindFirstChild("gcells"))
	if gcells and gcells:IsA("IntValue") then
		return gcells
	end
	return nil
end

local function getLevelParts(player)
	local character = player.Character
	if not character then
		return nil
	end
	local addXP = character:FindFirstChild("AddXP")
	local level = character:FindFirstChild("Level")
	local xp = character:FindFirstChild("XP")
	local kaiju = character:FindFirstChild("Kaiju")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not (addXP and addXP:IsA("BindableEvent") and level and xp and kaiju and kaiju:IsA("StringValue")) then
		return nil
	end
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return { addXP = addXP, level = level, xp = xp, kaiju = kaiju.Value }
end

local function planLevels(parts, count)
	local LevelManager = require(ReplicatedStorage:WaitForChild("LevelManager"))
	local maxLevel = LevelManager.GetMaxLevel(parts.kaiju)
	local level = parts.level.Value
	local needed = -parts.xp.Value
	local gained = 0
	while gained < count and level < maxLevel do
		needed += LevelManager.GetXPForNextLevel(level, parts.kaiju)
		level += 1
		gained += 1
	end
	return gained, math.max(needed, 0)
end

function Codes.grant(player, reward)
	local gcells = reward.GCells and getGCells(player)
	if reward.GCells and not gcells then
		return false
	end
	local parts = reward.Levels and getLevelParts(player)
	if reward.Levels and not parts then
		return false
	end

	local lines = {}
	if gcells then
		if _G.GCellGuardAllow then
			_G.GCellGuardAllow(gcells, reward.GCells)
		end
		gcells.Value += reward.GCells
		table.insert(lines, commas(reward.GCells) .. " G-Cells")
	end
	if parts then
		local gained, needed = planLevels(parts, reward.Levels)
		if gained > 0 then
			parts.addXP:Fire(needed)
			table.insert(lines, "+" .. gained .. (gained == 1 and " level" or " levels") .. " on " .. parts.kaiju)
		else
			table.insert(lines, parts.kaiju .. " is already max level")
		end
	end
	return true, "You received " .. table.concat(lines, " and ") .. "!"
end

function Codes.Init(store)
	local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = REMOTE_NAME
		remote.Parent = ReplicatedStorage
	end

	Players.PlayerRemoving:Connect(function(player)
		lastTry[player.UserId] = nil
	end)

	remote.OnServerEvent:Connect(function(player, text)
		local userId = player.UserId
		local now = os.clock()
		if lastTry[userId] and now - lastTry[userId] < COOLDOWN then
			remote:FireClient(player, false, "Slow down.")
			return
		end
		lastTry[userId] = now
		if not store.ready(userId) then
			remote:FireClient(player, false, "Codes are unavailable right now. Try again later.")
			return
		end
		local key = Codes.normalize(text)
		local reward = key and Codes.Rewards[key]
		if not reward then
			remote:FireClient(player, false, "Invalid code.")
			return
		end
		if store.has(userId, key) then
			remote:FireClient(player, false, "You already redeemed this code.")
			return
		end
		local given, message = Codes.grant(player, reward)
		if not given then
			remote:FireClient(player, false, "Could not give the reward yet. Try again in a moment.")
			return
		end
		store.mark(userId, key)
		remote:FireClient(player, true, message)
	end)
end

return Codes
