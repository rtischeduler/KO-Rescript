local sound = script.Parent

local playlist = {
	85064855756444,
	91833688670813,
	138218992610096,
	111847399366175,
	138218992610096,
	85064855756444,
}

sound.Looped = false

local currentIndex = math.random(1, #playlist)
local failedAttempts = 0
local maxFailedAttempts = #playlist * 2

local function playNext()
	currentIndex = currentIndex + 1
	if currentIndex > #playlist then
		currentIndex = 1
	end

	sound.SoundId = "rbxassetid://" .. playlist[currentIndex]

	local startTime = tick()
	local timeout = 5

	while not sound.IsLoaded and (tick() - startTime) < timeout do
		task.wait(0.1)
	end

	if not sound.IsLoaded then

		failedAttempts = failedAttempts + 1
		if failedAttempts >= maxFailedAttempts then

			return
		end

		playNext()
		return
	end

	failedAttempts = 0

	sound:Play()
end

playNext()

sound.Ended:Connect(playNext)
