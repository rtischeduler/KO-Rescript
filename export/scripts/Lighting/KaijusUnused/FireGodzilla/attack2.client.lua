local player = game.Players.LocalPlayer
repeat wait() until player.Character.Humanoid
local humanoid = player.Character.Humanoid
local mouse = player:GetMouse()

local anim = Instance.new("Animation")
anim.AnimationId = "http://www.roblox.com/asset/?id=10881322130"

mouse.KeyDown:connect(function(key)
	if key == "2" then
		local playAnim = humanoid:LoadAnimation(anim)

		script.Parent.CharacterScripts.Sounds.Beam:Play()

		playAnim:Play()
		wait(3.5)

		wait(5)

	end
end)
