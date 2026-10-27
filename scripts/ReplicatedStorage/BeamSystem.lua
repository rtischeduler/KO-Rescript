local BeamSystem = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
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
local BEAM_SLOW_FACTOR = 0.7
local BEAM_SLOW_LINGER = 0.35
local function easeOutCubic(t)
	return 1 - (1 - t) ^ 3
end
local function easeInOutQuad(t)
	if t < 0.5 then return 2 * t * t end
	return 1 - (-2 * t + 2) ^ 2 / 2
end
local slowedHumanoids = {}
local slowConnection = nil
local function releaseBeamSlow(humanoid)
	local data = slowedHumanoids[humanoid]
	if not data then return end
	slowedHumanoids[humanoid] = nil
	if humanoid.Parent then
		humanoid:SetAttribute("BeamSlowFactor", nil)
		if humanoid.WalkSpeed == data.applied then
			humanoid.WalkSpeed = data.base
		elseif humanoid:GetAttribute("Slowed") then
			humanoid.WalkSpeed = humanoid.WalkSpeed / data.factor
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
	if not humanoid or not humanoid.Parent then return end
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
local function findBeamAttachments(morphModel)
	local beamStarts = {}
	local beamEnds = {}
	for _, descendant in ipairs(morphModel:GetDescendants()) do
		if descendant:IsA("Attachment") then
			if descendant.Name == "BeamStart" then
				table.insert(beamStarts, descendant)
			elseif descendant.Name == "BeamEnd" then
				table.insert(beamEnds, descendant)
			end
		end
	end
	return beamStarts, beamEnds
end
local function enableBeams(beamStarts, enabled, beamNameFilter)
	for _, beamStart in ipairs(beamStarts) do
		for _, child in ipairs(beamStart:GetChildren()) do
			if child:IsA("Beam") then
				if beamNameFilter and not beamNameFilter[child.Name] then
				else
					if enabled then
						child.Transparency = NumberSequence.new(0.2)
					end
					child.Enabled = enabled
				end
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
local function createDPSScript(hitbox, player, character, duration)
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
		local dmg2 = stats:FindFirstChild("DMG2")
		if dmg2 then
			beamDamage = dmg2.Value
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


	task.spawn(function()
		task.wait(duration + 2)
		if activeBeams[player] and activeBeams[player].character == character then
			BeamSystem.ForceCleanup(player)
		end
	end)	local beamStarts, beamEnds = findBeamAttachments(character)
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
	hitbox.Parent = Workspace
	local dpsScript = createDPSScript(hitbox, player, character, duration)
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
	local NUM_GLOW_LIGHTS = 6
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
		impactFolder.Parent = Workspace
		activeBeams[player].impactFolder = impactFolder
		local function makeImpactPart(shape, size)
			local part = Instance.new("Part")
			part.Name = "ImpactPart"
			part.Shape = shape
			part.Size = size
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.CastShadow = false
			part.Material = Enum.Material.Neon
			part.Color = impactColor
			part.Transparency = 1
			part.Parent = impactFolder
			return part
		end
		local impactCore = makeImpactPart(Enum.PartType.Ball, Vector3.new(1, 1, 1))
		local impactRings = {
			makeImpactPart(Enum.PartType.Cylinder, Vector3.new(0.25, 1, 1)),
			makeImpactPart(Enum.PartType.Cylinder, Vector3.new(0.25, 1, 1)),
		}
		local impactLight = Instance.new("PointLight")
		impactLight.Color = impactColor
		impactLight.Range = 22
		impactLight.Brightness = 0
		impactLight.Parent = impactCore
		local impactEmitter = Instance.new("ParticleEmitter")
		impactEmitter.Rate = 0
		impactEmitter.Lifetime = NumberRange.new(0.35, 0.7)
		impactEmitter.Speed = NumberRange.new(18, 38)
		impactEmitter.Drag = 3
		impactEmitter.SpreadAngle = Vector2.new(180, 180)
		impactEmitter.LightEmission = 1
		impactEmitter.Color = ColorSequence.new(impactColor)
		impactEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0)})
		impactEmitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
		impactEmitter.Parent = impactCore
		local impactSurfacePos, impactSurfaceNormal = nil, Vector3.yAxis
		local lastEmit = 0
		local function updateImpact(endPos, extent, now)
			if beamIteration % 3 == 0 or not impactSurfacePos then
				local filter = {character, impactFolder, hitbox}
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr.Character then table.insert(filter, plr.Character) end
				end
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = filter
				local result = Workspace:Raycast(endPos + Vector3.new(0, 5, 0), Vector3.new(0, -25, 0), params)
				if result then
					impactSurfacePos = result.Position + result.Normal * 0.15
					impactSurfaceNormal = result.Normal
				else
					impactSurfacePos = endPos
					impactSurfaceNormal = Vector3.yAxis
				end
			end
			if extent < 0.02 then
				impactCore.Transparency = 1
				for _, ring in ipairs(impactRings) do ring.Transparency = 1 end
				impactLight.Brightness = 0
				return
			end
			local coreSize = math.max(0.05, (6 + math.sin(now * 16)) * extent)
			impactCore.Size = Vector3.new(coreSize, coreSize, coreSize)
			impactCore.CFrame = CFrame.new(impactSurfacePos + impactSurfaceNormal * (coreSize * 0.3))
			impactCore.Transparency = 0.3 + (1 - extent) * 0.7
			impactLight.Brightness = 1.5 * extent
			local ringBase = CFrame.lookAt(impactSurfacePos, impactSurfacePos + impactSurfaceNormal) * CFrame.Angles(0, math.pi / 2, 0)
			for i, ring in ipairs(impactRings) do
				local p = ((now / 0.7) + (i - 1) * 0.5) % 1
				local diameter = math.max(0.05, (3 + 30 * p) * extent)
				ring.Size = Vector3.new(0.25, diameter, diameter)
				ring.CFrame = ringBase
				ring.Transparency = math.clamp(0.25 + 0.75 * p ^ 1.3 + (1 - extent) * 0.5, 0, 1)
			end
			if extent > 0.5 and now - lastEmit > 0.12 then
				lastEmit = now
				impactEmitter:Emit(5)
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
		local smoothTip = currentTarget
		local lastFrameTime = tick()
		local wasClashing = false
		local clashTransitionUntil = 0
		local extent = 0
		local function renderFrame(ext, tip, clashing, now)
			local myHRP = character:FindFirstChild("HumanoidRootPart")
			if not myHRP then return end
			local startPos = getHeadPosition(character) or myHRP.Position
			local endPos = startPos:Lerp(tip, ext)
			hitbox.CFrame = orientHitbox(clashing and startPos or myHRP.Position, tip, endPos)
			positionSideHitboxes(startPos, hitbox.CFrame, sideHitboxes, ext)
			for _, be in ipairs(beamEndOffsets) do
				be.att.CFrame = CFrame.new(be.offset * ext)
			end
			if beamIteration % 2 == 0 and #glowAttachments > 0 and primaryBeamStart and primaryBeamStart.Parent then
				local beamStartPos = primaryBeamStart.WorldPosition
				for i, att in ipairs(glowAttachments) do
					local t = i / (NUM_GLOW_LIGHTS + 1)
					att.WorldPosition = beamStartPos:Lerp(endPos, t)
					local light = att:FindFirstChildOfClass("PointLight")
					if light then light.Brightness = 0.3 * ext end
				end
			end
			updateImpact(endPos, ext, now)
		end
		renderFrame(0, smoothTip, false, tick())
		while tick() - startTime < duration do
			beamIteration += 1
			if not character.Parent or not character:FindFirstChild("HumanoidRootPart") then
				break
			end
			local myHRP = character:FindFirstChild("HumanoidRootPart")
			local clashPartner = nil
			if currentClashPartner then
				local partner = currentClashPartner
				local clashStillValid = false
				for _, otherData in pairs(activeBeams) do
					if otherData == partner and otherData.character and otherData.character.Parent
						and otherData.hitbox and otherData.hitbox.Parent and not otherData.ending then
						local partnerHRP = partner.character:FindFirstChild("HumanoidRootPart")
						if partnerHRP and myHRP then
							if isFacing(myHRP, partnerHRP.Position) and isFacing(partnerHRP, myHRP.Position) then
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
				end
			end
			if not clashPartner and myHRP and activeBeams[player].clashRequestedBy then
				local requester = activeBeams[player].clashRequestedBy
				activeBeams[player].clashRequestedBy = nil
				if requester and requester.character and requester.character.Parent
					and requester.hitbox and requester.hitbox.Parent and not requester.ending then
					local requesterHRP = requester.character:FindFirstChild("HumanoidRootPart")
					if requesterHRP then
						if isFacing(myHRP, requesterHRP.Position) and isFacing(requesterHRP, myHRP.Position) then
							clashPartner = requester
							currentClashPartner = requester
						end
					end
				end
			end
			if not clashPartner and myHRP then
				for otherPlayer, otherData in pairs(activeBeams) do
					if otherPlayer ~= player and otherData and otherData.hitbox and otherData.hitbox.Parent and not otherData.ending
						and otherData.character and otherData.character.Parent then
						local otherHRP = otherData.character:FindFirstChild("HumanoidRootPart")
						if otherHRP then
							if isFacing(myHRP, otherHRP.Position) and isFacing(otherHRP, myHRP.Position) then
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
			if clashPartner then
				hitbox:SetAttribute("IsClashing", true)
				local myHeadPos = getHeadPosition(character)
				local partnerHeadPos = getHeadPosition(clashPartner.character)
				if myHeadPos and partnerHeadPos then
					desiredTip = (myHeadPos + partnerHeadPos) / 2
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
				desiredTip = currentTarget
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
			renderFrame(extent, smoothTip, isClashingNow, now)
			if beamIteration % 3 == 0 then
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
									local leaderstats = attackerPlayer:FindFirstChild("leaderstats")
									if leaderstats then
										local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
										if gcells and gcells:IsA("IntValue") then
											if _G.GCellGuardAllow then _G.GCellGuardAllow(gcells, 25) end
											gcells.Value = gcells.Value + 25
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
			if activeBeams[player] then activeBeams[player].ending = true end
			hitbox:SetAttribute("IsClashing", false)
			if dpsScript then dpsScript.Enabled = false end
			for _, side in ipairs(sideHitboxes) do
				if side.dps then side.dps.Enabled = false end
			end
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
		local ib = activeBeams[player] and activeBeams[player].impactFolder
		if ib then ib:Destroy() end
		hitbox:Destroy()
	end)
	activeBeams[player] = nil
	beamGenerations[player] = nil
	playerAims[player] = nil
	playerShiftLock[player] = nil
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