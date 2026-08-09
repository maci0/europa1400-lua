-- Europa 1400 - Inventory Helper
--
-- High-level wrapper for inventory / warehouse / goods targets.
-- Mirrors city/building/unit: wraps game.read_mem + catalog calls
-- behind `inventory.*` so catalog inventory/economy entries triage quickly.
--
--   inventory = dofile('lua/inventory.lua')  -- or already `inventory`
--   inventory.find()                           -- catalog.hunt("inventory")
--   inventory.scan(0x00400000, 0x300000)       -- preset hunt for inventory strings
--   inventory.get(owner, goodId)               -- GetInventoryCount or raw read
--   inventory.add(owner, goodId, 10)
--   inventory.remove(owner, goodId, 5)
--   inventory.warehouse(whId, goodId)
--   inventory.transfer(src,dst,goodId,amount)
--   inventory.at(0x12340000):count_for(3)      -- raw slot scan
--   inventory.at(0x12340000):list()            -- dump all slots
--   inventory.at(0x12340000):dump()
--
-- Offsets below are defaults — calibrate via struct.dump once the real
-- inventory/warehouse struct is reversed. Override e.g. inventory.offsets.stride=12

local M = {}

M.offsets = {
    stride    = 8,    -- bytes per slot: int id + int count
    id        = 0,
    count     = 4,
    max_items = 32,   -- slots to scan for list/count_for
}

local function game_ok()
    local g = _G.game
    if g and g.read_mem then return g end
    local ok, m = pcall(dofile, "lua/gamecalls.lua")
    if ok and m then return m end
    return nil
end

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
    print(string.format("inventory.scan [0x%08X +0x%X]", base, size))
    local presets = _G.presets or (pcall(dofile, "lua/presets.lua") and _G.presets)
    if presets and presets.hunt then
        local hits = presets.hunt("inventory", base, size) or {}
        if #hits > 0 then
            print(string.format("inventory.scan: %d preset hit(s), try inventory.at(hits[1])", #hits))
            return hits
        end
    end
    print("inventory.scan: no hits; try inventory.find() or wider base/size")
    return {}
end

function M.find(base, size)
    local cat = _G.catalog or (pcall(dofile, "lua/catalog.lua") and _G.catalog)
    if not cat or not cat.hunt then error("catalog not available") end
    return cat.hunt("inventory", base, size)
end

-- high-level catalog wrappers (pcall game.call, fallback to nil+hint)
function M.get(owner, itemId)
    local g = game_ok()
    if g and g.call then
        local ok, ret = pcall(g.call, "GetInventoryCount", owner, itemId)
        if ok then return ret end
        -- try warehouse variant if owner looks like small int warehouseId
        ok, ret = pcall(g.call, "GetWarehouseGoods", owner, itemId)
        if ok then return ret end
    end
    -- fallback: if owner is an address, try raw slot scan
    if type(owner) == "number" and owner > 0x10000 then
        local obj = M.at(owner)
        local ok, v = pcall(function() return obj:count_for(itemId) end)
        if ok then return v end
    end
    error("GetInventoryCount not registered and raw read failed; run inventory.find() / game.register first")
end

function M.add(owner, itemId, amount)
    local g = game_ok()
    if g and g.call then
        local ok, ret = pcall(g.call, "AddInventoryItem", owner, itemId, amount)
        if ok then print(string.format("inventory add owner=%s item=%s x%d -> %s", tostring(owner), tostring(itemId), amount, tostring(ret))); return ret end
    end
    error("AddInventoryItem not registered; register via catalog or game.register first")
end

function M.remove(owner, itemId, amount)
    local g = game_ok()
    if g and g.call then
        local ok, ret = pcall(g.call, "RemoveInventoryItem", owner, itemId, amount)
        if ok then print(string.format("inventory remove owner=%s item=%s x%d -> %s", tostring(owner), tostring(itemId), amount, tostring(ret))); return ret end
    end
    error("RemoveInventoryItem not registered; register via catalog or game.register first")
end

function M.warehouse(warehouseId, goodId)
    local g = game_ok()
    if g and g.call then
        local ok, ret = pcall(g.call, "GetWarehouseGoods", warehouseId, goodId)
        if ok then return ret end
    end
    error("GetWarehouseGoods not registered; register via catalog or game.register first")
end

function M.transfer(src, dst, goodId, amount)
    local g = game_ok()
    if g and g.call then
        local ok, ret = pcall(g.call, "TransferGoods", src, dst, goodId, amount)
        if ok then print(string.format("transfer %s->%s good=%s x%d -> %s", tostring(src), tostring(dst), tostring(goodId), amount, tostring(ret))); return ret end
    end
    error("TransferGoods not registered; register via catalog or game.register first")
end


local function call_or_hint(name, ...)
    local g = game_ok()
    if g and g.call then
        local ok, ret = pcall(g.call, name, ...)
        if ok then return ret end
        error(tostring(ret))
    end
    error(name .. " not registered; run inventory.find()/catalog.hunt or game.register first")
end

function M.value(owner) return call_or_hint("GetInventoryValue", owner) end
function M.warehouse_capacity(wh) return call_or_hint("GetWarehouseCapacity", wh) end
function M.set_warehouse_capacity(wh, cap) local r=call_or_hint("SetWarehouseCapacity", wh, cap); print(string.format("warehouse %s cap->%s", tostring(wh), tostring(cap))); return r end
function M.cart_capacity(cart) return call_or_hint("GetCartCapacity", cart) end
function M.set_cart_capacity(cart, cap) local r=call_or_hint("SetCartCapacity", cart, cap); print(string.format("cart %s cap->%s", tostring(cart), tostring(cap))); return r end
function M.cart_goods(cart, goodId) return call_or_hint("GetCartGoods", cart, goodId) end
function M.has_goods(cart, goodId, amt) return call_or_hint("HasCartGoods", cart, goodId, amt) end

-- ergonomic aliases + goods-aware helpers
function M.get_goods(ownerId, good) -- good may be name or id
    if type(good)=="string" then
        local e=_G.enums or (pcall(dofile,"lua/enums.lua") and _G.enums)
        if e and e.lookup then
            -- reverse lookup: find id by name
            local tbl=e.good or e.goods
            if tbl then for id,name in pairs(tbl) do if name:lower()==good:lower() then good=id; break end end end
        end
    end
    return M.get(ownerId, good)
end
function M.set_goods(ownerId, good, count)
    if type(good)=="string" then
        local e=_G.enums or (pcall(dofile,"lua/enums.lua") and _G.enums)
        if e and e.lookup then
            local tbl=e.good or e.goods
            if tbl then for id,name in pairs(tbl) do if name:lower()==good:lower() then good=id; break end end end
        end
    end
    local cur = 0
    do local ok,v=pcall(M.get, ownerId, good); if ok then cur=v or 0 end end
    local delta = (count or 0) - cur
    if delta > 0 then return M.add(ownerId, good, delta)
    elseif delta < 0 then return M.remove(ownerId, good, -delta)
    else print(string.format("set %s good %s already %s", tostring(ownerId), tostring(good), tostring(count))); return true end
end

local Obj = {}
Obj.__index = Obj

function Obj:item(idx)
    if type(idx) ~= "number" or idx < 0 or idx >= M.offsets.max_items then error("idx 0.." .. (M.offsets.max_items-1) .. " required") end
    local g = game_ok()
    if not g then error("game not available") end
    local base = self.addr + idx * M.offsets.stride
    local d = g.read_mem(base + M.offsets.id, 4, "int")
    local c = g.read_mem(base + M.offsets.count, 4, "int")
    if not d or not c then error(string.format("item read failed at 0x%08X", base)) end
    return { id = d[0], count = c[0], addr = base }
end

function Obj:count_for(goodId)
    for i = 0, M.offsets.max_items - 1 do
        local it = self:item(i)
        if it.id == goodId then return it.count end
        -- empty slot sentinel: id 0 or -1 with count 0 often means end; don't break, some inventories sparse
    end
    return 0
end

function Obj:list()
    local g = game_ok()
    local enums = _G.enums or (pcall(dofile, "lua/enums.lua") and _G.enums)
    local out = {}
    for i = 0, M.offsets.max_items - 1 do
        local ok, it = pcall(function() return self:item(i) end)
        if not ok then break end
        if it.id ~= 0 and it.count ~= 0 then
            local name = nil
            if enums and enums.lookup then
                local ok2, n = pcall(enums.lookup, "good", it.id)
                if ok2 then name = n end
            end
            print(string.format("  [%2d] @0x%08X  id=%d (%s)  count=%d", i, it.addr, it.id, name or "?", it.count))
            out[#out+1] = it
        end
    end
    if #out == 0 then print(string.format("inventory @0x%08X: (empty/no slots with id!=0)", self.addr)) end
    return out
end

function Obj:dump()
    local str = _G.struct or (pcall(dofile, "lua/struct.lua") and _G.struct)
    if str and str.dump then
        local ok = pcall(str.dump, self.addr, "Inventory")
        if not ok then
            -- fallback: hex + item list
            pcall(str.hex, self.addr, M.offsets.stride * math.min(8, M.offsets.max_items))
            self:list()
        end
    else
        self:list()
    end
    return self
end

function M.at(addr)
    addr = to_addr(addr)
    return setmetatable({ addr = addr }, Obj)
end

return M
