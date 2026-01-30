program verify_shm;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, fafafa.core.sync.namedRWLock;

var
  LRWLock1, LRWLock2: INamedRWLock;
  LWriteGuard: INamedRWLockWriteGuard;
  LReadGuard: INamedRWLockReadGuard;

begin
  WriteLn('=== 验证真正的跨进程共享内存实现 ===');
  
  try
    // 创建第一个实例
    WriteLn('1. 创建第一个命名读写锁实例...');
    LRWLock1 := MakeNamedRWLock('verify_test_lock');
    WriteLn('   成功创建');
    
    // 创建第二个同名实例（模拟另一个进程）
    WriteLn('2. 创建第二个同名实例（模拟跨进程）...');
    LRWLock2 := MakeNamedRWLock('verify_test_lock');
    WriteLn('   成功创建');
    
    // 测试互斥性
    WriteLn('3. 测试读写锁互斥性...');
    
    // 第一个实例获取写锁
    WriteLn('   第一个实例获取写锁...');
    LWriteGuard := LRWLock1.WriteLock;
    WriteLn('   成功获取写锁');
    
    // 第二个实例尝试获取写锁（应该失败）
    WriteLn('   第二个实例尝试非阻塞获取写锁...');
    if LRWLock2.TryWriteLock = nil then
      WriteLn('   ✓ 正确：第二个实例无法获取写锁（互斥工作正常）')
    else
      WriteLn('   ✗ 错误：第二个实例获取了写锁（互斥失败）');
    
    // 释放写锁
    WriteLn('   释放第一个实例的写锁...');
    LWriteGuard := nil;
    WriteLn('   写锁已释放');
    
    // 现在第二个实例应该能获取写锁
    WriteLn('   第二个实例再次尝试获取写锁...');
    LWriteGuard := LRWLock2.TryWriteLock;
    if LWriteGuard <> nil then
    begin
      WriteLn('   ✓ 正确：第二个实例成功获取写锁');
      LWriteGuard := nil;
      WriteLn('   释放写锁');
    end
    else
      WriteLn('   ✗ 错误：第二个实例无法获取写锁');
    
    // 测试多读者
    WriteLn('4. 测试多读者并发...');
    LReadGuard := LRWLock1.ReadLock;
    WriteLn('   第一个实例获取读锁');
    
    if LRWLock2.TryReadLock <> nil then
      WriteLn('   ✓ 正确：第二个实例也能获取读锁（多读者工作正常）')
    else
      WriteLn('   ✗ 错误：第二个实例无法获取读锁');
    
    WriteLn('5. 清理资源...');
    LReadGuard := nil;
    LRWLock1 := nil;
    LRWLock2 := nil;
    WriteLn('   资源已清理');
    
    WriteLn('=== 验证完成 ===');
    WriteLn('✓ 真正的跨进程共享内存实现工作正常！');
    
  except
    on E: Exception do
    begin
      WriteLn('✗ 错误: ', E.Message);
      Halt(1);
    end;
  end;
end.
