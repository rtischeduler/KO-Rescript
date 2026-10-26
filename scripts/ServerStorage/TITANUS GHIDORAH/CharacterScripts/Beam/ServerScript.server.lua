local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BeamSystem = require(ReplicatedStorage:FindFirstChild("BeamSystem"))

local beamRemote = script.Parent

local beamSound = script.Parent.Parent.Sounds.Beam

local animationsFolder = script.Parent.Parent.Parent:FindFirstChild("Animations")

local debounce = {}

beamRemote.OnServerEvent:Connect(function(player, targetPos)

	if debounce[player] then return end

	debounce[player] = true

	local character = player.Character

	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")

	if not hrp then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if animationsFolder then

		local beamAnim = animationsFolder:FindFirstChild("Attack2")

		if beamAnim and humanoid then

			local animator = humanoid:FindFirstChild("Animator")

			if animator then

				local track = animator:LoadAnimation(beamAnim)

				track.Priority = Enum.AnimationPriority.Action

				track:Play(0.1, 100)

			end

		end

	end

	local soundClone = beamSound:Clone()

	soundClone.Parent = hrp

	soundClone.Looped = false


	soundClone:Play()

	BeamSystem.ActivateBeam({
		character = character,
		player = player,
		initialTargetPosition = targetPos,
		duration = 8,
	})

	soundClone:Destroy()

	debounce[player] = nil

end)
