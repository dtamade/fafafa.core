program test_scheduler_basic;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.clock,
  fafafa.core.time.scheduler;

var
  scheduler: ITaskScheduler;
  task1, task2: IScheduledTask;
  executedCount: Integer = 0;
  
procedure TestCallback(const ATask: IScheduledTask);
begin
  Inc(executedCount);
  WriteLn('Task executed: ', ATask.GetName, ', Count: ', executedCount);
end;

begin
  WriteLn('=== Scheduler Basic Test ===');
  WriteLn;
  
  // 创建调度器
  scheduler := CreateTaskScheduler;
  
  // 创建测试任务
  task1 := scheduler.CreateTask('Task1', @TestCallback);
  task2 := scheduler.CreateTask('Task2', @TestCallback);
  
  // 调度任务
  scheduler.ScheduleOnce(task1, TDuration.FromMs(100));
  scheduler.ScheduleOnce(task2, TDuration.FromMs(200));
  
  WriteLn('Scheduled 2 tasks');
  WriteLn('Task count: ', scheduler.GetTaskCount);
  WriteLn;
  
  // 启动调度器
  WriteLn('Starting scheduler...');
  scheduler.Start;
  
  // 等待任务执行
  Sleep(500);
  
  // 停止调度器
  WriteLn;
  WriteLn('Stopping scheduler...');
  scheduler.Stop;
  
  WriteLn;
  WriteLn('Final executed count: ', executedCount);
  WriteLn('Expected: 2');
  
  if executedCount = 2 then
    WriteLn('TEST PASSED')
  else
    WriteLn('TEST FAILED');
    
  WriteLn;
  WriteLn('=== Test Complete ===');
end.
