program example_thread_channel;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, fafafa.core.thread;

var
  LChan: IChannel;
  LRecvDone: Boolean = False;
  LGot: Pointer = nil;
  LData: Pointer;
  LPool: IThreadPool;
  LRecvFuture: IFuture;

function RecvTask(Data: Pointer): Boolean;
begin
  Result := LChan.Recv(LGot);
  LRecvDone := Result;
end;

begin

  // Demonstrate unbuffered channel (capacity=0) handshake
  LChan := CreateChannel(0);
  LPool := CreateSingleThreadPool;

  // Start receiver which will block until sender sends
  LRecvFuture := LPool.Submit(@RecvTask, nil);

  Sleep(100); // ensure receiver is waiting

  // Send value; this will wake the receiver
  LData := Pointer(PtrUInt(123));
  if LChan.Send(LData) then
    Writeln('Send ok, data=', PtrUInt(LData))
  else
    Writeln('Send failed');

  // Wait receiver
  LRecvFuture.WaitFor(2000);
  Writeln('Recv done=', LRecvDone, ', value=', PtrUInt(LGot));

  LPool.Shutdown;
  LPool.AwaitTermination(2000);
end.

