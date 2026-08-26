-- Europa 1400 - VTable Dumper
--
-- Finds likely C++ vtables (arrays of 3+ code pointers into executable
-- regions) without symbols. Useful to map game classes and their
-- virtual methods before drilling with disasm/finder/trace.
--
--   vtable = require("vtable")
--   vtable.scan(0x00400000, 0x800000, 3)          -- 3+ consecutive code ptrs
--   vtable.at(0x00AB1234, 12)                     -- dump 12 entries at addr
--   vtable.follow(0x00AB1234, "thiscall(int)")    -- read ptr then try trace stub

local ffi = require("ffi")

ffi.cdef[[
    void* GetModuleHandleA(const char* lpModuleName);
    void* GetCurrentProcess(void);
    int   VirtualQueryEx(void* hProcess, const void* lpAddress, void* lpBuffer, unsigned long dwLength);
    int   ReadProcessMemory(void* hProcess, const void* lpBaseAddress, void* lpBuffer,
                            unsigned long nSize, unsigned long* lpNumberOfBytesRead);
    typedef struct {
        void*         BaseAddress;
        void*         AllocationBase;
        unsigned long AllocationProtect;
        unsigned long RegionSize;
        unsigned long State;
        unsigned long Protect;
        unsigned long Type;
    } MEMORY_BASIC_INFORMATION;
]]

local kernel32 = ffi.load("kernel32")
local has_bit, bit = pcall(require, "bit")
if not has_bit then bit = _G.bit end

local MEM_COMMIT    = 0x1000
local PAGE_GUARD    = 0x100
local PAGE_NOACCESS = 0x01
local PAGE_EXEC     = 0x10
local PAGE_EXEC_R   = 0x20
local PAGE_EXEC_RW  = 0x40
local PAGE_EXEC_RC  = 0x80

local function to_addr(v)
    if type(v) == "number" then return v end
    if type(v) ~= "string" then error("address must be number or hex string") end
    local s = v:gsub("^%s+", ""):gsub("%s+$", "")
    local mod, off = s:match("^(.+)%+(.+)$")
    if mod then
        mod = mod:gsub("^%s+", ""):gsub("%s+$", "")
        off = off:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^0[xX]", "")
        local base
        if mod == "" or mod:lower() == "main" or mod:lower() == "exe" then
            base = tonumber(ffi.cast("uintptr_t", kernel32.GetModuleHandleA(nil)))
        else
            local h = kernel32.GetModuleHandleA(mod)
            if h == nil then error("module not loaded: " .. mod) end
            base = tonumber(ffi.cast("uintptr_t", h))
        end
        local delta = tonumber(off, 16) or tonumber(off)
        if not delta then error("invalid offset in '" .. v .. "'") end
        return base + delta
    end
    s = s:gsub("^0[xX]", "")
    local n = tonumber(s, 16)
    if not n then error("invalid address: " .. v) end
    return n
end

local function exec_regions()
    local hProc = kernel32.GetCurrentProcess()
    local mbi = ffi.new("MEMORY_BASIC_INFORMATION")
    local out = {}
    local addr = 0
    while addr < 0x7FFF0000 do
        if kernel32.VirtualQueryEx(hProc, ffi.cast("void*", addr), mbi, ffi.sizeof(mbi)) == 0 then break end
        local prot = tonumber(mbi.Protect)
        local st   = tonumber(mbi.State)
        local is_exec = prot == PAGE_EXEC or prot == PAGE_EXEC_R or prot == PAGE_EXEC_RW or prot == PAGE_EXEC_RC
        if st == MEM_COMMIT and is_exec and bit.band(prot, PAGE_GUARD) == 0 then
            out[#out+1] = { base = tonumber(ffi.cast("uintptr_t", mbi.BaseAddress)), size = tonumber(mbi.RegionSize) }
        end
        addr = tonumber(ffi.cast("uintptr_t", mbi.BaseAddress)) + tonumber(mbi.RegionSize)
        if addr == 0 then break end
    end
    return out
end

local function is_code_ptr(ptr, execs)
    if ptr < 0x00400000 or ptr >= 0x80000000 then return false end
    for _, r in ipairs(execs) do
        if ptr >= r.base and ptr < r.base + r.size then return true end
    end
    return false
end

local function read_u32(addr)
    local out = ffi.new("uint32_t[1]")
    local got = ffi.new("unsigned long[1]")
    if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", addr), out, 4, got) == 0 then return nil end
    if tonumber(got[0]) ~= 4 then return nil end
    return tonumber(out[0])
end

local M = {}

function M.at(addr, count)
    addr = to_addr(addr); count = count or 16
    if count <= 0 or count > 128 then error("count out of range 1..128") end
    print(string.format("vtable @ 0x%08X  (%d entries):", addr, count))
    for i = 0, count-1 do
        local v = read_u32(addr + i*4)
        if not v then print(string.format("  [%2d] <read failed>", i)); break end
        print(string.format("  [%2d] 0x%08X", i, v))
    end
end

function M.scan(base, size, min_entries, max_hits)
    base = base and to_addr(base) or 0x00400000
    size = size or 0x800000
    min_entries = min_entries or 3
    max_hits = max_hits or 200
    if min_entries < 2 or min_entries > 16 then error("min_entries 2..16") end
    local execs = exec_regions()
    if #execs == 0 then print("vtable.scan: no executable regions enumerated (fallback check: any ptr >=0x400000)"); end
    local chunk = 65536
    local hProc = kernel32.GetCurrentProcess()
    local hits = {}
    local off = 0
    while off < size do
        local want = math.min(chunk, size - off)
        local cur  = base + off
        local buf  = ffi.new("uint8_t[?]", want)
        local got  = ffi.new("unsigned long[1]")
        if kernel32.ReadProcessMemory(hProc, ffi.cast("void*", cur), buf, want, got) ~= 0 then
            local n = tonumber(got[0])
            local run = 0
            local run_start = nil
            for i = 0, n - 4, 4 do
                local ptr = tonumber(ffi.cast("uint32_t*", buf + i)[0])
                local is_code = #execs > 0 and is_code_ptr(ptr, execs) or (ptr >= 0x00400000 and ptr < 0x80000000 and ptr % 4 == 0)
                if is_code and ptr ~= 0 then
                    if run == 0 then run_start = cur + i end
                    run = run + 1
                else
                    if run >= min_entries then
                        hits[#hits+1] = { addr = run_start, count = run }
                        if #hits >= max_hits then break end
                    end
                    run = 0; run_start = nil
                end
            end
            if run >= min_entries then
                hits[#hits+1] = { addr = run_start, count = run }
            end
            if #hits >= max_hits then break end
        end
        off = off + want
        if #hits >= max_hits then break end
    end
    print(string.format("vtable.scan: %d candidate(s)  [0x%08X +0x%X  min %d ptrs]", #hits, base, size, min_entries))
    for i = 1, math.min(#hits, 50) do
        print(string.format("  0x%08X  (%d ptrs)", hits[i].addr, hits[i].count))
    end
    if #hits > 50 then print(string.format("  ... and %d more", #hits - 50)) end
    return hits
end

return M
