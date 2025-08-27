program PerformanceMonitoringDemo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.sync,
  fafafa.core.lockfree;

{**
 * 性能监控演示程序
 * 展示如何使用性能监控器来分析无锁数据结构的性能
 *}

{**
 * 演示SPSC队列的性能监控
 *}
procedure DemoSPSCQueueMonitoring;
type
  TIntQueue = TIntegerSPSCQueue;
var
  LQueue: TIntQueue;
  LMonitor: TPerformanceMonitor;
  LStartTime: QWord;
  LValue: Integer;
  I: Integer;
const
  OPERATIONS = 1000000;
begin
  WriteLn('=== SPSC队列性能监控演示 ===');
  
  LQueue := CreateIntSPSCQueue(OPERATIONS);
  LMonitor := TPerformanceMonitor.Create;
  try
    LMonitor.Enable;
    WriteLn('开始监控SPSC队列性能...');
    WriteLn('执行', OPERATIONS, '次入队和出队操作');
    WriteLn;
    
    // 入队操作监控
    WriteLn('入队阶段:');
    LStartTime := GetTickCount64;
    for I := 1 to OPERATIONS do
    begin
      LMonitor.RecordOperation(LQueue.Enqueue(I));
      
      // 每10万次操作输出一次进度
      if I mod 100000 = 0 then
        Write('.');
    end;
    WriteLn;
    WriteLn('入队完成，耗时: ', GetTickCount64 - LStartTime, ' ms');
    WriteLn;
    
    // 出队操作监控
    WriteLn('出队阶段:');
    LStartTime := GetTickCount64;
    for I := 1 to OPERATIONS do
    begin
      LMonitor.RecordOperation(LQueue.Dequeue(LValue));
      
      if I mod 100000 = 0 then
        Write('.');
    end;
    WriteLn;
    WriteLn('出队完成，耗时: ', GetTickCount64 - LStartTime, ' ms');
    WriteLn;
    
    // 输出性能报告
    WriteLn(LMonitor.GenerateReport);
    
  finally
    LQueue.Free;
    LMonitor.Free;
  end;
  WriteLn;
end;

{**
 * 演示 MPSC（Michael-Scott）队列的性能监控
 *}
procedure DemoMichaelScottQueueMonitoring;
type
  TIntQueue = TIntMPSCQueue;
var
  LQueue: TIntQueue;
  LMonitor: TPerformanceMonitor;
  LStartTime: QWord;
  LValue: Integer;
  I: Integer;
const
  OPERATIONS = 500000; // 示例操作数
begin
  WriteLn('=== MPSC（Michael-Scott）队列性能监控演示 ===');
  
  LQueue := CreateIntMPSCQueue;
  LMonitor := TPerformanceMonitor.Create;
  try
    LMonitor.Enable;
    WriteLn('开始监控 MPSC（Michael-Scott）队列性能...');
    WriteLn('执行', OPERATIONS, '次入队和出队操作');
    WriteLn;
    
    // 入队操作监控
    WriteLn('入队阶段:');
    LStartTime := GetTickCount64;
    for I := 1 to OPERATIONS do
    begin
      LQueue.Enqueue(I);
      LMonitor.RecordOperation(True); // MPSC（Michael-Scott）队列入队总是成功
      
      if I mod 50000 = 0 then
        Write('.');
    end;
    WriteLn;
    WriteLn('入队完成，耗时: ', GetTickCount64 - LStartTime, ' ms');
    WriteLn;
    
    // 出队操作监控
    WriteLn('出队阶段:');
    LStartTime := GetTickCount64;
    for I := 1 to OPERATIONS do
    begin
      LMonitor.RecordOperation(LQueue.Dequeue(LValue));
      
      if I mod 50000 = 0 then
        Write('.');
    end;
    WriteLn;
    WriteLn('出队完成，耗时: ', GetTickCount64 - LStartTime, ' ms');
    WriteLn;
    
    // 输出性能报告
    WriteLn(LMonitor.GenerateReport);
    
  finally
    LQueue.Free;
    LMonitor.Free;
  end;
  WriteLn;
end;

{**
 * 演示预分配MPMC队列的性能监控
 *}
procedure DemoPreAllocMPMCQueueMonitoring;
type
  TIntQueue = specialize TPreAllocMPMCQueue<Integer>;
var
  LQueue: TIntQueue;
  LMonitor: TPerformanceMonitor;
  LStartTime: QWord;
  LValue: Integer;
  I: Integer;
const
  OPERATIONS = 500000;
begin
  WriteLn('=== 预分配MPMC队列性能监控演示 ===');
  
  LQueue := TIntQueue.Create(OPERATIONS);
  LMonitor := TPerformanceMonitor.Create;
  try
    LMonitor.Enable;
    WriteLn('开始监控预分配MPMC队列性能...');
    WriteLn('执行', OPERATIONS, '次入队和出队操作');
    WriteLn;
    
    // 入队操作监控
    WriteLn('入队阶段:');
    LStartTime := GetTickCount64;
    for I := 1 to OPERATIONS do
    begin
      LMonitor.RecordOperation(LQueue.Enqueue(I));
      
      if I mod 50000 = 0 then
        Write('.');
    end;
    WriteLn;
    WriteLn('入队完成，耗时: ', GetTickCount64 - LStartTime, ' ms');
    WriteLn;
    
    // 出队操作监控
    WriteLn('出队阶段:');
    LStartTime := GetTickCount64;
    for I := 1 to OPERATIONS do
    begin
      LMonitor.RecordOperation(LQueue.Dequeue(LValue));
      
      if I mod 50000 = 0 then
        Write('.');
    end;
    WriteLn;
    WriteLn('出队完成，耗时: ', GetTickCount64 - LStartTime, ' ms');
    WriteLn;
    
    // 输出性能报告
    WriteLn(LMonitor.GenerateReport);
    
  finally
    LQueue.Free;
    LMonitor.Free;
  end;
  WriteLn;
end;

{**
 * 性能对比分析
 *}
procedure PerformanceComparison;
type
  TSPSCQueue = TIntegerSPSCQueue;
  TMSQueue = TIntMPSCQueue;
  TMPMCQueue = TIntMPMCQueue;
var
  LSPSCQueue: TSPSCQueue;
  LMSQueue: TMSQueue;
  LMPMCQueue: TMPMCQueue;
  LStartTime, LEndTime: QWord;
  LValue: Integer;
  I: Integer;
const
  OPERATIONS = 200000; // 统一的操作数
begin
  WriteLn('=== 性能对比分析 ===');
  WriteLn('统一执行', OPERATIONS, '次操作进行对比');
  WriteLn;
  
  // SPSC队列
  WriteLn('测试SPSC队列...');
  LSPSCQueue := CreateIntSPSCQueue(OPERATIONS);
  try
    LStartTime := GetTickCount64;
    for I := 1 to OPERATIONS do
      LSPSCQueue.Enqueue(I);
    for I := 1 to OPERATIONS do
      LSPSCQueue.Dequeue(LValue);
    LEndTime := GetTickCount64;
    WriteLn('SPSC队列: ', LEndTime - LStartTime, ' ms');
    if (LEndTime - LStartTime) > 0 then
      WriteLn('吞吐量: ', (OPERATIONS * 2 * 1000) div (LEndTime - LStartTime), ' ops/sec');
  finally
    LSPSCQueue.Free;
  end;
  
  // Michael-Scott队列
  WriteLn('测试 MPSC（Michael-Scott）队列...');
  LMSQueue := CreateIntMSQueue;
  try
    LStartTime := GetTickCount64;
    for I := 1 to OPERATIONS do
      LMSQueue.Enqueue(I);
    for I := 1 to OPERATIONS do
      LMSQueue.Dequeue(LValue);
    LEndTime := GetTickCount64;
    WriteLn('MPSC（Michael-Scott）队列: ', LEndTime - LStartTime, ' ms');
    if (LEndTime - LStartTime) > 0 then
      WriteLn('吞吐量: ', (OPERATIONS * 2 * 1000) div (LEndTime - LStartTime), ' ops/sec');
  finally
    LMSQueue.Free;
  end;
  
  // 预分配MPMC队列
  WriteLn('测试预分配MPMC队列...');
  LMPMCQueue := CreateIntMPMCQueue(OPERATIONS);
  try
    LStartTime := GetTickCount64;
    for I := 1 to OPERATIONS do
      LMPMCQueue.Enqueue(I);
    for I := 1 to OPERATIONS do
      LMPMCQueue.Dequeue(LValue);
    LEndTime := GetTickCount64;
    WriteLn('预分配MPMC队列: ', LEndTime - LStartTime, ' ms');
    if (LEndTime - LStartTime) > 0 then
      WriteLn('吞吐量: ', (OPERATIONS * 2 * 1000) div (LEndTime - LStartTime), ' ops/sec');
  finally
    LMPMCQueue.Free;
  end;
  
  WriteLn('✅ 性能对比完成！');
  WriteLn;
end;

{**
 * 主程序
 *}
begin
  WriteLn('无锁数据结构性能监控演示');
  WriteLn('基于学术级性能监控框架');
  WriteLn('============================');
  WriteLn;
  
  try
    DemoSPSCQueueMonitoring;
    DemoMichaelScottQueueMonitoring;
    DemoPreAllocMPMCQueueMonitoring;
    PerformanceComparison;
    
    WriteLn('🎉 性能监控演示完成！');
    WriteLn;
    WriteLn('📊 监控要点:');
    WriteLn('- 总操作数: 记录所有操作的数量');
    WriteLn('- 成功/失败率: 监控操作的成功率');
    WriteLn('- 吞吐量: 每秒操作数 (ops/sec)');
    WriteLn('- 平均时间: 每次操作的平均耗时');
    WriteLn('- 监控时长: 整个测试的持续时间');
    WriteLn;
    WriteLn('🚀 性能优化建议:');
    WriteLn('- SPSC队列适合单生产者单消费者场景');
    WriteLn('- MPSC（Michael-Scott）队列适合多生产者-单消费者或多消费者场景');
    WriteLn('- 预分配版本提供ABA安全保证');
    WriteLn('- 根据实际需求选择合适的数据结构');
    
  except
    on E: Exception do
    begin
      WriteLn('演示过程中发生异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
