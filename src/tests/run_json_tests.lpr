program run_json_tests;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}cthreads,{$ENDIF}{$ENDIF}
  consoletestrunner,
  test_json_reader_basic,
  test_json_pointer_basic;

begin
  RegisterTests; // from test_json_reader_basic
  RegisterJsonPointerTests;
  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
end.

