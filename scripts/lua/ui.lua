-- Europa 1400 - UI Helper
--
-- Thin convenience around ShowMessage/ShowDialog-style functions
-- once reversed, plus window enumeration sugar for dialog flow.
--
--   ui = require("ui")  -- or already `ui`
--   ui.message("Hello from Lua!")
--   choice = ui.dialog("Attack?", 2)  -- 2 buttons
--   ui.windows()                       -- enumerate visible windows
--   ui.find("Europa*")
--
-- All `game.*` calls are pcall-wrapped so a missing catalog entry
-- just prints a hint instead of crashing the console.

local M = {}

local function try_game(name, ...)
    local game = _G.game
    if not game or not game.call then
        print(string.format("ui: game.%s not available, register %s first", tostring(name), tostring(name)))
        return nil
    end
    local ok, res = pcall(game.call, name, ...)
    if not ok then
        print(string.format("ui: game.call(%q) failed: %s", tostring(name), tostring(res)))
        return nil
    end
    return res
end

function M.message(text)
    if type(text) ~= "string" then error("text must be string") end
    -- prefer ShowMessage if catalog-registered, fall back to ShowDialog
    local res = try_game("ShowMessage", text)
    if res ~= nil then return res end
    return try_game("ShowDialog", text, 1)
end

function M.dialog(text, buttons)
    if type(text) ~= "string" then error("text must be string") end
    buttons = buttons or 1
    local res = try_game("ShowDialog", text, buttons)
    if res ~= nil then return res end
    return try_game("ShowMessage", text)
end

function M.windows()
    local sys = _G.system
    if not sys or not sys.window_info then
        print("ui.windows: system.window_info not available")
        return {}
    end
    return sys.window_info()
end

function M.find(pattern)
    if type(pattern) ~= "string" or pattern == "" then error("pattern required") end
    local info = M.windows()
    -- system.window_info returns {windows={...}} or similar; normalize
    local list = nil
    if type(info) == "table" then
        list = info.windows or info
    end
    if type(list) ~= "table" then return {} end
    -- very small glob: * == .*, ? == .
    local lua_pat = "^" .. pattern:gsub("([%.%+%-%[%]%(%)%$%%])","%%%1"):gsub("%*",".*"):gsub("%?",".") .. "$"
    local out = {}
    for _, w in ipairs(list) do
        local title = w.title or w.text or w.name or ""
        if title:find(lua_pat) then out[#out+1]=w end
    end
    print(string.format("ui.find %q: %d hit(s)", pattern, #out))
    for _, w in ipairs(out) do
        print(string.format("  hwnd 0x%08X  %q  class %q", w.hwnd or w.handle or 0, w.title or "", w.class or w.className or ""))
    end
    return out
end

return M
