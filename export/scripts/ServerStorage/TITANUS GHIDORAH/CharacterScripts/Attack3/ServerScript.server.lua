local attackRemote = script.Parent

local hitSound = script.Parent.Parent.Sounds.HitSound

local animationsFolder = script.Parent.Parent.Parent:FindFirstChild("Animations")

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local debounce = {}

local function getHumanoidAndPlayer(part)

	local character = part.Parent

	if not character then return nil, nil end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	local player = Players:GetPlayerFromCharacter(character)

	return humanoid, player

end

attackRemote.OnServerEvent:Connect(function(player)

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

	local damage = 10

	local stats = character:FindFirstChild("Stats")

	if stats then

		local dmgValue = stats:FindFirstChild("DMG3")

		if dmgValue then

			damage = dmgValue.Value

		end

	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if animationsFolder then

		local beamAnim = animationsFolder:FindFirstChild("Attack3")

		if beamAnim and humanoid then

			local animator = humanoid:FindFirstChild("Animator")

			if animator then

				local track = animator:LoadAnimation(beamAnim)

				track.Priority = Enum.AnimationPriority.Action4

				track:Play(0.1, 100)

			end

		end

	end

	local hitbox = Instance.new("Part")

	hitbox.Name = "AttackHitbox"
	hitbox:SetAttribute("MeleeHit", true)

	hitbox.Size = Vector3.new(50, 50, 50)

	hitbox.Anchored = true

	hitbox.CanCollide = false

	hitbox.CanTouch = true

	hitbox.Transparency = 1

	hitbox.Color = Color3.fromRGB(255, 0, 0)

	hitbox.Material = Enum.Material.Neon

	hitbox.Parent = character

	hitbox.CFrame = hrp.CFrame * CFrame.new(0, 0, -10)

	local hitPlayers = {}

	local hitPartConnections = {}
	local hitPartsEnabled = {}
	for _, folder in ipairs({character:FindFirstChild("HitParts"), character:FindFirstChild("HitParts2")}) do
		if folder then
			for _, part in ipairs(folder:GetDescendants()) do
				if part:IsA("BasePart") and not part:FindFirstChildWhichIsA("Script") then
					part.CanTouch = true
					table.insert(hitPartsEnabled, part)
					local conn = part.Touched:Connect(function(hit)
						local hitHumanoid, hitPlayer = getHumanoidAndPlayer(hit)
						if hitHumanoid and hitPlayer and hitPlayer ~= player and not hitPlayers[hitPlayer] then
							hitPlayers[hitPlayer] = true
							local _c = hitHumanoid:FindFirstChild("creator")
							if not _c then _c = Instance.new("ObjectValue") _c.Name = "creator" _c.Parent = hitHumanoid end
							_c.Value = player
							hitHumanoid:TakeDamage(damage)
							local hitSoundClone = hitSound:Clone()
							hitSoundClone.Parent = hrp
							hitSoundClone.Looped = false

							hitSoundClone:Play()
							hitSoundClone.Ended:Connect(function() hitSoundClone:Destroy() end)
							local leaderstats = player:FindFirstChild("leaderstats")
							if leaderstats then
								local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
								if gcells and gcells:IsA("IntValue") then
									if _G.GCellGuardAllow then _G.GCellGuardAllow(gcells, 25) end
									gcells.Value = gcells.Value + 25
								end
							end
						end
					end)
					table.insert(hitPartConnections, conn)
				end
			end
		end
	end

	local startTime = tick()

	local duration = 0.5

	local connection = hitbox.Touched:Connect(function(hit)

		local hitHumanoid, hitPlayer = getHumanoidAndPlayer(hit)

		if hitHumanoid and hitPlayer and hitPlayer ~= player and not hitPlayers[hitPlayer] then

			hitPlayers[hitPlayer] = true

			local _c = hitHumanoid:FindFirstChild("creator")

			if not _c then _c = Instance.new("ObjectValue") _c.Name = "creator" _c.Parent = hitHumanoid end

			_c.Value = player

			hitHumanoid:TakeDamage(damage)

			local hitSoundClone = hitSound:Clone()

			hitSoundClone.Parent = hrp

			hitSoundClone.Looped = false


			hitSoundClone:Play()

			hitSoundClone.Ended:Connect(function()

				hitSoundClone:Destroy()

			end)

			local leaderstats = player:FindFirstChild("leaderstats")

			if leaderstats then

				local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")

				if gcells and gcells:IsA("IntValue") then

					if _G.GCellGuardAllow then _G.GCellGuardAllow(gcells, 25) end
					gcells.Value = gcells.Value + 25

				end

			end

		end

	end)

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

				local hitSoundClone = hitSound:Clone()

				hitSoundClone.Parent = hrp

				hitSoundClone.Looped = false


				hitSoundClone:Play()

				hitSoundClone.Ended:Connect(function()

					hitSoundClone:Destroy()

				end)

				local leaderstats = player:FindFirstChild("leaderstats")

				if leaderstats then

					local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")

					if gcells and gcells:IsA("IntValue") then

						if _G.GCellGuardAllow then _G.GCellGuardAllow(gcells, 25) end
						gcells.Value = gcells.Value + 25

					end

				end

			end

		end

		task.wait(0.05)

	end

	connection:Disconnect()

	hitbox:Destroy()

	for _, conn in ipairs(hitPartConnections) do
		conn:Disconnect()
	end
	for _, part in ipairs(hitPartsEnabled) do
		if part.Parent then
			part.CanTouch = false
		end
	end

	debounce[player] = nil

end)
