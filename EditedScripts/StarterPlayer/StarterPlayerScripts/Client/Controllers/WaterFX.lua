local WaterFX = { Name = "WaterFX" }

local FOAM = "rbxasset://textures/particles/smoke_main.dds"
local SPRAY = "rbxasset://textures/particles/sparkles_main.dds"

local function sizeSequence(a, b)
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, a),
		NumberSequenceKeypoint.new(1, b),
	})
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

	local attachment = Instance.new("Attachment")
	attachment.Parent = part

	local wake = Instance.new("ParticleEmitter")
	wake.Texture = FOAM
	wake.Rate = 0
	wake.Lifetime = NumberRange.new(fx.WakeLifetime * 0.7, fx.WakeLifetime)
	wake.Speed = NumberRange.new(0.5, 2)
	wake.SpreadAngle = Vector2.new(180, 180)
	wake.Drag = 3
	wake.LightEmission = 0.3
	wake.Color = ColorSequence.new(fx.FoamColor)
	wake.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	wake.Size = sizeSequence(1, 3)
	wake.Parent = attachment

	local spray = Instance.new("ParticleEmitter")
	spray.Texture = SPRAY
	spray.Rate = 0
	spray.Lifetime = NumberRange.new(0.5, 0.9)
	spray.Speed = NumberRange.new(8, 16)
	spray.SpreadAngle = Vector2.new(35, 35)
	spray.EmissionDirection = Enum.NormalId.Top
	spray.Acceleration = Vector3.new(0, -workspace.Gravity * 0.6, 0)
	spray.LightEmission = 0.5
	spray.Color = ColorSequence.new(fx.SprayColor)
	spray.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	spray.Size = sizeSequence(0.6, 0.2)
	spray.Parent = attachment

	return part, wake, spray
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
		local part, wake, spray = build(folder, fx)
		tracked[player] = {
			root = root,
			part = part,
			wake = wake,
			spray = spray,
			scale = 0,
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

	local function applyScale(entry, scale)
		if math.abs(entry.scale - scale) < 0.25 then
			return
		end
		entry.scale = scale
		entry.wake.Size = sizeSequence(scale, scale * 3)
		entry.spray.Size = sizeSequence(scale * 0.6, scale * 0.2)
		entry.spray.Speed = NumberRange.new(8 * scale ^ 0.5, 16 * scale ^ 0.5)
	end

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
					local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
					local scale = math.clamp(math.max(root.Size.X, root.Size.Z) / fx.ReferenceSize, 1, fx.MaxScale)
					applyScale(entry, scale)
					entry.part.CFrame = CFrame.new(pos.X, level + fx.SurfaceLift, pos.Z)

					entry.wake.Rate = speed > fx.MinSpeed and math.min(speed * fx.RatePerSpeed, fx.MaxRate) or 0
					entry.spray.Rate = speed > fx.SprayMinSpeed
							and math.min((speed - fx.SprayMinSpeed) * fx.SprayPerSpeed, fx.SprayMaxRate)
						or 0

					if not entry.wasIn and now >= entry.nextSplash then
						local count = math.clamp(-velocity.Y * fx.SplashPerSpeed * scale ^ 0.5, fx.SplashMinCount, fx.SplashMaxCount)
						entry.spray:Emit(math.floor(count))
						entry.wake:Emit(math.floor(count * 0.5))
						entry.nextSplash = now + fx.SplashCooldown
					end
				else
					entry.wake.Rate = 0
					entry.spray.Rate = 0
				end

				entry.wasIn = inWater
			end
		end
	end)
end

return WaterFX
