-- Europa 1400 - String Dumper
--
-- Enumerate printable strings in a memory region. Classic RE primitive
-- for discovering UI texts, debug logs and function-adjacent strings
-- without leaving the console.
--
--   strs = require("strings")
--   strs.dump(0x00400000, 0x300000, 5)        -- ASCII, min len 5
--   strs.dump(0x00400000, 0x300000, 5, 200)   -- cap 200 hits
--   hits = strs.scan(0x00400000, 0x300000, 4)
--   hits = strs.find("Gold", 0x00400000, 0x300000)
--   hits = strs.wide(0x00400000, 0x300000, 4)  -- UTF-16LE

local ffi = require("ffi")

ffi.cdef[[
    void* GetModuleHandleA(const char* lpModuleName);
    void* GetCurrentProcess(void);
    int   VirtualQueryEx(void* hProcess, const void* lpAddress, void* lpBuffer, unsigned long dwLength);
    int   ReadProcessMemory(void* hProcess, const void* lpBaseAddress, void* lpBuffer,
                            unsigned long nSize, unsigned long* lpNumberOfBytesRead);
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

local MEM_COMMIT    = 0x1000
local PAGE_GUARD    = 0x100
local PAGE_NOACCESS = 0x01

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

local function is_readable(protect, state)
    if state ~= MEM_COMMIT then return false end
    if bit and bit.band(protect, PAGE_GUARD) ~= 0 then return false end
    if protect == PAGE_NOACCESS then return false end
    return protect ~= 0
end

local function regions(base, max_size)
    local hProc = kernel32.GetCurrentProcess()
    local mbi = ffi.new("MEMORY_BASIC_INFORMATION")
    local out, addr = {}, base
    local limit = base + max_size
    while addr < limit do
        if kernel32.VirtualQueryEx(hProc, ffi.cast("void*", addr), mbi, ffi.sizeof(mbi)) == 0 then break end
        if is_readable(mbi.Protect, mbi.State) then
            table.insert(out, {
                base = tonumber(ffi.cast("uintptr_t", mbi.BaseAddress)),
                size = tonumber(mbi.RegionSize),
            })
        end
        addr = tonumber(ffi.cast("uintptr_t", mbi.BaseAddress)) + tonumber(mbi.RegionSize)
        if addr == 0 then break end
    end
    return out
end

local function collect_ascii(base, size, min_len, max_count, filter)
    min_len   = min_len   or 4
    max_count = max_count or 500
    if min_len < 2 then min_len = 2 end
    if max_count < 1 then max_count = 500 end
    local regs
    if base then
        regs = regions(base, size or 0x300000)
        if #regs == 0 then regs = { { base = base, size = size or 0x300000 } } end
    else
        regs = regions(0x00400000, 0x3000000)
    end
    local chunk = 65536
    local hits = {}
    local needle = filter and filter:lower() or nil
    for _, r in ipairs(regs) do
        local pending_addr, pending = nil, {}
        local off = 0
        while off < r.size do
            local want = math.min(chunk, r.size - off)
            local cur  = r.base + off
            local buf  = ffi.new("uint8_t[?]", want)
            local got  = ffi.new("unsigned long[1]")
            if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", cur), buf, want, got) ~= 0 then
                local n = tonumber(got[0])
                for i = 0, n - 1 do
                    local b = buf[i]
                    local printable = b >= 32 and b < 127
                    if printable then
                        if not pending_addr then pending_addr = cur + i end
                        pending[#pending + 1] = string.char(b)
                    else
                        if pending_addr then
                            if #pending >= min_len then
                                local s = table.concat(pending)
                                if not needle or s:lower():find(needle, 1, true) then
                                    hits[#hits + 1] = { addr = pending_addr, text = s }
                                    if #hits >= max_count then return hits end
                                end
                            end
                            pending_addr, pending = nil, {}
                        end
                    end
                end
                -- carry pending across chunk boundary (don't flush yet)
                if n < want then
                    if pending_addr and #pending >= min_len then
                        local s = table.concat(pending)
                        if not needle or s:lower():find(needle, 1, true) then
                            hits[#hits + 1] = { addr = pending_addr, text = s }
                        end
                    end
                    pending_addr, pending = nil, {}
                end
            end
            off = off + want
            if #hits >= max_count then break end
        end
        -- flush trailing pending string at region end
        if pending_addr and #pending >= min_len then
            local s = table.concat(pending)
            if not needle or s:lower():find(needle, 1, true) then
                hits[#hits + 1] = { addr = pending_addr, text = s }
            end
        end
        if #hits >= max_count then break end
    end
    return hits
end

local function collect_wide(base, size, min_len, max_count, filter)
    min_len   = min_len   or 4
    max_count = max_count or 500
    local regs
    if base then
        regs = regions(base, size or 0x300000)
        if #regs == 0 then regs = { { base = base, size = size or 0x300000 } } end
    else
        regs = regions(0x00400000, 0x3000000)
    end
    local chunk = 65536
    local hits = {}
    local needle = filter and filter:lower() or nil
    for _, r in ipairs(regs) do
        local pending_addr, pending = nil, {}
        local off = 0
        while off + 1 < r.size do
            local want = math.min(chunk, r.size - off)
            want = want - (want % 2)
            if want < 2 then break end
            local cur = r.base + off
            local buf = ffi.new("uint8_t[?]", want)
            local got = ffi.new("unsigned long[1]")
            if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", cur), buf, want, got) ~= 0 then
                local n = tonumber(got[0])
                n = n - (n % 2)
                for i = 0, n - 2, 2 do
                    local lo, hi = buf[i], buf[i+1]
                    local is_wide_char = hi == 0 and lo >= 32 and lo < 127
                    if is_wide_char then
                        if not pending_addr then pending_addr = cur + i end
                        pending[#pending + 1] = string.char(lo)
                    else
                        if pending_addr then
                            if #pending >= min_len then
                                local s = table.concat(pending)
                                if not needle or s:lower():find(needle, 1, true) then
                                    hits[#hits + 1] = { addr = pending_addr, text = s }
                                    if #hits >= max_count then return hits end
                                end
                            end
                            pending_addr, pending = nil, {}
                        end
                        if lo == 0 and hi == 0 then
                            -- skip double NUL, already flushed
                        end
                    end
                end
            end
            off = off + want
            if #hits >= max_count then break end
        end
        if pending_addr and #pending >= min_len then
            local s = table.concat(pending)
            if not needle or s:lower():find(needle, 1, true) then
                hits[#hits + 1] = { addr = pending_addr, text = s }
            end
        end
        if #hits >= max_count then break end
    end
    return hits
end

local M = {}

function M.scan(base, size, min_len, max_count)
    if base ~= nil then base = to_addr(base) end
    local hits = collect_ascii(base, size, min_len, max_count, nil)
    return hits
end

function M.dump(base, size, min_len, max_count)
    if base ~= nil and type(base) == "string" and not base:find("%+") and not base:match("^0[xX]") and not tonumber(base) then
        -- called as dump("Gold", base, size) overload is handled via find
    end
    if base ~= nil and type(base) ~= "number" then
        -- allow to_addr for first arg
        local ok, v = pcall(to_addr, base)
        if ok then base = v end
    else
        if base ~= nil then base = to_addr(base) end
    end
    local hits = collect_ascii(base, size, min_len, max_count, nil)
    print(string.format("strings: %d hit(s)  [base 0x%08X size 0x%X min_len %d]",
        #hits, base or 0x00400000, size or 0x300000, min_len or 4))
    for i = 1, math.min(#hits, max_count or 200) do
        local h = hits[i]
        print(string.format("  0x%08X  %q", h.addr, h.text))
    end
    if #hits > (max_count or 200) then print(string.format("  ... and %d more", #hits - (max_count or 200))) end
    return hits
end

function M.find(needle, base, size, min_len, max_count)
    if type(needle) ~= "string" or needle == "" then error("needle must be non-empty string") end
    if base ~= nil then base = to_addr(base) end
    local hits = collect_ascii(base, size, min_len or 4, max_count or 500, needle)
    print(string.format("strings.find %q: %d hit(s)", needle, #hits))
    for i = 1, math.min(#hits, 200) do
        local h = hits[i]
        print(string.format("  0x%08X  %q", h.addr, h.text))
    end
    if #hits > 200 then print(string.format("  ... and %d more", #hits - 200)) end
    return hits
end

function M.wide(base, size, min_len, max_count)
    if base ~= nil then base = to_addr(base) end
    local hits = collect_wide(base, size, min_len, max_count, nil)
    print(string.format("wide strings: %d hit(s)", #hits))
    for i = 1, math.min(#hits, 200) do
        print(string.format("  0x%08X  %q", hits[i].addr, hits[i].text))
    end
    return hits
end

function M.wide_find(needle, base, size, min_len, max_count)
    if type(needle) ~= "string" or needle == "" then error("needle required") end
    if base ~= nil then base = to_addr(base) end
    local hits = collect_wide(base, size, min_len or 4, max_count or 500, needle)
    print(string.format("wide.find %q: %d hit(s)", needle, #hits))
    for i = 1, math.min(#hits, 200) do
        print(string.format("  0x%08X  %q", hits[i].addr, hits[i].text))
    end
    return hits
end

return M
