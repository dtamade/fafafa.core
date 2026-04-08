@echo off
setlocal
cd /d "%~dp0"

if "%LAZBUILD%"=="" set "LAZBUILD=lazbuild"
if "%FPC%"=="" set "FPC=fpc"

if exist "*.lpi" (
  where "%LAZBUILD%" >nul 2>nul
  if errorlevel 1 (
    echo [BuildAndRun] lazbuild not found: %LAZBUILD%
    exit /b 1
  )
  for %%p in (*.lpi) do (
    echo [BUILD] %LAZBUILD% %%p (project default mode)
    call "%LAZBUILD%" "%%p"
    if errorlevel 1 exit /b 1
  )
) else (
  if not exist "*.lpr" if not exist "*.pas" (
    echo [BuildAndRun] no project source found
    exit /b 1
  )
  where "%FPC%" >nul 2>nul
  if errorlevel 1 (
    echo [BuildAndRun] fpc not found: %FPC%
    exit /b 1
  )
  if not exist "bin" mkdir bin
  if not exist "lib\fpc" mkdir lib\fpc
  for %%p in (*.lpr *.pas) do (
    echo [BUILD] %FPC% %%p ^> bin\%%~np.exe
    call "%FPC%" -MObjFPC -Scghi -O1 -g -gl -l -vewnhibq -Fu..\..\src -Fu. -FUlib\fpc -FEbin -o"bin\%%~np.exe" "%%p"
    if errorlevel 1 exit /b 1
  )
)

echo [RUN] Running example...
for %%f in (bin\*.exe) do (
  echo [RUN] %%f
  "%%f"
  if errorlevel 1 exit /b 1
)

if "%FAFAFA_INTERACTIVE%"=="1" pause
exit /b 0
