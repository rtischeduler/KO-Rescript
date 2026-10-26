local player = game.Players.LocalPlayer
repeat wait() until player.Character.Humanoid
local humanoid = player.Character.Humanoid
local mouse = player:GetMouse()

local anim = Instance.new("Animation")
anim.AnimationId = "http://www.roblox.com/asset/?id=10880983526"

mouse.KeyDown:connect(function(key)
	if key == "r" then
		local playAnim = humanoid:LoadAnimation(anim)
		playAnim:Play()
		script.Parent.CharacterScripts.Sounds.Roar1:Play()
	end
end)
