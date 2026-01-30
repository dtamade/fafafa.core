unit Test_fafafa_core_time_cpu_basic;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.cpu,
  fafafa.core.time, fafafa.core.time.duration;

type
  { 基础用例：验证 CpuRelax/SchedYield/NanoSleep 的可调用性与基本时间语义 }
  TTestCase_TimeCPU_Basic = class(TTestCase)
  published
    procedure Test_CpuRelax_Callable_NoCrash;
    procedure Test_SchedYield_Callable_NoCrash;
    procedure Test_NanoSleep_Basic_Ranges;
  end;

implementation

procedure TTestCase_TimeCPU_Basic.Test_CpuRelax_Callable_NoCrash;
var
  i: Integer;
begin
  // 调用若干次，确保不会崩溃（不同架构分支）
  for i := 1 to 128 do
    CpuRelax;
  CheckTrue(True);
end;

procedure TTestCase_TimeCPU_Basic.Test_SchedYield_Callable_NoCrash;
var
  i: Integer;
begin
  for i := 1 to 16 do
    SchedYield;
  CheckTrue(True);
end;

procedure TTestCase_TimeCPU_Basic.Test_NanoSleep_Basic_Ranges;
var
  t0, t1: TInstant;
  d0ns, d1ns, d2ns: Int64;
begin
  // 使用统一的时间 API 来衡量时间消耗
  t0 := NowInstant; NanoSleep(200000); t1 := NowInstant; d0ns := t1.Diff(t0).AsNs; // 0.2ms
  t0 := NowInstant; NanoSleep(1000000); t1 := NowInstant; d1ns := t1.Diff(t0).AsNs; // 1ms
  t0 := NowInstant; NanoSleep(5*1000000); t1 := NowInstant; d2ns := t1.Diff(t0).AsNs; // 5ms

  // 单调性
  CheckTrue(d1ns >= d0ns);
  CheckTrue(d2ns >= d1ns);

  // 宽松上界，避免不同平台调度差异导致脆弱
  // 5ms 目标值，允许不超过 60ms
  CheckTrue(d2ns <= 60 * 1000 * 1000);
end;

initialization
  RegisterTest(TTestCase_TimeCPU_Basic);
end.


