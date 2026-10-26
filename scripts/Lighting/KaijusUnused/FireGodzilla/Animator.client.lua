local char = script.Parent
local currentAnim = "Idle"
local humanoid = char:WaitForChild("Humanoid")
local animations = char:WaitForChild("Animations")

Idle = humanoid:LoadAnimation(animations.Idle)
Walk = humanoid:LoadAnimation(animations.Walk)

local function stopAnimations()
	for i,v in pairs(humanoid:GetPlayingAnimationTracks()) do
		v:Stop()
	end
end

function charMoving(speed)

	if speed > 1 and currentAnim ~= "Walk" then
		currentAnim = "Walk"
		stopAnimations()
		Walk:Play()

	elseif speed < 2 and currentAnim ~= "Idle" then
		currentAnim = "Idle"
		stopAnimations()
		Idle:Play()
	end
end

Idle:Play()
humanoid.Running:Connect(charMoving)
