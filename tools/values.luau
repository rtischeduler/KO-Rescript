local values = {}

local function countInto(counts, inst)
	counts[inst.ClassName] = (counts[inst.ClassName] or 0) + 1
	for _, d in inst:GetDescendants() do
		counts[d.ClassName] = (counts[d.ClassName] or 0) + 1
	end
end

local function resolve(root, path: string)
	local list = { root }
	for seg in path:gmatch("[^/]+") do
		local nextList = {}
		for _, cur in list do
			for _, child in cur:GetChildren() do
				if child.Name == seg then table.insert(nextList, child) end
			end
		end
		list = nextList
		if #list == 0 then break end
	end
	return list
end

function values.apply(root, ops)
	local r = { changed = {}, unchanged = {}, missing = {}, ambiguous = {}, errors = {}, deletedClasses = {} }
	for _, op in ops do
		local path = op.path
		if type(path) ~= "string" then
			table.insert(r.errors, "op without path")
			continue
		end
		local found = resolve(root, path)
		if #found == 0 then
			table.insert(r.missing, path)
			continue
		end
		if #found > 1 then
			table.insert(r.ambiguous, path)
			continue
		end
		local target = found[1]
		if op.delete then
			countInto(r.deletedClasses, target)
			target:Destroy()
			table.insert(r.changed, path .. " (deleted)")
			continue
		end
		local notes = {}
		for k, v in op.attributes or {} do
			if target:GetAttribute(k) ~= v then
				target:SetAttribute(k, v)
				table.insert(notes, k .. "=" .. tostring(v))
			end
		end
		for _, k in op.remove_attributes or {} do
			if target:GetAttribute(k) ~= nil then
				target:SetAttribute(k, nil)
				table.insert(notes, "-" .. k)
			end
		end
		for k, v in op.properties or {} do
			local okRead, cur = pcall(function() return target[k] end)
			if okRead and cur ~= v then
				local okWrite, err = pcall(function() target[k] = v end)
				if okWrite then
					table.insert(notes, k .. "=" .. tostring(v))
				else
					table.insert(r.errors, path .. "." .. k .. ": " .. tostring(err))
				end
			elseif not okRead then
				table.insert(r.errors, path .. "." .. k .. ": unknown property")
			end
		end
		if #notes > 0 then
			table.insert(r.changed, path .. " [" .. table.concat(notes, ", ") .. "]")
		else
			table.insert(r.unchanged, path)
		end
	end
	return r
end

return values
