{$CODEPAGE UTF8}
program fafafa.core.sync.spin.stress;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, DateUtils,
  fafafa.core.sync.spin.base,
  fafafa.core.sync.spin;

type
  TStressTestResult = record
    TestName: string;
    ThreadCount: Integer;
    OperationsPerThread: Integer;
    TotalOperations: Integer;
    ElapsedMs: QWord;
    OpsPerSecond: Double;
    ErrorCount: Integer;
    Success: Boolean;
  end;

  TWorkerThread = class(TThread)
  private
    FSpinLock: ISpinLock;
    FOperations: Integer;
    FSharedCounter: PInteger;
    FErrorCount: Integer;
    FTestType: Integer; // 0=Acquire/Release, 1=TryAcquire, 2=Mixed
  public
    constructor Create(ASpinLock: ISpinLock; AOperations: Integer; 
                      ASharedCounter: PInteger; ATestType: Integer);
    procedure Execute; override;
    property ErrorCount: Integer read FErrorCount;
  end;

  TStressTestSuite = class
  private
    FResults: array of TStressTestResult;
    procedure AddResult(const AResult: TStressTestResult);
    procedure PrintResults;
    function RunMultiThreadTest(const ATestName: string; AThreadCount, AOperationsPerThread: Integer;
                               ATestType: Integer; APolicy: TSpinLockPolicy): TStressTestResult;
  public
    procedure RunAllStressTests;
    procedure StressTestBasicConcurrency;
    procedure StressTestHighContention;
    procedure StressTestMixedOperations;
    procedure StressTestLongRunning;
  end;

constructor TWorkerThread.Create(ASpinLock: ISpinLock; AOperations: Integer; 
                                ASharedCounter: PInteger; ATestType: Integer);
begin
  inherited Create(False);
  FSpinLock := ASpinLock;
  FOperations := AOperations;
  FSharedCounter := ASharedCounter;
  FTestType := ATestType;
  FErrorCount := 0;
end;

procedure TWorkerThread.Execute;
var
  i: Integer;
  localValue: Integer;
begin
  try
    case FTestType of
      0: // Acquire/Release 测试
      begin
        for i := 1 to FOperations do
        begin
          try
            FSpinLock.Acquire;
            try
              localValue := FSharedCounter^;
              Inc(localValue);
              FSharedCounter^ := localValue;
            finally
              FSpinLock.Release;
            end;
          except
            Inc(FErrorCount);
          end;
        end;
      end;
      
      1: // TryAcquire 测试
      begin
        for i := 1 to FOperations do
        begin
          try
            if FSpinLock.TryAcquire(10) then
            begin
              try
                localValue := FSharedCounter^;
                Inc(localValue);
                FSharedCounter^ := localValue;
              finally
                FSpinLock.Release;
              end;
            end
            else
              Inc(FErrorCount); // 记录获取失败
          except
            Inc(FErrorCount);
          end;
        end;
      end;
      
      2: // 混合操作测试
      begin
        for i := 1 to FOperations do
        begin
          try
            if (i mod 3) = 0 then
            begin
              // 使用 TryAcquire
              if FSpinLock.TryAcquire(5) then
              begin
                try
                  localValue := FSharedCounter^;
                  Inc(localValue);
                  FSharedCounter^ := localValue;
                finally
                  FSpinLock.Release;
                end;
              end;
            end
            else
            begin
              // 使用 Acquire
              FSpinLock.Acquire;
              try
                localValue := FSharedCounter^;
                Inc(localValue);
                FSharedCounter^ := localValue;
              finally
                FSpinLock.Release;
              end;
            end;
          except
            Inc(FErrorCount);
          end;
        end;
      end;
    end;
  except
    Inc(FErrorCount);
  end;
end;

procedure TStressTestSuite.AddResult(const AResult: TStressTestResult);
var
  idx: Integer;
begin
  idx := Length(FResults);
  SetLength(FResults, idx + 1);
  FResults[idx] := AResult;
end;

procedure TStressTestSuite.PrintResults;
var
  i: Integer;
  totalOps: Int64;
  avgOpsPerSec: Double;
begin
  WriteLn('');
  WriteLn('=== fafafa.core.sync.spin 并发压力测试结果 ===');
  WriteLn('');
  WriteLn(Format('%-25s %8s %10s %12s %10s %15s %8s %6s', 
    ['测试名称', '线程数', '总操作数', '耗时(ms)', '错误数', '操作/秒', '成功', '状态']));
  WriteLn(StringOfChar('-', 95));
  
  totalOps := 0;
  avgOpsPerSec := 0;
  
  for i := 0 to High(FResults) do
  begin
    with FResults[i] do
    begin
      WriteLn(Format('%-25s %8d %10d %12d %10d %15.0f %8s %6s',
        [TestName, ThreadCount, TotalOperations, ElapsedMs, ErrorCount, 
         OpsPerSecond, BoolToStr(Success, '是', '否'),
         IfThen(Success, '✓', '✗')]));
      
      Inc(totalOps, TotalOperations);
      avgOpsPerSec := avgOpsPerSec + OpsPerSecond;
    end;
  end;
  
  WriteLn(StringOfChar('-', 95));
  WriteLn(Format('总计: %d 个测试, %d 总操作数, 平均 %.0f 操作/秒', 
    [Length(FResults), totalOps, avgOpsPerSec / Length(FResults)]));
  WriteLn('');
end;

function TStressTestSuite.RunMultiThreadTest(const ATestName: string; 
  AThreadCount, AOperationsPerThread: Integer; ATestType: Integer; 
  APolicy: TSpinLockPolicy): TStressTestResult;
var
  spinLock: ISpinLock;
  threads: array of TWorkerThread;
  sharedCounter: Integer;
  i: Integer;
  startTime, endTime: QWord;
  totalErrors: Integer;
begin
  Result.TestName := ATestName;
  Result.ThreadCount := AThreadCount;
  Result.OperationsPerThread := AOperationsPerThread;
  Result.TotalOperations := AThreadCount * AOperationsPerThread;
  
  spinLock := MakeSpinLock(APolicy);
  sharedCounter := 0;
  
  SetLength(threads, AThreadCount);
  
  WriteLn(Format('运行 %s (线程数: %d, 每线程操作: %d)...', 
    [ATestName, AThreadCount, AOperationsPerThread]));
  
  startTime := GetTickCount64;
  
  // 创建并启动线程
  for i := 0 to AThreadCount - 1 do
  begin
    threads[i] := TWorkerThread.Create(spinLock, AOperationsPerThread, 
                                      @sharedCounter, ATestType);
  end;
  
  // 等待所有线程完成
  totalErrors := 0;
  for i := 0 to AThreadCount - 1 do
  begin
    threads[i].WaitFor;
    Inc(totalErrors, threads[i].ErrorCount);
    threads[i].Free;
  end;
  
  endTime := GetTickCount64;
  
  Result.ElapsedMs := endTime - startTime;
  Result.ErrorCount := totalErrors;
  
  if Result.ElapsedMs > 0 then
    Result.OpsPerSecond := (Result.TotalOperations * 1000.0) / Result.ElapsedMs
  else
    Result.OpsPerSecond := 0;
  
  // 验证结果正确性（对于某些测试类型）
  if ATestType = 0 then // Acquire/Release 测试应该保证计数器正确
    Result.Success := (sharedCounter = Result.TotalOperations) and (totalErrors = 0)
  else
    Result.Success := (totalErrors < Result.TotalOperations * 0.1); // 允许少量失败
  
  WriteLn(Format('  完成: %d ms, 错误: %d, 计数器: %d, 成功: %s', 
    [Result.ElapsedMs, totalErrors, sharedCounter, BoolToStr(Result.Success, '是', '否')]));
end;

procedure TStressTestSuite.StressTestBasicConcurrency;
var
  policy: TSpinLockPolicy;
begin
  WriteLn('=== 基础并发测试 ===');
  
  policy := DefaultSpinLockPolicy;
  
  // 2 线程测试
  AddResult(RunMultiThreadTest('基础并发-2线程', 2, 50000, 0, policy));
  
  // 4 线程测试
  AddResult(RunMultiThreadTest('基础并发-4线程', 4, 25000, 0, policy));
  
  // 8 线程测试
  AddResult(RunMultiThreadTest('基础并发-8线程', 8, 12500, 0, policy));
end;

procedure TStressTestSuite.StressTestHighContention;
var
  policy: TSpinLockPolicy;
begin
  WriteLn('=== 高争用测试 ===');
  
  policy := DefaultSpinLockPolicy;
  policy.MaxSpins := 1000;
  
  // 16 线程高争用
  AddResult(RunMultiThreadTest('高争用-16线程', 16, 5000, 0, policy));
  
  // 32 线程极高争用
  AddResult(RunMultiThreadTest('极高争用-32线程', 32, 2500, 0, policy));
end;

procedure TStressTestSuite.StressTestMixedOperations;
var
  policy: TSpinLockPolicy;
begin
  WriteLn('=== 混合操作测试 ===');
  
  policy := DefaultSpinLockPolicy;
  
  // TryAcquire 测试
  AddResult(RunMultiThreadTest('TryAcquire测试', 8, 10000, 1, policy));
  
  // 混合操作测试
  AddResult(RunMultiThreadTest('混合操作测试', 8, 10000, 2, policy));
end;

procedure TStressTestSuite.StressTestLongRunning;
var
  policy: TSpinLockPolicy;
begin
  WriteLn('=== 长时间运行测试 ===');
  
  policy := DefaultSpinLockPolicy;
  
  // 长时间运行测试
  AddResult(RunMultiThreadTest('长时间运行', 4, 100000, 0, policy));
end;

procedure TStressTestSuite.RunAllStressTests;
begin
  WriteLn('开始 fafafa.core.sync.spin 并发压力测试套件...');
  WriteLn('');
  
  StressTestBasicConcurrency;
  StressTestHighContention;
  StressTestMixedOperations;
  StressTestLongRunning;
  
  PrintResults;
end;

var
  Suite: TStressTestSuite;
begin
  Suite := TStressTestSuite.Create;
  try
    Suite.RunAllStressTests;
  finally
    Suite.Free;
  end;
  
  WriteLn('并发压力测试完成。按回车键退出...');
  ReadLn;
end.
