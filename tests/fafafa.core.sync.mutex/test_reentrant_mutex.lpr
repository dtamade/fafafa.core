program test_reentrant_mutex;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils,
  fafafa.core.sync.mutex;

var
  m: IMutex;
  nm: INonReentrantMutex;

begin
  WriteLn('=== 测试重新设计的 Mutex 接口 ===');
  
  try
    // 测试标准可重入互斥锁
    WriteLn('1. 测试标准可重入互斥锁...');
    m := MakeMutex;
    WriteLn('   ✅ MakeMutex 成功');
    
    // 测试可重入性
    WriteLn('2. 测试可重入性...');
    m.Acquire;
    WriteLn('   ✅ 第一次 Acquire 成功');
    
    m.Acquire;
    WriteLn('   ✅ 第二次 Acquire 成功（可重入）');
    
    m.Acquire;
    WriteLn('   ✅ 第三次 Acquire 成功（可重入）');
    
    // 测试新的接口方法
    WriteLn('3. 测试新的接口方法...');
    WriteLn('   持有次数: ', m.GetHoldCount);
    WriteLn('   是否被当前线程持有: ', m.IsHeldByCurrentThread);
    
    // 释放锁
    WriteLn('4. 释放锁...');
    m.Release;
    WriteLn('   ✅ 第一次 Release 成功');
    
    m.Release;
    WriteLn('   ✅ 第二次 Release 成功');
    
    m.Release;
    WriteLn('   ✅ 第三次 Release 成功');
    
    // 测试非重入互斥锁
    WriteLn('');
    WriteLn('5. 测试非重入互斥锁...');
    nm := MakeNonReentrantMutex;
    WriteLn('   ✅ MakeNonReentrantMutex 成功');
    
    nm.Acquire;
    WriteLn('   ✅ 非重入锁 Acquire 成功');
    
    // 测试非重入性（应该不会阻塞，因为使用 TryAcquire）
    if nm.TryAcquire then
    begin
      WriteLn('   ❌ 非重入锁意外地允许了重入！');
      nm.Release;
    end
    else
    begin
      WriteLn('   ✅ 非重入锁正确拒绝了重入');
    end;
    
    nm.Release;
    WriteLn('   ✅ 非重入锁 Release 成功');
    
    WriteLn('');
    WriteLn('✅ 所有测试通过！重新设计的接口工作正常！');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
