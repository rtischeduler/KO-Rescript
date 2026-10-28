
local SecurityPolicy = {}

local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ownershipStore
do
    local ok, store = pcall(function()
        return DataStoreService:GetDataStore("Ownership")
    end)
    if ok then
        ownershipStore = store
    else
        warn("[SecurityPolicy] Ownership datastore unavailable: " .. tostring(store))
    end
end
local ownershipCache = {}

function SecurityPolicy.ClearOwnershipCache(player)
	if player then
		ownershipCache[player.UserId] = nil
	end
end

task.spawn(function()
	local buyEvent = ReplicatedStorage:WaitForChild("BuyKaiju", 30)
	if buyEvent and buyEvent:IsA("RemoteEvent") then
		buyEvent.OnServerEvent:Connect(function(player, kaijuName)
			ownershipCache[player.UserId] = nil
		end)
	end
end)

local GamepassWhitelist = {
	[274893778] = true
}

local gamepassKaijus = {
	["BURNING GODZILLA"] = 1891042639,
	["THERMONUCLEAR GODZILLA"] = 1818653788,
	["VOLCANIC BIOLLANTE"] = 1893256558,
	["FROSTBITE GODZILLA"] = 1822212269,
	["MINILLA"] = 1928197563,
}

local FREE_MORPHS = {
    ["GOJIRA [FREE]"] = true,
    ["SHIN FORM 2 [FREE]"] = true,
    ["ANGUIRUS [FREE]"] = true,
    ["MILITARY TANK [FREE]"] = true,
    ["F16C [FREE]"] = true,
    ["CIVILIAN [FREE]"] = true,
}

local legacyNames = {
	Godzilla2014 = "GODZILLA 2014",
	TitanusGhidorah = "TITANUS GHIDORAH",
	Godzilla2019 = "TITANUS GOJIRA",
	F16C = "F16C [FREE]",
	Mosura = "TITANUS MOSURA",
	Behemoth = "TITANUS BEHEMOTH",
	Gigan = "GIGAN",
	Anguirus = "ANGUIRUS [FREE]",
	Biollante = "BIOLLANTE",
	Burning = "BURNING GODZILLA",
	FinalWars = "FINAL WARS GODZILLA",
	Heisei = "HEISEI GODZILLA",
	KamataKun = "SHIN FORM 2 [FREE]",
	KingGhidorah = "KING GHIDORAH",
	MaleMuto = "MALE MUTO",
	Mothra = "MOTHRA",
	Rodan = "TITANUS RODAN",
	Shin = "SHIN GOJIRA",
	ShinagawaKun = "SHIN FORM 3",
	Tank = "MILITARY TANK [FREE]",
	Human = "CIVILIAN [FREE]",
	Godzilla1954 = "GOJIRA [FREE]",
	Kiryu = "KIRYU",
	["Mecha King Ghidorah"] = "MECHA KING GHIDORAH",
}

local function getMorphFolder()
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local supplies = replicatedStorage:FindFirstChild("MorphSupplies")
	return supplies and supplies:FindFirstChild("Morphs")
end

local function getPrice(model)
	local stats = model and model:FindFirstChild("Stats")
	local price = stats and stats:FindFirstChild("Price")
	if not price then
		return nil
	end
	return tonumber(price.Value)
end

local function loadOwnership(player)
	local cached = ownershipCache[player.UserId]
	if cached ~= nil then
		return cached
	end

    if not ownershipStore then return nil end
	local success, data = pcall(function()
		return ownershipStore:GetAsync(tostring(player.UserId))
	end)
	if not success or type(data) ~= "table" then
		return nil
	end

	ownershipCache[player.UserId] = data
	return data
end

local function dataOwns(data, morphName)
	if type(data) ~= "table" then
		return false
	end
	if data[morphName] then
		return true
	end
	for legacyName, mappedName in pairs(legacyNames) do
		if mappedName == morphName and data[legacyName] then
			return true
		end
	end
	for _, value in ipairs(data) do
		if value == morphName or legacyNames[value] == morphName then
			return true
		end
	end
	return false
end

local function ownsGamepass(player, morphName)
	
	if GamepassWhitelist[player.UserId] then
		return true
	end
	
	local gamepassId = gamepassKaijus[morphName]
	if not gamepassId then
		return false
	end
	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)
	return success and owns == true
end

function SecurityPolicy.CanUseMorph(player, selectedCreature)
	if not player or player.Parent ~= Players then
		return false
	end
	if typeof(selectedCreature) ~= "Instance" or not selectedCreature:IsA("Model") then
		return false
	end
	
	if GamepassWhitelist[player.UserId] then
		return true
	end

	local morphFolder = getMorphFolder()
	if not morphFolder or not selectedCreature:IsDescendantOf(morphFolder) then
		return false
	end

	local morphName = selectedCreature.Name
	local price = getPrice(selectedCreature)
	if price == nil then
    return FREE_MORPHS[morphName] == true
	end
	if price <= 0 then
		return true
	end
	if ownsGamepass(player, morphName) then
		return true
	end

	if type(_G.KUNOwnsKaiju) == "function" then
		return _G.KUNOwnsKaiju(player, morphName)
	end

	local data = loadOwnership(player)
	return dataOwns(data, morphName)
end

Players.PlayerRemoving:Connect(function(player)
	ownershipCache[player.UserId] = nil
end)

return SecurityPolicy
