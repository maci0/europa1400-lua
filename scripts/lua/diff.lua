-- Europa 1400 - Memory Diff
--
-- Compare two snapshots of the same address range. Complements
-- valuescan/watch: use diff to find *what* changed when you don't
-- know the exact value (e.g. inventory after a trade).
--
--   diff = dofile('lua/diff.lua')    -- or already `diff`
--   a = diff.snap(0x12340000, 64)
--   -- perform in-game action --
--   b = diff.snap(0x12340000, 64)
--   diff.compare(a, b)
--   diff.watch(0x12340000, 64, 200, 20)  -- poll and print diffs

local ffi = require("ffi")

ffi.cdef[[
    void* GetModuleHandleA(const char* lpModuleName);
    void* GetCurrentProcess(void);
    int   ReadProcessMemory(void* hProcess, const void* lpBaseAddress,
                            void* lpBuffer, unsigned long nSize,
                            unsigned long* lpNumberOfBytesRead);
    void __stdcall Sleep(unsigned long dwMilliseconds);
]]

local kernel32 = ffi.load("kernel32")

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

local function snap_bytes(addr, len)
    local buf = ffi.new("uint8_t[?]", len)
    local got = ffi.new("unsigned long[1]")
    if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", addr), buf, len, got) == 0 then
        return nil
    end
    local n = tonumber(got[0])
    local t = {}
    for i = 0, n-1 do t[i+1] = buf[i] end
    return t, n
end

local M = {}

function M.snap(addr, len)
    addr = to_addr(addr); len = len or 64
    if len <= 0 or len > 4096 then error("len out of range 1..4096") end
    local bytes = snap_bytes(addr, len)
    if not bytes then error(string.format("Read failed at 0x%08X", addr)) end
    return { addr = addr, len = len, bytes = bytes }
end

function M.compare(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then error("compare(snapA, snapB) with snapshots from diff.snap") end
    if a.addr ~= b.addr then print(string.format("warning: different bases 0x%08X vs 0x%08X", a.addr, b.addr)) end
    local len = math.min(#a.bytes, #b.bytes)
    local diffs = {}
    for i = 1, len do
        if a.bytes[i] ~= b.bytes[i] then
            diffs[#diffs+1] = { off = i-1, a = a.bytes[i], b = b.bytes[i] }
        end
    end
    if #diffs == 0 then
        print(string.format("No diff in %d bytes @ 0x%08X", len, a.addr))
        return diffs
    end
    print(string.format("Diff @ 0x%08X  len %d  changed %d byte(s):", a.addr, len, #diffs))
    for _, d in ipairs(diffs) do
        local av, bv = d.a, d.b
        local ai = tonumber(ffi.cast("int8_t", ffi.new("uint8_t[1]", av))[0])
        -- also show as int32-aligned if at aligned offset
        local extra = ""
        if d.off % 4 == 0 and d.off + 3 < len then
            local ai32 = a.bytes[d.off+1] + a.bytes[d.off+2]*256 + a.bytes[d.off+3]*65536 + a.bytes[d.off+4]*16777216
            local bi32 = b.bytes[d.off+1] + b.bytes[d.off+2]*256 + b.bytes[d.off+3]*65536 + b.bytes[d.off+4]*16777216
            -- signed
            if ai32 >= 0x80000000 then ai32 = ai32 - 0x100000000 end
            if bi32 >= 0x80000000 then bi32 = bi32 - 0x100000000 end
            if ai32 ~= bi32 then
                -- decode float too
                local af = tonumber(ffi.cast("float*", ffi.new("uint8_t[4]", a.bytes[d.off+1], a.bytes[d.off+2], a.bytes[d.off+3], a.bytes[d.off+4]))[0])
                -- fallback: best-effort, avoid overcomplicating
                extra = string.format("  (i32 %d -> %d)", ai32, bi32)
            end
            _ = ai; _ = af
        end
        print(string.format("  +0x%04X  %02X -> %02X%s", d.off, av, bv, extra))
    end
    return diffs
end

-- Poll `count` times, print a diff whenever the snapshot changes
function M.watch(addr, len, interval_ms, count)
    addr = to_addr(addr); len = len or 64
    interval_ms = interval_ms or 200
    count = count or 30
    local prev = M.snap(addr, len)
    print(string.format("diff.watch 0x%08X len %d  %d x %dms", addr, len, count, interval_ms))
    for i = 1, count do
        kernel32.Sleep(interval_ms)
        local cur = M.snap(addr, len)
        local diffs = {}
        for j = 1, math.min(#prev.bytes, #cur.bytes) do
            if prev.bytes[j] ~= cur.bytes[j] then diffs[#diffs+1] = j end
        end
        if #diffs > 0 then
            print(string.format("  [%d] %d byte(s) changed", i, #diffs))
            M.compare(prev, cur)
            prev = cur
        end
    end
    print("diff.watch done")
    return prev
end

return M
