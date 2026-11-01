local MarketplaceService = game:GetService("MarketplaceService")
local Player = game.Players.LocalPlayer

local ProductId = script.Parent.id.Value

script.Parent.MouseButton1Click:Connect(function()
	MarketplaceService:PromptProductPurchase(Player, ProductId)
end)
