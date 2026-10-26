local Skins = script.Parent
if Skins then
	Skins.MouseButton1Click:Connect(function()
		script.Parent.Parent.Visible = false
		script.Parent.Parent.Parent.BuyGCells.Visible = true
	end)
end
