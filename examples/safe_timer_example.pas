program safe_timer_example;

{$MODE OBJFPC}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.time,
  fafafa.core.time.timer,
  fafafa.core.time.timer.safe,
  fafafa.core.time.clock.safe,
  fafafa.core.result;

var
  SafeScheduler: ISafeTimerScheduler;
  SafeClock: IMonotonicClockSafe;
  
// 模拟可能失败的任务
procedure UnreliableTask;
begin
  if Random(100) < 30 then  // 30% 失败率
    raise Exception.Create('Task failed randomly');
  WriteLn('Task executed successfully');
end;

// 模拟长时间运行的任务
procedure LongRunningTask;
var
  I: Integer;
begin
  WriteLn('Starting long task...');
  for I := 1 to 5 do
  begin
    Sleep(200);
    Write('.');
  end;
  WriteLn(' Done!');
end;

// 展示基本的安全定时器用法
procedure DemoBasicSafeTimer;
var
  Timer: ISafeTimer;
  Stats: TTimerStats;
begin
  WriteLn('=== Basic Safe Timer Demo ===');
  
  // 创建一个带错误处理的定时器
  Timer := SafeScheduler.ScheduleSafeOnce(
    TDuration.FromMillis(100),
    function: TResult<Boolean, TTimerErrorInfo>
    var
      ErrorInfo: TTimerErrorInfo;
    begin
      try
        WriteLn('Safe timer callback executing...');
        UnreliableTask;
        Result := TResult<Boolean, TTimerErrorInfo>.Ok(True);
      except
        on E: Exception do
        begin
          ErrorInfo.Error := teCallbackError;
          ErrorInfo.Message := E.Message;
          ErrorInfo.Exception := E;
          Result := TResult<Boolean, TTimerErrorInfo>.Err(ErrorInfo);
        end;
      end;
    end,
    tesContinue  // 错误时继续执行
  );
  
  Sleep(200);
  
  // 获取统计信息
  Stats := Timer.Stats;
  WriteLn(Format('Executed: %d, Errors: %d', [Stats.ExecutedCount, Stats.ErrorCount]));
  if Stats.ErrorCount > 0 then
    WriteLn('Last error: ', Stats.LastError.Message);
  
  WriteLn;
end;

// 展示重试机制
procedure DemoRetryTimer;
var
  Timer: ISafeTimer;
  SuccessCount: Integer = 0;
  AttemptCount: Integer = 0;
begin
  WriteLn('=== Retry Timer Demo ===');
  
  Timer := CreateRetryTimer(
    SafeScheduler,
    TDuration.FromMillis(100),
    procedure
    begin
      Inc(AttemptCount);
      WriteLn(Format('Attempt %d...', [AttemptCount]));
      if AttemptCount < 3 then
        raise Exception.Create('Failed, will retry')
      else
      begin
        WriteLn('Success on attempt ', AttemptCount);
        Inc(SuccessCount);
      end;
    end,
    5,  // 最多重试5次
    TDuration.FromMillis(200)  // 重试延迟200ms
  );
  
  Sleep(2000);  // 等待重试完成
  
  WriteLn(Format('Final result: %d successful executions', [SuccessCount]));
  WriteLn;
end;

// 展示超时保护
procedure DemoTimeoutTimer;
var
  Timer: ISafeTimer;
begin
  WriteLn('=== Timeout Timer Demo ===');
  
  // 创建一个有超时保护的定时器
  Timer := CreateTimeoutTimer(
    SafeScheduler,
    TDuration.FromMillis(100),
    procedure
    begin
      WriteLn('Task with timeout starting...');
      Sleep(500);  // 模拟长时间操作
      WriteLn('Task completed (this should not print if timeout works)');
    end,
    TDuration.FromMillis(300)  // 300ms 超时
  );
  
  Sleep(1000);
  
  WriteLn('Timeout demo completed');
  WriteLn;
end;

// 展示周期性安全定时器
procedure DemoPeriodicSafeTimer;
var
  Timer: ISafeTimer;
  ExecutionCount: Integer = 0;
  ErrorCount: Integer = 0;
begin
  WriteLn('=== Periodic Safe Timer Demo ===');
  
  Timer := SafeScheduler.ScheduleSafeFixedRate(
    TDuration.FromMillis(100),  // 初始延迟
    TDuration.FromMillis(200),  // 周期
    function: TResult<Boolean, TTimerErrorInfo>
    var
      ErrorInfo: TTimerErrorInfo;
    begin
      Inc(ExecutionCount);
      WriteLn(Format('Periodic execution #%d', [ExecutionCount]));
      
      try
        if ExecutionCount mod 3 = 0 then
          raise Exception.Create('Simulated periodic error');
        Result := TResult<Boolean, TTimerErrorInfo>.Ok(True);
      except
        on E: Exception do
        begin
          Inc(ErrorCount);
          ErrorInfo.Error := teCallbackError;
          ErrorInfo.Message := E.Message;
          ErrorInfo.Exception := E;
          Result := TResult<Boolean, TTimerErrorInfo>.Err(ErrorInfo);
        end;
      end;
      
      // 执行10次后停止
      if ExecutionCount >= 10 then
        Timer.Cancel;
    end,
    tesContinue  // 错误时继续执行
  );
  
  Sleep(2500);  // 等待执行
  
  WriteLn(Format('Total executions: %d, Errors: %d', [ExecutionCount, ErrorCount]));
  WriteLn;
end;

// 展示错误策略
procedure DemoErrorStrategies;
var
  Timer1, Timer2, Timer3: ISafeTimer;
  ExecutionCount1, ExecutionCount2, ExecutionCount3: Integer;
begin
  WriteLn('=== Error Strategies Demo ===');
  
  ExecutionCount1 := 0;
  ExecutionCount2 := 0;
  ExecutionCount3 := 0;
  
  // 策略1：停止
  WriteLn('Timer 1: Stop on error');
  Timer1 := SafeScheduler.ScheduleSafeFixedDelay(
    TDuration.FromMillis(50),
    TDuration.FromMillis(100),
    function: TResult<Boolean, TTimerErrorInfo>
    var
      ErrorInfo: TTimerErrorInfo;
    begin
      Inc(ExecutionCount1);
      WriteLn(Format('  Timer1 execution #%d', [ExecutionCount1]));
      if ExecutionCount1 = 2 then
      begin
        ErrorInfo.Error := teCallbackError;
        ErrorInfo.Message := 'Stopping timer';
        Result := TResult<Boolean, TTimerErrorInfo>.Err(ErrorInfo);
      end
      else
        Result := TResult<Boolean, TTimerErrorInfo>.Ok(True);
    end,
    tesStop
  );
  
  // 策略2：继续
  WriteLn('Timer 2: Continue on error');
  Timer2 := SafeScheduler.ScheduleSafeFixedDelay(
    TDuration.FromMillis(50),
    TDuration.FromMillis(100),
    function: TResult<Boolean, TTimerErrorInfo>
    var
      ErrorInfo: TTimerErrorInfo;
    begin
      Inc(ExecutionCount2);
      WriteLn(Format('  Timer2 execution #%d', [ExecutionCount2]));
      if ExecutionCount2 mod 2 = 0 then
      begin
        ErrorInfo.Error := teCallbackError;
        ErrorInfo.Message := 'Error but continuing';
        Result := TResult<Boolean, TTimerErrorInfo>.Err(ErrorInfo);
      end
      else
        Result := TResult<Boolean, TTimerErrorInfo>.Ok(True);
      
      if ExecutionCount2 >= 5 then
        Timer2.Cancel;
    end,
    tesContinue
  );
  
  // 策略3：指数退避
  WriteLn('Timer 3: Exponential backoff on error');
  Timer3 := SafeScheduler.ScheduleSafeOnce(
    TDuration.FromMillis(50),
    function: TResult<Boolean, TTimerErrorInfo>
    var
      ErrorInfo: TTimerErrorInfo;
    begin
      Inc(ExecutionCount3);
      WriteLn(Format('  Timer3 attempt #%d', [ExecutionCount3]));
      if ExecutionCount3 < 3 then
      begin
        ErrorInfo.Error := teCallbackError;
        ErrorInfo.Message := Format('Attempt %d failed, will backoff', [ExecutionCount3]);
        Result := TResult<Boolean, TTimerErrorInfo>.Err(ErrorInfo);
      end
      else
      begin
        WriteLn('  Timer3 finally succeeded!');
        Result := TResult<Boolean, TTimerErrorInfo>.Ok(True);
      end;
    end,
    tesBackoff
  );
  
  Sleep(2000);
  
  WriteLn(Format('Final counts - Timer1: %d, Timer2: %d, Timer3: %d',
    [ExecutionCount1, ExecutionCount2, ExecutionCount3]));
  WriteLn;
end;

// 展示全局统计
procedure DemoGlobalStats;
var
  Stats: TTimerStats;
  I: Integer;
  Timer: ITimer;
begin
  WriteLn('=== Global Statistics Demo ===');
  
  // 创建多个定时器
  for I := 1 to 5 do
  begin
    SafeScheduler.ScheduleOnce(
      TDuration.FromMillis(I * 50),
      procedure
      begin
        WriteLn(Format('Timer %d executed', [I]));
        if I mod 2 = 0 then
          raise Exception.Create('Even timer error');
      end
    );
  end;
  
  Sleep(500);
  
  // 获取全局统计
  Stats := SafeScheduler.GetGlobalStats;
  WriteLn('Global Statistics:');
  WriteLn(Format('  Scheduled: %d', [Stats.ScheduledCount]));
  WriteLn(Format('  Executed: %d', [Stats.ExecutedCount]));
  WriteLn(Format('  Errors: %d', [Stats.ErrorCount]));
  WriteLn(Format('  Retries: %d', [Stats.RetryCount]));
  
  if Stats.ErrorCount > 0 then
    WriteLn(Format('  Last error: %s', [Stats.LastError.Message]));
  
  WriteLn;
end;

// 展示 Try 方法的使用
procedure DemoTryScheduling;
var
  Timer: ITimer;
  Result: TResult<Boolean, TTimerErrorInfo>;
begin
  WriteLn('=== Try Scheduling Demo ===');
  
  // 尝试调度一个定时器
  Result := SafeScheduler.TryScheduleOnce(
    TDuration.FromMillis(100),
    procedure
    begin
      WriteLn('Successfully scheduled timer executed');
    end,
    Timer
  );
  
  if Result.IsOk then
  begin
    WriteLn('Timer scheduled successfully');
    Sleep(200);
  end
  else
    WriteLn('Failed to schedule timer: ', Result.UnwrapErr.Message);
  
  // 模拟调度失败的情况
  SafeScheduler.Shutdown;  // 关闭调度器
  
  Result := SafeScheduler.TryScheduleOnce(
    TDuration.FromMillis(100),
    procedure
    begin
      WriteLn('This should not execute');
    end,
    Timer
  );
  
  if Result.IsErr then
    WriteLn('Expected failure after shutdown: ', Result.UnwrapErr.Message);
  
  WriteLn;
end;

begin
  Randomize;
  
  WriteLn('Safe Timer Module Examples');
  WriteLn('==========================');
  WriteLn;
  
  // 创建安全时钟和调度器
  SafeClock := CreateMonotonicClockSafe;
  SafeScheduler := CreateSafeTimerScheduler(SafeClock);
  
  try
    // 运行各种演示
    DemoBasicSafeTimer;
    DemoRetryTimer;
    DemoTimeoutTimer;
    DemoPeriodicSafeTimer;
    DemoErrorStrategies;
    DemoGlobalStats;
    DemoTryScheduling;
    
    WriteLn('All demos completed successfully!');
  except
    on E: Exception do
      WriteLn('Error in demo: ', E.Message);
  end;
  
  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
end.