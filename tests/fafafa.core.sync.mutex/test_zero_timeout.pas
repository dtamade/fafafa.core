program test_zero_timeout;

{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex;

var
  Mutex: IMutex;
  Result1, Result2, Result3: Boolean;
begin
  WriteLn('测试 TryAcquire(0) 行为');
  WriteLn('========================');
  WriteLn;
  
  Mutex := MakeMutex;
  
  WriteLn('Test 1: TryAcquire() 无参数');
  Result1 := Mutex.TryAcquire();
  WriteLn('  结果: ', Result1);
  
  if Result1 then
  begin
    Mutex.Release;
    WriteLn('  锁已释放');
  end;
  
  WriteLn;
  WriteLn('Test 2: TryAcquire(0) 零超时');
  Result2 := Mutex.TryAcquire(0);
  WriteLn('  结果: ', Result2);
  
  if Result2 then
  begin
    Mutex.Release;
    WriteLn('  锁已释放');
  end;
  
  WriteLn;
  WriteLn('Test 3: TryAcquire(100) 带超时');
  Result3 := Mutex.TryAcquire(100);
  WriteLn('  结果: ', Result3);
  
  if Result3 then
  begin
    Mutex.Release;
    WriteLn('  锁已释放');
  end;
  
  WriteLn;
  WriteLn('分析:');
  WriteLn('-----');
  if not Result2 then
  begin
    WriteLn('✗ 问题找到: TryAcquire(0) 在锁空闲时返回了 False！');
    WriteLn('  这是 BUG 所在！基类 TTryLock.TryAcquire(0) 的实现有问题。');
  end;
end.
