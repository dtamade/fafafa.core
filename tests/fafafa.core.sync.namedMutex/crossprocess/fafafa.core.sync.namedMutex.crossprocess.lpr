{$CODEPAGE UTF8}
program fafafa.core.sync.namedMutex.crossprocess;

{$mode objfpc}{$H+}
{$LINKLIB pthread}

uses
  SysUtils, Classes,
  fafafa.core.sync.namedMutex;

const
  MUTEX_NAME = 'fafafa_crossprocess_test';
  SHARED_FILE = '/tmp/fafafa_crossprocess_counter.txt';
  MAX_ITERATIONS = 1000;

var
  LMutex: INamedMutex;
  LProcessId: string;
  LCounter: Integer;
  LFile: TextFile;
  i: Integer;
  LGuard: INamedMutexGuard;

procedure WriteLog(const AMessage: string);
begin
  WriteLn(Format('[%s] %s', [LProcessId, AMessage]));
end;

function ReadCounter: Integer;
begin
  Result := 0;
  if FileExists(SHARED_FILE) then
  begin
    AssignFile(LFile, SHARED_FILE);
    Reset(LFile);
    try
      if not Eof(LFile) then
        ReadLn(LFile, Result);
    finally
      CloseFile(LFile);
    end;
  end;
end;

procedure WriteCounter(AValue: Integer);
begin
  AssignFile(LFile, SHARED_FILE);
  Rewrite(LFile);
  try
    WriteLn(LFile, AValue);
  finally
    CloseFile(LFile);
  end;
end;

begin
  // 获取进程标识
  LProcessId := Format('PID_%d', [GetProcessID]);
  
  WriteLog('启动跨进程测试');
  
  try
    // 创建命名互斥锁
    LMutex := CreateNamedMutex(MUTEX_NAME);
    WriteLog('成功创建命名互斥锁');
    
    // 执行多次锁定和计数操作
    for i := 1 to MAX_ITERATIONS do
    begin
      // 使用 RAII 模式获取锁
      LGuard := LMutex.Lock;
      try
        // 读取当前计数
        LCounter := ReadCounter;
        
        // 增加计数
        Inc(LCounter);
        
        // 写回计数
        WriteCounter(LCounter);
        
        if i mod 100 = 0 then
          WriteLog(Format('完成 %d 次迭代，当前计数: %d', [i, LCounter]));
          
      finally
        LGuard := nil; // 显式释放守卫
      end;
      
      // 短暂休眠模拟实际工作
      Sleep(1);
    end;
    
    WriteLog(Format('测试完成，最终计数: %d', [ReadCounter]));
    
  except
    on E: Exception do
    begin
      WriteLog(Format('错误: %s', [E.Message]));
      ExitCode := 1;
    end;
  end;
end.
