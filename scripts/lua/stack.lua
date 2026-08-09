-- Europa 1400 - Stack Viewer
--
-- Inspect the current thread's call stack and raw stack memory.
-- Complements patch/trace when you need to see *who* called a
-- hooked function and with what stack args.
--
--   stack = dofile('lua/stack.lua')  -- or already `stack`
--   stack.capture(0, 16)              -- RtlCaptureStackBackTrace
--   stack.dump(0, 64)                 -- alias: hex around current stack region
--   stack.ebp_chain(0x0012FF00, 16)   -- walk EBP chain from addr
--   stack.args(ebp, 4)                -- dump 4 args at [ebp+8]

local ffi = require("ffi")

ffi.cdef[[
    void* GetModuleHandleA(const char* lpModuleName);
    void* GetCurrentProcess(void);
    unsigned short RtlCaptureStackBackTrace(unsigned long FramesToSkip, unsigned long FramesToCapture,
                                            void** BackTrace, unsigned long* BackTraceHash);
    int   ReadProcessMemory(void* hProcess, const void* lpBaseAddress,
                            void* lpBuffer, unsigned long nSize,
                            unsigned long* lpNumberOfBytesRead);
]]

local kernel32 = ffi.load("kernel32")
-- RtlCaptureStackBackTrace lives in kernel32 on modern Windows; fallback to ntdll
local has_rtl = pcall(function() return kernel32.RtlCaptureStackBackTrace end)
local ntdll = nil
if not has_rtl then
    local ok, lib = pcall(ffi.load, "ntdll")
    if ok then ntdll = lib end
end

local function capture_fn()
    if has_rtl then return kernel32.RtlCaptureStackBackTrace end
    if ntdll then return ntdll.RtlCaptureStackBackTrace end
    return nil
end

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

local M = {}

function M.capture(skip, count)
    skip = skip or 0
    count = count or 16
    if count <= 0 or count > 64 then error("count 1..64") end
    local fn = capture_fn()
    if not fn then print("stack.capture: RtlCaptureStackBackTrace not available"); return {} end
    local buf = ffi.new("void*[?]", count)
    local n = fn(skip, count, buf, nil)
    n = tonumber(n) or 0
    print(string.format("stack.capture: %d frame(s) (skip %d)", n, skip))
    for i = 0, n-1 do
        print(string.format("  [%2d] 0x%08X", i, tonumber(ffi.cast("uintptr_t", buf[i]))))
    end
    local out = {}
    for i = 0, n-1 do out[i+1] = tonumber(ffi.cast("uintptr_t", buf[i])) end
    return out
end

-- Walk EBP chain: each frame is [ebp] = prev ebp, [ebp+4] = ret addr
function M.ebp_chain(ebp, max_frames)
    ebp = to_addr(ebp)
    max_frames = max_frames or 16
    print(string.format("EBP chain from 0x%08X (max %d):", ebp, max_frames))
    local out = {}
    for i = 1, max_frames do
        local prev = ffi.new("uint32_t[1]")
        local ret  = ffi.new("uint32_t[1]")
        local got1 = ffi.new("unsigned long[1]")
        local got2 = ffi.new("unsigned long[1]")
        local hProc = kernel32.GetCurrentProcess()
        if kernel32.ReadProcessMemory(hProc, ffi.cast("void*", ebp), prev, 4, got1) == 0 then break end
        if kernel32.ReadProcessMemory(hProc, ffi.cast("void*", ebp + 4), ret, 4, got2) == 0 then break end
        local p = tonumber(prev[0]); local r = tonumber(ret[0])
        print(string.format("  [%2d] ebp 0x%08X  ret 0x%08X  next ebp 0x%08X", i-1, ebp, r, p))
        out[#out+1] = { ebp = ebp, ret = r, next_ebp = p }
        if p == 0 or p == ebp or p < 0x10000 then break end
        ebp = p
    end
    return out
end

function M.args(ebp, n)
    ebp = to_addr(ebp); n = n or 4
    if n <= 0 or n > 16 then error("n 1..16") end
    print(string.format("args at ebp 0x%08X:", ebp))
    for i = 0, n-1 do
        local v = ffi.new("uint32_t[1]")
        local got = ffi.new("unsigned long[1]")
        local addr = ebp + 8 + i*4
        if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", addr), v, 4, got) ~= 0 then
            print(string.format("  [ebp+%d] 0x%08X (0x%08X)  %d", 8+i*4, addr, tonumber(v[0]), tonumber(ffi.cast("int32_t*", v)[0])))
        end
    end
end

-- Dump raw stack memory around current thread's stack (best-effort via incoming addr)
function M.dump(addr, len)
    if addr == 0 or addr == nil then
        -- No reliable FS:TEB read from Lua; require explicit addr
        print("stack.dump: pass an address, e.g. stack.dump(0x0012FF00, 64) or stack.ebp_chain(addr)")
        return nil
    end
    addr = to_addr(addr); len = len or 64
    local buf = ffi.new("uint8_t[?]", len)
    local got = ffi.new("unsigned long[1]")
    if kernel32.ReadProcessMemory(kernel32.GetCurrentProcess(), ffi.cast("void*", addr), buf, len, got) == 0 then
        print(string.format("stack.dump: read failed at 0x%08X", addr)); return nil
    end
    local n = tonumber(got[0])
    local cols = 16
    local lines = {}
    for off = 0, n-1, cols do
        local hex, asc = {}, {}
        for c = 0, cols-1 do
            if off+c < n then
                local b = buf[off+c]
                hex[#hex+1]=string.format("%02X", b)
                asc[#asc+1]=(b>=32 and b<127) and string.char(b) or "."
            else hex[#hex+1]="  "; asc[#asc+1]=" " end
        end
        lines[#lines+1]=string.format("%08X  %s  |%s|", addr+off, table.concat(hex," "), table.concat(asc))
    end
    local s = table.concat(lines, "\n")
    print(s)
    return s
end

return M
