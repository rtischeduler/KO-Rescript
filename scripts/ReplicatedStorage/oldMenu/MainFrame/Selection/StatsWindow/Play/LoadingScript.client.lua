local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local button = script.Parent
local player = Players.LocalPlayer

button.MouseButton1Click:Connect(function()
	local playerGui = player:WaitForChild("PlayerGui")
	local gameGui = playerGui:FindFirstChild("GameGui")

	if not gameGui then
		warn("GameGui not found in PlayerGui")
		return
	end

	local mainFrame = gameGui:FindFirstChild("MainFrame")
	if not mainFrame then
		warn("MainFrame not found in GameGui")
		return
	end

	local loading = mainFrame:FindFirstChild("Loading")
	if not loading then
		warn("Loading not found in MainFrame")
		return
	end

	local textLabel = loading:FindFirstChild("TextLabel")

	loading.Visible = true
	local slideInTween = TweenService:Create(loading, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
	})
	slideInTween:Play()

	task.wait(2.5)

	local fadeInfo = TweenInfo.new(
		1,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	local slideInTween = TweenService:Create(loading, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 1, 0),
	})
	slideInTween:Play()

	local backgroundTween = TweenService:Create(loading, fadeInfo, {
     	BackgroundTransparency = 0
	})
	backgroundTween:Play()

	if textLabel then
		local textTween = TweenService:Create(textLabel, fadeInfo, {
			TextTransparency = 0
		})
		textTween:Play()

		textTween.Completed:Connect(function()
			loading.Visible = false

			loading.BackgroundTransparency = 0
			if textLabel then
				textLabel.TextTransparency = 0
			end
		end)
	else

		backgroundTween.Completed:Connect(function()
			loading.Visible = false
			loading.BackgroundTransparency = 0
		end)
	end
end)
