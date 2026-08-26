-- Europa 1400 - Known Enums & Lookup Helpers
--
-- Best-effort enums extracted from public wikis and observed strings.
-- Lets you decode dumped ints without memorizing magic numbers.
--
--   enums = require("enums")  -- or already `enums`
--   enums.building(3)
--   enums.good(0)
--   enums.title(5)
--   enums.lookup("building", 3)    -- generic
--   enums.dump("building")         -- list all

local M = {}

M.building = {
    [0]="Church", [1]="Tavern", [2]="Market", [3]="Workshop",
    [4]="House", [5]="GuildHall", [6]="Farm", [7]="Mine",
    [8]="Harbor", [9]="Bank", [10]="TownHall", [11]="Monastery",
}

M.title = {
    [0]="Serf", [1]="Citizen", [2]="Patrician", [3]="Noble",
    [4]="Councillor", [5]="Mayor", [6]="GuildMaster",
}

M.good = {
    [0]="Wood", [1]="Stone", [2]="Wool", [3]="Cloth", [4]="Iron",
    [5]="Tools", [6]="Wheat", [7]="Flour", [8]="Bread", [9]="Beer",
    [10]="Meat", [11]="Fish", [12]="Gold", [13]="Perfume", [14]="Jewellery",
}

M.unit_type = {
    [0]="Peasant", [1]="Craftsman", [2]="Guard", [3]="Thief",
    [4]="Priest", [5]="Scholar", [6]="Noble_unit",
}

M.skill = {
    [0]="Charisma", [1]="Bargaining", [2]="Combat", [3]="Stealth",
    [4]="Crafting", [5]="Rhetoric", [6]="Empathy", [7]="Shadow_arts",
}

M.season = {
    [0]="Spring", [1]="Summer", [2]="Autumn", [3]="Winter",
}

M.difficulty = {
    [0]="Easy", [1]="Normal", [2]="Hard", [3]="VeryHard",
}

M.guild = {
    [0]="Thieves", [1]="Merchants", [2]="Craftsmen", [3]="Clergy",
    [4]="Nobility", [5]="Underworld",
}

M.office = {
    [0]="Councillor", [1]="Judge", [2]="Treasurer", [3]="Mayor",
    [4]="GuildMaster", [5]="Bishop",
}

M.faction = {
    [0]="City", [1]="Church", [2]="Guild", [3]="Nobility",
    [4]="Commoners", [5]="Crown",
}

M.quest_status = {
    [0]="Inactive", [1]="Active", [2]="Completed", [3]="Failed", [4]="Expired",
}

M.marriage = {
    [0]="Single", [1]="Married", [2]="Widowed", [3]="Divorced",
}

M.crime = {
    [0]="Theft", [1]="Assault", [2]="Murder", [3]="Fraud", [4]="Heresy",
    [5]="Treason", [6]="Bribery",
}

M.production = {
    [0]="Idle", [1]="Producing", [2]="Blocked", [3]="NoWorkers",
    [4]="NoInput", [5]="FullOutput",
}

M.morale = {
    [0]="Mutinous", [1]="Unhappy", [2]="Neutral", [3]="Content", [4]="Happy",
}

M.world_event = {
    [0]="Plague", [1]="Famine", [2]="Fire", [3]="Fair", [4]="Tournament",
    [5]="Election", [6]="Trial", [7]="War",
}

M.stock = {
    [0]="GuildShare", [1]="CityBond", [2]="TradeContract", [3]="Loan",
}

M.court_favor = {
    [0]="Neutral", [1]="Liked", [2]="Favored", [3]="Trusted", [4]="InnerCircle",
}

local maps = {
    building = "building",
    title    = "title",
    good     = "good",
    goods    = "good",
    item     = "good",
    unit     = "unit_type",
    unit_type= "unit_type",
    skill    = "skill",
    season   = "season",
    difficulty="difficulty",
    guild    = "guild",
    office   = "office",
    faction  = "faction",
    quest_status = "quest_status",
    quest    = "quest_status",
    marriage = "marriage",
    crime    = "crime",
    production = "production",
    morale   = "morale",
    world_event = "world_event",
    event    = "world_event",
    stock    = "stock",
    court_favor = "court_favor",
    favor    = "court_favor",
}

function M.lookup(kind, id)
    if type(kind) ~= "string" or kind == "" then error("kind required") end
    local key = maps[kind:lower()] or kind:lower()
    local tbl = M[key]
    if type(tbl) ~= "table" then error("unknown enum: " .. tostring(kind)) end
    local name = tbl[id]
    if name then
        print(string.format("%s[%d] = %q", key, id, name))
        return name
    else
        print(string.format("%s[%d] = <unknown>", key, id))
        return nil
    end
end

function M.dump(kind)
    if kind then
        local key = maps[kind:lower()] or kind:lower()
        local tbl = M[key]
        if not tbl then error("unknown enum: " .. tostring(kind)) end
        print(string.format("Enum %s:", key))
        local keys = {}
        for k in pairs(tbl) do keys[#keys+1]=k end
        table.sort(keys)
        for _, k in ipairs(keys) do
            print(string.format("  %2d  %s", k, tbl[k]))
        end
        return tbl
    end
    print("Enums: building, title, good, unit_type, skill, season, difficulty, guild, office, faction, quest_status, marriage, crime, production, morale, world_event, stock, court_favor")
    print("Use: enums.dump('building')  or  enums.lookup('good', 12)")
    return maps
end

-- convenience aliases
M.buildings = M.building
M.titles    = M.title
M.goods     = M.good
M.skills    = M.skill
M.seasons   = M.season
M.difficulties = M.difficulty
M.guilds    = M.guild
M.offices   = M.office
M.factions  = M.faction
M.quest_statuses = M.quest_status
M.crimes    = M.crime
M.productions = M.production
M.morales   = M.morale
M.events    = M.world_event
M.world_events = M.world_event
M.stocks    = M.stock
M.court_favors = M.court_favor
M.favors    = M.court_favor

return M
