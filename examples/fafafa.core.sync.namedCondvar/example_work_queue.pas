program example_work_queue;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes,
  fafafa.core.sync.namedCondvar, fafafa.core.sync.namedMutex;

const
  QUEUE_SIZE = 20;
  SHARED_QUEUE_NAME = 'WorkQueue';
  SHARED_MUTEX_NAME = 'WorkQueueMutex';
  SHARED_CONDITION_NAME = 'WorkQueueCondition';

type
  // 工作项结构
  TWorkItem = record
    Id: Integer;
    Data: string[50];
    Priority: Integer;
    CreatedTime: QWord;
  end;

  // 共享工作队列结构
  TSharedWorkQueue = record
    Items: array[0..QUEUE_SIZE-1] of TWorkItem;
    Count: Integer;
    Head: Integer;
    Tail: Integer;
    NextId: Integer;
  end;

var
  GMutex: INamedMutex;
  GCondition: INamedConditionVariable;

procedure WriteSharedQueue(const AQueue: TSharedWorkQueue);
var
  LFile: File of TSharedWorkQueue;
begin
  AssignFile(LFile, SHARED_QUEUE_NAME + '.dat');
  Rewrite(LFile);
  try
    Write(LFile, AQueue);
  finally
    CloseFile(LFile);
  end;
end;

function ReadSharedQueue: TSharedWorkQueue;
var
  LFile: File of TSharedWorkQueue;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.NextId := 1;
  
  if FileExists(SHARED_QUEUE_NAME + '.dat') then
  begin
    AssignFile(LFile, SHARED_QUEUE_NAME + '.dat');
    Reset(LFile);
    try
      if not EOF(LFile) then
        Read(LFile, Result);
    finally
      CloseFile(LFile);
    end;
  end;
end;

procedure MasterDemo;
var
  LQueue: TSharedWorkQueue;
  LGuard: INamedMutexGuard;
  LWorkItem: TWorkItem;
  LProcessId: string;
  i: Integer;
begin
  LProcessId := 'Master_' + IntToStr(GetProcessID);
  WriteLn('=== 主进程示例 (', LProcessId, ') ===');
  WriteLn('负责分发工作任务');
  WriteLn;
  
  for i := 1 to 30 do
  begin
    LGuard := GMutex.Lock;
    try
      LQueue := ReadSharedQueue;
      
      // 等待队列有空间
      while LQueue.Count >= QUEUE_SIZE do
      begin
        WriteLn('[', LProcessId, '] 队列已满，等待工作进程处理...');
        GCondition.Wait(GMutex, 3000);
        LQueue := ReadSharedQueue;
      end;
      
      // 创建新的工作项
      LWorkItem.Id := LQueue.NextId;
      Inc(LQueue.NextId);
      LWorkItem.Data := 'Task_' + IntToStr(LWorkItem.Id) + '_Data';
      LWorkItem.Priority := Random(10) + 1;
      LWorkItem.CreatedTime := GetTickCount64;
      
      // 添加到队列
      LQueue.Items[LQueue.Tail] := LWorkItem;
      LQueue.Tail := (LQueue.Tail + 1) mod QUEUE_SIZE;
      Inc(LQueue.Count);
      
      WriteLn('[', LProcessId, '] 添加任务: ID=', LWorkItem.Id, 
              ', Priority=', LWorkItem.Priority, 
              ', Queue=', LQueue.Count, '/', QUEUE_SIZE);
      
      WriteSharedQueue(LQueue);
      
      // 通知工作进程有新任务
      GCondition.Broadcast; // 唤醒所有等待的工作进程
      
    finally
      LGuard := nil;
    end;
    
    Sleep(100 + Random(200));
  end;
  
  WriteLn('[', LProcessId, '] 任务分发完成');
end;

procedure WorkerDemo;
var
  LQueue: TSharedWorkQueue;
  LGuard: INamedMutexGuard;
  LWorkItem: TWorkItem;
  LProcessId: string;
  LProcessedCount: Integer;
begin
  LProcessId := 'Worker_' + IntToStr(GetProcessID);
  WriteLn('=== 工作进程示例 (', LProcessId, ') ===');
  WriteLn('负责处理工作任务');
  WriteLn;
  
  LProcessedCount := 0;
  
  while LProcessedCount < 10 do // 每个工作进程处理10个任务
  begin
    LGuard := GMutex.Lock;
    try
      LQueue := ReadSharedQueue;
      
      // 等待队列非空
      while LQueue.Count <= 0 do
      begin
        WriteLn('[', LProcessId, '] 队列为空，等待新任务...');
        if not GCondition.Wait(GMutex, 5000) then // 5秒超时
        begin
          WriteLn('[', LProcessId, '] 等待超时，退出');
          Exit;
        end;
        LQueue := ReadSharedQueue;
      end;
      
      // 从队列头部取出任务
      LWorkItem := LQueue.Items[LQueue.Head];
      LQueue.Head := (LQueue.Head + 1) mod QUEUE_SIZE;
      Dec(LQueue.Count);
      
      WriteLn('[', LProcessId, '] 获取任务: ID=', LWorkItem.Id, 
              ', Priority=', LWorkItem.Priority,
              ', Age=', GetTickCount64 - LWorkItem.CreatedTime, 'ms',
              ', Queue=', LQueue.Count, '/', QUEUE_SIZE);
      
      WriteSharedQueue(LQueue);
      
      // 通知主进程队列有空间
      GCondition.Signal;
      
    finally
      LGuard := nil;
    end;
    
    // 模拟任务处理时间（优先级越高处理越快）
    Sleep(1000 - LWorkItem.Priority * 80);
    
    WriteLn('[', LProcessId, '] 完成任务: ID=', LWorkItem.Id, 
            ', Data=', LWorkItem.Data);
    
    Inc(LProcessedCount);
  end;
  
  WriteLn('[', LProcessId, '] 工作完成，处理了 ', LProcessedCount, ' 个任务');
end;

procedure MonitorDemo;
var
  LQueue: TSharedWorkQueue;
  LGuard: INamedMutexGuard;
  LProcessId: string;
  LStats: TNamedConditionVariableStats;
  i: Integer;
begin
  LProcessId := 'Monitor_' + IntToStr(GetProcessID);
  WriteLn('=== 监控进程示例 (', LProcessId, ') ===');
  WriteLn('负责监控队列状态和统计信息');
  WriteLn;
  
  for i := 1 to 20 do
  begin
    LGuard := GMutex.Lock;
    try
      LQueue := ReadSharedQueue;
      
      WriteLn('[', LProcessId, '] 队列状态: ', LQueue.Count, '/', QUEUE_SIZE, 
              ', 下一个ID: ', LQueue.NextId);
      
      // 显示统计信息（如果启用）
      LStats := GCondition.GetStats;
      if LStats.WaitCount > 0 then
      begin
        WriteLn('[', LProcessId, '] 条件变量统计:');
        WriteLn('  等待次数: ', LStats.WaitCount);
        WriteLn('  信号次数: ', LStats.SignalCount);
        WriteLn('  广播次数: ', LStats.BroadcastCount);
        WriteLn('  当前等待者: ', LStats.CurrentWaiters);
      end;
      
    finally
      LGuard := nil;
    end;
    
    Sleep(2000); // 每2秒监控一次
  end;
  
  WriteLn('[', LProcessId, '] 监控完成');
end;

procedure ShowUsageInstructions;
begin
  WriteLn('跨进程工作队列示例');
  WriteLn('==================');
  WriteLn;
  WriteLn('使用说明:');
  WriteLn('1. 启动一个主进程（Master）负责分发任务');
  WriteLn('2. 启动多个工作进程（Worker）负责处理任务');
  WriteLn('3. 可选启动监控进程（Monitor）查看状态');
  WriteLn('4. 程序根据进程ID自动分配角色');
  WriteLn;
  WriteLn('角色分配规则:');
  WriteLn('- 进程ID末位 1-3: Master（主进程）');
  WriteLn('- 进程ID末位 4-8: Worker（工作进程）');
  WriteLn('- 进程ID末位 9-0: Monitor（监控进程）');
  WriteLn;
  WriteLn('当前进程ID: ', GetProcessID);
end;

function DetermineRole: string;
var
  LLastDigit: Integer;
begin
  LLastDigit := GetProcessID mod 10;
  case LLastDigit of
    1..3: Result := 'master';
    4..8: Result := 'worker';
    else Result := 'monitor';
  end;
end;

begin
  ShowUsageInstructions;
  
  try
    // 初始化同步对象（启用统计）
    GMutex := MakeNamedMutex(SHARED_MUTEX_NAME);
    GCondition := MakeNamedConditionVariableWithStats(SHARED_CONDITION_NAME);
    
    WriteLn;
    WriteLn('同步对象初始化完成');
    WriteLn('互斥锁: ', GMutex.GetName);
    WriteLn('条件变量: ', GCondition.GetName);
    WriteLn('分配角色: ', DetermineRole);
    WriteLn;
    
    // 根据进程ID确定角色并执行相应逻辑
    case DetermineRole of
      'master': MasterDemo;
      'worker': WorkerDemo;
      'monitor': MonitorDemo;
    end;
    
    WriteLn;
    WriteLn('示例执行完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
