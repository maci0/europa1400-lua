-- Europa 1400 Game Function Registry
-- 
-- This file contains registered game functions discovered through
-- reverse engineering with Ghidra. Add your function discoveries here.
--
-- Usage:
--   1. Analyze game functions in Ghidra
--   2. Register functions with game.register(name, address, signature, description)
--   3. Call functions with game.call(name, ...)
--   4. Save your work with game.save("filename.lua")

local game = require('lua/gamecalls')

--============================================================================
-- FUNCTION REGISTRATIONS
-- Add your discovered game functions below
--============================================================================

--[[
EXAMPLE REGISTRATIONS (replace with real addresses from your analysis):

-- Player/Economy Functions
game.register("GetPlayerGold", 0x00403000, "int()", 
              "Get current player gold amount")
game.register("SetPlayerGold", 0x00403100, "void(int)", 
              "Set player gold - int amount")
game.register("GetPlayerName", 0x00403200, "char*()", 
              "Get player name string")

-- Game State Functions  
game.register("GetGameState", 0x00405000, "int()", 
              "Get current game state enum")
game.register("PauseGame", 0x00405100, "void(int)", 
              "Pause/unpause game - int paused")

-- UI Functions
game.register("ShowMessage", 0x00404000, "void(char*)", 
              "Display message to player")
game.register("ShowDialog", 0x00404100, "int(char*, int)", 
              "Show dialog - returns user choice")

-- Network Functions (if applicable)
game.register("CreateConnection", 0x00402000, "void*(char*, int)", 
              "Create network connection - host, port")
game.register("SendPacket", 0x00402100, "int(void*, void*, int)", 
              "Send network packet - connection, data, size")
--]]

--============================================================================
-- USAGE EXAMPLES
-- Uncomment these when you have registered functions
--============================================================================

--[[
-- List all registered functions
game.list()

-- Call a function
local gold = game.call("GetPlayerGold") 
print("Current gold:", gold)

-- Call with parameters
game.call("SetPlayerGold", 9999)
game.call("ShowMessage", "Hello from Lua!")

-- Memory operations
local data, bytes_read = game.read_mem(0x500000, 4, "int")
if data then
    print("Memory value:", data[0])
end

-- Save your function registry
game.save("my_game_functions.lua")

-- Load previously saved functions
game.load("my_game_functions.lua")
--]]

--============================================================================
-- MODULE EXPORT
--============================================================================

-- Return the game function interface
return game