local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local RUMBLE_TIME = 0.8
local COLLAPSE_TIME = 2.6
local DEBRIS_CHUNKS = 9
local FX_DISTANCE = 900
local DEBRIS_GROUP = "CollapseDebris"
local DARK = Color3.new(0, 0, 0)

local SFX_COLLAPSE = "rbxassetid://127181227297856"
local SFX_BUILDING_HITS = { "rbxassetid://138817960173178", "rbxassetid://104781713803672" }
local SFX_FLICKER = "rbxassetid://5948753051"
local SFX_COLLAPSE_VOLUME = 1
local SFX_HIT_VOLUME = 0.8
local SFX_FLICKER_VOLUME = 0.2

local remote = ReplicatedStorage:WaitForChild("BuildingFX")

local function lerp(a, b, t) return a + (b - a) * t end
local function rand(a, b) return a + math.random() * (b - a) end
local function maxAxis(part)
	return math.max(part.Size.X, part.Size.Y, part.Size.Z) / 2
end

local function easeLinear(p) return p end
local function easeInOut(p)
	if p < 0.5 then return 2 * p * p end
	return 1 - (-2 * p + 2) ^ 2 / 2
end
local function easeCollapse(p) return p ^ 1.7 end
local function easeTilt(p) return p ^ 1.6 end

local function nearCamera(position)
	local camera = Workspace.CurrentCamera
	return camera ~= nil and (camera.CFrame.Position - position).Magnitude <= FX_DISTANCE
end

local function playOneShot(parent, soundId, volume, lifetime)
	if not parent or not parent.Parent then return end
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = volume
	s.RollOffMaxDistance = 400
	s.Parent = parent
	s:Play()
	Debris:AddItem(s, lifetime or 8)
end

local function playHitSound(base)
	if not base or not base.Parent then return end
	local template = remote:FindFirstChild("HitSound")
	if template and template:IsA("Sound") then
		local s = template:Clone()
		s.Parent = base
		s:Play()
		Debris:AddItem(s, 5)
	end
	playOneShot(base, SFX_BUILDING_HITS[math.random(#SFX_BUILDING_HITS)], SFX_HIT_VOLUME, 6)
end

local states = setmetatable({}, { __mode = "k" })
local tracked = setmetatable({}, { __mode = "k" })
local active = {}
local heartbeat = nil

local function getState(building)
	if not building or not building.Parent then return nil end
	local existing = states[building]
	if existing then
		if existing.base.Parent then return existing end
		states[building] = nil
	end
	local base = building:FindFirstChild("BuildingBase")
	if not base or not base:IsA("BasePart") then return nil end

	local parts, origCFs = {}, {}
	local minY = math.huge
	for _, d in building:GetDescendants() do
		if d:IsA("BasePart") and not d.Name:lower():find("leftover") then
			table.insert(parts, d)
			table.insert(origCFs, d.CFrame)
			minY = math.min(minY, d.Position.Y - d.Size.Y / 2)
		end
	end
	if #parts == 0 then return nil end

	local basePos = base.Position
	local footW, footD = base.Size.X, base.Size.Z
	local s = {
		building = building,
		base = base,
		parts = parts,
		origCFs = origCFs,
		cframes = table.create(#parts),
		pivot = Vector3.new(basePos.X, minY, basePos.Z),
		footW = footW,
		footD = footD,
		shakeScale = math.clamp(maxAxis(base) / 25, 0.4, 2.5),
		dustScale = math.clamp(math.max(footW, footD) / 8, 3, 14),
		pose = { sink = 0, tx = 0, tz = 0 },
		anim = nil,
		jolt = nil,
		seed = math.random() * 1000,
		epoch = 0,
	}
	states[building] = s
	return s
end

local function apply(s, sx, sy, sz, rx, rz)
	local pose = s.pose
	local rot = CFrame.Angles(pose.tx + rx, 0, pose.tz + rz)
	local offset = CFrame.new(sx, sy - pose.sink, sz) * CFrame.new(s.pivot) * rot * CFrame.new(-s.pivot)
	local cframes, origCFs = s.cframes, s.origCFs
	for i = 1, #s.parts do cframes[i] = offset * origCFs[i] end
	pcall(Workspace.BulkMoveTo, Workspace, s.parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

local function step(s, now)
	local pose = s.pose
	local amp = 0
	local anim = s.anim
	if anim then
		local p = math.clamp((now - anim.t0) / anim.dur, 0, 1)
		local e = anim.ease(p)
		local te = anim.tiltEase(p)
		pose.sink = lerp(anim.from.sink, anim.to.sink, e)
		pose.tx = lerp(anim.from.tx, anim.to.tx, te)
		pose.tz = lerp(anim.from.tz, anim.to.tz, te)
		amp = anim.amp * math.sin(math.pi * p ^ 0.6)
		if p >= 1 then s.anim = nil end
	end
	local jolt = s.jolt
	if jolt then
		local jp = (now - jolt.t0) / jolt.dur
		if jp >= 1 then
			s.jolt = nil
		else
			amp += jolt.amp * (1 - jp) ^ 2
		end
	end
	local sx, sy, sz, rx, rz = 0, 0, 0, 0, 0
	if amp > 0.001 then
		local t = now * 24
		local ts = amp * s.shakeScale
		local seed = s.seed
		sx = math.noise(t, seed, 0.5) * 2 * ts
		sy = math.noise(t, seed, 10.5) * ts
		sz = math.noise(t, seed, 20.5) * 2 * ts
		rx = math.noise(t, seed, 30.5) * 0.012 * amp
		rz = math.noise(t, seed, 40.5) * 0.012 * amp
	end
	apply(s, sx, sy, sz, rx, rz)
	return s.anim ~= nil or s.jolt ~= nil
end

local function onHeartbeat()
	local now = os.clock()
	for s in active do
		if not s.base.Parent or not step(s, now) then
			active[s] = nil
		end
	end
	if next(active) == nil and heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
end

local function activate(s)
	active[s] = true
	if not heartbeat then
		heartbeat = RunService.Heartbeat:Connect(onHeartbeat)
	end
end

local function startAnim(s, sink, tx, tz, dur, amp, ease, tiltEase)
	s.seed = math.random() * 1000
	local pose = s.pose
	s.anim = {
		from = { sink = pose.sink, tx = pose.tx, tz = pose.tz },
		to = { sink = sink, tx = tx, tz = tz },
		t0 = os.clock(), dur = dur, amp = amp,
		ease = ease, tiltEase = tiltEase or ease,
	}
	activate(s)
end

local function addJolt(s, amp, dur)
	local current = s.jolt
	if current and current.amp * (1 - (os.clock() - current.t0) / current.dur) > amp then return end
	s.seed = math.random() * 1000
	s.jolt = { amp = amp, dur = dur, t0 = os.clock() }
	activate(s)
end

local function setPose(s, sink, tx, tz)
	s.anim, s.jolt = nil, nil
	active[s] = nil
	s.pose.sink, s.pose.tx, s.pose.tz = sink, tx, tz
	apply(s, 0, 0, 0, 0, 0)
end

local function dust(s, count, sources)
	if not nearCamera(s.pivot) then return end
	for _ = 1, sources do
		local att = Instance.new("Attachment")
		att.Parent = Workspace.Terrain
		att.WorldPosition = s.pivot + Vector3.new(rand(-s.footW / 2, s.footW / 2) * 0.8, 0.5, rand(-s.footD / 2, s.footD / 2) * 0.8)
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Rate = 0
		e.Lifetime = NumberRange.new(2, 4)
		e.Speed = NumberRange.new(8, 26)
		e.SpreadAngle = Vector2.new(75, 75)
		e.EmissionDirection = Enum.NormalId.Top
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-40, 40)
		e.Drag = 2
		e.Acceleration = Vector3.new(0, 1.5, 0)
		e.Color = ColorSequence.new(Color3.fromRGB(155, 145, 130), Color3.fromRGB(105, 105, 105))
		e.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, s.dustScale * 0.4),
			NumberSequenceKeypoint.new(1, s.dustScale * 1.6),
		})
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.6, 0.75),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Parent = att
		e:Emit(count)
		Debris:AddItem(att, 7)
	end
end

local function throwChunks(s, count)
	if not nearCamera(s.pivot) then return end
	for _ = 1, count do
		local chunk = Instance.new("Part")
		chunk.Name = "CollapseChunk"
		chunk.Size = Vector3.new(rand(0.8, 2.8), rand(0.8, 2.8), rand(0.8, 2.8))
		chunk.Material = Enum.Material.CorrodedMetal
		chunk.Color = s.base.Color
		chunk.CanTouch = false
		chunk.CanQuery = false
		pcall(function() chunk.CollisionGroup = DEBRIS_GROUP end)
		chunk.CFrame = CFrame.new(s.pivot + Vector3.new(rand(-s.footW / 2, s.footW / 2), rand(2, 15), rand(-s.footD / 2, s.footD / 2)))
			* CFrame.Angles(rand(0, 6), rand(0, 6), rand(0, 6))
		chunk.Parent = Workspace
		chunk.AssemblyLinearVelocity = Vector3.new(rand(-1, 1), rand(0.4, 1.2), rand(-1, 1)).Unit * rand(18, 45)
		chunk.AssemblyAngularVelocity = Vector3.new(rand(-8, 8), rand(-8, 8), rand(-8, 8))
		local life = rand(2, 2.8)
		task.delay(life - 1, function()
			if chunk.Parent then TweenService:Create(chunk, TweenInfo.new(1), { Transparency = 1 }):Play() end
		end)
		Debris:AddItem(chunk, life)
	end
end

local flickerToken = setmetatable({}, { __mode = "k" })

local function flickerWindow(window, duration, litColor, material, color)
	flickerToken[window] = (flickerToken[window] or 0) + 1
	local mine = flickerToken[window]
	task.spawn(function()
		local stop = os.clock() + duration
		while flickerToken[window] == mine and window.Parent and os.clock() < stop do
			window.Material = Enum.Material.Neon
			window.Color = math.random() < 0.5 and litColor or DARK
			task.wait(0.03 + math.random() * 0.09)
		end
		if flickerToken[window] ~= mine or not window.Parent then return end
		window.Material, window.Color = material, color
	end)
end

local handlers = {}

handlers.Sound = function(building)
	local base = building and building:FindFirstChild("BuildingBase")
	if base and nearCamera(base.Position) then playHitSound(base) end
end

handlers.Hit = function(building, hp)
	local s = getState(building)
	if not s then return end
	addJolt(s, 1 + (100 - math.max(hp or 0, 0)) / 60, 0.45)
	dust(s, 6, 1)
end

handlers.Half = function(building, fraction, angle, direction)
	local s = getState(building)
	if not s then return end
	startAnim(s, s.base.Size.Y * fraction, angle * math.cos(direction), angle * math.sin(direction), 1.6, 1.8, easeInOut)
	dust(s, 25, 2)
end

handlers.Destroy = function(building, direction, angle, useBaseSound)
	local s = getState(building)
	if not s then return end
	s.epoch += 1
	local epoch = s.epoch

	local sound = s.base:FindFirstChildOfClass("Sound")
	if useBaseSound and sound then
		sound:Play()
	elseif nearCamera(s.pivot) then
		playOneShot(s.base, SFX_COLLAPSE, SFX_COLLAPSE_VOLUME, 12)
	end

	local pose = s.pose
	startAnim(s, pose.sink, pose.tx, pose.tz, RUMBLE_TIME, 2.6, easeLinear)
	dust(s, 20, 2)

	task.delay(RUMBLE_TIME, function()
		if s.epoch ~= epoch or not s.base.Parent then return end
		startAnim(s, s.base.Size.Y, angle * math.cos(direction), angle * math.sin(direction), COLLAPSE_TIME, 3.4, easeCollapse, easeTilt)
		dust(s, 35, 4)
		task.spawn(function()
			local t0 = os.clock()
			while s.epoch == epoch and s.base.Parent and os.clock() - t0 < COLLAPSE_TIME do
				throwChunks(s, 1)
				task.wait(COLLAPSE_TIME / DEBRIS_CHUNKS)
			end
		end)
		task.delay(COLLAPSE_TIME, function()
			if s.epoch ~= epoch or not s.base.Parent then return end
			dust(s, 80, 5)
			addJolt(s, 5, 0.9)
		end)
	end)
end

handlers.Respawn = function(building)
	local s = getState(building)
	if not s then return end
	s.epoch += 1
	setPose(s, 0, 0, 0)
	local sound = s.base:FindFirstChildOfClass("Sound")
	if sound then sound:Stop() end
end

handlers.Flicker = function(building, windows)
	local base = building and building:FindFirstChild("BuildingBase")
	if not base or not nearCamera(base.Position) then return end
	playOneShot(base, SFX_FLICKER, SFX_FLICKER_VOLUME, 4)
	for _, entry in windows do
		local window = entry[1]
		if window and window.Parent then
			flickerWindow(window, entry[2], entry[5], entry[3], entry[4])
		end
	end
end

remote.OnClientEvent:Connect(function(kind, ...)
	local handler = handlers[kind]
	if not handler then return end
	local ok, err = pcall(handler, ...)
	if not ok then warn("[BuildingFX] " .. tostring(kind) .. " failed: " .. tostring(err)) end
end)

local function snapToServerState(building)
	local state = building:GetAttribute("FXState")
	if state ~= "Half" and state ~= "Destroyed" then return end
	if states[building] then return end
	local s = getState(building)
	if not s then return end
	local angle = building:GetAttribute("FXAng") or 0
	local direction = building:GetAttribute("FXDir") or 0
	local fraction = state == "Destroyed" and 1 or (building:GetAttribute("FXFrac") or 0.5)
	setPose(s, s.base.Size.Y * fraction, angle * math.cos(direction), angle * math.sin(direction))
end

local function track(inst)
	if tracked[inst] or not inst:IsA("Model") or not inst.Name:lower():find("building") then return end
	if not inst:FindFirstChild("BuildingBase") then return end
	tracked[inst] = true
	snapToServerState(inst)
end

task.spawn(function()
	local map = Workspace:WaitForChild("Map")
	for _, d in map:GetDescendants() do track(d) end
	map.DescendantAdded:Connect(function(d)
		if d:IsA("Model") then
			task.wait(0.1)
			track(d)
		end
	end)
end)
