



local Trove = require(script.Parent.Parent.Trove)
local Signal = require(script.Parent.Parent.Signal)

local UserInputService = game:GetService("UserInputService")
local HapticService = game:GetService("HapticService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local function ApplyDeadzone(value: number, threshold: number): number
	if math.abs(value) < threshold then
		return 0
	end
	return ((math.abs(value) - threshold) / (1 - threshold)) * math.sign(value)
end

local function GetActiveGamepad(): Enum.UserInputType?
	local activeGamepad = nil
	local navGamepads = UserInputService:GetNavigationGamepads()
	if #navGamepads > 1 then
		for _, navGamepad in ipairs(navGamepads) do
			if activeGamepad == nil or navGamepad.Value < activeGamepad.Value then
				activeGamepad = navGamepad
			end
		end
	else
		local connectedGamepads = UserInputService:GetConnectedGamepads()
		for _, connectedGamepad in ipairs(connectedGamepads) do
			if activeGamepad == nil or connectedGamepad.Value < activeGamepad.Value then
				activeGamepad = connectedGamepad
			end
		end
	end
	if activeGamepad and not UserInputService:GetGamepadConnected(activeGamepad) then
		activeGamepad = nil
	end
	return activeGamepad
end

local function HeartbeatDelay(duration: number, callback: () -> nil): RBXScriptConnection
	local start = time()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local elapsed = time() - start
		if elapsed >= duration then
			connection:Disconnect()
			callback()
		end
	end)
	return connection
end


local Gamepad = {}
Gamepad.__index = Gamepad




















function Gamepad.new(gamepad: Enum.UserInputType?)
	local self = setmetatable({}, Gamepad)
	self._trove = Trove.new()
	self._gamepadTrove = self._trove:Construct(Trove)
	self.ButtonDown = self._trove:Construct(Signal)
	self.ButtonUp = self._trove:Construct(Signal)
	self.Connected = self._trove:Construct(Signal)
	self.Disconnected = self._trove:Construct(Signal)
	self.GamepadChanged = self._trove:Construct(Signal)
	self.DefaultDeadzone = 0.05
	self.SupportsVibration = false
	self.State = {}
	self:_setupGamepad(gamepad)
	self:_setupMotors()
	return self
end

function Gamepad:_setupActiveGamepad(gamepad: Enum.UserInputType?)
	local lastGamepad = self._gamepad
	if gamepad == lastGamepad then
		return
	end

	self._gamepadTrove:Clean()
	table.clear(self.State)
	self.SupportsVibration = if gamepad then HapticService:IsVibrationSupported(gamepad) else false

	self._gamepad = gamepad

	
	if not gamepad then
		self.Disconnected:Fire()
		self.GamepadChanged:Fire(nil)
		return
	end

	for _, inputObject in ipairs(UserInputService:GetGamepadState(gamepad)) do
		self.State[inputObject.KeyCode] = inputObject
	end

	self._gamepadTrove:Add(self, "StopMotors")

	self._gamepadTrove:Connect(UserInputService.InputBegan, function(input, processed)
		if input.UserInputType == gamepad then
			self.ButtonDown:Fire(input.KeyCode, processed)
		end
	end)

	self._gamepadTrove:Connect(UserInputService.InputEnded, function(input, processed)
		if input.UserInputType == gamepad then
			self.ButtonUp:Fire(input.KeyCode, processed)
		end
	end)

	if lastGamepad == nil then
		self.Connected:Fire()
	end
	self.GamepadChanged:Fire(gamepad)
end

function Gamepad:_setupGamepad(forcedGamepad: Enum.UserInputType?)
	if forcedGamepad then
		

		self._trove:Connect(UserInputService.GamepadConnected, function(gp)
			if gp == forcedGamepad then
				self:_setupActiveGamepad(forcedGamepad)
			end
		end)

		self._trove:Connect(UserInputService.GamepadDisconnected, function(gp)
			if gp == forcedGamepad then
				self:_setupActiveGamepad(nil)
			end
		end)

		if UserInputService:GetGamepadConnected(forcedGamepad) then
			self:_setupActiveGamepad(forcedGamepad)
		end
	else
		

		local function CheckToSetupActive()
			local active = GetActiveGamepad()
			if active ~= self._gamepad then
				self:_setupActiveGamepad(active)
			end
		end

		self._trove:Connect(UserInputService.GamepadConnected, CheckToSetupActive)
		self._trove:Connect(UserInputService.GamepadDisconnected, CheckToSetupActive)
		self:_setupActiveGamepad(GetActiveGamepad())
	end
end

function Gamepad:_setupMotors()
	self._setMotorIds = {}
	for _, motor in ipairs(Enum.VibrationMotor:GetEnumItems()) do
		self._setMotorIds[motor] = 0
	end
end


function Gamepad:GetThumbstick(thumbstick: Enum.KeyCode, deadzoneThreshold: number?): Vector2
	local pos = self.State[thumbstick].Position
	local deadzone = deadzoneThreshold or self.DefaultDeadzone
	return Vector2.new(ApplyDeadzone(pos.X, deadzone), ApplyDeadzone(pos.Y, deadzone))
end


function Gamepad:GetTrigger(trigger: Enum.KeyCode, deadzoneThreshold: number?): number
	return ApplyDeadzone(self.State[trigger].Position.Z, deadzoneThreshold or self.DefaultDeadzone)
end


function Gamepad:IsButtonDown(gamepadButton: Enum.KeyCode): boolean
	return UserInputService:IsGamepadButtonDown(self._gamepad, gamepadButton)
end


function Gamepad:IsMotorSupported(motor: Enum.VibrationMotor): boolean
	return HapticService:IsMotorSupported(self._gamepad, motor)
end


function Gamepad:SetMotor(motor: Enum.VibrationMotor, intensity: number): number
	self._setMotorIds[motor] += 1
	local id = self._setMotorIds[motor]
	HapticService:SetMotor(self._gamepad, motor, intensity)
	return id
end


function Gamepad:PulseMotor(motor: Enum.VibrationMotor, intensity: number, duration: number)
	local id = self:SetMotor(motor, intensity)
	local heartbeat = HeartbeatDelay(duration, function()
		if self._setMotorIds[motor] ~= id then
			return
		end
		self:StopMotor(motor)
	end)
	self._gamepadTrove:Add(heartbeat)
end


function Gamepad:StopMotor(motor: Enum.VibrationMotor)
	self:SetMotor(motor, 0)
end


function Gamepad:StopMotors()
	for _, motor in ipairs(Enum.VibrationMotor:GetEnumItems()) do
		if self:IsMotorSupported(motor) then
			self:StopMotor(motor)
		end
	end
end


function Gamepad:IsConnected(): boolean
	return if self._gamepad then UserInputService:GetGamepadConnected(self._gamepad) else false
end


function Gamepad:GetUserInputType(): Enum.UserInputType?
	return self._gamepad
end


function Gamepad:SetAutoSelectGui(enabled: boolean)
	GuiService.AutoSelectGuiEnabled = enabled
end


function Gamepad:IsAutoSelectGuiEnabled(): boolean
	return GuiService.AutoSelectGuiEnabled
end


function Gamepad:Destroy()
	self._trove:Destroy()
end

return Gamepad
