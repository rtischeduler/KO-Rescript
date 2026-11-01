-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiler will be improved VERY SOON!
-- Decompiled with Konstant V2.1, a fast Luau decompiler made in Luau by plusgiant5 (https://discord.gg/wyButjTMhM)
-- Decompiled on 2025-05-07 10:06:37
-- Luau version 6, Types version 3
-- Time taken: 0.000824 seconds

local LocalPlayer_upvr = game.Players.LocalPlayer
local mouse_upvr = LocalPlayer_upvr:GetMouse()
game:GetService("RunService").Heartbeat:Connect(function() -- Line 4
	--[[ Upvalues[2]:
		[1]: mouse_upvr (readonly)
		[2]: LocalPlayer_upvr (readonly)
	]]
	script.Parent.RemoteEvents.Beam:FireServer("UpdateMousePos", mouse_upvr.Hit.p)
	LocalPlayer_upvr.Character:WaitForChild("Code").MouseX.Value = tostring(mouse_upvr.Hit.p.X)
	LocalPlayer_upvr.Character:WaitForChild("Code").MouseY.Value = tostring(mouse_upvr.Hit.p.Y)
	LocalPlayer_upvr.Character:WaitForChild("Code").MouseZ.Value = tostring(mouse_upvr.Hit.p.Z)
end)