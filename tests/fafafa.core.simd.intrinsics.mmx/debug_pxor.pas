program debug_pxor;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.mmx;

var
  a, b, result: TM64;

begin
  WriteLn('Debug mmx_pxor Test');
  WriteLn('===================');
  
  a.mm_u64 := UInt64($F0F0F0F0F0F0F0F0);
  b.mm_u64 := UInt64($AAAAAAAAAAAAAAAA);
  result := mmx_pxor(a, b);
  
  WriteLn('a.mm_u64 = $', IntToHex(a.mm_u64, 16));
  WriteLn('b.mm_u64 = $', IntToHex(b.mm_u64, 16));
  WriteLn('result.mm_u64 = $', IntToHex(result.mm_u64, 16));
  
  WriteLn('');
  WriteLn('Manual calculation:');
  WriteLn('$F0F0F0F0F0F0F0F0 XOR $AAAAAAAAAAAAAAAA = $5A5A5A5A5A5A5A5A');
  WriteLn('Expected: $5A5A5A5A5A5A5A5A');
  WriteLn('Actual:   $', IntToHex(result.mm_u64, 16));
  
  if result.mm_u64 = UInt64($5A5A5A5A5A5A5A5A) then
    WriteLn('✓ Test PASSED')
  else
    WriteLn('✗ Test FAILED');
  
  WriteLn('');
  WriteLn('Testing self XOR...');
  result := mmx_pxor(a, a);
  WriteLn('a XOR a = $', IntToHex(result.mm_u64, 16));
  
  if result.mm_u64 = 0 then
    WriteLn('✓ Self XOR test PASSED')
  else
    WriteLn('✗ Self XOR test FAILED');
  
  WriteLn('');
  WriteLn('Debug completed.');
end.
