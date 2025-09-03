unit test_tick_core;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.tick, fafafa.core.time.duration;

// 严格的最小可编译测试：只验证公共 API 的基本契约
// 后续可逐步扩展更严格的行为测试

type
  TTest_Tick_API = class(TTestCase)
  published
    procedure Test_GetTickTypeName_All;
    procedure Test_DefaultTick_Basic;
    procedure Test_HighPrecisionTick_Basic;
    procedure Test_SystemTick_Basic;
    procedure Test_QuickMeasure_Basic;
  end;

implementation

procedure TTest_Tick_API.Test_GetTickTypeName_All;
var
  t: TTickType;
  name: string;
begin
  for t := Low(TTickType) to High(TTickType) do
  begin
    name := GetTickTypeName(t);
    AssertTrue('TickType name must be non-empty', name <> '');
  end;
end;

procedure TTest_Tick_API.Test_DefaultTick_Basic;
var
  tick: ITick;
begin
  tick := DefaultTick;
  AssertTrue('DefaultTick should return non-nil', tick <> nil);
  AssertTrue('Resolution must be > 0', tick.GetResolution > 0);
  AssertTrue('Current tick must be > 0', tick.GetCurrentTick > 0);
end;

procedure TTest_Tick_API.Test_HighPrecisionTick_Basic;
var
  tick: ITick;
begin
  tick := HighPrecisionTick;
  AssertTrue('HighPrecisionTick should return non-nil', tick <> nil);
  AssertTrue('Resolution must be > 0', tick.GetResolution > 0);
end;

procedure TTest_Tick_API.Test_SystemTick_Basic;
var
  tick: ITick;
begin
  tick := SystemTick;
  AssertTrue('SystemTick should return non-nil', tick <> nil);
  AssertTrue('Resolution must be > 0', tick.GetResolution > 0);
end;

procedure TTest_Tick_API.Test_QuickMeasure_Basic;
var
  d: TDuration;
begin
  d := QuickMeasure(
    procedure
    begin
      // 空过程，测量框架运行开销
    end
  );
  // 只要求可调用且返回非负
  AssertTrue('QuickMeasure returns non-negative duration', d.AsNs >= 0);
end;

initialization
  RegisterTest(TTest_Tick_API);

end.

