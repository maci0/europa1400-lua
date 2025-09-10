-- Europa 1400 Game Function Calling System
-- 
-- This module provides a comprehensive system for registering and calling
-- game functions discovered through reverse engineering with Ghidra.
-- 
-- Features:
-- - Function registration with FFI signatures
-- - Direct function calling in console thread  
-- - Remote thread execution in main game process
-- - Memory read/write operations
-- - Debug logging and call tracking
-- - Persistent save/load of function registrations

local ffi = require('ffi')

-- Windows API definitions for process manipulation and memory operations
ffi.cdef[[
    // Process and thread management
    void* GetCurrentProcess();
    unsigned long GetCurrentProcessId();
    unsigned long GetCurrentThreadId();
    void* CreateRemoteThread(void* hProcess, void* lpThreadAttributes, unsigned long dwStackSize,
                           void* lpStartAddress, void* lpParameter, unsigned long dwCreationFlags,
                           unsigned long* lpThreadId);
    unsigned long WaitForSingleObject(void* hHandle, unsigned long dwMilliseconds);
    int CloseHandle(void* hObject);
    
    // Memory management
    void* VirtualAllocEx(void* hProcess, void* lpAddress, unsigned long dwSize, 
                        unsigned long flAllocationType, unsigned long flProtect);
    int VirtualFreeEx(void* hProcess, void* lpAddress, unsigned long dwSize, unsigned long dwFreeType);
    int WriteProcessMemory(void* hProcess, void* lpBaseAddress, const void* lpBuffer,
                          unsigned long nSize, unsigned long* lpNumberOfBytesWritten);
    int ReadProcessMemory(void* hProcess, const void* lpBaseAddress, void* lpBuffer,
                         unsigned long nSize, unsigned long* lpNumberOfBytesRead);
    
    // Module management
    void* GetModuleHandleA(const char* lpModuleName);
    void* GetProcAddress(void* hModule, const char* lpProcName);
]]

local kernel32 = ffi.load('kernel32')

--============================================================================
-- CONFIGURATION AND STATE
--============================================================================

-- Function registry - stores all registered game functions
local function_registry = {}

-- Debug and logging configuration
local debug_settings = {
    enabled = true,
    log_calls = true,
    log_parameters = true, 
    log_return_values = true,
    log_memory_ops = true,
    max_log_entries = 1000
}

-- Logging storage
local call_log = {}
local memory_log = {}

-- Windows memory constants
local MEM_COMMIT = 0x1000
local MEM_RESERVE = 0x2000  
local MEM_RELEASE = 0x8000
local PAGE_EXECUTE_READWRITE = 0x40

-- Default timeouts (milliseconds)
local DEFAULT_THREAD_TIMEOUT = 5000
local DEFAULT_SAVE_FILE = "lua/functions_save.lua"

--============================================================================
-- UTILITY FUNCTIONS
--============================================================================

-- Count entries in a table
local function table_count(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Validate function signature format
local function validate_signature(signature)
    if not signature or type(signature) ~= "string" then
        return false, "Signature must be a string"
    end
    
    -- Basic validation - should contain parentheses
    if not signature:match("%(.*%)") then
        return false, "Signature must contain parentheses, e.g., 'int()' or 'void(int, int)'"
    end
    
    return true
end

-- Format function parameters for display
local function format_parameters(...)
    local args = {...}
    local formatted = {}
    
    for i, arg in ipairs(args) do
        local arg_str
        if type(arg) == "number" then
            -- Show large numbers in hex format
            if arg > 65535 then
                arg_str = string.format("0x%08X (%d)", arg, arg)
            else
                arg_str = tostring(arg)
            end
        elseif type(arg) == "string" then
            arg_str = '"' .. arg .. '"'
        elseif type(arg) == "cdata" then
            arg_str = string.format("cdata: 0x%08X", tonumber(ffi.cast("uintptr_t", arg)))
        else
            arg_str = tostring(arg)
        end
        table.insert(formatted, arg_str)
    end
    
    return table.concat(formatted, ", ")
end

--============================================================================
-- LOGGING SYSTEM  
--============================================================================
local function log_entry(entry_type, data)
    if not debug_settings.enabled then return end
    
    local timestamp = os.date("%H:%M:%S")
    local entry = {
        timestamp = timestamp,
        type = entry_type,
        data = data
    }
    
    if entry_type == "call" and debug_settings.log_calls then
        table.insert(call_log, entry)
        if #call_log > debug_settings.max_log_entries then
            table.remove(call_log, 1)
        end
        
        if debug_settings.log_calls then
            print(string.format("[%s] CALL: %s", timestamp, data.summary))
        end
    elseif entry_type == "memory" and debug_settings.log_memory_ops then
        table.insert(memory_log, entry)
        if #memory_log > debug_settings.max_log_entries then
            table.remove(memory_log, 1)
        end
        
        if debug_settings.log_memory_ops then
            print(string.format("[%s] MEMORY: %s", timestamp, data.summary))
        end
    end
end

local function format_parameters(...)
    local args = {...}
    local formatted = {}
    
    for i, arg in ipairs(args) do
        local arg_str
        if type(arg) == "number" then
            if arg > 65535 then
                arg_str = string.format("0x%08X (%d)", arg, arg)
            else
                arg_str = tostring(arg)
            end
        elseif type(arg) == "string" then
            arg_str = '"' .. arg .. '"'
        else
            arg_str = tostring(arg)
        end
        table.insert(formatted, arg_str)
    end
    
    return table.concat(formatted, ", ")
end

--============================================================================
-- CORE FUNCTIONS
--============================================================================

-- Register a game function for calling
-- @param name: Function name (for reference)
-- @param address: Function address from Ghidra (can be hex string or number)  
-- @param signature: FFI function signature, e.g. "int(int, int)"
-- @param description: Optional description
function register_function(name, address, signature, description)
    -- Input validation
    if not name or type(name) ~= "string" or name == "" then
        error("Function name must be a non-empty string")
    end
    
    if not address then
        error("Function address is required")
    end
    
    -- Validate signature
    local valid, err = validate_signature(signature)
    if not valid then
        error("Invalid signature: " .. err)
    end
    
    -- Convert hex string address to number if needed
    local addr_num = address
    if type(address) == "string" then
        addr_num = tonumber(address, 16)
        if not addr_num then
            error("Invalid address format: " .. address)
        end
    elseif type(address) ~= "number" then
        error("Address must be a number or hex string")
    end
    
    -- Validate address range (basic sanity check)
    if addr_num <= 0 or addr_num > 0xFFFFFFFF then
        error(string.format("Address out of valid range: 0x%08X", addr_num))
    end
    
    -- Check if function already exists
    if function_registry[name] then
        print(string.format("Warning: Overwriting existing function '%s'", name))
    end
    
    -- Create FFI function pointer with error handling
    local success, func_ptr = pcall(function()
        return ffi.cast(signature .. "*", addr_num)
    end)
    
    if not success then
        error("Failed to create function pointer: " .. tostring(func_ptr))
    end
    
    -- Store function information
    function_registry[name] = {
        address = addr_num,
        signature = signature,
        func_ptr = func_ptr,
        description = description or "No description",
        registered_time = os.time()
    }
    
    -- Success message
    print(string.format("✓ Registered function: %s", name))
    print(string.format("  Address: 0x%08X", addr_num))
    print(string.format("  Signature: %s", signature))
    if description and description ~= "" then
        print(string.format("  Description: %s", description))
    end
end

-- Call a registered function directly (in console thread)
-- @param name: Function name
-- @param ...: Function arguments
function call_function(name, ...)
    local func_info = function_registry[name]
    if not func_info then
        error("Function '" .. name .. "' not registered")
    end
    
    local params = format_parameters(...)
    local call_info = {
        function_name = name,
        address = func_info.address,
        thread_type = "console",
        parameters = params,
        signature = func_info.signature
    }
    
    if debug_settings.log_calls then
        call_info.summary = string.format("%s(%s) [console thread] @ 0x%08X", 
                                        name, params, func_info.address)
        log_entry("call", call_info)
    end
    
    local start_time = os.clock()
    local success, result = pcall(func_info.func_ptr, ...)
    local end_time = os.clock()
    
    call_info.execution_time = (end_time - start_time) * 1000 -- ms
    call_info.success = success
    call_info.result = result
    
    if debug_settings.log_return_values then
        print(string.format("  -> Result: %s (%.2fms)", 
                          tostring(result), call_info.execution_time))
    end
    
    if not success then
        print(string.format("  -> ERROR: %s", tostring(result)))
        error(result)
    end
    
    return result
end

-- Call a registered function in the main game process (new thread)
-- Note: This works best with simple functions that take basic parameters
-- @param name: Function name
-- @param param: Single parameter to pass (limitations of CreateRemoteThread)
function call_function_main(name, param)
    local func_info = function_registry[name]
    if not func_info then
        error("Function '" .. name .. "' not registered")
    end
    
    local call_info = {
        function_name = name,
        address = func_info.address,
        thread_type = "main_process",
        parameters = tostring(param or "none"),
        signature = func_info.signature
    }
    
    if debug_settings.log_calls then
        call_info.summary = string.format("%s(%s) [main process] @ 0x%08X", 
                                        name, tostring(param or "none"), func_info.address)
        log_entry("call", call_info)
    end
    
    local hProcess = kernel32.GetCurrentProcess()
    local start_time = os.clock()
    
    -- Create remote thread to execute the function
    local hThread = kernel32.CreateRemoteThread(
        hProcess,
        nil,
        0,
        ffi.cast("void*", func_info.address),
        ffi.cast("void*", param or 0),
        0,
        nil
    )
    
    local success = false
    local result = nil
    
    if hThread ~= nil then
        -- Wait for completion (max 5 seconds)
        result = kernel32.WaitForSingleObject(hThread, 5000)
        kernel32.CloseHandle(hThread)
        success = (result == 0) -- 0 = success
        
        local end_time = os.clock()
        call_info.execution_time = (end_time - start_time) * 1000
        call_info.success = success
        call_info.wait_result = result
        
        if debug_settings.log_return_values then
            print(string.format("  -> Thread result: %s (%.2fms)", 
                              success and "SUCCESS" or "TIMEOUT/ERROR", call_info.execution_time))
        end
    else
        call_info.success = false
        call_info.error = "Failed to create remote thread"
        
        if debug_settings.log_return_values then
            print("  -> ERROR: Failed to create remote thread")
        end
    end
    
    return success
end

-- List all registered functions
function list_functions()
    print("Registered game functions:")
    print("=" .. string.rep("=", 50))
    
    if next(function_registry) == nil then
        print("  No functions registered")
        return
    end
    
    for name, info in pairs(function_registry) do
        print(string.format("  %s", name))
        print(string.format("    Address: 0x%08X", info.address))
        print(string.format("    Signature: %s", info.signature))
        print(string.format("    Description: %s", info.description))
        print("")
    end
end

-- Read memory at a specific address
-- @param address: Memory address
-- @param size: Number of bytes to read
-- @param type: FFI type (e.g., "int", "char", "float")
function read_memory(address, size, ffi_type)
    local addr_num = type(address) == "string" and tonumber(address, 16) or address
    local buffer = ffi.new(ffi_type .. "[?]", size / ffi.sizeof(ffi_type))
    local hProcess = kernel32.GetCurrentProcess()
    
    local mem_info = {
        operation = "READ",
        address = addr_num,
        size = size,
        type = ffi_type
    }
    
    local bytes_read = ffi.new("unsigned long[1]")
    local success = kernel32.ReadProcessMemory(
        hProcess,
        ffi.cast("void*", addr_num),
        buffer,
        size,
        bytes_read
    )
    
    mem_info.success = (success ~= 0)
    mem_info.bytes_processed = bytes_read[0]
    
    if debug_settings.log_memory_ops then
        mem_info.summary = string.format("READ 0x%08X (%d bytes, %s) -> %s", 
                                       addr_num, size, ffi_type, 
                                       success ~= 0 and "SUCCESS" or "FAILED")
        log_entry("memory", mem_info)
    end
    
    if success ~= 0 then
        return buffer, bytes_read[0]
    else
        return nil, 0
    end
end

-- Write memory at a specific address
-- @param address: Memory address
-- @param data: Data to write (FFI array or single value)
-- @param size: Number of bytes to write
function write_memory(address, data, size)
    local addr_num = type(address) == "string" and tonumber(address, 16) or address
    local hProcess = kernel32.GetCurrentProcess()
    
    local mem_info = {
        operation = "WRITE",
        address = addr_num,
        size = size,
        data = tostring(data)
    }
    
    local bytes_written = ffi.new("unsigned long[1]")
    local success = kernel32.WriteProcessMemory(
        hProcess,
        ffi.cast("void*", addr_num),
        data,
        size,
        bytes_written
    )
    
    mem_info.success = (success ~= 0)
    mem_info.bytes_processed = bytes_written[0]
    
    if debug_settings.log_memory_ops then
        mem_info.summary = string.format("WRITE 0x%08X (%d bytes) -> %s", 
                                       addr_num, size, 
                                       success ~= 0 and "SUCCESS" or "FAILED")
        log_entry("memory", mem_info)
    end
    
    return success ~= 0, bytes_written[0]
end

-- Helper function to get module base address
function get_module_base(module_name)
    local hModule = kernel32.GetModuleHandleA(module_name)
    if hModule ~= nil then
        return tonumber(ffi.cast("uintptr_t", hModule))
    end
    return nil
end

-- Save function registrations to file
-- @param filename: File to save to (default: "functions.lua")
function save_functions(filename)
    filename = filename or "lua/functions_save.lua"
    
    local file = io.open(filename, "w")
    if not file then
        error("Could not open file for writing: " .. filename)
    end
    
    file:write("-- Auto-generated function registrations\n")
    file:write("-- Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n")
    file:write("local game = require('lua/gamecalls')\n\n")
    
    for name, info in pairs(function_registry) do
        file:write(string.format('game.register("%s", 0x%08X, "%s", "%s")\n',
                                name, info.address, info.signature, info.description))
    end
    
    file:write("\nreturn game\n")
    file:close()
    
    print(string.format("Saved %d function registrations to: %s", 
                       table_count(function_registry), filename))
end

-- Load function registrations from file
-- @param filename: File to load from
function load_functions(filename)
    filename = filename or "lua/functions_save.lua"
    
    local chunk, err = loadfile(filename)
    if not chunk then
        error("Could not load functions file: " .. (err or "unknown error"))
    end
    
    local old_count = table_count(function_registry)
    chunk() -- Execute the file
    local new_count = table_count(function_registry)
    
    print(string.format("Loaded function registrations from: %s", filename))
    print(string.format("Functions loaded: %d (total: %d)", new_count - old_count, new_count))
end

-- Debug and logging management functions
function debug_enable(enabled)
    debug_settings.enabled = enabled ~= false
    print("Debug logging: " .. (debug_settings.enabled and "ENABLED" or "DISABLED"))
end

function debug_config(config)
    if config then
        for key, value in pairs(config) do
            if debug_settings[key] ~= nil then
                debug_settings[key] = value
                print(string.format("Debug setting %s: %s", key, tostring(value)))
            end
        end
    else
        print("Current debug settings:")
        for key, value in pairs(debug_settings) do
            print(string.format("  %s: %s", key, tostring(value)))
        end
    end
end

function show_call_log(count)
    count = count or 10
    print(string.format("Recent function calls (last %d):", count))
    print(string.rep("-", 60))
    
    local start_idx = math.max(1, #call_log - count + 1)
    for i = start_idx, #call_log do
        local entry = call_log[i]
        print(string.format("[%s] %s", entry.timestamp, entry.data.summary))
        
        if entry.data.execution_time then
            print(string.format("    Time: %.2fms, Success: %s", 
                              entry.data.execution_time, tostring(entry.data.success)))
        end
    end
    
    if #call_log == 0 then
        print("  No function calls logged")
    end
end

function show_memory_log(count)
    count = count or 10
    print(string.format("Recent memory operations (last %d):", count))
    print(string.rep("-", 60))
    
    local start_idx = math.max(1, #memory_log - count + 1)
    for i = start_idx, #memory_log do
        local entry = memory_log[i]
        print(string.format("[%s] %s", entry.timestamp, entry.data.summary))
        
        if entry.data.bytes_processed then
            print(string.format("    Bytes: %d, Success: %s", 
                              entry.data.bytes_processed, tostring(entry.data.success)))
        end
    end
    
    if #memory_log == 0 then
        print("  No memory operations logged")
    end
end

function clear_logs()
    call_log = {}
    memory_log = {}
    print("All logs cleared")
end

-- Helper function to count table entries
function table_count(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Export the API
return {
    -- Core functions
    register = register_function,
    call = call_function,
    call_main = call_function_main,
    list = list_functions,
    read_mem = read_memory,
    write_mem = write_memory,
    get_module_base = get_module_base,
    
    -- Save/Load functions
    save = save_functions,
    load = load_functions,
    
    -- Debug functions
    debug_on = debug_enable,
    debug_config = debug_config,
    show_calls = show_call_log,
    show_memory = show_memory_log,
    clear_logs = clear_logs
}