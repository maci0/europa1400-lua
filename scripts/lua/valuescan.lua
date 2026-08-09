-- Europa 1400 - Value Scanner (Cheat-Engine style)
--
-- Scan committed readable memory for a live value without hard-coded
-- addresses. Useful to locate player gold, health, inventory, etc.
-- then hand the hit to `pointer` or `xrefs` to trace back to code.
--
--   vs = dofile('lua/valuescan.lua')
--   hits = vs.int32(1500, 0x00400000, 0x300000)        -- exact i32
--   hits = vs.int32_range(1000, 5000, 0x00400000, 0x300000)
--   hits = vs.float32(99.5, 0.01, 0x00400000, 0x300000) -- with epsilon
--   hits = vs.bytes("47 6F 6C 64")                      -- alias to scan.scan
--   vs.update(hits, 1600)                               -- re-filter hits after value changed
--   vs.dump(hits, 5)                                    -- print first 5

local ffi = require("ffi")

ffi.cdef[[
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

local function to_addr(v)
    if type(v) == "string" then
        local s = v:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^0[xX]", "")
        local n = tonumber(s, 16)
        if not n then error("invalid address: " .. tostring(v)) end
        return n
    elseif type(v) == "number" then return v
    else error("address must be number or hex string") end
end

local function is_readable(protect, state)
    if state ~= MEM_COMMIT then return false end
    if bit and bit.band(protect, PAGE_GUARD) ~= 0 then return false end
    if protect == PAGE_NOACCESS then return false end
    return protect ~= 0 and protect ~= PAGE_NOACCESS
end

local function regions(base, max_size)
    local hProc = kernel32.GetCurrentProcess()
    local mbi = ffi.new("MEMORY_BASIC_INFORMATION")
    local out, addr = {}, base
    local limit = base + max_size
    while addr < limit do
        if kernel32.VirtualQueryEx(hProc, ffi.cast("void*", addr), mbi, ffi.sizeof(mbi)) == 0 then break end
        if is_readable(mbi.Protect, mbi.State) then
            table.insert(out, {
                base = tonumber(ffi.cast("uintptr_t", mbi.BaseAddress)),
                size = tonumber(mbi.RegionSize),
            })
        end
        addr = tonumber(ffi.cast("uintptr_t", mbi.BaseAddress)) + tonumber(mbi.RegionSize)
        if addr == 0 then break end
    end
    return out
end

local function chunk_scan(base, size, max_hits, stride, check_fn)
    max_hits = max_hits or 512
    stride   = stride or 1
    local hProc = kernel32.GetCurrentProcess()
    local regs
    if base then
        regs = regions(base, size or 0x300000)
        if #regs == 0 then regs = { { base = base, size = size or 0x200000 } } end
    else
        regs = regions(0x00400000, 0x3000000)
    end
    local chunk = 65536
    local hits = {}
    for _, r in ipairs(regs) do
        local off = 0
        while off < r.size do
            local want = math.min(chunk, r.size - off)
            local cur  = r.base + off
            local buf  = ffi.new("uint8_t[?]", want)
            local got  = ffi.new("unsigned long[1]")
            if kernel32.ReadProcessMemory(hProc, ffi.cast("void*", cur), buf, want, got) ~= 0 then
                local n = tonumber(got[0])
                for i = 0, n - stride, stride do
                    if check_fn(buf, i, cur + i) then
                        table.insert(hits, cur + i)
                        if #hits >= max_hits then return hits end
                    end
                end
                if n < want then -- partial region, stop
                end
            end
            off = off + want
            if #hits >= max_hits then break end
        end
        if #hits >= max_hits then break end
    end
    return hits
end

local M = {}

function M.int32(value, base, size, max_hits)
    if type(value) ~= "number" then error("value must be number") end
    if base ~= nil then base = to_addr(base) end
    local iv = ffi.cast("int32_t", value)
    return chunk_scan(base, size, max_hits, 4, function(buf, i)
        return ffi.cast("int32_t*", buf + i)[0] == iv
    end)
end

function M.uint32(value, base, size, max_hits)
    if type(value) ~= "number" then error("value must be number") end
    if base ~= nil then base = to_addr(base) end
    local uv = ffi.cast("uint32_t", value)
    return chunk_scan(base, size, max_hits, 4, function(buf, i)
        return ffi.cast("uint32_t*", buf + i)[0] == uv
    end)
end

function M.int16(value, base, size, max_hits)
    if type(value) ~= "number" then error("value must be number") end
    if base ~= nil then base = to_addr(base) end
    local v = ffi.cast("int16_t", value)
    return chunk_scan(base, size, max_hits, 2, function(buf, i)
        return ffi.cast("int16_t*", buf + i)[0] == v
    end)
end

function M.int32_range(lo, hi, base, size, max_hits)
    if type(lo) ~= "number" or type(hi) ~= "number" then error("lo/hi must be numbers") end
    if lo > hi then lo, hi = hi, lo end
    if base ~= nil then base = to_addr(base) end
    return chunk_scan(base, size, max_hits, 4, function(buf, i)
        local v = tonumber(ffi.cast("int32_t*", buf + i)[0])
        return v >= lo and v <= hi
    end)
end

function M.float32(value, epsilon, base, size, max_hits)
    if type(value) ~= "number" then error("value must be number") end
    epsilon = epsilon or 0.001
    if base ~= nil then base = to_addr(base) end
    -- disambiguate: float32(value, base) vs float32(value, epsilon, base)
    if type(epsilon) == "string" or (type(epsilon)=="number" and epsilon > 0x10000) then
        -- caller omitted epsilon
        max_hits = size
        size = base
        base = epsilon
        epsilon = 0.001
        base = to_addr(base)
    end
    return chunk_scan(base, size, max_hits, 4, function(buf, i)
        local v = tonumber(ffi.cast("float*", buf + i)[0])
        if v ~= v then return false end -- NaN
        return math.abs(v - value) <= epsilon
    end)
end

function M.double(value, epsilon, base, size, max_hits)
    if type(value) ~= "number" then error("value must be number") end
    epsilon = epsilon or 0.001
    if base ~= nil then base = to_addr(base) end
    if type(epsilon) == "string" or (type(epsilon)=="number" and epsilon > 0x10000) then
        max_hits = size; size = base; base = epsilon; epsilon = 0.001
        base = to_addr(base)
    end
    return chunk_scan(base, size, max_hits, 8, function(buf, i)
        local v = tonumber(ffi.cast("double*", buf + i)[0])
        if v ~= v then return false end
        return math.abs(v - value) <= epsilon
    end)
end

-- Re-filter a previous hit list after the in-game value changed.
-- Keeps only addresses that now hold `value` (int32 by default).
--   hits = vs.int32(100, base, size)
--   -- change gold in game --
--   hits = vs.update(hits, 150)
function M.update(hits, value, ctype)
    if type(hits) ~= "table" then error("hits must be table from a prior scan") end
    if type(value) ~= "number" then error("value must be number") end
    ctype = ctype or "int32_t"
    local hProc = kernel32.GetCurrentProcess()
    local out = {}
    for _, addr in ipairs(hits) do
        local sz = ffi.sizeof(ctype)
        local tmp = ffi.new("uint8_t[?]", sz)
        local got = ffi.new("unsigned long[1]")
        if kernel32.ReadProcessMemory(hProc, ffi.cast("void*", addr), tmp, sz, got) ~= 0 and tonumber(got[0]) == sz then
            local cur
            if ctype == "float" or ctype == "double" then
                cur = tonumber(ffi.cast(ctype.."*", tmp)[0])
                if math.abs(cur - value) <= 0.001 then table.insert(out, addr) end
            else
                cur = tonumber(ffi.cast(ctype.."*", tmp)[0])
                if cur == value then table.insert(out, addr) end
            end
        end
    end
    return out
end

function M.dump(hits, count)
    count = count or math.min(10, #hits)
    print(string.format("%d hit(s), showing %d:", #hits, math.min(count, #hits)))
    local hProc = kernel32.GetCurrentProcess()
    for i = 1, math.min(count, #hits) do
        local addr = hits[i]
        local v = ffi.new("int32_t[1]")
        local got = ffi.new("unsigned long[1]")
        local s = ""
        if kernel32.ReadProcessMemory(hProc, ffi.cast("void*", addr), v, 4, got) ~= 0 then
            s = string.format(" i32=%d (0x%08X)  f32=%.6g", v[0], tonumber(ffi.cast("uint32_t*", v)[0]), tonumber(ffi.cast("float*", v)[0]))
        end
        print(string.format("  [%d] 0x%08X%s", i, addr, s))
    end
    return hits
end

return M
