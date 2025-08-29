program debug_direct;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.rwlock, fafafa.core.sync.base;

var
  RWLock: IRWLock;

begin
  WriteLn('=== 直接调用 AcquireWrite/ReleaseWrite 测试 ===');
  
  // 创建读写锁
  RWLock := MakeRWLock;
  WriteLn('读写锁已创建');
  
  try
    // 第一次获取写锁
    WriteLn('=== 第一次 AcquireWrite ===');
    RWLock.AcquireWrite;
    WriteLn('状态: IsWriteLocked=', RWLock.IsWriteLocked, ', WriterThread=', RWLock.GetWriterThread);
    
    // 第二次获取写锁（可重入）
    WriteLn('=== 第二次 AcquireWrite（可重入）===');
    RWLock.AcquireWrite;
    WriteLn('状态: IsWriteLocked=', RWLock.IsWriteLocked, ', WriterThread=', RWLock.GetWriterThread);
    
    // 第一次释放写锁
    WriteLn('=== 第一次 ReleaseWrite ===');
    RWLock.ReleaseWrite;
    WriteLn('状态: IsWriteLocked=', RWLock.IsWriteLocked, ', WriterThread=', RWLock.GetWriterThread);
    
    // 第二次释放写锁
    WriteLn('=== 第二次 ReleaseWrite ===');
    RWLock.ReleaseWrite;
    WriteLn('最终状态: IsWriteLocked=', RWLock.IsWriteLocked, ', WriterThread=', RWLock.GetWriterThread);
    
    WriteLn('=== 测试完成 ===');
    
  except
    on E: Exception do
    begin
      WriteLn('异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
