-- Europa 1400 - Nearby Function Finder
--
-- When you find one function, neighbours are often related
-- (e.g. GetGold next to SetGold). This helper lists prologues
-- near an address so you can triage a whole cluster.
--
--   near = dofile('lua/near.lua')  -- or already `near`
--   near.around(0x401000, 0x1000)          -- funcs within ±0x1000
--   near.around(0x401000, 0x1000, 5)        -- up to 5 closest
--   near.list(0x401000, 0x800, 10)          -- sorted by distance

local M = {}

function M.around(addr, radius, limit)
    if type(addr) == "string" then
        local s = addr:gsub("^0[xX]","")
        addr = tonumber(s, 16)
        if not addr then error("invalid addr: " .. tostring(addr)) end
    end
    if type(addr) ~= "number" then error("addr must be number or hex string") end
    radius = radius or 0x1000
    limit  = limit  or 20
    local finder = _G.finder or (pcall(dofile, "lua/finder.lua") and _G.finder)
    if not finder or not finder.prologues then error("finder not available") end
    local base = addr - radius
    if base < 0x00400000 then base = 0x00400000 end
    local size = radius * 2
    local pros = finder.prologues(base, size, 200) or {}
    -- each entry is {addr, pat} from finder; normalize
    local cands = {}
    for _, p in ipairs(pros) do
        local a = type(p)=="table" and (p.addr or p[1]) or p
        if type(a)=="number" then
            local dist = math.abs(a - addr)
            if dist <= radius and a ~= addr then
                cands[#cands+1] = { addr=a, dist=dist, pat=type(p)=="table" and p.pat or nil }
            end
        end
    end
    table.sort(cands, function(a,b) return a.dist < b.dist end)
    while #cands > limit do table.remove(cands) end
    print(string.format("near 0x%08X ±0x%X: %d candidate(s)", addr, radius, #cands))
    for i, c in ipairs(cands) do
        print(string.format("  [%2d] 0x%08X  +%d  %s", i, c.addr, c.dist, c.pat or ""))
    end
    return cands
end

M.list = M.around

return M
