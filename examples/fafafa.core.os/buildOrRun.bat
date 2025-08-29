@echo off
echo Building fafafa.core.os system info example...
lazbuild example_system_info.lpi
if %errorlevel% neq 0 (
    echo Build failed!
    exit /b 1
)
echo Build successful!
echo.
echo Running example...
echo.
bin\example_system_info.exe
echo.
echo Example completed.
pause
