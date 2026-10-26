-- KOFramework: single entry point for the server. See EditedScripts/README.md for install + rollback.
local ServerScriptService = game:GetService("ServerScriptService")

if ServerScriptService:GetAttribute("KOFrameworkActive") then
	return
end

local Core = script:WaitForChild("Core")
local Services = script:WaitForChild("Services")
local Logger = require(Core.Logger)
local Lifecycle = require(Core.Lifecycle)
local Config = require(script:WaitForChild("Config"))
local log = Logger.new("KOFramework")

-- Safety net: these scripts are replaced by the framework. If any is still enabled we do nothing, so the old
-- setup keeps running untouched instead of double-initialising Data/Combat (duplicate remotes, double saves).
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

ServerScriptService:SetAttribute("KOFrameworkActive", true)

local lifecycle = Lifecycle.new(log)

-- Order matters: Morph claims MorphBootstrapActive before the legacy Character module initialises.
lifecycle:Register(require(Services.MorphService))
lifecycle:Register(require(Services.GCellGuardService)) -- installs _G.GCellGuardAllow before Combat/World run
lifecycle:Register(require(Services.EliminatorService))
lifecycle:Register(require(Services.SettingsService))
lifecycle:Register(require(Services.HealthService))

local LegacyService = require(Services.LegacyService)
for _, moduleName in ipairs(Config.LegacyModules) do
	lifecycle:Register(LegacyService.Create(moduleName))
end

lifecycle:Register(require(Services.KnitService))

lifecycle:InitAll()
lifecycle:StartAll()

ServerScriptService:SetAttribute("KOFrameworkReady", true)
log:info("Started. Service status:\n" .. lifecycle:Report())
