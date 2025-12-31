program bench_atomic_basic;

{**
 * fafafa.core.atomic 基础原子操作基准测试
 *
 * @desc 对比 fafafa.core.atomic 与 RTL 原子操作的基础性能
 * @author fafafa.core team
 * @version 1.0.0
 * @since 2025-08-31
 *}

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.atomic;

type
  TBenchResult = record
    Name: string;
    OpsPerSecond: Double;
    AvgTimeNs: Double;
  end;

var
  // 测试数据
  TestValue32: Int32 = 100;
  TestValue64: Int64 = 1000;
  TestPtr: Pointer = nil;

  // 基准测试结果
  Results: array of TBenchResult;

// 简易基准测试函数
function RunBenchmark(const TestName: string; TestProc: TProcedure; Iterations: Integer = 1000000): TBenchResult;
var
  StartTime, EndTime: TDateTime;
  I: Integer;
  ElapsedMs: Double;
begin
  Result.Name := TestName;

  // 预热
  for I := 1 to 1000 do
    TestProc();

  // 正式测试
  StartTime := Now;
  for I := 1 to Iterations do
    TestProc();
  EndTime := Now;

  ElapsedMs := (EndTime - StartTime) * 24 * 60 * 60 * 1000; // 转换为毫秒
  Result.OpsPerSecond := Iterations / (ElapsedMs / 1000);
  Result.AvgTimeNs := (ElapsedMs * 1000000) / Iterations; // 转换为纳秒
end;

// === 32位原子操作基准测试 ===

procedure Test_FafafaAtomic_Load32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_load(Value);
  // 防止编译器优化
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_RTL_Load32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := InterlockedExchangeAdd(Value, 0);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_NonAtomic_Load32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := Value;
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_FafafaAtomic_Store32;
var
  Value: Int32;
begin
  Value := TestValue32;
  atomic_store(Value, 42);
end;

procedure Test_RTL_Store32;
var
  Value: Int32;
begin
  Value := TestValue32;
  InterlockedExchange(Value, 42);
end;

procedure Test_NonAtomic_Store32;
var
  Value: Int32;
begin
  Value := TestValue32;
  Value := 42;
end;

procedure Test_FafafaAtomic_Exchange32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_exchange(Value, 42);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_RTL_Exchange32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := InterlockedExchange(Value, 42);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_FafafaAtomic_FetchAdd32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_fetch_add(Value, 1);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_RTL_FetchAdd32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := InterlockedExchangeAdd(Value, 1);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_FafafaAtomic_Increment32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_increment(Value);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_RTL_Increment32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := InterlockedIncrement(Value);
  if Dummy = -999999 then WriteLn('Never');
end;

// 添加结果到数组
procedure AddResult(const AResult: TBenchResult);
begin
  SetLength(Results, Length(Results) + 1);
  Results[High(Results)] := AResult;
end;

// 打印结果
procedure PrintResults;
var
  I: Integer;
begin
  WriteLn('=== 基准测试结果 ===');
  WriteLn(Format('%-30s %15s %15s', ['测试名称', 'ops/sec', '平均时间(ns)']));
  WriteLn(StringOfChar('-', 65));

  for I := 0 to High(Results) do
  begin
    WriteLn(Format('%-30s %15.0f %15.2f', [
      Results[I].Name,
      Results[I].OpsPerSecond,
      Results[I].AvgTimeNs
    ]));
  end;
  WriteLn;
end;

// 性能对比
procedure PrintComparison(const BaselineName, TargetName: string);
var
  BaselineOps, TargetOps: Double;
  Ratio: Double;
  I: Integer;
begin
  BaselineOps := 0;
  TargetOps := 0;

  for I := 0 to High(Results) do
  begin
    if Results[I].Name = BaselineName then
      BaselineOps := Results[I].OpsPerSecond
    else if Results[I].Name = TargetName then
      TargetOps := Results[I].OpsPerSecond;
  end;

  if (BaselineOps > 0) and (TargetOps > 0) then
  begin
    Ratio := TargetOps / BaselineOps;
    WriteLn(Format('%s vs %s: %.2fx', [TargetName, BaselineName, Ratio]));
  end;
end;

begin
  try
    WriteLn('=== fafafa.core.atomic 基础原子操作基准测试 ===');
    WriteLn;

    // 初始化测试数据
    TestPtr := @TestValue32;

    WriteLn('运行基准测试...');

    // 32位原子操作测试
    AddResult(RunBenchmark('fafafa_atomic_load32', @Test_FafafaAtomic_Load32));
    AddResult(RunBenchmark('rtl_load32', @Test_RTL_Load32));
    AddResult(RunBenchmark('nonatomic_load32', @Test_NonAtomic_Load32));

    AddResult(RunBenchmark('fafafa_atomic_store32', @Test_FafafaAtomic_Store32));
    AddResult(RunBenchmark('rtl_store32', @Test_RTL_Store32));
    AddResult(RunBenchmark('nonatomic_store32', @Test_NonAtomic_Store32));

    AddResult(RunBenchmark('fafafa_atomic_exchange32', @Test_FafafaAtomic_Exchange32));
    AddResult(RunBenchmark('rtl_exchange32', @Test_RTL_Exchange32));

    AddResult(RunBenchmark('fafafa_atomic_fetch_add32', @Test_FafafaAtomic_FetchAdd32));
    AddResult(RunBenchmark('rtl_fetch_add32', @Test_RTL_FetchAdd32));

    AddResult(RunBenchmark('fafafa_atomic_increment32', @Test_FafafaAtomic_Increment32));
    AddResult(RunBenchmark('rtl_increment32', @Test_RTL_Increment32));

    // 打印结果
    PrintResults;

    WriteLn('=== 性能对比分析 ===');
    WriteLn('32位原子操作性能对比:');
    PrintComparison('nonatomic_load32', 'fafafa_atomic_load32');
    PrintComparison('nonatomic_load32', 'rtl_load32');
    PrintComparison('rtl_load32', 'fafafa_atomic_load32');
    WriteLn;

    PrintComparison('nonatomic_store32', 'fafafa_atomic_store32');
    PrintComparison('nonatomic_store32', 'rtl_store32');
    PrintComparison('rtl_store32', 'fafafa_atomic_store32');
    WriteLn;

    PrintComparison('rtl_exchange32', 'fafafa_atomic_exchange32');
    PrintComparison('rtl_fetch_add32', 'fafafa_atomic_fetch_add32');
    PrintComparison('rtl_increment32', 'fafafa_atomic_increment32');
    WriteLn;

    WriteLn('基准测试完成！');
    WriteLn('按回车键退出...');
    ReadLn;

  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
var
  Value: Int32;
  Result: Int32;
begin
  Value := TestValue32;
  while aState.KeepRunning do
  begin
    Result := Value; // 直接读取，非原子操作
    aState.Blackhole(Result);
  end;
end;

procedure BM_FafafaAtomic_Store32(aState: IBenchmarkState);
var
  Value: Int32;
begin
  Value := TestValue32;
  while aState.KeepRunning do
  begin
    atomic_store(Value, 42);
  end;
end;

procedure BM_RTL_Store32(aState: IBenchmarkState);
var
  Value: Int32;
begin
  Value := TestValue32;
  while aState.KeepRunning do
  begin
    // RTL 没有专门的 store，使用 InterlockedExchange 模拟
    InterlockedExchange(Value, 42);
  end;
end;

procedure BM_NonAtomic_Store32(aState: IBenchmarkState);
var
  Value: Int32;
begin
  Value := TestValue32;
  while aState.KeepRunning do
  begin
    Value := 42; // 直接赋值，非原子操作
  end;
end;

procedure BM_FafafaAtomic_Exchange32(aState: IBenchmarkState);
var
  Value: Int32;
  Result: Int32;
begin
  Value := TestValue32;
  while aState.KeepRunning do
  begin
    Result := atomic_exchange(Value, 42);
    aState.Blackhole(Result);
  end;
end;

procedure BM_RTL_Exchange32(aState: IBenchmarkState);
var
  Value: Int32;
  Result: Int32;
begin
  Value := TestValue32;
  while aState.KeepRunning do
  begin
    Result := InterlockedExchange(Value, 42);
    aState.Blackhole(Result);
  end;
end;

procedure BM_FafafaAtomic_CompareExchange32(aState: IBenchmarkState);
var
  Value: Int32;
  Expected: Int32;
  Result: Boolean;
begin
  Value := TestValue32;
  while aState.KeepRunning do
  begin
    Expected := 42;
    Result := atomic_compare_exchange_strong(Value, Expected, 100);
    aState.Blackhole(Int64(Result));
  end;
end;

procedure BM_RTL_CompareExchange32(aState: IBenchmarkState);
var
  Value: Int32;
  Result: Int32;
begin
  Value := TestValue32;
  while aState.KeepRunning do
  begin
    Result := InterlockedCompareExchange(Value, 100, 42);
    aState.Blackhole(Result);
  end;
end;

procedure BM_FafafaAtomic_FetchAdd32(aState: IBenchmarkState);
var
  Value: Int32;
  Result: Int32;
begin
  Value := TestValue32;
  while aState.KeepRunning do
  begin
    Result := atomic_fetch_add(Value, 1);
    aState.Blackhole(Result);
  end;
end;

procedure BM_RTL_FetchAdd32(aState: IBenchmarkState);
var
  Value: Int32;
  Result: Int32;
begin
  Value := TestValue32;
  while aState.KeepRunning do
  begin
    Result := InterlockedExchangeAdd(Value, 1);
    aState.Blackhole(Result);
  end;
end;

procedure BM_FafafaAtomic_Increment32(aState: IBenchmarkState);
var
  Value: Int32;
  Result: Int32;
begin
  Value := TestValue32;
  while aState.KeepRunning do
  begin
    Result := atomic_increment(Value);
    aState.Blackhole(Result);
  end;
end;

procedure BM_RTL_Increment32(aState: IBenchmarkState);
var
  Value: Int32;
  Result: Int32;
begin
  Value := TestValue32;
  while aState.KeepRunning do
  begin
    Result := InterlockedIncrement(Value);
    aState.Blackhole(Result);
  end;
end;

// === 64位原子操作基准测试 ===

procedure BM_FafafaAtomic_Load64(aState: IBenchmarkState);
var
  Value: Int64;
  Result: Int64;
begin
  Value := TestValue64;
  while aState.KeepRunning do
  begin
    Result := atomic_load_64(Value);
    aState.Blackhole(Result);
  end;
end;

procedure BM_RTL_Load64(aState: IBenchmarkState);
var
  Value: Int64;
  Result: Int64;
begin
  Value := TestValue64;
  while aState.KeepRunning do
  begin
    Result := InterlockedExchangeAdd64(Value, 0);
    aState.Blackhole(Result);
  end;
end;

procedure BM_FafafaAtomic_Exchange64(aState: IBenchmarkState);
var
  Value: Int64;
  Result: Int64;
begin
  Value := TestValue64;
  while aState.KeepRunning do
  begin
    Result := atomic_exchange_64(Value, 42);
    aState.Blackhole(Result);
  end;
end;

procedure BM_RTL_Exchange64(aState: IBenchmarkState);
var
  Value: Int64;
  Result: Int64;
begin
  Value := TestValue64;
  while aState.KeepRunning do
  begin
    Result := InterlockedExchange64(Value, 42);
    aState.Blackhole(Result);
  end;
end;

procedure BM_FafafaAtomic_FetchAdd64(aState: IBenchmarkState);
var
  Value: Int64;
  Result: Int64;
begin
  Value := TestValue64;
  while aState.KeepRunning do
  begin
    Result := atomic_fetch_add_64(Value, 1);
    aState.Blackhole(Result);
  end;
end;

procedure BM_RTL_FetchAdd64(aState: IBenchmarkState);
var
  Value: Int64;
  Result: Int64;
begin
  Value := TestValue64;
  while aState.KeepRunning do
  begin
    Result := InterlockedExchangeAdd64(Value, 1);
    aState.Blackhole(Result);
  end;
end;

// === 指针原子操作基准测试 ===

procedure BM_FafafaAtomic_LoadPtr(aState: IBenchmarkState);
var
  Value: Pointer;
  Result: Pointer;
begin
  Value := TestPtr;
  while aState.KeepRunning do
  begin
    Result := atomic_load(Value);
    aState.Blackhole(PtrUInt(Result));
  end;
end;

procedure BM_RTL_LoadPtr(aState: IBenchmarkState);
var
  Value: Pointer;
  Result: Pointer;
begin
  Value := TestPtr;
  while aState.KeepRunning do
  begin
    Result := RTL_InterlockedExchangePointer(Value, Value);
    aState.Blackhole(PtrUInt(Result));
  end;
end;

procedure BM_FafafaAtomic_ExchangePtr(aState: IBenchmarkState);
var
  Value: Pointer;
  Result: Pointer;
begin
  Value := TestPtr;
  while aState.KeepRunning do
  begin
    Result := atomic_exchange(Value, @TestValue32);
    aState.Blackhole(PtrUInt(Result));
  end;
end;

procedure BM_RTL_ExchangePtr(aState: IBenchmarkState);
var
  Value: Pointer;
  Result: Pointer;
begin
  Value := TestPtr;
  while aState.KeepRunning do
  begin
    Result := RTL_InterlockedExchangePointer(Value, @TestValue32);
    aState.Blackhole(PtrUInt(Result));
  end;
end;

// === 主程序 ===

procedure RunBasicAtomicBenchmarks;
var
  Suite: IBenchmarkSuite;
  Results: TBenchmarkResultArray;
  I: Integer;
  Config: TBenchmarkConfig;
begin
  WriteLn('=== fafafa.core.atomic 基础原子操作基准测试 ===');
  WriteLn;

  // 创建基准测试套件
  Suite := CreateBenchmarkSuite;
  Config := CreateDefaultBenchmarkConfig;
  Config.MeasureIterations := 1000000; // 100万次迭代
  Config.WarmupIterations := 10000;    // 1万次预热

  // 32位原子操作测试
  WriteLn('注册 32位原子操作基准测试...');
  Suite.AddFunction('fafafa_atomic_load32', @BM_FafafaAtomic_Load32, Config);
  Suite.AddFunction('rtl_load32', @BM_RTL_Load32, Config);
  Suite.AddFunction('nonatomic_load32', @BM_NonAtomic_Load32, Config);

  Suite.AddFunction('fafafa_atomic_store32', @BM_FafafaAtomic_Store32, Config);
  Suite.AddFunction('rtl_store32', @BM_RTL_Store32, Config);
  Suite.AddFunction('nonatomic_store32', @BM_NonAtomic_Store32, Config);

  Suite.AddFunction('fafafa_atomic_exchange32', @BM_FafafaAtomic_Exchange32, Config);
  Suite.AddFunction('rtl_exchange32', @BM_RTL_Exchange32, Config);

  Suite.AddFunction('fafafa_atomic_cas32', @BM_FafafaAtomic_CompareExchange32, Config);
  Suite.AddFunction('rtl_cas32', @BM_RTL_CompareExchange32, Config);

  Suite.AddFunction('fafafa_atomic_fetch_add32', @BM_FafafaAtomic_FetchAdd32, Config);
  Suite.AddFunction('rtl_fetch_add32', @BM_RTL_FetchAdd32, Config);

  Suite.AddFunction('fafafa_atomic_increment32', @BM_FafafaAtomic_Increment32, Config);
  Suite.AddFunction('rtl_increment32', @BM_RTL_Increment32, Config);

  // 64位原子操作测试
  WriteLn('注册 64位原子操作基准测试...');
  Suite.AddFunction('fafafa_atomic_load64', @BM_FafafaAtomic_Load64, Config);
  Suite.AddFunction('rtl_load64', @BM_RTL_Load64, Config);

  Suite.AddFunction('fafafa_atomic_exchange64', @BM_FafafaAtomic_Exchange64, Config);
  Suite.AddFunction('rtl_exchange64', @BM_RTL_Exchange64, Config);

  Suite.AddFunction('fafafa_atomic_fetch_add64', @BM_FafafaAtomic_FetchAdd64, Config);
  Suite.AddFunction('rtl_fetch_add64', @BM_RTL_FetchAdd64, Config);

  // 指针原子操作测试
  WriteLn('注册指针原子操作基准测试...');
  Suite.AddFunction('fafafa_atomic_load_ptr', @BM_FafafaAtomic_LoadPtr, Config);
  Suite.AddFunction('rtl_load_ptr', @BM_RTL_LoadPtr, Config);

  Suite.AddFunction('fafafa_atomic_exchange_ptr', @BM_FafafaAtomic_ExchangePtr, Config);
  Suite.AddFunction('rtl_exchange_ptr', @BM_RTL_ExchangePtr, Config);

  WriteLn('开始运行基准测试...');
  WriteLn;

  // 运行所有基准测试
  Results := Suite.RunAll;

  WriteLn;
  WriteLn('=== 基准测试结果 ===');

  // 创建比较器并添加结果
  Comparator := CreateBenchComparator;
  try
    for I := 0 to High(Results) do
    begin
      var BenchResult: TAtomicBenchResult;
      BenchResult.TestName := Results[I].GetName;
      BenchResult.OpsPerSecond := Results[I].GetThroughput;
      BenchResult.AvgTimeNs := Results[I].GetTimePerIteration(buNanoSeconds);
      BenchResult.TotalIterations := Results[I].GetIterations;
      BenchResult.ThreadCount := 1;

      if Results[I].HasStatistics then
      begin
        var Stats := Results[I].GetStatistics;
        BenchResult.MinTimeNs := Stats.MinTime;
        BenchResult.MaxTimeNs := Stats.MaxTime;
        BenchResult.StdDevNs := Stats.StdDev;
      end;

      Comparator.AddResult(BenchResult);
    end;

    // 打印所有结果
    Comparator.PrintAllResults;

    WriteLn('=== 性能对比分析 ===');

    // 32位操作对比
    WriteLn('32位原子操作性能对比:');
    Comparator.PrintComparison('nonatomic_load32', 'fafafa_atomic_load32');
    Comparator.PrintComparison('nonatomic_load32', 'rtl_load32');
    Comparator.PrintComparison('rtl_load32', 'fafafa_atomic_load32');
    WriteLn;

    Comparator.PrintComparison('nonatomic_store32', 'fafafa_atomic_store32');
    Comparator.PrintComparison('nonatomic_store32', 'rtl_store32');
    Comparator.PrintComparison('rtl_store32', 'fafafa_atomic_store32');
    WriteLn;

    Comparator.PrintComparison('rtl_exchange32', 'fafafa_atomic_exchange32');
    Comparator.PrintComparison('rtl_cas32', 'fafafa_atomic_cas32');
    Comparator.PrintComparison('rtl_fetch_add32', 'fafafa_atomic_fetch_add32');
    Comparator.PrintComparison('rtl_increment32', 'fafafa_atomic_increment32');
    WriteLn;

    // 64位操作对比
    WriteLn('64位原子操作性能对比:');
    Comparator.PrintComparison('rtl_load64', 'fafafa_atomic_load64');
    Comparator.PrintComparison('rtl_exchange64', 'fafafa_atomic_exchange64');
    Comparator.PrintComparison('rtl_fetch_add64', 'fafafa_atomic_fetch_add64');
    WriteLn;

    // 指针操作对比
    WriteLn('指针原子操作性能对比:');
    Comparator.PrintComparison('rtl_load_ptr', 'fafafa_atomic_load_ptr');
    Comparator.PrintComparison('rtl_exchange_ptr', 'fafafa_atomic_exchange_ptr');
    WriteLn;

    // 保存结果到文件
    ForceDirectories('results');
    Comparator.SaveToJSON('results/basic_atomic_results.json');
    Comparator.SaveToCSV('results/basic_atomic_results.csv');
    WriteLn('结果已保存到 results/ 目录');

  finally
    Comparator.Free;
  end;
end;

begin
  try
    // 初始化测试数据
    TestPtr := @TestValue32;

    // 运行基准测试
    RunBasicAtomicBenchmarks;

    WriteLn;
    WriteLn('基准测试完成。按回车键退出...');
    ReadLn;

  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
