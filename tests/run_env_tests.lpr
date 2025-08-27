program run_env_tests;

{$mode objfpc}{$H+}
{$I src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}cthreads,{$ENDIF}{$ENDIF}
  consoletestrunner,
  fafafa.core.env.testcase;

begin
  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
end.

