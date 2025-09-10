# Example Workflows

Real-world examples of using the Europa 1400 Lua Console for reverse engineering.

## Discovering Player Gold System

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

## Memory Analysis Workflow

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

## Window Analysis

1. **Enumerate all process windows:**
   ```lua
   system.window_info()
   ```
2. **Identify main game window:**
   ```lua
   -- Look for visible windows with game-related class names
   -- Document window hierarchy and relationships
   ```

## Building a Function Library

```lua
-- Player functions
game.register("GetPlayerGold", 0x403000, "int()", "Get gold")
game.register("SetPlayerGold", 0x403100, "void(int)", "Set gold")
game.register("GetPlayerName", 0x403200, "char*()", "Get player name")

-- Unit functions  
game.register("CreateUnit", 0x404000, "void*(int, int, int)", "Create unit")
game.register("GetUnitHealth", 0x404100, "int(void*)", "Get unit HP")
game.register("SetUnitHealth", 0x404200, "void(void*, int)", "Set unit HP")

-- Save everything
game.save("complete_analysis.lua")

-- Show what we have
list()
```