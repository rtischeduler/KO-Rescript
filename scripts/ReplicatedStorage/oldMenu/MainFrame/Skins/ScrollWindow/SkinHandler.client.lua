local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local scrollWindow = script.Parent
local skinsFrame = scrollWindow.Parent
local statsWindow = skinsFrame:WaitForChild("StatsWindow")

local charName = statsWindow:WaitForChild("CharName")
local imageLabel = statsWindow:WaitForChild("Image")
local characterValue = statsWindow:WaitForChild("Character")
local playButton = statsWindow:WaitForChild("Play")
local buyGPButton = statsWindow:WaitForChild("BuyGP")

local currentGamepassId = 0
local currentSkinName = ""

local function ownsGamepass(gamepassId)
    if gamepassId == 0 then
        return true
    end

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

local function promptPurchase(gamepassId)
    if gamepassId > 0 then
        MarketplaceService:PromptGamePassPurchase(player, gamepassId)
    end
end

local function selectSkin(imageButton)

    local imageId = imageButton.Image
    local nameTag = imageButton:FindFirstChild("NameTag")
	local skinName = nameTag.Text

    local gamepassIdValue = imageButton:FindFirstChild("GamepassId")
    local gamepassId = gamepassIdValue and gamepassIdValue.Value or 0

    currentGamepassId = gamepassId
    currentSkinName = imageButton.Name

    charName.Text = skinName
    imageLabel.Image = imageId
    characterValue.Value = imageButton.Name

    local ownsSkin = ownsGamepass(gamepassId)

    if ownsSkin then

        playButton.Visible = true
        buyGPButton.Visible = false
    else

        playButton.Visible = false
        buyGPButton.Visible = true
    end

    statsWindow.Visible = true
end

local function setupButton(button)
    if button:IsA("ImageButton") then
        button.MouseButton1Click:Connect(function()
            selectSkin(button)
        end)
    end
end

for _, child in ipairs(scrollWindow:GetChildren()) do
    setupButton(child)
end

scrollWindow.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("ImageButton") then
        setupButton(descendant)
    end
end)

buyGPButton.MouseButton1Click:Connect(function()
    if currentGamepassId > 0 then
        promptPurchase(currentGamepassId)
    end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(purchasingPlayer, gamepassId, wasPurchased)
    if purchasingPlayer == player and wasPurchased then

        if gamepassId == currentGamepassId then

            playButton.Visible = true
            buyGPButton.Visible = false
        end
    end
end)
