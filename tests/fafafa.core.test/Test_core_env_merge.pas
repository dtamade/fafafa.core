unit Test_core_env_merge;

{$mode ObjFPC}{$H+}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.args, fafafa.core.args.command, args_test_helper;

type
  { TTestCase_Core_EnvMerge }
  TTestCase_Core_EnvMerge = class(TTestCase)
  published
    procedure Test_CLI_Takes_Precedence_Over_ENV;
  end;

procedure RegisterTests;

implementation

function H_Capture(const A: IArgs): Integer;
begin
  // Assert precedence inside handler for clarity
  // but we simply return 0 here; assertions are outside
  Exit(0);
end;

procedure RegisterTests;
begin
  testregistry.RegisterTest(TTestCase_Core_EnvMerge);
end;

procedure TTestCase_Core_EnvMerge.Test_CLI_Takes_Precedence_Over_ENV;
var Root: IRootCommand; Opts: TArgsOptions; code: Integer;
    cliArgv, merged: array of string;
    A: IArgs;
    v: string;
    ok: boolean;
begin
  // root and simple command
  Root := NewRootCommand;
  Root.Register(NewCommandPath(['run'], @H_Capture, 'desc'));

  // 使用 helper 构造合并 argv：ENV('APP_') 之后接 CLI，保证 last-wins
  SetLength(cliArgv, 2);
  cliArgv[0] := 'run'; cliArgv[1] := '--count=5';
  merged := MakeMergedArgv(cliArgv, 'APP_');

  // run
  Opts := MakeDefaultOpts;
  code := Root.Run(merged, Opts);
  AssertEquals(0, code);

  // After run, we can separately parse to verify precedence
  A := TArgs.FromArray(merged, Opts);
  ok := A.TryGetValue('count', v);
  AssertTrue(ok);
  AssertEquals('5', v);
  AssertTrue(A.HasFlag('debug'));
end;

end.

