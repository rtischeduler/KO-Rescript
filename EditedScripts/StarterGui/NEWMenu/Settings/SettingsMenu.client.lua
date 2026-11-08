local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local settings = script.Parent
local panel = settings:WaitForChild("SettingsPanel")
local KOSettings = require(ReplicatedStorage:WaitForChild("KOSettings"))
local remote = ReplicatedStorage:WaitForChild("SettingsPrefs", 30)

local FONT = Font.new("rbxasset://fonts/families/ComicNeueAngular.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
local FONT_BOLD = Font.new("rbxasset://fonts/families/ComicNeueAngular.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)

local WHITE = Color3.fromRGB(255, 255, 255)
local BLUE = Color3.fromRGB(0, 132, 255)
local TRACK = Color3.fromRGB(153, 153, 153)
local ACCENT = Color3.fromRGB(156, 255, 248)
local LIGHT = Color3.fromRGB(225, 228, 235)
local TEXT = Color3.fromRGB(0, 0, 0)
local ORANGE = Color3.fromRGB(235, 140, 0)
local GREEN = Color3.fromRGB(0, 150, 60)
local RED = Color3.fromRGB(190, 55, 55)

local LABEL_W, VALUE_W, PAD = 170, 84, 16
local ROW_H, ROW_GAP = 52, 12
local TAB_ORDER = { "General", "Audio", "UI", "Controls", "Other" }

local KEY_TEXT = {
	One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9", Zero = "0",
	LeftShift = "L-Shift", RightShift = "R-Shift", LeftControl = "L-Ctrl", RightControl = "R-Ctrl",
	LeftAlt = "L-Alt", RightAlt = "R-Alt", Space = "Space", Return = "Enter", Backspace = "Backspace",
}

local function rowY(index)
	return (index - 1) * (ROW_H + ROW_GAP)
end

local function new(class, props, parent)
	local inst = Instance.new(class)
	for key, value in pairs(props) do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

local function corner(inst)
	new("UICorner", { CornerRadius = UDim.new(0, 3) }, inst)
end

local function label(parent, text, y)
	return new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.fromOffset(LABEL_W, ROW_H),
		Text = text,
		TextColor3 = TEXT,
		FontFace = FONT,
		TextSize = 22,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 2,
	}, parent)
end

local function button(parent, props)
	local btn = new("TextButton", {
		AutoButtonColor = false,
		BorderSizePixel = 0,
		FontFace = FONT_BOLD,
		TextSize = 20,
		TextColor3 = WHITE,
		BackgroundColor3 = BLUE,
		ZIndex = 2,
	}, parent)
	for key, value in pairs(props) do
		btn[key] = value
	end
	corner(btn)
	return btn
end

local refreshers = {}
local pending, flushing = {}, false

local function flush()
	flushing = false
	local batch = pending
	pending = {}
	if not remote then
		return
	end
	for name in pairs(batch) do
		task.spawn(function()
			pcall(function()
				remote:InvokeServer("set", name, KOSettings.Get(name))
			end)
		end)
	end
end

local function queueSave(name)
	pending[name] = true
	if not flushing then
		flushing = true
		task.delay(0.5, flush)
	end
end

local function userSet(name, value)
	if KOSettings.Set(name, value) then
		queueSave(name)
	end
end

KOSettings.OnChanged(function(name)
	local refresh = refreshers[name]
	if refresh then
		refresh()
	end
end)

local pages = {}

local function newPage(name, rows, offset, extras)
	local frame = new("Frame", {
		Name = "Page" .. name,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		Position = UDim2.fromOffset(0, offset),
		Size = UDim2.new(1, 0, 0, rows * (ROW_H + ROW_GAP)),
	}, panel)
	pages[name] = { frame = frame, height = offset + rows * (ROW_H + ROW_GAP), extras = extras }
	return frame
end

local function addToggle(parent, text, name, row)
	label(parent, text, rowY(row))
	local btn = button(parent, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, rowY(row) + 8),
		Size = UDim2.fromOffset(VALUE_W, ROW_H - 16),
	})
	local function refresh()
		local on = KOSettings.Get(name)
		btn.Text = on and "ON" or "OFF"
		btn.BackgroundColor3 = on and BLUE or TRACK
	end
	refreshers[name] = refresh
	refresh()
	btn.MouseButton1Click:Connect(function()
		userSet(name, not KOSettings.Get(name))
	end)
end

local function addChoice(parent, text, name, row, display)
	label(parent, text, rowY(row))
	local options = KOSettings.Choices(name)
	local count = #options
	local holder = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, LABEL_W, 0, rowY(row) + 8),
		Size = UDim2.new(1, -LABEL_W, 0, ROW_H - 16),
	}, parent)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, holder)
	local buttons = {}
	for index, option in ipairs(options) do
		local btn = button(holder, {
			LayoutOrder = index,
			Size = UDim2.new(1 / count, -math.ceil(6 * (count - 1) / count), 1, 0),
			Text = display and display[option] or option,
			FontFace = FONT,
			TextSize = 18,
		})
		btn.MouseButton1Click:Connect(function()
			userSet(name, option)
		end)
		buttons[option] = btn
	end
	local function refresh()
		local current = KOSettings.Get(name)
		for option, btn in pairs(buttons) do
			local selected = option == current
			btn.BackgroundColor3 = selected and BLUE or LIGHT
			btn.TextColor3 = selected and WHITE or TEXT
		end
	end
	refreshers[name] = refresh
	refresh()
end

local function addSlider(parent, text, name, row)
	label(parent, text, rowY(row))
	local hit = new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, LABEL_W, 0, rowY(row)),
		Size = UDim2.new(1, -(LABEL_W + VALUE_W + 16), 0, ROW_H),
		ZIndex = 3,
	}, parent)
	local track = new("Frame", {
		BackgroundColor3 = TRACK,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 14),
		ZIndex = 2,
	}, hit)
	corner(track)
	local fill = new("Frame", { BackgroundColor3 = ACCENT, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), ZIndex = 2 }, track)
	corner(fill)
	local value = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, rowY(row) + 6),
		Size = UDim2.fromOffset(VALUE_W, ROW_H - 12),
		BackgroundColor3 = BLUE,
		BorderSizePixel = 0,
		TextColor3 = WHITE,
		FontFace = FONT,
		TextSize = 20,
		ZIndex = 2,
	}, parent)
	corner(value)

	local function refresh()
		local v = KOSettings.Get(name)
		fill.Size = UDim2.fromScale(v, 1)
		value.Text = math.floor(v * 100 + 0.5) .. "%"
	end
	refreshers[name] = refresh
	refresh()

	local dragging = false
	local function setFromX(x)
		local width = track.AbsoluteSize.X
		if width > 0 then
			userSet(name, math.clamp((x - track.AbsolutePosition.X) / width, 0, 1))
		end
	end
	local function isPress(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
	end
	hit.InputBegan:Connect(function(input)
		if isPress(input) then
			dragging = true
			panel.ScrollingEnabled = false
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if dragging and isPress(input) then
			dragging = false
			panel.ScrollingEnabled = true
		end
	end)
end

local listening, listenConn
local keyButtons = {}

local function refreshKeys()
	for id, btn in pairs(keyButtons) do
		if listening ~= id then
			local keyName = KOSettings.Get("Key_" .. id)
			btn.Text = KEY_TEXT[keyName] or keyName
			btn.BackgroundColor3 = BLUE
		end
	end
end

local function stopListening()
	if listenConn then
		listenConn:Disconnect()
		listenConn = nil
	end
	if listening then
		listening = nil
		KOSettings.SetRebinding(false)
	end
	refreshKeys()
end

local function startListening(id)
	stopListening()
	listening = id
	KOSettings.SetRebinding(true)
	keyButtons[id].Text = "Press a key"
	keyButtons[id].BackgroundColor3 = ORANGE
	listenConn = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if input.KeyCode ~= Enum.KeyCode.Escape then
			local changed = KOSettings.SetKey(id, input.KeyCode.Name)
			if changed then
				for _, name in ipairs(changed) do
					queueSave(name)
				end
			end
		end
		stopListening()
	end)
end

local function addKey(parent, action, row)
	label(parent, action.label, rowY(row))
	local btn = button(parent, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, rowY(row) + 8),
		Size = UDim2.fromOffset(140, ROW_H - 16),
	})
	keyButtons[action.id] = btn
	refreshers["Key_" .. action.id] = refreshKeys
	btn.MouseButton1Click:Connect(function()
		startListening(action.id)
	end)
end

local generalExtras = {}
for _, name in ipairs({ "FOVLabel", "FOVBack", "FOVUpdater", "FOVText" }) do
	local inst = panel:FindFirstChild(name)
	if inst and inst:IsA("GuiObject") then
		table.insert(generalExtras, inst)
	end
end
for _, name in ipairs({ "CodesLabel", "CodesBackground" }) do
	local inst = panel:FindFirstChild(name)
	if inst and inst:IsA("GuiObject") then
		inst.Visible = false
	end
end

local general = newPage("General", 3, ROW_H + ROW_GAP, generalExtras)
addChoice(general, "Graphics", "Graphics", 1)
addChoice(general, "Day / Night cycle", "DayNight", 2, { Day = "Always Day", Night = "Always Night" })
addToggle(general, "Rain", "Rain", 3)

local audio = newPage("Audio", 3, 0, {})
addSlider(audio, "Master volume", "MasterVolume", 1)
addSlider(audio, "Music volume", "MusicVolume", 2)
addSlider(audio, "Sound volume", "SoundVolume", 3)

local ui = newPage("UI", 4, 0, {})
addToggle(ui, "Damage indicators", "DamageIndicator", 1)
addToggle(ui, "G-Cell indicators", "GCellIndicator", 2)
addToggle(ui, "XP indicators", "XPIndicator", 3)
addToggle(ui, "Candy indicators", "CandyIndicator", 4)

local actions = KOSettings.Actions()
local controls = newPage("Controls", #actions, 0, {})
for index, action in ipairs(actions) do
	addKey(controls, action, index)
end
refreshKeys()

local insertCode = panel:FindFirstChild("InsertCode")
local other = newPage("Other", 3, 0, insertCode and { insertCode } or {})
label(other, "Redeem code", rowY(1))

local status = new("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, rowY(2)),
	Size = UDim2.new(1, 0, 0, ROW_H),
	Text = "",
	TextColor3 = GREEN,
	FontFace = FONT,
	TextSize = 20,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 2,
}, other)

local function setStatus(text, good)
	status.Text = text
	status.TextColor3 = good and GREEN or RED
end

local redeemBtn = button(other, {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, rowY(1) + 6),
	Size = UDim2.fromOffset(VALUE_W, ROW_H - 12),
	Text = "Redeem",
})

if insertCode and insertCode:IsA("TextBox") then
	insertCode.AnchorPoint = Vector2.zero
	insertCode.Position = UDim2.new(0, LABEL_W, 0, rowY(1) + 6)
	insertCode.Size = UDim2.new(1, -(LABEL_W + VALUE_W + 8), 0, ROW_H - 12)
	insertCode.BackgroundColor3 = WHITE
	insertCode.BackgroundTransparency = 0
	insertCode.BorderSizePixel = 0
	insertCode.TextColor3 = TEXT
	insertCode.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
	insertCode.PlaceholderText = "Enter a code"
	insertCode.Text = ""
	insertCode.FontFace = FONT
	insertCode.TextScaled = true
	insertCode.TextXAlignment = Enum.TextXAlignment.Left
	insertCode.ClearTextOnFocus = false
	insertCode.ZIndex = 2
	new("UITextSizeConstraint", { MaxTextSize = 24 }, insertCode)
	local stroke = insertCode:FindFirstChildOfClass("UIStroke") or new("UIStroke", {}, insertCode)
	stroke.Thickness = 1
	stroke.Color = BLUE
	stroke.Transparency = 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local pad = insertCode:FindFirstChildOfClass("UIPadding") or new("UIPadding", {}, insertCode)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
end

local redeeming = false
local function redeem()
	if redeeming or not insertCode or not remote then
		return
	end
	if insertCode.Text:gsub("%s", "") == "" then
		setStatus("Enter a code first.", false)
		return
	end
	redeeming = true
	local ok, success, message = pcall(function()
		return remote:InvokeServer("redeem", insertCode.Text)
	end)
	redeeming = false
	if ok and success then
		insertCode.Text = ""
		setStatus(message or "Code redeemed!", true)
	else
		setStatus((ok and message) or "Something went wrong. Try again.", false)
	end
end
redeemBtn.MouseButton1Click:Connect(redeem)
if insertCode then
	insertCode.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			redeem()
		end
	end)
end

local resetBtn = button(other, {
	Position = UDim2.fromOffset(0, rowY(3) + 6),
	Size = UDim2.new(1, 0, 0, ROW_H - 12),
	Text = "Reset settings",
	BackgroundColor3 = RED,
})
local confirmUntil = 0
resetBtn.MouseButton1Click:Connect(function()
	if os.clock() > confirmUntil then
		confirmUntil = os.clock() + 3
		resetBtn.Text = "Click again to confirm"
		task.delay(3, function()
			if os.clock() >= confirmUntil then
				resetBtn.Text = "Reset settings"
			end
		end)
		return
	end
	confirmUntil = 0
	resetBtn.Text = "Reset settings"
	KOSettings.Reset()
	local fovUpdater = panel:FindFirstChild("FOVUpdater")
	local fovValue = fovUpdater and fovUpdater:FindFirstChild("FOV")
	if fovValue then
		fovValue.Value = 0.7
	end
	if remote then
		task.spawn(function()
			pcall(function()
				remote:InvokeServer("reset")
			end)
		end)
	end
	setStatus("All settings were reset.", true)
end)

local tabBar = new("Frame", {
	Name = "Tabs",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(PAD, 58),
	Size = UDim2.new(1, -PAD * 2, 0, 40),
}, settings)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, tabBar)

local tabs = {}
local function showPage(name)
	stopListening()
	for pageName, page in pairs(pages) do
		local on = pageName == name
		page.frame.Visible = on
		for _, inst in ipairs(page.extras) do
			inst.Visible = on
		end
		tabs[pageName].BackgroundColor3 = on and WHITE or BLUE
		tabs[pageName].TextColor3 = on and BLUE or WHITE
	end
	panel.AutomaticCanvasSize = Enum.AutomaticSize.None
	panel.CanvasSize = UDim2.fromOffset(0, pages[name].height + PAD * 2)
	panel.CanvasPosition = Vector2.zero
end

for index, name in ipairs(TAB_ORDER) do
	local btn = button(tabBar, {
		Name = name,
		LayoutOrder = index,
		Size = UDim2.new(1 / #TAB_ORDER, -math.ceil(6 * (#TAB_ORDER - 1) / #TAB_ORDER), 1, 0),
		Text = name,
		TextSize = 22,
	})
	btn.MouseButton1Click:Connect(function()
		showPage(name)
	end)
	tabs[name] = btn
end

settings:GetPropertyChangedSignal("Visible"):Connect(function()
	if not settings.Visible then
		stopListening()
	end
end)

showPage("General")
