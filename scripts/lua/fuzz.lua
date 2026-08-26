-- Europa 1400 - Fuzz Helper
--
-- Brute-force argument ranges for a probed function. Useful to learn
-- valid values / counts without reading the disassembly first.
--
--   fuzz = require("fuzz")  -- or already `fuzz`
--   fuzz.int("GetGold", 0, 10)                  -- try int 0..10
--   fuzz.ints("DoThing", { {0,5}, {0,5} })      -- 2 args, 0..5 each
--   fuzz.strings("ShowMessage", {"","hi","Gold"})
--   fuzz.raw(0x401000, "int(int)", {{0},{1},{-1},{9999}})

local M = {}

local game = require("gamecalls")


function M.raw(addr, sig_or_name, arg_sets)
    -- Overload: fuzz.raw(0x401000, "int(int)", {{0},{1}})
    --       or: fuzz.raw("GetGold", nil, {{},{0}}) -- name lookup via game
    local is_addr = type(addr) == "number" or (type(addr)=="string" and addr:match("^0[xX]"))
    local game = game
    if not is_addr and type(addr)=="string" then
        -- treat addr as game name
        if not game then error("game not available for name-based fuzz") end
        sig_or_name = addr -- shift: fuzz.raw("Name", {{...}})
        -- actually fuzz.ints style handles this; keep simple
    end
    if type(sig_or_name) == "table" and not arg_sets then
        arg_sets = sig_or_name; sig_or_name = nil
    end

    -- dispatch to game.call when addr is name
    local is_name = type(addr)=="string" and not addr:match("^0[xX]") and not addr:match("^[0-9a-fA-F]+$")
    -- Heuristic: if it contains only hex chars and maybe 0x, treat as addr already done
    -- Simpler: if game and game.get_address(addr) returns non-nil, it's a name
    if game and type(addr)=="string" and game.get_address and game.get_address(addr) then
        is_name = true
    end

    arg_sets = arg_sets or {{}}
    local sig = sig_or_name

    print(string.format("fuzz %s  %s  %d case(s)", tostring(addr), sig and ("sig "..sig) or "", #arg_sets))
    print(string.rep("-", 60))
    for i, args in ipairs(arg_sets) do
        if type(args) ~= "table" then args = {args} end
        local ok, res
        if is_name then
            ok, res = pcall(function() return game.call(addr, unpack(args)) end)
        else
            local a = type(addr)=="string" and (function()
                local s=addr:gsub("^0[xX]",""); local n=tonumber(s,16); if not n then error("bad addr") end; return n
            end)() or addr
            local ffi = require("ffi")
            local fn
            local ok2, err = pcall(function() fn = ffi.cast((sig or "int()") .. "*", a) end)
            if not ok2 then
                print(string.format("  [%2d] bad sig %s: %s", i, tostring(sig), tostring(err))); ok=false; res=err
            else
                ok, res = pcall(function() return fn(unpack(args)) end)
            end
        end
        local arg_s = "(" .. table.concat((function()
            local t={}; for _,v in ipairs(args) do t[#t+1]=tostring(v) end; return t
        end)(), ", ") .. ")"
        if ok then print(string.format("  [%2d] %-16s -> %s", i, arg_s, tostring(res)))
        else print(string.format("  [%2d] %-16s ERR %s", i, arg_s, tostring(res):gsub("\n.*",""))) end
    end
end

function M.int(name_or_addr, lo, hi, step)
    lo = lo or 0; hi = hi or 10; step = step or 1
    local sets = {}
    for v = lo, hi, step do sets[#sets+1] = {v} end
    return M.raw(name_or_addr, nil, sets)
end

function M.ints(name_or_addr, ranges)
    -- ranges: { {lo,hi,step}, {lo,hi,step}, ... } one per arg position
    if type(ranges) ~= "table" then error("ranges must be array of {lo,hi,step}") end
    local dims = {}
    for _, r in ipairs(ranges) do
        local lo, hi, step = r[1], r[2], r[3] or 1
        local vals = {}
        for v = lo, hi, step do vals[#vals+1]=v end
        dims[#dims+1]=vals
    end
    -- cartesian product, cap 256
    local sets = {{}}
    for _, vals in ipairs(dims) do
        local nxt = {}
        for _, prefix in ipairs(sets) do
            for _, v in ipairs(vals) do
                local t={}; for _,x in ipairs(prefix) do t[#t+1]=x end; t[#t+1]=v
                nxt[#nxt+1]=t
                if #nxt >= 256 then break end
            end
            if #nxt >= 256 then break end
        end
        sets = nxt
        if #sets >= 256 then break end
    end
    return M.raw(name_or_addr, nil, sets)
end

function M.strings(name_or_addr, strs)
    if type(strs) ~= "table" then error("strs must be array of strings") end
    local sets = {}
    for _, s in ipairs(strs) do sets[#sets+1]={s} end
    return M.raw(name_or_addr, nil, sets)
end

return M
