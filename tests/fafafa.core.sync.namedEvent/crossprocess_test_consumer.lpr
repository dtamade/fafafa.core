{$CODEPAGE UTF8}
program crossprocess_test_consumer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.namedEvent;

const
  EVENT_NAME = 'CrossProcessTest_Event';
  MAX_WAIT_TIME = 30000; // 30秒超时

var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
  LCount: Integer;
  LStartTime: TDateTime;
begin
  WriteLn('[Consumer] 开始跨进程事件测试...');
  
  try
    // 打开已存在的命名事件
    WriteLn('[Consumer] 正在连接到事件: ', EVENT_NAME);
    LEvent := CreateManualResetNamedEvent(EVENT_NAME, False);
    WriteLn('[Consumer] 连接到事件成功: ', EVENT_NAME);
    
    LCount := 0;
    LStartTime := Now;
    
    while True do
    begin
      // 检查超时
      if (Now - LStartTime) * 24 * 60 * 60 * 1000 > MAX_WAIT_TIME then
      begin
        WriteLn('[Consumer] 超时退出');
        ExitCode := 2;
        Exit;
      end;
      
      // 等待事件触发
      LGuard := LEvent.TryWaitFor(1000);
      if Assigned(LGuard) then
      begin
        Inc(LCount);
        WriteLn('[Consumer] 第 ', LCount, ' 次检测到事件触发');
        
        // 如果收到足够多的事件，认为测试成功
        if LCount >= 11 then // 10次循环 + 1次结束信号
        begin
          WriteLn('[Consumer] 测试成功完成，共收到 ', LCount, ' 次事件');
          ExitCode := 0;
          Exit;
        end;
        
        LGuard := nil;
      end
      else
      begin
        // 超时，继续等待
        Write('.');
      end;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('[Consumer] 错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
