local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ALLOWED = {
	[string.lower("L0tzie")] = true,
	[string.lower("DenisTheCheeseKing")] = true,
	[string.lower("DandyDandicusDancif")] = true,
	[string.lower("25X_Rock")] = true,
}
local COMMAND = ";serverm"
local HOLD_TIME = 6
local FADE_TIME = 0.5
local MAX_LENGTH = 200
local MAX_NAME_LENGTH = 32

local player = Players.LocalPlayer
local sendEvent = ReplicatedStorage:WaitForChild("ServerMessageSend")
local showEvent = ReplicatedStorage:WaitForChild("ServerMessageShow")

local gui = Instance.new("ScreenGui")
gui.Name = "ServerMessageGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000
gui.Parent = player:WaitForChild("PlayerGui")

local panel
local currentToken = 0

local function closePanel()
	if panel then
		panel:Destroy()
		panel = nil
	end
end

local function openPanel()
	if not ALLOWED[string.lower(player.Name)] then
		return
	end
	closePanel()

	panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(420, 268)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(70, 70, 70)
	stroke.Thickness = 1
	stroke.Parent = panel

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(16, 10)
	title.Size = UDim2.new(1, -60, 0, 28)
	title.Font = Enum.Font.GothamBold
	title.Text = "Server Message"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -12, 0, 10)
	close.Size = UDim2.fromOffset(28, 28)
	close.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	close.BorderSizePixel = 0
	close.Font = Enum.Font.GothamBold
	close.Text = "X"
	close.TextColor3 = Color3.fromRGB(255, 255, 255)
	close.TextSize = 14
	close.Parent = panel
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = close

	local nameBox = Instance.new("TextBox")
	nameBox.Position = UDim2.fromOffset(16, 48)
	nameBox.Size = UDim2.new(1, -32, 0, 34)
	nameBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	nameBox.BorderSizePixel = 0
	nameBox.ClearTextOnFocus = false
	nameBox.Font = Enum.Font.Gotham
	nameBox.PlaceholderText = "Custom display name (leave empty to show yours)"
	nameBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
	nameBox.Text = ""
	nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameBox.TextSize = 15
	nameBox.TextXAlignment = Enum.TextXAlignment.Left
	nameBox.Parent = panel
	local nameCorner = Instance.new("UICorner")
	nameCorner.CornerRadius = UDim.new(0, 8)
	nameCorner.Parent = nameBox
	local namePadding = Instance.new("UIPadding")
	namePadding.PaddingLeft = UDim.new(0, 8)
	namePadding.PaddingRight = UDim.new(0, 8)
	namePadding.Parent = nameBox

	local box = Instance.new("TextBox")
	box.Position = UDim2.fromOffset(16, 92)
	box.Size = UDim2.new(1, -32, 0, 100)
	box.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.MultiLine = true
	box.TextWrapped = true
	box.Font = Enum.Font.Gotham
	box.PlaceholderText = "Type your message..."
	box.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
	box.Text = ""
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.TextSize = 16
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextYAlignment = Enum.TextYAlignment.Top
	box.Parent = panel
	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 8)
	boxCorner.Parent = box
	local boxPadding = Instance.new("UIPadding")
	boxPadding.PaddingLeft = UDim.new(0, 8)
	boxPadding.PaddingRight = UDim.new(0, 8)
	boxPadding.PaddingTop = UDim.new(0, 8)
	boxPadding.PaddingBottom = UDim.new(0, 8)
	boxPadding.Parent = box

	local send = Instance.new("TextButton")
	send.AnchorPoint = Vector2.new(0.5, 1)
	send.Position = UDim2.new(0.5, 0, 1, -16)
	send.Size = UDim2.fromOffset(160, 36)
	send.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
	send.BorderSizePixel = 0
	send.Font = Enum.Font.GothamBold
	send.Text = "Send"
	send.TextColor3 = Color3.fromRGB(255, 255, 255)
	send.TextSize = 16
	send.Parent = panel
	local sendCorner = Instance.new("UICorner")
	sendCorner.CornerRadius = UDim.new(0, 8)
	sendCorner.Parent = send

	box:GetPropertyChangedSignal("Text"):Connect(function()
		if #box.Text > MAX_LENGTH then
			box.Text = box.Text:sub(1, MAX_LENGTH)
		end
	end)

	nameBox:GetPropertyChangedSignal("Text"):Connect(function()
		if #nameBox.Text > MAX_NAME_LENGTH then
			nameBox.Text = nameBox.Text:sub(1, MAX_NAME_LENGTH)
		end
	end)

	close.Activated:Connect(closePanel)
	send.Activated:Connect(function()
		local text = box.Text
		if text:match("^%s*$") then
			return
		end
		sendEvent:FireServer(text, nameBox.Text)
		closePanel()
	end)

	task.defer(function()
		if box and box.Parent then
			box:CaptureFocus()
		end
	end)
end

local function showMessage(name, userId, message, anonymous)
	currentToken += 1
	local token = currentToken

	local old = gui:FindFirstChild("Message")
	if old then
		old:Destroy()
	end

	local frame = Instance.new("Frame")
	frame.Name = "Message"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Active = false
	frame.Parent = gui

	local avatar = Instance.new("ImageLabel")
	avatar.AnchorPoint = Vector2.new(0.5, 0)
	avatar.Position = UDim2.new(0.5, 0, 0, 40)
	avatar.Size = UDim2.fromOffset(64, 64)
	avatar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	avatar.BackgroundTransparency = 1
	avatar.ImageTransparency = 1
	avatar.BorderSizePixel = 0
	avatar.Parent = frame
	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatar

	local hasAvatar = userId > 0
	avatar.Visible = hasAvatar

	task.spawn(function()
		if not hasAvatar then
			return
		end
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok and avatar.Parent then
			avatar.Image = content
		end
	end)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.AnchorPoint = Vector2.new(0.5, 0)
	nameLabel.Position = UDim2.new(0.5, 0, 0, hasAvatar and 110 or 40)
	nameLabel.Size = UDim2.fromOffset(300, 24)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 20
	nameLabel.TextTransparency = 1
	nameLabel.Parent = frame

	local messageLabel = Instance.new("TextLabel")
	messageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	messageLabel.Position = UDim2.fromScale(0.5, 0.5)
	messageLabel.Size = UDim2.new(0.7, 0, 0.4, 0)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Font = Enum.Font.GothamMedium
	messageLabel.Text = message
	messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	messageLabel.TextScaled = true
	messageLabel.TextWrapped = true
	messageLabel.TextTransparency = 1
	messageLabel.Parent = frame
	local sizeLimit = Instance.new("UITextSizeConstraint")
	sizeLimit.MaxTextSize = 40
	sizeLimit.MinTextSize = 12
	sizeLimit.Parent = messageLabel

	local fadeIn = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(frame, fadeIn, { BackgroundTransparency = 0.35 }):Play()
	TweenService:Create(avatar, fadeIn, { ImageTransparency = 0 }):Play()
	TweenService:Create(nameLabel, fadeIn, { TextTransparency = 0 }):Play()
	TweenService:Create(messageLabel, fadeIn, { TextTransparency = 0 }):Play()

	task.delay(HOLD_TIME, function()
		if token ~= currentToken or not frame.Parent then
			return
		end
		local fadeOut = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(frame, fadeOut, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(avatar, fadeOut, { ImageTransparency = 1 }):Play()
		TweenService:Create(nameLabel, fadeOut, { TextTransparency = 1 }):Play()
		TweenService:Create(messageLabel, fadeOut, { TextTransparency = 1 }):Play()
		task.wait(FADE_TIME)
		if token == currentToken and frame.Parent then
			frame:Destroy()
		end
	end)
end

showEvent.OnClientEvent:Connect(function(name, userId, message, anonymous)
	if typeof(name) ~= "string" or typeof(userId) ~= "number" or typeof(message) ~= "string" then
		return
	end
	showMessage(name, userId, message, anonymous == true)
end)

player:GetAttributeChangedSignal("ServerMessageOpenRequest"):Connect(function()
	openPanel()
end)

player.Chatted:Connect(function(text)
	if not ALLOWED[string.lower(player.Name)] then
		return
	end
	if text:lower():match("^%s*" .. COMMAND .. "%s*$") then
		openPanel()
	end
end)