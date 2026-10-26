local frame = script.Parent
local scrollWindow = frame:FindFirstChild("ScrollWindow")
local statsWindow = frame:FindFirstChild("StatsWindow")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local getOwnershipFunc = ReplicatedStorage:WaitForChild("GetKaijuOwnership")
local buyKaijuEvent = ReplicatedStorage:WaitForChild("BuyKaiju")
local KaijusUnused = Lighting:WaitForChild("KaijusUnused")
local Morphs = ReplicatedStorage:FindFirstChild("MorphSupplies")
if Morphs then Morphs = Morphs:FindFirstChild("Morphs") end

local imageDisplay = statsWindow and statsWindow:FindFirstChild("Image")
local charNameLabel = statsWindow and statsWindow:FindFirstChild("CharName")
local charVal = statsWindow and statsWindow:FindFirstChild("Character")
local playButton = statsWindow and statsWindow:FindFirstChild("Play")
local buyButton = statsWindow and statsWindow:FindFirstChild("Buy")
local buyGPButton = statsWindow and statsWindow:FindFirstChild("BuyGP")
local cpLabel = imageDisplay and imageDisplay:FindFirstChild("CP")

local currentKaiju = nil
local currentPrice = 0
local selectionId = 0
local isProcessingSelection = false

local gamepassKaijus = {
	["Burning"] = 1891042639,
}

local nameMapping = {
	["Godzilla2014"] = "GODZILLA 2014",
	["TitanusGhidorah"] = "TITANUS GHIDORAH",
	["Godzilla2019"] = "TITANUS GOJIRA",
	["F16C"] = "F16C [FREE]",
	["Mosura"] = "TITANUS MOSURA",
	["Behemoth"] = "TITANUS BEHEMOTH",
	["Anguirus"] = "ANGUIRUS [FREE]",
	["Biollante"] = "BIOLLANTE",
	["Burning"] = "BURNING GODZILLA",
	["FinalWars"] = "FINAL WARS GODZILLA",
	["Heisei"] = "HEISEI GODZILLA",
	["KamataKun"] = "SHIN FORM 2 [FREE]",
	["KingGhidorah"] = "KING GHIDORAH",
	["MaleMuto"] = "MALE MUTO",
	["Mothra"] = "MOTHRA",
	["Rodan"] = "TITANUS RODAN",
	["Shin"] = "SHIN GOJIRA",
	["ShinagawaKun"] = "SHIN FORM 3",
	["Tank"] = "MILITARY TANK [FREE]",
	["Human"] = "CIVILIAN [FREE]",
	["Godzilla1954"] = "GOJIRA [FREE]",
}

local function getKaijuPrice(kaijuName)

	local kaiju = KaijusUnused:FindFirstChild(kaijuName)
	if kaiju then
		local stats = kaiju:FindFirstChild("Stats")
		if stats then
			local price = stats:FindFirstChild("Price")
			if price and price.Value > 0 then
				return price.Value
			end
		end
	end

	local morphName = nameMapping[kaijuName]
	if morphName and Morphs then
		local morph = Morphs:FindFirstChild(morphName)
		if morph then
			local stats = morph:FindFirstChild("Stats")
			if stats then
				local price = stats:FindFirstChild("Price")
				if price then
					return price.Value
				end
			end
		end
	end

	return 3500
end

local function ownsGamepass(gamepassId)
	local success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)
	if success then
		return result
	else
		warn("Failed to check gamepass ownership: " .. tostring(result))
		return false
	end
end

local function updateButtons(kaijuName, price, expectedSelectionId)
	local gamepassId = gamepassKaijus[kaijuName]
	local isGamepassKaiju = gamepassId ~= nil
	local owned = false

	if isGamepassKaiju then
		owned = ownsGamepass(gamepassId)
	else
		owned = getOwnershipFunc:InvokeServer(kaijuName)
	end

	if expectedSelectionId ~= selectionId then
		return
	end

	isProcessingSelection = false
	script.Parent.StatsWindow.Loading.Visible = false

	if isGamepassKaiju then

		if playButton then
			playButton.Visible = owned
			playButton.Active = owned
		end
		if buyButton then
			buyButton.Visible = false
		end
		if buyGPButton then
			buyGPButton.Visible = not owned
			if not owned then
				buyGPButton.Text = "gpbuy"
			end
		end
		if cpLabel then
			if owned then
				cpLabel.Text = "OWNED"
			else
				cpLabel.Text = "Gamepass Required"
			end
		end
		script.Parent.StatsWindow.Play.Visible = owned
	else

		if playButton then
			playButton.Visible = owned
			if owned then
				playButton.Active = true
			else
				playButton.Active = false
			end
		end

		if buyButton then
			buyButton.Visible = not owned
			if not owned then
				buyButton.Text = "Buy (" .. price .. " GCells)"
				script.Parent.StatsWindow.Play.Visible = false
			end
		end

		if buyGPButton then
			buyGPButton.Visible = false
		end

		if cpLabel then
			if owned then
				cpLabel.Text = "OWNED"
				script.Parent.StatsWindow.Play.Visible = true
			else
				cpLabel.Text = "Price: " .. price .. " GCells"
				script.Parent.StatsWindow.Play.Visible = false
			end
		end
	end
end

local function onCharacterSelected(imageButton)

	if isProcessingSelection then
		return
	end

	selectionId = selectionId + 1
	local mySelectionId = selectionId

	script.Parent.StatsWindow.Play.Visible = false
	script.Parent.StatsWindow.Play.Active = false
	script.Parent.StatsWindow.Loading.Visible = true
	isProcessingSelection = true

	local nameTag = imageButton:FindFirstChild("NameTag")

	local imageId = imageButton.Image
	local characterName = imageButton.Name
	local displayName = nameTag and nameTag.Text or characterName

	currentKaiju = characterName
	currentPrice = getKaijuPrice(characterName)

	local Kaiju = KaijusUnused:FindFirstChild(characterName)
	if Kaiju then
		local stats = Kaiju:FindFirstChild("Stats")
		if stats then
			local dmg = stats:FindFirstChild("DMG1")
			local hp = stats:FindFirstChild("HP")
			local defense = stats:FindFirstChild("Defense")
			local speed = stats:FindFirstChild("WS")

			if dmg and script.Parent.StatsWindow.DMG then
				script.Parent.StatsWindow.DMG.TextLabel.Text = tostring(dmg.Value)
			end
			if hp and script.Parent.StatsWindow.HP then
				script.Parent.StatsWindow.HP.TextLabel.Text = tostring(hp.Value)
			end
			if defense and script.Parent.StatsWindow.Defense then
				script.Parent.StatsWindow.Defense.TextLabel.Text = tostring(defense.Value)
			end
			if speed and script.Parent.StatsWindow.Speed then
				script.Parent.StatsWindow.Speed.TextLabel.Text = tostring(speed.Value)
			end
		end
	end

	if statsWindow then
		statsWindow.Visible = true
	end

	if imageDisplay then
		imageDisplay.Image = imageId
	end

	if charNameLabel then
		charNameLabel.Text = displayName
	end

	if charVal then
		charVal.Value = characterName
	end

	updateButtons(characterName, currentPrice, mySelectionId)
end

if buyButton then
	buyButton.MouseButton1Click:Connect(function()
		if not currentKaiju then return end

		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
			if gcells and gcells.Value >= currentPrice then

				buyKaijuEvent:FireServer(currentKaiju)
			else

				buyButton.Text = "Not enough!"
				task.wait(1)
				buyButton.Text = "Buy (" .. currentPrice .. " GCells)"
			end
		end
	end)
end

if buyGPButton then
	buyGPButton.MouseButton1Click:Connect(function()
		if not currentKaiju then return end
		local gamepassId = gamepassKaijus[currentKaiju]
		if gamepassId and gamepassId > 0 then
			MarketplaceService:PromptGamePassPurchase(player, gamepassId)
		end
	end)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(purchasingPlayer, gamepassId, wasPurchased)
	if purchasingPlayer == player and wasPurchased then

		local currentGamepassId = gamepassKaijus[currentKaiju]
		if currentGamepassId and gamepassId == currentGamepassId then

			selectionId = selectionId + 1
			updateButtons(currentKaiju, 0, selectionId)
		end
	end
end)

buyKaijuEvent.OnClientEvent:Connect(function(kaijuName, success, message)
	if success then

		selectionId = selectionId + 1
		updateButtons(kaijuName, 0, selectionId)

		local gcellsLabel = frame:FindFirstChild("GCells")
		if gcellsLabel then
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local gcells = leaderstats:FindFirstChild("GCells") or leaderstats:FindFirstChild("gcells")
				if gcells then
					gcellsLabel.Text = tostring(gcells.Value) .. " GCells"
				end
			end
		end
	else

		if buyButton then
			buyButton.Text = message or "Error"
			task.wait(1)
			buyButton.Text = "Buy (" .. currentPrice .. " GCells)"
		end
	end
end)

if scrollWindow then
	for _, child in scrollWindow:GetChildren() do
		if child:IsA("ImageButton") then
			child.MouseButton1Click:Connect(function()
				onCharacterSelected(child)
			end)
		end
	end
end
