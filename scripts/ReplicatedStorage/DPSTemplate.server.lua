local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local attackerName = script:GetAttribute("Attacker")
local BeamSystem = nil
task.spawn(function()
	local module = ReplicatedStorage:WaitForChild("BeamSystem", 10)
	if module then
		local ok, result = pcall(require, module)
		if ok then BeamSystem = result end
	end
end)
local Knockback = nil
task.spawn(function()
	local module = ReplicatedStorage:WaitForChild("Knockback", 10)
	if module then
		local ok, result = pcall(require, module)
		if ok then Knockback = result end
	end
end)
local hitDebounce = {}


local charRadiusCache = {}
local function getCharRadius(char)
	local cached = charRadiusCache[char]
	if cached then return cached end
	local ok, size = pcall(function()
		local _, s = char:GetBoundingBox()
		return s
	end)
	local radius = (ok and size) and math.max(size.X, size.Y, size.Z) / 2 or 30
	charRadiusCache[char] = radius
	return radius
end

local function characterTouchesHitbox(char, hitbox)
	local cf = hitbox.CFrame
	local half = hitbox.Size / 2
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			local lp = cf:PointToObjectSpace(part.Position)
			local r = part.Size.Magnitude / 2
			if math.abs(lp.X) <= half.X + r and math.abs(lp.Y) <= half.Y + r and math.abs(lp.Z) <= half.Z + r then
				return true
			end
		end
	end
	return false
end

local function awardGCells(attacker, at)
	local leaderstats = attacker:FindFirstChild("leaderstats")
	if leaderstats then
		local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
		if gcells and gcells:IsA("IntValue") then
			local amount = math.floor(2 * (_G.RewardScale and _G.RewardScale(attacker, at, false) or 1) + math.random())
			if amount <= 0 then return end
			if _G.GCellGuardAllow then _G.GCellGuardAllow(gcells, amount) end
			gcells.Value = gcells.Value + amount
			if _G.ShowIndicator then _G.ShowIndicator(attacker, 0, amount, 0, at) end
		end
	end
end

local DAMAGE_INTERVAL = 0.1

local beamDuration = script:GetAttribute("BeamDuration") or 6
local beamDamage = script:GetAttribute("BeamDamage") or 0

local DAMAGE_AMOUNT
if beamDamage > 0 then
	local numTicks = beamDuration / DAMAGE_INTERVAL
	DAMAGE_AMOUNT = beamDamage / numTicks
else
	DAMAGE_AMOUNT = 6
end

local MAX_LIFETIME = beamDuration + 5
task.delay(MAX_LIFETIME, function()
	if script.Parent and script.Parent.Parent then
		script.Parent:Destroy()
	end
end)

task.spawn(function()
	while script.Parent and script.Parent.Parent do
		local hitbox = script.Parent
		if not hitbox:IsA("BasePart") then break end

		local attacker = Players:FindFirstChild(attackerName)
		if attacker then
			local attackerChar = attacker.Character
			local hitboxPos = hitbox.Position
			local hitRadius = hitbox.Size.Magnitude / 2

			
			
			for _, player in ipairs(Players:GetPlayers()) do
				local char = player.Character
				if char and char ~= attackerChar then
					if not hitDebounce[char] then
						local humanoid = char:FindFirstChildOfClass("Humanoid")
						if humanoid and humanoid.Health > 0 then
							local hrp = char:FindFirstChild("HumanoidRootPart")
							if hrp then
								local attackerHumanoid = attackerChar and attackerChar:FindFirstChildOfClass("Humanoid")
								if attackerHumanoid and attackerHumanoid.Health <= 0 then
									continue
								end
								if characterTouchesHitbox(char, hitbox) then
									hitDebounce[char] = true

									local creator = humanoid:FindFirstChild("creator")
									if not creator then
										creator = Instance.new("ObjectValue")
										creator.Name = "creator"
										creator.Parent = humanoid
									end
									creator.Value = attacker
									humanoid:SetAttribute("LastDPSAttacker", attacker.UserId)
									humanoid.Health = humanoid.Health - DAMAGE_AMOUNT
									if _G.ShowIndicator then _G.ShowIndicator(attacker, DAMAGE_AMOUNT, 0, 0, char) end
									awardGCells(attacker, char)
									if Knockback and attackerChar then
										Knockback.push(char, attackerChar, "beam")
									end
									if BeamSystem and BeamSystem.ApplyBeamSlow then
										BeamSystem.ApplyBeamSlow(humanoid)
									end

									task.spawn(function()
										task.wait(DAMAGE_INTERVAL)
										hitDebounce[char] = nil
									end)
								end
							end
						end
					end
				end
				end
			end

		
		for char in pairs(charRadiusCache) do
			if not char.Parent then
				charRadiusCache[char] = nil
			end
		end

		task.wait(0.1)
	end
end)
