local button = script.Parent

button.MouseButton1Down:Connect(function()
	script.Parent.Parent.Parent.Visible = false
end)
