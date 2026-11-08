local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local KOSettings = require(ReplicatedStorage:WaitForChild("KOSettings"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function makeGroup(name, parent)
	local group = parent:FindFirstChild(name)
	if not group then
		group = Instance.new("SoundGroup")
		group.Name = name
		group.Parent = parent
	end
	return group
end

local masterGroup = makeGroup("KOMaster", SoundService)
local musicGroup = makeGroup("KOMusic", masterGroup)
local sfxGroup = makeGroup("KOSfx", masterGroup)
local footsteps = SoundService:FindFirstChild("Footsteps")
local footstepBase

local function applyAudio()
	local master = KOSettings.Get("MasterVolume")
	masterGroup.Volume = master
	musicGroup.Volume = KOSettings.Get("MusicVolume")
	sfxGroup.Volume = KOSettings.Get("SoundVolume")
	if footsteps and footsteps:IsA("SoundGroup") then
		footstepBase = footstepBase or footsteps.Volume
		footsteps.Volume = footstepBase * master * KOSettings.Get("SoundVolume")
	end
end

local function route(sound)
	if sound.SoundGroup then
		return
	end
	local isMusic = sound.Name == "Music" or sound:FindFirstAncestor("Music") ~= nil
	sound.SoundGroup = isMusic and musicGroup or sfxGroup
end

local rainEmitters = setmetatable({}, { __mode = "k" })
local rainWanted = setmetatable({}, { __mode = "k" })

local function applyRain(emitter)
	local on = KOSettings.Get("Rain")
	local wanted = rainWanted[emitter]
	if wanted == nil then
		return
	end
	local target = on and wanted
	if emitter.Enabled ~= target then
		emitter.Enabled = target
	end
end

local function trackRain(emitter)
	if rainEmitters[emitter] then
		return
	end
	rainEmitters[emitter] = true
	rainWanted[emitter] = emitter.Enabled
	emitter:GetPropertyChangedSignal("Enabled"):Connect(function()
		if KOSettings.Get("Rain") then
			rainWanted[emitter] = emitter.Enabled
		elseif emitter.Enabled then
			rainWanted[emitter] = true
			emitter.Enabled = false
		end
	end)
	applyRain(emitter)
end

local function handle(inst)
	if inst:IsA("Sound") then
		route(inst)
	elseif inst:IsA("ParticleEmitter") and inst.Name:match("^Rain%d*$") then
		trackRain(inst)
	end
end

local function scan(root)
	local count = 0
	for _, inst in ipairs(root:GetDescendants()) do
		handle(inst)
		count += 1
		if count % 4000 == 0 then
			task.wait()
		end
	end
end

for _, root in ipairs({ Workspace, SoundService, playerGui }) do
	root.DescendantAdded:Connect(handle)
	task.spawn(scan, root)
end

local clockConn
local function applyDayNight()
	if clockConn then
		clockConn:Disconnect()
		clockConn = nil
	end
	local mode = KOSettings.Get("DayNight")
	if mode == "Auto" then
		return
	end
	local hour = mode == "Day" and 14 or 0
	clockConn = RunService.RenderStepped:Connect(function()
		Lighting.ClockTime = hour
	end)
end

KOSettings.OnChanged(function(name)
	if name == "DayNight" then
		applyDayNight()
	elseif name == "Rain" then
		for emitter in pairs(rainEmitters) do
			applyRain(emitter)
		end
	elseif name == "MasterVolume" or name == "MusicVolume" or name == "SoundVolume" then
		applyAudio()
	end
end)

applyAudio()
applyDayNight()

task.spawn(function()
	local remote = ReplicatedStorage:WaitForChild("SettingsPrefs", 60)
	if not remote then
		return
	end
	local ok, saved = pcall(function()
		return remote:InvokeServer("get")
	end)
	if ok and type(saved) == "table" then
		KOSettings.Load(saved)
	end
end)
