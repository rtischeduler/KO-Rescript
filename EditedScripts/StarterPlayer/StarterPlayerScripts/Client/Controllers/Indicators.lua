local IndicatorsController = { Name = "Indicators" }

local HOLD_TIME = 1.1
local FADE_TIME = 0.4
local RISE_STUDS = 5
local ROW_HEIGHT = 12
local WIDTH = 100
local TEXT_SIZE = 10
local REF_DISTANCE = 70
local MIN_SCALE = 0.3
local MAX_DISTANCE = 450
local MAX_ACTIVE = 24

local ROWS = {
	{ key = "damage", label = "Damage", color = Color3.fromRGB(255, 70, 70) },
	{ key = "gcells", label = "Gcells", color = Color3.fromRGB(70, 255, 110) },
	{ key = "xp", label = "Exp", color = Color3.fromRGB(255, 245, 106) },
	{ key = "candy", label = "Candy", color = Color3.fromRGB(255, 140, 0) },
}

local function formatAmount(value)
	if value >= 10 then
		return tostring(math.floor(value + 0.5))
	end
	return tostring(math.floor(value * 10 + 0.5) / 10)
end

function IndicatorsController:Start()
	task.spawn(function()
		local Players = game:GetService("Players")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local RunService = game:GetService("RunService")
		local TweenService = game:GetService("TweenService")
		local Workspace = game:GetService("Workspace")

		local player = Players.LocalPlayer
		local remote = ReplicatedStorage:WaitForChild("RewardIndicator")
		local playerGui = player:WaitForChild("PlayerGui")

		local guiFolder
		local anchorFolder
		local function ensureGuiFolder()
			if guiFolder and guiFolder.Parent then
				return guiFolder
			end
			guiFolder = Instance.new("Folder")
			guiFolder.Name = "RewardIndicators"
			guiFolder.Parent = player:FindFirstChildOfClass("PlayerGui") or playerGui
			return guiFolder
		end
		ensureGuiFolder()

		local active = {}
		local floatInfo = TweenInfo.new(HOLD_TIME + FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local fadeInfo = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		local function getAnchorFolder()
			if anchorFolder and anchorFolder.Parent then
				return anchorFolder
			end
			anchorFolder = Instance.new("Folder")
			anchorFolder.Name = "RewardAnchors"
			anchorFolder.Parent = Workspace.Terrain
			return anchorFolder
		end

		local function destroyEntry(entry)
			if entry.dead then
				return
			end
			entry.dead = true
			entry.gui:Destroy()
			entry.anchor:Destroy()
		end

		local function spawnIndicator(position, values)
			local anchorFolder = getAnchorFolder()
			if not anchorFolder then
				return
			end

			local lines = {}
			for _, row in ROWS do
				local value = values[row.key]
				if value > 0.05 then
					table.insert(lines, { row = row, text = row.label .. ": " .. formatAmount(value) })
				end
			end
			if #lines == 0 then
				return
			end

			while #active >= MAX_ACTIVE do
				destroyEntry(table.remove(active, 1))
			end

			local anchor = Instance.new("Part")
			anchor.Name = "Anchor"
			anchor.Anchored = true
			anchor.CanCollide = false
			anchor.CanTouch = false
			anchor.CanQuery = false
			anchor.CastShadow = false
			anchor.Transparency = 1
			anchor.Size = Vector3.new(0.2, 0.2, 0.2)
			anchor.Position = position
			anchor.Parent = anchorFolder

			local gui = Instance.new("BillboardGui")
			gui.Name = "Indicator"
			gui.Adornee = anchor
			gui.AlwaysOnTop = true
			gui.LightInfluence = 0
			gui.ResetOnSpawn = false
			gui.MaxDistance = MAX_DISTANCE
			gui.Size = UDim2.fromOffset(WIDTH, ROW_HEIGHT * #lines)
			gui.StudsOffsetWorldSpace = Vector3.new(math.random(-20, 20) / 10, 0, math.random(-20, 20) / 10)

			local container = Instance.new("Frame")
			container.AnchorPoint = Vector2.new(0.5, 0.5)
			container.Position = UDim2.fromScale(0.5, 0.5)
			container.Size = UDim2.fromScale(1, 1)
			container.BackgroundTransparency = 1
			container.Parent = gui

			local scale = Instance.new("UIScale")
			scale.Parent = container

			local layout = Instance.new("UIListLayout")
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Parent = container

			local labels = {}
			for index, line in lines do
				local label = Instance.new("TextLabel")
				label.LayoutOrder = index
				label.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
				label.BackgroundTransparency = 1
				label.Font = Enum.Font.GothamMedium
				label.TextSize = TEXT_SIZE
				label.TextColor3 = line.row.color
				label.TextStrokeColor3 = Color3.new(0, 0, 0)
				label.TextStrokeTransparency = 0.5
				label.Text = line.text
				label.Parent = container
				table.insert(labels, label)
			end

			gui.Parent = ensureGuiFolder()

			local entry = { gui = gui, anchor = anchor, scale = scale, position = position, dead = false }
			table.insert(active, entry)

			TweenService:Create(gui, floatInfo, {
				StudsOffsetWorldSpace = gui.StudsOffsetWorldSpace + Vector3.new(0, RISE_STUDS, 0),
			}):Play()

			task.delay(HOLD_TIME, function()
				if entry.dead then
					return
				end
				for _, label in labels do
					TweenService:Create(label, fadeInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
				end
			end)
			task.delay(HOLD_TIME + FADE_TIME, function()
				destroyEntry(entry)
			end)
		end

		RunService.Heartbeat:Connect(function()
			local camera = Workspace.CurrentCamera
			if not camera or #active == 0 then
				return
			end
			local cameraPosition = camera.CFrame.Position
			for index = #active, 1, -1 do
				local entry = active[index]
				if entry.dead then
					table.remove(active, index)
				else
					local distance = math.max((cameraPosition - entry.position).Magnitude, 1)
					entry.scale.Scale = math.clamp(REF_DISTANCE / distance, MIN_SCALE, 1)
				end
			end
		end)

		remote.OnClientEvent:Connect(function(position, damage, gcells, xp, candy)
			if typeof(position) ~= "Vector3" then
				return
			end
			pcall(spawnIndicator, position, {
				damage = tonumber(damage) or 0,
				gcells = tonumber(gcells) or 0,
				xp = tonumber(xp) or 0,
				candy = tonumber(candy) or 0,
			})
		end)
	end)
end

return IndicatorsController
