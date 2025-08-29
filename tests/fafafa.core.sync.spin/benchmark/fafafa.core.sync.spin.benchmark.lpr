{$CODEPAGE UTF8}
program fafafa.core.sync.spin.benchmark;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, DateUtils,
  fafafa.core.sync.spin.base,
  fafafa.core.sync.spin;

type
  TBenchmarkResult = record
    TestName: string;
    Operations: Integer;
    ElapsedMs: QWord;
    OpsPerSecond: Double;
    AvgLatencyNs: Double;
  end;

  TBenchmarkSuite = class
  private
    FResults: array of TBenchmarkResult;
    procedure AddResult(const ATestName: string; AOperations: Integer; AElapsedMs: QWord);
    procedure PrintResults;
  public
    procedure RunAllBenchmarks;
    procedure BenchmarkBasicOperations;
    procedure BenchmarkContentionScenarios;
    procedure BenchmarkBackoffStrategies;
    procedure BenchmarkTimeoutBehavior;
  end;

procedure TBenchmarkSuite.AddResult(const ATestName: string; AOperations: Integer; AElapsedMs: QWord);
var
  idx: Integer;
begin
  idx := Length(FResults);
  SetLength(FResults, idx + 1);
  
  FResults[idx].TestName := ATestName;
  FResults[idx].Operations := AOperations;
  FResults[idx].ElapsedMs := AElapsedMs;
  
  if AElapsedMs > 0 then
  begin
    FResults[idx].OpsPerSecond := (AOperations * 1000.0) / AElapsedMs;
    FResults[idx].AvgLatencyNs := (AElapsedMs * 1000000.0) / AOperations;
  end
  else
  begin
    FResults[idx].OpsPerSecond := 0;
    FResults[idx].AvgLatencyNs := 0;
  end;
end;

procedure TBenchmarkSuite.PrintResults;
var
  i: Integer;
begin
  WriteLn('');
  WriteLn('=== fafafa.core.sync.spin 基准测试结果 ===');
  WriteLn('');
  WriteLn(Format('%-30s %10s %10s %15s %15s', 
    ['测试名称', '操作数', '耗时(ms)', '操作/秒', '平均延迟(ns)']));
  WriteLn(StringOfChar('-', 85));
  
  for i := 0 to High(FResults) do
  begin
    WriteLn(Format('%-30s %10d %10d %15.0f %15.2f',
      [FResults[i].TestName,
       FResults[i].Operations,
       FResults[i].ElapsedMs,
       FResults[i].OpsPerSecond,
       FResults[i].AvgLatencyNs]));
  end;
  
  WriteLn('');
end;

procedure TBenchmarkSuite.BenchmarkBasicOperations;
const
  OPERATIONS = 1000000;
var
  spinLock: ISpinLock;
  i: Integer;
  startTime, endTime: QWord;
begin
  WriteLn('运行基础操作基准测试...');
  
  // 测试默认配置
  spinLock := MakeSpinLock(DefaultSpinLockPolicy);
  
  startTime := GetTickCount64;
  for i := 1 to OPERATIONS do
  begin
    spinLock.Acquire;
    spinLock.Release;
  end;
  endTime := GetTickCount64;
  
  AddResult('基础 Acquire/Release', OPERATIONS, endTime - startTime);
  
  // 测试 TryAcquire
  startTime := GetTickCount64;
  for i := 1 to OPERATIONS do
  begin
    if spinLock.TryAcquire then
      spinLock.Release;
  end;
  endTime := GetTickCount64;
  
  AddResult('TryAcquire (成功)', OPERATIONS, endTime - startTime);
end;

procedure TBenchmarkSuite.BenchmarkContentionScenarios;
const
  OPERATIONS = 100000;
var
  spinLock: ISpinLock;
  policy: TSpinLockPolicy;
  i: Integer;
  startTime, endTime: QWord;
begin
  WriteLn('运行争用场景基准测试...');
  
  // 低争用场景 (少自旋)
  policy := DefaultSpinLockPolicy;
  policy.MaxSpins := 10;
  spinLock := MakeSpinLock(policy);
  
  startTime := GetTickCount64;
  for i := 1 to OPERATIONS do
  begin
    spinLock.Acquire;
    spinLock.Release;
  end;
  endTime := GetTickCount64;
  
  AddResult('低争用 (MaxSpins=10)', OPERATIONS, endTime - startTime);
  
  // 高争用场景 (多自旋)
  policy.MaxSpins := 1000;
  spinLock := MakeSpinLock(policy);
  
  startTime := GetTickCount64;
  for i := 1 to OPERATIONS do
  begin
    spinLock.Acquire;
    spinLock.Release;
  end;
  endTime := GetTickCount64;
  
  AddResult('高争用 (MaxSpins=1000)', OPERATIONS, endTime - startTime);
end;

procedure TBenchmarkSuite.BenchmarkBackoffStrategies;
const
  OPERATIONS = 100000;
var
  spinLock: ISpinLock;
  policy: TSpinLockPolicy;
  i: Integer;
  startTime, endTime: QWord;
begin
  WriteLn('运行退避策略基准测试...');
  
  // 线性退避
  policy := DefaultSpinLockPolicy;
  policy.BackoffStrategy := sbsLinear;
  policy.MaxSpins := 100;
  spinLock := MakeSpinLock(policy);
  
  startTime := GetTickCount64;
  for i := 1 to OPERATIONS do
  begin
    spinLock.Acquire;
    spinLock.Release;
  end;
  endTime := GetTickCount64;
  
  AddResult('线性退避策略', OPERATIONS, endTime - startTime);
  
  // 指数退避
  policy.BackoffStrategy := sbsExponential;
  spinLock := MakeSpinLock(policy);
  
  startTime := GetTickCount64;
  for i := 1 to OPERATIONS do
  begin
    spinLock.Acquire;
    spinLock.Release;
  end;
  endTime := GetTickCount64;
  
  AddResult('指数退避策略', OPERATIONS, endTime - startTime);
  
  // 自适应退避
  policy.BackoffStrategy := sbsAdaptive;
  spinLock := MakeSpinLock(policy);
  
  startTime := GetTickCount64;
  for i := 1 to OPERATIONS do
  begin
    spinLock.Acquire;
    spinLock.Release;
  end;
  endTime := GetTickCount64;
  
  AddResult('自适应退避策略', OPERATIONS, endTime - startTime);
end;

procedure TBenchmarkSuite.BenchmarkTimeoutBehavior;
const
  OPERATIONS = 10000;
var
  spinLock: ISpinLock;
  i: Integer;
  startTime, endTime: QWord;
  successCount: Integer;
begin
  WriteLn('运行超时行为基准测试...');
  
  spinLock := MakeSpinLock(DefaultSpinLockPolicy);
  successCount := 0;
  
  // 测试零超时
  startTime := GetTickCount64;
  for i := 1 to OPERATIONS do
  begin
    if spinLock.TryAcquire(0) then
    begin
      Inc(successCount);
      spinLock.Release;
    end;
  end;
  endTime := GetTickCount64;
  
  AddResult('TryAcquire 零超时', OPERATIONS, endTime - startTime);
  
  // 测试短超时
  successCount := 0;
  startTime := GetTickCount64;
  for i := 1 to OPERATIONS do
  begin
    if spinLock.TryAcquire(1) then
    begin
      Inc(successCount);
      spinLock.Release;
    end;
  end;
  endTime := GetTickCount64;
  
  AddResult('TryAcquire 1ms超时', OPERATIONS, endTime - startTime);
end;

procedure TBenchmarkSuite.RunAllBenchmarks;
begin
  WriteLn('开始 fafafa.core.sync.spin 基准测试套件...');
  WriteLn('');
  
  BenchmarkBasicOperations;
  BenchmarkContentionScenarios;
  BenchmarkBackoffStrategies;
  BenchmarkTimeoutBehavior;
  
  PrintResults;
end;

var
  Suite: TBenchmarkSuite;
begin
  Suite := TBenchmarkSuite.Create;
  try
    Suite.RunAllBenchmarks;
  finally
    Suite.Free;
  end;
  
  WriteLn('基准测试完成。按回车键退出...');
  ReadLn;
end.
