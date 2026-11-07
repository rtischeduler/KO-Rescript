-- Usage: lune run tools/zilla_jr_dump <place.rbxl> <outDir> [term] [includeDefaults 0|1]
-- Extracts everything about the ZILLA JR kaiju (model data, attributes, server-side attributes)
-- plus a geometry analysis to explain why melee hitboxes land behind him.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local process = require("@lune/process")

local inPath = process.args[1]
local outDir = process.args[2]
local term = process.args[3] or "zilla jr"
local includeDefaults = process.args[4] == "1"

local function norm(s: any): string
	return (string.lower(tostring(s)):gsub("[%s_%-%.]", ""))
end
local termN = norm(term)

local place = roblox.deserializePlace(fs.readFile(inPath))
local db = roblox.getReflectionDatabase()
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame

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

local function num(n: number): any
	if n ~= n then return "NaN" end
	if n == math.huge then return "Infinity" end
	if n == -math.huge then return "-Infinity" end
	return n
end

local function round(n: number): number
	return math.floor(n * 1000 + 0.5) / 1000
end

local function vec(v: Vector3)
	return { X = round(v.X), Y = round(v.Y), Z = round(v.Z) }
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
	elseif t == "Instance" then
		return { Ref = pathOf(v) }
	elseif t == "nil" then
		return nil
	else
		local ok, s = pcall(tostring, v)
		return ok and s or ("<" .. t .. ">")
	end
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

local function isScript(i): boolean
	local c = i.ClassName
	return c == "Script" or c == "LocalScript" or c == "ModuleScript"
end

local function attrsOf(inst)
	local ok, a = pcall(function() return inst:GetAttributes() end)
	if not ok or not a or next(a) == nil then return nil end
	local out = {}
	for k, v in a do out[k] = toJson(v) end
	return out
end

local function tagsOf(inst)
	local ok, t = pcall(function() return inst:GetTags() end)
	if ok and t and #t > 0 then return t end
	return nil
end

local function propsOf(inst)
	local info = classInfo(inst.ClassName)
	local script = isScript(inst)
	local props = {}
	for _, pname in info.names do
		if pname ~= "Name" and pname ~= "Parent" and not (script and pname == "Source") then
			local ok, v = pcall(function() return inst[pname] end)
			if ok and v ~= nil then
				local skip = false
				if not includeDefaults then
					local d = info.defaults[pname]
					if d ~= nil and (d == v or tostring(d) == tostring(v)) then skip = true end
				end
				if not skip then props[pname] = toJson(v) end
			end
		end
	end
	return props
end

local function writeJson(rel: string, value)
	local full = outDir .. "/" .. rel
	local dir = full:match("^(.*)/[^/]*$")
	if not fs.isDir(dir) then fs.writeDir(dir) end
	fs.writeFile(full, serde.encode("json", value, true))
end

local function writeText(rel: string, text: string)
	local full = outDir .. "/" .. rel
	local dir = full:match("^(.*)/[^/]*$")
	if not fs.isDir(dir) then fs.writeDir(dir) end
	fs.writeFile(full, text)
end

-- ---------------------------------------------------------------- full dump of a subtree
local usedScriptFiles = {}
local function dumpNode(inst, rootDir: string, rootInst)
	local node = { Name = inst.Name, ClassName = inst.ClassName, Properties = propsOf(inst) }
	local a = attrsOf(inst)
	if a then node.Attributes = a end
	local t = tagsOf(inst)
	if t then node.Tags = t end
	if isScript(inst) then
		local rel = pathOf(inst):sub(#pathOf(rootInst) + 2)
		local ext = inst.ClassName == "ModuleScript" and ".lua" or (inst.ClassName == "LocalScript" and ".client.lua" or ".server.lua")
		local parts = string.split(rel, "/")
		for i, p in parts do parts[i] = sanitize(p) end
		local candidate = table.concat(parts, "/")
		local n = 1
		local file = candidate .. ext
		while usedScriptFiles[rootDir .. file] do
			n += 1
			file = candidate .. "__" .. n .. ext
		end
		usedScriptFiles[rootDir .. file] = true
		writeText(rootDir .. "scripts/" .. file, inst.Source)
		node.SourceFile = "scripts/" .. file
	end
	local kids = inst:GetChildren()
	if #kids > 0 then
		local list = table.create(#kids)
		for i, c in kids do list[i] = dumpNode(c, rootDir, rootInst) end
		node.Children = list
	end
	return node
end

-- ---------------------------------------------------------------- geometry analysis
local function isHitboxName(n: string): boolean
	local l = string.lower(n)
	return l:find("hit", 1, true) ~= nil or l:find("melee", 1, true) ~= nil or l:find("attack", 1, true) ~= nil
end

local function cornersOf(cf: CFrame, size: Vector3)
	local out = {}
	for _, sx in { -0.5, 0.5 } do
		for _, sy in { -0.5, 0.5 } do
			for _, sz in { -0.5, 0.5 } do
				table.insert(out, cf * Vector3.new(size.X * sx, size.Y * sy, size.Z * sz))
			end
		end
	end
	return out
end

local function findRoot(model)
	local hrp = model:FindFirstChild("HumanoidRootPart", true)
	return hrp
end

-- Returns a table describing where the visible body sits relative to HumanoidRootPart.
local function analyze(model)
	local hrp = findRoot(model)
	local res = { path = pathOf(model), className = model.ClassName }
	local ok, pp = pcall(function() return model.PrimaryPart end)
	res.primaryPart = ok and pp and pathOf(pp) or nil
	local okP, pivot = pcall(function() return model:GetPivot() end)
	if not hrp then
		res.error = "no HumanoidRootPart"
		return res
	end
	local hrpCF = hrp.CFrame
	res.hrp = {
		path = pathOf(hrp),
		position = vec(hrpCF.Position),
		lookVector = vec(hrpCF.LookVector),
		rightVector = vec(hrpCF.RightVector),
		upVector = vec(hrpCF.UpVector),
		size = vec(hrp.Size),
		anchored = hrp.Anchored,
		canCollide = hrp.CanCollide,
	}
	if okP and pivot then
		res.pivot = toJson(pivot)
		local rel = hrpCF:ToObjectSpace(pivot)
		res.pivotInHrpSpace = vec(rel.Position)
	end

	local minV, maxV = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	local sum, vol = Vector3.new(0, 0, 0), 0
	local minAll, maxAll = minV, maxV
	local visibleCount, hitboxParts, biggest = 0, {}, {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d ~= hrp then
			local loc = hrpCF:ToObjectSpace(d.CFrame)
			local rec = {
				path = pathOf(d):sub(#pathOf(model) + 2),
				class = d.ClassName,
				localPos = vec(loc.Position),
				size = vec(d.Size),
				transparency = d.Transparency,
				canCollide = d.CanCollide,
				canTouch = d.CanTouch,
				canQuery = d.CanQuery,
				massless = d.Massless,
				anchored = d.Anchored,
			}
			local a = attrsOf(d)
			if a then rec.attributes = a end
			if isHitboxName(d.Name) or d:GetAttribute("MeleeHit") then table.insert(hitboxParts, rec) end
			-- bounding data uses every part so it matches Model:GetBoundingBox
			for _, c in cornersOf(hrpCF:ToObjectSpace(d.CFrame), d.Size) do
				minAll = Vector3.new(math.min(minAll.X, c.X), math.min(minAll.Y, c.Y), math.min(minAll.Z, c.Z))
				maxAll = Vector3.new(math.max(maxAll.X, c.X), math.max(maxAll.Y, c.Y), math.max(maxAll.Z, c.Z))
			end
			if d.Transparency < 1 then
				visibleCount += 1
				local v = d.Size.X * d.Size.Y * d.Size.Z
				sum += loc.Position * v
				vol += v
				for _, c in cornersOf(hrpCF:ToObjectSpace(d.CFrame), d.Size) do
					minV = Vector3.new(math.min(minV.X, c.X), math.min(minV.Y, c.Y), math.min(minV.Z, c.Z))
					maxV = Vector3.new(math.max(maxV.X, c.X), math.max(maxV.Y, c.Y), math.max(maxV.Z, c.Z))
				end
				table.insert(biggest, { rec = rec, vol = v })
			end
		end
	end
	table.sort(biggest, function(a, b) return a.vol > b.vol end)
	local top = {}
	for i = 1, math.min(8, #biggest) do table.insert(top, biggest[i].rec) end
	res.visiblePartCount = visibleCount
	res.hitboxLikeParts = hitboxParts
	res.biggestVisibleParts = top
	if vol > 0 then
		local com = sum / vol
		res.visibleCenterOfMassInHrpSpace = vec(com)
		res.visibleBoundsInHrpSpace = { min = vec(minV), max = vec(maxV), size = vec(maxV - minV) }
		-- Roblox forward is -Z in the HRP's own space. Positive Z = behind the root part.
		res.bodyMassIsBehindHrp = com.Z > 0.5
		res.bodyExtentFrontOfHrp = round(-minV.Z)
		res.bodyExtentBehindHrp = round(maxV.Z)
	end
	if minAll.X ~= math.huge then
		res.allPartsBoundsInHrpSpace = { min = vec(minAll), max = vec(maxAll), size = vec(maxAll - minAll) }
		-- Combat.lua's bodyContactHit uses character:GetBoundingBox(); its centre is this:
		local center = (minAll + maxAll) / 2
		res.allPartsBoundsCenterInHrpSpace = vec(center)
	end
	return res
end

-- ---------------------------------------------------------------- hitbox attributes on remotes
local function hitboxAttrs(inst)
	local a = inst:GetAttributes()
	local out, any = {}, false
	for k, v in a do
		local l = string.lower(k)
		if l:find("hitbox", 1, true) or l:find("travel", 1, true) or l:find("damagestat", 1, true) or l:find("anim", 1, true) then
			out[k] = toJson(v)
			any = true
		end
	end
	return any and out or nil
end

-- ---------------------------------------------------------------- find ZILLA JR
local roots, references = {}, {}
local function matchesName(inst): boolean
	return norm(inst.Name) == termN
end
local function matchesAttr(inst): boolean
	local a = inst:GetAttributes()
	for _, v in a do
		if type(v) == "string" and norm(v) == termN then return true end
	end
	return false
end

for _, d in place:GetDescendants() do
	local isContainer = d:IsA("Model") or d:IsA("Folder")
	local byName = matchesName(d)
	local byAttr = matchesAttr(d)
	if (byName or byAttr) and isContainer then
		table.insert(roots, d)
	elseif byName or byAttr or (norm(d.Name):find(termN, 1, true)) then
		table.insert(references, { path = pathOf(d), class = d.ClassName, why = byAttr and "attribute value" or "name" })
	end
	if d:IsA("StringValue") and norm(d.Value) == termN then
		table.insert(references, { path = pathOf(d), class = d.ClassName, why = "StringValue.Value = " .. d.Value })
	end
end

-- Roots may be nested inside each other (e.g. a folder named ZILLA JR holding the model): keep outermost only.
local filtered = {}
for _, r in roots do
	local nested = false
	for _, o in roots do
		if o ~= r and r:IsDescendantOf(o) then nested = true break end
	end
	if not nested then table.insert(filtered, r) end
end
roots = filtered

if #roots == 0 then
	writeJson("NOT_FOUND.json", { term = term, references = references })
	print("No model/folder matching '" .. term .. "' found. References: " .. #references)
	process.exit(1)
end

local summary = { "# ZILLA JR extraction", "" }
table.insert(summary, ("Matched %d root(s) for `%s`:"):format(#roots, term))
for _, r in roots do table.insert(summary, ("- `%s` [%s]"):format(pathOf(r), r.ClassName)) end
table.insert(summary, "")

-- ---------------------------------------------------------------- per-root outputs
local analyses = {}
for idx, root in roots do
	local dir = (#roots == 1 and "" or ("root" .. idx .. "/"))
	writeJson(dir .. "model.json", dumpNode(root, dir, root))

	-- attributes everywhere under the model, flat for easy reading
	local flat = { [pathOf(root)] = attrsOf(root) or {} }
	local hitboxRemotes = {}
	for _, d in root:GetDescendants() do
		local a = attrsOf(d)
		if a then flat[pathOf(d)] = a end
		local ha = hitboxAttrs(d)
		if ha then table.insert(hitboxRemotes, { path = pathOf(d), class = d.ClassName, attributes = ha }) end
	end
	writeJson(dir .. "attributes_model.json", flat)

	local an = analyze(root)
	an.hitboxAttributeInstances = hitboxRemotes
	-- Where each melee hitbox lands, using Combat.lua's formula: hrp.CFrame * CFrame.new(offset)
	local hrp = findRoot(root)
	if hrp then
		local predictions = {}
		for _, h in hitboxRemotes do
			local inst = place
			local target = nil
			for _, d in root:GetDescendants() do
				if pathOf(d) == h.path then target = d break end
			end
			if target then
				local ox = target:GetAttribute("HitboxOffsetX") or 0
				local oy = target:GetAttribute("HitboxOffsetY") or 0
				local oz = target:GetAttribute("HitboxOffsetZ") or -10
				local sx = target:GetAttribute("HitboxSizeX") or 15
				local sy = target:GetAttribute("HitboxSizeY") or 15
				local sz = target:GetAttribute("HitboxSizeZ") or 15
				table.insert(predictions, {
					remote = h.path,
					usesDefaults = target:GetAttribute("HitboxOffsetZ") == nil,
					offsetInHrpSpace = { X = ox, Y = oy, Z = oz },
					sizeStuds = { X = sx, Y = sy, Z = sz },
					note = "Hitbox centre = HumanoidRootPart.CFrame * CFrame.new(offset). Negative Z is the direction the HRP faces.",
				})
			end
		end
		an.meleeHitboxPredictions = predictions
	end
	table.insert(analyses, an)

	table.insert(summary, ("## %s"):format(pathOf(root)))
	if an.hrp then
		table.insert(summary, ("- HumanoidRootPart look vector: (%s, %s, %s)"):format(an.hrp.lookVector.X, an.hrp.lookVector.Y, an.hrp.lookVector.Z))
		table.insert(summary, ("- Visible body centre of mass in HRP space: %s"):format(an.visibleCenterOfMassInHrpSpace and serde.encode("json", an.visibleCenterOfMassInHrpSpace) or "n/a"))
		table.insert(summary, ("- Body extent in FRONT of HRP (-Z): %s studs, BEHIND (+Z): %s studs"):format(tostring(an.bodyExtentFrontOfHrp), tostring(an.bodyExtentBehindHrp)))
		table.insert(summary, ("- Body mass behind HRP: %s"):format(tostring(an.bodyMassIsBehindHrp)))
		table.insert(summary, ("- Model pivot in HRP space: %s"):format(an.pivotInHrpSpace and serde.encode("json", an.pivotInHrpSpace) or "n/a"))
	else
		table.insert(summary, "- " .. tostring(an.error))
	end
	table.insert(summary, ("- Hitbox attribute instances: %d, hitbox-like parts: %d"):format(#hitboxRemotes, an.hitboxLikeParts and #an.hitboxLikeParts or 0))
	table.insert(summary, "")
end
writeJson("analysis.json", analyses)

-- ---------------------------------------------------------------- server-side attributes
-- Services, every ancestor of each root, and every instance in the game carrying a Hitbox*/Kaiju* attribute
-- that sits at or under a path mentioning the kaiju, plus the shared remote tables Combat.lua reads.
local server = { services = {}, ancestors = {}, relatedInstances = {}, allHitboxAttributeKeys = {} }
for _, svc in place:GetChildren() do
	local a = attrsOf(svc)
	if a then server.services[svc.Name] = a end
end
for _, root in roots do
	local cur = root.Parent
	while cur and cur.Parent do
		local a = attrsOf(cur)
		server.ancestors[pathOf(cur)] = a or {}
		cur = cur.Parent
	end
end
local keyCounts = {}
for _, d in place:GetDescendants() do
	local a = d:GetAttributes()
	for k, v in a do
		local l = string.lower(k)
		if l:find("hitbox", 1, true) or l:find("kaiju", 1, true) then
			local e = keyCounts[k]
			if not e then e = { count = 0, samples = {} } keyCounts[k] = e end
			e.count += 1
			if #e.samples < 5 then table.insert(e.samples, { path = pathOf(d), value = toJson(v) }) end
		end
	end
	local p = norm(pathOf(d))
	if p:find(termN, 1, true) and not (function() for _, r in roots do if d == r or d:IsDescendantOf(r) then return true end end return false end)() then
		local entry = { path = pathOf(d), class = d.ClassName, attributes = attrsOf(d), tags = tagsOf(d) }
		if d:IsA("ValueBase") then
			local ok, v = pcall(function() return d.Value end)
			if ok then entry.value = toJson(v) end
		end
		table.insert(server.relatedInstances, entry)
	end
end
server.allHitboxAttributeKeys = keyCounts
writeJson("server_attributes.json", server)
writeJson("references.json", references)

-- ---------------------------------------------------------------- comparison against every other kaiju
local cmp = {}
local kaijus = place.ServerStorage and place.ServerStorage:FindFirstChild("Kaijus")
local function addCompare(m)
	if m:IsA("Model") and findRoot(m) then
		local a = analyze(m)
		local name = attrsOf(m) and attrsOf(m).KaijuName or m.Name
		table.insert(cmp, {
			model = pathOf(m),
			kaijuName = name,
			hrpLook = a.hrp and a.hrp.lookVector,
			massCentreInHrp = a.visibleCenterOfMassInHrpSpace,
			frontExtent = a.bodyExtentFrontOfHrp,
			behindExtent = a.bodyExtentBehindHrp,
			massBehind = a.bodyMassIsBehindHrp,
			pivotInHrp = a.pivotInHrpSpace,
		})
	end
end
if kaijus then
	for _, k in kaijus:GetDescendants() do
		if k:IsA("Model") and k.Parent and (k.Parent == kaijus or k.Parent:IsA("Folder")) and k:FindFirstChildWhichIsA("Humanoid") then
			addCompare(k)
		end
	end
end
writeJson("compare_all_kaijus.json", cmp)
table.insert(summary, ("Compared against %d other kaiju models: see compare_all_kaijus.json."):format(#cmp))
table.insert(summary, ("References to the name elsewhere in the game: %d (references.json)."):format(#references))
table.insert(summary, ("Instances outside the model whose path mentions it: %d (server_attributes.json)."):format(#server.relatedInstances))
writeText("summary.md", table.concat(summary, "\n") .. "\n")
print("done: " .. #roots .. " root(s), " .. #cmp .. " compared kaijus")
