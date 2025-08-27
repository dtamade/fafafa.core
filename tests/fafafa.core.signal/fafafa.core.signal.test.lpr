program fafafa_core_signal_tests;
{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}cthreads,{$ENDIF}{$ENDIF}
  consoletestrunner, fpcunit, testregistry,
  fafafa.core.signal, fafafa.core.env,
  fafafa.core.signal.testcase,
  fafafa.core.signal.extra.testcase,
  fafafa.core.signal.extra2.testcase,
  fafafa.core.signal.stop_semantics.testcase,
  fafafa.core.signal.trystart_fail.testcase;

begin
  // Ensure Windows ConsoleCtrlHandler is disabled inside tests even when run manually
  env_set('FAFAFA_SIGNAL_TEST_DISABLE_WINCTRL', '1');
  with TTestRunner.Create(nil) do
  begin
    Initialize;
    WriteLn('[RUNNER] BEGIN'); System.Flush(Output);
    Run;
    WriteLn('[RUNNER] END'); System.Flush(Output);
    Free;
  end;
end.

