program trace_acquire;

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
  i: Integer;
  Success: Boolean;
begin
  WriteLn('追踪 TryAcquire 行为模式');
  WriteLn('========================');
  WriteLn;
  
  Mutex := MakeMutex;
  
  WriteLn('首先尝试连续调用 TryAcquire() 3次（无获取）:');
  for i := 1 to 3 do
  begin
    Success := Mutex.TryAcquire();
    WriteLn('  第', i, '次调用 TryAcquire(): ', Success);
    if Success then
    begin
      Mutex.Release;
      WriteLn('    锁已释放');
    end;
  end;
  
  WriteLn;
  WriteLn('现在尝试连续调用 TryAcquire(0) 3次:');
  for i := 1 to 3 do
  begin
    Success := Mutex.TryAcquire(0);
    WriteLn('  第', i, '次调用 TryAcquire(0): ', Success);
    if Success then
    begin
      Mutex.Release;
      WriteLn('    锁已释放');
    end;
  end;
  
  WriteLn;
  WriteLn('现在尝试连续调用 TryAcquire(100) 3次:');
  for i := 1 to 3 do
  begin
    Success := Mutex.TryAcquire(100);
    WriteLn('  第', i, '次调用 TryAcquire(100): ', Success);
    if Success then
    begin
      Mutex.Release;
      WriteLn('    锁已释放');
    end;
  end;
  
  WriteLn;
  WriteLn('诊断结果:');
  WriteLn('---------');
  WriteLn('看起来 SRWLOCK 的状态在第一次 TryAcquire 成功后');
  WriteLn('没有被正确重置，导致后续调用都失败了。');
end.
