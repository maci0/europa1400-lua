/**
 * Europa 1400 Lua Console - Interactive Lua scripting interface
 *
 * This DLL provides a comprehensive console interface for executing Lua scripts
 * within the Europa 1400 game environment using LuaJIT FFI. Designed for
 * reverse engineering, game analysis, and function calling from Ghidra.
 *
 * Features:
 * - Interactive Lua console with command history
 * - Game function registration and calling system
 * - System diagnostic functions
 * - Memory read/write operations
 * - Persistent function save/load
 * - Clean DLL unloading without affecting main game
 */

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

//============================================================================
// CONFIGURATION AND CONSTANTS
//============================================================================

#define CONSOLE_BUFFER_SIZE 4096
#define CONSOLE_TITLE "Europa 1400 - Lua Console v1.0"
#define INIT_SCRIPT_PATH "lua/init.lua"
#define MAX_COMMAND_HISTORY 100

// Console colors for better visibility
#define COLOR_ERROR FOREGROUND_RED | FOREGROUND_INTENSITY
#define COLOR_SUCCESS FOREGROUND_GREEN | FOREGROUND_INTENSITY
#define COLOR_INFO FOREGROUND_BLUE | FOREGROUND_INTENSITY
#define COLOR_WARNING FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_INTENSITY
#define COLOR_NORMAL FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE

//============================================================================
// GLOBAL STATE
//============================================================================

// Module handle for self-unloading
static HMODULE g_hModule = NULL;

// Console state
static HANDLE g_hConsole = NULL;
static WORD   g_originalConsoleAttributes = 0;

// Command history
static char g_commandHistory[MAX_COMMAND_HISTORY][CONSOLE_BUFFER_SIZE];
static int  g_historyCount = 0;
static int  g_historyIndex = 0;

//============================================================================
// UTILITY FUNCTIONS
//============================================================================

/**
 * Set console text color for better visual feedback
 * @param color Color attribute (use COLOR_* constants)
 */
static void SetConsoleColor(WORD color)
{
    if (g_hConsole)
    {
        SetConsoleTextAttribute(g_hConsole, color);
    }
}

/**
 * Reset console color to original
 */
static void ResetConsoleColor(void)
{
    if (g_hConsole)
    {
        SetConsoleTextAttribute(g_hConsole, g_originalConsoleAttributes);
    }
}

/**
 * Print colored message to console
 * @param color Color to use
 * @param format Printf-style format string
 */
static void PrintColored(WORD color, const char *format, ...)
{
    SetConsoleColor(color);

    va_list args;
    va_start(args, format);
    vprintf(format, args);
    va_end(args);

    ResetConsoleColor();
}

/**
 * Add command to history buffer
 * @param command Command to add
 */
static void AddToHistory(const char *command)
{
    if (strlen(command) == 0)
        return;

    // Avoid duplicate consecutive commands
    if (g_historyCount > 0 && strcmp(g_commandHistory[g_historyCount - 1], command) == 0)
    {
        return;
    }

    // Add to history
    if (g_historyCount < MAX_COMMAND_HISTORY)
    {
        strncpy(g_commandHistory[g_historyCount], command, CONSOLE_BUFFER_SIZE - 1);
        g_commandHistory[g_historyCount][CONSOLE_BUFFER_SIZE - 1] = '\0';
        g_historyCount++;
    }
    else
    {
        // Shift history buffer
        for (int i = 0; i < MAX_COMMAND_HISTORY - 1; i++)
        {
            strcpy(g_commandHistory[i], g_commandHistory[i + 1]);
        }
        strncpy(g_commandHistory[MAX_COMMAND_HISTORY - 1], command, CONSOLE_BUFFER_SIZE - 1);
        g_commandHistory[MAX_COMMAND_HISTORY - 1][CONSOLE_BUFFER_SIZE - 1] = '\0';
    }

    g_historyIndex = g_historyCount;
}

/**
 * Sets up the console window with appropriate title and properties
 */
static BOOL SetupConsoleWindow(void)
{
    SetConsoleTitle(CONSOLE_TITLE);

    // Get console handles
    g_hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
    if (g_hConsole == INVALID_HANDLE_VALUE)
    {
        return FALSE;
    }

    // Store original console attributes
    CONSOLE_SCREEN_BUFFER_INFO consoleInfo;
    if (GetConsoleScreenBufferInfo(g_hConsole, &consoleInfo))
    {
        g_originalConsoleAttributes = consoleInfo.wAttributes;
    }

    // Set console buffer size for more scrollback
    COORD newSize = {120, 3000};
    SetConsoleScreenBufferSize(g_hConsole, newSize);

    // Get console window handle for positioning
    HWND consoleWindow = GetConsoleWindow();
    if (consoleWindow != NULL)
    {
        // Position console window (not always on top to avoid focus issues)
        RECT rect;
        GetWindowRect(consoleWindow, &rect);
        SetWindowPos(consoleWindow, HWND_TOP, rect.left, rect.top, 800, 600, SWP_SHOWWINDOW);
    }

    return TRUE;
}

//============================================================================
// CORE FUNCTIONS
//============================================================================

/**
 * Loads and executes the initialization Lua script
 * @param L Lua state
 * @return TRUE on success, FALSE on error
 */
static BOOL LoadInitScript(lua_State *L)
{
    PrintColored(COLOR_INFO, "Loading initialization script: %s\n", INIT_SCRIPT_PATH);

    // Check if file exists first
    HANDLE hFile =
        CreateFile(INIT_SCRIPT_PATH, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE)
    {
        PrintColored(COLOR_ERROR, "Error: Cannot find init script '%s'\n", INIT_SCRIPT_PATH);
        PrintColored(COLOR_WARNING, "Make sure the lua/ directory is in the same location as the game executable.\n");
        return FALSE;
    }
    CloseHandle(hFile);

    // Execute the script
    int result = luaL_dofile(L, INIT_SCRIPT_PATH);
    if (result != 0)
    {
        const char *error = lua_tostring(L, -1);
        PrintColored(COLOR_ERROR, "Failed to load %s: %s\n", INIT_SCRIPT_PATH, error ? error : "(unknown error)");
        lua_pop(L, 1);
        return FALSE;
    }

    PrintColored(COLOR_SUCCESS, "✓ Initialization complete\n\n");
    return TRUE;
}

/**
 * Trim whitespace from both ends of a string in place
 * @param str String to trim
 */
static void TrimString(char *str)
{
    if (!str)
        return;

    // Trim leading whitespace
    char *start = str;
    while (*start && (*start == ' ' || *start == '\t' || *start == '\n' || *start == '\r'))
    {
        start++;
    }

    // Trim trailing whitespace
    char *end = str + strlen(str) - 1;
    while (end > str && (*end == ' ' || *end == '\t' || *end == '\n' || *end == '\r'))
    {
        *end = '\0';
        end--;
    }

    // Move trimmed string to beginning
    if (start != str)
    {
        memmove(str, start, strlen(start) + 1);
    }
}

/**
 * Check if command is a built-in console command
 * @param command Command to check
 * @return TRUE if handled, FALSE if should be passed to Lua
 */
static BOOL HandleBuiltinCommand(const char *command)
{
    if (strcmp(command, "cls") == 0 || strcmp(command, "clear") == 0)
    {
        system("cls");
        return TRUE;
    }

    if (strcmp(command, "history") == 0)
    {
        PrintColored(COLOR_INFO, "Command History:\n");
        for (int i = 0; i < g_historyCount; i++)
        {
            printf("%3d: %s\n", i + 1, g_commandHistory[i]);
        }
        return TRUE;
    }

    if (strncmp(command, "lua ", 4) == 0)
    {
        // Allow explicit lua prefix (for clarity)
        return FALSE; // Pass the command without prefix to Lua
    }

    return FALSE;
}

/**
 * Processes a single line of user input with enhanced features
 * @param L Lua state
 * @param line Input line to process
 * @return 0 to continue, 1 to exit
 */
static int ProcessCommand(lua_State *L, const char *line)
{
    // Create a working copy and trim whitespace
    char *command = malloc(strlen(line) + 1);
    if (!command)
    {
        PrintColored(COLOR_ERROR, "Memory allocation failed\n");
        return 0;
    }

    strcpy(command, line);
    TrimString(command);

    // Skip empty commands
    if (strlen(command) == 0)
    {
        free(command);
        return 0;
    }

    // Check for exit commands
    if (strcmp(command, "exit") == 0 || strcmp(command, "quit") == 0 || strcmp(command, "q") == 0)
    {
        free(command);
        return 1;
    }

    // Add to command history
    AddToHistory(command);

    // Handle built-in commands
    if (HandleBuiltinCommand(command))
    {
        free(command);
        return 0;
    }

    // Execute Lua command with error handling
    int result = luaL_dostring(L, command);
    if (result != 0)
    {
        const char *error = lua_tostring(L, -1);
        PrintColored(COLOR_ERROR, "Lua error: %s\n", error ? error : "(unknown error)");
        lua_pop(L, 1);
    }

    free(command);
    return 0;
}

/**
 * Display minimal console status after initialization
 */
static void ShowConsoleReady(void)
{
    // Just show that the console is ready - let Lua handle the welcome
    PrintColored(COLOR_SUCCESS, "Console ready. ");
    printf("Type ");
    PrintColored(COLOR_INFO, "help()");
    printf(" for commands, ");
    PrintColored(COLOR_INFO, "cls");
    printf(" to clear, ");
    PrintColored(COLOR_INFO, "exit");
    printf(" to quit.\n\n");
}

/**
 * Main console loop - handles user input and command execution with enhanced features
 * @param L Lua state
 */
static void RunConsoleLoop(lua_State *L)
{
    char inputBuffer[CONSOLE_BUFFER_SIZE];

    // Show minimal ready message (Lua init.lua handles the main welcome)
    ShowConsoleReady();

    // Main input loop
    while (1)
    {
        // Show prompt with color
        SetConsoleColor(COLOR_SUCCESS);
        printf("lua> ");
        ResetConsoleColor();
        fflush(stdout);

        // Read user input with buffer overflow protection
        if (!fgets(inputBuffer, sizeof(inputBuffer), stdin))
        {
            PrintColored(COLOR_WARNING, "\nEnd of input reached. Exiting...\n");
            break;
        }

        // Check for buffer overflow
        if (strlen(inputBuffer) == sizeof(inputBuffer) - 1 && inputBuffer[sizeof(inputBuffer) - 2] != '\n')
        {
            PrintColored(COLOR_ERROR, "Input too long! Maximum %d characters.\n", CONSOLE_BUFFER_SIZE - 1);

            // Clear remaining input from buffer
            int c;
            while ((c = getchar()) != '\n' && c != EOF)
                ;
            continue;
        }

        // Process the command
        if (ProcessCommand(L, inputBuffer) == 1)
        {
            PrintColored(COLOR_SUCCESS, "Goodbye!\n");
            break;
        }
    }
}

/**
 * Console thread entry point with comprehensive error handling
 * Sets up console, initializes Lua, and runs the main loop
 */
static DWORD WINAPI ConsoleThread(LPVOID param)
{
    lua_State *L = NULL;
    BOOL       initSuccess = FALSE;

    // Allocate console with error checking
    if (!AllocConsole())
    {
        // Console might already exist, that's okay
        DWORD error = GetLastError();
        if (error != ERROR_ACCESS_DENIED)
        {
            return 1;
        }
    }

    // Redirect standard streams with error checking
    if (!freopen("CONIN$", "r", stdin) || !freopen("CONOUT$", "w", stdout) || !freopen("CONOUT$", "w", stderr))
    {
        goto cleanup;
    }

    // Setup console appearance
    if (!SetupConsoleWindow())
    {
        printf("Warning: Could not setup console window properties\n");
    }

    // Initialize Lua state with error checking
    L = luaL_newstate();
    if (!L)
    {
        PrintColored(COLOR_ERROR, "FATAL: Failed to create Lua state\n");
        goto cleanup;
    }

    // Load standard Lua libraries
    luaL_openlibs(L);
    PrintColored(COLOR_INFO, "Lua %s initialized\n", LUA_VERSION);

    // Load initialization script
    if (!LoadInitScript(L))
    {
        PrintColored(COLOR_ERROR, "Failed to load initialization script\n");
        PrintColored(COLOR_WARNING, "Console will start with limited functionality\n");
        printf("You can still execute Lua commands manually.\n\n");
    }
    else
    {
        initSuccess = TRUE;
    }

    // Run the main console loop
    RunConsoleLoop(L);

cleanup:
    PrintColored(COLOR_INFO, "Shutting down console...\n");

    // Clean up Lua resources
    if (L)
    {
        lua_close(L);
        L = NULL;
    }

    // Reset console colors
    ResetConsoleColor();

    // Give user a moment to see shutdown message
    Sleep(1000);

    // Close console window gracefully
    HWND consoleWindow = GetConsoleWindow();
    if (consoleWindow)
    {
        ShowWindow(consoleWindow, SW_HIDE);
        // Don't destroy - let FreeConsole handle it
    }

    // Free console resources
    FreeConsole();

    // Self-unload DLL without affecting main game process
    if (g_hModule)
    {
        HANDLE hUnloadThread = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)FreeLibrary, g_hModule, 0, NULL);
        if (hUnloadThread)
        {
            CloseHandle(hUnloadThread);
        }
    }

    return 0;
}

//============================================================================
// DLL ENTRY POINT
//============================================================================

/**
 * DLL entry point - handles DLL lifecycle events
 * Creates console thread on process attach with proper error handling
 */
BOOL APIENTRY DllMain(HINSTANCE hInstance, DWORD dwReason, LPVOID lpReserved)
{
    switch (dwReason)
    {
    case DLL_PROCESS_ATTACH: {
        // Store module handle for self-unloading capability
        g_hModule = (HMODULE)hInstance;

        // Optimize performance by disabling thread attach/detach notifications
        DisableThreadLibraryCalls(g_hModule);

        // Create console thread with error handling
        HANDLE hConsoleThread = CreateThread(NULL,          // Default security attributes
                                             0,             // Default stack size
                                             ConsoleThread, // Thread function
                                             NULL,          // No thread parameter
                                             0,             // Run immediately
                                             NULL           // Don't need thread ID
        );

        if (!hConsoleThread)
        {
            // Failed to create thread - this is a critical error
            // But we don't want to prevent the DLL from loading
            // as it might interfere with the game
            return TRUE;
        }

        // Close the thread handle immediately since we don't need to track it
        // The thread will continue running independently
        CloseHandle(hConsoleThread);
        break;
    }

    case DLL_PROCESS_DETACH:
        // Note: Cleanup is handled in the console thread itself
        // to ensure proper shutdown sequence
        break;

    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
        // These are disabled by DisableThreadLibraryCalls
        break;
    }

    return TRUE;
}
