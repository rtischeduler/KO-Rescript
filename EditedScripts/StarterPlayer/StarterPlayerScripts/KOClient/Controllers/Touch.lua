local TouchController = { Name = "Touch" }

function TouchController:Start()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local UserInputService = game:GetService("UserInputService")

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local hasMorphed = false

	local function findMobileFrame()
		local gameGui = playerGui:FindFirstChild("GameGui")
		local mainFrame = gameGui and gameGui:FindFirstChild("MainFrame")
		local interface = mainFrame and mainFrame:FindFirstChild("Interface")
		return interface and interface:FindFirstChild("Mobile")
	end

	local function hideTouchControls()
		local touchGui = playerGui:FindFirstChild("TouchGui")
		if touchGui then
			touchGui.Enabled = false
		end

		local mobile = findMobileFrame()
		if mobile then
			mobile.Visible = false
		end
	end

	local function showTouchControls()
		local touchGui = playerGui:FindFirstChild("TouchGui")
		if touchGui then
			touchGui.Enabled = true
		end

		if UserInputService.TouchEnabled then
			local mobile = findMobileFrame()
			if mobile then
				mobile.Visible = true
			end
		end
	end

	hideTouchControls()

	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "TouchGui" and not hasMorphed then
			task.defer(function()
				child.Enabled = false
			end)
		end
	end)

	local function monitorTouchGui(touchGui)
		touchGui.Changed:Connect(function(prop)
			if prop == "Enabled" and not hasMorphed then
				if touchGui.Enabled then
					task.defer(function()
						if not hasMorphed then
							touchGui.Enabled = false
						end
					end)
				end
			end
		end)
	end

	local existingTouchGui = playerGui:FindFirstChild("TouchGui")
	if existingTouchGui then
		monitorTouchGui(existingTouchGui)
	end

	local morphSupplies = ReplicatedStorage:FindFirstChild("MorphSupplies")
	local events = morphSupplies and morphSupplies:FindFirstChild("Events")
	local fireEvent = events and events:FindFirstChild("Fire")
	if fireEvent then
		fireEvent.OnClientEvent:Connect(function()
			hasMorphed = true

			task.wait(1)
			showTouchControls()
		end)
	end

	player.CharacterAdded:Connect(function(character)
		task.wait(1)

		local kaijuValue = character:FindFirstChild("Kaiju")
		if kaijuValue then
			hasMorphed = true
			showTouchControls()
		end
	end)
end

return TouchController
