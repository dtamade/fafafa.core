program debug_shm;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  cthreads, SysUtils, fafafa.core.sync.namedRWLock;

var
  LRWLock: INamedRWLock;
  LReadGuard: INamedRWLockReadGuard;
  LWriteGuard: INamedRWLockWriteGuard;

begin
  WriteLn('=== 调试共享内存实现 ===');
  
  try
    WriteLn('1. 检查 /dev/shm/ 目录（创建前）:');
    WriteLn('   (跳过系统调用)');
    
    WriteLn('2. 创建命名读写锁...');
    LRWLock := MakeNamedRWLock('debug_test_lock');
    WriteLn('   创建成功');
    
    WriteLn('3. 检查 /dev/shm/ 目录（创建后）:');
    WriteLn('   (跳过系统调用)');
    
    WriteLn('4. 尝试获取读锁...');
    try
      LReadGuard := LRWLock.ReadLock;
      WriteLn('   读锁获取成功');
      LReadGuard := nil;
      WriteLn('   读锁释放成功');
    except
      on E: Exception do
        WriteLn('   读锁操作失败: ', E.Message);
    end;

    WriteLn('5. 尝试获取写锁...');
    try
      LWriteGuard := LRWLock.WriteLock;
      WriteLn('   写锁获取成功');
      LWriteGuard := nil;
      WriteLn('   写锁释放成功');
    except
      on E: Exception do
        WriteLn('   写锁操作失败: ', E.Message);
    end;
    
    WriteLn('6. 清理资源...');
    LRWLock := nil;
    WriteLn('   资源清理完成');
    
    WriteLn('7. 检查 /dev/shm/ 目录（清理后）:');
    WriteLn('   (跳过系统调用)');
    
    WriteLn('=== 调试完成 ===');
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      WriteLn('错误类型: ', E.ClassName);
      Halt(1);
    end;
  end;
end.
