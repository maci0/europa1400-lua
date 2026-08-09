-- Europa 1400 Lua Console - Initialization Script
-- Loads all required modules and sets up the console environment

local ffi = require('ffi')

-- Load basic Windows API for compatibility
ffi.cdef[[
    void __stdcall Sleep(unsigned long dwMilliseconds);
]]
k32 = ffi.load('kernel32')

-- Load core modules
game = dofile('lua/game_functions.lua')    -- Game function registration system
system = dofile('lua/sysinfo.lua')        -- System diagnostic functions
scan = dofile('lua/memscan.lua')          -- Memory scanner (AOB / dump / regions)
exports = dofile('lua/exports.lua')       -- PE export/import inspector
xrefs = dofile('lua/xrefs.lua')           -- Cross-reference finder
valuescan = dofile('lua/valuescan.lua')   -- Value scanner (int32/float/string)
pointer = dofile('lua/pointer.lua')       -- Pointer chain resolver
patch = dofile('lua/patch.lua')           -- Live memory patcher (NOP/JMP/restore)
watch = dofile('lua/watch.lua')           -- Live memory watcher (poll/wait/diff)
struct = dofile('lua/struct.lua')         -- Structured memory dumper (register/dump/array/hex)
finder = dofile('lua/finder.lua')         -- Function finder (string/bytes -> xref -> prologue)
trace  = dofile('lua/trace.lua')          -- Execution tracer (hook game.call)
disasm = dofile('lua/disasm.lua')         -- Lightweight x86 disassembly view
sig    = dofile('lua/sig.lua')            -- Signature maker (stable AOB patterns)
hook   = dofile('lua/hook.lua')           -- IAT hook helper (mod!dll!func -> new addr)
presets= dofile('lua/presets.lua')        -- RE presets (cheat-sheet string sets)
strings= dofile('lua/strings.lua')        -- String dumper (ASCII/wide enumeration)
session= dofile('lua/session.lua')        -- Session manager (collect/save/load/status)
vtable = dofile('lua/vtable.lua')         -- VTable dumper (class vtables)
probe  = dofile('lua/probe.lua')          -- Safe call probe (infer sig/arity)
dump   = dofile('lua/dump.lua')           -- Raw memory dumper to host files
stack  = dofile('lua/stack.lua')          -- Stack viewer (backtrace / EBP chain)
near   = dofile('lua/near.lua')           -- Nearby func finder (cluster around addr)
fuzz   = dofile('lua/fuzz.lua')           -- Fuzz helper (brute-force arg ranges)
catalog= dofile('lua/catalog.lua')        -- Function catalog (curated list)
player = dofile('lua/player.lua')         -- Player helper (gold/fame/name via scan/struct)
city   = dofile('lua/city.lua')           -- City helper (treasury/pop/happiness/owner via scan/struct)
building = dofile('lua/building.lua')     -- Building helper (level/owner/type/workers/output)
unit     = dofile('lua/unit.lua')         -- Unit helper (health/owner/type/pos/skill)
inventory = dofile('lua/inventory.lua')   -- Inventory helper (ware/goods/list/transfer)
economy = dofile('lua/economy.lua')       -- Economy helper (guild/market/tax/routes)
world  = dofile('lua/world.lua')          -- World helper (clock/year/season/speed/city/state)
quest  = dofile('lua/quest.lua')          -- Quest helper (start/complete/status/vars)
social = dofile('lua/social.lua')         -- Social helper (guild/nobility/reputation/diplomacy/marriage)
cheat  = dofile('lua/cheat.lua')          -- Cheat shortcuts (gold/fame/health/time/economy/quest)
state  = dofile('lua/state.lua')          -- Save/state helper (save/load/pause/state)
snapshot = dofile('lua/snapshot.lua')     -- Cross-domain state snapshot + diff
civic  = dofile('lua/civic.lua')          -- Civic helper (election/trial/crime/workshop)
ui     = dofile('lua/ui.lua')             -- UI helper (message/dialog + window sugar)
enums  = dofile('lua/enums.lua')          -- Enum lookups (building/good/title/unit)
codegen= dofile('lua/codegen.lua')        -- Code generator (struct/register stubs)
rtti   = dofile('lua/rtti.lua')           -- RTTI scanner (MSVC type names)
threads= dofile('lua/threads.lua')        -- Thread inspector (Toolhelp threads)
report = dofile('lua/report.lua')         -- Report generator (markdown snapshot)
diff   = dofile('lua/diff.lua')           -- Memory diff (snapshot + compare + watch)
heap   = dofile('lua/heap.lua')           -- Heap walker (Toolhelp heaps/blocks)
auto   = dofile('lua/auto.lua')           -- Auto discover (string/preset -> func -> sig/probe)
obj    = dofile('lua/obj.lua')            -- C++ object helper (thiscall / vtable)

-- Load utility modules
local beep_module = dofile('lua/beep.lua')
beep = beep_module.beep                    -- System beep (console thread)
beep_main = beep_module.beep_main          -- System beep (main process)
thread_info = beep_module.info             -- Thread information
beep_types = beep_module.types             -- Beep type constants

-- Console help function
function help()
    local separator = "=" .. string.rep("=", 60)

    print("Europa 1400 Lua Console - Available Commands")
    print(separator)
    print()

    -- Game function system
    print("GAME FUNCTIONS (game.*)")
    print("  game.register(name, addr, sig, desc)  Register game function from Ghidra")
    print("  game.call(name, ...)                  Call registered function")
    print("  game.list()                           List all registered functions")
    print("  game.get_address(name)                Get address of registered function")
    print("  game.save([filename])                 Save functions to file")
    print("  game.load([filename])                 Load functions from file")
    print()

    -- System diagnostic functions
    print("SYSTEM DIAGNOSTICS (system.*)")
    print("  system.info()           System information (CPU, memory limits)")
    print("  system.memory_info()    Memory status (RAM usage)")
    print("  system.list_modules()   List loaded DLLs with addresses")
    print("  system.window_info()    Window information")
    print("  system.memory_layout()  Memory layout overview")
    print("  system.thread_info()    Thread information")
    print()

    -- Memory scanner
    print("MEMORY SCANNER (scan.*)")
    print("  scan.scan(pattern, base, size)  AOB scan, e.g. scan.scan('8B 45 ?? 90', 0x400000, 0x200000)")
    print("  scan.find(...)                  Alias for scan.scan")
    print("  scan.find_string(s, base, size) Find ASCII string in memory")
    print("  scan.dump(addr, len)            Hex dump at address")
    print("  scan.regions([base,size])       List readable memory regions")
    print()

    -- Value scanner
    print("VALUE SCANNER (valuescan.*)")
    print("  valuescan.int32(v, base, size)      Exact int32 scan")
    print("  valuescan.uint32(v, base, size)     Exact uint32 scan")
    print("  valuescan.int32_range(lo,hi,base,size) Range scan")
    print("  valuescan.float32(v, eps, base, size) Float scan")
    print("  valuescan.update(hits, v [,ctype])  Re-filter hits after value changed")
    print("  valuescan.dump(hits [,n])            Print hits with decoded values")
    print()

    -- Pointer chains
    print("POINTER CHAINS (pointer.*)")
    print('  pointer.resolve("mod+0xOFF", {0x10, 0x8})  Follow chain to final addr')
    print('  pointer.read(base, offs, "int")       Read typed value at chain end')
    print("  pointer.deref(addr)                 Read uint32 at addr")
    print("  pointer.dump_chain(base, offs)      Debug-print each level")
    print()

    -- PE / Xrefs
    print("PE & XREFS")
    print("  exports.list([mod])             List PE exports (mod = 'kernel32.dll' or nil for exe)")
    print("  exports.imports([mod])          List PE imports")
    print("  exports.resolve(mod, name)      Resolve export address")
    print("  xrefs.to(addr, base, size)      Find code xrefs to address")
    print("  xrefs.string_refs(s, base, size) Find xrefs to string")
    print()

    -- Live patching
    print("PATCHER (patch.*)")
    print("  patch.bytes(addr, '90 90')      Write bytes (hex string or table)")
    print("  patch.nop(addr, 5)              NOP N bytes")
    print("  patch.jmp(src, dst [,pad])      Write JMP rel32 at src -> dst")
    print("  patch.call(src, dst [,pad])     Write CALL rel32 at src -> dst")
    print("  patch.dump(addr [,len])         Show bytes at addr")
    print("  patch.restore(addr)             Restore original bytes at addr")
    print("  patch.restore_all()             Restore all active patches")
    print("  patch.list()                    List active patches")
    print()

    -- Watcher
    print("WATCHER (watch.*)")
    print("  watch.once(addr [,type])        Single read (int/float/double)")
    print("  watch.new(addr [,type]):poll(ms, n)  Poll and print changes")
    print("  watch.new(addr [,type]):wait(timeout, interval) Wait for change")
    print("  watch.track(addr, type, ms, n)  Convenience poll")
    print("  watch.wait(addr, type, timeout, interval) Convenience wait")
    print("  watch.diff(addr [,len])         Hex diff vs last snapshot")
    print()

    -- Struct dumper
    print("STRUCT (struct.*)")
    print("  struct.register(name, fields)   Remember struct layout")
    print("  struct.dump(addr, name|fields)  Field-aware dump at addr")
    print("  struct.array(addr, type, n)     Dump typed array")
    print("  struct.hex(addr, len)           Hex dump at addr")
    print("  struct.layout(type)             Show sizeof + field offsets")
    print("  struct.list()                   List registered structs")
    print()

    -- Function finder
    print("FINDER (finder.*)")
    print("  finder.string_func(str, base, size) String -> xrefs -> func prologues")
    print("  finder.bytes_func(pat, base, size)  Pattern -> hits")
    print("  finder.prologues(base, size)        Enumerate function prologues")
    print("  finder.callers(addr, base, size)    Who calls this addr?")
    print("  finder.register_hits(prefix, sig, hits)  Bulk game.register")
    print()

    -- Tracer
    print("TRACER (trace.*)")
    print("  trace.hook()                        Hook game.call to log all calls")
    print("  trace.unhook()                      Remove hook")
    print("  trace.call(name, ...)               Single traced call")
    print("  trace.show([n])                     Show last n entries")
    print("  trace.stats()                       Hits + avg time per function")
    print("  trace.save([path])                  Persist log to file")
    print("  trace.clear()                       Clear log")
    print()

    -- Disassembler
    print("DISASSEMBLER (disasm.*)")
    print("  disasm.at(addr, n)                  Disassemble n insns at addr")
    print("  disasm.func(addr [,max])            Disassemble func until ret")
    print("  disasm.decode('55 8B EC ...')        Decode hex string")
    print()

    -- Signature maker
    print("SIGNATURES (sig.*)")
    print("  sig.at(addr, n)                     Exact pattern at addr")
    print("  sig.masked(addr, n)                 Mask CALL/JMP immediates as ??")
    print("  sig.func(addr [,max])               Pattern for whole func until ret")
    print("  sig.verify(pat, addr)               Check pattern matches at addr")
    print("  sig.save(path, {{name,pat},...})    Save named patterns to file")
    print()

    -- IAT hook
    print("IAT HOOK (hook.*)")
    print("  hook.list([mod])                    Show IAT (imports) for mod")
    print("  hook.iat(mod, dll, func, newAddr)   Redirect import (returns old addr)")
    print("  hook.restore(mod,dll,func)          Restore one IAT entry")
    print("  hook.restore_all()                  Restore all IAT hooks")
    print()

    -- Presets
    print("PRESETS (presets.*)")
    print("  presets.strings()                   List curated string keys")
    print("  presets.hunt(key [,base,size])      finder.string_func over preset tags")
    print("  presets.hunt('wizard')              Dedicated wizard template preset")
    print("  presets.apply(key,base,size,sig)    hunt + bulk game.register")
    print("  presets.dump([key])                 Show preset tags")
    print()

    -- String dumper
    print("STRINGS (strings.*)")
    print("  strings.dump(base, size, min, max)  Dump ASCII strings")
    print("  strings.find(needle, base, size)    Filtered ASCII search")
    print("  strings.wide(base, size)            UTF-16LE strings")
    print("  strings.scan(base, size, min, max)  Return hits without printing")
    print()

    -- Session
    print("SESSION (session.*)")
    print("  session.save([path])                Snapshot game funcs + notes to file")
    print("  session.load([path])                Restore session from file")
    print("  session.status()                    Show funcs/notes/patches/hooks")
    print("  session.note(text)                  Append free-form note")
    print("  session.notes()                     List notes")
    print()

    -- VTables / RTTI / Report / Diff / Probe
    print("VTABLES (vtable.*)")
    print("  vtable.scan([base, size, min, max]) Enumerate candidate vtables")
    print("  vtable.at(addr, n)                  Dump vtable entries at addr")
    print("  threads.list()                      List threads for PID")
    print("  threads.current()                   Current TID + PID")
    print("  rtti.list([base,size,max])          List MSVC RTTI type names")
    print("  rtti.find(needle, base, size)       Filter types by substring")
    print("  rtti.vtables(needle, base, size)    Type -> xrefs -> nearby vtables")
    print("  rtti.at(addr)                       Show type string at addr")
    print("  report.save([path])                 Write markdown snapshot (funcs+RTTI+mods)")
    print("  report.print()                      Snapshot + console summary")
    print("  diff.snap(addr, len)                Snapshot bytes at addr")
    print("  diff.compare(a, b)                  Diff two snapshots")
    print("  diff.watch(addr, len, ms, n)        Poll and print diffs")
    print("  heap.list()                         List heaps + block counts")
    print("  heap.blocks(id, n)                  Dump blocks of heap id")
    print("  heap.find(addr)                     Which heap/block owns addr?")
    print("  probe.at(addr, sigs [,args])        Try sigs/args without crashing")
    print("  probe.register(name, addr [,sigs])  Probe then game.register best sig")
    print("  dump.region(base, size, path)       Dump raw bytes to file")
    print("  dump.func(addr, path [,max])        Dump func bytes until RET")
    print("  stack.capture([skip, n])            Backtrace via RtlCaptureStackBackTrace")
    print("  stack.ebp_chain(ebp [,max])         Walk EBP chain + ret addrs")
    print("  stack.args(ebp, n)                  Dump n args at [ebp+8]")
    print("  auto.discover(keyword [,base,size,opts]) One-shot string->func->sig/probe")
    print("  auto.quick(addr, sigs [,name])      Probe + optionally register")
    print("  fuzz.int(name, lo, hi)              Try int range")
    print("  fuzz.ints(name, {{lo,hi,step},...}) Cartesian int ranges")
    print("  fuzz.strings(name, {...})           Try string args")
    print("  near.around(addr, radius [,limit]) Related funcs near addr")
    print("  ui.message(text)                    ShowMessage wrapper")
    print("  ui.dialog(text [,n])                ShowDialog wrapper")
    print("  obj.at(addr)                        C++ object at addr (vtable ptr)")
    print("  obj:vcall(idx, sig, args)           Call vtable[idx] as thiscall")
    print("  obj:field(type, off)                Typed field read")
    print("  player.at(addr)                     Player object (gold/fame/name)")
    print("  player.scan([base,size,hint])       Locate player via presets/valuescan")
    print("  city.at(addr)                       City object (treasury/pop/happiness/owner)")
    print("  city.scan([base,size])              Locate city via presets/city strings")
    print("  city.find([base,size])              catalog.hunt world/city")
    print("  building.at(addr)                   Building object (level/owner/durability/income/morale...)")
    print("  building.scan([base,size])          Locate building via presets")
    print("  building.find([base,size])          catalog.hunt building")
    print("  unit.at(addr)                       Unit object (health/owner/type/pos/skill)")
    print("  unit.scan([base,size])              Locate unit via presets")
    print("  unit.find([base,size])              catalog.hunt unit")
    print("  inventory.at(addr)                  Inventory at addr (slots/list)")
    print("  inventory.get(owner,item)           GetInventoryCount / warehouse fallback")
    print("  inventory.add/remove/transfer(...)  Add/remove/transfer goods")
    print("  quest.start(id,owner)/complete(id)  Start/complete/fail/status + vars")
    print("  social.join/leave/is_member         Guild membership + ranks")
    print("  social.nobility/reputation/alliance Standing/diplomacy/alliance/marriage/chat")
    print("  economy.guild/market/tax/route      Guild balance / market price / tax / trade routes")
    print("  economy.scan/find([base,size])      Presets hunt over guild/trade/tax/inventory")
    print("  world.time/year/season/speed        Clock/year/season/speed/difficulty")
    print("  world.city_owner/office/enter/leave City/world state + selected unit/building")
    print("  world.scan/find([base,size])        Presets hunt over clock/city/map/guild")
    print("  cheat.gold/fame/health/time         Quick cheats (gold/fame/health/time/year/speed)")
    print("  cheat.tax/market/guild/quest        Economy/quest cheat one-liners")
    print("  state.save/load/pause/is_paused     Save/load + pause/state")
    print("  state.scan/find([base,size])        Presets hunt over save/clock")
    print("  snapshot.capture/print/diff/save    Cross-domain snapshot + before/after diff")
    print("  civic.votes/trial/crime/efficiency  Election/trial/crime/workshop (civic)")
    print("  civic.scan/find([base,size])        Presets hunt over civic/city/building")
    print("  enums.lookup(kind, id)              Decode enum (building/good/...)")
    print("  enums.dump([kind])                  List enum values")
    print("  codegen.struct(name, fields)        Emit struct register code")
    print()

        -- Aliases
    print("ALIASES  (shortcuts)")
    print("  hunt(key)  = presets.hunt(key)")
    print("  gold()     = catalog.hunt('economy')")
    print("  report()   = report.save()")
    print()

    -- Utility functions
    print("UTILITIES")
    print("  help()                  Show this help")
    print("  list()                  Alias for game.list()")
    print("  beep()                  System beep (console thread)")
    print("  thread_info()           Basic thread info")
    print()

    -- Usage examples
    print("EXAMPLES")
    print('  game.register("GetGold", 0x401000, "int()", "Get player gold")')
    print('  local gold = game.call("GetGold")')
    print('  system.memory_info()')
    print('  scan.scan("55 8B EC 83 EC ??", 0x401000, 0x10000)')
    print('  scan.dump(0x401000, 64)')
    print('  local hits = valuescan.int32(1500, 0x400000, 0x300000)')
    print('  local addr = pointer.resolve("game.exe+0x1A3000", {0x10, 0x8})')
    print('  exports.list("game.exe")')
    print('  xrefs.to(0x401000, 0x400000, 0x200000)')
    print('  game.save("my_functions.lua")')
    print(separator)
end

function list()
    game.list()
end

-- Global shortcuts
function hunt(key, base, size) return presets.hunt(key, base, size) end
function gold() return catalog.hunt("economy") end
function report() return _G.report.save() end

-- Console initialization and welcome message
local function show_welcome()
    local separator = "=" .. string.rep("=", 50)

    print()
    print("Europa 1400 Lua Console")
    print(separator)
    print("Game Function Analysis & Reverse Engineering Tool")
    print()
    print("Quick Start:")
    print("  help()              - Show all available commands")
    print("  game.list()         - List registered functions")
    print("  system.info()       - Show system information")
    print("  scan.regions()      - Show readable memory regions")
    print("  valuescan.int32(1500, 0x400000, 0x300000)  -- find live value")
    print()
    print("Ready! Type help() for complete command reference.")
    print(separator)
    print()
end

-- Initialize console
beep()
show_welcome()
