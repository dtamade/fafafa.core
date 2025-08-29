{$CODEPAGE UTF8}
program debug_timeout_zero;

uses
  fafafa.core.sync.spin;

var
  SpinLock: ISpinLock;
  Result1, Result2: Boolean;
begin
  WriteLn('调试超时为0的问题');
  
  SpinLock := MakeSpinLock;
  
  WriteLn('测试 TryAcquire 无参版本:');
  Result1 := SpinLock.TryAcquire;
  WriteLn('结果: ', Result1);
  if Result1 then
  begin
    WriteLn('成功获取锁，现在释放');
    SpinLock.Release;
  end;
  
  WriteLn('测试 TryAcquire(0):');
  Result2 := SpinLock.TryAcquire(0);
  WriteLn('结果: ', Result2);
  if Result2 then
  begin
    WriteLn('成功获取锁，现在释放');
    SpinLock.Release;
  end;
  
  WriteLn('两个结果应该相同: ', Result1, ' = ', Result2);
end.
