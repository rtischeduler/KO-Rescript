local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local process = require("@lune/process")

local inPath = process.args[1]
local outDir = process.args[2]
local term = string.lower(process.args[3] or "player")
local includeDefaults = process.args[4] == "1"

local place = roblox.deserializePlace(fs.readFile(inPath))
local db = roblox.getReflectionDatabase()

local function sanitize(name: string): string
	local s = tostring(name):gsub('[<>:"/\\|?*%c]', "_")
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	if s == "" or s == "." or s == ".." then s = "_" end
	if #s > 80 then s = s:sub(1, 80) end
	return s
end

local function pathOf(inst): string
	local parts = {}
	local cur = inst
	while cur and cur.Parent do
		table.insert(parts, 1, cur.Name)
		cur = cur.Parent
	end
	return table.concat(parts, "/")
end

local classCache = {}
local function classInfo(className: string)
	if classCache[className] then return classCache[className] end
	local names, defaults, seen = {}, {}, {}
	local cur = db:GetClass(className)
	while cur do
		for pname, prop in cur.Properties do
			if not seen[pname] then
				seen[pname] = true
				local scr = tostring(prop.Scriptability)
				if scr ~= "None" and scr ~= "Write" then table.insert(names, pname) end
			end
		end
		if cur.DefaultProperties then
			for pname, val in cur.DefaultProperties do
				if defaults[pname] == nil then defaults[pname] = val end
			end
		end
		cur = cur.Superclass and db:GetClass(cur.Superclass) or nil
	end
	table.sort(names)
	local info = { names = names, defaults = defaults }
	classCache[className] = info
	return info
end

local function num(n: number): any
	if n ~= n then return "NaN" end
	if n == math.huge then return "Infinity" end
	if n == -math.huge then return "-Infinity" end
	return n
end

local function toJson(v: any): any
	local t = typeof(v)
	if t == "string" then
		if utf8.len(v) == nil then return "[binary " .. #v .. " bytes]" end
		return v
	elseif t == "number" then
		return num(v)
	elseif t == "boolean" then
		return v
	elseif t == "Vector3" then
		return { X = num(v.X), Y = num(v.Y), Z = num(v.Z) }
	elseif t == "Vector2" then
		return { X = num(v.X), Y = num(v.Y) }
	elseif t == "Color3" then
		return { R = num(v.R), G = num(v.G), B = num(v.B) }
	elseif t == "CFrame" then
		local c = { v:GetComponents() }
		for i, x in c do c[i] = num(x) end
		return { Position = { c[1], c[2], c[3] }, Rotation = { c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11], c[12] } }
	elseif t == "EnumItem" or t == "BrickColor" or t == "UDim2" or t == "UDim" or t == "Rect" or t == "NumberRange"
		or t == "NumberSequence" or t == "ColorSequence" or t == "Font" or t == "PhysicalProperties" or t == "Faces"
		or t == "Axes" or t == "Vector3int16" or t == "Vector2int16" or t == "Region3" or t == "Ray" then
		return tostring(v)
	elseif t == "Instance" then
		return { Ref = pathOf(v) }
	else
		local ok, s = pcall(tostring, v)
		return { Type = t, Value = ok and s or "?" }
	end
end

local function isScript(i): boolean
	local c = i.ClassName
	return c == "Script" or c == "LocalScript" or c == "ModuleScript"
end

local function containsTerm(s: any): boolean
	return type(s) == "string" and string.find(string.lower(s), term, 1, true) ~= nil
end

local tagIndex, attrIndex, searchHits = {}, {}, {}
local counts = { instances = 0, scripts = 0 }
local usedScriptFiles = {}

local function sample(index, key, path, class, extra)
	local e = index[key]
	if not e then
		e = { count = 0, samples = {} }
		index[key] = e
	end
	e.count += 1
	if #e.samples < 8 then table.insert(e.samples, { path = path, class = class, value = extra }) end
end

local function hit(path, class, why, detail)
	if #searchHits < 2000 then table.insert(searchHits, { path = path, class = class, why = why, detail = detail }) end
end

local function writeScript(inst, path: string): string
	local ext = inst.ClassName == "ModuleScript" and ".lua" or (inst.ClassName == "LocalScript" and ".client.lua" or ".server.lua")
	if inst.ClassName == "Script" then
		local ok, rc = pcall(function() return inst.RunContext end)
		if ok and rc and rc.Name == "Client" then ext = ".client.lua" end
	end
	local parts = string.split(path, "/")
	for i, p in parts do parts[i] = sanitize(p) end
	local rel = table.concat(parts, "/")
	local candidate = rel .. ext
	local n = 1
	while usedScriptFiles[candidate] do
		n += 1
		candidate = rel .. "__" .. n .. ext
	end
	usedScriptFiles[candidate] = true
	local full = outDir .. "/scripts/" .. candidate
	local dir = full:match("^(.*)/[^/]*$")
	if not fs.isDir(dir) then fs.writeDir(dir) end
	fs.writeFile(full, inst.Source)
	return "scripts/" .. candidate
end

local function nodeOf(inst)
	counts.instances += 1
	local path = pathOf(inst)
	local class = inst.ClassName
	local node = { Name = inst.Name, ClassName = class }
	local info = classInfo(class)
	local props = {}
	local script = isScript(inst)
	for _, pname in info.names do
		if pname ~= "Name" and pname ~= "Parent" and not (script and pname == "Source") then
			local ok, v = pcall(function() return inst[pname] end)
			if ok and v ~= nil then
				local skip = false
				if not includeDefaults then
					local d = info.defaults[pname]
					if d ~= nil and (d == v or tostring(d) == tostring(v)) then skip = true end
				end
				if not skip then
					props[pname] = toJson(v)
					if type(v) == "string" and containsTerm(v) then hit(path, class, "property " .. pname, v:sub(1, 200)) end
				end
			end
		end
	end
	node.Properties = props

	local okA, attrs = pcall(function() return inst:GetAttributes() end)
	if okA and attrs and next(attrs) ~= nil then
		local a = {}
		for k, v in attrs do
			a[k] = toJson(v)
			sample(attrIndex, k, path, class, a[k])
			if containsTerm(k) or containsTerm(v) then hit(path, class, "attribute " .. k, tostring(v):sub(1, 200)) end
		end
		node.Attributes = a
	end
	local okT, tags = pcall(function() return inst:GetTags() end)
	if okT and tags and #tags > 0 then
		node.Tags = tags
		for _, tag in tags do
			sample(tagIndex, tag, path, class, nil)
			if containsTerm(tag) then hit(path, class, "tag", tag) end
		end
	end
	if containsTerm(inst.Name) then hit(path, class, "name", inst.Name) end
	if containsTerm(class) then hit(path, class, "class", class) end

	if script then
		counts.scripts += 1
		node.SourceFile = writeScript(inst, path)
	end

	local kids = inst:GetChildren()
	if #kids > 0 then
		local list = table.create(#kids)
		for i, c in kids do list[i] = nodeOf(c) end
		node.Children = list
	end
	return node
end

local function writeJson(rel: string, value)
	local full = outDir .. "/" .. rel
	local dir = full:match("^(.*)/[^/]*$")
	if not fs.isDir(dir) then fs.writeDir(dir) end
	fs.writeFile(full, serde.encode("json", value, true))
end

local CHUNK_THRESHOLD = 300
local CHUNK_SIZE = 200

for _, service in place:GetChildren() do
	local sname = sanitize(service.Name)
	counts.instances += 1
	local info = classInfo(service.ClassName)
	local selfNode = { Name = service.Name, ClassName = service.ClassName, Properties = {} }
	for _, pname in info.names do
		if pname ~= "Name" and pname ~= "Parent" then
			local ok, v = pcall(function() return service[pname] end)
			if ok and v ~= nil then
				local d = info.defaults[pname]
				if includeDefaults or d == nil or not (d == v or tostring(d) == tostring(v)) then
					selfNode.Properties[pname] = toJson(v)
				end
			end
		end
	end
	local kids = service:GetChildren()
	selfNode.ChildCount = #kids
	writeJson("tree/" .. sname .. "/_service.json", selfNode)

	if #kids <= CHUNK_THRESHOLD then
		local used = {}
		for _, kid in kids do
			local base = sanitize(kid.Name)
			local name = base
			local n = 1
			while used[name] do
				n += 1
				name = base .. "__" .. n
			end
			used[name] = true
			writeJson("tree/" .. sname .. "/" .. name .. ".json", nodeOf(kid))
		end
	else
		local i, chunk = 1, 1
		while i <= #kids do
			local group = {}
			for j = i, math.min(i + CHUNK_SIZE - 1, #kids) do table.insert(group, nodeOf(kids[j])) end
			writeJson(("tree/%s/_chunk_%04d.json"):format(sname, chunk), group)
			i += CHUNK_SIZE
			chunk += 1
		end
	end
end

local function sortedList(index)
	local list = {}
	for k, e in index do table.insert(list, { name = k, count = e.count, samples = e.samples }) end
	table.sort(list, function(a, b) return a.count > b.count end)
	return list
end

local tags = sortedList(tagIndex)
local attrs = sortedList(attrIndex)
writeJson("tags.json", tags)
writeJson("attributes.json", attrs)
writeJson("search.json", { term = term, hits = searchHits })

local md = {}
table.insert(md, "# Game tree export")
table.insert(md, "")
table.insert(md, ("- instances: **%d**, scripts written as Lua: **%d**"):format(counts.instances, counts.scripts))
table.insert(md, ("- distinct tags: **%d**, distinct attribute names: **%d**"):format(#tags, #attrs))
table.insert(md, ("- search hits for `%s`: **%d**%s"):format(term, #searchHits, #searchHits >= 2000 and " (capped)" or ""))
table.insert(md, "")
table.insert(md, "## Tags (instance count, first sample)")
for i, t in tags do
	if i > 150 then break end
	local s = t.samples[1]
	table.insert(md, ("- `%s` x%d - `%s` [%s]"):format(t.name, t.count, s and s.path or "", s and s.class or ""))
end
table.insert(md, "")
table.insert(md, "## Attribute names (instance count, first sample)")
for i, t in attrs do
	if i > 150 then break end
	local s = t.samples[1]
	table.insert(md, ("- `%s` x%d - `%s` [%s]"):format(t.name, t.count, s and s.path or "", s and s.class or ""))
end
table.insert(md, "")
table.insert(md, ("## Search hits for `%s` (first 150)"):format(term))
for i, h in searchHits do
	if i > 150 then break end
	table.insert(md, ("- %s: `%s` [%s] %s"):format(h.why, h.path, h.class, h.detail and ("= " .. h.detail) or ""))
end
fs.writeFile(outDir .. "/summary.md", table.concat(md, "\n") .. "\n")
print(("exported %d instances, %d scripts, %d tags, %d attribute names, %d search hits"):format(counts.instances, counts.scripts, #tags, #attrs, #searchHits))
