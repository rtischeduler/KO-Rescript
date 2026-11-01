local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage:WaitForChild("Knit"):WaitForChild("Knit"))
local BeamSystem = require(ReplicatedStorage:FindFirstChild("BeamSystem"))



local BeamService = Knit.CreateService {
	Name = "BeamService",
	Client = {
		BeamAim = Knit.CreateUnreliableSignal(),
		BeamStarted = Knit.CreateSignal(),
		BeamEnded = Knit.CreateSignal(),
	},
}

function BeamService:KnitInit()
	
	BeamSystem.SetComm(self.Client)

	
	self.Client.BeamAim:Connect(function(player, targetPosition, isShiftLock)
		if typeof(targetPosition) == "Vector3" then
			BeamSystem.SetAim(player, targetPosition, isShiftLock)
		end
	end)
end

return BeamService