-- Europa 1400 - Save/State Helper
--
-- Wraps save/load + pause/state catalog entries behind `state.*`.
--
--   state = require("state")  -- or already `state`
--   state.find()                      -- catalog.hunt("save") + state
--   state.scan(0x00400000, 0x300000)  -- presets.hunt save/map
--   state.save("mysave.sav")          -- SaveGame
--   state.load("mysave.sav")          -- LoadGame
--   state.pause(1) / state.unpause()  -- PauseGame
--   state.is_paused()                 -- IsGamePaused
--   state.get()                       -- GetGameState

local M = {}

local game = require("gamecalls")


local function call_or_hint(name, ...)
    if not game.get_address(name) then
        error(name .. " not registered; run state.find() / catalog.hunt('save') or game.register first", 2)
    end
    local ok, ret = pcall(game.call, name, ...)
    if ok then return ret end
    error(tostring(ret), 0)
end

function M.scan(base, size)
    base = base or 0x00400000; size = size or 0x300000
    print(string.format("state.scan [0x%08X +0x%X]", base, size))
    local presets = require("presets")
    local hits = {}
    if presets and presets.hunt then
        for _, key in ipairs({ "save", "clock" }) do
            local h = presets.hunt(key, base, size) or {}
            for _, a in ipairs(h) do hits[#hits+1] = a end
        end
        local seen, uniq = {}, {}
        for _, a in ipairs(hits) do if not seen[a] then seen[a]=true; uniq[#uniq+1]=a end end
        hits = uniq; table.sort(hits)
        if #hits > 0 then print(string.format("state.scan: %d unique hit(s)", #hits)); return hits end
    end
    print("state.scan: no hits; try state.find() or wider base/size")
    return hits
end

function M.find(base, size)
    local cat = require("catalog")
    if not cat or not cat.hunt then error("catalog not available") end
    local out = cat.hunt("save", base, size)
    if #out == 0 then out = cat.hunt("state", base, size) end
    return out
end

function M.save(path)
    if type(path) ~= "string" or path == "" then error("save path string required") end
    local r = call_or_hint("SaveGame", path)
    print(string.format("save %q -> %s", path, tostring(r)))
    return r
end

function M.load(path)
    if type(path) ~= "string" or path == "" then error("load path string required") end
    local r = call_or_hint("LoadGame", path)
    print(string.format("load %q -> %s", path, tostring(r)))
    return r
end

function M.pause(flag)
    if flag == nil then flag = 1 end
    local r = call_or_hint("PauseGame", flag and 1 or 0)
    print(string.format("pause %s -> %s", tostring(flag), tostring(r)))
    return r
end

function M.unpause() return M.pause(0) end

function M.is_paused() return call_or_hint("IsGamePaused") end
function M.get() return call_or_hint("GetGameState") end


-- city/world state surfaced via state.* so catalog.hunt("state") triage works from one door
function M.city_owner(cityId) return call_or_hint("GetCityOwner", cityId) end
function M.wall_health(cityId) return call_or_hint("GetCityWallHealth", cityId) end
function M.defense(cityId) return call_or_hint("GetCityDefense", cityId) end
function M.unrest(cityId) return call_or_hint("GetCityUnrest", cityId) end
function M.corruption(cityId) return call_or_hint("GetCityCorruption", cityId) end
function M.stability(cityId) return call_or_hint("GetCityStability", cityId) end
function M.pop_limit(cityId) return call_or_hint("GetCityPopulationLimit", cityId) end
function M.difficulty() return call_or_hint("GetDifficulty") end
function M.diff_level() return call_or_hint("GetDifficulty") end
function M.ai_behavior(pid) return call_or_hint("GetAIBehavior", pid) end
function M.aggressiveness(pid) return call_or_hint("GetAggressiveness", pid) end
function M.dynasty_members(pid) return call_or_hint("GetDynastyMembers", pid) end
function M.dynasty_name(pid) return call_or_hint("GetDynastyName", pid) end


function M.guard_count(pid_or_city) return call_or_hint("GetGuardCount", pid_or_city or 0) end
function M.guard_morale(pid_or_city) return call_or_hint("GetGuardMorale", pid_or_city or 0) end
function M.disease(pid_or_city) return call_or_hint("GetDiseaseState", pid_or_city or 0) end
function M.drunk(pid_or_city) return call_or_hint("GetDrunkLevel", pid_or_city or 0) end
function M.heir(pid_or_city) return call_or_hint("GetHeir", pid_or_city or 0) end
function M.arrest_warrant(pid_or_city) return call_or_hint("GetArrestWarrant", pid_or_city or 0) end
function M.bandit_threat(pid_or_city) return call_or_hint("GetBanditThreat", pid_or_city or 0) end
function M.excommunication(pid_or_city) return call_or_hint("GetExcommunicationState", pid_or_city or 0) end

function M.alliance(a,b) return call_or_hint("GetAlliance", a or 0, b or 0) end
function M.ambassador(cityId) return call_or_hint("GetAmbassadorLevel", cityId or 0) end
function M.character_trait(pid, trait) return call_or_hint("GetCharacterTrait", pid or 0, trait or 0) end
function M.fair(id) return call_or_hint("GetCityFairState", id or 0) end
function M.festival_state(id) return call_or_hint("GetFestivalState", id or 0) end
function M.game_speed() return call_or_hint("GetGameSpeed") end
function M.event_state(id) return call_or_hint("GetEventState", id or 0) end
function M.evidence(id) return call_or_hint("GetEvidenceCount", id or 0) end
function M.set_faith(pid, v) local r=call_or_hint("SetFaith", pid or 0, v or 0); print(string.format("faith pid=%s -> %s", tostring(pid), tostring(v))); return r end

function M.church_corruption(cityId) return call_or_hint("GetChurchCorruption", cityId or 0) end
function M.crime(pid) return call_or_hint("GetCrimeLevel", pid or 0) end
function M.militia(cityId) return call_or_hint("GetMilitiaCount", cityId or 0) end
function M.piety(pid) return call_or_hint("GetPiety", pid or 0) end
function M.heretic(pid) return call_or_hint("GetHereticSuspicion", pid or 0) end
function M.inquisition(pid) return call_or_hint("GetInquisitionSuspicion", pid or 0) end
function M.jail_time(pid) return call_or_hint("GetJailTime", pid or 0) end
function M.player_age(pid) return call_or_hint("GetPlayerAge", pid or 0) end

function M.diplomacy(a,b) return call_or_hint("GetDiplomacy", a,b) end
function M.dynasty_reputation(pid) return call_or_hint("GetDynastyReputation", pid or 0) end
function M.player_exp(pid) return call_or_hint("GetPlayerExperience", pid or 0) end
function M.player_honor(pid) return call_or_hint("GetPlayerHonor", pid or 0) end
function M.poison(pid) return call_or_hint("GetPoisonLevel", pid or 0) end
function M.plague(cityId) return call_or_hint("GetPlagueState", cityId or 0) end
function M.public_order(cityId) return call_or_hint("GetPublicOrder", cityId or 0) end
function M.reputation_decay(a,b) return call_or_hint("GetReputationDecay", a,b) end


function M.season() return call_or_hint("GetSeason") end
function M.intrigue_level(a,b) return call_or_hint("GetIntrigueLevel", a or 0, b or 0) end
function M.set_intrigue_level(a,b,v) local r=call_or_hint("SetIntrigueLevel", a or 0, b or 0, v or 0); print(string.format("intrigue %s->%s=%s", tostring(a), tostring(b), tostring(v))); return r end
function M.office_holder(cityId, office) return call_or_hint("GetOfficeHolder", cityId or 0, office or 0) end
function M.set_office_holder(cityId, office, pid) local r=call_or_hint("SetOfficeHolder", cityId or 0, office or 0, pid or 0); print(string.format("office holder city=%s off=%s->%s", tostring(cityId), tostring(office), tostring(pid))); return r end
function M.office_term(cityId, office) return call_or_hint("GetOfficeTerm", cityId or 0, office or 0) end
function M.set_office_term(cityId, office, term) local r=call_or_hint("SetOfficeTerm", cityId or 0, office or 0, term or 0); print(string.format("office term city=%s off=%s->%s", tostring(cityId), tostring(office), tostring(term))); return r end
function M.road_bandit_risk(cityA, cityB) return call_or_hint("GetRoadBanditRisk", cityA or 0, cityB or 0) end
function M.set_road_bandit_risk(cityA, cityB, risk) local r=call_or_hint("SetRoadBanditRisk", cityA or 0, cityB or 0, risk or 0); print(string.format("bandit risk %s->%s=%s", tostring(cityA), tostring(cityB), tostring(risk))); return r end



function M.election_votes(cityId, cand) return call_or_hint("GetElectionVotes", cityId or 0, cand or 0) end
function M.set_election_votes(cityId, cand, v) local r=call_or_hint("SetElectionVotes", cityId or 0, cand or 0, v or 0); print(string.format("election city=%s cand=%s->%s", tostring(cityId), tostring(cand), tostring(v))); return r end
function M.privileges(pid) return call_or_hint("GetPrivileges", pid or 0) end
function M.marriage_state(pid, partner) return call_or_hint("GetMarriageState", pid or 0, partner or 0) end
function M.office_competition(cityId, office) return call_or_hint("GetOfficeCompetition", cityId or 0, office or 0) end
function M.patrol_strength(cityId) return call_or_hint("GetPatrolStrength", cityId or 0) end
function M.set_patrol_strength(cityId, v) local r=call_or_hint("SetPatrolStrength", cityId or 0, v or 0); print(string.format("patrol city=%s->%s", tostring(cityId), tostring(v))); return r end
function M.kidnap_chance(a,b) return call_or_hint("GetKidnapChance", a or 0, b or 0) end
function M.reputation_decay(a,b) return call_or_hint("GetReputationDecay", a or 0, b or 0) end


function M.city_rank(cityId) return call_or_hint("GetCityRank", cityId or 0) end
function M.city_growth(cityId) return call_or_hint("GetCityGrowthRate", cityId or 0) end
function M.espionage(a,b) return call_or_hint("GetEspionageLevel", a,b) end
function M.siege_progress(cityId) return call_or_hint("GetSiegeProgress", cityId or 0) end
function M.wall_garrison(cityId) return call_or_hint("GetWallGarrisonCount", cityId or 0) end
function M.watch_strength(cityId) return call_or_hint("GetWatchStrength", cityId or 0) end
function M.trial_verdict(trialId) return call_or_hint("GetTrialVerdict", trialId or 0) end
function M.worker_morale(buildingId) return call_or_hint("GetWorkerMorale", buildingId or 0) end

function M.dynasty_decay(pid) return call_or_hint("GetDynastyPrestigeDecay", pid or 0) end
function M.marriage_partner(pid) return call_or_hint("GetMarriagePartner", pid or 0) end
function M.relation(a,b) return call_or_hint("GetRelation", a,b) end
function M.robber_threat(cityId) return call_or_hint("GetRobberThreat", cityId or 0) end
function M.spy_suspicion(a,b) return call_or_hint("GetSpySuspicion", a,b) end
function M.tavern_brawl(cityId) return call_or_hint("GetTavernBrawlChance", cityId or 0) end
function M.time() return call_or_hint("GetTimeHours") end
function M.year() return call_or_hint("GetYear") end


function M.broadcast_event(eventId, payload) local r=call_or_hint("BroadcastEvent", eventId or 0, payload or ""); print(string.format("broadcast event=%s payload=%q -> %s", tostring(eventId), tostring(payload), tostring(r))); return r end
function M.divorce(pid, spouse) local r=call_or_hint("Divorce", pid or 0, spouse or 0); print(string.format("divorce pid=%s spouse=%s -> %s", tostring(pid), tostring(spouse), tostring(r))); return r end
function M.arrest_warrant(pid) return call_or_hint("GetArrestWarrant", pid or 0) end
function M.issue_warrant(issuer, target) local r=call_or_hint("IssueArrestWarrant", issuer or 0, target or 0); print(string.format("warrant %s->%s -> %s", tostring(issuer), tostring(target), tostring(r))); return r end
function M.spy_network(a,b) return call_or_hint("GetSpyNetwork", a or 0, b or 0) end
function M.diplomacy_offer(a,b,c,d,e) return call_or_hint("SendDiplomacyOffer", a or 0, b or 0, c or 0, d or 0, e or 0) end



function M.player_health(pid) return call_or_hint("GetPlayerHealth", pid or 0) end
function M.set_player_health(pid, v) local r=call_or_hint("SetPlayerHealth", pid or 0, v or 0); print(string.format("player health pid=%s->%s", tostring(pid), tostring(v))); return r end
function M.spy_info(a,b) return call_or_hint("GetSpyInfo", a or 0, b or 0) end
function M.trial_witness(trialId) return call_or_hint("GetTrialWitnessCount", trialId or 0) end
function M.is_bribed(a,b) return call_or_hint("IsBribed", a or 0, b or 0) end
function M.is_besieged(cityId) return call_or_hint("IsCityBesieged", cityId or 0) end
function M.is_office_vacant(cityId, office) return call_or_hint("IsOfficeVacant", cityId or 0, office or 0) end
function M.is_player_dead(pid) return call_or_hint("IsPlayerDead", pid or 0) end
function M.start_trial(accused, crime) local r=call_or_hint("StartTrial", accused or 0, crime or 0); print(string.format("start trial accused=%s crime=%s -> %s", tostring(accused), tostring(crime), tostring(r))); return r end
function M.trigger_event(eventId, cityId) local r=call_or_hint("TriggerEvent", eventId or 0, cityId or 0); print(string.format("trigger event=%s city=%s -> %s", tostring(eventId), tostring(cityId), tostring(r))); return r end


return M
