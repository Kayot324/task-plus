# task+
A simple, strict-typed, and promise-driven wrapper for Roblox's native `task` library.

`task+` makes it easy to link your functions into clean execution chains, helping you avoid nested callback hell. It also includes built-in protection against common Parallel Luau multi-threading mistakes.

---

## Installation

1. Download the latest `.rbxm` model from the [Roblox Marketplace](https://create.roblox.com/store/asset/80290836879169/task).
2. Drop the folder into `ReplicatedStorage` or `ServerScriptService`.
3. Require it in your scripts:

```lua
const task = require(game:GetService("ReplicatedStorage")["task+"]);
```

---

## Folder Structure
For your project repository, it is recommended to organize your files like this:
```text
task+/
├── init.lua             # Main TaskManager logic
├── proximity_methods.lua # Chaining logic (andCall, andThen, etc.)
├── type_marshaller.lua  # Strict type definitions
└── parallel_states.lua  # SharedTable multi-threading checker
```

---

## Quick Examples

### 1. Basic Chaining (Run functions one after another)
```lua
local function printHello()
	print("Hello")
end

local function printWorld()
	print("World")
end

-- Waits 5 seconds, prints "Hello", and prints "World" right after it finishes
task.delay(5, printHello):andCall(printWorld)
```

### 2. Passing Data & Catching Errors
```lua
local function getNumber()
	return 10 -- Passes 10 to the next step
end

task.spawn(getNumber)
	:andThen(function(myNumber)
		print("Got number:", myNumber) -- Prints 10
		return myNumber * 2 -- Passes 20 to the next step
	end)
	:andThen(function(newNumber)
		if newNumber > 15 then
			error("Number is too big!") -- Triggers an error
		end
	end)
	:andCatch(function(err)
		warn("Caught a bug:", err) -- Runs because an error happened above
	end)
	:andClear() -- Completely cleans up the memory
```

### 3. Safe Calls with Return Values
```lua
local function brokenFunction()
	error("Something broke!")
end

-- ':andSafeCall' runs a function safely inside a pcall
local success, result = task.spawn(brokenFunction):andSafeCall(function()
	print("This runs inside pcall")
end)

print(success) -- Prints false
```

### 4. Global Thread Management
```lua
local myThread = task.delay(10, function() print("Done") end)

-- Check and force delete task+ threads from any other external script
if task.Threads.IsTaskPlus(myThread) and task.Threads.IsCompleted(myThread) then
	task.Threads.Clear(myThread) -- Deletes the thread from memory immediately
end
```

---

## Thread Synchronization Note
Instead of relying on slow scans, `task+` uses a fast `SharedTable` trap to check thread states instantly:

```lua
if parallel_states.IsParallel() then 
    task.synchronize() 
end
```
