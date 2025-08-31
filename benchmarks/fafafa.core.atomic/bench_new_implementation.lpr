program bench_new_implementation;

{**
 * 新实现的 fafafa.core.atomic 基准测试
 *
 * @desc 测试重载设计策略的性能效果
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
  TestValue64: Int64 = 1000;
  TestPtr: Pointer = nil;
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

// === 32位原子操作测试 ===

// Fast versions (no memory_order)
procedure Test_Fast_Load32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_load(Value); // 无 memory_order 参数
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Fast_Store32;
var
  Value: Int32;
begin
  Value := TestValue32;
  atomic_store(Value, 42); // 无 memory_order 参数
end;

procedure Test_Fast_Exchange32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_exchange(Value, 42); // 无 memory_order 参数
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Fast_FetchAdd32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_fetch_add(Value, 1); // 无 memory_order 参数
  if Dummy = -999999 then WriteLn('Never');
end;

// Standard versions with memory_order_relaxed
procedure Test_Relaxed_Load32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_load(Value, memory_order_relaxed);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Relaxed_Store32;
var
  Value: Int32;
begin
  Value := TestValue32;
  atomic_store(Value, 42, memory_order_relaxed);
end;

procedure Test_Relaxed_Exchange32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_exchange(Value, 42, memory_order_relaxed);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_Relaxed_FetchAdd32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_fetch_add(Value, 1, memory_order_relaxed);
  if Dummy = -999999 then WriteLn('Never');
end;

// Standard versions with memory_order_seq_cst
procedure Test_SeqCst_Load32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_load(Value, memory_order_seq_cst);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_SeqCst_Store32;
var
  Value: Int32;
begin
  Value := TestValue32;
  atomic_store(Value, 42, memory_order_seq_cst);
end;

procedure Test_SeqCst_Exchange32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_exchange(Value, 42, memory_order_seq_cst);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_SeqCst_FetchAdd32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_fetch_add(Value, 1, memory_order_seq_cst);
  if Dummy = -999999 then WriteLn('Never');
end;

// RTL 直接调用对比
procedure Test_RTL_Load32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := InterlockedExchangeAdd(Value, 0);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_RTL_Store32;
var
  Value: Int32;
begin
  Value := TestValue32;
  InterlockedExchange(Value, 42);
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

procedure Test_RTL_FetchAdd32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := InterlockedExchangeAdd(Value, 1);
  if Dummy = -999999 then WriteLn('Never');
end;

// 非原子操作基线
procedure Test_NonAtomic_Load32;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := Value;
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_NonAtomic_Store32;
var
  Value: Int32;
begin
  Value := TestValue32;
  Value := 42;
end;

// 打印结果
procedure PrintResults;
var
  I: Integer;
begin
  WriteLn('=== 新实现基准测试结果 ===');
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
    WriteLn('=== fafafa.core.atomic 新实现基准测试 ===');
    WriteLn;

    // 初始化测试数据
    TestPtr := @TestValue32;

    WriteLn('运行新实现基准测试...');

    // 32位原子操作测试
    WriteLn('测试 32位原子操作...');

    // Fast versions (无 memory_order 参数)
    AddResult(RunBenchmark('fast_load32', @Test_Fast_Load32));
    AddResult(RunBenchmark('fast_store32', @Test_Fast_Store32));
    AddResult(RunBenchmark('fast_exchange32', @Test_Fast_Exchange32));
    AddResult(RunBenchmark('fast_fetch_add32', @Test_Fast_FetchAdd32));

    // Relaxed versions
    AddResult(RunBenchmark('relaxed_load32', @Test_Relaxed_Load32));
    AddResult(RunBenchmark('relaxed_store32', @Test_Relaxed_Store32));
    AddResult(RunBenchmark('relaxed_exchange32', @Test_Relaxed_Exchange32));
    AddResult(RunBenchmark('relaxed_fetch_add32', @Test_Relaxed_FetchAdd32));

    // Seq_cst versions
    AddResult(RunBenchmark('seq_cst_load32', @Test_SeqCst_Load32));
    AddResult(RunBenchmark('seq_cst_store32', @Test_SeqCst_Store32));
    AddResult(RunBenchmark('seq_cst_exchange32', @Test_SeqCst_Exchange32));
    AddResult(RunBenchmark('seq_cst_fetch_add32', @Test_SeqCst_FetchAdd32));

    // RTL 直接调用
    AddResult(RunBenchmark('rtl_load32', @Test_RTL_Load32));
    AddResult(RunBenchmark('rtl_store32', @Test_RTL_Store32));
    AddResult(RunBenchmark('rtl_exchange32', @Test_RTL_Exchange32));
    AddResult(RunBenchmark('rtl_fetch_add32', @Test_RTL_FetchAdd32));

    // 非原子操作基线
    AddResult(RunBenchmark('nonatomic_load32', @Test_NonAtomic_Load32));
    AddResult(RunBenchmark('nonatomic_store32', @Test_NonAtomic_Store32));

    // 打印结果
    PrintResults;

    WriteLn('=== 性能对比分析 ===');
    WriteLn;

    WriteLn('Load 操作性能对比:');
    PrintComparison('nonatomic_load32', 'fast_load32');
    PrintComparison('nonatomic_load32', 'relaxed_load32');
    PrintComparison('nonatomic_load32', 'seq_cst_load32');
    PrintComparison('rtl_load32', 'fast_load32');
    PrintComparison('fast_load32', 'relaxed_load32');
    PrintComparison('relaxed_load32', 'seq_cst_load32');
    WriteLn;

    WriteLn('Store 操作性能对比:');
    PrintComparison('nonatomic_store32', 'fast_store32');
    PrintComparison('nonatomic_store32', 'relaxed_store32');
    PrintComparison('nonatomic_store32', 'seq_cst_store32');
    PrintComparison('rtl_store32', 'fast_store32');
    PrintComparison('fast_store32', 'relaxed_store32');
    PrintComparison('relaxed_store32', 'seq_cst_store32');
    WriteLn;

    WriteLn('Exchange 操作性能对比:');
    PrintComparison('rtl_exchange32', 'fast_exchange32');
    PrintComparison('fast_exchange32', 'relaxed_exchange32');
    PrintComparison('relaxed_exchange32', 'seq_cst_exchange32');
    WriteLn;

    WriteLn('FetchAdd 操作性能对比:');
    PrintComparison('rtl_fetch_add32', 'fast_fetch_add32');
    PrintComparison('fast_fetch_add32', 'relaxed_fetch_add32');
    PrintComparison('relaxed_fetch_add32', 'seq_cst_fetch_add32');
    WriteLn;

    WriteLn('重载设计效果总结:');
    WriteLn('- Fast版本 (无memory_order): 直接调用RTL，最佳性能');
    WriteLn('- Relaxed版本: 与Fast版本性能相当，无额外屏障开销');
    WriteLn('- Seq_cst版本: 有内存屏障开销，但符合C++11标准');
    WriteLn;

    WriteLn('新实现基准测试完成！');
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
