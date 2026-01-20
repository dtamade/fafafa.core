program debug_count;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.rwlock, fafafa.core.sync.base, fafafa.core.sync.rwlock.base;

var
  RWLock: IRWLock;

procedure ShowState(const AStep: string);
begin
  WriteLn(Format('%s: IsWriteLocked=%s, WriterThread=%d', 
    [AStep, BoolToStr(RWLock.IsWriteLocked, True), RWLock.GetWriterThread]));
end;

begin
  WriteLn('=== 可重入性计数调试 ===');
  
  // 创建读写锁
  RWLock := MakeRWLock;
  WriteLn('读写锁已创建');
  
  try
    // 直接调用 AcquireWrite/ReleaseWrite 来验证基础逻辑
    WriteLn('=== 直接调用测试 ===');
    
    ShowState('初始状态');
    
    WriteLn('第一次 AcquireWrite...');
    RWLock.AcquireWrite;
    ShowState('第一次 AcquireWrite 后');
    
    WriteLn('第二次 AcquireWrite（可重入）...');
    RWLock.AcquireWrite;
    ShowState('第二次 AcquireWrite 后');
    
    WriteLn('第一次 ReleaseWrite...');
    RWLock.ReleaseWrite;
    ShowState('第一次 ReleaseWrite 后');
    
    WriteLn('第二次 ReleaseWrite...');
    RWLock.ReleaseWrite;
    ShowState('第二次 ReleaseWrite 后');
    
    WriteLn('');
    WriteLn('=== 混合调用测试 ===');
    
    WriteLn('AcquireWrite...');
    RWLock.AcquireWrite;
    ShowState('AcquireWrite 后');
    
    WriteLn('TryAcquireWriteEx(50)...');
    if RWLock.TryAcquireWriteEx(50) = lrSuccess then
    begin
      WriteLn('TryAcquireWriteEx 成功');
      ShowState('TryAcquireWriteEx 后');
      
      WriteLn('第一次 ReleaseWrite...');
      RWLock.ReleaseWrite;
      ShowState('第一次 ReleaseWrite 后');
      
      WriteLn('第二次 ReleaseWrite...');
      RWLock.ReleaseWrite;
      ShowState('第二次 ReleaseWrite 后');
    end
    else
    begin
      WriteLn('TryAcquireWriteEx 失败');
      RWLock.ReleaseWrite;
    end;
    
    WriteLn('=== 测试完成 ===');
    
  except
    on E: Exception do
    begin
      WriteLn('异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
