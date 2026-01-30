program example_basic_usage;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

{
  Basic Event Usage Example
  
  This example demonstrates:
  1. Creating and using events
  2. Basic wait and signal operations
  3. Auto-reset vs manual-reset behavior
  4. Timeout handling
}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, StrUtils, fafafa.core.sync.event, fafafa.core.sync.base;

procedure DemoAutoResetEvent;
var
  Event: IEvent;
  Result: TWaitResult;
begin
  WriteLn('=== Auto-Reset Event Demo ===');
  
  // Create auto-reset event, initial state: not signaled
  Event := MakeEvent(False, False);
  WriteLn('Created auto-reset event, initial state: not signaled');
  
  // Try to wait (should timeout)
  WriteLn('Trying to wait for 100ms...');
  Result := Event.WaitFor(100);
  if Result = wrTimeout then
    WriteLn('Wait result: timeout')
  else
    WriteLn('Wait result: signaled');

  // Set event to signaled state
  WriteLn('Setting event to signaled state');
  Event.SetEvent;
  
  // First wait (should succeed and auto-reset)
  WriteLn('First wait...');
  Result := Event.WaitFor(100);
  WriteLn('Wait result: ', IfThen(Result = wrSignaled, 'success', 'failed'));
  
  // Second wait (should timeout because auto-reset)
  WriteLn('Second wait...');
  Result := Event.WaitFor(100);
  WriteLn('Wait result: ', IfThen(Result = wrTimeout, 'timeout (auto-reset)', 'unexpected success'));
  
  WriteLn;
end;

procedure DemoManualResetEvent;
var
  Event: IEvent;
  Result: TWaitResult;
begin
  WriteLn('=== Manual-Reset Event Demo ===');
  
  // Create manual-reset event, initial state: not signaled
  Event := MakeEvent(True, False);
  WriteLn('Created manual-reset event, initial state: not signaled');
  
  // Try to wait (should timeout)
  WriteLn('Trying to wait for 100ms...');
  Result := Event.WaitFor(100);
  if Result = wrTimeout then
    WriteLn('Wait result: timeout')
  else
    WriteLn('Wait result: signaled');

  // Set event to signaled state
  WriteLn('Setting event to signaled state');
  Event.SetEvent;
  
  // First wait (should succeed)
  WriteLn('First wait...');
  Result := Event.WaitFor(100);
  WriteLn('Wait result: ', IfThen(Result = wrSignaled, 'success', 'failed'));
  
  // Second wait (should also succeed because manual-reset)
  WriteLn('Second wait...');
  Result := Event.WaitFor(100);
  WriteLn('Wait result: ', IfThen(Result = wrSignaled, 'success (still signaled)', 'failed'));
  
  // Reset event manually
  WriteLn('Resetting event manually');
  Event.ResetEvent;
  
  // Third wait (should timeout after manual reset)
  WriteLn('Third wait after reset...');
  Result := Event.WaitFor(100);
  WriteLn('Wait result: ', IfThen(Result = wrTimeout, 'timeout (manually reset)', 'unexpected success'));
  
  WriteLn;
end;

procedure DemoTryWait;
var
  Event: IEvent;
begin
  WriteLn('=== TryWait Demo ===');
  
  Event := MakeEvent(False, False);
  WriteLn('Created auto-reset event');
  
  // Try non-blocking wait (should return false)
  WriteLn('TryWait on non-signaled event: ', Event.TryWait);
  
  // Set event and try again
  Event.SetEvent;
  WriteLn('Set event, TryWait: ', Event.TryWait);
  
  // Try again (should return false because auto-reset)
  WriteLn('TryWait again (auto-reset): ', Event.TryWait);
  
  WriteLn;
end;

procedure DemoInitialState;
var
  Event: IEvent;
begin
  WriteLn('=== Initial State Demo ===');
  
  // Create event with initial signaled state
  Event := MakeEvent(False, True);
  WriteLn('Created auto-reset event with initial signaled state');
  
  // Should succeed immediately
  WriteLn('TryWait on initially signaled event: ', Event.TryWait);
  
  // Should fail now (auto-reset)
  WriteLn('TryWait again (auto-reset): ', Event.TryWait);
  
  WriteLn;
end;

begin
  WriteLn('fafafa.core.sync.event Basic Usage Example');
  WriteLn('==========================================');
  WriteLn;
  
  try
    DemoAutoResetEvent;
    DemoManualResetEvent;
    DemoTryWait;
    DemoInitialState;
    
    WriteLn('All demos completed successfully!');
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
