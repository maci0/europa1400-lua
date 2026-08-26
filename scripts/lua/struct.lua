-- Europa 1400 - Structured Memory Dumper
--
-- Dump typed structs/arrays at an address without manual ffi.cast
-- boilerplate. Complements scan/valuescan (find it) -> pointer (follow
-- it) -> struct (understand it).
--
--   struct = require("struct")
--   ffi.cdef[[ typedef struct { int gold; int fame; char name[32]; } Player; ]]
--   struct.layout("Player")                 -- sizeof + offsets
--   struct.dump(0x12340000, "Player")       -- field-aware dump (needs registration)
--   struct.dump(0x12340000, {               -- ad-hoc field table
--     { name="gold", type="int",  offset=0 },
--     { name="fame", type="int",  offset=4 },
--     { name="name", type="char[32]", offset=8 },
--   })
--   struct.register("Player", { ... })      -- remember for later dumps
--   struct.dump(0x12340000, "Player")
--   struct.array(0x12340000, "int", 8)
--   struct.hex(0x12340000, 64)

local ffi = require("ffi")

ffi.cdef[[
    void* GetModuleHandleA(const char* lpModuleName);
    void* GetCurrentProcess(void);
    int   ReadProcessMemory(void* hProcess, const void* lpBaseAddress,
                            void* lpBuffer, unsigned long nSize,
                            unsigned long* lpNumberOfBytesRead);
]]

local kernel32 = ffi.load("kernel32")

local registry = {} -- ctype name -> field table

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

local function read_bytes(addr, len)
    local buf = ffi.new("uint8_t[?]", len)
    local got = ffi.new("unsigned long[1]")
    if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", addr), buf, len, got) == 0
        or tonumber(got[0]) ~= len then
        return nil
    end
    return buf
end

local function sizeof_of(ctype)
    local ok, sz = pcall(ffi.sizeof, ctype)
    if ok then return sz end
    -- handle "char[32]" etc via temporary typedef already covered by sizeof above;
    -- fallback: try base type
    return nil
end

local function read_field(base_addr, field)
    local addr = base_addr + (field.offset or 0)
    local ctype = field.type or "int"
    -- char[N] -> string
    local arr_n = ctype:match("^%s*char%s*%[%s*(%d+)%s*%]%s*$")
    if arr_n then
        local n = tonumber(arr_n)
        local buf = read_bytes(addr, n)
        if not buf then return nil, "<read failed>" end
        local s = ffi.string(buf, n)
        local z = s:find("\0", 1, true)
        if z then s = s:sub(1, z-1) end
        -- escape non-printable for readability
        if s:find("[^%w%p ]") then
            s = s:gsub(".", function(c)
                local b = c:byte()
                if b >= 32 and b < 127 then return c end
                return string.format("\\x%02X", b)
            end)
        end
        return s, string.format('char[%d]', n)
    end
    local sz = sizeof_of(ctype)
    if not sz then return nil, "<unknown type>" end
    local buf = read_bytes(addr, sz)
    if not buf then return nil, "<read failed>" end
    if ctype == "float" or ctype == "double" then
        return tonumber(ffi.cast(ctype .. "*", buf)[0]), ctype
    end
    if ctype:find("%*") then
        local v = tonumber(ffi.cast("uintptr_t", ffi.cast(ctype, buf)[0] or ffi.cast(ctype .. "*", buf)[0]))
        -- fallback: read as uintptr_t
        local uv = tonumber(ffi.cast("uint32_t*", buf)[0])
        return uv, ctype .. string.format(" (0x%08X)", uv or 0)
    end
    -- integer types
    local v = tonumber(ffi.cast(ctype .. "*", buf)[0])
    return v, ctype
end

local M = {}

function M.register(name, fields)
    if type(name) ~= "string" or name == "" then error("name must be non-empty string") end
    if type(fields) ~= "table" then error("fields must be array of {name, type, offset}") end
    for i, f in ipairs(fields) do
        if type(f.name) ~= "string" or type(f.type) ~= "string" or type(f.offset) ~= "number" then
            error(string.format("field[%d] must be {name=string, type=string, offset=number}", i))
        end
    end
    registry[name] = fields
    print(string.format("Registered struct '%s' (%d fields)", name, #fields))
    return fields
end

function M.layout(ctype)
    local sz = sizeof_of(ctype)
    if not sz then
        print("Unknown type: " .. tostring(ctype))
        return nil
    end
    print(string.format("Type %-24s  sizeof=%d (0x%X)", ctype, sz, sz))
    local fields = registry[ctype]
    if fields then
        for _, f in ipairs(fields) do
            local fsz = sizeof_of(f.type) or 0
            print(string.format("  +0x%04X  %-12s  %-14s  (size %d)", f.offset, f.name, f.type, fsz))
        end
    else
        -- try ffi.offsetof introspection if fields were defined via ffi.cdef without registration
        print("  (no field registry; register via struct.register('" .. ctype .. "', {...}) for field offsets)")
        -- attempt to probe common fields via pcall offsetof for already-defined struct
        -- we cannot enumerate field names, but we can show that offsetof works:
        -- e.g. ffi.offsetof("Player", "gold")
    end
    return sz, fields
end

function M.dump(addr, ctype_or_fields, opts)
    addr = to_addr(addr)
    opts = opts or {}
    local fields
    local ctype_name
    if type(ctype_or_fields) == "string" then
        ctype_name = ctype_or_fields
        fields = registry[ctype_name]
        if not fields then
            -- no registry: try to treat as primitive type
            local sz = sizeof_of(ctype_name)
            if sz and sz <= 64 then
                local v, vt = read_field(addr, { type = ctype_name, offset = 0 })
                print(string.format("0x%08X  %s = %s", addr, vt or ctype_name, v ~= nil and tostring(v) or "<failed>"))
                local hex = read_bytes(addr, math.min(32, sz * 2))
                if hex then
                    local t = {}
                    for i = 0, sz-1 do t[#t+1] = string.format("%02X", hex[i]) end
                    print("  hex: " .. table.concat(t, " "))
                end
                return v
            end
            print(string.format("No field registry for '%s'. Pass a field table or register first; falling back to a hex dump.", ctype_name))
            return M.hex(addr, sz or 64)
        end
    elseif type(ctype_or_fields) == "table" then
        fields = ctype_or_fields
    else
        error("second arg must be ctype name string or field table")
    end

    print(string.format("Struct %s @ 0x%08X", ctype_name or "(anonymous)", addr))
    print(string.rep("-", 56))
    for _, f in ipairs(fields) do
        local v, vt = read_field(addr, f)
        local vs
        if v == nil then vs = "<read failed>"
        elseif type(v) == "string" then vs = string.format('"%s"', v)
        elseif type(v) == "number" and vt and vt:find("float") then vs = string.format("%.6g", v)
        elseif type(v) == "number" and v > 65535 then vs = string.format("%d (0x%08X)", v, v % 0x100000000)
        else vs = tostring(v) end
        print(string.format("  +0x%04X  %-16s  %-12s = %s", f.offset, f.name, vt or f.type, vs))
    end
    return fields
end

function M.array(addr, ctype, count, stride)
    addr = to_addr(addr)
    if type(ctype) ~= "string" then error("ctype must be string") end
    count = count or 8
    if count <= 0 or count > 1024 then error("count out of range 1..1024") end
    local sz = sizeof_of(ctype)
    if not sz then error("unknown ctype: " .. ctype) end
    stride = stride or sz
    print(string.format("Array %s[%d] @ 0x%08X  (stride %d)", ctype, count, addr, stride))
    for i = 0, count-1 do
        local a = addr + i * stride
        local v, _ = read_field(a, { type = ctype, offset = 0 })
        local vs = v == nil and "<failed>" or (type(v)=="number" and v>65535) and string.format("%d (0x%08X)", v, v%0x100000000) or tostring(v)
        print(string.format("  [%2d] 0x%08X = %s", i, a, vs))
    end
end

function M.hex(addr, len)
    addr = to_addr(addr); len = len or 64
    if len <= 0 or len > 4096 then error("len out of range") end
    local buf = read_bytes(addr, len)
    if not buf then print(string.format("Read failed at 0x%08X", addr)); return nil end
    local cols = 16
    local lines = {}
    for off = 0, len-1, cols do
        local hex, asc = {}, {}
        for c = 0, cols-1 do
            if off+c < len then
                local b = buf[off+c]
                hex[#hex+1] = string.format("%02X", b)
                asc[#asc+1] = (b >= 32 and b < 127) and string.char(b) or "."
            else hex[#hex+1]="  "; asc[#asc+1]=" " end
        end
        lines[#lines+1] = string.format("%08X  %s  |%s|", addr+off, table.concat(hex," "), table.concat(asc))
    end
    local s = table.concat(lines, "\n")
    print(s)
    return s
end

function M.list()
    if not next(registry) then print("No registered structs"); return registry end
    print("Registered structs:")
    for name, fields in pairs(registry) do
        print(string.format("  %s (%d fields, sizeof %s)", name, #fields, tostring(sizeof_of(name) or "?")))
    end
    return registry
end

return M
