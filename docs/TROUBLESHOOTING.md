# Troubleshooting Guide

Common issues and solutions for the Europa 1400 Lua Console.

## Console Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| Console doesn't appear | ASI file not in correct location | Ensure `luaapi.asi` is in game directory |
| "Cannot find init script" | Missing lua/ directory | Copy lua/ directory to game folder |
| Console appears but no commands | Init script failed | Check console for error messages |
| Focus stealing | Game window conflicts | Use `cls` to clear, avoid window resizing |

## Function Call Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| "Function not registered" | Typo in function name | Check with `list()` command |
| Crashes when calling | Wrong address or signature | Verify address in Ghidra, check signature |
| Wrong results | Incorrect calling convention | Try `__stdcall` or `__fastcall` |
| Access violations | Invalid memory access | Verify parameters and memory addresses |

## Memory Operation Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| Read returns nil | Invalid memory address | Check address validity, process permissions |
| Write fails | Read-only memory | `patch.*` auto-uses VirtualProtect; use `watch.diff` to see change |
| Incorrect data | Wrong data type | Match FFI type to actual data structure |
| Pattern finds 0 hits | ASLR / wrong base | Use `scan.regions()` to enumerate; try `sig.masked` pattern |
| Linux `loadfile` OK but load fails | `kernel32` not on Linux | Expected — modules run in-game on Windows; `loadfile`-clean is the Linux check |

## Build Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| Zig not found | Missing Zig compiler | Install Zig from official website |
| LuaJIT build fails | Missing source | Ensure `vendor/luajit/` contains source |
| Link errors | Wrong architecture | Build for correct target (x86/x64) |

## Catalog / Hunt

| Problem | Cause | Solution |
|---------|-------|----------|
| `catalog.hunt` finds nothing | Tags too narrow | Try broader `presets.hunt("map")` or wider base/size |
| `catalog.register_all` does nothing | No verified addresses | Still candidates — fill `address` via `auto.discover`/`finder` first |

## New Modules (scan / valuescan / pointer / xrefs / finder / patch / watch / struct / trace / disasm / sig)

| Problem | Cause | Solution |
|---------|-------|----------|
| No xrefs found | Wrong base/size | Use `scan.regions()` then `xrefs.to(addr, base, size)` with wider window |
| `sig.verify` fails | Volatile bytes | Use `sig.masked` / `sig.func` to wildcard CALL/JMP immediates |
| `watch` never fires | Value not written frequently | Lower interval or use `watch.diff` around the action |
| `struct.dump` is empty | No `ffi.cdef` yet | `ffi.cdef` the struct first, then `struct.register` |

## General Tips

- **Start with simple functions first** - Test basic functions without parameters
- **Use the debug system** - Enable logging to see what's happening
- **Check addresses carefully** - Verify addresses from Ghidra are correct  
- **Test incrementally** - Build up function libraries gradually
- **Save your work frequently** - Use `game.save()` to avoid losing progress