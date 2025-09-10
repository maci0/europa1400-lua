# Usage Guide

Detailed usage instructions and examples for the Europa 1400 Lua Console.

## Basic Console Commands

```lua
-- Core information
help()                      -- Show all available commands
list()                      -- List registered game functions

-- System diagnostics  
system.info()               -- System hardware information
system.memory_info()        -- RAM usage and memory status
system.list_modules()       -- Loaded DLLs with addresses
system.window_info()        -- All process windows with details
system.memory_layout()      -- Memory layout overview
system.thread_info()        -- Thread information

-- Console utilities
cls                         -- Clear screen
history                     -- Show command history
exit / quit / q            -- Close console
```

## Game Function System

### Registering Functions (from Ghidra)
```lua
-- Basic function (no parameters)
game.register("GetPlayerGold", 0x403000, "int()", "Get current gold")

-- Function with parameters  
game.register("SetPlayerGold", 0x403100, "void(int)", "Set gold amount")

-- Complex function with multiple parameters
game.register("CreateUnit", 0x404000, "void*(int, int, int)", "Create unit at x,y")

-- Different calling conventions
game.register("WinAPIFunc", 0x405000, "int __stdcall(int, char*)", "Windows API style")
```

### Calling Functions
```lua  
-- Simple calls
local gold = game.call("GetPlayerGold")
print("Current gold:", gold)

-- With parameters
game.call("SetPlayerGold", 9999)
game.call("CreateUnit", 1, 100, 200)  -- type=1, x=100, y=200

-- Error handling
local success, result = pcall(function()
    return game.call("SomeFunction", param1, param2)
end)
if success then
    print("Result:", result)
else
    print("Error:", result)
end
```

## Memory Operations

```lua
-- Read memory
local data, bytes_read = game.read_mem(0x500000, 4, "int")
if data then
    print("Memory value:", data[0])
end

-- Write memory
local ffi = require('ffi')
local new_value = ffi.new("int[1]", 12345)
local success, bytes_written = game.write_mem(0x500000, new_value, 4)
print("Write successful:", success, "Bytes:", bytes_written)

-- Get module base addresses
local base = game.get_module_base("kernel32.dll")
print("Kernel32 base:", string.format("0x%08X", base))
```

## Working with Structs

```lua
local ffi = require('ffi')

-- Define a game struct
ffi.cdef[[
typedef struct {
    int x, y;
    int health;
    char name[32];
} Player;
]]

-- Read struct from memory
local player_addr = 0x600000
local data, size = game.read_mem(player_addr, ffi.sizeof("Player"), "Player")
if data then
    local player = ffi.cast("Player*", data)
    print("Player position:", player.x, player.y)
    print("Player health:", player.health)
    print("Player name:", ffi.string(player.name))
end
```

## Analysis Persistence

```lua
-- Save your function discoveries
game.save("player_functions.lua")       -- Save to specific file
game.save("network_functions.lua")      -- Multiple analysis files
game.save()                             -- Save to default file

-- Load previous analysis
game.load("player_functions.lua")       -- Load specific file
game.load()                             -- Load default file

-- Manage your work
list()                                  -- See what's loaded
game.list()                             -- Detailed function list
```

## Debugging & Logging

```lua
-- View call history
game.show_calls(10)                     -- Last 10 function calls
game.show_memory(5)                     -- Last 5 memory operations

-- Configure debugging
game.debug_config()                     -- Show current settings
game.debug_on(true)                     -- Enable verbose logging
game.debug_on(false)                    -- Disable verbose logging

-- Configure specific logging
game.debug_config({
    log_calls = true,
    log_parameters = true,
    log_return_values = true,
    log_memory_ops = false
})

-- Clear logs
game.clear_logs()                       -- Clear all debug logs
```

## Advanced Usage

### Multiple Calling Conventions

```lua
-- Standard (default)
game.register("StandardFunc", 0x401000, "int(int, int)", "Standard call")

-- Windows API (__stdcall)  
game.register("WinAPIFunc", 0x402000, "int __stdcall(int, int)", "Windows API")

-- Fast call (__fastcall)
game.register("FastFunc", 0x403000, "int __fastcall(int, int)", "Fast call")
```

### Complex Data Types

```lua
local ffi = require('ffi')

-- Define complex structures
ffi.cdef[[
typedef struct {
    int id;
    float x, y, z;
    char name[64];
    struct {
        int health;
        int mana;
    } stats;
} GameEntity;
]]

-- Work with pointers and structures
local entity_ptr = game.call("CreateEntity", 1, 100.0, 200.0, 300.0)
if entity_ptr ~= nil then
    local entity = ffi.cast("GameEntity*", entity_ptr)
    print("Entity ID:", entity.id)
    print("Position:", entity.x, entity.y, entity.z)
    print("Name:", ffi.string(entity.name))
end
```

### Error Handling Best Practices

```lua
-- Always wrap potentially dangerous calls
local function safe_call(func_name, ...)
    local success, result = pcall(game.call, func_name, ...)
    if success then
        return result
    else
        print("ERROR calling", func_name, ":", result)
        return nil
    end
end

-- Use safe_call for risky operations
local gold = safe_call("GetPlayerGold")
if gold then
    print("Gold:", gold)
end
```