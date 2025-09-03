program example_thread_coordination;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

{
  Thread Coordination Example
  
  This example demonstrates:
  1. Coordinating multiple threads with events
  2. Barrier-like synchronization using manual-reset events
  3. Phase-based execution coordination
  4. Timeout handling in multi-thread scenarios
}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, StrUtils, Classes, fafafa.core.sync.event, fafafa.core.sync.base;

type
  TCoordinatedWorker = class(TThread)
  private
    FWorkerId: Integer;
    FStartEvent: IEvent;
    FPhase1Complete: IEvent;
    FPhase2Complete: IEvent;
    FShutdown: IEvent;
  protected
    procedure Execute; override;
  public
    constructor Create(WorkerId: Integer; StartEvent, Phase1Complete, Phase2Complete, Shutdown: IEvent);
  end;

constructor TCoordinatedWorker.Create(WorkerId: Integer; StartEvent, Phase1Complete, Phase2Complete, Shutdown: IEvent);
begin
  FWorkerId := WorkerId;
  FStartEvent := StartEvent;
  FPhase1Complete := Phase1Complete;
  FPhase2Complete := Phase2Complete;
  FShutdown := Shutdown;
  
  FreeOnTerminate := False;
  inherited Create(False);
end;

procedure TCoordinatedWorker.Execute;
begin
  WriteLn('[Worker ', FWorkerId, '] Created, waiting for start signal...');
  
  // Wait for start signal
  if FStartEvent.WaitFor(5000) <> wrSignaled then
  begin
    WriteLn('[Worker ', FWorkerId, '] Timeout waiting for start signal');
    Exit;
  end;
  
  WriteLn('[Worker ', FWorkerId, '] Started, beginning Phase 1...');
  
  // Phase 1: Individual work
  Sleep(Random(500) + 200); // Simulate variable work time
  WriteLn('[Worker ', FWorkerId, '] Phase 1 completed');
  
  // Wait for all workers to complete Phase 1
  WriteLn('[Worker ', FWorkerId, '] Waiting for all workers to complete Phase 1...');
  if FPhase1Complete.WaitFor(3000) <> wrSignaled then
  begin
    WriteLn('[Worker ', FWorkerId, '] Timeout waiting for Phase 1 completion');
    Exit;
  end;
  
  WriteLn('[Worker ', FWorkerId, '] All workers completed Phase 1, beginning Phase 2...');
  
  // Phase 2: Coordinated work
  Sleep(Random(300) + 100);
  WriteLn('[Worker ', FWorkerId, '] Phase 2 completed');
  
  // Wait for all workers to complete Phase 2
  WriteLn('[Worker ', FWorkerId, '] Waiting for all workers to complete Phase 2...');
  if FPhase2Complete.WaitFor(3000) <> wrSignaled then
  begin
    WriteLn('[Worker ', FWorkerId, '] Timeout waiting for Phase 2 completion');
    Exit;
  end;
  
  WriteLn('[Worker ', FWorkerId, '] All phases completed, finishing...');
end;

procedure RunCoordinationDemo;
const
  WORKER_COUNT = 4;
var
  Workers: array[0..WORKER_COUNT-1] of TCoordinatedWorker;
  StartEvent, Phase1Complete, Phase2Complete, Shutdown: IEvent;
  i: Integer;
  Phase1Counter, Phase2Counter: Integer;
begin
  WriteLn('=== Thread Coordination Demo ===');
  WriteLn('Creating ', WORKER_COUNT, ' coordinated workers...');
  
  // Create coordination events
  StartEvent := MakeEvent(True, False);      // Manual-reset: broadcast to all
  Phase1Complete := MakeEvent(True, False);  // Manual-reset: broadcast to all
  Phase2Complete := MakeEvent(True, False);  // Manual-reset: broadcast to all
  Shutdown := MakeEvent(True, False);        // Manual-reset: broadcast to all
  
  Phase1Counter := 0;
  Phase2Counter := 0;
  
  try
    // Create worker threads
    for i := 0 to WORKER_COUNT - 1 do
    begin
      Workers[i] := TCoordinatedWorker.Create(
        i + 1, StartEvent, Phase1Complete, Phase2Complete, Shutdown
      );
    end;
    
    WriteLn('All workers created, waiting a moment...');
    Sleep(500);
    
    // Start all workers simultaneously
    WriteLn('Starting all workers...');
    StartEvent.SetEvent;
    
    // Monitor Phase 1 completion
    WriteLn('Monitoring Phase 1 completion...');
    while Phase1Counter < WORKER_COUNT do
    begin
      Sleep(100);
      // In a real scenario, you'd have a proper counter mechanism
      // This is simplified for demonstration
      Inc(Phase1Counter);
    end;
    
    WriteLn('All workers should have completed Phase 1, signaling...');
    Phase1Complete.SetEvent;
    
    // Monitor Phase 2 completion
    WriteLn('Monitoring Phase 2 completion...');
    Sleep(1000); // Simulate monitoring time
    
    WriteLn('All workers should have completed Phase 2, signaling...');
    Phase2Complete.SetEvent;
    
    // Wait for all workers to complete
    WriteLn('Waiting for all workers to finish...');
    for i := 0 to WORKER_COUNT - 1 do
    begin
      if Workers[i].WaitFor <> 0 then
        WriteLn('Worker ', i + 1, ' finished with error')
      else
        WriteLn('Worker ', i + 1, ' finished successfully');
    end;
    
  finally
    // Clean up
    Shutdown.SetEvent;
    for i := 0 to WORKER_COUNT - 1 do
      Workers[i].Free;
  end;
  
  WriteLn('Thread coordination demo completed');
  WriteLn;
end;

procedure RunTimeoutDemo;
var
  Event: IEvent;
  StartTime: QWord;
  Result: TWaitResult;
begin
  WriteLn('=== Timeout Handling Demo ===');
  
  Event := MakeEvent(False, False);
  
  WriteLn('Testing various timeout scenarios...');
  
  // Test 1: Short timeout
  WriteLn('Test 1: 100ms timeout on non-signaled event');
  StartTime := GetTickCount64;
  Result := Event.WaitFor(100);
  WriteLn('Result: ', IfThen(Result = wrTimeout, 'timeout', 'signaled'), 
          ', elapsed: ', GetTickCount64 - StartTime, 'ms');
  
  // Test 2: Zero timeout (immediate)
  WriteLn('Test 2: Zero timeout (TryWait equivalent)');
  StartTime := GetTickCount64;
  Result := Event.WaitFor(0);
  WriteLn('Result: ', IfThen(Result = wrTimeout, 'timeout', 'signaled'), 
          ', elapsed: ', GetTickCount64 - StartTime, 'ms');
  
  // Test 3: Signal and immediate wait
  WriteLn('Test 3: Signal event and wait immediately');
  Event.SetEvent;
  StartTime := GetTickCount64;
  Result := Event.WaitFor(100);
  WriteLn('Result: ', IfThen(Result = wrSignaled, 'signaled', 'timeout'), 
          ', elapsed: ', GetTickCount64 - StartTime, 'ms');
  
  WriteLn('Timeout demo completed');
  WriteLn;
end;

begin
  WriteLn('fafafa.core.sync.event Thread Coordination Example');
  WriteLn('==================================================');
  WriteLn;
  
  try
    Randomize;
    
    RunCoordinationDemo;
    RunTimeoutDemo;
    
    WriteLn('All demos completed successfully!');
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
