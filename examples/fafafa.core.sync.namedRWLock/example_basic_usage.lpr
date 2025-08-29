program example_basic_usage;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.namedRWLock;

procedure DemonstrateBasicUsage;
var
  LRWLock: INamedRWLock;
  LReadGuard: INamedRWLockReadGuard;
  LWriteGuard: INamedRWLockWriteGuard;
begin
  WriteLn('=== Basic Usage Demo ===');

  // Create named read-write lock
  LRWLock := MakeNamedRWLock('example_basic');
  WriteLn('Created named RWLock: ', LRWLock.GetName);

  // Modern RAII pattern - read lock
  WriteLn('Acquiring read lock...');
  LReadGuard := LRWLock.ReadLock;
  try
    WriteLn('Successfully acquired read lock, current reader count: ', LRWLock.GetReaderCount);
    WriteLn('Performing read operation...');
    Sleep(100); // Simulate read operation
  finally
    LReadGuard := nil; // Auto-release read lock
    WriteLn('Read lock automatically released');
  end;

  // Modern RAII pattern - write lock
  WriteLn('Acquiring write lock...');
  LWriteGuard := LRWLock.WriteLock;
  try
    WriteLn('Successfully acquired write lock, write lock status: ', LRWLock.IsWriteLocked);
    WriteLn('Performing write operation...');
    Sleep(100); // Simulate write operation
  finally
    LWriteGuard := nil; // Auto-release write lock
    WriteLn('Write lock automatically released');
  end;

  WriteLn('Basic usage demo completed');
  WriteLn;
end;

procedure DemonstrateTraditionalAPI;
var
  LRWLock: INamedRWLock;
begin
  WriteLn('=== Traditional API Demo ===');

  LRWLock := MakeNamedRWLock('example_traditional');
  WriteLn('Created named RWLock: ', LRWLock.GetName);

  // Traditional read lock API
  WriteLn('Using traditional API to acquire read lock...');
  LRWLock.AcquireRead;
  try
    WriteLn('Successfully acquired read lock, current reader count: ', LRWLock.GetReaderCount);
    WriteLn('Performing read operation...');
    Sleep(100);
  finally
    LRWLock.ReleaseRead;
    WriteLn('Read lock released');
  end;

  // Traditional write lock API
  WriteLn('Using traditional API to acquire write lock...');
  LRWLock.AcquireWrite;
  try
    WriteLn('Successfully acquired write lock, write lock status: ', LRWLock.IsWriteLocked);
    WriteLn('Performing write operation...');
    Sleep(100);
  finally
    LRWLock.ReleaseWrite;
    WriteLn('Write lock released');
  end;

  WriteLn('Traditional API demo completed');
  WriteLn;
end;

procedure DemonstrateNonBlockingTry;
var
  LRWLock: INamedRWLock;
  LReadGuard: INamedRWLockReadGuard;
  LWriteGuard: INamedRWLockWriteGuard;
begin
  WriteLn('=== Non-blocking Try Demo ===');

  LRWLock := MakeNamedRWLock('example_nonblocking');
  WriteLn('Created named RWLock: ', LRWLock.GetName);

  // Non-blocking read lock try
  WriteLn('Trying to acquire read lock non-blocking...');
  LReadGuard := LRWLock.TryReadLock;
  if Assigned(LReadGuard) then
  begin
    WriteLn('Successfully acquired read lock');
    LReadGuard := nil;
    WriteLn('Read lock released');
  end
  else
    WriteLn('Could not acquire read lock');

  // Non-blocking write lock try
  WriteLn('Trying to acquire write lock non-blocking...');
  LWriteGuard := LRWLock.TryWriteLock;
  if Assigned(LWriteGuard) then
  begin
    WriteLn('Successfully acquired write lock');
    LWriteGuard := nil;
    WriteLn('Write lock released');
  end
  else
    WriteLn('Could not acquire write lock');

  WriteLn('Non-blocking try demo completed');
  WriteLn;
end;

procedure DemonstrateTimeoutControl;
var
  LRWLock: INamedRWLock;
  LReadGuard: INamedRWLockReadGuard;
  LWriteGuard: INamedRWLockWriteGuard;
begin
  WriteLn('=== Timeout Control Demo ===');

  LRWLock := MakeNamedRWLock('example_timeout');
  WriteLn('Created named RWLock: ', LRWLock.GetName);

  // Timed read lock acquisition
  WriteLn('Trying to acquire read lock within 1000ms...');
  LReadGuard := LRWLock.TryReadLockFor(1000);
  if Assigned(LReadGuard) then
  begin
    WriteLn('Successfully acquired read lock within timeout');
    LReadGuard := nil;
    WriteLn('Read lock released');
  end
  else
    WriteLn('Timeout, could not acquire read lock');

  // Timed write lock acquisition
  WriteLn('Trying to acquire write lock within 1000ms...');
  LWriteGuard := LRWLock.TryWriteLockFor(1000);
  if Assigned(LWriteGuard) then
  begin
    WriteLn('Successfully acquired write lock within timeout');
    LWriteGuard := nil;
    WriteLn('Write lock released');
  end
  else
    WriteLn('Timeout, could not acquire write lock');

  WriteLn('Timeout control demo completed');
  WriteLn;
end;

procedure DemonstrateMultipleReaders;
var
  LRWLock: INamedRWLock;
  LReadGuard1, LReadGuard2, LReadGuard3: INamedRWLockReadGuard;
begin
  WriteLn('=== Multiple Readers Demo ===');

  LRWLock := MakeNamedRWLock('example_multiple_readers');
  WriteLn('Created named RWLock: ', LRWLock.GetName);

  // Acquire multiple read locks
  WriteLn('Acquiring first read lock...');
  LReadGuard1 := LRWLock.ReadLock;
  WriteLn('Current reader count: ', LRWLock.GetReaderCount);

  WriteLn('Acquiring second read lock...');
  LReadGuard2 := LRWLock.ReadLock;
  WriteLn('Current reader count: ', LRWLock.GetReaderCount);

  WriteLn('Acquiring third read lock...');
  LReadGuard3 := LRWLock.ReadLock;
  WriteLn('Current reader count: ', LRWLock.GetReaderCount);

  WriteLn('All readers performing read operations simultaneously...');
  Sleep(200);

  // Release read locks one by one
  WriteLn('Releasing first read lock...');
  LReadGuard1 := nil;
  WriteLn('Current reader count: ', LRWLock.GetReaderCount);

  WriteLn('Releasing second read lock...');
  LReadGuard2 := nil;
  WriteLn('Current reader count: ', LRWLock.GetReaderCount);

  WriteLn('Releasing third read lock...');
  LReadGuard3 := nil;
  WriteLn('Current reader count: ', LRWLock.GetReaderCount);

  WriteLn('Multiple readers demo completed');
  WriteLn;
end;

procedure DemonstrateReaderWriterExclusion;
var
  LRWLock: INamedRWLock;
  LReadGuard: INamedRWLockReadGuard;
  LWriteGuard: INamedRWLockWriteGuard;
begin
  WriteLn('=== Reader-Writer Exclusion Demo ===');

  LRWLock := MakeNamedRWLock('example_exclusion');
  WriteLn('Created named RWLock: ', LRWLock.GetName);

  // First acquire read lock
  WriteLn('Acquiring read lock...');
  LReadGuard := LRWLock.ReadLock;
  WriteLn('Successfully acquired read lock, current reader count: ', LRWLock.GetReaderCount);

  // Try to acquire write lock while holding read lock
  WriteLn('Trying to acquire write lock while holding read lock...');
  LWriteGuard := LRWLock.TryWriteLock;
  if Assigned(LWriteGuard) then
  begin
    WriteLn('Unexpected: acquired write lock while holding read lock!');
    LWriteGuard := nil;
  end
  else
    WriteLn('Correct: cannot acquire write lock while holding read lock');

  // Release read lock
  WriteLn('Releasing read lock...');
  LReadGuard := nil;
  WriteLn('Read lock released');

  // Now try to acquire write lock
  WriteLn('Now trying to acquire write lock...');
  LWriteGuard := LRWLock.TryWriteLock;
  if Assigned(LWriteGuard) then
  begin
    WriteLn('Successfully acquired write lock');
    WriteLn('Write lock status: ', LRWLock.IsWriteLocked);

    // Try to acquire read lock while holding write lock
    WriteLn('Trying to acquire read lock while holding write lock...');
    LReadGuard := LRWLock.TryReadLock;
    if Assigned(LReadGuard) then
    begin
      WriteLn('Unexpected: acquired read lock while holding write lock!');
      LReadGuard := nil;
    end
    else
      WriteLn('Correct: cannot acquire read lock while holding write lock');

    LWriteGuard := nil;
    WriteLn('Write lock released');
  end
  else
    WriteLn('Could not acquire write lock');

  WriteLn('Reader-writer exclusion demo completed');
  WriteLn;
end;

procedure DemonstrateGlobalNamespace;
var
  LRWLock: INamedRWLock;
  LReadGuard: INamedRWLockReadGuard;
begin
  WriteLn('=== Global Namespace Demo ===');

  // Create global named read-write lock
  LRWLock := MakeGlobalNamedRWLock('example_global');
  WriteLn('Created global named RWLock: ', LRWLock.GetName);

  // Use global lock
  WriteLn('Acquiring global read lock...');
  LReadGuard := LRWLock.ReadLock;
  try
    WriteLn('Successfully acquired global read lock');
    WriteLn('This lock can be accessed across sessions (Windows) or processes (Unix)');
    Sleep(100);
  finally
    LReadGuard := nil;
    WriteLn('Global read lock released');
  end;

  WriteLn('Global namespace demo completed');
  WriteLn;
end;

begin
  try
    WriteLn('fafafa.core.sync.namedRWLock Basic Usage Examples');
    WriteLn('=================================================');
    WriteLn;
    
    DemonstrateBasicUsage;
    DemonstrateTraditionalAPI;
    DemonstrateNonBlockingTry;
    DemonstrateTimeoutControl;
    DemonstrateMultipleReaders;
    DemonstrateReaderWriterExclusion;
    DemonstrateGlobalNamespace;
    
    WriteLn('All demos completed!');
    WriteLn('Press Enter to exit...');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn('Exception occurred: ', E.ClassName, ': ', E.Message);
      WriteLn('Press Enter to exit...');
      ReadLn;
    end;
  end;
end.
