-- Europa 1400 - Live Memory Watcher
--
-- Poll-based watchpoints for reverse engineering when hardware
-- breakpoints are overkill. Watches an address/type for changes,
-- prints a diff, optionally snapshots a hex dump around the hit.
-- Complements valuescan (find it) -> watch (who changes it) -> xrefs/patch.
--
--   watch = require("watch")
--   w = watch.new(0x12340000, "int")
--   w:poll(500, 20)                 -- 20 samples, 500ms apart (blocking)
--   watch.once(0x12340000, "int")   -- single read + pretty print
--   watch.wait(0x12340000, "int", 5000, 100)  -- wait up to 5s for change
--   watch.track(0x12340000, "int", 200, 30)   -- track N samples, report diffs
--   watch.diff(0x12340000, 64)      -- hex diff vs previous snapshot

local ffi = require("ffi")

ffi.cdef[[
    void* GetModuleHandleA(const char* lpModuleName);
    void* GetCurrentProcess(void);
    int   ReadProcessMemory(void* hProcess, const void* lpBaseAddress,
                            void* lpBuffer, unsigned long nSize,
                            unsigned long* lpNumberOfBytesRead);
    void __stdcall Sleep(unsigned long dwMilliseconds);
    unsigned long GetTickCount(void);
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

local function read_typed(addr, ctype)
    ctype = ctype or "int"
    local sz = ffi.sizeof(ctype)
    local buf = ffi.new("uint8_t[?]", sz)
    local got = ffi.new("unsigned long[1]")
    if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", addr), buf, sz, got) == 0
        or tonumber(got[0]) ~= sz then
        return nil, "ReadProcessMemory failed at 0x" .. string.format("%08X", addr)
    end
    if ctype == "float" or ctype == "double" then
        return tonumber(ffi.cast(ctype .. "*", buf)[0])
    end
    if ctype:find("char") then
        -- return as Lua string (up to first NUL if char array, handle via size)
        local s = ffi.string(ffi.cast("char*", buf), sz)
        -- trim at first NUL for readability
        local z = s:find("\0", 1, true)
        if z then s = s:sub(1, z-1) end
        return s
    end
    return tonumber(ffi.cast(ctype .. "*", buf)[0])
end

local function fmt_val(v, ctype)
    if v == nil then return "<read failed>" end
    if type(v) == "string" then return string.format('"%s"', v) end
    if ctype == "float" or ctype == "double" then return string.format("%.6g", v) end
    if type(v) == "number" and v > 65535 then
        return string.format("%d (0x%08X)", v, v % 0x100000000)
    end
    return tostring(v)
end

local function hex_snapshot(addr, len)
    len = len or 32
    local buf = ffi.new("uint8_t[?]", len)
    local got = ffi.new("unsigned long[1]")
    if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", addr), buf, len, got) == 0 then
        return nil
    end
    local n = tonumber(got[0])
    local t = {}
    for i = 0, n-1 do t[#t+1] = string.format("%02X", buf[i]) end
    return table.concat(t, " "), n
end

local M = {}
M._snapshots = {} -- addr -> hex string for diff

-- Single read + print
function M.once(addr, ctype)
    addr = to_addr(addr); ctype = ctype or "int"
    local v, err = read_typed(addr, ctype)
    if err then print(err); return nil end
    local hex = hex_snapshot(addr, math.min(16, ffi.sizeof(ctype) * 2))
    print(string.format("0x%08X  %s = %s   [%s]", addr, ctype, fmt_val(v, ctype), hex or "?"))
    return v
end

-- Watcher object
local Watcher = {}
Watcher.__index = Watcher

function Watcher:poll(interval_ms, count, on_change)
    interval_ms = interval_ms or 200
    count = count or 30
    local prev = read_typed(self.addr, self.ctype)
    print(string.format("Watch 0x%08X (%s) every %dms x%d  start=%s", self.addr, self.ctype, interval_ms, count, fmt_val(prev, self.ctype)))
    for i = 1, count do
        kernel32.Sleep(interval_ms)
        local cur, err = read_typed(self.addr, self.ctype)
        if err then print(string.format("  [%d] read failed: %s", i, err)) else
            if cur ~= prev then
                local msg = string.format("  [%d] CHANGE %s -> %s", i, fmt_val(prev, self.ctype), fmt_val(cur, self.ctype))
                print(msg)
                local hx = hex_snapshot(self.addr, 16)
                if hx then print("       hex: " .. hx) end
                if on_change then pcall(on_change, cur, prev, self.addr) end
                prev = cur
            end
        end
    end
    print("Watch done.")
    return prev
end

function Watcher:wait(timeout_ms, interval_ms)
    timeout_ms = timeout_ms or 5000
    interval_ms = interval_ms or 100
    local start = kernel32.GetTickCount()
    local prev = read_typed(self.addr, self.ctype)
    print(string.format("Wait for change at 0x%08X (%s) = %s  timeout %dms", self.addr, self.ctype, fmt_val(prev, self.ctype), timeout_ms))
    while true do
        kernel32.Sleep(interval_ms)
        local cur = read_typed(self.addr, self.ctype)
        if cur ~= nil and cur ~= prev then
            print(string.format("  CHANGED %s -> %s  after %lums", fmt_val(prev, self.ctype), fmt_val(cur, self.ctype), kernel32.GetTickCount() - start))
            local hx = hex_snapshot(self.addr, 16)
            if hx then print("  hex: " .. hx) end
            return cur, prev
        end
        if kernel32.GetTickCount() - start >= timeout_ms then
            print("  timeout, no change")
            return nil, prev
        end
    end
end

function M.new(addr, ctype)
    addr = to_addr(addr); ctype = ctype or "int"
    -- validate
    local _, err = read_typed(addr, ctype)
    if err then error(err) end
    return setmetatable({ addr = addr, ctype = ctype }, Watcher)
end

-- Convenience: blocking track without creating object
function M.track(addr, ctype, interval_ms, count, on_change)
    if type(ctype) == "number" then -- track(addr, interval, count) overload
        on_change = count; count = interval_ms; interval_ms = ctype; ctype = "int"
    end
    local w = M.new(addr, ctype)
    return w:poll(interval_ms or 200, count or 30, on_change)
end

function M.wait(addr, ctype, timeout_ms, interval_ms)
    if type(ctype) == "number" then interval_ms = timeout_ms; timeout_ms = ctype; ctype = "int" end
    local w = M.new(addr, ctype)
    return w:wait(timeout_ms, interval_ms)
end

-- Snapshot current hex around addr and diff vs last snapshot
function M.diff(addr, len)
    addr = to_addr(addr); len = len or 32
    local cur = hex_snapshot(addr, len)
    if not cur then print("diff: read failed"); return nil end
    local prev = M._snapshots[addr]
    M._snapshots[addr] = cur
    if not prev then
        print(string.format("Snapshot 0x%08X: %s", addr, cur))
        return cur
    end
    if cur == prev then
        print(string.format("No change at 0x%08X", addr))
    else
        print(string.format("Diff 0x%08X:", addr))
        print("  before: " .. prev)
        print("  after : " .. cur)
    end
    return cur
end

function M.snap(addr, len)
    addr = to_addr(addr); len = len or 32
    local cur = hex_snapshot(addr, len)
    if cur then M._snapshots[addr] = cur; print(string.format("Snapshot 0x%08X: %s", addr, cur)) end
    return cur
end

return M
