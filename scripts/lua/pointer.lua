-- Europa 1400 - Pointer Chain Resolver
--
-- Resolves multi-level pointers (as seen in Cheat Engine) to a final
-- address, then optionally reads a typed value there.
--
--   ptr = require("pointer")
--   addr = ptr.resolve("game.exe+0x1A3F00", {0x10, 0x20, 0x8})
--   val  = ptr.read(addr, "int")          -- or ptr.deref(addr)
--   ptr.dump_chain("game.exe+0x1A3F00", {0x10, 0x20, 0x8})
--
-- Offsets are added *before* each deref except the last (standard CE
-- semantics: base -> [+off0] -> [+off1] -> ... -> +lastOff).
-- Pass { } for a single-level pointer.

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
    if type(v) ~= "string" then error("address must be number or string") end
    local s = v:gsub("^%s+", ""):gsub("%s+$", "")
    -- "module.dll+0x1234" or "module.dll+1234"
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

local function read_u32(addr)
    local out = ffi.new("uint32_t[1]")
    local got = ffi.new("unsigned long[1]")
    if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(),
        ffi.cast("void*", addr), out, 4, got) == 0 or tonumber(got[0]) ~= 4 then
        return nil
    end
    return tonumber(out[0])
end

local M = {}

-- Resolve a pointer chain to the final address.
-- base: number | "0x401000" | "game.exe+0x1234" | "kernel32.dll+0x10"
-- offsets: array of numbers (each added before deref except last)
-- Returns final address (number).
function M.resolve(base, offsets)
    local cur = to_addr(base)
    offsets = offsets or {}
    if type(offsets) ~= "table" then error("offsets must be array/table") end
    if #offsets == 0 then return cur end
    for i = 1, #offsets - 1 do
        local off = offsets[i]
        if type(off) ~= "number" then error("offset #" .. i .. " must be number") end
        local ptr = read_u32(cur + off)
        if not ptr then error(string.format("failed to deref level %d at 0x%08X+0x%X", i, cur, off)) end
        if ptr == 0 then error(string.format("null pointer at level %d (0x%08X+0x%X)", i, cur, off)) end
        cur = ptr
    end
    local last = offsets[#offsets]
    if type(last) ~= "number" then error("last offset must be number") end
    -- last level: also deref if there were multiple levels, otherwise just add
    -- Standard CE chain: each offset except last is deref; last is add. But
    -- many tutorials treat last as add as well. We do: deref all but last, then add last.
    -- If caller wants final deref, append 0.
    if #offsets == 1 then
        -- single offset: base + off is the address (no deref), but if base itself
        -- is a pointer, caller should pass base as pointer value. Keep simple.
        return cur + last
    end
    -- cur already holds value after #offsets-1 derefs; last is final add
    return cur + last
end

-- Deref once: read uint32 at addr
function M.deref(addr)
    addr = to_addr(addr)
    local v = read_u32(addr)
    if not v then error(string.format("deref failed at 0x%08X", addr)) end
    return v
end

-- Read typed value at resolved address
function M.read(addr_or_base, ctype_or_offsets, maybe_ctype)
    -- Overloads:
    --   read(addr, "int")
    --   read(base, offsets, "int")
    local addr, ctype
    if type(ctype_or_offsets) == "table" then
        addr = M.resolve(addr_or_base, ctype_or_offsets)
        ctype = maybe_ctype or "int"
    else
        addr = to_addr(addr_or_base)
        ctype = ctype_or_offsets or "int"
    end
    if type(ctype) ~= "string" then error("ctype must be string") end
    local sz = ffi.sizeof(ctype)
    local buf = ffi.new("uint8_t[?]", sz)
    local got = ffi.new("unsigned long[1]")
    if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(),
        ffi.cast("void*", addr), buf, sz, got) == 0 or tonumber(got[0]) ~= sz then
        error(string.format("read failed at 0x%08X (%s)", addr, ctype))
    end
    local v = ffi.cast(ctype .. "*", buf)[0]
    -- return as Lua number/string appropriately
    if ctype == "float" or ctype == "double" then return tonumber(v) end
    if ctype:match("char") then return ffi.string(ffi.cast("char*", buf)) end
    return tonumber(v)
end

-- Print each level of a chain for debugging
function M.dump_chain(base, offsets)
    local cur = to_addr(base)
    offsets = offsets or {}
    print(string.format("Chain base 0x%08X  offsets {%s}", cur,
        table.concat((function()
            local t={}; for _,o in ipairs(offsets) do t[#t+1]=string.format("0x%X",o) end; return t
        end)(), ", ")))
    if #offsets == 0 then
        print(string.format("  final 0x%08X", cur))
        return cur
    end
    for i = 1, #offsets - 1 do
        local off = offsets[i]
        local nxt = read_u32(cur + off)
        print(string.format("  [%d] 0x%08X + 0x%X -> 0x%08X %s", i, cur, off, nxt or 0, nxt and "" or "(FAILED)"))
        if not nxt or nxt == 0 then return nil end
        cur = nxt
    end
    local final = cur + offsets[#offsets]
    print(string.format("  final 0x%08X + 0x%X = 0x%08X", cur, offsets[#offsets], final))
    return final
end

-- Backwards compat alias
M.follow = M.resolve

return M
