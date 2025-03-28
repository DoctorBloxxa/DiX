local utils = {}
local tock = os.clock

function utils:GetAncestry(Instance: Instance, Stop: Instance, InvertList: boolean)
	local List, InvertedList = {}, {}
	local Stop = Stop or game
	local Parent = Instance

	repeat
		List[#List + 1] = Parent
		Parent = Parent.Parent
	until Parent == Stop or Parent.Parent == nil

	for i = 1, #List do
		InvertedList[i] = List[#List - i + 1]
	end

	return not InvertList and InvertedList or List
end

-- stylua: ignore start
function utils:GetRootClass(Instance: Instance, ClassName: string, IsBaseClass: boolean, Stop: Instance)
	local Result, Parent = Instance, Instance
	local Stop = Stop or game

	local MatchClass = IsBaseClass and 
		function(Instance: Instance, ClassName: string) 
			return Instance:IsA(ClassName)
		end 
		or 
		function(Instance: Instance, ClassName: string) 
			return Instance.ClassName == ClassName
		end

	repeat
		if Parent.ClassName == ClassName then
			Result = Parent
		end
		Parent = Parent.Parent
	until Parent == Stop or Parent.Parent == nil

	return Result
end
-- stylua: ignore end

function utils:watchdog(Budget: number, YieldMethod: (any) -> any)
	local Deadline = 0

	local watchdog = {}

	function watchdog:Reset()
		Deadline = tock() + Budget
	end

	function watchdog:Tick()
		if tock() >= Deadline then
			YieldMethod()
			watchdog:Reset()
		end
	end

	return watchdog
end

function utils:matchpattern(Pattern: string, Target: string, CaseSensitive: boolean)
	if CaseSensitive then
		Pattern = string.lower(Pattern)
		Target = string.lower(Target)
	end

	return string.find(Target, Pattern)
end

return utils
