local MenuController = { Name = "Menu" }

local function unlockEntity(cfg)
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer

	if player.Name ~= cfg.EntityUnlockUser then
		return
	end

	local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 10)
	if not playerGui then
		return
	end

	local newMenu = playerGui:FindFirstChild("NEWMenu") or playerGui:WaitForChild("NEWMenu", 10)
	if not newMenu then
		return
	end

	local kaijus = newMenu:FindFirstChild("Kaijus")
	local list = kaijus and kaijus:FindFirstChild("List")
	local scrollFrame = list and list:FindFirstChild("ScrollingFrame")

	if scrollFrame then
		local entityEntry = scrollFrame:FindFirstChild("ENTITY")
		if entityEntry then
			entityEntry.Visible = true
		end
	end
end

local function runMenuCamera(cfg)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local Workspace = game:GetService("Workspace")
	local StarterGui = game:GetService("StarterGui")
	local TweenService = game:GetService("TweenService")

	local tweenInfo = TweenInfo.new(cfg.TweenSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local player = Players.LocalPlayer

	local camPoints = Workspace:FindFirstChild("CamPoints") or Workspace:WaitForChild("CamPoints", 15)
	local menuCam = camPoints and (camPoints:FindFirstChild("Menu") or camPoints:WaitForChild("Menu", 5))

	local newMenuTemplate = StarterGui:FindFirstChild("NEWMenu") or StarterGui:WaitForChild("NEWMenu", 10)
	local gameGuiTemplate = StarterGui:FindFirstChild("GameGui") or StarterGui:WaitForChild("GameGui", 10)

	local enforcing = false
	local renderName = cfg.CameraName

	player:SetAttribute("HasMorphed", false)

	local function applyMenuCamera()
		local cam = Workspace.CurrentCamera
		if cam and menuCam then
			cam.CameraType = Enum.CameraType.Scriptable
			cam.CFrame = menuCam.CFrame
			return true
		end
		return false
	end

	local function startEnforcing()
		if enforcing or not menuCam then
			return
		end
		enforcing = true
		player:SetAttribute("MenuCameraActive", true)

		applyMenuCamera()

		pcall(function()
			RunService:UnbindFromRenderStep(renderName)
		end)
		RunService:BindToRenderStep(renderName, Enum.RenderPriority.Camera.Value + cfg.CameraPriorityOffset, function()
			if enforcing then
				applyMenuCamera()
			end
		end)
	end

	local function stopEnforcing()
		enforcing = false
		player:SetAttribute("MenuCameraActive", false)
		pcall(function()
			RunService:UnbindFromRenderStep(renderName)
		end)
		local cam = Workspace.CurrentCamera
		if cam then
			cam.CameraType = Enum.CameraType.Custom
		end
	end

	local function disableMenuGuis()
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			for _, menuGui in ipairs(playerGui:GetChildren()) do
				if menuGui:IsA("ScreenGui") and (menuGui.Name == "NEWMenu" or menuGui.Name == "oldMenu") then
					menuGui.Enabled = false
				end
			end
		end
	end

	local function cloneNewMenu(parentGui)
		if not newMenuTemplate then
			return
		end
		local cloned = newMenuTemplate:Clone()
		cloned.Enabled = true

		local mainMenu = cloned:FindFirstChild("MainMenu")
		if mainMenu then
			mainMenu.Visible = true
			mainMenu.Position = UDim2.new(0, 0, -1, 0)
		end
		cloned.Parent = parentGui
	end

	local function cloneGameGui(parentGui)
		if not gameGuiTemplate then
			return
		end
		local cloned = gameGuiTemplate:Clone()

		local mainFrame = cloned:FindFirstChild("MainFrame")
		if mainFrame then
			local interface = mainFrame:FindFirstChild("Interface")
			if interface then
				interface.Visible = false
			end
			local loading = mainFrame:FindFirstChild("Loading")
			if loading then
				loading.Visible = false
				loading.Position = UDim2.new(0, 0, -1, 0)
			end
		end
		cloned.Parent = parentGui
	end

	local function ensureGuiCloned(playerGui, guiName, template, cloneFunc)
		if playerGui:FindFirstChild(guiName) then
			return
		end
		if not template then
			return
		end

		cloneFunc(playerGui)

		local count = 0
		for _, child in ipairs(playerGui:GetChildren()) do
			if child.Name == guiName then
				count = count + 1
				if count > 1 then
					child:Destroy()
				end
			end
		end

		local ourInstance = playerGui:FindFirstChild(guiName)
		if ourInstance then
			local conn
			conn = playerGui.ChildAdded:Connect(function(child)
				if child.Name == guiName and child ~= ourInstance and ourInstance.Parent then
					child:Destroy()
				end
			end)
			task.delay(15, function()
				if conn then
					conn:Disconnect()
				end
			end)
		end
	end

	local function onDeath(deadCharacter)
		if player:GetAttribute("IsMorphing") then
			player:SetAttribute("IsMorphing", false)
			return
		end

		if player.Character and player.Character ~= deadCharacter and not player:GetAttribute("ReturnToMenu") then
			return
		end

		player:SetAttribute("HasMorphed", false)

		local playerGui = player:FindFirstChild("PlayerGui")
		if not playerGui then
			return
		end

		local gameGui = playerGui:FindFirstChild("GameGui")
		if gameGui then
			gameGui.Enabled = false
			local mainFrame = gameGui:FindFirstChild("MainFrame")
			if mainFrame then
				local interface = mainFrame:FindFirstChild("Interface")
				if interface then
					interface.Visible = false
				end
			end
		end

		local touchGui = playerGui:FindFirstChild("TouchGui")
		if touchGui then
			touchGui.Enabled = false
		end

		task.wait(cfg.DeathReturnDelay)

		if player:GetAttribute("HasMorphed") then
			return
		end

		startEnforcing()

		player:SetAttribute("ReturnToMenu", false)

		playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			local existingMenu = playerGui:FindFirstChild("NEWMenu")
			if not existingMenu and newMenuTemplate then
				cloneNewMenu(playerGui)
				existingMenu = playerGui:FindFirstChild("NEWMenu")
			end

			if existingMenu then
				existingMenu.Enabled = true
				local mainMenu = existingMenu:FindFirstChild("MainMenu")
				if mainMenu then
					mainMenu.Visible = true
					mainMenu.Position = UDim2.new(0, 0, -1, 0)
					TweenService:Create(mainMenu, tweenInfo, {
						Position = UDim2.new(0, 0, 0, 0),
					}):Play()
				end

				local kaijusFrame = existingMenu:FindFirstChild("Kaijus")
				if kaijusFrame then
					kaijusFrame.Visible = true
					kaijusFrame.Position = UDim2.new(1.1, 0, 0, 0)
				end
			end
		end
	end

	local function onCharacterAdded(character)
		local morphWasRequested = player:GetAttribute("IsMorphing") == true
		if morphWasRequested or player:GetAttribute("HasMorphed") == true then
			stopEnforcing()
			disableMenuGuis()
		end
		player:SetAttribute("IsMorphing", false)

		if player:GetAttribute("HasMorphed") then
			stopEnforcing()
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)

		if humanoid then
			humanoid.Died:Connect(function()
				task.spawn(onDeath, character)
			end)
		end
	end

	player:SetAttribute("HasMorphed", false)
	startEnforcing()

	task.spawn(function()
		for _ = 1, 10 do
			task.wait(0.5)
			if not enforcing then
				return
			end
			local cam = Workspace.CurrentCamera
			if cam and cam.CameraType == Enum.CameraType.Scriptable then
				return
			end
			applyMenuCamera()
		end
	end)

	task.spawn(function()
		local playerGui = player:WaitForChild("PlayerGui", 10)
		if not playerGui then
			return
		end

		task.wait(0.5)

		ensureGuiCloned(playerGui, "NEWMenu", newMenuTemplate, cloneNewMenu)

		ensureGuiCloned(playerGui, "GameGui", gameGuiTemplate, cloneGameGui)

		local gameGui = playerGui:FindFirstChild("GameGui")
		if gameGui then
			gameGui.Enabled = false
			local mainFrame = gameGui:FindFirstChild("MainFrame")
			if mainFrame then
				local interface = mainFrame:FindFirstChild("Interface")
				if interface then
					interface.Visible = false
				end
				local loading = mainFrame:FindFirstChild("Loading")
				if loading then
					loading.Visible = false
					loading.Position = UDim2.new(0, 0, -1, 0)
				end
			end
		end

		task.wait(0.2)
		local newMenu = playerGui:FindFirstChild("NEWMenu")
		if newMenu then
			newMenu.Enabled = true
			local mainMenu = newMenu:FindFirstChild("MainMenu")
			if mainMenu and mainMenu.Position.Y.Scale < -0.5 then
				mainMenu.Visible = true
				mainMenu.Position = UDim2.new(0, 0, -1, 0)
				TweenService:Create(mainMenu, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(0, 0, 0, 0),
				}):Play()
			end
		end
	end)

	player.CharacterAdded:Connect(onCharacterAdded)

	player:GetAttributeChangedSignal("HasMorphed"):Connect(function()
		if player:GetAttribute("HasMorphed") == true then
			stopEnforcing()
			disableMenuGuis()
		end
	end)

	if player.Character then
		onCharacterAdded(player.Character)
	end
end

function MenuController:Start()
	local framework = script:FindFirstAncestor("Client")
	local cfg = require(framework.Config).Menu
	local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Util"))
	local log = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Logger")).new("Menu")

	Util.spawn(log, "EntityUnlock", unlockEntity, cfg)
	Util.spawn(log, "MenuCamera", runMenuCamera, cfg)
end

return MenuController
