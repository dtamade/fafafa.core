program debug_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.mmx in '../../src/fafafa.core.simd.intrinsics.mmx.pas';

var
  a, count, result: TM64;
  success: Boolean;

begin
  WriteLn('Debug MMX Shift Test');
  WriteLn('====================');
  success := True;
  
  // Test psllq shift by 8
  WriteLn('Test 1: psllq shift by 8');
  a.mm_u64 := $0000000000000001;
  count := mmx_setzero_si64;
  count.mm_u8[0] := 8;  // 左移8位
  result := mmx_psllq(a, count);
  WriteLn('  Input: $', IntToHex(a.mm_u64, 16));
  WriteLn('  Shift: ', count.mm_u8[0], ' bits');
  WriteLn('  Result: $', IntToHex(result.mm_u64, 16));
  WriteLn('  Expected: $0000000000000100');
  if result.mm_u64 <> $0000000000000100 then
  begin
    WriteLn('  FAILED!');
    success := False;
  end
  else
    WriteLn('  PASSED');
  
  // Test psllq shift by 64 (overflow)
  WriteLn('Test 2: psllq shift by 64 (overflow)');
  a.mm_u64 := $0000000000000001;
  count := mmx_setzero_si64;
  count.mm_u8[0] := 64;  // 左移64位
  result := mmx_psllq(a, count);
  WriteLn('  Input: $', IntToHex(a.mm_u64, 16));
  WriteLn('  Shift: ', count.mm_u8[0], ' bits');
  WriteLn('  Result: $', IntToHex(result.mm_u64, 16));
  WriteLn('  Expected: $0000000000000000');
  if result.mm_u64 <> 0 then
  begin
    WriteLn('  FAILED!');
    success := False;
  end
  else
    WriteLn('  PASSED');
  
  // Test psllq_imm shift by 12
  WriteLn('Test 3: psllq_imm shift by 12');
  a.mm_u64 := $0000000000000001;
  result := mmx_psllq_imm(a, 12);
  WriteLn('  Input: $', IntToHex(a.mm_u64, 16));
  WriteLn('  Shift: 12 bits');
  WriteLn('  Result: $', IntToHex(result.mm_u64, 16));
  WriteLn('  Expected: $0000000000001000');
  if result.mm_u64 <> $0000000000001000 then
  begin
    WriteLn('  FAILED!');
    success := False;
  end
  else
    WriteLn('  PASSED');
  
  // Test psrlq shift by 8
  WriteLn('Test 4: psrlq shift by 8');
  a.mm_u64 := $0000000000001000;
  count := mmx_setzero_si64;
  count.mm_u8[0] := 8;  // 右移8位
  result := mmx_psrlq(a, count);
  WriteLn('  Input: $', IntToHex(a.mm_u64, 16));
  WriteLn('  Shift: ', count.mm_u8[0], ' bits');
  WriteLn('  Result: $', IntToHex(result.mm_u64, 16));
  WriteLn('  Expected: $0000000000000010');
  if result.mm_u64 <> $0000000000000010 then
  begin
    WriteLn('  FAILED!');
    success := False;
  end
  else
    WriteLn('  PASSED');
  
  // Test psrlq_imm shift by 12
  WriteLn('Test 5: psrlq_imm shift by 12');
  a.mm_u64 := $0000000000001000;
  result := mmx_psrlq_imm(a, 12);
  WriteLn('  Input: $', IntToHex(a.mm_u64, 16));
  WriteLn('  Shift: 12 bits');
  WriteLn('  Result: $', IntToHex(result.mm_u64, 16));
  WriteLn('  Expected: $0000000000000001');
  if result.mm_u64 <> $0000000000000001 then
  begin
    WriteLn('  FAILED!');
    success := False;
  end
  else
    WriteLn('  PASSED');

  // Test pcmpeqw
  WriteLn('Test 6: pcmpeqw');
  a := mmx_set_pi16(100, 200, 300, 400);
  count := mmx_set_pi16(100, 250, 300, 350);
  result := mmx_pcmpeqw(a, count);
  WriteLn('  a = [', a.mm_i16[0], ',', a.mm_i16[1], ',', a.mm_i16[2], ',', a.mm_i16[3], ']');
  WriteLn('  b = [', count.mm_i16[0], ',', count.mm_i16[1], ',', count.mm_i16[2], ',', count.mm_i16[3], ']');
  WriteLn('  result = [', result.mm_u16[0], ',', result.mm_u16[1], ',', result.mm_u16[2], ',', result.mm_u16[3], ']');
  WriteLn('  expected = [0, 65535, 0, 65535]');
  if (result.mm_u16[0] <> 0) or (result.mm_u16[1] <> 65535) or (result.mm_u16[2] <> 0) or (result.mm_u16[3] <> 65535) then
  begin
    WriteLn('  FAILED!');
    success := False;
  end
  else
    WriteLn('  PASSED');

  // Test pcmpgtd
  WriteLn('Test 7: pcmpgtd');
  a := mmx_set_pi32(1000000, -1000000);
  count := mmx_set_pi32(2000000, -2000000);
  result := mmx_pcmpgtd(a, count);
  WriteLn('  a = [', a.mm_i32[0], ',', a.mm_i32[1], ']');
  WriteLn('  b = [', count.mm_i32[0], ',', count.mm_i32[1], ']');
  WriteLn('  result = [', result.mm_u32[0], ',', result.mm_u32[1], ']');
  WriteLn('  expected = [4294967295, 0]');
  if (result.mm_u32[0] <> 4294967295) or (result.mm_u32[1] <> 0) then
  begin
    WriteLn('  FAILED!');
    success := False;
  end
  else
    WriteLn('  PASSED');

  // Test some edge cases that might be failing
  WriteLn('Test 8: paddq (64-bit addition)');
  a.mm_i64 := 1000000000000;
  count.mm_i64 := 500000000000;
  result := mmx_paddq(a, count);
  WriteLn('  a = ', a.mm_i64);
  WriteLn('  b = ', count.mm_i64);
  WriteLn('  result = ', result.mm_i64);
  WriteLn('  expected = 1500000000000');
  if result.mm_i64 <> 1500000000000 then
  begin
    WriteLn('  FAILED!');
    success := False;
  end
  else
    WriteLn('  PASSED');

  // Test psubq (64-bit subtraction)
  WriteLn('Test 9: psubq (64-bit subtraction)');
  a.mm_i64 := 2000000000000;
  count.mm_i64 := 500000000000;
  result := mmx_psubq(a, count);
  WriteLn('  a = ', a.mm_i64);
  WriteLn('  b = ', count.mm_i64);
  WriteLn('  result = ', result.mm_i64);
  WriteLn('  expected = 1500000000000');
  if result.mm_i64 <> 1500000000000 then
  begin
    WriteLn('  FAILED!');
    success := False;
  end
  else
    WriteLn('  PASSED');

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
