{$CODEPAGE UTF8}
program crossprocess_test_producer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.namedEvent;

const
  EVENT_NAME = 'CrossProcessTest_Event';
  ITERATIONS = 10;

var
  LEvent: INamedEvent;
  I: Integer;
begin
  WriteLn('[Producer] 开始跨进程事件测试...');
  
  try
    // 创建命名事件
    LEvent := CreateManualResetNamedEvent(EVENT_NAME, False);
    WriteLn('[Producer] 创建事件成功: ', EVENT_NAME);

    // 等待更长时间让消费者准备好
    WriteLn('[Producer] 等待消费者准备...');
    Sleep(3000);
    
    for I := 1 to ITERATIONS do
    begin
      WriteLn('[Producer] 第 ', I, ' 次触发事件');
      
      // 触发事件
      LEvent.SetEvent;
      
      // 等待一下
      Sleep(500);
      
      // 重置事件
      LEvent.ResetEvent;
      WriteLn('[Producer] 第 ', I, ' 次重置事件');
      
      Sleep(500);
    end;
    
    // 最后触发一次表示结束
    WriteLn('[Producer] 发送结束信号');
    LEvent.SetEvent;
    
    WriteLn('[Producer] 测试完成');
    
  except
    on E: Exception do
    begin
      WriteLn('[Producer] 错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
