-- Europa 1400 - Unit Helper
--
-- High-level wrapper for unit / character / party targets.
-- Mirrors player/city/building: wraps game.read_mem + preset flows
-- behind `unit.*` so catalog unit/player entries triage quickly.
--
--   unit = dofile('lua/unit.lua')  -- or already `unit`
--   unit.find()                      -- catalog.hunt("unit") helper
--   unit.scan(0x00400000, 0x300000)  -- preset hunt for unit strings
--   unit.at(0x12340000):health()     -- read HP
--   unit.at(0x12340000):set_health(100)
--   unit.at(0x12340000):move(512, 384)
--   unit.at(0x12340000):dump()
--
-- Offsets are defaults — calibrate via struct.dump once the real
-- unit struct is reversed. Override e.g.  unit.offsets.health = 0x18

local M = {}

M.offsets = {
    health    = 0,
    owner     = 4,
    utype     = 8,   -- unit type id
    x         = 12,
    y         = 16,
    skill     = 20,  -- primary skill / level bucket
    -- name char[32] at +24 if present
    name      = 24,
    name_len  = 32,
}

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

function M.scan(base, size)
    base = base or 0x00400000; size = size or 0x300000
    print(string.format("unit.scan [0x%08X +0x%X]", base, size))
    local presets = _G.presets or (pcall(dofile, "lua/presets.lua") and _G.presets)
    if presets and presets.hunt then
        local hits = presets.hunt("unit", base, size) or {}
        if #hits > 0 then
            print(string.format("unit.scan: %d preset hit(s), try unit.at(hits[1])", #hits))
            return hits
        end
    end
    print("unit.scan: no hits; try unit.find() or wider base/size")
    return {}
end

function M.find(base, size)
    local cat = _G.catalog or (pcall(dofile, "lua/catalog.lua") and _G.catalog)
    if not cat or not cat.hunt then error("catalog not available") end
    return cat.hunt("unit", base, size)
end

local Obj = {}
Obj.__index = Obj

local function _read_int(addr, field)
    local g = game_ok()
    if not g then error("game not available") end
    local off = M.offsets[field]
    if off == nil then error("unknown offset: " .. tostring(field)) end
    local d = g.read_mem(addr + off, 4, "int")
    if not d then error(string.format("%s read failed at 0x%08X", field, addr + off)) end
    return d[0]
end

local function _write_int(addr, field, v)
    if type(v) ~= "number" then error(field .. " must be number") end
    local g = game_ok()
    if not g then error("game not available") end
    local off = M.offsets[field]
    if off == nil then error("unknown offset: " .. tostring(field)) end
    local ffi = require("ffi")
    local p = ffi.new("int[1]", v)
    local ok = g.write_mem(addr + off, p, 4)
    if not ok then error("write failed: " .. field) end
    print(string.format("unit 0x%08X %s -> %d", addr, field, v))
    return true
end

function Obj:health()    return _read_int(self.addr, "health") end
function Obj:owner()     return _read_int(self.addr, "owner") end
function Obj:utype()     return _read_int(self.addr, "utype") end
function Obj:x()         return _read_int(self.addr, "x") end
function Obj:y()         return _read_int(self.addr, "y") end
function Obj:skill()     return _read_int(self.addr, "skill") end
function Obj:cart_speed()
    local g = game_ok()
    if g and g.call then local ok, r = pcall(g.call, "GetCartSpeed", self.addr); if ok then return r end end
    return _read_int(self.addr, "skill")
end
function Obj:set_health(v) return _write_int(self.addr, "health", v) end
function Obj:set_owner(v)  return _write_int(self.addr, "owner", v) end
function Obj:set_skill(v)  return _write_int(self.addr, "skill", v) end
function Obj:set_cart_speed(v)
    local g = game_ok()
    if g and g.call then local ok, r = pcall(g.call, "SetCartSpeed", self.addr, v); if ok then print(string.format("unit 0x%08X cart_speed -> %d", self.addr, v)); return r end end
    return _write_int(self.addr, "skill", v)
end
function Obj:cart_capacity()
    local g = game_ok()
    if g and g.call then local ok, r = pcall(g.call, "GetCartCapacity", self.addr); if ok then return r end end
    return _read_int(self.addr, "skill")
end
function Obj:set_cart_capacity(v)
    local g = game_ok()
    if g and g.call then local ok, r = pcall(g.call, "SetCartCapacity", self.addr, v); if ok then print(string.format("unit 0x%08X cart_capacity -> %d", self.addr, v)); return r end end
    return _write_int(self.addr, "skill", v)
end
function Obj:cart_goods(goodId)
    local g = game_ok()
    if g and g.call then local ok, r = pcall(g.call, "GetCartGoods", self.addr, goodId); if ok then return r end end
    error("GetCartGoods not registered or addr not a cart; try inventory.get")
end
function Obj:has_goods(goodId, amount) local g = game_ok(); if g and g.call then local ok, r = pcall(g.call, "HasCartGoods", self.addr, goodId, amount); if ok then return r end end; error("HasCartGoods not registered") end
function Obj:guard_level()
    local g = game_ok()
    if g and g.call then local ok, r = pcall(g.call, "GetCartGuardLevel", self.addr); if ok then return r end end
    error("GetCartGuardLevel not registered; run catalog.hunt unit/building + game.register first")
end
function Obj:caravan_value()
    local g = game_ok()
    if g and g.call then local ok, r = pcall(g.call, "GetCaravanValue", self.addr); if ok then return r end end
    error("GetCaravanValue not registered; run catalog.hunt unit/economy + game.register first")
end

function Obj:pos()
    return self:x(), self:y()
end

function Obj:move(x, y)
    local g = game_ok()
    if not g then error("game not available") end
    -- prefer catalog-registered MoveUnit, else raw field writes
    if g.call then
        local ok, ret = pcall(g.call, "MoveUnit", self.addr, x, y)
        if ok then
            print(string.format("unit 0x%08X move -> (%d,%d) = %s", self.addr, x, y, tostring(ret)))
            return ret
        end
    end
    _write_int(self.addr, "x", x)
    _write_int(self.addr, "y", y)
    return true
end

function Obj:delete()
    local g = game_ok()
    if g and g.call then
        local ok, ret = pcall(g.call, "DeleteUnit", self.addr)
        if ok then print(string.format("unit 0x%08X delete -> %s", self.addr, tostring(ret))); return ret end
    end
    error("DeleteUnit not registered; register via catalog or game.register first")
end

function Obj:name()
    local g = game_ok()
    if not g then error("game not available") end
    local off = M.offsets.name
    local len = M.offsets.name_len or 32
    local d = g.read_mem(self.addr + off, len, "char")
    if not d then return nil end
    local s = require("ffi").string(d, len)
    local z = s:find("\0", 1, true)
    if z then s = s:sub(1, z-1) end
    return s
end

function Obj:dump()
    local str = _G.struct or (pcall(dofile, "lua/struct.lua") and _G.struct)
    if str and str.dump then
        local ok = pcall(str.dump, self.addr, "Unit")
        if not ok then
            pcall(str.dump, self.addr, {
                {name="health", type="int", offset=M.offsets.health},
                {name="owner",  type="int", offset=M.offsets.owner},
                {name="utype",  type="int", offset=M.offsets.utype},
                {name="x",      type="int", offset=M.offsets.x},
                {name="y",      type="int", offset=M.offsets.y},
                {name="skill",  type="int", offset=M.offsets.skill},
                {name="name",   type="char[32]", offset=M.offsets.name},
            })
        end
    else
        print(string.format("unit @ 0x%08X  hp=%s owner=%s type=%s pos=(%s,%s) skill=%s name=%q",
            self.addr,
            tostring(pcall(function() return self:health() end) and self:health() or "?"),
            tostring(pcall(function() return self:owner() end) and self:owner() or "?"),
            tostring(pcall(function() return self:utype() end) and self:utype() or "?"),
            tostring(pcall(function() return self:x() end) and self:x() or "?"),
            tostring(pcall(function() return self:y() end) and self:y() or "?"),
            tostring(pcall(function() return self:skill() end) and self:skill() or "?"),
            tostring(self:name() or "")))
    end
    return self
end


local function call_or_hint(name, ...)
    local g = game_ok()
    if g and g.call then
        local ok, ret = pcall(g.call, name, ...)
        if ok then return ret end
        error(tostring(ret))
    end
    error(name .. " not registered; run unit.find()/catalog.hunt or game.register first")
end

function Obj:worker_count() return call_or_hint("GetWorkerCount", self.addr) end
function Obj:hired_count() return call_or_hint("GetWorkerCount", self.addr) end
function Obj:max_workers() return call_or_hint("GetMaxWorkers", self.addr) end
function Obj:apprentice_count() return call_or_hint("GetApprenticeCount", self.addr) end
function Obj:is_alive() return call_or_hint("IsUnitAlive", self.addr) end
function Obj:type_name()
    local id=self:utype()
    local e=_G.enums or (pcall(dofile,"lua/enums.lua") and _G.enums)
    if e and e.lookup then local ok,n=pcall(e.lookup,"unit",id); if ok and n then return n end end
    return tostring(id)
end
function Obj:skill_level(skillId) return call_or_hint("GetSkillLevel", self.addr, skillId) end
function Obj:set_skill_level(skillId, lvl) local r=call_or_hint("SetSkillLevel", self.addr, skillId, lvl); print(string.format("unit 0x%08X skill[%s]->%s", self.addr, tostring(skillId), tostring(lvl))); return r end
function Obj:worker_skill(workerId) return call_or_hint("GetWorkerSkill", self.addr, workerId) end
function Obj:set_worker_skill(workerId, lvl) local r=call_or_hint("SetWorkerSkill", self.addr, workerId, lvl); print(string.format("unit 0x%08X worker[%s]->%s", self.addr, tostring(workerId), tostring(lvl))); return r end
function Obj:hire(workerType) local r=call_or_hint("HireWorker", self.addr, workerType); print(string.format("hire %s -> 0x%08X %s", tostring(workerType), self.addr, tostring(r))); return r end
function Obj:fire(workerId) local r=call_or_hint("FireWorker", self.addr, workerId); print(string.format("fire %s 0x%08X -> %s", tostring(workerId), self.addr, tostring(r))); return r end

-- static / global helpers
function M.create(utype, x, y) local r=call_or_hint("CreateUnit", utype, x, y); print(string.format("create unit type=%s @%s,%s -> %s", tostring(utype), tostring(x), tostring(y), tostring(r))); return r end
function M.selected() return call_or_hint("GetSelectedUnit") end
function M.at_selected() local p=M.selected(); if not p then print("no selected unit"); return nil end; return M.at(tonumber(require("ffi").cast("uintptr_t", p))) end
function M.master_count(ptr) return call_or_hint("GetMasterCount", ptr or 0) end
function M.family_count(pid) return call_or_hint("GetFamilyMemberCount", pid) end
function M.servant_count(pid) return call_or_hint("GetServantCount", pid) end
function M.assassin_level(pid) return call_or_hint("GetAssassinLevel", pid) end
function M.set_assassin_level(pid, lvl) local r=call_or_hint("SetAssassinLevel", pid, lvl); print(string.format("assassin pid=%s->%s", tostring(pid), tostring(lvl))); return r end


function Obj:health_via_call() return call_or_hint("GetUnitHealth", self.addr) end
function Obj:set_health_via_call(v) local r=call_or_hint("SetUnitHealth", self.addr, v); print(string.format("unit 0x%08X health->%s", self.addr, tostring(v))); return r end
function Obj:pos_x_via_call() return call_or_hint("GetUnitPosX", self.addr) end
function Obj:pos_y_via_call() return call_or_hint("GetUnitPosY", self.addr) end
function Obj:set_pos_x_via_call(v) local r=call_or_hint("SetUnitPosX", self.addr, v); print(string.format("unit 0x%08X posX->%s", self.addr, tostring(v))); return r end
function Obj:set_pos_y_via_call(v) local r=call_or_hint("SetUnitPosY", self.addr, v); print(string.format("unit 0x%08X posY->%s", self.addr, tostring(v))); return r end
function Obj:owner_via_call() return call_or_hint("GetUnitOwner", self.addr) end
function Obj:type_via_call() return call_or_hint("GetUnitType", self.addr) end
function Obj:set_type_via_call(v) local r=call_or_hint("SetUnitType", self.addr, v); print(string.format("unit 0x%08X type->%s", self.addr, tostring(v))); return r end
function Obj:name_via_call() return call_or_hint("GetUnitName", self.addr) end

function M.at(addr)
    addr = to_addr(addr)
    return setmetatable({ addr = addr }, Obj)
end

return M
