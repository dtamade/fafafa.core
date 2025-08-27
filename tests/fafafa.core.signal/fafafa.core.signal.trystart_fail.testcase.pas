unit fafafa.core.signal.trystart_fail.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, sysutils,
  fafafa.core.signal, fafafa.core.env;

type
  TTestCase_TryStartFail = class(TTestCase)
  published
    procedure Test_TryStart_Fail_By_Env;
    procedure Test_TryStop_Fail_By_Env;
  end;

implementation

procedure TTestCase_TryStartFail.Test_TryStart_Fail_By_Env;
var C: ISignalCenter; ok: Boolean; Err: string; G: TEnvOverrideGuard;
begin
  // 注入 Start 失败
  G := env_override('FAFAFA_SIGNAL_TEST_FAIL_START', '1');
  try
    C := SignalCenter;
    ok := C.TryStart(Err);
    CheckFalse(ok, 'TryStart should fail by env');
    CheckTrue(Err <> '', 'Err should not be empty');
  finally
    G.Done;
  end;
end;

procedure TTestCase_TryStartFail.Test_TryStop_Fail_By_Env;
var C: ISignalCenter; ok: Boolean; Err: string; G: TEnvOverrideGuard;
begin
  C := SignalCenter;
  C.Start;
  // 注入 Stop 失败
  G := env_override('FAFAFA_SIGNAL_TEST_FAIL_STOP', '1');
  try
    ok := C.TryStop(Err);
    CheckFalse(ok, 'TryStop should fail by env');
    CheckTrue(Err <> '', 'Err should not be empty');
  finally
    G.Done;
    // 确保停止（避免影响后续用例）
    C.Stop;
  end;
end;

initialization
  RegisterTest(TTestCase_TryStartFail);

end.

