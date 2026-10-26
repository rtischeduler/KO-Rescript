
local main = _G.HDAdminMain




local module = {
	
	
	["example2"] = {
		Function = function(speaker, args)
			print("HELLO (Client)")
		end;
		UnFunction = function(speaker, args)
			print("GOODBYE (Client)")
		end;
		};
	
	
	
	
	
	
};




for commandName, command in pairs(module) do
	command.Name = commandName
end



return module