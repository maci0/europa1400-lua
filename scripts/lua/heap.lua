-- Europa 1400 - Heap Walker
--
-- Enumerate heap allocations via Toolhelp + HeapWalk so you can
-- narrow scans to heap regions instead of the whole address space.
-- Useful when valuescan finds too many hits in image/stack.
--
--   heap = require("heap")    -- or already `heap`
--   heap.list()                       -- all heaps + block counts
--   heap.blocks(heapId, 200)          -- dump first 200 blocks of one heap
--   heap.find(0x12340000)             -- which heap/block owns addr?
--   heap.scan(valuescan.int32, 1500, 64)  -- valuescan limited to heap memory

local ffi = require("ffi")

ffi.cdef[[
    void* GetCurrentProcess(void);
    unsigned long GetCurrentProcessId(void);
    void* CreateToolhelp32Snapshot(unsigned long dwFlags, unsigned long th32ProcessID);
    int Heap32ListFirst(void* hSnapshot, void* lphl);
    int Heap32ListNext(void* hSnapshot, void* lphl);
    int Heap32First(void* lphe, unsigned long th32ProcessID, unsigned long th32HeapID);
    int Heap32Next(void* lphe);
    int CloseHandle(void* hObject);

    typedef struct {
        unsigned long dwSize;
        unsigned long th32ProcessID;
        unsigned long th32HeapID;
        unsigned long dwFlags;
    } HEAPLIST32;

    typedef struct {
        unsigned long dwSize;
        void*         hHandle;
        unsigned long dwAddress;
        unsigned long dwBlockSize;
        unsigned long dwFlags;
        unsigned long dwLockCount;
        unsigned long dwResvd;
        unsigned long th32ProcessID;
        unsigned long th32HeapID;
    } HEAPENTRY32;
]]

local kernel32 = ffi.load("kernel32")

local TH32CS_SNAPHEAPLIST = 0x00000001

local function snap()
    local h = kernel32.CreateToolhelp32Snapshot(TH32CS_SNAPHEAPLIST, kernel32.GetCurrentProcessId())
    if h == ffi.cast("void*", -1) then error("CreateToolhelp32Snapshot failed") end
    return h
end

local M = {}

function M.list()
    local h = snap()
    local hl = ffi.new("HEAPLIST32"); hl.dwSize = ffi.sizeof("HEAPLIST32")
    local out = {}
    local ok = kernel32.Heap32ListFirst(h, hl) ~= 0
    while ok do
        local entry = {
            heapId = tonumber(hl.th32HeapID),
            flags  = tonumber(hl.dwFlags),
            pid    = tonumber(hl.th32ProcessID),
        }
        -- count blocks (cap 50000 to avoid long walk)
        local he = ffi.new("HEAPENTRY32"); he.dwSize = ffi.sizeof("HEAPENTRY32")
        local cnt = 0
        if kernel32.Heap32First(he, hl.th32ProcessID, hl.th32HeapID) ~= 0 then
            repeat cnt = cnt + 1 until kernel32.Heap32Next(he) == 0 or cnt >= 50000
        end
        entry.blocks = cnt
        out[#out+1] = entry
        print(string.format("  heapId %lu  blocks ~%d  flags 0x%X", entry.heapId, entry.blocks, entry.flags))
        ok = kernel32.Heap32ListNext(h, hl) ~= 0
    end
    kernel32.CloseHandle(h)
    if #out == 0 then print("heap.list: no heaps enumerated") end
    return out
end

function M.blocks(heapId, max_blocks)
    if type(heapId) ~= "number" then error("heapId must be number (see heap.list)") end
    max_blocks = max_blocks or 200
    local h = snap()
    local hl = ffi.new("HEAPLIST32"); hl.dwSize = ffi.sizeof("HEAPLIST32")
    local found = false
    local ok = kernel32.Heap32ListFirst(h, hl) ~= 0
    while ok do
        if tonumber(hl.th32HeapID) == heapId then found = true; break end
        ok = kernel32.Heap32ListNext(h, hl) ~= 0
    end
    if not found then kernel32.CloseHandle(h); error("heapId not found: " .. tostring(heapId)) end
    local he = ffi.new("HEAPENTRY32"); he.dwSize = ffi.sizeof("HEAPENTRY32")
    local n = 0
    if kernel32.Heap32First(he, hl.th32ProcessID, hl.th32HeapID) ~= 0 then
        repeat
            n = n + 1
            print(string.format("  [%4d] 0x%08X  size 0x%X (%d)  flags 0x%X",
                n, tonumber(he.dwAddress), tonumber(he.dwBlockSize), tonumber(he.dwBlockSize), tonumber(he.dwFlags)))
            if n >= max_blocks then break end
        until kernel32.Heap32Next(he) == 0
    end
    kernel32.CloseHandle(h)
    return n
end

function M.find(addr)
    local ffi2 = require("ffi")
    local to_addr
    if type(addr) == "number" then to_addr = addr
    elseif type(addr) == "string" then
        local s = addr:gsub("^0[xX]", "")
        to_addr = tonumber(s, 16)
        if not to_addr then error("invalid addr: " .. addr) end
    else error("addr must be number or hex string") end
    local h = snap()
    local hl = ffi2.new("HEAPLIST32"); hl.dwSize = ffi2.sizeof("HEAPLIST32")
    local ok = kernel32.Heap32ListFirst(h, hl) ~= 0
    while ok do
        local he = ffi2.new("HEAPENTRY32"); he.dwSize = ffi2.sizeof("HEAPENTRY32")
        if kernel32.Heap32First(he, hl.th32ProcessID, hl.th32HeapID) ~= 0 then
            repeat
                local a = tonumber(he.dwAddress)
                local sz = tonumber(he.dwBlockSize)
                if to_addr >= a and to_addr < a + sz then
                    print(string.format("0x%08X in heap %lu block 0x%08X +0x%X (off 0x%X)",
                        to_addr, tonumber(hl.th32HeapID), a, sz, to_addr - a))
                    kernel32.CloseHandle(h)
                    return { heapId = tonumber(hl.th32HeapID), blockAddr = a, blockSize = sz, offset = to_addr - a }
                end
            until kernel32.Heap32Next(he) == 0
        end
        ok = kernel32.Heap32ListNext(h, hl) ~= 0
    end
    kernel32.CloseHandle(h)
    print(string.format("0x%08X: not in any heap block", to_addr))
    return nil
end

return M
