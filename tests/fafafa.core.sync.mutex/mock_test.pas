program mock_test;

{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex;

procedure AssertTrue(const Message: string; Condition: Boolean);
begin
  Write('Assert: ', Message, ' ... ');
  if Condition then
    WriteLn('PASS')
  else
  begin
    WriteLn('FAIL');
    raise Exception.Create('Assertion failed: ' + Message);
  end;
end;

procedure AssertFalse(const Message: string; Condition: Boolean);
begin
  AssertTrue(Message, not Condition);
end;

procedure Test_TryAcquire_WithTimeout;
var
  FMutex: IMutex;
begin
  WriteLn('Running Test_TryAcquire_WithTimeout');
  WriteLn('====================================');
  
  // 创建新的 mutex
  FMutex := MakeMutex;
  WriteLn('Mutex created');
  
  // 测试零超时（立即返回）
  WriteLn;
  WriteLn('Step 1: Testing TryAcquire(0)...');
  AssertTrue('零超时 TryAcquire 应该成功', FMutex.TryAcquire(0));
  
  try
    // 测试重入检测
    WriteLn;
    WriteLn('Step 2: Testing reentrant TryAcquire(100)...');
    WriteLn('  Current state: Lock is held by current thread');
    WriteLn('  Calling TryAcquire(100)...');
    
    // 这里是第144行的测试
    AssertFalse('重入 TryAcquire 应该失败', FMutex.TryAcquire(100));
    
  finally
    FMutex.Release;
    WriteLn('Lock released');
  end;
  
  // 测试正常超时获取
  WriteLn;
  WriteLn('Step 3: Testing normal TryAcquire(1000)...');
  AssertTrue('正常超时 TryAcquire 应该成功', FMutex.TryAcquire(1000));
  FMutex.Release;
  
  WriteLn;
  WriteLn('Test completed successfully!');
end;

begin
  try
    Test_TryAcquire_WithTimeout;
  except
    on E: Exception do
    begin
      WriteLn;
      WriteLn('TEST FAILED: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
