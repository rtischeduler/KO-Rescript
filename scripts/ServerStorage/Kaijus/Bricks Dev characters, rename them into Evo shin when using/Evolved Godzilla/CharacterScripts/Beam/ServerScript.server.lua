local beamRemote = script.Parent
local beamSound = script.Parent.Parent.Sounds.Beam
local spikesFolder = script.Parent.Parent.Parent:FindFirstChild("Spikes")
local animationsFolder = script.Parent.Parent.Parent:FindFirstChild("Animations")

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

beamRemote.OnServerEvent:Connect(function(player)
	-- Debounce check
	if debounce[player] then return end
	debounce[player] = true

	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

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
				track:Play()
			end
		end
	end
	
	--wait(0.1)

	-- Charging phase: glow spikes from 1 to N, 0.1 seconds each
	for i, spikeData in ipairs(spikes) do
		setSpikeGlow(spikeData.part, true)
		wait(0.25)
	end
	

	script.Parent.Parent.Parent.HitParts.BeamParticle.FireParticle1.Enabled = true
	script.Parent.Parent.Parent.HitParts.BeamParticle.FireParticle2.Enabled = true
	script.Parent.Parent.Parent.HitParts.BeamParticle.FireParticle3.Enabled = true
	-- Wait for sound to finish
	--soundClone.Ended:Wait()
	wait(4.7)
	script.Parent.Parent.Parent.HitParts.BeamParticle.FireParticle1.Enabled = false
	script.Parent.Parent.Parent.HitParts.BeamParticle.FireParticle2.Enabled = false
	script.Parent.Parent.Parent.HitParts.BeamParticle.FireParticle3.Enabled = false

	-- Cooldown phase: turn off spikes from N to 1, 0.2 seconds each
	for i = #spikes, 1, -1 do
		setSpikeGlow(spikes[i].part, false)
		task.wait(0.2)
	end

	-- Delete the sound
	soundClone:Destroy()

	-- Allow beam to be used again
	debounce[player] = nil
end)