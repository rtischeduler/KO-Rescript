local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local function getCamera()
	return Workspace.CurrentCamera
end

local function waitForLocalPlayer()
	if player then return player end
	return Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

player = waitForLocalPlayer()

local function initDisableResetButton()
	task.wait(1)
	local success, err = pcall(function()
		StarterGui:SetCore("ResetButtonCallback", false)
	end)
	if not success then
		warn("Failed to disable reset button: " .. tostring(err))
	end
end

local function initOldCursor()
	local mouse = player:GetMouse()
	mouse.Icon = "http://www.roblox.com/asset/?id=7025168168"
end

local function initGamepassFriends()
	
end

local function initUnderwaterEffect()
	local blur = Lighting:FindFirstChild("UnderwaterBlur")
	local correction = Lighting:FindFirstChild("UnderwaterCorrection")

	if not blur or not correction then
		warn("UnderwaterEffect: UnderwaterBlur or UnderwaterCorrection not found in Lighting")
		return
	end

	local cachedOcean = nil
	RunService.RenderStepped:Connect(function()
		if not cachedOcean or not cachedOcean.Parent or cachedOcean.Parent ~= Workspace then
			cachedOcean = Workspace:FindFirstChild("Ocean")
		end
		local ocean = cachedOcean
		if ocean and ocean:IsA("BasePart") then
			local below = camera.CFrame.Position.Y < ocean.Position.Y
			if blur.Enabled ~= below then blur.Enabled = below end
			if correction.Enabled ~= below then correction.Enabled = below end
		end
	end)
end

local function initCameraToggle()
	local isConsole = GuiService:IsTenFootInterface()
	local maxZoomDistance = isConsole and 200 or 100
	local isHeadMode = false
	local currentHeadPart = nil
	local connections = {}

	local function findHeadPart(character)
		if not character then return nil end
		local fakeHead = character:FindFirstChild("FakeHead")
		if fakeHead and fakeHead:IsA("BasePart") then
			return fakeHead
		end
		local head = character:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			return head
		end
		local headPart = character:FindFirstChild("HeadPart")
		if headPart and headPart:IsA("BasePart") then
			return headPart
		end
		return nil
	end

	local function enforceMaxZoom()
		player.CameraMaxZoomDistance = maxZoomDistance
		player.CameraMinZoomDistance = 0.5
	end

	local function updateCameraSubject()
		if player:GetAttribute("MenuCameraActive") then return end
		local character = player.Character
		if not character then return end
		local cam = getCamera()
		if not cam then return end

		if isHeadMode then
			local headPart = findHeadPart(character)
			if headPart then
				currentHeadPart = headPart
				cam.CameraSubject = headPart
			else
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					cam.CameraSubject = humanoid
				end
				currentHeadPart = nil
			end
		else
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				cam.CameraSubject = humanoid
			end
			currentHeadPart = nil
		end
	end

	local function startHeadMonitor(character)
		if connections.headMonitor then
			connections.headMonitor:Disconnect()
		end
		connections.headMonitor = RunService.Heartbeat:Connect(function()
			if not isHeadMode then return end
			if player:GetAttribute("MenuCameraActive") then return end
			if not character or not character.Parent then return end
			if currentHeadPart and currentHeadPart.Parent then return end
			local newHeadPart = findHeadPart(character)
			if newHeadPart and newHeadPart ~= currentHeadPart then
				currentHeadPart = newHeadPart
				local cam = getCamera()
				if cam then
					cam.CameraSubject = newHeadPart
				end
			end
		end)
	end

	local function onCharacterAdded(character)
		enforceMaxZoom()
		updateCameraSubject()
		startHeadMonitor(character)
		character.ChildAdded:Connect(function(child)
			if isHeadMode and (child.Name == "FakeHead" or child.Name == "Head" or child.Name == "HeadPart") then
				if child:IsA("BasePart") and not player:GetAttribute("MenuCameraActive") then
					currentHeadPart = child
					local cam = getCamera()
					if cam then
						cam.CameraSubject = child
					end
				end
			end
			if child:IsA("Humanoid") then
				enforceMaxZoom()
			end
		end)
		character.ChildRemoved:Connect(function(child)
			if isHeadMode and child == currentHeadPart then
				task.wait(0.1)
				updateCameraSubject()
			end
		end)
	end


	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end

	RunService.Heartbeat:Connect(function()
		local detectedConsole = GuiService:IsTenFootInterface()
		if detectedConsole ~= isConsole then
			isConsole = detectedConsole
			maxZoomDistance = isConsole and 200 or 100
		end
		if player.CameraMaxZoomDistance ~= maxZoomDistance then
			player.CameraMaxZoomDistance = maxZoomDistance
		end
		if player.CameraMinZoomDistance ~= 0.5 then
			player.CameraMinZoomDistance = 0.5
		end
	end)
end

local function initShiftLock()
	local isMobile = UserInputService.TouchEnabled
	local isShiftLocked = false
	local renderConnection = nil
	local TARGET_OFFSET = Vector3.new(9.5, 1.5, 3.5)
	local OFFSET_RATE = 9
	local currentOffset = Vector3.new(0, 0, 0)
	local toggleTime = 0
	local function lerpAngle(a, b, t)
		local diff = (b - a + math.pi) % (2 * math.pi) - math.pi
		return a + diff * t
	end
	

	player:SetAttribute("ShiftLockEnabled", false)
	if not isMobile then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	local function getShiftLockButton()
		local gui = player:FindFirstChild("PlayerGui")
		if not gui then return nil end
		local gameGui = gui:FindFirstChild("GameGui")
		if not gameGui then return nil end
		local mainFrame = gameGui:FindFirstChild("MainFrame")
		if not mainFrame then return nil end
		local interface = mainFrame:FindFirstChild("Interface")
		if not interface then return nil end
		local mobile = interface:FindFirstChild("Mobile")
		if not mobile then return nil end
		return mobile:FindFirstChild("ShiftLock")
	end

	local function getCtrlLockButton()
		local gui = player:FindFirstChild("PlayerGui")
		if not gui then return nil end
		local gameGui = gui:FindFirstChild("GameGui")
		if not gameGui then return nil end
		local mainFrame = gameGui:FindFirstChild("MainFrame")
		if not mainFrame then return nil end
		local interface = mainFrame:FindFirstChild("Interface")
		if not interface then return nil end
		local buttons = interface:FindFirstChild("Buttons")
		if not buttons then return nil end
		return buttons:FindFirstChild("CtrlLock")
	end

	local function ensureRender()
		if renderConnection then return end
		renderConnection = RunService.RenderStepped:Connect(function(dt)
			dt = math.clamp(dt, 0, 0.1)
			local target = isShiftLocked and TARGET_OFFSET or Vector3.new(0, 0, 0)
			currentOffset = currentOffset:Lerp(target, 1 - math.exp(-OFFSET_RATE * dt))
			if isShiftLocked then
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local hrp = character and character:FindFirstChild("HumanoidRootPart")
				if humanoid and hrp then
					humanoid.AutoRotate = false
					local lookVector = camera.CFrame.LookVector
					local targetYaw = math.atan2(-lookVector.X, -lookVector.Z)
					local currentLook = hrp.CFrame.LookVector
					local currentYaw = math.atan2(-currentLook.X, -currentLook.Z)
					local t = math.clamp((tick() - toggleTime) / 0.35, 0, 1)
					local rate = 8 + 72 * t * t
					local yaw = lerpAngle(currentYaw, targetYaw, 1 - math.exp(-rate * dt))
					hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, yaw, 0)
				end
			end
			if currentOffset.Magnitude > 0.01 then
				camera.CFrame = camera.CFrame * CFrame.new(currentOffset)
			elseif not isShiftLocked then
				currentOffset = Vector3.new(0, 0, 0)
				if renderConnection then
					renderConnection:Disconnect()
					renderConnection = nil
				end
			end
		end)
	end

	local function stopRotation()
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.AutoRotate = true
			end
		end
	end

	local function startRotation()
		ensureRender()
	end

	local ctrlLockNormalImage = "rbxassetid://5044539836"
	local ctrlLockHoverImage = "rbxassetid://5044539486"

	local function updateCtrlLockVisuals()
		local button = getCtrlLockButton()
		if button then
			button.Image = isShiftLocked and ctrlLockHoverImage or ctrlLockNormalImage
		end
	end

	local function setShiftLock(enabled)
		isShiftLocked = enabled
		toggleTime = tick()
		player:SetAttribute("ShiftLockEnabled", enabled)
		if enabled then
			if not isMobile then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			end
			startRotation()
		else
			if not isMobile then
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			end
			stopRotation()
		end
		updateCtrlLockVisuals()
	end

	local function connectMobileButton()
		local button = getShiftLockButton()
		if button then
			button.MouseButton1Click:Connect(function()
				setShiftLock(not isShiftLocked)
			end)
			return true
		end
		return false
	end

	local function connectCtrlLockButton()
		local button = getCtrlLockButton()
		if button then
			button.MouseButton1Click:Connect(function()
				setShiftLock(not isShiftLocked)
			end)
			return true
		end
		return false
	end

	if not isMobile then
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
				setShiftLock(not isShiftLocked)
			end
		end)
	end

	player.CharacterAdded:Connect(function(character)
		task.wait(0.1)
		if isShiftLocked then
			startRotation()
		else
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.AutoRotate = true
			end
		end
	end)

	task.spawn(function()
		for i = 1, 20 do
			if connectMobileButton() then break end
			task.wait(0.5)
		end
	end)

	task.spawn(function()
		for i = 1, 20 do
			if connectCtrlLockButton() then break end
			task.wait(0.5)
		end
	end)

	if player.Character and isShiftLocked then
		startRotation()
	end
end

local function safeInit(name, func)
	local success, err = pcall(func)
	if not success then
		warn("ClientHandler: " .. name .. " failed: " .. tostring(err))
	end
end

task.spawn(function()
	safeInit("DisableResetButton", initDisableResetButton)
end)

task.spawn(function()
	safeInit("OldCursor", initOldCursor)
end)

task.spawn(function()
	safeInit("GamepassFriends", initGamepassFriends)
end)

task.spawn(function()
	safeInit("UnderwaterEffect", initUnderwaterEffect)
end)

task.spawn(function()
	safeInit("CameraToggle", initCameraToggle)
end)

task.spawn(function()
	safeInit("ShiftLock", initShiftLock)
end)

task.spawn(function()
	local CollectionService = game:GetService("CollectionService")
	local UserInputService = game:GetService("UserInputService")
	local okQuality, quality = pcall(function()
		return UserSettings().GameSettings.SavedQualityLevel.Value
	end)
	local lowEnd = UserInputService.TouchEnabled or (okQuality and quality > 0 and quality <= 4)
	local MAX_LIGHTS = lowEnd and 20 or 60
	local MAX_DISTANCE = lowEnd and 160 or 300
	local TAG = "BuildingGlowLight"
	local lights = {}
	local entries = {}

	local function add(light)
		if light:IsA("PointLight") then lights[light] = true end
	end

	for _, light in CollectionService:GetTagged(TAG) do add(light) end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(add)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(light)
		lights[light] = nil
	end)

	while true do
		task.wait(0.5)
		local cam = workspace.CurrentCamera
		if cam then
			local origin = cam.CFrame.Position
			table.clear(entries)
			for light in lights do
				local part = light.Parent
				if part and part:IsA("BasePart") then
					local d = (part.Position - origin).Magnitude
					if d <= MAX_DISTANCE then
						table.insert(entries, { light, d })
					elseif light.Enabled then
						light.Enabled = false
					end
				else
					lights[light] = nil
				end
			end
			table.sort(entries, function(a, b) return a[2] < b[2] end)
			for i, entry in entries do
				local on = i <= MAX_LIGHTS
				if entry[1].Enabled ~= on then entry[1].Enabled = on end
			end
		end
	end
end)
