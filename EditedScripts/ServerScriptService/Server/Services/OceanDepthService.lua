local OceanDepthService = { Name = "OceanDepth", Async = true }

local function sameColor(a, b, tolerance)
	return math.abs(a.R - b.R) <= tolerance and math.abs(a.G - b.G) <= tolerance and math.abs(a.B - b.B) <= tolerance
end

function OceanDepthService.Init()
	local cfg = require(script:FindFirstAncestor("Server").Config).OceanDepth
	if not cfg.Enabled or workspace:GetAttribute("OceanDeepened") then
		return
	end

	local material = Enum.Material[cfg.Material]
	local best, bestVolume = nil, 0
	local wedges = {}

	for index, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("BasePart") and inst.Material == material then
			if inst:IsA("WedgePart") then
				table.insert(wedges, inst)
			elseif not inst:IsA("CornerWedgePart") then
				local volume = inst.Size.X * inst.Size.Y * inst.Size.Z
				if volume > bestVolume then
					best, bestVolume = inst, volume
				end
			end
		end
		if index % cfg.YieldEvery == 0 then
			task.wait()
		end
	end

	if not best then
		return
	end

	workspace:SetAttribute("OceanDeepened", true)

	local floorColor = best.Color
	best.CFrame = best.CFrame - Vector3.new(0, cfg.DepthDrop, 0)

	for _, wedge in ipairs(wedges) do
		local upright = wedge.CFrame.UpVector.Y >= cfg.MinUpright
		if upright and sameColor(wedge.Color, floorColor, cfg.ColorTolerance) then
			local cf = wedge.CFrame
			local size = wedge.Size
			wedge.Size = Vector3.new(size.X, size.Y + cfg.WedgeGrow, size.Z)
			wedge.CFrame = cf * CFrame.new(0, -cfg.WedgeGrow / 2, 0)
		end
	end
end

return OceanDepthService
