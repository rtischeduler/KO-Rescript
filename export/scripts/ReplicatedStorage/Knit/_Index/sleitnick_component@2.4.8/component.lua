



type AncestorList = { Instance }


type ExtensionFn = (any) -> ()


type ExtensionShouldFn = (any) -> boolean


type Extension = {
	ShouldExtend: ExtensionShouldFn?,
	ShouldConstruct: ExtensionShouldFn?,
	Constructing: ExtensionFn?,
	Constructed: ExtensionFn?,
	Starting: ExtensionFn?,
	Started: ExtensionFn?,
	Stopping: ExtensionFn?,
	Stopped: ExtensionFn?,
}


type ComponentConfig = {
	Tag: string,
	Ancestors: AncestorList?,
	Extensions: { Extension }?,
}







local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Promise)
local Signal = require(script.Parent.Signal)
local Symbol = require(script.Parent.Symbol)
local Trove = require(script.Parent.Trove)

local IS_SERVER = RunService:IsServer()
local DEFAULT_ANCESTORS = { workspace, game:GetService("Players") }
local DEFAULT_TIMEOUT = 60


local KEY_ANCESTORS = Symbol("Ancestors")
local KEY_INST_TO_COMPONENTS = Symbol("InstancesToComponents")
local KEY_LOCK_CONSTRUCT = Symbol("LockConstruct")
local KEY_COMPONENTS = Symbol("Components")
local KEY_TROVE = Symbol("Trove")
local KEY_EXTENSIONS = Symbol("Extensions")
local KEY_ACTIVE_EXTENSIONS = Symbol("ActiveExtensions")
local KEY_STARTING = Symbol("Starting")
local KEY_STARTED = Symbol("Started")

local renderId = 0
local function NextRenderName(): string
	renderId += 1
	return "ComponentRender" .. tostring(renderId)
end

local function InvokeExtensionFn(component, fnName: string)
	for _, extension in ipairs(component[KEY_ACTIVE_EXTENSIONS]) do
		local fn = extension[fnName]
		if type(fn) == "function" then
			fn(component)
		end
	end
end

local function ShouldConstruct(component): boolean
	for _, extension in ipairs(component[KEY_ACTIVE_EXTENSIONS]) do
		local fn = extension.ShouldConstruct
		if type(fn) == "function" then
			local shouldConstruct = fn(component)
			if not shouldConstruct then
				return false
			end
		end
	end
	return true
end

local function GetActiveExtensions(component, extensionList)
	local activeExtensions = table.create(#extensionList)
	local allActive = true
	for _, extension in ipairs(extensionList) do
		local fn = extension.ShouldExtend
		local shouldExtend = type(fn) ~= "function" or not not fn(component)
		if shouldExtend then
			table.insert(activeExtensions, extension)
		else
			allActive = false
		end
	end
	return if allActive then extensionList else activeExtensions
end


local Component = {}
Component.__index = Component


function Component.new(config: ComponentConfig)
	local customComponent = {}
	customComponent.__index = customComponent
	customComponent.__tostring = function()
		return "Component<" .. config.Tag .. ">"
	end
	customComponent[KEY_ANCESTORS] = config.Ancestors or DEFAULT_ANCESTORS
	customComponent[KEY_INST_TO_COMPONENTS] = {}
	customComponent[KEY_COMPONENTS] = {}
	customComponent[KEY_LOCK_CONSTRUCT] = {}
	customComponent[KEY_TROVE] = Trove.new()
	customComponent[KEY_EXTENSIONS] = config.Extensions or {}
	customComponent[KEY_STARTED] = false
	customComponent.Tag = config.Tag
	customComponent.Started = customComponent[KEY_TROVE]:Construct(Signal)
	customComponent.Stopped = customComponent[KEY_TROVE]:Construct(Signal)
	setmetatable(customComponent, Component)
	customComponent:_setup()
	return customComponent
end

function Component:_instantiate(instance: Instance)
	local component = setmetatable({}, self)
	component.Instance = instance
	component[KEY_ACTIVE_EXTENSIONS] = GetActiveExtensions(component, self[KEY_EXTENSIONS])
	if not ShouldConstruct(component) then
		return nil
	end
	InvokeExtensionFn(component, "Constructing")
	if type(component.Construct) == "function" then
		component:Construct()
	end
	InvokeExtensionFn(component, "Constructed")
	return component
end

function Component:_setup()
	local watchingInstances = {}

	local function StartComponent(component)
		component[KEY_STARTING] = coroutine.running()

		InvokeExtensionFn(component, "Starting")

		component:Start()
		if component[KEY_STARTING] == nil then
			
			return
		end

		InvokeExtensionFn(component, "Started")

		local hasHeartbeatUpdate = typeof(component.HeartbeatUpdate) == "function"
		local hasSteppedUpdate = typeof(component.SteppedUpdate) == "function"
		local hasRenderSteppedUpdate = typeof(component.RenderSteppedUpdate) == "function"

		if hasHeartbeatUpdate then
			component._heartbeatUpdate = RunService.Heartbeat:Connect(function(dt)
				component:HeartbeatUpdate(dt)
			end)
		end

		if hasSteppedUpdate then
			component._steppedUpdate = RunService.Stepped:Connect(function(_, dt)
				component:SteppedUpdate(dt)
			end)
		end

		if hasRenderSteppedUpdate and not IS_SERVER then
			if component.RenderPriority then
				component._renderName = NextRenderName()
				RunService:BindToRenderStep(component._renderName, component.RenderPriority, function(dt)
					component:RenderSteppedUpdate(dt)
				end)
			else
				component._renderSteppedUpdate = RunService.RenderStepped:Connect(function(dt)
					component:RenderSteppedUpdate(dt)
				end)
			end
		end

		component[KEY_STARTED] = true
		component[KEY_STARTING] = nil

		self.Started:Fire(component)
	end

	local function StopComponent(component)
		if component[KEY_STARTING] then
			
			local startThread = component[KEY_STARTING]
			if coroutine.status(startThread) ~= "normal" then
				pcall(function()
					task.cancel(startThread)
				end)
			else
				task.defer(function()
					pcall(function()
						task.cancel(startThread)
					end)
				end)
			end
			component[KEY_STARTING] = nil
		end

		if component._heartbeatUpdate then
			component._heartbeatUpdate:Disconnect()
		end

		if component._steppedUpdate then
			component._steppedUpdate:Disconnect()
		end

		if component._renderSteppedUpdate then
			component._renderSteppedUpdate:Disconnect()
		elseif component._renderName then
			RunService:UnbindFromRenderStep(component._renderName)
		end

		InvokeExtensionFn(component, "Stopping")
		component:Stop()
		InvokeExtensionFn(component, "Stopped")
		self.Stopped:Fire(component)
	end

	local function SafeConstruct(instance, id)
		if self[KEY_LOCK_CONSTRUCT][instance] ~= id then
			return nil
		end
		local component = self:_instantiate(instance)
		if self[KEY_LOCK_CONSTRUCT][instance] ~= id then
			return nil
		end
		return component
	end

	local function TryConstructComponent(instance)
		if self[KEY_INST_TO_COMPONENTS][instance] then
			return
		end
		local id = self[KEY_LOCK_CONSTRUCT][instance] or 0
		id += 1
		self[KEY_LOCK_CONSTRUCT][instance] = id
		task.defer(function()
			local component = SafeConstruct(instance, id)
			if not component then
				return
			end
			self[KEY_INST_TO_COMPONENTS][instance] = component
			table.insert(self[KEY_COMPONENTS], component)
			task.defer(function()
				if self[KEY_INST_TO_COMPONENTS][instance] == component then
					StartComponent(component)
				end
			end)
		end)
	end

	local function TryDeconstructComponent(instance)
		local component = self[KEY_INST_TO_COMPONENTS][instance]
		if not component then
			return
		end
		self[KEY_INST_TO_COMPONENTS][instance] = nil
		self[KEY_LOCK_CONSTRUCT][instance] = nil
		local components = self[KEY_COMPONENTS]
		local index = table.find(components, component)
		if index then
			local n = #components
			components[index] = components[n]
			components[n] = nil
		end
		if component[KEY_STARTED] or component[KEY_STARTING] then
			task.spawn(StopComponent, component)
		end
	end

	local function StartWatchingInstance(instance)
		if watchingInstances[instance] then
			return
		end
		local function IsInAncestorList(): boolean
			for _, parent in ipairs(self[KEY_ANCESTORS]) do
				if instance:IsDescendantOf(parent) then
					return true
				end
			end
			return false
		end
		local ancestryChangedHandle = self[KEY_TROVE]:Connect(instance.AncestryChanged, function(_, parent)
			if parent and IsInAncestorList() then
				TryConstructComponent(instance)
			else
				TryDeconstructComponent(instance)
			end
		end)
		watchingInstances[instance] = ancestryChangedHandle
		if IsInAncestorList() then
			TryConstructComponent(instance)
		end
	end

	local function InstanceTagged(instance: Instance)
		StartWatchingInstance(instance)
	end

	local function InstanceUntagged(instance: Instance)
		local watchHandle = watchingInstances[instance]
		if watchHandle then
			watchingInstances[instance] = nil
			self[KEY_TROVE]:Remove(watchHandle)
		end
		TryDeconstructComponent(instance)
	end

	self[KEY_TROVE]:Connect(CollectionService:GetInstanceAddedSignal(self.Tag), InstanceTagged)
	self[KEY_TROVE]:Connect(CollectionService:GetInstanceRemovedSignal(self.Tag), InstanceUntagged)

	local tagged = CollectionService:GetTagged(self.Tag)
	for _, instance in ipairs(tagged) do
		task.defer(InstanceTagged, instance)
	end
end


function Component:GetAll()
	return self[KEY_COMPONENTS]
end


function Component:FromInstance(instance: Instance)
	return self[KEY_INST_TO_COMPONENTS][instance]
end


function Component:WaitForInstance(instance: Instance, timeout: number?)
	local componentInstance = self:FromInstance(instance)
	if componentInstance and componentInstance[KEY_STARTED] then
		return Promise.resolve(componentInstance)
	end
	return Promise.fromEvent(self.Started, function(c)
		local match = c.Instance == instance
		if match then
			componentInstance = c
		end
		return match
	end)
		:andThen(function()
			return componentInstance
		end)
		:timeout(if type(timeout) == "number" then timeout else DEFAULT_TIMEOUT)
end


function Component:Construct() end


function Component:Start() end


function Component:Stop() end


function Component:GetComponent(componentClass)
	return componentClass[KEY_INST_TO_COMPONENTS][self.Instance]
end





function Component:Destroy()
	self[KEY_TROVE]:Destroy()
end

return Component
