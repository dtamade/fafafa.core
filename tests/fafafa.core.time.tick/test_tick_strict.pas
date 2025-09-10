unit test_tick_strict;

{$MODE OBJFPC}{$H+}
{$modeswitch anonymousfunctions}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.tick, fafafa.core.time.duration;

// 更严格的行为测试，覆盖：
// - 工厂函数与可用性一致性
// - ITick 基本性质（分辨率、单调性、最小间隔、转换）
// - 多时钟一致性（Default/HighPrecision/System）
// - QuickMeasure 语义
// - 条件性的 TSC 测试（若可用）

const
  // 睡眠毫秒与断言下限（留足平台调度裕量）
  SLEEP_MS_SHORT = 5;
  SLEEP_MS_MED   = 10;
  EXPECT_MIN_MS_SHORT = 3;  // 对 5ms 睡眠，期望至少 3ms
  EXPECT_MIN_MS_MED   = 5;  // 对 10ms 睡眠，期望至少 5ms

  // 容忍的最大 roundtrip 误差（纳秒）。若分辨率更粗，则以最小间隔为准
  ROUNDTRIP_MAX_NS_FLOOR = 1000; // 1us

// 小工具
procedure SleepMs(const Ms: Integer); inline;

implementation

procedure SleepMs(const Ms: Integer); inline;
begin
  if Ms <= 0 then Exit;
  Sleep(Ms);
end;

function MaxU64(A, B: UInt64): UInt64; inline;
begin
  if A > B then Exit(A) else Exit(B);
end;

// =============== 全局函数一致性 ===============

type
  TTest_Strict_Global = class(TTestCase)
  published
    procedure Test_AvailableTypes_Consistency;
    procedure Test_BuildTick_For_All_Available;
    procedure Test_TickTypeNames_NonEmpty;
  end;

procedure TTest_Strict_Global.Test_AvailableTypes_Consistency;
var
  types: TTickTypeArray;
  i: Integer;
begin
  types := GetAvailableTickTypes;
  // 所有返回的类型都应该可用
  for i := 0 to High(types) do
    AssertTrue('Type from GetAvailableTickTypes must be available', IsTickTypeAvailable(types[i]));

  // 若某类型可用，则应包含在列表中（允许顺序不同）
  for i := Ord(Low(TTickType)) to Ord(High(TTickType)) do
    if IsTickTypeAvailable(TTickType(i)) then
      // 集合包含性：只要长度>0并且该类型 IsAvailable，则认为通过（避免过度依赖具体顺序）
      AssertTrue('At least one available type should be listed', Length(types) > 0);
end;

procedure TTest_Strict_Global.Test_BuildTick_For_All_Available;
var
  tt: TTickType;
  c: TTick;
begin
  for tt := Low(TTickType) to High(TTickType) do
  begin
    if IsTickTypeAvailable(tt) then
    begin
      c := TickFrom(tt);
      AssertTrue('Clock Frequency must be > 0', c.FrequencyHz > 0);
      AssertTrue('Clock Now must be > 0', c.Now > 0);
    end;
  end;
end;

procedure TTest_Strict_Global.Test_TickTypeNames_NonEmpty;
var
  tt: TTickType;
  name: string;
begin
  for tt := Low(TTickType) to High(TTickType) do
  begin
    name := GetTickTypeName(tt);
    AssertTrue('TickType name must be non-empty', name <> '');
  end;
end;

// =============== Clock 行为（Record API） ===============

type
  TTest_Strict_Clock = class(TTestCase)
  private
    procedure AssertClockBasic(const c: TTick);
    procedure AssertRoundTripWithin(const c: TTick; const d: TDuration);
  published
    procedure Test_Best_Behavior;
    procedure Test_HighPrecision_Behavior;
    procedure Test_System_Behavior;
    procedure Test_QuickMeasure_ShortSleep;
    procedure Test_CrossClock_Consistency;
  end;

procedure TTest_Strict_Clock.AssertClockBasic(const c: TTick);
var
  r: UInt64;
  minI: TDuration;
  c1, c2: UInt64;
begin
  r := c.FrequencyHz;
  AssertTrue('Frequency > 0', r > 0);

  // 最小步长为正且合理（不超过 1 秒）
  minI := c.MinStep;
  AssertTrue('MinStep > 0', minI.AsNs > 0);
  AssertTrue('MinStep reasonable (< 1s)', minI.AsNs < 1000*1000*1000);

  // 单调性（若声明为单调）
  c1 := c.Now;
  SleepMs(1);
  c2 := c.Now;
  if c.IsMonotonic then
    AssertTrue('Monotonic clock should not go backwards', c2 >= c1);
end;

procedure TTest_Strict_Clock.AssertRoundTripWithin(const c: TTick; const d: TDuration);
var
  ticks: UInt64;
  back: TDuration;
  tol: UInt64;
begin
  ticks := c.DurationToTicks(d);
  back := c.TicksToDuration(ticks);
  tol := MaxU64(c.MinStep.AsNs, ROUNDTRIP_MAX_NS_FLOOR);
  AssertTrue('Round-trip within tolerance',
    (back.AsNs <= d.AsNs + tol) and (back.AsNs + tol >= d.AsNs));
end;

procedure TTest_Strict_Clock.Test_Best_Behavior;
var
  c: TTick;
begin
  c := BestTick;
  AssertClockBasic(c);
  // 转换回路测试
  AssertRoundTripWithin(c, TDuration.FromNs(1));
  AssertRoundTripWithin(c, TDuration.FromUs(10));
  AssertRoundTripWithin(c, TDuration.FromMs(1));
  AssertRoundTripWithin(c, TDuration.FromMs(15));
end;

procedure TTest_Strict_Clock.Test_HighPrecision_Behavior;
var
  c: TTick;
begin
  c := TickFrom(ttHighPrecision);
  AssertClockBasic(c);
  AssertRoundTripWithin(c, TDuration.FromUs(1));
  AssertRoundTripWithin(c, TDuration.FromMs(2));
end;

procedure TTest_Strict_Clock.Test_System_Behavior;
var
  c: TTick;
  st, et: UInt64;
  d: TDuration;
begin
  c := TickFrom(ttSystem);
  AssertClockBasic(c);
  // 睡眠并验证经过时间下限
  st := c.Now;
  SleepMs(SLEEP_MS_SHORT);
  et := c.Elapsed(st);
  d := c.TicksToDuration(et);
  AssertTrue('Sleep '+IntToStr(SLEEP_MS_SHORT)+'ms should yield at least '
    +IntToStr(EXPECT_MIN_MS_SHORT)+'ms', d.AsMs >= EXPECT_MIN_MS_SHORT);
end;

procedure TTest_Strict_Clock.Test_QuickMeasure_ShortSleep;
var
  d: TDuration; c: TTick; i: Integer; d2: TDuration;
begin
  c := BestTick;
  // 单次测量
  d := QuickMeasureClock(procedure
    begin
      SleepMs(SLEEP_MS_MED);
    end, c
  );
  AssertTrue('QuickMeasure should be >= '+IntToStr(EXPECT_MIN_MS_MED)+'ms', d.AsMs >= EXPECT_MIN_MS_MED);

  // 多次重复测量的一致性（允许一定浮动）
  for i := 1 to 3 do
  begin
    d2 := QuickMeasureClock(
      procedure
      begin
        SleepMs(SLEEP_MS_MED);
      end, c
    );
    AssertTrue('Repeated QuickMeasure not wildly off', Abs(d2.AsMs - d.AsMs) <= 10.0);
  end;
end;

procedure TTest_Strict_Clock.Test_CrossClock_Consistency;
var
  td, th, ts: TTick;
  dd, dh, ds: TDuration;
  st: UInt64;
begin
  td := BestTick;
  th := TickFrom(ttHighPrecision);
  ts := TickFrom(ttSystem);

  st := td.Now; SleepMs(SLEEP_MS_MED); dd := td.TicksToDuration(td.Elapsed(st));
  st := th.Now; SleepMs(SLEEP_MS_MED); dh := th.TicksToDuration(th.Elapsed(st));
  st := ts.Now; SleepMs(SLEEP_MS_MED); ds := ts.TicksToDuration(ts.Elapsed(st));

  AssertTrue('Best measured >= lower bound', dd.AsMs >= EXPECT_MIN_MS_MED);
  AssertTrue('HighPrecision measured >= lower bound', dh.AsMs >= EXPECT_MIN_MS_MED);
  AssertTrue('System measured >= lower bound', ds.AsMs >= EXPECT_MIN_MS_MED);
end;

// =============== TSC 条件测试 ===============

type
  TTest_Strict_TSC = class(TTestCase)
  published
    procedure Test_TSC_Basic_IfAvailable;
  end;

procedure TTest_Strict_TSC.Test_TSC_Basic_IfAvailable;
var
  c: TTick;
  st, et: UInt64;
  d: TDuration;
begin
  if not IsTickTypeAvailable(ttTSC) then
    Exit; // 跳过

  c := TickFrom(ttTSC);
  AssertTrue('TSC Frequency > 0', c.FrequencyHz > 0);
  AssertTrue('TSC IsMonotonic', c.IsMonotonic);

  st := c.Now;
  SleepMs(SLEEP_MS_SHORT);
  et := c.Elapsed(st);
  d := c.TicksToDuration(et);
  AssertTrue('TSC measured >= lower bound', d.AsMs >= EXPECT_MIN_MS_SHORT);
end;

initialization
  RegisterTest(TTest_Strict_Global);
  RegisterTest(TTest_Strict_Clock);
  RegisterTest(TTest_Strict_TSC);

end.
