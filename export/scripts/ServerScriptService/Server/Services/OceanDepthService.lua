local OceanDepthService = { Name = "OceanDepth", Async = true }

local function sameColor(a, b, tolerance)
	return math.abs(a.R - b.R) <= tolerance and math.abs(a.G - b.G) <= tolerance and math.abs(a.B - b.B) <= tolerance
end

function OceanDepthService.Init()
	local cfg = require(script:FindFirstAncestor("Server").Config).OceanDepth
	if not cfg.Enabled or workspace:GetAttribute("OceanDeepened") then
		return
	end

	local floors = {}
	local wedges = {}

	for index, inst in ipairs(game:GetDescendants()) do
		if inst:IsA("WedgePart") then
			table.insert(wedges, inst)
		elseif table.find(cfg.FloorNames, inst.Name) and inst:IsA("BasePart") and inst:IsDescendantOf(workspace) then
			table.insert(floors, inst)
		end
		if index % cfg.YieldEvery == 0 then
			task.wait()
		end
	end

	if #floors == 0 then
		return
	end

	workspace:SetAttribute("OceanDeepened", true)

	local signatures = {}
	for _, floor in ipairs(floors) do
		table.insert(signatures, { Material = floor.Material, Color = floor.Color })
		floor.CFrame = floor.CFrame - Vector3.new(0, cfg.DepthDrop, 0)
	end

	for _, wedge in ipairs(wedges) do
		if wedge.CFrame.UpVector.Y >= cfg.MinUpright then
			for _, signature in ipairs(signatures) do
				if wedge.Material == signature.Material and sameColor(wedge.Color, signature.Color, cfg.ColorTolerance) then
					local cf = wedge.CFrame
					local size = wedge.Size
					wedge.Size = Vector3.new(size.X, size.Y + cfg.WedgeGrow, size.Z)
					wedge.CFrame = cf * CFrame.new(0, -cfg.WedgeGrow / 2, 0)
					break
				end
			end
		end
	end
end

return OceanDepthService
