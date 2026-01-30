program example_timeout;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.mutex, fafafa.core.sync.condvar;

var
  Mutex: IMutex;
  Cond: ICondVar;

begin
  Mutex := MakeMutex;
  Cond := MakeCondVar;

  Mutex.Acquire;
  try
    Writeln('等待 200ms...');
    if Cond.Wait(Mutex, 200) then
      Writeln('被唤醒')
    else
      Writeln('超时返回');
  finally
    Mutex.Release;
  end;

  Writeln('示例完成。');
end.

