-- Europa 1400 - Social / Guild / Relations Helper
--
-- Wraps guild membership, privileges, nobility, reputation, diplomacy,
-- alliance, family and marriage catalog entries behind `social.*`.
--
--   social = require("social")  -- or already `social`
--   social.find()                       -- catalog.hunt("guild") + reputation/diplomacy
--   social.scan(0x00400000, 0x300000)   -- presets.hunt guild/reputation/chat/unit
--   social.is_member(pid, gid)          -- IsGuildMember
--   social.join(pid, gid) / social.leave(gid)
--   social.guild_rank(pid, gid) / social.set_guild_rank(pid, gid, rank)
--   social.nobility(pid) / social.set_nobility(pid, title)
--   social.privileges(pid)
--   social.reputation(pid, faction) / social.set_reputation(pid, faction, v)
--   social.diplomacy(a,b) / social.set_diplomacy(a,b,v)
--   social.alliance(a,b) / social.set_alliance(a,b,state)
--   social.family_count(familyId)       -- GetFamilyMemberCount
--   social.marriage(pid, spouse)        -- GetMarriageState
--   social.marriage_partner(pid)        -- GetMarriagePartner
--   social.divorce(pid, spouse)
--   social.chat(pid, text)              -- SendChatMessage
--   social.broadcast(eventId, payload)  -- BroadcastEvent
--
-- All wrappers pcall game.call and error with a hint if not yet registered.

local M = {}

local game = require("gamecalls")

local function call_or_hint(name, ...)
    if not game.get_address(name) then
        error(name .. " not registered; run social.find() / catalog.hunt('guild') or game.register first", 2)
    end
    local ok, ret = pcall(game.call, name, ...)
    if ok then return ret end
    error(tostring(ret), 0)
end

function M.scan(base, size)
    base = base or 0x00400000; size = size or 0x300000
    print(string.format("social.scan [0x%08X +0x%X]", base, size))
    local presets = require("presets")
    local hits = {}
    if presets and presets.hunt then
        for _, key in ipairs({ "guild", "reputation", "chat", "unit", "fame" }) do
            local h = presets.hunt(key, base, size) or {}
            for _, a in ipairs(h) do hits[#hits+1] = a end
        end
        local seen, uniq = {}, {}
        for _, a in ipairs(hits) do if not seen[a] then seen[a]=true; uniq[#uniq+1]=a end end
        hits = uniq; table.sort(hits)
        if #hits > 0 then print(string.format("social.scan: %d unique hit(s)", #hits)); return hits end
    end
    print("social.scan: no hits; try social.find() or wider base/size")
    return hits
end

function M.find(base, size)
    local cat = require("catalog")
    if not cat or not cat.hunt then error("catalog not available") end
    -- try guild tag first, then fall back to player/state
    local out = cat.hunt("guild", base, size)
    if #out == 0 then out = cat.hunt("player", base, size) end
    return out
end

-- guild
function M.is_member(pid, gid) return call_or_hint("IsGuildMember", pid, gid) end
function M.join(pid, gid) local r=call_or_hint("JoinGuild", pid, gid); print(string.format("guild join player=%s guild=%s -> %s", tostring(pid), tostring(gid), tostring(r))); return r end
function M.leave(gid) local r=call_or_hint("LeaveGuild", gid); print(string.format("guild leave %s -> %s", tostring(gid), tostring(r))); return r end
function M.guild_rank(pid, gid) return call_or_hint("GetGuildRank", pid, gid) end
function M.set_guild_rank(pid, gid, rank) local r=call_or_hint("SetGuildRank", pid, gid, rank); print(string.format("guild rank player=%s guild=%s -> %s", tostring(pid), tostring(gid), tostring(rank))); return r end

-- player standing
function M.nobility(pid) return call_or_hint("NobilityTitle", pid) end
function M.set_nobility(pid, title) local r=call_or_hint("SetNobilityTitle", pid, title); print(string.format("nobility player=%s -> %s", tostring(pid), tostring(title))); return r end
function M.privileges(pid) return call_or_hint("GetPrivileges", pid) end

-- reputation / diplomacy / alliance
function M.reputation(pid, fid) return call_or_hint("GetReputation", pid, fid) end
function M.set_reputation(pid, fid, v) local r=call_or_hint("SetReputation", pid, fid, v); print(string.format("reputation player=%s faction=%s -> %s", tostring(pid), tostring(fid), tostring(v))); return r end
function M.diplomacy(a,b) return call_or_hint("GetDiplomacy", a, b) end
function M.set_diplomacy(a,b,v) local r=call_or_hint("SetDiplomacy", a, b, v); print(string.format("diplomacy %s<->%s -> %s", tostring(a), tostring(b), tostring(v))); return r end
function M.alliance(a,b) return call_or_hint("GetAlliance", a, b) end
function M.set_alliance(a,b,state) local r=call_or_hint("SetAlliance", a, b, state); print(string.format("alliance %s<->%s -> %s", tostring(a), tostring(b), tostring(state))); return r end

-- family / marriage
function M.family_count(familyId) return call_or_hint("GetFamilyMemberCount", familyId) end
function M.marriage(pid, spouse) return call_or_hint("GetMarriageState", pid, spouse) end
function M.marriage_partner(pid) return call_or_hint("GetMarriagePartner", pid) end
function M.divorce(pid, spouse) local r=call_or_hint("Divorce", pid, spouse); print(string.format("divorce %s <-> %s -> %s", tostring(pid), tostring(spouse), tostring(r))); return r end
function M.is_dead(pid) return call_or_hint("IsPlayerDead", pid) end
function M.dynasty_name(dynastyId) return call_or_hint("GetDynastyName", dynastyId) end
function M.set_dynasty_name(dynastyId, name) local r=call_or_hint("SetDynastyName", dynastyId, name); print(string.format("dynasty %s -> %q", tostring(dynastyId), tostring(name))); return r end
function M.espionage(playerId, targetId) return call_or_hint("GetEspionageLevel", playerId, targetId) end
function M.set_espionage(playerId, targetId, lvl) local r=call_or_hint("SetEspionageLevel", playerId, targetId, lvl); print(string.format("espionage %s -> %s -> %s", tostring(playerId), tostring(targetId), tostring(lvl))); return r end
function M.intrigue(playerId, targetId) return call_or_hint("GetIntrigueLevel", playerId, targetId) end
function M.set_intrigue(playerId, targetId, lvl) local r=call_or_hint("SetIntrigueLevel", playerId, targetId, lvl); print(string.format("intrigue %s -> %s -> %s", tostring(playerId), tostring(targetId), tostring(lvl))); return r end
function M.aggressiveness(playerId) return call_or_hint("GetAggressiveness", playerId) end
function M.set_aggressiveness(playerId, lvl) local r=call_or_hint("SetAggressiveness", playerId, lvl); print(string.format("aggressiveness %s -> %s", tostring(playerId), tostring(lvl))); return r end
function M.is_title_available(titleId) return call_or_hint("IsTitleAvailable", titleId) end
function M.claim_title(playerId, titleId) local r=call_or_hint("ClaimTitle", playerId, titleId); print(string.format("claim title player=%s title=%s -> %s", tostring(playerId), tostring(titleId), tostring(r))); return r end
function M.title_cost(titleId) return call_or_hint("GetTitleCost", titleId) end
function M.influence(playerId, cityId) return call_or_hint("GetInfluence", playerId, cityId) end
function M.set_influence(playerId, cityId, v) local r=call_or_hint("SetInfluence", playerId, cityId, v); print(string.format("influence player=%s city=%s -> %s", tostring(playerId), tostring(cityId), tostring(v))); return r end
function M.guild_reputation(playerId, guildId) return call_or_hint("GetGuildReputation", playerId, guildId) end
function M.set_guild_reputation(playerId, guildId, rep) local r=call_or_hint("SetGuildReputation", playerId, guildId, rep); print(string.format("guild rep player=%s guild=%s -> %s", tostring(playerId), tostring(guildId), tostring(rep))); return r end
function M.dynasty_cash(dynastyId) return call_or_hint("GetDynastyCash", dynastyId) end
function M.set_dynasty_cash(dynastyId, amount) local r=call_or_hint("SetDynastyCash", dynastyId, amount); print(string.format("dynasty cash %s -> %s", tostring(dynastyId), tostring(amount))); return r end
function M.court_influence(playerId) return call_or_hint("GetCourtInfluence", playerId) end
function M.set_court_influence(playerId, v) local r=call_or_hint("SetCourtInfluence", playerId, v); print(string.format("court influence player=%s -> %s", tostring(playerId), tostring(v))); return r end
function M.relation(a,b) return call_or_hint("GetRelation", a, b) end
function M.set_relation(a,b,v) local r=call_or_hint("SetRelation", a, b, v); print(string.format("relation %s<->%s -> %s", tostring(a), tostring(b), tostring(v))); return r end
function M.prestige(playerId) return call_or_hint("GetPrestige", playerId) end
function M.set_prestige(playerId, v) local r=call_or_hint("SetPrestige", playerId, v); print(string.format("prestige player=%s -> %s", tostring(playerId), tostring(v))); return r end
function M.disease(playerId) return call_or_hint("GetDiseaseState", playerId) end
function M.set_disease(playerId, v) local r=call_or_hint("SetDiseaseState", playerId, v); print(string.format("disease player=%s -> %s", tostring(playerId), tostring(v))); return r end
function M.court_rank(playerId) return call_or_hint("GetCourtRank", playerId) end
function M.set_court_rank(playerId, v) local r=call_or_hint("SetCourtRank", playerId, v); print(string.format("court rank player=%s -> %s", tostring(playerId), tostring(v))); return r end
function M.ai_behavior(playerId) return call_or_hint("GetAIBehavior", playerId) end
function M.set_ai_behavior(playerId, v) local r=call_or_hint("SetAIBehavior", playerId, v); print(string.format("ai_behavior player=%s -> %s", tostring(playerId), tostring(v))); return r end
function M.faith(playerId) return call_or_hint("GetFaith", playerId) end
function M.set_faith(playerId, v) local r=call_or_hint("SetFaith", playerId, v); print(string.format("faith player=%s -> %s", tostring(playerId), tostring(v))); return r end
function M.tithe(cityId) return call_or_hint("GetTitheRate", cityId) end
function M.set_tithe(cityId, v) local r=call_or_hint("SetTitheRate", cityId, v); print(string.format("tithe city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.piety(playerId) return call_or_hint("GetPiety", playerId) end
function M.set_piety(playerId, v) local r=call_or_hint("SetPiety", playerId, v); print(string.format("piety player=%s -> %s", tostring(playerId), tostring(v))); return r end
function M.court_favor(playerId, nobleId) return call_or_hint("GetCourtFavor", playerId, nobleId) end
function M.set_court_favor(playerId, nobleId, v) local r=call_or_hint("SetCourtFavor", playerId, nobleId, v); print(string.format("court favor player=%s noble=%s -> %s", tostring(playerId), tostring(nobleId), tostring(v))); return r end
function M.dynasty_members(dynastyId) return call_or_hint("GetDynastyMembers", dynastyId) end
function M.guild_master(guildId) return call_or_hint("GetGuildMaster", guildId) end
function M.set_guild_master(guildId, playerId) local r=call_or_hint("SetGuildMaster", guildId, playerId); print(string.format("guild master guild=%s -> player %s", tostring(guildId), tostring(playerId))); return r end
function M.bribe_success(pid, cityId, officeId) return call_or_hint("GetBribeSuccess", pid, cityId, officeId) end
function M.spy_info(pid, targetId) return call_or_hint("GetSpyInfo", pid, targetId) end
function M.dynasty_reputation(dynastyId) return call_or_hint("GetDynastyReputation", dynastyId) end
function M.set_dynasty_reputation(dynastyId, v) local r=call_or_hint("SetDynastyReputation", dynastyId, v); print(string.format("dynasty rep %s -> %s", tostring(dynastyId), tostring(v))); return r end
function M.family_wealth(familyId) return call_or_hint("GetFamilyWealth", familyId) end
function M.set_family_wealth(familyId, v) local r=call_or_hint("SetFamilyWealth", familyId, v); print(string.format("family wealth %s -> %s", tostring(familyId), tostring(v))); return r end
function M.court_influence_level(playerId, level) return call_or_hint("GetCourtInfluenceLevel", playerId, level) end
function M.set_court_influence_level(playerId, level, v) local r=call_or_hint("SetCourtInfluenceLevel", playerId, level, v); print(string.format("court influence lvl player=%s lvl=%s -> %s", tostring(playerId), tostring(level), tostring(v))); return r end
function M.assassin_level(playerId) return call_or_hint("GetAssassinLevel", playerId) end
function M.set_assassin_level(playerId, v) local r=call_or_hint("SetAssassinLevel", playerId, v); print(string.format("assassin lvl player=%s -> %s", tostring(playerId), tostring(v))); return r end
function M.arrest_warrant(playerId) return call_or_hint("GetArrestWarrant", playerId) end
function M.issue_warrant(issuerId, targetId) local r=call_or_hint("IssueArrestWarrant", issuerId, targetId); print(string.format("warrant %s -> %s = %s", tostring(issuerId), tostring(targetId), tostring(r))); return r end
function M.poison(playerId) return call_or_hint("GetPoisonLevel", playerId) end
function M.set_poison(playerId, v) local r=call_or_hint("SetPoisonLevel", playerId, v); print(string.format("poison player=%s -> %s", tostring(playerId), tostring(v))); return r end
function M.drunk(playerId) return call_or_hint("GetDrunkLevel", playerId) end
function M.set_drunk(playerId, v) local r=call_or_hint("SetDrunkLevel", playerId, v); print(string.format("drunk player=%s -> %s", tostring(playerId), tostring(v))); return r end
function M.title_tier(titleId) return call_or_hint("GetTitleTier", titleId) end
function M.evidence(playerId) return call_or_hint("GetEvidenceCount", playerId) end
function M.jail_time(playerId) return call_or_hint("GetJailTime", playerId) end
function M.set_jail_time(playerId, v) local r=call_or_hint("SetJailTime", playerId, v); print(string.format("jail_time player=%s -> %s", tostring(playerId), tostring(v))); return r end
function M.public_order(cityId) return call_or_hint("GetPublicOrder", cityId) end
function M.set_public_order(cityId, v) local r=call_or_hint("SetPublicOrder", cityId, v); print(string.format("public order city=%s -> %s", tostring(cityId), tostring(v))); return r end
function M.city_favor(cityId, playerId) return call_or_hint("GetCityFavor", cityId, playerId) end
function M.set_city_favor(cityId, playerId, v) local r=call_or_hint("SetCityFavor", cityId, playerId, v); print(string.format("city favor city=%s player=%s -> %s", tostring(cityId), tostring(playerId), tostring(v))); return r end
function M.spy_network(playerId, cityId) return call_or_hint("GetSpyNetwork", playerId, cityId) end
function M.age(playerId) return call_or_hint("GetPlayerAge", playerId) end
function M.set_age(playerId, v) local r=call_or_hint("SetPlayerAge", playerId, v); print(string.format("age player=%s -> %s", tostring(playerId), tostring(v))); return r end
function M.heir(playerId) return call_or_hint("GetHeir", playerId) end
function M.set_heir(playerId, v) local r=call_or_hint("SetHeir", playerId, v); print(string.format("heir player=%s -> %s", tostring(playerId), tostring(v))); return r end
function M.honor(playerId) return call_or_hint("GetPlayerHonor", playerId) end
function M.set_honor(playerId, v) local r=call_or_hint("SetPlayerHonor", playerId, v); print(string.format("honor player=%s -> %s", tostring(playerId), tostring(v))); return r end
function M.trait(playerId, traitId) return call_or_hint("GetCharacterTrait", playerId, traitId) end
function M.set_trait(playerId, traitId, v) local r=call_or_hint("SetCharacterTrait", playerId, traitId, v); print(string.format("trait player=%s trait=%s -> %s", tostring(playerId), tostring(traitId), tostring(v))); return r end
function M.kidnap_chance(a,b) return call_or_hint("GetKidnapChance", a, b) end
function M.ransom(pid) return call_or_hint("GetRansomPrice", pid) end
function M.set_ransom(pid, v) local r=call_or_hint("SetRansomPrice", pid, v); print(string.format("ransom player=%s -> %s", tostring(pid), tostring(v))); return r end
function M.papal_favor(pid) return call_or_hint("GetPapalFavor", pid) end
function M.set_papal_favor(pid, v) local r=call_or_hint("SetPapalFavor", pid, v); print(string.format("papal favor player=%s -> %s", tostring(pid), tostring(v))); return r end
function M.heretic(pid) return call_or_hint("GetHereticSuspicion", pid) end
function M.set_heretic(pid, v) local r=call_or_hint("SetHereticSuspicion", pid, v); print(string.format("heretic suspicion player=%s -> %s", tostring(pid), tostring(v))); return r end
function M.trade_rep(pid, cityId) return call_or_hint("GetTradeReputation", pid, cityId) end
function M.set_trade_rep(pid, cityId, v) local r=call_or_hint("SetTradeReputation", pid, cityId, v); print(string.format("trade rep player=%s city=%s -> %s", tostring(pid), tostring(cityId), tostring(v))); return r end
function M.feast_cost(pid, ftype) return call_or_hint("GetFeastCost", pid, ftype) end
function M.favor_debt(a,b) return call_or_hint("GetFavorDebt", a, b) end
function M.set_favor_debt(a,b,v) local r=call_or_hint("SetFavorDebt", a, b, v); print(string.format("favor debt %s->%s -> %s", tostring(a), tostring(b), tostring(v))); return r end
function M.ambassador(pid) return call_or_hint("GetAmbassadorLevel", pid) end
function M.set_ambassador(pid, v) local r=call_or_hint("SetAmbassadorLevel", pid, v); print(string.format("ambassador player=%s -> %s", tostring(pid), tostring(v))); return r end
function M.bounty(pid) return call_or_hint("GetBountyPrice", pid) end
function M.set_bounty(pid, v) local r=call_or_hint("SetBountyPrice", pid, v); print(string.format("bounty player=%s -> %s", tostring(pid), tostring(v))); return r end
function M.charter_cost(gid) return call_or_hint("GetGuildCharterCost", gid) end
function M.xp(pid) return call_or_hint("GetPlayerExperience", pid) end
function M.set_xp(pid, v) local r=call_or_hint("SetPlayerExperience", pid, v); print(string.format("xp player=%s -> %s", tostring(pid), tostring(v))); return r end
function M.church_donation(pid) return call_or_hint("GetChurchDonationTotal", pid) end
function M.set_church_donation(pid, v) local r=call_or_hint("SetChurchDonationTotal", pid, v); print(string.format("church donation player=%s -> %s", tostring(pid), tostring(v))); return r end
function M.noble_house(pid) return call_or_hint("GetNobleHouseRank", pid) end
function M.set_noble_house(pid, v) local r=call_or_hint("SetNobleHouseRank", pid, v); print(string.format("noble house player=%s -> %s", tostring(pid), tostring(v))); return r end
function M.nepotism(pid, officeId) return call_or_hint("GetNepotismLevel", pid, officeId) end
function M.set_nepotism(pid, officeId, v) local r=call_or_hint("SetNepotismLevel", pid, officeId, v); print(string.format("nepotism player=%s office=%s -> %s", tostring(pid), tostring(officeId), tostring(v))); return r end
function M.bishop(pid, dioceseId) return call_or_hint("GetBishopInfluence", pid, dioceseId) end
function M.reputation_decay(pid, fid) return call_or_hint("GetReputationDecay", pid, fid) end
function M.set_reputation_decay(pid, fid, v) local r=call_or_hint("SetReputationDecay", pid, fid, v); print(string.format("rep decay player=%s faction=%s -> %s", tostring(pid), tostring(fid), tostring(v))); return r end
function M.banquet_bonus(typ) return call_or_hint("GetBanquetPrestigeBonus", typ) end
function M.gambling_debt(pid) return call_or_hint("GetGamblingDebt", pid) end
function M.set_gambling_debt(pid, v) local r=call_or_hint("SetGamblingDebt", pid, v); print(string.format("gambling debt player=%s -> %s", tostring(pid), tostring(v))); return r end
function M.imperial(pid) return call_or_hint("GetImperialFavor", pid) end
function M.set_imperial(pid, v) local r=call_or_hint("SetImperialFavor", pid, v); print(string.format("imperial favor player=%s -> %s", tostring(pid), tostring(v))); return r end
function M.tavern(pid, cityId) return call_or_hint("GetTavernReputation", pid, cityId) end
function M.monastery(pid, cityId) return call_or_hint("GetMonasteryInfluence", pid, cityId) end
function M.title_rank(pid, titleId) return call_or_hint("GetTitleRank", pid, titleId) end
function M.cathedral(pid, cityId) return call_or_hint("GetCathedralInfluence", pid, cityId) end
function M.alms(pid) return call_or_hint("GetAlmsEffectiveness", pid) end
function M.indulgence_cost(pid, lvl) return call_or_hint("GetIndulgenceCost", pid, lvl) end
function M.dynasty_prestige_decay(pid) return call_or_hint("GetDynastyPrestigeDecay", pid) end
function M.sin(pid) return call_or_hint("GetSinLevel", pid) end
function M.set_sin(pid, lvl) local r=call_or_hint("SetSinLevel", pid, lvl); print(string.format("sin player=%s -> %s", tostring(pid), tostring(lvl))); return r end
function M.confession_cost(pid, lvl) return call_or_hint("GetConfessionCost", pid, lvl) end
function M.excommunication(pid) return call_or_hint("GetExcommunicationState", pid) end
function M.set_excommunication(pid, v) local r=call_or_hint("SetExcommunicationState", pid, v); print(string.format("excommunication player=%s -> %s", tostring(pid), tostring(v))); return r end
function M.guild_promotion_cost(gid, rank) return call_or_hint("GetGuildPromotionCost", gid, rank) end
function M.pilgrimage_cost(pid, ptype) return call_or_hint("GetPilgrimageCost", pid, ptype) end
function M.relic_value(rid) return call_or_hint("GetRelicValue", rid) end
function M.crusade(pid, cid) return call_or_hint("GetCrusadeContribution", pid, cid) end
function M.set_crusade(pid, cid, v) local r=call_or_hint("SetCrusadeContribution", pid, cid, v); print(string.format("crusade player=%s crusade=%s -> %s", tostring(pid), tostring(cid), tostring(v))); return r end
function M.joust(pid, jtype) return call_or_hint("GetJoustReward", pid, jtype) end
function M.tournament(pid, tid) return call_or_hint("GetTournamentStanding", pid, tid) end
function M.inquisition(pid) return call_or_hint("GetInquisitionSuspicion", pid) end
function M.set_inquisition(pid, v) local r=call_or_hint("SetInquisitionSuspicion", pid, v); print(string.format("inquisition player=%s -> %s", tostring(pid), tostring(v))); return r end
function M.cartel(pid, cityId) return call_or_hint("GetCartelInfluence", pid, cityId) end
function M.fence_price(pid, goodId) return call_or_hint("GetFencePrice", pid, goodId) end
function M.jester(pid) return call_or_hint("GetCourtJesterEffect", pid) end
function M.bard(pid, cityId) return call_or_hint("GetBardInfluence", pid, cityId) end
function M.dowry(pid, spouse) return call_or_hint("GetDowryAmount", pid, spouse) end
function M.wedding(pid, wtype) return call_or_hint("GetWeddingCost", pid, wtype) end
function M.patrician(pid, cityId) return call_or_hint("GetPatricianInfluence", pid, cityId) end
function M.noble_auth(pid, cityId) return call_or_hint("GetNobleAuthority", pid, cityId) end
function M.clergy(pid, cityId) return call_or_hint("GetClergyInfluence", pid, cityId) end
function M.council_power(pid, cityId) return call_or_hint("GetCouncilVotePower", pid, cityId) end
function M.court_intrigue(pid, cityId) return call_or_hint("GetCourtIntriguePower", pid, cityId) end
function M.church(pid, cityId) return call_or_hint("GetChurchInfluence", pid, cityId) end
function M.noble_demands(pid, cityId) return call_or_hint("GetNobleDemands", pid, cityId) end
function M.office_competition(cityId, officeId) return call_or_hint("GetOfficeCompetition", cityId, officeId) end

-- chat / events
function M.chat(pid, text) local r=call_or_hint("SendChatMessage", pid, text); print(string.format("chat player=%s %q -> %s", tostring(pid), tostring(text), tostring(r))); return r end
function M.broadcast(eventId, payload) local r=call_or_hint("BroadcastEvent", eventId, payload); print(string.format("broadcast event=%s -> %s", tostring(eventId), tostring(r))); return r end

return M
