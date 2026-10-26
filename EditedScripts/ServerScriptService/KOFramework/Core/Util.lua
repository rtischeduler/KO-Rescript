-- Shared helpers. Nothing in here touches `game` at load time, so it can be unit-tested outside Roblox.
local Util = {}

-- Returns parent[name] if it exists with the right class, otherwise (re)creates it.
function Util.getOrCreate(parent, className, name)
	local object = parent:FindFirstChild(name)
	if object and not object:IsA(className) then
		object:Destroy()
		object = nil
	end
	if not object then
		object = Instance.new(className)
		object.Name = name
		object.Parent = parent
	end
	return object
end

-- { "Foo", "Bar" } -> { foo = true, bar = true }
function Util.lowerSet(list)
	local set = {}
	for _, value in ipairs(list) do
		set[string.lower(tostring(value))] = true
	end
	return set
end

-- Runs fn up to `attempts` times, waiting delaySeconds * attemptNumber between tries.
-- Returns (true, result) on success or (false, lastError). waitFn is injectable for tests.
function Util.retry(fn, attempts, delaySeconds, waitFn)
	waitFn = waitFn or task.wait
	local lastError
	for attempt = 1, attempts do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastError = result
		if attempt < attempts then
			waitFn(delaySeconds * attempt)
		end
	end
	return false, lastError
end

return Util
