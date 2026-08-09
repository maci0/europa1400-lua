-- Europa 1400 - Safe Call Probe
--
-- Try calling a discovered address with several signatures / arg sets
-- without crashing the console. Useful to infer calling convention and
-- arity for a newly found candidate before committing a game.register.
--
--   probe = dofile('lua/probe.lua')   -- or already `probe`
--   probe.at(0x401000, {"int()", "void(int)", "int(int,int)"} )
--   probe.at(0x401000, {"int()"}, {{}})                 -- explicit arg sets
--   probe.at(0x401000, {"int(int)"}, {{0},{1},{-1}, {0x1234}})
--   probe.register("GetGold", 0x401000)                  -- try common sigs

local ffi = require("ffi")

local COMMON_SIGS = {
    "int()", "void()", "int(int)", "void(int)",
    "int(int,int)", "void(int,int)",
    "int(void*)", "void*(int)",
    "int(char*)", "void(char*)",
    "int __stdcall()", "void __stdcall()",
    "int __stdcall(int)", "void __stdcall(int)",
}

local function try_one(addr, sig, args)
    args = args or {}
    local ok, fn = pcall(function() return ffi.cast(sig .. "*", addr) end)
    if not ok then return { sig=sig, args=args, ok=false, err="bad sig: " .. tostring(fn) } end
    local t0 = os.clock()
    local ok2, res = pcall(function() return fn(unpack(args)) end)
    local ms = (os.clock() - t0) * 1000
    return { sig=sig, args=args, ok=ok2, result=res, ms=ms }
end

local M = {}

function M.at(addr, sigs, arg_sets)
    if type(addr) == "string" then
        local s = addr:gsub("^0[xX]", "")
        addr = tonumber(s, 16)
        if not addr then error("invalid addr: " .. tostring(addr)) end
    end
    if type(addr) ~= "number" then error("addr must be number or hex string") end
    sigs = sigs or COMMON_SIGS
    if type(sigs) == "string" then sigs = { sigs } end
    if type(sigs) ~= "table" then error("sigs must be string or array") end

    -- default arg sets if not provided: try empty and common ints
    if not arg_sets then
        arg_sets = { {}, {0}, {1}, {0,0} }
    end

    local results = {}
    print(string.format("probe 0x%08X — %d sig(s) x %d arg set(s)", addr, #sigs, #arg_sets))
    print(string.rep("-", 60))
    for _, sig in ipairs(sigs) do
        for _, args in ipairs(arg_sets) do
            local r = try_one(addr, sig, args)
            results[#results+1] = r
            local a = #args == 0 and "()" or "(" .. table.concat((function()
                local t={}; for _,v in ipairs(args) do t[#t+1]=tostring(v) end; return t
            end)(), ", ") .. ")"
            if r.ok then
                print(string.format("  OK   %-24s %-16s -> %s  %.2fms", sig, a, tostring(r.result), r.ms))
            else
                -- only print first line of error
                local e = tostring(r.result or r.err):gsub("\n.*","")
                if #e > 80 then e = e:sub(1,80) .. "…" end
                print(string.format("  FAIL %-24s %-16s    %s", sig, a, e))
            end
        end
    end
    return results
end

function M.register(name, addr, sigs)
    if type(name) ~= "string" or name == "" then error("name required") end
    local results = M.at(addr, sigs or COMMON_SIGS, { {} })
    -- pick first OK sig
    for _, r in ipairs(results) do
        if r.ok then
            local game = _G.game or (pcall(dofile, "lua/gamecalls.lua") and _G.game)
            if not game then error("game not available") end
            game.register(name, addr, r.sig, "probed " .. r.sig)
            print(string.format("probe.register: picked '%s' for %s", r.sig, name))
            return r.sig
        end
    end
    print("probe.register: no sig succeeded; not registered")
    return nil
end

function M.batch(addrs, sigs)
    if type(addrs) ~= "table" then error("addrs must be array of addresses") end
    local out = {}
    for _, addr in ipairs(addrs) do
        local a = type(addr)=="table" and (addr.addr or addr[1]) or addr
        print(string.format("\n-- probe 0x%08X --", tonumber(a) or 0))
        local res = M.at(a, sigs)
        -- best OK sig per addr
        local best = nil
        for _, r in ipairs(res or {}) do if r.ok then best = r.sig; break end end
        out[#out+1] = { addr=a, bestSig=best, results=res }
    end
    return out
end

function M.bestSig(addr, sigs)
    local res = M.at(addr, sigs, { {} })
    for _, r in ipairs(res or {}) do if r.ok then return r.sig end end
    return nil
end

return M
