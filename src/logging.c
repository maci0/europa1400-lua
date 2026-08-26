/*
 * logging.c: file-based logging for the injected DLL.
 */

#define WIN32_LEAN_AND_MEAN
#include <shlwapi.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <windows.h>

#include "logging.h"

#define LOG_LINE_MAX 1024
#define LOG_TIMESTAMP_MAX 64

// Lines written before the log is truncated back to zero length.
#define LOG_MAX_LINES 50000u

logging_context g_logctx = {.log_file = INVALID_HANDLE_VALUE};

static void reset_log_file(void)
{
    SetFilePointer(g_logctx.log_file, 0, NULL, FILE_BEGIN);
    SetEndOfFile(g_logctx.log_file);
    g_logctx.log_line_count = 0;
}

void hook_logf(const char *fmt, ...)
{
    if (!g_logctx.critical_section_initialized || g_logctx.log_file == INVALID_HANDLE_VALUE)
    {
        return;
    }

    EnterCriticalSection(&g_logctx.critical_section);

    if (++g_logctx.log_line_count > LOG_MAX_LINES)
    {
        reset_log_file();
    }

    SYSTEMTIME st;
    GetLocalTime(&st);
    char buffer[LOG_LINE_MAX];
    int  prefix = snprintf(buffer, LOG_TIMESTAMP_MAX, "[%04d-%02d-%02d %02d:%02d:%02d.%03d] ", st.wYear, st.wMonth,
                           st.wDay, st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
    if (prefix < 0)
        prefix = 0;
    else if (prefix >= LOG_TIMESTAMP_MAX)
        prefix = LOG_TIMESTAMP_MAX - 1;

    va_list ap;
    va_start(ap, fmt);
    int len = vsnprintf(buffer + prefix, (size_t)(LOG_LINE_MAX - prefix), fmt, ap);
    va_end(ap);

    if (len < 0)
    {
        LeaveCriticalSection(&g_logctx.critical_section);
        return;
    }
    if (len >= LOG_LINE_MAX - prefix)
    {
        len = LOG_LINE_MAX - prefix - 1;
    }

    if (len > 0)
    {
        int total = prefix + len;
        if (buffer[total - 1] != '\n' && total < LOG_LINE_MAX)
        {
            buffer[total++] = '\n';
        }

        DWORD written;
        WriteFile(g_logctx.log_file, buffer, (DWORD)total, &written, NULL);
        FlushFileBuffers(g_logctx.log_file);
    }

    LeaveCriticalSection(&g_logctx.critical_section);
}

bool init_logging(HMODULE hModule)
{
    InitializeCriticalSection(&g_logctx.critical_section);
    g_logctx.critical_section_initialized = true;

    wchar_t dllPath[MAX_PATH];
    if (GetModuleFileNameW(hModule, dllPath, MAX_PATH) == 0)
    {
        return false;
    }
    if (!PathRemoveFileSpecW(dllPath))
    {
        return false;
    }
    if (wcscat_s(dllPath, MAX_PATH, L"\\hook_log.txt") != 0)
    {
        return false;
    }

    HANDLE file = CreateFileW(dllPath, GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (file == INVALID_HANDLE_VALUE)
    {
        return false;
    }

    g_logctx.log_file = file;
    SetFilePointer(g_logctx.log_file, 0, NULL, FILE_END);
    hook_logf("DLL attached to process %lu, log: %ls", GetCurrentProcessId(), dllPath);
    return true;
}

void close_logging(void)
{
    if (g_logctx.log_file != INVALID_HANDLE_VALUE)
    {
        CloseHandle(g_logctx.log_file);
        g_logctx.log_file = INVALID_HANDLE_VALUE;
    }

    if (g_logctx.critical_section_initialized)
    {
        DeleteCriticalSection(&g_logctx.critical_section);
        g_logctx.critical_section_initialized = false;
    }
}
