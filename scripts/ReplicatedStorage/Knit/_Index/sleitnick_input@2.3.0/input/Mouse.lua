



local Signal = require(script.Parent.Parent.Signal)
local Trove = require(script.Parent.Parent.Trove)

local UserInputService = game:GetService("UserInputService")

local RAY_DISTANCE = 1000


local Mouse = {}
Mouse.__index = Mouse











function Mouse.new()
	local self = setmetatable({}, Mouse)

	self._trove = Trove.new()

	self.LeftDown = self._trove:Construct(Signal)
	self.LeftUp = self._trove:Construct(Signal)
	self.RightDown = self._trove:Construct(Signal)
	self.RightUp = self._trove:Construct(Signal)
	self.MiddleDown = self._trove:Construct(Signal)
	self.MiddleUp = self._trove:Construct(Signal)
	self.Scrolled = self._trove:Construct(Signal)
	self.Moved = self._trove:Construct(Signal)

	self._trove:Connect(UserInputService.InputBegan, function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.LeftDown:Fire()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			self.RightDown:Fire()
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
			self.MiddleDown:Fire()
		end
	end)

	self._trove:Connect(UserInputService.InputEnded, function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.LeftUp:Fire()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			self.RightUp:Fire()
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
			self.MiddleUp:Fire()
		end
	end)

	self._trove:Connect(UserInputService.InputChanged, function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local position = input.Position
			self.Moved:Fire(Vector2.new(position.X, position.Y))
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			self.Scrolled:Fire(input.Position.Z)
		end
	end)

	return self
end


function Mouse:IsLeftDown(): boolean
	return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
end


function Mouse:IsRightDown(): boolean
	return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end


function Mouse:IsMiddleDown(): boolean
	return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton3)
end


function Mouse:GetPosition(): Vector2
	return UserInputService:GetMouseLocation()
end


function Mouse:GetDelta(): Vector2
	return UserInputService:GetMouseDelta()
end


function Mouse:GetRay(overridePos: Vector2?): Ray
	local mousePos = overridePos or UserInputService:GetMouseLocation()
	local viewportMouseRay = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y)
	return viewportMouseRay
end


function Mouse:Raycast(raycastParams: RaycastParams, distance: number?, overridePos: Vector2?): RaycastResult?
	local viewportMouseRay = self:GetRay(overridePos)
	local result = workspace:Raycast(
		viewportMouseRay.Origin,
		viewportMouseRay.Direction * (distance or RAY_DISTANCE),
		raycastParams
	)
	return result
end


function Mouse:Project(distance: number?, overridePos: Vector2?): Vector3
	local viewportMouseRay = self:GetRay(overridePos)
	return viewportMouseRay.Origin + (viewportMouseRay.Direction.Unit * (distance or RAY_DISTANCE))
end


function Mouse:Lock()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
end


function Mouse:LockCenter()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end


function Mouse:Unlock()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end


function Mouse:Destroy()
	self._trove:Destroy()
end

return Mouse
