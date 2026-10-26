local clickSound = script.Parent:FindFirstChild("Button")
local mainFrame = script.Parent:FindFirstChild("MainFrame")

local function playClickSound()
	if clickSound then
		clickSound:Play()
	end
end

local function showFrame(frameName)
	if not mainFrame then return end

	for _, child in mainFrame:GetChildren() do
		if child:IsA("Frame") then
			child.Visible = false
		end
	end

	local targetFrame = mainFrame:FindFirstChild(frameName)
	if targetFrame then
		targetFrame.Visible = true
	end
end

local function showMainMenu()
	if not mainFrame then return end

	for _, child in mainFrame:GetChildren() do
		if child:IsA("Frame") then
			child.Visible = false
		end
	end

	local mainMenu = mainFrame:FindFirstChild("MainMenu")
	if mainMenu then
		mainMenu.Visible = true
	end
end

for _, descendant in script.Parent:GetDescendants() do
	if descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
		descendant.MouseButton1Click:Connect(playClickSound)
	end
end

local mainMenu = mainFrame and mainFrame:FindFirstChild("MainMenu")
if mainMenu then

	local howToPlayBtn = mainMenu:FindFirstChild("HowToPlay")
	if howToPlayBtn then
		howToPlayBtn.MouseButton1Click:Connect(function()
			showFrame("HTP")
		end)
	end

	local moreBtn = mainMenu:FindFirstChild("More")
	if moreBtn then
		moreBtn.MouseButton1Click:Connect(function()
			showFrame("MoreGames")
		end)
	end

	local playBtn = mainMenu:FindFirstChild("Play")
	if playBtn then
		playBtn.MouseButton1Click:Connect(function()
			showFrame("Selection")
		end)
	end

	local storeBtn = mainMenu:FindFirstChild("Store")
	if storeBtn then
		storeBtn.MouseButton1Click:Connect(function()
			showFrame("Store")
		end)
	end
end

for _, descendant in mainFrame:GetDescendants() do
	if descendant.Name == "Back" and (descendant:IsA("TextButton") or descendant:IsA("ImageButton")) then
		descendant.MouseButton1Click:Connect(showMainMenu)
	end
end

while wait(0.1) do
	local player = game.Players.LocalPlayer
	local leaderstats = player and player:FindFirstChild("leaderstats")
	local gcells = leaderstats and leaderstats:FindFirstChild("GCells")
	if gcells then
		script.Parent.MainFrame.MainMenu.GCells.Text = "GCells: "..tostring(gcells.Value)
		script.Parent.MainFrame.Selection.GCells.Text = "GCells: "..tostring(gcells.Value)
		script.Parent.MainFrame.Skins.GCells.Text = "GCells: "..tostring(gcells.Value)
	end
end
