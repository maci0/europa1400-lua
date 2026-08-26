-- Europa 1400 - Cheat / Quick-Use Helpers
--
-- Convenience shortcuts that compose the domain helpers into one-liners
-- people actually want during a live session. All go through
-- player/economy/world/quest/social wrappers so they honor the
-- catalog registration state (and give the same hint errors if not
-- yet registered).
--
--   cheat = require("cheat")  -- or already `cheat`
--   cheat.gold(999999)                -- player + legacy indexed api
--   cheat.fame(100)
--   cheat.health(pid, 100)
--   cheat.time(12)                    -- world time
--   cheat.tax(cityId, goodId, 5)
--   cheat.market(goodId, cityId, 1)   -- set price to 1 for testing
--   cheat.office(cityId, officeId, playerId)
--   cheat.quest_start(id, owner) / cheat.quest_done(id)

local M = {}

-- Per-object state (a building's output, a unit's cargo) lives on the object
-- <mod>.at(addr) returns, so fall back to it and let the cheat name the field
-- directly.
local function delegate(mod, fn, ...)
    local g = require(mod)
    if g[fn] then return g[fn](...) end
    if g.at and select("#", ...) > 0 then
        local obj = g.at((select(1, ...)))
        if obj and obj[fn] then return obj[fn](obj, select(2, ...)) end
    end
    error(string.format("%s.%s does not exist", mod, fn))
end

function M.gold(amount)
    if type(amount) ~= "number" then error("gold amount number required") end
    -- prefer indexed API if present, also try player.set_gold via address if known
        local g = _G.game
    if g and g.call then
        -- try both signatures: int(int) indexed and int() singleton
        if pcall(g.call, "SetPlayerGold", amount) then print(string.format("cheat gold -> %d (SetPlayerGold)", amount)) else pcall(g.call, "AddGold", amount); pcall(g.call, "GetPlayerGoldRaw", 0) end
    end
    -- also try player at known address if user previously resolved
    if _G.player and _G.player.at and _G._cheat_player_addr then
        pcall(function() _G.player.at(_G._cheat_player_addr):set_gold(amount) end)
    end
    print(string.format("cheat gold(%d) attempted; verify with game.call / valuescan", amount))
    return amount
end

function M.fame(amount)
    if type(amount) ~= "number" then error("fame number required") end
    local g = _G.game
    if g and g.call then pcall(g.call, "SetPlayerFame", amount) end
    print(string.format("cheat fame(%d) attempted", amount))
    return amount
end

function M.health(playerId, hp)
    if type(playerId) ~= "number" or type(hp) ~= "number" then error("health(playerId, hp) numbers required") end
    if _G.world or _G.social then
        -- world wraps nothing for health; use direct game call
        local g = _G.game
        if g and g.call then
            local ok, r = pcall(g.call, "SetPlayerHealth", playerId, hp)
            if ok then print(string.format("cheat health player=%s -> %s", tostring(playerId), tostring(hp))); return r end
        end
    end
    -- fallback to unit address if playerId looks like an address
    if playerId > 0x10000 and _G.unit then pcall(function() _G.unit.at(playerId):set_health(hp) end) end
    print("cheat health attempted; verify with GetPlayerHealth / unit.at")
end

function M.time(hours)
    if _G.world and _G.world.set_time then return _G.world.set_time(hours) end
    local g = _G.game; if g and g.call then return pcall(g.call, "SetTimeHours", hours) end
    error("world/time not available")
end

function M.year(y)
    if _G.world and _G.world.set_year then return _G.world.set_year(y) end
    local g = _G.game; if g and g.call then return pcall(g.call, "SetYear", y) end
    error("world/year not available")
end

function M.speed(v) return delegate("world", "set_speed", v) end
function M.difficulty(v) return delegate("world", "set_difficulty", v) end
function M.city_owner(cityId, owner) return delegate("world", "set_city_owner", cityId, owner) end
function M.office(cityId, officeId, playerId) return delegate("world", "set_office", cityId, officeId, playerId) end
function M.tax(cityId, goodId, rate) return delegate("economy", "set_tax_rate", cityId, goodId, rate) end
function M.market(args1, args2, args3)
    -- market(goodId, cityId, price) or market{good,city,price}
    if type(args1) == "table" then return delegate("economy", "set_market_price", args1[1], args1[2], args1[3]) end
    return delegate("economy", "set_market_price", args1, args2, args3)
end
function M.guild_balance(gid, amt) return delegate("economy", "set_guild_balance", gid, amt) end
function M.stock(pid, sid, n) if n==nil then return delegate("economy","stock", pid, sid) else return delegate("economy","set_stock", pid, sid, n) end end
function M.income(pid, n) if n==nil then return delegate("economy","daily_income", pid) else return delegate("economy","set_daily_income", pid, n) end end

function M.quest_start(id, owner) return delegate("quest", "start", id, owner) end
function M.quest_done(id) return delegate("quest", "complete", id) end
function M.quest_fail(id) return delegate("quest", "fail", id) end
function M.crime(pid, lvl) if lvl==nil then return delegate("civic","crime", pid) else return delegate("civic","set_crime", pid, lvl) end end
function M.votes(cid, cand, n) if n==nil then return delegate("civic","votes", cid, cand) else return delegate("civic","set_votes", cid, cand, n) end end
function M.efficiency(bldg, pct) if pct==nil then return delegate("civic","efficiency", bldg) else return delegate("civic","set_efficiency", bldg, pct) end end
function M.intrigue(pid, tid, lvl) if lvl==nil then return delegate("social","intrigue", pid, tid) else return delegate("social","set_intrigue", pid, tid, lvl) end end
function M.bribe(cid, oid, price) if price==nil then return delegate("economy","bribe_price", cid, oid) else return delegate("economy","set_bribe_price", cid, oid, price) end end
function M.title(pid, tid) if tid==nil then return delegate("social","is_title_available", pid) else return delegate("social","claim_title", pid, tid) end end
function M.influence(pid, cid, v) if v==nil then return delegate("social","influence", pid, cid) else return delegate("social","set_influence", pid, cid, v) end end
function M.title_cost(tid) return delegate("economy","title_cost", tid) end
function M.warehouse(addr, n) if n==nil then return delegate("building","capacity", addr) else return delegate("building","set_capacity", addr, n) end end
function M.supply(cid, gid, v) if v==nil then return delegate("economy","supply", cid, gid) else return delegate("economy","set_supply", cid, gid, v) end end
function M.demand(cid, gid, v) if v==nil then return delegate("economy","demand", cid, gid) else return delegate("economy","set_demand", cid, gid, v) end end
function M.profit(a,b,good) return delegate("economy","trade_profit", a, b, good) end
function M.relation(a,b,v) if v==nil then return delegate("social","relation", a, b) else return delegate("social","set_relation", a, b, v) end end
function M.prestige(pid, v) if v==nil then return delegate("social","prestige", pid) else return delegate("social","set_prestige", pid, v) end end
function M.disease(pid, v) if v==nil then return delegate("social","disease", pid) else return delegate("social","set_disease", pid, v) end end
function M.faith(pid, v) if v==nil then return delegate("social","faith", pid) else return delegate("social","set_faith", pid, v) end end
function M.tithe(cid, v) if v==nil then return delegate("social","tithe", cid) else return delegate("social","set_tithe", cid, v) end end
function M.piety(pid, v) if v==nil then return delegate("social","piety", pid) else return delegate("social","set_piety", pid, v) end end
function M.court_favor(pid, nid, v) if v==nil then return delegate("social","court_favor", pid, nid) else return delegate("social","set_court_favor", pid, nid, v) end end
function M.upkeep(bldg, v) if v==nil then if _G.building and _G.building.at then local ok,b=pcall(_G.building.at,bldg); if ok and b.upkeep_via_call then return b:upkeep_via_call() end end; return delegate("building","upkeep_via_call",bldg) else return delegate("building","set_upkeep_via_call",bldg,v) end end
function M.guild_master(gid, pid) if pid==nil then return delegate("social","guild_master", gid) else return delegate("social","set_guild_master", gid, pid) end end
function M.guard(cid, n) if n==nil then return delegate("world","guard_count", cid) else return delegate("world","set_guard_count", cid, n) end end
function M.cart_goods(cart, gid) return delegate("unit","cart_goods", cart, gid) end
function M.bribe_success(pid, cid, oid) return delegate("social","bribe_success", pid, cid, oid) end
function M.debt(pid, v) if v==nil then return delegate("economy","debt", pid) else return delegate("economy","set_debt", pid, v) end end
function M.bank(pid, v) if v==nil then return delegate("economy","bank", pid) else return delegate("economy","set_bank", pid, v) end end
function M.loan(pid, loanId, v) if v==nil then return delegate("economy","loan", pid, loanId) else return delegate("economy","set_loan", pid, loanId, v) end end
function M.interest(cid, v) if v==nil then return delegate("economy","interest", cid) else return delegate("economy","set_interest", cid, v) end end
function M.dynasty_rep(did, v) if v==nil then return delegate("social","dynasty_reputation", did) else return delegate("social","set_dynasty_reputation", did, v) end end
function M.family_wealth(fid, v) if v==nil then return delegate("social","family_wealth", fid) else return delegate("social","set_family_wealth", fid, v) end end
function M.building_tax(bldg, v) if v==nil then return delegate("civic","building_tax", bldg) else return delegate("civic","set_building_tax", bldg, v) end end
function M.worker_skill(wid, sid, v) if v==nil then return delegate("civic","worker_skill", wid, sid) else return delegate("civic","set_worker_skill", wid, sid, v) end end
function M.court_level(pid, lvl, v) if v==nil then return delegate("social","court_influence_level", pid, lvl) else return delegate("social","set_court_influence_level", pid, lvl, v) end end
function M.assassin(pid, v) if v==nil then return delegate("social","assassin_level", pid) else return delegate("social","set_assassin_level", pid, v) end end
function M.warrant(pid) return delegate("social","arrest_warrant", pid) end
function M.issue_warrant(issuer, target) return delegate("social","issue_warrant", issuer, target) end
function M.verdict(tid, v) if v==nil then return delegate("civic","trial_verdict", tid) else return delegate("civic","set_trial_verdict", tid, v) end end
function M.poison(pid, v) if v==nil then return delegate("social","poison", pid) else return delegate("social","set_poison", pid, v) end end
function M.drunk(pid, v) if v==nil then return delegate("social","drunk", pid) else return delegate("social","set_drunk", pid, v) end end
function M.title_tier(tid) return delegate("social","title_tier", tid) end
function M.evidence(pid) return delegate("social","evidence", pid) end
function M.jail(pid, v) if v==nil then return delegate("social","jail_time", pid) else return delegate("social","set_jail_time", pid, v) end end
function M.public_order(cid, v) if v==nil then return delegate("social","public_order", cid) else return delegate("social","set_public_order", cid, v) end end
function M.city_favor(cid, pid, v) if v==nil then return delegate("social","city_favor", cid, pid) else return delegate("social","set_city_favor", cid, pid, v) end end
function M.office_term(cid, oid, v) if v==nil then return delegate("world","office_term", cid, oid) else return delegate("world","set_office_term", cid, oid, v) end end
function M.guild_fee(gid, v) if v==nil then return delegate("economy","guild_fee", gid) else return delegate("economy","set_guild_fee", gid, v) end end
function M.harvest(bldg, gid, v) if v==nil then return delegate("civic","harvest_yield", bldg, gid) else return delegate("civic","set_harvest_yield", bldg, gid, v) end end
function M.servants(bldg) return delegate("building","servants", bldg) end
function M.slots(bldg) return delegate("building","slots", bldg) end
function M.militia(cid, v) if v==nil then return delegate("world","militia", cid) else return delegate("world","set_militia", cid, v) end end
function M.wall(cid, v) if v==nil then return delegate("world","wall_health", cid) else return delegate("world","set_wall_health", cid, v) end end
function M.wage(bldg, wtype, v) if v==nil then return delegate("civic","worker_wage", bldg, wtype) else return delegate("civic","set_worker_wage", bldg, wtype, v) end end
function M.witnesses(tid) return delegate("civic","witnesses", tid) end
function M.spy_net(pid, cid) return delegate("social","spy_network", pid, cid) end
function M.age(pid, v) if v==nil then return delegate("social","age", pid) else return delegate("social","set_age", pid, v) end end
function M.heir(pid, v) if v==nil then return delegate("social","heir", pid) else return delegate("social","set_heir", pid, v) end end
function M.rent(bldg, v) if v==nil then return delegate("building","rent", bldg) else return delegate("building","set_rent", bldg, v) end end
function M.defense(cid, v) if v==nil then return delegate("world","defense", cid) else return delegate("world","set_defense", cid, v) end end
function M.trait(pid, tid, v) if v==nil then return delegate("social","trait", pid, tid) else return delegate("social","set_trait", pid, tid, v) end end
function M.kidnap(a,b) return delegate("social","kidnap_chance", a, b) end
function M.ransom(pid, v) if v==nil then return delegate("social","ransom", pid) else return delegate("social","set_ransom", pid, v) end end
function M.unrest(cid, v) if v==nil then return delegate("world","unrest", cid) else return delegate("world","set_unrest", cid, v) end end
function M.security(bldg) return delegate("building","security", bldg) end
function M.honor(pid, v) if v==nil then return delegate("social","honor", pid) else return delegate("social","set_honor", pid, v) end end
function M.bvalue(bldg) return delegate("building","bvalue", bldg) end
function M.prosperity(cid, v) if v==nil then return delegate("world","prosperity", cid) else return delegate("world","set_prosperity", cid, v) end end
function M.salary(cid, oid, v) if v==nil then return delegate("world","office_salary", cid, oid) else return delegate("world","set_office_salary", cid, oid, v) end end
function M.papal(pid, v) if v==nil then return delegate("social","papal_favor", pid) else return delegate("social","set_papal_favor", pid, v) end end
function M.heretic(pid, v) if v==nil then return delegate("social","heretic", pid) else return delegate("social","set_heretic", pid, v) end end
function M.guard_level(cart) return delegate("unit","guard_level", cart) end
function M.blessing(bldg, v) if v==nil then return delegate("building","blessing", bldg) else return delegate("building","set_blessing", bldg, v) end end
function M.trade_rep(pid, cid, v) if v==nil then return delegate("social","trade_rep", pid, cid) else return delegate("social","set_trade_rep", pid, cid, v) end end
function M.feast(pid, ftype) return delegate("social","feast_cost", pid, ftype) end
function M.favor_debt(a,b,v) if v==nil then return delegate("social","favor_debt", a, b) else return delegate("social","set_favor_debt", a, b, v) end end
function M.ambassador(pid, v) if v==nil then return delegate("social","ambassador", pid) else return delegate("social","set_ambassador", pid, v) end end
function M.festival(cid) return delegate("world","festival", cid) end
function M.food(cid, v) if v==nil then return delegate("world","food", cid) else return delegate("world","set_food", cid, v) end end
function M.accident(bldg, v) if v==nil then return delegate("building","accident", bldg) else return delegate("building","set_accident", bldg, v) end end
function M.fire_risk(bldg) return delegate("building","fire_risk", bldg) end
function M.bounty(pid, v) if v==nil then return delegate("social","bounty", pid) else return delegate("social","set_bounty", pid, v) end end
function M.charter(gid) return delegate("social","charter_cost", gid) end
function M.corruption(cid, v) if v==nil then return delegate("world","corruption", cid) else return delegate("world","set_corruption", cid, v) end end
function M.bribe_cooldown(pid, cid, oid) return delegate("world","bribe_cooldown", pid, cid, oid) end
function M.xp(pid, v) if v==nil then return delegate("social","xp", pid) else return delegate("social","set_xp", pid, v) end end
function M.donation(pid, v) if v==nil then return delegate("social","church_donation", pid) else return delegate("social","set_church_donation", pid, v) end end
function M.strikes(bldg) return delegate("building","strikes", bldg) end
function M.bandit(cid, v) if v==nil then return delegate("world","bandit", cid) else return delegate("world","set_bandit", cid, v) end end
function M.spy_suspicion(pid, cid, v) if v==nil then return delegate("world","spy_suspicion", pid, cid) else return delegate("world","set_spy_suspicion", pid, cid, v) end end
function M.prod_bonus(bldg, gid, v) if v==nil then return delegate("building","prod_bonus", bldg, gid) else return delegate("building","set_prod_bonus", bldg, gid, v) end end
function M.noble_house(pid, v) if v==nil then return delegate("social","noble_house", pid) else return delegate("social","set_noble_house", pid, v) end end
function M.route_profit(a,b,g) return delegate("economy","route_profit", a, b, g) end
function M.caravan(cart) return delegate("unit","caravan_value", cart) end
function M.nepotism(pid, oid, v) if v==nil then return delegate("social","nepotism", pid, oid) else return delegate("social","set_nepotism", pid, oid, v) end end
function M.bishop(pid, did) return delegate("social","bishop", pid, did) end
function M.btax(bldg, v) if v==nil then return delegate("building","btax_rate", bldg) else return delegate("building","set_btax_rate", bldg, v) end end
function M.road(cid) return delegate("world","road", cid) end
function M.imperial(pid, v) if v==nil then return delegate("social","imperial", pid) else return delegate("social","set_imperial", pid, v) end end
function M.tavern(pid, cid) return delegate("social","tavern", pid, cid) end
function M.monastery(pid, cid) return delegate("social","monastery", pid, cid) end
function M.title_rank(pid, tid) return delegate("social","title_rank", pid, tid) end
function M.plague(cid, v) if v==nil then return delegate("world","plague", cid) else return delegate("world","set_plague", cid, v) end end
function M.apprentice_slots(bldg) return delegate("building","apprentice_slots", bldg) end
function M.wall_cost(cid, lvl) return delegate("world","wall_cost", cid, lvl) end
function M.fair(cid) return delegate("world","fair", cid) end
function M.granary(bldg) return delegate("building","granary_cap", bldg) end
function M.baker_bonus(bldg, gid, v) if v==nil then return delegate("building","baker_bonus", bldg, gid) else return delegate("building","set_baker_bonus", bldg, gid, v) end end
function M.master_bribe(bldg) return delegate("building","master_bribe", bldg) end
function M.gambling_debt(pid, v) if v==nil then return delegate("social","gambling_debt", pid) else return delegate("social","set_gambling_debt", pid, v) end end
function M.toll(cid, rid, v) if v==nil then return delegate("world","toll", cid, rid) else return delegate("world","set_toll", cid, rid, v) end end
function M.toll_gates(cid, v) if v==nil then return delegate("world","toll_gates", cid) else return delegate("world","set_toll_gates", cid, v) end end
function M.escort(cid, lvl) return delegate("world","escort_cost", cid, lvl) end
function M.rep_decay(pid, fid, v) if v==nil then return delegate("social","reputation_decay", pid, fid) else return delegate("social","set_reputation_decay", pid, fid, v) end end
function M.banquet(t) return delegate("social","banquet_bonus", t) end
function M.road_upkeep(cid, rid) return delegate("world","road_upkeep", cid, rid) end
function M.stalls(cid) return delegate("world","market_stalls", cid) end
function M.harbor_level(cid, v) if v==nil then return delegate("world","harbor", cid) else return delegate("world","set_harbor", cid, v) end end
function M.cathedral(pid, cid) return delegate("social","cathedral", pid, cid) end
function M.alms(pid) return delegate("social","alms", pid) end
function M.indulgence(pid, lvl) return delegate("social","indulgence_cost", pid, lvl) end
function M.prestige_decay(pid) return delegate("social","dynasty_prestige_decay", pid) end
function M.sin(pid, v) if v==nil then return delegate("social","sin", pid) else return delegate("social","set_sin", pid, v) end end
function M.confession(pid, lvl) return delegate("social","confession_cost", pid, lvl) end
function M.excommunication(pid, v) if v==nil then return delegate("social","excommunication", pid) else return delegate("social","set_excommunication", pid, v) end end
function M.promotion_cost(gid, lvl) return delegate("social","guild_promotion_cost", gid, lvl) end
function M.upgrade_cost(bldg, uid) return delegate("building","upgrade_cost", bldg, uid) end
function M.tax_income(cid) return delegate("world","tax_income", cid) end
function M.university(cid, v) if v==nil then return delegate("world","university", cid) else return delegate("world","set_university", cid, v) end end
function M.guard_morale(cid, v) if v==nil then return delegate("world","guard_morale", cid) else return delegate("world","set_guard_morale", cid, v) end end
function M.pilgrimage(pid, ptype) return delegate("social","pilgrimage_cost", pid, ptype) end
function M.relic(rid) return delegate("social","relic_value", rid) end
function M.crusade(pid, cid, v) if v==nil then return delegate("social","crusade", pid, cid) else return delegate("social","set_crusade", pid, cid, v) end end
function M.joust(pid, jtype) return delegate("social","joust", pid, jtype) end
function M.tournament(pid, tid) return delegate("social","tournament", pid, tid) end
function M.inquisition(pid, v) if v==nil then return delegate("social","inquisition", pid) else return delegate("social","set_inquisition", pid, v) end end
function M.brewery(bldg, gid, v) if v==nil then return delegate("building","brewery_output", bldg, gid) else return delegate("building","set_brewery_output", bldg, gid, v) end end
function M.militia_upkeep(cid) return delegate("world","militia_upkeep", cid) end
function M.smuggler(cityId, goodId) return delegate("world","smuggler_fee", cityId, goodId) end
function M.harbor_fee(cityId, goodId) return delegate("world","harbor_fee", cityId, goodId) end
function M.festival_cost(cityId, ftype) return delegate("world","festival_cost", cityId, ftype) end
function M.cartel(pid, cityId) return delegate("social","cartel", pid, cityId) end
function M.fence(pid, goodId) return delegate("social","fence_price", pid, goodId) end
function M.jester(pid) return delegate("social","jester", pid) end
function M.bard(pid, cityId) return delegate("social","bard", pid, cityId) end
function M.mill(bldg, gid, v) if v==nil then return delegate("building","mill_output", bldg, gid) else return delegate("building","set_mill_output", bldg, gid, v) end end
function M.blacksmith(bldg, gid, v) if v==nil then return delegate("building","blacksmith_output", bldg, gid) else return delegate("building","set_blacksmith_output", bldg, gid, v) end end
function M.tannery(bldg, gid, v) if v==nil then return delegate("building","tannery_output", bldg, gid) else return delegate("building","set_tannery_output", bldg, gid, v) end end
function M.weaver(bldg, gid, v) if v==nil then return delegate("building","weaver_output", bldg, gid) else return delegate("building","set_weaver_output", bldg, gid, v) end end
function M.mint(bldg) return delegate("building","mint_profit", bldg) end
function M.herb(bldg, gid) return delegate("building","herb_yield", bldg, gid) end
function M.vineyard(bldg, gid, v) if v==nil then return delegate("building","vineyard_output", bldg, gid) else return delegate("building","set_vineyard_output", bldg, gid, v) end end
function M.pottery(bldg, gid, v) if v==nil then return delegate("building","pottery_output", bldg, gid) else return delegate("building","set_pottery_output", bldg, gid, v) end end
function M.tailor(bldg, gid, v) if v==nil then return delegate("building","tailor_output", bldg, gid) else return delegate("building","set_tailor_output", bldg, gid, v) end end
function M.fishing(bldg, gid) return delegate("building","fishing_yield", bldg, gid) end
function M.orchard(bldg, gid) return delegate("building","orchard_yield", bldg, gid) end
function M.carpenter(bldg, gid, v) if v==nil then return delegate("building","carpenter_output", bldg, gid) else return delegate("building","set_carpenter_output", bldg, gid, v) end end
function M.ropemaker(bldg, gid, v) if v==nil then return delegate("building","ropemaker_output", bldg, gid) else return delegate("building","set_ropemaker_output", bldg, gid, v) end end
function M.apiary(bldg, gid) return delegate("building","apiary_yield", bldg, gid) end
function M.hunting(bldg, gid) return delegate("building","hunting_yield", bldg, gid) end
function M.alchemist(bldg, gid, v) if v==nil then return delegate("building","alchemist_output", bldg, gid) else return delegate("building","set_alchemist_output", bldg, gid, v) end end
function M.glassworks(bldg, gid, v) if v==nil then return delegate("building","glassworks_output", bldg, gid) else return delegate("building","set_glassworks_output", bldg, gid, v) end end
function M.mason(bldg, gid, v) if v==nil then return delegate("building","mason_output", bldg, gid) else return delegate("building","set_mason_output", bldg, gid, v) end end
function M.distillery(bldg, gid, v) if v==nil then return delegate("building","distillery_output", bldg, gid) else return delegate("building","set_distillery_output", bldg, gid, v) end end
function M.pasture(bldg, gid) return delegate("building","pasture_yield", bldg, gid) end
function M.quarry(bldg, gid) return delegate("building","quarry_yield", bldg, gid) end
function M.forge(bldg, gid, v) if v==nil then return delegate("building","forge_output", bldg, gid) else return delegate("building","set_forge_output", bldg, gid, v) end end
function M.sawmill(bldg, gid, v) if v==nil then return delegate("building","sawmill_output", bldg, gid) else return delegate("building","set_sawmill_output", bldg, gid, v) end end
function M.kiln(bldg, gid, v) if v==nil then return delegate("building","kiln_output", bldg, gid) else return delegate("building","set_kiln_output", bldg, gid, v) end end
function M.foundry(bldg, gid, v) if v==nil then return delegate("building","foundry_output", bldg, gid) else return delegate("building","set_foundry_output", bldg, gid, v) end end
function M.market_fee(cityId, v) if v==nil then return delegate("world","market_fee", cityId) else return delegate("world","set_market_fee", cityId, v) end end
function M.guild_levy(gid, cid, v) if v==nil then return delegate("economy","guild_levy", gid, cid) else return delegate("economy","set_guild_levy", gid, cid, v) end end
function M.watch_strength(cityId, v) if v==nil then return delegate("world","watch", cityId) else return delegate("world","set_watch", cityId, v) end end
function M.noble_auth(pid, cid) return delegate("social","noble_auth", pid, cid) end
function M.debasement(cityId, v) if v==nil then return delegate("world","debasement", cityId) else return delegate("world","set_debasement", cityId, v) end end
function M.regulation(cityId) return delegate("world","regulation", cityId) end
function M.siege(cityId, v) if v==nil then return delegate("world","siege", cityId) else return delegate("world","set_siege", cityId, v) end end
function M.garrison(cityId, v) if v==nil then return delegate("world","garrison", cityId) else return delegate("world","set_garrison", cityId, v) end end
function M.merc_cost(cityId, mtype) return delegate("world","merc_cost", cityId, mtype) end
function M.hospital(bldg) return delegate("building","hospital_cap", bldg) end
function M.clergy(pid, cityId) return delegate("social","clergy", pid, cityId) end
function M.council_power(pid, cityId) return delegate("social","council_power", pid, cityId) end
function M.patrol(cityId, v) if v==nil then return delegate("world","patrol", cityId) else return delegate("world","set_patrol", cityId, v) end end
function M.bandit_risk(cityId, roadId, v) if v==nil then return delegate("world","bandit_risk", cityId, roadId) else return delegate("world","set_bandit_risk", cityId, roadId, v) end end
function M.tavern_brawl(cityId) return delegate("world","tavern_brawl", cityId) end
function M.guild_hall(gid, cid, v) if v==nil then return delegate("world","guild_hall", gid, cid) else return delegate("world","set_guild_hall", gid, cid, v) end end
function M.court_intrigue(pid, cityId) return delegate("social","court_intrigue", pid, cityId) end
function M.tavern_income(bldg) return delegate("building","tavern_income", bldg) end
function M.church_influence(pid, cityId) return delegate("social","church", pid, cityId) end
function M.noble_demands(pid, cityId) return delegate("social","noble_demands", pid, cityId) end
function M.office_comp(cityId, oid) return delegate("social","office_competition", cityId, oid) end
function M.tax_collector(cityId, v) if v==nil then return delegate("world","tax_collector", cityId) else return delegate("world","set_tax_collector", cityId, v) end end
function M.wall_repair(cityId) return delegate("world","wall_repair", cityId) end
function M.town_hall(cityId, v) if v==nil then return delegate("world","town_hall", cityId) else return delegate("world","set_town_hall", cityId, v) end end
function M.church_level(cityId, v) if v==nil then return delegate("world","church_level", cityId) else return delegate("world","set_church_level", cityId, v) end end
function M.market_level(cityId, v) if v==nil then return delegate("world","market_level", cityId) else return delegate("world","set_market_level", cityId, v) end end
function M.tavern_level(cityId, v) if v==nil then return delegate("world","tavern_level", cityId) else return delegate("world","set_tavern_level", cityId, v) end end
function M.library(cityId, v) if v==nil then return delegate("world","library", cityId) else return delegate("world","set_library", cityId, v) end end
function M.school(cityId, v) if v==nil then return delegate("world","school", cityId) else return delegate("world","set_school", cityId, v) end end
function M.dock(cityId, v) if v==nil then return delegate("world","dock", cityId) else return delegate("world","set_dock", cityId, v) end end
function M.armory(cityId, v) if v==nil then return delegate("world","armory", cityId) else return delegate("world","set_armory", cityId, v) end end
function M.warehouse_level(cityId, v) if v==nil then return delegate("world","warehouse", cityId) else return delegate("world","set_warehouse", cityId, v) end end
function M.mine(cityId, v) if v==nil then return delegate("world","mine", cityId) else return delegate("world","set_mine", cityId, v) end end
function M.garrison_level(cityId, v) if v==nil then return delegate("world","garrison_level", cityId) else return delegate("world","set_garrison_level", cityId, v) end end
function M.bathhouse_level(cityId, v) if v==nil then return delegate("world","bathhouse_level", cityId) else return delegate("world","set_bathhouse_level", cityId, v) end end
function M.harbor_master(cityId, v) if v==nil then return delegate("world","harbor_master", cityId) else return delegate("world","set_harbor_master", cityId, v) end end
function M.guardhouse(cityId, v) if v==nil then return delegate("world","guardhouse", cityId) else return delegate("world","set_guardhouse", cityId, v) end end
function M.courthouse(cityId, v) if v==nil then return delegate("world","courthouse", cityId) else return delegate("world","set_courthouse", cityId, v) end end
function M.univ_hall(cityId, v) if v==nil then return delegate("world","univ_hall", cityId) else return delegate("world","set_univ_hall", cityId, v) end end
function M.castle(cityId, v) if v==nil then return delegate("world","castle", cityId) else return delegate("world","set_castle", cityId, v) end end
function M.cathedral_level(cityId, v) if v==nil then return delegate("world","cathedral_level", cityId) else return delegate("world","set_cathedral_level", cityId, v) end end
function M.monastery_level(cityId, v) if v==nil then return delegate("world","monastery_level", cityId) else return delegate("world","set_monastery_level", cityId, v) end end
function M.harbor_level2(cityId, v) if v==nil then return delegate("world","harbor_level2", cityId) else return delegate("world","set_harbor_level2", cityId, v) end end
function M.barracks(cityId, v) if v==nil then return delegate("world","barracks", cityId) else return delegate("world","set_barracks", cityId, v) end end
function M.stables(cityId, v) if v==nil then return delegate("world","stables", cityId) else return delegate("world","set_stables", cityId, v) end end
function M.gates(cityId, v) if v==nil then return delegate("world","gates", cityId) else return delegate("world","set_gates", cityId, v) end end
function M.sentry(cityId, v) if v==nil then return delegate("world","sentry", cityId) else return delegate("world","set_sentry", cityId, v) end end
function M.well(cityId, v) if v==nil then return delegate("world","well", cityId) else return delegate("world","set_well", cityId, v) end end
function M.bridge(cityId, v) if v==nil then return delegate("world","bridge", cityId) else return delegate("world","set_bridge", cityId, v) end end
function M.wall_level(cityId, v) if v==nil then return delegate("world","wall_level", cityId) else return delegate("world","set_wall_level", cityId, v) end end
function M.tower_level(cityId, v) if v==nil then return delegate("world","tower", cityId) else return delegate("world","set_tower", cityId, v) end end
function M.forum(cityId, v) if v==nil then return delegate("world","forum", cityId) else return delegate("world","set_forum", cityId, v) end end
function M.granary_level(cityId, v) if v==nil then return delegate("world","granary_level", cityId) else return delegate("world","set_granary_level", cityId, v) end end
function M.prison(cityId, v) if v==nil then return delegate("world","prison", cityId) else return delegate("world","set_prison", cityId, v) end end
function M.harbor_dock(cityId, v) if v==nil then return delegate("world","harbor_dock", cityId) else return delegate("world","set_harbor_dock", cityId, v) end end
function M.guild_house2(cityId, v) if v==nil then return delegate("world","guild_house2", cityId) else return delegate("world","set_guild_house2", cityId, v) end end
function M.house(cityId, v) if v==nil then return delegate("world","house", cityId) else return delegate("world","set_house", cityId, v) end end
function M.chapel(cityId, v) if v==nil then return delegate("world","chapel", cityId) else return delegate("world","set_chapel", cityId, v) end end
function M.hospital_level(cityId, v) if v==nil then return delegate("world","hospital_level", cityId) else return delegate("world","set_hospital_level", cityId, v) end end
function M.harbor_walls2(cityId, v) if v==nil then return delegate("world","harbor_walls2", cityId) else return delegate("world","set_harbor_walls2", cityId, v) end end
function M.schoolhouse2(cityId, v) if v==nil then return delegate("world","schoolhouse2", cityId) else return delegate("world","set_schoolhouse2", cityId, v) end end
function M.library_hall2(cityId, v) if v==nil then return delegate("world","library_hall2", cityId) else return delegate("world","set_library_hall2", cityId, v) end end
function M.brothel_tax(cityId, v) if v==nil then return delegate("world","brothel_tax", cityId) else return delegate("world","set_brothel_tax", cityId, v) end end
function M.harbor_walls_tax2(cityId, v) if v==nil then return delegate("world","harbor_walls_tax2", cityId) else return delegate("world","set_harbor_walls_tax2", cityId, v) end end
function M.schoolhouse_tax(cityId, v) if v==nil then return delegate("world","schoolhouse_tax", cityId) else return delegate("world","set_schoolhouse_tax", cityId, v) end end
function M.library_hall_tax(cityId, v) if v==nil then return delegate("world","library_hall_tax", cityId) else return delegate("world","set_library_hall_tax", cityId, v) end end
function M.barber_tax(cityId, v) if v==nil then return delegate("world","barber_tax", cityId) else return delegate("world","set_barber_tax", cityId, v) end end
function M.schoolhouse_tax2(cityId, v) if v==nil then return delegate("world","schoolhouse_tax2", cityId) else return delegate("world","set_schoolhouse_tax2", cityId, v) end end
function M.library_hall_tax2(cityId, v) if v==nil then return delegate("world","library_hall_tax2", cityId) else return delegate("world","set_library_hall_tax2", cityId, v) end end
function M.brothel_tax2(cityId, v) if v==nil then return delegate("world","brothel_tax2", cityId) else return delegate("world","set_brothel_tax2", cityId, v) end end
function M.contor_tax2(cityId, v) if v==nil then return delegate("world","contor_tax2", cityId) else return delegate("world","set_contor_tax2", cityId, v) end end
function M.dice_house_tax2(cityId, v) if v==nil then return delegate("world","dice_house_tax2", cityId) else return delegate("world","set_dice_house_tax2", cityId, v) end end
function M.thieves_guild_tax2(cityId, v) if v==nil then return delegate("world","thieves_guild_tax2", cityId) else return delegate("world","set_thieves_guild_tax2", cityId, v) end end
function M.harbor_walls_tax4(cityId, v) if v==nil then return delegate("world","harbor_walls_tax4", cityId) else return delegate("world","set_harbor_walls_tax4", cityId, v) end end
function M.ropemaker_ws_tax(cityId, v) if v==nil then return delegate("world","ropemaker_ws_tax", cityId) else return delegate("world","set_ropemaker_ws_tax", cityId, v) end end
function M.tannery_tax(cityId, v) if v==nil then return delegate("world","tannery_tax", cityId) else return delegate("world","set_tannery_tax", cityId, v) end end
function M.weaving_tax(cityId, v) if v==nil then return delegate("world","weaving_tax", cityId) else return delegate("world","set_weaving_tax", cityId, v) end end
function M.mint_tax(cityId, v) if v==nil then return delegate("world","mint_tax", cityId) else return delegate("world","set_mint_tax", cityId, v) end end
function M.herb_garden_tax(cityId, v) if v==nil then return delegate("world","herb_garden_tax", cityId) else return delegate("world","set_herb_garden_tax", cityId, v) end end
function M.vineyard_tax(cityId, v) if v==nil then return delegate("world","vineyard_tax", cityId) else return delegate("world","set_vineyard_tax", cityId, v) end end
function M.pottery_tax(cityId, v) if v==nil then return delegate("world","pottery_tax", cityId) else return delegate("world","set_pottery_tax", cityId, v) end end
function M.tailor_tax(cityId, v) if v==nil then return delegate("world","tailor_tax", cityId) else return delegate("world","set_tailor_tax", cityId, v) end end
function M.tavern_tax(cityId, v) if v==nil then return delegate("world","tavern_tax", cityId) else return delegate("world","set_tavern_tax", cityId, v) end end
function M.bathhouse_tax(cityId, v) if v==nil then return delegate("world","bathhouse_tax", cityId) else return delegate("world","set_bathhouse_tax", cityId, v) end end
function M.church_level_tax(cityId, v) if v==nil then return delegate("world","church_level_tax", cityId) else return delegate("world","set_church_level_tax", cityId, v) end end
function M.contor_level_tax(cityId, v) if v==nil then return delegate("world","contor_level_tax", cityId) else return delegate("world","set_contor_level_tax", cityId, v) end end
function M.dice_house_level_tax(cityId, v) if v==nil then return delegate("world","dice_house_level_tax", cityId) else return delegate("world","set_dice_house_level_tax", cityId, v) end end
function M.thieves_guild_level_tax(cityId, v) if v==nil then return delegate("world","thieves_guild_level_tax", cityId) else return delegate("world","set_thieves_guild_level_tax", cityId, v) end end
function M.ropemaker_workshop_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_workshop_level_tax", cityId) else return delegate("world","set_ropemaker_workshop_level_tax", cityId, v) end end
function M.tannery_level_tax(cityId, v) if v==nil then return delegate("world","tannery_level_tax", cityId) else return delegate("world","set_tannery_level_tax", cityId, v) end end
function M.weaving_level_tax(cityId, v) if v==nil then return delegate("world","weaving_level_tax", cityId) else return delegate("world","set_weaving_level_tax", cityId, v) end end
function M.mint_level_tax(cityId, v) if v==nil then return delegate("world","mint_level_tax", cityId) else return delegate("world","set_mint_level_tax", cityId, v) end end
function M.herb_garden_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden_level_tax", cityId) else return delegate("world","set_herb_garden_level_tax", cityId, v) end end
function M.vineyard_level_tax(cityId, v) if v==nil then return delegate("world","vineyard_level_tax", cityId) else return delegate("world","set_vineyard_level_tax", cityId, v) end end
function M.pottery_level_tax(cityId, v) if v==nil then return delegate("world","pottery_level_tax", cityId) else return delegate("world","set_pottery_level_tax", cityId, v) end end
function M.tailor_level_tax(cityId, v) if v==nil then return delegate("world","tailor_level_tax", cityId) else return delegate("world","set_tailor_level_tax", cityId, v) end end
function M.tavern_level_tax(cityId, v) if v==nil then return delegate("world","tavern_level_tax", cityId) else return delegate("world","set_tavern_level_tax", cityId, v) end end
function M.apothecary_level_tax(cityId, v) if v==nil then return delegate("world","apothecary_level_tax", cityId) else return delegate("world","set_apothecary_level_tax", cityId, v) end end
function M.goldsmith_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith_level_tax", cityId) else return delegate("world","set_goldsmith_level_tax", cityId, v) end end
function M.jeweler_level_tax(cityId, v) if v==nil then return delegate("world","jeweler_level_tax", cityId) else return delegate("world","set_jeweler_level_tax", cityId, v) end end
function M.perfumer_level_tax(cityId, v) if v==nil then return delegate("world","perfumer_level_tax", cityId) else return delegate("world","set_perfumer_level_tax", cityId, v) end end
function M.soapmaker_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker_level_tax", cityId) else return delegate("world","set_soapmaker_level_tax", cityId, v) end end
function M.candlemaker_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker_level_tax", cityId) else return delegate("world","set_candlemaker_level_tax", cityId, v) end end
function M.papermill_level_tax(cityId, v) if v==nil then return delegate("world","papermill_level_tax", cityId) else return delegate("world","set_papermill_level_tax", cityId, v) end end
function M.printing_level_tax(cityId, v) if v==nil then return delegate("world","printing_level_tax", cityId) else return delegate("world","set_printing_level_tax", cityId, v) end end
function M.toolmaker_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker_level_tax", cityId) else return delegate("world","set_toolmaker_level_tax", cityId, v) end end
function M.charcoal_level_tax(cityId, v) if v==nil then return delegate("world","charcoal_level_tax", cityId) else return delegate("world","set_charcoal_level_tax", cityId, v) end end
function M.furrier_level_tax(cityId, v) if v==nil then return delegate("world","furrier_level_tax", cityId) else return delegate("world","set_furrier_level_tax", cityId, v) end end
function M.dyer_level_tax(cityId, v) if v==nil then return delegate("world","dyer_level_tax", cityId) else return delegate("world","set_dyer_level_tax", cityId, v) end end
function M.saddler_level_tax(cityId, v) if v==nil then return delegate("world","saddler_level_tax", cityId) else return delegate("world","set_saddler_level_tax", cityId, v) end end
function M.armorer_level_tax(cityId, v) if v==nil then return delegate("world","armorer_level_tax", cityId) else return delegate("world","set_armorer_level_tax", cityId, v) end end
function M.bowyer_level_tax(cityId, v) if v==nil then return delegate("world","bowyer_level_tax", cityId) else return delegate("world","set_bowyer_level_tax", cityId, v) end end
function M.cartwright_level_tax(cityId, v) if v==nil then return delegate("world","cartwright_level_tax", cityId) else return delegate("world","set_cartwright_level_tax", cityId, v) end end
function M.carpenter_level_tax(cityId, v) if v==nil then return delegate("world","carpenter_level_tax", cityId) else return delegate("world","set_carpenter_level_tax", cityId, v) end end
function M.ropemaker_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_level_tax", cityId) else return delegate("world","set_ropemaker_level_tax", cityId, v) end end
function M.cooper_level_tax(cityId, v) if v==nil then return delegate("world","cooper_level_tax", cityId) else return delegate("world","set_cooper_level_tax", cityId, v) end end
function M.spinner_level_tax(cityId, v) if v==nil then return delegate("world","spinner_level_tax", cityId) else return delegate("world","set_spinner_level_tax", cityId, v) end end
function M.turner_level_tax(cityId, v) if v==nil then return delegate("world","turner_level_tax", cityId) else return delegate("world","set_turner_level_tax", cityId, v) end end
function M.stonecutter_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter_level_tax", cityId) else return delegate("world","set_stonecutter_level_tax", cityId, v) end end
function M.cobbler_level_tax(cityId, v) if v==nil then return delegate("world","cobbler_level_tax", cityId) else return delegate("world","set_cobbler_level_tax", cityId, v) end end
function M.butcher_level_tax(cityId, v) if v==nil then return delegate("world","butcher_level_tax", cityId) else return delegate("world","set_butcher_level_tax", cityId, v) end end
function M.baker_level_tax(cityId, v) if v==nil then return delegate("world","baker_level_tax", cityId) else return delegate("world","set_baker_level_tax", cityId, v) end end
function M.shepherd_level_tax(cityId, v) if v==nil then return delegate("world","shepherd_level_tax", cityId) else return delegate("world","set_shepherd_level_tax", cityId, v) end end
function M.dairy_level_tax(cityId, v) if v==nil then return delegate("world","dairy_level_tax", cityId) else return delegate("world","set_dairy_level_tax", cityId, v) end end
function M.brewmaster_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster_level_tax", cityId) else return delegate("world","set_brewmaster_level_tax", cityId, v) end end
function M.miller_level_tax(cityId, v) if v==nil then return delegate("world","miller_level_tax", cityId) else return delegate("world","set_miller_level_tax", cityId, v) end end
function M.fishery_level_tax(cityId, v) if v==nil then return delegate("world","fishery_level_tax", cityId) else return delegate("world","set_fishery_level_tax", cityId, v) end end
function M.chandler_level_tax(cityId, v) if v==nil then return delegate("world","chandler_level_tax", cityId) else return delegate("world","set_chandler_level_tax", cityId, v) end end
function M.goldbeater_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater_level_tax", cityId) else return delegate("world","set_goldbeater_level_tax", cityId, v) end end
function M.potter_level_tax(cityId, v) if v==nil then return delegate("world","potter_level_tax", cityId) else return delegate("world","set_potter_level_tax", cityId, v) end end
function M.fowler_level_tax(cityId, v) if v==nil then return delegate("world","fowler_level_tax", cityId) else return delegate("world","set_fowler_level_tax", cityId, v) end end
function M.vintner_level_tax(cityId, v) if v==nil then return delegate("world","vintner_level_tax", cityId) else return delegate("world","set_vintner_level_tax", cityId, v) end end
function M.distiller_level_tax(cityId, v) if v==nil then return delegate("world","distiller_level_tax", cityId) else return delegate("world","set_distiller_level_tax", cityId, v) end end
function M.cook_level_tax(cityId, v) if v==nil then return delegate("world","cook_level_tax", cityId) else return delegate("world","set_cook_level_tax", cityId, v) end end
function M.brickmaker_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker_level_tax", cityId) else return delegate("world","set_brickmaker_level_tax", cityId, v) end end
function M.bathhouse_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse_level_tax", cityId) else return delegate("world","set_bathhouse_level_tax", cityId, v) end end
function M.barracks_level_tax(cityId, v) if v==nil then return delegate("world","barracks_level_tax", cityId) else return delegate("world","set_barracks_level_tax", cityId, v) end end
function M.school_level_tax(cityId, v) if v==nil then return delegate("world","school_level_tax", cityId) else return delegate("world","set_school_level_tax", cityId, v) end end
function M.library_level_tax(cityId, v) if v==nil then return delegate("world","library_level_tax", cityId) else return delegate("world","set_library_level_tax", cityId, v) end end
function M.mine_level_tax(cityId, v) if v==nil then return delegate("world","mine_level_tax", cityId) else return delegate("world","set_mine_level_tax", cityId, v) end end
function M.warehouse_level_tax(cityId, v) if v==nil then return delegate("world","warehouse_level_tax", cityId) else return delegate("world","set_warehouse_level_tax", cityId, v) end end
function M.garrison_level_tax(cityId, v) if v==nil then return delegate("world","garrison_level_tax", cityId) else return delegate("world","set_garrison_level_tax", cityId, v) end end
function M.monastery_level_tax(cityId, v) if v==nil then return delegate("world","monastery_level_tax", cityId) else return delegate("world","set_monastery_level_tax", cityId, v) end end
function M.cathedral_level_tax(cityId, v) if v==nil then return delegate("world","cathedral_level_tax", cityId) else return delegate("world","set_cathedral_level_tax", cityId, v) end end
function M.town_hall_level_tax(cityId, v) if v==nil then return delegate("world","town_hall_level_tax", cityId) else return delegate("world","set_town_hall_level_tax", cityId, v) end end
function M.market_level_tax(cityId, v) if v==nil then return delegate("world","market_level_tax", cityId) else return delegate("world","set_market_level_tax", cityId, v) end end
function M.harbor_level_tax(cityId, v) if v==nil then return delegate("world","harbor_level_tax", cityId) else return delegate("world","set_harbor_level_tax", cityId, v) end end
function M.guardhouse_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse_level_tax", cityId) else return delegate("world","set_guardhouse_level_tax", cityId, v) end end
function M.courthouse_level_tax(cityId, v) if v==nil then return delegate("world","courthouse_level_tax", cityId) else return delegate("world","set_courthouse_level_tax", cityId, v) end end
function M.univ_hall_level_tax(cityId, v) if v==nil then return delegate("world","univ_hall_level_tax", cityId) else return delegate("world","set_univ_hall_level_tax", cityId, v) end end
function M.castle_level_tax(cityId, v) if v==nil then return delegate("world","castle_level_tax", cityId) else return delegate("world","set_castle_level_tax", cityId, v) end end
function M.barracks2_level_tax(cityId, v) if v==nil then return delegate("world","barracks2_level_tax", cityId) else return delegate("world","set_barracks2_level_tax", cityId, v) end end
function M.stables_level_tax(cityId, v) if v==nil then return delegate("world","stables_level_tax", cityId) else return delegate("world","set_stables_level_tax", cityId, v) end end
function M.gates_level_tax(cityId, v) if v==nil then return delegate("world","gates_level_tax", cityId) else return delegate("world","set_gates_level_tax", cityId, v) end end
function M.sentry_level_tax(cityId, v) if v==nil then return delegate("world","sentry_level_tax", cityId) else return delegate("world","set_sentry_level_tax", cityId, v) end end
function M.well_level_tax(cityId, v) if v==nil then return delegate("world","well_level_tax", cityId) else return delegate("world","set_well_level_tax", cityId, v) end end
function M.bridge_level_tax(cityId, v) if v==nil then return delegate("world","bridge_level_tax", cityId) else return delegate("world","set_bridge_level_tax", cityId, v) end end
function M.wall_level_tax(cityId, v) if v==nil then return delegate("world","wall_level_tax", cityId) else return delegate("world","set_wall_level_tax", cityId, v) end end
function M.tower_level_tax(cityId, v) if v==nil then return delegate("world","tower_level_tax", cityId) else return delegate("world","set_tower_level_tax", cityId, v) end end
function M.forum_level_tax(cityId, v) if v==nil then return delegate("world","forum_level_tax", cityId) else return delegate("world","set_forum_level_tax", cityId, v) end end
function M.granary_level_tax(cityId, v) if v==nil then return delegate("world","granary_level_tax", cityId) else return delegate("world","set_granary_level_tax", cityId, v) end end
function M.prison_level_tax(cityId, v) if v==nil then return delegate("world","prison_level_tax", cityId) else return delegate("world","set_prison_level_tax", cityId, v) end end
function M.harbor_dock_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock_level_tax", cityId) else return delegate("world","set_harbor_dock_level_tax", cityId, v) end end
function M.guild_house_level_tax(cityId, v) if v==nil then return delegate("world","guild_house_level_tax", cityId) else return delegate("world","set_guild_house_level_tax", cityId, v) end end
function M.house_level_tax(cityId, v) if v==nil then return delegate("world","house_level_tax", cityId) else return delegate("world","set_house_level_tax", cityId, v) end end
function M.chapel_level_tax(cityId, v) if v==nil then return delegate("world","chapel_level_tax", cityId) else return delegate("world","set_chapel_level_tax", cityId, v) end end
function M.hospital_level_tax(cityId, v) if v==nil then return delegate("world","hospital_level_tax", cityId) else return delegate("world","set_hospital_level_tax", cityId, v) end end
function M.brothel_level_tax(cityId, v) if v==nil then return delegate("world","brothel_level_tax", cityId) else return delegate("world","set_brothel_level_tax", cityId, v) end end
function M.university_level_tax(cityId, v) if v==nil then return delegate("world","university_level_tax", cityId) else return delegate("world","set_university_level_tax", cityId, v) end end
function M.harbor_walls_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls_level_tax", cityId) else return delegate("world","set_harbor_walls_level_tax", cityId, v) end end
function M.schoolhouse_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse_level_tax", cityId) else return delegate("world","set_schoolhouse_level_tax", cityId, v) end end
function M.library_hall_level_tax(cityId, v) if v==nil then return delegate("world","library_hall_level_tax", cityId) else return delegate("world","set_library_hall_level_tax", cityId, v) end end
function M.barber_level_tax(cityId, v) if v==nil then return delegate("world","barber_level_tax", cityId) else return delegate("world","set_barber_level_tax", cityId, v) end end
function M.contor2_level_tax(cityId, v) if v==nil then return delegate("world","contor2_level_tax", cityId) else return delegate("world","set_contor2_level_tax", cityId, v) end end
function M.dice_house2_level_tax(cityId, v) if v==nil then return delegate("world","dice_house2_level_tax", cityId) else return delegate("world","set_dice_house2_level_tax", cityId, v) end end
function M.thieves2_level_tax(cityId, v) if v==nil then return delegate("world","thieves2_level_tax", cityId) else return delegate("world","set_thieves2_level_tax", cityId, v) end end
function M.ropemaker_ws2_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_ws2_level_tax", cityId) else return delegate("world","set_ropemaker_ws2_level_tax", cityId, v) end end
function M.tannery2_level_tax(cityId, v) if v==nil then return delegate("world","tannery2_level_tax", cityId) else return delegate("world","set_tannery2_level_tax", cityId, v) end end
function M.weaving2_level_tax(cityId, v) if v==nil then return delegate("world","weaving2_level_tax", cityId) else return delegate("world","set_weaving2_level_tax", cityId, v) end end
function M.mint2_level_tax(cityId, v) if v==nil then return delegate("world","mint2_level_tax", cityId) else return delegate("world","set_mint2_level_tax", cityId, v) end end
function M.herb_garden2_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden2_level_tax", cityId) else return delegate("world","set_herb_garden2_level_tax", cityId, v) end end
function M.vineyard2_level_tax(cityId, v) if v==nil then return delegate("world","vineyard2_level_tax", cityId) else return delegate("world","set_vineyard2_level_tax", cityId, v) end end
function M.pottery2_level_tax(cityId, v) if v==nil then return delegate("world","pottery2_level_tax", cityId) else return delegate("world","set_pottery2_level_tax", cityId, v) end end
function M.tailor2_level_tax(cityId, v) if v==nil then return delegate("world","tailor2_level_tax", cityId) else return delegate("world","set_tailor2_level_tax", cityId, v) end end
function M.tavern2_level_tax(cityId, v) if v==nil then return delegate("world","tavern2_level_tax", cityId) else return delegate("world","set_tavern2_level_tax", cityId, v) end end
function M.apothecary2_level_tax(cityId, v) if v==nil then return delegate("world","apothecary2_level_tax", cityId) else return delegate("world","set_apothecary2_level_tax", cityId, v) end end
function M.goldsmith2_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith2_level_tax", cityId) else return delegate("world","set_goldsmith2_level_tax", cityId, v) end end
function M.jeweler2_level_tax(cityId, v) if v==nil then return delegate("world","jeweler2_level_tax", cityId) else return delegate("world","set_jeweler2_level_tax", cityId, v) end end
function M.perfumer2_level_tax(cityId, v) if v==nil then return delegate("world","perfumer2_level_tax", cityId) else return delegate("world","set_perfumer2_level_tax", cityId, v) end end
function M.soapmaker2_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker2_level_tax", cityId) else return delegate("world","set_soapmaker2_level_tax", cityId, v) end end
function M.candlemaker2_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker2_level_tax", cityId) else return delegate("world","set_candlemaker2_level_tax", cityId, v) end end
function M.papermill2_level_tax(cityId, v) if v==nil then return delegate("world","papermill2_level_tax", cityId) else return delegate("world","set_papermill2_level_tax", cityId, v) end end
function M.printing2_level_tax(cityId, v) if v==nil then return delegate("world","printing2_level_tax", cityId) else return delegate("world","set_printing2_level_tax", cityId, v) end end
function M.toolmaker2_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker2_level_tax", cityId) else return delegate("world","set_toolmaker2_level_tax", cityId, v) end end
function M.charcoal2_level_tax(cityId, v) if v==nil then return delegate("world","charcoal2_level_tax", cityId) else return delegate("world","set_charcoal2_level_tax", cityId, v) end end
function M.furrier2_level_tax(cityId, v) if v==nil then return delegate("world","furrier2_level_tax", cityId) else return delegate("world","set_furrier2_level_tax", cityId, v) end end
function M.dyer2_level_tax(cityId, v) if v==nil then return delegate("world","dyer2_level_tax", cityId) else return delegate("world","set_dyer2_level_tax", cityId, v) end end
function M.saddler2_level_tax(cityId, v) if v==nil then return delegate("world","saddler2_level_tax", cityId) else return delegate("world","set_saddler2_level_tax", cityId, v) end end
function M.armorer2_level_tax(cityId, v) if v==nil then return delegate("world","armorer2_level_tax", cityId) else return delegate("world","set_armorer2_level_tax", cityId, v) end end
function M.bowyer2_level_tax(cityId, v) if v==nil then return delegate("world","bowyer2_level_tax", cityId) else return delegate("world","set_bowyer2_level_tax", cityId, v) end end
function M.cartwright2_level_tax(cityId, v) if v==nil then return delegate("world","cartwright2_level_tax", cityId) else return delegate("world","set_cartwright2_level_tax", cityId, v) end end
function M.carpenter2_level_tax(cityId, v) if v==nil then return delegate("world","carpenter2_level_tax", cityId) else return delegate("world","set_carpenter2_level_tax", cityId, v) end end
function M.ropemaker2_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker2_level_tax", cityId) else return delegate("world","set_ropemaker2_level_tax", cityId, v) end end
function M.cooper2_level_tax(cityId, v) if v==nil then return delegate("world","cooper2_level_tax", cityId) else return delegate("world","set_cooper2_level_tax", cityId, v) end end
function M.spinner2_level_tax(cityId, v) if v==nil then return delegate("world","spinner2_level_tax", cityId) else return delegate("world","set_spinner2_level_tax", cityId, v) end end
function M.turner2_level_tax(cityId, v) if v==nil then return delegate("world","turner2_level_tax", cityId) else return delegate("world","set_turner2_level_tax", cityId, v) end end
function M.stonecutter2_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter2_level_tax", cityId) else return delegate("world","set_stonecutter2_level_tax", cityId, v) end end
function M.cobbler2_level_tax(cityId, v) if v==nil then return delegate("world","cobbler2_level_tax", cityId) else return delegate("world","set_cobbler2_level_tax", cityId, v) end end
function M.butcher2_level_tax(cityId, v) if v==nil then return delegate("world","butcher2_level_tax", cityId) else return delegate("world","set_butcher2_level_tax", cityId, v) end end
function M.baker2_level_tax(cityId, v) if v==nil then return delegate("world","baker2_level_tax", cityId) else return delegate("world","set_baker2_level_tax", cityId, v) end end
function M.shepherd2_level_tax(cityId, v) if v==nil then return delegate("world","shepherd2_level_tax", cityId) else return delegate("world","set_shepherd2_level_tax", cityId, v) end end
function M.dairy2_level_tax(cityId, v) if v==nil then return delegate("world","dairy2_level_tax", cityId) else return delegate("world","set_dairy2_level_tax", cityId, v) end end
function M.brewmaster2_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster2_level_tax", cityId) else return delegate("world","set_brewmaster2_level_tax", cityId, v) end end
function M.miller2_level_tax(cityId, v) if v==nil then return delegate("world","miller2_level_tax", cityId) else return delegate("world","set_miller2_level_tax", cityId, v) end end
function M.fishery2_level_tax(cityId, v) if v==nil then return delegate("world","fishery2_level_tax", cityId) else return delegate("world","set_fishery2_level_tax", cityId, v) end end
function M.chandler2_level_tax(cityId, v) if v==nil then return delegate("world","chandler2_level_tax", cityId) else return delegate("world","set_chandler2_level_tax", cityId, v) end end
function M.goldbeater2_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater2_level_tax", cityId) else return delegate("world","set_goldbeater2_level_tax", cityId, v) end end
function M.potter2_level_tax(cityId, v) if v==nil then return delegate("world","potter2_level_tax", cityId) else return delegate("world","set_potter2_level_tax", cityId, v) end end
function M.fowler2_level_tax(cityId, v) if v==nil then return delegate("world","fowler2_level_tax", cityId) else return delegate("world","set_fowler2_level_tax", cityId, v) end end
function M.vintner2_level_tax(cityId, v) if v==nil then return delegate("world","vintner2_level_tax", cityId) else return delegate("world","set_vintner2_level_tax", cityId, v) end end
function M.distiller2_level_tax(cityId, v) if v==nil then return delegate("world","distiller2_level_tax", cityId) else return delegate("world","set_distiller2_level_tax", cityId, v) end end
function M.cook2_level_tax(cityId, v) if v==nil then return delegate("world","cook2_level_tax", cityId) else return delegate("world","set_cook2_level_tax", cityId, v) end end
function M.brickmaker2_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker2_level_tax", cityId) else return delegate("world","set_brickmaker2_level_tax", cityId, v) end end
function M.bathhouse2_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse2_level_tax", cityId) else return delegate("world","set_bathhouse2_level_tax", cityId, v) end end
function M.barracks3_level_tax(cityId, v) if v==nil then return delegate("world","barracks3_level_tax", cityId) else return delegate("world","set_barracks3_level_tax", cityId, v) end end
function M.school2_level_tax(cityId, v) if v==nil then return delegate("world","school2_level_tax", cityId) else return delegate("world","set_school2_level_tax", cityId, v) end end
function M.library2_level_tax(cityId, v) if v==nil then return delegate("world","library2_level_tax", cityId) else return delegate("world","set_library2_level_tax", cityId, v) end end
function M.mine2_level_tax(cityId, v) if v==nil then return delegate("world","mine2_level_tax", cityId) else return delegate("world","set_mine2_level_tax", cityId, v) end end
function M.warehouse2_level_tax(cityId, v) if v==nil then return delegate("world","warehouse2_level_tax", cityId) else return delegate("world","set_warehouse2_level_tax", cityId, v) end end
function M.garrison2_level_tax(cityId, v) if v==nil then return delegate("world","garrison2_level_tax", cityId) else return delegate("world","set_garrison2_level_tax", cityId, v) end end
function M.monastery2_level_tax(cityId, v) if v==nil then return delegate("world","monastery2_level_tax", cityId) else return delegate("world","set_monastery2_level_tax", cityId, v) end end
function M.cathedral2_level_tax(cityId, v) if v==nil then return delegate("world","cathedral2_level_tax", cityId) else return delegate("world","set_cathedral2_level_tax", cityId, v) end end
function M.town_hall2_level_tax(cityId, v) if v==nil then return delegate("world","town_hall2_level_tax", cityId) else return delegate("world","set_town_hall2_level_tax", cityId, v) end end
function M.market2_level_tax(cityId, v) if v==nil then return delegate("world","market2_level_tax", cityId) else return delegate("world","set_market2_level_tax", cityId, v) end end
function M.harbor2_level_tax(cityId, v) if v==nil then return delegate("world","harbor2_level_tax", cityId) else return delegate("world","set_harbor2_level_tax", cityId, v) end end
function M.guardhouse2_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse2_level_tax", cityId) else return delegate("world","set_guardhouse2_level_tax", cityId, v) end end
function M.courthouse2_level_tax(cityId, v) if v==nil then return delegate("world","courthouse2_level_tax", cityId) else return delegate("world","set_courthouse2_level_tax", cityId, v) end end
function M.univ_hall2_level_tax(cityId, v) if v==nil then return delegate("world","univ_hall2_level_tax", cityId) else return delegate("world","set_univ_hall2_level_tax", cityId, v) end end
function M.castle2_level_tax(cityId, v) if v==nil then return delegate("world","castle2_level_tax", cityId) else return delegate("world","set_castle2_level_tax", cityId, v) end end
function M.barracks4_level_tax(cityId, v) if v==nil then return delegate("world","barracks4_level_tax", cityId) else return delegate("world","set_barracks4_level_tax", cityId, v) end end
function M.stables2_level_tax(cityId, v) if v==nil then return delegate("world","stables2_level_tax", cityId) else return delegate("world","set_stables2_level_tax", cityId, v) end end
function M.gates2_level_tax(cityId, v) if v==nil then return delegate("world","gates2_level_tax", cityId) else return delegate("world","set_gates2_level_tax", cityId, v) end end
function M.sentry2_level_tax(cityId, v) if v==nil then return delegate("world","sentry2_level_tax", cityId) else return delegate("world","set_sentry2_level_tax", cityId, v) end end
function M.well2_level_tax(cityId, v) if v==nil then return delegate("world","well2_level_tax", cityId) else return delegate("world","set_well2_level_tax", cityId, v) end end
function M.bridge2_level_tax(cityId, v) if v==nil then return delegate("world","bridge2_level_tax", cityId) else return delegate("world","set_bridge2_level_tax", cityId, v) end end
function M.wall2_level_tax(cityId, v) if v==nil then return delegate("world","wall2_level_tax", cityId) else return delegate("world","set_wall2_level_tax", cityId, v) end end
function M.tower2_level_tax(cityId, v) if v==nil then return delegate("world","tower2_level_tax", cityId) else return delegate("world","set_tower2_level_tax", cityId, v) end end
function M.forum2_level_tax(cityId, v) if v==nil then return delegate("world","forum2_level_tax", cityId) else return delegate("world","set_forum2_level_tax", cityId, v) end end
function M.granary2_level_tax(cityId, v) if v==nil then return delegate("world","granary2_level_tax", cityId) else return delegate("world","set_granary2_level_tax", cityId, v) end end
function M.prison2_level_tax(cityId, v) if v==nil then return delegate("world","prison2_level_tax", cityId) else return delegate("world","set_prison2_level_tax", cityId, v) end end
function M.harbor_dock2_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock2_level_tax", cityId) else return delegate("world","set_harbor_dock2_level_tax", cityId, v) end end
function M.guild_house2_level_tax(cityId, v) if v==nil then return delegate("world","guild_house2_level_tax", cityId) else return delegate("world","set_guild_house2_level_tax", cityId, v) end end
function M.house2_level_tax(cityId, v) if v==nil then return delegate("world","house2_level_tax", cityId) else return delegate("world","set_house2_level_tax", cityId, v) end end
function M.chapel2_level_tax(cityId, v) if v==nil then return delegate("world","chapel2_level_tax", cityId) else return delegate("world","set_chapel2_level_tax", cityId, v) end end
function M.hospital2_level_tax(cityId, v) if v==nil then return delegate("world","hospital2_level_tax", cityId) else return delegate("world","set_hospital2_level_tax", cityId, v) end end
function M.brothel2_level_tax(cityId, v) if v==nil then return delegate("world","brothel2_level_tax", cityId) else return delegate("world","set_brothel2_level_tax", cityId, v) end end
function M.university2_level_tax(cityId, v) if v==nil then return delegate("world","university2_level_tax", cityId) else return delegate("world","set_university2_level_tax", cityId, v) end end
function M.harbor_walls2_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls2_level_tax", cityId) else return delegate("world","set_harbor_walls2_level_tax", cityId, v) end end
function M.schoolhouse2_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse2_level_tax", cityId) else return delegate("world","set_schoolhouse2_level_tax", cityId, v) end end
function M.library_hall2_level_tax(cityId, v) if v==nil then return delegate("world","library_hall2_level_tax", cityId) else return delegate("world","set_library_hall2_level_tax", cityId, v) end end
function M.barber2_level_tax(cityId, v) if v==nil then return delegate("world","barber2_level_tax", cityId) else return delegate("world","set_barber2_level_tax", cityId, v) end end
function M.contor3_level_tax(cityId, v) if v==nil then return delegate("world","contor3_level_tax", cityId) else return delegate("world","set_contor3_level_tax", cityId, v) end end
function M.dice_house3_level_tax(cityId, v) if v==nil then return delegate("world","dice_house3_level_tax", cityId) else return delegate("world","set_dice_house3_level_tax", cityId, v) end end
function M.thieves3_level_tax(cityId, v) if v==nil then return delegate("world","thieves3_level_tax", cityId) else return delegate("world","set_thieves3_level_tax", cityId, v) end end
function M.ropemaker_ws3_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_ws3_level_tax", cityId) else return delegate("world","set_ropemaker_ws3_level_tax", cityId, v) end end
function M.tannery3_level_tax(cityId, v) if v==nil then return delegate("world","tannery3_level_tax", cityId) else return delegate("world","set_tannery3_level_tax", cityId, v) end end
function M.weaving3_level_tax(cityId, v) if v==nil then return delegate("world","weaving3_level_tax", cityId) else return delegate("world","set_weaving3_level_tax", cityId, v) end end
function M.mint3_level_tax(cityId, v) if v==nil then return delegate("world","mint3_level_tax", cityId) else return delegate("world","set_mint3_level_tax", cityId, v) end end
function M.herb_garden3_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden3_level_tax", cityId) else return delegate("world","set_herb_garden3_level_tax", cityId, v) end end
function M.vineyard3_level_tax(cityId, v) if v==nil then return delegate("world","vineyard3_level_tax", cityId) else return delegate("world","set_vineyard3_level_tax", cityId, v) end end
function M.pottery3_level_tax(cityId, v) if v==nil then return delegate("world","pottery3_level_tax", cityId) else return delegate("world","set_pottery3_level_tax", cityId, v) end end
function M.tailor3_level_tax(cityId, v) if v==nil then return delegate("world","tailor3_level_tax", cityId) else return delegate("world","set_tailor3_level_tax", cityId, v) end end
function M.tavern3_level_tax(cityId, v) if v==nil then return delegate("world","tavern3_level_tax", cityId) else return delegate("world","set_tavern3_level_tax", cityId, v) end end
function M.apothecary3_level_tax(cityId, v) if v==nil then return delegate("world","apothecary3_level_tax", cityId) else return delegate("world","set_apothecary3_level_tax", cityId, v) end end
function M.goldsmith3_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith3_level_tax", cityId) else return delegate("world","set_goldsmith3_level_tax", cityId, v) end end
function M.jeweler3_level_tax(cityId, v) if v==nil then return delegate("world","jeweler3_level_tax", cityId) else return delegate("world","set_jeweler3_level_tax", cityId, v) end end
function M.perfumer3_level_tax(cityId, v) if v==nil then return delegate("world","perfumer3_level_tax", cityId) else return delegate("world","set_perfumer3_level_tax", cityId, v) end end
function M.soapmaker3_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker3_level_tax", cityId) else return delegate("world","set_soapmaker3_level_tax", cityId, v) end end
function M.candlemaker3_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker3_level_tax", cityId) else return delegate("world","set_candlemaker3_level_tax", cityId, v) end end
function M.papermill3_level_tax(cityId, v) if v==nil then return delegate("world","papermill3_level_tax", cityId) else return delegate("world","set_papermill3_level_tax", cityId, v) end end
function M.printing3_level_tax(cityId, v) if v==nil then return delegate("world","printing3_level_tax", cityId) else return delegate("world","set_printing3_level_tax", cityId, v) end end
function M.toolmaker3_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker3_level_tax", cityId) else return delegate("world","set_toolmaker3_level_tax", cityId, v) end end
function M.charcoal3_level_tax(cityId, v) if v==nil then return delegate("world","charcoal3_level_tax", cityId) else return delegate("world","set_charcoal3_level_tax", cityId, v) end end
function M.furrier3_level_tax(cityId, v) if v==nil then return delegate("world","furrier3_level_tax", cityId) else return delegate("world","set_furrier3_level_tax", cityId, v) end end
function M.dyer3_level_tax(cityId, v) if v==nil then return delegate("world","dyer3_level_tax", cityId) else return delegate("world","set_dyer3_level_tax", cityId, v) end end
function M.saddler3_level_tax(cityId, v) if v==nil then return delegate("world","saddler3_level_tax", cityId) else return delegate("world","set_saddler3_level_tax", cityId, v) end end
function M.armorer3_level_tax(cityId, v) if v==nil then return delegate("world","armorer3_level_tax", cityId) else return delegate("world","set_armorer3_level_tax", cityId, v) end end
function M.bowyer3_level_tax(cityId, v) if v==nil then return delegate("world","bowyer3_level_tax", cityId) else return delegate("world","set_bowyer3_level_tax", cityId, v) end end
function M.cartwright3_level_tax(cityId, v) if v==nil then return delegate("world","cartwright3_level_tax", cityId) else return delegate("world","set_cartwright3_level_tax", cityId, v) end end
function M.carpenter3_level_tax(cityId, v) if v==nil then return delegate("world","carpenter3_level_tax", cityId) else return delegate("world","set_carpenter3_level_tax", cityId, v) end end
function M.ropemaker3_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker3_level_tax", cityId) else return delegate("world","set_ropemaker3_level_tax", cityId, v) end end
function M.cooper3_level_tax(cityId, v) if v==nil then return delegate("world","cooper3_level_tax", cityId) else return delegate("world","set_cooper3_level_tax", cityId, v) end end
function M.spinner3_level_tax(cityId, v) if v==nil then return delegate("world","spinner3_level_tax", cityId) else return delegate("world","set_spinner3_level_tax", cityId, v) end end
function M.turner3_level_tax(cityId, v) if v==nil then return delegate("world","turner3_level_tax", cityId) else return delegate("world","set_turner3_level_tax", cityId, v) end end
function M.stonecutter3_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter3_level_tax", cityId) else return delegate("world","set_stonecutter3_level_tax", cityId, v) end end
function M.cobbler3_level_tax(cityId, v) if v==nil then return delegate("world","cobbler3_level_tax", cityId) else return delegate("world","set_cobbler3_level_tax", cityId, v) end end
function M.butcher3_level_tax(cityId, v) if v==nil then return delegate("world","butcher3_level_tax", cityId) else return delegate("world","set_butcher3_level_tax", cityId, v) end end
function M.baker3_level_tax(cityId, v) if v==nil then return delegate("world","baker3_level_tax", cityId) else return delegate("world","set_baker3_level_tax", cityId, v) end end
function M.shepherd3_level_tax(cityId, v) if v==nil then return delegate("world","shepherd3_level_tax", cityId) else return delegate("world","set_shepherd3_level_tax", cityId, v) end end
function M.dairy3_level_tax(cityId, v) if v==nil then return delegate("world","dairy3_level_tax", cityId) else return delegate("world","set_dairy3_level_tax", cityId, v) end end
function M.brewmaster3_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster3_level_tax", cityId) else return delegate("world","set_brewmaster3_level_tax", cityId, v) end end
function M.miller3_level_tax(cityId, v) if v==nil then return delegate("world","miller3_level_tax", cityId) else return delegate("world","set_miller3_level_tax", cityId, v) end end
function M.fishery3_level_tax(cityId, v) if v==nil then return delegate("world","fishery3_level_tax", cityId) else return delegate("world","set_fishery3_level_tax", cityId, v) end end
function M.chandler3_level_tax(cityId, v) if v==nil then return delegate("world","chandler3_level_tax", cityId) else return delegate("world","set_chandler3_level_tax", cityId, v) end end
function M.goldbeater3_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater3_level_tax", cityId) else return delegate("world","set_goldbeater3_level_tax", cityId, v) end end
function M.potter3_level_tax(cityId, v) if v==nil then return delegate("world","potter3_level_tax", cityId) else return delegate("world","set_potter3_level_tax", cityId, v) end end
function M.fowler3_level_tax(cityId, v) if v==nil then return delegate("world","fowler3_level_tax", cityId) else return delegate("world","set_fowler3_level_tax", cityId, v) end end
function M.vintner3_level_tax(cityId, v) if v==nil then return delegate("world","vintner3_level_tax", cityId) else return delegate("world","set_vintner3_level_tax", cityId, v) end end
function M.distiller3_level_tax(cityId, v) if v==nil then return delegate("world","distiller3_level_tax", cityId) else return delegate("world","set_distiller3_level_tax", cityId, v) end end
function M.cook3_level_tax(cityId, v) if v==nil then return delegate("world","cook3_level_tax", cityId) else return delegate("world","set_cook3_level_tax", cityId, v) end end
function M.brickmaker3_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker3_level_tax", cityId) else return delegate("world","set_brickmaker3_level_tax", cityId, v) end end
function M.bathhouse3_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse3_level_tax", cityId) else return delegate("world","set_bathhouse3_level_tax", cityId, v) end end
function M.barracks5_level_tax(cityId, v) if v==nil then return delegate("world","barracks5_level_tax", cityId) else return delegate("world","set_barracks5_level_tax", cityId, v) end end
function M.school3_level_tax(cityId, v) if v==nil then return delegate("world","school3_level_tax", cityId) else return delegate("world","set_school3_level_tax", cityId, v) end end
function M.library3_level_tax(cityId, v) if v==nil then return delegate("world","library3_level_tax", cityId) else return delegate("world","set_library3_level_tax", cityId, v) end end
function M.mine3_level_tax(cityId, v) if v==nil then return delegate("world","mine3_level_tax", cityId) else return delegate("world","set_mine3_level_tax", cityId, v) end end
function M.warehouse3_level_tax(cityId, v) if v==nil then return delegate("world","warehouse3_level_tax", cityId) else return delegate("world","set_warehouse3_level_tax", cityId, v) end end
function M.garrison3_level_tax(cityId, v) if v==nil then return delegate("world","garrison3_level_tax", cityId) else return delegate("world","set_garrison3_level_tax", cityId, v) end end
function M.monastery3_level_tax(cityId, v) if v==nil then return delegate("world","monastery3_level_tax", cityId) else return delegate("world","set_monastery3_level_tax", cityId, v) end end
function M.cathedral3_level_tax(cityId, v) if v==nil then return delegate("world","cathedral3_level_tax", cityId) else return delegate("world","set_cathedral3_level_tax", cityId, v) end end
function M.town_hall3_level_tax(cityId, v) if v==nil then return delegate("world","town_hall3_level_tax", cityId) else return delegate("world","set_town_hall3_level_tax", cityId, v) end end
function M.market3_level_tax(cityId, v) if v==nil then return delegate("world","market3_level_tax", cityId) else return delegate("world","set_market3_level_tax", cityId, v) end end
function M.harbor3_level_tax(cityId, v) if v==nil then return delegate("world","harbor3_level_tax", cityId) else return delegate("world","set_harbor3_level_tax", cityId, v) end end
function M.guardhouse3_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse3_level_tax", cityId) else return delegate("world","set_guardhouse3_level_tax", cityId, v) end end
function M.courthouse3_level_tax(cityId, v) if v==nil then return delegate("world","courthouse3_level_tax", cityId) else return delegate("world","set_courthouse3_level_tax", cityId, v) end end
function M.univ_hall3_level_tax(cityId, v) if v==nil then return delegate("world","univ_hall3_level_tax", cityId) else return delegate("world","set_univ_hall3_level_tax", cityId, v) end end
function M.castle3_level_tax(cityId, v) if v==nil then return delegate("world","castle3_level_tax", cityId) else return delegate("world","set_castle3_level_tax", cityId, v) end end
function M.barracks6_level_tax(cityId, v) if v==nil then return delegate("world","barracks6_level_tax", cityId) else return delegate("world","set_barracks6_level_tax", cityId, v) end end
function M.stables3_level_tax(cityId, v) if v==nil then return delegate("world","stables3_level_tax", cityId) else return delegate("world","set_stables3_level_tax", cityId, v) end end
function M.gates3_level_tax(cityId, v) if v==nil then return delegate("world","gates3_level_tax", cityId) else return delegate("world","set_gates3_level_tax", cityId, v) end end
function M.sentry3_level_tax(cityId, v) if v==nil then return delegate("world","sentry3_level_tax", cityId) else return delegate("world","set_sentry3_level_tax", cityId, v) end end
function M.well3_level_tax(cityId, v) if v==nil then return delegate("world","well3_level_tax", cityId) else return delegate("world","set_well3_level_tax", cityId, v) end end
function M.bridge3_level_tax(cityId, v) if v==nil then return delegate("world","bridge3_level_tax", cityId) else return delegate("world","set_bridge3_level_tax", cityId, v) end end
function M.wall3_level_tax(cityId, v) if v==nil then return delegate("world","wall3_level_tax", cityId) else return delegate("world","set_wall3_level_tax", cityId, v) end end
function M.tower3_level_tax(cityId, v) if v==nil then return delegate("world","tower3_level_tax", cityId) else return delegate("world","set_tower3_level_tax", cityId, v) end end
function M.forum3_level_tax(cityId, v) if v==nil then return delegate("world","forum3_level_tax", cityId) else return delegate("world","set_forum3_level_tax", cityId, v) end end
function M.granary3_level_tax(cityId, v) if v==nil then return delegate("world","granary3_level_tax", cityId) else return delegate("world","set_granary3_level_tax", cityId, v) end end
function M.prison3_level_tax(cityId, v) if v==nil then return delegate("world","prison3_level_tax", cityId) else return delegate("world","set_prison3_level_tax", cityId, v) end end
function M.harbor_dock3_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock3_level_tax", cityId) else return delegate("world","set_harbor_dock3_level_tax", cityId, v) end end
function M.guild_house3_level_tax(cityId, v) if v==nil then return delegate("world","guild_house3_level_tax", cityId) else return delegate("world","set_guild_house3_level_tax", cityId, v) end end
function M.house3_level_tax(cityId, v) if v==nil then return delegate("world","house3_level_tax", cityId) else return delegate("world","set_house3_level_tax", cityId, v) end end
function M.chapel3_level_tax(cityId, v) if v==nil then return delegate("world","chapel3_level_tax", cityId) else return delegate("world","set_chapel3_level_tax", cityId, v) end end
function M.hospital3_level_tax(cityId, v) if v==nil then return delegate("world","hospital3_level_tax", cityId) else return delegate("world","set_hospital3_level_tax", cityId, v) end end
function M.brothel3_level_tax(cityId, v) if v==nil then return delegate("world","brothel3_level_tax", cityId) else return delegate("world","set_brothel3_level_tax", cityId, v) end end
function M.university3_level_tax(cityId, v) if v==nil then return delegate("world","university3_level_tax", cityId) else return delegate("world","set_university3_level_tax", cityId, v) end end
function M.harbor_walls3_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls3_level_tax", cityId) else return delegate("world","set_harbor_walls3_level_tax", cityId, v) end end
function M.schoolhouse3_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse3_level_tax", cityId) else return delegate("world","set_schoolhouse3_level_tax", cityId, v) end end
function M.library_hall3_level_tax(cityId, v) if v==nil then return delegate("world","library_hall3_level_tax", cityId) else return delegate("world","set_library_hall3_level_tax", cityId, v) end end
function M.barber3_level_tax(cityId, v) if v==nil then return delegate("world","barber3_level_tax", cityId) else return delegate("world","set_barber3_level_tax", cityId, v) end end
function M.contor4_level_tax(cityId, v) if v==nil then return delegate("world","contor4_level_tax", cityId) else return delegate("world","set_contor4_level_tax", cityId, v) end end
function M.dice_house4_level_tax(cityId, v) if v==nil then return delegate("world","dice_house4_level_tax", cityId) else return delegate("world","set_dice_house4_level_tax", cityId, v) end end
function M.thieves4_level_tax(cityId, v) if v==nil then return delegate("world","thieves4_level_tax", cityId) else return delegate("world","set_thieves4_level_tax", cityId, v) end end
function M.ropemaker_ws4_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_ws4_level_tax", cityId) else return delegate("world","set_ropemaker_ws4_level_tax", cityId, v) end end
function M.tannery4_level_tax(cityId, v) if v==nil then return delegate("world","tannery4_level_tax", cityId) else return delegate("world","set_tannery4_level_tax", cityId, v) end end
function M.weaving4_level_tax(cityId, v) if v==nil then return delegate("world","weaving4_level_tax", cityId) else return delegate("world","set_weaving4_level_tax", cityId, v) end end
function M.mint4_level_tax(cityId, v) if v==nil then return delegate("world","mint4_level_tax", cityId) else return delegate("world","set_mint4_level_tax", cityId, v) end end
function M.herb_garden4_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden4_level_tax", cityId) else return delegate("world","set_herb_garden4_level_tax", cityId, v) end end
function M.vineyard4_level_tax(cityId, v) if v==nil then return delegate("world","vineyard4_level_tax", cityId) else return delegate("world","set_vineyard4_level_tax", cityId, v) end end
function M.pottery4_level_tax(cityId, v) if v==nil then return delegate("world","pottery4_level_tax", cityId) else return delegate("world","set_pottery4_level_tax", cityId, v) end end
function M.tailor4_level_tax(cityId, v) if v==nil then return delegate("world","tailor4_level_tax", cityId) else return delegate("world","set_tailor4_level_tax", cityId, v) end end
function M.tavern4_level_tax(cityId, v) if v==nil then return delegate("world","tavern4_level_tax", cityId) else return delegate("world","set_tavern4_level_tax", cityId, v) end end
function M.apothecary4_level_tax(cityId, v) if v==nil then return delegate("world","apothecary4_level_tax", cityId) else return delegate("world","set_apothecary4_level_tax", cityId, v) end end
function M.goldsmith4_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith4_level_tax", cityId) else return delegate("world","set_goldsmith4_level_tax", cityId, v) end end
function M.jeweler4_level_tax(cityId, v) if v==nil then return delegate("world","jeweler4_level_tax", cityId) else return delegate("world","set_jeweler4_level_tax", cityId, v) end end
function M.perfumer4_level_tax(cityId, v) if v==nil then return delegate("world","perfumer4_level_tax", cityId) else return delegate("world","set_perfumer4_level_tax", cityId, v) end end
function M.soapmaker4_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker4_level_tax", cityId) else return delegate("world","set_soapmaker4_level_tax", cityId, v) end end
function M.candlemaker4_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker4_level_tax", cityId) else return delegate("world","set_candlemaker4_level_tax", cityId, v) end end
function M.papermill4_level_tax(cityId, v) if v==nil then return delegate("world","papermill4_level_tax", cityId) else return delegate("world","set_papermill4_level_tax", cityId, v) end end
function M.printing4_level_tax(cityId, v) if v==nil then return delegate("world","printing4_level_tax", cityId) else return delegate("world","set_printing4_level_tax", cityId, v) end end
function M.toolmaker4_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker4_level_tax", cityId) else return delegate("world","set_toolmaker4_level_tax", cityId, v) end end
function M.charcoal4_level_tax(cityId, v) if v==nil then return delegate("world","charcoal4_level_tax", cityId) else return delegate("world","set_charcoal4_level_tax", cityId, v) end end
function M.furrier4_level_tax(cityId, v) if v==nil then return delegate("world","furrier4_level_tax", cityId) else return delegate("world","set_furrier4_level_tax", cityId, v) end end
function M.dyer4_level_tax(cityId, v) if v==nil then return delegate("world","dyer4_level_tax", cityId) else return delegate("world","set_dyer4_level_tax", cityId, v) end end
function M.saddler4_level_tax(cityId, v) if v==nil then return delegate("world","saddler4_level_tax", cityId) else return delegate("world","set_saddler4_level_tax", cityId, v) end end
function M.armorer4_level_tax(cityId, v) if v==nil then return delegate("world","armorer4_level_tax", cityId) else return delegate("world","set_armorer4_level_tax", cityId, v) end end
function M.bowyer4_level_tax(cityId, v) if v==nil then return delegate("world","bowyer4_level_tax", cityId) else return delegate("world","set_bowyer4_level_tax", cityId, v) end end
function M.cartwright4_level_tax(cityId, v) if v==nil then return delegate("world","cartwright4_level_tax", cityId) else return delegate("world","set_cartwright4_level_tax", cityId, v) end end
function M.carpenter4_level_tax(cityId, v) if v==nil then return delegate("world","carpenter4_level_tax", cityId) else return delegate("world","set_carpenter4_level_tax", cityId, v) end end
function M.ropemaker4_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker4_level_tax", cityId) else return delegate("world","set_ropemaker4_level_tax", cityId, v) end end
function M.cooper4_level_tax(cityId, v) if v==nil then return delegate("world","cooper4_level_tax", cityId) else return delegate("world","set_cooper4_level_tax", cityId, v) end end
function M.spinner4_level_tax(cityId, v) if v==nil then return delegate("world","spinner4_level_tax", cityId) else return delegate("world","set_spinner4_level_tax", cityId, v) end end
function M.turner4_level_tax(cityId, v) if v==nil then return delegate("world","turner4_level_tax", cityId) else return delegate("world","set_turner4_level_tax", cityId, v) end end
function M.stonecutter4_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter4_level_tax", cityId) else return delegate("world","set_stonecutter4_level_tax", cityId, v) end end
function M.cobbler4_level_tax(cityId, v) if v==nil then return delegate("world","cobbler4_level_tax", cityId) else return delegate("world","set_cobbler4_level_tax", cityId, v) end end
function M.butcher4_level_tax(cityId, v) if v==nil then return delegate("world","butcher4_level_tax", cityId) else return delegate("world","set_butcher4_level_tax", cityId, v) end end
function M.baker4_level_tax(cityId, v) if v==nil then return delegate("world","baker4_level_tax", cityId) else return delegate("world","set_baker4_level_tax", cityId, v) end end
function M.shepherd4_level_tax(cityId, v) if v==nil then return delegate("world","shepherd4_level_tax", cityId) else return delegate("world","set_shepherd4_level_tax", cityId, v) end end
function M.dairy4_level_tax(cityId, v) if v==nil then return delegate("world","dairy4_level_tax", cityId) else return delegate("world","set_dairy4_level_tax", cityId, v) end end
function M.brewmaster4_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster4_level_tax", cityId) else return delegate("world","set_brewmaster4_level_tax", cityId, v) end end
function M.miller4_level_tax(cityId, v) if v==nil then return delegate("world","miller4_level_tax", cityId) else return delegate("world","set_miller4_level_tax", cityId, v) end end
function M.fishery4_level_tax(cityId, v) if v==nil then return delegate("world","fishery4_level_tax", cityId) else return delegate("world","set_fishery4_level_tax", cityId, v) end end
function M.chandler4_level_tax(cityId, v) if v==nil then return delegate("world","chandler4_level_tax", cityId) else return delegate("world","set_chandler4_level_tax", cityId, v) end end
function M.goldbeater4_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater4_level_tax", cityId) else return delegate("world","set_goldbeater4_level_tax", cityId, v) end end
function M.potter4_level_tax(cityId, v) if v==nil then return delegate("world","potter4_level_tax", cityId) else return delegate("world","set_potter4_level_tax", cityId, v) end end
function M.fowler4_level_tax(cityId, v) if v==nil then return delegate("world","fowler4_level_tax", cityId) else return delegate("world","set_fowler4_level_tax", cityId, v) end end
function M.vintner4_level_tax(cityId, v) if v==nil then return delegate("world","vintner4_level_tax", cityId) else return delegate("world","set_vintner4_level_tax", cityId, v) end end
function M.distiller4_level_tax(cityId, v) if v==nil then return delegate("world","distiller4_level_tax", cityId) else return delegate("world","set_distiller4_level_tax", cityId, v) end end
function M.cook4_level_tax(cityId, v) if v==nil then return delegate("world","cook4_level_tax", cityId) else return delegate("world","set_cook4_level_tax", cityId, v) end end
function M.brickmaker4_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker4_level_tax", cityId) else return delegate("world","set_brickmaker4_level_tax", cityId, v) end end
function M.bathhouse4_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse4_level_tax", cityId) else return delegate("world","set_bathhouse4_level_tax", cityId, v) end end
function M.barracks7_level_tax(cityId, v) if v==nil then return delegate("world","barracks7_level_tax", cityId) else return delegate("world","set_barracks7_level_tax", cityId, v) end end
function M.school4_level_tax(cityId, v) if v==nil then return delegate("world","school4_level_tax", cityId) else return delegate("world","set_school4_level_tax", cityId, v) end end
function M.library4_level_tax(cityId, v) if v==nil then return delegate("world","library4_level_tax", cityId) else return delegate("world","set_library4_level_tax", cityId, v) end end
function M.mine4_level_tax(cityId, v) if v==nil then return delegate("world","mine4_level_tax", cityId) else return delegate("world","set_mine4_level_tax", cityId, v) end end
function M.warehouse4_level_tax(cityId, v) if v==nil then return delegate("world","warehouse4_level_tax", cityId) else return delegate("world","set_warehouse4_level_tax", cityId, v) end end
function M.garrison4_level_tax(cityId, v) if v==nil then return delegate("world","garrison4_level_tax", cityId) else return delegate("world","set_garrison4_level_tax", cityId, v) end end
function M.monastery4_level_tax(cityId, v) if v==nil then return delegate("world","monastery4_level_tax", cityId) else return delegate("world","set_monastery4_level_tax", cityId, v) end end
function M.cathedral4_level_tax(cityId, v) if v==nil then return delegate("world","cathedral4_level_tax", cityId) else return delegate("world","set_cathedral4_level_tax", cityId, v) end end
function M.town_hall4_level_tax(cityId, v) if v==nil then return delegate("world","town_hall4_level_tax", cityId) else return delegate("world","set_town_hall4_level_tax", cityId, v) end end
function M.market4_level_tax(cityId, v) if v==nil then return delegate("world","market4_level_tax", cityId) else return delegate("world","set_market4_level_tax", cityId, v) end end
function M.harbor4_level_tax(cityId, v) if v==nil then return delegate("world","harbor4_level_tax", cityId) else return delegate("world","set_harbor4_level_tax", cityId, v) end end
function M.guardhouse4_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse4_level_tax", cityId) else return delegate("world","set_guardhouse4_level_tax", cityId, v) end end
function M.courthouse4_level_tax(cityId, v) if v==nil then return delegate("world","courthouse4_level_tax", cityId) else return delegate("world","set_courthouse4_level_tax", cityId, v) end end
function M.univ_hall4_level_tax(cityId, v) if v==nil then return delegate("world","univ_hall4_level_tax", cityId) else return delegate("world","set_univ_hall4_level_tax", cityId, v) end end
function M.castle4_level_tax(cityId, v) if v==nil then return delegate("world","castle4_level_tax", cityId) else return delegate("world","set_castle4_level_tax", cityId, v) end end
function M.barracks8_level_tax(cityId, v) if v==nil then return delegate("world","barracks8_level_tax", cityId) else return delegate("world","set_barracks8_level_tax", cityId, v) end end
function M.stables4_level_tax(cityId, v) if v==nil then return delegate("world","stables4_level_tax", cityId) else return delegate("world","set_stables4_level_tax", cityId, v) end end
function M.gates4_level_tax(cityId, v) if v==nil then return delegate("world","gates4_level_tax", cityId) else return delegate("world","set_gates4_level_tax", cityId, v) end end
function M.sentry4_level_tax(cityId, v) if v==nil then return delegate("world","sentry4_level_tax", cityId) else return delegate("world","set_sentry4_level_tax", cityId, v) end end
function M.well4_level_tax(cityId, v) if v==nil then return delegate("world","well4_level_tax", cityId) else return delegate("world","set_well4_level_tax", cityId, v) end end
function M.bridge4_level_tax(cityId, v) if v==nil then return delegate("world","bridge4_level_tax", cityId) else return delegate("world","set_bridge4_level_tax", cityId, v) end end
function M.wall4_level_tax(cityId, v) if v==nil then return delegate("world","wall4_level_tax", cityId) else return delegate("world","set_wall4_level_tax", cityId, v) end end
function M.tower4_level_tax(cityId, v) if v==nil then return delegate("world","tower4_level_tax", cityId) else return delegate("world","set_tower4_level_tax", cityId, v) end end
function M.forum4_level_tax(cityId, v) if v==nil then return delegate("world","forum4_level_tax", cityId) else return delegate("world","set_forum4_level_tax", cityId, v) end end
function M.granary4_level_tax(cityId, v) if v==nil then return delegate("world","granary4_level_tax", cityId) else return delegate("world","set_granary4_level_tax", cityId, v) end end
function M.prison4_level_tax(cityId, v) if v==nil then return delegate("world","prison4_level_tax", cityId) else return delegate("world","set_prison4_level_tax", cityId, v) end end
function M.harbor_dock4_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock4_level_tax", cityId) else return delegate("world","set_harbor_dock4_level_tax", cityId, v) end end
function M.guild_house4_level_tax(cityId, v) if v==nil then return delegate("world","guild_house4_level_tax", cityId) else return delegate("world","set_guild_house4_level_tax", cityId, v) end end
function M.house4_level_tax(cityId, v) if v==nil then return delegate("world","house4_level_tax", cityId) else return delegate("world","set_house4_level_tax", cityId, v) end end
function M.chapel4_level_tax(cityId, v) if v==nil then return delegate("world","chapel4_level_tax", cityId) else return delegate("world","set_chapel4_level_tax", cityId, v) end end
function M.hospital4_level_tax(cityId, v) if v==nil then return delegate("world","hospital4_level_tax", cityId) else return delegate("world","set_hospital4_level_tax", cityId, v) end end
function M.brothel4_level_tax(cityId, v) if v==nil then return delegate("world","brothel4_level_tax", cityId) else return delegate("world","set_brothel4_level_tax", cityId, v) end end
function M.university4_level_tax(cityId, v) if v==nil then return delegate("world","university4_level_tax", cityId) else return delegate("world","set_university4_level_tax", cityId, v) end end
function M.harbor_walls4_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls4_level_tax", cityId) else return delegate("world","set_harbor_walls4_level_tax", cityId, v) end end
function M.schoolhouse4_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse4_level_tax", cityId) else return delegate("world","set_schoolhouse4_level_tax", cityId, v) end end
function M.library_hall4_level_tax(cityId, v) if v==nil then return delegate("world","library_hall4_level_tax", cityId) else return delegate("world","set_library_hall4_level_tax", cityId, v) end end
function M.barber4_level_tax(cityId, v) if v==nil then return delegate("world","barber4_level_tax", cityId) else return delegate("world","set_barber4_level_tax", cityId, v) end end
function M.contor5_level_tax(cityId, v) if v==nil then return delegate("world","contor5_level_tax", cityId) else return delegate("world","set_contor5_level_tax", cityId, v) end end
function M.dice_house5_level_tax(cityId, v) if v==nil then return delegate("world","dice_house5_level_tax", cityId) else return delegate("world","set_dice_house5_level_tax", cityId, v) end end
function M.thieves5_level_tax(cityId, v) if v==nil then return delegate("world","thieves5_level_tax", cityId) else return delegate("world","set_thieves5_level_tax", cityId, v) end end
function M.ropemaker_ws5_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_ws5_level_tax", cityId) else return delegate("world","set_ropemaker_ws5_level_tax", cityId, v) end end
function M.tannery5_level_tax(cityId, v) if v==nil then return delegate("world","tannery5_level_tax", cityId) else return delegate("world","set_tannery5_level_tax", cityId, v) end end
function M.weaving5_level_tax(cityId, v) if v==nil then return delegate("world","weaving5_level_tax", cityId) else return delegate("world","set_weaving5_level_tax", cityId, v) end end
function M.mint5_level_tax(cityId, v) if v==nil then return delegate("world","mint5_level_tax", cityId) else return delegate("world","set_mint5_level_tax", cityId, v) end end
function M.herb_garden5_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden5_level_tax", cityId) else return delegate("world","set_herb_garden5_level_tax", cityId, v) end end
function M.vineyard5_level_tax(cityId, v) if v==nil then return delegate("world","vineyard5_level_tax", cityId) else return delegate("world","set_vineyard5_level_tax", cityId, v) end end
function M.pottery5_level_tax(cityId, v) if v==nil then return delegate("world","pottery5_level_tax", cityId) else return delegate("world","set_pottery5_level_tax", cityId, v) end end
function M.tailor5_level_tax(cityId, v) if v==nil then return delegate("world","tailor5_level_tax", cityId) else return delegate("world","set_tailor5_level_tax", cityId, v) end end
function M.tavern5_level_tax(cityId, v) if v==nil then return delegate("world","tavern5_level_tax", cityId) else return delegate("world","set_tavern5_level_tax", cityId, v) end end
function M.apothecary5_level_tax(cityId, v) if v==nil then return delegate("world","apothecary5_level_tax", cityId) else return delegate("world","set_apothecary5_level_tax", cityId, v) end end
function M.goldsmith5_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith5_level_tax", cityId) else return delegate("world","set_goldsmith5_level_tax", cityId, v) end end
function M.jeweler5_level_tax(cityId, v) if v==nil then return delegate("world","jeweler5_level_tax", cityId) else return delegate("world","set_jeweler5_level_tax", cityId, v) end end
function M.perfumer5_level_tax(cityId, v) if v==nil then return delegate("world","perfumer5_level_tax", cityId) else return delegate("world","set_perfumer5_level_tax", cityId, v) end end
function M.soapmaker5_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker5_level_tax", cityId) else return delegate("world","set_soapmaker5_level_tax", cityId, v) end end
function M.candlemaker5_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker5_level_tax", cityId) else return delegate("world","set_candlemaker5_level_tax", cityId, v) end end
function M.papermill5_level_tax(cityId, v) if v==nil then return delegate("world","papermill5_level_tax", cityId) else return delegate("world","set_papermill5_level_tax", cityId, v) end end
function M.printing5_level_tax(cityId, v) if v==nil then return delegate("world","printing5_level_tax", cityId) else return delegate("world","set_printing5_level_tax", cityId, v) end end
function M.toolmaker5_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker5_level_tax", cityId) else return delegate("world","set_toolmaker5_level_tax", cityId, v) end end
function M.charcoal5_level_tax(cityId, v) if v==nil then return delegate("world","charcoal5_level_tax", cityId) else return delegate("world","set_charcoal5_level_tax", cityId, v) end end
function M.furrier5_level_tax(cityId, v) if v==nil then return delegate("world","furrier5_level_tax", cityId) else return delegate("world","set_furrier5_level_tax", cityId, v) end end
function M.dyer5_level_tax(cityId, v) if v==nil then return delegate("world","dyer5_level_tax", cityId) else return delegate("world","set_dyer5_level_tax", cityId, v) end end
function M.saddler5_level_tax(cityId, v) if v==nil then return delegate("world","saddler5_level_tax", cityId) else return delegate("world","set_saddler5_level_tax", cityId, v) end end
function M.armorer5_level_tax(cityId, v) if v==nil then return delegate("world","armorer5_level_tax", cityId) else return delegate("world","set_armorer5_level_tax", cityId, v) end end
function M.bowyer5_level_tax(cityId, v) if v==nil then return delegate("world","bowyer5_level_tax", cityId) else return delegate("world","set_bowyer5_level_tax", cityId, v) end end
function M.cartwright5_level_tax(cityId, v) if v==nil then return delegate("world","cartwright5_level_tax", cityId) else return delegate("world","set_cartwright5_level_tax", cityId, v) end end
function M.carpenter5_level_tax(cityId, v) if v==nil then return delegate("world","carpenter5_level_tax", cityId) else return delegate("world","set_carpenter5_level_tax", cityId, v) end end
function M.ropemaker5_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker5_level_tax", cityId) else return delegate("world","set_ropemaker5_level_tax", cityId, v) end end
function M.cooper5_level_tax(cityId, v) if v==nil then return delegate("world","cooper5_level_tax", cityId) else return delegate("world","set_cooper5_level_tax", cityId, v) end end
function M.spinner5_level_tax(cityId, v) if v==nil then return delegate("world","spinner5_level_tax", cityId) else return delegate("world","set_spinner5_level_tax", cityId, v) end end
function M.turner5_level_tax(cityId, v) if v==nil then return delegate("world","turner5_level_tax", cityId) else return delegate("world","set_turner5_level_tax", cityId, v) end end
function M.stonecutter5_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter5_level_tax", cityId) else return delegate("world","set_stonecutter5_level_tax", cityId, v) end end
function M.cobbler5_level_tax(cityId, v) if v==nil then return delegate("world","cobbler5_level_tax", cityId) else return delegate("world","set_cobbler5_level_tax", cityId, v) end end
function M.butcher5_level_tax(cityId, v) if v==nil then return delegate("world","butcher5_level_tax", cityId) else return delegate("world","set_butcher5_level_tax", cityId, v) end end
function M.baker5_level_tax(cityId, v) if v==nil then return delegate("world","baker5_level_tax", cityId) else return delegate("world","set_baker5_level_tax", cityId, v) end end
function M.shepherd5_level_tax(cityId, v) if v==nil then return delegate("world","shepherd5_level_tax", cityId) else return delegate("world","set_shepherd5_level_tax", cityId, v) end end
function M.dairy5_level_tax(cityId, v) if v==nil then return delegate("world","dairy5_level_tax", cityId) else return delegate("world","set_dairy5_level_tax", cityId, v) end end
function M.brewmaster5_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster5_level_tax", cityId) else return delegate("world","set_brewmaster5_level_tax", cityId, v) end end
function M.miller5_level_tax(cityId, v) if v==nil then return delegate("world","miller5_level_tax", cityId) else return delegate("world","set_miller5_level_tax", cityId, v) end end
function M.fishery5_level_tax(cityId, v) if v==nil then return delegate("world","fishery5_level_tax", cityId) else return delegate("world","set_fishery5_level_tax", cityId, v) end end
function M.chandler5_level_tax(cityId, v) if v==nil then return delegate("world","chandler5_level_tax", cityId) else return delegate("world","set_chandler5_level_tax", cityId, v) end end
function M.goldbeater5_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater5_level_tax", cityId) else return delegate("world","set_goldbeater5_level_tax", cityId, v) end end
function M.potter5_level_tax(cityId, v) if v==nil then return delegate("world","potter5_level_tax", cityId) else return delegate("world","set_potter5_level_tax", cityId, v) end end
function M.fowler5_level_tax(cityId, v) if v==nil then return delegate("world","fowler5_level_tax", cityId) else return delegate("world","set_fowler5_level_tax", cityId, v) end end
function M.vintner5_level_tax(cityId, v) if v==nil then return delegate("world","vintner5_level_tax", cityId) else return delegate("world","set_vintner5_level_tax", cityId, v) end end
function M.distiller5_level_tax(cityId, v) if v==nil then return delegate("world","distiller5_level_tax", cityId) else return delegate("world","set_distiller5_level_tax", cityId, v) end end
function M.cook5_level_tax(cityId, v) if v==nil then return delegate("world","cook5_level_tax", cityId) else return delegate("world","set_cook5_level_tax", cityId, v) end end
function M.brickmaker5_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker5_level_tax", cityId) else return delegate("world","set_brickmaker5_level_tax", cityId, v) end end
function M.bathhouse5_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse5_level_tax", cityId) else return delegate("world","set_bathhouse5_level_tax", cityId, v) end end
function M.barracks9_level_tax(cityId, v) if v==nil then return delegate("world","barracks9_level_tax", cityId) else return delegate("world","set_barracks9_level_tax", cityId, v) end end
function M.school5_level_tax(cityId, v) if v==nil then return delegate("world","school5_level_tax", cityId) else return delegate("world","set_school5_level_tax", cityId, v) end end
function M.library5_level_tax(cityId, v) if v==nil then return delegate("world","library5_level_tax", cityId) else return delegate("world","set_library5_level_tax", cityId, v) end end
function M.mine5_level_tax(cityId, v) if v==nil then return delegate("world","mine5_level_tax", cityId) else return delegate("world","set_mine5_level_tax", cityId, v) end end
function M.warehouse5_level_tax(cityId, v) if v==nil then return delegate("world","warehouse5_level_tax", cityId) else return delegate("world","set_warehouse5_level_tax", cityId, v) end end
function M.garrison5_level_tax(cityId, v) if v==nil then return delegate("world","garrison5_level_tax", cityId) else return delegate("world","set_garrison5_level_tax", cityId, v) end end
function M.monastery5_level_tax(cityId, v) if v==nil then return delegate("world","monastery5_level_tax", cityId) else return delegate("world","set_monastery5_level_tax", cityId, v) end end
function M.cathedral5_level_tax(cityId, v) if v==nil then return delegate("world","cathedral5_level_tax", cityId) else return delegate("world","set_cathedral5_level_tax", cityId, v) end end
function M.town_hall5_level_tax(cityId, v) if v==nil then return delegate("world","town_hall5_level_tax", cityId) else return delegate("world","set_town_hall5_level_tax", cityId, v) end end
function M.market5_level_tax(cityId, v) if v==nil then return delegate("world","market5_level_tax", cityId) else return delegate("world","set_market5_level_tax", cityId, v) end end
function M.harbor5_level_tax(cityId, v) if v==nil then return delegate("world","harbor5_level_tax", cityId) else return delegate("world","set_harbor5_level_tax", cityId, v) end end
function M.guardhouse5_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse5_level_tax", cityId) else return delegate("world","set_guardhouse5_level_tax", cityId, v) end end
function M.courthouse5_level_tax(cityId, v) if v==nil then return delegate("world","courthouse5_level_tax", cityId) else return delegate("world","set_courthouse5_level_tax", cityId, v) end end
function M.univ_hall5_level_tax(cityId, v) if v==nil then return delegate("world","univ_hall5_level_tax", cityId) else return delegate("world","set_univ_hall5_level_tax", cityId, v) end end
function M.castle5_level_tax(cityId, v) if v==nil then return delegate("world","castle5_level_tax", cityId) else return delegate("world","set_castle5_level_tax", cityId, v) end end
function M.barracks10_level_tax(cityId, v) if v==nil then return delegate("world","barracks10_level_tax", cityId) else return delegate("world","set_barracks10_level_tax", cityId, v) end end
function M.stables5_level_tax(cityId, v) if v==nil then return delegate("world","stables5_level_tax", cityId) else return delegate("world","set_stables5_level_tax", cityId, v) end end
function M.gates5_level_tax(cityId, v) if v==nil then return delegate("world","gates5_level_tax", cityId) else return delegate("world","set_gates5_level_tax", cityId, v) end end
function M.sentry5_level_tax(cityId, v) if v==nil then return delegate("world","sentry5_level_tax", cityId) else return delegate("world","set_sentry5_level_tax", cityId, v) end end
function M.well5_level_tax(cityId, v) if v==nil then return delegate("world","well5_level_tax", cityId) else return delegate("world","set_well5_level_tax", cityId, v) end end
function M.bridge5_level_tax(cityId, v) if v==nil then return delegate("world","bridge5_level_tax", cityId) else return delegate("world","set_bridge5_level_tax", cityId, v) end end
function M.wall5_level_tax(cityId, v) if v==nil then return delegate("world","wall5_level_tax", cityId) else return delegate("world","set_wall5_level_tax", cityId, v) end end
function M.tower5_level_tax(cityId, v) if v==nil then return delegate("world","tower5_level_tax", cityId) else return delegate("world","set_tower5_level_tax", cityId, v) end end
function M.forum5_level_tax(cityId, v) if v==nil then return delegate("world","forum5_level_tax", cityId) else return delegate("world","set_forum5_level_tax", cityId, v) end end
function M.granary5_level_tax(cityId, v) if v==nil then return delegate("world","granary5_level_tax", cityId) else return delegate("world","set_granary5_level_tax", cityId, v) end end
function M.prison5_level_tax(cityId, v) if v==nil then return delegate("world","prison5_level_tax", cityId) else return delegate("world","set_prison5_level_tax", cityId, v) end end
function M.harbor_dock5_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock5_level_tax", cityId) else return delegate("world","set_harbor_dock5_level_tax", cityId, v) end end
function M.guild_house5_level_tax(cityId, v) if v==nil then return delegate("world","guild_house5_level_tax", cityId) else return delegate("world","set_guild_house5_level_tax", cityId, v) end end
function M.house5_level_tax(cityId, v) if v==nil then return delegate("world","house5_level_tax", cityId) else return delegate("world","set_house5_level_tax", cityId, v) end end
function M.chapel5_level_tax(cityId, v) if v==nil then return delegate("world","chapel5_level_tax", cityId) else return delegate("world","set_chapel5_level_tax", cityId, v) end end
function M.hospital5_level_tax(cityId, v) if v==nil then return delegate("world","hospital5_level_tax", cityId) else return delegate("world","set_hospital5_level_tax", cityId, v) end end
function M.brothel5_level_tax(cityId, v) if v==nil then return delegate("world","brothel5_level_tax", cityId) else return delegate("world","set_brothel5_level_tax", cityId, v) end end
function M.university5_level_tax(cityId, v) if v==nil then return delegate("world","university5_level_tax", cityId) else return delegate("world","set_university5_level_tax", cityId, v) end end
function M.harbor_walls5_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls5_level_tax", cityId) else return delegate("world","set_harbor_walls5_level_tax", cityId, v) end end
function M.schoolhouse5_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse5_level_tax", cityId) else return delegate("world","set_schoolhouse5_level_tax", cityId, v) end end
function M.library_hall5_level_tax(cityId, v) if v==nil then return delegate("world","library_hall5_level_tax", cityId) else return delegate("world","set_library_hall5_level_tax", cityId, v) end end
function M.barber5_level_tax(cityId, v) if v==nil then return delegate("world","barber5_level_tax", cityId) else return delegate("world","set_barber5_level_tax", cityId, v) end end
function M.contor6_level_tax(cityId, v) if v==nil then return delegate("world","contor6_level_tax", cityId) else return delegate("world","set_contor6_level_tax", cityId, v) end end
function M.dice_house6_level_tax(cityId, v) if v==nil then return delegate("world","dice_house6_level_tax", cityId) else return delegate("world","set_dice_house6_level_tax", cityId, v) end end
function M.thieves6_level_tax(cityId, v) if v==nil then return delegate("world","thieves6_level_tax", cityId) else return delegate("world","set_thieves6_level_tax", cityId, v) end end
function M.ropemaker_ws6_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_ws6_level_tax", cityId) else return delegate("world","set_ropemaker_ws6_level_tax", cityId, v) end end
function M.tannery6_level_tax(cityId, v) if v==nil then return delegate("world","tannery6_level_tax", cityId) else return delegate("world","set_tannery6_level_tax", cityId, v) end end
function M.weaving6_level_tax(cityId, v) if v==nil then return delegate("world","weaving6_level_tax", cityId) else return delegate("world","set_weaving6_level_tax", cityId, v) end end
function M.mint6_level_tax(cityId, v) if v==nil then return delegate("world","mint6_level_tax", cityId) else return delegate("world","set_mint6_level_tax", cityId, v) end end
function M.herb_garden6_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden6_level_tax", cityId) else return delegate("world","set_herb_garden6_level_tax", cityId, v) end end
function M.vineyard6_level_tax(cityId, v) if v==nil then return delegate("world","vineyard6_level_tax", cityId) else return delegate("world","set_vineyard6_level_tax", cityId, v) end end
function M.pottery6_level_tax(cityId, v) if v==nil then return delegate("world","pottery6_level_tax", cityId) else return delegate("world","set_pottery6_level_tax", cityId, v) end end
function M.tailor6_level_tax(cityId, v) if v==nil then return delegate("world","tailor6_level_tax", cityId) else return delegate("world","set_tailor6_level_tax", cityId, v) end end
function M.tavern6_level_tax(cityId, v) if v==nil then return delegate("world","tavern6_level_tax", cityId) else return delegate("world","set_tavern6_level_tax", cityId, v) end end
function M.apothecary6_level_tax(cityId, v) if v==nil then return delegate("world","apothecary6_level_tax", cityId) else return delegate("world","set_apothecary6_level_tax", cityId, v) end end
function M.goldsmith6_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith6_level_tax", cityId) else return delegate("world","set_goldsmith6_level_tax", cityId, v) end end
function M.jeweler6_level_tax(cityId, v) if v==nil then return delegate("world","jeweler6_level_tax", cityId) else return delegate("world","set_jeweler6_level_tax", cityId, v) end end
function M.perfumer6_level_tax(cityId, v) if v==nil then return delegate("world","perfumer6_level_tax", cityId) else return delegate("world","set_perfumer6_level_tax", cityId, v) end end
function M.soapmaker6_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker6_level_tax", cityId) else return delegate("world","set_soapmaker6_level_tax", cityId, v) end end
function M.candlemaker6_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker6_level_tax", cityId) else return delegate("world","set_candlemaker6_level_tax", cityId, v) end end
function M.papermill6_level_tax(cityId, v) if v==nil then return delegate("world","papermill6_level_tax", cityId) else return delegate("world","set_papermill6_level_tax", cityId, v) end end
function M.printing6_level_tax(cityId, v) if v==nil then return delegate("world","printing6_level_tax", cityId) else return delegate("world","set_printing6_level_tax", cityId, v) end end
function M.toolmaker6_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker6_level_tax", cityId) else return delegate("world","set_toolmaker6_level_tax", cityId, v) end end
function M.charcoal6_level_tax(cityId, v) if v==nil then return delegate("world","charcoal6_level_tax", cityId) else return delegate("world","set_charcoal6_level_tax", cityId, v) end end
function M.furrier6_level_tax(cityId, v) if v==nil then return delegate("world","furrier6_level_tax", cityId) else return delegate("world","set_furrier6_level_tax", cityId, v) end end
function M.dyer6_level_tax(cityId, v) if v==nil then return delegate("world","dyer6_level_tax", cityId) else return delegate("world","set_dyer6_level_tax", cityId, v) end end
function M.saddler6_level_tax(cityId, v) if v==nil then return delegate("world","saddler6_level_tax", cityId) else return delegate("world","set_saddler6_level_tax", cityId, v) end end
function M.armorer6_level_tax(cityId, v) if v==nil then return delegate("world","armorer6_level_tax", cityId) else return delegate("world","set_armorer6_level_tax", cityId, v) end end
function M.bowyer6_level_tax(cityId, v) if v==nil then return delegate("world","bowyer6_level_tax", cityId) else return delegate("world","set_bowyer6_level_tax", cityId, v) end end
function M.cartwright6_level_tax(cityId, v) if v==nil then return delegate("world","cartwright6_level_tax", cityId) else return delegate("world","set_cartwright6_level_tax", cityId, v) end end
function M.carpenter6_level_tax(cityId, v) if v==nil then return delegate("world","carpenter6_level_tax", cityId) else return delegate("world","set_carpenter6_level_tax", cityId, v) end end
function M.ropemaker6_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker6_level_tax", cityId) else return delegate("world","set_ropemaker6_level_tax", cityId, v) end end
function M.cooper6_level_tax(cityId, v) if v==nil then return delegate("world","cooper6_level_tax", cityId) else return delegate("world","set_cooper6_level_tax", cityId, v) end end
function M.spinner6_level_tax(cityId, v) if v==nil then return delegate("world","spinner6_level_tax", cityId) else return delegate("world","set_spinner6_level_tax", cityId, v) end end
function M.turner6_level_tax(cityId, v) if v==nil then return delegate("world","turner6_level_tax", cityId) else return delegate("world","set_turner6_level_tax", cityId, v) end end
function M.stonecutter6_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter6_level_tax", cityId) else return delegate("world","set_stonecutter6_level_tax", cityId, v) end end
function M.cobbler6_level_tax(cityId, v) if v==nil then return delegate("world","cobbler6_level_tax", cityId) else return delegate("world","set_cobbler6_level_tax", cityId, v) end end
function M.butcher6_level_tax(cityId, v) if v==nil then return delegate("world","butcher6_level_tax", cityId) else return delegate("world","set_butcher6_level_tax", cityId, v) end end
function M.baker6_level_tax(cityId, v) if v==nil then return delegate("world","baker6_level_tax", cityId) else return delegate("world","set_baker6_level_tax", cityId, v) end end
function M.shepherd6_level_tax(cityId, v) if v==nil then return delegate("world","shepherd6_level_tax", cityId) else return delegate("world","set_shepherd6_level_tax", cityId, v) end end
function M.dairy6_level_tax(cityId, v) if v==nil then return delegate("world","dairy6_level_tax", cityId) else return delegate("world","set_dairy6_level_tax", cityId, v) end end
function M.brewmaster6_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster6_level_tax", cityId) else return delegate("world","set_brewmaster6_level_tax", cityId, v) end end
function M.miller6_level_tax(cityId, v) if v==nil then return delegate("world","miller6_level_tax", cityId) else return delegate("world","set_miller6_level_tax", cityId, v) end end
function M.fishery6_level_tax(cityId, v) if v==nil then return delegate("world","fishery6_level_tax", cityId) else return delegate("world","set_fishery6_level_tax", cityId, v) end end
function M.chandler6_level_tax(cityId, v) if v==nil then return delegate("world","chandler6_level_tax", cityId) else return delegate("world","set_chandler6_level_tax", cityId, v) end end
function M.goldbeater6_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater6_level_tax", cityId) else return delegate("world","set_goldbeater6_level_tax", cityId, v) end end
function M.potter6_level_tax(cityId, v) if v==nil then return delegate("world","potter6_level_tax", cityId) else return delegate("world","set_potter6_level_tax", cityId, v) end end
function M.fowler6_level_tax(cityId, v) if v==nil then return delegate("world","fowler6_level_tax", cityId) else return delegate("world","set_fowler6_level_tax", cityId, v) end end
function M.vintner6_level_tax(cityId, v) if v==nil then return delegate("world","vintner6_level_tax", cityId) else return delegate("world","set_vintner6_level_tax", cityId, v) end end
function M.distiller6_level_tax(cityId, v) if v==nil then return delegate("world","distiller6_level_tax", cityId) else return delegate("world","set_distiller6_level_tax", cityId, v) end end
function M.cook6_level_tax(cityId, v) if v==nil then return delegate("world","cook6_level_tax", cityId) else return delegate("world","set_cook6_level_tax", cityId, v) end end
function M.brickmaker6_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker6_level_tax", cityId) else return delegate("world","set_brickmaker6_level_tax", cityId, v) end end
function M.bathhouse6_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse6_level_tax", cityId) else return delegate("world","set_bathhouse6_level_tax", cityId, v) end end
function M.barracks11_level_tax(cityId, v) if v==nil then return delegate("world","barracks11_level_tax", cityId) else return delegate("world","set_barracks11_level_tax", cityId, v) end end
function M.school6_level_tax(cityId, v) if v==nil then return delegate("world","school6_level_tax", cityId) else return delegate("world","set_school6_level_tax", cityId, v) end end
function M.library6_level_tax(cityId, v) if v==nil then return delegate("world","library6_level_tax", cityId) else return delegate("world","set_library6_level_tax", cityId, v) end end
function M.mine6_level_tax(cityId, v) if v==nil then return delegate("world","mine6_level_tax", cityId) else return delegate("world","set_mine6_level_tax", cityId, v) end end
function M.warehouse6_level_tax(cityId, v) if v==nil then return delegate("world","warehouse6_level_tax", cityId) else return delegate("world","set_warehouse6_level_tax", cityId, v) end end
function M.garrison6_level_tax(cityId, v) if v==nil then return delegate("world","garrison6_level_tax", cityId) else return delegate("world","set_garrison6_level_tax", cityId, v) end end
function M.monastery6_level_tax(cityId, v) if v==nil then return delegate("world","monastery6_level_tax", cityId) else return delegate("world","set_monastery6_level_tax", cityId, v) end end
function M.cathedral6_level_tax(cityId, v) if v==nil then return delegate("world","cathedral6_level_tax", cityId) else return delegate("world","set_cathedral6_level_tax", cityId, v) end end
function M.town_hall6_level_tax(cityId, v) if v==nil then return delegate("world","town_hall6_level_tax", cityId) else return delegate("world","set_town_hall6_level_tax", cityId, v) end end
function M.market6_level_tax(cityId, v) if v==nil then return delegate("world","market6_level_tax", cityId) else return delegate("world","set_market6_level_tax", cityId, v) end end
function M.harbor6_level_tax(cityId, v) if v==nil then return delegate("world","harbor6_level_tax", cityId) else return delegate("world","set_harbor6_level_tax", cityId, v) end end
function M.guardhouse6_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse6_level_tax", cityId) else return delegate("world","set_guardhouse6_level_tax", cityId, v) end end
function M.courthouse6_level_tax(cityId, v) if v==nil then return delegate("world","courthouse6_level_tax", cityId) else return delegate("world","set_courthouse6_level_tax", cityId, v) end end
function M.univ_hall6_level_tax(cityId, v) if v==nil then return delegate("world","univ_hall6_level_tax", cityId) else return delegate("world","set_univ_hall6_level_tax", cityId, v) end end
function M.castle6_level_tax(cityId, v) if v==nil then return delegate("world","castle6_level_tax", cityId) else return delegate("world","set_castle6_level_tax", cityId, v) end end
function M.barracks12_level_tax(cityId, v) if v==nil then return delegate("world","barracks12_level_tax", cityId) else return delegate("world","set_barracks12_level_tax", cityId, v) end end
function M.stables6_level_tax(cityId, v) if v==nil then return delegate("world","stables6_level_tax", cityId) else return delegate("world","set_stables6_level_tax", cityId, v) end end
function M.gates6_level_tax(cityId, v) if v==nil then return delegate("world","gates6_level_tax", cityId) else return delegate("world","set_gates6_level_tax", cityId, v) end end
function M.sentry6_level_tax(cityId, v) if v==nil then return delegate("world","sentry6_level_tax", cityId) else return delegate("world","set_sentry6_level_tax", cityId, v) end end
function M.well6_level_tax(cityId, v) if v==nil then return delegate("world","well6_level_tax", cityId) else return delegate("world","set_well6_level_tax", cityId, v) end end
function M.bridge6_level_tax(cityId, v) if v==nil then return delegate("world","bridge6_level_tax", cityId) else return delegate("world","set_bridge6_level_tax", cityId, v) end end
function M.wall6_level_tax(cityId, v) if v==nil then return delegate("world","wall6_level_tax", cityId) else return delegate("world","set_wall6_level_tax", cityId, v) end end
function M.tower6_level_tax(cityId, v) if v==nil then return delegate("world","tower6_level_tax", cityId) else return delegate("world","set_tower6_level_tax", cityId, v) end end
function M.forum6_level_tax(cityId, v) if v==nil then return delegate("world","forum6_level_tax", cityId) else return delegate("world","set_forum6_level_tax", cityId, v) end end
function M.granary6_level_tax(cityId, v) if v==nil then return delegate("world","granary6_level_tax", cityId) else return delegate("world","set_granary6_level_tax", cityId, v) end end
function M.prison6_level_tax(cityId, v) if v==nil then return delegate("world","prison6_level_tax", cityId) else return delegate("world","set_prison6_level_tax", cityId, v) end end
function M.harbor_dock6_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock6_level_tax", cityId) else return delegate("world","set_harbor_dock6_level_tax", cityId, v) end end
function M.guild_house6_level_tax(cityId, v) if v==nil then return delegate("world","guild_house6_level_tax", cityId) else return delegate("world","set_guild_house6_level_tax", cityId, v) end end
function M.house6_level_tax(cityId, v) if v==nil then return delegate("world","house6_level_tax", cityId) else return delegate("world","set_house6_level_tax", cityId, v) end end
function M.chapel6_level_tax(cityId, v) if v==nil then return delegate("world","chapel6_level_tax", cityId) else return delegate("world","set_chapel6_level_tax", cityId, v) end end
function M.hospital6_level_tax(cityId, v) if v==nil then return delegate("world","hospital6_level_tax", cityId) else return delegate("world","set_hospital6_level_tax", cityId, v) end end
function M.brothel6_level_tax(cityId, v) if v==nil then return delegate("world","brothel6_level_tax", cityId) else return delegate("world","set_brothel6_level_tax", cityId, v) end end
function M.university6_level_tax(cityId, v) if v==nil then return delegate("world","university6_level_tax", cityId) else return delegate("world","set_university6_level_tax", cityId, v) end end
function M.harbor_walls6_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls6_level_tax", cityId) else return delegate("world","set_harbor_walls6_level_tax", cityId, v) end end
function M.schoolhouse6_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse6_level_tax", cityId) else return delegate("world","set_schoolhouse6_level_tax", cityId, v) end end
function M.library_hall6_level_tax(cityId, v) if v==nil then return delegate("world","library_hall6_level_tax", cityId) else return delegate("world","set_library_hall6_level_tax", cityId, v) end end
function M.barber6_level_tax(cityId, v) if v==nil then return delegate("world","barber6_level_tax", cityId) else return delegate("world","set_barber6_level_tax", cityId, v) end end
function M.contor7_level_tax(cityId, v) if v==nil then return delegate("world","contor7_level_tax", cityId) else return delegate("world","set_contor7_level_tax", cityId, v) end end
function M.dice_house7_level_tax(cityId, v) if v==nil then return delegate("world","dice_house7_level_tax", cityId) else return delegate("world","set_dice_house7_level_tax", cityId, v) end end
function M.thieves7_level_tax(cityId, v) if v==nil then return delegate("world","thieves7_level_tax", cityId) else return delegate("world","set_thieves7_level_tax", cityId, v) end end
function M.ropemaker_ws7_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_ws7_level_tax", cityId) else return delegate("world","set_ropemaker_ws7_level_tax", cityId, v) end end
function M.tannery7_level_tax(cityId, v) if v==nil then return delegate("world","tannery7_level_tax", cityId) else return delegate("world","set_tannery7_level_tax", cityId, v) end end
function M.weaving7_level_tax(cityId, v) if v==nil then return delegate("world","weaving7_level_tax", cityId) else return delegate("world","set_weaving7_level_tax", cityId, v) end end
function M.mint7_level_tax(cityId, v) if v==nil then return delegate("world","mint7_level_tax", cityId) else return delegate("world","set_mint7_level_tax", cityId, v) end end
function M.herb_garden7_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden7_level_tax", cityId) else return delegate("world","set_herb_garden7_level_tax", cityId, v) end end
function M.vineyard7_level_tax(cityId, v) if v==nil then return delegate("world","vineyard7_level_tax", cityId) else return delegate("world","set_vineyard7_level_tax", cityId, v) end end
function M.pottery7_level_tax(cityId, v) if v==nil then return delegate("world","pottery7_level_tax", cityId) else return delegate("world","set_pottery7_level_tax", cityId, v) end end
function M.tailor7_level_tax(cityId, v) if v==nil then return delegate("world","tailor7_level_tax", cityId) else return delegate("world","set_tailor7_level_tax", cityId, v) end end
function M.tavern7_level_tax(cityId, v) if v==nil then return delegate("world","tavern7_level_tax", cityId) else return delegate("world","set_tavern7_level_tax", cityId, v) end end
function M.apothecary7_level_tax(cityId, v) if v==nil then return delegate("world","apothecary7_level_tax", cityId) else return delegate("world","set_apothecary7_level_tax", cityId, v) end end
function M.goldsmith7_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith7_level_tax", cityId) else return delegate("world","set_goldsmith7_level_tax", cityId, v) end end
function M.jeweler7_level_tax(cityId, v) if v==nil then return delegate("world","jeweler7_level_tax", cityId) else return delegate("world","set_jeweler7_level_tax", cityId, v) end end
function M.perfumer7_level_tax(cityId, v) if v==nil then return delegate("world","perfumer7_level_tax", cityId) else return delegate("world","set_perfumer7_level_tax", cityId, v) end end
function M.soapmaker7_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker7_level_tax", cityId) else return delegate("world","set_soapmaker7_level_tax", cityId, v) end end
function M.candlemaker7_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker7_level_tax", cityId) else return delegate("world","set_candlemaker7_level_tax", cityId, v) end end
function M.papermill7_level_tax(cityId, v) if v==nil then return delegate("world","papermill7_level_tax", cityId) else return delegate("world","set_papermill7_level_tax", cityId, v) end end
function M.printing7_level_tax(cityId, v) if v==nil then return delegate("world","printing7_level_tax", cityId) else return delegate("world","set_printing7_level_tax", cityId, v) end end
function M.toolmaker7_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker7_level_tax", cityId) else return delegate("world","set_toolmaker7_level_tax", cityId, v) end end
function M.charcoal7_level_tax(cityId, v) if v==nil then return delegate("world","charcoal7_level_tax", cityId) else return delegate("world","set_charcoal7_level_tax", cityId, v) end end
function M.furrier7_level_tax(cityId, v) if v==nil then return delegate("world","furrier7_level_tax", cityId) else return delegate("world","set_furrier7_level_tax", cityId, v) end end
function M.dyer7_level_tax(cityId, v) if v==nil then return delegate("world","dyer7_level_tax", cityId) else return delegate("world","set_dyer7_level_tax", cityId, v) end end
function M.saddler7_level_tax(cityId, v) if v==nil then return delegate("world","saddler7_level_tax", cityId) else return delegate("world","set_saddler7_level_tax", cityId, v) end end
function M.armorer7_level_tax(cityId, v) if v==nil then return delegate("world","armorer7_level_tax", cityId) else return delegate("world","set_armorer7_level_tax", cityId, v) end end
function M.bowyer7_level_tax(cityId, v) if v==nil then return delegate("world","bowyer7_level_tax", cityId) else return delegate("world","set_bowyer7_level_tax", cityId, v) end end
function M.cartwright7_level_tax(cityId, v) if v==nil then return delegate("world","cartwright7_level_tax", cityId) else return delegate("world","set_cartwright7_level_tax", cityId, v) end end
function M.carpenter7_level_tax(cityId, v) if v==nil then return delegate("world","carpenter7_level_tax", cityId) else return delegate("world","set_carpenter7_level_tax", cityId, v) end end
function M.ropemaker7_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker7_level_tax", cityId) else return delegate("world","set_ropemaker7_level_tax", cityId, v) end end
function M.cooper7_level_tax(cityId, v) if v==nil then return delegate("world","cooper7_level_tax", cityId) else return delegate("world","set_cooper7_level_tax", cityId, v) end end
function M.spinner7_level_tax(cityId, v) if v==nil then return delegate("world","spinner7_level_tax", cityId) else return delegate("world","set_spinner7_level_tax", cityId, v) end end
function M.turner7_level_tax(cityId, v) if v==nil then return delegate("world","turner7_level_tax", cityId) else return delegate("world","set_turner7_level_tax", cityId, v) end end
function M.stonecutter7_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter7_level_tax", cityId) else return delegate("world","set_stonecutter7_level_tax", cityId, v) end end
function M.cobbler7_level_tax(cityId, v) if v==nil then return delegate("world","cobbler7_level_tax", cityId) else return delegate("world","set_cobbler7_level_tax", cityId, v) end end
function M.butcher7_level_tax(cityId, v) if v==nil then return delegate("world","butcher7_level_tax", cityId) else return delegate("world","set_butcher7_level_tax", cityId, v) end end
function M.baker7_level_tax(cityId, v) if v==nil then return delegate("world","baker7_level_tax", cityId) else return delegate("world","set_baker7_level_tax", cityId, v) end end
function M.shepherd7_level_tax(cityId, v) if v==nil then return delegate("world","shepherd7_level_tax", cityId) else return delegate("world","set_shepherd7_level_tax", cityId, v) end end
function M.dairy7_level_tax(cityId, v) if v==nil then return delegate("world","dairy7_level_tax", cityId) else return delegate("world","set_dairy7_level_tax", cityId, v) end end
function M.brewmaster7_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster7_level_tax", cityId) else return delegate("world","set_brewmaster7_level_tax", cityId, v) end end
function M.miller7_level_tax(cityId, v) if v==nil then return delegate("world","miller7_level_tax", cityId) else return delegate("world","set_miller7_level_tax", cityId, v) end end
function M.fishery7_level_tax(cityId, v) if v==nil then return delegate("world","fishery7_level_tax", cityId) else return delegate("world","set_fishery7_level_tax", cityId, v) end end
function M.chandler7_level_tax(cityId, v) if v==nil then return delegate("world","chandler7_level_tax", cityId) else return delegate("world","set_chandler7_level_tax", cityId, v) end end
function M.goldbeater7_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater7_level_tax", cityId) else return delegate("world","set_goldbeater7_level_tax", cityId, v) end end
function M.potter7_level_tax(cityId, v) if v==nil then return delegate("world","potter7_level_tax", cityId) else return delegate("world","set_potter7_level_tax", cityId, v) end end
function M.fowler7_level_tax(cityId, v) if v==nil then return delegate("world","fowler7_level_tax", cityId) else return delegate("world","set_fowler7_level_tax", cityId, v) end end
function M.vintner7_level_tax(cityId, v) if v==nil then return delegate("world","vintner7_level_tax", cityId) else return delegate("world","set_vintner7_level_tax", cityId, v) end end
function M.distiller7_level_tax(cityId, v) if v==nil then return delegate("world","distiller7_level_tax", cityId) else return delegate("world","set_distiller7_level_tax", cityId, v) end end
function M.cook7_level_tax(cityId, v) if v==nil then return delegate("world","cook7_level_tax", cityId) else return delegate("world","set_cook7_level_tax", cityId, v) end end
function M.brickmaker7_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker7_level_tax", cityId) else return delegate("world","set_brickmaker7_level_tax", cityId, v) end end
function M.bathhouse7_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse7_level_tax", cityId) else return delegate("world","set_bathhouse7_level_tax", cityId, v) end end
function M.barracks13_level_tax(cityId, v) if v==nil then return delegate("world","barracks13_level_tax", cityId) else return delegate("world","set_barracks13_level_tax", cityId, v) end end
function M.school7_level_tax(cityId, v) if v==nil then return delegate("world","school7_level_tax", cityId) else return delegate("world","set_school7_level_tax", cityId, v) end end
function M.library7_level_tax(cityId, v) if v==nil then return delegate("world","library7_level_tax", cityId) else return delegate("world","set_library7_level_tax", cityId, v) end end
function M.mine7_level_tax(cityId, v) if v==nil then return delegate("world","mine7_level_tax", cityId) else return delegate("world","set_mine7_level_tax", cityId, v) end end
function M.warehouse7_level_tax(cityId, v) if v==nil then return delegate("world","warehouse7_level_tax", cityId) else return delegate("world","set_warehouse7_level_tax", cityId, v) end end
function M.garrison7_level_tax(cityId, v) if v==nil then return delegate("world","garrison7_level_tax", cityId) else return delegate("world","set_garrison7_level_tax", cityId, v) end end
function M.monastery7_level_tax(cityId, v) if v==nil then return delegate("world","monastery7_level_tax", cityId) else return delegate("world","set_monastery7_level_tax", cityId, v) end end
function M.cathedral7_level_tax(cityId, v) if v==nil then return delegate("world","cathedral7_level_tax", cityId) else return delegate("world","set_cathedral7_level_tax", cityId, v) end end
function M.town_hall7_level_tax(cityId, v) if v==nil then return delegate("world","town_hall7_level_tax", cityId) else return delegate("world","set_town_hall7_level_tax", cityId, v) end end
function M.market7_level_tax(cityId, v) if v==nil then return delegate("world","market7_level_tax", cityId) else return delegate("world","set_market7_level_tax", cityId, v) end end
function M.harbor7_level_tax(cityId, v) if v==nil then return delegate("world","harbor7_level_tax", cityId) else return delegate("world","set_harbor7_level_tax", cityId, v) end end
function M.guardhouse7_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse7_level_tax", cityId) else return delegate("world","set_guardhouse7_level_tax", cityId, v) end end
function M.courthouse7_level_tax(cityId, v) if v==nil then return delegate("world","courthouse7_level_tax", cityId) else return delegate("world","set_courthouse7_level_tax", cityId, v) end end
function M.univ_hall7_level_tax(cityId, v) if v==nil then return delegate("world","univ_hall7_level_tax", cityId) else return delegate("world","set_univ_hall7_level_tax", cityId, v) end end
function M.castle7_level_tax(cityId, v) if v==nil then return delegate("world","castle7_level_tax", cityId) else return delegate("world","set_castle7_level_tax", cityId, v) end end
function M.barracks14_level_tax(cityId, v) if v==nil then return delegate("world","barracks14_level_tax", cityId) else return delegate("world","set_barracks14_level_tax", cityId, v) end end
function M.stables7_level_tax(cityId, v) if v==nil then return delegate("world","stables7_level_tax", cityId) else return delegate("world","set_stables7_level_tax", cityId, v) end end
function M.gates7_level_tax(cityId, v) if v==nil then return delegate("world","gates7_level_tax", cityId) else return delegate("world","set_gates7_level_tax", cityId, v) end end
function M.sentry7_level_tax(cityId, v) if v==nil then return delegate("world","sentry7_level_tax", cityId) else return delegate("world","set_sentry7_level_tax", cityId, v) end end
function M.well7_level_tax(cityId, v) if v==nil then return delegate("world","well7_level_tax", cityId) else return delegate("world","set_well7_level_tax", cityId, v) end end
function M.bridge7_level_tax(cityId, v) if v==nil then return delegate("world","bridge7_level_tax", cityId) else return delegate("world","set_bridge7_level_tax", cityId, v) end end
function M.wall7_level_tax(cityId, v) if v==nil then return delegate("world","wall7_level_tax", cityId) else return delegate("world","set_wall7_level_tax", cityId, v) end end
function M.tower7_level_tax(cityId, v) if v==nil then return delegate("world","tower7_level_tax", cityId) else return delegate("world","set_tower7_level_tax", cityId, v) end end
function M.forum7_level_tax(cityId, v) if v==nil then return delegate("world","forum7_level_tax", cityId) else return delegate("world","set_forum7_level_tax", cityId, v) end end
function M.granary7_level_tax(cityId, v) if v==nil then return delegate("world","granary7_level_tax", cityId) else return delegate("world","set_granary7_level_tax", cityId, v) end end
function M.prison7_level_tax(cityId, v) if v==nil then return delegate("world","prison7_level_tax", cityId) else return delegate("world","set_prison7_level_tax", cityId, v) end end
function M.harbor_dock7_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock7_level_tax", cityId) else return delegate("world","set_harbor_dock7_level_tax", cityId, v) end end
function M.guild_house7_level_tax(cityId, v) if v==nil then return delegate("world","guild_house7_level_tax", cityId) else return delegate("world","set_guild_house7_level_tax", cityId, v) end end
function M.house7_level_tax(cityId, v) if v==nil then return delegate("world","house7_level_tax", cityId) else return delegate("world","set_house7_level_tax", cityId, v) end end
function M.chapel7_level_tax(cityId, v) if v==nil then return delegate("world","chapel7_level_tax", cityId) else return delegate("world","set_chapel7_level_tax", cityId, v) end end
function M.hospital7_level_tax(cityId, v) if v==nil then return delegate("world","hospital7_level_tax", cityId) else return delegate("world","set_hospital7_level_tax", cityId, v) end end
function M.brothel7_level_tax(cityId, v) if v==nil then return delegate("world","brothel7_level_tax", cityId) else return delegate("world","set_brothel7_level_tax", cityId, v) end end
function M.university7_level_tax(cityId, v) if v==nil then return delegate("world","university7_level_tax", cityId) else return delegate("world","set_university7_level_tax", cityId, v) end end
function M.harbor_walls7_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls7_level_tax", cityId) else return delegate("world","set_harbor_walls7_level_tax", cityId, v) end end
function M.schoolhouse7_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse7_level_tax", cityId) else return delegate("world","set_schoolhouse7_level_tax", cityId, v) end end
function M.library_hall7_level_tax(cityId, v) if v==nil then return delegate("world","library_hall7_level_tax", cityId) else return delegate("world","set_library_hall7_level_tax", cityId, v) end end
function M.barber7_level_tax(cityId, v) if v==nil then return delegate("world","barber7_level_tax", cityId) else return delegate("world","set_barber7_level_tax", cityId, v) end end
function M.contor8_level_tax(cityId, v) if v==nil then return delegate("world","contor8_level_tax", cityId) else return delegate("world","set_contor8_level_tax", cityId, v) end end
function M.dice_house8_level_tax(cityId, v) if v==nil then return delegate("world","dice_house8_level_tax", cityId) else return delegate("world","set_dice_house8_level_tax", cityId, v) end end
function M.thieves8_level_tax(cityId, v) if v==nil then return delegate("world","thieves8_level_tax", cityId) else return delegate("world","set_thieves8_level_tax", cityId, v) end end
function M.ropemaker_ws8_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_ws8_level_tax", cityId) else return delegate("world","set_ropemaker_ws8_level_tax", cityId, v) end end
function M.tannery8_level_tax(cityId, v) if v==nil then return delegate("world","tannery8_level_tax", cityId) else return delegate("world","set_tannery8_level_tax", cityId, v) end end
function M.weaving8_level_tax(cityId, v) if v==nil then return delegate("world","weaving8_level_tax", cityId) else return delegate("world","set_weaving8_level_tax", cityId, v) end end
function M.mint8_level_tax(cityId, v) if v==nil then return delegate("world","mint8_level_tax", cityId) else return delegate("world","set_mint8_level_tax", cityId, v) end end
function M.herb_garden8_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden8_level_tax", cityId) else return delegate("world","set_herb_garden8_level_tax", cityId, v) end end
function M.vineyard8_level_tax(cityId, v) if v==nil then return delegate("world","vineyard8_level_tax", cityId) else return delegate("world","set_vineyard8_level_tax", cityId, v) end end
function M.pottery8_level_tax(cityId, v) if v==nil then return delegate("world","pottery8_level_tax", cityId) else return delegate("world","set_pottery8_level_tax", cityId, v) end end
function M.tailor8_level_tax(cityId, v) if v==nil then return delegate("world","tailor8_level_tax", cityId) else return delegate("world","set_tailor8_level_tax", cityId, v) end end
function M.tavern8_level_tax(cityId, v) if v==nil then return delegate("world","tavern8_level_tax", cityId) else return delegate("world","set_tavern8_level_tax", cityId, v) end end
function M.apothecary8_level_tax(cityId, v) if v==nil then return delegate("world","apothecary8_level_tax", cityId) else return delegate("world","set_apothecary8_level_tax", cityId, v) end end
function M.goldsmith8_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith8_level_tax", cityId) else return delegate("world","set_goldsmith8_level_tax", cityId, v) end end
function M.jeweler8_level_tax(cityId, v) if v==nil then return delegate("world","jeweler8_level_tax", cityId) else return delegate("world","set_jeweler8_level_tax", cityId, v) end end
function M.perfumer8_level_tax(cityId, v) if v==nil then return delegate("world","perfumer8_level_tax", cityId) else return delegate("world","set_perfumer8_level_tax", cityId, v) end end
function M.soapmaker8_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker8_level_tax", cityId) else return delegate("world","set_soapmaker8_level_tax", cityId, v) end end
function M.candlemaker8_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker8_level_tax", cityId) else return delegate("world","set_candlemaker8_level_tax", cityId, v) end end
function M.papermill8_level_tax(cityId, v) if v==nil then return delegate("world","papermill8_level_tax", cityId) else return delegate("world","set_papermill8_level_tax", cityId, v) end end
function M.printing8_level_tax(cityId, v) if v==nil then return delegate("world","printing8_level_tax", cityId) else return delegate("world","set_printing8_level_tax", cityId, v) end end
function M.toolmaker8_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker8_level_tax", cityId) else return delegate("world","set_toolmaker8_level_tax", cityId, v) end end
function M.charcoal8_level_tax(cityId, v) if v==nil then return delegate("world","charcoal8_level_tax", cityId) else return delegate("world","set_charcoal8_level_tax", cityId, v) end end
function M.furrier8_level_tax(cityId, v) if v==nil then return delegate("world","furrier8_level_tax", cityId) else return delegate("world","set_furrier8_level_tax", cityId, v) end end
function M.dyer8_level_tax(cityId, v) if v==nil then return delegate("world","dyer8_level_tax", cityId) else return delegate("world","set_dyer8_level_tax", cityId, v) end end
function M.saddler8_level_tax(cityId, v) if v==nil then return delegate("world","saddler8_level_tax", cityId) else return delegate("world","set_saddler8_level_tax", cityId, v) end end
function M.armorer8_level_tax(cityId, v) if v==nil then return delegate("world","armorer8_level_tax", cityId) else return delegate("world","set_armorer8_level_tax", cityId, v) end end
function M.bowyer8_level_tax(cityId, v) if v==nil then return delegate("world","bowyer8_level_tax", cityId) else return delegate("world","set_bowyer8_level_tax", cityId, v) end end
function M.cartwright8_level_tax(cityId, v) if v==nil then return delegate("world","cartwright8_level_tax", cityId) else return delegate("world","set_cartwright8_level_tax", cityId, v) end end
function M.carpenter8_level_tax(cityId, v) if v==nil then return delegate("world","carpenter8_level_tax", cityId) else return delegate("world","set_carpenter8_level_tax", cityId, v) end end
function M.ropemaker8_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker8_level_tax", cityId) else return delegate("world","set_ropemaker8_level_tax", cityId, v) end end
function M.cooper8_level_tax(cityId, v) if v==nil then return delegate("world","cooper8_level_tax", cityId) else return delegate("world","set_cooper8_level_tax", cityId, v) end end
function M.spinner8_level_tax(cityId, v) if v==nil then return delegate("world","spinner8_level_tax", cityId) else return delegate("world","set_spinner8_level_tax", cityId, v) end end
function M.turner8_level_tax(cityId, v) if v==nil then return delegate("world","turner8_level_tax", cityId) else return delegate("world","set_turner8_level_tax", cityId, v) end end
function M.stonecutter8_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter8_level_tax", cityId) else return delegate("world","set_stonecutter8_level_tax", cityId, v) end end
function M.cobbler8_level_tax(cityId, v) if v==nil then return delegate("world","cobbler8_level_tax", cityId) else return delegate("world","set_cobbler8_level_tax", cityId, v) end end
function M.butcher8_level_tax(cityId, v) if v==nil then return delegate("world","butcher8_level_tax", cityId) else return delegate("world","set_butcher8_level_tax", cityId, v) end end
function M.baker8_level_tax(cityId, v) if v==nil then return delegate("world","baker8_level_tax", cityId) else return delegate("world","set_baker8_level_tax", cityId, v) end end
function M.shepherd8_level_tax(cityId, v) if v==nil then return delegate("world","shepherd8_level_tax", cityId) else return delegate("world","set_shepherd8_level_tax", cityId, v) end end
function M.dairy8_level_tax(cityId, v) if v==nil then return delegate("world","dairy8_level_tax", cityId) else return delegate("world","set_dairy8_level_tax", cityId, v) end end
function M.brewmaster8_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster8_level_tax", cityId) else return delegate("world","set_brewmaster8_level_tax", cityId, v) end end
function M.miller8_level_tax(cityId, v) if v==nil then return delegate("world","miller8_level_tax", cityId) else return delegate("world","set_miller8_level_tax", cityId, v) end end
function M.fishery8_level_tax(cityId, v) if v==nil then return delegate("world","fishery8_level_tax", cityId) else return delegate("world","set_fishery8_level_tax", cityId, v) end end
function M.chandler8_level_tax(cityId, v) if v==nil then return delegate("world","chandler8_level_tax", cityId) else return delegate("world","set_chandler8_level_tax", cityId, v) end end
function M.goldbeater8_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater8_level_tax", cityId) else return delegate("world","set_goldbeater8_level_tax", cityId, v) end end
function M.potter8_level_tax(cityId, v) if v==nil then return delegate("world","potter8_level_tax", cityId) else return delegate("world","set_potter8_level_tax", cityId, v) end end
function M.fowler8_level_tax(cityId, v) if v==nil then return delegate("world","fowler8_level_tax", cityId) else return delegate("world","set_fowler8_level_tax", cityId, v) end end
function M.vintner8_level_tax(cityId, v) if v==nil then return delegate("world","vintner8_level_tax", cityId) else return delegate("world","set_vintner8_level_tax", cityId, v) end end
function M.distiller8_level_tax(cityId, v) if v==nil then return delegate("world","distiller8_level_tax", cityId) else return delegate("world","set_distiller8_level_tax", cityId, v) end end
function M.cook8_level_tax(cityId, v) if v==nil then return delegate("world","cook8_level_tax", cityId) else return delegate("world","set_cook8_level_tax", cityId, v) end end
function M.brickmaker8_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker8_level_tax", cityId) else return delegate("world","set_brickmaker8_level_tax", cityId, v) end end
function M.bathhouse8_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse8_level_tax", cityId) else return delegate("world","set_bathhouse8_level_tax", cityId, v) end end
function M.barracks15_level_tax(cityId, v) if v==nil then return delegate("world","barracks15_level_tax", cityId) else return delegate("world","set_barracks15_level_tax", cityId, v) end end
function M.school8_level_tax(cityId, v) if v==nil then return delegate("world","school8_level_tax", cityId) else return delegate("world","set_school8_level_tax", cityId, v) end end
function M.library8_level_tax(cityId, v) if v==nil then return delegate("world","library8_level_tax", cityId) else return delegate("world","set_library8_level_tax", cityId, v) end end
function M.mine8_level_tax(cityId, v) if v==nil then return delegate("world","mine8_level_tax", cityId) else return delegate("world","set_mine8_level_tax", cityId, v) end end
function M.warehouse8_level_tax(cityId, v) if v==nil then return delegate("world","warehouse8_level_tax", cityId) else return delegate("world","set_warehouse8_level_tax", cityId, v) end end
function M.garrison8_level_tax(cityId, v) if v==nil then return delegate("world","garrison8_level_tax", cityId) else return delegate("world","set_garrison8_level_tax", cityId, v) end end
function M.monastery8_level_tax(cityId, v) if v==nil then return delegate("world","monastery8_level_tax", cityId) else return delegate("world","set_monastery8_level_tax", cityId, v) end end
function M.cathedral8_level_tax(cityId, v) if v==nil then return delegate("world","cathedral8_level_tax", cityId) else return delegate("world","set_cathedral8_level_tax", cityId, v) end end
function M.town_hall8_level_tax(cityId, v) if v==nil then return delegate("world","town_hall8_level_tax", cityId) else return delegate("world","set_town_hall8_level_tax", cityId, v) end end
function M.market8_level_tax(cityId, v) if v==nil then return delegate("world","market8_level_tax", cityId) else return delegate("world","set_market8_level_tax", cityId, v) end end
function M.harbor8_level_tax(cityId, v) if v==nil then return delegate("world","harbor8_level_tax", cityId) else return delegate("world","set_harbor8_level_tax", cityId, v) end end
function M.guardhouse8_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse8_level_tax", cityId) else return delegate("world","set_guardhouse8_level_tax", cityId, v) end end
function M.courthouse8_level_tax(cityId, v) if v==nil then return delegate("world","courthouse8_level_tax", cityId) else return delegate("world","set_courthouse8_level_tax", cityId, v) end end
function M.univ_hall8_level_tax(cityId, v) if v==nil then return delegate("world","univ_hall8_level_tax", cityId) else return delegate("world","set_univ_hall8_level_tax", cityId, v) end end
function M.castle8_level_tax(cityId, v) if v==nil then return delegate("world","castle8_level_tax", cityId) else return delegate("world","set_castle8_level_tax", cityId, v) end end
function M.well8_level_tax(cityId, v) if v==nil then return delegate("world","well8_level_tax", cityId) else return delegate("world","set_well8_level_tax", cityId, v) end end
function M.bridge8_level_tax(cityId, v) if v==nil then return delegate("world","bridge8_level_tax", cityId) else return delegate("world","set_bridge8_level_tax", cityId, v) end end
function M.wall8_level_tax(cityId, v) if v==nil then return delegate("world","wall8_level_tax", cityId) else return delegate("world","set_wall8_level_tax", cityId, v) end end
function M.tower8_level_tax(cityId, v) if v==nil then return delegate("world","tower8_level_tax", cityId) else return delegate("world","set_tower8_level_tax", cityId, v) end end
function M.forum8_level_tax(cityId, v) if v==nil then return delegate("world","forum8_level_tax", cityId) else return delegate("world","set_forum8_level_tax", cityId, v) end end
function M.granary8_level_tax(cityId, v) if v==nil then return delegate("world","granary8_level_tax", cityId) else return delegate("world","set_granary8_level_tax", cityId, v) end end
function M.prison8_level_tax(cityId, v) if v==nil then return delegate("world","prison8_level_tax", cityId) else return delegate("world","set_prison8_level_tax", cityId, v) end end
function M.harbor_dock8_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock8_level_tax", cityId) else return delegate("world","set_harbor_dock8_level_tax", cityId, v) end end
function M.guild_house8_level_tax(cityId, v) if v==nil then return delegate("world","guild_house8_level_tax", cityId) else return delegate("world","set_guild_house8_level_tax", cityId, v) end end
function M.house8_level_tax(cityId, v) if v==nil then return delegate("world","house8_level_tax", cityId) else return delegate("world","set_house8_level_tax", cityId, v) end end
function M.chapel8_level_tax(cityId, v) if v==nil then return delegate("world","chapel8_level_tax", cityId) else return delegate("world","set_chapel8_level_tax", cityId, v) end end
function M.hospital8_level_tax(cityId, v) if v==nil then return delegate("world","hospital8_level_tax", cityId) else return delegate("world","set_hospital8_level_tax", cityId, v) end end
function M.brothel8_level_tax(cityId, v) if v==nil then return delegate("world","brothel8_level_tax", cityId) else return delegate("world","set_brothel8_level_tax", cityId, v) end end
function M.university8_level_tax(cityId, v) if v==nil then return delegate("world","university8_level_tax", cityId) else return delegate("world","set_university8_level_tax", cityId, v) end end
function M.harbor_walls8_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls8_level_tax", cityId) else return delegate("world","set_harbor_walls8_level_tax", cityId, v) end end
function M.schoolhouse8_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse8_level_tax", cityId) else return delegate("world","set_schoolhouse8_level_tax", cityId, v) end end
function M.library_hall8_level_tax(cityId, v) if v==nil then return delegate("world","library_hall8_level_tax", cityId) else return delegate("world","set_library_hall8_level_tax", cityId, v) end end
function M.barber8_level_tax(cityId, v) if v==nil then return delegate("world","barber8_level_tax", cityId) else return delegate("world","set_barber8_level_tax", cityId, v) end end
function M.contor9_level_tax(cityId, v) if v==nil then return delegate("world","contor9_level_tax", cityId) else return delegate("world","set_contor9_level_tax", cityId, v) end end
function M.dice_house9_level_tax(cityId, v) if v==nil then return delegate("world","dice_house9_level_tax", cityId) else return delegate("world","set_dice_house9_level_tax", cityId, v) end end
function M.thieves9_level_tax(cityId, v) if v==nil then return delegate("world","thieves9_level_tax", cityId) else return delegate("world","set_thieves9_level_tax", cityId, v) end end
function M.ropemaker_ws9_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_ws9_level_tax", cityId) else return delegate("world","set_ropemaker_ws9_level_tax", cityId, v) end end
function M.tannery9_level_tax(cityId, v) if v==nil then return delegate("world","tannery9_level_tax", cityId) else return delegate("world","set_tannery9_level_tax", cityId, v) end end
function M.weaving9_level_tax(cityId, v) if v==nil then return delegate("world","weaving9_level_tax", cityId) else return delegate("world","set_weaving9_level_tax", cityId, v) end end
function M.mint9_level_tax(cityId, v) if v==nil then return delegate("world","mint9_level_tax", cityId) else return delegate("world","set_mint9_level_tax", cityId, v) end end
function M.herb_garden9_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden9_level_tax", cityId) else return delegate("world","set_herb_garden9_level_tax", cityId, v) end end
function M.vineyard9_level_tax(cityId, v) if v==nil then return delegate("world","vineyard9_level_tax", cityId) else return delegate("world","set_vineyard9_level_tax", cityId, v) end end
function M.pottery9_level_tax(cityId, v) if v==nil then return delegate("world","pottery9_level_tax", cityId) else return delegate("world","set_pottery9_level_tax", cityId, v) end end
function M.tailor9_level_tax(cityId, v) if v==nil then return delegate("world","tailor9_level_tax", cityId) else return delegate("world","set_tailor9_level_tax", cityId, v) end end
function M.tavern9_level_tax(cityId, v) if v==nil then return delegate("world","tavern9_level_tax", cityId) else return delegate("world","set_tavern9_level_tax", cityId, v) end end
function M.apothecary9_level_tax(cityId, v) if v==nil then return delegate("world","apothecary9_level_tax", cityId) else return delegate("world","set_apothecary9_level_tax", cityId, v) end end
function M.goldsmith9_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith9_level_tax", cityId) else return delegate("world","set_goldsmith9_level_tax", cityId, v) end end
function M.jeweler9_level_tax(cityId, v) if v==nil then return delegate("world","jeweler9_level_tax", cityId) else return delegate("world","set_jeweler9_level_tax", cityId, v) end end
function M.perfumer9_level_tax(cityId, v) if v==nil then return delegate("world","perfumer9_level_tax", cityId) else return delegate("world","set_perfumer9_level_tax", cityId, v) end end
function M.soapmaker9_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker9_level_tax", cityId) else return delegate("world","set_soapmaker9_level_tax", cityId, v) end end
function M.candlemaker9_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker9_level_tax", cityId) else return delegate("world","set_candlemaker9_level_tax", cityId, v) end end
function M.papermill9_level_tax(cityId, v) if v==nil then return delegate("world","papermill9_level_tax", cityId) else return delegate("world","set_papermill9_level_tax", cityId, v) end end
function M.printing9_level_tax(cityId, v) if v==nil then return delegate("world","printing9_level_tax", cityId) else return delegate("world","set_printing9_level_tax", cityId, v) end end
function M.toolmaker9_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker9_level_tax", cityId) else return delegate("world","set_toolmaker9_level_tax", cityId, v) end end
function M.charcoal9_level_tax(cityId, v) if v==nil then return delegate("world","charcoal9_level_tax", cityId) else return delegate("world","set_charcoal9_level_tax", cityId, v) end end
function M.furrier9_level_tax(cityId, v) if v==nil then return delegate("world","furrier9_level_tax", cityId) else return delegate("world","set_furrier9_level_tax", cityId, v) end end
function M.dyer9_level_tax(cityId, v) if v==nil then return delegate("world","dyer9_level_tax", cityId) else return delegate("world","set_dyer9_level_tax", cityId, v) end end
function M.saddler9_level_tax(cityId, v) if v==nil then return delegate("world","saddler9_level_tax", cityId) else return delegate("world","set_saddler9_level_tax", cityId, v) end end
function M.armorer9_level_tax(cityId, v) if v==nil then return delegate("world","armorer9_level_tax", cityId) else return delegate("world","set_armorer9_level_tax", cityId, v) end end
function M.bowyer9_level_tax(cityId, v) if v==nil then return delegate("world","bowyer9_level_tax", cityId) else return delegate("world","set_bowyer9_level_tax", cityId, v) end end
function M.cartwright9_level_tax(cityId, v) if v==nil then return delegate("world","cartwright9_level_tax", cityId) else return delegate("world","set_cartwright9_level_tax", cityId, v) end end
function M.carpenter9_level_tax(cityId, v) if v==nil then return delegate("world","carpenter9_level_tax", cityId) else return delegate("world","set_carpenter9_level_tax", cityId, v) end end
function M.ropemaker9_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker9_level_tax", cityId) else return delegate("world","set_ropemaker9_level_tax", cityId, v) end end
function M.cooper9_level_tax(cityId, v) if v==nil then return delegate("world","cooper9_level_tax", cityId) else return delegate("world","set_cooper9_level_tax", cityId, v) end end
function M.spinner9_level_tax(cityId, v) if v==nil then return delegate("world","spinner9_level_tax", cityId) else return delegate("world","set_spinner9_level_tax", cityId, v) end end
function M.turner9_level_tax(cityId, v) if v==nil then return delegate("world","turner9_level_tax", cityId) else return delegate("world","set_turner9_level_tax", cityId, v) end end
function M.stonecutter9_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter9_level_tax", cityId) else return delegate("world","set_stonecutter9_level_tax", cityId, v) end end
function M.cobbler9_level_tax(cityId, v) if v==nil then return delegate("world","cobbler9_level_tax", cityId) else return delegate("world","set_cobbler9_level_tax", cityId, v) end end
function M.butcher9_level_tax(cityId, v) if v==nil then return delegate("world","butcher9_level_tax", cityId) else return delegate("world","set_butcher9_level_tax", cityId, v) end end
function M.baker9_level_tax(cityId, v) if v==nil then return delegate("world","baker9_level_tax", cityId) else return delegate("world","set_baker9_level_tax", cityId, v) end end
function M.shepherd9_level_tax(cityId, v) if v==nil then return delegate("world","shepherd9_level_tax", cityId) else return delegate("world","set_shepherd9_level_tax", cityId, v) end end
function M.dairy9_level_tax(cityId, v) if v==nil then return delegate("world","dairy9_level_tax", cityId) else return delegate("world","set_dairy9_level_tax", cityId, v) end end
function M.brewmaster9_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster9_level_tax", cityId) else return delegate("world","set_brewmaster9_level_tax", cityId, v) end end
function M.miller9_level_tax(cityId, v) if v==nil then return delegate("world","miller9_level_tax", cityId) else return delegate("world","set_miller9_level_tax", cityId, v) end end
function M.fishery9_level_tax(cityId, v) if v==nil then return delegate("world","fishery9_level_tax", cityId) else return delegate("world","set_fishery9_level_tax", cityId, v) end end
function M.chandler9_level_tax(cityId, v) if v==nil then return delegate("world","chandler9_level_tax", cityId) else return delegate("world","set_chandler9_level_tax", cityId, v) end end
function M.goldbeater9_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater9_level_tax", cityId) else return delegate("world","set_goldbeater9_level_tax", cityId, v) end end
function M.potter9_level_tax(cityId, v) if v==nil then return delegate("world","potter9_level_tax", cityId) else return delegate("world","set_potter9_level_tax", cityId, v) end end
function M.fowler9_level_tax(cityId, v) if v==nil then return delegate("world","fowler9_level_tax", cityId) else return delegate("world","set_fowler9_level_tax", cityId, v) end end
function M.vintner9_level_tax(cityId, v) if v==nil then return delegate("world","vintner9_level_tax", cityId) else return delegate("world","set_vintner9_level_tax", cityId, v) end end
function M.distiller9_level_tax(cityId, v) if v==nil then return delegate("world","distiller9_level_tax", cityId) else return delegate("world","set_distiller9_level_tax", cityId, v) end end
function M.cook9_level_tax(cityId, v) if v==nil then return delegate("world","cook9_level_tax", cityId) else return delegate("world","set_cook9_level_tax", cityId, v) end end
function M.brickmaker9_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker9_level_tax", cityId) else return delegate("world","set_brickmaker9_level_tax", cityId, v) end end
function M.bathhouse9_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse9_level_tax", cityId) else return delegate("world","set_bathhouse9_level_tax", cityId, v) end end
function M.barracks16_level_tax(cityId, v) if v==nil then return delegate("world","barracks16_level_tax", cityId) else return delegate("world","set_barracks16_level_tax", cityId, v) end end
function M.school9_level_tax(cityId, v) if v==nil then return delegate("world","school9_level_tax", cityId) else return delegate("world","set_school9_level_tax", cityId, v) end end
function M.library9_level_tax(cityId, v) if v==nil then return delegate("world","library9_level_tax", cityId) else return delegate("world","set_library9_level_tax", cityId, v) end end
function M.mine9_level_tax(cityId, v) if v==nil then return delegate("world","mine9_level_tax", cityId) else return delegate("world","set_mine9_level_tax", cityId, v) end end
function M.warehouse9_level_tax(cityId, v) if v==nil then return delegate("world","warehouse9_level_tax", cityId) else return delegate("world","set_warehouse9_level_tax", cityId, v) end end
function M.garrison9_level_tax(cityId, v) if v==nil then return delegate("world","garrison9_level_tax", cityId) else return delegate("world","set_garrison9_level_tax", cityId, v) end end
function M.monastery9_level_tax(cityId, v) if v==nil then return delegate("world","monastery9_level_tax", cityId) else return delegate("world","set_monastery9_level_tax", cityId, v) end end
function M.cathedral9_level_tax(cityId, v) if v==nil then return delegate("world","cathedral9_level_tax", cityId) else return delegate("world","set_cathedral9_level_tax", cityId, v) end end
function M.town_hall9_level_tax(cityId, v) if v==nil then return delegate("world","town_hall9_level_tax", cityId) else return delegate("world","set_town_hall9_level_tax", cityId, v) end end
function M.market9_level_tax(cityId, v) if v==nil then return delegate("world","market9_level_tax", cityId) else return delegate("world","set_market9_level_tax", cityId, v) end end
function M.harbor9_level_tax(cityId, v) if v==nil then return delegate("world","harbor9_level_tax", cityId) else return delegate("world","set_harbor9_level_tax", cityId, v) end end
function M.guardhouse9_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse9_level_tax", cityId) else return delegate("world","set_guardhouse9_level_tax", cityId, v) end end
function M.courthouse9_level_tax(cityId, v) if v==nil then return delegate("world","courthouse9_level_tax", cityId) else return delegate("world","set_courthouse9_level_tax", cityId, v) end end
function M.univ_hall9_level_tax(cityId, v) if v==nil then return delegate("world","univ_hall9_level_tax", cityId) else return delegate("world","set_univ_hall9_level_tax", cityId, v) end end
function M.castle9_level_tax(cityId, v) if v==nil then return delegate("world","castle9_level_tax", cityId) else return delegate("world","set_castle9_level_tax", cityId, v) end end
function M.well9_level_tax(cityId, v) if v==nil then return delegate("world","well9_level_tax", cityId) else return delegate("world","set_well9_level_tax", cityId, v) end end
function M.bridge9_level_tax(cityId, v) if v==nil then return delegate("world","bridge9_level_tax", cityId) else return delegate("world","set_bridge9_level_tax", cityId, v) end end
function M.wall9_level_tax(cityId, v) if v==nil then return delegate("world","wall9_level_tax", cityId) else return delegate("world","set_wall9_level_tax", cityId, v) end end
function M.tower9_level_tax(cityId, v) if v==nil then return delegate("world","tower9_level_tax", cityId) else return delegate("world","set_tower9_level_tax", cityId, v) end end
function M.forum9_level_tax(cityId, v) if v==nil then return delegate("world","forum9_level_tax", cityId) else return delegate("world","set_forum9_level_tax", cityId, v) end end
function M.granary9_level_tax(cityId, v) if v==nil then return delegate("world","granary9_level_tax", cityId) else return delegate("world","set_granary9_level_tax", cityId, v) end end
function M.prison9_level_tax(cityId, v) if v==nil then return delegate("world","prison9_level_tax", cityId) else return delegate("world","set_prison9_level_tax", cityId, v) end end
function M.harbor_dock9_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock9_level_tax", cityId) else return delegate("world","set_harbor_dock9_level_tax", cityId, v) end end
function M.guild_house9_level_tax(cityId, v) if v==nil then return delegate("world","guild_house9_level_tax", cityId) else return delegate("world","set_guild_house9_level_tax", cityId, v) end end
function M.house9_level_tax(cityId, v) if v==nil then return delegate("world","house9_level_tax", cityId) else return delegate("world","set_house9_level_tax", cityId, v) end end
function M.chapel9_level_tax(cityId, v) if v==nil then return delegate("world","chapel9_level_tax", cityId) else return delegate("world","set_chapel9_level_tax", cityId, v) end end
function M.hospital9_level_tax(cityId, v) if v==nil then return delegate("world","hospital9_level_tax", cityId) else return delegate("world","set_hospital9_level_tax", cityId, v) end end
function M.brothel9_level_tax(cityId, v) if v==nil then return delegate("world","brothel9_level_tax", cityId) else return delegate("world","set_brothel9_level_tax", cityId, v) end end
function M.university9_level_tax(cityId, v) if v==nil then return delegate("world","university9_level_tax", cityId) else return delegate("world","set_university9_level_tax", cityId, v) end end
function M.harbor_walls9_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls9_level_tax", cityId) else return delegate("world","set_harbor_walls9_level_tax", cityId, v) end end
function M.schoolhouse9_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse9_level_tax", cityId) else return delegate("world","set_schoolhouse9_level_tax", cityId, v) end end
function M.library_hall9_level_tax(cityId, v) if v==nil then return delegate("world","library_hall9_level_tax", cityId) else return delegate("world","set_library_hall9_level_tax", cityId, v) end end
function M.barber9_level_tax(cityId, v) if v==nil then return delegate("world","barber9_level_tax", cityId) else return delegate("world","set_barber9_level_tax", cityId, v) end end
function M.contor10_level_tax(cityId, v) if v==nil then return delegate("world","contor10_level_tax", cityId) else return delegate("world","set_contor10_level_tax", cityId, v) end end
function M.dice_house10_level_tax(cityId, v) if v==nil then return delegate("world","dice_house10_level_tax", cityId) else return delegate("world","set_dice_house10_level_tax", cityId, v) end end
function M.thieves10_level_tax(cityId, v) if v==nil then return delegate("world","thieves10_level_tax", cityId) else return delegate("world","set_thieves10_level_tax", cityId, v) end end
function M.ropemaker_ws10_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_ws10_level_tax", cityId) else return delegate("world","set_ropemaker_ws10_level_tax", cityId, v) end end
function M.tannery10_level_tax(cityId, v) if v==nil then return delegate("world","tannery10_level_tax", cityId) else return delegate("world","set_tannery10_level_tax", cityId, v) end end
function M.weaving10_level_tax(cityId, v) if v==nil then return delegate("world","weaving10_level_tax", cityId) else return delegate("world","set_weaving10_level_tax", cityId, v) end end
function M.mint10_level_tax(cityId, v) if v==nil then return delegate("world","mint10_level_tax", cityId) else return delegate("world","set_mint10_level_tax", cityId, v) end end
function M.herb_garden10_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden10_level_tax", cityId) else return delegate("world","set_herb_garden10_level_tax", cityId, v) end end
function M.vineyard10_level_tax(cityId, v) if v==nil then return delegate("world","vineyard10_level_tax", cityId) else return delegate("world","set_vineyard10_level_tax", cityId, v) end end
function M.pottery10_level_tax(cityId, v) if v==nil then return delegate("world","pottery10_level_tax", cityId) else return delegate("world","set_pottery10_level_tax", cityId, v) end end
function M.tailor10_level_tax(cityId, v) if v==nil then return delegate("world","tailor10_level_tax", cityId) else return delegate("world","set_tailor10_level_tax", cityId, v) end end
function M.tavern10_level_tax(cityId, v) if v==nil then return delegate("world","tavern10_level_tax", cityId) else return delegate("world","set_tavern10_level_tax", cityId, v) end end
function M.apothecary10_level_tax(cityId, v) if v==nil then return delegate("world","apothecary10_level_tax", cityId) else return delegate("world","set_apothecary10_level_tax", cityId, v) end end
function M.goldsmith10_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith10_level_tax", cityId) else return delegate("world","set_goldsmith10_level_tax", cityId, v) end end
function M.jeweler10_level_tax(cityId, v) if v==nil then return delegate("world","jeweler10_level_tax", cityId) else return delegate("world","set_jeweler10_level_tax", cityId, v) end end
function M.perfumer10_level_tax(cityId, v) if v==nil then return delegate("world","perfumer10_level_tax", cityId) else return delegate("world","set_perfumer10_level_tax", cityId, v) end end
function M.soapmaker10_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker10_level_tax", cityId) else return delegate("world","set_soapmaker10_level_tax", cityId, v) end end
function M.candlemaker10_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker10_level_tax", cityId) else return delegate("world","set_candlemaker10_level_tax", cityId, v) end end
function M.papermill10_level_tax(cityId, v) if v==nil then return delegate("world","papermill10_level_tax", cityId) else return delegate("world","set_papermill10_level_tax", cityId, v) end end
function M.printing10_level_tax(cityId, v) if v==nil then return delegate("world","printing10_level_tax", cityId) else return delegate("world","set_printing10_level_tax", cityId, v) end end
function M.toolmaker10_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker10_level_tax", cityId) else return delegate("world","set_toolmaker10_level_tax", cityId, v) end end
function M.charcoal10_level_tax(cityId, v) if v==nil then return delegate("world","charcoal10_level_tax", cityId) else return delegate("world","set_charcoal10_level_tax", cityId, v) end end
function M.furrier10_level_tax(cityId, v) if v==nil then return delegate("world","furrier10_level_tax", cityId) else return delegate("world","set_furrier10_level_tax", cityId, v) end end
function M.dyer10_level_tax(cityId, v) if v==nil then return delegate("world","dyer10_level_tax", cityId) else return delegate("world","set_dyer10_level_tax", cityId, v) end end
function M.saddler10_level_tax(cityId, v) if v==nil then return delegate("world","saddler10_level_tax", cityId) else return delegate("world","set_saddler10_level_tax", cityId, v) end end
function M.armorer10_level_tax(cityId, v) if v==nil then return delegate("world","armorer10_level_tax", cityId) else return delegate("world","set_armorer10_level_tax", cityId, v) end end
function M.bowyer10_level_tax(cityId, v) if v==nil then return delegate("world","bowyer10_level_tax", cityId) else return delegate("world","set_bowyer10_level_tax", cityId, v) end end
function M.cartwright10_level_tax(cityId, v) if v==nil then return delegate("world","cartwright10_level_tax", cityId) else return delegate("world","set_cartwright10_level_tax", cityId, v) end end
function M.carpenter10_level_tax(cityId, v) if v==nil then return delegate("world","carpenter10_level_tax", cityId) else return delegate("world","set_carpenter10_level_tax", cityId, v) end end
function M.ropemaker10_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker10_level_tax", cityId) else return delegate("world","set_ropemaker10_level_tax", cityId, v) end end
function M.cooper10_level_tax(cityId, v) if v==nil then return delegate("world","cooper10_level_tax", cityId) else return delegate("world","set_cooper10_level_tax", cityId, v) end end
function M.spinner10_level_tax(cityId, v) if v==nil then return delegate("world","spinner10_level_tax", cityId) else return delegate("world","set_spinner10_level_tax", cityId, v) end end
function M.turner10_level_tax(cityId, v) if v==nil then return delegate("world","turner10_level_tax", cityId) else return delegate("world","set_turner10_level_tax", cityId, v) end end
function M.stonecutter10_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter10_level_tax", cityId) else return delegate("world","set_stonecutter10_level_tax", cityId, v) end end
function M.cobbler10_level_tax(cityId, v) if v==nil then return delegate("world","cobbler10_level_tax", cityId) else return delegate("world","set_cobbler10_level_tax", cityId, v) end end
function M.butcher10_level_tax(cityId, v) if v==nil then return delegate("world","butcher10_level_tax", cityId) else return delegate("world","set_butcher10_level_tax", cityId, v) end end
function M.baker10_level_tax(cityId, v) if v==nil then return delegate("world","baker10_level_tax", cityId) else return delegate("world","set_baker10_level_tax", cityId, v) end end
function M.shepherd10_level_tax(cityId, v) if v==nil then return delegate("world","shepherd10_level_tax", cityId) else return delegate("world","set_shepherd10_level_tax", cityId, v) end end
function M.dairy10_level_tax(cityId, v) if v==nil then return delegate("world","dairy10_level_tax", cityId) else return delegate("world","set_dairy10_level_tax", cityId, v) end end
function M.brewmaster10_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster10_level_tax", cityId) else return delegate("world","set_brewmaster10_level_tax", cityId, v) end end
function M.miller10_level_tax(cityId, v) if v==nil then return delegate("world","miller10_level_tax", cityId) else return delegate("world","set_miller10_level_tax", cityId, v) end end
function M.fishery10_level_tax(cityId, v) if v==nil then return delegate("world","fishery10_level_tax", cityId) else return delegate("world","set_fishery10_level_tax", cityId, v) end end
function M.chandler10_level_tax(cityId, v) if v==nil then return delegate("world","chandler10_level_tax", cityId) else return delegate("world","set_chandler10_level_tax", cityId, v) end end
function M.brickmaker10_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker10_level_tax", cityId) else return delegate("world","set_brickmaker10_level_tax", cityId, v) end end
function M.potter10_level_tax(cityId, v) if v==nil then return delegate("world","potter10_level_tax", cityId) else return delegate("world","set_potter10_level_tax", cityId, v) end end
function M.glassblower10_level_tax(cityId, v) if v==nil then return delegate("world","glassblower10_level_tax", cityId) else return delegate("world","set_glassblower10_level_tax", cityId, v) end end
function M.goldbeater10_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater10_level_tax", cityId) else return delegate("world","set_goldbeater10_level_tax", cityId, v) end end
function M.fowler10_level_tax(cityId, v) if v==nil then return delegate("world","fowler10_level_tax", cityId) else return delegate("world","set_fowler10_level_tax", cityId, v) end end
function M.vintner10_level_tax(cityId, v) if v==nil then return delegate("world","vintner10_level_tax", cityId) else return delegate("world","set_vintner10_level_tax", cityId, v) end end
function M.distiller10_level_tax(cityId, v) if v==nil then return delegate("world","distiller10_level_tax", cityId) else return delegate("world","set_distiller10_level_tax", cityId, v) end end
function M.cook10_level_tax(cityId, v) if v==nil then return delegate("world","cook10_level_tax", cityId) else return delegate("world","set_cook10_level_tax", cityId, v) end end
function M.glassblower_level_tax(cityId, v) if v==nil then return delegate("world","glassblower_level_tax", cityId) else return delegate("world","set_glassblower_level_tax", cityId, v) end end
function M.glassblower2_level_tax(cityId, v) if v==nil then return delegate("world","glassblower2_level_tax", cityId) else return delegate("world","set_glassblower2_level_tax", cityId, v) end end
function M.glassblower3_level_tax(cityId, v) if v==nil then return delegate("world","glassblower3_level_tax", cityId) else return delegate("world","set_glassblower3_level_tax", cityId, v) end end
function M.glassblower4_level_tax(cityId, v) if v==nil then return delegate("world","glassblower4_level_tax", cityId) else return delegate("world","set_glassblower4_level_tax", cityId, v) end end
function M.glassblower5_level_tax(cityId, v) if v==nil then return delegate("world","glassblower5_level_tax", cityId) else return delegate("world","set_glassblower5_level_tax", cityId, v) end end
function M.glassblower6_level_tax(cityId, v) if v==nil then return delegate("world","glassblower6_level_tax", cityId) else return delegate("world","set_glassblower6_level_tax", cityId, v) end end
function M.glassblower7_level_tax(cityId, v) if v==nil then return delegate("world","glassblower7_level_tax", cityId) else return delegate("world","set_glassblower7_level_tax", cityId, v) end end
function M.glassblower8_level_tax(cityId, v) if v==nil then return delegate("world","glassblower8_level_tax", cityId) else return delegate("world","set_glassblower8_level_tax", cityId, v) end end
function M.glassblower9_level_tax(cityId, v) if v==nil then return delegate("world","glassblower9_level_tax", cityId) else return delegate("world","set_glassblower9_level_tax", cityId, v) end end
function M.barber10_level_tax(cityId, v) if v==nil then return delegate("world","barber10_level_tax", cityId) else return delegate("world","set_barber10_level_tax", cityId, v) end end
function M.bathhouse10_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse10_level_tax", cityId) else return delegate("world","set_bathhouse10_level_tax", cityId, v) end end
function M.bridge10_level_tax(cityId, v) if v==nil then return delegate("world","bridge10_level_tax", cityId) else return delegate("world","set_bridge10_level_tax", cityId, v) end end
function M.brothel10_level_tax(cityId, v) if v==nil then return delegate("world","brothel10_level_tax", cityId) else return delegate("world","set_brothel10_level_tax", cityId, v) end end
function M.castle10_level_tax(cityId, v) if v==nil then return delegate("world","castle10_level_tax", cityId) else return delegate("world","set_castle10_level_tax", cityId, v) end end
function M.cathedral10_level_tax(cityId, v) if v==nil then return delegate("world","cathedral10_level_tax", cityId) else return delegate("world","set_cathedral10_level_tax", cityId, v) end end
function M.chapel10_level_tax(cityId, v) if v==nil then return delegate("world","chapel10_level_tax", cityId) else return delegate("world","set_chapel10_level_tax", cityId, v) end end
function M.courthouse10_level_tax(cityId, v) if v==nil then return delegate("world","courthouse10_level_tax", cityId) else return delegate("world","set_courthouse10_level_tax", cityId, v) end end
function M.forum10_level_tax(cityId, v) if v==nil then return delegate("world","forum10_level_tax", cityId) else return delegate("world","set_forum10_level_tax", cityId, v) end end
function M.garrison10_level_tax(cityId, v) if v==nil then return delegate("world","garrison10_level_tax", cityId) else return delegate("world","set_garrison10_level_tax", cityId, v) end end
function M.gates10_level_tax(cityId, v) if v==nil then return delegate("world","gates10_level_tax", cityId) else return delegate("world","set_gates10_level_tax", cityId, v) end end
function M.granary10_level_tax(cityId, v) if v==nil then return delegate("world","granary10_level_tax", cityId) else return delegate("world","set_granary10_level_tax", cityId, v) end end
function M.guardhouse10_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse10_level_tax", cityId) else return delegate("world","set_guardhouse10_level_tax", cityId, v) end end
function M.guild_house10_level_tax(cityId, v) if v==nil then return delegate("world","guild_house10_level_tax", cityId) else return delegate("world","set_guild_house10_level_tax", cityId, v) end end
function M.harbor10_level_tax(cityId, v) if v==nil then return delegate("world","harbor10_level_tax", cityId) else return delegate("world","set_harbor10_level_tax", cityId, v) end end
function M.harbor_dock10_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock10_level_tax", cityId) else return delegate("world","set_harbor_dock10_level_tax", cityId, v) end end
function M.harbor_walls10_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls10_level_tax", cityId) else return delegate("world","set_harbor_walls10_level_tax", cityId, v) end end
function M.hospital10_level_tax(cityId, v) if v==nil then return delegate("world","hospital10_level_tax", cityId) else return delegate("world","set_hospital10_level_tax", cityId, v) end end
function M.house10_level_tax(cityId, v) if v==nil then return delegate("world","house10_level_tax", cityId) else return delegate("world","set_house10_level_tax", cityId, v) end end
function M.library10_level_tax(cityId, v) if v==nil then return delegate("world","library10_level_tax", cityId) else return delegate("world","set_library10_level_tax", cityId, v) end end
function M.library_hall10_level_tax(cityId, v) if v==nil then return delegate("world","library_hall10_level_tax", cityId) else return delegate("world","set_library_hall10_level_tax", cityId, v) end end
function M.market10_level_tax(cityId, v) if v==nil then return delegate("world","market10_level_tax", cityId) else return delegate("world","set_market10_level_tax", cityId, v) end end
function M.mine10_level_tax(cityId, v) if v==nil then return delegate("world","mine10_level_tax", cityId) else return delegate("world","set_mine10_level_tax", cityId, v) end end
function M.monastery10_level_tax(cityId, v) if v==nil then return delegate("world","monastery10_level_tax", cityId) else return delegate("world","set_monastery10_level_tax", cityId, v) end end
function M.prison10_level_tax(cityId, v) if v==nil then return delegate("world","prison10_level_tax", cityId) else return delegate("world","set_prison10_level_tax", cityId, v) end end
function M.school10_level_tax(cityId, v) if v==nil then return delegate("world","school10_level_tax", cityId) else return delegate("world","set_school10_level_tax", cityId, v) end end
function M.schoolhouse10_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse10_level_tax", cityId) else return delegate("world","set_schoolhouse10_level_tax", cityId, v) end end
function M.sentry_tower10_level_tax(cityId, v) if v==nil then return delegate("world","sentry_tower10_level_tax", cityId) else return delegate("world","set_sentry_tower10_level_tax", cityId, v) end end
function M.stables10_level_tax(cityId, v) if v==nil then return delegate("world","stables10_level_tax", cityId) else return delegate("world","set_stables10_level_tax", cityId, v) end end
function M.tower10_level_tax(cityId, v) if v==nil then return delegate("world","tower10_level_tax", cityId) else return delegate("world","set_tower10_level_tax", cityId, v) end end
function M.town_hall10_level_tax(cityId, v) if v==nil then return delegate("world","town_hall10_level_tax", cityId) else return delegate("world","set_town_hall10_level_tax", cityId, v) end end
function M.university10_level_tax(cityId, v) if v==nil then return delegate("world","university10_level_tax", cityId) else return delegate("world","set_university10_level_tax", cityId, v) end end
function M.university_hall10_level_tax(cityId, v) if v==nil then return delegate("world","university_hall10_level_tax", cityId) else return delegate("world","set_university_hall10_level_tax", cityId, v) end end
function M.wall10_level_tax(cityId, v) if v==nil then return delegate("world","wall10_level_tax", cityId) else return delegate("world","set_wall10_level_tax", cityId, v) end end
function M.warehouse10_level_tax(cityId, v) if v==nil then return delegate("world","warehouse10_level_tax", cityId) else return delegate("world","set_warehouse10_level_tax", cityId, v) end end
function M.well10_level_tax(cityId, v) if v==nil then return delegate("world","well10_level_tax", cityId) else return delegate("world","set_well10_level_tax", cityId, v) end end
function M.gates8_level_tax(cityId, v) if v==nil then return delegate("world","gates8_level_tax", cityId) else return delegate("world","set_gates8_level_tax", cityId, v) end end
function M.gates9_level_tax(cityId, v) if v==nil then return delegate("world","gates9_level_tax", cityId) else return delegate("world","set_gates9_level_tax", cityId, v) end end
function M.sentry_tower8_level_tax(cityId, v) if v==nil then return delegate("world","sentry_tower8_level_tax", cityId) else return delegate("world","set_sentry_tower8_level_tax", cityId, v) end end
function M.sentry_tower9_level_tax(cityId, v) if v==nil then return delegate("world","sentry_tower9_level_tax", cityId) else return delegate("world","set_sentry_tower9_level_tax", cityId, v) end end
function M.stables8_level_tax(cityId, v) if v==nil then return delegate("world","stables8_level_tax", cityId) else return delegate("world","set_stables8_level_tax", cityId, v) end end
function M.stables9_level_tax(cityId, v) if v==nil then return delegate("world","stables9_level_tax", cityId) else return delegate("world","set_stables9_level_tax", cityId, v) end end
function M.church2_level_tax(cityId, v) if v==nil then return delegate("world","church2_level_tax", cityId) else return delegate("world","set_church2_level_tax", cityId, v) end end
function M.church3_level_tax(cityId, v) if v==nil then return delegate("world","church3_level_tax", cityId) else return delegate("world","set_church3_level_tax", cityId, v) end end
function M.church4_level_tax(cityId, v) if v==nil then return delegate("world","church4_level_tax", cityId) else return delegate("world","set_church4_level_tax", cityId, v) end end
function M.church5_level_tax(cityId, v) if v==nil then return delegate("world","church5_level_tax", cityId) else return delegate("world","set_church5_level_tax", cityId, v) end end
function M.church6_level_tax(cityId, v) if v==nil then return delegate("world","church6_level_tax", cityId) else return delegate("world","set_church6_level_tax", cityId, v) end end
function M.church7_level_tax(cityId, v) if v==nil then return delegate("world","church7_level_tax", cityId) else return delegate("world","set_church7_level_tax", cityId, v) end end
function M.church8_level_tax(cityId, v) if v==nil then return delegate("world","church8_level_tax", cityId) else return delegate("world","set_church8_level_tax", cityId, v) end end
function M.church9_level_tax(cityId, v) if v==nil then return delegate("world","church9_level_tax", cityId) else return delegate("world","set_church9_level_tax", cityId, v) end end
function M.church10_level_tax(cityId, v) if v==nil then return delegate("world","church10_level_tax", cityId) else return delegate("world","set_church10_level_tax", cityId, v) end end
function M.town_hall11_level_tax(cityId, v) if v==nil then return delegate("world","town_hall11_level_tax", cityId) else return delegate("world","set_town_hall11_level_tax", cityId, v) end end
function M.university11_level_tax(cityId, v) if v==nil then return delegate("world","university11_level_tax", cityId) else return delegate("world","set_university11_level_tax", cityId, v) end end
function M.wall11_level_tax(cityId, v) if v==nil then return delegate("world","wall11_level_tax", cityId) else return delegate("world","set_wall11_level_tax", cityId, v) end end
function M.apothecary11_level_tax(cityId, v) if v==nil then return delegate("world","apothecary11_level_tax", cityId) else return delegate("world","set_apothecary11_level_tax", cityId, v) end end
function M.baker11_level_tax(cityId, v) if v==nil then return delegate("world","baker11_level_tax", cityId) else return delegate("world","set_baker11_level_tax", cityId, v) end end
function M.barber11_level_tax(cityId, v) if v==nil then return delegate("world","barber11_level_tax", cityId) else return delegate("world","set_barber11_level_tax", cityId, v) end end
function M.bathhouse11_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse11_level_tax", cityId) else return delegate("world","set_bathhouse11_level_tax", cityId, v) end end
function M.bowyer11_level_tax(cityId, v) if v==nil then return delegate("world","bowyer11_level_tax", cityId) else return delegate("world","set_bowyer11_level_tax", cityId, v) end end
function M.brewmaster11_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster11_level_tax", cityId) else return delegate("world","set_brewmaster11_level_tax", cityId, v) end end
function M.brickmaker11_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker11_level_tax", cityId) else return delegate("world","set_brickmaker11_level_tax", cityId, v) end end
function M.bridge11_level_tax(cityId, v) if v==nil then return delegate("world","bridge11_level_tax", cityId) else return delegate("world","set_bridge11_level_tax", cityId, v) end end
function M.brothel11_level_tax(cityId, v) if v==nil then return delegate("world","brothel11_level_tax", cityId) else return delegate("world","set_brothel11_level_tax", cityId, v) end end
function M.butcher11_level_tax(cityId, v) if v==nil then return delegate("world","butcher11_level_tax", cityId) else return delegate("world","set_butcher11_level_tax", cityId, v) end end
function M.candlemaker11_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker11_level_tax", cityId) else return delegate("world","set_candlemaker11_level_tax", cityId, v) end end
function M.carpenter11_level_tax(cityId, v) if v==nil then return delegate("world","carpenter11_level_tax", cityId) else return delegate("world","set_carpenter11_level_tax", cityId, v) end end
function M.cartwright11_level_tax(cityId, v) if v==nil then return delegate("world","cartwright11_level_tax", cityId) else return delegate("world","set_cartwright11_level_tax", cityId, v) end end
function M.castle11_level_tax(cityId, v) if v==nil then return delegate("world","castle11_level_tax", cityId) else return delegate("world","set_castle11_level_tax", cityId, v) end end
function M.cathedral11_level_tax(cityId, v) if v==nil then return delegate("world","cathedral11_level_tax", cityId) else return delegate("world","set_cathedral11_level_tax", cityId, v) end end
function M.chandler11_level_tax(cityId, v) if v==nil then return delegate("world","chandler11_level_tax", cityId) else return delegate("world","set_chandler11_level_tax", cityId, v) end end
function M.chapel11_level_tax(cityId, v) if v==nil then return delegate("world","chapel11_level_tax", cityId) else return delegate("world","set_chapel11_level_tax", cityId, v) end end
function M.church11_level_tax(cityId, v) if v==nil then return delegate("world","church11_level_tax", cityId) else return delegate("world","set_church11_level_tax", cityId, v) end end
function M.cobbler11_level_tax(cityId, v) if v==nil then return delegate("world","cobbler11_level_tax", cityId) else return delegate("world","set_cobbler11_level_tax", cityId, v) end end
function M.contor11_level_tax(cityId, v) if v==nil then return delegate("world","contor11_level_tax", cityId) else return delegate("world","set_contor11_level_tax", cityId, v) end end
function M.cook11_level_tax(cityId, v) if v==nil then return delegate("world","cook11_level_tax", cityId) else return delegate("world","set_cook11_level_tax", cityId, v) end end
function M.cooper11_level_tax(cityId, v) if v==nil then return delegate("world","cooper11_level_tax", cityId) else return delegate("world","set_cooper11_level_tax", cityId, v) end end
function M.courthouse11_level_tax(cityId, v) if v==nil then return delegate("world","courthouse11_level_tax", cityId) else return delegate("world","set_courthouse11_level_tax", cityId, v) end end
function M.dairy11_level_tax(cityId, v) if v==nil then return delegate("world","dairy11_level_tax", cityId) else return delegate("world","set_dairy11_level_tax", cityId, v) end end
function M.dice_house11_level_tax(cityId, v) if v==nil then return delegate("world","dice_house11_level_tax", cityId) else return delegate("world","set_dice_house11_level_tax", cityId, v) end end
function M.distiller11_level_tax(cityId, v) if v==nil then return delegate("world","distiller11_level_tax", cityId) else return delegate("world","set_distiller11_level_tax", cityId, v) end end
function M.dyer11_level_tax(cityId, v) if v==nil then return delegate("world","dyer11_level_tax", cityId) else return delegate("world","set_dyer11_level_tax", cityId, v) end end
function M.fishery11_level_tax(cityId, v) if v==nil then return delegate("world","fishery11_level_tax", cityId) else return delegate("world","set_fishery11_level_tax", cityId, v) end end
function M.forum11_level_tax(cityId, v) if v==nil then return delegate("world","forum11_level_tax", cityId) else return delegate("world","set_forum11_level_tax", cityId, v) end end
function M.fowler11_level_tax(cityId, v) if v==nil then return delegate("world","fowler11_level_tax", cityId) else return delegate("world","set_fowler11_level_tax", cityId, v) end end
function M.furrier11_level_tax(cityId, v) if v==nil then return delegate("world","furrier11_level_tax", cityId) else return delegate("world","set_furrier11_level_tax", cityId, v) end end
function M.garrison11_level_tax(cityId, v) if v==nil then return delegate("world","garrison11_level_tax", cityId) else return delegate("world","set_garrison11_level_tax", cityId, v) end end
function M.gates11_level_tax(cityId, v) if v==nil then return delegate("world","gates11_level_tax", cityId) else return delegate("world","set_gates11_level_tax", cityId, v) end end
function M.glassblower11_level_tax(cityId, v) if v==nil then return delegate("world","glassblower11_level_tax", cityId) else return delegate("world","set_glassblower11_level_tax", cityId, v) end end
function M.goldbeater11_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater11_level_tax", cityId) else return delegate("world","set_goldbeater11_level_tax", cityId, v) end end
function M.goldsmith11_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith11_level_tax", cityId) else return delegate("world","set_goldsmith11_level_tax", cityId, v) end end
function M.granary11_level_tax(cityId, v) if v==nil then return delegate("world","granary11_level_tax", cityId) else return delegate("world","set_granary11_level_tax", cityId, v) end end
function M.guardhouse11_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse11_level_tax", cityId) else return delegate("world","set_guardhouse11_level_tax", cityId, v) end end
function M.guild_house11_level_tax(cityId, v) if v==nil then return delegate("world","guild_house11_level_tax", cityId) else return delegate("world","set_guild_house11_level_tax", cityId, v) end end
function M.harbor11_level_tax(cityId, v) if v==nil then return delegate("world","harbor11_level_tax", cityId) else return delegate("world","set_harbor11_level_tax", cityId, v) end end
function M.harbor_dock11_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock11_level_tax", cityId) else return delegate("world","set_harbor_dock11_level_tax", cityId, v) end end
function M.harbor_walls11_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls11_level_tax", cityId) else return delegate("world","set_harbor_walls11_level_tax", cityId, v) end end
function M.herb_garden11_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden11_level_tax", cityId) else return delegate("world","set_herb_garden11_level_tax", cityId, v) end end
function M.hospital11_level_tax(cityId, v) if v==nil then return delegate("world","hospital11_level_tax", cityId) else return delegate("world","set_hospital11_level_tax", cityId, v) end end
function M.house11_level_tax(cityId, v) if v==nil then return delegate("world","house11_level_tax", cityId) else return delegate("world","set_house11_level_tax", cityId, v) end end
function M.jeweler11_level_tax(cityId, v) if v==nil then return delegate("world","jeweler11_level_tax", cityId) else return delegate("world","set_jeweler11_level_tax", cityId, v) end end
function M.library11_level_tax(cityId, v) if v==nil then return delegate("world","library11_level_tax", cityId) else return delegate("world","set_library11_level_tax", cityId, v) end end
function M.library_hall11_level_tax(cityId, v) if v==nil then return delegate("world","library_hall11_level_tax", cityId) else return delegate("world","set_library_hall11_level_tax", cityId, v) end end
function M.market11_level_tax(cityId, v) if v==nil then return delegate("world","market11_level_tax", cityId) else return delegate("world","set_market11_level_tax", cityId, v) end end
function M.miller11_level_tax(cityId, v) if v==nil then return delegate("world","miller11_level_tax", cityId) else return delegate("world","set_miller11_level_tax", cityId, v) end end
function M.mine11_level_tax(cityId, v) if v==nil then return delegate("world","mine11_level_tax", cityId) else return delegate("world","set_mine11_level_tax", cityId, v) end end
function M.mint11_level_tax(cityId, v) if v==nil then return delegate("world","mint11_level_tax", cityId) else return delegate("world","set_mint11_level_tax", cityId, v) end end
function M.monastery11_level_tax(cityId, v) if v==nil then return delegate("world","monastery11_level_tax", cityId) else return delegate("world","set_monastery11_level_tax", cityId, v) end end
function M.papermill11_level_tax(cityId, v) if v==nil then return delegate("world","papermill11_level_tax", cityId) else return delegate("world","set_papermill11_level_tax", cityId, v) end end
function M.perfumer11_level_tax(cityId, v) if v==nil then return delegate("world","perfumer11_level_tax", cityId) else return delegate("world","set_perfumer11_level_tax", cityId, v) end end
function M.potter11_level_tax(cityId, v) if v==nil then return delegate("world","potter11_level_tax", cityId) else return delegate("world","set_potter11_level_tax", cityId, v) end end
function M.pottery11_level_tax(cityId, v) if v==nil then return delegate("world","pottery11_level_tax", cityId) else return delegate("world","set_pottery11_level_tax", cityId, v) end end
function M.printing_house11_level_tax(cityId, v) if v==nil then return delegate("world","printing_house11_level_tax", cityId) else return delegate("world","set_printing_house11_level_tax", cityId, v) end end
function M.ropemaker11_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker11_level_tax", cityId) else return delegate("world","set_ropemaker11_level_tax", cityId, v) end end
function M.ropemaker_workshop11_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_workshop11_level_tax", cityId) else return delegate("world","set_ropemaker_workshop11_level_tax", cityId, v) end end
function M.saddler11_level_tax(cityId, v) if v==nil then return delegate("world","saddler11_level_tax", cityId) else return delegate("world","set_saddler11_level_tax", cityId, v) end end
function M.school11_level_tax(cityId, v) if v==nil then return delegate("world","school11_level_tax", cityId) else return delegate("world","set_school11_level_tax", cityId, v) end end
function M.schoolhouse11_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse11_level_tax", cityId) else return delegate("world","set_schoolhouse11_level_tax", cityId, v) end end
function M.sentry_tower11_level_tax(cityId, v) if v==nil then return delegate("world","sentry_tower11_level_tax", cityId) else return delegate("world","set_sentry_tower11_level_tax", cityId, v) end end
function M.stables11_level_tax(cityId, v) if v==nil then return delegate("world","stables11_level_tax", cityId) else return delegate("world","set_stables11_level_tax", cityId, v) end end
function M.stonecutter11_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter11_level_tax", cityId) else return delegate("world","set_stonecutter11_level_tax", cityId, v) end end
function M.tailor11_level_tax(cityId, v) if v==nil then return delegate("world","tailor11_level_tax", cityId) else return delegate("world","set_tailor11_level_tax", cityId, v) end end
function M.tannery11_level_tax(cityId, v) if v==nil then return delegate("world","tannery11_level_tax", cityId) else return delegate("world","set_tannery11_level_tax", cityId, v) end end
function M.tavern11_level_tax(cityId, v) if v==nil then return delegate("world","tavern11_level_tax", cityId) else return delegate("world","set_tavern11_level_tax", cityId, v) end end
function M.thieves_guild11_level_tax(cityId, v) if v==nil then return delegate("world","thieves_guild11_level_tax", cityId) else return delegate("world","set_thieves_guild11_level_tax", cityId, v) end end
function M.toolmaker11_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker11_level_tax", cityId) else return delegate("world","set_toolmaker11_level_tax", cityId, v) end end
function M.tower11_level_tax(cityId, v) if v==nil then return delegate("world","tower11_level_tax", cityId) else return delegate("world","set_tower11_level_tax", cityId, v) end end
function M.town_hall12_level_tax(cityId, v) if v==nil then return delegate("world","town_hall12_level_tax", cityId) else return delegate("world","set_town_hall12_level_tax", cityId, v) end end
function M.turner11_level_tax(cityId, v) if v==nil then return delegate("world","turner11_level_tax", cityId) else return delegate("world","set_turner11_level_tax", cityId, v) end end
function M.university12_level_tax(cityId, v) if v==nil then return delegate("world","university12_level_tax", cityId) else return delegate("world","set_university12_level_tax", cityId, v) end end
function M.university_hall11_level_tax(cityId, v) if v==nil then return delegate("world","university_hall11_level_tax", cityId) else return delegate("world","set_university_hall11_level_tax", cityId, v) end end
function M.vineyard11_level_tax(cityId, v) if v==nil then return delegate("world","vineyard11_level_tax", cityId) else return delegate("world","set_vineyard11_level_tax", cityId, v) end end
function M.vintner11_level_tax(cityId, v) if v==nil then return delegate("world","vintner11_level_tax", cityId) else return delegate("world","set_vintner11_level_tax", cityId, v) end end
function M.wall12_level_tax(cityId, v) if v==nil then return delegate("world","wall12_level_tax", cityId) else return delegate("world","set_wall12_level_tax", cityId, v) end end
function M.warehouse11_level_tax(cityId, v) if v==nil then return delegate("world","warehouse11_level_tax", cityId) else return delegate("world","set_warehouse11_level_tax", cityId, v) end end
function M.weaving_mill11_level_tax(cityId, v) if v==nil then return delegate("world","weaving_mill11_level_tax", cityId) else return delegate("world","set_weaving_mill11_level_tax", cityId, v) end end
function M.well11_level_tax(cityId, v) if v==nil then return delegate("world","well11_level_tax", cityId) else return delegate("world","set_well11_level_tax", cityId, v) end end
function M.armorer11_level_tax(cityId, v) if v==nil then return delegate("world","armorer11_level_tax", cityId) else return delegate("world","set_armorer11_level_tax", cityId, v) end end
function M.candlemaker12_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker12_level_tax", cityId) else return delegate("world","set_candlemaker12_level_tax", cityId, v) end end
function M.carpenter12_level_tax(cityId, v) if v==nil then return delegate("world","carpenter12_level_tax", cityId) else return delegate("world","set_carpenter12_level_tax", cityId, v) end end
function M.cartwright12_level_tax(cityId, v) if v==nil then return delegate("world","cartwright12_level_tax", cityId) else return delegate("world","set_cartwright12_level_tax", cityId, v) end end
function M.chandler12_level_tax(cityId, v) if v==nil then return delegate("world","chandler12_level_tax", cityId) else return delegate("world","set_chandler12_level_tax", cityId, v) end end
function M.charcoal11_level_tax(cityId, v) if v==nil then return delegate("world","charcoal11_level_tax", cityId) else return delegate("world","set_charcoal11_level_tax", cityId, v) end end
function M.charcoal12_level_tax(cityId, v) if v==nil then return delegate("world","charcoal12_level_tax", cityId) else return delegate("world","set_charcoal12_level_tax", cityId, v) end end
function M.church12_level_tax(cityId, v) if v==nil then return delegate("world","church12_level_tax", cityId) else return delegate("world","set_church12_level_tax", cityId, v) end end
function M.cobbler12_level_tax(cityId, v) if v==nil then return delegate("world","cobbler12_level_tax", cityId) else return delegate("world","set_cobbler12_level_tax", cityId, v) end end
function M.contor12_level_tax(cityId, v) if v==nil then return delegate("world","contor12_level_tax", cityId) else return delegate("world","set_contor12_level_tax", cityId, v) end end
function M.cook12_level_tax(cityId, v) if v==nil then return delegate("world","cook12_level_tax", cityId) else return delegate("world","set_cook12_level_tax", cityId, v) end end
function M.cooper12_level_tax(cityId, v) if v==nil then return delegate("world","cooper12_level_tax", cityId) else return delegate("world","set_cooper12_level_tax", cityId, v) end end
function M.courthouse12_level_tax(cityId, v) if v==nil then return delegate("world","courthouse12_level_tax", cityId) else return delegate("world","set_courthouse12_level_tax", cityId, v) end end
function M.dairy12_level_tax(cityId, v) if v==nil then return delegate("world","dairy12_level_tax", cityId) else return delegate("world","set_dairy12_level_tax", cityId, v) end end
function M.dice_house12_level_tax(cityId, v) if v==nil then return delegate("world","dice_house12_level_tax", cityId) else return delegate("world","set_dice_house12_level_tax", cityId, v) end end
function M.distiller12_level_tax(cityId, v) if v==nil then return delegate("world","distiller12_level_tax", cityId) else return delegate("world","set_distiller12_level_tax", cityId, v) end end
function M.dyer12_level_tax(cityId, v) if v==nil then return delegate("world","dyer12_level_tax", cityId) else return delegate("world","set_dyer12_level_tax", cityId, v) end end
function M.fishery12_level_tax(cityId, v) if v==nil then return delegate("world","fishery12_level_tax", cityId) else return delegate("world","set_fishery12_level_tax", cityId, v) end end
function M.forum12_level_tax(cityId, v) if v==nil then return delegate("world","forum12_level_tax", cityId) else return delegate("world","set_forum12_level_tax", cityId, v) end end
function M.fowler12_level_tax(cityId, v) if v==nil then return delegate("world","fowler12_level_tax", cityId) else return delegate("world","set_fowler12_level_tax", cityId, v) end end
function M.furrier12_level_tax(cityId, v) if v==nil then return delegate("world","furrier12_level_tax", cityId) else return delegate("world","set_furrier12_level_tax", cityId, v) end end
function M.garrison12_level_tax(cityId, v) if v==nil then return delegate("world","garrison12_level_tax", cityId) else return delegate("world","set_garrison12_level_tax", cityId, v) end end
function M.gates12_level_tax(cityId, v) if v==nil then return delegate("world","gates12_level_tax", cityId) else return delegate("world","set_gates12_level_tax", cityId, v) end end
function M.glassblower12_level_tax(cityId, v) if v==nil then return delegate("world","glassblower12_level_tax", cityId) else return delegate("world","set_glassblower12_level_tax", cityId, v) end end
function M.goldbeater12_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater12_level_tax", cityId) else return delegate("world","set_goldbeater12_level_tax", cityId, v) end end
function M.goldsmith12_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith12_level_tax", cityId) else return delegate("world","set_goldsmith12_level_tax", cityId, v) end end
function M.granary12_level_tax(cityId, v) if v==nil then return delegate("world","granary12_level_tax", cityId) else return delegate("world","set_granary12_level_tax", cityId, v) end end
function M.guardhouse12_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse12_level_tax", cityId) else return delegate("world","set_guardhouse12_level_tax", cityId, v) end end
function M.guild_house12_level_tax(cityId, v) if v==nil then return delegate("world","guild_house12_level_tax", cityId) else return delegate("world","set_guild_house12_level_tax", cityId, v) end end
function M.harbor12_level_tax(cityId, v) if v==nil then return delegate("world","harbor12_level_tax", cityId) else return delegate("world","set_harbor12_level_tax", cityId, v) end end
function M.harbor_dock12_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock12_level_tax", cityId) else return delegate("world","set_harbor_dock12_level_tax", cityId, v) end end
function M.harbor_walls12_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls12_level_tax", cityId) else return delegate("world","set_harbor_walls12_level_tax", cityId, v) end end
function M.herb_garden12_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden12_level_tax", cityId) else return delegate("world","set_herb_garden12_level_tax", cityId, v) end end
function M.hospital12_level_tax(cityId, v) if v==nil then return delegate("world","hospital12_level_tax", cityId) else return delegate("world","set_hospital12_level_tax", cityId, v) end end
function M.house12_level_tax(cityId, v) if v==nil then return delegate("world","house12_level_tax", cityId) else return delegate("world","set_house12_level_tax", cityId, v) end end
function M.jeweler12_level_tax(cityId, v) if v==nil then return delegate("world","jeweler12_level_tax", cityId) else return delegate("world","set_jeweler12_level_tax", cityId, v) end end
function M.library12_level_tax(cityId, v) if v==nil then return delegate("world","library12_level_tax", cityId) else return delegate("world","set_library12_level_tax", cityId, v) end end
function M.library_hall12_level_tax(cityId, v) if v==nil then return delegate("world","library_hall12_level_tax", cityId) else return delegate("world","set_library_hall12_level_tax", cityId, v) end end
function M.market12_level_tax(cityId, v) if v==nil then return delegate("world","market12_level_tax", cityId) else return delegate("world","set_market12_level_tax", cityId, v) end end
function M.miller12_level_tax(cityId, v) if v==nil then return delegate("world","miller12_level_tax", cityId) else return delegate("world","set_miller12_level_tax", cityId, v) end end
function M.mine12_level_tax(cityId, v) if v==nil then return delegate("world","mine12_level_tax", cityId) else return delegate("world","set_mine12_level_tax", cityId, v) end end
function M.mint12_level_tax(cityId, v) if v==nil then return delegate("world","mint12_level_tax", cityId) else return delegate("world","set_mint12_level_tax", cityId, v) end end
function M.monastery12_level_tax(cityId, v) if v==nil then return delegate("world","monastery12_level_tax", cityId) else return delegate("world","set_monastery12_level_tax", cityId, v) end end
function M.papermill12_level_tax(cityId, v) if v==nil then return delegate("world","papermill12_level_tax", cityId) else return delegate("world","set_papermill12_level_tax", cityId, v) end end
function M.perfumer12_level_tax(cityId, v) if v==nil then return delegate("world","perfumer12_level_tax", cityId) else return delegate("world","set_perfumer12_level_tax", cityId, v) end end
function M.potter12_level_tax(cityId, v) if v==nil then return delegate("world","potter12_level_tax", cityId) else return delegate("world","set_potter12_level_tax", cityId, v) end end
function M.pottery12_level_tax(cityId, v) if v==nil then return delegate("world","pottery12_level_tax", cityId) else return delegate("world","set_pottery12_level_tax", cityId, v) end end
function M.printing_house12_level_tax(cityId, v) if v==nil then return delegate("world","printing_house12_level_tax", cityId) else return delegate("world","set_printing_house12_level_tax", cityId, v) end end
function M.ropemaker12_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker12_level_tax", cityId) else return delegate("world","set_ropemaker12_level_tax", cityId, v) end end
function M.ropemaker_workshop12_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_workshop12_level_tax", cityId) else return delegate("world","set_ropemaker_workshop12_level_tax", cityId, v) end end
function M.saddler12_level_tax(cityId, v) if v==nil then return delegate("world","saddler12_level_tax", cityId) else return delegate("world","set_saddler12_level_tax", cityId, v) end end
function M.school12_level_tax(cityId, v) if v==nil then return delegate("world","school12_level_tax", cityId) else return delegate("world","set_school12_level_tax", cityId, v) end end
function M.schoolhouse12_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse12_level_tax", cityId) else return delegate("world","set_schoolhouse12_level_tax", cityId, v) end end
function M.sentry_tower12_level_tax(cityId, v) if v==nil then return delegate("world","sentry_tower12_level_tax", cityId) else return delegate("world","set_sentry_tower12_level_tax", cityId, v) end end
function M.stables12_level_tax(cityId, v) if v==nil then return delegate("world","stables12_level_tax", cityId) else return delegate("world","set_stables12_level_tax", cityId, v) end end
function M.stonecutter12_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter12_level_tax", cityId) else return delegate("world","set_stonecutter12_level_tax", cityId, v) end end
function M.tailor12_level_tax(cityId, v) if v==nil then return delegate("world","tailor12_level_tax", cityId) else return delegate("world","set_tailor12_level_tax", cityId, v) end end
function M.tannery12_level_tax(cityId, v) if v==nil then return delegate("world","tannery12_level_tax", cityId) else return delegate("world","set_tannery12_level_tax", cityId, v) end end
function M.tavern12_level_tax(cityId, v) if v==nil then return delegate("world","tavern12_level_tax", cityId) else return delegate("world","set_tavern12_level_tax", cityId, v) end end
function M.thieves_guild12_level_tax(cityId, v) if v==nil then return delegate("world","thieves_guild12_level_tax", cityId) else return delegate("world","set_thieves_guild12_level_tax", cityId, v) end end
function M.toolmaker12_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker12_level_tax", cityId) else return delegate("world","set_toolmaker12_level_tax", cityId, v) end end
function M.tower12_level_tax(cityId, v) if v==nil then return delegate("world","tower12_level_tax", cityId) else return delegate("world","set_tower12_level_tax", cityId, v) end end
function M.turner12_level_tax(cityId, v) if v==nil then return delegate("world","turner12_level_tax", cityId) else return delegate("world","set_turner12_level_tax", cityId, v) end end
function M.university13_level_tax(cityId, v) if v==nil then return delegate("world","university13_level_tax", cityId) else return delegate("world","set_university13_level_tax", cityId, v) end end
function M.university_hall12_level_tax(cityId, v) if v==nil then return delegate("world","university_hall12_level_tax", cityId) else return delegate("world","set_university_hall12_level_tax", cityId, v) end end
function M.vineyard12_level_tax(cityId, v) if v==nil then return delegate("world","vineyard12_level_tax", cityId) else return delegate("world","set_vineyard12_level_tax", cityId, v) end end
function M.vintner12_level_tax(cityId, v) if v==nil then return delegate("world","vintner12_level_tax", cityId) else return delegate("world","set_vintner12_level_tax", cityId, v) end end
function M.wall13_level_tax(cityId, v) if v==nil then return delegate("world","wall13_level_tax", cityId) else return delegate("world","set_wall13_level_tax", cityId, v) end end
function M.warehouse12_level_tax(cityId, v) if v==nil then return delegate("world","warehouse12_level_tax", cityId) else return delegate("world","set_warehouse12_level_tax", cityId, v) end end
function M.weaving_mill12_level_tax(cityId, v) if v==nil then return delegate("world","weaving_mill12_level_tax", cityId) else return delegate("world","set_weaving_mill12_level_tax", cityId, v) end end
function M.well12_level_tax(cityId, v) if v==nil then return delegate("world","well12_level_tax", cityId) else return delegate("world","set_well12_level_tax", cityId, v) end end
function M.armorer12_level_tax(cityId, v) if v==nil then return delegate("world","armorer12_level_tax", cityId) else return delegate("world","set_armorer12_level_tax", cityId, v) end end
function M.baker12_level_tax(cityId, v) if v==nil then return delegate("world","baker12_level_tax", cityId) else return delegate("world","set_baker12_level_tax", cityId, v) end end
function M.barber12_level_tax(cityId, v) if v==nil then return delegate("world","barber12_level_tax", cityId) else return delegate("world","set_barber12_level_tax", cityId, v) end end
function M.bathhouse12_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse12_level_tax", cityId) else return delegate("world","set_bathhouse12_level_tax", cityId, v) end end
function M.bowyer12_level_tax(cityId, v) if v==nil then return delegate("world","bowyer12_level_tax", cityId) else return delegate("world","set_bowyer12_level_tax", cityId, v) end end
function M.brewmaster12_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster12_level_tax", cityId) else return delegate("world","set_brewmaster12_level_tax", cityId, v) end end
function M.brickmaker12_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker12_level_tax", cityId) else return delegate("world","set_brickmaker12_level_tax", cityId, v) end end
function M.bridge12_level_tax(cityId, v) if v==nil then return delegate("world","bridge12_level_tax", cityId) else return delegate("world","set_bridge12_level_tax", cityId, v) end end
function M.brothel12_level_tax(cityId, v) if v==nil then return delegate("world","brothel12_level_tax", cityId) else return delegate("world","set_brothel12_level_tax", cityId, v) end end
function M.butcher12_level_tax(cityId, v) if v==nil then return delegate("world","butcher12_level_tax", cityId) else return delegate("world","set_butcher12_level_tax", cityId, v) end end
function M.castle12_level_tax(cityId, v) if v==nil then return delegate("world","castle12_level_tax", cityId) else return delegate("world","set_castle12_level_tax", cityId, v) end end
function M.cathedral12_level_tax(cityId, v) if v==nil then return delegate("world","cathedral12_level_tax", cityId) else return delegate("world","set_cathedral12_level_tax", cityId, v) end end
function M.chandler13_level_tax(cityId, v) if v==nil then return delegate("world","chandler13_level_tax", cityId) else return delegate("world","set_chandler13_level_tax", cityId, v) end end
function M.chapel12_level_tax(cityId, v) if v==nil then return delegate("world","chapel12_level_tax", cityId) else return delegate("world","set_chapel12_level_tax", cityId, v) end end
function M.church13_level_tax(cityId, v) if v==nil then return delegate("world","church13_level_tax", cityId) else return delegate("world","set_church13_level_tax", cityId, v) end end
function M.cobbler13_level_tax(cityId, v) if v==nil then return delegate("world","cobbler13_level_tax", cityId) else return delegate("world","set_cobbler13_level_tax", cityId, v) end end
function M.contor13_level_tax(cityId, v) if v==nil then return delegate("world","contor13_level_tax", cityId) else return delegate("world","set_contor13_level_tax", cityId, v) end end
function M.cook13_level_tax(cityId, v) if v==nil then return delegate("world","cook13_level_tax", cityId) else return delegate("world","set_cook13_level_tax", cityId, v) end end
function M.cooper13_level_tax(cityId, v) if v==nil then return delegate("world","cooper13_level_tax", cityId) else return delegate("world","set_cooper13_level_tax", cityId, v) end end
function M.courthouse13_level_tax(cityId, v) if v==nil then return delegate("world","courthouse13_level_tax", cityId) else return delegate("world","set_courthouse13_level_tax", cityId, v) end end
function M.dairy13_level_tax(cityId, v) if v==nil then return delegate("world","dairy13_level_tax", cityId) else return delegate("world","set_dairy13_level_tax", cityId, v) end end
function M.dice_house13_level_tax(cityId, v) if v==nil then return delegate("world","dice_house13_level_tax", cityId) else return delegate("world","set_dice_house13_level_tax", cityId, v) end end
function M.distiller13_level_tax(cityId, v) if v==nil then return delegate("world","distiller13_level_tax", cityId) else return delegate("world","set_distiller13_level_tax", cityId, v) end end
function M.dyer13_level_tax(cityId, v) if v==nil then return delegate("world","dyer13_level_tax", cityId) else return delegate("world","set_dyer13_level_tax", cityId, v) end end
function M.fishery13_level_tax(cityId, v) if v==nil then return delegate("world","fishery13_level_tax", cityId) else return delegate("world","set_fishery13_level_tax", cityId, v) end end
function M.forum13_level_tax(cityId, v) if v==nil then return delegate("world","forum13_level_tax", cityId) else return delegate("world","set_forum13_level_tax", cityId, v) end end
function M.fowler13_level_tax(cityId, v) if v==nil then return delegate("world","fowler13_level_tax", cityId) else return delegate("world","set_fowler13_level_tax", cityId, v) end end
function M.furrier13_level_tax(cityId, v) if v==nil then return delegate("world","furrier13_level_tax", cityId) else return delegate("world","set_furrier13_level_tax", cityId, v) end end
function M.garrison13_level_tax(cityId, v) if v==nil then return delegate("world","garrison13_level_tax", cityId) else return delegate("world","set_garrison13_level_tax", cityId, v) end end
function M.gates13_level_tax(cityId, v) if v==nil then return delegate("world","gates13_level_tax", cityId) else return delegate("world","set_gates13_level_tax", cityId, v) end end
function M.glassblower13_level_tax(cityId, v) if v==nil then return delegate("world","glassblower13_level_tax", cityId) else return delegate("world","set_glassblower13_level_tax", cityId, v) end end
function M.goldbeater13_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater13_level_tax", cityId) else return delegate("world","set_goldbeater13_level_tax", cityId, v) end end
function M.goldsmith13_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith13_level_tax", cityId) else return delegate("world","set_goldsmith13_level_tax", cityId, v) end end
function M.granary13_level_tax(cityId, v) if v==nil then return delegate("world","granary13_level_tax", cityId) else return delegate("world","set_granary13_level_tax", cityId, v) end end
function M.guardhouse13_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse13_level_tax", cityId) else return delegate("world","set_guardhouse13_level_tax", cityId, v) end end
function M.guild_house13_level_tax(cityId, v) if v==nil then return delegate("world","guild_house13_level_tax", cityId) else return delegate("world","set_guild_house13_level_tax", cityId, v) end end
function M.harbor13_level_tax(cityId, v) if v==nil then return delegate("world","harbor13_level_tax", cityId) else return delegate("world","set_harbor13_level_tax", cityId, v) end end
function M.harbor_dock13_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock13_level_tax", cityId) else return delegate("world","set_harbor_dock13_level_tax", cityId, v) end end
function M.harbor_walls13_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls13_level_tax", cityId) else return delegate("world","set_harbor_walls13_level_tax", cityId, v) end end
function M.herb_garden13_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden13_level_tax", cityId) else return delegate("world","set_herb_garden13_level_tax", cityId, v) end end
function M.hospital13_level_tax(cityId, v) if v==nil then return delegate("world","hospital13_level_tax", cityId) else return delegate("world","set_hospital13_level_tax", cityId, v) end end
function M.house13_level_tax(cityId, v) if v==nil then return delegate("world","house13_level_tax", cityId) else return delegate("world","set_house13_level_tax", cityId, v) end end
function M.jeweler13_level_tax(cityId, v) if v==nil then return delegate("world","jeweler13_level_tax", cityId) else return delegate("world","set_jeweler13_level_tax", cityId, v) end end
function M.library13_level_tax(cityId, v) if v==nil then return delegate("world","library13_level_tax", cityId) else return delegate("world","set_library13_level_tax", cityId, v) end end
function M.library_hall13_level_tax(cityId, v) if v==nil then return delegate("world","library_hall13_level_tax", cityId) else return delegate("world","set_library_hall13_level_tax", cityId, v) end end
function M.market13_level_tax(cityId, v) if v==nil then return delegate("world","market13_level_tax", cityId) else return delegate("world","set_market13_level_tax", cityId, v) end end
function M.miller13_level_tax(cityId, v) if v==nil then return delegate("world","miller13_level_tax", cityId) else return delegate("world","set_miller13_level_tax", cityId, v) end end
function M.mine13_level_tax(cityId, v) if v==nil then return delegate("world","mine13_level_tax", cityId) else return delegate("world","set_mine13_level_tax", cityId, v) end end
function M.mint13_level_tax(cityId, v) if v==nil then return delegate("world","mint13_level_tax", cityId) else return delegate("world","set_mint13_level_tax", cityId, v) end end
function M.monastery13_level_tax(cityId, v) if v==nil then return delegate("world","monastery13_level_tax", cityId) else return delegate("world","set_monastery13_level_tax", cityId, v) end end
function M.papermill13_level_tax(cityId, v) if v==nil then return delegate("world","papermill13_level_tax", cityId) else return delegate("world","set_papermill13_level_tax", cityId, v) end end
function M.perfumer13_level_tax(cityId, v) if v==nil then return delegate("world","perfumer13_level_tax", cityId) else return delegate("world","set_perfumer13_level_tax", cityId, v) end end
function M.potter13_level_tax(cityId, v) if v==nil then return delegate("world","potter13_level_tax", cityId) else return delegate("world","set_potter13_level_tax", cityId, v) end end
function M.pottery13_level_tax(cityId, v) if v==nil then return delegate("world","pottery13_level_tax", cityId) else return delegate("world","set_pottery13_level_tax", cityId, v) end end
function M.printing_house13_level_tax(cityId, v) if v==nil then return delegate("world","printing_house13_level_tax", cityId) else return delegate("world","set_printing_house13_level_tax", cityId, v) end end
function M.ropemaker13_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker13_level_tax", cityId) else return delegate("world","set_ropemaker13_level_tax", cityId, v) end end
function M.ropemaker_workshop13_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_workshop13_level_tax", cityId) else return delegate("world","set_ropemaker_workshop13_level_tax", cityId, v) end end
function M.saddler13_level_tax(cityId, v) if v==nil then return delegate("world","saddler13_level_tax", cityId) else return delegate("world","set_saddler13_level_tax", cityId, v) end end
function M.school13_level_tax(cityId, v) if v==nil then return delegate("world","school13_level_tax", cityId) else return delegate("world","set_school13_level_tax", cityId, v) end end
function M.schoolhouse13_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse13_level_tax", cityId) else return delegate("world","set_schoolhouse13_level_tax", cityId, v) end end
function M.sentry_tower13_level_tax(cityId, v) if v==nil then return delegate("world","sentry_tower13_level_tax", cityId) else return delegate("world","set_sentry_tower13_level_tax", cityId, v) end end
function M.stables13_level_tax(cityId, v) if v==nil then return delegate("world","stables13_level_tax", cityId) else return delegate("world","set_stables13_level_tax", cityId, v) end end
function M.stonecutter13_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter13_level_tax", cityId) else return delegate("world","set_stonecutter13_level_tax", cityId, v) end end
function M.tailor13_level_tax(cityId, v) if v==nil then return delegate("world","tailor13_level_tax", cityId) else return delegate("world","set_tailor13_level_tax", cityId, v) end end
function M.tannery13_level_tax(cityId, v) if v==nil then return delegate("world","tannery13_level_tax", cityId) else return delegate("world","set_tannery13_level_tax", cityId, v) end end
function M.tavern13_level_tax(cityId, v) if v==nil then return delegate("world","tavern13_level_tax", cityId) else return delegate("world","set_tavern13_level_tax", cityId, v) end end
function M.thieves_guild13_level_tax(cityId, v) if v==nil then return delegate("world","thieves_guild13_level_tax", cityId) else return delegate("world","set_thieves_guild13_level_tax", cityId, v) end end
function M.toolmaker13_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker13_level_tax", cityId) else return delegate("world","set_toolmaker13_level_tax", cityId, v) end end
function M.tower13_level_tax(cityId, v) if v==nil then return delegate("world","tower13_level_tax", cityId) else return delegate("world","set_tower13_level_tax", cityId, v) end end
function M.turner13_level_tax(cityId, v) if v==nil then return delegate("world","turner13_level_tax", cityId) else return delegate("world","set_turner13_level_tax", cityId, v) end end
function M.university14_level_tax(cityId, v) if v==nil then return delegate("world","university14_level_tax", cityId) else return delegate("world","set_university14_level_tax", cityId, v) end end
function M.university_hall13_level_tax(cityId, v) if v==nil then return delegate("world","university_hall13_level_tax", cityId) else return delegate("world","set_university_hall13_level_tax", cityId, v) end end
function M.vineyard13_level_tax(cityId, v) if v==nil then return delegate("world","vineyard13_level_tax", cityId) else return delegate("world","set_vineyard13_level_tax", cityId, v) end end
function M.vintner13_level_tax(cityId, v) if v==nil then return delegate("world","vintner13_level_tax", cityId) else return delegate("world","set_vintner13_level_tax", cityId, v) end end
function M.wall14_level_tax(cityId, v) if v==nil then return delegate("world","wall14_level_tax", cityId) else return delegate("world","set_wall14_level_tax", cityId, v) end end
function M.warehouse13_level_tax(cityId, v) if v==nil then return delegate("world","warehouse13_level_tax", cityId) else return delegate("world","set_warehouse13_level_tax", cityId, v) end end
function M.weaving_mill13_level_tax(cityId, v) if v==nil then return delegate("world","weaving_mill13_level_tax", cityId) else return delegate("world","set_weaving_mill13_level_tax", cityId, v) end end
function M.well13_level_tax(cityId, v) if v==nil then return delegate("world","well13_level_tax", cityId) else return delegate("world","set_well13_level_tax", cityId, v) end end
function M.armorer13_level_tax(cityId, v) if v==nil then return delegate("world","armorer13_level_tax", cityId) else return delegate("world","set_armorer13_level_tax", cityId, v) end end
function M.baker13_level_tax(cityId, v) if v==nil then return delegate("world","baker13_level_tax", cityId) else return delegate("world","set_baker13_level_tax", cityId, v) end end
function M.barber13_level_tax(cityId, v) if v==nil then return delegate("world","barber13_level_tax", cityId) else return delegate("world","set_barber13_level_tax", cityId, v) end end
function M.bathhouse13_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse13_level_tax", cityId) else return delegate("world","set_bathhouse13_level_tax", cityId, v) end end
function M.bowyer13_level_tax(cityId, v) if v==nil then return delegate("world","bowyer13_level_tax", cityId) else return delegate("world","set_bowyer13_level_tax", cityId, v) end end
function M.brewmaster13_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster13_level_tax", cityId) else return delegate("world","set_brewmaster13_level_tax", cityId, v) end end
function M.brickmaker13_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker13_level_tax", cityId) else return delegate("world","set_brickmaker13_level_tax", cityId, v) end end
function M.bridge13_level_tax(cityId, v) if v==nil then return delegate("world","bridge13_level_tax", cityId) else return delegate("world","set_bridge13_level_tax", cityId, v) end end
function M.brothel13_level_tax(cityId, v) if v==nil then return delegate("world","brothel13_level_tax", cityId) else return delegate("world","set_brothel13_level_tax", cityId, v) end end
function M.butcher13_level_tax(cityId, v) if v==nil then return delegate("world","butcher13_level_tax", cityId) else return delegate("world","set_butcher13_level_tax", cityId, v) end end
function M.candlemaker13_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker13_level_tax", cityId) else return delegate("world","set_candlemaker13_level_tax", cityId, v) end end
function M.carpenter13_level_tax(cityId, v) if v==nil then return delegate("world","carpenter13_level_tax", cityId) else return delegate("world","set_carpenter13_level_tax", cityId, v) end end
function M.cartwright13_level_tax(cityId, v) if v==nil then return delegate("world","cartwright13_level_tax", cityId) else return delegate("world","set_cartwright13_level_tax", cityId, v) end end
function M.castle13_level_tax(cityId, v) if v==nil then return delegate("world","castle13_level_tax", cityId) else return delegate("world","set_castle13_level_tax", cityId, v) end end
function M.cathedral13_level_tax(cityId, v) if v==nil then return delegate("world","cathedral13_level_tax", cityId) else return delegate("world","set_cathedral13_level_tax", cityId, v) end end
function M.chapel13_level_tax(cityId, v) if v==nil then return delegate("world","chapel13_level_tax", cityId) else return delegate("world","set_chapel13_level_tax", cityId, v) end end
function M.charcoal13_level_tax(cityId, v) if v==nil then return delegate("world","charcoal13_level_tax", cityId) else return delegate("world","set_charcoal13_level_tax", cityId, v) end end
function M.church14_level_tax(cityId, v) if v==nil then return delegate("world","church14_level_tax", cityId) else return delegate("world","set_church14_level_tax", cityId, v) end end
function M.cobbler14_level_tax(cityId, v) if v==nil then return delegate("world","cobbler14_level_tax", cityId) else return delegate("world","set_cobbler14_level_tax", cityId, v) end end
function M.contor14_level_tax(cityId, v) if v==nil then return delegate("world","contor14_level_tax", cityId) else return delegate("world","set_contor14_level_tax", cityId, v) end end
function M.cook14_level_tax(cityId, v) if v==nil then return delegate("world","cook14_level_tax", cityId) else return delegate("world","set_cook14_level_tax", cityId, v) end end
function M.cooper14_level_tax(cityId, v) if v==nil then return delegate("world","cooper14_level_tax", cityId) else return delegate("world","set_cooper14_level_tax", cityId, v) end end
function M.courthouse14_level_tax(cityId, v) if v==nil then return delegate("world","courthouse14_level_tax", cityId) else return delegate("world","set_courthouse14_level_tax", cityId, v) end end
function M.dairy14_level_tax(cityId, v) if v==nil then return delegate("world","dairy14_level_tax", cityId) else return delegate("world","set_dairy14_level_tax", cityId, v) end end
function M.dice_house14_level_tax(cityId, v) if v==nil then return delegate("world","dice_house14_level_tax", cityId) else return delegate("world","set_dice_house14_level_tax", cityId, v) end end
function M.distiller14_level_tax(cityId, v) if v==nil then return delegate("world","distiller14_level_tax", cityId) else return delegate("world","set_distiller14_level_tax", cityId, v) end end
function M.dyer14_level_tax(cityId, v) if v==nil then return delegate("world","dyer14_level_tax", cityId) else return delegate("world","set_dyer14_level_tax", cityId, v) end end
function M.fishery14_level_tax(cityId, v) if v==nil then return delegate("world","fishery14_level_tax", cityId) else return delegate("world","set_fishery14_level_tax", cityId, v) end end
function M.forum14_level_tax(cityId, v) if v==nil then return delegate("world","forum14_level_tax", cityId) else return delegate("world","set_forum14_level_tax", cityId, v) end end
function M.fowler14_level_tax(cityId, v) if v==nil then return delegate("world","fowler14_level_tax", cityId) else return delegate("world","set_fowler14_level_tax", cityId, v) end end
function M.furrier14_level_tax(cityId, v) if v==nil then return delegate("world","furrier14_level_tax", cityId) else return delegate("world","set_furrier14_level_tax", cityId, v) end end
function M.garrison14_level_tax(cityId, v) if v==nil then return delegate("world","garrison14_level_tax", cityId) else return delegate("world","set_garrison14_level_tax", cityId, v) end end
function M.gates14_level_tax(cityId, v) if v==nil then return delegate("world","gates14_level_tax", cityId) else return delegate("world","set_gates14_level_tax", cityId, v) end end
function M.glassblower14_level_tax(cityId, v) if v==nil then return delegate("world","glassblower14_level_tax", cityId) else return delegate("world","set_glassblower14_level_tax", cityId, v) end end
function M.goldbeater14_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater14_level_tax", cityId) else return delegate("world","set_goldbeater14_level_tax", cityId, v) end end
function M.goldsmith14_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith14_level_tax", cityId) else return delegate("world","set_goldsmith14_level_tax", cityId, v) end end
function M.granary14_level_tax(cityId, v) if v==nil then return delegate("world","granary14_level_tax", cityId) else return delegate("world","set_granary14_level_tax", cityId, v) end end
function M.guardhouse14_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse14_level_tax", cityId) else return delegate("world","set_guardhouse14_level_tax", cityId, v) end end
function M.guild_house14_level_tax(cityId, v) if v==nil then return delegate("world","guild_house14_level_tax", cityId) else return delegate("world","set_guild_house14_level_tax", cityId, v) end end
function M.harbor14_level_tax(cityId, v) if v==nil then return delegate("world","harbor14_level_tax", cityId) else return delegate("world","set_harbor14_level_tax", cityId, v) end end
function M.harbor_dock14_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock14_level_tax", cityId) else return delegate("world","set_harbor_dock14_level_tax", cityId, v) end end
function M.harbor_walls14_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls14_level_tax", cityId) else return delegate("world","set_harbor_walls14_level_tax", cityId, v) end end
function M.herb_garden14_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden14_level_tax", cityId) else return delegate("world","set_herb_garden14_level_tax", cityId, v) end end
function M.hospital14_level_tax(cityId, v) if v==nil then return delegate("world","hospital14_level_tax", cityId) else return delegate("world","set_hospital14_level_tax", cityId, v) end end
function M.house14_level_tax(cityId, v) if v==nil then return delegate("world","house14_level_tax", cityId) else return delegate("world","set_house14_level_tax", cityId, v) end end
function M.jeweler14_level_tax(cityId, v) if v==nil then return delegate("world","jeweler14_level_tax", cityId) else return delegate("world","set_jeweler14_level_tax", cityId, v) end end
function M.library14_level_tax(cityId, v) if v==nil then return delegate("world","library14_level_tax", cityId) else return delegate("world","set_library14_level_tax", cityId, v) end end
function M.library_hall14_level_tax(cityId, v) if v==nil then return delegate("world","library_hall14_level_tax", cityId) else return delegate("world","set_library_hall14_level_tax", cityId, v) end end
function M.market14_level_tax(cityId, v) if v==nil then return delegate("world","market14_level_tax", cityId) else return delegate("world","set_market14_level_tax", cityId, v) end end
function M.miller14_level_tax(cityId, v) if v==nil then return delegate("world","miller14_level_tax", cityId) else return delegate("world","set_miller14_level_tax", cityId, v) end end
function M.mine14_level_tax(cityId, v) if v==nil then return delegate("world","mine14_level_tax", cityId) else return delegate("world","set_mine14_level_tax", cityId, v) end end
function M.mint14_level_tax(cityId, v) if v==nil then return delegate("world","mint14_level_tax", cityId) else return delegate("world","set_mint14_level_tax", cityId, v) end end
function M.monastery14_level_tax(cityId, v) if v==nil then return delegate("world","monastery14_level_tax", cityId) else return delegate("world","set_monastery14_level_tax", cityId, v) end end
function M.papermill14_level_tax(cityId, v) if v==nil then return delegate("world","papermill14_level_tax", cityId) else return delegate("world","set_papermill14_level_tax", cityId, v) end end
function M.perfumer14_level_tax(cityId, v) if v==nil then return delegate("world","perfumer14_level_tax", cityId) else return delegate("world","set_perfumer14_level_tax", cityId, v) end end
function M.potter14_level_tax(cityId, v) if v==nil then return delegate("world","potter14_level_tax", cityId) else return delegate("world","set_potter14_level_tax", cityId, v) end end
function M.pottery14_level_tax(cityId, v) if v==nil then return delegate("world","pottery14_level_tax", cityId) else return delegate("world","set_pottery14_level_tax", cityId, v) end end
function M.printing_house14_level_tax(cityId, v) if v==nil then return delegate("world","printing_house14_level_tax", cityId) else return delegate("world","set_printing_house14_level_tax", cityId, v) end end
function M.ropemaker14_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker14_level_tax", cityId) else return delegate("world","set_ropemaker14_level_tax", cityId, v) end end
function M.ropemaker_workshop14_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_workshop14_level_tax", cityId) else return delegate("world","set_ropemaker_workshop14_level_tax", cityId, v) end end
function M.saddler14_level_tax(cityId, v) if v==nil then return delegate("world","saddler14_level_tax", cityId) else return delegate("world","set_saddler14_level_tax", cityId, v) end end
function M.school14_level_tax(cityId, v) if v==nil then return delegate("world","school14_level_tax", cityId) else return delegate("world","set_school14_level_tax", cityId, v) end end
function M.schoolhouse14_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse14_level_tax", cityId) else return delegate("world","set_schoolhouse14_level_tax", cityId, v) end end
function M.sentry_tower14_level_tax(cityId, v) if v==nil then return delegate("world","sentry_tower14_level_tax", cityId) else return delegate("world","set_sentry_tower14_level_tax", cityId, v) end end
function M.stables14_level_tax(cityId, v) if v==nil then return delegate("world","stables14_level_tax", cityId) else return delegate("world","set_stables14_level_tax", cityId, v) end end
function M.stonecutter14_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter14_level_tax", cityId) else return delegate("world","set_stonecutter14_level_tax", cityId, v) end end
function M.tailor14_level_tax(cityId, v) if v==nil then return delegate("world","tailor14_level_tax", cityId) else return delegate("world","set_tailor14_level_tax", cityId, v) end end
function M.tannery14_level_tax(cityId, v) if v==nil then return delegate("world","tannery14_level_tax", cityId) else return delegate("world","set_tannery14_level_tax", cityId, v) end end
function M.tavern14_level_tax(cityId, v) if v==nil then return delegate("world","tavern14_level_tax", cityId) else return delegate("world","set_tavern14_level_tax", cityId, v) end end
function M.thieves_guild14_level_tax(cityId, v) if v==nil then return delegate("world","thieves_guild14_level_tax", cityId) else return delegate("world","set_thieves_guild14_level_tax", cityId, v) end end
function M.toolmaker14_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker14_level_tax", cityId) else return delegate("world","set_toolmaker14_level_tax", cityId, v) end end
function M.tower14_level_tax(cityId, v) if v==nil then return delegate("world","tower14_level_tax", cityId) else return delegate("world","set_tower14_level_tax", cityId, v) end end
function M.turner14_level_tax(cityId, v) if v==nil then return delegate("world","turner14_level_tax", cityId) else return delegate("world","set_turner14_level_tax", cityId, v) end end
function M.university15_level_tax(cityId, v) if v==nil then return delegate("world","university15_level_tax", cityId) else return delegate("world","set_university15_level_tax", cityId, v) end end
function M.university_hall14_level_tax(cityId, v) if v==nil then return delegate("world","university_hall14_level_tax", cityId) else return delegate("world","set_university_hall14_level_tax", cityId, v) end end
function M.vineyard14_level_tax(cityId, v) if v==nil then return delegate("world","vineyard14_level_tax", cityId) else return delegate("world","set_vineyard14_level_tax", cityId, v) end end
function M.vintner14_level_tax(cityId, v) if v==nil then return delegate("world","vintner14_level_tax", cityId) else return delegate("world","set_vintner14_level_tax", cityId, v) end end
function M.wall15_level_tax(cityId, v) if v==nil then return delegate("world","wall15_level_tax", cityId) else return delegate("world","set_wall15_level_tax", cityId, v) end end
function M.warehouse15_level_tax(cityId, v) if v==nil then return delegate("world","warehouse15_level_tax", cityId) else return delegate("world","set_warehouse15_level_tax", cityId, v) end end
function M.weaving_mill15_level_tax(cityId, v) if v==nil then return delegate("world","weaving_mill15_level_tax", cityId) else return delegate("world","set_weaving_mill15_level_tax", cityId, v) end end
function M.well15_level_tax(cityId, v) if v==nil then return delegate("world","well15_level_tax", cityId) else return delegate("world","set_well15_level_tax", cityId, v) end end
function M.town_hall16_level_tax(cityId, v) if v==nil then return delegate("world","town_hall16_level_tax", cityId) else return delegate("world","set_town_hall16_level_tax", cityId, v) end end
function M.apothecary15_level_tax(cityId, v) if v==nil then return delegate("world","apothecary15_level_tax", cityId) else return delegate("world","set_apothecary15_level_tax", cityId, v) end end
function M.armorer15_level_tax(cityId, v) if v==nil then return delegate("world","armorer15_level_tax", cityId) else return delegate("world","set_armorer15_level_tax", cityId, v) end end
function M.baker15_level_tax(cityId, v) if v==nil then return delegate("world","baker15_level_tax", cityId) else return delegate("world","set_baker15_level_tax", cityId, v) end end
function M.barber15_level_tax(cityId, v) if v==nil then return delegate("world","barber15_level_tax", cityId) else return delegate("world","set_barber15_level_tax", cityId, v) end end
function M.bathhouse15_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse15_level_tax", cityId) else return delegate("world","set_bathhouse15_level_tax", cityId, v) end end
function M.bowyer15_level_tax(cityId, v) if v==nil then return delegate("world","bowyer15_level_tax", cityId) else return delegate("world","set_bowyer15_level_tax", cityId, v) end end
function M.brewmaster15_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster15_level_tax", cityId) else return delegate("world","set_brewmaster15_level_tax", cityId, v) end end
function M.brickmaker15_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker15_level_tax", cityId) else return delegate("world","set_brickmaker15_level_tax", cityId, v) end end
function M.bridge15_level_tax(cityId, v) if v==nil then return delegate("world","bridge15_level_tax", cityId) else return delegate("world","set_bridge15_level_tax", cityId, v) end end
function M.brothel15_level_tax(cityId, v) if v==nil then return delegate("world","brothel15_level_tax", cityId) else return delegate("world","set_brothel15_level_tax", cityId, v) end end
function M.butcher15_level_tax(cityId, v) if v==nil then return delegate("world","butcher15_level_tax", cityId) else return delegate("world","set_butcher15_level_tax", cityId, v) end end
function M.candlemaker15_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker15_level_tax", cityId) else return delegate("world","set_candlemaker15_level_tax", cityId, v) end end
function M.carpenter15_level_tax(cityId, v) if v==nil then return delegate("world","carpenter15_level_tax", cityId) else return delegate("world","set_carpenter15_level_tax", cityId, v) end end
function M.cartwright15_level_tax(cityId, v) if v==nil then return delegate("world","cartwright15_level_tax", cityId) else return delegate("world","set_cartwright15_level_tax", cityId, v) end end
function M.castle15_level_tax(cityId, v) if v==nil then return delegate("world","castle15_level_tax", cityId) else return delegate("world","set_castle15_level_tax", cityId, v) end end
function M.cathedral15_level_tax(cityId, v) if v==nil then return delegate("world","cathedral15_level_tax", cityId) else return delegate("world","set_cathedral15_level_tax", cityId, v) end end
function M.chandler15_level_tax(cityId, v) if v==nil then return delegate("world","chandler15_level_tax", cityId) else return delegate("world","set_chandler15_level_tax", cityId, v) end end
function M.chapel15_level_tax(cityId, v) if v==nil then return delegate("world","chapel15_level_tax", cityId) else return delegate("world","set_chapel15_level_tax", cityId, v) end end
function M.charcoal15_level_tax(cityId, v) if v==nil then return delegate("world","charcoal15_level_tax", cityId) else return delegate("world","set_charcoal15_level_tax", cityId, v) end end
function M.church15_level_tax(cityId, v) if v==nil then return delegate("world","church15_level_tax", cityId) else return delegate("world","set_church15_level_tax", cityId, v) end end
function M.cobbler15_level_tax(cityId, v) if v==nil then return delegate("world","cobbler15_level_tax", cityId) else return delegate("world","set_cobbler15_level_tax", cityId, v) end end
function M.contor15_level_tax(cityId, v) if v==nil then return delegate("world","contor15_level_tax", cityId) else return delegate("world","set_contor15_level_tax", cityId, v) end end
function M.cook15_level_tax(cityId, v) if v==nil then return delegate("world","cook15_level_tax", cityId) else return delegate("world","set_cook15_level_tax", cityId, v) end end
function M.cooper15_level_tax(cityId, v) if v==nil then return delegate("world","cooper15_level_tax", cityId) else return delegate("world","set_cooper15_level_tax", cityId, v) end end
function M.courthouse15_level_tax(cityId, v) if v==nil then return delegate("world","courthouse15_level_tax", cityId) else return delegate("world","set_courthouse15_level_tax", cityId, v) end end
function M.dairy15_level_tax(cityId, v) if v==nil then return delegate("world","dairy15_level_tax", cityId) else return delegate("world","set_dairy15_level_tax", cityId, v) end end
function M.dice_house15_level_tax(cityId, v) if v==nil then return delegate("world","dice_house15_level_tax", cityId) else return delegate("world","set_dice_house15_level_tax", cityId, v) end end
function M.distiller15_level_tax(cityId, v) if v==nil then return delegate("world","distiller15_level_tax", cityId) else return delegate("world","set_distiller15_level_tax", cityId, v) end end
function M.dyer15_level_tax(cityId, v) if v==nil then return delegate("world","dyer15_level_tax", cityId) else return delegate("world","set_dyer15_level_tax", cityId, v) end end
function M.fishery15_level_tax(cityId, v) if v==nil then return delegate("world","fishery15_level_tax", cityId) else return delegate("world","set_fishery15_level_tax", cityId, v) end end
function M.forum15_level_tax(cityId, v) if v==nil then return delegate("world","forum15_level_tax", cityId) else return delegate("world","set_forum15_level_tax", cityId, v) end end
function M.fowler15_level_tax(cityId, v) if v==nil then return delegate("world","fowler15_level_tax", cityId) else return delegate("world","set_fowler15_level_tax", cityId, v) end end
function M.furrier15_level_tax(cityId, v) if v==nil then return delegate("world","furrier15_level_tax", cityId) else return delegate("world","set_furrier15_level_tax", cityId, v) end end
function M.garrison15_level_tax(cityId, v) if v==nil then return delegate("world","garrison15_level_tax", cityId) else return delegate("world","set_garrison15_level_tax", cityId, v) end end
function M.gates15_level_tax(cityId, v) if v==nil then return delegate("world","gates15_level_tax", cityId) else return delegate("world","set_gates15_level_tax", cityId, v) end end
function M.glassblower15_level_tax(cityId, v) if v==nil then return delegate("world","glassblower15_level_tax", cityId) else return delegate("world","set_glassblower15_level_tax", cityId, v) end end
function M.goldbeater15_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater15_level_tax", cityId) else return delegate("world","set_goldbeater15_level_tax", cityId, v) end end
function M.goldsmith15_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith15_level_tax", cityId) else return delegate("world","set_goldsmith15_level_tax", cityId, v) end end
function M.granary15_level_tax(cityId, v) if v==nil then return delegate("world","granary15_level_tax", cityId) else return delegate("world","set_granary15_level_tax", cityId, v) end end
function M.guardhouse15_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse15_level_tax", cityId) else return delegate("world","set_guardhouse15_level_tax", cityId, v) end end
function M.guild_house15_level_tax(cityId, v) if v==nil then return delegate("world","guild_house15_level_tax", cityId) else return delegate("world","set_guild_house15_level_tax", cityId, v) end end
function M.harbor15_level_tax(cityId, v) if v==nil then return delegate("world","harbor15_level_tax", cityId) else return delegate("world","set_harbor15_level_tax", cityId, v) end end
function M.harbor_dock15_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock15_level_tax", cityId) else return delegate("world","set_harbor_dock15_level_tax", cityId, v) end end
function M.harbor_walls15_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls15_level_tax", cityId) else return delegate("world","set_harbor_walls15_level_tax", cityId, v) end end
function M.herb_garden15_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden15_level_tax", cityId) else return delegate("world","set_herb_garden15_level_tax", cityId, v) end end
function M.hospital15_level_tax(cityId, v) if v==nil then return delegate("world","hospital15_level_tax", cityId) else return delegate("world","set_hospital15_level_tax", cityId, v) end end
function M.house15_level_tax(cityId, v) if v==nil then return delegate("world","house15_level_tax", cityId) else return delegate("world","set_house15_level_tax", cityId, v) end end
function M.jeweler15_level_tax(cityId, v) if v==nil then return delegate("world","jeweler15_level_tax", cityId) else return delegate("world","set_jeweler15_level_tax", cityId, v) end end
function M.library15_level_tax(cityId, v) if v==nil then return delegate("world","library15_level_tax", cityId) else return delegate("world","set_library15_level_tax", cityId, v) end end
function M.library_hall15_level_tax(cityId, v) if v==nil then return delegate("world","library_hall15_level_tax", cityId) else return delegate("world","set_library_hall15_level_tax", cityId, v) end end
function M.market15_level_tax(cityId, v) if v==nil then return delegate("world","market15_level_tax", cityId) else return delegate("world","set_market15_level_tax", cityId, v) end end
function M.miller15_level_tax(cityId, v) if v==nil then return delegate("world","miller15_level_tax", cityId) else return delegate("world","set_miller15_level_tax", cityId, v) end end
function M.mine15_level_tax(cityId, v) if v==nil then return delegate("world","mine15_level_tax", cityId) else return delegate("world","set_mine15_level_tax", cityId, v) end end
function M.mint15_level_tax(cityId, v) if v==nil then return delegate("world","mint15_level_tax", cityId) else return delegate("world","set_mint15_level_tax", cityId, v) end end
function M.monastery15_level_tax(cityId, v) if v==nil then return delegate("world","monastery15_level_tax", cityId) else return delegate("world","set_monastery15_level_tax", cityId, v) end end
function M.papermill15_level_tax(cityId, v) if v==nil then return delegate("world","papermill15_level_tax", cityId) else return delegate("world","set_papermill15_level_tax", cityId, v) end end
function M.perfumer15_level_tax(cityId, v) if v==nil then return delegate("world","perfumer15_level_tax", cityId) else return delegate("world","set_perfumer15_level_tax", cityId, v) end end
function M.potter15_level_tax(cityId, v) if v==nil then return delegate("world","potter15_level_tax", cityId) else return delegate("world","set_potter15_level_tax", cityId, v) end end
function M.pottery15_level_tax(cityId, v) if v==nil then return delegate("world","pottery15_level_tax", cityId) else return delegate("world","set_pottery15_level_tax", cityId, v) end end
function M.printing_house15_level_tax(cityId, v) if v==nil then return delegate("world","printing_house15_level_tax", cityId) else return delegate("world","set_printing_house15_level_tax", cityId, v) end end
function M.ropemaker15_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker15_level_tax", cityId) else return delegate("world","set_ropemaker15_level_tax", cityId, v) end end
function M.ropemaker_workshop15_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_workshop15_level_tax", cityId) else return delegate("world","set_ropemaker_workshop15_level_tax", cityId, v) end end
function M.saddler15_level_tax(cityId, v) if v==nil then return delegate("world","saddler15_level_tax", cityId) else return delegate("world","set_saddler15_level_tax", cityId, v) end end
function M.school15_level_tax(cityId, v) if v==nil then return delegate("world","school15_level_tax", cityId) else return delegate("world","set_school15_level_tax", cityId, v) end end
function M.schoolhouse15_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse15_level_tax", cityId) else return delegate("world","set_schoolhouse15_level_tax", cityId, v) end end
function M.sentry_tower15_level_tax(cityId, v) if v==nil then return delegate("world","sentry_tower15_level_tax", cityId) else return delegate("world","set_sentry_tower15_level_tax", cityId, v) end end
function M.stables15_level_tax(cityId, v) if v==nil then return delegate("world","stables15_level_tax", cityId) else return delegate("world","set_stables15_level_tax", cityId, v) end end
function M.stonecutter15_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter15_level_tax", cityId) else return delegate("world","set_stonecutter15_level_tax", cityId, v) end end
function M.tailor15_level_tax(cityId, v) if v==nil then return delegate("world","tailor15_level_tax", cityId) else return delegate("world","set_tailor15_level_tax", cityId, v) end end
function M.tannery15_level_tax(cityId, v) if v==nil then return delegate("world","tannery15_level_tax", cityId) else return delegate("world","set_tannery15_level_tax", cityId, v) end end
function M.tavern15_level_tax(cityId, v) if v==nil then return delegate("world","tavern15_level_tax", cityId) else return delegate("world","set_tavern15_level_tax", cityId, v) end end
function M.thieves_guild15_level_tax(cityId, v) if v==nil then return delegate("world","thieves_guild15_level_tax", cityId) else return delegate("world","set_thieves_guild15_level_tax", cityId, v) end end
function M.toolmaker15_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker15_level_tax", cityId) else return delegate("world","set_toolmaker15_level_tax", cityId, v) end end
function M.tower15_level_tax(cityId, v) if v==nil then return delegate("world","tower15_level_tax", cityId) else return delegate("world","set_tower15_level_tax", cityId, v) end end
function M.turner15_level_tax(cityId, v) if v==nil then return delegate("world","turner15_level_tax", cityId) else return delegate("world","set_turner15_level_tax", cityId, v) end end
function M.university16_level_tax(cityId, v) if v==nil then return delegate("world","university16_level_tax", cityId) else return delegate("world","set_university16_level_tax", cityId, v) end end
function M.university_hall15_level_tax(cityId, v) if v==nil then return delegate("world","university_hall15_level_tax", cityId) else return delegate("world","set_university_hall15_level_tax", cityId, v) end end
function M.vineyard15_level_tax(cityId, v) if v==nil then return delegate("world","vineyard15_level_tax", cityId) else return delegate("world","set_vineyard15_level_tax", cityId, v) end end
function M.vintner15_level_tax(cityId, v) if v==nil then return delegate("world","vintner15_level_tax", cityId) else return delegate("world","set_vintner15_level_tax", cityId, v) end end
function M.wall16_level_tax(cityId, v) if v==nil then return delegate("world","wall16_level_tax", cityId) else return delegate("world","set_wall16_level_tax", cityId, v) end end
function M.apothecary16_level_tax(cityId, v) if v==nil then return delegate("world","apothecary16_level_tax", cityId) else return delegate("world","set_apothecary16_level_tax", cityId, v) end end
function M.armorer16_level_tax(cityId, v) if v==nil then return delegate("world","armorer16_level_tax", cityId) else return delegate("world","set_armorer16_level_tax", cityId, v) end end
function M.baker16_level_tax(cityId, v) if v==nil then return delegate("world","baker16_level_tax", cityId) else return delegate("world","set_baker16_level_tax", cityId, v) end end
function M.barber16_level_tax(cityId, v) if v==nil then return delegate("world","barber16_level_tax", cityId) else return delegate("world","set_barber16_level_tax", cityId, v) end end
function M.bathhouse16_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse16_level_tax", cityId) else return delegate("world","set_bathhouse16_level_tax", cityId, v) end end
function M.bowyer16_level_tax(cityId, v) if v==nil then return delegate("world","bowyer16_level_tax", cityId) else return delegate("world","set_bowyer16_level_tax", cityId, v) end end
function M.brewmaster16_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster16_level_tax", cityId) else return delegate("world","set_brewmaster16_level_tax", cityId, v) end end
function M.brickmaker16_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker16_level_tax", cityId) else return delegate("world","set_brickmaker16_level_tax", cityId, v) end end
function M.bridge16_level_tax(cityId, v) if v==nil then return delegate("world","bridge16_level_tax", cityId) else return delegate("world","set_bridge16_level_tax", cityId, v) end end
function M.brothel16_level_tax(cityId, v) if v==nil then return delegate("world","brothel16_level_tax", cityId) else return delegate("world","set_brothel16_level_tax", cityId, v) end end
function M.butcher16_level_tax(cityId, v) if v==nil then return delegate("world","butcher16_level_tax", cityId) else return delegate("world","set_butcher16_level_tax", cityId, v) end end
function M.candlemaker16_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker16_level_tax", cityId) else return delegate("world","set_candlemaker16_level_tax", cityId, v) end end
function M.carpenter16_level_tax(cityId, v) if v==nil then return delegate("world","carpenter16_level_tax", cityId) else return delegate("world","set_carpenter16_level_tax", cityId, v) end end
function M.cartwright16_level_tax(cityId, v) if v==nil then return delegate("world","cartwright16_level_tax", cityId) else return delegate("world","set_cartwright16_level_tax", cityId, v) end end
function M.castle16_level_tax(cityId, v) if v==nil then return delegate("world","castle16_level_tax", cityId) else return delegate("world","set_castle16_level_tax", cityId, v) end end
function M.cathedral16_level_tax(cityId, v) if v==nil then return delegate("world","cathedral16_level_tax", cityId) else return delegate("world","set_cathedral16_level_tax", cityId, v) end end
function M.chandler16_level_tax(cityId, v) if v==nil then return delegate("world","chandler16_level_tax", cityId) else return delegate("world","set_chandler16_level_tax", cityId, v) end end
function M.chapel16_level_tax(cityId, v) if v==nil then return delegate("world","chapel16_level_tax", cityId) else return delegate("world","set_chapel16_level_tax", cityId, v) end end
function M.charcoal16_level_tax(cityId, v) if v==nil then return delegate("world","charcoal16_level_tax", cityId) else return delegate("world","set_charcoal16_level_tax", cityId, v) end end
function M.church16_level_tax(cityId, v) if v==nil then return delegate("world","church16_level_tax", cityId) else return delegate("world","set_church16_level_tax", cityId, v) end end
function M.cobbler16_level_tax(cityId, v) if v==nil then return delegate("world","cobbler16_level_tax", cityId) else return delegate("world","set_cobbler16_level_tax", cityId, v) end end
function M.contor16_level_tax(cityId, v) if v==nil then return delegate("world","contor16_level_tax", cityId) else return delegate("world","set_contor16_level_tax", cityId, v) end end
function M.cook16_level_tax(cityId, v) if v==nil then return delegate("world","cook16_level_tax", cityId) else return delegate("world","set_cook16_level_tax", cityId, v) end end
function M.cooper16_level_tax(cityId, v) if v==nil then return delegate("world","cooper16_level_tax", cityId) else return delegate("world","set_cooper16_level_tax", cityId, v) end end
function M.courthouse16_level_tax(cityId, v) if v==nil then return delegate("world","courthouse16_level_tax", cityId) else return delegate("world","set_courthouse16_level_tax", cityId, v) end end
function M.dairy16_level_tax(cityId, v) if v==nil then return delegate("world","dairy16_level_tax", cityId) else return delegate("world","set_dairy16_level_tax", cityId, v) end end
function M.dice_house16_level_tax(cityId, v) if v==nil then return delegate("world","dice_house16_level_tax", cityId) else return delegate("world","set_dice_house16_level_tax", cityId, v) end end
function M.distiller16_level_tax(cityId, v) if v==nil then return delegate("world","distiller16_level_tax", cityId) else return delegate("world","set_distiller16_level_tax", cityId, v) end end
function M.dyer16_level_tax(cityId, v) if v==nil then return delegate("world","dyer16_level_tax", cityId) else return delegate("world","set_dyer16_level_tax", cityId, v) end end
function M.fishery16_level_tax(cityId, v) if v==nil then return delegate("world","fishery16_level_tax", cityId) else return delegate("world","set_fishery16_level_tax", cityId, v) end end
function M.forum16_level_tax(cityId, v) if v==nil then return delegate("world","forum16_level_tax", cityId) else return delegate("world","set_forum16_level_tax", cityId, v) end end
function M.fowler16_level_tax(cityId, v) if v==nil then return delegate("world","fowler16_level_tax", cityId) else return delegate("world","set_fowler16_level_tax", cityId, v) end end
function M.furrier16_level_tax(cityId, v) if v==nil then return delegate("world","furrier16_level_tax", cityId) else return delegate("world","set_furrier16_level_tax", cityId, v) end end
function M.garrison16_level_tax(cityId, v) if v==nil then return delegate("world","garrison16_level_tax", cityId) else return delegate("world","set_garrison16_level_tax", cityId, v) end end
function M.gates16_level_tax(cityId, v) if v==nil then return delegate("world","gates16_level_tax", cityId) else return delegate("world","set_gates16_level_tax", cityId, v) end end
function M.glassblower16_level_tax(cityId, v) if v==nil then return delegate("world","glassblower16_level_tax", cityId) else return delegate("world","set_glassblower16_level_tax", cityId, v) end end
function M.goldbeater16_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater16_level_tax", cityId) else return delegate("world","set_goldbeater16_level_tax", cityId, v) end end
function M.goldsmith16_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith16_level_tax", cityId) else return delegate("world","set_goldsmith16_level_tax", cityId, v) end end
function M.granary16_level_tax(cityId, v) if v==nil then return delegate("world","granary16_level_tax", cityId) else return delegate("world","set_granary16_level_tax", cityId, v) end end
function M.guardhouse16_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse16_level_tax", cityId) else return delegate("world","set_guardhouse16_level_tax", cityId, v) end end
function M.guild_house16_level_tax(cityId, v) if v==nil then return delegate("world","guild_house16_level_tax", cityId) else return delegate("world","set_guild_house16_level_tax", cityId, v) end end
function M.harbor16_level_tax(cityId, v) if v==nil then return delegate("world","harbor16_level_tax", cityId) else return delegate("world","set_harbor16_level_tax", cityId, v) end end
function M.harbor_dock16_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock16_level_tax", cityId) else return delegate("world","set_harbor_dock16_level_tax", cityId, v) end end
function M.harbor_walls16_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls16_level_tax", cityId) else return delegate("world","set_harbor_walls16_level_tax", cityId, v) end end
function M.herb_garden16_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden16_level_tax", cityId) else return delegate("world","set_herb_garden16_level_tax", cityId, v) end end
function M.hospital16_level_tax(cityId, v) if v==nil then return delegate("world","hospital16_level_tax", cityId) else return delegate("world","set_hospital16_level_tax", cityId, v) end end
function M.house16_level_tax(cityId, v) if v==nil then return delegate("world","house16_level_tax", cityId) else return delegate("world","set_house16_level_tax", cityId, v) end end
function M.jeweler16_level_tax(cityId, v) if v==nil then return delegate("world","jeweler16_level_tax", cityId) else return delegate("world","set_jeweler16_level_tax", cityId, v) end end
function M.library16_level_tax(cityId, v) if v==nil then return delegate("world","library16_level_tax", cityId) else return delegate("world","set_library16_level_tax", cityId, v) end end
function M.library_hall16_level_tax(cityId, v) if v==nil then return delegate("world","library_hall16_level_tax", cityId) else return delegate("world","set_library_hall16_level_tax", cityId, v) end end
function M.market16_level_tax(cityId, v) if v==nil then return delegate("world","market16_level_tax", cityId) else return delegate("world","set_market16_level_tax", cityId, v) end end
function M.miller16_level_tax(cityId, v) if v==nil then return delegate("world","miller16_level_tax", cityId) else return delegate("world","set_miller16_level_tax", cityId, v) end end
function M.mine16_level_tax(cityId, v) if v==nil then return delegate("world","mine16_level_tax", cityId) else return delegate("world","set_mine16_level_tax", cityId, v) end end
function M.mint16_level_tax(cityId, v) if v==nil then return delegate("world","mint16_level_tax", cityId) else return delegate("world","set_mint16_level_tax", cityId, v) end end
function M.monastery16_level_tax(cityId, v) if v==nil then return delegate("world","monastery16_level_tax", cityId) else return delegate("world","set_monastery16_level_tax", cityId, v) end end
function M.papermill16_level_tax(cityId, v) if v==nil then return delegate("world","papermill16_level_tax", cityId) else return delegate("world","set_papermill16_level_tax", cityId, v) end end
function M.perfumer16_level_tax(cityId, v) if v==nil then return delegate("world","perfumer16_level_tax", cityId) else return delegate("world","set_perfumer16_level_tax", cityId, v) end end
function M.potter16_level_tax(cityId, v) if v==nil then return delegate("world","potter16_level_tax", cityId) else return delegate("world","set_potter16_level_tax", cityId, v) end end
function M.pottery16_level_tax(cityId, v) if v==nil then return delegate("world","pottery16_level_tax", cityId) else return delegate("world","set_pottery16_level_tax", cityId, v) end end
function M.printing_house16_level_tax(cityId, v) if v==nil then return delegate("world","printing_house16_level_tax", cityId) else return delegate("world","set_printing_house16_level_tax", cityId, v) end end
function M.ropemaker16_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker16_level_tax", cityId) else return delegate("world","set_ropemaker16_level_tax", cityId, v) end end
function M.ropemaker_workshop16_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_workshop16_level_tax", cityId) else return delegate("world","set_ropemaker_workshop16_level_tax", cityId, v) end end
function M.saddler16_level_tax(cityId, v) if v==nil then return delegate("world","saddler16_level_tax", cityId) else return delegate("world","set_saddler16_level_tax", cityId, v) end end
function M.school16_level_tax(cityId, v) if v==nil then return delegate("world","school16_level_tax", cityId) else return delegate("world","set_school16_level_tax", cityId, v) end end
function M.schoolhouse16_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse16_level_tax", cityId) else return delegate("world","set_schoolhouse16_level_tax", cityId, v) end end
function M.sentry_tower16_level_tax(cityId, v) if v==nil then return delegate("world","sentry_tower16_level_tax", cityId) else return delegate("world","set_sentry_tower16_level_tax", cityId, v) end end
function M.stables16_level_tax(cityId, v) if v==nil then return delegate("world","stables16_level_tax", cityId) else return delegate("world","set_stables16_level_tax", cityId, v) end end
function M.stonecutter16_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter16_level_tax", cityId) else return delegate("world","set_stonecutter16_level_tax", cityId, v) end end
function M.tailor16_level_tax(cityId, v) if v==nil then return delegate("world","tailor16_level_tax", cityId) else return delegate("world","set_tailor16_level_tax", cityId, v) end end
function M.tannery16_level_tax(cityId, v) if v==nil then return delegate("world","tannery16_level_tax", cityId) else return delegate("world","set_tannery16_level_tax", cityId, v) end end
function M.tavern16_level_tax(cityId, v) if v==nil then return delegate("world","tavern16_level_tax", cityId) else return delegate("world","set_tavern16_level_tax", cityId, v) end end
function M.thieves_guild16_level_tax(cityId, v) if v==nil then return delegate("world","thieves_guild16_level_tax", cityId) else return delegate("world","set_thieves_guild16_level_tax", cityId, v) end end
function M.toolmaker16_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker16_level_tax", cityId) else return delegate("world","set_toolmaker16_level_tax", cityId, v) end end
function M.tower16_level_tax(cityId, v) if v==nil then return delegate("world","tower16_level_tax", cityId) else return delegate("world","set_tower16_level_tax", cityId, v) end end
function M.turner16_level_tax(cityId, v) if v==nil then return delegate("world","turner16_level_tax", cityId) else return delegate("world","set_turner16_level_tax", cityId, v) end end
function M.university_hall16_level_tax(cityId, v) if v==nil then return delegate("world","university_hall16_level_tax", cityId) else return delegate("world","set_university_hall16_level_tax", cityId, v) end end
function M.vineyard16_level_tax(cityId, v) if v==nil then return delegate("world","vineyard16_level_tax", cityId) else return delegate("world","set_vineyard16_level_tax", cityId, v) end end
function M.vintner16_level_tax(cityId, v) if v==nil then return delegate("world","vintner16_level_tax", cityId) else return delegate("world","set_vintner16_level_tax", cityId, v) end end
function M.wall17_level_tax(cityId, v) if v==nil then return delegate("world","wall17_level_tax", cityId) else return delegate("world","set_wall17_level_tax", cityId, v) end end
function M.warehouse16_level_tax(cityId, v) if v==nil then return delegate("world","warehouse16_level_tax", cityId) else return delegate("world","set_warehouse16_level_tax", cityId, v) end end
function M.weaving_mill16_level_tax(cityId, v) if v==nil then return delegate("world","weaving_mill16_level_tax", cityId) else return delegate("world","set_weaving_mill16_level_tax", cityId, v) end end
function M.well16_level_tax(cityId, v) if v==nil then return delegate("world","well16_level_tax", cityId) else return delegate("world","set_well16_level_tax", cityId, v) end end
function M.armorer17_level_tax(cityId, v) if v==nil then return delegate("world","armorer17_level_tax", cityId) else return delegate("world","set_armorer17_level_tax", cityId, v) end end
function M.baker17_level_tax(cityId, v) if v==nil then return delegate("world","baker17_level_tax", cityId) else return delegate("world","set_baker17_level_tax", cityId, v) end end
function M.barber17_level_tax(cityId, v) if v==nil then return delegate("world","barber17_level_tax", cityId) else return delegate("world","set_barber17_level_tax", cityId, v) end end
function M.bathhouse17_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse17_level_tax", cityId) else return delegate("world","set_bathhouse17_level_tax", cityId, v) end end
function M.bowyer17_level_tax(cityId, v) if v==nil then return delegate("world","bowyer17_level_tax", cityId) else return delegate("world","set_bowyer17_level_tax", cityId, v) end end
function M.brewmaster17_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster17_level_tax", cityId) else return delegate("world","set_brewmaster17_level_tax", cityId, v) end end
function M.brickmaker17_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker17_level_tax", cityId) else return delegate("world","set_brickmaker17_level_tax", cityId, v) end end
function M.bridge17_level_tax(cityId, v) if v==nil then return delegate("world","bridge17_level_tax", cityId) else return delegate("world","set_bridge17_level_tax", cityId, v) end end
function M.brothel17_level_tax(cityId, v) if v==nil then return delegate("world","brothel17_level_tax", cityId) else return delegate("world","set_brothel17_level_tax", cityId, v) end end
function M.butcher17_level_tax(cityId, v) if v==nil then return delegate("world","butcher17_level_tax", cityId) else return delegate("world","set_butcher17_level_tax", cityId, v) end end
function M.candlemaker17_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker17_level_tax", cityId) else return delegate("world","set_candlemaker17_level_tax", cityId, v) end end
function M.carpenter17_level_tax(cityId, v) if v==nil then return delegate("world","carpenter17_level_tax", cityId) else return delegate("world","set_carpenter17_level_tax", cityId, v) end end
function M.cartwright17_level_tax(cityId, v) if v==nil then return delegate("world","cartwright17_level_tax", cityId) else return delegate("world","set_cartwright17_level_tax", cityId, v) end end
function M.castle17_level_tax(cityId, v) if v==nil then return delegate("world","castle17_level_tax", cityId) else return delegate("world","set_castle17_level_tax", cityId, v) end end
function M.cathedral17_level_tax(cityId, v) if v==nil then return delegate("world","cathedral17_level_tax", cityId) else return delegate("world","set_cathedral17_level_tax", cityId, v) end end
function M.chandler17_level_tax(cityId, v) if v==nil then return delegate("world","chandler17_level_tax", cityId) else return delegate("world","set_chandler17_level_tax", cityId, v) end end
function M.chapel17_level_tax(cityId, v) if v==nil then return delegate("world","chapel17_level_tax", cityId) else return delegate("world","set_chapel17_level_tax", cityId, v) end end
function M.charcoal17_level_tax(cityId, v) if v==nil then return delegate("world","charcoal17_level_tax", cityId) else return delegate("world","set_charcoal17_level_tax", cityId, v) end end
function M.church17_level_tax(cityId, v) if v==nil then return delegate("world","church17_level_tax", cityId) else return delegate("world","set_church17_level_tax", cityId, v) end end
function M.cobbler17_level_tax(cityId, v) if v==nil then return delegate("world","cobbler17_level_tax", cityId) else return delegate("world","set_cobbler17_level_tax", cityId, v) end end
function M.contor17_level_tax(cityId, v) if v==nil then return delegate("world","contor17_level_tax", cityId) else return delegate("world","set_contor17_level_tax", cityId, v) end end
function M.cook17_level_tax(cityId, v) if v==nil then return delegate("world","cook17_level_tax", cityId) else return delegate("world","set_cook17_level_tax", cityId, v) end end
function M.cooper17_level_tax(cityId, v) if v==nil then return delegate("world","cooper17_level_tax", cityId) else return delegate("world","set_cooper17_level_tax", cityId, v) end end
function M.courthouse17_level_tax(cityId, v) if v==nil then return delegate("world","courthouse17_level_tax", cityId) else return delegate("world","set_courthouse17_level_tax", cityId, v) end end
function M.dairy17_level_tax(cityId, v) if v==nil then return delegate("world","dairy17_level_tax", cityId) else return delegate("world","set_dairy17_level_tax", cityId, v) end end
function M.dice_house17_level_tax(cityId, v) if v==nil then return delegate("world","dice_house17_level_tax", cityId) else return delegate("world","set_dice_house17_level_tax", cityId, v) end end
function M.distiller17_level_tax(cityId, v) if v==nil then return delegate("world","distiller17_level_tax", cityId) else return delegate("world","set_distiller17_level_tax", cityId, v) end end
function M.dyer17_level_tax(cityId, v) if v==nil then return delegate("world","dyer17_level_tax", cityId) else return delegate("world","set_dyer17_level_tax", cityId, v) end end
function M.fishery17_level_tax(cityId, v) if v==nil then return delegate("world","fishery17_level_tax", cityId) else return delegate("world","set_fishery17_level_tax", cityId, v) end end
function M.forum17_level_tax(cityId, v) if v==nil then return delegate("world","forum17_level_tax", cityId) else return delegate("world","set_forum17_level_tax", cityId, v) end end
function M.fowler17_level_tax(cityId, v) if v==nil then return delegate("world","fowler17_level_tax", cityId) else return delegate("world","set_fowler17_level_tax", cityId, v) end end
function M.furrier17_level_tax(cityId, v) if v==nil then return delegate("world","furrier17_level_tax", cityId) else return delegate("world","set_furrier17_level_tax", cityId, v) end end
function M.garrison17_level_tax(cityId, v) if v==nil then return delegate("world","garrison17_level_tax", cityId) else return delegate("world","set_garrison17_level_tax", cityId, v) end end
function M.gates17_level_tax(cityId, v) if v==nil then return delegate("world","gates17_level_tax", cityId) else return delegate("world","set_gates17_level_tax", cityId, v) end end
function M.glassblower17_level_tax(cityId, v) if v==nil then return delegate("world","glassblower17_level_tax", cityId) else return delegate("world","set_glassblower17_level_tax", cityId, v) end end
function M.goldbeater17_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater17_level_tax", cityId) else return delegate("world","set_goldbeater17_level_tax", cityId, v) end end
function M.goldsmith17_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith17_level_tax", cityId) else return delegate("world","set_goldsmith17_level_tax", cityId, v) end end
function M.granary17_level_tax(cityId, v) if v==nil then return delegate("world","granary17_level_tax", cityId) else return delegate("world","set_granary17_level_tax", cityId, v) end end
function M.guardhouse17_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse17_level_tax", cityId) else return delegate("world","set_guardhouse17_level_tax", cityId, v) end end
function M.guild_house17_level_tax(cityId, v) if v==nil then return delegate("world","guild_house17_level_tax", cityId) else return delegate("world","set_guild_house17_level_tax", cityId, v) end end
function M.harbor17_level_tax(cityId, v) if v==nil then return delegate("world","harbor17_level_tax", cityId) else return delegate("world","set_harbor17_level_tax", cityId, v) end end
function M.harbor_dock17_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock17_level_tax", cityId) else return delegate("world","set_harbor_dock17_level_tax", cityId, v) end end
function M.harbor_walls17_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls17_level_tax", cityId) else return delegate("world","set_harbor_walls17_level_tax", cityId, v) end end
function M.herb_garden17_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden17_level_tax", cityId) else return delegate("world","set_herb_garden17_level_tax", cityId, v) end end
function M.hospital17_level_tax(cityId, v) if v==nil then return delegate("world","hospital17_level_tax", cityId) else return delegate("world","set_hospital17_level_tax", cityId, v) end end
function M.house17_level_tax(cityId, v) if v==nil then return delegate("world","house17_level_tax", cityId) else return delegate("world","set_house17_level_tax", cityId, v) end end
function M.jeweler17_level_tax(cityId, v) if v==nil then return delegate("world","jeweler17_level_tax", cityId) else return delegate("world","set_jeweler17_level_tax", cityId, v) end end
function M.library17_level_tax(cityId, v) if v==nil then return delegate("world","library17_level_tax", cityId) else return delegate("world","set_library17_level_tax", cityId, v) end end
function M.library_hall17_level_tax(cityId, v) if v==nil then return delegate("world","library_hall17_level_tax", cityId) else return delegate("world","set_library_hall17_level_tax", cityId, v) end end
function M.market17_level_tax(cityId, v) if v==nil then return delegate("world","market17_level_tax", cityId) else return delegate("world","set_market17_level_tax", cityId, v) end end
function M.miller17_level_tax(cityId, v) if v==nil then return delegate("world","miller17_level_tax", cityId) else return delegate("world","set_miller17_level_tax", cityId, v) end end
function M.mine17_level_tax(cityId, v) if v==nil then return delegate("world","mine17_level_tax", cityId) else return delegate("world","set_mine17_level_tax", cityId, v) end end
function M.mint17_level_tax(cityId, v) if v==nil then return delegate("world","mint17_level_tax", cityId) else return delegate("world","set_mint17_level_tax", cityId, v) end end
function M.monastery17_level_tax(cityId, v) if v==nil then return delegate("world","monastery17_level_tax", cityId) else return delegate("world","set_monastery17_level_tax", cityId, v) end end
function M.papermill17_level_tax(cityId, v) if v==nil then return delegate("world","papermill17_level_tax", cityId) else return delegate("world","set_papermill17_level_tax", cityId, v) end end
function M.perfumer17_level_tax(cityId, v) if v==nil then return delegate("world","perfumer17_level_tax", cityId) else return delegate("world","set_perfumer17_level_tax", cityId, v) end end
function M.potter17_level_tax(cityId, v) if v==nil then return delegate("world","potter17_level_tax", cityId) else return delegate("world","set_potter17_level_tax", cityId, v) end end
function M.pottery17_level_tax(cityId, v) if v==nil then return delegate("world","pottery17_level_tax", cityId) else return delegate("world","set_pottery17_level_tax", cityId, v) end end
function M.printing_house17_level_tax(cityId, v) if v==nil then return delegate("world","printing_house17_level_tax", cityId) else return delegate("world","set_printing_house17_level_tax", cityId, v) end end
function M.ropemaker17_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker17_level_tax", cityId) else return delegate("world","set_ropemaker17_level_tax", cityId, v) end end
function M.ropemaker_workshop17_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_workshop17_level_tax", cityId) else return delegate("world","set_ropemaker_workshop17_level_tax", cityId, v) end end
function M.saddler17_level_tax(cityId, v) if v==nil then return delegate("world","saddler17_level_tax", cityId) else return delegate("world","set_saddler17_level_tax", cityId, v) end end
function M.school17_level_tax(cityId, v) if v==nil then return delegate("world","school17_level_tax", cityId) else return delegate("world","set_school17_level_tax", cityId, v) end end
function M.schoolhouse17_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse17_level_tax", cityId) else return delegate("world","set_schoolhouse17_level_tax", cityId, v) end end
function M.sentry_tower17_level_tax(cityId, v) if v==nil then return delegate("world","sentry_tower17_level_tax", cityId) else return delegate("world","set_sentry_tower17_level_tax", cityId, v) end end
function M.stables17_level_tax(cityId, v) if v==nil then return delegate("world","stables17_level_tax", cityId) else return delegate("world","set_stables17_level_tax", cityId, v) end end
function M.stonecutter17_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter17_level_tax", cityId) else return delegate("world","set_stonecutter17_level_tax", cityId, v) end end
function M.tailor17_level_tax(cityId, v) if v==nil then return delegate("world","tailor17_level_tax", cityId) else return delegate("world","set_tailor17_level_tax", cityId, v) end end
function M.tannery17_level_tax(cityId, v) if v==nil then return delegate("world","tannery17_level_tax", cityId) else return delegate("world","set_tannery17_level_tax", cityId, v) end end
function M.tavern17_level_tax(cityId, v) if v==nil then return delegate("world","tavern17_level_tax", cityId) else return delegate("world","set_tavern17_level_tax", cityId, v) end end
function M.thieves_guild17_level_tax(cityId, v) if v==nil then return delegate("world","thieves_guild17_level_tax", cityId) else return delegate("world","set_thieves_guild17_level_tax", cityId, v) end end
function M.toolmaker17_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker17_level_tax", cityId) else return delegate("world","set_toolmaker17_level_tax", cityId, v) end end
function M.tower17_level_tax(cityId, v) if v==nil then return delegate("world","tower17_level_tax", cityId) else return delegate("world","set_tower17_level_tax", cityId, v) end end
function M.turner17_level_tax(cityId, v) if v==nil then return delegate("world","turner17_level_tax", cityId) else return delegate("world","set_turner17_level_tax", cityId, v) end end
function M.university17_level_tax(cityId, v) if v==nil then return delegate("world","university17_level_tax", cityId) else return delegate("world","set_university17_level_tax", cityId, v) end end
function M.university_hall17_level_tax(cityId, v) if v==nil then return delegate("world","university_hall17_level_tax", cityId) else return delegate("world","set_university_hall17_level_tax", cityId, v) end end
function M.vineyard17_level_tax(cityId, v) if v==nil then return delegate("world","vineyard17_level_tax", cityId) else return delegate("world","set_vineyard17_level_tax", cityId, v) end end
function M.vintner17_level_tax(cityId, v) if v==nil then return delegate("world","vintner17_level_tax", cityId) else return delegate("world","set_vintner17_level_tax", cityId, v) end end
function M.wall18_level_tax(cityId, v) if v==nil then return delegate("world","wall18_level_tax", cityId) else return delegate("world","set_wall18_level_tax", cityId, v) end end
function M.warehouse17_level_tax(cityId, v) if v==nil then return delegate("world","warehouse17_level_tax", cityId) else return delegate("world","set_warehouse17_level_tax", cityId, v) end end
function M.weaving_mill17_level_tax(cityId, v) if v==nil then return delegate("world","weaving_mill17_level_tax", cityId) else return delegate("world","set_weaving_mill17_level_tax", cityId, v) end end
function M.well17_level_tax(cityId, v) if v==nil then return delegate("world","well17_level_tax", cityId) else return delegate("world","set_well17_level_tax", cityId, v) end end
function M.armorer18_level_tax(cityId, v) if v==nil then return delegate("world","armorer18_level_tax", cityId) else return delegate("world","set_armorer18_level_tax", cityId, v) end end
function M.baker18_level_tax(cityId, v) if v==nil then return delegate("world","baker18_level_tax", cityId) else return delegate("world","set_baker18_level_tax", cityId, v) end end
function M.barber18_level_tax(cityId, v) if v==nil then return delegate("world","barber18_level_tax", cityId) else return delegate("world","set_barber18_level_tax", cityId, v) end end
function M.bathhouse18_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse18_level_tax", cityId) else return delegate("world","set_bathhouse18_level_tax", cityId, v) end end
function M.bowyer18_level_tax(cityId, v) if v==nil then return delegate("world","bowyer18_level_tax", cityId) else return delegate("world","set_bowyer18_level_tax", cityId, v) end end
function M.brewmaster18_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster18_level_tax", cityId) else return delegate("world","set_brewmaster18_level_tax", cityId, v) end end
function M.brickmaker18_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker18_level_tax", cityId) else return delegate("world","set_brickmaker18_level_tax", cityId, v) end end
function M.bridge18_level_tax(cityId, v) if v==nil then return delegate("world","bridge18_level_tax", cityId) else return delegate("world","set_bridge18_level_tax", cityId, v) end end
function M.brothel18_level_tax(cityId, v) if v==nil then return delegate("world","brothel18_level_tax", cityId) else return delegate("world","set_brothel18_level_tax", cityId, v) end end
function M.butcher18_level_tax(cityId, v) if v==nil then return delegate("world","butcher18_level_tax", cityId) else return delegate("world","set_butcher18_level_tax", cityId, v) end end
function M.candlemaker18_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker18_level_tax", cityId) else return delegate("world","set_candlemaker18_level_tax", cityId, v) end end
function M.carpenter18_level_tax(cityId, v) if v==nil then return delegate("world","carpenter18_level_tax", cityId) else return delegate("world","set_carpenter18_level_tax", cityId, v) end end
function M.cartwright18_level_tax(cityId, v) if v==nil then return delegate("world","cartwright18_level_tax", cityId) else return delegate("world","set_cartwright18_level_tax", cityId, v) end end
function M.castle18_level_tax(cityId, v) if v==nil then return delegate("world","castle18_level_tax", cityId) else return delegate("world","set_castle18_level_tax", cityId, v) end end
function M.cathedral18_level_tax(cityId, v) if v==nil then return delegate("world","cathedral18_level_tax", cityId) else return delegate("world","set_cathedral18_level_tax", cityId, v) end end
function M.chandler18_level_tax(cityId, v) if v==nil then return delegate("world","chandler18_level_tax", cityId) else return delegate("world","set_chandler18_level_tax", cityId, v) end end
function M.chapel18_level_tax(cityId, v) if v==nil then return delegate("world","chapel18_level_tax", cityId) else return delegate("world","set_chapel18_level_tax", cityId, v) end end
function M.charcoal18_level_tax(cityId, v) if v==nil then return delegate("world","charcoal18_level_tax", cityId) else return delegate("world","set_charcoal18_level_tax", cityId, v) end end
function M.church18_level_tax(cityId, v) if v==nil then return delegate("world","church18_level_tax", cityId) else return delegate("world","set_church18_level_tax", cityId, v) end end
function M.cobbler18_level_tax(cityId, v) if v==nil then return delegate("world","cobbler18_level_tax", cityId) else return delegate("world","set_cobbler18_level_tax", cityId, v) end end
function M.contor18_level_tax(cityId, v) if v==nil then return delegate("world","contor18_level_tax", cityId) else return delegate("world","set_contor18_level_tax", cityId, v) end end
function M.cook18_level_tax(cityId, v) if v==nil then return delegate("world","cook18_level_tax", cityId) else return delegate("world","set_cook18_level_tax", cityId, v) end end
function M.cooper18_level_tax(cityId, v) if v==nil then return delegate("world","cooper18_level_tax", cityId) else return delegate("world","set_cooper18_level_tax", cityId, v) end end
function M.courthouse18_level_tax(cityId, v) if v==nil then return delegate("world","courthouse18_level_tax", cityId) else return delegate("world","set_courthouse18_level_tax", cityId, v) end end
function M.dairy18_level_tax(cityId, v) if v==nil then return delegate("world","dairy18_level_tax", cityId) else return delegate("world","set_dairy18_level_tax", cityId, v) end end
function M.dice_house18_level_tax(cityId, v) if v==nil then return delegate("world","dice_house18_level_tax", cityId) else return delegate("world","set_dice_house18_level_tax", cityId, v) end end
function M.distiller18_level_tax(cityId, v) if v==nil then return delegate("world","distiller18_level_tax", cityId) else return delegate("world","set_distiller18_level_tax", cityId, v) end end
function M.dyer18_level_tax(cityId, v) if v==nil then return delegate("world","dyer18_level_tax", cityId) else return delegate("world","set_dyer18_level_tax", cityId, v) end end
function M.fishery18_level_tax(cityId, v) if v==nil then return delegate("world","fishery18_level_tax", cityId) else return delegate("world","set_fishery18_level_tax", cityId, v) end end
function M.forum18_level_tax(cityId, v) if v==nil then return delegate("world","forum18_level_tax", cityId) else return delegate("world","set_forum18_level_tax", cityId, v) end end
function M.fowler18_level_tax(cityId, v) if v==nil then return delegate("world","fowler18_level_tax", cityId) else return delegate("world","set_fowler18_level_tax", cityId, v) end end
function M.furrier18_level_tax(cityId, v) if v==nil then return delegate("world","furrier18_level_tax", cityId) else return delegate("world","set_furrier18_level_tax", cityId, v) end end
function M.garrison18_level_tax(cityId, v) if v==nil then return delegate("world","garrison18_level_tax", cityId) else return delegate("world","set_garrison18_level_tax", cityId, v) end end
function M.gates18_level_tax(cityId, v) if v==nil then return delegate("world","gates18_level_tax", cityId) else return delegate("world","set_gates18_level_tax", cityId, v) end end
function M.glassblower18_level_tax(cityId, v) if v==nil then return delegate("world","glassblower18_level_tax", cityId) else return delegate("world","set_glassblower18_level_tax", cityId, v) end end
function M.goldbeater18_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater18_level_tax", cityId) else return delegate("world","set_goldbeater18_level_tax", cityId, v) end end
function M.goldsmith18_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith18_level_tax", cityId) else return delegate("world","set_goldsmith18_level_tax", cityId, v) end end
function M.granary18_level_tax(cityId, v) if v==nil then return delegate("world","granary18_level_tax", cityId) else return delegate("world","set_granary18_level_tax", cityId, v) end end
function M.guardhouse18_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse18_level_tax", cityId) else return delegate("world","set_guardhouse18_level_tax", cityId, v) end end
function M.guild_house18_level_tax(cityId, v) if v==nil then return delegate("world","guild_house18_level_tax", cityId) else return delegate("world","set_guild_house18_level_tax", cityId, v) end end
function M.harbor18_level_tax(cityId, v) if v==nil then return delegate("world","harbor18_level_tax", cityId) else return delegate("world","set_harbor18_level_tax", cityId, v) end end
function M.harbor_dock18_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock18_level_tax", cityId) else return delegate("world","set_harbor_dock18_level_tax", cityId, v) end end
function M.harbor_walls18_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls18_level_tax", cityId) else return delegate("world","set_harbor_walls18_level_tax", cityId, v) end end
function M.herb_garden18_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden18_level_tax", cityId) else return delegate("world","set_herb_garden18_level_tax", cityId, v) end end
function M.hospital18_level_tax(cityId, v) if v==nil then return delegate("world","hospital18_level_tax", cityId) else return delegate("world","set_hospital18_level_tax", cityId, v) end end
function M.house18_level_tax(cityId, v) if v==nil then return delegate("world","house18_level_tax", cityId) else return delegate("world","set_house18_level_tax", cityId, v) end end
function M.jeweler18_level_tax(cityId, v) if v==nil then return delegate("world","jeweler18_level_tax", cityId) else return delegate("world","set_jeweler18_level_tax", cityId, v) end end
function M.library18_level_tax(cityId, v) if v==nil then return delegate("world","library18_level_tax", cityId) else return delegate("world","set_library18_level_tax", cityId, v) end end
function M.library_hall18_level_tax(cityId, v) if v==nil then return delegate("world","library_hall18_level_tax", cityId) else return delegate("world","set_library_hall18_level_tax", cityId, v) end end
function M.market18_level_tax(cityId, v) if v==nil then return delegate("world","market18_level_tax", cityId) else return delegate("world","set_market18_level_tax", cityId, v) end end
function M.miller18_level_tax(cityId, v) if v==nil then return delegate("world","miller18_level_tax", cityId) else return delegate("world","set_miller18_level_tax", cityId, v) end end
function M.mine18_level_tax(cityId, v) if v==nil then return delegate("world","mine18_level_tax", cityId) else return delegate("world","set_mine18_level_tax", cityId, v) end end
function M.mint18_level_tax(cityId, v) if v==nil then return delegate("world","mint18_level_tax", cityId) else return delegate("world","set_mint18_level_tax", cityId, v) end end
function M.monastery18_level_tax(cityId, v) if v==nil then return delegate("world","monastery18_level_tax", cityId) else return delegate("world","set_monastery18_level_tax", cityId, v) end end
function M.papermill18_level_tax(cityId, v) if v==nil then return delegate("world","papermill18_level_tax", cityId) else return delegate("world","set_papermill18_level_tax", cityId, v) end end
function M.perfumer18_level_tax(cityId, v) if v==nil then return delegate("world","perfumer18_level_tax", cityId) else return delegate("world","set_perfumer18_level_tax", cityId, v) end end
function M.potter18_level_tax(cityId, v) if v==nil then return delegate("world","potter18_level_tax", cityId) else return delegate("world","set_potter18_level_tax", cityId, v) end end
function M.pottery18_level_tax(cityId, v) if v==nil then return delegate("world","pottery18_level_tax", cityId) else return delegate("world","set_pottery18_level_tax", cityId, v) end end
function M.printing_house18_level_tax(cityId, v) if v==nil then return delegate("world","printing_house18_level_tax", cityId) else return delegate("world","set_printing_house18_level_tax", cityId, v) end end
function M.ropemaker18_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker18_level_tax", cityId) else return delegate("world","set_ropemaker18_level_tax", cityId, v) end end
function M.ropemaker_workshop18_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_workshop18_level_tax", cityId) else return delegate("world","set_ropemaker_workshop18_level_tax", cityId, v) end end
function M.saddler18_level_tax(cityId, v) if v==nil then return delegate("world","saddler18_level_tax", cityId) else return delegate("world","set_saddler18_level_tax", cityId, v) end end
function M.school18_level_tax(cityId, v) if v==nil then return delegate("world","school18_level_tax", cityId) else return delegate("world","set_school18_level_tax", cityId, v) end end
function M.schoolhouse18_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse18_level_tax", cityId) else return delegate("world","set_schoolhouse18_level_tax", cityId, v) end end
function M.sentry_tower18_level_tax(cityId, v) if v==nil then return delegate("world","sentry_tower18_level_tax", cityId) else return delegate("world","set_sentry_tower18_level_tax", cityId, v) end end
function M.stables18_level_tax(cityId, v) if v==nil then return delegate("world","stables18_level_tax", cityId) else return delegate("world","set_stables18_level_tax", cityId, v) end end
function M.stonecutter18_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter18_level_tax", cityId) else return delegate("world","set_stonecutter18_level_tax", cityId, v) end end
function M.tailor18_level_tax(cityId, v) if v==nil then return delegate("world","tailor18_level_tax", cityId) else return delegate("world","set_tailor18_level_tax", cityId, v) end end
function M.tannery18_level_tax(cityId, v) if v==nil then return delegate("world","tannery18_level_tax", cityId) else return delegate("world","set_tannery18_level_tax", cityId, v) end end
function M.tavern18_level_tax(cityId, v) if v==nil then return delegate("world","tavern18_level_tax", cityId) else return delegate("world","set_tavern18_level_tax", cityId, v) end end
function M.thieves_guild18_level_tax(cityId, v) if v==nil then return delegate("world","thieves_guild18_level_tax", cityId) else return delegate("world","set_thieves_guild18_level_tax", cityId, v) end end
function M.toolmaker18_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker18_level_tax", cityId) else return delegate("world","set_toolmaker18_level_tax", cityId, v) end end
function M.tower18_level_tax(cityId, v) if v==nil then return delegate("world","tower18_level_tax", cityId) else return delegate("world","set_tower18_level_tax", cityId, v) end end
function M.turner18_level_tax(cityId, v) if v==nil then return delegate("world","turner18_level_tax", cityId) else return delegate("world","set_turner18_level_tax", cityId, v) end end
function M.university_hall18_level_tax(cityId, v) if v==nil then return delegate("world","university_hall18_level_tax", cityId) else return delegate("world","set_university_hall18_level_tax", cityId, v) end end
function M.vineyard18_level_tax(cityId, v) if v==nil then return delegate("world","vineyard18_level_tax", cityId) else return delegate("world","set_vineyard18_level_tax", cityId, v) end end
function M.vintner18_level_tax(cityId, v) if v==nil then return delegate("world","vintner18_level_tax", cityId) else return delegate("world","set_vintner18_level_tax", cityId, v) end end
function M.warehouse18_level_tax(cityId, v) if v==nil then return delegate("world","warehouse18_level_tax", cityId) else return delegate("world","set_warehouse18_level_tax", cityId, v) end end
function M.weaving_mill18_level_tax(cityId, v) if v==nil then return delegate("world","weaving_mill18_level_tax", cityId) else return delegate("world","set_weaving_mill18_level_tax", cityId, v) end end
function M.well18_level_tax(cityId, v) if v==nil then return delegate("world","well18_level_tax", cityId) else return delegate("world","set_well18_level_tax", cityId, v) end end
function M.armorer19_level_tax(cityId, v) if v==nil then return delegate("world","armorer19_level_tax", cityId) else return delegate("world","set_armorer19_level_tax", cityId, v) end end
function M.baker19_level_tax(cityId, v) if v==nil then return delegate("world","baker19_level_tax", cityId) else return delegate("world","set_baker19_level_tax", cityId, v) end end
function M.barber19_level_tax(cityId, v) if v==nil then return delegate("world","barber19_level_tax", cityId) else return delegate("world","set_barber19_level_tax", cityId, v) end end
function M.bathhouse19_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse19_level_tax", cityId) else return delegate("world","set_bathhouse19_level_tax", cityId, v) end end
function M.bowyer19_level_tax(cityId, v) if v==nil then return delegate("world","bowyer19_level_tax", cityId) else return delegate("world","set_bowyer19_level_tax", cityId, v) end end
function M.brewmaster19_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster19_level_tax", cityId) else return delegate("world","set_brewmaster19_level_tax", cityId, v) end end
function M.brickmaker19_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker19_level_tax", cityId) else return delegate("world","set_brickmaker19_level_tax", cityId, v) end end
function M.bridge19_level_tax(cityId, v) if v==nil then return delegate("world","bridge19_level_tax", cityId) else return delegate("world","set_bridge19_level_tax", cityId, v) end end
function M.brothel19_level_tax(cityId, v) if v==nil then return delegate("world","brothel19_level_tax", cityId) else return delegate("world","set_brothel19_level_tax", cityId, v) end end
function M.butcher19_level_tax(cityId, v) if v==nil then return delegate("world","butcher19_level_tax", cityId) else return delegate("world","set_butcher19_level_tax", cityId, v) end end
function M.candlemaker19_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker19_level_tax", cityId) else return delegate("world","set_candlemaker19_level_tax", cityId, v) end end
function M.carpenter19_level_tax(cityId, v) if v==nil then return delegate("world","carpenter19_level_tax", cityId) else return delegate("world","set_carpenter19_level_tax", cityId, v) end end
function M.cartwright19_level_tax(cityId, v) if v==nil then return delegate("world","cartwright19_level_tax", cityId) else return delegate("world","set_cartwright19_level_tax", cityId, v) end end
function M.castle19_level_tax(cityId, v) if v==nil then return delegate("world","castle19_level_tax", cityId) else return delegate("world","set_castle19_level_tax", cityId, v) end end
function M.cathedral19_level_tax(cityId, v) if v==nil then return delegate("world","cathedral19_level_tax", cityId) else return delegate("world","set_cathedral19_level_tax", cityId, v) end end
function M.chandler19_level_tax(cityId, v) if v==nil then return delegate("world","chandler19_level_tax", cityId) else return delegate("world","set_chandler19_level_tax", cityId, v) end end
function M.chapel19_level_tax(cityId, v) if v==nil then return delegate("world","chapel19_level_tax", cityId) else return delegate("world","set_chapel19_level_tax", cityId, v) end end
function M.charcoal19_level_tax(cityId, v) if v==nil then return delegate("world","charcoal19_level_tax", cityId) else return delegate("world","set_charcoal19_level_tax", cityId, v) end end
function M.church19_level_tax(cityId, v) if v==nil then return delegate("world","church19_level_tax", cityId) else return delegate("world","set_church19_level_tax", cityId, v) end end
function M.cobbler19_level_tax(cityId, v) if v==nil then return delegate("world","cobbler19_level_tax", cityId) else return delegate("world","set_cobbler19_level_tax", cityId, v) end end
function M.contor19_level_tax(cityId, v) if v==nil then return delegate("world","contor19_level_tax", cityId) else return delegate("world","set_contor19_level_tax", cityId, v) end end
function M.cook19_level_tax(cityId, v) if v==nil then return delegate("world","cook19_level_tax", cityId) else return delegate("world","set_cook19_level_tax", cityId, v) end end
function M.cooper19_level_tax(cityId, v) if v==nil then return delegate("world","cooper19_level_tax", cityId) else return delegate("world","set_cooper19_level_tax", cityId, v) end end
function M.courthouse19_level_tax(cityId, v) if v==nil then return delegate("world","courthouse19_level_tax", cityId) else return delegate("world","set_courthouse19_level_tax", cityId, v) end end
function M.dairy19_level_tax(cityId, v) if v==nil then return delegate("world","dairy19_level_tax", cityId) else return delegate("world","set_dairy19_level_tax", cityId, v) end end
function M.dice_house19_level_tax(cityId, v) if v==nil then return delegate("world","dice_house19_level_tax", cityId) else return delegate("world","set_dice_house19_level_tax", cityId, v) end end
function M.distiller19_level_tax(cityId, v) if v==nil then return delegate("world","distiller19_level_tax", cityId) else return delegate("world","set_distiller19_level_tax", cityId, v) end end
function M.dyer19_level_tax(cityId, v) if v==nil then return delegate("world","dyer19_level_tax", cityId) else return delegate("world","set_dyer19_level_tax", cityId, v) end end
function M.fishery19_level_tax(cityId, v) if v==nil then return delegate("world","fishery19_level_tax", cityId) else return delegate("world","set_fishery19_level_tax", cityId, v) end end
function M.forum19_level_tax(cityId, v) if v==nil then return delegate("world","forum19_level_tax", cityId) else return delegate("world","set_forum19_level_tax", cityId, v) end end
function M.fowler19_level_tax(cityId, v) if v==nil then return delegate("world","fowler19_level_tax", cityId) else return delegate("world","set_fowler19_level_tax", cityId, v) end end
function M.furrier19_level_tax(cityId, v) if v==nil then return delegate("world","furrier19_level_tax", cityId) else return delegate("world","set_furrier19_level_tax", cityId, v) end end
function M.garrison19_level_tax(cityId, v) if v==nil then return delegate("world","garrison19_level_tax", cityId) else return delegate("world","set_garrison19_level_tax", cityId, v) end end
function M.gates19_level_tax(cityId, v) if v==nil then return delegate("world","gates19_level_tax", cityId) else return delegate("world","set_gates19_level_tax", cityId, v) end end
function M.glassblower19_level_tax(cityId, v) if v==nil then return delegate("world","glassblower19_level_tax", cityId) else return delegate("world","set_glassblower19_level_tax", cityId, v) end end
function M.goldbeater19_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater19_level_tax", cityId) else return delegate("world","set_goldbeater19_level_tax", cityId, v) end end
function M.goldsmith19_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith19_level_tax", cityId) else return delegate("world","set_goldsmith19_level_tax", cityId, v) end end
function M.granary19_level_tax(cityId, v) if v==nil then return delegate("world","granary19_level_tax", cityId) else return delegate("world","set_granary19_level_tax", cityId, v) end end
function M.guardhouse19_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse19_level_tax", cityId) else return delegate("world","set_guardhouse19_level_tax", cityId, v) end end
function M.guild_house19_level_tax(cityId, v) if v==nil then return delegate("world","guild_house19_level_tax", cityId) else return delegate("world","set_guild_house19_level_tax", cityId, v) end end
function M.harbor19_level_tax(cityId, v) if v==nil then return delegate("world","harbor19_level_tax", cityId) else return delegate("world","set_harbor19_level_tax", cityId, v) end end
function M.harbor_dock19_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock19_level_tax", cityId) else return delegate("world","set_harbor_dock19_level_tax", cityId, v) end end
function M.harbor_walls19_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls19_level_tax", cityId) else return delegate("world","set_harbor_walls19_level_tax", cityId, v) end end
function M.herb_garden19_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden19_level_tax", cityId) else return delegate("world","set_herb_garden19_level_tax", cityId, v) end end
function M.hospital19_level_tax(cityId, v) if v==nil then return delegate("world","hospital19_level_tax", cityId) else return delegate("world","set_hospital19_level_tax", cityId, v) end end
function M.house19_level_tax(cityId, v) if v==nil then return delegate("world","house19_level_tax", cityId) else return delegate("world","set_house19_level_tax", cityId, v) end end
function M.jeweler19_level_tax(cityId, v) if v==nil then return delegate("world","jeweler19_level_tax", cityId) else return delegate("world","set_jeweler19_level_tax", cityId, v) end end
function M.library19_level_tax(cityId, v) if v==nil then return delegate("world","library19_level_tax", cityId) else return delegate("world","set_library19_level_tax", cityId, v) end end
function M.library_hall19_level_tax(cityId, v) if v==nil then return delegate("world","library_hall19_level_tax", cityId) else return delegate("world","set_library_hall19_level_tax", cityId, v) end end
function M.market19_level_tax(cityId, v) if v==nil then return delegate("world","market19_level_tax", cityId) else return delegate("world","set_market19_level_tax", cityId, v) end end
function M.miller19_level_tax(cityId, v) if v==nil then return delegate("world","miller19_level_tax", cityId) else return delegate("world","set_miller19_level_tax", cityId, v) end end
function M.mine19_level_tax(cityId, v) if v==nil then return delegate("world","mine19_level_tax", cityId) else return delegate("world","set_mine19_level_tax", cityId, v) end end
function M.mint19_level_tax(cityId, v) if v==nil then return delegate("world","mint19_level_tax", cityId) else return delegate("world","set_mint19_level_tax", cityId, v) end end
function M.monastery19_level_tax(cityId, v) if v==nil then return delegate("world","monastery19_level_tax", cityId) else return delegate("world","set_monastery19_level_tax", cityId, v) end end
function M.papermill19_level_tax(cityId, v) if v==nil then return delegate("world","papermill19_level_tax", cityId) else return delegate("world","set_papermill19_level_tax", cityId, v) end end
function M.perfumer19_level_tax(cityId, v) if v==nil then return delegate("world","perfumer19_level_tax", cityId) else return delegate("world","set_perfumer19_level_tax", cityId, v) end end
function M.potter19_level_tax(cityId, v) if v==nil then return delegate("world","potter19_level_tax", cityId) else return delegate("world","set_potter19_level_tax", cityId, v) end end
function M.pottery19_level_tax(cityId, v) if v==nil then return delegate("world","pottery19_level_tax", cityId) else return delegate("world","set_pottery19_level_tax", cityId, v) end end
function M.printing_house19_level_tax(cityId, v) if v==nil then return delegate("world","printing_house19_level_tax", cityId) else return delegate("world","set_printing_house19_level_tax", cityId, v) end end
function M.ropemaker19_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker19_level_tax", cityId) else return delegate("world","set_ropemaker19_level_tax", cityId, v) end end
function M.ropemaker_workshop19_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_workshop19_level_tax", cityId) else return delegate("world","set_ropemaker_workshop19_level_tax", cityId, v) end end
function M.saddler19_level_tax(cityId, v) if v==nil then return delegate("world","saddler19_level_tax", cityId) else return delegate("world","set_saddler19_level_tax", cityId, v) end end
function M.school19_level_tax(cityId, v) if v==nil then return delegate("world","school19_level_tax", cityId) else return delegate("world","set_school19_level_tax", cityId, v) end end
function M.schoolhouse19_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse19_level_tax", cityId) else return delegate("world","set_schoolhouse19_level_tax", cityId, v) end end
function M.sentry_tower19_level_tax(cityId, v) if v==nil then return delegate("world","sentry_tower19_level_tax", cityId) else return delegate("world","set_sentry_tower19_level_tax", cityId, v) end end
function M.stables19_level_tax(cityId, v) if v==nil then return delegate("world","stables19_level_tax", cityId) else return delegate("world","set_stables19_level_tax", cityId, v) end end
function M.stonecutter19_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter19_level_tax", cityId) else return delegate("world","set_stonecutter19_level_tax", cityId, v) end end
function M.tailor19_level_tax(cityId, v) if v==nil then return delegate("world","tailor19_level_tax", cityId) else return delegate("world","set_tailor19_level_tax", cityId, v) end end
function M.tannery19_level_tax(cityId, v) if v==nil then return delegate("world","tannery19_level_tax", cityId) else return delegate("world","set_tannery19_level_tax", cityId, v) end end
function M.tavern19_level_tax(cityId, v) if v==nil then return delegate("world","tavern19_level_tax", cityId) else return delegate("world","set_tavern19_level_tax", cityId, v) end end
function M.thieves_guild19_level_tax(cityId, v) if v==nil then return delegate("world","thieves_guild19_level_tax", cityId) else return delegate("world","set_thieves_guild19_level_tax", cityId, v) end end
function M.toolmaker19_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker19_level_tax", cityId) else return delegate("world","set_toolmaker19_level_tax", cityId, v) end end
function M.tower19_level_tax(cityId, v) if v==nil then return delegate("world","tower19_level_tax", cityId) else return delegate("world","set_tower19_level_tax", cityId, v) end end
function M.turner19_level_tax(cityId, v) if v==nil then return delegate("world","turner19_level_tax", cityId) else return delegate("world","set_turner19_level_tax", cityId, v) end end
function M.university_hall19_level_tax(cityId, v) if v==nil then return delegate("world","university_hall19_level_tax", cityId) else return delegate("world","set_university_hall19_level_tax", cityId, v) end end
function M.vineyard19_level_tax(cityId, v) if v==nil then return delegate("world","vineyard19_level_tax", cityId) else return delegate("world","set_vineyard19_level_tax", cityId, v) end end
function M.vintner19_level_tax(cityId, v) if v==nil then return delegate("world","vintner19_level_tax", cityId) else return delegate("world","set_vintner19_level_tax", cityId, v) end end
function M.warehouse19_level_tax(cityId, v) if v==nil then return delegate("world","warehouse19_level_tax", cityId) else return delegate("world","set_warehouse19_level_tax", cityId, v) end end
function M.weaving_mill19_level_tax(cityId, v) if v==nil then return delegate("world","weaving_mill19_level_tax", cityId) else return delegate("world","set_weaving_mill19_level_tax", cityId, v) end end
function M.well19_level_tax(cityId, v) if v==nil then return delegate("world","well19_level_tax", cityId) else return delegate("world","set_well19_level_tax", cityId, v) end end
function M.wall19_level_tax(cityId, v) if v==nil then return delegate("world","wall19_level_tax", cityId) else return delegate("world","set_wall19_level_tax", cityId, v) end end
function M.armorer20_level_tax(cityId, v) if v==nil then return delegate("world","armorer20_level_tax", cityId) else return delegate("world","set_armorer20_level_tax", cityId, v) end end
function M.baker20_level_tax(cityId, v) if v==nil then return delegate("world","baker20_level_tax", cityId) else return delegate("world","set_baker20_level_tax", cityId, v) end end
function M.barber20_level_tax(cityId, v) if v==nil then return delegate("world","barber20_level_tax", cityId) else return delegate("world","set_barber20_level_tax", cityId, v) end end
function M.bathhouse20_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse20_level_tax", cityId) else return delegate("world","set_bathhouse20_level_tax", cityId, v) end end
function M.bowyer20_level_tax(cityId, v) if v==nil then return delegate("world","bowyer20_level_tax", cityId) else return delegate("world","set_bowyer20_level_tax", cityId, v) end end
function M.brewmaster20_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster20_level_tax", cityId) else return delegate("world","set_brewmaster20_level_tax", cityId, v) end end
function M.brickmaker20_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker20_level_tax", cityId) else return delegate("world","set_brickmaker20_level_tax", cityId, v) end end
function M.bridge20_level_tax(cityId, v) if v==nil then return delegate("world","bridge20_level_tax", cityId) else return delegate("world","set_bridge20_level_tax", cityId, v) end end
function M.brothel20_level_tax(cityId, v) if v==nil then return delegate("world","brothel20_level_tax", cityId) else return delegate("world","set_brothel20_level_tax", cityId, v) end end
function M.butcher20_level_tax(cityId, v) if v==nil then return delegate("world","butcher20_level_tax", cityId) else return delegate("world","set_butcher20_level_tax", cityId, v) end end
function M.candlemaker20_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker20_level_tax", cityId) else return delegate("world","set_candlemaker20_level_tax", cityId, v) end end
function M.carpenter20_level_tax(cityId, v) if v==nil then return delegate("world","carpenter20_level_tax", cityId) else return delegate("world","set_carpenter20_level_tax", cityId, v) end end
function M.cartwright20_level_tax(cityId, v) if v==nil then return delegate("world","cartwright20_level_tax", cityId) else return delegate("world","set_cartwright20_level_tax", cityId, v) end end
function M.castle20_level_tax(cityId, v) if v==nil then return delegate("world","castle20_level_tax", cityId) else return delegate("world","set_castle20_level_tax", cityId, v) end end
function M.cathedral20_level_tax(cityId, v) if v==nil then return delegate("world","cathedral20_level_tax", cityId) else return delegate("world","set_cathedral20_level_tax", cityId, v) end end
function M.chandler20_level_tax(cityId, v) if v==nil then return delegate("world","chandler20_level_tax", cityId) else return delegate("world","set_chandler20_level_tax", cityId, v) end end
function M.chapel20_level_tax(cityId, v) if v==nil then return delegate("world","chapel20_level_tax", cityId) else return delegate("world","set_chapel20_level_tax", cityId, v) end end
function M.charcoal20_level_tax(cityId, v) if v==nil then return delegate("world","charcoal20_level_tax", cityId) else return delegate("world","set_charcoal20_level_tax", cityId, v) end end
function M.church20_level_tax(cityId, v) if v==nil then return delegate("world","church20_level_tax", cityId) else return delegate("world","set_church20_level_tax", cityId, v) end end
function M.cobbler20_level_tax(cityId, v) if v==nil then return delegate("world","cobbler20_level_tax", cityId) else return delegate("world","set_cobbler20_level_tax", cityId, v) end end
function M.contor20_level_tax(cityId, v) if v==nil then return delegate("world","contor20_level_tax", cityId) else return delegate("world","set_contor20_level_tax", cityId, v) end end
function M.cook20_level_tax(cityId, v) if v==nil then return delegate("world","cook20_level_tax", cityId) else return delegate("world","set_cook20_level_tax", cityId, v) end end
function M.cooper20_level_tax(cityId, v) if v==nil then return delegate("world","cooper20_level_tax", cityId) else return delegate("world","set_cooper20_level_tax", cityId, v) end end
function M.courthouse20_level_tax(cityId, v) if v==nil then return delegate("world","courthouse20_level_tax", cityId) else return delegate("world","set_courthouse20_level_tax", cityId, v) end end
function M.dairy20_level_tax(cityId, v) if v==nil then return delegate("world","dairy20_level_tax", cityId) else return delegate("world","set_dairy20_level_tax", cityId, v) end end
function M.dice_house20_level_tax(cityId, v) if v==nil then return delegate("world","dice_house20_level_tax", cityId) else return delegate("world","set_dice_house20_level_tax", cityId, v) end end
function M.distiller20_level_tax(cityId, v) if v==nil then return delegate("world","distiller20_level_tax", cityId) else return delegate("world","set_distiller20_level_tax", cityId, v) end end
function M.dyer20_level_tax(cityId, v) if v==nil then return delegate("world","dyer20_level_tax", cityId) else return delegate("world","set_dyer20_level_tax", cityId, v) end end
function M.fishery20_level_tax(cityId, v) if v==nil then return delegate("world","fishery20_level_tax", cityId) else return delegate("world","set_fishery20_level_tax", cityId, v) end end
function M.forum20_level_tax(cityId, v) if v==nil then return delegate("world","forum20_level_tax", cityId) else return delegate("world","set_forum20_level_tax", cityId, v) end end
function M.fowler20_level_tax(cityId, v) if v==nil then return delegate("world","fowler20_level_tax", cityId) else return delegate("world","set_fowler20_level_tax", cityId, v) end end
function M.furrier20_level_tax(cityId, v) if v==nil then return delegate("world","furrier20_level_tax", cityId) else return delegate("world","set_furrier20_level_tax", cityId, v) end end
function M.garrison20_level_tax(cityId, v) if v==nil then return delegate("world","garrison20_level_tax", cityId) else return delegate("world","set_garrison20_level_tax", cityId, v) end end
function M.gates20_level_tax(cityId, v) if v==nil then return delegate("world","gates20_level_tax", cityId) else return delegate("world","set_gates20_level_tax", cityId, v) end end
function M.glassblower20_level_tax(cityId, v) if v==nil then return delegate("world","glassblower20_level_tax", cityId) else return delegate("world","set_glassblower20_level_tax", cityId, v) end end
function M.goldbeater20_level_tax(cityId, v) if v==nil then return delegate("world","goldbeater20_level_tax", cityId) else return delegate("world","set_goldbeater20_level_tax", cityId, v) end end
function M.goldsmith20_level_tax(cityId, v) if v==nil then return delegate("world","goldsmith20_level_tax", cityId) else return delegate("world","set_goldsmith20_level_tax", cityId, v) end end
function M.granary20_level_tax(cityId, v) if v==nil then return delegate("world","granary20_level_tax", cityId) else return delegate("world","set_granary20_level_tax", cityId, v) end end
function M.guardhouse20_level_tax(cityId, v) if v==nil then return delegate("world","guardhouse20_level_tax", cityId) else return delegate("world","set_guardhouse20_level_tax", cityId, v) end end
function M.guild_house20_level_tax(cityId, v) if v==nil then return delegate("world","guild_house20_level_tax", cityId) else return delegate("world","set_guild_house20_level_tax", cityId, v) end end
function M.harbor20_level_tax(cityId, v) if v==nil then return delegate("world","harbor20_level_tax", cityId) else return delegate("world","set_harbor20_level_tax", cityId, v) end end
function M.harbor_dock20_level_tax(cityId, v) if v==nil then return delegate("world","harbor_dock20_level_tax", cityId) else return delegate("world","set_harbor_dock20_level_tax", cityId, v) end end
function M.harbor_walls20_level_tax(cityId, v) if v==nil then return delegate("world","harbor_walls20_level_tax", cityId) else return delegate("world","set_harbor_walls20_level_tax", cityId, v) end end
function M.herb_garden20_level_tax(cityId, v) if v==nil then return delegate("world","herb_garden20_level_tax", cityId) else return delegate("world","set_herb_garden20_level_tax", cityId, v) end end
function M.hospital20_level_tax(cityId, v) if v==nil then return delegate("world","hospital20_level_tax", cityId) else return delegate("world","set_hospital20_level_tax", cityId, v) end end
function M.house20_level_tax(cityId, v) if v==nil then return delegate("world","house20_level_tax", cityId) else return delegate("world","set_house20_level_tax", cityId, v) end end
function M.jeweler20_level_tax(cityId, v) if v==nil then return delegate("world","jeweler20_level_tax", cityId) else return delegate("world","set_jeweler20_level_tax", cityId, v) end end
function M.library20_level_tax(cityId, v) if v==nil then return delegate("world","library20_level_tax", cityId) else return delegate("world","set_library20_level_tax", cityId, v) end end
function M.library_hall20_level_tax(cityId, v) if v==nil then return delegate("world","library_hall20_level_tax", cityId) else return delegate("world","set_library_hall20_level_tax", cityId, v) end end
function M.market20_level_tax(cityId, v) if v==nil then return delegate("world","market20_level_tax", cityId) else return delegate("world","set_market20_level_tax", cityId, v) end end
function M.miller20_level_tax(cityId, v) if v==nil then return delegate("world","miller20_level_tax", cityId) else return delegate("world","set_miller20_level_tax", cityId, v) end end
function M.mine20_level_tax(cityId, v) if v==nil then return delegate("world","mine20_level_tax", cityId) else return delegate("world","set_mine20_level_tax", cityId, v) end end
function M.mint20_level_tax(cityId, v) if v==nil then return delegate("world","mint20_level_tax", cityId) else return delegate("world","set_mint20_level_tax", cityId, v) end end
function M.monastery20_level_tax(cityId, v) if v==nil then return delegate("world","monastery20_level_tax", cityId) else return delegate("world","set_monastery20_level_tax", cityId, v) end end
function M.papermill20_level_tax(cityId, v) if v==nil then return delegate("world","papermill20_level_tax", cityId) else return delegate("world","set_papermill20_level_tax", cityId, v) end end
function M.perfumer20_level_tax(cityId, v) if v==nil then return delegate("world","perfumer20_level_tax", cityId) else return delegate("world","set_perfumer20_level_tax", cityId, v) end end
function M.potter20_level_tax(cityId, v) if v==nil then return delegate("world","potter20_level_tax", cityId) else return delegate("world","set_potter20_level_tax", cityId, v) end end
function M.pottery20_level_tax(cityId, v) if v==nil then return delegate("world","pottery20_level_tax", cityId) else return delegate("world","set_pottery20_level_tax", cityId, v) end end
function M.printing_house20_level_tax(cityId, v) if v==nil then return delegate("world","printing_house20_level_tax", cityId) else return delegate("world","set_printing_house20_level_tax", cityId, v) end end
function M.ropemaker20_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker20_level_tax", cityId) else return delegate("world","set_ropemaker20_level_tax", cityId, v) end end
function M.ropemaker_workshop20_level_tax(cityId, v) if v==nil then return delegate("world","ropemaker_workshop20_level_tax", cityId) else return delegate("world","set_ropemaker_workshop20_level_tax", cityId, v) end end
function M.saddler20_level_tax(cityId, v) if v==nil then return delegate("world","saddler20_level_tax", cityId) else return delegate("world","set_saddler20_level_tax", cityId, v) end end
function M.school20_level_tax(cityId, v) if v==nil then return delegate("world","school20_level_tax", cityId) else return delegate("world","set_school20_level_tax", cityId, v) end end
function M.schoolhouse20_level_tax(cityId, v) if v==nil then return delegate("world","schoolhouse20_level_tax", cityId) else return delegate("world","set_schoolhouse20_level_tax", cityId, v) end end
function M.sentry_tower20_level_tax(cityId, v) if v==nil then return delegate("world","sentry_tower20_level_tax", cityId) else return delegate("world","set_sentry_tower20_level_tax", cityId, v) end end
function M.stables20_level_tax(cityId, v) if v==nil then return delegate("world","stables20_level_tax", cityId) else return delegate("world","set_stables20_level_tax", cityId, v) end end
function M.stonecutter20_level_tax(cityId, v) if v==nil then return delegate("world","stonecutter20_level_tax", cityId) else return delegate("world","set_stonecutter20_level_tax", cityId, v) end end
function M.tailor20_level_tax(cityId, v) if v==nil then return delegate("world","tailor20_level_tax", cityId) else return delegate("world","set_tailor20_level_tax", cityId, v) end end
function M.tannery20_level_tax(cityId, v) if v==nil then return delegate("world","tannery20_level_tax", cityId) else return delegate("world","set_tannery20_level_tax", cityId, v) end end
function M.tavern20_level_tax(cityId, v) if v==nil then return delegate("world","tavern20_level_tax", cityId) else return delegate("world","set_tavern20_level_tax", cityId, v) end end
function M.thieves_guild20_level_tax(cityId, v) if v==nil then return delegate("world","thieves_guild20_level_tax", cityId) else return delegate("world","set_thieves_guild20_level_tax", cityId, v) end end
function M.toolmaker20_level_tax(cityId, v) if v==nil then return delegate("world","toolmaker20_level_tax", cityId) else return delegate("world","set_toolmaker20_level_tax", cityId, v) end end
function M.tower20_level_tax(cityId, v) if v==nil then return delegate("world","tower20_level_tax", cityId) else return delegate("world","set_tower20_level_tax", cityId, v) end end
function M.turner20_level_tax(cityId, v) if v==nil then return delegate("world","turner20_level_tax", cityId) else return delegate("world","set_turner20_level_tax", cityId, v) end end
function M.university_hall20_level_tax(cityId, v) if v==nil then return delegate("world","university_hall20_level_tax", cityId) else return delegate("world","set_university_hall20_level_tax", cityId, v) end end
function M.vineyard20_level_tax(cityId, v) if v==nil then return delegate("world","vineyard20_level_tax", cityId) else return delegate("world","set_vineyard20_level_tax", cityId, v) end end
function M.vintner20_level_tax(cityId, v) if v==nil then return delegate("world","vintner20_level_tax", cityId) else return delegate("world","set_vintner20_level_tax", cityId, v) end end
function M.wall20_level_tax(cityId, v) if v==nil then return delegate("world","wall20_level_tax", cityId) else return delegate("world","set_wall20_level_tax", cityId, v) end end
function M.warehouse20_level_tax(cityId, v) if v==nil then return delegate("world","warehouse20_level_tax", cityId) else return delegate("world","set_warehouse20_level_tax", cityId, v) end end
function M.weaving_mill20_level_tax(cityId, v) if v==nil then return delegate("world","weaving_mill20_level_tax", cityId) else return delegate("world","set_weaving_mill20_level_tax", cityId, v) end end
function M.well20_level_tax(cityId, v) if v==nil then return delegate("world","well20_level_tax", cityId) else return delegate("world","set_well20_level_tax", cityId, v) end end
function M.warehouse14_level_tax(cityId, v) if v==nil then return delegate("world","warehouse14_level_tax", cityId) else return delegate("world","set_warehouse14_level_tax", cityId, v) end end
function M.weaving_mill14_level_tax(cityId, v) if v==nil then return delegate("world","weaving_mill14_level_tax", cityId) else return delegate("world","set_weaving_mill14_level_tax", cityId, v) end end
function M.well14_level_tax(cityId, v) if v==nil then return delegate("world","well14_level_tax", cityId) else return delegate("world","set_well14_level_tax", cityId, v) end end
function M.armorer14_level_tax(cityId, v) if v==nil then return delegate("world","armorer14_level_tax", cityId) else return delegate("world","set_armorer14_level_tax", cityId, v) end end
function M.baker14_level_tax(cityId, v) if v==nil then return delegate("world","baker14_level_tax", cityId) else return delegate("world","set_baker14_level_tax", cityId, v) end end
function M.barber14_level_tax(cityId, v) if v==nil then return delegate("world","barber14_level_tax", cityId) else return delegate("world","set_barber14_level_tax", cityId, v) end end
function M.bathhouse14_level_tax(cityId, v) if v==nil then return delegate("world","bathhouse14_level_tax", cityId) else return delegate("world","set_bathhouse14_level_tax", cityId, v) end end
function M.bowyer14_level_tax(cityId, v) if v==nil then return delegate("world","bowyer14_level_tax", cityId) else return delegate("world","set_bowyer14_level_tax", cityId, v) end end
function M.brewmaster14_level_tax(cityId, v) if v==nil then return delegate("world","brewmaster14_level_tax", cityId) else return delegate("world","set_brewmaster14_level_tax", cityId, v) end end
function M.brickmaker14_level_tax(cityId, v) if v==nil then return delegate("world","brickmaker14_level_tax", cityId) else return delegate("world","set_brickmaker14_level_tax", cityId, v) end end
function M.bridge14_level_tax(cityId, v) if v==nil then return delegate("world","bridge14_level_tax", cityId) else return delegate("world","set_bridge14_level_tax", cityId, v) end end
function M.brothel14_level_tax(cityId, v) if v==nil then return delegate("world","brothel14_level_tax", cityId) else return delegate("world","set_brothel14_level_tax", cityId, v) end end
function M.butcher14_level_tax(cityId, v) if v==nil then return delegate("world","butcher14_level_tax", cityId) else return delegate("world","set_butcher14_level_tax", cityId, v) end end
function M.candlemaker14_level_tax(cityId, v) if v==nil then return delegate("world","candlemaker14_level_tax", cityId) else return delegate("world","set_candlemaker14_level_tax", cityId, v) end end
function M.carpenter14_level_tax(cityId, v) if v==nil then return delegate("world","carpenter14_level_tax", cityId) else return delegate("world","set_carpenter14_level_tax", cityId, v) end end
function M.cartwright14_level_tax(cityId, v) if v==nil then return delegate("world","cartwright14_level_tax", cityId) else return delegate("world","set_cartwright14_level_tax", cityId, v) end end
function M.castle14_level_tax(cityId, v) if v==nil then return delegate("world","castle14_level_tax", cityId) else return delegate("world","set_castle14_level_tax", cityId, v) end end
function M.cathedral14_level_tax(cityId, v) if v==nil then return delegate("world","cathedral14_level_tax", cityId) else return delegate("world","set_cathedral14_level_tax", cityId, v) end end
function M.chandler14_level_tax(cityId, v) if v==nil then return delegate("world","chandler14_level_tax", cityId) else return delegate("world","set_chandler14_level_tax", cityId, v) end end
function M.chapel14_level_tax(cityId, v) if v==nil then return delegate("world","chapel14_level_tax", cityId) else return delegate("world","set_chapel14_level_tax", cityId, v) end end
function M.charcoal14_level_tax(cityId, v) if v==nil then return delegate("world","charcoal14_level_tax", cityId) else return delegate("world","set_charcoal14_level_tax", cityId, v) end end
function M.contor_tax(cityId, v) if v==nil then return delegate("world","contor_tax", cityId) else return delegate("world","set_contor_tax", cityId, v) end end
function M.dice_house_tax(cityId, v) if v==nil then return delegate("world","dice_house_tax", cityId) else return delegate("world","set_dice_house_tax", cityId, v) end end
function M.thieves_guild_tax(cityId, v) if v==nil then return delegate("world","thieves_guild_tax", cityId) else return delegate("world","set_thieves_guild_tax", cityId, v) end end
function M.harbor_walls_tax3(cityId, v) if v==nil then return delegate("world","harbor_walls_tax3", cityId) else return delegate("world","set_harbor_walls_tax3", cityId, v) end end
function M.brothel(cityId, v) if v==nil then return delegate("world","brothel", cityId) else return delegate("world","set_brothel", cityId, v) end end
function M.harbor_walls(cityId, v) if v==nil then return delegate("world","harbor_walls", cityId) else return delegate("world","set_harbor_walls", cityId, v) end end
function M.schoolhouse(cityId, v) if v==nil then return delegate("world","schoolhouse", cityId) else return delegate("world","set_schoolhouse", cityId, v) end end
function M.library_hall(cityId, v) if v==nil then return delegate("world","library_hall", cityId) else return delegate("world","set_library_hall", cityId, v) end end
function M.barber_level(cityId, v) if v==nil then return delegate("world","barber_level", cityId) else return delegate("world","set_barber_level", cityId, v) end end
function M.contor(cityId, v) if v==nil then return delegate("world","contor", cityId) else return delegate("world","set_contor", cityId, v) end end
function M.dice_house(cityId, v) if v==nil then return delegate("world","dice_house", cityId) else return delegate("world","set_dice_house", cityId, v) end end
function M.thieves(cityId, v) if v==nil then return delegate("world","thieves", cityId) else return delegate("world","set_thieves", cityId, v) end end
function M.ropemaker_workshop(cityId, v) if v==nil then return delegate("world","ropemaker_workshop", cityId) else return delegate("world","set_ropemaker_workshop", cityId, v) end end
function M.tannery(cityId, v) if v==nil then return delegate("world","tannery", cityId) else return delegate("world","set_tannery", cityId, v) end end
function M.weaving_mill(cityId, v) if v==nil then return delegate("world","weaving_mill", cityId) else return delegate("world","set_weaving_mill", cityId, v) end end
function M.mint(cityId, v) if v==nil then return delegate("world","mint", cityId) else return delegate("world","set_mint", cityId, v) end end
function M.herb_garden(cityId, v) if v==nil then return delegate("world","herb_garden", cityId) else return delegate("world","set_herb_garden", cityId, v) end end
function M.vineyard(cityId, v) if v==nil then return delegate("world","vineyard", cityId) else return delegate("world","set_vineyard", cityId, v) end end
function M.pottery(cityId, v) if v==nil then return delegate("world","pottery", cityId) else return delegate("world","set_pottery", cityId, v) end end
function M.tailor(cityId, v) if v==nil then return delegate("world","tailor", cityId) else return delegate("world","set_tailor", cityId, v) end end
function M.apothecary_level(cityId, v) if v==nil then return delegate("world","apothecary_level", cityId) else return delegate("world","set_apothecary_level", cityId, v) end end
function M.goldsmith_level(cityId, v) if v==nil then return delegate("world","goldsmith_level", cityId) else return delegate("world","set_goldsmith_level", cityId, v) end end
function M.jeweler_level(cityId, v) if v==nil then return delegate("world","jeweler_level", cityId) else return delegate("world","set_jeweler_level", cityId, v) end end
function M.perfumer_level(cityId, v) if v==nil then return delegate("world","perfumer_level", cityId) else return delegate("world","set_perfumer_level", cityId, v) end end
function M.soapmaker_level(cityId, v) if v==nil then return delegate("world","soapmaker_level", cityId) else return delegate("world","set_soapmaker_level", cityId, v) end end
function M.candlemaker_level(cityId, v) if v==nil then return delegate("world","candlemaker_level", cityId) else return delegate("world","set_candlemaker_level", cityId, v) end end
function M.papermill_level(cityId, v) if v==nil then return delegate("world","papermill_level", cityId) else return delegate("world","set_papermill_level", cityId, v) end end
function M.printing_house(cityId, v) if v==nil then return delegate("world","printing_house", cityId) else return delegate("world","set_printing_house", cityId, v) end end
function M.toolmaker_level(cityId, v) if v==nil then return delegate("world","toolmaker_level", cityId) else return delegate("world","set_toolmaker_level", cityId, v) end end
function M.charcoal_level(cityId, v) if v==nil then return delegate("world","charcoal_level", cityId) else return delegate("world","set_charcoal_level", cityId, v) end end
function M.furrier_level(cityId, v) if v==nil then return delegate("world","furrier_level", cityId) else return delegate("world","set_furrier_level", cityId, v) end end
function M.dyer_level(cityId, v) if v==nil then return delegate("world","dyer_level", cityId) else return delegate("world","set_dyer_level", cityId, v) end end
function M.saddler_level(cityId, v) if v==nil then return delegate("world","saddler_level", cityId) else return delegate("world","set_saddler_level", cityId, v) end end
function M.armorer_level(cityId, v) if v==nil then return delegate("world","armorer_level", cityId) else return delegate("world","set_armorer_level", cityId, v) end end
function M.bowyer_level(cityId, v) if v==nil then return delegate("world","bowyer_level", cityId) else return delegate("world","set_bowyer_level", cityId, v) end end
function M.cartwright_level(cityId, v) if v==nil then return delegate("world","cartwright_level", cityId) else return delegate("world","set_cartwright_level", cityId, v) end end
function M.carpenter_level(cityId, v) if v==nil then return delegate("world","carpenter_level", cityId) else return delegate("world","set_carpenter_level", cityId, v) end end
function M.ropemaker_level(cityId, v) if v==nil then return delegate("world","ropemaker_level", cityId) else return delegate("world","set_ropemaker_level", cityId, v) end end
function M.cooper_level(cityId, v) if v==nil then return delegate("world","cooper_level", cityId) else return delegate("world","set_cooper_level", cityId, v) end end
function M.spinner_level(cityId, v) if v==nil then return delegate("world","spinner_level", cityId) else return delegate("world","set_spinner_level", cityId, v) end end
function M.turner_level(cityId, v) if v==nil then return delegate("world","turner_level", cityId) else return delegate("world","set_turner_level", cityId, v) end end
function M.stonecutter_level(cityId, v) if v==nil then return delegate("world","stonecutter_level", cityId) else return delegate("world","set_stonecutter_level", cityId, v) end end
function M.cobbler_level(cityId, v) if v==nil then return delegate("world","cobbler_level", cityId) else return delegate("world","set_cobbler_level", cityId, v) end end
function M.butcher_level(cityId, v) if v==nil then return delegate("world","butcher_level", cityId) else return delegate("world","set_butcher_level", cityId, v) end end
function M.baker_level(cityId, v) if v==nil then return delegate("world","baker_level", cityId) else return delegate("world","set_baker_level", cityId, v) end end
function M.shepherd_level(cityId, v) if v==nil then return delegate("world","shepherd_level", cityId) else return delegate("world","set_shepherd_level", cityId, v) end end
function M.dairy_level(cityId, v) if v==nil then return delegate("world","dairy_level", cityId) else return delegate("world","set_dairy_level", cityId, v) end end
function M.brewmaster_level(cityId, v) if v==nil then return delegate("world","brewmaster_level", cityId) else return delegate("world","set_brewmaster_level", cityId, v) end end
function M.miller_level(cityId, v) if v==nil then return delegate("world","miller_level", cityId) else return delegate("world","set_miller_level", cityId, v) end end
function M.fishery_level(cityId, v) if v==nil then return delegate("world","fishery_level", cityId) else return delegate("world","set_fishery_level", cityId, v) end end
function M.chandler_level(cityId, v) if v==nil then return delegate("world","chandler_level", cityId) else return delegate("world","set_chandler_level", cityId, v) end end
function M.goldbeater_level(cityId, v) if v==nil then return delegate("world","goldbeater_level", cityId) else return delegate("world","set_goldbeater_level", cityId, v) end end
function M.potter_level(cityId, v) if v==nil then return delegate("world","potter_level", cityId) else return delegate("world","set_potter_level", cityId, v) end end
function M.fowler_level(cityId, v) if v==nil then return delegate("world","fowler_level", cityId) else return delegate("world","set_fowler_level", cityId, v) end end
function M.vintner_level(cityId, v) if v==nil then return delegate("world","vintner_level", cityId) else return delegate("world","set_vintner_level", cityId, v) end end
function M.distiller_level(cityId, v) if v==nil then return delegate("world","distiller_level", cityId) else return delegate("world","set_distiller_level", cityId, v) end end
function M.cook_level(cityId, v) if v==nil then return delegate("world","cook_level", cityId) else return delegate("world","set_cook_level", cityId, v) end end
function M.brickmaker_level(cityId, v) if v==nil then return delegate("world","brickmaker_level", cityId) else return delegate("world","set_brickmaker_level", cityId, v) end end
function M.tavern_level2(cityId, v) if v==nil then return delegate("world","tavern_level2", cityId) else return delegate("world","set_tavern_level2", cityId, v) end end
function M.mill_level(cityId, v) if v==nil then return delegate("world","mill_level", cityId) else return delegate("world","set_mill_level", cityId, v) end end
function M.brewery_tavern(cityId, v) if v==nil then return delegate("world","brewery_tavern", cityId) else return delegate("world","set_brewery_tavern", cityId, v) end end
function M.smith_level(cityId, v) if v==nil then return delegate("world","smith_level", cityId) else return delegate("world","set_smith_level", cityId, v) end end
function M.carpenters(cityId, v) if v==nil then return delegate("world","carpenters", cityId) else return delegate("world","set_carpenters", cityId, v) end end
function M.tailor_workshop(cityId, v) if v==nil then return delegate("world","tailor_workshop", cityId) else return delegate("world","set_tailor_workshop", cityId, v) end end
function M.joiner_workshop(cityId, v) if v==nil then return delegate("world","joiner_workshop", cityId) else return delegate("world","set_joiner_workshop", cityId, v) end end
function M.carter_workshop(cityId, v) if v==nil then return delegate("world","carter_workshop", cityId) else return delegate("world","set_carter_workshop", cityId, v) end end
function M.mining_workshop(cityId, v) if v==nil then return delegate("world","mining_workshop", cityId) else return delegate("world","set_mining_workshop", cityId, v) end end
function M.logging_workshop(cityId, v) if v==nil then return delegate("world","logging_workshop", cityId) else return delegate("world","set_logging_workshop", cityId, v) end end
function M.inn_level(cityId, v) if v==nil then return delegate("world","inn_level", cityId) else return delegate("world","set_inn_level", cityId, v) end end
function M.robber_camp(cityId, v) if v==nil then return delegate("world","robber_camp", cityId) else return delegate("world","set_robber_camp", cityId, v) end end
function M.joiner_ws2(cityId, v) if v==nil then return delegate("world","joiner_ws2", cityId) else return delegate("world","set_joiner_ws2", cityId, v) end end
function M.carter_ws2(cityId, v) if v==nil then return delegate("world","carter_ws2", cityId) else return delegate("world","set_carter_ws2", cityId, v) end end
function M.mining_ws2(cityId, v) if v==nil then return delegate("world","mining_ws2", cityId) else return delegate("world","set_mining_ws2", cityId, v) end end
function M.logging_ws2(cityId, v) if v==nil then return delegate("world","logging_ws2", cityId) else return delegate("world","set_logging_ws2", cityId, v) end end
function M.inn_level2(cityId, v) if v==nil then return delegate("world","inn_level2", cityId) else return delegate("world","set_inn_level2", cityId, v) end end
function M.robber_camp2(cityId, v) if v==nil then return delegate("world","robber_camp2", cityId) else return delegate("world","set_robber_camp2", cityId, v) end end
function M.toll_gate_level(cityId, v) if v==nil then return delegate("world","toll_gate_level", cityId) else return delegate("world","set_toll_gate_level", cityId, v) end end
function M.road_level(cityId, v) if v==nil then return delegate("world","road_level", cityId) else return delegate("world","set_road_level", cityId, v) end end
function M.toll_gate_tax(cityId, v) if v==nil then return delegate("world","toll_gate_tax", cityId) else return delegate("world","set_toll_gate_tax", cityId, v) end end
function M.bridge_cost(cityId) return delegate("world","bridge_cost", cityId) end
function M.dock_tax(cityId, v) if v==nil then return delegate("world","dock_tax", cityId) else return delegate("world","set_dock_tax", cityId, v) end end
function M.harbor_walls_tax(cityId, v) if v==nil then return delegate("world","harbor_walls_tax", cityId) else return delegate("world","set_harbor_walls_tax", cityId, v) end end
function M.forum_tax(cityId, v) if v==nil then return delegate("world","forum_tax", cityId) else return delegate("world","set_forum_tax", cityId, v) end end
function M.granary_tax(cityId, v) if v==nil then return delegate("world","granary_tax", cityId) else return delegate("world","set_granary_tax", cityId, v) end end
function M.guild_house_tax(cityId, v) if v==nil then return delegate("world","guild_house_tax", cityId) else return delegate("world","set_guild_house_tax", cityId, v) end end
function M.house_tax(cityId, v) if v==nil then return delegate("world","house_tax", cityId) else return delegate("world","set_house_tax", cityId, v) end end
function M.chapel_tax(cityId, v) if v==nil then return delegate("world","chapel_tax", cityId) else return delegate("world","set_chapel_tax", cityId, v) end end
function M.hospital_tax(cityId, v) if v==nil then return delegate("world","hospital_tax", cityId) else return delegate("world","set_hospital_tax", cityId, v) end end
function M.guild_tax(gid, cid) return delegate("economy","guild_tax", gid, cid) end
function M.pop_limit(cityId, v) if v==nil then return delegate("world","pop_limit", cityId) else return delegate("world","set_pop_limit", cityId, v) end end
function M.growth(cityId) return delegate("world","growth", cityId) end
function M.apothecary(bldg, gid, v) if v==nil then return delegate("building","apothecary_output", bldg, gid) else return delegate("building","set_apothecary_output", bldg, gid, v) end end
function M.scribe(bldg, gid, v) if v==nil then return delegate("building","scribe_output", bldg, gid) else return delegate("building","set_scribe_output", bldg, gid, v) end end
function M.goldsmith(bldg, gid) return delegate("building","goldsmith_output", bldg, gid) end
function M.falconer(bldg, gid) return delegate("building","falconer_yield", bldg, gid) end
function M.jeweler(bldg, gid, v) if v==nil then return delegate("building","jeweler_output", bldg, gid) else return delegate("building","set_jeweler_output", bldg, gid, v) end end
function M.bathhouse(bldg) return delegate("building","bathhouse_income", bldg) end
function M.perfumer(bldg, gid, v) if v==nil then return delegate("building","perfumer_output", bldg, gid) else return delegate("building","set_perfumer_output", bldg, gid, v) end end
function M.soapmaker(bldg, gid, v) if v==nil then return delegate("building","soapmaker_output", bldg, gid) else return delegate("building","set_soapmaker_output", bldg, gid, v) end end
function M.candlemaker(bldg, gid, v) if v==nil then return delegate("building","candlemaker_output", bldg, gid) else return delegate("building","set_candlemaker_output", bldg, gid, v) end end
function M.papermill(bldg, gid, v) if v==nil then return delegate("building","papermill_output", bldg, gid) else return delegate("building","set_papermill_output", bldg, gid, v) end end
function M.printing(bldg, gid, v) if v==nil then return delegate("building","printing_output", bldg, gid) else return delegate("building","set_printing_output", bldg, gid, v) end end
function M.toolmaker(bldg, gid, v) if v==nil then return delegate("building","toolmaker_output", bldg, gid) else return delegate("building","set_toolmaker_output", bldg, gid, v) end end
function M.charcoal(bldg, gid, v) if v==nil then return delegate("building","charcoal_output", bldg, gid) else return delegate("building","set_charcoal_output", bldg, gid, v) end end
function M.furrier(bldg, gid, v) if v==nil then return delegate("building","furrier_output", bldg, gid) else return delegate("building","set_furrier_output", bldg, gid, v) end end
function M.dyer(bldg, gid, v) if v==nil then return delegate("building","dyer_output", bldg, gid) else return delegate("building","set_dyer_output", bldg, gid, v) end end
function M.saddler(bldg, gid, v) if v==nil then return delegate("building","saddler_output", bldg, gid) else return delegate("building","set_saddler_output", bldg, gid, v) end end
function M.armorer(bldg, gid, v) if v==nil then return delegate("building","armorer_output", bldg, gid) else return delegate("building","set_armorer_output", bldg, gid, v) end end
function M.bowyer(bldg, gid, v) if v==nil then return delegate("building","bowyer_output", bldg, gid) else return delegate("building","set_bowyer_output", bldg, gid, v) end end
function M.cartwright(bldg, gid, v) if v==nil then return delegate("building","cartwright_output", bldg, gid) else return delegate("building","set_cartwright_output", bldg, gid, v) end end
function M.mint_out(bldg, gid, v) if v==nil then return delegate("building","mint_output", bldg, gid) else return delegate("building","set_mint_output", bldg, gid, v) end end
function M.winery(bldg, gid, v) if v==nil then return delegate("building","winery_output", bldg, gid) else return delegate("building","set_winery_output", bldg, gid, v) end end
function M.shipwright(bldg, gid, v) if v==nil then return delegate("building","shipwright_output", bldg, gid) else return delegate("building","set_shipwright_output", bldg, gid, v) end end
function M.cooper(bldg, gid, v) if v==nil then return delegate("building","cooper_output", bldg, gid) else return delegate("building","set_cooper_output", bldg, gid, v) end end
function M.spinner(bldg, gid, v) if v==nil then return delegate("building","spinner_output", bldg, gid) else return delegate("building","set_spinner_output", bldg, gid, v) end end
function M.turner(bldg, gid, v) if v==nil then return delegate("building","turner_output", bldg, gid) else return delegate("building","set_turner_output", bldg, gid, v) end end
function M.barber(bldg, gid, v) if v==nil then return delegate("building","barber_output", bldg, gid) else return delegate("building","set_barber_output", bldg, gid, v) end end
function M.stonecutter(bldg, gid, v) if v==nil then return delegate("building","stonecutter_output", bldg, gid) else return delegate("building","set_stonecutter_output", bldg, gid, v) end end
function M.tailor_master(bldg, gid, v) if v==nil then return delegate("building","tailor_master_output", bldg, gid) else return delegate("building","set_tailor_master_output", bldg, gid, v) end end
function M.cobbler(bldg, gid, v) if v==nil then return delegate("building","cobbler_output", bldg, gid) else return delegate("building","set_cobbler_output", bldg, gid, v) end end
function M.butcher(bldg, gid, v) if v==nil then return delegate("building","butcher_output", bldg, gid) else return delegate("building","set_butcher_output", bldg, gid, v) end end
function M.baker2(bldg, gid, v) if v==nil then return delegate("building","baker2_output", bldg, gid) else return delegate("building","set_baker2_output", bldg, gid, v) end end
function M.shepherd(bldg, gid) return delegate("building","shepherd_yield", bldg, gid) end
function M.dairy(bldg, gid) return delegate("building","dairy_yield", bldg, gid) end
function M.brewmaster(bldg, gid, v) if v==nil then return delegate("building","brewmaster_output", bldg, gid) else return delegate("building","set_brewmaster_output", bldg, gid, v) end end
function M.miller(bldg, gid) return delegate("building","miller_yield", bldg, gid) end
function M.fishery(bldg, gid) return delegate("building","fishery_yield", bldg, gid) end
function M.joiner(bldg, gid, v) if v==nil then return delegate("building","joiner_output", bldg, gid) else return delegate("building","set_joiner_output", bldg, gid, v) end end
function M.carter(bldg, gid, v) if v==nil then return delegate("building","carter_output", bldg, gid) else return delegate("building","set_carter_output", bldg, gid, v) end end
function M.mining(bldg, gid) return delegate("building","mining_yield", bldg, gid) end
function M.logging(bldg, gid) return delegate("building","logging_yield", bldg, gid) end
function M.innkeeper(bldg) return delegate("building","innkeeper_income", bldg) end
function M.tollmaster(bldg) return delegate("building","tollmaster_income", bldg) end
function M.chandler(bldg, gid, v) if v==nil then return delegate("building","chandler_output", bldg, gid) else return delegate("building","set_chandler_output", bldg, gid, v) end end
function M.goldbeater(bldg, gid, v) if v==nil then return delegate("building","goldbeater_output", bldg, gid) else return delegate("building","set_goldbeater_output", bldg, gid, v) end end
function M.potter(bldg, gid, v) if v==nil then return delegate("building","potter_output", bldg, gid) else return delegate("building","set_potter_output", bldg, gid, v) end end
function M.fowler(bldg, gid) return delegate("building","fowler_yield", bldg, gid) end
function M.vintner(bldg, gid) return delegate("building","vintner_output", bldg, gid) end
function M.road_toll(cityId, roadId, v) if v==nil then return delegate("world","road_toll", cityId, roadId) else return delegate("world","set_road_toll", cityId, roadId, v) end end
function M.church_corruption(cityId, v) if v==nil then return delegate("world","church_corruption", cityId) else return delegate("world","set_church_corruption", cityId, v) end end
function M.stall_rent(cityId, stype) return delegate("world","stall_rent", cityId, stype) end
function M.church_tax(cityId, v) if v==nil then return delegate("world","church_tax", cityId) else return delegate("world","set_church_tax", cityId, v) end end
function M.dowry(pid, s) return delegate("social","dowry", pid, s) end
function M.wedding(pid, t) return delegate("social","wedding", pid, t) end
function M.patrician(pid, cid) return delegate("social","patrician", pid, cid) end

-- record a player address for cheat.gold fallback
function M.set_player_addr(addr)
    local n = addr
    if type(addr) == "string" then
        local s = addr:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^0[xX]", "")
        n = tonumber(s, 16)
        if not n then error("invalid addr: " .. tostring(addr)) end
    end
    _G._cheat_player_addr = n
    print(string.format("cheat player addr -> 0x%08X", n))
    return n
end

function M.help()
    print("cheat.* quick cheats:")
    print("  cheat.gold(n)  cheat.fame(n)  cheat.health(pid,n)  cheat.faith(pid[,v])  cheat.prestige(pid[,v])")
    print("  cheat.time(h)  cheat.year(y)  cheat.speed(v)  cheat.difficulty(v)")
    print("  cheat.city_owner(cid,owner)  cheat.office(cid,oid,pid)  cheat.guard(cid[,n])")
    print("  cheat.tax(cid,gid,rate)  cheat.market(gid,cid,price)  cheat.guild_balance(gid,n)")
    print("  cheat.stock(pid,sid[,n])  cheat.income(pid[,n])  cheat.bribe(cid,oid[,price])")
    print("  cheat.quest_start(id,owner)  cheat.quest_done(id)  cheat.quest_fail(id)")
    print("  cheat.set_player_addr(addr)  -- remember player struct for gold fallback")
    print("  cheat.crime(pid[,lvl])  cheat.votes(cid,cand[,n])  cheat.efficiency(bldg[,pct])")
    print("  cheat.intrigue(pid,tid[,lvl])  cheat.title(pid,tid)  cheat.influence(pid,cid[,v])")
    print("  cheat.warehouse(bldg[,cap])  cheat.title_cost(tid)  cheat.upkeep(bldg[,cost])  cheat.disease(pid[,v])")
    print("  cheat.supply(cid,gid[,v])  cheat.demand(cid,gid[,v])  cheat.profit(a,b,good)  cheat.relation(a,b[,v])")
    print("  cheat.tithe(cid[,v])  cheat.piety(pid[,v])  cheat.court_favor(pid,nid[,v])  cheat.guild_master(gid[,pid])")
    print("  cheat.cart_goods(cart,gid)  cheat.bribe_success(pid,cid,oid)")
    print("  cheat.debt(pid[,v])  cheat.bank(pid[,v])  cheat.loan(pid,loanId[,v])  cheat.interest(cid[,v])")
    print("  cheat.dynasty_rep(did[,v])  cheat.family_wealth(fid[,v])  cheat.building_tax(bldg[,v])  cheat.worker_skill(wid,sid[,v])")
    print("  cheat.court_level(pid,lvl[,v])  cheat.assassin(pid[,v])  cheat.warrant(pid)  cheat.verdict(tid[,v])")
    print("  cheat.poison(pid[,v])  cheat.drunk(pid[,v])  cheat.title_tier(tid)  cheat.evidence(pid)  cheat.jail(pid[,v])  cheat.public_order(cid[,v])")
    print("  cheat.city_favor(cid,pid[,v])  cheat.office_term(cid,oid[,v])  cheat.guild_fee(gid[,v])")
    print("  cheat.harvest(bldg,gid[,v])  cheat.servants(bldg)  cheat.slots(bldg)  cheat.militia(cid[,v])  cheat.wall(cid[,v])")
    print("  cheat.wage(bldg,wtype[,v])  cheat.witnesses(tid)  cheat.spy_net(pid,cid)  cheat.age(pid[,v])  cheat.heir(pid[,v])")
    print("  cheat.rent(bldg[,v])  cheat.defense(cid[,v])  cheat.trait(pid,tid[,v])  cheat.kidnap(a,b)  cheat.ransom(pid[,v])")
    print("  cheat.unrest(cid[,v])  cheat.security(bldg)  cheat.honor(pid[,v])  cheat.bvalue(bldg)")
    print("  cheat.prosperity(cid[,v])  cheat.salary(cid,oid[,v])  cheat.papal(pid[,v])  cheat.heretic(pid[,v])")
    print("  cheat.guard_level(cart)  cheat.blessing(bldg[,v])  cheat.trade_rep(pid,cid[,v])  cheat.feast(pid,ftype)")
    print("  cheat.favor_debt(a,b[,v])  cheat.ambassador(pid[,v])  cheat.festival(cid)  cheat.food(cid[,v])")
    print("  cheat.accident(bldg[,v])  cheat.fire_risk(bldg)  cheat.bounty(pid[,v])  cheat.charter(gid)")
    print("  cheat.corruption(cid[,v])  cheat.bribe_cooldown(pid,cid,oid)  cheat.xp(pid[,v])  cheat.donation(pid[,v])  cheat.strikes(bldg)")
    print("  cheat.bandit(cid[,v])  cheat.spy_suspicion(pid,cid[,v])  cheat.prod_bonus(bldg,gid[,v])  cheat.noble_house(pid[,v])")
    print("  cheat.route_profit(a,b,good)  cheat.caravan(cart)  cheat.nepotism(pid,oid[,v])  cheat.bishop(pid,did)")
    print("  cheat.btax(bldg[,v])  cheat.road(cid)  cheat.imperial(pid[,v])  cheat.tavern(pid,cid)  cheat.monastery(pid,cid)")
    print("  cheat.title_rank(pid,tid)  cheat.plague(cid[,v])  cheat.apprentice_slots(bldg)")
    print("  cheat.wall_cost(cid,lvl)  cheat.fair(cid)  cheat.granary(bldg)  cheat.baker_bonus(bldg,gid[,v])")
    print("  cheat.master_bribe(bldg)  cheat.gambling_debt(pid[,v])  cheat.sin(pid[,v])  cheat.confession(pid,lvl)  cheat.excommunication(pid[,v])")
    print("  cheat.promotion_cost(gid,lvl)  cheat.upgrade_cost(bldg,uid)  cheat.tax_income(cid)  cheat.university(cid[,v])  cheat.guard_morale(cid[,v])")
    print("  cheat.pilgrimage(pid,t)  cheat.relic(rid)  cheat.crusade(pid,cid[,v])  cheat.joust(pid,t)  cheat.tournament(pid,tid)  cheat.inquisition(pid[,v])")
    print("  cheat.brewery(bldg,gid[,v])  cheat.militia_upkeep(cid)  cheat.smuggler(cid,gid)  cheat.mill(bldg,gid[,v])  cheat.harbor_fee(cid,gid)  cheat.festival_cost(cid,ftype)")
    print("  cheat.cartel(pid,cid)  cheat.fence(pid,gid)  cheat.jester(pid)  cheat.bard(pid,cid)  cheat.dowry(pid,s)  cheat.wedding(pid,t)  cheat.patrician(pid,cid)")
    print("  cheat.stall_rent(cid,t)  cheat.church_tax(cid[,v])  cheat.blacksmith(bldg,gid[,v])  cheat.tannery(bldg,gid[,v])  cheat.weaver(bldg,gid[,v])  cheat.mint(bldg)  cheat.herb(bldg,gid)  cheat.market_fee(cid[,v])  cheat.vineyard(bldg,gid[,v])  cheat.pottery(bldg,gid[,v])  cheat.tailor(bldg,gid[,v])  cheat.fishing(bldg,gid)  cheat.orchard(bldg,gid)")
    print("  cheat.joiner(bldg,gid[,v])  cheat.carter(bldg,gid[,v])  cheat.mining(bldg,gid)  cheat.logging(bldg,gid)  cheat.innkeeper(bldg)  cheat.tollmaster(bldg)")
    print("  cheat.town_hall(cid[,v])  cheat.church_level(cid[,v])  cheat.market_level(cid[,v])  cheat.tavern_level(cid[,v])  cheat.library(cid[,v])  cheat.school(cid[,v])  cheat.dock(cid[,v])  cheat.armory(cid[,v])  cheat.warehouse_level(cid[,v])  cheat.mine(cid[,v])  cheat.garrison_level(cid[,v])  cheat.bathhouse_level(cid[,v])  cheat.harbor_master(cid[,v])  cheat.guardhouse(cid[,v])  cheat.courthouse(cid[,v])  cheat.univ_hall(cid[,v])  cheat.castle(cid[,v])  cheat.cathedral_level(cid[,v])  cheat.monastery_level(cid[,v])  cheat.harbor_level2(cid[,v])  cheat.barracks(cid[,v])  cheat.stables(cid[,v])  cheat.gates(cid[,v])  cheat.sentry(cid[,v])  cheat.well(cid[,v])  cheat.bridge(cid[,v])  cheat.wall_level(cid[,v])  cheat.tower_level(cid[,v])  cheat.forum(cid[,v])  cheat.granary_level(cid[,v])  cheat.prison(cid[,v])  cheat.harbor_dock(cid[,v])  cheat.guild_house2(cid[,v])  cheat.house(cid[,v])  cheat.chapel(cid[,v])  cheat.hospital_level(cid[,v])  cheat.brothel(cid[,v])  cheat.harbor_walls(cid[,v])  cheat.schoolhouse(cid[,v])  cheat.library_hall(cid[,v])  cheat.barber_level(cid[,v])  cheat.contor(cid[,v])  cheat.dice_house(cid[,v])  cheat.thieves(cid[,v])  cheat.ropemaker_workshop(cid[,v])  cheat.tannery(cid[,v])  cheat.weaving_mill(cid[,v])  cheat.mint(cid[,v])  cheat.herb_garden(cid[,v])  cheat.vineyard(cid[,v])  cheat.pottery(cid[,v])  cheat.tailor(cid[,v])  cheat.apothecary_level(cid[,v])  cheat.goldsmith_level(cid[,v])  cheat.jeweler_level(cid[,v])  cheat.perfumer_level(cid[,v])  cheat.soapmaker_level(cid[,v])  cheat.candlemaker_level(cid[,v])  cheat.papermill_level(cid[,v])  cheat.printing_house(cid[,v])  cheat.toolmaker_level(cid[,v])  cheat.charcoal_level(cid[,v])  cheat.furrier_level(cid[,v])  cheat.dyer_level(cid[,v])  cheat.saddler_level(cid[,v])  cheat.armorer_level(cid[,v])  cheat.bowyer_level(cid[,v])  cheat.cartwright_level(cid[,v])  cheat.carpenter_level(cid[,v])  cheat.ropemaker_level(cid[,v])  cheat.cooper_level(cid[,v])  cheat.spinner_level(cid[,v])  cheat.turner_level(cid[,v])  cheat.stonecutter_level(cid[,v])  cheat.cobbler_level(cid[,v])  cheat.butcher_level(cid[,v])  cheat.baker_level(cid[,v])  cheat.shepherd_level(cid[,v])  cheat.dairy_level(cid[,v])  cheat.brewmaster_level(cid[,v])  cheat.miller_level(cid[,v])  cheat.fishery_level(cid[,v])  cheat.chandler_level(cid[,v])  cheat.goldbeater_level(cid[,v])  cheat.potter_level(cid[,v])  cheat.fowler_level(cid[,v])  cheat.vintner_level(cid[,v])  cheat.distiller_level(cid[,v])  cheat.cook_level(cid[,v])  cheat.brickmaker_level(cid[,v])  cheat.tavern_level2(cid[,v])  cheat.mill_level(cid[,v])  cheat.brewery_tavern(cid[,v])  cheat.smith_level(cid[,v])  cheat.carpenters(cid[,v])  cheat.tailor_workshop(cid[,v])  cheat.joiner_workshop(cid[,v])  cheat.carter_workshop(cid[,v])  cheat.mining_workshop(cid[,v])  cheat.logging_workshop(cid[,v])  cheat.inn_level(cid[,v])  cheat.robber_camp(cid[,v])  cheat.joiner_ws2(cid[,v])  cheat.carter_ws2(cid[,v])  cheat.mining_ws2(cid[,v])  cheat.logging_ws2(cid[,v])  cheat.inn_level2(cid[,v])  cheat.robber_camp2(cid[,v])  cheat.toll_gate_level(cid[,v])  cheat.road_level(cid[,v])  cheat.toll_gate_tax(cid[,v])  cheat.bridge_cost(cid)  cheat.dock_tax(cid[,v])  cheat.harbor_walls_tax(cid[,v])  cheat.forum_tax(cid[,v])  cheat.granary_tax(cid[,v])  cheat.guild_house_tax(cid[,v])  cheat.house_tax(cid[,v])  cheat.chapel_tax(cid[,v])  cheat.hospital_tax(cid[,v])  cheat.harbor_walls2(cid[,v])  cheat.schoolhouse2(cid[,v])  cheat.library_hall2(cid[,v])  cheat.brothel_tax(cid[,v])  cheat.harbor_walls_tax2(cid[,v])  cheat.schoolhouse_tax(cid[,v])  cheat.library_hall_tax(cid[,v])  cheat.barber_tax(cid[,v])  cheat.contor_tax(cid[,v])  cheat.dice_house_tax(cid[,v])  cheat.thieves_guild_tax(cid[,v])  cheat.harbor_walls_tax3(cid[,v])  cheat.schoolhouse_tax2(cid[,v])  cheat.library_hall_tax2(cid[,v])  cheat.brothel_tax2(cid[,v])  cheat.contor_tax2(cid[,v])  cheat.dice_house_tax2(cid[,v])  cheat.thieves_guild_tax2(cid[,v])  cheat.harbor_walls_tax4(cid[,v])  cheat.ropemaker_ws_tax(cid[,v])  cheat.tannery_tax(cid[,v])  cheat.weaving_tax(cid[,v])  cheat.mint_tax(cid[,v])  cheat.herb_garden_tax(cid[,v])  cheat.vineyard_tax(cid[,v])  cheat.pottery_tax(cid[,v])  cheat.tailor_tax(cid[,v])  cheat.tavern_tax(cid[,v])  cheat.bathhouse_tax(cid[,v])  cheat.church_level_tax(cid[,v])  cheat.contor_level_tax(cid[,v])  cheat.dice_house_level_tax(cid[,v])  cheat.thieves_guild_level_tax(cid[,v])  cheat.ropemaker_level_tax(cid[,v])  cheat.tannery_level_tax(cid[,v])  cheat.weaving_level_tax(cid[,v])  cheat.mint_level_tax(cid[,v])  cheat.herb_garden_level_tax(cid[,v])  cheat.vineyard_level_tax(cid[,v])  cheat.pottery_level_tax(cid[,v])  cheat.tailor_level_tax(cid[,v])  cheat.tavern_level_tax(cid[,v])  cheat.apothecary_level_tax(cid[,v])  cheat.goldsmith_level_tax(cid[,v])  cheat.jeweler_level_tax(cid[,v])  cheat.perfumer_level_tax(cid[,v])  cheat.soapmaker_level_tax(cid[,v])  cheat.candlemaker_level_tax(cid[,v])")
end

function M.prison11_level_tax(cityId, v) if v==nil then return delegate("world","prison11_level_tax", cityId) else return delegate("world","set_prison11_level_tax", cityId, v) end end
function M.prison12_level_tax(cityId, v) if v==nil then return delegate("world","prison12_level_tax", cityId) else return delegate("world","set_prison12_level_tax", cityId, v) end end
function M.prison13_level_tax(cityId, v) if v==nil then return delegate("world","prison13_level_tax", cityId) else return delegate("world","set_prison13_level_tax", cityId, v) end end
function M.prison14_level_tax(cityId, v) if v==nil then return delegate("world","prison14_level_tax", cityId) else return delegate("world","set_prison14_level_tax", cityId, v) end end
function M.prison15_level_tax(cityId, v) if v==nil then return delegate("world","prison15_level_tax", cityId) else return delegate("world","set_prison15_level_tax", cityId, v) end end
function M.prison16_level_tax(cityId, v) if v==nil then return delegate("world","prison16_level_tax", cityId) else return delegate("world","set_prison16_level_tax", cityId, v) end end
function M.prison17_level_tax(cityId, v) if v==nil then return delegate("world","prison17_level_tax", cityId) else return delegate("world","set_prison17_level_tax", cityId, v) end end
function M.prison18_level_tax(cityId, v) if v==nil then return delegate("world","prison18_level_tax", cityId) else return delegate("world","set_prison18_level_tax", cityId, v) end end
function M.prison19_level_tax(cityId, v) if v==nil then return delegate("world","prison19_level_tax", cityId) else return delegate("world","set_prison19_level_tax", cityId, v) end end
function M.prison20_level_tax(cityId, v) if v==nil then return delegate("world","prison20_level_tax", cityId) else return delegate("world","set_prison20_level_tax", cityId, v) end end
function M.shepherd11_level_tax(cityId, v) if v==nil then return delegate("world","shepherd11_level_tax", cityId) else return delegate("world","set_shepherd11_level_tax", cityId, v) end end
function M.shepherd12_level_tax(cityId, v) if v==nil then return delegate("world","shepherd12_level_tax", cityId) else return delegate("world","set_shepherd12_level_tax", cityId, v) end end
function M.shepherd13_level_tax(cityId, v) if v==nil then return delegate("world","shepherd13_level_tax", cityId) else return delegate("world","set_shepherd13_level_tax", cityId, v) end end
function M.shepherd14_level_tax(cityId, v) if v==nil then return delegate("world","shepherd14_level_tax", cityId) else return delegate("world","set_shepherd14_level_tax", cityId, v) end end
function M.shepherd15_level_tax(cityId, v) if v==nil then return delegate("world","shepherd15_level_tax", cityId) else return delegate("world","set_shepherd15_level_tax", cityId, v) end end
function M.shepherd16_level_tax(cityId, v) if v==nil then return delegate("world","shepherd16_level_tax", cityId) else return delegate("world","set_shepherd16_level_tax", cityId, v) end end
function M.shepherd17_level_tax(cityId, v) if v==nil then return delegate("world","shepherd17_level_tax", cityId) else return delegate("world","set_shepherd17_level_tax", cityId, v) end end
function M.shepherd18_level_tax(cityId, v) if v==nil then return delegate("world","shepherd18_level_tax", cityId) else return delegate("world","set_shepherd18_level_tax", cityId, v) end end
function M.shepherd19_level_tax(cityId, v) if v==nil then return delegate("world","shepherd19_level_tax", cityId) else return delegate("world","set_shepherd19_level_tax", cityId, v) end end
function M.shepherd20_level_tax(cityId, v) if v==nil then return delegate("world","shepherd20_level_tax", cityId) else return delegate("world","set_shepherd20_level_tax", cityId, v) end end
function M.soapmaker11_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker11_level_tax", cityId) else return delegate("world","set_soapmaker11_level_tax", cityId, v) end end
function M.soapmaker12_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker12_level_tax", cityId) else return delegate("world","set_soapmaker12_level_tax", cityId, v) end end
function M.soapmaker13_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker13_level_tax", cityId) else return delegate("world","set_soapmaker13_level_tax", cityId, v) end end
function M.soapmaker14_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker14_level_tax", cityId) else return delegate("world","set_soapmaker14_level_tax", cityId, v) end end
function M.soapmaker15_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker15_level_tax", cityId) else return delegate("world","set_soapmaker15_level_tax", cityId, v) end end
function M.soapmaker16_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker16_level_tax", cityId) else return delegate("world","set_soapmaker16_level_tax", cityId, v) end end
function M.soapmaker17_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker17_level_tax", cityId) else return delegate("world","set_soapmaker17_level_tax", cityId, v) end end
function M.soapmaker18_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker18_level_tax", cityId) else return delegate("world","set_soapmaker18_level_tax", cityId, v) end end
function M.soapmaker19_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker19_level_tax", cityId) else return delegate("world","set_soapmaker19_level_tax", cityId, v) end end
function M.soapmaker20_level_tax(cityId, v) if v==nil then return delegate("world","soapmaker20_level_tax", cityId) else return delegate("world","set_soapmaker20_level_tax", cityId, v) end end
function M.spinner11_level_tax(cityId, v) if v==nil then return delegate("world","spinner11_level_tax", cityId) else return delegate("world","set_spinner11_level_tax", cityId, v) end end
function M.spinner12_level_tax(cityId, v) if v==nil then return delegate("world","spinner12_level_tax", cityId) else return delegate("world","set_spinner12_level_tax", cityId, v) end end
function M.spinner13_level_tax(cityId, v) if v==nil then return delegate("world","spinner13_level_tax", cityId) else return delegate("world","set_spinner13_level_tax", cityId, v) end end
function M.spinner14_level_tax(cityId, v) if v==nil then return delegate("world","spinner14_level_tax", cityId) else return delegate("world","set_spinner14_level_tax", cityId, v) end end
function M.spinner15_level_tax(cityId, v) if v==nil then return delegate("world","spinner15_level_tax", cityId) else return delegate("world","set_spinner15_level_tax", cityId, v) end end
function M.spinner16_level_tax(cityId, v) if v==nil then return delegate("world","spinner16_level_tax", cityId) else return delegate("world","set_spinner16_level_tax", cityId, v) end end
function M.spinner17_level_tax(cityId, v) if v==nil then return delegate("world","spinner17_level_tax", cityId) else return delegate("world","set_spinner17_level_tax", cityId, v) end end
function M.spinner18_level_tax(cityId, v) if v==nil then return delegate("world","spinner18_level_tax", cityId) else return delegate("world","set_spinner18_level_tax", cityId, v) end end
function M.spinner19_level_tax(cityId, v) if v==nil then return delegate("world","spinner19_level_tax", cityId) else return delegate("world","set_spinner19_level_tax", cityId, v) end end
function M.spinner20_level_tax(cityId, v) if v==nil then return delegate("world","spinner20_level_tax", cityId) else return delegate("world","set_spinner20_level_tax", cityId, v) end end

function M.apothecary12_level_tax(cityId, v) if v==nil then return delegate("world","apothecary12_level_tax", cityId) else return delegate("world","set_apothecary12_level_tax", cityId, v) end end
function M.apothecary13_level_tax(cityId, v) if v==nil then return delegate("world","apothecary13_level_tax", cityId) else return delegate("world","set_apothecary13_level_tax", cityId, v) end end
function M.apothecary14_level_tax(cityId, v) if v==nil then return delegate("world","apothecary14_level_tax", cityId) else return delegate("world","set_apothecary14_level_tax", cityId, v) end end
function M.apothecary17_level_tax(cityId, v) if v==nil then return delegate("world","apothecary17_level_tax", cityId) else return delegate("world","set_apothecary17_level_tax", cityId, v) end end
function M.apothecary18_level_tax(cityId, v) if v==nil then return delegate("world","apothecary18_level_tax", cityId) else return delegate("world","set_apothecary18_level_tax", cityId, v) end end
function M.apothecary19_level_tax(cityId, v) if v==nil then return delegate("world","apothecary19_level_tax", cityId) else return delegate("world","set_apothecary19_level_tax", cityId, v) end end
function M.apothecary20_level_tax(cityId, v) if v==nil then return delegate("world","apothecary20_level_tax", cityId) else return delegate("world","set_apothecary20_level_tax", cityId, v) end end
function M.town_hall13_level_tax(cityId, v) if v==nil then return delegate("world","town_hall13_level_tax", cityId) else return delegate("world","set_town_hall13_level_tax", cityId, v) end end
function M.town_hall14_level_tax(cityId, v) if v==nil then return delegate("world","town_hall14_level_tax", cityId) else return delegate("world","set_town_hall14_level_tax", cityId, v) end end
function M.town_hall15_level_tax(cityId, v) if v==nil then return delegate("world","town_hall15_level_tax", cityId) else return delegate("world","set_town_hall15_level_tax", cityId, v) end end
function M.town_hall17_level_tax(cityId, v) if v==nil then return delegate("world","town_hall17_level_tax", cityId) else return delegate("world","set_town_hall17_level_tax", cityId, v) end end
function M.town_hall18_level_tax(cityId, v) if v==nil then return delegate("world","town_hall18_level_tax", cityId) else return delegate("world","set_town_hall18_level_tax", cityId, v) end end
function M.town_hall19_level_tax(cityId, v) if v==nil then return delegate("world","town_hall19_level_tax", cityId) else return delegate("world","set_town_hall19_level_tax", cityId, v) end end
function M.town_hall20_level_tax(cityId, v) if v==nil then return delegate("world","town_hall20_level_tax", cityId) else return delegate("world","set_town_hall20_level_tax", cityId, v) end end
function M.barracks17_level_tax(cityId, v) if v==nil then return delegate("world","barracks17_level_tax", cityId) else return delegate("world","set_barracks17_level_tax", cityId, v) end end
function M.barracks18_level_tax(cityId, v) if v==nil then return delegate("world","barracks18_level_tax", cityId) else return delegate("world","set_barracks18_level_tax", cityId, v) end end
function M.barracks19_level_tax(cityId, v) if v==nil then return delegate("world","barracks19_level_tax", cityId) else return delegate("world","set_barracks19_level_tax", cityId, v) end end
function M.barracks20_level_tax(cityId, v) if v==nil then return delegate("world","barracks20_level_tax", cityId) else return delegate("world","set_barracks20_level_tax", cityId, v) end end
function M.university18_level_tax(cityId, v) if v==nil then return delegate("world","university18_level_tax", cityId) else return delegate("world","set_university18_level_tax", cityId, v) end end
function M.university19_level_tax(cityId, v) if v==nil then return delegate("world","university19_level_tax", cityId) else return delegate("world","set_university19_level_tax", cityId, v) end end
function M.university20_level_tax(cityId, v) if v==nil then return delegate("world","university20_level_tax", cityId) else return delegate("world","set_university20_level_tax", cityId, v) end end

function M.herbgarden_yield(bldg, gid, v) if v==nil then return delegate("economy","herbgarden_yield", bldg, gid) else return delegate("economy","set_herbgarden_yield", bldg, gid, v) end end
function M.tailor_master(bldg, gid, v) if v==nil then return delegate("economy","tailor_master_output", bldg, gid) else return delegate("economy","set_tailor_master_output", bldg, gid, v) end end

function M.production_bonus(building, goodId, v) if v==nil then return delegate("civic","production_bonus", building, goodId) else return delegate("civic","set_production_bonus", building, goodId, v) end end
function M.inventory_value(building) return delegate("civic","inventory_value", building) end

function M.season() return delegate("state","season") end
function M.intrigue_level(a,b,v) if v==nil then return delegate("state","intrigue_level", a,b) else return delegate("state","set_intrigue_level", a,b,v) end end
function M.office_holder(cityId, office, v) if v==nil then return delegate("state","office_holder", cityId, office) else return delegate("state","set_office_holder", cityId, office, v) end end
function M.office_term(cityId, office, v) if v==nil then return delegate("state","office_term", cityId, office) else return delegate("state","set_office_term", cityId, office, v) end end
function M.road_bandit(cityA, cityB, v) if v==nil then return delegate("state","road_bandit_risk", cityA, cityB) else return delegate("state","set_road_bandit_risk", cityA, cityB, v) end end

function M.election_votes(cityId, cand, v) if v==nil then return delegate("state","election_votes", cityId, cand) else return delegate("state","set_election_votes", cityId, cand, v) end end
function M.privileges(pid) return delegate("state","privileges", pid) end
function M.marriage_state(pid, partner) return delegate("state","marriage_state", pid, partner) end
function M.office_competition(cityId, office) return delegate("state","office_competition", cityId, office) end
function M.patrol(cityId, v) if v==nil then return delegate("state","patrol_strength", cityId) else return delegate("state","set_patrol_strength", cityId, v) end end
function M.kidnap(a, b) return delegate("state","kidnap_chance", a,b) end
function M.reputation_decay(a,b,v) if v==nil then return delegate("state","reputation_decay", a,b) else return delegate("social","set_reputation_decay", a,b,v) end end

function M.city_rank(cityId) return delegate("state","city_rank", cityId) end
function M.city_growth(cityId) return delegate("state","city_growth", cityId) end
function M.espionage(a,b,v) if v==nil then return delegate("state","espionage", a,b) else return delegate("social","set_espionage", a,b,v) end end
function M.siege(cityId, v) if v==nil then return delegate("state","siege_progress", cityId) else return delegate("state","set_siege_progress", cityId, v) end end
function M.wall_garrison(cityId, v) if v==nil then return delegate("state","wall_garrison", cityId) else return delegate("state","set_wall_garrison", cityId, v) end end
function M.watch(cityId, v) if v==nil then return delegate("state","watch_strength", cityId) else return delegate("state","set_watch_strength", cityId, v) end end
function M.trial_verdict(trialId, v) if v==nil then return delegate("state","trial_verdict", trialId) else return delegate("civic","set_trial_verdict", trialId, v) end end
function M.worker_morale(bldg, v) if v==nil then return delegate("state","worker_morale", bldg) else return delegate("civic","set_worker_morale", bldg, v) end end

function M.dynasty_decay(pid) return delegate("state","dynasty_decay", pid) end
function M.marriage_partner(pid) return delegate("state","marriage_partner", pid) end
function M.relation(a,b,v) if v==nil then return delegate("state","relation", a,b) else return delegate("social","set_relation", a,b,v) end end
function M.robber(cityId, v) if v==nil and false then return nil else return delegate("state","robber_threat", cityId) end end
function M.spy_suspicion(a,b,v) if v==nil then return delegate("state","spy_suspicion", a,b) else return delegate("world","set_spy_suspicion", a,b,v) end end
function M.brawl(cityId) return delegate("state","tavern_brawl", cityId) end
function M.time_hours(v) if v==nil then return delegate("state","time") else return delegate("world","set_time", v) end end
function M.year(v) if v==nil then return delegate("state","year") else return delegate("world","set_year", v) end end

function M.broadcast(eventId, payload, v) if payload==nil then payload="" end; return delegate("state","broadcast_event", eventId, payload) end
function M.divorce(pid, spouse, v) if spouse==nil then return delegate("state","divorce", pid, spouse) else return delegate("state","divorce", pid, spouse) end end
function M.warrant(pid, v) if v==nil then return delegate("state","arrest_warrant", pid) else return delegate("state","issue_warrant", pid, v) end end
function M.spy_network(a, b) return delegate("state","spy_network", a,b) end
function M.diplomacy(a,b,c,d,e) return delegate("state","diplomacy_offer", a,b,c,d,e) end

function M.player_health(pid, v) if v==nil then return delegate("state","player_health", pid) else return delegate("state","set_player_health", pid, v) end end
function M.spy_info(a,b) return delegate("state","spy_info", a,b) end
function M.trial_witness(trialId) return delegate("state","trial_witness", trialId) end
function M.bribed(a, b) return delegate("state","is_bribed", a,b) end
function M.besieged(cityId) return delegate("state","is_besieged", cityId) end
function M.vacant(cityId, office) return delegate("state","is_office_vacant", cityId, office) end
function M.dead(pid) return delegate("state","is_player_dead", pid) end
function M.trial(accused, crime, v) if crime==nil and v==nil then return delegate("state","trial_witness", accused) end; return delegate("state","start_trial", accused, crime) end
function M.trigger(cityId, eventId, v) return delegate("state","trigger_event", eventId or cityId, cityId) end

function M.harvest_yield(bldg, gid, v) if v==nil then return delegate("economy","harvest_yield", bldg, gid) else return delegate("economy","set_harvest_yield", bldg, gid, v) end end
function M.dairy_yield(bldg, gid, v) return delegate("economy","dairy_yield", bldg, gid) end
function M.fishing_yield(bldg, gid, v) return delegate("economy","fishing_yield", bldg, gid) end
function M.hunting_yield(bldg, gid, v) return delegate("economy","hunting_yield", bldg, gid) end
function M.pasture_yield(bldg, gid, v) return delegate("economy","pasture_yield", bldg, gid) end
function M.apiary_yield(bldg, gid, v) return delegate("economy","apiary_yield", bldg, gid) end
function M.orchard_yield(bldg, gid, v) return delegate("economy","orchard_yield", bldg, gid) end
function M.chandler_yield(bldg, gid, v) return delegate("economy","chandler_yield", bldg, gid) end

function M.quarry_yield(bldg, gid, v) return delegate("economy","quarry_yield", bldg, gid) end
function M.falconer_yield(bldg, gid, v) return delegate("economy","falconer_yield", bldg, gid) end
function M.shepherd_yield(bldg, gid, v) return delegate("economy","shepherd_yield", bldg, gid) end
function M.miller_yield(bldg, gid, v) return delegate("economy","miller_yield", bldg, gid) end
function M.fishery_yield(bldg, gid, v) return delegate("economy","fishery_yield", bldg, gid) end
function M.fowler_yield(bldg, gid, v) return delegate("economy","fowler_yield", bldg, gid) end
function M.distiller_yield(bldg, gid, v) return delegate("economy","distiller_yield", bldg, gid) end
function M.mining_yield(bldg, gid, v) return delegate("economy","mining_yield", bldg, gid) end
function M.logging_yield(bldg, gid, v) return delegate("economy","logging_yield", bldg, gid) end

function M.bounty(pid, v) if v==nil then return delegate("economy","bounty", pid) else return delegate("economy","set_bounty", pid, v) end end
function M.church_donation(pid, v) if v==nil then return delegate("economy","church_donation", pid) else return delegate("economy","set_church_donation", pid, v) end end
function M.city_gold(cityId, v) if v==nil then return delegate("economy","city_gold", cityId) else return delegate("economy","set_city_gold", cityId, v) end end
function M.city_happiness(cityId, v) if v==nil then return delegate("economy","city_happiness", cityId) else return delegate("economy","set_city_happiness", cityId, v) end end
function M.dynasty_cash(pid, v) if v==nil then return delegate("economy","dynasty_cash", pid) else return delegate("economy","set_dynasty_cash", pid, v) end end
function M.family_wealth(pid, v) if v==nil then return delegate("economy","family_wealth", pid) else return delegate("economy","set_family_wealth", pid, v) end end
function M.production_rate(building, goodId, v) if v==nil then return delegate("economy","production_rate", building, goodId) else return delegate("economy","set_production_rate", building, goodId, v) end end
function M.worker_wage(building, wageType, v) if v==nil then return delegate("economy","worker_wage", building, wageType) else return delegate("economy","set_worker_wage", building, wageType, v) end end

function M.confession_cost(a, b, v) if v==nil then return delegate("economy","confession_cost", a, b) else return delegate("economy","set_confession_cost", a, b, v) end end
function M.dowry(a, b, v) if v==nil then return delegate("economy","dowry", a, b) else return delegate("economy","set_dowry", a, b, v) end end
function M.feast_cost(a, b, v) if v==nil then return delegate("economy","feast_cost", a, b) else return delegate("economy","set_feast_cost", a, b, v) end end
function M.fence_price(a, b, v) if v==nil then return delegate("economy","fence_price", a, b) else return delegate("economy","set_fence_price", a, b, v) end end
function M.guild_charter_cost(guildId, v) if v==nil then return delegate("economy","guild_charter_cost", guildId) else return delegate("economy","set_guild_charter_cost", guildId, v) end end
function M.guild_promotion_cost(guildId, rank, v) if v==nil then return delegate("economy","guild_promotion_cost", guildId, rank) else return delegate("economy","set_guild_promotion_cost", guildId, rank, v) end end
function M.indulgence_cost(a, b, v) if v==nil then return delegate("economy","indulgence_cost", a, b) else return delegate("economy","set_indulgence_cost", a, b, v) end end
function M.joust_reward(cityId, joustType, v) if v==nil then return delegate("economy","joust_reward", cityId, joustType) else return delegate("economy","set_joust_reward", cityId, joustType, v) end end

function M.pilgrimage_cost(a, b, v) return delegate("economy","pilgrimage_cost", a, b) end
function M.wedding_cost(a, b, v) return delegate("economy","wedding_cost", a, b) end
function M.relic_value(itemId, v) return delegate("economy","relic_value", itemId) end
function M.tithe_rate(cityId, v) if v==nil then return delegate("economy","tithe_rate", cityId) else return delegate("economy","set_tithe_rate", cityId, v) end end
function M.trade_reputation(a, b, v) if v==nil then return delegate("economy","trade_reputation", a, b) else return delegate("economy","set_trade_reputation", a, b, v) end end
function M.city_tax_rate(cityId, goodId, v) return delegate("economy","city_tax_rate", cityId, goodId) end
function M.favor_debt(a, b, v) if v==nil then return delegate("economy","favor_debt", a, b) else return delegate("economy","set_favor_debt", a, b, v) end end
function M.ransom(pid, v) if v==nil then return delegate("economy","ransom", pid) else return delegate("economy","set_ransom", pid, v) end end

return M
