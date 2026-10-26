script.Parent.Visible = false
local uis = game:GetService("UserInputService")
local ismobile = uis.TouchEnabled

if not ismobile then return end

local player = game.Players.LocalPlayer

local RunButton = script.Parent:FindFirstChild("Run")
if RunButton then
	RunButton.MouseButton1Click:Connect(function()
		local character = player.Character
		if not character then return end
		local control = character:FindFirstChild("Control")
		if control then
			local runFolder = control:FindFirstChild("Run")
			if runFolder then
				local runningValue = runFolder:FindFirstChild("Running")
				if runningValue then
					runningValue.Value = true
				end
			end
		end
	end)
end

local WalkButton = script.Parent:FindFirstChild("Walk")
if WalkButton then
	WalkButton.MouseButton1Click:Connect(function()
		local character = player.Character
		if not character then return end
		local control = character:FindFirstChild("Control")
		if control then
			local runFolder = control:FindFirstChild("Run")
			if runFolder then
				local runningValue = runFolder:FindFirstChild("Running")
				if runningValue then
					runningValue.Value = false
				end
			end
		end
	end)
end
