local KnitController = { Name = "Knit" }

function KnitController:Start()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Knit = require(ReplicatedStorage:WaitForChild("Knit"):WaitForChild("Knit"))
	Knit.Start():andThen(function()
		print("[Knit] Client started successfully")
	end):catch(function(err)
		warn("[Knit] Client failed to start:", err)
	end)
end

return KnitController
