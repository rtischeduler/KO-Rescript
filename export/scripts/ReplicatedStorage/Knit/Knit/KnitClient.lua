
type Middleware = {
	Inbound: ClientMiddleware?,
	Outbound: ClientMiddleware?,
}


type ClientMiddlewareFn = (args: { any }) -> (boolean, ...any)


type ClientMiddleware = { ClientMiddlewareFn }


type PerServiceMiddleware = { [string]: Middleware }


type ControllerDef = {
	Name: string,
	[any]: any,
}


type Controller = {
	Name: string,
	[any]: any,
}


type Service = {
	[any]: any,
}


type KnitOptions = {
	ServicePromises: boolean,
	Middleware: Middleware?,
	PerServiceMiddleware: PerServiceMiddleware?,
}

local defaultOptions: KnitOptions = {
	ServicePromises = true,
	Middleware = nil,
	PerServiceMiddleware = {},
}

local selectedOptions = nil


local KnitClient = {}


KnitClient.Player = game:GetService("Players").LocalPlayer


KnitClient.Util = (script.Parent :: Instance).Parent

local Promise = require(KnitClient.Util.Promise)
local Comm = require(KnitClient.Util.Comm)
local ClientComm = Comm.ClientComm

local controllers: { [string]: Controller } = {}
local services: { [string]: Service } = {}
local servicesFolder = nil

local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")

local function DoesControllerExist(controllerName: string): boolean
	local controller: Controller? = controllers[controllerName]

	return controller ~= nil
end

local function GetServicesFolder()
	if not servicesFolder then
		local parent = script.Parent :: Instance
		servicesFolder = parent:FindFirstChild("Services")
		if not servicesFolder then
			servicesFolder = parent:WaitForChild("Services", 30)
		end
	end

	return servicesFolder
end

local function GetMiddlewareForService(serviceName: string)
	local knitMiddleware = if selectedOptions.Middleware ~= nil then selectedOptions.Middleware else {}
	local serviceMiddleware = selectedOptions.PerServiceMiddleware[serviceName]

	return if serviceMiddleware ~= nil then serviceMiddleware else knitMiddleware
end

local function BuildService(serviceName: string)
	local folder = GetServicesFolder()
	local middleware = GetMiddlewareForService(serviceName)
	local clientComm = ClientComm.new(folder, selectedOptions.ServicePromises, serviceName)
	local service = clientComm:BuildObject(middleware.Inbound, middleware.Outbound)

	services[serviceName] = service

	return service
end


function KnitClient.CreateController(controllerDef: ControllerDef): Controller
	assert(type(controllerDef) == "table", `Controller must be a table; got {type(controllerDef)}`)
	assert(type(controllerDef.Name) == "string", `Controller.Name must be a string; got {type(controllerDef.Name)}`)
	assert(#controllerDef.Name > 0, "Controller.Name must be a non-empty string")
	assert(not DoesControllerExist(controllerDef.Name), `Controller {controllerDef.Name} already exists`)
	assert(not started, `Controllers cannot be created after calling "Knit.Start()"`)

	local controller = controllerDef :: Controller
	controllers[controller.Name] = controller

	return controller
end


function KnitClient.AddControllers(parent: Instance): { Controller }
	assert(not started, `Controllers cannot be added after calling "Knit.Start()"`)

	local addedControllers = {}
	for _, v in parent:GetChildren() do
		if not v:IsA("ModuleScript") then
			continue
		end

		table.insert(addedControllers, require(v))
	end

	return addedControllers
end


function KnitClient.AddControllersDeep(parent: Instance): { Controller }
	assert(not started, `Controllers cannot be added after calling "Knit.Start()"`)

	local addedControllers = {}
	for _, v in parent:GetDescendants() do
		if not v:IsA("ModuleScript") then
			continue
		end

		table.insert(addedControllers, require(v))
	end

	return addedControllers
end


function KnitClient.GetService(serviceName: string): Service
	local service = services[serviceName]
	if service then
		return service
	end

	assert(started, "Cannot call GetService until Knit has been started")
	assert(type(serviceName) == "string", `ServiceName must be a string; got {type(serviceName)}`)

	return BuildService(serviceName)
end


function KnitClient.GetController(controllerName: string): Controller
	local controller = controllers[controllerName]
	if controller then
		return controller
	end

	assert(started, "Cannot call GetController until Knit has been started")
	assert(type(controllerName) == "string", `ControllerName must be a string; got {type(controllerName)}`)
	error(`Could not find controller "{controllerName}". Check to verify a controller with this name exists.`, 2)
end


function KnitClient.GetControllers(): { [string]: Controller }
	assert(started, "Cannot call GetControllers until Knit has been started")

	return controllers
end


function KnitClient.Start(options: KnitOptions?)
	if started then
		return Promise.reject("Knit already started")
	end

	started = true

	table.freeze(controllers)

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
	if type(selectedOptions.PerServiceMiddleware) ~= "table" then
		selectedOptions.PerServiceMiddleware = {}
	end

	return Promise.new(function(resolve)
		
		local promisesStartControllers = {}

		for _, controller in controllers do
			if type(controller.KnitInit) == "function" then
				table.insert(
					promisesStartControllers,
					Promise.new(function(r)
						debug.setmemorycategory(controller.Name)
						controller:KnitInit()
						r()
					end)
				)
			end
		end

		resolve(Promise.all(promisesStartControllers))
	end):andThen(function()
		
		for _, controller in controllers do
			if type(controller.KnitStart) == "function" then
				task.spawn(function()
					debug.setmemorycategory(controller.Name)
					controller:KnitStart()
				end)
			end
		end

		startedComplete = true
		onStartedComplete:Fire()

		task.defer(function()
			onStartedComplete:Destroy()
		end)
	end)
end


function KnitClient.OnStart()
	if startedComplete then
		return Promise.resolve()
	else
		return Promise.fromEvent(onStartedComplete.Event)
	end
end

return KnitClient
