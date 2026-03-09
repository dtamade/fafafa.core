program simple_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.mmx in '../../src/fafafa.core.simd.intrinsics.mmx.pas';

var
  result: TM64;
  a, b: TM64;
  i: Integer;
  success: Boolean;

begin
  WriteLn('Simple MMX Test');
  WriteLn('===============');
  success := True;
  
  // Test 1: setzero
  WriteLn('Test 1: mmx_setzero_si64');
  result := mmx_setzero_si64;
  WriteLn('  Result: mm_u64 = ', result.mm_u64);
  if result.mm_u64 <> 0 then
  begin
    WriteLn('  FAILED: Expected 0');
    success := False;
  end
  else
    WriteLn('  PASSED');
  
  // Test 2: set1_pi8
  WriteLn('Test 2: mmx_set1_pi8(42)');
  result := mmx_set1_pi8(42);
  WriteLn('  Result bytes:');
  for i := 0 to 7 do
    WriteLn('    mm_u8[', i, '] = ', result.mm_u8[i]);
  
  for i := 0 to 7 do
  begin
    if result.mm_u8[i] <> 42 then
    begin
      WriteLn('  FAILED: mm_u8[', i, '] = ', result.mm_u8[i], ', expected 42');
      success := False;
    end;
  end;
  if success then WriteLn('  PASSED');
  
  // Test 3: set_pi8
  WriteLn('Test 3: mmx_set_pi8(1,2,3,4,5,6,7,8)');
  result := mmx_set_pi8(1, 2, 3, 4, 5, 6, 7, 8);
  WriteLn('  Result bytes:');
  for i := 0 to 7 do
    WriteLn('    mm_i8[', i, '] = ', result.mm_i8[i]);
  
  // Expected: [8,7,6,5,4,3,2,1] based on implementation
  if (result.mm_i8[0] <> 8) or (result.mm_i8[1] <> 7) or 
     (result.mm_i8[2] <> 6) or (result.mm_i8[3] <> 5) or
     (result.mm_i8[4] <> 4) or (result.mm_i8[5] <> 3) or
     (result.mm_i8[6] <> 2) or (result.mm_i8[7] <> 1) then
  begin
    WriteLn('  FAILED: Unexpected values');
    success := False;
  end
  else
    WriteLn('  PASSED');
  
  // Test 4: paddb
  WriteLn('Test 4: mmx_paddb');
  a := mmx_set1_pi8(10);
  b := mmx_set1_pi8(20);
  result := mmx_paddb(a, b);
  WriteLn('  10 + 20 = ');
  for i := 0 to 7 do
    WriteLn('    mm_u8[', i, '] = ', result.mm_u8[i]);
  
  for i := 0 to 7 do
  begin
    if result.mm_u8[i] <> 30 then
    begin
      WriteLn('  FAILED: mm_u8[', i, '] = ', result.mm_u8[i], ', expected 30');
      success := False;
    end;
  end;
  if success then WriteLn('  PASSED');
  
  // Test 5: pcmpeqw
  WriteLn('Test 5: mmx_pcmpeqw');
  a := mmx_set_pi16(100, 200, 300, 400);
  b := mmx_set_pi16(100, 250, 300, 350);
  result := mmx_pcmpeqw(a, b);
  WriteLn('  a = [', a.mm_i16[0], ',', a.mm_i16[1], ',', a.mm_i16[2], ',', a.mm_i16[3], ']');
  WriteLn('  b = [', b.mm_i16[0], ',', b.mm_i16[1], ',', b.mm_i16[2], ',', b.mm_i16[3], ']');
  WriteLn('  result = [', result.mm_u16[0], ',', result.mm_u16[1], ',', result.mm_u16[2], ',', result.mm_u16[3], ']');

  // Test 6: pcmpgtd
  WriteLn('Test 6: mmx_pcmpgtd');
  a := mmx_set_pi32(1000000, -1000000);
  b := mmx_set_pi32(2000000, -2000000);
  result := mmx_pcmpgtd(a, b);
  WriteLn('  a = [', a.mm_i32[0], ',', a.mm_i32[1], ']');
  WriteLn('  b = [', b.mm_i32[0], ',', b.mm_i32[1], ']');
  WriteLn('  result = [', result.mm_u32[0], ',', result.mm_u32[1], ']');

  WriteLn('');
  if success then
  begin
    WriteLn('All tests PASSED!');
    ExitCode := 0;
  end
  else
  begin
    WriteLn('Some tests FAILED!');
    ExitCode := 1;
  end;
end.
