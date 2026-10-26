local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function updateGCellsDisplay()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
	if gcells then
		script.Parent.Text = "GCells: " .. tostring(gcells.Value)
	end
end

local function waitForLeaderstats()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats then
		local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
		if gcells then

			gcells:GetPropertyChangedSignal("Value"):Connect(updateGCellsDisplay)

			updateGCellsDisplay()
		end

		leaderstats.ChildAdded:Connect(function(child)
			if child.Name == "GCells" or child.Name == "gcells" then
				child:GetPropertyChangedSignal("Value"):Connect(updateGCellsDisplay)
				updateGCellsDisplay()
			end
		end)
	end
end

waitForLeaderstats()
