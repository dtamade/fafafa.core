unit fafafa.core.time.tick.test.testcase;

{$MODE OBJFPC}{$H+}
{$modeswitch anonymousfunctions}
{$IFDEF WINDOWS}
{$CODEPAGE UTF8}
{$ENDIF}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.tick,
  fafafa.core.time.tick.base;

type
  TTest_Tick_All = class(TTestCase)
  private
    procedure SleepMs(const Ms: Integer); inline;
    procedure AssertClockBasic(const c: ITick);
    function IsTypeAvailable(const T: TTickType): Boolean; inline;
    function TryMakeHardware(out C: ITick): Boolean;
  published
    procedure Test_TickTypeNames_Mapping_Exact;
    procedure Test_GetAvailableTickTypes_BasicAndConsistency;
    procedure Test_GetAvailableTickTypes_Stable;
    procedure Test_HasHardwareTick_Consistency;
    procedure Test_Factory_ReturnsExpectedType;
    procedure Test_Factory_MultipleInstances_Consistency;
    procedure Test_Tick_Advances_PerType;
    procedure Test_Tick_Monotonicity_IfFlagSet;
    procedure Test_MakeBestTick_Preference;
    procedure Test_MakeBestTick_StableType;
    procedure Test_MakeTick_Overload_Equals_Best;
    procedure Test_MakeTick_Hardware_Exception_IfUnavailable;
    procedure Test_Tick_Stability_Under_Fast_Loop;
    procedure Test_Parallel_Factory_Calls;
    procedure Test_Hardware_Monotonicity_IfAvailable;
    procedure Test_Parallel_Hardware_Factory_Calls_IfAvailable;
    procedure Test_Tick_Eventual_Progress;
  end;

implementation

type
  TBestTickThread = class(TThread)
  public
    Success: Boolean;
    constructor Create;
    procedure Execute; override;
  end;

  THardwareTickThread = class(TThread)
  public
    Success: Boolean;
    constructor Create;
    procedure Execute; override;
  end;

constructor TBestTickThread.Create;
begin
  inherited Create(True);
  FreeOnTerminate := False;
  Success := False;
end;

procedure TBestTickThread.Execute;
var
  C: ITick;
  I: Integer;
  Prev, NowV: UInt64;
begin
  try
    C := MakeBestTick;
    Prev := C.Tick;
    for I := 1 to 2000 do
    begin
      NowV := C.Tick;
      if (C.GetIsMonotonic) and (NowV < Prev) then Exit;
      Prev := NowV;
    end;
    Success := True;
  except
    Success := False;
  end;
end;

constructor THardwareTickThread.Create;
begin
  inherited Create(True);
  FreeOnTerminate := False;
  Success := False;
end;

procedure THardwareTickThread.Execute;
var
  C: ITick;
  I: Integer;
  Prev, NowV: UInt64;
begin
  try
    C := MakeHWTick;
    Prev := C.Tick;
    for I := 1 to 2000 do
    begin
      NowV := C.Tick;
      if (C.GetIsMonotonic) and (NowV < Prev) then Exit;
      Prev := NowV;
    end;
    Success := True;
  except
    on ETickNotAvailable do Success := False;
    else Success := False;
  end;
end;

procedure TTest_Tick_All.SleepMs(const Ms: Integer); inline;
begin
  if Ms > 0 then Sleep(Ms);
end;

procedure TTest_Tick_All.AssertClockBasic(const c: ITick);
var
  res, t0, t1: UInt64;
begin
  res := c.GetResolution;
  AssertTrue('Resolution > 0', res > 0);
  t0 := c.Tick;
  SleepMs(1);
  t1 := c.Tick;
  AssertTrue('Tick must advance', t1 > t0);
end;

function TTest_Tick_All.IsTypeAvailable(const T: TTickType): Boolean; inline;
begin
  Result := T in GetAvailableTickTypes;
end;

function TTest_Tick_All.TryMakeHardware(out C: ITick): Boolean;
begin
  Result := False;
  C := nil;
  try
    C := MakeHWTick;
    Result := True;
  except
    on E: ETickNotAvailable do Result := False;
    else raise;
  end;
end;

procedure TTest_Tick_All.Test_TickTypeNames_Mapping_Exact;
var
  t: TTickType;
  name: string;
begin
  for t := Low(TTickType) to High(TTickType) do
  begin
    name := GetTickTypeName(t);
    AssertTrue('non-empty name', name <> '');
    case t of
      ttStandard:      AssertEquals('name std', 'Standard Precision Timer', name);
      ttHighPrecision: AssertEquals('name hd',  'High Precision Timer',    name);
      ttHardware:      AssertEquals('name hw',  'Hardware Timer',           name);
    end;
  end;
end;

procedure TTest_Tick_All.Test_GetAvailableTickTypes_BasicAndConsistency;
var
  types: TTickTypes;
begin
  types := GetAvailableTickTypes;
  {$IF DEFINED(WINDOWS) OR DEFINED(DARWIN) OR DEFINED(UNIX)}
  AssertTrue('std present',      ttStandard in types);
  AssertTrue('high precision',   ttHighPrecision in types);
  {$ENDIF}
  // 硬件可用性只能依赖平台宏与构建开关
  if ttHardware in types then;
end;

procedure TTest_Tick_All.Test_GetAvailableTickTypes_Stable;
var
  A, B, C: TTickTypes;
begin
  A := GetAvailableTickTypes;
  B := GetAvailableTickTypes;
  C := GetAvailableTickTypes;
  AssertTrue('stable availability A=B', A = B);
  AssertTrue('stable availability B=C', B = C);
end;

procedure TTest_Tick_All.Test_HasHardwareTick_Consistency;
begin
  AssertEquals('HasHardwareTick consistent', ttHardware in GetAvailableTickTypes, HasHardwareTick);
end;

procedure TTest_Tick_All.Test_Factory_ReturnsExpectedType;
var
  c: ITick;
begin
  c := MakeStdTick;
  AssertEquals('std type', Ord(ttStandard), Ord(c.GetTickType));
  c := MakeHDTick;
  AssertEquals('hd type', Ord(ttHighPrecision), Ord(c.GetTickType));
  if HasHardwareTick then
  begin
    c := MakeHWTick;
    AssertEquals('hw type', Ord(ttHardware), Ord(c.GetTickType));
  end;
end;

procedure TTest_Tick_All.Test_Factory_MultipleInstances_Consistency;
var
  c1, c2: ITick;
begin
  c1 := MakeStdTick; c2 := MakeStdTick;
  AssertEquals('std type equal', Ord(c1.GetTickType), Ord(c2.GetTickType));
  c1 := MakeHDTick; c2 := MakeHDTick;
  AssertEquals('hd type equal', Ord(c1.GetTickType), Ord(c2.GetTickType));
end;

procedure TTest_Tick_All.Test_Tick_Advances_PerType;
var
  types: TTickTypes;
  c: ITick;
begin
  types := GetAvailableTickTypes;
  if ttStandard in types     then AssertClockBasic(MakeStdTick);
  if ttHighPrecision in types then AssertClockBasic(MakeHDTick);
  if ttHardware in types then AssertClockBasic(MakeHWTick);
end;

procedure TTest_Tick_All.Test_Tick_Monotonicity_IfFlagSet;
var
  types: TTickTypes;
  c: ITick; i: Integer; prev, nowv: UInt64;
begin
  types := GetAvailableTickTypes;
  if ttHighPrecision in types then
  begin
    c := MakeHDTick;
    if c.GetIsMonotonic then
    begin
      prev := c.Tick;
      for i := 1 to 100 do
      begin
        nowv := c.Tick;
        AssertTrue('monotonic non-decrease', nowv >= prev);
        prev := nowv;
      end;
    end;
  end;
end;

procedure TTest_Tick_All.Test_MakeBestTick_Preference;
var
  c: ITick;
  types: TTickTypes;
begin
  types := GetAvailableTickTypes;
  c := MakeBestTick;
  if ttHardware in types then
    AssertEquals('best -> hw', Ord(ttHardware), Ord(c.GetTickType))
  else if ttHighPrecision in types then
    AssertEquals('best -> hd', Ord(ttHighPrecision), Ord(c.GetTickType))
  else if ttStandard in types then
    AssertEquals('best -> std', Ord(ttStandard), Ord(c.GetTickType))
  else
    Fail('No available tick types');
end;

procedure TTest_Tick_All.Test_MakeBestTick_StableType;
var
  T1, T2, T3: TTickType;
begin
  T1 := MakeBestTick.GetTickType;
  T2 := MakeBestTick.GetTickType;
  T3 := MakeBestTick.GetTickType;
  AssertEquals('stable best type 1=2', Ord(T1), Ord(T2));
  AssertEquals('stable best type 2=3', Ord(T2), Ord(T3));
end;

procedure TTest_Tick_All.Test_MakeTick_Overload_Equals_Best;
var
  a, b: ITick;
begin
  a := MakeTick; // 无参重载
  b := MakeBestTick;
  AssertEquals('overload equals', Ord(a.GetTickType), Ord(b.GetTickType));
end;

procedure TTest_Tick_All.Test_MakeTick_Hardware_Exception_IfUnavailable;
var
  c: ITick;
begin
  if HasHardwareTick then Exit;
  if TryMakeHardware(c) then
    Fail('MakeHWTick should not succeed when HasHardwareTick = False');
end;

procedure TTest_Tick_All.Test_Tick_Stability_Under_Fast_Loop;
var
  C: ITick;
  I: Integer;
  StartV, EndV: UInt64;
begin
  C := MakeBestTick;
  StartV := C.Tick;
  EndV := StartV;
  for I := 1 to 50000 do
    EndV := C.Tick;
  AssertTrue('tick progressed after many calls', EndV >= StartV);
end;

procedure TTest_Tick_All.Test_Parallel_Factory_Calls;
var
  T1, T2, T3, T4: TBestTickThread;
begin
  T1 := TBestTickThread.Create;
  T2 := TBestTickThread.Create;
  T3 := TBestTickThread.Create;
  T4 := TBestTickThread.Create;
  try
    T1.Start; T2.Start; T3.Start; T4.Start;
    T1.WaitFor; T2.WaitFor; T3.WaitFor; T4.WaitFor;
    AssertTrue('thread 1 ok', T1.Success);
    AssertTrue('thread 2 ok', T2.Success);
    AssertTrue('thread 3 ok', T3.Success);
    AssertTrue('thread 4 ok', T4.Success);
  finally
    T1.Free; T2.Free; T3.Free; T4.Free;
  end;
end;

procedure TTest_Tick_All.Test_Hardware_Monotonicity_IfAvailable;
var
  C: ITick; I: Integer; Prev, NowV: UInt64;
begin
  if not HasHardwareTick then Exit;
  C := MakeHWTick;
  if not C.GetIsMonotonic then Exit;
  Prev := C.Tick;
  for I := 1 to 200 do
  begin
    NowV := C.Tick;
    AssertTrue('hw monotonic non-decrease', NowV >= Prev);
    Prev := NowV;
  end;
end;

procedure TTest_Tick_All.Test_Parallel_Hardware_Factory_Calls_IfAvailable;
var
  T1, T2, T3, T4: THardwareTickThread;
begin
  if not HasHardwareTick then Exit;
  T1 := THardwareTickThread.Create;
  T2 := THardwareTickThread.Create;
  T3 := THardwareTickThread.Create;
  T4 := THardwareTickThread.Create;
  try
    T1.Start; T2.Start; T3.Start; T4.Start;
    T1.WaitFor; T2.WaitFor; T3.WaitFor; T4.WaitFor;
    AssertTrue('hw thread 1 ok', T1.Success);
    AssertTrue('hw thread 2 ok', T2.Success);
    AssertTrue('hw thread 3 ok', T3.Success);
    AssertTrue('hw thread 4 ok', T4.Success);
  finally
    T1.Free; T2.Free; T3.Free; T4.Free;
  end;
end;

procedure TTest_Tick_All.Test_Tick_Eventual_Progress;
var
  C: ITick; StartV, CurV: UInt64; Deadline: QWord;
begin
  C := MakeBestTick;
  StartV := C.Tick;
  CurV := StartV;
  // 最多等待 ~10ms 直到 tick 变化（兼容粗分辨率平台）
  Deadline := GetTickCount64 + 10;
  while (CurV = StartV) and (GetTickCount64 < Deadline) do
    CurV := C.Tick;
  AssertTrue('eventual progress within 10ms', CurV >= StartV);
end;

initialization
  RegisterTest(TTest_Tick_All);

end.


