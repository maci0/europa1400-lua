-- Europa 1400 - Cross-Reference Finder
--
-- Finds code references to an address/string: CALL/JMP targets,
-- PUSH immediates, MOV-with-imm, and absolute pointers.
-- Useful to trace "what calls this function" without Ghidra.
--
-- Usage:
--   xrefs.to(0x00401000, 0x00400000, 0x200000)
--   xrefs.calls_to("GetPlayerGold")        -- resolves via game registry
--   xrefs.string_refs("Gold")

local ffi = require("ffi")

ffi.cdef[[
    void* GetCurrentProcess(void);
    int ReadProcessMemory(void* hProcess, const void* lpBaseAddress,
                          void* lpBuffer, unsigned long nSize,
                          unsigned long* lpNumberOfBytesRead);
]]

local kernel32 = ffi.load("kernel32")

local function to_addr(v)
    if type(v) == "string" then
        local s = v:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^0[xX]", "")
        local n = tonumber(s, 16)
        if not n then error("invalid address: " .. v) end
        return n
    elseif type(v) == "number" then return v
    else error("address must be number or hex string") end
end

local function read_bytes(base, size)
    if size <= 0 or size > 0x2000000 then error("size out of range") end
    local buf = ffi.new("uint8_t[?]", size)
    local got = ffi.new("unsigned long[1]")
    if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(),
        ffi.cast("void*", base), buf, size, got) == 0 then
        error(string.format("ReadProcessMemory failed at 0x%08X", base))
    end
    return buf, tonumber(got[0])
end

local M = {}

-- Find xrefs to target address in [base, base+size).
-- Checks: E8 call rel32, E9 jmp rel32, 68 push imm32, C7 /0 mov imm32,
-- and raw 4-byte little-endian pointer.
function M.to(target, base, size, max_hits)
    target = to_addr(target)
    base = to_addr(base)
    if type(size) ~= "number" or size <= 0 then error("size required (bytes to scan)") end
    max_hits = max_hits or 256

    local buf, n = read_bytes(base, size)
    local hits = {}

    local function add(off, kind)
        table.insert(hits, { addr = base + off, kind = kind })
    end

    for i = 0, n - 1 do
        if #hits >= max_hits then break end
        local b = buf[i]
        -- CALL rel32  E8 xx xx xx xx
        if b == 0xE8 and i + 4 < n then
            local rel = tonumber(ffi.cast("int32_t*", buf + i + 1)[0])
            local dst = base + i + 5 + rel
            if dst == target then add(i, "CALL rel32") end
        -- JMP rel32  E9 xx xx xx xx  (and conditional Jcc rel32 0F 8x)
        elseif b == 0xE9 and i + 4 < n then
            local rel = tonumber(ffi.cast("int32_t*", buf + i + 1)[0])
            if base + i + 5 + rel == target then add(i, "JMP rel32") end
        elseif b == 0x0F and i + 5 < n and buf[i+1] >= 0x80 and buf[i+1] <= 0x8F then
            local rel = tonumber(ffi.cast("int32_t*", buf + i + 2)[0])
            if base + i + 6 + rel == target then add(i, "Jcc rel32") end
        -- PUSH imm32  68 xx xx xx xx
        elseif b == 0x68 and i + 4 < n then
            if tonumber(ffi.cast("uint32_t*", buf + i + 1)[0]) == target then add(i, "PUSH imm32") end
        -- MOV r/m32, imm32  C7 /0
        elseif b == 0xC7 and i + 5 < n then
            if math.floor(buf[i+1] / 8) % 8 == 0 then
                -- modrm reg==0 => MOV
                local imm_off = i + 2
                local mod = math.floor(buf[i+1] / 64)
                if mod == 0 and (buf[i+1] % 8) == 5 then imm_off = i + 6 -- disp32
                elseif mod == 1 then imm_off = i + 3
                elseif mod == 2 then imm_off = i + 6
                end
                if imm_off + 3 < n and tonumber(ffi.cast("uint32_t*", buf + imm_off)[0]) == target then
                    add(i, "MOV r/m32,imm32")
                end
            end
        end
        -- raw pointer (always check, cheap)
        if i + 3 < n and tonumber(ffi.cast("uint32_t*", buf + i)[0]) == target then
            -- avoid double-counting the PUSH/MOV we already handled at same i
            local already = false
            for k = #hits, math.max(1, #hits-2), -1 do if hits[k].addr == base+i then already=true end end
            if not already then add(i, "ABS32") end
            if #hits >= max_hits then break end
        end
    end

    if #hits == 0 then
        print(string.format("No xrefs to 0x%08X in [0x%08X, 0x%08X)", target, base, base+n))
    else
        print(string.format("Xrefs to 0x%08X in [0x%08X, 0x%08X) : %d hits", target, base, base+n, #hits))
        for _, h in ipairs(hits) do
            print(string.format("  0x%08X  %-14s  bytes: %02X %02X %02X %02X %02X",
                h.addr, h.kind, buf[h.addr - base] or 0, buf[h.addr - base + 1] or 0,
                buf[h.addr - base + 2] or 0, buf[h.addr - base + 3] or 0, buf[h.addr - base + 4] or 0))
        end
    end
    return hits
end



-- Find references to an ASCII string (find string then find its pointers)
function M.string_refs(str, base, size, max_hits)
    if type(str) ~= "string" or str == "" then error("str required") end
    local ok, sc = pcall(dofile, "lua/memscan.lua")
    local scan = ok and sc or (type(_G.scan)=="table" and _G.scan or nil)
    if not scan then scan = dofile("lua/memscan.lua") end
    local s_hits = scan.find_string(str, base, size, 32)
    if #s_hits == 0 then
        print("string not found: " .. str)
        return {}
    end
    print(string.format("String '%s' at %d location(s):", str, #s_hits))
    for _, a in ipairs(s_hits) do print(string.format("  0x%08X", a)) end
    local all = {}
    for _, sa in ipairs(s_hits) do
        local xr = M.to(sa, base, size, max_hits)
        for _, h in ipairs(xr) do table.insert(all, h) end
        if #all >= (max_hits or 256) then break end
    end
    return all
end

return M
