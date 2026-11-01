local WaterFX = { Name = "WaterFX" }

local FOAM = "rbxasset://textures/particles/smoke_main.dds"

local function sizeSequence(a, b)
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, a),
		NumberSequenceKeypoint.new(1, b),
	})
end

local function newFoam(attachment, fx)
	local foam = Instance.new("ParticleEmitter")
	foam.Texture = FOAM
	foam.Rate = 0
	foam.Lifetime = NumberRange.new(fx.WakeLifetime * 0.7, fx.WakeLifetime)
	foam.Speed = NumberRange.new(1.5, 4)
	foam.SpreadAngle = Vector2.new(18, 6)
	foam.EmissionDirection = Enum.NormalId.Front
	foam.Drag = 2
	foam.LightEmission = 0.2
	foam.Rotation = NumberRange.new(-180, 180)
	foam.RotSpeed = NumberRange.new(-30, 30)
	foam.Color = ColorSequence.new(fx.FoamColor)
	foam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.6, 0.75),
		NumberSequenceKeypoint.new(1, 1),
	})
	foam.Size = sizeSequence(1, 2.5)
	foam.Parent = attachment
	return foam
end

local function newSplash(attachment, fx)
	local splash = Instance.new("ParticleEmitter")
	splash.Texture = fx.SplashTexture
	splash.Rate = 0
	splash.Lifetime = NumberRange.new(0.6, 1.1)
	splash.Speed = NumberRange.new(8, 16)
	splash.SpreadAngle = Vector2.new(16, 16)
	splash.EmissionDirection = Enum.NormalId.Front
	splash.Acceleration = Vector3.new(0, -workspace.Gravity * 0.8, 0)
	splash.LightEmission = 0.35
	splash.Rotation = NumberRange.new(-180, 180)
	splash.RotSpeed = NumberRange.new(-60, 60)
	splash.Color = ColorSequence.new(fx.SprayColor)
	splash.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	splash.Size = sizeSequence(0.9, 0.5)
	splash.Parent = attachment
	return splash
end

local function build(folder, fx)
	local part = Instance.new("Part")
	part.Name = "WaterFXEmitter"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.one
	part.Parent = folder

	local rim = {}
	for i = 1, fx.RimPoints do
		local angle = (i - 1) / fx.RimPoints * math.pi * 2
		local foamAttachment = Instance.new("Attachment")
		foamAttachment.Parent = part
		local splashAttachment = Instance.new("Attachment")
		splashAttachment.Parent = part
		rim[i] = {
			dir = Vector3.new(math.cos(angle), 0, math.sin(angle)),
			foamAttachment = foamAttachment,
			splashAttachment = splashAttachment,
			foam = newFoam(foamAttachment, fx),
			splash = newSplash(splashAttachment, fx),
		}
	end

	return part, rim
end

local function placeRim(rim, radius, pitch)
	local tilt = math.rad(pitch)
	for _, point in ipairs(rim) do
		local position = point.dir * radius
		point.foamAttachment.CFrame = CFrame.lookAt(position, position + point.dir)
		local aim = point.dir * math.cos(tilt) + Vector3.yAxis * math.sin(tilt)
		point.splashAttachment.CFrame = CFrame.lookAt(position, position + aim)
	end
end

function WaterFX:Start()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local config = require(script:FindFirstAncestor("Client").Config)
	local fx = config.WaterFX
	local levelOffset = config.Ocean.LevelOffset

	local ocean = workspace:WaitForChild("Ocean", config.Ocean.WaitTimeout)
	if not ocean or not ocean:IsA("BasePart") then
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = "WaterFX"
	folder.Parent = workspace

	local tracked = {}

	local function untrack(player)
		local entry = tracked[player]
		if entry then
			entry.part:Destroy()
			tracked[player] = nil
		end
	end

	local function track(player, character)
		untrack(player)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not root then
			return
		end
		local part, rim = build(folder, fx)
		tracked[player] = {
			root = root,
			part = part,
			rim = rim,
			scale = 0,
			radius = 0,
			wasIn = false,
			nextSplash = 0,
		}
	end

	local function hook(player)
		player.CharacterAdded:Connect(function(character)
			track(player, character)
		end)
		player.CharacterRemoving:Connect(function()
			untrack(player)
		end)
		if player.Character then
			task.spawn(track, player, player.Character)
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		hook(player)
	end
	Players.PlayerAdded:Connect(hook)
	Players.PlayerRemoving:Connect(untrack)

	local function applyScale(entry, scale, radius)
		if math.abs(entry.scale - scale) < 0.25 and math.abs(entry.radius - radius) < 0.25 then
			return
		end
		entry.scale = scale
		entry.radius = radius
		placeRim(entry.rim, radius, fx.SplashPitch)
		local root = math.sqrt(scale)
		for _, point in ipairs(entry.rim) do
			point.foam.Size = sizeSequence(scale * 0.8, scale * 2.4)
			point.foam.Speed = NumberRange.new(1.5 * root, 4 * root)
			point.splash.Size = sizeSequence(scale * 0.9, scale * 0.4)
			point.splash.Speed = NumberRange.new(8 * root, 16 * root)
		end
	end

	local Quality = (function()
		local ok, module = pcall(function()
			return require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GraphicsQuality", 5))
		end)
		if ok then
			return module
		end
		return { Settings = function() return { OceanRate = nil, WaterFx = 1, ParticleScale = 1 } end }
	end)()
	local interval = 1 / fx.UpdateRate
	local elapsed = 0

	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < interval then
			return
		end
		elapsed = 0

		local camera = workspace.CurrentCamera
		if not camera or not ocean.Parent then
			return
		end

		local camPos = camera.CFrame.Position
		local level = ocean.Position.Y + ocean.Size.Y / 2 + levelOffset
		local now = os.clock()
		local fxScale = Quality.Settings().WaterFx

		for player, entry in pairs(tracked) do
			local root = entry.root
			if not root.Parent then
				untrack(player)
			else
				local pos = root.Position
				local halfHeight = root.Size.Y / 2
				local inWater = pos.Y - halfHeight <= level + fx.SurfaceMargin
					and pos.Y > level - fx.MaxDepth
					and (pos - camPos).Magnitude <= fx.MaxDistance

				if inWater then
					local velocity = root.AssemblyLinearVelocity
					local flat = Vector3.new(velocity.X, 0, velocity.Z)
					local speed = flat.Magnitude
					local moveDir = speed > 0.1 and flat.Unit or Vector3.zero
					local scale = math.clamp(math.max(root.Size.X, root.Size.Z) / fx.ReferenceSize, 1, fx.MaxScale)
					local radius = math.clamp(math.max(root.Size.X, root.Size.Z) * fx.RimRadiusFactor, 1, fx.MaxRadius)
					applyScale(entry, scale, radius)
					entry.part.CFrame = CFrame.new(pos.X, level + fx.SurfaceLift, pos.Z)

					local moving = speed > fx.MinSpeed
					local foamRate = moving and math.min(speed * fx.RatePerSpeed, fx.MaxRate) * 2 / fx.RimPoints or 0
					local sprayRate = speed > fx.SprayMinSpeed
						and math.min((speed - fx.SprayMinSpeed) * fx.SprayPerSpeed, fx.SprayMaxRate) * 2 / fx.RimPoints
						or 0

					for _, point in ipairs(entry.rim) do
						local facing = moveDir:Dot(point.dir)
						local foam = fx.IdleFoamRate
						local spray = 0
						if moving then
							if facing < fx.TrailDot then
								foam = foamRate
							elseif facing > fx.BowDot then
								foam = foamRate * 0.5
								spray = sprayRate * facing
							else
								foam = foamRate * 0.4
							end
						end
						point.foam.Rate = foam * fxScale
						point.splash.Rate = spray * fxScale
					end

					if not entry.wasIn and now >= entry.nextSplash then
						local count = math.clamp(-velocity.Y * fx.SplashPerSpeed * scale ^ 0.5, fx.SplashMinCount, fx.SplashMaxCount)
						if fxScale > 0 then
							local perPoint = math.max(1, math.floor(count * fxScale / fx.RimPoints + 0.5))
							for _, point in ipairs(entry.rim) do
								point.splash:Emit(perPoint)
								point.foam:Emit(math.max(1, math.floor(perPoint * 0.5)))
							end
						end
						entry.nextSplash = now + fx.SplashCooldown
					end
				else
					for _, point in ipairs(entry.rim) do
						point.foam.Rate = 0
						point.splash.Rate = 0
					end
				end

				entry.wasIn = inWater
			end
		end
	end)
end

return WaterFX