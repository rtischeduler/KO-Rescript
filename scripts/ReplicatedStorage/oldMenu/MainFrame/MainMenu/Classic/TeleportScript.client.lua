local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local button = script.Parent
local PLACE_ID = 93353573853653

button.MouseButton1Click:Connect(function()
	local player = Players.LocalPlayer
	TeleportService:Teleport(PLACE_ID, player)
end)
