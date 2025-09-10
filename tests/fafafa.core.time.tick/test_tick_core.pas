unit test_tick_core;

{$MODE OBJFPC}{$H+}
{$modeswitch anonymousfunctions}
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
    procedure Test_BestTick_Basic;
    procedure Test_TickFrom_Basic;
    procedure Test_QuickMeasure_Basic;
    procedure Test_SystemTick_Basic; // updated to record style
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

procedure TTest_Tick_API.Test_BestTick_Basic;
var
  c: TTick;
begin
  c := BestTick;
  AssertTrue('Now > 0', c.Now > 0);
  AssertTrue('Frequency > 0', c.FrequencyHz > 0);
  AssertTrue('MinStep > 0', c.MinStep.AsNs > 0);
end;

procedure TTest_Tick_API.Test_TickFrom_Basic;
var
  c: TTick;
begin
  c := TickFrom(ttHighPrecision);
  AssertTrue('Now > 0', c.Now > 0);
  AssertTrue('Frequency > 0', c.FrequencyHz > 0);
end;

procedure TTest_Tick_API.Test_SystemTick_Basic;
var
  c: TTick;
begin
  c := TTick.From(ttSystem);
  AssertTrue('Now > 0', c.Now > 0);
  AssertTrue('MinStep must be > 0', c.MinStep.AsNs > 0);
end;

procedure TTest_Tick_API.Test_QuickMeasure_Basic;
var
  d: TDuration;
begin
  d := QuickMeasure(procedure
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
