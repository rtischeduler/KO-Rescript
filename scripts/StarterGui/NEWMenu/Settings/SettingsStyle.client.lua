local settings = script.Parent

if settings:IsA("GuiObject") then
	settings.AnchorPoint = Vector2.zero
	settings.Size = UDim2.new(0.792, 0, 0.931, 0)
	settings.BackgroundColor3 = Color3.fromRGB(116, 125, 255)
	settings.BackgroundTransparency = 0
	settings.BorderSizePixel = 0
	local corner = settings:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
	corner.Parent = settings
end