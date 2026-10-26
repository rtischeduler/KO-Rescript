local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local eliminatorPopupEvent = ReplicatedStorage:WaitForChild("EliminatorPopup")

eliminatorPopupEvent.OnClientEvent:Connect(function(message, colorType)
	
	local rgb
	if colorType == "green" then
		rgb = "rgb(0,255,100)"
	else
		rgb = "rgb(255,50,50)"
	end

	local success = pcall(function()
		local TextChatService = game:GetService("TextChatService")
		local channel = TextChatService.TextChannels:FindFirstChild("RBXSystem")
		if channel then
			local coloredMessage = '<font color="' .. rgb .. '">' .. message .. '</font>'
			channel:DisplaySystemMessage(coloredMessage)
			return
		end
	end)

	if not success then
		pcall(function()
			StarterGui:SetCore("ChatMakeSystemMessage", {
				Text = message,
				Color = (colorType == "green") and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50),
				Font = Enum.Font.GothamBold,
			})
		end)
	end
end)