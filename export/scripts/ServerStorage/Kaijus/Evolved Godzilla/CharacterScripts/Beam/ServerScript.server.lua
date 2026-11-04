local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BeamSystem = require(ReplicatedStorage:FindFirstChild("BeamSystem"))

local beamRemote = script.Parent
local beamSound = script.Parent.Parent.Sounds.Beam
local model = script.Parent.Parent.Parent
local spikesFolder = model:FindFirstChild("Spikes")
local animationsFolder = model:FindFirstChild("Animations")

-- The BeamParticle part lives at the model root (some kaiju keep it under a HitParts folder)
local beamParticle = model:FindFirstChild("BeamParticle")
if not beamParticle then
	local hitParts = model:FindFirstChild("HitParts")
	beamParticle = hitParts and hitParts:FindFirstChild("BeamParticle") or nil
end

local debounce = {}

-- Helper function to get sorted spikes
local function getSortedSpikes()
	if not spikesFolder then return {} end

	local spikes = {}
	for _, child in ipairs(spikesFolder:GetChildren()) do
		if child:IsA("BasePart") then
			-- Extract number from name (e.g., "Spikes1" -> 1)
			local number = tonumber(string.match(child.Name, "%d+"))
			if number then
				table.insert(spikes, {part = child, number = number})
			end
		end
	end

	-- Sort by number
	table.sort(spikes, function(a, b)
		return a.number < b.number
	end)

	return spikes
end

-- Store original spike properties
local originalProperties = {}

local function setSpikeGlow(spike, glowEnabled)
	if glowEnabled then
		-- Store original properties if not already stored
		if not originalProperties[spike] then
			originalProperties[spike] = {
				Material = spike.Material,
				UsePartColor = spike.UsePartColor
			}
		end
		-- Set to neon glow using existing part color
		spike.Material = Enum.Material.Neon
		spike.UsePartColor = true
	else
		-- Restore original properties
		if originalProperties[spike] then
			spike.Material = originalProperties[spike].Material
			spike.UsePartColor = originalProperties[spike].UsePartColor
		end
	end
end

beamRemote.OnServerEvent:Connect(function(player, targetPos)
	-- Debounce check
	if debounce[player] then return end
	debounce[player] = true

	local character = player.Character
	if not character then
		debounce[player] = nil
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		debounce[player] = nil
		return
	end

	-- Play Beam animation
	

	-- Get sorted spikes
	local spikes = getSortedSpikes()

	-- Clone and play the Beam sound on HumanoidRootPart
	local soundClone = beamSound:Clone()
	soundClone.Parent = hrp
	soundClone:Play()
	
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
	
	--wait(0.1)

	-- Charging phase: glow spikes from 1 to N
	for i, spikeData in ipairs(spikes) do
		setSpikeGlow(spikeData.part, true)
		wait(0.25)
	end

	-- Fire the aimable beam (BeamSystem handles aiming, hitbox, and DPS from Stats.DMG2)
	BeamSystem.ActivateBeam({
		character = character,
		player = player,
		initialTargetPosition = targetPos,
		duration = 4.7,
	})

	-- Cooldown phase: turn off spikes from N to 1
	for i = #spikes, 1, -1 do
		setSpikeGlow(spikes[i].part, false)
		task.wait(0.2)
	end

	-- Delete the sound
	soundClone:Destroy()

	-- Allow beam to be used again
	debounce[player] = nil
end)