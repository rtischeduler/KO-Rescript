local ToggledOffImage = script.Parent.Image
local ToggledOnImage = script.Parent.HoverImage
local Button = script.Parent
local Player = game.Players.LocalPlayer
local PlayerGUI = Player:WaitForChild("PlayerGui")

Button.MouseButton1Click:Connect(function()
	if Button.Image == ToggledOffImage then
		Button.Image = ToggledOnImage
		PlayerGUI.Music.Music.Volume = 0
	else
		Button.Image = ToggledOffImage
		PlayerGUI.Music.Music.Volume = 1.2
	end
end)
