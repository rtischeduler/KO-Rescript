local Util = {}

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

function Util.lowerSet(list)
	local set = {}
	for _, value in ipairs(list) do
		set[string.lower(tostring(value))] = true
	end
	return set
end

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
