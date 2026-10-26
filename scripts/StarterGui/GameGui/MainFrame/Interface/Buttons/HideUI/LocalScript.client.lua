local Button = script.Parent
local ToggledOffImage = script.Parent.Image
local ToggledOnImage = script.Parent.HoverImage
local Toggled = false

Button.MouseButton1Click:Connect(function()
	if Toggled == false then
		Toggled = true
		script.Parent.Image = ToggledOnImage
		script.Parent.Parent.CtrlLock.Visible = false
		script.Parent.Parent.Music.Visible = false
		script.Parent.Parent.Shop.Visible = false
		script.Parent.Parent.GCells.Visible = false
		script.Parent.Parent.Parent.Backpack.Visible = false
		script.Parent.Parent.Parent.Bars.Visible = false
	else
		Toggled = false
		script.Parent.Image = ToggledOffImage
		script.Parent.Parent.CtrlLock.Visible = true
		script.Parent.Parent.Music.Visible = true
		script.Parent.Parent.Shop.Visible = true
		script.Parent.Parent.GCells.Visible = true
		script.Parent.Parent.Parent.Backpack.Visible = true
		script.Parent.Parent.Parent.Bars.Visible = true
	end
end)
