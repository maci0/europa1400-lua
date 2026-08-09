-- Europa 1400 - City Helper
--
-- High-level wrapper for city / treasury / building-economy targets.
-- Mirrors player.lua: wraps raw game.read_mem/write_mem + preset flows
-- behind `city.*` so catalog world/economy entries can be triaged quickly.
--
--   city = dofile('lua/city.lua')  -- or already `city`
--   city.find()                       -- catalog.hunt("world") helper
--   city.scan(0x00400000, 0x300000)   -- preset hunt for city strings
--   city.at(0x12340000):gold()        -- read treasury
--   city.at(0x12340000):set_gold(9999)
--   city.at(0x12340000):dump()        -- struct-aware dump
--
-- Offsets below are defaults (0/4/8/12) — calibrate via struct.dump
-- or catalog once the real city struct is reversed. Override via
--   city.offsets.gold = 0x10

local M = {}

-- default field offsets (placeholder — refine per build)
M.offsets = {
    population = 0,
    happiness  = 4,
    gold       = 8,
    owner      = 12,
    -- name is char[32] at +16 if present
    name       = 16,
    name_len   = 32,
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
    print(string.format("city.scan [0x%08X +0x%X]", base, size))
    local presets = _G.presets or (pcall(dofile, "lua/presets.lua") and _G.presets)
    if presets and presets.hunt then
        local hits = presets.hunt("city", base, size) or {}
        if #hits > 0 then
            print(string.format("city.scan: %d preset hit(s), try city.at(hits[1])", #hits))
            return hits
        end
    end
    print("city.scan: no hits; try city.find() or wider base/size")
    return {}
end

function M.find(base, size)
    local cat = _G.catalog or (pcall(dofile, "lua/catalog.lua") and _G.catalog)
    if not cat or not cat.hunt then error("catalog not available") end
    -- world tag covers GetCityOwner/SetCityOwner/IsCityBesieged etc.
    local out = cat.hunt("world", base, size)
    if #out == 0 then out = cat.hunt("city", base, size) end
    return out
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
    print(string.format("city 0x%08X %s -> %d", addr, field, v))
    return true
end

function Obj:population() return _read_int(self.addr, "population") end
function Obj:set_population(v) return _write_int(self.addr, "population", v) end
function Obj:happiness() return _read_int(self.addr, "happiness") end
function Obj:set_happiness(v) return _write_int(self.addr, "happiness", v) end
function Obj:gold() return _read_int(self.addr, "gold") end
function Obj:set_gold(v) return _write_int(self.addr, "gold", v) end
function Obj:owner() return _read_int(self.addr, "owner") end
function Obj:set_owner(v) return _write_int(self.addr, "owner", v) end

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
        local ok = pcall(str.dump, self.addr, "City")
        if not ok then
            pcall(str.dump, self.addr, {
                {name="population", type="int", offset=M.offsets.population},
                {name="happiness",  type="int", offset=M.offsets.happiness},
                {name="gold",       type="int", offset=M.offsets.gold},
                {name="owner",      type="int", offset=M.offsets.owner},
                {name="name",       type="char[32]", offset=M.offsets.name},
            })
        end
    else
        print(string.format("city @ 0x%08X  pop=%s happy=%s gold=%s owner=%s name=%q",
            self.addr,
            tostring(pcall(function() return self:population() end) and self:population() or "?"),
            tostring(pcall(function() return self:happiness() end) and self:happiness() or "?"),
            tostring(pcall(function() return self:gold() end) and self:gold() or "?"),
            tostring(pcall(function() return self:owner() end) and self:owner() or "?"),
            tostring(self:name() or "")))
    end
    return self
end


local function call_world(name, ...)
    local w = _G.world or (pcall(dofile, "lua/world.lua") and _G.world)
    if w and w[name] then
        local ok, r = pcall(w[name], w, ...)
        if ok then return r end
    end
    -- fallback to game.call hint with matching GetCity* name (capitalize underscore)
    local g = game_ok()
    if g and g.call then
        local catalog_map = {
            rank="GetCityRank", prestige="GetCityPrestige", favor="GetCityFavor",
            defense="GetCityDefense", unrest="GetCityUnrest", corruption="GetCityCorruption",
            stability="GetCityStability", food="GetCityFoodSupply", festival="GetFestivalState",
            fair="GetCityFairState", growth="GetCityGrowthRate", toll="GetCityTollGateCount",
            wall="GetCityWallHealth", market_fee="GetCityMarketFee", stalls="GetCityMarketStallCount",
            tax_rate="GetCityTaxRate", tax_income="GetCityTaxIncome", harbor="GetCityHarborLevel",
        }
        -- handled below via explicit per-method; this is just for error path
    end
    error(name .. " not registered; run world.find()/catalog.hunt")
end

function Obj:rank()            local w=_G.world or (pcall(dofile,"lua/world.lua") and _G.world); if w and w.city_rank then local ok,r=pcall(w.city_rank,  self.addr); if ok then return r end end; return call_world("GetCityRank", self.addr) end
function Obj:prestige()        local w=_G.world or (pcall(dofile,"lua/world.lua") and _G.world); if w and w.city_prestige then local ok,r=pcall(w.city_prestige,self.addr); if ok then return r end end; return nil end
function Obj:favor(pid)        local w=_G.world or (pcall(dofile,"lua/world.lua") and _G.world); if w and w.city_favor then local ok,r=pcall(w.city_favor,self.addr,pid); if ok then return r end end; return nil end
function Obj:wall_health()     local w=_G.world or (pcall(dofile,"lua/world.lua") and _G.world); if w and w.wall_health then local ok,r=pcall(w.wall_health,self.addr); if ok then return r end end; return nil end
function Obj:unrest()          local w=_G.world or (pcall(dofile,"lua/world.lua") and _G.world); if w and w.unrest then local ok,r=pcall(w.unrest,self.addr); if ok then return r end end; return nil end
function Obj:defense()         local w=_G.world or (pcall(dofile,"lua/world.lua") and _G.world); if w and w.city_defense then local ok,r=pcall(w.city_defense,self.addr); if ok then return r end end; return nil end
function Obj:corruption()      local w=_G.world or (pcall(dofile,"lua/world.lua") and _G.world); if w and w.city_corruption then local ok,r=pcall(w.city_corruption,self.addr); if ok then return r end end; return nil end
function Obj:stability()       local w=_G.world or (pcall(dofile,"lua/world.lua") and _G.world); if w and w.city_stability then local ok,r=pcall(w.city_stability,self.addr); if ok then return r end end; return nil end
function Obj:food()            local w=_G.world or (pcall(dofile,"lua/world.lua") and _G.world); if w and w.food then local ok,r=pcall(w.food,self.addr); if ok then return r end end; return nil end
function Obj:festival_state()  local w=_G.world or (pcall(dofile,"lua/world.lua") and _G.world); if w and w.festival then local ok,r=pcall(w.festival,self.addr); if ok then return r end end; return nil end

-- static helpers mirroring world but discoverable via city.*
function M.rank(cityId)         local w=_G.world or (pcall(dofile,"lua/world.lua") and _G.world); if w and w.city_rank then return w.city_rank(cityId) end end
function M.prestige(cityId)     local w=_G.world or (pcall(dofile,"lua/world.lua") and _G.world); if w and w.city_prestige then return w.city_prestige(cityId) end end
function M.favor(cityId,pid)    local w=_G.world or (pcall(dofile,"lua/world.lua") and _G.world); if w and w.city_favor then return w.city_favor(cityId,pid) end end
function M.wall_health(cityId)  local w=_G.world or (pcall(dofile,"lua/world.lua") and _G.world); if w and w.wall_health then return w.wall_health(cityId) end end
function M.unrest(cityId)       local w=_G.world or (pcall(dofile,"lua/world.lua") and _G.world); if w and w.unrest then return w.unrest(cityId) end end
function M.defense(cityId)      local w=_G.world or (pcall(dofile,"lua/world.lua") and _G.world); if w and w.city_defense then return w.city_defense(cityId) end end

function M.at(addr)
    addr = to_addr(addr)
    return setmetatable({ addr = addr }, Obj)
end


function M.gold_via_call(cityId) return call_world("GetCityGold", cityId) end
function M.set_gold_via_call(cityId, v) local w=_G.world or (pcall(dofile,"lua/world.lua") and _G.world); if w and w.set_city_gold then return w.set_city_gold(cityId,v) end; return call_world("SetCityGold", cityId, v) end
function M.happiness_via_call(cityId) return call_world("GetCityHappiness", cityId) end
function M.set_happiness_via_call(cityId, v) local w=_G.world or (pcall(dofile,"lua/world.lua") and _G.world); if w and w.set_city_happiness then return w.set_city_happiness(cityId,v) end; return call_world("SetCityHappiness", cityId, v) end


return M
