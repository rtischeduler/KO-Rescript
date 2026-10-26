local sound = script.Parent

local playlist = {
	139211069363591,
	71211209896315,
	131975572063582,
	93706949444055,
	99921814103955,
	108755930190420,
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
