local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BeamSystem = require(ReplicatedStorage:FindFirstChild("BeamSystem"))

local beamRemote = script.Parent
local attackSound = script.Parent.Parent.Sounds.Attack4
local model = script.Parent.Parent.Parent
local spikesFolder = model:FindFirstChild("Spikes")
local animationsFolder = model:FindFirstChild("Animations")

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

	-- Play Attack4 animation
	

	-- Get sorted spikes
	local spikes = getSortedSpikes()

	-- Clone and play the Attack4 sound on HumanoidRootPart
	local soundClone = attackSound:Clone()
	soundClone.Parent = hrp
	soundClone:Play()
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if animationsFolder then
		local beamAnim = animationsFolder:FindFirstChild("Attack4")
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
	

	-- Supercharged sparkles: wrap the player in Godzilla's glow color during the beam
	local glowColor = beamRemote:GetAttribute("GlowColor")
	if typeof(glowColor) ~= "Color3" then
		glowColor = Color3.fromRGB(247, 130, 255)
	end
	local sparkleParts = {}
	for _, partName in ipairs({"HumanoidRootPart", "Torso", "Head", "Chest"}) do
		local part = character:FindFirstChild(partName)
		if part and part:IsA("BasePart") then
			local sparkles = Instance.new("Sparkles")
			sparkles.Name = "SuperChargeSparkles"
			sparkles.SparkleColor = glowColor
			sparkles.Parent = part
			table.insert(sparkleParts, sparkles)
		end
	end

	-- Extra dense sparkles on the root part for that supercharged feel
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		local rootSparkles = Instance.new("Sparkles")
		rootSparkles.Name = "SuperChargeRootSparkles"
		rootSparkles.SparkleColor = glowColor
		rootSparkles.Parent = rootPart
		table.insert(sparkleParts, rootSparkles)
	end

	-- Blazing atomic eyes: fire effect on the Eyes in Godzilla's glow color
	local eyes = character:FindFirstChild("Eyes")
	if eyes and eyes:IsA("BasePart") then
		local eyeFire = Instance.new("Fire")
		eyeFire.Name = "SuperChargeEyeFire"
		eyeFire.Color = glowColor
		eyeFire.SecondaryColor = Color3.new(
			math.min(glowColor.R * 0.6 + 0.4, 1),
			math.min(glowColor.G * 0.6 + 0.4, 1),
			math.min(glowColor.B * 0.6 + 0.4, 1)
		)
		eyeFire.Size = 1.5
		eyeFire.Heat = 12
		eyeFire.Parent = eyes
		table.insert(sparkleParts, eyeFire)
	end

	-- Fire the aimable beam (BeamSystem handles aiming, hitbox, and DPS from Stats.DMG4)
	BeamSystem.ActivateBeam({
		character = character,
		player = player,
		initialTargetPosition = targetPos,
		duration = 4.7,
		damageStat = "DMG4",
	})

	-- Cooldown phase: turn off spikes from N to 1, 0.2 seconds each
	for i = #spikes, 1, -1 do
		setSpikeGlow(spikes[i].part, false)
		task.wait(0.2)
	end

	-- Remove the supercharged sparkles and eye fire
	for _, effect in ipairs(sparkleParts) do
		if effect.Parent then
			effect:Destroy()
		end
	end

	-- Delete the sound
	soundClone:Destroy()

	-- Allow beam to be used again
	debounce[player] = nil
end)