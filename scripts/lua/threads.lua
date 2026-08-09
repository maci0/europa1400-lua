-- Europa 1400 - Thread Inspector
--
-- Enumerate threads for the current process so you can correlate
-- window/thread ids (system.window_info) with game logic threads
-- and target the right thread for hooking/watching.
--
--   threads = dofile('lua/threads.lua')  -- or already `threads`
--   threads.list()
--   threads.current()                     -- current thread id

local ffi = require("ffi")

ffi.cdef[[
    void* GetCurrentProcess(void);
    unsigned long GetCurrentProcessId(void);
    unsigned long GetCurrentThreadId(void);
    void* CreateToolhelp32Snapshot(unsigned long dwFlags, unsigned long th32ProcessID);
    int Thread32First(void* hSnapshot, void* lpte);
    int Thread32Next(void* hSnapshot, void* lpte);
    int CloseHandle(void* hObject);

    typedef struct {
        unsigned long dwSize;
        unsigned long cntUsage;
        unsigned long th32ThreadID;
        unsigned long th32OwnerProcessID;
        long tpBasePri;
        long tpDeltaPri;
        unsigned long dwFlags;
    } THREADENTRY32;
]]

local kernel32 = ffi.load("kernel32")
local TH32CS_SNAPTHREAD = 0x00000004

local M = {}

function M.list()
    local pid = kernel32.GetCurrentProcessId()
    local h = kernel32.CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0)
    if h == ffi.cast("void*", -1) then error("CreateToolhelp32Snapshot failed") end
    local te = ffi.new("THREADENTRY32"); te.dwSize = ffi.sizeof("THREADENTRY32")
    local out = {}
    local ok = kernel32.Thread32First(h, te) ~= 0
    while ok do
        if tonumber(te.th32OwnerProcessID) == tonumber(pid) then
            out[#out+1] = {
                tid = tonumber(te.th32ThreadID),
                pri = tonumber(te.tpBasePri),
                delta = tonumber(te.tpDeltaPri),
            }
        end
        ok = kernel32.Thread32Next(h, te) ~= 0
    end
    kernel32.CloseHandle(h)
    local cur = tonumber(kernel32.GetCurrentThreadId())
    print(string.format("Threads for PID %lu: %d", pid, #out))
    for _, t in ipairs(out) do
        local mark = (t.tid == cur) and " <- current" or ""
        print(string.format("  TID %5lu  pri %2d  delta %+d%s", t.tid, t.pri, t.delta, mark))
    end
    if #out == 0 then print("  (none — snapshot may need PROCESS query privilege)") end
    return out
end

function M.current()
    local tid = tonumber(kernel32.GetCurrentThreadId())
    local pid = tonumber(kernel32.GetCurrentProcessId())
    print(string.format("Current TID %lu  PID %lu", tid, pid))
    return tid, pid
end

return M
