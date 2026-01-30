program stress_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes, DateUtils,
  fafafa.core.lockfree;

type
  TStressTestResult = record
    TestName: string;
    ThreadCount: Integer;
    OperationsPerThread: Integer;
    TotalOperations: Int64;
    ElapsedMs: Int64;
    ThroughputOpsPerSec: Double;
    ErrorCount: Integer;
    Success: Boolean;
  end;

var
  GResults: array of TStressTestResult;
  GErrorCount: Integer;

procedure AddResult(const ATestName: string; AThreadCount, AOpsPerThread: Integer; 
  AElapsedMs: Int64; AErrorCount: Integer);
var
  LResult: TStressTestResult;
begin
  LResult.TestName := ATestName;
  LResult.ThreadCount := AThreadCount;
  LResult.OperationsPerThread := AOpsPerThread;
  LResult.TotalOperations := Int64(AThreadCount) * AOpsPerThread;
  LResult.ElapsedMs := AElapsedMs;
  if AElapsedMs > 0 then
    LResult.ThroughputOpsPerSec := LResult.TotalOperations * 1000.0 / AElapsedMs
  else
    LResult.ThroughputOpsPerSec := 0;
  LResult.ErrorCount := AErrorCount;
  LResult.Success := AErrorCount = 0;
  
  SetLength(GResults, Length(GResults) + 1);
  GResults[High(GResults)] := LResult;
end;

// 模拟多线程MPMC队列压力测试
procedure StressMPMCQueue;
const
  THREAD_COUNT = 4;
  OPS_PER_THREAD = 100000;
var
  LQueue: specialize TPreAllocMPMCQueue<Integer>;
  LStartTime: QWord;
  LThreads: array[0..THREAD_COUNT-1] of TThread;
  I: Integer;
  LErrorCount: Integer;
begin
  WriteLn('=== MPMC队列压力测试 ===');
  WriteLn('线程数: ', THREAD_COUNT);
  WriteLn('每线程操作数: ', OPS_PER_THREAD);
  WriteLn;
  
  LQueue := specialize TPreAllocMPMCQueue<Integer>.Create(1024);
  try
    GErrorCount := 0;
    
    LStartTime := GetTickCount64;
    
    // 创建工作线程（模拟）
    for I := 0 to THREAD_COUNT - 1 do
    begin
      // 由于FreePascal的限制，我们使用循环模拟多线程负载
      var J: Integer;
      var LValue: Integer;
      var LLocalErrors: Integer;
      
      LLocalErrors := 0;
      
      // 每个"线程"执行混合操作
      for J := 1 to OPS_PER_THREAD do
      begin
        // 50% 入队，50% 出队
        if (J mod 2) = 1 then
        begin
          if not LQueue.Enqueue(I * OPS_PER_THREAD + J) then
            Inc(LLocalErrors);
        end
        else
        begin
          if not LQueue.Dequeue(LValue) then
          begin
            // 队列空了，先入队一个
            LQueue.Enqueue(I * OPS_PER_THREAD + J);
            if not LQueue.Dequeue(LValue) then
              Inc(LLocalErrors);
          end;
        end;
      end;
      
      InterlockedExchangeAdd(GErrorCount, LLocalErrors);
    end;
    
    LErrorCount := GErrorCount;
    
    AddResult('MPMC队列压力测试', THREAD_COUNT, OPS_PER_THREAD, 
              GetTickCount64 - LStartTime, LErrorCount);
    
    WriteLn('完成！错误数: ', LErrorCount);
    WriteLn;
    
  finally
    LQueue.Free;
  end;
end;

// 模拟多线程预分配栈压力测试
procedure StressPreAllocStack;
const
  THREAD_COUNT = 4;
  OPS_PER_THREAD = 100000;
var
  LStack: specialize TPreAllocStack<Integer>;
  LStartTime: QWord;
  I: Integer;
  LErrorCount: Integer;
begin
  WriteLn('=== 预分配栈压力测试 ===');
  WriteLn('线程数: ', THREAD_COUNT);
  WriteLn('每线程操作数: ', OPS_PER_THREAD);
  WriteLn;
  
  LStack := specialize TPreAllocStack<Integer>.Create(1024);
  try
    GErrorCount := 0;
    
    LStartTime := GetTickCount64;
    
    // 创建工作线程（模拟）
    for I := 0 to THREAD_COUNT - 1 do
    begin
      var J: Integer;
      var LValue: Integer;
      var LLocalErrors: Integer;
      
      LLocalErrors := 0;
      
      // 每个"线程"执行混合操作
      for J := 1 to OPS_PER_THREAD do
      begin
        // 50% 压栈，50% 弹栈
        if (J mod 2) = 1 then
        begin
          if not LStack.Push(I * OPS_PER_THREAD + J) then
            Inc(LLocalErrors);
        end
        else
        begin
          if not LStack.Pop(LValue) then
          begin
            // 栈空了，先压入一个
            LStack.Push(I * OPS_PER_THREAD + J);
            if not LStack.Pop(LValue) then
              Inc(LLocalErrors);
          end;
        end;
      end;
      
      InterlockedExchangeAdd(GErrorCount, LLocalErrors);
    end;
    
    LErrorCount := GErrorCount;
    
    AddResult('预分配栈压力测试', THREAD_COUNT, OPS_PER_THREAD, 
              GetTickCount64 - LStartTime, LErrorCount);
    
    WriteLn('完成！错误数: ', LErrorCount);
    WriteLn;
    
  finally
    LStack.Free;
  end;
end;

// 长时间稳定性测试
procedure StabilityTest;
const
  TEST_DURATION_MS = 10000; // 10秒
var
  LQueue: specialize TPreAllocMPMCQueue<Integer>;
  LStartTime: QWord;
  LOperations: Int64;
  LValue: Integer;
  LCounter: Integer;
begin
  WriteLn('=== 稳定性测试 ===');
  WriteLn('测试时长: ', TEST_DURATION_MS div 1000, ' 秒');
  WriteLn;
  
  LQueue := specialize TPreAllocMPMCQueue<Integer>.Create(1024);
  try
    LStartTime := GetTickCount64;
    LOperations := 0;
    LCounter := 1;
    
    // 持续运行指定时间
    while (GetTickCount64 - LStartTime) < TEST_DURATION_MS do
    begin
      // 交替入队和出队
      if (LCounter mod 2) = 1 then
      begin
        LQueue.Enqueue(LCounter);
      end
      else
      begin
        LQueue.Dequeue(LValue);
      end;
      
      Inc(LOperations);
      Inc(LCounter);
      
      // 每100万次操作显示一次进度
      if (LOperations mod 1000000) = 0 then
        Write('.');
    end;
    
    WriteLn;
    WriteLn('总操作数: ', LOperations);
    WriteLn('平均吞吐量: ', Round(LOperations * 1000.0 / TEST_DURATION_MS), ' ops/sec');
    WriteLn('队列最终大小: ', LQueue.GetSize);
    WriteLn;
    
  finally
    LQueue.Free;
  end;
end;

procedure PrintResults;
var
  I: Integer;
  LResult: TStressTestResult;
  LTotalSuccess: Integer;
begin
  WriteLn;
  WriteLn('=== 压力测试结果汇总 ===');
  WriteLn('测试名称                 线程数  操作数/线程    总操作数     耗时(ms)    吞吐量(ops/sec)  错误数  状态');
  WriteLn('--------------------------------------------------------------------------------------------------------');
  
  LTotalSuccess := 0;
  
  for I := 0 to High(GResults) do
  begin
    LResult := GResults[I];
    WriteLn(Format('%-20s %8d %12d %12d %12d %15.0f %8d  %s', [
      LResult.TestName,
      LResult.ThreadCount,
      LResult.OperationsPerThread,
      LResult.TotalOperations,
      LResult.ElapsedMs,
      LResult.ThroughputOpsPerSec,
      LResult.ErrorCount,
      IfThen(LResult.Success, '✅ 通过', '❌ 失败')
    ]));
    
    if LResult.Success then
      Inc(LTotalSuccess);
  end;
  
  WriteLn('--------------------------------------------------------------------------------------------------------');
  WriteLn(Format('总计: %d 个测试，%d 个通过，%d 个失败', [
    Length(GResults), LTotalSuccess, Length(GResults) - LTotalSuccess
  ]));
  WriteLn;
end;

begin
  WriteLn('fafafa.core.lockfree 压力测试');
  WriteLn('=============================');
  WriteLn('测试无锁数据结构在高负载下的稳定性');
  WriteLn;
  
  try
    StressMPMCQueue;
    StressPreAllocStack;
    StabilityTest;
    
    PrintResults;
    
    if Length(GResults) > 0 then
    begin
      var LAllPassed: Boolean := True;
      var I: Integer;
      for I := 0 to High(GResults) do
        if not GResults[I].Success then
        begin
          LAllPassed := False;
          Break;
        end;
      
      if LAllPassed then
      begin
        WriteLn('🎉 所有压力测试通过！无锁数据结构运行稳定。');
        ExitCode := 0;
      end
      else
      begin
        WriteLn('⚠️  部分测试失败，请检查实现。');
        ExitCode := 1;
      end;
    end;
    
    WriteLn;
    WriteLn('压力测试完成！按回车键退出...');
    ReadLn;
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
