-- Europa 1400 - Quest Helper
--
-- Wraps quest-related catalog entries behind `quest.*`.
--
--   quest = dofile('lua/quest.lua')  -- or already `quest`
--   quest.find()                      -- catalog.hunt("quest")
--   quest.scan(0x00400000, 0x300000)  -- presets.hunt quest
--   quest.start(questId, ownerId)     -- StartQuest
--   quest.complete(questId)           -- CompleteQuest
--
-- All wrappers pcall game.call and error with a hint if not yet registered.

local M = {}

local function game_ok()
    local g = _G.game
    if g and g.read_mem then return g end
    local ok, m = pcall(dofile, "lua/gamecalls.lua")
    if ok and m then return m end
    return nil
end

local function call_or_hint(name, ...)
    local g = game_ok()
    if g and g.call then
        local ok, ret = pcall(g.call, name, ...)
        if ok then return ret end
        error(tostring(ret))
    end
    error(name .. " not registered; run quest.find() / catalog.hunt('quest') or game.register first")
end

function M.scan(base, size)
    base = base or 0x00400000; size = size or 0x300000
    print(string.format("quest.scan [0x%08X +0x%X]", base, size))
    local presets = _G.presets or (pcall(dofile, "lua/presets.lua") and _G.presets)
    local hits = {}
    if presets and presets.hunt then
        hits = presets.hunt("quest", base, size) or {}
        if #hits > 0 then print(string.format("quest.scan: %d hit(s)", #hits)); return hits end
    end
    print("quest.scan: no hits; try quest.find() or wider base/size")
    return hits
end

function M.find(base, size)
    local cat = _G.catalog or (pcall(dofile, "lua/catalog.lua") and _G.catalog)
    if not cat or not cat.hunt then error("catalog not available") end
    return cat.hunt("quest", base, size)
end

function M.start(questId, ownerId)
    local r = call_or_hint("StartQuest", questId, ownerId)
    print(string.format("quest start id=%s owner=%s -> %s", tostring(questId), tostring(ownerId), tostring(r)))
    return r
end

function M.complete(questId)
    local r = call_or_hint("CompleteQuest", questId)
    print(string.format("quest complete id=%s -> %s", tostring(questId), tostring(r)))
    return r
end

function M.status(questId) return call_or_hint("GetQuestStatus", questId) end
function M.fail(questId) local r=call_or_hint("FailQuest", questId); print(string.format("quest fail id=%s -> %s", tostring(questId), tostring(r))); return r end
function M.owner(questId) return call_or_hint("GetQuestOwner", questId) end
function M.target(questId) return call_or_hint("GetQuestTarget", questId) end
function M.get_var(questId, varId) return call_or_hint("GetQuestVar", questId, varId) end
function M.set_var(questId, varId, v) local r=call_or_hint("SetQuestVar", questId, varId, v); print(string.format("quest %s var %s -> %s", tostring(questId), tostring(varId), tostring(v))); return r end

return M
