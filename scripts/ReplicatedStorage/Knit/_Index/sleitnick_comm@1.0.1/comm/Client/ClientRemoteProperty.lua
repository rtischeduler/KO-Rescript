



local Promise = require(script.Parent.Parent.Parent.Promise)
local Signal = require(script.Parent.Parent.Parent.Signal)
local ClientRemoteSignal = require(script.Parent.ClientRemoteSignal)
local Types = require(script.Parent.Parent.Types)




local ClientRemoteProperty = {}
ClientRemoteProperty.__index = ClientRemoteProperty

function ClientRemoteProperty.new(
	re: RemoteEvent,
	inboundMiddleware: Types.ClientMiddleware?,
	outboudMiddleware: Types.ClientMiddleware?
)
	local self = setmetatable({}, ClientRemoteProperty)
	self._rs = ClientRemoteSignal.new(re, inboundMiddleware, outboudMiddleware)
	self._ready = false
	self._value = nil
	self.Changed = Signal.new()
	self._rs:Fire()

	local resolveOnReadyPromise
	self._readyPromise = Promise.new(function(resolve)
		resolveOnReadyPromise = resolve
	end)
	self._changed = self._rs:Connect(function(value)
		local changed = value ~= self._value
		self._value = value
		if not self._ready then
			self._ready = true
			resolveOnReadyPromise(value)
		end
		if changed then
			self.Changed:Fire(value)
		end
	end)

	return self
end


function ClientRemoteProperty:Get(): any
	return self._value
end


function ClientRemoteProperty:OnReady()
	return self._readyPromise
end


function ClientRemoteProperty:IsReady(): boolean
	return self._ready
end


function ClientRemoteProperty:Observe(observer: (any) -> ())
	if self._ready then
		task.defer(observer, self._value)
	end
	return self.Changed:Connect(observer)
end


function ClientRemoteProperty:Destroy()
	self._rs:Destroy()
	if self._readyPromise then
		self._readyPromise:cancel()
	end
	if self._changed then
		self._changed:Disconnect()
	end
	self.Changed:Destroy()
end

return ClientRemoteProperty
