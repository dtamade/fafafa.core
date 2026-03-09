program final_debug;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.mmx in '../../src/fafafa.core.simd.intrinsics.mmx.pas';

var
  a, b, result: TM64;
  success: Boolean;
  value: LongInt;
  dest: LongInt;
  value64: UInt64;
  dest64: UInt64;

begin
  WriteLn('Final Debug Test - Finding the 2 failures');
  WriteLn('==========================================');
  success := True;
  
  // Test movd_mm_store
  WriteLn('Test 1: mmx_movd_mm_store');
  a.mm_u64 := $1234567876543210;
  dest := 0;
  mmx_movd_mm_store(dest, a);
  WriteLn('  Input: $', IntToHex(a.mm_u64, 16));
  WriteLn('  Stored: $', IntToHex(dest, 8));
  WriteLn('  Expected: $76543210');
  if dest <> LongInt($76543210) then
  begin
    WriteLn('  FAILED!');
    success := False;
  end
  else
    WriteLn('  PASSED');
  
  // Test movq_mm_store
  WriteLn('Test 2: mmx_movq_mm_store');
  a.mm_u64 := UInt64($FEDCBA9876543210);
  dest64 := 0;
  mmx_movq_mm_store(dest64, a);
  WriteLn('  Input: $', IntToHex(a.mm_u64, 16));
  WriteLn('  Stored: $', IntToHex(dest64, 16));
  WriteLn('  Expected: $FEDCBA9876543210');
  if dest64 <> UInt64($FEDCBA9876543210) then
  begin
    WriteLn('  FAILED!');
    success := False;
  end
  else
    WriteLn('  PASSED');
  
  // Test movd_mm
  WriteLn('Test 3: mmx_movd_mm');
  value := $12345678;
  result := mmx_movd_mm(@value);
  WriteLn('  Input: $', IntToHex(value, 8));
  WriteLn('  Result low32: $', IntToHex(result.mm_u32[0], 8));
  WriteLn('  Result high32: $', IntToHex(result.mm_u32[1], 8));
  WriteLn('  Expected: low=$12345678, high=$00000000');
  if (result.mm_u32[0] <> $12345678) or (result.mm_u32[1] <> $00000000) then
  begin
    WriteLn('  FAILED!');
    success := False;
  end
  else
    WriteLn('  PASSED');
  
  // Test movq_mm
  WriteLn('Test 4: mmx_movq_mm');
  value64 := UInt64($FEDCBA9876543210);
  result := mmx_movq_mm(@value64);
  WriteLn('  Input: $', IntToHex(value64, 16));
  WriteLn('  Result: $', IntToHex(result.mm_u64, 16));
  WriteLn('  Expected: $FEDCBA9876543210');
  if result.mm_u64 <> UInt64($FEDCBA9876543210) then
  begin
    WriteLn('  FAILED!');
    success := False;
  end
  else
    WriteLn('  PASSED');
  
  // Test emms
  WriteLn('Test 5: mmx_emms');
  try
    mmx_emms;
    WriteLn('  PASSED - no crash');
  except
    WriteLn('  FAILED - crashed');
    success := False;
  end;
  
  // Test pmaddwd with the exact same values as the unit test
  WriteLn('Test 6: pmaddwd unit test case');
  a := mmx_set_pi16(10, 20, 30, 40);
  b := mmx_set_pi16(2, 3, 4, 5);
  result := mmx_pmaddwd(a, b);
  WriteLn('  a = [', a.mm_i16[0], ',', a.mm_i16[1], ',', a.mm_i16[2], ',', a.mm_i16[3], ']');
  WriteLn('  b = [', b.mm_i16[0], ',', b.mm_i16[1], ',', b.mm_i16[2], ',', b.mm_i16[3], ']');
  WriteLn('  result = [', result.mm_i32[0], ',', result.mm_i32[1], ']');
  // pmaddwd: (a[0]*b[0] + a[1]*b[1]), (a[2]*b[2] + a[3]*b[3])
  // (40*5 + 30*4), (20*3 + 10*2) = (200+120), (60+20) = 320, 80
  WriteLn('  expected = [320, 80]');
  if (result.mm_i32[0] <> 320) or (result.mm_i32[1] <> 80) then
  begin
    WriteLn('  FAILED!');
    success := False;
  end
  else
    WriteLn('  PASSED');

  // Test some word shift operations that might be failing
  WriteLn('Test 7: psllw edge case');
  a := mmx_set_pi16(1, 2, 4, 8);
  b := mmx_setzero_si64;
  b.mm_u8[0] := 2;  // 左移2位
  result := mmx_psllw(a, b);
  WriteLn('  a = [', a.mm_i16[0], ',', a.mm_i16[1], ',', a.mm_i16[2], ',', a.mm_i16[3], ']');
  WriteLn('  shift = ', b.mm_u8[0], ' bits');
  WriteLn('  result = [', result.mm_i16[0], ',', result.mm_i16[1], ',', result.mm_i16[2], ',', result.mm_i16[3], ']');
  WriteLn('  expected = [32, 16, 8, 4]');
  if (result.mm_i16[0] <> 32) or (result.mm_i16[1] <> 16) or (result.mm_i16[2] <> 8) or (result.mm_i16[3] <> 4) then
  begin
    WriteLn('  FAILED!');
    success := False;
  end
  else
    WriteLn('  PASSED');

  // Test psraw with negative numbers
  WriteLn('Test 8: psraw with negative numbers');
  a := mmx_set_pi16(-8, -4, -2, -1);
  b := mmx_setzero_si64;
  b.mm_u8[0] := 1;  // 右移1位
  result := mmx_psraw(a, b);
  WriteLn('  a = [', a.mm_i16[0], ',', a.mm_i16[1], ',', a.mm_i16[2], ',', a.mm_i16[3], ']');
  WriteLn('  shift = ', b.mm_u8[0], ' bits');
  WriteLn('  result = [', result.mm_i16[0], ',', result.mm_i16[1], ',', result.mm_i16[2], ',', result.mm_i16[3], ']');
  WriteLn('  expected = [-1, -1, -2, -4] (arithmetic right shift)');
  if (result.mm_i16[0] <> -1) or (result.mm_i16[1] <> -1) or (result.mm_i16[2] <> -2) or (result.mm_i16[3] <> -4) then
  begin
    WriteLn('  FAILED!');
    success := False;
  end
  else
    WriteLn('  PASSED');

  WriteLn('');
  if success then
  begin
    WriteLn('All debug tests PASSED!');
    ExitCode := 0;
  end
  else
  begin
    WriteLn('Some debug tests FAILED!');
    ExitCode := 1;
  end;
end.
