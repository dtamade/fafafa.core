program crossprocess_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, Process,
  fafafa.core.sync.namedCondvar,
  fafafa.core.sync.namedMutex,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex;

const
  TEST_CONDVAR_NAME = 'test_crossprocess_condvar';
  TEST_MUTEX_NAME = 'test_crossprocess_mutex';

var
  LCondVar: INamedConditionVariable;
  LMutex: INamedMutex;
  LGuard: INamedMutexGuard;
  LRole: string;

procedure RunProducer;
begin
  WriteLn('[Producer] 启动生产者进程');

  LMutex := Sync.MakeNamedMutex(TEST_MUTEX_NAME);
  LCondVar := MakeNamedConditionVariable(TEST_CONDVAR_NAME);

  WriteLn('[Producer] 等待2秒后发送信号...');
  Sleep(2000);

  LGuard := LMutex.Lock;
  try
    WriteLn('[Producer] 发送信号给消费者');
    LCondVar.Signal;
  finally
    LGuard := nil;
  end;

  WriteLn('[Producer] 生产者完成');
end;

procedure RunConsumer;
var
  LStartTime: QWord;
  LResult: Boolean;
begin
  WriteLn('[Consumer] 启动消费者进程');

  LMutex := Sync.MakeNamedMutex(TEST_MUTEX_NAME);
  LCondVar := MakeNamedConditionVariable(TEST_CONDVAR_NAME);

  LStartTime := GetTickCount64;

  LGuard := LMutex.Lock;
  try
    WriteLn('[Consumer] 等待生产者信号...');
    LResult := LCondVar.Wait(ILock(LMutex), 5000); // 使用 ILock 版本

    if LResult then
    begin
      WriteLn('[Consumer] ✓ 成功接收到信号，用时: ', GetTickCount64 - LStartTime, 'ms');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('[Consumer] ✗ 等待超时，未收到信号');
      ExitCode := 1;
    end;
  finally
    LGuard := nil;
  end;
end;

procedure RunTest;
var
  LProducerProcess: TProcess;
  LConsumerProcess: TProcess;
  LProducerResult, LConsumerResult: Integer;
begin
  WriteLn('=== 跨进程条件变量测试 ===');
  WriteLn('测试场景：生产者-消费者模式');
  WriteLn;
  
  // 创建生产者进程
  LProducerProcess := TProcess.Create(nil);
  try
    LProducerProcess.Executable := ParamStr(0);
    LProducerProcess.Parameters.Add('producer');
    LProducerProcess.Options := [poWaitOnExit];
    
    // 创建消费者进程
    LConsumerProcess := TProcess.Create(nil);
    try
      LConsumerProcess.Executable := ParamStr(0);
      LConsumerProcess.Parameters.Add('consumer');
      LConsumerProcess.Options := [poWaitOnExit];
      
      WriteLn('启动消费者进程...');
      LConsumerProcess.Execute;
      
      // 稍等一下确保消费者先启动
      Sleep(500);
      
      WriteLn('启动生产者进程...');
      LProducerProcess.Execute;
      
      // 等待两个进程完成
      LProducerResult := LProducerProcess.ExitStatus;
      LConsumerResult := LConsumerProcess.ExitStatus;
      
      WriteLn;
      WriteLn('测试结果:');
      WriteLn('  生产者退出码: ', LProducerResult);
      WriteLn('  消费者退出码: ', LConsumerResult);
      
      if (LProducerResult = 0) and (LConsumerResult = 0) then
      begin
        WriteLn('🎉 跨进程条件变量测试通过！');
        ExitCode := 0;
      end
      else
      begin
        WriteLn('❌ 跨进程条件变量测试失败！');
        ExitCode := 1;
      end;
      
    finally
      LConsumerProcess.Free;
    end;
  finally
    LProducerProcess.Free;
  end;
end;

begin
  try
    if ParamCount = 0 then
    begin
      RunTest;
    end
    else
    begin
      LRole := ParamStr(1);
      if LRole = 'producer' then
        RunProducer
      else if LRole = 'consumer' then
        RunConsumer
      else
      begin
        WriteLn('用法: ', ParamStr(0), ' [producer|consumer]');
        ExitCode := 1;
      end;
    end;
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
