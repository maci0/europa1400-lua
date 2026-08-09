# Europa 1400 Lua Console

**A reverse engineering and analysis toolkit for Europa 1400: The Guild**

An interactive Lua console that runs directly inside the game process. Designed for reverse engineers, modders, and game researchers who want to understand and interact with Europa 1400's internals.

---

## 🎯 **What is this?**

This is a **DLL injection mod** that provides:

- 🔧 **Interactive Lua Console** - Execute scripts directly in the game process
- 🎮 **Game Function Calling** - Call discovered functions from Ghidra analysis
- 🧠 **Memory Operations** - Read/write game memory in real-time
- 🔎 **Memory Scanner** - AOB pattern scanning, hex dumps, string search, region enumeration
- 🎯 **Value Scanner** - Live int32/float/range scans with `update` narrowing
- 🔗 **Pointer Chains** - `module+RVA` chains with Cheat Engine semantics
- 🧩 **PE Inspector** - Enumerate exports/imports from any loaded module (ASLR-safe)
- 🔗 **Xref Finder** - Find CALL/JMP/PUSH/MOV references to any address or string
- 🩹 **Live Patcher** - NOP / JMP / CALL patches with `VirtualProtect` + restore
- 👁️ **Live Watcher** - Poll/wait/diff for typed memory watches
- 🧱 **Struct Dumper** - Field-aware struct/array/hex dumps
- 🔍 **Function Finder** - String/bytes → xrefs → prologue auto-discovery
- 🔬 **Execution Tracer** - Hook `game.call` for arg/return/timing logging
- 🔎 **Lightweight Disassembler** - x86 view for triage (`disasm.at`/`func`/`decode`)
- 🧬 **Signature Maker** - Stable AOBs with CALL/JMP masking (`sig.masked`/`func`)
- 🪝 **IAT Hook** - Redirect imports via IAT patching
- 🔍 **RE Presets / Strings** - Curated string sets + ASCII/wide dumps
- 💾 **Session / Report** - Snapshot game funcs + notes → markdown report
- 🧱 **VTable / RTTI** - Enumerate vtables and MSVC type names
- 🧿 **Diff / Heap / Probe / Dump / Auto** - Diff, heap walker, safe probe, raw dump, auto discover
- 🧪 **Stack / Near / Fuzz** - Backtrace/EBP chain, nearby finder, fuzz helper
- 🧱 **C++ Objects** - `thiscall`/`vtable` access via `obj.*`
- 📚 **Function Catalog** - 4463 curated in-game functions + `catalog.hunt`
- 🧮 **Enums / Codegen** - Building/good/title/unit lookups + struct/codegen helpers
- 🧵 **Threads** - Toolhelp thread inspector
- 🎯 **Player** - `player.*` helpers (gold/fame/name via scan/struct)
- 📊 **System Diagnostics** - Comprehensive process and system analysis tools
- 💾 **Persistent Analysis** - Save and share your reverse engineering work
- 🔍 **Advanced Debugging** - Function call logging, parameter tracking, execution history

**Perfect for:** Game modding, reverse engineering, function analysis, memory research, and understanding game mechanics.

---

## ⚡ **Quick Start**

1. **Build and Install** (see [Installation](#-installation))
2. **Launch Europa 1400** → Console appears automatically  
3. **Start exploring:**
   ```lua
   help()                    -- Show all commands
   system.info()             -- System information
   scan.regions()            -- Readable memory regions
   scan.scan("55 8B EC", 0x401000, 0x10000)  -- AOB scan
   exports.list()            -- PE exports of main exe
   ```

4. **Register a function from Ghidra:**
   ```lua
   game.register("GetPlayerGold", 0x403000, "int()", "Get player gold")
   local gold = game.call("GetPlayerGold")
   print("Player has:", gold, "gold")
   ```

5. **Save your progress:**
   ```lua
   game.save("my_analysis.lua")
   ```

---

## 📸 **Screenshots**

### Console Interface & System Diagnostics
![Europa 1400 Lua Console Interface](media/screenshot1.png)

*The interactive Lua console showing system information, memory diagnostics, and command history features.*

### Window Info  
![Game Function Analysis](media/screenshot2.png)

*The interactive Lua console showing window information*


---

## 🚀 **Key Features**

### **🎮 Game Function System**
- Direct function calling from Ghidra addresses
- Multiple calling conventions support
- Parameter validation and error handling
- Return value capture and logging

### **🧠 Memory Operations**
- Real-time memory read/write with type safety
- Struct support for complex data types
- Module base address resolution
- Memory layout analysis

### **📊 System Diagnostics**
- Complete system information (CPU, memory, architecture)
- Process window enumeration with full details
- Loaded module analysis with addresses and paths
- Memory usage monitoring with formatted output

### **🔍 Debugging & Logging**
- Function call history with timing information
- Parameter and return value tracking
- Memory operation logging with success/failure status
- Colored console output for better readability
- Command history with navigation (100 commands)

### **💾 Persistent Analysis**
- Save/load function registrations to files
- Build function libraries over time
- Share analysis work with other researchers
- Template-based organization

---

## 📦 **Installation**

### **Prerequisites**
- **Europa 1400: The Guild** (original game)
- **dxwrapper** for modern graphics compatibility
- **Wine** (Linux users) or **Windows**

### **Build Requirements**
- **Zig compiler** (latest stable)
- **LuaJIT source code** (included in vendor/)
- **Git** for cloning

### **Building from Source**

1. **Clone and setup:**
   ```bash
   git clone https://github.com/your-repo/europa1400-lua
   cd europa1400-lua
   ```

2. **Build LuaJIT:**
   ```bash
   make lua
   ```

3. **Build the console:**
   ```bash
   make
   ```

4. **Install to game directory:**
   ```bash
   make install
   ```

   This copies:
   - `luaapi.asi` → `~/.wine/drive_c/Guild/`
   - `lua/` directory with all scripts

### **Verify Installation**
1. Launch Europa 1400
2. Console window appears automatically  
3. You see: `"Europa 1400 Lua Console Ready"`
4. Type `help()` to see available commands

---

## 📖 **Documentation**

- **[Usage Guide](docs/USAGE.md)** - Detailed usage instructions and examples
- **[API Reference](docs/API.md)** - Complete function reference
- **[Examples](docs/EXAMPLES.md)** - Real-world reverse engineering workflows
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

---

## 📁 **Project Structure**

```
europa1400-lua/
├── src/                   # C source: main.c, logging.h/c
├── scripts/lua/           # Lua modules (all loadfile-clean on Linux, run on Windows)
│   ├── gamecalls.lua      # game.* — register/call/read_mem/write_mem/save/load
│   ├── sysinfo.lua        # system.* — info/memory_info/list_modules/window_info
│   ├── memscan.lua        # scan.* — AOB scan, dump, string search, regions
│   ├── valuescan.lua      # valuescan.* — live value scans + update narrowing
│   ├── pointer.lua        # pointer.* — module+RVA chains
│   ├── exports.lua        # exports.* — PE export/import enumeration
│   ├── xrefs.lua          # xrefs.* — CALL/JMP/PUSH/MOV cross-refs
│   ├── patch.lua          # patch.* — NOP/JMP/CALL + VirtualProtect + restore
│   ├── watch.lua          # watch.* — poll/wait/diff typed watches
│   ├── struct.lua         # struct.* — field-aware dumper
│   ├── finder.lua         # finder.* — string/bytes → xref → prologue
│   ├── trace.lua          # trace.* — game.call hook for args/return/timing
│   ├── disasm.lua         # disasm.* — lightweight x86 view
│   ├── sig.lua            # sig.* — stable masked signatures
│   ├── hook.lua           # hook.* — IAT hook helper
│   ├── presets.lua        # presets.* — RE cheat-sheet
│   ├── strings.lua        # strings.* — string dumper
│   ├── session.lua        # session.* — session manager
│   ├── vtable.lua         # vtable.* — vtable dumper
│   ├── threads.lua        # threads.* — thread inspector (Toolhelp threads)
│   ├── rtti.lua           # rtti.* — RTTI scanner
│   ├── report.lua         # report.* — report generator
│   ├── diff.lua           # diff.* — memory diff
│   ├── heap.lua           # heap.* — heap walker
│   ├── probe.lua          # probe.* — safe call probe
│   ├── dump.lua           # dump.* — raw memory dumper (binary dump to files)
│   ├── auto.lua           # auto.* — one-shot string/preset -> func -> sig/probe
│   ├── stack.lua          # stack.* — stack viewer (capture/EBP chain/args)
│   ├── near.lua           # near.* — nearby func finder (cluster around addr)
│   ├── fuzz.lua           # fuzz.* — fuzz helper (range arg brute-force)
│   ├── catalog.lua        # catalog.* — function catalog (4463 entries)
│   ├── ui.lua             # ui.* — UI helpers (dialog/tavern probing)
│   ├── player.lua         # player.* — player helper (gold/fame/name via scan/struct)
│   ├── city.lua           # city.* — city helper (treasury/pop/happiness/owner)
│   ├── building.lua       # building.* — building helper (level/owner/type/workers)
│   ├── unit.lua           # unit.* — unit helper (health/owner/type/pos/skill)
│   ├── inventory.lua      # inventory.* — inventory/warehouse goods helper
│   ├── economy.lua        # economy.* — guild/market/tax/trade routes
│   ├── world.lua          # world.* — clock/year/season/speed/city/state
│   ├── quest.lua          # quest.* — quest start/complete/status/vars
│   ├── social.lua         # social.* — guild/nobility/reputation/diplomacy/marriage
│   ├── cheat.lua          # cheat.* — quick cheats (gold/fame/time/market/quest)
│   ├── state.lua          # state.* — save/load/pause/state
│   ├── snapshot.lua       # snapshot.* — cross-domain snapshot + diff
│   ├── civic.lua          # civic.* — election/trial/crime/workshop
│   ├── obj.lua            # obj.* — C++ object helper (vtable/thiscall)
│   ├── enums.lua          # enums.* — enum lookups (building/good/title/unit)
│   ├── codegen.lua        # codegen.* — struct/register code generator
│   ├── check.lua          # self-test (make check)
│   ├── beep.lua           # beep.* — MessageBeep helper
│   └── init.lua           # console init + help() for all modules
├── docs/                  # API.md, USAGE.md, EXAMPLES.md, TROUBLESHOOTING.md
├── media/                 # Screenshots
├── vendor/luajit/         # LuaJIT source
├── bin/                   # Built artifacts (luaapi.asi)
└── Makefile              # Zig x86-windows-gnu DLL build
```


> State wrappers now 92 (`broadcast/divorce/warrant/spy/diplomacy` + `city_*`/`season`/`intrigue`/`office`/`bandit`), `cheat` 2219 bridges.
## Reversed Functions (curated via `catalog.*`)

4463 entries, e.g.:

| Function | Signature | Found via |
|----------|-----------|-----------|
| GetPlayerGold | `int()` | finder + disasm + sig |
| SetPlayerGold | `void(int)` | Ghidra (examples) |
| IsGamePaused | `int()` | catalog (see `catalog.hunt`) |
| Probe at 0x401000 | `probe.at` | `probe`/`auto` workflow |

Full list: `catalog.list()` in-game or `catalog.lua` in repo. The toolkit reversed the workflow itself: `catalog` → `presets`/`strings` → `finder`/`xrefs` → `disasm` → `vtable`/`rtti` → `enums`/`struct`/`obj` → `valuescan`/`pointer`/`heap` → `disasm` → `sig` → `patch`/`hook`/`watch`/`diff` → `probe`/`fuzz`/`near`/`stack`/`auto`/`trace` → `session`/`report`. Also see: `threads`, `dump`, `codegen`.

---

## 🤝 **Contributing**

We welcome contributions! Here's how to get involved:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes with proper testing
4. Update documentation as needed
5. Submit a pull request

### **Areas for Contribution**
- 🔧 Additional system diagnostic functions
- 🎮 Game-specific analysis tools
- 📊 Enhanced debugging features
- 🛡️ Security and stability improvements
- 📖 Documentation and examples
- 🐛 Bug fixes and error handling

---

## 📄 **License**

This project is licensed under the **GPLv3 License** - see the [LICENSE](LICENSE) file for details.

**Important**: This software is for educational and research purposes. Always respect game terms of service and applicable laws when using reverse engineering tools.

---

## 🙏 **Acknowledgments**

- **[LuaJIT Team](https://luajit.org/)** - Excellent Lua implementation with FFI
- **[dxwrapper Project](https://github.com/elishacloud/dxwrapper)** - D3D8/D3D9/Vulkan compatibility layer
- **[Ghidra Team](https://ghidra-sre.org/)** - Revolutionary reverse engineering platform
- **[Europa 1400 Community](https://europa1400-wiki.eulenet.io/)** - Game preservation and reverse engineering support
- **Contributors** - Everyone who helps improve this project

---

## 📞 **Support & Community**

- 🐛 **Issues**: Report bugs and request features in [GitHub Issues](https://github.com/your-repo/europa1400-lua/issues)
- 💬 **Discussions**: Join conversations in [GitHub Discussions](https://github.com/your-repo/europa1400-lua/discussions)
- 📧 **Contact**: For questions about reverse engineering or advanced usage
- 🤝 **Contributing**: See [Contributing](#-contributing) section above

---

**Ready to dive deep into Europa 1400?** Start your reverse engineering journey! 🚀