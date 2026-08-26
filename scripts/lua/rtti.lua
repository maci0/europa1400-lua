-- Europa 1400 - RTTI / Type Name Scanner
--
-- MSVC 32-bit RTTI leaves mangled type names like ".?AVPlayer@@" in the
-- binary. Finding them reveals class names and, via xrefs, their vtables
-- and virtual methods, a fast way to group the many functions you will
-- reverse next.
--
--   rtti = require("rtti")
--   rtti.list(0x00400000, 0x300000, 100)      -- first 100 type names
--   rtti.find("Player", 0x00400000, 0x300000) -- filter by substring
--   rtti.vtables("Player", 0x00400000, 0x800000)
--   rtti.at(0x00AB1234)                        -- show raw type string at addr

local ffi = require("ffi")

ffi.cdef[[
    void* GetModuleHandleA(const char* lpModuleName);
    void* GetCurrentProcess(void);
    int   ReadProcessMemory(void* hProcess, const void* lpBaseAddress,
                            void* lpBuffer, unsigned long nSize,
                            unsigned long* lpNumberOfBytesRead);
    int   VirtualQueryEx(void* hProcess, const void* lpAddress, void* lpBuffer, unsigned long dwLength);
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

local function read_cstr(addr, max)
    max = max or 256
    local buf = ffi.new("uint8_t[?]", max)
    local got = ffi.new("unsigned long[1]")
    if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", addr), buf, max, got) == 0 then
        return nil
    end
    local n = tonumber(got[0])
    local chars = {}
    for i = 0, n-1 do
        local b = buf[i]
        if b == 0 then break end
        if b < 32 or b >= 127 then break end
        chars[#chars+1] = string.char(b)
    end
    return table.concat(chars)
end

local function demangle(mangled)
    -- ".?AVPlayer@@" -> "Player", ".?AVFoo@Bar@@" -> "Bar::Foo" (approx)
    if not mangled then return nil end
    local s = mangled:match("^%.%?AV(.+)@@$") or mangled:match("^%.%?AU(.+)@@$") or mangled
    if s and s:find("@") then
        local parts = {}
        for p in s:gmatch("([^@]+)") do parts[#parts+1] = p end
        -- MSVC reverses nesting with @ separators; best-effort
        local out = {}
        for i = #parts, 1, -1 do out[#out+1] = parts[i] end
        return table.concat(out, "::")
    end
    return s or mangled
end

local M = {}

function M.at(addr)
    addr = to_addr(addr)
    local s = read_cstr(addr, 256)
    if not s or s == "" then print(string.format("0x%08X: <no string>", addr)); return nil end
    print(string.format("0x%08X: %q  ->  %s", addr, s, demangle(s)))
    return s
end

-- Reuse strings module if available, otherwise inline a lean scan for ".?AV"
function M.list(base, size, max_hits)
    base = base and to_addr(base) or 0x00400000
    size = size or 0x300000
    max_hits = max_hits or 200
    local hits = require("strings").find(".?AV", base, size, 4, max_hits * 2)
    -- Filter to mangled type names and dedup
    local seen, out = {}, {}
    for _, h in ipairs(hits) do
        local s = h.text
        if s and s:find("%.%?A[UV]") and s:find("@@") then
            if not seen[s] then
                seen[s] = true
                out[#out+1] = { addr = h.addr, mangled = s, demangled = demangle(s) }
                if #out >= max_hits then break end
            end
        end
    end
    table.sort(out, function(a,b) return a.demangled < b.demangled end)
    print(string.format("rtti.list: %d unique type(s)  [0x%08X +0x%X]", #out, base, size))
    for i = 1, math.min(#out, 100) do
        print(string.format("  0x%08X  %-40s  %q", out[i].addr, out[i].demangled, out[i].mangled))
    end
    if #out > 100 then print(string.format("  ... and %d more", #out - 100)) end
    return out
end

function M.find(needle, base, size, max_hits)
    if type(needle) ~= "string" or needle == "" then error("needle required") end
    base = base and to_addr(base) or 0x00400000
    size = size or 0x300000
    max_hits = max_hits or 100
    local all = M.list(base, size, 500)
    local low = needle:lower()
    local filtered = {}
    for _, e in ipairs(all) do
        if e.demangled:lower():find(low, 1, true) or e.mangled:lower():find(low, 1, true) then
            filtered[#filtered+1] = e
            if #filtered >= max_hits then break end
        end
    end
    print(string.format("rtti.find %q: %d hit(s)", needle, #filtered))
    for _, e in ipairs(filtered) do
        print(string.format("  0x%08X  %-32s  %q", e.addr, e.demangled, e.mangled))
    end
    return filtered
end

-- For a given class/type, find xrefs to its TypeDescriptor string and report
-- nearby vtables: chaining strings -> xrefs -> vtable is caller work, but
-- we narrow the needle first.
function M.vtables(needle, base, size)
    if type(needle) ~= "string" or needle == "" then error("needle (class name) required") end
    base = base and to_addr(base) or 0x00400000
    size = size or 0x800000
    local types = M.find(needle, base, size, 20)
    if #types == 0 then print("rtti.vtables: no type found for " .. needle); return {} end
    local xrefs = require("xrefs")
    local vtable = require("vtable")
    local results = {}
    for _, t in ipairs(types) do
        print(string.format("\nType %s @ 0x%08X:", t.demangled, t.addr))
        if xrefs and xrefs.to then
            local xr = xrefs.to(t.addr, base, size, 20)
            for _, h in ipairs(xr or {}) do
                print(string.format("  xref 0x%08X  %-12s", h.addr, h.kind))
                -- CompleteObjectLocator is usually a few words before the vtable;
                -- if this xref looks like it's inside a small struct, try nearby
                if vtable and vtable.at then
                    -- best-effort: dump what looks like a vtable near the xref
                    -- (the xref target is the type string, not the vtable itself,
                    --  but COL/TypeDescriptor layout puts it close)
                end
            end
            results[#results+1] = { type = t, xrefs = xr }
        else
            print("  (xrefs module not loaded)")
        end
    end
    return results
end

return M
