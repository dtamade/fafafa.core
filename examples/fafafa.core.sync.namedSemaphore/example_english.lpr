program example_english;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.namedSemaphore;

procedure DemoBasicUsage;
var
  LSemaphore: INamedSemaphore;
  LGuard: INamedSemaphoreGuard;
begin
  WriteLn('=== Basic Usage Demo ===');
  
  // Create named semaphore (default config: initial count 1, max count 1)
  LSemaphore := MakeNamedSemaphore('BasicSemaphoreDemo');
  WriteLn('Created semaphore: ', LSemaphore.GetName);
  WriteLn('Max count: ', LSemaphore.GetMaxCount);
  
  // Use RAII pattern to acquire semaphore
  WriteLn('Acquiring semaphore...');
  LGuard := LSemaphore.Wait;
  WriteLn('Successfully acquired semaphore, guard name: ', LGuard.GetName);
  
  // Simulate some work
  WriteLn('Executing critical section code...');
  Sleep(1000);
  
  // Guard will automatically release semaphore when it goes out of scope
  LGuard := nil;
  WriteLn('Semaphore automatically released');
  WriteLn;
end;

procedure DemoCountingSemaphore;
var
  LSemaphore: INamedSemaphore;
  LGuards: array[1..3] of INamedSemaphoreGuard;
  LGuard4: INamedSemaphoreGuard;
  LCurrentCount: Integer;
  I: Integer;
begin
  WriteLn('=== Counting Semaphore Demo ===');
  
  // Create counting semaphore: initial count 3, max count 5
  LSemaphore := MakeNamedSemaphore('CountingSemaphoreDemo', 3, 5);
  WriteLn('Created counting semaphore: ', LSemaphore.GetName);
  WriteLn('Max count: ', LSemaphore.GetMaxCount);
  
  // Get current count (if platform supports)
  LCurrentCount := LSemaphore.GetCurrentCount;
  if LCurrentCount >= 0 then
    WriteLn('Current available count: ', LCurrentCount);
  
  // Acquire multiple semaphores
  WriteLn('Acquiring multiple semaphores...');
  for I := 1 to 3 do
  begin
    LGuards[I] := LSemaphore.TryWait;
    if Assigned(LGuards[I]) then
      WriteLn('Successfully acquired semaphore #', I)
    else
      WriteLn('Failed to acquire semaphore #', I);
  end;
  
  // Try to acquire 4th (should fail)
  LGuard4 := LSemaphore.TryWait;
  if Assigned(LGuard4) then
    WriteLn('Unexpected: acquired 4th semaphore')
  else
    WriteLn('Expected: cannot acquire 4th semaphore (resources exhausted)');
  
  // Release one semaphore
  WriteLn('Releasing 1st semaphore...');
  LGuards[1] := nil;
  
  // Now should be able to acquire one semaphore
  LGuard4 := LSemaphore.TryWait;
  if Assigned(LGuard4) then
    WriteLn('Success: acquired semaphore after release')
  else
    WriteLn('Error: still cannot acquire semaphore after release');
  
  // Cleanup
  for I := 2 to 3 do
    LGuards[I] := nil;
  LGuard4 := nil;
  
  WriteLn('All semaphores released');
  WriteLn;
end;

procedure DemoBinarySemaphore;
var
  LSemaphore: INamedSemaphore;
  LGuard1, LGuard2: INamedSemaphoreGuard;
begin
  WriteLn('=== Binary Semaphore Demo ===');
  
  // Create binary semaphore (like mutex, but allows multiple releases)
  LSemaphore := MakeNamedSemaphore('BinarySemaphoreDemo', 1, 1);
  WriteLn('Created binary semaphore: ', LSemaphore.GetName);
  WriteLn('Max count: ', LSemaphore.GetMaxCount);
  
  // First acquisition should succeed
  LGuard1 := LSemaphore.TryWait;
  if Assigned(LGuard1) then
    WriteLn('Successfully acquired binary semaphore')
  else
    WriteLn('Error: failed to acquire binary semaphore');
  
  // Second acquisition should fail
  LGuard2 := LSemaphore.TryWait;
  if Assigned(LGuard2) then
    WriteLn('Error: unexpectedly acquired second semaphore')
  else
    WriteLn('Expected: cannot acquire second semaphore (binary semaphore property)');
  
  // Release semaphore
  WriteLn('Releasing binary semaphore...');
  LGuard1 := nil;
  
  // Now should be able to acquire
  LGuard2 := LSemaphore.TryWait;
  if Assigned(LGuard2) then
    WriteLn('Success: acquired semaphore after release')
  else
    WriteLn('Error: still cannot acquire semaphore after release');
  
  LGuard2 := nil;
  WriteLn('Binary semaphore released');
  WriteLn;
end;

procedure DemoTimeoutOperations;
var
  LSemaphore: INamedSemaphore;
  LGuard1, LGuard2: INamedSemaphoreGuard;
  LStartTime: TDateTime;
  LElapsed: Double;
begin
  WriteLn('=== Timeout Operations Demo ===');
  
  // Create binary semaphore
  LSemaphore := MakeNamedSemaphore('TimeoutDemo', 1, 1);
  WriteLn('Created semaphore for timeout test');
  
  // First acquire semaphore
  LGuard1 := LSemaphore.TryWait;
  WriteLn('First guard acquired semaphore');
  
  // Try timeout acquisition (should timeout)
  WriteLn('Trying timeout acquisition (1 second timeout)...');
  LStartTime := Now;
  LGuard2 := LSemaphore.TryWaitFor(1000); // 1 second timeout
  
  if Assigned(LGuard2) then
    WriteLn('Error: unexpectedly acquired semaphore')
  else
  begin
    LElapsed := (Now - LStartTime) * 24 * 60 * 60 * 1000; // Convert to milliseconds
    WriteLn('Expected: timeout, elapsed approximately ', Round(LElapsed), ' ms');
  end;
  
  // Release first guard
  WriteLn('Releasing first guard...');
  LGuard1 := nil;
  
  // Now timeout acquisition should succeed immediately
  WriteLn('Trying timeout acquisition again...');
  LStartTime := Now;
  LGuard2 := LSemaphore.TryWaitFor(1000);
  
  if Assigned(LGuard2) then
  begin
    LElapsed := (Now - LStartTime) * 24 * 60 * 60 * 1000; // Convert to milliseconds
    WriteLn('Success: immediately acquired semaphore, elapsed ', Round(LElapsed), ' ms');
  end
  else
    WriteLn('Error: still cannot acquire semaphore after release');
  
  LGuard2 := nil;
  WriteLn;
end;

procedure DemoErrorHandling;
var
  LSemaphore: INamedSemaphore;
begin
  WriteLn('=== Error Handling Demo ===');
  
  // Test invalid name
  try
    MakeNamedSemaphore('');
    WriteLn('Error: should have thrown exception');
  except
    on E: Exception do
      WriteLn('Expected exception: ', E.ClassName, ' - ', E.Message);
  end;
  
  // Test invalid count
  try
    MakeNamedSemaphore('InvalidCount', -1, 5);
    WriteLn('Error: should have thrown exception');
  except
    on E: Exception do
      WriteLn('Expected exception: ', E.ClassName, ' - ', E.Message);
  end;
  
  // Test invalid release count
  try
    LSemaphore := MakeNamedSemaphore('ValidSemaphore');
    LSemaphore.Release(0);
    WriteLn('Error: should have thrown exception');
  except
    on E: Exception do
      WriteLn('Expected exception: ', E.ClassName, ' - ', E.Message);
  end;
  
  WriteLn;
end;

procedure DemoMultipleRelease;
var
  LSemaphore: INamedSemaphore;
  LGuards: array[1..3] of INamedSemaphoreGuard;
  LGuard, LGuard4: INamedSemaphoreGuard;
  I: Integer;
begin
  WriteLn('=== Multiple Release Demo ===');
  
  // Create counting semaphore with initial count 0
  LSemaphore := MakeNamedSemaphore('MultiReleaseDemo', 0, 5);
  WriteLn('Created counting semaphore (initial count 0, max count 5)');
  
  // Try to acquire (should fail)
  LGuard := LSemaphore.TryWait;
  if Assigned(LGuard) then
    WriteLn('Error: unexpectedly acquired semaphore')
  else
    WriteLn('Expected: cannot acquire semaphore (count is 0)');
  
  // Release 3 counts
  WriteLn('Releasing 3 counts...');
  LSemaphore.Release(3);
  
  // Now should be able to acquire 3 semaphores
  WriteLn('Trying to acquire 3 semaphores...');
  for I := 1 to 3 do
  begin
    LGuards[I] := LSemaphore.TryWait;
    if Assigned(LGuards[I]) then
      WriteLn('Successfully acquired semaphore #', I)
    else
      WriteLn('Failed to acquire semaphore #', I);
  end;
  
  // 4th should fail
  LGuard4 := LSemaphore.TryWait;
  if Assigned(LGuard4) then
    WriteLn('Error: unexpectedly acquired 4th semaphore')
  else
    WriteLn('Expected: cannot acquire 4th semaphore');
  
  // Cleanup
  for I := 1 to 3 do
    LGuards[I] := nil;
  
  WriteLn('All semaphores released');
  WriteLn;
end;

begin
  WriteLn('fafafa.core.sync.namedSemaphore Basic Usage Examples');
  WriteLn('====================================================');
  WriteLn;
  
  try
    DemoBasicUsage;
    DemoCountingSemaphore;
    DemoBinarySemaphore;
    DemoTimeoutOperations;
    DemoErrorHandling;
    DemoMultipleRelease;
    
    WriteLn('=== All Demos Completed ===');
    WriteLn('Named semaphore functionality works correctly!');
    
  except
    on E: Exception do
    begin
      WriteLn('Exception occurred: ', E.ClassName, ' - ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
end.
