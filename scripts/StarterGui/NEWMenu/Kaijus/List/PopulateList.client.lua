local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local player = Players.LocalPlayer
local CANDY_COLOR = Color3.fromRGB(255, 140, 0)
local candyModule = ReplicatedStorage:WaitForChild("CandyConfig", 15)
local CandyConfig = candyModule and require(candyModule)
local function isSeason()
	return CandyConfig ~= nil and CandyConfig.isSeason()
end
local function isCandyModel(model)
	local parent = model.Parent
	while parent and parent.Name ~= "Morphs" do
		if string.lower(string.sub(parent.Name, 1, 9)) == "halloween" then
			return true
		end
		parent = parent.Parent
	end
	return false
end
local scrollingFrame = script.Parent:FindFirstChild("ScrollingFrame")
if not scrollingFrame then return end
local template = scrollingFrame:FindFirstChild("Template")
if not template then return end
local morphSupplies = ReplicatedStorage:WaitForChild("MorphSupplies", 30)
local morphs = morphSupplies and morphSupplies:WaitForChild("Morphs", 30)
if not morphs then
	warn("PopulateList: MorphSupplies.Morphs was not available")
	return
end
for _ = 1, 300 do
	if #morphs:GetChildren() > 0 then break end
	task.wait(0.1)
end
local kaijusFrame = script.Parent.Parent
local statsFrame = kaijusFrame:FindFirstChild("Stats")
local kaijuNameLabel = statsFrame and statsFrame:FindFirstChild("KaijuName")
local levelLabel = statsFrame and statsFrame:FindFirstChild("Level")
local kaijuImageLabel = statsFrame and statsFrame:FindFirstChild("KaijuImage")
local skillPointsTxt = statsFrame and statsFrame:FindFirstChild("SkillPointsTxt")
local selectButton = statsFrame and statsFrame:FindFirstChild("Select")
local selectTxt = selectButton and selectButton:FindFirstChild("TXT")
local newMenu = kaijusFrame.Parent
local mainMenu = newMenu and newMenu:FindFirstChild("MainMenu")
local getKaijuDataFunc
local getOwnershipFunc
local buyKaijuEvent
local setSelectedKaijuEvent
local getGamepassKaijusFunc
local getSelectedKaijuFunc
local remoteNames = {
	GetKaijuData = true,
	GetKaijuOwnership = true,
	BuyKaiju = true,
	SetSelectedKaiju = true,
	GetGamepassKaijus = true,
	GetSelectedKaiju = true,
}
local function refreshRemotes()
	getKaijuDataFunc = ReplicatedStorage:FindFirstChild("GetKaijuData")
	getOwnershipFunc = ReplicatedStorage:FindFirstChild("GetKaijuOwnership")
	buyKaijuEvent = ReplicatedStorage:FindFirstChild("BuyKaiju")
	setSelectedKaijuEvent = ReplicatedStorage:FindFirstChild("SetSelectedKaiju")
	getGamepassKaijusFunc = ReplicatedStorage:FindFirstChild("GetGamepassKaijus")
	getSelectedKaijuFunc = ReplicatedStorage:FindFirstChild("GetSelectedKaiju")
end
refreshRemotes()
ReplicatedStorage.ChildAdded:Connect(function(child)
	if remoteNames[child.Name] then
		refreshRemotes()
	end
end)

local kaijuDataCache = {}
local ownershipCache = {}
local gamepassKaijusCache = {}
local gamepassInfoCache = {}
local currentMorphName = nil
local currentKaijuName = nil
local currentPrice = 0
local currentOwned = false
local currentRequirement = nil
local currentIsCandy = false
local function formatBuyText(price, requirement, isCandy)
	if isCandy and not isSeason() then
		return "Offsale until halloween"
	end
	if price == math.huge then
		return "Not for sale yet"
	end
	local text = "BUY (" .. tostring(price) .. (isCandy and " Candy" or "")
	if requirement and requirement ~= "" then
		local reqTexts = {}
		for reqPart in requirement:gmatch("[^,]+") do
			reqPart = reqPart:match("^%s*(.-)%s*$")
			local reqKaiju, reqLevel = reqPart:match("^(.+):(%d+)$")
			if reqKaiju and reqLevel then
				table.insert(reqTexts, "Lvl " .. reqLevel .. " " .. reqKaiju)
			end
		end
		if #reqTexts > 0 then
			text = text .. ", Requires " .. table.concat(reqTexts, " & ")
		end
	end
	text = text .. ")"
	return text
end
local morphInfoMap = {}
local function getMorphAttribute(model, attributeName, fallback)
	local ok, value = pcall(function()
		return model:GetAttribute(attributeName)
	end)
	if ok and value ~= nil then
		return value
	end
	return fallback
end
local LEGACY_MORPH_NAMES = {
	["Godzilla1954"] = "GOJIRA [FREE]",
	["Anguirus"] = "ANGUIRUS [FREE]",
	["KamataKun"] = "SHIN FORM 2 [FREE]",
	["Godzilla2014"] = "GODZILLA 2014",
	["F16C"] = "F16C [FREE]",
	["Human"] = "CIVILIAN [FREE]",
	["Tank"] = "MILITARY TANK [FREE]",
}
local function getKaijuDataEntry(morphName)
	local data = kaijuDataCache[morphName]
	if data then return data end
	local legacyName = nil
	for oldName, currentName in pairs(LEGACY_MORPH_NAMES) do
		if currentName == morphName then
			legacyName = oldName
			break
		end
	end
	return legacyName and kaijuDataCache[legacyName] or nil
end
local function fetchKaijuData()
	if getKaijuDataFunc then
		local success, data = pcall(function()
			return getKaijuDataFunc:InvokeServer()
		end)
		if success and type(data) == "table" then
			kaijuDataCache = data
		end
	end
end
local function fetchOwnership()
	if getOwnershipFunc then
		local success, data = pcall(function()
			return getOwnershipFunc:InvokeServer()
		end)
		if success and type(data) == "table" then
			ownershipCache = data
		end
	end
end
local function fetchGamepassKaijus()
	if getGamepassKaijusFunc then
		local success, data = pcall(function()
			return getGamepassKaijusFunc:InvokeServer()
		end)
		if success and type(data) == "table" then
			gamepassKaijusCache = data
		end
	end
end
local function fetchGamepassInfo()
	for morphName, gamepassId in pairs(gamepassKaijusCache) do
		if not gamepassInfoCache[gamepassId] then
			local success, info = pcall(function()
				return MarketplaceService:GetProductInfoAsync(tonumber(gamepassId), Enum.InfoType.GamePass)
			end)
			if success and info then
				gamepassInfoCache[gamepassId] = info
			end
		end
	end
end
local function isGamepassKaiju(morphName)
	return gamepassKaijusCache[morphName] ~= nil
end
local MANUAL_OFFSALE_GAMEPASSES = {}
local function isGamepassOffsale(morphName)
	if MANUAL_OFFSALE_GAMEPASSES[morphName] then return true end
	local gamepassId = gamepassKaijusCache[morphName]
	if not gamepassId then return false end
	local info = gamepassInfoCache[gamepassId]
	if not info then return false end
	return not info.IsForSale
end
local function getMorphPrice(morphModel)
	local stats = morphModel:FindFirstChild("Stats")
	if stats then
		local price = stats:FindFirstChild("Price")
		if price then
			return price.Value
		end
	end
	if isCandyModel(morphModel) then
		return math.huge
	end
	return 0
end
local function isOwned(morphName, price)
	if price <= 0 then return true end
	if ownershipCache[morphName] then return true end
	return false
end
local function getLayoutOrder(morphName)
	local upper = string.upper(morphName)
	if upper == "GOJIRA [FREE]" then
		return 0
	elseif upper == "SHIN FORM 2 [FREE]" then
		return 1
	elseif upper == "ANGUIRUS [FREE]" then
		return 2
	elseif upper == "MILITARY TANK [FREE]" then
		return 9998
	elseif upper == "CIVILIAN [FREE]" then
		return 9999
	else
		return nil
	end
end
local sortedMorphs = {}
local function collectModels(folder)
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") then
			table.insert(sortedMorphs, model)
		elseif model:IsA("Folder") and string.lower(string.sub(model.Name, 1, 9)) == "halloween" then
			collectModels(model)
		end
	end
end
collectModels(morphs)
table.sort(sortedMorphs, function(a, b)
	return a.Name < b.Name
end)
local layoutOrders = {}
local otherIndex = 100
for _, model in ipairs(sortedMorphs) do
	local order = getLayoutOrder(model.Name)
	if order then
		layoutOrders[model.Name] = order
	else
		layoutOrders[model.Name] = otherIndex
		otherIndex = otherIndex + 1
	end
end
local layout = scrollingFrame:FindFirstChild("KaijuListLayout")
if not layout then
	layout = Instance.new("UIListLayout")
	layout.Name = "KaijuListLayout"
	layout.Parent = scrollingFrame
end
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Top
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
scrollingFrame.CanvasPosition = Vector2.new(0, 0)
local function refreshListCanvas()
	local contentHeight = layout.AbsoluteContentSize.Y
	local viewportHeight = scrollingFrame.AbsoluteSize.Y
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(contentHeight + 6, viewportHeight))
end
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshListCanvas)
local function selectKaiju(morphName)
	local info = morphInfoMap[morphName]
	if not info then return end
	if kaijuNameLabel then
		kaijuNameLabel.Text = info.kaijuName
	end
	if kaijuImageLabel then
		kaijuImageLabel.Image = info.kaijuImage
	end
	local morphData = getKaijuDataEntry(morphName)
	local level = (morphData and morphData.level) or 1
	if levelLabel then
		levelLabel.Text = "Level " .. tostring(level)
	end
	currentMorphName = morphName
	currentKaijuName = info.kaijuName
	currentPrice = info.morphPrice
	currentOwned = isOwned(morphName, info.morphPrice)
	currentRequirement = info.requirement
	currentIsCandy = info.isCandy == true
	if statsFrame then
		statsFrame:SetAttribute("CurrentMorph", nil)
		statsFrame:SetAttribute("CurrentMorph", morphName)
	end
	if selectTxt then
		if currentOwned then
			selectTxt.Text = "SELECT " .. string.upper(info.kaijuName)
		elseif isGamepassKaiju(morphName) and currentOwned == false then  
			if isGamepassOffsale(morphName) then
				selectTxt.Text = "OFFSALE"
			else
					if isGamepassOffsale(currentMorphName) then
						selectTxt.Text = "OFFSALE"
					else
						selectTxt.Text = "BUY GAMEPASS"
					end
			end
		else
			selectTxt.Text = formatBuyText(info.morphPrice, info.requirement, info.isCandy)
		end
	end
end
local function populate()
	fetchKaijuData()
	fetchGamepassKaijus()
	fetchGamepassInfo()
	fetchOwnership()
	for _, model in ipairs(sortedMorphs) do
		local clone = scrollingFrame:FindFirstChild(model.Name)
		if not clone or not clone:IsA("GuiObject") then
			clone = template:Clone()
		end
		clone.Name = model.Name
		clone.Size = UDim2.new(0.968, 0, 0, 77)
		clone.Position = UDim2.new(0, 0, 0, 0)
		clone.AnchorPoint = Vector2.new(0, 0)
		clone.BackgroundTransparency = 0
		clone.ZIndex = 2
		if model.Name == "ENTITY" and player.Name ~= "L0tzie" and player.Name ~= "badkid235321" and player.Name ~= "riotfan1223" and player.Name ~= "cjax1710" then
			clone.Visible = false
		elseif model.Name == "LOTZIGAN" and player.Name ~= "L0tzie" then
			clone.Visible = false
		elseif model.Name == "UNCMINILLA" and player.Name ~= "24X_ROCK" and player.Name ~= "BlueEnderCookie_2" and player.Name ~= "riotfan1223" and player.Name ~= "HeiseiGodzilla19933" then
			clone.Visible = false
		elseif model.Name == "DESTOROYAH"
			and player.Name ~= "DenisTheCheeseKing" and player.Name ~= "BlueEnderCookie_2" and player.Name ~= "riotfan1223" then
			clone.Visible = false
		elseif model.Name == "thedenis"
			and player.Name ~= "DenisTheCheeseKing" then
			clone.Visible = false
		elseif model.Name == "RED"
			and player.Name ~= "BlueEnderCookie_2" and player.Name ~= "riotfan1223" then
			clone.Visible = false
		else
			clone.Visible = true
		end
		clone.LayoutOrder = layoutOrders[model.Name] or 0
		local kaijuName = getMorphAttribute(model, "KaijuName", model.Name)
		local kaijuDesc = getMorphAttribute(model, "KaijuDescription", "")
		local kaijuImage = getMorphAttribute(model, "KaijuImage", "")
		local nameLabel = clone:FindFirstChild("KaijuName")
		if nameLabel then
			nameLabel.Text = kaijuName
			if isCandyModel(model) then
				nameLabel.TextColor3 = CANDY_COLOR
			end
		end
		local descLabel = clone:FindFirstChild("KaijuDescription")
		if descLabel then
			descLabel.Text = kaijuDesc
		end
		local imageLabel = clone:FindFirstChild("KaijuImage")
		if imageLabel then
			imageLabel.Image = kaijuImage
		end
		local clickBtn = clone:FindFirstChild("ClickHandler")
		if not clickBtn then
			clickBtn = Instance.new("TextButton")
			clickBtn.Name = "ClickHandler"
			clickBtn.Size = UDim2.new(1, 0, 1, 0)
			clickBtn.Position = UDim2.new(0, 0, 0, 0)
			clickBtn.BackgroundTransparency = 1
			clickBtn.Text = ""
			clickBtn.ZIndex = 10
			clickBtn.Parent = clone
		end
		local morphName = model.Name
		local morphPrice = getMorphPrice(model)
		morphInfoMap[morphName] = {
			kaijuName = kaijuName,
			kaijuImage = kaijuImage,
			morphPrice = morphPrice,
			visible = clone.Visible,
			requirement = getMorphAttribute(model, "Requirement", nil),
			isCandy = isCandyModel(model),
		}
		clickBtn.MouseButton1Click:Connect(function()
			selectKaiju(morphName)
		end)
		clone.Parent = scrollingFrame
	end
	template.Visible = false
	task.defer(refreshListCanvas)
end
if selectButton then
	local slideTweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	selectButton.MouseButton1Click:Connect(function()
		if not currentMorphName then return end
		if currentOwned then
			if setSelectedKaijuEvent then
				setSelectedKaijuEvent:FireServer(currentMorphName)
			end
			TweenService:Create(kaijusFrame, slideTweenInfo, {
				Position = UDim2.new(1.1, 0, 0, 0),
			}):Play()
			if mainMenu then
				TweenService:Create(mainMenu, slideTweenInfo, {
					Position = UDim2.new(0, 0, 0, 0),
				}):Play()
			end
		elseif isGamepassKaiju(currentMorphName) then
			if not isGamepassOffsale(currentMorphName) then
				local gamepassId = gamepassKaijusCache[currentMorphName]
				if gamepassId then
					MarketplaceService:PromptGamePassPurchase(player, gamepassId)
				end
			end
		else
			if buyKaijuEvent then
				if not (currentIsCandy and not isSeason()) and currentPrice ~= math.huge then
					buyKaijuEvent:FireServer(currentMorphName)
				end
			end
		end
	end)
	if buyKaijuEvent then
		buyKaijuEvent.OnClientEvent:Connect(function(kaijuName, success, message)
			if success or message == "Already owned" then
				ownershipCache[kaijuName] = true
			end
			if kaijuName == currentMorphName then
				if success then
					currentOwned = true
					ownershipCache[currentMorphName] = true
					if selectTxt then
						selectTxt.Text = "SELECT " .. string.upper(currentKaijuName or "")
					end
					if setSelectedKaijuEvent then
						setSelectedKaijuEvent:FireServer(currentMorphName)
					end
					TweenService:Create(kaijusFrame, slideTweenInfo, {
						Position = UDim2.new(1.1, 0, 0, 0),
					}):Play()
					if mainMenu then
						TweenService:Create(mainMenu, slideTweenInfo, {
							Position = UDim2.new(0, 0, 0, 0),
						}):Play()
					end
				elseif message == "Already owned" then
					currentOwned = true
					ownershipCache[currentMorphName] = true
					if selectTxt then
						selectTxt.Text = "SELECT " .. string.upper(currentKaijuName or "")
					end
				else
					if selectTxt then
						selectTxt.Text = "FAILED: " .. tostring(message or "Unknown error")
						task.delay(3, function()
							if selectTxt and not currentOwned then
								if isGamepassKaiju(currentMorphName) then
										if isGamepassOffsale(currentMorphName) then
											selectTxt.Text = "OFFSALE"
										else
											selectTxt.Text = "BUY GAMEPASS"
										end
								else
									selectTxt.Text = formatBuyText(currentPrice, currentRequirement, currentIsCandy)
								end
							end
							end)
					end
				end
			end
		end)
	end
end
populate()
local function selectInitialMorph()
	refreshRemotes()
	local selectedMorph = nil
	if getSelectedKaijuFunc then
		local success, result = pcall(function()
			return getSelectedKaijuFunc:InvokeServer()
		end)
		if success then selectedMorph = result end
	end
	if selectedMorph and morphInfoMap[selectedMorph] and morphInfoMap[selectedMorph].visible then
		selectKaiju(selectedMorph)
		return
	end
	for _, model in ipairs(sortedMorphs) do
		local info = morphInfoMap[model.Name]
		if info and info.visible then
			selectKaiju(model.Name)
			return
		end
	end
end
selectInitialMorph()
task.spawn(function()
	for _ = 1, 60 do
		refreshRemotes()
		if getKaijuDataFunc then fetchKaijuData() end
		if getOwnershipFunc then fetchOwnership() end
		if getGamepassKaijusFunc then
			fetchGamepassKaijus()
			fetchGamepassInfo()
		end
		if getKaijuDataFunc and getOwnershipFunc and getGamepassKaijusFunc and getSelectedKaijuFunc then
			selectInitialMorph()
			break
		end
		task.wait(1)
	end
end)

task.spawn(function()
	for attempt = 1, 3 do
		task.wait(2 * attempt)
		local hasAny = false
		for _ in pairs(ownershipCache) do
			hasAny = true
			break
		end
		if hasAny then break end
		fetchOwnership()
		if currentMorphName then
			local newOwned = isOwned(currentMorphName, currentPrice)
			if newOwned ~= currentOwned then
				currentOwned = newOwned
				if selectTxt then
					if currentOwned then
						selectTxt.Text = "SELECT " .. string.upper(currentKaijuName or "")
					elseif isGamepassKaiju(currentMorphName) then
							if isGamepassOffsale(currentMorphName) then
								selectTxt.Text = "OFFSALE"
							else
								selectTxt.Text = "BUY GAMEPASS"
							end
					else
						selectTxt.Text = formatBuyText(currentPrice, currentRequirement, currentIsCandy)
					end
				end
			end
		end
	end
end)
local levelUpdateRemote = ReplicatedStorage:FindFirstChild("LevelUpdate")
if levelUpdateRemote then
	levelUpdateRemote.OnClientEvent:Connect(function(data)
		if data and data.kaiju then
			local cached = kaijuDataCache[data.kaiju]
			if cached then
				cached.level = data.level


				local pointsPerLevel = (data.kaiju == "MINILLA") and 25 or 5
				local total = math.floor((data.level or 1) / pointsPerLevel)

				cached.availableSkillPoints = math.max(0, total - (cached.usedSkillPoints or 0))
			else
				local pointsPerLevel = (data.kaiju == "MINILLA") and 25 or 5
				local total = math.floor((data.level or 1) / pointsPerLevel)

				kaijuDataCache[data.kaiju] = {
					level = data.level,
					xp = data.xp or 0,
					usedSkillPoints = 0,
					availableSkillPoints = total,
				}
			end
			if data.kaiju == currentMorphName and levelLabel then
				levelLabel.Text = "Level " .. tostring(data.level)
			end
		end
	end)
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(purchasedPlayerId, gamepassId, wasPurchased)
	if wasPurchased and purchasedPlayerId == player.UserId then
		for morphName, gpId in pairs(gamepassKaijusCache) do
			if gpId == gamepassId then
				ownershipCache[morphName] = true
				if morphName == currentMorphName then
					currentOwned = true
					if selectTxt then
						selectTxt.Text = "SELECT " .. string.upper(currentKaijuName or "")
					end
				end
				break
			end
		end
	end
end)