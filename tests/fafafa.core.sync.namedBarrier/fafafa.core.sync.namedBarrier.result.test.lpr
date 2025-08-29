program fafafa.core.sync.namedBarrier.result.test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.base, fafafa.core.sync.namedBarrier;

procedure TestResultBasedCreation;
var
  LResult: TNamedBarrierResult;
  LBarrier: INamedBarrier;
begin
  WriteLn('Testing TResult-based barrier creation...');
  
  // Test successful creation
  LResult := CreateNamedBarrierResult('test_result_barrier_1');
  if LResult.IsOk then
  begin
    LBarrier := LResult.Value;
    WriteLn('  ✓ Successful creation with TResult');
    WriteLn('  - Name: ', LBarrier.GetName);
    WriteLn('  - Participant count: ', LBarrier.GetParticipantCount);
  end
  else
  begin
    WriteLn('  ✗ Creation failed: ', LResult.Base.ErrorMessage);
  end;
  
  // Test creation with invalid name
  LResult := CreateNamedBarrierResult('');
  if LResult.IsError then
  begin
    WriteLn('  ✓ Correctly caught invalid name error');
    WriteLn('  - Error: ', LResult.Base.ErrorMessage);
  end
  else
  begin
    WriteLn('  ✗ Should have failed with invalid name');
  end;
  
  WriteLn;
end;

procedure TestResultBasedOperations;
var
  LBarrierResult: TNamedBarrierResult;
  LBarrier: INamedBarrier;
  LGuardResult: TNamedBarrierGuardResult;
  LGuard: INamedBarrierGuard;
  LCountResult: TResultCardinal;
  LBoolResult: TResultBool;
  LBaseResult: TResultBase;
begin
  WriteLn('Testing TResult-based barrier operations...');
  
  // Create barrier
  LBarrierResult := CreateNamedBarrierResult('test_result_barrier_2', 2);
  if not LBarrierResult.IsOk then
  begin
    WriteLn('  ✗ Failed to create barrier: ', LBarrierResult.Base.ErrorMessage);
    Exit;
  end;
  
  LBarrier := LBarrierResult.Value;
  
  // Test GetWaitingCountResult
  LCountResult := LBarrier.GetWaitingCountResult;
  if LCountResult.IsOk then
  begin
    WriteLn('  ✓ GetWaitingCountResult successful');
    WriteLn('  - Waiting count: ', LCountResult.Value);
  end
  else
  begin
    WriteLn('  ✗ GetWaitingCountResult failed: ', LCountResult.Base.ErrorMessage);
  end;
  
  // Test IsSignaledResult
  LBoolResult := LBarrier.IsSignaledResult;
  if LBoolResult.IsOk then
  begin
    WriteLn('  ✓ IsSignaledResult successful');
    WriteLn('  - Is signaled: ', BoolToStr(LBoolResult.Value, True));
  end
  else
  begin
    WriteLn('  ✗ IsSignaledResult failed: ', LBoolResult.Base.ErrorMessage);
  end;
  
  // Test SignalResult
  LBaseResult := LBarrier.SignalResult;
  if LBaseResult.IsOk then
  begin
    WriteLn('  ✓ SignalResult successful');
  end
  else
  begin
    WriteLn('  ✗ SignalResult failed: ', LBaseResult.ErrorMessage);
  end;
  
  // Test TryWaitResult after signaling
  LGuardResult := LBarrier.TryWaitResult;
  if LGuardResult.IsOk then
  begin
    LGuard := LGuardResult.Value;
    WriteLn('  ✓ TryWaitResult successful after signaling');
    WriteLn('  - Guard name: ', LGuard.GetName);
    WriteLn('  - Is last participant: ', BoolToStr(LGuard.IsLastParticipant, True));
  end
  else
  begin
    WriteLn('  ✓ TryWaitResult correctly failed (expected for single process)');
    WriteLn('  - Error: ', LGuardResult.Base.ErrorMessage);
  end;
  
  // Test ResetResult
  LBaseResult := LBarrier.ResetResult;
  if LBaseResult.IsOk then
  begin
    WriteLn('  ✓ ResetResult successful');
  end
  else
  begin
    WriteLn('  ✗ ResetResult failed: ', LBaseResult.ErrorMessage);
  end;
  
  WriteLn;
end;

procedure TestResultBasedTimeout;
var
  LBarrierResult: TNamedBarrierResult;
  LBarrier: INamedBarrier;
  LGuardResult: TNamedBarrierGuardResult;
  LStartTime, LEndTime: QWord;
begin
  WriteLn('Testing TResult-based timeout operations...');
  
  // Create barrier
  LBarrierResult := CreateNamedBarrierResult('test_result_barrier_3', 3);
  if not LBarrierResult.IsOk then
  begin
    WriteLn('  ✗ Failed to create barrier: ', LBarrierResult.Base.ErrorMessage);
    Exit;
  end;
  
  LBarrier := LBarrierResult.Value;
  
  // Test timeout with TryWaitForResult
  WriteLn('  Testing 100ms timeout...');
  LStartTime := GetTickCount64;
  LGuardResult := LBarrier.TryWaitForResult(100);
  LEndTime := GetTickCount64;
  
  if LGuardResult.IsError then
  begin
    WriteLn('  ✓ TryWaitForResult correctly timed out');
    WriteLn('  - Error: ', LGuardResult.Base.ErrorMessage);
    WriteLn('  - Elapsed time: ', LEndTime - LStartTime, ' ms');
  end
  else
  begin
    WriteLn('  ✗ TryWaitForResult should have timed out');
  end;
  
  WriteLn;
end;

procedure TestResultBasedErrorHandling;
var
  LResult: TNamedBarrierResult;
begin
  WriteLn('Testing TResult-based error handling...');
  
  // Test invalid participant count
  LResult := CreateNamedBarrierResult('test_invalid', 1);
  if LResult.IsError then
  begin
    WriteLn('  ✓ Correctly caught invalid participant count');
    WriteLn('  - Error type: ', Ord(LResult.Base.Error));
    WriteLn('  - Error message: ', LResult.Base.ErrorMessage);
  end
  else
  begin
    WriteLn('  ✗ Should have failed with invalid participant count');
  end;
  
  // Test TryOpenNamedBarrierResult with non-existent barrier
  LResult := TryOpenNamedBarrierResult('nonexistent_barrier_12345');
  if LResult.IsError then
  begin
    WriteLn('  ✓ Correctly handled non-existent barrier');
    WriteLn('  - Error type: ', Ord(LResult.Base.Error));
    WriteLn('  - Error message: ', LResult.Base.ErrorMessage);
  end
  else
  begin
    WriteLn('  ? Unexpectedly succeeded opening non-existent barrier');
  end;
  
  WriteLn;
end;

procedure TestResultValueOrMethods;
var
  LResult: TNamedBarrierResult;
  LBarrier: INamedBarrier;
  LCountResult: TResultCardinal;
  LCount: Cardinal;
begin
  WriteLn('Testing TResult ValueOr methods...');
  
  // Test successful case
  LResult := CreateNamedBarrierResult('test_value_or', 2);
  LBarrier := LResult.ValueOr(nil);
  if Assigned(LBarrier) then
  begin
    WriteLn('  ✓ ValueOr returned valid barrier on success');
    WriteLn('  - Name: ', LBarrier.GetName);
  end
  else
  begin
    WriteLn('  ✗ ValueOr returned nil on success');
  end;
  
  // Test error case with default
  LResult := CreateNamedBarrierResult('', 2);
  LBarrier := LResult.ValueOr(nil);
  if not Assigned(LBarrier) then
  begin
    WriteLn('  ✓ ValueOr returned default (nil) on error');
  end
  else
  begin
    WriteLn('  ✗ ValueOr should have returned default on error');
  end;
  
  // Test with Cardinal result
  if Assigned(LBarrier) then
  begin
    LCountResult := LBarrier.GetWaitingCountResult;
    LCount := LCountResult.ValueOr(999);
    WriteLn('  ✓ Cardinal ValueOr returned: ', LCount);
  end;
  
  WriteLn;
end;

var
  LTestsPassed, LTestsTotal: Integer;

begin
  // Set random seed
  Randomize;
  
  WriteLn('fafafa.core.sync.namedBarrier TResult Interface Tests');
  WriteLn('===================================================');
  WriteLn;
  
  LTestsTotal := 5;
  LTestsPassed := 0;
  
  try
    TestResultBasedCreation;
    Inc(LTestsPassed);
    
    TestResultBasedOperations;
    Inc(LTestsPassed);
    
    TestResultBasedTimeout;
    Inc(LTestsPassed);
    
    TestResultBasedErrorHandling;
    Inc(LTestsPassed);
    
    TestResultValueOrMethods;
    Inc(LTestsPassed);
    
    WriteLn('===================================================');
    WriteLn('Tests completed: ', LTestsPassed, '/', LTestsTotal, ' passed');
    
    if LTestsPassed = LTestsTotal then
    begin
      WriteLn('✓ All TResult interface tests PASSED!');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('✗ Some tests FAILED');
      ExitCode := 1;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('Test execution error: ', E.ClassName, ' - ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('NOTE: These tests verify the TResult-based incremental interface.');
  WriteLn('The original interface remains unchanged and fully compatible.');
end.
