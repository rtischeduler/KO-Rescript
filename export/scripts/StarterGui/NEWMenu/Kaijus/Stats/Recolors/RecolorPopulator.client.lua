local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local setRecolorEvent = ReplicatedStorage:WaitForChild("SetRecolor", 10)
local LevelManager = require(ReplicatedStorage:WaitForChild("LevelManager"))
local getKaijuDataFunc = ReplicatedStorage:WaitForChild("GetKaijuData", 10)

local RECOLOR_GAMEPASS_ID = 1819433033
local Recolors = require(ReplicatedStorage:WaitForChild("Recolors"))
local GOLD_REQUIRED_LEVEL = Recolors.Unlock.Gold.level
local localPlayer = Players.LocalPlayer

local ownsRecolorGamepass = nil

local recolorsFrame = script.Parent
local template = recolorsFrame:FindFirstChild("Template")
local statsFrame = recolorsFrame.Parent

local SELECTED_COLOR = Color3.fromRGB(116, 125, 255)
local NO_SKIN_NAME = "NO SKIN"

local kaijuRecolorSelections = {}

local currentSelectedButton = nil
local currentMorphName = nil
local kaijuLevelCache = {}
local diamondButton = nil
local goldButton = nil

local layout = Instance.new("UIListLayout")
layout.Name = "RecolorListLayout"
layout.FillDirection = Enum.FillDirection.Horizontal
layout.VerticalAlignment = Enum.VerticalAlignment.Top
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = recolorsFrame

local function selectButtonVisual(button)

	if currentSelectedButton and currentSelectedButton ~= button then
		local stroke = currentSelectedButton:FindFirstChild("SelectionStroke")
		if stroke then
			stroke.Transparency = 1
		end
	end

	currentSelectedButton = button
	local stroke = button:FindFirstChild("SelectionStroke")
	if stroke then
		stroke.Transparency = 0
	end
end

local function isKaijuMaxLevel(morphName)
	if not morphName then return false end
	local level = kaijuLevelCache[morphName] or 1
	local maxLevel = LevelManager.GetMaxLevel(morphName)
	return level >= maxLevel
end

local function isKaijuLevel50(morphName)
	if not morphName then return false end
	local level = kaijuLevelCache[morphName] or 1
	return level >= GOLD_REQUIRED_LEVEL
end

local function checkRecolorGamepass()
	return true
end

local function updateDiamondLockState()
	if not diamondButton then return end
	local maxed = isKaijuMaxLevel(currentMorphName)
	local textLabel = diamondButton:FindFirstChild("TextLabel")
	if maxed then
		diamondButton.ImageTransparency = 0
		if textLabel then
			textLabel.Text = "Diamond"
			textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	else
		diamondButton.ImageTransparency = 0.6
		if textLabel then
			textLabel.Text = "Diamond (Max Lvl)"
			textLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end
end

local function updateGoldLockState()
	if not goldButton then return end
	local unlocked = isKaijuLevel50(currentMorphName)
	local textLabel = goldButton:FindFirstChild("TextLabel")
	if unlocked then
		goldButton.ImageTransparency = 0
		if textLabel then
			textLabel.Text = "Gold"
			textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	else
		goldButton.ImageTransparency = 0.6
		if textLabel then
			textLabel.Text = "Gold (Lvl 50)"
			textLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end
end

local function createRecolorButton(recolorName, primaryColor, secondaryColor, tertiaryColor, eyeColor, isNoSkin)
	local clone = template:Clone()
	clone.Name = recolorName
	clone.Visible = true

	if not isNoSkin and primaryColor then
		clone.ImageColor3 = primaryColor
	end

	local textLabel = clone:FindFirstChild("TextLabel")
	if textLabel then
		textLabel.Text = recolorName
	end

	if not isNoSkin then
		local strip = Instance.new("Frame")
		strip.Name = "ColorStrip"
		strip.Size = UDim2.new(1, 0, 0, 4)
		strip.Position = UDim2.new(0, 0, 0, 0)
		strip.BackgroundTransparency = 1
		strip.ZIndex = 4
		strip.Parent = clone

		local stripLayout = Instance.new("UIListLayout")
		stripLayout.FillDirection = Enum.FillDirection.Horizontal
		stripLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		stripLayout.Padding = UDim.new(0, 0)
		stripLayout.SortOrder = Enum.SortOrder.LayoutOrder
		stripLayout.Parent = strip

		local function addStripColor(color, order)
			local bar = Instance.new("Frame")
			bar.Size = UDim2.new(0.25, 0, 1, 0)
			bar.BackgroundColor3 = color or Color3.new(0.5, 0.5, 0.5)
			bar.BorderSizePixel = 0
			bar.ZIndex = 5
			bar.LayoutOrder = order
			bar.Parent = strip
		end

		addStripColor(primaryColor, 1)
		addStripColor(secondaryColor, 2)
		addStripColor(tertiaryColor, 3)
		addStripColor(eyeColor, 4)
	end

	local stroke = Instance.new("UIStroke")
	stroke.Name = "SelectionStroke"
	stroke.Color = SELECTED_COLOR
	stroke.Thickness = 3
	stroke.Transparency = 1
	stroke.Parent = clone

	local btn = clone:FindFirstChild("Btn")
	if btn then
		btn.MouseButton1Click:Connect(function()

			if recolorName == "Diamond" and not isKaijuMaxLevel(currentMorphName) then
				return
			end

			if recolorName == "Gold" and not isKaijuLevel50(currentMorphName) then
				return
			end

			if recolorName ~= "NO SKIN" and recolorName ~= "Diamond" and recolorName ~= "Gold" then
				if not checkRecolorGamepass() then
					MarketplaceService:PromptGamePassPurchase(localPlayer, RECOLOR_GAMEPASS_ID)
					return
				end
			end

			if currentMorphName then
				kaijuRecolorSelections[currentMorphName] = recolorName

				if setRecolorEvent then
					setRecolorEvent:FireServer(currentMorphName, recolorName)
				end
			end

			selectButtonVisual(clone)
		end)
	end

	return clone
end

local function populateRecolors()

	local noSkinBtn = createRecolorButton(NO_SKIN_NAME, nil, nil, nil, nil, true)
	noSkinBtn.LayoutOrder = 0
	noSkinBtn.Parent = recolorsFrame

	local order = 1
	for _, name in ipairs(Recolors.Order) do
		local d = Recolors.Get(name)
		local button = createRecolorButton(name, d.Primary or Color3.new(1, 1, 1), d.Secondary, d.Tertiary, d.EyeColor, false)
		button.LayoutOrder = order
		button.Parent = recolorsFrame
		if name == "Diamond" then
			diamondButton = button
		elseif name == "Gold" then
			goldButton = button
		end
		order = order + 1
	end
end

local function onKaijuChanged(morphName)
	currentMorphName = morphName

	if not morphName then return end

	local savedRecolor = kaijuRecolorSelections[morphName] or NO_SKIN_NAME

	local button = recolorsFrame:FindFirstChild(savedRecolor)
	if button then
		selectButtonVisual(button)
	end

	updateDiamondLockState()

	updateGoldLockState()
end

if statsFrame then
	statsFrame:GetAttributeChangedSignal("CurrentMorph"):Connect(function()
		local morph = statsFrame:GetAttribute("CurrentMorph")
		onKaijuChanged(morph)
	end)

	local existingMorph = statsFrame:GetAttribute("CurrentMorph")
	if existingMorph then
		onKaijuChanged(existingMorph)
	end
end

populateRecolors()

task.spawn(function()
	if getKaijuDataFunc then
		local success, data = pcall(function()
			return getKaijuDataFunc:InvokeServer()
		end)
		if success and type(data) == "table" then
			for kaijuName, kaijuData in pairs(data) do
				kaijuLevelCache[kaijuName] = kaijuData.level or 1
			end

			updateDiamondLockState()
			updateGoldLockState()
		end
	end
end)

local levelUpdateRemote = ReplicatedStorage:FindFirstChild("LevelUpdate")
if levelUpdateRemote then
	levelUpdateRemote.OnClientEvent:Connect(function(data)
		if data and data.kaiju then
			kaijuLevelCache[data.kaiju] = data.level or kaijuLevelCache[data.kaiju] or 1

			if data.kaiju == currentMorphName then
				updateDiamondLockState()
				updateGoldLockState()
			end
		end
	end)
end

local getRecolorDataFunc = ReplicatedStorage:WaitForChild("GetRecolorData", 10)
if getRecolorDataFunc then
	task.spawn(function()
		local savedRecolors = getRecolorDataFunc:InvokeServer()
		if type(savedRecolors) == "table" then
			for kaijuName, recolorName in pairs(savedRecolors) do
				kaijuRecolorSelections[kaijuName] = recolorName
			end

			if currentMorphName then
				onKaijuChanged(currentMorphName)
			end
		end
	end)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
	if player == localPlayer and gamepassId == RECOLOR_GAMEPASS_ID and wasPurchased then
		ownsRecolorGamepass = true
	end
end)

template.Parent = nil
