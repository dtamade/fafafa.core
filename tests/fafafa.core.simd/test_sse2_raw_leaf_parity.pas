program test_sse2_raw_leaf_parity;
{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Math,
  fafafa.core.simd.intrinsics.base,
  fafafa.core.simd.intrinsics.x86.sse2;

var
  GPass: Integer = 0;
  GFail: Integer = 0;

procedure CheckF32(const aName: string; aExpected, aActual: Single);
begin
  if Abs(aExpected - aActual) < 1e-6 then Inc(GPass)
  else begin
    WriteLn('FAIL: ', aName, ' expected=', aExpected:0:6, ' got=', aActual:0:6);
    Inc(GFail);
  end;
end;

procedure CheckI32(const aName: string; aExpected, aActual: Int32);
begin
  if aExpected = aActual then Inc(GPass)
  else begin
    WriteLn('FAIL: ', aName, ' expected=', aExpected, ' got=', aActual);
    Inc(GFail);
  end;
end;

procedure CheckF64(const aName: string; aExpected, aActual: Double);
begin
  if Abs(aExpected - aActual) < 1e-12 then Inc(GPass)
  else begin
    WriteLn('FAIL: ', aName, ' expected=', aExpected:0:10, ' got=', aActual:0:10);
    Inc(GFail);
  end;
end;

var
  A, B, C: TM128;
  DataF32: array[0..3] of Single;
  DataI32: array[0..3] of Int32;
  DataF64: array[0..1] of Double;
begin
  WriteLn('=== SSE2 Raw Leaf (intrinsics.x86.sse2) Parity Test ===');
  WriteLn;

  // --- Load/Store ---
  DataF32[0] := 1.0; DataF32[1] := 2.0; DataF32[2] := 3.0; DataF32[3] := 4.0;
  A := simd_load_ps(@DataF32[0]);
  CheckF32('load_ps[0]', 1.0, A.m128_f32[0]);
  CheckF32('load_ps[1]', 2.0, A.m128_f32[1]);
  CheckF32('load_ps[2]', 3.0, A.m128_f32[2]);
  CheckF32('load_ps[3]', 4.0, A.m128_f32[3]);

  DataF32[0] := 0; DataF32[1] := 0; DataF32[2] := 0; DataF32[3] := 0;
  simd_storeu_ps(DataF32[0], A);
  CheckF32('storeu_ps[0]', 1.0, DataF32[0]);
  CheckF32('storeu_ps[3]', 4.0, DataF32[3]);

  // --- Set/Zero ---
  A := simd_setzero_ps;
  CheckF32('setzero_ps[0]', 0.0, A.m128_f32[0]);
  CheckF32('setzero_ps[3]', 0.0, A.m128_f32[3]);

  A := simd_set1_ps(3.14);
  CheckF32('set1_ps[0]', 3.14, A.m128_f32[0]);
  CheckF32('set1_ps[2]', 3.14, A.m128_f32[2]);

  A := simd_set1_epi32(42);
  CheckI32('set1_epi32[0]', 42, A.m128i_i32[0]);
  CheckI32('set1_epi32[3]', 42, A.m128i_i32[3]);

  // --- Arithmetic (F32) ---
  A := simd_set1_ps(3.0);
  B := simd_set1_ps(2.0);
  C := simd_add_ps(A, B);
  CheckF32('add_ps', 5.0, C.m128_f32[0]);

  C := simd_sub_ps(A, B);
  CheckF32('sub_ps', 1.0, C.m128_f32[0]);

  C := simd_mul_ps(A, B);
  CheckF32('mul_ps', 6.0, C.m128_f32[0]);

  C := simd_div_ps(A, B);
  CheckF32('div_ps', 1.5, C.m128_f32[0]);

  // --- Arithmetic (F64) ---
  DataF64[0] := 10.0; DataF64[1] := 20.0;
  A := simd_load_pd(@DataF64[0]);
  CheckF64('load_pd[0]', 10.0, A.m128d_f64[0]);
  CheckF64('load_pd[1]', 20.0, A.m128d_f64[1]);

  B := simd_set1_pd(5.0);
  C := simd_add_pd(A, B);
  CheckF64('add_pd[0]', 15.0, C.m128d_f64[0]);
  CheckF64('add_pd[1]', 25.0, C.m128d_f64[1]);

  C := simd_mul_pd(A, B);
  CheckF64('mul_pd[0]', 50.0, C.m128d_f64[0]);
  CheckF64('mul_pd[1]', 100.0, C.m128d_f64[1]);

  // --- Integer Arithmetic ---
  A := simd_set1_epi32(10);
  B := simd_set1_epi32(3);
  C := simd_add_epi32(A, B);
  CheckI32('add_epi32', 13, C.m128i_i32[0]);

  C := simd_sub_epi32(A, B);
  CheckI32('sub_epi32', 7, C.m128i_i32[0]);

  // --- Bitwise ---
  DataI32[0] := $FF00FF00; DataI32[1] := $FF00FF00; DataI32[2] := $FF00FF00; DataI32[3] := $FF00FF00;
  A := simd_load_si128(@DataI32[0]);
  DataI32[0] := $0F0F0F0F; DataI32[1] := $0F0F0F0F; DataI32[2] := $0F0F0F0F; DataI32[3] := $0F0F0F0F;
  B := simd_load_si128(@DataI32[0]);

  C := simd_and_si128(A, B);
  CheckI32('and_si128', Int32($0F000F00), C.m128i_i32[0]);

  C := simd_or_si128(A, B);
  CheckI32('or_si128', Int32($FF0FFF0F), C.m128i_i32[0]);

  C := simd_xor_si128(A, B);
  CheckI32('xor_si128', Int32($F00FF00F), C.m128i_i32[0]);

  // --- Shift ---
  A := simd_set1_epi32(8);
  C := simd_slli_epi32(A, 2);
  CheckI32('slli_epi32', 32, C.m128i_i32[0]);

  C := simd_srli_epi32(A, 1);
  CheckI32('srli_epi32', 4, C.m128i_i32[0]);

  // --- Compare ---
  A := simd_set1_epi32(5);
  B := simd_set1_epi32(5);
  C := simd_cmpeq_epi32(A, B);
  CheckI32('cmpeq_epi32 (equal)', Int32($FFFFFFFF), C.m128i_i32[0]);

  B := simd_set1_epi32(3);
  C := simd_cmpgt_epi32(A, B);
  CheckI32('cmpgt_epi32 (5>3)', Int32($FFFFFFFF), C.m128i_i32[0]);

  C := simd_cmpgt_epi32(B, A);
  CheckI32('cmpgt_epi32 (3>5)', 0, C.m128i_i32[0]);

  // --- Summary ---
  WriteLn;
  if GFail = 0 then
  begin
    WriteLn('RAW LEAF PARITY OK: ', GPass, ' checks passed');
    WriteLn('  SSE2 intrinsics.x86.sse2 raw leaf produces correct results.');
    WriteLn('  This is evidence toward promoting it from experimental-isolated to active-leaf.');
  end
  else
  begin
    WriteLn('RAW LEAF PARITY FAILED: ', GPass, ' passed, ', GFail, ' failed');
    Halt(1);
  end;
end.
