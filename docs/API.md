# API Reference

Complete reference for all available functions and their usage.

## Game Function System (`game.*`)

| Function | Description | Example |
|----------|-------------|---------|
| `game.register(name, addr, sig, desc)` | Register game function | `game.register("GetGold", 0x403000, "int()", "Get gold")` |
| `game.call(name, ...)` | Call registered function | `game.call("GetGold")` |
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

## Debug & Logging (`game.*`)

| Function | Description | Usage |
|----------|-------------|--------|
| `game.show_calls(count)` | Show recent function calls | `game.show_calls(10)` |
| `game.show_memory(count)` | Show recent memory operations | `game.show_memory(5)` |
| `game.debug_config([config])` | Configure debug settings | `game.debug_config()` |
| `game.debug_on(enabled)` | Enable/disable logging | `game.debug_on(true)` |
| `game.clear_logs()` | Clear all logs | `game.clear_logs()` |

## Console Commands

| Command | Description |
|---------|-------------|
| `help()` | Show all available commands |
| `list()` | List registered game functions |
| `cls` / `clear` | Clear screen |
| `history` | Show command history |
| `exit` / `quit` / `q` | Close console |