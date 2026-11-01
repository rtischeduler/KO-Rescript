local attackRemote = script.Parent
local hitSound = script.Parent.Parent.Sounds.HitSound
local animationsFolder = script.Parent.Parent.Parent:FindFirstChild("Animations")

local debounce = {}

attackRemote.OnServerEvent:Connect(function(player)

	if debounce[player] then return end
	debounce[player] = true

	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local damage = 10
	local stats = character:FindFirstChild("Stats")
	if stats then
		local dmgValue = stats:FindFirstChild("DMG1")
		if dmgValue then
			damage = dmgValue.Value
		end
	end

	local soundClone = hitSound:Clone()
	soundClone.Parent = hrp
	soundClone:Play()
	soundClone.Ended:Connect(function()
		soundClone:Destroy()
	end)

	local hitbox = Instance.new("Part")
	hitbox.Name = "AttackHitbox"
	hitbox.Size = Vector3.new(8, 6, 8)
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.Transparency = 1
	hitbox.Color = Color3.fromRGB(255, 0, 0)
	hitbox.Material = Enum.Material.Neon
	hitbox.Parent = script.Parent.Parent.Parent

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if animationsFolder then
		local beamAnim = animationsFolder:FindFirstChild("Attack1")
		if beamAnim and humanoid then
			local animator = humanoid:FindFirstChild("Animator")
			if animator then
				local track = animator:LoadAnimation(beamAnim)
				track:Play()
			end
		end
	end

	hitbox.CFrame = hrp.CFrame * CFrame.new(0, 0, -10)

	local hitPlayers = {}

	hitbox.Touched:Connect(function(hit)
		local hitCharacter = hit.Parent
		local hitHumanoid = hitCharacter and hitCharacter:FindFirstChildOfClass("Humanoid")
		local hitPlayer = game.Players:GetPlayerFromCharacter(hitCharacter)

		if hitHumanoid and hitPlayer and hitPlayer ~= player and not hitPlayers[hitPlayer] then
			hitPlayers[hitPlayer] = true
			local _c = hitHumanoid:FindFirstChild("creator")
			if not _c then _c = Instance.new("ObjectValue") _c.Name = "creator" _c.Parent = hitHumanoid end
			_c.Value = player
			hitHumanoid:TakeDamage(damage)

			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
				if gcells and gcells:IsA("IntValue") then
					if _G.GCellGuardAllow then _G.GCellGuardAllow(gcells, 50) end
					gcells.Value = gcells.Value + 50
				end
			end
		end
	end)

	task.wait(0.5)
	hitbox:Destroy()

	debounce[player] = nil
end)
