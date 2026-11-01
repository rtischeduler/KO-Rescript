local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local BeamClientFX = {}
BeamClientFX.__index = BeamClientFX

local localPlayer = Players.LocalPlayer
local SMOKE_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local SMOKE_DIRECTIONS = 8
local SMOKE_REACH = 32
local NUM_GLOW_LIGHTS = 8
local SHIFTLOCK_RAISE = 8
local SHIFTLOCK_MIN_FORWARD = 8
local TEMPLATE_TIMEOUT = 1.5

local function scaleSequence(seq, k)
	local points = {}
	for _, kp in ipairs(seq.Keypoints) do
		table.insert(points, NumberSequenceKeypoint.new(kp.Time, kp.Value * k, kp.Envelope * k))
	end
	return NumberSequence.new(points)
end

local function makeFallbackEmitter(color)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0)})
	emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
	return emitter
end

local function makeFxEmitter(source, kind, power)
	power = power or 1
	local emitter = source:Clone()
	for _, child in ipairs(emitter:GetChildren()) do
		child:Destroy()
	end
	emitter.Enabled = false
	emitter.Rate = 0
	emitter.Acceleration = Vector3.new(0, 0, 0)
	emitter.VelocityInheritance = 0
	emitter.RotSpeed = NumberRange.new(0, 0)
	emitter.Rotation = NumberRange.new(0, 0)
	emitter.LockedToPart = false
	if kind == "ring" then
		emitter.Shape = Enum.ParticleEmitterShape.Disc
		emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.SpreadAngle = Vector2.new(0, 0)
		emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
		emitter.Speed = NumberRange.new(32 * power, 48 * power)
		emitter.Lifetime = NumberRange.new(0.4, 0.65)
		emitter.Drag = 0
		emitter.Size = scaleSequence(source.Size, 1.4 * power)
	else
		emitter.Shape = Enum.ParticleEmitterShape.Sphere
		emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Orientation = Enum.ParticleOrientation.FacingCamera
		emitter.Speed = NumberRange.new(5 * power, 12 * power)
		emitter.Lifetime = NumberRange.new(0.25, 0.45)
		emitter.Drag = 2
		emitter.Size = scaleSequence(source.Size, 2.2 * power)
	end
	return emitter
end

local function makeSmokeEmitter(color)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = SMOKE_TEXTURE
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.05
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(1, 9)})
	emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1)})
	emitter.Lifetime = NumberRange.new(0.25, 0.45)
	emitter.Speed = NumberRange.new(35, 50)
	emitter.Drag = 4
	emitter.SpreadAngle = Vector2.new(18, 18)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-60, 60)
	emitter.LockedToPart = false
	emitter.Rate = 0
	emitter.Enabled = false
	return emitter
end

local function makeStartSmokeEmitter(color)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "LocalBeamStartSmoke"
	emitter.Texture = SMOKE_TEXTURE
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 5)})
	emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.78), NumberSequenceKeypoint.new(1, 1)})
	emitter.Lifetime = NumberRange.new(0.2, 0.35)
	emitter.Speed = NumberRange.new(28, 44)
	emitter.Drag = 3
	emitter.Shape = Enum.ParticleEmitterShape.Sphere
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-40, 40)
	emitter.LockedToPart = false
	emitter.Rate = 12
	emitter.Enabled = true
	return emitter
end

local function evalColorSequence(seq, t)
	local keypoints = seq.Keypoints
	if not keypoints or #keypoints == 0 then return Color3.new(1, 1, 1) end
	if t <= keypoints[1].Time then return keypoints[1].Value end
	if t >= keypoints[#keypoints].Time then return keypoints[#keypoints].Value end
	for i = 1, #keypoints - 1 do
		local kp0 = keypoints[i]
		local kp1 = keypoints[i + 1]
		if t >= kp0.Time and t <= kp1.Time then
			return kp0.Value:Lerp(kp1.Value, (t - kp0.Time) / (kp1.Time - kp0.Time))
		end
	end
	return keypoints[#keypoints].Value
end

local function clampTipToWalls(startPos, tip, character)
	local direction = tip - startPos
	local distance = direction.Magnitude
	if distance < 1 then return tip end
	local unit = direction.Unit
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local excluded = {character}
	local origin = startPos
	local remaining = distance
	for _ = 1, 12 do
		params.FilterDescendantsInstances = excluded
		local result = Workspace:Raycast(origin, unit * remaining, params)
		if not result then return tip end
		local inst = result.Instance
		local model = inst:FindFirstAncestorOfClass("Model")
		local isCharacter = model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
		local skip = isCharacter or result.Material == Enum.Material.Water or inst.Transparency >= 0.95 or not inst.CanCollide
		if not skip then
			return result.Position - unit * 0.5
		end
		remaining = remaining - (result.Position - origin).Magnitude
		if remaining <= 0.1 then return tip end
		origin = result.Position
		table.insert(excluded, inst)
	end
	return tip
end

function BeamClientFX.ShapeTip(character, startPos, aim, shiftLock)
	local target = aim
	if shiftLock then
		target = target + Vector3.new(0, SHIFTLOCK_RAISE, 0)
	end
	return clampTipToWalls(startPos, target, character)
end

function BeamClientFX.EnforceForward(hrp, startPos, tip, shiftLock)
	if not shiftLock or not hrp then return tip end
	local look = hrp.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude <= 0.01 then return tip end
	flat = flat.Unit
	local d = tip - startPos
	local f = d:Dot(flat)
	if f < SHIFTLOCK_MIN_FORWARD then
		return startPos + d + flat * (SHIFTLOCK_MIN_FORWARD - f)
	end
	return tip
end

local function adoptServerImpact(self, inst)
	if inst.Name ~= "BeamImpact" or not inst:IsA("Folder") then return end
	local function check()
		if inst:GetAttribute("OwnerUserId") == localPlayer.UserId then
			self.serverImpact = inst
			return true
		end
		return false
	end
	if check() then return end
	local connection
	connection = inst:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		if check() then
			connection:Disconnect()
		end
	end)
	table.insert(self.connections, connection)
end

local function hideServerCopy(inst)
	if inst:IsA("ParticleEmitter") and inst.Name == "BeamStartSmoke" then
		inst.Enabled = false
	elseif inst:IsA("PointLight") and inst.Name == "GlowLight" then
		inst.Enabled = false
	end
end

function BeamClientFX.new(character)
	local self = setmetatable({}, BeamClientFX)
	self.character = character
	self.hrp = character:FindFirstChild("HumanoidRootPart")
	self.connections = {}
	self.iteration = 0
	self.startTime = os.clock()
	self.built = false
	self.fxGroup = {}
	self.smokeGroup = {}
	self.glow = {}
	self.startSmoke = {}
	self.surfaceOffset = nil
	self.surfaceNormal = Vector3.yAxis
	self.serverImpact = nil

	self.beamStarts = {}
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Attachment") and descendant.Name == "BeamStart" then
			table.insert(self.beamStarts, descendant)
		end
	end
	self.primaryStart = self.beamStarts[1]

	local colorSeq = nil
	for _, beamStart in ipairs(self.beamStarts) do
		for _, child in ipairs(beamStart:GetChildren()) do
			if child:IsA("Beam") then
				colorSeq = child.Color
				break
			end
		end
		if colorSeq then break end
	end
	self.colorSeq = colorSeq
	local hasColor = colorSeq ~= nil and #colorSeq.Keypoints > 0
	self.fallbackColor = hasColor and colorSeq.Keypoints[1].Value or Color3.new(1, 1, 1)
	self.impactColor = hasColor and evalColorSequence(colorSeq, 1) or self.fallbackColor
	self.smokeColor = Color3.new(0.82, 0.82, 0.82):Lerp(self.impactColor, 0.2)

	self.folder = Instance.new("Folder")
	self.folder.Name = "BeamClientFX"
	self.folder.Parent = Workspace

	self.anchor = Instance.new("Part")
	self.anchor.Name = "ImpactAnchor"
	self.anchor.Size = Vector3.new(1, 1, 1)
	self.anchor.Transparency = 1
	self.anchor.Anchored = true
	self.anchor.CanCollide = false
	self.anchor.CanTouch = false
	self.anchor.CanQuery = false
	self.anchor.Parent = self.folder

	self.light = Instance.new("PointLight")
	self.light.Color = self.impactColor
	self.light.Range = 24
	self.light.Brightness = 0
	self.light.Parent = self.anchor

	for i = 1, SMOKE_DIRECTIONS do
		local att = Instance.new("Attachment")
		att.Parent = self.anchor
		local smoke = makeSmokeEmitter(self.smokeColor)
		smoke.Parent = att
		self.smokeGroup[i] = {att = att, emitter = smoke}
	end

	self.params = RaycastParams.new()
	self.params.FilterType = Enum.RaycastFilterType.Exclude

	for _, beamStart in ipairs(self.beamStarts) do
		local smoke = makeStartSmokeEmitter(self.smokeColor)
		smoke.Parent = beamStart
		table.insert(self.startSmoke, smoke)
	end

	if self.hrp and self.primaryStart then
		for i = 1, NUM_GLOW_LIGHTS do
			local att = Instance.new("Attachment")
			att.Name = "LocalBeamGlow" .. i
			att.Parent = self.hrp
			local light = Instance.new("PointLight")
			light.Name = "LocalGlowLight"
			if hasColor then
				light.Color = evalColorSequence(colorSeq, i / (NUM_GLOW_LIGHTS + 1))
			else
				light.Color = self.fallbackColor
			end
			light.Range = 32
			light.Brightness = 0
			light.Parent = att
			table.insert(self.glow, {att = att, light = light})
		end
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		hideServerCopy(descendant)
	end
	table.insert(self.connections, character.DescendantAdded:Connect(hideServerCopy))

	for _, child in ipairs(Workspace:GetChildren()) do
		adoptServerImpact(self, child)
	end
	table.insert(self.connections, Workspace.ChildAdded:Connect(function(child)
		adoptServerImpact(self, child)
	end))

	return self
end

function BeamClientFX:_buildFx(sources)
	for _, entry in ipairs(self.fxGroup) do
		entry.emitter:Destroy()
	end
	self.fxGroup = {}
	for _, source in ipairs(sources) do
		local ring = makeFxEmitter(source, "ring", 1)
		ring.Parent = self.anchor
		table.insert(self.fxGroup, {emitter = ring, rate = 55})
		local core = makeFxEmitter(source, "core", 1)
		core.Parent = self.anchor
		table.insert(self.fxGroup, {emitter = core, rate = 22})
	end
end

function BeamClientFX:_syncTemplates(endsHolder, now)
	if self.built then return end
	local sources = {}
	if endsHolder then
		for _, child in ipairs(endsHolder:GetChildren()) do
			if child:IsA("Attachment") and child.Name == "BeamEnd" then
				for _, emitter in ipairs(child:GetChildren()) do
					if emitter:IsA("ParticleEmitter") and #sources < 4 then
						table.insert(sources, emitter)
					end
				end
			end
		end
	end
	if #sources == 0 then
		if now - self.startTime < TEMPLATE_TIMEOUT then return end
		sources = {makeFallbackEmitter(self.impactColor)}
	end
	self:_buildFx(sources)
	self.built = true
end

function BeamClientFX:_setIntensity(intensity)
	local enabled = intensity > 0.05
	for _, entry in ipairs(self.fxGroup) do
		local rate = enabled and math.floor(entry.rate * intensity + 0.5) or 0
		if entry.emitter.Rate ~= rate then entry.emitter.Rate = rate end
		if entry.emitter.Enabled ~= enabled then entry.emitter.Enabled = enabled end
	end
	for _, entry in ipairs(self.smokeGroup) do
		local rate = enabled and math.floor(9 * intensity + 0.5) or 0
		if entry.emitter.Rate ~= rate then entry.emitter.Rate = rate end
		if entry.emitter.Enabled ~= enabled then entry.emitter.Enabled = enabled end
	end
end

function BeamClientFX:_updateSmoke(impactPos, normal)
	local base = normal:Cross(Vector3.xAxis)
	if base.Magnitude < 0.1 then
		base = normal:Cross(Vector3.zAxis)
	end
	base = base.Unit
	local origin = impactPos + normal * 2
	for i, entry in ipairs(self.smokeGroup) do
		local angle = (i - 1) / SMOKE_DIRECTIONS * math.pi * 2
		local dir = CFrame.fromAxisAngle(normal, angle):VectorToWorldSpace(base)
		local result = Workspace:Raycast(origin, dir * SMOKE_REACH, self.params)
		local free = SMOKE_REACH
		local emitDir = (dir * 0.85 + normal * 0.15).Unit
		if result then
			free = math.max(result.Distance - 1.5, 0)
			local slide = dir - result.Normal * dir:Dot(result.Normal)
			emitDir = (normal * 0.8 + slide * 0.2 + result.Normal * 0.2).Unit
		end
		entry.att.WorldCFrame = CFrame.lookAt(origin, origin + emitDir) * CFrame.Angles(-math.pi / 2, 0, 0)
		local life = math.clamp(free / 50, 0.15, 0.5)
		entry.emitter.Lifetime = NumberRange.new(life * 0.8, life)
	end
end

function BeamClientFX:_updateImpact(endPos, extent, endsHolder)
	if self.iteration % 2 == 0 or not self.surfaceOffset then
		local filter = {self.character, self.folder}
		if endsHolder then
			table.insert(filter, endsHolder)
		end
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.Character then
				table.insert(filter, plr.Character)
			end
		end
		self.params.FilterDescendantsInstances = filter
		local result = Workspace:Raycast(endPos + Vector3.new(0, 4, 0), Vector3.new(0, -14, 0), self.params)
		if result and (result.Position - endPos).Magnitude <= 7 then
			self.surfaceOffset = result.Position + result.Normal * 0.15 - endPos
			self.surfaceNormal = result.Normal
		else
			self.surfaceOffset = Vector3.zero
			self.surfaceNormal = Vector3.yAxis
		end
		self:_updateSmoke(endPos + self.surfaceOffset, self.surfaceNormal)
	end
	local impactPos = endPos + self.surfaceOffset
	self.anchor.CFrame = CFrame.lookAt(impactPos, impactPos + self.surfaceNormal) * CFrame.Angles(-math.pi / 2, 0, 0)
	self.light.Color = self.impactColor
	self.light.Brightness = 1.5 * extent
	self:_setIntensity(extent)
end

function BeamClientFX:_updateGlow(endPos, extent)
	local startAtt = self.primaryStart
	if not startAtt or not startAtt.Parent or #self.glow == 0 then return end
	local startPos = startAtt.WorldPosition
	local range = math.clamp((endPos - startPos).Magnitude / (NUM_GLOW_LIGHTS + 1) * 1.4, 20, 60)
	for i, entry in ipairs(self.glow) do
		entry.att.WorldPosition = startPos:Lerp(endPos, i / (NUM_GLOW_LIGHTS + 1))
		entry.light.Brightness = 0.9 * extent
		entry.light.Range = range
	end
end

function BeamClientFX:_suppressServer()
	local folder = self.serverImpact
	if not folder then return end
	if not folder.Parent then
		self.serverImpact = nil
		return
	end
	local clash = folder:GetAttribute("FxMode") == "clash"
	for _, descendant in ipairs(folder:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			if not clash and descendant.Enabled then
				descendant.Enabled = false
			end
		elseif descendant:IsA("PointLight") then
			if descendant.Enabled ~= clash then
				descendant.Enabled = clash
			end
		end
	end
end

function BeamClientFX:Step(endPos, extent, active, endsHolder)
	self.iteration += 1
	self:_syncTemplates(endsHolder, os.clock())
	self:_suppressServer()
	self:_updateGlow(endPos, extent)
	if active and self.built then
		self:_updateImpact(endPos, extent, endsHolder)
	else
		self:_setIntensity(0)
		self.light.Brightness = 0
	end
end

function BeamClientFX:Destroy()
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end
	self.connections = {}
	for _, smoke in ipairs(self.startSmoke) do
		pcall(function() smoke:Destroy() end)
	end
	for _, entry in ipairs(self.glow) do
		pcall(function() entry.att:Destroy() end)
	end
	if self.folder then
		pcall(function() self.folder:Destroy() end)
	end
	self.startSmoke = {}
	self.glow = {}
	self.fxGroup = {}
	self.smokeGroup = {}
	self.serverImpact = nil
end

return BeamClientFX
