-- Tiny tagged logger so every framework message is easy to grep in the output window.
local Logger = {}
Logger.__index = Logger

function Logger.new(tag)
	return setmetatable({ tag = tag }, Logger)
end

function Logger:info(message)
	print(("[%s] %s"):format(self.tag, tostring(message)))
end

function Logger:warn(message)
	warn(("[%s] %s"):format(self.tag, tostring(message)))
end

return Logger
