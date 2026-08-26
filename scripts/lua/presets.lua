-- Europa 1400 - RE Presets (cheat-sheet + discover helpers)
--
-- Central place for Europa 1400 string/pattern presets so
-- `finder`/`scan`/`valuescan` workflows can be driven without
-- re-typing candidate strings.
--
--   presets = require("presets")
--   presets.strings()               -- print curated string list
--   presets.hunt("gold")            -- string_func for synonym set
--   presets.apply("gold", base, size)
--   presets.dump("gold")            -- dump preset table

-- German needles are written as Latin-1 byte escapes (\228 = a-umlaut).
-- The game stores single-byte strings, so a UTF-8 literal here would never
-- match; confirm with scan.dump on a string you have already located.

local M = {}

-- Curated string triggers observed or likely in the game/strings.
-- The hunt() helper expands via patterns below.
M.entries = {
    -- economy / player
    { key="gold",      tags={"gold","Geld","money","thalerc","coin","ducat"} },
    { key="inventory", tags={"inventory","Inventar","waren","goods","item"} },
    { key="trade",     tags={"trade","handel","markt","market","price","preis","route","Route","diplomacy","Diplomatie","stock","Stock","aktie","Aktie","income","Income","Einkommen","supply","Supply","Angebot","demand","Demand","Nachfrage","profit","Profit","relation","Relation","Beziehung","debt","Debt","Schulden","bank","Bank","loan","Loan","Darlehen","interest","Interest","Zins","bounty","Bounty","Kopfgeld","charter","Charter","Charta"} },
    { key="fame",      tags={"fame","Ruhm","reputation","Ansehen","title","Titel","difficulty","Schwierig","health","Health","Gesundheit","experience","Experience","Erfahrung","xp","XP","donation","Donation","Spende"} },
    -- world / map
    { key="map",       tags={"karte","map","stadt","city","building","gebaeude","enter","Enter","leave","Leave"} },
    { key="unit",      tags={"unit","Einheit","soldier","guard","wache","squad","skill","Skill","Faehigkeit","family","Familie","marriage","Heirat","pos","Pos","position","Position","health","Health","Lebens"} },
    { key="clock",     tags={"clock","zeit","hour","stunde","tag","day"} },
    { key="save",      tags={"save","Speichern","Spielstand","load","laden"} },
    -- guild / building
    { key="guild",     tags={"guild","Gilde","zunft","market","markt","reputation","Reputation","dynasty","Dynastie","cash","Cash","court","Court","Hof","master","Master","Meister","fee","Fee","Gebuehr","charter","Charter"} },
    { key="building",  tags={"building","gebaeude","haus","workshop","werkstatt","warehouse","lager","upgrade","Upgrade","level","Level","hire","Hire","worker","Worker","durability","Durability","income","Income","efficiency","Effizienz","moral","morale","Morale","upkeep","Upkeep","Unterhalt","capacity","Capacity","Kapazitaet","servant","Servant","Diener","slots","Slots","harvest","Harvest","Ernte","rent","Rent","Miete","security","Security","Sicherheit","value","Value","Wert","accident","Accident","Unfall","fire","Fire","Feuer","strike","Strike","Streik","bonus","Bonus","apprentice","Apprentice","Lehrling","granary","Granary","Speicher","baker","Baker","B\228cker","master","Master","Meister","brewery","Brewery","Brauerei","mill","Mill","M\252hle","blacksmith","Blacksmith","Schmied","tannery","Tannery","Gerberei","weaver","Weaver","Weber","mint","Mint","M\252nze","herb","Herb","Kraut","vineyard","Vineyard","Weinberg","pottery","Pottery","T\246pferei","tailor","Tailor","Schneider","fishing","Fishing","Fischerei","orchard","Orchard","Obstgarten","carpenter","Carpenter","Zimmermann","ropemaker","Ropemaker","Seiler","apiary","Apiary","Imkerei","hunting","Hunting","Jagd","alchemist","Alchemist","Alchemist","glassworks","Glassworks","Glas","mason","Mason","Steinmetz","distillery","Distillery","Brennerei","pasture","Pasture","Weide","quarry","Quarry","Steinbruch","forge","Forge","Schmiede","sawmill","Sawmill","S\228gewerk","kiln","Kiln","Ofen","foundry","Foundry","Gie\223erei","apothecary","Apothecary","Apotheke","scribe","Scribe","Schreiber","goldsmith","Goldsmith","Goldschmied","falconer","Falconer","Falkner","jeweler","Jeweler","Juwelier","bathhouse","Bathhouse","Badehaus","perfumer","Perfumer","Parfum","soapmaker","Soapmaker","Seife","candlemaker","Candlemaker","Kerze","papermill","Papermill","Papier","printing","Printing","Druck","toolmaker","Toolmaker","Werkzeug","charcoal","Charcoal","Kohle","furrier","Furrier","K\252rschner","dyer","Dyer","F\228rber","saddler","Saddler","Sattler","armorer","Armorer","Plattner","bowyer","Bowyer","Bogen","cartwright","Cartwright","Wagner","mint","Mint2","winery","Winery","Kelter","shipwright","Shipwright","Schiff","cooper","Cooper","B\246ttcher","spinner","Spinner","Spinner","turner","Turner","Drechsler","barber","Barber","Barbier","stonecutter","Stonecutter","Steinmetz","cobbler","Cobbler","Schuster","butcher","Butcher","Metzger","baker2","Baker2","shepherd","Shepherd","Sch\228fer","dairy","Dairy","Molke","brewmaster","Brewmaster","Braumeister","miller","Miller","M\252ller","fishery","Fishery","chandler","Chandler","Kerzen","goldbeater","Goldbeater","Gold","potter","Potter","T\246pfer","fowler","Fowler","Vogel","vintner","Vintner","Wein","dowry","Dowry","Mitgift","wedding","Wedding","Hochzeit"} },
    { key="quest",     tags={"quest","Quest","Aufgabe","mission","Mission"} },
    { key="reputation",tags={"reputation","Reputation","Ruf","Ansehen","fame","dynasty","Dynastie","espionage","Espionage","Spionage","spy","Spy","network","Network","intrigue","Intrige","bribe","Bestechung","title","Titel","aggress","Aggress","faith","Faith","Glaube","piety","Piety","Froemmig","tithe","Tithe","Zehnten","AI","Verhalten","behavior","Behavior","court","Court","Hof","favor","Favor","Gunst","poison","Poison","Gift","assassin","Assassin","drunk","Drunk","Betrunken","apprentice","Apprentice","Lehrling","master","Master","evidence","Evidence","Beweis","trait","Trait","Charakter","kidnap","Kidnap","Entfuehr","ransom","Ransom","Loesegeld","honor","Honor","Ehre","trade","Trade","Handel","feast","Feast","Fest","favor","Favor","ambassador","Ambassador","Botschafter","bounty","Bounty","charter","Charter","xp","XP","donation","Donation","experience","Experience","noble","Noble","Adel","bandit","Bandit","suspicion","Suspicion","imperial","Imperial","Kaiser","plague","Plague","Pest","tavern","Tavern","Taverne","monastery","Monastery","Kloster","apprentice","Apprentice","gambling","Gambling","Gluecksspiel","banquet","Banquet","Bankett","decay","Decay","sin","Sin","Suende","confession","Confession","Beichte","excommunication","Excommunication","promotion","Promotion","Bef\246rderung","pilgrim","Pilgrim","relic","Relic","crusade","Crusade","Kreuzzug","university","University","Universit\228t","guard","Guard","morale","Morale","joust","Joust","tournament","Tournament","inquisition","Inquisition","smuggler","Smuggler","brewery","Brewery","cartel","Cartel","fence","Fence","jester","Jester","bard","Bard","mill","Mill","harbor","Harbor"} },
    { key="chat",      tags={"chat","Chat","message","Nachricht","broadcast","Event"} },
    { key="tax",       tags={"tax","Tax","Steuer","tribute","Tribut","levy","Levy","watch","Watch","debasement","Debasement","regulation","Regulation","dock_tax","DockTax","harbor_walls_tax","HarborWallsTax","forum_tax","ForumTax","granary_tax","GranaryTax","guild_house_tax","GuildHouseTax","house_tax","HouseTax","chapel_tax","ChapelTax","hospital_tax","HospitalTax","harbor_walls2","HarborWalls2","schoolhouse2","Schoolhouse2","library_hall2","LibraryHall2","brothel_tax","BrothelTax","harbor_walls_tax2","HarborWallsTax2","schoolhouse_tax","SchoolhouseTax","library_hall_tax","LibraryHallTax","barber_tax","BarberTax","contor_tax","ContorTax","dice_house_tax","DiceHouseTax","thieves_guild_tax","ThievesGuildTax","harbor_walls_tax3","HarborWallsTax3","schoolhouse_tax2","SchoolhouseTax2","library_hall_tax2","LibraryHallTax2","brothel_tax2","BrothelTax2","contor_tax2","ContorTax2","dice_house_tax2","DiceHouseTax2","thieves_guild_tax2","ThievesGuildTax2","harbor_walls_tax4","HarborWallsTax4","ropemaker_ws_tax","RopemakerWSTax","tannery_tax","TanneryTax","weaving_tax","WeavingTax","mint_tax","MintTax","herb_garden_tax","HerbGardenTax","vineyard_tax","VineyardTax","pottery_tax","PotteryTax","tailor_tax","TailorTax","tavern_tax","TavernTax","bathhouse_tax","BathhouseTax","church_level_tax","ChurchLevelTax","contor_level_tax","ContorLevelTax","dice_house_level_tax","DiceHouseLevelTax","thieves_guild_level_tax","ThievesGuildLevelTax","ropemaker_level_tax","RopemakerLevelTax","tannery_level_tax","TanneryLevelTax","weaving_level_tax","WeavingLevelTax","mint_level_tax","MintLevelTax","herb_garden_level_tax","HerbGardenLevelTax","vineyard_level_tax","VineyardLevelTax","pottery_level_tax","PotteryLevelTax","tailor_level_tax","TailorLevelTax","tavern_level_tax","TavernLevelTax","apothecary_level_tax","ApothecaryLevelTax","goldsmith_level_tax","GoldsmithLevelTax","jeweler_level_tax","JewelerLevelTax","perfumer_level_tax","PerfumerLevelTax","soapmaker_level_tax","SoapmakerLevelTax","candlemaker_level_tax","CandlemakerLevelTax"} },
    { key="wizard",    tags={"wizard","Zauberer","mage","Magier"} },
    { key="city",      tags={"hospital","Hospital","Hospital","clergy","Clergy","Klerus","mercenary","Mercenary","S\246ldner","siege","Siege","Belagerung","garrison","Garrison","Garnison","council","Council","Rat","patrol","Patrol","Patrouille","bandit","Bandit","tavern","Tavern","guild","Guild","intrigue","Intrigue","road","Road","city","City","Stadt","owner","Owner","besieged","Besieged","alliance","Alliance","Buendnis","treasury","Treasury","Schatz","population","Population","Bevoelkerung","happiness","Happiness","Stimmung","output","Output","Produktion","wahl","election","Election","votes","Votes","crime","Crime","Verbrechen","efficiency","Effizienz","queue","Queue","trial","Trial","Gericht","rank","Rank","Rang","prestige","Prestige","Ansehen","order","Order","Ordnung","favor","Favor","Gunst","term","Term","Amtszeit","jail","Jail","Kerker","harvest","Harvest","militia","Militia","wall","Wall","Mauer","witness","Witness","Zeuge","unrest","Unrest","Unruhe","defense","Defense","Verteidigung","security","Security","prosperity","Prosperity","Wohlstand","salary","Salary","Gehalt","value","Value","festival","Festival","Fest","feast","Feast","food","Food","Nahrung","bounty","Bounty","corruption","Corruption","Korruption","bribe","Bribe","bandit","Bandit","Rauber","suspicion","Suspicion","Verdacht","noble","Noble","Adel","bonus","Bonus","imperial","Imperial","plague","Plague","tavern","Tavern","monastery","Monastery","wall","Wall","fair","Fair","Messe","granary","Granary","toll","Toll","Zoll","gate","Gate","Tor","escort","Escort","Geleit","banquet","Banquet","harbor","Harbor","Hafen","stall","Stall","road","Road","cathedral","Cathedral","alms","Alms","indulgence","Indulgence","university","University","pilgrim","Pilgrim","relic","Relic","crusade","Crusade","joust","Joust","tournament","Tournament","brewery","Brewery","militia","Militia","upkeep","Upkeep","smuggler","Smuggler","mill","Mill","cartel","Cartel","fence","Fence","jester","Jester","bard","Bard","blacksmith","Blacksmith","dowry","Dowry","stall","Stall","church","Church","hall","Hall","market","Market","tavern","Tavern","library","Library","school","School","dock","Dock","armory","Armory","warehouse","Warehouse","mine","Mine","garrison","Garrison","bathhouse","Bathhouse","harbor_master","HarborMaster","guardhouse","Guardhouse","courthouse","Courthouse","university_hall","UniversityHall","castle","Castle","Burg","cathedral","Cathedral","monastery","Monastery","harbor","Harbor2","barracks","Barracks","Kaserne","stables","Stables","Stall","gates","Gates","Tor","sentry","Sentry","Turm","well","Well","Brunnen","bridge","Bridge","Br\252cke","wall","Wall2","tower","Tower","forum","Forum","granary","Granary","prison","Prison","harbor_dock","HarborDock","guild_house","GuildHouse","house","House","chapel","Chapel","hospital","Hospital","brothel","Brothel","harbor_walls","HarborWalls","schoolhouse","Schoolhouse","library_hall","LibraryHall","barber","Barber","contor","Contor","dice","Dice","thieves","Thieves","ropemaker","Ropemaker","tannery","Tannery","weaving","Weaving","mint","Mint","herb_garden","HerbGarden","vineyard","Vineyard","pottery","Pottery","tailor","Tailor","apothecary_level","ApothecaryLevel","goldsmith_level","GoldsmithLevel","jeweler_level","JewelerLevel","perfumer_level","PerfumerLevel","soapmaker_level","SoapmakerLevel","candlemaker_level","CandlemakerLevel","papermill_level","PapermillLevel","printing_house","PrintingHouse","toolmaker_level","ToolmakerLevel","charcoal_level","CharcoalLevel","furrier_level","FurrierLevel","dyer_level","DyerLevel","saddler_level","SaddlerLevel","armorer_level","ArmorerLevel","bowyer_level","BowyerLevel","cartwright_level","CartwrightLevel","carpenter_level","CarpenterLevel","cooper_level","CooperLevel","spinner_level","SpinnerLevel","turner_level","TurnerLevel","stonecutter_level","StonecutterLevel","cobbler_level","CobblerLevel","butcher_level","ButcherLevel","baker_level","BakerLevel","shepherd_level","ShepherdLevel","dairy_level","DairyLevel","brewmaster_level","BrewmasterLevel","miller_level","MillerLevel","fishery_level","FisheryLevel","chandler_level","ChandlerLevel","goldbeater_level","GoldbeaterLevel","potter_level","PotterLevel","fowler_level","FowlerLevel","vintner_level","VintnerLevel","distiller_level","DistillerLevel","cook_level","CookLevel","brickmaker_level","BrickmakerLevel","tavern_level2","TavernLevel","mill_level","MillLevel","brewery_tavern","BreweryTavern","smith_level","SmithLevel","carpenters_level","CarpentersLevel","tailor_workshop","TailorWorkshop","joiner_workshop","JoinerWorkshop","carter_workshop","CarterWorkshop","mining_workshop","MiningWorkshop","logging_workshop","LoggingWorkshop","inn_level","InnLevel","robber_camp","RobberCamp","joiner_ws2","JoinerWS2","carter_ws2","CarterWS2","mining_ws2","MiningWS2","logging_ws2","LoggingWS2","inn_level2","InnLevel2","robber_camp2","RobberCamp2","toll_gate","TollGate","road_level","RoadLevel","toll_gate_tax","TollGateTax","bridge_cost","BridgeCost","tannery","Tannery","weaver","Weaver","mint","Mint","herb","Herb","fee","Fee"} },
    -- UI / engine / civic
    { key="dialog",    tags={"dialog","Dialog","MessageBox","Message"} },
    { key="civic",     tags={"wahl","election","Election","votes","Votes","trial","Trial","Gericht","crime","Crime","Verbrechen","moral","morale","Morale","event","Event","Ereignis","durability","Durability","income","Income","Einkommen","guard","Guard","Wache","cart","Cart","Karren","bribe","Bribe","Bestechung","tax","Tax","Steuer","harvest","Harvest","order","Order","jail","Jail","favor","Gunst","rank","Rank","prestige","Prestige"} },
    { key="network",   tags={"socket","connect","packet","send","recv"} },
}

function M.list_keys()
    local ks = {}
    for _, e in ipairs(M.entries) do ks[#ks+1] = e.key end
    return ks
end

function M.strings()
    print("Presets (key -> tags):")
    for _, e in ipairs(M.entries) do
        print(string.format("  %-10s : %s", e.key, table.concat(e.tags, ", ")))
    end
    print("\nUse: presets.hunt('gold')  or  presets.hunt('gold', base, size)")
    return M.entries
end

function M.tags_for(key)
    for _, e in ipairs(M.entries) do
        if e.key == key then return e.tags end
    end
    -- if key itself looks like a plain string, treat as singleton
    if type(key) == "string" and key ~= "" then return { key } end
    return nil
end

-- Run finder.string_func for every tag in the preset (or single string)
function M.hunt(key, base, size, opts)
    opts = opts or {}
    base = base or 0x00400000
    size = size or 0x300000
    local finder = require("finder")
    local tags = M.tags_for(key)
    if not tags then error("unknown preset key: " .. tostring(key)) end
    local all = {}
    local seen = {}
    for _, s in ipairs(tags) do
        local hits = finder.string_func(s, base, size, opts) or {}
        for _, h in ipairs(hits) do
            local addr = type(h) == "table" and (h.addr or h) or h
            if type(addr) == "number" and not seen[addr] then
                seen[addr] = true
                all[#all+1] = addr
            end
        end
    end
    table.sort(all)
    print(string.format("presets.hunt('%s'): %d unique func(s)", tostring(key), #all))
    for _, a in ipairs(all) do print(string.format("  0x%08X", a)) end
    return all
end

-- Apply: hunt + optionally register
function M.apply(key, base, size, signature, prefix)
    local hits = M.hunt(key, base, size)
    if signature and #hits > 0 then
        local finder = require("finder")
        if finder.register_hits then
            finder.register_hits(prefix or (tostring(key) .. "_fn"), signature, hits)
        else
            for i, addr in ipairs(hits) do
                _G.game.register(string.format("%s_fn_%d", tostring(key), i), addr, signature, "preset " .. tostring(key))
            end
        end
    end
    return hits
end

function M.dump(key)
    if key then
        local tags = M.tags_for(key)
        if not tags then error("unknown preset: " .. tostring(key)) end
        print(key .. " : " .. table.concat(tags, ", "))
        return tags
    end
    return M.strings()
end

return M
