local prev
local parts = script.Parent:GetChildren()
for i = 1,#parts do
if ((parts[i].className == "Part") or (parts[i].className == "SpawnLocation") or (parts[i].className == "Seat") or (parts[i].className == "TrussPart") or (parts[i].className == "VehicleSeat")) then
		if (prev ~= nil) then
			local weld = Instance.new("Weld")
			weld.Part0 = prev
			weld.Part1 = parts[i]
			weld.C0 = prev.CFrame:inverse()
			weld.C1 = parts[i].CFrame:inverse()
			weld.Parent = prev
			parts[i].Anchored = false
		end
		prev = parts[i]
	end
end
wait(3)
