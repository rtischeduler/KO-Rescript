local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Codes = {}

local COOLDOWN = 1
local REMOTE_NAME = "RedeemCode"

Codes.Rewards = {
	WELCOME = { GCells = 100 },
	LOTSZILLA = { GCells = 7000, Levels = 5 },
}

local lastTry = {}
local busy = {}
local okStore, levelStore = pcall(function()
	return DataStoreService:GetDataStore("PlayerLevels_v3")
end)

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

local function findValue(root, name)
	local found = root:FindFirstChild(name) or root:FindFirstChild(name, true)
	if found and found:IsA("ValueBase") then
		return found
	end
	return nil
end

local function getGCells(player)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		return nil
	end
	for _, child in ipairs(stats:GetChildren()) do
		if child.Name:lower() == "gcells" and child:IsA("ValueBase") and type(child.Value) == "number" then
			return child
		end
	end
	return nil
end

local function getLevelParts(player)
	local character = player.Character
	if not character then
		return nil
	end
	local addXP = character:FindFirstChild("AddXP") or character:FindFirstChild("AddXP", true)
	local level = findValue(character, "Level")
	local xp = findValue(character, "XP")
	local kaiju = findValue(character, "Kaiju")
	if not (addXP and addXP:IsA("BindableEvent")) then
		return nil
	end
	if not (level and xp and kaiju and type(level.Value) == "number" and type(xp.Value) == "number") then
		return nil
	end
	return { addXP = addXP, level = level, xp = xp, kaiju = tostring(kaiju.Value) }
end

local function grantStoredLevels(player, count)
	local getSelected = _G.KUNGetSelectedKaiju
	local kaiju = getSelected and getSelected(player)
	if type(kaiju) ~= "string" or kaiju == "" then
		return nil, "select a kaiju first"
	end
	if not okStore or not levelStore then
		return nil, "level data is unavailable right now"
	end
	local LevelManager = require(ReplicatedStorage:WaitForChild("LevelManager"))
	local maxLevel = LevelManager.GetMaxLevel(kaiju)
	local gained, newLevel = 0, 1
	local ok = pcall(function()
		levelStore:UpdateAsync("Player_" .. player.UserId, function(data)
			if type(data) ~= "table" then
				data = {}
			end
			local entry = data[kaiju]
			if type(entry) ~= "table" then
				entry = { level = 1, xp = 0, usedSkillPoints = 0, xpVersion = LevelManager.XP_VERSION }
				data[kaiju] = entry
			end
			LevelManager.MigrateEntry(kaiju, entry)
			local current = entry.level or 1
			newLevel = math.min(maxLevel, current + count)
			gained = newLevel - current
			entry.level = newLevel
			if newLevel >= maxLevel then
				entry.xp = 0
			end
			return data
		end)
	end)
	if not ok then
		return nil, "level data could not be saved, try again"
	end
	local changed = ServerStorage:FindFirstChild("LevelChanged")
	if changed and changed:IsA("BindableEvent") then
		changed:Fire(player.UserId, kaiju, newLevel)
	end
	return kaiju, gained
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
		return false, "your G-Cells stat was not found"
	end

	local lines = {}
	if reward.Levels then
		local parts = getLevelParts(player)
		if parts then
			local gained, needed = planLevels(parts, reward.Levels)
			if gained > 0 then
				parts.addXP:Fire(needed)
				table.insert(lines, "+" .. gained .. (gained == 1 and " level" or " levels") .. " on " .. parts.kaiju)
			else
				table.insert(lines, parts.kaiju .. " is already max level")
			end
		else
			local kaiju, gained = grantStoredLevels(player, reward.Levels)
			if not kaiju then
				return false, gained
			end
			if gained > 0 then
				table.insert(lines, "+" .. gained .. (gained == 1 and " level" or " levels") .. " on " .. kaiju)
			else
				table.insert(lines, kaiju .. " is already max level")
			end
		end
	end

	if gcells then
		if _G.GCellGuardAllow then
			_G.GCellGuardAllow(gcells, reward.GCells)
		end
		gcells.Value += reward.GCells
		table.insert(lines, 1, commas(reward.GCells) .. " G-Cells")
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
		busy[player.UserId] = nil
	end)

	remote.OnServerEvent:Connect(function(player, text)
		local userId = player.UserId
		if busy[userId] then
			return
		end
		local now = os.clock()
		if lastTry[userId] and now - lastTry[userId] < COOLDOWN then
			remote:FireClient(player, false, "Slow down.")
			return
		end
		lastTry[userId] = now
		busy[userId] = true
		local function finish(success, message)
			busy[userId] = nil
			remote:FireClient(player, success, message)
		end
		if not store.ready(userId) then
			finish(false, "Codes are unavailable right now. Try again later.")
			return
		end
		local key = Codes.normalize(text)
		local reward = key and Codes.Rewards[key]
		if not reward then
			finish(false, "Invalid code.")
			return
		end
		if store.has(userId, key) then
			finish(false, "You already redeemed this code.")
			return
		end
		local given, message = Codes.grant(player, reward)
		if not given then
			finish(false, "Could not give the reward: " .. tostring(message) .. ".")
			return
		end
		store.mark(userId, key)
		finish(true, message)
	end)
end

return Codes
