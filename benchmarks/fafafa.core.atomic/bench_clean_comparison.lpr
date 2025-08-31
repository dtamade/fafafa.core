program bench_clean_comparison;

{**
 * fafafa.core.atomic vs RTL 清晰对比测试
 *
 * @desc 按照统一命名规范对比 atomic vs rtl 性能
 * @author fafafa.core team
 * @version 1.0.0
 * @since 2025-08-31
 *}

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$INLINE ON}

{$i ../../src/fafafa.core.atomic.fast.inc}

uses
  SysUtils,
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

// === LOAD 操作对比 ===

procedure Test_atomic_load;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_load(Value); // 无 memory_order，最快版本
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_rtl_load;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := InterlockedExchangeAdd(Value, 0); // RTL 实现
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_atomic_load_relaxed;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_load(Value, memory_order_relaxed);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_atomic_load_acquire;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_load(Value, memory_order_acquire);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_atomic_load_seq_cst;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_load(Value, memory_order_seq_cst);
  if Dummy = -999999 then WriteLn('Never');
end;

// === STORE 操作对比 ===

procedure Test_atomic_store;
var
  Value: Int32;
begin
  Value := TestValue32;
  atomic_store(Value, 42); // 无 memory_order，最快版本
end;

procedure Test_rtl_store;
var
  Value: Int32;
begin
  Value := TestValue32;
  InterlockedExchange(Value, 42); // RTL 实现
end;

procedure Test_atomic_store_relaxed;
var
  Value: Int32;
begin
  Value := TestValue32;
  atomic_store(Value, 42, memory_order_relaxed);
end;

procedure Test_atomic_store_release;
var
  Value: Int32;
begin
  Value := TestValue32;
  atomic_store(Value, 42, memory_order_release);
end;

procedure Test_atomic_store_seq_cst;
var
  Value: Int32;
begin
  Value := TestValue32;
  atomic_store(Value, 42, memory_order_seq_cst);
end;

// === EXCHANGE 操作对比 ===

procedure Test_atomic_exchange;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_exchange(Value, 42); // 无 memory_order，最快版本
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_rtl_exchange;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := InterlockedExchange(Value, 42); // RTL 实现
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_atomic_exchange_relaxed;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_exchange(Value, 42, memory_order_relaxed);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_atomic_exchange_acq_rel;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_exchange(Value, 42, memory_order_acq_rel);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_atomic_exchange_seq_cst;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_exchange(Value, 42, memory_order_seq_cst);
  if Dummy = -999999 then WriteLn('Never');
end;

// === FETCH_ADD 操作对比 ===

procedure Test_atomic_fetch_add;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_fetch_add(Value, 1); // 无 memory_order，最快版本
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_rtl_fetch_add;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := InterlockedExchangeAdd(Value, 1); // RTL 实现
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_atomic_fetch_add_relaxed;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_fetch_add(Value, 1, memory_order_relaxed);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_atomic_fetch_add_acq_rel;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_fetch_add(Value, 1, memory_order_acq_rel);
  if Dummy = -999999 then WriteLn('Never');
end;

procedure Test_atomic_fetch_add_seq_cst;
var
  Value: Int32;
  Dummy: Int32;
begin
  Value := TestValue32;
  Dummy := atomic_fetch_add(Value, 1, memory_order_seq_cst);
  if Dummy = -999999 then WriteLn('Never');
end;

// 打印结果
procedure PrintResults;
var
  I: Integer;
begin
  WriteLn('=== fafafa.core.atomic vs RTL 性能对比 ===');
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
    WriteLn('=== fafafa.core.atomic vs RTL 清晰对比测试 ===');
    WriteLn;

    WriteLn('运行基准测试...');

    // === LOAD 操作对比 ===
    WriteLn('测试 LOAD 操作...');
    AddResult(RunBenchmark('atomic_load', @Test_atomic_load));
    AddResult(RunBenchmark('rtl_load', @Test_rtl_load));
    AddResult(RunBenchmark('atomic_load_relaxed', @Test_atomic_load_relaxed));
    AddResult(RunBenchmark('atomic_load_acquire', @Test_atomic_load_acquire));
    AddResult(RunBenchmark('atomic_load_seq_cst', @Test_atomic_load_seq_cst));

    // === STORE 操作对比 ===
    WriteLn('测试 STORE 操作...');
    AddResult(RunBenchmark('atomic_store', @Test_atomic_store));
    AddResult(RunBenchmark('rtl_store', @Test_rtl_store));
    AddResult(RunBenchmark('atomic_store_relaxed', @Test_atomic_store_relaxed));
    AddResult(RunBenchmark('atomic_store_release', @Test_atomic_store_release));
    AddResult(RunBenchmark('atomic_store_seq_cst', @Test_atomic_store_seq_cst));

    // === EXCHANGE 操作对比 ===
    WriteLn('测试 EXCHANGE 操作...');
    AddResult(RunBenchmark('atomic_exchange', @Test_atomic_exchange));
    AddResult(RunBenchmark('rtl_exchange', @Test_rtl_exchange));
    AddResult(RunBenchmark('atomic_exchange_relaxed', @Test_atomic_exchange_relaxed));
    AddResult(RunBenchmark('atomic_exchange_acq_rel', @Test_atomic_exchange_acq_rel));
    AddResult(RunBenchmark('atomic_exchange_seq_cst', @Test_atomic_exchange_seq_cst));

    // === FETCH_ADD 操作对比 ===
    WriteLn('测试 FETCH_ADD 操作...');
    AddResult(RunBenchmark('atomic_fetch_add', @Test_atomic_fetch_add));
    AddResult(RunBenchmark('rtl_fetch_add', @Test_rtl_fetch_add));
    AddResult(RunBenchmark('atomic_fetch_add_relaxed', @Test_atomic_fetch_add_relaxed));
    AddResult(RunBenchmark('atomic_fetch_add_acq_rel', @Test_atomic_fetch_add_acq_rel));
    AddResult(RunBenchmark('atomic_fetch_add_seq_cst', @Test_atomic_fetch_add_seq_cst));

    // 打印结果
    PrintResults;

    WriteLn('=== 详细性能对比分析 ===');
    WriteLn;

    WriteLn('LOAD 操作对比:');
    PrintComparison('rtl_load', 'atomic_load');
    PrintComparison('atomic_load', 'atomic_load_relaxed');
    PrintComparison('atomic_load_relaxed', 'atomic_load_acquire');
    PrintComparison('atomic_load_acquire', 'atomic_load_seq_cst');
    WriteLn;

    WriteLn('STORE 操作对比:');
    PrintComparison('rtl_store', 'atomic_store');
    PrintComparison('atomic_store', 'atomic_store_relaxed');
    PrintComparison('atomic_store_relaxed', 'atomic_store_release');
    PrintComparison('atomic_store_release', 'atomic_store_seq_cst');
    WriteLn;

    WriteLn('EXCHANGE 操作对比:');
    PrintComparison('rtl_exchange', 'atomic_exchange');
    PrintComparison('atomic_exchange', 'atomic_exchange_relaxed');
    PrintComparison('atomic_exchange_relaxed', 'atomic_exchange_acq_rel');
    PrintComparison('atomic_exchange_acq_rel', 'atomic_exchange_seq_cst');
    WriteLn;

    WriteLn('FETCH_ADD 操作对比:');
    PrintComparison('rtl_fetch_add', 'atomic_fetch_add');
    PrintComparison('atomic_fetch_add', 'atomic_fetch_add_relaxed');
    PrintComparison('atomic_fetch_add_relaxed', 'atomic_fetch_add_acq_rel');
    PrintComparison('atomic_fetch_add_acq_rel', 'atomic_fetch_add_seq_cst');
    WriteLn;

    WriteLn('=== 内存序开销分析 ===');
    WriteLn('relaxed → acquire → seq_cst 的性能递减符合 C++ 标准预期');
    WriteLn('atomic 无参数版本应该与 RTL 性能相当或更好');
    WriteLn;

    WriteLn('清晰对比测试完成！');
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
