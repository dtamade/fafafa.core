program debug_shift;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.mmx;

var
  a, count, result: TM64;

begin
  WriteLn('Debug Shift Operations Test');
  WriteLn('===========================');
  
  // 测试 psllq
  WriteLn('Testing mmx_psllq...');
  a.mm_u64 := $0000000000000001;
  count := mmx_setzero_si64;
  count.mm_u8[0] := 8;  // 左移8位
  result := mmx_psllq(a, count);
  WriteLn('psllq: $', IntToHex(a.mm_u64, 16), ' << 8 = $', IntToHex(result.mm_u64, 16));
  WriteLn('Expected: $0000000000000100');
  
  if result.mm_u64 = UInt64($0000000000000100) then
    WriteLn('✓ psllq shift by 8 PASSED')
  else
    WriteLn('✗ psllq shift by 8 FAILED');
  
  // 测试移位超过位宽
  count.mm_u8[0] := 64;
  result := mmx_psllq(a, count);
  WriteLn('psllq overflow: $', IntToHex(a.mm_u64, 16), ' << 64 = $', IntToHex(result.mm_u64, 16));
  WriteLn('Expected: $0000000000000000');
  
  if result.mm_u64 = 0 then
    WriteLn('✓ psllq overflow PASSED')
  else
    WriteLn('✗ psllq overflow FAILED');
  
  WriteLn('');
  
  // 测试 psllq_imm
  WriteLn('Testing mmx_psllq_imm...');
  a.mm_u64 := $0000000000000001;
  result := mmx_psllq_imm(a, 12);
  WriteLn('psllq_imm: $', IntToHex(a.mm_u64, 16), ' << 12 = $', IntToHex(result.mm_u64, 16));
  WriteLn('Expected: $0000000000001000');
  
  if result.mm_u64 = UInt64($0000000000001000) then
    WriteLn('✓ psllq_imm shift by 12 PASSED')
  else
    WriteLn('✗ psllq_imm shift by 12 FAILED');
  
  // 测试移位超过位宽
  result := mmx_psllq_imm(a, 64);
  WriteLn('psllq_imm overflow: $', IntToHex(a.mm_u64, 16), ' << 64 = $', IntToHex(result.mm_u64, 16));
  WriteLn('Expected: $0000000000000000');
  
  if result.mm_u64 = 0 then
    WriteLn('✓ psllq_imm overflow PASSED')
  else
    WriteLn('✗ psllq_imm overflow FAILED');
  
  WriteLn('');
  WriteLn('Debug completed.');
end.
