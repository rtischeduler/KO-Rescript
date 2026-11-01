local GraphicsController = { Name = "Graphics" }

local ALIASES = { high = "High", medium = "Medium", med = "Medium", low = "Low", lowest = "Lowest", auto = "Auto" }
local USAGE = "Type /graphics High, Medium, Low, Lowest or Auto in chat."

function GraphicsController:Start()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local Lighting = game:GetService("Lighting")
	local StarterGui = game:GetService("StarterGui")
	local TextChatService = game:GetService("TextChatService")
	local UserInputService = game:GetService("UserInputService")
	local Workspace = game:GetService("Workspace")
	local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
	local Quality = require(Shared:WaitForChild("GraphicsQuality"))
	local cfg = require(script:FindFirstAncestor("Client").Config).Graphics

	local originals = setmetatable({}, { __mode = "k" })
	local function remember(inst, props)
		local saved = originals[inst]
		if not saved then
			saved = {}
			originals[inst] = saved
			for _, prop in ipairs(props) do
				saved[prop] = inst[prop]
			end
		end
		return saved
	end

	local originalQuality
	pcall(function()
		originalQuality = settings().Rendering.QualityLevel.Value
	end)

	local function notify(title, text)
		task.spawn(function()
			for _ = 1, 10 do
				local ok = pcall(function()
					StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = cfg.NotifySeconds })
				end)
				if ok then
					return
				end
				task.wait(1)
			end
		end)
	end

	local function applyToInstance(inst, s)
		if inst:IsA("ParticleEmitter") then
			if inst.Parent and inst.Parent:GetAttribute("GraphicsManaged") then
				return
			end
			local saved = remember(inst, { "Rate" })
			if saved.Rate > 0 then
				inst.Rate = saved.Rate * s.ParticleScale
			end
		elseif inst:IsA("PointLight") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight") then
			local saved = remember(inst, { "Shadows" })
			inst.Shadows = saved.Shadows and s.LightShadows
		end
	end

	local function applyEffect(inst, s)
		local rule = s.Effects[inst.ClassName]
		if rule ~= nil then
			local saved = remember(inst, { "Enabled" })
			inst.Enabled = saved.Enabled and rule
		elseif inst:IsA("Atmosphere") then
			local saved = remember(inst, { "Density", "Haze", "Glare" })
			inst.Density = saved.Density * s.Atmosphere
			inst.Haze = saved.Haze * s.Atmosphere
			inst.Glare = saved.Glare * s.Atmosphere
		end
	end

	local function applyGlobal(s)
		pcall(function()
			local saved = remember(Lighting, { "GlobalShadows", "EnvironmentSpecularScale" })
			Lighting.GlobalShadows = saved.GlobalShadows and s.Shadows
			Lighting.EnvironmentSpecularScale = saved.EnvironmentSpecularScale * s.Specular
		end)
		for _, inst in ipairs(Lighting:GetChildren()) do
			pcall(applyEffect, inst, s)
		end
		pcall(function()
			local terrain = Workspace.Terrain
			local saved = remember(terrain, { "Decoration" })
			terrain.Decoration = saved.Decoration and s.Decoration
		end)
		pcall(function()
			local target = originalQuality
			if s.QualityLevel and originalQuality then
				target = math.min(originalQuality, s.QualityLevel)
			end
			if target then
				settings().Rendering.QualityLevel = target
			end
		end)
	end

	local addedConn
	local applyToken = 0

	local function applyAll()
		applyToken += 1
		local token = applyToken
		local s = Quality.Settings()
		applyGlobal(s)

		if addedConn then
			addedConn:Disconnect()
			addedConn = nil
		end
		if s.ParticleScale < 1 or not s.LightShadows then
			addedConn = Workspace.DescendantAdded:Connect(function(inst)
				pcall(applyToInstance, inst, Quality.Settings())
			end)
		end

		task.spawn(function()
			local all = Workspace:GetDescendants()
			for i, inst in ipairs(all) do
				if token ~= applyToken then
					return
				end
				pcall(applyToInstance, inst, s)
				if i % cfg.SweepChunk == 0 then
					task.wait()
				end
			end
		end)
	end

	local autoEnabled = cfg.Auto
	local graceUntil = os.clock() + cfg.GraceSeconds
	local cooldownUntil = 0

	Quality.OnChanged(function(name, source)
		applyAll()
		cooldownUntil = os.clock() + cfg.CooldownSeconds
		if source == "auto" then
			notify("Graphics lowered to " .. name, "Adjust anytime: type /graphics High or /graphics Low in chat.")
		end
	end)

	local strikes = 0
	local function evaluate(fps)
		local now = os.clock()
		if not autoEnabled or now < graceUntil or now < cooldownUntil or not UserInputService.WindowFocused then
			strikes = 0
			return
		end
		strikes = fps < cfg.LowFps and strikes + 1 or 0
		if strikes >= cfg.Strikes then
			strikes = 0
			local nextTier = Quality.Next()
			if nextTier then
				Quality.Set(nextTier, "auto")
			end
		end
	end

	local acc, frames = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		if dt > cfg.IgnoreFrameOver then
			return
		end
		acc += dt
		frames += 1
		if acc >= cfg.SampleSeconds then
			local fps = frames / acc
			acc, frames = 0, 0
			evaluate(fps)
		end
	end)

	local function handleCommand(arg)
		arg = string.lower((arg or ""):gsub("%s", ""))
		if arg == "" then
			notify("Graphics: " .. Quality.Get(), USAGE)
			return
		end
		local choice = ALIASES[arg]
		if not choice then
			notify("Unknown graphics setting", USAGE)
		elseif choice == "Auto" then
			autoEnabled = true
			notify("Graphics: Auto", "Quality will drop on its own if the game lags.")
		else
			autoEnabled = false
			Quality.Set(choice, "manual")
			notify("Graphics set to " .. choice, "Auto-lowering is off. Type /graphics Auto to turn it back on.")
		end
	end

	local hooked = false
	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		hooked = pcall(function()
			local command = Instance.new("TextChatCommand")
			command.Name = "GraphicsCommand"
			command.PrimaryAlias = "/graphics"
			command.Parent = TextChatService
			command.Triggered:Connect(function(_, text)
				handleCommand(text:match("^%S+%s*(.*)$"))
			end)
		end)
	end
	if not hooked then
		Players.LocalPlayer.Chatted:Connect(function(message)
			local arg = message:lower():match("^/graphics%s*(.*)$")
			if arg then
				handleCommand(arg)
			end
		end)
	end
end

return GraphicsController
