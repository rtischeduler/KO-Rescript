
--// Physical Properties Reset Plugin

local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Workspace = game:GetService("Workspace")

--// Toolbar
local toolbar = plugin:CreateToolbar("Model Tools")

local openButton = toolbar:CreateButton(
	"PhysicsReset",
	"Open Physical Properties Reset",
	""
)

--// Widget
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	300,
	230,
	250,
	180
)

local widget = plugin:CreateDockWidgetPluginGui(
	"PhysicalPropertiesResetUI",
	widgetInfo
)

widget.Title = "Physical Properties Reset"

--// UI Main Frame
local main = Instance.new("Frame")
main.Size = UDim2.fromScale(1, 1)
main.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
main.BorderSizePixel = 0
main.Parent = widget

--// Padding
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 12)
padding.PaddingBottom = UDim.new(0, 12)
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.Parent = main

--// Layout
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = main

--// Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundTransparency = 1
title.Text = "PHYSICAL PROPERTIES"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.LayoutOrder = 1
title.Parent = main

--// Description
local description = Instance.new("TextLabel")
description.Size = UDim2.new(1, 0, 0, 25)
description.BackgroundTransparency = 1
description.Text = "Restore Roblox default physical properties."
description.TextColor3 = Color3.fromRGB(180, 180, 190)
description.Font = Enum.Font.Gotham
description.TextSize = 11
description.LayoutOrder = 2
description.Parent = main

--// Status
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 25)
status.BackgroundTransparency = 1
status.Text = "Ready"
status.TextColor3 = Color3.fromRGB(100, 220, 140)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.LayoutOrder = 5
status.Parent = main

--// Button Creator
local function createButton(text, order, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 42)
	button.BackgroundColor3 = Color3.fromRGB(65, 105, 200)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 13
	button.LayoutOrder = order
	button.Parent = main

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	button.MouseButton1Click:Connect(callback)

	return button
end

--// Reset Function
local function resetParts(objects)
	local recording = ChangeHistoryService:TryBeginRecording(
		"ResetPhysicalProperties",
		"Reset Physical Properties"
	)

	if not recording then
		status.Text = "Could not start undo recording"
		return
	end

	local count = 0

	for _, object in ipairs(objects) do
		if object:IsA("BasePart") then
			object.CustomPhysicalProperties = nil
			count += 1
		end

		for _, descendant in ipairs(object:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.CustomPhysicalProperties = nil
				count += 1
			end
		end
	end

	ChangeHistoryService:FinishRecording(
		recording,
		Enum.FinishRecordingOperation.Commit
	)

	status.Text = "Reset " .. count .. " parts successfully!"
end

--// Selected Model Button
createButton("RESET SELECTED MODELS", 3, function()
	local selected = Selection:Get()

	if #selected == 0 then
		status.Text = "Nothing selected!"
		return
	end

	resetParts(selected)
end)

--// Entire Workspace Button
createButton("RESET ENTIRE WORKSPACE", 4, function()
	resetParts({Workspace})
end)

--// Open / Close
openButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)
