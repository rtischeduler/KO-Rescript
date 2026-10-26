local Chat = game:GetService("Chat")
local ReplicatedModules = Chat:WaitForChild("ClientChatModules")
local ChatConstants = require(ReplicatedModules:WaitForChild("ChatConstants"))

local function Run(ChatService)

	local function MeCommandFilterFunction(speakerName, messageObj, channelName)
		local message = messageObj.Message
		if message and string.sub(message, 1, 4):lower() == "/me " then

			messageObj.MessageType = ChatConstants.MessageTypeMeCommand
		end
	end

	ChatService:RegisterFilterMessageFunction("me_command", MeCommandFilterFunction)
end

return Run
