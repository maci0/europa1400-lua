-- Europa 1400 - Auto Discover
--
-- One-shot helper that chains the toolkit:
--   string/preset -> func candidates (finder) -> disasm -> sig -> probe
--
-- Lets you go from a keyword to a tested game.register in one call.
--
--   auto = require("auto")  -- or already `auto`
--   auto.discover("gold")                              -- preset-aware
--   auto.discover("Gold", 0x00400000, 0x300000, {probe=true, register=true, sig="int()"})
--   auto.quick(0x401000, {"int()", "void(int)"})       -- just probe+register
--   auto.from_string("MyGold", "Gold", 0x00400000, 0x300000)

local M = {}

local game = require("gamecalls")

function M.discover(keyword, base, size, opts)
    opts = opts or {}
    base = base or 0x00400000
    size = size or 0x300000
    local finder = require("finder")
    local disasm = require("disasm")
    local sig    = require("sig")
    local probe  = require("probe")
    local presets= require("presets")

    -- Prefer presets.hunt if keyword matches a preset key, otherwise finder.string_func
    local candidates = {}
    if presets and presets.tags_for and presets.tags_for(keyword) then
        candidates = presets.hunt(keyword, base, size, { dump = false }) or {}
    elseif finder and finder.string_func then
        candidates = finder.string_func(keyword, base, size, { dump = false }) or {}
    else
        error("finder/presets not available")
    end

    if #candidates == 0 then
        print(string.format("auto.discover(%q): no candidates", tostring(keyword)))
        return {}
    end

    print(string.format("auto.discover(%q): %d candidate(s)", tostring(keyword), #candidates))
    local results = {}
    for i, addr in ipairs(candidates) do
        local a = type(addr) == "table" and (addr.addr or addr) or addr
        print(string.format("\n[%d] 0x%08X", i, a))
        if disasm and disasm.func then pcall(disasm.func, a) end
        local pat = nil
        if sig and sig.masked then
            local ok, p = pcall(sig.masked, a, 24)
            if ok then pat = p end
        end
        local probed = nil
        if opts.probe ~= false and probe and probe.at then
            local sigs = opts.sig and { opts.sig } or nil
            local ok, res = pcall(probe.at, a, sigs)
            if ok then probed = res end
        end
        if type(opts.register) == "string" then
            local name = string.format("%s_auto_%d", tostring(keyword), i)
            pcall(game.register, name, a, opts.register, "auto " .. tostring(keyword))
        end
        results[#results+1] = { addr = a, sig_pat = pat, probe = probed }
        if opts.limit and i >= opts.limit then break end
    end
    return results
end

function M.quick(addr, sigs, name)
    local probe = require("probe")
    if not probe then error("probe not available") end
    local res = probe.at(addr, sigs)
    if name then
        local ok = false
        for _, r in ipairs(res or {}) do
            if r.ok then
                    pcall(game.register, name, addr, r.sig, "auto quick")
                ok = true; break
            end
        end
        if not ok then print("auto.quick: no sig succeeded; not registered") end
    end
    return res
end

function M.from_string(name, needle, base, size, sig)
    if type(name) ~= "string" or name == "" then error("name required") end
    needle = needle or name
    local res = M.discover(needle, base, size, { probe = true, limit = 1 })
    if #res == 0 then print("auto.from_string: no candidate"); return nil end
    local addr = res[1].addr
    sig = sig or "int()"
    -- Prefer probed sig if available
    if res[1].probe then
        for _, r in ipairs(res[1].probe) do
            if r.ok then sig = r.sig; break end
        end
    end
    game.register(name, addr, sig, "auto from_string " .. tostring(needle))
    return addr, sig
end

return M
