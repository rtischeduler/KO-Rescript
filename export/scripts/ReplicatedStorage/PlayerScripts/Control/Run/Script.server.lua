local runRemote = script.Parent
local runValue = script.Parent.Running

runRemote.OnServerEvent:Connect(function()
	local Value = runValue.Value
	if Value then
		runValue.Value = false
	else
		runValue.Value = true
	end
end)
