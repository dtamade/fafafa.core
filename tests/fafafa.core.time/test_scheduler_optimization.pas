program test_scheduler_optimization;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.clock,
  fafafa.core.time.scheduler;

procedure TestCallback(const ATask: IScheduledTask);
begin
  WriteLn('Task executed: ', ATask.GetName);
end;

var
  scheduler: ITaskScheduler;
  task1, task2, task3: IScheduledTask;
  i: Integer;
  startTime, endTime: TInstant;
  
begin
  WriteLn('=== 测试调度器优先队列优化 ===');
  WriteLn;
  
  // 创建调度器
  scheduler := CreateTaskScheduler;
  scheduler.Start;
  
  WriteLn('1. 测试基本任务添加和获取');
  task1 := scheduler.CreateTask('Task1', @TestCallback);
  task2 := scheduler.CreateTask('Task2', @TestCallback);
  task3 := scheduler.CreateTask('Task3', @TestCallback);
  
  scheduler.ScheduleOnce(task1, TDuration.FromSec(5));
  scheduler.ScheduleOnce(task2, TDuration.FromSec(3));
  scheduler.ScheduleOnce(task3, TDuration.FromSec(1));
  
  WriteLn('添加了 3 个任务');
  WriteLn('任务总数: ', scheduler.GetTaskCount);
  WriteLn;
  
  WriteLn('2. 测试 GetTask (O(1) 哈希查找)');
  startTime := DefaultMonotonicClock.NowInstant;
  for i := 1 to 10000 do
  begin
    task1 := scheduler.GetTask(task1.GetId);
  end;
  endTime := DefaultMonotonicClock.NowInstant;
  WriteLn('GetTask 10000 次耗时: ', endTime.Diff(startTime).ToMs, ' ms');
  WriteLn;
  
  WriteLn('3. 测试大批量任务添加');
  startTime := DefaultMonotonicClock.NowInstant;
  for i := 1 to 1000 do
  begin
    scheduler.ScheduleOnce(
      scheduler.CreateTask('BulkTask' + IntToStr(i), @TestCallback),
      TDuration.FromSec(i)
    );
  end;
  endTime := DefaultMonotonicClock.NowInstant;
  WriteLn('添加 1000 个任务耗时: ', endTime.Diff(startTime).ToMs, ' ms');
  WriteLn('任务总数: ', scheduler.GetTaskCount);
  WriteLn;
  
  WriteLn('4. 测试任务移除');
  startTime := DefaultMonotonicClock.NowInstant;
  scheduler.RemoveTask(task2);
  endTime := DefaultMonotonicClock.NowInstant;
  WriteLn('RemoveTask 耗时: ', endTime.Diff(startTime).ToMs, ' ms');
  WriteLn('剩余任务数: ', scheduler.GetTaskCount);
  WriteLn;
  
  WriteLn('5. 测试完成');
  scheduler.Stop;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
