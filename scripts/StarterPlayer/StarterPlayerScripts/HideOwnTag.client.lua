local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

local function hideTagIfMatch(instance)
	if instance.Name == "Tag" and instance:IsA("BillboardGui") then
		instance.Enabled = false
	end
end

local function hideOwnTag(character)
	
	for _, descendant in character:GetDescendants() do
		hideTagIfMatch(descendant)
	end

	
	character.DescendantAdded:Connect(hideTagIfMatch)
end

localPlayer.CharacterAdded:Connect(function(character)
	hideOwnTag(character)
end)

if localPlayer.Character then
	hideOwnTag(localPlayer.Character)
end
