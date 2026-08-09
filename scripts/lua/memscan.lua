-- Europa 1400 - Memory Scanner for Reverse Engineering
--
-- Byte-pattern (AOB) scanning, hex dumping, region enumeration and
-- string searching built on ReadProcessMemory / VirtualQueryEx.
-- Designed to locate functions and data without hard-coded addresses
-- (ASLR / version differences).
--
-- Usage:
--   scan.find("8B 45 08 ?? 83", 0x00400000, 0x200000)
--   scan.dump(0x00401000, 64)
--   scan.regions()
--   scan.find_string("Gold", 0x00400000, 0x300000)

local ffi = require("ffi")

ffi.cdef[[
    void* GetCurrentProcess();
    int VirtualQueryEx(void* hProcess, const void* lpAddress,
                       void* lpBuffer, unsigned long dwLength);
    int ReadProcessMemory(void* hProcess, const void* lpBaseAddress,
                          void* lpBuffer, unsigned long nSize,
                          unsigned long* lpNumberOfBytesRead);

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
local has_bit, bit = pcall(require, "bit")
if not has_bit then bit = _G.bit end

local MEM_COMMIT  = 0x1000
local PAGE_GUARD  = 0x100
local PAGE_NOACCESS = 0x01

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------

local function to_addr(v)
    if type(v) == "string" then
        local s = v:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^0[xX]", "")
        local n = tonumber(s, 16)
        if not n then error("invalid address: " .. v) end
        return n
    elseif type(v) == "number" then
        return v
    else
        error("address must be number or hex string")
    end
end

-- "8B 45 ?? 90" -> {0x8B,0x45,nil,0x90}
local function parse_pattern(pat)
    if type(pat) ~= "string" or pat:match("^%s*$") then
        error("pattern must be a non-empty string like '8B 45 ?? 90'")
    end
    local bytes = {}
    for tok in pat:gmatch("%S+") do
        if tok == "?" or tok == "??" then
            table.insert(bytes, nil)
        else
            local b = tonumber(tok, 16)
            if not b or b < 0 or b > 0xFF then
                error("invalid pattern token: " .. tok)
            end
            table.insert(bytes, b)
        end
    end
    if #bytes == 0 then error("empty pattern") end
    return bytes
end

local function is_readable(protect, state)
    if state ~= MEM_COMMIT then return false end
    if bit and bit.band(protect, PAGE_GUARD) ~= 0 then return false end
    if protect == PAGE_NOACCESS then return false end
    -- PAGE_READONLY 0x02, READWRITE 0x04, WRITECOPY 0x08, EXECUTE_READ 0x20,
    -- EXECUTE_READWRITE 0x40, EXECUTE_WRITECOPY 0x80
    local readable = { [0x02]=true,[0x04]=true,[0x08]=true,[0x10]=true,
                       [0x20]=true,[0x40]=true,[0x80]=true }
    -- fallback: any commit that is not NOACCESS/GUARD is usually readable
    if readable[protect] then return true end
    -- protect may include PAGE_GUARD etc composite; mask it out
    return protect ~= 0
end

-- ---------------------------------------------------------------------------
-- public
-- ---------------------------------------------------------------------------

local M = {}

-- Enumerate committed readable regions in [base, base+max_size)
function M.regions(base, max_size)
    base = base and to_addr(base) or 0
    local hProc = kernel32.GetCurrentProcess()
    local mbi = ffi.new("MEMORY_BASIC_INFORMATION")
    local out = {}
    local addr = base
    local limit = max_size and (base + max_size) or 0x7FFF0000
    while addr < limit do
        local ret = kernel32.VirtualQueryEx(hProc, ffi.cast("void*", addr), mbi, ffi.sizeof(mbi))
        if ret == 0 then break end
        if is_readable(mbi.Protect, mbi.State) then
            table.insert(out, {
                base = tonumber(ffi.cast("uintptr_t", mbi.BaseAddress)),
                size = tonumber(mbi.RegionSize),
                protect = tonumber(mbi.Protect),
                state = tonumber(mbi.State),
                type = tonumber(mbi.Type),
            })
        end
        addr = tonumber(ffi.cast("uintptr_t", mbi.BaseAddress)) + tonumber(mbi.RegionSize)
        if addr == 0 then break end
    end
    return out
end

-- Hex dump: prints and returns string
function M.dump(address, length, cols)
    local addr = to_addr(address)
    length = length or 64
    cols = cols or 16
    if length <= 0 or length > 0x100000 then error("dump length out of range") end
    local hProc = kernel32.GetCurrentProcess()
    local buf = ffi.new("uint8_t[?]", length)
    local read = ffi.new("unsigned long[1]")
    if kernel32.ReadProcessMemory(hProc, ffi.cast("void*", addr), buf, length, read) == 0 then
        error(string.format("ReadProcessMemory failed at 0x%08X", addr))
    end
    local n = tonumber(read[0])
    local lines = {}
    for off = 0, n - 1, cols do
        local hex, asc = {}, {}
        for c = 0, cols - 1 do
            if off + c < n then
                local b = buf[off + c]
                table.insert(hex, string.format("%02X", b))
                table.insert(asc, (b >= 32 and b < 127) and string.char(b) or ".")
            else
                table.insert(hex, "  ")
                table.insert(asc, " ")
            end
        end
        table.insert(lines, string.format("%08X  %s  |%s|", addr + off,
            table.concat(hex, " "), table.concat(asc)))
    end
    local s = table.concat(lines, "\n")
    print(s)
    return s
end

-- AOB scan. Returns array of hit addresses.
-- pattern: "8B 45 ?? 83 C4 04"   base/size: region to scan
function M.scan(pattern, base, size, max_hits)
    local pat = parse_pattern(pattern)
    local plen = #pat
    max_hits = max_hits or 256
    local hProc = kernel32.GetCurrentProcess()

    -- collect regions to scan
    local regs
    if base then
        local b = to_addr(base)
        if size then
            regs = { { base = b, size = size } }
        else
            regs = M.regions(b, 0x2000000)
            if #regs == 0 then regs = { { base = b, size = 0x100000 } } end
        end
    else
        regs = M.regions(0x00400000, 0x3000000)
        if #regs == 0 then
            regs = { { base = 0x00400000, size = 0x200000 } }
        end
    end

    local hits = {}
    local chunk_size = 65536
    for _, r in ipairs(regs) do
        local rbase = r.base
        local rsize = r.size
        if rsize >= plen then
            local buf = ffi.new("uint8_t[?]", chunk_size + plen)
            local read = ffi.new("unsigned long[1]")
            local offset = 0
            while offset < rsize do
                local to_read = math.min(chunk_size, rsize - offset)
                local cur = rbase + offset
                if kernel32.ReadProcessMemory(hProc, ffi.cast("void*", cur), buf, to_read, read) == 0 then
                    offset = offset + to_read
                else
                    local avail = tonumber(read[0])
                    -- scan avail bytes (need plen-1 lookahead already in buf if we overlap)
                    local limit = avail - plen
                    for i = 0, limit do
                        local ok = true
                        for j = 1, plen do
                            local need = pat[j]
                            if need ~= nil and buf[i + j - 1] ~= need then ok = false; break end
                        end
                        if ok then
                            table.insert(hits, cur + i)
                            if #hits >= max_hits then return hits end
                        end
                    end
                    if avail < to_read then break end
                    offset = offset + avail
                    -- overlap plen-1 so patterns crossing chunk boundary are found:
                    if offset < rsize then offset = offset - (plen - 1) end
                end
            end
        end
        if #hits >= max_hits then break end
    end
    return hits
end

-- alias
M.find = M.scan

-- Find occurrences of an ASCII/UTF-8 string (case-sensitive)
function M.find_string(str, base, size, max_hits)
    if type(str) ~= "string" or str == "" then error("str must be non-empty") end
    local pat = {}
    for i = 1, #str do pat[i] = string.format("%02X", str:byte(i)) end
    return M.scan(table.concat(pat, " "), base, size, max_hits)
end

return M
