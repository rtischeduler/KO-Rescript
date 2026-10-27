local Util = {}

function Util.spawn(log, name, fn, ...)
	task.spawn(function(...)
		local ok, err = pcall(fn, ...)
		if not ok then
			log:warn(name .. " failed: " .. tostring(err))
		end
	end, ...)
end

return Util
