{$CODEPAGE UTF8}
program example_crossprocess_producer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.namedEvent;

const
  EVENT_NAME = 'CrossProcessDemo';
  DATA_READY_EVENT = 'DataReady';
  PROCESSING_DONE_EVENT = 'ProcessingDone';

procedure SimulateDataProduction;
var
  LDataReadyEvent: INamedEvent;
  LProcessingDoneEvent: INamedEvent;
  LGuard: INamedEventGuard;
  I: Integer;
begin
  WriteLn('=== 跨进程生产者示例 ===');
  WriteLn('进程ID: ', GetProcessID);
  WriteLn;
  
  try
    // 创建事件（如果消费者已经创建，则连接到现有事件）
    LDataReadyEvent := MakeNamedEvent(DATA_READY_EVENT);
    LProcessingDoneEvent := MakeNamedEvent(PROCESSING_DONE_EVENT);
    
    WriteLn('✓ 连接到命名事件:');
    WriteLn('  数据就绪事件: ', LDataReadyEvent.GetName);
    WriteLn('  处理完成事件: ', LProcessingDoneEvent.GetName);
    WriteLn;
    
    // 模拟生产数据
    for I := 1 to 5 do
    begin
      WriteLn('📦 生产数据包 #', I);
      
      // 模拟数据生产时间
      Sleep(500 + Random(1000));
      
      // 通知数据就绪
      LDataReadyEvent.SetEvent;
      WriteLn('✅ 数据包 #', I, ' 已就绪，通知消费者');
      
      // 等待消费者处理完成
      WriteLn('⏳ 等待消费者处理数据包 #', I, '...');
      LGuard := LProcessingDoneEvent.TryWaitFor(10000); // 10秒超时
      
      if Assigned(LGuard) then
      begin
        WriteLn('✅ 数据包 #', I, ' 处理完成');
        LGuard := nil;
        
        // 重置处理完成事件（为下一轮做准备）
        LProcessingDoneEvent.ResetEvent;
      end
      else
      begin
        WriteLn('⚠️  数据包 #', I, ' 处理超时');
        Break;
      end;
      
      WriteLn;
    end;
    
    WriteLn('🎉 所有数据生产完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 生产者出错: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end;

procedure ShowUsage;
begin
  WriteLn('跨进程命名事件生产者示例');
  WriteLn('==========================');
  WriteLn;
  WriteLn('使用方法:');
  WriteLn('1. 先启动消费者: ./example_crossprocess_consumer');
  WriteLn('2. 再启动生产者: ./example_crossprocess_producer');
  WriteLn;
  WriteLn('或者同时启动多个生产者和消费者测试并发场景');
  WriteLn;
end;

begin
  ShowUsage;
  
  // 初始化随机数种子
  Randomize;
  
  SimulateDataProduction;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
