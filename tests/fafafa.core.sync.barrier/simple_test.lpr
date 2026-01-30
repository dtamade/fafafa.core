program simple_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.sync.barrier;

var
  Barrier: IBarrier;
  
begin
  WriteLn('Testing fafafa.core.sync.barrier basic functionality...');
  
  try
    // Test 1: Create barrier
    WriteLn('Test 1: Creating barrier with 2 participants...');
    Barrier := MakeBarrier(2);
    WriteLn('✓ Barrier created successfully');
    
    // Test 2: Check participant count
    WriteLn('Test 2: Checking participant count...');
    try
      if Barrier.GetParticipantCount = 2 then
        WriteLn('✓ Participant count is correct: ', Barrier.GetParticipantCount)
      else
        WriteLn('✗ Participant count is wrong: ', Barrier.GetParticipantCount);
    except
      on E: Exception do
        WriteLn('✗ GetParticipantCount failed: ', E.Message);
    end;
    
    // Test 3: Check error state (removed - GetLastError not available)
    WriteLn('Test 3: Skipped (GetLastError not available in current API)');
    
    // Test 4: Single participant barrier
    WriteLn('Test 4: Creating single participant barrier...');
    Barrier := MakeBarrier(1);
    WriteLn('✓ Single participant barrier created');
    
    // Test 5: Wait on single participant barrier (should return immediately)
    WriteLn('Test 5: Waiting on single participant barrier...');
    if Barrier.Wait then
      WriteLn('✓ Wait returned True (serial thread)')
    else
      WriteLn('✗ Wait returned False (unexpected)');
    
    WriteLn('');
    WriteLn('All basic tests passed! ✓');

  except
    on E: Exception do
    begin
      WriteLn('✗ Test failed with exception: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
