program debug_guard;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.rwlock, fafafa.core.sync.base;

var
  RWLock: IRWLock;
  Guard1, Guard2: IRWLockWriteGuard;

procedure ShowState(const AStep: string);
begin
  WriteLn(Format('%s: IsWriteLocked=%s, WriterThread=%d', 
    [AStep, BoolToStr(RWLock.IsWriteLocked, True), RWLock.GetWriterThread]));
end;

begin
  WriteLn('=== 守卫析构调试 ===');
  
  // 创建读写锁
  RWLock := MakeRWLock;
  WriteLn('读写锁已创建');
  
  try
    ShowState('初始状态');
    
    // 获取第一个守卫
    WriteLn('创建 Guard1 (Write)...');
    Guard1 := RWLock.Write;
    WriteLn('Guard1 创建完成, IsValid=', Guard1.IsValid);
    ShowState('Guard1 创建后');
    
    // 获取第二个守卫
    WriteLn('创建 Guard2 (TryWrite)...');
    Guard2 := RWLock.TryWrite(50);
    if Guard2 <> nil then
    begin
      WriteLn('Guard2 创建完成, IsValid=', Guard2.IsValid);
      ShowState('Guard2 创建后');
    end
    else
    begin
      WriteLn('Guard2 创建失败');
      ShowState('Guard2 创建失败后');
    end;
    
    // 手动释放 Guard2
    if Guard2 <> nil then
    begin
      WriteLn('手动释放 Guard2...');
      WriteLn('释放前: Guard2.IsValid=', Guard2.IsValid);
      Guard2.Release;  // 手动调用 Release
      WriteLn('手动释放后: Guard2.IsValid=', Guard2.IsValid);
      ShowState('Guard2 手动释放后');
      Guard2 := nil;  // 清空引用
      WriteLn('Guard2 引用清空');
      ShowState('Guard2 引用清空后');
    end;
    
    // 手动释放 Guard1
    if Guard1 <> nil then
    begin
      WriteLn('手动释放 Guard1...');
      WriteLn('释放前: Guard1.IsValid=', Guard1.IsValid);
      Guard1.Release;  // 手动调用 Release
      WriteLn('手动释放后: Guard1.IsValid=', Guard1.IsValid);
      ShowState('Guard1 手动释放后');
      Guard1 := nil;  // 清空引用
      WriteLn('Guard1 引用清空');
      ShowState('Guard1 引用清空后');
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
