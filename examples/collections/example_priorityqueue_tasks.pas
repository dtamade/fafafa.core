program example_priorityqueue_tasks;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.collections.priorityqueue;

type
  TTask = record
    Priority: Integer;  // 越小优先级越高
    Name: string;
  end;

// 比较器函数：按优先级排序
function CompareTaskPriority(const A, B: TTask): Integer;
begin
  Result := A.Priority - B.Priority;  // 升序，小的优先
end;

var
  LTaskQueue: specialize TPriorityQueue<TTask>;
  LTask: TTask;
  
begin
  WriteLn('========================================');
  WriteLn('PriorityQueue 任务调度示例');
  WriteLn('========================================');
  WriteLn;

  // 初始化优先队列
  LTaskQueue.Initialize(@CompareTaskPriority);
  
  // 添加任务（乱序）
  WriteLn('添加任务：');
  
  LTask.Priority := 3; LTask.Name := '发送邮件';
  LTaskQueue.Enqueue(LTask);
  WriteLn('  添加: [优先级 ', LTask.Priority, '] ', LTask.Name);
  
  LTask.Priority := 1; LTask.Name := '紧急修复Bug';
  LTaskQueue.Enqueue(LTask);
  WriteLn('  添加: [优先级 ', LTask.Priority, '] ', LTask.Name);
  
  LTask.Priority := 5; LTask.Name := '更新文档';
  LTaskQueue.Enqueue(LTask);
  WriteLn('  添加: [优先级 ', LTask.Priority, '] ', LTask.Name);
  
  LTask.Priority := 2; LTask.Name := '代码审查';
  LTaskQueue.Enqueue(LTask);
  WriteLn('  添加: [优先级 ', LTask.Priority, '] ', LTask.Name);
  
  LTask.Priority := 1; LTask.Name := '处理客户投诉';
  LTaskQueue.Enqueue(LTask);
  WriteLn('  添加: [优先级 ', LTask.Priority, '] ', LTask.Name);
  
  WriteLn;
  WriteLn('队列中有 ', LTaskQueue.Count, ' 个任务');
  WriteLn;
  
  // 按优先级顺序处理任务
  WriteLn('按优先级处理任务：');
  while LTaskQueue.Dequeue(LTask) do
  begin
    WriteLn('  处理: [优先级 ', LTask.Priority, '] ', LTask.Name);
  end;
  
  WriteLn;
  WriteLn('所有任务已完成！');
  WriteLn('队列现在为空：', LTaskQueue.IsEmpty);
end.

