program example_autolock;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
{$I ..\..\src\fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.sync;

procedure DemoAutoLock;
var
  LMutex: IMutex;
  LGuard: ILockGuard;
  LAcquired: Boolean;
begin
  WriteLn('=== AutoLock / Guard 示例 ===');

  LMutex := MakeMutex;
  LGuard := LMutex.Lock;
  WriteLn('进入作用域后 Guard.IsLocked = ', BoolToStr(Assigned(LGuard) and LGuard.IsLocked, True));

  LGuard := nil;

  LAcquired := LMutex.TryAcquire;
  WriteLn('离开作用域后 TryAcquire = ', BoolToStr(LAcquired, True));
  if LAcquired then
    LMutex.Release;
end;

begin
  try
    DemoAutoLock;
  except
    on LError: Exception do
    begin
      WriteLn('异常: ', LError.Message);
      Halt(1);
    end;
  end;
end.
