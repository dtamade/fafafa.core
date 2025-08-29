{$CODEPAGE UTF8}
program stress_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes, DateUtils,
  fafafa.core.sync.namedEvent;

type
  TStressTestResult = record
    TestName: string;
    ThreadCount: Integer;
    Duration: Integer; // 秒
    TotalOperations: Int64;
    SuccessfulOperations: Int64;
    FailedOperations: Int64;
    OperationsPerSecond: Double;
    ErrorRate: Double;
    MaxMemoryUsage: Int64; // KB
  end;

  TStressWorker = class(TThread)
  private
    FEvent: INamedEvent;
    FDurationSeconds: Integer;
    FOperationCount: Int64;
    FSuccessCount: Int64;
    FErrorCount: Int64;
    FWorkerID: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AWorkerID: Integer; AEvent: INamedEvent; ADurationSeconds: Integer);
    property OperationCount: Int64 read FOperationCount;
    property SuccessCount: Int64 read FSuccessCount;
    property ErrorCount: Int64 read FErrorCount;
  end;

constructor TStressWorker.Create(AWorkerID: Integer; AEvent: INamedEvent; ADurationSeconds: Integer);
begin
  FWorkerID := AWorkerID;
  FEvent := AEvent;
  FDurationSeconds := ADurationSeconds;
  FOperationCount := 0;
  FSuccessCount := 0;
  FErrorCount := 0;
  inherited Create(False);
end;

procedure TStressWorker.Execute;
var
  LStartTime: TDateTime;
  LGuard: INamedEventGuard;
  LElapsed: Double;
begin
  LStartTime := Now;
  
  while True do
  begin
    LElapsed := (Now - LStartTime) * 24 * 60 * 60; // 秒
    if LElapsed >= FDurationSeconds then
      Break;
      
    Inc(FOperationCount);
    
    try
      // 随机选择操作类型
      case Random(3) of
        0: begin
          // 非阻塞等待
          LGuard := FEvent.TryWait;
          if Assigned(LGuard) then
          begin
            Inc(FSuccessCount);
            LGuard := nil;
          end;
        end;
        1: begin
          // 短超时等待
          LGuard := FEvent.TryWaitFor(10);
          if Assigned(LGuard) then
          begin
            Inc(FSuccessCount);
            LGuard := nil;
          end;
        end;
        2: begin
          // 触发事件（只有部分线程执行）
          if FWorkerID mod 4 = 0 then
          begin
            FEvent.SetEvent;
            Inc(FSuccessCount);
          end;
        end;
      end;
      
    except
      on E: Exception do
      begin
        Inc(FErrorCount);
        // 在压力测试中不输出错误，避免影响性能
      end;
    end;
    
    // 短暂休息，避免过度占用CPU
    if FOperationCount mod 1000 = 0 then
      Sleep(1);
  end;
end;

function GetMemoryUsage: Int64;
var
  LMemInfo: string;
  LFile: TextFile;
  LLine: string;
  LPos: Integer;
begin
  Result := 0;
  try
    AssignFile(LFile, '/proc/self/status');
    Reset(LFile);
    
    while not EOF(LFile) do
    begin
      ReadLn(LFile, LLine);
      if Pos('VmRSS:', LLine) = 1 then
      begin
        LPos := Pos(':', LLine);
        if LPos > 0 then
        begin
          LMemInfo := Trim(Copy(LLine, LPos + 1, Length(LLine)));
          LPos := Pos(' ', LMemInfo);
          if LPos > 0 then
            LMemInfo := Copy(LMemInfo, 1, LPos - 1);
          Result := StrToInt64Def(LMemInfo, 0);
          Break;
        end;
      end;
    end;
    
    CloseFile(LFile);
  except
    Result := 0;
  end;
end;

function RunStressTest(AThreadCount, ADurationSeconds: Integer; const ATestName: string): TStressTestResult;
var
  LEvent: INamedEvent;
  LWorkers: array of TStressWorker;
  I: Integer;
  LStartTime: TDateTime;
  LStartMemory, LMaxMemory, LCurrentMemory: Int64;
  LTotalOps, LTotalSuccess, LTotalErrors: Int64;
begin
  WriteLn('开始压力测试: ', ATestName);
  WriteLn('线程数: ', AThreadCount, ', 持续时间: ', ADurationSeconds, ' 秒');
  
  // 创建事件
  LEvent := MakeManualResetNamedEvent('StressTest_' + ATestName, False);
  
  // 记录初始内存
  LStartMemory := GetMemoryUsage;
  LMaxMemory := LStartMemory;
  
  SetLength(LWorkers, AThreadCount);
  
  // 创建工作线程
  for I := 0 to AThreadCount - 1 do
  begin
    LWorkers[I] := TStressWorker.Create(I, LEvent, ADurationSeconds);
  end;
  
  LStartTime := Now;
  
  // 定期触发事件和监控内存
  while (Now - LStartTime) * 24 * 60 * 60 < ADurationSeconds do
  begin
    // 触发事件
    LEvent.SetEvent;
    Sleep(50);
    LEvent.ResetEvent;
    Sleep(50);
    
    // 监控内存使用
    LCurrentMemory := GetMemoryUsage;
    if LCurrentMemory > LMaxMemory then
      LMaxMemory := LCurrentMemory;
      
    // 每10秒输出一次进度
    if Trunc((Now - LStartTime) * 24 * 60 * 60) mod 10 = 0 then
    begin
      Write('.');
      if Trunc((Now - LStartTime) * 24 * 60 * 60) mod 60 = 0 then
        WriteLn(' ', Trunc((Now - LStartTime) * 24 * 60 * 60), 's');
    end;
  end;
  
  WriteLn;
  WriteLn('等待所有线程完成...');
  
  // 等待所有线程完成
  LTotalOps := 0;
  LTotalSuccess := 0;
  LTotalErrors := 0;
  
  for I := 0 to AThreadCount - 1 do
  begin
    LWorkers[I].WaitFor;
    LTotalOps := LTotalOps + LWorkers[I].OperationCount;
    LTotalSuccess := LTotalSuccess + LWorkers[I].SuccessCount;
    LTotalErrors := LTotalErrors + LWorkers[I].ErrorCount;
    LWorkers[I].Free;
  end;
  
  // 计算结果
  Result.TestName := ATestName;
  Result.ThreadCount := AThreadCount;
  Result.Duration := ADurationSeconds;
  Result.TotalOperations := LTotalOps;
  Result.SuccessfulOperations := LTotalSuccess;
  Result.FailedOperations := LTotalErrors;
  Result.OperationsPerSecond := LTotalOps / ADurationSeconds;
  Result.ErrorRate := (LTotalErrors / LTotalOps) * 100;
  Result.MaxMemoryUsage := LMaxMemory - LStartMemory;
  
  WriteLn('✓ 压力测试完成');
end;

procedure PrintStressResult(const AResult: TStressTestResult);
begin
  WriteLn('========================================');
  WriteLn('压力测试结果: ', AResult.TestName);
  WriteLn('========================================');
  WriteLn('线程数: ', AResult.ThreadCount);
  WriteLn('持续时间: ', AResult.Duration, ' 秒');
  WriteLn('总操作数: ', AResult.TotalOperations);
  WriteLn('成功操作: ', AResult.SuccessfulOperations);
  WriteLn('失败操作: ', AResult.FailedOperations);
  WriteLn('平均吞吐量: ', FormatFloat('0.00', AResult.OperationsPerSecond), ' ops/sec');
  WriteLn('错误率: ', FormatFloat('0.00', AResult.ErrorRate), '%');
  WriteLn('最大内存增长: ', AResult.MaxMemoryUsage, ' KB');
  WriteLn('========================================');
  WriteLn;
end;

procedure RunAllStressTests;
var
  LResult: TStressTestResult;
begin
  WriteLn('fafafa.core.sync.namedEvent 压力测试套件');
  WriteLn('==========================================');
  WriteLn;
  
  // 中等并发短时间测试
  LResult := RunStressTest(10, 30, 'Medium_Concurrency_Short');
  PrintStressResult(LResult);
  
  // 高并发短时间测试（减少时间以适应演示）
  LResult := RunStressTest(50, 30, 'High_Concurrency_Short');
  PrintStressResult(LResult);
  
  WriteLn('🎉 压力测试完成！');
end;

begin
  // 初始化随机数种子
  Randomize;
  
  try
    RunAllStressTests;
  except
    on E: Exception do
    begin
      WriteLn('❌ 压力测试出错: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
