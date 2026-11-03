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
	Sky = "Dark",
	Lighting = {
		Day = {
			Brightness = 1.5, Ambient = Color3.new(0.38, 0.36, 0.4),
			OutdoorAmbient = Color3.new(0.24, 0.22, 0.27),
			ColorShift_Top = Color3.new(1, 0.64, 0.4),
			ColorShift_Bottom = Color3.new(0.15, 0.13, 0.2),
			FogColor = Color3.new(0.43, 0.39, 0.47), FogEnd = 6500,
			Density = 0.32, AtmColor = Color3.new(0.62, 0.57, 0.68), Haze = 2,
			AtmDecay = Color3.new(0.85, 0.5, 0.3),
			Cloud = Color3.new(0.56, 0.52, 0.6),
		},
		Night = {
			Brightness = 1.2, Ambient = Color3.new(0.27, 0.29, 0.41),
			OutdoorAmbient = Color3.new(0.17, 0.19, 0.31),
			ColorShift_Top = Color3.new(0.3, 0.38, 0.62),
			ColorShift_Bottom = Color3.new(0.05, 0.06, 0.1),
			FogColor = Color3.new(0.15, 0.15, 0.25), FogEnd = 3800,
			Density = 0.4, AtmColor = Color3.new(0.14, 0.12, 0.24), Haze = 2.6,
			AtmDecay = Color3.new(0.36, 0.28, 0.4),
			Cloud = Color3.new(0.1, 0.1, 0.16),
		},
		Rain = {
			FogEndMul = 0.55, DensityAdd = 0.1, HazeAdd = 0.7,
			FogColor = Color3.new(0.3, 0.31, 0.38),
			AtmColor = Color3.new(0.36, 0.36, 0.43),
			Cloud = Color3.new(0.13, 0.13, 0.17),
		},
	},
	DayLights = { Buildings = 0.35, Windows = 0.5, Spread = 25 },
	Effects = {
		Exposure = -0.1,
	},
	Weather = { Kind = "Rain", Gap = { 100, 180 }, Duration = { 30, 120 } },
	WindowColors = {
		rgb(255, 120, 20), rgb(255, 120, 20), rgb(255, 120, 20),
		rgb(150, 60, 220), rgb(150, 60, 220), rgb(150, 60, 220),
		rgb(205, 55, 165),
		rgb(110, 230, 60),
	},
	GroundColor = rgb(96, 52, 128),
	RainColor = rgb(165, 95, 235),
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
