



local Trove = require(script.Parent.Parent.Trove)
local Signal = require(script.Parent.Parent.Signal)

local UserInputService = game:GetService("UserInputService")


local Keyboard = {}
Keyboard.__index = Keyboard





function Keyboard.new()
	local self = setmetatable({}, Keyboard)
	self._trove = Trove.new()
	self.KeyDown = self._trove:Construct(Signal)
	self.KeyUp = self._trove:Construct(Signal)
	self:_setup()
	return self
end


function Keyboard:IsKeyDown(keyCode: Enum.KeyCode): boolean
	return UserInputService:IsKeyDown(keyCode)
end


function Keyboard:AreKeysDown(keyCodeOne: Enum.KeyCode, keyCodeTwo: Enum.KeyCode): boolean
	return self:IsKeyDown(keyCodeOne) and self:IsKeyDown(keyCodeTwo)
end


function Keyboard:AreEitherKeysDown(keyCodeOne: Enum.KeyCode, keyCodeTwo: Enum.KeyCode): boolean
	return self:IsKeyDown(keyCodeOne) or self:IsKeyDown(keyCodeTwo)
end

function Keyboard:_setup()
	self._trove:Connect(UserInputService.InputBegan, function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			self.KeyDown:Fire(input.KeyCode)
		end
	end)

	self._trove:Connect(UserInputService.InputEnded, function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			self.KeyUp:Fire(input.KeyCode)
		end
	end)
end


function Keyboard:Destroy()
	self._trove:Destroy()
end

return Keyboard
