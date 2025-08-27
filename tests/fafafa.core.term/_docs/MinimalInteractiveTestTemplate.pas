unit MinimalInteractiveTestTemplate;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.term;

// 目的：演示“交互前置 + 作用域 init/done”的最小范式

type
  TTest_MinimalInteractive = class(TTestCase)
  published
    procedure Test_Clear_Succeeds_When_Interactive;
  end;

implementation

uses tests.fafafa.core.term.TestHelpers_Env, tests.fafafa.core.term.TestHelpers_Skip;

procedure TTest_MinimalInteractive.Test_Clear_Succeeds_When_Interactive;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    CheckTrue(term_clear);
  finally
    term_done;
  end;
end;

initialization
  RegisterTest(TTest_MinimalInteractive);

end.
