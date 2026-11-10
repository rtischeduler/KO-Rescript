local attackRemote = script.Parent
local hitSound = script.Parent.Parent.Sounds.HitSound
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DamageMultiplierPerLevel = ReplicatedStorage:WaitForChild("DamageMultiplierPerLevel")

local debounce = {}

local function getHumanoidAndPlayer(part)
	local character = part.Parent
	if not character then return nil, nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local player = Players:GetPlayerFromCharacter(character)
	return humanoid, player
end

attackRemote.OnServerEvent:Connect(function(player)
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
	
	-- Get damage from Stats.DMG3
	local damage = 10
	local stats = character:FindFirstChild("Stats")
	if stats then
		local dmgValue = stats:FindFirstChild("DMG3")
		if dmgValue then
			damage = dmgValue.Value
		end
	end
	
	-- Clone and play the HitSound on HumanoidRootPart
	local soundClone = hitSound:Clone()
	soundClone.Parent = hrp
	soundClone:Play()
	soundClone.Ended:Connect(function()
		soundClone:Destroy()
	end)
	
	-- Play animation
	local animationsFolder = script.Parent.Parent.Parent:FindFirstChild("Animations")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if animationsFolder then
		local beamAnim = animationsFolder:FindFirstChild("Attack3")
		if beamAnim and humanoid then
			local animator = humanoid:FindFirstChild("Animator")
			if animator then
				local track = animator:LoadAnimation(beamAnim)
				track:Play()
			end
		end
	end
	
	-- Create hitbox in front of player
	local hitbox = Instance.new("Part")
	hitbox.Name = "AttackHitbox"
	hitbox.Size = Vector3.new(15, 15, 15)
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CanTouch = true
	hitbox.Transparency = 1
	hitbox.Color = Color3.fromRGB(255, 0, 0)
	hitbox.Material = Enum.Material.Neon
	hitbox.Parent = character
	hitbox.CFrame = hrp.CFrame * CFrame.new(0, 0, -10)
	
	-- Track players already hit
	local hitPlayers = {}
	local startTime = tick()
	local duration = 0.5
	
	-- Use both Touched event and overlap detection for reliability
	local connection = hitbox.Touched:Connect(function(hit)
		local hitHumanoid, hitPlayer = getHumanoidAndPlayer(hit)
		if hitHumanoid and hitPlayer and hitPlayer ~= player and not hitPlayers[hitPlayer] then
			hitPlayers[hitPlayer] = true
			local _c = hitHumanoid:FindFirstChild("creator")
			if not _c then _c = Instance.new("ObjectValue") _c.Name = "creator" _c.Parent = hitHumanoid end
			_c.Value = player
			hitHumanoid:TakeDamage(damage)
		---- Add 25 GCells to attacker
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
				if gcells and gcells:IsA("IntValue") then
					gcells.Value = gcells.Value + 25
				end
			end
		end
	end)
	
	-- Also check for overlapping parts periodically
	while tick() - startTime < duration do
		local overlapParams = OverlapParams.new()
		overlapParams.FilterDescendantsInstances = {character}
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		
		local overlappingParts = workspace:GetPartsInPart(hitbox, overlapParams)
		for _, part in ipairs(overlappingParts) do
			local hitHumanoid, hitPlayer = getHumanoidAndPlayer(part)
			if hitHumanoid and hitPlayer and hitPlayer ~= player and not hitPlayers[hitPlayer] then
				hitPlayers[hitPlayer] = true
				local _c = hitHumanoid:FindFirstChild("creator")
				if not _c then _c = Instance.new("ObjectValue") _c.Name = "creator" _c.Parent = hitHumanoid end
				_c.Value = player
				hitHumanoid:TakeDamage(damage)
			---- Add 25 GCells to attacker
				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats then
					local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
					if gcells and gcells:IsA("IntValue") then
						gcells.Value = gcells.Value + 25
					end
				end
			end
		end
		task.wait(0.05)
	end
	
	-- Cleanup
	connection:Disconnect()
	hitbox:Destroy()
	
	-- Allow attack to be used again
	debounce[player] = nil
end)