local Players = game:GetService("Players")

local player = Players.LocalPlayer

if player:GetAttribute("ClientActive") then
	return
end

local Controllers = script:WaitForChild("Controllers")
local Logger = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Logger"))
local Lifecycle = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Lifecycle"))
local log = Logger.new("Client")

local REPLACED = {
	"BlindEffect",
	"BossHUD",
	"Daiju",
	"EliminatorPopupDisplay",
	"HideOwnTag",
	"KillMessageDisplay",
	"KnitClientBootstrap",
	"MenuCameraController",
	"Ocean",
	"PulseRenderer",
	"RaffleHUD",
	"RainClient",
	"SettingsSaver",
	"TouchControlHider",
}
local stillActive = {}
for _, name in ipairs(REPLACED) do
	local found = script.Parent:FindFirstChild(name)
	if found and found ~= script and found:IsA("BaseScript") and not found.Disabled then
		table.insert(stillActive, name)
	end
end
if #stillActive > 0 then
	log:warn("Not starting: delete or disable these replaced scripts first: " .. table.concat(stillActive, ", "))
	return
end

player:SetAttribute("ClientActive", true)

local lifecycle = Lifecycle.new(log)

lifecycle:Register(require(Controllers.Knit))
lifecycle:Register(require(Controllers.Menu))
lifecycle:Register(require(Controllers.Settings))
lifecycle:Register(require(Controllers.Touch))
lifecycle:Register(require(Controllers.Chat))
lifecycle:Register(require(Controllers.Hud))
lifecycle:Register(require(Controllers.Indicators))
lifecycle:Register(require(Controllers.Ocean))
lifecycle:Register(require(Controllers.WaterFX))
lifecycle:Register(require(Controllers.Effects))
lifecycle:Register(require(Controllers.Sounds))

lifecycle:InitAll()
lifecycle:StartAll()

log:info("Started. Controller status:\n" .. lifecycle:Report())
