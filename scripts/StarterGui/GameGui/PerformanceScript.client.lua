local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then
	return
end

local gameGui = playerGui:FindFirstChild("GameGui")
if not gameGui then
	return
end

local preformance = gameGui:FindFirstChild("MainFrame") and gameGui.MainFrame:FindFirstChild("Interface") and gameGui.MainFrame.Interface:FindFirstChild("Preformance")
if not preformance then
	return
end

local fpsLabel = preformance:FindFirstChild("FPS")
local pingLabel = preformance:FindFirstChild("Ping")
local regionLabel = preformance:FindFirstChild("Region")
local serverAgeLabel = preformance:FindFirstChild("ServerAge")


local frameCount = 0
local lastFpsUpdate = os.clock()
local currentFps = 0

RunService.RenderStepped:Connect(function()
	frameCount += 1
	local now = os.clock()
	if now - lastFpsUpdate >= 1 then
		currentFps = math.floor(frameCount / (now - lastFpsUpdate))
		frameCount = 0
		lastFpsUpdate = now
	end
end)


local perfRemote = ReplicatedStorage:FindFirstChild("PerformanceRemote")
if not perfRemote then
	perfRemote = ReplicatedStorage:WaitForChild("PerformanceRemote", 15)
end

if not perfRemote then
	
	while task.wait(0.5) do
		if fpsLabel then
			fpsLabel.Text = "FPS: " .. currentFps
		end
	end
	return
end

local cachedRegion = nil

local function formatServerAge(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)
	if hours > 0 then
		return string.format("Server Age: %dh %dm", hours, minutes)
	elseif minutes > 0 then
		return string.format("Server Age: %dm %ds", minutes, secs)
	else
		return string.format("Server Age: %ds", secs)
	end
end


while task.wait(1) do
	
	if fpsLabel then
		fpsLabel.Text = "FPS: " .. currentFps
	end

	
	local startTime = os.clock()
	local success, result = pcall(function()
		return perfRemote:InvokeServer()
	end)
	local pingMs = math.floor((os.clock() - startTime) * 1000)

	if success and result then
		if pingLabel then
			pingLabel.Text = "Ping: " .. pingMs .. " ms"
		end

		if result.region and result.region ~= "" then
			cachedRegion = result.region
		end
		if regionLabel and cachedRegion then
			regionLabel.Text = "Region: " .. cachedRegion
		end

		if serverAgeLabel and result.serverAge then
			serverAgeLabel.Text = formatServerAge(result.serverAge)
		end
	elseif pingLabel then
		pingLabel.Text = "Ping: " .. pingMs .. " ms"
	end
end