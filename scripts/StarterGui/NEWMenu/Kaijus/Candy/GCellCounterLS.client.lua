local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function updateCandyDisplay()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local candy = leaderstats:FindFirstChild("Candy")
	if candy then
		script.Parent.Text = "Candy: " .. tostring(candy.Value)
	end
end

local function waitForLeaderstats()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats then
		local candy = leaderstats:FindFirstChild("Candy")
		if candy then

			candy:GetPropertyChangedSignal("Value"):Connect(updateCandyDisplay)

			updateCandyDisplay()
		end

		leaderstats.ChildAdded:Connect(function(child)
			if child.Name == "Candy" then
				child:GetPropertyChangedSignal("Value"):Connect(updateCandyDisplay)
				updateCandyDisplay()
			end
		end)
	end
end

waitForLeaderstats()
