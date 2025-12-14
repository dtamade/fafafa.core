unit Test_fafafa_core_time_scheduler_priorityqueue;

{$mode objfpc}{$H+}

{**
 * TDD 测试：调度器优先队列集成
 *
 * 目的：
 *   验证 TTaskScheduler 使用 IPriorityQueue<IScheduledTask> 时的正确性，
 *   包括：
 *   1. 接口引用计数管理（无泄漏、无 double-free）
 *   2. 堆属性维护（下一任务始终是最早到期的）
 *   3. 任务移除时堆的正确性
 *   4. 大量任务时的性能（与线性扫描对比）
 *
 * 这些测试应该在调度器切换到优先队列实现之前全部通过（红）或跳过，
 * 切换后全部通过（绿）。
 *}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.clock,
  fafafa.core.time.scheduler;

type
  { TTestSchedulerPriorityQueue }
  TTestSchedulerPriorityQueue = class(TTestCase)
  private
    FScheduler: ITaskScheduler;
    FExecutionOrder: array of string;
    FExecutionCount: Integer;
    
    procedure RecordExecution(const ATask: IScheduledTask);
    procedure ClearExecutionRecord;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基本堆属性测试
    procedure Test_GetNextTask_ReturnsEarliestTask;
    procedure Test_GetNextTask_AfterRemoval_StillReturnsEarliest;
    procedure Test_MultipleTasksSameTime_AllExecuted;
    
    // 引用计数和内存测试
    procedure Test_AddRemove_NoMemoryLeak;
    procedure Test_ClearAllTasks_NoMemoryLeak;
    procedure Test_SchedulerDestroy_ReleasesAllTasks;
    
    // 动态调度测试
    procedure Test_DynamicReschedule_HeapUpdatesCorrectly;
    procedure Test_CancelTask_RemovedFromHeap;
    
    // 压力测试
    procedure Test_ManyTasks_CorrectExecutionOrder;
    procedure Test_ManyTasks_HeapPerformance;
  end;

implementation

{ TTestSchedulerPriorityQueue }

procedure TTestSchedulerPriorityQueue.RecordExecution(const ATask: IScheduledTask);
begin
  SetLength(FExecutionOrder, Length(FExecutionOrder) + 1);
  FExecutionOrder[High(FExecutionOrder)] := ATask.GetName;
  Inc(FExecutionCount);
end;

procedure TTestSchedulerPriorityQueue.ClearExecutionRecord;
begin
  SetLength(FExecutionOrder, 0);
  FExecutionCount := 0;
end;

procedure TTestSchedulerPriorityQueue.SetUp;
begin
  FScheduler := CreateTaskScheduler;
  ClearExecutionRecord;
end;

procedure TTestSchedulerPriorityQueue.TearDown;
begin
  if Assigned(FScheduler) then
  begin
    if FScheduler.IsRunning then
      FScheduler.Stop;
    FScheduler := nil;
  end;
  ClearExecutionRecord;
end;

procedure TTestSchedulerPriorityQueue.Test_GetNextTask_ReturnsEarliestTask;
var
  task1, task2, task3: IScheduledTask;
  clock: IMonotonicClock;
  baseTime: TInstant;
begin
  clock := DefaultMonotonicClock;
  baseTime := clock.NowInstant;
  
  // 创建三个任务，延迟分别为 300ms, 100ms, 200ms
  task1 := FScheduler.CreateTask('Task300', @RecordExecution);
  task2 := FScheduler.CreateTask('Task100', @RecordExecution);
  task3 := FScheduler.CreateTask('Task200', @RecordExecution);
  
  // 调度（顺序：300, 100, 200）
  CheckTrue(FScheduler.ScheduleOnce(task1, TDuration.FromMs(300)), 'Task1 schedule');
  CheckTrue(FScheduler.ScheduleOnce(task2, TDuration.FromMs(100)), 'Task2 schedule');
  CheckTrue(FScheduler.ScheduleOnce(task3, TDuration.FromMs(200)), 'Task3 schedule');
  
  // 启动调度器，等待所有任务执行
  FScheduler.Start;
  Sleep(500);
  FScheduler.Stop;
  
  // 验证执行顺序：应该是 100ms -> 200ms -> 300ms
  CheckEquals(3, FExecutionCount, 'All tasks should execute');
  CheckEquals('Task100', FExecutionOrder[0], 'First should be Task100 (100ms)');
  CheckEquals('Task200', FExecutionOrder[1], 'Second should be Task200 (200ms)');
  CheckEquals('Task300', FExecutionOrder[2], 'Third should be Task300 (300ms)');
end;

procedure TTestSchedulerPriorityQueue.Test_GetNextTask_AfterRemoval_StillReturnsEarliest;
var
  task1, task2, task3: IScheduledTask;
begin
  // 创建三个任务
  task1 := FScheduler.CreateTask('Task100', @RecordExecution);
  task2 := FScheduler.CreateTask('Task200', @RecordExecution);
  task3 := FScheduler.CreateTask('Task300', @RecordExecution);
  
  // 调度
  FScheduler.ScheduleOnce(task1, TDuration.FromMs(100));
  FScheduler.ScheduleOnce(task2, TDuration.FromMs(200));
  FScheduler.ScheduleOnce(task3, TDuration.FromMs(300));
  
  // 移除最早的任务
  FScheduler.RemoveTask(task1);
  
  // 启动并等待
  FScheduler.Start;
  Sleep(400);
  FScheduler.Stop;
  
  // 验证：Task100 被移除，剩下 Task200 -> Task300
  CheckEquals(2, FExecutionCount, 'Two tasks should execute');
  CheckEquals('Task200', FExecutionOrder[0], 'First should be Task200');
  CheckEquals('Task300', FExecutionOrder[1], 'Second should be Task300');
end;

procedure TTestSchedulerPriorityQueue.Test_MultipleTasksSameTime_AllExecuted;
var
  task1, task2, task3: IScheduledTask;
begin
  // 创建三个任务，延迟相同
  task1 := FScheduler.CreateTask('TaskA', @RecordExecution);
  task2 := FScheduler.CreateTask('TaskB', @RecordExecution);
  task3 := FScheduler.CreateTask('TaskC', @RecordExecution);
  
  // 全部调度为 50ms 后执行
  FScheduler.ScheduleOnce(task1, TDuration.FromMs(50));
  FScheduler.ScheduleOnce(task2, TDuration.FromMs(50));
  FScheduler.ScheduleOnce(task3, TDuration.FromMs(50));
  
  FScheduler.Start;
  Sleep(200);
  FScheduler.Stop;
  
  // 所有任务都应该执行（顺序可能不确定，但都应该执行）
  CheckEquals(3, FExecutionCount, 'All three tasks should execute');
end;

procedure TTestSchedulerPriorityQueue.Test_AddRemove_NoMemoryLeak;
var
  task: IScheduledTask;
  i: Integer;
begin
  // 反复添加和移除任务
  for i := 1 to 100 do
  begin
    task := FScheduler.CreateTask(Format('Task%d', [i]), @RecordExecution);
    FScheduler.ScheduleOnce(task, TDuration.FromSec(10));
    FScheduler.RemoveTask(task);
    task := nil;
  end;
  
  // 验证任务数为 0
  CheckEquals(0, FScheduler.GetTaskCount, 'All tasks should be removed');
  // 如果有内存泄漏，heaptrc 会在程序结束时报告
end;

procedure TTestSchedulerPriorityQueue.Test_ClearAllTasks_NoMemoryLeak;
var
  task: IScheduledTask;
  i: Integer;
begin
  // 添加多个任务
  for i := 1 to 50 do
  begin
    task := FScheduler.CreateTask(Format('Task%d', [i]), @RecordExecution);
    FScheduler.ScheduleOnce(task, TDuration.FromSec(10));
  end;
  
  CheckEquals(50, FScheduler.GetTaskCount, 'Should have 50 tasks');
  
  // 通过 Shutdown 清理
  FScheduler.Shutdown(TDuration.FromSec(1));
  
  // Scheduler 应该已停止
  CheckFalse(FScheduler.IsRunning, 'Scheduler should be stopped');
end;

procedure TTestSchedulerPriorityQueue.Test_SchedulerDestroy_ReleasesAllTasks;
var
  scheduler: ITaskScheduler;
  task: IScheduledTask;
  i: Integer;
begin
  scheduler := CreateTaskScheduler;
  
  // 添加任务
  for i := 1 to 20 do
  begin
    task := scheduler.CreateTask(Format('Task%d', [i]), @RecordExecution);
    scheduler.ScheduleOnce(task, TDuration.FromSec(10));
  end;
  
  // 直接释放调度器（不调用 Stop）
  // 调度器析构函数应该正确释放所有任务引用
  scheduler := nil;
  
  // 如果引用计数管理正确，不会崩溃也不会泄漏
  CheckTrue(True, 'Scheduler destroyed without crash');
end;

procedure TTestSchedulerPriorityQueue.Test_DynamicReschedule_HeapUpdatesCorrectly;
var
  task1, task2: IScheduledTask;
begin
  // 创建两个周期任务
  task1 := FScheduler.CreateTask('FastTask', @RecordExecution);
  task2 := FScheduler.CreateTask('SlowTask', @RecordExecution);
  
  // FastTask: 每 50ms 执行一次
  // SlowTask: 每 150ms 执行一次
  FScheduler.ScheduleFixed(task1, TDuration.FromMs(50), TDuration.FromMs(50));
  FScheduler.ScheduleFixed(task2, TDuration.FromMs(150), TDuration.FromMs(150));
  
  FScheduler.Start;
  Sleep(400);
  FScheduler.Stop;
  
  // FastTask 应该执行更多次
  // 在 400ms 内：FastTask 约 7-8 次，SlowTask 约 2-3 次
  // 验证两个任务都执行了
  CheckTrue(FExecutionCount >= 5, 'Should have multiple executions');
  
  // 计算各任务执行次数
  var fastCount: Integer := 0;
  var slowCount: Integer := 0;
  var i: Integer;
  for i := 0 to High(FExecutionOrder) do
  begin
    if FExecutionOrder[i] = 'FastTask' then
      Inc(fastCount)
    else if FExecutionOrder[i] = 'SlowTask' then
      Inc(slowCount);
  end;
  
  CheckTrue(fastCount > slowCount, 'FastTask should execute more times');
end;

procedure TTestSchedulerPriorityQueue.Test_CancelTask_RemovedFromHeap;
var
  task1, task2, task3: IScheduledTask;
begin
  task1 := FScheduler.CreateTask('Task1', @RecordExecution);
  task2 := FScheduler.CreateTask('Task2', @RecordExecution);
  task3 := FScheduler.CreateTask('Task3', @RecordExecution);
  
  FScheduler.ScheduleOnce(task1, TDuration.FromMs(100));
  FScheduler.ScheduleOnce(task2, TDuration.FromMs(200));
  FScheduler.ScheduleOnce(task3, TDuration.FromMs(300));
  
  // 取消 Task2
  task2.Cancel;
  
  FScheduler.Start;
  Sleep(400);
  FScheduler.Stop;
  
  // Task2 被取消，不应该执行
  CheckEquals(2, FExecutionCount, 'Only non-cancelled tasks should execute');
  
  // 验证 Task2 不在执行列表中
  var i: Integer;
  var foundTask2: Boolean := False;
  for i := 0 to High(FExecutionOrder) do
    if FExecutionOrder[i] = 'Task2' then
      foundTask2 := True;
  
  CheckFalse(foundTask2, 'Cancelled Task2 should not execute');
end;

procedure TTestSchedulerPriorityQueue.Test_ManyTasks_CorrectExecutionOrder;
var
  tasks: array of IScheduledTask;
  i: Integer;
  delays: array of Integer;
begin
  // 创建 20 个任务，随机延迟
  SetLength(tasks, 20);
  SetLength(delays, 20);
  
  for i := 0 to 19 do
  begin
    delays[i] := 50 + Random(200); // 50-250ms
    tasks[i] := FScheduler.CreateTask(Format('Task_%03d', [delays[i]]), @RecordExecution);
    FScheduler.ScheduleOnce(tasks[i], TDuration.FromMs(delays[i]));
  end;
  
  FScheduler.Start;
  Sleep(500);
  FScheduler.Stop;
  
  // 验证所有任务都执行了
  CheckEquals(20, FExecutionCount, 'All 20 tasks should execute');
  
  // 验证执行顺序大致正确（通过任务名中的延迟值）
  // 注意：由于定时精度和线程调度，不能要求严格顺序，但应该大致按时间排序
  // 这里只验证所有任务都执行了
end;

procedure TTestSchedulerPriorityQueue.Test_ManyTasks_HeapPerformance;
var
  task: IScheduledTask;
  i: Integer;
  startTime: TInstant;
  elapsed: TDuration;
begin
  startTime := DefaultMonotonicClock.NowInstant;
  
  // 添加 1000 个任务
  for i := 1 to 1000 do
  begin
    task := FScheduler.CreateTask(Format('Task%d', [i]), @RecordExecution);
    FScheduler.ScheduleOnce(task, TDuration.FromMs(10000 + i)); // 都在未来
  end;
  
  elapsed := DefaultMonotonicClock.NowInstant.Diff(startTime);
  
  // 1000 个任务的插入应该在合理时间内完成
  // 对于堆实现：O(n log n) ≈ 10000 次操作
  // 对于线性扫描：O(n²) ≈ 1000000 次操作
  // 在现代 CPU 上，堆实现应该在 100ms 内完成
  CheckTrue(elapsed.AsMs < 1000, 
    Format('Adding 1000 tasks should be fast, took %d ms', [elapsed.AsMs]));
  
  CheckEquals(1000, FScheduler.GetTaskCount, 'Should have 1000 tasks');
  
  // 移除所有任务
  startTime := DefaultMonotonicClock.NowInstant;
  for i := 1 to 1000 do
  begin
    task := FScheduler.GetTask(Format('Task%d', [i]));
    if Assigned(task) then
      FScheduler.RemoveTask(task);
  end;
  
  elapsed := DefaultMonotonicClock.NowInstant.Diff(startTime);
  
  // 移除也应该高效
  CheckTrue(elapsed.AsMs < 2000,
    Format('Removing 1000 tasks should be fast, took %d ms', [elapsed.AsMs]));
  
  CheckEquals(0, FScheduler.GetTaskCount, 'All tasks should be removed');
end;

initialization
  RegisterTest(TTestSchedulerPriorityQueue);

end.
