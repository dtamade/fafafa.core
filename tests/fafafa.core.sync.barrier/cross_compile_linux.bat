@echo off
echo ========================================
echo fafafa.core.sync.barrier Linux Cross-Compilation
echo ========================================
echo.

echo 1. Cleaning previous Linux build...
if exist "fafafa.core.sync.barrier.test" del "fafafa.core.sync.barrier.test"
if exist "lib" rmdir /s /q "lib" 2>nul

echo 2. Cross-compiling for Linux x86_64...
lazbuild --cpu=x86_64 --os=linux fafafa.core.sync.barrier.test.lpi
set BUILD_RESULT=%ERRORLEVEL%

if %BUILD_RESULT% equ 0 (
    echo   SUCCESS: Linux cross-compilation completed
) else (
    echo   FAILED: Linux cross-compilation failed ^(exit code: %BUILD_RESULT%^)
    exit /b 1
)

echo.
echo 3. Checking generated Linux executable...
if exist "fafafa.core.sync.barrier.test" (
    echo   SUCCESS: Linux executable generated
    echo   File: fafafa.core.sync.barrier.test
) else (
    echo   FAILED: Linux executable not found
    exit /b 1
)

echo.
echo 4. Analyzing build output...
echo   Target OS: Linux x86_64
echo   Compiler: Free Pascal 3.3.1+
echo   Generated files:

dir /b fafafa.core.sync.barrier.test* 2>nul
if exist "lib" (
    echo   Object files: lib\*.o
    echo   Unit files: lib\*.ppu
)

echo.
echo ========================================
echo Cross-compilation Summary:
echo ========================================
echo Platform: Windows to Linux x86_64
echo Status: SUCCESS
echo Executable: fafafa.core.sync.barrier.test
echo Size: 
for %%F in (fafafa.core.sync.barrier.test) do echo   %%~zF bytes

echo.
echo Notes:
echo - Linux executable ready for deployment
echo - Requires Linux x86_64 runtime environment
echo - Uses Unix pthread_barrier_t implementation
echo - Fallback to mutex + condition variable available
echo.
echo To test on Linux:
echo   chmod +x fafafa.core.sync.barrier.test
echo   ./fafafa.core.sync.barrier.test --all
echo.
