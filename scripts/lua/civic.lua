-- Europa 1400 - Civic / Law Helper
--
-- Wraps election / trial / crime / workshop-efficiency catalog
-- entries behind `civic.*`.
--
--   civic = require("civic")  -- or already `civic`
--   civic.find()                       -- catalog.hunt("world")/civic preset
--   civic.scan(0x00400000, 0x300000)   -- presets.hunt civic/city/building
--   civic.votes(cityId, candidateId)   -- GetElectionVotes
--   civic.set_votes(cityId, candidateId, n)
--   civic.trial(accusedId, crimeId)    -- StartTrial
--   civic.crime(pid) / civic.set_crime(pid, level)
--   civic.efficiency(building) / civic.set_efficiency(building, pct)
--   civic.queue(building)              -- GetProductionQueue
--
-- All wrappers pcall game.call and error with a hint if not yet registered.

local M = {}

local game = require("gamecalls")

local function call_or_hint(name, ...)
    if not game.get_address(name) then
        error(name .. " not registered; run civic.find() / catalog.hunt + game.register first", 2)
    end
    local ok, ret = pcall(game.call, name, ...)
    if ok then return ret end
    error(tostring(ret), 0)
end

function M.scan(base, size)
    base = base or 0x00400000; size = size or 0x300000
    print(string.format("civic.scan [0x%08X +0x%X]", base, size))
    local presets = require("presets")
    local hits = {}
    if presets and presets.hunt then
        for _, key in ipairs({ "civic", "city", "building" }) do
            local h = presets.hunt(key, base, size) or {}
            for _, a in ipairs(h) do hits[#hits+1] = a end
        end
        local seen, uniq = {}, {}
        for _, a in ipairs(hits) do if not seen[a] then seen[a]=true; uniq[#uniq+1]=a end end
        hits = uniq; table.sort(hits)
        if #hits > 0 then print(string.format("civic.scan: %d unique hit(s)", #hits)); return hits end
    end
    print("civic.scan: no hits; try civic.find() or wider base/size")
    return hits
end

function M.find(base, size)
    local cat = require("catalog")
    if not cat or not cat.hunt then error("catalog not available") end
    local out = cat.hunt("civic", base, size)
    if #out > 0 then return out end
    return cat.hunt("world", base, size)
end

function M.votes(cityId, candidateId) return call_or_hint("GetElectionVotes", cityId, candidateId) end
function M.set_votes(cityId, candidateId, votes)
    local r = call_or_hint("SetElectionVotes", cityId, candidateId, votes)
    print(string.format("election city=%s cand=%s -> %s votes", tostring(cityId), tostring(candidateId), tostring(votes)))
    return r
end
function M.trial(accusedId, crimeId)
    local r = call_or_hint("StartTrial", accusedId, crimeId)
    print(string.format("trial accused=%s crime=%s -> %s", tostring(accusedId), tostring(crimeId), tostring(r)))
    return r
end
function M.crime(playerId) return call_or_hint("GetCrimeLevel", playerId) end
function M.set_crime(playerId, level)
    local r = call_or_hint("SetCrimeLevel", playerId, level)
    print(string.format("crime player=%s -> %s", tostring(playerId), tostring(level)))
    return r
end
function M.efficiency(building) return call_or_hint("GetWorkshopEfficiency", building) end
function M.set_efficiency(building, pct)
    local r = call_or_hint("SetWorkshopEfficiency", building, pct)
    print(string.format("workshop 0x%08X efficiency -> %s%%", building, tostring(pct)))
    return r
end
function M.queue(building) return call_or_hint("GetProductionQueue", building) end
function M.durability(building) return call_or_hint("GetBuildingDurability", building) end
function M.set_durability(building, v) local r=call_or_hint("SetBuildingDurability", building, v); print(string.format("building 0x%08X durability -> %s", building, tostring(v))); return r end
function M.income(building) return call_or_hint("GetBuildingIncome", building) end
function M.set_income(building, v) local r=call_or_hint("SetBuildingIncome", building, v); print(string.format("building 0x%08X income -> %s", building, tostring(v))); return r end
function M.morale(buildingId) return call_or_hint("GetMorale", buildingId) end
function M.set_morale(buildingId, v) local r=call_or_hint("SetMorale", buildingId, v); print(string.format("morale %s -> %s", tostring(buildingId), tostring(v))); return r end
function M.trigger_event(eventId, cityId) local r=call_or_hint("TriggerEvent", eventId, cityId); print(string.format("event %s city %s -> %s", tostring(eventId), tostring(cityId), tostring(r))); return r end
function M.event_state(eventId) return call_or_hint("GetEventState", eventId) end
function M.production_rate(building, goodId) return call_or_hint("GetProductionRate", building, goodId) end
function M.set_production_rate(building, goodId, rate) local r=call_or_hint("SetProductionRate", building, goodId, rate); print(string.format("production 0x%08X good=%s -> %s", building, tostring(goodId), tostring(rate))); return r end
function M.city_stability(cityId) return call_or_hint("GetCityStability", cityId) end
function M.set_city_stability(cityId, v) local r=call_or_hint("SetCityStability", cityId, v); print(string.format("stability city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.worker_morale(buildingId) return call_or_hint("GetWorkerMorale", buildingId) end
function M.set_worker_morale(buildingId, v) local r=call_or_hint("SetWorkerMorale", buildingId, v); print(string.format("worker morale %s -> %s", tostring(buildingId), tostring(v))); return r end
function M.building_tax(building) return call_or_hint("GetBuildingTax", building) end
function M.set_building_tax(building, v) local r=call_or_hint("SetBuildingTax", building, v); print(string.format("building tax 0x%08X -> %s", building, tostring(v))); return r end
function M.worker_skill(workerId, skillId) return call_or_hint("GetWorkerSkill", workerId, skillId) end
function M.set_worker_skill(workerId, skillId, v) local r=call_or_hint("SetWorkerSkill", workerId, skillId, v); print(string.format("worker %s skill %s -> %s", tostring(workerId), tostring(skillId), tostring(v))); return r end
function M.trial_verdict(trialId) return call_or_hint("GetTrialVerdict", trialId) end
function M.set_trial_verdict(trialId, v) local r=call_or_hint("SetTrialVerdict", trialId, v); print(string.format("verdict trial=%s -> %s", tostring(trialId), tostring(v))); return r end
function M.harvest_yield(farm, goodId) return call_or_hint("GetHarvestYield", farm, goodId) end
function M.set_harvest_yield(farm, goodId, v) local r=call_or_hint("SetHarvestYield", farm, goodId, v); print(string.format("harvest 0x%08X good=%s -> %s", farm, tostring(goodId), tostring(v))); return r end
function M.witnesses(trialId) return call_or_hint("GetTrialWitnessCount", trialId) end
function M.worker_wage(building, wtype) return call_or_hint("GetWorkerWage", building, wtype) end
function M.set_worker_wage(building, wtype, v) local r=call_or_hint("SetWorkerWage", building, wtype, v); print(string.format("wage 0x%08X type=%s -> %s", building, tostring(wtype), tostring(v))); return r end

function M.witness_count(trialId) return call_or_hint("GetTrialWitnessCount", trialId) end
function M.evidence_count(trialId) return call_or_hint("GetEvidenceCount", trialId) end
function M.trial_verdict(trialId) return call_or_hint("GetTrialVerdict", trialId) end
function M.set_verdict(trialId, v) local r=call_or_hint("SetTrialVerdict", trialId, v); print(string.format("trial %s verdict->%s", tostring(trialId), tostring(v))); return r end
function M.crime_type(pid)
    local id=M.crime(pid)
    local e=require("enums")
    if e and e.lookup and id then local ok,n=pcall(e.lookup,"crime",id); if ok and n then return n,id end end
    return id
end

function M.production_bonus(building, goodId) return call_or_hint("GetProductionBonus", building, goodId) end
function M.set_production_bonus(building, goodId, bonus) local r=call_or_hint("SetProductionBonus", building, goodId, bonus); print(string.format("production bonus 0x%08X good=%s -> %s", building, tostring(goodId), tostring(bonus))); return r end
function M.inventory_value(building) local iv=require("inventory"); if iv and iv.value then return iv.value(building) end; return call_or_hint("GetInventoryValue", building) end

return M
