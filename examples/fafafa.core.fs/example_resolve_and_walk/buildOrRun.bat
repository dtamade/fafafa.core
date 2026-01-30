@echo off
setlocal

set LAZBUILD_EXE=lazbuild
set PRJ=%~dp0example_resolve_and_walk.lpi

%LAZBUILD_EXE% "%PRJ%" || goto :eof

set BIN=%~dp0bin\example_resolve_and_walk.exe
if exist "%BIN%" (
  echo Running example...
  "%BIN%"
) else (
  set BIN=%~dp0bin\example_resolve_and_walk
  if exist "%BIN%" (
    echo Running example...
    "%BIN%"
  ) else (
    echo Executable not found in bin\
  )
)

