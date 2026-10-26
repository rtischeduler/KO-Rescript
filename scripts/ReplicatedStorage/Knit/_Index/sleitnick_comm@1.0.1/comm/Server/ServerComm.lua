



local Comm = require(script.Parent)
local Types = require(script.Parent.Parent.Types)
local Util = require(script.Parent.Parent.Util)


local ServerComm = {}
ServerComm.__index = ServerComm





function ServerComm.new(parent: Instance, namespace: string?)
	assert(Util.IsServer, "ServerComm must be constructed from the server")
	assert(typeof(parent) == "Instance", "Parent must be of type Instance")
	local ns = Util.DefaultCommFolderName
	if namespace then
		ns = namespace
	end
	assert(not parent:FindFirstChild(ns), "Parent already has another ServerComm bound to namespace " .. ns)
	local self = setmetatable({}, ServerComm)
	self._instancesFolder = Instance.new("Folder")
	self._instancesFolder.Name = ns
	self._instancesFolder.Parent = parent
	return self
end


function ServerComm:BindFunction(
	name: string,
	fn: Types.FnBind,
	inboundMiddleware: Types.ServerMiddleware?,
	outboundMiddleware: Types.ServerMiddleware?
): RemoteFunction
	return Comm.BindFunction(self._instancesFolder, name, fn, inboundMiddleware, outboundMiddleware)
end


function ServerComm:WrapMethod(
	tbl: {},
	name: string,
	inboundMiddleware: Types.ServerMiddleware?,
	outboundMiddleware: Types.ServerMiddleware?
): RemoteFunction
	return Comm.WrapMethod(self._instancesFolder, tbl, name, inboundMiddleware, outboundMiddleware)
end


function ServerComm:CreateSignal(
	name: string,
	unreliable: boolean?,
	inboundMiddleware: Types.ServerMiddleware?,
	outboundMiddleware: Types.ServerMiddleware?
)
	return Comm.CreateSignal(self._instancesFolder, name, unreliable, inboundMiddleware, outboundMiddleware)
end


function ServerComm:CreateProperty(
	name: string,
	initialValue: any,
	inboundMiddleware: Types.ServerMiddleware?,
	outboundMiddleware: Types.ServerMiddleware?
)
	return Comm.CreateProperty(self._instancesFolder, name, initialValue, inboundMiddleware, outboundMiddleware)
end


function ServerComm:Destroy()
	self._instancesFolder:Destroy()
end

return ServerComm
