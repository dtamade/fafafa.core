@echo off
set SCRIPT_DIR=%~dp0
set LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat
set PROJ=fafafa.core.lockfree.ifaces_factories.test.lpi
set EXE=%SCRIPT_DIR%bin\lockfree_ifaces_factories_tests

call "%LAZBUILD%" "%SCRIPT_DIR%%PROJ%"
REM Don't trust errorlevel: some wrappers return 0 even on errors
if not exist "%EXE%.exe" (
  echo Lazbuild did not produce executable. Trying FPC fallback...
  goto :FALLBACK
) else (
  goto :RUN
)

:FALLBACK

REM === Fallback: build with FPC directly ===
set FPC_BIN="D:\devtools\lazarus\trunk\fpc\bin\x86_64-win64\fpc.exe"
set LPR=%SCRIPT_DIR%fafafa.core.lockfree.ifaces_factories.test.lpr
set OUTDIR=%SCRIPT_DIR%lib
set BINDIR=%SCRIPT_DIR%bin
if not exist "%OUTDIR%" mkdir "%OUTDIR%"
if not exist "%BINDIR%" mkdir "%BINDIR%"

pushd "%SCRIPT_DIR%"
%FPC_BIN% -MObjFPC -Scghi -O1 -gw3 -gl -gh -Xg -gt -l -vewnhibq ^
  -Fi"lib\x86_64-win64" ^
  -Fi"..\..\src" ^
  -Fu"." ^
  -Fu"..\..\src" ^
  -Fu"D:\devtools\lazarus\trunk\lazarus\components\fpcunit\lib\x86_64-win64\win32" ^
  -Fu"D:\devtools\lazarus\trunk\lazarus\components\synedit\units\x86_64-win64\win32" ^
  -Fu"D:\devtools\lazarus\trunk\lazarus\lcl\units\x86_64-win64\win32" ^
  -Fu"D:\devtools\lazarus\trunk\lazarus\components\lazedit\lib\x86_64-win64" ^
  -Fu"D:\devtools\lazarus\trunk\lazarus\lcl\units\x86_64-win64" ^
  -Fu"D:\devtools\lazarus\trunk\lazarus\components\freetype\lib\x86_64-win64" ^
  -Fu"D:\devtools\lazarus\trunk\lazarus\components\lazutils\lib\x86_64-win64" ^
  -Fu"D:\devtools\lazarus\trunk\lazarus\packager\units\x86_64-win64" ^
  -FU"lib\x86_64-win64" ^
  -FE"bin" ^
  -o"bin\lockfree_ifaces_factories_tests.exe" ^
  -dLCL -dLCLwin32 ^
  "fafafa.core.lockfree.ifaces_factories.test.lpr"
popd
if %ERRORLEVEL% NEQ 0 (
  echo FPC fallback build failed: %ERRORLEVEL%
  exit /b %ERRORLEVEL%
)

:RUN
if exist "%EXE%.exe" (
  set "EXEFULL=%EXE%.exe"
) else (
  set "EXEFULL=%EXE%"
)

REM === Logging support ===
set "LOG_DIR=%SCRIPT_DIR%logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set "LOG_FILE_IFACES=%LOG_DIR%\latest_ifaces_factories.log"

>"%LOG_FILE_IFACES%" echo [run] %EXEFULL% --all --format=plain --progress
"%EXEFULL%" --all --format=plain --progress >> "%LOG_FILE_IFACES%" 2>&1

type "%LOG_FILE_IFACES%"
