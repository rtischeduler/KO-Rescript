local ChatController = { Name = "Chat" }

local KILL_RICH = "rgb(255,80,80)"
local KILL_FALLBACK = Color3.fromRGB(255, 105, 85)
local GREEN_RICH = "rgb(0,255,100)"
local GREEN_FALLBACK = Color3.fromRGB(0, 255, 100)
local RED_RICH = "rgb(255,50,50)"
local RED_FALLBACK = Color3.fromRGB(255, 50, 50)

local function showSystemMessage(message, richColor, fallbackColor)
	local StarterGui = game:GetService("StarterGui")

	local success = pcall(function()
		local TextChatService = game:GetService("TextChatService")
		local channel = TextChatService.TextChannels:FindFirstChild("RBXSystem")
		if channel then
			channel:DisplaySystemMessage('<font color="' .. richColor .. '">' .. message .. "</font>")
		end
	end)

	if not success then
		pcall(function()
			StarterGui:SetCore("ChatMakeSystemMessage", {
				Text = message,
				Color = fallbackColor,
				Font = Enum.Font.GothamBold,
			})
		end)
	end
end

function ChatController:Start()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local framework = script:FindFirstAncestor("Client")
	local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Util"))
	local log = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Logger")).new("Chat")

	Util.spawn(log, "KillMessage", function()
		local killMessageEvent = ReplicatedStorage:WaitForChild("KillMessage")
		killMessageEvent.OnClientEvent:Connect(function(message)
			showSystemMessage(message, KILL_RICH, KILL_FALLBACK)
		end)
	end)

	Util.spawn(log, "EliminatorPopup", function()
		local eliminatorPopupEvent = ReplicatedStorage:WaitForChild("EliminatorPopup")
		eliminatorPopupEvent.OnClientEvent:Connect(function(message, colorType)
			if colorType == "green" then
				showSystemMessage(message, GREEN_RICH, GREEN_FALLBACK)
			else
				showSystemMessage(message, RED_RICH, RED_FALLBACK)
			end
		end)
	end)
end

return ChatController
