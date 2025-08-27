program example_autolock;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.base,
  fafafa.core.sync;

procedure DemoAutoLock;
var
  LMutex: ILock;
  guard: TAutoLock;
begin
  WriteLn('=== AutoLock 示例 ===');
  LMutex := TMutex.Create;
  WriteLn('进入作用域，创建 guard...');
  guard := TAutoLock.Create(LMutex);
  try
    WriteLn('作用域中：IsLocked=', BoolToStr(LMutex.IsLocked, 'True', 'False'));
  finally
    guard.Free;
  end;
  WriteLn('离开作用域：IsLocked=', BoolToStr(LMutex.IsLocked, 'True', 'False'));
end;

begin
  try
    DemoAutoLock;
  except
    on E: Exception do begin
      WriteLn('异常: ', E.Message);
      Halt(1);
    end;
  end;
end.

