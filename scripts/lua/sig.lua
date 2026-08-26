-- Europa 1400 - Signature Maker
--
-- Generate stable AOB patterns from live bytes, with optional
-- masking of volatile operands (CALL/JMP rel32, absolute pointers).
-- Use with scan/finder to make version-proof signatures for
-- discovered functions.
--
--   sig = require("sig")
--   sig.at(0x401000, 16)              -- exact pattern at addr
--   sig.masked(0x401000, 24)          -- with CALL/JMP immediates as ??
--   sig.func(0x401000)                -- from func start to RET
--   sig.bytes("55 8B EC 83 EC 10")    -- normalize / validate helper
--   sig.save("my_sigs.lua", { {name="PlayerUpdate", pat=sig.masked(0x401000, 20)} })

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

local function bytes_to_pat(bytes, mask)
    -- mask[i] == true -> wildcard
    local parts = {}
    for i, b in ipairs(bytes) do
        if mask and mask[i] then parts[#parts+1] = "??"
        else parts[#parts+1] = string.format("%02X", b) end
    end
    return table.concat(parts, " ")
end

local function validate_pat(pat)
    if type(pat) ~= "string" or pat:match("^%s*$") then error("pattern must be non-empty string") end
    for tok in pat:gmatch("%S+") do
        if tok ~= "?" and tok ~= "??" then
            local b = tonumber(tok, 16)
            if not b or b < 0 or b > 0xFF then error("invalid pattern token: " .. tok) end
        end
    end
    return pat
end

local M = {}

-- Normalize a pattern string (upper-case, single spaces)
function M.normalize(pat)
    validate_pat(pat)
    local out = {}
    for tok in pat:gmatch("%S+") do
        if tok == "?" then out[#out+1] = "??"
        elseif tok:match("^[0-9a-fA-F][0-9a-fA-F]$") then out[#out+1] = tok:upper()
        else out[#out+1] = tok:upper() end
    end
    return table.concat(out, " ")
end
M.bytes = M.normalize

-- Exact pattern of len bytes at addr
function M.at(addr, len)
    addr = to_addr(addr); len = len or 16
    if len <= 0 or len > 256 then error("len out of range 1..256") end
    local bytes = read_bytes(addr, len)
    if not bytes then error(string.format("Read failed at 0x%08X", addr)) end
    local pat = bytes_to_pat(bytes)
    print(string.format("0x%08X  %s", addr, pat))
    return pat
end

-- Like at(), but wildcards CALL rel32 (E8), JMP rel32 (E9), Jcc rel32 (0F 8x)
-- and optionally absolute ptrs that look like code addresses (>0x00400000).
function M.masked(addr, len, opts)
    addr = to_addr(addr); len = len or 24
    opts = opts or {}
    if len <= 0 or len > 256 then error("len out of range") end
    local bytes = read_bytes(addr, len)
    if not bytes then error(string.format("Read failed at 0x%08X", addr)) end
    local mask = {}
    local i = 1
    while i <= #bytes do
        local b = bytes[i]
        if b == 0xE8 or b == 0xE9 then
            -- next 4 bytes are rel32 -> wildcard
            for k = i+1, math.min(i+4, #bytes) do mask[k] = true end
            i = i + 5
        elseif b == 0x0F and bytes[i+1] and bytes[i+1] >= 0x80 and bytes[i+1] <= 0x8F then
            for k = i+2, math.min(i+5, #bytes) do mask[k] = true end
            i = i + 6
        elseif b == 0x68 and not opts.keep_push_imm then
            -- PUSH imm32, often an address; wildcard if it looks like a pointer
            if i+4 <= #bytes then
                local imm = bytes[i+1] + bytes[i+2]*256 + bytes[i+3]*65536 + bytes[i+4]*16777216
                if imm >= 0x00400000 and imm < 0x80000000 then
                    for k = i+1, i+4 do mask[k] = true end
                end
            end
            i = i + 1
        else
            i = i + 1
        end
    end
    local pat = bytes_to_pat(bytes, mask)
    print(string.format("0x%08X  %s", addr, pat))
    return pat
end

-- Pattern for the function starting at addr, until RET or max_len
function M.func(addr, max_len)
    addr = to_addr(addr); max_len = max_len or 64
    if max_len <= 0 or max_len > 256 then error("max_len out of range") end
    local bytes = read_bytes(addr, max_len)
    if not bytes then error(string.format("Read failed at 0x%08X", addr)) end
    -- find first C3/C2 within max_len
    local cut = #bytes
    for i, b in ipairs(bytes) do
        if b == 0xC3 or b == 0xC2 or b == 0xCB then cut = i; break end
    end
    -- trim to cut
    local trimmed = {}
    for i = 1, cut do trimmed[i] = bytes[i] end
    -- apply same masking as masked()
    local mask = {}
    local i = 1
    while i <= #trimmed do
        local b = trimmed[i]
        if b == 0xE8 or b == 0xE9 then
            for k = i+1, math.min(i+4, #trimmed) do mask[k]=true end
            i = i + 5
        elseif b == 0x0F and trimmed[i+1] and trimmed[i+1] >= 0x80 and trimmed[i+1] <= 0x8F then
            for k = i+2, math.min(i+5, #trimmed) do mask[k]=true end
            i = i + 6
        else i = i + 1 end
    end
    local pat = bytes_to_pat(trimmed, mask)
    print(string.format("func 0x%08X (%d bytes)  %s", addr, cut, pat))
    return pat
end

-- Verify a pattern matches at addr (useful before saving)
function M.verify(pat, addr)
    pat = M.normalize(pat); addr = to_addr(addr)
    local parts = {}
    for tok in pat:gmatch("%S+") do parts[#parts+1] = tok end
    local bytes = read_bytes(addr, #parts)
    if not bytes then error(string.format("Read failed at 0x%08X", addr)) end
    for i, tok in ipairs(parts) do
        if tok ~= "??" then
            local need = tonumber(tok, 16)
            if bytes[i] ~= need then
                print(string.format("mismatch at +%d: need %s got %02X", i-1, tok, bytes[i]))
                return false
            end
        end
    end
    print(string.format("verify OK: '%s' matches at 0x%08X", pat, addr))
    return true
end

-- Save named patterns to a lua file: { {name, pat}, ... }
function M.save(path, entries)
    if type(path) ~= "string" or path == "" then error("path required") end
    if type(entries) ~= "table" then error("entries must be array of {name, pat}") end
    local f, err = io.open(path, "w")
    if not f then error("cannot open " .. path .. ": " .. tostring(err)) end
    f:write("-- signatures " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
    f:write("return {\n")
    for _, e in ipairs(entries) do
        local name = e.name or e[1]; local pat = e.pat or e[2]
        if type(name) ~= "string" or type(pat) ~= "string" then error("each entry needs {name, pat}") end
        validate_pat(pat)
        f:write(string.format("  {name=%q, pat=%q},\n", name, M.normalize(pat)))
    end
    f:write("}\n")
    f:close()
    print(string.format("sig: saved %d pattern(s) to %s", #entries, path))
end

return M
