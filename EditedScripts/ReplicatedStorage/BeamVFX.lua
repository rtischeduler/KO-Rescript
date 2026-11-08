local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local BeamVFX = {}

local TEXTURES = {
	Smoke = "rbxassetid://4770542473",
	Burn = "rbxassetid://101217028801705",
	Spark = "rbxassetid://90163371828645",
	GlowA = "rbxassetid://6091474388",
	GlowB = "rbxassetid://18654084346",
	Ghidorah = "rbxassetid://7151778302",
}

local SMOKE_DIRECTIONS = 10
local SMOKE_SEGMENTS = 3
local SMOKE_REACH = 34
local SMOKE_SPEED = 38
local SMOKE_REFRESH = 0.1
local SMOKE_MOVE_REFRESH = 3
local BURN_LIFETIME = 2
local BURN_SIZE = 9

local GHIDORAH_LAYERS = {
	{scale = 0.42, speed = 48, length = 12, transparency = 0.3, curve = 0, z = 0, boost = 0.5},
	{scale = 0.27, speed = 80, length = 8, transparency = 0.12, curve = 1.6, z = 1, boost = 0.5},
	{scale = 0.13, speed = 125, length = 5, transparency = 0, curve = -1.3, z = 2, boost = 0.5},
}

local GLOW_LAYERS = {
	{texture = TEXTURES.GlowA, scale = 0.85, speed = 14, length = 14, transparency = 0.32, z = -1, brightness = 2.2},
	{texture = TEXTURES.GlowB, scale = 1, speed = -20, length = 20, transparency = 0.45, z = -2, brightness = 1.8},
}

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

local function nightBrightness()
	local t = Lighting.ClockTime
	if t >= 17.5 or t <= 6.5 then return 2 end
	return 1
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
	for _, beamStart in ipairs(beamStarts) do
		for _, child in ipairs(beamStart:GetChildren()) do
			if child:IsA("Beam") and child.Attachment1 and string.sub(child.Name, 1, 7) ~= "BeamVFX" and (not beamNameFilter or beamNameFilter[child.Name]) then
				local key = child.Attachment1
				local group = groups[key]
				if not group then
					group = {start = beamStart, finish = child.Attachment1, templates = {}}
					groups[key] = group
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
	local vfx = {entries = {}, instances = {}, folders = {}, server = isServer == true}
	local ghidorah = isGhidorah(character)
	local brightness = nightBrightness()
	for _, group in pairs(collectGroups(beamStarts, beamNameFilter)) do
		local colorSeq = group.templates[1].Color
		local bestSat = -1
		local maxW0, maxW1 = 0, 0
		for _, tpl in ipairs(group.templates) do
			local sat = saturation(tpl.Color)
			if sat > bestSat then
				bestSat = sat
				colorSeq = tpl.Color
			end
			maxW0 = math.max(maxW0, tpl.Width0)
			maxW1 = math.max(maxW1, tpl.Width1)
		end
		if ghidorah then
			maxW0 = maxW0 * 0.5
			maxW1 = maxW1 * 0.5
		end
		local folder = Instance.new("Folder")
		folder.Name = "BeamVFX"
		folder.Parent = group.start
		table.insert(vfx.folders, folder)
		table.insert(vfx.instances, folder)
		local function tag(beam)
			beam:SetAttribute("BeamVFXServer", vfx.server)
		end
		for _, layer in ipairs(GLOW_LAYERS) do
			local glow = newBeam(group.start, group.finish, folder, "BeamGlow")
			glow.Texture = layer.texture
			glow.TextureMode = Enum.TextureMode.Wrap
			glow.TextureLength = layer.length
			glow.TextureSpeed = layer.speed
			glow.Color = colorSeq
			glow.Width0 = math.max(maxW0 * layer.scale, 1)
			glow.Width1 = math.max(maxW1 * layer.scale, 1)
			glow.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, layer.transparency + 0.1),
				NumberSequenceKeypoint.new(0.5, layer.transparency),
				NumberSequenceKeypoint.new(1, layer.transparency + 0.15),
			})
			glow.Brightness = layer.brightness * brightness
			glow.ZOffset = layer.z
			tag(glow)
			addEntry(vfx, glow, layer.speed, 0.25)
		end
		local first = true
		local function place(beam)
			if first then
				beam.Name = "BeamVFXCore"
				beam.Parent = group.start
				first = false
			else
				beam.Name = "BeamVFXLayer"
			end
			tag(beam)
		end
		if ghidorah then
			for _, layer in ipairs(GHIDORAH_LAYERS) do
				local beam = newBeam(group.start, group.finish, folder, "BeamVFXLayer")
				beam.Texture = TEXTURES.Ghidorah
				beam.TextureMode = Enum.TextureMode.Wrap
				beam.TextureLength = layer.length
				beam.TextureSpeed = layer.speed
				beam.Color = colorSeq
				beam.Width0 = math.max(maxW0 * layer.scale, 0.5)
				beam.Width1 = math.max(maxW1 * layer.scale, 0.7)
				beam.CurveSize0 = layer.curve
				beam.CurveSize1 = -layer.curve
				beam.Transparency = NumberSequence.new(layer.transparency)
				beam.Brightness = brightness * (1 + layer.z * 0.4)
				beam.ZOffset = layer.z
				place(beam)
				addEntry(vfx, beam, layer.speed, layer.boost)
			end
		else
			for _, tpl in ipairs(group.templates) do
				local beam = newBeam(group.start, group.finish, folder, "BeamVFXLayer")
				beam.Texture = tpl.Texture
				beam.TextureMode = tpl.TextureMode
				beam.TextureLength = tpl.TextureLength
				beam.TextureSpeed = tpl.TextureSpeed
				beam.Color = tpl.Color
				beam.Width0 = tpl.Width0
				beam.Width1 = tpl.Width1
				beam.CurveSize0 = tpl.CurveSize0
				beam.CurveSize1 = tpl.CurveSize1
				beam.Transparency = NumberSequence.new(0)
				beam.Brightness = brightness
				beam.ZOffset = tpl.ZOffset
				place(beam)
				addEntry(vfx, beam, tpl.TextureSpeed, 1)
			end
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
		if inst:IsA("Beam") then
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

function BeamVFX.FindSurface(endPos, dir, params)
	if dir and dir.Magnitude > 0.01 then
		local unit = dir.Unit
		local result = Workspace:Raycast(endPos - unit * 4, unit * 9, params)
		if result then
			return result.Position + result.Normal * 0.15, result.Normal, true
		end
	end
	local result = Workspace:Raycast(endPos + Vector3.new(0, 4, 0), Vector3.new(0, -14, 0), params)
	if result and (result.Position - endPos).Magnitude <= 7 then
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
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1):Lerp(color, 0.25)),
		ColorSequenceKeypoint.new(1, color),
	})
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.1), NumberSequenceKeypoint.new(1, 0)})
	emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1)})
	emitter.Lifetime = NumberRange.new(0.25, 0.6)
	emitter.Speed = NumberRange.new(20, 55)
	emitter.SpreadAngle = Vector2.new(60, 60)
	emitter.Acceleration = Vector3.new(0, -60, 0)
	emitter.Drag = 1
	emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
	emitter.LockedToPart = false
	emitter.Rate = 0
	emitter.Enabled = false
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
	local enabled = intensity > 0.05
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
	local sparkRate = enabled and math.floor(34 * intensity + 0.5) or 0
	if self.spark.Rate ~= sparkRate then self.spark.Rate = sparkRate end
	if self.spark.Enabled ~= enabled then self.spark.Enabled = enabled end
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
