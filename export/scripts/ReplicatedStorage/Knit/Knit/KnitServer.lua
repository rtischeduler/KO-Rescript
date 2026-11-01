
type Middleware = {
	Inbound: ServerMiddleware?,
	Outbound: ServerMiddleware?,
}


type ServerMiddlewareFn = (player: Player, args: { any }) -> (boolean, ...any)


type ServerMiddleware = { ServerMiddlewareFn }


type ServiceDef = {
	Name: string,
	Client: { [any]: any }?,
	Middleware: Middleware?,
	[any]: any,
}


type Service = {
	Name: string,
	Client: ServiceClient,
	KnitComm: any,
	[any]: any,
}


type ServiceClient = {
	Server: Service,
	[any]: any,
}


type KnitOptions = {
	Middleware: Middleware?,
}

local defaultOptions: KnitOptions = {
	Middleware = nil,
}

local selectedOptions = nil


local KnitServer = {}


KnitServer.Util = (script.Parent :: Instance).Parent

local SIGNAL_MARKER = newproxy(true)
getmetatable(SIGNAL_MARKER).__tostring = function()
	return "SIGNAL_MARKER"
end

local UNRELIABLE_SIGNAL_MARKER = newproxy(true)
getmetatable(UNRELIABLE_SIGNAL_MARKER).__tostring = function()
	return "UNRELIABLE_SIGNAL_MARKER"
end

local PROPERTY_MARKER = newproxy(true)
getmetatable(PROPERTY_MARKER).__tostring = function()
	return "PROPERTY_MARKER"
end

local knitRepServiceFolder = Instance.new("Folder")
knitRepServiceFolder.Name = "Services"

local Promise = require(KnitServer.Util.Promise)
local Comm = require(KnitServer.Util.Comm)
local ServerComm = Comm.ServerComm

local services: { [string]: Service } = {}
local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")

local function DoesServiceExist(serviceName: string): boolean
	local service: Service? = services[serviceName]

	return service ~= nil
end


function KnitServer.CreateService(serviceDef: ServiceDef): Service
	assert(type(serviceDef) == "table", `Service must be a table; got {type(serviceDef)}`)
	assert(type(serviceDef.Name) == "string", `Service.Name must be a string; got {type(serviceDef.Name)}`)
	assert(#serviceDef.Name > 0, "Service.Name must be a non-empty string")
	assert(not DoesServiceExist(serviceDef.Name), `Service "{serviceDef.Name}" already exists`)
	assert(not started, `Services cannot be created after calling "Knit.Start()"`)

	local service = serviceDef
	service.KnitComm = ServerComm.new(knitRepServiceFolder, serviceDef.Name)

	if type(service.Client) ~= "table" then
		service.Client = { Server = service }
	else
		if service.Client.Server ~= service then
			service.Client.Server = service
		end
	end

	services[service.Name] = service

	return service
end


function KnitServer.AddServices(parent: Instance): { Service }
	assert(not started, `Services cannot be added after calling "Knit.Start()"`)

	local addedServices = {}
	for _, v in parent:GetChildren() do
		if not v:IsA("ModuleScript") then
			continue
		end

		table.insert(addedServices, require(v))
	end

	return addedServices
end


function KnitServer.AddServicesDeep(parent: Instance): { Service }
	assert(not started, `Services cannot be added after calling "Knit.Start()"`)

	local addedServices = {}
	for _, v in parent:GetDescendants() do
		if not v:IsA("ModuleScript") then
			continue
		end

		table.insert(addedServices, require(v))
	end

	return addedServices
end


function KnitServer.GetService(serviceName: string): Service
	assert(started, "Cannot call GetService until Knit has been started")
	assert(type(serviceName) == "string", `ServiceName must be a string; got {type(serviceName)}`)

	return assert(services[serviceName], `Could not find service "{serviceName}"`) :: Service
end


function KnitServer.GetServices(): { [string]: Service }
	assert(started, "Cannot call GetServices until Knit has been started")

	return services
end


function KnitServer.CreateSignal()
	return SIGNAL_MARKER
end


function KnitServer.CreateUnreliableSignal()
	return UNRELIABLE_SIGNAL_MARKER
end


function KnitServer.CreateProperty(initialValue: any)
	return { PROPERTY_MARKER, initialValue }
end


function KnitServer.Start(options: KnitOptions?)
	if started then
		return Promise.reject("Knit already started")
	end

	started = true

	table.freeze(services)

	if options == nil then
		selectedOptions = defaultOptions
	else
		assert(typeof(options) == "table", `KnitOptions should be a table or nil; got {typeof(options)}`)
		selectedOptions = options
		for k, v in defaultOptions do
			if selectedOptions[k] == nil then
				selectedOptions[k] = v
			end
		end
	end

	return Promise.new(function(resolve)
		local knitMiddleware = if selectedOptions.Middleware ~= nil then selectedOptions.Middleware else {}

		
		for _, service in services do
			local middleware = if service.Middleware ~= nil then service.Middleware else {}
			local inbound = if middleware.Inbound ~= nil then middleware.Inbound else knitMiddleware.Inbound
			local outbound = if middleware.Outbound ~= nil then middleware.Outbound else knitMiddleware.Outbound

			service.Middleware = nil

			for k, v in service.Client do
				if type(v) == "function" then
					service.KnitComm:WrapMethod(service.Client, k, inbound, outbound)
				elseif v == SIGNAL_MARKER then
					service.Client[k] = service.KnitComm:CreateSignal(k, false, inbound, outbound)
				elseif v == UNRELIABLE_SIGNAL_MARKER then
					service.Client[k] = service.KnitComm:CreateSignal(k, true, inbound, outbound)
				elseif type(v) == "table" and v[1] == PROPERTY_MARKER then
					service.Client[k] = service.KnitComm:CreateProperty(k, v[2], inbound, outbound)
				end
			end
		end

		
		local promisesInitServices = {}
		for _, service in services do
			if type(service.KnitInit) == "function" then
				table.insert(
					promisesInitServices,
					Promise.new(function(r)
						debug.setmemorycategory(service.Name)
						service:KnitInit()
						r()
					end)
				)
			end
		end

		resolve(Promise.all(promisesInitServices))
	end):andThen(function()
		
		for _, service in services do
			if type(service.KnitStart) == "function" then
				task.spawn(function()
					debug.setmemorycategory(service.Name)
					service:KnitStart()
				end)
			end
		end

		startedComplete = true
		onStartedComplete:Fire()

		task.defer(function()
			onStartedComplete:Destroy()
		end)

		
		knitRepServiceFolder.Parent = script.Parent
	end)
end


function KnitServer.OnStart()
	if startedComplete then
		return Promise.resolve()
	else
		return Promise.fromEvent(onStartedComplete.Event)
	end
end

return KnitServer
