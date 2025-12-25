{$mode objfpc}{$H+}{$J-}
{$modeswitch anonymousfunctions}
{$I ..\..\src\fafafa.core.settings.inc}

unit Test_fafafa_core_time_perf_regression;

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.clock,
  fafafa.core.time.stopwatch;

type
  {
    性能回归测试套件

    验证关键操作的性能不退化：
    1. NowInstant() 调用 < 500ns（宽松目标，实际应 < 150ns）
    2. Duration 算术操作 < 50ns
    3. Instant 比较操作 < 50ns

    注意：这些测试使用宽松的阈值以避免在不同环境下的误报
  }
  TTestPerfRegression = class(TTestCase)
  private
    FClock: IMonotonicClock;
    FIterations: Integer;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 时钟性能测试
    procedure Test_NowInstant_Performance;
    procedure Test_NowUnixNs_Performance;

    // Duration 性能测试
    procedure Test_Duration_Add_Performance;
    procedure Test_Duration_Compare_Performance;
    procedure Test_Duration_FromMs_Performance;

    // Instant 性能测试
    procedure Test_Instant_Add_Performance;
    procedure Test_Instant_Compare_Performance;
    procedure Test_Instant_Elapsed_Performance;

    // 综合性能测试
    procedure Test_Stopwatch_Overhead;

    // SleepFor 精度测试
    procedure Test_SleepFor_Precision_1ms;
    procedure Test_SleepFor_Precision_100us;

    // TimeIt 基准测试
    procedure Test_TimeIt_Function_Overhead;
    procedure Test_TimeIt_Accuracy;

    // WaitFor 精度测试
    procedure Test_WaitFor_Precision_1ms;
    procedure Test_WaitFor_CancelOverhead;
  end;

implementation

{ TTestPerfRegression }

procedure TTestPerfRegression.SetUp;
begin
  FClock := CreateMonotonicClock;
  FIterations := 100000; // 10万次迭代取平均
end;

procedure TTestPerfRegression.TearDown;
begin
  FClock := nil;
end;

// === 时钟性能测试 ===

procedure TTestPerfRegression.Test_NowInstant_Performance;
var
  startTime, endTime: TInstant;
  i: Integer;
  totalNs, avgNs: Int64;
  dummy: TInstant;
begin
  // 预热
  for i := 1 to 1000 do
    dummy := FClock.NowInstant;

  // 计时
  startTime := FClock.NowInstant;
  for i := 1 to FIterations do
    dummy := FClock.NowInstant;
  endTime := FClock.NowInstant;

  totalNs := endTime.Diff(startTime).AsNs;
  avgNs := totalNs div FIterations;

  // 宽松目标：< 2000ns（不同环境差异很大，重要的是不退化）
  AssertTrue(Format('NowInstant 平均耗时 %d ns 应 < 2000ns', [avgNs]), avgNs < 2000);

  // 避免编译器优化掉 dummy
  if dummy.AsNsSinceEpoch = 0 then
    Fail('不应该发生');
end;

procedure TTestPerfRegression.Test_NowUnixNs_Performance;
var
  sysClock: ISystemClock;
  startTime, endTime: TInstant;
  i: Integer;
  totalNs, avgNs: Int64;
  dummy: Int64;
begin
  sysClock := DefaultSystemClock;

  // 预热
  for i := 1 to 1000 do
    dummy := sysClock.NowUnixNs;

  // 计时
  startTime := FClock.NowInstant;
  for i := 1 to FIterations do
    dummy := sysClock.NowUnixNs;
  endTime := FClock.NowInstant;

  totalNs := endTime.Diff(startTime).AsNs;
  avgNs := totalNs div FIterations;

  // 系统时钟可能稍慢，目标 < 3000ns（环境差异）
  AssertTrue(Format('NowUnixNs 平均耗时 %d ns 应 < 3000ns', [avgNs]), avgNs < 3000);

  if dummy = 0 then
    Fail('不应该发生');
end;

// === Duration 性能测试 ===

procedure TTestPerfRegression.Test_Duration_Add_Performance;
var
  startTime, endTime: TInstant;
  i: Integer;
  totalNs, avgNs: Int64;
  a, b, dummy: TDuration;
begin
  a := TDuration.FromMs(100);
  b := TDuration.FromMs(200);

  // 预热
  for i := 1 to 1000 do
    dummy := a + b;

  // 计时
  startTime := FClock.NowInstant;
  for i := 1 to FIterations do
    dummy := a + b;
  endTime := FClock.NowInstant;

  totalNs := endTime.Diff(startTime).AsNs;
  avgNs := totalNs div FIterations;

  // 目标 < 50ns
  AssertTrue(Format('Duration.Add 平均耗时 %d ns 应 < 50ns', [avgNs]), avgNs < 50);

  if dummy.AsNs = 0 then
    Fail('不应该发生');
end;

procedure TTestPerfRegression.Test_Duration_Compare_Performance;
var
  startTime, endTime: TInstant;
  i: Integer;
  totalNs, avgNs: Int64;
  a, b: TDuration;
  dummy: Boolean;
begin
  a := TDuration.FromMs(100);
  b := TDuration.FromMs(200);

  // 预热
  for i := 1 to 1000 do
    dummy := a < b;

  // 计时
  startTime := FClock.NowInstant;
  for i := 1 to FIterations do
    dummy := a < b;
  endTime := FClock.NowInstant;

  totalNs := endTime.Diff(startTime).AsNs;
  avgNs := totalNs div FIterations;

  // 目标 < 20ns
  AssertTrue(Format('Duration.Compare 平均耗时 %d ns 应 < 20ns', [avgNs]), avgNs < 20);

  if not dummy then
    ; // 避免警告
end;

procedure TTestPerfRegression.Test_Duration_FromMs_Performance;
var
  startTime, endTime: TInstant;
  i: Integer;
  totalNs, avgNs: Int64;
  dummy: TDuration;
begin
  // 预热
  for i := 1 to 1000 do
    dummy := TDuration.FromMs(i);

  // 计时
  startTime := FClock.NowInstant;
  for i := 1 to FIterations do
    dummy := TDuration.FromMs(i);
  endTime := FClock.NowInstant;

  totalNs := endTime.Diff(startTime).AsNs;
  avgNs := totalNs div FIterations;

  // 目标 < 30ns
  AssertTrue(Format('Duration.FromMs 平均耗时 %d ns 应 < 30ns', [avgNs]), avgNs < 30);

  if dummy.AsNs = 0 then
    Fail('不应该发生');
end;

// === Instant 性能测试 ===

procedure TTestPerfRegression.Test_Instant_Add_Performance;
var
  startTime, endTime: TInstant;
  i: Integer;
  totalNs, avgNs: Int64;
  inst: TInstant;
  dur: TDuration;
  dummy: TInstant;
begin
  inst := FClock.NowInstant;
  dur := TDuration.FromMs(100);

  // 预热
  for i := 1 to 1000 do
    dummy := inst.Add(dur);

  // 计时
  startTime := FClock.NowInstant;
  for i := 1 to FIterations do
    dummy := inst.Add(dur);
  endTime := FClock.NowInstant;

  totalNs := endTime.Diff(startTime).AsNs;
  avgNs := totalNs div FIterations;

  // 目标 < 50ns
  AssertTrue(Format('Instant.Add 平均耗时 %d ns 应 < 50ns', [avgNs]), avgNs < 50);

  if dummy.AsNsSinceEpoch = 0 then
    Fail('不应该发生');
end;

procedure TTestPerfRegression.Test_Instant_Compare_Performance;
var
  startTime, endTime: TInstant;
  i: Integer;
  totalNs, avgNs: Int64;
  a, b: TInstant;
  dummy: Boolean;
begin
  a := FClock.NowInstant;
  b := a.Add(TDuration.FromMs(100));

  // 预热
  for i := 1 to 1000 do
    dummy := a < b;

  // 计时
  startTime := FClock.NowInstant;
  for i := 1 to FIterations do
    dummy := a < b;
  endTime := FClock.NowInstant;

  totalNs := endTime.Diff(startTime).AsNs;
  avgNs := totalNs div FIterations;

  // 目标 < 20ns
  AssertTrue(Format('Instant.Compare 平均耗时 %d ns 应 < 20ns', [avgNs]), avgNs < 20);

  if not dummy then
    ; // 避免警告
end;

procedure TTestPerfRegression.Test_Instant_Elapsed_Performance;
var
  startTime, endTime: TInstant;
  i: Integer;
  totalNs, avgNs: Int64;
  baseTime: TInstant;
  dummy: TDuration;
begin
  baseTime := FClock.NowInstant;

  // 预热
  for i := 1 to 1000 do
    dummy := FClock.NowInstant.Diff(baseTime);

  // 计时
  startTime := FClock.NowInstant;
  for i := 1 to FIterations do
    dummy := FClock.NowInstant.Diff(baseTime);
  endTime := FClock.NowInstant;

  totalNs := endTime.Diff(startTime).AsNs;
  avgNs := totalNs div FIterations;

  // 包含 NowInstant 调用，目标 < 3000ns（环境差异）
  AssertTrue(Format('Instant.Elapsed 平均耗时 %d ns 应 < 3000ns', [avgNs]), avgNs < 3000);

  if dummy.AsNs = 0 then
    Fail('不应该发生');
end;

// === 综合性能测试 ===

procedure TTestPerfRegression.Test_Stopwatch_Overhead;
var
  sw: TStopwatch;
  i: Integer;
  totalNs, avgNs: Int64;
  startTime, endTime: TInstant;
begin
  // 测试 Stopwatch 的开销
  sw := TStopwatch.Create;

  // 预热
  for i := 1 to 1000 do
  begin
    sw.Reset;
    sw.Start;
    sw.Stop;
  end;

  // 计时
  startTime := FClock.NowInstant;
  for i := 1 to FIterations do
  begin
    sw.Reset;
    sw.Start;
    sw.Stop;
  end;
  endTime := FClock.NowInstant;

  totalNs := endTime.Diff(startTime).AsNs;
  avgNs := totalNs div FIterations;

  // Stopwatch 开销应该较小，目标 < 1500ns（包含 3 次操作）
  AssertTrue(Format('Stopwatch 周期平均耗时 %d ns 应 < 1500ns', [avgNs]), avgNs < 1500);
end;

// === SleepFor 精度测试 ===

procedure TTestPerfRegression.Test_SleepFor_Precision_1ms;
var
  startTime, endTime: TInstant;
  i, successCount: Integer;
  actualNs, requestedNs: Int64;
  errorPercent: Double;
  dur: TDuration;
const
  TestCount = 20;
  RequestedMs = 1;
begin
  // 测试 SleepFor(1ms) 的精度
  requestedNs := RequestedMs * 1000000;
  successCount := 0;

  for i := 1 to TestCount do
  begin
    dur := TDuration.FromMs(RequestedMs);
    startTime := FClock.NowInstant;
    FClock.SleepFor(dur);
    endTime := FClock.NowInstant;

    actualNs := endTime.Diff(startTime).AsNs;
    errorPercent := Abs(actualNs - requestedNs) / requestedNs * 100;

    // 允许 100% 误差（1ms 请求可能睡 0.5ms-2ms）
    if errorPercent < 100 then
      Inc(successCount);
  end;

  // 至少 80% 的测试应该在误差范围内
  AssertTrue(Format('SleepFor(1ms) 精度: %d/%d 次在误差范围内', [successCount, TestCount]),
    successCount >= TestCount * 80 div 100);
end;

procedure TTestPerfRegression.Test_SleepFor_Precision_100us;
var
  startTime, endTime: TInstant;
  i, successCount: Integer;
  actualNs, requestedNs: Int64;
  dur: TDuration;
const
  TestCount = 20;
  RequestedUs = 100;
begin
  // 测试 SleepFor(100us) 的精度（短睡眠更依赖系统调度器）
  requestedNs := RequestedUs * 1000;
  successCount := 0;

  for i := 1 to TestCount do
  begin
    dur := TDuration.FromUs(RequestedUs);
    startTime := FClock.NowInstant;
    FClock.SleepFor(dur);
    endTime := FClock.NowInstant;

    actualNs := endTime.Diff(startTime).AsNs;

    // 短睡眠允许较大误差：至少睡了一半时间，且不超过 10 倍
    if (actualNs >= requestedNs div 2) and (actualNs < requestedNs * 10) then
      Inc(successCount);
  end;

  // 至少 70% 的测试应该在误差范围内（短睡眠精度较低）
  AssertTrue(Format('SleepFor(100us) 精度: %d/%d 次在误差范围内', [successCount, TestCount]),
    successCount >= TestCount * 70 div 100);
end;

// === TimeIt 基准测试 ===

procedure TTestPerfRegression.Test_TimeIt_Function_Overhead;
var
  startTime, endTime: TInstant;
  i: Integer;
  totalNs, avgNs: Int64;
  dummy: TDuration;
begin
  // 测试 TimeIt 函数本身的开销
  // 使用空过程测量

  // 预热
  for i := 1 to 100 do
    dummy := TimeIt(procedure begin end);

  // 计时
  startTime := FClock.NowInstant;
  for i := 1 to 1000 do
    dummy := TimeIt(procedure begin end);
  endTime := FClock.NowInstant;

  totalNs := endTime.Diff(startTime).AsNs;
  avgNs := totalNs div 1000;

  // TimeIt 开销应该 < 10000ns（包含两次 NowInstant + 过程调用）
  AssertTrue(Format('TimeIt 开销 %d ns 应 < 10000ns', [avgNs]), avgNs < 10000);

  if dummy.AsNs < 0 then
    Fail('不应该发生');
end;

procedure TTestPerfRegression.Test_TimeIt_Accuracy;
var
  measured: TDuration;
  actualNs, expectedNs: Int64;
  errorPercent: Double;
const
  WorkMs = 5;
begin
  // 测试 TimeIt 测量精度
  expectedNs := WorkMs * 1000000;

  measured := TimeIt(procedure
  begin
    SleepFor(TDuration.FromMs(WorkMs));
  end);

  actualNs := measured.AsNs;
  errorPercent := Abs(actualNs - expectedNs) / expectedNs * 100;

  // 允许 100% 误差（5ms 工作可能测量为 2.5ms-10ms）
  AssertTrue(Format('TimeIt 精度: 测量 %d ns, 期望 %d ns, 误差 %.1f%%',
    [actualNs, expectedNs, errorPercent]), errorPercent < 100);
end;

// === WaitFor 精度测试 ===

procedure TTestPerfRegression.Test_WaitFor_Precision_1ms;
var
  startTime, endTime: TInstant;
  i, successCount: Integer;
  actualNs, requestedNs: Int64;
  dur: TDuration;
  ok: Boolean;
const
  TestCount = 20;
  RequestedMs = 1;
begin
  // 测试 WaitFor(1ms, nil) 的精度（无取消令牌）
  requestedNs := RequestedMs * 1000000;
  successCount := 0;

  for i := 1 to TestCount do
  begin
    dur := TDuration.FromMs(RequestedMs);
    startTime := FClock.NowInstant;
    ok := FClock.WaitFor(dur, nil);
    endTime := FClock.NowInstant;

    AssertTrue('WaitFor 应返回 True（未取消）', ok);

    actualNs := endTime.Diff(startTime).AsNs;

    // 允许 100% 误差
    if (actualNs >= requestedNs div 2) and (actualNs < requestedNs * 3) then
      Inc(successCount);
  end;

  // 至少 80% 的测试应该在误差范围内
  AssertTrue(Format('WaitFor(1ms) 精度: %d/%d 次在误差范围内', [successCount, TestCount]),
    successCount >= TestCount * 80 div 100);
end;

procedure TTestPerfRegression.Test_WaitFor_CancelOverhead;
var
  startTime, endTime: TInstant;
  i: Integer;
  totalNs, avgNs: Int64;
  dur: TDuration;
  ok: Boolean;
const
  TestIterations = 100;
begin
  // 测试 WaitFor 的极短等待开销（用于测量取消检查开销）
  dur := TDuration.FromNs(1); // 1ns 等待，几乎立即返回

  // 预热
  for i := 1 to 20 do
    ok := FClock.WaitFor(dur, nil);

  // 计时
  startTime := FClock.NowInstant;
  for i := 1 to TestIterations do
    ok := FClock.WaitFor(dur, nil);
  endTime := FClock.NowInstant;

  totalNs := endTime.Diff(startTime).AsNs;
  avgNs := totalNs div TestIterations;

  // WaitFor(1ns) 开销应该 < 50000ns（50us）
  AssertTrue(Format('WaitFor(1ns) 开销 %d ns 应 < 50000ns', [avgNs]), avgNs < 50000);

  if not ok then
    ; // 避免警告
end;

initialization
  RegisterTest(TTestPerfRegression);

end.
