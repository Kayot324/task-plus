export type task_item = ((...any) -> (...any) | thread);
export type IntelliThread = {

	--[[
		Schedules a callback to be executed strictly AFTER the current task finishes.
		Returns a new IntelliThread for further chaining.
	]]
	andCall: (self: IntelliThread, callback: (...any) -> (...any)) -> IntelliThread,

	--[[
		Same as "andCall" method but wrapped into a safecall function (known as pcall)
		Returns status of safecall and it's returnables or exception info.
	]]
	andSafeCall: (self: IntelliThread, callback: (...any) -> (...any)) -> (boolean, ...any);
	--[[
		Instantly cancels the thread at the current stage of the chain.
		Returns self to allow continuous chaining.
	]]
	andClear: (self: IntelliThread) -> IntelliThread,
	
	--[[
		Pipes data from the previous chain link to the next callback.
	]]
	andThen: (self: IntelliThread, callback: (data: any) -> (any)) -> IntelliThread,
	
	--[[
		Catches error if ":andThen" encountered an exception.
	]]
	andCatch: (self: IntelliThread, errorHandler: (errorMessage: string) -> ()) -> IntelliThread,
	RawThread: thread?, --// if you need the raw thread then okay bro nobody stops you
};

export type IntelliThreadInternal = {
	RawThread: (thread?),
	_onComplete: { (...any) -> (...any) },
	_isDone: (boolean),
	_result: (any),
	_callProtected: (boolean?) --// mostly doesn't appear and equals to nil unless call has error and being handled by ":andCatch"
};



return nil;
