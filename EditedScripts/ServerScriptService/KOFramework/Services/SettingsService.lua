-- Replaces: SettingsStore.server.lua. Same DataStore ("PlayerSettings"), key ("Player_<id>"), value ({ fov = n })
-- and same GetSettingsData remote contract: number -> clamp, store, return true; anything else -> return stored FOV.
-- Fixes: retries on DataStore errors, saves on server shutdown, only writes when the FOV changed, and a failed
-- load can no longer overwrite a player's saved FOV with the default when they leave.
local SettingsService = { Name = "Settings", Async = true }

-- Returns a clamped number, or nil if the value is not a usable number (non-number or NaN).
function SettingsService.normalizeFov(value, cfg)
	if type(value) ~= "number" or value ~= value then
		return nil
	end
	return math.clamp(value, cfg.MinFov, cfg.MaxFov)
end

function SettingsService:Init()
	local DataStoreService = game:GetService("DataStoreService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local framework = script:FindFirstAncestor("KOFramework")
	local PlayerHooks = require(framework.Core.PlayerHooks)
	local Util = require(framework.Core.Util)
	local Logger = require(framework.Core.Logger)
	local cfg = require(framework.Config).Settings
	local log = Logger.new("Settings")

	local okStore, store = pcall(function()
		return DataStoreService:GetDataStore(cfg.StoreName)
	end)
	if not okStore then
		log:warn("DataStore unavailable, settings will not persist: " .. tostring(store))
		store = nil
	end

	local values, dirty, saving = {}, {}, {}

	local function keyFor(userId)
		return cfg.KeyPrefix .. userId
	end

	local function save(userId)
		if not store or not dirty[userId] or saving[userId] then
			return
		end
		local fov = values[userId]
		if not fov then
			return
		end
		saving[userId] = true
		local ok, err = Util.retry(function()
			store:SetAsync(keyFor(userId), { fov = fov })
		end, cfg.DataStoreAttempts, 1)
		saving[userId] = nil
		if ok then
			if values[userId] == fov then
				dirty[userId] = nil
			end
		else
			log:warn("Failed to save settings for " .. tostring(userId) .. ": " .. tostring(err))
		end
	end

	PlayerHooks.OnPlayer(function(player)
		local userId = player.UserId
		if not store then
			values[userId] = values[userId] or cfg.DefaultFov
			return
		end
		local ok, data = Util.retry(function()
			return store:GetAsync(keyFor(userId))
		end, cfg.DataStoreAttempts, 1)

		if not player.Parent then
			return -- left while loading
		end
		if dirty[userId] then
			return -- the client already set a value while we were loading; keep theirs
		end
		local loaded = ok and type(data) == "table" and SettingsService.normalizeFov(data.fov, cfg)
		values[userId] = loaded or cfg.DefaultFov
		if loaded then
			log:info(("Loaded FOV for %s: %s"):format(player.Name, tostring(loaded)))
		end
	end)

	PlayerHooks.OnRemoving(function(player)
		local userId = player.UserId
		save(userId)
		values[userId] = nil
		dirty[userId] = nil
		saving[userId] = nil
	end)

	game:BindToClose(function()
		for userId in pairs(dirty) do
			save(userId)
		end
	end)

	local remote = ReplicatedStorage:WaitForChild(cfg.RemoteName, cfg.RemoteWaitTimeout)
	if not remote then
		error("remote '" .. cfg.RemoteName .. "' not found in ReplicatedStorage")
	end
	remote.OnServerInvoke = function(player, newFov)
		local normalized = SettingsService.normalizeFov(newFov, cfg)
		if normalized then
			values[player.UserId] = normalized
			dirty[player.UserId] = true
			return true
		end
		return values[player.UserId] or cfg.DefaultFov
	end
end

return SettingsService
