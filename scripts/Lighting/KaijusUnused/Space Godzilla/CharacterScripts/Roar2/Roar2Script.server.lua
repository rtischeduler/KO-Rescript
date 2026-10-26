local roarEvent = script.Parent
local characterScripts = roarEvent.Parent
local soundsFolder = characterScripts:FindFirstChild("Sounds")
local animationsFolder = characterScripts.Parent:FindFirstChild("Animations")

roarEvent.OnServerEvent:Connect(function(player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local debounce = characterScripts:FindFirstChild("Debounce")
	if not debounce or debounce.Value then return end

	debounce.Value = true

	if animationsFolder then
		local roarAnim = animationsFolder:FindFirstChild("Roar2")
		if roarAnim then
			local animator = humanoid:FindFirstChild("Animator")
			if animator then
				local track = animator:LoadAnimation(roarAnim)
				track:Play()
			end
		end
	end

	local soundLength = 0
	if soundsFolder then
		local roarSound = soundsFolder:FindFirstChild("Roar2")
		if roarSound then
			local soundClone = roarSound:Clone()
			soundClone.Parent = character:FindFirstChild("Head") or character:FindFirstChild("Torso") or character
			soundClone:Play()
			soundLength = soundClone.TimeLength
			task.wait(soundLength)
			soundClone:Destroy()
		end
	end

	debounce.Value = false
end)
