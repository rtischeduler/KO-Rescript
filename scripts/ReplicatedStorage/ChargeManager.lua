local ChargeManager = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local isClient = player ~= nil

--[[local siphonEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Siphon")
if not siphonEvent then
	siphonEvent = Instance.new("RemoteEvent")
	siphonEvent.Name = "Siphon"
	siphonEvent.Parent = game:GetService("ReplicatedStorage")
end]]

local MAX_CHARGE = 100
local currentCharge = 100
local isFlying = false

local CHARGE_REQUIREMENTS = {
	Attack1 = 10,
	Attack2 = 30,
	Attack3 = 15,
	Attack4 = 10,
	Roar1 = 0,
	Roar2 = 0,
}

local NAME_MAP = {
	Attack = "Attack1", Attack1Event = "Attack1",
	Beam = "Attack2", Attack2Event = "Attack2",
	Attack3 = "Attack3", Attack3Event = "Attack3",
	Attack4 = "Attack4", Attack4Event = "Attack4",
	Roar1 = "Roar1", Roar1Event = "Roar1",
	Roar2 = "Roar2", Roar2Event = "Roar2",
}

local REVERSE_NAME_MAP = {}
for eventName, canonicalName in pairs(NAME_MAP) do
	REVERSE_NAME_MAP[canonicalName] = REVERSE_NAME_MAP[canonicalName] or {}
	table.insert(REVERSE_NAME_MAP[canonicalName], eventName)
end

local function normalize(name)
	return NAME_MAP[name] or name
end

local function getAttributeCharge(abilityName)
	local character = player.Character
	if not character then return nil end

	local charScripts = character:FindFirstChild("CharacterScripts")
	if not charScripts then return nil end

	local possibleNames = REVERSE_NAME_MAP[abilityName]
	if not possibleNames then return nil end

	for _, eventName in ipairs(possibleNames) do
		local event = charScripts:FindFirstChild(eventName)
		if event and event:IsA("RemoteEvent") then
			local attr = event:GetAttribute("Charge")
			if attr then return attr end
		end
	end

	local animEvents = charScripts:FindFirstChild("AnimEvents")
	if animEvents then
		for _, eventName in ipairs(possibleNames) do
			local event = animEvents:FindFirstChild(eventName)
			if event and event:IsA("RemoteEvent") then
				local attr = event:GetAttribute("Charge")
				if attr then return attr end
			end
		end
	end

	return nil
end

local function getChargeBar()
	local gui = player:FindFirstChild("PlayerGui")
	if not gui then return nil end
	local gameGui = gui:FindFirstChild("GameGui")
	if not gameGui then return nil end
	local mainFrame = gameGui:FindFirstChild("MainFrame")
	if not mainFrame then return nil end
	local interface = mainFrame:FindFirstChild("Interface")
	if not interface then return nil end
	local bars = interface:FindFirstChild("Bars")
	if not bars then return nil end
	return bars:FindFirstChild("ChargeBar")
end

local function getChargeStats()
	local gui = player:FindFirstChild("PlayerGui")
	if not gui then return nil end
	local gameGui = gui:FindFirstChild("GameGui")
	if not gameGui then return nil end
	local mainFrame = gameGui:FindFirstChild("MainFrame")
	if not mainFrame then return nil end
	local interface = mainFrame:FindFirstChild("Interface")
	if not interface then return nil end
	local stats = interface:FindFirstChild("Stats")
	if not stats then return nil end
	return stats:FindFirstChild("Charge")
end

local function updateUI()
	if not isClient then return end
	local chargeBar = getChargeBar()
	if chargeBar then
		local fill = chargeBar:FindFirstChild("Fill")
		local text = chargeBar:FindFirstChild("Text")
		local pct = math.clamp(currentCharge / MAX_CHARGE, 0, 1)
		if fill then
			fill.Size = UDim2.new(pct, 0, 1, 0)
		end
		if text then
			text.Text = "Charge: " .. tostring(math.floor(currentCharge)) .. "/" .. tostring(MAX_CHARGE)
		end
	end

	local chargeStats = getChargeStats()
	if chargeStats then
		local label = chargeStats:FindFirstChild("TextLabel")
		if label then
			label.Text = tostring(math.floor(currentCharge))
		end
	end
end

--[[function ChargeManager.chargeSiphon(chargeAmount)
		print("Siphoning Charge")
		currentCharge = math.min(MAX_CHARGE, currentCharge + chargeAmount)
		updateUI()		
end	

siphonEvent.OnClientEvent:Connect(function(chargeAmount)
	ChargeManager.chargeSiphon(chargeAmount)
	print("Recieved Siphon")
end)]]


function ChargeManager.getCharge()
	return currentCharge
end

function ChargeManager.getMaxCharge()
	return MAX_CHARGE
end

function ChargeManager.getRequiredCharge(abilityName, remoteEvent)
	if remoteEvent and remoteEvent:IsA("RemoteEvent") then
		local attrCharge = remoteEvent:GetAttribute("Charge")
		if typeof(attrCharge) == "number" then
			return attrCharge
		end
	end
	abilityName = normalize(abilityName)
	local attrCharge = getAttributeCharge(abilityName)
	if attrCharge then
		return attrCharge
	end
	return CHARGE_REQUIREMENTS[abilityName] or 0
end

function ChargeManager.canUseCharge(abilityName, remoteEvent)
	local required = ChargeManager.getRequiredCharge(abilityName, remoteEvent)
	return currentCharge >= required
end

function ChargeManager.consumeCharge(abilityName, remoteEvent)
	local amount = ChargeManager.getRequiredCharge(abilityName, remoteEvent)
	if amount > 0 then
		currentCharge = math.max(0, currentCharge - amount)
		updateUI()
	end
end

function ChargeManager.setFlying(flying)
	isFlying = flying
end

function ChargeManager.drainCharge(amount)
	if amount > 0 then
		currentCharge = math.max(0, currentCharge - amount)
		updateUI()
	end
end

function ChargeManager.reset()
	currentCharge = MAX_CHARGE
	isFlying = false
	updateUI()
end

if isClient then
	task.spawn(function()
		while task.wait(0.2) do
			if not isFlying and currentCharge < MAX_CHARGE then
				currentCharge = math.min(currentCharge + 1, MAX_CHARGE)
			end
			updateUI()
		end
	end)

	updateUI()
end

return ChargeManager
