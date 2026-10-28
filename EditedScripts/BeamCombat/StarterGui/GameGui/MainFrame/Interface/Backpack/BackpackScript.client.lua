local Players = game:GetService("Players")
local player = Players.LocalPlayer

local backpack = script.Parent
local template = backpack:FindFirstChild("Template")

local TweenService = game:GetService("TweenService")
local CooldownManager = require(game:GetService("ReplicatedStorage"):WaitForChild("CooldownManager"))
local ChargeManager = require(game:GetService("ReplicatedStorage"):WaitForChild("ChargeManager"))
local UserInputService = game:GetService("UserInputService")
local isMobile = UserInputService.TouchEnabled

local function getDeviceSettings()
	if not UserInputService.TouchEnabled then

		return { buttonSize = 110, spacing = 14, backpackWidth = 800, backpackHeight = 130 }
	end

	return { buttonSize = 70, spacing = 8, backpackWidth = 500, backpackHeight = 90 }
end

local deviceSettings = getDeviceSettings()
local BUTTON_SIZE = deviceSettings.buttonSize
local SPACING = deviceSettings.spacing
local SCALE = BUTTON_SIZE / 80

backpack.Size = UDim2.new(0, deviceSettings.backpackWidth, 0, deviceSettings.backpackHeight)
backpack.Position = UDim2.new(0.5, -deviceSettings.backpackWidth / 2, 1, -deviceSettings.backpackHeight - 15)

local function scaleButtonChildren(button)
	local r = function(n) return math.round(n * SCALE) end

	local num = button:FindFirstChild("Num")
	if num then
		num.Size = UDim2.new(0, r(28), 0, r(9))
	end

	local title = button:FindFirstChild("Title")
	if title then
		if button.Name == "Sprint" then
			title.Size = UDim2.new(1, 0, 0, r(18))
			title.Position = UDim2.new(0, 0, 1, -r(18))
			title.TextScaled = true
		else
			title.Size = UDim2.new(0, r(69), 0, r(10))
			title.Position = UDim2.new(0, r(5), 0, r(66))
		end
	end

	local indicator = button:FindFirstChild("ActiveIndicator")
	if indicator then
		indicator.Size = UDim2.new(1, -r(4), 1, -r(4))
		indicator.Position = UDim2.new(0, r(2), 0, r(2))
	end

	local corner = button:FindFirstChild("UICorner")
	if corner then
		local originalRadius = (button.Name == "Sprint") and 4 or 7
		corner.CornerRadius = UDim.new(0, r(originalRadius))
	end
end

local sprintBtn = backpack:FindFirstChild("Sprint")
if sprintBtn then
	sprintBtn.Size = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE)
	scaleButtonChildren(sprintBtn)
end
if template then
	template.Size = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE)
	scaleButtonChildren(template)
end

local bars = backpack.Parent:FindFirstChild("Bars")
if bars then
	bars.Position = UDim2.new(0.5, -185, 1, -deviceSettings.backpackHeight - 40)
end

local activeButtons = {}

local slotToEvent = {}

local activeCooldowns = {}

local RunService = game:GetService("RunService")
local Knit = require(game:GetService("ReplicatedStorage"):WaitForChild("Knit"):WaitForChild("Knit"))
local BeamService = nil
local beamActive = false
local currentBeamGeneration = nil
local beamLockedYaw = nil
local beamDelayToken = nil
local beamStartTimeout = nil
local beamRotationConnection = nil
local currentScreenPos = nil
local activeTouches = {}
local beamPredictionConnection = nil
local beamPredictChar = nil
local beamPredictBeamStart = nil
local beamPredictHitbox = nil
local beamEndsReparented = false

local stopBeamRotation
local startBeamRotation

local SPRINT_IMAGE_NORMAL = "rbxassetid://85803878121852"
local SPRINT_IMAGE_FLYING = ""

local function getDisplayName(event)
	local attackName = event:GetAttribute("AttackName")
	if attackName and attackName ~= "" then
		return attackName
	end
	local name = event.Name
	if name == "Attack" or name == "Attack1Event" then return "Attack" end
	if name == "Beam" or name == "Attack2Event" then return "Beam" end
	if name == "Attack3" or name == "Attack3Event" then return "Attack 3" end
	if name == "Roar1" or name == "Roar1Event" then return "Roar 1" end
	if name == "Roar2" or name == "Roar2Event" then return "Roar 2" end
	return name
end

local function isAttackEvent(event)
	if not event:IsA("RemoteEvent") then return false end
	local attackName = event:GetAttribute("AttackName")
	if attackName then return true end
	local lower = string.lower(event.Name)
	return lower:find("attack") or lower:find("beam") or lower:find("roar")
end

local ORDER = {
	Attack = 1, Attack1Event = 1,
	Beam = 2, Attack2Event = 2,
	Attack3 = 3, Attack3Event = 3,
	Attack4 = 4, Attack4Event = 4,
	Roar1 = 5, Roar1Event = 5,
	Roar2 = 6, Roar2Event = 6,
}

local NUMBERS = {"ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX"}

local function clearButtons()
	for _, child in ipairs(backpack:GetChildren()) do
		if child:IsA("ImageButton") and child.Name ~= "Template" and child.Name ~= "Sprint" then
			child.Parent = nil
		end
	end
end

local function getShiftLockState()
	return player:GetAttribute("ShiftLockEnabled") == true
end

local function isJoystickStart(position, gameProcessed)
	if gameProcessed then return true end
	local camera = workspace.CurrentCamera
	if not camera then return false end
	local viewport = camera.ViewportSize
	return position.X < viewport.X * 0.5
end

local function pickBestTouchPos()
	for input, data in pairs(activeTouches) do
		if not data.isJoystick then
			return data.pos
		end
	end
	return nil
end

UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		currentScreenPos = Vector2.new(input.Position.X, input.Position.Y)
	elseif input.UserInputType == Enum.UserInputType.Touch then
		local data = activeTouches[input]
		if data then
			data.pos = Vector2.new(input.Position.X, input.Position.Y)
			if not data.isJoystick then
				currentScreenPos = data.pos
			end
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Touch then
		local pos = Vector2.new(input.Position.X, input.Position.Y)
		local isJoystick = isJoystickStart(pos, gameProcessed)
		activeTouches[input] = {pos = pos, isJoystick = isJoystick}
		if not isJoystick then
			currentScreenPos = pos
		end
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		currentScreenPos = Vector2.new(input.Position.X, input.Position.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Touch then
		activeTouches[input] = nil
		local best = pickBestTouchPos()
		if best then
			currentScreenPos = best
		end
	end
end)

local function raycastFiltered(origin, direction, character)
	local excluded = {character}
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local currentOrigin = origin
	local dirUnit = direction.Unit
	local remainingDist = direction.Magnitude

	for i = 1, 30 do
		params.FilterDescendantsInstances = excluded
		local result = workspace:Raycast(currentOrigin, dirUnit * remainingDist, params)
		if not result then return nil end

		local inst = result.Instance
		local isTransparent = inst:IsA("BasePart") and not inst:IsA("Terrain") and (inst.Transparency >= 0.95 or not inst.CanCollide)
		local isWater = result.Material == Enum.Material.Water

		if isTransparent or isWater then
			local consumed = (result.Position - currentOrigin).Magnitude
			remainingDist = remainingDist - consumed
			if remainingDist <= 0.1 then return nil end
			currentOrigin = result.Position
			table.insert(excluded, inst)
		else
			return result
		end
	end
	return nil
end

local function advanceOrigin(origin, direction, character)
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return origin end
	local unit = direction.Unit
	local along = (hrp.Position - origin):Dot(unit)
	if along > 0 then return origin + unit * along end
	return origin
end

local function getAimPosition(character)
	local camera = workspace.CurrentCamera
	if not camera then return nil end
	if not character then return nil end

	local isShiftLock = getShiftLockState()

	if isShiftLock then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end

		local camLook = camera.CFrame.LookVector
		local camPitch = math.asin(math.clamp(camLook.Y, -1, 1))

		local charLook = hrp.CFrame.LookVector
		local charYaw = math.atan2(-charLook.X, charLook.Z)

		local cosPitch = math.cos(camPitch)
		local direction = Vector3.new(
			-math.sin(charYaw) * cosPitch,
			math.sin(camPitch),
			math.cos(charYaw) * cosPitch
		).Unit

		local result = raycastFiltered(advanceOrigin(camera.CFrame.Position, direction, character), direction * 1000, character)
		if result then
			return result.Position
		else
			return advanceOrigin(camera.CFrame.Position, direction, character) + direction * 1000
		end
	else
		local screenPos = nil

		if UserInputService.MouseEnabled then
			local mouseLocation = UserInputService:GetMouseLocation()
			screenPos = Vector2.new(mouseLocation.X, mouseLocation.Y)
		end

		if not screenPos then
			screenPos = currentScreenPos
		end

		local ray
		if screenPos then
			ray = camera:ScreenPointToRay(screenPos.X, screenPos.Y)
		else
			local viewport = camera.ViewportSize
			ray = camera:ViewportPointToRay(viewport.X / 2, viewport.Y / 2)
		end

		local result = raycastFiltered(advanceOrigin(ray.Origin, ray.Direction, character), ray.Direction * 1000, character)
		if result then
			return result.Position
		else
			return advanceOrigin(ray.Origin, ray.Direction, character) + ray.Direction * 1000
		end
	end
end

local function needsAimPosition(eventName)
	return eventName == "Beam" or eventName == "Attack2Event"
		or eventName == "Attack3" or eventName == "Attack3Event"
end

local function isBeamEvent(eventName)
	return eventName == "Beam" or eventName == "Attack2Event"
		or eventName == "Attack3" or eventName == "Attack3Event"
end

stopBeamRotation = function()
	if beamRotationConnection then
		beamRotationConnection:Disconnect()
		beamRotationConnection = nil
	end
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.AutoRotate = true
		end
	end
end

local PRED_INTRO_TIME = 0.4
local PRED_FOLLOW_RATE = 40
local PRED_SERVER_RATE = 14
local PRED_TRANSITION_RATE = 6
local PRED_TRANSITION_TIME = 0.7
local beamPredictStartTime = 0
local beamPredictTip = nil
local beamPredictEnd = nil
local beamPredictServerMode = false
local beamPredictTransitionUntil = 0
local beamPredictServerHitbox = nil
local beamPredictLastTime = 0

local function easeOutCubic(t)
	return 1 - (1 - t) ^ 3
end

local function getBeamHeadPosition(character)
	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head.Position
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	return hrp and hrp.Position or nil
end

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

local function findServerBeamHitbox()
	if beamPredictServerHitbox and beamPredictServerHitbox.Parent then
		return beamPredictServerHitbox
	end
	beamPredictServerHitbox = nil
	local playerName = player.Name
	for _, child in ipairs(workspace:GetChildren()) do
		if child:IsA("BasePart") and child.Name == "BeamHitbox" and child:GetAttribute("Attacker") == playerName
			and child:GetAttribute("BeamMain") then
			beamPredictServerHitbox = child
			return child
		end
	end
	return nil
end

local function startBeamPrediction()
	beamPredictChar = player.Character
	if not beamPredictChar then return end

	beamPredictBeamStart = nil
	for _, descendant in ipairs(beamPredictChar:GetDescendants()) do
		if descendant:IsA("Attachment") and descendant.Name == "BeamStart" then
			beamPredictBeamStart = descendant
			break
		end
	end

	if beamPredictionConnection then
		beamPredictionConnection:Disconnect()
	end

	if beamPredictHitbox then
		beamPredictHitbox:Destroy()
		beamPredictHitbox = nil
	end
	beamEndsReparented = false
	beamPredictServerHitbox = nil
	beamPredictServerMode = false
	beamPredictTransitionUntil = 0
	beamPredictStartTime = tick()
	beamPredictLastTime = beamPredictStartTime

	beamPredictHitbox = Instance.new("Part")
	beamPredictHitbox.Name = "BeamPredictionHitbox"
	beamPredictHitbox.Size = Vector3.new(6, 6, 6)
	beamPredictHitbox.Anchored = true
	beamPredictHitbox.CanCollide = false
	beamPredictHitbox.CanTouch = false
	beamPredictHitbox.CanQuery = false
	beamPredictHitbox.Transparency = 1
	beamPredictHitbox.Parent = beamPredictChar

	local charHRP = beamPredictChar:FindFirstChild("HumanoidRootPart")
	local startPos = getBeamHeadPosition(beamPredictChar) or (charHRP and charHRP.Position) or Vector3.new()
	beamPredictTip = getAimPosition(beamPredictChar)
	if not beamPredictTip and charHRP then
		beamPredictTip = charHRP.Position + charHRP.CFrame.LookVector * 50
	end
	beamPredictEnd = startPos
	beamPredictHitbox.CFrame = CFrame.new(startPos)

	beamPredictionConnection = RunService.RenderStepped:Connect(function()
		if not beamActive or not beamPredictChar or not beamPredictChar.Parent then return end
		local hrp = beamPredictChar:FindFirstChild("HumanoidRootPart")
		if not hrp or not beamPredictHitbox or not beamPredictHitbox.Parent then return end

		local now = tick()
		local dt = math.clamp(now - beamPredictLastTime, 0.001, 0.25)
		beamPredictLastTime = now

		local serverHitbox = findServerBeamHitbox()

		if not beamEndsReparented and serverHitbox then
			local reparentedAny = false
			for _, child in ipairs(serverHitbox:GetChildren()) do
				if child:IsA("Attachment") and child.Name == "BeamEnd" then
					child.Parent = beamPredictHitbox
					reparentedAny = true
				end
			end
			if reparentedAny then
				beamEndsReparented = true
			end
		end

		local startPos = getBeamHeadPosition(beamPredictChar) or hrp.Position
		local serverMode = serverHitbox ~= nil
			and (serverHitbox:GetAttribute("IsClashing") == true or serverHitbox:GetAttribute("BeamEnding") == true)

		if serverMode ~= beamPredictServerMode then
			beamPredictServerMode = serverMode
			beamPredictTransitionUntil = now + PRED_TRANSITION_TIME
			if not serverMode and beamPredictEnd then
				beamPredictTip = beamPredictEnd
			end
		end

		local extent
		local dirTarget
		if serverMode then
			extent = serverHitbox:GetAttribute("BeamExtent") or 1
			beamPredictEnd = beamPredictEnd:Lerp(serverHitbox.Position, 1 - math.exp(-PRED_SERVER_RATE * dt))
			beamPredictTip = beamPredictEnd
			dirTarget = beamPredictEnd
		else
			local aim = getAimPosition(beamPredictChar)
			if aim and beamPredictTip then
				local rate = now < beamPredictTransitionUntil and PRED_TRANSITION_RATE or PRED_FOLLOW_RATE
				beamPredictTip = beamPredictTip:Lerp(aim, 1 - math.exp(-rate * dt))
			end
			extent = easeOutCubic(math.clamp((now - beamPredictStartTime) / PRED_INTRO_TIME, 0, 1))
			beamPredictEnd = startPos:Lerp(beamPredictTip or startPos, extent)
			dirTarget = beamPredictTip or beamPredictEnd
		end

		beamPredictHitbox.CFrame = orientHitbox(serverMode and startPos or hrp.Position, dirTarget, beamPredictEnd)

		for _, child in ipairs(beamPredictHitbox:GetChildren()) do
			if child:IsA("Attachment") and child.Name == "BeamEnd" then
				local offset = child:GetAttribute("BeamEndOffset") or Vector3.new(0, 0, 0)
				child.CFrame = CFrame.new(offset * extent)
			end
		end

		if beamPredictBeamStart and beamPredictBeamStart.Parent then
			local beamStartPos = beamPredictBeamStart.WorldPosition
			for i = 1, 6 do
				local att = hrp:FindFirstChild("BeamGlowLight" .. i)
				if att then
					att.WorldPosition = beamStartPos:Lerp(beamPredictEnd, i / 7)
				end
			end
		end
	end)
end

local function cleanupBeamEndVisuals(beamEndAtt)
	for _, child in ipairs(beamEndAtt:GetChildren()) do
		if child:IsA("ParticleEmitter") then
			child.Enabled = false
			child:Clear()
		elseif child:IsA("Light") then
			child.Enabled = false
		end
	end
end

local function stopBeamPrediction()
	if beamPredictionConnection then
		beamPredictionConnection:Disconnect()
		beamPredictionConnection = nil
	end

	
	if beamPredictHitbox then
		for _, child in ipairs(beamPredictHitbox:GetChildren()) do
			if child:IsA("Attachment") and child.Name == "BeamEnd" then
				if beamPredictChar and beamPredictChar.Parent then
					local serverHitbox = findServerBeamHitbox()
					if serverHitbox and serverHitbox.Parent then
						child.Parent = serverHitbox
						local offset = child:GetAttribute("BeamEndOffset") or Vector3.new(0, 0, 0)
						child.CFrame = CFrame.new(offset)
					else
						child.Parent = nil
					end
				else
					child.Parent = nil
				end
			end
		end
		beamPredictHitbox:Destroy()
		beamPredictHitbox = nil
	end

	beamEndsReparented = false
	if beamPredictChar and beamPredictChar.Parent then
		for _, descendant in ipairs(beamPredictChar:GetDescendants()) do
			if descendant:IsA("Attachment") and descendant.Name == "BeamEnd" then
				cleanupBeamEndVisuals(descendant)
				descendant:SetAttribute("BeamEndOffset", nil)
			end
		end
	end
	beamPredictChar = nil
	beamPredictBeamStart = nil
	beamPredictServerHitbox = nil
	beamPredictTip = nil
	beamPredictEnd = nil
	beamPredictServerMode = false
end

startBeamRotation = function()
	stopBeamRotation()
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end

	if not getShiftLockState() then
		humanoid.AutoRotate = false
	end

	beamRotationConnection = RunService.RenderStepped:Connect(function()
		if not beamActive then return end
		if not character or not character.Parent then return end

		if getShiftLockState() then return end
		local currentHrp = character:FindFirstChild("HumanoidRootPart")
		if not currentHrp then return end
		local currentHum = character:FindFirstChildOfClass("Humanoid")
		if currentHum then
			currentHum.AutoRotate = false
		end
		local targetPos = getAimPosition(character)
		if not targetPos then return end
		local pos = currentHrp.Position
		local lookDir = Vector3.new(targetPos.X - pos.X, 0, targetPos.Z - pos.Z)
		if lookDir.Magnitude > 0.1 then
			local yaw = math.atan2(-lookDir.X, -lookDir.Z)
			currentHrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
		end
	end)
end


Knit.OnStart():andThen(function()
	BeamService = Knit.GetService("BeamService")

	BeamService.BeamStarted:Connect(function(generation)
		if beamStartTimeout then
			task.cancel(beamStartTimeout)
			beamStartTimeout = nil
		end
		currentBeamGeneration = generation

		if getShiftLockState() then
			local character = player.Character
			if character then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local charLook = hrp.CFrame.LookVector
					beamLockedYaw = math.atan2(-charLook.X, charLook.Z)
				end
			end
		end
		beamActive = true
		startBeamRotation()
		startBeamPrediction()
	end)

	BeamService.BeamEnded:Connect(function(generation)
		if generation ~= nil and generation ~= currentBeamGeneration then return end
		currentBeamGeneration = nil
		beamActive = false
		beamLockedYaw = nil
		if beamStartTimeout then
			task.cancel(beamStartTimeout)
			beamStartTimeout = nil
		end
		if beamDelayToken then
			task.cancel(beamDelayToken)
			beamDelayToken = nil
		end
		stopBeamRotation()
		stopBeamPrediction()
	end)
end):catch(warn)


local function onCharacterDied(character)
	local hum = character:WaitForChild("Humanoid", 5)
	if hum then
		hum.Died:Connect(function()
			beamActive = false
			currentBeamGeneration = nil
			beamLockedYaw = nil
			if beamStartTimeout then
				task.cancel(beamStartTimeout)
				beamStartTimeout = nil
			end
			if beamDelayToken then
				task.cancel(beamDelayToken)
				beamDelayToken = nil
			end
			stopBeamRotation()
			stopBeamPrediction()
		end)
	end
end


task.spawn(function()
	local lastAim, lastLock = nil, nil
	while task.wait(0.05) do
		if beamActive and BeamService then
			local character = player.Character
			local targetPos = getAimPosition(character)
			if targetPos then
				local lock = getShiftLockState()
				if targetPos ~= lastAim or lock ~= lastLock then
					lastAim, lastLock = targetPos, lock
					BeamService.BeamAim:Fire(targetPos, lock)
				end
			end
		else
			lastAim, lastLock = nil, nil
		end
	end
end)


local PREDICTION_ANIM_MAP = {
	Attack = "Attack1", Attack1Event = "Attack1",
	Beam = "Attack2", Attack2Event = "Attack2",
	Attack3 = "Attack3", Attack3Event = "Attack3",
	Attack4 = "Attack4", Attack4Event = "Attack4",
	Roar1 = "Roar1", Roar1Event = "Roar1",
	Roar2 = "Roar2", Roar2Event = "Roar2",
}

local ROAR_EVENTS = {
	Roar1 = true, Roar1Event = true,
	Roar2 = true, Roar2Event = true,
}



local RunService = game:GetService("RunService")

local SHAKE_FREQ = 7
local BEAM_ROT = 0.0022
local BEAM_POS = 0.008
local ROAR_ROT = 0.0038
local ROAR_POS = 0.014
local PULSE_ROT = 0.005
local PULSE_POS = 0.02
local ROAR_FALLBACK = 3
local KICK_TIME = 0.45

local shakeState = { beamLevel = 0, roarStart = 0, roarEnd = 0, kickStart = -10, kickDir = 1 }

local function shakeNoise(t, seed)
	return math.noise(t * SHAKE_FREQ, seed + 0.5, 0.37) * 2
end

local function onShakeAbility(eventName)
	if isBeamEvent(eventName) then return end
	local now = os.clock()
	if ROAR_EVENTS[eventName] then
		shakeState.roarStart = now
		shakeState.roarEnd = now + ROAR_FALLBACK
	else
		shakeState.kickStart = now
		shakeState.kickDir = -shakeState.kickDir
	end
end

local function syncRoarShakeToSound(sound)
	local startedAt = shakeState.roarStart
	task.spawn(function()
		local t0 = os.clock()
		while sound.Parent and sound.TimeLength == 0 and os.clock() - t0 < 1 do
			task.wait()
		end
		if sound.TimeLength > 0 and shakeState.roarStart == startedAt then
			shakeState.roarEnd = startedAt + sound.TimeLength / math.max(sound.PlaybackSpeed, 0.05)
		end
	end)
end

pcall(function() RunService:UnbindFromRenderStep("KOCameraShake") end)
RunService:BindToRenderStep("KOCameraShake", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local camera = workspace.CurrentCamera
	if not camera or camera.CameraType == Enum.CameraType.Scriptable then return end
	if player:GetAttribute("CameraShake") == false then return end
	local now = os.clock()
	local target = beamActive and 1 or 0
	local rate = target > shakeState.beamLevel and 5 or 3
	shakeState.beamLevel += (target - shakeState.beamLevel) * math.min(dt * rate, 1)
	if shakeState.beamLevel < 0.01 then shakeState.beamLevel = 0 end
	local roar = 0
	if now < shakeState.roarEnd then
		roar = math.clamp(math.min((now - shakeState.roarStart) / 0.15, (shakeState.roarEnd - now) / 0.4, 1), 0, 1)
	end
	local pulse = 0
	local pulseEnd = player:GetAttribute("PulseShakeEnd") or 0
	if now < pulseEnd then
		local pulseStart = player:GetAttribute("PulseShakeStart") or now
		local env = math.clamp(math.min((now - pulseStart) / 0.08, (pulseEnd - now) / 0.5, 1), 0, 1)
		pulse = env * (player:GetAttribute("PulseShakeAmp") or 0)
	end
	local kickAge = now - shakeState.kickStart
	local kick = kickAge < KICK_TIME and math.exp(-kickAge * 9) or 0
	local rotAmp = math.max(shakeState.beamLevel * BEAM_ROT, roar * ROAR_ROT, pulse * PULSE_ROT)
	local posAmp = math.max(shakeState.beamLevel * BEAM_POS, roar * ROAR_POS, pulse * PULSE_POS)
	if rotAmp == 0 and posAmp == 0 and kick == 0 then return end
	local pitch = shakeNoise(now, 1) * rotAmp
	local yaw = shakeNoise(now, 2) * rotAmp
	local roll = shakeNoise(now, 3) * rotAmp * 0.7
	local px = shakeNoise(now, 4) * posAmp
	local py = shakeNoise(now, 5) * posAmp
	if kick > 0 then
		roll += shakeState.kickDir * 0.016 * kick * math.cos(kickAge * 20)
		pitch -= 0.009 * kick * math.cos(kickAge * 16)
		yaw += shakeState.kickDir * 0.004 * kick * math.sin(kickAge * 14)
		py -= 0.04 * kick
	end
	camera.CFrame = camera.CFrame * CFrame.new(px, py, 0) * CFrame.Angles(pitch, yaw, roll)
end)

local function silenceServerRoarSound(char, roarName)
	local targets = {}
	local head = char:FindFirstChild("Head")
	local torso = char:FindFirstChild("Torso")
	if head then table.insert(targets, head) end
	if torso then table.insert(targets, torso) end
	table.insert(targets, char)

	local connections = {}
	local TIMEOUT = 3

	local function checkAndSilence(child)
		if child:IsA("Sound") and child.Name == roarName and not child:GetAttribute("ClientPrediction") then
			child.Volume = 0
			child:Stop()
		end
	end

	for _, target in ipairs(targets) do
		
		for _, child in ipairs(target:GetChildren()) do
			checkAndSilence(child)
		end
		
		local conn = target.ChildAdded:Connect(checkAndSilence)
		table.insert(connections, conn)
	end

	
	task.delay(TIMEOUT, function()
		for _, conn in ipairs(connections) do
			conn:Disconnect()
		end
	end)
end

local function playClientPrediction(eventName, char)
	local animName = PREDICTION_ANIM_MAP[eventName]
	if not animName then return end
	onShakeAbility(eventName)

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChild("Animator")
	if not animator then return end

	local animationsFolder = char:FindFirstChild("Animations")
	if animationsFolder then
		local anim = animationsFolder:FindFirstChild(animName)
		if anim then
			local track = animator:LoadAnimation(anim)
			track.Looped = false
			track.Priority = Enum.AnimationPriority.Action
			track:Play()
		end
	end

	if ROAR_EVENTS[eventName] then
		local cs = char:FindFirstChild("CharacterScripts")
		if cs then
			local soundsFolder = cs:FindFirstChild("Sounds")
			if soundsFolder then
				local sound = soundsFolder:FindFirstChild(animName)
				if sound then
					local soundClone = sound:Clone()
					soundClone:SetAttribute("ClientPrediction", true)
					soundClone.Parent = char:FindFirstChild("Head") or char:FindFirstChild("Torso") or char
					soundClone:Play()
					syncRoarShakeToSound(soundClone)
					local len = soundClone.TimeLength / soundClone.PlaybackSpeed
					task.spawn(function()
						task.wait(len > 0 and len or 5)
						soundClone:Destroy()
					end)
					
					silenceServerRoarSound(char, animName)
				end
			end
		end
	end
end

local function fireAbility(eventName)
	local button = activeButtons[eventName]
	if not button then return end

	local char = player.Character
	if not char then return end
	local cs = char:FindFirstChild("CharacterScripts")
	if not cs then return end

	local evt = cs:FindFirstChild(eventName)
	if not evt then
		local ae = cs:FindFirstChild("AnimEvents")
		if ae then
			evt = ae:FindFirstChild(eventName)
		end
	end
	if not evt then return end

	local cdDuration = CooldownManager.getDuration(eventName)
	if not CooldownManager.canUse(eventName) then
		return
	end
	if not ChargeManager.canUseCharge(eventName) then
		return
	end

	CooldownManager.start(eventName, cdDuration)
	ChargeManager.consumeCharge(eventName)

	playClientPrediction(eventName, char)

	if needsAimPosition(eventName) then
		local aimPos = getAimPosition(char)
		if aimPos then
			evt:FireServer(aimPos)
		else
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				evt:FireServer(hrp.Position + hrp.CFrame.LookVector * 1000)
			end
		end
	else
		evt:FireServer()
	end

	if isBeamEvent(eventName) then
		if beamStartTimeout then
			task.cancel(beamStartTimeout)
		end
		beamStartTimeout = task.delay(5, function()
			beamStartTimeout = nil
			beamActive = false
			currentBeamGeneration = nil
			beamLockedYaw = nil
			stopBeamRotation()
			stopBeamPrediction()
		end)
	end

	CooldownManager.startAttackDuration(eventName)

	local attackDuration = CooldownManager.getAttackDuration(eventName)
	local visualDuration = math.max(cdDuration, attackDuration)

	local charge = button:FindFirstChild("Charge")
	if charge then
		charge.Size = UDim2.new(1, 0, -1, 0)
		local tween = TweenService:Create(charge, TweenInfo.new(visualDuration, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 0, 0)})
		activeCooldowns[eventName] = true
		tween.Completed:Connect(function()
			activeCooldowns[eventName] = nil
		end)
		tween:Play()
	end

	for _, otherButton in ipairs(backpack:GetChildren()) do
		if otherButton:IsA("ImageButton") and otherButton.Name ~= "Template" and otherButton.Name ~= "Sprint" and otherButton ~= button then

			local otherRemaining = CooldownManager.getRemaining(otherButton.Name)
			local otherVisualDuration = math.max(otherRemaining, attackDuration)
			local otherCharge = otherButton:FindFirstChild("Charge")
			if otherCharge then
				otherCharge.Size = UDim2.new(1, 0, -1, 0)
				local otherTween = TweenService:Create(otherCharge, TweenInfo.new(otherVisualDuration, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 0, 0)})
				otherTween:Play()
			end
		end
	end
end

local function buildButtons(character)
	clearButtons()
	activeButtons = {}
	slotToEvent = {}

	backpack.Size = UDim2.new(0, deviceSettings.backpackWidth, 0, deviceSettings.backpackHeight)
	backpack.Position = UDim2.new(0.5, -deviceSettings.backpackWidth / 2, 1, -deviceSettings.backpackHeight - 15)
	local barsFrame = backpack.Parent:FindFirstChild("Bars")
	if barsFrame then
		barsFrame.Position = UDim2.new(0.5, -185, 1, -deviceSettings.backpackHeight - 40)
	end
	if template then
		template.Size = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE)
		scaleButtonChildren(template)
	end

	local sprint = backpack:FindFirstChild("Sprint")

	local charScripts = character:FindFirstChild("CharacterScripts")
	if not charScripts then
		if sprint then sprint.Visible = false end
		return
	end

	if sprint then
		sprint.Size = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE)
		scaleButtonChildren(sprint)
		sprint.Visible = true
		local canFly = character:FindFirstChild("canFly")
		local isFlying = canFly and canFly.Value == true
		if isFlying then
			sprint.Image = SPRINT_IMAGE_FLYING
		else
			sprint.Image = SPRINT_IMAGE_NORMAL
		end

		local sprintTitle = sprint:FindFirstChild("Title")
		if sprintTitle then
			sprintTitle.Text = isFlying and "Fly" or "Sprint"
		end
		local sprintNum = sprint:FindFirstChild("Num")
		if sprintNum then
			sprintNum.Text = "SHIFT"
		end
	end

	local events = {}
	local seenSlots = {}

	local function addEvent(child)
		if not isAttackEvent(child) then return end
		local slot = ORDER[child.Name] or 99
		local dedupKey = (slot == 99) and child.Name or tostring(slot)
		if seenSlots[dedupKey] then return end
		seenSlots[dedupKey] = true
		table.insert(events, child)
	end

	for _, child in ipairs(charScripts:GetChildren()) do
		addEvent(child)
	end

	local animEvents = charScripts:FindFirstChild("AnimEvents")
	if animEvents then
		for _, child in ipairs(animEvents:GetChildren()) do
			addEvent(child)
		end
	end

	table.sort(events, function(a, b)
		return (ORDER[a.Name] or 99) < (ORDER[b.Name] or 99)
	end)

	local sprintCount = (sprint and sprint.Visible) and 1 or 0
	local totalButtons = #events + sprintCount
	local totalWidth = totalButtons * BUTTON_SIZE + math.max(totalButtons - 1, 0) * SPACING
	local backpackWidth = backpack.Size.X.Offset
	local startX = (backpackWidth - totalWidth) / 2

	for i, event in ipairs(events) do
		if template then
			local button = template:Clone()
			button.Name = event.Name
			button.Size = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE)
			button.Visible = true
			scaleButtonChildren(button)
			button.Parent = backpack
			activeButtons[event.Name] = button
			slotToEvent[ORDER[event.Name] or 99] = event.Name

			local attackImage = event:GetAttribute("AttackImage")
			if attackImage and attackImage ~= "" then
				button.Image = attackImage
			end

			local title = button:FindFirstChild("Title")
			if title then
				title.Text = getDisplayName(event)
			end

			local num = button:FindFirstChild("Num")
			if num then
				local eventName = event.Name
				if eventName == "Roar1" or eventName == "Roar1Event" then
					num.Text = "R"
				elseif eventName == "Roar2" or eventName == "Roar2Event" then
					num.Text = "T"
				else
					num.Text = NUMBERS[i] or tostring(i)
				end
			end

			button.Position = UDim2.new(0, startX + (i - 1) * (BUTTON_SIZE + SPACING), 0, 0)

			button.MouseButton1Click:Connect(function()
				fireAbility(event.Name)
			end)
		end
	end

	if sprint then
		sprint.Position = UDim2.new(0, startX + #events * (BUTTON_SIZE + SPACING), 0, 0)
	end

	return #events
end

local function onCharacterChanged(character)
	clearButtons()

	local connection
	connection = character.ChildAdded:Connect(function(child)
		if child.Name == "CharacterScripts" then
			connection:Disconnect()
			task.wait(0.2)
			buildButtons(character)

			child.ChildAdded:Connect(function(grandchild)
				if grandchild:IsA("RemoteEvent") then
					task.wait(0.1)
					buildButtons(character)
				end
			end)
			child.ChildRemoved:Connect(function()
				task.wait(0.1)
				buildButtons(character)
			end)
		end
	end)

	local existing = character:FindFirstChild("CharacterScripts")
	if existing then
		if connection then
			connection:Disconnect()
		end
		task.wait(0.2)
		buildButtons(character)

		existing.ChildAdded:Connect(function(child)
			if child:IsA("RemoteEvent") then
				task.wait(0.1)
				buildButtons(character)
			end
		end)
		existing.ChildRemoved:Connect(function()
			task.wait(0.1)
			buildButtons(character)
		end)
	end
end

local sprintActive = false

local function updateSprintVisual()
	local sprint = backpack:FindFirstChild("Sprint")
	if not sprint then return end
	local indicator = sprint:FindFirstChild("ActiveIndicator")
	if indicator then
		indicator.BackgroundTransparency = sprintActive and 0.5 or 1
	end
end

local function setSprintState(active)
	sprintActive = active
	updateSprintVisual()
end

local function getSprintRunningValue()
	local character = player.Character
	if not character then return nil end
	local control = character:FindFirstChild("Control")
	if not control then return nil end
	local runFolder = control:FindFirstChild("Run")
	if not runFolder then return nil end
	return runFolder:FindFirstChild("Running")
end

local function playSprintCooldownFill()
	local sprint = backpack:FindFirstChild("Sprint")
	if not sprint then return end
	local charge = sprint:FindFirstChild("Charge")
	if charge then
		charge.Size = UDim2.new(1, 0, -1, 0)
		local tween = TweenService:Create(charge, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 0, 0)})
		tween:Play()
	end
end

local function doSprintToggle()
	if not CooldownManager.canUse("Sprint") then return end
	local runningValue = getSprintRunningValue()
	if not runningValue then return end
	CooldownManager.start("Sprint", 0.5)
	playSprintCooldownFill()
	runningValue.Value = not runningValue.Value
	setSprintState(runningValue.Value)
end

local function doSprintStart()
	if not CooldownManager.canUse("Sprint") then return end
	local runningValue = getSprintRunningValue()
	if not runningValue then return end
	CooldownManager.start("Sprint", 0.5)
	playSprintCooldownFill()
	runningValue.Value = true
	setSprintState(true)
end

local function doSprintStop()
	local runningValue = getSprintRunningValue()
	if not runningValue then return end
	runningValue.Value = false
	setSprintState(false)
end

local sprintButton = backpack:FindFirstChild("Sprint")
if sprintButton then
	sprintButton.MouseButton1Click:Connect(doSprintToggle)
end

local function watchRunningValue(character)
	task.spawn(function()
		local control = character:WaitForChild("Control", 10)
		if not control then return end
		local runFolder = control:WaitForChild("Run", 5)
		if not runFolder then return end
		local runningValue = runFolder:WaitForChild("Running", 5)
		if not runningValue then return end

		runningValue:GetPropertyChangedSignal("Value"):Connect(function()
			if character == player.Character then
				setSprintState(runningValue.Value)
			end
		end)
		setSprintState(runningValue.Value)
	end)
end

if player.Character then
	onCharacterChanged(player.Character)
	watchRunningValue(player.Character)
	onCharacterDied(player.Character)
end

player.CharacterAdded:Connect(function(character)
	beamActive = false
	currentBeamGeneration = nil
	beamLockedYaw = nil
	if beamStartTimeout then
		task.cancel(beamStartTimeout)
		beamStartTimeout = nil
	end
	if beamDelayToken then
		task.cancel(beamDelayToken)
		beamDelayToken = nil
	end
	stopBeamRotation()
	stopBeamPrediction()
	CooldownManager.reset()
	ChargeManager.reset()
	activeCooldowns = {}
	setSprintState(false)
	onCharacterChanged(character)
	watchRunningValue(character)
	onCharacterDied(character)
end)

local KEY_TO_SLOT = {
	[Enum.KeyCode.R] = 5,
	[Enum.KeyCode.T] = 6,
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
}

local GAMEPAD_TO_SLOT = {
	[Enum.KeyCode.ButtonY] = 2,
	[Enum.KeyCode.ButtonX] = 1,
	[Enum.KeyCode.ButtonB] = 3,
	[Enum.KeyCode.ButtonR1] = 4,
	[Enum.KeyCode.DPadLeft] = 5,
	[Enum.KeyCode.DPadRight] = 6,
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	local slot = KEY_TO_SLOT[input.KeyCode] or GAMEPAD_TO_SLOT[input.KeyCode]
	if slot then
		local eventName = slotToEvent[slot]
		if eventName then
			fireAbility(eventName)
		end
	end
end)


UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.ButtonL3 then
		doSprintToggle()
	end
end)

