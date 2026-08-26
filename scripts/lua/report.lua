-- Europa 1400 - RE Report Generator
--
-- One-command snapshot of everything you have reversed so far.
-- Writes a markdown report with system info, loaded modules,
-- registered game functions, RTTI/vtable samples, patches and hooks.
-- Shareable and re-runnable: the report also embeds a Lua snippet
-- to re-register the discovered functions.
--
--   report = require("report")   -- or already `report`
--   report.save("my_report.md")
--   report.save()                        -- -> re_report.md
--   report.print()                       -- to console

local M = {}

local DEFAULT_PATH = "re_report.md"

local function safe_call(mod, fn, ...)
    local g = _G[mod]
    if not g or type(g[fn]) ~= "function" then return nil, "no " .. mod .. "." .. fn end
    local ok, res = pcall(g[fn], ...)
    if not ok then return nil, tostring(res) end
    return res
end

local function capture_lines(fn)
    local lines = {}
    local old_print = print
    print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        lines[#lines+1] = table.concat(parts, "\t")
    end
    local ok, err = pcall(fn)
    print = old_print
    if not ok then lines[#lines+1] = "[error] " .. tostring(err) end
    return table.concat(lines, "\n")
end

function M.collect()
    local st = { date = os.date("%Y-%m-%d %H:%M:%S") }

    -- game registry
    local game = _G.game
    if game and game.get_registry then
        local ok, reg = pcall(game.get_registry)
        if ok and type(reg) == "table" then
            st.game = {}
            for name, info in pairs(reg) do
                st.game[#st.game+1] = { name=name, address=info.address, signature=info.signature, description=info.description }
            end
            table.sort(st.game, function(a,b) return a.name < b.name end)
        end
    end

    -- system + modules (captured as text)
    if _G.system then
        st.system_text = capture_lines(function() if _G.system.info then _G.system.info() end end)
        st.modules_text = capture_lines(function() if _G.system.list_modules then _G.system.list_modules() end end)
        st.memory_text = capture_lines(function() if _G.system.memory_info then _G.system.memory_info() end end)
    end

    -- patches / hooks
    if _G.patch and _G.patch.list then
        st.patches_text = capture_lines(function() _G.patch.list() end)
    end
    if _G.hook and _G.hook.list then
        -- hook.list needs a mod arg; try game exe
        st.hook_text = capture_lines(function() pcall(_G.hook.list, "game.exe") end)
    end

    -- rtti sample (first 30)
    if _G.rtti and _G.rtti.list then
        local ok, res = pcall(_G.rtti.list, 0x00400000, 0x300000, 30)
        if ok then st.rtti = res end
    end

    -- notes
    if _G.session and _G.session.collect then
        local ok, s = pcall(_G.session.collect)
        if ok then st.notes = s.notes end
    end

    return st
end

function M.save(path)
    path = path or DEFAULT_PATH
    local st = M.collect()
    local f, err = io.open(path, "w")
    if not f then error("cannot open " .. path .. ": " .. tostring(err)) end

    f:write("# Europa 1400 RE Report: " .. st.date .. "\n\n")

    f:write("## Game Functions (" .. tostring(st.game and #st.game or 0) .. ")\n\n")
    if st.game and #st.game > 0 then
        f:write("| Name | Address | Signature | Description |\n")
        f:write("|------|---------|-----------|-------------|\n")
        for _, e in ipairs(st.game) do
            f:write(string.format("| %s | 0x%08X | `%s` | %s |\n", e.name, e.address, e.signature, (e.description or ""):gsub("|","/")))
        end
        f:write("\n```lua\n-- Re-register snippet\n")
        for _, e in ipairs(st.game) do
            f:write(string.format('game.register("%s", 0x%08X, "%s", "%s")\n',
                e.name:gsub('"','\\"'), e.address, e.signature:gsub('"','\\"'), (e.description or ""):gsub('"','\\"')))
        end
        f:write("```\n\n")
    else
        f:write("_No registered functions yet; use `finder`/`scan`/`valuescan` then `game.register`._\n\n")
    end

    if st.rtti and #st.rtti > 0 then
        f:write("## RTTI Sample (first 30)\n\n")
        for _, e in ipairs(st.rtti) do
            f:write(string.format("- `0x%08X`  **%s**  `%s`\n", e.addr, e.demangled, e.mangled))
        end
        f:write("\n")
    end

    if st.system_text and st.system_text ~= "" then
        f:write("## System\n\n```\n" .. st.system_text .. "\n```\n\n")
    end
    if st.modules_text and st.modules_text ~= "" then
        f:write("## Loaded Modules\n\n```\n" .. st.modules_text .. "\n```\n\n")
    end
    if st.memory_text and st.memory_text ~= "" then
        f:write("## Memory\n\n```\n" .. st.memory_text .. "\n```\n\n")
    end
    if st.patches_text then
        f:write("## Patches\n\n```\n" .. st.patches_text .. "\n```\n\n")
    end
    if st.hook_text then
        f:write("## IAT Hooks (game.exe)\n\n```\n" .. st.hook_text .. "\n```\n\n")
    end
    if st.notes and #st.notes > 0 then
        f:write("## Notes\n\n")
        for i, n in ipairs(st.notes) do
            f:write(string.format("%d. [%s] %s\n", i, n.t or "?", n.text or "" ))
        end
        f:write("\n")
    end

    f:write("---\n_Generated by `report.save`; `report.print()` for the console view._\n")
    f:close()
    print(string.format("report: saved -> %s  (%d funcs)", path, st.game and #st.game or 0))
    return path
end

function M.print()
    local path = M.save(DEFAULT_PATH)
    -- also echo a short summary
    local st = M.collect()
    print(string.format("report: %d funcs, %d rtti sample", st.game and #st.game or 0, st.rtti and #st.rtti or 0))
    return path
end

return M
