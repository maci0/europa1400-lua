-- Europa 1400 - Execution Tracer
--
-- Lightweight call tracer for registered game functions. Wraps
-- `game.call` to record arguments, return values and timing so
-- you can infer signatures and side effects without a debugger.
-- Works entirely in the Lua console thread; no code patching.
--
--   trace = require("trace")   -- or already available as `trace`
--   trace.hook()                      -- start tracing all game.call
--   game.call("GetGold")              -- automatically logged
--   trace.call("GetGold", 1, 2)       -- explicit traced call
--   trace.show(20)                    -- last 20 entries
--   trace.stats()                     -- hits + avg time per function
--   trace.save("trace.lua")           -- persist log
--   trace.clear(); trace.unhook()     -- stop

local M = {}

local game = require("gamecalls")

M.log = {}
M.max = 500
M.enabled = nil          -- nil = trace all, or set {["Fn"]=true}
M._orig_call = nil
M._hooked = false

local function should_trace(name)
    if M.enabled == nil then return true end
    return M.enabled[name] == true
end

local function record(name, args, result, ok, ms)
    local e = {
        t = os.date("%H:%M:%S"),
        name = name,
        args = args,
        result = result,
        ok = ok,
        ms = ms,
    }
    M.log[#M.log + 1] = e
    if #M.log > M.max then table.remove(M.log, 1) end
    return e
end

local function fmt_args(a)
    if not a or #a == 0 then return "" end
    local parts = {}
    for i, v in ipairs(a) do
        if type(v) == "number" and v > 65535 then parts[i] = string.format("0x%X(%d)", v, v)
        elseif type(v) == "string" then parts[i] = string.format("%q", v)
        else parts[i] = tostring(v) end
    end
    return table.concat(parts, ", ")
end

-- Explicit traced call (does not require hook)
function M.call(name, ...)
    local g = game
    if not g then error("game module not available") end
    if type(name) ~= "string" or name == "" then error("name must be non-empty string") end
    local args = {...}
    local t0 = os.clock()
    local ok, res = pcall(g.call, name, ...)
    local ms = (os.clock() - t0) * 1000
    record(name, args, ok and res or res, ok, ms)
    if not ok then error(res) end
    return res
end

function M.enable(name)
    if type(name) ~= "string" or name == "" then error("name required") end
    M.enabled = M.enabled or {}
    M.enabled[name] = true
end

function M.disable(name)
    if not M.enabled then return end
    M.enabled[name] = nil
    if not next(M.enabled) then M.enabled = nil end
end

function M.enable_only(names)
    M.enabled = {}
    for _, n in ipairs(names) do M.enabled[n] = true end
end

function M.hook()
    if M._hooked then return end
    local g = game
    if not g then error("game module not available") end
    M._orig_call = g.call
    local orig = g.call
    g.call = function(name, ...)
        if not should_trace(name) then return orig(name, ...) end
        local args = {...}
        local t0 = os.clock()
        local ok, res = pcall(orig, name, ...)
        local ms = (os.clock() - t0) * 1000
        record(name, args, ok and res or res, ok, ms)
        if not ok then error(res) end
        return res
    end
    M._hooked = true
    print("trace: hooked game.call (all calls will be logged)")
end

function M.unhook()
    if not M._hooked then return end
    local g = game
    if g and M._orig_call then g.call = M._orig_call end
    M._orig_call = nil
    M._hooked = false
    print("trace: unhooked")
end

function M.show(n)
    n = n or 20
    if #M.log == 0 then print("trace: no entries"); return M.log end
    local from = math.max(1, #M.log - n + 1)
    for i = from, #M.log do
        local e = M.log[i]
        local status = e.ok and "OK" or "ERR"
        print(string.format("[%s] #%d %s(%s) -> %s [%s %.2fms]",
            e.t, i, e.name, fmt_args(e.args), tostring(e.result), status, e.ms))
    end
    return M.log
end

function M.stats()
    if #M.log == 0 then print("trace: no entries"); return {} end
    local by = {}
    for _, e in ipairs(M.log) do
        local s = by[e.name]
        if not s then s = { n=0, ok=0, err=0, total_ms=0 }; by[e.name]=s end
        s.n = s.n + 1
        if e.ok then s.ok = s.ok + 1 else s.err = s.err + 1 end
        s.total_ms = s.total_ms + (e.ms or 0)
    end
    print(string.format("%-24s %5s %5s %5s %10s", "function", "calls", "ok", "err", "avg ms"))
    print(string.rep("-", 55))
    for name, s in pairs(by) do
        print(string.format("%-24s %5d %5d %5d %10.2f", name, s.n, s.ok, s.err, s.total_ms / s.n))
    end
    return by
end

function M.clear()
    M.log = {}
    print("trace: cleared")
end

function M.save(path)
    path = path or "trace.lua"
    local f, err = io.open(path, "w")
    if not f then error("cannot open " .. path .. ": " .. tostring(err)) end
    f:write("-- trace log " .. os.date("%Y-%m-%d %H:%M:%S") .. "\nreturn {\n")
    for i, e in ipairs(M.log) do
        f:write(string.format("  {t=%q,name=%q,ok=%s,ms=%.3f,args={", e.t, e.name, tostring(e.ok), e.ms or 0))
        for j, v in ipairs(e.args or {}) do
            if type(v) == "string" then f:write(string.format("%q", v))
            else f:write(tostring(v)) end
            if j < #e.args then f:write(",") end
        end
        f:write(string.format("},result=%q},\n", tostring(e.result)))
        if i > 5000 then break end
    end
    f:write("}\n")
    f:close()
    print("trace: saved " .. #M.log .. " entries to " .. path)
end

return M
