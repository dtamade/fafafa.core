program bench_memory_order_analysis;

{**
 * fafafa.core.atomic 内存序性能分析
 *
 * @desc 分析不同内存序对性能的影响，找出性能瓶颈
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

// === 不同内存序的 Load 操作测试 ===

procedure Test_Load_Relaxed;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_load(Value, memory_order_relaxed);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Load_Acquire;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_load(Value, memory_order_acquire);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Load_SeqCst;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_load(Value, memory_order_seq_cst);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Load_Default;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_load(Value); // 使用默认内存序
  if Dummy = -999999 then WriteLn('Never');
end;

// === 不同内存序的 Store 操作测试 ===

procedure Test_Store_Relaxed;
var
  Value: Int32;
begin
  Value := TestValue32;
  atomic_store(Value, 42, memory_order_relaxed);
end;

procedure Test_Store_Release;
var
  Value: Int32;
begin
  Value := TestValue32;
  atomic_store(Value, 42, memory_order_release);
end;

procedure Test_Store_SeqCst;
var
  Value: Int32;
begin
  Value := TestValue32;
  atomic_store(Value, 42, memory_order_seq_cst);
end;

procedure Test_Store_Default;
var
  Value: Int32;
begin
  Value := TestValue32;
  atomic_store(Value, 42); // 使用默认内存序
end;

// === 不同内存序的 Exchange 操作测试 ===

procedure Test_Exchange_Relaxed;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_exchange(Value, 42, memory_order_relaxed);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Exchange_AcqRel;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_exchange(Value, 42, memory_order_acq_rel);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Exchange_SeqCst;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_exchange(Value, 42, memory_order_seq_cst);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Exchange_Default;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_exchange(Value, 42); // 使用默认内存序
  if Dummy = -999999 then WriteLn('Never');
end;

// === 不同内存序的 FetchAdd 操作测试 ===

procedure Test_FetchAdd_Relaxed;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_fetch_add(Value, 1, memory_order_relaxed);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_FetchAdd_AcqRel;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_fetch_add(Value, 1, memory_order_acq_rel);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_FetchAdd_SeqCst;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_fetch_add(Value, 1, memory_order_seq_cst);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_FetchAdd_Default;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_fetch_add(Value, 1); // 使用默认内存序
  if Dummy = -999999 then WriteLn('Never');
end;

// === RTL 直接调用对比 ===

procedure Test_RTL_Load;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := InterlockedExchangeAdd(Value, 0);
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
  WriteLn('=== 内存序性能分析结果 ===');
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
    WriteLn('=== fafafa.core.atomic 内存序性能分析 ===');
    WriteLn;
    
    WriteLn('运行内存序性能分析...');
    
    // Load 操作不同内存序测试
    AddResult(RunBenchmark('load_relaxed', @Test_Load_Relaxed));
    AddResult(RunBenchmark('load_acquire', @Test_Load_Acquire));
    AddResult(RunBenchmark('load_seq_cst', @Test_Load_SeqCst));
    AddResult(RunBenchmark('load_default', @Test_Load_Default));
    AddResult(RunBenchmark('rtl_load', @Test_RTL_Load));
    
    // Store 操作不同内存序测试
    AddResult(RunBenchmark('store_relaxed', @Test_Store_Relaxed));
    AddResult(RunBenchmark('store_release', @Test_Store_Release));
    AddResult(RunBenchmark('store_seq_cst', @Test_Store_SeqCst));
    AddResult(RunBenchmark('store_default', @Test_Store_Default));
    
    // Exchange 操作不同内存序测试
    AddResult(RunBenchmark('exchange_relaxed', @Test_Exchange_Relaxed));
    AddResult(RunBenchmark('exchange_acq_rel', @Test_Exchange_AcqRel));
    AddResult(RunBenchmark('exchange_seq_cst', @Test_Exchange_SeqCst));
    AddResult(RunBenchmark('exchange_default', @Test_Exchange_Default));
    AddResult(RunBenchmark('rtl_exchange', @Test_RTL_Exchange));
    
    // FetchAdd 操作不同内存序测试
    AddResult(RunBenchmark('fetch_add_relaxed', @Test_FetchAdd_Relaxed));
    AddResult(RunBenchmark('fetch_add_acq_rel', @Test_FetchAdd_AcqRel));
    AddResult(RunBenchmark('fetch_add_seq_cst', @Test_FetchAdd_SeqCst));
    AddResult(RunBenchmark('fetch_add_default', @Test_FetchAdd_Default));
    AddResult(RunBenchmark('rtl_fetch_add', @Test_RTL_FetchAdd));
    
    // 打印结果
    PrintResults;
    
    WriteLn('=== 内存序性能影响分析 ===');
    WriteLn;
    
    WriteLn('Load 操作内存序影响:');
    PrintComparison('load_relaxed', 'load_acquire');
    PrintComparison('load_relaxed', 'load_seq_cst');
    PrintComparison('load_relaxed', 'load_default');
    PrintComparison('rtl_load', 'load_relaxed');
    WriteLn;
    
    WriteLn('Store 操作内存序影响:');
    PrintComparison('store_relaxed', 'store_release');
    PrintComparison('store_relaxed', 'store_seq_cst');
    PrintComparison('store_relaxed', 'store_default');
    WriteLn;
    
    WriteLn('Exchange 操作内存序影响:');
    PrintComparison('exchange_relaxed', 'exchange_acq_rel');
    PrintComparison('exchange_relaxed', 'exchange_seq_cst');
    PrintComparison('exchange_relaxed', 'exchange_default');
    PrintComparison('rtl_exchange', 'exchange_relaxed');
    WriteLn;
    
    WriteLn('FetchAdd 操作内存序影响:');
    PrintComparison('fetch_add_relaxed', 'fetch_add_acq_rel');
    PrintComparison('fetch_add_relaxed', 'fetch_add_seq_cst');
    PrintComparison('fetch_add_relaxed', 'fetch_add_default');
    PrintComparison('rtl_fetch_add', 'fetch_add_relaxed');
    WriteLn;
    
    WriteLn('内存序性能分析完成！');
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
