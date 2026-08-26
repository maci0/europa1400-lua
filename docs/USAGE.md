# Usage Guide

Detailed usage instructions and examples for the Europa 1400 Lua Console.

## Basic Console Commands

```lua
-- Core information
help()                      -- Show all available commands
list()                      -- List registered game functions

-- System diagnostics
system.info()               -- System hardware information
system.memory_info()        -- RAM usage and memory status
system.list_modules()       -- Loaded DLLs with addresses
system.window_info()        -- All process windows with details
system.memory_layout()      -- Memory layout overview
system.thread_info()        -- Thread information

-- Console utilities
cls                         -- Clear screen
history                     -- Show command history
exit / quit / q            -- Close console
```

## Game Function System

### Registering Functions (from Ghidra)
```lua
-- Basic function (no parameters)
game.register("GetPlayerGold", 0x403000, "int()", "Get current gold")

-- Function with parameters
game.register("SetPlayerGold", 0x403100, "void(int)", "Set gold amount")

-- Complex function with multiple parameters
game.register("CreateUnit", 0x404000, "void*(int, int, int)", "Create unit at x,y")

-- Different calling conventions
game.register("WinAPIFunc", 0x405000, "int __stdcall(int, char*)", "Windows API style")

-- Look up already-registered addresses
game.get_address("GetPlayerGold")   -- -> 0x403000
game.get_registry()                 -- raw registry table
```

### Calling Functions
```lua
-- Simple calls
local gold = game.call("GetPlayerGold")
print("Current gold:", gold)

-- With parameters
game.call("SetPlayerGold", 9999)
game.call("CreateUnit", 1, 100, 200)  -- type=1, x=100, y=200

-- Traced call (logs args/return/timing to trace.log)
trace.call("GetPlayerGold")
trace.hook()                        -- hook all subsequent game.call
game.call("GetPlayerGold")          -- auto-logged
trace.show(10); trace.stats()

-- Error handling
local success, result = pcall(function()
    return game.call("SomeFunction", param1, param2)
end)
if success then print("Result:", result) else print("Error:", result) end
```

## Memory Operations

```lua
-- Read memory
local data, bytes_read = game.read_mem(0x500000, 4, "int")
if data then print("Memory value:", data[0]) end

-- Write memory
local ffi = require('ffi')
local new_value = ffi.new("int[1]", 12345)
local success, bytes_written = game.write_mem(0x500000, new_value, 4)
print("Write successful:", success, "Bytes:", bytes_written)

-- Get module base addresses
local base = game.get_module_base("kernel32.dll")
print("Kernel32 base:", string.format("0x%08X", base))
```

## Memory Scanner (`scan.*`)

```lua
-- Byte-pattern (AOB) scan: ?? / ? = wildcard, unaffected by ASLR
local hits = scan.scan("55 8B EC 83 EC ??", 0x00400000, 0x200000)
for _, addr in ipairs(hits) do print(string.format("hit 0x%08X", addr)) end
scan.find("8B 45 08 ?? 83", 0x400000, 0x200000)   -- alias
scan.find_string("Gold", 0x400000, 0x300000)      -- ASCII search

-- Hex dump around a candidate function
scan.dump(0x401000, 64)

-- Enumerate readable regions before scanning
for _, r in ipairs(scan.regions(0x400000, 0x300000)) do
    print(string.format("0x%08X  size 0x%X  prot 0x%X", r.base, r.size, r.protect))
end
```

## Value Scanner (`valuescan.*`)

```lua
local hits = valuescan.int32(1500, 0x00400000, 0x300000)
valuescan.dump(hits, 5)
-- Change gold in-game, then narrow:
hits = valuescan.update(hits, 1350)
valuescan.dump(hits, 5)

valuescan.int32_range(1000, 5000, 0x00400000, 0x300000)
valuescan.float32(99.5, 0.01, 0x00400000, 0x300000)
valuescan.double(3.14, 0.001, 0x00400000, 0x300000)
```

## Pointer Chains (`pointer.*`)

```lua
-- module+RVA base + offsets (Cheat Engine semantics)
local addr = pointer.resolve("game.exe+0x1A3F00", {0x10, 0x20, 0x8})
print(string.format("gold @ 0x%08X = %d", addr, pointer.read(addr, "int")))
pointer.dump_chain("game.exe+0x1A3F00", {0x10, 0x20, 0x8})
local gold = pointer.read("game.exe+0x1A3F00", {0x10, 0x20, 0x8}, "int")
```

## Live Patcher (`patch.*`)

```lua
patch.dump(0x401000, 16)          -- inspect before
patch.nop(0x401000, 5)            -- NOP 5 bytes
patch.bytes(0x401000, "90 90 90") -- raw bytes (hex string or {0x90,...})
patch.jmp(0x401000, 0x402000, 6)  -- JMP rel32, pad to 6 with NOPs
patch.call(0x401000, 0x402000)    -- CALL rel32
patch.list()                      -- orig vs current
patch.restore(0x401000)           -- undo one
patch.restore_all()               -- undo all
```

## Live Watcher (`watch.*`)

```lua
watch.once(0x12340000, "int")
local w = watch.new(0x12340000, "float")
w:poll(500, 20)                   -- 20 samples, 500ms apart
w:wait(5000, 100)                 -- wait up to 5s for first change
watch.track(0x12340000, "int", 200, 30)
watch.wait(0x12340000, "int", 5000, 100)
watch.diff(0x12340000, 32)        -- hex diff vs last snapshot
```

## Structured Dumper (`struct.*`)

```lua
local ffi = require('ffi')
ffi.cdef[[ typedef struct { int gold; int fame; char name[32]; } Player; ]]
struct.register("Player", {
    {name="gold", type="int",       offset=0},
    {name="fame", type="int",       offset=4},
    {name="name", type="char[32]",  offset=8},
})
struct.layout("Player")
struct.dump(0x12340000, "Player")
struct.dump(0x12340000, { {name="gold",type="int",offset=0} }) -- ad-hoc
struct.array(0x12340000, "int", 8)
struct.hex(0x12340000, 64)
struct.list()
```

## Function Finder (`finder.*`)

```lua
-- String -> xrefs -> nearest function prologues (512B lookback)
local funcs = finder.string_func("Gold", 0x00400000, 0x300000)
finder.bytes_func("55 8B EC", 0x00400000, 0x200000)
finder.prologues(0x00401000, 0x50000)
finder.callers(0x00402000, 0x00400000, 0x200000)
finder.register_hits("Gold_fn", "int()", funcs)
```

## Execution Tracer (`trace.*`)

```lua
trace.hook()                      -- log every game.call
game.call("GetGold")
game.call("SetGold", 999)
trace.show(10)
trace.stats()                     -- per-function counts + avg ms
trace.enable("GetGold")           -- filter to one function
trace.save("trace.lua")
trace.clear(); trace.unhook()
```

## PE Exports / Imports (`exports.*`)

```lua
exports.list()                        -- main exe
exports.list("kernel32.dll")
exports.imports("game.exe")
local addr = exports.resolve("kernel32.dll", "CreateFileA")
game.register("CreateFileA_wrap", addr, "void*(char*, int, int, void*, int, int, void*)", "wrapped")
```

## Cross-References (`xrefs.*`)

```lua
xrefs.to(0x401000, 0x400000, 0x200000)
xrefs.string_refs("Gold", 0x400000, 0x300000)
```

## RTTI + VTables

```lua
-- MSVC class names are in the binary as ".?AVPlayer@@"
rtti.list(0x00400000, 0x300000, 50)
rtti.find("Player", 0x00400000, 0x300000)
rtti.vtables("Player", 0x00400000, 0x800000)  -- type -> xrefs -> vtable neighborhood

-- Enumerate candidate vtables (runs of code pointers)
vtable.scan(0x00400000, 0x800000, 3)
vtable.at(0x00AB1234, 12)
disasm.func(0x00AB1234)                      -- triage first virtual method
```

## Heap / Diff

```lua
-- When valuescan is too noisy, narrow to heap allocations first
heap.list()
heap.blocks(heapId, 200)
heap.find(0x12340000)

-- Snapshot-based diff (unknown value)
local a = diff.snap(0x12340000, 64)
-- perform in-game action
local b = diff.snap(0x12340000, 64)
diff.compare(a, b)
diff.watch(0x12340000, 64, 200, 20)
```

## Presets + Strings

```lua
presets.strings()
presets.dump("gold")
local funcs = presets.hunt("gold", 0x00400000, 0x300000)
presets.apply("gold", 0x00400000, 0x300000, "int()")

-- Raw string enumeration (also powers presets/rtti under the hood)
strings.dump(0x00400000, 0x300000, 5, 200)
strings.find("Gold", 0x00400000, 0x300000)
strings.wide(0x00400000, 0x300000, 4)
strings.wide_find("Gold", 0x00400000, 0x300000)
```

## Session + Report

```lua
session.note("gold offset 0x10 via pointer chain")
session.status(); session.save("my_session.lua"); session.load("my_session.lua")
report.save("run1.md"); report.print()        -- markdown snapshot with funcs/RTTI/mods
sig.save("my_sigs.lua", {{name="Gold_func", pat=sig.masked(0x401000, 24)}})
```

## Disassembly + Signatures

```lua
local funcs = finder.string_func("Gold", 0x00400000, 0x300000)
disasm.func(funcs[1])
sig.masked(funcs[1], 32)
sig.verify("55 8B EC 83 EC ?? 56 57", funcs[1])
disasm.at(0x401000, 20); disasm.decode("55 8B EC 83 EC 10 56 57 E8 00 10 00 00 C3")
```

## Safe Probe

```lua
-- Try many signatures without crashing the console
probe.at(0x401000, {"int()", "int(int)", "void(int,int)"} )
probe.at(0x401000, {"int(int)"}, {{0},{1},{-1},{0x1234}})
probe.register("GetGold", 0x401000)        -- picks first OK sig and game.register
```

## Function Catalog

```lua
catalog.list()                   -- 261 curated entries incl. city treasury + building upgrade/hire (economy/player/ui/unit/world/quest/…)
catalog.find("quest")
-- One-call sweep for a whole tag:
catalog.hunt("guild")              -- auto.discover per guild entry
probe.batch({0x401000, 0x402000}, {"int()", "void(int)"})
catalog.find("gold")
catalog.by_tag("economy")
catalog.hunt("economy")          -- one-call sweep: auto.discover per entry
catalog.register_all(true)       -- dry-run before committing
catalog.register_all()           -- bulk game.register once addresses verified
```

## Auto Discover

```lua
auto.discover("gold")            -- preset 'gold' over EN/DE synonyms
auto.discover("Gold", 0x00400000, 0x300000, { probe=true, register="int()", limit=3 })
auto.quick(0x401000, {"int()", "void(int)"}, "MyFunc")
auto.from_string("GetGold", "Gold", 0x00400000, 0x300000, "int()")
```

## Fuzz / Near / Stack

```lua
fuzz.int("GetGold", 0, 10)
fuzz.ints("MyFunc", {{0,5},{0,5}})
fuzz.strings("ShowMessage", {"","hi","Gold"})
near.around(0x401000, 0x1000, 5) -- nearby prologues → related funcs
stack.capture(0, 16)
stack.ebp_chain(0x12FF00, 16)
stack.args(0x12FF00, 4)
```

## Enums + Codegen

```lua
enums.lookup("building", 3)        -- "Workshop"
enums.dump("building")             -- all building types
codegen.struct("Player", { {name="gold",type="int"}, {name="fame",type="int"}, {name="name",type="char[32]"} })
codegen.cdef("Player", { {"gold","int"}, {"fame","int"} })
codegen.func_stub("GetGold", "int()", "Get current player gold")
```

## IAT Hook

```lua
hook.list("game.exe")
local old = hook.iat("game.exe", "kernel32.dll", "CreateFileA", myFn)
hook.restore("game.exe", "kernel32.dll", "CreateFileA")
hook.restore_all()
```

## Player Helper

Convenience wrapper around `game.read_mem`/`valuescan`/`struct` for the player's gold/fame/name struct.

```lua
player.scan(0x00400000, 0x300000, 1500)   -- via presets.hunt("gold") or valuescan hint
player.at(0x00AB1234):gold()              -- int at +0
player.at(0x00AB1234):set_gold(9999)
player.at(0x00AB1234):fame()              -- +4
player.at(0x00AB1234):name()              -- +8
player.at(0x00AB1234):dump()              -- field-aware dump
player.find()                             -- catalog.hunt("economy")
```

## Domain Helpers (city / building / unit / inventory / economy / world / quest / social / civic / cheat / state / snapshot)

```lua
-- each has scan/find + typed wrappers; examples:
city.at(0x00AB1234):gold()                  -- treasury via offsets
building.at(0x00AB1234):durability()        -- + income/efficiency/morale/upkeep
unit.at(0x00AB1234):health()                -- + owner/type/pos/skill + move/delete
inventory.at(0x00AB1234):list()             -- raw slots; inventory.get/add/remove/warehouse/transfer
economy.guild_balance(0); economy.market_price(3,0); economy.stock(0,1); economy.bribe_price(0,1); economy.supply(0,3); economy.demand(0,3); economy.trade_profit(0,1,3); economy.debt(0); economy.bank(0); economy.assassination_cost(0,1); economy.repay(0,1)
world.time(); world.year(); world.season(); world.city_owner(0); world.office_bribe_cost(0,1); world.guard_count(0)
quest.start(1,0); quest.complete(1); quest.status(1)
social.is_member(0,1); social.nobility(0); social.espionage(0,1); social.guild_reputation(0,1); social.dynasty_cash(0); social.prestige(0); social.disease(0); social.faith(0); social.ai_behavior(0); social.bribe_success(0,0,1)
civic.votes(0,0); civic.crime(0); civic.efficiency(bldg); civic.durability(bldg); state.is_bribed(0,1); civic.production_rate(bldg,3); civic.city_stability(0); civic.worker_morale(bldg)
cheat.gold(99999); cheat.crime(0,0); cheat.stock(0,1,10); cheat.bribe(0,1,500); cheat.supply(0,3,500); cheat.debt(0,0); cheat.spy_info(0,1)
state.save("sv.sav"); state.pause(1); state.is_paused()
local a = snapshot.capture(); -- action; local b = snapshot.capture(); snapshot.diff(a,b) -- set _G._snapshot_extended=true for supply/demand/trade/relation
```

## Working with Structs (game.read_mem style)

```lua
local ffi = require('ffi')
ffi.cdef[[
typedef struct { int x, y; int health; char name[32]; } Player;
]]
local player_addr = 0x600000
local data, size = game.read_mem(player_addr, ffi.sizeof("Player"), "Player")
if data then
    local player = ffi.cast("Player*", data)
    print("Player position:", player.x, player.y)
    print("Player health:", player.health)
    print("Player name:", ffi.string(player.name))
end
```

## Analysis Persistence

```lua
game.save("player_functions.lua")
game.save("network_functions.lua")
game.save()                             -- default file
game.load("player_functions.lua")
game.load()                             -- default file
list(); game.list()
```

## End-to-End: From String to Function

```lua
local s_hits = scan.find_string("Gold", 0x400000, 0x300000)
local refs = xrefs.string_refs("Gold", 0x400000, 0x300000)
scan.dump(refs[1].addr - 32, 128)
game.register("GetPlayerGold", refs[1].addr, "int()", "candidate from xref")
print(game.call("GetPlayerGold"))
game.save("gold_funcs.lua")
```

## Debugging & Logging

```lua
game.show_calls(10)
game.show_memory(5)
game.debug_config(); game.debug_on(true); game.debug_on(false)
game.debug_config({ log_calls=true, log_parameters=true, log_return_values=true, log_memory_ops=false })
game.clear_logs()
```

## Advanced Usage

### Multiple Calling Conventions

```lua
game.register("StandardFunc", 0x401000, "int(int, int)", "Standard call")
game.register("WinAPIFunc", 0x402000, "int __stdcall(int, int)", "Windows API")
game.register("FastFunc", 0x403000, "int __fastcall(int, int)", "Fast call")
```

### Complex Data Types

```lua
local ffi = require('ffi')
ffi.cdef[[
typedef struct {
    int id; float x, y, z; char name[64];
    struct { int health; int mana; } stats;
} GameEntity;
]]
local entity_ptr = game.call("CreateEntity", 1, 100.0, 200.0, 300.0)
if entity_ptr ~= nil then
    local entity = ffi.cast("GameEntity*", entity_ptr)
    print("Entity ID:", entity.id, "Position:", entity.x, entity.y, entity.z)
end
```

### Error Handling Best Practices

```lua
local function safe_call(func_name, ...)
    local success, result = pcall(game.call, func_name, ...)
    if success then return result else print("ERROR calling", func_name, ":", result) return nil end
end
local gold = safe_call("GetPlayerGold")
if gold then print("Gold:", gold) end
```
