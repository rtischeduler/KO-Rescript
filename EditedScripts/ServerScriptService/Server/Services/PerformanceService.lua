local PerformanceService = { Name = "Performance" }

function PerformanceService.isLagging(avgFrameTime, threshold)
	return avgFrameTime > threshold
end

function PerformanceService:Start()
	local RunService = game:GetService("RunService")
	local ServerScriptService = game:GetService("ServerScriptService")
	local cfg = require(script:FindFirstAncestor("Server").Config).Performance
	local total, frames = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		total += dt
		frames += 1
		if total >= cfg.SampleSeconds then
			local avg = total / frames
			total, frames = 0, 0
			ServerScriptService:SetAttribute("ServerFrameTime", avg)
			ServerScriptService:SetAttribute("ServerLagging", PerformanceService.isLagging(avg, cfg.LagFrameTime))
		end
	end)
end

return PerformanceService
