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
  GDuration: Integer = 10; // 秒

procedure ShowUsage;
begin
  WriteLn('跨进程命名事件测试工具');
  WriteLn('========================');
  WriteLn;
  WriteLn('用法:');
  WriteLn('  ', ExtractFileName(ParamStr(0)), ' [选项]');
  WriteLn;
  WriteLn('选项:');
  WriteLn('  --mode=parent|child|producer|consumer  测试模式');
  WriteLn('  --test=<name>                          测试名称');
  WriteLn('  --count=<n>                            子进程数量 (默认: 2)');
  WriteLn('  --duration=<n>                         测试持续时间秒数 (默认: 10)');
  WriteLn('  --help                                 显示此帮助');
  WriteLn;
  WriteLn('测试模式:');
  WriteLn('  parent    - 父进程模式，启动多个子进程');
  WriteLn('  child     - 子进程模式，由父进程启动');
  WriteLn('  producer  - 生产者模式，发送数据');
  WriteLn('  consumer  - 消费者模式，接收数据');
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
          WriteLn('错误：无效的模式 "', LValue, '"');
          Halt(1);
        end;
      end
      else if LKey = '--test' then
        GTestName := LValue
      else if LKey = '--count' then
        GProcessCount := StrToIntDef(LValue, 2)
      else if LKey = '--duration' then
        GDuration := StrToIntDef(LValue, 10)
      else
      begin
        WriteLn('错误：未知选项 "', LKey, '"');
        Halt(1);
      end;
    end
    else
    begin
      WriteLn('错误：无效参数 "', LParam, '"');
      Halt(1);
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
    
    WriteLn('启动子进程: ', AMode, ' (测试: ', ATestName, ')');
    LProcess.Execute;
    
    LExitCode := LProcess.ExitStatus;
    Result := (LExitCode = 0);
    
    if Result then
      WriteLn('✓ 子进程 ', AMode, ' 成功完成')
    else
      WriteLn('❌ 子进程 ', AMode, ' 失败，退出码: ', LExitCode);
      
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
  WriteLn('=== 跨进程测试套件 ===');
  WriteLn('进程ID: ', GetProcessID);
  WriteLn;
  
  // 测试1：基本的多进程事件同步
  LTestName := 'BasicSync_' + IntToStr(GetProcessID);
  WriteLn('测试1: 基本多进程事件同步');
  WriteLn('测试名称: ', LTestName);
  
  LSuccess := True;
  for I := 1 to GProcessCount do
  begin
    if not RunChildProcess('child', LTestName, GDuration) then
      LSuccess := False;
  end;
  
  if LSuccess then
    WriteLn('✅ 测试1通过')
  else
    WriteLn('❌ 测试1失败');
  
  WriteLn;
  
  // 测试2：生产者-消费者模式
  LTestName := 'ProdCons_' + IntToStr(GetProcessID);
  WriteLn('测试2: 生产者-消费者模式');
  WriteLn('测试名称: ', LTestName);
  
  // 启动消费者
  if RunChildProcess('consumer', LTestName, GDuration) and
     RunChildProcess('producer', LTestName, GDuration) then
    WriteLn('✅ 测试2通过')
  else
    WriteLn('❌ 测试2失败');
    
  WriteLn;
  WriteLn('🎉 跨进程测试完成');
end;

procedure RunChildTest;
var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
  LStartTime: TDateTime;
  LOperations: Integer;
begin
  WriteLn('=== 子进程测试 ===');
  WriteLn('进程ID: ', GetProcessID);
  WriteLn('测试名称: ', GTestName);
  WriteLn('持续时间: ', GDuration, ' 秒');
  WriteLn;
  
  try
    // 创建或连接到命名事件
    LEvent := CreateManualResetNamedEvent(GTestName, False);
    WriteLn('✓ 连接到事件: ', LEvent.GetName);
    
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
      
      // 偶尔触发事件
      if Random(100) < 10 then
      begin
        LEvent.SetEvent;
        Sleep(10);
        LEvent.ResetEvent;
      end;
      
      Sleep(1);
    end;
    
    WriteLn('✓ 子进程完成，操作次数: ', LOperations);
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 子进程出错: ', E.ClassName, ': ', E.Message);
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
    LDataEvent := CreateManualResetNamedEvent(GTestName + '_Data', False);
    LAckEvent := CreateManualResetNamedEvent(GTestName + '_Ack', False);
    
    WriteLn('✓ 创建事件:');
    WriteLn('  数据事件: ', LDataEvent.GetName);
    WriteLn('  确认事件: ', LAckEvent.GetName);
    WriteLn;
    
    // 生产数据
    for I := 1 to 5 do
    begin
      WriteLn('📦 生产数据包 #', I);
      
      // 触发数据就绪事件
      LDataEvent.SetEvent;
      WriteLn('✅ 数据包 #', I, ' 已就绪');
      
      // 等待消费者确认
      WriteLn('⏳ 等待消费者确认...');
      if Assigned(LAckEvent.TryWaitFor(5000)) then
      begin
        WriteLn('✅ 收到确认');
        LAckEvent.ResetEvent;
        LDataEvent.ResetEvent;
      end
      else
      begin
        WriteLn('⚠️ 等待确认超时');
      end;
      
      Sleep(500);
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
    LDataEvent := CreateManualResetNamedEvent(GTestName + '_Data', False);
    LAckEvent := CreateManualResetNamedEvent(GTestName + '_Ack', False);
    
    WriteLn('✓ 连接事件:');
    WriteLn('  数据事件: ', LDataEvent.GetName);
    WriteLn('  确认事件: ', LAckEvent.GetName);
    WriteLn;
    
    LPacketCount := 0;
    WriteLn('⏳ 等待数据...');
    
    // 等待数据
    while LPacketCount < 5 do
    begin
      LGuard := LDataEvent.TryWaitFor(10000);
      if Assigned(LGuard) then
      begin
        Inc(LPacketCount);
        WriteLn('📨 收到数据包 #', LPacketCount);
        LGuard := nil;
        
        // 模拟处理时间
        Sleep(200);
        
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
