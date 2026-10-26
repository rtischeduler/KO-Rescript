local blast = script.Parent
local startSize = 5
local maxSize = 250
local growDuration = 2
local fadeDuration = 2

local function animateBlast()
	blast.Size = Vector3.new(startSize, startSize, startSize)
	blast.Transparency = 0.5

	local startTime = tick()
	while tick() - startTime < growDuration do
		local progress = (tick() - startTime) / growDuration
		local currentSize = startSize + (maxSize - startSize) * progress
		blast.Size = Vector3.new(currentSize, currentSize, currentSize)
		task.wait()
	end

	blast.Size = Vector3.new(maxSize, maxSize, maxSize)

	startTime = tick()
	while tick() - startTime < fadeDuration do
		local progress = (tick() - startTime) / fadeDuration
		blast.Transparency = 0.5 + 0.5 * progress
		task.wait()
	end

	blast.Transparency = 1
end

animateBlast()

wait(15)
blast:Destroy()
