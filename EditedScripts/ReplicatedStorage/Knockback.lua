local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knockback = {}

local SETTINGS = {
	attack = { speed = 30, lift = 8 },
	beam = { speed = 4, lift = 0 },
}
local MAX_FLAT_SPEED = 45

local function addVelocity(root, vec)
	local v = root.AssemblyLinearVelocity + vec
	local flat = Vector3.new(v.X, 0, v.Z)
	if flat.Magnitude > MAX_FLAT_SPEED then
		flat = flat.Unit * MAX_FLAT_SPEED
		v = Vector3.new(flat.X, v.Y, flat.Z)
	end
	root.AssemblyLinearVelocity = v
end

if RunService:IsServer() then
	local remote = ReplicatedStorage:FindFirstChild("KnockbackEvent")
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = "KnockbackEvent"
		remote.Parent = ReplicatedStorage
	end

	function Knockback.push(targetChar, sourceChar, kind)
		local setting = SETTINGS[kind]
		local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
		local sourceRoot = sourceChar and sourceChar:FindFirstChild("HumanoidRootPart")
		if not setting or not targetRoot or not sourceRoot then return end
		local flat = Vector3.new(targetRoot.Position.X - sourceRoot.Position.X, 0, targetRoot.Position.Z - sourceRoot.Position.Z)
		if flat.Magnitude < 0.01 then return end
		local vec = flat.Unit * setting.speed + Vector3.new(0, setting.lift, 0)
		local player = Players:GetPlayerFromCharacter(targetChar)
		if player then
			remote:FireClient(player, vec)
		else
			addVelocity(targetRoot, vec)
		end
	end
else
	local remote = ReplicatedStorage:WaitForChild("KnockbackEvent")
	remote.OnClientEvent:Connect(function(vec)
		local player = Players.LocalPlayer
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and typeof(vec) == "Vector3" then
			addVelocity(root, vec)
		end
	end)
end

return Knockback
