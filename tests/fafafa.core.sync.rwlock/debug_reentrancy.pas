program debug_reentrancy;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.rwlock, fafafa.core.sync.base;

var
  RWLock: IRWLock;
  Guard1, Guard2: IRWLockWriteGuard;

begin
  WriteLn('=== 调试可重入性行为 ===');
  
  // 创建读写锁
  RWLock := MakeRWLock;
  WriteLn('读写锁已创建');
  
  try
    // 获取第一个写锁守卫（通过 Write()）
    WriteLn('=== 步骤1: 获取第一个写锁守卫（Write()）===');
    Guard1 := RWLock.Write;
    if Guard1 <> nil then
    begin
      WriteLn('第一个写锁守卫获取成功, IsValid=', Guard1.IsValid);
    end
    else
      WriteLn('第一个写锁守卫获取失败');

    WriteLn('状态: IsWriteLocked=', RWLock.IsWriteLocked, ', WriterThread=', RWLock.GetWriterThread);

    // 尝试获取第二个写锁守卫（通过 TryWrite()）
    WriteLn('=== 步骤2: 获取第二个写锁守卫（TryWrite()）===');
    Guard2 := RWLock.TryWrite(50);
    if Guard2 <> nil then
    begin
      WriteLn('第二个写锁守卫获取成功（可重入）, IsValid=', Guard2.IsValid);
    end
    else
      WriteLn('第二个写锁守卫获取失败');

    WriteLn('状态: IsWriteLocked=', RWLock.IsWriteLocked, ', WriterThread=', RWLock.GetWriterThread);
    WriteLn('Guard1.IsValid=', Guard1.IsValid, ', Guard2.IsValid=', Guard2.IsValid);

    // 释放第二个守卫（TryWrite 创建的）
    WriteLn('=== 步骤3: 释放第二个写锁守卫（TryWrite 创建的）===');
    if Guard2 <> nil then
    begin
      WriteLn('释放第二个写锁守卫... IsValid=', Guard2.IsValid);
      Guard2 := nil;
      WriteLn('第二个写锁守卫已释放');
    end;

    WriteLn('状态: IsWriteLocked=', RWLock.IsWriteLocked, ', WriterThread=', RWLock.GetWriterThread);
    WriteLn('Guard1.IsValid=', Guard1.IsValid);

    // 释放第一个守卫（Write 创建的）
    WriteLn('=== 步骤4: 释放第一个写锁守卫（Write 创建的）===');
    if Guard1 <> nil then
    begin
      WriteLn('释放第一个写锁守卫... IsValid=', Guard1.IsValid);
      Guard1 := nil;
      WriteLn('第一个写锁守卫已释放');
    end;

    WriteLn('最终状态: IsWriteLocked=', RWLock.IsWriteLocked, ', WriterThread=', RWLock.GetWriterThread);
    
    // 验证锁完全释放后可以重新获取
    WriteLn('验证锁完全释放后可以重新获取...');
    Guard1 := RWLock.TryWrite(50);
    if Guard1 <> nil then
    begin
      WriteLn('重新获取写锁成功');
      Guard1 := nil;
      WriteLn('重新获取的写锁已释放');
    end
    else
      WriteLn('重新获取写锁失败');
    
    WriteLn('=== 测试完成 ===');
    
  except
    on E: Exception do
    begin
      WriteLn('异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
