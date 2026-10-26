
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local button = script.Parent
local event = ReplicatedStorage:WaitForChild("MorphSupplies"):WaitForChild("Events"):WaitForChild("Fire")
local morphs = ReplicatedStorage:WaitForChild("MorphSupplies"):WaitForChild("Morphs")

button.MouseButton1Click:Connect(function()
	local creatureValue = script.Parent.Parent.CharName.Text
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	local selectedCreature = morphs:FindFirstChild(creatureValue)
	if selectedCreature then
		event:FireServer(selectedCreature)
		end
	if not selectedCreature then
		warn("There was no model with that name. Make sure the string value is spelled EXACTLY like the morph's name!")
	end
	script.Parent.Parent.Parent.Visible = false
	wait(5)
	script.Parent.Parent.Parent.Parent.Parent.Parent.GameGui.MainFrame.Interface.Visible = true

	local player = Players.LocalPlayer
	local playerGui = player:FindFirstChild("PlayerGui")
	if playerGui then

		local touchGui = playerGui:FindFirstChild("TouchGui")
		if touchGui then
			touchGui.Enabled = true
		end

		local uis = game:GetService("UserInputService")
		if uis.TouchEnabled then
			local gameGui = playerGui:FindFirstChild("GameGui")
			if gameGui then
				local mainFrame = gameGui:FindFirstChild("MainFrame")
				if mainFrame then
					local interface = mainFrame:FindFirstChild("Interface")
					if interface then
						local mobile = interface:FindFirstChild("Mobile")
						if mobile then
							mobile.Visible = true
						end
					end
				end
			end
		end
	end
end)
