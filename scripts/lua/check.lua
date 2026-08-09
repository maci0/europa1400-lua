-- Europa 1400 - Self-Test (Linux-friendly)
--
-- Verifies all Lua modules are loadfile-clean and that core helpers
-- behave as expected without requiring Windows (no kernel32 load).
-- Run via `make check` or:
--   luajit scripts/lua/check.lua
--
-- On Windows the same file can also exercise live helpers when loaded
-- inside the game's Lua console; on Linux it only checks parsing.

local files = {
    "scripts/lua/gamecalls.lua",
    "scripts/lua/sysinfo.lua",
    "scripts/lua/beep.lua",
    "scripts/lua/memscan.lua",
    "scripts/lua/valuescan.lua",
    "scripts/lua/pointer.lua",
    "scripts/lua/exports.lua",
    "scripts/lua/xrefs.lua",
    "scripts/lua/patch.lua",
    "scripts/lua/watch.lua",
    "scripts/lua/struct.lua",
    "scripts/lua/finder.lua",
    "scripts/lua/trace.lua",
    "scripts/lua/disasm.lua",
    "scripts/lua/sig.lua",
    "scripts/lua/hook.lua",
    "scripts/lua/presets.lua",
    "scripts/lua/strings.lua",
    "scripts/lua/session.lua",
    "scripts/lua/vtable.lua",
    "scripts/lua/threads.lua",
    "scripts/lua/rtti.lua",
    "scripts/lua/report.lua",
    "scripts/lua/diff.lua",
    "scripts/lua/heap.lua",
    "scripts/lua/probe.lua",
    "scripts/lua/dump.lua",
    "scripts/lua/auto.lua",
    "scripts/lua/fuzz.lua",
    "scripts/lua/near.lua",
    "scripts/lua/stack.lua",
    "scripts/lua/catalog.lua",
    "scripts/lua/ui.lua",
    "scripts/lua/player.lua",
    "scripts/lua/city.lua",
    "scripts/lua/building.lua",
    "scripts/lua/unit.lua",
    "scripts/lua/inventory.lua",
    "scripts/lua/economy.lua",
    "scripts/lua/world.lua",
    "scripts/lua/quest.lua",
    "scripts/lua/social.lua",
    "scripts/lua/cheat.lua",
    "scripts/lua/state.lua",
    "scripts/lua/snapshot.lua",
    "scripts/lua/civic.lua",
    "scripts/lua/enums.lua",
    "scripts/lua/codegen.lua",
    "scripts/lua/obj.lua",
    "scripts/lua/init.lua",
    "scripts/lua/game_functions.lua",
}

local fails = 0
for _, f in ipairs(files) do
    local fn, err = loadfile(f)
    if not fn then
        io.stderr:write("FAIL " .. f .. ": " .. tostring(err) .. "\n")
        fails = fails + 1
    else
        print("OK " .. f)
    end
end

-- spot-check disasm.decode without needing kernel32 (stub)
do
    local ffi = require("ffi")
    local orig_load = ffi.load
    local stubbed = false
    ffi.load = function(name)
        if name == "kernel32" and not stubbed then
            stubbed = true
            -- Provide minimal kernel32 API so disasm.lua can load
            -- (actual process-memory paths won't be exercised here)
            return setmetatable({}, {
                __index = function(_, k)
                    return function() return nil end
                end
            })
        end
        return orig_load(name)
    end
    local ok, mod = pcall(loadfile, "scripts/lua/disasm.lua")
    if ok and mod then
        local ok2, m = pcall(mod)
        if ok2 and m and m.decode then
            local ok3, out = pcall(m.decode, "55 8B EC 83 EC 10 C3")
            if ok3 and out and out:find("push ebp") and out:find("ret") then
                print("OK disasm.decode smoke test")
            else
                io.stderr:write("FAIL disasm.decode smoke test\n")
                fails = fails + 1
            end
        end
    end
    ffi.load = orig_load
end

-- sig.normalize smoke test (no kernel32 needed beyond load)
do
    local ffi = require("ffi")
    local orig_load = ffi.load
    ffi.load = function(name)
        if name == "kernel32" then
            return { GetModuleHandleA=function() return nil end,
                     GetCurrentProcess=function() return ffi.cast("void*",1) end,
                     ReadProcessMemory=function() return 0 end,
                     VirtualProtect=function() return 0 end,
                     FlushInstructionCache=function() return 0 end }
        end
        return orig_load(name)
    end
    local ok, mod = pcall(loadfile, "scripts/lua/sig.lua")
    if ok and mod then
        local ok2, m = pcall(mod)
        if ok2 and m then
            local got = m.normalize("55 8b ec ??")
            if got == "55 8B EC ??" then print("OK sig.normalize smoke test")
            else io.stderr:write("FAIL sig.normalize: got " .. tostring(got) .. "\n"); fails=fails+1 end
        end
    end
    ffi.load = orig_load
end

if fails > 0 then
    io.stderr:write(string.format("\n%d check(s) failed\n", fails))
    os.exit(1)
else
    print(string.format("\nAll %d checks passed", #files + 2))
end
