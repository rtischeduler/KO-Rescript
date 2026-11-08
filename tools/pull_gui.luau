local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local process = require("@lune/process")

local inPath = process.args[1]
local outDir = process.args[2]
local targets = string.split(process.args[3] or "StarterGui/NEWMenu/Settings", ",")
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

local function dump(inst)
	local info = classInfo(inst.ClassName)
	local props = {}
	for _, pname in info.names do
		local ok, v = pcall(function() return (inst :: any)[pname] end)
		if ok and v ~= nil and (includeDefaults or toJson(v) ~= toJson(info.defaults[pname])) then
			props[pname] = toJson(v)
		end
	end
	if inst.ClassName == "TextLabel" or inst.ClassName == "TextButton" or inst.ClassName == "TextBox" then
		local ok, f = pcall(function() return (inst :: any).FontFace end)
		if ok then props.FontFace = tostring(f.Family) .. ", " .. tostring(f.Weight) .. ", " .. tostring(f.Style) end
	end
	local attrs = inst:GetAttributes()
	if next(attrs) ~= nil then
		local a = {}
		for k, v in attrs do a[k] = toJson(v) end
		props.__attributes = a
	end
	local kids = {}
	for _, c in inst:GetChildren() do table.insert(kids, dump(c)) end
	return { Name = inst.Name, ClassName = inst.ClassName, Properties = props, Children = kids }
end

local function resolve(path: string)
	local list = { place }
	for seg in path:gmatch("[^/]+") do
		local nextList = {}
		for _, cur in list do
			for _, child in cur:GetChildren() do
				if child.Name == seg then table.insert(nextList, child) end
			end
		end
		list = nextList
	end
	return list
end

fs.writeDir(outDir)
local summary = { "# GUI pull", "" }
for _, raw in targets do
	local path = raw:gsub("^%s+", ""):gsub("%s+$", "")
	if path == "" then continue end
	local found = resolve(path)
	if #found == 0 then
		table.insert(summary, "- `" .. path .. "`: **not found**")
		continue
	end
	for i, inst in found do
		local base = sanitize((path:gsub("/", "__")) .. (#found > 1 and ("__" .. i) or ""))
		fs.writeFile(outDir .. "/" .. base .. ".json", serde.encode("json", dump(inst), true))
		fs.writeFile(outDir .. "/" .. base .. ".rbxmx", roblox.serializeModel({ inst }, true))
		table.insert(summary, ("- `%s`: %d descendants -> `%s.json` + `%s.rbxmx`"):format(path, #inst:GetDescendants(), base, base))
	end
end
fs.writeFile(outDir .. "/summary.md", table.concat(summary, "\n") .. "\n")
print(table.concat(summary, "\n"))
