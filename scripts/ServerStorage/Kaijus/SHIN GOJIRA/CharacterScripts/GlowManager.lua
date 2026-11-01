local TweenService = game:GetService("TweenService")

local GlowManager = {}

local model = script.Parent.Parent
local parts = nil
local activeCount = 0
local originalProps = {}
local activeTweens = {}

local brightPurple = Color3.fromRGB(160, 0, 255)
local brighterPurple = Color3.fromRGB(255, 102, 204)

local function getGlowAndRedParts()
	if parts then return parts end
	parts = {}
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

local function cancelAllTweens()
	for _, tween in ipairs(activeTweens) do
		tween:Cancel()
	end
	activeTweens = {}
end

function GlowManager.StartGlow(chargeDuration)
	activeCount = activeCount + 1
	local glowParts = getGlowAndRedParts()

	cancelAllTweens()

	if activeCount == 1 then
		for _, part in ipairs(glowParts) do
			if not originalProps[part] then
				originalProps[part] = {
					Color = part.Color,
					Material = part.Material,
				}
			end
		end
	end

	local totalDuration = tonumber(chargeDuration) or 0

	-- No charge duration: snap to the glow instantly (original behavior)
	if totalDuration <= 0 then
		for _, part in ipairs(glowParts) do
			part.Material = Enum.Material.Neon
			part.Color = brightPurple
		end

		local brightTweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		for _, part in ipairs(glowParts) do
			local tween = TweenService:Create(part, brightTweenInfo, { Color = brighterPurple })
			table.insert(activeTweens, tween)
			tween:Play()
		end
		return
	end

	-- Charge duration: tween the glow in over the charge period instead of snapping.
	-- Stage 1 fades from the original color into the glow color (60% of the charge),
	-- stage 2 brightens it to the full charge color (remaining 40%).
	local stage1Time = totalDuration * 0.6
	local stage2Time = totalDuration * 0.4

	for _, part in ipairs(glowParts) do
		part.Material = Enum.Material.Neon
		local startColor = originalProps[part] and originalProps[part].Color or part.Color
		part.Color = startColor
	end

	local stage1Info = TweenInfo.new(stage1Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local stage2Info = TweenInfo.new(stage2Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	for _, part in ipairs(glowParts) do
		local tween = TweenService:Create(part, stage1Info, { Color = brightPurple })
		local tween2 = TweenService:Create(part, stage2Info, { Color = brighterPurple })
		table.insert(activeTweens, tween)
		table.insert(activeTweens, tween2)

		tween.Completed:Connect(function(playbackState)
			if playbackState == Enum.PlaybackState.Completed and activeCount > 0 then
				tween2:Play()
			end
		end)
		tween:Play()
	end
end

function GlowManager.EndGlow()
	activeCount = math.max(0, activeCount - 1)

	if activeCount > 0 then
		return
	end

	cancelAllTweens()
	local glowParts = getGlowAndRedParts()
	local restoreTweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	for _, part in ipairs(glowParts) do
		local props = originalProps[part]
		if props then
			local tween = TweenService:Create(part, restoreTweenInfo, { Color = props.Color })
			table.insert(activeTweens, tween)
			tween:Play()
			local partRef = part
			local propsRef = props
			tween.Completed:Connect(function()
				if activeCount == 0 then
					partRef.Material = propsRef.Material
					originalProps[partRef] = nil
				end
			end)
		end
	end
end

return GlowManager