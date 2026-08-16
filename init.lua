--!optimize 2
--!strict

--[[
	we're so back!!!
	- @Jacket_Howla
]]

local RunService  = game:GetService("RunService");
local TaskManager = { Threads = {} };

local methods          = require(script.proximity_methods)(TaskManager);
local type_marshaller  = require(script.type_marshaller);
local parallel_states  = require(script.parallel_states);



local function _executeAndComplete(FunctionOrThread: (...any) -> (...any) | thread, smartObj: any, ...: any): ()
	
	if (typeof(FunctionOrThread) == "function") then
		FunctionOrThread(...);
	else
		task.spawn(FunctionOrThread, ...);
	end;
	
	methods.fireComplete(smartObj);
end;

--[[
	Checks if the given thread part of task+ library.
]]
TaskManager.Threads.IsTaskPlus = function(thread: type_marshaller.IntelliThreadInternal?): (boolean)
	return (typeof(thread) == 'table' and thread._isDone ~= nil and thread._onComplete ~= nil);
end;

--[[
	Checks if current task+ thread is completed or not.
	If given <strong>thread</strong> is not task+'s returns nil.
]]
TaskManager.Threads.IsCompleted = function(thread: type_marshaller.IntelliThreadInternal): (boolean?)
	
	if not TaskManager.Threads.IsTaskPlus(thread) then
		warn("TaskManager.Threads 'IsCompleted' is not type of IntelliThreadInternal"); return nil;
	end;
	
	return thread._isDone;
end;

--[[
	Fully clears task+ thread from the memory.
]]
TaskManager.Threads.Clear = function(thread: type_marshaller.IntelliThreadInternal?): ()

	if not TaskManager.Threads.IsTaskPlus(thread) then
		warn("TaskManager.Threads 'Clear' is not type of IntelliThreadInternal"); return;
	end;

	local raw = (thread :: type_marshaller.IntelliThreadInternal).RawThread :: (thread);
	if (raw and coroutine.status(raw) == "suspended") then
		task.cancel(raw);
	end;

	setmetatable(thread, nil);
	table.clear(thread); --// this is table dont worry
end;

--[[
	Wraps a function execution in a protected call (pcall) with the given arguments.
]]
TaskManager.pcall = function(Function: (...any) -> (...any), ...: any): (boolean, ...any)
	return pcall(Function, ...);
end;

--[[
	Schedules a function or thread to be executed deferredly after the frame simulation ends (post-physics and animations stuff).
]]
TaskManager.defer = function(FunctionOrThread: (...any) -> (...any) | thread, ...: any): (type_marshaller.IntelliThread)
	
	local smartObj = methods.createIntelliThread();
	local thread = task.defer(_executeAndComplete, FunctionOrThread, smartObj, ...);

	(smartObj :: any).RawThread = thread;
	return smartObj;
end;

--[[
	Yields the current thread for the specified <strong>duration</strong> in seconds without throttling.
]]
TaskManager.wait = function(duration: number?): (number)
	return task.wait(duration);
end;

--[[
	Yields the current thread for a specific amount of heartbeat frames.
]]
TaskManager.waitframes = function(frames: number?): (number)
	local runner = coroutine.running();
	local c      = frames or 1;
	local s      = os.clock();
	local count  = 0;
	local con: (RBXScriptConnection);

	con = RunService.Heartbeat:Connect(function(): ()
		count += 1;

		if count >= c then
			con:Disconnect();
			task.spawn(runner); 
		end;
	end);

	coroutine.yield();
	return (os.clock() - s);
end;

--[[
	Schedules a function or thread to be executed after the specified <strong>duration</strong> in seconds.
]]
TaskManager.delay = function(duration: number?, FunctionOrThread: (...any) -> (...any) | thread, ...: any): (type_marshaller.IntelliThread)
	
	local smartObj = methods.createIntelliThread();
	local thread = task.delay(duration, _executeAndComplete, FunctionOrThread, smartObj, ...);

	(smartObj :: any).RawThread = thread;
	return smartObj;
end;

--[[
	Instantly schedules a function or thread to run on a new thread within' the task schedula'.
]]
TaskManager.spawn = function(FunctionOrThread: (...any) -> (...any) | thread, ...: any): (type_marshaller.IntelliThread)

	local smartObj = methods.createIntelliThread();
	local thread = task.spawn(_executeAndComplete, FunctionOrThread, smartObj, ...);

	(smartObj :: any).RawThread = thread;
	return smartObj;
end;

--[[
	<strong>pretty safe to use now</strong>
	Cancels the specified thread and prevents it from being resumed.
]]
TaskManager.cancel = function(thread: thread): ()
	if typeof(thread) == "thread" then
		local status = coroutine.status(thread);

		if (status == "suspended" or status == "running") then
			task.cancel(thread);
		end;
	end;
end;

--[[
	<strong>safe to use now</strong>
	Shifts the current thread execution back to serial mode, returning to the main processor thread.
	Must be invoked when parallel code needs to access non-thread-safe Luau resources.
]]
TaskManager.synchronize = function(): ()
	if parallel_states.IsParallel() then
		task.synchronize();
	end;
end;

--[[
	<strong>safe to use now</strong>
	Shifts the current thread execution to parallel mode for high-loaded network or heavy native math processing.
	Must be executed from within an Actor instance context.
]]
TaskManager.desynchronize = function(): ()
	if not parallel_states.IsParallel() then 
		task.desynchronize(); 
	end;
end;


return setmetatable({}, {
	__index    = TaskManager,
	__newindex = function(): () 
		error("Cannot write new index to protected table", 2);
	end,
	__metatable = "The metatable is locked",
});
