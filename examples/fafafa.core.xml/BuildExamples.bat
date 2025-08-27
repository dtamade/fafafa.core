@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"

set "OUT_DIR=%SCRIPT_DIR%bin"
set "LIB_DIR=%SCRIPT_DIR%lib"

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"

rem Build reader
call "%LAZBUILD%" "%SCRIPT_DIR%example_xml_reader.lpi" --bm=Debug --ws=nogui --lazarusdir=""
if %ERRORLEVEL% NEQ 0 goto :ERR

rem Build writer
call "%LAZBUILD%" "%SCRIPT_DIR%example_xml_writer.lpi" --bm=Debug --ws=nogui --lazarusdir=""
if %ERRORLEVEL% NEQ 0 goto :ERR

rem Build config demo
call "%LAZBUILD%" "%SCRIPT_DIR%example_xml_config.lpi" --bm=Debug --ws=nogui --lazarusdir=""
if %ERRORLEVEL% NEQ 0 goto :ERR

rem Build bench (memory)
call "%LAZBUILD%" "%SCRIPT_DIR%bench_xml_reader.lpi" --bm=Debug --ws=nogui --lazarusdir=""
if %ERRORLEVEL% NEQ 0 goto :ERR

rem Build bench (file)
call "%LAZBUILD%" "%SCRIPT_DIR%bench_xml_reader_file.lpi" --bm=Debug --ws=nogui --lazarusdir=""
if %ERRORLEVEL% NEQ 0 goto :ERR

rem Build writer attr+pretty combined
call "%LAZBUILD%" "%SCRIPT_DIR%example_writer_attr_pretty_combined.lpi" --bm=Debug --ws=nogui --lazarusdir=""
if %ERRORLEVEL% NEQ 0 goto :ERR

rem Build reader autodecode
call "%LAZBUILD%" "%SCRIPT_DIR%example_xml_reader_autodecode.lpi" --bm=Debug --ws=nogui --lazarusdir=""
if %ERRORLEVEL% NEQ 0 goto :ERR

echo.
echo [OK] Examples built into bin/ (libs in lib/)
goto END

:ERR
echo Build failed with error code %ERRORLEVEL%.

:END
endlocal

