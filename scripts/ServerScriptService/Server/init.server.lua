local ServerScriptService = game:GetService("ServerScriptService")

if ServerScriptService:GetAttribute("ServerFrameworkActive") then
	return
end

local Services = script:WaitForChild("Services")
local Logger = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Logger"))
local Lifecycle = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Lifecycle"))
local Config = require(script:WaitForChild("Config"))
local log = Logger.new("Server")

local REPLACED = {
	"ServerHandler",
	"MorphBootstrap",
	"HealthEnforcer",
	"GCellIntegrityGuard",
	"PlayerEliminator",
	"SettingsStore",
}
local stillActive = {}
for _, name in ipairs(REPLACED) do
	local found = ServerScriptService:FindFirstChild(name)
	if found and found ~= script and not (found:IsA("BaseScript") and found.Disabled) then
		table.insert(stillActive, name)
	end
end
if #stillActive > 0 then
	log:warn("Not starting: disable or delete these replaced scripts first: " .. table.concat(stillActive, ", "))
	return
end

ServerScriptService:SetAttribute("ServerFrameworkActive", true)

local lifecycle = Lifecycle.new(log)

lifecycle:Register(require(Services.MorphService))
lifecycle:Register(require(Services.GCellGuardService))
lifecycle:Register(require(Services.IndicatorService))
lifecycle:Register(require(Services.CandyService))
lifecycle:Register(require(Services.EliminatorService))
lifecycle:Register(require(Services.SettingsService))
lifecycle:Register(require(Services.HealthService))
lifecycle:Register(require(Services.OceanDepthService))

local LegacyService = require(Services.LegacyService)
for _, moduleName in ipairs(Config.LegacyModules) do
	lifecycle:Register(LegacyService.Create(moduleName))
end

lifecycle:Register(require(Services.KnitService))

lifecycle:InitAll()
lifecycle:StartAll()

ServerScriptService:SetAttribute("ServerReady", true)
log:info("Started. Service status:\n" .. lifecycle:Report())
