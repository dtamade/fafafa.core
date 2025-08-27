unit Test_fafafa_core_time_platform_sleep;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time;

type
  TTestCase_PlatformSleep = class(TTestCase)
  published
    procedure Test_CrossPlatform_Sleep_Tolerance;
  end;

implementation

procedure TTestCase_PlatformSleep.Test_CrossPlatform_Sleep_Tolerance;
var
  t0, t1: TInstant;
  dMs: Int64;
  old: TSleepStrategy;
begin
  old := GetSleepStrategy;
  try
    SetSleepStrategy(Balanced);
    
    {$IFDEF LINUX}
    // Linux: nanosleep/clock_nanosleep 路径，允许更宽容的误差
    t0 := NowInstant;
    SleepFor(TDuration.FromMs(5));
    t1 := NowInstant;
    dMs := t1.Diff(t0).AsMs;
    // Linux 下允许 [2, 50] ms 的宽松区间
    CheckTrue(dMs >= 2, Format('Linux sleep too short: %d ms', [dMs]));
    CheckTrue(dMs <= 50, Format('Linux sleep too long: %d ms', [dMs]));
    {$ENDIF}
    
    {$IFDEF DARWIN}
    // macOS: mach_wait_until 路径，通常精度较好但允许调度延迟
    t0 := NowInstant;
    SleepFor(TDuration.FromMs(3));
    t1 := NowInstant;
    dMs := t1.Diff(t0).AsMs;
    // macOS 下允许 [1, 30] ms 的宽松区间
    CheckTrue(dMs >= 1, Format('macOS sleep too short: %d ms', [dMs]));
    CheckTrue(dMs <= 30, Format('macOS sleep too long: %d ms', [dMs]));
    {$ENDIF}
    
    {$IFDEF MSWINDOWS}
    // Windows: 已在其他用例覆盖，这里仅做基本验证
    t0 := NowInstant;
    SleepFor(TDuration.FromMs(2));
    t1 := NowInstant;
    dMs := t1.Diff(t0).AsMs;
    CheckTrue(dMs >= 1, Format('Windows sleep too short: %d ms', [dMs]));
    CheckTrue(dMs <= 25, Format('Windows sleep too long: %d ms', [dMs]));
    {$ENDIF}
    
  finally
    SetSleepStrategy(old);
  end;
end;

initialization
  RegisterTest(TTestCase_PlatformSleep);
end.
