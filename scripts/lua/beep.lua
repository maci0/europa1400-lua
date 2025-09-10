-- Europa 1400 - System Beep Utilities
-- 
-- This module provides system beep functionality with support for:
-- - Console thread beeping (simple MessageBeep)
-- - Main process thread beeping (via CreateRemoteThread)
-- - Basic thread information display

local ffi = require('ffi')

-- Windows API definitions for beep functionality
ffi.cdef[[
    // Sound functions
    int MessageBeep(unsigned int uType);
    
    // Process and thread management
    void* GetCurrentProcess();
    unsigned long GetCurrentProcessId();
    void* GetCurrentThread();
    unsigned long GetCurrentThreadId();
    void* CreateRemoteThread(void* hProcess, void* lpThreadAttributes, unsigned long dwStackSize,
                           void* lpStartAddress, void* lpParameter, unsigned long dwCreationFlags,
                           unsigned long* lpThreadId);
    unsigned long WaitForSingleObject(void* hHandle, unsigned long dwMilliseconds);
    int CloseHandle(void* hObject);
]]

-- Load Windows DLLs
local user32 = ffi.load('user32')
local kernel32 = ffi.load('kernel32')

--============================================================================
-- CONSTANTS
--============================================================================

-- Windows MessageBeep sound types
local BEEP_TYPES = {
    OK = 0x00000000,           -- Default system beep
    ERROR = 0x00000010,        -- Error sound
    QUESTION = 0x00000020,     -- Question sound  
    WARNING = 0x00000030,      -- Warning sound
    INFORMATION = 0x00000040   -- Information sound
}

-- Timeout for remote thread operations (milliseconds)
local REMOTE_THREAD_TIMEOUT = 1000

--============================================================================
-- BEEP FUNCTIONS
--============================================================================

-- Simple beep function (runs in console thread)
local function beep_console(beepType)
    beepType = beepType or BEEP_TYPES.OK
    return user32.MessageBeep(beepType)
end

-- Advanced: Execute MessageBeep in the main game process/thread
local function beep_main_process(beepType)
    beepType = beepType or BEEP_TYPES.OK
    
    -- Get current process handle (the game process)
    local hProcess = kernel32.GetCurrentProcess()
    local processId = kernel32.GetCurrentProcessId()
    local currentThreadId = kernel32.GetCurrentThreadId()
    
    print(string.format("Console thread ID: %d", currentThreadId))
    print(string.format("Process ID: %d", processId))
    
    -- Get address of MessageBeep function
    local messageBeepAddr = ffi.cast("void*", user32.MessageBeep)
    
    print(string.format("MessageBeep address: 0x%08X", tonumber(ffi.cast("uintptr_t", messageBeepAddr))))
    
    -- Create a simple thread that calls MessageBeep
    -- This will run in the main process but in a separate thread
    local hThread = kernel32.CreateRemoteThread(
        hProcess,           -- Target process (same process)
        nil,               -- Default security
        0,                 -- Default stack size
        messageBeepAddr,   -- Start address (MessageBeep function)
        ffi.cast("void*", beepType), -- Parameter (beep type)
        0,                 -- Run immediately
        nil                -- Don't need thread ID
    )
    
    if hThread ~= nil then
        print("Successfully created thread in main process")
        -- Wait for the thread to complete (max 1 second)
        kernel32.WaitForSingleObject(hThread, 1000)
        kernel32.CloseHandle(hThread)
        return true
    else
        print("Failed to create thread in main process")
        return false
    end
end

-- Show thread information (basic info for beep functionality)
local function show_thread_info()
    local currentThreadId = kernel32.GetCurrentThreadId()
    local processId = kernel32.GetCurrentProcessId()
    
    print(string.format("Current thread ID: %d", currentThreadId))
    print(string.format("Current process ID: %d", processId))
    
    return {
        thread_id = currentThreadId,
        process_id = processId
    }
end

-- Export functions
return {
    beep = beep_console,
    beep_main = beep_main_process,
    info = show_thread_info,
    types = BEEP_TYPES
}