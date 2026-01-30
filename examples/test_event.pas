{$mode objfpc}{$H+}
program test_event;

uses
  SysUtils, Classes,
  fafafa.core.sync.event;

var
  Event: IEvent;
  ThreadResults: array[1..3] of Boolean;
  
type
  TWorkerThread = class(TThread)
  private
    FIndex: Integer;
    FEvent: IEvent;
  protected
    procedure Execute; override;
  public
    constructor Create(AIndex: Integer; AEvent: IEvent);
  end;

constructor TWorkerThread.Create(AIndex: Integer; AEvent: IEvent);
begin
  inherited Create(False);
  FIndex := AIndex;
  FEvent := AEvent;
  FreeOnTerminate := True;
end;

procedure TWorkerThread.Execute;
begin
  WriteLn('[Thread ', FIndex, '] Waiting for event...');
  
  // Wait for the event to be signaled
  if FEvent.Wait = wrSignaled then
  begin
    WriteLn('[Thread ', FIndex, '] Event received!');
    ThreadResults[FIndex] := True;
  end
  else
  begin
    WriteLn('[Thread ', FIndex, '] Wait failed!');
    ThreadResults[FIndex] := False;
  end;
end;

procedure TestAutoResetEvent;
var
  i: Integer;
  Threads: array[1..3] of TWorkerThread;
begin
  WriteLn('=== Testing Auto-Reset Event ===');
  WriteLn('(Only one thread should receive each signal)');
  WriteLn;
  
  // Create auto-reset event (default)
  Event := MakeEvent(False, False);
  
  // Clear results
  for i := 1 to 3 do
    ThreadResults[i] := False;
  
  // Create and start threads
  for i := 1 to 3 do
    Threads[i] := TWorkerThread.Create(i, Event);
  
  // Give threads time to start waiting
  Sleep(100);
  
  // Signal the event 3 times (one for each thread)
  for i := 1 to 3 do
  begin
    WriteLn('Main: Signaling event ', i, '...');
    Event.SetEvent;
    Sleep(100); // Give time for one thread to wake up
  end;
  
  // Wait for all threads to complete
  Sleep(500);
  
  // Check results
  WriteLn;
  WriteLn('Results:');
  for i := 1 to 3 do
    WriteLn('  Thread ', i, ': ', ThreadResults[i]);
  
  WriteLn;
end;

procedure TestManualResetEvent;
var
  i: Integer;
  Threads: array[1..3] of TWorkerThread;
begin
  WriteLn('=== Testing Manual-Reset Event ===');
  WriteLn('(All threads should receive the signal)');
  WriteLn;
  
  // Create manual-reset event
  Event := MakeEvent(True, False);
  
  // Clear results
  for i := 1 to 3 do
    ThreadResults[i] := False;
  
  // Create and start threads
  for i := 1 to 3 do
    Threads[i] := TWorkerThread.Create(i, Event);
  
  // Give threads time to start waiting
  Sleep(100);
  
  // Signal the event once (should wake all threads)
  WriteLn('Main: Signaling event...');
  Event.SetEvent;
  
  // Wait for all threads to complete
  Sleep(500);
  
  // Reset the event for next use
  Event.ResetEvent;
  
  // Check results
  WriteLn;
  WriteLn('Results:');
  for i := 1 to 3 do
    WriteLn('  Thread ', i, ': ', ThreadResults[i]);
  
  WriteLn;
end;

procedure TestEventTimeout;
var
  StartTime, EndTime: TDateTime;
  WaitResult: TWaitResult;
begin
  WriteLn('=== Testing Event Timeout ===');
  WriteLn;
  
  Event := MakeEvent(False, False);
  
  WriteLn('Waiting for event with 1 second timeout...');
  StartTime := Now;
  WaitResult := Event.WaitFor(1000);
  EndTime := Now;
  
  WriteLn('Wait result: ', Ord(WaitResult));
  WriteLn('Time elapsed: ', FormatDateTime('ss.zzz', EndTime - StartTime), ' seconds');
  
  if WaitResult = wrTimeout then
    WriteLn('Timeout occurred as expected')
  else
    WriteLn('Unexpected result!');
  
  WriteLn;
end;

procedure TestEventSignaledState;
begin
  WriteLn('=== Testing Event Signaled State ===');
  WriteLn;
  
  Event := MakeEvent(True, False); // Manual reset, initially not signaled
  
  WriteLn('Initial state - IsSignaled: ', Event.IsSignaled);
  
  Event.SetEvent;
  WriteLn('After SetEvent - IsSignaled: ', Event.IsSignaled);
  
  Event.ResetEvent;
  WriteLn('After ResetEvent - IsSignaled: ', Event.IsSignaled);
  
  WriteLn;
end;

procedure TestTryWait;
begin
  WriteLn('=== Testing TryWait (Non-blocking) ===');
  WriteLn;
  
  Event := MakeEvent(False, False);
  
  WriteLn('TryWait on non-signaled event: ', Event.TryWait);
  
  Event.SetEvent;
  WriteLn('After SetEvent - TryWait: ', Event.TryWait);
  WriteLn('Second TryWait (auto-reset consumed): ', Event.TryWait);
  
  WriteLn;
end;

begin
  try
    WriteLn('Event Synchronization Primitive Test');
    WriteLn('=====================================');
    WriteLn;
    
    TestAutoResetEvent;
    TestManualResetEvent;
    TestEventTimeout;
    TestEventSignaledState;
    TestTryWait;
    
    WriteLn('All tests completed!');
  except
    on E: Exception do
      WriteLn('Error: ', E.Message);
  end;
  
  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
end.