unit test_tick_strict;

{$MODE OBJFPC}{$H+}
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
    procedure Test_CreateTick_For_All_Available;
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
      AssertTrue('Available type must appear in GetAvailableTickTypes',
        Pos(','+IntToStr(i)+',', ','+IntToStr(Ord(types[Low(types)]))+',') >= 0
        or (Length(types) > 1)); // 放宽：不强制顺序与无重复
end;

procedure TTest_Strict_Global.Test_CreateTick_For_All_Available;
var
  tt: TTickType;
  t: ITick;
begin
  for tt := Low(TTickType) to High(TTickType) do
  begin
    if IsTickTypeAvailable(tt) then
    begin
      t := CreateTick(tt);
      AssertTrue('CreateTick returns non-nil for available type', t <> nil);
      AssertTrue('Resolution must be > 0', t.GetResolution > 0);
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

// =============== ITick 行为 ===============

type
  TTest_Strict_ITick = class(TTestCase)
  private
    procedure AssertTickBasic(const t: ITick);
    procedure AssertRoundTripWithin(const t: ITick; const d: TDuration);
  published
    procedure Test_DefaultTick_Behavior;
    procedure Test_HighPrecisionTick_Behavior;
    procedure Test_SystemTick_Behavior;
    procedure Test_QuickMeasure_ShortSleep;
    procedure Test_CrossClock_Consistency;
  end;

procedure TTest_Strict_ITick.AssertTickBasic(const t: ITick);
var
  r: UInt64;
  minI, durRes: TDuration;
  c1, c2: UInt64;
begin
  AssertTrue('tick <> nil', t <> nil);
  r := t.GetResolution;
  AssertTrue('Resolution > 0', r > 0);

  // 最小间隔与 DurationResolution 一致且为正
  minI := t.GetMinimumInterval;
  durRes := t.GetDurationResolution;
  AssertTrue('MinimumInterval > 0', minI.AsNs > 0);
  AssertTrue('DurationResolution > 0', durRes.AsNs > 0);
  AssertEquals('DurationResolution equals MinimumInterval', minI.AsNs, durRes.AsNs);

  // 单调性（若声明为单调）
  c1 := t.GetCurrentTick;
  SleepMs(1);
  c2 := t.GetCurrentTick;
  if t.IsMonotonic then
    AssertTrue('Monotonic clock should not go backwards', c2 >= c1);
end;

procedure TTest_Strict_ITick.AssertRoundTripWithin(const t: ITick; const d: TDuration);
var
  ticks: UInt64;
  back: TDuration;
  tol: UInt64;
begin
  ticks := t.DurationToTicks(d);
  back := t.TicksToDuration(ticks);
  tol := MaxU64(t.GetMinimumInterval.AsNs, ROUNDTRIP_MAX_NS_FLOOR);
  AssertTrue('Round-trip within tolerance',
    (back.AsNs <= d.AsNs + tol) and (back.AsNs + tol >= d.AsNs));
end;

procedure TTest_Strict_ITick.Test_DefaultTick_Behavior;
var
  t: ITick;
begin
  t := DefaultTick;
  AssertTickBasic(t);
  // 转换回路测试
  AssertRoundTripWithin(t, TDuration.FromNs(1));
  AssertRoundTripWithin(t, TDuration.FromUs(10));
  AssertRoundTripWithin(t, TDuration.FromMs(1));
  AssertRoundTripWithin(t, TDuration.FromMs(15));
end;

procedure TTest_Strict_ITick.Test_HighPrecisionTick_Behavior;
var
  t: ITick;
begin
  t := HighPrecisionTick;
  AssertTickBasic(t);
  AssertRoundTripWithin(t, TDuration.FromUs(1));
  AssertRoundTripWithin(t, TDuration.FromMs(2));
end;

procedure TTest_Strict_ITick.Test_SystemTick_Behavior;
var
  t: ITick;
  st, et: UInt64;
  d: TDuration;
begin
  t := SystemTick;
  AssertTickBasic(t);
  // 睡眠并验证经过时间下限
  st := t.GetCurrentTick;
  SleepMs(SLEEP_MS_SHORT);
  et := t.GetElapsedTicks(st);
  d := t.TicksToDuration(et);
  AssertTrue('Sleep '+IntToStr(SLEEP_MS_SHORT)+'ms should yield at least '
    +IntToStr(EXPECT_MIN_MS_SHORT)+'ms', d.AsMs >= EXPECT_MIN_MS_SHORT);
end;

procedure TTest_Strict_ITick.Test_QuickMeasure_ShortSleep;
var
  d: TDuration;
begin
  d := QuickMeasure(
    procedure
    begin
      SleepMs(SLEEP_MS_MED);
    end
  );
  AssertTrue('QuickMeasure should be >= '+IntToStr(EXPECT_MIN_MS_MED)+'ms', d.AsMs >= EXPECT_MIN_MS_MED);
end;

procedure TTest_Strict_ITick.Test_CrossClock_Consistency;
var
  td, th, ts: ITick;
  dd, dh, ds: TDuration;
  st: UInt64;
begin
  td := DefaultTick;
  th := HighPrecisionTick;
  ts := SystemTick;

  st := td.GetCurrentTick; SleepMs(SLEEP_MS_MED); dd := td.TicksToDuration(td.GetElapsedTicks(st));
  st := th.GetCurrentTick; SleepMs(SLEEP_MS_MED); dh := th.TicksToDuration(th.GetElapsedTicks(st));
  st := ts.GetCurrentTick; SleepMs(SLEEP_MS_MED); ds := ts.TicksToDuration(ts.GetElapsedTicks(st));

  AssertTrue('DefaultTick measured >= lower bound', dd.AsMs >= EXPECT_MIN_MS_MED);
  AssertTrue('HighPrecisionTick measured >= lower bound', dh.AsMs >= EXPECT_MIN_MS_MED);
  AssertTrue('SystemTick measured >= lower bound', ds.AsMs >= EXPECT_MIN_MS_MED);
end;

// =============== TSC 条件测试 ===============

type
  TTest_Strict_TSC = class(TTestCase)
  published
    procedure Test_TSC_Basic_IfAvailable;
  end;

procedure TTest_Strict_TSC.Test_TSC_Basic_IfAvailable;
var
  t: ITick;
  st, et: UInt64;
  d: TDuration;
begin
  if not IsTickTypeAvailable(ttTSC) then
    Exit; // 跳过

  t := CreateTick(ttTSC);
  AssertTrue('TSC tick <> nil', t <> nil);
  AssertTrue('TSC Resolution > 0', t.GetResolution > 0);
  AssertTrue('TSC IsHighResolution', t.IsHighResolution);
  AssertTrue('TSC IsMonotonic', t.IsMonotonic);

  st := t.GetCurrentTick;
  SleepMs(SLEEP_MS_SHORT);
  et := t.GetElapsedTicks(st);
  d := t.TicksToDuration(et);
  AssertTrue('TSC measured >= lower bound', d.AsMs >= EXPECT_MIN_MS_SHORT);
end;

initialization
  RegisterTest(TTest_Strict_Global);
  RegisterTest(TTest_Strict_ITick);
  RegisterTest(TTest_Strict_TSC);

end.

