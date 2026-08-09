-- Europa 1400 - Live Memory Patcher
--
-- Patch bytes in the game process with automatic VirtualProtect
-- handling and restore support. For NOPing, bypassing checks, and
-- inline JMP hooks during reverse engineering.
--
--   patch = dofile('lua/patch.lua')
--   patch.nop(0x401000, 5)
--   patch.bytes("0x401000", "90 90 90 90 90")
--   patch.jmp(0x401000, 0x402000)           -- E9 rel32 at src -> dst
--   patch.restore(0x401000)                 -- undo last patch at addr
--   patch.restore_all()
--   patch.dump(0x401000, 16)

local ffi = require("ffi")

ffi.cdef[[
    void* GetModuleHandleA(const char* lpModuleName);
    void* GetCurrentProcess(void);
    int   ReadProcessMemory(void* hProcess, const void* lpBaseAddress,
                            void* lpBuffer, unsigned long nSize,
                            unsigned long* lpNumberOfBytesRead);
    int   WriteProcessMemory(void* hProcess, void* lpBaseAddress,
                             const void* lpBuffer, unsigned long nSize,
                             unsigned long* lpNumberOfBytesWritten);
    int   VirtualProtect(void* lpAddress, unsigned long dwSize,
                         unsigned long flNewProtect, unsigned long* lpflOldProtect);
    int   VirtualProtectEx(void* hProcess, void* lpAddress, unsigned long dwSize,
                           unsigned long flNewProtect, unsigned long* lpflOldProtect);
    int   FlushInstructionCache(void* hProcess, const void* lpBaseAddress, unsigned long dwSize);
]]

local kernel32 = ffi.load("kernel32")

local PAGE_EXECUTE_READWRITE = 0x40

local backups = {} -- addr -> { bytes = "...", len = n }

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

local function parse_bytes(input)
    if type(input) == "table" then
        for i, b in ipairs(input) do
            if type(b) ~= "number" or b < 0 or b > 255 then
                error(string.format("byte[%d] out of range 0..255", i))
            end
        end
        return input
    end
    if type(input) ~= "string" then error("bytes must be hex string or byte table") end
    local s = input:gsub(",", " ")
    local out = {}
    -- allow "9090EB" (no spaces) -> pairs of hex chars
    local has_space = s:find("%s") ~= nil
    if not has_space and #s >= 2 and s:match("^[0-9a-fA-F]+$") and (#s % 2 == 0) then
        for i = 1, #s, 2 do
            local b = tonumber(s:sub(i, i+1), 16)
            if not b then error("invalid hex byte: " .. s:sub(i, i+1)) end
            out[#out+1] = b
        end
    else
        for tok in s:gmatch("%S+") do
            -- allow "0x90" prefix
            tok = tok:gsub("^0[xX]", "")
            local b = tonumber(tok, 16)
            if not b or b < 0 or b > 255 then error("invalid hex byte: " .. tok) end
            out[#out+1] = b
        end
    end
    if #out == 0 then error("empty patch") end
    return out
end

local function protect_writable(addr, len)
    local old = ffi.new("unsigned long[1]")
    if kernel32.VirtualProtect(ffi.cast("void*", addr), len, PAGE_EXECUTE_READWRITE, old) == 0 then
        -- fallback to VirtualProtectEx on current process (same effect)
        if kernel32.VirtualProtectEx(kernel32.GetCurrentProcess(), ffi.cast("void*", addr), len, PAGE_EXECUTE_READWRITE, old) == 0 then
            error(string.format("VirtualProtect failed at 0x%08X (len %d)", addr, len))
        end
    end
    return tonumber(old[0])
end

local function restore_protect(addr, len, old)
    local tmp = ffi.new("unsigned long[1]")
    kernel32.VirtualProtect(ffi.cast("void*", addr), len, old, tmp)
    kernel32.FlushInstructionCache(kernel32.GetCurrentProcess(), ffi.cast("void*", addr), len)
end

local function read_bytes_raw(addr, len)
    local buf = ffi.new("uint8_t[?]", len)
    local got = ffi.new("unsigned long[1]")
    if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", addr), buf, len, got) == 0 then
        error(string.format("ReadProcessMemory failed at 0x%08X", addr))
    end
    local n = tonumber(got[0])
    local t = {}
    for i = 0, n-1 do t[i+1] = buf[i] end
    return t, buf, n
end

local M = {}

function M.read(addr, len)
    addr = to_addr(addr)
    len = len or 16
    if len <= 0 or len > 4096 then error("len out of range") end
    local bytes = read_bytes_raw(addr, len)
    local hex = {}
    for i, b in ipairs(bytes) do hex[i] = string.format("%02X", b) end
    local s = string.format("0x%08X: %s", addr, table.concat(hex, " "))
    print(s)
    return bytes
end
M.dump = M.read

-- Patch `len` bytes at `addr` with `hex_or_bytes`
function M.bytes(addr, hex_or_bytes)
    addr = to_addr(addr)
    local b = parse_bytes(hex_or_bytes)
    local len = #b
    local orig = read_bytes_raw(addr, len)
    local key = addr
    if not backups[key] then backups[key] = { bytes = orig, len = len } end
    -- Also save per-range for restore_all correctness if same addr patched twice with different len:
    -- keep first backup only (original bytes), updates still applied.

    local old = protect_writable(addr, len)
    local buf = ffi.new("uint8_t[?]", len)
    for i = 0, len-1 do buf[i] = b[i+1] end
    local written = ffi.new("unsigned long[1]")
    local ok = kernel32.WriteProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", addr), buf, len, written) ~= 0
        and tonumber(written[0]) == len
    restore_protect(addr, len, old)
    if not ok then error(string.format("WriteProcessMemory failed at 0x%08X", addr)) end
    print(string.format("Patched 0x%08X (%d bytes): %s", addr, len, table.concat((function()
        local t={}; for _,v in ipairs(b) do t[#t+1]=string.format("%02X",v) end; return t
    end)(), " ")))
    return true
end

function M.nop(addr, len)
    addr = to_addr(addr)
    if type(len) ~= "number" or len <= 0 or len > 1024 then error("len must be 1..1024") end
    local t = {}
    for i = 1, len do t[i] = 0x90 end
    return M.bytes(addr, t)
end

-- Write a 5-byte JMP rel32 at `src` that jumps to `dst`
-- If `nop_len` is given and >5, pads remainder with NOPs
function M.jmp(src, dst, nop_len)
    src = to_addr(src); dst = to_addr(dst)
    local rel = dst - (src + 5)
    -- rel must fit in int32
    if rel < -0x80000000 or rel > 0x7FFFFFFF then
        error(string.format("JMP target out of rel32 range: src 0x%08X dst 0x%08X rel %d", src, dst, rel))
    end
    local b = { 0xE9,
        bit and bit.band(rel, 0xFF) or (rel % 256),
        bit and bit.band(bit.rshift(rel, 8), 0xFF) or (math.floor(rel/256) % 256),
        bit and bit.band(bit.rshift(rel, 16), 0xFF) or (math.floor(rel/65536) % 256),
        bit and bit.band(bit.rshift(rel, 24), 0xFF) or (math.floor(rel/16777216) % 256),
    }
    -- LuaJIT has `bit` lib; fallback above uses math if missing
    if not bit then
        -- recompute cleanly without bit
        local u = rel >= 0 and rel or (0x100000000 + rel)
        b[2] = u % 256; b[3] = math.floor(u/256)%256; b[4]=math.floor(u/65536)%256; b[5]=math.floor(u/16777216)%256
    end
    if nop_len and nop_len > 5 then
        for _ = 6, nop_len do b[#b+1] = 0x90 end
    end
    return M.bytes(src, b)
end

-- Like jmp but uses CALL rel32 (E8)
function M.call(src, dst, nop_len)
    src = to_addr(src); dst = to_addr(dst)
    local rel = dst - (src + 5)
    if rel < -0x80000000 or rel > 0x7FFFFFFF then
        error(string.format("CALL target out of rel32 range: src 0x%08X dst 0x%08X", src, dst))
    end
    local u = rel >= 0 and rel or (0x100000000 + rel)
    local b = { 0xE8, u%256, math.floor(u/256)%256, math.floor(u/65536)%256, math.floor(u/16777216)%256 }
    if not bit then
        -- already computed via math, ok
    else
        b[2]=bit.band(rel,0xFF); b[3]=bit.band(bit.rshift(rel,8),0xFF); b[4]=bit.band(bit.rshift(rel,16),0xFF); b[5]=bit.band(bit.rshift(rel,24),0xFF)
    end
    if nop_len and nop_len > 5 then for _=6,nop_len do b[#b+1]=0x90 end end
    return M.bytes(src, b)
end

function M.restore(addr)
    addr = to_addr(addr)
    local bk = backups[addr]
    if not bk then error(string.format("no backup for 0x%08X (was it patched?)", addr)) end
    local old = protect_writable(addr, bk.len)
    local buf = ffi.new("uint8_t[?]", bk.len)
    for i = 0, bk.len-1 do buf[i] = bk.bytes[i+1] end
    local written = ffi.new("unsigned long[1]")
    local ok = kernel32.WriteProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", addr), buf, bk.len, written) ~= 0
    restore_protect(addr, bk.len, old)
    if not ok then error(string.format("restore failed at 0x%08X", addr)) end
    backups[addr] = nil
    print(string.format("Restored 0x%08X (%d bytes)", addr, bk.len))
    return true
end

function M.restore_all()
    local addrs = {}
    for a in pairs(backups) do addrs[#addrs+1]=a end
    table.sort(addrs)
    for _, a in ipairs(addrs) do
        -- pcall each so one failure doesn't block others
        local ok, err = pcall(M.restore, a)
        if not ok then print("restore failed at " .. string.format("0x%08X: %s", a, err)) end
    end
    return true
end

function M.list()
    if not next(backups) then print("No active patches"); return {} end
    print("Active patches:")
    for addr, bk in pairs(backups) do
        local cur = read_bytes_raw(addr, bk.len)
        local function hx(t) local r={}; for _,v in ipairs(t) do r[#r+1]=string.format("%02X",v) end; return table.concat(r," ") end
        print(string.format("  0x%08X  len %2d  orig: %s  cur: %s", addr, bk.len, hx(bk.bytes), hx(cur)))
    end
    return backups
end

return M
