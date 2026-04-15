@echo off
setlocal ENABLEDELAYEDEXPANSION
pushd "%~dp0"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=test"

set "PROJECT=tests_mem_allocator_only.lpi"
set "TEST_EXECUTABLE=bin\tests_mem_allocator_only_debug"
set "TEST_EXECUTABLE_ALT=bin\tests_mem_allocator_only_debug.exe"
set "TEST_EXECUTABLE_FALLBACK=bin\tests_mem_allocator_only"
set "TEST_EXECUTABLE_FALLBACK_ALT=bin\tests_mem_allocator_only.exe"
set "LAZBUILD=..\..\tools\lazbuild.bat"
set "BUILD_LOG=logs\build.txt"
set "TEST_LOG=logs\test.txt"
set "BUILD_MODE=Debug"
set "SRC_WARN_PATTERNS=/C:\"src/.*fafafa.core.mem.allocator.*Warning:\" /C:\"src/.*fafafa.core.mem.allocator.*Hint:\" /C:\"\src\.*fafafa.core.mem.allocator.*Warning:\" /C:\"\src\.*fafafa.core.mem.allocator.*Hint:\""

if /i "%ACTION%"=="build-no-contracts" (
  set "BUILD_MODE=NoContracts"
  set "TEST_EXECUTABLE=bin\tests_mem_allocator_only_nocontracts"
  set "TEST_EXECUTABLE_ALT=bin\tests_mem_allocator_only_nocontracts.exe"
)
if /i "%ACTION%"=="check-no-contracts" (
  set "BUILD_MODE=NoContracts"
  set "TEST_EXECUTABLE=bin\tests_mem_allocator_only_nocontracts"
  set "TEST_EXECUTABLE_ALT=bin\tests_mem_allocator_only_nocontracts.exe"
)
if /i "%ACTION%"=="test-no-contracts" (
  set "BUILD_MODE=NoContracts"
  set "TEST_EXECUTABLE=bin\tests_mem_allocator_only_nocontracts"
  set "TEST_EXECUTABLE_ALT=bin\tests_mem_allocator_only_nocontracts.exe"
)

if not exist logs mkdir logs >nul 2>nul
if exist "%BUILD_LOG%" del /q "%BUILD_LOG%" >nul 2>nul
if exist "%TEST_LOG%" del /q "%TEST_LOG%" >nul 2>nul

set "LZ_Q="
if /i not "%FAFAFA_BUILD_QUIET%"=="0" set "LZ_Q=--quiet"

set "SKIP_BUILD_FLAG=%FAFAFA_SKIP_BUILD: =%"
set "SKIP_BUILD="
if /i "%ACTION%"=="test" if /i "%SKIP_BUILD_FLAG%"=="1" set "SKIP_BUILD=1"
if /i "%ACTION%"=="test-no-contracts" if /i "%SKIP_BUILD_FLAG%"=="1" set "SKIP_BUILD=1"

if defined SKIP_BUILD (
  echo [BUILD] SKIPPED ^(FAFAFA_SKIP_BUILD=1^)
  set "EXIT_ERR=0"
) else if exist "%LAZBUILD%" (
  echo [BUILD] Project: %PROJECT%
  call "%LAZBUILD%" %LZ_Q% --bm=%BUILD_MODE% --build-all "%PROJECT%" >"%BUILD_LOG%" 2>&1
  set "EXIT_ERR=!ERRORLEVEL!"
) else (
  where lazbuild >nul 2>nul
  if !ERRORLEVEL! EQU 0 (
    echo [BUILD] Project: %PROJECT%
    lazbuild %LZ_Q% --bm=%BUILD_MODE% --build-all "%PROJECT%" >"%BUILD_LOG%" 2>&1
    set "EXIT_ERR=!ERRORLEVEL!"
  ) else (
    echo [ERROR] tools\lazbuild.bat not found and lazbuild not in PATH.
    set "EXIT_ERR=1"
  )
)

if not !EXIT_ERR! EQU 0 (
  echo [BUILD] FAILED code=!EXIT_ERR!  ^(see "%BUILD_LOG%"^)
  goto :END
)

if defined SKIP_BUILD goto :AFTER_BUILD

echo [BUILD] OK

findstr /R %SRC_WARN_PATTERNS% "%BUILD_LOG%" >nul
if !ERRORLEVEL! EQU 0 (
  echo [CHECK] FAILED: found current-module src warnings/hints. See "%BUILD_LOG%".
  set "EXIT_ERR=1"
  goto :END
)
echo [CHECK] OK

:AFTER_BUILD
if /i "%ACTION%"=="build" goto :END_OK
if /i "%ACTION%"=="check" goto :END_OK
if /i "%ACTION%"=="build-no-contracts" goto :END_OK
if /i "%ACTION%"=="check-no-contracts" goto :END_OK

if /i not "%ACTION%"=="test" if /i not "%ACTION%"=="test-no-contracts" (
  echo Usage: %~nx0 [build^|check^|test^|build-no-contracts^|check-no-contracts^|test-no-contracts]
  set "EXIT_ERR=2"
  goto :END
)

if exist "%TEST_EXECUTABLE_ALT%" (
  "%TEST_EXECUTABLE_ALT%" --all --format=plain >"%TEST_LOG%" 2>&1
  set "EXIT_ERR=!ERRORLEVEL!"
) else if exist "%TEST_EXECUTABLE%" (
  "%TEST_EXECUTABLE%" --all --format=plain >"%TEST_LOG%" 2>&1
  set "EXIT_ERR=!ERRORLEVEL!"
) else if exist "%TEST_EXECUTABLE_FALLBACK_ALT%" (
  "%TEST_EXECUTABLE_FALLBACK_ALT%" --all --format=plain >"%TEST_LOG%" 2>&1
  set "EXIT_ERR=!ERRORLEVEL!"
) else if exist "%TEST_EXECUTABLE_FALLBACK%" (
  "%TEST_EXECUTABLE_FALLBACK%" --all --format=plain >"%TEST_LOG%" 2>&1
  set "EXIT_ERR=!ERRORLEVEL!"
) else (
  echo [ERROR] Test executable not found: %TEST_EXECUTABLE%[.exe]
  set "EXIT_ERR=1"
  goto :END
)

if not !EXIT_ERR! EQU 0 (
  echo [TEST] FAILED code=!EXIT_ERR!  ^(see "%TEST_LOG%"^)
  goto :END
)

echo [TEST] OK
findstr /R /C:"^[1-9][0-9]* unfreed memory blocks" "%TEST_LOG%" >nul
if !ERRORLEVEL! EQU 0 (
  echo [LEAK] FAILED: heaptrc reports unfreed blocks. See "%TEST_LOG%".
  set "EXIT_ERR=1"
  goto :END
)
echo [LEAK] OK
goto :END_OK

:END_OK
set "EXIT_ERR=0"

:END
popd
endlocal
exit /b %EXIT_ERR%
