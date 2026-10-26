-- Replaces the Knit startup block at the bottom of ServerHandler. Runs in the Start phase, after every Init is kicked off.
local KnitService = { Name = "Knit" }

function KnitService:Start()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")
	local Knit = require(ReplicatedStorage:WaitForChild("Knit"):WaitForChild("Knit"))
	Knit.AddServices(ServerScriptService:WaitForChild("KnitServices"))
	Knit.Start():andThen(function()
		print("[Knit] Server started successfully")
	end):catch(function(err)
		warn("[Knit] Server failed to start: " .. tostring(err))
	end)
end

return KnitService
