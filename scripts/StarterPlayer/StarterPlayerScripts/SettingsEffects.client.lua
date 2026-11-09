local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
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
local footGroup = makeGroup("KOFootsteps", sfxGroup)
local footsteps = SoundService:FindFirstChild("Footsteps")
local footstepBase

local function applyAudio()
	local master = KOSettings.Get("MasterVolume")
	masterGroup.Volume = master
	musicGroup.Volume = KOSettings.Get("MusicVolume")
	sfxGroup.Volume = KOSettings.Get("SoundVolume")
	footGroup.Volume = KOSettings.Get("FootstepVolume")
	if footsteps and footsteps:IsA("SoundGroup") then
		footstepBase = footstepBase or footsteps.Volume
		footsteps.Volume = footstepBase * master * KOSettings.Get("SoundVolume") * KOSettings.Get("FootstepVolume")
	end
end

local function route(sound)
	if sound.SoundGroup then
		return
	end
	if sound.Name == "FootStep" or sound.Name == "Running" then
		sound.SoundGroup = footGroup
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

local NEUTRAL = { LowGain = 0, MidGain = 0, HighGain = 0 }
local MUFFLED = { LowGain = 0, MidGain = -12, HighGain = -50 }
local muffles = {}

local function addMuffle(group)
	local effect = group:FindFirstChild("KOMuffle")
	if not effect then
		effect = Instance.new("EqualizerSoundEffect")
		effect.Name = "KOMuffle"
		effect.LowGain = 0
		effect.MidGain = 0
		effect.HighGain = 0
		effect.Parent = group
	end
	table.insert(muffles, effect)
end

addMuffle(masterGroup)
if footsteps and footsteps:IsA("SoundGroup") then
	addMuffle(footsteps)
end

local muffled = false
local function setMuffled(on)
	if muffled == on then
		return
	end
	muffled = on
	for _, effect in ipairs(muffles) do
		TweenService:Create(effect, TweenInfo.new(0.35), on and MUFFLED or NEUTRAL):Play()
	end
end

local function cameraUnderwater()
	local camera = Workspace.CurrentCamera
	if not camera then
		return false
	end
	local position = camera.CFrame.Position
	local ocean = Workspace:FindFirstChild("Ocean")
	if ocean and ocean:IsA("BasePart") then
		return position.Y < ocean.Position.Y
	end
	local terrain = Workspace.Terrain
	local cell = terrain:WorldToCell(position)
	local origin = terrain:CellCenterToWorld(cell.X, cell.Y, cell.Z) - Vector3.new(2, 2, 2)
	local ok, materials = pcall(terrain.ReadVoxels, terrain, Region3.new(origin, origin + Vector3.new(4, 4, 4)), 4)
	return ok and materials[1][1][1] == Enum.Material.Water
end

local lastCheck = 0
local function updateMuffle(force)
	local now = os.clock()
	if not force and now - lastCheck < 0.1 then
		return
	end
	lastCheck = now
	setMuffled(KOSettings.Get("UnderwaterMuffle") and cameraUnderwater())
end

RunService.Heartbeat:Connect(function()
	updateMuffle(false)
end)

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
	elseif name == "MasterVolume" or name == "MusicVolume" or name == "SoundVolume" or name == "FootstepVolume" then
		applyAudio()
	elseif name == "UnderwaterMuffle" then
		updateMuffle(true)
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