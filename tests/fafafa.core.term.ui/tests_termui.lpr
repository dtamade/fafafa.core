program tests_termui;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils,
  fpcunit, testregistry, testutils, TextTestRunner,
  fafafa.core.term.ui;

begin
  // Run all registered tests with plain output by default.
  if IsConsole then
    TextTestRunner.RunRegisteredTests
  else
    RunRegisteredTests;
end.

