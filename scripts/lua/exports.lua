-- Europa 1400 - PE Export / Import Inspector
--
-- Enumerate exports and imports of any loaded module by parsing its
-- PE headers directly from process memory. No hard-coded offsets:
-- works under ASLR and across game versions.
--
-- Usage:
--   exports.list("game.exe")          -- list exports
--   exports.list()                    -- list exports of main exe
--   exports.resolve("kernel32.dll", "CreateFileA")
--   exports.imports("game.exe")

local ffi = require("ffi")

ffi.cdef[[
    void* GetModuleHandleA(const char* lpModuleName);
    unsigned long GetModuleFileNameA(void* hModule, char* lpFilename, unsigned long nSize);
    void* GetCurrentProcess(void);
    int ReadProcessMemory(void* hProcess, const void* lpBaseAddress,
                          void* lpBuffer, unsigned long nSize,
                          unsigned long* lpNumberOfBytesRead);
]]

local kernel32 = ffi.load("kernel32")

local function get_base(mod)
    if not mod or mod == "" then
        -- main exe: GetModuleHandleA(nil) returns exe base
        local h = kernel32.GetModuleHandleA(nil)
        if h == nil then error("GetModuleHandleA(nil) failed") end
        return tonumber(ffi.cast("uintptr_t", h)), "(main exe)"
    end
    local h = kernel32.GetModuleHandleA(mod)
    if h == nil then error("module not loaded: " .. tostring(mod)) end
    return tonumber(ffi.cast("uintptr_t", h)), mod
end

local function read_u16(base, off)
    return tonumber(ffi.cast("uint16_t*", base + off)[0])
end
local function read_u32(base, off)
    return tonumber(ffi.cast("uint32_t*", base + off)[0])
end
local function read_str(base, rva)
    if rva == 0 then return "" end
    return ffi.string(ffi.cast("char*", base + rva))
end

local function parse_exports(base)
    -- DOS header
    if read_u16(base, 0) ~= 0x5A4D then error("bad DOS magic") end
    local e_lfanew = read_u32(base, 0x3C)
    -- NT signature
    if read_u32(base, e_lfanew) ~= 0x00004550 then error("bad NT signature") end
    local file_hdr = e_lfanew + 4
    local num_sections = read_u16(base, file_hdr + 2)
    local opt_hdr = file_hdr + 20
    local magic = read_u16(base, opt_hdr)
    local is64 = (magic == 0x020B)
    -- DataDirectory[0] = exports
    local dd_off
    if is64 then dd_off = opt_hdr + 112 -- IMAGE_OPTIONAL_HEADER64.DataDirectory
    else dd_off = opt_hdr + 96  -- IMAGE_OPTIONAL_HEADER32.DataDirectory
    end
    local exp_rva  = read_u32(base, dd_off)
    local exp_size = read_u32(base, dd_off + 4)
    if exp_rva == 0 or exp_size == 0 then return {}, is64, num_sections end

    local exp_base = base + exp_rva
    local num_funcs = read_u32(base, exp_rva + 20) -- NumberOfFunctions
    local num_names = read_u32(base, exp_rva + 24) -- NumberOfNames
    local addr_funcs = read_u32(base, exp_rva + 28)
    local addr_names = read_u32(base, exp_rva + 32)
    local addr_ords  = read_u32(base, exp_rva + 36)
    -- sanity cap to avoid pathological loops
    if num_names > 20000 then num_names = 20000 end

    local out = {}
    for i = 0, num_names - 1 do
        local name_rva = read_u32(base, addr_names + i*4)
        local name = read_str(base, name_rva)
        local ord  = tonumber(ffi.cast("uint16_t*", base + addr_ords + i*2)[0])
        local func_rva = 0
        if ord < num_funcs then
            func_rva = read_u32(base, addr_funcs + ord*4)
        end
        local va = func_rva ~= 0 and (base + func_rva) or 0
        -- detect forwarded export (rva inside export dir)
        local forwarded = func_rva >= exp_rva and func_rva < exp_rva + exp_size
        local fwd_str = forwarded and read_str(base, func_rva) or nil
        table.insert(out, { name=name, ordinal=ord, rva=func_rva, va=va, forwarded=fwd_str })
    end
    table.sort(out, function(a,b) return a.name < b.name end)
    return out, is64
end

local function parse_imports(base)
    if read_u16(base, 0) ~= 0x5A4D then error("bad DOS magic") end
    local e_lfanew = read_u32(base, 0x3C)
    if read_u32(base, e_lfanew) ~= 0x00004550 then error("bad NT signature") end
    local file_hdr = e_lfanew + 4
    local opt_hdr = file_hdr + 20
    local magic = read_u16(base, opt_hdr)
    local is64 = (magic == 0x020B)
    local dd_off = is64 and (opt_hdr + 112) or (opt_hdr + 96)
    -- DataDirectory[1] = imports
    local imp_rva  = read_u32(base, dd_off + 8)
    local imp_size = read_u32(base, dd_off + 12)
    if imp_rva == 0 or imp_size == 0 then return {} end
    local out = {}
    local off = imp_rva
    for _ = 1, 256 do
        local name_rva = read_u32(base, off + 12)
        if name_rva == 0 then break end
        local dll = read_str(base, name_rva)
        local thunk = read_u32(base, off + 0) -- OriginalFirstThunk
        if thunk == 0 then thunk = read_u32(base, off + 16) end
        -- count thunks
        local count = 0
        local t = thunk
        while true do
            local v = is64 and tonumber(ffi.cast("uint64_t*", base + t)[0]) or read_u32(base, t)
            if v == 0 then break end
            count = count + 1
            t = t + (is64 and 8 or 4)
            if count > 5000 then break end
        end
        table.insert(out, { dll=dll, count=count, rva=off })
        off = off + 20
        if off >= imp_rva + imp_size then break end
    end
    return out
end

local M = {}

function M.list(mod)
    local base, label = get_base(mod)
    local exps = parse_exports(base)
    print(string.format("Exports of %s @ 0x%08X  (%d names)", label, base, #exps))
    print(string.rep("-", 60))
    for _, e in ipairs(exps) do
        if e.forwarded then
            print(string.format("  %-40s -> %s  (forwarded)", e.name, e.forwarded))
        else
            print(string.format("  %-40s 0x%08X (ord %d, rva 0x%X)", e.name, e.va, e.ordinal, e.rva))
        end
    end
    if #exps == 0 then print("  (no export names or stripped)") end
    return exps
end

function M.imports(mod)
    local base, label = get_base(mod)
    local imps = parse_imports(base)
    print(string.format("Imports of %s @ 0x%08X  (%d DLLs)", label, base, #imps))
    print(string.rep("-", 60))
    for _, im in ipairs(imps) do
        print(string.format("  %-20s  %d imports  (rva 0x%X)", im.dll, im.count, im.rva))
    end
    if #imps == 0 then print("  (no imports)") end
    return imps
end

function M.resolve(mod, name)
    if type(name) ~= "string" or name == "" then error("name must be non-empty string") end
    local base = get_base(mod)
    local exps = parse_exports(base)
    for _, e in ipairs(exps) do
        if e.name == name then
            if e.forwarded then
                print(string.format("%s!%s forwarded -> %s", tostring(mod), name, e.forwarded))
                return nil, e.forwarded
            end
            print(string.format("%s!%s = 0x%08X", tostring(mod), name, e.va))
            return e.va
        end
    end
    error(string.format("export not found: %s!%s", tostring(mod), name))
end

return M
