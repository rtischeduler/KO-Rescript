local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knockback = {}

local SETTINGS = {
	attack = { speed = 40, lift = 8 },
	beam = { speed = 3, lift = 0 },
}

-- Resolves speed/lift/duration from a base setting plus optional overrides.
-- Any two of (speed, distance, duration) define the motion; the third is derived.
local function resolveMotion(base, overrides)
	base = base or {}
	overrides = overrides or {}
	-- tonumber() coerces string-typed attributes so comparisons never error.
	local speed = tonumber(overrides.speed) or tonumber(base.speed)
	local lift = tonumber(overrides.lift) or tonumber(base.lift) or 0
	local duration = tonumber(overrides.duration) or tonumber(base.duration)
	local distance = tonumber(overrides.distance) or tonumber(base.distance)
	if distance and distance > 0 then
		if duration and duration > 0 then
			if not overrides.speed then
				speed = distance / duration
			end
		elseif speed and speed > 0 then
			duration = distance / speed
		end
	end
	return speed, lift, duration
end
if RunService:IsServer() then
	local remote = ReplicatedStorage:FindFirstChild("KnockbackEvent")
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = "KnockbackEvent"
		remote.Parent = ReplicatedStorage
	end

	function Knockback.push(targetChar, sourceChar, kind, overrides)
		local setting = SETTINGS[kind]
		local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
		local sourceRoot = sourceChar and sourceChar:FindFirstChild("HumanoidRootPart")
		if not setting or not targetRoot or not sourceRoot then return end
		local speed, lift, duration = resolveMotion(setting, overrides)
		if not speed or speed <= 0 then return end
		local flat = Vector3.new(targetRoot.Position.X - sourceRoot.Position.X, 0, targetRoot.Position.Z - sourceRoot.Position.Z)
		if flat.Magnitude < 0.01 then return end
		local vec = flat.Unit * speed + Vector3.new(0, lift, 0)
		local player = Players:GetPlayerFromCharacter(targetChar)
		if player then
			remote:FireClient(player, vec, duration)
		else
			targetRoot.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity + vec
		end
	end

	-- Dashes the attacker forward along their flattened look direction.
	-- Motion is configurable via params and/or attributes on the attacker's character:
	-- TravelSpeed, TravelDistance, TravelDuration (any two of speed/distance/duration define the motion).
	local DEFAULT_TRAVEL = { speed = 50, distance = 14 }
	function Knockback.travel(attackerChar, params)
		local root = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")
		if not root then return end
		params = params or {}
		params.speed = params.speed or tonumber(attackerChar:GetAttribute("TravelSpeed")) or DEFAULT_TRAVEL.speed
		params.distance = params.distance or tonumber(attackerChar:GetAttribute("TravelDistance")) or DEFAULT_TRAVEL.distance
		params.duration = params.duration or tonumber(attackerChar:GetAttribute("TravelDuration"))
		local speed, _, duration = resolveMotion(nil, params)
		if not speed or speed <= 0 or not duration or duration <= 0 then return end
		local look = root.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude < 0.01 then return end
		local vec = flat.Unit * speed
		local player = Players:GetPlayerFromCharacter(attackerChar)
		if player then
			remote:FireClient(player, vec, duration, "travel")
		else
			-- NPC / server fallback: sustained push for the full duration instead of a one-frame velocity add.
			local start = os.clock()
			local connection
			connection = RunService.Heartbeat:Connect(function()
				if os.clock() - start >= duration or not root.Parent then
					connection:Disconnect()
					return
				end
				root.AssemblyLinearVelocity = Vector3.new(vec.X, root.AssemblyLinearVelocity.Y, vec.Z)
			end)
		end
	end
else
	local remote = ReplicatedStorage:WaitForChild("KnockbackEvent")
	local MAX_FLAT_SPEED = 70
	local active = nil
	local mover = nil

	local function getMover(root)
		if mover and mover.Parent == root then
			return mover
		end
		if mover then
			mover:Destroy()
			mover = nil
		end
		local attachment = root:FindFirstChild("RootAttachment") or root:FindFirstChildOfClass("Attachment")
		if not attachment then
			attachment = Instance.new("Attachment")
			attachment.Name = "KnockbackAttachment"
			attachment.Parent = root
		end
		mover = Instance.new("LinearVelocity")
		mover.Name = "KnockbackMover"
		mover.Attachment0 = attachment
		mover.RelativeTo = Enum.ActuatorRelativeTo.World
		mover.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		mover.MaxAxesForce = Vector3.new(math.huge, 0, math.huge)
		mover.Enabled = false
		mover.Parent = root
		return mover
	end

	local function setFlightMoverEnabled(root, enabled)
		-- The character's own flight/swim control rig ("FlyVelocity" LinearVelocity)
		-- overrides any velocity we set while PlatformStand is on. Pause it while
		-- knockback/travel is active so the motion actually applies.
		local fly = root and root:FindFirstChild("FlyVelocity")
		if fly and fly:IsA("LinearVelocity") then
			fly.Enabled = enabled
		end
	end

	local function clearActive()
		active = nil
		if mover then
			mover.Enabled = false
		end
		local player = Players.LocalPlayer
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		setFlightMoverEnabled(root, true)
	end

	remote.OnClientEvent:Connect(function(vec, duration, mode)
		local player = Players.LocalPlayer
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 or typeof(vec) ~= "Vector3" then
			return
		end
		local now = os.clock()
		local flat = Vector3.new(vec.X, 0, vec.Z)
		if mode == "travel" then
			-- Travel mode: constant velocity for the full duration (no decay, no merging).
			if typeof(duration) ~= "number" or duration <= 0 then return end
			active = { vel = flat, untilT = now + duration, duration = duration, travel = true }
			if mover then
				mover.Enabled = false
			end
			return
		end
		duration = (typeof(duration) == "number" and duration > 0) and duration or (flat.Magnitude > 20 and 0.45 or 0.15)
		local carried = Vector3.zero
		if active then
			carried = active.vel * math.clamp((active.untilT - now) / active.duration, 0, 1)
		end
		local total = carried + flat
		if total.Magnitude > MAX_FLAT_SPEED then
			total = total.Unit * MAX_FLAT_SPEED
		end
		active = { vel = total, untilT = now + duration, duration = duration }
		if vec.Y > 0 then
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(v.X, math.max(v.Y, vec.Y), v.Z)
		end
	end)

	-- Clean up active state and any stale mover when the character respawns.
	local localPlayer = Players.LocalPlayer
	if localPlayer then
		localPlayer.CharacterAdded:Connect(function()
			clearActive()
			if mover then
				mover:Destroy()
				mover = nil
			end
		end)
	end

	RunService.Heartbeat:Connect(function()
		if not active then return end
		local player = Players.LocalPlayer
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local now = os.clock()
		if not root or not humanoid or now >= active.untilT then
			clearActive()
			return
		end
		-- Swim/Fly/Glide modes enable PlatformStand: pause the flight control mover
		-- and apply velocity directly to the root so knockback/travel still work.
		if humanoid.PlatformStand then
			setFlightMoverEnabled(root, false)
			local frac = active.travel and 1 or (active.untilT - now) / active.duration
			root.AssemblyLinearVelocity = Vector3.new(active.vel.X * frac, root.AssemblyLinearVelocity.Y, active.vel.Z * frac)
			return
		end
		setFlightMoverEnabled(root, true)
		local frac = active.travel and 1 or (active.untilT - now) / active.duration
		local walk = humanoid.MoveDirection * humanoid.WalkSpeed
		local m = getMover(root)
		m.VectorVelocity = Vector3.new(walk.X, 0, walk.Z) + active.vel * frac
		m.Enabled = true
	end)
end

return Knockback
