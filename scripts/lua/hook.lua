-- Europa 1400 - Import Hook Helper
--
-- Patch IAT entries to redirect imported API calls. Useful to log,
-- block, or replace game imports (file, registry, network, etc.)
-- without inline code caves.
--
--   hook = require("hook")
--   hook.list("game.exe")                     -- show IAT slots
--   old = hook.iat("game.exe", "kernel32.dll", "CreateFileA", myFn)
--   hook.restore("game.exe", "kernel32.dll", "CreateFileA")
--   hook.restore_all()
--
-- myFn must be an FFI function pointer (ffi.cast) already registered
-- via game.register or a stub you provide. For quick logging stubs
-- use hook.stub("CreateFileA").

local ffi = require("ffi")

ffi.cdef[[
    void* GetModuleHandleA(const char* lpModuleName);
    void* GetCurrentProcess(void);
    int   ReadProcessMemory(void* hProcess, const void* lpBaseAddress,
                            void* lpBuffer, unsigned long nSize,
                            unsigned long* lpNumberOfBytesRead);
    int   WriteProcessMemory(void* hProcess, const void* lpBaseAddress,
                             const void* lpBuffer, unsigned long nSize,
                             unsigned long* lpNumberOfBytesWritten);
    int   VirtualProtect(void* lpAddress, unsigned long dwSize,
                         unsigned long flNewProtect, unsigned long* lpflOldProtect);
    int   FlushInstructionCache(void* hProcess, const void* lpBaseAddress, unsigned long dwSize);
]]

local kernel32 = ffi.load("kernel32")
local PAGE_EXECUTE_READWRITE = 0x40

local backups = {} -- "mod|dll|func" -> { addr, old }

local function to_mod_base(mod)
    if not mod or mod == "" then
        local h = kernel32.GetModuleHandleA(nil)
        if h == nil then error("GetModuleHandleA(nil) failed") end
        return tonumber(ffi.cast("uintptr_t", h)), "(main exe)"
    end
    local h = kernel32.GetModuleHandleA(mod)
    if h == nil then error("module not loaded: " .. tostring(mod)) end
    return tonumber(ffi.cast("uintptr_t", h)), mod
end

local function ru32(base, off) return tonumber(ffi.cast("uint32_t*", base + off)[0]) end
local function ru16(base, off) return tonumber(ffi.cast("uint16_t*", base + off)[0]) end
local function rstr(base, rva) if rva==0 then return "" end; return ffi.string(ffi.cast("char*", base + rva)) end

local function find_iat(mod, dll_name, func_name)
    local base = to_mod_base(mod)
    if ru16(base, 0) ~= 0x5A4D then error("bad DOS magic") end
    local lfanew = ru32(base, 0x3C)
    if ru32(base, lfanew) ~= 0x00004550 then error("bad NT sig") end
    local file_hdr = lfanew + 4
    local opt = file_hdr + 20
    local magic = ru16(base, opt)
    local is64 = (magic == 0x020B)
    local dd = is64 and (opt + 112) or (opt + 96)
    local imp_rva = ru32(base, dd + 8)
    local imp_sz  = ru32(base, dd + 12)
    if imp_rva == 0 then error("no imports") end
    local target_dll = dll_name:lower()
    local off = imp_rva
    for _ = 1, 256 do
        local name_rva = ru32(base, off + 12)
        if name_rva == 0 then break end
        local dll = rstr(base, name_rva):lower()
        if dll == target_dll then
            local oft = ru32(base, off + 0)  -- OriginalFirstThunk (hint/name table)
            local ft  = ru32(base, off + 16) -- FirstThunk (IAT)
            if oft == 0 then oft = ft end
            if ft == 0 then error("no IAT for " .. dll_name) end
            -- walk thunks
            local idx = 0
            while true do
                local val = is64 and tonumber(ffi.cast("uint64_t*", base + oft + idx*(is64 and 8 or 4))[0]) or ru32(base, oft + idx*4)
                if val == 0 then break end
                local is_ord = is64 and (val >= 0x8000000000000000) or (val >= 0x80000000)
                local name = nil
                if not is_ord then
                    -- low 31/63 bits = hint/name RVA; skip hint word
                    local rva = is64 and (val % 0x8000000000000000) or (val % 0x80000000)
                    name = rstr(base, rva + 2)
                end
                if name and name:lower() == func_name:lower() then
                    local iat_addr = base + ft + idx * (is64 and 8 or 4)
                    local cur = is64 and tonumber(ffi.cast("uint64_t*", iat_addr)[0]) or ru32(base, ft + idx*4)
                    -- cur is current VA (resolved by loader)
                    return iat_addr, cur, dll, name
                end
                idx = idx + 1
                if idx > 5000 then break end
            end
            error(string.format("import not found: %s!%s in %s", dll_name, func_name, tostring(mod)))
        end
        off = off + 20
        if off >= imp_rva + imp_sz then break end
    end
    error(string.format("DLL not found in imports: %s (in %s)", dll_name, tostring(mod)))
end

local function patch_ptr(iat_addr, new_val, is64)
    local sz = is64 and 8 or 4
    local old = ffi.new("unsigned long[1]")
    if kernel32.VirtualProtect(ffi.cast("void*", iat_addr), sz, PAGE_EXECUTE_READWRITE, old) == 0 then
        error("VirtualProtect failed")
    end
    local op = old[0]
    local buf = is64 and ffi.new("uint64_t[1]", new_val) or ffi.new("uint32_t[1]", new_val)
    local written = ffi.new("unsigned long[1]")
    local ok = kernel32.WriteProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", iat_addr), buf, sz, written) ~= 0
    local tmp = ffi.new("unsigned long[1]")
    kernel32.VirtualProtect(ffi.cast("void*", iat_addr), sz, op, tmp)
    kernel32.FlushInstructionCache(kernel32.GetCurrentProcess(), ffi.cast("void*", iat_addr), sz)
    if not ok then error("WriteProcessMemory failed at IAT") end
    return op
end

local M = {}

function M.list(mod)
    local base, label = to_mod_base(mod)
    if ru16(base, 0) ~= 0x5A4D then error("bad DOS magic") end
    local lfanew = ru32(base, 0x3C)
    local opt = lfanew + 4 + 20
    local magic = ru16(base, opt)
    local is64 = (magic == 0x020B)
    local dd = is64 and (opt + 112) or (opt + 96)
    local imp_rva = ru32(base, dd + 8)
    local imp_sz  = ru32(base, dd + 12)
    if imp_rva == 0 then print("No imports for " .. label); return {} end
    print(string.format("IAT for %s @ 0x%08X", label, base))
    print(string.rep("-", 60))
    local out = {}
    local off = imp_rva
    for _ = 1, 64 do
        local name_rva = ru32(base, off + 12)
        if name_rva == 0 then break end
        local dll = rstr(base, name_rva)
        local oft = ru32(base, off + 0); local ft = ru32(base, off + 16)
        if oft == 0 then oft = ft end
        print(string.format("  %s  (oft 0x%X  iat 0x%X)", dll, oft, ft))
        local idx = 0
        while idx < 32 do
            local val = is64 and tonumber(ffi.cast("uint64_t*", base + oft + idx*(is64 and 8 or 4))[0]) or ru32(base, oft + idx*4)
            if val == 0 then break end
            local is_ord = is64 and (val >= 0x8000000000000000) or (val >= 0x80000000)
            local name = is_ord and ("#ordinal " .. tostring(val % 0x10000)) or rstr(base, (is64 and (val % 0x8000000000000000) or (val % 0x80000000)) + 2)
            print(string.format("    [%2d] %-32s  iat 0x%08X", idx, name, base + ft + idx*(is64 and 8 or 4)))
            idx = idx + 1
        end
        if idx >= 32 then print("    ...") end
        off = off + 20
        if off >= imp_rva + imp_sz then break end
        out[#out+1] = dll
    end
    return out
end

-- Create a simple logging stub that forwards to original (for quick triage)
-- Returns cdata function pointer; keep it alive while hooked.
function M.stub(name, signature)
    signature = signature or "int(__stdcall*)(void)"
    -- generic stub: log and return 0; user can replace with real logic
    -- We cannot create a true Lua callback as imported function without
    -- knowing signature; this is a placeholder that prints and returns 0.
    -- For real hooks, provide your own ffi.cast(signature.."*", addr)
    print(string.format("hook.stub: create your own stub via ffi.cast('%s*', addr) for %s", signature, name))
    return nil
end

function M.iat(mod, dll, func, new_addr)
    if type(dll) ~= "string" or type(func) ~= "string" then error("dll and func must be strings") end
    local new_val
    if type(new_addr) == "number" then new_val = new_addr
    elseif type(new_addr) == "cdata" then new_val = tonumber(ffi.cast("uintptr_t", new_addr))
    elseif type(new_addr) == "string" then
        local s = new_addr:gsub("^0[xX]", "")
        new_val = tonumber(s, 16)
        if not new_val then error("invalid new_addr: " .. new_addr) end
    else error("new_addr must be number/cdata/hex string") end
    local base, _ = to_mod_base(mod)
    local lfanew = ru32(base, 0x3C)
    local is64 = (ru16(base, lfanew + 4 + 20) == 0x020B)
    local iat_addr, old_val = find_iat(mod, dll, func)
    local key = string.format("%s|%s|%s", tostring(mod or "exe"), dll:lower(), func:lower())
    if not backups[key] then backups[key] = { addr = iat_addr, old = old_val, is64 = is64 } end
    patch_ptr(iat_addr, new_val, is64)
    print(string.format("hook.iat %s!%s in %s: 0x%08X -> 0x%08X  (iat 0x%08X)", dll, func, tostring(mod or "exe"), old_val, new_val, iat_addr))
    return old_val
end

function M.restore(mod, dll, func)
    local key = string.format("%s|%s|%s", tostring(mod or "exe"), dll:lower(), func:lower())
    local bk = backups[key]
    if not bk then error("no backup for " .. key) end
    patch_ptr(bk.addr, bk.old, bk.is64)
    backups[key] = nil
    print(string.format("hook.restore %s: back to 0x%08X", key, bk.old))
    return bk.old
end

function M.restore_all()
    local keys = {}
    for k in pairs(backups) do keys[#keys+1]=k end
    for _, k in ipairs(keys) do
        local bk = backups[k]
        patch_ptr(bk.addr, bk.old, bk.is64)
        print(string.format("hook.restore %s -> 0x%08X", k, bk.old))
    end
    for k in pairs(backups) do backups[k]=nil end
end

function M.backups() return backups end

return M
