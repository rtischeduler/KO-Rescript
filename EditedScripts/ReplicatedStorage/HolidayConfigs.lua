local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HolidayConfigs = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

HolidayConfigs.Order = { "Halloween", "Christmas" }

HolidayConfigs.DefaultWeather = { Kind = "Rain", Gap = { 120, 200 }, Duration = { 20, 120 } }

HolidayConfigs.Halloween = {
	Name = "Halloween",
	Months = { 10, 11 },
	ForceNight = true,
	Lighting = {
		Day = {
			Brightness = 1.7, Ambient = Color3.new(0.44, 0.36, 0.58),
			OutdoorAmbient = Color3.new(0.32, 0.25, 0.48),
			ColorShift_Top = Color3.new(0.5, 0.35, 0.78),
			ColorShift_Bottom = Color3.new(0.08, 0.05, 0.14),
			FogColor = Color3.new(0.2, 0.13, 0.32), FogEnd = 5200,
			Density = 0.3, AtmColor = Color3.new(0.24, 0.14, 0.4), Haze = 2.1,
			AtmDecay = Color3.new(0.55, 0.3, 0.6),
			Cloud = Color3.new(0.18, 0.12, 0.28),
		},
		Night = {
			Brightness = 1.7, Ambient = Color3.new(0.44, 0.36, 0.58),
			OutdoorAmbient = Color3.new(0.32, 0.25, 0.48),
			ColorShift_Top = Color3.new(0.5, 0.35, 0.78),
			ColorShift_Bottom = Color3.new(0.08, 0.05, 0.14),
			FogColor = Color3.new(0.2, 0.13, 0.32), FogEnd = 5200,
			Density = 0.3, AtmColor = Color3.new(0.24, 0.14, 0.4), Haze = 2.1,
			AtmDecay = Color3.new(0.55, 0.3, 0.6),
			Cloud = Color3.new(0.18, 0.12, 0.28),
		},
		Rain = {
			FogEndMul = 0.65, DensityAdd = 0.07, HazeAdd = 0.5,
			FogColor = Color3.new(0.24, 0.18, 0.32),
			AtmColor = Color3.new(0.3, 0.22, 0.4),
			Cloud = Color3.new(0.14, 0.1, 0.2),
		},
	},
	DayLights = { Buildings = 0.35, Windows = 0.5, Spread = 25 },
	Effects = {
		Exposure = 0.05,
	},
	Weather = { Kind = "Rain", Gap = { 100, 180 }, Duration = { 30, 120 } },
	WindowColors = {
		rgb(255, 150, 50), rgb(255, 150, 50), rgb(255, 150, 50),
		rgb(255, 175, 80), rgb(255, 175, 80),
		rgb(240, 160, 60),
		rgb(255, 200, 120),
	},
	GroundColor = rgb(105, 95, 56),
}

HolidayConfigs.Christmas = {
	Name = "Christmas",
	Placeholder = true,
	Months = { 12, 1 },
	Lighting = {
		Day = {
			Brightness = 2, Ambient = Color3.new(0.55, 0.58, 0.65),
			OutdoorAmbient = Color3.new(0.4, 0.45, 0.55),
			ColorShift_Top = Color3.new(0.85, 0.9, 1),
			ColorShift_Bottom = Color3.new(0.2, 0.22, 0.3),
			FogColor = Color3.new(0.8, 0.85, 0.92), FogEnd = 4500,
			Density = 0.4, AtmColor = Color3.new(0.85, 0.9, 0.97), Haze = 2.4,
			Cloud = Color3.new(0.95, 0.97, 1),
		},
		Night = {
			Brightness = 1.2, Ambient = Color3.new(0.3, 0.36, 0.5),
			OutdoorAmbient = Color3.new(0.2, 0.26, 0.4),
			ColorShift_Top = Color3.new(0.2, 0.28, 0.45),
			ColorShift_Bottom = Color3.new(0.08, 0.1, 0.18),
			FogColor = Color3.new(0.25, 0.3, 0.42), FogEnd = 3000,
			Density = 0.42, AtmColor = Color3.new(0.18, 0.24, 0.38), Haze = 3,
			Cloud = Color3.new(0.3, 0.35, 0.45),
		},
		Snow = {
			FogEndMul = 0.5, DensityAdd = 0.12, HazeAdd = 0.8,
			FogColor = Color3.new(0.7, 0.75, 0.82),
			AtmColor = Color3.new(0.75, 0.8, 0.88),
			Cloud = Color3.new(0.6, 0.64, 0.7),
		},
	},
	Weather = { Kind = "Snow", Gap = { 60, 120 }, Duration = { 60, 180 } },
	WindowColors = {
		rgb(220, 40, 40), rgb(50, 190, 80), rgb(255, 235, 190),
	},
	GroundColor = nil,
}

function HolidayConfigs.getActive(month)
	local override = ReplicatedStorage:GetAttribute("HolidayOverride")
	if override == "None" then return nil end
	if override and table.find(HolidayConfigs.Order, override) then
		return HolidayConfigs[override]
	end
	month = month or os.date("!*t").month
	for _, key in HolidayConfigs.Order do
		local config = HolidayConfigs[key]
		if table.find(config.Months, month) then return config end
	end
	return nil
end

function HolidayConfigs.getWeather()
	local holiday = HolidayConfigs.getActive()
	return holiday and holiday.Weather or HolidayConfigs.DefaultWeather
end

return HolidayConfigs