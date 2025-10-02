program safe_clock_usage_example;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.time.base,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.clock,
  fafafa.core.time.clock.safe,
  fafafa.core.time.result,
  fafafa.core.time.duration.safe,
  fafafa.core.thread.cancel;

{ 示例 1: 基本的错误处理 }
procedure Example1_BasicErrorHandling;
var
  safeClock: IMonotonicClockSafe;
  instant: TInstant;
  duration: TDuration;
begin
  WriteLn('=== 示例 1: 基本错误处理 ===');
  
  safeClock := CreateMonotonicClockSafe(nil);
  
  // Try 模式 - 简单的成功/失败检查
  if safeClock.TryNowInstant(instant) then
    WriteLn('获取时间成功: ', instant.AsNsSinceEpoch, ' ns')
  else
    WriteLn('获取时间失败！');
  
  // Result 模式 - 更详细的错误信息
  var instantResult := safeClock.NowInstantResult;
  if instantResult.IsOk then
    WriteLn('当前时间: ', instantResult.Value.AsNsSinceEpoch, ' ns')
  else
    WriteLn('错误: ', instantResult.Error.Message);
  
  WriteLn;
end;

{ 示例 2: 带重试的健壮时间操作 }
procedure Example2_RobustTimeOperationWithRetry;
var
  safeClock: IMonotonicClockSafe;
  
  function GetTimeWithRetry(MaxRetries: Integer): TInstant;
  var
    i: Integer;
    instant: TInstant;
  begin
    for i := 1 to MaxRetries do
    begin
      if safeClock.TryNowInstant(instant) then
      begin
        WriteLn('  第 ', i, ' 次尝试成功');
        Exit(instant);
      end;
      WriteLn('  第 ', i, ' 次尝试失败，重试中...');
      Sleep(10); // 短暂延迟后重试
    end;
    raise Exception.Create('获取时间失败，已达最大重试次数');
  end;
  
var
  startTime, endTime: TInstant;
  elapsed: TDuration;
begin
  WriteLn('=== 示例 2: 带重试的健壮操作 ===');
  
  safeClock := CreateMonotonicClockSafe(nil);
  
  try
    startTime := GetTimeWithRetry(3);
    
    // 执行一些操作
    WriteLn('执行业务逻辑...');
    Sleep(100);
    
    endTime := GetTimeWithRetry(3);
    
    elapsed := endTime.Diff(startTime);
    WriteLn('操作耗时: ', elapsed.AsMs, ' ms');
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
  
  WriteLn;
end;

{ 示例 3: 监控和统计 }
procedure Example3_MonitoringAndStatistics;
var
  safeClock: IMonotonicClockSafe;
  stats: TClockErrorStats;
  instant: TInstant;
  i: Integer;
begin
  WriteLn('=== 示例 3: 监控和统计 ===');
  
  safeClock := CreateMonotonicClockSafe(nil);
  safeClock.ResetErrorStats;
  
  // 执行多次操作
  WriteLn('执行 100 次时间获取操作...');
  for i := 1 to 100 do
  begin
    safeClock.TryNowInstant(instant);
    if i mod 25 = 0 then
      Write('.');
  end;
  WriteLn;
  
  // 获取统计信息
  stats := safeClock.GetErrorStats;
  WriteLn('统计信息:');
  WriteLn('  总操作数: ', stats.TotalOperations);
  WriteLn('  成功次数: ', stats.SuccessfulOperations);
  WriteLn('  失败次数: ', stats.FailedOperations);
  
  if stats.FailedOperations > 0 then
  begin
    WriteLn('  成功率: ', 
      FormatFloat('0.00', (stats.SuccessfulOperations / stats.TotalOperations) * 100), '%');
    WriteLn('  最后错误: ', stats.LastError.Message);
    WriteLn('  错误时间: ', stats.LastErrorTime.AsNsSinceEpoch, ' ns');
  end
  else
    WriteLn('  成功率: 100%');
  
  WriteLn;
end;

{ 示例 4: 超时和取消操作 }
procedure Example4_TimeoutAndCancellation;
var
  safeClock: IMonotonicClockSafe;
  cancelToken: ICancellationTokenSource;
  waitResult: Boolean;
  success: Boolean;
  thread: TThread;
begin
  WriteLn('=== 示例 4: 超时和取消操作 ===');
  
  safeClock := CreateMonotonicClockSafe(nil);
  
  // 创建取消令牌
  cancelToken := CreateCancellationTokenSource;
  
  // 在后台线程中取消操作
  thread := TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(500); // 500ms 后取消
      cancelToken.Cancel;
      WriteLn('  [后台线程] 已发送取消信号');
    end
  );
  thread.Start;
  
  WriteLn('开始等待 2 秒，但会在 500ms 时被取消...');
  success := safeClock.TryWaitFor(TDuration.FromSeconds(2), cancelToken.Token, waitResult);
  
  if success then
  begin
    if waitResult then
      WriteLn('等待完成（未被取消）')
    else
      WriteLn('等待被取消');
  end
  else
    WriteLn('等待操作失败');
  
  thread.WaitFor;
  thread.Free;
  
  WriteLn;
end;

{ 示例 5: 安全的性能测量 }
procedure Example5_SafePerformanceMeasurement;
var
  safeClock: IMonotonicClockSafe;
  
  function MeasureOperation(const Operation: TProc): TDurationResult;
  var
    startResult, endResult: TInstantResult;
    start, endTime: TInstant;
  begin
    startResult := safeClock.NowInstantResult;
    if not startResult.IsOk then
      Exit(TDurationResult.Err(startResult.Error));
    
    start := startResult.Value;
    
    // 执行操作
    Operation();
    
    endResult := safeClock.NowInstantResult;
    if not endResult.IsOk then
      Exit(TDurationResult.Err(endResult.Error));
    
    endTime := endResult.Value;
    
    Result := TDurationResult.Ok(endTime.Diff(start));
  end;
  
var
  durationResult: TDurationResult;
  totalTime: TDuration;
  i: Integer;
begin
  WriteLn('=== 示例 5: 安全的性能测量 ===');
  
  safeClock := CreateMonotonicClockSafe(nil);
  totalTime := TDuration.Zero;
  
  WriteLn('测量 5 次操作的执行时间...');
  for i := 1 to 5 do
  begin
    durationResult := MeasureOperation(
      procedure
      begin
        // 模拟一些工作
        Sleep(Random(50) + 10);
      end
    );
    
    if durationResult.IsOk then
    begin
      WriteLn('  操作 ', i, ': ', durationResult.Value.AsMs, ' ms');
      totalTime := totalTime.Add(durationResult.Value);
    end
    else
      WriteLn('  操作 ', i, ': 测量失败 - ', durationResult.Error.Message);
  end;
  
  WriteLn('总耗时: ', totalTime.AsMs, ' ms');
  WriteLn('平均耗时: ', totalTime.AsMs div 5, ' ms');
  
  WriteLn;
end;

{ 示例 6: 综合应用 - 带监控的批处理任务 }
type
  TBatchProcessor = class
  private
    FClock: IMonotonicClockSafe;
    FSystemClock: ISystemClockSafe;
    FItemsProcessed: Integer;
    FErrors: Integer;
    
    procedure ProcessItem(ItemId: Integer);
  public
    constructor Create;
    procedure RunBatch(ItemCount: Integer);
    procedure PrintReport;
  end;

constructor TBatchProcessor.Create;
begin
  FClock := CreateMonotonicClockSafe(nil);
  FSystemClock := CreateSystemClockSafe(nil);
  FItemsProcessed := 0;
  FErrors := 0;
end;

procedure TBatchProcessor.ProcessItem(ItemId: Integer);
var
  sleepResult: TBoolResult;
begin
  // 模拟处理
  sleepResult := FClock.SleepForResult(TDuration.FromMs(Random(20) + 5));
  
  if sleepResult.IsOk then
  begin
    Inc(FItemsProcessed);
    Write('.');
  end
  else
  begin
    Inc(FErrors);
    Write('X');
  end;
  
  if ItemId mod 20 = 0 then
    WriteLn(' [', ItemId, ']');
end;

procedure TBatchProcessor.RunBatch(ItemCount: Integer);
var
  startTimeResult: TDateTimeResult;
  startInstant: TInstant;
  endInstant: TInstant;
  i: Integer;
begin
  WriteLn('开始批处理 ', ItemCount, ' 个项目...');
  
  // 记录开始时间
  startTimeResult := FSystemClock.NowLocalResult;
  if startTimeResult.IsOk then
    WriteLn('开始时间: ', FormatDateTime('yyyy-mm-dd hh:nn:ss', startTimeResult.Value));
  
  if not FClock.TryNowInstant(startInstant) then
  begin
    WriteLn('无法获取开始时间');
    Exit;
  end;
  
  // 处理项目
  for i := 1 to ItemCount do
    ProcessItem(i);
  
  if not FClock.TryNowInstant(endInstant) then
  begin
    WriteLn('无法获取结束时间');
    Exit;
  end;
  
  WriteLn;
  WriteLn('批处理完成！');
  WriteLn('  处理成功: ', FItemsProcessed, ' 项');
  WriteLn('  处理失败: ', FErrors, ' 项');
  WriteLn('  总耗时: ', endInstant.Diff(startInstant).AsMs, ' ms');
end;

procedure TBatchProcessor.PrintReport;
var
  clockStats: TClockErrorStats;
  sysStats: TClockErrorStats;
begin
  WriteLn;
  WriteLn('=== 性能报告 ===');
  
  clockStats := FClock.GetErrorStats;
  WriteLn('单调时钟统计:');
  WriteLn('  总操作: ', clockStats.TotalOperations);
  WriteLn('  成功: ', clockStats.SuccessfulOperations);
  WriteLn('  失败: ', clockStats.FailedOperations);
  
  sysStats := FSystemClock.GetErrorStats;
  WriteLn('系统时钟统计:');
  WriteLn('  总操作: ', sysStats.TotalOperations);
  WriteLn('  成功: ', sysStats.SuccessfulOperations);
  WriteLn('  失败: ', sysStats.FailedOperations);
end;

procedure Example6_BatchProcessingWithMonitoring;
var
  processor: TBatchProcessor;
begin
  WriteLn('=== 示例 6: 带监控的批处理任务 ===');
  
  processor := TBatchProcessor.Create;
  try
    processor.RunBatch(50);
    processor.PrintReport;
  finally
    processor.Free;
  end;
  
  WriteLn;
end;

{ 示例 7: 安全的 Duration 运算集成 }
procedure Example7_SafeDurationArithmetic;
var
  safeClock: IMonotonicClockSafe;
  start, finish: TInstant;
  elapsed: TDuration;
  doubled: TDurationResult;
  halfed: TDurationResult;
begin
  WriteLn('=== 示例 7: 安全的 Duration 运算 ===');
  
  safeClock := CreateMonotonicClockSafe(nil);
  
  // 获取起始时间
  if not safeClock.TryNowInstant(start) then
  begin
    WriteLn('无法获取起始时间');
    Exit;
  end;
  
  // 执行一些操作
  Sleep(123);
  
  // 获取结束时间
  if not safeClock.TryNowInstant(finish) then
  begin
    WriteLn('无法获取结束时间');
    Exit;
  end;
  
  // 计算耗时
  elapsed := finish.Diff(start);
  WriteLn('原始耗时: ', elapsed.AsMs, ' ms');
  
  // 安全的乘法运算
  doubled := elapsed.CheckedMul(2);
  if doubled.IsOk then
    WriteLn('双倍时间: ', doubled.Value.AsMs, ' ms')
  else
    WriteLn('计算双倍时间失败: ', doubled.Error.Message);
  
  // 安全的除法运算
  halfed := elapsed.CheckedDiv(2);
  if halfed.IsOk then
    WriteLn('一半时间: ', halfed.Value.AsMs, ' ms')
  else
    WriteLn('计算一半时间失败: ', halfed.Error.Message);
  
  // 饱和运算（不会溢出）
  var saturated := elapsed.SaturatingMul(1000000);
  WriteLn('饱和乘法结果: ', saturated.AsSeconds, ' 秒');
  
  WriteLn;
end;

{ 主程序 }
begin
  Randomize;
  
  WriteLn('===================================');
  WriteLn('   安全时钟接口使用示例');
  WriteLn('===================================');
  WriteLn;
  
  try
    Example1_BasicErrorHandling;
    Example2_RobustTimeOperationWithRetry;
    Example3_MonitoringAndStatistics;
    Example4_TimeoutAndCancellation;
    Example5_SafePerformanceMeasurement;
    Example6_BatchProcessingWithMonitoring;
    Example7_SafeDurationArithmetic;
    
    WriteLn('所有示例执行完成！');
    WriteLn;
    WriteLn('总结：');
    WriteLn('- 使用 Try 模式进行简单的错误检查');
    WriteLn('- 使用 Result 模式获取详细的错误信息');
    WriteLn('- 通过统计功能监控系统健康状态');
    WriteLn('- 实现重试机制提高系统可靠性');
    WriteLn('- 集成安全的 Duration 运算避免溢出');
  except
    on E: Exception do
      WriteLn('程序错误: ', E.Message);
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.