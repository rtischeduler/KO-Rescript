local IndicatorsController = { Name = "Indicators" }

local HOLD_TIME = 1.6
local FADE_TIME = 0.45
local ROW_HEIGHT = 32

local ROWS = {
	{ key = "damage", label = "Damage", color = Color3.fromRGB(255, 70, 70) },
	{ key = "gcells", label = "Gcells", color = Color3.fromRGB(70, 255, 110) },
	{ key = "xp", label = "Exp", color = Color3.fromRGB(255, 225, 60) },
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
		local TweenService = game:GetService("TweenService")

		local player = Players.LocalPlayer
		local remote = ReplicatedStorage:WaitForChild("RewardIndicator")

		local gui = Instance.new("ScreenGui")
		gui.Name = "RewardIndicators"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 5
		gui.Parent = player:WaitForChild("PlayerGui")

		local holder = Instance.new("Frame")
		holder.Name = "Stack"
		holder.AnchorPoint = Vector2.new(0, 0.5)
		holder.Position = UDim2.new(0.5, 90, 0.5, -20)
		holder.Size = UDim2.fromOffset(300, ROW_HEIGHT * #ROWS)
		holder.BackgroundTransparency = 1
		holder.Parent = gui

		local scale = Instance.new("UIScale")
		scale.Parent = holder

		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = holder

		local labels = {}
		local totals = {}
		for index, row in ROWS do
			local label = Instance.new("TextLabel")
			label.Name = row.key
			label.LayoutOrder = index
			label.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.GothamBlack
			label.TextSize = 26
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextColor3 = row.color
			label.TextStrokeColor3 = Color3.new(0, 0, 0)
			label.TextStrokeTransparency = 0.1
			label.Text = ""
			label.Parent = holder
			labels[row.key] = label
			totals[row.key] = 0
		end

		local lastUpdate = 0
		local token = 0
		local fadeInfo = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local popInfo = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

		local function render()
			for _, row in ROWS do
				local value = totals[row.key]
				local label = labels[row.key]
				label.Text = value > 0.05 and (row.label .. ": " .. formatAmount(value)) or ""
				label.TextTransparency = 0
				label.TextStrokeTransparency = 0.1
			end
		end

		local function clear()
			for _, row in ROWS do
				totals[row.key] = 0
				labels[row.key].Text = ""
			end
		end

		remote.OnClientEvent:Connect(function(damage, gcells, xp)
			local now = os.clock()
			if now - lastUpdate > HOLD_TIME + FADE_TIME then
				clear()
			end
			lastUpdate = now

			totals.damage += tonumber(damage) or 0
			totals.gcells += tonumber(gcells) or 0
			totals.xp += tonumber(xp) or 0
			render()

			scale.Scale = 1.12
			TweenService:Create(scale, popInfo, { Scale = 1 }):Play()

			token += 1
			local mine = token
			task.delay(HOLD_TIME, function()
				if mine ~= token then
					return
				end
				for _, label in labels do
					TweenService:Create(label, fadeInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
				end
				task.delay(FADE_TIME, function()
					if mine == token then
						clear()
					end
				end)
			end)
		end)
	end)
end

return IndicatorsController
