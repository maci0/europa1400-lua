-- Europa 1400 - System Information and Diagnostics
--
-- This module provides comprehensive system diagnostic functions for
-- reverse engineering and game analysis:
-- - System hardware information
-- - Memory status and usage
-- - Loaded module enumeration
-- - Window information
-- - Process and thread details

local ffi = require('ffi')

-- Windows API definitions for system diagnostics
ffi.cdef[[
    // Process and thread information
    void* GetCurrentProcess();
    unsigned long GetCurrentProcessId();
    void* GetCurrentThread();
    unsigned long GetCurrentThreadId();
    
    // Module management
    void* GetModuleHandleA(const char* lpModuleName);
    unsigned long GetModuleFileNameA(void* hModule, char* lpFilename, unsigned long nSize);
    void* GetProcAddress(void* hModule, const char* lpProcName);
    
    // System information
    int GetSystemInfo(void* lpSystemInfo);
    int GlobalMemoryStatusEx(void* lpBuffer);
    
    // Window management
    void* GetConsoleWindow();
    unsigned long GetWindowThreadProcessId(void* hWnd, unsigned long* lpdwProcessId);
    int GetWindowTextA(void* hWnd, char* lpString, int nMaxCount);
    void* FindWindowA(const char* lpClassName, const char* lpWindowName);
    int EnumWindows(void* lpEnumFunc, uintptr_t lParam);
    int IsWindowVisible(void* hWnd);
    int GetClassNameA(void* hWnd, char* lpClassName, int nMaxCount);
    void* GetWindow(void* hWnd, unsigned int uCmd);
    void* GetParent(void* hWnd);
    
    // System information structures
    typedef struct {
        unsigned short wProcessorArchitecture;
        unsigned short wReserved;
        unsigned long dwPageSize;
        void* lpMinimumApplicationAddress;
        void* lpMaximumApplicationAddress;
        uintptr_t dwActiveProcessorMask;
        unsigned long dwNumberOfProcessors;
        unsigned long dwProcessorType;
        unsigned long dwAllocationGranularity;
        unsigned short wProcessorLevel;
        unsigned short wProcessorRevision;
    } SYSTEM_INFO;
    
    typedef struct {
        unsigned long dwLength;
        unsigned long dwMemoryLoad;
        uint64_t ullTotalPhys;
        uint64_t ullAvailPhys;
        uint64_t ullTotalPageFile;
        uint64_t ullAvailPageFile;
        uint64_t ullTotalVirtual;
        uint64_t ullAvailVirtual;
        uint64_t ullAvailExtendedVirtual;
    } MEMORYSTATUSEX;
]]

-- Load Windows system DLLs
local user32 = ffi.load('user32')
local kernel32 = ffi.load('kernel32')

--============================================================================
-- CONSTANTS
--============================================================================

-- Window enumeration constants
local GW_HWNDFIRST = 0
local GW_HWNDLAST = 1
local GW_HWNDNEXT = 2
local GW_HWNDPREV = 3
local GW_OWNER = 4
local GW_CHILD = 5

--============================================================================
-- UTILITY FUNCTIONS
--============================================================================

-- Format bytes in human-readable units
local function format_bytes(bytes)
    if bytes > 1024^3 then
        return string.format("%.2f GB", bytes / (1024^3))
    elseif bytes > 1024^2 then
        return string.format("%.2f MB", bytes / (1024^2))
    elseif bytes > 1024 then
        return string.format("%.2f KB", bytes / 1024)
    else
        return string.format("%d bytes", bytes)
    end
end

-- Create a separator line
local function separator(length, char)
    return (char or "="):rep(length or 50)
end

--============================================================================
-- DIAGNOSTIC FUNCTIONS  
--============================================================================

-- Show thread information
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

-- Show detailed system information
local function show_system_info()
    print("System Information:")
    print("=" .. string.rep("=", 40))
    
    -- Get system info
    local sysInfo = ffi.new("SYSTEM_INFO")
    kernel32.GetSystemInfo(sysInfo)
    
    print(string.format("Processor Architecture: %d", sysInfo.wProcessorArchitecture))
    print(string.format("Number of Processors: %d", sysInfo.dwNumberOfProcessors))
    print(string.format("Page Size: %d bytes", sysInfo.dwPageSize))
    print(string.format("Allocation Granularity: %d bytes", sysInfo.dwAllocationGranularity))
    print(string.format("Min App Address: 0x%08X", tonumber(ffi.cast("uintptr_t", sysInfo.lpMinimumApplicationAddress))))
    print(string.format("Max App Address: 0x%08X", tonumber(ffi.cast("uintptr_t", sysInfo.lpMaximumApplicationAddress))))
    
    return {
        architecture = sysInfo.wProcessorArchitecture,
        processors = sysInfo.dwNumberOfProcessors,
        page_size = sysInfo.dwPageSize,
        allocation_granularity = sysInfo.dwAllocationGranularity,
        min_app_address = tonumber(ffi.cast("uintptr_t", sysInfo.lpMinimumApplicationAddress)),
        max_app_address = tonumber(ffi.cast("uintptr_t", sysInfo.lpMaximumApplicationAddress))
    }
end

-- Show memory status
local function show_memory_info()
    print("Memory Status")
    print(separator(30))
    
    local memStatus = ffi.new("MEMORYSTATUSEX")
    memStatus.dwLength = ffi.sizeof("MEMORYSTATUSEX")
    
    if kernel32.GlobalMemoryStatusEx(memStatus) ~= 0 then
        print(string.format("Memory Load: %d%%", memStatus.dwMemoryLoad))
        print(string.format("Total Physical: %s", format_bytes(tonumber(memStatus.ullTotalPhys))))
        print(string.format("Available Physical: %s", format_bytes(tonumber(memStatus.ullAvailPhys))))
        print(string.format("Total Virtual: %s", format_bytes(tonumber(memStatus.ullTotalVirtual))))
        print(string.format("Available Virtual: %s", format_bytes(tonumber(memStatus.ullAvailVirtual))))
        
        return {
            memory_load = memStatus.dwMemoryLoad,
            total_physical = tonumber(memStatus.ullTotalPhys),
            available_physical = tonumber(memStatus.ullAvailPhys),
            total_virtual = tonumber(memStatus.ullTotalVirtual),
            available_virtual = tonumber(memStatus.ullAvailVirtual)
        }
    else
        print("❌ Failed to retrieve memory status")
        return nil
    end
end

-- List loaded modules
local function list_modules()
    print("Loaded Modules:")
    print("=" .. string.rep("=", 30))
    
    local modules = {}
    local common_modules = {
        "kernel32.dll", "user32.dll", "ntdll.dll", "advapi32.dll",
        "gdi32.dll", "comctl32.dll", "ole32.dll", "shell32.dll",
        "msvcrt.dll", "d3d8.dll", "d3d9.dll", "opengl32.dll",
        "winmm.dll", "dsound.dll", "dinput8.dll"
    }
    
    for _, module_name in ipairs(common_modules) do
        local hModule = kernel32.GetModuleHandleA(module_name)
        if hModule ~= nil then
            local filename = ffi.new("char[?]", 260)
            local length = kernel32.GetModuleFileNameA(hModule, filename, 260)
            if length > 0 then
                local base_addr = tonumber(ffi.cast("uintptr_t", hModule))
                print(string.format("  %-15s: 0x%08X - %s", module_name, base_addr, ffi.string(filename)))
                modules[module_name] = {
                    base_address = base_addr,
                    path = ffi.string(filename)
                }
            end
        end
    end
    
    return modules
end

-- Get window information (title, class, visibility)
local function get_window_info(hwnd)
    local title = ffi.new("char[?]", 256)
    local className = ffi.new("char[?]", 256)
    
    user32.GetWindowTextA(hwnd, title, 256)
    user32.GetClassNameA(hwnd, className, 256)
    
    local isVisible = user32.IsWindowVisible(hwnd) ~= 0
    local parent = user32.GetParent(hwnd)
    
    return {
        handle = tonumber(ffi.cast("uintptr_t", hwnd)),
        title = ffi.string(title),
        class_name = ffi.string(className),
        visible = isVisible,
        parent = parent and tonumber(ffi.cast("uintptr_t", parent)) or nil
    }
end

-- Window enumeration callback function
local enum_callback = ffi.cast("int(__stdcall *)(void*, uintptr_t)", function(hwnd, lParam)
    local currentPid = kernel32.GetCurrentProcessId()
    local windowPid = ffi.new("unsigned long[1]")
    local threadId = user32.GetWindowThreadProcessId(hwnd, windowPid)
    
    -- Only process windows from our process
    if windowPid[0] == currentPid then
        local windows = ffi.cast("void**", lParam) -- Cast lParam to get our windows table pointer
        local windowInfo = get_window_info(hwnd)
        windowInfo.thread_id = threadId
        windowInfo.process_id = windowPid[0]
        
        -- We need to store this somehow - let's use a global table for the callback
        if not _G.temp_windows then _G.temp_windows = {} end
        table.insert(_G.temp_windows, windowInfo)
    end
    
    return 1 -- Continue enumeration
end)

-- Enumerate all windows belonging to the current process
local function show_window_info()
    print("Process Window Information")
    print(separator(40))
    
    local currentPid = kernel32.GetCurrentProcessId()
    print(string.format("Current Process ID: %d", currentPid))
    print()
    
    -- Initialize temporary storage for callback
    _G.temp_windows = {}
    
    -- Enumerate all windows
    user32.EnumWindows(enum_callback, 0)
    
    local windows = _G.temp_windows or {}
    _G.temp_windows = nil -- Clean up
    
    if #windows == 0 then
        print("❌ No windows found for this process")
        return {process_id = currentPid, windows = {}}
    end
    
    -- Sort windows: visible first, then by title
    table.sort(windows, function(a, b)
        if a.visible ~= b.visible then
            return a.visible -- Visible windows first
        end
        return a.title < b.title
    end)
    
    -- Display windows with categorization
    local visibleCount = 0
    local hiddenCount = 0
    
    print("VISIBLE WINDOWS:")
    for i, win in ipairs(windows) do
        if win.visible then
            visibleCount = visibleCount + 1
            print(string.format("  [%d] Handle: 0x%08X", visibleCount, win.handle))
            print(string.format("      Title: '%s'", win.title ~= "" and win.title or "(No title)"))
            print(string.format("      Class: %s", win.class_name))
            print(string.format("      Thread ID: %d", win.thread_id))
            if win.parent then
                print(string.format("      Parent: 0x%08X", win.parent))
            end
            print()
        end
    end
    
    if visibleCount == 0 then
        print("  No visible windows")
        print()
    end
    
    print("HIDDEN WINDOWS:")
    for i, win in ipairs(windows) do
        if not win.visible then
            hiddenCount = hiddenCount + 1
            print(string.format("  [%d] Handle: 0x%08X - '%s' (%s)", 
                  hiddenCount, win.handle, 
                  win.title ~= "" and win.title or "(No title)",
                  win.class_name))
        end
    end
    
    if hiddenCount == 0 then
        print("  No hidden windows")
    end
    
    print()
    print(string.format("Summary: %d visible, %d hidden, %d total windows", 
          visibleCount, hiddenCount, #windows))
    
    return {
        process_id = currentPid,
        windows = windows,
        visible_count = visibleCount,
        hidden_count = hiddenCount,
        total_count = #windows
    }
end

-- Show process memory layout
local function show_memory_layout()
    print("Memory Layout:")
    print("=" .. string.rep("=", 30))
    
    local modules = {}
    local common_modules = {"kernel32.dll", "user32.dll", "ntdll.dll"}
    
    for _, module_name in ipairs(common_modules) do
        local hModule = kernel32.GetModuleHandleA(module_name)
        if hModule ~= nil then
            local base_addr = tonumber(ffi.cast("uintptr_t", hModule))
            print(string.format("  %-12s: 0x%08X", module_name, base_addr))
            modules[module_name] = base_addr
        end
    end
    
    -- Show some key addresses
    local currentProcess = kernel32.GetCurrentProcess()
    local currentThread = kernel32.GetCurrentThread()
    
    print(string.format("  Current Process: 0x%08X", tonumber(ffi.cast("uintptr_t", currentProcess))))
    print(string.format("  Current Thread:  0x%08X", tonumber(ffi.cast("uintptr_t", currentThread))))
    
    return modules
end

-- Export functions
return {
    thread_info = show_thread_info,
    info = show_system_info,
    memory_info = show_memory_info,
    list_modules = list_modules,
    window_info = show_window_info,
    memory_layout = show_memory_layout
}