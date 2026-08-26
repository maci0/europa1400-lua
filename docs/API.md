# API Reference

Complete reference for all available functions and their usage.

## Game Function System (`game.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `game.register(name, addr, sig, desc)` | Register game function | `game.register("GetGold", 0x403000, "int()", "Get gold")` |
| `game.call(name, ...)` | Call registered function | `game.call("GetGold")` |
| `game.get_address(name)` | Get address of registered function | `game.get_address("GetGold")` |
| `game.get_registry()` | Get raw registry table | `game.get_registry()` |
| `game.list()` | List all registered functions | `game.list()` |
| `game.save([filename])` | Save functions to file | `game.save("my_funcs.lua")` |
| `game.load([filename])` | Load functions from file | `game.load("my_funcs.lua")` |
| `game.read_mem(addr, size, type)` | Read memory | `game.read_mem(0x500000, 4, "int")` |
| `game.write_mem(addr, data, size)` | Write memory | `game.write_mem(0x500000, data, 4)` |
| `game.get_module_base(name)` | Get module base address | `game.get_module_base("kernel32.dll")` |

## System Diagnostics (`system.*`)

| Function | Description | Output |
|----------|-------------|---------|
| `system.info()` | System hardware info | CPU, memory limits, architecture |
| `system.memory_info()` | Memory usage status | RAM usage, available memory |  
| `system.list_modules()` | Loaded modules | DLL names, base addresses, paths |
| `system.window_info()` | Process windows | All windows with handles, titles, classes |
| `system.memory_layout()` | Memory layout | Key module addresses |
| `system.thread_info()` | Thread information | Current thread and process IDs |

## Memory Scanner (`scan.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `scan.scan(pattern, base, size, max_hits)` | AOB byte-pattern scan (`??`/`?` = wildcard) | `scan.scan("8B 45 ?? 90", 0x400000, 0x200000)` |
| `scan.find(...)` | Alias for `scan.scan` | `scan.find("55 8B EC", 0x401000, 0x10000)` |
| `scan.find_string(str, base, size, max_hits)` | Find ASCII string in memory | `scan.find_string("Gold", 0x400000, 0x300000)` |
| `scan.dump(addr, len, cols)` | Hex dump (prints + returns) | `scan.dump(0x401000, 64)` |
| `scan.regions([base, max_size])` | Enumerate readable committed regions | `scan.regions()` |

## Value Scanner (`valuescan.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `valuescan.int32(v, base, size, max_hits)` | Exact int32 scan | `valuescan.int32(1500, 0x400000, 0x300000)` |
| `valuescan.uint32(v, base, size, max_hits)` | Exact uint32 scan | `valuescan.uint32(0xDEADBEEF, 0x400000, 0x300000)` |
| `valuescan.int16(v, base, size, max_hits)` | Exact int16 scan | `valuescan.int16(100, 0x400000, 0x100000)` |
| `valuescan.int32_range(lo, hi, base, size)` | Range scan | `valuescan.int32_range(1000, 5000, 0x400000, 0x300000)` |
| `valuescan.float32(v, eps, base, size)` | Float scan with epsilon | `valuescan.float32(99.5, 0.01, 0x400000, 0x300000)` |
| `valuescan.double(v, eps, base, size)` | Double scan | `valuescan.double(3.14, 0.001, 0x400000, 0x300000)` |
| `valuescan.update(hits, v [,ctype])` | Re-filter previous hits | `valuescan.update(hits, 1600)` |
| `valuescan.dump(hits [,n])` | Print hits with decoded values | `valuescan.dump(hits, 5)` |

## Pointer Chains (`pointer.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `pointer.resolve(base, offsets)` | Resolve chain to final address | `pointer.resolve("game.exe+0x1A3F00", {0x10, 0x8})` |
| `pointer.read(addr_or_base, ctype_or_offsets, ctype)` | Read typed value | `pointer.read(addr, "int")` |
| `pointer.deref(addr)` | Read uint32 at addr | `pointer.deref(0x12340000)` |
| `pointer.dump_chain(base, offsets)` | Debug-print each level | `pointer.dump_chain("game.exe+0x1000", {0x10})` |

`pointer.resolve` accepts `number`, `"0x401000"`, or `"module.dll+0x1234"` as base. Offsets follow Cheat Engine semantics: each offset except the last is dereferenced; the last is a final add (append `0` if you need a final deref).

## PE Inspector (`exports.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `exports.list([mod])` | List PE exports | `exports.list("kernel32.dll")` |
| `exports.imports([mod])` | List PE imports | `exports.imports("game.exe")` |
| `exports.resolve(mod, name)` | Resolve export address | `exports.resolve("kernel32.dll", "CreateFileA")` |

## Cross-References (`xrefs.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `xrefs.to(target, base, size)` | Find CALL/JMP/PUSH/MOV/ABS xrefs | `xrefs.to(0x401000, 0x400000, 0x200000)` |
| `xrefs.string_refs(str, base, size)` | Find xrefs to string | `xrefs.string_refs("Gold", 0x400000, 0x300000)` |

## Live Patcher (`patch.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `patch.bytes(addr, hex)` | Write raw bytes (hex string `"90 90"` or `{0x90,0x90}`) | `patch.bytes(0x401000, "90 90 90")` |
| `patch.nop(addr, n)` | NOP N bytes | `patch.nop(0x401000, 5)` |
| `patch.jmp(src, dst [,pad])` | Write `JMP rel32` at src → dst (pad with NOPs if needed) | `patch.jmp(0x401000, 0x402000, 6)` |
| `patch.call(src, dst [,pad])` | Write `CALL rel32` at src → dst | `patch.call(0x401000, 0x402000)` |
| `patch.dump(addr [,len])` | Hex view at addr | `patch.dump(0x401000, 16)` |
| `patch.restore(addr)` | Restore original bytes at addr | `patch.restore(0x401000)` |
| `patch.restore_all()` | Restore all active patches | `patch.restore_all()` |
| `patch.list()` | List active patches (orig vs current) | `patch.list()` |

All writes go through `VirtualProtect`→`WriteProcessMemory`→`FlushInstructionCache`; original bytes are saved on first patch for restore.

## Live Watcher (`watch.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `watch.once(addr [,ctype])` | Single read + pretty print | `watch.once(0x12340000, "int")` |
| `watch.new(addr [,ctype])` | Create watcher object | `w = watch.new(0x12340000, "float")` |
| `w:poll(interval_ms, count [,on_change])` | Poll N times, print changes | `w:poll(500, 20)` |
| `w:wait(timeout_ms [,interval_ms])` | Wait for first change | `w:wait(5000, 100)` |
| `watch.track(addr, ctype, ms, n)` | Convenience poll | `watch.track(0x12340000, "int", 200, 30)` |
| `watch.wait(addr, ctype, timeout, interval)` | Convenience wait | `watch.wait(0x12340000, "int", 5000, 100)` |
| `watch.diff(addr [,len])` | Hex snapshot diff vs last | `watch.diff(0x12340000, 32)` |
| `watch.snap(addr [,len])` | Save hex snapshot | `watch.snap(0x12340000, 32)` |

Supports `module+0xOFF` addresses; types include `int`, `float`, `double`, `short`, etc. Use with `valuescan` hits to find which code path mutates a value.

## Structured Dumper (`struct.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `struct.register(name, fields)` | Remember struct layout `{name, type, offset}` | `struct.register("Player", {{name="gold",type="int",offset=0}})` |
| `struct.dump(addr, name_or_fields)` | Field-aware dump at addr | `struct.dump(0x12340000, "Player")` |
| `struct.array(addr, ctype, n [,stride])` | Dump typed array | `struct.array(0x12340000, "int", 8)` |
| `struct.hex(addr, len)` | Hex dump at addr | `struct.hex(0x12340000, 64)` |
| `struct.layout(type)` | Show sizeof + field offsets | `struct.layout("Player")` |
| `struct.list()` | List registered structs | `struct.list()` |

Add `ffi.cdef` first, then register or dump ad-hoc; `char[N]` fields are rendered as strings, pointer fields as hex.

## Function Finder (`finder.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `finder.string_func(str, base, size [,opts])` | String → xrefs → nearest prologues | `finder.string_func("Gold", 0x400000, 0x300000)` |
| `finder.bytes_func(pattern, base, size [,opts])` | Pattern scan for func candidates | `finder.bytes_func("55 8B EC", 0x400000, 0x200000)` |
| `finder.prologues(base, size [,max])` | Enumerate function prologues | `finder.prologues(0x401000, 0x50000)` |
| `finder.callers(target, base, size [,max])` | Who CALL/JMP/references target | `finder.callers(0x401000, 0x400000, 0x200000)` |
| `finder.register_hits(prefix, sig, hits)` | Bulk `game.register` from hits | `finder.register_hits("Gold_fn","int()", hits)` |

`finder.string_func` chains `scan.find_string` → `xrefs.to` → prologue walk-back (512B); pass `{dump=true}` to also hex-dump candidates.

## Execution Tracer (`trace.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `trace.hook()` | Hook `game.call` to log every call | `trace.hook()` |
| `trace.unhook()` | Remove hook | `trace.unhook()` |
| `trace.call(name, ...)` | Single traced call | `trace.call("GetGold")` |
| `trace.show([n])` | Show last n entries | `trace.show(20)` |
| `trace.stats()` | Per-function counts + avg time | `trace.stats()` |
| `trace.save([path])` | Persist log to file | `trace.save("trace.lua")` |
| `trace.clear()` | Clear log | `trace.clear()` |
| `trace.enable(name)` / `disable` | Filter which functions are traced | `trace.enable("GetGold")` |

## Lightweight Disassembler (`disasm.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `disasm.at(addr, n)` | Disassemble n insns at addr | `disasm.at(0x401000, 20)` |
| `disasm.func(addr [,max])` | Disassemble func until RET | `disasm.func(0x401000)` |
| `disasm.decode(hex)` | Decode hex string | `disasm.decode("55 8B EC 83 EC 10")` |

Best-effort x86 32-bit table (MSVC-era prologues, call/jmp/mov/push/pop, ALU, RET). Falls back to `db 0x??`. Use `disasm.func` after `finder`/`scan` to triage candidates in-place.

## Signature Maker (`sig.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `sig.at(addr, n)` | Exact pattern at addr | `sig.at(0x401000, 16)` |
| `sig.masked(addr, n [,opts])` | Mask CALL/JMP rel32 + PUSH ptr as `??` | `sig.masked(0x401000, 24)` |
| `sig.func(addr [,max])` | Pattern for func until RET (masked) | `sig.func(0x401000)` |
| `sig.verify(pat, addr)` | Check pattern matches at addr | `sig.verify("55 8B EC ?? ??", 0x401000)` |
| `sig.normalize(pat)` | Upper-case + normalize wildcards | `sig.normalize("55 8b ec ??")` |
| `sig.save(path, {{name,pat},...})` | Save named patterns to file | `sig.save("sigs.lua", {{name="Foo",pat="55 8B EC ??"}})` |

Create stable AOBs from live bytes: `sig.masked`/`sig.func` wildcard CALL/JMP immediates and suspicious PUSH pointers for version-proof signatures.

## IAT Hook (`hook.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `hook.list([mod])` | Show IAT slots for mod | `hook.list("game.exe")` |
| `hook.iat(mod, dll, func, newAddr)` | Redirect import via IAT patch | `old=hook.iat("game.exe","kernel32.dll","CreateFileA", myFn)` |
| `hook.restore(mod, dll, func)` | Restore one IAT entry | `hook.restore("game.exe","kernel32.dll","CreateFileA")` |
| `hook.restore_all()` | Restore all IAT hooks | `hook.restore_all()` |

Patches the FirstThunk IAT pointer with VirtualProtect+WriteProcessMemory; original VA saved for restore.

## RE Presets (`presets.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `presets.strings()` | List curated string keys | `presets.strings()` |
| `presets.hunt(key [,base,size [,opts]])` | `finder.string_func` over preset tags | `presets.hunt("gold")` |
| `presets.apply(key,base,size,sig [,prefix])` | hunt + bulk `game.register` | `presets.apply("gold", 0x400000, 0x300000, "int()")` |
| `presets.dump([key])` | Show preset tags | `presets.dump("gold")` |

Keys: `gold`, `inventory`, `trade`, `map`, `save`, `dialog`, `network`. Each maps to EN/DE synonyms to widen string hits.

## String Dumper (`strings.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `strings.dump(base, size, min_len [,max])` | Dump ASCII strings | `strings.dump(0x400000, 0x300000, 5)` |
| `strings.find(needle, base, size)` | Filtered ASCII search | `strings.find("Gold", 0x400000, 0x300000)` |
| `strings.scan(base, size, min_len [,max])` | Return hits `{addr, text}` | `strings.scan(0x400000, 0x300000, 4)` |
| `strings.wide(base, size)` | UTF-16LE strings | `strings.wide(0x400000, 0x300000, 4)` |
| `strings.wide_find(needle, base, size)` | Filtered wide search | `strings.wide_find("Gold", 0x400000, 0x300000)` |

Chunked committed-region enumeration; strings spanning chunk boundaries are stitched.

## Session Manager (`session.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `session.save([path])` | Snapshot game funcs + notes to file | `session.save("my_session.lua")` |
| `session.load([path])` | Restore session from file | `session.load("my_session.lua")` |
| `session.status()` | Show funcs/notes/patches/hooks | `session.status()` |
| `session.note(text)` | Append free-form note | `session.note("gold offset 0x10")` |
| `session.notes()` | List notes | `session.notes()` |
| `session.clear_notes()` | Clear notes | `session.clear_notes()` |
| `session.export_sigs(path, entries)` | Save sigs via `sig.save` | `session.export_sigs("sigs.lua", entries)` |

Default session path is `lua/re_session.lua`; patches/IAT hooks are listed via `patch.list()` / `hook.backups()` status.

## VTables (`vtable.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `vtable.scan([base, size, min, max])` | Enumerate candidate vtables (runs of code pointers) | `vtable.scan(0x00400000, 0x800000, 3)` |
| `vtable.at(addr, n)` | Dump vtable entries at addr | `vtable.at(0x00AB1234, 12)` |

Heuristic: contiguous `min` pointers into executable regions (VirtualQueryEx). Pair with `disasm.func` to triage virtual methods.

## Threads (`threads.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `threads.list()` | List threads for current PID | `threads.list()` |
| `threads.current()` | Current TID + PID | `threads.current()` |

Toolhelp `Thread32First`/`Thread32Next`; marks current thread.

## RTTI (`rtti.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `rtti.list([base, size, max])` | List MSVC RTTI type names (`.?AV`/`?AU`) | `rtti.list(0x00400000, 0x300000, 100)` |
| `rtti.find(needle, base, size)` | Filter types by substring | `rtti.find("Player", 0x00400000, 0x300000)` |
| `rtti.vtables(needle, base, size)` | Type → xrefs toward nearby vtables | `rtti.vtables("Player", 0x00400000, 0x800000)` |
| `rtti.at(addr)` | Show type string + demangled name | `rtti.at(0x00AB1234)` |

Parses mangled `.?AVFoo@@` strings via `strings`/`memscan`, demangles to `Foo` (best-effort `::` nesting), then chains `xrefs.to` to locate the owning COL → vtable neighborhood.

## Report (`report.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `report.save([path])` | Write markdown snapshot (funcs, RTTI, mods, patches, notes) | `report.save("run1.md")` |
| `report.print()` | Save to `re_report.md` + console summary | `report.print()` |
| `report.collect()` | Return snapshot table without writing | `report.collect()` |

Embeds a `game.register` snippet so the report alone can re-seed the registry.

## Debug & Logging (`game.*`)

| Function | Description | Usage |
|----------|-------------|--------|
| `game.show_calls(count)` | Show recent function calls | `game.show_calls(10)` |
| `game.show_memory(count)` | Show recent memory operations | `game.show_memory(5)` |
| `game.debug_config([config])` | Configure debug settings | `game.debug_config()` |
| `game.debug_on(enabled)` | Enable/disable logging | `game.debug_on(true)` |
| `game.clear_logs()` | Clear all logs | `game.clear_logs()` |

## Memory Diff (`diff.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `diff.snap(addr, len)` | Snapshot bytes at addr | `a = diff.snap(0x12340000, 64)` |
| `diff.compare(a, b)` | Diff two snapshots (byte + i32 hint) | `diff.compare(a, b)` |
| `diff.watch(addr, len, ms, n)` | Poll and print diffs | `diff.watch(0x12340000, 64, 200, 20)` |

Use when you don't know the exact value: snapshot, perform an in-game action, snapshot again, then diff.

## Heap Walker (`heap.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `heap.list()` | List heaps + block counts | `heap.list()` |
| `heap.blocks(heapId, max)` | Dump blocks of one heap | `heap.blocks(1, 200)` |
| `heap.find(addr)` | Which heap/block owns addr? | `heap.find(0x12340000)` |

Toolhelp `Heap32List`/`Heap32First` enumeration; narrows valuescan to heap memory.

## Safe Probe (`probe.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `probe.at(addr, sigs [,arg_sets])` | Try sigs × arg sets at addr, print OK/FAIL | `probe.at(0x401000, {"int()", "void(int)"})` |
| `probe.register(name, addr [,sigs])` | Probe with common sigs then `game.register` best | `probe.register("GetGold", 0x401000)` |
| `probe.batch(addrs, sigs)` | Try sigs at each addr, report best per addr | `probe.batch({0x401000, 0x401100}, {"int()"})` |
| `probe.bestSig(addr, sigs)` | First OK sig at addr (single `probe.at`) | `probe.bestSig(0x401000, {"int()"})` |

Tries `ffi.cast(sig.."*", addr)` + `pcall` per arg set so a wrong signature does not crash the console.

## Raw Dumper (`dump.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `dump.region(base, size, path)` | Dump raw bytes to file | `dump.region(0x401000, 0x10000, "text.bin")` |
| `dump.range(addr, len, path)` | Alias for `dump.region` | `dump.range(0x401000, 64, "slice.bin")` |
| `dump.func(addr, path [,max])` | Dump func until RET | `dump.func(0x401000, "func.bin")` |

Reads via `ReadProcessMemory` and writes with `ffi.string` to preserve NULs.

## Enums (`enums.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `enums.lookup(kind, id)` | Decode id via enum (building/good/title/unit) | `enums.lookup("building", 3)` |
| `enums.dump([kind])` | List enum values | `enums.dump("building")` |

Kinds: `building`, `title`/`good`/`unit_type`/`skill`/`season`/`difficulty`/`guild`/`office`/`faction`/`quest_status`/`marriage`/`crime`/`production`/`morale`/`world_event`/`stock`/`court_favor` (aliases `event`→`world_event`, `favor`→`court_favor`). Extend the `enums.*` tables as you learn more.

## Code Generator (`codegen.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `codegen.struct(name, fields [,opts])` | Emit `ffi.cdef` + `struct.register` | `codegen.struct("Player", {{name="gold",type="int"}})` |
| `codegen.cdef(name, fields)` | Emit `ffi.cdef` only | `codegen.cdef("Player", {{"gold","int"}})` |
| `codegen.func_stub(name, sig [,desc])` | Emit `game.register` stub | `codegen.func_stub("GetGold","int()")` |

Accepts `{name,type}` or `[name,type]` field rows; computes aligned offsets.

## Player Helper (`player.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `player.at(addr)` | Player object at addr | `player.at(0x00AB1234):gold()` |
| `player.scan([base,size,hint])` | Locate player via presets/valuescan | `player.scan(0x400000, 0x300000, 1500)` |
| `player.find([base,size])` | `catalog.hunt("economy")` helper | `player.find()` |
| `o:gold()` / `o:set_gold(v)` | Read/write gold at +0 | `player.at(p):set_gold(9999)` |
| `o:fame()` / `o:set_fame(v)` | Read/write fame at +4 | `player.at(p):fame()` |
| `o:name()` | Read name at +8 as string | `player.at(p):name()` |
| `o:dump()` | Field-aware dump via `struct` | `player.at(p):dump()` |

Wraps `valuescan`/`pointer`/`struct`/`game.read_mem` for the most common first target.

## City Helper (`city.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `city.at(addr)` | City object at addr | `city.at(0x00AB1234):gold()` |
| `city.scan([base,size])` | Locate city via `presets.hunt("city")` | `city.scan(0x400000, 0x300000)` |
| `city.find([base,size])` | `catalog.hunt("world")` + `"city"` helper | `city.find()` |
| `o:gold()` / `o:set_gold(v)` | Treasury at `+offsets.gold` (default 8) | `city.at(p):set_gold(9999)` |
| `o:population()` / `o:set_population(v)` | Pop at +0 | `city.at(p):population()` |
| `o:happiness()` / `o:set_happiness(v)` | Happiness at +4 | `city.at(p):happiness()` |
| `o:owner()` / `o:set_owner(v)` | Owner id at +12 | `city.at(p):owner()` |
| `o:name()` | Name at +16 as string | `city.at(p):name()` |
| `o:dump()` | Field-aware dump via `struct` | `city.at(p):dump()` |
| `city.offsets` | Override field offsets | `city.offsets.gold = 0x10` |

Offsets are placeholders; calibrate via `struct.dump` once the real city struct is reversed.

## Building Helper (`building.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `building.at(addr)` | Building object | `building.at(0x00AB1234):level()` |
| `building.scan([base,size])` | Locate via `presets.hunt("building")` | `building.scan(0x400000, 0x300000)` |
| `building.find([base,size])` | `catalog.hunt("building")` helper | `building.find()` |
| `o:level()` / `o:set_level(v)` | Level at +0 | `building.at(p):level()` |
| `o:owner()` / `o:set_owner(v)` | Owner at +4 | `building.at(p):owner()` |
| `o:btype()` | Type id at +8 | `building.at(p):btype()` |
| `o:workers()` / `o:set_workers(v)` | Workers at +12 | `building.at(p):workers()` |
| `o:max_workers()` | Max workers at +16 | `building.at(p):max_workers()` |
| `o:output()` / `o:set_output(v)` | Output at +20 | `building.at(p):output()` |
| `o:durability()` / `o:set_durability(v)` | Durability at +28 | `building.at(p):durability()` |
| `o:income()` / `o:set_income(v)` | Income at +32 | `building.at(p):income()` |
| `o:efficiency()` / `o:set_efficiency(v)` | Efficiency at +36 | `building.at(p):efficiency()` |
| `o:morale()` / `o:set_morale(v)` | Morale at +40 | `building.at(p):morale()` |
| `o:capacity()` / `o:set_capacity(v)` | Warehouse capacity (via Get/SetWarehouseCapacity) | `building.at(p):capacity()` |
| `o:upkeep()` / `o:upkeep_via_call()` / `o:set_upkeep_via_call(v)` | Upkeep via offset or Get/SetBuildingUpkeep | `building.at(p):upkeep()` |
| `o:harvest(gid)` / `o:set_harvest(gid,v)` | Harvest yield via Get/SetHarvestYield | `building.at(p):harvest(3)` |
| `o:servants()` / `o:slots()` | Servant count / workshop slots (GetServantCount / GetWorkshopSlots) | `building.at(p):servants()` |
| `o:rent()` / `o:set_rent(v)` | Building rent (GetBuildingRent / SetBuildingRent) | `building.at(p):rent()` |
| `o:security()` | Building security (GetBuildingSecurity) | `building.at(p):security()` |
| `o:blessing()` / `o:set_blessing(v)` | Building blessing (Get/SetBuildingBlessing) | `building.at(p):blessing()` |
| `o:btax_rate()` / `o:set_btax_rate(v)` | Building tax rate (Get/SetBuildingTaxRate) | `building.at(p):btax_rate()` |
| `o:prod_bonus(gid)` / `o:set_prod_bonus(gid,v)` | Production bonus (Get/SetProductionBonus) | `building.at(p):prod_bonus(0)` |
| `o:strikes()` | Workshop strikes (GetWorkshopStrikes) | `building.at(p):strikes()` |
| `o:apprentice_slots()` | Apprentice slots (GetWorkshopApprenticeSlots) | `building.at(p):apprentice_slots()` |
| `o:granary_cap()` | Granary capacity (GetGranaryCapacity) | `building.at(p):granary_cap()` |
| `o:baker_bonus(gid)` / `o:set_baker_bonus(gid,v)` | Baker bonus (Get/SetBakerOutputBonus) | `building.at(p):baker_bonus(0)` |
| `o:master_bribe()` | Master bribe cost (GetMasterBribeCost) | `building.at(p):master_bribe()` |
| `o:upgrade_cost(uid)` | Workshop upgrade cost (GetWorkshopUpgradeCost) | `building.at(p):upgrade_cost(0)` |
| `o:brewery_output(gid)` / `o:set_brewery_output(gid,v)` | Brewery output (Get/SetBreweryOutput) | `building.at(p):brewery_output(0)` |
| `o:mill_output(gid)` / `o:set_mill_output(gid,v)` | Mill output (Get/SetMillOutput) | `building.at(p):mill_output(0)` |
| `o:blacksmith_output(gid)` / `o:set_blacksmith_output(gid,v)` | Blacksmith output (Get/SetBlacksmithOutput) | `building.at(p):blacksmith_output(0)` |
| `o:tannery_output(gid)` / `o:set_tannery_output(gid,v)` | Tannery output (Get/SetTanneryOutput) | `building.at(p):tannery_output(0)` |
| `o:weaver_output(gid)` / `o:set_weaver_output(gid,v)` | Weaver output (Get/SetWeaverOutput) | `building.at(p):weaver_output(0)` |
| `o:mint_profit()` | Mint profit (GetMintProfit) | `building.at(p):mint_profit()` |
| `o:herb_yield(gid)` | Herb garden yield (GetHerbGardenYield) | `building.at(p):herb_yield(0)` |
| `o:vineyard_output(gid)` / `o:set_vineyard_output(gid,v)` | Vineyard output (Get/SetVineyardOutput) | `building.at(p):vineyard_output(0)` |
| `o:pottery_output(gid)` / `o:set_pottery_output(gid,v)` | Pottery output (Get/SetPotteryOutput) | `building.at(p):pottery_output(0)` |
| `o:tailor_output(gid)` / `o:set_tailor_output(gid,v)` | Tailor output (Get/SetTailorOutput) | `building.at(p):tailor_output(0)` |
| `o:fishing_yield(gid)` | Fishing yield (GetFishingYield) | `building.at(p):fishing_yield(0)` |
| `o:orchard_yield(gid)` | Orchard yield (GetOrchardYield) | `building.at(p):orchard_yield(0)` |
| `o:carpenter_output(gid)` / `o:set_carpenter_output(gid,v)` | Carpenter output (Get/SetCarpenterOutput) | `building.at(p):carpenter_output(0)` |
| `o:ropemaker_output(gid)` / `o:set_ropemaker_output(gid,v)` | Ropemaker output (Get/SetRopemakerOutput) | `building.at(p):ropemaker_output(0)` |
| `o:apiary_yield(gid)` | Apiary yield (GetApiaryYield) | `building.at(p):apiary_yield(0)` |
| `o:hunting_yield(gid)` | Hunting yield (GetHuntingYield) | `building.at(p):hunting_yield(0)` |
| `o:alchemist_output(gid)` / `o:set_alchemist_output(gid,v)` | Alchemist output (Get/SetAlchemistOutput) | `building.at(p):alchemist_output(0)` |
| `o:glassworks_output(gid)` / `o:set_glassworks_output(gid,v)` | Glassworks output (Get/SetGlassworksOutput) | `building.at(p):glassworks_output(0)` |
| `o:mason_output(gid)` / `o:set_mason_output(gid,v)` | Mason output (Get/SetMasonOutput) | `building.at(p):mason_output(0)` |
| `o:distillery_output(gid)` / `o:set_distillery_output(gid,v)` | Distillery output (Get/SetDistilleryOutput) | `building.at(p):distillery_output(0)` |
| `o:pasture_yield(gid)` | Pasture yield (GetPastureYield) | `building.at(p):pasture_yield(0)` |
| `o:quarry_yield(gid)` | Quarry yield (GetQuarryYield) | `building.at(p):quarry_yield(0)` |
| `o:forge_output(gid)` / `o:set_forge_output(gid,v)` | Forge output (Get/SetForgeOutput) | `building.at(p):forge_output(0)` |
| `o:sawmill_output(gid)` / `o:set_sawmill_output(gid,v)` | Sawmill output (Get/SetSawmillOutput) | `building.at(p):sawmill_output(0)` |
| `o:kiln_output(gid)` / `o:set_kiln_output(gid,v)` | Kiln output (Get/SetKilnOutput) | `building.at(p):kiln_output(0)` |
| `o:foundry_output(gid)` / `o:set_foundry_output(gid,v)` | Foundry output (Get/SetFoundryOutput) | `building.at(p):foundry_output(0)` |
| `o:apothecary_output(gid)` / `o:set_apothecary_output(gid,v)` | Apothecary output (Get/SetApothecaryOutput) | `building.at(p):apothecary_output(0)` |
| `o:scribe_output(gid)` / `o:set_scribe_output(gid,v)` | Scribe output (Get/SetScribeOutput) | `building.at(p):scribe_output(0)` |
| `o:goldsmith_output(gid)` | Goldsmith output (GetGoldsmithOutput) | `building.at(p):goldsmith_output(0)` |
| `o:falconer_yield(gid)` | Falconer yield (GetFalconerYield) | `building.at(p):falconer_yield(0)` |
| `o:jeweler_output(gid)` / `o:set_jeweler_output(gid,v)` | Jeweler output (Get/SetJewelerOutput) | `building.at(p):jeweler_output(0)` |
| `o:bathhouse_income()` | Bathhouse income (GetBathhouseIncome) | `building.at(p):bathhouse_income()` |
| `o:perfumer_output(gid)` / `o:set_perfumer_output(gid,v)` | Perfumer output (Get/SetPerfumerOutput) | `building.at(p):perfumer_output(0)` |
| `o:soapmaker_output(gid)` / `o:set_soapmaker_output(gid,v)` | Soapmaker output (Get/SetSoapmakerOutput) | `building.at(p):soapmaker_output(0)` |
| `o:candlemaker_output(gid)` / `o:set_candlemaker_output(gid,v)` | Candlemaker output (Get/SetCandlemakerOutput) | `building.at(p):candlemaker_output(0)` |
| `o:papermill_output(gid)` / `o:set_papermill_output(gid,v)` | Papermill output (Get/SetPapermillOutput) | `building.at(p):papermill_output(0)` |
| `o:printing_output(gid)` / `o:set_printing_output(gid,v)` | Printing output (Get/SetPrintingOutput) | `building.at(p):printing_output(0)` |
| `o:toolmaker_output(gid)` / `o:set_toolmaker_output(gid,v)` | Toolmaker output (Get/SetToolmakerOutput) | `building.at(p):toolmaker_output(0)` |
| `o:charcoal_output(gid)` / `o:set_charcoal_output(gid,v)` | Charcoal output (Get/SetCharcoalOutput) | `building.at(p):charcoal_output(0)` |
| `o:furrier_output(gid)` / `o:set_furrier_output(gid,v)` | Furrier output (Get/SetFurrierOutput) | `building.at(p):furrier_output(0)` |
| `o:dyer_output(gid)` / `o:set_dyer_output(gid,v)` | Dyer output (Get/SetDyerOutput) | `building.at(p):dyer_output(0)` |
| `o:saddler_output(gid)` / `o:set_saddler_output(gid,v)` | Saddler output (Get/SetSaddlerOutput) | `building.at(p):saddler_output(0)` |
| `o:armorer_output(gid)` / `o:set_armorer_output(gid,v)` | Armorer output (Get/SetArmorerOutput) | `building.at(p):armorer_output(0)` |
| `o:bowyer_output(gid)` / `o:set_bowyer_output(gid,v)` | Bowyer output (Get/SetBowyerOutput) | `building.at(p):bowyer_output(0)` |
| `o:cartwright_output(gid)` / `o:set_cartwright_output(gid,v)` | Cartwright output (Get/SetCartwrightOutput) | `building.at(p):cartwright_output(0)` |
| `o:mint_output(gid)` / `o:set_mint_output(gid,v)` | Mint output (Get/SetMintOutput) | `building.at(p):mint_output(0)` |
| `o:winery_output(gid)` / `o:set_winery_output(gid,v)` | Winery output (Get/SetWineryOutput) | `building.at(p):winery_output(0)` |
| `o:shipwright_output(gid)` / `o:set_shipwright_output(gid,v)` | Shipwright output (Get/SetShipwrightOutput) | `building.at(p):shipwright_output(0)` |
| `o:cooper_output(gid)` / `o:set_cooper_output(gid,v)` | Cooper output (Get/SetCooperOutput) | `building.at(p):cooper_output(0)` |
| `o:spinner_output(gid)` / `o:set_spinner_output(gid,v)` | Spinner output (Get/SetSpinnerOutput) | `building.at(p):spinner_output(0)` |
| `o:turner_output(gid)` / `o:set_turner_output(gid,v)` | Turner output (Get/SetTurnerOutput) | `building.at(p):turner_output(0)` |
| `o:barber_output(gid)` / `o:set_barber_output(gid,v)` | Barber output (Get/SetBarberOutput) | `building.at(p):barber_output(0)` |
| `o:stonecutter_output(gid)` / `o:set_stonecutter_output(gid,v)` | Stonecutter output (Get/SetStonecutterOutput) | `building.at(p):stonecutter_output(0)` |
| `o:tailor_master_output(gid)` / `o:set_tailor_master_output(gid,v)` | Tailor master output (Get/SetTailorMasterOutput) | `building.at(p):tailor_master_output(0)` |
| `o:cobbler_output(gid)` / `o:set_cobbler_output(gid,v)` | Cobbler output (Get/SetCobblerOutput) | `building.at(p):cobbler_output(0)` |
| `o:butcher_output(gid)` / `o:set_butcher_output(gid,v)` | Butcher output (Get/SetButcherOutput) | `building.at(p):butcher_output(0)` |
| `o:baker2_output(gid)` / `o:set_baker2_output(gid,v)` | Baker output v2 (Get/SetBakerOutput2) | `building.at(p):baker2_output(0)` |
| `o:shepherd_yield(gid)` | Shepherd yield (GetShepherdYield) | `building.at(p):shepherd_yield(0)` |
| `o:dairy_yield(gid)` | Dairy yield (GetDairyYield) | `building.at(p):dairy_yield(0)` |
| `o:brewmaster_output(gid)` / `o:set_brewmaster_output(gid,v)` | Brewmaster output (Get/SetBrewmasterOutput) | `building.at(p):brewmaster_output(0)` |
| `o:miller_yield(gid)` | Miller yield (GetMillerYield) | `building.at(p):miller_yield(0)` |
| `o:fishery_yield(gid)` | Fishery yield (GetFisheryYield) | `building.at(p):fishery_yield(0)` |
| `o:joiner_output(gid)` / `o:set_joiner_output(gid,v)` | Joiner output (Get/SetJoinerOutput) | `building.at(p):joiner_output(0)` |
| `o:carter_output(gid)` / `o:set_carter_output(gid,v)` | Carter output (Get/SetCarterOutput) | `building.at(p):carter_output(0)` |
| `o:mining_yield(gid)` | Mining yield (GetMiningYield) | `building.at(p):mining_yield(0)` |
| `o:logging_yield(gid)` | Logging yield (GetLoggingYield) | `building.at(p):logging_yield(0)` |
| `o:innkeeper_income()` | Innkeeper income (GetInnkeeperIncome) | `building.at(p):innkeeper_income()` |
| `o:tollmaster_income()` | Tollmaster income (GetTollMasterIncome) | `building.at(p):tollmaster_income()` |
| `o:chandler_output(gid)` / `o:set_chandler_output(gid,v)` | Chandler output (Get/SetChandlerOutput) | `building.at(p):chandler_output(0)` |
| `o:goldbeater_output(gid)` / `o:set_goldbeater_output(gid,v)` | Goldbeater output (Get/SetGoldbeaterOutput) | `building.at(p):goldbeater_output(0)` |
| `o:potter_output(gid)` / `o:set_potter_output(gid,v)` | Potter output (Get/SetPotterOutput) | `building.at(p):potter_output(0)` |
| `o:fowler_yield(gid)` | Fowler yield (GetFowlerYield) | `building.at(p):fowler_yield(0)` |
| `o:vintner_output(gid)` | Vintner output (GetVintnerOutput) | `building.at(p):vintner_output(0)` |
| `o:distiller_yield(gid)` | Distiller yield (GetDistillerYield) | `building.at(p):distiller_yield(0)` |
| `o:cook_output(gid)` / `o:set_cook_output(gid,v)` | Cook output (Get/SetCookOutput) | `building.at(p):cook_output(0)` |
| `o:brickmaker_output(gid)` / `o:set_brickmaker_output(gid,v)` | Brickmaker output (Get/SetBrickmakerOutput) | `building.at(p):brickmaker_output(0)` |
| `o:chandler_yield(gid)` | Chandler yield alt (GetChandlerYield) | `building.at(p):chandler_yield(0)` |
| `o:inn_income()` | Inn income (GetInnIncome) | `building.at(p):inn_income()` |
| `o:hospital_cap()` | Hospital capacity (GetHospitalCapacity) | `building.at(p):hospital_cap()` |
| `o:tavern_income()` | Tavern income (GetTavernIncome) | `building.at(p):tavern_income()` |
| `o:accident()` / `o:set_accident(v)` | Accident chance (Get/SetAccidentChance) | `building.at(p):accident()` |
| `o:fire_risk()` | Fire risk (GetWorkshopFireRisk) | `building.at(p):fire_risk()` |
| `o:trade_reputation(city)` / `o:set_trade_reputation(city,n)` | Trade reputation (Get/SetTradeReputation) | `building.at(p):trade_reputation(1)` |
| `o:caravan_value()` | Caravan value (GetCaravanValue) | `building.at(p):caravan_value()` |
| `o:inventory_count(gid)` | Inventory count (GetInventoryCount) | `building.at(p):inventory_count(3)` |

| `o:is_running()` | Workshop running (IsWorkshopRunning) | `building.at(p):is_running()` |
| `o:name()` | Name at +44 | `building.at(p):name()` |
| `o:upgrade()` | Call `UpgradeBuilding` or bump level | `building.at(p):upgrade()` |
| `o:dump()` | Field-aware dump via `struct` | `building.at(p):dump()` |
| `building.offsets` | Override offsets | `building.offsets.level = 0x10` |

## Unit Helper (`unit.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `unit.at(addr)` | Unit object | `unit.at(0x00AB1234):health()` |
| `unit.scan([base,size])` | Locate via `presets.hunt("unit")` | `unit.scan(0x400000, 0x300000)` |
| `unit.find([base,size])` | `catalog.hunt("unit")` helper | `unit.find()` |
| `o:health()` / `o:set_health(v)` | Health at +0 | `unit.at(p):health()` |
| `o:owner()` / `o:set_owner(v)` | Owner at +4 | `unit.at(p):owner()` |
| `o:utype()` | Type id at +8 | `unit.at(p):utype()` |
| `o:x()` / `o:y()` / `o:pos()` | Position | `unit.at(p):pos()` |
| `o:skill()` / `o:set_skill(v)` | Skill at +20 | `unit.at(p):skill()` |
| `o:name()` | Name at +24 | `unit.at(p):name()` |
| `o:move(x,y)` | Call `MoveUnit` or set x/y | `unit.at(p):move(100,200)` |
| `o:delete()` | Call `DeleteUnit` | `unit.at(p):delete()` |
| `o:dump()` | Field-aware dump | `unit.at(p):dump()` |
| `o:cart_speed()` / `o:set_cart_speed(v)` | Cart speed (via Get/SetCartSpeed) | `unit.at(p):cart_speed()` |
| `o:cart_capacity()` / `o:set_cart_capacity(v)` | Cart capacity (via Get/SetCartCapacity) | `unit.at(p):cart_capacity()` |
| `o:cart_goods(gid)` / `o:has_goods(gid,n)` | Cart goods (via GetCartGoods/HasCartGoods) | `unit.at(p):cart_goods(3)` |
| `o:guard_level()` | Cart guard level (GetCartGuardLevel) | `unit.at(p):guard_level()` |
| `o:caravan_value()` | Caravan value (GetCaravanValue) | `unit.at(p):caravan_value()` |
| `unit.offsets` | Override offsets | `unit.offsets.health = 0x10` |

## Inventory Helper (`inventory.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `inventory.at(addr)` | Inventory/warehouse at addr | `inventory.at(0x00AB1234):list()` |
| `inventory.scan([base,size])` | Locate via `presets.hunt("inventory")` | `inventory.scan(0x400000, 0x300000)` |
| `inventory.find([base,size])` | `catalog.hunt("inventory")` helper | `inventory.find()` |
| `inventory.get(owner,item)` | Count via `GetInventoryCount`/`GetWarehouseGoods` or raw slots | `inventory.get(owner, 3)` |
| `inventory.add(owner,item,n)` | `AddInventoryItem` wrapper | `inventory.add(owner, 3, 10)` |
| `inventory.remove(owner,item,n)` | `RemoveInventoryItem` wrapper | `inventory.remove(owner, 3, 5)` |
| `inventory.warehouse(wh, good)` | `GetWarehouseGoods` wrapper | `inventory.warehouse(2, 3)` |
| `inventory.transfer(s,d,g,n)` | `TransferGoods` wrapper | `inventory.transfer(a,b,3,10)` |
| `inventory.value(wh)` / `inventory.set_warehouse_capacity(wh,v)` | `GetInventoryValue` / `SetWarehouseCapacity` | `inventory.value(p)` |
| `inventory.cart_capacity(cart)` / `inventory.set_cart_capacity(cart,v)` | `GetCartCapacity` / `SetCartCapacity` | `inventory.cart_capacity(cart)` |
| `economy.caravan_value(ptr)` / `inventory.get_goods(ptr,gid)` / `inventory.set_goods(ptr,gid,v)` | `GetCaravanValue` / `GetInventoryCount` goods helpers | `inventory.get_goods(p, 3)` |
| `o:item(i)` | Slot i `{id,count,addr}` | `inventory.at(p):item(0)` |
| `o:count_for(goodId)` | Count for one good across slots | `inventory.at(p):count_for(3)` |
| `o:list()` | Print non-empty slots (with good names) | `inventory.at(p):list()` |
| `o:dump()` | Struct + list | `inventory.at(p):dump()` |
| `inventory.offsets` | `{stride,id,count,max_items}` | `inventory.offsets.stride = 8` |

The raw slot layout is a placeholder; calibrate via `struct.dump` once the real inventory struct is reversed.

## Economy Helper (`economy.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `economy.find([base,size])` | `catalog.hunt("economy")` | `economy.find()` |
| `economy.scan([base,size])` | Hunt guild/trade/tax/inventory presets | `economy.scan(0x400000, 0x300000)` |
| `economy.guild_balance(gid)` | `GetGuildBalance` | `economy.guild_balance(0)` |
| `economy.set_guild_balance(gid,n)` | `SetGuildBalance` | `economy.set_guild_balance(0, 5000)` |
| `economy.market_price(gid,cid)` | `GetMarketPrice` | `economy.market_price(3, 0)` |
| `economy.set_market_price(gid,cid,p)` | `SetMarketPrice` | `economy.set_market_price(3, 0, 42)` |
| `economy.tax_rate(cid,gid)` | `GetTaxRate` | `economy.tax_rate(0, 3)` |
| `economy.set_tax_rate(cid,gid,r)` | `SetTaxRate` | `economy.set_tax_rate(0, 3, 10)` |
| `economy.route(id)` | `GetTradeRoute` | `economy.route(0)` |
| `economy.create_route(s,d,g)` | `CreateTradeRoute` | `economy.create_route(0,1,3)` |
| `economy.delete_route(id)` | `DeleteTradeRoute` | `economy.delete_route(0)` |

| `economy.stock(pid,sid)` / `economy.set_stock(pid,sid,n)` | `GetStockCount` / `SetStockCount` | `economy.stock(0, 1)` |
| `economy.daily_income(pid)` / `economy.set_daily_income(pid,n)` | `GetDailyIncome` / `SetDailyIncome` | `economy.daily_income(0)` |
| `economy.bribe_price(cid,oid)` / `economy.set_bribe_price(cid,oid,price)` | `GetBribePrice` / `SetBribePrice` | `economy.bribe_price(0, 1)` |
| `economy.title_cost(tid)` | `GetTitleCost` | `economy.title_cost(1)` |
| `economy.trade_profit(a,b,good)` | `GetTradeProfit` | `economy.trade_profit(0,1,3)` |
| `economy.trade_tax(a,b,good)` / `economy.set_trade_tax(a,b,good,tax)` | `GetTradeTax` / `SetTradeTax` | `economy.trade_tax(0,1,3)` |
| `economy.supply(cid,gid)` / `economy.set_supply(cid,gid,v)` | `GetMarketSupply` / `SetMarketSupply` | `economy.supply(0,3)` |
| `economy.demand(cid,gid)` / `economy.set_demand(cid,gid,v)` | `GetMarketDemand` / `SetMarketDemand` | `economy.demand(0,3)` |
| `economy.cook_output(ptr,idx)` / `economy.set_cook_output(ptr,idx,n)` | `GetCookOutput` / `SetCookOutput` | `economy.cook_output(p)` |
| `economy.cooper_output(ptr,idx)` / `economy.set_cooper_output(ptr,idx,n)` | `GetCooperOutput` / `SetCooperOutput` | `economy.cooper_output(p)` |
| `economy.dyer_output(ptr,idx)` / `economy.set_dyer_output(ptr,idx,n)` | `GetDyerOutput` / `SetDyerOutput` | `economy.dyer_output(p)` |
| `economy.furrier_output(ptr,idx)` / `economy.set_furrier_output(ptr,idx,n)` | `GetFurrierOutput` / `SetFurrierOutput` | `economy.furrier_output(p)` |
| `economy.saddler_output(ptr,idx)` / `economy.set_saddler_output(ptr,idx,n)` | `GetSaddlerOutput` / `SetSaddlerOutput` | `economy.saddler_output(p)` |
| `economy.ropemaker_output(ptr,idx)` / `economy.set_ropemaker_output(ptr,idx,n)` | `GetRopemakerOutput` / `SetRopemakerOutput` | `economy.ropemaker_output(p)` |
| `economy.tannery_output(ptr,idx)` / `economy.set_tannery_output(ptr,idx,n)` | `GetTanneryOutput` / `SetTanneryOutput` | `economy.tannery_output(p)` |
| `economy.weaving_output(ptr,idx)` / `economy.set_weaving_output(ptr,idx,n)` | `GetWeaverOutput` / `SetWeaverOutput` | `economy.weaving_output(p)` |
| `economy.potter_output(ptr,idx)` / `economy.set_potter_output(ptr,idx,n)` | `GetPotterOutput` / `SetPotterOutput` | `economy.potter_output(p)` |
| `economy.miller_output(ptr,idx)` / `economy.set_miller_output(ptr,idx,n)` | `GetMillOutput` / `SetMillOutput` | `economy.miller_output(p)` |
| `economy.baker_bonus_output(ptr,idx)` / `economy.set_baker_bonus_output(ptr,idx,n)` | `GetBakerOutputBonus` / `SetBakerOutputBonus` | `economy.baker_bonus_output(p)` |
| `economy.barber_output(ptr,idx)` / `economy.set_barber_output(ptr,idx,n)` | `GetBarberOutput` / `SetBarberOutput` | `economy.barber_output(p)` |
| `economy.goldsmith_output(ptr,idx)` / `economy.set_goldsmith_output(ptr,idx,n)` | `GetGoldsmithOutput` / `SetGoldsmithOutput` | `economy.goldsmith_output(p)` |
| `economy.vintner_output(ptr,idx)` / `economy.set_vintner_output(ptr,idx,n)` | `GetVintnerOutput` / `SetVintnerOutput` | `economy.vintner_output(p)` |
| `economy.herbgarden_yield(ptr,idx)` / `economy.set_herbgarden_yield(ptr,idx,n)` | `GetHerbGardenYield` / `SetHerbGardenYield` | `economy.herbgarden_yield(p)` |
| `economy.tailor_master_output(ptr,idx)` / `economy.set_tailor_master_output(ptr,idx,n)` | `GetTailorMasterOutput` / `SetTailorMasterOutput` | `economy.tailor_master_output(p)` |
| `economy.harvest_yield(ptr,idx)` / `economy.set_harvest_yield(ptr,idx,n)` | `GetHarvestYield` / `SetHarvestYield` | `economy.harvest_yield(p)` |
| `economy.dairy_yield(ptr,idx)` | `GetDairyYield` | `economy.dairy_yield(p)` |
| `economy.fishing_yield(ptr,idx)` | `GetFishingYield` | `economy.fishing_yield(p)` |
| `economy.hunting_yield(ptr,idx)` | `GetHuntingYield` | `economy.hunting_yield(p)` |
| `economy.pasture_yield(ptr,idx)` | `GetPastureYield` | `economy.pasture_yield(p)` |
| `economy.apiary_yield(ptr,idx)` | `GetApiaryYield` | `economy.apiary_yield(p)` |
| `economy.orchard_yield(ptr,idx)` | `GetOrchardYield` | `economy.orchard_yield(p)` |
| `economy.chandler_yield(ptr,idx)` | `GetChandlerYield` | `economy.chandler_yield(p)` |
| `economy.quarry_yield(ptr,idx)` | `GetQuarryYield` | `economy.quarry_yield(p)` |
| `economy.falconer_yield(ptr,idx)` | `GetFalconerYield` | `economy.falconer_yield(p)` |
| `economy.shepherd_yield(ptr,idx)` | `GetShepherdYield` | `economy.shepherd_yield(p)` |
| `economy.fishery_yield(ptr,idx)` | `GetFisheryYield` | `economy.fishery_yield(p)` |
| `economy.fowler_yield(ptr,idx)` | `GetFowlerYield` | `economy.fowler_yield(p)` |
| `economy.distiller_yield(ptr,idx)` | `GetDistillerYield` | `economy.distiller_yield(p)` |
| `economy.mining_yield(ptr,idx)` | `GetMiningYield` | `economy.mining_yield(p)` |
| `economy.logging_yield(ptr,idx)` | `GetLoggingYield` | `economy.logging_yield(p)` |
| `economy.inventory_value(owner)` | `GetInventoryValue` | `economy.inventory_value(owner)` |
| `economy.assassination_cost(a,b)` | `GetAssassinationCost` | `economy.assassination_cost(0,1)` |
| `economy.sabotage_cost(pid,bldg)` | `GetSabotageCost` | `economy.sabotage_cost(0,bldg)` |
| `economy.debt(pid)` / `economy.set_debt(pid,v)` | `GetPlayerDebt` / `SetPlayerDebt` | `economy.debt(0)` |
| `economy.bank(pid)` / `economy.set_bank(pid,v)` | `GetBankBalance` / `SetBankBalance` | `economy.bank(0)` |
| `economy.loan(pid,loanId)` / `economy.set_loan(pid,loanId,v)` | `GetLoanAmount` / `SetLoanAmount` | `economy.loan(0,1)` |
| `economy.interest(cid)` / `economy.set_interest(cid,v)` | `GetInterestRate` / `SetInterestRate` | `economy.interest(0)` |
| `economy.repay(pid,loanId)` | `GetRepayAmount` | `economy.repay(0,1)` |
| `economy.pay_loan(pid,loanId,amount)` | `PayLoan` | `economy.pay_loan(0,1,500)` |
| `economy.take_loan(pid,amount,duration)` | `TakeLoan` | `economy.take_loan(0,5000,12)` |
| `economy.credit(pid)` / `economy.set_credit(pid,v)` | `GetCreditScore` / `SetCreditScore` | `economy.credit(0)` |
| `economy.blackmail_cost(a,b)` | `GetBlackmailCost` | `economy.blackmail_cost(0,1)` |
| `economy.bribe_official(pid,cid,oid,amount)` | `BribeOfficial` | `economy.bribe_official(0,0,1,500)` |
| `economy.guild_fee(gid)` / `economy.set_guild_fee(gid,v)` | `GetGuildFee` / `SetGuildFee` | `economy.guild_fee(0)` |
| `economy.route_profit(a,b,g)` | `GetTradeRouteProfit` | `economy.route_profit(0,0,3)` |

Aliases: `economy.guild` → `guild_balance`, `economy.price` → `market_price`, `economy.income` → `daily_income`, `economy.bribe` → `bribe_price`. All wrappers error with a hint if the catalog entry not yet registered.

## World Helper (`world.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `world.find([base,size])` | `catalog.hunt("world")` | `world.find()` |
| `world.scan([base,size])` | Hunt clock/city/map/guild presets | `world.scan(0x400000, 0x300000)` |
| `world.time()` / `world.set_time(h)` | `GetTimeHours` / `SetTimeHours` | `world.time()` |
| `world.year()` / `world.set_year(y)` | `GetYear` / `SetYear` | `world.set_year(1400)` |
| `world.season()` | `GetSeason` (0..3) | `world.season()` |
| `world.speed()` / `world.set_speed(v)` | `GetGameSpeed` / `SetGameSpeed` | `world.set_speed(2)` |
| `world.difficulty()` / `world.set_difficulty(v)` | `GetDifficulty` / `SetDifficulty` | `world.set_difficulty(1)` |
| `world.is_paused()` | `IsGamePaused` | `world.is_paused()` |
| `world.city_owner(id)` / `world.set_city_owner(id,o)` | `GetCityOwner` / `SetCityOwner` | `world.city_owner(0)` |
| `world.is_besieged(id)` | `IsCityBesieged` | `world.is_besieged(0)` |
| `world.enter(pid,cid)` / `world.leave(pid)` | `EnterCity` / `LeaveCity` | `world.enter(0, 2)` |
| `world.office(cid,oid)` / `world.set_office(cid,oid,pid)` | `GetOfficeHolder` / `SetOfficeHolder` | `world.office(0, 1)` |
| `world.selected_unit()` / `world.selected_building()` | `GetSelectedUnit` / `GetSelectedBuilding` | `world.selected_unit()` |
| `world.office_bribe_cost(cid,oid)` / `world.is_bribed(cid,oid)` | `GetOfficeBribeCost` / `IsBribed` | `world.office_bribe_cost(0,1)` |
| `world.office_prestige(cid,oid)` / `world.is_office_vacant(cid,oid)` | `GetOfficePrestige` / `IsOfficeVacant` | `world.office_prestige(0,1)` |
| `world.guard_count(cid)` / `world.set_guard_count(cid,n)` | `GetGuardCount` / `SetGuardCount` | `world.guard_count(0)` |
| `world.city_rank(cid)` / `world.city_prestige(cid)` / `world.set_city_prestige(cid,v)` | `GetCityRank` / `GetCityPrestige` / `SetCityPrestige` | `world.city_rank(0)` |
| `world.public_order(cid)` / `world.set_public_order(cid,v)` | `GetPublicOrder` / `SetPublicOrder` | `world.public_order(0)` |
| `world.city_favor(cid,pid)` / `world.set_city_favor(cid,pid,v)` | `GetCityFavor` / `SetCityFavor` | `world.city_favor(0,0)` |
| `world.office_term(cid,oid)` / `world.set_office_term(cid,oid,v)` | `GetOfficeTerm` / `SetOfficeTerm` | `world.office_term(0,0)` |
| `world.militia(cid)` / `world.set_militia(cid,v)` | `GetMilitiaCount` / `SetMilitiaCount` | `world.militia(0)` |
| `world.wall_health(cid)` / `world.set_wall_health(cid,v)` | `GetCityWallHealth` / `SetCityWallHealth` | `world.wall_health(0)` |
| `world.defense(cid)` / `world.set_defense(cid,v)` | `GetCityDefense` / `SetCityDefense` | `world.defense(0)` |
| `world.unrest(cid)` / `world.set_unrest(cid,v)` | `GetCityUnrest` / `SetCityUnrest` | `world.unrest(0)` |
| `world.prosperity(cid)` / `world.set_prosperity(cid,v)` | `GetCityProsperity` / `SetCityProsperity` | `world.prosperity(0)` |
| `world.office_salary(cid,oid)` / `world.set_office_salary(cid,oid,v)` | `GetOfficeSalary` / `SetOfficeSalary` | `world.office_salary(0,0)` |
| `world.festival(cid)` | `GetFestivalState` | `world.festival(0)` |
| `world.food(cid)` / `world.set_food(cid,v)` | `GetCityFoodSupply` / `SetCityFoodSupply` | `world.food(0)` |
| `world.corruption(cid)` / `world.set_corruption(cid,v)` | `GetCityCorruption` / `SetCityCorruption` | `world.corruption(0)` |
| `world.bribe_cooldown(pid,cid,oid)` | `GetBribeCooldown` | `world.bribe_cooldown(0,0,0)` |
| `world.bandit(cid)` / `world.set_bandit(cid,v)` | `GetBanditThreat` / `SetBanditThreat` | `world.bandit(0)` |
| `world.spy_suspicion(pid,cid)` / `world.set_spy_suspicion(pid,cid,v)` | `GetSpySuspicion` / `SetSpySuspicion` | `world.spy_suspicion(0,0)` |
| `world.plague(cid)` / `world.set_plague(cid,v)` | `GetPlagueState` / `SetPlagueState` | `world.plague(0)` |
| `world.road(cid)` | `GetCityRoadQuality` | `world.road(0)` |
| `world.wall_cost(cid,lvl)` | `GetCityWallUpgradeCost` | `world.wall_cost(0,1)` |
| `world.fair(cid)` | `GetCityFairState` | `world.fair(0)` |
| `world.toll(cid,rid)` / `world.set_toll(cid,rid,v)` | `GetTollRevenue` / `SetTollRevenue` | `world.toll(0,0)` |
| `world.toll_gates(cid)` / `world.set_toll_gates(cid,n)` | `GetCityTollGateCount` / `SetCityTollGateCount` | `world.toll_gates(0)` |
| `world.escort_cost(cid,lvl)` | `GetEscortCost` | `world.escort_cost(0,1)` |
| `world.road_upkeep(cid,rid)` | `GetRoadUpkeepCost` | `world.road_upkeep(0,0)` |
| `world.market_stalls(cid)` | `GetCityMarketStallCount` | `world.market_stalls(0)` |
| `world.harbor(cid)` / `world.set_harbor(cid,lvl)` | `GetCityHarborLevel` / `SetCityHarborLevel` | `world.harbor(0)` |
| `world.tax_income(cid)` | `GetCityTaxIncome` | `world.tax_income(0)` |
| `world.university(cid)` / `world.set_university(cid,lvl)` | `GetUniversityLevel` / `SetUniversityLevel` | `world.university(0)` |
| `world.guard_morale(cid)` / `world.set_guard_morale(cid,v)` | `GetGuardMorale` / `SetGuardMorale` | `world.guard_morale(0)` |
| `world.militia_upkeep(cid)` | `GetMilitiaUpkeepCost` | `world.militia_upkeep(0)` |
| `world.smuggler_fee(cid,gid)` | `GetSmugglerFee` | `world.smuggler_fee(0,0)` |
| `world.harbor_fee(cid,gid)` | `GetHarborFee` | `world.harbor_fee(0,0)` |
| `world.festival_cost(cid,ftype)` | `GetCityFestivalCost` | `world.festival_cost(0,0)` |
| `world.stall_rent(cid,stype)` | `GetMarketStallRent` | `world.stall_rent(0,0)` |
| `world.church_tax(cid)` / `world.set_church_tax(cid,v)` | `GetChurchTaxRate` / `SetChurchTaxRate` | `world.church_tax(0)` |
| `world.market_fee(cid)` / `world.set_market_fee(cid,v)` | `GetCityMarketFee` / `SetCityMarketFee` | `world.market_fee(0)` |
| `world.watch(cid)` / `world.set_watch(cid,v)` | `GetWatchStrength` / `SetWatchStrength` | `world.watch(0)` |
| `world.debasement(cid)` / `world.set_debasement(cid,v)` | `GetCoinDebasement` / `SetCoinDebasement` | `world.debasement(0)` |
| `world.regulation(cid)` | `GetMarketRegulation` | `world.regulation(0)` |
| `world.siege(cid)` / `world.set_siege(cid,v)` | `GetSiegeProgress` / `SetSiegeProgress` | `world.siege(0)` |
| `world.garrison(cid)` / `world.set_garrison(cid,v)` | `GetWallGarrisonCount` / `SetWallGarrisonCount` | `world.garrison(0)` |
| `world.merc_cost(cid,t)` | `GetMercenaryCost` | `world.merc_cost(0,0)` |
| `world.patrol(cid)` / `world.set_patrol(cid,v)` | `GetPatrolStrength` / `SetPatrolStrength` | `world.patrol(0)` |
| `world.bandit_risk(cid,rid)` / `world.set_bandit_risk(cid,rid,v)` | `GetRoadBanditRisk` / `SetRoadBanditRisk` | `world.bandit_risk(0,0)` |
| `world.tavern_brawl(cid)` | `GetTavernBrawlChance` | `world.tavern_brawl(0)` |
| `world.guild_hall(gid,cid)` / `world.set_guild_hall(gid,cid,v)` | `GetGuildHallLevel` / `SetGuildHallLevel` | `world.guild_hall(0,0)` |
| `world.tax_collector(cid)` / `world.set_tax_collector(cid,v)` | `GetTaxCollectorEfficiency` / `SetTaxCollectorEfficiency` | `world.tax_collector(0)` |
| `world.wall_repair(cid)` | `GetCityWallRepairCost` | `world.wall_repair(0)` |
| `world.town_hall(cid)` / `world.set_town_hall(cid,v)` | `GetTownHallLevel` / `SetTownHallLevel` | `world.town_hall(0)` |
| `world.church_level(cid)` / `world.set_church_level(cid,v)` | `GetChurchLevel` / `SetChurchLevel` | `world.church_level(0)` |
| `world.market_level(cid)` / `world.set_market_level(cid,v)` | `GetMarketLevel` / `SetMarketLevel` | `world.market_level(0)` |
| `world.tavern_level(cid)` / `world.set_tavern_level(cid,v)` | `GetTavernLevel` / `SetTavernLevel` | `world.tavern_level(0)` |
| `world.library(cid)` / `world.set_library(cid,v)` | `GetLibraryLevel` / `SetLibraryLevel` | `world.library(0)` |
| `world.school(cid)` / `world.set_school(cid,v)` | `GetSchoolLevel` / `SetSchoolLevel` | `world.school(0)` |
| `world.dock(cid)` / `world.set_dock(cid,v)` | `GetDockLevel` / `SetDockLevel` | `world.dock(0)` |
| `world.armory(cid)` / `world.set_armory(cid,v)` | `GetArmoryLevel` / `SetArmoryLevel` | `world.armory(0)` |
| `world.warehouse(cid)` / `world.set_warehouse(cid,v)` | `GetWarehouseLevel` / `SetWarehouseLevel` | `world.warehouse(0)` |
| `world.mine(cid)` / `world.set_mine(cid,v)` | `GetMineLevel` / `SetMineLevel` | `world.mine(0)` |
| `world.garrison_level(cid)` / `world.set_garrison_level(cid,v)` | `GetGarrisonLevel` / `SetGarrisonLevel` | `world.garrison_level(0)` |
| `world.bathhouse_level(cid)` / `world.set_bathhouse_level(cid,v)` | `GetBathhouseLevel` / `SetBathhouseLevel` | `world.bathhouse_level(0)` |
| `world.harbor_master(cid)` / `world.set_harbor_master(cid,v)` | `GetHarborMasterLevel` / `SetHarborMasterLevel` | `world.harbor_master(0)` |
| `world.guardhouse(cid)` / `world.set_guardhouse(cid,v)` | `GetGuardhouseLevel` / `SetGuardhouseLevel` | `world.guardhouse(0)` |
| `world.courthouse(cid)` / `world.set_courthouse(cid,v)` | `GetCourthouseLevel` / `SetCourthouseLevel` | `world.courthouse(0)` |
| `world.univ_hall(cid)` / `world.set_univ_hall(cid,v)` | `GetUniversityHallLevel` / `SetUniversityHallLevel` | `world.univ_hall(0)` |
| `world.castle(cid)` / `world.set_castle(cid,v)` | `GetCastleLevel` / `SetCastleLevel` | `world.castle(0)` |
| `world.cathedral_level(cid)` / `world.set_cathedral_level(cid,v)` | `GetCathedralLevel` / `SetCathedralLevel` | `world.cathedral_level(0)` |
| `world.monastery_level(cid)` / `world.set_monastery_level(cid,v)` | `GetMonasteryLevel` / `SetMonasteryLevel` | `world.monastery_level(0)` |
| `world.harbor_level2(cid)` / `world.set_harbor_level2(cid,v)` | `GetHarborLevel` / `SetHarborLevel` | `world.harbor_level2(0)` |
| `world.barracks(cid)` / `world.set_barracks(cid,v)` | `GetBarracksLevel` / `SetBarracksLevel` | `world.barracks(0)` |
| `world.stables(cid)` / `world.set_stables(cid,v)` | `GetStablesLevel` / `SetStablesLevel` | `world.stables(0)` |
| `world.gates(cid)` / `world.set_gates(cid,v)` | `GetGatesLevel` / `SetGatesLevel` | `world.gates(0)` |
| `world.sentry(cid)` / `world.set_sentry(cid,v)` | `GetSentryTowerLevel` / `SetSentryTowerLevel` | `world.sentry(0)` |
| `world.well(cid)` / `world.set_well(cid,v)` | `GetWellLevel` / `SetWellLevel` | `world.well(0)` |
| `world.bridge(cid)` / `world.set_bridge(cid,v)` | `GetBridgeLevel` / `SetBridgeLevel` | `world.bridge(0)` |
| `world.wall_level(cid)` / `world.set_wall_level(cid,v)` | `GetWallLevel` / `SetWallLevel` | `world.wall_level(0)` |
| `world.tower(cid)` / `world.set_tower(cid,v)` | `GetTowerLevel` / `SetTowerLevel` | `world.tower(0)` |
| `world.forum(cid)` / `world.set_forum(cid,v)` | `GetForumLevel` / `SetForumLevel` | `world.forum(0)` |
| `world.granary_level(cid)` / `world.set_granary_level(cid,v)` | `GetGranaryLevel` / `SetGranaryLevel` | `world.granary_level(0)` |
| `world.prison(cid)` / `world.set_prison(cid,v)` | `GetPrisonLevel` / `SetPrisonLevel` | `world.prison(0)` |
| `world.harbor_dock(cid)` / `world.set_harbor_dock(cid,v)` | `GetHarborDockLevel` / `SetHarborDockLevel` | `world.harbor_dock(0)` |
| `world.guild_house2(cid)` / `world.set_guild_house2(cid,v)` | `GetGuildHouseLevel` / `SetGuildHouseLevel` | `world.guild_house2(0)` |
| `world.house(cid)` / `world.set_house(cid,v)` | `GetHouseLevel` / `SetHouseLevel` | `world.house(0)` |
| `world.chapel(cid)` / `world.set_chapel(cid,v)` | `GetChapelLevel` / `SetChapelLevel` | `world.chapel(0)` |
| `world.hospital_level(cid)` / `world.set_hospital_level(cid,v)` | `GetHospitalLevel` / `SetHospitalLevel` | `world.hospital_level(0)` |
| `world.brothel(cid)` / `world.set_brothel(cid,v)` | `GetBrothelLevel` / `SetBrothelLevel` | `world.brothel(0)` |
| `world.harbor_walls(cid)` / `world.set_harbor_walls(cid,v)` | `GetHarborWallsLevel` / `SetHarborWallsLevel` | `world.harbor_walls(0)` |
| `world.schoolhouse(cid)` / `world.set_schoolhouse(cid,v)` | `GetSchoolhouseLevel` / `SetSchoolhouseLevel` | `world.schoolhouse(0)` |
| `world.library_hall(cid)` / `world.set_library_hall(cid,v)` | `GetLibraryHallLevel` / `SetLibraryHallLevel` | `world.library_hall(0)` |
| `world.barber_level(cid)` / `world.set_barber_level(cid,v)` | `GetBarberLevel` / `SetBarberLevel` | `world.barber_level(0)` |
| `world.contor(cid)` / `world.set_contor(cid,v)` | `GetContorLevel` / `SetContorLevel` | `world.contor(0)` |
| `world.dice_house(cid)` / `world.set_dice_house(cid,v)` | `GetDiceHouseLevel` / `SetDiceHouseLevel` | `world.dice_house(0)` |
| `world.thieves(cid)` / `world.set_thieves(cid,v)` | `GetThievesGuildLevel` / `SetThievesGuildLevel` | `world.thieves(0)` |
| `world.ropemaker_workshop(cid)` / `world.set_ropemaker_workshop(cid,v)` | `GetRopemakerWorkshopLevel` / `SetRopemakerWorkshopLevel` | `world.ropemaker_workshop(0)` |
| `world.tannery(cid)` / `world.set_tannery(cid,v)` | `GetTanneryLevel` / `SetTanneryLevel` | `world.tannery(0)` |
| `world.weaving_mill(cid)` / `world.set_weaving_mill(cid,v)` | `GetWeavingMillLevel` / `SetWeavingMillLevel` | `world.weaving_mill(0)` |
| `world.mint(cid)` / `world.set_mint(cid,v)` | `GetMintLevel` / `SetMintLevel` | `world.mint(0)` |
| `world.herb_garden(cid)` / `world.set_herb_garden(cid,v)` | `GetHerbGardenLevel` / `SetHerbGardenLevel` | `world.herb_garden(0)` |
| `world.vineyard(cid)` / `world.set_vineyard(cid,v)` | `GetVineyardLevel` / `SetVineyardLevel` | `world.vineyard(0)` |
| `world.pottery(cid)` / `world.set_pottery(cid,v)` | `GetPotteryLevel` / `SetPotteryLevel` | `world.pottery(0)` |
| `world.tailor(cid)` / `world.set_tailor(cid,v)` | `GetTailorLevel` / `SetTailorLevel` | `world.tailor(0)` |
| `world.apothecary_level(cid)` / `world.set_apothecary_level(cid,v)` | `GetApothecaryLevel` / `SetApothecaryLevel` | `world.apothecary_level(0)` |
| `world.goldsmith_level(cid)` / `world.set_goldsmith_level(cid,v)` | `GetGoldsmithLevel` / `SetGoldsmithLevel` | `world.goldsmith_level(0)` |
| `world.jeweler_level(cid)` / `world.set_jeweler_level(cid,v)` | `GetJewelerLevel` / `SetJewelerLevel` | `world.jeweler_level(0)` |
| `world.perfumer_level(cid)` / `world.set_perfumer_level(cid,v)` | `GetPerfumerLevel` / `SetPerfumerLevel` | `world.perfumer_level(0)` |
| `world.soapmaker_level(cid)` / `world.set_soapmaker_level(cid,v)` | `GetSoapmakerLevel` / `SetSoapmakerLevel` | `world.soapmaker_level(0)` |
| `world.candlemaker_level(cid)` / `world.set_candlemaker_level(cid,v)` | `GetCandlemakerLevel` / `SetCandlemakerLevel` | `world.candlemaker_level(0)` |
| `world.papermill_level(cid)` / `world.set_papermill_level(cid,v)` | `GetPapermillLevel` / `SetPapermillLevel` | `world.papermill_level(0)` |
| `world.printing_house(cid)` / `world.set_printing_house(cid,v)` | `GetPrintingHouseLevel` / `SetPrintingHouseLevel` | `world.printing_house(0)` |
| `world.toolmaker_level(cid)` / `world.set_toolmaker_level(cid,v)` | `GetToolmakerLevel` / `SetToolmakerLevel` | `world.toolmaker_level(0)` |
| `world.charcoal_level(cid)` / `world.set_charcoal_level(cid,v)` | `GetCharcoalLevel` / `SetCharcoalLevel` | `world.charcoal_level(0)` |
| `world.furrier_level(cid)` / `world.set_furrier_level(cid,v)` | `GetFurrierLevel` / `SetFurrierLevel` | `world.furrier_level(0)` |
| `world.dyer_level(cid)` / `world.set_dyer_level(cid,v)` | `GetDyerLevel` / `SetDyerLevel` | `world.dyer_level(0)` |
| `world.saddler_level(cid)` / `world.set_saddler_level(cid,v)` | `GetSaddlerLevel` / `SetSaddlerLevel` | `world.saddler_level(0)` |
| `world.armorer_level(cid)` / `world.set_armorer_level(cid,v)` | `GetArmorerLevel` / `SetArmorerLevel` | `world.armorer_level(0)` |
| `world.bowyer_level(cid)` / `world.set_bowyer_level(cid,v)` | `GetBowyerLevel` / `SetBowyerLevel` | `world.bowyer_level(0)` |
| `world.cartwright_level(cid)` / `world.set_cartwright_level(cid,v)` | `GetCartwrightLevel` / `SetCartwrightLevel` | `world.cartwright_level(0)` |
| `world.carpenter_level(cid)` / `world.set_carpenter_level(cid,v)` | `GetCarpenterLevel` / `SetCarpenterLevel` | `world.carpenter_level(0)` |
| `world.ropemaker_level(cid)` / `world.set_ropemaker_level(cid,v)` | `GetRopemakerLevel2` / `SetRopemakerLevel2` | `world.ropemaker_level(0)` |
| `world.cooper_level(cid)` / `world.set_cooper_level(cid,v)` | `GetCooperLevel` / `SetCooperLevel` | `world.cooper_level(0)` |
| `world.spinner_level(cid)` / `world.set_spinner_level(cid,v)` | `GetSpinnerLevel` / `SetSpinnerLevel` | `world.spinner_level(0)` |
| `world.turner_level(cid)` / `world.set_turner_level(cid,v)` | `GetTurnerLevel` / `SetTurnerLevel` | `world.turner_level(0)` |
| `world.stonecutter_level(cid)` / `world.set_stonecutter_level(cid,v)` | `GetStonecutterLevel` / `SetStonecutterLevel` | `world.stonecutter_level(0)` |
| `world.cobbler_level(cid)` / `world.set_cobbler_level(cid,v)` | `GetCobblerLevel` / `SetCobblerLevel` | `world.cobbler_level(0)` |
| `world.butcher_level(cid)` / `world.set_butcher_level(cid,v)` | `GetButcherLevel` / `SetButcherLevel` | `world.butcher_level(0)` |
| `world.baker_level(cid)` / `world.set_baker_level(cid,v)` | `GetBakerLevel` / `SetBakerLevel` | `world.baker_level(0)` |
| `world.shepherd_level(cid)` / `world.set_shepherd_level(cid,v)` | `GetShepherdLevel` / `SetShepherdLevel` | `world.shepherd_level(0)` |
| `world.dairy_level(cid)` / `world.set_dairy_level(cid,v)` | `GetDairyLevel` / `SetDairyLevel` | `world.dairy_level(0)` |
| `world.brewmaster_level(cid)` / `world.set_brewmaster_level(cid,v)` | `GetBrewmasterLevel` / `SetBrewmasterLevel` | `world.brewmaster_level(0)` |
| `world.miller_level(cid)` / `world.set_miller_level(cid,v)` | `GetMillerLevel` / `SetMillerLevel` | `world.miller_level(0)` |
| `world.fishery_level(cid)` / `world.set_fishery_level(cid,v)` | `GetFisheryLevel` / `SetFisheryLevel` | `world.fishery_level(0)` |
| `world.chandler_level(cid)` / `world.set_chandler_level(cid,v)` | `GetChandlerLevel` / `SetChandlerLevel` | `world.chandler_level(0)` |
| `world.goldbeater_level(cid)` / `world.set_goldbeater_level(cid,v)` | `GetGoldbeaterLevel` / `SetGoldbeaterLevel` | `world.goldbeater_level(0)` |
| `world.potter_level(cid)` / `world.set_potter_level(cid,v)` | `GetPotterLevel` / `SetPotterLevel` | `world.potter_level(0)` |
| `world.fowler_level(cid)` / `world.set_fowler_level(cid,v)` | `GetFowlerLevel` / `SetFowlerLevel` | `world.fowler_level(0)` |
| `world.vintner_level(cid)` / `world.set_vintner_level(cid,v)` | `GetVintnerLevel` / `SetVintnerLevel` | `world.vintner_level(0)` |
| `world.distiller_level(cid)` / `world.set_distiller_level(cid,v)` | `GetDistillerLevel` / `SetDistillerLevel` | `world.distiller_level(0)` |
| `world.cook_level(cid)` / `world.set_cook_level(cid,v)` | `GetCookLevel` / `SetCookLevel` | `world.cook_level(0)` |
| `world.brickmaker_level(cid)` / `world.set_brickmaker_level(cid,v)` | `GetBrickmakerLevel` / `SetBrickmakerLevel` | `world.brickmaker_level(0)` |
| `world.tavern_level2(cid)` / `world.set_tavern_level2(cid,v)` | `GetTavernLevel2` / `SetTavernLevel2` | `world.tavern_level2(0)` |
| `world.mill_level(cid)` / `world.set_mill_level(cid,v)` | `GetMillLevel` / `SetMillLevel` | `world.mill_level(0)` |
| `world.brewery_tavern(cid)` / `world.set_brewery_tavern(cid,v)` | `GetBreweryTavernLevel` / `SetBreweryTavernLevel` | `world.brewery_tavern(0)` |
| `world.smith_level(cid)` / `world.set_smith_level(cid,v)` | `GetSmithLevel` / `SetSmithLevel` | `world.smith_level(0)` |
| `world.carpenters(cid)` / `world.set_carpenters(cid,v)` | `GetCarpentersLevel` / `SetCarpentersLevel` | `world.carpenters(0)` |
| `world.tailor_workshop(cid)` / `world.set_tailor_workshop(cid,v)` | `GetTailorWorkshopLevel` / `SetTailorWorkshopLevel` | `world.tailor_workshop(0)` |
| `world.joiner_workshop(cid)` / `world.set_joiner_workshop(cid,v)` | `GetJoinerWorkshopLevel` / `SetJoinerWorkshopLevel` | `world.joiner_workshop(0)` |
| `world.carter_workshop(cid)` / `world.set_carter_workshop(cid,v)` | `GetCarterWorkshopLevel` / `SetCarterWorkshopLevel` | `world.carter_workshop(0)` |
| `world.mining_workshop(cid)` / `world.set_mining_workshop(cid,v)` | `GetMiningWorkshopLevel` / `SetMiningWorkshopLevel` | `world.mining_workshop(0)` |
| `world.logging_workshop(cid)` / `world.set_logging_workshop(cid,v)` | `GetLoggingWorkshopLevel` / `SetLoggingWorkshopLevel` | `world.logging_workshop(0)` |
| `world.inn_level(cid)` / `world.set_inn_level(cid,v)` | `GetInnLevel` / `SetInnLevel` | `world.inn_level(0)` |
| `world.robber_camp(cid)` / `world.set_robber_camp(cid,v)` | `GetRobberCampLevel` / `SetRobberCampLevel` | `world.robber_camp(0)` |
| `world.joiner_ws2(cid)` / `world.set_joiner_ws2(cid,v)` | `GetJoinerWorkshopLevel2` / `SetJoinerWorkshopLevel2` | `world.joiner_ws2(0)` |
| `world.carter_ws2(cid)` / `world.set_carter_ws2(cid,v)` | `GetCarterWorkshopLevel2` / `SetCarterWorkshopLevel2` | `world.carter_ws2(0)` |
| `world.toll_gate_level(cid)` / `world.set_toll_gate_level(cid,v)` | `GetTollGateLevel` / `SetTollGateLevel` | `world.toll_gate_level(0)` |
| `world.road_level(cid)` / `world.set_road_level(cid,v)` | `GetRoadLevel` / `SetRoadLevel` | `world.road_level(0)` |
| `world.toll_gate_tax(cid)` / `world.set_toll_gate_tax(cid,v)` | `GetTollGateTaxRate` / `SetTollGateTaxRate` | `world.toll_gate_tax(0)` |
| `world.bridge_cost(cid)` | `GetBridgeConstructionCost` | `world.bridge_cost(0)` |
| `world.dock_tax(cid)` / `world.set_dock_tax(cid,v)` | `GetDockTaxRate` / `SetDockTaxRate` | `world.dock_tax(0)` |
| `world.harbor_walls_tax(cid)` / `world.set_harbor_walls_tax(cid,v)` | `GetHarborWallsTaxRate` / `SetHarborWallsTaxRate` | `world.harbor_walls_tax(0)` |
| `world.forum_tax(cid)` / `world.set_forum_tax(cid,v)` | `GetForumTaxRate` / `SetForumTaxRate` | `world.forum_tax(0)` |
| `world.granary_tax(cid)` / `world.set_granary_tax(cid,v)` | `GetGranaryTaxRate` / `SetGranaryTaxRate` | `world.granary_tax(0)` |
| `world.guild_house_tax(cid)` / `world.set_guild_house_tax(cid,v)` | `GetGuildHouseTaxRate` / `SetGuildHouseTaxRate` | `world.guild_house_tax(0)` |
| `world.house_tax(cid)` / `world.set_house_tax(cid,v)` | `GetHouseTaxRate` / `SetHouseTaxRate` | `world.house_tax(0)` |
| `world.chapel_tax(cid)` / `world.set_chapel_tax(cid,v)` | `GetChapelTaxRate` / `SetChapelTaxRate` | `world.chapel_tax(0)` |
| `world.hospital_tax(cid)` / `world.set_hospital_tax(cid,v)` | `GetHospitalTaxRate` / `SetHospitalTaxRate` | `world.hospital_tax(0)` |
| `world.harbor_walls2(cid)` / `world.set_harbor_walls2(cid,v)` | `GetHarborWallsLevel2` / `SetHarborWallsLevel2` | `world.harbor_walls2(0)` |
| `world.schoolhouse2(cid)` / `world.set_schoolhouse2(cid,v)` | `GetSchoolhouseLevel2` / `SetSchoolhouseLevel2` | `world.schoolhouse2(0)` |
| `world.library_hall2(cid)` / `world.set_library_hall2(cid,v)` | `GetLibraryHallLevel2` / `SetLibraryHallLevel2` | `world.library_hall2(0)` |
| `world.brothel_tax(cid)` / `world.set_brothel_tax(cid,v)` | `GetBrothelTaxRate` / `SetBrothelTaxRate` | `world.brothel_tax(0)` |
| `world.harbor_walls_tax2(cid)` / `world.set_harbor_walls_tax2(cid,v)` | `GetHarborWallsTaxRate2` / `SetHarborWallsTaxRate2` | `world.harbor_walls_tax2(0)` |
| `world.schoolhouse_tax(cid)` / `world.set_schoolhouse_tax(cid,v)` | `GetSchoolhouseTaxRate` / `SetSchoolhouseTaxRate` | `world.schoolhouse_tax(0)` |
| `world.library_hall_tax(cid)` / `world.set_library_hall_tax(cid,v)` | `GetLibraryHallTaxRate` / `SetLibraryHallTaxRate` | `world.library_hall_tax(0)` |
| `world.barber_tax(cid)` / `world.set_barber_tax(cid,v)` | `GetBarberTaxRate` / `SetBarberTaxRate` | `world.barber_tax(0)` |
| `world.schoolhouse_tax2(cid)` / `world.set_schoolhouse_tax2(cid,v)` | `GetSchoolhouseTaxRate2` / `SetSchoolhouseTaxRate2` | `world.schoolhouse_tax2(0)` |
| `world.library_hall_tax2(cid)` / `world.set_library_hall_tax2(cid,v)` | `GetLibraryHallTaxRate2` / `SetLibraryHallTaxRate2` | `world.library_hall_tax2(0)` |
| `world.brothel_tax2(cid)` / `world.set_brothel_tax2(cid,v)` | `GetBrothelTaxRate2` / `SetBrothelTaxRate2` | `world.brothel_tax2(0)` |
| `world.contor_tax2(cid)` / `world.set_contor_tax2(cid,v)` | `GetContorTaxRate2` / `SetContorTaxRate2` | `world.contor_tax2(0)` |
| `world.dice_house_tax2(cid)` / `world.set_dice_house_tax2(cid,v)` | `GetDiceHouseTaxRate2` / `SetDiceHouseTaxRate2` | `world.dice_house_tax2(0)` |
| `world.thieves_guild_tax2(cid)` / `world.set_thieves_guild_tax2(cid,v)` | `GetThievesGuildTaxRate2` / `SetThievesGuildTaxRate2` | `world.thieves_guild_tax2(0)` |
| `world.harbor_walls_tax4(cid)` / `world.set_harbor_walls_tax4(cid,v)` | `GetHarborWallsTaxRate4` / `SetHarborWallsTaxRate4` | `world.harbor_walls_tax4(0)` |
| `world.ropemaker_ws_tax(cid)` / `world.set_ropemaker_ws_tax(cid,v)` | `GetRopemakerWorkshopTaxRate` / `SetRopemakerWorkshopTaxRate` | `world.ropemaker_ws_tax(0)` |
| `world.tannery_tax(cid)` / `world.set_tannery_tax(cid,v)` | `GetTanneryTaxRate` / `SetTanneryTaxRate` | `world.tannery_tax(0)` |
| `world.weaving_tax(cid)` / `world.set_weaving_tax(cid,v)` | `GetWeavingMillTaxRate` / `SetWeavingMillTaxRate` | `world.weaving_tax(0)` |
| `world.mint_tax(cid)` / `world.set_mint_tax(cid,v)` | `GetMintTaxRate` / `SetMintTaxRate` | `world.mint_tax(0)` |
| `world.herb_garden_tax(cid)` / `world.set_herb_garden_tax(cid,v)` | `GetHerbGardenTaxRate` / `SetHerbGardenTaxRate` | `world.herb_garden_tax(0)` |
| `world.vineyard_tax(cid)` / `world.set_vineyard_tax(cid,v)` | `GetVineyardTaxRate` / `SetVineyardTaxRate` | `world.vineyard_tax(0)` |
| `world.pottery_tax(cid)` / `world.set_pottery_tax(cid,v)` | `GetPotteryTaxRate` / `SetPotteryTaxRate` | `world.pottery_tax(0)` |
| `world.tailor_tax(cid)` / `world.set_tailor_tax(cid,v)` | `GetTailorTaxRate` / `SetTailorTaxRate` | `world.tailor_tax(0)` |
| `world.tavern_tax(cid)` / `world.set_tavern_tax(cid,v)` | `GetTavernTaxRate` / `SetTavernTaxRate` | `world.tavern_tax(0)` |
| `world.bathhouse_tax(cid)` / `world.set_bathhouse_tax(cid,v)` | `GetBathhouseTaxRate` / `SetBathhouseTaxRate` | `world.bathhouse_tax(0)` |
| `world.church_level_tax(cid)` / `world.set_church_level_tax(cid,v)` | `GetChurchLevelTaxRate` / `SetChurchLevelTaxRate` | `world.church_level_tax(0)` |
| `world.contor_level_tax(cid)` / `world.set_contor_level_tax(cid,v)` | `GetContorLevelTaxRate` / `SetContorLevelTaxRate` | `world.contor_level_tax(0)` |
| `world.dice_house_level_tax(cid)` / `world.set_dice_house_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate` / `SetDiceHouseLevelTaxRate` | `world.dice_house_level_tax(0)` |
| `world.thieves_guild_level_tax(cid)` / `world.set_thieves_guild_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate` / `SetThievesGuildLevelTaxRate` | `world.thieves_guild_level_tax(0)` |
| `world.ropemaker_level_tax(cid)` / `world.set_ropemaker_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate` / `SetRopemakerWorkshopLevelTaxRate` | `world.ropemaker_level_tax(0)` |
| `world.tannery_level_tax(cid)` / `world.set_tannery_level_tax(cid,v)` | `GetTanneryLevelTaxRate` / `SetTanneryLevelTaxRate` | `world.tannery_level_tax(0)` |
| `world.weaving_level_tax(cid)` / `world.set_weaving_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate` / `SetWeavingMillLevelTaxRate` | `world.weaving_level_tax(0)` |
| `world.mint_level_tax(cid)` / `world.set_mint_level_tax(cid,v)` | `GetMintLevelTaxRate` / `SetMintLevelTaxRate` | `world.mint_level_tax(0)` |
| `world.herb_garden_level_tax(cid)` / `world.set_herb_garden_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate` / `SetHerbGardenLevelTaxRate` | `world.herb_garden_level_tax(0)` |
| `world.vineyard_level_tax(cid)` / `world.set_vineyard_level_tax(cid,v)` | `GetVineyardLevelTaxRate` / `SetVineyardLevelTaxRate` | `world.vineyard_level_tax(0)` |
| `world.pottery_level_tax(cid)` / `world.set_pottery_level_tax(cid,v)` | `GetPotteryLevelTaxRate` / `SetPotteryLevelTaxRate` | `world.pottery_level_tax(0)` |
| `world.tailor_level_tax(cid)` / `world.set_tailor_level_tax(cid,v)` | `GetTailorLevelTaxRate` / `SetTailorLevelTaxRate` | `world.tailor_level_tax(0)` |
| `world.tavern_level_tax(cid)` / `world.set_tavern_level_tax(cid,v)` | `GetTavernLevelTaxRate` / `SetTavernLevelTaxRate` | `world.tavern_level_tax(0)` |
| `world.apothecary_level_tax(cid)` / `world.set_apothecary_level_tax(cid,v)` | `GetApothecaryLevelTaxRate` / `SetApothecaryLevelTaxRate` | `world.apothecary_level_tax(0)` |
| `world.goldsmith_level_tax(cid)` / `world.set_goldsmith_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate` / `SetGoldsmithLevelTaxRate` | `world.goldsmith_level_tax(0)` |
| `world.jeweler_level_tax(cid)` / `world.set_jeweler_level_tax(cid,v)` | `GetJewelerLevelTaxRate` / `SetJewelerLevelTaxRate` | `world.jeweler_level_tax(0)` |
| `world.perfumer_level_tax(cid)` / `world.set_perfumer_level_tax(cid,v)` | `GetPerfumerLevelTaxRate` / `SetPerfumerLevelTaxRate` | `world.perfumer_level_tax(0)` |
| `world.soapmaker_level_tax(cid)` / `world.set_soapmaker_level_tax(cid,v)` | `GetSoapmakerLevelTaxRate` / `SetSoapmakerLevelTaxRate` | `world.soapmaker_level_tax(0)` |
| `world.candlemaker_level_tax(cid)` / `world.set_candlemaker_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate` / `SetCandlemakerLevelTaxRate` | `world.candlemaker_level_tax(0)` |
| `world.papermill_level_tax(cid)` / `world.set_papermill_level_tax(cid,v)` | `GetPapermillLevelTaxRate` / `SetPapermillLevelTaxRate` | `world.papermill_level_tax(0)` |
| `world.printing_level_tax(cid)` / `world.set_printing_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate` / `SetPrintingHouseLevelTaxRate` | `world.printing_level_tax(0)` |
| `world.toolmaker_level_tax(cid)` / `world.set_toolmaker_level_tax(cid,v)` | `GetToolmakerLevelTaxRate` / `SetToolmakerLevelTaxRate` | `world.toolmaker_level_tax(0)` |
| `world.charcoal_level_tax(cid)` / `world.set_charcoal_level_tax(cid,v)` | `GetCharcoalLevelTaxRate` / `SetCharcoalLevelTaxRate` | `world.charcoal_level_tax(0)` |
| `world.furrier_level_tax(cid)` / `world.set_furrier_level_tax(cid,v)` | `GetFurrierLevelTaxRate` / `SetFurrierLevelTaxRate` | `world.furrier_level_tax(0)` |
| `world.dyer_level_tax(cid)` / `world.set_dyer_level_tax(cid,v)` | `GetDyerLevelTaxRate` / `SetDyerLevelTaxRate` | `world.dyer_level_tax(0)` |
| `world.saddler_level_tax(cid)` / `world.set_saddler_level_tax(cid,v)` | `GetSaddlerLevelTaxRate` / `SetSaddlerLevelTaxRate` | `world.saddler_level_tax(0)` |
| `world.armorer_level_tax(cid)` / `world.set_armorer_level_tax(cid,v)` | `GetArmorerLevelTaxRate` / `SetArmorerLevelTaxRate` | `world.armorer_level_tax(0)` |
| `world.bowyer_level_tax(cid)` / `world.set_bowyer_level_tax(cid,v)` | `GetBowyerLevelTaxRate` / `SetBowyerLevelTaxRate` | `world.bowyer_level_tax(0)` |
| `world.cartwright_level_tax(cid)` / `world.set_cartwright_level_tax(cid,v)` | `GetCartwrightLevelTaxRate` / `SetCartwrightLevelTaxRate` | `world.cartwright_level_tax(0)` |
| `world.carpenter_level_tax(cid)` / `world.set_carpenter_level_tax(cid,v)` | `GetCarpenterLevelTaxRate` / `SetCarpenterLevelTaxRate` | `world.carpenter_level_tax(0)` |
| `world.ropemaker_level_tax(cid)` / `world.set_ropemaker_level_tax(cid,v)` | `GetRopemakerLevelTaxRate` / `SetRopemakerLevelTaxRate` | `world.ropemaker_level_tax(0)` |
| `world.cooper_level_tax(cid)` / `world.set_cooper_level_tax(cid,v)` | `GetCooperLevelTaxRate` / `SetCooperLevelTaxRate` | `world.cooper_level_tax(0)` |
| `world.spinner_level_tax(cid)` / `world.set_spinner_level_tax(cid,v)` | `GetSpinnerLevelTaxRate` / `SetSpinnerLevelTaxRate` | `world.spinner_level_tax(0)` |
| `world.turner_level_tax(cid)` / `world.set_turner_level_tax(cid,v)` | `GetTurnerLevelTaxRate` / `SetTurnerLevelTaxRate` | `world.turner_level_tax(0)` |
| `world.stonecutter_level_tax(cid)` / `world.set_stonecutter_level_tax(cid,v)` | `GetStonecutterLevelTaxRate` / `SetStonecutterLevelTaxRate` | `world.stonecutter_level_tax(0)` |
| `world.cobbler_level_tax(cid)` / `world.set_cobbler_level_tax(cid,v)` | `GetCobblerLevelTaxRate` / `SetCobblerLevelTaxRate` | `world.cobbler_level_tax(0)` |
| `world.butcher_level_tax(cid)` / `world.set_butcher_level_tax(cid,v)` | `GetButcherLevelTaxRate` / `SetButcherLevelTaxRate` | `world.butcher_level_tax(0)` |
| `world.baker_level_tax(cid)` / `world.set_baker_level_tax(cid,v)` | `GetBakerLevelTaxRate` / `SetBakerLevelTaxRate` | `world.baker_level_tax(0)` |
| `world.shepherd_level_tax(cid)` / `world.set_shepherd_level_tax(cid,v)` | `GetShepherdLevelTaxRate` / `SetShepherdLevelTaxRate` | `world.shepherd_level_tax(0)` |
| `world.dairy_level_tax(cid)` / `world.set_dairy_level_tax(cid,v)` | `GetDairyLevelTaxRate` / `SetDairyLevelTaxRate` | `world.dairy_level_tax(0)` |
| `world.brewmaster_level_tax(cid)` / `world.set_brewmaster_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate` / `SetBrewmasterLevelTaxRate` | `world.brewmaster_level_tax(0)` |
| `world.miller_level_tax(cid)` / `world.set_miller_level_tax(cid,v)` | `GetMillerLevelTaxRate` / `SetMillerLevelTaxRate` | `world.miller_level_tax(0)` |
| `world.fishery_level_tax(cid)` / `world.set_fishery_level_tax(cid,v)` | `GetFisheryLevelTaxRate` / `SetFisheryLevelTaxRate` | `world.fishery_level_tax(0)` |
| `world.chandler_level_tax(cid)` / `world.set_chandler_level_tax(cid,v)` | `GetChandlerLevelTaxRate` / `SetChandlerLevelTaxRate` | `world.chandler_level_tax(0)` |
| `world.goldbeater_level_tax(cid)` / `world.set_goldbeater_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate` / `SetGoldbeaterLevelTaxRate` | `world.goldbeater_level_tax(0)` |
| `world.potter_level_tax(cid)` / `world.set_potter_level_tax(cid,v)` | `GetPotterLevelTaxRate` / `SetPotterLevelTaxRate` | `world.potter_level_tax(0)` |
| `world.fowler_level_tax(cid)` / `world.set_fowler_level_tax(cid,v)` | `GetFowlerLevelTaxRate` / `SetFowlerLevelTaxRate` | `world.fowler_level_tax(0)` |
| `world.vintner_level_tax(cid)` / `world.set_vintner_level_tax(cid,v)` | `GetVintnerLevelTaxRate` / `SetVintnerLevelTaxRate` | `world.vintner_level_tax(0)` |
| `world.distiller_level_tax(cid)` / `world.set_distiller_level_tax(cid,v)` | `GetDistillerLevelTaxRate` / `SetDistillerLevelTaxRate` | `world.distiller_level_tax(0)` |
| `world.cook_level_tax(cid)` / `world.set_cook_level_tax(cid,v)` | `GetCookLevelTaxRate` / `SetCookLevelTaxRate` | `world.cook_level_tax(0)` |
| `world.brickmaker_level_tax(cid)` / `world.set_brickmaker_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate` / `SetBrickmakerLevelTaxRate` | `world.brickmaker_level_tax(0)` |
| `world.bathhouse_level_tax(cid)` / `world.set_bathhouse_level_tax(cid,v)` | `GetBathhouseLevelTaxRate` / `SetBathhouseLevelTaxRate` | `world.bathhouse_level_tax(0)` |
| `world.barracks_level_tax(cid)` / `world.set_barracks_level_tax(cid,v)` | `GetBarracksLevelTaxRate` / `SetBarracksLevelTaxRate` | `world.barracks_level_tax(0)` |
| `world.school_level_tax(cid)` / `world.set_school_level_tax(cid,v)` | `GetSchoolLevelTaxRate` / `SetSchoolLevelTaxRate` | `world.school_level_tax(0)` |
| `world.library_level_tax(cid)` / `world.set_library_level_tax(cid,v)` | `GetLibraryLevelTaxRate` / `SetLibraryLevelTaxRate` | `world.library_level_tax(0)` |
| `world.mine_level_tax(cid)` / `world.set_mine_level_tax(cid,v)` | `GetMineLevelTaxRate` / `SetMineLevelTaxRate` | `world.mine_level_tax(0)` |
| `world.warehouse_level_tax(cid)` / `world.set_warehouse_level_tax(cid,v)` | `GetWarehouseLevelTaxRate` / `SetWarehouseLevelTaxRate` | `world.warehouse_level_tax(0)` |
| `world.garrison_level_tax(cid)` / `world.set_garrison_level_tax(cid,v)` | `GetGarrisonLevelTaxRate` / `SetGarrisonLevelTaxRate` | `world.garrison_level_tax(0)` |
| `world.monastery_level_tax(cid)` / `world.set_monastery_level_tax(cid,v)` | `GetMonasteryLevelTaxRate` / `SetMonasteryLevelTaxRate` | `world.monastery_level_tax(0)` |
| `world.cathedral_level_tax(cid)` / `world.set_cathedral_level_tax(cid,v)` | `GetCathedralLevelTaxRate` / `SetCathedralLevelTaxRate` | `world.cathedral_level_tax(0)` |
| `world.town_hall_level_tax(cid)` / `world.set_town_hall_level_tax(cid,v)` | `GetTownHallLevelTaxRate` / `SetTownHallLevelTaxRate` | `world.town_hall_level_tax(0)` |
| `world.market_level_tax(cid)` / `world.set_market_level_tax(cid,v)` | `GetMarketLevelTaxRate` / `SetMarketLevelTaxRate` | `world.market_level_tax(0)` |
| `world.harbor_level_tax(cid)` / `world.set_harbor_level_tax(cid,v)` | `GetHarborLevelTaxRate` / `SetHarborLevelTaxRate` | `world.harbor_level_tax(0)` |
| `world.guardhouse_level_tax(cid)` / `world.set_guardhouse_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate` / `SetGuardhouseLevelTaxRate` | `world.guardhouse_level_tax(0)` |
| `world.courthouse_level_tax(cid)` / `world.set_courthouse_level_tax(cid,v)` | `GetCourthouseLevelTaxRate` / `SetCourthouseLevelTaxRate` | `world.courthouse_level_tax(0)` |
| `world.univ_hall_level_tax(cid)` / `world.set_univ_hall_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate` / `SetUniversityHallLevelTaxRate` | `world.univ_hall_level_tax(0)` |
| `world.castle_level_tax(cid)` / `world.set_castle_level_tax(cid,v)` | `GetCastleLevelTaxRate` / `SetCastleLevelTaxRate` | `world.castle_level_tax(0)` |
| `world.barracks2_level_tax(cid)` / `world.set_barracks2_level_tax(cid,v)` | `GetBarracksLevelTaxRate2` / `SetBarracksLevelTaxRate2` | `world.barracks2_level_tax(0)` |
| `world.stables_level_tax(cid)` / `world.set_stables_level_tax(cid,v)` | `GetStablesLevelTaxRate` / `SetStablesLevelTaxRate` | `world.stables_level_tax(0)` |
| `world.gates_level_tax(cid)` / `world.set_gates_level_tax(cid,v)` | `GetGatesLevelTaxRate` / `SetGatesLevelTaxRate` | `world.gates_level_tax(0)` |
| `world.sentry_level_tax(cid)` / `world.set_sentry_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate` / `SetSentryTowerLevelTaxRate` | `world.sentry_level_tax(0)` |
| `world.well_level_tax(cid)` / `world.set_well_level_tax(cid,v)` | `GetWellLevelTaxRate` / `SetWellLevelTaxRate` | `world.well_level_tax(0)` |
| `world.bridge_level_tax(cid)` / `world.set_bridge_level_tax(cid,v)` | `GetBridgeLevelTaxRate` / `SetBridgeLevelTaxRate` | `world.bridge_level_tax(0)` |
| `world.wall_level_tax(cid)` / `world.set_wall_level_tax(cid,v)` | `GetWallLevelTaxRate` / `SetWallLevelTaxRate` | `world.wall_level_tax(0)` |
| `world.tower_level_tax(cid)` / `world.set_tower_level_tax(cid,v)` | `GetTowerLevelTaxRate` / `SetTowerLevelTaxRate` | `world.tower_level_tax(0)` |
| `world.forum_level_tax(cid)` / `world.set_forum_level_tax(cid,v)` | `GetForumLevelTaxRate` / `SetForumLevelTaxRate` | `world.forum_level_tax(0)` |
| `world.granary_level_tax(cid)` / `world.set_granary_level_tax(cid,v)` | `GetGranaryLevelTaxRate` / `SetGranaryLevelTaxRate` | `world.granary_level_tax(0)` |
| `world.prison_level_tax(cid)` / `world.set_prison_level_tax(cid,v)` | `GetPrisonLevelTaxRate` / `SetPrisonLevelTaxRate` | `world.prison_level_tax(0)` |
| `world.harbor_dock_level_tax(cid)` / `world.set_harbor_dock_level_tax(cid,v)` | `GetHarborDockLevelTaxRate` / `SetHarborDockLevelTaxRate` | `world.harbor_dock_level_tax(0)` |
| `world.guild_house_level_tax(cid)` / `world.set_guild_house_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate` / `SetGuildHouseLevelTaxRate` | `world.guild_house_level_tax(0)` |
| `world.house_level_tax(cid)` / `world.set_house_level_tax(cid,v)` | `GetHouseLevelTaxRate` / `SetHouseLevelTaxRate` | `world.house_level_tax(0)` |
| `world.chapel_level_tax(cid)` / `world.set_chapel_level_tax(cid,v)` | `GetChapelLevelTaxRate` / `SetChapelLevelTaxRate` | `world.chapel_level_tax(0)` |
| `world.hospital_level_tax(cid)` / `world.set_hospital_level_tax(cid,v)` | `GetHospitalLevelTaxRate` / `SetHospitalLevelTaxRate` | `world.hospital_level_tax(0)` |
| `world.brothel_level_tax(cid)` / `world.set_brothel_level_tax(cid,v)` | `GetBrothelLevelTaxRate` / `SetBrothelLevelTaxRate` | `world.brothel_level_tax(0)` |
| `world.university_level_tax(cid)` / `world.set_university_level_tax(cid,v)` | `GetUniversityLevelTaxRate` / `SetUniversityLevelTaxRate` | `world.university_level_tax(0)` |
| `world.harbor_walls_level_tax(cid)` / `world.set_harbor_walls_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate` / `SetHarborWallsLevelTaxRate` | `world.harbor_walls_level_tax(0)` |
| `world.schoolhouse_level_tax(cid)` / `world.set_schoolhouse_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate` / `SetSchoolhouseLevelTaxRate` | `world.schoolhouse_level_tax(0)` |
| `world.library_hall_level_tax(cid)` / `world.set_library_hall_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate` / `SetLibraryHallLevelTaxRate` | `world.library_hall_level_tax(0)` |
| `world.barber_level_tax(cid)` / `world.set_barber_level_tax(cid,v)` | `GetBarberLevelTaxRate` / `SetBarberLevelTaxRate` | `world.barber_level_tax(0)` |
| `world.contor2_level_tax(cid)` / `world.set_contor2_level_tax(cid,v)` | `GetContorLevelTaxRate2` / `SetContorLevelTaxRate2` | `world.contor2_level_tax(0)` |
| `world.dice_house2_level_tax(cid)` / `world.set_dice_house2_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate2` / `SetDiceHouseLevelTaxRate2` | `world.dice_house2_level_tax(0)` |
| `world.thieves2_level_tax(cid)` / `world.set_thieves2_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate2` / `SetThievesGuildLevelTaxRate2` | `world.thieves2_level_tax(0)` |
| `world.ropemaker_ws2_level_tax(cid)` / `world.set_ropemaker_ws2_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate2` / `SetRopemakerWorkshopLevelTaxRate2` | `world.ropemaker_ws2_level_tax(0)` |
| `world.tannery2_level_tax(cid)` / `world.set_tannery2_level_tax(cid,v)` | `GetTanneryLevelTaxRate2` / `SetTanneryLevelTaxRate2` | `world.tannery2_level_tax(0)` |
| `world.weaving2_level_tax(cid)` / `world.set_weaving2_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate2` / `SetWeavingMillLevelTaxRate2` | `world.weaving2_level_tax(0)` |
| `world.mint2_level_tax(cid)` / `world.set_mint2_level_tax(cid,v)` | `GetMintLevelTaxRate2` / `SetMintLevelTaxRate2` | `world.mint2_level_tax(0)` |
| `world.herb_garden2_level_tax(cid)` / `world.set_herb_garden2_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate2` / `SetHerbGardenLevelTaxRate2` | `world.herb_garden2_level_tax(0)` |
| `world.vineyard2_level_tax(cid)` / `world.set_vineyard2_level_tax(cid,v)` | `GetVineyardLevelTaxRate2` / `SetVineyardLevelTaxRate2` | `world.vineyard2_level_tax(0)` |
| `world.pottery2_level_tax(cid)` / `world.set_pottery2_level_tax(cid,v)` | `GetPotteryLevelTaxRate2` / `SetPotteryLevelTaxRate2` | `world.pottery2_level_tax(0)` |
| `world.tailor2_level_tax(cid)` / `world.set_tailor2_level_tax(cid,v)` | `GetTailorLevelTaxRate2` / `SetTailorLevelTaxRate2` | `world.tailor2_level_tax(0)` |
| `world.tavern2_level_tax(cid)` / `world.set_tavern2_level_tax(cid,v)` | `GetTavernLevelTaxRate2` / `SetTavernLevelTaxRate2` | `world.tavern2_level_tax(0)` |
| `world.apothecary2_level_tax(cid)` / `world.set_apothecary2_level_tax(cid,v)` | `GetApothecaryLevelTaxRate2` / `SetApothecaryLevelTaxRate2` | `world.apothecary2_level_tax(0)` |
| `world.goldsmith2_level_tax(cid)` / `world.set_goldsmith2_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate2` / `SetGoldsmithLevelTaxRate2` | `world.goldsmith2_level_tax(0)` |
| `world.jeweler2_level_tax(cid)` / `world.set_jeweler2_level_tax(cid,v)` | `GetJewelerLevelTaxRate2` / `SetJewelerLevelTaxRate2` | `world.jeweler2_level_tax(0)` |
| `world.perfumer2_level_tax(cid)` / `world.set_perfumer2_level_tax(cid,v)` | `GetPerfumerLevelTaxRate2` / `SetPerfumerLevelTaxRate2` | `world.perfumer2_level_tax(0)` |
| `world.soapmaker2_level_tax(cid)` / `world.set_soapmaker2_level_tax(cid,v)` | `GetSoapmakerLevelTaxRate2` / `SetSoapmakerLevelTaxRate2` | `world.soapmaker2_level_tax(0)` |
| `world.candlemaker2_level_tax(cid)` / `world.set_candlemaker2_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate2` / `SetCandlemakerLevelTaxRate2` | `world.candlemaker2_level_tax(0)` |
| `world.papermill2_level_tax(cid)` / `world.set_papermill2_level_tax(cid,v)` | `GetPapermillLevelTaxRate2` / `SetPapermillLevelTaxRate2` | `world.papermill2_level_tax(0)` |
| `world.printing2_level_tax(cid)` / `world.set_printing2_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate2` / `SetPrintingHouseLevelTaxRate2` | `world.printing2_level_tax(0)` |
| `world.toolmaker2_level_tax(cid)` / `world.set_toolmaker2_level_tax(cid,v)` | `GetToolmakerLevelTaxRate2` / `SetToolmakerLevelTaxRate2` | `world.toolmaker2_level_tax(0)` |
| `world.charcoal2_level_tax(cid)` / `world.set_charcoal2_level_tax(cid,v)` | `GetCharcoalLevelTaxRate2` / `SetCharcoalLevelTaxRate2` | `world.charcoal2_level_tax(0)` |
| `world.furrier2_level_tax(cid)` / `world.set_furrier2_level_tax(cid,v)` | `GetFurrierLevelTaxRate2` / `SetFurrierLevelTaxRate2` | `world.furrier2_level_tax(0)` |
| `world.dyer2_level_tax(cid)` / `world.set_dyer2_level_tax(cid,v)` | `GetDyerLevelTaxRate2` / `SetDyerLevelTaxRate2` | `world.dyer2_level_tax(0)` |
| `world.saddler2_level_tax(cid)` / `world.set_saddler2_level_tax(cid,v)` | `GetSaddlerLevelTaxRate2` / `SetSaddlerLevelTaxRate2` | `world.saddler2_level_tax(0)` |
| `world.armorer2_level_tax(cid)` / `world.set_armorer2_level_tax(cid,v)` | `GetArmorerLevelTaxRate2` / `SetArmorerLevelTaxRate2` | `world.armorer2_level_tax(0)` |
| `world.bowyer2_level_tax(cid)` / `world.set_bowyer2_level_tax(cid,v)` | `GetBowyerLevelTaxRate2` / `SetBowyerLevelTaxRate2` | `world.bowyer2_level_tax(0)` |
| `world.cartwright2_level_tax(cid)` / `world.set_cartwright2_level_tax(cid,v)` | `GetCartwrightLevelTaxRate2` / `SetCartwrightLevelTaxRate2` | `world.cartwright2_level_tax(0)` |
| `world.carpenter2_level_tax(cid)` / `world.set_carpenter2_level_tax(cid,v)` | `GetCarpenterLevelTaxRate2` / `SetCarpenterLevelTaxRate2` | `world.carpenter2_level_tax(0)` |
| `world.ropemaker2_level_tax(cid)` / `world.set_ropemaker2_level_tax(cid,v)` | `GetRopemakerLevelTaxRate2` / `SetRopemakerLevelTaxRate2` | `world.ropemaker2_level_tax(0)` |
| `world.cooper2_level_tax(cid)` / `world.set_cooper2_level_tax(cid,v)` | `GetCooperLevelTaxRate2` / `SetCooperLevelTaxRate2` | `world.cooper2_level_tax(0)` |
| `world.spinner2_level_tax(cid)` / `world.set_spinner2_level_tax(cid,v)` | `GetSpinnerLevelTaxRate2` / `SetSpinnerLevelTaxRate2` | `world.spinner2_level_tax(0)` |
| `world.turner2_level_tax(cid)` / `world.set_turner2_level_tax(cid,v)` | `GetTurnerLevelTaxRate2` / `SetTurnerLevelTaxRate2` | `world.turner2_level_tax(0)` |
| `world.stonecutter2_level_tax(cid)` / `world.set_stonecutter2_level_tax(cid,v)` | `GetStonecutterLevelTaxRate2` / `SetStonecutterLevelTaxRate2` | `world.stonecutter2_level_tax(0)` |
| `world.cobbler2_level_tax(cid)` / `world.set_cobbler2_level_tax(cid,v)` | `GetCobblerLevelTaxRate2` / `SetCobblerLevelTaxRate2` | `world.cobbler2_level_tax(0)` |
| `world.butcher2_level_tax(cid)` / `world.set_butcher2_level_tax(cid,v)` | `GetButcherLevelTaxRate2` / `SetButcherLevelTaxRate2` | `world.butcher2_level_tax(0)` |
| `world.baker2_level_tax(cid)` / `world.set_baker2_level_tax(cid,v)` | `GetBakerLevelTaxRate2` / `SetBakerLevelTaxRate2` | `world.baker2_level_tax(0)` |
| `world.shepherd2_level_tax(cid)` / `world.set_shepherd2_level_tax(cid,v)` | `GetShepherdLevelTaxRate2` / `SetShepherdLevelTaxRate2` | `world.shepherd2_level_tax(0)` |
| `world.dairy2_level_tax(cid)` / `world.set_dairy2_level_tax(cid,v)` | `GetDairyLevelTaxRate2` / `SetDairyLevelTaxRate2` | `world.dairy2_level_tax(0)` |
| `world.brewmaster2_level_tax(cid)` / `world.set_brewmaster2_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate2` / `SetBrewmasterLevelTaxRate2` | `world.brewmaster2_level_tax(0)` |
| `world.miller2_level_tax(cid)` / `world.set_miller2_level_tax(cid,v)` | `GetMillerLevelTaxRate2` / `SetMillerLevelTaxRate2` | `world.miller2_level_tax(0)` |
| `world.fishery2_level_tax(cid)` / `world.set_fishery2_level_tax(cid,v)` | `GetFisheryLevelTaxRate2` / `SetFisheryLevelTaxRate2` | `world.fishery2_level_tax(0)` |
| `world.chandler2_level_tax(cid)` / `world.set_chandler2_level_tax(cid,v)` | `GetChandlerLevelTaxRate2` / `SetChandlerLevelTaxRate2` | `world.chandler2_level_tax(0)` |
| `world.goldbeater2_level_tax(cid)` / `world.set_goldbeater2_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate2` / `SetGoldbeaterLevelTaxRate2` | `world.goldbeater2_level_tax(0)` |
| `world.potter2_level_tax(cid)` / `world.set_potter2_level_tax(cid,v)` | `GetPotterLevelTaxRate2` / `SetPotterLevelTaxRate2` | `world.potter2_level_tax(0)` |
| `world.fowler2_level_tax(cid)` / `world.set_fowler2_level_tax(cid,v)` | `GetFowlerLevelTaxRate2` / `SetFowlerLevelTaxRate2` | `world.fowler2_level_tax(0)` |
| `world.vintner2_level_tax(cid)` / `world.set_vintner2_level_tax(cid,v)` | `GetVintnerLevelTaxRate2` / `SetVintnerLevelTaxRate2` | `world.vintner2_level_tax(0)` |
| `world.distiller2_level_tax(cid)` / `world.set_distiller2_level_tax(cid,v)` | `GetDistillerLevelTaxRate2` / `SetDistillerLevelTaxRate2` | `world.distiller2_level_tax(0)` |
| `world.cook2_level_tax(cid)` / `world.set_cook2_level_tax(cid,v)` | `GetCookLevelTaxRate2` / `SetCookLevelTaxRate2` | `world.cook2_level_tax(0)` |
| `world.brickmaker2_level_tax(cid)` / `world.set_brickmaker2_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate2` / `SetBrickmakerLevelTaxRate2` | `world.brickmaker2_level_tax(0)` |
| `world.bathhouse2_level_tax(cid)` / `world.set_bathhouse2_level_tax(cid,v)` | `GetBathhouseLevelTaxRate2` / `SetBathhouseLevelTaxRate2` | `world.bathhouse2_level_tax(0)` |
| `world.barracks3_level_tax(cid)` / `world.set_barracks3_level_tax(cid,v)` | `GetBarracksLevelTaxRate3` / `SetBarracksLevelTaxRate3` | `world.barracks3_level_tax(0)` |
| `world.school2_level_tax(cid)` / `world.set_school2_level_tax(cid,v)` | `GetSchoolLevelTaxRate2` / `SetSchoolLevelTaxRate2` | `world.school2_level_tax(0)` |
| `world.library2_level_tax(cid)` / `world.set_library2_level_tax(cid,v)` | `GetLibraryLevelTaxRate2` / `SetLibraryLevelTaxRate2` | `world.library2_level_tax(0)` |
| `world.mine2_level_tax(cid)` / `world.set_mine2_level_tax(cid,v)` | `GetMineLevelTaxRate2` / `SetMineLevelTaxRate2` | `world.mine2_level_tax(0)` |
| `world.warehouse2_level_tax(cid)` / `world.set_warehouse2_level_tax(cid,v)` | `GetWarehouseLevelTaxRate2` / `SetWarehouseLevelTaxRate2` | `world.warehouse2_level_tax(0)` |
| `world.garrison2_level_tax(cid)` / `world.set_garrison2_level_tax(cid,v)` | `GetGarrisonLevelTaxRate2` / `SetGarrisonLevelTaxRate2` | `world.garrison2_level_tax(0)` |
| `world.monastery2_level_tax(cid)` / `world.set_monastery2_level_tax(cid,v)` | `GetMonasteryLevelTaxRate2` / `SetMonasteryLevelTaxRate2` | `world.monastery2_level_tax(0)` |
| `world.cathedral2_level_tax(cid)` / `world.set_cathedral2_level_tax(cid,v)` | `GetCathedralLevelTaxRate2` / `SetCathedralLevelTaxRate2` | `world.cathedral2_level_tax(0)` |
| `world.town_hall2_level_tax(cid)` / `world.set_town_hall2_level_tax(cid,v)` | `GetTownHallLevelTaxRate2` / `SetTownHallLevelTaxRate2` | `world.town_hall2_level_tax(0)` |
| `world.market2_level_tax(cid)` / `world.set_market2_level_tax(cid,v)` | `GetMarketLevelTaxRate2` / `SetMarketLevelTaxRate2` | `world.market2_level_tax(0)` |
| `world.harbor2_level_tax(cid)` / `world.set_harbor2_level_tax(cid,v)` | `GetHarborLevelTaxRate2` / `SetHarborLevelTaxRate2` | `world.harbor2_level_tax(0)` |
| `world.guardhouse2_level_tax(cid)` / `world.set_guardhouse2_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate2` / `SetGuardhouseLevelTaxRate2` | `world.guardhouse2_level_tax(0)` |
| `world.courthouse2_level_tax(cid)` / `world.set_courthouse2_level_tax(cid,v)` | `GetCourthouseLevelTaxRate2` / `SetCourthouseLevelTaxRate2` | `world.courthouse2_level_tax(0)` |
| `world.univ_hall2_level_tax(cid)` / `world.set_univ_hall2_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate2` / `SetUniversityHallLevelTaxRate2` | `world.univ_hall2_level_tax(0)` |
| `world.castle2_level_tax(cid)` / `world.set_castle2_level_tax(cid,v)` | `GetCastleLevelTaxRate2` / `SetCastleLevelTaxRate2` | `world.castle2_level_tax(0)` |
| `world.barracks4_level_tax(cid)` / `world.set_barracks4_level_tax(cid,v)` | `GetBarracksLevelTaxRate4` / `SetBarracksLevelTaxRate4` | `world.barracks4_level_tax(0)` |
| `world.stables2_level_tax(cid)` / `world.set_stables2_level_tax(cid,v)` | `GetStablesLevelTaxRate2` / `SetStablesLevelTaxRate2` | `world.stables2_level_tax(0)` |
| `world.gates2_level_tax(cid)` / `world.set_gates2_level_tax(cid,v)` | `GetGatesLevelTaxRate2` / `SetGatesLevelTaxRate2` | `world.gates2_level_tax(0)` |
| `world.sentry2_level_tax(cid)` / `world.set_sentry2_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate2` / `SetSentryTowerLevelTaxRate2` | `world.sentry2_level_tax(0)` |
| `world.well2_level_tax(cid)` / `world.set_well2_level_tax(cid,v)` | `GetWellLevelTaxRate2` / `SetWellLevelTaxRate2` | `world.well2_level_tax(0)` |
| `world.bridge2_level_tax(cid)` / `world.set_bridge2_level_tax(cid,v)` | `GetBridgeLevelTaxRate2` / `SetBridgeLevelTaxRate2` | `world.bridge2_level_tax(0)` |
| `world.wall2_level_tax(cid)` / `world.set_wall2_level_tax(cid,v)` | `GetWallLevelTaxRate2` / `SetWallLevelTaxRate2` | `world.wall2_level_tax(0)` |
| `world.tower2_level_tax(cid)` / `world.set_tower2_level_tax(cid,v)` | `GetTowerLevelTaxRate2` / `SetTowerLevelTaxRate2` | `world.tower2_level_tax(0)` |
| `world.forum2_level_tax(cid)` / `world.set_forum2_level_tax(cid,v)` | `GetForumLevelTaxRate2` / `SetForumLevelTaxRate2` | `world.forum2_level_tax(0)` |
| `world.granary2_level_tax(cid)` / `world.set_granary2_level_tax(cid,v)` | `GetGranaryLevelTaxRate2` / `SetGranaryLevelTaxRate2` | `world.granary2_level_tax(0)` |
| `world.prison2_level_tax(cid)` / `world.set_prison2_level_tax(cid,v)` | `GetPrisonLevelTaxRate2` / `SetPrisonLevelTaxRate2` | `world.prison2_level_tax(0)` |
| `world.harbor_dock2_level_tax(cid)` / `world.set_harbor_dock2_level_tax(cid,v)` | `GetHarborDockLevelTaxRate2` / `SetHarborDockLevelTaxRate2` | `world.harbor_dock2_level_tax(0)` |
| `world.guild_house2_level_tax(cid)` / `world.set_guild_house2_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate2` / `SetGuildHouseLevelTaxRate2` | `world.guild_house2_level_tax(0)` |
| `world.house2_level_tax(cid)` / `world.set_house2_level_tax(cid,v)` | `GetHouseLevelTaxRate2` / `SetHouseLevelTaxRate2` | `world.house2_level_tax(0)` |
| `world.chapel2_level_tax(cid)` / `world.set_chapel2_level_tax(cid,v)` | `GetChapelLevelTaxRate2` / `SetChapelLevelTaxRate2` | `world.chapel2_level_tax(0)` |
| `world.hospital2_level_tax(cid)` / `world.set_hospital2_level_tax(cid,v)` | `GetHospitalLevelTaxRate2` / `SetHospitalLevelTaxRate2` | `world.hospital2_level_tax(0)` |
| `world.brothel2_level_tax(cid)` / `world.set_brothel2_level_tax(cid,v)` | `GetBrothelLevelTaxRate2` / `SetBrothelLevelTaxRate2` | `world.brothel2_level_tax(0)` |
| `world.university2_level_tax(cid)` / `world.set_university2_level_tax(cid,v)` | `GetUniversityLevelTaxRate2` / `SetUniversityLevelTaxRate2` | `world.university2_level_tax(0)` |
| `world.harbor_walls2_level_tax(cid)` / `world.set_harbor_walls2_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate2` / `SetHarborWallsLevelTaxRate2` | `world.harbor_walls2_level_tax(0)` |
| `world.schoolhouse2_level_tax(cid)` / `world.set_schoolhouse2_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate2` / `SetSchoolhouseLevelTaxRate2` | `world.schoolhouse2_level_tax(0)` |
| `world.library_hall2_level_tax(cid)` / `world.set_library_hall2_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate2` / `SetLibraryHallLevelTaxRate2` | `world.library_hall2_level_tax(0)` |
| `world.barber2_level_tax(cid)` / `world.set_barber2_level_tax(cid,v)` | `GetBarberLevelTaxRate2` / `SetBarberLevelTaxRate2` | `world.barber2_level_tax(0)` |
| `world.contor3_level_tax(cid)` / `world.set_contor3_level_tax(cid,v)` | `GetContorLevelTaxRate3` / `SetContorLevelTaxRate3` | `world.contor3_level_tax(0)` |
| `world.dice_house3_level_tax(cid)` / `world.set_dice_house3_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate3` / `SetDiceHouseLevelTaxRate3` | `world.dice_house3_level_tax(0)` |
| `world.thieves3_level_tax(cid)` / `world.set_thieves3_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate3` / `SetThievesGuildLevelTaxRate3` | `world.thieves3_level_tax(0)` |
| `world.ropemaker_ws3_level_tax(cid)` / `world.set_ropemaker_ws3_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate3` / `SetRopemakerWorkshopLevelTaxRate3` | `world.ropemaker_ws3_level_tax(0)` |
| `world.tannery3_level_tax(cid)` / `world.set_tannery3_level_tax(cid,v)` | `GetTanneryLevelTaxRate3` / `SetTanneryLevelTaxRate3` | `world.tannery3_level_tax(0)` |
| `world.weaving3_level_tax(cid)` / `world.set_weaving3_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate3` / `SetWeavingMillLevelTaxRate3` | `world.weaving3_level_tax(0)` |
| `world.mint3_level_tax(cid)` / `world.set_mint3_level_tax(cid,v)` | `GetMintLevelTaxRate3` / `SetMintLevelTaxRate3` | `world.mint3_level_tax(0)` |
| `world.herb_garden3_level_tax(cid)` / `world.set_herb_garden3_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate3` / `SetHerbGardenLevelTaxRate3` | `world.herb_garden3_level_tax(0)` |
| `world.vineyard3_level_tax(cid)` / `world.set_vineyard3_level_tax(cid,v)` | `GetVineyardLevelTaxRate3` / `SetVineyardLevelTaxRate3` | `world.vineyard3_level_tax(0)` |
| `world.pottery3_level_tax(cid)` / `world.set_pottery3_level_tax(cid,v)` | `GetPotteryLevelTaxRate3` / `SetPotteryLevelTaxRate3` | `world.pottery3_level_tax(0)` |
| `world.tailor3_level_tax(cid)` / `world.set_tailor3_level_tax(cid,v)` | `GetTailorLevelTaxRate3` / `SetTailorLevelTaxRate3` | `world.tailor3_level_tax(0)` |
| `world.tavern3_level_tax(cid)` / `world.set_tavern3_level_tax(cid,v)` | `GetTavernLevelTaxRate3` / `SetTavernLevelTaxRate3` | `world.tavern3_level_tax(0)` |
| `world.apothecary3_level_tax(cid)` / `world.set_apothecary3_level_tax(cid,v)` | `GetApothecaryLevelTaxRate3` / `SetApothecaryLevelTaxRate3` | `world.apothecary3_level_tax(0)` |
| `world.goldsmith3_level_tax(cid)` / `world.set_goldsmith3_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate3` / `SetGoldsmithLevelTaxRate3` | `world.goldsmith3_level_tax(0)` |
| `world.jeweler3_level_tax(cid)` / `world.set_jeweler3_level_tax(cid,v)` | `GetJewelerLevelTaxRate3` / `SetJewelerLevelTaxRate3` | `world.jeweler3_level_tax(0)` |
| `world.perfumer3_level_tax(cid)` / `world.set_perfumer3_level_tax(cid,v)` | `GetPerfumerLevelTaxRate3` / `SetPerfumerLevelTaxRate3` | `world.perfumer3_level_tax(0)` |
| `world.soapmaker3_level_tax(cid)` / `world.set_soapmaker3_level_tax(cid,v)` | `GetSoapmakerLevelTaxRate3` / `SetSoapmakerLevelTaxRate3` | `world.soapmaker3_level_tax(0)` |
| `world.candlemaker3_level_tax(cid)` / `world.set_candlemaker3_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate3` / `SetCandlemakerLevelTaxRate3` | `world.candlemaker3_level_tax(0)` |
| `world.papermill3_level_tax(cid)` / `world.set_papermill3_level_tax(cid,v)` | `GetPapermillLevelTaxRate3` / `SetPapermillLevelTaxRate3` | `world.papermill3_level_tax(0)` |
| `world.printing3_level_tax(cid)` / `world.set_printing3_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate3` / `SetPrintingHouseLevelTaxRate3` | `world.printing3_level_tax(0)` |
| `world.toolmaker3_level_tax(cid)` / `world.set_toolmaker3_level_tax(cid,v)` | `GetToolmakerLevelTaxRate3` / `SetToolmakerLevelTaxRate3` | `world.toolmaker3_level_tax(0)` |
| `world.charcoal3_level_tax(cid)` / `world.set_charcoal3_level_tax(cid,v)` | `GetCharcoalLevelTaxRate3` / `SetCharcoalLevelTaxRate3` | `world.charcoal3_level_tax(0)` |
| `world.furrier3_level_tax(cid)` / `world.set_furrier3_level_tax(cid,v)` | `GetFurrierLevelTaxRate3` / `SetFurrierLevelTaxRate3` | `world.furrier3_level_tax(0)` |
| `world.dyer3_level_tax(cid)` / `world.set_dyer3_level_tax(cid,v)` | `GetDyerLevelTaxRate3` / `SetDyerLevelTaxRate3` | `world.dyer3_level_tax(0)` |
| `world.saddler3_level_tax(cid)` / `world.set_saddler3_level_tax(cid,v)` | `GetSaddlerLevelTaxRate3` / `SetSaddlerLevelTaxRate3` | `world.saddler3_level_tax(0)` |
| `world.armorer3_level_tax(cid)` / `world.set_armorer3_level_tax(cid,v)` | `GetArmorerLevelTaxRate3` / `SetArmorerLevelTaxRate3` | `world.armorer3_level_tax(0)` |
| `world.bowyer3_level_tax(cid)` / `world.set_bowyer3_level_tax(cid,v)` | `GetBowyerLevelTaxRate3` / `SetBowyerLevelTaxRate3` | `world.bowyer3_level_tax(0)` |
| `world.cartwright3_level_tax(cid)` / `world.set_cartwright3_level_tax(cid,v)` | `GetCartwrightLevelTaxRate3` / `SetCartwrightLevelTaxRate3` | `world.cartwright3_level_tax(0)` |
| `world.carpenter3_level_tax(cid)` / `world.set_carpenter3_level_tax(cid,v)` | `GetCarpenterLevelTaxRate3` / `SetCarpenterLevelTaxRate3` | `world.carpenter3_level_tax(0)` |
| `world.ropemaker3_level_tax(cid)` / `world.set_ropemaker3_level_tax(cid,v)` | `GetRopemakerLevelTaxRate3` / `SetRopemakerLevelTaxRate3` | `world.ropemaker3_level_tax(0)` |
| `world.cooper3_level_tax(cid)` / `world.set_cooper3_level_tax(cid,v)` | `GetCooperLevelTaxRate3` / `SetCooperLevelTaxRate3` | `world.cooper3_level_tax(0)` |
| `world.spinner3_level_tax(cid)` / `world.set_spinner3_level_tax(cid,v)` | `GetSpinnerLevelTaxRate3` / `SetSpinnerLevelTaxRate3` | `world.spinner3_level_tax(0)` |
| `world.turner3_level_tax(cid)` / `world.set_turner3_level_tax(cid,v)` | `GetTurnerLevelTaxRate3` / `SetTurnerLevelTaxRate3` | `world.turner3_level_tax(0)` |
| `world.stonecutter3_level_tax(cid)` / `world.set_stonecutter3_level_tax(cid,v)` | `GetStonecutterLevelTaxRate3` / `SetStonecutterLevelTaxRate3` | `world.stonecutter3_level_tax(0)` |
| `world.cobbler3_level_tax(cid)` / `world.set_cobbler3_level_tax(cid,v)` | `GetCobblerLevelTaxRate3` / `SetCobblerLevelTaxRate3` | `world.cobbler3_level_tax(0)` |
| `world.butcher3_level_tax(cid)` / `world.set_butcher3_level_tax(cid,v)` | `GetButcherLevelTaxRate3` / `SetButcherLevelTaxRate3` | `world.butcher3_level_tax(0)` |
| `world.baker3_level_tax(cid)` / `world.set_baker3_level_tax(cid,v)` | `GetBakerLevelTaxRate3` / `SetBakerLevelTaxRate3` | `world.baker3_level_tax(0)` |
| `world.shepherd3_level_tax(cid)` / `world.set_shepherd3_level_tax(cid,v)` | `GetShepherdLevelTaxRate3` / `SetShepherdLevelTaxRate3` | `world.shepherd3_level_tax(0)` |
| `world.dairy3_level_tax(cid)` / `world.set_dairy3_level_tax(cid,v)` | `GetDairyLevelTaxRate3` / `SetDairyLevelTaxRate3` | `world.dairy3_level_tax(0)` |
| `world.brewmaster3_level_tax(cid)` / `world.set_brewmaster3_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate3` / `SetBrewmasterLevelTaxRate3` | `world.brewmaster3_level_tax(0)` |
| `world.miller3_level_tax(cid)` / `world.set_miller3_level_tax(cid,v)` | `GetMillerLevelTaxRate3` / `SetMillerLevelTaxRate3` | `world.miller3_level_tax(0)` |
| `world.fishery3_level_tax(cid)` / `world.set_fishery3_level_tax(cid,v)` | `GetFisheryLevelTaxRate3` / `SetFisheryLevelTaxRate3` | `world.fishery3_level_tax(0)` |
| `world.chandler3_level_tax(cid)` / `world.set_chandler3_level_tax(cid,v)` | `GetChandlerLevelTaxRate3` / `SetChandlerLevelTaxRate3` | `world.chandler3_level_tax(0)` |
| `world.goldbeater3_level_tax(cid)` / `world.set_goldbeater3_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate3` / `SetGoldbeaterLevelTaxRate3` | `world.goldbeater3_level_tax(0)` |
| `world.potter3_level_tax(cid)` / `world.set_potter3_level_tax(cid,v)` | `GetPotterLevelTaxRate3` / `SetPotterLevelTaxRate3` | `world.potter3_level_tax(0)` |
| `world.fowler3_level_tax(cid)` / `world.set_fowler3_level_tax(cid,v)` | `GetFowlerLevelTaxRate3` / `SetFowlerLevelTaxRate3` | `world.fowler3_level_tax(0)` |
| `world.vintner3_level_tax(cid)` / `world.set_vintner3_level_tax(cid,v)` | `GetVintnerLevelTaxRate3` / `SetVintnerLevelTaxRate3` | `world.vintner3_level_tax(0)` |
| `world.distiller3_level_tax(cid)` / `world.set_distiller3_level_tax(cid,v)` | `GetDistillerLevelTaxRate3` / `SetDistillerLevelTaxRate3` | `world.distiller3_level_tax(0)` |
| `world.cook3_level_tax(cid)` / `world.set_cook3_level_tax(cid,v)` | `GetCookLevelTaxRate3` / `SetCookLevelTaxRate3` | `world.cook3_level_tax(0)` |
| `world.brickmaker3_level_tax(cid)` / `world.set_brickmaker3_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate3` / `SetBrickmakerLevelTaxRate3` | `world.brickmaker3_level_tax(0)` |
| `world.bathhouse3_level_tax(cid)` / `world.set_bathhouse3_level_tax(cid,v)` | `GetBathhouseLevelTaxRate3` / `SetBathhouseLevelTaxRate3` | `world.bathhouse3_level_tax(0)` |
| `world.barracks5_level_tax(cid)` / `world.set_barracks5_level_tax(cid,v)` | `GetBarracksLevelTaxRate5` / `SetBarracksLevelTaxRate5` | `world.barracks5_level_tax(0)` |
| `world.school3_level_tax(cid)` / `world.set_school3_level_tax(cid,v)` | `GetSchoolLevelTaxRate3` / `SetSchoolLevelTaxRate3` | `world.school3_level_tax(0)` |
| `world.library3_level_tax(cid)` / `world.set_library3_level_tax(cid,v)` | `GetLibraryLevelTaxRate3` / `SetLibraryLevelTaxRate3` | `world.library3_level_tax(0)` |
| `world.mine3_level_tax(cid)` / `world.set_mine3_level_tax(cid,v)` | `GetMineLevelTaxRate3` / `SetMineLevelTaxRate3` | `world.mine3_level_tax(0)` |
| `world.warehouse3_level_tax(cid)` / `world.set_warehouse3_level_tax(cid,v)` | `GetWarehouseLevelTaxRate3` / `SetWarehouseLevelTaxRate3` | `world.warehouse3_level_tax(0)` |
| `world.garrison3_level_tax(cid)` / `world.set_garrison3_level_tax(cid,v)` | `GetGarrisonLevelTaxRate3` / `SetGarrisonLevelTaxRate3` | `world.garrison3_level_tax(0)` |
| `world.monastery3_level_tax(cid)` / `world.set_monastery3_level_tax(cid,v)` | `GetMonasteryLevelTaxRate3` / `SetMonasteryLevelTaxRate3` | `world.monastery3_level_tax(0)` |
| `world.cathedral3_level_tax(cid)` / `world.set_cathedral3_level_tax(cid,v)` | `GetCathedralLevelTaxRate3` / `SetCathedralLevelTaxRate3` | `world.cathedral3_level_tax(0)` |
| `world.town_hall3_level_tax(cid)` / `world.set_town_hall3_level_tax(cid,v)` | `GetTownHallLevelTaxRate3` / `SetTownHallLevelTaxRate3` | `world.town_hall3_level_tax(0)` |
| `world.market3_level_tax(cid)` / `world.set_market3_level_tax(cid,v)` | `GetMarketLevelTaxRate3` / `SetMarketLevelTaxRate3` | `world.market3_level_tax(0)` |
| `world.harbor3_level_tax(cid)` / `world.set_harbor3_level_tax(cid,v)` | `GetHarborLevelTaxRate3` / `SetHarborLevelTaxRate3` | `world.harbor3_level_tax(0)` |
| `world.guardhouse3_level_tax(cid)` / `world.set_guardhouse3_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate3` / `SetGuardhouseLevelTaxRate3` | `world.guardhouse3_level_tax(0)` |
| `world.courthouse3_level_tax(cid)` / `world.set_courthouse3_level_tax(cid,v)` | `GetCourthouseLevelTaxRate3` / `SetCourthouseLevelTaxRate3` | `world.courthouse3_level_tax(0)` |
| `world.univ_hall3_level_tax(cid)` / `world.set_univ_hall3_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate3` / `SetUniversityHallLevelTaxRate3` | `world.univ_hall3_level_tax(0)` |
| `world.castle3_level_tax(cid)` / `world.set_castle3_level_tax(cid,v)` | `GetCastleLevelTaxRate3` / `SetCastleLevelTaxRate3` | `world.castle3_level_tax(0)` |
| `world.barracks6_level_tax(cid)` / `world.set_barracks6_level_tax(cid,v)` | `GetBarracksLevelTaxRate6` / `SetBarracksLevelTaxRate6` | `world.barracks6_level_tax(0)` |
| `world.stables3_level_tax(cid)` / `world.set_stables3_level_tax(cid,v)` | `GetStablesLevelTaxRate3` / `SetStablesLevelTaxRate3` | `world.stables3_level_tax(0)` |
| `world.gates3_level_tax(cid)` / `world.set_gates3_level_tax(cid,v)` | `GetGatesLevelTaxRate3` / `SetGatesLevelTaxRate3` | `world.gates3_level_tax(0)` |
| `world.sentry3_level_tax(cid)` / `world.set_sentry3_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate3` / `SetSentryTowerLevelTaxRate3` | `world.sentry3_level_tax(0)` |
| `world.well3_level_tax(cid)` / `world.set_well3_level_tax(cid,v)` | `GetWellLevelTaxRate3` / `SetWellLevelTaxRate3` | `world.well3_level_tax(0)` |
| `world.bridge3_level_tax(cid)` / `world.set_bridge3_level_tax(cid,v)` | `GetBridgeLevelTaxRate3` / `SetBridgeLevelTaxRate3` | `world.bridge3_level_tax(0)` |
| `world.wall3_level_tax(cid)` / `world.set_wall3_level_tax(cid,v)` | `GetWallLevelTaxRate3` / `SetWallLevelTaxRate3` | `world.wall3_level_tax(0)` |
| `world.tower3_level_tax(cid)` / `world.set_tower3_level_tax(cid,v)` | `GetTowerLevelTaxRate3` / `SetTowerLevelTaxRate3` | `world.tower3_level_tax(0)` |
| `world.forum3_level_tax(cid)` / `world.set_forum3_level_tax(cid,v)` | `GetForumLevelTaxRate3` / `SetForumLevelTaxRate3` | `world.forum3_level_tax(0)` |
| `world.granary3_level_tax(cid)` / `world.set_granary3_level_tax(cid,v)` | `GetGranaryLevelTaxRate3` / `SetGranaryLevelTaxRate3` | `world.granary3_level_tax(0)` |
| `world.prison3_level_tax(cid)` / `world.set_prison3_level_tax(cid,v)` | `GetPrisonLevelTaxRate3` / `SetPrisonLevelTaxRate3` | `world.prison3_level_tax(0)` |
| `world.harbor_dock3_level_tax(cid)` / `world.set_harbor_dock3_level_tax(cid,v)` | `GetHarborDockLevelTaxRate3` / `SetHarborDockLevelTaxRate3` | `world.harbor_dock3_level_tax(0)` |
| `world.guild_house3_level_tax(cid)` / `world.set_guild_house3_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate3` / `SetGuildHouseLevelTaxRate3` | `world.guild_house3_level_tax(0)` |
| `world.house3_level_tax(cid)` / `world.set_house3_level_tax(cid,v)` | `GetHouseLevelTaxRate3` / `SetHouseLevelTaxRate3` | `world.house3_level_tax(0)` |
| `world.chapel3_level_tax(cid)` / `world.set_chapel3_level_tax(cid,v)` | `GetChapelLevelTaxRate3` / `SetChapelLevelTaxRate3` | `world.chapel3_level_tax(0)` |
| `world.hospital3_level_tax(cid)` / `world.set_hospital3_level_tax(cid,v)` | `GetHospitalLevelTaxRate3` / `SetHospitalLevelTaxRate3` | `world.hospital3_level_tax(0)` |
| `world.brothel3_level_tax(cid)` / `world.set_brothel3_level_tax(cid,v)` | `GetBrothelLevelTaxRate3` / `SetBrothelLevelTaxRate3` | `world.brothel3_level_tax(0)` |
| `world.university3_level_tax(cid)` / `world.set_university3_level_tax(cid,v)` | `GetUniversityLevelTaxRate3` / `SetUniversityLevelTaxRate3` | `world.university3_level_tax(0)` |
| `world.harbor_walls3_level_tax(cid)` / `world.set_harbor_walls3_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate3` / `SetHarborWallsLevelTaxRate3` | `world.harbor_walls3_level_tax(0)` |
| `world.schoolhouse3_level_tax(cid)` / `world.set_schoolhouse3_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate3` / `SetSchoolhouseLevelTaxRate3` | `world.schoolhouse3_level_tax(0)` |
| `world.library_hall3_level_tax(cid)` / `world.set_library_hall3_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate3` / `SetLibraryHallLevelTaxRate3` | `world.library_hall3_level_tax(0)` |
| `world.barber3_level_tax(cid)` / `world.set_barber3_level_tax(cid,v)` | `GetBarberLevelTaxRate3` / `SetBarberLevelTaxRate3` | `world.barber3_level_tax(0)` |
| `world.contor4_level_tax(cid)` / `world.set_contor4_level_tax(cid,v)` | `GetContorLevelTaxRate4` / `SetContorLevelTaxRate4` | `world.contor4_level_tax(0)` |
| `world.dice_house4_level_tax(cid)` / `world.set_dice_house4_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate4` / `SetDiceHouseLevelTaxRate4` | `world.dice_house4_level_tax(0)` |
| `world.thieves4_level_tax(cid)` / `world.set_thieves4_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate4` / `SetThievesGuildLevelTaxRate4` | `world.thieves4_level_tax(0)` |
| `world.ropemaker_ws4_level_tax(cid)` / `world.set_ropemaker_ws4_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate4` / `SetRopemakerWorkshopLevelTaxRate4` | `world.ropemaker_ws4_level_tax(0)` |
| `world.tannery4_level_tax(cid)` / `world.set_tannery4_level_tax(cid,v)` | `GetTanneryLevelTaxRate4` / `SetTanneryLevelTaxRate4` | `world.tannery4_level_tax(0)` |
| `world.weaving4_level_tax(cid)` / `world.set_weaving4_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate4` / `SetWeavingMillLevelTaxRate4` | `world.weaving4_level_tax(0)` |
| `world.mint4_level_tax(cid)` / `world.set_mint4_level_tax(cid,v)` | `GetMintLevelTaxRate4` / `SetMintLevelTaxRate4` | `world.mint4_level_tax(0)` |
| `world.herb_garden4_level_tax(cid)` / `world.set_herb_garden4_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate4` / `SetHerbGardenLevelTaxRate4` | `world.herb_garden4_level_tax(0)` |
| `world.vineyard4_level_tax(cid)` / `world.set_vineyard4_level_tax(cid,v)` | `GetVineyardLevelTaxRate4` / `SetVineyardLevelTaxRate4` | `world.vineyard4_level_tax(0)` |
| `world.pottery4_level_tax(cid)` / `world.set_pottery4_level_tax(cid,v)` | `GetPotteryLevelTaxRate4` / `SetPotteryLevelTaxRate4` | `world.pottery4_level_tax(0)` |
| `world.tailor4_level_tax(cid)` / `world.set_tailor4_level_tax(cid,v)` | `GetTailorLevelTaxRate4` / `SetTailorLevelTaxRate4` | `world.tailor4_level_tax(0)` |
| `world.tavern4_level_tax(cid)` / `world.set_tavern4_level_tax(cid,v)` | `GetTavernLevelTaxRate4` / `SetTavernLevelTaxRate4` | `world.tavern4_level_tax(0)` |
| `world.apothecary4_level_tax(cid)` / `world.set_apothecary4_level_tax(cid,v)` | `GetApothecaryLevelTaxRate4` / `SetApothecaryLevelTaxRate4` | `world.apothecary4_level_tax(0)` |
| `world.goldsmith4_level_tax(cid)` / `world.set_goldsmith4_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate4` / `SetGoldsmithLevelTaxRate4` | `world.goldsmith4_level_tax(0)` |
| `world.jeweler4_level_tax(cid)` / `world.set_jeweler4_level_tax(cid,v)` | `GetJewelerLevelTaxRate4` / `SetJewelerLevelTaxRate4` | `world.jeweler4_level_tax(0)` |
| `world.perfumer4_level_tax(cid)` / `world.set_perfumer4_level_tax(cid,v)` | `GetPerfumerLevelTaxRate4` / `SetPerfumerLevelTaxRate4` | `world.perfumer4_level_tax(0)` |
| `world.soapmaker4_level_tax(cid)` / `world.set_soapmaker4_level_tax(cid,v)` | `GetSoapmakerLevelTaxRate4` / `SetSoapmakerLevelTaxRate4` | `world.soapmaker4_level_tax(0)` |
| `world.candlemaker4_level_tax(cid)` / `world.set_candlemaker4_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate4` / `SetCandlemakerLevelTaxRate4` | `world.candlemaker4_level_tax(0)` |
| `world.papermill4_level_tax(cid)` / `world.set_papermill4_level_tax(cid,v)` | `GetPapermillLevelTaxRate4` / `SetPapermillLevelTaxRate4` | `world.papermill4_level_tax(0)` |
| `world.printing4_level_tax(cid)` / `world.set_printing4_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate4` / `SetPrintingHouseLevelTaxRate4` | `world.printing4_level_tax(0)` |
| `world.toolmaker4_level_tax(cid)` / `world.set_toolmaker4_level_tax(cid,v)` | `GetToolmakerLevelTaxRate4` / `SetToolmakerLevelTaxRate4` | `world.toolmaker4_level_tax(0)` |
| `world.charcoal4_level_tax(cid)` / `world.set_charcoal4_level_tax(cid,v)` | `GetCharcoalLevelTaxRate4` / `SetCharcoalLevelTaxRate4` | `world.charcoal4_level_tax(0)` |
| `world.furrier4_level_tax(cid)` / `world.set_furrier4_level_tax(cid,v)` | `GetFurrierLevelTaxRate4` / `SetFurrierLevelTaxRate4` | `world.furrier4_level_tax(0)` |
| `world.dyer4_level_tax(cid)` / `world.set_dyer4_level_tax(cid,v)` | `GetDyerLevelTaxRate4` / `SetDyerLevelTaxRate4` | `world.dyer4_level_tax(0)` |
| `world.saddler4_level_tax(cid)` / `world.set_saddler4_level_tax(cid,v)` | `GetSaddlerLevelTaxRate4` / `SetSaddlerLevelTaxRate4` | `world.saddler4_level_tax(0)` |
| `world.armorer4_level_tax(cid)` / `world.set_armorer4_level_tax(cid,v)` | `GetArmorerLevelTaxRate4` / `SetArmorerLevelTaxRate4` | `world.armorer4_level_tax(0)` |
| `world.bowyer4_level_tax(cid)` / `world.set_bowyer4_level_tax(cid,v)` | `GetBowyerLevelTaxRate4` / `SetBowyerLevelTaxRate4` | `world.bowyer4_level_tax(0)` |
| `world.cartwright4_level_tax(cid)` / `world.set_cartwright4_level_tax(cid,v)` | `GetCartwrightLevelTaxRate4` / `SetCartwrightLevelTaxRate4` | `world.cartwright4_level_tax(0)` |
| `world.carpenter4_level_tax(cid)` / `world.set_carpenter4_level_tax(cid,v)` | `GetCarpenterLevelTaxRate4` / `SetCarpenterLevelTaxRate4` | `world.carpenter4_level_tax(0)` |
| `world.ropemaker4_level_tax(cid)` / `world.set_ropemaker4_level_tax(cid,v)` | `GetRopemakerLevelTaxRate4` / `SetRopemakerLevelTaxRate4` | `world.ropemaker4_level_tax(0)` |
| `world.cooper4_level_tax(cid)` / `world.set_cooper4_level_tax(cid,v)` | `GetCooperLevelTaxRate4` / `SetCooperLevelTaxRate4` | `world.cooper4_level_tax(0)` |
| `world.spinner4_level_tax(cid)` / `world.set_spinner4_level_tax(cid,v)` | `GetSpinnerLevelTaxRate4` / `SetSpinnerLevelTaxRate4` | `world.spinner4_level_tax(0)` |
| `world.turner4_level_tax(cid)` / `world.set_turner4_level_tax(cid,v)` | `GetTurnerLevelTaxRate4` / `SetTurnerLevelTaxRate4` | `world.turner4_level_tax(0)` |
| `world.stonecutter4_level_tax(cid)` / `world.set_stonecutter4_level_tax(cid,v)` | `GetStonecutterLevelTaxRate4` / `SetStonecutterLevelTaxRate4` | `world.stonecutter4_level_tax(0)` |
| `world.cobbler4_level_tax(cid)` / `world.set_cobbler4_level_tax(cid,v)` | `GetCobblerLevelTaxRate4` / `SetCobblerLevelTaxRate4` | `world.cobbler4_level_tax(0)` |
| `world.butcher4_level_tax(cid)` / `world.set_butcher4_level_tax(cid,v)` | `GetButcherLevelTaxRate4` / `SetButcherLevelTaxRate4` | `world.butcher4_level_tax(0)` |
| `world.baker4_level_tax(cid)` / `world.set_baker4_level_tax(cid,v)` | `GetBakerLevelTaxRate4` / `SetBakerLevelTaxRate4` | `world.baker4_level_tax(0)` |
| `world.shepherd4_level_tax(cid)` / `world.set_shepherd4_level_tax(cid,v)` | `GetShepherdLevelTaxRate4` / `SetShepherdLevelTaxRate4` | `world.shepherd4_level_tax(0)` |
| `world.dairy4_level_tax(cid)` / `world.set_dairy4_level_tax(cid,v)` | `GetDairyLevelTaxRate4` / `SetDairyLevelTaxRate4` | `world.dairy4_level_tax(0)` |
| `world.brewmaster4_level_tax(cid)` / `world.set_brewmaster4_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate4` / `SetBrewmasterLevelTaxRate4` | `world.brewmaster4_level_tax(0)` |
| `world.miller4_level_tax(cid)` / `world.set_miller4_level_tax(cid,v)` | `GetMillerLevelTaxRate4` / `SetMillerLevelTaxRate4` | `world.miller4_level_tax(0)` |
| `world.fishery4_level_tax(cid)` / `world.set_fishery4_level_tax(cid,v)` | `GetFisheryLevelTaxRate4` / `SetFisheryLevelTaxRate4` | `world.fishery4_level_tax(0)` |
| `world.chandler4_level_tax(cid)` / `world.set_chandler4_level_tax(cid,v)` | `GetChandlerLevelTaxRate4` / `SetChandlerLevelTaxRate4` | `world.chandler4_level_tax(0)` |
| `world.goldbeater4_level_tax(cid)` / `world.set_goldbeater4_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate4` / `SetGoldbeaterLevelTaxRate4` | `world.goldbeater4_level_tax(0)` |
| `world.potter4_level_tax(cid)` / `world.set_potter4_level_tax(cid,v)` | `GetPotterLevelTaxRate4` / `SetPotterLevelTaxRate4` | `world.potter4_level_tax(0)` |
| `world.fowler4_level_tax(cid)` / `world.set_fowler4_level_tax(cid,v)` | `GetFowlerLevelTaxRate4` / `SetFowlerLevelTaxRate4` | `world.fowler4_level_tax(0)` |
| `world.vintner4_level_tax(cid)` / `world.set_vintner4_level_tax(cid,v)` | `GetVintnerLevelTaxRate4` / `SetVintnerLevelTaxRate4` | `world.vintner4_level_tax(0)` |
| `world.distiller4_level_tax(cid)` / `world.set_distiller4_level_tax(cid,v)` | `GetDistillerLevelTaxRate4` / `SetDistillerLevelTaxRate4` | `world.distiller4_level_tax(0)` |
| `world.cook4_level_tax(cid)` / `world.set_cook4_level_tax(cid,v)` | `GetCookLevelTaxRate4` / `SetCookLevelTaxRate4` | `world.cook4_level_tax(0)` |
| `world.brickmaker4_level_tax(cid)` / `world.set_brickmaker4_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate4` / `SetBrickmakerLevelTaxRate4` | `world.brickmaker4_level_tax(0)` |
| `world.bathhouse4_level_tax(cid)` / `world.set_bathhouse4_level_tax(cid,v)` | `GetBathhouseLevelTaxRate4` / `SetBathhouseLevelTaxRate4` | `world.bathhouse4_level_tax(0)` |
| `world.barracks7_level_tax(cid)` / `world.set_barracks7_level_tax(cid,v)` | `GetBarracksLevelTaxRate7` / `SetBarracksLevelTaxRate7` | `world.barracks7_level_tax(0)` |
| `world.school4_level_tax(cid)` / `world.set_school4_level_tax(cid,v)` | `GetSchoolLevelTaxRate4` / `SetSchoolLevelTaxRate4` | `world.school4_level_tax(0)` |
| `world.library4_level_tax(cid)` / `world.set_library4_level_tax(cid,v)` | `GetLibraryLevelTaxRate4` / `SetLibraryLevelTaxRate4` | `world.library4_level_tax(0)` |
| `world.mine4_level_tax(cid)` / `world.set_mine4_level_tax(cid,v)` | `GetMineLevelTaxRate4` / `SetMineLevelTaxRate4` | `world.mine4_level_tax(0)` |
| `world.warehouse4_level_tax(cid)` / `world.set_warehouse4_level_tax(cid,v)` | `GetWarehouseLevelTaxRate4` / `SetWarehouseLevelTaxRate4` | `world.warehouse4_level_tax(0)` |
| `world.garrison4_level_tax(cid)` / `world.set_garrison4_level_tax(cid,v)` | `GetGarrisonLevelTaxRate4` / `SetGarrisonLevelTaxRate4` | `world.garrison4_level_tax(0)` |
| `world.monastery4_level_tax(cid)` / `world.set_monastery4_level_tax(cid,v)` | `GetMonasteryLevelTaxRate4` / `SetMonasteryLevelTaxRate4` | `world.monastery4_level_tax(0)` |
| `world.cathedral4_level_tax(cid)` / `world.set_cathedral4_level_tax(cid,v)` | `GetCathedralLevelTaxRate4` / `SetCathedralLevelTaxRate4` | `world.cathedral4_level_tax(0)` |
| `world.town_hall4_level_tax(cid)` / `world.set_town_hall4_level_tax(cid,v)` | `GetTownHallLevelTaxRate4` / `SetTownHallLevelTaxRate4` | `world.town_hall4_level_tax(0)` |
| `world.market4_level_tax(cid)` / `world.set_market4_level_tax(cid,v)` | `GetMarketLevelTaxRate4` / `SetMarketLevelTaxRate4` | `world.market4_level_tax(0)` |
| `world.harbor4_level_tax(cid)` / `world.set_harbor4_level_tax(cid,v)` | `GetHarborLevelTaxRate4` / `SetHarborLevelTaxRate4` | `world.harbor4_level_tax(0)` |
| `world.guardhouse4_level_tax(cid)` / `world.set_guardhouse4_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate4` / `SetGuardhouseLevelTaxRate4` | `world.guardhouse4_level_tax(0)` |
| `world.courthouse4_level_tax(cid)` / `world.set_courthouse4_level_tax(cid,v)` | `GetCourthouseLevelTaxRate4` / `SetCourthouseLevelTaxRate4` | `world.courthouse4_level_tax(0)` |
| `world.univ_hall4_level_tax(cid)` / `world.set_univ_hall4_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate4` / `SetUniversityHallLevelTaxRate4` | `world.univ_hall4_level_tax(0)` |
| `world.castle4_level_tax(cid)` / `world.set_castle4_level_tax(cid,v)` | `GetCastleLevelTaxRate4` / `SetCastleLevelTaxRate4` | `world.castle4_level_tax(0)` |
| `world.barracks8_level_tax(cid)` / `world.set_barracks8_level_tax(cid,v)` | `GetBarracksLevelTaxRate8` / `SetBarracksLevelTaxRate8` | `world.barracks8_level_tax(0)` |
| `world.stables4_level_tax(cid)` / `world.set_stables4_level_tax(cid,v)` | `GetStablesLevelTaxRate4` / `SetStablesLevelTaxRate4` | `world.stables4_level_tax(0)` |
| `world.gates4_level_tax(cid)` / `world.set_gates4_level_tax(cid,v)` | `GetGatesLevelTaxRate4` / `SetGatesLevelTaxRate4` | `world.gates4_level_tax(0)` |
| `world.sentry4_level_tax(cid)` / `world.set_sentry4_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate4` / `SetSentryTowerLevelTaxRate4` | `world.sentry4_level_tax(0)` |
| `world.well4_level_tax(cid)` / `world.set_well4_level_tax(cid,v)` | `GetWellLevelTaxRate4` / `SetWellLevelTaxRate4` | `world.well4_level_tax(0)` |
| `world.bridge4_level_tax(cid)` / `world.set_bridge4_level_tax(cid,v)` | `GetBridgeLevelTaxRate4` / `SetBridgeLevelTaxRate4` | `world.bridge4_level_tax(0)` |
| `world.wall4_level_tax(cid)` / `world.set_wall4_level_tax(cid,v)` | `GetWallLevelTaxRate4` / `SetWallLevelTaxRate4` | `world.wall4_level_tax(0)` |
| `world.tower4_level_tax(cid)` / `world.set_tower4_level_tax(cid,v)` | `GetTowerLevelTaxRate4` / `SetTowerLevelTaxRate4` | `world.tower4_level_tax(0)` |
| `world.forum4_level_tax(cid)` / `world.set_forum4_level_tax(cid,v)` | `GetForumLevelTaxRate4` / `SetForumLevelTaxRate4` | `world.forum4_level_tax(0)` |
| `world.granary4_level_tax(cid)` / `world.set_granary4_level_tax(cid,v)` | `GetGranaryLevelTaxRate4` / `SetGranaryLevelTaxRate4` | `world.granary4_level_tax(0)` |
| `world.prison4_level_tax(cid)` / `world.set_prison4_level_tax(cid,v)` | `GetPrisonLevelTaxRate4` / `SetPrisonLevelTaxRate4` | `world.prison4_level_tax(0)` |
| `world.harbor_dock4_level_tax(cid)` / `world.set_harbor_dock4_level_tax(cid,v)` | `GetHarborDockLevelTaxRate4` / `SetHarborDockLevelTaxRate4` | `world.harbor_dock4_level_tax(0)` |
| `world.guild_house4_level_tax(cid)` / `world.set_guild_house4_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate4` / `SetGuildHouseLevelTaxRate4` | `world.guild_house4_level_tax(0)` |
| `world.house4_level_tax(cid)` / `world.set_house4_level_tax(cid,v)` | `GetHouseLevelTaxRate4` / `SetHouseLevelTaxRate4` | `world.house4_level_tax(0)` |
| `world.chapel4_level_tax(cid)` / `world.set_chapel4_level_tax(cid,v)` | `GetChapelLevelTaxRate4` / `SetChapelLevelTaxRate4` | `world.chapel4_level_tax(0)` |
| `world.hospital4_level_tax(cid)` / `world.set_hospital4_level_tax(cid,v)` | `GetHospitalLevelTaxRate4` / `SetHospitalLevelTaxRate4` | `world.hospital4_level_tax(0)` |
| `world.brothel4_level_tax(cid)` / `world.set_brothel4_level_tax(cid,v)` | `GetBrothelLevelTaxRate4` / `SetBrothelLevelTaxRate4` | `world.brothel4_level_tax(0)` |
| `world.university4_level_tax(cid)` / `world.set_university4_level_tax(cid,v)` | `GetUniversityLevelTaxRate4` / `SetUniversityLevelTaxRate4` | `world.university4_level_tax(0)` |
| `world.harbor_walls4_level_tax(cid)` / `world.set_harbor_walls4_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate4` / `SetHarborWallsLevelTaxRate4` | `world.harbor_walls4_level_tax(0)` |
| `world.schoolhouse4_level_tax(cid)` / `world.set_schoolhouse4_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate4` / `SetSchoolhouseLevelTaxRate4` | `world.schoolhouse4_level_tax(0)` |
| `world.library_hall4_level_tax(cid)` / `world.set_library_hall4_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate4` / `SetLibraryHallLevelTaxRate4` | `world.library_hall4_level_tax(0)` |
| `world.barber4_level_tax(cid)` / `world.set_barber4_level_tax(cid,v)` | `GetBarberLevelTaxRate4` / `SetBarberLevelTaxRate4` | `world.barber4_level_tax(0)` |
| `world.contor5_level_tax(cid)` / `world.set_contor5_level_tax(cid,v)` | `GetContorLevelTaxRate5` / `SetContorLevelTaxRate5` | `world.contor5_level_tax(0)` |
| `world.dice_house5_level_tax(cid)` / `world.set_dice_house5_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate5` / `SetDiceHouseLevelTaxRate5` | `world.dice_house5_level_tax(0)` |
| `world.thieves5_level_tax(cid)` / `world.set_thieves5_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate5` / `SetThievesGuildLevelTaxRate5` | `world.thieves5_level_tax(0)` |
| `world.ropemaker_ws5_level_tax(cid)` / `world.set_ropemaker_ws5_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate5` / `SetRopemakerWorkshopLevelTaxRate5` | `world.ropemaker_ws5_level_tax(0)` |
| `world.tannery5_level_tax(cid)` / `world.set_tannery5_level_tax(cid,v)` | `GetTanneryLevelTaxRate5` / `SetTanneryLevelTaxRate5` | `world.tannery5_level_tax(0)` |
| `world.weaving5_level_tax(cid)` / `world.set_weaving5_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate5` / `SetWeavingMillLevelTaxRate5` | `world.weaving5_level_tax(0)` |
| `world.mint5_level_tax(cid)` / `world.set_mint5_level_tax(cid,v)` | `GetMintLevelTaxRate5` / `SetMintLevelTaxRate5` | `world.mint5_level_tax(0)` |
| `world.herb_garden5_level_tax(cid)` / `world.set_herb_garden5_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate5` / `SetHerbGardenLevelTaxRate5` | `world.herb_garden5_level_tax(0)` |
| `world.vineyard5_level_tax(cid)` / `world.set_vineyard5_level_tax(cid,v)` | `GetVineyardLevelTaxRate5` / `SetVineyardLevelTaxRate5` | `world.vineyard5_level_tax(0)` |
| `world.pottery5_level_tax(cid)` / `world.set_pottery5_level_tax(cid,v)` | `GetPotteryLevelTaxRate5` / `SetPotteryLevelTaxRate5` | `world.pottery5_level_tax(0)` |
| `world.tailor5_level_tax(cid)` / `world.set_tailor5_level_tax(cid,v)` | `GetTailorLevelTaxRate5` / `SetTailorLevelTaxRate5` | `world.tailor5_level_tax(0)` |
| `world.tavern5_level_tax(cid)` / `world.set_tavern5_level_tax(cid,v)` | `GetTavernLevelTaxRate5` / `SetTavernLevelTaxRate5` | `world.tavern5_level_tax(0)` |
| `world.apothecary5_level_tax(cid)` / `world.set_apothecary5_level_tax(cid,v)` | `GetApothecaryLevelTaxRate5` / `SetApothecaryLevelTaxRate5` | `world.apothecary5_level_tax(0)` |
| `world.goldsmith5_level_tax(cid)` / `world.set_goldsmith5_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate5` / `SetGoldsmithLevelTaxRate5` | `world.goldsmith5_level_tax(0)` |
| `world.jeweler5_level_tax(cid)` / `world.set_jeweler5_level_tax(cid,v)` | `GetJewelerLevelTaxRate5` / `SetJewelerLevelTaxRate5` | `world.jeweler5_level_tax(0)` |
| `world.perfumer5_level_tax(cid)` / `world.set_perfumer5_level_tax(cid,v)` | `GetPerfumerLevelTaxRate5` / `SetPerfumerLevelTaxRate5` | `world.perfumer5_level_tax(0)` |
| `world.soapmaker5_level_tax(cid)` / `world.set_soapmaker5_level_tax(cid,v)` | `GetSoapmakerLevelTaxRate5` / `SetSoapmakerLevelTaxRate5` | `world.soapmaker5_level_tax(0)` |
| `world.candlemaker5_level_tax(cid)` / `world.set_candlemaker5_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate5` / `SetCandlemakerLevelTaxRate5` | `world.candlemaker5_level_tax(0)` |
| `world.papermill5_level_tax(cid)` / `world.set_papermill5_level_tax(cid,v)` | `GetPapermillLevelTaxRate5` / `SetPapermillLevelTaxRate5` | `world.papermill5_level_tax(0)` |
| `world.printing5_level_tax(cid)` / `world.set_printing5_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate5` / `SetPrintingHouseLevelTaxRate5` | `world.printing5_level_tax(0)` |
| `world.toolmaker5_level_tax(cid)` / `world.set_toolmaker5_level_tax(cid,v)` | `GetToolmakerLevelTaxRate5` / `SetToolmakerLevelTaxRate5` | `world.toolmaker5_level_tax(0)` |
| `world.charcoal5_level_tax(cid)` / `world.set_charcoal5_level_tax(cid,v)` | `GetCharcoalLevelTaxRate5` / `SetCharcoalLevelTaxRate5` | `world.charcoal5_level_tax(0)` |
| `world.furrier5_level_tax(cid)` / `world.set_furrier5_level_tax(cid,v)` | `GetFurrierLevelTaxRate5` / `SetFurrierLevelTaxRate5` | `world.furrier5_level_tax(0)` |
| `world.dyer5_level_tax(cid)` / `world.set_dyer5_level_tax(cid,v)` | `GetDyerLevelTaxRate5` / `SetDyerLevelTaxRate5` | `world.dyer5_level_tax(0)` |
| `world.saddler5_level_tax(cid)` / `world.set_saddler5_level_tax(cid,v)` | `GetSaddlerLevelTaxRate5` / `SetSaddlerLevelTaxRate5` | `world.saddler5_level_tax(0)` |
| `world.armorer5_level_tax(cid)` / `world.set_armorer5_level_tax(cid,v)` | `GetArmorerLevelTaxRate5` / `SetArmorerLevelTaxRate5` | `world.armorer5_level_tax(0)` |
| `world.bowyer5_level_tax(cid)` / `world.set_bowyer5_level_tax(cid,v)` | `GetBowyerLevelTaxRate5` / `SetBowyerLevelTaxRate5` | `world.bowyer5_level_tax(0)` |
| `world.cartwright5_level_tax(cid)` / `world.set_cartwright5_level_tax(cid,v)` | `GetCartwrightLevelTaxRate5` / `SetCartwrightLevelTaxRate5` | `world.cartwright5_level_tax(0)` |
| `world.carpenter5_level_tax(cid)` / `world.set_carpenter5_level_tax(cid,v)` | `GetCarpenterLevelTaxRate5` / `SetCarpenterLevelTaxRate5` | `world.carpenter5_level_tax(0)` |
| `world.ropemaker5_level_tax(cid)` / `world.set_ropemaker5_level_tax(cid,v)` | `GetRopemakerLevelTaxRate5` / `SetRopemakerLevelTaxRate5` | `world.ropemaker5_level_tax(0)` |
| `world.cooper5_level_tax(cid)` / `world.set_cooper5_level_tax(cid,v)` | `GetCooperLevelTaxRate5` / `SetCooperLevelTaxRate5` | `world.cooper5_level_tax(0)` |
| `world.spinner5_level_tax(cid)` / `world.set_spinner5_level_tax(cid,v)` | `GetSpinnerLevelTaxRate5` / `SetSpinnerLevelTaxRate5` | `world.spinner5_level_tax(0)` |
| `world.turner5_level_tax(cid)` / `world.set_turner5_level_tax(cid,v)` | `GetTurnerLevelTaxRate5` / `SetTurnerLevelTaxRate5` | `world.turner5_level_tax(0)` |
| `world.stonecutter5_level_tax(cid)` / `world.set_stonecutter5_level_tax(cid,v)` | `GetStonecutterLevelTaxRate5` / `SetStonecutterLevelTaxRate5` | `world.stonecutter5_level_tax(0)` |
| `world.cobbler5_level_tax(cid)` / `world.set_cobbler5_level_tax(cid,v)` | `GetCobblerLevelTaxRate5` / `SetCobblerLevelTaxRate5` | `world.cobbler5_level_tax(0)` |
| `world.butcher5_level_tax(cid)` / `world.set_butcher5_level_tax(cid,v)` | `GetButcherLevelTaxRate5` / `SetButcherLevelTaxRate5` | `world.butcher5_level_tax(0)` |
| `world.baker5_level_tax(cid)` / `world.set_baker5_level_tax(cid,v)` | `GetBakerLevelTaxRate5` / `SetBakerLevelTaxRate5` | `world.baker5_level_tax(0)` |
| `world.shepherd5_level_tax(cid)` / `world.set_shepherd5_level_tax(cid,v)` | `GetShepherdLevelTaxRate5` / `SetShepherdLevelTaxRate5` | `world.shepherd5_level_tax(0)` |
| `world.dairy5_level_tax(cid)` / `world.set_dairy5_level_tax(cid,v)` | `GetDairyLevelTaxRate5` / `SetDairyLevelTaxRate5` | `world.dairy5_level_tax(0)` |
| `world.brewmaster5_level_tax(cid)` / `world.set_brewmaster5_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate5` / `SetBrewmasterLevelTaxRate5` | `world.brewmaster5_level_tax(0)` |
| `world.miller5_level_tax(cid)` / `world.set_miller5_level_tax(cid,v)` | `GetMillerLevelTaxRate5` / `SetMillerLevelTaxRate5` | `world.miller5_level_tax(0)` |
| `world.fishery5_level_tax(cid)` / `world.set_fishery5_level_tax(cid,v)` | `GetFisheryLevelTaxRate5` / `SetFisheryLevelTaxRate5` | `world.fishery5_level_tax(0)` |
| `world.chandler5_level_tax(cid)` / `world.set_chandler5_level_tax(cid,v)` | `GetChandlerLevelTaxRate5` / `SetChandlerLevelTaxRate5` | `world.chandler5_level_tax(0)` |
| `world.goldbeater5_level_tax(cid)` / `world.set_goldbeater5_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate5` / `SetGoldbeaterLevelTaxRate5` | `world.goldbeater5_level_tax(0)` |
| `world.potter5_level_tax(cid)` / `world.set_potter5_level_tax(cid,v)` | `GetPotterLevelTaxRate5` / `SetPotterLevelTaxRate5` | `world.potter5_level_tax(0)` |
| `world.fowler5_level_tax(cid)` / `world.set_fowler5_level_tax(cid,v)` | `GetFowlerLevelTaxRate5` / `SetFowlerLevelTaxRate5` | `world.fowler5_level_tax(0)` |
| `world.vintner5_level_tax(cid)` / `world.set_vintner5_level_tax(cid,v)` | `GetVintnerLevelTaxRate5` / `SetVintnerLevelTaxRate5` | `world.vintner5_level_tax(0)` |
| `world.distiller5_level_tax(cid)` / `world.set_distiller5_level_tax(cid,v)` | `GetDistillerLevelTaxRate5` / `SetDistillerLevelTaxRate5` | `world.distiller5_level_tax(0)` |
| `world.cook5_level_tax(cid)` / `world.set_cook5_level_tax(cid,v)` | `GetCookLevelTaxRate5` / `SetCookLevelTaxRate5` | `world.cook5_level_tax(0)` |
| `world.brickmaker5_level_tax(cid)` / `world.set_brickmaker5_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate5` / `SetBrickmakerLevelTaxRate5` | `world.brickmaker5_level_tax(0)` |
| `world.bathhouse5_level_tax(cid)` / `world.set_bathhouse5_level_tax(cid,v)` | `GetBathhouseLevelTaxRate5` / `SetBathhouseLevelTaxRate5` | `world.bathhouse5_level_tax(0)` |
| `world.barracks9_level_tax(cid)` / `world.set_barracks9_level_tax(cid,v)` | `GetBarracksLevelTaxRate9` / `SetBarracksLevelTaxRate9` | `world.barracks9_level_tax(0)` |
| `world.school5_level_tax(cid)` / `world.set_school5_level_tax(cid,v)` | `GetSchoolLevelTaxRate5` / `SetSchoolLevelTaxRate5` | `world.school5_level_tax(0)` |
| `world.library5_level_tax(cid)` / `world.set_library5_level_tax(cid,v)` | `GetLibraryLevelTaxRate5` / `SetLibraryLevelTaxRate5` | `world.library5_level_tax(0)` |
| `world.mine5_level_tax(cid)` / `world.set_mine5_level_tax(cid,v)` | `GetMineLevelTaxRate5` / `SetMineLevelTaxRate5` | `world.mine5_level_tax(0)` |
| `world.warehouse5_level_tax(cid)` / `world.set_warehouse5_level_tax(cid,v)` | `GetWarehouseLevelTaxRate5` / `SetWarehouseLevelTaxRate5` | `world.warehouse5_level_tax(0)` |
| `world.garrison5_level_tax(cid)` / `world.set_garrison5_level_tax(cid,v)` | `GetGarrisonLevelTaxRate5` / `SetGarrisonLevelTaxRate5` | `world.garrison5_level_tax(0)` |
| `world.monastery5_level_tax(cid)` / `world.set_monastery5_level_tax(cid,v)` | `GetMonasteryLevelTaxRate5` / `SetMonasteryLevelTaxRate5` | `world.monastery5_level_tax(0)` |
| `world.cathedral5_level_tax(cid)` / `world.set_cathedral5_level_tax(cid,v)` | `GetCathedralLevelTaxRate5` / `SetCathedralLevelTaxRate5` | `world.cathedral5_level_tax(0)` |
| `world.town_hall5_level_tax(cid)` / `world.set_town_hall5_level_tax(cid,v)` | `GetTownHallLevelTaxRate5` / `SetTownHallLevelTaxRate5` | `world.town_hall5_level_tax(0)` |
| `world.market5_level_tax(cid)` / `world.set_market5_level_tax(cid,v)` | `GetMarketLevelTaxRate5` / `SetMarketLevelTaxRate5` | `world.market5_level_tax(0)` |
| `world.harbor5_level_tax(cid)` / `world.set_harbor5_level_tax(cid,v)` | `GetHarborLevelTaxRate5` / `SetHarborLevelTaxRate5` | `world.harbor5_level_tax(0)` |
| `world.guardhouse5_level_tax(cid)` / `world.set_guardhouse5_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate5` / `SetGuardhouseLevelTaxRate5` | `world.guardhouse5_level_tax(0)` |
| `world.courthouse5_level_tax(cid)` / `world.set_courthouse5_level_tax(cid,v)` | `GetCourthouseLevelTaxRate5` / `SetCourthouseLevelTaxRate5` | `world.courthouse5_level_tax(0)` |
| `world.univ_hall5_level_tax(cid)` / `world.set_univ_hall5_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate5` / `SetUniversityHallLevelTaxRate5` | `world.univ_hall5_level_tax(0)` |
| `world.castle5_level_tax(cid)` / `world.set_castle5_level_tax(cid,v)` | `GetCastleLevelTaxRate5` / `SetCastleLevelTaxRate5` | `world.castle5_level_tax(0)` |
| `world.barracks10_level_tax(cid)` / `world.set_barracks10_level_tax(cid,v)` | `GetBarracksLevelTaxRate10` / `SetBarracksLevelTaxRate10` | `world.barracks10_level_tax(0)` |
| `world.stables5_level_tax(cid)` / `world.set_stables5_level_tax(cid,v)` | `GetStablesLevelTaxRate5` / `SetStablesLevelTaxRate5` | `world.stables5_level_tax(0)` |
| `world.gates5_level_tax(cid)` / `world.set_gates5_level_tax(cid,v)` | `GetGatesLevelTaxRate5` / `SetGatesLevelTaxRate5` | `world.gates5_level_tax(0)` |
| `world.sentry5_level_tax(cid)` / `world.set_sentry5_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate5` / `SetSentryTowerLevelTaxRate5` | `world.sentry5_level_tax(0)` |
| `world.well5_level_tax(cid)` / `world.set_well5_level_tax(cid,v)` | `GetWellLevelTaxRate5` / `SetWellLevelTaxRate5` | `world.well5_level_tax(0)` |
| `world.bridge5_level_tax(cid)` / `world.set_bridge5_level_tax(cid,v)` | `GetBridgeLevelTaxRate5` / `SetBridgeLevelTaxRate5` | `world.bridge5_level_tax(0)` |
| `world.wall5_level_tax(cid)` / `world.set_wall5_level_tax(cid,v)` | `GetWallLevelTaxRate5` / `SetWallLevelTaxRate5` | `world.wall5_level_tax(0)` |
| `world.tower5_level_tax(cid)` / `world.set_tower5_level_tax(cid,v)` | `GetTowerLevelTaxRate5` / `SetTowerLevelTaxRate5` | `world.tower5_level_tax(0)` |
| `world.forum5_level_tax(cid)` / `world.set_forum5_level_tax(cid,v)` | `GetForumLevelTaxRate5` / `SetForumLevelTaxRate5` | `world.forum5_level_tax(0)` |
| `world.granary5_level_tax(cid)` / `world.set_granary5_level_tax(cid,v)` | `GetGranaryLevelTaxRate5` / `SetGranaryLevelTaxRate5` | `world.granary5_level_tax(0)` |
| `world.prison5_level_tax(cid)` / `world.set_prison5_level_tax(cid,v)` | `GetPrisonLevelTaxRate5` / `SetPrisonLevelTaxRate5` | `world.prison5_level_tax(0)` |
| `world.harbor_dock5_level_tax(cid)` / `world.set_harbor_dock5_level_tax(cid,v)` | `GetHarborDockLevelTaxRate5` / `SetHarborDockLevelTaxRate5` | `world.harbor_dock5_level_tax(0)` |
| `world.guild_house5_level_tax(cid)` / `world.set_guild_house5_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate5` / `SetGuildHouseLevelTaxRate5` | `world.guild_house5_level_tax(0)` |
| `world.house5_level_tax(cid)` / `world.set_house5_level_tax(cid,v)` | `GetHouseLevelTaxRate5` / `SetHouseLevelTaxRate5` | `world.house5_level_tax(0)` |
| `world.chapel5_level_tax(cid)` / `world.set_chapel5_level_tax(cid,v)` | `GetChapelLevelTaxRate5` / `SetChapelLevelTaxRate5` | `world.chapel5_level_tax(0)` |
| `world.hospital5_level_tax(cid)` / `world.set_hospital5_level_tax(cid,v)` | `GetHospitalLevelTaxRate5` / `SetHospitalLevelTaxRate5` | `world.hospital5_level_tax(0)` |
| `world.brothel5_level_tax(cid)` / `world.set_brothel5_level_tax(cid,v)` | `GetBrothelLevelTaxRate5` / `SetBrothelLevelTaxRate5` | `world.brothel5_level_tax(0)` |
| `world.university5_level_tax(cid)` / `world.set_university5_level_tax(cid,v)` | `GetUniversityLevelTaxRate5` / `SetUniversityLevelTaxRate5` | `world.university5_level_tax(0)` |
| `world.harbor_walls5_level_tax(cid)` / `world.set_harbor_walls5_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate5` / `SetHarborWallsLevelTaxRate5` | `world.harbor_walls5_level_tax(0)` |
| `world.schoolhouse5_level_tax(cid)` / `world.set_schoolhouse5_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate5` / `SetSchoolhouseLevelTaxRate5` | `world.schoolhouse5_level_tax(0)` |
| `world.library_hall5_level_tax(cid)` / `world.set_library_hall5_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate5` / `SetLibraryHallLevelTaxRate5` | `world.library_hall5_level_tax(0)` |
| `world.barber5_level_tax(cid)` / `world.set_barber5_level_tax(cid,v)` | `GetBarberLevelTaxRate5` / `SetBarberLevelTaxRate5` | `world.barber5_level_tax(0)` |
| `world.contor6_level_tax(cid)` / `world.set_contor6_level_tax(cid,v)` | `GetContorLevelTaxRate6` / `SetContorLevelTaxRate6` | `world.contor6_level_tax(0)` |
| `world.dice_house6_level_tax(cid)` / `world.set_dice_house6_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate6` / `SetDiceHouseLevelTaxRate6` | `world.dice_house6_level_tax(0)` |
| `world.thieves6_level_tax(cid)` / `world.set_thieves6_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate6` / `SetThievesGuildLevelTaxRate6` | `world.thieves6_level_tax(0)` |
| `world.ropemaker_ws6_level_tax(cid)` / `world.set_ropemaker_ws6_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate6` / `SetRopemakerWorkshopLevelTaxRate6` | `world.ropemaker_ws6_level_tax(0)` |
| `world.tannery6_level_tax(cid)` / `world.set_tannery6_level_tax(cid,v)` | `GetTanneryLevelTaxRate6` / `SetTanneryLevelTaxRate6` | `world.tannery6_level_tax(0)` |
| `world.weaving6_level_tax(cid)` / `world.set_weaving6_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate6` / `SetWeavingMillLevelTaxRate6` | `world.weaving6_level_tax(0)` |
| `world.mint6_level_tax(cid)` / `world.set_mint6_level_tax(cid,v)` | `GetMintLevelTaxRate6` / `SetMintLevelTaxRate6` | `world.mint6_level_tax(0)` |
| `world.herb_garden6_level_tax(cid)` / `world.set_herb_garden6_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate6` / `SetHerbGardenLevelTaxRate6` | `world.herb_garden6_level_tax(0)` |
| `world.vineyard6_level_tax(cid)` / `world.set_vineyard6_level_tax(cid,v)` | `GetVineyardLevelTaxRate6` / `SetVineyardLevelTaxRate6` | `world.vineyard6_level_tax(0)` |
| `world.pottery6_level_tax(cid)` / `world.set_pottery6_level_tax(cid,v)` | `GetPotteryLevelTaxRate6` / `SetPotteryLevelTaxRate6` | `world.pottery6_level_tax(0)` |
| `world.tailor6_level_tax(cid)` / `world.set_tailor6_level_tax(cid,v)` | `GetTailorLevelTaxRate6` / `SetTailorLevelTaxRate6` | `world.tailor6_level_tax(0)` |
| `world.tavern6_level_tax(cid)` / `world.set_tavern6_level_tax(cid,v)` | `GetTavernLevelTaxRate6` / `SetTavernLevelTaxRate6` | `world.tavern6_level_tax(0)` |
| `world.apothecary6_level_tax(cid)` / `world.set_apothecary6_level_tax(cid,v)` | `GetApothecaryLevelTaxRate6` / `SetApothecaryLevelTaxRate6` | `world.apothecary6_level_tax(0)` |
| `world.goldsmith6_level_tax(cid)` / `world.set_goldsmith6_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate6` / `SetGoldsmithLevelTaxRate6` | `world.goldsmith6_level_tax(0)` |
| `world.jeweler6_level_tax(cid)` / `world.set_jeweler6_level_tax(cid,v)` | `GetJewelerLevelTaxRate6` / `SetJewelerLevelTaxRate6` | `world.jeweler6_level_tax(0)` |
| `world.perfumer6_level_tax(cid)` / `world.set_perfumer6_level_tax(cid,v)` | `GetPerfumerLevelTaxRate6` / `SetPerfumerLevelTaxRate6` | `world.perfumer6_level_tax(0)` |
| `world.soapmaker6_level_tax(cid)` / `world.set_soapmaker6_level_tax(cid,v)` | `GetSoapmakerLevelTaxRate6` / `SetSoapmakerLevelTaxRate6` | `world.soapmaker6_level_tax(0)` |
| `world.candlemaker6_level_tax(cid)` / `world.set_candlemaker6_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate6` / `SetCandlemakerLevelTaxRate6` | `world.candlemaker6_level_tax(0)` |
| `world.papermill6_level_tax(cid)` / `world.set_papermill6_level_tax(cid,v)` | `GetPapermillLevelTaxRate6` / `SetPapermillLevelTaxRate6` | `world.papermill6_level_tax(0)` |
| `world.printing6_level_tax(cid)` / `world.set_printing6_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate6` / `SetPrintingHouseLevelTaxRate6` | `world.printing6_level_tax(0)` |
| `world.toolmaker6_level_tax(cid)` / `world.set_toolmaker6_level_tax(cid,v)` | `GetToolmakerLevelTaxRate6` / `SetToolmakerLevelTaxRate6` | `world.toolmaker6_level_tax(0)` |
| `world.charcoal6_level_tax(cid)` / `world.set_charcoal6_level_tax(cid,v)` | `GetCharcoalLevelTaxRate6` / `SetCharcoalLevelTaxRate6` | `world.charcoal6_level_tax(0)` |
| `world.furrier6_level_tax(cid)` / `world.set_furrier6_level_tax(cid,v)` | `GetFurrierLevelTaxRate6` / `SetFurrierLevelTaxRate6` | `world.furrier6_level_tax(0)` |
| `world.dyer6_level_tax(cid)` / `world.set_dyer6_level_tax(cid,v)` | `GetDyerLevelTaxRate6` / `SetDyerLevelTaxRate6` | `world.dyer6_level_tax(0)` |
| `world.saddler6_level_tax(cid)` / `world.set_saddler6_level_tax(cid,v)` | `GetSaddlerLevelTaxRate6` / `SetSaddlerLevelTaxRate6` | `world.saddler6_level_tax(0)` |
| `world.armorer6_level_tax(cid)` / `world.set_armorer6_level_tax(cid,v)` | `GetArmorerLevelTaxRate6` / `SetArmorerLevelTaxRate6` | `world.armorer6_level_tax(0)` |
| `world.bowyer6_level_tax(cid)` / `world.set_bowyer6_level_tax(cid,v)` | `GetBowyerLevelTaxRate6` / `SetBowyerLevelTaxRate6` | `world.bowyer6_level_tax(0)` |
| `world.cartwright6_level_tax(cid)` / `world.set_cartwright6_level_tax(cid,v)` | `GetCartwrightLevelTaxRate6` / `SetCartwrightLevelTaxRate6` | `world.cartwright6_level_tax(0)` |
| `world.carpenter6_level_tax(cid)` / `world.set_carpenter6_level_tax(cid,v)` | `GetCarpenterLevelTaxRate6` / `SetCarpenterLevelTaxRate6` | `world.carpenter6_level_tax(0)` |
| `world.ropemaker6_level_tax(cid)` / `world.set_ropemaker6_level_tax(cid,v)` | `GetRopemakerLevelTaxRate6` / `SetRopemakerLevelTaxRate6` | `world.ropemaker6_level_tax(0)` |
| `world.cooper6_level_tax(cid)` / `world.set_cooper6_level_tax(cid,v)` | `GetCooperLevelTaxRate6` / `SetCooperLevelTaxRate6` | `world.cooper6_level_tax(0)` |
| `world.spinner6_level_tax(cid)` / `world.set_spinner6_level_tax(cid,v)` | `GetSpinnerLevelTaxRate6` / `SetSpinnerLevelTaxRate6` | `world.spinner6_level_tax(0)` |
| `world.turner6_level_tax(cid)` / `world.set_turner6_level_tax(cid,v)` | `GetTurnerLevelTaxRate6` / `SetTurnerLevelTaxRate6` | `world.turner6_level_tax(0)` |
| `world.stonecutter6_level_tax(cid)` / `world.set_stonecutter6_level_tax(cid,v)` | `GetStonecutterLevelTaxRate6` / `SetStonecutterLevelTaxRate6` | `world.stonecutter6_level_tax(0)` |
| `world.cobbler6_level_tax(cid)` / `world.set_cobbler6_level_tax(cid,v)` | `GetCobblerLevelTaxRate6` / `SetCobblerLevelTaxRate6` | `world.cobbler6_level_tax(0)` |
| `world.butcher6_level_tax(cid)` / `world.set_butcher6_level_tax(cid,v)` | `GetButcherLevelTaxRate6` / `SetButcherLevelTaxRate6` | `world.butcher6_level_tax(0)` |
| `world.baker6_level_tax(cid)` / `world.set_baker6_level_tax(cid,v)` | `GetBakerLevelTaxRate6` / `SetBakerLevelTaxRate6` | `world.baker6_level_tax(0)` |
| `world.shepherd6_level_tax(cid)` / `world.set_shepherd6_level_tax(cid,v)` | `GetShepherdLevelTaxRate6` / `SetShepherdLevelTaxRate6` | `world.shepherd6_level_tax(0)` |
| `world.dairy6_level_tax(cid)` / `world.set_dairy6_level_tax(cid,v)` | `GetDairyLevelTaxRate6` / `SetDairyLevelTaxRate6` | `world.dairy6_level_tax(0)` |
| `world.brewmaster6_level_tax(cid)` / `world.set_brewmaster6_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate6` / `SetBrewmasterLevelTaxRate6` | `world.brewmaster6_level_tax(0)` |
| `world.miller6_level_tax(cid)` / `world.set_miller6_level_tax(cid,v)` | `GetMillerLevelTaxRate6` / `SetMillerLevelTaxRate6` | `world.miller6_level_tax(0)` |
| `world.fishery6_level_tax(cid)` / `world.set_fishery6_level_tax(cid,v)` | `GetFisheryLevelTaxRate6` / `SetFisheryLevelTaxRate6` | `world.fishery6_level_tax(0)` |
| `world.chandler6_level_tax(cid)` / `world.set_chandler6_level_tax(cid,v)` | `GetChandlerLevelTaxRate6` / `SetChandlerLevelTaxRate6` | `world.chandler6_level_tax(0)` |
| `world.goldbeater6_level_tax(cid)` / `world.set_goldbeater6_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate6` / `SetGoldbeaterLevelTaxRate6` | `world.goldbeater6_level_tax(0)` |
| `world.potter6_level_tax(cid)` / `world.set_potter6_level_tax(cid,v)` | `GetPotterLevelTaxRate6` / `SetPotterLevelTaxRate6` | `world.potter6_level_tax(0)` |
| `world.fowler6_level_tax(cid)` / `world.set_fowler6_level_tax(cid,v)` | `GetFowlerLevelTaxRate6` / `SetFowlerLevelTaxRate6` | `world.fowler6_level_tax(0)` |
| `world.vintner6_level_tax(cid)` / `world.set_vintner6_level_tax(cid,v)` | `GetVintnerLevelTaxRate6` / `SetVintnerLevelTaxRate6` | `world.vintner6_level_tax(0)` |
| `world.distiller6_level_tax(cid)` / `world.set_distiller6_level_tax(cid,v)` | `GetDistillerLevelTaxRate6` / `SetDistillerLevelTaxRate6` | `world.distiller6_level_tax(0)` |
| `world.cook6_level_tax(cid)` / `world.set_cook6_level_tax(cid,v)` | `GetCookLevelTaxRate6` / `SetCookLevelTaxRate6` | `world.cook6_level_tax(0)` |
| `world.brickmaker6_level_tax(cid)` / `world.set_brickmaker6_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate6` / `SetBrickmakerLevelTaxRate6` | `world.brickmaker6_level_tax(0)` |
| `world.bathhouse6_level_tax(cid)` / `world.set_bathhouse6_level_tax(cid,v)` | `GetBathhouseLevelTaxRate6` / `SetBathhouseLevelTaxRate6` | `world.bathhouse6_level_tax(0)` |
| `world.barracks11_level_tax(cid)` / `world.set_barracks11_level_tax(cid,v)` | `GetBarracksLevelTaxRate11` / `SetBarracksLevelTaxRate11` | `world.barracks11_level_tax(0)` |
| `world.school6_level_tax(cid)` / `world.set_school6_level_tax(cid,v)` | `GetSchoolLevelTaxRate6` / `SetSchoolLevelTaxRate6` | `world.school6_level_tax(0)` |
| `world.library6_level_tax(cid)` / `world.set_library6_level_tax(cid,v)` | `GetLibraryLevelTaxRate6` / `SetLibraryLevelTaxRate6` | `world.library6_level_tax(0)` |
| `world.mine6_level_tax(cid)` / `world.set_mine6_level_tax(cid,v)` | `GetMineLevelTaxRate6` / `SetMineLevelTaxRate6` | `world.mine6_level_tax(0)` |
| `world.warehouse6_level_tax(cid)` / `world.set_warehouse6_level_tax(cid,v)` | `GetWarehouseLevelTaxRate6` / `SetWarehouseLevelTaxRate6` | `world.warehouse6_level_tax(0)` |
| `world.garrison6_level_tax(cid)` / `world.set_garrison6_level_tax(cid,v)` | `GetGarrisonLevelTaxRate6` / `SetGarrisonLevelTaxRate6` | `world.garrison6_level_tax(0)` |
| `world.monastery6_level_tax(cid)` / `world.set_monastery6_level_tax(cid,v)` | `GetMonasteryLevelTaxRate6` / `SetMonasteryLevelTaxRate6` | `world.monastery6_level_tax(0)` |
| `world.cathedral6_level_tax(cid)` / `world.set_cathedral6_level_tax(cid,v)` | `GetCathedralLevelTaxRate6` / `SetCathedralLevelTaxRate6` | `world.cathedral6_level_tax(0)` |
| `world.town_hall6_level_tax(cid)` / `world.set_town_hall6_level_tax(cid,v)` | `GetTownHallLevelTaxRate6` / `SetTownHallLevelTaxRate6` | `world.town_hall6_level_tax(0)` |
| `world.market6_level_tax(cid)` / `world.set_market6_level_tax(cid,v)` | `GetMarketLevelTaxRate6` / `SetMarketLevelTaxRate6` | `world.market6_level_tax(0)` |
| `world.harbor6_level_tax(cid)` / `world.set_harbor6_level_tax(cid,v)` | `GetHarborLevelTaxRate6` / `SetHarborLevelTaxRate6` | `world.harbor6_level_tax(0)` |
| `world.guardhouse6_level_tax(cid)` / `world.set_guardhouse6_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate6` / `SetGuardhouseLevelTaxRate6` | `world.guardhouse6_level_tax(0)` |
| `world.courthouse6_level_tax(cid)` / `world.set_courthouse6_level_tax(cid,v)` | `GetCourthouseLevelTaxRate6` / `SetCourthouseLevelTaxRate6` | `world.courthouse6_level_tax(0)` |
| `world.univ_hall6_level_tax(cid)` / `world.set_univ_hall6_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate6` / `SetUniversityHallLevelTaxRate6` | `world.univ_hall6_level_tax(0)` |
| `world.castle6_level_tax(cid)` / `world.set_castle6_level_tax(cid,v)` | `GetCastleLevelTaxRate6` / `SetCastleLevelTaxRate6` | `world.castle6_level_tax(0)` |
| `world.barracks12_level_tax(cid)` / `world.set_barracks12_level_tax(cid,v)` | `GetBarracksLevelTaxRate12` / `SetBarracksLevelTaxRate12` | `world.barracks12_level_tax(0)` |
| `world.stables6_level_tax(cid)` / `world.set_stables6_level_tax(cid,v)` | `GetStablesLevelTaxRate6` / `SetStablesLevelTaxRate6` | `world.stables6_level_tax(0)` |
| `world.gates6_level_tax(cid)` / `world.set_gates6_level_tax(cid,v)` | `GetGatesLevelTaxRate6` / `SetGatesLevelTaxRate6` | `world.gates6_level_tax(0)` |
| `world.sentry6_level_tax(cid)` / `world.set_sentry6_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate6` / `SetSentryTowerLevelTaxRate6` | `world.sentry6_level_tax(0)` |
| `world.well6_level_tax(cid)` / `world.set_well6_level_tax(cid,v)` | `GetWellLevelTaxRate6` / `SetWellLevelTaxRate6` | `world.well6_level_tax(0)` |
| `world.bridge6_level_tax(cid)` / `world.set_bridge6_level_tax(cid,v)` | `GetBridgeLevelTaxRate6` / `SetBridgeLevelTaxRate6` | `world.bridge6_level_tax(0)` |
| `world.wall6_level_tax(cid)` / `world.set_wall6_level_tax(cid,v)` | `GetWallLevelTaxRate6` / `SetWallLevelTaxRate6` | `world.wall6_level_tax(0)` |
| `world.tower6_level_tax(cid)` / `world.set_tower6_level_tax(cid,v)` | `GetTowerLevelTaxRate6` / `SetTowerLevelTaxRate6` | `world.tower6_level_tax(0)` |
| `world.forum6_level_tax(cid)` / `world.set_forum6_level_tax(cid,v)` | `GetForumLevelTaxRate6` / `SetForumLevelTaxRate6` | `world.forum6_level_tax(0)` |
| `world.granary6_level_tax(cid)` / `world.set_granary6_level_tax(cid,v)` | `GetGranaryLevelTaxRate6` / `SetGranaryLevelTaxRate6` | `world.granary6_level_tax(0)` |
| `world.prison6_level_tax(cid)` / `world.set_prison6_level_tax(cid,v)` | `GetPrisonLevelTaxRate6` / `SetPrisonLevelTaxRate6` | `world.prison6_level_tax(0)` |
| `world.harbor_dock6_level_tax(cid)` / `world.set_harbor_dock6_level_tax(cid,v)` | `GetHarborDockLevelTaxRate6` / `SetHarborDockLevelTaxRate6` | `world.harbor_dock6_level_tax(0)` |
| `world.guild_house6_level_tax(cid)` / `world.set_guild_house6_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate6` / `SetGuildHouseLevelTaxRate6` | `world.guild_house6_level_tax(0)` |
| `world.house6_level_tax(cid)` / `world.set_house6_level_tax(cid,v)` | `GetHouseLevelTaxRate6` / `SetHouseLevelTaxRate6` | `world.house6_level_tax(0)` |
| `world.chapel6_level_tax(cid)` / `world.set_chapel6_level_tax(cid,v)` | `GetChapelLevelTaxRate6` / `SetChapelLevelTaxRate6` | `world.chapel6_level_tax(0)` |
| `world.hospital6_level_tax(cid)` / `world.set_hospital6_level_tax(cid,v)` | `GetHospitalLevelTaxRate6` / `SetHospitalLevelTaxRate6` | `world.hospital6_level_tax(0)` |
| `world.brothel6_level_tax(cid)` / `world.set_brothel6_level_tax(cid,v)` | `GetBrothelLevelTaxRate6` / `SetBrothelLevelTaxRate6` | `world.brothel6_level_tax(0)` |
| `world.university6_level_tax(cid)` / `world.set_university6_level_tax(cid,v)` | `GetUniversityLevelTaxRate6` / `SetUniversityLevelTaxRate6` | `world.university6_level_tax(0)` |
| `world.harbor_walls6_level_tax(cid)` / `world.set_harbor_walls6_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate6` / `SetHarborWallsLevelTaxRate6` | `world.harbor_walls6_level_tax(0)` |
| `world.schoolhouse6_level_tax(cid)` / `world.set_schoolhouse6_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate6` / `SetSchoolhouseLevelTaxRate6` | `world.schoolhouse6_level_tax(0)` |
| `world.library_hall6_level_tax(cid)` / `world.set_library_hall6_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate6` / `SetLibraryHallLevelTaxRate6` | `world.library_hall6_level_tax(0)` |
| `world.barber6_level_tax(cid)` / `world.set_barber6_level_tax(cid,v)` | `GetBarberLevelTaxRate6` / `SetBarberLevelTaxRate6` | `world.barber6_level_tax(0)` |
| `world.contor7_level_tax(cid)` / `world.set_contor7_level_tax(cid,v)` | `GetContorLevelTaxRate7` / `SetContorLevelTaxRate7` | `world.contor7_level_tax(0)` |
| `world.dice_house7_level_tax(cid)` / `world.set_dice_house7_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate7` / `SetDiceHouseLevelTaxRate7` | `world.dice_house7_level_tax(0)` |
| `world.thieves7_level_tax(cid)` / `world.set_thieves7_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate7` / `SetThievesGuildLevelTaxRate7` | `world.thieves7_level_tax(0)` |
| `world.ropemaker_ws7_level_tax(cid)` / `world.set_ropemaker_ws7_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate7` / `SetRopemakerWorkshopLevelTaxRate7` | `world.ropemaker_ws7_level_tax(0)` |
| `world.tannery7_level_tax(cid)` / `world.set_tannery7_level_tax(cid,v)` | `GetTanneryLevelTaxRate7` / `SetTanneryLevelTaxRate7` | `world.tannery7_level_tax(0)` |
| `world.weaving7_level_tax(cid)` / `world.set_weaving7_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate7` / `SetWeavingMillLevelTaxRate7` | `world.weaving7_level_tax(0)` |
| `world.mint7_level_tax(cid)` / `world.set_mint7_level_tax(cid,v)` | `GetMintLevelTaxRate7` / `SetMintLevelTaxRate7` | `world.mint7_level_tax(0)` |
| `world.herb_garden7_level_tax(cid)` / `world.set_herb_garden7_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate7` / `SetHerbGardenLevelTaxRate7` | `world.herb_garden7_level_tax(0)` |
| `world.vineyard7_level_tax(cid)` / `world.set_vineyard7_level_tax(cid,v)` | `GetVineyardLevelTaxRate7` / `SetVineyardLevelTaxRate7` | `world.vineyard7_level_tax(0)` |
| `world.pottery7_level_tax(cid)` / `world.set_pottery7_level_tax(cid,v)` | `GetPotteryLevelTaxRate7` / `SetPotteryLevelTaxRate7` | `world.pottery7_level_tax(0)` |
| `world.tailor7_level_tax(cid)` / `world.set_tailor7_level_tax(cid,v)` | `GetTailorLevelTaxRate7` / `SetTailorLevelTaxRate7` | `world.tailor7_level_tax(0)` |
| `world.tavern7_level_tax(cid)` / `world.set_tavern7_level_tax(cid,v)` | `GetTavernLevelTaxRate7` / `SetTavernLevelTaxRate7` | `world.tavern7_level_tax(0)` |
| `world.apothecary7_level_tax(cid)` / `world.set_apothecary7_level_tax(cid,v)` | `GetApothecaryLevelTaxRate7` / `SetApothecaryLevelTaxRate7` | `world.apothecary7_level_tax(0)` |
| `world.goldsmith7_level_tax(cid)` / `world.set_goldsmith7_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate7` / `SetGoldsmithLevelTaxRate7` | `world.goldsmith7_level_tax(0)` |
| `world.jeweler7_level_tax(cid)` / `world.set_jeweler7_level_tax(cid,v)` | `GetJewelerLevelTaxRate7` / `SetJewelerLevelTaxRate7` | `world.jeweler7_level_tax(0)` |
| `world.perfumer7_level_tax(cid)` / `world.set_perfumer7_level_tax(cid,v)` | `GetPerfumerLevelTaxRate7` / `SetPerfumerLevelTaxRate7` | `world.perfumer7_level_tax(0)` |
| `world.soapmaker7_level_tax(cid)` / `world.set_soapmaker7_level_tax(cid,v)` | `GetSoapmakerLevelTaxRate7` / `SetSoapmakerLevelTaxRate7` | `world.soapmaker7_level_tax(0)` |
| `world.candlemaker7_level_tax(cid)` / `world.set_candlemaker7_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate7` / `SetCandlemakerLevelTaxRate7` | `world.candlemaker7_level_tax(0)` |
| `world.papermill7_level_tax(cid)` / `world.set_papermill7_level_tax(cid,v)` | `GetPapermillLevelTaxRate7` / `SetPapermillLevelTaxRate7` | `world.papermill7_level_tax(0)` |
| `world.printing7_level_tax(cid)` / `world.set_printing7_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate7` / `SetPrintingHouseLevelTaxRate7` | `world.printing7_level_tax(0)` |
| `world.toolmaker7_level_tax(cid)` / `world.set_toolmaker7_level_tax(cid,v)` | `GetToolmakerLevelTaxRate7` / `SetToolmakerLevelTaxRate7` | `world.toolmaker7_level_tax(0)` |
| `world.charcoal7_level_tax(cid)` / `world.set_charcoal7_level_tax(cid,v)` | `GetCharcoalLevelTaxRate7` / `SetCharcoalLevelTaxRate7` | `world.charcoal7_level_tax(0)` |
| `world.furrier7_level_tax(cid)` / `world.set_furrier7_level_tax(cid,v)` | `GetFurrierLevelTaxRate7` / `SetFurrierLevelTaxRate7` | `world.furrier7_level_tax(0)` |
| `world.dyer7_level_tax(cid)` / `world.set_dyer7_level_tax(cid,v)` | `GetDyerLevelTaxRate7` / `SetDyerLevelTaxRate7` | `world.dyer7_level_tax(0)` |
| `world.saddler7_level_tax(cid)` / `world.set_saddler7_level_tax(cid,v)` | `GetSaddlerLevelTaxRate7` / `SetSaddlerLevelTaxRate7` | `world.saddler7_level_tax(0)` |
| `world.armorer7_level_tax(cid)` / `world.set_armorer7_level_tax(cid,v)` | `GetArmorerLevelTaxRate7` / `SetArmorerLevelTaxRate7` | `world.armorer7_level_tax(0)` |
| `world.bowyer7_level_tax(cid)` / `world.set_bowyer7_level_tax(cid,v)` | `GetBowyerLevelTaxRate7` / `SetBowyerLevelTaxRate7` | `world.bowyer7_level_tax(0)` |
| `world.cartwright7_level_tax(cid)` / `world.set_cartwright7_level_tax(cid,v)` | `GetCartwrightLevelTaxRate7` / `SetCartwrightLevelTaxRate7` | `world.cartwright7_level_tax(0)` |
| `world.carpenter7_level_tax(cid)` / `world.set_carpenter7_level_tax(cid,v)` | `GetCarpenterLevelTaxRate7` / `SetCarpenterLevelTaxRate7` | `world.carpenter7_level_tax(0)` |
| `world.ropemaker7_level_tax(cid)` / `world.set_ropemaker7_level_tax(cid,v)` | `GetRopemakerLevelTaxRate7` / `SetRopemakerLevelTaxRate7` | `world.ropemaker7_level_tax(0)` |
| `world.cooper7_level_tax(cid)` / `world.set_cooper7_level_tax(cid,v)` | `GetCooperLevelTaxRate7` / `SetCooperLevelTaxRate7` | `world.cooper7_level_tax(0)` |
| `world.spinner7_level_tax(cid)` / `world.set_spinner7_level_tax(cid,v)` | `GetSpinnerLevelTaxRate7` / `SetSpinnerLevelTaxRate7` | `world.spinner7_level_tax(0)` |
| `world.turner7_level_tax(cid)` / `world.set_turner7_level_tax(cid,v)` | `GetTurnerLevelTaxRate7` / `SetTurnerLevelTaxRate7` | `world.turner7_level_tax(0)` |
| `world.stonecutter7_level_tax(cid)` / `world.set_stonecutter7_level_tax(cid,v)` | `GetStonecutterLevelTaxRate7` / `SetStonecutterLevelTaxRate7` | `world.stonecutter7_level_tax(0)` |
| `world.cobbler7_level_tax(cid)` / `world.set_cobbler7_level_tax(cid,v)` | `GetCobblerLevelTaxRate7` / `SetCobblerLevelTaxRate7` | `world.cobbler7_level_tax(0)` |
| `world.butcher7_level_tax(cid)` / `world.set_butcher7_level_tax(cid,v)` | `GetButcherLevelTaxRate7` / `SetButcherLevelTaxRate7` | `world.butcher7_level_tax(0)` |
| `world.baker7_level_tax(cid)` / `world.set_baker7_level_tax(cid,v)` | `GetBakerLevelTaxRate7` / `SetBakerLevelTaxRate7` | `world.baker7_level_tax(0)` |
| `world.shepherd7_level_tax(cid)` / `world.set_shepherd7_level_tax(cid,v)` | `GetShepherdLevelTaxRate7` / `SetShepherdLevelTaxRate7` | `world.shepherd7_level_tax(0)` |
| `world.dairy7_level_tax(cid)` / `world.set_dairy7_level_tax(cid,v)` | `GetDairyLevelTaxRate7` / `SetDairyLevelTaxRate7` | `world.dairy7_level_tax(0)` |
| `world.brewmaster7_level_tax(cid)` / `world.set_brewmaster7_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate7` / `SetBrewmasterLevelTaxRate7` | `world.brewmaster7_level_tax(0)` |
| `world.miller7_level_tax(cid)` / `world.set_miller7_level_tax(cid,v)` | `GetMillerLevelTaxRate7` / `SetMillerLevelTaxRate7` | `world.miller7_level_tax(0)` |
| `world.fishery7_level_tax(cid)` / `world.set_fishery7_level_tax(cid,v)` | `GetFisheryLevelTaxRate7` / `SetFisheryLevelTaxRate7` | `world.fishery7_level_tax(0)` |
| `world.chandler7_level_tax(cid)` / `world.set_chandler7_level_tax(cid,v)` | `GetChandlerLevelTaxRate7` / `SetChandlerLevelTaxRate7` | `world.chandler7_level_tax(0)` |
| `world.goldbeater7_level_tax(cid)` / `world.set_goldbeater7_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate7` / `SetGoldbeaterLevelTaxRate7` | `world.goldbeater7_level_tax(0)` |
| `world.potter7_level_tax(cid)` / `world.set_potter7_level_tax(cid,v)` | `GetPotterLevelTaxRate7` / `SetPotterLevelTaxRate7` | `world.potter7_level_tax(0)` |
| `world.fowler7_level_tax(cid)` / `world.set_fowler7_level_tax(cid,v)` | `GetFowlerLevelTaxRate7` / `SetFowlerLevelTaxRate7` | `world.fowler7_level_tax(0)` |
| `world.vintner7_level_tax(cid)` / `world.set_vintner7_level_tax(cid,v)` | `GetVintnerLevelTaxRate7` / `SetVintnerLevelTaxRate7` | `world.vintner7_level_tax(0)` |
| `world.distiller7_level_tax(cid)` / `world.set_distiller7_level_tax(cid,v)` | `GetDistillerLevelTaxRate7` / `SetDistillerLevelTaxRate7` | `world.distiller7_level_tax(0)` |
| `world.cook7_level_tax(cid)` / `world.set_cook7_level_tax(cid,v)` | `GetCookLevelTaxRate7` / `SetCookLevelTaxRate7` | `world.cook7_level_tax(0)` |
| `world.brickmaker7_level_tax(cid)` / `world.set_brickmaker7_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate7` / `SetBrickmakerLevelTaxRate7` | `world.brickmaker7_level_tax(0)` |
| `world.bathhouse7_level_tax(cid)` / `world.set_bathhouse7_level_tax(cid,v)` | `GetBathhouseLevelTaxRate7` / `SetBathhouseLevelTaxRate7` | `world.bathhouse7_level_tax(0)` |
| `world.barracks13_level_tax(cid)` / `world.set_barracks13_level_tax(cid,v)` | `GetBarracksLevelTaxRate13` / `SetBarracksLevelTaxRate13` | `world.barracks13_level_tax(0)` |
| `world.school7_level_tax(cid)` / `world.set_school7_level_tax(cid,v)` | `GetSchoolLevelTaxRate7` / `SetSchoolLevelTaxRate7` | `world.school7_level_tax(0)` |
| `world.library7_level_tax(cid)` / `world.set_library7_level_tax(cid,v)` | `GetLibraryLevelTaxRate7` / `SetLibraryLevelTaxRate7` | `world.library7_level_tax(0)` |
| `world.mine7_level_tax(cid)` / `world.set_mine7_level_tax(cid,v)` | `GetMineLevelTaxRate7` / `SetMineLevelTaxRate7` | `world.mine7_level_tax(0)` |
| `world.warehouse7_level_tax(cid)` / `world.set_warehouse7_level_tax(cid,v)` | `GetWarehouseLevelTaxRate7` / `SetWarehouseLevelTaxRate7` | `world.warehouse7_level_tax(0)` |
| `world.garrison7_level_tax(cid)` / `world.set_garrison7_level_tax(cid,v)` | `GetGarrisonLevelTaxRate7` / `SetGarrisonLevelTaxRate7` | `world.garrison7_level_tax(0)` |
| `world.monastery7_level_tax(cid)` / `world.set_monastery7_level_tax(cid,v)` | `GetMonasteryLevelTaxRate7` / `SetMonasteryLevelTaxRate7` | `world.monastery7_level_tax(0)` |
| `world.cathedral7_level_tax(cid)` / `world.set_cathedral7_level_tax(cid,v)` | `GetCathedralLevelTaxRate7` / `SetCathedralLevelTaxRate7` | `world.cathedral7_level_tax(0)` |
| `world.town_hall7_level_tax(cid)` / `world.set_town_hall7_level_tax(cid,v)` | `GetTownHallLevelTaxRate7` / `SetTownHallLevelTaxRate7` | `world.town_hall7_level_tax(0)` |
| `world.market7_level_tax(cid)` / `world.set_market7_level_tax(cid,v)` | `GetMarketLevelTaxRate7` / `SetMarketLevelTaxRate7` | `world.market7_level_tax(0)` |
| `world.harbor7_level_tax(cid)` / `world.set_harbor7_level_tax(cid,v)` | `GetHarborLevelTaxRate7` / `SetHarborLevelTaxRate7` | `world.harbor7_level_tax(0)` |
| `world.guardhouse7_level_tax(cid)` / `world.set_guardhouse7_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate7` / `SetGuardhouseLevelTaxRate7` | `world.guardhouse7_level_tax(0)` |
| `world.courthouse7_level_tax(cid)` / `world.set_courthouse7_level_tax(cid,v)` | `GetCourthouseLevelTaxRate7` / `SetCourthouseLevelTaxRate7` | `world.courthouse7_level_tax(0)` |
| `world.univ_hall7_level_tax(cid)` / `world.set_univ_hall7_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate7` / `SetUniversityHallLevelTaxRate7` | `world.univ_hall7_level_tax(0)` |
| `world.castle7_level_tax(cid)` / `world.set_castle7_level_tax(cid,v)` | `GetCastleLevelTaxRate7` / `SetCastleLevelTaxRate7` | `world.castle7_level_tax(0)` |
| `world.barracks14_level_tax(cid)` / `world.set_barracks14_level_tax(cid,v)` | `GetBarracksLevelTaxRate14` / `SetBarracksLevelTaxRate14` | `world.barracks14_level_tax(0)` |
| `world.stables7_level_tax(cid)` / `world.set_stables7_level_tax(cid,v)` | `GetStablesLevelTaxRate7` / `SetStablesLevelTaxRate7` | `world.stables7_level_tax(0)` |
| `world.gates7_level_tax(cid)` / `world.set_gates7_level_tax(cid,v)` | `GetGatesLevelTaxRate7` / `SetGatesLevelTaxRate7` | `world.gates7_level_tax(0)` |
| `world.sentry7_level_tax(cid)` / `world.set_sentry7_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate7` / `SetSentryTowerLevelTaxRate7` | `world.sentry7_level_tax(0)` |
| `world.well7_level_tax(cid)` / `world.set_well7_level_tax(cid,v)` | `GetWellLevelTaxRate7` / `SetWellLevelTaxRate7` | `world.well7_level_tax(0)` |
| `world.bridge7_level_tax(cid)` / `world.set_bridge7_level_tax(cid,v)` | `GetBridgeLevelTaxRate7` / `SetBridgeLevelTaxRate7` | `world.bridge7_level_tax(0)` |
| `world.wall7_level_tax(cid)` / `world.set_wall7_level_tax(cid,v)` | `GetWallLevelTaxRate7` / `SetWallLevelTaxRate7` | `world.wall7_level_tax(0)` |
| `world.tower7_level_tax(cid)` / `world.set_tower7_level_tax(cid,v)` | `GetTowerLevelTaxRate7` / `SetTowerLevelTaxRate7` | `world.tower7_level_tax(0)` |
| `world.forum7_level_tax(cid)` / `world.set_forum7_level_tax(cid,v)` | `GetForumLevelTaxRate7` / `SetForumLevelTaxRate7` | `world.forum7_level_tax(0)` |
| `world.granary7_level_tax(cid)` / `world.set_granary7_level_tax(cid,v)` | `GetGranaryLevelTaxRate7` / `SetGranaryLevelTaxRate7` | `world.granary7_level_tax(0)` |
| `world.prison7_level_tax(cid)` / `world.set_prison7_level_tax(cid,v)` | `GetPrisonLevelTaxRate7` / `SetPrisonLevelTaxRate7` | `world.prison7_level_tax(0)` |
| `world.harbor_dock7_level_tax(cid)` / `world.set_harbor_dock7_level_tax(cid,v)` | `GetHarborDockLevelTaxRate7` / `SetHarborDockLevelTaxRate7` | `world.harbor_dock7_level_tax(0)` |
| `world.guild_house7_level_tax(cid)` / `world.set_guild_house7_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate7` / `SetGuildHouseLevelTaxRate7` | `world.guild_house7_level_tax(0)` |
| `world.house7_level_tax(cid)` / `world.set_house7_level_tax(cid,v)` | `GetHouseLevelTaxRate7` / `SetHouseLevelTaxRate7` | `world.house7_level_tax(0)` |
| `world.chapel7_level_tax(cid)` / `world.set_chapel7_level_tax(cid,v)` | `GetChapelLevelTaxRate7` / `SetChapelLevelTaxRate7` | `world.chapel7_level_tax(0)` |
| `world.hospital7_level_tax(cid)` / `world.set_hospital7_level_tax(cid,v)` | `GetHospitalLevelTaxRate7` / `SetHospitalLevelTaxRate7` | `world.hospital7_level_tax(0)` |
| `world.brothel7_level_tax(cid)` / `world.set_brothel7_level_tax(cid,v)` | `GetBrothelLevelTaxRate7` / `SetBrothelLevelTaxRate7` | `world.brothel7_level_tax(0)` |
| `world.university7_level_tax(cid)` / `world.set_university7_level_tax(cid,v)` | `GetUniversityLevelTaxRate7` / `SetUniversityLevelTaxRate7` | `world.university7_level_tax(0)` |
| `world.harbor_walls7_level_tax(cid)` / `world.set_harbor_walls7_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate7` / `SetHarborWallsLevelTaxRate7` | `world.harbor_walls7_level_tax(0)` |
| `world.schoolhouse7_level_tax(cid)` / `world.set_schoolhouse7_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate7` / `SetSchoolhouseLevelTaxRate7` | `world.schoolhouse7_level_tax(0)` |
| `world.library_hall7_level_tax(cid)` / `world.set_library_hall7_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate7` / `SetLibraryHallLevelTaxRate7` | `world.library_hall7_level_tax(0)` |
| `world.barber7_level_tax(cid)` / `world.set_barber7_level_tax(cid,v)` | `GetBarberLevelTaxRate7` / `SetBarberLevelTaxRate7` | `world.barber7_level_tax(0)` |
| `world.contor8_level_tax(cid)` / `world.set_contor8_level_tax(cid,v)` | `GetContorLevelTaxRate8` / `SetContorLevelTaxRate8` | `world.contor8_level_tax(0)` |
| `world.dice_house8_level_tax(cid)` / `world.set_dice_house8_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate8` / `SetDiceHouseLevelTaxRate8` | `world.dice_house8_level_tax(0)` |
| `world.thieves8_level_tax(cid)` / `world.set_thieves8_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate8` / `SetThievesGuildLevelTaxRate8` | `world.thieves8_level_tax(0)` |
| `world.ropemaker_ws8_level_tax(cid)` / `world.set_ropemaker_ws8_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate8` / `SetRopemakerWorkshopLevelTaxRate8` | `world.ropemaker_ws8_level_tax(0)` |
| `world.tannery8_level_tax(cid)` / `world.set_tannery8_level_tax(cid,v)` | `GetTanneryLevelTaxRate8` / `SetTanneryLevelTaxRate8` | `world.tannery8_level_tax(0)` |
| `world.weaving8_level_tax(cid)` / `world.set_weaving8_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate8` / `SetWeavingMillLevelTaxRate8` | `world.weaving8_level_tax(0)` |
| `world.mint8_level_tax(cid)` / `world.set_mint8_level_tax(cid,v)` | `GetMintLevelTaxRate8` / `SetMintLevelTaxRate8` | `world.mint8_level_tax(0)` |
| `world.herb_garden8_level_tax(cid)` / `world.set_herb_garden8_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate8` / `SetHerbGardenLevelTaxRate8` | `world.herb_garden8_level_tax(0)` |
| `world.vineyard8_level_tax(cid)` / `world.set_vineyard8_level_tax(cid,v)` | `GetVineyardLevelTaxRate8` / `SetVineyardLevelTaxRate8` | `world.vineyard8_level_tax(0)` |
| `world.pottery8_level_tax(cid)` / `world.set_pottery8_level_tax(cid,v)` | `GetPotteryLevelTaxRate8` / `SetPotteryLevelTaxRate8` | `world.pottery8_level_tax(0)` |
| `world.tailor8_level_tax(cid)` / `world.set_tailor8_level_tax(cid,v)` | `GetTailorLevelTaxRate8` / `SetTailorLevelTaxRate8` | `world.tailor8_level_tax(0)` |
| `world.tavern8_level_tax(cid)` / `world.set_tavern8_level_tax(cid,v)` | `GetTavernLevelTaxRate8` / `SetTavernLevelTaxRate8` | `world.tavern8_level_tax(0)` |
| `world.apothecary8_level_tax(cid)` / `world.set_apothecary8_level_tax(cid,v)` | `GetApothecaryLevelTaxRate8` / `SetApothecaryLevelTaxRate8` | `world.apothecary8_level_tax(0)` |
| `world.goldsmith8_level_tax(cid)` / `world.set_goldsmith8_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate8` / `SetGoldsmithLevelTaxRate8` | `world.goldsmith8_level_tax(0)` |
| `world.jeweler8_level_tax(cid)` / `world.set_jeweler8_level_tax(cid,v)` | `GetJewelerLevelTaxRate8` / `SetJewelerLevelTaxRate8` | `world.jeweler8_level_tax(0)` |
| `world.perfumer8_level_tax(cid)` / `world.set_perfumer8_level_tax(cid,v)` | `GetPerfumerLevelTaxRate8` / `SetPerfumerLevelTaxRate8` | `world.perfumer8_level_tax(0)` |
| `world.soapmaker8_level_tax(cid)` / `world.set_soapmaker8_level_tax(cid,v)` | `GetSoapmakerLevelTaxRate8` / `SetSoapmakerLevelTaxRate8` | `world.soapmaker8_level_tax(0)` |
| `world.candlemaker8_level_tax(cid)` / `world.set_candlemaker8_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate8` / `SetCandlemakerLevelTaxRate8` | `world.candlemaker8_level_tax(0)` |
| `world.papermill8_level_tax(cid)` / `world.set_papermill8_level_tax(cid,v)` | `GetPapermillLevelTaxRate8` / `SetPapermillLevelTaxRate8` | `world.papermill8_level_tax(0)` |
| `world.printing8_level_tax(cid)` / `world.set_printing8_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate8` / `SetPrintingHouseLevelTaxRate8` | `world.printing8_level_tax(0)` |
| `world.toolmaker8_level_tax(cid)` / `world.set_toolmaker8_level_tax(cid,v)` | `GetToolmakerLevelTaxRate8` / `SetToolmakerLevelTaxRate8` | `world.toolmaker8_level_tax(0)` |
| `world.charcoal8_level_tax(cid)` / `world.set_charcoal8_level_tax(cid,v)` | `GetCharcoalLevelTaxRate8` / `SetCharcoalLevelTaxRate8` | `world.charcoal8_level_tax(0)` |
| `world.furrier8_level_tax(cid)` / `world.set_furrier8_level_tax(cid,v)` | `GetFurrierLevelTaxRate8` / `SetFurrierLevelTaxRate8` | `world.furrier8_level_tax(0)` |
| `world.dyer8_level_tax(cid)` / `world.set_dyer8_level_tax(cid,v)` | `GetDyerLevelTaxRate8` / `SetDyerLevelTaxRate8` | `world.dyer8_level_tax(0)` |
| `world.saddler8_level_tax(cid)` / `world.set_saddler8_level_tax(cid,v)` | `GetSaddlerLevelTaxRate8` / `SetSaddlerLevelTaxRate8` | `world.saddler8_level_tax(0)` |
| `world.armorer8_level_tax(cid)` / `world.set_armorer8_level_tax(cid,v)` | `GetArmorerLevelTaxRate8` / `SetArmorerLevelTaxRate8` | `world.armorer8_level_tax(0)` |
| `world.bowyer8_level_tax(cid)` / `world.set_bowyer8_level_tax(cid,v)` | `GetBowyerLevelTaxRate8` / `SetBowyerLevelTaxRate8` | `world.bowyer8_level_tax(0)` |
| `world.cartwright8_level_tax(cid)` / `world.set_cartwright8_level_tax(cid,v)` | `GetCartwrightLevelTaxRate8` / `SetCartwrightLevelTaxRate8` | `world.cartwright8_level_tax(0)` |
| `world.carpenter8_level_tax(cid)` / `world.set_carpenter8_level_tax(cid,v)` | `GetCarpenterLevelTaxRate8` / `SetCarpenterLevelTaxRate8` | `world.carpenter8_level_tax(0)` |
| `world.ropemaker8_level_tax(cid)` / `world.set_ropemaker8_level_tax(cid,v)` | `GetRopemakerLevelTaxRate8` / `SetRopemakerLevelTaxRate8` | `world.ropemaker8_level_tax(0)` |
| `world.cooper8_level_tax(cid)` / `world.set_cooper8_level_tax(cid,v)` | `GetCooperLevelTaxRate8` / `SetCooperLevelTaxRate8` | `world.cooper8_level_tax(0)` |
| `world.spinner8_level_tax(cid)` / `world.set_spinner8_level_tax(cid,v)` | `GetSpinnerLevelTaxRate8` / `SetSpinnerLevelTaxRate8` | `world.spinner8_level_tax(0)` |
| `world.turner8_level_tax(cid)` / `world.set_turner8_level_tax(cid,v)` | `GetTurnerLevelTaxRate8` / `SetTurnerLevelTaxRate8` | `world.turner8_level_tax(0)` |
| `world.stonecutter8_level_tax(cid)` / `world.set_stonecutter8_level_tax(cid,v)` | `GetStonecutterLevelTaxRate8` / `SetStonecutterLevelTaxRate8` | `world.stonecutter8_level_tax(0)` |
| `world.cobbler8_level_tax(cid)` / `world.set_cobbler8_level_tax(cid,v)` | `GetCobblerLevelTaxRate8` / `SetCobblerLevelTaxRate8` | `world.cobbler8_level_tax(0)` |
| `world.butcher8_level_tax(cid)` / `world.set_butcher8_level_tax(cid,v)` | `GetButcherLevelTaxRate8` / `SetButcherLevelTaxRate8` | `world.butcher8_level_tax(0)` |
| `world.baker8_level_tax(cid)` / `world.set_baker8_level_tax(cid,v)` | `GetBakerLevelTaxRate8` / `SetBakerLevelTaxRate8` | `world.baker8_level_tax(0)` |
| `world.shepherd8_level_tax(cid)` / `world.set_shepherd8_level_tax(cid,v)` | `GetShepherdLevelTaxRate8` / `SetShepherdLevelTaxRate8` | `world.shepherd8_level_tax(0)` |
| `world.dairy8_level_tax(cid)` / `world.set_dairy8_level_tax(cid,v)` | `GetDairyLevelTaxRate8` / `SetDairyLevelTaxRate8` | `world.dairy8_level_tax(0)` |
| `world.brewmaster8_level_tax(cid)` / `world.set_brewmaster8_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate8` / `SetBrewmasterLevelTaxRate8` | `world.brewmaster8_level_tax(0)` |
| `world.miller8_level_tax(cid)` / `world.set_miller8_level_tax(cid,v)` | `GetMillerLevelTaxRate8` / `SetMillerLevelTaxRate8` | `world.miller8_level_tax(0)` |
| `world.fishery8_level_tax(cid)` / `world.set_fishery8_level_tax(cid,v)` | `GetFisheryLevelTaxRate8` / `SetFisheryLevelTaxRate8` | `world.fishery8_level_tax(0)` |
| `world.chandler8_level_tax(cid)` / `world.set_chandler8_level_tax(cid,v)` | `GetChandlerLevelTaxRate8` / `SetChandlerLevelTaxRate8` | `world.chandler8_level_tax(0)` |
| `world.goldbeater8_level_tax(cid)` / `world.set_goldbeater8_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate8` / `SetGoldbeaterLevelTaxRate8` | `world.goldbeater8_level_tax(0)` |
| `world.potter8_level_tax(cid)` / `world.set_potter8_level_tax(cid,v)` | `GetPotterLevelTaxRate8` / `SetPotterLevelTaxRate8` | `world.potter8_level_tax(0)` |
| `world.fowler8_level_tax(cid)` / `world.set_fowler8_level_tax(cid,v)` | `GetFowlerLevelTaxRate8` / `SetFowlerLevelTaxRate8` | `world.fowler8_level_tax(0)` |
| `world.vintner8_level_tax(cid)` / `world.set_vintner8_level_tax(cid,v)` | `GetVintnerLevelTaxRate8` / `SetVintnerLevelTaxRate8` | `world.vintner8_level_tax(0)` |
| `world.distiller8_level_tax(cid)` / `world.set_distiller8_level_tax(cid,v)` | `GetDistillerLevelTaxRate8` / `SetDistillerLevelTaxRate8` | `world.distiller8_level_tax(0)` |
| `world.cook8_level_tax(cid)` / `world.set_cook8_level_tax(cid,v)` | `GetCookLevelTaxRate8` / `SetCookLevelTaxRate8` | `world.cook8_level_tax(0)` |
| `world.brickmaker8_level_tax(cid)` / `world.set_brickmaker8_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate8` / `SetBrickmakerLevelTaxRate8` | `world.brickmaker8_level_tax(0)` |
| `world.bathhouse8_level_tax(cid)` / `world.set_bathhouse8_level_tax(cid,v)` | `GetBathhouseLevelTaxRate8` / `SetBathhouseLevelTaxRate8` | `world.bathhouse8_level_tax(0)` |
| `world.barracks15_level_tax(cid)` / `world.set_barracks15_level_tax(cid,v)` | `GetBarracksLevelTaxRate15` / `SetBarracksLevelTaxRate15` | `world.barracks15_level_tax(0)` |
| `world.school8_level_tax(cid)` / `world.set_school8_level_tax(cid,v)` | `GetSchoolLevelTaxRate8` / `SetSchoolLevelTaxRate8` | `world.school8_level_tax(0)` |
| `world.library8_level_tax(cid)` / `world.set_library8_level_tax(cid,v)` | `GetLibraryLevelTaxRate8` / `SetLibraryLevelTaxRate8` | `world.library8_level_tax(0)` |
| `world.mine8_level_tax(cid)` / `world.set_mine8_level_tax(cid,v)` | `GetMineLevelTaxRate8` / `SetMineLevelTaxRate8` | `world.mine8_level_tax(0)` |
| `world.warehouse8_level_tax(cid)` / `world.set_warehouse8_level_tax(cid,v)` | `GetWarehouseLevelTaxRate8` / `SetWarehouseLevelTaxRate8` | `world.warehouse8_level_tax(0)` |
| `world.garrison8_level_tax(cid)` / `world.set_garrison8_level_tax(cid,v)` | `GetGarrisonLevelTaxRate8` / `SetGarrisonLevelTaxRate8` | `world.garrison8_level_tax(0)` |
| `world.monastery8_level_tax(cid)` / `world.set_monastery8_level_tax(cid,v)` | `GetMonasteryLevelTaxRate8` / `SetMonasteryLevelTaxRate8` | `world.monastery8_level_tax(0)` |
| `world.cathedral8_level_tax(cid)` / `world.set_cathedral8_level_tax(cid,v)` | `GetCathedralLevelTaxRate8` / `SetCathedralLevelTaxRate8` | `world.cathedral8_level_tax(0)` |
| `world.town_hall8_level_tax(cid)` / `world.set_town_hall8_level_tax(cid,v)` | `GetTownHallLevelTaxRate8` / `SetTownHallLevelTaxRate8` | `world.town_hall8_level_tax(0)` |
| `world.market8_level_tax(cid)` / `world.set_market8_level_tax(cid,v)` | `GetMarketLevelTaxRate8` / `SetMarketLevelTaxRate8` | `world.market8_level_tax(0)` |
| `world.harbor8_level_tax(cid)` / `world.set_harbor8_level_tax(cid,v)` | `GetHarborLevelTaxRate8` / `SetHarborLevelTaxRate8` | `world.harbor8_level_tax(0)` |
| `world.guardhouse8_level_tax(cid)` / `world.set_guardhouse8_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate8` / `SetGuardhouseLevelTaxRate8` | `world.guardhouse8_level_tax(0)` |
| `world.courthouse8_level_tax(cid)` / `world.set_courthouse8_level_tax(cid,v)` | `GetCourthouseLevelTaxRate8` / `SetCourthouseLevelTaxRate8` | `world.courthouse8_level_tax(0)` |
| `world.univ_hall8_level_tax(cid)` / `world.set_univ_hall8_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate8` / `SetUniversityHallLevelTaxRate8` | `world.univ_hall8_level_tax(0)` |
| `world.castle8_level_tax(cid)` / `world.set_castle8_level_tax(cid,v)` | `GetCastleLevelTaxRate8` / `SetCastleLevelTaxRate8` | `world.castle8_level_tax(0)` |
| `world.well8_level_tax(cid)` / `world.set_well8_level_tax(cid,v)` | `GetWellLevelTaxRate8` / `SetWellLevelTaxRate8` | `world.well8_level_tax(0)` |
| `world.bridge8_level_tax(cid)` / `world.set_bridge8_level_tax(cid,v)` | `GetBridgeLevelTaxRate8` / `SetBridgeLevelTaxRate8` | `world.bridge8_level_tax(0)` |
| `world.wall8_level_tax(cid)` / `world.set_wall8_level_tax(cid,v)` | `GetWallLevelTaxRate8` / `SetWallLevelTaxRate8` | `world.wall8_level_tax(0)` |
| `world.tower8_level_tax(cid)` / `world.set_tower8_level_tax(cid,v)` | `GetTowerLevelTaxRate8` / `SetTowerLevelTaxRate8` | `world.tower8_level_tax(0)` |
| `world.forum8_level_tax(cid)` / `world.set_forum8_level_tax(cid,v)` | `GetForumLevelTaxRate8` / `SetForumLevelTaxRate8` | `world.forum8_level_tax(0)` |
| `world.granary8_level_tax(cid)` / `world.set_granary8_level_tax(cid,v)` | `GetGranaryLevelTaxRate8` / `SetGranaryLevelTaxRate8` | `world.granary8_level_tax(0)` |
| `world.prison8_level_tax(cid)` / `world.set_prison8_level_tax(cid,v)` | `GetPrisonLevelTaxRate8` / `SetPrisonLevelTaxRate8` | `world.prison8_level_tax(0)` |
| `world.harbor_dock8_level_tax(cid)` / `world.set_harbor_dock8_level_tax(cid,v)` | `GetHarborDockLevelTaxRate8` / `SetHarborDockLevelTaxRate8` | `world.harbor_dock8_level_tax(0)` |
| `world.guild_house8_level_tax(cid)` / `world.set_guild_house8_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate8` / `SetGuildHouseLevelTaxRate8` | `world.guild_house8_level_tax(0)` |
| `world.house8_level_tax(cid)` / `world.set_house8_level_tax(cid,v)` | `GetHouseLevelTaxRate8` / `SetHouseLevelTaxRate8` | `world.house8_level_tax(0)` |
| `world.chapel8_level_tax(cid)` / `world.set_chapel8_level_tax(cid,v)` | `GetChapelLevelTaxRate8` / `SetChapelLevelTaxRate8` | `world.chapel8_level_tax(0)` |
| `world.hospital8_level_tax(cid)` / `world.set_hospital8_level_tax(cid,v)` | `GetHospitalLevelTaxRate8` / `SetHospitalLevelTaxRate8` | `world.hospital8_level_tax(0)` |
| `world.brothel8_level_tax(cid)` / `world.set_brothel8_level_tax(cid,v)` | `GetBrothelLevelTaxRate8` / `SetBrothelLevelTaxRate8` | `world.brothel8_level_tax(0)` |
| `world.university8_level_tax(cid)` / `world.set_university8_level_tax(cid,v)` | `GetUniversityLevelTaxRate8` / `SetUniversityLevelTaxRate8` | `world.university8_level_tax(0)` |
| `world.harbor_walls8_level_tax(cid)` / `world.set_harbor_walls8_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate8` / `SetHarborWallsLevelTaxRate8` | `world.harbor_walls8_level_tax(0)` |
| `world.schoolhouse8_level_tax(cid)` / `world.set_schoolhouse8_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate8` / `SetSchoolhouseLevelTaxRate8` | `world.schoolhouse8_level_tax(0)` |
| `world.library_hall8_level_tax(cid)` / `world.set_library_hall8_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate8` / `SetLibraryHallLevelTaxRate8` | `world.library_hall8_level_tax(0)` |
| `world.barber8_level_tax(cid)` / `world.set_barber8_level_tax(cid,v)` | `GetBarberLevelTaxRate8` / `SetBarberLevelTaxRate8` | `world.barber8_level_tax(0)` |
| `world.contor9_level_tax(cid)` / `world.set_contor9_level_tax(cid,v)` | `GetContorLevelTaxRate9` / `SetContorLevelTaxRate9` | `world.contor9_level_tax(0)` |
| `world.dice_house9_level_tax(cid)` / `world.set_dice_house9_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate9` / `SetDiceHouseLevelTaxRate9` | `world.dice_house9_level_tax(0)` |
| `world.thieves9_level_tax(cid)` / `world.set_thieves9_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate9` / `SetThievesGuildLevelTaxRate9` | `world.thieves9_level_tax(0)` |
| `world.ropemaker_ws9_level_tax(cid)` / `world.set_ropemaker_ws9_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate9` / `SetRopemakerWorkshopLevelTaxRate9` | `world.ropemaker_ws9_level_tax(0)` |
| `world.tannery9_level_tax(cid)` / `world.set_tannery9_level_tax(cid,v)` | `GetTanneryLevelTaxRate9` / `SetTanneryLevelTaxRate9` | `world.tannery9_level_tax(0)` |
| `world.weaving9_level_tax(cid)` / `world.set_weaving9_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate9` / `SetWeavingMillLevelTaxRate9` | `world.weaving9_level_tax(0)` |
| `world.mint9_level_tax(cid)` / `world.set_mint9_level_tax(cid,v)` | `GetMintLevelTaxRate9` / `SetMintLevelTaxRate9` | `world.mint9_level_tax(0)` |
| `world.herb_garden9_level_tax(cid)` / `world.set_herb_garden9_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate9` / `SetHerbGardenLevelTaxRate9` | `world.herb_garden9_level_tax(0)` |
| `world.vineyard9_level_tax(cid)` / `world.set_vineyard9_level_tax(cid,v)` | `GetVineyardLevelTaxRate9` / `SetVineyardLevelTaxRate9` | `world.vineyard9_level_tax(0)` |
| `world.pottery9_level_tax(cid)` / `world.set_pottery9_level_tax(cid,v)` | `GetPotteryLevelTaxRate9` / `SetPotteryLevelTaxRate9` | `world.pottery9_level_tax(0)` |
| `world.tailor9_level_tax(cid)` / `world.set_tailor9_level_tax(cid,v)` | `GetTailorLevelTaxRate9` / `SetTailorLevelTaxRate9` | `world.tailor9_level_tax(0)` |
| `world.tavern9_level_tax(cid)` / `world.set_tavern9_level_tax(cid,v)` | `GetTavernLevelTaxRate9` / `SetTavernLevelTaxRate9` | `world.tavern9_level_tax(0)` |
| `world.apothecary9_level_tax(cid)` / `world.set_apothecary9_level_tax(cid,v)` | `GetApothecaryLevelTaxRate9` / `SetApothecaryLevelTaxRate9` | `world.apothecary9_level_tax(0)` |
| `world.goldsmith9_level_tax(cid)` / `world.set_goldsmith9_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate9` / `SetGoldsmithLevelTaxRate9` | `world.goldsmith9_level_tax(0)` |
| `world.jeweler9_level_tax(cid)` / `world.set_jeweler9_level_tax(cid,v)` | `GetJewelerLevelTaxRate9` / `SetJewelerLevelTaxRate9` | `world.jeweler9_level_tax(0)` |
| `world.perfumer9_level_tax(cid)` / `world.set_perfumer9_level_tax(cid,v)` | `GetPerfumerLevelTaxRate9` / `SetPerfumerLevelTaxRate9` | `world.perfumer9_level_tax(0)` |
| `world.soapmaker9_level_tax(cid)` / `world.set_soapmaker9_level_tax(cid,v)` | `GetSoapmakerLevelTaxRate9` / `SetSoapmakerLevelTaxRate9` | `world.soapmaker9_level_tax(0)` |
| `world.candlemaker9_level_tax(cid)` / `world.set_candlemaker9_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate9` / `SetCandlemakerLevelTaxRate9` | `world.candlemaker9_level_tax(0)` |
| `world.papermill9_level_tax(cid)` / `world.set_papermill9_level_tax(cid,v)` | `GetPapermillLevelTaxRate9` / `SetPapermillLevelTaxRate9` | `world.papermill9_level_tax(0)` |
| `world.printing9_level_tax(cid)` / `world.set_printing9_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate9` / `SetPrintingHouseLevelTaxRate9` | `world.printing9_level_tax(0)` |
| `world.toolmaker9_level_tax(cid)` / `world.set_toolmaker9_level_tax(cid,v)` | `GetToolmakerLevelTaxRate9` / `SetToolmakerLevelTaxRate9` | `world.toolmaker9_level_tax(0)` |
| `world.charcoal9_level_tax(cid)` / `world.set_charcoal9_level_tax(cid,v)` | `GetCharcoalLevelTaxRate9` / `SetCharcoalLevelTaxRate9` | `world.charcoal9_level_tax(0)` |
| `world.furrier9_level_tax(cid)` / `world.set_furrier9_level_tax(cid,v)` | `GetFurrierLevelTaxRate9` / `SetFurrierLevelTaxRate9` | `world.furrier9_level_tax(0)` |
| `world.dyer9_level_tax(cid)` / `world.set_dyer9_level_tax(cid,v)` | `GetDyerLevelTaxRate9` / `SetDyerLevelTaxRate9` | `world.dyer9_level_tax(0)` |
| `world.saddler9_level_tax(cid)` / `world.set_saddler9_level_tax(cid,v)` | `GetSaddlerLevelTaxRate9` / `SetSaddlerLevelTaxRate9` | `world.saddler9_level_tax(0)` |
| `world.armorer9_level_tax(cid)` / `world.set_armorer9_level_tax(cid,v)` | `GetArmorerLevelTaxRate9` / `SetArmorerLevelTaxRate9` | `world.armorer9_level_tax(0)` |
| `world.bowyer9_level_tax(cid)` / `world.set_bowyer9_level_tax(cid,v)` | `GetBowyerLevelTaxRate9` / `SetBowyerLevelTaxRate9` | `world.bowyer9_level_tax(0)` |
| `world.cartwright9_level_tax(cid)` / `world.set_cartwright9_level_tax(cid,v)` | `GetCartwrightLevelTaxRate9` / `SetCartwrightLevelTaxRate9` | `world.cartwright9_level_tax(0)` |
| `world.carpenter9_level_tax(cid)` / `world.set_carpenter9_level_tax(cid,v)` | `GetCarpenterLevelTaxRate9` / `SetCarpenterLevelTaxRate9` | `world.carpenter9_level_tax(0)` |
| `world.ropemaker9_level_tax(cid)` / `world.set_ropemaker9_level_tax(cid,v)` | `GetRopemakerLevelTaxRate9` / `SetRopemakerLevelTaxRate9` | `world.ropemaker9_level_tax(0)` |
| `world.cooper9_level_tax(cid)` / `world.set_cooper9_level_tax(cid,v)` | `GetCooperLevelTaxRate9` / `SetCooperLevelTaxRate9` | `world.cooper9_level_tax(0)` |
| `world.spinner9_level_tax(cid)` / `world.set_spinner9_level_tax(cid,v)` | `GetSpinnerLevelTaxRate9` / `SetSpinnerLevelTaxRate9` | `world.spinner9_level_tax(0)` |
| `world.turner9_level_tax(cid)` / `world.set_turner9_level_tax(cid,v)` | `GetTurnerLevelTaxRate9` / `SetTurnerLevelTaxRate9` | `world.turner9_level_tax(0)` |
| `world.stonecutter9_level_tax(cid)` / `world.set_stonecutter9_level_tax(cid,v)` | `GetStonecutterLevelTaxRate9` / `SetStonecutterLevelTaxRate9` | `world.stonecutter9_level_tax(0)` |
| `world.cobbler9_level_tax(cid)` / `world.set_cobbler9_level_tax(cid,v)` | `GetCobblerLevelTaxRate9` / `SetCobblerLevelTaxRate9` | `world.cobbler9_level_tax(0)` |
| `world.butcher9_level_tax(cid)` / `world.set_butcher9_level_tax(cid,v)` | `GetButcherLevelTaxRate9` / `SetButcherLevelTaxRate9` | `world.butcher9_level_tax(0)` |
| `world.baker9_level_tax(cid)` / `world.set_baker9_level_tax(cid,v)` | `GetBakerLevelTaxRate9` / `SetBakerLevelTaxRate9` | `world.baker9_level_tax(0)` |
| `world.shepherd9_level_tax(cid)` / `world.set_shepherd9_level_tax(cid,v)` | `GetShepherdLevelTaxRate9` / `SetShepherdLevelTaxRate9` | `world.shepherd9_level_tax(0)` |
| `world.dairy9_level_tax(cid)` / `world.set_dairy9_level_tax(cid,v)` | `GetDairyLevelTaxRate9` / `SetDairyLevelTaxRate9` | `world.dairy9_level_tax(0)` |
| `world.brewmaster9_level_tax(cid)` / `world.set_brewmaster9_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate9` / `SetBrewmasterLevelTaxRate9` | `world.brewmaster9_level_tax(0)` |
| `world.miller9_level_tax(cid)` / `world.set_miller9_level_tax(cid,v)` | `GetMillerLevelTaxRate9` / `SetMillerLevelTaxRate9` | `world.miller9_level_tax(0)` |
| `world.fishery9_level_tax(cid)` / `world.set_fishery9_level_tax(cid,v)` | `GetFisheryLevelTaxRate9` / `SetFisheryLevelTaxRate9` | `world.fishery9_level_tax(0)` |
| `world.chandler9_level_tax(cid)` / `world.set_chandler9_level_tax(cid,v)` | `GetChandlerLevelTaxRate9` / `SetChandlerLevelTaxRate9` | `world.chandler9_level_tax(0)` |
| `world.goldbeater9_level_tax(cid)` / `world.set_goldbeater9_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate9` / `SetGoldbeaterLevelTaxRate9` | `world.goldbeater9_level_tax(0)` |
| `world.potter9_level_tax(cid)` / `world.set_potter9_level_tax(cid,v)` | `GetPotterLevelTaxRate9` / `SetPotterLevelTaxRate9` | `world.potter9_level_tax(0)` |
| `world.fowler9_level_tax(cid)` / `world.set_fowler9_level_tax(cid,v)` | `GetFowlerLevelTaxRate9` / `SetFowlerLevelTaxRate9` | `world.fowler9_level_tax(0)` |
| `world.vintner9_level_tax(cid)` / `world.set_vintner9_level_tax(cid,v)` | `GetVintnerLevelTaxRate9` / `SetVintnerLevelTaxRate9` | `world.vintner9_level_tax(0)` |
| `world.distiller9_level_tax(cid)` / `world.set_distiller9_level_tax(cid,v)` | `GetDistillerLevelTaxRate9` / `SetDistillerLevelTaxRate9` | `world.distiller9_level_tax(0)` |
| `world.cook9_level_tax(cid)` / `world.set_cook9_level_tax(cid,v)` | `GetCookLevelTaxRate9` / `SetCookLevelTaxRate9` | `world.cook9_level_tax(0)` |
| `world.brickmaker9_level_tax(cid)` / `world.set_brickmaker9_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate9` / `SetBrickmakerLevelTaxRate9` | `world.brickmaker9_level_tax(0)` |
| `world.bathhouse9_level_tax(cid)` / `world.set_bathhouse9_level_tax(cid,v)` | `GetBathhouseLevelTaxRate9` / `SetBathhouseLevelTaxRate9` | `world.bathhouse9_level_tax(0)` |
| `world.barracks16_level_tax(cid)` / `world.set_barracks16_level_tax(cid,v)` | `GetBarracksLevelTaxRate16` / `SetBarracksLevelTaxRate16` | `world.barracks16_level_tax(0)` |
| `world.school9_level_tax(cid)` / `world.set_school9_level_tax(cid,v)` | `GetSchoolLevelTaxRate9` / `SetSchoolLevelTaxRate9` | `world.school9_level_tax(0)` |
| `world.library9_level_tax(cid)` / `world.set_library9_level_tax(cid,v)` | `GetLibraryLevelTaxRate9` / `SetLibraryLevelTaxRate9` | `world.library9_level_tax(0)` |
| `world.mine9_level_tax(cid)` / `world.set_mine9_level_tax(cid,v)` | `GetMineLevelTaxRate9` / `SetMineLevelTaxRate9` | `world.mine9_level_tax(0)` |
| `world.warehouse9_level_tax(cid)` / `world.set_warehouse9_level_tax(cid,v)` | `GetWarehouseLevelTaxRate9` / `SetWarehouseLevelTaxRate9` | `world.warehouse9_level_tax(0)` |
| `world.garrison9_level_tax(cid)` / `world.set_garrison9_level_tax(cid,v)` | `GetGarrisonLevelTaxRate9` / `SetGarrisonLevelTaxRate9` | `world.garrison9_level_tax(0)` |
| `world.monastery9_level_tax(cid)` / `world.set_monastery9_level_tax(cid,v)` | `GetMonasteryLevelTaxRate9` / `SetMonasteryLevelTaxRate9` | `world.monastery9_level_tax(0)` |
| `world.cathedral9_level_tax(cid)` / `world.set_cathedral9_level_tax(cid,v)` | `GetCathedralLevelTaxRate9` / `SetCathedralLevelTaxRate9` | `world.cathedral9_level_tax(0)` |
| `world.town_hall9_level_tax(cid)` / `world.set_town_hall9_level_tax(cid,v)` | `GetTownHallLevelTaxRate9` / `SetTownHallLevelTaxRate9` | `world.town_hall9_level_tax(0)` |
| `world.market9_level_tax(cid)` / `world.set_market9_level_tax(cid,v)` | `GetMarketLevelTaxRate9` / `SetMarketLevelTaxRate9` | `world.market9_level_tax(0)` |
| `world.harbor9_level_tax(cid)` / `world.set_harbor9_level_tax(cid,v)` | `GetHarborLevelTaxRate9` / `SetHarborLevelTaxRate9` | `world.harbor9_level_tax(0)` |
| `world.guardhouse9_level_tax(cid)` / `world.set_guardhouse9_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate9` / `SetGuardhouseLevelTaxRate9` | `world.guardhouse9_level_tax(0)` |
| `world.courthouse9_level_tax(cid)` / `world.set_courthouse9_level_tax(cid,v)` | `GetCourthouseLevelTaxRate9` / `SetCourthouseLevelTaxRate9` | `world.courthouse9_level_tax(0)` |
| `world.univ_hall9_level_tax(cid)` / `world.set_univ_hall9_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate9` / `SetUniversityHallLevelTaxRate9` | `world.univ_hall9_level_tax(0)` |
| `world.castle9_level_tax(cid)` / `world.set_castle9_level_tax(cid,v)` | `GetCastleLevelTaxRate9` / `SetCastleLevelTaxRate9` | `world.castle9_level_tax(0)` |
| `world.well9_level_tax(cid)` / `world.set_well9_level_tax(cid,v)` | `GetWellLevelTaxRate9` / `SetWellLevelTaxRate9` | `world.well9_level_tax(0)` |
| `world.bridge9_level_tax(cid)` / `world.set_bridge9_level_tax(cid,v)` | `GetBridgeLevelTaxRate9` / `SetBridgeLevelTaxRate9` | `world.bridge9_level_tax(0)` |
| `world.wall9_level_tax(cid)` / `world.set_wall9_level_tax(cid,v)` | `GetWallLevelTaxRate9` / `SetWallLevelTaxRate9` | `world.wall9_level_tax(0)` |
| `world.tower9_level_tax(cid)` / `world.set_tower9_level_tax(cid,v)` | `GetTowerLevelTaxRate9` / `SetTowerLevelTaxRate9` | `world.tower9_level_tax(0)` |
| `world.forum9_level_tax(cid)` / `world.set_forum9_level_tax(cid,v)` | `GetForumLevelTaxRate9` / `SetForumLevelTaxRate9` | `world.forum9_level_tax(0)` |
| `world.granary9_level_tax(cid)` / `world.set_granary9_level_tax(cid,v)` | `GetGranaryLevelTaxRate9` / `SetGranaryLevelTaxRate9` | `world.granary9_level_tax(0)` |
| `world.prison9_level_tax(cid)` / `world.set_prison9_level_tax(cid,v)` | `GetPrisonLevelTaxRate9` / `SetPrisonLevelTaxRate9` | `world.prison9_level_tax(0)` |
| `world.harbor_dock9_level_tax(cid)` / `world.set_harbor_dock9_level_tax(cid,v)` | `GetHarborDockLevelTaxRate9` / `SetHarborDockLevelTaxRate9` | `world.harbor_dock9_level_tax(0)` |
| `world.guild_house9_level_tax(cid)` / `world.set_guild_house9_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate9` / `SetGuildHouseLevelTaxRate9` | `world.guild_house9_level_tax(0)` |
| `world.house9_level_tax(cid)` / `world.set_house9_level_tax(cid,v)` | `GetHouseLevelTaxRate9` / `SetHouseLevelTaxRate9` | `world.house9_level_tax(0)` |
| `world.chapel9_level_tax(cid)` / `world.set_chapel9_level_tax(cid,v)` | `GetChapelLevelTaxRate9` / `SetChapelLevelTaxRate9` | `world.chapel9_level_tax(0)` |
| `world.hospital9_level_tax(cid)` / `world.set_hospital9_level_tax(cid,v)` | `GetHospitalLevelTaxRate9` / `SetHospitalLevelTaxRate9` | `world.hospital9_level_tax(0)` |
| `world.brothel9_level_tax(cid)` / `world.set_brothel9_level_tax(cid,v)` | `GetBrothelLevelTaxRate9` / `SetBrothelLevelTaxRate9` | `world.brothel9_level_tax(0)` |
| `world.university9_level_tax(cid)` / `world.set_university9_level_tax(cid,v)` | `GetUniversityLevelTaxRate9` / `SetUniversityLevelTaxRate9` | `world.university9_level_tax(0)` |
| `world.harbor_walls9_level_tax(cid)` / `world.set_harbor_walls9_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate9` / `SetHarborWallsLevelTaxRate9` | `world.harbor_walls9_level_tax(0)` |
| `world.schoolhouse9_level_tax(cid)` / `world.set_schoolhouse9_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate9` / `SetSchoolhouseLevelTaxRate9` | `world.schoolhouse9_level_tax(0)` |
| `world.library_hall9_level_tax(cid)` / `world.set_library_hall9_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate9` / `SetLibraryHallLevelTaxRate9` | `world.library_hall9_level_tax(0)` |
| `world.barber9_level_tax(cid)` / `world.set_barber9_level_tax(cid,v)` | `GetBarberLevelTaxRate9` / `SetBarberLevelTaxRate9` | `world.barber9_level_tax(0)` |
| `world.contor10_level_tax(cid)` / `world.set_contor10_level_tax(cid,v)` | `GetContorLevelTaxRate10` / `SetContorLevelTaxRate10` | `world.contor10_level_tax(0)` |
| `world.dice_house10_level_tax(cid)` / `world.set_dice_house10_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate10` / `SetDiceHouseLevelTaxRate10` | `world.dice_house10_level_tax(0)` |
| `world.thieves10_level_tax(cid)` / `world.set_thieves10_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate10` / `SetThievesGuildLevelTaxRate10` | `world.thieves10_level_tax(0)` |
| `world.ropemaker_ws10_level_tax(cid)` / `world.set_ropemaker_ws10_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate10` / `SetRopemakerWorkshopLevelTaxRate10` | `world.ropemaker_ws10_level_tax(0)` |
| `world.tannery10_level_tax(cid)` / `world.set_tannery10_level_tax(cid,v)` | `GetTanneryLevelTaxRate10` / `SetTanneryLevelTaxRate10` | `world.tannery10_level_tax(0)` |
| `world.weaving10_level_tax(cid)` / `world.set_weaving10_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate10` / `SetWeavingMillLevelTaxRate10` | `world.weaving10_level_tax(0)` |
| `world.mint10_level_tax(cid)` / `world.set_mint10_level_tax(cid,v)` | `GetMintLevelTaxRate10` / `SetMintLevelTaxRate10` | `world.mint10_level_tax(0)` |
| `world.herb_garden10_level_tax(cid)` / `world.set_herb_garden10_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate10` / `SetHerbGardenLevelTaxRate10` | `world.herb_garden10_level_tax(0)` |
| `world.vineyard10_level_tax(cid)` / `world.set_vineyard10_level_tax(cid,v)` | `GetVineyardLevelTaxRate10` / `SetVineyardLevelTaxRate10` | `world.vineyard10_level_tax(0)` |
| `world.pottery10_level_tax(cid)` / `world.set_pottery10_level_tax(cid,v)` | `GetPotteryLevelTaxRate10` / `SetPotteryLevelTaxRate10` | `world.pottery10_level_tax(0)` |
| `world.tailor10_level_tax(cid)` / `world.set_tailor10_level_tax(cid,v)` | `GetTailorLevelTaxRate10` / `SetTailorLevelTaxRate10` | `world.tailor10_level_tax(0)` |
| `world.tavern10_level_tax(cid)` / `world.set_tavern10_level_tax(cid,v)` | `GetTavernLevelTaxRate10` / `SetTavernLevelTaxRate10` | `world.tavern10_level_tax(0)` |
| `world.apothecary10_level_tax(cid)` / `world.set_apothecary10_level_tax(cid,v)` | `GetApothecaryLevelTaxRate10` / `SetApothecaryLevelTaxRate10` | `world.apothecary10_level_tax(0)` |
| `world.goldsmith10_level_tax(cid)` / `world.set_goldsmith10_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate10` / `SetGoldsmithLevelTaxRate10` | `world.goldsmith10_level_tax(0)` |
| `world.jeweler10_level_tax(cid)` / `world.set_jeweler10_level_tax(cid,v)` | `GetJewelerLevelTaxRate10` / `SetJewelerLevelTaxRate10` | `world.jeweler10_level_tax(0)` |
| `world.perfumer10_level_tax(cid)` / `world.set_perfumer10_level_tax(cid,v)` | `GetPerfumerLevelTaxRate10` / `SetPerfumerLevelTaxRate10` | `world.perfumer10_level_tax(0)` |
| `world.soapmaker10_level_tax(cid)` / `world.set_soapmaker10_level_tax(cid,v)` | `GetSoapmakerLevelTaxRate10` / `SetSoapmakerLevelTaxRate10` | `world.soapmaker10_level_tax(0)` |
| `world.candlemaker10_level_tax(cid)` / `world.set_candlemaker10_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate10` / `SetCandlemakerLevelTaxRate10` | `world.candlemaker10_level_tax(0)` |
| `world.papermill10_level_tax(cid)` / `world.set_papermill10_level_tax(cid,v)` | `GetPapermillLevelTaxRate10` / `SetPapermillLevelTaxRate10` | `world.papermill10_level_tax(0)` |
| `world.printing10_level_tax(cid)` / `world.set_printing10_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate10` / `SetPrintingHouseLevelTaxRate10` | `world.printing10_level_tax(0)` |
| `world.toolmaker10_level_tax(cid)` / `world.set_toolmaker10_level_tax(cid,v)` | `GetToolmakerLevelTaxRate10` / `SetToolmakerLevelTaxRate10` | `world.toolmaker10_level_tax(0)` |
| `world.charcoal10_level_tax(cid)` / `world.set_charcoal10_level_tax(cid,v)` | `GetCharcoalLevelTaxRate10` / `SetCharcoalLevelTaxRate10` | `world.charcoal10_level_tax(0)` |
| `world.furrier10_level_tax(cid)` / `world.set_furrier10_level_tax(cid,v)` | `GetFurrierLevelTaxRate10` / `SetFurrierLevelTaxRate10` | `world.furrier10_level_tax(0)` |
| `world.dyer10_level_tax(cid)` / `world.set_dyer10_level_tax(cid,v)` | `GetDyerLevelTaxRate10` / `SetDyerLevelTaxRate10` | `world.dyer10_level_tax(0)` |
| `world.saddler10_level_tax(cid)` / `world.set_saddler10_level_tax(cid,v)` | `GetSaddlerLevelTaxRate10` / `SetSaddlerLevelTaxRate10` | `world.saddler10_level_tax(0)` |
| `world.armorer10_level_tax(cid)` / `world.set_armorer10_level_tax(cid,v)` | `GetArmorerLevelTaxRate10` / `SetArmorerLevelTaxRate10` | `world.armorer10_level_tax(0)` |
| `world.bowyer10_level_tax(cid)` / `world.set_bowyer10_level_tax(cid,v)` | `GetBowyerLevelTaxRate10` / `SetBowyerLevelTaxRate10` | `world.bowyer10_level_tax(0)` |
| `world.cartwright10_level_tax(cid)` / `world.set_cartwright10_level_tax(cid,v)` | `GetCartwrightLevelTaxRate10` / `SetCartwrightLevelTaxRate10` | `world.cartwright10_level_tax(0)` |
| `world.carpenter10_level_tax(cid)` / `world.set_carpenter10_level_tax(cid,v)` | `GetCarpenterLevelTaxRate10` / `SetCarpenterLevelTaxRate10` | `world.carpenter10_level_tax(0)` |
| `world.ropemaker10_level_tax(cid)` / `world.set_ropemaker10_level_tax(cid,v)` | `GetRopemakerLevelTaxRate10` / `SetRopemakerLevelTaxRate10` | `world.ropemaker10_level_tax(0)` |
| `world.cooper10_level_tax(cid)` / `world.set_cooper10_level_tax(cid,v)` | `GetCooperLevelTaxRate10` / `SetCooperLevelTaxRate10` | `world.cooper10_level_tax(0)` |
| `world.spinner10_level_tax(cid)` / `world.set_spinner10_level_tax(cid,v)` | `GetSpinnerLevelTaxRate10` / `SetSpinnerLevelTaxRate10` | `world.spinner10_level_tax(0)` |
| `world.turner10_level_tax(cid)` / `world.set_turner10_level_tax(cid,v)` | `GetTurnerLevelTaxRate10` / `SetTurnerLevelTaxRate10` | `world.turner10_level_tax(0)` |
| `world.stonecutter10_level_tax(cid)` / `world.set_stonecutter10_level_tax(cid,v)` | `GetStonecutterLevelTaxRate10` / `SetStonecutterLevelTaxRate10` | `world.stonecutter10_level_tax(0)` |
| `world.cobbler10_level_tax(cid)` / `world.set_cobbler10_level_tax(cid,v)` | `GetCobblerLevelTaxRate10` / `SetCobblerLevelTaxRate10` | `world.cobbler10_level_tax(0)` |
| `world.butcher10_level_tax(cid)` / `world.set_butcher10_level_tax(cid,v)` | `GetButcherLevelTaxRate10` / `SetButcherLevelTaxRate10` | `world.butcher10_level_tax(0)` |
| `world.baker10_level_tax(cid)` / `world.set_baker10_level_tax(cid,v)` | `GetBakerLevelTaxRate10` / `SetBakerLevelTaxRate10` | `world.baker10_level_tax(0)` |
| `world.shepherd10_level_tax(cid)` / `world.set_shepherd10_level_tax(cid,v)` | `GetShepherdLevelTaxRate10` / `SetShepherdLevelTaxRate10` | `world.shepherd10_level_tax(0)` |
| `world.dairy10_level_tax(cid)` / `world.set_dairy10_level_tax(cid,v)` | `GetDairyLevelTaxRate10` / `SetDairyLevelTaxRate10` | `world.dairy10_level_tax(0)` |
| `world.brewmaster10_level_tax(cid)` / `world.set_brewmaster10_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate10` / `SetBrewmasterLevelTaxRate10` | `world.brewmaster10_level_tax(0)` |
| `world.miller10_level_tax(cid)` / `world.set_miller10_level_tax(cid,v)` | `GetMillerLevelTaxRate10` / `SetMillerLevelTaxRate10` | `world.miller10_level_tax(0)` |
| `world.fishery10_level_tax(cid)` / `world.set_fishery10_level_tax(cid,v)` | `GetFisheryLevelTaxRate10` / `SetFisheryLevelTaxRate10` | `world.fishery10_level_tax(0)` |
| `world.chandler10_level_tax(cid)` / `world.set_chandler10_level_tax(cid,v)` | `GetChandlerLevelTaxRate10` / `SetChandlerLevelTaxRate10` | `world.chandler10_level_tax(0)` |
| `world.brickmaker10_level_tax(cid)` / `world.set_brickmaker10_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate10` / `SetBrickmakerLevelTaxRate10` | `world.brickmaker10_level_tax(0)` |
| `world.potter10_level_tax(cid)` / `world.set_potter10_level_tax(cid,v)` | `GetPotterLevelTaxRate10` / `SetPotterLevelTaxRate10` | `world.potter10_level_tax(0)` |
| `world.glassblower10_level_tax(cid)` / `world.set_glassblower10_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate10` / `SetGlassblowerLevelTaxRate10` | `world.glassblower10_level_tax(0)` |
| `world.goldbeater10_level_tax(cid)` / `world.set_goldbeater10_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate10` / `SetGoldbeaterLevelTaxRate10` | `world.goldbeater10_level_tax(0)` |
| `world.fowler10_level_tax(cid)` / `world.set_fowler10_level_tax(cid,v)` | `GetFowlerLevelTaxRate10` / `SetFowlerLevelTaxRate10` | `world.fowler10_level_tax(0)` |
| `world.vintner10_level_tax(cid)` / `world.set_vintner10_level_tax(cid,v)` | `GetVintnerLevelTaxRate10` / `SetVintnerLevelTaxRate10` | `world.vintner10_level_tax(0)` |
| `world.distiller10_level_tax(cid)` / `world.set_distiller10_level_tax(cid,v)` | `GetDistillerLevelTaxRate10` / `SetDistillerLevelTaxRate10` | `world.distiller10_level_tax(0)` |
| `world.cook10_level_tax(cid)` / `world.set_cook10_level_tax(cid,v)` | `GetCookLevelTaxRate10` / `SetCookLevelTaxRate10` | `world.cook10_level_tax(0)` |
| `world.glassblower_level_tax(cid)` / `world.set_glassblower_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate` / `SetGlassblowerLevelTaxRate` | `world.glassblower_level_tax(0)` |
| `world.glassblower2_level_tax(cid)` / `world.set_glassblower2_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate2` / `SetGlassblowerLevelTaxRate2` | `world.glassblower2_level_tax(0)` |
| `world.glassblower3_level_tax(cid)` / `world.set_glassblower3_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate3` / `SetGlassblowerLevelTaxRate3` | `world.glassblower3_level_tax(0)` |
| `world.glassblower4_level_tax(cid)` / `world.set_glassblower4_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate4` / `SetGlassblowerLevelTaxRate4` | `world.glassblower4_level_tax(0)` |
| `world.glassblower5_level_tax(cid)` / `world.set_glassblower5_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate5` / `SetGlassblowerLevelTaxRate5` | `world.glassblower5_level_tax(0)` |
| `world.glassblower6_level_tax(cid)` / `world.set_glassblower6_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate6` / `SetGlassblowerLevelTaxRate6` | `world.glassblower6_level_tax(0)` |
| `world.glassblower7_level_tax(cid)` / `world.set_glassblower7_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate7` / `SetGlassblowerLevelTaxRate7` | `world.glassblower7_level_tax(0)` |
| `world.glassblower8_level_tax(cid)` / `world.set_glassblower8_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate8` / `SetGlassblowerLevelTaxRate8` | `world.glassblower8_level_tax(0)` |
| `world.glassblower9_level_tax(cid)` / `world.set_glassblower9_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate9` / `SetGlassblowerLevelTaxRate9` | `world.glassblower9_level_tax(0)` |
| `world.barber10_level_tax(cid)` / `world.set_barber10_level_tax(cid,v)` | `GetBarberLevelTaxRate10` / `SetBarberLevelTaxRate10` | `world.barber10_level_tax(0)` |
| `world.bathhouse10_level_tax(cid)` / `world.set_bathhouse10_level_tax(cid,v)` | `GetBathhouseLevelTaxRate10` / `SetBathhouseLevelTaxRate10` | `world.bathhouse10_level_tax(0)` |
| `world.bridge10_level_tax(cid)` / `world.set_bridge10_level_tax(cid,v)` | `GetBridgeLevelTaxRate10` / `SetBridgeLevelTaxRate10` | `world.bridge10_level_tax(0)` |
| `world.brothel10_level_tax(cid)` / `world.set_brothel10_level_tax(cid,v)` | `GetBrothelLevelTaxRate10` / `SetBrothelLevelTaxRate10` | `world.brothel10_level_tax(0)` |
| `world.castle10_level_tax(cid)` / `world.set_castle10_level_tax(cid,v)` | `GetCastleLevelTaxRate10` / `SetCastleLevelTaxRate10` | `world.castle10_level_tax(0)` |
| `world.cathedral10_level_tax(cid)` / `world.set_cathedral10_level_tax(cid,v)` | `GetCathedralLevelTaxRate10` / `SetCathedralLevelTaxRate10` | `world.cathedral10_level_tax(0)` |
| `world.chapel10_level_tax(cid)` / `world.set_chapel10_level_tax(cid,v)` | `GetChapelLevelTaxRate10` / `SetChapelLevelTaxRate10` | `world.chapel10_level_tax(0)` |
| `world.courthouse10_level_tax(cid)` / `world.set_courthouse10_level_tax(cid,v)` | `GetCourthouseLevelTaxRate10` / `SetCourthouseLevelTaxRate10` | `world.courthouse10_level_tax(0)` |
| `world.forum10_level_tax(cid)` / `world.set_forum10_level_tax(cid,v)` | `GetForumLevelTaxRate10` / `SetForumLevelTaxRate10` | `world.forum10_level_tax(0)` |
| `world.garrison10_level_tax(cid)` / `world.set_garrison10_level_tax(cid,v)` | `GetGarrisonLevelTaxRate10` / `SetGarrisonLevelTaxRate10` | `world.garrison10_level_tax(0)` |
| `world.gates10_level_tax(cid)` / `world.set_gates10_level_tax(cid,v)` | `GetGatesLevelTaxRate10` / `SetGatesLevelTaxRate10` | `world.gates10_level_tax(0)` |
| `world.granary10_level_tax(cid)` / `world.set_granary10_level_tax(cid,v)` | `GetGranaryLevelTaxRate10` / `SetGranaryLevelTaxRate10` | `world.granary10_level_tax(0)` |
| `world.guardhouse10_level_tax(cid)` / `world.set_guardhouse10_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate10` / `SetGuardhouseLevelTaxRate10` | `world.guardhouse10_level_tax(0)` |
| `world.guild_house10_level_tax(cid)` / `world.set_guild_house10_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate10` / `SetGuildHouseLevelTaxRate10` | `world.guild_house10_level_tax(0)` |
| `world.harbor10_level_tax(cid)` / `world.set_harbor10_level_tax(cid,v)` | `GetHarborLevelTaxRate10` / `SetHarborLevelTaxRate10` | `world.harbor10_level_tax(0)` |
| `world.harbor_dock10_level_tax(cid)` / `world.set_harbor_dock10_level_tax(cid,v)` | `GetHarborDockLevelTaxRate10` / `SetHarborDockLevelTaxRate10` | `world.harbor_dock10_level_tax(0)` |
| `world.harbor_walls10_level_tax(cid)` / `world.set_harbor_walls10_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate10` / `SetHarborWallsLevelTaxRate10` | `world.harbor_walls10_level_tax(0)` |
| `world.hospital10_level_tax(cid)` / `world.set_hospital10_level_tax(cid,v)` | `GetHospitalLevelTaxRate10` / `SetHospitalLevelTaxRate10` | `world.hospital10_level_tax(0)` |
| `world.house10_level_tax(cid)` / `world.set_house10_level_tax(cid,v)` | `GetHouseLevelTaxRate10` / `SetHouseLevelTaxRate10` | `world.house10_level_tax(0)` |
| `world.library10_level_tax(cid)` / `world.set_library10_level_tax(cid,v)` | `GetLibraryLevelTaxRate10` / `SetLibraryLevelTaxRate10` | `world.library10_level_tax(0)` |
| `world.library_hall10_level_tax(cid)` / `world.set_library_hall10_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate10` / `SetLibraryHallLevelTaxRate10` | `world.library_hall10_level_tax(0)` |
| `world.market10_level_tax(cid)` / `world.set_market10_level_tax(cid,v)` | `GetMarketLevelTaxRate10` / `SetMarketLevelTaxRate10` | `world.market10_level_tax(0)` |
| `world.mine10_level_tax(cid)` / `world.set_mine10_level_tax(cid,v)` | `GetMineLevelTaxRate10` / `SetMineLevelTaxRate10` | `world.mine10_level_tax(0)` |
| `world.monastery10_level_tax(cid)` / `world.set_monastery10_level_tax(cid,v)` | `GetMonasteryLevelTaxRate10` / `SetMonasteryLevelTaxRate10` | `world.monastery10_level_tax(0)` |
| `world.prison10_level_tax(cid)` / `world.set_prison10_level_tax(cid,v)` | `GetPrisonLevelTaxRate10` / `SetPrisonLevelTaxRate10` | `world.prison10_level_tax(0)` |
| `world.school10_level_tax(cid)` / `world.set_school10_level_tax(cid,v)` | `GetSchoolLevelTaxRate10` / `SetSchoolLevelTaxRate10` | `world.school10_level_tax(0)` |
| `world.schoolhouse10_level_tax(cid)` / `world.set_schoolhouse10_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate10` / `SetSchoolhouseLevelTaxRate10` | `world.schoolhouse10_level_tax(0)` |
| `world.sentry_tower10_level_tax(cid)` / `world.set_sentry_tower10_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate10` / `SetSentryTowerLevelTaxRate10` | `world.sentry_tower10_level_tax(0)` |
| `world.stables10_level_tax(cid)` / `world.set_stables10_level_tax(cid,v)` | `GetStablesLevelTaxRate10` / `SetStablesLevelTaxRate10` | `world.stables10_level_tax(0)` |
| `world.tower10_level_tax(cid)` / `world.set_tower10_level_tax(cid,v)` | `GetTowerLevelTaxRate10` / `SetTowerLevelTaxRate10` | `world.tower10_level_tax(0)` |
| `world.town_hall10_level_tax(cid)` / `world.set_town_hall10_level_tax(cid,v)` | `GetTownHallLevelTaxRate10` / `SetTownHallLevelTaxRate10` | `world.town_hall10_level_tax(0)` |
| `world.university10_level_tax(cid)` / `world.set_university10_level_tax(cid,v)` | `GetUniversityLevelTaxRate10` / `SetUniversityLevelTaxRate10` | `world.university10_level_tax(0)` |
| `world.university_hall10_level_tax(cid)` / `world.set_university_hall10_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate10` / `SetUniversityHallLevelTaxRate10` | `world.university_hall10_level_tax(0)` |
| `world.wall10_level_tax(cid)` / `world.set_wall10_level_tax(cid,v)` | `GetWallLevelTaxRate10` / `SetWallLevelTaxRate10` | `world.wall10_level_tax(0)` |
| `world.warehouse10_level_tax(cid)` / `world.set_warehouse10_level_tax(cid,v)` | `GetWarehouseLevelTaxRate10` / `SetWarehouseLevelTaxRate10` | `world.warehouse10_level_tax(0)` |
| `world.well10_level_tax(cid)` / `world.set_well10_level_tax(cid,v)` | `GetWellLevelTaxRate10` / `SetWellLevelTaxRate10` | `world.well10_level_tax(0)` |
| `world.gates8_level_tax(cid)` / `world.set_gates8_level_tax(cid,v)` | `GetGatesLevelTaxRate8` / `SetGatesLevelTaxRate8` | `world.gates8_level_tax(0)` |
| `world.gates9_level_tax(cid)` / `world.set_gates9_level_tax(cid,v)` | `GetGatesLevelTaxRate9` / `SetGatesLevelTaxRate9` | `world.gates9_level_tax(0)` |
| `world.sentry_tower8_level_tax(cid)` / `world.set_sentry_tower8_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate8` / `SetSentryTowerLevelTaxRate8` | `world.sentry_tower8_level_tax(0)` |
| `world.sentry_tower9_level_tax(cid)` / `world.set_sentry_tower9_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate9` / `SetSentryTowerLevelTaxRate9` | `world.sentry_tower9_level_tax(0)` |
| `world.stables8_level_tax(cid)` / `world.set_stables8_level_tax(cid,v)` | `GetStablesLevelTaxRate8` / `SetStablesLevelTaxRate8` | `world.stables8_level_tax(0)` |
| `world.stables9_level_tax(cid)` / `world.set_stables9_level_tax(cid,v)` | `GetStablesLevelTaxRate9` / `SetStablesLevelTaxRate9` | `world.stables9_level_tax(0)` |
| `world.church2_level_tax(cid)` / `world.set_church2_level_tax(cid,v)` | `GetChurchLevelTaxRate2` / `SetChurchLevelTaxRate2` | `world.church2_level_tax(0)` |
| `world.church3_level_tax(cid)` / `world.set_church3_level_tax(cid,v)` | `GetChurchLevelTaxRate3` / `SetChurchLevelTaxRate3` | `world.church3_level_tax(0)` |
| `world.church4_level_tax(cid)` / `world.set_church4_level_tax(cid,v)` | `GetChurchLevelTaxRate4` / `SetChurchLevelTaxRate4` | `world.church4_level_tax(0)` |
| `world.church5_level_tax(cid)` / `world.set_church5_level_tax(cid,v)` | `GetChurchLevelTaxRate5` / `SetChurchLevelTaxRate5` | `world.church5_level_tax(0)` |
| `world.church6_level_tax(cid)` / `world.set_church6_level_tax(cid,v)` | `GetChurchLevelTaxRate6` / `SetChurchLevelTaxRate6` | `world.church6_level_tax(0)` |
| `world.church7_level_tax(cid)` / `world.set_church7_level_tax(cid,v)` | `GetChurchLevelTaxRate7` / `SetChurchLevelTaxRate7` | `world.church7_level_tax(0)` |
| `world.church8_level_tax(cid)` / `world.set_church8_level_tax(cid,v)` | `GetChurchLevelTaxRate8` / `SetChurchLevelTaxRate8` | `world.church8_level_tax(0)` |
| `world.church9_level_tax(cid)` / `world.set_church9_level_tax(cid,v)` | `GetChurchLevelTaxRate9` / `SetChurchLevelTaxRate9` | `world.church9_level_tax(0)` |
| `world.church10_level_tax(cid)` / `world.set_church10_level_tax(cid,v)` | `GetChurchLevelTaxRate10` / `SetChurchLevelTaxRate10` | `world.church10_level_tax(0)` |
| `world.town_hall11_level_tax(cid)` / `world.set_town_hall11_level_tax(cid,v)` | `GetTownHallLevelTaxRate11` / `SetTownHallLevelTaxRate11` | `world.town_hall11_level_tax(0)` |
| `world.university11_level_tax(cid)` / `world.set_university11_level_tax(cid,v)` | `GetUniversityLevelTaxRate11` / `SetUniversityLevelTaxRate11` | `world.university11_level_tax(0)` |
| `world.wall11_level_tax(cid)` / `world.set_wall11_level_tax(cid,v)` | `GetWallLevelTaxRate11` / `SetWallLevelTaxRate11` | `world.wall11_level_tax(0)` |
| `world.apothecary11_level_tax(cid)` / `world.set_apothecary11_level_tax(cid,v)` | `GetApothecaryLevelTaxRate11` / `SetApothecaryLevelTaxRate11` | `world.apothecary11_level_tax(0)` |
| `world.baker11_level_tax(cid)` / `world.set_baker11_level_tax(cid,v)` | `GetBakerLevelTaxRate11` / `SetBakerLevelTaxRate11` | `world.baker11_level_tax(0)` |
| `world.barber11_level_tax(cid)` / `world.set_barber11_level_tax(cid,v)` | `GetBarberLevelTaxRate11` / `SetBarberLevelTaxRate11` | `world.barber11_level_tax(0)` |
| `world.bathhouse11_level_tax(cid)` / `world.set_bathhouse11_level_tax(cid,v)` | `GetBathhouseLevelTaxRate11` / `SetBathhouseLevelTaxRate11` | `world.bathhouse11_level_tax(0)` |
| `world.bowyer11_level_tax(cid)` / `world.set_bowyer11_level_tax(cid,v)` | `GetBowyerLevelTaxRate11` / `SetBowyerLevelTaxRate11` | `world.bowyer11_level_tax(0)` |
| `world.brewmaster11_level_tax(cid)` / `world.set_brewmaster11_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate11` / `SetBrewmasterLevelTaxRate11` | `world.brewmaster11_level_tax(0)` |
| `world.brickmaker11_level_tax(cid)` / `world.set_brickmaker11_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate11` / `SetBrickmakerLevelTaxRate11` | `world.brickmaker11_level_tax(0)` |
| `world.bridge11_level_tax(cid)` / `world.set_bridge11_level_tax(cid,v)` | `GetBridgeLevelTaxRate11` / `SetBridgeLevelTaxRate11` | `world.bridge11_level_tax(0)` |
| `world.brothel11_level_tax(cid)` / `world.set_brothel11_level_tax(cid,v)` | `GetBrothelLevelTaxRate11` / `SetBrothelLevelTaxRate11` | `world.brothel11_level_tax(0)` |
| `world.butcher11_level_tax(cid)` / `world.set_butcher11_level_tax(cid,v)` | `GetButcherLevelTaxRate11` / `SetButcherLevelTaxRate11` | `world.butcher11_level_tax(0)` |
| `world.candlemaker11_level_tax(cid)` / `world.set_candlemaker11_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate11` / `SetCandlemakerLevelTaxRate11` | `world.candlemaker11_level_tax(0)` |
| `world.carpenter11_level_tax(cid)` / `world.set_carpenter11_level_tax(cid,v)` | `GetCarpenterLevelTaxRate11` / `SetCarpenterLevelTaxRate11` | `world.carpenter11_level_tax(0)` |
| `world.cartwright11_level_tax(cid)` / `world.set_cartwright11_level_tax(cid,v)` | `GetCartwrightLevelTaxRate11` / `SetCartwrightLevelTaxRate11` | `world.cartwright11_level_tax(0)` |
| `world.castle11_level_tax(cid)` / `world.set_castle11_level_tax(cid,v)` | `GetCastleLevelTaxRate11` / `SetCastleLevelTaxRate11` | `world.castle11_level_tax(0)` |
| `world.cathedral11_level_tax(cid)` / `world.set_cathedral11_level_tax(cid,v)` | `GetCathedralLevelTaxRate11` / `SetCathedralLevelTaxRate11` | `world.cathedral11_level_tax(0)` |
| `world.chandler11_level_tax(cid)` / `world.set_chandler11_level_tax(cid,v)` | `GetChandlerLevelTaxRate11` / `SetChandlerLevelTaxRate11` | `world.chandler11_level_tax(0)` |
| `world.chapel11_level_tax(cid)` / `world.set_chapel11_level_tax(cid,v)` | `GetChapelLevelTaxRate11` / `SetChapelLevelTaxRate11` | `world.chapel11_level_tax(0)` |
| `world.church11_level_tax(cid)` / `world.set_church11_level_tax(cid,v)` | `GetChurchLevelTaxRate11` / `SetChurchLevelTaxRate11` | `world.church11_level_tax(0)` |
| `world.cobbler11_level_tax(cid)` / `world.set_cobbler11_level_tax(cid,v)` | `GetCobblerLevelTaxRate11` / `SetCobblerLevelTaxRate11` | `world.cobbler11_level_tax(0)` |
| `world.contor11_level_tax(cid)` / `world.set_contor11_level_tax(cid,v)` | `GetContorLevelTaxRate11` / `SetContorLevelTaxRate11` | `world.contor11_level_tax(0)` |
| `world.cook11_level_tax(cid)` / `world.set_cook11_level_tax(cid,v)` | `GetCookLevelTaxRate11` / `SetCookLevelTaxRate11` | `world.cook11_level_tax(0)` |
| `world.cooper11_level_tax(cid)` / `world.set_cooper11_level_tax(cid,v)` | `GetCooperLevelTaxRate11` / `SetCooperLevelTaxRate11` | `world.cooper11_level_tax(0)` |
| `world.courthouse11_level_tax(cid)` / `world.set_courthouse11_level_tax(cid,v)` | `GetCourthouseLevelTaxRate11` / `SetCourthouseLevelTaxRate11` | `world.courthouse11_level_tax(0)` |
| `world.dairy11_level_tax(cid)` / `world.set_dairy11_level_tax(cid,v)` | `GetDairyLevelTaxRate11` / `SetDairyLevelTaxRate11` | `world.dairy11_level_tax(0)` |
| `world.dice_house11_level_tax(cid)` / `world.set_dice_house11_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate11` / `SetDiceHouseLevelTaxRate11` | `world.dice_house11_level_tax(0)` |
| `world.distiller11_level_tax(cid)` / `world.set_distiller11_level_tax(cid,v)` | `GetDistillerLevelTaxRate11` / `SetDistillerLevelTaxRate11` | `world.distiller11_level_tax(0)` |
| `world.dyer11_level_tax(cid)` / `world.set_dyer11_level_tax(cid,v)` | `GetDyerLevelTaxRate11` / `SetDyerLevelTaxRate11` | `world.dyer11_level_tax(0)` |
| `world.fishery11_level_tax(cid)` / `world.set_fishery11_level_tax(cid,v)` | `GetFisheryLevelTaxRate11` / `SetFisheryLevelTaxRate11` | `world.fishery11_level_tax(0)` |
| `world.forum11_level_tax(cid)` / `world.set_forum11_level_tax(cid,v)` | `GetForumLevelTaxRate11` / `SetForumLevelTaxRate11` | `world.forum11_level_tax(0)` |
| `world.fowler11_level_tax(cid)` / `world.set_fowler11_level_tax(cid,v)` | `GetFowlerLevelTaxRate11` / `SetFowlerLevelTaxRate11` | `world.fowler11_level_tax(0)` |
| `world.furrier11_level_tax(cid)` / `world.set_furrier11_level_tax(cid,v)` | `GetFurrierLevelTaxRate11` / `SetFurrierLevelTaxRate11` | `world.furrier11_level_tax(0)` |
| `world.garrison11_level_tax(cid)` / `world.set_garrison11_level_tax(cid,v)` | `GetGarrisonLevelTaxRate11` / `SetGarrisonLevelTaxRate11` | `world.garrison11_level_tax(0)` |
| `world.gates11_level_tax(cid)` / `world.set_gates11_level_tax(cid,v)` | `GetGatesLevelTaxRate11` / `SetGatesLevelTaxRate11` | `world.gates11_level_tax(0)` |
| `world.glassblower11_level_tax(cid)` / `world.set_glassblower11_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate11` / `SetGlassblowerLevelTaxRate11` | `world.glassblower11_level_tax(0)` |
| `world.goldbeater11_level_tax(cid)` / `world.set_goldbeater11_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate11` / `SetGoldbeaterLevelTaxRate11` | `world.goldbeater11_level_tax(0)` |
| `world.goldsmith11_level_tax(cid)` / `world.set_goldsmith11_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate11` / `SetGoldsmithLevelTaxRate11` | `world.goldsmith11_level_tax(0)` |
| `world.granary11_level_tax(cid)` / `world.set_granary11_level_tax(cid,v)` | `GetGranaryLevelTaxRate11` / `SetGranaryLevelTaxRate11` | `world.granary11_level_tax(0)` |
| `world.guardhouse11_level_tax(cid)` / `world.set_guardhouse11_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate11` / `SetGuardhouseLevelTaxRate11` | `world.guardhouse11_level_tax(0)` |
| `world.guild_house11_level_tax(cid)` / `world.set_guild_house11_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate11` / `SetGuildHouseLevelTaxRate11` | `world.guild_house11_level_tax(0)` |
| `world.harbor11_level_tax(cid)` / `world.set_harbor11_level_tax(cid,v)` | `GetHarborLevelTaxRate11` / `SetHarborLevelTaxRate11` | `world.harbor11_level_tax(0)` |
| `world.harbor_dock11_level_tax(cid)` / `world.set_harbor_dock11_level_tax(cid,v)` | `GetHarborDockLevelTaxRate11` / `SetHarborDockLevelTaxRate11` | `world.harbor_dock11_level_tax(0)` |
| `world.harbor_walls11_level_tax(cid)` / `world.set_harbor_walls11_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate11` / `SetHarborWallsLevelTaxRate11` | `world.harbor_walls11_level_tax(0)` |
| `world.herb_garden11_level_tax(cid)` / `world.set_herb_garden11_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate11` / `SetHerbGardenLevelTaxRate11` | `world.herb_garden11_level_tax(0)` |
| `world.hospital11_level_tax(cid)` / `world.set_hospital11_level_tax(cid,v)` | `GetHospitalLevelTaxRate11` / `SetHospitalLevelTaxRate11` | `world.hospital11_level_tax(0)` |
| `world.house11_level_tax(cid)` / `world.set_house11_level_tax(cid,v)` | `GetHouseLevelTaxRate11` / `SetHouseLevelTaxRate11` | `world.house11_level_tax(0)` |
| `world.jeweler11_level_tax(cid)` / `world.set_jeweler11_level_tax(cid,v)` | `GetJewelerLevelTaxRate11` / `SetJewelerLevelTaxRate11` | `world.jeweler11_level_tax(0)` |
| `world.library11_level_tax(cid)` / `world.set_library11_level_tax(cid,v)` | `GetLibraryLevelTaxRate11` / `SetLibraryLevelTaxRate11` | `world.library11_level_tax(0)` |
| `world.library_hall11_level_tax(cid)` / `world.set_library_hall11_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate11` / `SetLibraryHallLevelTaxRate11` | `world.library_hall11_level_tax(0)` |
| `world.market11_level_tax(cid)` / `world.set_market11_level_tax(cid,v)` | `GetMarketLevelTaxRate11` / `SetMarketLevelTaxRate11` | `world.market11_level_tax(0)` |
| `world.miller11_level_tax(cid)` / `world.set_miller11_level_tax(cid,v)` | `GetMillerLevelTaxRate11` / `SetMillerLevelTaxRate11` | `world.miller11_level_tax(0)` |
| `world.mine11_level_tax(cid)` / `world.set_mine11_level_tax(cid,v)` | `GetMineLevelTaxRate11` / `SetMineLevelTaxRate11` | `world.mine11_level_tax(0)` |
| `world.mint11_level_tax(cid)` / `world.set_mint11_level_tax(cid,v)` | `GetMintLevelTaxRate11` / `SetMintLevelTaxRate11` | `world.mint11_level_tax(0)` |
| `world.monastery11_level_tax(cid)` / `world.set_monastery11_level_tax(cid,v)` | `GetMonasteryLevelTaxRate11` / `SetMonasteryLevelTaxRate11` | `world.monastery11_level_tax(0)` |
| `world.papermill11_level_tax(cid)` / `world.set_papermill11_level_tax(cid,v)` | `GetPapermillLevelTaxRate11` / `SetPapermillLevelTaxRate11` | `world.papermill11_level_tax(0)` |
| `world.perfumer11_level_tax(cid)` / `world.set_perfumer11_level_tax(cid,v)` | `GetPerfumerLevelTaxRate11` / `SetPerfumerLevelTaxRate11` | `world.perfumer11_level_tax(0)` |
| `world.potter11_level_tax(cid)` / `world.set_potter11_level_tax(cid,v)` | `GetPotterLevelTaxRate11` / `SetPotterLevelTaxRate11` | `world.potter11_level_tax(0)` |
| `world.pottery11_level_tax(cid)` / `world.set_pottery11_level_tax(cid,v)` | `GetPotteryLevelTaxRate11` / `SetPotteryLevelTaxRate11` | `world.pottery11_level_tax(0)` |
| `world.printing_house11_level_tax(cid)` / `world.set_printing_house11_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate11` / `SetPrintingHouseLevelTaxRate11` | `world.printing_house11_level_tax(0)` |
| `world.ropemaker11_level_tax(cid)` / `world.set_ropemaker11_level_tax(cid,v)` | `GetRopemakerLevelTaxRate11` / `SetRopemakerLevelTaxRate11` | `world.ropemaker11_level_tax(0)` |
| `world.ropemaker_workshop11_level_tax(cid)` / `world.set_ropemaker_workshop11_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate11` / `SetRopemakerWorkshopLevelTaxRate11` | `world.ropemaker_workshop11_level_tax(0)` |
| `world.saddler11_level_tax(cid)` / `world.set_saddler11_level_tax(cid,v)` | `GetSaddlerLevelTaxRate11` / `SetSaddlerLevelTaxRate11` | `world.saddler11_level_tax(0)` |
| `world.school11_level_tax(cid)` / `world.set_school11_level_tax(cid,v)` | `GetSchoolLevelTaxRate11` / `SetSchoolLevelTaxRate11` | `world.school11_level_tax(0)` |
| `world.schoolhouse11_level_tax(cid)` / `world.set_schoolhouse11_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate11` / `SetSchoolhouseLevelTaxRate11` | `world.schoolhouse11_level_tax(0)` |
| `world.sentry_tower11_level_tax(cid)` / `world.set_sentry_tower11_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate11` / `SetSentryTowerLevelTaxRate11` | `world.sentry_tower11_level_tax(0)` |
| `world.stables11_level_tax(cid)` / `world.set_stables11_level_tax(cid,v)` | `GetStablesLevelTaxRate11` / `SetStablesLevelTaxRate11` | `world.stables11_level_tax(0)` |
| `world.stonecutter11_level_tax(cid)` / `world.set_stonecutter11_level_tax(cid,v)` | `GetStonecutterLevelTaxRate11` / `SetStonecutterLevelTaxRate11` | `world.stonecutter11_level_tax(0)` |
| `world.tailor11_level_tax(cid)` / `world.set_tailor11_level_tax(cid,v)` | `GetTailorLevelTaxRate11` / `SetTailorLevelTaxRate11` | `world.tailor11_level_tax(0)` |
| `world.tannery11_level_tax(cid)` / `world.set_tannery11_level_tax(cid,v)` | `GetTanneryLevelTaxRate11` / `SetTanneryLevelTaxRate11` | `world.tannery11_level_tax(0)` |
| `world.tavern11_level_tax(cid)` / `world.set_tavern11_level_tax(cid,v)` | `GetTavernLevelTaxRate11` / `SetTavernLevelTaxRate11` | `world.tavern11_level_tax(0)` |
| `world.thieves_guild11_level_tax(cid)` / `world.set_thieves_guild11_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate11` / `SetThievesGuildLevelTaxRate11` | `world.thieves_guild11_level_tax(0)` |
| `world.toolmaker11_level_tax(cid)` / `world.set_toolmaker11_level_tax(cid,v)` | `GetToolmakerLevelTaxRate11` / `SetToolmakerLevelTaxRate11` | `world.toolmaker11_level_tax(0)` |
| `world.tower11_level_tax(cid)` / `world.set_tower11_level_tax(cid,v)` | `GetTowerLevelTaxRate11` / `SetTowerLevelTaxRate11` | `world.tower11_level_tax(0)` |
| `world.town_hall12_level_tax(cid)` / `world.set_town_hall12_level_tax(cid,v)` | `GetTownHallLevelTaxRate12` / `SetTownHallLevelTaxRate12` | `world.town_hall12_level_tax(0)` |
| `world.turner11_level_tax(cid)` / `world.set_turner11_level_tax(cid,v)` | `GetTurnerLevelTaxRate11` / `SetTurnerLevelTaxRate11` | `world.turner11_level_tax(0)` |
| `world.university12_level_tax(cid)` / `world.set_university12_level_tax(cid,v)` | `GetUniversityLevelTaxRate12` / `SetUniversityLevelTaxRate12` | `world.university12_level_tax(0)` |
| `world.university_hall11_level_tax(cid)` / `world.set_university_hall11_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate11` / `SetUniversityHallLevelTaxRate11` | `world.university_hall11_level_tax(0)` |
| `world.vineyard11_level_tax(cid)` / `world.set_vineyard11_level_tax(cid,v)` | `GetVineyardLevelTaxRate11` / `SetVineyardLevelTaxRate11` | `world.vineyard11_level_tax(0)` |
| `world.vintner11_level_tax(cid)` / `world.set_vintner11_level_tax(cid,v)` | `GetVintnerLevelTaxRate11` / `SetVintnerLevelTaxRate11` | `world.vintner11_level_tax(0)` |
| `world.wall12_level_tax(cid)` / `world.set_wall12_level_tax(cid,v)` | `GetWallLevelTaxRate12` / `SetWallLevelTaxRate12` | `world.wall12_level_tax(0)` |
| `world.warehouse11_level_tax(cid)` / `world.set_warehouse11_level_tax(cid,v)` | `GetWarehouseLevelTaxRate11` / `SetWarehouseLevelTaxRate11` | `world.warehouse11_level_tax(0)` |
| `world.weaving_mill11_level_tax(cid)` / `world.set_weaving_mill11_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate11` / `SetWeavingMillLevelTaxRate11` | `world.weaving_mill11_level_tax(0)` |
| `world.well11_level_tax(cid)` / `world.set_well11_level_tax(cid,v)` | `GetWellLevelTaxRate11` / `SetWellLevelTaxRate11` | `world.well11_level_tax(0)` |
| `world.armorer11_level_tax(cid)` / `world.set_armorer11_level_tax(cid,v)` | `GetArmorerLevelTaxRate11` / `SetArmorerLevelTaxRate11` | `world.armorer11_level_tax(0)` |
| `world.candlemaker12_level_tax(cid)` / `world.set_candlemaker12_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate12` / `SetCandlemakerLevelTaxRate12` | `world.candlemaker12_level_tax(0)` |
| `world.carpenter12_level_tax(cid)` / `world.set_carpenter12_level_tax(cid,v)` | `GetCarpenterLevelTaxRate12` / `SetCarpenterLevelTaxRate12` | `world.carpenter12_level_tax(0)` |
| `world.cartwright12_level_tax(cid)` / `world.set_cartwright12_level_tax(cid,v)` | `GetCartwrightLevelTaxRate12` / `SetCartwrightLevelTaxRate12` | `world.cartwright12_level_tax(0)` |
| `world.chandler12_level_tax(cid)` / `world.set_chandler12_level_tax(cid,v)` | `GetChandlerLevelTaxRate12` / `SetChandlerLevelTaxRate12` | `world.chandler12_level_tax(0)` |
| `world.charcoal11_level_tax(cid)` / `world.set_charcoal11_level_tax(cid,v)` | `GetCharcoalLevelTaxRate11` / `SetCharcoalLevelTaxRate11` | `world.charcoal11_level_tax(0)` |
| `world.charcoal12_level_tax(cid)` / `world.set_charcoal12_level_tax(cid,v)` | `GetCharcoalLevelTaxRate12` / `SetCharcoalLevelTaxRate12` | `world.charcoal12_level_tax(0)` |
| `world.church12_level_tax(cid)` / `world.set_church12_level_tax(cid,v)` | `GetChurchLevelTaxRate12` / `SetChurchLevelTaxRate12` | `world.church12_level_tax(0)` |
| `world.cobbler12_level_tax(cid)` / `world.set_cobbler12_level_tax(cid,v)` | `GetCobblerLevelTaxRate12` / `SetCobblerLevelTaxRate12` | `world.cobbler12_level_tax(0)` |
| `world.contor12_level_tax(cid)` / `world.set_contor12_level_tax(cid,v)` | `GetContorLevelTaxRate12` / `SetContorLevelTaxRate12` | `world.contor12_level_tax(0)` |
| `world.cook12_level_tax(cid)` / `world.set_cook12_level_tax(cid,v)` | `GetCookLevelTaxRate12` / `SetCookLevelTaxRate12` | `world.cook12_level_tax(0)` |
| `world.cooper12_level_tax(cid)` / `world.set_cooper12_level_tax(cid,v)` | `GetCooperLevelTaxRate12` / `SetCooperLevelTaxRate12` | `world.cooper12_level_tax(0)` |
| `world.courthouse12_level_tax(cid)` / `world.set_courthouse12_level_tax(cid,v)` | `GetCourthouseLevelTaxRate12` / `SetCourthouseLevelTaxRate12` | `world.courthouse12_level_tax(0)` |
| `world.dairy12_level_tax(cid)` / `world.set_dairy12_level_tax(cid,v)` | `GetDairyLevelTaxRate12` / `SetDairyLevelTaxRate12` | `world.dairy12_level_tax(0)` |
| `world.dice_house12_level_tax(cid)` / `world.set_dice_house12_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate12` / `SetDiceHouseLevelTaxRate12` | `world.dice_house12_level_tax(0)` |
| `world.distiller12_level_tax(cid)` / `world.set_distiller12_level_tax(cid,v)` | `GetDistillerLevelTaxRate12` / `SetDistillerLevelTaxRate12` | `world.distiller12_level_tax(0)` |
| `world.dyer12_level_tax(cid)` / `world.set_dyer12_level_tax(cid,v)` | `GetDyerLevelTaxRate12` / `SetDyerLevelTaxRate12` | `world.dyer12_level_tax(0)` |
| `world.fishery12_level_tax(cid)` / `world.set_fishery12_level_tax(cid,v)` | `GetFisheryLevelTaxRate12` / `SetFisheryLevelTaxRate12` | `world.fishery12_level_tax(0)` |
| `world.forum12_level_tax(cid)` / `world.set_forum12_level_tax(cid,v)` | `GetForumLevelTaxRate12` / `SetForumLevelTaxRate12` | `world.forum12_level_tax(0)` |
| `world.fowler12_level_tax(cid)` / `world.set_fowler12_level_tax(cid,v)` | `GetFowlerLevelTaxRate12` / `SetFowlerLevelTaxRate12` | `world.fowler12_level_tax(0)` |
| `world.furrier12_level_tax(cid)` / `world.set_furrier12_level_tax(cid,v)` | `GetFurrierLevelTaxRate12` / `SetFurrierLevelTaxRate12` | `world.furrier12_level_tax(0)` |
| `world.garrison12_level_tax(cid)` / `world.set_garrison12_level_tax(cid,v)` | `GetGarrisonLevelTaxRate12` / `SetGarrisonLevelTaxRate12` | `world.garrison12_level_tax(0)` |
| `world.gates12_level_tax(cid)` / `world.set_gates12_level_tax(cid,v)` | `GetGatesLevelTaxRate12` / `SetGatesLevelTaxRate12` | `world.gates12_level_tax(0)` |
| `world.glassblower12_level_tax(cid)` / `world.set_glassblower12_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate12` / `SetGlassblowerLevelTaxRate12` | `world.glassblower12_level_tax(0)` |
| `world.goldbeater12_level_tax(cid)` / `world.set_goldbeater12_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate12` / `SetGoldbeaterLevelTaxRate12` | `world.goldbeater12_level_tax(0)` |
| `world.goldsmith12_level_tax(cid)` / `world.set_goldsmith12_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate12` / `SetGoldsmithLevelTaxRate12` | `world.goldsmith12_level_tax(0)` |
| `world.granary12_level_tax(cid)` / `world.set_granary12_level_tax(cid,v)` | `GetGranaryLevelTaxRate12` / `SetGranaryLevelTaxRate12` | `world.granary12_level_tax(0)` |
| `world.guardhouse12_level_tax(cid)` / `world.set_guardhouse12_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate12` / `SetGuardhouseLevelTaxRate12` | `world.guardhouse12_level_tax(0)` |
| `world.guild_house12_level_tax(cid)` / `world.set_guild_house12_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate12` / `SetGuildHouseLevelTaxRate12` | `world.guild_house12_level_tax(0)` |
| `world.harbor12_level_tax(cid)` / `world.set_harbor12_level_tax(cid,v)` | `GetHarborLevelTaxRate12` / `SetHarborLevelTaxRate12` | `world.harbor12_level_tax(0)` |
| `world.harbor_dock12_level_tax(cid)` / `world.set_harbor_dock12_level_tax(cid,v)` | `GetHarborDockLevelTaxRate12` / `SetHarborDockLevelTaxRate12` | `world.harbor_dock12_level_tax(0)` |
| `world.harbor_walls12_level_tax(cid)` / `world.set_harbor_walls12_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate12` / `SetHarborWallsLevelTaxRate12` | `world.harbor_walls12_level_tax(0)` |
| `world.herb_garden12_level_tax(cid)` / `world.set_herb_garden12_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate12` / `SetHerbGardenLevelTaxRate12` | `world.herb_garden12_level_tax(0)` |
| `world.hospital12_level_tax(cid)` / `world.set_hospital12_level_tax(cid,v)` | `GetHospitalLevelTaxRate12` / `SetHospitalLevelTaxRate12` | `world.hospital12_level_tax(0)` |
| `world.house12_level_tax(cid)` / `world.set_house12_level_tax(cid,v)` | `GetHouseLevelTaxRate12` / `SetHouseLevelTaxRate12` | `world.house12_level_tax(0)` |
| `world.jeweler12_level_tax(cid)` / `world.set_jeweler12_level_tax(cid,v)` | `GetJewelerLevelTaxRate12` / `SetJewelerLevelTaxRate12` | `world.jeweler12_level_tax(0)` |
| `world.library12_level_tax(cid)` / `world.set_library12_level_tax(cid,v)` | `GetLibraryLevelTaxRate12` / `SetLibraryLevelTaxRate12` | `world.library12_level_tax(0)` |
| `world.library_hall12_level_tax(cid)` / `world.set_library_hall12_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate12` / `SetLibraryHallLevelTaxRate12` | `world.library_hall12_level_tax(0)` |
| `world.market12_level_tax(cid)` / `world.set_market12_level_tax(cid,v)` | `GetMarketLevelTaxRate12` / `SetMarketLevelTaxRate12` | `world.market12_level_tax(0)` |
| `world.miller12_level_tax(cid)` / `world.set_miller12_level_tax(cid,v)` | `GetMillerLevelTaxRate12` / `SetMillerLevelTaxRate12` | `world.miller12_level_tax(0)` |
| `world.mine12_level_tax(cid)` / `world.set_mine12_level_tax(cid,v)` | `GetMineLevelTaxRate12` / `SetMineLevelTaxRate12` | `world.mine12_level_tax(0)` |
| `world.mint12_level_tax(cid)` / `world.set_mint12_level_tax(cid,v)` | `GetMintLevelTaxRate12` / `SetMintLevelTaxRate12` | `world.mint12_level_tax(0)` |
| `world.monastery12_level_tax(cid)` / `world.set_monastery12_level_tax(cid,v)` | `GetMonasteryLevelTaxRate12` / `SetMonasteryLevelTaxRate12` | `world.monastery12_level_tax(0)` |
| `world.papermill12_level_tax(cid)` / `world.set_papermill12_level_tax(cid,v)` | `GetPapermillLevelTaxRate12` / `SetPapermillLevelTaxRate12` | `world.papermill12_level_tax(0)` |
| `world.perfumer12_level_tax(cid)` / `world.set_perfumer12_level_tax(cid,v)` | `GetPerfumerLevelTaxRate12` / `SetPerfumerLevelTaxRate12` | `world.perfumer12_level_tax(0)` |
| `world.potter12_level_tax(cid)` / `world.set_potter12_level_tax(cid,v)` | `GetPotterLevelTaxRate12` / `SetPotterLevelTaxRate12` | `world.potter12_level_tax(0)` |
| `world.pottery12_level_tax(cid)` / `world.set_pottery12_level_tax(cid,v)` | `GetPotteryLevelTaxRate12` / `SetPotteryLevelTaxRate12` | `world.pottery12_level_tax(0)` |
| `world.printing_house12_level_tax(cid)` / `world.set_printing_house12_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate12` / `SetPrintingHouseLevelTaxRate12` | `world.printing_house12_level_tax(0)` |
| `world.ropemaker12_level_tax(cid)` / `world.set_ropemaker12_level_tax(cid,v)` | `GetRopemakerLevelTaxRate12` / `SetRopemakerLevelTaxRate12` | `world.ropemaker12_level_tax(0)` |
| `world.ropemaker_workshop12_level_tax(cid)` / `world.set_ropemaker_workshop12_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate12` / `SetRopemakerWorkshopLevelTaxRate12` | `world.ropemaker_workshop12_level_tax(0)` |
| `world.saddler12_level_tax(cid)` / `world.set_saddler12_level_tax(cid,v)` | `GetSaddlerLevelTaxRate12` / `SetSaddlerLevelTaxRate12` | `world.saddler12_level_tax(0)` |
| `world.school12_level_tax(cid)` / `world.set_school12_level_tax(cid,v)` | `GetSchoolLevelTaxRate12` / `SetSchoolLevelTaxRate12` | `world.school12_level_tax(0)` |
| `world.schoolhouse12_level_tax(cid)` / `world.set_schoolhouse12_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate12` / `SetSchoolhouseLevelTaxRate12` | `world.schoolhouse12_level_tax(0)` |
| `world.sentry_tower12_level_tax(cid)` / `world.set_sentry_tower12_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate12` / `SetSentryTowerLevelTaxRate12` | `world.sentry_tower12_level_tax(0)` |
| `world.stables12_level_tax(cid)` / `world.set_stables12_level_tax(cid,v)` | `GetStablesLevelTaxRate12` / `SetStablesLevelTaxRate12` | `world.stables12_level_tax(0)` |
| `world.stonecutter12_level_tax(cid)` / `world.set_stonecutter12_level_tax(cid,v)` | `GetStonecutterLevelTaxRate12` / `SetStonecutterLevelTaxRate12` | `world.stonecutter12_level_tax(0)` |
| `world.tailor12_level_tax(cid)` / `world.set_tailor12_level_tax(cid,v)` | `GetTailorLevelTaxRate12` / `SetTailorLevelTaxRate12` | `world.tailor12_level_tax(0)` |
| `world.tannery12_level_tax(cid)` / `world.set_tannery12_level_tax(cid,v)` | `GetTanneryLevelTaxRate12` / `SetTanneryLevelTaxRate12` | `world.tannery12_level_tax(0)` |
| `world.tavern12_level_tax(cid)` / `world.set_tavern12_level_tax(cid,v)` | `GetTavernLevelTaxRate12` / `SetTavernLevelTaxRate12` | `world.tavern12_level_tax(0)` |
| `world.thieves_guild12_level_tax(cid)` / `world.set_thieves_guild12_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate12` / `SetThievesGuildLevelTaxRate12` | `world.thieves_guild12_level_tax(0)` |
| `world.toolmaker12_level_tax(cid)` / `world.set_toolmaker12_level_tax(cid,v)` | `GetToolmakerLevelTaxRate12` / `SetToolmakerLevelTaxRate12` | `world.toolmaker12_level_tax(0)` |
| `world.tower12_level_tax(cid)` / `world.set_tower12_level_tax(cid,v)` | `GetTowerLevelTaxRate12` / `SetTowerLevelTaxRate12` | `world.tower12_level_tax(0)` |
| `world.turner12_level_tax(cid)` / `world.set_turner12_level_tax(cid,v)` | `GetTurnerLevelTaxRate12` / `SetTurnerLevelTaxRate12` | `world.turner12_level_tax(0)` |
| `world.university13_level_tax(cid)` / `world.set_university13_level_tax(cid,v)` | `GetUniversityLevelTaxRate13` / `SetUniversityLevelTaxRate13` | `world.university13_level_tax(0)` |
| `world.university_hall12_level_tax(cid)` / `world.set_university_hall12_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate12` / `SetUniversityHallLevelTaxRate12` | `world.university_hall12_level_tax(0)` |
| `world.vineyard12_level_tax(cid)` / `world.set_vineyard12_level_tax(cid,v)` | `GetVineyardLevelTaxRate12` / `SetVineyardLevelTaxRate12` | `world.vineyard12_level_tax(0)` |
| `world.vintner12_level_tax(cid)` / `world.set_vintner12_level_tax(cid,v)` | `GetVintnerLevelTaxRate12` / `SetVintnerLevelTaxRate12` | `world.vintner12_level_tax(0)` |
| `world.wall13_level_tax(cid)` / `world.set_wall13_level_tax(cid,v)` | `GetWallLevelTaxRate13` / `SetWallLevelTaxRate13` | `world.wall13_level_tax(0)` |
| `world.warehouse12_level_tax(cid)` / `world.set_warehouse12_level_tax(cid,v)` | `GetWarehouseLevelTaxRate12` / `SetWarehouseLevelTaxRate12` | `world.warehouse12_level_tax(0)` |
| `world.weaving_mill12_level_tax(cid)` / `world.set_weaving_mill12_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate12` / `SetWeavingMillLevelTaxRate12` | `world.weaving_mill12_level_tax(0)` |
| `world.well12_level_tax(cid)` / `world.set_well12_level_tax(cid,v)` | `GetWellLevelTaxRate12` / `SetWellLevelTaxRate12` | `world.well12_level_tax(0)` |
| `world.armorer12_level_tax(cid)` / `world.set_armorer12_level_tax(cid,v)` | `GetArmorerLevelTaxRate12` / `SetArmorerLevelTaxRate12` | `world.armorer12_level_tax(0)` |
| `world.baker12_level_tax(cid)` / `world.set_baker12_level_tax(cid,v)` | `GetBakerLevelTaxRate12` / `SetBakerLevelTaxRate12` | `world.baker12_level_tax(0)` |
| `world.barber12_level_tax(cid)` / `world.set_barber12_level_tax(cid,v)` | `GetBarberLevelTaxRate12` / `SetBarberLevelTaxRate12` | `world.barber12_level_tax(0)` |
| `world.bathhouse12_level_tax(cid)` / `world.set_bathhouse12_level_tax(cid,v)` | `GetBathhouseLevelTaxRate12` / `SetBathhouseLevelTaxRate12` | `world.bathhouse12_level_tax(0)` |
| `world.bowyer12_level_tax(cid)` / `world.set_bowyer12_level_tax(cid,v)` | `GetBowyerLevelTaxRate12` / `SetBowyerLevelTaxRate12` | `world.bowyer12_level_tax(0)` |
| `world.brewmaster12_level_tax(cid)` / `world.set_brewmaster12_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate12` / `SetBrewmasterLevelTaxRate12` | `world.brewmaster12_level_tax(0)` |
| `world.brickmaker12_level_tax(cid)` / `world.set_brickmaker12_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate12` / `SetBrickmakerLevelTaxRate12` | `world.brickmaker12_level_tax(0)` |
| `world.bridge12_level_tax(cid)` / `world.set_bridge12_level_tax(cid,v)` | `GetBridgeLevelTaxRate12` / `SetBridgeLevelTaxRate12` | `world.bridge12_level_tax(0)` |
| `world.brothel12_level_tax(cid)` / `world.set_brothel12_level_tax(cid,v)` | `GetBrothelLevelTaxRate12` / `SetBrothelLevelTaxRate12` | `world.brothel12_level_tax(0)` |
| `world.butcher12_level_tax(cid)` / `world.set_butcher12_level_tax(cid,v)` | `GetButcherLevelTaxRate12` / `SetButcherLevelTaxRate12` | `world.butcher12_level_tax(0)` |
| `world.castle12_level_tax(cid)` / `world.set_castle12_level_tax(cid,v)` | `GetCastleLevelTaxRate12` / `SetCastleLevelTaxRate12` | `world.castle12_level_tax(0)` |
| `world.cathedral12_level_tax(cid)` / `world.set_cathedral12_level_tax(cid,v)` | `GetCathedralLevelTaxRate12` / `SetCathedralLevelTaxRate12` | `world.cathedral12_level_tax(0)` |
| `world.chandler13_level_tax(cid)` / `world.set_chandler13_level_tax(cid,v)` | `GetChandlerLevelTaxRate13` / `SetChandlerLevelTaxRate13` | `world.chandler13_level_tax(0)` |
| `world.chapel12_level_tax(cid)` / `world.set_chapel12_level_tax(cid,v)` | `GetChapelLevelTaxRate12` / `SetChapelLevelTaxRate12` | `world.chapel12_level_tax(0)` |
| `world.church13_level_tax(cid)` / `world.set_church13_level_tax(cid,v)` | `GetChurchLevelTaxRate13` / `SetChurchLevelTaxRate13` | `world.church13_level_tax(0)` |
| `world.cobbler13_level_tax(cid)` / `world.set_cobbler13_level_tax(cid,v)` | `GetCobblerLevelTaxRate13` / `SetCobblerLevelTaxRate13` | `world.cobbler13_level_tax(0)` |
| `world.contor13_level_tax(cid)` / `world.set_contor13_level_tax(cid,v)` | `GetContorLevelTaxRate13` / `SetContorLevelTaxRate13` | `world.contor13_level_tax(0)` |
| `world.cook13_level_tax(cid)` / `world.set_cook13_level_tax(cid,v)` | `GetCookLevelTaxRate13` / `SetCookLevelTaxRate13` | `world.cook13_level_tax(0)` |
| `world.cooper13_level_tax(cid)` / `world.set_cooper13_level_tax(cid,v)` | `GetCooperLevelTaxRate13` / `SetCooperLevelTaxRate13` | `world.cooper13_level_tax(0)` |
| `world.courthouse13_level_tax(cid)` / `world.set_courthouse13_level_tax(cid,v)` | `GetCourthouseLevelTaxRate13` / `SetCourthouseLevelTaxRate13` | `world.courthouse13_level_tax(0)` |
| `world.dairy13_level_tax(cid)` / `world.set_dairy13_level_tax(cid,v)` | `GetDairyLevelTaxRate13` / `SetDairyLevelTaxRate13` | `world.dairy13_level_tax(0)` |
| `world.dice_house13_level_tax(cid)` / `world.set_dice_house13_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate13` / `SetDiceHouseLevelTaxRate13` | `world.dice_house13_level_tax(0)` |
| `world.distiller13_level_tax(cid)` / `world.set_distiller13_level_tax(cid,v)` | `GetDistillerLevelTaxRate13` / `SetDistillerLevelTaxRate13` | `world.distiller13_level_tax(0)` |
| `world.dyer13_level_tax(cid)` / `world.set_dyer13_level_tax(cid,v)` | `GetDyerLevelTaxRate13` / `SetDyerLevelTaxRate13` | `world.dyer13_level_tax(0)` |
| `world.fishery13_level_tax(cid)` / `world.set_fishery13_level_tax(cid,v)` | `GetFisheryLevelTaxRate13` / `SetFisheryLevelTaxRate13` | `world.fishery13_level_tax(0)` |
| `world.forum13_level_tax(cid)` / `world.set_forum13_level_tax(cid,v)` | `GetForumLevelTaxRate13` / `SetForumLevelTaxRate13` | `world.forum13_level_tax(0)` |
| `world.fowler13_level_tax(cid)` / `world.set_fowler13_level_tax(cid,v)` | `GetFowlerLevelTaxRate13` / `SetFowlerLevelTaxRate13` | `world.fowler13_level_tax(0)` |
| `world.furrier13_level_tax(cid)` / `world.set_furrier13_level_tax(cid,v)` | `GetFurrierLevelTaxRate13` / `SetFurrierLevelTaxRate13` | `world.furrier13_level_tax(0)` |
| `world.garrison13_level_tax(cid)` / `world.set_garrison13_level_tax(cid,v)` | `GetGarrisonLevelTaxRate13` / `SetGarrisonLevelTaxRate13` | `world.garrison13_level_tax(0)` |
| `world.gates13_level_tax(cid)` / `world.set_gates13_level_tax(cid,v)` | `GetGatesLevelTaxRate13` / `SetGatesLevelTaxRate13` | `world.gates13_level_tax(0)` |
| `world.glassblower13_level_tax(cid)` / `world.set_glassblower13_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate13` / `SetGlassblowerLevelTaxRate13` | `world.glassblower13_level_tax(0)` |
| `world.goldbeater13_level_tax(cid)` / `world.set_goldbeater13_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate13` / `SetGoldbeaterLevelTaxRate13` | `world.goldbeater13_level_tax(0)` |
| `world.goldsmith13_level_tax(cid)` / `world.set_goldsmith13_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate13` / `SetGoldsmithLevelTaxRate13` | `world.goldsmith13_level_tax(0)` |
| `world.granary13_level_tax(cid)` / `world.set_granary13_level_tax(cid,v)` | `GetGranaryLevelTaxRate13` / `SetGranaryLevelTaxRate13` | `world.granary13_level_tax(0)` |
| `world.guardhouse13_level_tax(cid)` / `world.set_guardhouse13_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate13` / `SetGuardhouseLevelTaxRate13` | `world.guardhouse13_level_tax(0)` |
| `world.guild_house13_level_tax(cid)` / `world.set_guild_house13_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate13` / `SetGuildHouseLevelTaxRate13` | `world.guild_house13_level_tax(0)` |
| `world.harbor13_level_tax(cid)` / `world.set_harbor13_level_tax(cid,v)` | `GetHarborLevelTaxRate13` / `SetHarborLevelTaxRate13` | `world.harbor13_level_tax(0)` |
| `world.harbor_dock13_level_tax(cid)` / `world.set_harbor_dock13_level_tax(cid,v)` | `GetHarborDockLevelTaxRate13` / `SetHarborDockLevelTaxRate13` | `world.harbor_dock13_level_tax(0)` |
| `world.harbor_walls13_level_tax(cid)` / `world.set_harbor_walls13_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate13` / `SetHarborWallsLevelTaxRate13` | `world.harbor_walls13_level_tax(0)` |
| `world.herb_garden13_level_tax(cid)` / `world.set_herb_garden13_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate13` / `SetHerbGardenLevelTaxRate13` | `world.herb_garden13_level_tax(0)` |
| `world.hospital13_level_tax(cid)` / `world.set_hospital13_level_tax(cid,v)` | `GetHospitalLevelTaxRate13` / `SetHospitalLevelTaxRate13` | `world.hospital13_level_tax(0)` |
| `world.house13_level_tax(cid)` / `world.set_house13_level_tax(cid,v)` | `GetHouseLevelTaxRate13` / `SetHouseLevelTaxRate13` | `world.house13_level_tax(0)` |
| `world.jeweler13_level_tax(cid)` / `world.set_jeweler13_level_tax(cid,v)` | `GetJewelerLevelTaxRate13` / `SetJewelerLevelTaxRate13` | `world.jeweler13_level_tax(0)` |
| `world.library13_level_tax(cid)` / `world.set_library13_level_tax(cid,v)` | `GetLibraryLevelTaxRate13` / `SetLibraryLevelTaxRate13` | `world.library13_level_tax(0)` |
| `world.library_hall13_level_tax(cid)` / `world.set_library_hall13_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate13` / `SetLibraryHallLevelTaxRate13` | `world.library_hall13_level_tax(0)` |
| `world.market13_level_tax(cid)` / `world.set_market13_level_tax(cid,v)` | `GetMarketLevelTaxRate13` / `SetMarketLevelTaxRate13` | `world.market13_level_tax(0)` |
| `world.miller13_level_tax(cid)` / `world.set_miller13_level_tax(cid,v)` | `GetMillerLevelTaxRate13` / `SetMillerLevelTaxRate13` | `world.miller13_level_tax(0)` |
| `world.mine13_level_tax(cid)` / `world.set_mine13_level_tax(cid,v)` | `GetMineLevelTaxRate13` / `SetMineLevelTaxRate13` | `world.mine13_level_tax(0)` |
| `world.mint13_level_tax(cid)` / `world.set_mint13_level_tax(cid,v)` | `GetMintLevelTaxRate13` / `SetMintLevelTaxRate13` | `world.mint13_level_tax(0)` |
| `world.monastery13_level_tax(cid)` / `world.set_monastery13_level_tax(cid,v)` | `GetMonasteryLevelTaxRate13` / `SetMonasteryLevelTaxRate13` | `world.monastery13_level_tax(0)` |
| `world.papermill13_level_tax(cid)` / `world.set_papermill13_level_tax(cid,v)` | `GetPapermillLevelTaxRate13` / `SetPapermillLevelTaxRate13` | `world.papermill13_level_tax(0)` |
| `world.perfumer13_level_tax(cid)` / `world.set_perfumer13_level_tax(cid,v)` | `GetPerfumerLevelTaxRate13` / `SetPerfumerLevelTaxRate13` | `world.perfumer13_level_tax(0)` |
| `world.potter13_level_tax(cid)` / `world.set_potter13_level_tax(cid,v)` | `GetPotterLevelTaxRate13` / `SetPotterLevelTaxRate13` | `world.potter13_level_tax(0)` |
| `world.pottery13_level_tax(cid)` / `world.set_pottery13_level_tax(cid,v)` | `GetPotteryLevelTaxRate13` / `SetPotteryLevelTaxRate13` | `world.pottery13_level_tax(0)` |
| `world.printing_house13_level_tax(cid)` / `world.set_printing_house13_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate13` / `SetPrintingHouseLevelTaxRate13` | `world.printing_house13_level_tax(0)` |
| `world.ropemaker13_level_tax(cid)` / `world.set_ropemaker13_level_tax(cid,v)` | `GetRopemakerLevelTaxRate13` / `SetRopemakerLevelTaxRate13` | `world.ropemaker13_level_tax(0)` |
| `world.ropemaker_workshop13_level_tax(cid)` / `world.set_ropemaker_workshop13_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate13` / `SetRopemakerWorkshopLevelTaxRate13` | `world.ropemaker_workshop13_level_tax(0)` |
| `world.saddler13_level_tax(cid)` / `world.set_saddler13_level_tax(cid,v)` | `GetSaddlerLevelTaxRate13` / `SetSaddlerLevelTaxRate13` | `world.saddler13_level_tax(0)` |
| `world.school13_level_tax(cid)` / `world.set_school13_level_tax(cid,v)` | `GetSchoolLevelTaxRate13` / `SetSchoolLevelTaxRate13` | `world.school13_level_tax(0)` |
| `world.schoolhouse13_level_tax(cid)` / `world.set_schoolhouse13_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate13` / `SetSchoolhouseLevelTaxRate13` | `world.schoolhouse13_level_tax(0)` |
| `world.sentry_tower13_level_tax(cid)` / `world.set_sentry_tower13_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate13` / `SetSentryTowerLevelTaxRate13` | `world.sentry_tower13_level_tax(0)` |
| `world.stables13_level_tax(cid)` / `world.set_stables13_level_tax(cid,v)` | `GetStablesLevelTaxRate13` / `SetStablesLevelTaxRate13` | `world.stables13_level_tax(0)` |
| `world.stonecutter13_level_tax(cid)` / `world.set_stonecutter13_level_tax(cid,v)` | `GetStonecutterLevelTaxRate13` / `SetStonecutterLevelTaxRate13` | `world.stonecutter13_level_tax(0)` |
| `world.tailor13_level_tax(cid)` / `world.set_tailor13_level_tax(cid,v)` | `GetTailorLevelTaxRate13` / `SetTailorLevelTaxRate13` | `world.tailor13_level_tax(0)` |
| `world.tannery13_level_tax(cid)` / `world.set_tannery13_level_tax(cid,v)` | `GetTanneryLevelTaxRate13` / `SetTanneryLevelTaxRate13` | `world.tannery13_level_tax(0)` |
| `world.tavern13_level_tax(cid)` / `world.set_tavern13_level_tax(cid,v)` | `GetTavernLevelTaxRate13` / `SetTavernLevelTaxRate13` | `world.tavern13_level_tax(0)` |
| `world.thieves_guild13_level_tax(cid)` / `world.set_thieves_guild13_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate13` / `SetThievesGuildLevelTaxRate13` | `world.thieves_guild13_level_tax(0)` |
| `world.toolmaker13_level_tax(cid)` / `world.set_toolmaker13_level_tax(cid,v)` | `GetToolmakerLevelTaxRate13` / `SetToolmakerLevelTaxRate13` | `world.toolmaker13_level_tax(0)` |
| `world.tower13_level_tax(cid)` / `world.set_tower13_level_tax(cid,v)` | `GetTowerLevelTaxRate13` / `SetTowerLevelTaxRate13` | `world.tower13_level_tax(0)` |
| `world.turner13_level_tax(cid)` / `world.set_turner13_level_tax(cid,v)` | `GetTurnerLevelTaxRate13` / `SetTurnerLevelTaxRate13` | `world.turner13_level_tax(0)` |
| `world.university14_level_tax(cid)` / `world.set_university14_level_tax(cid,v)` | `GetUniversityLevelTaxRate14` / `SetUniversityLevelTaxRate14` | `world.university14_level_tax(0)` |
| `world.university_hall13_level_tax(cid)` / `world.set_university_hall13_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate13` / `SetUniversityHallLevelTaxRate13` | `world.university_hall13_level_tax(0)` |
| `world.vineyard13_level_tax(cid)` / `world.set_vineyard13_level_tax(cid,v)` | `GetVineyardLevelTaxRate13` / `SetVineyardLevelTaxRate13` | `world.vineyard13_level_tax(0)` |
| `world.vintner13_level_tax(cid)` / `world.set_vintner13_level_tax(cid,v)` | `GetVintnerLevelTaxRate13` / `SetVintnerLevelTaxRate13` | `world.vintner13_level_tax(0)` |
| `world.wall14_level_tax(cid)` / `world.set_wall14_level_tax(cid,v)` | `GetWallLevelTaxRate14` / `SetWallLevelTaxRate14` | `world.wall14_level_tax(0)` |
| `world.warehouse13_level_tax(cid)` / `world.set_warehouse13_level_tax(cid,v)` | `GetWarehouseLevelTaxRate13` / `SetWarehouseLevelTaxRate13` | `world.warehouse13_level_tax(0)` |
| `world.weaving_mill13_level_tax(cid)` / `world.set_weaving_mill13_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate13` / `SetWeavingMillLevelTaxRate13` | `world.weaving_mill13_level_tax(0)` |
| `world.well13_level_tax(cid)` / `world.set_well13_level_tax(cid,v)` | `GetWellLevelTaxRate13` / `SetWellLevelTaxRate13` | `world.well13_level_tax(0)` |
| `world.armorer13_level_tax(cid)` / `world.set_armorer13_level_tax(cid,v)` | `GetArmorerLevelTaxRate13` / `SetArmorerLevelTaxRate13` | `world.armorer13_level_tax(0)` |
| `world.baker13_level_tax(cid)` / `world.set_baker13_level_tax(cid,v)` | `GetBakerLevelTaxRate13` / `SetBakerLevelTaxRate13` | `world.baker13_level_tax(0)` |
| `world.barber13_level_tax(cid)` / `world.set_barber13_level_tax(cid,v)` | `GetBarberLevelTaxRate13` / `SetBarberLevelTaxRate13` | `world.barber13_level_tax(0)` |
| `world.bathhouse13_level_tax(cid)` / `world.set_bathhouse13_level_tax(cid,v)` | `GetBathhouseLevelTaxRate13` / `SetBathhouseLevelTaxRate13` | `world.bathhouse13_level_tax(0)` |
| `world.bowyer13_level_tax(cid)` / `world.set_bowyer13_level_tax(cid,v)` | `GetBowyerLevelTaxRate13` / `SetBowyerLevelTaxRate13` | `world.bowyer13_level_tax(0)` |
| `world.brewmaster13_level_tax(cid)` / `world.set_brewmaster13_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate13` / `SetBrewmasterLevelTaxRate13` | `world.brewmaster13_level_tax(0)` |
| `world.brickmaker13_level_tax(cid)` / `world.set_brickmaker13_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate13` / `SetBrickmakerLevelTaxRate13` | `world.brickmaker13_level_tax(0)` |
| `world.bridge13_level_tax(cid)` / `world.set_bridge13_level_tax(cid,v)` | `GetBridgeLevelTaxRate13` / `SetBridgeLevelTaxRate13` | `world.bridge13_level_tax(0)` |
| `world.brothel13_level_tax(cid)` / `world.set_brothel13_level_tax(cid,v)` | `GetBrothelLevelTaxRate13` / `SetBrothelLevelTaxRate13` | `world.brothel13_level_tax(0)` |
| `world.butcher13_level_tax(cid)` / `world.set_butcher13_level_tax(cid,v)` | `GetButcherLevelTaxRate13` / `SetButcherLevelTaxRate13` | `world.butcher13_level_tax(0)` |
| `world.candlemaker13_level_tax(cid)` / `world.set_candlemaker13_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate13` / `SetCandlemakerLevelTaxRate13` | `world.candlemaker13_level_tax(0)` |
| `world.carpenter13_level_tax(cid)` / `world.set_carpenter13_level_tax(cid,v)` | `GetCarpenterLevelTaxRate13` / `SetCarpenterLevelTaxRate13` | `world.carpenter13_level_tax(0)` |
| `world.cartwright13_level_tax(cid)` / `world.set_cartwright13_level_tax(cid,v)` | `GetCartwrightLevelTaxRate13` / `SetCartwrightLevelTaxRate13` | `world.cartwright13_level_tax(0)` |
| `world.castle13_level_tax(cid)` / `world.set_castle13_level_tax(cid,v)` | `GetCastleLevelTaxRate13` / `SetCastleLevelTaxRate13` | `world.castle13_level_tax(0)` |
| `world.cathedral13_level_tax(cid)` / `world.set_cathedral13_level_tax(cid,v)` | `GetCathedralLevelTaxRate13` / `SetCathedralLevelTaxRate13` | `world.cathedral13_level_tax(0)` |
| `world.chapel13_level_tax(cid)` / `world.set_chapel13_level_tax(cid,v)` | `GetChapelLevelTaxRate13` / `SetChapelLevelTaxRate13` | `world.chapel13_level_tax(0)` |
| `world.charcoal13_level_tax(cid)` / `world.set_charcoal13_level_tax(cid,v)` | `GetCharcoalLevelTaxRate13` / `SetCharcoalLevelTaxRate13` | `world.charcoal13_level_tax(0)` |
| `world.church14_level_tax(cid)` / `world.set_church14_level_tax(cid,v)` | `GetChurchLevelTaxRate14` / `SetChurchLevelTaxRate14` | `world.church14_level_tax(0)` |
| `world.cobbler14_level_tax(cid)` / `world.set_cobbler14_level_tax(cid,v)` | `GetCobblerLevelTaxRate14` / `SetCobblerLevelTaxRate14` | `world.cobbler14_level_tax(0)` |
| `world.contor14_level_tax(cid)` / `world.set_contor14_level_tax(cid,v)` | `GetContorLevelTaxRate14` / `SetContorLevelTaxRate14` | `world.contor14_level_tax(0)` |
| `world.cook14_level_tax(cid)` / `world.set_cook14_level_tax(cid,v)` | `GetCookLevelTaxRate14` / `SetCookLevelTaxRate14` | `world.cook14_level_tax(0)` |
| `world.cooper14_level_tax(cid)` / `world.set_cooper14_level_tax(cid,v)` | `GetCooperLevelTaxRate14` / `SetCooperLevelTaxRate14` | `world.cooper14_level_tax(0)` |
| `world.courthouse14_level_tax(cid)` / `world.set_courthouse14_level_tax(cid,v)` | `GetCourthouseLevelTaxRate14` / `SetCourthouseLevelTaxRate14` | `world.courthouse14_level_tax(0)` |
| `world.dairy14_level_tax(cid)` / `world.set_dairy14_level_tax(cid,v)` | `GetDairyLevelTaxRate14` / `SetDairyLevelTaxRate14` | `world.dairy14_level_tax(0)` |
| `world.dice_house14_level_tax(cid)` / `world.set_dice_house14_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate14` / `SetDiceHouseLevelTaxRate14` | `world.dice_house14_level_tax(0)` |
| `world.distiller14_level_tax(cid)` / `world.set_distiller14_level_tax(cid,v)` | `GetDistillerLevelTaxRate14` / `SetDistillerLevelTaxRate14` | `world.distiller14_level_tax(0)` |
| `world.dyer14_level_tax(cid)` / `world.set_dyer14_level_tax(cid,v)` | `GetDyerLevelTaxRate14` / `SetDyerLevelTaxRate14` | `world.dyer14_level_tax(0)` |
| `world.fishery14_level_tax(cid)` / `world.set_fishery14_level_tax(cid,v)` | `GetFisheryLevelTaxRate14` / `SetFisheryLevelTaxRate14` | `world.fishery14_level_tax(0)` |
| `world.forum14_level_tax(cid)` / `world.set_forum14_level_tax(cid,v)` | `GetForumLevelTaxRate14` / `SetForumLevelTaxRate14` | `world.forum14_level_tax(0)` |
| `world.fowler14_level_tax(cid)` / `world.set_fowler14_level_tax(cid,v)` | `GetFowlerLevelTaxRate14` / `SetFowlerLevelTaxRate14` | `world.fowler14_level_tax(0)` |
| `world.furrier14_level_tax(cid)` / `world.set_furrier14_level_tax(cid,v)` | `GetFurrierLevelTaxRate14` / `SetFurrierLevelTaxRate14` | `world.furrier14_level_tax(0)` |
| `world.garrison14_level_tax(cid)` / `world.set_garrison14_level_tax(cid,v)` | `GetGarrisonLevelTaxRate14` / `SetGarrisonLevelTaxRate14` | `world.garrison14_level_tax(0)` |
| `world.gates14_level_tax(cid)` / `world.set_gates14_level_tax(cid,v)` | `GetGatesLevelTaxRate14` / `SetGatesLevelTaxRate14` | `world.gates14_level_tax(0)` |
| `world.glassblower14_level_tax(cid)` / `world.set_glassblower14_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate14` / `SetGlassblowerLevelTaxRate14` | `world.glassblower14_level_tax(0)` |
| `world.goldbeater14_level_tax(cid)` / `world.set_goldbeater14_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate14` / `SetGoldbeaterLevelTaxRate14` | `world.goldbeater14_level_tax(0)` |
| `world.goldsmith14_level_tax(cid)` / `world.set_goldsmith14_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate14` / `SetGoldsmithLevelTaxRate14` | `world.goldsmith14_level_tax(0)` |
| `world.granary14_level_tax(cid)` / `world.set_granary14_level_tax(cid,v)` | `GetGranaryLevelTaxRate14` / `SetGranaryLevelTaxRate14` | `world.granary14_level_tax(0)` |
| `world.guardhouse14_level_tax(cid)` / `world.set_guardhouse14_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate14` / `SetGuardhouseLevelTaxRate14` | `world.guardhouse14_level_tax(0)` |
| `world.guild_house14_level_tax(cid)` / `world.set_guild_house14_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate14` / `SetGuildHouseLevelTaxRate14` | `world.guild_house14_level_tax(0)` |
| `world.harbor14_level_tax(cid)` / `world.set_harbor14_level_tax(cid,v)` | `GetHarborLevelTaxRate14` / `SetHarborLevelTaxRate14` | `world.harbor14_level_tax(0)` |
| `world.harbor_dock14_level_tax(cid)` / `world.set_harbor_dock14_level_tax(cid,v)` | `GetHarborDockLevelTaxRate14` / `SetHarborDockLevelTaxRate14` | `world.harbor_dock14_level_tax(0)` |
| `world.harbor_walls14_level_tax(cid)` / `world.set_harbor_walls14_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate14` / `SetHarborWallsLevelTaxRate14` | `world.harbor_walls14_level_tax(0)` |
| `world.herb_garden14_level_tax(cid)` / `world.set_herb_garden14_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate14` / `SetHerbGardenLevelTaxRate14` | `world.herb_garden14_level_tax(0)` |
| `world.hospital14_level_tax(cid)` / `world.set_hospital14_level_tax(cid,v)` | `GetHospitalLevelTaxRate14` / `SetHospitalLevelTaxRate14` | `world.hospital14_level_tax(0)` |
| `world.house14_level_tax(cid)` / `world.set_house14_level_tax(cid,v)` | `GetHouseLevelTaxRate14` / `SetHouseLevelTaxRate14` | `world.house14_level_tax(0)` |
| `world.jeweler14_level_tax(cid)` / `world.set_jeweler14_level_tax(cid,v)` | `GetJewelerLevelTaxRate14` / `SetJewelerLevelTaxRate14` | `world.jeweler14_level_tax(0)` |
| `world.library14_level_tax(cid)` / `world.set_library14_level_tax(cid,v)` | `GetLibraryLevelTaxRate14` / `SetLibraryLevelTaxRate14` | `world.library14_level_tax(0)` |
| `world.library_hall14_level_tax(cid)` / `world.set_library_hall14_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate14` / `SetLibraryHallLevelTaxRate14` | `world.library_hall14_level_tax(0)` |
| `world.market14_level_tax(cid)` / `world.set_market14_level_tax(cid,v)` | `GetMarketLevelTaxRate14` / `SetMarketLevelTaxRate14` | `world.market14_level_tax(0)` |
| `world.miller14_level_tax(cid)` / `world.set_miller14_level_tax(cid,v)` | `GetMillerLevelTaxRate14` / `SetMillerLevelTaxRate14` | `world.miller14_level_tax(0)` |
| `world.mine14_level_tax(cid)` / `world.set_mine14_level_tax(cid,v)` | `GetMineLevelTaxRate14` / `SetMineLevelTaxRate14` | `world.mine14_level_tax(0)` |
| `world.mint14_level_tax(cid)` / `world.set_mint14_level_tax(cid,v)` | `GetMintLevelTaxRate14` / `SetMintLevelTaxRate14` | `world.mint14_level_tax(0)` |
| `world.monastery14_level_tax(cid)` / `world.set_monastery14_level_tax(cid,v)` | `GetMonasteryLevelTaxRate14` / `SetMonasteryLevelTaxRate14` | `world.monastery14_level_tax(0)` |
| `world.papermill14_level_tax(cid)` / `world.set_papermill14_level_tax(cid,v)` | `GetPapermillLevelTaxRate14` / `SetPapermillLevelTaxRate14` | `world.papermill14_level_tax(0)` |
| `world.perfumer14_level_tax(cid)` / `world.set_perfumer14_level_tax(cid,v)` | `GetPerfumerLevelTaxRate14` / `SetPerfumerLevelTaxRate14` | `world.perfumer14_level_tax(0)` |
| `world.potter14_level_tax(cid)` / `world.set_potter14_level_tax(cid,v)` | `GetPotterLevelTaxRate14` / `SetPotterLevelTaxRate14` | `world.potter14_level_tax(0)` |
| `world.pottery14_level_tax(cid)` / `world.set_pottery14_level_tax(cid,v)` | `GetPotteryLevelTaxRate14` / `SetPotteryLevelTaxRate14` | `world.pottery14_level_tax(0)` |
| `world.printing_house14_level_tax(cid)` / `world.set_printing_house14_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate14` / `SetPrintingHouseLevelTaxRate14` | `world.printing_house14_level_tax(0)` |
| `world.ropemaker14_level_tax(cid)` / `world.set_ropemaker14_level_tax(cid,v)` | `GetRopemakerLevelTaxRate14` / `SetRopemakerLevelTaxRate14` | `world.ropemaker14_level_tax(0)` |
| `world.ropemaker_workshop14_level_tax(cid)` / `world.set_ropemaker_workshop14_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate14` / `SetRopemakerWorkshopLevelTaxRate14` | `world.ropemaker_workshop14_level_tax(0)` |
| `world.saddler14_level_tax(cid)` / `world.set_saddler14_level_tax(cid,v)` | `GetSaddlerLevelTaxRate14` / `SetSaddlerLevelTaxRate14` | `world.saddler14_level_tax(0)` |
| `world.school14_level_tax(cid)` / `world.set_school14_level_tax(cid,v)` | `GetSchoolLevelTaxRate14` / `SetSchoolLevelTaxRate14` | `world.school14_level_tax(0)` |
| `world.schoolhouse14_level_tax(cid)` / `world.set_schoolhouse14_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate14` / `SetSchoolhouseLevelTaxRate14` | `world.schoolhouse14_level_tax(0)` |
| `world.sentry_tower14_level_tax(cid)` / `world.set_sentry_tower14_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate14` / `SetSentryTowerLevelTaxRate14` | `world.sentry_tower14_level_tax(0)` |
| `world.stables14_level_tax(cid)` / `world.set_stables14_level_tax(cid,v)` | `GetStablesLevelTaxRate14` / `SetStablesLevelTaxRate14` | `world.stables14_level_tax(0)` |
| `world.stonecutter14_level_tax(cid)` / `world.set_stonecutter14_level_tax(cid,v)` | `GetStonecutterLevelTaxRate14` / `SetStonecutterLevelTaxRate14` | `world.stonecutter14_level_tax(0)` |
| `world.tailor14_level_tax(cid)` / `world.set_tailor14_level_tax(cid,v)` | `GetTailorLevelTaxRate14` / `SetTailorLevelTaxRate14` | `world.tailor14_level_tax(0)` |
| `world.tannery14_level_tax(cid)` / `world.set_tannery14_level_tax(cid,v)` | `GetTanneryLevelTaxRate14` / `SetTanneryLevelTaxRate14` | `world.tannery14_level_tax(0)` |
| `world.tavern14_level_tax(cid)` / `world.set_tavern14_level_tax(cid,v)` | `GetTavernLevelTaxRate14` / `SetTavernLevelTaxRate14` | `world.tavern14_level_tax(0)` |
| `world.thieves_guild14_level_tax(cid)` / `world.set_thieves_guild14_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate14` / `SetThievesGuildLevelTaxRate14` | `world.thieves_guild14_level_tax(0)` |
| `world.toolmaker14_level_tax(cid)` / `world.set_toolmaker14_level_tax(cid,v)` | `GetToolmakerLevelTaxRate14` / `SetToolmakerLevelTaxRate14` | `world.toolmaker14_level_tax(0)` |
| `world.tower14_level_tax(cid)` / `world.set_tower14_level_tax(cid,v)` | `GetTowerLevelTaxRate14` / `SetTowerLevelTaxRate14` | `world.tower14_level_tax(0)` |
| `world.turner14_level_tax(cid)` / `world.set_turner14_level_tax(cid,v)` | `GetTurnerLevelTaxRate14` / `SetTurnerLevelTaxRate14` | `world.turner14_level_tax(0)` |
| `world.university15_level_tax(cid)` / `world.set_university15_level_tax(cid,v)` | `GetUniversityLevelTaxRate15` / `SetUniversityLevelTaxRate15` | `world.university15_level_tax(0)` |
| `world.university_hall14_level_tax(cid)` / `world.set_university_hall14_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate14` / `SetUniversityHallLevelTaxRate14` | `world.university_hall14_level_tax(0)` |
| `world.vineyard14_level_tax(cid)` / `world.set_vineyard14_level_tax(cid,v)` | `GetVineyardLevelTaxRate14` / `SetVineyardLevelTaxRate14` | `world.vineyard14_level_tax(0)` |
| `world.vintner14_level_tax(cid)` / `world.set_vintner14_level_tax(cid,v)` | `GetVintnerLevelTaxRate14` / `SetVintnerLevelTaxRate14` | `world.vintner14_level_tax(0)` |
| `world.wall15_level_tax(cid)` / `world.set_wall15_level_tax(cid,v)` | `GetWallLevelTaxRate15` / `SetWallLevelTaxRate15` | `world.wall15_level_tax(0)` |
| `world.warehouse15_level_tax(cid)` / `world.set_warehouse15_level_tax(cid,v)` | `GetWarehouseLevelTaxRate15` / `SetWarehouseLevelTaxRate15` | `world.warehouse15_level_tax(0)` |
| `world.weaving_mill15_level_tax(cid)` / `world.set_weaving_mill15_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate15` / `SetWeavingMillLevelTaxRate15` | `world.weaving_mill15_level_tax(0)` |
| `world.well15_level_tax(cid)` / `world.set_well15_level_tax(cid,v)` | `GetWellLevelTaxRate15` / `SetWellLevelTaxRate15` | `world.well15_level_tax(0)` |
| `world.town_hall16_level_tax(cid)` / `world.set_town_hall16_level_tax(cid,v)` | `GetTownHallLevelTaxRate16` / `SetTownHallLevelTaxRate16` | `world.town_hall16_level_tax(0)` |
| `world.apothecary15_level_tax(cid)` / `world.set_apothecary15_level_tax(cid,v)` | `GetApothecaryLevelTaxRate15` / `SetApothecaryLevelTaxRate15` | `world.apothecary15_level_tax(0)` |
| `world.armorer15_level_tax(cid)` / `world.set_armorer15_level_tax(cid,v)` | `GetArmorerLevelTaxRate15` / `SetArmorerLevelTaxRate15` | `world.armorer15_level_tax(0)` |
| `world.baker15_level_tax(cid)` / `world.set_baker15_level_tax(cid,v)` | `GetBakerLevelTaxRate15` / `SetBakerLevelTaxRate15` | `world.baker15_level_tax(0)` |
| `world.barber15_level_tax(cid)` / `world.set_barber15_level_tax(cid,v)` | `GetBarberLevelTaxRate15` / `SetBarberLevelTaxRate15` | `world.barber15_level_tax(0)` |
| `world.bathhouse15_level_tax(cid)` / `world.set_bathhouse15_level_tax(cid,v)` | `GetBathhouseLevelTaxRate15` / `SetBathhouseLevelTaxRate15` | `world.bathhouse15_level_tax(0)` |
| `world.bowyer15_level_tax(cid)` / `world.set_bowyer15_level_tax(cid,v)` | `GetBowyerLevelTaxRate15` / `SetBowyerLevelTaxRate15` | `world.bowyer15_level_tax(0)` |
| `world.brewmaster15_level_tax(cid)` / `world.set_brewmaster15_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate15` / `SetBrewmasterLevelTaxRate15` | `world.brewmaster15_level_tax(0)` |
| `world.brickmaker15_level_tax(cid)` / `world.set_brickmaker15_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate15` / `SetBrickmakerLevelTaxRate15` | `world.brickmaker15_level_tax(0)` |
| `world.bridge15_level_tax(cid)` / `world.set_bridge15_level_tax(cid,v)` | `GetBridgeLevelTaxRate15` / `SetBridgeLevelTaxRate15` | `world.bridge15_level_tax(0)` |
| `world.brothel15_level_tax(cid)` / `world.set_brothel15_level_tax(cid,v)` | `GetBrothelLevelTaxRate15` / `SetBrothelLevelTaxRate15` | `world.brothel15_level_tax(0)` |
| `world.butcher15_level_tax(cid)` / `world.set_butcher15_level_tax(cid,v)` | `GetButcherLevelTaxRate15` / `SetButcherLevelTaxRate15` | `world.butcher15_level_tax(0)` |
| `world.candlemaker15_level_tax(cid)` / `world.set_candlemaker15_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate15` / `SetCandlemakerLevelTaxRate15` | `world.candlemaker15_level_tax(0)` |
| `world.carpenter15_level_tax(cid)` / `world.set_carpenter15_level_tax(cid,v)` | `GetCarpenterLevelTaxRate15` / `SetCarpenterLevelTaxRate15` | `world.carpenter15_level_tax(0)` |
| `world.cartwright15_level_tax(cid)` / `world.set_cartwright15_level_tax(cid,v)` | `GetCartwrightLevelTaxRate15` / `SetCartwrightLevelTaxRate15` | `world.cartwright15_level_tax(0)` |
| `world.castle15_level_tax(cid)` / `world.set_castle15_level_tax(cid,v)` | `GetCastleLevelTaxRate15` / `SetCastleLevelTaxRate15` | `world.castle15_level_tax(0)` |
| `world.cathedral15_level_tax(cid)` / `world.set_cathedral15_level_tax(cid,v)` | `GetCathedralLevelTaxRate15` / `SetCathedralLevelTaxRate15` | `world.cathedral15_level_tax(0)` |
| `world.chandler15_level_tax(cid)` / `world.set_chandler15_level_tax(cid,v)` | `GetChandlerLevelTaxRate15` / `SetChandlerLevelTaxRate15` | `world.chandler15_level_tax(0)` |
| `world.chapel15_level_tax(cid)` / `world.set_chapel15_level_tax(cid,v)` | `GetChapelLevelTaxRate15` / `SetChapelLevelTaxRate15` | `world.chapel15_level_tax(0)` |
| `world.charcoal15_level_tax(cid)` / `world.set_charcoal15_level_tax(cid,v)` | `GetCharcoalLevelTaxRate15` / `SetCharcoalLevelTaxRate15` | `world.charcoal15_level_tax(0)` |
| `world.church15_level_tax(cid)` / `world.set_church15_level_tax(cid,v)` | `GetChurchLevelTaxRate15` / `SetChurchLevelTaxRate15` | `world.church15_level_tax(0)` |
| `world.cobbler15_level_tax(cid)` / `world.set_cobbler15_level_tax(cid,v)` | `GetCobblerLevelTaxRate15` / `SetCobblerLevelTaxRate15` | `world.cobbler15_level_tax(0)` |
| `world.contor15_level_tax(cid)` / `world.set_contor15_level_tax(cid,v)` | `GetContorLevelTaxRate15` / `SetContorLevelTaxRate15` | `world.contor15_level_tax(0)` |
| `world.cook15_level_tax(cid)` / `world.set_cook15_level_tax(cid,v)` | `GetCookLevelTaxRate15` / `SetCookLevelTaxRate15` | `world.cook15_level_tax(0)` |
| `world.cooper15_level_tax(cid)` / `world.set_cooper15_level_tax(cid,v)` | `GetCooperLevelTaxRate15` / `SetCooperLevelTaxRate15` | `world.cooper15_level_tax(0)` |
| `world.courthouse15_level_tax(cid)` / `world.set_courthouse15_level_tax(cid,v)` | `GetCourthouseLevelTaxRate15` / `SetCourthouseLevelTaxRate15` | `world.courthouse15_level_tax(0)` |
| `world.dairy15_level_tax(cid)` / `world.set_dairy15_level_tax(cid,v)` | `GetDairyLevelTaxRate15` / `SetDairyLevelTaxRate15` | `world.dairy15_level_tax(0)` |
| `world.dice_house15_level_tax(cid)` / `world.set_dice_house15_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate15` / `SetDiceHouseLevelTaxRate15` | `world.dice_house15_level_tax(0)` |
| `world.distiller15_level_tax(cid)` / `world.set_distiller15_level_tax(cid,v)` | `GetDistillerLevelTaxRate15` / `SetDistillerLevelTaxRate15` | `world.distiller15_level_tax(0)` |
| `world.dyer15_level_tax(cid)` / `world.set_dyer15_level_tax(cid,v)` | `GetDyerLevelTaxRate15` / `SetDyerLevelTaxRate15` | `world.dyer15_level_tax(0)` |
| `world.fishery15_level_tax(cid)` / `world.set_fishery15_level_tax(cid,v)` | `GetFisheryLevelTaxRate15` / `SetFisheryLevelTaxRate15` | `world.fishery15_level_tax(0)` |
| `world.forum15_level_tax(cid)` / `world.set_forum15_level_tax(cid,v)` | `GetForumLevelTaxRate15` / `SetForumLevelTaxRate15` | `world.forum15_level_tax(0)` |
| `world.fowler15_level_tax(cid)` / `world.set_fowler15_level_tax(cid,v)` | `GetFowlerLevelTaxRate15` / `SetFowlerLevelTaxRate15` | `world.fowler15_level_tax(0)` |
| `world.furrier15_level_tax(cid)` / `world.set_furrier15_level_tax(cid,v)` | `GetFurrierLevelTaxRate15` / `SetFurrierLevelTaxRate15` | `world.furrier15_level_tax(0)` |
| `world.garrison15_level_tax(cid)` / `world.set_garrison15_level_tax(cid,v)` | `GetGarrisonLevelTaxRate15` / `SetGarrisonLevelTaxRate15` | `world.garrison15_level_tax(0)` |
| `world.gates15_level_tax(cid)` / `world.set_gates15_level_tax(cid,v)` | `GetGatesLevelTaxRate15` / `SetGatesLevelTaxRate15` | `world.gates15_level_tax(0)` |
| `world.glassblower15_level_tax(cid)` / `world.set_glassblower15_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate15` / `SetGlassblowerLevelTaxRate15` | `world.glassblower15_level_tax(0)` |
| `world.goldbeater15_level_tax(cid)` / `world.set_goldbeater15_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate15` / `SetGoldbeaterLevelTaxRate15` | `world.goldbeater15_level_tax(0)` |
| `world.goldsmith15_level_tax(cid)` / `world.set_goldsmith15_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate15` / `SetGoldsmithLevelTaxRate15` | `world.goldsmith15_level_tax(0)` |
| `world.granary15_level_tax(cid)` / `world.set_granary15_level_tax(cid,v)` | `GetGranaryLevelTaxRate15` / `SetGranaryLevelTaxRate15` | `world.granary15_level_tax(0)` |
| `world.guardhouse15_level_tax(cid)` / `world.set_guardhouse15_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate15` / `SetGuardhouseLevelTaxRate15` | `world.guardhouse15_level_tax(0)` |
| `world.guild_house15_level_tax(cid)` / `world.set_guild_house15_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate15` / `SetGuildHouseLevelTaxRate15` | `world.guild_house15_level_tax(0)` |
| `world.harbor15_level_tax(cid)` / `world.set_harbor15_level_tax(cid,v)` | `GetHarborLevelTaxRate15` / `SetHarborLevelTaxRate15` | `world.harbor15_level_tax(0)` |
| `world.harbor_dock15_level_tax(cid)` / `world.set_harbor_dock15_level_tax(cid,v)` | `GetHarborDockLevelTaxRate15` / `SetHarborDockLevelTaxRate15` | `world.harbor_dock15_level_tax(0)` |
| `world.harbor_walls15_level_tax(cid)` / `world.set_harbor_walls15_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate15` / `SetHarborWallsLevelTaxRate15` | `world.harbor_walls15_level_tax(0)` |
| `world.herb_garden15_level_tax(cid)` / `world.set_herb_garden15_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate15` / `SetHerbGardenLevelTaxRate15` | `world.herb_garden15_level_tax(0)` |
| `world.hospital15_level_tax(cid)` / `world.set_hospital15_level_tax(cid,v)` | `GetHospitalLevelTaxRate15` / `SetHospitalLevelTaxRate15` | `world.hospital15_level_tax(0)` |
| `world.house15_level_tax(cid)` / `world.set_house15_level_tax(cid,v)` | `GetHouseLevelTaxRate15` / `SetHouseLevelTaxRate15` | `world.house15_level_tax(0)` |
| `world.jeweler15_level_tax(cid)` / `world.set_jeweler15_level_tax(cid,v)` | `GetJewelerLevelTaxRate15` / `SetJewelerLevelTaxRate15` | `world.jeweler15_level_tax(0)` |
| `world.library15_level_tax(cid)` / `world.set_library15_level_tax(cid,v)` | `GetLibraryLevelTaxRate15` / `SetLibraryLevelTaxRate15` | `world.library15_level_tax(0)` |
| `world.library_hall15_level_tax(cid)` / `world.set_library_hall15_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate15` / `SetLibraryHallLevelTaxRate15` | `world.library_hall15_level_tax(0)` |
| `world.market15_level_tax(cid)` / `world.set_market15_level_tax(cid,v)` | `GetMarketLevelTaxRate15` / `SetMarketLevelTaxRate15` | `world.market15_level_tax(0)` |
| `world.miller15_level_tax(cid)` / `world.set_miller15_level_tax(cid,v)` | `GetMillerLevelTaxRate15` / `SetMillerLevelTaxRate15` | `world.miller15_level_tax(0)` |
| `world.mine15_level_tax(cid)` / `world.set_mine15_level_tax(cid,v)` | `GetMineLevelTaxRate15` / `SetMineLevelTaxRate15` | `world.mine15_level_tax(0)` |
| `world.mint15_level_tax(cid)` / `world.set_mint15_level_tax(cid,v)` | `GetMintLevelTaxRate15` / `SetMintLevelTaxRate15` | `world.mint15_level_tax(0)` |
| `world.monastery15_level_tax(cid)` / `world.set_monastery15_level_tax(cid,v)` | `GetMonasteryLevelTaxRate15` / `SetMonasteryLevelTaxRate15` | `world.monastery15_level_tax(0)` |
| `world.papermill15_level_tax(cid)` / `world.set_papermill15_level_tax(cid,v)` | `GetPapermillLevelTaxRate15` / `SetPapermillLevelTaxRate15` | `world.papermill15_level_tax(0)` |
| `world.perfumer15_level_tax(cid)` / `world.set_perfumer15_level_tax(cid,v)` | `GetPerfumerLevelTaxRate15` / `SetPerfumerLevelTaxRate15` | `world.perfumer15_level_tax(0)` |
| `world.potter15_level_tax(cid)` / `world.set_potter15_level_tax(cid,v)` | `GetPotterLevelTaxRate15` / `SetPotterLevelTaxRate15` | `world.potter15_level_tax(0)` |
| `world.pottery15_level_tax(cid)` / `world.set_pottery15_level_tax(cid,v)` | `GetPotteryLevelTaxRate15` / `SetPotteryLevelTaxRate15` | `world.pottery15_level_tax(0)` |
| `world.printing_house15_level_tax(cid)` / `world.set_printing_house15_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate15` / `SetPrintingHouseLevelTaxRate15` | `world.printing_house15_level_tax(0)` |
| `world.ropemaker15_level_tax(cid)` / `world.set_ropemaker15_level_tax(cid,v)` | `GetRopemakerLevelTaxRate15` / `SetRopemakerLevelTaxRate15` | `world.ropemaker15_level_tax(0)` |
| `world.ropemaker_workshop15_level_tax(cid)` / `world.set_ropemaker_workshop15_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate15` / `SetRopemakerWorkshopLevelTaxRate15` | `world.ropemaker_workshop15_level_tax(0)` |
| `world.saddler15_level_tax(cid)` / `world.set_saddler15_level_tax(cid,v)` | `GetSaddlerLevelTaxRate15` / `SetSaddlerLevelTaxRate15` | `world.saddler15_level_tax(0)` |
| `world.school15_level_tax(cid)` / `world.set_school15_level_tax(cid,v)` | `GetSchoolLevelTaxRate15` / `SetSchoolLevelTaxRate15` | `world.school15_level_tax(0)` |
| `world.schoolhouse15_level_tax(cid)` / `world.set_schoolhouse15_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate15` / `SetSchoolhouseLevelTaxRate15` | `world.schoolhouse15_level_tax(0)` |
| `world.sentry_tower15_level_tax(cid)` / `world.set_sentry_tower15_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate15` / `SetSentryTowerLevelTaxRate15` | `world.sentry_tower15_level_tax(0)` |
| `world.stables15_level_tax(cid)` / `world.set_stables15_level_tax(cid,v)` | `GetStablesLevelTaxRate15` / `SetStablesLevelTaxRate15` | `world.stables15_level_tax(0)` |
| `world.stonecutter15_level_tax(cid)` / `world.set_stonecutter15_level_tax(cid,v)` | `GetStonecutterLevelTaxRate15` / `SetStonecutterLevelTaxRate15` | `world.stonecutter15_level_tax(0)` |
| `world.tailor15_level_tax(cid)` / `world.set_tailor15_level_tax(cid,v)` | `GetTailorLevelTaxRate15` / `SetTailorLevelTaxRate15` | `world.tailor15_level_tax(0)` |
| `world.tannery15_level_tax(cid)` / `world.set_tannery15_level_tax(cid,v)` | `GetTanneryLevelTaxRate15` / `SetTanneryLevelTaxRate15` | `world.tannery15_level_tax(0)` |
| `world.tavern15_level_tax(cid)` / `world.set_tavern15_level_tax(cid,v)` | `GetTavernLevelTaxRate15` / `SetTavernLevelTaxRate15` | `world.tavern15_level_tax(0)` |
| `world.thieves_guild15_level_tax(cid)` / `world.set_thieves_guild15_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate15` / `SetThievesGuildLevelTaxRate15` | `world.thieves_guild15_level_tax(0)` |
| `world.toolmaker15_level_tax(cid)` / `world.set_toolmaker15_level_tax(cid,v)` | `GetToolmakerLevelTaxRate15` / `SetToolmakerLevelTaxRate15` | `world.toolmaker15_level_tax(0)` |
| `world.tower15_level_tax(cid)` / `world.set_tower15_level_tax(cid,v)` | `GetTowerLevelTaxRate15` / `SetTowerLevelTaxRate15` | `world.tower15_level_tax(0)` |
| `world.turner15_level_tax(cid)` / `world.set_turner15_level_tax(cid,v)` | `GetTurnerLevelTaxRate15` / `SetTurnerLevelTaxRate15` | `world.turner15_level_tax(0)` |
| `world.university16_level_tax(cid)` / `world.set_university16_level_tax(cid,v)` | `GetUniversityLevelTaxRate16` / `SetUniversityLevelTaxRate16` | `world.university16_level_tax(0)` |
| `world.university_hall15_level_tax(cid)` / `world.set_university_hall15_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate15` / `SetUniversityHallLevelTaxRate15` | `world.university_hall15_level_tax(0)` |
| `world.vineyard15_level_tax(cid)` / `world.set_vineyard15_level_tax(cid,v)` | `GetVineyardLevelTaxRate15` / `SetVineyardLevelTaxRate15` | `world.vineyard15_level_tax(0)` |
| `world.vintner15_level_tax(cid)` / `world.set_vintner15_level_tax(cid,v)` | `GetVintnerLevelTaxRate15` / `SetVintnerLevelTaxRate15` | `world.vintner15_level_tax(0)` |
| `world.wall16_level_tax(cid)` / `world.set_wall16_level_tax(cid,v)` | `GetWallLevelTaxRate16` / `SetWallLevelTaxRate16` | `world.wall16_level_tax(0)` |
| `world.apothecary16_level_tax(cid)` / `world.set_apothecary16_level_tax(cid,v)` | `GetApothecaryLevelTaxRate16` / `SetApothecaryLevelTaxRate16` | `world.apothecary16_level_tax(0)` |
| `world.armorer16_level_tax(cid)` / `world.set_armorer16_level_tax(cid,v)` | `GetArmorerLevelTaxRate16` / `SetArmorerLevelTaxRate16` | `world.armorer16_level_tax(0)` |
| `world.baker16_level_tax(cid)` / `world.set_baker16_level_tax(cid,v)` | `GetBakerLevelTaxRate16` / `SetBakerLevelTaxRate16` | `world.baker16_level_tax(0)` |
| `world.barber16_level_tax(cid)` / `world.set_barber16_level_tax(cid,v)` | `GetBarberLevelTaxRate16` / `SetBarberLevelTaxRate16` | `world.barber16_level_tax(0)` |
| `world.warehouse14_level_tax(cid)` / `world.set_warehouse14_level_tax(cid,v)` | `GetWarehouseLevelTaxRate14` / `SetWarehouseLevelTaxRate14` | `world.warehouse14_level_tax(0)` |
| `world.weaving_mill14_level_tax(cid)` / `world.set_weaving_mill14_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate14` / `SetWeavingMillLevelTaxRate14` | `world.weaving_mill14_level_tax(0)` |
| `world.well14_level_tax(cid)` / `world.set_well14_level_tax(cid,v)` | `GetWellLevelTaxRate14` / `SetWellLevelTaxRate14` | `world.well14_level_tax(0)` |
| `world.armorer14_level_tax(cid)` / `world.set_armorer14_level_tax(cid,v)` | `GetArmorerLevelTaxRate14` / `SetArmorerLevelTaxRate14` | `world.armorer14_level_tax(0)` |
| `world.baker14_level_tax(cid)` / `world.set_baker14_level_tax(cid,v)` | `GetBakerLevelTaxRate14` / `SetBakerLevelTaxRate14` | `world.baker14_level_tax(0)` |
| `world.barber14_level_tax(cid)` / `world.set_barber14_level_tax(cid,v)` | `GetBarberLevelTaxRate14` / `SetBarberLevelTaxRate14` | `world.barber14_level_tax(0)` |
| `world.bathhouse14_level_tax(cid)` / `world.set_bathhouse14_level_tax(cid,v)` | `GetBathhouseLevelTaxRate14` / `SetBathhouseLevelTaxRate14` | `world.bathhouse14_level_tax(0)` |
| `world.bowyer14_level_tax(cid)` / `world.set_bowyer14_level_tax(cid,v)` | `GetBowyerLevelTaxRate14` / `SetBowyerLevelTaxRate14` | `world.bowyer14_level_tax(0)` |
| `world.brewmaster14_level_tax(cid)` / `world.set_brewmaster14_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate14` / `SetBrewmasterLevelTaxRate14` | `world.brewmaster14_level_tax(0)` |
| `world.brickmaker14_level_tax(cid)` / `world.set_brickmaker14_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate14` / `SetBrickmakerLevelTaxRate14` | `world.brickmaker14_level_tax(0)` |
| `world.brickmaker16_level_tax(cid)` / `world.set_brickmaker16_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate16` / `SetBrickmakerLevelTaxRate16` | `world.brickmaker16_level_tax(0)` |
| `world.bridge16_level_tax(cid)` / `world.set_bridge16_level_tax(cid,v)` | `GetBridgeLevelTaxRate16` / `SetBridgeLevelTaxRate16` | `world.bridge16_level_tax(0)` |
| `world.brothel16_level_tax(cid)` / `world.set_brothel16_level_tax(cid,v)` | `GetBrothelLevelTaxRate16` / `SetBrothelLevelTaxRate16` | `world.brothel16_level_tax(0)` |
| `world.butcher16_level_tax(cid)` / `world.set_butcher16_level_tax(cid,v)` | `GetButcherLevelTaxRate16` / `SetButcherLevelTaxRate16` | `world.butcher16_level_tax(0)` |
| `world.candlemaker16_level_tax(cid)` / `world.set_candlemaker16_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate16` / `SetCandlemakerLevelTaxRate16` | `world.candlemaker16_level_tax(0)` |
| `world.carpenter16_level_tax(cid)` / `world.set_carpenter16_level_tax(cid,v)` | `GetCarpenterLevelTaxRate16` / `SetCarpenterLevelTaxRate16` | `world.carpenter16_level_tax(0)` |
| `world.cartwright16_level_tax(cid)` / `world.set_cartwright16_level_tax(cid,v)` | `GetCartwrightLevelTaxRate16` / `SetCartwrightLevelTaxRate16` | `world.cartwright16_level_tax(0)` |
| `world.castle16_level_tax(cid)` / `world.set_castle16_level_tax(cid,v)` | `GetCastleLevelTaxRate16` / `SetCastleLevelTaxRate16` | `world.castle16_level_tax(0)` |
| `world.cathedral16_level_tax(cid)` / `world.set_cathedral16_level_tax(cid,v)` | `GetCathedralLevelTaxRate16` / `SetCathedralLevelTaxRate16` | `world.cathedral16_level_tax(0)` |
| `world.chandler16_level_tax(cid)` / `world.set_chandler16_level_tax(cid,v)` | `GetChandlerLevelTaxRate16` / `SetChandlerLevelTaxRate16` | `world.chandler16_level_tax(0)` |
| `world.chapel16_level_tax(cid)` / `world.set_chapel16_level_tax(cid,v)` | `GetChapelLevelTaxRate16` / `SetChapelLevelTaxRate16` | `world.chapel16_level_tax(0)` |
| `world.charcoal16_level_tax(cid)` / `world.set_charcoal16_level_tax(cid,v)` | `GetCharcoalLevelTaxRate16` / `SetCharcoalLevelTaxRate16` | `world.charcoal16_level_tax(0)` |
| `world.church16_level_tax(cid)` / `world.set_church16_level_tax(cid,v)` | `GetChurchLevelTaxRate16` / `SetChurchLevelTaxRate16` | `world.church16_level_tax(0)` |
| `world.cobbler16_level_tax(cid)` / `world.set_cobbler16_level_tax(cid,v)` | `GetCobblerLevelTaxRate16` / `SetCobblerLevelTaxRate16` | `world.cobbler16_level_tax(0)` |
| `world.contor16_level_tax(cid)` / `world.set_contor16_level_tax(cid,v)` | `GetContorLevelTaxRate16` / `SetContorLevelTaxRate16` | `world.contor16_level_tax(0)` |
| `world.cook16_level_tax(cid)` / `world.set_cook16_level_tax(cid,v)` | `GetCookLevelTaxRate16` / `SetCookLevelTaxRate16` | `world.cook16_level_tax(0)` |
| `world.cooper16_level_tax(cid)` / `world.set_cooper16_level_tax(cid,v)` | `GetCooperLevelTaxRate16` / `SetCooperLevelTaxRate16` | `world.cooper16_level_tax(0)` |
| `world.courthouse16_level_tax(cid)` / `world.set_courthouse16_level_tax(cid,v)` | `GetCourthouseLevelTaxRate16` / `SetCourthouseLevelTaxRate16` | `world.courthouse16_level_tax(0)` |
| `world.dairy16_level_tax(cid)` / `world.set_dairy16_level_tax(cid,v)` | `GetDairyLevelTaxRate16` / `SetDairyLevelTaxRate16` | `world.dairy16_level_tax(0)` |
| `world.dice_house16_level_tax(cid)` / `world.set_dice_house16_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate16` / `SetDiceHouseLevelTaxRate16` | `world.dice_house16_level_tax(0)` |
| `world.distiller16_level_tax(cid)` / `world.set_distiller16_level_tax(cid,v)` | `GetDistillerLevelTaxRate16` / `SetDistillerLevelTaxRate16` | `world.distiller16_level_tax(0)` |
| `world.dyer16_level_tax(cid)` / `world.set_dyer16_level_tax(cid,v)` | `GetDyerLevelTaxRate16` / `SetDyerLevelTaxRate16` | `world.dyer16_level_tax(0)` |
| `world.fishery16_level_tax(cid)` / `world.set_fishery16_level_tax(cid,v)` | `GetFisheryLevelTaxRate16` / `SetFisheryLevelTaxRate16` | `world.fishery16_level_tax(0)` |
| `world.forum16_level_tax(cid)` / `world.set_forum16_level_tax(cid,v)` | `GetForumLevelTaxRate16` / `SetForumLevelTaxRate16` | `world.forum16_level_tax(0)` |
| `world.fowler16_level_tax(cid)` / `world.set_fowler16_level_tax(cid,v)` | `GetFowlerLevelTaxRate16` / `SetFowlerLevelTaxRate16` | `world.fowler16_level_tax(0)` |
| `world.furrier16_level_tax(cid)` / `world.set_furrier16_level_tax(cid,v)` | `GetFurrierLevelTaxRate16` / `SetFurrierLevelTaxRate16` | `world.furrier16_level_tax(0)` |
| `world.garrison16_level_tax(cid)` / `world.set_garrison16_level_tax(cid,v)` | `GetGarrisonLevelTaxRate16` / `SetGarrisonLevelTaxRate16` | `world.garrison16_level_tax(0)` |
| `world.gates16_level_tax(cid)` / `world.set_gates16_level_tax(cid,v)` | `GetGatesLevelTaxRate16` / `SetGatesLevelTaxRate16` | `world.gates16_level_tax(0)` |
| `world.glassblower16_level_tax(cid)` / `world.set_glassblower16_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate16` / `SetGlassblowerLevelTaxRate16` | `world.glassblower16_level_tax(0)` |
| `world.goldbeater16_level_tax(cid)` / `world.set_goldbeater16_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate16` / `SetGoldbeaterLevelTaxRate16` | `world.goldbeater16_level_tax(0)` |
| `world.goldsmith16_level_tax(cid)` / `world.set_goldsmith16_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate16` / `SetGoldsmithLevelTaxRate16` | `world.goldsmith16_level_tax(0)` |
| `world.granary16_level_tax(cid)` / `world.set_granary16_level_tax(cid,v)` | `GetGranaryLevelTaxRate16` / `SetGranaryLevelTaxRate16` | `world.granary16_level_tax(0)` |
| `world.guardhouse16_level_tax(cid)` / `world.set_guardhouse16_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate16` / `SetGuardhouseLevelTaxRate16` | `world.guardhouse16_level_tax(0)` |
| `world.guild_house16_level_tax(cid)` / `world.set_guild_house16_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate16` / `SetGuildHouseLevelTaxRate16` | `world.guild_house16_level_tax(0)` |
| `world.harbor16_level_tax(cid)` / `world.set_harbor16_level_tax(cid,v)` | `GetHarborLevelTaxRate16` / `SetHarborLevelTaxRate16` | `world.harbor16_level_tax(0)` |
| `world.harbor_dock16_level_tax(cid)` / `world.set_harbor_dock16_level_tax(cid,v)` | `GetHarborDockLevelTaxRate16` / `SetHarborDockLevelTaxRate16` | `world.harbor_dock16_level_tax(0)` |
| `world.harbor_walls16_level_tax(cid)` / `world.set_harbor_walls16_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate16` / `SetHarborWallsLevelTaxRate16` | `world.harbor_walls16_level_tax(0)` |
| `world.herb_garden16_level_tax(cid)` / `world.set_herb_garden16_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate16` / `SetHerbGardenLevelTaxRate16` | `world.herb_garden16_level_tax(0)` |
| `world.hospital16_level_tax(cid)` / `world.set_hospital16_level_tax(cid,v)` | `GetHospitalLevelTaxRate16` / `SetHospitalLevelTaxRate16` | `world.hospital16_level_tax(0)` |
| `world.house16_level_tax(cid)` / `world.set_house16_level_tax(cid,v)` | `GetHouseLevelTaxRate16` / `SetHouseLevelTaxRate16` | `world.house16_level_tax(0)` |
| `world.jeweler16_level_tax(cid)` / `world.set_jeweler16_level_tax(cid,v)` | `GetJewelerLevelTaxRate16` / `SetJewelerLevelTaxRate16` | `world.jeweler16_level_tax(0)` |
| `world.library16_level_tax(cid)` / `world.set_library16_level_tax(cid,v)` | `GetLibraryLevelTaxRate16` / `SetLibraryLevelTaxRate16` | `world.library16_level_tax(0)` |
| `world.library_hall16_level_tax(cid)` / `world.set_library_hall16_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate16` / `SetLibraryHallLevelTaxRate16` | `world.library_hall16_level_tax(0)` |
| `world.market16_level_tax(cid)` / `world.set_market16_level_tax(cid,v)` | `GetMarketLevelTaxRate16` / `SetMarketLevelTaxRate16` | `world.market16_level_tax(0)` |
| `world.miller16_level_tax(cid)` / `world.set_miller16_level_tax(cid,v)` | `GetMillerLevelTaxRate16` / `SetMillerLevelTaxRate16` | `world.miller16_level_tax(0)` |
| `world.mine16_level_tax(cid)` / `world.set_mine16_level_tax(cid,v)` | `GetMineLevelTaxRate16` / `SetMineLevelTaxRate16` | `world.mine16_level_tax(0)` |
| `world.mint16_level_tax(cid)` / `world.set_mint16_level_tax(cid,v)` | `GetMintLevelTaxRate16` / `SetMintLevelTaxRate16` | `world.mint16_level_tax(0)` |
| `world.monastery16_level_tax(cid)` / `world.set_monastery16_level_tax(cid,v)` | `GetMonasteryLevelTaxRate16` / `SetMonasteryLevelTaxRate16` | `world.monastery16_level_tax(0)` |
| `world.papermill16_level_tax(cid)` / `world.set_papermill16_level_tax(cid,v)` | `GetPapermillLevelTaxRate16` / `SetPapermillLevelTaxRate16` | `world.papermill16_level_tax(0)` |
| `world.perfumer16_level_tax(cid)` / `world.set_perfumer16_level_tax(cid,v)` | `GetPerfumerLevelTaxRate16` / `SetPerfumerLevelTaxRate16` | `world.perfumer16_level_tax(0)` |
| `world.potter16_level_tax(cid)` / `world.set_potter16_level_tax(cid,v)` | `GetPotterLevelTaxRate16` / `SetPotterLevelTaxRate16` | `world.potter16_level_tax(0)` |
| `world.pottery16_level_tax(cid)` / `world.set_pottery16_level_tax(cid,v)` | `GetPotteryLevelTaxRate16` / `SetPotteryLevelTaxRate16` | `world.pottery16_level_tax(0)` |
| `world.printing_house16_level_tax(cid)` / `world.set_printing_house16_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate16` / `SetPrintingHouseLevelTaxRate16` | `world.printing_house16_level_tax(0)` |
| `world.ropemaker16_level_tax(cid)` / `world.set_ropemaker16_level_tax(cid,v)` | `GetRopemakerLevelTaxRate16` / `SetRopemakerLevelTaxRate16` | `world.ropemaker16_level_tax(0)` |
| `world.ropemaker_workshop16_level_tax(cid)` / `world.set_ropemaker_workshop16_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate16` / `SetRopemakerWorkshopLevelTaxRate16` | `world.ropemaker_workshop16_level_tax(0)` |
| `world.saddler16_level_tax(cid)` / `world.set_saddler16_level_tax(cid,v)` | `GetSaddlerLevelTaxRate16` / `SetSaddlerLevelTaxRate16` | `world.saddler16_level_tax(0)` |
| `world.school16_level_tax(cid)` / `world.set_school16_level_tax(cid,v)` | `GetSchoolLevelTaxRate16` / `SetSchoolLevelTaxRate16` | `world.school16_level_tax(0)` |
| `world.schoolhouse16_level_tax(cid)` / `world.set_schoolhouse16_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate16` / `SetSchoolhouseLevelTaxRate16` | `world.schoolhouse16_level_tax(0)` |
| `world.sentry_tower16_level_tax(cid)` / `world.set_sentry_tower16_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate16` / `SetSentryTowerLevelTaxRate16` | `world.sentry_tower16_level_tax(0)` |
| `world.stables16_level_tax(cid)` / `world.set_stables16_level_tax(cid,v)` | `GetStablesLevelTaxRate16` / `SetStablesLevelTaxRate16` | `world.stables16_level_tax(0)` |
| `world.stonecutter16_level_tax(cid)` / `world.set_stonecutter16_level_tax(cid,v)` | `GetStonecutterLevelTaxRate16` / `SetStonecutterLevelTaxRate16` | `world.stonecutter16_level_tax(0)` |
| `world.tailor16_level_tax(cid)` / `world.set_tailor16_level_tax(cid,v)` | `GetTailorLevelTaxRate16` / `SetTailorLevelTaxRate16` | `world.tailor16_level_tax(0)` |
| `world.tannery16_level_tax(cid)` / `world.set_tannery16_level_tax(cid,v)` | `GetTanneryLevelTaxRate16` / `SetTanneryLevelTaxRate16` | `world.tannery16_level_tax(0)` |
| `world.tavern16_level_tax(cid)` / `world.set_tavern16_level_tax(cid,v)` | `GetTavernLevelTaxRate16` / `SetTavernLevelTaxRate16` | `world.tavern16_level_tax(0)` |
| `world.thieves_guild16_level_tax(cid)` / `world.set_thieves_guild16_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate16` / `SetThievesGuildLevelTaxRate16` | `world.thieves_guild16_level_tax(0)` |
| `world.toolmaker16_level_tax(cid)` / `world.set_toolmaker16_level_tax(cid,v)` | `GetToolmakerLevelTaxRate16` / `SetToolmakerLevelTaxRate16` | `world.toolmaker16_level_tax(0)` |
| `world.tower16_level_tax(cid)` / `world.set_tower16_level_tax(cid,v)` | `GetTowerLevelTaxRate16` / `SetTowerLevelTaxRate16` | `world.tower16_level_tax(0)` |
| `world.turner16_level_tax(cid)` / `world.set_turner16_level_tax(cid,v)` | `GetTurnerLevelTaxRate16` / `SetTurnerLevelTaxRate16` | `world.turner16_level_tax(0)` |
| `world.university_hall16_level_tax(cid)` / `world.set_university_hall16_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate16` / `SetUniversityHallLevelTaxRate16` | `world.university_hall16_level_tax(0)` |
| `world.vineyard16_level_tax(cid)` / `world.set_vineyard16_level_tax(cid,v)` | `GetVineyardLevelTaxRate16` / `SetVineyardLevelTaxRate16` | `world.vineyard16_level_tax(0)` |
| `world.vintner16_level_tax(cid)` / `world.set_vintner16_level_tax(cid,v)` | `GetVintnerLevelTaxRate16` / `SetVintnerLevelTaxRate16` | `world.vintner16_level_tax(0)` |
| `world.wall17_level_tax(cid)` / `world.set_wall17_level_tax(cid,v)` | `GetWallLevelTaxRate17` / `SetWallLevelTaxRate17` | `world.wall17_level_tax(0)` |
| `world.warehouse16_level_tax(cid)` / `world.set_warehouse16_level_tax(cid,v)` | `GetWarehouseLevelTaxRate16` / `SetWarehouseLevelTaxRate16` | `world.warehouse16_level_tax(0)` |
| `world.weaving_mill16_level_tax(cid)` / `world.set_weaving_mill16_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate16` / `SetWeavingMillLevelTaxRate16` | `world.weaving_mill16_level_tax(0)` |
| `world.well16_level_tax(cid)` / `world.set_well16_level_tax(cid,v)` | `GetWellLevelTaxRate16` / `SetWellLevelTaxRate16` | `world.well16_level_tax(0)` |
| `world.armorer17_level_tax(cid)` / `world.set_armorer17_level_tax(cid,v)` | `GetArmorerLevelTaxRate17` / `SetArmorerLevelTaxRate17` | `world.armorer17_level_tax(0)` |
| `world.baker17_level_tax(cid)` / `world.set_baker17_level_tax(cid,v)` | `GetBakerLevelTaxRate17` / `SetBakerLevelTaxRate17` | `world.baker17_level_tax(0)` |
| `world.barber17_level_tax(cid)` / `world.set_barber17_level_tax(cid,v)` | `GetBarberLevelTaxRate17` / `SetBarberLevelTaxRate17` | `world.barber17_level_tax(0)` |
| `world.bathhouse17_level_tax(cid)` / `world.set_bathhouse17_level_tax(cid,v)` | `GetBathhouseLevelTaxRate17` / `SetBathhouseLevelTaxRate17` | `world.bathhouse17_level_tax(0)` |
| `world.bowyer17_level_tax(cid)` / `world.set_bowyer17_level_tax(cid,v)` | `GetBowyerLevelTaxRate17` / `SetBowyerLevelTaxRate17` | `world.bowyer17_level_tax(0)` |
| `world.brewmaster17_level_tax(cid)` / `world.set_brewmaster17_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate17` / `SetBrewmasterLevelTaxRate17` | `world.brewmaster17_level_tax(0)` |
| `world.brickmaker17_level_tax(cid)` / `world.set_brickmaker17_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate17` / `SetBrickmakerLevelTaxRate17` | `world.brickmaker17_level_tax(0)` |
| `world.bridge17_level_tax(cid)` / `world.set_bridge17_level_tax(cid,v)` | `GetBridgeLevelTaxRate17` / `SetBridgeLevelTaxRate17` | `world.bridge17_level_tax(0)` |
| `world.brothel17_level_tax(cid)` / `world.set_brothel17_level_tax(cid,v)` | `GetBrothelLevelTaxRate17` / `SetBrothelLevelTaxRate17` | `world.brothel17_level_tax(0)` |
| `world.butcher17_level_tax(cid)` / `world.set_butcher17_level_tax(cid,v)` | `GetButcherLevelTaxRate17` / `SetButcherLevelTaxRate17` | `world.butcher17_level_tax(0)` |
| `world.candlemaker17_level_tax(cid)` / `world.set_candlemaker17_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate17` / `SetCandlemakerLevelTaxRate17` | `world.candlemaker17_level_tax(0)` |
| `world.carpenter17_level_tax(cid)` / `world.set_carpenter17_level_tax(cid,v)` | `GetCarpenterLevelTaxRate17` / `SetCarpenterLevelTaxRate17` | `world.carpenter17_level_tax(0)` |
| `world.cartwright17_level_tax(cid)` / `world.set_cartwright17_level_tax(cid,v)` | `GetCartwrightLevelTaxRate17` / `SetCartwrightLevelTaxRate17` | `world.cartwright17_level_tax(0)` |
| `world.castle17_level_tax(cid)` / `world.set_castle17_level_tax(cid,v)` | `GetCastleLevelTaxRate17` / `SetCastleLevelTaxRate17` | `world.castle17_level_tax(0)` |
| `world.cathedral17_level_tax(cid)` / `world.set_cathedral17_level_tax(cid,v)` | `GetCathedralLevelTaxRate17` / `SetCathedralLevelTaxRate17` | `world.cathedral17_level_tax(0)` |
| `world.chandler17_level_tax(cid)` / `world.set_chandler17_level_tax(cid,v)` | `GetChandlerLevelTaxRate17` / `SetChandlerLevelTaxRate17` | `world.chandler17_level_tax(0)` |
| `world.chapel17_level_tax(cid)` / `world.set_chapel17_level_tax(cid,v)` | `GetChapelLevelTaxRate17` / `SetChapelLevelTaxRate17` | `world.chapel17_level_tax(0)` |
| `world.charcoal17_level_tax(cid)` / `world.set_charcoal17_level_tax(cid,v)` | `GetCharcoalLevelTaxRate17` / `SetCharcoalLevelTaxRate17` | `world.charcoal17_level_tax(0)` |
| `world.church17_level_tax(cid)` / `world.set_church17_level_tax(cid,v)` | `GetChurchLevelTaxRate17` / `SetChurchLevelTaxRate17` | `world.church17_level_tax(0)` |
| `world.cobbler17_level_tax(cid)` / `world.set_cobbler17_level_tax(cid,v)` | `GetCobblerLevelTaxRate17` / `SetCobblerLevelTaxRate17` | `world.cobbler17_level_tax(0)` |
| `world.contor17_level_tax(cid)` / `world.set_contor17_level_tax(cid,v)` | `GetContorLevelTaxRate17` / `SetContorLevelTaxRate17` | `world.contor17_level_tax(0)` |
| `world.cook17_level_tax(cid)` / `world.set_cook17_level_tax(cid,v)` | `GetCookLevelTaxRate17` / `SetCookLevelTaxRate17` | `world.cook17_level_tax(0)` |
| `world.cooper17_level_tax(cid)` / `world.set_cooper17_level_tax(cid,v)` | `GetCooperLevelTaxRate17` / `SetCooperLevelTaxRate17` | `world.cooper17_level_tax(0)` |
| `world.courthouse17_level_tax(cid)` / `world.set_courthouse17_level_tax(cid,v)` | `GetCourthouseLevelTaxRate17` / `SetCourthouseLevelTaxRate17` | `world.courthouse17_level_tax(0)` |
| `world.dairy17_level_tax(cid)` / `world.set_dairy17_level_tax(cid,v)` | `GetDairyLevelTaxRate17` / `SetDairyLevelTaxRate17` | `world.dairy17_level_tax(0)` |
| `world.dice_house17_level_tax(cid)` / `world.set_dice_house17_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate17` / `SetDiceHouseLevelTaxRate17` | `world.dice_house17_level_tax(0)` |
| `world.distiller17_level_tax(cid)` / `world.set_distiller17_level_tax(cid,v)` | `GetDistillerLevelTaxRate17` / `SetDistillerLevelTaxRate17` | `world.distiller17_level_tax(0)` |
| `world.dyer17_level_tax(cid)` / `world.set_dyer17_level_tax(cid,v)` | `GetDyerLevelTaxRate17` / `SetDyerLevelTaxRate17` | `world.dyer17_level_tax(0)` |
| `world.fishery17_level_tax(cid)` / `world.set_fishery17_level_tax(cid,v)` | `GetFisheryLevelTaxRate17` / `SetFisheryLevelTaxRate17` | `world.fishery17_level_tax(0)` |
| `world.forum17_level_tax(cid)` / `world.set_forum17_level_tax(cid,v)` | `GetForumLevelTaxRate17` / `SetForumLevelTaxRate17` | `world.forum17_level_tax(0)` |
| `world.fowler17_level_tax(cid)` / `world.set_fowler17_level_tax(cid,v)` | `GetFowlerLevelTaxRate17` / `SetFowlerLevelTaxRate17` | `world.fowler17_level_tax(0)` |
| `world.furrier17_level_tax(cid)` / `world.set_furrier17_level_tax(cid,v)` | `GetFurrierLevelTaxRate17` / `SetFurrierLevelTaxRate17` | `world.furrier17_level_tax(0)` |
| `world.garrison17_level_tax(cid)` / `world.set_garrison17_level_tax(cid,v)` | `GetGarrisonLevelTaxRate17` / `SetGarrisonLevelTaxRate17` | `world.garrison17_level_tax(0)` |
| `world.gates17_level_tax(cid)` / `world.set_gates17_level_tax(cid,v)` | `GetGatesLevelTaxRate17` / `SetGatesLevelTaxRate17` | `world.gates17_level_tax(0)` |
| `world.glassblower17_level_tax(cid)` / `world.set_glassblower17_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate17` / `SetGlassblowerLevelTaxRate17` | `world.glassblower17_level_tax(0)` |
| `world.goldbeater17_level_tax(cid)` / `world.set_goldbeater17_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate17` / `SetGoldbeaterLevelTaxRate17` | `world.goldbeater17_level_tax(0)` |
| `world.goldsmith17_level_tax(cid)` / `world.set_goldsmith17_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate17` / `SetGoldsmithLevelTaxRate17` | `world.goldsmith17_level_tax(0)` |
| `world.granary17_level_tax(cid)` / `world.set_granary17_level_tax(cid,v)` | `GetGranaryLevelTaxRate17` / `SetGranaryLevelTaxRate17` | `world.granary17_level_tax(0)` |
| `world.guardhouse17_level_tax(cid)` / `world.set_guardhouse17_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate17` / `SetGuardhouseLevelTaxRate17` | `world.guardhouse17_level_tax(0)` |
| `world.guild_house17_level_tax(cid)` / `world.set_guild_house17_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate17` / `SetGuildHouseLevelTaxRate17` | `world.guild_house17_level_tax(0)` |
| `world.harbor17_level_tax(cid)` / `world.set_harbor17_level_tax(cid,v)` | `GetHarborLevelTaxRate17` / `SetHarborLevelTaxRate17` | `world.harbor17_level_tax(0)` |
| `world.harbor_dock17_level_tax(cid)` / `world.set_harbor_dock17_level_tax(cid,v)` | `GetHarborDockLevelTaxRate17` / `SetHarborDockLevelTaxRate17` | `world.harbor_dock17_level_tax(0)` |
| `world.harbor_walls17_level_tax(cid)` / `world.set_harbor_walls17_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate17` / `SetHarborWallsLevelTaxRate17` | `world.harbor_walls17_level_tax(0)` |
| `world.herb_garden17_level_tax(cid)` / `world.set_herb_garden17_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate17` / `SetHerbGardenLevelTaxRate17` | `world.herb_garden17_level_tax(0)` |
| `world.hospital17_level_tax(cid)` / `world.set_hospital17_level_tax(cid,v)` | `GetHospitalLevelTaxRate17` / `SetHospitalLevelTaxRate17` | `world.hospital17_level_tax(0)` |
| `world.house17_level_tax(cid)` / `world.set_house17_level_tax(cid,v)` | `GetHouseLevelTaxRate17` / `SetHouseLevelTaxRate17` | `world.house17_level_tax(0)` |
| `world.jeweler17_level_tax(cid)` / `world.set_jeweler17_level_tax(cid,v)` | `GetJewelerLevelTaxRate17` / `SetJewelerLevelTaxRate17` | `world.jeweler17_level_tax(0)` |
| `world.library17_level_tax(cid)` / `world.set_library17_level_tax(cid,v)` | `GetLibraryLevelTaxRate17` / `SetLibraryLevelTaxRate17` | `world.library17_level_tax(0)` |
| `world.library_hall17_level_tax(cid)` / `world.set_library_hall17_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate17` / `SetLibraryHallLevelTaxRate17` | `world.library_hall17_level_tax(0)` |
| `world.market17_level_tax(cid)` / `world.set_market17_level_tax(cid,v)` | `GetMarketLevelTaxRate17` / `SetMarketLevelTaxRate17` | `world.market17_level_tax(0)` |
| `world.miller17_level_tax(cid)` / `world.set_miller17_level_tax(cid,v)` | `GetMillerLevelTaxRate17` / `SetMillerLevelTaxRate17` | `world.miller17_level_tax(0)` |
| `world.mine17_level_tax(cid)` / `world.set_mine17_level_tax(cid,v)` | `GetMineLevelTaxRate17` / `SetMineLevelTaxRate17` | `world.mine17_level_tax(0)` |
| `world.mint17_level_tax(cid)` / `world.set_mint17_level_tax(cid,v)` | `GetMintLevelTaxRate17` / `SetMintLevelTaxRate17` | `world.mint17_level_tax(0)` |
| `world.monastery17_level_tax(cid)` / `world.set_monastery17_level_tax(cid,v)` | `GetMonasteryLevelTaxRate17` / `SetMonasteryLevelTaxRate17` | `world.monastery17_level_tax(0)` |
| `world.papermill17_level_tax(cid)` / `world.set_papermill17_level_tax(cid,v)` | `GetPapermillLevelTaxRate17` / `SetPapermillLevelTaxRate17` | `world.papermill17_level_tax(0)` |
| `world.perfumer17_level_tax(cid)` / `world.set_perfumer17_level_tax(cid,v)` | `GetPerfumerLevelTaxRate17` / `SetPerfumerLevelTaxRate17` | `world.perfumer17_level_tax(0)` |
| `world.potter17_level_tax(cid)` / `world.set_potter17_level_tax(cid,v)` | `GetPotterLevelTaxRate17` / `SetPotterLevelTaxRate17` | `world.potter17_level_tax(0)` |
| `world.pottery17_level_tax(cid)` / `world.set_pottery17_level_tax(cid,v)` | `GetPotteryLevelTaxRate17` / `SetPotteryLevelTaxRate17` | `world.pottery17_level_tax(0)` |
| `world.printing_house17_level_tax(cid)` / `world.set_printing_house17_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate17` / `SetPrintingHouseLevelTaxRate17` | `world.printing_house17_level_tax(0)` |
| `world.ropemaker17_level_tax(cid)` / `world.set_ropemaker17_level_tax(cid,v)` | `GetRopemakerLevelTaxRate17` / `SetRopemakerLevelTaxRate17` | `world.ropemaker17_level_tax(0)` |
| `world.ropemaker_workshop17_level_tax(cid)` / `world.set_ropemaker_workshop17_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate17` / `SetRopemakerWorkshopLevelTaxRate17` | `world.ropemaker_workshop17_level_tax(0)` |
| `world.saddler17_level_tax(cid)` / `world.set_saddler17_level_tax(cid,v)` | `GetSaddlerLevelTaxRate17` / `SetSaddlerLevelTaxRate17` | `world.saddler17_level_tax(0)` |
| `world.school17_level_tax(cid)` / `world.set_school17_level_tax(cid,v)` | `GetSchoolLevelTaxRate17` / `SetSchoolLevelTaxRate17` | `world.school17_level_tax(0)` |
| `world.schoolhouse17_level_tax(cid)` / `world.set_schoolhouse17_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate17` / `SetSchoolhouseLevelTaxRate17` | `world.schoolhouse17_level_tax(0)` |
| `world.sentry_tower17_level_tax(cid)` / `world.set_sentry_tower17_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate17` / `SetSentryTowerLevelTaxRate17` | `world.sentry_tower17_level_tax(0)` |
| `world.stables17_level_tax(cid)` / `world.set_stables17_level_tax(cid,v)` | `GetStablesLevelTaxRate17` / `SetStablesLevelTaxRate17` | `world.stables17_level_tax(0)` |
| `world.stonecutter17_level_tax(cid)` / `world.set_stonecutter17_level_tax(cid,v)` | `GetStonecutterLevelTaxRate17` / `SetStonecutterLevelTaxRate17` | `world.stonecutter17_level_tax(0)` |
| `world.tailor17_level_tax(cid)` / `world.set_tailor17_level_tax(cid,v)` | `GetTailorLevelTaxRate17` / `SetTailorLevelTaxRate17` | `world.tailor17_level_tax(0)` |
| `world.tannery17_level_tax(cid)` / `world.set_tannery17_level_tax(cid,v)` | `GetTanneryLevelTaxRate17` / `SetTanneryLevelTaxRate17` | `world.tannery17_level_tax(0)` |
| `world.tavern17_level_tax(cid)` / `world.set_tavern17_level_tax(cid,v)` | `GetTavernLevelTaxRate17` / `SetTavernLevelTaxRate17` | `world.tavern17_level_tax(0)` |
| `world.thieves_guild17_level_tax(cid)` / `world.set_thieves_guild17_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate17` / `SetThievesGuildLevelTaxRate17` | `world.thieves_guild17_level_tax(0)` |
| `world.toolmaker17_level_tax(cid)` / `world.set_toolmaker17_level_tax(cid,v)` | `GetToolmakerLevelTaxRate17` / `SetToolmakerLevelTaxRate17` | `world.toolmaker17_level_tax(0)` |
| `world.tower17_level_tax(cid)` / `world.set_tower17_level_tax(cid,v)` | `GetTowerLevelTaxRate17` / `SetTowerLevelTaxRate17` | `world.tower17_level_tax(0)` |
| `world.turner17_level_tax(cid)` / `world.set_turner17_level_tax(cid,v)` | `GetTurnerLevelTaxRate17` / `SetTurnerLevelTaxRate17` | `world.turner17_level_tax(0)` |
| `world.university17_level_tax(cid)` / `world.set_university17_level_tax(cid,v)` | `GetUniversityLevelTaxRate17` / `SetUniversityLevelTaxRate17` | `world.university17_level_tax(0)` |
| `world.university_hall17_level_tax(cid)` / `world.set_university_hall17_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate17` / `SetUniversityHallLevelTaxRate17` | `world.university_hall17_level_tax(0)` |
| `world.vineyard17_level_tax(cid)` / `world.set_vineyard17_level_tax(cid,v)` | `GetVineyardLevelTaxRate17` / `SetVineyardLevelTaxRate17` | `world.vineyard17_level_tax(0)` |
| `world.vintner17_level_tax(cid)` / `world.set_vintner17_level_tax(cid,v)` | `GetVintnerLevelTaxRate17` / `SetVintnerLevelTaxRate17` | `world.vintner17_level_tax(0)` |
| `world.wall18_level_tax(cid)` / `world.set_wall18_level_tax(cid,v)` | `GetWallLevelTaxRate18` / `SetWallLevelTaxRate18` | `world.wall18_level_tax(0)` |
| `world.warehouse17_level_tax(cid)` / `world.set_warehouse17_level_tax(cid,v)` | `GetWarehouseLevelTaxRate17` / `SetWarehouseLevelTaxRate17` | `world.warehouse17_level_tax(0)` |
| `world.weaving_mill17_level_tax(cid)` / `world.set_weaving_mill17_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate17` / `SetWeavingMillLevelTaxRate17` | `world.weaving_mill17_level_tax(0)` |
| `world.well17_level_tax(cid)` / `world.set_well17_level_tax(cid,v)` | `GetWellLevelTaxRate17` / `SetWellLevelTaxRate17` | `world.well17_level_tax(0)` |
| `world.armorer18_level_tax(cid)` / `world.set_armorer18_level_tax(cid,v)` | `GetArmorerLevelTaxRate18` / `SetArmorerLevelTaxRate18` | `world.armorer18_level_tax(0)` |
| `world.baker18_level_tax(cid)` / `world.set_baker18_level_tax(cid,v)` | `GetBakerLevelTaxRate18` / `SetBakerLevelTaxRate18` | `world.baker18_level_tax(0)` |
| `world.barber18_level_tax(cid)` / `world.set_barber18_level_tax(cid,v)` | `GetBarberLevelTaxRate18` / `SetBarberLevelTaxRate18` | `world.barber18_level_tax(0)` |
| `world.bathhouse18_level_tax(cid)` / `world.set_bathhouse18_level_tax(cid,v)` | `GetBathhouseLevelTaxRate18` / `SetBathhouseLevelTaxRate18` | `world.bathhouse18_level_tax(0)` |
| `world.bowyer18_level_tax(cid)` / `world.set_bowyer18_level_tax(cid,v)` | `GetBowyerLevelTaxRate18` / `SetBowyerLevelTaxRate18` | `world.bowyer18_level_tax(0)` |
| `world.brewmaster18_level_tax(cid)` / `world.set_brewmaster18_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate18` / `SetBrewmasterLevelTaxRate18` | `world.brewmaster18_level_tax(0)` |
| `world.brickmaker18_level_tax(cid)` / `world.set_brickmaker18_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate18` / `SetBrickmakerLevelTaxRate18` | `world.brickmaker18_level_tax(0)` |
| `world.bridge18_level_tax(cid)` / `world.set_bridge18_level_tax(cid,v)` | `GetBridgeLevelTaxRate18` / `SetBridgeLevelTaxRate18` | `world.bridge18_level_tax(0)` |
| `world.brothel18_level_tax(cid)` / `world.set_brothel18_level_tax(cid,v)` | `GetBrothelLevelTaxRate18` / `SetBrothelLevelTaxRate18` | `world.brothel18_level_tax(0)` |
| `world.butcher18_level_tax(cid)` / `world.set_butcher18_level_tax(cid,v)` | `GetButcherLevelTaxRate18` / `SetButcherLevelTaxRate18` | `world.butcher18_level_tax(0)` |
| `world.candlemaker18_level_tax(cid)` / `world.set_candlemaker18_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate18` / `SetCandlemakerLevelTaxRate18` | `world.candlemaker18_level_tax(0)` |
| `world.carpenter18_level_tax(cid)` / `world.set_carpenter18_level_tax(cid,v)` | `GetCarpenterLevelTaxRate18` / `SetCarpenterLevelTaxRate18` | `world.carpenter18_level_tax(0)` |
| `world.cartwright18_level_tax(cid)` / `world.set_cartwright18_level_tax(cid,v)` | `GetCartwrightLevelTaxRate18` / `SetCartwrightLevelTaxRate18` | `world.cartwright18_level_tax(0)` |
| `world.castle18_level_tax(cid)` / `world.set_castle18_level_tax(cid,v)` | `GetCastleLevelTaxRate18` / `SetCastleLevelTaxRate18` | `world.castle18_level_tax(0)` |
| `world.cathedral18_level_tax(cid)` / `world.set_cathedral18_level_tax(cid,v)` | `GetCathedralLevelTaxRate18` / `SetCathedralLevelTaxRate18` | `world.cathedral18_level_tax(0)` |
| `world.chandler18_level_tax(cid)` / `world.set_chandler18_level_tax(cid,v)` | `GetChandlerLevelTaxRate18` / `SetChandlerLevelTaxRate18` | `world.chandler18_level_tax(0)` |
| `world.chapel18_level_tax(cid)` / `world.set_chapel18_level_tax(cid,v)` | `GetChapelLevelTaxRate18` / `SetChapelLevelTaxRate18` | `world.chapel18_level_tax(0)` |
| `world.charcoal18_level_tax(cid)` / `world.set_charcoal18_level_tax(cid,v)` | `GetCharcoalLevelTaxRate18` / `SetCharcoalLevelTaxRate18` | `world.charcoal18_level_tax(0)` |
| `world.church18_level_tax(cid)` / `world.set_church18_level_tax(cid,v)` | `GetChurchLevelTaxRate18` / `SetChurchLevelTaxRate18` | `world.church18_level_tax(0)` |
| `world.cobbler18_level_tax(cid)` / `world.set_cobbler18_level_tax(cid,v)` | `GetCobblerLevelTaxRate18` / `SetCobblerLevelTaxRate18` | `world.cobbler18_level_tax(0)` |
| `world.contor18_level_tax(cid)` / `world.set_contor18_level_tax(cid,v)` | `GetContorLevelTaxRate18` / `SetContorLevelTaxRate18` | `world.contor18_level_tax(0)` |
| `world.cook18_level_tax(cid)` / `world.set_cook18_level_tax(cid,v)` | `GetCookLevelTaxRate18` / `SetCookLevelTaxRate18` | `world.cook18_level_tax(0)` |
| `world.cooper18_level_tax(cid)` / `world.set_cooper18_level_tax(cid,v)` | `GetCooperLevelTaxRate18` / `SetCooperLevelTaxRate18` | `world.cooper18_level_tax(0)` |
| `world.courthouse18_level_tax(cid)` / `world.set_courthouse18_level_tax(cid,v)` | `GetCourthouseLevelTaxRate18` / `SetCourthouseLevelTaxRate18` | `world.courthouse18_level_tax(0)` |
| `world.dairy18_level_tax(cid)` / `world.set_dairy18_level_tax(cid,v)` | `GetDairyLevelTaxRate18` / `SetDairyLevelTaxRate18` | `world.dairy18_level_tax(0)` |
| `world.dice_house18_level_tax(cid)` / `world.set_dice_house18_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate18` / `SetDiceHouseLevelTaxRate18` | `world.dice_house18_level_tax(0)` |
| `world.distiller18_level_tax(cid)` / `world.set_distiller18_level_tax(cid,v)` | `GetDistillerLevelTaxRate18` / `SetDistillerLevelTaxRate18` | `world.distiller18_level_tax(0)` |
| `world.dyer18_level_tax(cid)` / `world.set_dyer18_level_tax(cid,v)` | `GetDyerLevelTaxRate18` / `SetDyerLevelTaxRate18` | `world.dyer18_level_tax(0)` |
| `world.fishery18_level_tax(cid)` / `world.set_fishery18_level_tax(cid,v)` | `GetFisheryLevelTaxRate18` / `SetFisheryLevelTaxRate18` | `world.fishery18_level_tax(0)` |
| `world.forum18_level_tax(cid)` / `world.set_forum18_level_tax(cid,v)` | `GetForumLevelTaxRate18` / `SetForumLevelTaxRate18` | `world.forum18_level_tax(0)` |
| `world.fowler18_level_tax(cid)` / `world.set_fowler18_level_tax(cid,v)` | `GetFowlerLevelTaxRate18` / `SetFowlerLevelTaxRate18` | `world.fowler18_level_tax(0)` |
| `world.furrier18_level_tax(cid)` / `world.set_furrier18_level_tax(cid,v)` | `GetFurrierLevelTaxRate18` / `SetFurrierLevelTaxRate18` | `world.furrier18_level_tax(0)` |
| `world.garrison18_level_tax(cid)` / `world.set_garrison18_level_tax(cid,v)` | `GetGarrisonLevelTaxRate18` / `SetGarrisonLevelTaxRate18` | `world.garrison18_level_tax(0)` |
| `world.gates18_level_tax(cid)` / `world.set_gates18_level_tax(cid,v)` | `GetGatesLevelTaxRate18` / `SetGatesLevelTaxRate18` | `world.gates18_level_tax(0)` |
| `world.glassblower18_level_tax(cid)` / `world.set_glassblower18_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate18` / `SetGlassblowerLevelTaxRate18` | `world.glassblower18_level_tax(0)` |
| `world.goldbeater18_level_tax(cid)` / `world.set_goldbeater18_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate18` / `SetGoldbeaterLevelTaxRate18` | `world.goldbeater18_level_tax(0)` |
| `world.goldsmith18_level_tax(cid)` / `world.set_goldsmith18_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate18` / `SetGoldsmithLevelTaxRate18` | `world.goldsmith18_level_tax(0)` |
| `world.granary18_level_tax(cid)` / `world.set_granary18_level_tax(cid,v)` | `GetGranaryLevelTaxRate18` / `SetGranaryLevelTaxRate18` | `world.granary18_level_tax(0)` |
| `world.guardhouse18_level_tax(cid)` / `world.set_guardhouse18_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate18` / `SetGuardhouseLevelTaxRate18` | `world.guardhouse18_level_tax(0)` |
| `world.guild_house18_level_tax(cid)` / `world.set_guild_house18_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate18` / `SetGuildHouseLevelTaxRate18` | `world.guild_house18_level_tax(0)` |
| `world.harbor18_level_tax(cid)` / `world.set_harbor18_level_tax(cid,v)` | `GetHarborLevelTaxRate18` / `SetHarborLevelTaxRate18` | `world.harbor18_level_tax(0)` |
| `world.harbor_dock18_level_tax(cid)` / `world.set_harbor_dock18_level_tax(cid,v)` | `GetHarborDockLevelTaxRate18` / `SetHarborDockLevelTaxRate18` | `world.harbor_dock18_level_tax(0)` |
| `world.harbor_walls18_level_tax(cid)` / `world.set_harbor_walls18_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate18` / `SetHarborWallsLevelTaxRate18` | `world.harbor_walls18_level_tax(0)` |
| `world.herb_garden18_level_tax(cid)` / `world.set_herb_garden18_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate18` / `SetHerbGardenLevelTaxRate18` | `world.herb_garden18_level_tax(0)` |
| `world.hospital18_level_tax(cid)` / `world.set_hospital18_level_tax(cid,v)` | `GetHospitalLevelTaxRate18` / `SetHospitalLevelTaxRate18` | `world.hospital18_level_tax(0)` |
| `world.house18_level_tax(cid)` / `world.set_house18_level_tax(cid,v)` | `GetHouseLevelTaxRate18` / `SetHouseLevelTaxRate18` | `world.house18_level_tax(0)` |
| `world.jeweler18_level_tax(cid)` / `world.set_jeweler18_level_tax(cid,v)` | `GetJewelerLevelTaxRate18` / `SetJewelerLevelTaxRate18` | `world.jeweler18_level_tax(0)` |
| `world.library18_level_tax(cid)` / `world.set_library18_level_tax(cid,v)` | `GetLibraryLevelTaxRate18` / `SetLibraryLevelTaxRate18` | `world.library18_level_tax(0)` |
| `world.library_hall18_level_tax(cid)` / `world.set_library_hall18_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate18` / `SetLibraryHallLevelTaxRate18` | `world.library_hall18_level_tax(0)` |
| `world.market18_level_tax(cid)` / `world.set_market18_level_tax(cid,v)` | `GetMarketLevelTaxRate18` / `SetMarketLevelTaxRate18` | `world.market18_level_tax(0)` |
| `world.miller18_level_tax(cid)` / `world.set_miller18_level_tax(cid,v)` | `GetMillerLevelTaxRate18` / `SetMillerLevelTaxRate18` | `world.miller18_level_tax(0)` |
| `world.mine18_level_tax(cid)` / `world.set_mine18_level_tax(cid,v)` | `GetMineLevelTaxRate18` / `SetMineLevelTaxRate18` | `world.mine18_level_tax(0)` |
| `world.mint18_level_tax(cid)` / `world.set_mint18_level_tax(cid,v)` | `GetMintLevelTaxRate18` / `SetMintLevelTaxRate18` | `world.mint18_level_tax(0)` |
| `world.monastery18_level_tax(cid)` / `world.set_monastery18_level_tax(cid,v)` | `GetMonasteryLevelTaxRate18` / `SetMonasteryLevelTaxRate18` | `world.monastery18_level_tax(0)` |
| `world.papermill18_level_tax(cid)` / `world.set_papermill18_level_tax(cid,v)` | `GetPapermillLevelTaxRate18` / `SetPapermillLevelTaxRate18` | `world.papermill18_level_tax(0)` |
| `world.perfumer18_level_tax(cid)` / `world.set_perfumer18_level_tax(cid,v)` | `GetPerfumerLevelTaxRate18` / `SetPerfumerLevelTaxRate18` | `world.perfumer18_level_tax(0)` |
| `world.potter18_level_tax(cid)` / `world.set_potter18_level_tax(cid,v)` | `GetPotterLevelTaxRate18` / `SetPotterLevelTaxRate18` | `world.potter18_level_tax(0)` |
| `world.pottery18_level_tax(cid)` / `world.set_pottery18_level_tax(cid,v)` | `GetPotteryLevelTaxRate18` / `SetPotteryLevelTaxRate18` | `world.pottery18_level_tax(0)` |
| `world.printing_house18_level_tax(cid)` / `world.set_printing_house18_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate18` / `SetPrintingHouseLevelTaxRate18` | `world.printing_house18_level_tax(0)` |
| `world.ropemaker18_level_tax(cid)` / `world.set_ropemaker18_level_tax(cid,v)` | `GetRopemakerLevelTaxRate18` / `SetRopemakerLevelTaxRate18` | `world.ropemaker18_level_tax(0)` |
| `world.ropemaker_workshop18_level_tax(cid)` / `world.set_ropemaker_workshop18_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate18` / `SetRopemakerWorkshopLevelTaxRate18` | `world.ropemaker_workshop18_level_tax(0)` |
| `world.saddler18_level_tax(cid)` / `world.set_saddler18_level_tax(cid,v)` | `GetSaddlerLevelTaxRate18` / `SetSaddlerLevelTaxRate18` | `world.saddler18_level_tax(0)` |
| `world.school18_level_tax(cid)` / `world.set_school18_level_tax(cid,v)` | `GetSchoolLevelTaxRate18` / `SetSchoolLevelTaxRate18` | `world.school18_level_tax(0)` |
| `world.schoolhouse18_level_tax(cid)` / `world.set_schoolhouse18_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate18` / `SetSchoolhouseLevelTaxRate18` | `world.schoolhouse18_level_tax(0)` |
| `world.sentry_tower18_level_tax(cid)` / `world.set_sentry_tower18_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate18` / `SetSentryTowerLevelTaxRate18` | `world.sentry_tower18_level_tax(0)` |
| `world.stables18_level_tax(cid)` / `world.set_stables18_level_tax(cid,v)` | `GetStablesLevelTaxRate18` / `SetStablesLevelTaxRate18` | `world.stables18_level_tax(0)` |
| `world.stonecutter18_level_tax(cid)` / `world.set_stonecutter18_level_tax(cid,v)` | `GetStonecutterLevelTaxRate18` / `SetStonecutterLevelTaxRate18` | `world.stonecutter18_level_tax(0)` |
| `world.tailor18_level_tax(cid)` / `world.set_tailor18_level_tax(cid,v)` | `GetTailorLevelTaxRate18` / `SetTailorLevelTaxRate18` | `world.tailor18_level_tax(0)` |
| `world.tannery18_level_tax(cid)` / `world.set_tannery18_level_tax(cid,v)` | `GetTanneryLevelTaxRate18` / `SetTanneryLevelTaxRate18` | `world.tannery18_level_tax(0)` |
| `world.tavern18_level_tax(cid)` / `world.set_tavern18_level_tax(cid,v)` | `GetTavernLevelTaxRate18` / `SetTavernLevelTaxRate18` | `world.tavern18_level_tax(0)` |
| `world.thieves_guild18_level_tax(cid)` / `world.set_thieves_guild18_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate18` / `SetThievesGuildLevelTaxRate18` | `world.thieves_guild18_level_tax(0)` |
| `world.toolmaker18_level_tax(cid)` / `world.set_toolmaker18_level_tax(cid,v)` | `GetToolmakerLevelTaxRate18` / `SetToolmakerLevelTaxRate18` | `world.toolmaker18_level_tax(0)` |
| `world.tower18_level_tax(cid)` / `world.set_tower18_level_tax(cid,v)` | `GetTowerLevelTaxRate18` / `SetTowerLevelTaxRate18` | `world.tower18_level_tax(0)` |
| `world.turner18_level_tax(cid)` / `world.set_turner18_level_tax(cid,v)` | `GetTurnerLevelTaxRate18` / `SetTurnerLevelTaxRate18` | `world.turner18_level_tax(0)` |
| `world.university_hall18_level_tax(cid)` / `world.set_university_hall18_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate18` / `SetUniversityHallLevelTaxRate18` | `world.university_hall18_level_tax(0)` |
| `world.vineyard18_level_tax(cid)` / `world.set_vineyard18_level_tax(cid,v)` | `GetVineyardLevelTaxRate18` / `SetVineyardLevelTaxRate18` | `world.vineyard18_level_tax(0)` |
| `world.vintner18_level_tax(cid)` / `world.set_vintner18_level_tax(cid,v)` | `GetVintnerLevelTaxRate18` / `SetVintnerLevelTaxRate18` | `world.vintner18_level_tax(0)` |
| `world.warehouse18_level_tax(cid)` / `world.set_warehouse18_level_tax(cid,v)` | `GetWarehouseLevelTaxRate18` / `SetWarehouseLevelTaxRate18` | `world.warehouse18_level_tax(0)` |
| `world.weaving_mill18_level_tax(cid)` / `world.set_weaving_mill18_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate18` / `SetWeavingMillLevelTaxRate18` | `world.weaving_mill18_level_tax(0)` |
| `world.well18_level_tax(cid)` / `world.set_well18_level_tax(cid,v)` | `GetWellLevelTaxRate18` / `SetWellLevelTaxRate18` | `world.well18_level_tax(0)` |
| `world.armorer19_level_tax(cid)` / `world.set_armorer19_level_tax(cid,v)` | `GetArmorerLevelTaxRate19` / `SetArmorerLevelTaxRate19` | `world.armorer19_level_tax(0)` |
| `world.baker19_level_tax(cid)` / `world.set_baker19_level_tax(cid,v)` | `GetBakerLevelTaxRate19` / `SetBakerLevelTaxRate19` | `world.baker19_level_tax(0)` |
| `world.barber19_level_tax(cid)` / `world.set_barber19_level_tax(cid,v)` | `GetBarberLevelTaxRate19` / `SetBarberLevelTaxRate19` | `world.barber19_level_tax(0)` |
| `world.bathhouse19_level_tax(cid)` / `world.set_bathhouse19_level_tax(cid,v)` | `GetBathhouseLevelTaxRate19` / `SetBathhouseLevelTaxRate19` | `world.bathhouse19_level_tax(0)` |
| `world.bowyer19_level_tax(cid)` / `world.set_bowyer19_level_tax(cid,v)` | `GetBowyerLevelTaxRate19` / `SetBowyerLevelTaxRate19` | `world.bowyer19_level_tax(0)` |
| `world.brewmaster19_level_tax(cid)` / `world.set_brewmaster19_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate19` / `SetBrewmasterLevelTaxRate19` | `world.brewmaster19_level_tax(0)` |
| `world.brickmaker19_level_tax(cid)` / `world.set_brickmaker19_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate19` / `SetBrickmakerLevelTaxRate19` | `world.brickmaker19_level_tax(0)` |
| `world.bridge19_level_tax(cid)` / `world.set_bridge19_level_tax(cid,v)` | `GetBridgeLevelTaxRate19` / `SetBridgeLevelTaxRate19` | `world.bridge19_level_tax(0)` |
| `world.brothel19_level_tax(cid)` / `world.set_brothel19_level_tax(cid,v)` | `GetBrothelLevelTaxRate19` / `SetBrothelLevelTaxRate19` | `world.brothel19_level_tax(0)` |
| `world.butcher19_level_tax(cid)` / `world.set_butcher19_level_tax(cid,v)` | `GetButcherLevelTaxRate19` / `SetButcherLevelTaxRate19` | `world.butcher19_level_tax(0)` |
| `world.candlemaker19_level_tax(cid)` / `world.set_candlemaker19_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate19` / `SetCandlemakerLevelTaxRate19` | `world.candlemaker19_level_tax(0)` |
| `world.carpenter19_level_tax(cid)` / `world.set_carpenter19_level_tax(cid,v)` | `GetCarpenterLevelTaxRate19` / `SetCarpenterLevelTaxRate19` | `world.carpenter19_level_tax(0)` |
| `world.cartwright19_level_tax(cid)` / `world.set_cartwright19_level_tax(cid,v)` | `GetCartwrightLevelTaxRate19` / `SetCartwrightLevelTaxRate19` | `world.cartwright19_level_tax(0)` |
| `world.castle19_level_tax(cid)` / `world.set_castle19_level_tax(cid,v)` | `GetCastleLevelTaxRate19` / `SetCastleLevelTaxRate19` | `world.castle19_level_tax(0)` |
| `world.cathedral19_level_tax(cid)` / `world.set_cathedral19_level_tax(cid,v)` | `GetCathedralLevelTaxRate19` / `SetCathedralLevelTaxRate19` | `world.cathedral19_level_tax(0)` |
| `world.chandler19_level_tax(cid)` / `world.set_chandler19_level_tax(cid,v)` | `GetChandlerLevelTaxRate19` / `SetChandlerLevelTaxRate19` | `world.chandler19_level_tax(0)` |
| `world.chapel19_level_tax(cid)` / `world.set_chapel19_level_tax(cid,v)` | `GetChapelLevelTaxRate19` / `SetChapelLevelTaxRate19` | `world.chapel19_level_tax(0)` |
| `world.charcoal19_level_tax(cid)` / `world.set_charcoal19_level_tax(cid,v)` | `GetCharcoalLevelTaxRate19` / `SetCharcoalLevelTaxRate19` | `world.charcoal19_level_tax(0)` |
| `world.church19_level_tax(cid)` / `world.set_church19_level_tax(cid,v)` | `GetChurchLevelTaxRate19` / `SetChurchLevelTaxRate19` | `world.church19_level_tax(0)` |
| `world.cobbler19_level_tax(cid)` / `world.set_cobbler19_level_tax(cid,v)` | `GetCobblerLevelTaxRate19` / `SetCobblerLevelTaxRate19` | `world.cobbler19_level_tax(0)` |
| `world.contor19_level_tax(cid)` / `world.set_contor19_level_tax(cid,v)` | `GetContorLevelTaxRate19` / `SetContorLevelTaxRate19` | `world.contor19_level_tax(0)` |
| `world.cook19_level_tax(cid)` / `world.set_cook19_level_tax(cid,v)` | `GetCookLevelTaxRate19` / `SetCookLevelTaxRate19` | `world.cook19_level_tax(0)` |
| `world.cooper19_level_tax(cid)` / `world.set_cooper19_level_tax(cid,v)` | `GetCooperLevelTaxRate19` / `SetCooperLevelTaxRate19` | `world.cooper19_level_tax(0)` |
| `world.courthouse19_level_tax(cid)` / `world.set_courthouse19_level_tax(cid,v)` | `GetCourthouseLevelTaxRate19` / `SetCourthouseLevelTaxRate19` | `world.courthouse19_level_tax(0)` |
| `world.dairy19_level_tax(cid)` / `world.set_dairy19_level_tax(cid,v)` | `GetDairyLevelTaxRate19` / `SetDairyLevelTaxRate19` | `world.dairy19_level_tax(0)` |
| `world.dice_house19_level_tax(cid)` / `world.set_dice_house19_level_tax(cid,v)` | `GetDiceHouseLevelTaxRate19` / `SetDiceHouseLevelTaxRate19` | `world.dice_house19_level_tax(0)` |
| `world.distiller19_level_tax(cid)` / `world.set_distiller19_level_tax(cid,v)` | `GetDistillerLevelTaxRate19` / `SetDistillerLevelTaxRate19` | `world.distiller19_level_tax(0)` |
| `world.dyer19_level_tax(cid)` / `world.set_dyer19_level_tax(cid,v)` | `GetDyerLevelTaxRate19` / `SetDyerLevelTaxRate19` | `world.dyer19_level_tax(0)` |
| `world.fishery19_level_tax(cid)` / `world.set_fishery19_level_tax(cid,v)` | `GetFisheryLevelTaxRate19` / `SetFisheryLevelTaxRate19` | `world.fishery19_level_tax(0)` |
| `world.forum19_level_tax(cid)` / `world.set_forum19_level_tax(cid,v)` | `GetForumLevelTaxRate19` / `SetForumLevelTaxRate19` | `world.forum19_level_tax(0)` |
| `world.fowler19_level_tax(cid)` / `world.set_fowler19_level_tax(cid,v)` | `GetFowlerLevelTaxRate19` / `SetFowlerLevelTaxRate19` | `world.fowler19_level_tax(0)` |
| `world.furrier19_level_tax(cid)` / `world.set_furrier19_level_tax(cid,v)` | `GetFurrierLevelTaxRate19` / `SetFurrierLevelTaxRate19` | `world.furrier19_level_tax(0)` |
| `world.garrison19_level_tax(cid)` / `world.set_garrison19_level_tax(cid,v)` | `GetGarrisonLevelTaxRate19` / `SetGarrisonLevelTaxRate19` | `world.garrison19_level_tax(0)` |
| `world.gates19_level_tax(cid)` / `world.set_gates19_level_tax(cid,v)` | `GetGatesLevelTaxRate19` / `SetGatesLevelTaxRate19` | `world.gates19_level_tax(0)` |
| `world.glassblower19_level_tax(cid)` / `world.set_glassblower19_level_tax(cid,v)` | `GetGlassblowerLevelTaxRate19` / `SetGlassblowerLevelTaxRate19` | `world.glassblower19_level_tax(0)` |
| `world.goldbeater19_level_tax(cid)` / `world.set_goldbeater19_level_tax(cid,v)` | `GetGoldbeaterLevelTaxRate19` / `SetGoldbeaterLevelTaxRate19` | `world.goldbeater19_level_tax(0)` |
| `world.goldsmith19_level_tax(cid)` / `world.set_goldsmith19_level_tax(cid,v)` | `GetGoldsmithLevelTaxRate19` / `SetGoldsmithLevelTaxRate19` | `world.goldsmith19_level_tax(0)` |
| `world.granary19_level_tax(cid)` / `world.set_granary19_level_tax(cid,v)` | `GetGranaryLevelTaxRate19` / `SetGranaryLevelTaxRate19` | `world.granary19_level_tax(0)` |
| `world.guardhouse19_level_tax(cid)` / `world.set_guardhouse19_level_tax(cid,v)` | `GetGuardhouseLevelTaxRate19` / `SetGuardhouseLevelTaxRate19` | `world.guardhouse19_level_tax(0)` |
| `world.guild_house19_level_tax(cid)` / `world.set_guild_house19_level_tax(cid,v)` | `GetGuildHouseLevelTaxRate19` / `SetGuildHouseLevelTaxRate19` | `world.guild_house19_level_tax(0)` |
| `world.harbor19_level_tax(cid)` / `world.set_harbor19_level_tax(cid,v)` | `GetHarborLevelTaxRate19` / `SetHarborLevelTaxRate19` | `world.harbor19_level_tax(0)` |
| `world.harbor_dock19_level_tax(cid)` / `world.set_harbor_dock19_level_tax(cid,v)` | `GetHarborDockLevelTaxRate19` / `SetHarborDockLevelTaxRate19` | `world.harbor_dock19_level_tax(0)` |
| `world.harbor_walls19_level_tax(cid)` / `world.set_harbor_walls19_level_tax(cid,v)` | `GetHarborWallsLevelTaxRate19` / `SetHarborWallsLevelTaxRate19` | `world.harbor_walls19_level_tax(0)` |
| `world.herb_garden19_level_tax(cid)` / `world.set_herb_garden19_level_tax(cid,v)` | `GetHerbGardenLevelTaxRate19` / `SetHerbGardenLevelTaxRate19` | `world.herb_garden19_level_tax(0)` |
| `world.hospital19_level_tax(cid)` / `world.set_hospital19_level_tax(cid,v)` | `GetHospitalLevelTaxRate19` / `SetHospitalLevelTaxRate19` | `world.hospital19_level_tax(0)` |
| `world.house19_level_tax(cid)` / `world.set_house19_level_tax(cid,v)` | `GetHouseLevelTaxRate19` / `SetHouseLevelTaxRate19` | `world.house19_level_tax(0)` |
| `world.jeweler19_level_tax(cid)` / `world.set_jeweler19_level_tax(cid,v)` | `GetJewelerLevelTaxRate19` / `SetJewelerLevelTaxRate19` | `world.jeweler19_level_tax(0)` |
| `world.library19_level_tax(cid)` / `world.set_library19_level_tax(cid,v)` | `GetLibraryLevelTaxRate19` / `SetLibraryLevelTaxRate19` | `world.library19_level_tax(0)` |
| `world.library_hall19_level_tax(cid)` / `world.set_library_hall19_level_tax(cid,v)` | `GetLibraryHallLevelTaxRate19` / `SetLibraryHallLevelTaxRate19` | `world.library_hall19_level_tax(0)` |
| `world.market19_level_tax(cid)` / `world.set_market19_level_tax(cid,v)` | `GetMarketLevelTaxRate19` / `SetMarketLevelTaxRate19` | `world.market19_level_tax(0)` |
| `world.miller19_level_tax(cid)` / `world.set_miller19_level_tax(cid,v)` | `GetMillerLevelTaxRate19` / `SetMillerLevelTaxRate19` | `world.miller19_level_tax(0)` |
| `world.mine19_level_tax(cid)` / `world.set_mine19_level_tax(cid,v)` | `GetMineLevelTaxRate19` / `SetMineLevelTaxRate19` | `world.mine19_level_tax(0)` |
| `world.mint19_level_tax(cid)` / `world.set_mint19_level_tax(cid,v)` | `GetMintLevelTaxRate19` / `SetMintLevelTaxRate19` | `world.mint19_level_tax(0)` |
| `world.monastery19_level_tax(cid)` / `world.set_monastery19_level_tax(cid,v)` | `GetMonasteryLevelTaxRate19` / `SetMonasteryLevelTaxRate19` | `world.monastery19_level_tax(0)` |
| `world.papermill19_level_tax(cid)` / `world.set_papermill19_level_tax(cid,v)` | `GetPapermillLevelTaxRate19` / `SetPapermillLevelTaxRate19` | `world.papermill19_level_tax(0)` |
| `world.perfumer19_level_tax(cid)` / `world.set_perfumer19_level_tax(cid,v)` | `GetPerfumerLevelTaxRate19` / `SetPerfumerLevelTaxRate19` | `world.perfumer19_level_tax(0)` |
| `world.potter19_level_tax(cid)` / `world.set_potter19_level_tax(cid,v)` | `GetPotterLevelTaxRate19` / `SetPotterLevelTaxRate19` | `world.potter19_level_tax(0)` |
| `world.pottery19_level_tax(cid)` / `world.set_pottery19_level_tax(cid,v)` | `GetPotteryLevelTaxRate19` / `SetPotteryLevelTaxRate19` | `world.pottery19_level_tax(0)` |
| `world.printing_house19_level_tax(cid)` / `world.set_printing_house19_level_tax(cid,v)` | `GetPrintingHouseLevelTaxRate19` / `SetPrintingHouseLevelTaxRate19` | `world.printing_house19_level_tax(0)` |
| `world.ropemaker19_level_tax(cid)` / `world.set_ropemaker19_level_tax(cid,v)` | `GetRopemakerLevelTaxRate19` / `SetRopemakerLevelTaxRate19` | `world.ropemaker19_level_tax(0)` |
| `world.ropemaker_workshop19_level_tax(cid)` / `world.set_ropemaker_workshop19_level_tax(cid,v)` | `GetRopemakerWorkshopLevelTaxRate19` / `SetRopemakerWorkshopLevelTaxRate19` | `world.ropemaker_workshop19_level_tax(0)` |
| `world.saddler19_level_tax(cid)` / `world.set_saddler19_level_tax(cid,v)` | `GetSaddlerLevelTaxRate19` / `SetSaddlerLevelTaxRate19` | `world.saddler19_level_tax(0)` |
| `world.school19_level_tax(cid)` / `world.set_school19_level_tax(cid,v)` | `GetSchoolLevelTaxRate19` / `SetSchoolLevelTaxRate19` | `world.school19_level_tax(0)` |
| `world.schoolhouse19_level_tax(cid)` / `world.set_schoolhouse19_level_tax(cid,v)` | `GetSchoolhouseLevelTaxRate19` / `SetSchoolhouseLevelTaxRate19` | `world.schoolhouse19_level_tax(0)` |
| `world.sentry_tower19_level_tax(cid)` / `world.set_sentry_tower19_level_tax(cid,v)` | `GetSentryTowerLevelTaxRate19` / `SetSentryTowerLevelTaxRate19` | `world.sentry_tower19_level_tax(0)` |
| `world.stables19_level_tax(cid)` / `world.set_stables19_level_tax(cid,v)` | `GetStablesLevelTaxRate19` / `SetStablesLevelTaxRate19` | `world.stables19_level_tax(0)` |
| `world.stonecutter19_level_tax(cid)` / `world.set_stonecutter19_level_tax(cid,v)` | `GetStonecutterLevelTaxRate19` / `SetStonecutterLevelTaxRate19` | `world.stonecutter19_level_tax(0)` |
| `world.tailor19_level_tax(cid)` / `world.set_tailor19_level_tax(cid,v)` | `GetTailorLevelTaxRate19` / `SetTailorLevelTaxRate19` | `world.tailor19_level_tax(0)` |
| `world.tannery19_level_tax(cid)` / `world.set_tannery19_level_tax(cid,v)` | `GetTanneryLevelTaxRate19` / `SetTanneryLevelTaxRate19` | `world.tannery19_level_tax(0)` |
| `world.tavern19_level_tax(cid)` / `world.set_tavern19_level_tax(cid,v)` | `GetTavernLevelTaxRate19` / `SetTavernLevelTaxRate19` | `world.tavern19_level_tax(0)` |
| `world.thieves_guild19_level_tax(cid)` / `world.set_thieves_guild19_level_tax(cid,v)` | `GetThievesGuildLevelTaxRate19` / `SetThievesGuildLevelTaxRate19` | `world.thieves_guild19_level_tax(0)` |
| `world.toolmaker19_level_tax(cid)` / `world.set_toolmaker19_level_tax(cid,v)` | `GetToolmakerLevelTaxRate19` / `SetToolmakerLevelTaxRate19` | `world.toolmaker19_level_tax(0)` |
| `world.tower19_level_tax(cid)` / `world.set_tower19_level_tax(cid,v)` | `GetTowerLevelTaxRate19` / `SetTowerLevelTaxRate19` | `world.tower19_level_tax(0)` |
| `world.turner19_level_tax(cid)` / `world.set_turner19_level_tax(cid,v)` | `GetTurnerLevelTaxRate19` / `SetTurnerLevelTaxRate19` | `world.turner19_level_tax(0)` |
| `world.university_hall19_level_tax(cid)` / `world.set_university_hall19_level_tax(cid,v)` | `GetUniversityHallLevelTaxRate19` / `SetUniversityHallLevelTaxRate19` | `world.university_hall19_level_tax(0)` |
| `world.vineyard19_level_tax(cid)` / `world.set_vineyard19_level_tax(cid,v)` | `GetVineyardLevelTaxRate19` / `SetVineyardLevelTaxRate19` | `world.vineyard19_level_tax(0)` |
| `world.vintner19_level_tax(cid)` / `world.set_vintner19_level_tax(cid,v)` | `GetVintnerLevelTaxRate19` / `SetVintnerLevelTaxRate19` | `world.vintner19_level_tax(0)` |
| `world.warehouse19_level_tax(cid)` / `world.set_warehouse19_level_tax(cid,v)` | `GetWarehouseLevelTaxRate19` / `SetWarehouseLevelTaxRate19` | `world.warehouse19_level_tax(0)` |
| `world.weaving_mill19_level_tax(cid)` / `world.set_weaving_mill19_level_tax(cid,v)` | `GetWeavingMillLevelTaxRate19` / `SetWeavingMillLevelTaxRate19` | `world.weaving_mill19_level_tax(0)` |
| `world.well19_level_tax(cid)` / `world.set_well19_level_tax(cid,v)` | `GetWellLevelTaxRate19` / `SetWellLevelTaxRate19` | `world.well19_level_tax(0)` |
| `world.wall19_level_tax(cid)` / `world.set_wall19_level_tax(cid,v)` | `GetWallLevelTaxRate19` / `SetWallLevelTaxRate19` | `world.wall19_level_tax(0)` |
| `world.armorer20_level_tax(cid)` / `world.set_armorer20_level_tax(cid,v)` | `GetArmorerLevelTaxRate20` / `SetArmorerLevelTaxRate20` | `world.armorer20_level_tax(0)` |
| `world.baker20_level_tax(cid)` / `world.set_baker20_level_tax(cid,v)` | `GetBakerLevelTaxRate20` / `SetBakerLevelTaxRate20` | `world.baker20_level_tax(0)` |
| `world.barber20_level_tax(cid)` / `world.set_barber20_level_tax(cid,v)` | `GetBarberLevelTaxRate20` / `SetBarberLevelTaxRate20` | `world.barber20_level_tax(0)` |
| `world.bathhouse20_level_tax(cid)` / `world.set_bathhouse20_level_tax(cid,v)` | `GetBathhouseLevelTaxRate20` / `SetBathhouseLevelTaxRate20` | `world.bathhouse20_level_tax(0)` |
| `world.bowyer20_level_tax(cid)` / `world.set_bowyer20_level_tax(cid,v)` | `GetBowyerLevelTaxRate20` / `SetBowyerLevelTaxRate20` | `world.bowyer20_level_tax(0)` |
| `world.brewmaster20_level_tax(cid)` / `world.set_brewmaster20_level_tax(cid,v)` | `GetBrewmasterLevelTaxRate20` / `SetBrewmasterLevelTaxRate20` | `world.brewmaster20_level_tax(0)` |
| `world.brickmaker20_level_tax(cid)` / `world.set_brickmaker20_level_tax(cid,v)` | `GetBrickmakerLevelTaxRate20` / `SetBrickmakerLevelTaxRate20` | `world.brickmaker20_level_tax(0)` |
| `world.bridge14_level_tax(cid)` / `world.set_bridge14_level_tax(cid,v)` | `GetBridgeLevelTaxRate14` / `SetBridgeLevelTaxRate14` | `world.bridge14_level_tax(0)` |
| `world.brothel14_level_tax(cid)` / `world.set_brothel14_level_tax(cid,v)` | `GetBrothelLevelTaxRate14` / `SetBrothelLevelTaxRate14` | `world.brothel14_level_tax(0)` |
| `world.butcher14_level_tax(cid)` / `world.set_butcher14_level_tax(cid,v)` | `GetButcherLevelTaxRate14` / `SetButcherLevelTaxRate14` | `world.butcher14_level_tax(0)` |
| `world.candlemaker14_level_tax(cid)` / `world.set_candlemaker14_level_tax(cid,v)` | `GetCandlemakerLevelTaxRate14` / `SetCandlemakerLevelTaxRate14` | `world.candlemaker14_level_tax(0)` |
| `world.carpenter14_level_tax(cid)` / `world.set_carpenter14_level_tax(cid,v)` | `GetCarpenterLevelTaxRate14` / `SetCarpenterLevelTaxRate14` | `world.carpenter14_level_tax(0)` |
| `world.cartwright14_level_tax(cid)` / `world.set_cartwright14_level_tax(cid,v)` | `GetCartwrightLevelTaxRate14` / `SetCartwrightLevelTaxRate14` | `world.cartwright14_level_tax(0)` |
| `world.castle14_level_tax(cid)` / `world.set_castle14_level_tax(cid,v)` | `GetCastleLevelTaxRate14` / `SetCastleLevelTaxRate14` | `world.castle14_level_tax(0)` |
| `world.cathedral14_level_tax(cid)` / `world.set_cathedral14_level_tax(cid,v)` | `GetCathedralLevelTaxRate14` / `SetCathedralLevelTaxRate14` | `world.cathedral14_level_tax(0)` |
| `world.chandler14_level_tax(cid)` / `world.set_chandler14_level_tax(cid,v)` | `GetChandlerLevelTaxRate14` / `SetChandlerLevelTaxRate14` | `world.chandler14_level_tax(0)` |
| `world.chapel14_level_tax(cid)` / `world.set_chapel14_level_tax(cid,v)` | `GetChapelLevelTaxRate14` / `SetChapelLevelTaxRate14` | `world.chapel14_level_tax(0)` |
| `world.charcoal14_level_tax(cid)` / `world.set_charcoal14_level_tax(cid,v)` | `GetCharcoalLevelTaxRate14` / `SetCharcoalLevelTaxRate14` | `world.charcoal14_level_tax(0)` |
| `world.contor_tax(cid)` / `world.set_contor_tax(cid,v)` | `GetContorTaxRate` / `SetContorTaxRate` | `world.contor_tax(0)` |
| `world.dice_house_tax(cid)` / `world.set_dice_house_tax(cid,v)` | `GetDiceHouseTaxRate` / `SetDiceHouseTaxRate` | `world.dice_house_tax(0)` |
| `world.thieves_guild_tax(cid)` / `world.set_thieves_guild_tax(cid,v)` | `GetThievesGuildTaxRate` / `SetThievesGuildTaxRate` | `world.thieves_guild_tax(0)` |
| `world.harbor_walls_tax3(cid)` / `world.set_harbor_walls_tax3(cid,v)` | `GetHarborWallsTaxRate3` / `SetHarborWallsTaxRate3` | `world.harbor_walls_tax3(0)` |
| `world.mining_ws2(cid)` / `world.set_mining_ws2(cid,v)` | `GetMiningWorkshopLevel2` / `SetMiningWorkshopLevel2` | `world.mining_ws2(0)` |
| `world.logging_ws2(cid)` / `world.set_logging_ws2(cid,v)` | `GetLoggingWorkshopLevel2` / `SetLoggingWorkshopLevel2` | `world.logging_ws2(0)` |
| `world.inn_level2(cid)` / `world.set_inn_level2(cid,v)` | `GetInnLevel2` / `SetInnLevel2` | `world.inn_level2(0)` |
| `world.robber_camp2(cid)` / `world.set_robber_camp2(cid,v)` | `GetRobberCampLevel2` / `SetRobberCampLevel2` | `world.robber_camp2(0)` |
| `world.pop_limit(cid)` / `world.set_pop_limit(cid,v)` | `GetCityPopulationLimit` / `SetCityPopulationLimit` | `world.pop_limit(0)` |
| `world.growth(cid)` | `GetCityGrowthRate` | `world.growth(0)` |
| `world.road_toll(cid,rid)` / `world.set_road_toll(cid,rid,v)` | `GetRoadTollRate` / `SetRoadTollRate` | `world.road_toll(0,0)` |
| `world.church_corruption(cid)` / `world.set_church_corruption(cid,v)` | `GetChurchCorruption` / `SetChurchCorruption` | `world.church_corruption(0)` |
| `world.robber(cid)` | `GetRobberThreat` | `world.robber(0)` |

## Quest Helper (`quest.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `quest.find([base,size])` | `catalog.hunt("quest")` | `quest.find()` |
| `quest.scan([base,size])` | Hunt quest preset | `quest.scan(0x400000, 0x300000)` |
| `quest.start(id, owner)` | `StartQuest` | `quest.start(1, 0)` |
| `quest.complete(id)` | `CompleteQuest` | `quest.complete(1)` |
| `quest.fail(id)` | `FailQuest` | `quest.fail(1)` |
| `quest.status(id)` | `GetQuestStatus` | `quest.status(1)` |
| `quest.owner(id)` | `GetQuestOwner` | `quest.owner(1)` |
| `quest.target(id)` | `GetQuestTarget` | `quest.target(1)` |
| `quest.get_var(id,var)` | `GetQuestVar` | `quest.get_var(1, 0)` |
| `quest.set_var(id,var,v)` | `SetQuestVar` | `quest.set_var(1, 0, 42)` |

All wrappers error with a hint if the catalog entry not yet registered.

## Social Helper (`social.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `social.find([base,size])` | `catalog.hunt("guild")` fallback | `social.find()` |
| `social.scan([base,size])` | Hunt guild/reputation/chat/unit/fame presets | `social.scan(0x400000, 0x300000)` |
| `social.is_member(pid,gid)` | `IsGuildMember` | `social.is_member(0, 1)` |
| `social.join(pid,gid)` | `JoinGuild` | `social.join(0, 1)` |
| `social.leave(gid)` | `LeaveGuild` | `social.leave(1)` |
| `social.guild_rank(pid,gid)` / `social.set_guild_rank(pid,gid,r)` | `GetGuildRank` / `SetGuildRank` | `social.guild_rank(0, 1)` |
| `social.nobility(pid)` / `social.set_nobility(pid,t)` | `NobilityTitle` / `SetNobilityTitle` | `social.nobility(0)` |
| `social.privileges(pid)` | `GetPrivileges` | `social.privileges(0)` |
| `social.reputation(pid,fid)` / `social.set_reputation(pid,fid,v)` | `GetReputation` / `SetReputation` | `social.reputation(0, 1)` |
| `social.diplomacy(a,b)` / `social.set_diplomacy(a,b,v)` | `GetDiplomacy` / `SetDiplomacy` | `social.diplomacy(0, 1)` |
| `social.alliance(a,b)` / `social.set_alliance(a,b,s)` | `GetAlliance` / `SetAlliance` | `social.alliance(0, 1)` |
| `social.family_count(fid)` | `GetFamilyMemberCount` | `social.family_count(0)` |
| `social.marriage(pid,spouse)` | `GetMarriageState` | `social.marriage(0, 1)` |
| `social.marriage_partner(pid)` | `GetMarriagePartner` | `social.marriage_partner(0)` |
| `social.divorce(pid,spouse)` | `Divorce` | `social.divorce(0, 1)` |
| `social.is_dead(pid)` | `IsPlayerDead` | `social.is_dead(0)` |
| `social.dynasty_name(did)` / `social.set_dynasty_name(did,name)` | `GetDynastyName` / `SetDynastyName` | `social.dynasty_name(0)` |
| `social.dynasty_members(did)` | `GetDynastyMembers` | `social.dynasty_members(0)` |
| `social.espionage(pid,tid)` / `social.set_espionage(pid,tid,lvl)` | `GetEspionageLevel` / `SetEspionageLevel` | `social.espionage(0, 1)` |
| `social.intrigue(pid,tid)` / `social.set_intrigue(pid,tid,lvl)` | `GetIntrigueLevel` / `SetIntrigueLevel` | `social.intrigue(0, 1)` |
| `social.aggressiveness(pid)` / `social.set_aggressiveness(pid,lvl)` | `GetAggressiveness` / `SetAggressiveness` | `social.aggressiveness(0)` |
| `social.is_title_available(tid)` | `IsTitleAvailable` | `social.is_title_available(1)` |
| `social.claim_title(pid,tid)` | `ClaimTitle` | `social.claim_title(0, 1)` |
| `social.title_cost(tid)` | `GetTitleCost` | `social.title_cost(1)` |
| `social.influence(pid,cid)` / `social.set_influence(pid,cid,v)` | `GetInfluence` / `SetInfluence` | `social.influence(0, 0)` |
| `social.guild_reputation(pid,gid)` / `social.set_guild_reputation(pid,gid,rep)` | `GetGuildReputation` / `SetGuildReputation` | `social.guild_reputation(0,1)` |
| `social.dynasty_cash(did)` / `social.set_dynasty_cash(did,n)` | `GetDynastyCash` / `SetDynastyCash` | `social.dynasty_cash(0)` |
| `social.court_influence(pid)` / `social.set_court_influence(pid,v)` | `GetCourtInfluence` / `SetCourtInfluence` | `social.court_influence(0)` |
| `social.guild_master(gid)` / `social.set_guild_master(gid,pid)` | `GetGuildMaster` / `SetGuildMaster` | `social.guild_master(0)` |
| `social.relation(a,b)` / `social.set_relation(a,b,v)` | `GetRelation` / `SetRelation` | `social.relation(0,1)` |
| `social.prestige(pid)` / `social.set_prestige(pid,v)` | `GetPrestige` / `SetPrestige` | `social.prestige(0)` |
| `social.disease(pid)` / `social.set_disease(pid,v)` | `GetDiseaseState` / `SetDiseaseState` | `social.disease(0)` |
| `social.court_rank(pid)` / `social.set_court_rank(pid,v)` | `GetCourtRank` / `SetCourtRank` | `social.court_rank(0)` |
| `social.ai_behavior(pid)` / `social.set_ai_behavior(pid,v)` | `GetAIBehavior` / `SetAIBehavior` | `social.ai_behavior(0)` |
| `social.faith(pid)` / `social.set_faith(pid,v)` | `GetFaith` / `SetFaith` | `social.faith(0)` |
| `social.tithe(cid)` / `social.set_tithe(cid,v)` | `GetTitheRate` / `SetTitheRate` | `social.tithe(0)` |
| `social.piety(pid)` / `social.set_piety(pid,v)` | `GetPiety` / `SetPiety` | `social.piety(0)` |
| `social.court_favor(pid,nid)` / `social.set_court_favor(pid,nid,v)` | `GetCourtFavor` / `SetCourtFavor` | `social.court_favor(0,1)` |
| `social.bribe_success(pid,cid,oid)` | `GetBribeSuccess` | `social.bribe_success(0,0,1)` |
| `social.spy_info(pid,tid)` | `GetSpyInfo` | `social.spy_info(0,1)` |
| `social.dynasty_reputation(did)` / `social.set_dynasty_reputation(did,v)` | `GetDynastyReputation` / `SetDynastyReputation` | `social.dynasty_reputation(0)` |
| `social.family_wealth(fid)` / `social.set_family_wealth(fid,v)` | `GetFamilyWealth` / `SetFamilyWealth` | `social.family_wealth(0)` |
| `social.court_influence_level(pid,lvl)` / `social.set_court_influence_level(pid,lvl,v)` | `GetCourtInfluenceLevel` / `SetCourtInfluenceLevel` | `social.court_influence_level(0,1)` |
| `social.assassin_level(pid)` / `social.set_assassin_level(pid,v)` | `GetAssassinLevel` / `SetAssassinLevel` | `social.assassin_level(0)` |
| `social.arrest_warrant(pid)` / `social.issue_warrant(issuer,target)` | `GetArrestWarrant` / `IssueArrestWarrant` | `social.arrest_warrant(0)` |
| `social.poison(pid)` / `social.set_poison(pid,v)` | `GetPoisonLevel` / `SetPoisonLevel` | `social.poison(0)` |
| `social.drunk(pid)` / `social.set_drunk(pid,v)` | `GetDrunkLevel` / `SetDrunkLevel` | `social.drunk(0)` |
| `social.title_tier(tid)` | `GetTitleTier` | `social.title_tier(0)` |
| `social.evidence(pid)` | `GetEvidenceCount` | `social.evidence(0)` |
| `social.jail_time(pid)` / `social.set_jail_time(pid,v)` | `GetJailTime` / `SetJailTime` | `social.jail_time(0)` |
| `social.public_order(cid)` / `social.set_public_order(cid,v)` | `GetPublicOrder` / `SetPublicOrder` | `social.public_order(0)` |
| `social.city_favor(cid,pid)` / `social.set_city_favor(cid,pid,v)` | `GetCityFavor` / `SetCityFavor` | `social.city_favor(0,0)` |
| `social.spy_network(pid,cid)` | `GetSpyNetwork` | `social.spy_network(0,0)` |
| `social.age(pid)` / `social.set_age(pid,v)` | `GetPlayerAge` / `SetPlayerAge` | `social.age(0)` |
| `social.heir(pid)` / `social.set_heir(pid,v)` | `GetHeir` / `SetHeir` | `social.heir(0)` |
| `social.trait(pid,tid)` / `social.set_trait(pid,tid,v)` | `GetCharacterTrait` / `SetCharacterTrait` | `social.trait(0,1)` |
| `social.kidnap_chance(a,b)` / `social.ransom(pid)` / `social.set_ransom(pid,v)` | `GetKidnapChance` / `GetRansomPrice` / `SetRansomPrice` | `social.ransom(0)` |
| `social.papal_favor(pid)` / `social.set_papal_favor(pid,v)` | `GetPapalFavor` / `SetPapalFavor` | `social.papal_favor(0)` |
| `social.heretic(pid)` / `social.set_heretic(pid,v)` | `GetHereticSuspicion` / `SetHereticSuspicion` | `social.heretic(0)` |
| `social.trade_rep(pid,cid)` / `social.set_trade_rep(pid,cid,v)` | `GetTradeReputation` / `SetTradeReputation` | `social.trade_rep(0,0)` |
| `social.feast_cost(pid,ftype)` | `GetFeastCost` | `social.feast_cost(0,1)` |
| `social.favor_debt(a,b)` / `social.set_favor_debt(a,b,v)` | `GetFavorDebt` / `SetFavorDebt` | `social.favor_debt(0,1)` |
| `social.ambassador(pid)` / `social.set_ambassador(pid,v)` | `GetAmbassadorLevel` / `SetAmbassadorLevel` | `social.ambassador(0)` |
| `social.bounty(pid)` / `social.set_bounty(pid,v)` | `GetBountyPrice` / `SetBountyPrice` | `social.bounty(0)` |
| `social.charter_cost(gid)` | `GetGuildCharterCost` | `social.charter_cost(0)` |
| `social.xp(pid)` / `social.set_xp(pid,v)` | `GetPlayerExperience` / `SetPlayerExperience` | `social.xp(0)` |
| `social.church_donation(pid)` / `social.set_church_donation(pid,v)` | `GetChurchDonationTotal` / `SetChurchDonationTotal` | `social.church_donation(0)` |
| `social.noble_house(pid)` / `social.set_noble_house(pid,v)` | `GetNobleHouseRank` / `SetNobleHouseRank` | `social.noble_house(0)` |
| `social.gambling_debt(pid)` / `social.set_gambling_debt(pid,v)` | `GetGamblingDebt` / `SetGamblingDebt` | `social.gambling_debt(0)` |
| `social.imperial(pid)` / `social.set_imperial(pid,v)` | `GetImperialFavor` / `SetImperialFavor` | `social.imperial(0)` |
| `social.tavern(pid,cid)` | `GetTavernReputation` | `social.tavern(0,0)` |
| `social.monastery(pid,cid)` | `GetMonasteryInfluence` | `social.monastery(0,0)` |
| `social.title_rank(pid,tid)` | `GetTitleRank` | `social.title_rank(0,0)` |
| `social.nepotism(pid,oid)` / `social.set_nepotism(pid,oid,v)` | `GetNepotismLevel` / `SetNepotismLevel` | `social.nepotism(0,0)` |
| `social.bishop(pid,did)` | `GetBishopInfluence` | `social.bishop(0,0)` |
| `social.cathedral(pid,cid)` | `GetCathedralInfluence` | `social.cathedral(0,0)` |
| `social.alms(pid)` | `GetAlmsEffectiveness` | `social.alms(0)` |
| `social.indulgence_cost(pid,lvl)` | `GetIndulgenceCost` | `social.indulgence_cost(0,1)` |
| `social.dynasty_prestige_decay(pid)` | `GetDynastyPrestigeDecay` | `social.dynasty_prestige_decay(0)` |
| `social.sin(pid)` / `social.set_sin(pid,v)` | `GetSinLevel` / `SetSinLevel` | `social.sin(0)` |
| `social.confession_cost(pid,lvl)` | `GetConfessionCost` | `social.confession_cost(0,1)` |
| `social.excommunication(pid)` / `social.set_excommunication(pid,v)` | `GetExcommunicationState` / `SetExcommunicationState` | `social.excommunication(0)` |
| `social.guild_promotion_cost(gid,lvl)` | `GetGuildPromotionCost` | `social.guild_promotion_cost(0,1)` |
| `social.pilgrimage_cost(pid,ptype)` | `GetPilgrimageCost` | `social.pilgrimage_cost(0,0)` |
| `social.relic_value(rid)` | `GetRelicValue` | `social.relic_value(0)` |
| `social.crusade(pid,cid)` / `social.set_crusade(pid,cid,v)` | `GetCrusadeContribution` / `SetCrusadeContribution` | `social.crusade(0,0)` |
| `social.joust(pid,ftype)` | `GetJoustReward` | `social.joust(0,0)` |
| `social.tournament(pid,tid)` | `GetTournamentStanding` | `social.tournament(0,0)` |
| `social.inquisition(pid)` / `social.set_inquisition(pid,v)` | `GetInquisitionSuspicion` / `SetInquisitionSuspicion` | `social.inquisition(0)` |
| `social.cartel(pid,cid)` | `GetCartelInfluence` | `social.cartel(0,0)` |
| `social.fence_price(pid,gid)` | `GetFencePrice` | `social.fence_price(0,0)` |
| `social.jester(pid)` | `GetCourtJesterEffect` | `social.jester(0)` |
| `social.bard(pid,cid)` | `GetBardInfluence` | `social.bard(0,0)` |
| `social.dowry(pid,spouse)` | `GetDowryAmount` | `social.dowry(0,1)` |
| `social.wedding(pid,wtype)` | `GetWeddingCost` | `social.wedding(0,0)` |
| `social.patrician(pid,cid)` | `GetPatricianInfluence` | `social.patrician(0,0)` |
| `social.noble_auth(pid,cid)` | `GetNobleAuthority` | `social.noble_auth(0,0)` |
| `social.clergy(pid,cid)` | `GetClergyInfluence` | `social.clergy(0,0)` |
| `social.council_power(pid,cid)` | `GetCouncilVotePower` | `social.council_power(0,0)` |
| `social.court_intrigue(pid,cid)` | `GetCourtIntriguePower` | `social.court_intrigue(0,0)` |
| `social.church(pid,cid)` | `GetChurchInfluence` | `social.church(0,0)` |
| `social.noble_demands(pid,cid)` | `GetNobleDemands` | `social.noble_demands(0,0)` |
| `social.office_competition(cid,oid)` | `GetOfficeCompetition` | `social.office_competition(0,0)` |
| `social.chat(pid,text)` | `SendChatMessage` | `social.chat(0, "hi")` |
| `social.broadcast(id,payload)` | `BroadcastEvent` | `social.broadcast(1, "x")` |

## Auto Discover (`auto.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `auto.discover(keyword [,base,size,opts])` | Preset/finder → disasm → sig → probe | `auto.discover("gold")` |
| `auto.quick(addr, sigs [,name])` | Probe sigs at addr, optionally register | `auto.quick(0x401000, {"int()"})` |
| `auto.from_string(name, needle [,base,size [,sig]])` | Discover then `game.register(name)` | `auto.from_string("GetGold","Gold")` |

`auto.discover` prefers `presets.hunt` when `keyword` matches a preset key. Options: `{probe=true, register="int()", limit=1}`.

## Fuzz Helper (`fuzz.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `fuzz.int(name, lo, hi [,step])` | Try int range 0..10 | `fuzz.int("GetGold", 0, 10)` |
| `fuzz.ints(name, {{lo,hi,step},...})` | Cartesian ranges, cap 256 | `fuzz.ints("F", {{0,5},{0,1}})` |
| `fuzz.strings(name, {...})` | Try string args | `fuzz.strings("Msg", {"hi","Gold"})` |
| `fuzz.raw(addr_or_name, sig, {{...}})` | Low-level arg sets | `fuzz.raw(0x401000, "int(int)", {{0},{1}})` |

Uses `pcall` so a bad arg does not crash; when `addr` is a `game` name it routes via `game.call`.

## Nearby Finder (`near.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `near.around(addr, radius [,limit])` | Funcs within ±radius of addr | `near.around(0x401000, 0x1000, 5)` |
| `near.list` | Alias for `near.around` | `near.list(0x401000, 0x800, 10)` |

Enumerates `finder.prologues` in the window, dedups, sorts by distance.

## Stack Viewer (`stack.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `stack.capture([skip, n])` | Backtrace via `RtlCaptureStackBackTrace` | `stack.capture(0, 16)` |
| `stack.ebp_chain(ebp [,max])` | Walk EBP chain + ret addrs | `stack.ebp_chain(0x12FF00, 16)` |
| `stack.args(ebp, n)` | Dump n args at `[ebp+8]` | `stack.args(0x12FF00, 4)` |
| `stack.dump(addr, len)` | Hex around stack region | `stack.dump(0x12FF00, 64)` |

Complements `trace`: use it when patching or hooking to see *who called* and with what stack args.

## Function Catalog (`catalog.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `catalog.list()` | List curated function entries | `catalog.list()` |
| `catalog.find(needle)` | Search by name/desc/sig | `catalog.find("gold")` |
| `catalog.by_tag(tag)` | Filter by tag (economy, ui, unit…) | `catalog.by_tag("economy")` |
| `catalog.register_all([dry])` | Bulk register entries with verified addresses | `catalog.register_all()` |
| `catalog.hunt([tag, base, size])` | Run `auto.discover` for each catalog entry in tag | `catalog.hunt("economy")` |
| `catalog.export([path])` | Write catalog to standalone lua file | `catalog.export("my_catalog.lua")` |

Knowledge base separate from `gamecalls` runtime registry; seed addresses after confirming via `finder`/`scan`. `catalog.hunt` chains `auto.discover` per entry for one-call sweeps.

## UI Helper (`ui.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `ui.message(text)` | Show message (ShowMessage → ShowDialog fallback) | `ui.message("Hello")` |
| `ui.dialog(text [,buttons])` | Show dialog, returns choice | `ui.dialog("Attack?", 2)` |
| `ui.windows()` | Enumerate windows via `system.window_info` | `ui.windows()` |
| `ui.find(pattern)` | Filter windows by glob `*`/`?` | `ui.find("Europa*")` |

`ui.message`/`dialog` are `pcall`-wrapped `game.call`; a missing catalog entry prints a hint instead of crashing.

## Cheats (`cheat.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `cheat.gold(n)` | Set/add gold (tries `SetPlayerGold`/`AddGold` + player addr) | `cheat.gold(99999)` |
| `cheat.fame(n)` | `SetPlayerFame` | `cheat.fame(100)` |
| `cheat.faith(pid[,v])` / `cheat.prestige(pid[,v])` / `cheat.disease(pid[,v])` | Faith / prestige / disease via social | `cheat.faith(0, 50)` |
| `cheat.health(pid,hp)` | `SetPlayerHealth` or `unit.at(addr):set_health` | `cheat.health(0, 100)` |
| `cheat.time(h)` / `cheat.year(y)` | `SetTimeHours` / `SetYear` via world | `cheat.time(12)` |
| `cheat.speed(v)` / `cheat.difficulty(v)` | `SetGameSpeed` / `SetDifficulty` | `cheat.speed(2)` |
| `cheat.city_owner(cid,owner)` / `cheat.guard(cid[,n])` | `SetCityOwner` / `GuardCount` via world | `cheat.city_owner(0, 1)` |
| `cheat.office(cid,oid,pid)` / `cheat.guild_master(gid[,pid])` | `SetOfficeHolder` / `GuildMaster` via world/social | `cheat.office(0, 1, 0)` |
| `cheat.tax(cid,gid,rate)` | `SetTaxRate` via economy | `cheat.tax(0, 3, 5)` |
| `cheat.market(gid,cid,price)` | `SetMarketPrice` via economy | `cheat.market(3, 0, 1)` |
| `cheat.guild_balance(gid,n)` | `SetGuildBalance` via economy | `cheat.guild_balance(0, 5000)` |
| `cheat.quest_start(id,owner)` / `cheat.quest_done(id)` / `cheat.quest_fail(id)` | Quest start/complete/fail via quest | `cheat.quest_done(1)` |
| `cheat.stock(pid,sid[,n])` / `cheat.income(pid[,n])` | Stock / daily income via economy | `cheat.income(0, 999)` |
| `cheat.bribe(cid,oid[,price])` / `cheat.intrigue(pid,tid[,lvl])` / `cheat.title(pid,tid)` | Bribe / intrigue / title via economy/social | `cheat.bribe(0,1,500)` |
| `cheat.influence(pid,cid[,v])` / `cheat.title_cost(tid)` / `cheat.warehouse(bldg[,cap])` | Influence / title cost / warehouse capacity | `cheat.influence(0,0,50)` |
| `cheat.supply(cid,gid[,v])` / `cheat.demand(cid,gid[,v])` / `cheat.profit(a,b,good)` | Supply / demand / trade profit | `cheat.supply(0,3,500)` |
| `cheat.upkeep(bldg[,cost])` | Building upkeep (via Get/SetBuildingUpkeep) | `cheat.upkeep(bldg, 100)` |
| `cheat.debt(pid[,v])` / `cheat.bank(pid[,v])` / `cheat.loan(pid,loan[,v])` / `cheat.interest(cid[,v])` | Debt / bank / loan / interest via economy | `cheat.debt(0, 500)` |
| `cheat.cart_goods(cart,gid)` / `cheat.bribe_success(pid,cid,oid)` | Cart goods / bribe success | `cheat.cart_goods(cart,3)` |
| `cheat.tithe(cid[,v])` / `cheat.piety(pid[,v])` / `cheat.court_favor(pid,nid[,v])` | Tithe / piety / court favor via social | `cheat.tithe(0, 10)` |
| `cheat.dynasty_rep(did[,v])` / `cheat.family_wealth(fid[,v])` / `cheat.building_tax(bldg[,v])` / `cheat.worker_skill(wid,sid[,v])` | Dynasty rep / family wealth / building tax / worker skill | `cheat.dynasty_rep(0, 50)` |
| `cheat.court_level(pid,lvl[,v])` / `cheat.assassin(pid[,v])` / `cheat.warrant(pid)` / `cheat.verdict(tid[,v])` | Court level / assassin / warrant / verdict | `cheat.court_level(0,1,10)` |
| `cheat.poison(pid[,v])` / `cheat.drunk(pid[,v])` / `cheat.title_tier(tid)` / `cheat.evidence(pid)` | Poison / drunk / title tier / evidence | `cheat.poison(0, 50)` |
| `cheat.jail(pid[,v])` / `cheat.public_order(cid[,v])` / `cheat.city_favor(cid,pid[,v])` | Jail / public order / city favor | `cheat.jail(0, 0)` |
| `cheat.guild_fee(gid[,v])` / `cheat.office_term(cid,oid[,v])` | Guild fee / office term | `cheat.guild_fee(0, 100)` |
| `cheat.harvest(bldg,gid[,v])` / `cheat.servants(bldg)` / `cheat.slots(bldg)` | Harvest / servants / workshop slots | `cheat.harvest(bldg,3,50)` |
| `cheat.militia(cid[,v])` / `cheat.wall(cid[,v])` / `cheat.wage(bldg,wtype[,v])` | Militia / wall / wage | `cheat.militia(0, 100)` |
| `cheat.witnesses(tid)` / `cheat.spy_net(pid,cid)` | Witnesses / spy network | `cheat.witnesses(0)` |
| `cheat.age(pid[,v])` / `cheat.heir(pid[,v])` / `cheat.rent(bldg[,v])` / `cheat.defense(cid[,v])` | Age / heir / rent / defense | `cheat.age(0,30)` |
| `cheat.trait(pid,tid[,v])` / `cheat.kidnap(a,b)` / `cheat.ransom(pid[,v])` / `cheat.unrest(cid[,v])` / `cheat.security(bldg)` | Trait / kidnap / ransom / unrest / security | `cheat.trait(0,1,5)` |
| `cheat.honor(pid[,v])` / `cheat.bvalue(bldg)` / `cheat.prosperity(cid[,v])` / `cheat.salary(cid,oid[,v])` | Honor / bvalue / prosperity / salary | `cheat.honor(0, 10)` |
| `cheat.papal(pid[,v])` / `cheat.heretic(pid[,v])` / `cheat.guard_level(cart)` / `cheat.blessing(bldg[,v])` | Papal / heretic / guard_level / blessing | `cheat.papal(0, 10)` |
| `cheat.trade_rep(pid,cid[,v])` / `cheat.feast(pid,ftype)` / `cheat.favor_debt(a,b[,v])` | Trade rep / feast / favor debt | `cheat.trade_rep(0,0,10)` |
| `cheat.ambassador(pid[,v])` / `cheat.festival(cid)` | Ambassador / festival | `cheat.ambassador(0, 5)` |
| `cheat.food(cid[,v])` / `cheat.accident(bldg[,v])` / `cheat.fire_risk(bldg)` / `cheat.bounty(pid[,v])` / `cheat.charter(gid)` | Food / accident / fire_risk / bounty / charter | `cheat.food(0, 100)` |
| `cheat.corruption(cid[,v])` / `cheat.bribe_cooldown(pid,cid,oid)` / `cheat.xp(pid[,v])` / `cheat.donation(pid[,v])` / `cheat.strikes(bldg)` | Corruption / bribe_cooldown / xp / donation / strikes | `cheat.corruption(0, 10)` |
| `cheat.bandit(cid[,v])` / `cheat.spy_suspicion(pid,cid[,v])` / `cheat.prod_bonus(bldg,gid[,v])` / `cheat.noble_house(pid[,v])` | Bandit / spy_suspicion / prod_bonus / noble_house | `cheat.bandit(0, 5)` |
| `cheat.route_profit(a,b,g)` / `cheat.caravan(cart)` / `cheat.nepotism(pid,oid[,v])` / `cheat.bishop(pid,did)` | Route_profit / caravan / nepotism / bishop | `cheat.route_profit(0,0,3)` |
| `cheat.btax(bldg[,v])` / `cheat.road(cid)` | Btax / road | `cheat.btax(bldg, 5)` |
| `cheat.toll(cid,rid[,v])` / `cheat.toll_gates(cid[,v])` / `cheat.escort(cid,lvl)` | Toll / gates / escort via world | `cheat.toll(0,0,100)` |
| `cheat.rep_decay(pid,fid[,v])` / `cheat.banquet(t)` | Rep decay / banquet bonus via social | `cheat.rep_decay(0,0,5)` |
| `cheat.road_upkeep(cid,rid)` / `cheat.stalls(cid)` / `cheat.harbor_level(cid[,v])` | Road upkeep / stalls / harbor via world | `cheat.harbor_level(0,2)` |
| `cheat.cathedral(pid,cid)` / `cheat.alms(pid)` / `cheat.indulgence(pid,lvl)` | Cathedral / alms / indulgence via social | `cheat.cathedral(0,0)` |
| `cheat.prestige_decay(pid)` | Dynasty prestige decay via social | `cheat.prestige_decay(0)` |
| `cheat.sin(pid[,v])` / `cheat.confession(pid,lvl)` / `cheat.excommunication(pid[,v])` | Sin / confession / excommunication via social | `cheat.sin(0, 10)` |
| `cheat.promotion_cost(gid,lvl)` / `cheat.upgrade_cost(bldg,uid)` / `cheat.tax_income(cid)` | Guild promo / workshop upgrade / tax income | `cheat.tax_income(0)` |
| `cheat.university(cid[,v])` / `cheat.guard_morale(cid[,v])` | University / guard morale via world | `cheat.university(0,1)` |
| `cheat.pilgrimage(pid,t)` / `cheat.relic(rid)` / `cheat.crusade(pid,cid[,v])` | Pilgrimage / relic / crusade via social | `cheat.crusade(0,0,100)` |
| `cheat.joust(pid,t)` / `cheat.tournament(pid,tid)` / `cheat.inquisition(pid[,v])` | Joust / tournament / inquisition via social | `cheat.joust(0,0)` |
| `cheat.brewery(bldg,gid[,v])` / `cheat.militia_upkeep(cid)` / `cheat.smuggler(cid,gid)` | Brewery / militia upkeep / smuggler via building/world | `cheat.brewery(bldg,0,10)` |
| `cheat.mill(bldg,gid[,v])` / `cheat.harbor_fee(cid,gid)` / `cheat.festival_cost(cid,ftype)` | Mill / harbor fee / festival cost | `cheat.mill(bldg,0,10)` |
| `cheat.cartel(pid,cid)` / `cheat.fence(pid,gid)` / `cheat.jester(pid)` / `cheat.bard(pid,cid)` | Cartel / fence / jester / bard via social | `cheat.cartel(0,0)` |
| `cheat.dowry(pid,s)` / `cheat.wedding(pid,t)` / `cheat.patrician(pid,cid)` | Dowry / wedding / patrician via social | `cheat.dowry(0,1)` |
| `cheat.stall_rent(cid,t)` / `cheat.church_tax(cid[,v])` | Stall rent / church tax via world | `cheat.stall_rent(0,0)` |
| `cheat.tannery(bldg,gid[,v])` / `cheat.weaver(bldg,gid[,v])` / `cheat.mint(bldg)` / `cheat.herb(bldg,gid)` | Tannery / weaver / mint / herb via building | `cheat.tannery(bldg,0,10)` |
| `cheat.vineyard(bldg,gid[,v])` / `cheat.pottery(bldg,gid[,v])` / `cheat.tailor(bldg,gid[,v])` | Vineyard / pottery / tailor via building | `cheat.vineyard(bldg,0,10)` |
| `cheat.fishing(bldg,gid)` / `cheat.orchard(bldg,gid)` | Fishing / orchard via building | `cheat.fishing(bldg,0)` |
| `cheat.carpenter(bldg,gid[,v])` / `cheat.ropemaker(bldg,gid[,v])` | Carpenter / ropemaking via building | `cheat.carpenter(bldg,0,10)` |
| `cheat.apiary(bldg,gid)` / `cheat.hunting(bldg,gid)` / `cheat.alchemist(bldg,gid[,v])` | Apiary / hunting / alchemist via building | `cheat.apiary(bldg,0)` |
| `cheat.glassworks(bldg,gid[,v])` / `cheat.mason(bldg,gid[,v])` / `cheat.distillery(bldg,gid[,v])` | Glassworks / mason / distillery via building | `cheat.glassworks(bldg,0,10)` |
| `cheat.pasture(bldg,gid)` / `cheat.quarry(bldg,gid)` | Pasture / quarry via building | `cheat.pasture(bldg,0)` |
| `cheat.forge(bldg,gid[,v])` / `cheat.sawmill(bldg,gid[,v])` | Forge / sawmill via building | `cheat.forge(bldg,0,10)` |
| `cheat.kiln(bldg,gid[,v])` / `cheat.foundry(bldg,gid[,v])` | Kiln / foundry via building | `cheat.kiln(bldg,0,10)` |
| `cheat.market_fee(cid[,v])` | Market fee via world | `cheat.market_fee(0,100)` |
| `cheat.guild_levy(gid,cid[,v])` / `cheat.watch_strength(cid[,v])` | Guild levy / watch via economy/world | `cheat.guild_levy(0,0,100)` |
| `cheat.noble_auth(pid,cid)` / `cheat.debasement(cid[,v])` / `cheat.regulation(cid)` | Noble auth / debasement / regulation | `cheat.noble_auth(0,0)` |
| `cheat.siege(cid[,v])` / `cheat.garrison(cid[,v])` / `cheat.merc_cost(cid,t)` | Siege / garrison / merc cost via world | `cheat.siege(0,50)` |
| `cheat.hospital(bldg)` / `cheat.clergy(pid,cid)` / `cheat.council_power(pid,cid)` | Hospital / clergy / council via building/social | `cheat.hospital(bldg)` |
| `cheat.patrol(cid[,v])` / `cheat.bandit_risk(cid,rid[,v])` | Patrol / bandit risk via world | `cheat.patrol(0,10)` |
| `cheat.tavern_brawl(cid)` / `cheat.guild_hall(gid,cid[,v])` | Tavern brawl / guild hall via world | `cheat.tavern_brawl(0)` |
| `cheat.court_intrigue(pid,cid)` | Court intrigue via social | `cheat.court_intrigue(0,0)` |
| `cheat.tavern_income(bldg)` | Tavern income via building | `cheat.tavern_income(bldg)` |
| `cheat.church_influence(pid,cid)` / `cheat.noble_demands(pid,cid)` | Church / noble demands via social | `cheat.church_influence(0,0)` |
| `cheat.office_comp(cid,oid)` / `cheat.tax_collector(cid[,v])` / `cheat.wall_repair(cid)` | Office comp / tax collector / wall repair | `cheat.office_comp(0,0)` |
| `cheat.guild_tax(gid,cid)` | Guild tax rate via economy | `cheat.guild_tax(0,0)` |
| `cheat.town_hall(cid[,v])` / `cheat.church_level(cid[,v])` | Town hall / church level via world | `cheat.town_hall(0,2)` |
| `cheat.library(cid[,v])` / `cheat.school(cid[,v])` | Library / school via world | `cheat.library(0,2)` |
| `cheat.dock(cid[,v])` / `cheat.armory(cid[,v])` | Dock / armory via world | `cheat.dock(0,2)` |
| `cheat.warehouse_level(cid[,v])` / `cheat.mine(cid[,v])` | Warehouse / mine via world | `cheat.warehouse_level(0,2)` |
| `cheat.garrison_level(cid[,v])` / `cheat.bathhouse_level(cid[,v])` | Garrison / bathhouse via world | `cheat.garrison_level(0,2)` |
| `cheat.harbor_master(cid[,v])` / `cheat.guardhouse(cid[,v])` | Harbor master / guardhouse via world | `cheat.harbor_master(0,2)` |
| `cheat.courthouse(cid[,v])` / `cheat.univ_hall(cid[,v])` | Courthouse / univ hall via world | `cheat.courthouse(0,2)` |
| `cheat.castle(cid[,v])` / `cheat.cathedral_level(cid[,v])` | Castle / cathedral via world | `cheat.castle(0,2)` |
| `cheat.monastery_level(cid[,v])` / `cheat.harbor_level2(cid[,v])` | Monastery / harbor v2 via world | `cheat.monastery_level(0,2)` |
| `cheat.barracks(cid[,v])` / `cheat.stables(cid[,v])` | Barracks / stables via world | `cheat.barracks(0,2)` |
| `cheat.gates(cid[,v])` / `cheat.sentry(cid[,v])` | Gates / sentry via world | `cheat.gates(0,2)` |
| `cheat.well(cid[,v])` / `cheat.bridge(cid[,v])` | Well / bridge via world | `cheat.well(0,2)` |
| `cheat.forum(cid[,v])` / `cheat.granary_level(cid[,v])` | Forum / granary via world | `cheat.forum(0,2)` |
| `cheat.prison(cid[,v])` / `cheat.harbor_dock(cid[,v])` | Prison / harbor dock via world | `cheat.prison(0,2)` |
| `cheat.guild_house2(cid[,v])` / `cheat.house(cid[,v])` | Guild house / house via world | `cheat.guild_house2(0,2)` |
| `cheat.chapel(cid[,v])` / `cheat.hospital_level(cid[,v])` | Chapel / hospital via world | `cheat.chapel(0,2)` |
| `cheat.brothel(cid[,v])` / `cheat.harbor_walls(cid[,v])` | Brothel / harbor walls via world | `cheat.brothel(0,2)` |
| `cheat.schoolhouse(cid[,v])` / `cheat.library_hall(cid[,v])` | Schoolhouse / library hall via world | `cheat.schoolhouse(0,2)` |
| `cheat.barber_level(cid[,v])` / `cheat.contor(cid[,v])` | Barber / contor via world | `cheat.barber_level(0,2)` |
| `cheat.dice_house(cid[,v])` / `cheat.thieves(cid[,v])` | Dice house / thieves via world | `cheat.dice_house(0,2)` |
| `cheat.ropemaker_workshop(cid[,v])` / `cheat.tannery(cid[,v])` | Ropemaker workshop / tannery via world | `cheat.ropemaker_workshop(0,2)` |
| `cheat.weaving_mill(cid[,v])` / `cheat.mint(cid[,v])` | Weaving mill / mint via world | `cheat.weaving_mill(0,2)` |
| `cheat.herb_garden(cid[,v])` / `cheat.vineyard(cid[,v])` | Herb garden / vineyard via world | `cheat.herb_garden(0,2)` |
| `cheat.apothecary_level(cid[,v])` / `cheat.goldsmith_level(cid[,v])` | Apothecary / goldsmith level via world | `cheat.apothecary_level(0,2)` |
| `cheat.soapmaker_level(cid[,v])` / `cheat.candlemaker_level(cid[,v])` | Soapmaker / candlemaker level via world | `cheat.soapmaker_level(0,2)` |
| `cheat.papermill_level(cid[,v])` / `cheat.printing_house(cid[,v])` | Papermill / printing house via world | `cheat.papermill_level(0,2)` |
| `cheat.toolmaker_level(cid[,v])` / `cheat.charcoal_level(cid[,v])` | Toolmaker / charcoal via world | `cheat.toolmaker_level(0,2)` |
| `cheat.furrier_level(cid[,v])` / `cheat.dyer_level(cid[,v])` | Furrier / dyer via world | `cheat.furrier_level(0,2)` |
| `cheat.saddler_level(cid[,v])` / `cheat.armorer_level(cid[,v])` | Saddler / armorer via world | `cheat.saddler_level(0,2)` |
| `cheat.bowyer_level(cid[,v])` / `cheat.cartwright_level(cid[,v])` | Bowyer / cartwright via world | `cheat.bowyer_level(0,2)` |
| `cheat.carpenter_level(cid[,v])` / `cheat.ropemaker_level(cid[,v])` | Carpenter / ropemaking via world | `cheat.carpenter_level(0,2)` |
| `cheat.cooper_level(cid[,v])` / `cheat.spinner_level(cid[,v])` | Cooper / spinner via world | `cheat.cooper_level(0,2)` |
| `cheat.turner_level(cid[,v])` / `cheat.stonecutter_level(cid[,v])` | Turner / stonecutter via world | `cheat.turner_level(0,2)` |
| `cheat.cobbler_level(cid[,v])` / `cheat.butcher_level(cid[,v])` | Cobbler / butcher via world | `cheat.cobbler_level(0,2)` |
| `cheat.baker_level(cid[,v])` / `cheat.shepherd_level(cid[,v])` | Baker / shepherd via world | `cheat.baker_level(0,2)` |
| `cheat.dairy_level(cid[,v])` / `cheat.brewmaster_level(cid[,v])` | Dairy / brewmaster via world | `cheat.dairy_level(0,2)` |
| `cheat.miller_level(cid[,v])` / `cheat.fishery_level(cid[,v])` | Miller / fishery via world | `cheat.miller_level(0,2)` |
| `cheat.chandler_level(cid[,v])` / `cheat.goldbeater_level(cid[,v])` | Chandler / goldbeater via world | `cheat.chandler_level(0,2)` |
| `cheat.potter_level(cid[,v])` / `cheat.fowler_level(cid[,v])` | Potter / fowler via world | `cheat.potter_level(0,2)` |
| `cheat.vintner_level(cid[,v])` / `cheat.distiller_level(cid[,v])` | Vintner / distiller via world | `cheat.vintner_level(0,2)` |
| `cheat.cook_level(cid[,v])` / `cheat.brickmaker_level(cid[,v])` | Cook / brickmaker via world | `cheat.cook_level(0,2)` |
| `cheat.tavern_level2(cid[,v])` / `cheat.mill_level(cid[,v])` | Tavern v2 / mill via world | `cheat.tavern_level2(0,2)` |
| `cheat.brewery_tavern(cid[,v])` / `cheat.smith_level(cid[,v])` | Brewery tavern / smith via world | `cheat.brewery_tavern(0,2)` |
| `cheat.carpenters(cid[,v])` / `cheat.tailor_workshop(cid[,v])` | Carpenters / tailor workshop via world | `cheat.carpenters(0,2)` |
| `cheat.joiner_workshop(cid[,v])` / `cheat.carter_workshop(cid[,v])` | Joiner / carter workshop via world | `cheat.joiner_workshop(0,2)` |
| `cheat.mining_workshop(cid[,v])` / `cheat.logging_workshop(cid[,v])` | Mining / logging workshop via world | `cheat.mining_workshop(0,2)` |
| `cheat.inn_level(cid[,v])` / `cheat.robber_camp(cid[,v])` | Inn / robber camp via world | `cheat.inn_level(0,2)` |
| `cheat.joiner_ws2(cid[,v])` / `cheat.carter_ws2(cid[,v])` | Joiner ws2 / carter ws2 via world | `cheat.joiner_ws2(0,2)` |
| `cheat.toll_gate_level(cid[,v])` / `cheat.road_level(cid[,v])` | Toll gate / road level via world | `cheat.toll_gate_level(0,2)` |
| `cheat.toll_gate_tax(cid[,v])` / `cheat.bridge_cost(cid)` | Toll gate tax / bridge cost via world | `cheat.toll_gate_tax(0,2)` |
| `cheat.dock_tax(cid[,v])` / `cheat.harbor_walls_tax(cid[,v])` | Dock / harbor walls tax via world | `cheat.dock_tax(0,2)` |
| `cheat.forum_tax(cid[,v])` / `cheat.granary_tax(cid[,v])` | Forum / granary tax via world | `cheat.forum_tax(0,2)` |
| `cheat.guild_house_tax(cid[,v])` / `cheat.house_tax(cid[,v])` | Guild house / house tax via world | `cheat.guild_house_tax(0,2)` |
| `cheat.chapel_tax(cid[,v])` / `cheat.hospital_tax(cid[,v])` | Chapel / hospital tax via world | `cheat.chapel_tax(0,2)` |
| `cheat.harbor_walls2(cid[,v])` / `cheat.schoolhouse2(cid[,v])` | Harbor walls2 / schoolhouse2 via world | `cheat.harbor_walls2(0,2)` |
| `cheat.library_hall2(cid[,v])` / `cheat.brothel_tax(cid[,v])` | Library hall2 / brothel tax via world | `cheat.library_hall2(0,2)` |
| `cheat.harbor_walls_tax2(cid[,v])` / `cheat.schoolhouse_tax(cid[,v])` | Harbor walls tax2 / schoolhouse tax via world | `cheat.harbor_walls_tax2(0,2)` |
| `cheat.library_hall_tax(cid[,v])` / `cheat.barber_tax(cid[,v])` | Library hall tax / barber tax via world | `cheat.library_hall_tax(0,2)` |
| `cheat.schoolhouse_tax2(cid[,v])` / `cheat.library_hall_tax2(cid[,v])` | Schoolhouse tax2 / library hall tax2 via world | `cheat.schoolhouse_tax2(0,2)` |
| `cheat.brothel_tax2(cid[,v])` / `cheat.contor_tax2(cid[,v])` | Brothel tax2 / contor tax2 via world | `cheat.brothel_tax2(0,2)` |
| `cheat.dice_house_tax2(cid[,v])` / `cheat.thieves_guild_tax2(cid[,v])` | Dice house tax2 / thieves guild tax2 via world | `cheat.dice_house_tax2(0,2)` |
| `cheat.harbor_walls_tax4(cid[,v])` / `cheat.ropemaker_ws_tax(cid[,v])` | Harbor walls tax4 / ropemaking workshop tax via world | `cheat.harbor_walls_tax4(0,2)` |
| `cheat.tannery_tax(cid[,v])` / `cheat.weaving_tax(cid[,v])` | Tannery / weaving tax via world | `cheat.tannery_tax(0,2)` |
| `cheat.mint_tax(cid[,v])` / `cheat.herb_garden_tax(cid[,v])` | Mint / herb garden tax via world | `cheat.mint_tax(0,2)` |
| `cheat.vineyard_tax(cid[,v])` / `cheat.pottery_tax(cid[,v])` | Vineyard / pottery tax via world | `cheat.vineyard_tax(0,2)` |
| `cheat.tailor_tax(cid[,v])` / `cheat.tavern_tax(cid[,v])` | Tailor / tavern tax via world | `cheat.tailor_tax(0,2)` |
| `cheat.bathhouse_tax(cid[,v])` / `cheat.church_level_tax(cid[,v])` | Bathhouse / church level tax via world | `cheat.bathhouse_tax(0,2)` |
| `cheat.contor_level_tax(cid[,v])` / `cheat.dice_house_level_tax(cid[,v])` | Contor / dice house level tax via world | `cheat.contor_level_tax(0,2)` |
| `cheat.thieves_guild_level_tax(cid[,v])` / `cheat.ropemaker_level_tax(cid[,v])` | Thieves guild level / ropemaking level tax via world | `cheat.thieves_guild_level_tax(0,2)` |
| `cheat.tannery_level_tax(cid[,v])` / `cheat.weaving_level_tax(cid[,v])` | Tannery / weaving level tax via world | `cheat.tannery_level_tax(0,2)` |
| `cheat.mint_level_tax(cid[,v])` / `cheat.herb_garden_level_tax(cid[,v])` | Mint level / herb garden level tax via world | `cheat.mint_level_tax(0,2)` |
| `cheat.vineyard_level_tax(cid[,v])` / `cheat.pottery_level_tax(cid[,v])` | Vineyard / pottery level tax via world | `cheat.vineyard_level_tax(0,2)` |
| `cheat.tailor_level_tax(cid[,v])` / `cheat.tavern_level_tax(cid[,v])` | Tailor level / tavern level tax via world | `cheat.tailor_level_tax(0,2)` |
| `cheat.apothecary_level_tax(cid[,v])` / `cheat.goldsmith_level_tax(cid[,v])` | Apothecary / goldsmith level tax via world | `cheat.apothecary_level_tax(0,2)` |
| `cheat.jeweler_level_tax(cid[,v])` / `cheat.perfumer_level_tax(cid[,v])` | Jeweler / perfumer level tax via world | `cheat.jeweler_level_tax(0,2)` |
| `cheat.soapmaker_level_tax(cid[,v])` / `cheat.candlemaker_level_tax(cid[,v])` | Soapmaker / candlemaker level tax via world | `cheat.soapmaker_level_tax(0,2)` |
| `cheat.papermill_level_tax(cid[,v])` / `cheat.printing_level_tax(cid[,v])` | Papermill / printing house level tax via world | `cheat.papermill_level_tax(0,2)` |
| `cheat.toolmaker_level_tax(cid[,v])` / `cheat.charcoal_level_tax(cid[,v])` | Toolmaker / charcoal burner level tax via world | `cheat.toolmaker_level_tax(0,2)` |
| `cheat.furrier_level_tax(cid[,v])` / `cheat.dyer_level_tax(cid[,v])` | Furrier / dyer level tax via world | `cheat.furrier_level_tax(0,2)` |
| `cheat.saddler_level_tax(cid[,v])` / `cheat.armorer_level_tax(cid[,v])` | Saddler / armorer level tax via world | `cheat.saddler_level_tax(0,2)` |
| `cheat.bowyer_level_tax(cid[,v])` / `cheat.cartwright_level_tax(cid[,v])` | Bowyer / cartwright level tax via world | `cheat.bowyer_level_tax(0,2)` |
| `cheat.carpenter_level_tax(cid[,v])` / `cheat.ropemaker_level_tax(cid[,v])` | Carpenter / ropemaker level tax via world | `cheat.carpenter_level_tax(0,2)` |
| `cheat.cooper_level_tax(cid[,v])` / `cheat.spinner_level_tax(cid[,v])` | Cooper / spinner level tax via world | `cheat.cooper_level_tax(0,2)` |
| `cheat.turner_level_tax(cid[,v])` / `cheat.stonecutter_level_tax(cid[,v])` | Turner / stonecutter level tax via world | `cheat.turner_level_tax(0,2)` |
| `cheat.cobbler_level_tax(cid[,v])` / `cheat.butcher_level_tax(cid[,v])` | Cobbler / butcher level tax via world | `cheat.cobbler_level_tax(0,2)` |
| `cheat.baker_level_tax(cid[,v])` / `cheat.shepherd_level_tax(cid[,v])` | Baker / shepherd level tax via world | `cheat.baker_level_tax(0,2)` |
| `cheat.dairy_level_tax(cid[,v])` / `cheat.brewmaster_level_tax(cid[,v])` | Dairy / brewmaster level tax via world | `cheat.dairy_level_tax(0,2)` |
| `cheat.miller_level_tax(cid[,v])` / `cheat.fishery_level_tax(cid[,v])` | Miller / fishery level tax via world | `cheat.miller_level_tax(0,2)` |
| `cheat.chandler_level_tax(cid[,v])` / `cheat.goldbeater_level_tax(cid[,v])` | Chandler / goldbeater level tax via world | `cheat.chandler_level_tax(0,2)` |
| `cheat.potter_level_tax(cid[,v])` / `cheat.fowler_level_tax(cid[,v])` | Potter / fowler level tax via world | `cheat.potter_level_tax(0,2)` |
| `cheat.vintner_level_tax(cid[,v])` / `cheat.distiller_level_tax(cid[,v])` | Vintner / distiller level tax via world | `cheat.vintner_level_tax(0,2)` |
| `cheat.cook_level_tax(cid[,v])` / `cheat.brickmaker_level_tax(cid[,v])` | Cook / brickmaker level tax via world | `cheat.cook_level_tax(0,2)` |
| `cheat.bathhouse_level_tax(cid[,v])` / `cheat.barracks_level_tax(cid[,v])` | Bathhouse / barracks level tax via world | `cheat.bathhouse_level_tax(0,2)` |
| `cheat.school_level_tax(cid[,v])` / `cheat.library_level_tax(cid[,v])` | School / library level tax via world | `cheat.school_level_tax(0,2)` |
| `cheat.mine_level_tax(cid[,v])` / `cheat.warehouse_level_tax(cid[,v])` | Mine / warehouse level tax via world | `cheat.mine_level_tax(0,2)` |
| `cheat.garrison_level_tax(cid[,v])` / `cheat.monastery_level_tax(cid[,v])` | Garrison / monastery level tax via world | `cheat.garrison_level_tax(0,2)` |
| `cheat.cathedral_level_tax(cid[,v])` / `cheat.town_hall_level_tax(cid[,v])` | Cathedral / town hall level tax via world | `cheat.cathedral_level_tax(0,2)` |
| `cheat.market_level_tax(cid[,v])` / `cheat.harbor_level_tax(cid[,v])` | Market / harbor level tax via world | `cheat.market_level_tax(0,2)` |
| `cheat.guardhouse_level_tax(cid[,v])` / `cheat.courthouse_level_tax(cid[,v])` | Guardhouse / courthouse level tax via world | `cheat.guardhouse_level_tax(0,2)` |
| `cheat.univ_hall_level_tax(cid[,v])` / `cheat.castle_level_tax(cid[,v])` | University hall / castle level tax via world | `cheat.univ_hall_level_tax(0,2)` |
| `cheat.barracks2_level_tax(cid[,v])` / `cheat.stables_level_tax(cid[,v])` | Barracks2 / stables level tax via world | `cheat.barracks2_level_tax(0,2)` |
| `cheat.gates_level_tax(cid[,v])` / `cheat.sentry_level_tax(cid[,v])` | Gates / sentry tower level tax via world | `cheat.gates_level_tax(0,2)` |
| `cheat.well_level_tax(cid[,v])` / `cheat.bridge_level_tax(cid[,v])` | Well / bridge level tax via world | `cheat.well_level_tax(0,2)` |
| `cheat.wall_level_tax(cid[,v])` / `cheat.tower_level_tax(cid[,v])` | Wall / tower level tax via world | `cheat.wall_level_tax(0,2)` |
| `cheat.forum_level_tax(cid[,v])` / `cheat.granary_level_tax(cid[,v])` | Forum / granary level tax via world | `cheat.forum_level_tax(0,2)` |
| `cheat.prison_level_tax(cid[,v])` / `cheat.harbor_dock_level_tax(cid[,v])` | Prison / harbor dock level tax via world | `cheat.prison_level_tax(0,2)` |
| `cheat.guild_house_level_tax(cid[,v])` / `cheat.house_level_tax(cid[,v])` | Guild house / house level tax via world | `cheat.guild_house_level_tax(0,2)` |
| `cheat.chapel_level_tax(cid[,v])` / `cheat.hospital_level_tax(cid[,v])` | Chapel / hospital level tax via world | `cheat.chapel_level_tax(0,2)` |
| `cheat.brothel_level_tax(cid[,v])` / `cheat.university_level_tax(cid[,v])` | Brothel / university level tax via world | `cheat.brothel_level_tax(0,2)` |
| `cheat.harbor_walls_level_tax(cid[,v])` / `cheat.schoolhouse_level_tax(cid[,v])` | Harbor walls / schoolhouse level tax via world | `cheat.harbor_walls_level_tax(0,2)` |
| `cheat.library_hall_level_tax(cid[,v])` / `cheat.barber_level_tax(cid[,v])` | Library hall / barber level tax via world | `cheat.library_hall_level_tax(0,2)` |
| `cheat.contor2_level_tax(cid[,v])` / `cheat.dice_house2_level_tax(cid[,v])` | Contor2 / dice house2 level tax via world | `cheat.contor2_level_tax(0,2)` |
| `cheat.thieves2_level_tax(cid[,v])` / `cheat.ropemaker_ws2_level_tax(cid[,v])` | Thieves2 / ropemaking workshop2 level tax via world | `cheat.thieves2_level_tax(0,2)` |
| `cheat.tannery2_level_tax(cid[,v])` / `cheat.weaving2_level_tax(cid[,v])` | Tannery2 / weaving mill2 level tax via world | `cheat.tannery2_level_tax(0,2)` |
| `cheat.mint2_level_tax(cid[,v])` / `cheat.herb_garden2_level_tax(cid[,v])` | Mint2 / herb garden2 level tax via world | `cheat.mint2_level_tax(0,2)` |
| `cheat.vineyard2_level_tax(cid[,v])` / `cheat.pottery2_level_tax(cid[,v])` | Vineyard2 / pottery2 level tax via world | `cheat.vineyard2_level_tax(0,2)` |
| `cheat.tailor2_level_tax(cid[,v])` / `cheat.tavern2_level_tax(cid[,v])` | Tailor2 / tavern2 level tax via world | `cheat.tailor2_level_tax(0,2)` |
| `cheat.apothecary2_level_tax(cid[,v])` / `cheat.goldsmith2_level_tax(cid[,v])` | Apothecary2 / goldsmith2 level tax via world | `cheat.apothecary2_level_tax(0,2)` |
| `cheat.jeweler2_level_tax(cid[,v])` / `cheat.perfumer2_level_tax(cid[,v])` | Jeweler2 / perfumer2 level tax via world | `cheat.jeweler2_level_tax(0,2)` |
| `cheat.soapmaker2_level_tax(cid[,v])` / `cheat.candlemaker2_level_tax(cid[,v])` | Soapmaker2 / candlemaker2 level tax via world | `cheat.soapmaker2_level_tax(0,2)` |
| `cheat.papermill2_level_tax(cid[,v])` / `cheat.printing2_level_tax(cid[,v])` | Papermill2 / printing house2 level tax via world | `cheat.papermill2_level_tax(0,2)` |
| `cheat.toolmaker2_level_tax(cid[,v])` / `cheat.charcoal2_level_tax(cid[,v])` | Toolmaker2 / charcoal burner2 level tax via world | `cheat.toolmaker2_level_tax(0,2)` |
| `cheat.furrier2_level_tax(cid[,v])` / `cheat.dyer2_level_tax(cid[,v])` | Furrier2 / dyer2 level tax via world | `cheat.furrier2_level_tax(0,2)` |
| `cheat.saddler2_level_tax(cid[,v])` / `cheat.armorer2_level_tax(cid[,v])` | Saddler2 / armorer2 level tax via world | `cheat.saddler2_level_tax(0,2)` |
| `cheat.bowyer2_level_tax(cid[,v])` / `cheat.cartwright2_level_tax(cid[,v])` | Bowyer2 / cartwright2 level tax via world | `cheat.bowyer2_level_tax(0,2)` |
| `cheat.carpenter2_level_tax(cid[,v])` / `cheat.ropemaker2_level_tax(cid[,v])` | Carpenter2 / ropemaker2 level tax via world | `cheat.carpenter2_level_tax(0,2)` |
| `cheat.cooper2_level_tax(cid[,v])` / `cheat.spinner2_level_tax(cid[,v])` | Cooper2 / spinner2 level tax via world | `cheat.cooper2_level_tax(0,2)` |
| `cheat.turner2_level_tax(cid[,v])` / `cheat.stonecutter2_level_tax(cid[,v])` | Turner2 / stonecutter2 level tax via world | `cheat.turner2_level_tax(0,2)` |
| `cheat.cobbler2_level_tax(cid[,v])` / `cheat.butcher2_level_tax(cid[,v])` | Cobbler2 / butcher2 level tax via world | `cheat.cobbler2_level_tax(0,2)` |
| `cheat.baker2_level_tax(cid[,v])` / `cheat.shepherd2_level_tax(cid[,v])` | Baker2 / shepherd2 level tax via world | `cheat.baker2_level_tax(0,2)` |
| `cheat.dairy2_level_tax(cid[,v])` / `cheat.brewmaster2_level_tax(cid[,v])` | Dairy2 / brewmaster2 level tax via world | `cheat.dairy2_level_tax(0,2)` |
| `cheat.miller2_level_tax(cid[,v])` / `cheat.fishery2_level_tax(cid[,v])` | Miller2 / fishery2 level tax via world | `cheat.miller2_level_tax(0,2)` |
| `cheat.chandler2_level_tax(cid[,v])` / `cheat.goldbeater2_level_tax(cid[,v])` | Chandler2 / goldbeater2 level tax via world | `cheat.chandler2_level_tax(0,2)` |
| `cheat.potter2_level_tax(cid[,v])` / `cheat.fowler2_level_tax(cid[,v])` | Potter2 / fowler2 level tax via world | `cheat.potter2_level_tax(0,2)` |
| `cheat.vintner2_level_tax(cid[,v])` / `cheat.distiller2_level_tax(cid[,v])` | Vintner2 / distiller2 level tax via world | `cheat.vintner2_level_tax(0,2)` |
| `cheat.cook2_level_tax(cid[,v])` / `cheat.brickmaker2_level_tax(cid[,v])` | Cook2 / brickmaker2 level tax via world | `cheat.cook2_level_tax(0,2)` |
| `cheat.bathhouse2_level_tax(cid[,v])` / `cheat.barracks3_level_tax(cid[,v])` | Bathhouse2 / barracks3 level tax via world | `cheat.bathhouse2_level_tax(0,2)` |
| `cheat.school2_level_tax(cid[,v])` / `cheat.library2_level_tax(cid[,v])` | School2 / library2 level tax via world | `cheat.school2_level_tax(0,2)` |
| `cheat.mine2_level_tax(cid[,v])` / `cheat.warehouse2_level_tax(cid[,v])` | Mine2 / warehouse2 level tax via world | `cheat.mine2_level_tax(0,2)` |
| `cheat.garrison2_level_tax(cid[,v])` / `cheat.monastery2_level_tax(cid[,v])` | Garrison2 / monastery2 level tax via world | `cheat.garrison2_level_tax(0,2)` |
| `cheat.cathedral2_level_tax(cid[,v])` / `cheat.town_hall2_level_tax(cid[,v])` | Cathedral2 / town hall2 level tax via world | `cheat.cathedral2_level_tax(0,2)` |
| `cheat.market2_level_tax(cid[,v])` / `cheat.harbor2_level_tax(cid[,v])` | Market2 / harbor2 level tax via world | `cheat.market2_level_tax(0,2)` |
| `cheat.guardhouse2_level_tax(cid[,v])` / `cheat.courthouse2_level_tax(cid[,v])` | Guardhouse2 / courthouse2 level tax via world | `cheat.guardhouse2_level_tax(0,2)` |
| `cheat.univ_hall2_level_tax(cid[,v])` / `cheat.castle2_level_tax(cid[,v])` | University hall2 / castle2 level tax via world | `cheat.univ_hall2_level_tax(0,2)` |
| `cheat.barracks4_level_tax(cid[,v])` / `cheat.stables2_level_tax(cid[,v])` | Barracks4 / stables2 level tax via world | `cheat.barracks4_level_tax(0,2)` |
| `cheat.gates2_level_tax(cid[,v])` / `cheat.sentry2_level_tax(cid[,v])` | Gates2 / sentry2 level tax via world | `cheat.gates2_level_tax(0,2)` |
| `cheat.well2_level_tax(cid[,v])` / `cheat.bridge2_level_tax(cid[,v])` | Well2 / bridge2 level tax via world | `cheat.well2_level_tax(0,2)` |
| `cheat.wall2_level_tax(cid[,v])` / `cheat.tower2_level_tax(cid[,v])` | Wall2 / tower2 level tax via world | `cheat.wall2_level_tax(0,2)` |
| `cheat.forum2_level_tax(cid[,v])` / `cheat.granary2_level_tax(cid[,v])` | Forum2 / granary2 level tax via world | `cheat.forum2_level_tax(0,2)` |
| `cheat.prison2_level_tax(cid[,v])` / `cheat.harbor_dock2_level_tax(cid[,v])` | Prison2 / harbor dock2 level tax via world | `cheat.prison2_level_tax(0,2)` |
| `cheat.guild_house2_level_tax(cid[,v])` / `cheat.house2_level_tax(cid[,v])` | Guild house2 / house2 level tax via world | `cheat.guild_house2_level_tax(0,2)` |
| `cheat.chapel2_level_tax(cid[,v])` / `cheat.hospital2_level_tax(cid[,v])` | Chapel2 / hospital2 level tax via world | `cheat.chapel2_level_tax(0,2)` |
| `cheat.brothel2_level_tax(cid[,v])` / `cheat.university2_level_tax(cid[,v])` | Brothel2 / university2 level tax via world | `cheat.brothel2_level_tax(0,2)` |
| `cheat.harbor_walls2_level_tax(cid[,v])` / `cheat.schoolhouse2_level_tax(cid[,v])` | Harbor walls2 / schoolhouse2 level tax via world | `cheat.harbor_walls2_level_tax(0,2)` |
| `cheat.library_hall2_level_tax(cid[,v])` / `cheat.barber2_level_tax(cid[,v])` | Library hall2 / barber2 level tax via world | `cheat.library_hall2_level_tax(0,2)` |
| `cheat.contor3_level_tax(cid[,v])` / `cheat.dice_house3_level_tax(cid[,v])` | Contor3 / dice house3 level tax via world | `cheat.contor3_level_tax(0,2)` |
| `cheat.thieves3_level_tax(cid[,v])` / `cheat.ropemaker_ws3_level_tax(cid[,v])` | Thieves3 / ropemaking workshop3 level tax via world | `cheat.thieves3_level_tax(0,2)` |
| `cheat.tannery3_level_tax(cid[,v])` / `cheat.weaving3_level_tax(cid[,v])` | Tannery3 / weaving mill3 level tax via world | `cheat.tannery3_level_tax(0,2)` |
| `cheat.mint3_level_tax(cid[,v])` / `cheat.herb_garden3_level_tax(cid[,v])` | Mint3 / herb garden3 level tax via world | `cheat.mint3_level_tax(0,2)` |
| `cheat.vineyard3_level_tax(cid[,v])` / `cheat.pottery3_level_tax(cid[,v])` | Vineyard3 / pottery3 level tax via world | `cheat.vineyard3_level_tax(0,2)` |
| `cheat.tailor3_level_tax(cid[,v])` / `cheat.tavern3_level_tax(cid[,v])` | Tailor3 / tavern3 level tax via world | `cheat.tailor3_level_tax(0,2)` |
| `cheat.apothecary3_level_tax(cid[,v])` / `cheat.goldsmith3_level_tax(cid[,v])` | Apothecary3 / goldsmith3 level tax via world | `cheat.apothecary3_level_tax(0,2)` |
| `cheat.jeweler3_level_tax(cid[,v])` / `cheat.perfumer3_level_tax(cid[,v])` | Jeweler3 / perfumer3 level tax via world | `cheat.jeweler3_level_tax(0,2)` |
| `cheat.soapmaker3_level_tax(cid[,v])` / `cheat.candlemaker3_level_tax(cid[,v])` | Soapmaker3 / candlemaker3 level tax via world | `cheat.soapmaker3_level_tax(0,2)` |
| `cheat.papermill3_level_tax(cid[,v])` / `cheat.printing3_level_tax(cid[,v])` | Papermill3 / printing house3 level tax via world | `cheat.papermill3_level_tax(0,2)` |
| `cheat.toolmaker3_level_tax(cid[,v])` / `cheat.charcoal3_level_tax(cid[,v])` | Toolmaker3 / charcoal burner3 level tax via world | `cheat.toolmaker3_level_tax(0,2)` |
| `cheat.furrier3_level_tax(cid[,v])` / `cheat.dyer3_level_tax(cid[,v])` | Furrier3 / dyer3 level tax via world | `cheat.furrier3_level_tax(0,2)` |
| `cheat.saddler3_level_tax(cid[,v])` / `cheat.armorer3_level_tax(cid[,v])` | Saddler3 / armorer3 level tax via world | `cheat.saddler3_level_tax(0,2)` |
| `cheat.bowyer3_level_tax(cid[,v])` / `cheat.cartwright3_level_tax(cid[,v])` | Bowyer3 / cartwright3 level tax via world | `cheat.bowyer3_level_tax(0,2)` |
| `cheat.carpenter3_level_tax(cid[,v])` / `cheat.ropemaker3_level_tax(cid[,v])` | Carpenter3 / ropemaker3 level tax via world | `cheat.carpenter3_level_tax(0,2)` |
| `cheat.cooper3_level_tax(cid[,v])` / `cheat.spinner3_level_tax(cid[,v])` | Cooper3 / spinner3 level tax via world | `cheat.cooper3_level_tax(0,2)` |
| `cheat.turner3_level_tax(cid[,v])` / `cheat.stonecutter3_level_tax(cid[,v])` | Turner3 / stonecutter3 level tax via world | `cheat.turner3_level_tax(0,2)` |
| `cheat.cobbler3_level_tax(cid[,v])` / `cheat.butcher3_level_tax(cid[,v])` | Cobbler3 / butcher3 level tax via world | `cheat.cobbler3_level_tax(0,2)` |
| `cheat.baker3_level_tax(cid[,v])` / `cheat.shepherd3_level_tax(cid[,v])` | Baker3 / shepherd3 level tax via world | `cheat.baker3_level_tax(0,2)` |
| `cheat.dairy3_level_tax(cid[,v])` / `cheat.brewmaster3_level_tax(cid[,v])` | Dairy3 / brewmaster3 level tax via world | `cheat.dairy3_level_tax(0,2)` |
| `cheat.miller3_level_tax(cid[,v])` / `cheat.fishery3_level_tax(cid[,v])` | Miller3 / fishery3 level tax via world | `cheat.miller3_level_tax(0,2)` |
| `cheat.chandler3_level_tax(cid[,v])` / `cheat.goldbeater3_level_tax(cid[,v])` | Chandler3 / goldbeater3 level tax via world | `cheat.chandler3_level_tax(0,2)` |
| `cheat.potter3_level_tax(cid[,v])` / `cheat.fowler3_level_tax(cid[,v])` | Potter3 / fowler3 level tax via world | `cheat.potter3_level_tax(0,2)` |
| `cheat.vintner3_level_tax(cid[,v])` / `cheat.distiller3_level_tax(cid[,v])` | Vintner3 / distiller3 level tax via world | `cheat.vintner3_level_tax(0,2)` |
| `cheat.cook3_level_tax(cid[,v])` / `cheat.brickmaker3_level_tax(cid[,v])` | Cook3 / brickmaker3 level tax via world | `cheat.cook3_level_tax(0,2)` |
| `cheat.bathhouse3_level_tax(cid[,v])` / `cheat.barracks5_level_tax(cid[,v])` | Bathhouse3 / barracks5 level tax via world | `cheat.bathhouse3_level_tax(0,2)` |
| `cheat.school3_level_tax(cid[,v])` / `cheat.library3_level_tax(cid[,v])` | School3 / library3 level tax via world | `cheat.school3_level_tax(0,2)` |
| `cheat.mine3_level_tax(cid[,v])` / `cheat.warehouse3_level_tax(cid[,v])` | Mine3 / warehouse3 level tax via world | `cheat.mine3_level_tax(0,2)` |
| `cheat.garrison3_level_tax(cid[,v])` / `cheat.monastery3_level_tax(cid[,v])` | Garrison3 / monastery3 level tax via world | `cheat.garrison3_level_tax(0,2)` |
| `cheat.cathedral3_level_tax(cid[,v])` / `cheat.town_hall3_level_tax(cid[,v])` | Cathedral3 / town hall3 level tax via world | `cheat.cathedral3_level_tax(0,2)` |
| `cheat.market3_level_tax(cid[,v])` / `cheat.harbor3_level_tax(cid[,v])` | Market3 / harbor3 level tax via world | `cheat.market3_level_tax(0,2)` |
| `cheat.guardhouse3_level_tax(cid[,v])` / `cheat.courthouse3_level_tax(cid[,v])` | Guardhouse3 / courthouse3 level tax via world | `cheat.guardhouse3_level_tax(0,2)` |
| `cheat.univ_hall3_level_tax(cid[,v])` / `cheat.castle3_level_tax(cid[,v])` | University hall3 / castle3 level tax via world | `cheat.univ_hall3_level_tax(0,2)` |
| `cheat.barracks6_level_tax(cid[,v])` / `cheat.stables3_level_tax(cid[,v])` | Barracks6 / stables3 level tax via world | `cheat.barracks6_level_tax(0,2)` |
| `cheat.gates3_level_tax(cid[,v])` / `cheat.sentry3_level_tax(cid[,v])` | Gates3 / sentry3 level tax via world | `cheat.gates3_level_tax(0,2)` |
| `cheat.well3_level_tax(cid[,v])` / `cheat.bridge3_level_tax(cid[,v])` | Well3 / bridge3 level tax via world | `cheat.well3_level_tax(0,2)` |
| `cheat.wall3_level_tax(cid[,v])` / `cheat.tower3_level_tax(cid[,v])` | Wall3 / tower3 level tax via world | `cheat.wall3_level_tax(0,2)` |
| `cheat.forum3_level_tax(cid[,v])` / `cheat.granary3_level_tax(cid[,v])` | Forum3 / granary3 level tax via world | `cheat.forum3_level_tax(0,2)` |
| `cheat.prison3_level_tax(cid[,v])` / `cheat.harbor_dock3_level_tax(cid[,v])` | Prison3 / harbor dock3 level tax via world | `cheat.prison3_level_tax(0,2)` |
| `cheat.guild_house3_level_tax(cid[,v])` / `cheat.house3_level_tax(cid[,v])` | Guild house3 / house3 level tax via world | `cheat.guild_house3_level_tax(0,2)` |
| `cheat.chapel3_level_tax(cid[,v])` / `cheat.hospital3_level_tax(cid[,v])` | Chapel3 / hospital3 level tax via world | `cheat.chapel3_level_tax(0,2)` |
| `cheat.brothel3_level_tax(cid[,v])` / `cheat.university3_level_tax(cid[,v])` | Brothel3 / university3 level tax via world | `cheat.brothel3_level_tax(0,2)` |
| `cheat.harbor_walls3_level_tax(cid[,v])` / `cheat.schoolhouse3_level_tax(cid[,v])` | Harbor walls3 / schoolhouse3 level tax via world | `cheat.harbor_walls3_level_tax(0,2)` |
| `cheat.library_hall3_level_tax(cid[,v])` / `cheat.barber3_level_tax(cid[,v])` | Library hall3 / barber3 level tax via world | `cheat.library_hall3_level_tax(0,2)` |
| `cheat.contor4_level_tax(cid[,v])` / `cheat.dice_house4_level_tax(cid[,v])` | Contor4 / dice house4 level tax via world | `cheat.contor4_level_tax(0,2)` |
| `cheat.thieves4_level_tax(cid[,v])` / `cheat.ropemaker_ws4_level_tax(cid[,v])` | Thieves4 / ropemaking workshop4 level tax via world | `cheat.thieves4_level_tax(0,2)` |
| `cheat.tannery4_level_tax(cid[,v])` / `cheat.weaving4_level_tax(cid[,v])` | Tannery4 / weaving mill4 level tax via world | `cheat.tannery4_level_tax(0,2)` |
| `cheat.mint4_level_tax(cid[,v])` / `cheat.herb_garden4_level_tax(cid[,v])` | Mint4 / herb garden4 level tax via world | `cheat.mint4_level_tax(0,2)` |
| `cheat.vineyard4_level_tax(cid[,v])` / `cheat.pottery4_level_tax(cid[,v])` | Vineyard4 / pottery4 level tax via world | `cheat.vineyard4_level_tax(0,2)` |
| `cheat.tailor4_level_tax(cid[,v])` / `cheat.tavern4_level_tax(cid[,v])` | Tailor4 / tavern4 level tax via world | `cheat.tailor4_level_tax(0,2)` |
| `cheat.apothecary4_level_tax(cid[,v])` / `cheat.goldsmith4_level_tax(cid[,v])` | Apothecary4 / goldsmith4 level tax via world | `cheat.apothecary4_level_tax(0,2)` |
| `cheat.jeweler4_level_tax(cid[,v])` / `cheat.perfumer4_level_tax(cid[,v])` | Jeweler4 / perfumer4 level tax via world | `cheat.jeweler4_level_tax(0,2)` |
| `cheat.soapmaker4_level_tax(cid[,v])` / `cheat.candlemaker4_level_tax(cid[,v])` | Soapmaker4 / candlemaker4 level tax via world | `cheat.soapmaker4_level_tax(0,2)` |
| `cheat.papermill4_level_tax(cid[,v])` / `cheat.printing4_level_tax(cid[,v])` | Papermill4 / printing house4 level tax via world | `cheat.papermill4_level_tax(0,2)` |
| `cheat.toolmaker4_level_tax(cid[,v])` / `cheat.charcoal4_level_tax(cid[,v])` | Toolmaker4 / charcoal burner4 level tax via world | `cheat.toolmaker4_level_tax(0,2)` |
| `cheat.furrier4_level_tax(cid[,v])` / `cheat.dyer4_level_tax(cid[,v])` | Furrier4 / dyer4 level tax via world | `cheat.furrier4_level_tax(0,2)` |
| `cheat.saddler4_level_tax(cid[,v])` / `cheat.armorer4_level_tax(cid[,v])` | Saddler4 / armorer4 level tax via world | `cheat.saddler4_level_tax(0,2)` |
| `cheat.bowyer4_level_tax(cid[,v])` / `cheat.cartwright4_level_tax(cid[,v])` | Bowyer4 / cartwright4 level tax via world | `cheat.bowyer4_level_tax(0,2)` |
| `cheat.carpenter4_level_tax(cid[,v])` / `cheat.ropemaker4_level_tax(cid[,v])` | Carpenter4 / ropemaker4 level tax via world | `cheat.carpenter4_level_tax(0,2)` |
| `cheat.cooper4_level_tax(cid[,v])` / `cheat.spinner4_level_tax(cid[,v])` | Cooper4 / spinner4 level tax via world | `cheat.cooper4_level_tax(0,2)` |
| `cheat.turner4_level_tax(cid[,v])` / `cheat.stonecutter4_level_tax(cid[,v])` | Turner4 / stonecutter4 level tax via world | `cheat.turner4_level_tax(0,2)` |
| `cheat.cobbler4_level_tax(cid[,v])` / `cheat.butcher4_level_tax(cid[,v])` | Cobbler4 / butcher4 level tax via world | `cheat.cobbler4_level_tax(0,2)` |
| `cheat.baker4_level_tax(cid[,v])` / `cheat.shepherd4_level_tax(cid[,v])` | Baker4 / shepherd4 level tax via world | `cheat.baker4_level_tax(0,2)` |
| `cheat.dairy4_level_tax(cid[,v])` / `cheat.brewmaster4_level_tax(cid[,v])` | Dairy4 / brewmaster4 level tax via world | `cheat.dairy4_level_tax(0,2)` |
| `cheat.miller4_level_tax(cid[,v])` / `cheat.fishery4_level_tax(cid[,v])` | Miller4 / fishery4 level tax via world | `cheat.miller4_level_tax(0,2)` |
| `cheat.chandler4_level_tax(cid[,v])` / `cheat.goldbeater4_level_tax(cid[,v])` | Chandler4 / goldbeater4 level tax via world | `cheat.chandler4_level_tax(0,2)` |
| `cheat.potter4_level_tax(cid[,v])` / `cheat.fowler4_level_tax(cid[,v])` | Potter4 / fowler4 level tax via world | `cheat.potter4_level_tax(0,2)` |
| `cheat.vintner4_level_tax(cid[,v])` / `cheat.distiller4_level_tax(cid[,v])` | Vintner4 / distiller4 level tax via world | `cheat.vintner4_level_tax(0,2)` |
| `cheat.cook4_level_tax(cid[,v])` / `cheat.brickmaker4_level_tax(cid[,v])` | Cook4 / brickmaker4 level tax via world | `cheat.cook4_level_tax(0,2)` |
| `cheat.bathhouse4_level_tax(cid[,v])` / `cheat.barracks7_level_tax(cid[,v])` | Bathhouse4 / barracks7 level tax via world | `cheat.bathhouse4_level_tax(0,2)` |
| `cheat.school4_level_tax(cid[,v])` / `cheat.library4_level_tax(cid[,v])` | School4 / library4 level tax via world | `cheat.school4_level_tax(0,2)` |
| `cheat.mine4_level_tax(cid[,v])` / `cheat.warehouse4_level_tax(cid[,v])` | Mine4 / warehouse4 level tax via world | `cheat.mine4_level_tax(0,2)` |
| `cheat.garrison4_level_tax(cid[,v])` / `cheat.monastery4_level_tax(cid[,v])` | Garrison4 / monastery4 level tax via world | `cheat.garrison4_level_tax(0,2)` |
| `cheat.cathedral4_level_tax(cid[,v])` / `cheat.town_hall4_level_tax(cid[,v])` | Cathedral4 / town hall4 level tax via world | `cheat.cathedral4_level_tax(0,2)` |
| `cheat.market4_level_tax(cid[,v])` / `cheat.harbor4_level_tax(cid[,v])` | Market4 / harbor4 level tax via world | `cheat.market4_level_tax(0,2)` |
| `cheat.guardhouse4_level_tax(cid[,v])` / `cheat.courthouse4_level_tax(cid[,v])` | Guardhouse4 / courthouse4 level tax via world | `cheat.guardhouse4_level_tax(0,2)` |
| `cheat.univ_hall4_level_tax(cid[,v])` / `cheat.castle4_level_tax(cid[,v])` | University hall4 / castle4 level tax via world | `cheat.univ_hall4_level_tax(0,2)` |
| `cheat.barracks8_level_tax(cid[,v])` / `cheat.stables4_level_tax(cid[,v])` | Barracks8 / stables4 level tax via world | `cheat.barracks8_level_tax(0,2)` |
| `cheat.gates4_level_tax(cid[,v])` / `cheat.sentry4_level_tax(cid[,v])` | Gates4 / sentry4 level tax via world | `cheat.gates4_level_tax(0,2)` |
| `cheat.well4_level_tax(cid[,v])` / `cheat.bridge4_level_tax(cid[,v])` | Well4 / bridge4 level tax via world | `cheat.well4_level_tax(0,2)` |
| `cheat.wall4_level_tax(cid[,v])` / `cheat.tower4_level_tax(cid[,v])` | Wall4 / tower4 level tax via world | `cheat.wall4_level_tax(0,2)` |
| `cheat.forum4_level_tax(cid[,v])` / `cheat.granary4_level_tax(cid[,v])` | Forum4 / granary4 level tax via world | `cheat.forum4_level_tax(0,2)` |
| `cheat.prison4_level_tax(cid[,v])` / `cheat.harbor_dock4_level_tax(cid[,v])` | Prison4 / harbor dock4 level tax via world | `cheat.prison4_level_tax(0,2)` |
| `cheat.guild_house4_level_tax(cid[,v])` / `cheat.house4_level_tax(cid[,v])` | Guild house4 / house4 level tax via world | `cheat.guild_house4_level_tax(0,2)` |
| `cheat.chapel4_level_tax(cid[,v])` / `cheat.hospital4_level_tax(cid[,v])` | Chapel4 / hospital4 level tax via world | `cheat.chapel4_level_tax(0,2)` |
| `cheat.brothel4_level_tax(cid[,v])` / `cheat.university4_level_tax(cid[,v])` | Brothel4 / university4 level tax via world | `cheat.brothel4_level_tax(0,2)` |
| `cheat.harbor_walls4_level_tax(cid[,v])` / `cheat.schoolhouse4_level_tax(cid[,v])` | Harbor walls4 / schoolhouse4 level tax via world | `cheat.harbor_walls4_level_tax(0,2)` |
| `cheat.library_hall4_level_tax(cid[,v])` / `cheat.barber4_level_tax(cid[,v])` | Library hall4 / barber4 level tax via world | `cheat.library_hall4_level_tax(0,2)` |
| `cheat.contor5_level_tax(cid[,v])` / `cheat.dice_house5_level_tax(cid[,v])` | Contor5 / dice house5 level tax via world | `cheat.contor5_level_tax(0,2)` |
| `cheat.thieves5_level_tax(cid[,v])` / `cheat.ropemaker_ws5_level_tax(cid[,v])` | Thieves5 / ropemaking workshop5 level tax via world | `cheat.thieves5_level_tax(0,2)` |
| `cheat.tannery5_level_tax(cid[,v])` / `cheat.weaving5_level_tax(cid[,v])` | Tannery5 / weaving mill5 level tax via world | `cheat.tannery5_level_tax(0,2)` |
| `cheat.mint5_level_tax(cid[,v])` / `cheat.herb_garden5_level_tax(cid[,v])` | Mint5 / herb garden5 level tax via world | `cheat.mint5_level_tax(0,2)` |
| `cheat.vineyard5_level_tax(cid[,v])` / `cheat.pottery5_level_tax(cid[,v])` | Vineyard5 / pottery5 level tax via world | `cheat.vineyard5_level_tax(0,2)` |
| `cheat.tailor5_level_tax(cid[,v])` / `cheat.tavern5_level_tax(cid[,v])` | Tailor5 / tavern5 level tax via world | `cheat.tailor5_level_tax(0,2)` |
| `cheat.apothecary5_level_tax(cid[,v])` / `cheat.goldsmith5_level_tax(cid[,v])` | Apothecary5 / goldsmith5 level tax via world | `cheat.apothecary5_level_tax(0,2)` |
| `cheat.jeweler5_level_tax(cid[,v])` / `cheat.perfumer5_level_tax(cid[,v])` | Jeweler5 / perfumer5 level tax via world | `cheat.jeweler5_level_tax(0,2)` |
| `cheat.soapmaker5_level_tax(cid[,v])` / `cheat.candlemaker5_level_tax(cid[,v])` | Soapmaker5 / candlemaker5 level tax via world | `cheat.soapmaker5_level_tax(0,2)` |
| `cheat.papermill5_level_tax(cid[,v])` / `cheat.printing5_level_tax(cid[,v])` | Papermill5 / printing house5 level tax via world | `cheat.papermill5_level_tax(0,2)` |
| `cheat.toolmaker5_level_tax(cid[,v])` / `cheat.charcoal5_level_tax(cid[,v])` | Toolmaker5 / charcoal burner5 level tax via world | `cheat.toolmaker5_level_tax(0,2)` |
| `cheat.furrier5_level_tax(cid[,v])` / `cheat.dyer5_level_tax(cid[,v])` | Furrier5 / dyer5 level tax via world | `cheat.furrier5_level_tax(0,2)` |
| `cheat.saddler5_level_tax(cid[,v])` / `cheat.armorer5_level_tax(cid[,v])` | Saddler5 / armorer5 level tax via world | `cheat.saddler5_level_tax(0,2)` |
| `cheat.bowyer5_level_tax(cid[,v])` / `cheat.cartwright5_level_tax(cid[,v])` | Bowyer5 / cartwright5 level tax via world | `cheat.bowyer5_level_tax(0,2)` |
| `cheat.carpenter5_level_tax(cid[,v])` / `cheat.ropemaker5_level_tax(cid[,v])` | Carpenter5 / ropemaker5 level tax via world | `cheat.carpenter5_level_tax(0,2)` |
| `cheat.cooper5_level_tax(cid[,v])` / `cheat.spinner5_level_tax(cid[,v])` | Cooper5 / spinner5 level tax via world | `cheat.cooper5_level_tax(0,2)` |
| `cheat.turner5_level_tax(cid[,v])` / `cheat.stonecutter5_level_tax(cid[,v])` | Turner5 / stonecutter5 level tax via world | `cheat.turner5_level_tax(0,2)` |
| `cheat.cobbler5_level_tax(cid[,v])` / `cheat.butcher5_level_tax(cid[,v])` | Cobbler5 / butcher5 level tax via world | `cheat.cobbler5_level_tax(0,2)` |
| `cheat.baker5_level_tax(cid[,v])` / `cheat.shepherd5_level_tax(cid[,v])` | Baker5 / shepherd5 level tax via world | `cheat.baker5_level_tax(0,2)` |
| `cheat.dairy5_level_tax(cid[,v])` / `cheat.brewmaster5_level_tax(cid[,v])` | Dairy5 / brewmaster5 level tax via world | `cheat.dairy5_level_tax(0,2)` |
| `cheat.miller5_level_tax(cid[,v])` / `cheat.fishery5_level_tax(cid[,v])` | Miller5 / fishery5 level tax via world | `cheat.miller5_level_tax(0,2)` |
| `cheat.chandler5_level_tax(cid[,v])` / `cheat.goldbeater5_level_tax(cid[,v])` | Chandler5 / goldbeater5 level tax via world | `cheat.chandler5_level_tax(0,2)` |
| `cheat.potter5_level_tax(cid[,v])` / `cheat.fowler5_level_tax(cid[,v])` | Potter5 / fowler5 level tax via world | `cheat.potter5_level_tax(0,2)` |
| `cheat.vintner5_level_tax(cid[,v])` / `cheat.distiller5_level_tax(cid[,v])` | Vintner5 / distiller5 level tax via world | `cheat.vintner5_level_tax(0,2)` |
| `cheat.cook5_level_tax(cid[,v])` / `cheat.brickmaker5_level_tax(cid[,v])` | Cook5 / brickmaker5 level tax via world | `cheat.cook5_level_tax(0,2)` |
| `cheat.bathhouse5_level_tax(cid[,v])` / `cheat.barracks9_level_tax(cid[,v])` | Bathhouse5 / barracks9 level tax via world | `cheat.bathhouse5_level_tax(0,2)` |
| `cheat.school5_level_tax(cid[,v])` / `cheat.library5_level_tax(cid[,v])` | School5 / library5 level tax via world | `cheat.school5_level_tax(0,2)` |
| `cheat.mine5_level_tax(cid[,v])` / `cheat.warehouse5_level_tax(cid[,v])` | Mine5 / warehouse5 level tax via world | `cheat.mine5_level_tax(0,2)` |
| `cheat.garrison5_level_tax(cid[,v])` / `cheat.monastery5_level_tax(cid[,v])` | Garrison5 / monastery5 level tax via world | `cheat.garrison5_level_tax(0,2)` |
| `cheat.cathedral5_level_tax(cid[,v])` / `cheat.town_hall5_level_tax(cid[,v])` | Cathedral5 / town hall5 level tax via world | `cheat.cathedral5_level_tax(0,2)` |
| `cheat.market5_level_tax(cid[,v])` / `cheat.harbor5_level_tax(cid[,v])` | Market5 / harbor5 level tax via world | `cheat.market5_level_tax(0,2)` |
| `cheat.guardhouse5_level_tax(cid[,v])` / `cheat.courthouse5_level_tax(cid[,v])` | Guardhouse5 / courthouse5 level tax via world | `cheat.guardhouse5_level_tax(0,2)` |
| `cheat.univ_hall5_level_tax(cid[,v])` / `cheat.castle5_level_tax(cid[,v])` | University hall5 / castle5 level tax via world | `cheat.univ_hall5_level_tax(0,2)` |
| `cheat.barracks10_level_tax(cid[,v])` / `cheat.stables5_level_tax(cid[,v])` | Barracks10 / stables5 level tax via world | `cheat.barracks10_level_tax(0,2)` |
| `cheat.gates5_level_tax(cid[,v])` / `cheat.sentry5_level_tax(cid[,v])` | Gates5 / sentry5 level tax via world | `cheat.gates5_level_tax(0,2)` |
| `cheat.well5_level_tax(cid[,v])` / `cheat.bridge5_level_tax(cid[,v])` | Well5 / bridge5 level tax via world | `cheat.well5_level_tax(0,2)` |
| `cheat.wall5_level_tax(cid[,v])` / `cheat.tower5_level_tax(cid[,v])` | Wall5 / tower5 level tax via world | `cheat.wall5_level_tax(0,2)` |
| `cheat.forum5_level_tax(cid[,v])` / `cheat.granary5_level_tax(cid[,v])` | Forum5 / granary5 level tax via world | `cheat.forum5_level_tax(0,2)` |
| `cheat.prison5_level_tax(cid[,v])` / `cheat.harbor_dock5_level_tax(cid[,v])` | Prison5 / harbor dock5 level tax via world | `cheat.prison5_level_tax(0,2)` |
| `cheat.guild_house5_level_tax(cid[,v])` / `cheat.house5_level_tax(cid[,v])` | Guild house5 / house5 level tax via world | `cheat.guild_house5_level_tax(0,2)` |
| `cheat.chapel5_level_tax(cid[,v])` / `cheat.hospital5_level_tax(cid[,v])` | Chapel5 / hospital5 level tax via world | `cheat.chapel5_level_tax(0,2)` |
| `cheat.brothel5_level_tax(cid[,v])` / `cheat.university5_level_tax(cid[,v])` | Brothel5 / university5 level tax via world | `cheat.brothel5_level_tax(0,2)` |
| `cheat.harbor_walls5_level_tax(cid[,v])` / `cheat.schoolhouse5_level_tax(cid[,v])` | Harbor walls5 / schoolhouse5 level tax via world | `cheat.harbor_walls5_level_tax(0,2)` |
| `cheat.library_hall5_level_tax(cid[,v])` / `cheat.barber5_level_tax(cid[,v])` | Library hall5 / barber5 level tax via world | `cheat.library_hall5_level_tax(0,2)` |
| `cheat.contor6_level_tax(cid[,v])` / `cheat.dice_house6_level_tax(cid[,v])` | Contor6 / dice house6 level tax via world | `cheat.contor6_level_tax(0,2)` |
| `cheat.thieves6_level_tax(cid[,v])` / `cheat.ropemaker_ws6_level_tax(cid[,v])` | Thieves6 / ropemaking workshop6 level tax via world | `cheat.thieves6_level_tax(0,2)` |
| `cheat.tannery6_level_tax(cid[,v])` / `cheat.weaving6_level_tax(cid[,v])` | Tannery6 / weaving mill6 level tax via world | `cheat.tannery6_level_tax(0,2)` |
| `cheat.mint6_level_tax(cid[,v])` / `cheat.herb_garden6_level_tax(cid[,v])` | Mint6 / herb garden6 level tax via world | `cheat.mint6_level_tax(0,2)` |
| `cheat.vineyard6_level_tax(cid[,v])` / `cheat.pottery6_level_tax(cid[,v])` | Vineyard6 / pottery6 level tax via world | `cheat.vineyard6_level_tax(0,2)` |
| `cheat.tailor6_level_tax(cid[,v])` / `cheat.tavern6_level_tax(cid[,v])` | Tailor6 / tavern6 level tax via world | `cheat.tailor6_level_tax(0,2)` |
| `cheat.apothecary6_level_tax(cid[,v])` / `cheat.goldsmith6_level_tax(cid[,v])` | Apothecary6 / goldsmith6 level tax via world | `cheat.apothecary6_level_tax(0,2)` |
| `cheat.jeweler6_level_tax(cid[,v])` / `cheat.perfumer6_level_tax(cid[,v])` | Jeweler6 / perfumer6 level tax via world | `cheat.jeweler6_level_tax(0,2)` |
| `cheat.soapmaker6_level_tax(cid[,v])` / `cheat.candlemaker6_level_tax(cid[,v])` | Soapmaker6 / candlemaker6 level tax via world | `cheat.soapmaker6_level_tax(0,2)` |
| `cheat.papermill6_level_tax(cid[,v])` / `cheat.printing6_level_tax(cid[,v])` | Papermill6 / printing house6 level tax via world | `cheat.papermill6_level_tax(0,2)` |
| `cheat.toolmaker6_level_tax(cid[,v])` / `cheat.charcoal6_level_tax(cid[,v])` | Toolmaker6 / charcoal burner6 level tax via world | `cheat.toolmaker6_level_tax(0,2)` |
| `cheat.furrier6_level_tax(cid[,v])` / `cheat.dyer6_level_tax(cid[,v])` | Furrier6 / dyer6 level tax via world | `cheat.furrier6_level_tax(0,2)` |
| `cheat.saddler6_level_tax(cid[,v])` / `cheat.armorer6_level_tax(cid[,v])` | Saddler6 / armorer6 level tax via world | `cheat.saddler6_level_tax(0,2)` |
| `cheat.bowyer6_level_tax(cid[,v])` / `cheat.cartwright6_level_tax(cid[,v])` | Bowyer6 / cartwright6 level tax via world | `cheat.bowyer6_level_tax(0,2)` |
| `cheat.carpenter6_level_tax(cid[,v])` / `cheat.ropemaker6_level_tax(cid[,v])` | Carpenter6 / ropemaker6 level tax via world | `cheat.carpenter6_level_tax(0,2)` |
| `cheat.cooper6_level_tax(cid[,v])` / `cheat.spinner6_level_tax(cid[,v])` | Cooper6 / spinner6 level tax via world | `cheat.cooper6_level_tax(0,2)` |
| `cheat.turner6_level_tax(cid[,v])` / `cheat.stonecutter6_level_tax(cid[,v])` | Turner6 / stonecutter6 level tax via world | `cheat.turner6_level_tax(0,2)` |
| `cheat.cobbler6_level_tax(cid[,v])` / `cheat.butcher6_level_tax(cid[,v])` | Cobbler6 / butcher6 level tax via world | `cheat.cobbler6_level_tax(0,2)` |
| `cheat.baker6_level_tax(cid[,v])` / `cheat.shepherd6_level_tax(cid[,v])` | Baker6 / shepherd6 level tax via world | `cheat.baker6_level_tax(0,2)` |
| `cheat.dairy6_level_tax(cid[,v])` / `cheat.brewmaster6_level_tax(cid[,v])` | Dairy6 / brewmaster6 level tax via world | `cheat.dairy6_level_tax(0,2)` |
| `cheat.miller6_level_tax(cid[,v])` / `cheat.fishery6_level_tax(cid[,v])` | Miller6 / fishery6 level tax via world | `cheat.miller6_level_tax(0,2)` |
| `cheat.chandler6_level_tax(cid[,v])` / `cheat.goldbeater6_level_tax(cid[,v])` | Chandler6 / goldbeater6 level tax via world | `cheat.chandler6_level_tax(0,2)` |
| `cheat.potter6_level_tax(cid[,v])` / `cheat.fowler6_level_tax(cid[,v])` | Potter6 / fowler6 level tax via world | `cheat.potter6_level_tax(0,2)` |
| `cheat.vintner6_level_tax(cid[,v])` / `cheat.distiller6_level_tax(cid[,v])` | Vintner6 / distiller6 level tax via world | `cheat.vintner6_level_tax(0,2)` |
| `cheat.cook6_level_tax(cid[,v])` / `cheat.brickmaker6_level_tax(cid[,v])` | Cook6 / brickmaker6 level tax via world | `cheat.cook6_level_tax(0,2)` |
| `cheat.bathhouse6_level_tax(cid[,v])` / `cheat.barracks11_level_tax(cid[,v])` | Bathhouse6 / barracks11 level tax via world | `cheat.bathhouse6_level_tax(0,2)` |
| `cheat.school6_level_tax(cid[,v])` / `cheat.library6_level_tax(cid[,v])` | School6 / library6 level tax via world | `cheat.school6_level_tax(0,2)` |
| `cheat.mine6_level_tax(cid[,v])` / `cheat.warehouse6_level_tax(cid[,v])` | Mine6 / warehouse6 level tax via world | `cheat.mine6_level_tax(0,2)` |
| `cheat.garrison6_level_tax(cid[,v])` / `cheat.monastery6_level_tax(cid[,v])` | Garrison6 / monastery6 level tax via world | `cheat.garrison6_level_tax(0,2)` |
| `cheat.cathedral6_level_tax(cid[,v])` / `cheat.town_hall6_level_tax(cid[,v])` | Cathedral6 / town hall6 level tax via world | `cheat.cathedral6_level_tax(0,2)` |
| `cheat.market6_level_tax(cid[,v])` / `cheat.harbor6_level_tax(cid[,v])` | Market6 / harbor6 level tax via world | `cheat.market6_level_tax(0,2)` |
| `cheat.guardhouse6_level_tax(cid[,v])` / `cheat.courthouse6_level_tax(cid[,v])` | Guardhouse6 / courthouse6 level tax via world | `cheat.guardhouse6_level_tax(0,2)` |
| `cheat.univ_hall6_level_tax(cid[,v])` / `cheat.castle6_level_tax(cid[,v])` | University hall6 / castle6 level tax via world | `cheat.univ_hall6_level_tax(0,2)` |
| `cheat.barracks12_level_tax(cid[,v])` / `cheat.stables6_level_tax(cid[,v])` | Barracks12 / stables6 level tax via world | `cheat.barracks12_level_tax(0,2)` |
| `cheat.gates6_level_tax(cid[,v])` / `cheat.sentry6_level_tax(cid[,v])` | Gates6 / sentry6 level tax via world | `cheat.gates6_level_tax(0,2)` |
| `cheat.well6_level_tax(cid[,v])` / `cheat.bridge6_level_tax(cid[,v])` | Well6 / bridge6 level tax via world | `cheat.well6_level_tax(0,2)` |
| `cheat.wall6_level_tax(cid[,v])` / `cheat.tower6_level_tax(cid[,v])` | Wall6 / tower6 level tax via world | `cheat.wall6_level_tax(0,2)` |
| `cheat.forum6_level_tax(cid[,v])` / `cheat.granary6_level_tax(cid[,v])` | Forum6 / granary6 level tax via world | `cheat.forum6_level_tax(0,2)` |
| `cheat.prison6_level_tax(cid[,v])` / `cheat.harbor_dock6_level_tax(cid[,v])` | Prison6 / harbor dock6 level tax via world | `cheat.prison6_level_tax(0,2)` |
| `cheat.guild_house6_level_tax(cid[,v])` / `cheat.house6_level_tax(cid[,v])` | Guild house6 / house6 level tax via world | `cheat.guild_house6_level_tax(0,2)` |
| `cheat.chapel6_level_tax(cid[,v])` / `cheat.hospital6_level_tax(cid[,v])` | Chapel6 / hospital6 level tax via world | `cheat.chapel6_level_tax(0,2)` |
| `cheat.brothel6_level_tax(cid[,v])` / `cheat.university6_level_tax(cid[,v])` | Brothel6 / university6 level tax via world | `cheat.brothel6_level_tax(0,2)` |
| `cheat.harbor_walls6_level_tax(cid[,v])` / `cheat.schoolhouse6_level_tax(cid[,v])` | Harbor walls6 / schoolhouse6 level tax via world | `cheat.harbor_walls6_level_tax(0,2)` |
| `cheat.library_hall6_level_tax(cid[,v])` / `cheat.barber6_level_tax(cid[,v])` | Library hall6 / barber6 level tax via world | `cheat.library_hall6_level_tax(0,2)` |
| `cheat.contor7_level_tax(cid[,v])` / `cheat.dice_house7_level_tax(cid[,v])` | Contor7 / dice house7 level tax via world | `cheat.contor7_level_tax(0,2)` |
| `cheat.thieves7_level_tax(cid[,v])` / `cheat.ropemaker_ws7_level_tax(cid[,v])` | Thieves7 / ropemaking workshop7 level tax via world | `cheat.thieves7_level_tax(0,2)` |
| `cheat.tannery7_level_tax(cid[,v])` / `cheat.weaving7_level_tax(cid[,v])` | Tannery7 / weaving mill7 level tax via world | `cheat.tannery7_level_tax(0,2)` |
| `cheat.mint7_level_tax(cid[,v])` / `cheat.herb_garden7_level_tax(cid[,v])` | Mint7 / herb garden7 level tax via world | `cheat.mint7_level_tax(0,2)` |
| `cheat.vineyard7_level_tax(cid[,v])` / `cheat.pottery7_level_tax(cid[,v])` | Vineyard7 / pottery7 level tax via world | `cheat.vineyard7_level_tax(0,2)` |
| `cheat.tailor7_level_tax(cid[,v])` / `cheat.tavern7_level_tax(cid[,v])` | Tailor7 / tavern7 level tax via world | `cheat.tailor7_level_tax(0,2)` |
| `cheat.apothecary7_level_tax(cid[,v])` / `cheat.goldsmith7_level_tax(cid[,v])` | Apothecary7 / goldsmith7 level tax via world | `cheat.apothecary7_level_tax(0,2)` |
| `cheat.jeweler7_level_tax(cid[,v])` / `cheat.perfumer7_level_tax(cid[,v])` | Jeweler7 / perfumer7 level tax via world | `cheat.jeweler7_level_tax(0,2)` |
| `cheat.soapmaker7_level_tax(cid[,v])` / `cheat.candlemaker7_level_tax(cid[,v])` | Soapmaker7 / candlemaker7 level tax via world | `cheat.soapmaker7_level_tax(0,2)` |
| `cheat.papermill7_level_tax(cid[,v])` / `cheat.printing7_level_tax(cid[,v])` | Papermill7 / printing house7 level tax via world | `cheat.papermill7_level_tax(0,2)` |
| `cheat.toolmaker7_level_tax(cid[,v])` / `cheat.charcoal7_level_tax(cid[,v])` | Toolmaker7 / charcoal burner7 level tax via world | `cheat.toolmaker7_level_tax(0,2)` |
| `cheat.furrier7_level_tax(cid[,v])` / `cheat.dyer7_level_tax(cid[,v])` | Furrier7 / dyer7 level tax via world | `cheat.furrier7_level_tax(0,2)` |
| `cheat.saddler7_level_tax(cid[,v])` / `cheat.armorer7_level_tax(cid[,v])` | Saddler7 / armorer7 level tax via world | `cheat.saddler7_level_tax(0,2)` |
| `cheat.bowyer7_level_tax(cid[,v])` / `cheat.cartwright7_level_tax(cid[,v])` | Bowyer7 / cartwright7 level tax via world | `cheat.bowyer7_level_tax(0,2)` |
| `cheat.carpenter7_level_tax(cid[,v])` / `cheat.ropemaker7_level_tax(cid[,v])` | Carpenter7 / ropemaker7 level tax via world | `cheat.carpenter7_level_tax(0,2)` |
| `cheat.cooper7_level_tax(cid[,v])` / `cheat.spinner7_level_tax(cid[,v])` | Cooper7 / spinner7 level tax via world | `cheat.cooper7_level_tax(0,2)` |
| `cheat.turner7_level_tax(cid[,v])` / `cheat.stonecutter7_level_tax(cid[,v])` | Turner7 / stonecutter7 level tax via world | `cheat.turner7_level_tax(0,2)` |
| `cheat.cobbler7_level_tax(cid[,v])` / `cheat.butcher7_level_tax(cid[,v])` | Cobbler7 / butcher7 level tax via world | `cheat.cobbler7_level_tax(0,2)` |
| `cheat.baker7_level_tax(cid[,v])` / `cheat.shepherd7_level_tax(cid[,v])` | Baker7 / shepherd7 level tax via world | `cheat.baker7_level_tax(0,2)` |
| `cheat.dairy7_level_tax(cid[,v])` / `cheat.brewmaster7_level_tax(cid[,v])` | Dairy7 / brewmaster7 level tax via world | `cheat.dairy7_level_tax(0,2)` |
| `cheat.miller7_level_tax(cid[,v])` / `cheat.fishery7_level_tax(cid[,v])` | Miller7 / fishery7 level tax via world | `cheat.miller7_level_tax(0,2)` |
| `cheat.chandler7_level_tax(cid[,v])` / `cheat.goldbeater7_level_tax(cid[,v])` | Chandler7 / goldbeater7 level tax via world | `cheat.chandler7_level_tax(0,2)` |
| `cheat.potter7_level_tax(cid[,v])` / `cheat.fowler7_level_tax(cid[,v])` | Potter7 / fowler7 level tax via world | `cheat.potter7_level_tax(0,2)` |
| `cheat.vintner7_level_tax(cid[,v])` / `cheat.distiller7_level_tax(cid[,v])` | Vintner7 / distiller7 level tax via world | `cheat.vintner7_level_tax(0,2)` |
| `cheat.cook7_level_tax(cid[,v])` / `cheat.brickmaker7_level_tax(cid[,v])` | Cook7 / brickmaker7 level tax via world | `cheat.cook7_level_tax(0,2)` |
| `cheat.bathhouse7_level_tax(cid[,v])` / `cheat.barracks13_level_tax(cid[,v])` | Bathhouse7 / barracks13 level tax via world | `cheat.bathhouse7_level_tax(0,2)` |
| `cheat.school7_level_tax(cid[,v])` / `cheat.library7_level_tax(cid[,v])` | School7 / library7 level tax via world | `cheat.school7_level_tax(0,2)` |
| `cheat.mine7_level_tax(cid[,v])` / `cheat.warehouse7_level_tax(cid[,v])` | Mine7 / warehouse7 level tax via world | `cheat.mine7_level_tax(0,2)` |
| `cheat.garrison7_level_tax(cid[,v])` / `cheat.monastery7_level_tax(cid[,v])` | Garrison7 / monastery7 level tax via world | `cheat.garrison7_level_tax(0,2)` |
| `cheat.cathedral7_level_tax(cid[,v])` / `cheat.town_hall7_level_tax(cid[,v])` | Cathedral7 / town hall7 level tax via world | `cheat.cathedral7_level_tax(0,2)` |
| `cheat.market7_level_tax(cid[,v])` / `cheat.harbor7_level_tax(cid[,v])` | Market7 / harbor7 level tax via world | `cheat.market7_level_tax(0,2)` |
| `cheat.guardhouse7_level_tax(cid[,v])` / `cheat.courthouse7_level_tax(cid[,v])` | Guardhouse7 / courthouse7 level tax via world | `cheat.guardhouse7_level_tax(0,2)` |
| `cheat.univ_hall7_level_tax(cid[,v])` / `cheat.castle7_level_tax(cid[,v])` | University hall7 / castle7 level tax via world | `cheat.univ_hall7_level_tax(0,2)` |
| `cheat.barracks14_level_tax(cid[,v])` / `cheat.stables7_level_tax(cid[,v])` | Barracks14 / stables7 level tax via world | `cheat.barracks14_level_tax(0,2)` |
| `cheat.gates7_level_tax(cid[,v])` / `cheat.sentry7_level_tax(cid[,v])` | Gates7 / sentry7 level tax via world | `cheat.gates7_level_tax(0,2)` |
| `cheat.well7_level_tax(cid[,v])` / `cheat.bridge7_level_tax(cid[,v])` | Well7 / bridge7 level tax via world | `cheat.well7_level_tax(0,2)` |
| `cheat.wall7_level_tax(cid[,v])` / `cheat.tower7_level_tax(cid[,v])` | Wall7 / tower7 level tax via world | `cheat.wall7_level_tax(0,2)` |
| `cheat.forum7_level_tax(cid[,v])` / `cheat.granary7_level_tax(cid[,v])` | Forum7 / granary7 level tax via world | `cheat.forum7_level_tax(0,2)` |
| `cheat.prison7_level_tax(cid[,v])` / `cheat.harbor_dock7_level_tax(cid[,v])` | Prison7 / harbor dock7 level tax via world | `cheat.prison7_level_tax(0,2)` |
| `cheat.guild_house7_level_tax(cid[,v])` / `cheat.house7_level_tax(cid[,v])` | Guild house7 / house7 level tax via world | `cheat.guild_house7_level_tax(0,2)` |
| `cheat.chapel7_level_tax(cid[,v])` / `cheat.hospital7_level_tax(cid[,v])` | Chapel7 / hospital7 level tax via world | `cheat.chapel7_level_tax(0,2)` |
| `cheat.brothel7_level_tax(cid[,v])` / `cheat.university7_level_tax(cid[,v])` | Brothel7 / university7 level tax via world | `cheat.brothel7_level_tax(0,2)` |
| `cheat.harbor_walls7_level_tax(cid[,v])` / `cheat.schoolhouse7_level_tax(cid[,v])` | Harbor walls7 / schoolhouse7 level tax via world | `cheat.harbor_walls7_level_tax(0,2)` |
| `cheat.library_hall7_level_tax(cid[,v])` / `cheat.barber7_level_tax(cid[,v])` | Library hall7 / barber7 level tax via world | `cheat.library_hall7_level_tax(0,2)` |
| `cheat.contor8_level_tax(cid[,v])` / `cheat.dice_house8_level_tax(cid[,v])` | Contor8 / dice house8 level tax via world | `cheat.contor8_level_tax(0,2)` |
| `cheat.thieves8_level_tax(cid[,v])` / `cheat.ropemaker_ws8_level_tax(cid[,v])` | Thieves8 / ropemaking workshop8 level tax via world | `cheat.thieves8_level_tax(0,2)` |
| `cheat.tannery8_level_tax(cid[,v])` / `cheat.weaving8_level_tax(cid[,v])` | Tannery8 / weaving mill8 level tax via world | `cheat.tannery8_level_tax(0,2)` |
| `cheat.mint8_level_tax(cid[,v])` / `cheat.herb_garden8_level_tax(cid[,v])` | Mint8 / herb garden8 level tax via world | `cheat.mint8_level_tax(0,2)` |
| `cheat.vineyard8_level_tax(cid[,v])` / `cheat.pottery8_level_tax(cid[,v])` | Vineyard8 / pottery8 level tax via world | `cheat.vineyard8_level_tax(0,2)` |
| `cheat.tailor8_level_tax(cid[,v])` / `cheat.tavern8_level_tax(cid[,v])` | Tailor8 / tavern8 level tax via world | `cheat.tailor8_level_tax(0,2)` |
| `cheat.apothecary8_level_tax(cid[,v])` / `cheat.goldsmith8_level_tax(cid[,v])` | Apothecary8 / goldsmith8 level tax via world | `cheat.apothecary8_level_tax(0,2)` |
| `cheat.jeweler8_level_tax(cid[,v])` / `cheat.perfumer8_level_tax(cid[,v])` | Jeweler8 / perfumer8 level tax via world | `cheat.jeweler8_level_tax(0,2)` |
| `cheat.soapmaker8_level_tax(cid[,v])` / `cheat.candlemaker8_level_tax(cid[,v])` | Soapmaker8 / candlemaker8 level tax via world | `cheat.soapmaker8_level_tax(0,2)` |
| `cheat.papermill8_level_tax(cid[,v])` / `cheat.printing8_level_tax(cid[,v])` | Papermill8 / printing house8 level tax via world | `cheat.papermill8_level_tax(0,2)` |
| `cheat.toolmaker8_level_tax(cid[,v])` / `cheat.charcoal8_level_tax(cid[,v])` | Toolmaker8 / charcoal burner8 level tax via world | `cheat.toolmaker8_level_tax(0,2)` |
| `cheat.furrier8_level_tax(cid[,v])` / `cheat.dyer8_level_tax(cid[,v])` | Furrier8 / dyer8 level tax via world | `cheat.furrier8_level_tax(0,2)` |
| `cheat.saddler8_level_tax(cid[,v])` / `cheat.armorer8_level_tax(cid[,v])` | Saddler8 / armorer8 level tax via world | `cheat.saddler8_level_tax(0,2)` |
| `cheat.bowyer8_level_tax(cid[,v])` / `cheat.cartwright8_level_tax(cid[,v])` | Bowyer8 / cartwright8 level tax via world | `cheat.bowyer8_level_tax(0,2)` |
| `cheat.carpenter8_level_tax(cid[,v])` / `cheat.ropemaker8_level_tax(cid[,v])` | Carpenter8 / ropemaker8 level tax via world | `cheat.carpenter8_level_tax(0,2)` |
| `cheat.cooper8_level_tax(cid[,v])` / `cheat.spinner8_level_tax(cid[,v])` | Cooper8 / spinner8 level tax via world | `cheat.cooper8_level_tax(0,2)` |
| `cheat.turner8_level_tax(cid[,v])` / `cheat.stonecutter8_level_tax(cid[,v])` | Turner8 / stonecutter8 level tax via world | `cheat.turner8_level_tax(0,2)` |
| `cheat.cobbler8_level_tax(cid[,v])` / `cheat.butcher8_level_tax(cid[,v])` | Cobbler8 / butcher8 level tax via world | `cheat.cobbler8_level_tax(0,2)` |
| `cheat.baker8_level_tax(cid[,v])` / `cheat.shepherd8_level_tax(cid[,v])` | Baker8 / shepherd8 level tax via world | `cheat.baker8_level_tax(0,2)` |
| `cheat.dairy8_level_tax(cid[,v])` / `cheat.brewmaster8_level_tax(cid[,v])` | Dairy8 / brewmaster8 level tax via world | `cheat.dairy8_level_tax(0,2)` |
| `cheat.miller8_level_tax(cid[,v])` / `cheat.fishery8_level_tax(cid[,v])` | Miller8 / fishery8 level tax via world | `cheat.miller8_level_tax(0,2)` |
| `cheat.chandler8_level_tax(cid[,v])` / `cheat.goldbeater8_level_tax(cid[,v])` | Chandler8 / goldbeater8 level tax via world | `cheat.chandler8_level_tax(0,2)` |
| `cheat.potter8_level_tax(cid[,v])` / `cheat.fowler8_level_tax(cid[,v])` | Potter8 / fowler8 level tax via world | `cheat.potter8_level_tax(0,2)` |
| `cheat.vintner8_level_tax(cid[,v])` / `cheat.distiller8_level_tax(cid[,v])` | Vintner8 / distiller8 level tax via world | `cheat.vintner8_level_tax(0,2)` |
| `cheat.cook8_level_tax(cid[,v])` / `cheat.brickmaker8_level_tax(cid[,v])` | Cook8 / brickmaker8 level tax via world | `cheat.cook8_level_tax(0,2)` |
| `cheat.bathhouse8_level_tax(cid[,v])` / `cheat.barracks15_level_tax(cid[,v])` | Bathhouse8 / barracks15 level tax via world | `cheat.bathhouse8_level_tax(0,2)` |
| `cheat.school8_level_tax(cid[,v])` / `cheat.library8_level_tax(cid[,v])` | School8 / library8 level tax via world | `cheat.school8_level_tax(0,2)` |
| `cheat.mine8_level_tax(cid[,v])` / `cheat.warehouse8_level_tax(cid[,v])` | Mine8 / warehouse8 level tax via world | `cheat.mine8_level_tax(0,2)` |
| `cheat.garrison8_level_tax(cid[,v])` / `cheat.monastery8_level_tax(cid[,v])` | Garrison8 / monastery8 level tax via world | `cheat.garrison8_level_tax(0,2)` |
| `cheat.cathedral8_level_tax(cid[,v])` / `cheat.town_hall8_level_tax(cid[,v])` | Cathedral8 / town hall8 level tax via world | `cheat.cathedral8_level_tax(0,2)` |
| `cheat.market8_level_tax(cid[,v])` / `cheat.harbor8_level_tax(cid[,v])` | Market8 / harbor8 level tax via world | `cheat.market8_level_tax(0,2)` |
| `cheat.guardhouse8_level_tax(cid[,v])` / `cheat.courthouse8_level_tax(cid[,v])` | Guardhouse8 / courthouse8 level tax via world | `cheat.guardhouse8_level_tax(0,2)` |
| `cheat.univ_hall8_level_tax(cid[,v])` / `cheat.castle8_level_tax(cid[,v])` | University hall8 / castle8 level tax via world | `cheat.univ_hall8_level_tax(0,2)` |
| `cheat.well8_level_tax(cid[,v])` / `cheat.bridge8_level_tax(cid[,v])` | Well8 / bridge8 level tax via world | `cheat.well8_level_tax(0,2)` |
| `cheat.wall8_level_tax(cid[,v])` / `cheat.tower8_level_tax(cid[,v])` | Wall8 / tower8 level tax via world | `cheat.wall8_level_tax(0,2)` |
| `cheat.forum8_level_tax(cid[,v])` / `cheat.granary8_level_tax(cid[,v])` | Forum8 / granary8 level tax via world | `cheat.forum8_level_tax(0,2)` |
| `cheat.prison8_level_tax(cid[,v])` / `cheat.harbor_dock8_level_tax(cid[,v])` | Prison8 / harbor dock8 level tax via world | `cheat.prison8_level_tax(0,2)` |
| `cheat.guild_house8_level_tax(cid[,v])` / `cheat.house8_level_tax(cid[,v])` | Guild house8 / house8 level tax via world | `cheat.guild_house8_level_tax(0,2)` |
| `cheat.chapel8_level_tax(cid[,v])` / `cheat.hospital8_level_tax(cid[,v])` | Chapel8 / hospital8 level tax via world | `cheat.chapel8_level_tax(0,2)` |
| `cheat.brothel8_level_tax(cid[,v])` / `cheat.university8_level_tax(cid[,v])` | Brothel8 / university8 level tax via world | `cheat.brothel8_level_tax(0,2)` |
| `cheat.harbor_walls8_level_tax(cid[,v])` / `cheat.schoolhouse8_level_tax(cid[,v])` | Harbor walls8 / schoolhouse8 level tax via world | `cheat.harbor_walls8_level_tax(0,2)` |
| `cheat.library_hall8_level_tax(cid[,v])` / `cheat.barber8_level_tax(cid[,v])` | Library hall8 / barber8 level tax via world | `cheat.library_hall8_level_tax(0,2)` |
| `cheat.contor9_level_tax(cid[,v])` / `cheat.dice_house9_level_tax(cid[,v])` | Contor9 / dice house9 level tax via world | `cheat.contor9_level_tax(0,2)` |
| `cheat.thieves9_level_tax(cid[,v])` / `cheat.ropemaker_ws9_level_tax(cid[,v])` | Thieves9 / ropemaking workshop9 level tax via world | `cheat.thieves9_level_tax(0,2)` |
| `cheat.tannery9_level_tax(cid[,v])` / `cheat.weaving9_level_tax(cid[,v])` | Tannery9 / weaving mill9 level tax via world | `cheat.tannery9_level_tax(0,2)` |
| `cheat.mint9_level_tax(cid[,v])` / `cheat.herb_garden9_level_tax(cid[,v])` | Mint9 / herb garden9 level tax via world | `cheat.mint9_level_tax(0,2)` |
| `cheat.vineyard9_level_tax(cid[,v])` / `cheat.pottery9_level_tax(cid[,v])` | Vineyard9 / pottery9 level tax via world | `cheat.vineyard9_level_tax(0,2)` |
| `cheat.tailor9_level_tax(cid[,v])` / `cheat.tavern9_level_tax(cid[,v])` | Tailor9 / tavern9 level tax via world | `cheat.tailor9_level_tax(0,2)` |
| `cheat.apothecary9_level_tax(cid[,v])` / `cheat.goldsmith9_level_tax(cid[,v])` | Apothecary9 / goldsmith9 level tax via world | `cheat.apothecary9_level_tax(0,2)` |
| `cheat.jeweler9_level_tax(cid[,v])` / `cheat.perfumer9_level_tax(cid[,v])` | Jeweler9 / perfumer9 level tax via world | `cheat.jeweler9_level_tax(0,2)` |
| `cheat.soapmaker9_level_tax(cid[,v])` / `cheat.candlemaker9_level_tax(cid[,v])` | Soapmaker9 / candlemaker9 level tax via world | `cheat.soapmaker9_level_tax(0,2)` |
| `cheat.papermill9_level_tax(cid[,v])` / `cheat.printing9_level_tax(cid[,v])` | Papermill9 / printing house9 level tax via world | `cheat.papermill9_level_tax(0,2)` |
| `cheat.toolmaker9_level_tax(cid[,v])` / `cheat.charcoal9_level_tax(cid[,v])` | Toolmaker9 / charcoal burner9 level tax via world | `cheat.toolmaker9_level_tax(0,2)` |
| `cheat.furrier9_level_tax(cid[,v])` / `cheat.dyer9_level_tax(cid[,v])` | Furrier9 / dyer9 level tax via world | `cheat.furrier9_level_tax(0,2)` |
| `cheat.saddler9_level_tax(cid[,v])` / `cheat.armorer9_level_tax(cid[,v])` | Saddler9 / armorer9 level tax via world | `cheat.saddler9_level_tax(0,2)` |
| `cheat.bowyer9_level_tax(cid[,v])` / `cheat.cartwright9_level_tax(cid[,v])` | Bowyer9 / cartwright9 level tax via world | `cheat.bowyer9_level_tax(0,2)` |
| `cheat.carpenter9_level_tax(cid[,v])` / `cheat.ropemaker9_level_tax(cid[,v])` | Carpenter9 / ropemaker9 level tax via world | `cheat.carpenter9_level_tax(0,2)` |
| `cheat.cooper9_level_tax(cid[,v])` / `cheat.spinner9_level_tax(cid[,v])` | Cooper9 / spinner9 level tax via world | `cheat.cooper9_level_tax(0,2)` |
| `cheat.turner9_level_tax(cid[,v])` / `cheat.stonecutter9_level_tax(cid[,v])` | Turner9 / stonecutter9 level tax via world | `cheat.turner9_level_tax(0,2)` |
| `cheat.cobbler9_level_tax(cid[,v])` / `cheat.butcher9_level_tax(cid[,v])` | Cobbler9 / butcher9 level tax via world | `cheat.cobbler9_level_tax(0,2)` |
| `cheat.baker9_level_tax(cid[,v])` / `cheat.shepherd9_level_tax(cid[,v])` | Baker9 / shepherd9 level tax via world | `cheat.baker9_level_tax(0,2)` |
| `cheat.dairy9_level_tax(cid[,v])` / `cheat.brewmaster9_level_tax(cid[,v])` | Dairy9 / brewmaster9 level tax via world | `cheat.dairy9_level_tax(0,2)` |
| `cheat.miller9_level_tax(cid[,v])` / `cheat.fishery9_level_tax(cid[,v])` | Miller9 / fishery9 level tax via world | `cheat.miller9_level_tax(0,2)` |
| `cheat.chandler9_level_tax(cid[,v])` / `cheat.goldbeater9_level_tax(cid[,v])` | Chandler9 / goldbeater9 level tax via world | `cheat.chandler9_level_tax(0,2)` |
| `cheat.potter9_level_tax(cid[,v])` / `cheat.fowler9_level_tax(cid[,v])` | Potter9 / fowler9 level tax via world | `cheat.potter9_level_tax(0,2)` |
| `cheat.vintner9_level_tax(cid[,v])` / `cheat.distiller9_level_tax(cid[,v])` | Vintner9 / distiller9 level tax via world | `cheat.vintner9_level_tax(0,2)` |
| `cheat.cook9_level_tax(cid[,v])` / `cheat.brickmaker9_level_tax(cid[,v])` | Cook9 / brickmaker9 level tax via world | `cheat.cook9_level_tax(0,2)` |
| `cheat.bathhouse9_level_tax(cid[,v])` / `cheat.barracks16_level_tax(cid[,v])` | Bathhouse9 / barracks16 level tax via world | `cheat.bathhouse9_level_tax(0,2)` |
| `cheat.school9_level_tax(cid[,v])` / `cheat.library9_level_tax(cid[,v])` | School9 / library9 level tax via world | `cheat.school9_level_tax(0,2)` |
| `cheat.mine9_level_tax(cid[,v])` / `cheat.warehouse9_level_tax(cid[,v])` | Mine9 / warehouse9 level tax via world | `cheat.mine9_level_tax(0,2)` |
| `cheat.garrison9_level_tax(cid[,v])` / `cheat.monastery9_level_tax(cid[,v])` | Garrison9 / monastery9 level tax via world | `cheat.garrison9_level_tax(0,2)` |
| `cheat.cathedral9_level_tax(cid[,v])` / `cheat.town_hall9_level_tax(cid[,v])` | Cathedral9 / town hall9 level tax via world | `cheat.cathedral9_level_tax(0,2)` |
| `cheat.market9_level_tax(cid[,v])` / `cheat.harbor9_level_tax(cid[,v])` | Market9 / harbor9 level tax via world | `cheat.market9_level_tax(0,2)` |
| `cheat.guardhouse9_level_tax(cid[,v])` / `cheat.courthouse9_level_tax(cid[,v])` | Guardhouse9 / courthouse9 level tax via world | `cheat.guardhouse9_level_tax(0,2)` |
| `cheat.univ_hall9_level_tax(cid[,v])` / `cheat.castle9_level_tax(cid[,v])` | University hall9 / castle9 level tax via world | `cheat.univ_hall9_level_tax(0,2)` |
| `cheat.well9_level_tax(cid[,v])` / `cheat.bridge9_level_tax(cid[,v])` | Well9 / bridge9 level tax via world | `cheat.well9_level_tax(0,2)` |
| `cheat.wall9_level_tax(cid[,v])` / `cheat.tower9_level_tax(cid[,v])` | Wall9 / tower9 level tax via world | `cheat.wall9_level_tax(0,2)` |
| `cheat.forum9_level_tax(cid[,v])` / `cheat.granary9_level_tax(cid[,v])` | Forum9 / granary9 level tax via world | `cheat.forum9_level_tax(0,2)` |
| `cheat.prison9_level_tax(cid[,v])` / `cheat.harbor_dock9_level_tax(cid[,v])` | Prison9 / harbor dock9 level tax via world | `cheat.prison9_level_tax(0,2)` |
| `cheat.guild_house9_level_tax(cid[,v])` / `cheat.house9_level_tax(cid[,v])` | Guild house9 / house9 level tax via world | `cheat.guild_house9_level_tax(0,2)` |
| `cheat.chapel9_level_tax(cid[,v])` / `cheat.hospital9_level_tax(cid[,v])` | Chapel9 / hospital9 level tax via world | `cheat.chapel9_level_tax(0,2)` |
| `cheat.brothel9_level_tax(cid[,v])` / `cheat.university9_level_tax(cid[,v])` | Brothel9 / university9 level tax via world | `cheat.brothel9_level_tax(0,2)` |
| `cheat.harbor_walls9_level_tax(cid[,v])` / `cheat.schoolhouse9_level_tax(cid[,v])` | Harbor walls9 / schoolhouse9 level tax via world | `cheat.harbor_walls9_level_tax(0,2)` |
| `cheat.library_hall9_level_tax(cid[,v])` / `cheat.barber9_level_tax(cid[,v])` | Library hall9 / barber9 level tax via world | `cheat.library_hall9_level_tax(0,2)` |
| `cheat.contor10_level_tax(cid[,v])` / `cheat.dice_house10_level_tax(cid[,v])` | Contor10 / dice house10 level tax via world | `cheat.contor10_level_tax(0,2)` |
| `cheat.thieves10_level_tax(cid[,v])` / `cheat.ropemaker_ws10_level_tax(cid[,v])` | Thieves10 / ropemaking workshop10 level tax via world | `cheat.thieves10_level_tax(0,2)` |
| `cheat.tannery10_level_tax(cid[,v])` / `cheat.weaving10_level_tax(cid[,v])` | Tannery10 / weaving mill10 level tax via world | `cheat.tannery10_level_tax(0,2)` |
| `cheat.mint10_level_tax(cid[,v])` / `cheat.herb_garden10_level_tax(cid[,v])` | Mint10 / herb garden10 level tax via world | `cheat.mint10_level_tax(0,2)` |
| `cheat.vineyard10_level_tax(cid[,v])` / `cheat.pottery10_level_tax(cid[,v])` | Vineyard10 / pottery10 level tax via world | `cheat.vineyard10_level_tax(0,2)` |
| `cheat.tailor10_level_tax(cid[,v])` / `cheat.tavern10_level_tax(cid[,v])` | Tailor10 / tavern10 level tax via world | `cheat.tailor10_level_tax(0,2)` |
| `cheat.apothecary10_level_tax(cid[,v])` / `cheat.goldsmith10_level_tax(cid[,v])` | Apothecary10 / goldsmith10 level tax via world | `cheat.apothecary10_level_tax(0,2)` |
| `cheat.jeweler10_level_tax(cid[,v])` / `cheat.perfumer10_level_tax(cid[,v])` | Jeweler10 / perfumer10 level tax via world | `cheat.jeweler10_level_tax(0,2)` |
| `cheat.soapmaker10_level_tax(cid[,v])` / `cheat.candlemaker10_level_tax(cid[,v])` | Soapmaker10 / candlemaker10 level tax via world | `cheat.soapmaker10_level_tax(0,2)` |
| `cheat.papermill10_level_tax(cid[,v])` / `cheat.printing10_level_tax(cid[,v])` | Papermill10 / printing house10 level tax via world | `cheat.papermill10_level_tax(0,2)` |
| `cheat.toolmaker10_level_tax(cid[,v])` / `cheat.charcoal10_level_tax(cid[,v])` | Toolmaker10 / charcoal burner10 level tax via world | `cheat.toolmaker10_level_tax(0,2)` |
| `cheat.furrier10_level_tax(cid[,v])` / `cheat.dyer10_level_tax(cid[,v])` | Furrier10 / dyer10 level tax via world | `cheat.furrier10_level_tax(0,2)` |
| `cheat.saddler10_level_tax(cid[,v])` / `cheat.armorer10_level_tax(cid[,v])` | Saddler10 / armorer10 level tax via world | `cheat.saddler10_level_tax(0,2)` |
| `cheat.bowyer10_level_tax(cid[,v])` / `cheat.cartwright10_level_tax(cid[,v])` | Bowyer10 / cartwright10 level tax via world | `cheat.bowyer10_level_tax(0,2)` |
| `cheat.carpenter10_level_tax(cid[,v])` / `cheat.ropemaker10_level_tax(cid[,v])` | Carpenter10 / ropemaker10 level tax via world | `cheat.carpenter10_level_tax(0,2)` |
| `cheat.cooper10_level_tax(cid[,v])` / `cheat.spinner10_level_tax(cid[,v])` | Cooper10 / spinner10 level tax via world | `cheat.cooper10_level_tax(0,2)` |
| `cheat.turner10_level_tax(cid[,v])` / `cheat.stonecutter10_level_tax(cid[,v])` | Turner10 / stonecutter10 level tax via world | `cheat.turner10_level_tax(0,2)` |
| `cheat.cobbler10_level_tax(cid[,v])` / `cheat.butcher10_level_tax(cid[,v])` | Cobbler10 / butcher10 level tax via world | `cheat.cobbler10_level_tax(0,2)` |
| `cheat.baker10_level_tax(cid[,v])` / `cheat.shepherd10_level_tax(cid[,v])` | Baker10 / shepherd10 level tax via world | `cheat.baker10_level_tax(0,2)` |
| `cheat.dairy10_level_tax(cid[,v])` / `cheat.brewmaster10_level_tax(cid[,v])` | Dairy10 / brewmaster10 level tax via world | `cheat.dairy10_level_tax(0,2)` |
| `cheat.miller10_level_tax(cid[,v])` / `cheat.fishery10_level_tax(cid[,v])` | Miller10 / fishery10 level tax via world | `cheat.miller10_level_tax(0,2)` |
| `cheat.chandler10_level_tax(cid[,v])` / `cheat.brickmaker10_level_tax(cid[,v])` | Chandler10 / brickmaker10 level tax via world | `cheat.chandler10_level_tax(0,2)` |
| `cheat.potter10_level_tax(cid[,v])` / `cheat.glassblower10_level_tax(cid[,v])` | Potter10 / glassblower10 level tax via world | `cheat.potter10_level_tax(0,2)` |
| `cheat.goldbeater10_level_tax(cid[,v])` / `cheat.fowler10_level_tax(cid[,v])` | Goldbeater10 / fowler10 level tax via world | `cheat.goldbeater10_level_tax(0,2)` |
| `cheat.vintner10_level_tax(cid[,v])` / `cheat.distiller10_level_tax(cid[,v])` | Vintner10 / distiller10 level tax via world | `cheat.vintner10_level_tax(0,2)` |
| `cheat.cook10_level_tax(cid[,v])` / `cheat.glassblower_level_tax(cid[,v])` | Cook10 / glassblower level tax via world | `cheat.cook10_level_tax(0,2)` |
| `cheat.glassblower2_level_tax(cid[,v])` / `cheat.glassblower3_level_tax(cid[,v])` | Glassblower2 / glassblower3 level tax via world | `cheat.glassblower2_level_tax(0,2)` |
| `cheat.glassblower4_level_tax(cid[,v])` / `cheat.glassblower5_level_tax(cid[,v])` | Glassblower4 / glassblower5 level tax via world | `cheat.glassblower4_level_tax(0,2)` |
| `cheat.glassblower6_level_tax(cid[,v])` / `cheat.glassblower7_level_tax(cid[,v])` | Glassblower6 / glassblower7 level tax via world | `cheat.glassblower6_level_tax(0,2)` |
| `cheat.glassblower8_level_tax(cid[,v])` / `cheat.glassblower9_level_tax(cid[,v])` | Glassblower8 / glassblower9 level tax via world | `cheat.glassblower8_level_tax(0,2)` |
| `cheat.barber10_level_tax(cid[,v])` / `cheat.bathhouse10_level_tax(cid[,v])` | Barber10 / bathhouse10 level tax via world | `cheat.barber10_level_tax(0,2)` |
| `cheat.bridge10_level_tax(cid[,v])` / `cheat.brothel10_level_tax(cid[,v])` | Bridge10 / brothel10 level tax via world | `cheat.bridge10_level_tax(0,2)` |
| `cheat.castle10_level_tax(cid[,v])` / `cheat.cathedral10_level_tax(cid[,v])` | Castle10 / cathedral10 level tax via world | `cheat.castle10_level_tax(0,2)` |
| `cheat.chapel10_level_tax(cid[,v])` / `cheat.courthouse10_level_tax(cid[,v])` | Chapel10 / courthouse10 level tax via world | `cheat.chapel10_level_tax(0,2)` |
| `cheat.forum10_level_tax(cid[,v])` / `cheat.garrison10_level_tax(cid[,v])` | Forum10 / garrison10 level tax via world | `cheat.forum10_level_tax(0,2)` |
| `cheat.gates10_level_tax(cid[,v])` / `cheat.granary10_level_tax(cid[,v])` | Gates10 / granary10 level tax via world | `cheat.gates10_level_tax(0,2)` |
| `cheat.guardhouse10_level_tax(cid[,v])` / `cheat.guild_house10_level_tax(cid[,v])` | Guardhouse10 / guild house10 level tax via world | `cheat.guardhouse10_level_tax(0,2)` |
| `cheat.harbor10_level_tax(cid[,v])` / `cheat.harbor_dock10_level_tax(cid[,v])` | Harbor10 / harbor dock10 level tax via world | `cheat.harbor10_level_tax(0,2)` |
| `cheat.harbor_walls10_level_tax(cid[,v])` / `cheat.hospital10_level_tax(cid[,v])` | Harbor walls10 / hospital10 level tax via world | `cheat.harbor_walls10_level_tax(0,2)` |
| `cheat.house10_level_tax(cid[,v])` / `cheat.library10_level_tax(cid[,v])` | House10 / library10 level tax via world | `cheat.house10_level_tax(0,2)` |
| `cheat.library_hall10_level_tax(cid[,v])` / `cheat.market10_level_tax(cid[,v])` | Library hall10 / market10 level tax via world | `cheat.library_hall10_level_tax(0,2)` |
| `cheat.mine10_level_tax(cid[,v])` / `cheat.monastery10_level_tax(cid[,v])` | Mine10 / monastery10 level tax via world | `cheat.mine10_level_tax(0,2)` |
| `cheat.prison10_level_tax(cid[,v])` / `cheat.school10_level_tax(cid[,v])` | Prison10 / school10 level tax via world | `cheat.prison10_level_tax(0,2)` |
| `cheat.schoolhouse10_level_tax(cid[,v])` / `cheat.sentry_tower10_level_tax(cid[,v])` | Schoolhouse10 / sentry tower10 level tax via world | `cheat.schoolhouse10_level_tax(0,2)` |
| `cheat.stables10_level_tax(cid[,v])` / `cheat.tower10_level_tax(cid[,v])` | Stables10 / tower10 level tax via world | `cheat.stables10_level_tax(0,2)` |
| `cheat.town_hall10_level_tax(cid[,v])` / `cheat.university10_level_tax(cid[,v])` | Town hall10 / university10 level tax via world | `cheat.town_hall10_level_tax(0,2)` |
| `cheat.university_hall10_level_tax(cid[,v])` / `cheat.wall10_level_tax(cid[,v])` | University hall10 / wall10 level tax via world | `cheat.university_hall10_level_tax(0,2)` |
| `cheat.warehouse10_level_tax(cid[,v])` / `cheat.well10_level_tax(cid[,v])` | Warehouse10 / well10 level tax via world | `cheat.warehouse10_level_tax(0,2)` |
| `cheat.sentry_tower8_level_tax(cid[,v])` / `cheat.sentry_tower9_level_tax(cid[,v])` | Sentry tower8 / sentry tower9 level tax via world | `cheat.sentry_tower8_level_tax(0,2)` |
| `cheat.stables8_level_tax(cid[,v])` / `cheat.stables9_level_tax(cid[,v])` | Stables8 / stables9 level tax via world | `cheat.stables8_level_tax(0,2)` |
| `cheat.church2_level_tax(cid[,v])` / `cheat.church3_level_tax(cid[,v])` | Church2 / church3 level tax via world | `cheat.church2_level_tax(0,2)` |
| `cheat.church4_level_tax(cid[,v])` / `cheat.church5_level_tax(cid[,v])` | Church4 / church5 level tax via world | `cheat.church4_level_tax(0,2)` |
| `cheat.church6_level_tax(cid[,v])` / `cheat.church7_level_tax(cid[,v])` | Church6 / church7 level tax via world | `cheat.church6_level_tax(0,2)` |
| `cheat.church8_level_tax(cid[,v])` / `cheat.church9_level_tax(cid[,v])` | Church8 / church9 level tax via world | `cheat.church8_level_tax(0,2)` |
| `cheat.church10_level_tax(cid[,v])` / `cheat.town_hall11_level_tax(cid[,v])` | Church10 / town hall11 level tax via world | `cheat.church10_level_tax(0,2)` |
| `cheat.university11_level_tax(cid[,v])` / `cheat.wall11_level_tax(cid[,v])` | University11 / wall11 level tax via world | `cheat.university11_level_tax(0,2)` |
| `cheat.apothecary11_level_tax(cid[,v])` / `cheat.baker11_level_tax(cid[,v])` | Apothecary11 / baker11 level tax via world | `cheat.apothecary11_level_tax(0,2)` |
| `cheat.barber11_level_tax(cid[,v])` / `cheat.bathhouse11_level_tax(cid[,v])` | Barber11 / bathhouse11 level tax via world | `cheat.barber11_level_tax(0,2)` |
| `cheat.bowyer11_level_tax(cid[,v])` / `cheat.brewmaster11_level_tax(cid[,v])` | Bowyer11 / brewmaster11 level tax via world | `cheat.bowyer11_level_tax(0,2)` |
| `cheat.brickmaker11_level_tax(cid[,v])` / `cheat.bridge11_level_tax(cid[,v])` | Brickmaker11 / bridge11 level tax via world | `cheat.brickmaker11_level_tax(0,2)` |
| `cheat.brothel11_level_tax(cid[,v])` / `cheat.butcher11_level_tax(cid[,v])` | Brothel11 / butcher11 level tax via world | `cheat.brothel11_level_tax(0,2)` |
| `cheat.candlemaker11_level_tax(cid[,v])` / `cheat.carpenter11_level_tax(cid[,v])` | Candlemaker11 / carpenter11 level tax via world | `cheat.candlemaker11_level_tax(0,2)` |
| `cheat.cartwright11_level_tax(cid[,v])` / `cheat.castle11_level_tax(cid[,v])` | Cartwright11 / castle11 level tax via world | `cheat.cartwright11_level_tax(0,2)` |
| `cheat.cathedral11_level_tax(cid[,v])` / `cheat.chandler11_level_tax(cid[,v])` | Cathedral11 / chandler11 level tax via world | `cheat.cathedral11_level_tax(0,2)` |
| `cheat.chapel11_level_tax(cid[,v])` / `cheat.church11_level_tax(cid[,v])` | Chapel11 / church11 level tax via world | `cheat.chapel11_level_tax(0,2)` |
| `cheat.cobbler11_level_tax(cid[,v])` / `cheat.contor11_level_tax(cid[,v])` | Cobbler11 / contor11 level tax via world | `cheat.cobbler11_level_tax(0,2)` |
| `cheat.cook11_level_tax(cid[,v])` / `cheat.cooper11_level_tax(cid[,v])` | Cook11 / cooper11 level tax via world | `cheat.cook11_level_tax(0,2)` |
| `cheat.courthouse11_level_tax(cid[,v])` / `cheat.dairy11_level_tax(cid[,v])` | Courthouse11 / dairy11 level tax via world | `cheat.courthouse11_level_tax(0,2)` |
| `cheat.dice_house11_level_tax(cid[,v])` / `cheat.distiller11_level_tax(cid[,v])` | Dice house11 / distiller11 level tax via world | `cheat.dice_house11_level_tax(0,2)` |
| `cheat.dyer11_level_tax(cid[,v])` / `cheat.fishery11_level_tax(cid[,v])` | Dyer11 / fishery11 level tax via world | `cheat.dyer11_level_tax(0,2)` |
| `cheat.forum11_level_tax(cid[,v])` / `cheat.fowler11_level_tax(cid[,v])` | Forum11 / fowler11 level tax via world | `cheat.forum11_level_tax(0,2)` |
| `cheat.furrier11_level_tax(cid[,v])` / `cheat.garrison11_level_tax(cid[,v])` | Furrier11 / garrison11 level tax via world | `cheat.furrier11_level_tax(0,2)` |
| `cheat.gates11_level_tax(cid[,v])` / `cheat.glassblower11_level_tax(cid[,v])` | Gates11 / glassblower11 level tax via world | `cheat.gates11_level_tax(0,2)` |
| `cheat.goldbeater11_level_tax(cid[,v])` / `cheat.goldsmith11_level_tax(cid[,v])` | Goldbeater11 / goldsmith11 level tax via world | `cheat.goldbeater11_level_tax(0,2)` |
| `cheat.granary11_level_tax(cid[,v])` / `cheat.guardhouse11_level_tax(cid[,v])` | Granary11 / guardhouse11 level tax via world | `cheat.granary11_level_tax(0,2)` |
| `cheat.guild_house11_level_tax(cid[,v])` / `cheat.harbor11_level_tax(cid[,v])` | Guild house11 / harbor11 level tax via world | `cheat.guild_house11_level_tax(0,2)` |
| `cheat.harbor_dock11_level_tax(cid[,v])` / `cheat.harbor_walls11_level_tax(cid[,v])` | Harbor dock11 / harbor walls11 level tax via world | `cheat.harbor_dock11_level_tax(0,2)` |
| `cheat.herb_garden11_level_tax(cid[,v])` / `cheat.hospital11_level_tax(cid[,v])` | Herb garden11 / hospital11 level tax via world | `cheat.herb_garden11_level_tax(0,2)` |
| `cheat.house11_level_tax(cid[,v])` / `cheat.jeweler11_level_tax(cid[,v])` | House11 / jeweler11 level tax via world | `cheat.house11_level_tax(0,2)` |
| `cheat.library11_level_tax(cid[,v])` / `cheat.library_hall11_level_tax(cid[,v])` | Library11 / library hall11 level tax via world | `cheat.library11_level_tax(0,2)` |
| `cheat.market11_level_tax(cid[,v])` / `cheat.miller11_level_tax(cid[,v])` | Market11 / miller11 level tax via world | `cheat.market11_level_tax(0,2)` |
| `cheat.mine11_level_tax(cid[,v])` / `cheat.mint11_level_tax(cid[,v])` | Mine11 / mint11 level tax via world | `cheat.mine11_level_tax(0,2)` |
| `cheat.monastery11_level_tax(cid[,v])` / `cheat.papermill11_level_tax(cid[,v])` | Monastery11 / papermill11 level tax via world | `cheat.monastery11_level_tax(0,2)` |
| `cheat.perfumer11_level_tax(cid[,v])` / `cheat.potter11_level_tax(cid[,v])` | Perfumer11 / potter11 level tax via world | `cheat.perfumer11_level_tax(0,2)` |
| `cheat.pottery11_level_tax(cid[,v])` / `cheat.printing_house11_level_tax(cid[,v])` | Pottery11 / printing house11 level tax via world | `cheat.pottery11_level_tax(0,2)` |
| `cheat.ropemaker11_level_tax(cid[,v])` / `cheat.ropemaker_workshop11_level_tax(cid[,v])` | Ropemaker11 / ropemaking workshop11 level tax via world | `cheat.ropemaker11_level_tax(0,2)` |
| `cheat.saddler11_level_tax(cid[,v])` / `cheat.school11_level_tax(cid[,v])` | Saddler11 / school11 level tax via world | `cheat.saddler11_level_tax(0,2)` |
| `cheat.schoolhouse11_level_tax(cid[,v])` / `cheat.sentry_tower11_level_tax(cid[,v])` | Schoolhouse11 / sentry tower11 level tax via world | `cheat.schoolhouse11_level_tax(0,2)` |
| `cheat.stables11_level_tax(cid[,v])` / `cheat.stonecutter11_level_tax(cid[,v])` | Stables11 / stonecutter11 level tax via world | `cheat.stables11_level_tax(0,2)` |
| `cheat.tailor11_level_tax(cid[,v])` / `cheat.tannery11_level_tax(cid[,v])` | Tailor11 / tannery11 level tax via world | `cheat.tailor11_level_tax(0,2)` |
| `cheat.tavern11_level_tax(cid[,v])` / `cheat.thieves_guild11_level_tax(cid[,v])` | Tavern11 / thieves guild11 level tax via world | `cheat.tavern11_level_tax(0,2)` |
| `cheat.toolmaker11_level_tax(cid[,v])` / `cheat.tower11_level_tax(cid[,v])` | Toolmaker11 / tower11 level tax via world | `cheat.toolmaker11_level_tax(0,2)` |
| `cheat.town_hall12_level_tax(cid[,v])` / `cheat.turner11_level_tax(cid[,v])` | Town hall12 / turner11 level tax via world | `cheat.town_hall12_level_tax(0,2)` |
| `cheat.university12_level_tax(cid[,v])` / `cheat.university_hall11_level_tax(cid[,v])` | University12 / university hall11 level tax via world | `cheat.university12_level_tax(0,2)` |
| `cheat.vineyard11_level_tax(cid[,v])` / `cheat.vintner11_level_tax(cid[,v])` | Vineyard11 / vintner11 level tax via world | `cheat.vineyard11_level_tax(0,2)` |
| `cheat.wall12_level_tax(cid[,v])` / `cheat.warehouse11_level_tax(cid[,v])` | Wall12 / warehouse11 level tax via world | `cheat.wall12_level_tax(0,2)` |
| `cheat.weaving_mill11_level_tax(cid[,v])` / `cheat.well11_level_tax(cid[,v])` | Weaving mill11 / well11 level tax via world | `cheat.weaving_mill11_level_tax(0,2)` |
| `cheat.armorer11_level_tax(cid[,v])` / `cheat.candlemaker12_level_tax(cid[,v])` | Armorer11 / candlemaker12 level tax via world | `cheat.armorer11_level_tax(0,2)` |
| `cheat.carpenter12_level_tax(cid[,v])` / `cheat.cartwright12_level_tax(cid[,v])` | Carpenter12 / cartwright12 level tax via world | `cheat.carpenter12_level_tax(0,2)` |
| `cheat.chandler12_level_tax(cid[,v])` / `cheat.charcoal11_level_tax(cid[,v])` | Chandler12 / charcoal11 level tax via world | `cheat.chandler12_level_tax(0,2)` |
| `cheat.charcoal12_level_tax(cid[,v])` / `cheat.church12_level_tax(cid[,v])` | Charcoal12 / church12 level tax via world | `cheat.charcoal12_level_tax(0,2)` |
| `cheat.cobbler12_level_tax(cid[,v])` / `cheat.contor12_level_tax(cid[,v])` | Cobbler12 / contor12 level tax via world | `cheat.cobbler12_level_tax(0,2)` |
| `cheat.cook12_level_tax(cid[,v])` / `cheat.cooper12_level_tax(cid[,v])` | Cook12 / cooper12 level tax via world | `cheat.cook12_level_tax(0,2)` |
| `cheat.courthouse12_level_tax(cid[,v])` / `cheat.dairy12_level_tax(cid[,v])` | Courthouse12 / dairy12 level tax via world | `cheat.courthouse12_level_tax(0,2)` |
| `cheat.dice_house12_level_tax(cid[,v])` / `cheat.distiller12_level_tax(cid[,v])` | Dice house12 / distiller12 level tax via world | `cheat.dice_house12_level_tax(0,2)` |
| `cheat.dyer12_level_tax(cid[,v])` / `cheat.fishery12_level_tax(cid[,v])` | Dyer12 / fishery12 level tax via world | `cheat.dyer12_level_tax(0,2)` |
| `cheat.forum12_level_tax(cid[,v])` / `cheat.fowler12_level_tax(cid[,v])` | Forum12 / fowler12 level tax via world | `cheat.forum12_level_tax(0,2)` |
| `cheat.furrier12_level_tax(cid[,v])` / `cheat.garrison12_level_tax(cid[,v])` | Furrier12 / garrison12 level tax via world | `cheat.furrier12_level_tax(0,2)` |
| `cheat.gates12_level_tax(cid[,v])` / `cheat.glassblower12_level_tax(cid[,v])` | Gates12 / glassblower12 level tax via world | `cheat.gates12_level_tax(0,2)` |
| `cheat.goldbeater12_level_tax(cid[,v])` / `cheat.goldsmith12_level_tax(cid[,v])` | Goldbeater12 / goldsmith12 level tax via world | `cheat.goldbeater12_level_tax(0,2)` |
| `cheat.granary12_level_tax(cid[,v])` / `cheat.guardhouse12_level_tax(cid[,v])` | Granary12 / guardhouse12 level tax via world | `cheat.granary12_level_tax(0,2)` |
| `cheat.guild_house12_level_tax(cid[,v])` / `cheat.harbor12_level_tax(cid[,v])` | Guild house12 / harbor12 level tax via world | `cheat.guild_house12_level_tax(0,2)` |
| `cheat.harbor_dock12_level_tax(cid[,v])` / `cheat.harbor_walls12_level_tax(cid[,v])` | Harbor dock12 / harbor walls12 level tax via world | `cheat.harbor_dock12_level_tax(0,2)` |
| `cheat.herb_garden12_level_tax(cid[,v])` / `cheat.hospital12_level_tax(cid[,v])` | Herb garden12 / hospital12 level tax via world | `cheat.herb_garden12_level_tax(0,2)` |
| `cheat.house12_level_tax(cid[,v])` / `cheat.jeweler12_level_tax(cid[,v])` | House12 / jeweler12 level tax via world | `cheat.house12_level_tax(0,2)` |
| `cheat.library12_level_tax(cid[,v])` / `cheat.library_hall12_level_tax(cid[,v])` | Library12 / library hall12 level tax via world | `cheat.library12_level_tax(0,2)` |
| `cheat.market12_level_tax(cid[,v])` / `cheat.miller12_level_tax(cid[,v])` | Market12 / miller12 level tax via world | `cheat.market12_level_tax(0,2)` |
| `cheat.mine12_level_tax(cid[,v])` / `cheat.mint12_level_tax(cid[,v])` | Mine12 / mint12 level tax via world | `cheat.mine12_level_tax(0,2)` |
| `cheat.monastery12_level_tax(cid[,v])` / `cheat.papermill12_level_tax(cid[,v])` | Monastery12 / papermill12 level tax via world | `cheat.monastery12_level_tax(0,2)` |
| `cheat.perfumer12_level_tax(cid[,v])` / `cheat.potter12_level_tax(cid[,v])` | Perfumer12 / potter12 level tax via world | `cheat.perfumer12_level_tax(0,2)` |
| `cheat.pottery12_level_tax(cid[,v])` / `cheat.printing_house12_level_tax(cid[,v])` | Pottery12 / printing house12 level tax via world | `cheat.pottery12_level_tax(0,2)` |
| `cheat.ropemaker12_level_tax(cid[,v])` / `cheat.ropemaker_workshop12_level_tax(cid[,v])` | Ropemaker12 / ropemaking workshop12 level tax via world | `cheat.ropemaker12_level_tax(0,2)` |
| `cheat.saddler12_level_tax(cid[,v])` / `cheat.school12_level_tax(cid[,v])` | Saddler12 / school12 level tax via world | `cheat.saddler12_level_tax(0,2)` |
| `cheat.schoolhouse12_level_tax(cid[,v])` / `cheat.sentry_tower12_level_tax(cid[,v])` | Schoolhouse12 / sentry tower12 level tax via world | `cheat.schoolhouse12_level_tax(0,2)` |
| `cheat.stables12_level_tax(cid[,v])` / `cheat.stonecutter12_level_tax(cid[,v])` | Stables12 / stonecutter12 level tax via world | `cheat.stables12_level_tax(0,2)` |
| `cheat.tailor12_level_tax(cid[,v])` / `cheat.tannery12_level_tax(cid[,v])` | Tailor12 / tannery12 level tax via world | `cheat.tailor12_level_tax(0,2)` |
| `cheat.tavern12_level_tax(cid[,v])` / `cheat.thieves_guild12_level_tax(cid[,v])` | Tavern12 / thieves guild12 level tax via world | `cheat.tavern12_level_tax(0,2)` |
| `cheat.toolmaker12_level_tax(cid[,v])` / `cheat.tower12_level_tax(cid[,v])` | Toolmaker12 / tower12 level tax via world | `cheat.toolmaker12_level_tax(0,2)` |
| `cheat.turner12_level_tax(cid[,v])` / `cheat.university13_level_tax(cid[,v])` | Turner12 / university13 level tax via world | `cheat.turner12_level_tax(0,2)` |
| `cheat.university_hall12_level_tax(cid[,v])` / `cheat.vineyard12_level_tax(cid[,v])` | University hall12 / vineyard12 level tax via world | `cheat.university_hall12_level_tax(0,2)` |
| `cheat.vintner12_level_tax(cid[,v])` / `cheat.wall13_level_tax(cid[,v])` | Vintner12 / wall13 level tax via world | `cheat.vintner12_level_tax(0,2)` |
| `cheat.warehouse12_level_tax(cid[,v])` / `cheat.weaving_mill12_level_tax(cid[,v])` | Warehouse12 / weaving mill12 level tax via world | `cheat.warehouse12_level_tax(0,2)` |
| `cheat.well12_level_tax(cid[,v])` / `cheat.armorer12_level_tax(cid[,v])` | Well12 / armorer12 level tax via world | `cheat.well12_level_tax(0,2)` |
| `cheat.baker12_level_tax(cid[,v])` / `cheat.barber12_level_tax(cid[,v])` | Baker12 / barber12 level tax via world | `cheat.baker12_level_tax(0,2)` |
| `cheat.bathhouse12_level_tax(cid[,v])` / `cheat.bowyer12_level_tax(cid[,v])` | Bathhouse12 / bowyer12 level tax via world | `cheat.bathhouse12_level_tax(0,2)` |
| `cheat.brewmaster12_level_tax(cid[,v])` / `cheat.brickmaker12_level_tax(cid[,v])` | Brewmaster12 / brickmaker12 level tax via world | `cheat.brewmaster12_level_tax(0,2)` |
| `cheat.bridge12_level_tax(cid[,v])` / `cheat.brothel12_level_tax(cid[,v])` | Bridge12 / brothel12 level tax via world | `cheat.bridge12_level_tax(0,2)` |
| `cheat.butcher12_level_tax(cid[,v])` / `cheat.castle12_level_tax(cid[,v])` | Butcher12 / castle12 level tax via world | `cheat.butcher12_level_tax(0,2)` |
| `cheat.cathedral12_level_tax(cid[,v])` / `cheat.chandler13_level_tax(cid[,v])` | Cathedral12 / chandler13 level tax via world | `cheat.cathedral12_level_tax(0,2)` |
| `cheat.chapel12_level_tax(cid[,v])` / `cheat.church13_level_tax(cid[,v])` | Chapel12 / church13 level tax via world | `cheat.chapel12_level_tax(0,2)` |
| `cheat.cobbler13_level_tax(cid[,v])` / `cheat.contor13_level_tax(cid[,v])` | Cobbler13 / contor13 level tax via world | `cheat.cobbler13_level_tax(0,2)` |
| `cheat.cook13_level_tax(cid[,v])` / `cheat.cooper13_level_tax(cid[,v])` | Cook13 / cooper13 level tax via world | `cheat.cook13_level_tax(0,2)` |
| `cheat.courthouse13_level_tax(cid[,v])` / `cheat.dairy13_level_tax(cid[,v])` | Courthouse13 / dairy13 level tax via world | `cheat.courthouse13_level_tax(0,2)` |
| `cheat.dice_house13_level_tax(cid[,v])` / `cheat.distiller13_level_tax(cid[,v])` | Dice house13 / distiller13 level tax via world | `cheat.dice_house13_level_tax(0,2)` |
| `cheat.dyer13_level_tax(cid[,v])` / `cheat.fishery13_level_tax(cid[,v])` | Dyer13 / fishery13 level tax via world | `cheat.dyer13_level_tax(0,2)` |
| `cheat.forum13_level_tax(cid[,v])` / `cheat.fowler13_level_tax(cid[,v])` | Forum13 / fowler13 level tax via world | `cheat.forum13_level_tax(0,2)` |
| `cheat.furrier13_level_tax(cid[,v])` / `cheat.garrison13_level_tax(cid[,v])` | Furrier13 / garrison13 level tax via world | `cheat.furrier13_level_tax(0,2)` |
| `cheat.gates13_level_tax(cid[,v])` / `cheat.glassblower13_level_tax(cid[,v])` | Gates13 / glassblower13 level tax via world | `cheat.gates13_level_tax(0,2)` |
| `cheat.goldbeater13_level_tax(cid[,v])` / `cheat.goldsmith13_level_tax(cid[,v])` | Goldbeater13 / goldsmith13 level tax via world | `cheat.goldbeater13_level_tax(0,2)` |
| `cheat.granary13_level_tax(cid[,v])` / `cheat.guardhouse13_level_tax(cid[,v])` | Granary13 / guardhouse13 level tax via world | `cheat.granary13_level_tax(0,2)` |
| `cheat.guild_house13_level_tax(cid[,v])` / `cheat.harbor13_level_tax(cid[,v])` | Guild house13 / harbor13 level tax via world | `cheat.guild_house13_level_tax(0,2)` |
| `cheat.harbor_dock13_level_tax(cid[,v])` / `cheat.harbor_walls13_level_tax(cid[,v])` | Harbor dock13 / harbor walls13 level tax via world | `cheat.harbor_dock13_level_tax(0,2)` |
| `cheat.herb_garden13_level_tax(cid[,v])` / `cheat.hospital13_level_tax(cid[,v])` | Herb garden13 / hospital13 level tax via world | `cheat.herb_garden13_level_tax(0,2)` |
| `cheat.house13_level_tax(cid[,v])` / `cheat.jeweler13_level_tax(cid[,v])` | House13 / jeweler13 level tax via world | `cheat.house13_level_tax(0,2)` |
| `cheat.library13_level_tax(cid[,v])` / `cheat.library_hall13_level_tax(cid[,v])` | Library13 / library hall13 level tax via world | `cheat.library13_level_tax(0,2)` |
| `cheat.market13_level_tax(cid[,v])` / `cheat.miller13_level_tax(cid[,v])` | Market13 / miller13 level tax via world | `cheat.market13_level_tax(0,2)` |
| `cheat.mine13_level_tax(cid[,v])` / `cheat.mint13_level_tax(cid[,v])` | Mine13 / mint13 level tax via world | `cheat.mine13_level_tax(0,2)` |
| `cheat.monastery13_level_tax(cid[,v])` / `cheat.papermill13_level_tax(cid[,v])` | Monastery13 / papermill13 level tax via world | `cheat.monastery13_level_tax(0,2)` |
| `cheat.perfumer13_level_tax(cid[,v])` / `cheat.potter13_level_tax(cid[,v])` | Perfumer13 / potter13 level tax via world | `cheat.perfumer13_level_tax(0,2)` |
| `cheat.pottery13_level_tax(cid[,v])` / `cheat.printing_house13_level_tax(cid[,v])` | Pottery13 / printing house13 level tax via world | `cheat.pottery13_level_tax(0,2)` |
| `cheat.ropemaker13_level_tax(cid[,v])` / `cheat.ropemaker_workshop13_level_tax(cid[,v])` | Ropemaker13 / ropemaking workshop13 level tax via world | `cheat.ropemaker13_level_tax(0,2)` |
| `cheat.saddler13_level_tax(cid[,v])` / `cheat.school13_level_tax(cid[,v])` | Saddler13 / school13 level tax via world | `cheat.saddler13_level_tax(0,2)` |
| `cheat.schoolhouse13_level_tax(cid[,v])` / `cheat.sentry_tower13_level_tax(cid[,v])` | Schoolhouse13 / sentry tower13 level tax via world | `cheat.schoolhouse13_level_tax(0,2)` |
| `cheat.stables13_level_tax(cid[,v])` / `cheat.stonecutter13_level_tax(cid[,v])` | Stables13 / stonecutter13 level tax via world | `cheat.stables13_level_tax(0,2)` |
| `cheat.tailor13_level_tax(cid[,v])` / `cheat.tannery13_level_tax(cid[,v])` | Tailor13 / tannery13 level tax via world | `cheat.tailor13_level_tax(0,2)` |
| `cheat.tavern13_level_tax(cid[,v])` / `cheat.thieves_guild13_level_tax(cid[,v])` | Tavern13 / thieves guild13 level tax via world | `cheat.tavern13_level_tax(0,2)` |
| `cheat.toolmaker13_level_tax(cid[,v])` / `cheat.tower13_level_tax(cid[,v])` | Toolmaker13 / tower13 level tax via world | `cheat.toolmaker13_level_tax(0,2)` |
| `cheat.turner13_level_tax(cid[,v])` / `cheat.university14_level_tax(cid[,v])` | Turner13 / university14 level tax via world | `cheat.turner13_level_tax(0,2)` |
| `cheat.university_hall13_level_tax(cid[,v])` / `cheat.vineyard13_level_tax(cid[,v])` | University hall13 / vineyard13 level tax via world | `cheat.university_hall13_level_tax(0,2)` |
| `cheat.vintner13_level_tax(cid[,v])` / `cheat.wall14_level_tax(cid[,v])` | Vintner13 / wall14 level tax via world | `cheat.vintner13_level_tax(0,2)` |
| `cheat.warehouse13_level_tax(cid[,v])` / `cheat.weaving_mill13_level_tax(cid[,v])` | Warehouse13 / weaving mill13 level tax via world | `cheat.warehouse13_level_tax(0,2)` |
| `cheat.well13_level_tax(cid[,v])` / `cheat.armorer13_level_tax(cid[,v])` | Well13 / armorer13 level tax via world | `cheat.well13_level_tax(0,2)` |
| `cheat.baker13_level_tax(cid[,v])` / `cheat.barber13_level_tax(cid[,v])` | Baker13 / barber13 level tax via world | `cheat.baker13_level_tax(0,2)` |
| `cheat.bathhouse13_level_tax(cid[,v])` / `cheat.bowyer13_level_tax(cid[,v])` | Bathhouse13 / bowyer13 level tax via world | `cheat.bathhouse13_level_tax(0,2)` |
| `cheat.brewmaster13_level_tax(cid[,v])` / `cheat.brickmaker13_level_tax(cid[,v])` | Brewmaster13 / brickmaker13 level tax via world | `cheat.brewmaster13_level_tax(0,2)` |
| `cheat.bridge13_level_tax(cid[,v])` / `cheat.brothel13_level_tax(cid[,v])` | Bridge13 / brothel13 level tax via world | `cheat.bridge13_level_tax(0,2)` |
| `cheat.butcher13_level_tax(cid[,v])` / `cheat.candlemaker13_level_tax(cid[,v])` | Butcher13 / candlemaker13 level tax via world | `cheat.butcher13_level_tax(0,2)` |
| `cheat.carpenter13_level_tax(cid[,v])` / `cheat.cartwright13_level_tax(cid[,v])` | Carpenter13 / cartwright13 level tax via world | `cheat.carpenter13_level_tax(0,2)` |
| `cheat.castle13_level_tax(cid[,v])` / `cheat.cathedral13_level_tax(cid[,v])` | Castle13 / cathedral13 level tax via world | `cheat.castle13_level_tax(0,2)` |
| `cheat.chapel13_level_tax(cid[,v])` / `cheat.charcoal13_level_tax(cid[,v])` | Chapel13 / charcoal13 level tax via world | `cheat.chapel13_level_tax(0,2)` |
| `cheat.church14_level_tax(cid[,v])` / `cheat.cobbler14_level_tax(cid[,v])` | Church14 / cobbler14 level tax via world | `cheat.church14_level_tax(0,2)` |
| `cheat.contor14_level_tax(cid[,v])` / `cheat.cook14_level_tax(cid[,v])` | Contor14 / cook14 level tax via world | `cheat.contor14_level_tax(0,2)` |
| `cheat.cooper14_level_tax(cid[,v])` / `cheat.courthouse14_level_tax(cid[,v])` | Cooper14 / courthouse14 level tax via world | `cheat.cooper14_level_tax(0,2)` |
| `cheat.dairy14_level_tax(cid[,v])` / `cheat.dice_house14_level_tax(cid[,v])` | Dairy14 / dice house14 level tax via world | `cheat.dairy14_level_tax(0,2)` |
| `cheat.distiller14_level_tax(cid[,v])` / `cheat.dyer14_level_tax(cid[,v])` | Distiller14 / dyer14 level tax via world | `cheat.distiller14_level_tax(0,2)` |
| `cheat.fishery14_level_tax(cid[,v])` / `cheat.forum14_level_tax(cid[,v])` | Fishery14 / forum14 level tax via world | `cheat.fishery14_level_tax(0,2)` |
| `cheat.fowler14_level_tax(cid[,v])` / `cheat.furrier14_level_tax(cid[,v])` | Fowler14 / furrier14 level tax via world | `cheat.fowler14_level_tax(0,2)` |
| `cheat.garrison14_level_tax(cid[,v])` / `cheat.gates14_level_tax(cid[,v])` | Garrison14 / gates14 level tax via world | `cheat.garrison14_level_tax(0,2)` |
| `cheat.glassblower14_level_tax(cid[,v])` / `cheat.goldbeater14_level_tax(cid[,v])` | Glassblower14 / goldbeater14 level tax via world | `cheat.glassblower14_level_tax(0,2)` |
| `cheat.goldsmith14_level_tax(cid[,v])` / `cheat.granary14_level_tax(cid[,v])` | Goldsmith14 / granary14 level tax via world | `cheat.goldsmith14_level_tax(0,2)` |
| `cheat.guardhouse14_level_tax(cid[,v])` / `cheat.guild_house14_level_tax(cid[,v])` | Guardhouse14 / guild house14 level tax via world | `cheat.guardhouse14_level_tax(0,2)` |
| `cheat.harbor14_level_tax(cid[,v])` / `cheat.harbor_dock14_level_tax(cid[,v])` | Harbor14 / harbor dock14 level tax via world | `cheat.harbor14_level_tax(0,2)` |
| `cheat.harbor_walls14_level_tax(cid[,v])` / `cheat.herb_garden14_level_tax(cid[,v])` | Harbor walls14 / herb garden14 level tax via world | `cheat.harbor_walls14_level_tax(0,2)` |
| `cheat.hospital14_level_tax(cid[,v])` / `cheat.house14_level_tax(cid[,v])` | Hospital14 / house14 level tax via world | `cheat.hospital14_level_tax(0,2)` |
| `cheat.jeweler14_level_tax(cid[,v])` / `cheat.library14_level_tax(cid[,v])` | Jeweler14 / library14 level tax via world | `cheat.jeweler14_level_tax(0,2)` |
| `cheat.library_hall14_level_tax(cid[,v])` / `cheat.market14_level_tax(cid[,v])` | Library hall14 / market14 level tax via world | `cheat.library_hall14_level_tax(0,2)` |
| `cheat.miller14_level_tax(cid[,v])` / `cheat.mine14_level_tax(cid[,v])` | Miller14 / mine14 level tax via world | `cheat.miller14_level_tax(0,2)` |
| `cheat.mint14_level_tax(cid[,v])` / `cheat.monastery14_level_tax(cid[,v])` | Mint14 / monastery14 level tax via world | `cheat.mint14_level_tax(0,2)` |
| `cheat.papermill14_level_tax(cid[,v])` / `cheat.perfumer14_level_tax(cid[,v])` | Papermill14 / perfumer14 level tax via world | `cheat.papermill14_level_tax(0,2)` |
| `cheat.potter14_level_tax(cid[,v])` / `cheat.pottery14_level_tax(cid[,v])` | Potter14 / pottery14 level tax via world | `cheat.potter14_level_tax(0,2)` |
| `cheat.printing_house14_level_tax(cid[,v])` / `cheat.ropemaker14_level_tax(cid[,v])` | Printing house14 / ropemaker14 level tax via world | `cheat.printing_house14_level_tax(0,2)` |
| `cheat.ropemaker_workshop14_level_tax(cid[,v])` / `cheat.saddler14_level_tax(cid[,v])` | Ropemaking workshop14 / saddler14 level tax via world | `cheat.ropemaker_workshop14_level_tax(0,2)` |
| `cheat.school14_level_tax(cid[,v])` / `cheat.schoolhouse14_level_tax(cid[,v])` | School14 / schoolhouse14 level tax via world | `cheat.school14_level_tax(0,2)` |
| `cheat.sentry_tower14_level_tax(cid[,v])` / `cheat.stables14_level_tax(cid[,v])` | Sentry tower14 / stables14 level tax via world | `cheat.sentry_tower14_level_tax(0,2)` |
| `cheat.stonecutter14_level_tax(cid[,v])` / `cheat.tailor14_level_tax(cid[,v])` | Stonecutter14 / tailor14 level tax via world | `cheat.stonecutter14_level_tax(0,2)` |
| `cheat.tannery14_level_tax(cid[,v])` / `cheat.tavern14_level_tax(cid[,v])` | Tannery14 / tavern14 level tax via world | `cheat.tannery14_level_tax(0,2)` |
| `cheat.thieves_guild14_level_tax(cid[,v])` / `cheat.toolmaker14_level_tax(cid[,v])` | Thieves guild14 / toolmaker14 level tax via world | `cheat.thieves_guild14_level_tax(0,2)` |
| `cheat.tower14_level_tax(cid[,v])` / `cheat.turner14_level_tax(cid[,v])` | Tower14 / turner14 level tax via world | `cheat.tower14_level_tax(0,2)` |
| `cheat.university15_level_tax(cid[,v])` / `cheat.university_hall14_level_tax(cid[,v])` | University15 / university hall14 level tax via world | `cheat.university15_level_tax(0,2)` |
| `cheat.vineyard14_level_tax(cid[,v])` / `cheat.vintner14_level_tax(cid[,v])` | Vineyard14 / vintner14 level tax via world | `cheat.vineyard14_level_tax(0,2)` |
| `cheat.wall15_level_tax(cid[,v])` / `cheat.warehouse14_level_tax(cid[,v])` | Wall15 / warehouse14 level tax via world | `cheat.wall15_level_tax(0,2)` |
| `cheat.warehouse15_level_tax(cid[,v])` / `cheat.weaving_mill15_level_tax(cid[,v])` | Warehouse15 / weaving mill15 level tax via world | `cheat.warehouse15_level_tax(0,2)` |
| `cheat.well15_level_tax(cid[,v])` / `cheat.town_hall16_level_tax(cid[,v])` | Well15 / town hall16 level tax via world | `cheat.well15_level_tax(0,2)` |
| `cheat.apothecary15_level_tax(cid[,v])` / `cheat.armorer15_level_tax(cid[,v])` | Apothecary15 / armorer15 level tax via world | `cheat.apothecary15_level_tax(0,2)` |
| `cheat.baker15_level_tax(cid[,v])` / `cheat.barber15_level_tax(cid[,v])` | Baker15 / barber15 level tax via world | `cheat.baker15_level_tax(0,2)` |
| `cheat.bathhouse15_level_tax(cid[,v])` / `cheat.bowyer15_level_tax(cid[,v])` | Bathhouse15 / bowyer15 level tax via world | `cheat.bathhouse15_level_tax(0,2)` |
| `cheat.brewmaster15_level_tax(cid[,v])` / `cheat.brickmaker15_level_tax(cid[,v])` | Brewmaster15 / brickmaker15 level tax via world | `cheat.brewmaster15_level_tax(0,2)` |
| `cheat.bridge15_level_tax(cid[,v])` / `cheat.brothel15_level_tax(cid[,v])` | Bridge15 / brothel15 level tax via world | `cheat.bridge15_level_tax(0,2)` |
| `cheat.butcher15_level_tax(cid[,v])` / `cheat.candlemaker15_level_tax(cid[,v])` | Butcher15 / candlemaker15 level tax via world | `cheat.butcher15_level_tax(0,2)` |
| `cheat.carpenter15_level_tax(cid[,v])` / `cheat.cartwright15_level_tax(cid[,v])` | Carpenter15 / cartwright15 level tax via world | `cheat.carpenter15_level_tax(0,2)` |
| `cheat.castle15_level_tax(cid[,v])` / `cheat.cathedral15_level_tax(cid[,v])` | Castle15 / cathedral15 level tax via world | `cheat.castle15_level_tax(0,2)` |
| `cheat.chandler15_level_tax(cid[,v])` / `cheat.chapel15_level_tax(cid[,v])` | Chandler15 / chapel15 level tax via world | `cheat.chandler15_level_tax(0,2)` |
| `cheat.charcoal15_level_tax(cid[,v])` / `cheat.church15_level_tax(cid[,v])` | Charcoal15 / church15 level tax via world | `cheat.charcoal15_level_tax(0,2)` |
| `cheat.cobbler15_level_tax(cid[,v])` / `cheat.contor15_level_tax(cid[,v])` | Cobbler15 / contor15 level tax via world | `cheat.cobbler15_level_tax(0,2)` |
| `cheat.cook15_level_tax(cid[,v])` / `cheat.cooper15_level_tax(cid[,v])` | Cook15 / cooper15 level tax via world | `cheat.cook15_level_tax(0,2)` |
| `cheat.courthouse15_level_tax(cid[,v])` / `cheat.dairy15_level_tax(cid[,v])` | Courthouse15 / dairy15 level tax via world | `cheat.courthouse15_level_tax(0,2)` |
| `cheat.dice_house15_level_tax(cid[,v])` / `cheat.distiller15_level_tax(cid[,v])` | Dice house15 / distiller15 level tax via world | `cheat.dice_house15_level_tax(0,2)` |
| `cheat.dyer15_level_tax(cid[,v])` / `cheat.fishery15_level_tax(cid[,v])` | Dyer15 / fishery15 level tax via world | `cheat.dyer15_level_tax(0,2)` |
| `cheat.forum15_level_tax(cid[,v])` / `cheat.fowler15_level_tax(cid[,v])` | Forum15 / fowler15 level tax via world | `cheat.forum15_level_tax(0,2)` |
| `cheat.furrier15_level_tax(cid[,v])` / `cheat.garrison15_level_tax(cid[,v])` | Furrier15 / garrison15 level tax via world | `cheat.furrier15_level_tax(0,2)` |
| `cheat.gates15_level_tax(cid[,v])` / `cheat.glassblower15_level_tax(cid[,v])` | Gates15 / glassblower15 level tax via world | `cheat.gates15_level_tax(0,2)` |
| `cheat.goldbeater15_level_tax(cid[,v])` / `cheat.goldsmith15_level_tax(cid[,v])` | Goldbeater15 / goldsmith15 level tax via world | `cheat.goldbeater15_level_tax(0,2)` |
| `cheat.granary15_level_tax(cid[,v])` / `cheat.guardhouse15_level_tax(cid[,v])` | Granary15 / guardhouse15 level tax via world | `cheat.granary15_level_tax(0,2)` |
| `cheat.guild_house15_level_tax(cid[,v])` / `cheat.harbor15_level_tax(cid[,v])` | Guild house15 / harbor15 level tax via world | `cheat.guild_house15_level_tax(0,2)` |
| `cheat.harbor_dock15_level_tax(cid[,v])` / `cheat.harbor_walls15_level_tax(cid[,v])` | Harbor dock15 / harbor walls15 level tax via world | `cheat.harbor_dock15_level_tax(0,2)` |
| `cheat.herb_garden15_level_tax(cid[,v])` / `cheat.hospital15_level_tax(cid[,v])` | Herb garden15 / hospital15 level tax via world | `cheat.herb_garden15_level_tax(0,2)` |
| `cheat.house15_level_tax(cid[,v])` / `cheat.jeweler15_level_tax(cid[,v])` | House15 / jeweler15 level tax via world | `cheat.house15_level_tax(0,2)` |
| `cheat.library15_level_tax(cid[,v])` / `cheat.library_hall15_level_tax(cid[,v])` | Library15 / library hall15 level tax via world | `cheat.library15_level_tax(0,2)` |
| `cheat.market15_level_tax(cid[,v])` / `cheat.miller15_level_tax(cid[,v])` | Market15 / miller15 level tax via world | `cheat.market15_level_tax(0,2)` |
| `cheat.mine15_level_tax(cid[,v])` / `cheat.mint15_level_tax(cid[,v])` | Mine15 / mint15 level tax via world | `cheat.mine15_level_tax(0,2)` |
| `cheat.monastery15_level_tax(cid[,v])` / `cheat.papermill15_level_tax(cid[,v])` | Monastery15 / papermill15 level tax via world | `cheat.monastery15_level_tax(0,2)` |
| `cheat.perfumer15_level_tax(cid[,v])` / `cheat.potter15_level_tax(cid[,v])` | Perfumer15 / potter15 level tax via world | `cheat.perfumer15_level_tax(0,2)` |
| `cheat.pottery15_level_tax(cid[,v])` / `cheat.printing_house15_level_tax(cid[,v])` | Pottery15 / printing house15 level tax via world | `cheat.pottery15_level_tax(0,2)` |
| `cheat.ropemaker15_level_tax(cid[,v])` / `cheat.ropemaker_workshop15_level_tax(cid[,v])` | Ropemaker15 / ropemaking workshop15 level tax via world | `cheat.ropemaker15_level_tax(0,2)` |
| `cheat.saddler15_level_tax(cid[,v])` / `cheat.school15_level_tax(cid[,v])` | Saddler15 / school15 level tax via world | `cheat.saddler15_level_tax(0,2)` |
| `cheat.schoolhouse15_level_tax(cid[,v])` / `cheat.sentry_tower15_level_tax(cid[,v])` | Schoolhouse15 / sentry tower15 level tax via world | `cheat.schoolhouse15_level_tax(0,2)` |
| `cheat.stables15_level_tax(cid[,v])` / `cheat.stonecutter15_level_tax(cid[,v])` | Stables15 / stonecutter15 level tax via world | `cheat.stables15_level_tax(0,2)` |
| `cheat.tailor15_level_tax(cid[,v])` / `cheat.tannery15_level_tax(cid[,v])` | Tailor15 / tannery15 level tax via world | `cheat.tailor15_level_tax(0,2)` |
| `cheat.tavern15_level_tax(cid[,v])` / `cheat.thieves_guild15_level_tax(cid[,v])` | Tavern15 / thieves guild15 level tax via world | `cheat.tavern15_level_tax(0,2)` |
| `cheat.toolmaker15_level_tax(cid[,v])` / `cheat.tower15_level_tax(cid[,v])` | Toolmaker15 / tower15 level tax via world | `cheat.toolmaker15_level_tax(0,2)` |
| `cheat.turner15_level_tax(cid[,v])` / `cheat.university16_level_tax(cid[,v])` | Turner15 / university16 level tax via world | `cheat.turner15_level_tax(0,2)` || `cheat.turner15_level_tax(cid[,v])` / `cheat.university16_level_tax(cid[,v])` | Turner15 / university16 level tax via world | `cheat.turner15_level_tax(0,2)` |
| `cheat.university_hall15_level_tax(cid[,v])` / `cheat.vineyard15_level_tax(cid[,v])` | University hall15 / vineyard15 level tax via world | `cheat.university_hall15_level_tax(0,2)` |
| `cheat.vintner15_level_tax(cid[,v])` / `cheat.wall16_level_tax(cid[,v])` | Vintner15 / wall16 level tax via world | `cheat.vintner15_level_tax(0,2)` || `cheat.vintner15_level_tax(cid[,v])` / `cheat.wall16_level_tax(cid[,v])` | Vintner15 / wall16 level tax via world | `cheat.vintner15_level_tax(0,2)` |
| `cheat.apothecary16_level_tax(cid[,v])` / `cheat.armorer16_level_tax(cid[,v])` | Apothecary16 / armorer16 level tax via world | `cheat.apothecary16_level_tax(0,2)` |
| `cheat.baker16_level_tax(cid[,v])` / `cheat.barber16_level_tax(cid[,v])` | Baker16 / barber16 level tax via world | `cheat.baker16_level_tax(0,2)` |
| `cheat.bathhouse16_level_tax(cid[,v])` / `cheat.bowyer16_level_tax(cid[,v])` | Bathhouse16 / bowyer16 level tax via world | `cheat.bathhouse16_level_tax(0,2)` |
| `cheat.brewmaster16_level_tax(cid[,v])` / `cheat.brickmaker16_level_tax(cid[,v])` | Brewmaster16 / brickmaker16 level tax via world | `cheat.brewmaster16_level_tax(0,2)` |
| `cheat.bridge16_level_tax(cid[,v])` / `cheat.brothel16_level_tax(cid[,v])` | Bridge16 / brothel16 level tax via world | `cheat.bridge16_level_tax(0,2)` |
| `cheat.butcher16_level_tax(cid[,v])` / `cheat.candlemaker16_level_tax(cid[,v])` | Butcher16 / candlemaker16 level tax via world | `cheat.butcher16_level_tax(0,2)` |
| `cheat.carpenter16_level_tax(cid[,v])` / `cheat.cartwright16_level_tax(cid[,v])` | Carpenter16 / cartwright16 level tax via world | `cheat.carpenter16_level_tax(0,2)` |
| `cheat.castle16_level_tax(cid[,v])` / `cheat.cathedral16_level_tax(cid[,v])` | Castle16 / cathedral16 level tax via world | `cheat.castle16_level_tax(0,2)` |
| `cheat.chandler16_level_tax(cid[,v])` / `cheat.chapel16_level_tax(cid[,v])` | Chandler16 / chapel16 level tax via world | `cheat.chandler16_level_tax(0,2)` |
| `cheat.charcoal16_level_tax(cid[,v])` / `cheat.church16_level_tax(cid[,v])` | Charcoal16 / church16 level tax via world | `cheat.charcoal16_level_tax(0,2)` |
| `cheat.cobbler16_level_tax(cid[,v])` / `cheat.contor16_level_tax(cid[,v])` | Cobbler16 / contor16 level tax via world | `cheat.cobbler16_level_tax(0,2)` |
| `cheat.cook16_level_tax(cid[,v])` / `cheat.cooper16_level_tax(cid[,v])` | Cook16 / cooper16 level tax via world | `cheat.cook16_level_tax(0,2)` |
| `cheat.courthouse16_level_tax(cid[,v])` / `cheat.dairy16_level_tax(cid[,v])` | Courthouse16 / dairy16 level tax via world | `cheat.courthouse16_level_tax(0,2)` |
| `cheat.dice_house16_level_tax(cid[,v])` / `cheat.distiller16_level_tax(cid[,v])` | Dice house16 / distiller16 level tax via world | `cheat.dice_house16_level_tax(0,2)` |
| `cheat.dyer16_level_tax(cid[,v])` / `cheat.fishery16_level_tax(cid[,v])` | Dyer16 / fishery16 level tax via world | `cheat.dyer16_level_tax(0,2)` |
| `cheat.forum16_level_tax(cid[,v])` / `cheat.fowler16_level_tax(cid[,v])` | Forum16 / fowler16 level tax via world | `cheat.forum16_level_tax(0,2)` |
| `cheat.furrier16_level_tax(cid[,v])` / `cheat.garrison16_level_tax(cid[,v])` | Furrier16 / garrison16 level tax via world | `cheat.furrier16_level_tax(0,2)` |
| `cheat.gates16_level_tax(cid[,v])` / `cheat.glassblower16_level_tax(cid[,v])` | Gates16 / glassblower16 level tax via world | `cheat.gates16_level_tax(0,2)` |
| `cheat.goldbeater16_level_tax(cid[,v])` / `cheat.goldsmith16_level_tax(cid[,v])` | Goldbeater16 / goldsmith16 level tax via world | `cheat.goldbeater16_level_tax(0,2)` |
| `cheat.granary16_level_tax(cid[,v])` / `cheat.guardhouse16_level_tax(cid[,v])` | Granary16 / guardhouse16 level tax via world | `cheat.granary16_level_tax(0,2)` |
| `cheat.guild_house16_level_tax(cid[,v])` / `cheat.harbor16_level_tax(cid[,v])` | Guild house16 / harbor16 level tax via world | `cheat.guild_house16_level_tax(0,2)` |
| `cheat.harbor_dock16_level_tax(cid[,v])` / `cheat.harbor_walls16_level_tax(cid[,v])` | Harbor dock16 / harbor walls16 level tax via world | `cheat.harbor_dock16_level_tax(0,2)` |
| `cheat.herb_garden16_level_tax(cid[,v])` / `cheat.hospital16_level_tax(cid[,v])` | Herb garden16 / hospital16 level tax via world | `cheat.herb_garden16_level_tax(0,2)` |
| `cheat.house16_level_tax(cid[,v])` / `cheat.jeweler16_level_tax(cid[,v])` | House16 / jeweler16 level tax via world | `cheat.house16_level_tax(0,2)` |
| `cheat.library16_level_tax(cid[,v])` / `cheat.library_hall16_level_tax(cid[,v])` | Library16 / library hall16 level tax via world | `cheat.library16_level_tax(0,2)` |
| `cheat.market16_level_tax(cid[,v])` / `cheat.miller16_level_tax(cid[,v])` | Market16 / miller16 level tax via world | `cheat.market16_level_tax(0,2)` |
| `cheat.mine16_level_tax(cid[,v])` / `cheat.mint16_level_tax(cid[,v])` | Mine16 / mint16 level tax via world | `cheat.mine16_level_tax(0,2)` |
| `cheat.monastery16_level_tax(cid[,v])` / `cheat.papermill16_level_tax(cid[,v])` | Monastery16 / papermill16 level tax via world | `cheat.monastery16_level_tax(0,2)` |
| `cheat.perfumer16_level_tax(cid[,v])` / `cheat.potter16_level_tax(cid[,v])` | Perfumer16 / potter16 level tax via world | `cheat.perfumer16_level_tax(0,2)` |
| `cheat.pottery16_level_tax(cid[,v])` / `cheat.printing_house16_level_tax(cid[,v])` | Pottery16 / printing house16 level tax via world | `cheat.pottery16_level_tax(0,2)` |
| `cheat.ropemaker16_level_tax(cid[,v])` / `cheat.ropemaker_workshop16_level_tax(cid[,v])` | Ropemaker16 / ropemaking workshop16 level tax via world | `cheat.ropemaker16_level_tax(0,2)` |
| `cheat.saddler16_level_tax(cid[,v])` / `cheat.school16_level_tax(cid[,v])` | Saddler16 / school16 level tax via world | `cheat.saddler16_level_tax(0,2)` |
| `cheat.schoolhouse16_level_tax(cid[,v])` / `cheat.sentry_tower16_level_tax(cid[,v])` | Schoolhouse16 / sentry tower16 level tax via world | `cheat.schoolhouse16_level_tax(0,2)` |
| `cheat.stables16_level_tax(cid[,v])` / `cheat.stonecutter16_level_tax(cid[,v])` | Stables16 / stonecutter16 level tax via world | `cheat.stables16_level_tax(0,2)` |
| `cheat.tailor16_level_tax(cid[,v])` / `cheat.tannery16_level_tax(cid[,v])` | Tailor16 / tannery16 level tax via world | `cheat.tailor16_level_tax(0,2)` |
| `cheat.tavern16_level_tax(cid[,v])` / `cheat.thieves_guild16_level_tax(cid[,v])` | Tavern16 / thieves guild16 level tax via world | `cheat.tavern16_level_tax(0,2)` |
| `cheat.toolmaker16_level_tax(cid[,v])` / `cheat.tower16_level_tax(cid[,v])` | Toolmaker16 / tower16 level tax via world | `cheat.toolmaker16_level_tax(0,2)` |
| `cheat.turner16_level_tax(cid[,v])` / `cheat.university_hall16_level_tax(cid[,v])` | Turner16 / university hall16 level tax via world | `cheat.turner16_level_tax(0,2)` |
| `cheat.vineyard16_level_tax(cid[,v])` / `cheat.vintner16_level_tax(cid[,v])` | Vineyard16 / vintner16 level tax via world | `cheat.vineyard16_level_tax(0,2)` |
| `cheat.wall17_level_tax(cid[,v])` / `cheat.warehouse16_level_tax(cid[,v])` | Wall17 / warehouse16 level tax via world | `cheat.wall17_level_tax(0,2)` |
| `cheat.weaving_mill16_level_tax(cid[,v])` / `cheat.well16_level_tax(cid[,v])` | Weaving mill16 / well16 level tax via world | `cheat.weaving_mill16_level_tax(0,2)` |
| `cheat.armorer17_level_tax(cid[,v])` / `cheat.baker17_level_tax(cid[,v])` | Armorer17 / baker17 level tax via world | `cheat.armorer17_level_tax(0,2)` |
| `cheat.barber17_level_tax(cid[,v])` / `cheat.bathhouse17_level_tax(cid[,v])` | Barber17 / bathhouse17 level tax via world | `cheat.barber17_level_tax(0,2)` |
| `cheat.bowyer17_level_tax(cid[,v])` / `cheat.brewmaster17_level_tax(cid[,v])` | Bowyer17 / brewmaster17 level tax via world | `cheat.bowyer17_level_tax(0,2)` |
| `cheat.brickmaker17_level_tax(cid[,v])` / `cheat.bridge17_level_tax(cid[,v])` | Brickmaker17 / bridge17 level tax via world | `cheat.brickmaker17_level_tax(0,2)` |
| `cheat.brothel17_level_tax(cid[,v])` / `cheat.butcher17_level_tax(cid[,v])` | Brothel17 / butcher17 level tax via world | `cheat.brothel17_level_tax(0,2)` |
| `cheat.candlemaker17_level_tax(cid[,v])` / `cheat.carpenter17_level_tax(cid[,v])` | Candlemaker17 / carpenter17 level tax via world | `cheat.candlemaker17_level_tax(0,2)` |
| `cheat.cartwright17_level_tax(cid[,v])` / `cheat.castle17_level_tax(cid[,v])` | Cartwright17 / castle17 level tax via world | `cheat.cartwright17_level_tax(0,2)` |
| `cheat.cathedral17_level_tax(cid[,v])` / `cheat.chandler17_level_tax(cid[,v])` | Cathedral17 / chandler17 level tax via world | `cheat.cathedral17_level_tax(0,2)` |
| `cheat.chapel17_level_tax(cid[,v])` / `cheat.charcoal17_level_tax(cid[,v])` | Chapel17 / charcoal17 level tax via world | `cheat.chapel17_level_tax(0,2)` |
| `cheat.church17_level_tax(cid[,v])` / `cheat.cobbler17_level_tax(cid[,v])` | Church17 / cobbler17 level tax via world | `cheat.church17_level_tax(0,2)` |
| `cheat.contor17_level_tax(cid[,v])` / `cheat.cook17_level_tax(cid[,v])` | Contor17 / cook17 level tax via world | `cheat.contor17_level_tax(0,2)` |
| `cheat.cooper17_level_tax(cid[,v])` / `cheat.courthouse17_level_tax(cid[,v])` | Cooper17 / courthouse17 level tax via world | `cheat.cooper17_level_tax(0,2)` |
| `cheat.dairy17_level_tax(cid[,v])` / `cheat.dice_house17_level_tax(cid[,v])` | Dairy17 / dice house17 level tax via world | `cheat.dairy17_level_tax(0,2)` |
| `cheat.distiller17_level_tax(cid[,v])` / `cheat.dyer17_level_tax(cid[,v])` | Distiller17 / dyer17 level tax via world | `cheat.distiller17_level_tax(0,2)` |
| `cheat.fishery17_level_tax(cid[,v])` / `cheat.forum17_level_tax(cid[,v])` | Fishery17 / forum17 level tax via world | `cheat.fishery17_level_tax(0,2)` |
| `cheat.fowler17_level_tax(cid[,v])` / `cheat.furrier17_level_tax(cid[,v])` | Fowler17 / furrier17 level tax via world | `cheat.fowler17_level_tax(0,2)` |
| `cheat.garrison17_level_tax(cid[,v])` / `cheat.gates17_level_tax(cid[,v])` | Garrison17 / gates17 level tax via world | `cheat.garrison17_level_tax(0,2)` |
| `cheat.glassblower17_level_tax(cid[,v])` / `cheat.goldbeater17_level_tax(cid[,v])` | Glassblower17 / goldbeater17 level tax via world | `cheat.glassblower17_level_tax(0,2)` |
| `cheat.goldsmith17_level_tax(cid[,v])` / `cheat.granary17_level_tax(cid[,v])` | Goldsmith17 / granary17 level tax via world | `cheat.goldsmith17_level_tax(0,2)` |
| `cheat.guardhouse17_level_tax(cid[,v])` / `cheat.guild_house17_level_tax(cid[,v])` | Guardhouse17 / guild house17 level tax via world | `cheat.guardhouse17_level_tax(0,2)` |
| `cheat.harbor17_level_tax(cid[,v])` / `cheat.harbor_dock17_level_tax(cid[,v])` | Harbor17 / harbor dock17 level tax via world | `cheat.harbor17_level_tax(0,2)` |
| `cheat.harbor_walls17_level_tax(cid[,v])` / `cheat.herb_garden17_level_tax(cid[,v])` | Harbor walls17 / herb garden17 level tax via world | `cheat.harbor_walls17_level_tax(0,2)` |
| `cheat.hospital17_level_tax(cid[,v])` / `cheat.house17_level_tax(cid[,v])` | Hospital17 / house17 level tax via world | `cheat.hospital17_level_tax(0,2)` |
| `cheat.jeweler17_level_tax(cid[,v])` / `cheat.library17_level_tax(cid[,v])` | Jeweler17 / library17 level tax via world | `cheat.jeweler17_level_tax(0,2)` |
| `cheat.library_hall17_level_tax(cid[,v])` / `cheat.market17_level_tax(cid[,v])` | Library hall17 / market17 level tax via world | `cheat.library_hall17_level_tax(0,2)` |
| `cheat.miller17_level_tax(cid[,v])` / `cheat.mine17_level_tax(cid[,v])` | Miller17 / mine17 level tax via world | `cheat.miller17_level_tax(0,2)` |
| `cheat.mint17_level_tax(cid[,v])` / `cheat.monastery17_level_tax(cid[,v])` | Mint17 / monastery17 level tax via world | `cheat.mint17_level_tax(0,2)` |
| `cheat.papermill17_level_tax(cid[,v])` / `cheat.perfumer17_level_tax(cid[,v])` | Papermill17 / perfumer17 level tax via world | `cheat.papermill17_level_tax(0,2)` |
| `cheat.potter17_level_tax(cid[,v])` / `cheat.pottery17_level_tax(cid[,v])` | Potter17 / pottery17 level tax via world | `cheat.potter17_level_tax(0,2)` |
| `cheat.printing_house17_level_tax(cid[,v])` / `cheat.ropemaker17_level_tax(cid[,v])` | Printing house17 / ropemaker17 level tax via world | `cheat.printing_house17_level_tax(0,2)` |
| `cheat.ropemaker_workshop17_level_tax(cid[,v])` / `cheat.saddler17_level_tax(cid[,v])` | Ropemaking workshop17 / saddler17 level tax via world | `cheat.ropemaker_workshop17_level_tax(0,2)` |
| `cheat.school17_level_tax(cid[,v])` / `cheat.schoolhouse17_level_tax(cid[,v])` | School17 / schoolhouse17 level tax via world | `cheat.school17_level_tax(0,2)` |
| `cheat.sentry_tower17_level_tax(cid[,v])` / `cheat.stables17_level_tax(cid[,v])` | Sentry tower17 / stables17 level tax via world | `cheat.sentry_tower17_level_tax(0,2)` |
| `cheat.stonecutter17_level_tax(cid[,v])` / `cheat.tailor17_level_tax(cid[,v])` | Stonecutter17 / tailor17 level tax via world | `cheat.stonecutter17_level_tax(0,2)` |
| `cheat.tannery17_level_tax(cid[,v])` / `cheat.tavern17_level_tax(cid[,v])` | Tannery17 / tavern17 level tax via world | `cheat.tannery17_level_tax(0,2)` |
| `cheat.thieves_guild17_level_tax(cid[,v])` / `cheat.toolmaker17_level_tax(cid[,v])` | Thieves guild17 / toolmaker17 level tax via world | `cheat.thieves_guild17_level_tax(0,2)` |
| `cheat.tower17_level_tax(cid[,v])` / `cheat.turner17_level_tax(cid[,v])` | Tower17 / turner17 level tax via world | `cheat.tower17_level_tax(0,2)` |
| `cheat.university17_level_tax(cid[,v])` / `cheat.university_hall17_level_tax(cid[,v])` | University17 / university hall17 level tax via world | `cheat.university17_level_tax(0,2)` |
| `cheat.vineyard17_level_tax(cid[,v])` / `cheat.vintner17_level_tax(cid[,v])` | Vineyard17 / vintner17 level tax via world | `cheat.vineyard17_level_tax(0,2)` |
| `cheat.wall18_level_tax(cid[,v])` / `cheat.warehouse17_level_tax(cid[,v])` | Wall18 / warehouse17 level tax via world | `cheat.wall18_level_tax(0,2)` |
| `cheat.weaving_mill17_level_tax(cid[,v])` / `cheat.well17_level_tax(cid[,v])` | Weaving mill17 / well17 level tax via world | `cheat.weaving_mill17_level_tax(0,2)` |
| `cheat.armorer18_level_tax(cid[,v])` / `cheat.baker18_level_tax(cid[,v])` | Armorer18 / baker18 level tax via world | `cheat.armorer18_level_tax(0,2)` |
| `cheat.barber18_level_tax(cid[,v])` / `cheat.bathhouse18_level_tax(cid[,v])` | Barber18 / bathhouse18 level tax via world | `cheat.barber18_level_tax(0,2)` |
| `cheat.bowyer18_level_tax(cid[,v])` / `cheat.brewmaster18_level_tax(cid[,v])` | Bowyer18 / brewmaster18 level tax via world | `cheat.bowyer18_level_tax(0,2)` |
| `cheat.brickmaker18_level_tax(cid[,v])` / `cheat.bridge18_level_tax(cid[,v])` | Brickmaker18 / bridge18 level tax via world | `cheat.brickmaker18_level_tax(0,2)` |
| `cheat.brothel18_level_tax(cid[,v])` / `cheat.butcher18_level_tax(cid[,v])` | Brothel18 / butcher18 level tax via world | `cheat.brothel18_level_tax(0,2)` |
| `cheat.candlemaker18_level_tax(cid[,v])` / `cheat.carpenter18_level_tax(cid[,v])` | Candlemaker18 / carpenter18 level tax via world | `cheat.candlemaker18_level_tax(0,2)` |
| `cheat.cartwright18_level_tax(cid[,v])` / `cheat.castle18_level_tax(cid[,v])` | Cartwright18 / castle18 level tax via world | `cheat.cartwright18_level_tax(0,2)` |
| `cheat.cathedral18_level_tax(cid[,v])` / `cheat.chandler18_level_tax(cid[,v])` | Cathedral18 / chandler18 level tax via world | `cheat.cathedral18_level_tax(0,2)` |
| `cheat.chapel18_level_tax(cid[,v])` / `cheat.charcoal18_level_tax(cid[,v])` | Chapel18 / charcoal18 level tax via world | `cheat.chapel18_level_tax(0,2)` |
| `cheat.church18_level_tax(cid[,v])` / `cheat.cobbler18_level_tax(cid[,v])` | Church18 / cobbler18 level tax via world | `cheat.church18_level_tax(0,2)` |
| `cheat.contor18_level_tax(cid[,v])` / `cheat.cook18_level_tax(cid[,v])` | Contor18 / cook18 level tax via world | `cheat.contor18_level_tax(0,2)` |
| `cheat.cooper18_level_tax(cid[,v])` / `cheat.courthouse18_level_tax(cid[,v])` | Cooper18 / courthouse18 level tax via world | `cheat.cooper18_level_tax(0,2)` |
| `cheat.dairy18_level_tax(cid[,v])` / `cheat.dice_house18_level_tax(cid[,v])` | Dairy18 / dice house18 level tax via world | `cheat.dairy18_level_tax(0,2)` |
| `cheat.distiller18_level_tax(cid[,v])` / `cheat.dyer18_level_tax(cid[,v])` | Distiller18 / dyer18 level tax via world | `cheat.distiller18_level_tax(0,2)` |
| `cheat.fishery18_level_tax(cid[,v])` / `cheat.forum18_level_tax(cid[,v])` | Fishery18 / forum18 level tax via world | `cheat.fishery18_level_tax(0,2)` |
| `cheat.fowler18_level_tax(cid[,v])` / `cheat.furrier18_level_tax(cid[,v])` | Fowler18 / furrier18 level tax via world | `cheat.fowler18_level_tax(0,2)` |
| `cheat.garrison18_level_tax(cid[,v])` / `cheat.gates18_level_tax(cid[,v])` | Garrison18 / gates18 level tax via world | `cheat.garrison18_level_tax(0,2)` |
| `cheat.glassblower18_level_tax(cid[,v])` / `cheat.goldbeater18_level_tax(cid[,v])` | Glassblower18 / goldbeater18 level tax via world | `cheat.glassblower18_level_tax(0,2)` |
| `cheat.goldsmith18_level_tax(cid[,v])` / `cheat.granary18_level_tax(cid[,v])` | Goldsmith18 / granary18 level tax via world | `cheat.goldsmith18_level_tax(0,2)` |
| `cheat.guardhouse18_level_tax(cid[,v])` / `cheat.guild_house18_level_tax(cid[,v])` | Guardhouse18 / guild house18 level tax via world | `cheat.guardhouse18_level_tax(0,2)` |
| `cheat.harbor18_level_tax(cid[,v])` / `cheat.harbor_dock18_level_tax(cid[,v])` | Harbor18 / harbor dock18 level tax via world | `cheat.harbor18_level_tax(0,2)` |
| `cheat.harbor_walls18_level_tax(cid[,v])` / `cheat.herb_garden18_level_tax(cid[,v])` | Harbor walls18 / herb garden18 level tax via world | `cheat.harbor_walls18_level_tax(0,2)` |
| `cheat.hospital18_level_tax(cid[,v])` / `cheat.house18_level_tax(cid[,v])` | Hospital18 / house18 level tax via world | `cheat.hospital18_level_tax(0,2)` |
| `cheat.jeweler18_level_tax(cid[,v])` / `cheat.library18_level_tax(cid[,v])` | Jeweler18 / library18 level tax via world | `cheat.jeweler18_level_tax(0,2)` |
| `cheat.library_hall18_level_tax(cid[,v])` / `cheat.market18_level_tax(cid[,v])` | Library hall18 / market18 level tax via world | `cheat.library_hall18_level_tax(0,2)` |
| `cheat.miller18_level_tax(cid[,v])` / `cheat.mine18_level_tax(cid[,v])` | Miller18 / mine18 level tax via world | `cheat.miller18_level_tax(0,2)` |
| `cheat.mint18_level_tax(cid[,v])` / `cheat.monastery18_level_tax(cid[,v])` | Mint18 / monastery18 level tax via world | `cheat.mint18_level_tax(0,2)` |
| `cheat.papermill18_level_tax(cid[,v])` / `cheat.perfumer18_level_tax(cid[,v])` | Papermill18 / perfumer18 level tax via world | `cheat.papermill18_level_tax(0,2)` |
| `cheat.potter18_level_tax(cid[,v])` / `cheat.pottery18_level_tax(cid[,v])` | Potter18 / pottery18 level tax via world | `cheat.potter18_level_tax(0,2)` |
| `cheat.printing_house18_level_tax(cid[,v])` / `cheat.ropemaker18_level_tax(cid[,v])` | Printing house18 / ropemaker18 level tax via world | `cheat.printing_house18_level_tax(0,2)` |
| `cheat.ropemaker_workshop18_level_tax(cid[,v])` / `cheat.saddler18_level_tax(cid[,v])` | Ropemaking workshop18 / saddler18 level tax via world | `cheat.ropemaker_workshop18_level_tax(0,2)` |
| `cheat.school18_level_tax(cid[,v])` / `cheat.schoolhouse18_level_tax(cid[,v])` | School18 / schoolhouse18 level tax via world | `cheat.school18_level_tax(0,2)` |
| `cheat.sentry_tower18_level_tax(cid[,v])` / `cheat.stables18_level_tax(cid[,v])` | Sentry tower18 / stables18 level tax via world | `cheat.sentry_tower18_level_tax(0,2)` |
| `cheat.stonecutter18_level_tax(cid[,v])` / `cheat.tailor18_level_tax(cid[,v])` | Stonecutter18 / tailor18 level tax via world | `cheat.stonecutter18_level_tax(0,2)` |
| `cheat.tannery18_level_tax(cid[,v])` / `cheat.tavern18_level_tax(cid[,v])` | Tannery18 / tavern18 level tax via world | `cheat.tannery18_level_tax(0,2)` |
| `cheat.thieves_guild18_level_tax(cid[,v])` / `cheat.toolmaker18_level_tax(cid[,v])` | Thieves guild18 / toolmaker18 level tax via world | `cheat.thieves_guild18_level_tax(0,2)` |
| `cheat.tower18_level_tax(cid[,v])` / `cheat.turner18_level_tax(cid[,v])` | Tower18 / turner18 level tax via world | `cheat.tower18_level_tax(0,2)` |
| `cheat.university_hall18_level_tax(cid[,v])` / `cheat.vineyard18_level_tax(cid[,v])` | University hall18 / vineyard18 level tax via world | `cheat.university_hall18_level_tax(0,2)` |
| `cheat.vintner18_level_tax(cid[,v])` / `cheat.warehouse18_level_tax(cid[,v])` | Vintner18 / warehouse18 level tax via world | `cheat.vintner18_level_tax(0,2)` |
| `cheat.weaving_mill18_level_tax(cid[,v])` / `cheat.well18_level_tax(cid[,v])` | Weaving mill18 / well18 level tax via world | `cheat.weaving_mill18_level_tax(0,2)` |
| `cheat.armorer19_level_tax(cid[,v])` / `cheat.baker19_level_tax(cid[,v])` | Armorer19 / baker19 level tax via world | `cheat.armorer19_level_tax(0,2)` |
| `cheat.barber19_level_tax(cid[,v])` / `cheat.bathhouse19_level_tax(cid[,v])` | Barber19 / bathhouse19 level tax via world | `cheat.barber19_level_tax(0,2)` |
| `cheat.bowyer19_level_tax(cid[,v])` / `cheat.brewmaster19_level_tax(cid[,v])` | Bowyer19 / brewmaster19 level tax via world | `cheat.bowyer19_level_tax(0,2)` |
| `cheat.brickmaker19_level_tax(cid[,v])` / `cheat.bridge19_level_tax(cid[,v])` | Brickmaker19 / bridge19 level tax via world | `cheat.brickmaker19_level_tax(0,2)` |
| `cheat.brothel19_level_tax(cid[,v])` / `cheat.butcher19_level_tax(cid[,v])` | Brothel19 / butcher19 level tax via world | `cheat.brothel19_level_tax(0,2)` |
| `cheat.candlemaker19_level_tax(cid[,v])` / `cheat.carpenter19_level_tax(cid[,v])` | Candlemaker19 / carpenter19 level tax via world | `cheat.candlemaker19_level_tax(0,2)` |
| `cheat.cartwright19_level_tax(cid[,v])` / `cheat.castle19_level_tax(cid[,v])` | Cartwright19 / castle19 level tax via world | `cheat.cartwright19_level_tax(0,2)` |
| `cheat.cathedral19_level_tax(cid[,v])` / `cheat.chandler19_level_tax(cid[,v])` | Cathedral19 / chandler19 level tax via world | `cheat.cathedral19_level_tax(0,2)` |
| `cheat.chapel19_level_tax(cid[,v])` / `cheat.charcoal19_level_tax(cid[,v])` | Chapel19 / charcoal19 level tax via world | `cheat.chapel19_level_tax(0,2)` |
| `cheat.church19_level_tax(cid[,v])` / `cheat.cobbler19_level_tax(cid[,v])` | Church19 / cobbler19 level tax via world | `cheat.church19_level_tax(0,2)` |
| `cheat.contor19_level_tax(cid[,v])` / `cheat.cook19_level_tax(cid[,v])` | Contor19 / cook19 level tax via world | `cheat.contor19_level_tax(0,2)` |
| `cheat.cooper19_level_tax(cid[,v])` / `cheat.courthouse19_level_tax(cid[,v])` | Cooper19 / courthouse19 level tax via world | `cheat.cooper19_level_tax(0,2)` |
| `cheat.dairy19_level_tax(cid[,v])` / `cheat.dice_house19_level_tax(cid[,v])` | Dairy19 / dice house19 level tax via world | `cheat.dairy19_level_tax(0,2)` |
| `cheat.distiller19_level_tax(cid[,v])` / `cheat.dyer19_level_tax(cid[,v])` | Distiller19 / dyer19 level tax via world | `cheat.distiller19_level_tax(0,2)` |
| `cheat.fishery19_level_tax(cid[,v])` / `cheat.forum19_level_tax(cid[,v])` | Fishery19 / forum19 level tax via world | `cheat.fishery19_level_tax(0,2)` |
| `cheat.fowler19_level_tax(cid[,v])` / `cheat.furrier19_level_tax(cid[,v])` | Fowler19 / furrier19 level tax via world | `cheat.fowler19_level_tax(0,2)` |
| `cheat.garrison19_level_tax(cid[,v])` / `cheat.gates19_level_tax(cid[,v])` | Garrison19 / gates19 level tax via world | `cheat.garrison19_level_tax(0,2)` |
| `cheat.glassblower19_level_tax(cid[,v])` / `cheat.goldbeater19_level_tax(cid[,v])` | Glassblower19 / goldbeater19 level tax via world | `cheat.glassblower19_level_tax(0,2)` |
| `cheat.goldsmith19_level_tax(cid[,v])` / `cheat.granary19_level_tax(cid[,v])` | Goldsmith19 / granary19 level tax via world | `cheat.goldsmith19_level_tax(0,2)` |
| `cheat.guardhouse19_level_tax(cid[,v])` / `cheat.guild_house19_level_tax(cid[,v])` | Guardhouse19 / guild house19 level tax via world | `cheat.guardhouse19_level_tax(0,2)` |
| `cheat.harbor19_level_tax(cid[,v])` / `cheat.harbor_dock19_level_tax(cid[,v])` | Harbor19 / harbor dock19 level tax via world | `cheat.harbor19_level_tax(0,2)` |
| `cheat.harbor_walls19_level_tax(cid[,v])` / `cheat.herb_garden19_level_tax(cid[,v])` | Harbor walls19 / herb garden19 level tax via world | `cheat.harbor_walls19_level_tax(0,2)` |
| `cheat.hospital19_level_tax(cid[,v])` / `cheat.house19_level_tax(cid[,v])` | Hospital19 / house19 level tax via world | `cheat.hospital19_level_tax(0,2)` |
| `cheat.jeweler19_level_tax(cid[,v])` / `cheat.library19_level_tax(cid[,v])` | Jeweler19 / library19 level tax via world | `cheat.jeweler19_level_tax(0,2)` |
| `cheat.library_hall19_level_tax(cid[,v])` / `cheat.market19_level_tax(cid[,v])` | Library hall19 / market19 level tax via world | `cheat.library_hall19_level_tax(0,2)` |
| `cheat.miller19_level_tax(cid[,v])` / `cheat.mine19_level_tax(cid[,v])` | Miller19 / mine19 level tax via world | `cheat.miller19_level_tax(0,2)` |
| `cheat.mint19_level_tax(cid[,v])` / `cheat.monastery19_level_tax(cid[,v])` | Mint19 / monastery19 level tax via world | `cheat.mint19_level_tax(0,2)` |
| `cheat.papermill19_level_tax(cid[,v])` / `cheat.perfumer19_level_tax(cid[,v])` | Papermill19 / perfumer19 level tax via world | `cheat.papermill19_level_tax(0,2)` |
| `cheat.potter19_level_tax(cid[,v])` / `cheat.pottery19_level_tax(cid[,v])` | Potter19 / pottery19 level tax via world | `cheat.potter19_level_tax(0,2)` |
| `cheat.printing_house19_level_tax(cid[,v])` / `cheat.ropemaker19_level_tax(cid[,v])` | Printing house19 / ropemaker19 level tax via world | `cheat.printing_house19_level_tax(0,2)` |
| `cheat.ropemaker_workshop19_level_tax(cid[,v])` / `cheat.saddler19_level_tax(cid[,v])` | Ropemaking workshop19 / saddler19 level tax via world | `cheat.ropemaker_workshop19_level_tax(0,2)` |
| `cheat.school19_level_tax(cid[,v])` / `cheat.schoolhouse19_level_tax(cid[,v])` | School19 / schoolhouse19 level tax via world | `cheat.school19_level_tax(0,2)` |
| `cheat.sentry_tower19_level_tax(cid[,v])` / `cheat.stables19_level_tax(cid[,v])` | Sentry tower19 / stables19 level tax via world | `cheat.sentry_tower19_level_tax(0,2)` |
| `cheat.stonecutter19_level_tax(cid[,v])` / `cheat.tailor19_level_tax(cid[,v])` | Stonecutter19 / tailor19 level tax via world | `cheat.stonecutter19_level_tax(0,2)` |
| `cheat.tannery19_level_tax(cid[,v])` / `cheat.tavern19_level_tax(cid[,v])` | Tannery19 / tavern19 level tax via world | `cheat.tannery19_level_tax(0,2)` |
| `cheat.thieves_guild19_level_tax(cid[,v])` / `cheat.toolmaker19_level_tax(cid[,v])` | Thieves guild19 / toolmaker19 level tax via world | `cheat.thieves_guild19_level_tax(0,2)` |
| `cheat.tower19_level_tax(cid[,v])` / `cheat.turner19_level_tax(cid[,v])` | Tower19 / turner19 level tax via world | `cheat.tower19_level_tax(0,2)` |
| `cheat.university_hall19_level_tax(cid[,v])` / `cheat.vineyard19_level_tax(cid[,v])` | University hall19 / vineyard19 level tax via world | `cheat.university_hall19_level_tax(0,2)` |
| `cheat.vintner19_level_tax(cid[,v])` / `cheat.warehouse19_level_tax(cid[,v])` | Vintner19 / warehouse19 level tax via world | `cheat.vintner19_level_tax(0,2)` |
| `cheat.weaving_mill19_level_tax(cid[,v])` / `cheat.well19_level_tax(cid[,v])` | Weaving mill19 / well19 level tax via world | `cheat.weaving_mill19_level_tax(0,2)` |
| `cheat.wall19_level_tax(cid[,v])` / `cheat.armorer20_level_tax(cid[,v])` | Wall19 / armorer20 level tax via world | `cheat.wall19_level_tax(0,2)` |
| `cheat.baker20_level_tax(cid[,v])` / `cheat.barber20_level_tax(cid[,v])` | Baker20 / barber20 level tax via world | `cheat.baker20_level_tax(0,2)` |
| `cheat.bathhouse20_level_tax(cid[,v])` / `cheat.bowyer20_level_tax(cid[,v])` | Bathhouse20 / bowyer20 level tax via world | `cheat.bathhouse20_level_tax(0,2)` |
| `cheat.brewmaster20_level_tax(cid[,v])` / `cheat.brickmaker20_level_tax(cid[,v])` | Brewmaster20 / brickmaker20 level tax via world | `cheat.brewmaster20_level_tax(0,2)` |
| `cheat.weaving_mill14_level_tax(cid[,v])` / `cheat.well14_level_tax(cid[,v])` | Weaving mill14 / well14 level tax via world | `cheat.weaving_mill14_level_tax(0,2)` |
| `cheat.armorer14_level_tax(cid[,v])` / `cheat.baker14_level_tax(cid[,v])` | Armorer14 / baker14 level tax via world | `cheat.armorer14_level_tax(0,2)` |
| `cheat.barber14_level_tax(cid[,v])` / `cheat.bathhouse14_level_tax(cid[,v])` | Barber14 / bathhouse14 level tax via world | `cheat.barber14_level_tax(0,2)` |
| `cheat.bowyer14_level_tax(cid[,v])` / `cheat.brewmaster14_level_tax(cid[,v])` | Bowyer14 / brewmaster14 level tax via world | `cheat.bowyer14_level_tax(0,2)` |
| `cheat.brickmaker14_level_tax(cid[,v])` / `cheat.bridge14_level_tax(cid[,v])` | Brickmaker14 / bridge14 level tax via world | `cheat.brickmaker14_level_tax(0,2)` |
| `cheat.brothel14_level_tax(cid[,v])` / `cheat.butcher14_level_tax(cid[,v])` | Brothel14 / butcher14 level tax via world | `cheat.brothel14_level_tax(0,2)` |
| `cheat.candlemaker14_level_tax(cid[,v])` / `cheat.carpenter14_level_tax(cid[,v])` | Candlemaker14 / carpenter14 level tax via world | `cheat.candlemaker14_level_tax(0,2)` |
| `cheat.cartwright14_level_tax(cid[,v])` / `cheat.castle14_level_tax(cid[,v])` | Cartwright14 / castle14 level tax via world | `cheat.cartwright14_level_tax(0,2)` |
| `cheat.cathedral14_level_tax(cid[,v])` / `cheat.chandler14_level_tax(cid[,v])` | Cathedral14 / chandler14 level tax via world | `cheat.cathedral14_level_tax(0,2)` |
| `cheat.chapel14_level_tax(cid[,v])` / `cheat.charcoal14_level_tax(cid[,v])` | Chapel14 / charcoal14 level tax via world | `cheat.chapel14_level_tax(0,2)` |
| `cheat.gates8_level_tax(cid[,v])` / `cheat.gates9_level_tax(cid[,v])` | Gates8 / gates9 level tax via world | `cheat.gates8_level_tax(0,2)` |
| `cheat.sentry_tower8_level_tax(cid[,v])` / `cheat.sentry_tower9_level_tax(cid[,v])` | Sentry tower8 / sentry tower9 level tax via world | `cheat.sentry_tower8_level_tax(0,2)` |
| `cheat.stables8_level_tax(cid[,v])` / `cheat.stables9_level_tax(cid[,v])` | Stables8 / stables9 level tax via world | `cheat.stables8_level_tax(0,2)` |
| `cheat.contor_tax(cid[,v])` / `cheat.dice_house_tax(cid[,v])` | Contor / dice house tax via world | `cheat.contor_tax(0,2)` |
| `cheat.thieves_guild_tax(cid[,v])` / `cheat.harbor_walls_tax3(cid[,v])` | Thieves guild / harbor walls 3 tax via world | `cheat.thieves_guild_tax(0,2)` |
| `cheat.mining_ws2(cid[,v])` / `cheat.logging_ws2(cid[,v])` | Mining ws2 / logging ws2 via world | `cheat.mining_ws2(0,2)` |
| `cheat.inn_level2(cid[,v])` / `cheat.robber_camp2(cid[,v])` | Inn2 / robber camp2 via world | `cheat.inn_level2(0,2)` |
| `cheat.jeweler_level(cid[,v])` / `cheat.perfumer_level(cid[,v])` | Jeweler / perfumer via world | `cheat.jeweler_level(0,2)` |
| `cheat.pottery(cid[,v])` / `cheat.tailor(cid[,v])` | Pottery / tailor via world | `cheat.pottery(0,2)` |
| `cheat.wall_level(cid[,v])` / `cheat.tower_level(cid[,v])` | Wall / tower via world | `cheat.wall_level(0,2)` |
| `cheat.market_level(cid[,v])` / `cheat.tavern_level(cid[,v])` | Market / tavern level via world | `cheat.market_level(0,2)` |
| `cheat.pop_limit(cid[,v])` / `cheat.growth(cid)` | Pop limit / growth via world | `cheat.pop_limit(0,1000)` |
| `cheat.apothecary(bldg,gid[,v])` / `cheat.scribe(bldg,gid[,v])` | Apothecary / scribe via building | `cheat.apothecary(bldg,0,10)` |
| `cheat.goldsmith(bldg,gid)` | Goldsmith via building | `cheat.goldsmith(bldg,0)` |
| `cheat.falconer(bldg,gid)` / `cheat.jeweler(bldg,gid[,v])` | Falconer / jeweler via building | `cheat.falconer(bldg,0)` |
| `cheat.bathhouse(bldg)` | Bathhouse income via building | `cheat.bathhouse(bldg)` |
| `cheat.perfumer(bldg,gid[,v])` / `cheat.soapmaker(bldg,gid[,v])` | Perfumer / soapmaker via building | `cheat.perfumer(bldg,0,10)` |
| `cheat.candlemaker(bldg,gid[,v])` / `cheat.papermill(bldg,gid[,v])` | Candle / papermill via building | `cheat.candlemaker(bldg,0,10)` |
| `cheat.printing(bldg,gid[,v])` / `cheat.toolmaker(bldg,gid[,v])` | Printing / toolmaker via building | `cheat.printing(bldg,0,10)` |
| `cheat.charcoal(bldg,gid[,v])` / `cheat.furrier(bldg,gid[,v])` | Charcoal / furrier via building | `cheat.charcoal(bldg,0,10)` |
| `cheat.dyer(bldg,gid[,v])` / `cheat.saddler(bldg,gid[,v])` | Dyer / saddler via building | `cheat.dyer(bldg,0,10)` |
| `cheat.armorer(bldg,gid[,v])` / `cheat.bowyer(bldg,gid[,v])` | Armorer / bowyer via building | `cheat.armorer(bldg,0,10)` |
| `cheat.cartwright(bldg,gid[,v])` / `cheat.mint_out(bldg,gid[,v])` | Cartwright / mint via building | `cheat.cartwright(bldg,0,10)` |
| `cheat.winery(bldg,gid[,v])` / `cheat.shipwright(bldg,gid[,v])` | Winery / shipwright via building | `cheat.winery(bldg,0,10)` |
| `cheat.cooper(bldg,gid[,v])` / `cheat.spinner(bldg,gid[,v])` | Cooper / spinner via building | `cheat.cooper(bldg,0,10)` |
| `cheat.turner(bldg,gid[,v])` / `cheat.barber(bldg,gid[,v])` | Turner / barber via building | `cheat.turner(bldg,0,10)` |
| `cheat.stonecutter(bldg,gid[,v])` / `cheat.tailor_master(bldg,gid[,v])` | Stonecutter / tailor master via building | `cheat.stonecutter(bldg,0,10)` |
| `cheat.cobbler(bldg,gid[,v])` / `cheat.butcher(bldg,gid[,v])` | Cobbler / butcher via building | `cheat.cobbler(bldg,0,10)` |
| `cheat.baker2(bldg,gid[,v])` / `cheat.shepherd(bldg,gid)` | Baker v2 / shepherd via building | `cheat.baker2(bldg,0,10)` |
| `cheat.dairy(bldg,gid)` / `cheat.brewmaster(bldg,gid[,v])` | Dairy / brewmaster via building | `cheat.dairy(bldg,0)` |
| `cheat.miller(bldg,gid)` / `cheat.fishery(bldg,gid)` | Miller / fishery via building | `cheat.miller(bldg,0)` |
| `cheat.joiner(bldg,gid[,v])` / `cheat.carter(bldg,gid[,v])` | Joiner / carter via building | `cheat.joiner(bldg,0,10)` |
| `cheat.mining(bldg,gid)` / `cheat.logging(bldg,gid)` | Mining / logging via building | `cheat.mining(bldg,0)` |
| `cheat.innkeeper(bldg)` / `cheat.tollmaster(bldg)` | Innkeeper / tollmaster via building | `cheat.innkeeper(bldg)` |
| `cheat.chandler(bldg,gid[,v])` / `cheat.goldbeater(bldg,gid[,v])` | Chandler / goldbeater via building | `cheat.chandler(bldg,0,10)` |
| `cheat.potter(bldg,gid[,v])` / `cheat.fowler(bldg,gid)` | Potter / fowler via building | `cheat.potter(bldg,0,10)` |
| `cheat.vintner(bldg,gid)` | Vintner via building | `cheat.vintner(bldg,0)` |
| `cheat.road_toll(cid,rid[,v])` / `cheat.church_corruption(cid[,v])` | Road toll / church corruption via world | `cheat.road_toll(0,0,10)` |
| `cheat.blacksmith(bldg,gid[,v])` | Blacksmith output via building | `cheat.blacksmith(bldg,0,10)` |
| `cheat.imperial(pid[,v])` / `cheat.tavern(pid,cid)` / `cheat.monastery(pid,cid)` | Imperial / tavern / monastery | `cheat.imperial(0, 10)` |
| `cheat.title_rank(pid,tid)` / `cheat.plague(cid[,v])` / `cheat.apprentice_slots(bldg)` | Title_rank / plague / apprentice_slots | `cheat.title_rank(0,0)` |
| `cheat.wall_cost(cid,lvl)` / `cheat.fair(cid)` / `cheat.granary(bldg)` | Wall_cost / fair / granary | `cheat.wall_cost(0,1)` |
| `cheat.baker_bonus(bldg,gid[,v])` / `cheat.master_bribe(bldg)` / `cheat.gambling_debt(pid[,v])` | Baker_bonus / master_bribe / gambling_debt | `cheat.baker_bonus(bldg,0,5)` |
| `cheat.relation(a,b[,v])` | Relation | `cheat.relation(0,1,50)` |
| `cheat.crime(pid[,lvl])` / `cheat.votes(cid,cand[,n])` / `cheat.efficiency(bldg[,pct])` | Crime / votes / workshop efficiency via civic | `cheat.crime(0, 0)` |
| `cheat.set_player_addr(addr)` | Remember player struct addr for `cheat.gold` fallback | `cheat.set_player_addr(0x12340000)` |
| `cheat.help()` | List cheats | `cheat.help()` |

One-liners composing the domain helpers. Errors name the catalog entry to register first.

## Save/State (`state.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `state.find([base,size])` | `catalog.hunt("save")`/`"state"` | `state.find()` |
| `state.scan([base,size])` | Hunt save/clock presets | `state.scan(0x400000, 0x300000)` |
| `state.save(path)` | `SaveGame` | `state.save("mysave.sav")` |
| `state.load(path)` | `LoadGame` | `state.load("mysave.sav")` |
| `state.pause([flag])` / `state.unpause()` | `PauseGame` (1/0) | `state.pause(1)` |
| `state.is_paused()` | `IsGamePaused` | `state.is_paused()` |
| `state.get()` | `GetGameState` | `state.get()` |
| `state.disease(pid)` / `social.set_disease(pid,v)` | `GetDiseaseState` / `SetDiseaseState` | `state.disease(0)` |
| `state.guard_count(cityId)` / `world.set_guard_count(cityId,v)` | `GetGuardCount` / `SetGuardCount` | `state.guard_count(0)` |
| `state.guard_morale(cityId)` / `world.set_guard_morale(cityId,v)` | `GetGuardMorale` / `SetGuardMorale` | `state.guard_morale(0)` |
| `state.drunk(pid)` / `social.set_drunk(pid,v)` | `GetDrunkLevel` / `SetDrunkLevel` | `state.drunk(0)` |
| `state.heir(pid)` | `GetHeir` | `state.heir(0)` |
| `state.arrest_warrant(pid)` / `state.issue_warrant(issuer,target)` | `GetArrestWarrant` / `IssueArrestWarrant` | `state.arrest_warrant(0)` |
| `state.bandit_threat(cityId)` | `GetBanditThreat` | `state.bandit_threat(0)` |
| `state.excommunication(pid)` / `social.set_excommunication(pid,v)` | `GetExcommunicationState` / `SetExcommunicationState` | `state.excommunication(0)` |
| `state.alliance(a,b)` | `GetAlliance` | `state.alliance(0,1)` |
| `state.ambassador(cityId)` | `GetAmbassadorLevel` | `state.ambassador(0)` |
| `state.character_trait(pid,trait)` | `GetCharacterTrait` | `state.character_trait(0,1)` |
| `state.fair(id)` | `GetCityFairState` | `state.fair(0)` |
| `state.festival_state(id)` | `GetFestivalState` | `state.festival_state(0)` |
| `state.game_speed()` / `world.set_speed(v)` | `GetGameSpeed` / `SetGameSpeed` | `state.game_speed()` |
| `state.event_state(id)` | `GetEventState` | `state.event_state(0)` |
| `state.evidence(id)` | `GetEvidenceCount` | `state.evidence(0)` |
| `state.church_corruption(cityId)` | `GetChurchCorruption` | `state.church_corruption(0)` |
| `state.crime(pid)` | `GetCrimeLevel` | `state.crime(0)` |
| `state.militia(cityId)` | `GetMilitiaCount` | `state.militia(0)` |
| `state.piety(pid)` | `GetPiety` | `state.piety(0)` |
| `state.heretic(pid)` | `GetHereticSuspicion` | `state.heretic(0)` |
| `state.inquisition(pid)` | `GetInquisitionSuspicion` | `state.inquisition(0)` |
| `state.jail_time(pid)` | `GetJailTime` | `state.jail_time(0)` |
| `state.player_age(pid)` | `GetPlayerAge` | `state.player_age(0)` |
| `state.diplomacy(a,b)` | `GetDiplomacy` | `state.diplomacy(0,1)` |
| `state.dynasty_reputation(pid)` | `GetDynastyReputation` | `state.dynasty_reputation(0)` |
| `state.player_exp(pid)` | `GetPlayerExperience` | `state.player_exp(0)` |
| `state.player_honor(pid)` | `GetPlayerHonor` | `state.player_honor(0)` |
| `state.poison(pid)` | `GetPoisonLevel` | `state.poison(0)` |
| `state.plague(cityId)` | `GetPlagueState` | `state.plague(0)` |
| `state.public_order(cityId)` | `GetPublicOrder` | `state.public_order(0)` |
| `state.reputation_decay(a,b)` | `GetReputationDecay` | `state.reputation_decay(0,1)` |
| `state.season()` | `GetSeason` | `state.season()` |
| `state.intrigue_level(a,b)` / `state.set_intrigue_level(a,b,v)` | `GetIntrigueLevel` / `SetIntrigueLevel` | `state.intrigue_level(0,1)` |
| `state.office_holder(cityId,office)` / `state.set_office_holder(cityId,office,pid)` | `GetOfficeHolder` / `SetOfficeHolder` | `state.office_holder(0,1)` |
| `state.office_term(cityId,office)` / `state.set_office_term(cityId,office,term)` | `GetOfficeTerm` / `SetOfficeTerm` | `state.office_term(0,1)` |
| `state.road_bandit_risk(cityA,cityB)` / `state.set_road_bandit_risk(cityA,cityB,risk)` | `GetRoadBanditRisk` / `SetRoadBanditRisk` | `state.road_bandit_risk(0,1)` |
| `state.election_votes(cityId,cand)` / `state.set_election_votes(cityId,cand,v)` | `GetElectionVotes` / `SetElectionVotes` | `state.election_votes(0,1)` |
| `state.privileges(pid)` | `GetPrivileges` | `state.privileges(0)` |
| `state.marriage_state(pid,partner)` | `GetMarriageState` | `state.marriage_state(0,1)` |
| `state.office_competition(cityId,office)` | `GetOfficeCompetition` | `state.office_competition(0,1)` |
| `state.patrol_strength(cityId)` / `state.set_patrol_strength(cityId,v)` | `GetPatrolStrength` / `SetPatrolStrength` | `state.patrol_strength(0)` |
| `state.kidnap_chance(a,b)` | `GetKidnapChance` | `state.kidnap_chance(0,1)` |
| `state.city_rank(cityId)` | `GetCityRank` | `state.city_rank(0)` |
| `state.city_growth(cityId)` | `GetCityGrowthRate` | `state.city_growth(0)` |
| `state.espionage(a,b)` | `GetEspionageLevel` | `state.espionage(0,1)` |
| `state.siege_progress(cityId)` | `GetSiegeProgress` | `state.siege_progress(0)` |
| `state.wall_garrison(cityId)` | `GetWallGarrisonCount` | `state.wall_garrison(0)` |
| `state.watch_strength(cityId)` | `GetWatchStrength` | `state.watch_strength(0)` |
| `state.trial_verdict(trialId)` | `GetTrialVerdict` | `state.trial_verdict(0)` |
| `state.worker_morale(bldg)` | `GetWorkerMorale` | `state.worker_morale(0)` |
| `state.dynasty_decay(pid)` | `GetDynastyPrestigeDecay` | `state.dynasty_decay(0)` |
| `state.marriage_partner(pid)` | `GetMarriagePartner` | `state.marriage_partner(0)` |
| `state.relation(a,b)` | `GetRelation` | `state.relation(0,1)` |
| `state.robber_threat(cityId)` | `GetRobberThreat` | `state.robber_threat(0)` |
| `state.spy_suspicion(a,b)` | `GetSpySuspicion` | `state.spy_suspicion(0,1)` |
| `state.tavern_brawl(cityId)` | `GetTavernBrawlChance` | `state.tavern_brawl(0)` |
| `state.time()` / `world.set_time(v)` | `GetTimeHours` / `SetTimeHours` | `state.time()` |
| `state.year()` / `world.set_year(v)` | `GetYear` / `SetYear` | `state.year()` |
| `state.broadcast_event(eventId,payload)` | `BroadcastEvent` | `state.broadcast_event(0,"")` |
| `state.divorce(pid,spouse)` | `Divorce` | `state.divorce(0,1)` |
| `state.arrest_warrant(pid)` / `state.issue_warrant(issuer,target)` | `GetArrestWarrant` / `IssueArrestWarrant` | `state.arrest_warrant(0)` |
| `state.spy_network(a,b)` | `GetSpyNetwork` | `state.spy_network(0,1)` |
| `state.diplomacy_offer(a,b,c,d,e)` | `SendDiplomacyOffer` | `state.diplomacy_offer(0,1,0,0,0)` |
| `state.player_health(pid)` / `state.set_player_health(pid,v)` | `GetPlayerHealth` / `SetPlayerHealth` | `state.player_health(0)` |
| `state.spy_info(a,b)` | `GetSpyInfo` | `state.spy_info(0,1)` |
| `state.trial_witness(trialId)` | `GetTrialWitnessCount` | `state.trial_witness(0)` |
| `state.is_bribed(a,b)` | `IsBribed` | `state.is_bribed(0,1)` |
| `state.is_besieged(cityId)` | `IsCityBesieged` | `state.is_besieged(0)` |
| `state.is_office_vacant(cityId,office)` | `IsOfficeVacant` | `state.is_office_vacant(0,1)` |
| `state.is_player_dead(pid)` | `IsPlayerDead` | `state.is_player_dead(0)` |
| `state.start_trial(accused,crime)` | `StartTrial` | `state.start_trial(0,1)` |
| `state.trigger_event(eventId,cityId)` | `TriggerEvent` | `state.trigger_event(0,0)` |

## Snapshot (`snapshot.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `snapshot.capture()` | Capture cross-domain state (time/year/gold/etc) | `local s = snapshot.capture()` |
| `snapshot.print([s])` | Pretty-print snapshot | `snapshot.print(s)` |
| `snapshot.diff(a,b)` | Diff two snapshots (what changed after action) | `snapshot.diff(a,b)` |
| `snapshot.save([path,s])` | Persist snapshot as lua table | `snapshot.save("snap1.lua", s)` |

All reads are pcall-guarded; a missing registration leaves the field nil. The default capture samples market, guild, tax, city and building fields. Set `_G._snapshot_extended = true` to also sample roughly 243 further fields across economy, court, church, city and workshop state; `snapshot.print(s)` lists whatever was actually resolved.

## Civic (`civic.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `civic.find([base,size])` | `catalog.hunt("civic")`/`"world"` | `civic.find()` |
| `civic.scan([base,size])` | Hunt civic/city/building presets | `civic.scan(0x400000, 0x300000)` |
| `civic.votes(cid,cand)` / `civic.set_votes(cid,cand,n)` | `GetElectionVotes` / `SetElectionVotes` | `civic.votes(0, 0)` |
| `civic.trial(accused,crime)` | `StartTrial` | `civic.trial(0, 1)` |
| `civic.crime(pid)` / `civic.set_crime(pid,lvl)` | `GetCrimeLevel` / `SetCrimeLevel` | `civic.crime(0)` |
| `civic.efficiency(bldg)` / `civic.set_efficiency(bldg,pct)` | `GetWorkshopEfficiency` / `SetWorkshopEfficiency` | `civic.efficiency(bldg)` |
| `civic.queue(bldg)` | `GetProductionQueue` | `civic.queue(bldg)` |
| `civic.durability(bldg)` / `civic.set_durability(bldg,v)` | `GetBuildingDurability` / `SetBuildingDurability` | `civic.durability(bldg)` |
| `civic.income(bldg)` / `civic.set_income(bldg,v)` | `GetBuildingIncome` / `SetBuildingIncome` | `civic.income(bldg)` |
| `civic.morale(id)` / `civic.set_morale(id,v)` | `GetMorale` / `SetMorale` | `civic.morale(0)` |
| `civic.trigger_event(eid,cid)` / `civic.event_state(eid)` | `TriggerEvent` / `GetEventState` | `civic.trigger_event(0,0)` |
| `civic.production_rate(bldg,gid)` / `civic.set_production_rate(bldg,gid,rate)` | `GetProductionRate` / `SetProductionRate` | `civic.production_rate(bldg,3)` |
| `civic.city_stability(cid)` / `civic.set_city_stability(cid,v)` | `GetCityStability` / `SetCityStability` | `civic.city_stability(0)` |
| `civic.worker_morale(bid)` / `civic.set_worker_morale(bid,v)` | `GetWorkerMorale` / `SetWorkerMorale` | `civic.worker_morale(bldg)` |
| `civic.building_tax(bldg)` / `civic.set_building_tax(bldg,v)` | `GetBuildingTax` / `SetBuildingTax` | `civic.building_tax(bldg)` |
| `civic.worker_skill(wid,sid)` / `civic.set_worker_skill(wid,sid,v)` | `GetWorkerSkill` / `SetWorkerSkill` | `civic.worker_skill(0,1)` |
| `civic.trial_verdict(tid)` / `civic.set_trial_verdict(tid,v)` | `GetTrialVerdict` / `SetTrialVerdict` | `civic.trial_verdict(0)` |
| `civic.harvest_yield(farm,gid)` / `civic.set_harvest_yield(farm,gid,v)` | `GetHarvestYield` / `SetHarvestYield` | `civic.harvest_yield(farm,3)` |
| `civic.witnesses(tid)` | `GetTrialWitnessCount` | `civic.witnesses(0)` |
| `civic.worker_wage(bldg,wtype)` / `civic.set_worker_wage(bldg,wtype,v)` | `GetWorkerWage` / `SetWorkerWage` | `civic.worker_wage(bldg,0)` |

## C++ Objects (`obj.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `obj.at(addr)` | Object at addr (reads vtable ptr) | `obj.at(0x00AB1234)` |
| `o:vcall(idx, sig, args)` | Call vtable[idx] as `__thiscall` | `obj.at(p):vcall(0, "int(void*)", {})` |
| `o:call(addr, sig, args)` | Direct thiscall with `this=o.addr` | `o:call(0x401000, "int(void*,int)", {5})` |
| `o:field(ctype, off)` | Typed field read | `o:field("int", 0x10)` |
| `o:dump([n])` | Vtable + object header | `o:dump(12)` |
| `obj.dump(addr, n)` | One-shot vtable dump | `obj.dump(0x00AB1234, 16)` |

Pairs with `rtti`/`vtable` → `disasm` for virtual-method triage.

## Console Commands

| Command | Description |
|---------|-------------|
| `help()` | Show all available commands |
| `list()` | List registered game functions |
| `cls` / `clear` | Clear screen |
| `history` | Show command history |
| `exit` / `quit` / `q` | Close console |
