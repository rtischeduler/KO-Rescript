



local Trove = require(script.Parent.Parent.Trove)
local Signal = require(script.Parent.Parent.Signal)

local UserInputService = game:GetService("UserInputService")


local Touch = {}
Touch.__index = Touch













function Touch.new()
	local self = setmetatable({}, Touch)

	self._trove = Trove.new()

	self.TouchTap = self._trove:Construct(Signal.Wrap, UserInputService.TouchTap)
	self.TouchTapInWorld = self._trove:Construct(Signal.Wrap, UserInputService.TouchTapInWorld)
	self.TouchMoved = self._trove:Construct(Signal.Wrap, UserInputService.TouchMoved)
	self.TouchLongPress = self._trove:Construct(Signal.Wrap, UserInputService.TouchLongPress)
	self.TouchPan = self._trove:Construct(Signal.Wrap, UserInputService.TouchPan)
	self.TouchPinch = self._trove:Construct(Signal.Wrap, UserInputService.TouchPinch)
	self.TouchRotate = self._trove:Construct(Signal.Wrap, UserInputService.TouchRotate)
	self.TouchSwipe = self._trove:Construct(Signal.Wrap, UserInputService.TouchSwipe)
	self.TouchStarted = self._trove:Construct(Signal.Wrap, UserInputService.TouchStarted)
	self.TouchEnded = self._trove:Construct(Signal.Wrap, UserInputService.TouchEnded)

	return self
end


function Touch:IsTouchEnabled(): boolean
	return UserInputService.TouchEnabled
end


function Touch:Destroy()
	self._trove:Destroy()
end

return Touch
