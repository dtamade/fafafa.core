program crossprocess_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, Process,
  fafafa.core.sync.namedConditionVariable,
  fafafa.core.sync.namedMutex;

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

  LMutex := CreateNamedMutex(TEST_MUTEX_NAME);
  LCondVar := MakeNamedConditionVariable(TEST_CONDVAR_NAME);

  WriteLn('[Producer] 互斥锁句柄: ', IntToHex(PtrUInt(LMutex.GetHandle), 16));
  WriteLn('[Producer] 条件变量句柄: ', IntToHex(PtrUInt(LCondVar.GetHandle), 16));
  WriteLn('[Producer] 条件变量名称: ', LCondVar.GetName);
  WriteLn('[Producer] 是否为创建者: ', LCondVar.IsCreator);

  WriteLn('[Producer] 等待2秒后发送信号...');
  Sleep(2000);

  // 注意：对于条件变量的 Signal，我们不需要持有用户互斥锁
  // 这是因为我们修改了 Signal 实现，直接调用 pthread_cond_signal
  WriteLn('[Producer] 发送信号给消费者');
  LCondVar.Signal;
  WriteLn('[Producer] 信号已发送');

  WriteLn('[Producer] 生产者完成');
end;

procedure RunConsumer;
var
  LStartTime: QWord;
  LResult: Boolean;
begin
  WriteLn('[Consumer] 启动消费者进程');

  LMutex := CreateNamedMutex(TEST_MUTEX_NAME);
  LCondVar := MakeNamedConditionVariable(TEST_CONDVAR_NAME);

  WriteLn('[Consumer] 互斥锁句柄: ', IntToHex(PtrUInt(LMutex.GetHandle), 16));
  WriteLn('[Consumer] 条件变量句柄: ', IntToHex(PtrUInt(LCondVar.GetHandle), 16));
  WriteLn('[Consumer] 条件变量名称: ', LCondVar.GetName);
  WriteLn('[Consumer] 是否为创建者: ', LCondVar.IsCreator);

  LStartTime := GetTickCount64;

  // 使用传统的 Acquire/Release 方式，而不是 RAII 守卫
  // 这是因为 pthread_cond_wait 需要在持有锁的状态下调用，并且会自动释放和重新获取锁
  LMutex.Acquire;
  try
    WriteLn('[Consumer] 获取锁成功，开始等待生产者信号...');
    LResult := LCondVar.Wait(LMutex as ILock, 5000); // 5秒超时

    if LResult then
    begin
      WriteLn('[Consumer] ✓ 成功接收到信号，用时: ', GetTickCount64 - LStartTime, 'ms');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('[Consumer] ✗ 等待超时，未收到信号，用时: ', GetTickCount64 - LStartTime, 'ms');
      ExitCode := 1;
    end;
  finally
    LMutex.Release;
    WriteLn('[Consumer] 锁已释放');
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

      // 等待更长时间确保消费者完全启动并创建了共享对象
      WriteLn('等待消费者启动...');
      Sleep(1000);

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
