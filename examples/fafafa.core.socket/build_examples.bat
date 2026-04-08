@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.socket Example Build Script
echo ========================================
echo.

set "PROJECT_ROOT=%~dp0..\.."
set "EXAMPLES_DIR=%~dp0"
set "BIN_DIR=%EXAMPLES_DIR%bin"
set "LIB_DIR=%EXAMPLES_DIR%lib"

echo Project Root: %PROJECT_ROOT%
echo Examples Dir: %EXAMPLES_DIR%
echo Output Dir: %BIN_DIR%
echo Lib Dir: %LIB_DIR%
echo.

if "%LAZBUILD%"=="" (
  if exist "%PROJECT_ROOT%\tools\lazbuild.bat" (
    set "LAZBUILD=%PROJECT_ROOT%\tools\lazbuild.bat"
  ) else (
    set "LAZBUILD=lazbuild"
  )
)

if "%FPC%"=="" set "FPC=fpc"

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%\fpc" mkdir "%LIB_DIR%\fpc"

if exist "%LAZBUILD%" goto :have_lazbuild
where "%LAZBUILD%" >nul 2>nul
if errorlevel 1 (
  echo Error: lazbuild not found: %LAZBUILD%
  exit /b 1
)

:have_lazbuild
where "%FPC%" >nul 2>nul
if errorlevel 1 (
  echo Error: fpc not found: %FPC%
  exit /b 1
)

set "PROJECTS=example_socket.lpi echo_server.lpi echo_client.lpi udp_server.lpi udp_client.lpi example_echo_min_poll_nb.lpi"

echo ========================================
echo Building Lazarus projects
echo ========================================
for %%P in (%PROJECTS%) do (
  echo [BUILD] %LAZBUILD% %EXAMPLES_DIR%%%P (project default mode)
  call "%LAZBUILD%" "%EXAMPLES_DIR%%%P"
  if errorlevel 1 exit /b 1
)

echo ========================================
echo Building standalone Pascal examples
echo ========================================
for %%P in (best_practices_nonblocking.pas) do (
  echo [BUILD] %FPC% %%P ^> %BIN_DIR%%%~nP.exe
  call "%FPC%" -MObjFPC -Scghi -O1 -g -gl -l -vewnhibq -Fu"%PROJECT_ROOT%\src" -Fu"%EXAMPLES_DIR%" -FU"%LIB_DIR%\fpc" -FE"%BIN_DIR%" -o"%BIN_DIR%%%~nP.exe" "%EXAMPLES_DIR%%%P"
  if errorlevel 1 exit /b 1
)

echo.
echo ========================================
echo Build Complete
echo ========================================
echo.
echo Executable location:
echo   %BIN_DIR%\example_socket.exe
echo   %BIN_DIR%\echo_server.exe
echo   %BIN_DIR%\echo_client.exe
echo   %BIN_DIR%\udp_server.exe
echo   %BIN_DIR%\udp_client.exe
echo   %BIN_DIR%\best_practices_nonblocking.exe
echo   %BIN_DIR%\example_echo_min_poll_nb.exe
echo.
echo Run examples:
echo   %BIN_DIR%\example_socket.exe address-demo
echo   %BIN_DIR%\example_socket.exe tcp-server 8080
echo   %BIN_DIR%\example_socket.exe tcp-client localhost 8080
echo   %BIN_DIR%\echo_server.exe --port=8080
echo   %BIN_DIR%\echo_client.exe --host=127.0.0.1 --port=8080 --message="hello"
echo   %BIN_DIR%\udp_server.exe --port=9090
echo   %BIN_DIR%\udp_client.exe --host=127.0.0.1 --port=9090 --message="hello-udp"
echo   %BIN_DIR%\best_practices_nonblocking.exe --demo
echo   %BIN_DIR%\example_echo_min_poll_nb.exe
echo.

if "%FAFAFA_INTERACTIVE%"=="1" pause
exit /b 0
