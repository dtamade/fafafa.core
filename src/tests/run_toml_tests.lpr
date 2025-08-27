program run_toml_tests;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}cthreads,{$ENDIF}{$ENDIF}
  consoletestrunner,
  test_toml_basic,
  fafafa.core.args;

var opts: TArgsOptions;
begin
  // Best-practice: enable --no-xxx negation semantics globally for this program
  opts := ArgsOptionsDefault;
  opts.EnableNoPrefixNegation := True;
  ArgsOptionsSetDefault(opts);

  // Register TOML tests
  test_toml_basic.RegisterTomlBasicTests;
  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
end.

