local beamRemote = script.Parent
local beamSound = script.Parent.Parent.Sounds.Beam
local animationsFolder = script.Parent.Parent.Parent:FindFirstChild("Animations")

local TweenService = game:GetService("TweenService")

local debounce = {}

local function getSpikes(character)
	local spikesFolder = character:FindFirstChild("Spikes")
	if not spikesFolder then return {} end

	local spikes = {}
	for _, child in ipairs(spikesFolder:GetChildren()) do
		if child.Name == "Spike" and child:IsA("UnionOperation") then
			table.insert(spikes, child)
		end
	end
	return spikes
end

local function activateSpikes(character)
	local spikes = getSpikes(character)
	local originalColors = {}
	local originalMaterials = {}
	local originalUsePartColor = {}

	for i, spike in ipairs(spikes) do
		originalColors[i] = spike.Color
		originalMaterials[i] = spike.Material
		originalUsePartColor[i] = spike.UsePartColor

		spike.UsePartColor = true
		spike.Material = Enum.Material.Neon

		local electric = spike:FindFirstChild("Electric")
		local spiral = spike:FindFirstChild("Spiral")
		if electric then
			electric.Enabled = true
		end
		if spiral then
			spiral.Enabled = false
		end
	end

	local blueColor = Color3.fromRGB(0, 100, 255)
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	for i, spike in ipairs(spikes) do
		local tween = TweenService:Create(spike, tweenInfo, {Color = blueColor})
		tween:Play()
	end

	return spikes, originalColors, originalMaterials, originalUsePartColor
end

local function deactivateSpikes(spikes, originalColors, originalMaterials, originalUsePartColor)

	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	for i, spike in ipairs(spikes) do
		local tween = TweenService:Create(spike, tweenInfo, {Color = originalColors[i]})
		tween:Play()

		local electric = spike:FindFirstChild("Electric")
		if electric then
			electric.Enabled = false
		end
	end

	task.wait(3)
	for i, spike in ipairs(spikes) do
		spike.Material = Enum.Material.Slate
		spike.UsePartColor = false
	end
end

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

	local spikes, originalColors, originalMaterials, originalUsePartColor = activateSpikes(character)

	task.wait(1.5)
	script.Parent.Parent.Parent.HitParts.Beam.Transparency = 0
	script.Parent.Parent.Parent.HitParts.Beam.FireParticle.Enabled = true

	task.wait(7)
	deactivateSpikes(spikes, originalColors, originalMaterials, originalUsePartColor)

	task.wait(2.5)
	script.Parent.Parent.Parent.HitParts.Beam.Transparency = 1
	script.Parent.Parent.Parent.HitParts.Beam.FireParticle.Enabled = false

	soundClone:Destroy()

	debounce[player] = false
end)
