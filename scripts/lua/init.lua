-- Europa 1400 Lua Console - Initialization Script
-- Loads all required modules and sets up the console environment

local ffi = require('ffi')

-- Load basic Windows API for compatibility
ffi.cdef[[
    void __stdcall Sleep(unsigned long dwMilliseconds);
]]
k32 = ffi.load('kernel32')

-- Load core modules
game = dofile('lua/game_functions.lua')    -- Game function registration system
system = dofile('lua/sysinfo.lua')        -- System diagnostic functions

-- Load utility modules  
local beep_module = dofile('lua/beep.lua')
beep = beep_module.beep                    -- System beep (console thread)
beep_main = beep_module.beep_main          -- System beep (main process)
thread_info = beep_module.info             -- Thread information
beep_types = beep_module.types             -- Beep type constants

-- Console help function
function help()
    local separator = "=" .. string.rep("=", 60)
    
    print("Europa 1400 Lua Console - Available Commands")
    print(separator)
    print()
    
    -- Game function system
    print("GAME FUNCTIONS (game.*)")
    print("  game.register(name, addr, sig, desc)  Register game function from Ghidra")
    print("  game.call(name, ...)                  Call registered function")
    print("  game.list()                           List all registered functions")
    print("  game.save([filename])                 Save functions to file")
    print("  game.load([filename])                 Load functions from file")
    print()
    
    -- System diagnostic functions  
    print("SYSTEM DIAGNOSTICS (system.*)")
    print("  system.info()           System information (CPU, memory limits)")
    print("  system.memory_info()    Memory status (RAM usage)")
    print("  system.list_modules()   List loaded DLLs with addresses")
    print("  system.window_info()    Window information") 
    print("  system.memory_layout()  Memory layout overview")
    print("  system.thread_info()    Thread information")
    print()
    
    -- Utility functions
    print("UTILITIES")
    print("  help()                  Show this help")
    print("  list()                  Alias for game.list()")
    print("  beep()                  System beep (console thread)")
    print("  thread_info()           Basic thread info")
    print()
    
    -- Usage examples
    print("EXAMPLES")
    print('  game.register("GetGold", 0x401000, "int()", "Get player gold")')
    print('  local gold = game.call("GetGold")')
    print('  system.memory_info()')
    print('  game.save("my_functions.lua")')
    print(separator)
end

function list()
    game.list()
end

-- Console initialization and welcome message
local function show_welcome()
    local separator = "=" .. string.rep("=", 50)
    
    print()
    print("Europa 1400 Lua Console")
    print(separator)
    print("Game Function Analysis & Reverse Engineering Tool")
    print()
    print("Quick Start:")
    print("  help()              - Show all available commands")
    print("  game.list()         - List registered functions")
    print("  system.info()       - Show system information")
    print()
    print("Ready! Type help() for complete command reference.")
    print(separator)
    print()
end

-- Initialize console
beep()
show_welcome()