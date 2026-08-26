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

local ffi = require("ffi")
local game = require("gamecalls")

-- Cartesian products are capped so a wide range cannot lock up the console.
local MAX_ARG_SETS = 256

local function format_args(args)
    local parts = {}
    for _, v in ipairs(args) do parts[#parts + 1] = tostring(v) end
    return "(" .. table.concat(parts, ", ") .. ")"
end

-- addr is either a registered name, called through game.call, or an address
-- called through a cast of sig (default "int()").
function M.raw(addr, sig, arg_sets)
    if type(sig) == "table" and not arg_sets then
        arg_sets = sig
        sig = nil
    end
    arg_sets = arg_sets or { {} }

    local numeric = type(addr) == "number" and addr
        or (type(addr) == "string" and tonumber((addr:gsub("^0[xX]", "")), 16))
    local by_name = type(addr) == "string" and game.get_address(addr) ~= nil
    if not by_name and not numeric then
        error("fuzz: " .. tostring(addr) .. " is neither a registered name nor an address")
    end

    local fn
    if not by_name then
        local ptr_type, sig_err = game.pointer_type(sig or "int()")
        if not ptr_type then error("fuzz: " .. sig_err) end
        local ok, cast = pcall(ffi.cast, ptr_type, numeric)
        if not ok then error("fuzz: bad sig " .. tostring(sig) .. ": " .. tostring(cast)) end
        fn = cast
    end

    print(string.format("fuzz %s  %s  %d case(s)", tostring(addr),
        by_name and "by name" or ("sig " .. (sig or "int()")), #arg_sets))
    print(string.rep("-", 60))
    for i, args in ipairs(arg_sets) do
        if type(args) ~= "table" then args = { args } end
        local ok, res
        if by_name then
            ok, res = pcall(game.call, addr, unpack(args))
        else
            ok, res = pcall(fn, unpack(args))
        end
        if ok then
            print(string.format("  [%2d] %-16s -> %s", i, format_args(args), tostring(res)))
        else
            print(string.format("  [%2d] %-16s ERR %s", i, format_args(args), (tostring(res):gsub("\n.*", ""))))
        end
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
    local sets = {{}}
    for _, vals in ipairs(dims) do
        local nxt = {}
        for _, prefix in ipairs(sets) do
            for _, v in ipairs(vals) do
                local t={}; for _,x in ipairs(prefix) do t[#t+1]=x end; t[#t+1]=v
                nxt[#nxt+1]=t
                if #nxt >= MAX_ARG_SETS then break end
            end
            if #nxt >= MAX_ARG_SETS then break end
        end
        sets = nxt
        if #sets >= MAX_ARG_SETS then break end
    end
    local full = 1
    for _, vals in ipairs(dims) do full = full * #vals end
    if full > #sets then
        print(string.format("fuzz.ints: %d of %d combinations, capped at %d", #sets, full, MAX_ARG_SETS))
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
