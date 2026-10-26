
wait(0.2)
local Player = game.Players.LocalPlayer
if Player.Name == "L0tzie" then
	script.Parent.Visible = true
	return
else
	script.Parent:Destroy()
end
