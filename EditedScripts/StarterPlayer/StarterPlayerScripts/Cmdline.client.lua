local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local HISTORY_LIMIT = 30
local TOAST_TIME = 5
local BAR_HEIGHT = 44

local player = Players.LocalPlayer
local executeEvent = ReplicatedStorage:WaitForChild("CmdlineExecute")
local resultEvent = ReplicatedStorage:WaitForChild("CmdlineResult")

local gui = Instance.new("ScreenGui")
gui.Name = "CmdlineGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1001
gui.Parent = player:WaitForChild("PlayerGui")

local bar = Instance.new("Frame")
bar.Name = "Bar"
bar.AnchorPoint = Vector2.new(0, 1)
bar.Position = UDim2.new(0, 0, 1, 0)
bar.Size = UDim2.new(1, 0, 0, BAR_HEIGHT)
bar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bar.BackgroundTransparency = 0.05
bar.BorderSizePixel = 0
bar.Visible = false
bar.Parent = gui

local prompt = Instance.new("TextLabel")
prompt.BackgroundTransparency = 1
prompt.Position = UDim2.fromOffset(10, 0)
prompt.Size = UDim2.fromOffset(16, BAR_HEIGHT)
prompt.Font = Enum.Font.Code
prompt.Text = ">"
prompt.TextColor3 = Color3.fromRGB(0, 255, 120)
prompt.TextSize = 20
prompt.Parent = bar

local box = Instance.new("TextBox")
box.Name = "Input"
box.BackgroundTransparency = 1
box.Position = UDim2.fromOffset(32, 0)
box.Size = UDim2.new(1, -170, 1, 0)
box.ClearTextOnFocus = false
box.Font = Enum.Font.Code
box.PlaceholderText = "Type a command, e.g. ;candy me 3"
box.PlaceholderColor3 = Color3.fromRGB(110, 110, 110)
box.Text = ""
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.TextSize = 18
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextTruncate = Enum.TextTruncate.AtEnd
box.Parent = bar

local run = Instance.new("TextButton")
run.AnchorPoint = Vector2.new(1, 0.5)
run.Position = UDim2.new(1, -56, 0.5, 0)
run.Size = UDim2.fromOffset(64, 30)
run.BackgroundColor3 = Color3.fromRGB(0, 140, 70)
run.BorderSizePixel = 0
run.Font = Enum.Font.GothamBold
run.Text = "Run"
run.TextColor3 = Color3.fromRGB(255, 255, 255)
run.TextSize = 14
run.Parent = bar
local runCorner = Instance.new("UICorner")
runCorner.CornerRadius = UDim.new(0, 6)
runCorner.Parent = run

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0.5)
close.Position = UDim2.new(1, -12, 0.5, 0)
close.Size = UDim2.fromOffset(34, 30)
close.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
close.BorderSizePixel = 0
close.Font = Enum.Font.GothamBold
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.TextSize = 14
close.Parent = bar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = close

local suggestions = Instance.new("TextLabel")
suggestions.Name = "Suggestions"
suggestions.Position = UDim2.fromOffset(0, -24)
suggestions.Size = UDim2.new(1, 0, 0, 24)
suggestions.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
suggestions.BackgroundTransparency = 0.35
suggestions.BorderSizePixel = 0
suggestions.Font = Enum.Font.Code
suggestions.Text = ""
suggestions.TextColor3 = Color3.fromRGB(170, 170, 170)
suggestions.TextSize = 14
suggestions.TextXAlignment = Enum.TextXAlignment.Left
suggestions.TextTruncate = Enum.TextTruncate.AtEnd
suggestions.Visible = false
suggestions.Parent = bar
local suggestionsPadding = Instance.new("UIPadding")
suggestionsPadding.PaddingLeft = UDim.new(0, 32)
suggestionsPadding.Parent = suggestions

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(0, 1)
toast.Position = UDim2.new(0, 0, 1, 0)
toast.Size = UDim2.new(1, 0, 0, 28)
toast.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toast.BackgroundTransparency = 0.25
toast.BorderSizePixel = 0
toast.Font = Enum.Font.Code
toast.Text = ""
toast.TextColor3 = Color3.fromRGB(255, 255, 255)
toast.TextSize = 16
toast.TextWrapped = true
toast.TextXAlignment = Enum.TextXAlignment.Left
toast.Visible = false
toast.Parent = gui
local toastPadding = Instance.new("UIPadding")
toastPadding.PaddingLeft = UDim.new(0, 32)
toastPadding.PaddingRight = UDim.new(0, 12)
toastPadding.Parent = toast

local toggle = Instance.new("TextButton")
toggle.Name = "Toggle"
toggle.AnchorPoint = Vector2.new(1, 0)
toggle.Position = UDim2.new(1, -12, 0, 8)
toggle.Size = UDim2.fromOffset(40, 40)
toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toggle.BackgroundTransparency = 0.3
toggle.BorderSizePixel = 0
toggle.Font = Enum.Font.Code
toggle.Text = ";"
toggle.TextColor3 = Color3.fromRGB(0, 255, 120)
toggle.TextSize = 26
toggle.Visible = false
toggle.Parent = gui
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggle

local history = {}
local historyIndex = 0
local isOpen = false
local justOpened = false
local toastToken = 0
local keyboardOffset = 0

local function layout()
	bar.Position = UDim2.new(0, 0, 1, -keyboardOffset)
	local lift = keyboardOffset
	if isOpen then
		lift += BAR_HEIGHT + 28
	end
	toast.Position = UDim2.new(0, 0, 1, -lift)
end

local function updateKeyboard()
	if UserInputService.OnScreenKeyboardVisible then
		local top = UserInputService.OnScreenKeyboardPosition.Y
		keyboardOffset = math.max(0, gui.AbsoluteSize.Y - top)
	else
		keyboardOffset = 0
	end
	layout()
end

local function hasAccess()
	return player:GetAttribute("CmdlineAuthorized") == true
end

local function updateToggle()
	toggle.Visible = hasAccess() and UserInputService.TouchEnabled and not isOpen
end

local function commandNames()
	local raw = executeEvent:GetAttribute("CommandList") or ""
	local list = {}
	for name in string.gmatch(raw, "[^,]+") do
		table.insert(list, name)
	end
	table.insert(list, "serverm")
	table.sort(list)
	return list
end

local function matchesFor(prefix)
	local out = {}
	if prefix == "" then
		return out
	end
	for _, name in ipairs(commandNames()) do
		if string.sub(string.lower(name), 1, #prefix) == prefix then
			table.insert(out, name)
		end
	end
	return out
end

local function refreshSuggestions()
	local text = string.gsub(box.Text, "^%s*;?", "")
	if string.find(text, "%s") or text == "" then
		suggestions.Visible = false
		return
	end
	local found = matchesFor(string.lower(text))
	if #found == 0 then
		suggestions.Visible = false
		return
	end
	suggestions.Text = table.concat(found, "   ", 1, math.min(#found, 8))
	suggestions.Visible = true
end

local function showToast(text, ok)
	toastToken += 1
	local token = toastToken
	toast.Text = text
	toast.TextColor3 = ok and Color3.fromRGB(120, 255, 160) or Color3.fromRGB(255, 110, 110)
	toast.Visible = true
	local lines = math.max(1, math.ceil(#text / 80))
	toast.Size = UDim2.new(1, 0, 0, 12 + lines * 18)
	layout()
	task.delay(TOAST_TIME, function()
		if token == toastToken then
			toast.Visible = false
		end
	end)
end

local function closeBar()
	if not isOpen then
		return
	end
	isOpen = false
	bar.Visible = false
	suggestions.Visible = false
	if box:IsFocused() then
		box:ReleaseFocus()
	end
	layout()
	updateToggle()
end

local function openBar()
	if not hasAccess() then
		return
	end
	isOpen = true
	justOpened = true
	bar.Visible = true
	box.Text = ""
	historyIndex = #history + 1
	layout()
	updateToggle()
	task.defer(function()
		box:CaptureFocus()
	end)
	task.delay(0.25, function()
		justOpened = false
	end)
end

local function submit(text)
	text = string.gsub(text, "^%s+", "")
	text = string.gsub(text, "%s+$", "")
	if text == "" then
		return
	end
	if history[#history] ~= text then
		table.insert(history, text)
		if #history > HISTORY_LIMIT then
			table.remove(history, 1)
		end
	end
	local first = string.lower(string.match(text, "^;?%s*(%S+)") or "")
	box.Text = ""
	closeBar()
	if first == "serverm" then
		player:SetAttribute("ServerMessageOpenRequest", os.clock())
		return
	end
	executeEvent:FireServer(text)
end

box:GetPropertyChangedSignal("Text"):Connect(function()
	if justOpened and box.Text == ";" then
		box.Text = ""
		return
	end
	refreshSuggestions()
end)

box.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		submit(box.Text)
	end
end)

run.Activated:Connect(function()
	submit(box.Text)
end)

close.Activated:Connect(closeBar)

toggle.Activated:Connect(function()
	if isOpen then
		closeBar()
	else
		openBar()
	end
end)

UserInputService.InputBegan:Connect(function(input)
	if not isOpen or not box:IsFocused() then
		return
	end
	if input.KeyCode == Enum.KeyCode.Up then
		if #history > 0 then
			historyIndex = math.max(1, historyIndex - 1)
			box.Text = history[historyIndex] or ""
			box.CursorPosition = #box.Text + 1
		end
	elseif input.KeyCode == Enum.KeyCode.Down then
		if #history > 0 then
			historyIndex = math.min(#history + 1, historyIndex + 1)
			box.Text = history[historyIndex] or ""
			box.CursorPosition = #box.Text + 1
		end
	elseif input.KeyCode == Enum.KeyCode.Tab then
		local text = string.gsub(box.Text, "^%s*;?", "")
		if not string.find(text, "%s") then
			local found = matchesFor(string.lower(text))
			if #found > 0 then
				box.Text = found[1] .. " "
				box.CursorPosition = #box.Text + 1
			end
		end
	end
end)

ContextActionService:BindAction("CmdlineToggle", function(_, state)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if not hasAccess() then
		return Enum.ContextActionResult.Pass
	end
	if isOpen then
		if not box:IsFocused() then
			task.defer(function()
				box:CaptureFocus()
			end)
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end
	openBar()
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.Semicolon)

player.Chatted:Connect(function(message)
	if string.match(string.lower(message), "^%s*;cmdline%s*$") then
		openBar()
	end
end)

resultEvent.OnClientEvent:Connect(function(ok, message)
	showToast(tostring(message), ok == true)
end)

player:GetAttributeChangedSignal("CmdlineAuthorized"):Connect(function()
	if not hasAccess() then
		closeBar()
	end
	updateToggle()
end)

executeEvent:GetAttributeChangedSignal("CommandList"):Connect(refreshSuggestions)

updateToggle()
updateKeyboard()
UserInputService:GetPropertyChangedSignal("OnScreenKeyboardVisible"):Connect(updateKeyboard)
UserInputService:GetPropertyChangedSignal("OnScreenKeyboardPosition"):Connect(updateKeyboard)
UserInputService:GetPropertyChangedSignal("OnScreenKeyboardSize"):Connect(updateKeyboard)
