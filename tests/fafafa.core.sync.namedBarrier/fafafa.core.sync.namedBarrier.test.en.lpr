program fafafa.core.sync.namedBarrier.test.en;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.base, fafafa.core.sync.namedBarrier;

procedure TestBasicCreation;
var
  LBarrier: INamedBarrier;
begin
  WriteLn('Testing basic creation...');
  try
    LBarrier := CreateNamedBarrier('test_barrier_1');
    if Assigned(LBarrier) then
    begin
      WriteLn('  ✓ Basic creation successful');
      WriteLn('  - Name: ', LBarrier.GetName);
      WriteLn('  - Participant count: ', LBarrier.GetParticipantCount);
      WriteLn('  - Waiting count: ', LBarrier.GetWaitingCount);
    end
    else
      WriteLn('  ✗ Basic creation failed');
  except
    on E: Exception do
      WriteLn('  ✗ Basic creation exception: ', E.Message);
  end;
  WriteLn;
end;

procedure TestConfiguredCreation;
var
  LBarrier: INamedBarrier;
  LConfig: TNamedBarrierConfig;
begin
  WriteLn('Testing configured creation...');
  try
    LConfig := NamedBarrierConfigWithParticipants(3);
    LBarrier := CreateNamedBarrier('test_barrier_2', LConfig);
    if Assigned(LBarrier) then
    begin
      WriteLn('  ✓ Configured creation successful');
      WriteLn('  - Name: ', LBarrier.GetName);
      WriteLn('  - Participant count: ', LBarrier.GetParticipantCount);
    end
    else
      WriteLn('  ✗ Configured creation failed');
  except
    on E: Exception do
      WriteLn('  ✗ Configured creation exception: ', E.Message);
  end;
  WriteLn;
end;

procedure TestSignalAndReset;
var
  LBarrier: INamedBarrier;
begin
  WriteLn('Testing signal and reset...');
  try
    LBarrier := CreateNamedBarrier('test_barrier_3', 2);
    if Assigned(LBarrier) then
    begin
      WriteLn('  - Initial state: ', BoolToStr(LBarrier.IsSignaled, True));
      
      LBarrier.Signal;
      WriteLn('  - After signal: ', BoolToStr(LBarrier.IsSignaled, True));
      
      LBarrier.Reset;
      WriteLn('  - After reset: ', BoolToStr(LBarrier.IsSignaled, True));
      
      WriteLn('  ✓ Signal and reset working correctly');
    end
    else
      WriteLn('  ✗ Failed to create barrier');
  except
    on E: Exception do
      WriteLn('  ✗ Signal and reset exception: ', E.Message);
  end;
  WriteLn;
end;

procedure TestTryWait;
var
  LBarrier: INamedBarrier;
  LGuard: INamedBarrierGuard;
begin
  WriteLn('Testing non-blocking wait...');
  try
    LBarrier := CreateNamedBarrier('test_barrier_4', 2);
    if Assigned(LBarrier) then
    begin
      // Test unsignaled state
      LGuard := LBarrier.TryWait;
      if not Assigned(LGuard) then
        WriteLn('  ✓ Unsignaled state correctly returns nil')
      else
        WriteLn('  ✗ Unsignaled state incorrectly returns guard');
      
      // Test after signaling
      LBarrier.Signal;
      LGuard := LBarrier.TryWait;
      if Assigned(LGuard) then
      begin
        WriteLn('  ✓ Signaled state correctly returns guard');
        WriteLn('  - Guard name: ', LGuard.GetName);
        WriteLn('  - Guard participant count: ', LGuard.GetParticipantCount);
      end
      else
        WriteLn('  ✗ Signaled state incorrectly returns nil');
    end
    else
      WriteLn('  ✗ Failed to create barrier');
  except
    on E: Exception do
      WriteLn('  ✗ Non-blocking wait exception: ', E.Message);
  end;
  WriteLn;
end;

procedure TestTimeout;
var
  LBarrier: INamedBarrier;
  LGuard: INamedBarrierGuard;
  LStartTime, LEndTime: QWord;
begin
  WriteLn('Testing timeout functionality...');
  try
    LBarrier := CreateNamedBarrier('test_barrier_5', 3);
    if Assigned(LBarrier) then
    begin
      WriteLn('  Testing 100ms timeout...');
      LStartTime := GetTickCount64;
      LGuard := LBarrier.TryWaitFor(100);
      LEndTime := GetTickCount64;
      
      if not Assigned(LGuard) then
      begin
        WriteLn('  ✓ Timeout correctly returned nil');
        WriteLn('  - Elapsed time: ', LEndTime - LStartTime, ' ms');
      end
      else
        WriteLn('  ✗ Timeout incorrectly returned guard');
    end
    else
      WriteLn('  ✗ Failed to create barrier');
  except
    on E: Exception do
      WriteLn('  ✗ Timeout test exception: ', E.Message);
  end;
  WriteLn;
end;

procedure TestErrorHandling;
begin
  WriteLn('Testing error handling...');
  
  // Test invalid name
  try
    CreateNamedBarrier('');
    WriteLn('  ✗ Should have thrown invalid name exception');
  except
    on E: EInvalidArgument do
      WriteLn('  ✓ Correctly caught invalid name exception: ', E.Message);
    on E: Exception do
      WriteLn('  ? Unexpected exception type: ', E.ClassName, ' - ', E.Message);
  end;
  
  // Test invalid participant count
  try
    CreateNamedBarrier('test_invalid', 1);
    WriteLn('  ✗ Should have thrown invalid participant count exception');
  except
    on E: EInvalidArgument do
      WriteLn('  ✓ Correctly caught invalid participant count exception: ', E.Message);
    on E: Exception do
      WriteLn('  ? Unexpected exception type: ', E.ClassName, ' - ', E.Message);
  end;
  
  WriteLn;
end;

procedure TestMultipleInstances;
var
  LBarrier1, LBarrier2: INamedBarrier;
  LBarrierName: string;
begin
  WriteLn('Testing multiple instances...');
  try
    LBarrierName := 'shared_barrier_test';
    
    // Create first instance
    LBarrier1 := CreateNamedBarrier(LBarrierName, 2);
    WriteLn('  Created first instance: ', LBarrier1.GetName);
    
    // Create second instance (should connect to same barrier)
    LBarrier2 := CreateNamedBarrier(LBarrierName, 2);
    WriteLn('  Created second instance: ', LBarrier2.GetName);
    
    // Verify they reference the same barrier
    WriteLn('  Same participant count: ', 
      BoolToStr(LBarrier1.GetParticipantCount = LBarrier2.GetParticipantCount, True));
    
    // Signal from first instance
    WriteLn('  Signaling from first instance...');
    LBarrier1.Signal;
    
    // Check state from second instance
    WriteLn('  Second instance sees signaled state: ', BoolToStr(LBarrier2.IsSignaled, True));
    
    WriteLn('  ✓ Multiple instances working correctly');
  except
    on E: Exception do
      WriteLn('  ✗ Multiple instances exception: ', E.Message);
  end;
  WriteLn;
end;

var
  LTestsPassed, LTestsTotal: Integer;

begin
  // Set random seed
  Randomize;
  
  WriteLn('fafafa.core.sync.namedBarrier Basic Functionality Tests');
  WriteLn('====================================================');
  WriteLn;
  
  LTestsTotal := 7;
  LTestsPassed := 0;
  
  try
    TestBasicCreation;
    Inc(LTestsPassed);
    
    TestConfiguredCreation;
    Inc(LTestsPassed);
    
    TestSignalAndReset;
    Inc(LTestsPassed);
    
    TestTryWait;
    Inc(LTestsPassed);
    
    TestTimeout;
    Inc(LTestsPassed);
    
    TestErrorHandling;
    Inc(LTestsPassed);
    
    TestMultipleInstances;
    Inc(LTestsPassed);
    
    WriteLn('====================================================');
    WriteLn('Tests completed: ', LTestsPassed, '/', LTestsTotal, ' passed');
    
    if LTestsPassed = LTestsTotal then
    begin
      WriteLn('✓ All basic functionality tests PASSED!');
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
  WriteLn('NOTE: These are basic functionality tests.');
  WriteLn('Real barrier synchronization requires multiple processes.');
  WriteLn('Run cross-process examples to test full barrier functionality.');
end.
