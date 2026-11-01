






export type InputType = "MouseKeyboard" | "Touch" | "Gamepad"

local UserInputService = game:GetService("UserInputService")

local touchUserInputType = Enum.UserInputType.Touch
local keyboardUserInputType = Enum.UserInputType.Keyboard

type PreferredInput = {
	Current: InputType,
	Observe: (handler: (inputType: InputType) -> ()) -> () -> (),
}





local PreferredInput: PreferredInput

local subscribers = {}

PreferredInput = {

	Current = "MouseKeyboard",

	Observe = function(handler: (inputType: InputType) -> ()): () -> ()
		if table.find(subscribers, handler) then
			error("function already subscribed", 2)
		end
		table.insert(subscribers, handler)

		task.spawn(handler, PreferredInput.Current)

		return function()
			local index = table.find(subscribers, handler)
			if index then
				local n = #subscribers
				subscribers[index], subscribers[n] = subscribers[n], nil
			end
		end
	end,
}

local function SetPreferred(preferred: InputType)
	if preferred == PreferredInput.Current then
		return
	end
	PreferredInput.Current = preferred

	for _, subscriber in subscribers do
		task.spawn(subscriber, preferred)
	end
end

local function DeterminePreferred(inputType: Enum.UserInputType)
	if inputType == touchUserInputType then
		SetPreferred("Touch")
	elseif inputType == keyboardUserInputType or string.sub(inputType.Name, 1, 5) == "Mouse" then
		SetPreferred("MouseKeyboard")
	elseif string.sub(inputType.Name, 1, 7) == "Gamepad" then
		SetPreferred("Gamepad")
	end
end

DeterminePreferred(UserInputService:GetLastInputType())
UserInputService.LastInputTypeChanged:Connect(DeterminePreferred)

return PreferredInput
