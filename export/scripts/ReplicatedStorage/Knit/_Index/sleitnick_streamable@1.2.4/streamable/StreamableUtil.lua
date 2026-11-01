





local Trove = require(script.Parent.Parent.Trove)
local _Streamable = require(script.Parent.Streamable)

type Streamables = { _Streamable.Streamable }
type CompoundHandler = (Streamables, any) -> nil


local StreamableUtil = {}


function StreamableUtil.Compound(streamables: Streamables, handler: CompoundHandler)
	local compoundTrove = Trove.new()
	local observeAllTrove = Trove.new()
	local allAvailable = false
	local function Check()
		if allAvailable then
			return
		end
		for _, streamable in pairs(streamables) do
			if not streamable.Instance then
				return
			end
		end
		allAvailable = true
		handler(streamables, observeAllTrove)
	end
	local function Cleanup()
		if not allAvailable then
			return
		end
		allAvailable = false
		observeAllTrove:Clean()
	end
	for _, streamable in pairs(streamables) do
		compoundTrove:Add(streamable:Observe(function(_child, trove)
			Check()
			trove:Add(Cleanup)
		end))
	end
	compoundTrove:Add(Cleanup)
	return compoundTrove
end

return StreamableUtil
