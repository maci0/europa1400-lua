-- Europa 1400 - Struct Code Generator
--
-- Generate Lua FFI + struct.register boilerplate from a compact
-- table so discoveries can be pasted directly into your analysis
-- files without hand-writing offsets.
--
--   codegen = require("codegen")  -- or already `codegen`
--   codegen.struct("Player", {
--     {name="gold", type="int"},
--     {name="fame", type="int"},
--     {name="name", type="char[32]"},
--   })
--   -- prints ffi.cdef + struct.register with computed offsets
--   codegen.cdef("Player", { {"gold","int"}, {"fame","int"} })

local M = {}

local struct = require("struct")

local function size_of(ctype)
    local ok, sz = pcall(require("ffi").sizeof, ctype)
    if ok then return sz end
    -- char[N]
    local n = ctype:match("^%s*char%s*%[%s*(%d+)%s*%]%s*$")
    if n then return tonumber(n) end
    -- fallback: assume 4 (int/pointer/float)
    if ctype:find("%*") then return 4 end
    if ctype == "float" or ctype:find("int") then return 4 end
    if ctype == "double" then return 8 end
    if ctype == "short" then return 2 end
    if ctype == "char" then return 1 end
    return 4
end

local function align_of(ctype)
    local sz = size_of(ctype)
    if sz >= 4 then return 4 end
    if sz == 2 then return 2 end
    return 1
end

local function next_aligned(off, align)
    return math.ceil(off / align) * align
end

-- Compute offsets with natural alignment, return field list with .offset
function M.layout(name, fields)
    if type(name) ~= "string" or name == "" then error("name required") end
    if type(fields) ~= "table" then error("fields must be array") end
    local out = {}
    local off = 0
    local max_align = 1
    for i, f in ipairs(fields) do
        local fname, ftype
        if type(f) == "table" then
            if type(f.name) == "string" and type(f.type) == "string" then
                fname, ftype = f.name, f.type
            elseif f[1] and f[2] then
                fname, ftype = f[1], f[2]
            else error(string.format("field[%d] must be {name,type} or {name=...,type=...}", i)) end
        else error(string.format("field[%d] must be table", i)) end
        local al = align_of(ftype)
        max_align = math.max(max_align, al)
        off = next_aligned(off, al)
        out[#out+1] = { name=fname, type=ftype, offset=off }
        off = off + size_of(ftype)
    end
    -- tail padding to max align
    local total = next_aligned(off, max_align)
    return out, total
end

function M.cdef(name, fields)
    local out, total = M.layout(name, fields)
    local lines = {}
    lines[#lines+1] = string.format("ffi.cdef[[\ntypedef struct {\n")
    for _, f in ipairs(out) do
        lines[#lines+1] = string.format("    %s %s; // +0x%X\n", f.type, f.name, f.offset)
    end
    lines[#lines+1] = string.format("} %s; // sizeof 0x%X (%d)\n]]", name, total, total)
    local s = table.concat(lines, "")
    print(s)
    return s, out, total
end

function M.struct(name, fields, opts)
    opts = opts or {}
    local out, total = M.layout(name, fields)
    local cdef = M.cdef(name, fields)
    local lines = {}
    lines[#lines+1] = string.format("struct.register(\"%s\", {\n", name)
    for _, f in ipairs(out) do
        lines[#lines+1] = string.format('    {name="%s", type="%s", offset=0x%X},\n', f.name, f.type, f.offset)
    end
    lines[#lines+1] = string.format("}) -- sizeof 0x%X\n", total)
    if opts.exec then
        local fn, err = load(cdef)
        if fn then pcall(fn) end
        if struct and struct.register then
            struct.register(name, out)
        end
    end
    local s = table.concat(lines, "")
    print(s)
    return s, out, total
end

function M.func_stub(name, sig, desc)
    if type(name) ~= "string" or name == "" then error("name required") end
    sig = sig or "int()"
    local s = string.format('game.register("%s", 0x%08X, "%s", "%s")',
        name, 0x00400000, sig, desc or "")
    print(s .. "  -- TODO: fill address")
    return s
end

return M
