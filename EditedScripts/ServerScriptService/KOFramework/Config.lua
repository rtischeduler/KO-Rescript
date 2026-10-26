-- Every tunable that used to be hard-coded across the loose scripts. Values match the originals exactly.
return {
	Morph = {
		-- Morphs that spawn on the TankSpawns folder instead of SpawnPoints
		TankSpawnMorphs = { "MILITARY TANK [FREE]", "F16C [FREE]" },
		TankSpawnHeight = 10,
		SpawnHeight = 50,

		-- Kaiju only the players below may use (anyone else is kicked). Names are case-insensitive.
		RestrictedKaiju = { "EVOLVED GOJIRA", "D.E.M.O.N", "Homelander", "d", "A-train", "e", "MG21" },
		AllowedPlayers = { "AthosGame2023", "mr_bolde2", "DenisTheCheeseKing", "BlueEnderCookie_2" },
		-- Optional: add UserIds here to survive username changes (names above keep working)
		AllowedUserIds = {},
	},

	Health = {
		RegenDelay = 20, -- seconds after last damage before regen starts
		RegenInterval = 3, -- seconds between regen ticks
		RegenBasePercent = 0.01015, -- of MaxHealth per tick
		RegenPerPoint = 0.15, -- extra multiplier per RegenModifier point
		CharacterParentTimeout = 30, -- give up waiting for a character to be parented after this long
	},

	GCellGuard = {
		ReadyDelay = 1, -- seconds before a freshly seen GCells value starts being policed
		AllowanceTtl = 1, -- seconds an _G.GCellGuardAllow grant stays valid
		Tolerance = 0.5,
		ValueNames = { "GCells", "gcells" },
	},

	Eliminator = {
		MinAdminRank = 2,
		AdminRankNames = { "Admin", "HeadAdmin", "Owner" },
		JoinCheckDelay = 2,
		DeathKickDelay = 1,
	},

	Settings = {
		StoreName = "PlayerSettings",
		KeyPrefix = "Player_",
		RemoteName = "GetSettingsData",
		DefaultFov = 70,
		MinFov = 70,
		MaxFov = 120,
		DataStoreAttempts = 3,
		RemoteWaitTimeout = 60,
	},

	-- Big existing modules loaded in place from ServerScriptService.framework.modules (order preserved)
	LegacyModules = { "Character", "Combat", "Data", "World" },
}
