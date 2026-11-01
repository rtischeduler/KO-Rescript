-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

-- Decompiler will be improved VERY SOON!
-- Decompiled with Konstant V2.1, a fast Luau decompiler made in Luau by plusgiant5 (https://discord.gg/wyButjTMhM)
-- Decompiled on 2025-05-07 10:06:36
-- Luau version 6, Types version 3
-- Time taken: 0.019172 seconds

local LocalPlayer_upvr = game.Players.LocalPlayer
local any_GetControls_result1_upvr = require(game.Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
local mouse = LocalPlayer_upvr:GetMouse()
mouse.TargetFilter = workspace.Placeholders
local Parent_upvr = script.Parent.Parent
local Humanoid_upvr = Parent_upvr:WaitForChild("Humanoid")
local CurrentCamera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local LocalKaijuModules_upvr = require(game.ReplicatedStorage.LocalKaijuModules)
local Stats_upvr = script.Parent.Stats
local RemoteEvents_upvr = script.Parent.RemoteEvents
local AnimTracks = script.AnimTracks
local var12_upvw = false
local any_LoadAnimation_result1 = Humanoid_upvr:LoadAnimation(AnimTracks.Idle)
any_LoadAnimation_result1:Play()
WS = Stats_upvr.WS.Value -- Setting global
SS = Stats_upvr.SS.Value -- Setting global
SwimSpeed = Stats_upvr.SwimSpeed.Value -- Setting global
CurrentCamera.CFrame = workspace.Cutscene.BeforeChar.CFrame
any_GetControls_result1_upvr:Disable()
game.TweenService:Create(CurrentCamera, TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	CFrame = Parent_upvr.TrackPart.CFrame * CFrame.new(0, 0, 180);
}):Play()
wait(5)
any_LoadAnimation_result1:Stop()
any_GetControls_result1_upvr:Enable()
CurrentCamera.FieldOfView = 45
CurrentCamera.CameraSubject = Parent_upvr.Camera
CurrentCamera.CameraType = Enum.CameraType.Custom
LocalPlayer_upvr.CameraMinZoomDistance = 25
LocalPlayer_upvr.CameraMaxZoomDistance = 125
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled and not UserInputService.GamepadEnabled and not game.GuiService:IsTenFootInterface() then
	var12_upvw = true
end
local Value_upvr_6 = Stats_upvr.SE_ENEMY_1.Value
local Value_upvr_2 = Stats_upvr.SE_SELF_1.Value
local Value_upvr_3 = Stats_upvr.SE_ENEMY_2.Value
local Value_upvr = Stats_upvr.SE_SELF_2.Value
local Value_upvr_4 = Stats_upvr.AttackCooldown.Value
local Value_upvr_5 = Stats_upvr.PulseCooldown.Value
local any_LoadAnimation_result1_2_upvr = Humanoid_upvr:LoadAnimation(AnimTracks.Idle)
local any_LoadAnimation_result1_upvr_4 = Humanoid_upvr:LoadAnimation(AnimTracks.Walk)
local any_LoadAnimation_result1_upvr_5 = Humanoid_upvr:LoadAnimation(AnimTracks.Sprint)
local any_LoadAnimation_result1_10_upvr = Humanoid_upvr:LoadAnimation(AnimTracks.Roar1)
local any_LoadAnimation_result1_4_upvr = Humanoid_upvr:LoadAnimation(AnimTracks.Roar2)
local any_LoadAnimation_result1_6_upvr = Humanoid_upvr:LoadAnimation(AnimTracks.Melee1)
local any_LoadAnimation_result1_11_upvr = Humanoid_upvr:LoadAnimation(AnimTracks.Melee2)
local any_LoadAnimation_result1_3_upvr = Humanoid_upvr:LoadAnimation(AnimTracks.Melee3)
local any_LoadAnimation_result1_5_upvr = Humanoid_upvr:LoadAnimation(AnimTracks.BeamCharge)
local any_LoadAnimation_result1_12_upvr = Humanoid_upvr:LoadAnimation(AnimTracks.Beam)
local any_LoadAnimation_result1_upvr_3 = Humanoid_upvr:LoadAnimation(AnimTracks.SwimMovement)
local any_LoadAnimation_result1_13_upvr = Humanoid_upvr:LoadAnimation(AnimTracks.SwimIdle)
local any_LoadAnimation_result1_7_upvr = Humanoid_upvr:LoadAnimation(AnimTracks.Hurt)
local any_LoadAnimation_result1_upvr_2 = Humanoid_upvr:LoadAnimation(AnimTracks.Pulse)
local any_LoadAnimation_result1_upvr = Humanoid_upvr:LoadAnimation(AnimTracks.Grab)
local Interface_upvr = LocalPlayer_upvr.PlayerGui:WaitForChild("Interface")
function CreateError(arg1) -- Line 76
	--[[ Upvalues[1]:
		[1]: Interface_upvr (readonly)
	]]
	if Interface_upvr.ErrorMessage.Visible == false then
		Interface_upvr.ErrorMessage.Visible = true
		Interface_upvr.ErrorMessage.Text = arg1
		wait(3)
		Interface_upvr.ErrorMessage.Visible = false
	else
		Interface_upvr.ErrorMessage.Text = arg1
	end
end
LastCharge = tick() -- Setting global
local var37_upvw = true
local var38_upvw = true
local var39_upvw = false
local var40_upvw = true
local var41_upvw = false
local var42_upvw = true
local var43_upvw = false
local var44_upvw = false
local var45_upvw = false
local var46_upvw = true
local var47_upvw = false
local var48_upvw = true
local var49_upvw = false
local var50_upvw = false
local var51_upvw = true
repeat
	wait()
until Parent_upvr.HumanoidRootPart:FindFirstChild("SwimMover")
any_LoadAnimation_result1_2_upvr:Play()
any_LoadAnimation_result1_10_upvr:Play()
RemoteEvents_upvr.Roar:FireServer('1', var39_upvw, Value_upvr_6, Value_upvr_2, 5)
local Public_upvr = require(game.ReplicatedStorage.PlayerDataManager).GetPlayerData(LocalPlayer_upvr).Public
local TweenService_upvr = game.TweenService
local TweenInfo_new_result1_upvr = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0)
function TweenFOV(arg1) -- Line 116
	--[[ Upvalues[4]:
		[1]: Humanoid_upvr (readonly)
		[2]: Public_upvr (readonly)
		[3]: TweenService_upvr (readonly)
		[4]: TweenInfo_new_result1_upvr (readonly)
	]]
	if Humanoid_upvr.MoveDirection.Magnitude <= 0 and Public_upvr.DynamicFOV == "On" then
		local tbl = {}
		tbl.FieldOfView = arg1
		TweenService_upvr:Create(workspace.CurrentCamera, TweenInfo_new_result1_upvr, tbl):Play()
	end
end
repeat
	wait()
until any_LoadAnimation_result1_2_upvr.IsPlaying == true
RemoteEvents_upvr.ControlEnabled:FireServer()
Humanoid_upvr:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
Humanoid_upvr:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
Humanoid_upvr:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
local var57_upvw = false
UserInputService.InputBegan:Connect(function(arg1, arg2) -- Line 131
	--[[ Upvalues[1]:
		[1]: var57_upvw (read and write)
	]]
	if arg1.KeyCode == Enum.KeyCode.F and not arg2 then
		var57_upvw = not var57_upvw
	end
end)
UserInputService.InputBegan:Connect(function(arg1, arg2) -- Line 138
	--[[ Upvalues[2]:
		[1]: Humanoid_upvr (readonly)
		[2]: var50_upvw (read and write)
	]]
	if arg1.KeyCode == Enum.KeyCode.LeftControl and not arg2 and Humanoid_upvr.MoveDirection.Magnitude <= 0 and not var50_upvw then
		var50_upvw = true
	end
end)
UserInputService.InputEnded:Connect(function(arg1, arg2) -- Line 145
	--[[ Upvalues[1]:
		[1]: var50_upvw (read and write)
	]]
	if arg1.KeyCode == Enum.KeyCode.LeftControl and not arg2 and var50_upvw then
		var50_upvw = false
	end
end)
Parent_upvr.HumanoidRootPart.SwimMover.Changed:Connect(function() -- Line 154
	--[[ Upvalues[3]:
		[1]: Parent_upvr (readonly)
		[2]: var45_upvw (read and write)
		[3]: RemoteEvents_upvr (readonly)
	]]
	if Parent_upvr.HumanoidRootPart.SwimMover.MaxForce == Vector3.new(0, 0, 0) then
		var45_upvw = false
		RemoteEvents_upvr.Swim:FireServer(false)
	elseif Parent_upvr.HumanoidRootPart.SwimMover.MaxForce == Vector3.new(0, math.huge, 0) then
		var45_upvw = true
		RemoteEvents_upvr.Swim:FireServer(true)
	end
end)
Humanoid_upvr:GetPropertyChangedSignal("MoveDirection"):Connect(function() -- Line 165
	--[[ Upvalues[10]:
		[1]: var48_upvw (read and write)
		[2]: LocalKaijuModules_upvr (readonly)
		[3]: Humanoid_upvr (readonly)
		[4]: var44_upvw (read and write)
		[5]: var45_upvw (read and write)
		[6]: any_LoadAnimation_result1_upvr_4 (readonly)
		[7]: any_LoadAnimation_result1_upvr_5 (readonly)
		[8]: any_LoadAnimation_result1_2_upvr (readonly)
		[9]: any_LoadAnimation_result1_upvr_3 (readonly)
		[10]: any_LoadAnimation_result1_13_upvr (readonly)
	]]
	if var48_upvw == true then
		LocalKaijuModules_upvr.Movement(Humanoid_upvr, var44_upvw, var45_upvw, any_LoadAnimation_result1_upvr_4, any_LoadAnimation_result1_upvr_5, any_LoadAnimation_result1_2_upvr, any_LoadAnimation_result1_upvr_3, any_LoadAnimation_result1_13_upvr, WS, SS, SwimSpeed)
	end
end)
Humanoid_upvr:GetPropertyChangedSignal("WalkSpeed"):Connect(function() -- Line 171
	--[[ Upvalues[10]:
		[1]: var48_upvw (read and write)
		[2]: Humanoid_upvr (readonly)
		[3]: LocalKaijuModules_upvr (readonly)
		[4]: var44_upvw (read and write)
		[5]: var45_upvw (read and write)
		[6]: any_LoadAnimation_result1_upvr_4 (readonly)
		[7]: any_LoadAnimation_result1_upvr_5 (readonly)
		[8]: any_LoadAnimation_result1_2_upvr (readonly)
		[9]: any_LoadAnimation_result1_upvr_3 (readonly)
		[10]: any_LoadAnimation_result1_13_upvr (readonly)
	]]
	if var48_upvw == true and Humanoid_upvr.MoveDirection ~= Vector3.new(0, 0, 0) then
		LocalKaijuModules_upvr.Movement(Humanoid_upvr, var44_upvw, var45_upvw, any_LoadAnimation_result1_upvr_4, any_LoadAnimation_result1_upvr_5, any_LoadAnimation_result1_2_upvr, any_LoadAnimation_result1_upvr_3, any_LoadAnimation_result1_13_upvr, WS, SS, SwimSpeed)
	end
end)
any_LoadAnimation_result1_upvr_4.KeyframeReached:Connect(function(arg1) -- Line 178
	--[[ Upvalues[1]:
		[1]: RemoteEvents_upvr (readonly)
	]]
	if arg1 == "Step" then
		RemoteEvents_upvr.Footstep:FireServer("Step")
	end
end)
any_LoadAnimation_result1_upvr_5.KeyframeReached:Connect(function(arg1) -- Line 183
	--[[ Upvalues[1]:
		[1]: RemoteEvents_upvr (readonly)
	]]
	if arg1 == "Step" then
		RemoteEvents_upvr.Footstep:FireServer("Step")
	end
end)
function GetTarget() -- Line 190
	--[[ Upvalues[2]:
		[1]: Parent_upvr (readonly)
		[2]: Stats_upvr (readonly)
	]]
	-- KONSTANTERROR: [0] 1. Error Block 1 start (CF ANALYSIS FAILED)
	local ipairs_result1, ipairs_result2, ipairs_result3 = ipairs(game.Players:GetPlayers())
	-- KONSTANTERROR: [0] 1. Error Block 1 end (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [133] 76. Error Block 13 start (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [133] 76. Error Block 13 end (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [14] 10. Error Block 2 start (CF ANALYSIS FAILED)
	-- KONSTANTWARNING: Failed to evaluate expression, replaced with nil [133.7]
	-- KONSTANTERROR: [14] 10. Error Block 2 end (CF ANALYSIS FAILED)
end
any_LoadAnimation_result1_6_upvr.KeyframeReached:Connect(function(arg1) -- Line 207
	--[[ Upvalues[1]:
		[1]: RemoteEvents_upvr (readonly)
	]]
	if arg1 == "Stomp" then
		RemoteEvents_upvr.Footstep:FireServer("Stomp")
	end
end)
any_LoadAnimation_result1_11_upvr.KeyframeReached:Connect(function(arg1) -- Line 212
	--[[ Upvalues[1]:
		[1]: RemoteEvents_upvr (readonly)
	]]
	if arg1 == "Stomp" then
		RemoteEvents_upvr.Footstep:FireServer("Stomp")
	end
end)
any_LoadAnimation_result1_3_upvr.KeyframeReached:Connect(function(arg1) -- Line 217
	--[[ Upvalues[1]:
		[1]: RemoteEvents_upvr (readonly)
	]]
	if arg1 == "Stomp" then
		RemoteEvents_upvr.Footstep:FireServer("Stomp")
	end
end)
any_LoadAnimation_result1_12_upvr.KeyframeReached:Connect(function(arg1) -- Line 222
	--[[ Upvalues[1]:
		[1]: RemoteEvents_upvr (readonly)
	]]
	if arg1 == "Stomp" then
		RemoteEvents_upvr.Footstep:FireServer("Stomp")
	end
end)
any_LoadAnimation_result1_upvr.KeyframeReached:Connect(function(arg1) -- Line 227
	--[[ Upvalues[2]:
		[1]: RemoteEvents_upvr (readonly)
		[2]: any_LoadAnimation_result1_upvr (readonly)
	]]
	if arg1 == "Grab" then
		Target = GetTarget() -- Setting global
		if Target ~= nil then
			RemoteEvents_upvr.Footstep:FireServer("Grab", Target)
		end
	end
	any_LoadAnimation_result1_upvr.KeyframeReached:Connect(function(arg1_3) -- Line 234
		--[[ Upvalues[1]:
			[1]: RemoteEvents_upvr (copied, readonly)
		]]
		if arg1_3 == "Release" then
			if Target ~= nil then
				RemoteEvents_upvr.Footstep:FireServer("Release", Target)
			end
		end
	end)
end)
UserInputService.InputBegan:connect(function(arg1, arg2) -- Line 244
	--[[ Upvalues[3]:
		[1]: var45_upvw (read and write)
		[2]: var44_upvw (read and write)
		[3]: Humanoid_upvr (readonly)
	]]
	if arg1.KeyCode == Enum.KeyCode.LeftShift and not arg2 and var45_upvw == false and var44_upvw == false then
		Humanoid_upvr.WalkSpeed = SS
		var44_upvw = true
	elseif arg1.KeyCode == Enum.KeyCode.LeftShift and not arg2 and var45_upvw == false and var44_upvw == true then
		Humanoid_upvr.WalkSpeed = WS
		var44_upvw = false
	end
end)
UserInputService.InputBegan:Connect(function(arg1, arg2) -- Line 255
	--[[ Upvalues[9]:
		[1]: var37_upvw (read and write)
		[2]: Stats_upvr (readonly)
		[3]: var49_upvw (read and write)
		[4]: var46_upvw (read and write)
		[5]: any_LoadAnimation_result1_10_upvr (readonly)
		[6]: RemoteEvents_upvr (readonly)
		[7]: var39_upvw (read and write)
		[8]: Value_upvr_6 (readonly)
		[9]: Value_upvr_2 (readonly)
	]]
	if arg1.KeyCode == Enum.KeyCode.R and not arg2 and var37_upvw and Stats_upvr.CanRoar.Value == true and not var49_upvw then
		TweenFOV(50)
		var46_upvw = false
		var37_upvw = false
		any_LoadAnimation_result1_10_upvr:Play()
		RemoteEvents_upvr.Roar:FireServer('1', var39_upvw, Value_upvr_6, Value_upvr_2, 5)
		RemoteEvents_upvr.Cooldown:Fire("Roar", any_LoadAnimation_result1_10_upvr.Length + 5, "Cooldown")
		any_LoadAnimation_result1_10_upvr.Stopped:Connect(function() -- Line 263
			--[[ Upvalues[2]:
				[1]: var46_upvw (copied, read and write)
				[2]: var37_upvw (copied, read and write)
			]]
			TweenFOV(45)
			var46_upvw = true
			wait(5)
			var37_upvw = true
		end)
	elseif arg1.KeyCode == Enum.KeyCode.R and not arg2 and Stats_upvr.CanRoar.Value == true and not var37_upvw then
		CreateError("Wait before you can Roar again")
	end
end)
UserInputService.InputBegan:Connect(function(arg1, arg2) -- Line 274
	--[[ Upvalues[9]:
		[1]: var37_upvw (read and write)
		[2]: Stats_upvr (readonly)
		[3]: var49_upvw (read and write)
		[4]: var46_upvw (read and write)
		[5]: any_LoadAnimation_result1_4_upvr (readonly)
		[6]: RemoteEvents_upvr (readonly)
		[7]: var39_upvw (read and write)
		[8]: Value_upvr_3 (readonly)
		[9]: Value_upvr (readonly)
	]]
	if arg1.KeyCode == Enum.KeyCode.T and not arg2 and var37_upvw and Stats_upvr.CanRoar.Value == true and not var49_upvw then
		TweenFOV(50)
		var37_upvw = false
		var46_upvw = false
		any_LoadAnimation_result1_4_upvr:Play()
		RemoteEvents_upvr.Roar:FireServer('2', var39_upvw, Value_upvr_3, Value_upvr, 5)
		RemoteEvents_upvr.Cooldown:Fire("Roar", any_LoadAnimation_result1_4_upvr.Length + 5, "Cooldown")
		any_LoadAnimation_result1_4_upvr.Stopped:Connect(function() -- Line 282
			--[[ Upvalues[2]:
				[1]: var46_upvw (copied, read and write)
				[2]: var37_upvw (copied, read and write)
			]]
			TweenFOV(45)
			var46_upvw = true
			wait(5)
			var37_upvw = true
		end)
	elseif arg1.KeyCode == Enum.KeyCode.T and not arg2 and Stats_upvr.CanRoar.Value == true and not var37_upvw then
		CreateError("Wait before you can Roar again")
	end
end)
local var80_upvw = "Melee1"
local var81_upvw = 0
function AddCombo() -- Line 298
	--[[ Upvalues[1]:
		[1]: var81_upvw (read and write)
	]]
	if tick() - 0 < 2.5 then
		var81_upvw += 1
	else
		var81_upvw = 0
	end
	TweenFOV(50)
end
local any_LoadAnimation_result1_9_upvr = Humanoid_upvr:LoadAnimation(AnimTracks.Sprint)
mouse.Button1Down:Connect(function() -- Line 308
	--[[ Upvalues[16]:
		[1]: var38_upvw (read and write)
		[2]: any_LoadAnimation_result1_7_upvr (readonly)
		[3]: var12_upvw (read and write)
		[4]: var49_upvw (read and write)
		[5]: any_LoadAnimation_result1_upvr_5 (readonly)
		[6]: var50_upvw (read and write)
		[7]: any_LoadAnimation_result1_9_upvr (readonly)
		[8]: any_LoadAnimation_result1_12_upvr (readonly)
		[9]: var47_upvw (read and write)
		[10]: RemoteEvents_upvr (readonly)
		[11]: Parent_upvr (readonly)
		[12]: var80_upvw (read and write)
		[13]: any_LoadAnimation_result1_6_upvr (readonly)
		[14]: Value_upvr_4 (readonly)
		[15]: any_LoadAnimation_result1_11_upvr (readonly)
		[16]: any_LoadAnimation_result1_3_upvr (readonly)
	]]
	-- KONSTANTERROR: [0] 1. Error Block 1 start (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [0] 1. Error Block 1 end (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [2] 3. Error Block 2 start (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [2] 3. Error Block 2 end (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [7] 6. Error Block 3 start (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [7] 6. Error Block 3 end (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [10] 8. Error Block 4 start (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [10] 8. Error Block 4 end (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [197] 149. Error Block 20 start (CF ANALYSIS FAILED)
	wait(0.3)
	TweenFOV(45)
	wait(0.3)
	any_LoadAnimation_result1_9_upvr:Stop()
	Parent_upvr.HumanoidRootPart.KnockbackVelocity.MaxForce = Vector3.new(0, 0, 0)
	-- KONSTANTERROR: [197] 149. Error Block 20 end (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [221] 166. Error Block 21 start (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [221] 166. Error Block 21 end (CF ANALYSIS FAILED)
end)
UserInputService.InputBegan:Connect(function(arg1, arg2) -- Line 465
	--[[ Upvalues[7]:
		[1]: var38_upvw (read and write)
		[2]: any_LoadAnimation_result1_7_upvr (readonly)
		[3]: var12_upvw (read and write)
		[4]: var49_upvw (read and write)
		[5]: any_LoadAnimation_result1_6_upvr (readonly)
		[6]: RemoteEvents_upvr (readonly)
		[7]: Value_upvr_4 (readonly)
	]]
	if arg1.KeyCode == Enum.KeyCode.One and not arg2 and var38_upvw and any_LoadAnimation_result1_7_upvr.IsPlaying == false and var12_upvw == false and not var49_upvw then
		var38_upvw = false
		TweenFOV(50)
		any_LoadAnimation_result1_6_upvr:Play()
		RemoteEvents_upvr.Attack:FireServer("Melee1")
		RemoteEvents_upvr.Cooldown:Fire("Attack", any_LoadAnimation_result1_6_upvr.Length + Value_upvr_4, "Cooldown")
		any_LoadAnimation_result1_6_upvr.Stopped:Connect(function() -- Line 472
			--[[ Upvalues[2]:
				[1]: Value_upvr_4 (copied, readonly)
				[2]: var38_upvw (copied, read and write)
			]]
			wait(Value_upvr_4)
			var38_upvw = true
		end)
		wait(0.3)
		TweenFOV(45)
	end
end)
UserInputService.InputBegan:Connect(function(arg1, arg2) -- Line 482
	--[[ Upvalues[7]:
		[1]: var38_upvw (read and write)
		[2]: any_LoadAnimation_result1_7_upvr (readonly)
		[3]: var12_upvw (read and write)
		[4]: var49_upvw (read and write)
		[5]: any_LoadAnimation_result1_11_upvr (readonly)
		[6]: RemoteEvents_upvr (readonly)
		[7]: Value_upvr_4 (readonly)
	]]
	if arg1.KeyCode == Enum.KeyCode.Two and not arg2 and var38_upvw and any_LoadAnimation_result1_7_upvr.IsPlaying == false and var12_upvw == false and not var49_upvw then
		var38_upvw = false
		TweenFOV(50)
		any_LoadAnimation_result1_11_upvr:Play()
		RemoteEvents_upvr.Attack:FireServer("Melee2")
		RemoteEvents_upvr.Cooldown:Fire("Attack", any_LoadAnimation_result1_11_upvr.Length + Value_upvr_4, "Cooldown")
		any_LoadAnimation_result1_11_upvr.Stopped:Connect(function() -- Line 489
			--[[ Upvalues[2]:
				[1]: Value_upvr_4 (copied, readonly)
				[2]: var38_upvw (copied, read and write)
			]]
			wait(Value_upvr_4)
			var38_upvw = true
		end)
		wait(0.3)
		TweenFOV(45)
	end
end)
UserInputService.InputBegan:Connect(function(arg1, arg2) -- Line 499
	--[[ Upvalues[7]:
		[1]: var38_upvw (read and write)
		[2]: any_LoadAnimation_result1_7_upvr (readonly)
		[3]: var12_upvw (read and write)
		[4]: var49_upvw (read and write)
		[5]: any_LoadAnimation_result1_3_upvr (readonly)
		[6]: RemoteEvents_upvr (readonly)
		[7]: Value_upvr_4 (readonly)
	]]
	if arg1.KeyCode == Enum.KeyCode.Three and not arg2 and var38_upvw and any_LoadAnimation_result1_7_upvr.IsPlaying == false and var12_upvw == false and not var49_upvw then
		var38_upvw = false
		TweenFOV(50)
		any_LoadAnimation_result1_3_upvr:Play()
		RemoteEvents_upvr.Attack:FireServer("Melee3")
		RemoteEvents_upvr.Cooldown:Fire("Attack", any_LoadAnimation_result1_3_upvr.Length + Value_upvr_4, "Cooldown")
		any_LoadAnimation_result1_3_upvr.Stopped:Connect(function() -- Line 506
			--[[ Upvalues[2]:
				[1]: Value_upvr_4 (copied, readonly)
				[2]: var38_upvw (copied, read and write)
			]]
			wait(Value_upvr_4)
			var38_upvw = true
		end)
		wait(0.3)
		TweenFOV(45)
	end
end)
local var91_upvw = true
UserInputService.InputBegan:Connect(function(arg1, arg2) -- Line 542
	--[[ Upvalues[8]:
		[1]: Stats_upvr (readonly)
		[2]: var38_upvw (read and write)
		[3]: var91_upvw (read and write)
		[4]: any_LoadAnimation_result1_7_upvr (readonly)
		[5]: var12_upvw (read and write)
		[6]: var49_upvw (read and write)
		[7]: any_LoadAnimation_result1_upvr (readonly)
		[8]: RemoteEvents_upvr (readonly)
	]]
	if arg1.KeyCode == Enum.KeyCode.G and Stats_upvr.CanGrab.Value == true and not arg2 and var38_upvw and var91_upvw and any_LoadAnimation_result1_7_upvr.IsPlaying == false and var12_upvw == false and not var49_upvw then
		var38_upvw = false
		var91_upvw = false
		any_LoadAnimation_result1_upvr:Play()
		RemoteEvents_upvr.Attack:FireServer("Melee3")
		RemoteEvents_upvr.Cooldown:Fire("Grab", any_LoadAnimation_result1_upvr.Length + 3, "Cooldown")
		any_LoadAnimation_result1_upvr.Stopped:Connect(function() -- Line 549
			--[[ Upvalues[2]:
				[1]: var38_upvw (copied, read and write)
				[2]: var91_upvw (copied, read and write)
			]]
			var38_upvw = true
			wait(3)
			var91_upvw = true
		end)
	end
end)
UserInputService.InputBegan:Connect(function(arg1, arg2) -- Line 558
	--[[ Upvalues[10]:
		[1]: Stats_upvr (readonly)
		[2]: any_LoadAnimation_result1_upvr_2 (readonly)
		[3]: var51_upvw (read and write)
		[4]: var49_upvw (read and write)
		[5]: var48_upvw (read and write)
		[6]: RemoteEvents_upvr (readonly)
		[7]: Value_upvr_5 (readonly)
		[8]: any_LoadAnimation_result1_upvr_4 (readonly)
		[9]: any_LoadAnimation_result1_upvr_5 (readonly)
		[10]: Parent_upvr (readonly)
	]]
	if arg1.KeyCode == Enum.KeyCode.X and not arg2 and Stats_upvr.Charged.Value == true and 40 < Stats_upvr.Charge.Value and Stats_upvr.CanPulse.Value == true and Stats_upvr.Swimming.Value == false and any_LoadAnimation_result1_upvr_2.IsPlaying == false and var51_upvw == true and not var49_upvw then
		var48_upvw = false
		var51_upvw = false
		RemoteEvents_upvr.Beam:FireServer("ChargePulse")
		RemoteEvents_upvr.Cooldown:Fire("Pulse", any_LoadAnimation_result1_upvr_2.Length + Value_upvr_5, "Active")
		any_LoadAnimation_result1_upvr_2:Play()
		any_LoadAnimation_result1_upvr_4:Stop()
		any_LoadAnimation_result1_upvr_5:Stop()
		Parent_upvr.HumanoidRootPart.Anchored = true
		any_LoadAnimation_result1_upvr_2.KeyframeReached:Connect(function(arg1_4) -- Line 568
			--[[ Upvalues[1]:
				[1]: RemoteEvents_upvr (copied, readonly)
			]]
			if arg1_4 == "Pulse" then
				TweenFOV(60)
				RemoteEvents_upvr.Beam:FireServer("Pulse")
				wait(0.3)
				TweenFOV(45)
			end
		end)
		any_LoadAnimation_result1_upvr_2.Stopped:Connect(function() -- Line 576
			--[[ Upvalues[6]:
				[1]: var48_upvw (copied, read and write)
				[2]: RemoteEvents_upvr (copied, readonly)
				[3]: any_LoadAnimation_result1_upvr_2 (copied, readonly)
				[4]: Value_upvr_5 (copied, readonly)
				[5]: Parent_upvr (copied, readonly)
				[6]: var51_upvw (copied, read and write)
			]]
			var48_upvw = true
			RemoteEvents_upvr.Cooldown:Fire("Pulse", any_LoadAnimation_result1_upvr_2.Length + Value_upvr_5, "Inactive")
			RemoteEvents_upvr.Cooldown:Fire("Pulse", any_LoadAnimation_result1_upvr_2.Length + Value_upvr_5, "Cooldown")
			Parent_upvr.HumanoidRootPart.Anchored = false
			wait(Value_upvr_5)
			var51_upvw = true
		end)
	end
end)
Stats_upvr.Charge.Changed:Connect(function() -- Line 613
	--[[ Upvalues[6]:
		[1]: Stats_upvr (readonly)
		[2]: any_LoadAnimation_result1_12_upvr (readonly)
		[3]: var43_upvw (read and write)
		[4]: RemoteEvents_upvr (readonly)
		[5]: var39_upvw (read and write)
		[6]: var42_upvw (read and write)
	]]
	if Stats_upvr.Charge.Value < 1 and Stats_upvr.RequiresCharge.Value == true then
		any_LoadAnimation_result1_12_upvr:Stop()
		if var43_upvw == false then
			RemoteEvents_upvr.Beam:FireServer("Uncharge")
		end
		RemoteEvents_upvr.Beam:FireServer("Charge0")
		RemoteEvents_upvr.Beam:FireServer("StopBeam")
		var39_upvw = false
		var42_upvw = false
		wait(5)
		var42_upvw = true
	elseif 1 >= Stats_upvr.Charge.Value or Stats_upvr.RequiresCharge.Value ~= true then
	end
	if 40 < Stats_upvr.Charge.Value then
		RemoteEvents_upvr.Cooldown:Fire("Pulse", 5.7, "Enable")
	elseif Stats_upvr.Charge.Value < 40 then
		RemoteEvents_upvr.Cooldown:Fire("Pulse", 5.7, "Disable")
	end
end)
UserInputService.InputBegan:Connect(function(arg1, arg2) -- Line 636
	--[[ Upvalues[11]:
		[1]: var38_upvw (read and write)
		[2]: Stats_upvr (readonly)
		[3]: var42_upvw (read and write)
		[4]: var49_upvw (read and write)
		[5]: var40_upvw (read and write)
		[6]: var41_upvw (read and write)
		[7]: any_LoadAnimation_result1_5_upvr (readonly)
		[8]: any_LoadAnimation_result1_12_upvr (readonly)
		[9]: RemoteEvents_upvr (readonly)
		[10]: var47_upvw (read and write)
		[11]: var39_upvw (read and write)
	]]
	if arg1.KeyCode == Enum.KeyCode.E and var38_upvw and not arg2 and 0 < Stats_upvr.Charge.Value and var42_upvw == true and Stats_upvr.Charged.Value == true and not var49_upvw then
		var40_upvw = false
		var38_upvw = false
		var41_upvw = true
		any_LoadAnimation_result1_5_upvr:AdjustWeight(1, 0.5)
		any_LoadAnimation_result1_12_upvr:AdjustWeight(0, 0.5)
		RemoteEvents_upvr.Cooldown:Fire("Beam", 5.7, "Active")
		if var47_upvw == false then
			if Stats_upvr.RequiresCharge.Value == true then
				RemoteEvents_upvr.Beam:FireServer("newCharge")
				any_LoadAnimation_result1_5_upvr:Play()
				any_LoadAnimation_result1_5_upvr:AdjustSpeed(1)
				print(any_LoadAnimation_result1_5_upvr.Length / 1 - 0.5)
				wait(any_LoadAnimation_result1_5_upvr.Length / 1 - 0.5)
				var47_upvw = true
				RemoteEvents_upvr.Beam:FireServer("newFinishCharge")
			else
				var47_upvw = true
			end
		end
		repeat
			wait()
		until var47_upvw == true
		script.Parent.UpdateMousePos.Disabled = false
		any_LoadAnimation_result1_5_upvr:AdjustWeight(0, 0.5)
		any_LoadAnimation_result1_12_upvr:AdjustWeight(1, 0.5)
		any_LoadAnimation_result1_12_upvr:Play(0.5)
		RemoteEvents_upvr.Beam:FireServer("Beam")
		var39_upvw = true
	else
		if arg1.KeyCode == Enum.KeyCode.E and var38_upvw and not arg2 and Stats_upvr.Charge.Value < 1 then
			CreateError("You must charge up before using Atomic Breath")
			return
		end
		if arg1.KeyCode == Enum.KeyCode.E and var38_upvw and not arg2 and 0 < Stats_upvr.Charge.Value and var42_upvw == false then
			CreateError("Wait before you can use Atomic Breath again")
		end
	end
end)
UserInputService.InputEnded:Connect(function(arg1, arg2) -- Line 675
	--[[ Upvalues[8]:
		[1]: var41_upvw (read and write)
		[2]: var40_upvw (read and write)
		[3]: var42_upvw (read and write)
		[4]: var38_upvw (read and write)
		[5]: var47_upvw (read and write)
		[6]: any_LoadAnimation_result1_5_upvr (readonly)
		[7]: RemoteEvents_upvr (readonly)
		[8]: any_LoadAnimation_result1_12_upvr (readonly)
	]]
	if arg1.KeyCode == Enum.KeyCode.E and var41_upvw == true then
		script.Parent.UpdateMousePos.Disabled = true
		var40_upvw = true
		var42_upvw = false
		if var41_upvw == true then
			var38_upvw = true
		end
		var47_upvw = false
		any_LoadAnimation_result1_5_upvr:Stop()
		var41_upvw = false
		LastCharge = tick() -- Setting global
		RemoteEvents_upvr.Cooldown:Fire("Beam", 5.7, "Inactive")
		wait(0.1)
		any_LoadAnimation_result1_12_upvr:Stop(0.5)
		RemoteEvents_upvr.Cooldown:Fire("Beam", 5.7, "Cooldown")
		var47_upvw = false
		RemoteEvents_upvr.Beam:FireServer("StopBeam")
		var42_upvw = false
		wait(0.7)
		var47_upvw = false
		any_LoadAnimation_result1_12_upvr:Stop(0.5)
		RemoteEvents_upvr.Beam:FireServer("StopBeam")
		wait(5)
		var42_upvw = true
	end
end)
local var100_upvw = false
local any_LoadAnimation_result1_8_upvr = Humanoid_upvr:LoadAnimation(AnimTracks.Death)
Stats_upvr.HP.Changed:Connect(function() -- Line 704
	--[[ Upvalues[18]:
		[1]: Stats_upvr (readonly)
		[2]: var100_upvw (read and write)
		[3]: var49_upvw (read and write)
		[4]: any_GetControls_result1_upvr (readonly)
		[5]: LocalPlayer_upvr (readonly)
		[6]: Parent_upvr (readonly)
		[7]: var38_upvw (read and write)
		[8]: var40_upvw (read and write)
		[9]: any_LoadAnimation_result1_upvr_4 (readonly)
		[10]: any_LoadAnimation_result1_upvr_5 (readonly)
		[11]: any_LoadAnimation_result1_2_upvr (readonly)
		[12]: any_LoadAnimation_result1_6_upvr (readonly)
		[13]: any_LoadAnimation_result1_11_upvr (readonly)
		[14]: any_LoadAnimation_result1_3_upvr (readonly)
		[15]: any_LoadAnimation_result1_10_upvr (readonly)
		[16]: any_LoadAnimation_result1_4_upvr (readonly)
		[17]: any_LoadAnimation_result1_7_upvr (readonly)
		[18]: any_LoadAnimation_result1_8_upvr (readonly)
	]]
	if Stats_upvr.HP.Value < 1 and var100_upvw == false then
		var49_upvw = true
		any_GetControls_result1_upvr:Disable()
		workspace:FindFirstChild("ChargeParts"..LocalPlayer_upvr.Name).Parent = Parent_upvr
		var100_upvw = true
		var38_upvw = false
		var40_upvw = false
		script.Parent.UpdateMousePos.Disabled = true
		any_LoadAnimation_result1_upvr_4:Stop()
		any_LoadAnimation_result1_upvr_5:Stop()
		any_LoadAnimation_result1_2_upvr:Stop()
		any_LoadAnimation_result1_6_upvr:Stop()
		any_LoadAnimation_result1_11_upvr:Stop()
		any_LoadAnimation_result1_3_upvr:Stop()
		any_LoadAnimation_result1_10_upvr:Stop()
		any_LoadAnimation_result1_4_upvr:Stop()
		any_LoadAnimation_result1_7_upvr:Stop()
		wait(0.5)
		any_LoadAnimation_result1_8_upvr:Play()
		wait(2)
		any_LoadAnimation_result1_8_upvr:AdjustSpeed(0)
	end
end)
Humanoid_upvr.Died:Connect(function() -- Line 728
	game.ReplicatedStorage.RE.ReturnMenu:FireServer("HumDeath")
end)
Stats_upvr.Rage.Changed:Connect(function() -- Line 733
	--[[ Upvalues[4]:
		[1]: Stats_upvr (readonly)
		[2]: RemoteEvents_upvr (readonly)
		[3]: any_LoadAnimation_result1_4_upvr (readonly)
		[4]: var43_upvw (read and write)
	]]
	if Stats_upvr.Rage.Value == 100 then
		RemoteEvents_upvr.Rage:FireServer("EnableRage")
		any_LoadAnimation_result1_4_upvr:Play()
		var43_upvw = true
	elseif Stats_upvr.Rage.Value == 0 then
		RemoteEvents_upvr.Rage:FireServer("DisableRage")
		var43_upvw = false
	end
end)
lastHP = Stats_upvr.HP.Value -- Setting global
Stats_upvr.HP.Changed:Connect(function() -- Line 746
	--[[ Upvalues[7]:
		[1]: Stats_upvr (readonly)
		[2]: any_LoadAnimation_result1_7_upvr (readonly)
		[3]: var46_upvw (read and write)
		[4]: var49_upvw (read and write)
		[5]: var41_upvw (read and write)
		[6]: var81_upvw (read and write)
		[7]: any_LoadAnimation_result1_upvr_4 (readonly)
	]]
	if Stats_upvr.HP.Value < lastHP and any_LoadAnimation_result1_7_upvr.IsPlaying == false and var46_upvw == true and not var49_upvw then
		if var41_upvw == false then
			any_LoadAnimation_result1_7_upvr:Play()
			var81_upvw = 0
			any_LoadAnimation_result1_upvr_4:Play()
			any_LoadAnimation_result1_upvr_4:AdjustSpeed(-1)
		end
		any_LoadAnimation_result1_7_upvr.Stopped:Connect(function() -- Line 754
			--[[ Upvalues[1]:
				[1]: any_LoadAnimation_result1_upvr_4 (copied, readonly)
			]]
			any_LoadAnimation_result1_upvr_4:Stop(0.5)
		end)
		lastHP = Stats_upvr.HP.Value -- Setting global
	end
end)
local CONTROL_upvr = LocalPlayer_upvr.PlayerGui.Interface.CONTROL
CONTROL_upvr.Roar.MouseButton1Click:Connect(function() -- Line 764
	--[[ Upvalues[1]:
		[1]: CONTROL_upvr (readonly)
	]]
	CONTROL_upvr.Parent.Roars.Visible = true
end)
CONTROL_upvr.Parent.Roars.Roar1.MouseButton1Click:Connect(function() -- Line 769
	--[[ Upvalues[8]:
		[1]: var37_upvw (read and write)
		[2]: var49_upvw (read and write)
		[3]: CONTROL_upvr (readonly)
		[4]: any_LoadAnimation_result1_10_upvr (readonly)
		[5]: RemoteEvents_upvr (readonly)
		[6]: var39_upvw (read and write)
		[7]: Value_upvr_6 (readonly)
		[8]: Value_upvr_2 (readonly)
	]]
	if var37_upvw and not var49_upvw then
		CONTROL_upvr.Parent.Roars.Visible = false
		TweenFOV(50)
		var37_upvw = false
		any_LoadAnimation_result1_10_upvr:Play()
		RemoteEvents_upvr.Cooldown:Fire("Roar", any_LoadAnimation_result1_10_upvr.Length + 5, "Cooldown")
		RemoteEvents_upvr.Roar:FireServer('1', var39_upvw, Value_upvr_6, Value_upvr_2, 5)
		any_LoadAnimation_result1_10_upvr.Stopped:Connect(function() -- Line 777
			--[[ Upvalues[1]:
				[1]: var37_upvw (copied, read and write)
			]]
			wait(5)
			var37_upvw = true
			TweenFOV(45)
		end)
	else
		CreateError("Wait before you can Roar again")
	end
end)
CONTROL_upvr.Parent.Roars.Roar2.MouseButton1Click:Connect(function() -- Line 787
	--[[ Upvalues[8]:
		[1]: var37_upvw (read and write)
		[2]: var49_upvw (read and write)
		[3]: CONTROL_upvr (readonly)
		[4]: any_LoadAnimation_result1_4_upvr (readonly)
		[5]: RemoteEvents_upvr (readonly)
		[6]: var39_upvw (read and write)
		[7]: Value_upvr_3 (readonly)
		[8]: Value_upvr (readonly)
	]]
	if var37_upvw and not var49_upvw then
		CONTROL_upvr.Parent.Roars.Visible = false
		TweenFOV(50)
		var37_upvw = false
		any_LoadAnimation_result1_4_upvr:Play()
		RemoteEvents_upvr.Cooldown:Fire("Roar", any_LoadAnimation_result1_4_upvr.Length + 5, "Cooldown")
		RemoteEvents_upvr.Roar:FireServer('2', var39_upvw, Value_upvr_3, Value_upvr, 5)
		any_LoadAnimation_result1_4_upvr.Stopped:Connect(function() -- Line 795
			--[[ Upvalues[1]:
				[1]: var37_upvw (copied, read and write)
			]]
			wait(5)
			TweenFOV(45)
			var37_upvw = true
		end)
	else
		CreateError("Wait before you can Roar again")
	end
end)
local var113_upvw = false
CONTROL_upvr.Beam.MouseButton1Click:Connect(function() -- Line 833
	--[[ Upvalues[12]:
		[1]: var113_upvw (read and write)
		[2]: var38_upvw (read and write)
		[3]: Stats_upvr (readonly)
		[4]: var42_upvw (read and write)
		[5]: var49_upvw (read and write)
		[6]: RemoteEvents_upvr (readonly)
		[7]: any_LoadAnimation_result1_12_upvr (readonly)
		[8]: var40_upvw (read and write)
		[9]: var41_upvw (read and write)
		[10]: var47_upvw (read and write)
		[11]: any_LoadAnimation_result1_5_upvr (readonly)
		[12]: var39_upvw (read and write)
	]]
	-- KONSTANTERROR: [0] 1. Error Block 1 start (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [0] 1. Error Block 1 end (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [25] 18. Error Block 39 start (CF ANALYSIS FAILED)
	var113_upvw = true
	RemoteEvents_upvr.Cooldown:Fire("Beam", any_LoadAnimation_result1_12_upvr.Length + 5, "Active")
	var40_upvw = false
	var38_upvw = false
	var41_upvw = true
	if var47_upvw == false then
		if Stats_upvr.RequiresCharge.Value == true then
			RemoteEvents_upvr.Beam:FireServer("newCharge")
			any_LoadAnimation_result1_5_upvr:Play()
			any_LoadAnimation_result1_5_upvr:AdjustSpeed(2)
			any_LoadAnimation_result1_5_upvr.Stopped:Connect(function() -- Line 846
				--[[ Upvalues[2]:
					[1]: var47_upvw (copied, read and write)
					[2]: RemoteEvents_upvr (copied, readonly)
				]]
				wait(0.7)
				var47_upvw = true
				RemoteEvents_upvr.Beam:FireServer("newFinishCharge")
			end)
		else
			var47_upvw = true
		end
	end
	repeat
		wait()
	until var47_upvw == true
	script.Parent.UpdateMousePos.Disabled = false
	any_LoadAnimation_result1_12_upvr:Play()
	RemoteEvents_upvr.Beam:FireServer("Beam")
	if Stats_upvr.RequiresCharge.Value == true and var39_upvw == false then
		var39_upvw = true
		RemoteEvents_upvr.Beam:FireServer("ChargeEffectsOnlyFast")
	end
	var39_upvw = true
	do
		return
	end
	-- KONSTANTERROR: [25] 18. Error Block 39 end (CF ANALYSIS FAILED)
	-- KONSTANTERROR: [132] 97. Error Block 31 start (CF ANALYSIS FAILED)
	if var113_upvw == true and var41_upvw == true then
		script.Parent.UpdateMousePos.Disabled = true
		var113_upvw = false
		RemoteEvents_upvr.Cooldown:Fire("Beam", any_LoadAnimation_result1_12_upvr.Length + 5, "Inactive")
		RemoteEvents_upvr.Cooldown:Fire("Beam", any_LoadAnimation_result1_12_upvr.Length + 5.8, "Cooldown")
		var40_upvw = true
		var42_upvw = false
		if var41_upvw == true then
			var38_upvw = true
		end
		var47_upvw = false
		any_LoadAnimation_result1_5_upvr:Stop()
		var41_upvw = false
		LastCharge = tick() -- Setting global
		wait(0.1)
		any_LoadAnimation_result1_12_upvr:Stop()
		var47_upvw = false
		RemoteEvents_upvr.Beam:FireServer("StopBeam")
		var42_upvw = false
		wait(0.7)
		var47_upvw = false
		any_LoadAnimation_result1_12_upvr:Stop()
		RemoteEvents_upvr.Beam:FireServer("StopBeam")
		wait(5)
		var42_upvw = true
	end
	-- KONSTANTERROR: [132] 97. Error Block 31 end (CF ANALYSIS FAILED)
end)
CONTROL_upvr.Pulse.MouseButton1Click:Connect(function() -- Line 896
	--[[ Upvalues[10]:
		[1]: Stats_upvr (readonly)
		[2]: any_LoadAnimation_result1_upvr_2 (readonly)
		[3]: var51_upvw (read and write)
		[4]: var49_upvw (read and write)
		[5]: var48_upvw (read and write)
		[6]: RemoteEvents_upvr (readonly)
		[7]: Value_upvr_5 (readonly)
		[8]: any_LoadAnimation_result1_upvr_4 (readonly)
		[9]: any_LoadAnimation_result1_upvr_5 (readonly)
		[10]: Parent_upvr (readonly)
	]]
	if Stats_upvr.Charged.Value == true and Stats_upvr.CanPulse.Value == true and 40 < Stats_upvr.Charge.Value and Stats_upvr.Swimming.Value == false and any_LoadAnimation_result1_upvr_2.IsPlaying == false and var51_upvw == true and not var49_upvw then
		var48_upvw = false
		var51_upvw = false
		RemoteEvents_upvr.Beam:FireServer("ChargePulse")
		RemoteEvents_upvr.Cooldown:Fire("Pulse", any_LoadAnimation_result1_upvr_2.Length + Value_upvr_5, "Active")
		any_LoadAnimation_result1_upvr_2:Play()
		any_LoadAnimation_result1_upvr_4:Stop()
		any_LoadAnimation_result1_upvr_5:Stop()
		Parent_upvr.HumanoidRootPart.Anchored = true
		any_LoadAnimation_result1_upvr_2.KeyframeReached:Connect(function(arg1) -- Line 906
			--[[ Upvalues[1]:
				[1]: RemoteEvents_upvr (copied, readonly)
			]]
			if arg1 == "Pulse" then
				TweenFOV(60)
				RemoteEvents_upvr.Beam:FireServer("Pulse")
				wait(0.3)
				TweenFOV(45)
			end
		end)
		any_LoadAnimation_result1_upvr_2.Stopped:Connect(function() -- Line 914
			--[[ Upvalues[6]:
				[1]: RemoteEvents_upvr (copied, readonly)
				[2]: any_LoadAnimation_result1_upvr_2 (copied, readonly)
				[3]: Value_upvr_5 (copied, readonly)
				[4]: Parent_upvr (copied, readonly)
				[5]: var48_upvw (copied, read and write)
				[6]: var51_upvw (copied, read and write)
			]]
			RemoteEvents_upvr.Cooldown:Fire("Pulse", any_LoadAnimation_result1_upvr_2.Length + Value_upvr_5, "Inactive")
			RemoteEvents_upvr.Cooldown:Fire("Pulse", any_LoadAnimation_result1_upvr_2.Length + Value_upvr_5, "Cooldown")
			Parent_upvr.HumanoidRootPart.Anchored = false
			var48_upvw = true
			wait(Value_upvr_5)
			var51_upvw = true
		end)
	end
end)
CONTROL_upvr.Attack.MouseButton1Click:Connect(function() -- Line 926
	--[[ Upvalues[10]:
		[1]: var38_upvw (read and write)
		[2]: any_LoadAnimation_result1_7_upvr (readonly)
		[3]: var12_upvw (read and write)
		[4]: var49_upvw (read and write)
		[5]: var80_upvw (read and write)
		[6]: any_LoadAnimation_result1_6_upvr (readonly)
		[7]: RemoteEvents_upvr (readonly)
		[8]: Value_upvr_4 (readonly)
		[9]: any_LoadAnimation_result1_11_upvr (readonly)
		[10]: any_LoadAnimation_result1_3_upvr (readonly)
	]]
	if var38_upvw and any_LoadAnimation_result1_7_upvr.IsPlaying == false and var12_upvw == true and not var49_upvw then
		TweenFOV(50)
		var38_upvw = false
		if var80_upvw == "Melee1" then
			var80_upvw = "Melee2"
			any_LoadAnimation_result1_6_upvr:Play()
			RemoteEvents_upvr.Cooldown:Fire("Attack", any_LoadAnimation_result1_6_upvr.Length + Value_upvr_4, "Cooldown")
			RemoteEvents_upvr.Attack:FireServer("Melee1")
			any_LoadAnimation_result1_6_upvr.Stopped:Connect(function() -- Line 935
				--[[ Upvalues[1]:
					[1]: var38_upvw (copied, read and write)
				]]
				var38_upvw = true
			end)
		elseif var80_upvw == "Melee2" then
			var80_upvw = "Melee3"
			any_LoadAnimation_result1_11_upvr:Play()
			RemoteEvents_upvr.Cooldown:Fire("Attack", any_LoadAnimation_result1_6_upvr.Length + Value_upvr_4, "Cooldown")
			RemoteEvents_upvr.Attack:FireServer("Melee2")
			any_LoadAnimation_result1_11_upvr.Stopped:Connect(function() -- Line 943
				--[[ Upvalues[1]:
					[1]: var38_upvw (copied, read and write)
				]]
				var38_upvw = true
			end)
		elseif var80_upvw == "Melee3" then
			var80_upvw = "Melee1"
			any_LoadAnimation_result1_3_upvr:Play()
			RemoteEvents_upvr.Cooldown:Fire("Attack", any_LoadAnimation_result1_6_upvr.Length + Value_upvr_4, "Cooldown")
			RemoteEvents_upvr.Attack:FireServer("Melee3")
			any_LoadAnimation_result1_3_upvr.Stopped:Connect(function() -- Line 951
				--[[ Upvalues[1]:
					[1]: var38_upvw (copied, read and write)
				]]
				var38_upvw = true
			end)
		end
		wait(0.3)
		TweenFOV(45)
	end
end)
CONTROL_upvr.Parent.Sprint.MouseButton1Click:Connect(function() -- Line 961
	--[[ Upvalues[2]:
		[1]: var44_upvw (read and write)
		[2]: Humanoid_upvr (readonly)
	]]
	if var44_upvw == false then
		Humanoid_upvr.WalkSpeed = SS
		var44_upvw = true
	else
		Humanoid_upvr.WalkSpeed = WS
		var44_upvw = false
	end
end)