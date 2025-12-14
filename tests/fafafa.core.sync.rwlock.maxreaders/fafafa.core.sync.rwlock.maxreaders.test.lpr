program fafafa.core.sync.rwlock.maxreaders.test;

{**
 * TDD Tests for RWLock MaxReaders limit
 *
 * Following TDD: Red -> Green -> Refactor
 *}

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.rwlock,
  fafafa.core.sync.rwlock.base,
  fafafa.core.sync.builder;

var
  TestCount: Integer = 0;
  PassCount: Integer = 0;
  FailCount: Integer = 0;

procedure Check(ACondition: Boolean; const ATestName: string);
begin
  Inc(TestCount);
  if ACondition then
  begin
    Inc(PassCount);
    WriteLn('[PASS] ', ATestName);
  end
  else
  begin
    Inc(FailCount);
    WriteLn('[FAIL] ', ATestName);
  end;
end;

// ========== MaxReaders Configuration Tests ==========

procedure Test_RWLock_GetMaxReaders_ReturnsConfiguredValue;
var
  Options: TRWLockOptions;
  RWLock: IRWLock;
begin
  // Arrange
  Options := DefaultRWLockOptions;
  Options.MaxReaders := 100;

  // Act
  RWLock := MakeRWLock(Options);

  // Assert
  Check(RWLock.GetMaxReaders = 100, 'GetMaxReaders returns configured value (100)');
end;

procedure Test_RWLock_GetMaxReaders_DefaultValue;
var
  RWLock: IRWLock;
begin
  // Arrange & Act
  RWLock := MakeRWLock;

  // Assert - Default should be 1024 per TRWLockOptions default
  Check(RWLock.GetMaxReaders = 1024, 'GetMaxReaders returns default value (1024)');
end;

procedure Test_RWLockBuilder_WithMaxReaders_ConfiguresCorrectly;
var
  RWLock: IRWLock;
begin
  // Arrange & Act
  RWLock := RWLockBuilder.WithMaxReaders(50).Build;

  // Assert
  Check(RWLock.GetMaxReaders = 50, 'RWLockBuilder.WithMaxReaders configures correctly (50)');
end;

// ========== MaxReaders Boundary Behavior Tests ==========

procedure Test_RWLock_AcquireRead_SucceedsUnderLimit;
var
  Options: TRWLockOptions;
  RWLock: IRWLock;
  i: Integer;
begin
  // Arrange - Very small limit for testing
  Options := DefaultRWLockOptions;
  Options.MaxReaders := 3;
  RWLock := MakeRWLock(Options);

  // Act - Acquire up to limit
  for i := 1 to 3 do
    RWLock.AcquireRead;

  // Assert
  Check(RWLock.GetReaderCount = 3, 'AcquireRead succeeds up to MaxReaders limit');

  // Cleanup
  for i := 1 to 3 do
    RWLock.ReleaseRead;
end;

procedure Test_RWLock_TryAcquireRead_FailsAtLimit;
var
  Options: TRWLockOptions;
  RWLock: IRWLock;
  i: Integer;
  Result: Boolean;
begin
  // Arrange - Small limit
  Options := DefaultRWLockOptions;
  Options.MaxReaders := 2;
  RWLock := MakeRWLock(Options);

  // Act - Acquire to limit
  RWLock.AcquireRead;
  RWLock.AcquireRead;

  // Try to acquire one more (should fail)
  Result := RWLock.TryAcquireRead(0);

  // Assert
  Check(not Result, 'TryAcquireRead fails when at MaxReaders limit');
  Check(RWLock.GetReaderCount = 2, 'Reader count stays at limit');

  // Cleanup
  RWLock.ReleaseRead;
  RWLock.ReleaseRead;
end;

procedure Test_RWLock_TryAcquireRead_SucceedsAfterRelease;
var
  Options: TRWLockOptions;
  RWLock: IRWLock;
  Result: Boolean;
begin
  // Arrange - Small limit
  Options := DefaultRWLockOptions;
  Options.MaxReaders := 2;
  RWLock := MakeRWLock(Options);

  // Fill to limit
  RWLock.AcquireRead;
  RWLock.AcquireRead;

  // Release one
  RWLock.ReleaseRead;

  // Act - Try to acquire (should succeed now)
  Result := RWLock.TryAcquireRead(0);

  // Assert
  Check(Result, 'TryAcquireRead succeeds after release');
  Check(RWLock.GetReaderCount = 2, 'Reader count back at limit');

  // Cleanup
  RWLock.ReleaseRead;
  RWLock.ReleaseRead;
end;

// ========== Main ==========

begin
  WriteLn('=== RWLock MaxReaders Tests ===');
  WriteLn;

  // Configuration tests
  Test_RWLock_GetMaxReaders_ReturnsConfiguredValue;
  Test_RWLock_GetMaxReaders_DefaultValue;
  Test_RWLockBuilder_WithMaxReaders_ConfiguresCorrectly;

  // Boundary tests
  Test_RWLock_AcquireRead_SucceedsUnderLimit;
  Test_RWLock_TryAcquireRead_FailsAtLimit;
  Test_RWLock_TryAcquireRead_SucceedsAfterRelease;

  WriteLn;
  WriteLn('=== Results ===');
  WriteLn('Total: ', TestCount, ' | Pass: ', PassCount, ' | Fail: ', FailCount);

  if FailCount > 0 then
    Halt(1);
end.
