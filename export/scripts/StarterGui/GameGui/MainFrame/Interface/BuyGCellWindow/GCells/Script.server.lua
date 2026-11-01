local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local ProductRewards = {
	[3457853836] = 100,
	[3592370811] = 250,
	[3592370643] = 500,
	[3592370416] = 1000,
	[3592369940] = 2500,
	[3584672588] = 5000,
}

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local cash = player:FindFirstChild("leaderstats")
		and player.leaderstats:FindFirstChild("GCells")

	if cash then
		local reward = ProductRewards[receiptInfo.ProductId]

		if reward then
			cash.Value += reward
		end
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end
