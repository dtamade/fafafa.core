{$CODEPAGE UTF8}
program crossprocess_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes, Process,
  fafafa.core.sync.namedEvent;

type
  TTestMode = (tmParent, tmChild, tmProducer, tmConsumer);

var
  GTestMode: TTestMode = tmParent;
  GTestName: string = '';
  GProcessCount: Integer = 2;
  GDuration: Integer = 5; // 减少到5秒以适应演示

procedure ShowUsage;
begin
  WriteLn('Cross-process Named Event Test Tool');
  WriteLn('===================================');
  WriteLn;
  WriteLn('Usage:');
  WriteLn('  ', ExtractFileName(ParamStr(0)), ' [options]');
  WriteLn;
  WriteLn('Options:');
  WriteLn('  --mode=parent|child|producer|consumer  Test mode');
  WriteLn('  --test=<name>                          Test name');
  WriteLn('  --count=<n>                            Child process count (default: 2)');
  WriteLn('  --duration=<n>                         Test duration in seconds (default: 5)');
  WriteLn('  --help                                 Show this help');
end;

procedure ParseCommandLine;
var
  I: Integer;
  LParam, LKey, LValue: string;
  LPos: Integer;
begin
  for I := 1 to ParamCount do
  begin
    LParam := ParamStr(I);
    
    if (LParam = '--help') or (LParam = '-h') then
    begin
      ShowUsage;
      Halt(0);
    end;
    
    LPos := Pos('=', LParam);
    if LPos > 0 then
    begin
      LKey := Copy(LParam, 1, LPos - 1);
      LValue := Copy(LParam, LPos + 1, Length(LParam));
      
      if LKey = '--mode' then
      begin
        if LValue = 'parent' then GTestMode := tmParent
        else if LValue = 'child' then GTestMode := tmChild
        else if LValue = 'producer' then GTestMode := tmProducer
        else if LValue = 'consumer' then GTestMode := tmConsumer
        else
        begin
          WriteLn('Error: Invalid mode "', LValue, '"');
          Halt(1);
        end;
      end
      else if LKey = '--test' then
        GTestName := LValue
      else if LKey = '--count' then
        GProcessCount := StrToIntDef(LValue, 2)
      else if LKey = '--duration' then
        GDuration := StrToIntDef(LValue, 5);
    end;
  end;
end;

function RunChildProcess(const AMode, ATestName: string; ADuration: Integer): Boolean;
var
  LProcess: TProcess;
  LExitCode: Integer;
begin
  Result := False;
  LProcess := TProcess.Create(nil);
  try
    LProcess.Executable := ParamStr(0);
    LProcess.Parameters.Add('--mode=' + AMode);
    LProcess.Parameters.Add('--test=' + ATestName);
    LProcess.Parameters.Add('--duration=' + IntToStr(ADuration));
    
    LProcess.Options := [poWaitOnExit];
    
    WriteLn('Starting child process: ', AMode, ' (test: ', ATestName, ')');
    LProcess.Execute;

    LExitCode := LProcess.ExitStatus;
    Result := (LExitCode = 0);

    if Result then
      WriteLn('✓ Child process ', AMode, ' completed successfully')
    else
      WriteLn('❌ Child process ', AMode, ' failed, exit code: ', LExitCode);
      
  finally
    LProcess.Free;
  end;
end;

procedure RunParentTest;
var
  I: Integer;
  LSuccess: Boolean;
  LTestName: string;
begin
  WriteLn('=== Cross-Process Test Suite ===');
  WriteLn('Process ID: ', GetProcessID);
  WriteLn;

  // Test 1: Basic multi-process event synchronization
  LTestName := 'BasicSync_' + IntToStr(GetProcessID);
  WriteLn('Test 1: Basic multi-process event synchronization');
  WriteLn('Test name: ', LTestName);
  
  LSuccess := True;
  for I := 1 to GProcessCount do
  begin
    if not RunChildProcess('child', LTestName, GDuration) then
      LSuccess := False;
  end;
  
  if LSuccess then
    WriteLn('✅ Test 1 passed')
  else
    WriteLn('❌ Test 1 failed');

  WriteLn;
  WriteLn('🎉 Cross-process test completed');
end;

procedure RunChildTest;
var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
  LStartTime: TDateTime;
  LOperations: Integer;
begin
  WriteLn('=== Child Process Test ===');
  WriteLn('Process ID: ', GetProcessID);
  WriteLn('Test name: ', GTestName);
  WriteLn('Duration: ', GDuration, ' seconds');
  WriteLn;
  
  try
    // Create or connect to named event
    LEvent := MakeManualResetNamedEvent(GTestName, False);
    WriteLn('✓ Connected to event: ', LEvent.GetName);
    
    LOperations := 0;
    LStartTime := Now;
    
    // 运行测试循环
    while (Now - LStartTime) * 24 * 60 * 60 < GDuration do
    begin
      // 尝试等待事件
      LGuard := LEvent.TryWaitFor(100);
      if Assigned(LGuard) then
      begin
        Inc(LOperations);
        LGuard := nil;
      end;
      
      // Occasionally trigger event
      if Random(100) < 10 then
      begin
        LEvent.SetEvent;
        Sleep(10);
        LEvent.ResetEvent;
      end;

      Sleep(1);
    end;

    WriteLn('✓ Child process completed, operations: ', LOperations);
    
  except
    on E: Exception do
    begin
      WriteLn('❌ Child process error: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end;

procedure RunProducerTest;
var
  LDataEvent, LAckEvent: INamedEvent;
  I: Integer;
begin
  WriteLn('=== 生产者进程 ===');
  WriteLn('进程ID: ', GetProcessID);
  WriteLn('测试名称: ', GTestName);
  WriteLn;
  
  try
    // 创建数据就绪和确认事件
    LDataEvent := MakeManualResetNamedEvent(GTestName + '_Data', False);
    LAckEvent := MakeManualResetNamedEvent(GTestName + '_Ack', False);
    
    WriteLn('✓ 创建事件:');
    WriteLn('  数据事件: ', LDataEvent.GetName);
    WriteLn('  确认事件: ', LAckEvent.GetName);
    WriteLn;
    
    // 生产数据
    for I := 1 to 3 do // 减少到3个包
    begin
      WriteLn('📦 生产数据包 #', I);
      
      // 触发数据就绪事件
      LDataEvent.SetEvent;
      WriteLn('✅ 数据包 #', I, ' 已就绪');
      
      // 等待消费者确认
      WriteLn('⏳ 等待消费者确认...');
      if Assigned(LAckEvent.TryWaitFor(3000)) then
      begin
        WriteLn('✅ 收到确认');
        LAckEvent.ResetEvent;
        LDataEvent.ResetEvent;
      end
      else
      begin
        WriteLn('⚠️ 等待确认超时');
      end;
      
      Sleep(200);
      WriteLn;
    end;
    
    WriteLn('🎉 生产者完成');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 生产者出错: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end;

procedure RunConsumerTest;
var
  LDataEvent, LAckEvent: INamedEvent;
  LGuard: INamedEventGuard;
  LPacketCount: Integer;
begin
  WriteLn('=== 消费者进程 ===');
  WriteLn('进程ID: ', GetProcessID);
  WriteLn('测试名称: ', GTestName);
  WriteLn;
  
  try
    // 连接到数据就绪和确认事件
    LDataEvent := MakeManualResetNamedEvent(GTestName + '_Data', False);
    LAckEvent := MakeManualResetNamedEvent(GTestName + '_Ack', False);
    
    WriteLn('✓ 连接事件:');
    WriteLn('  数据事件: ', LDataEvent.GetName);
    WriteLn('  确认事件: ', LAckEvent.GetName);
    WriteLn;
    
    LPacketCount := 0;
    WriteLn('⏳ 等待数据...');
    
    // 等待数据
    while LPacketCount < 3 do // 减少到3个包
    begin
      LGuard := LDataEvent.TryWaitFor(5000);
      if Assigned(LGuard) then
      begin
        Inc(LPacketCount);
        WriteLn('📨 收到数据包 #', LPacketCount);
        LGuard := nil;
        
        // 模拟处理时间
        Sleep(100);
        
        // 发送确认
        LAckEvent.SetEvent;
        WriteLn('✅ 发送确认 #', LPacketCount);
      end
      else
      begin
        WriteLn('⏰ 等待数据超时');
        Break;
      end;
    end;
    
    WriteLn('🎉 消费者完成，处理了 ', LPacketCount, ' 个数据包');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 消费者出错: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end;

begin
  // 初始化随机数种子
  Randomize;
  
  // 解析命令行参数
  ParseCommandLine;
  
  // 根据模式运行相应测试
  case GTestMode of
    tmParent: RunParentTest;
    tmChild: RunChildTest;
    tmProducer: RunProducerTest;
    tmConsumer: RunConsumerTest;
  end;
end.
