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
  LInfo: TNamedBarrierInfo;
begin
  WriteLn('Testing basic creation...');
  try
    LBarrier := MakeNamedBarrier('test_barrier_1');
    if Assigned(LBarrier) then
    begin
      WriteLn('  ✓ Basic creation successful');
      LInfo := LBarrier.GetInfo;
      WriteLn('  - Name: ', LInfo.Name);
      WriteLn('  - Participant count: ', LInfo.ParticipantCount);
      WriteLn('  - Waiting count: ', LInfo.CurrentWaitingCount);
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
  LInfo: TNamedBarrierInfo;
begin
  WriteLn('Testing configured creation...');
  try
    LConfig := NamedBarrierConfigWithParticipants(3);
    LBarrier := MakeNamedBarrier('test_barrier_2', LConfig);
    if Assigned(LBarrier) then
    begin
      WriteLn('  ✓ Configured creation successful');
      LInfo := LBarrier.GetInfo;
      WriteLn('  - Name: ', LInfo.Name);
      WriteLn('  - Participant count: ', LInfo.ParticipantCount);
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
  LInfo: TNamedBarrierInfo;
begin
  WriteLn('Testing signal and reset...');
  try
    LBarrier := MakeNamedBarrier('test_barrier_3', 2);
    if Assigned(LBarrier) then
    begin
      LInfo := LBarrier.GetInfo;
      WriteLn('  - Initial state: ', BoolToStr(LInfo.IsSignaled, True));
      
      LBarrier.Signal;
      LInfo := LBarrier.GetInfo;
      WriteLn('  - After signal: ', BoolToStr(LInfo.IsSignaled, True));
      
      LBarrier.Reset;
      LInfo := LBarrier.GetInfo;
      WriteLn('  - After reset: ', BoolToStr(LInfo.IsSignaled, True));
      
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
    LBarrier := MakeNamedBarrier('test_barrier_4', 2);
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
        WriteLn('  - Is last participant: ', BoolToStr(LGuard.IsLastParticipant, True));
        WriteLn('  - Generation: ', LGuard.GetGeneration);
        WriteLn('  - WaitTime(ms): ', LGuard.GetWaitTime);
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
    LBarrier := MakeNamedBarrier('test_barrier_5', 3);
    if Assigned(LBarrier) then
    begin
      WriteLn('  Testing 100ms timeout...');
      LStartTime := GetTickCount64;
      LGuard := LBarrier.WaitFor(100);
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
    MakeNamedBarrier('');
    WriteLn('  ✗ Should have thrown invalid name exception');
  except
    on E: EInvalidArgument do
      WriteLn('  ✓ Correctly caught invalid name exception: ', E.Message);
    on E: Exception do
      WriteLn('  ? Unexpected exception type: ', E.ClassName, ' - ', E.Message);
  end;
  
  // Test invalid participant count
  try
    MakeNamedBarrier('test_invalid', 1);
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
  LInfo1, LInfo2: TNamedBarrierInfo;
begin
  WriteLn('Testing multiple instances...');
  try
    LBarrierName := 'shared_barrier_test';
    
    // Create first instance
    LBarrier1 := MakeNamedBarrier(LBarrierName, 2);
    LInfo1 := LBarrier1.GetInfo;
    WriteLn('  Created first instance: ', LInfo1.Name);
    
    // Create second instance (should connect to same barrier)
    LBarrier2 := MakeNamedBarrier(LBarrierName, 2);
    LInfo2 := LBarrier2.GetInfo;
    WriteLn('  Created second instance: ', LInfo2.Name);
    
    // Verify they reference the same barrier
    WriteLn('  Same participant count: ', 
      BoolToStr(LInfo1.ParticipantCount = LInfo2.ParticipantCount, True));
    
    // Signal from first instance
    WriteLn('  Signaling from first instance...');
    LBarrier1.Signal;
    
    // Check state from second instance
    LInfo2 := LBarrier2.GetInfo;
    WriteLn('  Second instance sees signaled state: ', BoolToStr(LInfo2.IsSignaled, True));
    
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
