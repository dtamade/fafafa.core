program example_task_scheduler;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.priorityqueue;

type
  TTask = record
    Name: string;
    Priority: Integer; // 优先级（数字越小越优先）
    Deadline: TDateTime;
  end;

function CompareTaskPriority(const aLeft, aRight: TTask; aData: Pointer): SizeInt;
begin
  // 先按优先级排序，再按截止时间
  if aLeft.Priority < aRight.Priority then
    Result := -1
  else if aLeft.Priority > aRight.Priority then
    Result := 1
  else if aLeft.Deadline < aRight.Deadline then
    Result := -1
  else if aLeft.Deadline > aRight.Deadline then
    Result := 1
  else
    Result := 0;
end;

function MakeTask(const aName: string; aPriority: Integer; aDeadlineHours: Integer): TTask;
begin
  Result.Name := aName;
  Result.Priority := aPriority;
  Result.Deadline := Now + (aDeadlineHours / 24);
end;

procedure PrintTask(const aTask: TTask);
begin
  WriteLn(Format('  [P%d] %s (截止: %s)', [
    aTask.Priority,
    aTask.Name,
    FormatDateTime('hh:nn', aTask.Deadline)
  ]));
end;

var
  LScheduler: specialize TPriorityQueue<TTask>;
  LTask: TTask;
  i: Integer;
begin
  WriteLn('=== 任务调度器示例（优先级队列）===');
  WriteLn;
  
  LScheduler := specialize TPriorityQueue<TTask>.Create(@CompareTaskPriority);
  try
    // 场景1：添加不同优先级的任务
    WriteLn('--- 场景1：添加任务 ---');
    LScheduler.Push(MakeTask('编写文档', 3, 8));
    LScheduler.Push(MakeTask('修复严重Bug', 1, 2));
    LScheduler.Push(MakeTask('代码审查', 2, 4));
    LScheduler.Push(MakeTask('重构代码', 3, 12));
    LScheduler.Push(MakeTask('处理客户投诉', 1, 1));
    WriteLn('已添加 ', LScheduler.GetCount, ' 个任务');
    WriteLn;
    
    // 场景2：按优先级执行任务
    WriteLn('--- 场景2：按优先级执行任务 ---');
    i := 1;
    while LScheduler.GetCount > 0 do
    begin
      LTask := LScheduler.Pop;
      WriteLn(Format('执行任务 #%d:', [i]));
      PrintTask(LTask);
      WriteLn;
      Inc(i);
    end;
    
    // 场景3：动态任务插入
    WriteLn('--- 场景3：动态插入紧急任务 ---');
    LScheduler.Push(MakeTask('常规开发', 3, 8));
    LScheduler.Push(MakeTask('测试', 3, 6));
    WriteLn('当前队列: ', LScheduler.GetCount, ' 个任务');
    
    // 插入紧急任务
    LScheduler.Push(MakeTask('生产环境宕机！', 0, 0));
    WriteLn('插入紧急任务后，下一个执行的任务:');
    LTask := LScheduler.Peek;
    PrintTask(LTask);
    WriteLn;
    
    WriteLn('=== 示例完成 ===');
  finally
    LScheduler.Free;
  end;
end.

