local GraphicsQuality = {}

local ORDER = { "High", "Medium", "Low", "Lowest" }

local TIERS = {
	High = {
		Shadows = true, LightShadows = true, Specular = 1, Atmosphere = 1, Decoration = true,
		ParticleScale = 1, OceanRate = nil, WaterFx = 1, QualityLevel = nil,
		Effects = { BloomEffect = true, SunRaysEffect = true, DepthOfFieldEffect = true },
	},
	Medium = {
		Shadows = true, LightShadows = true, Specular = 0.6, Atmosphere = 0.8, Decoration = true,
		ParticleScale = 0.6, OceanRate = 20, WaterFx = 0.6, QualityLevel = 7,
		Effects = { BloomEffect = true, SunRaysEffect = false, DepthOfFieldEffect = false },
	},
	Low = {
		Shadows = false, LightShadows = false, Specular = 0.2, Atmosphere = 0.5, Decoration = false,
		ParticleScale = 0.3, OceanRate = 10, WaterFx = 0.3, QualityLevel = 4,
		Effects = { BloomEffect = false, SunRaysEffect = false, DepthOfFieldEffect = false },
	},
	Lowest = {
		Shadows = false, LightShadows = false, Specular = 0, Atmosphere = 0, Decoration = false,
		ParticleScale = 0.1, OceanRate = 0, WaterFx = 0, QualityLevel = 1,
		Effects = { BloomEffect = false, SunRaysEffect = false, DepthOfFieldEffect = false },
	},
}

local current = "High"
local listeners = {}

function GraphicsQuality.Order()
	return ORDER
end

function GraphicsQuality.Get()
	return current
end

function GraphicsQuality.Index()
	return table.find(ORDER, current)
end

function GraphicsQuality.Settings()
	return TIERS[current]
end

function GraphicsQuality.Next()
	return ORDER[GraphicsQuality.Index() + 1]
end

function GraphicsQuality.Set(name, source)
	if not TIERS[name] then
		return false
	end
	if name == current then
		return true
	end
	current = name
	for _, fn in ipairs(listeners) do
		task.spawn(fn, name, source)
	end
	return true
end

function GraphicsQuality.OnChanged(fn)
	table.insert(listeners, fn)
end

return GraphicsQuality
