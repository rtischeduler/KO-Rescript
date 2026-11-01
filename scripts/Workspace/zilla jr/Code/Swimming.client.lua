-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiler will be improved VERY SOON!
-- Decompiled with Konstant V2.1, a fast Luau decompiler made in Luau by plusgiant5 (https://discord.gg/wyButjTMhM)
-- Decompiled on 2025-05-07 10:06:38
-- Luau version 6, Types version 3
-- Time taken: 0.001336 seconds

local Character_upvr = game.Players.LocalPlayer.Character
local UserInputService = game:GetService("UserInputService")
local BodyPosition_upvr = Instance.new("BodyPosition", Character_upvr.HumanoidRootPart)
BodyPosition_upvr.Name = "SwimMover"
BodyPosition_upvr.MaxForce = Vector3.new(0, 0, 0)
local var4_upvw = "None"
UserInputService.InputBegan:Connect(function(arg1, arg2) -- Line 11
	--[[ Upvalues[1]:
		[1]: var4_upvw (read and write)
	]]
	if arg1.KeyCode == Enum.KeyCode.Q and not arg2 then
		var4_upvw = "Descending"
	end
end)
UserInputService.InputEnded:Connect(function(arg1) -- Line 16
	--[[ Upvalues[1]:
		[1]: var4_upvw (read and write)
	]]
	if arg1.KeyCode == Enum.KeyCode.Q then
		var4_upvw = "None"
	end
end)
UserInputService.InputBegan:Connect(function(arg1, arg2) -- Line 22
	--[[ Upvalues[1]:
		[1]: var4_upvw (read and write)
	]]
	if arg1.KeyCode == Enum.KeyCode.Space and not arg2 then
		var4_upvw = "Ascending"
	end
end)
UserInputService.InputEnded:Connect(function(arg1) -- Line 27
	--[[ Upvalues[1]:
		[1]: var4_upvw (read and write)
	]]
	if arg1.KeyCode == Enum.KeyCode.Space then
		var4_upvw = "None"
	end
end)
local var10_upvw = false
game:GetService("RunService").Heartbeat:Connect(function() -- Line 33
	--[[ Upvalues[4]:
		[1]: Character_upvr (readonly)
		[2]: var10_upvw (read and write)
		[3]: BodyPosition_upvr (readonly)
		[4]: var4_upvw (read and write)
	]]
	if Character_upvr.Head.Position.Y < 276 and var10_upvw == false then
		var10_upvw = true
		BodyPosition_upvr.MaxForce = Vector3.new(0, math.huge, 0)
		BodyPosition_upvr.Position = Character_upvr.HumanoidRootPart.Position
	elseif 276 < Character_upvr.HumanoidRootPart.Position.Y then
		var10_upvw = false
		BodyPosition_upvr.MaxForce = Vector3.new(0, 0, 0)
		BodyPosition_upvr.Position = Character_upvr.HumanoidRootPart.Position
	end
	if var4_upvw == "None" then
		BodyPosition_upvr.Position = BodyPosition_upvr.Position
	else
		if var4_upvw == "Descending" then
			BodyPosition_upvr.Position -= Vector3.new(0, 1, 0)
			return
		end
		if var4_upvw == "Ascending" then
			BodyPosition_upvr.Position += Vector3.new(0, 1, 0)
		end
	end
end)