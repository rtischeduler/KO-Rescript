local LegacyService = {}

function LegacyService.Create(moduleName)
	return {
		Name = moduleName,
		Async = true,
		Init = function()
			local ServerScriptService = game:GetService("ServerScriptService")
			local folder = ServerScriptService:WaitForChild("framework", 30)
			local modules = folder and folder:WaitForChild("modules", 30)
			local moduleScript = modules and modules:FindFirstChild(moduleName)
			if not moduleScript then
				error("module not found: ServerScriptService.framework.modules." .. moduleName)
			end
			local system = require(moduleScript)
			if type(system) ~= "table" or type(system.Init) ~= "function" then
				error("module has no Init function")
			end
			system.Init()
		end,
	}
end

return LegacyService
