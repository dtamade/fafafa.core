program test_mutex;

{$I fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.sync.mutex;

type
  TTestThread = class(TThread)
  private
    FMutex: IMutex;
    FSharedCounter: PInteger;
    FTestThreadID: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IMutex; ACounter: PInteger; AThreadID: Integer);
  end;

constructor TTestThread.Create(AMutex: IMutex; ACounter: PInteger; AThreadID: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FMutex := AMutex;
  FSharedCounter := ACounter;
  FTestThreadID := AThreadID;
end;

procedure TTestThread.Execute;
var
  i: Integer;
  LocalValue: Integer;
begin
  for i := 1 to 1000 do
  begin
    // Acquire the mutex
    FMutex.Acquire;
    try
      // Critical section: modify shared counter
      LocalValue := FSharedCounter^;
      Inc(LocalValue);
      // Small delay to increase chance of race condition without mutex
      Sleep(0);
      FSharedCounter^ := LocalValue;
    finally
      // Always release
      FMutex.Release;
    end;
  end;
end;

procedure TestBasicMutex;
var
  Mutex: IMutex;
  SharedCounter: Integer;
  Threads: array[0..9] of TTestThread;
  i: Integer;
begin
  WriteLn('=== Testing Basic Mutex ===');
  WriteLn('10 threads incrementing shared counter 1000 times each');
  WriteLn;
  
  Mutex := MakeMutex;
  SharedCounter := 0;
  
  // Create and start threads
  for i := 0 to 9 do
  begin
    Threads[i] := TTestThread.Create(Mutex, @SharedCounter, i + 1);
    Threads[i].Start;
  end;
  
  // Wait for all threads to complete
  for i := 0 to 9 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  WriteLn('Expected counter value: 10000');
  WriteLn('Actual counter value: ', SharedCounter);
  
  if SharedCounter = 10000 then
    WriteLn('[OK] Mutex test PASSED')
  else
    WriteLn('[FAIL] Mutex test FAILED - race condition detected!');
  
  WriteLn;
end;

procedure TestTryAcquire;
var
  Mutex: IMutex;
  Success: Boolean;
begin
  WriteLn('=== Testing TryAcquire ===');
  WriteLn;
  
  Mutex := MakeMutex;
  
  // Test 1: TryAcquire on unlocked mutex should succeed
  Success := Mutex.TryAcquire;
  WriteLn('TryAcquire on unlocked mutex: ', Success);
  
  if Success then
  begin
    WriteLn('Note: This mutex is non-reentrant, cannot test from same thread');
    
    // Release the mutex
    Mutex.Release;
    WriteLn('Mutex released');
  end;
  
  // Test 2: TryAcquire with timeout 0 (immediate)
  Success := Mutex.TryAcquire(0);
  WriteLn('TryAcquire(0) on unlocked mutex: ', Success);
  
  if Success then
    Mutex.Release;
  
  WriteLn;
end;

type
  TLockThread = class(TThread)
  private
    FMutex: IMutex;
  protected
    procedure Execute; override;
  public
    constructor Create(AMutex: IMutex);
  end;

constructor TLockThread.Create(AMutex: IMutex);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FMutex := AMutex;
end;

procedure TLockThread.Execute;
begin
  FMutex.Acquire;
  Sleep(2000);
  FMutex.Release;
end;

procedure TestTryAcquireTimeout;
var
  Mutex: IMutex;
  LockThread: TLockThread;
  StartTime, EndTime: TDateTime;
  Success: Boolean;
begin
  WriteLn('=== Testing TryAcquire with Timeout ===');
  WriteLn;
  
  Mutex := MakeMutex;
  
  // Create a thread that holds the lock for 2 seconds
  LockThread := TLockThread.Create(Mutex);
  LockThread.Start;
  Sleep(100); // Give thread time to acquire lock
  
  // Try to acquire with 1 second timeout (should fail)
  WriteLn('Trying to acquire locked mutex with 1 second timeout...');
  StartTime := Now;
  Success := Mutex.TryAcquire(1000);
  EndTime := Now;
  
  WriteLn('Result: ', not Success, ' (should be false)');
  WriteLn('Time elapsed: ', FormatDateTime('ss.zzz', EndTime - StartTime), ' seconds');
  
  LockThread.WaitFor;
  LockThread.Free;
  
  // Now try with no lock (should succeed immediately)
  WriteLn;
  WriteLn('Trying to acquire unlocked mutex with 1 second timeout...');
  StartTime := Now;
  Success := Mutex.TryAcquire(1000);
  EndTime := Now;
  
  WriteLn('Result: ', Success, ' (should be true)');
  WriteLn('Time elapsed: ', FormatDateTime('ss.zzz', EndTime - StartTime), ' seconds');
  
  if Success then
    Mutex.Release;
  
  WriteLn;
end;

begin
  WriteLn('Mutex Synchronization Primitive Test');
  WriteLn('=====================================');
  WriteLn;
  
  TestBasicMutex;
  TestTryAcquire;
  TestTryAcquireTimeout;
  
  WriteLn('All tests completed!');
  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
end.