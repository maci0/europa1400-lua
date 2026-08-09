-- Europa 1400 - Economy Helper
--
-- High-level wrappers for guild/market/tax/trade routes.
-- Mirrors player/city/building/unit/inventory: thin wrappers over
-- catalog-registered game.call plus scan/find helpers.
--
--   economy = dofile('lua/economy.lua')  -- or already `economy`
--   economy.find()                        -- catalog.hunt("economy")
--   economy.scan(0x00400000, 0x300000)    -- presets.hunt guild/trade/tax
--   economy.guild_balance(gid)            -- GetGuildBalance
--   economy.set_guild_balance(gid, 5000)  -- SetGuildBalance
--   economy.market_price(goodId, cityId)  -- GetMarketPrice
--   economy.set_market_price(gid, cid, 42)
--   economy.tax_rate(cityId, goodId)
--   economy.set_tax_rate(cityId, goodId, 10)
--   economy.route(id)                     -- GetTradeRoute
--   economy.create_route(src,dst,goodId)
--   economy.delete_route(id)
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
        -- rethrow with original error if present
        error(tostring(ret))
    end
    error(name .. " not registered; run economy.find() / catalog.hunt('economy') or game.register first")
end

function M.scan(base, size)
    base = base or 0x00400000; size = size or 0x300000
    print(string.format("economy.scan [0x%08X +0x%X]", base, size))
    local presets = _G.presets or (pcall(dofile, "lua/presets.lua") and _G.presets)
    local hits = {}
    if presets and presets.hunt then
        for _, key in ipairs({ "guild", "trade", "tax", "inventory" }) do
            local h = presets.hunt(key, base, size) or {}
            for _, a in ipairs(h) do hits[#hits+1] = a end
        end
        -- dedup
        local seen, uniq = {}, {}
        for _, a in ipairs(hits) do if not seen[a] then seen[a]=true; uniq[#uniq+1]=a end end
        hits = uniq
        table.sort(hits)
        if #hits > 0 then
            print(string.format("economy.scan: %d unique hit(s)", #hits))
            return hits
        end
    end
    print("economy.scan: no hits; try economy.find() or wider base/size")
    return hits
end

function M.find(base, size)
    local cat = _G.catalog or (pcall(dofile, "lua/catalog.lua") and _G.catalog)
    if not cat or not cat.hunt then error("catalog not available") end
    return cat.hunt("economy", base, size)
end

function M.guild_balance(guildId) return call_or_hint("GetGuildBalance", guildId) end
function M.set_guild_balance(guildId, amount)
    local r = call_or_hint("SetGuildBalance", guildId, amount)
    print(string.format("guild %s balance -> %s", tostring(guildId), tostring(amount)))
    return r
end

function M.market_price(goodId, cityId) return call_or_hint("GetMarketPrice", goodId, cityId) end
function M.set_market_price(goodId, cityId, price)
    local r = call_or_hint("SetMarketPrice", goodId, cityId, price)
    print(string.format("market good=%s city=%s price -> %s", tostring(goodId), tostring(cityId), tostring(price)))
    return r
end

function M.tax_rate(cityId, goodId) return call_or_hint("GetTaxRate", cityId, goodId) end
function M.set_tax_rate(cityId, goodId, rate)
    local r = call_or_hint("SetTaxRate", cityId, goodId, rate)
    print(string.format("tax city=%s good=%s -> %s", tostring(cityId), tostring(goodId), tostring(rate)))
    return r
end

function M.route(routeId) return call_or_hint("GetTradeRoute", routeId) end
function M.create_route(srcCity, dstCity, goodId) return call_or_hint("CreateTradeRoute", srcCity, dstCity, goodId) end
function M.delete_route(routeId)
    local r = call_or_hint("DeleteTradeRoute", routeId)
    print(string.format("trade route %s deleted", tostring(routeId)))
    return r
end

function M.stock(playerId, stockId) return call_or_hint("GetStockCount", playerId, stockId) end
function M.set_stock(playerId, stockId, n) local r=call_or_hint("SetStockCount", playerId, stockId, n); print(string.format("stock player=%s stock=%s -> %s", tostring(playerId), tostring(stockId), tostring(n))); return r end
function M.daily_income(playerId) return call_or_hint("GetDailyIncome", playerId) end
function M.set_daily_income(playerId, amount) local r=call_or_hint("SetDailyIncome", playerId, amount); print(string.format("daily income player=%s -> %s", tostring(playerId), tostring(amount))); return r end

function M.bribe_price(cityId, officeId) return call_or_hint("GetBribePrice", cityId, officeId) end
function M.set_bribe_price(cityId, officeId, price) local r=call_or_hint("SetBribePrice", cityId, officeId, price); print(string.format("bribe city=%s office=%s -> %s", tostring(cityId), tostring(officeId), tostring(price))); return r end

function M.title_cost(titleId) return call_or_hint("GetTitleCost", titleId) end
function M.trade_profit(a,b,good) return call_or_hint("GetTradeProfit", a, b, good) end
function M.supply(cityId, goodId) return call_or_hint("GetMarketSupply", cityId, goodId) end
function M.set_supply(cityId, goodId, v) local r=call_or_hint("SetMarketSupply", cityId, goodId, v); print(string.format("supply city=%s good=%s -> %s", tostring(cityId), tostring(goodId), tostring(v))); return r end
function M.demand(cityId, goodId) return call_or_hint("GetMarketDemand", cityId, goodId) end
function M.set_demand(cityId, goodId, v) local r=call_or_hint("SetMarketDemand", cityId, goodId, v); print(string.format("demand city=%s good=%s -> %s", tostring(cityId), tostring(goodId), tostring(v))); return r end
function M.inventory_value(owner) return call_or_hint("GetInventoryValue", owner) end
function M.trade_tax(a,b,good) return call_or_hint("GetTradeTax", a, b, good) end
function M.set_trade_tax(a,b,good,tax) local r=call_or_hint("SetTradeTax", a, b, good, tax); print(string.format("trade_tax %s->%s good=%s -> %s", tostring(a), tostring(b), tostring(good), tostring(tax))); return r end
function M.assassination_cost(a,b) return call_or_hint("GetAssassinationCost", a, b) end
function M.sabotage_cost(pid, building) return call_or_hint("GetSabotageCost", pid, building) end
function M.debt(pid) return call_or_hint("GetPlayerDebt", pid) end
function M.set_debt(pid, v) local r=call_or_hint("SetPlayerDebt", pid, v); print(string.format("debt player=%s -> %s", tostring(pid), tostring(v))); return r end
function M.bank(pid) return call_or_hint("GetBankBalance", pid) end
function M.set_bank(pid, v) local r=call_or_hint("SetBankBalance", pid, v); print(string.format("bank player=%s -> %s", tostring(pid), tostring(v))); return r end
function M.loan(pid, loanId) return call_or_hint("GetLoanAmount", pid, loanId) end
function M.set_loan(pid, loanId, v) local r=call_or_hint("SetLoanAmount", pid, loanId, v); print(string.format("loan player=%s id=%s -> %s", tostring(pid), tostring(loanId), tostring(v))); return r end
function M.interest(cityId) return call_or_hint("GetInterestRate", cityId) end
function M.set_interest(cityId, v) local r=call_or_hint("SetInterestRate", cityId, v); print(string.format("interest city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.repay(pid, loanId) return call_or_hint("GetRepayAmount", pid, loanId) end
function M.pay_loan(pid, loanId, amount) local r=call_or_hint("PayLoan", pid, loanId, amount); print(string.format("pay loan player=%s loan=%s -> %s", tostring(pid), tostring(loanId), tostring(amount))); return r end
function M.take_loan(pid, amount, duration) local r=call_or_hint("TakeLoan", pid, amount, duration); print(string.format("take loan player=%s amount=%s dur=%s -> %s", tostring(pid), tostring(amount), tostring(duration), tostring(r))); return r end
function M.credit(pid) return call_or_hint("GetCreditScore", pid) end
function M.set_credit(pid, v) local r=call_or_hint("SetCreditScore", pid, v); print(string.format("credit player=%s -> %s", tostring(pid), tostring(v))); return r end
function M.blackmail_cost(a,b) return call_or_hint("GetBlackmailCost", a, b) end
function M.bribe_official(pid, cityId, officeId, amount) local r=call_or_hint("BribeOfficial", pid, cityId, officeId, amount); print(string.format("bribe official player=%s city=%s off=%s -> %s", tostring(pid), tostring(cityId), tostring(officeId), tostring(amount))); return r end
function M.guild_fee(guildId) return call_or_hint("GetGuildFee", guildId) end
function M.set_guild_fee(guildId, v) local r=call_or_hint("SetGuildFee", guildId, v); print(string.format("guild fee guild=%s -> %s", tostring(guildId), tostring(v))); return r end
function M.route_profit(a,b,good) return call_or_hint("GetTradeRouteProfit", a, b, good) end
function M.guild_levy(gid, cityId) return call_or_hint("GetGuildLevy", gid, cityId) end
function M.set_guild_levy(gid, cityId, v) local r=call_or_hint("SetGuildLevy", gid, cityId, v); print(string.format("guild levy guild=%s city=%s -> %s", tostring(gid), tostring(cityId), tostring(v))); return r end
function M.guild_tax(gid, cityId) return call_or_hint("GetGuildTaxRate", gid, cityId) end

-- aliases
M.guild = M.guild_balance
M.price = M.market_price
M.bribe = M.bribe_price
M.set_bribe = M.set_bribe_price
M.income = M.daily_income
M.set_income = M.set_daily_income

function M.cook_output(ptr, idx) return call_or_hint("GetCookOutput", ptr, idx or 0) end
function M.set_cook_output(ptr, idx, n) local r=call_or_hint("SetCookOutput", ptr, idx or 0, n or 0); print(string.format("cook output %s[%s]->%s", tostring(ptr), tostring(idx or 0), tostring(n or 0))); return r end
function M.cooper_output(ptr, idx) return call_or_hint("GetCooperOutput", ptr, idx or 0) end
function M.set_cooper_output(ptr, idx, n) local r=call_or_hint("SetCooperOutput", ptr, idx or 0, n or 0); print(string.format("cooper output %s[%s]->%s", tostring(ptr), tostring(idx or 0), tostring(n or 0))); return r end
function M.dyer_output(ptr, idx) return call_or_hint("GetDyerOutput", ptr, idx or 0) end
function M.set_dyer_output(ptr, idx, n) local r=call_or_hint("SetDyerOutput", ptr, idx or 0, n or 0); print(string.format("dyer output %s[%s]->%s", tostring(ptr), tostring(idx or 0), tostring(n or 0))); return r end
function M.furrier_output(ptr, idx) return call_or_hint("GetFurrierOutput", ptr, idx or 0) end
function M.set_furrier_output(ptr, idx, n) local r=call_or_hint("SetFurrierOutput", ptr, idx or 0, n or 0); print(string.format("furrier output %s[%s]->%s", tostring(ptr), tostring(idx or 0), tostring(n or 0))); return r end
function M.saddler_output(ptr, idx) return call_or_hint("GetSaddlerOutput", ptr, idx or 0) end
function M.set_saddler_output(ptr, idx, n) local r=call_or_hint("SetSaddlerOutput", ptr, idx or 0, n or 0); print(string.format("saddler output %s[%s]->%s", tostring(ptr), tostring(idx or 0), tostring(n or 0))); return r end
function M.ropemaker_output(ptr, idx) return call_or_hint("GetRopemakerOutput", ptr, idx or 0) end
function M.set_ropemaker_output(ptr, idx, n) local r=call_or_hint("SetRopemakerOutput", ptr, idx or 0, n or 0); print(string.format("ropemaker output %s[%s]->%s", tostring(ptr), tostring(idx or 0), tostring(n or 0))); return r end
function M.tannery_output(ptr, idx) return call_or_hint("GetTanneryOutput", ptr, idx or 0) end
function M.set_tannery_output(ptr, idx, n) local r=call_or_hint("SetTanneryOutput", ptr, idx or 0, n or 0); print(string.format("tannery output %s[%s]->%s", tostring(ptr), tostring(idx or 0), tostring(n or 0))); return r end
function M.weaving_output(ptr, idx) return call_or_hint("GetWeaverOutput", ptr, idx or 0) end
function M.set_weaving_output(ptr, idx, n) local r=call_or_hint("SetWeaverOutput", ptr, idx or 0, n or 0); print(string.format("weaving output %s[%s]->%s", tostring(ptr), tostring(idx or 0), tostring(n or 0))); return r end
function M.potter_output(ptr, idx) return call_or_hint("GetPotterOutput", ptr, idx or 0) end
function M.set_potter_output(ptr, idx, n) local r=call_or_hint("SetPotterOutput", ptr, idx or 0, n or 0); print(string.format("potter output %s[%s]->%s", tostring(ptr), tostring(idx or 0), tostring(n or 0))); return r end
function M.miller_output(ptr, idx) return call_or_hint("GetMillOutput", ptr, idx or 0) end
function M.set_miller_output(ptr, idx, n) local r=call_or_hint("SetMillOutput", ptr, idx or 0, n or 0); print(string.format("miller output %s[%s]->%s", tostring(ptr), tostring(idx or 0), tostring(n or 0))); return r end
function M.baker_bonus_output(ptr, idx) return call_or_hint("GetBakerOutputBonus", ptr, idx or 0) end
function M.set_baker_bonus_output(ptr, idx, n) local r=call_or_hint("SetBakerOutputBonus", ptr, idx or 0, n or 0); print(string.format("baker_bonus output %s[%s]->%s", tostring(ptr), tostring(idx or 0), tostring(n or 0))); return r end
function M.barber_output(ptr, idx) return call_or_hint("GetBarberOutput", ptr, idx or 0) end
function M.set_barber_output(ptr, idx, n) local r=call_or_hint("SetBarberOutput", ptr, idx or 0, n or 0); print(string.format("barber output %s[%s]->%s", tostring(ptr), tostring(idx or 0), tostring(n or 0))); return r end

function M.goldsmith_output(ptr, idx) return call_or_hint("GetGoldsmithOutput", ptr, idx or 0) end
function M.set_goldsmith_output(ptr, idx, n) local r=call_or_hint("SetGoldsmithOutput", ptr, idx or 0, n or 0); print(string.format("goldsmith output %s[%s]->%s", tostring(ptr), tostring(idx or 0), tostring(n or 0))); return r end
function M.vintner_output(ptr, idx) return call_or_hint("GetVintnerOutput", ptr, idx or 0) end
function M.set_vintner_output(ptr, idx, n) local r=call_or_hint("SetVintnerOutput", ptr, idx or 0, n or 0); print(string.format("vintner output %s[%s]->%s", tostring(ptr), tostring(idx or 0), tostring(n or 0))); return r end


function M.herbgarden_yield(ptr, idx) return call_or_hint("GetHerbGardenYield", ptr, idx or 0) end
function M.set_herbgarden_yield(ptr, idx, n) local r=call_or_hint("SetHerbGardenYield", ptr, idx or 0, n or 0); print(string.format("herbgarden_yield %s[%s]->%s", tostring(ptr), tostring(idx or 0), tostring(n or 0))); return r end
function M.tailor_master_output(ptr, idx) return call_or_hint("GetTailorMasterOutput", ptr, idx or 0) end
function M.set_tailor_master_output(ptr, idx, n) local r=call_or_hint("SetTailorMasterOutput", ptr, idx or 0, n or 0); print(string.format("tailor_master_output %s[%s]->%s", tostring(ptr), tostring(idx or 0), tostring(n or 0))); return r end


function M.harvest_yield(ptr, idx) return call_or_hint("GetHarvestYield", ptr, idx or 0) end
function M.set_harvest_yield(ptr, idx, n) local r=call_or_hint("SetHarvestYield", ptr, idx or 0, n or 0); print(string.format("harvest_yield %s[%s]->%s", tostring(ptr), tostring(idx or 0), tostring(n or 0))); return r end
function M.dairy_yield(ptr, idx) return call_or_hint("GetDairyYield", ptr, idx or 0) end
function M.fishing_yield(ptr, idx) return call_or_hint("GetFishingYield", ptr, idx or 0) end
function M.hunting_yield(ptr, idx) return call_or_hint("GetHuntingYield", ptr, idx or 0) end
function M.pasture_yield(ptr, idx) return call_or_hint("GetPastureYield", ptr, idx or 0) end
function M.apiary_yield(ptr, idx) return call_or_hint("GetApiaryYield", ptr, idx or 0) end
function M.orchard_yield(ptr, idx) return call_or_hint("GetOrchardYield", ptr, idx or 0) end
function M.chandler_yield(ptr, idx) return call_or_hint("GetChandlerYield", ptr, idx or 0) end

function M.quarry_yield(ptr, idx) return call_or_hint("GetQuarryYield", ptr, idx or 0) end
function M.falconer_yield(ptr, idx) return call_or_hint("GetFalconerYield", ptr, idx or 0) end
function M.shepherd_yield(ptr, idx) return call_or_hint("GetShepherdYield", ptr, idx or 0) end
function M.miller_yield(ptr, idx) return call_or_hint("GetMillerYield", ptr, idx or 0) end
function M.fishery_yield(ptr, idx) return call_or_hint("GetFisheryYield", ptr, idx or 0) end
function M.fowler_yield(ptr, idx) return call_or_hint("GetFowlerYield", ptr, idx or 0) end
function M.distiller_yield(ptr, idx) return call_or_hint("GetDistillerYield", ptr, idx or 0) end
function M.mining_yield(ptr, idx) return call_or_hint("GetMiningYield", ptr, idx or 0) end
function M.logging_yield(ptr, idx) return call_or_hint("GetLoggingYield", ptr, idx or 0) end

function M.bounty(pid) return call_or_hint("GetBountyPrice", pid or 0) end
function M.set_bounty(pid, v) local r=call_or_hint("SetBountyPrice", pid or 0, v or 0); print(string.format("bounty %s -> %s", tostring(pid), tostring(v))); return r end
function M.church_donation(pid) return call_or_hint("GetChurchDonationTotal", pid or 0) end
function M.set_church_donation(pid, v) local r=call_or_hint("SetChurchDonationTotal", pid or 0, v or 0); print(string.format("church_donation %s -> %s", tostring(pid), tostring(v))); return r end
function M.city_gold(cityId) return call_or_hint("GetCityGold", cityId or 0) end
function M.set_city_gold(cityId, v) local r=call_or_hint("SetCityGold", cityId or 0, v or 0); print(string.format("city_gold %s -> %s", tostring(cityId), tostring(v))); return r end
function M.city_happiness(cityId) return call_or_hint("GetCityHappiness", cityId or 0) end
function M.set_city_happiness(cityId, v) local r=call_or_hint("SetCityHappiness", cityId or 0, v or 0); print(string.format("city_happiness %s -> %s", tostring(cityId), tostring(v))); return r end
function M.dynasty_cash(pid) return call_or_hint("GetDynastyCash", pid or 0) end
function M.set_dynasty_cash(pid, v) local r=call_or_hint("SetDynastyCash", pid or 0, v or 0); print(string.format("dynasty_cash %s -> %s", tostring(pid), tostring(v))); return r end
function M.family_wealth(pid) return call_or_hint("GetFamilyWealth", pid or 0) end
function M.set_family_wealth(pid, v) local r=call_or_hint("SetFamilyWealth", pid or 0, v or 0); print(string.format("family_wealth %s -> %s", tostring(pid), tostring(v))); return r end
function M.production_rate(building, goodId) return call_or_hint("GetProductionRate", building, goodId) end
function M.set_production_rate(building, goodId, v) local r=call_or_hint("SetProductionRate", building, goodId, v or 0); print(string.format("production_rate %s -> %s", tostring(building), tostring(v))); return r end
function M.worker_wage(building, wageType) return call_or_hint("GetWorkerWage", building, wageType) end
function M.set_worker_wage(building, wageType, v) local r=call_or_hint("SetWorkerWage", building, wageType, v or 0); print(string.format("worker_wage %s -> %s", tostring(building), tostring(v))); return r end

function M.confession_cost(a,b) return call_or_hint("GetConfessionCost", a,b) end
function M.set_confession_cost(a,b, v) local r=call_or_hint("SetConfessionCost", a,b, v or 0); print(string.format("confession_cost %s -> %s", tostring(a), tostring(v))); return r end
function M.dowry(a,b) return call_or_hint("GetDowryAmount", a,b) end
function M.set_dowry(a,b, v) local r=call_or_hint("SetDowryAmount", a,b, v or 0); print(string.format("dowry %s -> %s", tostring(a), tostring(v))); return r end
function M.feast_cost(a,b) return call_or_hint("GetFeastCost", a,b) end
function M.set_feast_cost(a,b, v) local r=call_or_hint("SetFeastCost", a,b, v or 0); print(string.format("feast_cost %s -> %s", tostring(a), tostring(v))); return r end
function M.fence_price(a,b) return call_or_hint("GetFencePrice", a,b) end
function M.set_fence_price(a,b, v) local r=call_or_hint("SetFencePrice", a,b, v or 0); print(string.format("fence_price %s -> %s", tostring(a), tostring(v))); return r end
function M.guild_charter_cost(guildId) return call_or_hint("GetGuildCharterCost", guildId or 0) end
function M.set_guild_charter_cost(guildId, v) local r=call_or_hint("SetGuildCharterCost", guildId or 0, v or 0); print(string.format("guild_charter_cost %s -> %s", tostring(guildId), tostring(v))); return r end
function M.guild_promotion_cost(guildId, rank) return call_or_hint("GetGuildPromotionCost", guildId, rank) end
function M.set_guild_promotion_cost(guildId, rank, v) local r=call_or_hint("SetGuildPromotionCost", guildId, rank, v or 0); print(string.format("guild_promotion_cost %s -> %s", tostring(guildId), tostring(v))); return r end
function M.indulgence_cost(a,b) return call_or_hint("GetIndulgenceCost", a,b) end
function M.set_indulgence_cost(a,b, v) local r=call_or_hint("SetIndulgenceCost", a,b, v or 0); print(string.format("indulgence_cost %s -> %s", tostring(a), tostring(v))); return r end
function M.joust_reward(cityId, joustType) return call_or_hint("GetJoustReward", cityId, joustType) end
function M.set_joust_reward(cityId, joustType, v) local r=call_or_hint("SetJoustReward", cityId, joustType, v or 0); print(string.format("joust_reward %s -> %s", tostring(cityId), tostring(v))); return r end

function M.pilgrimage_cost(a,b) return call_or_hint("GetPilgrimageCost", a,b) end
function M.wedding_cost(a,b) return call_or_hint("GetWeddingCost", a,b) end
function M.relic_value(itemId) return call_or_hint("GetRelicValue", itemId or 0) end
function M.tithe_rate(cityId) return call_or_hint("GetTitheRate", cityId or 0) end
function M.set_tithe_rate(cityId, v) local r=call_or_hint("SetTitheRate", cityId or 0, v or 0); print(string.format("tithe_rate %s -> %s", tostring(cityId), tostring(v))); return r end
function M.trade_reputation(a,b) return call_or_hint("GetTradeReputation", a,b) end
function M.set_trade_reputation(a,b, v) local r=call_or_hint("SetTradeReputation", a,b, v or 0); print(string.format("trade_reputation %s -> %s", tostring(a), tostring(v))); return r end
function M.city_tax_rate(cityId, goodId) return call_or_hint("GetCityTaxRate", cityId, goodId) end
function M.favor_debt(a,b) return call_or_hint("GetFavorDebt", a,b) end
function M.set_favor_debt(a,b, v) local r=call_or_hint("SetFavorDebt", a,b, v or 0); print(string.format("favor_debt %s -> %s", tostring(a), tostring(v))); return r end
function M.ransom(pid) return call_or_hint("GetRansomPrice", pid or 0) end
function M.set_ransom(pid, v) local r=call_or_hint("SetRansomPrice", pid or 0, v or 0); print(string.format("ransom %s -> %s", tostring(pid), tostring(v))); return r end

function M.caravan_value(ptr) return call_or_hint("GetCaravanValue", ptr) end
function M.inventory_count(owner, goodId) return call_or_hint("GetInventoryCount", owner, goodId or 0) end
function M.workshop_efficiency(building) return call_or_hint("GetWorkshopEfficiency", building) end
function M.set_workshop_efficiency(building, v) local r=call_or_hint("SetWorkshopEfficiency", building, v or 0); print(string.format("workshop_efficiency %s -> %s", tostring(building), tostring(v))); return r end
function M.gambling_debt(pid) return call_or_hint("GetGamblingDebt", pid or 0) end
function M.set_gambling_debt(pid, v) local r=call_or_hint("SetGamblingDebt", pid or 0, v or 0); print(string.format("gambling_debt %s -> %s", tostring(pid), tostring(v))); return r end
function M.trade_execute(a,b,good,amt) return call_or_hint("TradeExecute", a,b,good or 0, amt or 1) end

return M
