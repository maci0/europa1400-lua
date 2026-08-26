#ifndef LOGGING_H
#define LOGGING_H

#include <stdbool.h>
#include <stdint.h>

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

typedef struct
{
    CRITICAL_SECTION critical_section;
    bool             critical_section_initialized;
    HANDLE           log_file;
    UINT32           log_line_count;
} logging_context;

extern logging_context g_logctx;

// Opens <dll directory>/hook_log.txt for append. False leaves logging inert;
// hook_logf stays safe to call either way.
bool init_logging(HMODULE hModule);
void close_logging(void);

// Thread-safe. Appends a newline if fmt does not end with one. Lines are
// truncated to LOG_LINE_MAX bytes including the timestamp prefix.
void hook_logf(const char *fmt, ...) __attribute__((format(printf, 1, 2)));

#endif // LOGGING_H
