program emms_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.mmx in '../../src/fafafa.core.simd.intrinsics.mmx.pas';

var
  a, b, result: TM64;
  success: Boolean;
  i: Integer;

begin
  WriteLn('MMX EMMS Function Test');
  WriteLn('======================');
  success := True;
  
  // Test 1: Basic EMMS call
  WriteLn('Test 1: Basic mmx_emms call');
  try
    mmx_emms;
    WriteLn('  PASSED - mmx_emms executed without error');
  except
    on E: Exception do
    begin
      WriteLn('  FAILED - mmx_emms threw exception: ', E.Message);
      success := False;
    end;
  end;
  
  // Test 2: EMMS after MMX operations
  WriteLn('Test 2: mmx_emms after MMX operations');
  try
    // Perform some MMX operations
    a := mmx_set1_pi16(100);
    b := mmx_set1_pi16(200);
    result := mmx_paddw(a, b);
    
    // Call EMMS to clear MMX state
    mmx_emms;
    
    WriteLn('  PASSED - mmx_emms after operations executed without error');
  except
    on E: Exception do
    begin
      WriteLn('  FAILED - mmx_emms after operations threw exception: ', E.Message);
      success := False;
    end;
  end;
  
  // Test 3: Multiple EMMS calls
  WriteLn('Test 3: Multiple mmx_emms calls');
  try
    mmx_emms;
    mmx_emms;
    mmx_emms;
    WriteLn('  PASSED - multiple mmx_emms calls executed without error');
  except
    on E: Exception do
    begin
      WriteLn('  FAILED - multiple mmx_emms calls threw exception: ', E.Message);
      success := False;
    end;
  end;
  
  // Test 4: EMMS in a loop
  WriteLn('Test 4: mmx_emms in loop');
  try
    for i := 1 to 10 do
    begin
      a := mmx_set1_pi8(i);
      b := mmx_set1_pi8(i * 2);
      result := mmx_paddb(a, b);
      mmx_emms;  // Clear state after each operation
    end;
    WriteLn('  PASSED - mmx_emms in loop executed without error');
  except
    on E: Exception do
    begin
      WriteLn('  FAILED - mmx_emms in loop threw exception: ', E.Message);
      success := False;
    end;
  end;
  
  // Test 5: Verify operations still work after EMMS
  WriteLn('Test 5: MMX operations after mmx_emms');
  try
    mmx_emms;  // Clear state first
    
    // Perform operations after EMMS
    a := mmx_set_pi32(1000, 2000);
    b := mmx_set_pi32(500, 1000);
    result := mmx_paddd(a, b);
    
    // Verify results are correct
    if (result.mm_i32[0] <> 3000) or (result.mm_i32[1] <> 1500) then
    begin
      WriteLn('  FAILED - MMX operations after EMMS produced incorrect results');
      WriteLn('    Expected: [3000, 1500]');
      WriteLn('    Actual: [', result.mm_i32[0], ', ', result.mm_i32[1], ']');
      success := False;
    end
    else
      WriteLn('  PASSED - MMX operations work correctly after mmx_emms');
  except
    on E: Exception do
    begin
      WriteLn('  FAILED - MMX operations after EMMS threw exception: ', E.Message);
      success := False;
    end;
  end;

  WriteLn('');
  if success then
  begin
    WriteLn('All EMMS tests PASSED!');
    WriteLn('mmx_emms implementation is working correctly.');
    ExitCode := 0;
  end
  else
  begin
    WriteLn('Some EMMS tests FAILED!');
    ExitCode := 1;
  end;
end.
