local Lifecycle = {}
Lifecycle.__index = Lifecycle

function Lifecycle.new(log, options)
	options = options or {}
	return setmetatable({
		_entries = {},
		_byName = {},
		_failed = {},
		_ordered = {},
		_log = log,
		_spawn = options.spawn,
		status = {},
	}, Lifecycle)
end

function Lifecycle:Register(def)
	assert(type(def) == "table" and type(def.Name) == "string", "service definition needs a string Name")
	assert(not self._byName[def.Name], "duplicate service: " .. def.Name)
	table.insert(self._entries, def)
	self._byName[def.Name] = def
	self.status[def.Name] = "registered"
	return def
end

function Lifecycle:_order()
	local ordered, state = {}, {}

	local function fail(def, reason)
		if self._failed[def.Name] then
			return false
		end
		state[def.Name] = "failed"
		self._failed[def.Name] = true
		self.status[def.Name] = "failed: " .. reason
		self._log:warn(def.Name .. " not started (" .. reason .. ")")
		return false
	end

	local function visit(def)
		local current = state[def.Name]
		if current == "done" then
			return true
		end
		if current == "failed" then
			return false
		end
		if current == "visiting" then
			return fail(def, "dependency cycle")
		end
		state[def.Name] = "visiting"
		for _, depName in ipairs(def.Requires or {}) do
			local dep = self._byName[depName]
			if not dep then
				return fail(def, "missing dependency " .. depName)
			end
			if not visit(dep) then
				return fail(def, "dependency " .. depName .. " unavailable")
			end
		end
		state[def.Name] = "done"
		table.insert(ordered, def)
		return true
	end

	for _, def in ipairs(self._entries) do
		visit(def)
	end
	return ordered
end

function Lifecycle:_initOne(def)
	for _, depName in ipairs(def.Requires or {}) do
		if self._failed[depName] then
			self._failed[def.Name] = true
			self.status[def.Name] = "skipped: " .. depName .. " failed"
			self._log:warn(def.Name .. " skipped because " .. depName .. " failed")
			return
		end
	end

	if type(def.Init) ~= "function" then
		self.status[def.Name] = "initialised"
		return
	end

	local function run()
		self.status[def.Name] = "initialising"
		local ok, err = pcall(def.Init, def)
		if ok then
			self.status[def.Name] = "initialised"
		else
			self._failed[def.Name] = true
			self.status[def.Name] = "failed: " .. tostring(err)
			self._log:warn(def.Name .. " failed to initialise: " .. tostring(err))
		end
	end

	if def.Async then
		(self._spawn or task.spawn)(run)
	else
		run()
	end
end

function Lifecycle:InitAll()
	self._ordered = self:_order()
	for _, def in ipairs(self._ordered) do
		self:_initOne(def)
	end
end

function Lifecycle:StartAll()
	for _, def in ipairs(self._ordered) do
		if type(def.Start) == "function" and not self._failed[def.Name] then
			(self._spawn or task.spawn)(function()
				local ok, err = pcall(def.Start, def)
				if not ok then
					self.status[def.Name] = "start failed: " .. tostring(err)
					self._log:warn(def.Name .. " failed to start: " .. tostring(err))
				end
			end)
		end
	end
end

function Lifecycle:Report()
	local lines = {}
	for _, def in ipairs(self._entries) do
		table.insert(lines, ("  %-12s %s"):format(def.Name, self.status[def.Name] or "unknown"))
	end
	return table.concat(lines, "\n")
end

return Lifecycle
