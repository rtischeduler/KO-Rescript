local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local BeamVFX = {}

local TEXTURES = {
	Smoke = "rbxassetid://4770542473",
	Burn = "rbxassetid://101217028801705",
	Spark = "rbxassetid://117219392616758",
	Shine = "rbxassetid://122607383215131",
	Main = "rbxassetid://18654087326",
	Glow = "rbxassetid://128372145766358",
}

local SMOKE_DIRECTIONS = 10
local SMOKE_SEGMENTS = 3
local SMOKE_REACH = 34
local SMOKE_SPEED = 38
local SMOKE_REFRESH = 0.1
local SMOKE_MOVE_REFRESH = 3
local BURN_LIFETIME = 2
local BURN_SIZE = 6

local MAIN_TEXTURE_LENGTH = 10
local MAIN_TEXTURE_SPEED = 30
local MAIN_BRIGHTNESS_DAY = 0.8
local MAIN_BRIGHTNESS_NIGHT = 1.3
local CONE_WIDEN = 1.7
local HOT_WIDTH_SCALE = 0.4
local HOT_BRIGHTNESS = 8
local GLOW_WIDTH_SCALE = 2
local GLOW_TRANSPARENCY = 0.6
local GLOW_BRIGHTNESS = 1.5
local SHINE_SIZE = 20
local SHINE_START_SIZE = 4
local SHINE_RATE = 14
local SHINE_START_RATE = 10
local SHINE_LIFETIME = 0.9
local SHINE_HOT_SCALE = 0.7
local SPARK_RATE = 40

local addEndShines

local function kaijuNameOf(character)
	local value = character:FindFirstChild("Kaiju")
	if value and value:IsA("StringValue") and value.Value ~= "" then
		return value.Value
	end
	return character:GetAttribute("KaijuName") or character.Name
end

local function isGhidorah(character)
	return string.find(string.lower(kaijuNameOf(character)), "ghidorah", 1, true) ~= nil
end

BeamVFX.IsGhidorah = isGhidorah

local RETRACT_BELOW = 0.95
local CLEAR_BELOW = 0.3

function BeamVFX.NewTracker()
	return {last = nil, retract = false}
end

function BeamVFX.Track(tracker, value)
	local last = tracker.last
	if last then
		local delta = value - last
		if delta < -0.002 then
			tracker.retract = true
		elseif delta > 0.002 then
			tracker.retract = false
		end
	end
	tracker.last = value
	return tracker.retract and value < RETRACT_BELOW
end

local baseSizes = setmetatable({}, {__mode = "k"})
local appliedScale = setmetatable({}, {__mode = "k"})

function BeamVFX.ScaleSize(emitter, k)
	local base = baseSizes[emitter]
	if not base then
		base = emitter.Size
		baseSizes[emitter] = base
	end
	k = math.max(k, 0.01)
	local last = appliedScale[emitter]
	if last and math.abs(last - k) < 0.02 then return end
	appliedScale[emitter] = k
	local points = {}
	for _, kp in ipairs(base.Keypoints) do
		table.insert(points, NumberSequenceKeypoint.new(kp.Time, kp.Value * k, kp.Envelope * k))
	end
	emitter.Size = NumberSequence.new(points)
end

function BeamVFX.ShouldClear(retract, value)
	return (retract and value < CLEAR_BELOW) or value <= 0.05
end

local function nightBrightness()
	local t = Lighting.ClockTime
	if t >= 17.5 or t <= 6.5 then return MAIN_BRIGHTNESS_NIGHT end
	return MAIN_BRIGHTNESS_DAY
end

local function saturation(seq)
	local best = 0
	for _, kp in ipairs(seq.Keypoints) do
		local c = kp.Value
		best = math.max(best, math.max(c.R, c.G, c.B) - math.min(c.R, c.G, c.B))
	end
	return best
end

local function newBeam(a0, a1, parent, name)
	local beam = Instance.new("Beam")
	beam.Name = name
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Segments = 20
	beam.Enabled = true
	beam.Parent = parent
	return beam
end

local function collectGroups(beamStarts, beamNameFilter)
	local groups = {}
	local lookup = {}
	for _, beamStart in ipairs(beamStarts) do
		for _, child in ipairs(beamStart:GetChildren()) do
			if child:IsA("Beam") and child.Attachment1 and string.sub(child.Name, 1, 7) ~= "BeamVFX" and (not beamNameFilter or beamNameFilter[child.Name]) then
				local byStart = lookup[beamStart]
				if not byStart then
					byStart = {}
					lookup[beamStart] = byStart
				end
				local group = byStart[child.Attachment1]
				if not group then
					group = {start = beamStart, finish = child.Attachment1, templates = {}}
					byStart[child.Attachment1] = group
					table.insert(groups, group)
				end
				table.insert(group.templates, child)
			end
		end
	end
	return groups
end

local function addEntry(vfx, beam, base, boost)
	table.insert(vfx.entries, {beam = beam, base = base, boost = boost or 1})
	table.insert(vfx.instances, beam)
end

function BeamVFX.Build(character, beamStarts, beamNameFilter, isServer)
	local vfx = {entries = {}, instances = {}, folders = {}, server = isServer == true, endShines = {}, tracker = BeamVFX.NewTracker(), endCleared = false}
	local ghidorah = isGhidorah(character)
	local brightness = nightBrightness()
	local shined = {}
	for _, group in ipairs(collectGroups(beamStarts, beamNameFilter)) do
		local best = group.templates[1]
		local bestSat = -1
		local maxW0, maxW1 = 0, 0
		for _, tpl in ipairs(group.templates) do
			local sat = saturation(tpl.Color)
			if sat > bestSat then
				bestSat = sat
				best = tpl
			end
			maxW0 = math.max(maxW0, tpl.Width0)
			maxW1 = math.max(maxW1, tpl.Width1)
		end
		if ghidorah then
			maxW0 = maxW0 * 0.5
			maxW1 = maxW1 * 0.5
		else
			maxW1 = maxW1 * CONE_WIDEN
		end
		local beam = newBeam(group.start, group.finish, group.start, "BeamVFXCore")
		beam.Texture = TEXTURES.Main
		beam.TextureMode = Enum.TextureMode.Wrap
		beam.TextureLength = MAIN_TEXTURE_LENGTH
		beam.TextureSpeed = best.TextureSpeed ~= 0 and best.TextureSpeed or MAIN_TEXTURE_SPEED
		beam.Color = best.Color
		beam.Width0 = maxW0
		beam.Width1 = maxW1
		beam.CurveSize0 = best.CurveSize0
		beam.CurveSize1 = best.CurveSize1
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.12, 0.08),
			NumberSequenceKeypoint.new(0.88, 0.08),
			NumberSequenceKeypoint.new(1, 0.3),
		})
		beam.Brightness = brightness
		beam.ZOffset = best.ZOffset
		beam:SetAttribute("BeamVFXServer", vfx.server)
		addEntry(vfx, beam, beam.TextureSpeed, 1)
		local hot = newBeam(group.start, group.finish, group.start, "BeamVFXHot")
		hot.Texture = TEXTURES.Main
		hot.TextureMode = Enum.TextureMode.Wrap
		hot.TextureLength = MAIN_TEXTURE_LENGTH
		hot.TextureSpeed = beam.TextureSpeed
		hot.Color = ColorSequence.new(Color3.new(1, 1, 1))
		hot.Width0 = math.max(maxW0 * HOT_WIDTH_SCALE, 0.3)
		hot.Width1 = math.max(maxW1 * HOT_WIDTH_SCALE, 0.3)
		hot.CurveSize0 = best.CurveSize0
		hot.CurveSize1 = best.CurveSize1
		hot.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(0.15, 0),
			NumberSequenceKeypoint.new(0.85, 0),
			NumberSequenceKeypoint.new(1, 0.2),
		})
		hot.Brightness = HOT_BRIGHTNESS
		hot.ZOffset = best.ZOffset + 1
		hot:SetAttribute("BeamVFXServer", vfx.server)
		addEntry(vfx, hot, hot.TextureSpeed, 1)
		local glow = newBeam(group.start, group.finish, group.start, "BeamVFXGlow")
		glow.Texture = TEXTURES.Glow
		glow.TextureMode = Enum.TextureMode.Stretch
		glow.TextureLength = 1
		glow.TextureSpeed = 0
		glow.Color = best.Color
		glow.Width0 = math.max(maxW0 * GLOW_WIDTH_SCALE, 1)
		glow.Width1 = math.max(maxW1 * GLOW_WIDTH_SCALE, 1)
		glow.CurveSize0 = best.CurveSize0
		glow.CurveSize1 = best.CurveSize1
		glow.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, GLOW_TRANSPARENCY + 0.15),
			NumberSequenceKeypoint.new(0.5, GLOW_TRANSPARENCY),
			NumberSequenceKeypoint.new(1, GLOW_TRANSPARENCY + 0.2),
		})
		glow.Brightness = GLOW_BRIGHTNESS * brightness
		glow.ZOffset = best.ZOffset - 1
		glow:SetAttribute("BeamVFXServer", vfx.server)
		table.insert(vfx.instances, glow)
		if ghidorah and not shined[group.finish] then
			shined[group.finish] = true
			local keys = best.Color.Keypoints
			addEndShines(vfx, group.finish, keys[#keys].Value)
		end
	end
	return vfx
end

function BeamVFX.SetBoost(vfx, boost)
	if not vfx then return end
	for _, entry in ipairs(vfx.entries) do
		local beam = entry.beam
		if beam.Parent then
			local want
			if entry.base ~= 0 then
				want = entry.base * (1 + (boost - 1) * entry.boost)
			else
				want = (boost - 1) * 2 * entry.boost
			end
			if math.abs(beam.TextureSpeed - want) > 0.25 then
				beam.TextureSpeed = want
			end
		end
	end
end

function BeamVFX.Destroy(vfx)
	if not vfx then return end
	local list = vfx.instances
	for _, inst in ipairs(list) do
		if inst:IsA("Beam") or inst:IsA("ParticleEmitter") then
			pcall(function() inst.Enabled = false end)
		end
	end
	task.delay(0.35, function()
		for _, inst in ipairs(list) do
			pcall(function() inst:Destroy() end)
		end
	end)
	vfx.entries = {}
	vfx.instances = {}
	vfx.folders = {}
end

function BeamVFX.ServerPresent(beamStarts)
	for _, beamStart in ipairs(beamStarts) do
		local core = beamStart:FindFirstChild("BeamVFXCore")
		if core and core:GetAttribute("BeamVFXServer") == true then
			return true
		end
	end
	return false
end

function BeamVFX.FindSurface(endPos, dir, params, maxDrop)
	if dir and dir.Magnitude > 0.01 then
		local unit = dir.Unit
		local result = Workspace:Raycast(endPos - unit * 4, unit * 9, params)
		if result then
			return result.Position + result.Normal * 0.15, result.Normal, true
		end
	end
	local result = Workspace:Raycast(endPos + Vector3.new(0, 4, 0), Vector3.new(0, -14, 0), params)
	if result and (result.Position - endPos).Magnitude <= (maxDrop or 7) then
		return result.Position + result.Normal * 0.15, result.Normal, true
	end
	return endPos, Vector3.yAxis, false
end

function BeamVFX.NewStartSmoke(parent, color, name)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = name or "BeamStartSmoke"
	emitter.Texture = TEXTURES.Smoke
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.2), NumberSequenceKeypoint.new(1, 6)})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0.72),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.25, 0.45)
	emitter.Speed = NumberRange.new(24, 40)
	emitter.Drag = 3
	emitter.Shape = Enum.ParticleEmitterShape.Sphere
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-40, 40)
	emitter.LockedToPart = false
	emitter.Rate = 14
	emitter.Enabled = true
	emitter.Parent = parent
	return emitter
end

local function makeSmokeEmitter(color)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "BeamSmoke"
	emitter.Texture = TEXTURES.Smoke
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.05
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 10)})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.6, 0.78),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.3, 0.45)
	emitter.Speed = NumberRange.new(SMOKE_SPEED * 0.9, SMOKE_SPEED * 1.1)
	emitter.Drag = 0
	emitter.SpreadAngle = Vector2.new(9, 9)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-50, 50)
	emitter.LockedToPart = false
	emitter.Rate = 0
	emitter.Enabled = false
	return emitter
end

local function makeSparkEmitter(color)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "BeamSpark"
	emitter.Texture = TEXTURES.Spark
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1):Lerp(color, 0.2)),
		ColorSequenceKeypoint.new(1, color),
	})
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0)})
	emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.15), NumberSequenceKeypoint.new(1, 1)})
	emitter.Lifetime = NumberRange.new(0.3, 0.65)
	emitter.Speed = NumberRange.new(28, 60)
	emitter.SpreadAngle = Vector2.new(75, 75)
	emitter.Acceleration = Vector3.new(0, -45, 0)
	emitter.Drag = 1.5
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-120, 120)
	emitter.Orientation = Enum.ParticleOrientation.FacingCamera
	emitter.LockedToPart = false
	emitter.Rate = 0
	emitter.Enabled = false
	return emitter
end

local function makeShineEmitter(color, size, name, hot)
	size = size or SHINE_SIZE
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = name or "BeamShine"
	emitter.Texture = TEXTURES.Shine
	if hot then
		size = size * SHINE_HOT_SCALE
		emitter.Color = ColorSequence.new(Color3.new(1, 1, 1))
	else
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1):Lerp(color, 0.3)),
			ColorSequenceKeypoint.new(1, color),
		})
	end
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.ZOffset = hot and 3 or 2
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size * 0.7),
		NumberSequenceKeypoint.new(0.4, size),
		NumberSequenceKeypoint.new(1, size * 0.8),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.15, 0),
		NumberSequenceKeypoint.new(0.85, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(SHINE_LIFETIME * 0.9, SHINE_LIFETIME)
	emitter.Speed = NumberRange.new(0, 0)
	emitter.SpreadAngle = Vector2.new(0, 0)
	emitter.Drag = 0
	emitter.Rotation = NumberRange.new(0, 360)
	if hot then
		emitter.RotSpeed = NumberRange.new(-620, -480)
	else
		emitter.RotSpeed = NumberRange.new(420, 560)
	end
	emitter.Orientation = Enum.ParticleOrientation.FacingCamera
	emitter.LockedToPart = true
	emitter.Rate = 0
	emitter.Enabled = false
	return emitter
end

addEndShines = function(vfx, finish, color)
	local shine = makeShineEmitter(color, nil, "BeamEndShine")
	shine.Rate = SHINE_RATE
	shine.Enabled = true
	shine.Parent = finish
	local hot = makeShineEmitter(color, nil, "BeamEndShineHot", true)
	hot.Rate = SHINE_RATE
	hot.Enabled = true
	hot.Parent = finish
	table.insert(vfx.instances, shine)
	table.insert(vfx.instances, hot)
	table.insert(vfx.endShines, shine)
	table.insert(vfx.endShines, hot)
end

function BeamVFX.SetExtent(vfx, extent)
	if not vfx or #vfx.endShines == 0 then return end
	local retract = BeamVFX.Track(vfx.tracker, extent)
	local k = math.clamp(extent, 0, 1)
	k = k * k
	local on = extent > 0.05
	local clear = BeamVFX.ShouldClear(retract, extent)
	for _, emitter in ipairs(vfx.endShines) do
		if emitter.Parent then
			BeamVFX.ScaleSize(emitter, k)
			if emitter.Enabled ~= on then emitter.Enabled = on end
			if clear and not vfx.endCleared then emitter:Clear() end
		end
	end
	vfx.endCleared = clear
end

function BeamVFX.NewStartShine(parent, color, name)
	local emitter = makeShineEmitter(color, SHINE_START_SIZE, name or "BeamStartShine")
	emitter.Rate = SHINE_START_RATE
	emitter.Enabled = true
	emitter.Parent = parent
	return emitter
end

local function makeBurnEmitter()
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "BeamBurn"
	emitter.Texture = TEXTURES.Burn
	emitter.Color = ColorSequence.new(Color3.fromRGB(18, 14, 12))
	emitter.LightEmission = 0
	emitter.LightInfluence = 0
	emitter.ZOffset = 0.5
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, BURN_SIZE), NumberSequenceKeypoint.new(1, BURN_SIZE)})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.05, 0.05),
		NumberSequenceKeypoint.new(0.4, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(BURN_LIFETIME, BURN_LIFETIME)
	emitter.Speed = NumberRange.new(0.05, 0.05)
	emitter.SpreadAngle = Vector2.new(0, 0)
	emitter.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(0, 0)
	emitter.Drag = 0
	emitter.LockedToPart = false
	emitter.Rate = 0
	emitter.Enabled = false
	return emitter
end

local BurnTrail = {}
BurnTrail.__index = BurnTrail

function BeamVFX.NewBurnTrail(parent)
	local self = setmetatable({}, BurnTrail)
	local part = Instance.new("Part")
	part.Name = "BeamBurnAnchor"
	part.Size = Vector3.new(1, 1, 1)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Parent = parent
	self.part = part
	self.burn = makeBurnEmitter()
	self.burn.Parent = part
	self.speed = 0
	self.lastPos = nil
	self.lastTime = nil
	self.rate = -1
	return self
end

function BurnTrail:Stop()
	self.lastPos = nil
	if self.burn then
		if self.rate ~= 0 then
			self.rate = 0
			self.burn.Rate = 0
		end
		if self.burn.Enabled then self.burn.Enabled = false end
	end
end

function BurnTrail:Update(endPos, dir, params, now, active)
	if not active or not self.burn then
		self:Stop()
		return
	end
	local pos, normal, hit = BeamVFX.FindSurface(endPos, dir, params, 3.5)
	if not hit then
		self:Stop()
		return
	end
	if self.lastPos and self.lastTime then
		local speed = (pos - self.lastPos).Magnitude / math.max(now - self.lastTime, 0.01)
		self.speed = self.speed + (speed - self.speed) * 0.4
	end
	self.lastPos = pos
	self.lastTime = now
	self.part.CFrame = CFrame.lookAt(pos, pos + normal) * CFrame.Angles(-math.pi / 2, 0, 0)
	local rate = math.clamp(math.floor(self.speed / 2 + 0.5), 8, 28)
	if rate ~= self.rate then
		self.rate = rate
		self.burn.Rate = rate
	end
	if not self.burn.Enabled then self.burn.Enabled = true end
end

function BurnTrail:Destroy()
	local burn = self.burn
	self.burn = nil
	local part = self.part
	if burn and part and part.Parent then
		pcall(function()
			local holder = Instance.new("Part")
			holder.Name = "BeamBurnHolder"
			holder.Size = Vector3.new(1, 1, 1)
			holder.Transparency = 1
			holder.Anchored = true
			holder.CanCollide = false
			holder.CanTouch = false
			holder.CanQuery = false
			holder.CFrame = part.CFrame
			holder.Parent = Workspace
			burn.Enabled = false
			burn.Rate = 0
			burn.Parent = holder
			Debris:AddItem(holder, BURN_LIFETIME + 0.5)
		end)
	end
	pcall(function() part:Destroy() end)
end

local Impact = {}
Impact.__index = Impact

function BeamVFX.NewImpact(anchor, color, options)
	options = options or {}
	local self = setmetatable({}, Impact)
	self.anchor = anchor
	self.smokeColor = Color3.new(0.82, 0.82, 0.82):Lerp(color, 0.2)
	self.smoke = {}
	self.lastUpdate = 0
	self.lastPos = nil
	self.openness = 1
	self.speed = 0
	self.lastTrack = nil
	self.lastTrackPos = nil
	self.burnRate = -1
	self.intensity = 0
	self.tracker = BeamVFX.NewTracker()
	self.cleared = false
	for i = 1, SMOKE_DIRECTIONS do
		self.smoke[i] = {}
		for s = 1, SMOKE_SEGMENTS do
			local att = Instance.new("Attachment")
			att.Name = "BeamSmokeAttachment"
			att.Parent = anchor
			local emitter = makeSmokeEmitter(self.smokeColor)
			emitter.Parent = att
			self.smoke[i][s] = {att = att, emitter = emitter, active = false}
		end
	end
	self.spark = makeSparkEmitter(color)
	self.spark.Parent = anchor
	if not options.noShine then
		self.shine = makeShineEmitter(color)
		self.shine.Parent = anchor
		self.shineHot = makeShineEmitter(color, nil, "BeamShineHot", true)
		self.shineHot.Parent = anchor
	end
	if options.burn then
		self.burn = makeBurnEmitter()
		self.burn.Parent = anchor
	end
	return self
end

local function slideOf(dir, normal)
	local slide = dir - normal * dir:Dot(normal)
	if slide.Magnitude < 0.05 then return nil end
	return slide.Unit
end

function Impact:Track(pos, now)
	if self.lastTrackPos and self.lastTrack then
		local dt = math.max(now - self.lastTrack, 0.01)
		local speed = (pos - self.lastTrackPos).Magnitude / dt
		self.speed = self.speed + (speed - self.speed) * 0.35
	end
	self.lastTrackPos = pos
	self.lastTrack = now
end

function Impact:Update(pos, normal, params, now, force)
	if not force and self.lastPos and now - self.lastUpdate < SMOKE_REFRESH
		and (pos - self.lastPos).Magnitude < SMOKE_MOVE_REFRESH then
		return
	end
	self.lastUpdate = now
	self.lastPos = pos
	local base = normal:Cross(Vector3.xAxis)
	if base.Magnitude < 0.1 then
		base = normal:Cross(Vector3.zAxis)
	end
	base = base.Unit
	local origin = pos + normal * 1.4
	local openTotal = 0
	for i = 1, SMOKE_DIRECTIONS do
		local angle = (i - 1) / SMOKE_DIRECTIONS * math.pi * 2
		local dir = CFrame.fromAxisAngle(normal, angle):VectorToWorldSpace(base)
		local segPos = origin
		local segDir = (dir * 0.92 + normal * 0.08).Unit
		local remaining = SMOKE_REACH
		local usedTotal = 0
		for s = 1, SMOKE_SEGMENTS do
			local entry = self.smoke[i][s]
			if remaining < 2.5 then
				entry.active = false
			else
				local result = Workspace:Raycast(segPos, segDir * remaining, params)
				local length = remaining
				if result then
					length = math.max(result.Distance - 1, 0.5)
				end
				entry.active = true
				entry.att.WorldCFrame = CFrame.lookAt(segPos, segPos + segDir) * CFrame.Angles(-math.pi / 2, 0, 0)
				local life = math.clamp(length / SMOKE_SPEED, 0.1, 0.55)
				entry.emitter.Lifetime = NumberRange.new(life * 0.85, life)
				usedTotal = usedTotal + length
				remaining = remaining - length
				if result then
					local wall = result.Normal
					local slide = slideOf(segDir, wall)
					local climb = slideOf(normal, wall)
					local nextDir
					if climb and slide then
						nextDir = (climb * 0.72 + slide * 0.28).Unit
					else
						nextDir = climb or slide
					end
					if not nextDir then
						remaining = 0
					else
						segPos = result.Position + wall * 1.3
						segDir = (nextDir + wall * 0.12).Unit
					end
				else
					remaining = 0
				end
			end
		end
		for s = 1, SMOKE_SEGMENTS do
			local entry = self.smoke[i][s]
			if s > 1 and not self.smoke[i][s - 1].active then
				entry.active = false
			end
		end
		openTotal = openTotal + math.min(usedTotal / SMOKE_REACH, 1)
	end
	self.openness = openTotal / SMOKE_DIRECTIONS
	self:SetIntensity(self.intensity, self.surface)
end

function Impact:SetIntensity(intensity, surfaceHit)
	self.intensity = intensity
	self.surface = surfaceHit
	local retract = BeamVFX.Track(self.tracker, intensity)
	local enabled = intensity > 0.05 and not retract
	local smokeRate = enabled and math.floor(8 * intensity + 0.5) or 0
	for i = 1, SMOKE_DIRECTIONS do
		for s = 1, SMOKE_SEGMENTS do
			local entry = self.smoke[i][s]
			local on = enabled and entry.active
			local rate = on and smokeRate or 0
			if entry.emitter.Rate ~= rate then entry.emitter.Rate = rate end
			if entry.emitter.Enabled ~= on then entry.emitter.Enabled = on end
		end
	end
	local sparkRate = enabled and math.floor(SPARK_RATE * intensity + 0.5) or 0
	if self.spark.Rate ~= sparkRate then self.spark.Rate = sparkRate end
	if self.spark.Enabled ~= enabled then self.spark.Enabled = enabled end
	local shineOn = intensity > 0.05
	local shineRate = shineOn and SHINE_RATE or 0
	local scale = math.clamp(intensity, 0, 1)
	scale = scale * scale
	if self.shine then
		BeamVFX.ScaleSize(self.shine, scale)
		BeamVFX.ScaleSize(self.shineHot, scale)
		if self.shine.Rate ~= shineRate then self.shine.Rate = shineRate end
		if self.shine.Enabled ~= shineOn then self.shine.Enabled = shineOn end
		if self.shineHot.Rate ~= shineRate then self.shineHot.Rate = shineRate end
		if self.shineHot.Enabled ~= shineOn then self.shineHot.Enabled = shineOn end
	end
	local clear = BeamVFX.ShouldClear(retract, intensity)
	if clear and not self.cleared then
		pcall(function() self.spark:Clear() end)
		if self.shine then
			pcall(function() self.shine:Clear() end)
			pcall(function() self.shineHot:Clear() end)
		end
		for i = 1, SMOKE_DIRECTIONS do
			for s = 1, SMOKE_SEGMENTS do
				pcall(function() self.smoke[i][s].emitter:Clear() end)
			end
		end
	end
	self.cleared = clear
	if self.burn then
		local burning = enabled and surfaceHit == true
		local rate = 0
		if burning then
			rate = math.clamp(math.floor(self.speed / 2 + 0.5), 10, 30)
		end
		if self.burnRate ~= rate then
			self.burnRate = rate
			self.burn.Rate = rate
		end
		if self.burn.Enabled ~= burning then self.burn.Enabled = burning end
	end
end

function Impact:Destroy()
	for i = 1, SMOKE_DIRECTIONS do
		for s = 1, SMOKE_SEGMENTS do
			pcall(function() self.smoke[i][s].att:Destroy() end)
		end
	end
	pcall(function() self.spark:Destroy() end)
	if self.shine then
		pcall(function() self.shine:Destroy() end)
		pcall(function() self.shineHot:Destroy() end)
	end
	if self.burn then
		local burn = self.burn
		self.burn = nil
		pcall(function()
			local holder = Instance.new("Part")
			holder.Name = "BeamBurnHolder"
			holder.Size = Vector3.new(1, 1, 1)
			holder.Transparency = 1
			holder.Anchored = true
			holder.CanCollide = false
			holder.CanTouch = false
			holder.CanQuery = false
			holder.CFrame = self.anchor.CFrame
			holder.Parent = Workspace
			burn.Enabled = false
			burn.Rate = 0
			burn.Parent = holder
			Debris:AddItem(holder, BURN_LIFETIME + 0.5)
		end)
	end
end

return BeamVFX
