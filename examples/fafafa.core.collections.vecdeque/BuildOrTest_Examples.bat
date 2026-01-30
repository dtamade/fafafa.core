@echo off
setlocal EnableExtensions EnableDelayedExpansion

set SCRIPT_DIR=%~dp0
set FPC_EXE=fpc
set FPC_OPTS=-MObjFPC -Scghi -O1 -gl -gh -Xg -vewnhibq

set EX1="%SCRIPT_DIR%example_growth_object_based_min.lpr"
set EX2="%SCRIPT_DIR%example_growth_interface_based_min.lpr"
set EX3="%SCRIPT_DIR%example_growth_page_aligned_min.lpr"
set EX4="%SCRIPT_DIR%example_growth_hugepage_aligned_min.lpr"
set EX5="%SCRIPT_DIR%example_growth_page_aligned_portable_min.lpr"

if "%1"=="clean" goto :clean

if not exist "%SCRIPT_DIR%bin" mkdir "%SCRIPT_DIR%bin"
if not exist "%SCRIPT_DIR%lib" mkdir "%SCRIPT_DIR%lib"

:build
%FPC_EXE% %FPC_OPTS% -I"%SCRIPT_DIR%..\..\src" -Fu"%SCRIPT_DIR%..\..\src" -FU"%SCRIPT_DIR%lib" -FE"%SCRIPT_DIR%bin" %EX1%
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
%FPC_EXE% %FPC_OPTS% -I"%SCRIPT_DIR%..\..\src" -Fu"%SCRIPT_DIR%..\..\src" -FU"%SCRIPT_DIR%lib" -FE"%SCRIPT_DIR%bin" %EX2%
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
%FPC_EXE% %FPC_OPTS% -I"%SCRIPT_DIR%..\..\src" -Fu"%SCRIPT_DIR%..\..\src" -FU"%SCRIPT_DIR%lib" -FE"%SCRIPT_DIR%bin" %EX3%
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
%FPC_EXE% %FPC_OPTS% -I"%SCRIPT_DIR%..\..\src" -Fu"%SCRIPT_DIR%..\..\src" -FU"%SCRIPT_DIR%lib" -FE"%SCRIPT_DIR%bin" %EX4%
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
%FPC_EXE% %FPC_OPTS% -I"%SCRIPT_DIR%..\..\src" -Fu"%SCRIPT_DIR%..\..\src" -FU"%SCRIPT_DIR%lib" -FE"%SCRIPT_DIR%bin" %EX5%
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

echo.
echo Running examples...
"%SCRIPT_DIR%bin\example_growth_object_based_min.exe"
set R=%ERRORLEVEL%
if not %R%==0 echo [FAIL] example_growth_object_based_min (exit %R%) & exit /b %R%
"%SCRIPT_DIR%bin\example_growth_interface_based_min.exe"
set R=%ERRORLEVEL%
if not %R%==0 echo [FAIL] example_growth_interface_based_min (exit %R%) & exit /b %R%
"%SCRIPT_DIR%bin\example_growth_page_aligned_min.exe"
set R=%ERRORLEVEL%
if not %R%==0 echo [FAIL] example_growth_page_aligned_min (exit %R%) & exit /b %R%
"%SCRIPT_DIR%bin\example_growth_hugepage_aligned_min.exe"
set R=%ERRORLEVEL%
if not %R%==0 echo [FAIL] example_growth_hugepage_aligned_min (exit %R%) & exit /b %R%
"%SCRIPT_DIR%bin\example_growth_page_aligned_portable_min.exe"
set R=%ERRORLEVEL%
if not %R%==0 echo [FAIL] example_growth_page_aligned_portable_min (exit %R%) & exit /b %R%
echo [PASS] All examples OK
exit /b 0

:clean
if exist "%SCRIPT_DIR%bin\example_growth_object_based_min.exe" del /q "%SCRIPT_DIR%bin\example_growth_object_based_min.exe"
if exist "%SCRIPT_DIR%bin\example_growth_interface_based_min.exe" del /q "%SCRIPT_DIR%bin\example_growth_interface_based_min.exe"
if exist "%SCRIPT_DIR%lib" rmdir /s /q "%SCRIPT_DIR%lib"
exit /b 0

