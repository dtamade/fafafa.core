@echo off
setlocal ENABLEDELAYEDEXPANSION
set ROOT=%~dp0..\..\..
set EXAMPLE_DIR=%~dp0
set BIN_DIR=%EXAMPLE_DIR%bin\
set LIB_DIR=%EXAMPLE_DIR%lib\
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"

set LPI=%EXAMPLE_DIR%example_realtime.lpi

if not exist "%LPI%" (
  echo Creating minimal .lpi project file...
  >"%LPI%" echo ^<?xml version="1.0" encoding="UTF-8"?^>
  >>"%LPI%" echo ^<CONFIG^>
  >>"%LPI%" echo   ^<ProjectOptions^>
  >>"%LPI%" echo     ^<Version Value="12"/^>
  >>"%LPI%" echo     ^<PathDelim Value="\"/^>
  >>"%LPI%" echo     ^<General^>
  >>"%LPI%" echo       ^<Title Value="example_realtime"/^>
  >>"%LPI%" echo       ^<Scaled Value="True"/^>
  >>"%LPI%" echo       ^<ResourceType Value="res"/^>
  >>"%LPI%" echo       ^<UseXPManifest Value="True"/^>
  >>"%LPI%" echo     ^</General^>
  >>"%LPI%" echo     ^<BuildModes^>
  >>"%LPI%" echo       ^<Item Name="Debug" Default="True"^>
  >>"%LPI%" echo         ^<CompilerOptions^>
  >>"%LPI%" echo           ^<Version Value="11"/^>
  >>"%LPI%" echo           ^<Target^>
  >>"%LPI%" echo             ^<Filename Value=".\bin\example_realtime"/^>
  >>"%LPI%" echo           ^</Target^>
  >>"%LPI%" echo           ^<SearchPaths^>
  >>"%LPI%" echo             ^<IncludeFiles Value="$(ProjOutDir);..\..\..\src"/^>
  >>"%LPI%" echo             ^<OtherUnitFiles Value="..\..\..\src"/^>
  >>"%LPI%" echo             ^<UnitOutputDirectory Value="lib\$(TargetCPU)-$(TargetOS)"/^>
  >>"%LPI%" echo           ^</SearchPaths^>
  >>"%LPI%" echo           ^<Linking^>
  >>"%LPI%" echo             ^<Debugging^>
  >>"%LPI%" echo               ^<DebugInfoType Value="dsDwarf3"/^>
  >>"%LPI%" echo               ^<UseHeaptrc Value="True"/^>
  >>"%LPI%" echo             ^</Debugging^>
  >>"%LPI%" echo           ^</Linking^>
  >>"%LPI%" echo         ^</CompilerOptions^>
  >>"%LPI%" echo       ^</Item^>
  >>"%LPI%" echo     ^</BuildModes^>
  >>"%LPI%" echo     ^<Units^>
  >>"%LPI%" echo       ^<Unit^>
  >>"%LPI%" echo         ^<Filename Value="example_realtime.lpr"/^>
  >>"%LPI%" echo         ^<IsPartOfProject Value="True"/^>
  >>"%LPI%" echo       ^</Unit^>
  >>"%LPI%" echo     ^</Units^>
  >>"%LPI%" echo   ^</ProjectOptions^>
  >>"%LPI%" echo   ^<CompilerOptions^>
  >>"%LPI%" echo     ^<Version Value="11"/^>
  >>"%LPI%" echo     ^<Target^>
  >>"%LPI%" echo       ^<Filename Value=".\bin\example_realtime"/^>
  >>"%LPI%" echo     ^</Target^>
  >>"%LPI%" echo     ^<SearchPaths^>
  >>"%LPI%" echo       ^<IncludeFiles Value="$(ProjOutDir);..\..\..\src"/^>
  >>"%LPI%" echo       ^<OtherUnitFiles Value="..\..\..\src"/^>
  >>"%LPI%" echo       ^<UnitOutputDirectory Value="lib\$(TargetCPU)-$(TargetOS)"/^>
  >>"%LPI%" echo     ^</SearchPaths^>
  >>"%LPI%" echo   ^</CompilerOptions^>
  >>"%LPI%" echo ^</CONFIG^>
)

call "%ROOT%\tools\lazbuild.bat" "%LPI%"
if errorlevel 1 (
  echo Build failed
  exit /b 1
)

"%BIN_DIR%example_realtime.exe"

