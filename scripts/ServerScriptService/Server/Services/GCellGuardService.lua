local GCellGuardService = { Name = "GCellGuard" }

function GCellGuardService.isIncreaseAllowed(delta, allowed, tolerance)
	return allowed + tolerance >= delta
end

function GCellGuardService:Init()
	local framework = script:FindFirstAncestor("Server")
	local PlayerHooks = require(framework.Core.PlayerHooks)
	local Logger = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Logger"))
	local cfg = require(framework.Config).GCellGuard
	local log = Logger.new("GCellGuard")

	local watchedNames = {}
	for _, name in ipairs(cfg.ValueNames) do
		watchedNames[name] = true
	end

	local pendingAllowances = setmetatable({}, { __mode = "k" })
	local hookedValues = setmetatable({}, { __mode = "k" })

	_G.GCellGuardAllow = function(value, amount)
		if typeof(value) ~= "Instance" or not value:IsA("IntValue") then
			return
		end
		local numericAmount = tonumber(amount)
		if not numericAmount or numericAmount <= 0 then
			return
		end
		pendingAllowances[value] = (pendingAllowances[value] or 0) + numericAmount
		task.delay(cfg.AllowanceTtl, function()
			pendingAllowances[value] = nil
		end)
	end

	local function hookValue(value)
		if not value:IsA("IntValue") or not watchedNames[value.Name] then
			return
		end
		if hookedValues[value] then
			return
		end
		hookedValues[value] = true

		local state = { ready = false, repairing = false, last = value.Value }

		task.delay(cfg.ReadyDelay, function()
			if value.Parent then
				state.last = value.Value
				state.ready = true
			end
		end)

		value:GetPropertyChangedSignal("Value"):Connect(function()
			local current = value.Value
			if state.repairing or not state.ready then
				state.last = current
				return
			end

			local previous = state.last or current
			if current > previous then
				local delta = current - previous
				local allowed = pendingAllowances[value] or 0
				pendingAllowances[value] = nil
				if not GCellGuardService.isIncreaseAllowed(delta, allowed, cfg.Tolerance) then
					state.repairing = true
					value.Value = previous
					state.repairing = false
					state.last = previous
					log:warn("Rejected unauthorized GCells increase for " .. value:GetFullName())
					return
				end
			else
				pendingAllowances[value] = nil
			end
			state.last = current
		end)
	end

	local function hookLeaderstats(leaderstats)
		for _, child in ipairs(leaderstats:GetChildren()) do
			hookValue(child)
		end
		leaderstats.ChildAdded:Connect(function(child)
			task.defer(hookValue, child)
		end)
	end

	PlayerHooks.OnPlayer(function(player)
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			hookLeaderstats(leaderstats)
		end
		player.ChildAdded:Connect(function(child)
			if child.Name == "leaderstats" and child:IsA("Folder") then
				hookLeaderstats(child)
			end
		end)
	end)

end

return GCellGuardService
