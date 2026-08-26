-- Europa 1400 - Memory Dumper
--
-- Dump process memory to host files for offline analysis in Ghidra,
-- hex editors, or diffing across game versions.
--
--   dump = require("dump")   -- or already `dump`
--   dump.region(0x00400000, 0x200000, "dump.bin")
--   dump.func(0x401000, "func.bin")          -- until RET
--   dump.range(0x401000, 64, "slice.bin")

local ffi = require("ffi")

ffi.cdef[[
    void* GetModuleHandleA(const char* lpModuleName);
    void* GetCurrentProcess(void);
    int   ReadProcessMemory(void* hProcess, const void* lpBaseAddress,
                            void* lpBuffer, unsigned long nSize,
                            unsigned long* lpNumberOfBytesRead);
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

local M = {}

function M.region(base, size, path)
    base = to_addr(base)
    if type(size) ~= "number" or size <= 0 or size > 0x2000000 then error("size out of range 1..32MB") end
    if type(path) ~= "string" or path == "" then error("path required") end
    local buf = ffi.new("uint8_t[?]", size)
    local got = ffi.new("unsigned long[1]")
    if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", base), buf, size, got) == 0 then
        error(string.format("ReadProcessMemory failed at 0x%08X", base))
    end
    local n = tonumber(got[0])
    local f, err = io.open(path, "wb")
    if not f then error("cannot open " .. path .. ": " .. tostring(err)) end
    -- write via ffi.string to avoid embedded NUL truncation
    f:write(ffi.string(buf, n))
    f:close()
    print(string.format("dump.region 0x%08X +0x%X -> %s (%d bytes)", base, size, path, n))
    return path
end

function M.range(addr, len, path)
    return M.region(addr, len, path)
end

function M.func(addr, path, max_len)
    addr = to_addr(addr)
    if type(path) ~= "string" or path == "" then error("path required") end
    max_len = max_len or 256
    if max_len <= 0 or max_len > 4096 then error("max_len out of range") end
    local buf = ffi.new("uint8_t[?]", max_len)
    local got = ffi.new("unsigned long[1]")
    if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", addr), buf, max_len, got) == 0 then
        error(string.format("Read failed at 0x%08X", addr))
    end
    local n = tonumber(got[0])
    -- cut at first RET (C3/C2/CB)
    local cut = n
    for i = 0, n-1 do
        if buf[i] == 0xC3 or buf[i] == 0xC2 or buf[i] == 0xCB then cut = i + 1; break end
    end
    local f, err = io.open(path, "wb")
    if not f then error("cannot open " .. path .. ": " .. tostring(err)) end
    f:write(ffi.string(buf, cut))
    f:close()
    print(string.format("dump.func 0x%08X -> %s (%d bytes)", addr, path, cut))
    return path
end

return M
