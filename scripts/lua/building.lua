-- Europa 1400 - Building Helper
--
-- High-level wrapper for workshop / warehouse / building-economy targets.
-- Mirrors city.lua/player.lua: wraps game.read_mem/write_mem + preset flows
-- behind `building.*` so catalog building/economy entries triage quickly.
--
--   building = require("building")  -- or already `building`
--   building.find()                          -- catalog.hunt("building") helper
--   building.scan(0x00400000, 0x300000)      -- preset hunt for building strings
--   building.at(0x12340000):level()          -- read building level
--   building.at(0x12340000):set_owner(2)
--   building.at(0x12340000):dump()
--
-- Offsets below are defaults; calibrate via struct.dump once the real
-- building struct is reversed. Override via  building.offsets.level = 0x10

local M = {}

local game = require("gamecalls")

local function call_or_hint(name, ...)
    if not game.get_address(name) then
        error(name .. " not registered; run building.find() / catalog.hunt or game.register first", 2)
    end
    local ok, ret = pcall(game.call, name, ...)
    if ok then return ret end
    error(tostring(ret), 0)
end

M.offsets = {
    level       = 0,
    owner       = 4,
    btype       = 8,   -- building type id
    workers     = 12,
    max_workers = 16,
    output      = 20,
    -- 4-byte gap at 24 for alignment in some builds
    durability  = 28,
    income      = 32,
    efficiency  = 36,
    morale      = 40,
    upkeep      = 48,
    -- name char[32] at +52 if present (shifted when upkeep present)
    name        = 52,
    name_len    = 32,
}

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
    print(string.format("building.scan [0x%08X +0x%X]", base, size))
    local presets = require("presets")
    if presets and presets.hunt then
        local hits = presets.hunt("building", base, size) or {}
        if #hits > 0 then
            print(string.format("building.scan: %d preset hit(s), try building.at(hits[1])", #hits))
            return hits
        end
    end
    print("building.scan: no hits; try building.find() or wider base/size")
    return {}
end

function M.find(base, size)
    local cat = require("catalog")
    if not cat or not cat.hunt then error("catalog not available") end
    return cat.hunt("building", base, size)
end

local Obj = {}
Obj.__index = Obj

local function _read_int(addr, field)
    local g = game
    if not g then error("game not available") end
    local off = M.offsets[field]
    if off == nil then error("unknown offset: " .. tostring(field)) end
    local d = g.read_mem(addr + off, 4, "int")
    if not d then error(string.format("%s read failed at 0x%08X", field, addr + off)) end
    return d[0]
end

local function _write_int(addr, field, v)
    if type(v) ~= "number" then error(field .. " must be number") end
    local g = game
    if not g then error("game not available") end
    local off = M.offsets[field]
    if off == nil then error("unknown offset: " .. tostring(field)) end
    local ffi = require("ffi")
    local p = ffi.new("int[1]", v)
    local ok = g.write_mem(addr + off, p, 4)
    if not ok then error("write failed: " .. field) end
    print(string.format("building 0x%08X %s -> %d", addr, field, v))
    return true
end

function Obj:level()       return _read_int(self.addr, "level") end
function Obj:owner()       return _read_int(self.addr, "owner") end
function Obj:btype()       return _read_int(self.addr, "btype") end
function Obj:workers()     return _read_int(self.addr, "workers") end
function Obj:max_workers() return _read_int(self.addr, "max_workers") end
function Obj:output()      return _read_int(self.addr, "output") end
function Obj:durability()  return _read_int(self.addr, "durability") end
function Obj:income()      return _read_int(self.addr, "income") end
function Obj:efficiency()  return _read_int(self.addr, "efficiency") end
function Obj:morale()      return _read_int(self.addr, "morale") end
function Obj:upkeep()      return _read_int(self.addr, "upkeep") end
function Obj:set_level(v)       return _write_int(self.addr, "level", v) end
function Obj:set_owner(v)       return _write_int(self.addr, "owner", v) end
function Obj:set_workers(v)     return _write_int(self.addr, "workers", v) end
function Obj:set_output(v)      return _write_int(self.addr, "output", v) end
function Obj:set_durability(v)  return _write_int(self.addr, "durability", v) end
function Obj:set_income(v)      return _write_int(self.addr, "income", v) end
function Obj:set_efficiency(v)  return _write_int(self.addr, "efficiency", v) end
function Obj:set_morale(v)      return _write_int(self.addr, "morale", v) end
function Obj:set_upkeep(v)      return _write_int(self.addr, "upkeep", v) end
function Obj:capacity()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetWarehouseCapacity", self.addr); if ok then return r end end
    return _read_int(self.addr, "morale")
end
function Obj:set_capacity(v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetWarehouseCapacity", self.addr, v); if ok then print(string.format("building 0x%08X capacity -> %d", self.addr, v)); return r end end
    return _write_int(self.addr, "morale", v)
end
function Obj:upkeep_via_call()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetBuildingUpkeep", self.addr); if ok then return r end end
    return self:upkeep()
end
function Obj:set_upkeep_via_call(v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetBuildingUpkeep", self.addr, v); if ok then print(string.format("building 0x%08X upkeep -> %d", self.addr, v)); return r end end
    return self:set_upkeep(v)
end
function Obj:harvest(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetHarvestYield", self.addr, goodId); if ok then return r end end
    error("GetHarvestYield not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_harvest(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetHarvestYield", self.addr, goodId, v); if ok then print(string.format("building 0x%08X harvest good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetHarvestYield not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:servants()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetServantCount", self.addr); if ok then return r end end
    error("GetServantCount not registered; run catalog.hunt building + game.register first")
end
function Obj:slots()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetWorkshopSlots", self.addr); if ok then return r end end
    error("GetWorkshopSlots not registered; run catalog.hunt building + game.register first")
end
function Obj:rent()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetBuildingRent", self.addr); if ok then return r end end
    error("GetBuildingRent not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_rent(v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetBuildingRent", self.addr, v); if ok then print(string.format("building 0x%08X rent -> %d", self.addr, v)); return r end end
    error("SetBuildingRent not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:security()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetBuildingSecurity", self.addr); if ok then return r end end
    error("GetBuildingSecurity not registered; run catalog.hunt building + game.register first")
end
function Obj:bvalue()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetBuildingValue", self.addr); if ok then return r end end
    error("GetBuildingValue not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:blessing()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetBuildingBlessing", self.addr); if ok then return r end end
    error("GetBuildingBlessing not registered; run catalog.hunt building/world + game.register first")
end
function Obj:set_blessing(v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetBuildingBlessing", self.addr, v); if ok then print(string.format("building 0x%08X blessing -> %s", self.addr, tostring(v))); return r end end
    error("SetBuildingBlessing not registered; run catalog.hunt building/world + game.register first")
end
function Obj:accident()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetAccidentChance", self.addr); if ok then return r end end
    error("GetAccidentChance not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_accident(v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetAccidentChance", self.addr, v); if ok then print(string.format("building 0x%08X accident -> %s", self.addr, tostring(v))); return r end end
    error("SetAccidentChance not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:fire_risk()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetWorkshopFireRisk", self.addr); if ok then return r end end
    error("GetWorkshopFireRisk not registered; run catalog.hunt building/world + game.register first")
end
function Obj:strikes()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetWorkshopStrikes", self.addr); if ok then return r end end
    error("GetWorkshopStrikes not registered; run catalog.hunt building/world + game.register first")
end
function Obj:prod_bonus(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetProductionBonus", self.addr, goodId); if ok then return r end end
    error("GetProductionBonus not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_prod_bonus(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetProductionBonus", self.addr, goodId, v); if ok then print(string.format("building 0x%08X bonus good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetProductionBonus not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:btax_rate()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetBuildingTaxRate", self.addr); if ok then return r end end
    error("GetBuildingTaxRate not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_btax_rate(v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetBuildingTaxRate", self.addr, v); if ok then print(string.format("building 0x%08X btax_rate -> %s", self.addr, tostring(v))); return r end end
    error("SetBuildingTaxRate not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:apprentice_slots()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetWorkshopApprenticeSlots", self.addr); if ok then return r end end
    error("GetWorkshopApprenticeSlots not registered; run catalog.hunt building/world + game.register first")
end
function Obj:granary_cap()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetGranaryCapacity", self.addr); if ok then return r end end
    error("GetGranaryCapacity not registered; run catalog.hunt building/world + game.register first")
end
function Obj:baker_bonus(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetBakerOutputBonus", self.addr, goodId); if ok then return r end end
    error("GetBakerOutputBonus not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_baker_bonus(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetBakerOutputBonus", self.addr, goodId, v); if ok then print(string.format("building 0x%08X baker good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetBakerOutputBonus not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:master_bribe()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetMasterBribeCost", self.addr); if ok then return r end end
    error("GetMasterBribeCost not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:brewery_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetBreweryOutput", self.addr, goodId); if ok then return r end end
    error("GetBreweryOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_brewery_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetBreweryOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X brewery good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetBreweryOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:upgrade_cost(upgradeId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetWorkshopUpgradeCost", self.addr, upgradeId); if ok then return r end end
    error("GetWorkshopUpgradeCost not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:mill_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetMillOutput", self.addr, goodId); if ok then return r end end
    error("GetMillOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_mill_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetMillOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X mill good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetMillOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:blacksmith_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetBlacksmithOutput", self.addr, goodId); if ok then return r end end
    error("GetBlacksmithOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_blacksmith_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetBlacksmithOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X blacksmith good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetBlacksmithOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:tannery_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetTanneryOutput", self.addr, goodId); if ok then return r end end
    error("GetTanneryOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_tannery_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetTanneryOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X tannery good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetTanneryOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:weaver_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetWeaverOutput", self.addr, goodId); if ok then return r end end
    error("GetWeaverOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_weaver_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetWeaverOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X weaver good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetWeaverOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:mint_profit()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetMintProfit", self.addr); if ok then return r end end
    error("GetMintProfit not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:herb_yield(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetHerbGardenYield", self.addr, goodId); if ok then return r end end
    error("GetHerbGardenYield not registered; run catalog.hunt building/world + game.register first")
end
function Obj:vineyard_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetVineyardOutput", self.addr, goodId); if ok then return r end end
    error("GetVineyardOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_vineyard_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetVineyardOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X vineyard good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetVineyardOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:pottery_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetPotteryOutput", self.addr, goodId); if ok then return r end end
    error("GetPotteryOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_pottery_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetPotteryOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X pottery good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetPotteryOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:tailor_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetTailorOutput", self.addr, goodId); if ok then return r end end
    error("GetTailorOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_tailor_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetTailorOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X tailor good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetTailorOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:fishing_yield(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetFishingYield", self.addr, goodId); if ok then return r end end
    error("GetFishingYield not registered; run catalog.hunt building/world + game.register first")
end
function Obj:orchard_yield(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetOrchardYield", self.addr, goodId); if ok then return r end end
    error("GetOrchardYield not registered; run catalog.hunt building/world + game.register first")
end
function Obj:carpenter_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetCarpenterOutput", self.addr, goodId); if ok then return r end end
    error("GetCarpenterOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_carpenter_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetCarpenterOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X carpenter good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetCarpenterOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:ropemaker_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetRopemakerOutput", self.addr, goodId); if ok then return r end end
    error("GetRopemakerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_ropemaker_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetRopemakerOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X rope good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetRopemakerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:apiary_yield(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetApiaryYield", self.addr, goodId); if ok then return r end end
    error("GetApiaryYield not registered; run catalog.hunt building/world + game.register first")
end
function Obj:hunting_yield(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetHuntingYield", self.addr, goodId); if ok then return r end end
    error("GetHuntingYield not registered; run catalog.hunt building/world + game.register first")
end
function Obj:alchemist_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetAlchemistOutput", self.addr, goodId); if ok then return r end end
    error("GetAlchemistOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_alchemist_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetAlchemistOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X alchemist good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetAlchemistOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:glassworks_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetGlassworksOutput", self.addr, goodId); if ok then return r end end
    error("GetGlassworksOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_glassworks_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetGlassworksOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X glassworks good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetGlassworksOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:mason_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetMasonOutput", self.addr, goodId); if ok then return r end end
    error("GetMasonOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_mason_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetMasonOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X mason good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetMasonOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:distillery_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetDistilleryOutput", self.addr, goodId); if ok then return r end end
    error("GetDistilleryOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_distillery_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetDistilleryOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X distillery good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetDistilleryOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:pasture_yield(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetPastureYield", self.addr, goodId); if ok then return r end end
    error("GetPastureYield not registered; run catalog.hunt building/world + game.register first")
end
function Obj:quarry_yield(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetQuarryYield", self.addr, goodId); if ok then return r end end
    error("GetQuarryYield not registered; run catalog.hunt building/world + game.register first")
end
function Obj:forge_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetForgeOutput", self.addr, goodId); if ok then return r end end
    error("GetForgeOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_forge_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetForgeOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X forge good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetForgeOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:sawmill_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetSawmillOutput", self.addr, goodId); if ok then return r end end
    error("GetSawmillOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_sawmill_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetSawmillOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X sawmill good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetSawmillOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:kiln_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetKilnOutput", self.addr, goodId); if ok then return r end end
    error("GetKilnOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_kiln_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetKilnOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X kiln good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetKilnOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:foundry_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetFoundryOutput", self.addr, goodId); if ok then return r end end
    error("GetFoundryOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_foundry_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetFoundryOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X foundry good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetFoundryOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:hospital_cap()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetHospitalCapacity", self.addr); if ok then return r end end
    error("GetHospitalCapacity not registered; run catalog.hunt building/world + game.register first")
end
function Obj:tavern_income()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetTavernIncome", self.addr); if ok then return r end end
    error("GetTavernIncome not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:apothecary_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetApothecaryOutput", self.addr, goodId); if ok then return r end end
    error("GetApothecaryOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_apothecary_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetApothecaryOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X apothecary good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetApothecaryOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:scribe_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetScribeOutput", self.addr, goodId); if ok then return r end end
    error("GetScribeOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_scribe_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetScribeOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X scribe good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetScribeOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:goldsmith_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetGoldsmithOutput", self.addr, goodId); if ok then return r end end
    error("GetGoldsmithOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:falconer_yield(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetFalconerYield", self.addr, goodId); if ok then return r end end
    error("GetFalconerYield not registered; run catalog.hunt building/world + game.register first")
end
function Obj:jeweler_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetJewelerOutput", self.addr, goodId); if ok then return r end end
    error("GetJewelerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_jeweler_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetJewelerOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X jeweler good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetJewelerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:bathhouse_income()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetBathhouseIncome", self.addr); if ok then return r end end
    error("GetBathhouseIncome not registered; run catalog.hunt building/economy + game.register first")
end

function Obj:perfumer_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetPerfumerOutput", self.addr, goodId); if ok then return r end end
    error("GetPerfumerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_perfumer_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetPerfumerOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X perfumer good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetPerfumerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:soapmaker_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetSoapmakerOutput", self.addr, goodId); if ok then return r end end
    error("GetSoapmakerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_soapmaker_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetSoapmakerOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X soap good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetSoapmakerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:candlemaker_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetCandlemakerOutput", self.addr, goodId); if ok then return r end end
    error("GetCandlemakerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_candlemaker_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetCandlemakerOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X candle good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetCandlemakerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:papermill_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetPapermillOutput", self.addr, goodId); if ok then return r end end
    error("GetPapermillOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_papermill_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetPapermillOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X paper good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetPapermillOutput not registered; run catalog.hunt building/economy + game.register first")
end

function Obj:printing_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetPrintingOutput", self.addr, goodId); if ok then return r end end
    error("GetPrintingOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_printing_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetPrintingOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X printing good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetPrintingOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:toolmaker_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetToolmakerOutput", self.addr, goodId); if ok then return r end end
    error("GetToolmakerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_toolmaker_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetToolmakerOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X toolmaker good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetToolmakerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:charcoal_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetCharcoalOutput", self.addr, goodId); if ok then return r end end
    error("GetCharcoalOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_charcoal_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetCharcoalOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X charcoal good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetCharcoalOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:furrier_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetFurrierOutput", self.addr, goodId); if ok then return r end end
    error("GetFurrierOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_furrier_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetFurrierOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X furrier good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetFurrierOutput not registered; run catalog.hunt building/economy + game.register first")
end

function Obj:dyer_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetDyerOutput", self.addr, goodId); if ok then return r end end
    error("GetDyerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_dyer_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetDyerOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X dyer good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetDyerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:saddler_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetSaddlerOutput", self.addr, goodId); if ok then return r end end
    error("GetSaddlerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_saddler_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetSaddlerOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X saddler good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetSaddlerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:armorer_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetArmorerOutput", self.addr, goodId); if ok then return r end end
    error("GetArmorerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_armorer_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetArmorerOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X armorer good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetArmorerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:bowyer_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetBowyerOutput", self.addr, goodId); if ok then return r end end
    error("GetBowyerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_bowyer_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetBowyerOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X bowyer good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetBowyerOutput not registered; run catalog.hunt building/economy + game.register first")
end

function Obj:cartwright_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetCartwrightOutput", self.addr, goodId); if ok then return r end end
    error("GetCartwrightOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_cartwright_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetCartwrightOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X cartwright good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetCartwrightOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:mint_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetMintOutput", self.addr, goodId); if ok then return r end end
    error("GetMintOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_mint_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetMintOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X mint_out good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetMintOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:winery_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetWineryOutput", self.addr, goodId); if ok then return r end end
    error("GetWineryOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_winery_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetWineryOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X winery good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetWineryOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:shipwright_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetShipwrightOutput", self.addr, goodId); if ok then return r end end
    error("GetShipwrightOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_shipwright_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetShipwrightOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X shipwright good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetShipwrightOutput not registered; run catalog.hunt building/economy + game.register first")
end

function Obj:cooper_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetCooperOutput", self.addr, goodId); if ok then return r end end
    error("GetCooperOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_cooper_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetCooperOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X cooper good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetCooperOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:spinner_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetSpinnerOutput", self.addr, goodId); if ok then return r end end
    error("GetSpinnerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_spinner_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetSpinnerOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X spinner good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetSpinnerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:turner_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetTurnerOutput", self.addr, goodId); if ok then return r end end
    error("GetTurnerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_turner_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetTurnerOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X turner good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetTurnerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:barber_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetBarberOutput", self.addr, goodId); if ok then return r end end
    error("GetBarberOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_barber_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetBarberOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X barber good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetBarberOutput not registered; run catalog.hunt building/economy + game.register first")
end

function Obj:stonecutter_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetStonecutterOutput", self.addr, goodId); if ok then return r end end
    error("GetStonecutterOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_stonecutter_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetStonecutterOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X stonecutter good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetStonecutterOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:tailor_master_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetTailorMasterOutput", self.addr, goodId); if ok then return r end end
    error("GetTailorMasterOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_tailor_master_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetTailorMasterOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X tailormaster good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetTailorMasterOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:cobbler_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetCobblerOutput", self.addr, goodId); if ok then return r end end
    error("GetCobblerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_cobbler_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetCobblerOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X cobbler good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetCobblerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:butcher_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetButcherOutput", self.addr, goodId); if ok then return r end end
    error("GetButcherOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_butcher_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetButcherOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X butcher good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetButcherOutput not registered; run catalog.hunt building/economy + game.register first")
end

function Obj:baker2_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetBakerOutput2", self.addr, goodId); if ok then return r end end
    error("GetBakerOutput2 not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_baker2_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetBakerOutput2", self.addr, goodId, v); if ok then print(string.format("building 0x%08X baker2 good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetBakerOutput2 not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:shepherd_yield(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetShepherdYield", self.addr, goodId); if ok then return r end end
    error("GetShepherdYield not registered; run catalog.hunt building/world + game.register first")
end
function Obj:dairy_yield(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetDairyYield", self.addr, goodId); if ok then return r end end
    error("GetDairyYield not registered; run catalog.hunt building/world + game.register first")
end
function Obj:brewmaster_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetBrewmasterOutput", self.addr, goodId); if ok then return r end end
    error("GetBrewmasterOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_brewmaster_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetBrewmasterOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X brewmaster good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetBrewmasterOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:miller_yield(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetMillerYield", self.addr, goodId); if ok then return r end end
    error("GetMillerYield not registered; run catalog.hunt building/world + game.register first")
end
function Obj:fishery_yield(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetFisheryYield", self.addr, goodId); if ok then return r end end
    error("GetFisheryYield not registered; run catalog.hunt building/world + game.register first")
end

function Obj:chandler_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetChandlerOutput", self.addr, goodId); if ok then return r end end
    error("GetChandlerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_chandler_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetChandlerOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X chandler good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetChandlerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:goldbeater_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetGoldbeaterOutput", self.addr, goodId); if ok then return r end end
    error("GetGoldbeaterOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_goldbeater_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetGoldbeaterOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X goldbeater good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetGoldbeaterOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:potter_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetPotterOutput", self.addr, goodId); if ok then return r end end
    error("GetPotterOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_potter_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetPotterOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X potter good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetPotterOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:fowler_yield(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetFowlerYield", self.addr, goodId); if ok then return r end end
    error("GetFowlerYield not registered; run catalog.hunt building/world + game.register first")
end
function Obj:vintner_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetVintnerOutput", self.addr, goodId); if ok then return r end end
    error("GetVintnerOutput not registered; run catalog.hunt building/economy + game.register first")
end

function Obj:distiller_yield(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetDistillerYield", self.addr, goodId); if ok then return r end end
    error("GetDistillerYield not registered; run catalog.hunt building/world + game.register first")
end
function Obj:cook_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetCookOutput", self.addr, goodId); if ok then return r end end
    error("GetCookOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_cook_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetCookOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X cook good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetCookOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:brickmaker_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetBrickmakerOutput", self.addr, goodId); if ok then return r end end
    error("GetBrickmakerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_brickmaker_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetBrickmakerOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X brick good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetBrickmakerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:chandler_yield(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetChandlerYield", self.addr, goodId); if ok then return r end end
    error("GetChandlerYield not registered; run catalog.hunt building/world + game.register first")
end
function Obj:inn_income()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetInnIncome", self.addr); if ok then return r end end
    error("GetInnIncome not registered; run catalog.hunt building/economy + game.register first")
end

function Obj:joiner_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetJoinerOutput", self.addr, goodId); if ok then return r end end
    error("GetJoinerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_joiner_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetJoinerOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X joiner good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetJoinerOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:carter_output(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetCarterOutput", self.addr, goodId); if ok then return r end end
    error("GetCarterOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:set_carter_output(goodId, v)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "SetCarterOutput", self.addr, goodId, v); if ok then print(string.format("building 0x%08X carter good=%s -> %s", self.addr, tostring(goodId), tostring(v))); return r end end
    error("SetCarterOutput not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:mining_yield(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetMiningYield", self.addr, goodId); if ok then return r end end
    error("GetMiningYield not registered; run catalog.hunt building/world + game.register first")
end
function Obj:logging_yield(goodId)
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetLoggingYield", self.addr, goodId); if ok then return r end end
    error("GetLoggingYield not registered; run catalog.hunt building/world + game.register first")
end
function Obj:innkeeper_income()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetInnkeeperIncome", self.addr); if ok then return r end end
    error("GetInnkeeperIncome not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:tollmaster_income()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "GetTollMasterIncome", self.addr); if ok then return r end end
    error("GetTollMasterIncome not registered; run catalog.hunt building/economy + game.register first")
end
function Obj:is_running()
    local g = game
    if g and g.call then local ok, r = pcall(g.call, "IsWorkshopRunning", self.addr); if ok then return r end end
    return _read_int(self.addr, "output") ~= 0 and 1 or 0
end

function Obj:name()
    local g = game
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

function Obj:upgrade()
    local g = game
    if not g then error("game not available") end
    -- try catalog-registered UpgradeBuilding first, else bump level field
    if g.call then
        local ok, ret = pcall(g.call, "UpgradeBuilding", self.addr)
        if ok then
            print(string.format("building 0x%08X upgrade -> %s", self.addr, tostring(ret)))
            return ret
        end
    end
    return self:set_level(self:level() + 1)
end

function Obj:dump()
    local str = require("struct")
    if str and str.dump then
        local ok = pcall(str.dump, self.addr, "Building")
        if not ok then
            pcall(str.dump, self.addr, {
                {name="level",       type="int", offset=M.offsets.level},
                {name="owner",       type="int", offset=M.offsets.owner},
                {name="btype",       type="int", offset=M.offsets.btype},
                {name="workers",     type="int", offset=M.offsets.workers},
                {name="max_workers", type="int", offset=M.offsets.max_workers},
                {name="output",      type="int", offset=M.offsets.output},
                {name="durability",  type="int", offset=M.offsets.durability},
                {name="income",      type="int", offset=M.offsets.income},
                {name="efficiency",  type="int", offset=M.offsets.efficiency},
                {name="morale",      type="int", offset=M.offsets.morale},
                {name="upkeep",      type="int", offset=M.offsets.upkeep},
                {name="name",        type="char[32]", offset=M.offsets.name},
            })
        end
    else
        print(string.format("building @ 0x%08X  level=%s owner=%s type=%s workers=%s/%s output=%s dura=%s income=%s eff=%s morale=%s upkeep=%s name=%q",
            self.addr,
            tostring(pcall(function() return self:level() end) and self:level() or "?"),
            tostring(pcall(function() return self:owner() end) and self:owner() or "?"),
            tostring(pcall(function() return self:btype() end) and self:btype() or "?"),
            tostring(pcall(function() return self:workers() end) and self:workers() or "?"),
            tostring(pcall(function() return self:max_workers() end) and self:max_workers() or "?"),
            tostring(pcall(function() return self:output() end) and self:output() or "?"),
            tostring(pcall(function() return self:durability() end) and self:durability() or "?"),
            tostring(pcall(function() return self:income() end) and self:income() or "?"),
            tostring(pcall(function() return self:efficiency() end) and self:efficiency() or "?"),
            tostring(pcall(function() return self:morale() end) and self:morale() or "?"),
            tostring(pcall(function() return self:upkeep() end) and self:upkeep() or "?"),
            tostring(self:name() or "")))
    end
    return self
end

function M.building_level(ptr) return call_or_hint("GetBuildingLevel", ptr) end
function M.set_building_level(ptr, v) local r=call_or_hint("SetBuildingLevel", ptr, v); print(string.format("set_building_level %s -> %s", tostring(ptr), tostring(v))); return r end
function M.building_output(ptr) return call_or_hint("GetBuildingOutput", ptr) end
function M.set_building_output(ptr, v) local r=call_or_hint("SetBuildingOutput", ptr, v); print(string.format("set_building_output %s -> %s", tostring(ptr), tostring(v))); return r end
function M.durability(ptr) return call_or_hint("GetBuildingDurability", ptr) end
function M.set_durability(ptr, v) local r=call_or_hint("SetBuildingDurability", ptr, v); print(string.format("set_durability %s -> %s", tostring(ptr), tostring(v))); return r end
function M.income(ptr) return call_or_hint("GetBuildingIncome", ptr) end
function M.set_income(ptr, v) local r=call_or_hint("SetBuildingIncome", ptr, v); print(string.format("set_income %s -> %s", tostring(ptr), tostring(v))); return r end
function M.upkeep(ptr) return call_or_hint("GetBuildingUpkeep", ptr) end
function M.set_upkeep(ptr, v) local r=call_or_hint("SetBuildingUpkeep", ptr, v); print(string.format("set_upkeep %s -> %s", tostring(ptr), tostring(v))); return r end
function M.tax(ptr) return call_or_hint("GetBuildingTax", ptr) end
function M.set_tax(ptr, v) local r=call_or_hint("SetBuildingTax", ptr, v); print(string.format("set_tax %s -> %s", tostring(ptr), tostring(v))); return r end
function M.tax_rate(ptr) return call_or_hint("GetBuildingTaxRate", ptr) end
function M.set_tax_rate(ptr, v) local r=call_or_hint("SetBuildingTaxRate", ptr, v); print(string.format("set_tax_rate %s -> %s", tostring(ptr), tostring(v))); return r end
function M.rent(ptr) return call_or_hint("GetBuildingRent", ptr) end
function M.set_rent(ptr, v) local r=call_or_hint("SetBuildingRent", ptr, v); print(string.format("set_rent %s -> %s", tostring(ptr), tostring(v))); return r end
function M.security(ptr) return call_or_hint("GetBuildingSecurity", ptr) end
function M.value(ptr) return call_or_hint("GetBuildingValue", ptr) end
function M.blessing(ptr) return call_or_hint("GetBuildingBlessing", ptr) end
function M.set_blessing(ptr, v) local r=call_or_hint("SetBuildingBlessing", ptr, v); print(string.format("set_blessing %s -> %s", tostring(ptr), tostring(v))); return r end
function M.owner(ptr) return call_or_hint("GetBuildingOwner", ptr) end
function M.set_owner(ptr, v) local r=call_or_hint("SetBuildingOwner", ptr, v); print(string.format("set_owner %s -> %s", tostring(ptr), tostring(v))); return r end
function M.btype(ptr) return call_or_hint("GetBuildingType", ptr) end
function M.upgrade(ptr) local r=call_or_hint("UpgradeBuilding", ptr); print(string.format("upgrade %s -> %s", tostring(ptr), tostring(r))); return r end
function M.downgrade(ptr) local r=call_or_hint("DowngradeBuilding", ptr); print(string.format("downgrade %s -> %s", tostring(ptr), tostring(r))); return r end
function M.create(btype, x, y) local r=call_or_hint("CreateBuilding", btype, x, y); print(string.format("create btype=%s @%s,%s -> %s", tostring(btype), tostring(x), tostring(y), tostring(r))); return r end

-- per-building aliases (curry self.addr so snapshot-building flow needs one less arg)
function Obj:trade_reputation(otherCity) return call_or_hint("GetTradeReputation", self.addr, otherCity or 0) end
function Obj:set_trade_reputation(otherCity, n) local r=call_or_hint("SetTradeReputation", self.addr, otherCity or 0, n or 0); print(string.format("building 0x%08X trade_rep[0x%X]->%s", self.addr, otherCity or 0, tostring(n))); return r end
function Obj:caravan_value() return call_or_hint("GetCaravanValue", self.addr) end
function Obj:inventory_count(goodId) return call_or_hint("GetInventoryCount", self.addr, goodId or 0) end

function M.at(addr)
    addr = to_addr(addr)
    return setmetatable({ addr = addr }, Obj)
end

return M
