program simple_mmx_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.intrinsics.mmx;

var
  result: TM64;

begin
  WriteLn('Simple MMX Test');
  
  // Test 1: setzero
  result := mmx_setzero_si64;
  WriteLn('setzero result: ', result.mm_u64);
  
  // Test 2: set1_pi8
  result := mmx_set1_pi8(42);
  WriteLn('set1_pi8(42) first byte: ', result.mm_u8[0]);
  
  // Test 3: emms
  mmx_emms;
  WriteLn('emms completed');
  
  WriteLn('Test finished');
end.
