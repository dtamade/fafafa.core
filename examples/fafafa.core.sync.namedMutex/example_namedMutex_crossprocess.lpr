program example_namedMutex_crossprocess;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.namedMutex;

const
  MUTEX_NAME = 'CrossProcessDemo';
  SHARED_RESOURCE_FILE = 'shared_counter.txt';

procedure ShowUsage;
begin
  WriteLn('跨进程命名互斥锁演示');
  WriteLn('用法:');
  WriteLn('  ', ExtractFileName(ParamStr(0)), ' [worker|reader] [count]');
  WriteLn('');
  WriteLn('参数:');
  WriteLn('  worker  - 工作进程模式，递增共享计数器');
  WriteLn('  reader  - 读取进程模式，读取共享计数器');
  WriteLn('  count   - 工作次数（仅对 worker 模式有效，默认 10）');
  WriteLn('');
  WriteLn('示例:');
  WriteLn('  启动多个工作进程:');
  WriteLn('    ', ExtractFileName(ParamStr(0)), ' worker 5');
  WriteLn('    ', ExtractFileName(ParamStr(0)), ' worker 3');
  WriteLn('');
  WriteLn('  启动读取进程:');
  WriteLn('    ', ExtractFileName(ParamStr(0)), ' reader');
end;

function ReadSharedCounter: Integer;
var
  F: TextFile;
begin
  Result := 0;
  if FileExists(SHARED_RESOURCE_FILE) then
  begin
    try
      AssignFile(F, SHARED_RESOURCE_FILE);
      Reset(F);
      try
        ReadLn(F, Result);
      finally
        CloseFile(F);
      end;
    except
      Result := 0;
    end;
  end;
end;

procedure WriteSharedCounter(AValue: Integer);
var
  F: TextFile;
begin
  AssignFile(F, SHARED_RESOURCE_FILE);
  Rewrite(F);
  try
    WriteLn(F, AValue);
  finally
    CloseFile(F);
  end;
end;

procedure WorkerMode(ACount: Integer);
var
  LMutex: INamedMutex;
  i, LCurrentValue: Integer;
  LProcessId: string;
begin
  LProcessId := IntToStr(GetProcessID);
  WriteLn('[Worker ', LProcessId, '] 启动，将执行 ', ACount, ' 次操作');
  
  // 创建命名互斥锁
  LMutex := CreateNamedMutex(MUTEX_NAME);
  WriteLn('[Worker ', LProcessId, '] 连接到互斥锁: ', LMutex.GetName);
  WriteLn('[Worker ', LProcessId, '] 是否为创建者: ', BoolToStr(LMutex.IsOwner, '是', '否'));
  
  for i := 1 to ACount do
  begin
    WriteLn('[Worker ', LProcessId, '] 操作 ', i, '/', ACount, ' - 等待互斥锁...');
    
    // 获取互斥锁保护共享资源
    with LMutex.LockNamed do
    begin
      WriteLn('[Worker ', LProcessId, '] 获取互斥锁成功，访问共享资源');
      
      // 读取当前值
      LCurrentValue := ReadSharedCounter;
      WriteLn('[Worker ', LProcessId, '] 当前计数器值: ', LCurrentValue);
      
      // 模拟一些处理时间
      Sleep(100 + Random(200));
      
      // 递增并写回
      Inc(LCurrentValue);
      WriteSharedCounter(LCurrentValue);
      WriteLn('[Worker ', LProcessId, '] 更新计数器值: ', LCurrentValue);
      
      WriteLn('[Worker ', LProcessId, '] 释放互斥锁');
    end;
    
    // 在操作之间稍作休息
    Sleep(50 + Random(100));
  end;
  
  WriteLn('[Worker ', LProcessId, '] 完成所有操作');
end;

procedure ReaderMode;
var
  LMutex: INamedMutex;
  LValue: Integer;
  LProcessId: string;
begin
  LProcessId := IntToStr(GetProcessID);
  WriteLn('[Reader ', LProcessId, '] 启动，将持续读取共享计数器');
  WriteLn('[Reader ', LProcessId, '] 按 Ctrl+C 退出');
  
  // 创建命名互斥锁
  LMutex := CreateNamedMutex(MUTEX_NAME);
  WriteLn('[Reader ', LProcessId, '] 连接到互斥锁: ', LMutex.GetName);
  
  while True do
  begin
    try
      // 尝试获取互斥锁（带超时）
      if Assigned(LMutex.TryLockForNamed(1000)) then
      begin
        try
          LValue := ReadSharedCounter;
          WriteLn('[Reader ', LProcessId, '] ', FormatDateTime('hh:nn:ss', Now), 
                  ' - 当前计数器值: ', LValue);
        except
          // Handle exception in critical section
        end;
        // Guard auto-released
      end
      else
        WriteLn('[Reader ', LProcessId, '] ', FormatDateTime('hh:nn:ss', Now), 
                ' - 无法获取互斥锁（其他进程正在使用）');
      
      Sleep(500);
    except
      on E: Exception do
      begin
        WriteLn('[Reader ', LProcessId, '] 错误: ', E.Message);
        Break;
      end;
    end;
  end;
end;

var
  LMode: string;
  LCount: Integer;

begin
  try
    Randomize;
    
    if ParamCount < 1 then
    begin
      ShowUsage;
      Exit;
    end;
    
    LMode := LowerCase(ParamStr(1));
    LCount := 10;
    
    if ParamCount >= 2 then
    begin
      try
        LCount := StrToInt(ParamStr(2));
      except
        WriteLn('警告: 无效的计数参数，使用默认值 10');
      end;
    end;
    
    WriteLn('跨进程命名互斥锁演示');
    WriteLn('====================');
    WriteLn('互斥锁名称: ', MUTEX_NAME);
    WriteLn('共享资源文件: ', SHARED_RESOURCE_FILE);
    WriteLn('进程ID: ', GetProcessID);
    WriteLn('');
    
    case LMode of
      'worker':
        WorkerMode(LCount);
      'reader':
        ReaderMode;
    else
      WriteLn('错误: 无效的模式 "', ParamStr(1), '"');
      WriteLn('');
      ShowUsage;
      ExitCode := 1;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
