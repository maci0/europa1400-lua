# Example Workflows

The workflows this toolkit is built around. Addresses like `0x403000` are placeholders:
substitute what Ghidra or `finder` gives you. No address here is a verified Europa 1400
address, and no catalog entry has one yet either.

## Discovering Player Gold System

1. **Find function in Ghidra** (e.g., at `0x403000`)
2. **Register and test:**
   ```lua
   game.register("GetPlayerGold", 0x403000, "int()", "Get current gold")
   local gold = game.call("GetPlayerGold")
   print("Current gold:", gold)
   ```
3. **Find related functions:**
   ```lua
   game.register("SetPlayerGold", 0x403100, "void(int)", "Set gold amount")
   game.register("AddGold", 0x403200, "void(int)", "Add gold amount")
   ```
4. **Test and verify:**
   ```lua
   print("Before:", game.call("GetPlayerGold"))
   game.call("AddGold", 1000)
   print("After:", game.call("GetPlayerGold"))
   ```
5. **Save your discoveries:**
   ```lua
   game.save("player_economy.lua")
   ```

## Auto Discover (auto.*)

```lua
-- One call: preset/finder → disasm → sig → probe
auto.discover("gold")    -- preset 'gold' over EN/DE synonyms
auto.discover("Gold", 0x00400000, 0x300000, { probe=true, register="int()", limit=3 })
-- Presets include trade/reputation/civic/city/building etc. for targeted hunts:
presets.hunt("civic"); presets.hunt("trade"); presets.hunt("reputation")
-- Probe an address with many signatures, optionally register the winner:
auto.quick(0x401000, {"int()", "void(int)", "int(int,int)"}, "MyFunc")
-- Named: discover by string then register under a name
auto.from_string("GetGold", "Gold", 0x00400000, 0x300000, "int()")
```

## Catalog Quick-Start

```lua
catalog.list()                   -- 4463 candidate entries, none with a verified address yet
catalog.find("gold")
catalog.by_tag("economy")
catalog.by_tag("building")
-- Sweep a whole tag through auto-discover (string → xref → prologue → sig/probe):
catalog.hunt("economy")          -- triages GetPlayerGold, AddGold, TradeExecute, …
catalog.hunt("building", 0x00400000, 0x300000)
-- Dry-run before committing:
catalog.register_all(true)
-- After you resolve addresses (via auto/finder), bulk-register:
catalog.register_all()
```

## Quick Discovery without Ghidra (finder)

```lua
-- String -> who references it -> nearest function prologue
local funcs = finder.string_func("Gold", 0x00400000, 0x300000)
-- { 0x00412A10, 0x00418C00, ... }
scan.dump(funcs[1], 64)          -- sanity-check the prologue
disasm.func(funcs[1])            -- also check disassembly
probe.at(funcs[1], {"int()", "int(int)"})  -- which sig won't crash?
game.register("GetGold_cand", funcs[1], "int()", "from Gold string")
trace.call("GetGold_cand")       -- logged
trace.show(5)

-- Enumerate all candidate functions in .text
local pros = finder.prologues(0x00401000, 0x50000)
finder.register_hits("fn", "int()", {pros[1].addr, pros[2].addr})

-- Or let probe pick the sig for you:
probe.register("GetGold", funcs[1])
```

## Live Value Hunting (no hard-coded addresses)

```lua
local hits = valuescan.int32(1500, 0x00400000, 0x300000)
valuescan.dump(hits, 5)
-- Change gold in-game (buy something), re-filter to narrow
hits = valuescan.update(hits, 1350)
valuescan.dump(hits, 5)         -- usually 1-3 candidates left

valuescan.float32(99.5, 0.01, 0x00400000, 0x300000)
valuescan.int32_range(1000, 5000, 0x00400000, 0x300000)

-- Watch live value and trace who mutates it (poll-based):
watch.track(hits[1], "int", 200, 30)  -- perform the in-game action while polling

-- Snapshot-based hex diff:
watch.snap(hits[1], 32); -- do action
watch.diff(hits[1], 32)
```

## Pointer Chains (stable addresses across restarts)

```lua
local addr = pointer.resolve("game.exe+0x1A3F00", {0x10, 0x20, 0x8})
print(string.format("gold @ 0x%08X = %d", addr, pointer.read(addr, "int")))
pointer.dump_chain("game.exe+0x1A3F00", {0x10, 0x20, 0x8})
local gold = pointer.read("game.exe+0x1A3F00", {0x10, 0x20, 0x8}, "int")

-- Patch then verify:
patch.dump(addr, 8)
game.write_mem(addr, ffi.new("int[1]", 9999), 4)
watch.once(addr, "int")
```

## String → Xref → Function (no Ghidra needed)

```lua
local hits = scan.find_string("Gold", 0x00400000, 0x300000)
local refs = xrefs.string_refs("Gold", 0x00400000, 0x300000)
scan.dump(refs[1].addr - 32, 128)
game.register("GetPlayerGold_guess", refs[1].addr, "int()", "from string xref")
print(game.call("GetPlayerGold_guess"))
```

## Pattern Scanning for ASLR / Multi-Version Support

```lua
local hits = scan.scan("55 8B EC 83 EC ?? 56 8B 45 08", 0x00400000, 0x200000)
for _, addr in ipairs(hits) do
    print(string.format("candidate 0x%08X", addr))
    scan.dump(addr, 48)
end
game.register("PlayerUpdate", hits[1], "void()", "found via AOB")
```

## Structured Struct Dumping

```lua
local ffi = require('ffi')
ffi.cdef[[ typedef struct { int gold; int fame; char name[32]; } Player; ]]
struct.register("Player", {
    {name="gold", type="int", offset=0},
    {name="fame", type="int", offset=4},
    {name="name", type="char[32]", offset=8},
})
-- Resolve pointer chain to Player*, then dump fields:
local base = pointer.resolve("game.exe+0x1A3F00", {0x10, 0x20, 0x8})
struct.dump(base, "Player")
struct.array(base + 0x40, "int", 8)   -- e.g. inventory array after struct
struct.hex(base, 64)
```

## Tracing and Timing

```lua
trace.hook()
game.call("GetPlayerGold")
game.call("SetPlayerGold", 5000)
trace.show(10)
trace.stats()                  -- calls / ok / err / avg ms per function
trace.enable("GetPlayerGold")  -- filter to one function
trace.save("my_trace.lua")
trace.clear(); trace.unhook()
```

## PE Analysis

```lua
exports.imports()                 -- main exe
exports.imports("kernel32.dll")
exports.list("user32.dll")
local addr = exports.resolve("kernel32.dll", "CreateFileA")
print(string.format("CreateFileA @ 0x%08X", addr))
```

## Cross-References

```lua
local addr = game.get_address("GetPlayerGold")
xrefs.to(addr, 0x00400000, 0x200000)
finder.callers(addr, 0x00400000, 0x200000)  -- wrapper
```

## Live Patching

```lua
-- Inspect, patch, verify, then restore:
scan.dump(0x00401000, 16)
patch.nop(0x00401000, 5)           -- or patch.bytes(0x401000, "90 90 90")
patch.list()
watch.once(0x00401000, "int")     -- verify side effect
patch.restore(0x00401000)
patch.restore_all()
```

## RTTI / VTable Class Discovery

```lua
-- Best first pass on an unknown binary: what classes exist?
rtti.list(0x00400000, 0x300000, 100)
rtti.find("Player", 0x00400000, 0x300000)
-- For each type, follow xrefs toward its vtable and dump methods:
local info = rtti.vtables("Player", 0x00400000, 0x800000)
-- Then pick a candidate vtable and triage:
vtable.at(0x00AB1234, 12)
disasm.func(0x00AB1400)       -- first virtual method
trace.call("Player_vfunc_0") -- if already registered via finder
```

## Heap-Aware + Session Workflow

```lua
heap.list()
-- narrow valuescan by heap, or at least find() to see heap of interest
local hits = valuescan.int32(5000, 0x00400000, 0x300000)
heap.find(hits[1])
session.note("5000 was in heap 2 block +0x40")
session.save("run2.lua")
report.save("run2.md")       -- shareable snapshot for others
```

## Disassembly + Signatures

```lua
-- Triage a candidate function in-place:
local funcs = finder.string_func("Gold", 0x00400000, 0x300000)
disasm.func(funcs[1])             -- no Ghidra round-trip
sig.masked(funcs[1], 32)          -- stable AOB with CALL/JMP wildcards
sig.verify("55 8B EC 83 EC ?? 56 57", funcs[1])
sig.save("sigs.lua", {{name="Gold_func", pat=sig.masked(funcs[1], 24)}})
scan.scan(sig.masked(funcs[1], 24), 0x00400000, 0x300000)  -- re-find next run

-- Decode raw bytes without reading process memory:
disasm.decode("55 8B EC 83 EC 10 56 57 E8 00 10 00 00 C3")
```

## Memory Analysis Workflow

1. **System info:**
   ```lua
   system.info(); system.memory_info(); system.list_modules()
   ```
2. **Regions:**
   ```lua
   for _, r in ipairs(scan.regions(0x00400000, 0x300000)) do
       print(string.format("0x%08X  0x%X  prot 0x%X", r.base, r.size, r.protect))
   end
   ```
3. **Dump:**
   ```lua
   local game_base = game.get_module_base("game.exe")
   scan.dump(game_base + 0x1000, 64)
   ```

## Window Analysis

```lua
system.window_info()
```

## Domain Helpers Quick-Uses

```lua
player.at(0x00AB1234):gold(); city.at(p):population(); building.at(p):efficiency(); building.at(p):durability(); building.at(p):upkeep()
unit.at(p):health(); unit.at(p):cart_speed(); unit.at(p):cart_capacity(); unit.at(p):cart_goods(3); inventory.at(p):list(); economy.stock(0,1); economy.daily_income(0); economy.bribe_price(0,1); economy.assassination_cost(0,1)
world.time(); world.city_owner(0); world.guard_count(0); world.office_bribe_cost(0,1); world.office_prestige(0,1); quest.start(1,0); social.espionage(0,1); social.guild_reputation(0,1); social.prestige(0); social.faith(0); social.bribe_success(0,0,1)
civic.votes(0,0); civic.crime(0); civic.set_crime(0,0); civic.production_rate(bldg,3); civic.city_stability(0)
cheat.gold(99999); cheat.income(0, 5000); cheat.crime(0,0); cheat.bribe(0,1,500); cheat.influence(0,0,50); cheat.debt(0,0); cheat.bank(0); cheat.loan(0,1); economy.repay(0,1)
state.save("sv.sav"); state.pause(1)
local a = snapshot.capture(); -- do action; local b = snapshot.capture(); snapshot.diff(a,b)
```

## Building a Function Library

```lua
game.register("GetPlayerGold", 0x403000, "int()", "Get gold")
game.register("SetPlayerGold", 0x403100, "void(int)", "Set gold")
game.register("GetPlayerName", 0x403200, "char*()", "Get player name")
game.register("CreateUnit", 0x404000, "void*(int, int, int)", "Create unit")
game.register("GetUnitHealth", 0x404100, "int(void*)", "Get unit HP")
game.register("SetUnitHealth", 0x404200, "void(void*, int)", "Set unit HP")
catalog.export("my_catalog.lua")   -- snapshot curated list for sharing
game.save("complete_analysis.lua")
list()
```
