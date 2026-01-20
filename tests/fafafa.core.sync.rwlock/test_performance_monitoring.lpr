{$CODEPAGE UTF8}
program test_performance_monitoring;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.rwlock.base, fafafa.core.sync.rwlock;

type
  TPerformanceTestThread = class(TThread)
  private
    FRWLock: TRWLock;
    FOperationCount: Integer;
    FIsReader: Boolean;
    FThreadIndex: Integer;
  public
    constructor Create(ARWLock: TRWLock; AOperationCount: Integer; AIsReader: Boolean; AThreadIndex: Integer);
    procedure Execute; override;
  end;

constructor TPerformanceTestThread.Create(ARWLock: TRWLock; AOperationCount: Integer; AIsReader: Boolean; AThreadIndex: Integer);
begin
  FRWLock := ARWLock;
  FOperationCount := AOperationCount;
  FIsReader := AIsReader;
  FThreadIndex := AThreadIndex;
  inherited Create(False);
end;

procedure TPerformanceTestThread.Execute;
var
  i: Integer;
begin
  for i := 1 to FOperationCount do
  begin
    if FIsReader then
    begin
      FRWLock.AcquireRead;
      try
        // 模拟读操作
        Sleep(0);
      finally
        FRWLock.ReleaseRead;
      end;
    end
    else
    begin
      FRWLock.AcquireWrite;
      try
        // 模拟写操作
        Sleep(1);
      finally
        FRWLock.ReleaseWrite;
      end;
    end;
  end;
end;

procedure TestBasicPerformanceStats;
var
  RWLock: TRWLock;
  Stats: TLockPerformanceStats;
  i: Integer;
begin
  WriteLn('=== 测试基础性能统计 ===');
  
  RWLock := TRWLock.Create;
  try
    // 执行一些操作
    for i := 1 to 100 do
    begin
      RWLock.AcquireRead;
      RWLock.ReleaseRead;
    end;
    
    for i := 1 to 50 do
    begin
      RWLock.AcquireWrite;
      RWLock.ReleaseWrite;
    end;
    
    // 获取性能统计
    Stats := RWLock.GetPerformanceStats;
    
    WriteLn('基础统计信息:');
    WriteLn('  总获取尝试: ', Stats.TotalAcquireAttempts);
    WriteLn('  成功获取: ', Stats.SuccessfulAcquires);
    WriteLn('  总释放: ', Stats.TotalReleases);
    WriteLn('  读锁尝试: ', Stats.ReadAcquireAttempts);
    WriteLn('  写锁尝试: ', Stats.WriteAcquireAttempts);
    WriteLn('  读锁成功: ', Stats.ReadSuccesses);
    WriteLn('  写锁成功: ', Stats.WriteSuccesses);
    WriteLn('  总等待时间: ', Stats.TotalWaitTime, ' μs');
    WriteLn('  最大等待时间: ', Stats.MaxWaitTime, ' μs');
    WriteLn('  最小等待时间: ', Stats.MinWaitTime, ' μs');
    
  finally
    RWLock.Free;
  end;
  
  WriteLn;
end;

procedure TestPerformanceMetrics;
var
  RWLock: TRWLock;
  ContentionRate, AvgWaitTime, Throughput, SpinEfficiency: Double;
  i: Integer;
begin
  WriteLn('=== 测试性能指标计算 ===');
  
  RWLock := TRWLock.Create;
  try
    // 执行一些操作来产生统计数据
    for i := 1 to 200 do
    begin
      RWLock.AcquireRead;
      Sleep(1);  // 模拟一些工作
      RWLock.ReleaseRead;
    end;
    
    // 获取计算的性能指标
    ContentionRate := RWLock.GetContentionRate;
    AvgWaitTime := RWLock.GetAverageWaitTime;
    Throughput := RWLock.GetThroughput;
    SpinEfficiency := RWLock.GetSpinEfficiency;
    
    WriteLn('性能指标:');
    WriteLn('  竞争率: ', ContentionRate:0:4);
    WriteLn('  平均等待时间: ', AvgWaitTime:0:2, ' μs');
    WriteLn('  吞吐量: ', Throughput:0:2, ' ops/sec');
    WriteLn('  自旋效率: ', SpinEfficiency:0:4);
    
  finally
    RWLock.Free;
  end;
  
  WriteLn;
end;

procedure TestMultiThreadedPerformanceStats;
var
  RWLock: TRWLock;
  Threads: array[0..7] of TPerformanceTestThread;
  Stats: TLockPerformanceStats;
  i: Integer;
  StartTime, EndTime: QWord;
  ElapsedMs: QWord;
  TotalOps: Integer;
  ActualThroughput: Double;
begin
  WriteLn('=== 测试多线程性能统计 ===');
  
  RWLock := TRWLock.Create;
  try
    StartTime := GetTickCount64;
    
    // 创建多个线程
    for i := 0 to 7 do
    begin
      if i < 6 then
        Threads[i] := TPerformanceTestThread.Create(RWLock, 500, True, i)  // 读线程
      else
        Threads[i] := TPerformanceTestThread.Create(RWLock, 100, False, i); // 写线程
    end;
    
    // 等待所有线程完成
    for i := 0 to 7 do
      Threads[i].WaitFor;
      
    EndTime := GetTickCount64;
    ElapsedMs := EndTime - StartTime;
    
    // 获取性能统计
    Stats := RWLock.GetPerformanceStats;
    TotalOps := 6 * 500 + 2 * 100;  // 6个读线程 + 2个写线程
    ActualThroughput := (TotalOps * 1000.0) / ElapsedMs;
    
    WriteLn('多线程统计信息:');
    WriteLn('  执行时间: ', ElapsedMs, ' ms');
    WriteLn('  总操作数: ', TotalOps);
    WriteLn('  实际吞吐量: ', ActualThroughput:0:2, ' ops/sec');
    WriteLn('  统计的总获取: ', Stats.TotalAcquireAttempts);
    WriteLn('  统计的成功获取: ', Stats.SuccessfulAcquires);
    WriteLn('  统计的总释放: ', Stats.TotalReleases);
    WriteLn('  竞争事件: ', Stats.ContentionEvents);
    WriteLn('  总自旋次数: ', Stats.TotalSpinCount);
    WriteLn('  自旋成功: ', Stats.SpinSuccesses);
    
    WriteLn('计算的性能指标:');
    WriteLn('  竞争率: ', RWLock.GetContentionRate:0:4);
    WriteLn('  平均等待时间: ', RWLock.GetAverageWaitTime:0:2, ' μs');
    WriteLn('  内部吞吐量: ', RWLock.GetThroughput:0:2, ' ops/sec');
    WriteLn('  自旋效率: ', RWLock.GetSpinEfficiency:0:4);
    
    // 清理线程
    for i := 0 to 7 do
      Threads[i].Free;
      
  finally
    RWLock.Free;
  end;
  
  WriteLn;
end;

procedure TestPerformanceStatsReset;
var
  RWLock: TRWLock;
  StatsBefore, StatsAfter: TLockPerformanceStats;
  i: Integer;
begin
  WriteLn('=== 测试性能统计重置 ===');
  
  RWLock := TRWLock.Create;
  try
    // 执行一些操作
    for i := 1 to 50 do
    begin
      RWLock.AcquireRead;
      RWLock.ReleaseRead;
    end;
    
    StatsBefore := RWLock.GetPerformanceStats;
    WriteLn('重置前统计:');
    WriteLn('  总获取尝试: ', StatsBefore.TotalAcquireAttempts);
    WriteLn('  成功获取: ', StatsBefore.SuccessfulAcquires);
    
    // 重置统计
    RWLock.ResetPerformanceStats;
    
    StatsAfter := RWLock.GetPerformanceStats;
    WriteLn('重置后统计:');
    WriteLn('  总获取尝试: ', StatsAfter.TotalAcquireAttempts);
    WriteLn('  成功获取: ', StatsAfter.SuccessfulAcquires);
    WriteLn('  开始时间: ', StatsAfter.StartTime);
    WriteLn('  重置时间: ', StatsAfter.LastResetTime);
    
    // 验证重置是否成功
    if (StatsAfter.TotalAcquireAttempts = 0) and (StatsAfter.SuccessfulAcquires = 0) then
      WriteLn('✓ 统计重置成功')
    else
      WriteLn('✗ 统计重置失败');
    
  finally
    RWLock.Free;
  end;
  
  WriteLn;
end;

begin
  WriteLn('fafafa.core.sync.rwlock 性能监控测试');
  WriteLn('====================================');
  WriteLn;
  
  TestBasicPerformanceStats;
  TestPerformanceMetrics;
  TestMultiThreadedPerformanceStats;
  TestPerformanceStatsReset;
  
  WriteLn('性能监控测试完成');
  WriteLn('验证了详细的性能统计和监控功能');
end.
