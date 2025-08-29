program simple_reentrant_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.mutex,
  fafafa.core.sync.recMutex,
  fafafa.core.sync.spinMutex;

procedure TestMutexReentrant;
var
  m: IMutex;
  success: Boolean;
begin
  WriteLn('=== 测试标准 Mutex 不可重入行为 ===');
  
  m := MakeMutex;
  
  WriteLn('1. 第一次 Acquire...');
  m.Acquire;
  WriteLn('   ✅ 第一次 Acquire 成功');
  
  WriteLn('2. 尝试同线程 TryAcquire...');
  success := m.TryAcquire;
  if success then
  begin
    WriteLn('   ❌ TryAcquire 成功 - Mutex 表现为可重入！');
    m.Release; // 释放 TryAcquire
  end
  else
  begin
    WriteLn('   ✅ TryAcquire 失败 - Mutex 正确表现为不可重入');
    WriteLn('   错误状态: ', Ord(m.GetLastError));
  end;
  
  WriteLn('3. 释放第一次 Acquire...');
  m.Release;
  WriteLn('   ✅ Release 成功');
  
  WriteLn('');
end;

procedure TestRecMutexReentrant;
var
  m: IRecMutex;
begin
  WriteLn('=== 测试 RecMutex 可重入行为 ===');
  
  m := MakeRecMutex;
  
  WriteLn('1. 第一次 Acquire...');
  m.Acquire;
  WriteLn('   ✅ 第一次 Acquire 成功');
  
  WriteLn('2. 尝试同线程 TryAcquire...');
  if m.TryAcquire then
  begin
    WriteLn('   ✅ TryAcquire 成功 - RecMutex 正确表现为可重入');
    m.Release; // 释放 TryAcquire
  end
  else
  begin
    WriteLn('   ❌ TryAcquire 失败 - RecMutex 应该可重入！');
    WriteLn('   错误状态: ', Ord(m.GetLastError));
  end;
  
  WriteLn('3. 释放第一次 Acquire...');
  m.Release;
  WriteLn('   ✅ Release 成功');
  
  WriteLn('');
end;

procedure TestSpinMutexReentrant;
var
  m: ISpinMutex;
  success: Boolean;
begin
  WriteLn('=== 测试 SpinMutex 不可重入行为 ===');
  
  m := MakeSpinMutex('test_spin_mutex');
  
  WriteLn('1. 第一次 Acquire...');
  m.Acquire;
  WriteLn('   ✅ 第一次 Acquire 成功');
  
  WriteLn('2. 尝试同线程 TryAcquire...');
  success := m.TryAcquire;
  if success then
  begin
    WriteLn('   ❌ TryAcquire 成功 - SpinMutex 表现为可重入！');
    m.Release; // 释放 TryAcquire
  end
  else
  begin
    WriteLn('   ✅ TryAcquire 失败 - SpinMutex 正确表现为不可重入');
    WriteLn('   错误状态: ', Ord(m.GetLastError));
  end;
  
  WriteLn('3. 释放第一次 Acquire...');
  m.Release;
  WriteLn('   ✅ Release 成功');
  
  WriteLn('');
end;

begin
  try
    TestMutexReentrant;
    TestRecMutexReentrant;
    TestSpinMutexReentrant;
    
    WriteLn('🎉 所有测试完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
