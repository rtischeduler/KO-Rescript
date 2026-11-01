local player = game.Players.LocalPlayer
repeat wait() until player.Character.Humanoid
local humanoid = player.Character.Humanoid
local mouse = player:GetMouse()

local anim = Instance.new("Animation")
anim.AnimationId = "http://www.roblox.com/asset/?id=10881312757"

mouse.KeyDown:connect(function(key)
	if key == "3" then
		local playAnim = humanoid:LoadAnimation(anim)
		playAnim:Play()

	end
end)
