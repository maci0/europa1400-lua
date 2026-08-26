# europa1400-lua

Injected LuaJIT console for Europa 1400: The Guild. A C DLL creates the console and a Lua
state; everything the user touches is a Lua module under `scripts/lua/`.

## Layout

- `src/` C: `main.c` (console thread, Lua state, DLL lifecycle), `logging.{c,h}` (file log
  next to the DLL). Formatted with `.clang-format`, built by `make`.
- `scripts/lua/` every console module, one global per module, bound in `init.lua`.
  Installed as `lua/` next to the ASI.
- `scripts/lua/check.lua` the self-test. `make check`.
- `docs/` API, usage, examples, troubleshooting.
- `vendor/luajit` submodule, pinned. `make lua` builds it for x86 Windows.
- `bin/` build output, gitignored. `.scratch/` scratch work, gitignored.

## Rules

- **Modules load with `require`.** The DLL points `package.path` at the script directory,
  so nothing may use `dofile` with a hardcoded `lua/...` path or assume a working
  directory. Requiring is cached; re-executing `catalog.lua` rebuilds 4463 entries.
- **A module returns its table and defines nothing global.** `init.lua` owns the globals.
- **Generated Lua must re-enter through `require`.** A saved session that `dofile`s a
  module gets a second, invisible registry.
- **Console output is ASCII.** The game console is an OEM code page; UTF-8 arrives as
  mojibake. In-memory string needles for the German build are Latin-1 byte escapes.
- **Catalog entries are candidates.** Nothing in `catalog.lua` has a verified address.
  Do not describe them as reversed, and do not add a `status` other than `candidate`
  without the evidence that changed it.
- **Placeholder struct offsets say so** in the module header, next to the calibration step.

## Gate

`make check` must pass before a commit. It loads every module against a stubbed kernel32,
so it catches syntax errors, missing require targets and load-time crashes; it cannot check
anything that reads live process memory. Windows-only behaviour is verified in-game and
said to be verified only when it was.

`make` must build clean with `-Wall -Wextra`.

A release bumps `CONSOLE_VERSION` in `src/main.c`, adds a `CHANGELOG.md` entry and
tags. The console title and the log header carry that string, so a bug report names
the build it came from.
