local attackRemote = script.Parent
local hitSound = script.Parent.Parent.Sounds.Pulse
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DamageMultiplierPerLevel = ReplicatedStorage:FindFirstChild("DamageMultiplierPerLevel")

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

	local damageMultiplier = 1
	local levelValue = character:FindFirstChild("Level")
	if levelValue and DamageMultiplierPerLevel then
		local level = levelValue.Value
		damageMultiplier = DamageMultiplierPerLevel.Value ^ (level - 1)
	end
	damage = damage * damageMultiplier

	local soundClone = hitSound:Clone()
	soundClone.Parent = hrp
	soundClone:Play()
	soundClone.Ended:Connect(function()
		soundClone:Destroy()
	end)

	local animationsFolder = script.Parent.Parent.Parent:FindFirstChild("Animations")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if animationsFolder then
		local blastAnim = animationsFolder:FindFirstChild("Attack3")
		if blastAnim and humanoid then
			local animator = humanoid:FindFirstChild("Animator")
			if animator then
				local track = animator:LoadAnimation(blastAnim)
				track:Play()
			end
		end
	end
wait(3.5)

	local hitParts = character:FindFirstChild("HitParts")
	local heiseiBlast = hitParts and hitParts:FindFirstChild("HeiseiBlast")

	if heiseiBlast then

		heiseiBlast.Transparency = 0
		heiseiBlast.Size = Vector3.new(5, 5, 5)
		heiseiBlast.CFrame = hrp.CFrame
		heiseiBlast.CanTouch = true

		heiseiBlast:SetAttribute("BlastActive", true)

		local playerNameValue = heiseiBlast:FindFirstChild("PlayerName")
		if playerNameValue then
			playerNameValue.Value = player.Name
		end
	end

	local startTime = tick()
	local duration = 1.5
	local tickInterval = 0.3
	local numTicks = duration / tickInterval
	local damagePerTick = damage / numTicks
	local gcellsPerTick = 50 / numTicks

	local pulseConnection
	pulseConnection = RunService.Heartbeat:Connect(function()
		if heiseiBlast and heiseiBlast.Parent and hrp and hrp.Parent then
			local progress = math.clamp((tick() - startTime) / duration, 0, 1)

			local startSize = 5
			local endSize = 100
			local currentSize = startSize + (endSize - startSize) * progress
			heiseiBlast.Size = Vector3.new(currentSize, currentSize, currentSize)

			heiseiBlast.Transparency = progress

			heiseiBlast.CFrame = hrp.CFrame
		end
	end)

	while tick() - startTime < duration do
		local hitThisTick = {}

		if heiseiBlast and heiseiBlast.Parent and hrp and hrp.Parent then

			local overlapParams = OverlapParams.new()
			overlapParams.FilterDescendantsInstances = {character}
			overlapParams.FilterType = Enum.RaycastFilterType.Exclude

			local overlappingParts = workspace:GetPartsInPart(heiseiBlast, overlapParams)
			for _, part in ipairs(overlappingParts) do
				local hitHumanoid, hitPlayer = getHumanoidAndPlayer(part)
				if hitHumanoid and hitPlayer and hitPlayer ~= player and not hitThisTick[hitPlayer] then
					hitThisTick[hitPlayer] = true
					local _c = hitHumanoid:FindFirstChild("creator")
					if not _c then _c = Instance.new("ObjectValue") _c.Name = "creator" _c.Parent = hitHumanoid end
					_c.Value = player
					hitHumanoid:TakeDamage(damagePerTick)

					local leaderstats = player:FindFirstChild("leaderstats")
					if leaderstats then
						local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
						if gcells and gcells:IsA("IntValue") then
							if _G.GCellGuardAllow then _G.GCellGuardAllow(gcells, gcellsPerTick) end
							gcells.Value = gcells.Value + gcellsPerTick
						end
					end
				end
			end
		end

		task.wait(tickInterval)
	end

	if pulseConnection then
		pulseConnection:Disconnect()
	end

	if heiseiBlast and heiseiBlast.Parent then
		heiseiBlast.Transparency = 1
		heiseiBlast.Size = Vector3.new(100, 100, 100)
		heiseiBlast.CanTouch = false
		heiseiBlast:SetAttribute("BlastActive", false)
	end

	debounce[player] = nil
end)
