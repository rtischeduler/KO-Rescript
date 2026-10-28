local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CandyConfig = {}

CandyConfig.Months = { 10, 11 }
CandyConfig.HealthStep = 1000
CandyConfig.CandyPerStep = 5
CandyConfig.FolderPrefix = "halloween"
CandyConfig.Color = Color3.fromRGB(255, 140, 0)

function CandyConfig.isSeason(month)
	local override = ReplicatedStorage:GetAttribute("HolidayOverride")
	if override == "None" then
		return false
	end
	if override == "Halloween" then
		return true
	end
	month = month or os.date("!*t").month
	return table.find(CandyConfig.Months, month) ~= nil
end

function CandyConfig.candyForHealth(maxHealth)
	maxHealth = tonumber(maxHealth) or 0
	if maxHealth <= 0 then
		return 0
	end
	return math.floor(maxHealth / CandyConfig.HealthStep) * CandyConfig.CandyPerStep
end

function CandyConfig.isCandyFolderName(name)
	return string.lower(string.sub(name, 1, #CandyConfig.FolderPrefix)) == CandyConfig.FolderPrefix
end

function CandyConfig.isCandyMorph(model)
	local parent = model.Parent
	while parent and parent.Name ~= "Morphs" do
		if CandyConfig.isCandyFolderName(parent.Name) then
			return true
		end
		parent = parent.Parent
	end
	return false
end

return CandyConfig
