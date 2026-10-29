local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knockback = {}

local SETTINGS = {
	attack = { speed = 60, lift = 10 },
	beam = { speed = 6, lift = 0 },
}
if RunService:IsServer() then
	local remote = ReplicatedStorage:FindFirstChild("KnockbackEvent")
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = "KnockbackEvent"
		remote.Parent = ReplicatedStorage
	end

	function Knockback.push(targetChar, sourceChar, kind)
		local setting = SETTINGS[kind]
		local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
		local sourceRoot = sourceChar and sourceChar:FindFirstChild("HumanoidRootPart")
		if not setting or not targetRoot or not sourceRoot then return end
		local flat = Vector3.new(targetRoot.Position.X - sourceRoot.Position.X, 0, targetRoot.Position.Z - sourceRoot.Position.Z)
		if flat.Magnitude < 0.01 then return end
		local vec = flat.Unit * setting.speed + Vector3.new(0, setting.lift, 0)
		local player = Players:GetPlayerFromCharacter(targetChar)
		if player then
			remote:FireClient(player, vec)
		else
			targetRoot.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity + vec
		end
	end
else
	local remote = ReplicatedStorage:WaitForChild("KnockbackEvent")
	local MAX_FLAT_SPEED = 80
	local active = nil
	local mover = nil

	local function getMover(root)
		if mover and mover.Parent == root then
			return mover
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

	local function clearActive()
		active = nil
		if mover then
			mover.Enabled = false
		end
	end

	remote.OnClientEvent:Connect(function(vec)
		local player = Players.LocalPlayer
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 or humanoid.PlatformStand or typeof(vec) ~= "Vector3" then
			return
		end
		local now = os.clock()
		local flat = Vector3.new(vec.X, 0, vec.Z)
		local duration = flat.Magnitude > 20 and 0.35 or 0.15
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

	RunService.Heartbeat:Connect(function()
		if not active then return end
		local player = Players.LocalPlayer
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local now = os.clock()
		if not root or not humanoid or humanoid.PlatformStand or now >= active.untilT then
			clearActive()
			return
		end
		local frac = (active.untilT - now) / active.duration
		local walk = humanoid.MoveDirection * humanoid.WalkSpeed
		local m = getMover(root)
		m.VectorVelocity = Vector3.new(walk.X, 0, walk.Z) + active.vel * frac
		m.Enabled = true
	end)
end

return Knockback
