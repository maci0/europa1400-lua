# Europa 1400 Lua Console

**A reverse engineering and analysis toolkit for Europa 1400: The Guild**

An interactive Lua console that runs directly inside the game process. Designed for reverse engineers, modders, and game researchers who want to understand and interact with Europa 1400's internals.

---

## 🎯 **What is this?**

This is a **DLL injection mod** that provides:

- 🔧 **Interactive Lua Console** - Execute scripts directly in the game process
- 🎮 **Game Function Calling** - Call discovered functions from Ghidra analysis
- 🧠 **Memory Operations** - Read/write game memory in real-time
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
   system.memory_info()      -- Memory status
   game.list()               -- List registered functions
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

## 🚀 **Key Features**

### **🎮 Advanced Game Function System**
- **Direct function calling** from Ghidra addresses
- **Multiple calling conventions** support
- **Parameter validation** and error handling
- **Return value capture** and logging
- **Signature verification** for safety

### **🧠 Comprehensive Memory Operations**
- **Real-time memory read/write** with type safety
- **Struct support** for complex data types
- **Module base address** resolution
- **Memory layout analysis** 
- **Process memory mapping**

### **📊 System Diagnostics**
- **Complete system information** (CPU, memory, architecture)
- **Process window enumeration** with full details
- **Loaded module analysis** with addresses and paths
- **Memory usage monitoring** with formatted output
- **Thread information** and process details

### **🔍 Advanced Debugging & Logging**
- **Function call history** with timing information
- **Parameter and return value** tracking
- **Memory operation logging** with success/failure status
- **Colored console output** for better readability
- **Command history** with navigation (100 commands)
- **Built-in commands** (cls, history, exit)

### **💾 Persistent Analysis System**
- **Save/load function registrations** to files
- **Build function libraries** over time
- **Share analysis work** with other researchers
- **Version-controlled discoveries**
- **Template-based organization**

### **🛡️ Quality & Safety**
- **Robust error handling** with helpful messages
- **Memory safety** with proper validation
- **Clean DLL unloading** without affecting game
- **Thread-safe operations**
- **Graceful failure recovery**

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

## 📖 **Usage Guide**

### **Basic Console Commands**

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

### **Game Function System**

#### **Registering Functions (from Ghidra)**
```lua
-- Basic function (no parameters)
game.register("GetPlayerGold", 0x403000, "int()", "Get current gold")

-- Function with parameters  
game.register("SetPlayerGold", 0x403100, "void(int)", "Set gold amount")

-- Complex function with multiple parameters
game.register("CreateUnit", 0x404000, "void*(int, int, int)", "Create unit at x,y")

-- Different calling conventions
game.register("WinAPIFunc", 0x405000, "int __stdcall(int, char*)", "Windows API style")
```

#### **Calling Functions**
```lua  
-- Simple calls
local gold = game.call("GetPlayerGold")
print("Current gold:", gold)

-- With parameters
game.call("SetPlayerGold", 9999)
game.call("CreateUnit", 1, 100, 200)  -- type=1, x=100, y=200

-- Error handling
local success, result = pcall(function()
    return game.call("SomeFunction", param1, param2)
end)
if success then
    print("Result:", result)
else
    print("Error:", result)
end
```

### **Memory Operations**

```lua
-- Read memory
local data, bytes_read = game.read_mem(0x500000, 4, "int")
if data then
    print("Memory value:", data[0])
end

-- Write memory
local ffi = require('ffi')
local new_value = ffi.new("int[1]", 12345)
local success, bytes_written = game.write_mem(0x500000, new_value, 4)
print("Write successful:", success, "Bytes:", bytes_written)

-- Get module base addresses
local base = game.get_module_base("kernel32.dll")
print("Kernel32 base:", string.format("0x%08X", base))
```

### **Working with Structs**

```lua
local ffi = require('ffi')

-- Define a game struct
ffi.cdef[[
typedef struct {
    int x, y;
    int health;
    char name[32];
} Player;
]]

-- Read struct from memory
local player_addr = 0x600000
local data, size = game.read_mem(player_addr, ffi.sizeof("Player"), "Player")
if data then
    local player = ffi.cast("Player*", data)
    print("Player position:", player.x, player.y)
    print("Player health:", player.health)
    print("Player name:", ffi.string(player.name))
end
```

### **Analysis Persistence**

```lua
-- Save your function discoveries
game.save("player_functions.lua")       -- Save to specific file
game.save("network_functions.lua")      -- Multiple analysis files
game.save()                             -- Save to default file

-- Load previous analysis
game.load("player_functions.lua")       -- Load specific file
game.load()                             -- Load default file

-- Manage your work
list()                                  -- See what's loaded
game.list()                             -- Detailed function list
```

### **Debugging & Logging**

```lua
-- View call history
game.show_calls(10)                     -- Last 10 function calls
game.show_memory(5)                     -- Last 5 memory operations

-- Configure debugging
game.debug_config()                     -- Show current settings
game.debug_on(true)                     -- Enable verbose logging
game.debug_on(false)                    -- Disable verbose logging

-- Configure specific logging
game.debug_config({
    log_calls = true,
    log_parameters = true,
    log_return_values = true,
    log_memory_ops = false
})

-- Clear logs
game.clear_logs()                       -- Clear all debug logs
```

---

## 🔬 **Example Workflows**

### **Discovering Player Gold System**

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

### **Memory Analysis Workflow**

1. **Get system information:**
   ```lua
   system.info()           -- CPU and memory limits
   system.memory_info()    -- Current memory usage
   system.list_modules()   -- All loaded DLLs
   ```
2. **Find game module:**
   ```lua
   local game_base = game.get_module_base("game.exe")
   print("Game base:", string.format("0x%08X", game_base))
   ```
3. **Explore memory regions:**
   ```lua
   -- Read game data structures
   local data, size = game.read_mem(game_base + 0x1000, 64, "char")
   -- Analyze and document findings
   ```

### **Window Analysis**

1. **Enumerate all process windows:**
   ```lua
   system.window_info()
   ```
2. **Identify main game window:**
   ```lua
   -- Look for visible windows with game-related class names
   -- Document window hierarchy and relationships
   ```

---

## 📁 **Project Structure**

```
europa1400-lua/
├── src/
│   ├── main.c                 # Main DLL with enhanced console
│   └── logging.h             # Logging utilities
├── scripts/lua/
│   ├── init.lua              # Console initialization & welcome
│   ├── gamecalls.lua         # Core function calling system
│   ├── sysinfo.lua           # System diagnostic functions
│   ├── beep.lua              # System utilities and examples
│   └── game_functions.lua    # Your function discoveries (template)
├── vendor/luajit/            # LuaJIT source code
├── bin/                      # Built artifacts
│   └── luaapi.asi          # The final DLL
├── Makefile                  # Build system
└── README.md                # This documentation
```

---

## 🔧 **API Reference**

### **Game Function System (`game.*`)**

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

### **System Diagnostics (`system.*`)**

| Function | Description | Output |
|----------|-------------|---------|
| `system.info()` | System hardware info | CPU, memory limits, architecture |
| `system.memory_info()` | Memory usage status | RAM usage, available memory |  
| `system.list_modules()` | Loaded modules | DLL names, base addresses, paths |
| `system.window_info()` | Process windows | All windows with handles, titles, classes |
| `system.memory_layout()` | Memory layout | Key module addresses |
| `system.thread_info()` | Thread information | Current thread and process IDs |

### **Debug & Logging (`game.*`)**

| Function | Description | Usage |
|----------|-------------|--------|
| `game.show_calls(count)` | Show recent function calls | `game.show_calls(10)` |
| `game.show_memory(count)` | Show recent memory operations | `game.show_memory(5)` |
| `game.debug_config([config])` | Configure debug settings | `game.debug_config()` |
| `game.debug_on(enabled)` | Enable/disable logging | `game.debug_on(true)` |
| `game.clear_logs()` | Clear all logs | `game.clear_logs()` |

---

## 🛠️ **Advanced Usage**

### **Multiple Calling Conventions**

```lua
-- Standard (default)
game.register("StandardFunc", 0x401000, "int(int, int)", "Standard call")

-- Windows API (__stdcall)  
game.register("WinAPIFunc", 0x402000, "int __stdcall(int, int)", "Windows API")

-- Fast call (__fastcall)
game.register("FastFunc", 0x403000, "int __fastcall(int, int)", "Fast call")
```

### **Complex Data Types**

```lua
local ffi = require('ffi')

-- Define complex structures
ffi.cdef[[
typedef struct {
    int id;
    float x, y, z;
    char name[64];
    struct {
        int health;
        int mana;
    } stats;
} GameEntity;
]]

-- Work with pointers and structures
local entity_ptr = game.call("CreateEntity", 1, 100.0, 200.0, 300.0)
if entity_ptr ~= nil then
    local entity = ffi.cast("GameEntity*", entity_ptr)
    print("Entity ID:", entity.id)
    print("Position:", entity.x, entity.y, entity.z)
    print("Name:", ffi.string(entity.name))
end
```

### **Error Handling Best Practices**

```lua
-- Always wrap potentially dangerous calls
local function safe_call(func_name, ...)
    local success, result = pcall(game.call, func_name, ...)
    if success then
        return result
    else
        print("ERROR calling", func_name, ":", result)
        return nil
    end
end

-- Use safe_call for risky operations
local gold = safe_call("GetPlayerGold")
if gold then
    print("Gold:", gold)
end
```

---

## 🐛 **Troubleshooting**

### **Console Issues**

| Problem | Cause | Solution |
|---------|-------|----------|
| Console doesn't appear | ASI file not in correct location | Ensure `luaapi.asi` is in game directory |
| "Cannot find init script" | Missing lua/ directory | Copy lua/ directory to game folder |
| Console appears but no commands | Init script failed | Check console for error messages |
| Focus stealing | Game window conflicts | Use `cls` to clear, avoid window resizing |

### **Function Call Issues**

| Problem | Cause | Solution |
|---------|-------|----------|
| "Function not registered" | Typo in function name | Check with `list()` command |
| Crashes when calling | Wrong address or signature | Verify address in Ghidra, check signature |
| Wrong results | Incorrect calling convention | Try `__stdcall` or `__fastcall` |
| Access violations | Invalid memory access | Verify parameters and memory addresses |

### **Memory Operation Issues**

| Problem | Cause | Solution |
|---------|-------|----------|
| Read returns nil | Invalid memory address | Check address validity, process permissions |
| Write fails | Read-only memory | Find writable memory regions |
| Incorrect data | Wrong data type | Match FFI type to actual data structure |

### **Build Issues**

| Problem | Cause | Solution |
|---------|-------|----------|
| Zig not found | Missing Zig compiler | Install Zig from official website |
| LuaJIT build fails | Missing source | Ensure `vendor/luajit/` contains source |
| Link errors | Wrong architecture | Build for correct target (x86/x64) |

---

## 🤝 **Contributing**

We welcome contributions! Here's how to get involved:

### **Development Setup**
1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes with proper testing
4. Update documentation as needed
5. Submit a pull request

### **Code Style**
- **C Code**: Follow existing indentation (4 spaces)
- **Lua Code**: Use consistent formatting with comments
- **Documentation**: Update README for user-facing changes
- **Testing**: Test all new features thoroughly

### **Areas for Contribution**
- 🔧 Additional system diagnostic functions
- 🎮 Game-specific analysis tools
- 📊 Enhanced debugging features
- 🛡️ Security and stability improvements
- 📖 Documentation and examples
- 🐛 Bug fixes and error handling

---

## 📄 **License**

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

**Important**: This software is for educational and research purposes. Always respect game terms of service and applicable laws when using reverse engineering tools.

---

## 🙏 **Acknowledgments**

- **LuaJIT Team** - Excellent Lua implementation with FFI
- **dxwrapper Project** - D3D8/D3D9/Vulkan compatibility layer
- **Ghidra Team** - Revolutionary reverse engineering platform
- **Europa 1400 Community** - Game preservation and modding support
- **Contributors** - Everyone who helps improve this project

---

## 📞 **Support & Community**

- 🐛 **Issues**: Report bugs and request features in [GitHub Issues](https://github.com/your-repo/europa1400-lua/issues)
- 💬 **Discussions**: Join conversations in [GitHub Discussions](https://github.com/your-repo/europa1400-lua/discussions)
- 📧 **Contact**: For questions about reverse engineering or advanced usage
- 🤝 **Contributing**: See [Contributing](#-contributing) section above

---

**Ready to dive deep into Europa 1400?** Start your reverse engineering journey! 🚀