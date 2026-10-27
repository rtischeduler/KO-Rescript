local CollectionService = game:GetService("CollectionService")
local DRY_RUN = true

local converted, roars = 0, 0
for _, inst in ipairs(game:GetDescendants()) do
	if inst:IsA("Script") and inst.Name == "DPS" and inst.Parent and inst.Parent:IsA("BasePart") then
		local src, part = inst.Source, inst.Parent
		local attrs = {
			Damage = tonumber(src:match("h%.Health%s*%-%s*%(?%s*([%d%.]+)")) or 0.9,
			GCellRate = tonumber(src:match("gcells%.Value%s*%+%s*([%d%.]+)")) or 0.2,
			Cooldown = src:find("debounce", 1, true) and 0.5 or 0,
			DamageMultiplier = tonumber(src:match("VOLCANIC_DAMAGE_MULTIPLIER%s*=%s*([%d%.]+)")) or 1,
			LevelScaled = src:find("DamageMultiplierPerLevel", 1, true) ~= nil,
			RequireBlastActive = src:find("BlastActive", 1, true) ~= nil,
		}
		print(part:GetFullName(), attrs.Damage, attrs.GCellRate, attrs.Cooldown, attrs.DamageMultiplier, attrs.LevelScaled, attrs.RequireBlastActive)
		if not DRY_RUN then
			for k, v in pairs(attrs) do
				part:SetAttribute(k, v)
			end
			CollectionService:AddTag(part, "DPSPart")
			inst:Destroy()
		end
		converted = converted + 1
	elseif inst:IsA("Script") and inst.Name:match("^Roar%dScript$") then
		if not DRY_RUN then inst:Destroy() end
		roars = roars + 1
	end
end
print(("DRY_RUN=%s  DPS: %d  Roar scripts: %d"):format(tostring(DRY_RUN), converted, roars))
