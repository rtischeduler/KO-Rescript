local GlowManager = {}

local model = script.Parent.Parent
local parts = nil
local activeCount = 0
local originalProps = {}
local generation = 0

local glowColor = Color3.fromRGB(38, 255, 0)

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

-- Ignition order: parts sorted by the number in their name, ascending.
-- Shin's glow parts are one continuous sequence (SpikeGlow 1-40 up the
-- tail, then Red 41-75 up the body), so this sweeps tail to head, matching
-- GODZILLA 2014's dorsal spike charge in this game.
local function getIgnitionOrder()
	local glowParts = getGlowAndRedParts()
	local numbered = {}
	local unnumbered = {}
	for _, part in ipairs(glowParts) do
		local number = tonumber(string.match(part.Name, "%d+"))
		if number then
			table.insert(numbered, { part = part, number = number })
		else
			table.insert(unnumbered, part)
		end
	end
	table.sort(numbered, function(a, b) return a.number < b.number end)
	local ordered = {}
	for _, entry in ipairs(numbered) do
		table.insert(ordered, entry.part)
	end
	for _, part in ipairs(unnumbered) do
		table.insert(ordered, part)
	end
	return ordered
end

function GlowManager.StartGlow(chargeDuration)
	activeCount = activeCount + 1
	local glowParts = getGlowAndRedParts()

	generation += 1
	local myGeneration = generation

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
	local ordered = getIgnitionOrder()

	-- No charge duration: snap everything to the glow instantly.
	if totalDuration <= 0 then
		for _, part in ipairs(ordered) do
			part.Material = Enum.Material.Neon
			part.Color = glowColor
		end
		return
	end

	-- Charge duration: ignite the parts one by one, tail to head, each
	-- one staying lit until the beam ends (2014-style dorsal charge).
	local perPartDelay = totalDuration / #ordered
	task.spawn(function()
		for _, part in ipairs(ordered) do
			if generation ~= myGeneration or activeCount <= 0 or not part.Parent then
				break
			end
			part.Material = Enum.Material.Neon
			part.Color = glowColor
			task.wait(perPartDelay)
		end
	end)
end

function GlowManager.EndGlow()
	activeCount = math.max(0, activeCount - 1)

	if activeCount > 0 then
		return
	end

	generation += 1
	local ordered = getIgnitionOrder()

	-- Power down in reverse ignition order (head to tail), one part at a
	-- time, restoring each part's original look instantly.
	local perPartDelay = math.min(0.1, 2 / #ordered)
	task.spawn(function()
		for i = #ordered, 1, -1 do
			local part = ordered[i]
			local props = originalProps[part]
			if props and part.Parent then
				part.Color = props.Color
				part.Material = props.Material
				originalProps[part] = nil
			end
			task.wait(perPartDelay)
		end
	end)
end

return GlowManager