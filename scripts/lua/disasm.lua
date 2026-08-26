-- Europa 1400 - Lightweight x86 Disassembler View
--
-- Best-effort disassembly for triaging functions found via scan/finder
-- without leaving the console. Not a full capstone replacement; it uses
-- a small opcode table for the most common 32-bit patterns you see in
-- MSVC-era game code (prologues, stack ops, calls, jumps, mov/push/pop,
-- ALU, ret). Falls back to `db 0x??` for unknown bytes.
--
--   disasm = require("disasm")
--   disasm.at(0x401000, 20)           -- 20 insns from addr
--   disasm.func(0x401000)             -- until RET or 64 insns
--   disasm.bytes("55 8B EC 83 EC 10") -- decode a hex string directly

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

local function read_bytes(addr, len)
    local buf = ffi.new("uint8_t[?]", len)
    local got = ffi.new("unsigned long[1]")
    if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", addr), buf, len, got) == 0 then
        return nil
    end
    local n = tonumber(got[0])
    local t = {}
    for i = 0, n-1 do t[i+1] = buf[i] end
    return t, buf, n
end

local function parse_hex(s)
    local out = {}
    for tok in s:gmatch("%S+") do
        tok = tok:gsub("^0[xX]", "")
        local b = tonumber(tok, 16)
        if not b or b < 0 or b > 255 then error("invalid hex byte: " .. tok) end
        out[#out+1] = b
    end
    -- also allow "9090" with no spaces
    if #out == 0 and s:match("^[0-9a-fA-F]+$") and #s % 2 == 0 then
        for i = 1, #s, 2 do out[#out+1] = tonumber(s:sub(i,i+1), 16) end
    end
    return out
end

-- very small mnemonic table for common opcodes; longer forms include modr/m handling
local REG32 = { "eax","ecx","edx","ebx","esp","ebp","esi","edi" }

local function reg_name(r) return REG32[(r % 8) + 1] end

local function decode_one(bytes, off, base_addr)
    -- off is 1-based index into bytes table
    local b0 = bytes[off]
    if not b0 then return 1, "db ?" end
    local addr = base_addr + (off - 1)
    local function hx(n) return string.format("%02X", n) end
    local function hex_bytes(n)
        local t = {}
        for i = 0, n-1 do if bytes[off+i] then t[#t+1] = hx(bytes[off+i]) else break end end
        return table.concat(t, " ")
    end

    -- single-byte
    if b0 == 0x55 then return 1, "push ebp"
    elseif b0 == 0x5D then return 1, "pop ebp"
    elseif b0 == 0x53 then return 1, "push ebx"
    elseif b0 == 0x56 then return 1, "push esi"
    elseif b0 == 0x57 then return 1, "push edi"
    elseif b0 == 0x5B then return 1, "pop ebx"
    elseif b0 == 0x5E then return 1, "pop esi"
    elseif b0 == 0x5F then return 1, "pop edi"
    elseif b0 == 0x90 then return 1, "nop"
    elseif b0 == 0xCC then return 1, "int3"
    elseif b0 == 0xC3 then return 1, "ret"
    elseif b0 == 0xC2 then
        local imm = bytes[off+1] and (bytes[off+1] + bytes[off+2]*256) or 0
        return 3, string.format("ret 0x%X", imm)
    elseif b0 == 0xCB then return 1, "retf"
    elseif b0 == 0xF4 then return 1, "hlt"
    elseif b0 == 0xFC then return 1, "cld"
    elseif b0 == 0xFD then return 1, "std"
    elseif b0 >= 0x50 and b0 <= 0x57 then return 1, "push " .. reg_name(b0 - 0x50)
    elseif b0 >= 0x58 and b0 <= 0x5F then return 1, "pop " .. reg_name(b0 - 0x58)
    elseif b0 == 0xE8 then
        local rel = bytes[off+1] and (bytes[off+1] + bytes[off+2]*256 + bytes[off+3]*65536 + bytes[off+4]*16777216) or 0
        if rel >= 0x80000000 then rel = rel - 0x100000000 end
        local dst = addr + 5 + rel
        return 5, string.format("call 0x%08X", dst % 0x100000000)
    elseif b0 == 0xE9 then
        local rel = bytes[off+1] and (bytes[off+1] + bytes[off+2]*256 + bytes[off+3]*65536 + bytes[off+4]*16777216) or 0
        if rel >= 0x80000000 then rel = rel - 0x100000000 end
        local dst = addr + 5 + rel
        return 5, string.format("jmp 0x%08X", dst % 0x100000000)
    elseif b0 == 0xEB then
        local rel = bytes[off+1] or 0
        if rel >= 0x80 then rel = rel - 0x100 end
        local dst = addr + 2 + rel
        return 2, string.format("jmp short 0x%08X", dst % 0x100000000)
    elseif b0 == 0x68 then
        local imm = bytes[off+1] and (bytes[off+1] + bytes[off+2]*256 + bytes[off+3]*65536 + bytes[off+4]*16777216) or 0
        return 5, string.format("push 0x%X", imm)
    elseif b0 == 0x6A then
        local imm = bytes[off+1] or 0
        if imm >= 0x80 then imm = imm - 0x100 end
        return 2, string.format("push %d", imm)
    elseif b0 == 0x8B then
        local modrm = bytes[off+1]
        if not modrm then return 1, "mov ?" end
        local mod = math.floor(modrm / 64)
        local reg = math.floor((modrm % 64) / 8)
        local rm  = modrm % 8
        local dst = reg_name(reg)
        if mod == 3 then return 2, string.format("mov %s, %s", dst, reg_name(rm))
        elseif mod == 0 and rm == 5 then
            local disp = bytes[off+2] and (bytes[off+2] + bytes[off+3]*256 + bytes[off+4]*65536 + bytes[off+5]*16777216) or 0
            return 6, string.format("mov %s, [0x%08X]", dst, disp)
        elseif mod == 1 then
            local disp = bytes[off+2] or 0
            if disp >= 0x80 then disp = disp - 0x100 end
            return 3, string.format("mov %s, [%s%+d]", dst, reg_name(rm), disp)
        elseif mod == 2 then
            local disp = bytes[off+2] and (bytes[off+2] + bytes[off+3]*256 + bytes[off+4]*65536 + bytes[off+5]*16777216) or 0
            if disp >= 0x80000000 then disp = disp - 0x100000000 end
            return 6, string.format("mov %s, [%s%+d]", dst, reg_name(rm), disp)
        else
            return 2, string.format("mov %s, [%s]", dst, reg_name(rm))
        end
    elseif b0 == 0x89 then
        local modrm = bytes[off+1]
        if not modrm then return 1, "mov ?" end
        local mod = math.floor(modrm / 64)
        local reg = math.floor((modrm % 64) / 8)
        local rm  = modrm % 8
        local src = reg_name(reg)
        if mod == 3 then return 2, string.format("mov %s, %s", reg_name(rm), src)
        else return 2, string.format("mov [%s], %s", reg_name(rm), src) end
    elseif b0 == 0x83 then
        local modrm = bytes[off+1]; local imm = bytes[off+2] or 0
        if imm >= 0x80 then imm = imm - 0x100 end
        local ops = { "add","or","adc","sbb","and","sub","xor","cmp" }
        local op = ops[math.floor((modrm % 64)/8)+1] or "?"
        return 3, string.format("%s %s, %d", op, reg_name(modrm % 8), imm)
    elseif b0 == 0x81 then
        local modrm = bytes[off+1]
        local ops = { "add","or","adc","sbb","and","sub","xor","cmp" }
        local op = ops[math.floor((modrm % 64)/8)+1] or "?"
        return 6, string.format("%s %s, 0x%X", op, reg_name(modrm % 8), bytes[off+2] or 0)
    elseif b0 == 0x33 or b0 == 0x32 or b0 == 0x2B or b0 == 0x03 then
        local verbs = { [0x33]="xor", [0x32]="xor", [0x2B]="sub", [0x03]="add" }
        local modrm = bytes[off+1]
        if modrm then
            local reg = math.floor((modrm % 64)/8); local rm = modrm % 8
            return 2, string.format("%s %s, %s", verbs[b0], reg_name(reg), reg_name(rm))
        end
        return 1, verbs[b0] or "?"
    elseif b0 == 0x85 then
        local modrm = bytes[off+1]
        if modrm then
            local reg = math.floor((modrm % 64)/8); local rm = modrm % 8
            return 2, string.format("test %s, %s", reg_name(rm), reg_name(reg))
        end
        return 1, "test ?"
    elseif b0 == 0x74 or b0 == 0x75 or b0 == 0x7C or b0 == 0x7D or b0 == 0x7E or b0 == 0x7F then
        local jcc = { [0x74]="jz", [0x75]="jnz", [0x7C]="jl", [0x7D]="jge", [0x7E]="jle", [0x7F]="jg" }
        local rel = bytes[off+1] or 0; if rel >= 0x80 then rel = rel - 0x100 end
        local dst = addr + 2 + rel
        return 2, string.format("%s 0x%08X", jcc[b0], dst % 0x100000000)
    elseif b0 == 0x0F then
        local b1 = bytes[off+1]
        if b1 and b1 >= 0x80 and b1 <= 0x8F then
            local jcc = { "jo","jno","jb","jnb","jz","jnz","jbe","ja","js","jns","jp","jnp","jl","jge","jle","jg" }
            local idx = (b1 - 0x80) + 1
            local rel = bytes[off+2] and (bytes[off+2] + bytes[off+3]*256 + bytes[off+4]*65536 + bytes[off+5]*16777216) or 0
            if rel >= 0x80000000 then rel = rel - 0x100000000 end
            local dst = addr + 6 + rel
            return 6, string.format("%s 0x%08X", jcc[idx] or "jcc", dst % 0x100000000)
        elseif b1 == 0xAF then
            local modrm = bytes[off+2]
            if modrm then
                local reg = math.floor((modrm % 64)/8); local rm = modrm % 8
                return 3, string.format("imul %s, %s", reg_name(reg), reg_name(rm))
            end
            return 2, "imul ?"
        end
        return 1, string.format("db 0x%02X", b0)
    elseif b0 == 0xFF then
        local modrm = bytes[off+1]
        if modrm then
            local ext = math.floor((modrm % 64)/8)
            if ext == 2 then return 2, string.format("call [%s]", reg_name(modrm % 8))
            elseif ext == 4 then return 2, string.format("jmp [%s]", reg_name(modrm % 8))
            elseif ext == 0 then return 2, string.format("inc [%s]", reg_name(modrm % 8))
            elseif ext == 1 then return 2, string.format("dec [%s]", reg_name(modrm % 8))
            end
        end
        return 1, string.format("db 0x%02X", b0)
    elseif b0 == 0xA1 then
        local disp = bytes[off+1] and (bytes[off+1] + bytes[off+2]*256 + bytes[off+3]*65536 + bytes[off+4]*16777216) or 0
        return 5, string.format("mov eax, [0x%08X]", disp)
    elseif b0 == 0xA3 then
        local disp = bytes[off+1] and (bytes[off+1] + bytes[off+2]*256 + bytes[off+3]*65536 + bytes[off+4]*16777216) or 0
        return 5, string.format("mov [0x%08X], eax", disp)
    elseif b0 == 0xB8 or b0 == 0xB9 or b0 == 0xBA or b0 == 0xBB or b0 == 0xBC or b0 == 0xBD or b0 == 0xBE or b0 == 0xBF then
        local reg = reg_name(b0 - 0xB8)
        local imm = bytes[off+1] and (bytes[off+1] + bytes[off+2]*256 + bytes[off+3]*65536 + bytes[off+4]*16777216) or 0
        return 5, string.format("mov %s, 0x%08X", reg, imm)
    end
    return 1, string.format("db 0x%02X", b0)
end

local M = {}

function M.decode(hex_string)
    local bytes = parse_hex(hex_string)
    local lines = {}
    local off = 1
    local fake_base = 0
    while off <= #bytes do
        local len, mnem = decode_one(bytes, off, fake_base)
        local hex = {}
        for i = 0, len-1 do if bytes[off+i] then hex[#hex+1]=string.format("%02X", bytes[off+i]) end end
        lines[#lines+1] = string.format("%04X  %-16s  %s", off-1, table.concat(hex, " "), mnem)
        off = off + len
    end
    local s = table.concat(lines, "\n")
    print(s)
    return s
end

function M.at(addr, count)
    addr = to_addr(addr); count = count or 20
    if count <= 0 or count > 500 then error("count out of range 1..500") end
    local raw, _, n = read_bytes(addr, count * 6 + 16)
    if not raw then print(string.format("Read failed at 0x%08X", addr)); return nil end
    -- convert raw table (1-based) already; need size n
    local bytes = {}
    for i = 1, n do bytes[i] = raw[i] end
    local lines = {}
    local off = 1
    local emitted = 0
    while off <= #bytes and emitted < count do
        local len, mnem = decode_one(bytes, off, addr)
        if off + len - 1 > #bytes then break end
        local hex = {}
        for i = 0, math.min(len, 6)-1 do hex[#hex+1] = string.format("%02X", bytes[off+i] or 0) end
        if len > 6 then hex[#hex+1] = "..." end
        lines[#lines+1] = string.format("%08X  %-20s  %s", addr + off - 1, table.concat(hex, " "), mnem)
        off = off + len
        emitted = emitted + 1
    end
    local s = table.concat(lines, "\n")
    print(s)
    return s
end

function M.func(addr, max_insns)
    addr = to_addr(addr); max_insns = max_insns or 64
    local raw, _, n = read_bytes(addr, max_insns * 6 + 32)
    if not raw then print(string.format("Read failed at 0x%08X", addr)); return nil end
    local bytes = {}
    for i = 1, n do bytes[i] = raw[i] end
    local lines = {}
    local off = 1
    for _ = 1, max_insns do
        if off > #bytes then break end
        local len, mnem = decode_one(bytes, off, addr)
        if off + len - 1 > #bytes then break end
        local hex = {}
        for i = 0, math.min(len, 6)-1 do hex[#hex+1] = string.format("%02X", bytes[off+i] or 0) end
        if len > 6 then hex[#hex+1] = "..." end
        lines[#lines+1] = string.format("%08X  %-20s  %s", addr + off - 1, table.concat(hex, " "), mnem)
        off = off + len
        if mnem:match("^ret") then break end
    end
    local s = table.concat(lines, "\n")
    print(s)
    return s
end

return M
