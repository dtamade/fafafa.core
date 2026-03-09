@echo off
setlocal ENABLEDELAYEDEXPANSION
pushd "%~dp0"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=test"

set "PROJECT=fafafa.core.args.validation.test.lpi"
set "TEST_EXECUTABLE=bin\fafafa.core.args.validation.test"
set "TEST_EXECUTABLE_ALT=bin\fafafa.core.args.validation.test.exe"
set "CLEAN_DIRS=lib bin logs"
set "LAZBUILD=..\..\tools\lazbuild.bat"

if /i "%ACTION%"=="clean" goto :CLEAN
if /i "%ACTION%"=="rebuild" set "DO_CLEAN=1"

if defined DO_CLEAN (
  for %%D in (%CLEAN_DIRS%) do if exist "%%D" rmdir /s /q "%%D" 2>nul
)

if not exist logs mkdir logs >nul 2>nul
set "BUILD_LOG=logs\build.txt"
set "TEST_LOG=logs\test.txt"
if exist "%BUILD_LOG%" del /q "%BUILD_LOG%" >nul 2>nul
if exist "%TEST_LOG%" del /q "%TEST_LOG%" >nul 2>nul

set "LZ_Q="
if /i not "%FAFAFA_BUILD_QUIET%"=="0" set "LZ_Q=--quiet"

set "EXIT_ERR=1"
if exist "%LAZBUILD%" (
  echo [BUILD] Project: %PROJECT%
  call "%LAZBUILD%" %LZ_Q% --build-all "%PROJECT%" >"%BUILD_LOG%" 2>&1
  set "EXIT_ERR=!ERRORLEVEL!"
) else (
  where lazbuild >nul 2>nul
  if !ERRORLEVEL! EQU 0 (
    echo [BUILD] Project: %PROJECT%
    lazbuild %LZ_Q% --build-all "%PROJECT%" >"%BUILD_LOG%" 2>&1
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

echo [BUILD] OK

if /i "%ACTION%"=="check" (
  findstr /R /C:"src/.*Warning:" /C:"src/.*Hint:" /C:"\src\.*Warning:" /C:"\src\.*Hint:" "%BUILD_LOG%" >nul
  if !ERRORLEVEL! EQU 0 (
    echo [CHECK] FAILED: found src warnings/hints. See "%BUILD_LOG%".
    set "EXIT_ERR=1"
    goto :END
  )
  echo [CHECK] OK
  set "EXIT_ERR=0"
  goto :END
)

if /i "%ACTION%"=="build" (
  set "EXIT_ERR=0"
  goto :END
)

if /i "%ACTION%"=="test" (
  if exist "%TEST_EXECUTABLE%" (
    "%TEST_EXECUTABLE%" --all --format=plain >"%TEST_LOG%" 2>&1
    set "EXIT_ERR=!ERRORLEVEL!"
  ) else if exist "%TEST_EXECUTABLE_ALT%" (
    "%TEST_EXECUTABLE_ALT%" --all --format=plain >"%TEST_LOG%" 2>&1
    set "EXIT_ERR=!ERRORLEVEL!"
  ) else (
    echo [ERROR] Test executable not found: %TEST_EXECUTABLE%[.exe]
    set "EXIT_ERR=1"
    goto :END
  )

  if !EXIT_ERR! EQU 0 (
    echo [TEST] OK
    findstr /R /C:"^[1-9][0-9]* unfreed memory blocks" "%TEST_LOG%" >nul
    if !ERRORLEVEL! EQU 0 (
      echo [LEAK] FAILED: heaptrc reports unfreed blocks. See "%TEST_LOG%".
      set "EXIT_ERR=1"
      goto :END
    )
    echo [LEAK] OK
  ) else (
    echo [TEST] FAILED code=!EXIT_ERR!  ^(see "%TEST_LOG%"^)
  )
  goto :END
)

echo Usage: %~nx0 [build^|check^|test^|clean^|rebuild]
set "EXIT_ERR=2"

:END
popd
endlocal
exit /b %EXIT_ERR%

:CLEAN
for %%D in (%CLEAN_DIRS%) do if exist "%%D" rmdir /s /q "%%D" 2>nul
set "EXIT_ERR=0"
popd
endlocal
exit /b %EXIT_ERR%
