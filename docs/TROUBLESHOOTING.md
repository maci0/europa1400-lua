# Troubleshooting Guide

Common issues and solutions for the Europa 1400 Lua Console.

## Console Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| Console doesn't appear | ASI file not in correct location | Ensure `luaapi.asi` is in game directory |
| `Failed to load .../lua/init.lua` | No `lua/` directory beside the ASI | The DLL resolves scripts from its own directory; `make install` puts both in place |
| Console appears but no commands | init.lua raised | The error is printed above the prompt and repeated in `hook_log.txt` next to the ASI |
| Focus stealing | Game window conflicts | Use `cls` to clear, avoid window resizing |

## Function Call Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| "Function not registered" | Typo in function name | Check with `list()` command |
| Crashes when calling | Wrong address or signature | Verify address in Ghidra, check signature |
| Wrong results | Wrong calling convention | Put it in the signature: `int __stdcall(int)`, `__cdecl`, `__fastcall`, `__thiscall` |
| Access violations | Invalid memory access | Verify parameters and memory addresses |

## Memory Operation Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| Read returns nil | Invalid memory address | Check address validity, process permissions |
| Write fails | Read-only memory | `patch.*` auto-uses VirtualProtect; use `watch.diff` to see change |
| Incorrect data | Wrong data type | Match FFI type to actual data structure |
| Pattern finds 0 hits | ASLR / wrong base | Use `scan.regions()` to enumerate; try `sig.masked` pattern |
| Linux load fails on `kernel32` | `kernel32` is Windows-only | Expected. `make check` stubs it, so modules load; anything touching live process memory has to be checked in-game |

## Build Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| Zig not found | Missing Zig compiler | Install Zig from official website |
| LuaJIT build fails | Missing source | Ensure `vendor/luajit/` contains source |
| Link errors | LuaJIT built for the wrong target | `make lua` builds it x86 Windows; rebuild it if you changed the target |

## Catalog / Hunt

| Problem | Cause | Solution |
|---------|-------|----------|
| `catalog.hunt` finds nothing | Tags too narrow | Try broader `presets.hunt("map")` or wider base/size |
| `catalog.register_all` does nothing | No entry has a verified address | Every catalog entry is a candidate; fill `address` via `auto.discover`/`finder` first |

## Scanning, Patching and Disassembly

| Problem | Cause | Solution |
|---------|-------|----------|
| No xrefs found | Wrong base/size | Use `scan.regions()` then `xrefs.to(addr, base, size)` with wider window |
| `sig.verify` fails | Volatile bytes | Use `sig.masked` / `sig.func` to wildcard CALL/JMP immediates |
| `watch` never fires | Value not written frequently | Lower interval or use `watch.diff` around the action |
| `struct.dump` is empty | No `ffi.cdef` yet | `ffi.cdef` the struct first, then `struct.register` |

## General Tips

- Start with a no-argument function; a wrong signature crashes the game, not the console.
- `game.debug_on(true)` logs every call and memory operation with timing.
- `session.save()` and `game.save()` write re-runnable Lua; a crash otherwise costs the session.