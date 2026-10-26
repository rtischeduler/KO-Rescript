local Players = game:GetService("Players")

local button = script.Parent
local player = Players.LocalPlayer
local isCountingDown = false

button.MouseButton1Click:Connect(function()
	if isCountingDown then return end

	isCountingDown = true
	local originalText = button.Text

	for i = 10, 0, -1 do
		button.Text = tostring(i)
		task.wait(1)
	end

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = 0
		end
	end

	button.Text = originalText
	isCountingDown = false
end)
