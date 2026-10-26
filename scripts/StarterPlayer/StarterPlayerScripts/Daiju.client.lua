local Players = game:GetService("Players")
local player = Players.LocalPlayer

if player.Name == "L0tzie" then

	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		playerGui = player:WaitForChild("PlayerGui", 10)
	end
	if not playerGui then return end

	local newMenu = playerGui:FindFirstChild("NEWMenu")
	if not newMenu then
		newMenu = playerGui:WaitForChild("NEWMenu", 10)
	end
	if not newMenu then return end
	local kaijus = newMenu:FindFirstChild("Kaijus")
	local list = kaijus and kaijus:FindFirstChild("List")
	local scrollFrame = list and list:FindFirstChild("ScrollingFrame")

	if scrollFrame then

		local entityEntry = scrollFrame:FindFirstChild("ENTITY")
		if entityEntry then
			entityEntry.Visible = true
		end
	end
end
