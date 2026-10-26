local Selection = script.Parent
local ScrollWindow = Selection:WaitForChild("ScrollWindow")
local StatsWindow = Selection:WaitForChild("StatsWindow")
local CharacterValue = StatsWindow:WaitForChild("Character")

local function onImageButtonClick(imageButton)
	local nameTag = imageButton:FindFirstChild("NameTag")
	if nameTag and nameTag:IsA("TextLabel") then
		CharacterValue.Value = nameTag.Text
	end
end

local function setupImageButton(descendant)
	if descendant:IsA("ImageButton") then
		descendant.MouseButton1Click:Connect(function()
			onImageButtonClick(descendant)
		end)
	end
end

for _, descendant in ScrollWindow:GetDescendants() do
	setupImageButton(descendant)
end

ScrollWindow.DescendantAdded:Connect(setupImageButton)
