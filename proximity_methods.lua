--!strict
--!optimize 2

local type_marshaller = require(script.Parent.type_marshaller);

local ProximityMethods = {};
local TaskProximity    = { __index = ProximityMethods };
local TaskManager: (any);

--// lego constructor
function ProximityMethods.createIntelliThread(): (type_marshaller.IntelliThread)
	local smartObj: type_marshaller.IntelliThreadInternal = {
		RawThread      = nil,
		_onComplete    = {},
		_isDone        = false,
		_result        = nil,
		_callProtected = nil
	};
	return setmetatable(smartObj, TaskProximity) :: (any);
end;

--[[
	Schedules a callback to be executed strictly AFTER the current task finishes.
	Returns a new IntelliThread for further chaining.
]]
function ProximityMethods:andCall(callback: (...any) -> (...any)): (type_marshaller.IntelliThread)
	local selfInternal = (self :: any) :: (type_marshaller.IntelliThreadInternal);
	local nextSmartObj = ProximityMethods.createIntelliThread();
	local nextInternal = (nextSmartObj :: any) :: (type_marshaller.IntelliThreadInternal);

	local function wrapper()
		if (typeof(callback) ~= "function") then
			error("Missing callback function for method andCall.", 2);
		end;

		local currentThread = selfInternal.RawThread;
		local result = callback(currentThread);

		nextInternal._result = result;

		if (typeof(result) == "thread") then
			nextInternal.RawThread = result;
		end;

		ProximityMethods.fireComplete(nextSmartObj);
	end;

	if (selfInternal._isDone) then
		wrapper();
	else
		table.insert(selfInternal._onComplete, wrapper);
	end;

	return nextSmartObj;
end;

--[[
	Same as "andCall" method but wrapped into a safecall function (known as pcall)
]]
function ProximityMethods:andSafeCall(callback: (...any) -> (...any)): (boolean, ...any)
	local selfInternal = (self :: any) :: (type_marshaller.IntelliThreadInternal);

	if (typeof(callback) ~= "function") then
		error("Missing callback function for method andSafeCall.", 2);
	end;

	if (not selfInternal._isDone) then
		
		local currentRunner = coroutine.running();
		table.insert(selfInternal._onComplete, function()
			task.spawn(currentRunner);
		end);
		coroutine.yield();
	end;

	local currentThread = selfInternal.RawThread;
	return pcall(callback, currentThread);
end;

--[[
	Pipes data from the previous chain link to the next callback.
]]
function ProximityMethods:andThen(callback: (data: any) -> (any)): (type_marshaller.IntelliThread)
	local selfInternal = (self :: any) :: (type_marshaller.IntelliThreadInternal);
	local nextSmartObj = ProximityMethods.createIntelliThread();
	local nextInternal = (nextSmartObj :: any) :: (type_marshaller.IntelliThreadInternal);

	local function wrapper()
		if (typeof(callback) ~= "function") then
			error("Missing callback function for method andThen.", 2);
		end;

		if (selfInternal._callProtected) then
			nextInternal._result = selfInternal._result;
			nextInternal._callProtected = true;
			ProximityMethods.fireComplete(nextSmartObj);
			return;
		end;

		local incomingData = selfInternal._result;
		local succeed, result = pcall(callback, incomingData);

		if (succeed) then
			nextInternal._result = result;
		else
			warn(`Error within andThen method pipeline: {tostring(result)}`);
			nextInternal._result = result;
			nextInternal._callProtected = true;
		end;

		ProximityMethods.fireComplete(nextSmartObj);
	end;

	if (selfInternal._isDone) then
		wrapper();
	else
		table.insert(selfInternal._onComplete, wrapper);
	end;

	return nextSmartObj;
end;

--[[
	Catches error if ":andThen" encountered an exception.
]]
function ProximityMethods:andCatch(errorHandler: (errorMessage: string) -> ()): (type_marshaller.IntelliThread)
	local selfInternal = (self :: any) :: (type_marshaller.IntelliThreadInternal);
	local nextSmartObj = ProximityMethods.createIntelliThread();
	local nextInternal = (nextSmartObj :: any) :: (type_marshaller.IntelliThreadInternal);

	local function wrapper()
		if (typeof(errorHandler) ~= "function") then
			error("Missing errorHandler function for method andCatch.", 2); --// lmfaoo
		end;

		if (selfInternal._callProtected) then
			local errMsg = tostring(selfInternal._result);
			pcall(errorHandler, errMsg);
			nextInternal._callProtected = nil;
			nextInternal._result = nil;
		else
			nextInternal._result = selfInternal._result;
		end;

		ProximityMethods.fireComplete(nextSmartObj);
	end;

	if (selfInternal._isDone) then
		wrapper();
	else
		table.insert(selfInternal._onComplete, wrapper);
	end;

	return nextSmartObj;
end;

--[[
	Instantly cancels the thread at the current stage of the chain.
	Returns self to allow continuous chaining.
]]
function ProximityMethods:andClear(): (type_marshaller.IntelliThread)
	local selfInternal = (self :: any) :: (type_marshaller.IntelliThreadInternal);

	local function reset()
		local currentThread = selfInternal.RawThread;
		if (currentThread) then
			local status = coroutine.status(currentThread);
			if (status == "suspended") then
				task.cancel(currentThread);
			end;
		end;

		selfInternal.RawThread = nil;
		table.clear(selfInternal._onComplete);
	end;

	if (selfInternal._isDone) then
		reset();
	else
		table.insert(selfInternal._onComplete, reset);
	end;

	return self :: (any);
end;

function ProximityMethods.fireComplete(smartObj: type_marshaller.IntelliThread): ()
	local internal = smartObj :: type_marshaller.IntelliThreadInternal;
	internal._isDone = true;

	for _, callback in internal._onComplete do
		callback(internal.RawThread);
	end;

	table.clear(internal._onComplete);
end;

return function(a)
	TaskManager = a;

	return setmetatable({}, {
		__index = ProximityMethods,
		__newindex = function(): () 
			error("Cannot write new index to protected table", 2);
		end,
		__metatable = "The metatable is locked",
	});
end;
