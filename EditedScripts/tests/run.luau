local Util = require("../ReplicatedStorage/Shared/Util")
local Lifecycle = require("../ReplicatedStorage/Shared/Lifecycle")
local Config = require("../ServerScriptService/Server/Config")
local Health = require("../ServerScriptService/Server/Services/HealthService")
local GCell = require("../ServerScriptService/Server/Services/GCellGuardService")
local Settings = require("../ServerScriptService/Server/Services/SettingsService")
local Eliminator = require("../ServerScriptService/Server/Services/EliminatorService")
local Quality = require("../ReplicatedStorage/Shared/GraphicsQuality")
local Perf = require("../ServerScriptService/Server/Services/PerformanceService")
local Reward = require("../ServerScriptService/Server/Services/RewardScalingService")

local failures, total = {}, 0
local function check(name, condition)
	total += 1
	if not condition then
		table.insert(failures, name)
	end
end
local function near(a, b)
	return math.abs(a - b) < 1e-9
end

local function stubLog()
	local log = { warnings = {} }
	function log:warn(message) table.insert(self.warnings, message) end
	function log:info() end
	return log
end
local function immediate(fn, ...) fn(...) end

local set = Util.lowerSet({ "Foo", "BAR", "d" })
check("lowerSet lowercases keys", set.foo and set.bar and set.d and not set.Foo)

local waits = {}
local calls = 0
local ok, result = Util.retry(function()
	calls += 1
	if calls < 3 then error("boom") end
	return "yes"
end, 3, 2, function(s) table.insert(waits, s) end)
check("retry succeeds on third try", ok == true and result == "yes" and calls == 3)
check("retry backs off linearly", #waits == 2 and waits[1] == 2 and waits[2] == 4)

waits = {}
local ok2, err2 = Util.retry(function() error("nope") end, 2, 1, function(s) table.insert(waits, s) end)
check("retry gives up with the last error", ok2 == false and string.find(tostring(err2), "nope") ~= nil and #waits == 1)

do
	local log = stubLog()
	local order = {}
	local lc = Lifecycle.new(log, { spawn = immediate })
	local function svc(name, extra)
		local def = { Name = name, Init = function() table.insert(order, name) end }
		for k, v in pairs(extra or {}) do def[k] = v end
		return lc:Register(def)
	end
	svc("B", { Requires = { "A" } })
	svc("A")
	svc("C", { Init = function() error("c broke") end })
	svc("D")
	svc("E", { Requires = { "C" } })
	svc("F", { Requires = { "Ghost" } })
	lc:InitAll()
	check("dependency initialises before dependent", order[1] == "A" and order[2] == "B")
	check("failure in one service does not stop others", table.find(order, "D") ~= nil)
	check("failed service recorded", string.find(lc.status.C, "failed") ~= nil)
	check("dependent of failed service is skipped", lc.status.E == "skipped: C failed" and not table.find(order, "E"))
	check("missing dependency is reported", string.find(lc.status.F, "missing dependency Ghost") ~= nil)
	check("warnings were logged", #log.warnings >= 3)

	local started = {}
	lc._ordered = lc._ordered
	for _, def in ipairs(lc._ordered) do
		def.Start = function() table.insert(started, def.Name) end
	end
	lc:StartAll()
	check("Start only runs for healthy services", table.find(started, "A") ~= nil and not table.find(started, "C"))
	check("report lists every registered service", string.find(lc:Report(), "  A ") ~= nil and string.find(lc:Report(), "  F ") ~= nil and string.find(lc:Report(), "  Ghost ") == nil)
end

do
	local lc = Lifecycle.new(stubLog(), { spawn = immediate })
	lc:Register({ Name = "X", Requires = { "Y" } })
	lc:Register({ Name = "Y", Requires = { "X" } })
	lc:InitAll()
	check("dependency cycle does not hang and is flagged", string.find(lc.status.X .. lc.status.Y, "cycle") ~= nil)
	local dupOk = pcall(function() lc:Register({ Name = "X" }) end)
	check("duplicate names are rejected", dupOk == false)
end

do
	local spawned = 0
	local lc = Lifecycle.new(stubLog(), { spawn = function(fn) spawned += 1; fn() end })
	lc:Register({ Name = "Sync", Init = function() end })
	lc:Register({ Name = "Async", Async = true, Init = function() end })
	lc:InitAll()
	check("only Async services are spawned", spawned == 1)
end

local h = Config.Health
check("regen matches old formula (no points)", near(Health.regenAmount(1000, nil, h), 1000 * 0.01015))
check("regen matches old formula (2 points)", near(Health.regenAmount(1000, 2, h), 1000 * 0.01015 * 1.3))
check("full health never regens", Health.canRegen(100, 100, nil, nil, 50, 20) == false)
check("boss mode blocks regen", Health.canRegen(50, 100, true, nil, 50, 20) == false)
check("never damaged regens immediately", Health.canRegen(50, 100, nil, nil, 0.1, 20) == true)
check("recent damage blocks regen", Health.canRegen(50, 100, nil, 100, 110, 20) == false)
check("regen resumes after the delay", Health.canRegen(50, 100, nil, 100, 120, 20) == true)

check("granted increase passes", GCell.isIncreaseAllowed(100, 100, 0.5) == true)
check("rounding tolerance passes", GCell.isIncreaseAllowed(100, 99.6, 0.5) == true)
check("ungranted increase is rejected", GCell.isIncreaseAllowed(5, 0, 0.5) == false)

local s = Config.Settings
check("fov clamps high", Settings.normalizeFov(500, s) == 120)
check("fov clamps low", Settings.normalizeFov(10, s) == 70)
check("fov keeps valid", Settings.normalizeFov(90, s) == 90)
check("fov rejects non-numbers", Settings.normalizeFov("90", s) == nil and Settings.normalizeFov(nil, s) == nil)
check("fov rejects NaN", Settings.normalizeFov(0 / 0, s) == nil)

check("rank entry matches name case-insensitively", Eliminator.entryMatches("BlueEnderCookie_2", "blueendercookie_2", 1))
check("rank entry matches userId", Eliminator.entryMatches(42, "x", 42))
check("rank entry ignores blanks and mismatches", not Eliminator.entryMatches("", "x", 1) and not Eliminator.entryMatches(7, "x", 8))

check("config: regen constants unchanged", h.RegenDelay == 20 and h.RegenInterval == 3 and h.RegenBasePercent == 0.01015 and h.RegenPerPoint == 0.15)
check("config: restricted kaiju + allowed players unchanged", #Config.Morph.RestrictedKaiju == 7 and #Config.Morph.AllowedPlayers == 4)
check("config: legacy module order unchanged", table.concat(Config.LegacyModules, ",") == "Character,Combat,Data,World")
check("config: guard timings unchanged", Config.GCellGuard.ReadyDelay == 1 and Config.GCellGuard.AllowanceTtl == 1 and Config.GCellGuard.Tolerance == 0.5)

check("graphics: starts on High with no ocean cap", Quality.Get() == "High" and Quality.Settings().OceanRate == nil and Quality.Settings().ParticleScale == 1)
check("graphics: steps High>Medium>Low>Lowest then stops", Quality.Next() == "Medium" and #Quality.Order() == 4 and Quality.Order()[4] == "Lowest")
check("graphics: particle scale only goes down", Quality.Order()[2] == "Medium" and Quality.Set("Nope") == false)
check("perf: lag threshold", Perf.isLagging(0.05, 1 / 30) and not Perf.isLagging(1 / 60, 1 / 30))

do
	local rc = Config.RewardScaling
	local g1, x1 = Reward.compute(1, false, false, true, rc)
	local g2, x2 = Reward.compute(1, false, true, false, rc)
	local g3, x3 = Reward.compute(1, false, true, true, rc)
	local g4, x4 = Reward.compute(30, false, false, true, rc)
	local g5, x5 = Reward.compute(6, false, false, true, rc)
	local g6, x6 = Reward.compute(1, true, true, true, rc)
	check("reward: fair fight is full", g1 == 1 and x1 == 1)
	check("reward: hitting a starter gives 0 gcells, tiny xp", g2 == 0 and x2 == rc.StarterXp)
	check("reward: killing a starter gives nothing", g3 == 0 and x3 == 0)
	check("reward: unbalanced gives nothing", g4 == 0 and x4 == 0)
	check("reward: stronger vs weaker tapers", g5 > 0 and g5 < 1 and x5 > g5)
	check("reward: starter vs starter is normal", g6 == 1 and x6 == 1)
end

print(("%d checks, %d failed"):format(total, #failures))
for _, name in ipairs(failures) do
	print("  FAIL: " .. name)
end
if #failures > 0 then
	error("unit tests failed")
end
