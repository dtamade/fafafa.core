program test_semaphore;

{$I fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.sync.sem;

type
  // Worker thread for testing semaphore as resource limiter
  TWorkerThread = class(TThread)
  private
    FSemaphore: ISem;
    FWorkerId: Integer;
    FWorkTime: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ASemaphore: ISem; AWorkerId: Integer; AWorkTime: Integer);
  end;

constructor TWorkerThread.Create(ASemaphore: ISem; AWorkerId: Integer; AWorkTime: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FSemaphore := ASemaphore;
  FWorkerId := AWorkerId;
  FWorkTime := AWorkTime;
end;

procedure TWorkerThread.Execute;
begin
  WriteLn('[Worker ', FWorkerId, '] Waiting for resource...');
  
  // Wait for semaphore (acquire resource)
  FSemaphore.Acquire;
  try
    WriteLn('[Worker ', FWorkerId, '] Got resource, working for ', FWorkTime, 'ms...');
    Sleep(FWorkTime);
    WriteLn('[Worker ', FWorkerId, '] Work done, releasing resource');
  finally
    // Release semaphore (return resource)
    FSemaphore.Release;
  end;
end;

procedure TestBasicSemaphore;
var
  Sem: ISem;
  Workers: array[0..4] of TWorkerThread;
  i: Integer;
begin
  WriteLn('=== Testing Basic Semaphore (max 2 concurrent) ===');
  WriteLn('5 workers competing for 2 resources');
  WriteLn;
  
// Create semaphore with initial count of 2 (2 resources available)
  Sem := MakeSem(2, 2);
  
  // Create and start 5 worker threads
  for i := 0 to 4 do
  begin
    Workers[i] := TWorkerThread.Create(Sem, i + 1, 500 + i * 100);
    Workers[i].Start;
  end;
  
  // Wait for all workers to complete
  for i := 0 to 4 do
  begin
    Workers[i].WaitFor;
    Workers[i].Free;
  end;
  
  WriteLn;
  WriteLn('All workers completed');
  WriteLn;
end;

procedure TestSemaphoreAsSignal;
var
  Sem: ISem;
  ProducerThread, ConsumerThread: TThread;
  SharedData: Integer;
begin
  WriteLn('=== Testing Semaphore as Signal ===');
  WriteLn('Producer-Consumer pattern with semaphore');
  WriteLn;
  
// Create semaphore with initial count of 0 (no signal)
  Sem := MakeSem(0, 1);
  SharedData := 0;
  
  // Consumer thread
  ConsumerThread := TThread.CreateAnonymousThread(
    procedure
    begin
      WriteLn('[Consumer] Waiting for data...');
      Sem.Acquire;  // Wait for producer signal
      WriteLn('[Consumer] Got signal, data = ', SharedData);
    end
  );
  
  // Producer thread
  ProducerThread := TThread.CreateAnonymousThread(
    procedure
    begin
      WriteLn('[Producer] Preparing data...');
      Sleep(1000);
      SharedData := 42;
      WriteLn('[Producer] Data ready, signaling consumer');
      Sem.Release;  // Signal consumer
    end
  );
  
  ConsumerThread.Start;
  ProducerThread.Start;
  
  ProducerThread.WaitFor;
  ConsumerThread.WaitFor;
  
  ProducerThread.Free;
  ConsumerThread.Free;
  
  WriteLn;
end;

procedure TestTryAcquire;
var
  Sem: ISem;
  Success: Boolean;
  StartTime, EndTime: TDateTime;
begin
  WriteLn('=== Testing TryAcquire ===');
  WriteLn;
  
// Create semaphore with count of 1
  Sem := MakeSem(1, 1);
  
// First try should succeed
  Success := Sem.TryAcquire(0);
  WriteLn('TryAcquire on available semaphore: ', Success);
  
// Second try should fail (count is 0)
  Success := Sem.TryAcquire(0);
  WriteLn('TryAcquire on exhausted semaphore: ', not Success);
  
  // Release once
  Sem.Release;
  
// Now try should succeed again
  Success := Sem.TryAcquire(0);
  WriteLn('TryAcquire after release: ', Success);
  
  if Success then
    Sem.Release;
  
  WriteLn;
  
  // Test with timeout
  WriteLn('Testing TryAcquire with timeout...');
  
  // Acquire the semaphore
  Sem.Acquire;
  
  // Try to acquire with 500ms timeout (should fail)
  StartTime := Now;
  Success := Sem.TryAcquire(500);
  EndTime := Now;
  
  WriteLn('TryAcquire(500ms) on exhausted semaphore: ', not Success);
  WriteLn('Time elapsed: ', FormatDateTime('ss.zzz', EndTime - StartTime), ' seconds');
  
  // Release
  Sem.Release;
  
  WriteLn;
end;

procedure TestMultipleRelease;
var
  Sem: ISem;
  i: Integer;
  Success: Boolean;
begin
  WriteLn('=== Testing Multiple Release ===');
  WriteLn;
  
// Create semaphore with initial count of 0
  Sem := MakeSem(0, 3);
  
  // Release 3 times
  WriteLn('Releasing 3 times...');
  for i := 1 to 3 do
  begin
    Sem.Release;
    WriteLn('Released ', i);
  end;
  
  // Now we should be able to acquire 3 times
  WriteLn;
  WriteLn('Acquiring 3 times...');
for i := 1 to 3 do
  begin
    Success := Sem.TryAcquire(0);
    WriteLn('Acquire ', i, ': ', Success);
  end;
  
// 4th acquire should fail
  Success := Sem.TryAcquire(0);
  WriteLn('Acquire 4 (should fail): ', not Success);
  
  WriteLn;
end;

begin
  WriteLn('Semaphore Synchronization Primitive Test');
  WriteLn('=========================================');
  WriteLn;
  
  TestBasicSemaphore;
  TestSemaphoreAsSignal;
  TestTryAcquire;
  TestMultipleRelease;
  
  WriteLn('All tests completed!');
  WriteLn;
end.
