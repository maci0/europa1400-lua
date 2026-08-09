-- Europa 1400 - World / Time Helper
--
-- Wraps clock / season / speed / difficulty + city/world state
-- catalog entries behind `world.*`.
--
--   world = dofile('lua/world.lua')  -- or already `world`
--   world.find()                       -- catalog.hunt("world")
--   world.scan(0x00400000, 0x300000)   -- presets.hunt clock/city
--   world.time()      -- GetTimeHours
--   world.set_time(12)
--   world.year() / world.set_year(1400)
--   world.season()    -- 0..3
--   world.speed() / world.set_speed(2)
--   world.difficulty() / world.set_difficulty(1)
--   world.city_owner(cityId) / world.set_city_owner(cityId, owner)
--   world.is_besieged(cityId)
--   world.enter(playerId, cityId) / world.leave(playerId)
--   world.office(cityId, officeId) / world.set_office(cityId, officeId, playerId)
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
    error(name .. " not registered; run world.find() / catalog.hunt('world') or game.register first")
end

function M.scan(base, size)
    base = base or 0x00400000; size = size or 0x300000
    print(string.format("world.scan [0x%08X +0x%X]", base, size))
    local presets = _G.presets or (pcall(dofile, "lua/presets.lua") and _G.presets)
    local hits = {}
    if presets and presets.hunt then
        for _, key in ipairs({ "clock", "city", "map", "guild" }) do
            local h = presets.hunt(key, base, size) or {}
            for _, a in ipairs(h) do hits[#hits+1] = a end
        end
        local seen, uniq = {}, {}
        for _, a in ipairs(hits) do if not seen[a] then seen[a]=true; uniq[#uniq+1]=a end end
        hits = uniq; table.sort(hits)
        if #hits > 0 then print(string.format("world.scan: %d unique hit(s)", #hits)); return hits end
    end
    print("world.scan: no hits; try world.find() or wider base/size")
    return hits
end

function M.find(base, size)
    local cat = _G.catalog or (pcall(dofile, "lua/catalog.lua") and _G.catalog)
    if not cat or not cat.hunt then error("catalog not available") end
    return cat.hunt("world", base, size)
end

-- clock / calendar
function M.time() return call_or_hint("GetTimeHours") end
function M.set_time(h) local r=call_or_hint("SetTimeHours", h); print(string.format("time -> %s", tostring(h))); return r end
function M.year() return call_or_hint("GetYear") end
function M.set_year(y) local r=call_or_hint("SetYear", y); print(string.format("year -> %s", tostring(y))); return r end
function M.season() return call_or_hint("GetSeason") end
function M.speed() return call_or_hint("GetGameSpeed") end
function M.set_speed(v) local r=call_or_hint("SetGameSpeed", v); print(string.format("speed -> %s", tostring(v))); return r end
function M.difficulty() return call_or_hint("GetDifficulty") end
function M.set_difficulty(v) local r=call_or_hint("SetDifficulty", v); print(string.format("difficulty -> %s", tostring(v))); return r end
function M.is_paused() return call_or_hint("IsGamePaused") end

-- city / world
function M.city_owner(cityId) return call_or_hint("GetCityOwner", cityId) end
function M.set_city_owner(cityId, owner) local r=call_or_hint("SetCityOwner", cityId, owner); print(string.format("city %s owner -> %s", tostring(cityId), tostring(owner))); return r end
function M.is_besieged(cityId) return call_or_hint("IsCityBesieged", cityId) end
function M.enter(playerId, cityId) return call_or_hint("EnterCity", playerId, cityId) end
function M.leave(playerId) return call_or_hint("LeaveCity", playerId) end
function M.office(cityId, officeId) return call_or_hint("GetOfficeHolder", cityId, officeId) end
function M.set_office(cityId, officeId, playerId) local r=call_or_hint("SetOfficeHolder", cityId, officeId, playerId); print(string.format("office city=%s off=%s -> player %s", tostring(cityId), tostring(officeId), tostring(playerId))); return r end
function M.selected_building() return call_or_hint("GetSelectedBuilding") end
function M.selected_unit() return call_or_hint("GetSelectedUnit") end
function M.office_bribe_cost(cityId, officeId) return call_or_hint("GetOfficeBribeCost", cityId, officeId) end
function M.is_bribed(cityId, officeId) return call_or_hint("IsBribed", cityId, officeId) end
function M.office_prestige(cityId, officeId) return call_or_hint("GetOfficePrestige", cityId, officeId) end
function M.is_office_vacant(cityId, officeId) return call_or_hint("IsOfficeVacant", cityId, officeId) end
function M.guard_count(cityId) return call_or_hint("GetGuardCount", cityId) end
function M.set_guard_count(cityId, n) local r=call_or_hint("SetGuardCount", cityId, n); print(string.format("guards city=%s -> %s", tostring(cityId), tostring(n))); return r end
function M.city_rank(cityId) return call_or_hint("GetCityRank", cityId) end
function M.city_prestige(cityId) return call_or_hint("GetCityPrestige", cityId) end
function M.set_city_prestige(cityId, v) local r=call_or_hint("SetCityPrestige", cityId, v); print(string.format("city prestige %s -> %s", tostring(cityId), tostring(v))); return r end
function M.public_order(cityId) return call_or_hint("GetPublicOrder", cityId) end
function M.set_public_order(cityId, v) local r=call_or_hint("SetPublicOrder", cityId, v); print(string.format("public order city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.city_favor(cityId, playerId) return call_or_hint("GetCityFavor", cityId, playerId) end
function M.set_city_favor(cityId, playerId, v) local r=call_or_hint("SetCityFavor", cityId, playerId, v); print(string.format("city favor city=%s player=%s -> %s", tostring(cityId), tostring(playerId), tostring(v))); return r end
function M.office_term(cityId, officeId) return call_or_hint("GetOfficeTerm", cityId, officeId) end
function M.set_office_term(cityId, officeId, v) local r=call_or_hint("SetOfficeTerm", cityId, officeId, v); print(string.format("office term city=%s off=%s -> %s", tostring(cityId), tostring(officeId), tostring(v))); return r end
function M.militia(cityId) return call_or_hint("GetMilitiaCount", cityId) end
function M.set_militia(cityId, v) local r=call_or_hint("SetMilitiaCount", cityId, v); print(string.format("militia city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall_health(cityId) return call_or_hint("GetCityWallHealth", cityId) end
function M.set_wall_health(cityId, v) local r=call_or_hint("SetCityWallHealth", cityId, v); print(string.format("wall health city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.defense(cityId) return call_or_hint("GetCityDefense", cityId) end
function M.set_defense(cityId, v) local r=call_or_hint("SetCityDefense", cityId, v); print(string.format("defense city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.unrest(cityId) return call_or_hint("GetCityUnrest", cityId) end
function M.set_unrest(cityId, v) local r=call_or_hint("SetCityUnrest", cityId, v); print(string.format("unrest city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prosperity(cityId) return call_or_hint("GetCityProsperity", cityId) end
function M.set_prosperity(cityId, v) local r=call_or_hint("SetCityProsperity", cityId, v); print(string.format("prosperity city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.office_salary(cityId, officeId) return call_or_hint("GetOfficeSalary", cityId, officeId) end
function M.set_office_salary(cityId, officeId, v) local r=call_or_hint("SetOfficeSalary", cityId, officeId, v); print(string.format("salary city=%s office=%s -> %s", tostring(cityId), tostring(officeId), tostring(v))); return r end
function M.festival(cityId) return call_or_hint("GetFestivalState", cityId) end
function M.food(cityId) return call_or_hint("GetCityFoodSupply", cityId) end
function M.set_food(cityId, v) local r=call_or_hint("SetCityFoodSupply", cityId, v); print(string.format("food city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.corruption(cityId) return call_or_hint("GetCityCorruption", cityId) end
function M.set_corruption(cityId, v) local r=call_or_hint("SetCityCorruption", cityId, v); print(string.format("corruption city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bribe_cooldown(pid, cityId, officeId) return call_or_hint("GetBribeCooldown", pid, cityId, officeId) end
function M.bandit(cityId) return call_or_hint("GetBanditThreat", cityId) end
function M.set_bandit(cityId, v) local r=call_or_hint("SetBanditThreat", cityId, v); print(string.format("bandit city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spy_suspicion(pid, cityId) return call_or_hint("GetSpySuspicion", pid, cityId) end
function M.set_spy_suspicion(pid, cityId, v) local r=call_or_hint("SetSpySuspicion", pid, cityId, v); print(string.format("spy suspicion %s city=%s -> %s", tostring(pid), tostring(cityId), tostring(v))); return r end
function M.road(cityId) return call_or_hint("GetCityRoadQuality", cityId) end
function M.plague(cityId) return call_or_hint("GetPlagueState", cityId) end
function M.set_plague(cityId, v) local r=call_or_hint("SetPlagueState", cityId, v); print(string.format("plague city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall_cost(cityId, lvl) return call_or_hint("GetCityWallUpgradeCost", cityId, lvl) end
function M.fair(cityId) return call_or_hint("GetCityFairState", cityId) end
function M.toll(cityId, roadId) return call_or_hint("GetTollRevenue", cityId, roadId) end
function M.set_toll(cityId, roadId, v) local r=call_or_hint("SetTollRevenue", cityId, roadId, v); print(string.format("toll city=%s road=%s -> %s", tostring(cityId), tostring(roadId), tostring(v))); return r end
function M.escort_cost(cityId, lvl) return call_or_hint("GetEscortCost", cityId, lvl) end
function M.toll_gates(cityId) return call_or_hint("GetCityTollGateCount", cityId) end
function M.set_toll_gates(cityId, v) local r=call_or_hint("SetCityTollGateCount", cityId, v); print(string.format("toll gates city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.road_upkeep(cityId, roadId) return call_or_hint("GetRoadUpkeepCost", cityId, roadId) end
function M.market_stalls(cityId) return call_or_hint("GetCityMarketStallCount", cityId) end
function M.harbor(cityId) return call_or_hint("GetCityHarborLevel", cityId) end
function M.set_harbor(cityId, lvl) local r=call_or_hint("SetCityHarborLevel", cityId, lvl); print(string.format("harbor city=%s -> %s", tostring(cityId), tostring(lvl))); return r end
function M.tax_income(cityId) return call_or_hint("GetCityTaxIncome", cityId) end
function M.university(cityId) return call_or_hint("GetUniversityLevel", cityId) end
function M.set_university(cityId, lvl) local r=call_or_hint("SetUniversityLevel", cityId, lvl); print(string.format("university city=%s -> %s", tostring(cityId), tostring(lvl))); return r end
function M.guard_morale(cityId) return call_or_hint("GetGuardMorale", cityId) end
function M.set_guard_morale(cityId, v) local r=call_or_hint("SetGuardMorale", cityId, v); print(string.format("guard morale city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.militia_upkeep(cityId) return call_or_hint("GetMilitiaUpkeepCost", cityId) end
function M.smuggler_fee(cityId, goodId) return call_or_hint("GetSmugglerFee", cityId, goodId) end
function M.harbor_fee(cityId, goodId) return call_or_hint("GetHarborFee", cityId, goodId) end
function M.festival_cost(cityId, ftype) return call_or_hint("GetCityFestivalCost", cityId, ftype) end
function M.stall_rent(cityId, stallType) return call_or_hint("GetMarketStallRent", cityId, stallType) end
function M.church_tax(cityId) return call_or_hint("GetChurchTaxRate", cityId) end
function M.set_church_tax(cityId, v) local r=call_or_hint("SetChurchTaxRate", cityId, v); print(string.format("church tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market_fee(cityId) return call_or_hint("GetCityMarketFee", cityId) end
function M.set_market_fee(cityId, v) local r=call_or_hint("SetCityMarketFee", cityId, v); print(string.format("market fee city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.watch(cityId) return call_or_hint("GetWatchStrength", cityId) end
function M.set_watch(cityId, v) local r=call_or_hint("SetWatchStrength", cityId, v); print(string.format("watch city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.debasement(cityId) return call_or_hint("GetCoinDebasement", cityId) end
function M.set_debasement(cityId, v) local r=call_or_hint("SetCoinDebasement", cityId, v); print(string.format("debasement city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.regulation(cityId) return call_or_hint("GetMarketRegulation", cityId) end
function M.siege(cityId) return call_or_hint("GetSiegeProgress", cityId) end
function M.set_siege(cityId, v) local r=call_or_hint("SetSiegeProgress", cityId, v); print(string.format("siege city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison(cityId) return call_or_hint("GetWallGarrisonCount", cityId) end
function M.set_garrison(cityId, v) local r=call_or_hint("SetWallGarrisonCount", cityId, v); print(string.format("garrison city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.merc_cost(cityId, mtype) return call_or_hint("GetMercenaryCost", cityId, mtype) end
function M.patrol(cityId) return call_or_hint("GetPatrolStrength", cityId) end
function M.set_patrol(cityId, v) local r=call_or_hint("SetPatrolStrength", cityId, v); print(string.format("patrol city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bandit_risk(cityId, roadId) return call_or_hint("GetRoadBanditRisk", cityId, roadId) end
function M.set_bandit_risk(cityId, roadId, v) local r=call_or_hint("SetRoadBanditRisk", cityId, roadId, v); print(string.format("bandit risk city=%s road=%s -> %s", tostring(cityId), tostring(roadId), tostring(v))); return r end
function M.tavern_brawl(cityId) return call_or_hint("GetTavernBrawlChance", cityId) end
function M.guild_hall(guildId, cityId) return call_or_hint("GetGuildHallLevel", guildId, cityId) end
function M.set_guild_hall(guildId, cityId, lvl) local r=call_or_hint("SetGuildHallLevel", guildId, cityId, lvl); print(string.format("guild hall guild=%s city=%s -> %s", tostring(guildId), tostring(cityId), tostring(lvl))); return r end
function M.tax_collector(cityId) return call_or_hint("GetTaxCollectorEfficiency", cityId) end
function M.set_tax_collector(cityId, v) local r=call_or_hint("SetTaxCollectorEfficiency", cityId, v); print(string.format("tax collector city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall_repair(cityId) return call_or_hint("GetCityWallRepairCost", cityId) end
function M.town_hall(cityId) return call_or_hint("GetTownHallLevel", cityId) end
function M.set_town_hall(cityId, v) local r=call_or_hint("SetTownHallLevel", cityId, v); print(string.format("town hall city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church_level(cityId) return call_or_hint("GetChurchLevel", cityId) end
function M.set_church_level(cityId, v) local r=call_or_hint("SetChurchLevel", cityId, v); print(string.format("church level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market_level(cityId) return call_or_hint("GetMarketLevel", cityId) end
function M.set_market_level(cityId, v) local r=call_or_hint("SetMarketLevel", cityId, v); print(string.format("market level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern_level(cityId) return call_or_hint("GetTavernLevel", cityId) end
function M.library(cityId) return call_or_hint("GetLibraryLevel", cityId) end
function M.set_library(cityId, v) local r=call_or_hint("SetLibraryLevel", cityId, v); print(string.format("library city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school(cityId) return call_or_hint("GetSchoolLevel", cityId) end
function M.set_school(cityId, v) local r=call_or_hint("SetSchoolLevel", cityId, v); print(string.format("school city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dock(cityId) return call_or_hint("GetDockLevel", cityId) end
function M.set_dock(cityId, v) local r=call_or_hint("SetDockLevel", cityId, v); print(string.format("dock city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armory(cityId) return call_or_hint("GetArmoryLevel", cityId) end
function M.warehouse(cityId) return call_or_hint("GetWarehouseLevel", cityId) end
function M.set_warehouse(cityId, v) local r=call_or_hint("SetWarehouseLevel", cityId, v); print(string.format("warehouse city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine(cityId) return call_or_hint("GetMineLevel", cityId) end
function M.set_mine(cityId, v) local r=call_or_hint("SetMineLevel", cityId, v); print(string.format("mine city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison_level(cityId) return call_or_hint("GetGarrisonLevel", cityId) end
function M.set_garrison_level(cityId, v) local r=call_or_hint("SetGarrisonLevel", cityId, v); print(string.format("garrison level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse_level(cityId) return call_or_hint("GetBathhouseLevel", cityId) end
function M.harbor_master(cityId) return call_or_hint("GetHarborMasterLevel", cityId) end
function M.set_harbor_master(cityId, v) local r=call_or_hint("SetHarborMasterLevel", cityId, v); print(string.format("harbor master city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse(cityId) return call_or_hint("GetGuardhouseLevel", cityId) end
function M.set_guardhouse(cityId, v) local r=call_or_hint("SetGuardhouseLevel", cityId, v); print(string.format("guardhouse city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse(cityId) return call_or_hint("GetCourthouseLevel", cityId) end
function M.set_courthouse(cityId, v) local r=call_or_hint("SetCourthouseLevel", cityId, v); print(string.format("courthouse city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.univ_hall(cityId) return call_or_hint("GetUniversityHallLevel", cityId) end
function M.castle(cityId) return call_or_hint("GetCastleLevel", cityId) end
function M.set_castle(cityId, v) local r=call_or_hint("SetCastleLevel", cityId, v); print(string.format("castle city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral_level(cityId) return call_or_hint("GetCathedralLevel", cityId) end
function M.set_cathedral_level(cityId, v) local r=call_or_hint("SetCathedralLevel", cityId, v); print(string.format("cathedral level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery_level(cityId) return call_or_hint("GetMonasteryLevel", cityId) end
function M.set_monastery_level(cityId, v) local r=call_or_hint("SetMonasteryLevel", cityId, v); print(string.format("monastery level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_level2(cityId) return call_or_hint("GetHarborLevel", cityId) end
function M.barracks(cityId) return call_or_hint("GetBarracksLevel", cityId) end
function M.set_barracks(cityId, v) local r=call_or_hint("SetBarracksLevel", cityId, v); print(string.format("barracks city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables(cityId) return call_or_hint("GetStablesLevel", cityId) end
function M.set_stables(cityId, v) local r=call_or_hint("SetStablesLevel", cityId, v); print(string.format("stables city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates(cityId) return call_or_hint("GetGatesLevel", cityId) end
function M.set_gates(cityId, v) local r=call_or_hint("SetGatesLevel", cityId, v); print(string.format("gates city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry(cityId) return call_or_hint("GetSentryTowerLevel", cityId) end
function M.well(cityId) return call_or_hint("GetWellLevel", cityId) end
function M.set_well(cityId, v) local r=call_or_hint("SetWellLevel", cityId, v); print(string.format("well city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge(cityId) return call_or_hint("GetBridgeLevel", cityId) end
function M.set_bridge(cityId, v) local r=call_or_hint("SetBridgeLevel", cityId, v); print(string.format("bridge city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall_level(cityId) return call_or_hint("GetWallLevel", cityId) end
function M.set_wall_level(cityId, v) local r=call_or_hint("SetWallLevel", cityId, v); print(string.format("wall level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower(cityId) return call_or_hint("GetTowerLevel", cityId) end
function M.forum(cityId) return call_or_hint("GetForumLevel", cityId) end
function M.set_forum(cityId, v) local r=call_or_hint("SetForumLevel", cityId, v); print(string.format("forum city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary_level(cityId) return call_or_hint("GetGranaryLevel", cityId) end
function M.set_granary_level(cityId, v) local r=call_or_hint("SetGranaryLevel", cityId, v); print(string.format("granary level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison(cityId) return call_or_hint("GetPrisonLevel", cityId) end
function M.set_prison(cityId, v) local r=call_or_hint("SetPrisonLevel", cityId, v); print(string.format("prison city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock(cityId) return call_or_hint("GetHarborDockLevel", cityId) end
function M.guild_house2(cityId) return call_or_hint("GetGuildHouseLevel", cityId) end
function M.set_guild_house2(cityId, v) local r=call_or_hint("SetGuildHouseLevel", cityId, v); print(string.format("guild house v2 city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house(cityId) return call_or_hint("GetHouseLevel", cityId) end
function M.set_house(cityId, v) local r=call_or_hint("SetHouseLevel", cityId, v); print(string.format("house city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel(cityId) return call_or_hint("GetChapelLevel", cityId) end
function M.set_chapel(cityId, v) local r=call_or_hint("SetChapelLevel", cityId, v); print(string.format("chapel city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital_level(cityId) return call_or_hint("GetHospitalLevel", cityId) end
function M.harbor_walls2(cityId) return call_or_hint("GetHarborWallsLevel2", cityId) end
function M.set_harbor_walls2(cityId, v) local r=call_or_hint("SetHarborWallsLevel2", cityId, v); print(string.format("harbor walls2 city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse2(cityId) return call_or_hint("GetSchoolhouseLevel2", cityId) end
function M.set_schoolhouse2(cityId, v) local r=call_or_hint("SetSchoolhouseLevel2", cityId, v); print(string.format("schoolhouse2 city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall2(cityId) return call_or_hint("GetLibraryHallLevel2", cityId) end
function M.set_library_hall2(cityId, v) local r=call_or_hint("SetLibraryHallLevel2", cityId, v); print(string.format("library hall2 city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel_tax(cityId) return call_or_hint("GetBrothelTaxRate", cityId) end
function M.harbor_walls_tax2(cityId) return call_or_hint("GetHarborWallsTaxRate2", cityId) end
function M.set_harbor_walls_tax2(cityId, v) local r=call_or_hint("SetHarborWallsTaxRate2", cityId, v); print(string.format("harbor walls tax2 city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse_tax(cityId) return call_or_hint("GetSchoolhouseTaxRate", cityId) end
function M.set_schoolhouse_tax(cityId, v) local r=call_or_hint("SetSchoolhouseTaxRate", cityId, v); print(string.format("schoolhouse tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall_tax(cityId) return call_or_hint("GetLibraryHallTaxRate", cityId) end
function M.set_library_hall_tax(cityId, v) local r=call_or_hint("SetLibraryHallTaxRate", cityId, v); print(string.format("library hall tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber_tax(cityId) return call_or_hint("GetBarberTaxRate", cityId) end
function M.schoolhouse_tax2(cityId) return call_or_hint("GetSchoolhouseTaxRate2", cityId) end
function M.set_schoolhouse_tax2(cityId, v) local r=call_or_hint("SetSchoolhouseTaxRate2", cityId, v); print(string.format("schoolhouse tax2 city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall_tax2(cityId) return call_or_hint("GetLibraryHallTaxRate2", cityId) end
function M.set_library_hall_tax2(cityId, v) local r=call_or_hint("SetLibraryHallTaxRate2", cityId, v); print(string.format("library hall tax2 city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel_tax2(cityId) return call_or_hint("GetBrothelTaxRate2", cityId) end
function M.set_brothel_tax2(cityId, v) local r=call_or_hint("SetBrothelTaxRate2", cityId, v); print(string.format("brothel tax2 city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor_tax2(cityId) return call_or_hint("GetContorTaxRate2", cityId) end
function M.dice_house_tax2(cityId) return call_or_hint("GetDiceHouseTaxRate2", cityId) end
function M.set_dice_house_tax2(cityId, v) local r=call_or_hint("SetDiceHouseTaxRate2", cityId, v); print(string.format("dice house tax2 city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves_guild_tax2(cityId) return call_or_hint("GetThievesGuildTaxRate2", cityId) end
function M.set_thieves_guild_tax2(cityId, v) local r=call_or_hint("SetThievesGuildTaxRate2", cityId, v); print(string.format("thieves guild tax2 city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls_tax4(cityId) return call_or_hint("GetHarborWallsTaxRate4", cityId) end
function M.set_harbor_walls_tax4(cityId, v) local r=call_or_hint("SetHarborWallsTaxRate4", cityId, v); print(string.format("harbor walls tax4 city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_ws_tax(cityId) return call_or_hint("GetRopemakerWorkshopTaxRate", cityId) end
function M.tannery_tax(cityId) return call_or_hint("GetTanneryTaxRate", cityId) end
function M.set_tannery_tax(cityId, v) local r=call_or_hint("SetTanneryTaxRate", cityId, v); print(string.format("tannery tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving_tax(cityId) return call_or_hint("GetWeavingMillTaxRate", cityId) end
function M.set_weaving_tax(cityId, v) local r=call_or_hint("SetWeavingMillTaxRate", cityId, v); print(string.format("weaving mill tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint_tax(cityId) return call_or_hint("GetMintTaxRate", cityId) end
function M.set_mint_tax(cityId, v) local r=call_or_hint("SetMintTaxRate", cityId, v); print(string.format("mint tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden_tax(cityId) return call_or_hint("GetHerbGardenTaxRate", cityId) end
function M.vineyard_tax(cityId) return call_or_hint("GetVineyardTaxRate", cityId) end
function M.set_vineyard_tax(cityId, v) local r=call_or_hint("SetVineyardTaxRate", cityId, v); print(string.format("vineyard tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery_tax(cityId) return call_or_hint("GetPotteryTaxRate", cityId) end
function M.set_pottery_tax(cityId, v) local r=call_or_hint("SetPotteryTaxRate", cityId, v); print(string.format("pottery tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor_tax(cityId) return call_or_hint("GetTailorTaxRate", cityId) end
function M.set_tailor_tax(cityId, v) local r=call_or_hint("SetTailorTaxRate", cityId, v); print(string.format("tailor tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern_tax(cityId) return call_or_hint("GetTavernTaxRate", cityId) end
function M.bathhouse_tax(cityId) return call_or_hint("GetBathhouseTaxRate", cityId) end
function M.set_bathhouse_tax(cityId, v) local r=call_or_hint("SetBathhouseTaxRate", cityId, v); print(string.format("bathhouse tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate", cityId) end
function M.set_church_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate", cityId, v); print(string.format("church level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate", cityId) end
function M.set_contor_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate", cityId, v); print(string.format("contor level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate", cityId) end
function M.thieves_guild_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate", cityId) end
function M.set_thieves_guild_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate", cityId, v); print(string.format("thieves guild level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_workshop_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate", cityId) end
function M.set_ropemaker_workshop_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate", cityId, v); print(string.format("ropemaker workshop level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate", cityId) end
function M.set_tannery_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate", cityId, v); print(string.format("tannery level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate", cityId) end
function M.mint_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate", cityId) end
function M.set_mint_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate", cityId, v); print(string.format("mint level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate", cityId) end
function M.set_herb_garden_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate", cityId, v); print(string.format("herb garden level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate", cityId) end
function M.set_vineyard_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate", cityId, v); print(string.format("vineyard level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate", cityId) end
function M.tailor_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate", cityId) end
function M.set_tailor_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate", cityId, v); print(string.format("tailor level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate", cityId) end
function M.set_tavern_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate", cityId, v); print(string.format("tavern level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate", cityId) end
function M.set_apothecary_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate", cityId, v); print(string.format("apothecary level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate", cityId) end
function M.jeweler_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate", cityId) end
function M.set_jeweler_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate", cityId, v); print(string.format("jeweler level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate", cityId) end
function M.set_perfumer_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate", cityId, v); print(string.format("perfumer level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate", cityId) end
function M.set_soapmaker_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate", cityId, v); print(string.format("soapmaker level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate", cityId) end
function M.set_candlemaker_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate", cityId, v); print(string.format("candlemaker level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate", cityId) end
function M.set_papermill_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate", cityId, v); print(string.format("papermill level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate", cityId) end
function M.set_printing_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate", cityId, v); print(string.format("printing house level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate", cityId) end
function M.set_toolmaker_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate", cityId, v); print(string.format("toolmaker level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate", cityId) end
function M.set_charcoal_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate", cityId, v); print(string.format("charcoal burner level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate", cityId) end
function M.set_furrier_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate", cityId, v); print(string.format("furrier level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate", cityId) end
function M.set_dyer_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate", cityId, v); print(string.format("dyer level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate", cityId) end
function M.set_saddler_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate", cityId, v); print(string.format("saddler level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate", cityId) end
function M.set_armorer_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate", cityId, v); print(string.format("armorer level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate", cityId) end
function M.set_bowyer_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate", cityId, v); print(string.format("bowyer level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate", cityId) end
function M.set_cartwright_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate", cityId, v); print(string.format("cartwright level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate", cityId) end
function M.set_carpenter_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate", cityId, v); print(string.format("carpenter level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate", cityId) end
function M.set_ropemaker_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate", cityId, v); print(string.format("ropemaker level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate", cityId) end
function M.set_cooper_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate", cityId, v); print(string.format("cooper level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate", cityId) end
function M.set_spinner_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate", cityId, v); print(string.format("spinner level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate", cityId) end
function M.set_turner_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate", cityId, v); print(string.format("turner level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate", cityId) end
function M.set_stonecutter_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate", cityId, v); print(string.format("stonecutter level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate", cityId) end
function M.set_cobbler_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate", cityId, v); print(string.format("cobbler level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate", cityId) end
function M.set_butcher_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate", cityId, v); print(string.format("butcher level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate", cityId) end
function M.set_baker_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate", cityId, v); print(string.format("baker level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate", cityId) end
function M.set_shepherd_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate", cityId, v); print(string.format("shepherd level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate", cityId) end
function M.set_dairy_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate", cityId, v); print(string.format("dairy level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate", cityId) end
function M.set_brewmaster_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate", cityId, v); print(string.format("brewmaster level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate", cityId) end
function M.set_miller_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate", cityId, v); print(string.format("miller level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate", cityId) end
function M.set_fishery_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate", cityId, v); print(string.format("fishery level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate", cityId) end
function M.set_chandler_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate", cityId, v); print(string.format("chandler level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate", cityId) end
function M.set_goldbeater_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate", cityId, v); print(string.format("goldbeater level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate", cityId) end
function M.set_potter_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate", cityId, v); print(string.format("potter level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate", cityId) end
function M.set_fowler_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate", cityId, v); print(string.format("fowler level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate", cityId) end
function M.set_vintner_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate", cityId, v); print(string.format("vintner level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate", cityId) end
function M.set_distiller_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate", cityId, v); print(string.format("distiller level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate", cityId) end
function M.set_cook_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate", cityId, v); print(string.format("cook level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate", cityId) end
function M.set_brickmaker_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate", cityId, v); print(string.format("brickmaker level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate", cityId) end
function M.set_bathhouse_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate", cityId, v); print(string.format("bathhouse level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate", cityId) end
function M.set_barracks_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate", cityId, v); print(string.format("barracks level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate", cityId) end
function M.set_school_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate", cityId, v); print(string.format("school level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate", cityId) end
function M.set_library_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate", cityId, v); print(string.format("library level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate", cityId) end
function M.set_mine_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate", cityId, v); print(string.format("mine level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate", cityId) end
function M.set_warehouse_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate", cityId, v); print(string.format("warehouse level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate", cityId) end
function M.set_garrison_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate", cityId, v); print(string.format("garrison level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate", cityId) end
function M.set_monastery_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate", cityId, v); print(string.format("monastery level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate", cityId) end
function M.set_cathedral_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate", cityId, v); print(string.format("cathedral level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate", cityId) end
function M.set_town_hall_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate", cityId, v); print(string.format("town hall level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate", cityId) end
function M.set_market_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate", cityId, v); print(string.format("market level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate", cityId) end
function M.set_harbor_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate", cityId, v); print(string.format("harbor level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate", cityId) end
function M.set_guardhouse_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate", cityId, v); print(string.format("guardhouse level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate", cityId) end
function M.set_courthouse_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate", cityId, v); print(string.format("courthouse level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.univ_hall_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate", cityId) end
function M.set_univ_hall_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate", cityId, v); print(string.format("university hall level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate", cityId) end
function M.set_castle_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate", cityId, v); print(string.format("castle level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks2_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate2", cityId) end
function M.set_barracks2_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate2", cityId, v); print(string.format("barracks2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate", cityId) end
function M.set_stables_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate", cityId, v); print(string.format("stables level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate", cityId) end
function M.set_gates_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate", cityId, v); print(string.format("gates level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate", cityId) end
function M.set_sentry_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate", cityId, v); print(string.format("sentry tower level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate", cityId) end
function M.set_well_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate", cityId, v); print(string.format("well level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate", cityId) end
function M.set_bridge_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate", cityId, v); print(string.format("bridge level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate", cityId) end
function M.set_wall_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate", cityId, v); print(string.format("wall level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate", cityId) end
function M.set_tower_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate", cityId, v); print(string.format("tower level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate", cityId) end
function M.set_forum_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate", cityId, v); print(string.format("forum level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate", cityId) end
function M.set_granary_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate", cityId, v); print(string.format("granary level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate", cityId) end
function M.set_prison_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate", cityId, v); print(string.format("prison level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate", cityId) end
function M.set_harbor_dock_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate", cityId, v); print(string.format("harbor dock level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate", cityId) end
function M.set_guild_house_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate", cityId, v); print(string.format("guild house level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate", cityId) end
function M.set_house_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate", cityId, v); print(string.format("house level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate", cityId) end
function M.set_chapel_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate", cityId, v); print(string.format("chapel level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate", cityId) end
function M.set_hospital_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate", cityId, v); print(string.format("hospital level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate", cityId) end
function M.set_brothel_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate", cityId, v); print(string.format("brothel level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate", cityId) end
function M.set_university_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate", cityId, v); print(string.format("university level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate", cityId) end
function M.set_harbor_walls_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate", cityId, v); print(string.format("harbor walls level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate", cityId) end
function M.set_schoolhouse_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate", cityId, v); print(string.format("schoolhouse level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate", cityId) end
function M.set_library_hall_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate", cityId, v); print(string.format("library hall level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate", cityId) end
function M.set_barber_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate", cityId, v); print(string.format("barber level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor2_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate2", cityId) end
function M.set_contor2_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate2", cityId, v); print(string.format("contor2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house2_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate2", cityId) end
function M.set_dice_house2_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate2", cityId, v); print(string.format("dice house2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves2_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate2", cityId) end
function M.set_thieves2_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate2", cityId, v); print(string.format("thieves guild2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_ws2_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate2", cityId) end
function M.set_ropemaker_ws2_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate2", cityId, v); print(string.format("ropemaker workshop2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery2_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate2", cityId) end
function M.set_tannery2_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate2", cityId, v); print(string.format("tannery2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving2_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate2", cityId) end
function M.set_weaving2_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate2", cityId, v); print(string.format("weaving mill2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint2_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate2", cityId) end
function M.set_mint2_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate2", cityId, v); print(string.format("mint2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden2_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate2", cityId) end
function M.set_herb_garden2_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate2", cityId, v); print(string.format("herb garden2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard2_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate2", cityId) end
function M.set_vineyard2_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate2", cityId, v); print(string.format("vineyard2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery2_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate2", cityId) end
function M.set_pottery2_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate2", cityId, v); print(string.format("pottery2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor2_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate2", cityId) end
function M.set_tailor2_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate2", cityId, v); print(string.format("tailor2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern2_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate2", cityId) end
function M.set_tavern2_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate2", cityId, v); print(string.format("tavern2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary2_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate2", cityId) end
function M.set_apothecary2_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate2", cityId, v); print(string.format("apothecary2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith2_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate2", cityId) end
function M.set_goldsmith2_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate2", cityId, v); print(string.format("goldsmith2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler2_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate2", cityId) end
function M.set_jeweler2_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate2", cityId, v); print(string.format("jeweler2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer2_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate2", cityId) end
function M.set_perfumer2_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate2", cityId, v); print(string.format("perfumer2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker2_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate2", cityId) end
function M.set_soapmaker2_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate2", cityId, v); print(string.format("soapmaker2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker2_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate2", cityId) end
function M.set_candlemaker2_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate2", cityId, v); print(string.format("candlemaker2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill2_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate2", cityId) end
function M.set_papermill2_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate2", cityId, v); print(string.format("papermill2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing2_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate2", cityId) end
function M.set_printing2_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate2", cityId, v); print(string.format("printing house2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker2_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate2", cityId) end
function M.set_toolmaker2_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate2", cityId, v); print(string.format("toolmaker2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal2_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate2", cityId) end
function M.set_charcoal2_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate2", cityId, v); print(string.format("charcoal burner2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier2_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate2", cityId) end
function M.set_furrier2_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate2", cityId, v); print(string.format("furrier2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer2_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate2", cityId) end
function M.set_dyer2_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate2", cityId, v); print(string.format("dyer2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler2_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate2", cityId) end
function M.set_saddler2_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate2", cityId, v); print(string.format("saddler2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer2_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate2", cityId) end
function M.set_armorer2_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate2", cityId, v); print(string.format("armorer2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer2_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate2", cityId) end
function M.set_bowyer2_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate2", cityId, v); print(string.format("bowyer2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright2_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate2", cityId) end
function M.set_cartwright2_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate2", cityId, v); print(string.format("cartwright2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter2_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate2", cityId) end
function M.set_carpenter2_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate2", cityId, v); print(string.format("carpenter2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker2_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate2", cityId) end
function M.set_ropemaker2_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate2", cityId, v); print(string.format("ropemaker2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper2_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate2", cityId) end
function M.set_cooper2_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate2", cityId, v); print(string.format("cooper2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner2_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate2", cityId) end
function M.set_spinner2_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate2", cityId, v); print(string.format("spinner2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner2_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate2", cityId) end
function M.set_turner2_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate2", cityId, v); print(string.format("turner2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter2_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate2", cityId) end
function M.set_stonecutter2_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate2", cityId, v); print(string.format("stonecutter2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler2_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate2", cityId) end
function M.set_cobbler2_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate2", cityId, v); print(string.format("cobbler2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher2_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate2", cityId) end
function M.set_butcher2_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate2", cityId, v); print(string.format("butcher2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker2_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate2", cityId) end
function M.set_baker2_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate2", cityId, v); print(string.format("baker2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd2_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate2", cityId) end
function M.set_shepherd2_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate2", cityId, v); print(string.format("shepherd2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy2_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate2", cityId) end
function M.set_dairy2_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate2", cityId, v); print(string.format("dairy2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster2_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate2", cityId) end
function M.set_brewmaster2_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate2", cityId, v); print(string.format("brewmaster2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller2_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate2", cityId) end
function M.set_miller2_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate2", cityId, v); print(string.format("miller2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery2_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate2", cityId) end
function M.set_fishery2_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate2", cityId, v); print(string.format("fishery2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler2_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate2", cityId) end
function M.set_chandler2_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate2", cityId, v); print(string.format("chandler2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater2_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate2", cityId) end
function M.set_goldbeater2_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate2", cityId, v); print(string.format("goldbeater2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter2_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate2", cityId) end
function M.set_potter2_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate2", cityId, v); print(string.format("potter2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler2_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate2", cityId) end
function M.set_fowler2_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate2", cityId, v); print(string.format("fowler2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner2_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate2", cityId) end
function M.set_vintner2_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate2", cityId, v); print(string.format("vintner2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller2_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate2", cityId) end
function M.set_distiller2_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate2", cityId, v); print(string.format("distiller2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook2_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate2", cityId) end
function M.set_cook2_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate2", cityId, v); print(string.format("cook2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker2_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate2", cityId) end
function M.set_brickmaker2_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate2", cityId, v); print(string.format("brickmaker2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse2_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate2", cityId) end
function M.set_bathhouse2_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate2", cityId, v); print(string.format("bathhouse2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks3_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate3", cityId) end
function M.set_barracks3_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate3", cityId, v); print(string.format("barracks3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school2_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate2", cityId) end
function M.set_school2_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate2", cityId, v); print(string.format("school2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library2_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate2", cityId) end
function M.set_library2_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate2", cityId, v); print(string.format("library2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine2_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate2", cityId) end
function M.set_mine2_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate2", cityId, v); print(string.format("mine2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse2_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate2", cityId) end
function M.set_warehouse2_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate2", cityId, v); print(string.format("warehouse2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison2_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate2", cityId) end
function M.set_garrison2_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate2", cityId, v); print(string.format("garrison2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery2_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate2", cityId) end
function M.set_monastery2_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate2", cityId, v); print(string.format("monastery2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral2_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate2", cityId) end
function M.set_cathedral2_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate2", cityId, v); print(string.format("cathedral2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall2_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate2", cityId) end
function M.set_town_hall2_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate2", cityId, v); print(string.format("town hall2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market2_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate2", cityId) end
function M.set_market2_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate2", cityId, v); print(string.format("market2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor2_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate2", cityId) end
function M.set_harbor2_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate2", cityId, v); print(string.format("harbor2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse2_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate2", cityId) end
function M.set_guardhouse2_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate2", cityId, v); print(string.format("guardhouse2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse2_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate2", cityId) end
function M.set_courthouse2_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate2", cityId, v); print(string.format("courthouse2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.univ_hall2_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate2", cityId) end
function M.set_univ_hall2_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate2", cityId, v); print(string.format("university hall2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle2_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate2", cityId) end
function M.set_castle2_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate2", cityId, v); print(string.format("castle2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks4_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate4", cityId) end
function M.set_barracks4_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate4", cityId, v); print(string.format("barracks4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables2_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate2", cityId) end
function M.set_stables2_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate2", cityId, v); print(string.format("stables2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates2_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate2", cityId) end
function M.set_gates2_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate2", cityId, v); print(string.format("gates2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry2_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate2", cityId) end
function M.set_sentry2_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate2", cityId, v); print(string.format("sentry tower2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well2_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate2", cityId) end
function M.set_well2_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate2", cityId, v); print(string.format("well2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge2_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate2", cityId) end
function M.set_bridge2_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate2", cityId, v); print(string.format("bridge2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall2_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate2", cityId) end
function M.set_wall2_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate2", cityId, v); print(string.format("wall2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower2_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate2", cityId) end
function M.set_tower2_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate2", cityId, v); print(string.format("tower2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum2_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate2", cityId) end
function M.set_forum2_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate2", cityId, v); print(string.format("forum2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary2_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate2", cityId) end
function M.set_granary2_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate2", cityId, v); print(string.format("granary2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison2_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate2", cityId) end
function M.set_prison2_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate2", cityId, v); print(string.format("prison2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock2_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate2", cityId) end
function M.set_harbor_dock2_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate2", cityId, v); print(string.format("harbor dock2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house2_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate2", cityId) end
function M.set_guild_house2_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate2", cityId, v); print(string.format("guild house2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house2_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate2", cityId) end
function M.set_house2_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate2", cityId, v); print(string.format("house2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel2_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate2", cityId) end
function M.set_chapel2_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate2", cityId, v); print(string.format("chapel2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital2_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate2", cityId) end
function M.set_hospital2_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate2", cityId, v); print(string.format("hospital2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel2_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate2", cityId) end
function M.set_brothel2_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate2", cityId, v); print(string.format("brothel2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university2_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate2", cityId) end
function M.set_university2_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate2", cityId, v); print(string.format("university2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls2_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate2", cityId) end
function M.set_harbor_walls2_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate2", cityId, v); print(string.format("harbor walls2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse2_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate2", cityId) end
function M.set_schoolhouse2_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate2", cityId, v); print(string.format("schoolhouse2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall2_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate2", cityId) end
function M.set_library_hall2_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate2", cityId, v); print(string.format("library hall2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber2_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate2", cityId) end
function M.set_barber2_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate2", cityId, v); print(string.format("barber2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor3_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate3", cityId) end
function M.set_contor3_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate3", cityId, v); print(string.format("contor3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house3_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate3", cityId) end
function M.set_dice_house3_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate3", cityId, v); print(string.format("dice house3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves3_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate3", cityId) end
function M.set_thieves3_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate3", cityId, v); print(string.format("thieves guild3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_ws3_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate3", cityId) end
function M.set_ropemaker_ws3_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate3", cityId, v); print(string.format("ropemaker workshop3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery3_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate3", cityId) end
function M.set_tannery3_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate3", cityId, v); print(string.format("tannery3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving3_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate3", cityId) end
function M.set_weaving3_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate3", cityId, v); print(string.format("weaving mill3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint3_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate3", cityId) end
function M.set_mint3_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate3", cityId, v); print(string.format("mint3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden3_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate3", cityId) end
function M.set_herb_garden3_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate3", cityId, v); print(string.format("herb garden3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard3_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate3", cityId) end
function M.set_vineyard3_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate3", cityId, v); print(string.format("vineyard3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery3_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate3", cityId) end
function M.set_pottery3_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate3", cityId, v); print(string.format("pottery3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor3_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate3", cityId) end
function M.set_tailor3_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate3", cityId, v); print(string.format("tailor3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern3_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate3", cityId) end
function M.set_tavern3_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate3", cityId, v); print(string.format("tavern3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary3_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate3", cityId) end
function M.set_apothecary3_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate3", cityId, v); print(string.format("apothecary3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith3_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate3", cityId) end
function M.set_goldsmith3_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate3", cityId, v); print(string.format("goldsmith3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler3_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate3", cityId) end
function M.set_jeweler3_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate3", cityId, v); print(string.format("jeweler3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer3_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate3", cityId) end
function M.set_perfumer3_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate3", cityId, v); print(string.format("perfumer3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker3_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate3", cityId) end
function M.set_soapmaker3_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate3", cityId, v); print(string.format("soapmaker3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker3_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate3", cityId) end
function M.set_candlemaker3_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate3", cityId, v); print(string.format("candlemaker3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill3_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate3", cityId) end
function M.set_papermill3_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate3", cityId, v); print(string.format("papermill3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing3_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate3", cityId) end
function M.set_printing3_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate3", cityId, v); print(string.format("printing house3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker3_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate3", cityId) end
function M.set_toolmaker3_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate3", cityId, v); print(string.format("toolmaker3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal3_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate3", cityId) end
function M.set_charcoal3_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate3", cityId, v); print(string.format("charcoal burner3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier3_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate3", cityId) end
function M.set_furrier3_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate3", cityId, v); print(string.format("furrier3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer3_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate3", cityId) end
function M.set_dyer3_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate3", cityId, v); print(string.format("dyer3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler3_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate3", cityId) end
function M.set_saddler3_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate3", cityId, v); print(string.format("saddler3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer3_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate3", cityId) end
function M.set_armorer3_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate3", cityId, v); print(string.format("armorer3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer3_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate3", cityId) end
function M.set_bowyer3_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate3", cityId, v); print(string.format("bowyer3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright3_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate3", cityId) end
function M.set_cartwright3_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate3", cityId, v); print(string.format("cartwright3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter3_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate3", cityId) end
function M.set_carpenter3_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate3", cityId, v); print(string.format("carpenter3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker3_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate3", cityId) end
function M.set_ropemaker3_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate3", cityId, v); print(string.format("ropemaker3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper3_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate3", cityId) end
function M.set_cooper3_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate3", cityId, v); print(string.format("cooper3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner3_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate3", cityId) end
function M.set_spinner3_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate3", cityId, v); print(string.format("spinner3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner3_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate3", cityId) end
function M.set_turner3_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate3", cityId, v); print(string.format("turner3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter3_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate3", cityId) end
function M.set_stonecutter3_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate3", cityId, v); print(string.format("stonecutter3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler3_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate3", cityId) end
function M.set_cobbler3_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate3", cityId, v); print(string.format("cobbler3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher3_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate3", cityId) end
function M.set_butcher3_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate3", cityId, v); print(string.format("butcher3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker3_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate3", cityId) end
function M.set_baker3_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate3", cityId, v); print(string.format("baker3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd3_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate3", cityId) end
function M.set_shepherd3_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate3", cityId, v); print(string.format("shepherd3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy3_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate3", cityId) end
function M.set_dairy3_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate3", cityId, v); print(string.format("dairy3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster3_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate3", cityId) end
function M.set_brewmaster3_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate3", cityId, v); print(string.format("brewmaster3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller3_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate3", cityId) end
function M.set_miller3_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate3", cityId, v); print(string.format("miller3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery3_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate3", cityId) end
function M.set_fishery3_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate3", cityId, v); print(string.format("fishery3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler3_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate3", cityId) end
function M.set_chandler3_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate3", cityId, v); print(string.format("chandler3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater3_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate3", cityId) end
function M.set_goldbeater3_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate3", cityId, v); print(string.format("goldbeater3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter3_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate3", cityId) end
function M.set_potter3_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate3", cityId, v); print(string.format("potter3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler3_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate3", cityId) end
function M.set_fowler3_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate3", cityId, v); print(string.format("fowler3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner3_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate3", cityId) end
function M.set_vintner3_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate3", cityId, v); print(string.format("vintner3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller3_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate3", cityId) end
function M.set_distiller3_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate3", cityId, v); print(string.format("distiller3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook3_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate3", cityId) end
function M.set_cook3_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate3", cityId, v); print(string.format("cook3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker3_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate3", cityId) end
function M.set_brickmaker3_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate3", cityId, v); print(string.format("brickmaker3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse3_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate3", cityId) end
function M.set_bathhouse3_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate3", cityId, v); print(string.format("bathhouse3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks5_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate5", cityId) end
function M.set_barracks5_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate5", cityId, v); print(string.format("barracks5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school3_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate3", cityId) end
function M.set_school3_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate3", cityId, v); print(string.format("school3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library3_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate3", cityId) end
function M.set_library3_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate3", cityId, v); print(string.format("library3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine3_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate3", cityId) end
function M.set_mine3_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate3", cityId, v); print(string.format("mine3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse3_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate3", cityId) end
function M.set_warehouse3_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate3", cityId, v); print(string.format("warehouse3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison3_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate3", cityId) end
function M.set_garrison3_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate3", cityId, v); print(string.format("garrison3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery3_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate3", cityId) end
function M.set_monastery3_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate3", cityId, v); print(string.format("monastery3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral3_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate3", cityId) end
function M.set_cathedral3_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate3", cityId, v); print(string.format("cathedral3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall3_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate3", cityId) end
function M.set_town_hall3_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate3", cityId, v); print(string.format("town hall3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market3_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate3", cityId) end
function M.set_market3_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate3", cityId, v); print(string.format("market3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor3_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate3", cityId) end
function M.set_harbor3_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate3", cityId, v); print(string.format("harbor3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse3_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate3", cityId) end
function M.set_guardhouse3_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate3", cityId, v); print(string.format("guardhouse3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse3_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate3", cityId) end
function M.set_courthouse3_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate3", cityId, v); print(string.format("courthouse3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.univ_hall3_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate3", cityId) end
function M.set_univ_hall3_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate3", cityId, v); print(string.format("university hall3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle3_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate3", cityId) end
function M.set_castle3_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate3", cityId, v); print(string.format("castle3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks6_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate6", cityId) end
function M.set_barracks6_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate6", cityId, v); print(string.format("barracks6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables3_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate3", cityId) end
function M.set_stables3_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate3", cityId, v); print(string.format("stables3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates3_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate3", cityId) end
function M.set_gates3_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate3", cityId, v); print(string.format("gates3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry3_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate3", cityId) end
function M.set_sentry3_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate3", cityId, v); print(string.format("sentry tower3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well3_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate3", cityId) end
function M.set_well3_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate3", cityId, v); print(string.format("well3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge3_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate3", cityId) end
function M.set_bridge3_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate3", cityId, v); print(string.format("bridge3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall3_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate3", cityId) end
function M.set_wall3_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate3", cityId, v); print(string.format("wall3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower3_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate3", cityId) end
function M.set_tower3_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate3", cityId, v); print(string.format("tower3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum3_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate3", cityId) end
function M.set_forum3_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate3", cityId, v); print(string.format("forum3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary3_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate3", cityId) end
function M.set_granary3_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate3", cityId, v); print(string.format("granary3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison3_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate3", cityId) end
function M.set_prison3_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate3", cityId, v); print(string.format("prison3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock3_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate3", cityId) end
function M.set_harbor_dock3_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate3", cityId, v); print(string.format("harbor dock3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house3_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate3", cityId) end
function M.set_guild_house3_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate3", cityId, v); print(string.format("guild house3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house3_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate3", cityId) end
function M.set_house3_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate3", cityId, v); print(string.format("house3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel3_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate3", cityId) end
function M.set_chapel3_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate3", cityId, v); print(string.format("chapel3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital3_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate3", cityId) end
function M.set_hospital3_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate3", cityId, v); print(string.format("hospital3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel3_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate3", cityId) end
function M.set_brothel3_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate3", cityId, v); print(string.format("brothel3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university3_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate3", cityId) end
function M.set_university3_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate3", cityId, v); print(string.format("university3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls3_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate3", cityId) end
function M.set_harbor_walls3_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate3", cityId, v); print(string.format("harbor walls3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse3_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate3", cityId) end
function M.set_schoolhouse3_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate3", cityId, v); print(string.format("schoolhouse3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall3_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate3", cityId) end
function M.set_library_hall3_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate3", cityId, v); print(string.format("library hall3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber3_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate3", cityId) end
function M.set_barber3_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate3", cityId, v); print(string.format("barber3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor4_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate4", cityId) end
function M.set_contor4_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate4", cityId, v); print(string.format("contor4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house4_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate4", cityId) end
function M.set_dice_house4_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate4", cityId, v); print(string.format("dice house4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves4_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate4", cityId) end
function M.set_thieves4_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate4", cityId, v); print(string.format("thieves guild4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_ws4_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate4", cityId) end
function M.set_ropemaker_ws4_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate4", cityId, v); print(string.format("ropemaker workshop4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery4_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate4", cityId) end
function M.set_tannery4_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate4", cityId, v); print(string.format("tannery4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving4_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate4", cityId) end
function M.set_weaving4_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate4", cityId, v); print(string.format("weaving mill4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint4_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate4", cityId) end
function M.set_mint4_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate4", cityId, v); print(string.format("mint4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden4_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate4", cityId) end
function M.set_herb_garden4_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate4", cityId, v); print(string.format("herb garden4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard4_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate4", cityId) end
function M.set_vineyard4_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate4", cityId, v); print(string.format("vineyard4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery4_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate4", cityId) end
function M.set_pottery4_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate4", cityId, v); print(string.format("pottery4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor4_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate4", cityId) end
function M.set_tailor4_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate4", cityId, v); print(string.format("tailor4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern4_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate4", cityId) end
function M.set_tavern4_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate4", cityId, v); print(string.format("tavern4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary4_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate4", cityId) end
function M.set_apothecary4_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate4", cityId, v); print(string.format("apothecary4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith4_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate4", cityId) end
function M.set_goldsmith4_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate4", cityId, v); print(string.format("goldsmith4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler4_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate4", cityId) end
function M.set_jeweler4_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate4", cityId, v); print(string.format("jeweler4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer4_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate4", cityId) end
function M.set_perfumer4_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate4", cityId, v); print(string.format("perfumer4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker4_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate4", cityId) end
function M.set_soapmaker4_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate4", cityId, v); print(string.format("soapmaker4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker4_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate4", cityId) end
function M.set_candlemaker4_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate4", cityId, v); print(string.format("candlemaker4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill4_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate4", cityId) end
function M.set_papermill4_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate4", cityId, v); print(string.format("papermill4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing4_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate4", cityId) end
function M.set_printing4_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate4", cityId, v); print(string.format("printing house4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker4_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate4", cityId) end
function M.set_toolmaker4_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate4", cityId, v); print(string.format("toolmaker4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal4_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate4", cityId) end
function M.set_charcoal4_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate4", cityId, v); print(string.format("charcoal burner4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier4_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate4", cityId) end
function M.set_furrier4_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate4", cityId, v); print(string.format("furrier4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer4_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate4", cityId) end
function M.set_dyer4_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate4", cityId, v); print(string.format("dyer4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler4_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate4", cityId) end
function M.set_saddler4_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate4", cityId, v); print(string.format("saddler4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer4_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate4", cityId) end
function M.set_armorer4_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate4", cityId, v); print(string.format("armorer4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer4_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate4", cityId) end
function M.set_bowyer4_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate4", cityId, v); print(string.format("bowyer4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright4_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate4", cityId) end
function M.set_cartwright4_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate4", cityId, v); print(string.format("cartwright4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter4_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate4", cityId) end
function M.set_carpenter4_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate4", cityId, v); print(string.format("carpenter4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker4_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate4", cityId) end
function M.set_ropemaker4_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate4", cityId, v); print(string.format("ropemaker4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper4_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate4", cityId) end
function M.set_cooper4_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate4", cityId, v); print(string.format("cooper4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner4_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate4", cityId) end
function M.set_spinner4_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate4", cityId, v); print(string.format("spinner4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner4_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate4", cityId) end
function M.set_turner4_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate4", cityId, v); print(string.format("turner4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter4_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate4", cityId) end
function M.set_stonecutter4_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate4", cityId, v); print(string.format("stonecutter4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler4_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate4", cityId) end
function M.set_cobbler4_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate4", cityId, v); print(string.format("cobbler4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher4_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate4", cityId) end
function M.set_butcher4_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate4", cityId, v); print(string.format("butcher4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker4_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate4", cityId) end
function M.set_baker4_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate4", cityId, v); print(string.format("baker4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd4_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate4", cityId) end
function M.set_shepherd4_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate4", cityId, v); print(string.format("shepherd4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy4_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate4", cityId) end
function M.set_dairy4_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate4", cityId, v); print(string.format("dairy4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster4_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate4", cityId) end
function M.set_brewmaster4_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate4", cityId, v); print(string.format("brewmaster4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller4_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate4", cityId) end
function M.set_miller4_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate4", cityId, v); print(string.format("miller4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery4_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate4", cityId) end
function M.set_fishery4_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate4", cityId, v); print(string.format("fishery4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler4_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate4", cityId) end
function M.set_chandler4_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate4", cityId, v); print(string.format("chandler4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater4_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate4", cityId) end
function M.set_goldbeater4_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate4", cityId, v); print(string.format("goldbeater4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter4_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate4", cityId) end
function M.set_potter4_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate4", cityId, v); print(string.format("potter4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler4_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate4", cityId) end
function M.set_fowler4_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate4", cityId, v); print(string.format("fowler4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner4_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate4", cityId) end
function M.set_vintner4_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate4", cityId, v); print(string.format("vintner4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller4_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate4", cityId) end
function M.set_distiller4_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate4", cityId, v); print(string.format("distiller4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook4_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate4", cityId) end
function M.set_cook4_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate4", cityId, v); print(string.format("cook4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker4_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate4", cityId) end
function M.set_brickmaker4_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate4", cityId, v); print(string.format("brickmaker4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse4_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate4", cityId) end
function M.set_bathhouse4_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate4", cityId, v); print(string.format("bathhouse4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks7_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate7", cityId) end
function M.set_barracks7_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate7", cityId, v); print(string.format("barracks7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school4_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate4", cityId) end
function M.set_school4_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate4", cityId, v); print(string.format("school4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library4_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate4", cityId) end
function M.set_library4_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate4", cityId, v); print(string.format("library4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine4_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate4", cityId) end
function M.set_mine4_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate4", cityId, v); print(string.format("mine4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse4_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate4", cityId) end
function M.set_warehouse4_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate4", cityId, v); print(string.format("warehouse4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison4_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate4", cityId) end
function M.set_garrison4_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate4", cityId, v); print(string.format("garrison4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery4_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate4", cityId) end
function M.set_monastery4_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate4", cityId, v); print(string.format("monastery4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral4_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate4", cityId) end
function M.set_cathedral4_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate4", cityId, v); print(string.format("cathedral4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall4_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate4", cityId) end
function M.set_town_hall4_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate4", cityId, v); print(string.format("town hall4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market4_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate4", cityId) end
function M.set_market4_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate4", cityId, v); print(string.format("market4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor4_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate4", cityId) end
function M.set_harbor4_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate4", cityId, v); print(string.format("harbor4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse4_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate4", cityId) end
function M.set_guardhouse4_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate4", cityId, v); print(string.format("guardhouse4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse4_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate4", cityId) end
function M.set_courthouse4_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate4", cityId, v); print(string.format("courthouse4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.univ_hall4_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate4", cityId) end
function M.set_univ_hall4_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate4", cityId, v); print(string.format("university hall4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle4_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate4", cityId) end
function M.set_castle4_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate4", cityId, v); print(string.format("castle4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks8_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate8", cityId) end
function M.set_barracks8_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate8", cityId, v); print(string.format("barracks8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables4_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate4", cityId) end
function M.set_stables4_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate4", cityId, v); print(string.format("stables4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates4_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate4", cityId) end
function M.set_gates4_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate4", cityId, v); print(string.format("gates4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry4_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate4", cityId) end
function M.set_sentry4_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate4", cityId, v); print(string.format("sentry tower4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well4_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate4", cityId) end
function M.set_well4_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate4", cityId, v); print(string.format("well4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge4_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate4", cityId) end
function M.set_bridge4_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate4", cityId, v); print(string.format("bridge4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall4_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate4", cityId) end
function M.set_wall4_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate4", cityId, v); print(string.format("wall4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower4_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate4", cityId) end
function M.set_tower4_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate4", cityId, v); print(string.format("tower4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum4_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate4", cityId) end
function M.set_forum4_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate4", cityId, v); print(string.format("forum4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary4_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate4", cityId) end
function M.set_granary4_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate4", cityId, v); print(string.format("granary4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison4_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate4", cityId) end
function M.set_prison4_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate4", cityId, v); print(string.format("prison4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock4_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate4", cityId) end
function M.set_harbor_dock4_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate4", cityId, v); print(string.format("harbor dock4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house4_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate4", cityId) end
function M.set_guild_house4_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate4", cityId, v); print(string.format("guild house4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house4_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate4", cityId) end
function M.set_house4_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate4", cityId, v); print(string.format("house4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel4_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate4", cityId) end
function M.set_chapel4_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate4", cityId, v); print(string.format("chapel4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital4_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate4", cityId) end
function M.set_hospital4_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate4", cityId, v); print(string.format("hospital4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel4_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate4", cityId) end
function M.set_brothel4_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate4", cityId, v); print(string.format("brothel4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university4_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate4", cityId) end
function M.set_university4_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate4", cityId, v); print(string.format("university4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls4_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate4", cityId) end
function M.set_harbor_walls4_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate4", cityId, v); print(string.format("harbor walls4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse4_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate4", cityId) end
function M.set_schoolhouse4_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate4", cityId, v); print(string.format("schoolhouse4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall4_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate4", cityId) end
function M.set_library_hall4_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate4", cityId, v); print(string.format("library hall4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber4_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate4", cityId) end
function M.set_barber4_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate4", cityId, v); print(string.format("barber4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor5_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate5", cityId) end
function M.set_contor5_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate5", cityId, v); print(string.format("contor5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house5_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate5", cityId) end
function M.set_dice_house5_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate5", cityId, v); print(string.format("dice house5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves5_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate5", cityId) end
function M.set_thieves5_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate5", cityId, v); print(string.format("thieves guild5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_ws5_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate5", cityId) end
function M.set_ropemaker_ws5_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate5", cityId, v); print(string.format("ropemaker workshop5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery5_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate5", cityId) end
function M.set_tannery5_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate5", cityId, v); print(string.format("tannery5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving5_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate5", cityId) end
function M.set_weaving5_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate5", cityId, v); print(string.format("weaving mill5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint5_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate5", cityId) end
function M.set_mint5_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate5", cityId, v); print(string.format("mint5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden5_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate5", cityId) end
function M.set_herb_garden5_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate5", cityId, v); print(string.format("herb garden5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard5_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate5", cityId) end
function M.set_vineyard5_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate5", cityId, v); print(string.format("vineyard5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery5_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate5", cityId) end
function M.set_pottery5_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate5", cityId, v); print(string.format("pottery5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor5_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate5", cityId) end
function M.set_tailor5_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate5", cityId, v); print(string.format("tailor5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern5_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate5", cityId) end
function M.set_tavern5_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate5", cityId, v); print(string.format("tavern5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary5_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate5", cityId) end
function M.set_apothecary5_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate5", cityId, v); print(string.format("apothecary5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith5_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate5", cityId) end
function M.set_goldsmith5_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate5", cityId, v); print(string.format("goldsmith5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler5_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate5", cityId) end
function M.set_jeweler5_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate5", cityId, v); print(string.format("jeweler5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer5_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate5", cityId) end
function M.set_perfumer5_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate5", cityId, v); print(string.format("perfumer5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker5_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate5", cityId) end
function M.set_soapmaker5_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate5", cityId, v); print(string.format("soapmaker5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker5_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate5", cityId) end
function M.set_candlemaker5_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate5", cityId, v); print(string.format("candlemaker5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill5_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate5", cityId) end
function M.set_papermill5_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate5", cityId, v); print(string.format("papermill5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing5_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate5", cityId) end
function M.set_printing5_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate5", cityId, v); print(string.format("printing house5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker5_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate5", cityId) end
function M.set_toolmaker5_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate5", cityId, v); print(string.format("toolmaker5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal5_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate5", cityId) end
function M.set_charcoal5_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate5", cityId, v); print(string.format("charcoal burner5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier5_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate5", cityId) end
function M.set_furrier5_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate5", cityId, v); print(string.format("furrier5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer5_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate5", cityId) end
function M.set_dyer5_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate5", cityId, v); print(string.format("dyer5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler5_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate5", cityId) end
function M.set_saddler5_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate5", cityId, v); print(string.format("saddler5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer5_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate5", cityId) end
function M.set_armorer5_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate5", cityId, v); print(string.format("armorer5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer5_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate5", cityId) end
function M.set_bowyer5_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate5", cityId, v); print(string.format("bowyer5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright5_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate5", cityId) end
function M.set_cartwright5_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate5", cityId, v); print(string.format("cartwright5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter5_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate5", cityId) end
function M.set_carpenter5_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate5", cityId, v); print(string.format("carpenter5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker5_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate5", cityId) end
function M.set_ropemaker5_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate5", cityId, v); print(string.format("ropemaker5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper5_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate5", cityId) end
function M.set_cooper5_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate5", cityId, v); print(string.format("cooper5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner5_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate5", cityId) end
function M.set_spinner5_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate5", cityId, v); print(string.format("spinner5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner5_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate5", cityId) end
function M.set_turner5_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate5", cityId, v); print(string.format("turner5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter5_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate5", cityId) end
function M.set_stonecutter5_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate5", cityId, v); print(string.format("stonecutter5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler5_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate5", cityId) end
function M.set_cobbler5_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate5", cityId, v); print(string.format("cobbler5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher5_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate5", cityId) end
function M.set_butcher5_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate5", cityId, v); print(string.format("butcher5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker5_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate5", cityId) end
function M.set_baker5_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate5", cityId, v); print(string.format("baker5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd5_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate5", cityId) end
function M.set_shepherd5_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate5", cityId, v); print(string.format("shepherd5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy5_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate5", cityId) end
function M.set_dairy5_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate5", cityId, v); print(string.format("dairy5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster5_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate5", cityId) end
function M.set_brewmaster5_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate5", cityId, v); print(string.format("brewmaster5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller5_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate5", cityId) end
function M.set_miller5_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate5", cityId, v); print(string.format("miller5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery5_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate5", cityId) end
function M.set_fishery5_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate5", cityId, v); print(string.format("fishery5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler5_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate5", cityId) end
function M.set_chandler5_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate5", cityId, v); print(string.format("chandler5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater5_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate5", cityId) end
function M.set_goldbeater5_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate5", cityId, v); print(string.format("goldbeater5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter5_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate5", cityId) end
function M.set_potter5_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate5", cityId, v); print(string.format("potter5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler5_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate5", cityId) end
function M.set_fowler5_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate5", cityId, v); print(string.format("fowler5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner5_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate5", cityId) end
function M.set_vintner5_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate5", cityId, v); print(string.format("vintner5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller5_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate5", cityId) end
function M.set_distiller5_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate5", cityId, v); print(string.format("distiller5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook5_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate5", cityId) end
function M.set_cook5_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate5", cityId, v); print(string.format("cook5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker5_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate5", cityId) end
function M.set_brickmaker5_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate5", cityId, v); print(string.format("brickmaker5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse5_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate5", cityId) end
function M.set_bathhouse5_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate5", cityId, v); print(string.format("bathhouse5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks9_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate9", cityId) end
function M.set_barracks9_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate9", cityId, v); print(string.format("barracks9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school5_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate5", cityId) end
function M.set_school5_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate5", cityId, v); print(string.format("school5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library5_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate5", cityId) end
function M.set_library5_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate5", cityId, v); print(string.format("library5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine5_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate5", cityId) end
function M.set_mine5_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate5", cityId, v); print(string.format("mine5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse5_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate5", cityId) end
function M.set_warehouse5_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate5", cityId, v); print(string.format("warehouse5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison5_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate5", cityId) end
function M.set_garrison5_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate5", cityId, v); print(string.format("garrison5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery5_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate5", cityId) end
function M.set_monastery5_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate5", cityId, v); print(string.format("monastery5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral5_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate5", cityId) end
function M.set_cathedral5_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate5", cityId, v); print(string.format("cathedral5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall5_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate5", cityId) end
function M.set_town_hall5_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate5", cityId, v); print(string.format("town hall5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market5_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate5", cityId) end
function M.set_market5_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate5", cityId, v); print(string.format("market5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor5_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate5", cityId) end
function M.set_harbor5_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate5", cityId, v); print(string.format("harbor5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse5_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate5", cityId) end
function M.set_guardhouse5_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate5", cityId, v); print(string.format("guardhouse5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse5_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate5", cityId) end
function M.set_courthouse5_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate5", cityId, v); print(string.format("courthouse5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.univ_hall5_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate5", cityId) end
function M.set_univ_hall5_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate5", cityId, v); print(string.format("university hall5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle5_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate5", cityId) end
function M.set_castle5_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate5", cityId, v); print(string.format("castle5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks10_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate10", cityId) end
function M.set_barracks10_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate10", cityId, v); print(string.format("barracks10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables5_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate5", cityId) end
function M.set_stables5_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate5", cityId, v); print(string.format("stables5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates5_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate5", cityId) end
function M.set_gates5_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate5", cityId, v); print(string.format("gates5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry5_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate5", cityId) end
function M.set_sentry5_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate5", cityId, v); print(string.format("sentry tower5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well5_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate5", cityId) end
function M.set_well5_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate5", cityId, v); print(string.format("well5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge5_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate5", cityId) end
function M.set_bridge5_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate5", cityId, v); print(string.format("bridge5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall5_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate5", cityId) end
function M.set_wall5_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate5", cityId, v); print(string.format("wall5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower5_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate5", cityId) end
function M.set_tower5_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate5", cityId, v); print(string.format("tower5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum5_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate5", cityId) end
function M.set_forum5_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate5", cityId, v); print(string.format("forum5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary5_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate5", cityId) end
function M.set_granary5_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate5", cityId, v); print(string.format("granary5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison5_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate5", cityId) end
function M.set_prison5_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate5", cityId, v); print(string.format("prison5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock5_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate5", cityId) end
function M.set_harbor_dock5_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate5", cityId, v); print(string.format("harbor dock5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house5_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate5", cityId) end
function M.set_guild_house5_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate5", cityId, v); print(string.format("guild house5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house5_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate5", cityId) end
function M.set_house5_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate5", cityId, v); print(string.format("house5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel5_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate5", cityId) end
function M.set_chapel5_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate5", cityId, v); print(string.format("chapel5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital5_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate5", cityId) end
function M.set_hospital5_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate5", cityId, v); print(string.format("hospital5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel5_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate5", cityId) end
function M.set_brothel5_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate5", cityId, v); print(string.format("brothel5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university5_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate5", cityId) end
function M.set_university5_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate5", cityId, v); print(string.format("university5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls5_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate5", cityId) end
function M.set_harbor_walls5_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate5", cityId, v); print(string.format("harbor walls5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse5_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate5", cityId) end
function M.set_schoolhouse5_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate5", cityId, v); print(string.format("schoolhouse5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall5_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate5", cityId) end
function M.set_library_hall5_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate5", cityId, v); print(string.format("library hall5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber5_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate5", cityId) end
function M.set_barber5_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate5", cityId, v); print(string.format("barber5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor6_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate6", cityId) end
function M.set_contor6_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate6", cityId, v); print(string.format("contor6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house6_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate6", cityId) end
function M.set_dice_house6_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate6", cityId, v); print(string.format("dice house6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves6_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate6", cityId) end
function M.set_thieves6_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate6", cityId, v); print(string.format("thieves guild6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_ws6_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate6", cityId) end
function M.set_ropemaker_ws6_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate6", cityId, v); print(string.format("ropemaker workshop6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery6_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate6", cityId) end
function M.set_tannery6_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate6", cityId, v); print(string.format("tannery6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving6_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate6", cityId) end
function M.set_weaving6_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate6", cityId, v); print(string.format("weaving mill6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint6_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate6", cityId) end
function M.set_mint6_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate6", cityId, v); print(string.format("mint6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden6_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate6", cityId) end
function M.set_herb_garden6_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate6", cityId, v); print(string.format("herb garden6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard6_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate6", cityId) end
function M.set_vineyard6_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate6", cityId, v); print(string.format("vineyard6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery6_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate6", cityId) end
function M.set_pottery6_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate6", cityId, v); print(string.format("pottery6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor6_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate6", cityId) end
function M.set_tailor6_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate6", cityId, v); print(string.format("tailor6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern6_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate6", cityId) end
function M.set_tavern6_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate6", cityId, v); print(string.format("tavern6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary6_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate6", cityId) end
function M.set_apothecary6_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate6", cityId, v); print(string.format("apothecary6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith6_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate6", cityId) end
function M.set_goldsmith6_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate6", cityId, v); print(string.format("goldsmith6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler6_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate6", cityId) end
function M.set_jeweler6_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate6", cityId, v); print(string.format("jeweler6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer6_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate6", cityId) end
function M.set_perfumer6_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate6", cityId, v); print(string.format("perfumer6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker6_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate6", cityId) end
function M.set_soapmaker6_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate6", cityId, v); print(string.format("soapmaker6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker6_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate6", cityId) end
function M.set_candlemaker6_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate6", cityId, v); print(string.format("candlemaker6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill6_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate6", cityId) end
function M.set_papermill6_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate6", cityId, v); print(string.format("papermill6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing6_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate6", cityId) end
function M.set_printing6_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate6", cityId, v); print(string.format("printing house6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker6_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate6", cityId) end
function M.set_toolmaker6_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate6", cityId, v); print(string.format("toolmaker6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal6_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate6", cityId) end
function M.set_charcoal6_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate6", cityId, v); print(string.format("charcoal burner6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier6_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate6", cityId) end
function M.set_furrier6_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate6", cityId, v); print(string.format("furrier6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer6_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate6", cityId) end
function M.set_dyer6_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate6", cityId, v); print(string.format("dyer6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler6_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate6", cityId) end
function M.set_saddler6_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate6", cityId, v); print(string.format("saddler6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer6_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate6", cityId) end
function M.set_armorer6_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate6", cityId, v); print(string.format("armorer6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer6_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate6", cityId) end
function M.set_bowyer6_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate6", cityId, v); print(string.format("bowyer6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright6_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate6", cityId) end
function M.set_cartwright6_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate6", cityId, v); print(string.format("cartwright6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter6_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate6", cityId) end
function M.set_carpenter6_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate6", cityId, v); print(string.format("carpenter6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker6_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate6", cityId) end
function M.set_ropemaker6_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate6", cityId, v); print(string.format("ropemaker6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper6_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate6", cityId) end
function M.set_cooper6_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate6", cityId, v); print(string.format("cooper6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner6_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate6", cityId) end
function M.set_spinner6_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate6", cityId, v); print(string.format("spinner6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner6_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate6", cityId) end
function M.set_turner6_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate6", cityId, v); print(string.format("turner6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter6_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate6", cityId) end
function M.set_stonecutter6_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate6", cityId, v); print(string.format("stonecutter6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler6_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate6", cityId) end
function M.set_cobbler6_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate6", cityId, v); print(string.format("cobbler6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher6_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate6", cityId) end
function M.set_butcher6_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate6", cityId, v); print(string.format("butcher6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker6_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate6", cityId) end
function M.set_baker6_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate6", cityId, v); print(string.format("baker6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd6_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate6", cityId) end
function M.set_shepherd6_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate6", cityId, v); print(string.format("shepherd6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy6_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate6", cityId) end
function M.set_dairy6_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate6", cityId, v); print(string.format("dairy6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster6_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate6", cityId) end
function M.set_brewmaster6_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate6", cityId, v); print(string.format("brewmaster6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller6_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate6", cityId) end
function M.set_miller6_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate6", cityId, v); print(string.format("miller6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery6_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate6", cityId) end
function M.set_fishery6_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate6", cityId, v); print(string.format("fishery6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler6_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate6", cityId) end
function M.set_chandler6_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate6", cityId, v); print(string.format("chandler6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater6_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate6", cityId) end
function M.set_goldbeater6_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate6", cityId, v); print(string.format("goldbeater6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter6_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate6", cityId) end
function M.set_potter6_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate6", cityId, v); print(string.format("potter6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler6_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate6", cityId) end
function M.set_fowler6_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate6", cityId, v); print(string.format("fowler6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner6_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate6", cityId) end
function M.set_vintner6_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate6", cityId, v); print(string.format("vintner6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller6_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate6", cityId) end
function M.set_distiller6_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate6", cityId, v); print(string.format("distiller6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook6_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate6", cityId) end
function M.set_cook6_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate6", cityId, v); print(string.format("cook6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker6_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate6", cityId) end
function M.set_brickmaker6_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate6", cityId, v); print(string.format("brickmaker6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse6_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate6", cityId) end
function M.set_bathhouse6_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate6", cityId, v); print(string.format("bathhouse6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks11_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate11", cityId) end
function M.set_barracks11_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate11", cityId, v); print(string.format("barracks11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school6_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate6", cityId) end
function M.set_school6_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate6", cityId, v); print(string.format("school6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library6_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate6", cityId) end
function M.set_library6_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate6", cityId, v); print(string.format("library6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine6_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate6", cityId) end
function M.set_mine6_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate6", cityId, v); print(string.format("mine6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse6_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate6", cityId) end
function M.set_warehouse6_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate6", cityId, v); print(string.format("warehouse6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison6_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate6", cityId) end
function M.set_garrison6_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate6", cityId, v); print(string.format("garrison6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery6_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate6", cityId) end
function M.set_monastery6_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate6", cityId, v); print(string.format("monastery6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral6_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate6", cityId) end
function M.set_cathedral6_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate6", cityId, v); print(string.format("cathedral6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall6_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate6", cityId) end
function M.set_town_hall6_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate6", cityId, v); print(string.format("town hall6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market6_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate6", cityId) end
function M.set_market6_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate6", cityId, v); print(string.format("market6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor6_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate6", cityId) end
function M.set_harbor6_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate6", cityId, v); print(string.format("harbor6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse6_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate6", cityId) end
function M.set_guardhouse6_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate6", cityId, v); print(string.format("guardhouse6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse6_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate6", cityId) end
function M.set_courthouse6_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate6", cityId, v); print(string.format("courthouse6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.univ_hall6_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate6", cityId) end
function M.set_univ_hall6_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate6", cityId, v); print(string.format("university hall6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle6_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate6", cityId) end
function M.set_castle6_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate6", cityId, v); print(string.format("castle6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks12_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate12", cityId) end
function M.set_barracks12_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate12", cityId, v); print(string.format("barracks12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables6_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate6", cityId) end
function M.set_stables6_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate6", cityId, v); print(string.format("stables6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates6_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate6", cityId) end
function M.set_gates6_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate6", cityId, v); print(string.format("gates6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry6_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate6", cityId) end
function M.set_sentry6_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate6", cityId, v); print(string.format("sentry tower6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well6_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate6", cityId) end
function M.set_well6_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate6", cityId, v); print(string.format("well6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge6_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate6", cityId) end
function M.set_bridge6_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate6", cityId, v); print(string.format("bridge6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall6_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate6", cityId) end
function M.set_wall6_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate6", cityId, v); print(string.format("wall6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower6_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate6", cityId) end
function M.set_tower6_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate6", cityId, v); print(string.format("tower6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum6_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate6", cityId) end
function M.set_forum6_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate6", cityId, v); print(string.format("forum6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary6_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate6", cityId) end
function M.set_granary6_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate6", cityId, v); print(string.format("granary6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison6_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate6", cityId) end
function M.set_prison6_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate6", cityId, v); print(string.format("prison6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock6_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate6", cityId) end
function M.set_harbor_dock6_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate6", cityId, v); print(string.format("harbor dock6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house6_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate6", cityId) end
function M.set_guild_house6_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate6", cityId, v); print(string.format("guild house6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house6_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate6", cityId) end
function M.set_house6_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate6", cityId, v); print(string.format("house6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel6_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate6", cityId) end
function M.set_chapel6_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate6", cityId, v); print(string.format("chapel6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital6_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate6", cityId) end
function M.set_hospital6_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate6", cityId, v); print(string.format("hospital6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel6_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate6", cityId) end
function M.set_brothel6_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate6", cityId, v); print(string.format("brothel6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university6_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate6", cityId) end
function M.set_university6_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate6", cityId, v); print(string.format("university6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls6_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate6", cityId) end
function M.set_harbor_walls6_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate6", cityId, v); print(string.format("harbor walls6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse6_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate6", cityId) end
function M.set_schoolhouse6_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate6", cityId, v); print(string.format("schoolhouse6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall6_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate6", cityId) end
function M.set_library_hall6_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate6", cityId, v); print(string.format("library hall6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber6_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate6", cityId) end
function M.set_barber6_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate6", cityId, v); print(string.format("barber6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor7_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate7", cityId) end
function M.set_contor7_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate7", cityId, v); print(string.format("contor7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house7_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate7", cityId) end
function M.set_dice_house7_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate7", cityId, v); print(string.format("dice house7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves7_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate7", cityId) end
function M.set_thieves7_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate7", cityId, v); print(string.format("thieves guild7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_ws7_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate7", cityId) end
function M.set_ropemaker_ws7_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate7", cityId, v); print(string.format("ropemaker workshop7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery7_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate7", cityId) end
function M.set_tannery7_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate7", cityId, v); print(string.format("tannery7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving7_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate7", cityId) end
function M.set_weaving7_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate7", cityId, v); print(string.format("weaving mill7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint7_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate7", cityId) end
function M.set_mint7_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate7", cityId, v); print(string.format("mint7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden7_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate7", cityId) end
function M.set_herb_garden7_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate7", cityId, v); print(string.format("herb garden7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard7_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate7", cityId) end
function M.set_vineyard7_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate7", cityId, v); print(string.format("vineyard7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery7_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate7", cityId) end
function M.set_pottery7_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate7", cityId, v); print(string.format("pottery7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor7_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate7", cityId) end
function M.set_tailor7_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate7", cityId, v); print(string.format("tailor7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern7_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate7", cityId) end
function M.set_tavern7_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate7", cityId, v); print(string.format("tavern7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary7_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate7", cityId) end
function M.set_apothecary7_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate7", cityId, v); print(string.format("apothecary7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith7_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate7", cityId) end
function M.set_goldsmith7_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate7", cityId, v); print(string.format("goldsmith7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler7_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate7", cityId) end
function M.set_jeweler7_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate7", cityId, v); print(string.format("jeweler7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer7_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate7", cityId) end
function M.set_perfumer7_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate7", cityId, v); print(string.format("perfumer7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker7_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate7", cityId) end
function M.set_soapmaker7_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate7", cityId, v); print(string.format("soapmaker7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker7_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate7", cityId) end
function M.set_candlemaker7_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate7", cityId, v); print(string.format("candlemaker7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill7_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate7", cityId) end
function M.set_papermill7_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate7", cityId, v); print(string.format("papermill7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing7_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate7", cityId) end
function M.set_printing7_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate7", cityId, v); print(string.format("printing house7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker7_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate7", cityId) end
function M.set_toolmaker7_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate7", cityId, v); print(string.format("toolmaker7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal7_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate7", cityId) end
function M.set_charcoal7_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate7", cityId, v); print(string.format("charcoal burner7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier7_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate7", cityId) end
function M.set_furrier7_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate7", cityId, v); print(string.format("furrier7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer7_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate7", cityId) end
function M.set_dyer7_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate7", cityId, v); print(string.format("dyer7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler7_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate7", cityId) end
function M.set_saddler7_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate7", cityId, v); print(string.format("saddler7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer7_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate7", cityId) end
function M.set_armorer7_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate7", cityId, v); print(string.format("armorer7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer7_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate7", cityId) end
function M.set_bowyer7_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate7", cityId, v); print(string.format("bowyer7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright7_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate7", cityId) end
function M.set_cartwright7_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate7", cityId, v); print(string.format("cartwright7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter7_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate7", cityId) end
function M.set_carpenter7_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate7", cityId, v); print(string.format("carpenter7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker7_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate7", cityId) end
function M.set_ropemaker7_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate7", cityId, v); print(string.format("ropemaker7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper7_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate7", cityId) end
function M.set_cooper7_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate7", cityId, v); print(string.format("cooper7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner7_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate7", cityId) end
function M.set_spinner7_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate7", cityId, v); print(string.format("spinner7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner7_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate7", cityId) end
function M.set_turner7_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate7", cityId, v); print(string.format("turner7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter7_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate7", cityId) end
function M.set_stonecutter7_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate7", cityId, v); print(string.format("stonecutter7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler7_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate7", cityId) end
function M.set_cobbler7_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate7", cityId, v); print(string.format("cobbler7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher7_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate7", cityId) end
function M.set_butcher7_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate7", cityId, v); print(string.format("butcher7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker7_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate7", cityId) end
function M.set_baker7_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate7", cityId, v); print(string.format("baker7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd7_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate7", cityId) end
function M.set_shepherd7_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate7", cityId, v); print(string.format("shepherd7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy7_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate7", cityId) end
function M.set_dairy7_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate7", cityId, v); print(string.format("dairy7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster7_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate7", cityId) end
function M.set_brewmaster7_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate7", cityId, v); print(string.format("brewmaster7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller7_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate7", cityId) end
function M.set_miller7_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate7", cityId, v); print(string.format("miller7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery7_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate7", cityId) end
function M.set_fishery7_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate7", cityId, v); print(string.format("fishery7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler7_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate7", cityId) end
function M.set_chandler7_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate7", cityId, v); print(string.format("chandler7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater7_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate7", cityId) end
function M.set_goldbeater7_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate7", cityId, v); print(string.format("goldbeater7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter7_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate7", cityId) end
function M.set_potter7_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate7", cityId, v); print(string.format("potter7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler7_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate7", cityId) end
function M.set_fowler7_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate7", cityId, v); print(string.format("fowler7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner7_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate7", cityId) end
function M.set_vintner7_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate7", cityId, v); print(string.format("vintner7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller7_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate7", cityId) end
function M.set_distiller7_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate7", cityId, v); print(string.format("distiller7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook7_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate7", cityId) end
function M.set_cook7_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate7", cityId, v); print(string.format("cook7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker7_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate7", cityId) end
function M.set_brickmaker7_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate7", cityId, v); print(string.format("brickmaker7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse7_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate7", cityId) end
function M.set_bathhouse7_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate7", cityId, v); print(string.format("bathhouse7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks13_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate13", cityId) end
function M.set_barracks13_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate13", cityId, v); print(string.format("barracks13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school7_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate7", cityId) end
function M.set_school7_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate7", cityId, v); print(string.format("school7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library7_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate7", cityId) end
function M.set_library7_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate7", cityId, v); print(string.format("library7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine7_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate7", cityId) end
function M.set_mine7_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate7", cityId, v); print(string.format("mine7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse7_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate7", cityId) end
function M.set_warehouse7_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate7", cityId, v); print(string.format("warehouse7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison7_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate7", cityId) end
function M.set_garrison7_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate7", cityId, v); print(string.format("garrison7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery7_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate7", cityId) end
function M.set_monastery7_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate7", cityId, v); print(string.format("monastery7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral7_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate7", cityId) end
function M.set_cathedral7_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate7", cityId, v); print(string.format("cathedral7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall7_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate7", cityId) end
function M.set_town_hall7_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate7", cityId, v); print(string.format("town hall7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market7_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate7", cityId) end
function M.set_market7_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate7", cityId, v); print(string.format("market7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor7_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate7", cityId) end
function M.set_harbor7_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate7", cityId, v); print(string.format("harbor7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse7_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate7", cityId) end
function M.set_guardhouse7_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate7", cityId, v); print(string.format("guardhouse7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse7_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate7", cityId) end
function M.set_courthouse7_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate7", cityId, v); print(string.format("courthouse7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.univ_hall7_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate7", cityId) end
function M.set_univ_hall7_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate7", cityId, v); print(string.format("university hall7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle7_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate7", cityId) end
function M.set_castle7_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate7", cityId, v); print(string.format("castle7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks14_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate14", cityId) end
function M.set_barracks14_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate14", cityId, v); print(string.format("barracks14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables7_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate7", cityId) end
function M.set_stables7_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate7", cityId, v); print(string.format("stables7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates7_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate7", cityId) end
function M.set_gates7_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate7", cityId, v); print(string.format("gates7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry7_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate7", cityId) end
function M.set_sentry7_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate7", cityId, v); print(string.format("sentry tower7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well7_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate7", cityId) end
function M.set_well7_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate7", cityId, v); print(string.format("well7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge7_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate7", cityId) end
function M.set_bridge7_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate7", cityId, v); print(string.format("bridge7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall7_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate7", cityId) end
function M.set_wall7_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate7", cityId, v); print(string.format("wall7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower7_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate7", cityId) end
function M.set_tower7_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate7", cityId, v); print(string.format("tower7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum7_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate7", cityId) end
function M.set_forum7_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate7", cityId, v); print(string.format("forum7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary7_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate7", cityId) end
function M.set_granary7_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate7", cityId, v); print(string.format("granary7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison7_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate7", cityId) end
function M.set_prison7_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate7", cityId, v); print(string.format("prison7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock7_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate7", cityId) end
function M.set_harbor_dock7_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate7", cityId, v); print(string.format("harbor dock7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house7_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate7", cityId) end
function M.set_guild_house7_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate7", cityId, v); print(string.format("guild house7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house7_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate7", cityId) end
function M.set_house7_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate7", cityId, v); print(string.format("house7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel7_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate7", cityId) end
function M.set_chapel7_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate7", cityId, v); print(string.format("chapel7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital7_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate7", cityId) end
function M.set_hospital7_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate7", cityId, v); print(string.format("hospital7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel7_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate7", cityId) end
function M.set_brothel7_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate7", cityId, v); print(string.format("brothel7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university7_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate7", cityId) end
function M.set_university7_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate7", cityId, v); print(string.format("university7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls7_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate7", cityId) end
function M.set_harbor_walls7_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate7", cityId, v); print(string.format("harbor walls7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse7_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate7", cityId) end
function M.set_schoolhouse7_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate7", cityId, v); print(string.format("schoolhouse7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall7_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate7", cityId) end
function M.set_library_hall7_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate7", cityId, v); print(string.format("library hall7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber7_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate7", cityId) end
function M.set_barber7_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate7", cityId, v); print(string.format("barber7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor8_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate8", cityId) end
function M.set_contor8_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate8", cityId, v); print(string.format("contor8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house8_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate8", cityId) end
function M.set_dice_house8_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate8", cityId, v); print(string.format("dice house8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves8_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate8", cityId) end
function M.set_thieves8_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate8", cityId, v); print(string.format("thieves guild8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_ws8_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate8", cityId) end
function M.set_ropemaker_ws8_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate8", cityId, v); print(string.format("ropemaker workshop8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery8_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate8", cityId) end
function M.set_tannery8_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate8", cityId, v); print(string.format("tannery8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving8_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate8", cityId) end
function M.set_weaving8_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate8", cityId, v); print(string.format("weaving mill8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint8_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate8", cityId) end
function M.set_mint8_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate8", cityId, v); print(string.format("mint8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden8_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate8", cityId) end
function M.set_herb_garden8_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate8", cityId, v); print(string.format("herb garden8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard8_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate8", cityId) end
function M.set_vineyard8_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate8", cityId, v); print(string.format("vineyard8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery8_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate8", cityId) end
function M.set_pottery8_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate8", cityId, v); print(string.format("pottery8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor8_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate8", cityId) end
function M.set_tailor8_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate8", cityId, v); print(string.format("tailor8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern8_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate8", cityId) end
function M.set_tavern8_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate8", cityId, v); print(string.format("tavern8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary8_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate8", cityId) end
function M.set_apothecary8_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate8", cityId, v); print(string.format("apothecary8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith8_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate8", cityId) end
function M.set_goldsmith8_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate8", cityId, v); print(string.format("goldsmith8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler8_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate8", cityId) end
function M.set_jeweler8_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate8", cityId, v); print(string.format("jeweler8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer8_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate8", cityId) end
function M.set_perfumer8_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate8", cityId, v); print(string.format("perfumer8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker8_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate8", cityId) end
function M.set_soapmaker8_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate8", cityId, v); print(string.format("soapmaker8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker8_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate8", cityId) end
function M.set_candlemaker8_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate8", cityId, v); print(string.format("candlemaker8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill8_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate8", cityId) end
function M.set_papermill8_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate8", cityId, v); print(string.format("papermill8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing8_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate8", cityId) end
function M.set_printing8_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate8", cityId, v); print(string.format("printing house8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker8_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate8", cityId) end
function M.set_toolmaker8_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate8", cityId, v); print(string.format("toolmaker8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal8_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate8", cityId) end
function M.set_charcoal8_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate8", cityId, v); print(string.format("charcoal burner8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier8_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate8", cityId) end
function M.set_furrier8_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate8", cityId, v); print(string.format("furrier8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer8_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate8", cityId) end
function M.set_dyer8_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate8", cityId, v); print(string.format("dyer8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler8_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate8", cityId) end
function M.set_saddler8_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate8", cityId, v); print(string.format("saddler8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer8_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate8", cityId) end
function M.set_armorer8_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate8", cityId, v); print(string.format("armorer8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer8_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate8", cityId) end
function M.set_bowyer8_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate8", cityId, v); print(string.format("bowyer8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright8_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate8", cityId) end
function M.set_cartwright8_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate8", cityId, v); print(string.format("cartwright8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter8_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate8", cityId) end
function M.set_carpenter8_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate8", cityId, v); print(string.format("carpenter8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker8_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate8", cityId) end
function M.set_ropemaker8_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate8", cityId, v); print(string.format("ropemaker8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper8_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate8", cityId) end
function M.set_cooper8_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate8", cityId, v); print(string.format("cooper8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner8_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate8", cityId) end
function M.set_spinner8_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate8", cityId, v); print(string.format("spinner8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner8_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate8", cityId) end
function M.set_turner8_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate8", cityId, v); print(string.format("turner8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter8_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate8", cityId) end
function M.set_stonecutter8_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate8", cityId, v); print(string.format("stonecutter8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler8_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate8", cityId) end
function M.set_cobbler8_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate8", cityId, v); print(string.format("cobbler8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher8_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate8", cityId) end
function M.set_butcher8_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate8", cityId, v); print(string.format("butcher8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker8_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate8", cityId) end
function M.set_baker8_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate8", cityId, v); print(string.format("baker8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd8_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate8", cityId) end
function M.set_shepherd8_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate8", cityId, v); print(string.format("shepherd8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy8_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate8", cityId) end
function M.set_dairy8_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate8", cityId, v); print(string.format("dairy8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster8_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate8", cityId) end
function M.set_brewmaster8_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate8", cityId, v); print(string.format("brewmaster8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller8_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate8", cityId) end
function M.set_miller8_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate8", cityId, v); print(string.format("miller8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery8_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate8", cityId) end
function M.set_fishery8_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate8", cityId, v); print(string.format("fishery8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler8_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate8", cityId) end
function M.set_chandler8_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate8", cityId, v); print(string.format("chandler8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater8_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate8", cityId) end
function M.set_goldbeater8_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate8", cityId, v); print(string.format("goldbeater8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter8_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate8", cityId) end
function M.set_potter8_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate8", cityId, v); print(string.format("potter8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler8_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate8", cityId) end
function M.set_fowler8_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate8", cityId, v); print(string.format("fowler8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner8_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate8", cityId) end
function M.set_vintner8_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate8", cityId, v); print(string.format("vintner8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller8_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate8", cityId) end
function M.set_distiller8_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate8", cityId, v); print(string.format("distiller8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook8_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate8", cityId) end
function M.set_cook8_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate8", cityId, v); print(string.format("cook8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker8_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate8", cityId) end
function M.set_brickmaker8_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate8", cityId, v); print(string.format("brickmaker8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse8_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate8", cityId) end
function M.set_bathhouse8_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate8", cityId, v); print(string.format("bathhouse8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks15_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate15", cityId) end
function M.set_barracks15_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate15", cityId, v); print(string.format("barracks15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school8_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate8", cityId) end
function M.set_school8_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate8", cityId, v); print(string.format("school8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library8_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate8", cityId) end
function M.set_library8_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate8", cityId, v); print(string.format("library8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine8_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate8", cityId) end
function M.set_mine8_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate8", cityId, v); print(string.format("mine8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse8_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate8", cityId) end
function M.set_warehouse8_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate8", cityId, v); print(string.format("warehouse8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison8_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate8", cityId) end
function M.set_garrison8_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate8", cityId, v); print(string.format("garrison8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery8_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate8", cityId) end
function M.set_monastery8_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate8", cityId, v); print(string.format("monastery8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral8_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate8", cityId) end
function M.set_cathedral8_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate8", cityId, v); print(string.format("cathedral8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall8_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate8", cityId) end
function M.set_town_hall8_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate8", cityId, v); print(string.format("town hall8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market8_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate8", cityId) end
function M.set_market8_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate8", cityId, v); print(string.format("market8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor8_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate8", cityId) end
function M.set_harbor8_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate8", cityId, v); print(string.format("harbor8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse8_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate8", cityId) end
function M.set_guardhouse8_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate8", cityId, v); print(string.format("guardhouse8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse8_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate8", cityId) end
function M.set_courthouse8_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate8", cityId, v); print(string.format("courthouse8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.univ_hall8_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate8", cityId) end
function M.set_univ_hall8_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate8", cityId, v); print(string.format("university hall8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle8_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate8", cityId) end
function M.set_castle8_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate8", cityId, v); print(string.format("castle8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well8_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate8", cityId) end
function M.set_well8_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate8", cityId, v); print(string.format("well8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge8_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate8", cityId) end
function M.set_bridge8_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate8", cityId, v); print(string.format("bridge8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall8_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate8", cityId) end
function M.set_wall8_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate8", cityId, v); print(string.format("wall8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower8_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate8", cityId) end
function M.set_tower8_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate8", cityId, v); print(string.format("tower8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum8_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate8", cityId) end
function M.set_forum8_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate8", cityId, v); print(string.format("forum8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary8_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate8", cityId) end
function M.set_granary8_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate8", cityId, v); print(string.format("granary8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison8_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate8", cityId) end
function M.set_prison8_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate8", cityId, v); print(string.format("prison8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock8_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate8", cityId) end
function M.set_harbor_dock8_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate8", cityId, v); print(string.format("harbor dock8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house8_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate8", cityId) end
function M.set_guild_house8_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate8", cityId, v); print(string.format("guild house8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house8_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate8", cityId) end
function M.set_house8_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate8", cityId, v); print(string.format("house8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel8_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate8", cityId) end
function M.set_chapel8_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate8", cityId, v); print(string.format("chapel8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital8_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate8", cityId) end
function M.set_hospital8_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate8", cityId, v); print(string.format("hospital8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel8_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate8", cityId) end
function M.set_brothel8_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate8", cityId, v); print(string.format("brothel8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university8_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate8", cityId) end
function M.set_university8_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate8", cityId, v); print(string.format("university8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls8_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate8", cityId) end
function M.set_harbor_walls8_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate8", cityId, v); print(string.format("harbor walls8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse8_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate8", cityId) end
function M.set_schoolhouse8_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate8", cityId, v); print(string.format("schoolhouse8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall8_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate8", cityId) end
function M.set_library_hall8_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate8", cityId, v); print(string.format("library hall8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber8_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate8", cityId) end
function M.set_barber8_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate8", cityId, v); print(string.format("barber8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor9_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate9", cityId) end
function M.set_contor9_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate9", cityId, v); print(string.format("contor9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house9_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate9", cityId) end
function M.set_dice_house9_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate9", cityId, v); print(string.format("dice house9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves9_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate9", cityId) end
function M.set_thieves9_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate9", cityId, v); print(string.format("thieves guild9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_ws9_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate9", cityId) end
function M.set_ropemaker_ws9_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate9", cityId, v); print(string.format("ropemaker workshop9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery9_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate9", cityId) end
function M.set_tannery9_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate9", cityId, v); print(string.format("tannery9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving9_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate9", cityId) end
function M.set_weaving9_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate9", cityId, v); print(string.format("weaving mill9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint9_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate9", cityId) end
function M.set_mint9_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate9", cityId, v); print(string.format("mint9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden9_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate9", cityId) end
function M.set_herb_garden9_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate9", cityId, v); print(string.format("herb garden9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard9_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate9", cityId) end
function M.set_vineyard9_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate9", cityId, v); print(string.format("vineyard9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery9_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate9", cityId) end
function M.set_pottery9_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate9", cityId, v); print(string.format("pottery9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor9_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate9", cityId) end
function M.set_tailor9_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate9", cityId, v); print(string.format("tailor9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern9_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate9", cityId) end
function M.set_tavern9_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate9", cityId, v); print(string.format("tavern9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary9_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate9", cityId) end
function M.set_apothecary9_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate9", cityId, v); print(string.format("apothecary9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith9_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate9", cityId) end
function M.set_goldsmith9_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate9", cityId, v); print(string.format("goldsmith9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler9_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate9", cityId) end
function M.set_jeweler9_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate9", cityId, v); print(string.format("jeweler9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer9_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate9", cityId) end
function M.set_perfumer9_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate9", cityId, v); print(string.format("perfumer9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker9_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate9", cityId) end
function M.set_soapmaker9_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate9", cityId, v); print(string.format("soapmaker9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker9_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate9", cityId) end
function M.set_candlemaker9_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate9", cityId, v); print(string.format("candlemaker9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill9_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate9", cityId) end
function M.set_papermill9_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate9", cityId, v); print(string.format("papermill9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing9_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate9", cityId) end
function M.set_printing9_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate9", cityId, v); print(string.format("printing house9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker9_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate9", cityId) end
function M.set_toolmaker9_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate9", cityId, v); print(string.format("toolmaker9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal9_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate9", cityId) end
function M.set_charcoal9_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate9", cityId, v); print(string.format("charcoal burner9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier9_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate9", cityId) end
function M.set_furrier9_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate9", cityId, v); print(string.format("furrier9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer9_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate9", cityId) end
function M.set_dyer9_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate9", cityId, v); print(string.format("dyer9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler9_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate9", cityId) end
function M.set_saddler9_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate9", cityId, v); print(string.format("saddler9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer9_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate9", cityId) end
function M.set_armorer9_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate9", cityId, v); print(string.format("armorer9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer9_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate9", cityId) end
function M.set_bowyer9_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate9", cityId, v); print(string.format("bowyer9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright9_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate9", cityId) end
function M.set_cartwright9_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate9", cityId, v); print(string.format("cartwright9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter9_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate9", cityId) end
function M.set_carpenter9_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate9", cityId, v); print(string.format("carpenter9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker9_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate9", cityId) end
function M.set_ropemaker9_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate9", cityId, v); print(string.format("ropemaker9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper9_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate9", cityId) end
function M.set_cooper9_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate9", cityId, v); print(string.format("cooper9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner9_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate9", cityId) end
function M.set_spinner9_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate9", cityId, v); print(string.format("spinner9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner9_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate9", cityId) end
function M.set_turner9_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate9", cityId, v); print(string.format("turner9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter9_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate9", cityId) end
function M.set_stonecutter9_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate9", cityId, v); print(string.format("stonecutter9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler9_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate9", cityId) end
function M.set_cobbler9_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate9", cityId, v); print(string.format("cobbler9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher9_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate9", cityId) end
function M.set_butcher9_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate9", cityId, v); print(string.format("butcher9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker9_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate9", cityId) end
function M.set_baker9_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate9", cityId, v); print(string.format("baker9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd9_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate9", cityId) end
function M.set_shepherd9_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate9", cityId, v); print(string.format("shepherd9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy9_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate9", cityId) end
function M.set_dairy9_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate9", cityId, v); print(string.format("dairy9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster9_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate9", cityId) end
function M.set_brewmaster9_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate9", cityId, v); print(string.format("brewmaster9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller9_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate9", cityId) end
function M.set_miller9_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate9", cityId, v); print(string.format("miller9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery9_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate9", cityId) end
function M.set_fishery9_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate9", cityId, v); print(string.format("fishery9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler9_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate9", cityId) end
function M.set_chandler9_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate9", cityId, v); print(string.format("chandler9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater9_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate9", cityId) end
function M.set_goldbeater9_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate9", cityId, v); print(string.format("goldbeater9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter9_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate9", cityId) end
function M.set_potter9_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate9", cityId, v); print(string.format("potter9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler9_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate9", cityId) end
function M.set_fowler9_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate9", cityId, v); print(string.format("fowler9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner9_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate9", cityId) end
function M.set_vintner9_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate9", cityId, v); print(string.format("vintner9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller9_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate9", cityId) end
function M.set_distiller9_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate9", cityId, v); print(string.format("distiller9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook9_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate9", cityId) end
function M.set_cook9_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate9", cityId, v); print(string.format("cook9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker9_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate9", cityId) end
function M.set_brickmaker9_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate9", cityId, v); print(string.format("brickmaker9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse9_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate9", cityId) end
function M.set_bathhouse9_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate9", cityId, v); print(string.format("bathhouse9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks16_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate16", cityId) end
function M.set_barracks16_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate16", cityId, v); print(string.format("barracks16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school9_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate9", cityId) end
function M.set_school9_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate9", cityId, v); print(string.format("school9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library9_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate9", cityId) end
function M.set_library9_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate9", cityId, v); print(string.format("library9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine9_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate9", cityId) end
function M.set_mine9_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate9", cityId, v); print(string.format("mine9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse9_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate9", cityId) end
function M.set_warehouse9_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate9", cityId, v); print(string.format("warehouse9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison9_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate9", cityId) end
function M.set_garrison9_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate9", cityId, v); print(string.format("garrison9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery9_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate9", cityId) end
function M.set_monastery9_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate9", cityId, v); print(string.format("monastery9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral9_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate9", cityId) end
function M.set_cathedral9_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate9", cityId, v); print(string.format("cathedral9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall9_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate9", cityId) end
function M.set_town_hall9_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate9", cityId, v); print(string.format("town hall9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market9_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate9", cityId) end
function M.set_market9_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate9", cityId, v); print(string.format("market9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor9_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate9", cityId) end
function M.set_harbor9_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate9", cityId, v); print(string.format("harbor9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse9_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate9", cityId) end
function M.set_guardhouse9_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate9", cityId, v); print(string.format("guardhouse9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse9_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate9", cityId) end
function M.set_courthouse9_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate9", cityId, v); print(string.format("courthouse9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.univ_hall9_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate9", cityId) end
function M.set_univ_hall9_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate9", cityId, v); print(string.format("university hall9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle9_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate9", cityId) end
function M.set_castle9_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate9", cityId, v); print(string.format("castle9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well9_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate9", cityId) end
function M.set_well9_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate9", cityId, v); print(string.format("well9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge9_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate9", cityId) end
function M.set_bridge9_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate9", cityId, v); print(string.format("bridge9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall9_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate9", cityId) end
function M.set_wall9_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate9", cityId, v); print(string.format("wall9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower9_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate9", cityId) end
function M.set_tower9_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate9", cityId, v); print(string.format("tower9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum9_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate9", cityId) end
function M.set_forum9_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate9", cityId, v); print(string.format("forum9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary9_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate9", cityId) end
function M.set_granary9_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate9", cityId, v); print(string.format("granary9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison9_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate9", cityId) end
function M.set_prison9_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate9", cityId, v); print(string.format("prison9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock9_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate9", cityId) end
function M.set_harbor_dock9_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate9", cityId, v); print(string.format("harbor dock9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house9_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate9", cityId) end
function M.set_guild_house9_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate9", cityId, v); print(string.format("guild house9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house9_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate9", cityId) end
function M.set_house9_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate9", cityId, v); print(string.format("house9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel9_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate9", cityId) end
function M.set_chapel9_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate9", cityId, v); print(string.format("chapel9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital9_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate9", cityId) end
function M.set_hospital9_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate9", cityId, v); print(string.format("hospital9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel9_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate9", cityId) end
function M.set_brothel9_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate9", cityId, v); print(string.format("brothel9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university9_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate9", cityId) end
function M.set_university9_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate9", cityId, v); print(string.format("university9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls9_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate9", cityId) end
function M.set_harbor_walls9_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate9", cityId, v); print(string.format("harbor walls9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse9_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate9", cityId) end
function M.set_schoolhouse9_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate9", cityId, v); print(string.format("schoolhouse9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall9_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate9", cityId) end
function M.set_library_hall9_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate9", cityId, v); print(string.format("library hall9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber9_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate9", cityId) end
function M.set_barber9_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate9", cityId, v); print(string.format("barber9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor10_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate10", cityId) end
function M.set_contor10_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate10", cityId, v); print(string.format("contor10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house10_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate10", cityId) end
function M.set_dice_house10_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate10", cityId, v); print(string.format("dice house10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves10_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate10", cityId) end
function M.set_thieves10_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate10", cityId, v); print(string.format("thieves guild10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_ws10_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate10", cityId) end
function M.set_ropemaker_ws10_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate10", cityId, v); print(string.format("ropemaker workshop10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery10_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate10", cityId) end
function M.set_tannery10_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate10", cityId, v); print(string.format("tannery10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving10_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate10", cityId) end
function M.set_weaving10_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate10", cityId, v); print(string.format("weaving mill10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint10_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate10", cityId) end
function M.set_mint10_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate10", cityId, v); print(string.format("mint10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden10_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate10", cityId) end
function M.set_herb_garden10_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate10", cityId, v); print(string.format("herb garden10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard10_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate10", cityId) end
function M.set_vineyard10_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate10", cityId, v); print(string.format("vineyard10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery10_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate10", cityId) end
function M.set_pottery10_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate10", cityId, v); print(string.format("pottery10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor10_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate10", cityId) end
function M.set_tailor10_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate10", cityId, v); print(string.format("tailor10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern10_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate10", cityId) end
function M.set_tavern10_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate10", cityId, v); print(string.format("tavern10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary10_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate10", cityId) end
function M.set_apothecary10_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate10", cityId, v); print(string.format("apothecary10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith10_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate10", cityId) end
function M.set_goldsmith10_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate10", cityId, v); print(string.format("goldsmith10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler10_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate10", cityId) end
function M.set_jeweler10_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate10", cityId, v); print(string.format("jeweler10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer10_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate10", cityId) end
function M.set_perfumer10_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate10", cityId, v); print(string.format("perfumer10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker10_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate10", cityId) end
function M.set_soapmaker10_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate10", cityId, v); print(string.format("soapmaker10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker10_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate10", cityId) end
function M.set_candlemaker10_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate10", cityId, v); print(string.format("candlemaker10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill10_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate10", cityId) end
function M.set_papermill10_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate10", cityId, v); print(string.format("papermill10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing10_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate10", cityId) end
function M.set_printing10_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate10", cityId, v); print(string.format("printing house10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker10_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate10", cityId) end
function M.set_toolmaker10_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate10", cityId, v); print(string.format("toolmaker10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal10_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate10", cityId) end
function M.set_charcoal10_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate10", cityId, v); print(string.format("charcoal burner10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier10_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate10", cityId) end
function M.set_furrier10_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate10", cityId, v); print(string.format("furrier10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer10_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate10", cityId) end
function M.set_dyer10_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate10", cityId, v); print(string.format("dyer10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler10_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate10", cityId) end
function M.set_saddler10_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate10", cityId, v); print(string.format("saddler10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer10_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate10", cityId) end
function M.set_armorer10_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate10", cityId, v); print(string.format("armorer10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer10_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate10", cityId) end
function M.set_bowyer10_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate10", cityId, v); print(string.format("bowyer10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright10_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate10", cityId) end
function M.set_cartwright10_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate10", cityId, v); print(string.format("cartwright10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter10_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate10", cityId) end
function M.set_carpenter10_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate10", cityId, v); print(string.format("carpenter10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker10_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate10", cityId) end
function M.set_ropemaker10_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate10", cityId, v); print(string.format("ropemaker10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper10_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate10", cityId) end
function M.set_cooper10_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate10", cityId, v); print(string.format("cooper10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner10_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate10", cityId) end
function M.set_spinner10_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate10", cityId, v); print(string.format("spinner10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner10_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate10", cityId) end
function M.set_turner10_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate10", cityId, v); print(string.format("turner10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter10_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate10", cityId) end
function M.set_stonecutter10_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate10", cityId, v); print(string.format("stonecutter10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler10_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate10", cityId) end
function M.set_cobbler10_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate10", cityId, v); print(string.format("cobbler10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher10_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate10", cityId) end
function M.set_butcher10_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate10", cityId, v); print(string.format("butcher10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker10_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate10", cityId) end
function M.set_baker10_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate10", cityId, v); print(string.format("baker10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd10_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate10", cityId) end
function M.set_shepherd10_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate10", cityId, v); print(string.format("shepherd10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy10_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate10", cityId) end
function M.set_dairy10_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate10", cityId, v); print(string.format("dairy10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster10_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate10", cityId) end
function M.set_brewmaster10_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate10", cityId, v); print(string.format("brewmaster10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller10_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate10", cityId) end
function M.set_miller10_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate10", cityId, v); print(string.format("miller10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery10_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate10", cityId) end
function M.set_fishery10_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate10", cityId, v); print(string.format("fishery10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler10_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate10", cityId) end
function M.set_chandler10_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate10", cityId, v); print(string.format("chandler10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker10_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate10", cityId) end
function M.set_brickmaker10_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate10", cityId, v); print(string.format("brickmaker10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter10_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate10", cityId) end
function M.set_potter10_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate10", cityId, v); print(string.format("potter10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower10_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate10", cityId) end
function M.set_glassblower10_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate10", cityId, v); print(string.format("glassblower10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater10_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate10", cityId) end
function M.set_goldbeater10_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate10", cityId, v); print(string.format("goldbeater10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler10_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate10", cityId) end
function M.set_fowler10_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate10", cityId, v); print(string.format("fowler10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner10_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate10", cityId) end
function M.set_vintner10_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate10", cityId, v); print(string.format("vintner10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller10_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate10", cityId) end
function M.set_distiller10_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate10", cityId, v); print(string.format("distiller10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook10_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate10", cityId) end
function M.set_cook10_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate10", cityId, v); print(string.format("cook10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate", cityId) end
function M.set_glassblower_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate", cityId, v); print(string.format("glassblower level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower2_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate2", cityId) end
function M.set_glassblower2_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate2", cityId, v); print(string.format("glassblower2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower3_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate3", cityId) end
function M.set_glassblower3_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate3", cityId, v); print(string.format("glassblower3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower4_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate4", cityId) end
function M.set_glassblower4_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate4", cityId, v); print(string.format("glassblower4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower5_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate5", cityId) end
function M.set_glassblower5_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate5", cityId, v); print(string.format("glassblower5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower6_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate6", cityId) end
function M.set_glassblower6_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate6", cityId, v); print(string.format("glassblower6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower7_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate7", cityId) end
function M.set_glassblower7_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate7", cityId, v); print(string.format("glassblower7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower8_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate8", cityId) end
function M.set_glassblower8_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate8", cityId, v); print(string.format("glassblower8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower9_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate9", cityId) end
function M.set_glassblower9_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate9", cityId, v); print(string.format("glassblower9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber10_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate10", cityId) end
function M.set_barber10_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate10", cityId, v); print(string.format("barber10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse10_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate10", cityId) end
function M.set_bathhouse10_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate10", cityId, v); print(string.format("bathhouse10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge10_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate10", cityId) end
function M.set_bridge10_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate10", cityId, v); print(string.format("bridge10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel10_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate10", cityId) end
function M.set_brothel10_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate10", cityId, v); print(string.format("brothel10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle10_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate10", cityId) end
function M.set_castle10_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate10", cityId, v); print(string.format("castle10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral10_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate10", cityId) end
function M.set_cathedral10_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate10", cityId, v); print(string.format("cathedral10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel10_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate10", cityId) end
function M.set_chapel10_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate10", cityId, v); print(string.format("chapel10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse10_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate10", cityId) end
function M.set_courthouse10_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate10", cityId, v); print(string.format("courthouse10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum10_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate10", cityId) end
function M.set_forum10_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate10", cityId, v); print(string.format("forum10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison10_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate10", cityId) end
function M.set_garrison10_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate10", cityId, v); print(string.format("garrison10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates10_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate10", cityId) end
function M.set_gates10_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate10", cityId, v); print(string.format("gates10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary10_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate10", cityId) end
function M.set_granary10_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate10", cityId, v); print(string.format("granary10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse10_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate10", cityId) end
function M.set_guardhouse10_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate10", cityId, v); print(string.format("guardhouse10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house10_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate10", cityId) end
function M.set_guild_house10_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate10", cityId, v); print(string.format("guild house10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor10_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate10", cityId) end
function M.set_harbor10_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate10", cityId, v); print(string.format("harbor10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock10_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate10", cityId) end
function M.set_harbor_dock10_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate10", cityId, v); print(string.format("harbor dock10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls10_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate10", cityId) end
function M.set_harbor_walls10_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate10", cityId, v); print(string.format("harbor walls10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital10_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate10", cityId) end
function M.set_hospital10_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate10", cityId, v); print(string.format("hospital10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house10_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate10", cityId) end
function M.set_house10_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate10", cityId, v); print(string.format("house10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library10_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate10", cityId) end
function M.set_library10_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate10", cityId, v); print(string.format("library10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall10_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate10", cityId) end
function M.set_library_hall10_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate10", cityId, v); print(string.format("library hall10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market10_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate10", cityId) end
function M.set_market10_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate10", cityId, v); print(string.format("market10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine10_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate10", cityId) end
function M.set_mine10_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate10", cityId, v); print(string.format("mine10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery10_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate10", cityId) end
function M.set_monastery10_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate10", cityId, v); print(string.format("monastery10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison10_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate10", cityId) end
function M.set_prison10_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate10", cityId, v); print(string.format("prison10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school10_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate10", cityId) end
function M.set_school10_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate10", cityId, v); print(string.format("school10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse10_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate10", cityId) end
function M.set_schoolhouse10_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate10", cityId, v); print(string.format("schoolhouse10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry_tower10_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate10", cityId) end
function M.set_sentry_tower10_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate10", cityId, v); print(string.format("sentry tower10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables10_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate10", cityId) end
function M.set_stables10_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate10", cityId, v); print(string.format("stables10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower10_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate10", cityId) end
function M.set_tower10_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate10", cityId, v); print(string.format("tower10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall10_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate10", cityId) end
function M.set_town_hall10_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate10", cityId, v); print(string.format("town hall10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university10_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate10", cityId) end
function M.set_university10_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate10", cityId, v); print(string.format("university10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university_hall10_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate10", cityId) end
function M.set_university_hall10_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate10", cityId, v); print(string.format("university hall10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall10_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate10", cityId) end
function M.set_wall10_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate10", cityId, v); print(string.format("wall10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse10_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate10", cityId) end
function M.set_warehouse10_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate10", cityId, v); print(string.format("warehouse10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well10_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate10", cityId) end
function M.set_well10_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate10", cityId, v); print(string.format("well10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates8_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate8", cityId) end
function M.set_gates8_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate8", cityId, v); print(string.format("gates8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates9_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate9", cityId) end
function M.set_gates9_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate9", cityId, v); print(string.format("gates9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry_tower8_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate8", cityId) end
function M.set_sentry_tower8_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate8", cityId, v); print(string.format("sentry tower8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry_tower9_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate9", cityId) end
function M.set_sentry_tower9_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate9", cityId, v); print(string.format("sentry tower9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables8_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate8", cityId) end
function M.set_stables8_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate8", cityId, v); print(string.format("stables8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables9_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate9", cityId) end
function M.set_stables9_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate9", cityId, v); print(string.format("stables9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church2_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate2", cityId) end
function M.set_church2_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate2", cityId, v); print(string.format("church2 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church3_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate3", cityId) end
function M.set_church3_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate3", cityId, v); print(string.format("church3 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church4_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate4", cityId) end
function M.set_church4_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate4", cityId, v); print(string.format("church4 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church5_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate5", cityId) end
function M.set_church5_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate5", cityId, v); print(string.format("church5 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church6_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate6", cityId) end
function M.set_church6_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate6", cityId, v); print(string.format("church6 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church7_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate7", cityId) end
function M.set_church7_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate7", cityId, v); print(string.format("church7 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church8_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate8", cityId) end
function M.set_church8_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate8", cityId, v); print(string.format("church8 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church9_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate9", cityId) end
function M.set_church9_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate9", cityId, v); print(string.format("church9 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church10_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate10", cityId) end
function M.set_church10_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate10", cityId, v); print(string.format("church10 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall11_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate11", cityId) end
function M.set_town_hall11_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate11", cityId, v); print(string.format("town hall11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university11_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate11", cityId) end
function M.set_university11_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate11", cityId, v); print(string.format("university11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall11_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate11", cityId) end
function M.set_wall11_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate11", cityId, v); print(string.format("wall11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary11_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate11", cityId) end
function M.set_apothecary11_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate11", cityId, v); print(string.format("apothecary11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker11_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate11", cityId) end
function M.set_baker11_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate11", cityId, v); print(string.format("baker11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber11_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate11", cityId) end
function M.set_barber11_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate11", cityId, v); print(string.format("barber11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse11_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate11", cityId) end
function M.set_bathhouse11_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate11", cityId, v); print(string.format("bathhouse11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer11_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate11", cityId) end
function M.set_bowyer11_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate11", cityId, v); print(string.format("bowyer11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster11_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate11", cityId) end
function M.set_brewmaster11_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate11", cityId, v); print(string.format("brewmaster11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker11_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate11", cityId) end
function M.set_brickmaker11_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate11", cityId, v); print(string.format("brickmaker11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge11_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate11", cityId) end
function M.set_bridge11_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate11", cityId, v); print(string.format("bridge11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel11_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate11", cityId) end
function M.set_brothel11_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate11", cityId, v); print(string.format("brothel11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher11_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate11", cityId) end
function M.set_butcher11_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate11", cityId, v); print(string.format("butcher11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker11_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate11", cityId) end
function M.set_candlemaker11_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate11", cityId, v); print(string.format("candlemaker11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter11_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate11", cityId) end
function M.set_carpenter11_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate11", cityId, v); print(string.format("carpenter11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright11_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate11", cityId) end
function M.set_cartwright11_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate11", cityId, v); print(string.format("cartwright11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle11_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate11", cityId) end
function M.set_castle11_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate11", cityId, v); print(string.format("castle11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral11_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate11", cityId) end
function M.set_cathedral11_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate11", cityId, v); print(string.format("cathedral11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler11_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate11", cityId) end
function M.set_chandler11_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate11", cityId, v); print(string.format("chandler11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel11_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate11", cityId) end
function M.set_chapel11_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate11", cityId, v); print(string.format("chapel11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church11_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate11", cityId) end
function M.set_church11_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate11", cityId, v); print(string.format("church11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler11_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate11", cityId) end
function M.set_cobbler11_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate11", cityId, v); print(string.format("cobbler11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor11_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate11", cityId) end
function M.set_contor11_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate11", cityId, v); print(string.format("contor11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook11_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate11", cityId) end
function M.set_cook11_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate11", cityId, v); print(string.format("cook11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper11_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate11", cityId) end
function M.set_cooper11_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate11", cityId, v); print(string.format("cooper11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse11_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate11", cityId) end
function M.set_courthouse11_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate11", cityId, v); print(string.format("courthouse11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy11_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate11", cityId) end
function M.set_dairy11_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate11", cityId, v); print(string.format("dairy11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house11_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate11", cityId) end
function M.set_dice_house11_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate11", cityId, v); print(string.format("dice house11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller11_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate11", cityId) end
function M.set_distiller11_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate11", cityId, v); print(string.format("distiller11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer11_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate11", cityId) end
function M.set_dyer11_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate11", cityId, v); print(string.format("dyer11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery11_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate11", cityId) end
function M.set_fishery11_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate11", cityId, v); print(string.format("fishery11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum11_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate11", cityId) end
function M.set_forum11_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate11", cityId, v); print(string.format("forum11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler11_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate11", cityId) end
function M.set_fowler11_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate11", cityId, v); print(string.format("fowler11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier11_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate11", cityId) end
function M.set_furrier11_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate11", cityId, v); print(string.format("furrier11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison11_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate11", cityId) end
function M.set_garrison11_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate11", cityId, v); print(string.format("garrison11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates11_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate11", cityId) end
function M.set_gates11_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate11", cityId, v); print(string.format("gates11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower11_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate11", cityId) end
function M.set_glassblower11_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate11", cityId, v); print(string.format("glassblower11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater11_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate11", cityId) end
function M.set_goldbeater11_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate11", cityId, v); print(string.format("goldbeater11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith11_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate11", cityId) end
function M.set_goldsmith11_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate11", cityId, v); print(string.format("goldsmith11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary11_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate11", cityId) end
function M.set_granary11_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate11", cityId, v); print(string.format("granary11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse11_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate11", cityId) end
function M.set_guardhouse11_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate11", cityId, v); print(string.format("guardhouse11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house11_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate11", cityId) end
function M.set_guild_house11_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate11", cityId, v); print(string.format("guild house11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor11_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate11", cityId) end
function M.set_harbor11_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate11", cityId, v); print(string.format("harbor11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock11_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate11", cityId) end
function M.set_harbor_dock11_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate11", cityId, v); print(string.format("harbor dock11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls11_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate11", cityId) end
function M.set_harbor_walls11_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate11", cityId, v); print(string.format("harbor walls11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden11_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate11", cityId) end
function M.set_herb_garden11_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate11", cityId, v); print(string.format("herb garden11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital11_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate11", cityId) end
function M.set_hospital11_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate11", cityId, v); print(string.format("hospital11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house11_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate11", cityId) end
function M.set_house11_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate11", cityId, v); print(string.format("house11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler11_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate11", cityId) end
function M.set_jeweler11_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate11", cityId, v); print(string.format("jeweler11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library11_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate11", cityId) end
function M.set_library11_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate11", cityId, v); print(string.format("library11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall11_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate11", cityId) end
function M.set_library_hall11_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate11", cityId, v); print(string.format("library hall11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market11_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate11", cityId) end
function M.set_market11_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate11", cityId, v); print(string.format("market11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller11_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate11", cityId) end
function M.set_miller11_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate11", cityId, v); print(string.format("miller11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine11_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate11", cityId) end
function M.set_mine11_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate11", cityId, v); print(string.format("mine11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint11_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate11", cityId) end
function M.set_mint11_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate11", cityId, v); print(string.format("mint11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery11_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate11", cityId) end
function M.set_monastery11_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate11", cityId, v); print(string.format("monastery11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill11_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate11", cityId) end
function M.set_papermill11_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate11", cityId, v); print(string.format("papermill11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer11_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate11", cityId) end
function M.set_perfumer11_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate11", cityId, v); print(string.format("perfumer11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter11_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate11", cityId) end
function M.set_potter11_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate11", cityId, v); print(string.format("potter11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery11_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate11", cityId) end
function M.set_pottery11_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate11", cityId, v); print(string.format("pottery11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing_house11_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate11", cityId) end
function M.set_printing_house11_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate11", cityId, v); print(string.format("printing house11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker11_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate11", cityId) end
function M.set_ropemaker11_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate11", cityId, v); print(string.format("ropemaker11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_workshop11_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate11", cityId) end
function M.set_ropemaker_workshop11_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate11", cityId, v); print(string.format("ropemaking workshop11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler11_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate11", cityId) end
function M.set_saddler11_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate11", cityId, v); print(string.format("saddler11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school11_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate11", cityId) end
function M.set_school11_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate11", cityId, v); print(string.format("school11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse11_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate11", cityId) end
function M.set_schoolhouse11_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate11", cityId, v); print(string.format("schoolhouse11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry_tower11_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate11", cityId) end
function M.set_sentry_tower11_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate11", cityId, v); print(string.format("sentry tower11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables11_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate11", cityId) end
function M.set_stables11_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate11", cityId, v); print(string.format("stables11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter11_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate11", cityId) end
function M.set_stonecutter11_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate11", cityId, v); print(string.format("stonecutter11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor11_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate11", cityId) end
function M.set_tailor11_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate11", cityId, v); print(string.format("tailor11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery11_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate11", cityId) end
function M.set_tannery11_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate11", cityId, v); print(string.format("tannery11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern11_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate11", cityId) end
function M.set_tavern11_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate11", cityId, v); print(string.format("tavern11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves_guild11_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate11", cityId) end
function M.set_thieves_guild11_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate11", cityId, v); print(string.format("thieves guild11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker11_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate11", cityId) end
function M.set_toolmaker11_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate11", cityId, v); print(string.format("toolmaker11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower11_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate11", cityId) end
function M.set_tower11_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate11", cityId, v); print(string.format("tower11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall12_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate12", cityId) end
function M.set_town_hall12_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate12", cityId, v); print(string.format("town hall12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner11_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate11", cityId) end
function M.set_turner11_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate11", cityId, v); print(string.format("turner11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university12_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate12", cityId) end
function M.set_university12_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate12", cityId, v); print(string.format("university12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university_hall11_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate11", cityId) end
function M.set_university_hall11_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate11", cityId, v); print(string.format("university hall11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard11_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate11", cityId) end
function M.set_vineyard11_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate11", cityId, v); print(string.format("vineyard11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner11_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate11", cityId) end
function M.set_vintner11_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate11", cityId, v); print(string.format("vintner11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall12_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate12", cityId) end
function M.set_wall12_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate12", cityId, v); print(string.format("wall12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse11_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate11", cityId) end
function M.set_warehouse11_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate11", cityId, v); print(string.format("warehouse11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving_mill11_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate11", cityId) end
function M.set_weaving_mill11_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate11", cityId, v); print(string.format("weaving mill11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well11_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate11", cityId) end
function M.set_well11_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate11", cityId, v); print(string.format("well11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer11_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate11", cityId) end
function M.set_armorer11_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate11", cityId, v); print(string.format("armorer11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker12_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate12", cityId) end
function M.set_candlemaker12_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate12", cityId, v); print(string.format("candlemaker12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter12_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate12", cityId) end
function M.set_carpenter12_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate12", cityId, v); print(string.format("carpenter12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright12_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate12", cityId) end
function M.set_cartwright12_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate12", cityId, v); print(string.format("cartwright12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler12_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate12", cityId) end
function M.set_chandler12_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate12", cityId, v); print(string.format("chandler12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal11_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate11", cityId) end
function M.set_charcoal11_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate11", cityId, v); print(string.format("charcoal burner11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal12_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate12", cityId) end
function M.set_charcoal12_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate12", cityId, v); print(string.format("charcoal burner12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church12_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate12", cityId) end
function M.set_church12_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate12", cityId, v); print(string.format("church12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler12_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate12", cityId) end
function M.set_cobbler12_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate12", cityId, v); print(string.format("cobbler12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor12_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate12", cityId) end
function M.set_contor12_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate12", cityId, v); print(string.format("contor12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook12_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate12", cityId) end
function M.set_cook12_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate12", cityId, v); print(string.format("cook12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper12_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate12", cityId) end
function M.set_cooper12_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate12", cityId, v); print(string.format("cooper12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse12_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate12", cityId) end
function M.set_courthouse12_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate12", cityId, v); print(string.format("courthouse12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy12_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate12", cityId) end
function M.set_dairy12_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate12", cityId, v); print(string.format("dairy12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house12_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate12", cityId) end
function M.set_dice_house12_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate12", cityId, v); print(string.format("dice house12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller12_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate12", cityId) end
function M.set_distiller12_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate12", cityId, v); print(string.format("distiller12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer12_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate12", cityId) end
function M.set_dyer12_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate12", cityId, v); print(string.format("dyer12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery12_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate12", cityId) end
function M.set_fishery12_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate12", cityId, v); print(string.format("fishery12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum12_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate12", cityId) end
function M.set_forum12_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate12", cityId, v); print(string.format("forum12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler12_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate12", cityId) end
function M.set_fowler12_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate12", cityId, v); print(string.format("fowler12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier12_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate12", cityId) end
function M.set_furrier12_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate12", cityId, v); print(string.format("furrier12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison12_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate12", cityId) end
function M.set_garrison12_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate12", cityId, v); print(string.format("garrison12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates12_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate12", cityId) end
function M.set_gates12_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate12", cityId, v); print(string.format("gates12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower12_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate12", cityId) end
function M.set_glassblower12_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate12", cityId, v); print(string.format("glassblower12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater12_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate12", cityId) end
function M.set_goldbeater12_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate12", cityId, v); print(string.format("goldbeater12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith12_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate12", cityId) end
function M.set_goldsmith12_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate12", cityId, v); print(string.format("goldsmith12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary12_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate12", cityId) end
function M.set_granary12_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate12", cityId, v); print(string.format("granary12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse12_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate12", cityId) end
function M.set_guardhouse12_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate12", cityId, v); print(string.format("guardhouse12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house12_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate12", cityId) end
function M.set_guild_house12_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate12", cityId, v); print(string.format("guild house12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor12_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate12", cityId) end
function M.set_harbor12_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate12", cityId, v); print(string.format("harbor12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock12_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate12", cityId) end
function M.set_harbor_dock12_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate12", cityId, v); print(string.format("harbor dock12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls12_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate12", cityId) end
function M.set_harbor_walls12_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate12", cityId, v); print(string.format("harbor walls12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden12_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate12", cityId) end
function M.set_herb_garden12_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate12", cityId, v); print(string.format("herb garden12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital12_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate12", cityId) end
function M.set_hospital12_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate12", cityId, v); print(string.format("hospital12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house12_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate12", cityId) end
function M.set_house12_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate12", cityId, v); print(string.format("house12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler12_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate12", cityId) end
function M.set_jeweler12_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate12", cityId, v); print(string.format("jeweler12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library12_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate12", cityId) end
function M.set_library12_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate12", cityId, v); print(string.format("library12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall12_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate12", cityId) end
function M.set_library_hall12_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate12", cityId, v); print(string.format("library hall12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market12_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate12", cityId) end
function M.set_market12_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate12", cityId, v); print(string.format("market12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller12_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate12", cityId) end
function M.set_miller12_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate12", cityId, v); print(string.format("miller12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine12_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate12", cityId) end
function M.set_mine12_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate12", cityId, v); print(string.format("mine12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint12_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate12", cityId) end
function M.set_mint12_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate12", cityId, v); print(string.format("mint12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery12_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate12", cityId) end
function M.set_monastery12_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate12", cityId, v); print(string.format("monastery12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill12_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate12", cityId) end
function M.set_papermill12_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate12", cityId, v); print(string.format("papermill12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer12_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate12", cityId) end
function M.set_perfumer12_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate12", cityId, v); print(string.format("perfumer12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter12_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate12", cityId) end
function M.set_potter12_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate12", cityId, v); print(string.format("potter12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery12_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate12", cityId) end
function M.set_pottery12_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate12", cityId, v); print(string.format("pottery12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing_house12_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate12", cityId) end
function M.set_printing_house12_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate12", cityId, v); print(string.format("printing house12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker12_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate12", cityId) end
function M.set_ropemaker12_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate12", cityId, v); print(string.format("ropemaker12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_workshop12_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate12", cityId) end
function M.set_ropemaker_workshop12_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate12", cityId, v); print(string.format("ropemaking workshop12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler12_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate12", cityId) end
function M.set_saddler12_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate12", cityId, v); print(string.format("saddler12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school12_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate12", cityId) end
function M.set_school12_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate12", cityId, v); print(string.format("school12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse12_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate12", cityId) end
function M.set_schoolhouse12_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate12", cityId, v); print(string.format("schoolhouse12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry_tower12_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate12", cityId) end
function M.set_sentry_tower12_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate12", cityId, v); print(string.format("sentry tower12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables12_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate12", cityId) end
function M.set_stables12_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate12", cityId, v); print(string.format("stables12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter12_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate12", cityId) end
function M.set_stonecutter12_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate12", cityId, v); print(string.format("stonecutter12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor12_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate12", cityId) end
function M.set_tailor12_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate12", cityId, v); print(string.format("tailor12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery12_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate12", cityId) end
function M.set_tannery12_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate12", cityId, v); print(string.format("tannery12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern12_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate12", cityId) end
function M.set_tavern12_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate12", cityId, v); print(string.format("tavern12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves_guild12_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate12", cityId) end
function M.set_thieves_guild12_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate12", cityId, v); print(string.format("thieves guild12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker12_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate12", cityId) end
function M.set_toolmaker12_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate12", cityId, v); print(string.format("toolmaker12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower12_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate12", cityId) end
function M.set_tower12_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate12", cityId, v); print(string.format("tower12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner12_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate12", cityId) end
function M.set_turner12_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate12", cityId, v); print(string.format("turner12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university13_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate13", cityId) end
function M.set_university13_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate13", cityId, v); print(string.format("university13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university_hall12_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate12", cityId) end
function M.set_university_hall12_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate12", cityId, v); print(string.format("university hall12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard12_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate12", cityId) end
function M.set_vineyard12_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate12", cityId, v); print(string.format("vineyard12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner12_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate12", cityId) end
function M.set_vintner12_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate12", cityId, v); print(string.format("vintner12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall13_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate13", cityId) end
function M.set_wall13_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate13", cityId, v); print(string.format("wall13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse12_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate12", cityId) end
function M.set_warehouse12_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate12", cityId, v); print(string.format("warehouse12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving_mill12_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate12", cityId) end
function M.set_weaving_mill12_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate12", cityId, v); print(string.format("weaving mill12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well12_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate12", cityId) end
function M.set_well12_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate12", cityId, v); print(string.format("well12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer12_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate12", cityId) end
function M.set_armorer12_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate12", cityId, v); print(string.format("armorer12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker12_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate12", cityId) end
function M.set_baker12_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate12", cityId, v); print(string.format("baker12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber12_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate12", cityId) end
function M.set_barber12_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate12", cityId, v); print(string.format("barber12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse12_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate12", cityId) end
function M.set_bathhouse12_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate12", cityId, v); print(string.format("bathhouse12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer12_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate12", cityId) end
function M.set_bowyer12_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate12", cityId, v); print(string.format("bowyer12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster12_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate12", cityId) end
function M.set_brewmaster12_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate12", cityId, v); print(string.format("brewmaster12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker12_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate12", cityId) end
function M.set_brickmaker12_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate12", cityId, v); print(string.format("brickmaker12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge12_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate12", cityId) end
function M.set_bridge12_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate12", cityId, v); print(string.format("bridge12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel12_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate12", cityId) end
function M.set_brothel12_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate12", cityId, v); print(string.format("brothel12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher12_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate12", cityId) end
function M.set_butcher12_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate12", cityId, v); print(string.format("butcher12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle12_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate12", cityId) end
function M.set_castle12_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate12", cityId, v); print(string.format("castle12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral12_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate12", cityId) end
function M.set_cathedral12_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate12", cityId, v); print(string.format("cathedral12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler13_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate13", cityId) end
function M.set_chandler13_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate13", cityId, v); print(string.format("chandler13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel12_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate12", cityId) end
function M.set_chapel12_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate12", cityId, v); print(string.format("chapel12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church13_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate13", cityId) end
function M.set_church13_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate13", cityId, v); print(string.format("church13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler13_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate13", cityId) end
function M.set_cobbler13_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate13", cityId, v); print(string.format("cobbler13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor13_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate13", cityId) end
function M.set_contor13_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate13", cityId, v); print(string.format("contor13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook13_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate13", cityId) end
function M.set_cook13_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate13", cityId, v); print(string.format("cook13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper13_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate13", cityId) end
function M.set_cooper13_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate13", cityId, v); print(string.format("cooper13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse13_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate13", cityId) end
function M.set_courthouse13_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate13", cityId, v); print(string.format("courthouse13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy13_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate13", cityId) end
function M.set_dairy13_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate13", cityId, v); print(string.format("dairy13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house13_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate13", cityId) end
function M.set_dice_house13_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate13", cityId, v); print(string.format("dice house13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller13_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate13", cityId) end
function M.set_distiller13_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate13", cityId, v); print(string.format("distiller13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer13_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate13", cityId) end
function M.set_dyer13_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate13", cityId, v); print(string.format("dyer13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery13_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate13", cityId) end
function M.set_fishery13_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate13", cityId, v); print(string.format("fishery13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum13_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate13", cityId) end
function M.set_forum13_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate13", cityId, v); print(string.format("forum13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler13_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate13", cityId) end
function M.set_fowler13_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate13", cityId, v); print(string.format("fowler13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier13_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate13", cityId) end
function M.set_furrier13_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate13", cityId, v); print(string.format("furrier13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison13_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate13", cityId) end
function M.set_garrison13_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate13", cityId, v); print(string.format("garrison13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates13_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate13", cityId) end
function M.set_gates13_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate13", cityId, v); print(string.format("gates13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower13_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate13", cityId) end
function M.set_glassblower13_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate13", cityId, v); print(string.format("glassblower13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater13_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate13", cityId) end
function M.set_goldbeater13_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate13", cityId, v); print(string.format("goldbeater13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith13_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate13", cityId) end
function M.set_goldsmith13_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate13", cityId, v); print(string.format("goldsmith13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary13_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate13", cityId) end
function M.set_granary13_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate13", cityId, v); print(string.format("granary13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse13_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate13", cityId) end
function M.set_guardhouse13_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate13", cityId, v); print(string.format("guardhouse13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house13_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate13", cityId) end
function M.set_guild_house13_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate13", cityId, v); print(string.format("guild house13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor13_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate13", cityId) end
function M.set_harbor13_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate13", cityId, v); print(string.format("harbor13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock13_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate13", cityId) end
function M.set_harbor_dock13_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate13", cityId, v); print(string.format("harbor dock13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls13_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate13", cityId) end
function M.set_harbor_walls13_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate13", cityId, v); print(string.format("harbor walls13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden13_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate13", cityId) end
function M.set_herb_garden13_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate13", cityId, v); print(string.format("herb garden13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital13_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate13", cityId) end
function M.set_hospital13_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate13", cityId, v); print(string.format("hospital13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house13_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate13", cityId) end
function M.set_house13_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate13", cityId, v); print(string.format("house13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler13_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate13", cityId) end
function M.set_jeweler13_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate13", cityId, v); print(string.format("jeweler13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library13_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate13", cityId) end
function M.set_library13_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate13", cityId, v); print(string.format("library13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall13_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate13", cityId) end
function M.set_library_hall13_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate13", cityId, v); print(string.format("library hall13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market13_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate13", cityId) end
function M.set_market13_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate13", cityId, v); print(string.format("market13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller13_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate13", cityId) end
function M.set_miller13_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate13", cityId, v); print(string.format("miller13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine13_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate13", cityId) end
function M.set_mine13_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate13", cityId, v); print(string.format("mine13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint13_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate13", cityId) end
function M.set_mint13_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate13", cityId, v); print(string.format("mint13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery13_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate13", cityId) end
function M.set_monastery13_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate13", cityId, v); print(string.format("monastery13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill13_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate13", cityId) end
function M.set_papermill13_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate13", cityId, v); print(string.format("papermill13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer13_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate13", cityId) end
function M.set_perfumer13_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate13", cityId, v); print(string.format("perfumer13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter13_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate13", cityId) end
function M.set_potter13_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate13", cityId, v); print(string.format("potter13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery13_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate13", cityId) end
function M.set_pottery13_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate13", cityId, v); print(string.format("pottery13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing_house13_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate13", cityId) end
function M.set_printing_house13_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate13", cityId, v); print(string.format("printing house13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker13_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate13", cityId) end
function M.set_ropemaker13_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate13", cityId, v); print(string.format("ropemaker13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_workshop13_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate13", cityId) end
function M.set_ropemaker_workshop13_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate13", cityId, v); print(string.format("ropemaking workshop13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler13_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate13", cityId) end
function M.set_saddler13_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate13", cityId, v); print(string.format("saddler13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school13_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate13", cityId) end
function M.set_school13_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate13", cityId, v); print(string.format("school13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse13_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate13", cityId) end
function M.set_schoolhouse13_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate13", cityId, v); print(string.format("schoolhouse13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry_tower13_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate13", cityId) end
function M.set_sentry_tower13_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate13", cityId, v); print(string.format("sentry tower13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables13_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate13", cityId) end
function M.set_stables13_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate13", cityId, v); print(string.format("stables13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter13_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate13", cityId) end
function M.set_stonecutter13_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate13", cityId, v); print(string.format("stonecutter13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor13_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate13", cityId) end
function M.set_tailor13_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate13", cityId, v); print(string.format("tailor13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery13_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate13", cityId) end
function M.set_tannery13_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate13", cityId, v); print(string.format("tannery13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern13_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate13", cityId) end
function M.set_tavern13_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate13", cityId, v); print(string.format("tavern13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves_guild13_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate13", cityId) end
function M.set_thieves_guild13_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate13", cityId, v); print(string.format("thieves guild13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker13_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate13", cityId) end
function M.set_toolmaker13_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate13", cityId, v); print(string.format("toolmaker13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower13_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate13", cityId) end
function M.set_tower13_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate13", cityId, v); print(string.format("tower13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner13_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate13", cityId) end
function M.set_turner13_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate13", cityId, v); print(string.format("turner13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university14_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate14", cityId) end
function M.set_university14_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate14", cityId, v); print(string.format("university14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university_hall13_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate13", cityId) end
function M.set_university_hall13_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate13", cityId, v); print(string.format("university hall13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard13_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate13", cityId) end
function M.set_vineyard13_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate13", cityId, v); print(string.format("vineyard13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner13_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate13", cityId) end
function M.set_vintner13_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate13", cityId, v); print(string.format("vintner13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall14_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate14", cityId) end
function M.set_wall14_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate14", cityId, v); print(string.format("wall14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse13_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate13", cityId) end
function M.set_warehouse13_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate13", cityId, v); print(string.format("warehouse13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving_mill13_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate13", cityId) end
function M.set_weaving_mill13_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate13", cityId, v); print(string.format("weaving mill13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well13_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate13", cityId) end
function M.set_well13_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate13", cityId, v); print(string.format("well13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer13_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate13", cityId) end
function M.set_armorer13_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate13", cityId, v); print(string.format("armorer13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker13_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate13", cityId) end
function M.set_baker13_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate13", cityId, v); print(string.format("baker13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber13_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate13", cityId) end
function M.set_barber13_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate13", cityId, v); print(string.format("barber13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse13_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate13", cityId) end
function M.set_bathhouse13_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate13", cityId, v); print(string.format("bathhouse13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer13_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate13", cityId) end
function M.set_bowyer13_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate13", cityId, v); print(string.format("bowyer13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster13_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate13", cityId) end
function M.set_brewmaster13_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate13", cityId, v); print(string.format("brewmaster13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker13_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate13", cityId) end
function M.set_brickmaker13_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate13", cityId, v); print(string.format("brickmaker13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge13_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate13", cityId) end
function M.set_bridge13_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate13", cityId, v); print(string.format("bridge13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel13_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate13", cityId) end
function M.set_brothel13_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate13", cityId, v); print(string.format("brothel13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher13_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate13", cityId) end
function M.set_butcher13_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate13", cityId, v); print(string.format("butcher13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker13_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate13", cityId) end
function M.set_candlemaker13_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate13", cityId, v); print(string.format("candlemaker13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter13_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate13", cityId) end
function M.set_carpenter13_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate13", cityId, v); print(string.format("carpenter13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright13_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate13", cityId) end
function M.set_cartwright13_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate13", cityId, v); print(string.format("cartwright13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle13_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate13", cityId) end
function M.set_castle13_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate13", cityId, v); print(string.format("castle13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral13_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate13", cityId) end
function M.set_cathedral13_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate13", cityId, v); print(string.format("cathedral13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel13_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate13", cityId) end
function M.set_chapel13_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate13", cityId, v); print(string.format("chapel13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal13_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate13", cityId) end
function M.set_charcoal13_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate13", cityId, v); print(string.format("charcoal burner13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church14_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate14", cityId) end
function M.set_church14_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate14", cityId, v); print(string.format("church14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler14_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate14", cityId) end
function M.set_cobbler14_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate14", cityId, v); print(string.format("cobbler14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor14_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate14", cityId) end
function M.set_contor14_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate14", cityId, v); print(string.format("contor14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook14_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate14", cityId) end
function M.set_cook14_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate14", cityId, v); print(string.format("cook14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper14_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate14", cityId) end
function M.set_cooper14_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate14", cityId, v); print(string.format("cooper14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse14_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate14", cityId) end
function M.set_courthouse14_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate14", cityId, v); print(string.format("courthouse14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy14_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate14", cityId) end
function M.set_dairy14_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate14", cityId, v); print(string.format("dairy14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house14_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate14", cityId) end
function M.set_dice_house14_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate14", cityId, v); print(string.format("dice house14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller14_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate14", cityId) end
function M.set_distiller14_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate14", cityId, v); print(string.format("distiller14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer14_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate14", cityId) end
function M.set_dyer14_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate14", cityId, v); print(string.format("dyer14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery14_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate14", cityId) end
function M.set_fishery14_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate14", cityId, v); print(string.format("fishery14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum14_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate14", cityId) end
function M.set_forum14_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate14", cityId, v); print(string.format("forum14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler14_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate14", cityId) end
function M.set_fowler14_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate14", cityId, v); print(string.format("fowler14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier14_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate14", cityId) end
function M.set_furrier14_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate14", cityId, v); print(string.format("furrier14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison14_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate14", cityId) end
function M.set_garrison14_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate14", cityId, v); print(string.format("garrison14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates14_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate14", cityId) end
function M.set_gates14_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate14", cityId, v); print(string.format("gates14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower14_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate14", cityId) end
function M.set_glassblower14_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate14", cityId, v); print(string.format("glassblower14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater14_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate14", cityId) end
function M.set_goldbeater14_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate14", cityId, v); print(string.format("goldbeater14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith14_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate14", cityId) end
function M.set_goldsmith14_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate14", cityId, v); print(string.format("goldsmith14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary14_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate14", cityId) end
function M.set_granary14_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate14", cityId, v); print(string.format("granary14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse14_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate14", cityId) end
function M.set_guardhouse14_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate14", cityId, v); print(string.format("guardhouse14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house14_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate14", cityId) end
function M.set_guild_house14_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate14", cityId, v); print(string.format("guild house14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor14_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate14", cityId) end
function M.set_harbor14_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate14", cityId, v); print(string.format("harbor14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock14_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate14", cityId) end
function M.set_harbor_dock14_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate14", cityId, v); print(string.format("harbor dock14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls14_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate14", cityId) end
function M.set_harbor_walls14_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate14", cityId, v); print(string.format("harbor walls14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden14_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate14", cityId) end
function M.set_herb_garden14_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate14", cityId, v); print(string.format("herb garden14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital14_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate14", cityId) end
function M.set_hospital14_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate14", cityId, v); print(string.format("hospital14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house14_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate14", cityId) end
function M.set_house14_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate14", cityId, v); print(string.format("house14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler14_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate14", cityId) end
function M.set_jeweler14_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate14", cityId, v); print(string.format("jeweler14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library14_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate14", cityId) end
function M.set_library14_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate14", cityId, v); print(string.format("library14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall14_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate14", cityId) end
function M.set_library_hall14_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate14", cityId, v); print(string.format("library hall14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market14_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate14", cityId) end
function M.set_market14_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate14", cityId, v); print(string.format("market14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller14_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate14", cityId) end
function M.set_miller14_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate14", cityId, v); print(string.format("miller14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine14_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate14", cityId) end
function M.set_mine14_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate14", cityId, v); print(string.format("mine14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint14_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate14", cityId) end
function M.set_mint14_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate14", cityId, v); print(string.format("mint14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery14_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate14", cityId) end
function M.set_monastery14_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate14", cityId, v); print(string.format("monastery14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill14_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate14", cityId) end
function M.set_papermill14_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate14", cityId, v); print(string.format("papermill14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer14_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate14", cityId) end
function M.set_perfumer14_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate14", cityId, v); print(string.format("perfumer14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter14_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate14", cityId) end
function M.set_potter14_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate14", cityId, v); print(string.format("potter14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery14_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate14", cityId) end
function M.set_pottery14_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate14", cityId, v); print(string.format("pottery14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing_house14_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate14", cityId) end
function M.set_printing_house14_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate14", cityId, v); print(string.format("printing house14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker14_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate14", cityId) end
function M.set_ropemaker14_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate14", cityId, v); print(string.format("ropemaker14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_workshop14_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate14", cityId) end
function M.set_ropemaker_workshop14_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate14", cityId, v); print(string.format("ropemaking workshop14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler14_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate14", cityId) end
function M.set_saddler14_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate14", cityId, v); print(string.format("saddler14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school14_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate14", cityId) end
function M.set_school14_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate14", cityId, v); print(string.format("school14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse14_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate14", cityId) end
function M.set_schoolhouse14_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate14", cityId, v); print(string.format("schoolhouse14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry_tower14_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate14", cityId) end
function M.set_sentry_tower14_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate14", cityId, v); print(string.format("sentry tower14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables14_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate14", cityId) end
function M.set_stables14_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate14", cityId, v); print(string.format("stables14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter14_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate14", cityId) end
function M.set_stonecutter14_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate14", cityId, v); print(string.format("stonecutter14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor14_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate14", cityId) end
function M.set_tailor14_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate14", cityId, v); print(string.format("tailor14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery14_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate14", cityId) end
function M.set_tannery14_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate14", cityId, v); print(string.format("tannery14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern14_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate14", cityId) end
function M.set_tavern14_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate14", cityId, v); print(string.format("tavern14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves_guild14_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate14", cityId) end
function M.set_thieves_guild14_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate14", cityId, v); print(string.format("thieves guild14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker14_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate14", cityId) end
function M.set_toolmaker14_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate14", cityId, v); print(string.format("toolmaker14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower14_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate14", cityId) end
function M.set_tower14_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate14", cityId, v); print(string.format("tower14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner14_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate14", cityId) end
function M.set_turner14_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate14", cityId, v); print(string.format("turner14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university15_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate15", cityId) end
function M.set_university15_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate15", cityId, v); print(string.format("university15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university_hall14_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate14", cityId) end
function M.set_university_hall14_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate14", cityId, v); print(string.format("university hall14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard14_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate14", cityId) end
function M.set_vineyard14_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate14", cityId, v); print(string.format("vineyard14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner14_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate14", cityId) end
function M.set_vintner14_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate14", cityId, v); print(string.format("vintner14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall15_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate15", cityId) end
function M.set_wall15_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate15", cityId, v); print(string.format("wall15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse15_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate15", cityId) end
function M.set_warehouse15_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate15", cityId, v); print(string.format("warehouse15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving_mill15_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate15", cityId) end
function M.set_weaving_mill15_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate15", cityId, v); print(string.format("weaving mill15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well15_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate15", cityId) end
function M.set_well15_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate15", cityId, v); print(string.format("well15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall16_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate16", cityId) end
function M.set_town_hall16_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate16", cityId, v); print(string.format("town hall16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary15_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate15", cityId) end
function M.set_apothecary15_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate15", cityId, v); print(string.format("apothecary15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer15_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate15", cityId) end
function M.set_armorer15_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate15", cityId, v); print(string.format("armorer15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker15_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate15", cityId) end
function M.set_baker15_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate15", cityId, v); print(string.format("baker15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber15_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate15", cityId) end
function M.set_barber15_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate15", cityId, v); print(string.format("barber15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse15_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate15", cityId) end
function M.set_bathhouse15_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate15", cityId, v); print(string.format("bathhouse15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer15_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate15", cityId) end
function M.set_bowyer15_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate15", cityId, v); print(string.format("bowyer15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster15_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate15", cityId) end
function M.set_brewmaster15_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate15", cityId, v); print(string.format("brewmaster15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker15_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate15", cityId) end
function M.set_brickmaker15_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate15", cityId, v); print(string.format("brickmaker15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge15_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate15", cityId) end
function M.set_bridge15_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate15", cityId, v); print(string.format("bridge15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel15_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate15", cityId) end
function M.set_brothel15_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate15", cityId, v); print(string.format("brothel15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher15_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate15", cityId) end
function M.set_butcher15_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate15", cityId, v); print(string.format("butcher15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker15_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate15", cityId) end
function M.set_candlemaker15_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate15", cityId, v); print(string.format("candlemaker15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter15_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate15", cityId) end
function M.set_carpenter15_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate15", cityId, v); print(string.format("carpenter15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright15_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate15", cityId) end
function M.set_cartwright15_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate15", cityId, v); print(string.format("cartwright15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle15_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate15", cityId) end
function M.set_castle15_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate15", cityId, v); print(string.format("castle15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral15_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate15", cityId) end
function M.set_cathedral15_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate15", cityId, v); print(string.format("cathedral15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler15_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate15", cityId) end
function M.set_chandler15_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate15", cityId, v); print(string.format("chandler15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel15_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate15", cityId) end
function M.set_chapel15_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate15", cityId, v); print(string.format("chapel15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal15_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate15", cityId) end
function M.set_charcoal15_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate15", cityId, v); print(string.format("charcoal burner15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church15_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate15", cityId) end
function M.set_church15_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate15", cityId, v); print(string.format("church15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler15_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate15", cityId) end
function M.set_cobbler15_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate15", cityId, v); print(string.format("cobbler15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor15_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate15", cityId) end
function M.set_contor15_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate15", cityId, v); print(string.format("contor15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook15_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate15", cityId) end
function M.set_cook15_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate15", cityId, v); print(string.format("cook15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper15_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate15", cityId) end
function M.set_cooper15_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate15", cityId, v); print(string.format("cooper15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse15_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate15", cityId) end
function M.set_courthouse15_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate15", cityId, v); print(string.format("courthouse15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy15_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate15", cityId) end
function M.set_dairy15_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate15", cityId, v); print(string.format("dairy15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house15_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate15", cityId) end
function M.set_dice_house15_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate15", cityId, v); print(string.format("dice house15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller15_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate15", cityId) end
function M.set_distiller15_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate15", cityId, v); print(string.format("distiller15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer15_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate15", cityId) end
function M.set_dyer15_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate15", cityId, v); print(string.format("dyer15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery15_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate15", cityId) end
function M.set_fishery15_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate15", cityId, v); print(string.format("fishery15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum15_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate15", cityId) end
function M.set_forum15_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate15", cityId, v); print(string.format("forum15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler15_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate15", cityId) end
function M.set_fowler15_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate15", cityId, v); print(string.format("fowler15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier15_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate15", cityId) end
function M.set_furrier15_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate15", cityId, v); print(string.format("furrier15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison15_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate15", cityId) end
function M.set_garrison15_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate15", cityId, v); print(string.format("garrison15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates15_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate15", cityId) end
function M.set_gates15_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate15", cityId, v); print(string.format("gates15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower15_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate15", cityId) end
function M.set_glassblower15_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate15", cityId, v); print(string.format("glassblower15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater15_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate15", cityId) end
function M.set_goldbeater15_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate15", cityId, v); print(string.format("goldbeater15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith15_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate15", cityId) end
function M.set_goldsmith15_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate15", cityId, v); print(string.format("goldsmith15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary15_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate15", cityId) end
function M.set_granary15_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate15", cityId, v); print(string.format("granary15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse15_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate15", cityId) end
function M.set_guardhouse15_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate15", cityId, v); print(string.format("guardhouse15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house15_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate15", cityId) end
function M.set_guild_house15_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate15", cityId, v); print(string.format("guild house15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor15_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate15", cityId) end
function M.set_harbor15_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate15", cityId, v); print(string.format("harbor15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock15_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate15", cityId) end
function M.set_harbor_dock15_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate15", cityId, v); print(string.format("harbor dock15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls15_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate15", cityId) end
function M.set_harbor_walls15_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate15", cityId, v); print(string.format("harbor walls15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden15_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate15", cityId) end
function M.set_herb_garden15_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate15", cityId, v); print(string.format("herb garden15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital15_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate15", cityId) end
function M.set_hospital15_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate15", cityId, v); print(string.format("hospital15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house15_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate15", cityId) end
function M.set_house15_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate15", cityId, v); print(string.format("house15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler15_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate15", cityId) end
function M.set_jeweler15_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate15", cityId, v); print(string.format("jeweler15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library15_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate15", cityId) end
function M.set_library15_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate15", cityId, v); print(string.format("library15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall15_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate15", cityId) end
function M.set_library_hall15_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate15", cityId, v); print(string.format("library hall15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market15_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate15", cityId) end
function M.set_market15_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate15", cityId, v); print(string.format("market15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller15_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate15", cityId) end
function M.set_miller15_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate15", cityId, v); print(string.format("miller15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine15_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate15", cityId) end
function M.set_mine15_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate15", cityId, v); print(string.format("mine15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint15_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate15", cityId) end
function M.set_mint15_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate15", cityId, v); print(string.format("mint15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery15_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate15", cityId) end
function M.set_monastery15_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate15", cityId, v); print(string.format("monastery15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill15_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate15", cityId) end
function M.set_papermill15_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate15", cityId, v); print(string.format("papermill15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer15_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate15", cityId) end
function M.set_perfumer15_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate15", cityId, v); print(string.format("perfumer15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter15_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate15", cityId) end
function M.set_potter15_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate15", cityId, v); print(string.format("potter15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery15_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate15", cityId) end
function M.set_pottery15_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate15", cityId, v); print(string.format("pottery15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing_house15_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate15", cityId) end
function M.set_printing_house15_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate15", cityId, v); print(string.format("printing house15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker15_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate15", cityId) end
function M.set_ropemaker15_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate15", cityId, v); print(string.format("ropemaker15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_workshop15_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate15", cityId) end
function M.set_ropemaker_workshop15_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate15", cityId, v); print(string.format("ropemaking workshop15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler15_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate15", cityId) end
function M.set_saddler15_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate15", cityId, v); print(string.format("saddler15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school15_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate15", cityId) end
function M.set_school15_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate15", cityId, v); print(string.format("school15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse15_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate15", cityId) end
function M.set_schoolhouse15_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate15", cityId, v); print(string.format("schoolhouse15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry_tower15_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate15", cityId) end
function M.set_sentry_tower15_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate15", cityId, v); print(string.format("sentry tower15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables15_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate15", cityId) end
function M.set_stables15_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate15", cityId, v); print(string.format("stables15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter15_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate15", cityId) end
function M.set_stonecutter15_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate15", cityId, v); print(string.format("stonecutter15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor15_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate15", cityId) end
function M.set_tailor15_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate15", cityId, v); print(string.format("tailor15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery15_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate15", cityId) end
function M.set_tannery15_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate15", cityId, v); print(string.format("tannery15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern15_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate15", cityId) end
function M.set_tavern15_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate15", cityId, v); print(string.format("tavern15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves_guild15_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate15", cityId) end
function M.set_thieves_guild15_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate15", cityId, v); print(string.format("thieves guild15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker15_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate15", cityId) end
function M.set_toolmaker15_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate15", cityId, v); print(string.format("toolmaker15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower15_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate15", cityId) end
function M.set_tower15_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate15", cityId, v); print(string.format("tower15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner15_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate15", cityId) end
function M.set_turner15_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate15", cityId, v); print(string.format("turner15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university16_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate16", cityId) end
function M.set_university16_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate16", cityId, v); print(string.format("university16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university_hall15_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate15", cityId) end
function M.set_university_hall15_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate15", cityId, v); print(string.format("university hall15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard15_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate15", cityId) end
function M.set_vineyard15_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate15", cityId, v); print(string.format("vineyard15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner15_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate15", cityId) end
function M.set_vintner15_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate15", cityId, v); print(string.format("vintner15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall16_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate16", cityId) end
function M.set_wall16_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate16", cityId, v); print(string.format("wall16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary16_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate16", cityId) end
function M.set_apothecary16_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate16", cityId, v); print(string.format("apothecary16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer16_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate16", cityId) end
function M.set_armorer16_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate16", cityId, v); print(string.format("armorer16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker16_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate16", cityId) end
function M.set_baker16_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate16", cityId, v); print(string.format("baker16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber16_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate16", cityId) end
function M.set_barber16_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate16", cityId, v); print(string.format("barber16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse16_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate16", cityId) end
function M.set_bathhouse16_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate16", cityId, v); print(string.format("bathhouse16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer16_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate16", cityId) end
function M.set_bowyer16_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate16", cityId, v); print(string.format("bowyer16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster16_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate16", cityId) end
function M.set_brewmaster16_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate16", cityId, v); print(string.format("brewmaster16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker16_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate16", cityId) end
function M.set_brickmaker16_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate16", cityId, v); print(string.format("brickmaker16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge16_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate16", cityId) end
function M.set_bridge16_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate16", cityId, v); print(string.format("bridge16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel16_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate16", cityId) end
function M.set_brothel16_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate16", cityId, v); print(string.format("brothel16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher16_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate16", cityId) end
function M.set_butcher16_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate16", cityId, v); print(string.format("butcher16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker16_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate16", cityId) end
function M.set_candlemaker16_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate16", cityId, v); print(string.format("candlemaker16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter16_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate16", cityId) end
function M.set_carpenter16_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate16", cityId, v); print(string.format("carpenter16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright16_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate16", cityId) end
function M.set_cartwright16_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate16", cityId, v); print(string.format("cartwright16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle16_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate16", cityId) end
function M.set_castle16_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate16", cityId, v); print(string.format("castle16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral16_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate16", cityId) end
function M.set_cathedral16_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate16", cityId, v); print(string.format("cathedral16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler16_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate16", cityId) end
function M.set_chandler16_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate16", cityId, v); print(string.format("chandler16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel16_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate16", cityId) end
function M.set_chapel16_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate16", cityId, v); print(string.format("chapel16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal16_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate16", cityId) end
function M.set_charcoal16_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate16", cityId, v); print(string.format("charcoal burner16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church16_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate16", cityId) end
function M.set_church16_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate16", cityId, v); print(string.format("church16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler16_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate16", cityId) end
function M.set_cobbler16_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate16", cityId, v); print(string.format("cobbler16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor16_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate16", cityId) end
function M.set_contor16_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate16", cityId, v); print(string.format("contor16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook16_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate16", cityId) end
function M.set_cook16_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate16", cityId, v); print(string.format("cook16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper16_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate16", cityId) end
function M.set_cooper16_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate16", cityId, v); print(string.format("cooper16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse16_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate16", cityId) end
function M.set_courthouse16_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate16", cityId, v); print(string.format("courthouse16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy16_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate16", cityId) end
function M.set_dairy16_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate16", cityId, v); print(string.format("dairy16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house16_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate16", cityId) end
function M.set_dice_house16_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate16", cityId, v); print(string.format("dice house16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller16_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate16", cityId) end
function M.set_distiller16_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate16", cityId, v); print(string.format("distiller16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer16_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate16", cityId) end
function M.set_dyer16_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate16", cityId, v); print(string.format("dyer16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery16_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate16", cityId) end
function M.set_fishery16_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate16", cityId, v); print(string.format("fishery16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum16_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate16", cityId) end
function M.set_forum16_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate16", cityId, v); print(string.format("forum16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler16_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate16", cityId) end
function M.set_fowler16_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate16", cityId, v); print(string.format("fowler16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier16_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate16", cityId) end
function M.set_furrier16_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate16", cityId, v); print(string.format("furrier16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison16_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate16", cityId) end
function M.set_garrison16_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate16", cityId, v); print(string.format("garrison16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates16_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate16", cityId) end
function M.set_gates16_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate16", cityId, v); print(string.format("gates16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower16_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate16", cityId) end
function M.set_glassblower16_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate16", cityId, v); print(string.format("glassblower16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater16_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate16", cityId) end
function M.set_goldbeater16_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate16", cityId, v); print(string.format("goldbeater16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith16_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate16", cityId) end
function M.set_goldsmith16_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate16", cityId, v); print(string.format("goldsmith16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary16_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate16", cityId) end
function M.set_granary16_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate16", cityId, v); print(string.format("granary16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse16_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate16", cityId) end
function M.set_guardhouse16_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate16", cityId, v); print(string.format("guardhouse16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house16_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate16", cityId) end
function M.set_guild_house16_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate16", cityId, v); print(string.format("guild house16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor16_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate16", cityId) end
function M.set_harbor16_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate16", cityId, v); print(string.format("harbor16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock16_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate16", cityId) end
function M.set_harbor_dock16_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate16", cityId, v); print(string.format("harbor dock16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls16_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate16", cityId) end
function M.set_harbor_walls16_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate16", cityId, v); print(string.format("harbor walls16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden16_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate16", cityId) end
function M.set_herb_garden16_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate16", cityId, v); print(string.format("herb garden16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital16_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate16", cityId) end
function M.set_hospital16_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate16", cityId, v); print(string.format("hospital16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house16_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate16", cityId) end
function M.set_house16_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate16", cityId, v); print(string.format("house16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler16_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate16", cityId) end
function M.set_jeweler16_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate16", cityId, v); print(string.format("jeweler16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library16_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate16", cityId) end
function M.set_library16_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate16", cityId, v); print(string.format("library16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall16_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate16", cityId) end
function M.set_library_hall16_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate16", cityId, v); print(string.format("library hall16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market16_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate16", cityId) end
function M.set_market16_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate16", cityId, v); print(string.format("market16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller16_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate16", cityId) end
function M.set_miller16_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate16", cityId, v); print(string.format("miller16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine16_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate16", cityId) end
function M.set_mine16_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate16", cityId, v); print(string.format("mine16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint16_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate16", cityId) end
function M.set_mint16_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate16", cityId, v); print(string.format("mint16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery16_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate16", cityId) end
function M.set_monastery16_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate16", cityId, v); print(string.format("monastery16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill16_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate16", cityId) end
function M.set_papermill16_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate16", cityId, v); print(string.format("papermill16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer16_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate16", cityId) end
function M.set_perfumer16_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate16", cityId, v); print(string.format("perfumer16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter16_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate16", cityId) end
function M.set_potter16_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate16", cityId, v); print(string.format("potter16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery16_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate16", cityId) end
function M.set_pottery16_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate16", cityId, v); print(string.format("pottery16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing_house16_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate16", cityId) end
function M.set_printing_house16_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate16", cityId, v); print(string.format("printing house16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker16_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate16", cityId) end
function M.set_ropemaker16_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate16", cityId, v); print(string.format("ropemaker16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_workshop16_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate16", cityId) end
function M.set_ropemaker_workshop16_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate16", cityId, v); print(string.format("ropemaking workshop16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler16_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate16", cityId) end
function M.set_saddler16_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate16", cityId, v); print(string.format("saddler16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school16_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate16", cityId) end
function M.set_school16_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate16", cityId, v); print(string.format("school16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse16_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate16", cityId) end
function M.set_schoolhouse16_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate16", cityId, v); print(string.format("schoolhouse16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry_tower16_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate16", cityId) end
function M.set_sentry_tower16_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate16", cityId, v); print(string.format("sentry tower16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables16_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate16", cityId) end
function M.set_stables16_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate16", cityId, v); print(string.format("stables16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter16_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate16", cityId) end
function M.set_stonecutter16_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate16", cityId, v); print(string.format("stonecutter16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor16_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate16", cityId) end
function M.set_tailor16_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate16", cityId, v); print(string.format("tailor16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery16_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate16", cityId) end
function M.set_tannery16_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate16", cityId, v); print(string.format("tannery16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern16_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate16", cityId) end
function M.set_tavern16_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate16", cityId, v); print(string.format("tavern16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves_guild16_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate16", cityId) end
function M.set_thieves_guild16_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate16", cityId, v); print(string.format("thieves guild16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker16_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate16", cityId) end
function M.set_toolmaker16_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate16", cityId, v); print(string.format("toolmaker16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower16_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate16", cityId) end
function M.set_tower16_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate16", cityId, v); print(string.format("tower16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner16_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate16", cityId) end
function M.set_turner16_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate16", cityId, v); print(string.format("turner16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university_hall16_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate16", cityId) end
function M.set_university_hall16_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate16", cityId, v); print(string.format("university hall16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard16_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate16", cityId) end
function M.set_vineyard16_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate16", cityId, v); print(string.format("vineyard16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner16_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate16", cityId) end
function M.set_vintner16_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate16", cityId, v); print(string.format("vintner16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall17_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate17", cityId) end
function M.set_wall17_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate17", cityId, v); print(string.format("wall17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse16_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate16", cityId) end
function M.set_warehouse16_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate16", cityId, v); print(string.format("warehouse16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving_mill16_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate16", cityId) end
function M.set_weaving_mill16_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate16", cityId, v); print(string.format("weaving mill16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well16_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate16", cityId) end
function M.set_well16_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate16", cityId, v); print(string.format("well16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer17_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate17", cityId) end
function M.set_armorer17_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate17", cityId, v); print(string.format("armorer17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker17_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate17", cityId) end
function M.set_baker17_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate17", cityId, v); print(string.format("baker17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber17_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate17", cityId) end
function M.set_barber17_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate17", cityId, v); print(string.format("barber17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse17_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate17", cityId) end
function M.set_bathhouse17_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate17", cityId, v); print(string.format("bathhouse17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer17_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate17", cityId) end
function M.set_bowyer17_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate17", cityId, v); print(string.format("bowyer17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster17_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate17", cityId) end
function M.set_brewmaster17_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate17", cityId, v); print(string.format("brewmaster17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker17_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate17", cityId) end
function M.set_brickmaker17_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate17", cityId, v); print(string.format("brickmaker17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge17_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate17", cityId) end
function M.set_bridge17_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate17", cityId, v); print(string.format("bridge17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel17_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate17", cityId) end
function M.set_brothel17_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate17", cityId, v); print(string.format("brothel17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher17_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate17", cityId) end
function M.set_butcher17_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate17", cityId, v); print(string.format("butcher17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker17_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate17", cityId) end
function M.set_candlemaker17_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate17", cityId, v); print(string.format("candlemaker17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter17_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate17", cityId) end
function M.set_carpenter17_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate17", cityId, v); print(string.format("carpenter17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright17_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate17", cityId) end
function M.set_cartwright17_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate17", cityId, v); print(string.format("cartwright17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle17_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate17", cityId) end
function M.set_castle17_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate17", cityId, v); print(string.format("castle17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral17_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate17", cityId) end
function M.set_cathedral17_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate17", cityId, v); print(string.format("cathedral17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler17_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate17", cityId) end
function M.set_chandler17_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate17", cityId, v); print(string.format("chandler17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel17_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate17", cityId) end
function M.set_chapel17_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate17", cityId, v); print(string.format("chapel17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal17_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate17", cityId) end
function M.set_charcoal17_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate17", cityId, v); print(string.format("charcoal burner17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church17_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate17", cityId) end
function M.set_church17_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate17", cityId, v); print(string.format("church17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler17_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate17", cityId) end
function M.set_cobbler17_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate17", cityId, v); print(string.format("cobbler17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor17_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate17", cityId) end
function M.set_contor17_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate17", cityId, v); print(string.format("contor17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook17_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate17", cityId) end
function M.set_cook17_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate17", cityId, v); print(string.format("cook17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper17_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate17", cityId) end
function M.set_cooper17_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate17", cityId, v); print(string.format("cooper17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse17_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate17", cityId) end
function M.set_courthouse17_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate17", cityId, v); print(string.format("courthouse17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy17_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate17", cityId) end
function M.set_dairy17_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate17", cityId, v); print(string.format("dairy17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house17_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate17", cityId) end
function M.set_dice_house17_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate17", cityId, v); print(string.format("dice house17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller17_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate17", cityId) end
function M.set_distiller17_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate17", cityId, v); print(string.format("distiller17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer17_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate17", cityId) end
function M.set_dyer17_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate17", cityId, v); print(string.format("dyer17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery17_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate17", cityId) end
function M.set_fishery17_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate17", cityId, v); print(string.format("fishery17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum17_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate17", cityId) end
function M.set_forum17_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate17", cityId, v); print(string.format("forum17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler17_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate17", cityId) end
function M.set_fowler17_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate17", cityId, v); print(string.format("fowler17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier17_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate17", cityId) end
function M.set_furrier17_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate17", cityId, v); print(string.format("furrier17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison17_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate17", cityId) end
function M.set_garrison17_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate17", cityId, v); print(string.format("garrison17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates17_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate17", cityId) end
function M.set_gates17_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate17", cityId, v); print(string.format("gates17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower17_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate17", cityId) end
function M.set_glassblower17_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate17", cityId, v); print(string.format("glassblower17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater17_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate17", cityId) end
function M.set_goldbeater17_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate17", cityId, v); print(string.format("goldbeater17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith17_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate17", cityId) end
function M.set_goldsmith17_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate17", cityId, v); print(string.format("goldsmith17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary17_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate17", cityId) end
function M.set_granary17_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate17", cityId, v); print(string.format("granary17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse17_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate17", cityId) end
function M.set_guardhouse17_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate17", cityId, v); print(string.format("guardhouse17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house17_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate17", cityId) end
function M.set_guild_house17_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate17", cityId, v); print(string.format("guild house17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor17_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate17", cityId) end
function M.set_harbor17_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate17", cityId, v); print(string.format("harbor17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock17_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate17", cityId) end
function M.set_harbor_dock17_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate17", cityId, v); print(string.format("harbor dock17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls17_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate17", cityId) end
function M.set_harbor_walls17_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate17", cityId, v); print(string.format("harbor walls17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden17_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate17", cityId) end
function M.set_herb_garden17_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate17", cityId, v); print(string.format("herb garden17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital17_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate17", cityId) end
function M.set_hospital17_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate17", cityId, v); print(string.format("hospital17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house17_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate17", cityId) end
function M.set_house17_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate17", cityId, v); print(string.format("house17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler17_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate17", cityId) end
function M.set_jeweler17_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate17", cityId, v); print(string.format("jeweler17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library17_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate17", cityId) end
function M.set_library17_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate17", cityId, v); print(string.format("library17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall17_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate17", cityId) end
function M.set_library_hall17_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate17", cityId, v); print(string.format("library hall17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market17_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate17", cityId) end
function M.set_market17_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate17", cityId, v); print(string.format("market17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller17_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate17", cityId) end
function M.set_miller17_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate17", cityId, v); print(string.format("miller17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine17_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate17", cityId) end
function M.set_mine17_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate17", cityId, v); print(string.format("mine17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint17_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate17", cityId) end
function M.set_mint17_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate17", cityId, v); print(string.format("mint17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery17_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate17", cityId) end
function M.set_monastery17_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate17", cityId, v); print(string.format("monastery17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill17_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate17", cityId) end
function M.set_papermill17_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate17", cityId, v); print(string.format("papermill17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer17_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate17", cityId) end
function M.set_perfumer17_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate17", cityId, v); print(string.format("perfumer17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter17_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate17", cityId) end
function M.set_potter17_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate17", cityId, v); print(string.format("potter17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery17_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate17", cityId) end
function M.set_pottery17_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate17", cityId, v); print(string.format("pottery17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing_house17_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate17", cityId) end
function M.set_printing_house17_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate17", cityId, v); print(string.format("printing house17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker17_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate17", cityId) end
function M.set_ropemaker17_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate17", cityId, v); print(string.format("ropemaker17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_workshop17_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate17", cityId) end
function M.set_ropemaker_workshop17_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate17", cityId, v); print(string.format("ropemaking workshop17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler17_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate17", cityId) end
function M.set_saddler17_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate17", cityId, v); print(string.format("saddler17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school17_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate17", cityId) end
function M.set_school17_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate17", cityId, v); print(string.format("school17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse17_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate17", cityId) end
function M.set_schoolhouse17_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate17", cityId, v); print(string.format("schoolhouse17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry_tower17_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate17", cityId) end
function M.set_sentry_tower17_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate17", cityId, v); print(string.format("sentry tower17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables17_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate17", cityId) end
function M.set_stables17_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate17", cityId, v); print(string.format("stables17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter17_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate17", cityId) end
function M.set_stonecutter17_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate17", cityId, v); print(string.format("stonecutter17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor17_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate17", cityId) end
function M.set_tailor17_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate17", cityId, v); print(string.format("tailor17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery17_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate17", cityId) end
function M.set_tannery17_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate17", cityId, v); print(string.format("tannery17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern17_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate17", cityId) end
function M.set_tavern17_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate17", cityId, v); print(string.format("tavern17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves_guild17_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate17", cityId) end
function M.set_thieves_guild17_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate17", cityId, v); print(string.format("thieves guild17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker17_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate17", cityId) end
function M.set_toolmaker17_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate17", cityId, v); print(string.format("toolmaker17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower17_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate17", cityId) end
function M.set_tower17_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate17", cityId, v); print(string.format("tower17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner17_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate17", cityId) end
function M.set_turner17_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate17", cityId, v); print(string.format("turner17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university17_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate17", cityId) end
function M.set_university17_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate17", cityId, v); print(string.format("university17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university_hall17_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate17", cityId) end
function M.set_university_hall17_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate17", cityId, v); print(string.format("university hall17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard17_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate17", cityId) end
function M.set_vineyard17_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate17", cityId, v); print(string.format("vineyard17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner17_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate17", cityId) end
function M.set_vintner17_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate17", cityId, v); print(string.format("vintner17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall18_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate18", cityId) end
function M.set_wall18_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate18", cityId, v); print(string.format("wall18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse17_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate17", cityId) end
function M.set_warehouse17_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate17", cityId, v); print(string.format("warehouse17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving_mill17_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate17", cityId) end
function M.set_weaving_mill17_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate17", cityId, v); print(string.format("weaving mill17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well17_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate17", cityId) end
function M.set_well17_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate17", cityId, v); print(string.format("well17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer18_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate18", cityId) end
function M.set_armorer18_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate18", cityId, v); print(string.format("armorer18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker18_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate18", cityId) end
function M.set_baker18_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate18", cityId, v); print(string.format("baker18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber18_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate18", cityId) end
function M.set_barber18_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate18", cityId, v); print(string.format("barber18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse18_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate18", cityId) end
function M.set_bathhouse18_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate18", cityId, v); print(string.format("bathhouse18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer18_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate18", cityId) end
function M.set_bowyer18_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate18", cityId, v); print(string.format("bowyer18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster18_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate18", cityId) end
function M.set_brewmaster18_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate18", cityId, v); print(string.format("brewmaster18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker18_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate18", cityId) end
function M.set_brickmaker18_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate18", cityId, v); print(string.format("brickmaker18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge18_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate18", cityId) end
function M.set_bridge18_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate18", cityId, v); print(string.format("bridge18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel18_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate18", cityId) end
function M.set_brothel18_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate18", cityId, v); print(string.format("brothel18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher18_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate18", cityId) end
function M.set_butcher18_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate18", cityId, v); print(string.format("butcher18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker18_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate18", cityId) end
function M.set_candlemaker18_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate18", cityId, v); print(string.format("candlemaker18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter18_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate18", cityId) end
function M.set_carpenter18_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate18", cityId, v); print(string.format("carpenter18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright18_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate18", cityId) end
function M.set_cartwright18_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate18", cityId, v); print(string.format("cartwright18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle18_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate18", cityId) end
function M.set_castle18_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate18", cityId, v); print(string.format("castle18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral18_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate18", cityId) end
function M.set_cathedral18_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate18", cityId, v); print(string.format("cathedral18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler18_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate18", cityId) end
function M.set_chandler18_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate18", cityId, v); print(string.format("chandler18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel18_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate18", cityId) end
function M.set_chapel18_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate18", cityId, v); print(string.format("chapel18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal18_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate18", cityId) end
function M.set_charcoal18_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate18", cityId, v); print(string.format("charcoal burner18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church18_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate18", cityId) end
function M.set_church18_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate18", cityId, v); print(string.format("church18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler18_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate18", cityId) end
function M.set_cobbler18_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate18", cityId, v); print(string.format("cobbler18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor18_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate18", cityId) end
function M.set_contor18_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate18", cityId, v); print(string.format("contor18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook18_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate18", cityId) end
function M.set_cook18_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate18", cityId, v); print(string.format("cook18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper18_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate18", cityId) end
function M.set_cooper18_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate18", cityId, v); print(string.format("cooper18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse18_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate18", cityId) end
function M.set_courthouse18_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate18", cityId, v); print(string.format("courthouse18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy18_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate18", cityId) end
function M.set_dairy18_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate18", cityId, v); print(string.format("dairy18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house18_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate18", cityId) end
function M.set_dice_house18_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate18", cityId, v); print(string.format("dice house18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller18_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate18", cityId) end
function M.set_distiller18_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate18", cityId, v); print(string.format("distiller18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer18_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate18", cityId) end
function M.set_dyer18_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate18", cityId, v); print(string.format("dyer18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery18_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate18", cityId) end
function M.set_fishery18_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate18", cityId, v); print(string.format("fishery18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum18_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate18", cityId) end
function M.set_forum18_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate18", cityId, v); print(string.format("forum18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler18_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate18", cityId) end
function M.set_fowler18_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate18", cityId, v); print(string.format("fowler18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier18_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate18", cityId) end
function M.set_furrier18_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate18", cityId, v); print(string.format("furrier18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison18_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate18", cityId) end
function M.set_garrison18_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate18", cityId, v); print(string.format("garrison18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates18_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate18", cityId) end
function M.set_gates18_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate18", cityId, v); print(string.format("gates18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower18_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate18", cityId) end
function M.set_glassblower18_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate18", cityId, v); print(string.format("glassblower18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater18_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate18", cityId) end
function M.set_goldbeater18_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate18", cityId, v); print(string.format("goldbeater18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith18_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate18", cityId) end
function M.set_goldsmith18_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate18", cityId, v); print(string.format("goldsmith18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary18_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate18", cityId) end
function M.set_granary18_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate18", cityId, v); print(string.format("granary18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse18_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate18", cityId) end
function M.set_guardhouse18_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate18", cityId, v); print(string.format("guardhouse18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house18_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate18", cityId) end
function M.set_guild_house18_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate18", cityId, v); print(string.format("guild house18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor18_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate18", cityId) end
function M.set_harbor18_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate18", cityId, v); print(string.format("harbor18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock18_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate18", cityId) end
function M.set_harbor_dock18_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate18", cityId, v); print(string.format("harbor dock18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls18_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate18", cityId) end
function M.set_harbor_walls18_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate18", cityId, v); print(string.format("harbor walls18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden18_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate18", cityId) end
function M.set_herb_garden18_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate18", cityId, v); print(string.format("herb garden18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital18_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate18", cityId) end
function M.set_hospital18_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate18", cityId, v); print(string.format("hospital18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house18_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate18", cityId) end
function M.set_house18_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate18", cityId, v); print(string.format("house18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler18_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate18", cityId) end
function M.set_jeweler18_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate18", cityId, v); print(string.format("jeweler18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library18_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate18", cityId) end
function M.set_library18_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate18", cityId, v); print(string.format("library18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall18_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate18", cityId) end
function M.set_library_hall18_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate18", cityId, v); print(string.format("library hall18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market18_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate18", cityId) end
function M.set_market18_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate18", cityId, v); print(string.format("market18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller18_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate18", cityId) end
function M.set_miller18_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate18", cityId, v); print(string.format("miller18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine18_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate18", cityId) end
function M.set_mine18_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate18", cityId, v); print(string.format("mine18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint18_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate18", cityId) end
function M.set_mint18_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate18", cityId, v); print(string.format("mint18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery18_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate18", cityId) end
function M.set_monastery18_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate18", cityId, v); print(string.format("monastery18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill18_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate18", cityId) end
function M.set_papermill18_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate18", cityId, v); print(string.format("papermill18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer18_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate18", cityId) end
function M.set_perfumer18_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate18", cityId, v); print(string.format("perfumer18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter18_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate18", cityId) end
function M.set_potter18_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate18", cityId, v); print(string.format("potter18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery18_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate18", cityId) end
function M.set_pottery18_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate18", cityId, v); print(string.format("pottery18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing_house18_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate18", cityId) end
function M.set_printing_house18_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate18", cityId, v); print(string.format("printing house18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker18_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate18", cityId) end
function M.set_ropemaker18_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate18", cityId, v); print(string.format("ropemaker18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_workshop18_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate18", cityId) end
function M.set_ropemaker_workshop18_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate18", cityId, v); print(string.format("ropemaking workshop18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler18_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate18", cityId) end
function M.set_saddler18_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate18", cityId, v); print(string.format("saddler18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school18_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate18", cityId) end
function M.set_school18_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate18", cityId, v); print(string.format("school18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse18_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate18", cityId) end
function M.set_schoolhouse18_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate18", cityId, v); print(string.format("schoolhouse18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry_tower18_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate18", cityId) end
function M.set_sentry_tower18_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate18", cityId, v); print(string.format("sentry tower18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables18_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate18", cityId) end
function M.set_stables18_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate18", cityId, v); print(string.format("stables18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter18_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate18", cityId) end
function M.set_stonecutter18_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate18", cityId, v); print(string.format("stonecutter18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor18_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate18", cityId) end
function M.set_tailor18_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate18", cityId, v); print(string.format("tailor18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery18_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate18", cityId) end
function M.set_tannery18_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate18", cityId, v); print(string.format("tannery18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern18_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate18", cityId) end
function M.set_tavern18_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate18", cityId, v); print(string.format("tavern18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves_guild18_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate18", cityId) end
function M.set_thieves_guild18_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate18", cityId, v); print(string.format("thieves guild18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker18_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate18", cityId) end
function M.set_toolmaker18_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate18", cityId, v); print(string.format("toolmaker18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower18_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate18", cityId) end
function M.set_tower18_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate18", cityId, v); print(string.format("tower18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner18_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate18", cityId) end
function M.set_turner18_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate18", cityId, v); print(string.format("turner18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university_hall18_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate18", cityId) end
function M.set_university_hall18_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate18", cityId, v); print(string.format("university hall18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard18_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate18", cityId) end
function M.set_vineyard18_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate18", cityId, v); print(string.format("vineyard18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner18_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate18", cityId) end
function M.set_vintner18_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate18", cityId, v); print(string.format("vintner18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse18_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate18", cityId) end
function M.set_warehouse18_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate18", cityId, v); print(string.format("warehouse18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving_mill18_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate18", cityId) end
function M.set_weaving_mill18_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate18", cityId, v); print(string.format("weaving mill18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well18_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate18", cityId) end
function M.set_well18_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate18", cityId, v); print(string.format("well18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer19_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate19", cityId) end
function M.set_armorer19_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate19", cityId, v); print(string.format("armorer19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker19_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate19", cityId) end
function M.set_baker19_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate19", cityId, v); print(string.format("baker19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber19_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate19", cityId) end
function M.set_barber19_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate19", cityId, v); print(string.format("barber19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse19_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate19", cityId) end
function M.set_bathhouse19_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate19", cityId, v); print(string.format("bathhouse19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer19_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate19", cityId) end
function M.set_bowyer19_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate19", cityId, v); print(string.format("bowyer19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster19_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate19", cityId) end
function M.set_brewmaster19_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate19", cityId, v); print(string.format("brewmaster19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker19_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate19", cityId) end
function M.set_brickmaker19_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate19", cityId, v); print(string.format("brickmaker19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge19_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate19", cityId) end
function M.set_bridge19_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate19", cityId, v); print(string.format("bridge19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel19_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate19", cityId) end
function M.set_brothel19_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate19", cityId, v); print(string.format("brothel19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher19_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate19", cityId) end
function M.set_butcher19_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate19", cityId, v); print(string.format("butcher19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker19_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate19", cityId) end
function M.set_candlemaker19_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate19", cityId, v); print(string.format("candlemaker19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter19_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate19", cityId) end
function M.set_carpenter19_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate19", cityId, v); print(string.format("carpenter19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright19_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate19", cityId) end
function M.set_cartwright19_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate19", cityId, v); print(string.format("cartwright19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle19_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate19", cityId) end
function M.set_castle19_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate19", cityId, v); print(string.format("castle19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral19_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate19", cityId) end
function M.set_cathedral19_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate19", cityId, v); print(string.format("cathedral19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler19_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate19", cityId) end
function M.set_chandler19_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate19", cityId, v); print(string.format("chandler19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel19_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate19", cityId) end
function M.set_chapel19_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate19", cityId, v); print(string.format("chapel19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal19_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate19", cityId) end
function M.set_charcoal19_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate19", cityId, v); print(string.format("charcoal burner19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church19_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate19", cityId) end
function M.set_church19_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate19", cityId, v); print(string.format("church19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler19_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate19", cityId) end
function M.set_cobbler19_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate19", cityId, v); print(string.format("cobbler19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor19_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate19", cityId) end
function M.set_contor19_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate19", cityId, v); print(string.format("contor19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook19_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate19", cityId) end
function M.set_cook19_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate19", cityId, v); print(string.format("cook19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper19_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate19", cityId) end
function M.set_cooper19_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate19", cityId, v); print(string.format("cooper19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse19_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate19", cityId) end
function M.set_courthouse19_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate19", cityId, v); print(string.format("courthouse19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy19_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate19", cityId) end
function M.set_dairy19_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate19", cityId, v); print(string.format("dairy19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house19_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate19", cityId) end
function M.set_dice_house19_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate19", cityId, v); print(string.format("dice house19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller19_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate19", cityId) end
function M.set_distiller19_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate19", cityId, v); print(string.format("distiller19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer19_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate19", cityId) end
function M.set_dyer19_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate19", cityId, v); print(string.format("dyer19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery19_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate19", cityId) end
function M.set_fishery19_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate19", cityId, v); print(string.format("fishery19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum19_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate19", cityId) end
function M.set_forum19_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate19", cityId, v); print(string.format("forum19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler19_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate19", cityId) end
function M.set_fowler19_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate19", cityId, v); print(string.format("fowler19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier19_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate19", cityId) end
function M.set_furrier19_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate19", cityId, v); print(string.format("furrier19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison19_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate19", cityId) end
function M.set_garrison19_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate19", cityId, v); print(string.format("garrison19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates19_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate19", cityId) end
function M.set_gates19_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate19", cityId, v); print(string.format("gates19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower19_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate19", cityId) end
function M.set_glassblower19_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate19", cityId, v); print(string.format("glassblower19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater19_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate19", cityId) end
function M.set_goldbeater19_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate19", cityId, v); print(string.format("goldbeater19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith19_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate19", cityId) end
function M.set_goldsmith19_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate19", cityId, v); print(string.format("goldsmith19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary19_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate19", cityId) end
function M.set_granary19_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate19", cityId, v); print(string.format("granary19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse19_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate19", cityId) end
function M.set_guardhouse19_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate19", cityId, v); print(string.format("guardhouse19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house19_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate19", cityId) end
function M.set_guild_house19_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate19", cityId, v); print(string.format("guild house19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor19_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate19", cityId) end
function M.set_harbor19_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate19", cityId, v); print(string.format("harbor19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock19_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate19", cityId) end
function M.set_harbor_dock19_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate19", cityId, v); print(string.format("harbor dock19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls19_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate19", cityId) end
function M.set_harbor_walls19_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate19", cityId, v); print(string.format("harbor walls19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden19_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate19", cityId) end
function M.set_herb_garden19_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate19", cityId, v); print(string.format("herb garden19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital19_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate19", cityId) end
function M.set_hospital19_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate19", cityId, v); print(string.format("hospital19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house19_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate19", cityId) end
function M.set_house19_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate19", cityId, v); print(string.format("house19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler19_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate19", cityId) end
function M.set_jeweler19_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate19", cityId, v); print(string.format("jeweler19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library19_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate19", cityId) end
function M.set_library19_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate19", cityId, v); print(string.format("library19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall19_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate19", cityId) end
function M.set_library_hall19_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate19", cityId, v); print(string.format("library hall19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market19_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate19", cityId) end
function M.set_market19_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate19", cityId, v); print(string.format("market19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller19_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate19", cityId) end
function M.set_miller19_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate19", cityId, v); print(string.format("miller19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine19_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate19", cityId) end
function M.set_mine19_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate19", cityId, v); print(string.format("mine19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint19_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate19", cityId) end
function M.set_mint19_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate19", cityId, v); print(string.format("mint19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery19_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate19", cityId) end
function M.set_monastery19_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate19", cityId, v); print(string.format("monastery19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill19_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate19", cityId) end
function M.set_papermill19_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate19", cityId, v); print(string.format("papermill19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer19_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate19", cityId) end
function M.set_perfumer19_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate19", cityId, v); print(string.format("perfumer19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter19_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate19", cityId) end
function M.set_potter19_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate19", cityId, v); print(string.format("potter19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery19_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate19", cityId) end
function M.set_pottery19_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate19", cityId, v); print(string.format("pottery19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing_house19_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate19", cityId) end
function M.set_printing_house19_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate19", cityId, v); print(string.format("printing house19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker19_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate19", cityId) end
function M.set_ropemaker19_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate19", cityId, v); print(string.format("ropemaker19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_workshop19_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate19", cityId) end
function M.set_ropemaker_workshop19_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate19", cityId, v); print(string.format("ropemaking workshop19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler19_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate19", cityId) end
function M.set_saddler19_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate19", cityId, v); print(string.format("saddler19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school19_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate19", cityId) end
function M.set_school19_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate19", cityId, v); print(string.format("school19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse19_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate19", cityId) end
function M.set_schoolhouse19_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate19", cityId, v); print(string.format("schoolhouse19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry_tower19_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate19", cityId) end
function M.set_sentry_tower19_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate19", cityId, v); print(string.format("sentry tower19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables19_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate19", cityId) end
function M.set_stables19_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate19", cityId, v); print(string.format("stables19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter19_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate19", cityId) end
function M.set_stonecutter19_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate19", cityId, v); print(string.format("stonecutter19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor19_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate19", cityId) end
function M.set_tailor19_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate19", cityId, v); print(string.format("tailor19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery19_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate19", cityId) end
function M.set_tannery19_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate19", cityId, v); print(string.format("tannery19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern19_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate19", cityId) end
function M.set_tavern19_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate19", cityId, v); print(string.format("tavern19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves_guild19_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate19", cityId) end
function M.set_thieves_guild19_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate19", cityId, v); print(string.format("thieves guild19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker19_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate19", cityId) end
function M.set_toolmaker19_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate19", cityId, v); print(string.format("toolmaker19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower19_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate19", cityId) end
function M.set_tower19_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate19", cityId, v); print(string.format("tower19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner19_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate19", cityId) end
function M.set_turner19_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate19", cityId, v); print(string.format("turner19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university_hall19_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate19", cityId) end
function M.set_university_hall19_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate19", cityId, v); print(string.format("university hall19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard19_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate19", cityId) end
function M.set_vineyard19_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate19", cityId, v); print(string.format("vineyard19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner19_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate19", cityId) end
function M.set_vintner19_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate19", cityId, v); print(string.format("vintner19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse19_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate19", cityId) end
function M.set_warehouse19_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate19", cityId, v); print(string.format("warehouse19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving_mill19_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate19", cityId) end
function M.set_weaving_mill19_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate19", cityId, v); print(string.format("weaving mill19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well19_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate19", cityId) end
function M.set_well19_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate19", cityId, v); print(string.format("well19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall19_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate19", cityId) end
function M.set_wall19_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate19", cityId, v); print(string.format("wall19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer20_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate20", cityId) end
function M.set_armorer20_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate20", cityId, v); print(string.format("armorer20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker20_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate20", cityId) end
function M.set_baker20_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate20", cityId, v); print(string.format("baker20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber20_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate20", cityId) end
function M.set_barber20_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate20", cityId, v); print(string.format("barber20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse20_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate20", cityId) end
function M.set_bathhouse20_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate20", cityId, v); print(string.format("bathhouse20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer20_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate20", cityId) end
function M.set_bowyer20_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate20", cityId, v); print(string.format("bowyer20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster20_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate20", cityId) end
function M.set_brewmaster20_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate20", cityId, v); print(string.format("brewmaster20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker20_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate20", cityId) end
function M.set_brickmaker20_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate20", cityId, v); print(string.format("brickmaker20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge20_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate20", cityId) end
function M.set_bridge20_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate20", cityId, v); print(string.format("bridge20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel20_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate20", cityId) end
function M.set_brothel20_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate20", cityId, v); print(string.format("brothel20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher20_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate20", cityId) end
function M.set_butcher20_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate20", cityId, v); print(string.format("butcher20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker20_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate20", cityId) end
function M.set_candlemaker20_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate20", cityId, v); print(string.format("candlemaker20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter20_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate20", cityId) end
function M.set_carpenter20_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate20", cityId, v); print(string.format("carpenter20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright20_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate20", cityId) end
function M.set_cartwright20_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate20", cityId, v); print(string.format("cartwright20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle20_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate20", cityId) end
function M.set_castle20_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate20", cityId, v); print(string.format("castle20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral20_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate20", cityId) end
function M.set_cathedral20_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate20", cityId, v); print(string.format("cathedral20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler20_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate20", cityId) end
function M.set_chandler20_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate20", cityId, v); print(string.format("chandler20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel20_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate20", cityId) end
function M.set_chapel20_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate20", cityId, v); print(string.format("chapel20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal20_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate20", cityId) end
function M.set_charcoal20_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate20", cityId, v); print(string.format("charcoal burner20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.church20_level_tax(cityId) return call_or_hint("GetChurchLevelTaxRate20", cityId) end
function M.set_church20_level_tax(cityId, v) local r=call_or_hint("SetChurchLevelTaxRate20", cityId, v); print(string.format("church20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler20_level_tax(cityId) return call_or_hint("GetCobblerLevelTaxRate20", cityId) end
function M.set_cobbler20_level_tax(cityId, v) local r=call_or_hint("SetCobblerLevelTaxRate20", cityId, v); print(string.format("cobbler20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor20_level_tax(cityId) return call_or_hint("GetContorLevelTaxRate20", cityId) end
function M.set_contor20_level_tax(cityId, v) local r=call_or_hint("SetContorLevelTaxRate20", cityId, v); print(string.format("contor20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cook20_level_tax(cityId) return call_or_hint("GetCookLevelTaxRate20", cityId) end
function M.set_cook20_level_tax(cityId, v) local r=call_or_hint("SetCookLevelTaxRate20", cityId, v); print(string.format("cook20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper20_level_tax(cityId) return call_or_hint("GetCooperLevelTaxRate20", cityId) end
function M.set_cooper20_level_tax(cityId, v) local r=call_or_hint("SetCooperLevelTaxRate20", cityId, v); print(string.format("cooper20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.courthouse20_level_tax(cityId) return call_or_hint("GetCourthouseLevelTaxRate20", cityId) end
function M.set_courthouse20_level_tax(cityId, v) local r=call_or_hint("SetCourthouseLevelTaxRate20", cityId, v); print(string.format("courthouse20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy20_level_tax(cityId) return call_or_hint("GetDairyLevelTaxRate20", cityId) end
function M.set_dairy20_level_tax(cityId, v) local r=call_or_hint("SetDairyLevelTaxRate20", cityId, v); print(string.format("dairy20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house20_level_tax(cityId) return call_or_hint("GetDiceHouseLevelTaxRate20", cityId) end
function M.set_dice_house20_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate20", cityId, v); print(string.format("dice house20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller20_level_tax(cityId) return call_or_hint("GetDistillerLevelTaxRate20", cityId) end
function M.set_distiller20_level_tax(cityId, v) local r=call_or_hint("SetDistillerLevelTaxRate20", cityId, v); print(string.format("distiller20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer20_level_tax(cityId) return call_or_hint("GetDyerLevelTaxRate20", cityId) end
function M.set_dyer20_level_tax(cityId, v) local r=call_or_hint("SetDyerLevelTaxRate20", cityId, v); print(string.format("dyer20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery20_level_tax(cityId) return call_or_hint("GetFisheryLevelTaxRate20", cityId) end
function M.set_fishery20_level_tax(cityId, v) local r=call_or_hint("SetFisheryLevelTaxRate20", cityId, v); print(string.format("fishery20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum20_level_tax(cityId) return call_or_hint("GetForumLevelTaxRate20", cityId) end
function M.set_forum20_level_tax(cityId, v) local r=call_or_hint("SetForumLevelTaxRate20", cityId, v); print(string.format("forum20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler20_level_tax(cityId) return call_or_hint("GetFowlerLevelTaxRate20", cityId) end
function M.set_fowler20_level_tax(cityId, v) local r=call_or_hint("SetFowlerLevelTaxRate20", cityId, v); print(string.format("fowler20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier20_level_tax(cityId) return call_or_hint("GetFurrierLevelTaxRate20", cityId) end
function M.set_furrier20_level_tax(cityId, v) local r=call_or_hint("SetFurrierLevelTaxRate20", cityId, v); print(string.format("furrier20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.garrison20_level_tax(cityId) return call_or_hint("GetGarrisonLevelTaxRate20", cityId) end
function M.set_garrison20_level_tax(cityId, v) local r=call_or_hint("SetGarrisonLevelTaxRate20", cityId, v); print(string.format("garrison20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.gates20_level_tax(cityId) return call_or_hint("GetGatesLevelTaxRate20", cityId) end
function M.set_gates20_level_tax(cityId, v) local r=call_or_hint("SetGatesLevelTaxRate20", cityId, v); print(string.format("gates20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.glassblower20_level_tax(cityId) return call_or_hint("GetGlassblowerLevelTaxRate20", cityId) end
function M.set_glassblower20_level_tax(cityId, v) local r=call_or_hint("SetGlassblowerLevelTaxRate20", cityId, v); print(string.format("glassblower20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater20_level_tax(cityId) return call_or_hint("GetGoldbeaterLevelTaxRate20", cityId) end
function M.set_goldbeater20_level_tax(cityId, v) local r=call_or_hint("SetGoldbeaterLevelTaxRate20", cityId, v); print(string.format("goldbeater20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith20_level_tax(cityId) return call_or_hint("GetGoldsmithLevelTaxRate20", cityId) end
function M.set_goldsmith20_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate20", cityId, v); print(string.format("goldsmith20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary20_level_tax(cityId) return call_or_hint("GetGranaryLevelTaxRate20", cityId) end
function M.set_granary20_level_tax(cityId, v) local r=call_or_hint("SetGranaryLevelTaxRate20", cityId, v); print(string.format("granary20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guardhouse20_level_tax(cityId) return call_or_hint("GetGuardhouseLevelTaxRate20", cityId) end
function M.set_guardhouse20_level_tax(cityId, v) local r=call_or_hint("SetGuardhouseLevelTaxRate20", cityId, v); print(string.format("guardhouse20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.guild_house20_level_tax(cityId) return call_or_hint("GetGuildHouseLevelTaxRate20", cityId) end
function M.set_guild_house20_level_tax(cityId, v) local r=call_or_hint("SetGuildHouseLevelTaxRate20", cityId, v); print(string.format("guild house20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor20_level_tax(cityId) return call_or_hint("GetHarborLevelTaxRate20", cityId) end
function M.set_harbor20_level_tax(cityId, v) local r=call_or_hint("SetHarborLevelTaxRate20", cityId, v); print(string.format("harbor20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_dock20_level_tax(cityId) return call_or_hint("GetHarborDockLevelTaxRate20", cityId) end
function M.set_harbor_dock20_level_tax(cityId, v) local r=call_or_hint("SetHarborDockLevelTaxRate20", cityId, v); print(string.format("harbor dock20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls20_level_tax(cityId) return call_or_hint("GetHarborWallsLevelTaxRate20", cityId) end
function M.set_harbor_walls20_level_tax(cityId, v) local r=call_or_hint("SetHarborWallsLevelTaxRate20", cityId, v); print(string.format("harbor walls20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.herb_garden20_level_tax(cityId) return call_or_hint("GetHerbGardenLevelTaxRate20", cityId) end
function M.set_herb_garden20_level_tax(cityId, v) local r=call_or_hint("SetHerbGardenLevelTaxRate20", cityId, v); print(string.format("herb garden20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital20_level_tax(cityId) return call_or_hint("GetHospitalLevelTaxRate20", cityId) end
function M.set_hospital20_level_tax(cityId, v) local r=call_or_hint("SetHospitalLevelTaxRate20", cityId, v); print(string.format("hospital20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house20_level_tax(cityId) return call_or_hint("GetHouseLevelTaxRate20", cityId) end
function M.set_house20_level_tax(cityId, v) local r=call_or_hint("SetHouseLevelTaxRate20", cityId, v); print(string.format("house20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler20_level_tax(cityId) return call_or_hint("GetJewelerLevelTaxRate20", cityId) end
function M.set_jeweler20_level_tax(cityId, v) local r=call_or_hint("SetJewelerLevelTaxRate20", cityId, v); print(string.format("jeweler20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library20_level_tax(cityId) return call_or_hint("GetLibraryLevelTaxRate20", cityId) end
function M.set_library20_level_tax(cityId, v) local r=call_or_hint("SetLibraryLevelTaxRate20", cityId, v); print(string.format("library20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall20_level_tax(cityId) return call_or_hint("GetLibraryHallLevelTaxRate20", cityId) end
function M.set_library_hall20_level_tax(cityId, v) local r=call_or_hint("SetLibraryHallLevelTaxRate20", cityId, v); print(string.format("library hall20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.market20_level_tax(cityId) return call_or_hint("GetMarketLevelTaxRate20", cityId) end
function M.set_market20_level_tax(cityId, v) local r=call_or_hint("SetMarketLevelTaxRate20", cityId, v); print(string.format("market20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.miller20_level_tax(cityId) return call_or_hint("GetMillerLevelTaxRate20", cityId) end
function M.set_miller20_level_tax(cityId, v) local r=call_or_hint("SetMillerLevelTaxRate20", cityId, v); print(string.format("miller20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mine20_level_tax(cityId) return call_or_hint("GetMineLevelTaxRate20", cityId) end
function M.set_mine20_level_tax(cityId, v) local r=call_or_hint("SetMineLevelTaxRate20", cityId, v); print(string.format("mine20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint20_level_tax(cityId) return call_or_hint("GetMintLevelTaxRate20", cityId) end
function M.set_mint20_level_tax(cityId, v) local r=call_or_hint("SetMintLevelTaxRate20", cityId, v); print(string.format("mint20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.monastery20_level_tax(cityId) return call_or_hint("GetMonasteryLevelTaxRate20", cityId) end
function M.set_monastery20_level_tax(cityId, v) local r=call_or_hint("SetMonasteryLevelTaxRate20", cityId, v); print(string.format("monastery20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill20_level_tax(cityId) return call_or_hint("GetPapermillLevelTaxRate20", cityId) end
function M.set_papermill20_level_tax(cityId, v) local r=call_or_hint("SetPapermillLevelTaxRate20", cityId, v); print(string.format("papermill20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer20_level_tax(cityId) return call_or_hint("GetPerfumerLevelTaxRate20", cityId) end
function M.set_perfumer20_level_tax(cityId, v) local r=call_or_hint("SetPerfumerLevelTaxRate20", cityId, v); print(string.format("perfumer20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.potter20_level_tax(cityId) return call_or_hint("GetPotterLevelTaxRate20", cityId) end
function M.set_potter20_level_tax(cityId, v) local r=call_or_hint("SetPotterLevelTaxRate20", cityId, v); print(string.format("potter20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery20_level_tax(cityId) return call_or_hint("GetPotteryLevelTaxRate20", cityId) end
function M.set_pottery20_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate20", cityId, v); print(string.format("pottery20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing_house20_level_tax(cityId) return call_or_hint("GetPrintingHouseLevelTaxRate20", cityId) end
function M.set_printing_house20_level_tax(cityId, v) local r=call_or_hint("SetPrintingHouseLevelTaxRate20", cityId, v); print(string.format("printing house20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker20_level_tax(cityId) return call_or_hint("GetRopemakerLevelTaxRate20", cityId) end
function M.set_ropemaker20_level_tax(cityId, v) local r=call_or_hint("SetRopemakerLevelTaxRate20", cityId, v); print(string.format("ropemaker20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_workshop20_level_tax(cityId) return call_or_hint("GetRopemakerWorkshopLevelTaxRate20", cityId) end
function M.set_ropemaker_workshop20_level_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevelTaxRate20", cityId, v); print(string.format("ropemaker workshop20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.saddler20_level_tax(cityId) return call_or_hint("GetSaddlerLevelTaxRate20", cityId) end
function M.set_saddler20_level_tax(cityId, v) local r=call_or_hint("SetSaddlerLevelTaxRate20", cityId, v); print(string.format("saddler20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.school20_level_tax(cityId) return call_or_hint("GetSchoolLevelTaxRate20", cityId) end
function M.set_school20_level_tax(cityId, v) local r=call_or_hint("SetSchoolLevelTaxRate20", cityId, v); print(string.format("school20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse20_level_tax(cityId) return call_or_hint("GetSchoolhouseLevelTaxRate20", cityId) end
function M.set_schoolhouse20_level_tax(cityId, v) local r=call_or_hint("SetSchoolhouseLevelTaxRate20", cityId, v); print(string.format("schoolhouse20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.sentry_tower20_level_tax(cityId) return call_or_hint("GetSentryTowerLevelTaxRate20", cityId) end
function M.set_sentry_tower20_level_tax(cityId, v) local r=call_or_hint("SetSentryTowerLevelTaxRate20", cityId, v); print(string.format("sentry tower20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stables20_level_tax(cityId) return call_or_hint("GetStablesLevelTaxRate20", cityId) end
function M.set_stables20_level_tax(cityId, v) local r=call_or_hint("SetStablesLevelTaxRate20", cityId, v); print(string.format("stables20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter20_level_tax(cityId) return call_or_hint("GetStonecutterLevelTaxRate20", cityId) end
function M.set_stonecutter20_level_tax(cityId, v) local r=call_or_hint("SetStonecutterLevelTaxRate20", cityId, v); print(string.format("stonecutter20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor20_level_tax(cityId) return call_or_hint("GetTailorLevelTaxRate20", cityId) end
function M.set_tailor20_level_tax(cityId, v) local r=call_or_hint("SetTailorLevelTaxRate20", cityId, v); print(string.format("tailor20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery20_level_tax(cityId) return call_or_hint("GetTanneryLevelTaxRate20", cityId) end
function M.set_tannery20_level_tax(cityId, v) local r=call_or_hint("SetTanneryLevelTaxRate20", cityId, v); print(string.format("tannery20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern20_level_tax(cityId) return call_or_hint("GetTavernLevelTaxRate20", cityId) end
function M.set_tavern20_level_tax(cityId, v) local r=call_or_hint("SetTavernLevelTaxRate20", cityId, v); print(string.format("tavern20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves_guild20_level_tax(cityId) return call_or_hint("GetThievesGuildLevelTaxRate20", cityId) end
function M.set_thieves_guild20_level_tax(cityId, v) local r=call_or_hint("SetThievesGuildLevelTaxRate20", cityId, v); print(string.format("thieves guild20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toolmaker20_level_tax(cityId) return call_or_hint("GetToolmakerLevelTaxRate20", cityId) end
function M.set_toolmaker20_level_tax(cityId, v) local r=call_or_hint("SetToolmakerLevelTaxRate20", cityId, v); print(string.format("toolmaker20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tower20_level_tax(cityId) return call_or_hint("GetTowerLevelTaxRate20", cityId) end
function M.set_tower20_level_tax(cityId, v) local r=call_or_hint("SetTowerLevelTaxRate20", cityId, v); print(string.format("tower20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.turner20_level_tax(cityId) return call_or_hint("GetTurnerLevelTaxRate20", cityId) end
function M.set_turner20_level_tax(cityId, v) local r=call_or_hint("SetTurnerLevelTaxRate20", cityId, v); print(string.format("turner20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university_hall20_level_tax(cityId) return call_or_hint("GetUniversityHallLevelTaxRate20", cityId) end
function M.set_university_hall20_level_tax(cityId, v) local r=call_or_hint("SetUniversityHallLevelTaxRate20", cityId, v); print(string.format("university hall20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard20_level_tax(cityId) return call_or_hint("GetVineyardLevelTaxRate20", cityId) end
function M.set_vineyard20_level_tax(cityId, v) local r=call_or_hint("SetVineyardLevelTaxRate20", cityId, v); print(string.format("vineyard20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner20_level_tax(cityId) return call_or_hint("GetVintnerLevelTaxRate20", cityId) end
function M.set_vintner20_level_tax(cityId, v) local r=call_or_hint("SetVintnerLevelTaxRate20", cityId, v); print(string.format("vintner20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.wall20_level_tax(cityId) return call_or_hint("GetWallLevelTaxRate20", cityId) end
function M.set_wall20_level_tax(cityId, v) local r=call_or_hint("SetWallLevelTaxRate20", cityId, v); print(string.format("wall20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse20_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate20", cityId) end
function M.set_warehouse20_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate20", cityId, v); print(string.format("warehouse20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving_mill20_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate20", cityId) end
function M.set_weaving_mill20_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate20", cityId, v); print(string.format("weaving mill20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well20_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate20", cityId) end
function M.set_well20_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate20", cityId, v); print(string.format("well20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.warehouse14_level_tax(cityId) return call_or_hint("GetWarehouseLevelTaxRate14", cityId) end
function M.set_warehouse14_level_tax(cityId, v) local r=call_or_hint("SetWarehouseLevelTaxRate14", cityId, v); print(string.format("warehouse14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving_mill14_level_tax(cityId) return call_or_hint("GetWeavingMillLevelTaxRate14", cityId) end
function M.set_weaving_mill14_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate14", cityId, v); print(string.format("weaving mill14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.well14_level_tax(cityId) return call_or_hint("GetWellLevelTaxRate14", cityId) end
function M.set_well14_level_tax(cityId, v) local r=call_or_hint("SetWellLevelTaxRate14", cityId, v); print(string.format("well14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer14_level_tax(cityId) return call_or_hint("GetArmorerLevelTaxRate14", cityId) end
function M.set_armorer14_level_tax(cityId, v) local r=call_or_hint("SetArmorerLevelTaxRate14", cityId, v); print(string.format("armorer14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.baker14_level_tax(cityId) return call_or_hint("GetBakerLevelTaxRate14", cityId) end
function M.set_baker14_level_tax(cityId, v) local r=call_or_hint("SetBakerLevelTaxRate14", cityId, v); print(string.format("baker14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barber14_level_tax(cityId) return call_or_hint("GetBarberLevelTaxRate14", cityId) end
function M.set_barber14_level_tax(cityId, v) local r=call_or_hint("SetBarberLevelTaxRate14", cityId, v); print(string.format("barber14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bathhouse14_level_tax(cityId) return call_or_hint("GetBathhouseLevelTaxRate14", cityId) end
function M.set_bathhouse14_level_tax(cityId, v) local r=call_or_hint("SetBathhouseLevelTaxRate14", cityId, v); print(string.format("bathhouse14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer14_level_tax(cityId) return call_or_hint("GetBowyerLevelTaxRate14", cityId) end
function M.set_bowyer14_level_tax(cityId, v) local r=call_or_hint("SetBowyerLevelTaxRate14", cityId, v); print(string.format("bowyer14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster14_level_tax(cityId) return call_or_hint("GetBrewmasterLevelTaxRate14", cityId) end
function M.set_brewmaster14_level_tax(cityId, v) local r=call_or_hint("SetBrewmasterLevelTaxRate14", cityId, v); print(string.format("brewmaster14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker14_level_tax(cityId) return call_or_hint("GetBrickmakerLevelTaxRate14", cityId) end
function M.set_brickmaker14_level_tax(cityId, v) local r=call_or_hint("SetBrickmakerLevelTaxRate14", cityId, v); print(string.format("brickmaker14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge14_level_tax(cityId) return call_or_hint("GetBridgeLevelTaxRate14", cityId) end
function M.set_bridge14_level_tax(cityId, v) local r=call_or_hint("SetBridgeLevelTaxRate14", cityId, v); print(string.format("bridge14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brothel14_level_tax(cityId) return call_or_hint("GetBrothelLevelTaxRate14", cityId) end
function M.set_brothel14_level_tax(cityId, v) local r=call_or_hint("SetBrothelLevelTaxRate14", cityId, v); print(string.format("brothel14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher14_level_tax(cityId) return call_or_hint("GetButcherLevelTaxRate14", cityId) end
function M.set_butcher14_level_tax(cityId, v) local r=call_or_hint("SetButcherLevelTaxRate14", cityId, v); print(string.format("butcher14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker14_level_tax(cityId) return call_or_hint("GetCandlemakerLevelTaxRate14", cityId) end
function M.set_candlemaker14_level_tax(cityId, v) local r=call_or_hint("SetCandlemakerLevelTaxRate14", cityId, v); print(string.format("candlemaker14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenter14_level_tax(cityId) return call_or_hint("GetCarpenterLevelTaxRate14", cityId) end
function M.set_carpenter14_level_tax(cityId, v) local r=call_or_hint("SetCarpenterLevelTaxRate14", cityId, v); print(string.format("carpenter14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright14_level_tax(cityId) return call_or_hint("GetCartwrightLevelTaxRate14", cityId) end
function M.set_cartwright14_level_tax(cityId, v) local r=call_or_hint("SetCartwrightLevelTaxRate14", cityId, v); print(string.format("cartwright14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.castle14_level_tax(cityId) return call_or_hint("GetCastleLevelTaxRate14", cityId) end
function M.set_castle14_level_tax(cityId, v) local r=call_or_hint("SetCastleLevelTaxRate14", cityId, v); print(string.format("castle14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cathedral14_level_tax(cityId) return call_or_hint("GetCathedralLevelTaxRate14", cityId) end
function M.set_cathedral14_level_tax(cityId, v) local r=call_or_hint("SetCathedralLevelTaxRate14", cityId, v); print(string.format("cathedral14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler14_level_tax(cityId) return call_or_hint("GetChandlerLevelTaxRate14", cityId) end
function M.set_chandler14_level_tax(cityId, v) local r=call_or_hint("SetChandlerLevelTaxRate14", cityId, v); print(string.format("chandler14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel14_level_tax(cityId) return call_or_hint("GetChapelLevelTaxRate14", cityId) end
function M.set_chapel14_level_tax(cityId, v) local r=call_or_hint("SetChapelLevelTaxRate14", cityId, v); print(string.format("chapel14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal14_level_tax(cityId) return call_or_hint("GetCharcoalLevelTaxRate14", cityId) end
function M.set_charcoal14_level_tax(cityId, v) local r=call_or_hint("SetCharcoalLevelTaxRate14", cityId, v); print(string.format("charcoal burner14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_goldsmith_level_tax(cityId, v) local r=call_or_hint("SetGoldsmithLevelTaxRate", cityId, v); print(string.format("goldsmith level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_pottery_level_tax(cityId, v) local r=call_or_hint("SetPotteryLevelTaxRate", cityId, v); print(string.format("pottery level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_weaving_level_tax(cityId, v) local r=call_or_hint("SetWeavingMillLevelTaxRate", cityId, v); print(string.format("weaving level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_dice_house_level_tax(cityId, v) local r=call_or_hint("SetDiceHouseLevelTaxRate", cityId, v); print(string.format("dice house level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_tavern_tax(cityId, v) local r=call_or_hint("SetTavernTaxRate", cityId, v); print(string.format("tavern tax city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_herb_garden_tax(cityId, v) local r=call_or_hint("SetHerbGardenTaxRate", cityId, v); print(string.format("herb garden tax city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_ropemaker_ws_tax(cityId, v) local r=call_or_hint("SetRopemakerWorkshopTaxRate", cityId, v); print(string.format("ropemaker ws tax city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_contor_tax2(cityId, v) local r=call_or_hint("SetContorTaxRate2", cityId, v); print(string.format("contor tax2 city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.contor_tax(cityId) return call_or_hint("GetContorTaxRate", cityId) end
function M.set_contor_tax(cityId, v) local r=call_or_hint("SetContorTaxRate", cityId, v); print(string.format("contor tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house_tax(cityId) return call_or_hint("GetDiceHouseTaxRate", cityId) end
function M.set_dice_house_tax(cityId, v) local r=call_or_hint("SetDiceHouseTaxRate", cityId, v); print(string.format("dice house tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves_guild_tax(cityId) return call_or_hint("GetThievesGuildTaxRate", cityId) end
function M.set_thieves_guild_tax(cityId, v) local r=call_or_hint("SetThievesGuildTaxRate", cityId, v); print(string.format("thieves guild tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls_tax3(cityId) return call_or_hint("GetHarborWallsTaxRate3", cityId) end
function M.set_harbor_walls_tax3(cityId, v) local r=call_or_hint("SetHarborWallsTaxRate3", cityId, v); print(string.format("harbor walls tax3 city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_barber_tax(cityId, v) local r=call_or_hint("SetBarberTaxRate", cityId, v); print(string.format("barber tax city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_brothel_tax(cityId, v) local r=call_or_hint("SetBrothelTaxRate", cityId, v); print(string.format("brothel tax city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.brothel(cityId) return call_or_hint("GetBrothelLevel", cityId) end
function M.set_brothel(cityId, v) local r=call_or_hint("SetBrothelLevel", cityId, v); print(string.format("brothel city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls(cityId) return call_or_hint("GetHarborWallsLevel", cityId) end
function M.set_harbor_walls(cityId, v) local r=call_or_hint("SetHarborWallsLevel", cityId, v); print(string.format("harbor walls city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.schoolhouse(cityId) return call_or_hint("GetSchoolhouseLevel", cityId) end
function M.set_schoolhouse(cityId, v) local r=call_or_hint("SetSchoolhouseLevel", cityId, v); print(string.format("schoolhouse city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.library_hall(cityId) return call_or_hint("GetLibraryHallLevel", cityId) end
function M.barber_level(cityId) return call_or_hint("GetBarberLevel", cityId) end
function M.set_barber_level(cityId, v) local r=call_or_hint("SetBarberLevel", cityId, v); print(string.format("barber level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.contor(cityId) return call_or_hint("GetContorLevel", cityId) end
function M.set_contor(cityId, v) local r=call_or_hint("SetContorLevel", cityId, v); print(string.format("contor city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dice_house(cityId) return call_or_hint("GetDiceHouseLevel", cityId) end
function M.set_dice_house(cityId, v) local r=call_or_hint("SetDiceHouseLevel", cityId, v); print(string.format("dice house city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.thieves(cityId) return call_or_hint("GetThievesGuildLevel", cityId) end
function M.ropemaker_workshop(cityId) return call_or_hint("GetRopemakerWorkshopLevel", cityId) end
function M.set_ropemaker_workshop(cityId, v) local r=call_or_hint("SetRopemakerWorkshopLevel", cityId, v); print(string.format("ropemaker workshop city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tannery(cityId) return call_or_hint("GetTanneryLevel", cityId) end
function M.set_tannery(cityId, v) local r=call_or_hint("SetTanneryLevel", cityId, v); print(string.format("tannery city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.weaving_mill(cityId) return call_or_hint("GetWeavingMillLevel", cityId) end
function M.set_weaving_mill(cityId, v) local r=call_or_hint("SetWeavingMillLevel", cityId, v); print(string.format("weaving mill city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mint(cityId) return call_or_hint("GetMintLevel", cityId) end
function M.herb_garden(cityId) return call_or_hint("GetHerbGardenLevel", cityId) end
function M.set_herb_garden(cityId, v) local r=call_or_hint("SetHerbGardenLevel", cityId, v); print(string.format("herb garden city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vineyard(cityId) return call_or_hint("GetVineyardLevel", cityId) end
function M.set_vineyard(cityId, v) local r=call_or_hint("SetVineyardLevel", cityId, v); print(string.format("vineyard city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pottery(cityId) return call_or_hint("GetPotteryLevel", cityId) end
function M.set_pottery(cityId, v) local r=call_or_hint("SetPotteryLevel", cityId, v); print(string.format("pottery city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor(cityId) return call_or_hint("GetTailorLevel", cityId) end
function M.apothecary_level(cityId) return call_or_hint("GetApothecaryLevel", cityId) end
function M.set_apothecary_level(cityId, v) local r=call_or_hint("SetApothecaryLevel", cityId, v); print(string.format("apothecary level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldsmith_level(cityId) return call_or_hint("GetGoldsmithLevel", cityId) end
function M.set_goldsmith_level(cityId, v) local r=call_or_hint("SetGoldsmithLevel", cityId, v); print(string.format("goldsmith level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.jeweler_level(cityId) return call_or_hint("GetJewelerLevel", cityId) end
function M.set_jeweler_level(cityId, v) local r=call_or_hint("SetJewelerLevel", cityId, v); print(string.format("jeweler level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.perfumer_level(cityId) return call_or_hint("GetPerfumerLevel", cityId) end
function M.soapmaker_level(cityId) return call_or_hint("GetSoapmakerLevel", cityId) end
function M.set_soapmaker_level(cityId, v) local r=call_or_hint("SetSoapmakerLevel", cityId, v); print(string.format("soapmaker level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.candlemaker_level(cityId) return call_or_hint("GetCandlemakerLevel", cityId) end
function M.set_candlemaker_level(cityId, v) local r=call_or_hint("SetCandlemakerLevel", cityId, v); print(string.format("candlemaker level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.papermill_level(cityId) return call_or_hint("GetPapermillLevel", cityId) end
function M.set_papermill_level(cityId, v) local r=call_or_hint("SetPapermillLevel", cityId, v); print(string.format("papermill level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.printing_house(cityId) return call_or_hint("GetPrintingHouseLevel", cityId) end
function M.toolmaker_level(cityId) return call_or_hint("GetToolmakerLevel", cityId) end
function M.set_toolmaker_level(cityId, v) local r=call_or_hint("SetToolmakerLevel", cityId, v); print(string.format("toolmaker level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.charcoal_level(cityId) return call_or_hint("GetCharcoalLevel", cityId) end
function M.set_charcoal_level(cityId, v) local r=call_or_hint("SetCharcoalLevel", cityId, v); print(string.format("charcoal level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.furrier_level(cityId) return call_or_hint("GetFurrierLevel", cityId) end
function M.set_furrier_level(cityId, v) local r=call_or_hint("SetFurrierLevel", cityId, v); print(string.format("furrier level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dyer_level(cityId) return call_or_hint("GetDyerLevel", cityId) end
function M.saddler_level(cityId) return call_or_hint("GetSaddlerLevel", cityId) end
function M.set_saddler_level(cityId, v) local r=call_or_hint("SetSaddlerLevel", cityId, v); print(string.format("saddler level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.armorer_level(cityId) return call_or_hint("GetArmorerLevel", cityId) end
function M.set_armorer_level(cityId, v) local r=call_or_hint("SetArmorerLevel", cityId, v); print(string.format("armorer level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bowyer_level(cityId) return call_or_hint("GetBowyerLevel", cityId) end
function M.set_bowyer_level(cityId, v) local r=call_or_hint("SetBowyerLevel", cityId, v); print(string.format("bowyer level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cartwright_level(cityId) return call_or_hint("GetCartwrightLevel", cityId) end
function M.carpenter_level(cityId) return call_or_hint("GetCarpenterLevel", cityId) end
function M.set_carpenter_level(cityId, v) local r=call_or_hint("SetCarpenterLevel", cityId, v); print(string.format("carpenter level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.ropemaker_level(cityId) return call_or_hint("GetRopemakerLevel2", cityId) end
function M.set_ropemaker_level(cityId, v) local r=call_or_hint("SetRopemakerLevel2", cityId, v); print(string.format("ropemaker level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cooper_level(cityId) return call_or_hint("GetCooperLevel", cityId) end
function M.set_cooper_level(cityId, v) local r=call_or_hint("SetCooperLevel", cityId, v); print(string.format("cooper level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner_level(cityId) return call_or_hint("GetSpinnerLevel", cityId) end
function M.turner_level(cityId) return call_or_hint("GetTurnerLevel", cityId) end
function M.set_turner_level(cityId, v) local r=call_or_hint("SetTurnerLevel", cityId, v); print(string.format("turner level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.stonecutter_level(cityId) return call_or_hint("GetStonecutterLevel", cityId) end
function M.set_stonecutter_level(cityId, v) local r=call_or_hint("SetStonecutterLevel", cityId, v); print(string.format("stonecutter level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.cobbler_level(cityId) return call_or_hint("GetCobblerLevel", cityId) end
function M.set_cobbler_level(cityId, v) local r=call_or_hint("SetCobblerLevel", cityId, v); print(string.format("cobbler level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.butcher_level(cityId) return call_or_hint("GetButcherLevel", cityId) end
function M.baker_level(cityId) return call_or_hint("GetBakerLevel", cityId) end
function M.set_baker_level(cityId, v) local r=call_or_hint("SetBakerLevel", cityId, v); print(string.format("baker level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd_level(cityId) return call_or_hint("GetShepherdLevel", cityId) end
function M.set_shepherd_level(cityId, v) local r=call_or_hint("SetShepherdLevel", cityId, v); print(string.format("shepherd level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.dairy_level(cityId) return call_or_hint("GetDairyLevel", cityId) end
function M.set_dairy_level(cityId, v) local r=call_or_hint("SetDairyLevel", cityId, v); print(string.format("dairy level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brewmaster_level(cityId) return call_or_hint("GetBrewmasterLevel", cityId) end
function M.miller_level(cityId) return call_or_hint("GetMillerLevel", cityId) end
function M.set_miller_level(cityId, v) local r=call_or_hint("SetMillerLevel", cityId, v); print(string.format("miller level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fishery_level(cityId) return call_or_hint("GetFisheryLevel", cityId) end
function M.set_fishery_level(cityId, v) local r=call_or_hint("SetFisheryLevel", cityId, v); print(string.format("fishery level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chandler_level(cityId) return call_or_hint("GetChandlerLevel", cityId) end
function M.set_chandler_level(cityId, v) local r=call_or_hint("SetChandlerLevel", cityId, v); print(string.format("chandler level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.goldbeater_level(cityId) return call_or_hint("GetGoldbeaterLevel", cityId) end
function M.potter_level(cityId) return call_or_hint("GetPotterLevel", cityId) end
function M.set_potter_level(cityId, v) local r=call_or_hint("SetPotterLevel", cityId, v); print(string.format("potter level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.fowler_level(cityId) return call_or_hint("GetFowlerLevel", cityId) end
function M.set_fowler_level(cityId, v) local r=call_or_hint("SetFowlerLevel", cityId, v); print(string.format("fowler level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.vintner_level(cityId) return call_or_hint("GetVintnerLevel", cityId) end
function M.set_vintner_level(cityId, v) local r=call_or_hint("SetVintnerLevel", cityId, v); print(string.format("vintner level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.distiller_level(cityId) return call_or_hint("GetDistillerLevel", cityId) end
function M.cook_level(cityId) return call_or_hint("GetCookLevel", cityId) end
function M.set_cook_level(cityId, v) local r=call_or_hint("SetCookLevel", cityId, v); print(string.format("cook level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.brickmaker_level(cityId) return call_or_hint("GetBrickmakerLevel", cityId) end
function M.set_brickmaker_level(cityId, v) local r=call_or_hint("SetBrickmakerLevel", cityId, v); print(string.format("brickmaker level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tavern_level2(cityId) return call_or_hint("GetTavernLevel2", cityId) end
function M.set_tavern_level2(cityId, v) local r=call_or_hint("SetTavernLevel2", cityId, v); print(string.format("tavern v2 city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mill_level(cityId) return call_or_hint("GetMillLevel", cityId) end
function M.brewery_tavern(cityId) return call_or_hint("GetBreweryTavernLevel", cityId) end
function M.set_brewery_tavern(cityId, v) local r=call_or_hint("SetBreweryTavernLevel", cityId, v); print(string.format("brewery tavern city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.smith_level(cityId) return call_or_hint("GetSmithLevel", cityId) end
function M.set_smith_level(cityId, v) local r=call_or_hint("SetSmithLevel", cityId, v); print(string.format("smith level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carpenters(cityId) return call_or_hint("GetCarpentersLevel", cityId) end
function M.set_carpenters(cityId, v) local r=call_or_hint("SetCarpentersLevel", cityId, v); print(string.format("carpenters city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.tailor_workshop(cityId) return call_or_hint("GetTailorWorkshopLevel", cityId) end
function M.joiner_workshop(cityId) return call_or_hint("GetJoinerWorkshopLevel", cityId) end
function M.set_joiner_workshop(cityId, v) local r=call_or_hint("SetJoinerWorkshopLevel", cityId, v); print(string.format("joiner workshop city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carter_workshop(cityId) return call_or_hint("GetCarterWorkshopLevel", cityId) end
function M.set_carter_workshop(cityId, v) local r=call_or_hint("SetCarterWorkshopLevel", cityId, v); print(string.format("carter workshop city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.mining_workshop(cityId) return call_or_hint("GetMiningWorkshopLevel", cityId) end
function M.set_mining_workshop(cityId, v) local r=call_or_hint("SetMiningWorkshopLevel", cityId, v); print(string.format("mining workshop city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.logging_workshop(cityId) return call_or_hint("GetLoggingWorkshopLevel", cityId) end
function M.inn_level(cityId) return call_or_hint("GetInnLevel", cityId) end
function M.set_inn_level(cityId, v) local r=call_or_hint("SetInnLevel", cityId, v); print(string.format("inn level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.robber_camp(cityId) return call_or_hint("GetRobberCampLevel", cityId) end
function M.set_robber_camp(cityId, v) local r=call_or_hint("SetRobberCampLevel", cityId, v); print(string.format("robber camp city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.joiner_ws2(cityId) return call_or_hint("GetJoinerWorkshopLevel2", cityId) end
function M.set_joiner_ws2(cityId, v) local r=call_or_hint("SetJoinerWorkshopLevel2", cityId, v); print(string.format("joiner ws2 city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.carter_ws2(cityId) return call_or_hint("GetCarterWorkshopLevel2", cityId) end
function M.mining_ws2(cityId) return call_or_hint("GetMiningWorkshopLevel2", cityId) end
function M.set_mining_ws2(cityId, v) local r=call_or_hint("SetMiningWorkshopLevel2", cityId, v); print(string.format("mining ws2 city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.logging_ws2(cityId) return call_or_hint("GetLoggingWorkshopLevel2", cityId) end
function M.set_logging_ws2(cityId, v) local r=call_or_hint("SetLoggingWorkshopLevel2", cityId, v); print(string.format("logging ws2 city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.inn_level2(cityId) return call_or_hint("GetInnLevel2", cityId) end
function M.set_inn_level2(cityId, v) local r=call_or_hint("SetInnLevel2", cityId, v); print(string.format("inn2 city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.robber_camp2(cityId) return call_or_hint("GetRobberCampLevel2", cityId) end
function M.toll_gate_level(cityId) return call_or_hint("GetTollGateLevel", cityId) end
function M.set_toll_gate_level(cityId, v) local r=call_or_hint("SetTollGateLevel", cityId, v); print(string.format("toll gate level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.road_level(cityId) return call_or_hint("GetRoadLevel", cityId) end
function M.set_road_level(cityId, v) local r=call_or_hint("SetRoadLevel", cityId, v); print(string.format("road level city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.toll_gate_tax(cityId) return call_or_hint("GetTollGateTaxRate", cityId) end
function M.set_toll_gate_tax(cityId, v) local r=call_or_hint("SetTollGateTaxRate", cityId, v); print(string.format("toll gate tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.bridge_cost(cityId) return call_or_hint("GetBridgeConstructionCost", cityId) end
function M.dock_tax(cityId) return call_or_hint("GetDockTaxRate", cityId) end
function M.set_dock_tax(cityId, v) local r=call_or_hint("SetDockTaxRate", cityId, v); print(string.format("dock tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.harbor_walls_tax(cityId) return call_or_hint("GetHarborWallsTaxRate", cityId) end
function M.set_harbor_walls_tax(cityId, v) local r=call_or_hint("SetHarborWallsTaxRate", cityId, v); print(string.format("harbor walls tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.forum_tax(cityId) return call_or_hint("GetForumTaxRate", cityId) end
function M.set_forum_tax(cityId, v) local r=call_or_hint("SetForumTaxRate", cityId, v); print(string.format("forum tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.granary_tax(cityId) return call_or_hint("GetGranaryTaxRate", cityId) end
function M.guild_house_tax(cityId) return call_or_hint("GetGuildHouseTaxRate", cityId) end
function M.set_guild_house_tax(cityId, v) local r=call_or_hint("SetGuildHouseTaxRate", cityId, v); print(string.format("guild house tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.house_tax(cityId) return call_or_hint("GetHouseTaxRate", cityId) end
function M.set_house_tax(cityId, v) local r=call_or_hint("SetHouseTaxRate", cityId, v); print(string.format("house tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.chapel_tax(cityId) return call_or_hint("GetChapelTaxRate", cityId) end
function M.set_chapel_tax(cityId, v) local r=call_or_hint("SetChapelTaxRate", cityId, v); print(string.format("chapel tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.hospital_tax(cityId) return call_or_hint("GetHospitalTaxRate", cityId) end
function M.set_hospital_tax(cityId, v) local r=call_or_hint("SetHospitalTaxRate", cityId, v); print(string.format("hospital tax city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_granary_tax(cityId, v) local r=call_or_hint("SetGranaryTaxRate", cityId, v); print(string.format("granary tax city=%s -> %s", tostring(cityId), tostring(v))); return r end


function M.set_robber_camp2(cityId, v) local r=call_or_hint("SetRobberCampLevel2", cityId, v); print(string.format("robber camp2 city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_carter_ws2(cityId, v) local r=call_or_hint("SetCarterWorkshopLevel2", cityId, v); print(string.format("carter ws2 city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_logging_workshop(cityId, v) local r=call_or_hint("SetLoggingWorkshopLevel", cityId, v); print(string.format("logging workshop city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_tailor_workshop(cityId, v) local r=call_or_hint("SetTailorWorkshopLevel", cityId, v); print(string.format("tailor workshop city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_mill_level(cityId, v) local r=call_or_hint("SetMillLevel", cityId, v); print(string.format("mill level city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_distiller_level(cityId, v) local r=call_or_hint("SetDistillerLevel", cityId, v); print(string.format("distiller level city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_goldbeater_level(cityId, v) local r=call_or_hint("SetGoldbeaterLevel", cityId, v); print(string.format("goldbeater level city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_brewmaster_level(cityId, v) local r=call_or_hint("SetBrewmasterLevel", cityId, v); print(string.format("brewmaster level city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_butcher_level(cityId, v) local r=call_or_hint("SetButcherLevel", cityId, v); print(string.format("butcher level city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_spinner_level(cityId, v) local r=call_or_hint("SetSpinnerLevel", cityId, v); print(string.format("spinner level city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_cartwright_level(cityId, v) local r=call_or_hint("SetCartwrightLevel", cityId, v); print(string.format("cartwright level city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_dyer_level(cityId, v) local r=call_or_hint("SetDyerLevel", cityId, v); print(string.format("dyer level city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_printing_house(cityId, v) local r=call_or_hint("SetPrintingHouseLevel", cityId, v); print(string.format("printing house city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_perfumer_level(cityId, v) local r=call_or_hint("SetPerfumerLevel", cityId, v); print(string.format("perfumer level city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_tailor(cityId, v) local r=call_or_hint("SetTailorLevel", cityId, v); print(string.format("tailor city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_mint(cityId, v) local r=call_or_hint("SetMintLevel", cityId, v); print(string.format("mint city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_thieves(cityId, v) local r=call_or_hint("SetThievesGuildLevel", cityId, v); print(string.format("thieves level city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_library_hall(cityId, v) local r=call_or_hint("SetLibraryHallLevel", cityId, v); print(string.format("library hall city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_hospital_level(cityId, v) local r=call_or_hint("SetHospitalLevel", cityId, v); print(string.format("hospital level city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_harbor_dock(cityId, v) local r=call_or_hint("SetHarborDockLevel", cityId, v); print(string.format("harbor dock city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_tower(cityId, v) local r=call_or_hint("SetTowerLevel", cityId, v); print(string.format("tower city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_sentry(cityId, v) local r=call_or_hint("SetSentryTowerLevel", cityId, v); print(string.format("sentry city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_harbor_level2(cityId, v) local r=call_or_hint("SetHarborLevel", cityId, v); print(string.format("harbor v2 city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_univ_hall(cityId, v) local r=call_or_hint("SetUniversityHallLevel", cityId, v); print(string.format("univ hall city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_bathhouse_level(cityId, v) local r=call_or_hint("SetBathhouseLevel", cityId, v); print(string.format("bathhouse city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_armory(cityId, v) local r=call_or_hint("SetArmoryLevel", cityId, v); print(string.format("armory city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.set_tavern_level(cityId, v) local r=call_or_hint("SetTavernLevel", cityId, v); print(string.format("tavern level city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.road_toll(cityId, roadId) return call_or_hint("GetRoadTollRate", cityId, roadId) end
function M.set_road_toll(cityId, roadId, v) local r=call_or_hint("SetRoadTollRate", cityId, roadId, v); print(string.format("road toll city=%s road=%s -> %s", tostring(cityId), tostring(roadId), tostring(v))); return r end
function M.church_corruption(cityId) return call_or_hint("GetChurchCorruption", cityId) end
function M.robber(cityId) return call_or_hint("GetRobberThreat", cityId) end
function M.set_church_corruption(cityId, v) local r=call_or_hint("SetChurchCorruption", cityId, v); print(string.format("church corruption city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.pop_limit(cityId) return call_or_hint("GetCityPopulationLimit", cityId) end
function M.set_pop_limit(cityId, v) local r=call_or_hint("SetCityPopulationLimit", cityId, v); print(string.format("pop limit city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.growth(cityId) return call_or_hint("GetCityGrowthRate", cityId) end

function M.prison11_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate11", cityId) end
function M.set_prison11_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate11", cityId, v); print(string.format("prison11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison12_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate12", cityId) end
function M.set_prison12_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate12", cityId, v); print(string.format("prison12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison13_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate13", cityId) end
function M.set_prison13_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate13", cityId, v); print(string.format("prison13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison14_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate14", cityId) end
function M.set_prison14_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate14", cityId, v); print(string.format("prison14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison15_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate15", cityId) end
function M.set_prison15_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate15", cityId, v); print(string.format("prison15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison16_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate16", cityId) end
function M.set_prison16_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate16", cityId, v); print(string.format("prison16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison17_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate17", cityId) end
function M.set_prison17_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate17", cityId, v); print(string.format("prison17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison18_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate18", cityId) end
function M.set_prison18_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate18", cityId, v); print(string.format("prison18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison19_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate19", cityId) end
function M.set_prison19_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate19", cityId, v); print(string.format("prison19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.prison20_level_tax(cityId) return call_or_hint("GetPrisonLevelTaxRate20", cityId) end
function M.set_prison20_level_tax(cityId, v) local r=call_or_hint("SetPrisonLevelTaxRate20", cityId, v); print(string.format("prison20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd11_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate11", cityId) end
function M.set_shepherd11_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate11", cityId, v); print(string.format("shepherd11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd12_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate12", cityId) end
function M.set_shepherd12_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate12", cityId, v); print(string.format("shepherd12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd13_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate13", cityId) end
function M.set_shepherd13_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate13", cityId, v); print(string.format("shepherd13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd14_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate14", cityId) end
function M.set_shepherd14_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate14", cityId, v); print(string.format("shepherd14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd15_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate15", cityId) end
function M.set_shepherd15_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate15", cityId, v); print(string.format("shepherd15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd16_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate16", cityId) end
function M.set_shepherd16_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate16", cityId, v); print(string.format("shepherd16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd17_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate17", cityId) end
function M.set_shepherd17_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate17", cityId, v); print(string.format("shepherd17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd18_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate18", cityId) end
function M.set_shepherd18_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate18", cityId, v); print(string.format("shepherd18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd19_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate19", cityId) end
function M.set_shepherd19_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate19", cityId, v); print(string.format("shepherd19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.shepherd20_level_tax(cityId) return call_or_hint("GetShepherdLevelTaxRate20", cityId) end
function M.set_shepherd20_level_tax(cityId, v) local r=call_or_hint("SetShepherdLevelTaxRate20", cityId, v); print(string.format("shepherd20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker11_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate11", cityId) end
function M.set_soapmaker11_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate11", cityId, v); print(string.format("soapmaker11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker12_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate12", cityId) end
function M.set_soapmaker12_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate12", cityId, v); print(string.format("soapmaker12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker13_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate13", cityId) end
function M.set_soapmaker13_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate13", cityId, v); print(string.format("soapmaker13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker14_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate14", cityId) end
function M.set_soapmaker14_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate14", cityId, v); print(string.format("soapmaker14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker15_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate15", cityId) end
function M.set_soapmaker15_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate15", cityId, v); print(string.format("soapmaker15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker16_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate16", cityId) end
function M.set_soapmaker16_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate16", cityId, v); print(string.format("soapmaker16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker17_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate17", cityId) end
function M.set_soapmaker17_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate17", cityId, v); print(string.format("soapmaker17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker18_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate18", cityId) end
function M.set_soapmaker18_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate18", cityId, v); print(string.format("soapmaker18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker19_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate19", cityId) end
function M.set_soapmaker19_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate19", cityId, v); print(string.format("soapmaker19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.soapmaker20_level_tax(cityId) return call_or_hint("GetSoapmakerLevelTaxRate20", cityId) end
function M.set_soapmaker20_level_tax(cityId, v) local r=call_or_hint("SetSoapmakerLevelTaxRate20", cityId, v); print(string.format("soapmaker20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner11_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate11", cityId) end
function M.set_spinner11_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate11", cityId, v); print(string.format("spinner11 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner12_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate12", cityId) end
function M.set_spinner12_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate12", cityId, v); print(string.format("spinner12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner13_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate13", cityId) end
function M.set_spinner13_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate13", cityId, v); print(string.format("spinner13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner14_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate14", cityId) end
function M.set_spinner14_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate14", cityId, v); print(string.format("spinner14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner15_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate15", cityId) end
function M.set_spinner15_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate15", cityId, v); print(string.format("spinner15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner16_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate16", cityId) end
function M.set_spinner16_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate16", cityId, v); print(string.format("spinner16 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner17_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate17", cityId) end
function M.set_spinner17_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate17", cityId, v); print(string.format("spinner17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner18_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate18", cityId) end
function M.set_spinner18_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate18", cityId, v); print(string.format("spinner18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner19_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate19", cityId) end
function M.set_spinner19_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate19", cityId, v); print(string.format("spinner19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.spinner20_level_tax(cityId) return call_or_hint("GetSpinnerLevelTaxRate20", cityId) end
function M.set_spinner20_level_tax(cityId, v) local r=call_or_hint("SetSpinnerLevelTaxRate20", cityId, v); print(string.format("spinner20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end

function M.apothecary12_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate12", cityId) end
function M.set_apothecary12_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate12", cityId, v); print(string.format("apothecary12 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary13_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate13", cityId) end
function M.set_apothecary13_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate13", cityId, v); print(string.format("apothecary13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary14_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate14", cityId) end
function M.set_apothecary14_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate14", cityId, v); print(string.format("apothecary14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary17_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate17", cityId) end
function M.set_apothecary17_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate17", cityId, v); print(string.format("apothecary17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary18_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate18", cityId) end
function M.set_apothecary18_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate18", cityId, v); print(string.format("apothecary18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary19_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate19", cityId) end
function M.set_apothecary19_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate19", cityId, v); print(string.format("apothecary19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.apothecary20_level_tax(cityId) return call_or_hint("GetApothecaryLevelTaxRate20", cityId) end
function M.set_apothecary20_level_tax(cityId, v) local r=call_or_hint("SetApothecaryLevelTaxRate20", cityId, v); print(string.format("apothecary20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall13_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate13", cityId) end
function M.set_town_hall13_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate13", cityId, v); print(string.format("town hall13 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall14_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate14", cityId) end
function M.set_town_hall14_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate14", cityId, v); print(string.format("town hall14 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall15_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate15", cityId) end
function M.set_town_hall15_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate15", cityId, v); print(string.format("town hall15 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall17_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate17", cityId) end
function M.set_town_hall17_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate17", cityId, v); print(string.format("town hall17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall18_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate18", cityId) end
function M.set_town_hall18_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate18", cityId, v); print(string.format("town hall18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall19_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate19", cityId) end
function M.set_town_hall19_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate19", cityId, v); print(string.format("town hall19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.town_hall20_level_tax(cityId) return call_or_hint("GetTownHallLevelTaxRate20", cityId) end
function M.set_town_hall20_level_tax(cityId, v) local r=call_or_hint("SetTownHallLevelTaxRate20", cityId, v); print(string.format("town hall20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks17_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate17", cityId) end
function M.set_barracks17_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate17", cityId, v); print(string.format("barracks17 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks18_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate18", cityId) end
function M.set_barracks18_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate18", cityId, v); print(string.format("barracks18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks19_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate19", cityId) end
function M.set_barracks19_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate19", cityId, v); print(string.format("barracks19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.barracks20_level_tax(cityId) return call_or_hint("GetBarracksLevelTaxRate20", cityId) end
function M.set_barracks20_level_tax(cityId, v) local r=call_or_hint("SetBarracksLevelTaxRate20", cityId, v); print(string.format("barracks20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university18_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate18", cityId) end
function M.set_university18_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate18", cityId, v); print(string.format("university18 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university19_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate19", cityId) end
function M.set_university19_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate19", cityId, v); print(string.format("university19 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.university20_level_tax(cityId) return call_or_hint("GetUniversityLevelTaxRate20", cityId) end
function M.set_university20_level_tax(cityId, v) local r=call_or_hint("SetUniversityLevelTaxRate20", cityId, v); print(string.format("university20 level tax city=%s -> %s", tostring(cityId), tostring(v))); return r end

return M
