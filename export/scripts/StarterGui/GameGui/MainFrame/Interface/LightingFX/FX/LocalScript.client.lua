local Lighting = game:GetService("Lighting")

local function disableAllEffects()
	for _, child in script.Parent:GetChildren() do
		if child:IsA("TextButton") then
			local effect = Lighting:FindFirstChild(child.Name)
			if effect then
				effect.Enabled = false
			end
		end
	end
end

for _, child in script.Parent:GetChildren() do
	if child:IsA("TextButton") then
		local effect = Lighting:FindFirstChild(child.Name)
		if effect then
			child.MouseButton1Click:Connect(function()
				disableAllEffects()
				effect.Enabled = true
			end)
		end
	end
end
