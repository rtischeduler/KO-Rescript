local TweenService = game:GetService("TweenService")
local beamRemote = script.Parent
local beamSound = script.Parent.Parent.Sounds.Beam
local animationsFolder = script.Parent.Parent.Parent:FindFirstChild("Animations")

local debounce = {}

local function getGlowAndRedParts()
	local model = script.Parent.Parent.Parent
	local parts = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local name = descendant.Name
			if string.find(name, "Glow") or string.find(name, "Red") then
				table.insert(parts, descendant)
			end
		end
	end
	return parts
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
	
	-- Clone and play the Beam sound on HumanoidRootPart
	local soundClone = beamSound:Clone()
	soundClone.Parent = hrp
	soundClone:Play()

	-- Glow effect: store originals, set to neon purple, then tween brighter
	local glowParts = getGlowAndRedParts()
	local originalProps = {}
	local brightPurple = Color3.fromRGB(160, 0, 255)
	local brighterPurple = Color3.fromRGB(255, 102, 204)

	for _, part in glowParts do
		originalProps[part] = {
			Color = part.Color,
			Material = part.Material,
		}
		part.Material = Enum.Material.Neon
		part.Color = brightPurple
	end

	-- Tween to brighter purple
	local brightTweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, part in glowParts do
		local tween = TweenService:Create(part, brightTweenInfo, { Color = brighterPurple })
		tween:Play()
	end

	-- Wait for sound to finish
	--soundClone.Ended:Wait()
	script.Parent.Parent.Parent.HitParts.Beam1.Transparency = 1
	script.Parent.Parent.Parent.HitParts.Beam1.DPS.Enabled = true
	task.wait(4.5)
	script.Parent.Parent.Parent.HitParts.Beam1.Transparency = 0
	task.wait(7)
	script.Parent.Parent.Parent.HitParts.Beam1.DPS.Enabled = false
	script.Parent.Parent.Parent.HitParts.Beam1.Transparency = 1

	-- Tween Glow parts back to normal (slowly)
	local restoreTweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	for _, part in glowParts do
		local props = originalProps[part]
		if props then
			local tween = TweenService:Create(part, restoreTweenInfo, { Color = props.Color })
			tween:Play()
			tween.Completed:Connect(function()
				part.Material = props.Material
			end)
		end
	end

	-- Delete the sound
	soundClone:Destroy()
	
	-- Allow beam to be used again
	debounce[player] = nil
end)