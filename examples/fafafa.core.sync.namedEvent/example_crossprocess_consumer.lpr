{$CODEPAGE UTF8}
program example_crossprocess_consumer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.namedEvent;

const
  DATA_READY_EVENT = 'DataReady';
  PROCESSING_DONE_EVENT = 'ProcessingDone';

procedure SimulateDataConsumption;
var
  LDataReadyEvent: INamedEvent;
  LProcessingDoneEvent: INamedEvent;
  LGuard: INamedEventGuard;
  LPacketCount: Integer;
begin
  WriteLn('=== 跨进程消费者示例 ===');
  WriteLn('进程ID: ', GetProcessID);
  WriteLn;
  
  try
    // 创建手动重置事件用于数据就绪通知
    LDataReadyEvent := MakeManualResetNamedEvent(DATA_READY_EVENT, False);
    // 创建手动重置事件用于处理完成通知
    LProcessingDoneEvent := MakeManualResetNamedEvent(PROCESSING_DONE_EVENT, False);
    
    WriteLn('✓ 创建命名事件:');
    WriteLn('  数据就绪事件: ', LDataReadyEvent.GetName, ' (', 
            IfThen(LDataReadyEvent.IsManualReset, '手动重置', '自动重置'), ')');
    WriteLn('  处理完成事件: ', LProcessingDoneEvent.GetName, ' (', 
            IfThen(LProcessingDoneEvent.IsManualReset, '手动重置', '自动重置'), ')');
    WriteLn;
    
    LPacketCount := 0;
    
    WriteLn('⏳ 等待生产者数据...');
    
    // 持续等待数据
    while True do
    begin
      // 等待数据就绪事件
      LGuard := LDataReadyEvent.TryWaitFor(30000); // 30秒超时
      
      if Assigned(LGuard) then
      begin
        Inc(LPacketCount);
        WriteLn('📨 收到数据包 #', LPacketCount);
        LGuard := nil;
        
        // 重置数据就绪事件
        LDataReadyEvent.ResetEvent;
        
        // 模拟数据处理时间
        WriteLn('⚙️  处理数据包 #', LPacketCount, '...');
        Sleep(200 + Random(800));
        
        // 通知处理完成
        LProcessingDoneEvent.SetEvent;
        WriteLn('✅ 数据包 #', LPacketCount, ' 处理完成，通知生产者');
        WriteLn;
        
        // 如果处理了5个包，退出演示
        if LPacketCount >= 5 then
        begin
          WriteLn('🎉 演示完成，已处理 ', LPacketCount, ' 个数据包');
          Break;
        end;
      end
      else
      begin
        WriteLn('⏰ 等待数据超时，可能生产者已退出');
        Break;
      end;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 消费者出错: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end;

procedure ShowUsage;
begin
  WriteLn('跨进程命名事件消费者示例');
  WriteLn('==========================');
  WriteLn;
  WriteLn('使用方法:');
  WriteLn('1. 先启动消费者: ./example_crossprocess_consumer');
  WriteLn('2. 再启动生产者: ./example_crossprocess_producer');
  WriteLn;
  WriteLn('消费者将等待生产者的数据，并在处理完成后通知生产者');
  WriteLn;
end;

begin
  ShowUsage;
  
  // 初始化随机数种子
  Randomize;
  
  SimulateDataConsumption;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
