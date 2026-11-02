local sound = script.Parent

local playlist = {
	85064855756444,
	91833688670813,
	138218992610096,
	111847399366175,
	138218992610096,
	85064855756444,
}

local LOAD_TIMEOUT = 8
local ROUND_RETRY_DELAY = 20
local END_GRACE = 3

sound.Looped = false

local index = math.random(1, #playlist)

local function loadTrack(id)
	local target = "rbxassetid://" .. id
	if sound.SoundId ~= target then
		sound.SoundId = target
	end
	local startTime = os.clock()
	while not sound.IsLoaded and os.clock() - startTime < LOAD_TIMEOUT do
		task.wait(0.1)
	end
	return sound.IsLoaded and sound.TimeLength > 0
end

local function playTrack()
	local finished = false
	local connection = sound.Ended:Connect(function()
		finished = true
	end)

	sound.TimePosition = 0
	sound:Play()

	local playedSeconds = 0
	local expected = sound.TimeLength / math.max(sound.PlaybackSpeed, 0.05)
	while not finished and sound.Parent do
		task.wait(0.5)
		if sound.IsPlaying then
			playedSeconds += 0.5
			if playedSeconds > expected + END_GRACE then
				break
			end
		end
	end

	connection:Disconnect()
end

local failures = 0

while sound.Parent do
	index = index % #playlist + 1
	if loadTrack(playlist[index]) then
		failures = 0
		playTrack()
	else
		failures += 1
		if failures >= #playlist then
			failures = 0
			task.wait(ROUND_RETRY_DELAY)
		end
	end
end