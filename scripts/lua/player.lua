-- Europa 1400 - Player Helper
--
-- High-level wrapper around the low-level primitives for the most
-- common first target: the player (gold/fame/name). Keeps the
-- raw valuescan/pointer/struct/xref flow but behind `player.*`
-- so `catalog` economy entries can be triaged in one call.
--
--   player = dofile('lua/player.lua')  -- or already `player`
--   player.scan(0x00400000, 0x300000)   -- valuescan for current gold
--   player.at(0x12340000)                -- object at addr with gold/fame/name
--   player.at(0x12340000):gold()         -- read int at +0
--   player.at(0x12340000):set_gold(9999)
--   player.find()                        -- catalog.hunt("economy") helper
--   player.dump(0x12340000)              -- struct-aware dump

local M = {}

local function game_ok()
    local g = _G.game
    if g and g.read_mem then return g end
    local ok, m = pcall(dofile, "lua/gamecalls.lua")
    if ok and m then return m end
    return nil
end

local function to_addr(v)
    if type(v) == "number" then return v end
    if type(v) ~= "string" then error("addr must be number or hex string") end
    local s = v:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^0[xX]", "")
    local n = tonumber(s, 16)
    if not n then error("invalid addr: " .. tostring(v)) end
    return n
end

-- Try to locate player struct via economy preset; fall back to valuescan hint.
function M.scan(base, size, hint_gold)
    base = base or 0x00400000; size = size or 0x300000
    print(string.format("player.scan [0x%08X +0x%X] hint %s", base, size, tostring(hint_gold or "-")))
    -- Prefer preset/finder flow
    local presets = _G.presets or (pcall(dofile, "lua/presets.lua") and _G.presets)
    if presets and presets.hunt then
        local hits = presets.hunt("gold", base, size) or {}
        if #hits > 0 then
            print(string.format("player.scan: %d preset hit(s), try player.at(hits[1])", #hits))
            return hits
        end
    end
    -- Fallback: valuescan for hint_gold if provided
    if hint_gold and type(hint_gold) == "number" then
        local vs = _G.valuescan or (pcall(dofile, "lua/valuescan.lua") and _G.valuescan)
        if vs and vs.int32 then
            local hits = vs.int32(hint_gold, base, size, 64) or {}
            print(string.format("player.scan: valuescan for %d -> %d hit(s)", hint_gold, #hits))
            return hits
        end
    end
    print("player.scan: no hits; try player.find() or wider base/size")
    return {}
end

function M.find(base, size)
    local cat = _G.catalog or (pcall(dofile, "lua/catalog.lua") and _G.catalog)
    if not cat or not cat.hunt then error("catalog not available") end
    return cat.hunt("economy", base, size)
end

local Obj = {}
Obj.__index = Obj

function Obj:gold()
    local g = game_ok()
    if not g then error("game not available") end
    local d = g.read_mem(self.addr, 4, "int")
    if not d then error(string.format("gold read failed at 0x%08X", self.addr)) end
    return d[0]
end

function Obj:set_gold(v)
    if type(v) ~= "number" then error("gold must be number") end
    local g = game_ok()
    if not g then error("game not available") end
    local ffi = require("ffi")
    local p = ffi.new("int[1]", v)
    local ok = g.write_mem(self.addr, p, 4)
    if not ok then error("set_gold write failed") end
    print(string.format("player 0x%08X gold -> %d", self.addr, v))
    return true
end

function Obj:fame()
    local g = game_ok()
    if not g then error("game not available") end
    local off = 4
    local d = g.read_mem(self.addr + off, 4, "int")
    if not d then error(string.format("fame read failed at 0x%08X", self.addr + off)) end
    return d[0]
end

function Obj:set_fame(v)
    if type(v) ~= "number" then error("fame must be number") end
    local g = game_ok()
    local ffi = require("ffi")
    local p = ffi.new("int[1]", v)
    local ok = g.write_mem(self.addr + 4, p, 4)
    if not ok then error("set_fame write failed") end
    print(string.format("player 0x%08X fame -> %d", self.addr, v))
    return true
end

function Obj:name()
    local g = game_ok()
    if not g then error("game not available") end
    local d = g.read_mem(self.addr + 8, 32, "char")
    if not d then return nil end
    local s = require("ffi").string(d, 32)
    local z = s:find("\0", 1, true)
    if z then s = s:sub(1, z-1) end
    return s
end

function Obj:dump()
    local str = _G.struct or (pcall(dofile, "lua/struct.lua") and _G.struct)
    if str and str.dump then
        -- Try registered Player struct first
        local ok = pcall(str.dump, self.addr, "Player")
        if not ok then
            pcall(str.dump, self.addr, {
                {name="gold", type="int", offset=0},
                {name="fame", type="int", offset=4},
                {name="name", type="char[32]", offset=8},
            })
        end
    else
        print(string.format("player @ 0x%08X  gold=%s fame=%s name=%q",
            self.addr, tostring(pcall(function() return self:gold() end) and self:gold() or "?"),
            tostring(pcall(function() return self:fame() end) and self:fame() or "?"),
            tostring(self:name() or "")))
    end
    return self
end

function M.at(addr)
    addr = to_addr(addr)
    return setmetatable({ addr = addr }, Obj)
end


local function call_or_hint(name, ...)
    local g = game_ok()
    if g and g.call then
        local ok, ret = pcall(g.call, name, ...)
        if ok then return ret end
        error(tostring(ret))
    end
    error(name .. " not registered; run player.find()/catalog.hunt or game.register first")
end

function M.gold_via_call() return call_or_hint("GetPlayerGold") end
function M.set_gold_via_call(v) local r=call_or_hint("SetPlayerGold", v); print(string.format("SetPlayerGold %s -> %s", tostring(v), tostring(r))); return r end
function M.add_gold(amt) local r=call_or_hint("AddGold", amt); print(string.format("AddGold %s -> %s", tostring(amt), tostring(r))); return r end
function M.health(pid) return call_or_hint("GetPlayerHealth", pid or 0) end
function M.set_health(pid, hp) local r=call_or_hint("SetPlayerHealth", pid or 0, hp); print(string.format("health pid=%s -> %s", tostring(pid), tostring(hp))); return r end
function M.fame_via_call(pid) return call_or_hint("GetPlayerFame", pid or 0) end
function M.set_fame_via_call(pid, f) local r=call_or_hint("SetPlayerFame", pid or 0, f); print(string.format("fame pid=%s -> %s", tostring(pid), tostring(f))); return r end
function M.show_message(msg) local r=call_or_hint("ShowMessage", msg); print(string.format("message %q -> %s", tostring(msg), tostring(r))); return r end
function M.show_dialog(msg, flags) local r=call_or_hint("ShowDialog", msg or "", flags or 0); print(string.format("dialog %q -> %s", tostring(msg), tostring(r))); return r end
function M.trade_execute(a,b,good,amt) local r=call_or_hint("TradeExecute", a,b,good or 0, amt or 1); print(string.format("trade %s->%s good=%s x%s -> %s", tostring(a), tostring(b), tostring(good), tostring(amt), tostring(r))); return r end
function M.diplomacy_offer(a,b,offer) local r=call_or_hint("SendDiplomacyOffer", a,b,offer or 0); print(string.format("diplomacy %s->%s offer=%s -> %s", tostring(a), tostring(b), tostring(offer), tostring(r))); return r end



function M.gold_raw(pid) return call_or_hint("GetPlayerGoldRaw", pid or 0) end
function M.level(pid) return call_or_hint("GetPlayerLevel", pid or 0) end
function M.get_name(pid) return call_or_hint("GetPlayerName", pid or 0) end


return M
