@echo off
setlocal enabledelayedexpansion

echo Cleaning fafafa.core project...
echo.

set "deleted_count=0"

echo Removing .o files...
for /r . %%f in (*.o) do (
    if exist "%%f" (
        echo Deleting: %%f
        del "%%f" /q >nul 2>&1
        set /a deleted_count+=1
    )
)

echo Removing .ppu files...
for /r . %%f in (*.ppu) do (
    if exist "%%f" (
        echo Deleting: %%f
        del "%%f" /q >nul 2>&1
        set /a deleted_count+=1
    )
)

echo.
echo Cleanup completed!
echo Deleted !deleted_count! files.
echo.

echo Press any key to continue...
pause >nul
