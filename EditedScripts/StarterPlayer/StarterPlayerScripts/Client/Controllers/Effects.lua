local EffectsController = { Name = "Effects" }

local DEFAULT_QUALITY = { OceanRate = nil, WaterFx = 1, ParticleScale = 1 }
local resolvedQuality
local Quality = {
	Settings = function()
		if not resolvedQuality then
			local shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
			local module = shared and shared:FindFirstChild("GraphicsQuality")
			if module then
				local ok, result = pcall(require, module)
				if ok then
					resolvedQuality = result
				end
			end
		end
		return resolvedQuality and resolvedQuality.Settings() or DEFAULT_QUALITY
	end,
}

local function startRain(cfg)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local Workspace = game:GetService("Workspace")
	local Lighting = game:GetService("Lighting")
	local SoundService = game:GetService("SoundService")
	local ContentProvider = game:GetService("ContentProvider")
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")

	local rainTemplate = ReplicatedStorage:WaitForChild("Rain")
	local toggleEvent = ReplicatedStorage:WaitForChild("ToggleRain")
	local thunderEvent = ReplicatedStorage:WaitForChild("ThunderStrike", cfg.ThunderWaitTimeout)

	local okQuality, quality = pcall(function()
		return UserSettings().GameSettings.SavedQualityLevel.Value
	end)
	local lowEnd = UserInputService.TouchEnabled or (okQuality and quality > 0 and quality <= 4)
	local deviceScale = lowEnd and 0.5 or 1
	local okCfg, HolidayConfigs = pcall(function()
		return require(ReplicatedStorage:WaitForChild("HolidayConfigs", 5))
	end)

	local streakTexture = cfg.StreakTexture or ""
	if streakTexture == "" then
		for _, child in rainTemplate:GetChildren() do
			if child:IsA("ParticleEmitter") and child.Texture ~= "" then
				streakTexture = child.Texture
				break
			end
		end
	end

	local rig = nil
	local strikes = {}
	local flashConn = nil
	local correction = nil
	local bloom = nil
	local flashShown = false
	local preloaded = false

	local function particleScale()
		return deviceScale * Quality.Settings().ParticleScale
	end

	local function ignoreList(extra)
		local list = { extra }
		local character = Players.LocalPlayer and Players.LocalPlayer.Character
		if character then
			list[2] = character
		end
		return list
	end

	local function buildSplashPool()
		local pool = {}
		for i = 1, cfg.SplashPoolSize do
			local attachment = Instance.new("Attachment")
			attachment.Parent = Workspace.Terrain

			local scale = 0.75 + (i % 4) * 0.15
			local emitter = Instance.new("ParticleEmitter")
			emitter.Texture = cfg.SplashTexture
			emitter.Rate = 0
			emitter.Enabled = false
			emitter.Lifetime = NumberRange.new(cfg.SplashLifetime * 0.8, cfg.SplashLifetime * 1.2)
			emitter.Speed = NumberRange.new(0, 0)
			emitter.Rotation = NumberRange.new(0, 360)
			emitter.Orientation = Enum.ParticleOrientation.FacingCamera
			emitter.LightEmission = cfg.SplashLightEmission
			emitter.LightInfluence = 0.8
			emitter.Color = ColorSequence.new(cfg.SplashColor)
			emitter.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, cfg.SplashSize * 0.2 * scale),
				NumberSequenceKeypoint.new(0.35, cfg.SplashSize * 0.75 * scale),
				NumberSequenceKeypoint.new(1, cfg.SplashSize * scale),
			})
			emitter.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(0.5, 0.6),
				NumberSequenceKeypoint.new(1, 1),
			})
			emitter.Parent = attachment

			pool[i] = { attachment = attachment, emitter = emitter }
		end
		return pool
	end

	local function buildRig()
		local part = rainTemplate:Clone()
		for _, child in part:GetChildren() do
			if child:IsA("ParticleEmitter") or child:IsA("BaseScript") then
				child:Destroy()
			end
		end
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Transparency = 1
		part.Size = Vector3.new(cfg.PlateSize, 1, cfg.PlateSize)
		part:SetAttribute("GraphicsManaged", true)

		local holiday = okCfg and HolidayConfigs.getActive() or nil
		local tint = holiday and holiday.RainColor or nil

		local emitters = {}
		for _, layer in cfg.Layers do
			local lifetime = (cfg.OffsetY + cfg.FallDepth) / layer.speed
			local emitter = Instance.new("ParticleEmitter")
			emitter.Texture = streakTexture
			emitter.Orientation = Enum.ParticleOrientation.FacingCamera
			emitter.EmissionDirection = Enum.NormalId.Bottom
			emitter.Lifetime = NumberRange.new(lifetime * 0.92, lifetime * 1.08)
			emitter.Speed = NumberRange.new(layer.speed * 0.94, layer.speed * 1.06)
			emitter.Rotation = NumberRange.new(0, 0)
			emitter.SpreadAngle = Vector2.new(1.5, 1.5)
			emitter.Size = NumberSequence.new(layer.size)
			emitter.Color = ColorSequence.new(tint or layer.color)
			emitter.LightEmission = layer.lightEmission
			emitter.LightInfluence = 0.7
			emitter.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.1, layer.transparency),
				NumberSequenceKeypoint.new(0.8, layer.transparency),
				NumberSequenceKeypoint.new(1, 1),
			})
			emitter.Rate = 0
			emitter.Enabled = true
			emitter.Parent = part
			emitters[#emitters + 1] = { emitter = emitter, base = layer.rate, last = 0 }
		end

		local sound = part:FindFirstChild("Raining")
		local equalizer = nil
		local baseVolume = 0
		if sound then
			baseVolume = sound.Volume
			sound.Volume = 0
			equalizer = Instance.new("EqualizerSoundEffect")
			equalizer.Parent = sound
			sound:Play()
		end

		local coverParams = RaycastParams.new()
		coverParams.FilterType = Enum.RaycastFilterType.Exclude
		coverParams.IgnoreWater = true

		local splashParams = RaycastParams.new()
		splashParams.FilterType = Enum.RaycastFilterType.Exclude
		splashParams.IgnoreWater = false

		local mood = Instance.new("ColorCorrectionEffect")
		mood.Name = "StormMoodCorrection"
		mood.Parent = Lighting

		part.Parent = Workspace

		return {
			part = part,
			mood = mood,
			lastPosition = nil,
			cameraVelocity = Vector3.zero,
			roll = 0,
			lastRoll = 0,
			emitters = emitters,
			sound = sound,
			equalizer = equalizer,
			baseVolume = baseVolume,
			pool = buildSplashPool(),
			poolIndex = 0,
			intensity = 0,
			target = 1,
			cover = 0,
			coverTarget = 0,
			coverClock = 0,
			splashClock = 0,
			coverParams = coverParams,
			splashParams = splashParams,
			connections = {},
		}
	end

	local function destroyRig(r)
		for _, connection in r.connections do
			connection:Disconnect()
		end
		for _, entry in r.pool do
			entry.attachment:Destroy()
		end
		if r.sound then
			r.sound:Stop()
		end
		r.mood:Destroy()
		r.part:Destroy()
	end

	local function emitSplashes(r, cameraPosition)
		local density = particleScale() * r.intensity * (1 - r.cover * cfg.CoverSplash)
		local count = math.floor(cfg.SplashPerTick * density + math.random())
		if count <= 0 then return end

		r.splashParams.FilterDescendantsInstances = ignoreList(r.part)
		local rayVector = Vector3.new(0, -(cfg.SplashRayHeight + cfg.SplashRayDepth), 0)

		for _ = 1, count do
			local angle = math.random() * math.pi * 2
			local radius = math.sqrt(math.random()) * cfg.SplashRadius
			local origin = Vector3.new(
				cameraPosition.X + math.cos(angle) * radius,
				cameraPosition.Y + cfg.SplashRayHeight,
				cameraPosition.Z + math.sin(angle) * radius
			)
			local result = Workspace:Raycast(origin, rayVector, r.splashParams)
			if result and result.Normal.Y > cfg.SplashMinNormalY then
				local hit = result.Instance
				if hit:IsA("Terrain") or hit.Transparency < 0.95 then
					r.poolIndex = r.poolIndex % #r.pool + 1
					local entry = r.pool[r.poolIndex]
					entry.attachment.WorldPosition = result.Position + result.Normal * 0.05
					entry.emitter:Emit(1)
				end
			end
		end
	end

	local function stepRig(r, dt)
		local camera = Workspace.CurrentCamera
		if not camera then return end
		local cameraPosition = camera.CFrame.Position

		local direction = r.target - r.intensity
		local maxStep = dt / cfg.FadeSeconds
		if math.abs(direction) <= maxStep then
			r.intensity = r.target
		else
			r.intensity += math.sign(direction) * maxStep
		end

		if r.target == 0 and r.intensity <= 0.001 then
			destroyRig(r)
			if rig == r then
				rig = nil
			end
			return
		end

		r.coverClock += dt
		if r.coverClock >= cfg.CoverCheckSeconds then
			r.coverClock = 0
			r.coverParams.FilterDescendantsInstances = ignoreList(r.part)
			local hit = Workspace:Raycast(cameraPosition, Vector3.new(0, cfg.CoverRayLength, 0), r.coverParams)
			local covered = hit ~= nil and (hit.Instance:IsA("Terrain") or (hit.Instance.CanCollide and hit.Instance.Transparency < 0.95))
			r.coverTarget = covered and 1 or 0
		end
		r.cover += (r.coverTarget - r.cover) * math.min(1, dt * cfg.CoverResponse)

		local rateScale = particleScale() * r.intensity * (1 - (1 - cfg.CoverRate) * r.cover)
		for _, entry in r.emitters do
			local rate = entry.base * rateScale
			if math.abs(rate - entry.last) > 1 then
				entry.last = rate
				entry.emitter.Rate = rate
			end
		end

		if r.sound then
			r.sound.Volume = r.baseVolume * r.intensity * (1 - (1 - cfg.CoverVolume) * r.cover)
			r.equalizer.HighGain = -cfg.CoverMuffle * r.cover
		end

		local moodAmount = r.intensity * (1 - cfg.MoodCover * r.cover)
		r.mood.Brightness = -cfg.MoodDarken * moodAmount
		r.mood.Contrast = cfg.MoodContrast * moodAmount
		r.mood.Saturation = -cfg.MoodDesaturate * moodAmount
		r.mood.TintColor = Color3.new(1, 1, 1):Lerp(cfg.MoodTint, moodAmount)

		r.splashClock += dt
		if r.splashClock >= cfg.SplashInterval then
			r.splashClock = 0
			emitSplashes(r, cameraPosition)
		end
	end

	local function followCamera(r, dt)
		local camera = Workspace.CurrentCamera
		if not camera or not r.part.Parent then return end
		local cameraCFrame = camera.CFrame
		local position = cameraCFrame.Position

		if r.lastPosition and dt > 0 then
			local velocity = (position - r.lastPosition) / dt
			if velocity.Magnitude > cfg.MaxCameraSpeed then
				velocity = Vector3.zero
			end
			r.cameraVelocity = r.cameraVelocity:Lerp(velocity, math.min(1, dt * cfg.VelocityResponse))
		end
		r.lastPosition = position

		local horizontal = Vector3.new(r.cameraVelocity.X, 0, r.cameraVelocity.Z)
		local sideways = Vector3.new(cfg.WindX, 0, cfg.WindZ) - horizontal * cfg.MoveTilt
		local maxSideways = cfg.TiltSpeed * math.tan(math.rad(cfg.MaxTiltDegrees))
		if sideways.Magnitude > maxSideways then
			sideways = sideways.Unit * maxSideways
		end

		local drop = Vector3.new(sideways.X, -cfg.TiltSpeed, sideways.Z)
		local direction = drop.Unit

		local axis = Vector3.new(0, -1, 0):Cross(direction)
		local rotation = CFrame.identity
		if axis.Magnitude > 1e-4 then
			rotation = CFrame.fromAxisAngle(axis.Unit, math.acos(math.clamp(-direction.Y, -1, 1)))
		end

		local drift = Vector3.new(direction.X, 0, direction.Z) / -direction.Y * cfg.OffsetY
		r.part.CFrame = CFrame.new(position + Vector3.new(0, cfg.OffsetY, 0) - drift) * rotation

		local screenX = drop:Dot(cameraCFrame.RightVector)
		local screenY = drop:Dot(cameraCFrame.UpVector)
		local targetRoll = math.deg(math.atan2(screenX, -screenY)) * cfg.RollSign
		targetRoll = math.clamp(targetRoll, -cfg.MaxRollDegrees, cfg.MaxRollDegrees)
		r.roll += (targetRoll - r.roll) * math.min(1, dt * cfg.TiltResponse)

		if math.abs(r.roll - r.lastRoll) > 0.3 then
			r.lastRoll = r.roll
			for _, entry in r.emitters do
				entry.emitter.Rotation = NumberRange.new(r.roll, r.roll)
			end
		end
	end

	local function beginRain()
		if rig then
			rig.target = 1
			return
		end

		local r = buildRig()
		rig = r

		r.connections[#r.connections + 1] = RunService.RenderStepped:Connect(function(dt)
			followCamera(r, dt)
		end)
		r.connections[#r.connections + 1] = RunService.Heartbeat:Connect(function(dt)
			stepRig(r, dt)
		end)

		if not preloaded then
			preloaded = true
			task.spawn(function()
				local assets = {}
				for _, id in cfg.ThunderIds do
					local sound = Instance.new("Sound")
					sound.SoundId = id
					assets[#assets + 1] = sound
				end
				pcall(function()
					ContentProvider:PreloadAsync(assets)
				end)
				for _, sound in assets do
					sound:Destroy()
				end
			end)
		end
	end

	local function endRain()
		if rig then
			rig.target = 0
		end
	end

	local function ensureFlashEffects()
		if not correction or not correction.Parent then
			correction = Instance.new("ColorCorrectionEffect")
			correction.Name = "StormFlashCorrection"
			correction.Enabled = false
			correction.Parent = Lighting
		end
		if not bloom or not bloom.Parent then
			bloom = Instance.new("BloomEffect")
			bloom.Name = "StormFlashBloom"
			bloom.Intensity = 0
			bloom.Size = cfg.FlashBloomSize
			bloom.Threshold = cfg.FlashBloomThreshold
			bloom.Enabled = false
			bloom.Parent = Lighting
		end
	end

	local function applyFlash(level)
		if not correction or not bloom then return end
		if level > 0.002 then
			flashShown = true
			correction.Enabled = true
			bloom.Enabled = true
			correction.Brightness = level * cfg.FlashBrightness
			correction.Contrast = level * cfg.FlashContrast
			correction.Saturation = -level * cfg.FlashDesaturate
			correction.TintColor = Color3.new(1, 1, 1):Lerp(cfg.FlashTint, level)
			bloom.Intensity = level * cfg.FlashBloom
		elseif flashShown then
			flashShown = false
			correction.Enabled = false
			bloom.Enabled = false
			correction.Brightness = 0
			correction.Contrast = 0
			correction.Saturation = 0
			correction.TintColor = Color3.new(1, 1, 1)
			bloom.Intensity = 0
		end
	end

	local function stepStrikes(dt)
		local level = 0
		local now = os.clock()
		for sound, strike in strikes do
			local finished = false
			if sound.IsPlaying then
				strike.started = true
				local loudness = sound.PlaybackLoudness
				if loudness > strike.peak then
					strike.peak = loudness
				end
				local normalized = math.clamp(loudness / math.max(strike.peak, cfg.LoudnessFloor), 0, 1)
				strike.smooth += (normalized - strike.smooth) * math.min(1, dt * cfg.FlashResponse)

				local remaining = (sound.TimeLength - sound.TimePosition) / math.max(sound.PlaybackSpeed, 0.05)
				local flashTail = math.clamp(remaining / cfg.FlashFadeSeconds, 0, 1)
				flashTail = flashTail * flashTail * (3 - 2 * flashTail)
				local soundTail = math.clamp(remaining / cfg.SoundFadeSeconds, 0, 1)

				sound.Volume = strike.volume * soundTail
				level = math.max(level, strike.smooth * strike.strength * flashTail)
			elseif strike.started or now - strike.born > cfg.ThunderLoadTimeout then
				finished = true
			end
			if finished then
				strikes[sound] = nil
				sound:Destroy()
			end
		end
		applyFlash(math.clamp(level, 0, 1))
	end

	local function ensureFlashLoop()
		if flashConn then return end
		flashConn = RunService.RenderStepped:Connect(function(dt)
			stepStrikes(dt)
			if next(strikes) == nil then
				flashConn:Disconnect()
				flashConn = nil
				applyFlash(0)
			end
		end)
	end

	local function playThunder(index, speed, volume, distance)
		if not rig then return end
		local id = cfg.ThunderIds[index]
		if typeof(id) ~= "string" then return end
		speed = math.clamp(tonumber(speed) or 1, 0.8, 1.2)
		volume = math.clamp(tonumber(volume) or 1, 0.2, 1)
		distance = math.clamp(tonumber(distance) or 0, 0, 1)

		local baseVolume = cfg.ThunderVolume * volume * (1 - cfg.ThunderDistanceVolume * distance)

		local sound = Instance.new("Sound")
		sound.Name = "Thunder"
		sound.SoundId = id
		sound.PlaybackSpeed = speed
		sound.Volume = 0

		local equalizer = Instance.new("EqualizerSoundEffect")
		equalizer.HighGain = -cfg.ThunderMuffle * distance
		equalizer.MidGain = -cfg.ThunderMuffle * 0.25 * distance
		equalizer.Parent = sound

		local reverbCfg = cfg.ThunderReverb
		local reverb = Instance.new("ReverbSoundEffect")
		reverb.DecayTime = reverbCfg.DecayTime + distance * reverbCfg.DistanceDecay
		reverb.Density = reverbCfg.Density
		reverb.Diffusion = reverbCfg.Diffusion
		reverb.DryLevel = reverbCfg.DryLevel
		reverb.WetLevel = reverbCfg.WetLevel + distance * reverbCfg.DistanceWet
		reverb.Parent = sound

		sound.Parent = SoundService

		local strike = {
			volume = baseVolume,
			strength = volume * (1 - cfg.FlashDistanceFalloff * distance),
			peak = 0,
			smooth = 0,
			started = false,
			born = os.clock(),
		}
		strikes[sound] = strike
		ensureFlashEffects()
		ensureFlashLoop()

		task.spawn(function()
			pcall(function()
				ContentProvider:PreloadAsync({ sound })
			end)
			if strikes[sound] == nil or not sound.Parent then return end
			if sound.TimeLength <= 0 then
				strikes[sound] = nil
				sound:Destroy()
				return
			end
			sound.Volume = strike.volume
			sound:Play()
		end)
	end

	toggleEvent.OnClientEvent:Connect(function(isRaining)
		if isRaining then
			beginRain()
		else
			endRain()
		end
	end)

	if thunderEvent then
		thunderEvent.OnClientEvent:Connect(playThunder)
	end
end

local function startPulse(cfg)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local Debris = game:GetService("Debris")

	local pulseFireEvent = ReplicatedStorage:WaitForChild("PulseFire", cfg.WaitTimeout)
	if not pulseFireEvent then return end

	local BURST_TIME = cfg.BurstTime
	local SUSTAIN_TIME = cfg.SustainTime
	local DISSIPATE_TIME = cfg.DissipateTime
	local BURST_OVERSHOOT = cfg.BurstOvershoot
	local DISSIPATE_GROWTH = cfg.DissipateGrowth
	local MAX_ACTIVE = cfg.MaxActive
	local DEFAULT_COLOR = Color3.fromRGB(255, 120, 0)

	local PART_SPIN = {
		Shock     = Vector3.new(0,   90,  0),
		Shockwave = Vector3.new(0,  -55,  0),
		Sphere    = Vector3.new(25,  70,  0),
		Sphere2   = Vector3.new(0,  -85, 30),
	}
	local SPHERE_NAMES = { Sphere = true, Sphere2 = true }
	local SHOCK_NAME = "Shockwave"

	local active = {}

	local function removeActive(entry)
		local i = table.find(active, entry)
		if i then table.remove(active, i) end
	end

	local function destroyEntry(entry)
		removeActive(entry)
		if entry.clone and entry.clone.Parent then
			entry.clone:Destroy()
		end
	end

	local function getBaseDimension(clone)
		local ok, scale = pcall(clone.GetScale, clone)
		if not ok or not scale or scale <= 0 then scale = 1 end
		local _, size = clone:GetBoundingBox()
		local dim = math.max(size.X, size.Y, size.Z) / scale
		if dim <= 0 then dim = 1 end
		return dim
	end

	local function easeOutQuart(p) return 1 - (1 - p) ^ 4 end
	local function easeInPow(p) return p ^ 2.2 end
	local function rand(a, b) return a + math.random() * (b - a) end

	local function playFallback(position, color, maxSize)
		local ball = Instance.new("Part")
		ball.Shape = Enum.PartType.Ball
		ball.Material = Enum.Material.Neon
		ball.Color = color
		ball.Anchored = true
		ball.CanCollide = false
		ball.CanTouch = false
		ball.CanQuery = false
		ball.CastShadow = false
		ball.Transparency = 0.35
		ball.Size = Vector3.new(2, 2, 2)
		ball.Position = position
		ball.Parent = workspace
		local total = BURST_TIME + SUSTAIN_TIME + DISSIPATE_TIME
		Debris:AddItem(ball, total + 1)
		local size = maxSize * BURST_OVERSHOOT
		game:GetService("TweenService"):Create(ball, TweenInfo.new(total, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(size, size, size),
			Transparency = 1,
		}):Play()
	end

	local function runPulse(firingPlayer, color, maxSize)
		if typeof(color) ~= "Color3" then color = DEFAULT_COLOR end
		if type(maxSize) ~= "number" then maxSize = cfg.DefaultSize end
		maxSize = math.clamp(maxSize, cfg.MinSize, cfg.MaxSize)

		if not firingPlayer or not firingPlayer.Parent then return end
		local character = firingPlayer.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local template = ReplicatedStorage:FindFirstChild("Pulse") or ReplicatedStorage:WaitForChild("Pulse", 3)
		if not template then
			warn("[Pulse] template missing from ReplicatedStorage, using fallback")
			playFallback(hrp.Position, color, maxSize)
			return
		end

		local localPlayer = game:GetService("Players").LocalPlayer
		local strength = 1
		if firingPlayer ~= localPlayer then
			local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
			if myRoot then
				strength = math.clamp(1 - (myRoot.Position - hrp.Position).Magnitude / (maxSize * 1.5), 0, 1) * 0.6
			else
				strength = 0
			end
		end
		if strength > 0.02 then
			local now = os.clock()
			if now >= (localPlayer:GetAttribute("PulseShakeEnd") or 0) or strength >= (localPlayer:GetAttribute("PulseShakeAmp") or 0) then
				localPlayer:SetAttribute("PulseShakeStart", now)
				localPlayer:SetAttribute("PulseShakeEnd", now + BURST_TIME + SUSTAIN_TIME + DISSIPATE_TIME)
				localPlayer:SetAttribute("PulseShakeAmp", strength)
			end
		end

		local clone = template:Clone()
		local entry = { clone = clone }

		while #active >= MAX_ACTIVE do
			destroyEntry(active[1])
		end
		table.insert(active, entry)
		Debris:AddItem(clone, BURST_TIME + SUSTAIN_TIME + DISSIPATE_TIME + 5)

		local ok, err = pcall(function()
			local parts, emitters, baseTransparency = {}, {}, {}
			local spinParts = {}
			local sphereSet = {}
			local shockParts = {}

			for _, desc in ipairs(clone:GetDescendants()) do
				if desc:IsA("BasePart") then
					baseTransparency[desc] = desc.Name == "WD" and 1 or desc.Transparency
					desc.Color = color
					desc.CanCollide = false
					desc.CanTouch = false
					desc.CanQuery = false
					desc.Anchored = true
					desc.CastShadow = false
					if desc.Name == "WD" then desc.Transparency = 1 end
					table.insert(parts, desc)

					if PART_SPIN[desc.Name] then
						table.insert(spinParts, { part = desc, spin = PART_SPIN[desc.Name] })
					end
					if SPHERE_NAMES[desc.Name] then
						sphereSet[desc] = true
					end
				elseif desc:IsA("ParticleEmitter") then
					desc.Enabled = true
					desc.Color = ColorSequence.new(color)
					table.insert(emitters, desc)
				elseif desc:IsA("Beam") or desc:IsA("Trail") then
					desc.Color = ColorSequence.new(color)
				elseif desc:IsA("Light") then
					desc.Color = color
				elseif desc:IsA("Fire") then
					desc.Color = color
					desc.SecondaryColor = color
				elseif desc:IsA("Smoke") then
					desc.Color = color
				elseif desc:IsA("Sparkles") then
					desc.SparkleColor = color
				elseif desc:IsA("Decal") then
					desc.Color3 = color
				elseif desc:IsA("SurfaceAppearance") then
					desc.Color = color
				elseif desc:IsA("SpecialMesh") then
					desc.VertexColor = Vector3.new(color.R, color.G, color.B)
				end
			end

			if not clone.PrimaryPart then
				local sw = clone:FindFirstChild("Shockwave", true)
				clone.PrimaryPart = (sw and sw:IsA("BasePart") and sw) or clone:FindFirstChildWhichIsA("BasePart", true)
			end
			if not clone.PrimaryPart then
				warn("[Pulse] template has no parts, using fallback")
				clone:Destroy()
				playFallback(hrp.Position, color, maxSize)
				return
			end

			local light = Instance.new("PointLight")
			light.Color = color
			light.Brightness = 10
			light.Range = 80
			light.Shadows = false
			light.Parent = clone.PrimaryPart

			pcall(clone.ScaleTo, clone, 1)
			local baseDim = getBaseDimension(clone)

			for _, p in ipairs(parts) do
				if p.Name == SHOCK_NAME then
					table.insert(shockParts, { part = p, baseSize = p.Size })
				end
			end

			local lastPosition = hrp.Position
			local function currentPosition()
				if hrp and hrp.Parent then
					lastPosition = hrp.Position
				else
					local newChar = firingPlayer.Parent and firingPlayer.Character
					local newHrp = newChar and newChar:FindFirstChild("HumanoidRootPart")
					if newHrp then hrp = newHrp lastPosition = hrp.Position end
				end
				return lastPosition
			end

			local seed = math.random() * 1000
			local lastTick = os.clock()

			local function setPose(size, shake, spinMult, shockExtra)
				local now = os.clock()
				local dt = math.min(now - lastTick, 0.05)
				lastTick = now

				local scale = math.max(0.01, size / baseDim)
				local jitterScale = 1 + math.noise(now * 8, seed, 1) * 0.03 * shake
				pcall(clone.ScaleTo, clone, scale * jitterScale)

				for _, s in ipairs(shockParts) do
					s.part.Size = s.baseSize * (scale * jitterScale * shockExtra)
				end

				local tiltX = math.noise(now * 6, seed, 2) * 0.05 * shake
				local tiltZ = math.noise(now * 6, seed, 3) * 0.05 * shake
				local offset = Vector3.new(
					math.noise(now * 9, seed, 4) * shake * size * 0.005,
					math.noise(now * 9, seed, 5) * shake * size * 0.005,
					math.noise(now * 9, seed, 6) * shake * size * 0.005
				)
				clone:PivotTo(CFrame.new(currentPosition() + offset) * CFrame.Angles(tiltX, 0, tiltZ))

				for _, s in ipairs(spinParts) do
					local d = s.spin * (spinMult * dt)
					s.part.CFrame = s.part.CFrame * CFrame.Angles(math.rad(d.X), math.rad(d.Y), math.rad(d.Z))
				end
			end

			local function setTransparency(level, sphereLevel)
				for _, p in ipairs(parts) do
					local base = baseTransparency[p] or 0
					local l = sphereSet[p] and sphereLevel or level
					p.Transparency = base + (1 - base) * math.clamp(l, 0, 1)
				end
			end

			local function runPhase(duration, step)
				local t0 = os.clock()
				while clone.Parent do
					local e = os.clock() - t0
					if e >= duration then break end
					step(e / duration)
					RunService.Heartbeat:Wait()
				end
			end

			clone:PivotTo(CFrame.new(lastPosition))
			pcall(clone.ScaleTo, clone, 0.05)
			clone.Parent = workspace

			for _, e in ipairs(emitters) do
				e:Emit(math.max(1, math.floor((e:GetAttribute("EmitCount") or 25) * Quality.Settings().ParticleScale)))
			end

			local startSize = 2
			local peak = maxSize * BURST_OVERSHOOT

			runPhase(BURST_TIME, function(p)
				local size = startSize + (peak - startSize) * easeOutQuart(p)
				setPose(size, 1.2 * (1 - p * 0.4), 1.6 * (1 - p * 0.4), 1 + 0.15 * easeOutQuart(p))
				light.Brightness = 10 - 7 * p
				setTransparency(0, 0)
			end)
			if not clone.Parent then return end

			runPhase(SUSTAIN_TIME, function(p)
				local size = peak + (maxSize - peak) * p
				setPose(size, 1 - p * 0.5, 1.0 - p * 0.3, 1.15 + 0.10 * p)
				light.Brightness = 3 - p
				setTransparency(0, 0.35 * p)
			end)
			if not clone.Parent then return end

			for _, e in ipairs(emitters) do e.Enabled = false end

			runPhase(DISSIPATE_TIME, function(p)
				local grow = maxSize + (maxSize * DISSIPATE_GROWTH - maxSize) * easeOutQuart(p)
				setPose(grow, 0.5 * (1 - p), 0.7 * (1 - p), 1.25 + 0.30 * easeOutQuart(p))
				local level = easeInPow(p)
				local sphereLevel = 0.35 + p * 1.1
				setTransparency(level, sphereLevel)
				for _, e in ipairs(emitters) do
					e.Transparency = NumberSequence.new(level)
				end
				light.Brightness = 2 * (1 - p) ^ 2
			end)
		end)

		if not ok then
			warn("[Pulse] visual failed: " .. tostring(err))
			if clone.Parent then clone:Destroy() end
			playFallback(hrp.Position, color, maxSize)
		end

		destroyEntry(entry)
	end

	pulseFireEvent.OnClientEvent:Connect(function(firingPlayer, color, maxSize)
		task.spawn(runPulse, firingPlayer, color, maxSize)
	end)
end

function EffectsController:Start()
	local framework = script:FindFirstAncestor("Client")
	local cfg = require(framework.Config)
	local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Util"))
	local log = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Logger")).new("Effects")
	Util.spawn(log, "Rain", startRain, cfg.Rain)
	Util.spawn(log, "Pulse", startPulse, cfg.Pulse)
end

return EffectsController
