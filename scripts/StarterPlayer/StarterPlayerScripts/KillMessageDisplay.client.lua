local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local killMessageEvent = ReplicatedStorage:WaitForChild("KillMessage")

killMessageEvent.OnClientEvent:Connect(function(message)

	local success = pcall(function()
		local TextChatService = game:GetService("TextChatService")
		local channel = TextChatService.TextChannels:FindFirstChild("RBXSystem")
		if channel then
			local coloredMessage = '<font color="rgb(255,80,80)">' .. message .. '</font>'
			channel:DisplaySystemMessage(coloredMessage)
			return
		end
	end)

	if not success then
		pcall(function()
			StarterGui:SetCore("ChatMakeSystemMessage", {
				Text = message,
				Color = Color3.fromRGB(255, 105, 85),
				Font = Enum.Font.GothamBold,
			})
		end)
	end
end)
