-- Europa 1400 - Function Finder (high-level RE workflow)
--
-- Automates the common string/bytes -> xref -> prologue -> register loop
-- so you can discover candidates without leaving the console.
--
--   finder = require("finder")
--   finder.string_func("Gold", 0x00400000, 0x300000)
--   finder.bytes_func("55 8B EC 83 EC ??", 0x00400000, 0x200000)
--   finder.prologues(0x00401000, 0x50000)
--   finder.callers(0x00402000, 0x00400000, 0x200000)
--   finder.register_hits("Gold_func", "int()", hits)

local M = {}


local function to_addr(v)
    if type(v) == "number" then return v end
    if type(v) ~= "string" then return nil end
    local s = v:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^0[xX]", "")
    return tonumber(s, 16)
end

-- Walk backwards from an xref hit to find nearest function prologue
-- (55 8B EC,  53 56 57,  8B 44 24 xx, etc.) within lookback bytes.
local PROLOGUES = {
    "55 8B EC",          -- push ebp; mov ebp,esp
    "55 89 E5",          -- alternate (rare on MSVC)
    "53 56 57",          -- push ebx; push esi; push edi
    "56 57",             -- short
    "53 8B DC",          -- push ebx; mov ebx,esp (delphi-ish)
}

function M.prologues(base, size, max_hits)
    local scan = require("memscan")
    if not scan then error("scan module not loaded") end
    base = base or 0x00401000
    size = size or 0x200000
    max_hits = max_hits or 0 -- 0 = return all via scan.find limit
    local all = {}
    for _, pat in ipairs(PROLOGUES) do
        local hits = scan.scan(pat, base, size, 256)
        for _, h in ipairs(hits) do all[#all+1] = { addr = h, pat = pat } end
    end
    table.sort(all, function(a,b) return a.addr < b.addr end)
    -- dedup close hits (<16 apart -> keep first)
    local uniq = {}
    local last = -1e9
    for _, e in ipairs(all) do
        if e.addr - last >= 16 then uniq[#uniq+1] = e; last = e.addr end
    end
    if max_hits > 0 and #uniq > max_hits then
        while #uniq > max_hits do table.remove(uniq) end
    end
    print(string.format("Prologues in [0x%08X, +0x%X): %d", base, size, #uniq))
    for i = 1, math.min(20, #uniq) do
        print(string.format("  0x%08X  %s", uniq[i].addr, uniq[i].pat))
    end
    if #uniq > 20 then print(string.format("  ... and %d more", #uniq - 20)) end
    return uniq
end

local function nearest_prologue(addr, scan, base, size, lookback)
    lookback = lookback or 512
    local lo = math.max(addr - lookback, base or 0)
    local len = addr - lo
    if len <= 0 then return addr end
    -- scan backwards chunk: reuse scan.scan on [lo, addr)
    local hits = {}
    for _, pat in ipairs(PROLOGUES) do
        local hs = scan.scan(pat, lo, len, 32)
        for _, h in ipairs(hs) do hits[#hits+1] = h end
    end
    if #hits == 0 then return addr end
    table.sort(hits)
    -- nearest at or before addr
    local best = hits[1]
    for _, h in ipairs(hits) do if h <= addr and h > best then best = h end end
    return best
end

function M.string_func(str, base, size, opts)
    opts = opts or {}
    base = base or 0x00400000
    size = size or 0x300000
    local scan = require("memscan")
    local xrefs = require("xrefs")
    if not scan or not xrefs then error("scan/xrefs not loaded") end
    local s_hits = scan.find_string(str, base, size, 32)
    if #s_hits == 0 then print("string not found: " .. str); return {} end
    print(string.format("String '%s' @ %d loc(s)", str, #s_hits))
    for _, a in ipairs(s_hits) do print(string.format("  0x%08X", a)) end
    local funcs = {}
    local seen = {}
    for _, sa in ipairs(s_hits) do
        local xr = xrefs.to(sa, base, size, 64)
        for _, h in ipairs(xr) do
            local f = nearest_prologue(h.addr, scan, base, size, opts.lookback or 512)
            if not seen[f] then seen[f]=true; funcs[#funcs+1]=f end
        end
    end
    table.sort(funcs)
    print(string.format("Candidate funcs via '%s': %d", str, #funcs))
    for _, f in ipairs(funcs) do print(string.format("  0x%08X", f)) end
    if opts.dump then
        for _, f in ipairs(funcs) do scan.dump(f, 64) end
    end
    return funcs
end

function M.bytes_func(pattern, base, size, opts)
    opts = opts or {}
    base = base or 0x00400000
    size = size or 0x200000
    local scan = require("memscan")
    if not scan then error("scan not loaded") end
    local hits = scan.scan(pattern, base, size, 64)
    print(string.format("Pattern '%s' -> %d hit(s)", pattern, #hits))
    for _, h in ipairs(hits) do print(string.format("  0x%08X", h)) end
    if opts.dump then for _, h in ipairs(hits) do scan.dump(h, 48) end end
    return hits
end

function M.callers(target, base, size, max_hits)
    target = to_addr(target) or target
    if type(target) == "string" then
        -- try game registry
        local g = require("gamecalls")
        if g and g.get_address then
            local a = g.get_address(target)
            if a then target = a end
        end
    end
    if type(target) ~= "number" then error("target must be address or registered name") end
    local xrefs = require("xrefs")
    if not xrefs then error("xrefs not loaded") end
    base = base or 0x00400000
    size = size or 0x200000
    return xrefs.to(target, base, size, max_hits or 64)
end

function M.register_hits(prefix, signature, hits, desc_fmt)
    local g = require("gamecalls")
    if not g then error("game not loaded") end
    if type(prefix) ~= "string" or prefix == "" then error("prefix required") end
    signature = signature or "int()"
    hits = hits or {}
    for i, addr in ipairs(hits) do
        local name
        if type(addr) == "table" then addr = addr.addr end
        name = string.format("%s_%d", prefix, i)
        local desc = desc_fmt and string.format(desc_fmt, i, addr) or string.format("auto %s #%d", prefix, i)
        local ok, err = pcall(g.register, name, addr, signature, desc)
        if not ok then print("register failed " .. name .. ": " .. tostring(err))
        else print(string.format("Registered %s @ 0x%08X", name, addr)) end
    end
end

return M
