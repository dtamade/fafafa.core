program minimal_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.base,
  fafafa.core.simd.intrinsics.mmx;

var
  result: TM64;

begin
  WriteLn('MMX Minimal Test');
  WriteLn('================');
  
  // Test setzero
  result := mmx_setzero_si64;
  WriteLn('mmx_setzero_si64 result: ', result.mm_u64);
  
  // Test set1_pi8
  result := mmx_set1_pi8(42);
  WriteLn('mmx_set1_pi8(42) first byte: ', result.mm_u8[0]);
  WriteLn('mmx_set1_pi8(42) last byte: ', result.mm_u8[7]);
  
  // Test emms
  mmx_emms;
  WriteLn('mmx_emms executed successfully');
  
  WriteLn('Test completed');
end.
