local EffectsController = { Name = "Effects" }

local function startRain(cfg)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local Workspace = game:GetService("Workspace")

	local rainTemplate = ReplicatedStorage:WaitForChild("Rain")
	local toggleEvent = ReplicatedStorage:WaitForChild("ToggleRain")

	local rainClone = nil
	local renderConn = nil

	local RAIN_OFFSET = Vector3.new(0, cfg.OffsetY, 0)

	local TweenService = game:GetService("TweenService")
	local FADE = 6
	local UserInputService = game:GetService("UserInputService")
	local okQuality, quality = pcall(function()
		return UserSettings().GameSettings.SavedQualityLevel.Value
	end)
	local lowEnd = UserInputService.TouchEnabled or (okQuality and quality > 0 and quality <= 4)
	local rainScale = lowEnd and 0.5 or 1
	local okCfg, HolidayConfigs = pcall(function()
		return require(ReplicatedStorage:WaitForChild("HolidayConfigs", 5))
	end)

	local function follow(clone)
		local conn
		conn = RunService.RenderStepped:Connect(function()
			if not clone.Parent then
				conn:Disconnect()
				return
			end
			local camera = Workspace.CurrentCamera
			if camera then
				clone.CFrame = CFrame.new(camera.CFrame.Position + RAIN_OFFSET)
			end
		end)
		return conn
	end

	local function startRain()
		if rainClone then return end

		local clone = rainTemplate:Clone()
		rainClone = clone
		clone.Parent = Workspace

		local holiday = okCfg and HolidayConfigs.getActive() or nil
		local tint = holiday and holiday.RainColor or nil
		local info = TweenInfo.new(FADE, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		for _, child in clone:GetChildren() do
			if child:IsA("ParticleEmitter") then
				if tint then child.Color = ColorSequence.new(tint) end
				local rate = child.Rate * rainScale
				child.Rate = 0
				child.Enabled = true
				TweenService:Create(child, info, { Rate = rate }):Play()
			end
		end

		local sound = clone:FindFirstChild("Raining")
		if sound then
			local volume = sound.Volume
			sound.Volume = 0
			sound:Play()
			TweenService:Create(sound, info, { Volume = volume }):Play()
		end
		renderConn = follow(clone)
	end

	local function stopRain()
		local old, oldConn = rainClone, renderConn
		rainClone, renderConn = nil, nil
		if not old then return end

		local info = TweenInfo.new(FADE, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		for _, child in old:GetChildren() do
			if child:IsA("ParticleEmitter") then
				TweenService:Create(child, info, { Rate = 0 }):Play()
			end
		end
		local sound = old:FindFirstChild("Raining")
		if sound then
			TweenService:Create(sound, info, { Volume = 0 }):Play()
		end
		task.delay(FADE + 1, function()
			if oldConn then oldConn:Disconnect() end
			old:Destroy()
		end)
	end

	toggleEvent.OnClientEvent:Connect(function(isRaining)
		if isRaining then
			startRain()
		else
			stopRain()
		end
	end)
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

	local function runPulse(firingPlayer, color, maxSize)
		if typeof(color) ~= "Color3" then color = DEFAULT_COLOR end
		if type(maxSize) ~= "number" then maxSize = cfg.DefaultSize end
		maxSize = math.clamp(maxSize, cfg.MinSize, cfg.MaxSize)

		if not firingPlayer or not firingPlayer.Parent then return end
		local character = firingPlayer.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local template = ReplicatedStorage:FindFirstChild("Pulse")
		if not template then return end

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
				end
			end

			if not clone.PrimaryPart then
				local sw = clone:FindFirstChild("Shockwave", true)
				clone.PrimaryPart = (sw and sw:IsA("BasePart") and sw) or clone:FindFirstChildWhichIsA("BasePart", true)
			end
			if not clone.PrimaryPart then
				clone:Destroy()
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
				e:Emit(math.max(1, math.floor(e:GetAttribute("EmitCount") or 25)))
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
