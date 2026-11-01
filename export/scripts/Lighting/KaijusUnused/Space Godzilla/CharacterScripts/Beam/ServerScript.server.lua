local beamRemote = script.Parent

local beamSound = script.Parent.Parent.Sounds.Beam

local animationsFolder = script.Parent.Parent.Parent:FindFirstChild("Animations")

local debounce = {}

beamRemote.OnServerEvent:Connect(function(player)

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

				track:Play()

			end

		end

	end

	local soundClone = beamSound:Clone()

	soundClone.Parent = hrp

	soundClone:Play()
	wait(0.6)

	script.Parent.Parent.Parent.HitParts.Beam.Transparency = 0
    script.Parent.Parent.Parent.HitParts.Beam.CanTouch = true

	wait(6)

	script.Parent.Parent.Parent.HitParts.Beam.Transparency = 1
	script.Parent.Parent.Parent.HitParts.Beam.CanTouch = false

	soundClone:Destroy()

	debounce[player] = nil

end)
