return {
	Menu = {
		CameraName = "MenuCameraControl",
		CameraPriorityOffset = 1000,
		TweenSeconds = 0.6,
		DeathReturnDelay = 4,
		EntityUnlockUser = "L0tzie",
	},

	Settings = {
		MinFov = 70,
		MaxFov = 120,
	},

	Hud = {
		BossEndSeconds = 10,
		BlindHoldSeconds = 5,
		BlindFadeSeconds = 1,
	},

	Rain = {
		OffsetY = 60,
	},

	Pulse = {
		WaitTimeout = 10,
		BurstTime = 0.4,
		SustainTime = 0.5,
		DissipateTime = 0.6,
		BurstOvershoot = 1.1,
		DissipateGrowth = 1.25,
		MaxActive = 12,
		DefaultSize = 300,
		MinSize = 5,
		MaxSize = 2000,
	},

	Ocean = {
		WaitTimeout = 30,
		LevelOffset = 0,
		UpdateRate = 30,
		WaveSpeed = 0.7,
		WaveHeight = 0.45,
		NormalStrength = 5,
		Darken = 0.85,
		RippleHeight = 0.4,
		RippleSpeed = 9,
		RippleWidth = 4,
		RippleLife = 1.8,
		RippleBrightness = 1,
		MaxRipples = 32,
		MaxTriangles = 14000,
		RingSegments = 72,
		DetailRadius = 320,
		DetailPower = 1.3,
		DetailRings = 40,
		OuterRadius = 1000,
		OuterRings = 6,
		FarDrop = 3,
		Waves = {
			{ angle = 15,   length = 160, amp = 1.6,  fade = 1.00 },
			{ angle = -40,  length = 95,  amp = 1.1,  fade = 0.85 },
			{ angle = 70,   length = 60,  amp = 0.65, fade = 0.65 },
			{ angle = -110, length = 42,  amp = 0.35, fade = 0.5 },
		},
	},
}
