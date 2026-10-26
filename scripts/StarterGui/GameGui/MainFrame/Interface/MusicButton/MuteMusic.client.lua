local player = game.Players.LocalPlayer
local textbutton = script.Parent
local Music = player.PlayerGui:WaitForChild("Music"):FindFirstChild("Music")

textbutton.MouseButton1Click:Connect(function()
	if Music then
		Music:Pause()
	end
	textbutton.Text = "Unmute Music"
	script.Disabled = true
	script.Parent.UnmuteMusic.Disabled = false
end)
