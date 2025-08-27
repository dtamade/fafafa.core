# fafafa.core.sync examples

This folder contains small, runnable examples for the sync module: Mutex/AutoLock, Semaphore, RWLock, ConditionVariable.

## Build all

- Windows
  - Double‑click `BuildAllExamples.bat` or run it from a terminal in this folder

The binaries will be placed under `../../bin`.

## Projects included

- example_sync.lpi              – existing comprehensive example
- example_autolock.lpi          – RAII with TAutoLock
- example_semaphore.lpi         – ISemaphore Acquire/TryAcquire/Release
- example_rwlock.lpi            – IReadWriteLock with 2 readers + 1 writer
- example_condvar.lpi           – IConditionVariable signal (1 producer + 1 consumer)
- example_condvar_broadcast.lpi – IConditionVariable broadcast (1 producer + N consumers)

## Windows feature toggles (compile‑time)

The sync module provides optional Windows optimized paths, controlled by macros in:

- `src/fafafa.core.settings.inc`

Available toggles (commented out by default to preserve current behavior):

- `FAFAFA_SYNC_USE_CONDVAR`
  - Use native Windows Condition Variables (CONDITION_VARIABLE + SleepConditionVariableCS/SRW)
  - Strict semantics; avoids polling and aligns with Unix pthread condvars
  - Works best when the associated lock is a Windows CriticalSection or SRWLock
  - How to enable: open `src/fafafa.core.settings.inc` and uncomment the define
  - Notes:
    - Requires Windows Vista or later
    - Our TMutex will supply an internal CriticalSection and IWinCSProvider when this macro is enabled
    - If a provider is not available, the implementation falls back to the existing semaphore/event path

- `FAFAFA_SYNC_USE_SRWLOCK`
  - Use native Windows SRWLOCK for IReadWriteLock
  - Writer lock is non‑recursive (same as current semantics)
  - How to enable: open `src/fafafa.core.settings.inc` and uncomment the define
  - Notes:
    - Requires Windows Vista or later
    - We maintain atomic reader/writer flags for status queries

## Run tips

- The examples are small console apps; no arguments are required
- When toggles are enabled, rebuild the examples so the new code paths are picked up

## Troubleshooting

- If Lazarus/FPC cannot find units from `src`, ensure the project `.lpi` has search paths including `..\\..\\src` (already set in the example projects)
- If you enable toggles but your toolchain lacks certain Windows symbols, the module declares minimal external symbols conditionally to keep builds working

