@echo off
setlocal ENABLEDELAYEDEXPANSION
pushd "%~dp0"

set "LAZBUILD=..\..\tools\lazbuild.bat"
set "LAZBUILD_PATH=lazbuild"
set "PROJECT=fafafa.core.option.test.lpi"
set "TEST_EXECUTABLE=bin\fafafa.core.option.test.exe"
set "CLEAN_DIRS=lib bin"

set "EXIT_ERR=1"

REM Parse args: clean / rebuild / test
set "CMD=%1"
if /i "%CMD%"=="clean" goto :CLEAN
if /i "%CMD%"=="rebuild" ( set "DO_CLEAN=1" )

REM Build
if not exist "%LAZBUILD%" (
  where lazbuild >nul 2>nul
  if %ERRORLEVEL% EQU 0 (
    echo [INFO] Using lazbuild from PATH.
    set "LAZBUILD_PATH=lazbuild"
  ) else (
    echo [WARN] lazbuild not found. Build step will be skipped.
  )
)

if defined DO_CLEAN (
  echo [CLEAN] Removing: %CLEAN_DIRS%
  for %%D in (%CLEAN_DIRS%) do (
    if exist "%%D" (
      rmdir /s /q "%%D" 2>nul
      if exist "%%D" (
        echo [WARN] Failed to remove %%D
      )
    )
  )
)

set "LZ_Q="
if not "%FAFAFA_BUILD_QUIET%"=="0" set "LZ_Q=--quiet"
if not exist logs mkdir logs >nul 2>nul
set "BUILD_LOG=logs\build.txt"
set "TEST_LOG=logs\test.txt"
if exist "%BUILD_LOG%" del /q "%BUILD_LOG%" >nul 2>nul
if exist "%TEST_LOG%" del /q "%TEST_LOG%" >nul 2>nul

if exist "%LAZBUILD%" (
  echo [BUILD] Project: %PROJECT%
  call "%LAZBUILD%" %LZ_Q% --build-all "%PROJECT%" >"%BUILD_LOG%" 2>&1
  set "EXIT_ERR=%ERRORLEVEL%"
) else (
  where lazbuild >nul 2>nul
  if %ERRORLEVEL% EQU 0 (
    echo [INFO] Using lazbuild from PATH.
    lazbuild %LZ_Q% --build-all "%PROJECT%" >"%BUILD_LOG%" 2>&1
    set "EXIT_ERR=%ERRORLEVEL%"
  ) else (
    echo [WARN] tools\lazbuild.bat not found and lazbuild not in PATH. Skipping build step.
  )
)

if !EXIT_ERR! EQU 0 (
  echo [BUILD] OK
) else (
  echo [BUILD] FAILED code=!EXIT_ERR!
)

REM Test (optional)
if /i "%CMD%"=="test" (
  if exist "%TEST_EXECUTABLE%" (
    echo [TEST] Running...
    "%TEST_EXECUTABLE%" -a -p --format=plain >"%TEST_LOG%" 2>&1
    set "EXIT_ERR=!ERRORLEVEL!"
    if !EXIT_ERR! EQU 0 (
      echo [TEST] OK
    ) else (
      echo [TEST] FAILED code=!EXIT_ERR! & echo See "%TEST_LOG%" for details.
    )
  ) else (
    echo [ERROR] Test executable not found: %TEST_EXECUTABLE%
    if !EXIT_ERR! EQU 0 set "EXIT_ERR=1"
  )
) else if /i "%CMD%"=="clean" (
  rem already cleaned
) else if /i "%CMD%"=="rebuild" (
  rem already cleaned and built
) else (
  if !EXIT_ERR! EQU 0 (
    echo To run tests, pass 'test' as the first argument.
    echo Other commands: clean | rebuild
  )
)

popd
endlocal
exit /b !EXIT_ERR!

:CLEAN
for %%D in (%CLEAN_DIRS%) do (
  if exist "%%D" (
    echo [CLEAN] Removing %%D
    rmdir /s /q "%%D" 2>nul
  )
)
set "EXIT_ERR=0"
popd
endlocal
exit /b %EXIT_ERR%

