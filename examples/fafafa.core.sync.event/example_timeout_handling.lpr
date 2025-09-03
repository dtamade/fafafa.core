program example_timeout_handling;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$modeswitch anonymousfunctions}

{
  Timeout Handling Example
  
  This example demonstrates:
  1. Different timeout scenarios on events
  2. Measuring elapsed time for waits
  3. Using a signaler thread to simulate delayed events
}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes, fafafa.core.sync.event, fafafa.core.sync.base;

procedure RunImmediateTimeoutDemo;
var
  E: IEvent;
  res: TWaitResult;
  start, elapsed: QWord;
begin
  WriteLn('=== Immediate Timeout and Short Waits ===');
  E := MakeEvent(False, False);

  // Zero timeout (TryWait equivalent)
  start := GetTickCount64;
  res := E.WaitFor(0);
  elapsed := GetTickCount64 - start;
  WriteLn('WaitFor(0): result=', Ord(res), ' (0=Signaled,1=Timeout,..), elapsed=', elapsed, 'ms');

  // Short timeout on non-signaled event
  start := GetTickCount64;
  res := E.WaitFor(100);
  elapsed := GetTickCount64 - start;
  WriteLn('WaitFor(100): result=', Ord(res), ', elapsed=', elapsed, 'ms');

  WriteLn;
end;

procedure RunDelayedSignalDemo;
var
  E: IEvent;
  res: TWaitResult;
  start, elapsed: QWord;
  signaler: TThread;
begin
  WriteLn('=== Delayed Signal with Signaler Thread ===');
  E := MakeEvent(False, False);

  // Create a signaler thread that sets event after 300ms
  signaler := TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(300);
      E.SetEvent;
    end
  );
  signaler.FreeOnTerminate := False;
  signaler.Start;

  // Wait up to 1s - should be signaled around 300ms
  start := GetTickCount64;
  res := E.WaitFor(1000);
  elapsed := GetTickCount64 - start;

  case res of
    wrSignaled:  WriteLn('WaitFor(1000) signaled after ', elapsed, 'ms');
    wrTimeout:   WriteLn('Unexpected timeout after ', elapsed, 'ms');
  else
    WriteLn('Unexpected result: ', Ord(res));
  end;

  signaler.WaitFor;
  signaler.Free;
  WriteLn;
end;

procedure RunTimeoutLoopDemo;
var
  E: IEvent;
  i: Integer;
  res: TWaitResult;
begin
  WriteLn('=== Periodic Wait Loop with Timeout Handling ===');
  E := MakeEvent(False, False);

  // Simulate a loop that periodically waits with a timeout
  for i := 1 to 5 do
  begin
    res := E.WaitFor(150); // check periodically
    if res = wrSignaled then
    begin
      WriteLn('Loop iteration ', i, ': got signal');
      break;
    end
    else if res = wrTimeout then
    begin
      WriteLn('Loop iteration ', i, ': timeout (doing other work)');
      // do some work here
    end
    else
    begin
      WriteLn('Loop iteration ', i, ': unexpected result=', Ord(res));
    end;
  end;

  WriteLn('Loop finished');
  WriteLn;
end;

begin
  WriteLn('fafafa.core.sync.event Timeout Handling Example');
  WriteLn('================================================');
  WriteLn;

  try
    RunImmediateTimeoutDemo;
    RunDelayedSignalDemo;
    RunTimeoutLoopDemo;

    WriteLn('All demos completed successfully!');
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
