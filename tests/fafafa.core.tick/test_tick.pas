unit test_tick;

{$MODE OBJFPC}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.tick;

type

  { TTickTest }

  TTickTest = class(TTestCase)
  published
    procedure Test_GetAvailableTickTypes;
    procedure Test_GetTickTypeName;
    procedure Test_HasHardwareTick;
    procedure Test_MakeTick;
    procedure Test_MakeBestTick;
  end;

implementation

procedure TTickTest.Test_GetAvailableTickTypes;
var
  Types: TTickTypes;
begin
  Types := GetAvailableTickTypes;
  // 至少应该有标准计时器
  Check(ttStandard in Types, 'Standard tick should be available');
end;

procedure TTickTest.Test_GetTickTypeName;
begin
  CheckEquals('Standard Precision Timer', GetTickTypeName(ttStandard));
  CheckEquals('High Precision Timer', GetTickTypeName(ttHighPrecision));
  CheckEquals('Hardware Timer', GetTickTypeName(ttHardware));
end;

procedure TTickTest.Test_HasHardwareTick;
begin
  // 只检查函数可调用，不检查具体值（平台相关）
  HasHardwareTick;
  Check(True);
end;

procedure TTickTest.Test_MakeTick;
var
  Tick: ITick;
begin
  Tick := MakeTick(ttStandard);
  CheckNotNull(Tick, 'MakeTick(ttStandard) should return non-nil');
end;

procedure TTickTest.Test_MakeBestTick;
var
  Tick: ITick;
begin
  Tick := MakeBestTick;
  CheckNotNull(Tick, 'MakeBestTick should return non-nil');
end;

initialization
  RegisterTest(TTickTest);
end.
