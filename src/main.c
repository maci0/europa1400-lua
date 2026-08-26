/*
 * main.c: Europa 1400 Lua console.
 *
 * Injected as an ASI/DLL. On process attach a worker thread allocates a
 * console, creates a LuaJIT state, runs <dll directory>/lua/init.lua and then
 * reads Lua expressions from stdin until the user exits, at which point the
 * DLL unloads itself and leaves the game running.
 */

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"
#include <shlwapi.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <windows.h>

#include "logging.h"

#define CONSOLE_BUFFER_SIZE 4096
#define CONSOLE_VERSION "0.1.0"
#define CONSOLE_TITLE "Europa 1400 - Lua Console " CONSOLE_VERSION
#define SCRIPT_SUBDIR "/lua/"
#define INIT_SCRIPT "init.lua"
#define MAX_COMMAND_HISTORY 100
#define CONSOLE_COLUMNS 120
#define CONSOLE_SCROLLBACK_ROWS 3000
#define CONSOLE_WINDOW_WIDTH 800
#define CONSOLE_WINDOW_HEIGHT 600
#define UNLOAD_MESSAGE_LINGER_MS 1000

#define COLOR_ERROR (FOREGROUND_RED | FOREGROUND_INTENSITY)
#define COLOR_SUCCESS (FOREGROUND_GREEN | FOREGROUND_INTENSITY)
#define COLOR_INFO (FOREGROUND_BLUE | FOREGROUND_INTENSITY)
#define COLOR_WARNING (FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_INTENSITY)

static HMODULE g_hModule = NULL;

static HANDLE  g_hConsole = NULL;
static WORD    g_originalConsoleAttributes = 0;

// "<dll directory>/lua/", forward slashes so it can be spliced into Lua paths.
static char g_scriptDir[MAX_PATH];

static char g_commandHistory[MAX_COMMAND_HISTORY][CONSOLE_BUFFER_SIZE];
static int  g_historyCount = 0;

static void SetConsoleColor(WORD color)
{
    if (g_hConsole)
    {
        SetConsoleTextAttribute(g_hConsole, color);
    }
}

static void ResetConsoleColor(void)
{
    if (g_hConsole)
    {
        SetConsoleTextAttribute(g_hConsole, g_originalConsoleAttributes);
    }
}

static void PrintColored(WORD color, const char *format, ...) __attribute__((format(printf, 2, 3)));

static void PrintColored(WORD color, const char *format, ...)
{
    SetConsoleColor(color);

    va_list args;
    va_start(args, format);
    vprintf(format, args);
    va_end(args);

    ResetConsoleColor();
}

static void ClearConsole(void)
{
    CONSOLE_SCREEN_BUFFER_INFO info;
    if (!g_hConsole || !GetConsoleScreenBufferInfo(g_hConsole, &info))
    {
        return;
    }

    DWORD cells = (DWORD)info.dwSize.X * (DWORD)info.dwSize.Y;
    DWORD written;
    COORD home = {0, 0};
    FillConsoleOutputCharacterA(g_hConsole, ' ', cells, home, &written);
    FillConsoleOutputAttribute(g_hConsole, info.wAttributes, cells, home, &written);
    SetConsoleCursorPosition(g_hConsole, home);
}

static void AddToHistory(const char *command)
{
    if (g_historyCount > 0 && strcmp(g_commandHistory[g_historyCount - 1], command) == 0)
    {
        return;
    }

    int slot = g_historyCount;
    if (slot == MAX_COMMAND_HISTORY)
    {
        memmove(g_commandHistory[0], g_commandHistory[1], sizeof(g_commandHistory) - CONSOLE_BUFFER_SIZE);
        slot = MAX_COMMAND_HISTORY - 1;
    }
    else
    {
        g_historyCount++;
    }

    strncpy(g_commandHistory[slot], command, CONSOLE_BUFFER_SIZE - 1);
    g_commandHistory[slot][CONSOLE_BUFFER_SIZE - 1] = '\0';
}

// Fills g_scriptDir with the Lua script directory next to the loaded DLL.
static BOOL ResolveScriptDir(void)
{
    if (GetModuleFileNameA(g_hModule, g_scriptDir, MAX_PATH) == 0)
    {
        return FALSE;
    }
    if (!PathRemoveFileSpecA(g_scriptDir))
    {
        return FALSE;
    }
    if (strlen(g_scriptDir) + strlen(SCRIPT_SUBDIR) + strlen(INIT_SCRIPT) >= MAX_PATH)
    {
        return FALSE;
    }
    strcat(g_scriptDir, SCRIPT_SUBDIR);
    for (char *c = g_scriptDir; *c; c++)
    {
        if (*c == '\\')
        {
            *c = '/';
        }
    }
    return TRUE;
}

static BOOL SetupConsoleWindow(void)
{
    SetConsoleTitleA(CONSOLE_TITLE);

    g_hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
    if (g_hConsole == INVALID_HANDLE_VALUE || g_hConsole == NULL)
    {
        g_hConsole = NULL;
        return FALSE;
    }

    CONSOLE_SCREEN_BUFFER_INFO consoleInfo;
    if (GetConsoleScreenBufferInfo(g_hConsole, &consoleInfo))
    {
        g_originalConsoleAttributes = consoleInfo.wAttributes;
    }

    COORD newSize = {CONSOLE_COLUMNS, CONSOLE_SCROLLBACK_ROWS};
    SetConsoleScreenBufferSize(g_hConsole, newSize);

    HWND consoleWindow = GetConsoleWindow();
    if (consoleWindow != NULL)
    {
        // HWND_TOP rather than HWND_TOPMOST so the console cannot steal focus
        // from the game window.
        RECT rect;
        GetWindowRect(consoleWindow, &rect);
        SetWindowPos(consoleWindow, HWND_TOP, rect.left, rect.top, CONSOLE_WINDOW_WIDTH, CONSOLE_WINDOW_HEIGHT,
                     SWP_SHOWWINDOW);
    }

    return TRUE;
}

// Points package.path at the script directory so init.lua and the modules can
// require() each other regardless of the game's current working directory.
static void SetLuaPackagePath(lua_State *L)
{
    lua_getglobal(L, "package");
    lua_pushfstring(L, "%s?.lua", g_scriptDir);
    lua_setfield(L, -2, "path");
    lua_pop(L, 1);
}

static BOOL LoadInitScript(lua_State *L)
{
    char path[MAX_PATH];
    snprintf(path, sizeof(path), "%s%s", g_scriptDir, INIT_SCRIPT);

    if (luaL_dofile(L, path) != 0)
    {
        const char *error = lua_tostring(L, -1);
        PrintColored(COLOR_ERROR, "Failed to load %s: %s\n", path, error ? error : "(unknown error)");
        lua_pop(L, 1);
        return FALSE;
    }

    return TRUE;
}

static void TrimString(char *str)
{
    char *start = str;
    while (*start == ' ' || *start == '\t' || *start == '\n' || *start == '\r')
    {
        start++;
    }

    char *end = start + strlen(start);
    while (end > start && (end[-1] == ' ' || end[-1] == '\t' || end[-1] == '\n' || end[-1] == '\r'))
    {
        end--;
    }
    *end = '\0';

    if (start != str)
    {
        memmove(str, start, (size_t)(end - start) + 1);
    }
}

// TRUE if the command was a console builtin and must not reach Lua.
static BOOL HandleBuiltinCommand(const char *command)
{
    if (strcmp(command, "cls") == 0 || strcmp(command, "clear") == 0)
    {
        ClearConsole();
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

    return FALSE;
}

// Trims and runs one input line. Returns 1 when the user asked to exit.
static int ProcessCommand(lua_State *L, char *command)
{
    TrimString(command);

    if (command[0] == '\0')
    {
        return 0;
    }

    if (strcmp(command, "exit") == 0 || strcmp(command, "quit") == 0 || strcmp(command, "q") == 0)
    {
        return 1;
    }

    AddToHistory(command);

    if (HandleBuiltinCommand(command))
    {
        return 0;
    }

    if (luaL_dostring(L, command) != 0)
    {
        const char *error = lua_tostring(L, -1);
        PrintColored(COLOR_ERROR, "Lua error: %s\n", error ? error : "(unknown error)");
        lua_pop(L, 1);
    }

    return 0;
}

static void RunConsoleLoop(lua_State *L)
{
    char inputBuffer[CONSOLE_BUFFER_SIZE];

    PrintColored(COLOR_SUCCESS, "Console ready. ");
    printf("Type ");
    PrintColored(COLOR_INFO, "help()");
    printf(" for commands, ");
    PrintColored(COLOR_INFO, "cls");
    printf(" to clear, ");
    PrintColored(COLOR_INFO, "exit");
    printf(" to quit.\n\n");

    while (1)
    {
        SetConsoleColor(COLOR_SUCCESS);
        printf("lua> ");
        ResetConsoleColor();
        fflush(stdout);

        if (!fgets(inputBuffer, sizeof(inputBuffer), stdin))
        {
            PrintColored(COLOR_WARNING, "\nEnd of input reached. Exiting...\n");
            break;
        }

        // A full buffer with no newline means the line was cut short; drop the
        // rest so its tail is not executed as a separate command.
        size_t length = strlen(inputBuffer);
        if (length == sizeof(inputBuffer) - 1 && inputBuffer[length - 1] != '\n')
        {
            PrintColored(COLOR_ERROR, "Input too long. Maximum %d characters.\n", CONSOLE_BUFFER_SIZE - 1);
            int c;
            while ((c = getchar()) != '\n' && c != EOF)
                ;
            continue;
        }

        if (ProcessCommand(L, inputBuffer) == 1)
        {
            PrintColored(COLOR_SUCCESS, "Goodbye!\n");
            break;
        }
    }
}

static DWORD WINAPI ConsoleThread(LPVOID param)
{
    (void)param;
    lua_State *L = NULL;

    if (!AllocConsole() && GetLastError() != ERROR_ACCESS_DENIED)
    {
        return 1;
    }

    if (!freopen("CONIN$", "r", stdin) || !freopen("CONOUT$", "w", stdout) || !freopen("CONOUT$", "w", stderr))
    {
        FreeConsole();
        return 1;
    }

    if (!SetupConsoleWindow())
    {
        printf("Warning: could not set up console window properties\n");
    }

    init_logging(g_hModule);

    if (!ResolveScriptDir())
    {
        PrintColored(COLOR_ERROR, "FATAL: could not resolve the script directory next to the DLL\n");
        goto cleanup;
    }

    L = luaL_newstate();
    if (!L)
    {
        PrintColored(COLOR_ERROR, "FATAL: failed to create Lua state\n");
        goto cleanup;
    }

    luaL_openlibs(L);
    SetLuaPackagePath(L);
    PrintColored(COLOR_INFO, "%s initialized, scripts: %s\n", LUA_VERSION, g_scriptDir);

    if (!LoadInitScript(L))
    {
        PrintColored(COLOR_WARNING, "Console starts with limited functionality; Lua commands still work.\n\n");
    }

    hook_logf("Lua console " CONSOLE_VERSION " initialized, entering main loop");
    RunConsoleLoop(L);

cleanup:
    PrintColored(COLOR_INFO, "Shutting down console...\n");
    hook_logf("Shutting down console");
    close_logging();

    if (L)
    {
        lua_close(L);
    }

    ResetConsoleColor();
    Sleep(UNLOAD_MESSAGE_LINGER_MS);

    HWND consoleWindow = GetConsoleWindow();
    if (consoleWindow)
    {
        ShowWindow(consoleWindow, SW_HIDE);
    }
    FreeConsole();

    // Drops the last reference to this DLL and exits atomically, so the game
    // keeps running without the console.
    FreeLibraryAndExitThread(g_hModule, 0);
}

BOOL APIENTRY DllMain(HINSTANCE hInstance, DWORD dwReason, LPVOID lpReserved)
{
    (void)lpReserved;

    if (dwReason == DLL_PROCESS_ATTACH)
    {
        g_hModule = (HMODULE)hInstance;
        DisableThreadLibraryCalls(g_hModule);

        // A failed console thread must not stop the DLL from loading; the game
        // would fail to start with it.
        HANDLE hConsoleThread = CreateThread(NULL, 0, ConsoleThread, NULL, 0, NULL);
        if (hConsoleThread)
        {
            CloseHandle(hConsoleThread);
        }
    }

    return TRUE;
}
