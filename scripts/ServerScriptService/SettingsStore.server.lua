local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local saveRemote = ReplicatedStorage:WaitForChild("GetSettingsData")
local settingsStore = DataStoreService:GetDataStore("PlayerSettings")

local settingsSave = {}

Players.PlayerAdded:Connect(function(player)
	local playerKey = "Player_" .. player.UserId

	local success, savedData = pcall(function()
		return settingsStore:GetAsync(playerKey)
	end)

	if success and savedData and savedData.fov then
		settingsSave[player.UserId] = savedData.fov
		print("Loaded FOV for " .. player.Name .. ": " .. savedData.fov)
	else
		settingsSave[player.UserId] = 70
	end
end)

saveRemote.OnServerInvoke = function(player, newFov)
	if typeof(newFov) == "number" then
		settingsSave[player.UserId] = math.clamp(newFov, 70, 120)
		return true
	end

	return settingsSave[player.UserId] or 70
end

Players.PlayerRemoving:Connect(function(player)
	if settingsSave[player.UserId] then
		local success, err = pcall(function()
			local playerKey = "Player_" .. player.UserId
			settingsStore:SetAsync(playerKey, {fov = settingsSave[player.UserId]})
		end)

		if not success then
			warn("Failed to save data for " .. player.Name .. ": " .. tostring(err))
		else
			print("Successfully saved player settings")
		end
	end
	settingsSave[player.UserId] = nil
end)
