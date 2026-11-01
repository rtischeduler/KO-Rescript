



local Comm = require(script.Parent)
local Types = require(script.Parent.Parent.Types)
local Util = require(script.Parent.Parent.Util)


local ClientComm = {}
ClientComm.__index = ClientComm





function ClientComm.new(parent: Instance, usePromise: boolean, namespace: string?)
	assert(not Util.IsServer, "ClientComm must be constructed from the client")
	assert(typeof(parent) == "Instance", "Parent must be of type Instance")
	local ns = Util.DefaultCommFolderName
	if namespace then
		ns = namespace
	end
	local folder: Instance? = parent:WaitForChild(ns, Util.WaitForChildTimeout)
	assert(folder ~= nil, "Could not find namespace for ClientComm in parent: " .. ns)
	local self = setmetatable({}, ClientComm)
	self._instancesFolder = folder
	self._usePromise = usePromise
	return self
end


function ClientComm:GetFunction(
	name: string,
	inboundMiddleware: Types.ClientMiddleware?,
	outboundMiddleware: Types.ClientMiddleware?
)
	return Comm.GetFunction(self._instancesFolder, name, self._usePromise, inboundMiddleware, outboundMiddleware)
end


function ClientComm:GetSignal(
	name: string,
	inboundMiddleware: Types.ClientMiddleware?,
	outboundMiddleware: Types.ClientMiddleware?
)
	return Comm.GetSignal(self._instancesFolder, name, inboundMiddleware, outboundMiddleware)
end


function ClientComm:GetProperty(
	name: string,
	inboundMiddleware: Types.ClientMiddleware?,
	outboundMiddleware: Types.ClientMiddleware?
)
	return Comm.GetProperty(self._instancesFolder, name, inboundMiddleware, outboundMiddleware)
end


function ClientComm:BuildObject(inboundMiddleware: Types.ClientMiddleware?, outboundMiddleware: Types.ClientMiddleware?)
	local obj = {}
	local rfFolder = self._instancesFolder:FindFirstChild("RF")
	local reFolder = self._instancesFolder:FindFirstChild("RE")
	local rpFolder = self._instancesFolder:FindFirstChild("RP")
	if rfFolder then
		for _, rf in rfFolder:GetChildren() do
			if not rf:IsA("RemoteFunction") then
				continue
			end
			local f = self:GetFunction(rf.Name, inboundMiddleware, outboundMiddleware)
			obj[rf.Name] = function(_self, ...)
				return f(...)
			end
		end
	end
	if reFolder then
		for _, re in reFolder:GetChildren() do
			if (not re:IsA("RemoteEvent")) and (not re:IsA("UnreliableRemoteEvent")) then
				continue
			end
			obj[re.Name] = self:GetSignal(re.Name, inboundMiddleware, outboundMiddleware)
		end
	end
	if rpFolder then
		for _, re in rpFolder:GetChildren() do
			if not re:IsA("RemoteEvent") then
				continue
			end
			obj[re.Name] = self:GetProperty(re.Name, inboundMiddleware, outboundMiddleware)
		end
	end
	return obj
end


function ClientComm:Destroy() end

return ClientComm
