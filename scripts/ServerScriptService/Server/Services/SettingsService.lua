local SettingsService = { Name = "Settings", Async = true }

local AUTOSAVE_SECONDS = 60
local REDEEM_COOLDOWN = 1

function SettingsService.normalizeFov(value, cfg)
	if type(value) ~= "number" or value ~= value then
		return nil
	end
	return math.clamp(value, cfg.MinFov, cfg.MaxFov)
end

function SettingsService.cleanPrefs(data, KOSettings)
	local out = {}
	if type(data) ~= "table" then
		return out
	end
	for name in pairs(KOSettings.Defaults()) do
		local clean = KOSettings.Validate(name, data[name])
		if clean ~= nil then
			out[name] = clean
		end
	end
	return out
end

function SettingsService.cleanCodes(data)
	local out = {}
	if type(data) ~= "table" then
		return out
	end
	for key, value in pairs(data) do
		if type(key) == "string" and value == true then
			out[key] = true
		end
	end
	return out
end

function SettingsService:Init()
	local DataStoreService = game:GetService("DataStoreService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local framework = script:FindFirstAncestor("Server")
	local PlayerHooks = require(framework.Core.PlayerHooks)
	local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))
	local Logger = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Logger"))
	local KOSettings = require(ReplicatedStorage:WaitForChild("KOSettings"))
	local Codes = require(framework:WaitForChild("Codes"))
	local cfg = require(framework.Config).Settings
	local log = Logger.new("Settings")

	local okStore, store = pcall(function()
		return DataStoreService:GetDataStore(cfg.StoreName)
	end)
	if not okStore then
		log:warn("DataStore unavailable, settings will not persist: " .. tostring(store))
		store = nil
	end

	local values, prefs, redeemed = {}, {}, {}
	local dirty, saving, loaded, failed, rev, lastRedeem = {}, {}, {}, {}, {}, {}

	local function keyFor(userId)
		return cfg.KeyPrefix .. userId
	end

	local function touch(userId)
		dirty[userId] = true
		rev[userId] = (rev[userId] or 0) + 1
	end

	local function save(userId)
		if not store or not dirty[userId] or saving[userId] or failed[userId] then
			return
		end
		local fov = values[userId]
		if not fov then
			return
		end
		local snapshotRev = rev[userId]
		local snapshot = {
			fov = fov,
			prefs = table.clone(prefs[userId] or {}),
			codes = table.clone(redeemed[userId] or {}),
		}
		saving[userId] = true
		local ok, err = Util.retry(function()
			store:SetAsync(keyFor(userId), snapshot)
		end, cfg.DataStoreAttempts, 1)
		saving[userId] = nil
		if ok then
			if rev[userId] == snapshotRev then
				dirty[userId] = nil
			end
		else
			log:warn("Failed to save settings for " .. tostring(userId) .. ": " .. tostring(err))
		end
	end

	PlayerHooks.OnPlayer(function(player)
		local userId = player.UserId
		prefs[userId] = prefs[userId] or {}
		redeemed[userId] = redeemed[userId] or {}
		if not store then
			values[userId] = values[userId] or cfg.DefaultFov
			loaded[userId] = true
			return
		end
		local ok, data = Util.retry(function()
			return store:GetAsync(keyFor(userId))
		end, cfg.DataStoreAttempts, 1)

		if not player.Parent then
			return
		end
		local hasData = ok and type(data) == "table"
		if ok then
			if hasData then
				prefs[userId] = SettingsService.cleanPrefs(data.prefs, KOSettings)
				redeemed[userId] = SettingsService.cleanCodes(data.codes)
			end
		else
			failed[userId] = true
		end
		if not dirty[userId] then
			local fov = hasData and SettingsService.normalizeFov(data.fov, cfg)
			values[userId] = fov or cfg.DefaultFov
			if fov then
				log:info(("Loaded FOV for %s: %s"):format(player.Name, tostring(fov)))
			end
		end
		loaded[userId] = true
	end)

	PlayerHooks.OnRemoving(function(player)
		local userId = player.UserId
		while saving[userId] do
			task.wait(0.2)
		end
		save(userId)
		values[userId] = nil
		prefs[userId] = nil
		redeemed[userId] = nil
		dirty[userId] = nil
		saving[userId] = nil
		loaded[userId] = nil
		failed[userId] = nil
		rev[userId] = nil
		lastRedeem[userId] = nil
	end)

	game:BindToClose(function()
		for userId in pairs(dirty) do
			save(userId)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for userId in pairs(dirty) do
				task.spawn(save, userId)
			end
		end
	end)

	local remote = ReplicatedStorage:WaitForChild(cfg.RemoteName, cfg.RemoteWaitTimeout)
	if not remote then
		error("remote '" .. cfg.RemoteName .. "' not found in ReplicatedStorage")
	end
	remote.OnServerInvoke = function(player, newFov)
		local userId = player.UserId
		local normalized = SettingsService.normalizeFov(newFov, cfg)
		if normalized then
			values[userId] = normalized
			touch(userId)
			return true
		end
		return values[userId] or cfg.DefaultFov
	end

	local prefsRemote = ReplicatedStorage:FindFirstChild("SettingsPrefs")
	if not prefsRemote then
		prefsRemote = Instance.new("RemoteFunction")
		prefsRemote.Name = "SettingsPrefs"
		prefsRemote.Parent = ReplicatedStorage
	end

	local function waitLoaded(userId)
		local waited = 0
		while not loaded[userId] and waited < 15 do
			task.wait(0.1)
			waited += 0.1
		end
		return loaded[userId] == true
	end

	Codes.Init({
		ready = function(userId)
			waitLoaded(userId)
			return loaded[userId] == true and not failed[userId] and redeemed[userId] ~= nil
		end,
		has = function(userId, key)
			return redeemed[userId][key] == true
		end,
		mark = function(userId, key)
			redeemed[userId][key] = true
			touch(userId)
			task.spawn(save, userId)
		end,
	})

	prefsRemote.OnServerInvoke = function(player, action, name, value)
		local userId = player.UserId
		if action == "get" then
			waitLoaded(userId)
			return table.clone(prefs[userId] or {})
		end
		if not loaded[userId] then
			return false
		end
		if action == "set" then
			local clean = KOSettings.Validate(name, value)
			if clean == nil then
				return false
			end
			prefs[userId] = prefs[userId] or {}
			prefs[userId][name] = clean
			touch(userId)
			return true
		elseif action == "reset" then
			prefs[userId] = {}
			values[userId] = cfg.DefaultFov
			touch(userId)
			return true
		end
		return false
	end
end

return SettingsService