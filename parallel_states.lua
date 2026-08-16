--!optimize 2
--!strict

local States  = {};
local _0x023  = SharedTable.new();

local function Set(t: SharedTable): ()
	t.__env_parallel_check = true;
end;

--[[
	Determines if the current runner's lua_State in parallel or serial mode
	The "greatest" detector ever made
]]
function States.IsParallel(): (boolean)
	local Changed = pcall(Set, _0x023);
	return (not Changed);
end;

return setmetatable({}, {
	__index    = States,
	__newindex = function(): () 
		error("Cannot write new index to protected table", 2);
	end,
	__metatable = "The metatable is locked",
});
