@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Build/Test Script for fafafa.core.process (normalized)
REM Usage: buildOrTest.bat [build|test] [Debug|Release]

REM --- Resolve paths ---
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\.."
set "LAZBUILD=%ROOT_DIR%\tools\lazbuild.bat"
set "PROJECT=%SCRIPT_DIR%tests_process.lpi"
set "BIN_DIR=%SCRIPT_DIR%bin"
set "LIB_DIR=%SCRIPT_DIR%lib"
set "TEST_EXE=%BIN_DIR%\tests.exe"

REM --- Parse args ---
set "ACTION=%~1"
if not defined ACTION set "ACTION=test"
set "MODE=%~2"
if not defined MODE set "MODE=Debug"
echo ACTION=%ACTION% MODE=%MODE%

REM --- Discover lazbuild if wrapper not found ---
if exist "%LAZBUILD%" goto HAVE_LAZBUILD
for /f "delims=" %%P in ('where lazbuild 2^>nul') do set "LAZBUILD=%%P" & goto HAVE_LAZBUILD

echo ERROR: lazbuild not found. Checked:
echo   %ROOT_DIR%\tools\lazbuild.bat and PATH
exit /b 2

:HAVE_LAZBUILD

REM --- Ensure output directories (bin/lib may be used by .lpi Target) ---
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%" >nul 2>&1
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%" >nul 2>&1

REM --- Build ---
echo [1/2] Building: %PROJECT% (Mode=%MODE%)
call :HAS_MODE "%PROJECT%" "%MODE%"
if "%LZ_HAS_MODE%"=="1" (
  "%LAZBUILD%" --build-mode="%MODE%" "%PROJECT%"
) else (
  echo Note: Build mode "%MODE%" not found in project. Building default mode.
  "%LAZBUILD%" "%PROJECT%"
)
if errorlevel 1 (
  echo Build failed with errorlevel %ERRORLEVEL%
  exit /b %ERRORLEVEL%
)

REM Try to detect actual exe path from .lpi if expected path not found
call :DETECT_EXE "%PROJECT%" "%MODE%" "tests" "%TEST_EXE%"

if not exist "%TEST_EXE%" (
  echo ERROR: Test executable not found.
  echo Tried expected: %TEST_EXE%
  echo And searched by BuildMode='%MODE%' in project: %PROJECT%
  exit /b 3
)

echo.
echo [OK] Build successful. Using: %TEST_EXE%
echo.

if /i "%ACTION%"=="build" goto END
if /i not "%ACTION%"=="test" (
  echo Unknown action: %ACTION%
  echo Usage: %~nx0 [build^|test] [Debug^|Release]
  exit /b 4
)

REM --- Run tests ---
echo [2/2] Running tests...
set "LOG=%BIN_DIR%\last_all_full.log"
echo EXEC="%TEST_EXE%" ARGS=--all --format=plain --progress > "%LOG%"
"%TEST_EXE%" --all --format=plain --progress >> "%LOG%" 2>&1
set "TEST_RC=%ERRORLEVEL%"
echo TEST_EXIT_CODE=%TEST_RC% >> "%LOG%"
copy /y "%LOG%" "%BIN_DIR%\last_all.log" >nul 2>&1

echo ===== TEST EXIT CODE: %TEST_RC% =====
echo ===== Last 200 lines of log =====
where powershell >nul 2>nul && (
  powershell -NoProfile -Command "Get-Content -Path '%LOG%' -Tail 200"
) || (
  type "%LOG%"
)
if not "%TEST_RC%"=="0" (
  echo === Some tests failed with code %TEST_RC% ===
  exit /b %TEST_RC%
) else (
  echo === All tests passed ===
)

:END
exit /b 0

REM ---- helpers ----
:DETECT_EXE
REM %1=.lpi path, %2=mode, %3=default name, %4=expected path (may not exist)
set "_LPI=%~1"
set "_MODE=%~2"
set "_DEFNAME=%~3"
set "_EXPECT=%~4"
if exist "%_EXPECT%" set "TEST_EXE=%_EXPECT%" & goto :eof
set "_PROJDIR=%~dp1"
set "FOUND="

where powershell >nul 2>nul && (
  for /f "usebackq delims=" %%F in (`powershell -NoProfile -Command ^
    "$xml=[xml](Get-Content -LiteralPath '%_LPI%');" ^
    "$mode=$xml.ProjectOptions.BuildModes.Item | Where-Object { $_.Name -eq '%_MODE%' };" ^
    "if ($mode) { $name=$mode.CompilerOptions.TargetFilename.Value } else { $name=$null };" ^
    "if ([string]::IsNullOrWhiteSpace($name)) { $name='%_DEFNAME%' };" ^
    "$root=Split-Path -LiteralPath '%_LPI%';" ^
    "$cand=Get-ChildItem -Path $root -Recurse -Filter ($name+'.exe') -File | Sort-Object LastWriteTime -Desc | Select-Object -First 1;" ^
    "if ($cand) { $cand.FullName }"` ) do set "FOUND=%%F"
) || (
  for /f "usebackq delims=" %%F in (`dir /s /b "%_PROJDIR%%_DEFNAME%.exe" 2^>nul`) do set "FOUND=%%F" & goto DET_DONE
)
:DET_DONE
if defined FOUND set "TEST_EXE=%FOUND%"
set "_LPI=" & set "_MODE=" & set "_DEFNAME=" & set "_EXPECT=" & set "_PROJDIR=" & set "FOUND="
exit /b 0

:HAS_MODE
REM %1=.lpi path, %2=mode
set "LZ_HAS_MODE="
where powershell >nul 2>nul && (
  for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command ^
    "$xml=[xml](Get-Content -LiteralPath '%~1');" ^
    "$m='%~2';" ^
    "$ok=$false; if ($xml.ProjectOptions.BuildModes -and $xml.ProjectOptions.BuildModes.Item) { $ok=($xml.ProjectOptions.BuildModes.Item | Where-Object { $_.Name -eq $m }) -ne $null };" ^
    "if ($ok) { '1' } else { '0' }"` ) do set "LZ_HAS_MODE=%%V"
) || (
  REM fallback: naive findstr (may be wrong, but avoids PS requirement)
  findstr /i /c:"<BuildModes>" "%~1" >nul 2>&1 && findstr /i /c:"Name=\"%~2\"" "%~1" >nul 2>&1 && set "LZ_HAS_MODE=1" || set "LZ_HAS_MODE=0"
)
exit /b 0
