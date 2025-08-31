program bench_optimized_comparison;

{**
 * 优化版本原子操作性能对比
 *
 * @desc 对比原版、优化版和 RTL 的性能差异
 * @author fafafa.core team
 * @version 1.0.0
 * @since 2025-08-31
 *}

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.atomic,
  optimized_atomic_test;

type
  TBenchResult = record
    Name: string;
    OpsPerSecond: Double;
    AvgTimeNs: Double;
  end;

var
  TestValue32: Int32 = 100;
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
  
  ElapsedMs := (EndTime - StartTime) * 24 * 60 * 60 * 1000;
  Result.OpsPerSecond := Iterations / (ElapsedMs / 1000);
  Result.AvgTimeNs := (ElapsedMs * 1000000) / Iterations;
end;

procedure AddResult(const AResult: TBenchResult);
begin
  SetLength(Results, Length(Results) + 1);
  Results[High(Results)] := AResult;
end;

// === Load 操作对比测试 ===

procedure Test_Original_Load;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_load(Value); // 默认 seq_cst
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Optimized_Load_Relaxed;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := optimized_atomic_load(Value); // 默认 relaxed
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Optimized_Load_Acquire;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := optimized_atomic_load(Value, memory_order_acquire);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Fast_Load;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := fast_atomic_load(Value);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Smart_Load;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := smart_atomic_load(Value);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_RTL_Load;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := InterlockedExchangeAdd(Value, 0);
  if Dummy = -999999 then WriteLn('Never');
end;

// === Store 操作对比测试 ===

procedure Test_Original_Store;
var
  Value: Int32;
begin
  Value := TestValue32;
  atomic_store(Value, 42); // 默认 seq_cst
end;

procedure Test_Optimized_Store_Relaxed;
var
  Value: Int32;
begin
  Value := TestValue32;
  optimized_atomic_store(Value, 42); // 默认 relaxed
end;

procedure Test_Optimized_Store_Release;
var
  Value: Int32;
begin
  Value := TestValue32;
  optimized_atomic_store(Value, 42, memory_order_release);
end;

procedure Test_Fast_Store;
var
  Value: Int32;
begin
  Value := TestValue32;
  fast_atomic_store(Value, 42);
end;

procedure Test_Smart_Store;
var
  Value: Int32;
begin
  Value := TestValue32;
  smart_atomic_store(Value, 42);
end;

procedure Test_RTL_Store;
var
  Value: Int32;
begin
  Value := TestValue32;
  InterlockedExchange(Value, 42);
end;

// === Exchange 操作对比测试 ===

procedure Test_Original_Exchange;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_exchange(Value, 42); // 默认 seq_cst
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Optimized_Exchange_Relaxed;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := optimized_atomic_exchange(Value, 42); // 默认 relaxed
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Fast_Exchange;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := fast_atomic_exchange(Value, 42);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Smart_Exchange;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := smart_atomic_exchange(Value, 42);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_RTL_Exchange;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := InterlockedExchange(Value, 42);
  if Dummy = -999999 then WriteLn('Never');
end;

// === FetchAdd 操作对比测试 ===

procedure Test_Original_FetchAdd;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_fetch_add(Value, 1); // 默认 seq_cst
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Optimized_FetchAdd_Relaxed;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := optimized_atomic_fetch_add(Value, 1); // 默认 relaxed
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Fast_FetchAdd;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := fast_atomic_fetch_add(Value, 1);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Smart_FetchAdd;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := smart_atomic_fetch_add(Value, 1);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_RTL_FetchAdd;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := InterlockedExchangeAdd(Value, 1);
  if Dummy = -999999 then WriteLn('Never');
end;

// 打印结果
procedure PrintResults;
var
  I: Integer;
begin
  WriteLn('=== 优化版本性能对比结果 ===');
  WriteLn(Format('%-35s %15s %15s', ['测试名称', 'ops/sec', '平均时间(ns)']));
  WriteLn(StringOfChar('-', 70));
  
  for I := 0 to High(Results) do
  begin
    WriteLn(Format('%-35s %15.0f %15.2f', [
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
    if Ratio >= 1 then
      WriteLn(Format('%s vs %s: %.2fx (%.1f%% faster)', [
        TargetName, BaselineName, Ratio, (Ratio - 1) * 100
      ]))
    else
      WriteLn(Format('%s vs %s: %.2fx (%.1f%% slower)', [
        TargetName, BaselineName, Ratio, (1 - Ratio) * 100
      ]));
  end;
end;

begin
  try
    WriteLn('=== fafafa.core.atomic 优化版本性能对比 ===');
    WriteLn;

    WriteLn('运行优化版本性能对比测试...');

    // Load 操作对比
    AddResult(RunBenchmark('original_load', @Test_Original_Load));
    AddResult(RunBenchmark('optimized_load_relaxed', @Test_Optimized_Load_Relaxed));
    AddResult(RunBenchmark('optimized_load_acquire', @Test_Optimized_Load_Acquire));
    AddResult(RunBenchmark('fast_load', @Test_Fast_Load));
    AddResult(RunBenchmark('smart_load', @Test_Smart_Load));
    AddResult(RunBenchmark('rtl_load', @Test_RTL_Load));

    // Store 操作对比
    AddResult(RunBenchmark('original_store', @Test_Original_Store));
    AddResult(RunBenchmark('optimized_store_relaxed', @Test_Optimized_Store_Relaxed));
    AddResult(RunBenchmark('optimized_store_release', @Test_Optimized_Store_Release));
    AddResult(RunBenchmark('fast_store', @Test_Fast_Store));
    AddResult(RunBenchmark('smart_store', @Test_Smart_Store));
    AddResult(RunBenchmark('rtl_store', @Test_RTL_Store));

    // Exchange 操作对比
    AddResult(RunBenchmark('original_exchange', @Test_Original_Exchange));
    AddResult(RunBenchmark('optimized_exchange_relaxed', @Test_Optimized_Exchange_Relaxed));
    AddResult(RunBenchmark('fast_exchange', @Test_Fast_Exchange));
    AddResult(RunBenchmark('smart_exchange', @Test_Smart_Exchange));
    AddResult(RunBenchmark('rtl_exchange', @Test_RTL_Exchange));

    // FetchAdd 操作对比
    AddResult(RunBenchmark('original_fetch_add', @Test_Original_FetchAdd));
    AddResult(RunBenchmark('optimized_fetch_add_relaxed', @Test_Optimized_FetchAdd_Relaxed));
    AddResult(RunBenchmark('fast_fetch_add', @Test_Fast_FetchAdd));
    AddResult(RunBenchmark('smart_fetch_add', @Test_Smart_FetchAdd));
    AddResult(RunBenchmark('rtl_fetch_add', @Test_RTL_FetchAdd));

    // 打印结果
    PrintResults;

    WriteLn('=== 优化效果分析 ===');
    WriteLn;

    WriteLn('Load 操作优化效果:');
    PrintComparison('original_load', 'optimized_load_relaxed');
    PrintComparison('original_load', 'optimized_load_acquire');
    PrintComparison('original_load', 'fast_load');
    PrintComparison('original_load', 'smart_load');
    PrintComparison('rtl_load', 'optimized_load_relaxed');
    WriteLn;

    WriteLn('Store 操作优化效果:');
    PrintComparison('original_store', 'optimized_store_relaxed');
    PrintComparison('original_store', 'optimized_store_release');
    PrintComparison('original_store', 'fast_store');
    PrintComparison('original_store', 'smart_store');
    PrintComparison('rtl_store', 'optimized_store_relaxed');
    WriteLn;

    WriteLn('Exchange 操作优化效果:');
    PrintComparison('original_exchange', 'optimized_exchange_relaxed');
    PrintComparison('original_exchange', 'fast_exchange');
    PrintComparison('original_exchange', 'smart_exchange');
    PrintComparison('rtl_exchange', 'optimized_exchange_relaxed');
    WriteLn;

    WriteLn('FetchAdd 操作优化效果:');
    PrintComparison('original_fetch_add', 'optimized_fetch_add_relaxed');
    PrintComparison('original_fetch_add', 'fast_fetch_add');
    PrintComparison('original_fetch_add', 'smart_fetch_add');
    PrintComparison('rtl_fetch_add', 'optimized_fetch_add_relaxed');
    WriteLn;

    WriteLn('优化版本性能对比完成！');
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
