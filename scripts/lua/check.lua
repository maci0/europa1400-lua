-- Europa 1400 - self-test, runnable on Linux.
--
--   make check        (or: luajit scripts/lua/check.lua)
--
-- Loads and executes every module against a stubbed kernel32, so a syntax
-- error, a missing require target, a conflicting ffi.cdef or a module that
-- crashes at load time fails here rather than in the game. The stub returns
-- nil from every call, so only load-time behaviour is exercised; anything
-- that reads live process memory has to be checked on Windows.

local ffi = require("ffi")

local here = arg and arg[0] and arg[0]:match("^(.*)[/\\][^/\\]*$") or "scripts/lua"
package.path = here .. "/?.lua;" .. package.path

local stub = setmetatable({}, { __index = function() return function() return nil end end })
local real_load = ffi.load
ffi.load = function(name)
    if name == "kernel32" or name == "user32" or name == "psapi" or name == "winmm" then
        return stub
    end
    return real_load(name)
end

local failures = 0
local checks = 0

local function check(label, ok, detail)
    checks = checks + 1
    if ok then
        print("OK " .. label)
    else
        failures = failures + 1
        io.stderr:write("FAIL " .. label .. ": " .. tostring(detail) .. "\n")
    end
    return ok
end

local function modules()
    local names = {}
    local list = io.open(here .. "/.modules")
    if list then
        for line in list:lines() do names[#names + 1] = line end
        list:close()
        return names
    end
    -- No directory listing in plain Lua; derive the set from init.lua, which
    -- has to name every module it binds anyway.
    local init = assert(io.open(here .. "/init.lua"), "cannot read init.lua")
    local seen = {}
    for line in init:lines() do
        local name = line:match('^%s*[%w_]+%s*=%s*require%("([%w_]+)"%)')
            or line:match('^%s*local%s+[%w_]+%s*=%s*require%("([%w_]+)"%)')
        if name and not seen[name] then
            seen[name] = true
            names[#names + 1] = name
        end
    end
    init:close()
    return names
end

local names = modules()
check("init.lua names at least 40 modules", #names >= 40, #names .. " found")

for _, name in ipairs(names) do
    local ok, err = pcall(require, name)
    check(name, ok, err)
end

-- Every .lua file on disk must be reachable, otherwise a module can rot
-- unloaded and untested.
do
    local reachable = { init = true, check = true }
    for _, name in ipairs(names) do reachable[name] = true end
    local missing = {}
    for name in pairs(reachable) do
        if not io.open(here .. "/" .. name .. ".lua") then missing[#missing + 1] = name end
    end
    check("every named module exists on disk", #missing == 0, table.concat(missing, ", "))
end

do
    local decoded = require("disasm").decode("55 8B EC 83 EC 10 C3")
    check("disasm.decode", decoded and decoded:find("push ebp") and decoded:find("ret") ~= nil, decoded)
end

do
    local got = require("sig").normalize("55 8b ec ??")
    check("sig.normalize", got == "55 8B EC ??", got)
end

-- Regression: ffi.cast needs "int (*)()", not "int()*". Every registration
-- used to fail at cast time, so game.call could never reach a game function.
do
    local game = require("gamecalls")
    game.debug_on(false)
    for i, sig in ipairs({ "int()", "void(int)", "int(int, int)", "char*()",
                           "void*(int,int,int)", "int(void*,int)",
                           "int __stdcall(int, char*)", "int __thiscall(void*, int)" }) do
        local ok, err = pcall(game.register, "SigShape" .. i, 0x00401000, sig, sig)
        check("register " .. sig, ok, err)
    end
    check("register rejects a signature with no arg list",
        select(1, pcall(game.register, "NoArgs", 0x00401000, "int", "bad")) == false)
    game.debug_on(true)
end

-- The README and the docs quote the catalog size and its status; a stale count
-- there reads as progress that has not happened.
do
    local entries = require("catalog").entries
    local candidates, addressed = 0, 0
    for _, e in ipairs(entries) do
        if e.status == "candidate" then candidates = candidates + 1 end
        if e.address and e.address ~= 0 then addressed = addressed + 1 end
    end
    check("every catalog entry is an unaddressed candidate",
        candidates == #entries and addressed == 0,
        #entries .. " entries, " .. candidates .. " candidates, " .. addressed .. " addressed")

    local readme = assert(io.open(here .. "/../../README.md")):read("*a")
    check("README quotes the catalog size",
        readme:find(tostring(#entries), 1, true) ~= nil, #entries .. " entries")
end

-- probe, obj and fuzz built cast types the same broken way game.register did.
do
    local game = require("gamecalls")
    check("pointer_type builds a function pointer",
        game.pointer_type("int(int, int)") == "int (*)(int, int)", game.pointer_type("int(int, int)"))
    check("pointer_type keeps the calling convention",
        game.pointer_type("int __stdcall(int)") == "int __stdcall (*)(int)")
    check("pointer_type rejects a bare type", game.pointer_type("int") == nil)
end

-- cheat.* names per-object fields (a building's accident chance) that live on
-- the object <mod>.at(addr) returns, not on the module table. Reaching the
-- registration hint proves delegate() routed through .at() instead of raising
-- "does not exist".
do
    local ok, err = pcall(require("cheat").accident, 0x00401000)
    check("cheat delegates to the object accessor",
        ok == false and tostring(err):find("not registered") ~= nil, err)
end

-- game.save writes a file that re-registers through require("gamecalls"); if it
-- emitted dofile instead, the reload would populate a second, invisible registry.
do
    local game = require("gamecalls")
    game.debug_on(false)
    game.register("CheckRoundTrip", 0x00401000, "int()", "self-test")
    local path = os.tmpname()
    game.save(path)
    local body = assert(io.open(path)):read("*a")
    os.remove(path)
    check("game.save round-trips through require",
        body:find('require%("gamecalls"%)') ~= nil and body:find("CheckRoundTrip") ~= nil, body:sub(1, 200))
    game.debug_on(true)
end

-- init.lua last: it binds the globals the console exposes, and a name bound
-- twice (report the module, then report the function) is invisible until then.
do
    local ok, err = pcall(dofile, here .. "/init.lua")
    check("init.lua runs", ok, err)
    if ok then
        check("init.lua binds the report module, not a shadowing alias",
            type(_G.report) == "table" and type(_G.report.save) == "function", type(_G.report))
        check("help() runs", pcall(_G.help))
    end
end

if failures > 0 then
    io.stderr:write(string.format("\n%d of %d checks failed\n", failures, checks))
    os.exit(1)
end
print(string.format("\nAll %d checks passed", checks))
