return {
	Morph = {
		TankSpawnMorphs = { "MILITARY TANK [FREE]", "F16C [FREE]" },
		TankSpawnHeight = 10,
		SpawnHeight = 50,

		RestrictedKaiju = { "EVOLVED GOJIRA", "D.E.M.O.N", "Homelander", "d", "A-train", "e", "MG21" },
		AllowedPlayers = { "AthosGame2023", "mr_bolde2", "DenisTheCheeseKing", "BlueEnderCookie_2" },
		AllowedUserIds = {},
	},

	Health = {
		RegenDelay = 20,
		RegenInterval = 3,
		RegenBasePercent = 0.01015,
		RegenPerPoint = 0.15,
		CharacterParentTimeout = 30,
	},

	GCellGuard = {
		ReadyDelay = 1,
		AllowanceTtl = 1,
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

	LegacyModules = { "Character", "Combat", "Data", "World" },

	OceanDepth = {
		Enabled = true,
		FloorNames = { "Bottom" },
		DepthDrop = 25,
		WedgeGrow = 25,
		ColorTolerance = 0.02,
		MinUpright = 0.9,
		YieldEvery = 3000,
	},
}
