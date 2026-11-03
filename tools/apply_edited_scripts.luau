local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local serde = require("@lune/serde")
local valuesLib = require("./values")

local inPath = process.args[1]
local outPath = process.args[2]
local reportPath = process.args[3]
local editedDir = process.args[4]
local manifestPath = process.args[5]
local createMissing = process.args[6] == "1"
local valuesDir = process.args[7]

local SKIP_TOP = { tests = true, Migration = true }
local STRIP_TOP = { BeamCombat = true }

local function sanitize(name: string): string
	local s = name:gsub('[<>:"/\\|?*%c]', "_")
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	if s == "" or s == "." or s == ".." then s = "_" end
	return s
end

local function isScript(i): boolean
	local c = i.ClassName
	return c == "Script" or c == "LocalScript" or c == "ModuleScript"
end

local function isClientContext(i): boolean
	if i.ClassName == "LocalScript" then return true end
	if i.ClassName ~= "Script" then return false end
	local ok, rc = pcall(function() return i.RunContext end)
	return ok and rc ~= nil and rc.Name == "Client"
end

local function kindMatches(i, kind: string): boolean
	if kind == "module" then return i.ClassName == "ModuleScript" end
	if kind == "client" then return isClientContext(i) end
	return i.ClassName == "Script" and not isClientContext(i)
end

local function classify(file: string)
	if file:sub(-11) == ".server.lua" then return file:sub(1, -12), "server" end
	if file:sub(-11) == ".client.lua" then return file:sub(1, -12), "client" end
	return file:sub(1, -5), "module"
end

local place = roblox.deserializePlace(fs.readFile(inPath))

local function pathOf(inst): string
	local parts = {}
	local cur = inst
	while cur and cur.Parent do
		table.insert(parts, 1, cur.Name)
		cur = cur.Parent
	end
	return table.concat(parts, "/")
end

local function countClasses(root)
	local counts, total = {}, 0
	for _, d in root:GetDescendants() do
		counts[d.ClassName] = (counts[d.ClassName] or 0) + 1
		total += 1
	end
	return counts, total
end

local function diffCounts(a, b)
	local out = {}
	for k, v in a do
		if (b[k] or 0) ~= v then table.insert(out, k .. ": " .. v .. " -> " .. (b[k] or 0)) end
	end
	for k, v in b do
		if a[k] == nil then table.insert(out, k .. ": 0 -> " .. v) end
	end
	return out
end

local function lineCounts(text: string)
	local counts = {}
	for line in (text .. "\n"):gmatch("(.-)\n") do
		counts[line] = (counts[line] or 0) + 1
	end
	return counts
end

local function diffStat(old: string, new: string)
	local oc, nc = lineCounts(old), lineCounts(new)
	local added, removed = 0, 0
	for line, n in nc do
		local o = oc[line] or 0
		if n > o then added += n - o end
	end
	for line, n in oc do
		local m = nc[line] or 0
		if n > m then removed += n - m end
	end
	return added, removed
end

local function resolveParents(segments)
	local list = { place }
	for _, seg in segments do
		local nextList = {}
		for _, cur in list do
			for _, child in cur:GetChildren() do
				if child.Name == seg or sanitize(child.Name) == seg then
					table.insert(nextList, child)
				end
			end
		end
		list = nextList
		if #list == 0 then break end
	end
	return list
end

local before = countClasses(place)

local changed, created, unchanged, missing, ambiguous, skipped = {}, {}, {}, {}, {}, {}
local createdClasses = {}
local touched = {}

local manifest = {}
for line in fs.readFile(manifestPath):gmatch("[^\r\n]+") do
	local rel = line:gsub("^%s+", ""):gsub("%s+$", "")
	if rel ~= "" and rel:sub(-4) == ".lua" then table.insert(manifest, rel) end
end

for _, rel in manifest do
	local parts = string.split(rel, "/")
	if SKIP_TOP[parts[1]] then
		table.insert(skipped, rel .. " (excluded folder)")
		continue
	end
	if STRIP_TOP[parts[1]] then table.remove(parts, 1) end
	local file = table.remove(parts)
	local base, kind = classify(file)
	local fullFile = editedDir .. "/" .. rel
	if not fs.isFile(fullFile) then
		table.insert(skipped, rel .. " (file not in repo)")
		continue
	end
	local newSource = fs.readFile(fullFile)
	if newSource:gsub("%s", "") == "" then
		table.insert(skipped, rel .. " (empty file)")
		continue
	end
	newSource = newSource:gsub("\n$", "")

	local name = base
	if base == "init" then
		name = table.remove(parts)
		if not name then
			table.insert(skipped, rel .. " (init file at top level)")
			continue
		end
	end

	local parents = resolveParents(parts)
	local candidates = {}
	for _, p in parents do
		for _, child in p:GetChildren() do
			if isScript(child) and (child.Name == name or sanitize(child.Name) == name) and kindMatches(child, kind) then
				table.insert(candidates, child)
			end
		end
	end

	if #candidates == 1 then
		local target = candidates[1]
		local key = pathOf(target) .. ":" .. target.ClassName
		if touched[key] then
			table.insert(skipped, rel .. " (same target already handled: " .. key .. ")")
			continue
		end
		touched[key] = true
		local old = target.Source
		local oldTrim = old:gsub("%s+$", "")
		local newTrim = newSource:gsub("%s+$", "")
		if oldTrim == newTrim then
			table.insert(unchanged, pathOf(target))
		else
			local added, removed = diffStat(old, newSource)
			target.Source = newSource
			table.insert(changed, { path = pathOf(target), class = target.ClassName, added = added, removed = removed })
		end
	elseif #candidates > 1 then
		local paths = {}
		for _, c in candidates do table.insert(paths, pathOf(c) .. " [" .. c.ClassName .. "]") end
		table.insert(ambiguous, rel .. " -> " .. table.concat(paths, " | "))
	else
		if createMissing and base ~= "init" and #parts > 0 and #parents == 1 then
			local cls = kind == "server" and "Script" or kind == "client" and "LocalScript" or "ModuleScript"
			local inst = roblox.Instance.new(cls)
			inst.Name = name
			inst.Source = newSource
			inst.Parent = parents[1]
			createdClasses[cls] = (createdClasses[cls] or 0) + 1
			table.insert(created, pathOf(inst) .. " [" .. cls .. "]")
		else
			table.insert(missing, rel .. " -> " .. table.concat(parts, "/") .. "/" .. name .. " [" .. kind .. "]")
		end
	end
end

local valueResult = { changed = {}, unchanged = {}, missing = {}, ambiguous = {}, errors = {}, deletedClasses = {} }
if valuesDir and valuesDir ~= "" and fs.isDir(valuesDir) then
	local names = fs.readDir(valuesDir)
	table.sort(names)
	local ops = {}
	for _, f in names do
		if f:sub(-5) == ".json" then
			local okDecode, data = pcall(function() return serde.decode("json", fs.readFile(valuesDir .. "/" .. f)) end)
			if okDecode and type(data) == "table" then
				for _, op in data do table.insert(ops, op) end
			else
				table.insert(valueResult.errors, f .. ": invalid JSON")
			end
		end
	end
	local applied = valuesLib.apply(place, ops)
	for k, v in applied do
		if k == "errors" then
			for _, e in v do table.insert(valueResult.errors, e) end
		else
			valueResult[k] = v
		end
	end
end

local problems = {}
local expected = {}
for k, v in before do expected[k] = v end
for k, v in createdClasses do expected[k] = (expected[k] or 0) + v end
for k, v in valueResult.deletedClasses do expected[k] = (expected[k] or 0) - v end
for _, e in valueResult.errors do table.insert(problems, "values: " .. e) end
local afterClasses = countClasses(place)
for _, d in diffCounts(expected, afterClasses) do table.insert(problems, "after edit: " .. d) end

local serialized = nil
if #changed + #created + #valueResult.changed > 0 and #problems == 0 then
	serialized = roblox.serializePlace(place)
	local reloaded = roblox.deserializePlace(serialized)
	local reClasses = countClasses(reloaded)
	for _, d in diffCounts(afterClasses, reClasses) do table.insert(problems, "after re-serialize: " .. d) end
end

local out = {}
local function add(s: string) table.insert(out, s) end

add("# Script apply report")
add("")
add(("- changed: **%d**"):format(#changed))
add(("- created: **%d**"):format(#created))
add(("- unchanged: **%d**"):format(#unchanged))
add(("- missing in game (skipped): **%d**"):format(#missing))
add(("- ambiguous (skipped): **%d**"):format(#ambiguous))
add(("- skipped: **%d**"):format(#skipped))
add(("- values changed: **%d** (unchanged %d, missing %d, ambiguous %d)"):format(#valueResult.changed, #valueResult.unchanged, #valueResult.missing, #valueResult.ambiguous))
add("")
add("Scripts: only the `Source` of existing scripts is edited. Values: only what is listed in EditedValues (attributes, properties, listed deletions) is touched. Everything else is left as it is.")
add("")

if #problems > 0 then
	add("## VERIFICATION FAILED - nothing will be written or published")
	for _, p in problems do add("- " .. p) end
	add("")
end
if #changed > 0 then
	add("## Changed")
	for _, c in changed do
		add(("- ✏️ `%s` [%s] +%d / -%d lines"):format(c.path, c.class, c.added, c.removed))
	end
	add("")
end
if #valueResult.changed > 0 then
	add("## Values changed")
	for _, c in valueResult.changed do add("- 🔧 `" .. c .. "`") end
	add("")
end
if #valueResult.missing > 0 then
	add("## Value paths not found (skipped)")
	for _, m in valueResult.missing do add("- ❓ `" .. m .. "`") end
	add("")
end
if #valueResult.ambiguous > 0 then
	add("## Value paths ambiguous (skipped)")
	for _, m in valueResult.ambiguous do add("- ⚠️ `" .. m .. "`") end
	add("")
end
if #created > 0 then
	add("## Created (create_missing)")
	for _, c in created do add("- ➕ `" .. c .. "`") end
	add("")
end
if #missing > 0 then
	add("## Not found in game (skipped; scripts that require these will break if published as-is)")
	for _, m in missing do add("- ❓ `" .. m .. "`") end
	add("")
end
if #ambiguous > 0 then
	add("## Ambiguous path (skipped)")
	for _, m in ambiguous do add("- ⚠️ `" .. m .. "`") end
	add("")
end
if #skipped > 0 then
	add("## Skipped")
	for _, m in skipped do add("- " .. m) end
	add("")
end
if #unchanged > 0 then
	add("<details><summary>Unchanged (" .. #unchanged .. ")</summary>")
	add("")
	for _, u in unchanged do add("- `" .. u .. "`") end
	add("")
	add("</details>")
end

fs.writeFile(reportPath, table.concat(out, "\n") .. "\n")
fs.writeFile(
	reportPath .. ".result",
	("changed=%d\ncreated=%d\nmissing=%d\nfailed=%d\n"):format(#changed + #valueResult.changed, #created, #missing + #valueResult.missing, #problems > 0 and 1 or 0)
)
print(table.concat(out, "\n"))

if #problems > 0 then process.exit(1) end
if serialized then fs.writeFile(outPath, serialized) end
