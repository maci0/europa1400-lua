# Changelog

## 0.1.0

First tagged release. Everything below was already in the tree; this entry records
what was broken in it and is now fixed.

### Fixed

- `game.register` built its FFI type as `signature .. "*"`, which is not valid C.
  Every registration failed at `ffi.cast`, so `game.call` could never reach a game
  function. Same bug in `probe.at`, `obj:vcall`, `obj:call` and `fuzz.raw`; all five
  now go through `game.pointer_type`.
- Modules resolved each other with `_G.x or (pcall(dofile, "lua/x.lua") and _G.x)`.
  Nothing set those globals, so the fallback always produced nil after re-executing
  the module. Everything uses `require` now, and the DLL sets `package.path` from its
  own directory, so the scripts load regardless of the game's working directory.
- `game.save` emitted `dofile('lua/gamecalls.lua')`, so loading a saved file
  registered into a second, invisible registry. `game.load` reports the count it
  actually added.
- `init.lua` defined `report()` over the `report` module table, making `report.save`
  and `report.print` unreachable. The alias is gone.
- About 150 `cheat.*` one-liners named per-object fields as module functions and
  errored against an already-loaded module; `delegate` falls back to the object
  `<mod>.at(addr)` returns. Eight setters were delegated to `state`, which does not
  define them.
- `fuzz.raw` overwrote the signature with the function name on the name-based path.
- `cls` shelled out to `cmd.exe` from inside the game process; it uses the console
  API. Self-unload uses `FreeLibraryAndExitThread` instead of casting `FreeLibrary`
  into `CreateThread`.
- `logging_context.log_file` started at 0 rather than `INVALID_HANDLE_VALUE`, so a
  failed init left `WriteFile(NULL)` on every log call and `CloseHandle(NULL)` at
  exit.
- Console output is ASCII; the game console is not a UTF-8 terminal. German preset
  needles are Latin-1 byte escapes so they can match strings in the process.

### Changed

- `make check` executes every module against a stubbed kernel32 and runs `init.lua`,
  rather than only parsing files and silently skipping smoke tests. `make` builds with
  `-Wall -Wextra`.
- `gamecalls` no longer leaks 16 functions into `_G`.
- Docs: eleven functions were listed under the wrong module, the catalog size was
  quoted as 261 against an actual 4463, and the README described 4463 unaddressed
  candidates as reversed functions. The README now states what works and what is
  scaffolding, and the gate asserts the catalog count it quotes.

### Removed

- `game_functions.lua`, a comment block wrapping `return gamecalls`.
- Seventeen `cheat.*` setter halves with no implementation and no catalog entry; the
  getters remain.
