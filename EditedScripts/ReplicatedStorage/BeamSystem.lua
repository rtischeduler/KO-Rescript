local BeamSystem = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local BeamVFX = require(ReplicatedStorage:WaitForChild("BeamVFX"))
local playerAims = {}
local playerShiftLock = {}
local activeBeams = {}
local beamGenerations = {}
local beamGenerationCounter = 0
local beamStartedSignal = nil
local beamEndedSignal = nil
local INTRO_TIME = 0.4
local OUTRO_TIME = 0.35
local AIM_FOLLOW_RATE = 22
local CLASH_FOLLOW_RATE = 6
local CLASH_TRANSITION_TIME = 0.7
local OVERPOWER_TIME = 0.8
local OVERPOWER_DAMAGE = 50
local BEAM_SLOW_FACTOR = 0.7
local BEAM_SLOW_LINGER = 0.35
local BEAM_COUNTER_ENABLED = false
local function easeOutCubic(t)
	return 1 - (1 - t) ^ 3
end
local function easeInOutQuad(t)
	if t < 0.5 then return 2 * t * t end
	return 1 - (-2 * t + 2) ^ 2 / 2
end
local function scaleSequence(seq, k)
	local points = {}
	for _, kp in ipairs(seq.Keypoints) do
		table.insert(points, NumberSequenceKeypoint.new(kp.Time, kp.Value * k, kp.Envelope * k))
	end
	return NumberSequence.new(points)
end
local function collectTemplateEmitters(beamEnds)
	local list = {}
	for _, beamEnd in ipairs(beamEnds) do
		for _, child in ipairs(beamEnd:GetChildren()) do
			if child:IsA("ParticleEmitter") and #list < 4 and string.sub(child.Name, 1, 12) ~= "BeamEndShine" then
				table.insert(list, child)
			end
		end
	end
	return list
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
	local emitter = source:Clone() or makeFallbackEmitter(Color3.new(1, 1, 1))
	for _, child in ipairs(emitter:GetChildren()) do child:Destroy() end
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
local function spawnClashExplosion(position, sourcesA, sourcesB, colorA, colorB)
	local folder = Instance.new("Folder")
	folder.Name = "BeamClashExplosion"
	folder.Parent = Workspace
	Debris:AddItem(folder, 3)
	local anchor = Instance.new("Part")
	anchor.Name = "ExplosionAnchor"
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = folder
	local ringAtts = {}
	for _, rot in ipairs({CFrame.new(), CFrame.Angles(0, 0, math.pi / 2), CFrame.Angles(math.pi / 2, 0, 0)}) do
		local att = Instance.new("Attachment")
		att.CFrame = rot
		att.Parent = anchor
		table.insert(ringAtts, att)
	end
	local sources = {}
	for i = 1, math.min(#sourcesA, 3) do table.insert(sources, sourcesA[i]) end
	for i = 1, math.min(#sourcesB, 3) do table.insert(sources, sourcesB[i]) end
	if #sources == 0 then
		table.insert(sources, makeFallbackEmitter(colorA))
		table.insert(sources, makeFallbackEmitter(colorB))
	end
	local bursts = {}
	for _, source in ipairs(sources) do
		for _, att in ipairs(ringAtts) do
			local ring = makeFxEmitter(source, "ring", 1.6)
			ring.Lifetime = NumberRange.new(0.5, 0.9)
			ring.Parent = att
			table.insert(bursts, {emitter = ring, rate = 260})
		end
		local core = makeFxEmitter(source, "core", 2.4)
		core.Parent = anchor
		table.insert(bursts, {emitter = core, rate = 140})
	end
	local light = Instance.new("PointLight")
	light.Color = colorA:Lerp(colorB, 0.5)
	light.Range = 45
	light.Brightness = 6
	light.Parent = anchor
	for _, burst in ipairs(bursts) do
		burst.emitter.Rate = burst.rate
		burst.emitter.Enabled = true
	end
	TweenService:Create(light, TweenInfo.new(0.7), {Brightness = 0}):Play()
	task.delay(0.14, function()
		for _, burst in ipairs(bursts) do
			if burst.emitter.Parent then
				burst.emitter.Enabled = false
			end
		end
	end)
end
local slowedHumanoids = {}
local slowConnection = nil
local function releaseBeamSlow(humanoid)
	local data = slowedHumanoids[humanoid]
	if not data then return end
	slowedHumanoids[humanoid] = nil
	if humanoid.Parent then
		local current = humanoid.WalkSpeed
		local trueBase = humanoid:GetAttribute("BeamSlowBase")
		humanoid:SetAttribute("BeamSlowFactor", nil)
		humanoid:SetAttribute("BeamSlowBase", nil)
		if math.abs(current - data.applied) < 0.05 then
			humanoid.WalkSpeed = data.base
		elseif humanoid:GetAttribute("Slowed") then
			humanoid.WalkSpeed = current / data.factor
		elseif trueBase then
			humanoid.WalkSpeed = trueBase
		end
	end
end
local function ensureSlowLoop()
	if slowConnection then return end
	slowConnection = game:GetService("RunService").Heartbeat:Connect(function()
		local now = os.clock()
		local any = false
		for humanoid, data in pairs(slowedHumanoids) do
			if not humanoid.Parent or humanoid.Health <= 0 or now >= data.expires then
				releaseBeamSlow(humanoid)
			else
				any = true
			end
		end
		if not any and slowConnection then
			slowConnection:Disconnect()
			slowConnection = nil
		end
	end)
end
function BeamSystem.ApplyBeamSlow(humanoid)
	if not humanoid or not humanoid.Parent or humanoid.Health <= 0 then return end
	local data = slowedHumanoids[humanoid]
	if data then
		data.expires = os.clock() + BEAM_SLOW_LINGER
		return
	end
	local base = humanoid.WalkSpeed
	local applied = base * BEAM_SLOW_FACTOR
	slowedHumanoids[humanoid] = {base = base, applied = applied, factor = BEAM_SLOW_FACTOR, expires = os.clock() + BEAM_SLOW_LINGER}
	humanoid:SetAttribute("BeamSlowFactor", BEAM_SLOW_FACTOR)
	humanoid.WalkSpeed = applied
	ensureSlowLoop()
end
function BeamSystem.SetComm(comm)
	beamStartedSignal = comm.BeamStarted
	beamEndedSignal = comm.BeamEnded
end
Players.PlayerRemoving:Connect(function(player)
	if activeBeams[player] then
		pcall(BeamSystem.ForceCleanup, player)
	end
	activeBeams[player] = nil
	beamGenerations[player] = nil
	playerAims[player] = nil
	playerShiftLock[player] = nil
end)
local function cleanupStaleBeam(player)
	local gen = beamGenerations[player]
	activeBeams[player] = nil
	beamGenerations[player] = nil
	playerAims[player] = nil
	playerShiftLock[player] = nil
	if beamEndedSignal and player.Parent then
		beamEndedSignal:Fire(player, gen)
	end
end
local function findBeamAttachments(morphModel, beamNameFilter)
	local beamStarts = {}
	local beamEnds = {}
	local matchedEnds = nil
	if beamNameFilter then matchedEnds = {} end
	for _, descendant in ipairs(morphModel:GetDescendants()) do
		if descendant:IsA("Attachment") and descendant.Name == "BeamStart" then
			local hasMatch = not beamNameFilter
			if beamNameFilter then
				for _, child in ipairs(descendant:GetChildren()) do
					if child:IsA("Beam") and beamNameFilter[child.Name] then
						hasMatch = true
						break
					end
				end
			end
			if hasMatch then
				table.insert(beamStarts, descendant)
				if matchedEnds then
					for _, child in ipairs(descendant:GetChildren()) do
						if child:IsA("Beam") and beamNameFilter[child.Name] and child.Attachment1 then
							matchedEnds[child.Attachment1] = true
						end
					end
				end
			end
		end
	end
	for _, descendant in ipairs(morphModel:GetDescendants()) do
		if descendant:IsA("Attachment") and descendant.Name == "BeamEnd" then
			if not matchedEnds or matchedEnds[descendant] then
				table.insert(beamEnds, descendant)
			end
		end
	end
	return beamStarts, beamEnds
end
local function beamBrightness()
	local t = game:GetService("Lighting").ClockTime
	if t >= 17.5 or t <= 6.5 then return 4 end
	return 1
end
local function enableBeams(beamStarts, enabled, beamNameFilter)
	for _, beamStart in ipairs(beamStarts) do
		for _, child in ipairs(beamStart:GetChildren()) do
			if child:IsA("Beam") then
				child.Enabled = false
			elseif child:IsA("Light") then
				child.Enabled = enabled
			end
		end
	end
end
local function enableParticles(beamEnds, enabled)
	for _, beamEnd in ipairs(beamEnds) do
		for _, child in ipairs(beamEnd:GetChildren()) do
			if child:IsA("ParticleEmitter") then
				child.Enabled = enabled
				if not enabled then
					child:Clear()
				end
			elseif child:IsA("Light") then
				child.Enabled = enabled
			end
		end
	end
end
function BeamSystem.ForceCleanup(player)
	local data = activeBeams[player]
	if not data then return end
	if data.beamEndOriginals then
		for beamEnd, original in pairs(data.beamEndOriginals) do
			if beamEnd and beamEnd.Parent then
				for _, child in ipairs(beamEnd:GetChildren()) do
					if child:IsA("ParticleEmitter") then
						child.Enabled = false
						child:Clear()
					elseif child:IsA("Light") then
						child.Enabled = false
					end
				end
				if original.parent and original.parent.Parent then
					beamEnd.CFrame = original.cframe
					beamEnd.Parent = original.parent
				else
					beamEnd.Parent = nil
				end
				beamEnd:SetAttribute("BeamEndOffset", nil)
			end
		end
	end
	BeamVFX.Destroy(data.vfx)
	if data.impactFx then
		pcall(function() data.impactFx:Destroy() end)
		data.impactFx = nil
	end
	if data.burnTrails then
		for _, bt in ipairs(data.burnTrails) do
			pcall(function() bt.trail:Destroy() end)
		end
		data.burnTrails = nil
	end
	if data.impactFolder and data.impactFolder.Parent then
		pcall(function() data.impactFolder:Destroy() end)
	end
	if data.hitbox and data.hitbox.Parent then
		pcall(function() data.hitbox:Destroy() end)
	end
	if data.sideHitboxes then
		for _, side in ipairs(data.sideHitboxes) do
			if side.hitbox and side.hitbox.Parent then
				pcall(function() side.hitbox:Destroy() end)
			end
		end
	end
	if data.character and data.character.Parent then
		local beamStarts, beamEnds = findBeamAttachments(data.character)
		pcall(function()
			if #beamStarts > 0 then enableBeams(beamStarts, false, nil) end
			if #beamEnds > 0 then enableParticles(beamEnds, false) end
		end)
	end
	cleanupStaleBeam(player)
end
local function createDPSScript(hitbox, player, character, duration, damageStat)
	local dpsTemplate = ReplicatedStorage:FindFirstChild("DPSTemplate")
	if not dpsTemplate then
		warn("[BeamSystem] DPSTemplate not found in ReplicatedStorage!")
		return nil
	end
	local dpsScript = dpsTemplate:Clone()
	dpsScript.Name = "DPS"
	dpsScript.Enabled = false
	dpsScript:SetAttribute("Attacker", player.Name)
	dpsScript:SetAttribute("BeamDuration", duration)
	local beamDamage = 0
	local stats = character and character:FindFirstChild("Stats")
	if stats then
		local dmgValue = stats:FindFirstChild(damageStat or "DMG2") or stats:FindFirstChild("DMG2")
		if dmgValue then
			beamDamage = dmgValue.Value
		end
	end
	dpsScript:SetAttribute("BeamDamage", beamDamage)
	dpsScript.Parent = hitbox
	return dpsScript
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
			local alpha = (t - kp0.Time) / (kp1.Time - kp0.Time)
			return kp0.Value:Lerp(kp1.Value, alpha)
		end
	end
	return keypoints[#keypoints].Value
end
local function getHeadPosition(character)
	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head.Position
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	return hrp and hrp.Position or nil
end
local SHIFTLOCK_RAISE = 8

local function clampTipToWalls(startPos, tip, character)
	local direction = tip - startPos
	local distance = direction.Magnitude
	if distance < 1 then return tip end
	local unit = direction.Unit
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local excluded = { character }
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

function BeamSystem.ActivateBeam(config)
	local character = config.character
	local player = config.player
	local initialTargetPosition = config.initialTargetPosition
	local duration = config.duration or 6
	local beamNames = config.beamNames
	local beamNameFilter = nil
	if beamNames then
		beamNameFilter = {}
		for _, name in ipairs(beamNames) do
			beamNameFilter[name] = true
		end
	end
	if not character or not player then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local ownerHumanoid = character:FindFirstChildOfClass("Humanoid")
	if ownerHumanoid and ownerHumanoid.Health <= 0 then return end
	if activeBeams[player] then
		local prevData = activeBeams[player]
		local prevChar = prevData and prevData.character
		local prevHum = prevChar and prevChar:FindFirstChildOfClass("Humanoid")
		if prevChar and prevChar.Parent and prevChar:FindFirstChild("HumanoidRootPart")
			and (not prevHum or prevHum.Health > 0) then
			return
		end
		cleanupStaleBeam(player)
	end
	beamGenerationCounter = beamGenerationCounter + 1
	local myGeneration = beamGenerationCounter
	beamGenerations[player] = myGeneration
	activeBeams[player] = {character = character, hitbox = nil, dpsScript = nil, player = player, clashRequestedBy = nil, sideHitboxes = {}}
	local ancestryConn
	ancestryConn = character.AncestryChanged:Connect(function(_, parent)
		if not parent and activeBeams[player] and activeBeams[player].character == character then
			BeamSystem.ForceCleanup(player)
		end
	end)


	task.spawn(function()
		task.wait(duration + 2)
		if activeBeams[player] and activeBeams[player].character == character then
			BeamSystem.ForceCleanup(player)
		end
	end)
	local beamStarts, beamEnds = findBeamAttachments(character, beamNameFilter)
	local primaryBeamStart = beamStarts[1]
	local hitbox = Instance.new("Part")
	hitbox.Name = "BeamHitbox"
	hitbox.Size = Vector3.new(6, 6, 6)
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CanTouch = false
	hitbox.CanQuery = false
	hitbox.Transparency = 1
	hitbox.Material = Enum.Material.Neon
	hitbox.Color = Color3.fromRGB(255, 255, 255)
	hitbox:SetAttribute("Attacker", player.Name)
	hitbox:SetAttribute("BeamMain", true)
	hitbox.Parent = Workspace
	local dpsScript = createDPSScript(hitbox, player, character, duration, config.damageStat)
	activeBeams[player].hitbox = hitbox
	activeBeams[player].dpsScript = dpsScript
	local beamHitDebounce = {}
	local beamEndOriginals = {}
	local beamEndSpacing = 8
	local beamEndCleanupTemplate = ServerStorage:FindFirstChild("BeamEndCleanup")
	for _, beamEnd in ipairs(beamEnds) do
		local originalParent = beamEnd.Parent
		beamEndOriginals[beamEnd] = {
			parent = originalParent,
			cframe = beamEnd.CFrame
		}
		local origParentOV = Instance.new("ObjectValue")
		origParentOV.Name = "BeamOriginalParent"
		origParentOV.Value = originalParent
		origParentOV.Parent = beamEnd
		beamEnd:SetAttribute("BeamDuration", duration)
		if beamEndCleanupTemplate then
			local cleanupClone = beamEndCleanupTemplate:Clone()
			cleanupClone.Parent = beamEnd
		end
		beamEnd.Parent = hitbox
		local offset = Vector3.new(0, 0, 0)
		if originalParent then
			local parentName = originalParent.Name
			if parentName == "LHead" then
				offset = Vector3.new(-beamEndSpacing, 0, 0)
			elseif parentName == "RHead" or parentName == "RUmouth" then
				offset = Vector3.new(beamEndSpacing, 0, 0)
			end
		end
		beamEnd:SetAttribute("BeamEndOffset", offset)
		beamEnd.CFrame = CFrame.new(offset)
	end
	activeBeams[player].beamEndOriginals = beamEndOriginals
	local sideHitboxes = {}
	local NUM_SIDE_HITBOXES = 5
	for _, beamEnd in ipairs(beamEnds) do
		local offset = beamEnd:GetAttribute("BeamEndOffset")
		if offset and offset ~= Vector3.new(0, 0, 0) then
			for i = 1, NUM_SIDE_HITBOXES do
				local t = i / NUM_SIDE_HITBOXES
				local sideHitbox = Instance.new("Part")
				sideHitbox.Name = "BeamHitbox"
				sideHitbox.Size = Vector3.new(6, 6, 6)
				sideHitbox.Anchored = true
				sideHitbox.CanCollide = false
				sideHitbox.CanTouch = false
				sideHitbox.CanQuery = false
				sideHitbox.Transparency = 1
				sideHitbox.Material = Enum.Material.Neon
				sideHitbox.Color = Color3.fromRGB(255, 255, 255)
				sideHitbox:SetAttribute("Attacker", player.Name)
				sideHitbox.Parent = Workspace
				local sideDps = nil 
				table.insert(sideHitboxes, {hitbox = sideHitbox, dps = sideDps, offset = offset, t = t})
			end
		end
	end
	activeBeams[player].sideHitboxes = sideHitboxes
	local glowAttachments = {}
	local NUM_GLOW_LIGHTS = 8
	local success, err = pcall(function()
		if #beamStarts > 0 then
			enableBeams(beamStarts, true, beamNameFilter)
		end
		if #beamEnds > 0 then
			enableParticles(beamEnds, true)
		end
		local beamColorSeq = nil
		for _, beamStart in ipairs(beamStarts) do
			for _, child in ipairs(beamStart:GetChildren()) do
				if child:IsA("Beam") and child.Color then
					if not beamNameFilter or beamNameFilter[child.Name] then
						beamColorSeq = child.Color
						break
					end
				end
			end
			if beamColorSeq then break end
		end
		local fallbackColor = Color3.fromRGB(255, 255, 255)
		if beamColorSeq and #beamColorSeq.Keypoints > 0 then
			fallbackColor = beamColorSeq.Keypoints[1].Value
		end
		if primaryBeamStart then
			for i = 1, NUM_GLOW_LIGHTS do
				local att = Instance.new("Attachment")
				att.Name = "BeamGlowLight" .. i
				att.Parent = hrp
				local light = Instance.new("PointLight")
				light.Name = "GlowLight"
				if beamColorSeq then
					local t = i / (NUM_GLOW_LIGHTS + 1)
					light.Color = evalColorSequence(beamColorSeq, t)
				else
					light.Color = fallbackColor
				end
				light.Range = 32
			light.Brightness = 0.3
				light.Enabled = true
				light.Parent = att
				table.insert(glowAttachments, att)
			end
		end
		if beamStartedSignal then
			beamStartedSignal:Fire(player, myGeneration)
		end
		local currentTarget = initialTargetPosition
		if not currentTarget then
			currentTarget = primaryBeamStart.WorldPosition + primaryBeamStart.WorldCFrame.LookVector * 1000
		end
		playerAims[player] = currentTarget
		local beamIteration = 0
		local function orientHitbox(charPos, targetPos, placePos)
			placePos = placePos or targetPos
			local flatDir = Vector3.new(targetPos.X - charPos.X, 0, targetPos.Z - charPos.Z)
			if flatDir.Magnitude < 0.01 then
				return CFrame.new(placePos)
			end
			local lookCF = CFrame.lookAt(Vector3.new(charPos.X, 0, charPos.Z), Vector3.new(targetPos.X, 0, targetPos.Z))
			local rotation = lookCF - lookCF.Position
			return CFrame.new(placePos) * rotation
		end
		local function positionSideHitboxes(headPos, mainHitboxCF, sides, extent)
			local rotation = mainHitboxCF - mainHitboxCF.Position
			for _, side in ipairs(sides) do
				local endSidePos = (mainHitboxCF * CFrame.new(side.offset * extent)).Position
				local pos = headPos:Lerp(endSidePos, side.t)
				side.hitbox.CFrame = CFrame.new(pos) * rotation
			end
		end
		local beamEndOffsets = {}
		for _, beamEnd in ipairs(beamEnds) do
			local offset = beamEnd:GetAttribute("BeamEndOffset")
			if offset and offset ~= Vector3.new(0, 0, 0) then
				table.insert(beamEndOffsets, {att = beamEnd, offset = offset})
			end
		end
		local impactColor = fallbackColor
		if beamColorSeq and #beamColorSeq.Keypoints > 0 then
			impactColor = evalColorSequence(beamColorSeq, 1)
		end
		local impactFolder = Instance.new("Folder")
		impactFolder.Name = "BeamImpact"
		impactFolder:SetAttribute("OwnerUserId", player.UserId)
		impactFolder:SetAttribute("FxMode", "normal")
		impactFolder.Parent = Workspace
		activeBeams[player].impactFolder = impactFolder
		activeBeams[player].impactColor = impactColor
		local templateEmitters = collectTemplateEmitters(beamEnds)
		activeBeams[player].templateEmitters = templateEmitters
		local ownSources = templateEmitters
		if #ownSources == 0 then
			ownSources = {makeFallbackEmitter(impactColor)}
		end
		local vfx = BeamVFX.Build(character, beamStarts, beamNameFilter, true)
		activeBeams[player].vfx = vfx
		local smokeColor = Color3.new(0.82, 0.82, 0.82):Lerp(impactColor, 0.2)
		local startSmoke = {}
		for _, beamStart in ipairs(beamStarts) do
			table.insert(startSmoke, BeamVFX.NewStartSmoke(beamStart, smokeColor))
			table.insert(startSmoke, BeamVFX.NewStartShine(beamStart, impactColor))
		end
		impactFolder.Destroying:Connect(function()
			for _, smoke in ipairs(startSmoke) do
				pcall(function() smoke:Destroy() end)
			end
		end)
		local texBoost = 1
		local lastEndPos = nil
		local lastTexTime = tick()
		local impactAnchor = Instance.new("Part")
		impactAnchor.Name = "ImpactAnchor"
		impactAnchor.Size = Vector3.new(1, 1, 1)
		impactAnchor.Transparency = 1
		impactAnchor.Anchored = true
		impactAnchor.CanCollide = false
		impactAnchor.CanTouch = false
		impactAnchor.CanQuery = false
		impactAnchor.Parent = impactFolder
		local impactLight = Instance.new("PointLight")
		impactLight.Color = impactColor
		impactLight.Range = 24
		impactLight.Brightness = 0
		impactLight.Parent = impactAnchor
		local fxGroup = {}
		local fxKey = nil
		local function clearFx()
			for _, entry in ipairs(fxGroup) do
				entry.emitter:Destroy()
			end
			fxGroup = {}
			fxKey = nil
		end
		local function buildFx(key, sources)
			clearFx()
			fxKey = key
			impactFolder:SetAttribute("FxMode", string.sub(key, 1, 5) == "clash" and "clash" or "normal")
			for _, source in ipairs(sources) do
				local ring = makeFxEmitter(source, "ring", 1)
				ring.Parent = impactAnchor
				table.insert(fxGroup, {emitter = ring, rate = 55})
				local core = makeFxEmitter(source, "core", 1)
				core.Parent = impactAnchor
				table.insert(fxGroup, {emitter = core, rate = 22})
			end
		end
		local impactFx = BeamVFX.NewImpact(impactAnchor, impactColor, {burn = false, noShine = BeamVFX.IsGhidorah(character)})
		activeBeams[player].impactFx = impactFx
		local burnTrails = {}
		for _, endAtt in ipairs(beamEnds) do
			table.insert(burnTrails, {att = endAtt, trail = BeamVFX.NewBurnTrail(impactFolder)})
		end
		if #burnTrails == 0 then
			table.insert(burnTrails, {trail = BeamVFX.NewBurnTrail(impactFolder)})
		end
		activeBeams[player].burnTrails = burnTrails
		local smokeOpenness = 1
		local templateSpreadBase = {}
		local function setFxIntensity(intensity, surfaceHit)
			local enabled = intensity > 0.05
			for _, entry in ipairs(fxGroup) do
				local rate = enabled and math.floor(entry.rate * intensity + 0.5) or 0
				if entry.emitter.Rate ~= rate then entry.emitter.Rate = rate end
				if entry.emitter.Enabled ~= enabled then entry.emitter.Enabled = enabled end
			end
			impactFx:SetIntensity(intensity, surfaceHit)
		end
		local impactSurfaceOffset, impactSurfaceNormal = nil, Vector3.yAxis
		local impactFilterBuilt = false
		local impactSurfaceHit = false
		local cachedClampTip, cachedClampAim = nil, Vector3.zero
		local impactParams = RaycastParams.new()
		impactParams.FilterType = Enum.RaycastFilterType.Exclude
		local function updateSmoke(impactPos, normal, now, force)
			impactFx:Update(impactPos, normal, impactParams, now, force)
			smokeOpenness = impactFx.openness
			for _, source in ipairs(templateEmitters) do
				local baseSpread = templateSpreadBase[source]
				if not baseSpread then
					baseSpread = source.SpreadAngle
					templateSpreadBase[source] = baseSpread
				end
				local extra = 35 + 30 * smokeOpenness
				source.SpreadAngle = Vector2.new(math.min(baseSpread.X + extra, 180), math.min(baseSpread.Y + extra, 180))
			end
		end
		local function updateImpact(endPos, extent, now, clashInfo, startPos)
			if clashInfo and not clashInfo.lead then
				setFxIntensity(0, false)
				impactLight.Brightness = 0
				return
			end
			local key = "normal"
			local sources = ownSources
			if clashInfo then
				key = "clash" .. tostring(clashInfo.partnerData)
				sources = {}
				for _, src in ipairs(ownSources) do table.insert(sources, src) end
				local partnerSources = clashInfo.partnerSources
				if partnerSources and #partnerSources > 0 then
					for _, src in ipairs(partnerSources) do table.insert(sources, src) end
				else
					table.insert(sources, makeFallbackEmitter(clashInfo.partnerColor or impactColor))
				end
			end
			if key ~= fxKey then
				buildFx(key, sources)
			end
			if clashInfo then
				local axis = clashInfo.axis or Vector3.zAxis
				impactAnchor.CFrame = CFrame.lookAt(endPos, endPos + axis) * CFrame.Angles(-math.pi / 2, 0, 0)
				local mix = (math.sin(now * 9) + 1) / 2
				impactLight.Color = impactColor:Lerp(clashInfo.partnerColor or impactColor, mix)
				impactLight.Brightness = 3 * extent
				if beamIteration % 3 == 0 then updateSmoke(endPos, Vector3.yAxis, now, false) end
				setFxIntensity(extent * 1.4, false)
			else
				if beamIteration % 3 == 0 or not impactSurfaceOffset then
					if beamIteration % 15 == 0 or not impactFilterBuilt then
						impactFilterBuilt = true
						local filter = {character, impactFolder, hitbox}
						for _, plr in ipairs(Players:GetPlayers()) do
							if plr.Character then table.insert(filter, plr.Character) end
						end
						impactParams.FilterDescendantsInstances = filter
					end
					local surfacePos, surfaceNormal, surfaceHit = BeamVFX.FindSurface(endPos, startPos and (endPos - startPos) or nil, impactParams)
					impactSurfaceOffset = surfacePos - endPos
					impactSurfaceNormal = surfaceNormal
					impactSurfaceHit = surfaceHit
					updateSmoke(surfacePos, surfaceNormal, now, false)
				end
				local impactPos = endPos + impactSurfaceOffset
				impactAnchor.CFrame = CFrame.lookAt(impactPos, impactPos + impactSurfaceNormal) * CFrame.Angles(-math.pi / 2, 0, 0)
				local impactScale = 1
				if startPos then
					impactScale = math.clamp((endPos - startPos).Magnitude / 50, 0.12, 1)
				end
				impactLight.Color = impactColor
				impactLight.Brightness = 1.5 * extent * impactScale
				impactFx:Track(impactPos, now)
				setFxIntensity(extent, impactSurfaceHit)
			end
		end
		local startTime = tick()
		local currentClashPartner = nil
		local function isFacing(hrp, targetPos)
			local dir = targetPos - hrp.Position
			local horizDir = Vector3.new(dir.X, 0, dir.Z)
			if horizDir.Magnitude < 1 then return true end
			local look = hrp.CFrame.LookVector
			local horizLook = Vector3.new(look.X, 0, look.Z)
			return horizLook:Dot(horizDir.Unit) > 0
		end
		local charRadiusCache = {}
		local function getCharRadius(char)
			if charRadiusCache[char] then return charRadiusCache[char] end
			local ok, result = pcall(function()
				local _, size = char:GetBoundingBox()
				return math.max(size.X, size.Y, size.Z) / 2 + 5
			end)
			local radius = (ok and result) or 20
			charRadiusCache[char] = radius
			return radius
		end
		local function hitboxNearCharacter(hb, char)
			local charHRP = char:FindFirstChild("HumanoidRootPart")
			if not charHRP then return false end
			return (hb.Position - charHRP.Position).Magnitude < getCharRadius(char)
		end
		local CLASH_START_SLACK = 0.9
		local CLASH_KEEP_SLACK = 1.4
		local CLASH_BREAK_GRACE = 0.4
		local clashAimLostAt = nil
		local function aimsAt(plr, char, targetChar, slack)
			local myHead = getHeadPosition(char)
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local origin = myHead or (hrp and hrp.Position)
			local tHRP = targetChar:FindFirstChild("HumanoidRootPart")
			if not origin or not tHRP then return false end
			local dir
			local aim = plr and playerAims[plr]
			if aim and (aim - origin).Magnitude > 1 then
				dir = (aim - origin).Unit
			elseif hrp then
				dir = hrp.CFrame.LookVector
			else
				return false
			end
			local reach = math.max(getCharRadius(targetChar) - 5, 4) * slack + 3
			local tHead = getHeadPosition(targetChar) or tHRP.Position
			for _, c in ipairs({tHRP.Position, tHead}) do
				local to = c - origin
				local along = to:Dot(dir)
				if along > 0 and (to - dir * along).Magnitude <= reach then
					return true
				end
			end
			return false
		end
		local function mutualAim(otherData, slack)
			local otherChar = otherData.character
			if not otherChar then return false end
			return aimsAt(player, character, otherChar, slack) and aimsAt(otherData.player, otherChar, character, slack)
		end
		local smoothTip = currentTarget
		local lastFrameTime = tick()
		local wasClashing = false
		local clashTransitionUntil = 0
		local extent = 0
		local overpower = nil
		local lastClashData = nil
		local function renderFrame(ext, tip, clashing, now, clashInfo)
			local myHRP = character:FindFirstChild("HumanoidRootPart")
			if not myHRP then return end
			local startPos = getHeadPosition(character) or myHRP.Position
			if not clashing and playerShiftLock[player] then
				local look = myHRP.CFrame.LookVector
				local flat = Vector3.new(look.X, 0, look.Z)
				if flat.Magnitude > 0.01 then
					flat = flat.Unit
					local d = tip - startPos
					local f = d:Dot(flat)
					if f < 8 then tip = startPos + d + flat * (8 - f) end
				end
			end
			local endPos = startPos:Lerp(tip, ext)
			local roundedExt = math.floor(ext * 100 + 0.5) / 100
			if hitbox:GetAttribute("BeamExtent") ~= roundedExt then
				hitbox:SetAttribute("BeamExtent", roundedExt)
			end
			if beamIteration % 2 == 0 and #vfx.entries > 0 then
				local texDt = math.max(now - lastTexTime, 0.016)
				if lastEndPos then
					local speed = (endPos - lastEndPos).Magnitude / texDt
					local targetBoost = 1 + math.clamp(speed / 30, 0, 5)
					texBoost = texBoost + (targetBoost - texBoost) * 0.5
					BeamVFX.SetBoost(vfx, texBoost)
				end
				lastEndPos = endPos
				lastTexTime = now
			end
			hitbox.CFrame = orientHitbox(clashing and startPos or myHRP.Position, tip, endPos)
			positionSideHitboxes(startPos, hitbox.CFrame, sideHitboxes, ext)
			for _, be in ipairs(beamEndOffsets) do
				be.att.CFrame = CFrame.new(be.offset * ext)
			end
			if beamIteration % 2 == 0 and #glowAttachments > 0 and primaryBeamStart and primaryBeamStart.Parent then
				local beamStartPos = primaryBeamStart.WorldPosition
				local glowLength = (endPos - beamStartPos).Magnitude
				local glowScale = math.clamp(glowLength / 50, 0.12, 1)
				local glowRange = math.clamp(glowLength / (NUM_GLOW_LIGHTS + 1) * 1.4, 10, 60)
				for i, att in ipairs(glowAttachments) do
					local t = i / (NUM_GLOW_LIGHTS + 1)
					att.WorldPosition = beamStartPos:Lerp(endPos, t)
					local light = att:FindFirstChildOfClass("PointLight")
					if light then
						local b = 0.9 * ext * glowScale
						if math.abs(light.Brightness - b) > 0.02 then light.Brightness = b end
						if math.abs(light.Range - glowRange) > 0.5 then light.Range = glowRange end
					end
				end
			end
			updateImpact(endPos, ext, now, clashInfo, startPos)
			if beamIteration % 2 == 0 then
				local data = activeBeams[player]
				local burning = not clashInfo and ext > 0.9 and not (data and data.ending)
				for _, bt in ipairs(burnTrails) do
					local at = bt.att and bt.att.Parent and bt.att.WorldPosition or endPos
					bt.trail:Update(at, at - startPos, impactParams, now, burning)
				end
			end
		end
		renderFrame(0, smoothTip, false, tick())
		while tick() - startTime < duration or overpower do
			beamIteration += 1
			if not character.Parent or not character:FindFirstChild("HumanoidRootPart") then
				break
			end
			if ownerHumanoid and ownerHumanoid.Health <= 0 then
				break
			end
			local myHRP = character:FindFirstChild("HumanoidRootPart")
			local myData = activeBeams[player]
			if not overpower and myData and myData.overpowerRequest then
				local req = myData.overpowerRequest
				myData.overpowerRequest = nil
				if req.character and req.character.Parent and req.hitbox and req.hitbox.Parent then
					overpower = {loser = req, t0 = tick(), startPoint = smoothTip}
					myData.overpowering = true
					myData.overpowerDone = false
					currentClashPartner = nil
					if dpsScript then dpsScript.Enabled = false end
					for _, side in ipairs(sideHitboxes) do
						if side.dps then side.dps.Enabled = false end
					end
				else
					myData.overpowerDone = true
				end
			end
			if overpower then
				local now = tick()
				local loser = overpower.loser
				local loserHead = loser.character and loser.character.Parent and getHeadPosition(loser.character)
				local finished = false
				if not loserHead or not (loser.hitbox and loser.hitbox.Parent) then
					finished = true
				else
					local t = math.clamp((now - overpower.t0) / OVERPOWER_TIME, 0, 1)
					local clashPoint = overpower.startPoint:Lerp(loserHead, easeInOutQuad(t))
					smoothTip = clashPoint
					myData.clashPoint = clashPoint
					myData.clashLead = true
					extent = easeOutCubic(math.clamp((now - startTime) / INTRO_TIME, 0, 1))
					hitbox:SetAttribute("IsClashing", true)
					local myHead = getHeadPosition(character) or myHRP.Position
					local toLoser = loserHead - myHead
					renderFrame(extent, clashPoint, true, now, {
						lead = true,
						partnerColor = loser.impactColor or impactColor,
						partnerData = loser,
						partnerSources = loser.templateEmitters,
						axis = toLoser.Magnitude > 0.01 and toLoser.Unit or Vector3.zAxis,
					})
					if t >= 1 then
						finished = true
						local loserHum = loser.character:FindFirstChildOfClass("Humanoid")
						if loserHum and loserHum.Health > 0 then
							local creator = loserHum:FindFirstChild("creator")
							if not creator then
								creator = Instance.new("ObjectValue")
								creator.Name = "creator"
								creator.Parent = loserHum
							end
							creator.Value = player
							loserHum:SetAttribute("LastDPSAttacker", player.UserId)
							loserHum:TakeDamage(OVERPOWER_DAMAGE)
						end
						spawnClashExplosion(loserHead, ownSources, loser.templateEmitters or {}, impactColor, loser.impactColor or impactColor)
					end
				end
				if finished then
					overpower = nil
					wasClashing = true
					clashTransitionUntil = now + CLASH_TRANSITION_TIME
					lastFrameTime = now
					if myData then
						myData.overpowering = false
						myData.overpowerDone = true
						myData.clashPoint = nil
					end
				end
				task.wait(0.03)
				continue
			end
			local clashPartner = nil
			if currentClashPartner then
				local partner = currentClashPartner
				local clashStillValid = false
				for _, otherData in pairs(activeBeams) do
					if otherData == partner and otherData.character and otherData.character.Parent
						and otherData.hitbox and otherData.hitbox.Parent and not otherData.ending then
						if myHRP and mutualAim(partner, CLASH_KEEP_SLACK) then
							clashStillValid = true
							clashAimLostAt = nil
						elseif myHRP then
							clashAimLostAt = clashAimLostAt or tick()
							if tick() - clashAimLostAt < CLASH_BREAK_GRACE then
								clashStillValid = true
							end
						end
						break
					end
				end
				if clashStillValid then
					clashPartner = partner
				else
					currentClashPartner = nil
					clashAimLostAt = nil
				end
			end
			if not clashPartner and myHRP and activeBeams[player].clashRequestedBy then
				local requester = activeBeams[player].clashRequestedBy
				activeBeams[player].clashRequestedBy = nil
				if requester and requester.character and requester.character.Parent
					and requester.hitbox and requester.hitbox.Parent and not requester.ending then
					if mutualAim(requester, CLASH_KEEP_SLACK) then
						clashPartner = requester
						currentClashPartner = requester
					end
				end
			end
			if not clashPartner and myHRP and beamIteration % 3 == 0 then
				for otherPlayer, otherData in pairs(activeBeams) do
					if otherPlayer ~= player and otherData and otherData.hitbox and otherData.hitbox.Parent and not otherData.ending
						and otherData.character and otherData.character.Parent then
						local otherHRP = otherData.character:FindFirstChild("HumanoidRootPart")
						if otherHRP then
							if mutualAim(otherData, CLASH_START_SLACK) then
								if hitboxNearCharacter(hitbox, otherData.character)
									and hitboxNearCharacter(otherData.hitbox, character) then
									clashPartner = otherData
									currentClashPartner = otherData
									otherData.clashRequestedBy = activeBeams[player]
									if otherData.dpsScript then
										otherData.dpsScript.Enabled = false
									end
									break
								end
							end
						end
					end
				end
			end
			lastClashData = clashPartner
			local now = tick()
			local dt = math.clamp(now - lastFrameTime, 0.001, 0.25)
			lastFrameTime = now
			extent = easeOutCubic(math.clamp((now - startTime) / INTRO_TIME, 0, 1))
			local isClashingNow = clashPartner ~= nil
			if isClashingNow ~= wasClashing then
				wasClashing = isClashingNow
				clashTransitionUntil = now + CLASH_TRANSITION_TIME
			end
			local desiredTip = nil
			local clashInfo = nil
			if clashPartner then
				hitbox:SetAttribute("IsClashing", true)
				local myHeadPos = getHeadPosition(character)
				local partnerHeadPos = getHeadPosition(clashPartner.character)
				if myHeadPos and partnerHeadPos then
					desiredTip = (myHeadPos + partnerHeadPos) / 2
					local toPartner = partnerHeadPos - myHeadPos
					local partnerUserId = clashPartner.player and clashPartner.player.UserId or 0
					local lead = player.UserId < partnerUserId
					if activeBeams[player] then activeBeams[player].clashLead = lead end
					clashInfo = {
						lead = lead,
						partnerColor = clashPartner.impactColor or impactColor,
						partnerData = clashPartner,
						partnerSources = clashPartner.templateEmitters,
						axis = toPartner.Magnitude > 0.01 and toPartner.Unit or Vector3.zAxis,
					}
				end
				for _, side in ipairs(sideHitboxes) do
					if side.dps and side.dps.Enabled then
						side.dps.Enabled = false
					end
				end
				if dpsScript and dpsScript.Enabled then
					dpsScript.Enabled = false
				end
			else
				hitbox:SetAttribute("IsClashing", false)
				local latestAim = playerAims[player]
				if latestAim then
					currentTarget = latestAim
				end
				local aimTarget = currentTarget
				if playerShiftLock[player] then
					aimTarget = aimTarget + Vector3.new(0, SHIFTLOCK_RAISE, 0)
				end
				local wallOrigin = getHeadPosition(character)
				if not wallOrigin then
					local rootPart = character:FindFirstChild("HumanoidRootPart")
					wallOrigin = rootPart and rootPart.Position
				end
				if wallOrigin and (beamIteration % 2 == 0 or not cachedClampTip or (aimTarget - cachedClampAim).Magnitude > 3) then
					cachedClampTip = clampTipToWalls(wallOrigin, aimTarget, character)
					cachedClampAim = aimTarget
				end
				desiredTip = (wallOrigin and cachedClampTip) or aimTarget
				if extent >= 0.5 then
					if dpsScript and not dpsScript.Enabled then
						dpsScript.Enabled = true
					end
					for _, side in ipairs(sideHitboxes) do
						if side.dps and not side.dps.Enabled then
							side.dps.Enabled = true
						end
					end
				end
			end
			desiredTip = desiredTip or smoothTip
			local followRate = (isClashingNow or now < clashTransitionUntil) and CLASH_FOLLOW_RATE or AIM_FOLLOW_RATE
			smoothTip = smoothTip:Lerp(desiredTip, 1 - math.exp(-followRate * dt))
			renderFrame(extent, smoothTip, isClashingNow, now, clashInfo)
			if BEAM_COUNTER_ENABLED and beamIteration % 3 == 0 then
				local ownerHum = character:FindFirstChildOfClass("Humanoid")
				if ownerHum and ownerHum.Health > 0 then
					local ownerHRP = character:FindFirstChild("HumanoidRootPart")
					local atkParams = OverlapParams.new()
					atkParams.FilterDescendantsInstances = {character}
					atkParams.FilterType = Enum.RaycastFilterType.Exclude
					local atkParts = workspace:GetPartsInPart(hitbox, atkParams)
					for _, atkPart in ipairs(atkParts) do
						if atkPart.Name == "AttackHitbox" or atkPart:GetAttribute("MeleeHit") then
							local attackerChar = atkPart.Parent
							local attackerPlayer = Players:GetPlayerFromCharacter(attackerChar)
							if attackerPlayer and attackerPlayer ~= player and not beamHitDebounce[attackerPlayer] then
								local attackerHRP = attackerChar:FindFirstChild("HumanoidRootPart")
								local withinRange = true
								if ownerHRP and attackerHRP then
									local dist = (ownerHRP.Position - attackerHRP.Position).Magnitude
									local maxCounterRange = getCharRadius(character) + getCharRadius(attackerChar)
									withinRange = dist <= maxCounterRange
								end
								if withinRange then
									beamHitDebounce[attackerPlayer] = true
									local dmg = 10
									local atkStats = attackerChar:FindFirstChild("Stats")
									if atkStats then
										for _, dmgName in ipairs({"DMG1", "DMG2", "DMG3"}) do
											local dmgVal = atkStats:FindFirstChild(dmgName)
											if dmgVal then
												dmg = dmgVal.Value
												break
											end
										end
									end
									local creator = ownerHum:FindFirstChild("creator")
									if not creator then
										creator = Instance.new("ObjectValue")
										creator.Name = "creator"
										creator.Parent = ownerHum
									end
									creator.Value = attackerPlayer
									ownerHum:TakeDamage(dmg)
									local gcellAmount = math.floor(25 * (_G.RewardScale and _G.RewardScale(attackerPlayer, ownerHum.Parent, false) or 1) + math.random())
									if _G.ShowIndicator then _G.ShowIndicator(attackerPlayer, dmg, gcellAmount, 0, ownerHum.Parent) end
									local leaderstats = attackerPlayer:FindFirstChild("leaderstats")
									if leaderstats then
										local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
										if gcells and gcells:IsA("IntValue") then
											if _G.GCellGuardAllow then _G.GCellGuardAllow(gcells, gcellAmount) end
											gcells.Value = gcells.Value + gcellAmount
										end
									end
									task.spawn(function()
										task.wait(0.5)
										beamHitDebounce[attackerPlayer] = nil
									end)
								end
							end
						end
					end
				end
			end
			task.wait(0.03)
		end
		if character.Parent and character:FindFirstChild("HumanoidRootPart") then
			local overpoweredBy = nil
			local ownerDead = ownerHumanoid and ownerHumanoid.Health <= 0
			if not ownerDead and lastClashData and lastClashData.character and lastClashData.character.Parent
				and lastClashData.hitbox and lastClashData.hitbox.Parent and not lastClashData.ending then
				overpoweredBy = lastClashData
				overpoweredBy.overpowerRequest = activeBeams[player]
			end
			if activeBeams[player] then activeBeams[player].ending = true end
			hitbox:SetAttribute("IsClashing", false)
			hitbox:SetAttribute("BeamEnding", true)
			if dpsScript then dpsScript.Enabled = false end
			for _, side in ipairs(sideHitboxes) do
				if side.dps then side.dps.Enabled = false end
			end
			if overpoweredBy then
				local winnerData = overpoweredBy
				local deadline = tick() + OVERPOWER_TIME + 1.5
				while character.Parent and character:FindFirstChild("HumanoidRootPart")
					and not winnerData.overpowerDone and winnerData.hitbox and winnerData.hitbox.Parent
					and tick() < deadline do
					beamIteration += 1
					local now = tick()
					local point = winnerData.clashPoint
					if point then
						smoothTip = point
						local myHead = getHeadPosition(character) or point
						local toPoint = point - myHead
						renderFrame(1, point, true, now, {
							lead = false,
							partnerColor = winnerData.impactColor or impactColor,
							partnerData = winnerData,
							partnerSources = winnerData.templateEmitters,
							axis = toPoint.Magnitude > 0.01 and toPoint.Unit or Vector3.zAxis,
						})
					end
					task.wait(0.03)
				end
			else
				local outroStart = tick()
				local retractTip = smoothTip
				while character.Parent and character:FindFirstChild("HumanoidRootPart") do
					beamIteration += 1
					local now = tick()
					local t = (now - outroStart) / OUTRO_TIME
					if t >= 1 then break end
					renderFrame(1 - easeInOutQuad(t), retractTip, false, now)
					task.wait(0.03)
				end
			end
		end
	end)
	pcall(function()
		if #beamStarts > 0 then
			enableBeams(beamStarts, false, beamNameFilter)
		end
		if #beamEnds > 0 then
			enableParticles(beamEnds, false)
		end
		for _, att in ipairs(glowAttachments) do
			pcall(function() att:Destroy() end)
		end
		if dpsScript then
			dpsScript.Enabled = false
		end
		for _, side in ipairs(sideHitboxes) do
			if side.dps then
				side.dps.Enabled = false
			end
		end
		for beamEnd, original in pairs(beamEndOriginals) do
			beamEnd.CFrame = original.cframe
			beamEnd.Parent = original.parent
			beamEnd:SetAttribute("BeamEndOffset", nil)
		end
	end)
	pcall(function()
		for _, side in ipairs(sideHitboxes) do
			pcall(function() side.hitbox:Destroy() end)
		end
		local finishedData = activeBeams[player]
		if finishedData then
			if finishedData.impactFx then
				pcall(function() finishedData.impactFx:Destroy() end)
				finishedData.impactFx = nil
			end
			if finishedData.burnTrails then
				for _, bt in ipairs(finishedData.burnTrails) do
					pcall(function() bt.trail:Destroy() end)
				end
				finishedData.burnTrails = nil
			end
			BeamVFX.Destroy(finishedData.vfx)
		end
		local ib = activeBeams[player] and activeBeams[player].impactFolder
		if ib then ib:Destroy() end
		hitbox:Destroy()
	end)
	activeBeams[player] = nil
	beamGenerations[player] = nil
	playerAims[player] = nil
	playerShiftLock[player] = nil
	if ancestryConn then ancestryConn:Disconnect() end
	if beamEndedSignal then
		beamEndedSignal:Fire(player, myGeneration)
	end
	if not success then
		warn("[BeamSystem] Error during beam activation:", err)
	end
end
function BeamSystem.SetAim(player, targetPosition, isShiftLock)
	if typeof(targetPosition) == "Vector3" then
		playerAims[player] = targetPosition
		if isShiftLock ~= nil then
			playerShiftLock[player] = isShiftLock == true
		end
	end
end
return BeamSystem