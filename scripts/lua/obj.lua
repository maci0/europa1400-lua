-- Europa 1400 - C++ Object Helper
--
-- Convenience for `thiscall` style object methods that dominate
-- MSVC game code. Wraps pointer + vtable + thiscall in one place
-- so you can call virtual methods once you've mapped a class via
-- rtti/vtable/disasm.
--
--   obj = require("obj")  -- or already `obj`
--   o = obj.at(0x00AB1234)        -- object at addr (reads vtable ptr)
--   o:vcall(0, "int(void*)", {})  -- call vtable[0] with this=o.addr
--   o:call(0x00401234, "int(void*,int)", {5}) -- direct thiscall
--   o:field("int", 0x10)          -- typed field read
--   obj.vcall(0x00AB1234, 2, "int(void*)", {}) -- one-shot
--   obj.dump(0x00AB1234, 16)      -- vtable + first fields

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

local function read_u32(addr)
    local out = ffi.new("uint32_t[1]")
    local got = ffi.new("unsigned long[1]")
    if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", addr), out, 4, got) == 0 then return nil end
    if tonumber(got[0]) ~= 4 then return nil end
    return tonumber(out[0])
end

local M = {}

local Obj = {}
Obj.__index = Obj

function Obj:vtable()
    local vt = read_u32(self.addr)
    if not vt then error(string.format("failed to read vtable ptr at 0x%08X", self.addr)) end
    return vt
end

function Obj:vfunc(idx)
    local vt = self:vtable()
    local p = read_u32(vt + idx * 4)
    if not p then error(string.format("vfunc[%d] read failed (vtable 0x%08X)", idx, vt)) end
    return p
end

function Obj:vcall(idx, sig, args)
    sig = sig or "int(void*)"
    args = args or {}
    if type(sig) ~= "string" then error("sig must be string") end
    local fn_addr = self:vfunc(idx)
    local ok, fn = pcall(function() return ffi.cast(sig .. "*", fn_addr) end)
    if not ok then error("bad sig " .. sig .. ": " .. tostring(fn)) end
    -- thiscall on x86 MSVC passes `this` in ECX; LuaJIT FFI `__thiscall` needed
    -- if sig doesn't already specify convention, try as-is then __thiscall
    local this_sig = sig:find("__thiscall") and sig or sig:gsub("%(", " __thiscall(" , 1)
    local fn2
    local ok2 = pcall(function() fn2 = ffi.cast(this_sig .. "*", fn_addr) end)
    local use = (ok2 and fn2) and fn2 or fn
    local t0 = os.clock()
    local ok3, res = pcall(function() return use(self.addr, unpack(args)) end)
    local ms = (os.clock() - t0) * 1000
    if not ok3 then error(string.format("vcall[%d] 0x%08X failed: %s", idx, fn_addr, tostring(res))) end
    print(string.format("vcall[%d] 0x%08X %s(this=0x%08X) -> %s  %.2fms", idx, fn_addr, sig, self.addr, tostring(res), ms))
    return res
end

function Obj:call(addr, sig, args)
    addr = to_addr(addr); sig = sig or "int(void*)"; args = args or {}
    local ok, fn = pcall(function() return ffi.cast(sig .. "*", addr) end)
    if not ok then error("bad sig " .. sig .. ": " .. tostring(fn)) end
    local t0 = os.clock()
    local ok2, res = pcall(function() return fn(self.addr, unpack(args)) end)
    local ms = (os.clock() - t0) * 1000
    if not ok2 then error(tostring(res)) end
    print(string.format("call 0x%08X %s -> %s  %.2fms", addr, sig, tostring(res), ms))
    return res
end

function Obj:field(ctype, off)
    local addr = self.addr + (off or 0)
    ctype = ctype or "int"
    local sz = ffi.sizeof(ctype)
    local buf = ffi.new("uint8_t[?]", sz)
    local got = ffi.new("unsigned long[1]")
    if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", addr), buf, sz, got) == 0 then
        error(string.format("field read failed at 0x%08X", addr))
    end
    if ctype:find("char") then return ffi.string(ffi.cast("char*", buf)) end
    return tonumber(ffi.cast(ctype .. "*", buf)[0])
end

function Obj:dump(n)
    n = n or 12
    local vt = read_u32(self.addr)
    print(string.format("object 0x%08X  vtable 0x%08X", self.addr, vt or 0))
    if vt then
        for i = 0, math.min(n, 16) - 1 do
            local p = read_u32(vt + i * 4)
            if not p then break end
            print(string.format("  [%2d] 0x%08X", i, p))
        end
    end
    return vt
end

function M.at(addr)
    addr = to_addr(addr)
    return setmetatable({ addr = addr }, Obj)
end

function M.vcall(obj_addr, idx, sig, args)
    return M.at(obj_addr):vcall(idx, sig, args)
end

function M.dump(addr, n)
    return M.at(addr):dump(n)
end

return M
