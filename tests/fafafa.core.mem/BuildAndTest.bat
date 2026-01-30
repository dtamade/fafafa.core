@echo off

echo ===============================================
echo  fafafa.core.mem Unit Tests
echo ===============================================
echo.

echo Building with lazbuild...
lazbuild --build-mode=Debug tests\fafafa.core.mem\tests_mem.lpi

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed
    goto END
)
echo Build successful!

echo.
echo Running tests...
echo.
tests\fafafa.core.mem\bin\tests_mem_debug.exe --all --format=plain

echo.
echo ===============================================
echo  Tests completed
echo ===============================================

:END
pause
