-- Restyles the Settings screen to match the main menu: dark translucent panels, Comic Neue Angular, white text,
-- rounded 3px corners and the cyan accent. Layout only: every instance the other scripts use (FOVBack, FOVFront,
-- FOVUpdater, FOVText, InsertCode, Back) keeps its name and parent, so the slider and saving still work.

local settings = script.Parent
local panel = settings:FindFirstChild("SettingsPanel")
if not panel then return end

local FONT = Font.new("rbxasset://fonts/families/ComicNeueAngular.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
local FONT_BOLD = Font.new("rbxasset://fonts/families/ComicNeueAngular.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)

local BASE = Color3.fromRGB(40, 40, 40) -- same as the main menu buttons
local FIELD = Color3.fromRGB(24, 24, 24)
local ACCENT = Color3.fromRGB(156, 255, 248)
local TEXT = Color3.fromRGB(255, 255, 255)
local MUTED = Color3.fromRGB(170, 170, 170)
local RADIUS = UDim.new(0, 3)

local LABEL_W = 170 -- left label column
local VALUE_W = 84 -- right value column
local PAD = 16

local function ensure(parent: Instance, class: string, name: string)
	local inst = parent:FindFirstChild(name)
	if inst and inst.ClassName == class then return inst end
	inst = Instance.new(class)
	inst.Name = name
	inst.Parent = parent
	return inst
end

local function corner(inst: Instance)
	ensure(inst, "UICorner", "UICorner").CornerRadius = RADIUS
end

local function stroke(inst: Instance, color: Color3, transparency: number)
	local s = ensure(inst, "UIStroke", "UIStroke")
	s.Thickness = 1
	s.Color = color
	s.Transparency = transparency
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
end

local function textLimit(inst: Instance, max: number)
	ensure(inst, "UITextSizeConstraint", "UITextSizeConstraint").MaxTextSize = max
end

local function styleLabel(lbl: TextLabel, text: string, size: number, font: Font)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = TEXT
	lbl.FontFace = font
	lbl.TextScaled = false
	lbl.TextSize = size
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.BorderSizePixel = 0
	for _, c in lbl:GetChildren() do
		if c:IsA("UIStroke") then c:Destroy() end
	end
end

local function hide(name: string)
	local inst = panel:FindFirstChild(name)
	if inst and inst:IsA("GuiObject") then
		inst.Visible = false
	end
end

-- Window ---------------------------------------------------------------------------------------------------------
if settings:IsA("GuiObject") then
	settings.BackgroundColor3 = BASE
	settings.BackgroundTransparency = 0.3
	settings.BorderSizePixel = 0
	corner(settings)
end

local title = settings:FindFirstChild("TextLabel")
if title and title:IsA("TextLabel") then
	title.Position = UDim2.fromOffset(PAD, 12)
	title.Size = UDim2.new(1, -(PAD * 2 + 56), 0, 40)
	styleLabel(title, "Settings", 32, FONT_BOLD)
	textLimit(title, 32)
end

local back = settings:FindFirstChild("Back")
if back and back:IsA("TextButton") then
	back.AnchorPoint = Vector2.new(1, 0)
	back.Position = UDim2.new(1, -PAD, 0, 12)
	back.Size = UDim2.fromOffset(40, 40)
	back.BackgroundColor3 = FIELD
	back.BackgroundTransparency = 0.2
	back.BorderSizePixel = 0
	back.Text = "X"
	back.TextColor3 = TEXT
	back.FontFace = FONT_BOLD
	back.TextScaled = false
	back.TextSize = 24
	back.AutoButtonColor = false
	corner(back)

	back.MouseEnter:Connect(function()
		back.BackgroundColor3 = Color3.fromRGB(190, 55, 55)
	end)
	back.MouseLeave:Connect(function()
		back.BackgroundColor3 = FIELD
	end)
end

-- Content area ---------------------------------------------------------------------------------------------------
panel.AnchorPoint = Vector2.zero
panel.Position = UDim2.new(0, PAD, 0, 64)
panel.Size = UDim2.new(1, -PAD * 2, 1, -(64 + PAD))
panel.BackgroundTransparency = 1
panel.BorderSizePixel = 0
panel.CanvasSize = UDim2.fromOffset(0, 0)
panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
panel.ScrollingDirection = Enum.ScrollingDirection.Y
panel.ScrollBarThickness = 4
panel.ScrollBarImageColor3 = MUTED
panel.ScrollBarImageTransparency = 0.4

-- one row = label | control | value, stacked top to bottom
local ROW_H, ROW_GAP = 52, 12
local function rowY(index: number): number
	return (index - 1) * (ROW_H + ROW_GAP)
end

local function rowLabel(name: string, text: string, index: number)
	local lbl = panel:FindFirstChild(name)
	if not lbl or not lbl:IsA("TextLabel") then return end
	lbl.AnchorPoint = Vector2.zero
	lbl.Position = UDim2.fromOffset(0, rowY(index))
	lbl.Size = UDim2.fromOffset(LABEL_W, ROW_H)
	lbl.ZIndex = 2
	styleLabel(lbl, text, 24, FONT)
	textLimit(lbl, 24)
end

-- Row 1: field of view ---------------------------------------------------------------------------------------------
rowLabel("FOVLabel", "Field of view", 1)
hide("FOVSliderBackground")

local TRACK_H = 14
local trackPos = UDim2.new(0, LABEL_W, 0, rowY(1) + (ROW_H - TRACK_H) / 2)
local trackSize = UDim2.new(1, -(LABEL_W + VALUE_W + 16), 0, TRACK_H)

local fovBack = panel:FindFirstChild("FOVBack")
if fovBack and fovBack:IsA("GuiObject") then
	fovBack.AnchorPoint = Vector2.zero
	fovBack.Position = trackPos
	fovBack.Size = trackSize
	fovBack.BackgroundColor3 = FIELD
	fovBack.BackgroundTransparency = 0.1
	fovBack.BorderSizePixel = 0
	corner(fovBack)

	local fovFront = fovBack:FindFirstChild("FOVFront")
	if fovFront and fovFront:IsA("GuiObject") then
		fovFront.BackgroundColor3 = ACCENT
		fovFront.BackgroundTransparency = 0
		fovFront.BorderSizePixel = 0
		corner(fovFront)
	end
end

-- taller invisible hit area over the thin track so it is easy to grab (the slider script reads FOVBack for the maths)
local fovUpdater = panel:FindFirstChild("FOVUpdater")
if fovUpdater and fovUpdater:IsA("GuiObject") then
	fovUpdater.AnchorPoint = Vector2.zero
	fovUpdater.Position = UDim2.new(0, LABEL_W, 0, rowY(1))
	fovUpdater.Size = UDim2.new(1, -(LABEL_W + VALUE_W + 16), 0, ROW_H)
	fovUpdater.BackgroundTransparency = 1
	fovUpdater.BorderSizePixel = 0
end

local fovText = panel:FindFirstChild("FOVText")
if fovText and fovText:IsA("TextBox") then
	fovText.AnchorPoint = Vector2.new(1, 0)
	fovText.Position = UDim2.new(1, 0, 0, rowY(1) + 6)
	fovText.Size = UDim2.fromOffset(VALUE_W, ROW_H - 12)
	fovText.BackgroundColor3 = FIELD
	fovText.BackgroundTransparency = 0.1
	fovText.BorderSizePixel = 0
	fovText.TextColor3 = TEXT
	fovText.FontFace = FONT
	fovText.TextScaled = true
	fovText.TextXAlignment = Enum.TextXAlignment.Center
	fovText.ZIndex = 2
	textLimit(fovText, 24)
	corner(fovText)
	for _, c in fovText:GetChildren() do
		if c:IsA("UIStroke") then c:Destroy() end
	end
end

-- Row 2: codes -----------------------------------------------------------------------------------------------------
rowLabel("CodesLabel", "Redeem code", 2)
hide("CodesBackground")

local insertCode = panel:FindFirstChild("InsertCode")
if insertCode and insertCode:IsA("TextBox") then
	insertCode.AnchorPoint = Vector2.zero
	insertCode.Position = UDim2.new(0, LABEL_W, 0, rowY(2) + 6)
	insertCode.Size = UDim2.new(1, -LABEL_W, 0, ROW_H - 12)
	insertCode.BackgroundColor3 = FIELD
	insertCode.BackgroundTransparency = 0.1
	insertCode.BorderSizePixel = 0
	insertCode.TextColor3 = TEXT
	insertCode.PlaceholderColor3 = MUTED
	insertCode.PlaceholderText = "Enter a code"
	insertCode.Text = ""
	insertCode.FontFace = FONT
	insertCode.TextScaled = true
	insertCode.TextXAlignment = Enum.TextXAlignment.Left
	insertCode.ClearTextOnFocus = false
	insertCode.ZIndex = 2
	textLimit(insertCode, 24)
	corner(insertCode)

	local pad = ensure(insertCode, "UIPadding", "UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
end
