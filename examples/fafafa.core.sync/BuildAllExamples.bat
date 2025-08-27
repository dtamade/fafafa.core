@echo off
setlocal enabledelayedexpansion
set "DIR=%~dp0"

rem Prefer env LAZBUILD; fallback to typical Lazarus locations
if not defined LAZBUILD (
  if exist "D:\devtools\lazarus\trunk\lazarus\lazbuild.exe" (
    set "LAZBUILD=D:\devtools\lazarus\trunk\lazarus\lazbuild.exe"
  ) else if exist "D:\devtools\lazarus\lazbuild.exe" (
    set "LAZBUILD=D:\devtools\lazarus\lazbuild.exe"
  ) else if exist "D:\devtools\lazarus\trunk\lazbuild.exe" (
    set "LAZBUILD=D:\devtools\lazarus\trunk\lazbuild.exe"
  ) else (
    set "LAZBUILD=lazbuild"
  )
)

echo Using LAZBUILD="%LAZBUILD%"

set EXAMPLES=example_sync.lpi example_semaphore.lpi example_autolock.lpi example_rwlock.lpi example_condvar.lpi example_condvar_broadcast.lpi example_smoketest.lpi

for %%P in (%EXAMPLES%) do (
  echo Building %%P ...
  "%LAZBUILD%" --build-mode=Debug "%DIR%%%P" || exit /b 1
)

echo All examples built successfully.
exit /b 0
