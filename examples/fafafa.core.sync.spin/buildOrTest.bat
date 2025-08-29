@echo off
echo Building fafafa.core.sync.spin examples...

set SRC_DIR=..\..\src
set BIN_DIR=bin
set LIB_DIR=lib

if not exist %BIN_DIR% mkdir %BIN_DIR%
if not exist %LIB_DIR% mkdir %LIB_DIR%

echo.
echo Building basic usage example...
fpc -MObjFPC -Scaghi -Fu%SRC_DIR% -FE%BIN_DIR% -FU%LIB_DIR% example_basic_usage.pas
if %ERRORLEVEL% neq 0 goto :error

echo.
echo Building performance benchmark...
fpc -MObjFPC -Scaghi -Fu%SRC_DIR% -FE%BIN_DIR% -FU%LIB_DIR% benchmark_performance.pas
if %ERRORLEVEL% neq 0 goto :error

echo.
echo Building use cases example...
fpc -MObjFPC -Scaghi -Fu%SRC_DIR% -FE%BIN_DIR% -FU%LIB_DIR% example_use_cases.pas
if %ERRORLEVEL% neq 0 goto :error

echo.
echo All examples built successfully!
echo.
echo To run examples:
echo   %BIN_DIR%\example_basic_usage.exe
echo   %BIN_DIR%\benchmark_performance.exe
echo   %BIN_DIR%\example_use_cases.exe
goto :end

:error
echo.
echo Build failed!
exit /b 1

:end
