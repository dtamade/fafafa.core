@echo off
echo ========================================
echo Verifying fafafa.core.sync.spin builds
echo ========================================

echo Checking Windows build...
if exist bin\fafafa.core.sync.spin.test.exe (
    echo [OK] Windows executable: bin\fafafa.core.sync.spin.test.exe
    for %%F in (bin\fafafa.core.sync.spin.test.exe) do echo   Size: %%~zF bytes
) else (
    echo [FAIL] Windows executable not found
)

echo.
echo Checking Linux build...
if exist bin\fafafa.core.sync.spin.test (
    echo [OK] Linux executable: bin\fafafa.core.sync.spin.test
    for %%F in (bin\fafafa.core.sync.spin.test) do echo   Size: %%~zF bytes
) else (
    echo [FAIL] Linux executable not found
)

echo.
echo Build verification complete!

echo.
echo Usage instructions:
echo Windows: bin\fafafa.core.sync.spin.test.exe
echo Linux:   chmod +x fafafa.core.sync.spin.test && ./fafafa.core.sync.spin.test
