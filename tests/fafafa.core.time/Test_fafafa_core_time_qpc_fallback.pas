unit Test_fafafa_core_time_qpc_fallback;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.testhooks;

type
  TTestCase_QpcFallback = class(TTestCase)
  published
    procedure Test_ForceGTC64_Path_Monotonic_And_Sleep;
  end;

implementation

procedure TTestCase_QpcFallback.Test_ForceGTC64_Path_Monotonic_And_Sleep;
begin
  {$IFDEF MSWINDOWS}
  // 强制退化路径
  Test_ForceUseGTC64_ForWindows(True);
  // NowInstant 单调递增
  CheckTrue(DefaultMonotonicClock.NowInstant.Diff(DefaultMonotonicClock.NowInstant).AsNs >= 0);
  // SleepFor/WaitFor 在退化路径下可用
  DefaultMonotonicClock.SleepFor(TDuration.FromMs(2));
  CheckTrue(DefaultMonotonicClock.WaitFor(TDuration.FromMs(1), nil));
  // 退化计数（测试可见）查询
  CheckTrue(Test_GetWindowsQpcFallbackCount >= 0);
  // 恢复
  Test_ForceUseGTC64_ForWindows(False);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_QpcFallback);
end.

