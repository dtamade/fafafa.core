program example_auto_vs_manual;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$modeswitch anonymousfunctions}

{
  Auto-Reset vs Manual-Reset Event Comparison Example
  
  This example demonstrates:
  1. The difference between auto-reset and manual-reset events
  2. Multiple waiters behavior on a single SetEvent
  3. Basic thread coordination
}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes, fafafa.core.sync.event, fafafa.core.sync.base;

procedure RunAutoResetDemo;
const
  WORKER_COUNT = 3;
var
  AutoEvent: IEvent;
  Workers: array[0..WORKER_COUNT-1] of TThread;
  i: Integer;
begin
  WriteLn('=== Auto-Reset Event (only one waiter released per SetEvent) ===');
  AutoEvent := MakeEvent(False, False); // auto-reset

  // Create waiters
  for i := 0 to WORKER_COUNT - 1 do
  begin
    Workers[i] := TThread.CreateAnonymousThread(
      procedure
      var id: Integer;
          res: TWaitResult;
      begin
        id := i + 1;
        WriteLn('[AUTO] Worker ', id, ' waiting...');
        res := AutoEvent.WaitFor(2000);
        case res of
          wrSignaled:   WriteLn('[AUTO] Worker ', id, ' released');
          wrTimeout:    WriteLn('[AUTO] Worker ', id, ' timeout');
          wrAbandoned:  WriteLn('[AUTO] Worker ', id, ' abandoned');
        else
          WriteLn('[AUTO] Worker ', id, ' error');
        end;
      end
    );
    Workers[i].FreeOnTerminate := False;
  end;

  // Start all
  for i := 0 to WORKER_COUNT - 1 do
    Workers[i].Start;

  // Give them time to start waiting
  Sleep(200);

  // Each SetEvent should release exactly one waiter
  for i := 1 to WORKER_COUNT do
  begin
    WriteLn('[AUTO] Calling SetEvent #', i, ' ...');
    AutoEvent.SetEvent;
    Sleep(150);
  end;

  // Join
  for i := 0 to WORKER_COUNT - 1 do
    Workers[i].WaitFor;

  for i := 0 to WORKER_COUNT - 1 do
    Workers[i].Free;

  WriteLn('=== Auto-Reset demo done ===');
  WriteLn;
end;

procedure RunManualResetDemo;
const
  WORKER_COUNT = 3;
var
  ManualEvent: IEvent;
  Workers: array[0..WORKER_COUNT-1] of TThread;
  i: Integer;
begin
  WriteLn('=== Manual-Reset Event (broadcast to all waiters per SetEvent) ===');
  ManualEvent := MakeEvent(True, False); // manual-reset

  // Create waiters
  for i := 0 to WORKER_COUNT - 1 do
  begin
    Workers[i] := TThread.CreateAnonymousThread(
      procedure
      var id: Integer;
          res: TWaitResult;
      begin
        id := i + 1;
        WriteLn('[MANUAL] Worker ', id, ' waiting...');
        res := ManualEvent.WaitFor(3000);
        case res of
          wrSignaled:   WriteLn('[MANUAL] Worker ', id, ' released');
          wrTimeout:    WriteLn('[MANUAL] Worker ', id, ' timeout');
          wrAbandoned:  WriteLn('[MANUAL] Worker ', id, ' abandoned');
        else
          WriteLn('[MANUAL] Worker ', id, ' error');
        end;
      end
    );
    Workers[i].FreeOnTerminate := False;
  end;

  // Start all
  for i := 0 to WORKER_COUNT - 1 do
    Workers[i].Start;

  // Give them time to start waiting
  Sleep(200);

  // One SetEvent should release ALL waiters in manual-reset mode
  WriteLn('[MANUAL] Calling SetEvent once (broadcast)...');
  ManualEvent.SetEvent;

  // Give time for all to pass
  Sleep(400);

  // Reset and show they would block again
  WriteLn('[MANUAL] ResetEvent to block future waiters');
  ManualEvent.ResetEvent;

  // Join
  for i := 0 to WORKER_COUNT - 1 do
    Workers[i].WaitFor;

  for i := 0 to WORKER_COUNT - 1 do
    Workers[i].Free;

  WriteLn('=== Manual-Reset demo done ===');
  WriteLn;
end;

begin
  WriteLn('fafafa.core.sync.event Auto vs Manual Reset Example');
  WriteLn('====================================================');
  WriteLn;

  try
    RunAutoResetDemo;
    RunManualResetDemo;

    WriteLn('All demos completed successfully!');
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
