local player = game.Players.LocalPlayer
local textbutton = script.Parent
local Music = player.PlayerGui:WaitForChild("Music"):FindFirstChild("Music")

textbutton.MouseButton1Click:Connect(function()
	if Music then
		Music:Play()
	end
	textbutton.Text = "Mute Music"
	script.Disabled = true
	script.Parent.MuteMusic.Disabled = false
end)
