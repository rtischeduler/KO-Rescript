local beamEnd = script.Parent
if not beamEnd or not beamEnd:IsA("Attachment") then return end
local originalParentOV = beamEnd:FindFirstChild("BeamOriginalParent")
local originalParent = originalParentOV and originalParentOV.Value
local duration = beamEnd:GetAttribute("BeamDuration") or 6
local cleanedUp = false
local function cleanup()
	if cleanedUp then return end
	cleanedUp = true
	for _, child in ipairs(beamEnd:GetChildren()) do
		if child:IsA("ParticleEmitter") then
			child.Enabled = false
			child:Clear()
		elseif child:IsA("Light") then
			child.Enabled = false
		end
	end
	beamEnd:SetAttribute("BeamEndOffset", nil)
	beamEnd:SetAttribute("BeamDuration", nil)
	if originalParent and originalParent.Parent then
		pcall(function() beamEnd.Parent = originalParent end)
	else
		pcall(function() beamEnd.Parent = nil end)
	end
	if originalParentOV then
		pcall(function() originalParentOV:Destroy() end)
	end
	script:Destroy()
end
beamEnd.AncestryChanged:Connect(function()
	if cleanedUp then return end
	task.wait(0.1)
	if cleanedUp then return end
	local parent = beamEnd.Parent
	if not parent then
		cleanup()
		return
	end
	if parent:IsA("BasePart") and parent.Name == "BeamHitbox" then
		return
	end
	cleanup()
end)
task.delay(duration + 5, function()
	if cleanedUp then return end
	if beamEnd and beamEnd.Parent then
		local parent = beamEnd.Parent
		if parent:IsA("BasePart") and parent.Name == "BeamHitbox" then
			cleanup()
		end
	end
end)