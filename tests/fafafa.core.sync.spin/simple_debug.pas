{$CODEPAGE UTF8}
program simple_debug;

uses
  fafafa.core.sync.spin;

var
  SpinLock: ISpinLock;
begin
  WriteLn('创建自旋锁...');
  SpinLock := MakeSpinLock;
  WriteLn('自旋锁创建成功');
  
  WriteLn('测试 TryAcquire 无参版本...');
  if SpinLock.TryAcquire then
  begin
    WriteLn('TryAcquire 成功');
    SpinLock.Release;
    WriteLn('Release 完成');
  end
  else
  begin
    WriteLn('TryAcquire 失败！');
  end;
  
  WriteLn('测试 TryAcquire(0)...');
  if SpinLock.TryAcquire(0) then
  begin
    WriteLn('TryAcquire(0) 成功');
    SpinLock.Release;
    WriteLn('Release 完成');
  end
  else
  begin
    WriteLn('TryAcquire(0) 失败！');
  end;
  
  WriteLn('测试完成');
end.
