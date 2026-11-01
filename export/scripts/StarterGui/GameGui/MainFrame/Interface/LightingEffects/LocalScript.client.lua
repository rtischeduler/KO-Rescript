local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local GamePassId = 1819433033

local textbutton = script.Parent
local Menu = script.Parent.Parent.LightingFX
local player = Players.LocalPlayer

local function checkGamepassAndShow()
	local hasPass = false

	local success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GamePassId)
	end)

	if success and result then
		hasPass = true
	end

	if hasPass then

		script.Parent.Parent.Parent.Parent.Button:Play()
		if Menu.Visible == true then
			Menu.Visible = false
		else
			Menu.Visible = true
		end
	else

		MarketplaceService:PromptGamePassPurchase(player, GamePassId)
	end
end

textbutton.MouseButton1Click:Connect(checkGamepassAndShow)
