program simple_sse_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.base,
  fafafa.core.simd.intrinsics.sse;

var
  a, b, result: TM128;

begin
  WriteLn('Simple SSE Test');
  WriteLn('===============');
  
  // Test 1: setzero
  result := sse_setzero_ps;
  WriteLn('setzero result: ', result.m128_f32[0]:0:2);
  
  // Test 2: set1_ps
  result := sse_set1_ps(3.14);
  WriteLn('set1_ps(3.14) first: ', result.m128_f32[0]:0:2);
  WriteLn('set1_ps(3.14) last: ', result.m128_f32[3]:0:2);
  
  // Test 3: add_ps
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(1.0, 2.0, 3.0, 4.0);
  result := sse_add_ps(a, b);
  WriteLn('add_ps result[0]: ', result.m128_f32[0]:0:2);
  WriteLn('add_ps result[3]: ', result.m128_f32[3]:0:2);
  
  // Test 4: mul_ps
  a := sse_set_ps(2.0, 2.0, 2.0, 2.0);
  b := sse_set_ps(3.0, 4.0, 5.0, 6.0);
  result := sse_mul_ps(a, b);
  WriteLn('mul_ps result[0]: ', result.m128_f32[0]:0:2);
  WriteLn('mul_ps result[3]: ', result.m128_f32[3]:0:2);
  
  WriteLn('Test completed');
end.
