program example_thread_scheduler;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, fafafa.core.thread;

var
  LScheduler: ITaskScheduler;
  LFuture: IFuture;
  LStart, LEnd: QWord;
  LFlag: Boolean = False;

function SetTrue(Data: Pointer): Boolean;
begin
  if Data <> nil then
    PBoolean(Data)^ := True;
  Result := True;
end;

begin
  LScheduler := CreateTaskScheduler;
  LStart := GetTickCount64;
  LFuture := LScheduler.Schedule(@SetTrue, 300, @LFlag);
  Writeln('Scheduled, waiting...');
  LFuture.WaitFor(2000);
  LEnd := GetTickCount64;
  Writeln('Elapsed(ms)=', LEnd - LStart, ', Flag=', LFlag);
  LScheduler.Shutdown;
end.

