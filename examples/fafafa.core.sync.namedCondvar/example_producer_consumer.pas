program example_producer_consumer;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes,
  fafafa.core.sync.namedCondvar, fafafa.core.sync.namedMutex;

const
  BUFFER_SIZE = 10;
  SHARED_BUFFER_NAME = 'ProducerConsumerBuffer';
  SHARED_MUTEX_NAME = 'ProducerConsumerMutex';
  SHARED_NOT_EMPTY_NAME = 'ProducerConsumerNotEmpty';
  SHARED_NOT_FULL_NAME = 'ProducerConsumerNotFull';

type
  // 共享缓冲区结构（通过文件模拟）
  TSharedBuffer = record
    Items: array[0..BUFFER_SIZE-1] of Integer;
    Count: Integer;
    Head: Integer;
    Tail: Integer;
  end;

var
  GMutex: INamedMutex;
  GNotEmpty: INamedConditionVariable;  // 缓冲区非空条件
  GNotFull: INamedConditionVariable;   // 缓冲区非满条件

procedure WriteSharedBuffer(const ABuffer: TSharedBuffer);
var
  LFile: File of TSharedBuffer;
begin
  AssignFile(LFile, SHARED_BUFFER_NAME + '.dat');
  Rewrite(LFile);
  try
    Write(LFile, ABuffer);
  finally
    CloseFile(LFile);
  end;
end;

function ReadSharedBuffer: TSharedBuffer;
var
  LFile: File of TSharedBuffer;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  if FileExists(SHARED_BUFFER_NAME + '.dat') then
  begin
    AssignFile(LFile, SHARED_BUFFER_NAME + '.dat');
    Reset(LFile);
    try
      if not EOF(LFile) then
        Read(LFile, Result);
    finally
      CloseFile(LFile);
    end;
  end;
end;

procedure ProducerDemo;
var
  LBuffer: TSharedBuffer;
  LGuard: INamedMutexGuard;
  LProcessId: string;
  i: Integer;
begin
  LProcessId := 'Producer_' + IntToStr(GetProcessID);
  WriteLn('=== 生产者示例 (', LProcessId, ') ===');
  
  for i := 1 to 20 do
  begin
    LGuard := GMutex.Lock;
    try
      // 读取当前缓冲区状态
      LBuffer := ReadSharedBuffer;
      
      // 等待缓冲区不满
      while LBuffer.Count >= BUFFER_SIZE do
      begin
        WriteLn('[', LProcessId, '] 缓冲区已满，等待消费者...');
        GNotFull.Wait(GMutex, 5000); // 等待最多5秒
        LBuffer := ReadSharedBuffer;
      end;
      
      // 生产一个项目
      LBuffer.Items[LBuffer.Tail] := i * 100 + GetProcessID mod 100;
      LBuffer.Tail := (LBuffer.Tail + 1) mod BUFFER_SIZE;
      Inc(LBuffer.Count);
      
      WriteLn('[', LProcessId, '] 生产项目: ', LBuffer.Items[(LBuffer.Tail - 1 + BUFFER_SIZE) mod BUFFER_SIZE], 
              ' (缓冲区: ', LBuffer.Count, '/', BUFFER_SIZE, ')');
      
      // 保存缓冲区状态
      WriteSharedBuffer(LBuffer);
      
      // 通知消费者有新项目
      GNotEmpty.Signal;
      
    finally
      LGuard := nil;
    end;
    
    // 生产间隔
    Sleep(200 + Random(300));
  end;
  
  WriteLn('[', LProcessId, '] 生产完成');
end;

procedure ConsumerDemo;
var
  LBuffer: TSharedBuffer;
  LGuard: INamedMutexGuard;
  LProcessId: string;
  LItem: Integer;
  i: Integer;
begin
  LProcessId := 'Consumer_' + IntToStr(GetProcessID);
  WriteLn('=== 消费者示例 (', LProcessId, ') ===');
  
  for i := 1 to 15 do
  begin
    LGuard := GMutex.Lock;
    try
      // 读取当前缓冲区状态
      LBuffer := ReadSharedBuffer;
      
      // 等待缓冲区非空
      while LBuffer.Count <= 0 do
      begin
        WriteLn('[', LProcessId, '] 缓冲区为空，等待生产者...');
        GNotEmpty.Wait(GMutex, 5000); // 等待最多5秒
        LBuffer := ReadSharedBuffer;
      end;
      
      // 消费一个项目
      LItem := LBuffer.Items[LBuffer.Head];
      LBuffer.Head := (LBuffer.Head + 1) mod BUFFER_SIZE;
      Dec(LBuffer.Count);
      
      WriteLn('[', LProcessId, '] 消费项目: ', LItem, 
              ' (缓冲区: ', LBuffer.Count, '/', BUFFER_SIZE, ')');
      
      // 保存缓冲区状态
      WriteSharedBuffer(LBuffer);
      
      // 通知生产者有空间
      GNotFull.Signal;
      
    finally
      LGuard := nil;
    end;
    
    // 消费间隔
    Sleep(300 + Random(400));
  end;
  
  WriteLn('[', LProcessId, '] 消费完成');
end;

procedure ShowUsageInstructions;
begin
  WriteLn('跨进程生产者-消费者示例');
  WriteLn('========================');
  WriteLn;
  WriteLn('使用说明:');
  WriteLn('1. 在多个终端中运行此程序');
  WriteLn('2. 程序会自动检测角色（生产者或消费者）');
  WriteLn('3. 观察跨进程的条件变量同步效果');
  WriteLn;
  WriteLn('当前进程ID: ', GetProcessID);
  WriteLn;
end;

function DetermineRole: string;
begin
  // 简单的角色分配：奇数进程ID为生产者，偶数为消费者
  if GetProcessID mod 2 = 1 then
    Result := 'producer'
  else
    Result := 'consumer';
end;

begin
  ShowUsageInstructions;
  
  try
    // 初始化同步对象
    GMutex := MakeNamedMutex(SHARED_MUTEX_NAME);
    GNotEmpty := MakeNamedConditionVariable(SHARED_NOT_EMPTY_NAME);
    GNotFull := MakeNamedConditionVariable(SHARED_NOT_FULL_NAME);
    
    WriteLn('同步对象初始化完成');
    WriteLn('互斥锁: ', GMutex.GetName);
    WriteLn('非空条件: ', GNotEmpty.GetName);
    WriteLn('非满条件: ', GNotFull.GetName);
    WriteLn;
    
    // 根据进程ID确定角色
    case DetermineRole of
      'producer': ProducerDemo;
      'consumer': ConsumerDemo;
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
