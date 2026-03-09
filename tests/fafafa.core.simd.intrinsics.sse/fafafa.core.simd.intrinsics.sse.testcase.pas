unit fafafa.core.simd.intrinsics.sse.testcase;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, fpcunit, testutils, testregistry,
  fafafa.core.simd.intrinsics.base,
  fafafa.core.simd.intrinsics.sse;

type
  // TM128 类型测试
  TTestCase_TM128 = class(TTestCase)
  private
    procedure AssertTM128SingleArray(const Expected: array of Single; const Actual: TM128; const Msg: string);
    procedure AssertTM128IntArray(const Expected: array of LongInt; const Actual: TM128; const Msg: string);
    procedure AssertSingleEquals(const Expected, Actual: Single; const Msg: string);
  published
    // === 1️⃣ Load / Store 测试 ===
    procedure Test_sse_load_ps;
    procedure Test_sse_loadu_ps;
    procedure Test_sse_load_ss;
    procedure Test_sse_load1_ps;
    procedure Test_sse_store_ps;
    procedure Test_sse_storeu_ps;
    procedure Test_sse_store_ss;
    procedure Test_sse_store1_ps;
    procedure Test_sse_movq;
    procedure Test_sse_movq_store;
    
    // === 2️⃣ Set / Zero 测试 ===
    procedure Test_sse_setzero_ps;
    procedure Test_sse_set1_ps;
    procedure Test_sse_set_ps;
    procedure Test_sse_setr_ps;
    procedure Test_sse_set_ss;
    
    // === 3️⃣ Floating-Point Arithmetic 测试 ===
    procedure Test_sse_add_ps;
    procedure Test_sse_add_ss;
    procedure Test_sse_sub_ps;
    procedure Test_sse_sub_ss;
    procedure Test_sse_mul_ps;
    procedure Test_sse_mul_ss;
    procedure Test_sse_div_ps;
    procedure Test_sse_div_ss;
    procedure Test_sse_sqrt_ps;
    procedure Test_sse_sqrt_ss;
    procedure Test_sse_rcp_ps;
    procedure Test_sse_rcp_ss;
    procedure Test_sse_rsqrt_ps;
    procedure Test_sse_rsqrt_ss;
    procedure Test_sse_min_ps;
    procedure Test_sse_min_ss;
    procedure Test_sse_max_ps;
    procedure Test_sse_max_ss;
    
    // === 5️⃣ Logical Operations 测试 ===
    procedure Test_sse_and_ps;
    procedure Test_sse_andnot_ps;
    procedure Test_sse_andn_ps;
    procedure Test_sse_or_ps;
    procedure Test_sse_xor_ps;
    
    // === 6️⃣ Compare 测试 ===
    procedure Test_sse_cmpeq_ps;
    procedure Test_sse_cmpeq_ss;
    procedure Test_sse_cmplt_ps;
    procedure Test_sse_cmplt_ss;
    procedure Test_sse_cmple_ps;
    procedure Test_sse_cmple_ss;
    procedure Test_sse_cmpgt_ps;
    procedure Test_sse_cmpgt_ss;
    procedure Test_sse_cmpge_ps;
    procedure Test_sse_cmpge_ss;
    procedure Test_sse_cmpneq_ps;
    procedure Test_sse_cmpneq_ss;
    procedure Test_sse_cmpord_ps;
    procedure Test_sse_cmpord_ss;
    procedure Test_sse_cmpunord_ps;
    procedure Test_sse_cmpunord_ss;
    procedure Test_cmpord_cmpunord_inf_cases;
    procedure Test_cmpord_cmpunord_nan_payload_matrix;
    procedure Test_cmpord_cmpunord_ss_lane_preservation_bits;
    procedure Test_cmpeq_cmpneq_ss_bitpattern_semantics;
    procedure Test_cmpgt_cmpge_ss_bitpattern_semantics;
    procedure Test_compare_duality_matrix;
    procedure Test_cmpgt_cmpge_ps_inf_matrix;
    procedure Test_compare_partition_ps_finite_matrix;
    procedure Test_compare_masks_movemask_mapping;
    procedure Test_compare_partition_eq_lt_gt_neq_matrix;
    procedure Test_compare_partition_ss_lane_preservation_matrix;
    procedure Test_compare_ge_le_composition_ps_ss_matrix;
    procedure Test_compare_ss_movemask_bit0_mapping;
    procedure Test_cmpge_cmple_ss_edge_movemask_mapping;
    procedure Test_cmpord_cmpunord_ss_movemask_mapping;
    procedure Test_compare_ss_family_consistency_ordered_matrix;
    procedure Test_compare_ss_family_unordered_matrix;
    procedure Test_compare_ps_ord_unord_movemask_complement_matrix;
    procedure Test_compare_ps_family_consistency_ordered_matrix;
    procedure Test_compare_ps_movemask_stability_smoke_matrix;
    
    // === 7️⃣ Shuffle / Unpack 测试 ===
    procedure Test_sse_shuffle_ps;
    procedure Test_shuffle_ps_imm8_selection_matrix;
    procedure Test_shuffle_ps_imm8_exhaustive_smoke;
    procedure Test_sse_unpackhi_ps;
    procedure Test_sse_unpacklo_ps;
    procedure Test_sse_unpckhps;
    procedure Test_sse_unpcklps;
    
    // === 10️⃣ Data Movement 测试 ===
    procedure Test_sse_movaps;
    procedure Test_sse_movups;
    procedure Test_movaps_movups_consistency;
    procedure Test_movaps_unaligned_tm128;
    procedure Test_movaps_movups_bitpattern_stability;
    procedure Test_sse_movss;
    procedure Test_sse_move_ss;
    procedure Test_movss_move_ss_special_bitpatterns;
    procedure Test_movehl_movlh_bitpattern_semantics;
    procedure Test_sse_movhl_ps;
    procedure Test_sse_movehl_ps;
    procedure Test_sse_movlh_ps;
    procedure Test_sse_movelh_ps;
    procedure Test_sse_movd;
    procedure Test_sse_movd_toint;
    procedure Test_sse_movemask_ps;
    procedure Test_movemask_ps_signbit_matrix;
    procedure Test_movemask_ps_signbit_exhaustive_16cases;
    procedure Test_alias_consistency_pairs;
    
    // === 11️⃣ Cache Control 测试 ===
    procedure Test_sse_stream_ps;
    procedure Test_sse_stream_si64;
    procedure Test_stream_ps_unaligned_fallback;
    procedure Test_stream_si64_unaligned_fallback;
    procedure Test_sse_sfence;
    procedure Test_sse_prefetch;
    
    // === 12️⃣ Miscellaneous 测试 ===
    procedure Test_sse_getcsr;
    procedure Test_sse_setcsr;
    procedure Test_sse_cvtsi2ss;
    procedure Test_sse_cvtss2si;
    procedure Test_sse_cvttss2si;
    procedure Test_convert_scalar_int_combo;
    procedure Test_convert_rounding_mode_behavior;
  end;

implementation

procedure TTestCase_TM128.AssertTM128SingleArray(const Expected: array of Single; const Actual: TM128; const Msg: string);
var
  i: Integer;
begin
  AssertEquals(Msg + ' - array length', 4, Length(Expected));
  for i := 0 to 3 do
    AssertEquals(Msg + Format(' - element[%d]', [i]), Expected[i], Actual.m128_f32[i], 0.0001);
end;

procedure TTestCase_TM128.AssertTM128IntArray(const Expected: array of LongInt; const Actual: TM128; const Msg: string);
var
  i: Integer;
begin
  AssertEquals(Msg + ' - array length', 4, Length(Expected));
  for i := 0 to 3 do
    AssertEquals(Msg + Format(' - element[%d]', [i]), Expected[i], Actual.m128i_i32[i]);
end;

procedure TTestCase_TM128.AssertSingleEquals(const Expected, Actual: Single; const Msg: string);
begin
  AssertEquals(Msg, Expected, Actual, 0.0001);
end;

// === 1️⃣ Load / Store 测试 ===

procedure TTestCase_TM128.Test_sse_load_ps;
var
  data: array[0..3] of Single;
  result: TM128;
begin
  data[0] := 1.0;
  data[1] := 2.0;
  data[2] := 3.0;
  data[3] := 4.0;
  
  result := sse_load_ps(@data[0]);
  AssertTM128SingleArray([1.0, 2.0, 3.0, 4.0], result, 'sse_load_ps');
end;

procedure TTestCase_TM128.Test_sse_loadu_ps;
var
  data: array[0..3] of Single;
  result: TM128;
begin
  data[0] := 5.0;
  data[1] := 6.0;
  data[2] := 7.0;
  data[3] := 8.0;
  
  result := sse_loadu_ps(@data[0]);
  AssertTM128SingleArray([5.0, 6.0, 7.0, 8.0], result, 'sse_loadu_ps');
end;

procedure TTestCase_TM128.Test_sse_load_ss;
var
  data: Single;
  result: TM128;
begin
  data := 42.0;
  result := sse_load_ss(@data);
  AssertTM128SingleArray([42.0, 0.0, 0.0, 0.0], result, 'sse_load_ss');
end;

procedure TTestCase_TM128.Test_sse_load1_ps;
var
  LData: Single;
  LResult: TM128;
begin
  LData := 9.5;
  LResult := sse_load1_ps(@LData);
  AssertTM128SingleArray([9.5, 9.5, 9.5, 9.5], LResult, 'sse_load1_ps');

  LResult := sse_load1_ps(nil);
  AssertTM128SingleArray([0.0, 0.0, 0.0, 0.0], LResult, 'sse_load1_ps nil');
end;

procedure TTestCase_TM128.Test_sse_store_ps;
var
  src: TM128;
  dest: array[0..3] of Single;
begin
  src := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  sse_store_ps(dest, src);
  
  AssertSingleEquals(1.0, dest[0], 'store_ps[0]');
  AssertSingleEquals(2.0, dest[1], 'store_ps[1]');
  AssertSingleEquals(3.0, dest[2], 'store_ps[2]');
  AssertSingleEquals(4.0, dest[3], 'store_ps[3]');
end;

procedure TTestCase_TM128.Test_sse_storeu_ps;
var
  src: TM128;
  dest: array[0..3] of Single;
begin
  src := sse_set_ps(8.0, 7.0, 6.0, 5.0);
  sse_storeu_ps(dest, src);
  
  AssertSingleEquals(5.0, dest[0], 'storeu_ps[0]');
  AssertSingleEquals(6.0, dest[1], 'storeu_ps[1]');
  AssertSingleEquals(7.0, dest[2], 'storeu_ps[2]');
  AssertSingleEquals(8.0, dest[3], 'storeu_ps[3]');
end;

procedure TTestCase_TM128.Test_sse_store_ss;
var
  src: TM128;
  dest: Single;
begin
  src := sse_set_ss(123.456);
  sse_store_ss(dest, src);
  AssertSingleEquals(123.456, dest, 'store_ss');
end;

procedure TTestCase_TM128.Test_sse_store1_ps;
var
  LSrc: TM128;
  LDest: array[0..3] of Single;
begin
  LSrc := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  sse_store1_ps(LDest, LSrc);

  AssertSingleEquals(1.0, LDest[0], 'store1_ps[0]');
  AssertSingleEquals(1.0, LDest[1], 'store1_ps[1]');
  AssertSingleEquals(1.0, LDest[2], 'store1_ps[2]');
  AssertSingleEquals(1.0, LDest[3], 'store1_ps[3]');
end;

procedure TTestCase_TM128.Test_sse_movq;
var
  data: UInt64;
  result: TM128;
begin
  data := $123456789ABCDEF0;
  result := sse_movq(@data);
  AssertEquals('movq low 64-bit', data, result.m128i_u64[0]);
  AssertEquals('movq high 64-bit', UInt64(0), result.m128i_u64[1]);
end;

procedure TTestCase_TM128.Test_sse_movq_store;
var
  src: TM128;
  dest: UInt64;
begin
  src.m128i_u64[0] := UInt64($FEDCBA9876543210);
  src.m128i_u64[1] := UInt64($1111111111111111);
  sse_movq_store(dest, src);
  AssertEquals('movq_store', UInt64($FEDCBA9876543210), dest);
end;

// === 2️⃣ Set / Zero 测试 ===

procedure TTestCase_TM128.Test_sse_setzero_ps;
var
  result: TM128;
begin
  result := sse_setzero_ps;
  AssertTM128SingleArray([0.0, 0.0, 0.0, 0.0], result, 'setzero_ps');
end;

procedure TTestCase_TM128.Test_sse_set1_ps;
var
  result: TM128;
begin
  result := sse_set1_ps(3.14);
  AssertTM128SingleArray([3.14, 3.14, 3.14, 3.14], result, 'set1_ps');
end;

procedure TTestCase_TM128.Test_sse_set_ps;
var
  result: TM128;
begin
  result := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  AssertTM128SingleArray([1.0, 2.0, 3.0, 4.0], result, 'set_ps');
end;

procedure TTestCase_TM128.Test_sse_setr_ps;
var
  LResult: TM128;
begin
  LResult := sse_setr_ps(1.0, 2.0, 3.0, 4.0);
  AssertTM128SingleArray([1.0, 2.0, 3.0, 4.0], LResult, 'setr_ps');
end;

procedure TTestCase_TM128.Test_sse_set_ss;
var
  result: TM128;
begin
  result := sse_set_ss(99.9);
  AssertTM128SingleArray([99.9, 0.0, 0.0, 0.0], result, 'set_ss');
end;

// === 3️⃣ Floating-Point Arithmetic 测试 ===

procedure TTestCase_TM128.Test_sse_add_ps;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(8.0, 7.0, 6.0, 5.0);
  result := sse_add_ps(a, b);
  AssertTM128SingleArray([6.0, 8.0, 10.0, 12.0], result, 'add_ps');
end;

procedure TTestCase_TM128.Test_sse_add_ss;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(8.0, 7.0, 6.0, 5.0);
  result := sse_add_ss(a, b);
  AssertTM128SingleArray([6.0, 2.0, 3.0, 4.0], result, 'add_ss');
end;

procedure TTestCase_TM128.Test_sse_sub_ps;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(8.0, 6.0, 4.0, 2.0);
  b := sse_set_ps(2.0, 1.0, 1.0, 1.0);
  result := sse_sub_ps(a, b);
  AssertTM128SingleArray([1.0, 3.0, 5.0, 6.0], result, 'sub_ps');
end;

procedure TTestCase_TM128.Test_sse_sub_ss;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(8.0, 6.0, 4.0, 10.0);
  b := sse_set_ps(2.0, 1.0, 1.0, 3.0);
  result := sse_sub_ss(a, b);
  AssertTM128SingleArray([7.0, 4.0, 6.0, 8.0], result, 'sub_ss');
end;

procedure TTestCase_TM128.Test_sse_mul_ps;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(2.0, 2.0, 2.0, 2.0);
  result := sse_mul_ps(a, b);
  AssertTM128SingleArray([2.0, 4.0, 6.0, 8.0], result, 'mul_ps');
end;

procedure TTestCase_TM128.Test_sse_mul_ss;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 5.0);
  b := sse_set_ps(2.0, 2.0, 2.0, 3.0);
  result := sse_mul_ss(a, b);
  AssertTM128SingleArray([15.0, 2.0, 3.0, 4.0], result, 'mul_ss');
end;

procedure TTestCase_TM128.Test_sse_div_ps;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(8.0, 6.0, 4.0, 2.0);
  b := sse_set_ps(2.0, 2.0, 2.0, 2.0);
  result := sse_div_ps(a, b);
  AssertTM128SingleArray([1.0, 2.0, 3.0, 4.0], result, 'div_ps');
end;

procedure TTestCase_TM128.Test_sse_div_ss;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(8.0, 6.0, 4.0, 12.0);
  b := sse_set_ps(2.0, 2.0, 2.0, 3.0);
  result := sse_div_ss(a, b);
  AssertTM128SingleArray([4.0, 4.0, 6.0, 8.0], result, 'div_ss');
end;

procedure TTestCase_TM128.Test_sse_sqrt_ps;
var
  a, result: TM128;
begin
  a := sse_set_ps(16.0, 9.0, 4.0, 1.0);
  result := sse_sqrt_ps(a);
  AssertTM128SingleArray([1.0, 2.0, 3.0, 4.0], result, 'sqrt_ps');
end;

procedure TTestCase_TM128.Test_sse_sqrt_ss;
var
  a, result: TM128;
begin
  a := sse_set_ps(16.0, 9.0, 4.0, 25.0);
  result := sse_sqrt_ss(a);
  AssertTM128SingleArray([5.0, 4.0, 9.0, 16.0], result, 'sqrt_ss');
end;

procedure TTestCase_TM128.Test_sse_rcp_ps;
var
  a, result: TM128;
begin
  a := sse_set_ps(4.0, 2.0, 1.0, 0.5);
  result := sse_rcp_ps(a);
  // 近似倒数，允许较大误差
  AssertEquals('rcp_ps[0]', 2.0, result.m128_f32[0], 0.01);
  AssertEquals('rcp_ps[1]', 1.0, result.m128_f32[1], 0.01);
  AssertEquals('rcp_ps[2]', 0.5, result.m128_f32[2], 0.01);
  AssertEquals('rcp_ps[3]', 0.25, result.m128_f32[3], 0.01);
end;

procedure TTestCase_TM128.Test_sse_rcp_ss;
var
  a, result: TM128;
begin
  a := sse_set_ps(4.0, 2.0, 1.0, 4.0);
  result := sse_rcp_ss(a);
  AssertEquals('rcp_ss[0]', 0.25, result.m128_f32[0], 0.01);
  AssertSingleEquals(1.0, result.m128_f32[1], 'rcp_ss[1]');
  AssertSingleEquals(2.0, result.m128_f32[2], 'rcp_ss[2]');
  AssertSingleEquals(4.0, result.m128_f32[3], 'rcp_ss[3]');
end;

procedure TTestCase_TM128.Test_sse_rsqrt_ps;
var
  a, result: TM128;
begin
  a := sse_set_ps(16.0, 4.0, 1.0, 0.25);
  result := sse_rsqrt_ps(a);
  // 近似平方根倒数，允许较大误差
  AssertEquals('rsqrt_ps[0]', 2.0, result.m128_f32[0], 0.01);
  AssertEquals('rsqrt_ps[1]', 1.0, result.m128_f32[1], 0.01);
  AssertEquals('rsqrt_ps[2]', 0.5, result.m128_f32[2], 0.01);
  AssertEquals('rsqrt_ps[3]', 0.25, result.m128_f32[3], 0.01);
end;

procedure TTestCase_TM128.Test_sse_rsqrt_ss;
var
  a, result: TM128;
begin
  a := sse_set_ps(16.0, 4.0, 1.0, 4.0);
  result := sse_rsqrt_ss(a);
  AssertEquals('rsqrt_ss[0]', 0.5, result.m128_f32[0], 0.01);
  AssertSingleEquals(1.0, result.m128_f32[1], 'rsqrt_ss[1]');
  AssertSingleEquals(4.0, result.m128_f32[2], 'rsqrt_ss[2]');
  AssertSingleEquals(16.0, result.m128_f32[3], 'rsqrt_ss[3]');
end;

procedure TTestCase_TM128.Test_sse_min_ps;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 1.0, 6.0, 2.0);
  b := sse_set_ps(2.0, 3.0, 4.0, 5.0);
  result := sse_min_ps(a, b);
  AssertTM128SingleArray([2.0, 4.0, 1.0, 2.0], result, 'min_ps');
end;

procedure TTestCase_TM128.Test_sse_min_ss;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 1.0, 6.0, 8.0);
  b := sse_set_ps(2.0, 3.0, 4.0, 5.0);
  result := sse_min_ss(a, b);
  AssertTM128SingleArray([5.0, 6.0, 1.0, 4.0], result, 'min_ss');
end;

procedure TTestCase_TM128.Test_sse_max_ps;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 1.0, 6.0, 2.0);
  b := sse_set_ps(2.0, 3.0, 4.0, 5.0);
  result := sse_max_ps(a, b);
  AssertTM128SingleArray([5.0, 6.0, 3.0, 4.0], result, 'max_ps');
end;

procedure TTestCase_TM128.Test_sse_max_ss;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 1.0, 6.0, 3.0);
  b := sse_set_ps(2.0, 3.0, 4.0, 5.0);
  result := sse_max_ss(a, b);
  AssertTM128SingleArray([5.0, 6.0, 1.0, 4.0], result, 'max_ss');
end;

// === 5️⃣ Logical Operations 测试 ===

procedure TTestCase_TM128.Test_sse_and_ps;
var
  a, b, result: TM128;
begin
  a.m128i_u32[0] := $FFFFFFFF;
  a.m128i_u32[1] := $F0F0F0F0;
  a.m128i_u32[2] := $AAAAAAAA;
  a.m128i_u32[3] := $12345678;

  b.m128i_u32[0] := $0F0F0F0F;
  b.m128i_u32[1] := $FFFFFFFF;
  b.m128i_u32[2] := $55555555;
  b.m128i_u32[3] := $87654321;

  result := sse_and_ps(a, b);
  AssertEquals('and_ps[0]', $0F0F0F0F, result.m128i_u32[0]);
  AssertEquals('and_ps[1]', $F0F0F0F0, result.m128i_u32[1]);
  AssertEquals('and_ps[2]', $00000000, result.m128i_u32[2]);
  AssertEquals('and_ps[3]', $02244220, result.m128i_u32[3]);
end;

procedure TTestCase_TM128.Test_sse_andnot_ps;
var
  LVecA, LVecB, LResult: TM128;
begin
  LVecA.m128i_u32[0] := $FFFFFFFF;
  LVecA.m128i_u32[1] := $F0F0F0F0;
  LVecA.m128i_u32[2] := $AAAAAAAA;
  LVecA.m128i_u32[3] := $12345678;

  LVecB.m128i_u32[0] := $0F0F0F0F;
  LVecB.m128i_u32[1] := $FFFFFFFF;
  LVecB.m128i_u32[2] := $55555555;
  LVecB.m128i_u32[3] := $87654321;

  LResult := sse_andnot_ps(LVecA, LVecB);
  AssertEquals('andnot_ps[0]', $00000000, LResult.m128i_u32[0]);
  AssertEquals('andnot_ps[1]', $0F0F0F0F, LResult.m128i_u32[1]);
  AssertEquals('andnot_ps[2]', $55555555, LResult.m128i_u32[2]);
  AssertEquals('andnot_ps[3]', $85410101, LResult.m128i_u32[3]);
end;

procedure TTestCase_TM128.Test_sse_andn_ps;
var
  a, b, result: TM128;
begin
  a.m128i_u32[0] := $FFFFFFFF;
  a.m128i_u32[1] := $F0F0F0F0;
  a.m128i_u32[2] := $AAAAAAAA;
  a.m128i_u32[3] := $12345678;

  b.m128i_u32[0] := $0F0F0F0F;
  b.m128i_u32[1] := $FFFFFFFF;
  b.m128i_u32[2] := $55555555;
  b.m128i_u32[3] := $87654321;

  result := sse_andn_ps(a, b);
  AssertEquals('andn_ps[0]', $00000000, result.m128i_u32[0]);
  AssertEquals('andn_ps[1]', $0F0F0F0F, result.m128i_u32[1]);
  AssertEquals('andn_ps[2]', $55555555, result.m128i_u32[2]);
  AssertEquals('andn_ps[3]', $85410101, result.m128i_u32[3]);
end;

procedure TTestCase_TM128.Test_sse_or_ps;
var
  a, b, result: TM128;
begin
  a.m128i_u32[0] := $F0F0F0F0;
  a.m128i_u32[1] := $0F0F0F0F;
  a.m128i_u32[2] := $AAAAAAAA;
  a.m128i_u32[3] := $12345678;

  b.m128i_u32[0] := $0F0F0F0F;
  b.m128i_u32[1] := $F0F0F0F0;
  b.m128i_u32[2] := $55555555;
  b.m128i_u32[3] := $87654321;

  result := sse_or_ps(a, b);
  AssertEquals('or_ps[0]', $FFFFFFFF, result.m128i_u32[0]);
  AssertEquals('or_ps[1]', $FFFFFFFF, result.m128i_u32[1]);
  AssertEquals('or_ps[2]', $FFFFFFFF, result.m128i_u32[2]);
  AssertEquals('or_ps[3]', $97755779, result.m128i_u32[3]);
end;

procedure TTestCase_TM128.Test_sse_xor_ps;
var
  a, b, result: TM128;
begin
  a.m128i_u32[0] := $FFFFFFFF;
  a.m128i_u32[1] := $F0F0F0F0;
  a.m128i_u32[2] := $AAAAAAAA;
  a.m128i_u32[3] := $12345678;

  b.m128i_u32[0] := $FFFFFFFF;
  b.m128i_u32[1] := $0F0F0F0F;
  b.m128i_u32[2] := $AAAAAAAA;
  b.m128i_u32[3] := $87654321;

  result := sse_xor_ps(a, b);
  AssertEquals('xor_ps[0]', $00000000, result.m128i_u32[0]);
  AssertEquals('xor_ps[1]', $FFFFFFFF, result.m128i_u32[1]);
  AssertEquals('xor_ps[2]', $00000000, result.m128i_u32[2]);
  AssertEquals('xor_ps[3]', $95511559, result.m128i_u32[3]);
end;

// === 6️⃣ Compare 测试 ===

procedure TTestCase_TM128.Test_sse_cmpeq_ps;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(4.0, 5.0, 2.0, 3.0);
  result := sse_cmpeq_ps(a, b);
  AssertEquals('cmpeq_ps[0]', $00000000, result.m128i_u32[0]);
  AssertEquals('cmpeq_ps[1]', $FFFFFFFF, result.m128i_u32[1]);
  AssertEquals('cmpeq_ps[2]', $00000000, result.m128i_u32[2]);
  AssertEquals('cmpeq_ps[3]', $FFFFFFFF, result.m128i_u32[3]);
end;

procedure TTestCase_TM128.Test_sse_cmpeq_ss;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(5.0, 6.0, 7.0, 1.0);
  result := sse_cmpeq_ss(a, b);
  AssertEquals('cmpeq_ss[0]', $FFFFFFFF, result.m128i_u32[0]);
  AssertSingleEquals(2.0, result.m128_f32[1], 'cmpeq_ss[1]');
  AssertSingleEquals(3.0, result.m128_f32[2], 'cmpeq_ss[2]');
  AssertSingleEquals(4.0, result.m128_f32[3], 'cmpeq_ss[3]');
end;

procedure TTestCase_TM128.Test_sse_cmplt_ps;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(3.0, 5.0, 2.0, 3.0);
  result := sse_cmplt_ps(a, b);
  AssertEquals('cmplt_ps[0]', $FFFFFFFF, result.m128i_u32[0]);
  AssertEquals('cmplt_ps[1]', $00000000, result.m128i_u32[1]);
  AssertEquals('cmplt_ps[2]', $FFFFFFFF, result.m128i_u32[2]);
  AssertEquals('cmplt_ps[3]', $00000000, result.m128i_u32[3]);
end;

procedure TTestCase_TM128.Test_sse_cmplt_ss;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(5.0, 6.0, 7.0, 2.0);
  result := sse_cmplt_ss(a, b);
  AssertEquals('cmplt_ss[0]', $FFFFFFFF, result.m128i_u32[0]);
  AssertSingleEquals(2.0, result.m128_f32[1], 'cmplt_ss[1]');
  AssertSingleEquals(3.0, result.m128_f32[2], 'cmplt_ss[2]');
  AssertSingleEquals(4.0, result.m128_f32[3], 'cmplt_ss[3]');
end;

procedure TTestCase_TM128.Test_sse_cmple_ps;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(3.0, 3.0, 2.0, 3.0);
  result := sse_cmple_ps(a, b);
  AssertEquals('cmple_ps[0]', $FFFFFFFF, result.m128i_u32[0]);
  AssertEquals('cmple_ps[1]', $FFFFFFFF, result.m128i_u32[1]);
  AssertEquals('cmple_ps[2]', $FFFFFFFF, result.m128i_u32[2]);
  AssertEquals('cmple_ps[3]', $00000000, result.m128i_u32[3]);
end;

procedure TTestCase_TM128.Test_sse_cmple_ss;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(5.0, 6.0, 7.0, 1.0);
  result := sse_cmple_ss(a, b);
  AssertEquals('cmple_ss[0]', $FFFFFFFF, result.m128i_u32[0]);
  AssertSingleEquals(2.0, result.m128_f32[1], 'cmple_ss[1]');
  AssertSingleEquals(3.0, result.m128_f32[2], 'cmple_ss[2]');
  AssertSingleEquals(4.0, result.m128_f32[3], 'cmple_ss[3]');
end;

procedure TTestCase_TM128.Test_sse_cmpgt_ps;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(3.0, 5.0, 2.0, 3.0);
  result := sse_cmpgt_ps(a, b);
  AssertEquals('cmpgt_ps[0]', $00000000, result.m128i_u32[0]);
  AssertEquals('cmpgt_ps[1]', $00000000, result.m128i_u32[1]);
  AssertEquals('cmpgt_ps[2]', $00000000, result.m128i_u32[2]);
  AssertEquals('cmpgt_ps[3]', $FFFFFFFF, result.m128i_u32[3]);
end;

procedure TTestCase_TM128.Test_sse_cmpgt_ss;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 3.0);
  b := sse_set_ps(5.0, 6.0, 7.0, 2.0);
  result := sse_cmpgt_ss(a, b);
  AssertEquals('cmpgt_ss[0]', $FFFFFFFF, result.m128i_u32[0]);
  AssertSingleEquals(2.0, result.m128_f32[1], 'cmpgt_ss[1]');
  AssertSingleEquals(3.0, result.m128_f32[2], 'cmpgt_ss[2]');
  AssertSingleEquals(4.0, result.m128_f32[3], 'cmpgt_ss[3]');
end;

procedure TTestCase_TM128.Test_sse_cmpge_ps;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(3.0, 3.0, 2.0, 3.0);
  result := sse_cmpge_ps(a, b);
  AssertEquals('cmpge_ps[0]', $00000000, result.m128i_u32[0]);
  AssertEquals('cmpge_ps[1]', $FFFFFFFF, result.m128i_u32[1]);
  AssertEquals('cmpge_ps[2]', $FFFFFFFF, result.m128i_u32[2]);
  AssertEquals('cmpge_ps[3]', $FFFFFFFF, result.m128i_u32[3]);
end;

procedure TTestCase_TM128.Test_sse_cmpge_ss;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 2.0);
  b := sse_set_ps(5.0, 6.0, 7.0, 2.0);
  result := sse_cmpge_ss(a, b);
  AssertEquals('cmpge_ss[0]', $FFFFFFFF, result.m128i_u32[0]);
  AssertSingleEquals(2.0, result.m128_f32[1], 'cmpge_ss[1]');
  AssertSingleEquals(3.0, result.m128_f32[2], 'cmpge_ss[2]');
  AssertSingleEquals(4.0, result.m128_f32[3], 'cmpge_ss[3]');
end;

procedure TTestCase_TM128.Test_sse_cmpneq_ps;
var
  LVecA, LVecB, LResult: TM128;
begin
  LVecA := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  LVecB := sse_set_ps(0.0, 3.0, 5.0, 1.0);
  LResult := sse_cmpneq_ps(LVecA, LVecB);

  AssertEquals('cmpneq_ps[0]', $00000000, LResult.m128i_u32[0]);
  AssertEquals('cmpneq_ps[1]', $FFFFFFFF, LResult.m128i_u32[1]);
  AssertEquals('cmpneq_ps[2]', $00000000, LResult.m128i_u32[2]);
  AssertEquals('cmpneq_ps[3]', $FFFFFFFF, LResult.m128i_u32[3]);
end;

procedure TTestCase_TM128.Test_sse_cmpneq_ss;
var
  LVecA, LVecB, LResult: TM128;
begin
  LVecA := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  LVecB := sse_set_ps(9.0, 9.0, 9.0, 2.0);
  LResult := sse_cmpneq_ss(LVecA, LVecB);

  AssertEquals('cmpneq_ss[0]', $FFFFFFFF, LResult.m128i_u32[0]);
  AssertSingleEquals(2.0, LResult.m128_f32[1], 'cmpneq_ss[1]');
  AssertSingleEquals(3.0, LResult.m128_f32[2], 'cmpneq_ss[2]');
  AssertSingleEquals(4.0, LResult.m128_f32[3], 'cmpneq_ss[3]');
end;

procedure TTestCase_TM128.Test_sse_cmpord_ps;
var
  a, b, result: TM128;
  nan_val: Single;
begin
  nan_val := 0.0 / 0.0;  // 创建 NaN
  a := sse_set_ps(4.0, nan_val, 2.0, 1.0);
  b := sse_set_ps(3.0, 5.0, nan_val, 3.0);
  result := sse_cmpord_ps(a, b);
  AssertEquals('cmpord_ps[0]', $FFFFFFFF, result.m128i_u32[0]);
  AssertEquals('cmpord_ps[1]', $00000000, result.m128i_u32[1]);
  AssertEquals('cmpord_ps[2]', $00000000, result.m128i_u32[2]);
  AssertEquals('cmpord_ps[3]', $FFFFFFFF, result.m128i_u32[3]);
end;

procedure TTestCase_TM128.Test_sse_cmpord_ss;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(5.0, 6.0, 7.0, 2.0);
  result := sse_cmpord_ss(a, b);
  AssertEquals('cmpord_ss[0]', $FFFFFFFF, result.m128i_u32[0]);
  AssertSingleEquals(2.0, result.m128_f32[1], 'cmpord_ss[1]');
  AssertSingleEquals(3.0, result.m128_f32[2], 'cmpord_ss[2]');
  AssertSingleEquals(4.0, result.m128_f32[3], 'cmpord_ss[3]');
end;

procedure TTestCase_TM128.Test_sse_cmpunord_ps;
var
  a, b, result: TM128;
  nan_val: Single;
begin
  nan_val := 0.0 / 0.0;  // 创建 NaN
  a := sse_set_ps(4.0, nan_val, 2.0, 1.0);
  b := sse_set_ps(3.0, 5.0, nan_val, 3.0);
  result := sse_cmpunord_ps(a, b);
  AssertEquals('cmpunord_ps[0]', $00000000, result.m128i_u32[0]);
  AssertEquals('cmpunord_ps[1]', $FFFFFFFF, result.m128i_u32[1]);
  AssertEquals('cmpunord_ps[2]', $FFFFFFFF, result.m128i_u32[2]);
  AssertEquals('cmpunord_ps[3]', $00000000, result.m128i_u32[3]);
end;

procedure TTestCase_TM128.Test_sse_cmpunord_ss;
var
  a, b, result: TM128;
  nan_val: Single;
begin
  nan_val := 0.0 / 0.0;  // 创建 NaN
  a := sse_set_ps(4.0, 3.0, 2.0, nan_val);
  b := sse_set_ps(5.0, 6.0, 7.0, 2.0);
  result := sse_cmpunord_ss(a, b);
  AssertEquals('cmpunord_ss[0]', $FFFFFFFF, result.m128i_u32[0]);
  AssertSingleEquals(2.0, result.m128_f32[1], 'cmpunord_ss[1]');
  AssertSingleEquals(3.0, result.m128_f32[2], 'cmpunord_ss[2]');
  AssertSingleEquals(4.0, result.m128_f32[3], 'cmpunord_ss[3]');
end;

procedure TTestCase_TM128.Test_cmpord_cmpunord_inf_cases;
var
  LVecA, LVecB: TM128;
  LOrd, LUnord: TM128;
  LPosInf, LNegInf: Single;
begin
  LPosInf := 1.0 / 0.0;
  LNegInf := -1.0 / 0.0;

  // Inf 不是 NaN，因此应被视为 ordered
  LVecA := sse_set_ps(LPosInf, LNegInf, 2.0, -3.0);
  LVecB := sse_set_ps(9.0, -8.0, LPosInf, LNegInf);

  LOrd := sse_cmpord_ps(LVecA, LVecB);
  AssertEquals('cmpord_inf_ps[0]', $FFFFFFFF, LOrd.m128i_u32[0]);
  AssertEquals('cmpord_inf_ps[1]', $FFFFFFFF, LOrd.m128i_u32[1]);
  AssertEquals('cmpord_inf_ps[2]', $FFFFFFFF, LOrd.m128i_u32[2]);
  AssertEquals('cmpord_inf_ps[3]', $FFFFFFFF, LOrd.m128i_u32[3]);

  LUnord := sse_cmpunord_ps(LVecA, LVecB);
  AssertEquals('cmpunord_inf_ps[0]', $00000000, LUnord.m128i_u32[0]);
  AssertEquals('cmpunord_inf_ps[1]', $00000000, LUnord.m128i_u32[1]);
  AssertEquals('cmpunord_inf_ps[2]', $00000000, LUnord.m128i_u32[2]);
  AssertEquals('cmpunord_inf_ps[3]', $00000000, LUnord.m128i_u32[3]);

  LOrd := sse_cmpord_ss(LVecA, LVecB);
  AssertEquals('cmpord_inf_ss[0]', $FFFFFFFF, LOrd.m128i_u32[0]);

  LUnord := sse_cmpunord_ss(LVecA, LVecB);
  AssertEquals('cmpunord_inf_ss[0]', $00000000, LUnord.m128i_u32[0]);
end;


procedure TTestCase_TM128.Test_cmpord_cmpunord_nan_payload_matrix;
var
  LVecA, LVecB: TM128;
  LOrd, LUnord: TM128;
begin
  LVecA := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  LVecB := sse_set_ps(8.0, 7.0, 6.0, 5.0);

  // lane0: qNaN vs finite
  LVecA.m128i_u32[0] := DWord($7FC01234);
  // lane1: finite vs qNaN(negative payload)
  LVecB.m128i_u32[1] := DWord($FFC05678);
  // lane2: finite vs finite (ordered)
  // lane3: qNaN payload vs finite
  LVecA.m128i_u32[3] := DWord($7FC00001);

  LOrd := sse_cmpord_ps(LVecA, LVecB);
  AssertEquals('cmpord_nan_payload_ps[0]', $00000000, LOrd.m128i_u32[0]);
  AssertEquals('cmpord_nan_payload_ps[1]', $00000000, LOrd.m128i_u32[1]);
  AssertEquals('cmpord_nan_payload_ps[2]', $FFFFFFFF, LOrd.m128i_u32[2]);
  AssertEquals('cmpord_nan_payload_ps[3]', $00000000, LOrd.m128i_u32[3]);

  LUnord := sse_cmpunord_ps(LVecA, LVecB);
  AssertEquals('cmpunord_nan_payload_ps[0]', $FFFFFFFF, LUnord.m128i_u32[0]);
  AssertEquals('cmpunord_nan_payload_ps[1]', $FFFFFFFF, LUnord.m128i_u32[1]);
  AssertEquals('cmpunord_nan_payload_ps[2]', $00000000, LUnord.m128i_u32[2]);
  AssertEquals('cmpunord_nan_payload_ps[3]', $FFFFFFFF, LUnord.m128i_u32[3]);
end;


procedure TTestCase_TM128.Test_cmpord_cmpunord_ss_lane_preservation_bits;
var
  LVecA, LVecB: TM128;
  LOrd, LUnord: TM128;
begin
  // Upper lanes use distinct bit patterns to verify strict preservation.
  LVecA.m128i_u32[0] := DWord($3F800000); // 1.0 (ordered)
  LVecA.m128i_u32[1] := DWord($7FC01234); // qNaN payload
  LVecA.m128i_u32[2] := DWord($80000000); // -0.0
  LVecA.m128i_u32[3] := DWord($FF800000); // -Inf

  LVecB.m128i_u32[0] := DWord($40000000); // 2.0
  LVecB.m128i_u32[1] := DWord($00000001); // denorm
  LVecB.m128i_u32[2] := DWord($7F800000); // +Inf
  LVecB.m128i_u32[3] := DWord($FFC05678); // -qNaN payload

  LOrd := sse_cmpord_ss(LVecA, LVecB);
  AssertEquals('cmpord_ss bit lane0 ordered', DWord($FFFFFFFF), LOrd.m128i_u32[0]);
  AssertEquals('cmpord_ss bit lane1 preserve', LVecA.m128i_u32[1], LOrd.m128i_u32[1]);
  AssertEquals('cmpord_ss bit lane2 preserve', LVecA.m128i_u32[2], LOrd.m128i_u32[2]);
  AssertEquals('cmpord_ss bit lane3 preserve', LVecA.m128i_u32[3], LOrd.m128i_u32[3]);

  // Make lane0 unordered with qNaN payload.
  LVecA.m128i_u32[0] := DWord($7FC0ABCD);

  LOrd := sse_cmpord_ss(LVecA, LVecB);
  AssertEquals('cmpord_ss bit lane0 unordered', DWord($00000000), LOrd.m128i_u32[0]);
  AssertEquals('cmpord_ss unordered lane1 preserve', LVecA.m128i_u32[1], LOrd.m128i_u32[1]);
  AssertEquals('cmpord_ss unordered lane2 preserve', LVecA.m128i_u32[2], LOrd.m128i_u32[2]);
  AssertEquals('cmpord_ss unordered lane3 preserve', LVecA.m128i_u32[3], LOrd.m128i_u32[3]);

  LUnord := sse_cmpunord_ss(LVecA, LVecB);
  AssertEquals('cmpunord_ss bit lane0 unordered', DWord($FFFFFFFF), LUnord.m128i_u32[0]);
  AssertEquals('cmpunord_ss lane1 preserve', LVecA.m128i_u32[1], LUnord.m128i_u32[1]);
  AssertEquals('cmpunord_ss lane2 preserve', LVecA.m128i_u32[2], LUnord.m128i_u32[2]);
  AssertEquals('cmpunord_ss lane3 preserve', LVecA.m128i_u32[3], LUnord.m128i_u32[3]);
end;


procedure TTestCase_TM128.Test_cmpeq_cmpneq_ss_bitpattern_semantics;
var
  LVecA, LVecB: TM128;
  LEq, LNeq: TM128;
begin
  // Case 1: -0.0 == +0.0 in lane0, upper lanes must preserve from A.
  LVecA.m128i_u32[0] := DWord($80000000); // -0.0
  LVecA.m128i_u32[1] := DWord($7FC01234); // qNaN payload
  LVecA.m128i_u32[2] := DWord($FF800000); // -Inf
  LVecA.m128i_u32[3] := DWord($00000001); // denorm

  LVecB.m128i_u32[0] := DWord($00000000); // +0.0
  LVecB.m128i_u32[1] := DWord($3F800000); // 1.0
  LVecB.m128i_u32[2] := DWord($40000000); // 2.0
  LVecB.m128i_u32[3] := DWord($7F800000); // +Inf

  LEq := sse_cmpeq_ss(LVecA, LVecB);
  AssertEquals('cmpeq_ss bit lane0 -0==+0', DWord($FFFFFFFF), LEq.m128i_u32[0]);
  AssertEquals('cmpeq_ss lane1 preserve', LVecA.m128i_u32[1], LEq.m128i_u32[1]);
  AssertEquals('cmpeq_ss lane2 preserve', LVecA.m128i_u32[2], LEq.m128i_u32[2]);
  AssertEquals('cmpeq_ss lane3 preserve', LVecA.m128i_u32[3], LEq.m128i_u32[3]);

  LNeq := sse_cmpneq_ss(LVecA, LVecB);
  AssertEquals('cmpneq_ss bit lane0 -0!=+0 false', DWord($00000000), LNeq.m128i_u32[0]);
  AssertEquals('cmpneq_ss lane1 preserve', LVecA.m128i_u32[1], LNeq.m128i_u32[1]);
  AssertEquals('cmpneq_ss lane2 preserve', LVecA.m128i_u32[2], LNeq.m128i_u32[2]);
  AssertEquals('cmpneq_ss lane3 preserve', LVecA.m128i_u32[3], LNeq.m128i_u32[3]);

  // Case 2: NaN in lane0: cmpeq=false, cmpneq=true.
  LVecA.m128i_u32[0] := DWord($7FC0ABCD); // qNaN payload
  LVecA.m128i_u32[1] := DWord($80000000); // -0.0
  LVecA.m128i_u32[2] := DWord($7F800000); // +Inf
  LVecA.m128i_u32[3] := DWord($FFC05678); // -qNaN payload

  LVecB.m128i_u32[0] := DWord($3F800000); // 1.0

  LEq := sse_cmpeq_ss(LVecA, LVecB);
  AssertEquals('cmpeq_ss bit lane0 NaN==x false', DWord($00000000), LEq.m128i_u32[0]);
  AssertEquals('cmpeq_ss NaN lane1 preserve', LVecA.m128i_u32[1], LEq.m128i_u32[1]);
  AssertEquals('cmpeq_ss NaN lane2 preserve', LVecA.m128i_u32[2], LEq.m128i_u32[2]);
  AssertEquals('cmpeq_ss NaN lane3 preserve', LVecA.m128i_u32[3], LEq.m128i_u32[3]);

  LNeq := sse_cmpneq_ss(LVecA, LVecB);
  AssertEquals('cmpneq_ss bit lane0 NaN!=x true', DWord($FFFFFFFF), LNeq.m128i_u32[0]);
  AssertEquals('cmpneq_ss NaN lane1 preserve', LVecA.m128i_u32[1], LNeq.m128i_u32[1]);
  AssertEquals('cmpneq_ss NaN lane2 preserve', LVecA.m128i_u32[2], LNeq.m128i_u32[2]);
  AssertEquals('cmpneq_ss NaN lane3 preserve', LVecA.m128i_u32[3], LNeq.m128i_u32[3]);
end;


procedure TTestCase_TM128.Test_cmpgt_cmpge_ss_bitpattern_semantics;
var
  LVecA, LVecB: TM128;
  LGt, LGe: TM128;
begin
  // Case 1: lane0 3.0 > 2.0, upper lanes must preserve from A.
  LVecA.m128i_u32[0] := DWord($40400000); // 3.0
  LVecA.m128i_u32[1] := DWord($7FC01234); // qNaN payload
  LVecA.m128i_u32[2] := DWord($80000000); // -0.0
  LVecA.m128i_u32[3] := DWord($FF800000); // -Inf

  LVecB.m128i_u32[0] := DWord($40000000); // 2.0
  LVecB.m128i_u32[1] := DWord($3F800000); // 1.0
  LVecB.m128i_u32[2] := DWord($40000000); // 2.0
  LVecB.m128i_u32[3] := DWord($7F800000); // +Inf

  LGt := sse_cmpgt_ss(LVecA, LVecB);
  AssertEquals('cmpgt_ss bit lane0 3>2', DWord($FFFFFFFF), LGt.m128i_u32[0]);
  AssertEquals('cmpgt_ss lane1 preserve', LVecA.m128i_u32[1], LGt.m128i_u32[1]);
  AssertEquals('cmpgt_ss lane2 preserve', LVecA.m128i_u32[2], LGt.m128i_u32[2]);
  AssertEquals('cmpgt_ss lane3 preserve', LVecA.m128i_u32[3], LGt.m128i_u32[3]);

  LGe := sse_cmpge_ss(LVecA, LVecB);
  AssertEquals('cmpge_ss bit lane0 3>=2', DWord($FFFFFFFF), LGe.m128i_u32[0]);
  AssertEquals('cmpge_ss lane1 preserve', LVecA.m128i_u32[1], LGe.m128i_u32[1]);
  AssertEquals('cmpge_ss lane2 preserve', LVecA.m128i_u32[2], LGe.m128i_u32[2]);
  AssertEquals('cmpge_ss lane3 preserve', LVecA.m128i_u32[3], LGe.m128i_u32[3]);

  // Case 2: lane0 -0.0 vs +0.0 => gt false, ge true.
  LVecA.m128i_u32[0] := DWord($80000000); // -0.0
  LVecA.m128i_u32[1] := DWord($FFC05678); // -qNaN payload
  LVecA.m128i_u32[2] := DWord($7F800000); // +Inf
  LVecA.m128i_u32[3] := DWord($00000001); // denorm

  LVecB.m128i_u32[0] := DWord($00000000); // +0.0

  LGt := sse_cmpgt_ss(LVecA, LVecB);
  AssertEquals('cmpgt_ss bit lane0 -0>+0 false', DWord($00000000), LGt.m128i_u32[0]);
  AssertEquals('cmpgt_ss eq lane1 preserve', LVecA.m128i_u32[1], LGt.m128i_u32[1]);
  AssertEquals('cmpgt_ss eq lane2 preserve', LVecA.m128i_u32[2], LGt.m128i_u32[2]);
  AssertEquals('cmpgt_ss eq lane3 preserve', LVecA.m128i_u32[3], LGt.m128i_u32[3]);

  LGe := sse_cmpge_ss(LVecA, LVecB);
  AssertEquals('cmpge_ss bit lane0 -0>=+0 true', DWord($FFFFFFFF), LGe.m128i_u32[0]);
  AssertEquals('cmpge_ss eq lane1 preserve', LVecA.m128i_u32[1], LGe.m128i_u32[1]);
  AssertEquals('cmpge_ss eq lane2 preserve', LVecA.m128i_u32[2], LGe.m128i_u32[2]);
  AssertEquals('cmpge_ss eq lane3 preserve', LVecA.m128i_u32[3], LGe.m128i_u32[3]);

  // Case 3: lane0 1.0 vs 2.0 => gt/ge both false.
  LVecA.m128i_u32[0] := DWord($3F800000); // 1.0
  LVecA.m128i_u32[1] := DWord($80000000); // -0.0
  LVecA.m128i_u32[2] := DWord($3F800000); // 1.0
  LVecA.m128i_u32[3] := DWord($FF800000); // -Inf

  LVecB.m128i_u32[0] := DWord($40000000); // 2.0

  LGt := sse_cmpgt_ss(LVecA, LVecB);
  AssertEquals('cmpgt_ss bit lane0 1>2 false', DWord($00000000), LGt.m128i_u32[0]);
  AssertEquals('cmpgt_ss lt lane1 preserve', LVecA.m128i_u32[1], LGt.m128i_u32[1]);
  AssertEquals('cmpgt_ss lt lane2 preserve', LVecA.m128i_u32[2], LGt.m128i_u32[2]);
  AssertEquals('cmpgt_ss lt lane3 preserve', LVecA.m128i_u32[3], LGt.m128i_u32[3]);

  LGe := sse_cmpge_ss(LVecA, LVecB);
  AssertEquals('cmpge_ss bit lane0 1>=2 false', DWord($00000000), LGe.m128i_u32[0]);
  AssertEquals('cmpge_ss lt lane1 preserve', LVecA.m128i_u32[1], LGe.m128i_u32[1]);
  AssertEquals('cmpge_ss lt lane2 preserve', LVecA.m128i_u32[2], LGe.m128i_u32[2]);
  AssertEquals('cmpge_ss lt lane3 preserve', LVecA.m128i_u32[3], LGe.m128i_u32[3]);
end;


procedure TTestCase_TM128.Test_compare_duality_matrix;
const
  LVecPatternsA: array[0..3, 0..3] of DWord = (
    ($40400000, $40000000, $3F800000, $BF800000),
    ($80000000, $00000000, $C0000000, $7F800000),
    ($7F800000, $BF800000, $FF800000, $3F800000),
    ($7F800000, $FF800000, $40800000, $BF800000)
  );
  LVecPatternsB: array[0..3, 0..3] of DWord = (
    ($40000000, $40000000, $40800000, $C0000000),
    ($00000000, $80000000, $C0000000, $7F800000),
    ($7F800000, $C0000000, $00000000, $40000000),
    ($3F800000, $C0000000, $7F800000, $BF800000)
  );
var
  LVecA, LVecB: TM128;
  LGtPs, LLtSwapPs, LGePs, LLeSwapPs: TM128;
  LGtSs, LLtSwapSs, LGeSs, LLeSwapSs: TM128;
  LCaseIndex, LLaneIndex: Integer;
begin
  for LCaseIndex := 0 to High(LVecPatternsA) do
  begin
    for LLaneIndex := 0 to 3 do
    begin
      LVecA.m128i_u32[LLaneIndex] := LVecPatternsA[LCaseIndex, LLaneIndex];
      LVecB.m128i_u32[LLaneIndex] := LVecPatternsB[LCaseIndex, LLaneIndex];
    end;

    LGtPs := sse_cmpgt_ps(LVecA, LVecB);
    LLtSwapPs := sse_cmplt_ps(LVecB, LVecA);
    for LLaneIndex := 0 to 3 do
      AssertEquals('cmpgt_ps dual lane ' + IntToStr(LLaneIndex) + ' case ' + IntToStr(LCaseIndex),
        LGtPs.m128i_u32[LLaneIndex], LLtSwapPs.m128i_u32[LLaneIndex]);

    LGePs := sse_cmpge_ps(LVecA, LVecB);
    LLeSwapPs := sse_cmple_ps(LVecB, LVecA);
    for LLaneIndex := 0 to 3 do
      AssertEquals('cmpge_ps dual lane ' + IntToStr(LLaneIndex) + ' case ' + IntToStr(LCaseIndex),
        LGePs.m128i_u32[LLaneIndex], LLeSwapPs.m128i_u32[LLaneIndex]);

    LGtSs := sse_cmpgt_ss(LVecA, LVecB);
    LLtSwapSs := sse_cmplt_ss(LVecB, LVecA);
    AssertEquals('cmpgt_ss dual lane0 case ' + IntToStr(LCaseIndex), LGtSs.m128i_u32[0], LLtSwapSs.m128i_u32[0]);
    AssertEquals('cmpgt_ss preserve lane1 case ' + IntToStr(LCaseIndex), LVecA.m128i_u32[1], LGtSs.m128i_u32[1]);
    AssertEquals('cmpgt_ss preserve lane2 case ' + IntToStr(LCaseIndex), LVecA.m128i_u32[2], LGtSs.m128i_u32[2]);
    AssertEquals('cmpgt_ss preserve lane3 case ' + IntToStr(LCaseIndex), LVecA.m128i_u32[3], LGtSs.m128i_u32[3]);
    AssertEquals('cmplt_ss swap preserve lane1 case ' + IntToStr(LCaseIndex), LVecB.m128i_u32[1], LLtSwapSs.m128i_u32[1]);
    AssertEquals('cmplt_ss swap preserve lane2 case ' + IntToStr(LCaseIndex), LVecB.m128i_u32[2], LLtSwapSs.m128i_u32[2]);
    AssertEquals('cmplt_ss swap preserve lane3 case ' + IntToStr(LCaseIndex), LVecB.m128i_u32[3], LLtSwapSs.m128i_u32[3]);

    LGeSs := sse_cmpge_ss(LVecA, LVecB);
    LLeSwapSs := sse_cmple_ss(LVecB, LVecA);
    AssertEquals('cmpge_ss dual lane0 case ' + IntToStr(LCaseIndex), LGeSs.m128i_u32[0], LLeSwapSs.m128i_u32[0]);
    AssertEquals('cmpge_ss preserve lane1 case ' + IntToStr(LCaseIndex), LVecA.m128i_u32[1], LGeSs.m128i_u32[1]);
    AssertEquals('cmpge_ss preserve lane2 case ' + IntToStr(LCaseIndex), LVecA.m128i_u32[2], LGeSs.m128i_u32[2]);
    AssertEquals('cmpge_ss preserve lane3 case ' + IntToStr(LCaseIndex), LVecA.m128i_u32[3], LGeSs.m128i_u32[3]);
    AssertEquals('cmple_ss swap preserve lane1 case ' + IntToStr(LCaseIndex), LVecB.m128i_u32[1], LLeSwapSs.m128i_u32[1]);
    AssertEquals('cmple_ss swap preserve lane2 case ' + IntToStr(LCaseIndex), LVecB.m128i_u32[2], LLeSwapSs.m128i_u32[2]);
    AssertEquals('cmple_ss swap preserve lane3 case ' + IntToStr(LCaseIndex), LVecB.m128i_u32[3], LLeSwapSs.m128i_u32[3]);
  end;
end;


procedure TTestCase_TM128.Test_cmpgt_cmpge_ps_inf_matrix;
const
  LVecPatternsA: array[0..2, 0..3] of DWord = (
    ($7F800000, $7F800000, $FF800000, $3F800000),
    ($FF800000, $BF800000, $00000000, $7F800000),
    ($7F800000, $FF800000, $7F800000, $FF800000)
  );
  LVecPatternsB: array[0..2, 0..3] of DWord = (
    ($7F800000, $3F800000, $BF800000, $FF800000),
    ($FF800000, $FF800000, $7F800000, $FF800000),
    ($7F800000, $7F800000, $FF800000, $FF800000)
  );
  LExpectedGt: array[0..2, 0..3] of DWord = (
    ($00000000, $FFFFFFFF, $00000000, $FFFFFFFF),
    ($00000000, $FFFFFFFF, $00000000, $FFFFFFFF),
    ($00000000, $00000000, $FFFFFFFF, $00000000)
  );
  LExpectedGe: array[0..2, 0..3] of DWord = (
    ($FFFFFFFF, $FFFFFFFF, $00000000, $FFFFFFFF),
    ($FFFFFFFF, $FFFFFFFF, $00000000, $FFFFFFFF),
    ($FFFFFFFF, $00000000, $FFFFFFFF, $FFFFFFFF)
  );
var
  LVecA, LVecB: TM128;
  LGt, LGe: TM128;
  LCaseIndex, LLaneIndex: Integer;
begin
  for LCaseIndex := 0 to High(LVecPatternsA) do
  begin
    for LLaneIndex := 0 to 3 do
    begin
      LVecA.m128i_u32[LLaneIndex] := LVecPatternsA[LCaseIndex, LLaneIndex];
      LVecB.m128i_u32[LLaneIndex] := LVecPatternsB[LCaseIndex, LLaneIndex];
    end;

    LGt := sse_cmpgt_ps(LVecA, LVecB);
    LGe := sse_cmpge_ps(LVecA, LVecB);

    for LLaneIndex := 0 to 3 do
    begin
      AssertEquals(
        'cmpgt_ps inf-matrix lane ' + IntToStr(LLaneIndex) + ' case ' + IntToStr(LCaseIndex),
        LExpectedGt[LCaseIndex, LLaneIndex],
        LGt.m128i_u32[LLaneIndex]
      );
      AssertEquals(
        'cmpge_ps inf-matrix lane ' + IntToStr(LLaneIndex) + ' case ' + IntToStr(LCaseIndex),
        LExpectedGe[LCaseIndex, LLaneIndex],
        LGe.m128i_u32[LLaneIndex]
      );
    end;
  end;
end;


procedure TTestCase_TM128.Test_compare_partition_ps_finite_matrix;
const
  LVecPatternsA: array[0..3, 0..3] of DWord = (
    ($3F800000, $40000000, $40400000, $40800000),
    ($80000000, $00000000, $BF800000, $3F800000),
    ($7F800000, $FF800000, $3F800000, $BF800000),
    ($40400000, $40400000, $C0000000, $7F800000)
  );
  LVecPatternsB: array[0..3, 0..3] of DWord = (
    ($40000000, $40000000, $3F800000, $40800000),
    ($00000000, $80000000, $BF800000, $40000000),
    ($3F800000, $FF800000, $7F800000, $FF800000),
    ($40400000, $3F800000, $BF800000, $7F800000)
  );
var
  LVecA, LVecB: TM128;
  LGt, LGe, LLt, LLe: TM128;
  LCaseIndex, LLaneIndex: Integer;
  LGtLane, LGeLane, LLtLane, LLeLane: DWord;
begin
  for LCaseIndex := 0 to High(LVecPatternsA) do
  begin
    for LLaneIndex := 0 to 3 do
    begin
      LVecA.m128i_u32[LLaneIndex] := LVecPatternsA[LCaseIndex, LLaneIndex];
      LVecB.m128i_u32[LLaneIndex] := LVecPatternsB[LCaseIndex, LLaneIndex];
    end;

    LGt := sse_cmpgt_ps(LVecA, LVecB);
    LGe := sse_cmpge_ps(LVecA, LVecB);
    LLt := sse_cmplt_ps(LVecA, LVecB);
    LLe := sse_cmple_ps(LVecA, LVecB);

    for LLaneIndex := 0 to 3 do
    begin
      LGtLane := LGt.m128i_u32[LLaneIndex];
      LGeLane := LGe.m128i_u32[LLaneIndex];
      LLtLane := LLt.m128i_u32[LLaneIndex];
      LLeLane := LLe.m128i_u32[LLaneIndex];

      AssertEquals(
        'cmpgt/cmple partition OR lane ' + IntToStr(LLaneIndex) + ' case ' + IntToStr(LCaseIndex),
        DWord($FFFFFFFF),
        LGtLane or LLeLane
      );
      AssertEquals(
        'cmpgt/cmple partition AND lane ' + IntToStr(LLaneIndex) + ' case ' + IntToStr(LCaseIndex),
        DWord($00000000),
        LGtLane and LLeLane
      );

      AssertEquals(
        'cmpge/cmplt partition OR lane ' + IntToStr(LLaneIndex) + ' case ' + IntToStr(LCaseIndex),
        DWord($FFFFFFFF),
        LGeLane or LLtLane
      );
      AssertEquals(
        'cmpge/cmplt partition AND lane ' + IntToStr(LLaneIndex) + ' case ' + IntToStr(LCaseIndex),
        DWord($00000000),
        LGeLane and LLtLane
      );
    end;
  end;
end;


procedure TTestCase_TM128.Test_compare_masks_movemask_mapping;
const
  LVecPatternsA: array[0..3, 0..3] of DWord = (
    ($3F800000, $40000000, $40400000, $40800000),
    ($BF800000, $C0000000, $7F800000, $FF800000),
    ($00000000, $80000000, $40A00000, $C0A00000),
    ($7F800000, $FF800000, $3F800000, $BF800000)
  );
  LVecPatternsB: array[0..3, 0..3] of DWord = (
    ($00000000, $40000000, $40800000, $40800000),
    ($BF800000, $C0400000, $42C80000, $FF800000),
    ($80000000, $00000000, $40A00000, $C0C00000),
    ($7F800000, $FF800000, $40000000, $C0000000)
  );
  LExpectedGt: array[0..3] of Integer = (1, 6, 8, 8);
  LExpectedGe: array[0..3] of Integer = (11, 15, 15, 11);
  LExpectedLt: array[0..3] of Integer = (4, 0, 0, 4);
  LExpectedLe: array[0..3] of Integer = (14, 9, 7, 7);
  LExpectedEq: array[0..3] of Integer = (10, 9, 7, 3);
  LExpectedNeq: array[0..3] of Integer = (5, 6, 8, 12);
var
  LVecA, LVecB: TM128;
  LCaseIndex, LLaneIndex: Integer;
  LMaskGt, LMaskGe, LMaskLt, LMaskLe, LMaskEq, LMaskNeq: Integer;
begin
  for LCaseIndex := 0 to High(LVecPatternsA) do
  begin
    for LLaneIndex := 0 to 3 do
    begin
      LVecA.m128i_u32[LLaneIndex] := LVecPatternsA[LCaseIndex, LLaneIndex];
      LVecB.m128i_u32[LLaneIndex] := LVecPatternsB[LCaseIndex, LLaneIndex];
    end;

    LMaskGt := sse_movemask_ps(sse_cmpgt_ps(LVecA, LVecB));
    LMaskGe := sse_movemask_ps(sse_cmpge_ps(LVecA, LVecB));
    LMaskLt := sse_movemask_ps(sse_cmplt_ps(LVecA, LVecB));
    LMaskLe := sse_movemask_ps(sse_cmple_ps(LVecA, LVecB));
    LMaskEq := sse_movemask_ps(sse_cmpeq_ps(LVecA, LVecB));
    LMaskNeq := sse_movemask_ps(sse_cmpneq_ps(LVecA, LVecB));

    AssertEquals('cmpgt->movemask case ' + IntToStr(LCaseIndex), LExpectedGt[LCaseIndex], LMaskGt);
    AssertEquals('cmpge->movemask case ' + IntToStr(LCaseIndex), LExpectedGe[LCaseIndex], LMaskGe);
    AssertEquals('cmplt->movemask case ' + IntToStr(LCaseIndex), LExpectedLt[LCaseIndex], LMaskLt);
    AssertEquals('cmple->movemask case ' + IntToStr(LCaseIndex), LExpectedLe[LCaseIndex], LMaskLe);
    AssertEquals('cmpeq->movemask case ' + IntToStr(LCaseIndex), LExpectedEq[LCaseIndex], LMaskEq);
    AssertEquals('cmpneq->movemask case ' + IntToStr(LCaseIndex), LExpectedNeq[LCaseIndex], LMaskNeq);

    AssertEquals('cmpgt/cmple partition mask case ' + IntToStr(LCaseIndex), 15, LMaskGt or LMaskLe);
    AssertEquals('cmpge/cmplt partition mask case ' + IntToStr(LCaseIndex), 15, LMaskGe or LMaskLt);
    AssertEquals('cmpeq/cmpneq partition mask case ' + IntToStr(LCaseIndex), 15, LMaskEq or LMaskNeq);
  end;
end;


procedure TTestCase_TM128.Test_compare_partition_eq_lt_gt_neq_matrix;
const
  LVecPatternsA: array[0..3, 0..3] of DWord = (
    ($3F800000, $40000000, $40400000, $40800000),
    ($00000000, $80000000, $7F800000, $FF800000),
    ($C0400000, $C0000000, $BF800000, $00000000),
    ($7F800000, $FF800000, $40A00000, $C0A00000)
  );
  LVecPatternsB: array[0..3, 0..3] of DWord = (
    ($3F800000, $40400000, $40000000, $40800000),
    ($80000000, $00000000, $42C80000, $FF800000),
    ($C0800000, $C0000000, $3F800000, $00000000),
    ($7F800000, $FF800000, $40800000, $C0C00000)
  );
  LExpectedEq: array[0..3] of Integer = (9, 11, 10, 3);
  LExpectedLt: array[0..3] of Integer = (2, 0, 4, 0);
  LExpectedGt: array[0..3] of Integer = (4, 4, 1, 12);
  LExpectedNeq: array[0..3] of Integer = (6, 4, 5, 12);
var
  LVecA, LVecB: TM128;
  LCaseIndex, LLaneIndex: Integer;
  LMaskEq, LMaskLt, LMaskGt, LMaskNeq: Integer;
begin
  for LCaseIndex := 0 to High(LVecPatternsA) do
  begin
    for LLaneIndex := 0 to 3 do
    begin
      LVecA.m128i_u32[LLaneIndex] := LVecPatternsA[LCaseIndex, LLaneIndex];
      LVecB.m128i_u32[LLaneIndex] := LVecPatternsB[LCaseIndex, LLaneIndex];
    end;

    LMaskEq := sse_movemask_ps(sse_cmpeq_ps(LVecA, LVecB));
    LMaskLt := sse_movemask_ps(sse_cmplt_ps(LVecA, LVecB));
    LMaskGt := sse_movemask_ps(sse_cmpgt_ps(LVecA, LVecB));
    LMaskNeq := sse_movemask_ps(sse_cmpneq_ps(LVecA, LVecB));

    AssertEquals('cmpeq mask case ' + IntToStr(LCaseIndex), LExpectedEq[LCaseIndex], LMaskEq);
    AssertEquals('cmplt mask case ' + IntToStr(LCaseIndex), LExpectedLt[LCaseIndex], LMaskLt);
    AssertEquals('cmpgt mask case ' + IntToStr(LCaseIndex), LExpectedGt[LCaseIndex], LMaskGt);
    AssertEquals('cmpneq mask case ' + IntToStr(LCaseIndex), LExpectedNeq[LCaseIndex], LMaskNeq);

    AssertEquals('eq/lt disjoint case ' + IntToStr(LCaseIndex), 0, LMaskEq and LMaskLt);
    AssertEquals('eq/gt disjoint case ' + IntToStr(LCaseIndex), 0, LMaskEq and LMaskGt);
    AssertEquals('lt/gt disjoint case ' + IntToStr(LCaseIndex), 0, LMaskLt and LMaskGt);

    AssertEquals('eq/lt/gt partition case ' + IntToStr(LCaseIndex), 15, LMaskEq or LMaskLt or LMaskGt);
    AssertEquals('neq complement case ' + IntToStr(LCaseIndex), LMaskLt or LMaskGt, LMaskNeq);
  end;
end;


procedure TTestCase_TM128.Test_compare_partition_ss_lane_preservation_matrix;
const
  LVecPatternsA: array[0..3, 0..3] of DWord = (
    ($3F800000, $7FC01234, $FF800000, $00000001),
    ($3F800000, $80000000, $7F800000, $FFC05678),
    ($40400000, $7F7FFFFF, $C0000000, $80000000),
    ($80000000, $7FC0ABCD, $FF800000, $00000001)
  );
  LVecPatternsB: array[0..3, 0..3] of DWord = (
    ($3F800000, $40000000, $40400000, $40800000),
    ($40000000, $3F800000, $40400000, $40800000),
    ($40000000, $3F800000, $40400000, $40800000),
    ($00000000, $3F800000, $40400000, $40800000)
  );
  LExpectedEq: array[0..3] of DWord = ($FFFFFFFF, $00000000, $00000000, $FFFFFFFF);
  LExpectedLt: array[0..3] of DWord = ($00000000, $FFFFFFFF, $00000000, $00000000);
  LExpectedGt: array[0..3] of DWord = ($00000000, $00000000, $FFFFFFFF, $00000000);
  LExpectedNeq: array[0..3] of DWord = ($00000000, $FFFFFFFF, $FFFFFFFF, $00000000);
var
  LVecA, LVecB: TM128;
  LEq, LLt, LGt, LNeq: TM128;
  LCaseIndex, LLaneIndex: Integer;
begin
  for LCaseIndex := 0 to High(LVecPatternsA) do
  begin
    for LLaneIndex := 0 to 3 do
    begin
      LVecA.m128i_u32[LLaneIndex] := LVecPatternsA[LCaseIndex, LLaneIndex];
      LVecB.m128i_u32[LLaneIndex] := LVecPatternsB[LCaseIndex, LLaneIndex];
    end;

    LEq := sse_cmpeq_ss(LVecA, LVecB);
    LLt := sse_cmplt_ss(LVecA, LVecB);
    LGt := sse_cmpgt_ss(LVecA, LVecB);
    LNeq := sse_cmpneq_ss(LVecA, LVecB);

    AssertEquals('cmpeq_ss lane0 mask case ' + IntToStr(LCaseIndex), LExpectedEq[LCaseIndex], LEq.m128i_u32[0]);
    AssertEquals('cmplt_ss lane0 mask case ' + IntToStr(LCaseIndex), LExpectedLt[LCaseIndex], LLt.m128i_u32[0]);
    AssertEquals('cmpgt_ss lane0 mask case ' + IntToStr(LCaseIndex), LExpectedGt[LCaseIndex], LGt.m128i_u32[0]);
    AssertEquals('cmpneq_ss lane0 mask case ' + IntToStr(LCaseIndex), LExpectedNeq[LCaseIndex], LNeq.m128i_u32[0]);

    for LLaneIndex := 1 to 3 do
    begin
      AssertEquals('cmpeq_ss preserve lane ' + IntToStr(LLaneIndex) + ' case ' + IntToStr(LCaseIndex),
        LVecA.m128i_u32[LLaneIndex], LEq.m128i_u32[LLaneIndex]);
      AssertEquals('cmplt_ss preserve lane ' + IntToStr(LLaneIndex) + ' case ' + IntToStr(LCaseIndex),
        LVecA.m128i_u32[LLaneIndex], LLt.m128i_u32[LLaneIndex]);
      AssertEquals('cmpgt_ss preserve lane ' + IntToStr(LLaneIndex) + ' case ' + IntToStr(LCaseIndex),
        LVecA.m128i_u32[LLaneIndex], LGt.m128i_u32[LLaneIndex]);
      AssertEquals('cmpneq_ss preserve lane ' + IntToStr(LLaneIndex) + ' case ' + IntToStr(LCaseIndex),
        LVecA.m128i_u32[LLaneIndex], LNeq.m128i_u32[LLaneIndex]);
    end;

    AssertEquals('ss partition eq|lt|gt case ' + IntToStr(LCaseIndex),
      DWord($FFFFFFFF),
      LEq.m128i_u32[0] or LLt.m128i_u32[0] or LGt.m128i_u32[0]);
    AssertEquals('ss neq complement case ' + IntToStr(LCaseIndex),
      LLt.m128i_u32[0] or LGt.m128i_u32[0],
      LNeq.m128i_u32[0]);
  end;
end;


procedure TTestCase_TM128.Test_compare_ge_le_composition_ps_ss_matrix;
const
  LVecPatternsA: array[0..3, 0..3] of DWord = (
    ($3F800000, $40000000, $40400000, $40800000),
    ($BF800000, $C0000000, $7F800000, $FF800000),
    ($00000000, $80000000, $40A00000, $C0A00000),
    ($7F800000, $FF800000, $3F800000, $BF800000)
  );
  LVecPatternsB: array[0..3, 0..3] of DWord = (
    ($00000000, $40000000, $40800000, $40800000),
    ($BF800000, $C0400000, $42C80000, $FF800000),
    ($80000000, $00000000, $40A00000, $C0C00000),
    ($7F800000, $FF800000, $40000000, $C0000000)
  );
var
  LVecA, LVecB: TM128;
  LGePsMask, LGtPsMask, LEqPsMask: Integer;
  LLePsMask, LLtPsMask: Integer;
  LGeSs, LGtSs, LEqSs, LLeSs, LLtSs: TM128;
  LCaseIndex, LLaneIndex: Integer;
begin
  for LCaseIndex := 0 to High(LVecPatternsA) do
  begin
    for LLaneIndex := 0 to 3 do
    begin
      LVecA.m128i_u32[LLaneIndex] := LVecPatternsA[LCaseIndex, LLaneIndex];
      LVecB.m128i_u32[LLaneIndex] := LVecPatternsB[LCaseIndex, LLaneIndex];
    end;

    LGePsMask := sse_movemask_ps(sse_cmpge_ps(LVecA, LVecB));
    LGtPsMask := sse_movemask_ps(sse_cmpgt_ps(LVecA, LVecB));
    LEqPsMask := sse_movemask_ps(sse_cmpeq_ps(LVecA, LVecB));
    AssertEquals('cmpge_ps composition case ' + IntToStr(LCaseIndex), LGePsMask, LGtPsMask or LEqPsMask);

    LLePsMask := sse_movemask_ps(sse_cmple_ps(LVecA, LVecB));
    LLtPsMask := sse_movemask_ps(sse_cmplt_ps(LVecA, LVecB));
    AssertEquals('cmple_ps composition case ' + IntToStr(LCaseIndex), LLePsMask, LLtPsMask or LEqPsMask);

    LGeSs := sse_cmpge_ss(LVecA, LVecB);
    LGtSs := sse_cmpgt_ss(LVecA, LVecB);
    LEqSs := sse_cmpeq_ss(LVecA, LVecB);
    LLeSs := sse_cmple_ss(LVecA, LVecB);
    LLtSs := sse_cmplt_ss(LVecA, LVecB);

    AssertEquals('cmpge_ss composition lane0 case ' + IntToStr(LCaseIndex),
      LGeSs.m128i_u32[0], LGtSs.m128i_u32[0] or LEqSs.m128i_u32[0]);
    AssertEquals('cmple_ss composition lane0 case ' + IntToStr(LCaseIndex),
      LLeSs.m128i_u32[0], LLtSs.m128i_u32[0] or LEqSs.m128i_u32[0]);

    for LLaneIndex := 1 to 3 do
    begin
      AssertEquals('cmpge_ss preserve lane ' + IntToStr(LLaneIndex) + ' case ' + IntToStr(LCaseIndex),
        LVecA.m128i_u32[LLaneIndex], LGeSs.m128i_u32[LLaneIndex]);
      AssertEquals('cmpgt_ss preserve lane ' + IntToStr(LLaneIndex) + ' case ' + IntToStr(LCaseIndex),
        LVecA.m128i_u32[LLaneIndex], LGtSs.m128i_u32[LLaneIndex]);
      AssertEquals('cmpeq_ss preserve lane ' + IntToStr(LLaneIndex) + ' case ' + IntToStr(LCaseIndex),
        LVecA.m128i_u32[LLaneIndex], LEqSs.m128i_u32[LLaneIndex]);
      AssertEquals('cmple_ss preserve lane ' + IntToStr(LLaneIndex) + ' case ' + IntToStr(LCaseIndex),
        LVecA.m128i_u32[LLaneIndex], LLeSs.m128i_u32[LLaneIndex]);
      AssertEquals('cmplt_ss preserve lane ' + IntToStr(LLaneIndex) + ' case ' + IntToStr(LCaseIndex),
        LVecA.m128i_u32[LLaneIndex], LLtSs.m128i_u32[LLaneIndex]);
    end;
  end;
end;


procedure TTestCase_TM128.Test_compare_ss_movemask_bit0_mapping;
const
  LUPPER_MASK_FROM_A = 10; // lane1 negative(bit1), lane2 positive(bit2=0), lane3 negative(bit3)
var
  LVecA, LVecB: TM128;
  LResult: TM128;
  LMask: Integer;

  procedure AssertUpperLanesPreserved(const aResult: TM128; const aTag: string);
  begin
    AssertEquals(aTag + ' preserve lane1', LVecA.m128i_u32[1], aResult.m128i_u32[1]);
    AssertEquals(aTag + ' preserve lane2', LVecA.m128i_u32[2], aResult.m128i_u32[2]);
    AssertEquals(aTag + ' preserve lane3', LVecA.m128i_u32[3], aResult.m128i_u32[3]);
  end;
begin
  // Upper lanes use opposite sign patterns between A/B, so movemask bits1..3 can detect wrong source.
  LVecA.m128i_u32[1] := DWord($BF800000); // -1.0  -> sign bit 1 (bit1)
  LVecA.m128i_u32[2] := DWord($3F800000); // +1.0  -> sign bit 0 (bit2)
  LVecA.m128i_u32[3] := DWord($FF800000); // -Inf  -> sign bit 1 (bit3)

  LVecB.m128i_u32[1] := DWord($3F800000); // +1.0
  LVecB.m128i_u32[2] := DWord($BF800000); // -1.0
  LVecB.m128i_u32[3] := DWord($7F800000); // +Inf

  // cmpeq_ss true -> lane0 mask=1, movemask should only add bit0.
  LVecA.m128i_u32[0] := DWord($40000000); // 2.0
  LVecB.m128i_u32[0] := DWord($40000000); // 2.0
  LResult := sse_cmpeq_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmpeq_ss true movemask bit0 mapping', LUPPER_MASK_FROM_A or 1, LMask);
  AssertUpperLanesPreserved(LResult, 'cmpeq_ss true');

  // cmpeq_ss false -> lane0 mask=0, movemask keeps only upper bits from A.
  LVecB.m128i_u32[0] := DWord($40400000); // 3.0
  LResult := sse_cmpeq_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmpeq_ss false movemask bit0 mapping', LUPPER_MASK_FROM_A, LMask);
  AssertUpperLanesPreserved(LResult, 'cmpeq_ss false');

  // cmpgt_ss true -> lane0 mask=1.
  LVecA.m128i_u32[0] := DWord($40400000); // 3.0
  LVecB.m128i_u32[0] := DWord($40000000); // 2.0
  LResult := sse_cmpgt_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmpgt_ss true movemask bit0 mapping', LUPPER_MASK_FROM_A or 1, LMask);
  AssertUpperLanesPreserved(LResult, 'cmpgt_ss true');

  // cmpgt_ss false -> lane0 mask=0.
  LVecA.m128i_u32[0] := DWord($3F800000); // 1.0
  LVecB.m128i_u32[0] := DWord($40000000); // 2.0
  LResult := sse_cmpgt_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmpgt_ss false movemask bit0 mapping', LUPPER_MASK_FROM_A, LMask);
  AssertUpperLanesPreserved(LResult, 'cmpgt_ss false');

  // cmpneq_ss true -> lane0 mask=1.
  LVecA.m128i_u32[0] := DWord($3F800000); // 1.0
  LVecB.m128i_u32[0] := DWord($40000000); // 2.0
  LResult := sse_cmpneq_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmpneq_ss true movemask bit0 mapping', LUPPER_MASK_FROM_A or 1, LMask);
  AssertUpperLanesPreserved(LResult, 'cmpneq_ss true');

  // cmpneq_ss false (-0 == +0) -> lane0 mask=0.
  LVecA.m128i_u32[0] := DWord($80000000); // -0.0
  LVecB.m128i_u32[0] := DWord($00000000); // +0.0
  LResult := sse_cmpneq_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmpneq_ss false movemask bit0 mapping', LUPPER_MASK_FROM_A, LMask);
  AssertUpperLanesPreserved(LResult, 'cmpneq_ss false');
end;


procedure TTestCase_TM128.Test_cmpge_cmple_ss_edge_movemask_mapping;
const
  LUPPER_MASK_FROM_A = 10; // lane1 negative(bit1), lane2 positive(bit2=0), lane3 negative(bit3)
var
  LVecA, LVecB: TM128;
  LResult: TM128;
  LMask: Integer;

  procedure AssertUpperLanesPreserved(const aResult: TM128; const aTag: string);
  begin
    AssertEquals(aTag + ' preserve lane1', LVecA.m128i_u32[1], aResult.m128i_u32[1]);
    AssertEquals(aTag + ' preserve lane2', LVecA.m128i_u32[2], aResult.m128i_u32[2]);
    AssertEquals(aTag + ' preserve lane3', LVecA.m128i_u32[3], aResult.m128i_u32[3]);
  end;
begin
  // Upper lanes are intentionally sign-opposite in B to verify result upper lanes come from A.
  LVecA.m128i_u32[1] := DWord($BF800000); // -1.0
  LVecA.m128i_u32[2] := DWord($3F800000); // +1.0
  LVecA.m128i_u32[3] := DWord($FF800000); // -Inf

  LVecB.m128i_u32[1] := DWord($3F800000); // +1.0
  LVecB.m128i_u32[2] := DWord($BF800000); // -1.0
  LVecB.m128i_u32[3] := DWord($7F800000); // +Inf

  // cmpge_ss edge cases.
  LVecA.m128i_u32[0] := DWord($80000000); // -0.0
  LVecB.m128i_u32[0] := DWord($00000000); // +0.0
  LResult := sse_cmpge_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmpge_ss -0>=+0 bit0 mapping', LUPPER_MASK_FROM_A or 1, LMask);
  AssertUpperLanesPreserved(LResult, 'cmpge_ss -0>=+0');

  LVecA.m128i_u32[0] := DWord($FF800000); // -Inf
  LVecB.m128i_u32[0] := DWord($7F800000); // +Inf
  LResult := sse_cmpge_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmpge_ss -inf>=+inf bit0 mapping', LUPPER_MASK_FROM_A, LMask);
  AssertUpperLanesPreserved(LResult, 'cmpge_ss -inf>=+inf');

  LVecA.m128i_u32[0] := DWord($7F800000); // +Inf
  LVecB.m128i_u32[0] := DWord($7F800000); // +Inf
  LResult := sse_cmpge_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmpge_ss +inf>=+inf bit0 mapping', LUPPER_MASK_FROM_A or 1, LMask);
  AssertUpperLanesPreserved(LResult, 'cmpge_ss +inf>=+inf');

  // cmple_ss edge cases.
  LVecA.m128i_u32[0] := DWord($80000000); // -0.0
  LVecB.m128i_u32[0] := DWord($00000000); // +0.0
  LResult := sse_cmple_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmple_ss -0<=+0 bit0 mapping', LUPPER_MASK_FROM_A or 1, LMask);
  AssertUpperLanesPreserved(LResult, 'cmple_ss -0<=+0');

  LVecA.m128i_u32[0] := DWord($7F800000); // +Inf
  LVecB.m128i_u32[0] := DWord($FF800000); // -Inf
  LResult := sse_cmple_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmple_ss +inf<=-inf bit0 mapping', LUPPER_MASK_FROM_A, LMask);
  AssertUpperLanesPreserved(LResult, 'cmple_ss +inf<=-inf');

  LVecA.m128i_u32[0] := DWord($FF800000); // -Inf
  LVecB.m128i_u32[0] := DWord($7F800000); // +Inf
  LResult := sse_cmple_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmple_ss -inf<=+inf bit0 mapping', LUPPER_MASK_FROM_A or 1, LMask);
  AssertUpperLanesPreserved(LResult, 'cmple_ss -inf<=+inf');
end;


procedure TTestCase_TM128.Test_cmpord_cmpunord_ss_movemask_mapping;
const
  LUPPER_MASK_FROM_A = 10; // lane1 negative(bit1), lane2 positive(bit2=0), lane3 negative(bit3)
var
  LVecA, LVecB: TM128;
  LResult: TM128;
  LMask: Integer;

  procedure AssertUpperLanesPreserved(const aResult: TM128; const aTag: string);
  begin
    AssertEquals(aTag + ' preserve lane1', LVecA.m128i_u32[1], aResult.m128i_u32[1]);
    AssertEquals(aTag + ' preserve lane2', LVecA.m128i_u32[2], aResult.m128i_u32[2]);
    AssertEquals(aTag + ' preserve lane3', LVecA.m128i_u32[3], aResult.m128i_u32[3]);
  end;
begin
  // Upper lanes are sign-opposite between A/B for stronger preservation checks.
  LVecA.m128i_u32[1] := DWord($BF800000); // -1.0
  LVecA.m128i_u32[2] := DWord($3F800000); // +1.0
  LVecA.m128i_u32[3] := DWord($FF800000); // -Inf

  LVecB.m128i_u32[1] := DWord($3F800000); // +1.0
  LVecB.m128i_u32[2] := DWord($BF800000); // -1.0
  LVecB.m128i_u32[3] := DWord($7F800000); // +Inf

  // Ordered finite vs finite: cmpord=true, cmpunord=false.
  LVecA.m128i_u32[0] := DWord($3F800000); // 1.0
  LVecB.m128i_u32[0] := DWord($40000000); // 2.0
  LResult := sse_cmpord_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmpord_ss finite ordered bit0 mapping', LUPPER_MASK_FROM_A or 1, LMask);
  AssertUpperLanesPreserved(LResult, 'cmpord_ss finite ordered');

  LResult := sse_cmpunord_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmpunord_ss finite ordered bit0 mapping', LUPPER_MASK_FROM_A, LMask);
  AssertUpperLanesPreserved(LResult, 'cmpunord_ss finite ordered');

  // Ordered Inf vs Inf: cmpord=true, cmpunord=false.
  LVecA.m128i_u32[0] := DWord($7F800000); // +Inf
  LVecB.m128i_u32[0] := DWord($FF800000); // -Inf
  LResult := sse_cmpord_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmpord_ss inf ordered bit0 mapping', LUPPER_MASK_FROM_A or 1, LMask);
  AssertUpperLanesPreserved(LResult, 'cmpord_ss inf ordered');

  LResult := sse_cmpunord_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmpunord_ss inf ordered bit0 mapping', LUPPER_MASK_FROM_A, LMask);
  AssertUpperLanesPreserved(LResult, 'cmpunord_ss inf ordered');

  // Unordered with qNaN payload in A: cmpord=false, cmpunord=true.
  LVecA.m128i_u32[0] := DWord($7FC0ABCD); // qNaN payload
  LVecB.m128i_u32[0] := DWord($3F800000); // 1.0
  LResult := sse_cmpord_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmpord_ss qnan unordered bit0 mapping', LUPPER_MASK_FROM_A, LMask);
  AssertUpperLanesPreserved(LResult, 'cmpord_ss qnan unordered');

  LResult := sse_cmpunord_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmpunord_ss qnan unordered bit0 mapping', LUPPER_MASK_FROM_A or 1, LMask);
  AssertUpperLanesPreserved(LResult, 'cmpunord_ss qnan unordered');

  // Unordered with qNaN payload in B: cmpord=false, cmpunord=true.
  LVecA.m128i_u32[0] := DWord($40000000); // 2.0
  LVecB.m128i_u32[0] := DWord($FFC01234); // -qNaN payload
  LResult := sse_cmpord_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmpord_ss b-qnan unordered bit0 mapping', LUPPER_MASK_FROM_A, LMask);
  AssertUpperLanesPreserved(LResult, 'cmpord_ss b-qnan unordered');

  LResult := sse_cmpunord_ss(LVecA, LVecB);
  LMask := sse_movemask_ps(LResult);
  AssertEquals('cmpunord_ss b-qnan unordered bit0 mapping', LUPPER_MASK_FROM_A or 1, LMask);
  AssertUpperLanesPreserved(LResult, 'cmpunord_ss b-qnan unordered');
end;


procedure TTestCase_TM128.Test_compare_ss_family_consistency_ordered_matrix;
const
  LUPPER_MASK_FROM_A = 10; // lane1 negative(bit1), lane2 positive(bit2=0), lane3 negative(bit3)
  LCaseCount = 5;
  LCaseA0: array[0..LCaseCount - 1] of DWord = (
    $3F800000, // 1.0  (eq)
    $3F800000, // 1.0  (lt)
    $40400000, // 3.0  (gt)
    $80000000, // -0.0 (eq with +0.0)
    $7F800000  // +Inf (gt over -Inf)
  );
  LCaseB0: array[0..LCaseCount - 1] of DWord = (
    $3F800000, // 1.0
    $40000000, // 2.0
    $40000000, // 2.0
    $00000000, // +0.0
    $FF800000  // -Inf
  );
  LExpectedEqBit0: array[0..LCaseCount - 1] of Integer = (1, 0, 0, 1, 0);
  LExpectedNeqBit0: array[0..LCaseCount - 1] of Integer = (0, 1, 1, 0, 1);
  LExpectedGtBit0: array[0..LCaseCount - 1] of Integer = (0, 0, 1, 0, 1);
  LExpectedGeBit0: array[0..LCaseCount - 1] of Integer = (1, 0, 1, 1, 1);
  LExpectedLtBit0: array[0..LCaseCount - 1] of Integer = (0, 1, 0, 0, 0);
  LExpectedLeBit0: array[0..LCaseCount - 1] of Integer = (1, 1, 0, 1, 0);
  LExpectedOrdBit0: array[0..LCaseCount - 1] of Integer = (1, 1, 1, 1, 1);
  LExpectedUnordBit0: array[0..LCaseCount - 1] of Integer = (0, 0, 0, 0, 0);
var
  LVecA, LVecB: TM128;
  LEq, LNeq, LGt, LGe, LLt, LLe, LOrd, LUnord: TM128;
  LCaseIndex, LLaneIndex: Integer;

  procedure AssertUpperLanesPreserved(const aResult: TM128; const aTag: string);
  begin
    AssertEquals(aTag + ' preserve lane1', LVecA.m128i_u32[1], aResult.m128i_u32[1]);
    AssertEquals(aTag + ' preserve lane2', LVecA.m128i_u32[2], aResult.m128i_u32[2]);
    AssertEquals(aTag + ' preserve lane3', LVecA.m128i_u32[3], aResult.m128i_u32[3]);
  end;

  procedure AssertMaskBit0(const aResult: TM128; const aExpectedBit0: Integer; const aTag: string);
  var
    LMask: Integer;
  begin
    LMask := sse_movemask_ps(aResult);
    AssertEquals(aTag + ' movemask bit0 mapping', LUPPER_MASK_FROM_A or aExpectedBit0, LMask);
  end;
begin
  // Upper lanes use opposite signs between A/B to detect wrong-lane source quickly.
  LVecA.m128i_u32[1] := DWord($BF800000); // -1.0
  LVecA.m128i_u32[2] := DWord($3F800000); // +1.0
  LVecA.m128i_u32[3] := DWord($FF800000); // -Inf

  LVecB.m128i_u32[1] := DWord($3F800000); // +1.0
  LVecB.m128i_u32[2] := DWord($BF800000); // -1.0
  LVecB.m128i_u32[3] := DWord($7F800000); // +Inf

  for LCaseIndex := 0 to LCaseCount - 1 do
  begin
    LVecA.m128i_u32[0] := LCaseA0[LCaseIndex];
    LVecB.m128i_u32[0] := LCaseB0[LCaseIndex];

    LEq := sse_cmpeq_ss(LVecA, LVecB);
    LNeq := sse_cmpneq_ss(LVecA, LVecB);
    LGt := sse_cmpgt_ss(LVecA, LVecB);
    LGe := sse_cmpge_ss(LVecA, LVecB);
    LLt := sse_cmplt_ss(LVecA, LVecB);
    LLe := sse_cmple_ss(LVecA, LVecB);
    LOrd := sse_cmpord_ss(LVecA, LVecB);
    LUnord := sse_cmpunord_ss(LVecA, LVecB);

    AssertMaskBit0(LEq, LExpectedEqBit0[LCaseIndex], 'cmpeq_ss case ' + IntToStr(LCaseIndex));
    AssertMaskBit0(LNeq, LExpectedNeqBit0[LCaseIndex], 'cmpneq_ss case ' + IntToStr(LCaseIndex));
    AssertMaskBit0(LGt, LExpectedGtBit0[LCaseIndex], 'cmpgt_ss case ' + IntToStr(LCaseIndex));
    AssertMaskBit0(LGe, LExpectedGeBit0[LCaseIndex], 'cmpge_ss case ' + IntToStr(LCaseIndex));
    AssertMaskBit0(LLt, LExpectedLtBit0[LCaseIndex], 'cmplt_ss case ' + IntToStr(LCaseIndex));
    AssertMaskBit0(LLe, LExpectedLeBit0[LCaseIndex], 'cmple_ss case ' + IntToStr(LCaseIndex));
    AssertMaskBit0(LOrd, LExpectedOrdBit0[LCaseIndex], 'cmpord_ss case ' + IntToStr(LCaseIndex));
    AssertMaskBit0(LUnord, LExpectedUnordBit0[LCaseIndex], 'cmpunord_ss case ' + IntToStr(LCaseIndex));

    AssertUpperLanesPreserved(LEq, 'cmpeq_ss case ' + IntToStr(LCaseIndex));
    AssertUpperLanesPreserved(LNeq, 'cmpneq_ss case ' + IntToStr(LCaseIndex));
    AssertUpperLanesPreserved(LGt, 'cmpgt_ss case ' + IntToStr(LCaseIndex));
    AssertUpperLanesPreserved(LGe, 'cmpge_ss case ' + IntToStr(LCaseIndex));
    AssertUpperLanesPreserved(LLt, 'cmplt_ss case ' + IntToStr(LCaseIndex));
    AssertUpperLanesPreserved(LLe, 'cmple_ss case ' + IntToStr(LCaseIndex));
    AssertUpperLanesPreserved(LOrd, 'cmpord_ss case ' + IntToStr(LCaseIndex));
    AssertUpperLanesPreserved(LUnord, 'cmpunord_ss case ' + IntToStr(LCaseIndex));

    // Family consistency in ordered space.
    AssertEquals('cmpneq complement case ' + IntToStr(LCaseIndex),
      LEq.m128i_u32[0] xor DWord($FFFFFFFF), LNeq.m128i_u32[0]);
    AssertEquals('cmpge composition case ' + IntToStr(LCaseIndex),
      LGt.m128i_u32[0] or LEq.m128i_u32[0], LGe.m128i_u32[0]);
    AssertEquals('cmple composition case ' + IntToStr(LCaseIndex),
      LLt.m128i_u32[0] or LEq.m128i_u32[0], LLe.m128i_u32[0]);
    AssertEquals('cmpgt/cmplt disjoint case ' + IntToStr(LCaseIndex),
      DWord($00000000), LGt.m128i_u32[0] and LLt.m128i_u32[0]);
    AssertEquals('cmpord true case ' + IntToStr(LCaseIndex), DWord($FFFFFFFF), LOrd.m128i_u32[0]);
    AssertEquals('cmpunord false case ' + IntToStr(LCaseIndex), DWord($00000000), LUnord.m128i_u32[0]);

    for LLaneIndex := 1 to 3 do
      AssertEquals('ordered lane mirror case ' + IntToStr(LCaseIndex) + ' lane ' + IntToStr(LLaneIndex),
        LVecA.m128i_u32[LLaneIndex], LOrd.m128i_u32[LLaneIndex]);
  end;
end;


procedure TTestCase_TM128.Test_compare_ss_family_unordered_matrix;
const
  LUPPER_MASK_FROM_A = 10; // lane1 negative(bit1), lane2 positive(bit2=0), lane3 negative(bit3)
  LCaseCount = 6;
  LCaseA0: array[0..LCaseCount - 1] of DWord = (
    $3F800000, // 1.0 (ordered)
    $7F800000, // +Inf (ordered)
    $7FC0ABCD, // qNaN payload in A (unordered)
    $40000000, // 2.0 with qNaN in B (unordered)
    $7FC01234, // qNaN payload in A (unordered)
    $FFC0DDEE  // -qNaN payload in A (unordered)
  );
  LCaseB0: array[0..LCaseCount - 1] of DWord = (
    $3F800000, // 1.0
    $FF800000, // -Inf
    $3F800000, // 1.0
    $FFC01234, // -qNaN payload
    $7FC0FEED, // qNaN payload
    $7FC00001  // qNaN payload
  );
  LExpectedOrdBit0: array[0..LCaseCount - 1] of Integer = (1, 1, 0, 0, 0, 0);
  LExpectedUnordBit0: array[0..LCaseCount - 1] of Integer = (0, 0, 1, 1, 1, 1);
  LExpectedEqBit0: array[0..LCaseCount - 1] of Integer = (1, 0, 0, 0, 0, 0);
  LExpectedNeqBit0: array[0..LCaseCount - 1] of Integer = (0, 1, 1, 1, 1, 1);
var
  LVecA, LVecB: TM128;
  LOrd, LUnord, LEq, LNeq: TM128;
  LCaseIndex: Integer;

  procedure AssertUpperLanesPreserved(const aResult: TM128; const aTag: string);
  begin
    AssertEquals(aTag + ' preserve lane1', LVecA.m128i_u32[1], aResult.m128i_u32[1]);
    AssertEquals(aTag + ' preserve lane2', LVecA.m128i_u32[2], aResult.m128i_u32[2]);
    AssertEquals(aTag + ' preserve lane3', LVecA.m128i_u32[3], aResult.m128i_u32[3]);
  end;

  procedure AssertMaskBit0(const aResult: TM128; const aExpectedBit0: Integer; const aTag: string);
  var
    LMask: Integer;
  begin
    LMask := sse_movemask_ps(aResult);
    AssertEquals(aTag + ' movemask bit0 mapping', LUPPER_MASK_FROM_A or aExpectedBit0, LMask);
  end;
begin
  // Upper lanes use opposite signs between A/B to detect wrong source lane.
  LVecA.m128i_u32[1] := DWord($BF800000); // -1.0
  LVecA.m128i_u32[2] := DWord($3F800000); // +1.0
  LVecA.m128i_u32[3] := DWord($FF800000); // -Inf

  LVecB.m128i_u32[1] := DWord($3F800000); // +1.0
  LVecB.m128i_u32[2] := DWord($BF800000); // -1.0
  LVecB.m128i_u32[3] := DWord($7F800000); // +Inf

  for LCaseIndex := 0 to LCaseCount - 1 do
  begin
    LVecA.m128i_u32[0] := LCaseA0[LCaseIndex];
    LVecB.m128i_u32[0] := LCaseB0[LCaseIndex];

    LOrd := sse_cmpord_ss(LVecA, LVecB);
    LUnord := sse_cmpunord_ss(LVecA, LVecB);
    LEq := sse_cmpeq_ss(LVecA, LVecB);
    LNeq := sse_cmpneq_ss(LVecA, LVecB);

    AssertMaskBit0(LOrd, LExpectedOrdBit0[LCaseIndex], 'cmpord_ss case ' + IntToStr(LCaseIndex));
    AssertMaskBit0(LUnord, LExpectedUnordBit0[LCaseIndex], 'cmpunord_ss case ' + IntToStr(LCaseIndex));
    AssertMaskBit0(LEq, LExpectedEqBit0[LCaseIndex], 'cmpeq_ss case ' + IntToStr(LCaseIndex));
    AssertMaskBit0(LNeq, LExpectedNeqBit0[LCaseIndex], 'cmpneq_ss case ' + IntToStr(LCaseIndex));

    AssertUpperLanesPreserved(LOrd, 'cmpord_ss case ' + IntToStr(LCaseIndex));
    AssertUpperLanesPreserved(LUnord, 'cmpunord_ss case ' + IntToStr(LCaseIndex));
    AssertUpperLanesPreserved(LEq, 'cmpeq_ss case ' + IntToStr(LCaseIndex));
    AssertUpperLanesPreserved(LNeq, 'cmpneq_ss case ' + IntToStr(LCaseIndex));

    // Unordered specialization and complements.
    AssertEquals('ord/unord complement case ' + IntToStr(LCaseIndex),
      LOrd.m128i_u32[0] xor DWord($FFFFFFFF), LUnord.m128i_u32[0]);
    AssertEquals('eq/neq complement case ' + IntToStr(LCaseIndex),
      LEq.m128i_u32[0] xor DWord($FFFFFFFF), LNeq.m128i_u32[0]);

    if LExpectedUnordBit0[LCaseIndex] = 1 then
      AssertEquals('unordered implies neq true case ' + IntToStr(LCaseIndex), DWord($FFFFFFFF), LNeq.m128i_u32[0]);
  end;
end;


procedure TTestCase_TM128.Test_compare_ps_ord_unord_movemask_complement_matrix;
const
  LVecPatternsA: array[0..3, 0..3] of DWord = (
    ($3F800000, $40000000, $40400000, $7F800000),
    ($7FC01234, $3F800000, $40000000, $7F800000),
    ($3F800000, $7FC0ABCD, $40400000, $FF800000),
    ($7FC01234, $FFC0ABCD, $3F800000, $FF800000)
  );
  LVecPatternsB: array[0..3, 0..3] of DWord = (
    ($40A00000, $40C00000, $40E00000, $FF800000),
    ($40400000, $BF800000, $FFC05678, $FF800000),
    ($40000000, $3F800000, $BF800000, $7FC0FEED),
    ($7FC00001, $40000000, $7FC0BEEF, $FFC01234)
  );
  LExpectedOrdMask: array[0..3] of Integer = (15, 10, 5, 0);
  LExpectedUnordMask: array[0..3] of Integer = (0, 5, 10, 15);
var
  LVecA, LVecB: TM128;
  LOrd, LUnord: TM128;
  LOrdMask, LUnordMask: Integer;
  LCaseIndex, LLaneIndex: Integer;
begin
  for LCaseIndex := 0 to High(LExpectedOrdMask) do
  begin
    for LLaneIndex := 0 to 3 do
    begin
      LVecA.m128i_u32[LLaneIndex] := LVecPatternsA[LCaseIndex, LLaneIndex];
      LVecB.m128i_u32[LLaneIndex] := LVecPatternsB[LCaseIndex, LLaneIndex];
    end;

    LOrd := sse_cmpord_ps(LVecA, LVecB);
    LUnord := sse_cmpunord_ps(LVecA, LVecB);

    LOrdMask := sse_movemask_ps(LOrd);
    LUnordMask := sse_movemask_ps(LUnord);

    AssertEquals('cmpord_ps mask case ' + IntToStr(LCaseIndex), LExpectedOrdMask[LCaseIndex], LOrdMask);
    AssertEquals('cmpunord_ps mask case ' + IntToStr(LCaseIndex), LExpectedUnordMask[LCaseIndex], LUnordMask);

    AssertEquals('ord/unord partition OR case ' + IntToStr(LCaseIndex), 15, LOrdMask or LUnordMask);
    AssertEquals('ord/unord partition AND case ' + IntToStr(LCaseIndex), 0, LOrdMask and LUnordMask);
  end;
end;


procedure TTestCase_TM128.Test_compare_ps_family_consistency_ordered_matrix;
const
  LVecPatternsA: array[0..3, 0..3] of DWord = (
    ($3F800000, $40000000, $40400000, $40800000),
    ($3F800000, $40000000, $40400000, $40800000),
    ($80000000, $7F800000, $FF800000, $40A00000),
    ($7F800000, $FF800000, $00000000, $C0400000)
  );
  LVecPatternsB: array[0..3, 0..3] of DWord = (
    ($3F800000, $40000000, $40400000, $40800000),
    ($40000000, $40000000, $3F800000, $40A00000),
    ($00000000, $FF800000, $7F800000, $C1200000),
    ($7F800000, $FF800000, $80000000, $40E00000)
  );
  LExpectedEqMask: array[0..3] of Integer = (15, 2, 1, 7);
  LExpectedGtMask: array[0..3] of Integer = (0, 4, 10, 0);
  LExpectedLtMask: array[0..3] of Integer = (0, 9, 4, 8);
  LExpectedGeMask: array[0..3] of Integer = (15, 6, 11, 7);
  LExpectedLeMask: array[0..3] of Integer = (15, 11, 5, 15);
  LExpectedNeqMask: array[0..3] of Integer = (0, 13, 14, 8);
var
  LVecA, LVecB: TM128;
  LEq, LNeq, LGt, LGe, LLt, LLe, LOrd, LUnord: TM128;
  LEqMask, LNeqMask, LGtMask, LGeMask, LLtMask, LLeMask, LOrdMask, LUnordMask: Integer;
  LCaseIndex, LLaneIndex: Integer;
begin
  for LCaseIndex := 0 to High(LExpectedEqMask) do
  begin
    for LLaneIndex := 0 to 3 do
    begin
      LVecA.m128i_u32[LLaneIndex] := LVecPatternsA[LCaseIndex, LLaneIndex];
      LVecB.m128i_u32[LLaneIndex] := LVecPatternsB[LCaseIndex, LLaneIndex];
    end;

    LEq := sse_cmpeq_ps(LVecA, LVecB);
    LNeq := sse_cmpneq_ps(LVecA, LVecB);
    LGt := sse_cmpgt_ps(LVecA, LVecB);
    LGe := sse_cmpge_ps(LVecA, LVecB);
    LLt := sse_cmplt_ps(LVecA, LVecB);
    LLe := sse_cmple_ps(LVecA, LVecB);
    LOrd := sse_cmpord_ps(LVecA, LVecB);
    LUnord := sse_cmpunord_ps(LVecA, LVecB);

    LEqMask := sse_movemask_ps(LEq);
    LNeqMask := sse_movemask_ps(LNeq);
    LGtMask := sse_movemask_ps(LGt);
    LGeMask := sse_movemask_ps(LGe);
    LLtMask := sse_movemask_ps(LLt);
    LLeMask := sse_movemask_ps(LLe);
    LOrdMask := sse_movemask_ps(LOrd);
    LUnordMask := sse_movemask_ps(LUnord);

    AssertEquals('cmpeq_ps mask case ' + IntToStr(LCaseIndex), LExpectedEqMask[LCaseIndex], LEqMask);
    AssertEquals('cmpneq_ps mask case ' + IntToStr(LCaseIndex), LExpectedNeqMask[LCaseIndex], LNeqMask);
    AssertEquals('cmpgt_ps mask case ' + IntToStr(LCaseIndex), LExpectedGtMask[LCaseIndex], LGtMask);
    AssertEquals('cmpge_ps mask case ' + IntToStr(LCaseIndex), LExpectedGeMask[LCaseIndex], LGeMask);
    AssertEquals('cmplt_ps mask case ' + IntToStr(LCaseIndex), LExpectedLtMask[LCaseIndex], LLtMask);
    AssertEquals('cmple_ps mask case ' + IntToStr(LCaseIndex), LExpectedLeMask[LCaseIndex], LLeMask);

    // Family consistency in ordered space.
    AssertEquals('eq/neq complement case ' + IntToStr(LCaseIndex), LEqMask xor 15, LNeqMask);
    AssertEquals('ge composition case ' + IntToStr(LCaseIndex), LGtMask or LEqMask, LGeMask);
    AssertEquals('le composition case ' + IntToStr(LCaseIndex), LLtMask or LEqMask, LLeMask);
    AssertEquals('gt/lt disjoint case ' + IntToStr(LCaseIndex), 0, LGtMask and LLtMask);
    AssertEquals('ord mask case ' + IntToStr(LCaseIndex), 15, LOrdMask);
    AssertEquals('unord mask case ' + IntToStr(LCaseIndex), 0, LUnordMask);
  end;
end;


procedure TTestCase_TM128.Test_compare_ps_movemask_stability_smoke_matrix;
const
  LCASE_COUNT = 8;
  LVecPatternsA: array[0..LCASE_COUNT - 1, 0..3] of DWord = (
    ($3F800000, $40000000, $40400000, $40800000),
    ($3F800000, $40000000, $40400000, $40800000),
    ($80000000, $00000000, $BF800000, $3F800000),
    ($7F800000, $FF800000, $41200000, $C1200000),
    ($7F800000, $42C80000, $FF800000, $C2C80000),
    ($42280000, $C2280000, $00000000, $40E00000),
    ($00000001, $80000001, $7F7FFFFF, $FF7FFFFF),
    ($3F000000, $41000000, $C0800000, $3DCCCCCD)
  );
  LVecPatternsB: array[0..LCASE_COUNT - 1, 0..3] of DWord = (
    ($3F800000, $40000000, $40400000, $40800000),
    ($00000000, $40000000, $40800000, $40800000),
    ($00000000, $80000000, $C0000000, $40000000),
    ($7F800000, $FF800000, $C1200000, $41200000),
    ($3F800000, $42C80000, $FF800000, $C3480000),
    ($41A80000, $C2A80000, $3F800000, $40E00000),
    ($00000000, $80000000, $7F7FFFFF, $FF7FFFFF),
    ($3F800000, $40800000, $C1000000, $3E4CCCCD)
  );
var
  LVecA, LVecB: TM128;
  LEq, LNeq, LGt, LGe, LLt, LLe, LOrd, LUnord: TM128;
  LEqMask, LNeqMask, LGtMask, LGeMask, LLtMask, LLeMask, LOrdMask, LUnordMask: Integer;
  LExpectedEqMask, LExpectedNeqMask, LExpectedGtMask, LExpectedGeMask: Integer;
  LExpectedLtMask, LExpectedLeMask, LExpectedOrdMask, LExpectedUnordMask: Integer;
  LCaseIndex, LLaneIndex: Integer;

  function LaneBit(const aCond: Boolean; const aLane: Integer): Integer;
  begin
    if aCond then
      Result := 1 shl aLane
    else
      Result := 0;
  end;
begin
  for LCaseIndex := 0 to LCASE_COUNT - 1 do
  begin
    for LLaneIndex := 0 to 3 do
    begin
      LVecA.m128i_u32[LLaneIndex] := LVecPatternsA[LCaseIndex, LLaneIndex];
      LVecB.m128i_u32[LLaneIndex] := LVecPatternsB[LCaseIndex, LLaneIndex];
    end;

    LEq := sse_cmpeq_ps(LVecA, LVecB);
    LNeq := sse_cmpneq_ps(LVecA, LVecB);
    LGt := sse_cmpgt_ps(LVecA, LVecB);
    LGe := sse_cmpge_ps(LVecA, LVecB);
    LLt := sse_cmplt_ps(LVecA, LVecB);
    LLe := sse_cmple_ps(LVecA, LVecB);
    LOrd := sse_cmpord_ps(LVecA, LVecB);
    LUnord := sse_cmpunord_ps(LVecA, LVecB);

    LEqMask := sse_movemask_ps(LEq);
    LNeqMask := sse_movemask_ps(LNeq);
    LGtMask := sse_movemask_ps(LGt);
    LGeMask := sse_movemask_ps(LGe);
    LLtMask := sse_movemask_ps(LLt);
    LLeMask := sse_movemask_ps(LLe);
    LOrdMask := sse_movemask_ps(LOrd);
    LUnordMask := sse_movemask_ps(LUnord);

    LExpectedEqMask := 0;
    LExpectedNeqMask := 0;
    LExpectedGtMask := 0;
    LExpectedGeMask := 0;
    LExpectedLtMask := 0;
    LExpectedLeMask := 0;
    LExpectedOrdMask := 0;
    LExpectedUnordMask := 0;

    for LLaneIndex := 0 to 3 do
    begin
      LExpectedEqMask := LExpectedEqMask or LaneBit(LVecA.m128_f32[LLaneIndex] = LVecB.m128_f32[LLaneIndex], LLaneIndex);
      LExpectedNeqMask := LExpectedNeqMask or LaneBit(LVecA.m128_f32[LLaneIndex] <> LVecB.m128_f32[LLaneIndex], LLaneIndex);
      LExpectedGtMask := LExpectedGtMask or LaneBit(LVecA.m128_f32[LLaneIndex] > LVecB.m128_f32[LLaneIndex], LLaneIndex);
      LExpectedGeMask := LExpectedGeMask or LaneBit(LVecA.m128_f32[LLaneIndex] >= LVecB.m128_f32[LLaneIndex], LLaneIndex);
      LExpectedLtMask := LExpectedLtMask or LaneBit(LVecA.m128_f32[LLaneIndex] < LVecB.m128_f32[LLaneIndex], LLaneIndex);
      LExpectedLeMask := LExpectedLeMask or LaneBit(LVecA.m128_f32[LLaneIndex] <= LVecB.m128_f32[LLaneIndex], LLaneIndex);
      LExpectedOrdMask := LExpectedOrdMask or LaneBit(not IsNan(LVecA.m128_f32[LLaneIndex]) and not IsNan(LVecB.m128_f32[LLaneIndex]), LLaneIndex);
      LExpectedUnordMask := LExpectedUnordMask or LaneBit(IsNan(LVecA.m128_f32[LLaneIndex]) or IsNan(LVecB.m128_f32[LLaneIndex]), LLaneIndex);
    end;

    AssertEquals('cmpeq_ps smoke mask case ' + IntToStr(LCaseIndex), LExpectedEqMask, LEqMask);
    AssertEquals('cmpneq_ps smoke mask case ' + IntToStr(LCaseIndex), LExpectedNeqMask, LNeqMask);
    AssertEquals('cmpgt_ps smoke mask case ' + IntToStr(LCaseIndex), LExpectedGtMask, LGtMask);
    AssertEquals('cmpge_ps smoke mask case ' + IntToStr(LCaseIndex), LExpectedGeMask, LGeMask);
    AssertEquals('cmplt_ps smoke mask case ' + IntToStr(LCaseIndex), LExpectedLtMask, LLtMask);
    AssertEquals('cmple_ps smoke mask case ' + IntToStr(LCaseIndex), LExpectedLeMask, LLeMask);
    AssertEquals('cmpord_ps smoke mask case ' + IntToStr(LCaseIndex), LExpectedOrdMask, LOrdMask);
    AssertEquals('cmpunord_ps smoke mask case ' + IntToStr(LCaseIndex), LExpectedUnordMask, LUnordMask);

    AssertEquals('smoke eq/neq complement case ' + IntToStr(LCaseIndex), LEqMask xor 15, LNeqMask);
    AssertEquals('smoke ge composition case ' + IntToStr(LCaseIndex), LGtMask or LEqMask, LGeMask);
    AssertEquals('smoke le composition case ' + IntToStr(LCaseIndex), LLtMask or LEqMask, LLeMask);
    AssertEquals('smoke gt/lt disjoint case ' + IntToStr(LCaseIndex), 0, LGtMask and LLtMask);
    AssertEquals('smoke ord/unord partition OR case ' + IntToStr(LCaseIndex), 15, LOrdMask or LUnordMask);
    AssertEquals('smoke ord/unord partition AND case ' + IntToStr(LCaseIndex), 0, LOrdMask and LUnordMask);
  end;
end;

// === 7️⃣ Shuffle / Unpack 测试 ===

procedure TTestCase_TM128.Test_sse_shuffle_ps;
var
  LVecA, LVecB, LResult: TM128;
begin
  LVecA := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  LVecB := sse_set_ps(8.0, 7.0, 6.0, 5.0);

  LResult := sse_shuffle_ps(LVecA, LVecB, $E4);  // 11 10 01 00
  AssertTM128SingleArray([1.0, 2.0, 7.0, 8.0], LResult, 'shuffle_ps e4');

  LResult := sse_shuffle_ps(LVecA, LVecB, $1B);  // 00 01 10 11
  AssertTM128SingleArray([4.0, 3.0, 6.0, 5.0], LResult, 'shuffle_ps 1b');

  LResult := sse_shuffle_ps(LVecA, LVecB, $00);
  AssertTM128SingleArray([1.0, 1.0, 5.0, 5.0], LResult, 'shuffle_ps 00');

  LResult := sse_shuffle_ps(LVecA, LVecB, $FF);
  AssertTM128SingleArray([4.0, 4.0, 8.0, 8.0], LResult, 'shuffle_ps ff');
end;


procedure TTestCase_TM128.Test_shuffle_ps_imm8_selection_matrix;
const
  LIMM8_VALUES: array[0..7] of Byte = ($39, $4E, $93, $C6, $2D, $B4, $7A, $81);
var
  LVecA, LVecB, LResult: TM128;
  LExpected: array[0..3] of Single;
  LIndex: Integer;
  LImm8: Byte;
begin
  LVecA := sse_set_ps(40.0, 30.0, 20.0, 10.0);
  LVecB := sse_set_ps(80.0, 70.0, 60.0, 50.0);

  for LIndex := 0 to High(LIMM8_VALUES) do
  begin
    LImm8 := LIMM8_VALUES[LIndex];
    LResult := sse_shuffle_ps(LVecA, LVecB, LImm8);

    LExpected[0] := LVecA.m128_f32[LImm8 and $03];
    LExpected[1] := LVecA.m128_f32[(LImm8 shr 2) and $03];
    LExpected[2] := LVecB.m128_f32[(LImm8 shr 4) and $03];
    LExpected[3] := LVecB.m128_f32[(LImm8 shr 6) and $03];

    AssertTM128SingleArray(
      [LExpected[0], LExpected[1], LExpected[2], LExpected[3]],
      LResult,
      'shuffle_ps matrix imm8=' + IntToHex(LImm8, 2)
    );
  end;
end;


procedure TTestCase_TM128.Test_shuffle_ps_imm8_exhaustive_smoke;
var
  LVecA, LVecB, LResult: TM128;
  LExpected: array[0..3] of Single;
  LImm8: Integer;
begin
  LVecA := sse_set_ps(1040.0, 1030.0, 1020.0, 1010.0);
  LVecB := sse_set_ps(2040.0, 2030.0, 2020.0, 2010.0);

  for LImm8 := 0 to 255 do
  begin
    LResult := sse_shuffle_ps(LVecA, LVecB, Byte(LImm8));

    LExpected[0] := LVecA.m128_f32[LImm8 and $03];
    LExpected[1] := LVecA.m128_f32[(LImm8 shr 2) and $03];
    LExpected[2] := LVecB.m128_f32[(LImm8 shr 4) and $03];
    LExpected[3] := LVecB.m128_f32[(LImm8 shr 6) and $03];

    AssertTM128SingleArray(
      [LExpected[0], LExpected[1], LExpected[2], LExpected[3]],
      LResult,
      'shuffle_ps exhaustive imm8=' + IntToHex(LImm8, 2)
    );
  end;
end;

procedure TTestCase_TM128.Test_sse_unpackhi_ps;
var
  LVecA, LVecB, LResult: TM128;
begin
  LVecA := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  LVecB := sse_set_ps(8.0, 7.0, 6.0, 5.0);
  LResult := sse_unpackhi_ps(LVecA, LVecB);
  AssertTM128SingleArray([3.0, 7.0, 4.0, 8.0], LResult, 'unpackhi_ps');
end;

procedure TTestCase_TM128.Test_sse_unpacklo_ps;
var
  LVecA, LVecB, LResult: TM128;
begin
  LVecA := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  LVecB := sse_set_ps(8.0, 7.0, 6.0, 5.0);
  LResult := sse_unpacklo_ps(LVecA, LVecB);
  AssertTM128SingleArray([1.0, 5.0, 2.0, 6.0], LResult, 'unpacklo_ps');
end;

procedure TTestCase_TM128.Test_sse_unpckhps;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(8.0, 7.0, 6.0, 5.0);
  result := sse_unpckhps(a, b);
  AssertTM128SingleArray([3.0, 7.0, 4.0, 8.0], result, 'unpckhps');
end;

procedure TTestCase_TM128.Test_sse_unpcklps;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(8.0, 7.0, 6.0, 5.0);
  result := sse_unpcklps(a, b);
  AssertTM128SingleArray([1.0, 5.0, 2.0, 6.0], result, 'unpcklps');
end;

// === 10️⃣ Data Movement 测试 ===

procedure TTestCase_TM128.Test_sse_movaps;
var
  a, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  result := sse_movaps(a);
  AssertTM128SingleArray([1.0, 2.0, 3.0, 4.0], result, 'movaps');
end;

procedure TTestCase_TM128.Test_sse_movups;
var
  a, result: TM128;
begin
  a := sse_set_ps(8.0, 7.0, 6.0, 5.0);
  result := sse_movups(a);
  AssertTM128SingleArray([5.0, 6.0, 7.0, 8.0], result, 'movups');
end;

procedure TTestCase_TM128.Test_movaps_movups_consistency;
var
  LInput: TM128;
  LMovAps: TM128;
  LMovUps: TM128;
begin
  LInput := sse_set_ps(11.0, -2.0, 0.5, -99.25);
  LMovAps := sse_movaps(LInput);
  LMovUps := sse_movups(LInput);

  AssertTM128SingleArray([-99.25, 0.5, -2.0, 11.0], LMovAps, 'movaps consistency aps');
  AssertTM128SingleArray([-99.25, 0.5, -2.0, 11.0], LMovUps, 'movaps consistency ups');
end;

procedure TTestCase_TM128.Test_movaps_unaligned_tm128;
type
  TPackedM128 = packed record
    LPad: Byte;
    LValue: TM128;
  end;
var
  LPacked: TPackedM128;
  LResult: TM128;
begin
  FillChar(LPacked, SizeOf(LPacked), 0);
  LPacked.LValue := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  LResult := sse_movaps(LPacked.LValue);
  AssertTM128SingleArray([1.0, 2.0, 3.0, 4.0], LResult, 'movaps unaligned tm128');
end;


procedure TTestCase_TM128.Test_movaps_movups_bitpattern_stability;
var
  LInput, LMovAps, LMovUps: TM128;
  LIndex: Integer;
begin
  // 混合特殊位型：-0.0 / qNaN(payload) / 1.0 / -Inf
  LInput.m128i_u32[0] := DWord($80000000);
  LInput.m128i_u32[1] := DWord($7FC01234);
  LInput.m128i_u32[2] := DWord($3F800000);
  LInput.m128i_u32[3] := DWord($FF800000);

  LMovAps := sse_movaps(LInput);
  LMovUps := sse_movups(LInput);

  for LIndex := 0 to 3 do
  begin
    AssertEquals(
      'movaps bitpattern lane ' + IntToStr(LIndex),
      LInput.m128i_u32[LIndex],
      LMovAps.m128i_u32[LIndex]
    );
    AssertEquals(
      'movups bitpattern lane ' + IntToStr(LIndex),
      LInput.m128i_u32[LIndex],
      LMovUps.m128i_u32[LIndex]
    );
  end;
end;

procedure TTestCase_TM128.Test_sse_movss;
var
  a, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  result := sse_movss(a);
  AssertTM128SingleArray([1.0, 0.0, 0.0, 0.0], result, 'movss');
end;

procedure TTestCase_TM128.Test_sse_move_ss;
var
  LVecA, LVecB, LResult: TM128;
begin
  LVecA := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  LVecB := sse_set_ps(8.0, 7.0, 6.0, 5.0);
  LResult := sse_move_ss(LVecA, LVecB);
  AssertTM128SingleArray([5.0, 2.0, 3.0, 4.0], LResult, 'move_ss');
end;


procedure TTestCase_TM128.Test_movss_move_ss_special_bitpatterns;
var
  LVecA, LVecB, LMovSs, LMoveSs: TM128;
begin
  // A: -0.0 / qNaN(payload) / +1.0 / -Inf
  LVecA.m128i_u32[0] := DWord($80000000);
  LVecA.m128i_u32[1] := DWord($7FC01234);
  LVecA.m128i_u32[2] := DWord($3F800000);
  LVecA.m128i_u32[3] := DWord($FF800000);

  // B: -qNaN(payload) / denorm / +Inf / +2.0
  LVecB.m128i_u32[0] := DWord($FFC05678);
  LVecB.m128i_u32[1] := DWord($00000001);
  LVecB.m128i_u32[2] := DWord($7F800000);
  LVecB.m128i_u32[3] := DWord($40000000);

  LMovSs := sse_movss(LVecA);
  AssertEquals('movss bit lane0 keeps src low', LVecA.m128i_u32[0], LMovSs.m128i_u32[0]);
  AssertEquals('movss bit lane1 zeroed', DWord(0), LMovSs.m128i_u32[1]);
  AssertEquals('movss bit lane2 zeroed', DWord(0), LMovSs.m128i_u32[2]);
  AssertEquals('movss bit lane3 zeroed', DWord(0), LMovSs.m128i_u32[3]);

  LMoveSs := sse_move_ss(LVecA, LVecB);
  AssertEquals('move_ss bit lane0 from b', LVecB.m128i_u32[0], LMoveSs.m128i_u32[0]);
  AssertEquals('move_ss bit lane1 keeps a', LVecA.m128i_u32[1], LMoveSs.m128i_u32[1]);
  AssertEquals('move_ss bit lane2 keeps a', LVecA.m128i_u32[2], LMoveSs.m128i_u32[2]);
  AssertEquals('move_ss bit lane3 keeps a', LVecA.m128i_u32[3], LMoveSs.m128i_u32[3]);
end;


procedure TTestCase_TM128.Test_movehl_movlh_bitpattern_semantics;
var
  LVecA, LVecB: TM128;
  LMoveHl, LMovHl, LMoveLh, LMovLh: TM128;
begin
  LVecA.m128i_u32[0] := DWord($80000000); // -0.0
  LVecA.m128i_u32[1] := DWord($3F800000); // 1.0
  LVecA.m128i_u32[2] := DWord($7FC01234); // qNaN payload
  LVecA.m128i_u32[3] := DWord($FF800000); // -Inf

  LVecB.m128i_u32[0] := DWord($00000001); // denorm
  LVecB.m128i_u32[1] := DWord($40000000); // 2.0
  LVecB.m128i_u32[2] := DWord($FFC05678); // -qNaN payload
  LVecB.m128i_u32[3] := DWord($7F800000); // +Inf

  LMoveHl := sse_movehl_ps(LVecA, LVecB);
  AssertEquals('movehl lane0=b2', LVecB.m128i_u32[2], LMoveHl.m128i_u32[0]);
  AssertEquals('movehl lane1=b3', LVecB.m128i_u32[3], LMoveHl.m128i_u32[1]);
  AssertEquals('movehl lane2=a2', LVecA.m128i_u32[2], LMoveHl.m128i_u32[2]);
  AssertEquals('movehl lane3=a3', LVecA.m128i_u32[3], LMoveHl.m128i_u32[3]);

  LMovHl := sse_movhl_ps(LVecA, LVecB);
  AssertEquals('movhl alias lane0', LMoveHl.m128i_u32[0], LMovHl.m128i_u32[0]);
  AssertEquals('movhl alias lane1', LMoveHl.m128i_u32[1], LMovHl.m128i_u32[1]);
  AssertEquals('movhl alias lane2', LMoveHl.m128i_u32[2], LMovHl.m128i_u32[2]);
  AssertEquals('movhl alias lane3', LMoveHl.m128i_u32[3], LMovHl.m128i_u32[3]);

  LMoveLh := sse_movelh_ps(LVecA, LVecB);
  AssertEquals('movelh lane0=a0', LVecA.m128i_u32[0], LMoveLh.m128i_u32[0]);
  AssertEquals('movelh lane1=a1', LVecA.m128i_u32[1], LMoveLh.m128i_u32[1]);
  AssertEquals('movelh lane2=b0', LVecB.m128i_u32[0], LMoveLh.m128i_u32[2]);
  AssertEquals('movelh lane3=b1', LVecB.m128i_u32[1], LMoveLh.m128i_u32[3]);

  LMovLh := sse_movlh_ps(LVecA, LVecB);
  AssertEquals('movlh alias lane0', LMoveLh.m128i_u32[0], LMovLh.m128i_u32[0]);
  AssertEquals('movlh alias lane1', LMoveLh.m128i_u32[1], LMovLh.m128i_u32[1]);
  AssertEquals('movlh alias lane2', LMoveLh.m128i_u32[2], LMovLh.m128i_u32[2]);
  AssertEquals('movlh alias lane3', LMoveLh.m128i_u32[3], LMovLh.m128i_u32[3]);
end;

procedure TTestCase_TM128.Test_sse_movhl_ps;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(8.0, 7.0, 6.0, 5.0);
  result := sse_movhl_ps(a, b);
  AssertTM128SingleArray([7.0, 8.0, 3.0, 4.0], result, 'movhl_ps');
end;

procedure TTestCase_TM128.Test_sse_movehl_ps;
var
  LVecA, LVecB, LResult: TM128;
begin
  LVecA := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  LVecB := sse_set_ps(8.0, 7.0, 6.0, 5.0);
  LResult := sse_movehl_ps(LVecA, LVecB);
  AssertTM128SingleArray([7.0, 8.0, 3.0, 4.0], LResult, 'movehl_ps');
end;

procedure TTestCase_TM128.Test_sse_movlh_ps;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(8.0, 7.0, 6.0, 5.0);
  result := sse_movlh_ps(a, b);
  AssertTM128SingleArray([1.0, 2.0, 5.0, 6.0], result, 'movlh_ps');
end;

procedure TTestCase_TM128.Test_sse_movelh_ps;
var
  LVecA, LVecB, LResult: TM128;
begin
  LVecA := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  LVecB := sse_set_ps(8.0, 7.0, 6.0, 5.0);
  LResult := sse_movelh_ps(LVecA, LVecB);
  AssertTM128SingleArray([1.0, 2.0, 5.0, 6.0], LResult, 'movelh_ps');
end;

procedure TTestCase_TM128.Test_sse_movd;
var
  LResult: TM128;
begin
  LResult := sse_movd(12345);
  AssertEquals('movd[0]', 12345, LResult.m128i_i32[0]);
  AssertEquals('movd[1]', 0, LResult.m128i_i32[1]);
  AssertEquals('movd[2]', 0, LResult.m128i_i32[2]);
  AssertEquals('movd[3]', 0, LResult.m128i_i32[3]);

  LResult := sse_movd(-12345);
  AssertEquals('movd negative[0]', -12345, LResult.m128i_i32[0]);
  AssertEquals('movd negative[1]', 0, LResult.m128i_i32[1]);
  AssertEquals('movd negative[2]', 0, LResult.m128i_i32[2]);
  AssertEquals('movd negative[3]', 0, LResult.m128i_i32[3]);
end;

procedure TTestCase_TM128.Test_sse_movd_toint;
var
  LVec: TM128;
  LResult: LongInt;
begin
  LVec.m128i_i32[0] := 54321;
  LVec.m128i_i32[1] := 11111;
  LVec.m128i_i32[2] := 22222;
  LVec.m128i_i32[3] := 33333;
  LResult := sse_movd_toint(LVec);
  AssertEquals('movd_toint positive', 54321, LResult);

  LVec.m128i_i32[0] := -54321;
  LVec.m128i_i32[1] := -1;
  LVec.m128i_i32[2] := -2;
  LVec.m128i_i32[3] := -3;
  LResult := sse_movd_toint(LVec);
  AssertEquals('movd_toint negative', -54321, LResult);

  AssertEquals('movd_toint roundtrip', -12345, sse_movd_toint(sse_movd(-12345)));
end;

procedure TTestCase_TM128.Test_sse_movemask_ps;
var
  LVec: TM128;
  LMask: Integer;
begin
  LVec := sse_set_ps(4.0, -3.0, 2.0, -1.0);
  LMask := sse_movemask_ps(LVec);
  AssertEquals('movemask_ps mixed signs', 5, LMask);

  LVec := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  LMask := sse_movemask_ps(LVec);
  AssertEquals('movemask_ps all positive', 0, LMask);
end;


procedure TTestCase_TM128.Test_movemask_ps_signbit_matrix;
const
  LPatterns: array[0..7, 0..3] of DWord = (
    ($00000000, $3F800000, $40000000, $7F7FFFFF),
    ($80000000, $3F800000, $40000000, $7F7FFFFF),
    ($00000000, $BF800000, $40000000, $7F7FFFFF),
    ($00000000, $3F800000, $C0000000, $7F7FFFFF),
    ($00000000, $3F800000, $40000000, $FF7FFFFF),
    ($80000000, $BF800000, $40000000, $7F7FFFFF),
    ($7FC01234, $FFC05678, $C0000000, $7F800000),
    ($FF800000, $00000001, $FFC00001, $80000000)
  );
  LExpectedMasks: array[0..7] of Integer = (0, 1, 2, 4, 8, 3, 6, 13);
var
  LVec: TM128;
  LCaseIndex: Integer;
  LLaneIndex: Integer;
  LMask: Integer;
begin
  for LCaseIndex := 0 to High(LExpectedMasks) do
  begin
    for LLaneIndex := 0 to 3 do
      LVec.m128i_u32[LLaneIndex] := LPatterns[LCaseIndex, LLaneIndex];

    LMask := sse_movemask_ps(LVec);
    AssertEquals('movemask signbit case ' + IntToStr(LCaseIndex), LExpectedMasks[LCaseIndex], LMask);
  end;
end;


procedure TTestCase_TM128.Test_movemask_ps_signbit_exhaustive_16cases;
const
  LBasePatterns: array[0..3] of DWord = ($3F800000, $40000000, $40400000, $40800000);
var
  LVec: TM128;
  LMask, LExpectedMask: Integer;
  LLaneIndex: Integer;
begin
  for LExpectedMask := 0 to 15 do
  begin
    for LLaneIndex := 0 to 3 do
    begin
      if ((LExpectedMask shr LLaneIndex) and 1) <> 0 then
        LVec.m128i_u32[LLaneIndex] := LBasePatterns[LLaneIndex] or DWord($80000000)
      else
        LVec.m128i_u32[LLaneIndex] := LBasePatterns[LLaneIndex];
    end;

    LMask := sse_movemask_ps(LVec);
    AssertEquals('movemask exhaustive signbits case ' + IntToStr(LExpectedMask), LExpectedMask, LMask);
  end;
end;

procedure TTestCase_TM128.Test_alias_consistency_pairs;
var
  LVecA, LVecB: TM128;
  LBase, LAlias: TM128;
begin
  LVecA := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  LVecB := sse_set_ps(8.0, 7.0, 6.0, 5.0);

  LBase := sse_unpackhi_ps(LVecA, LVecB);
  LAlias := sse_unpckhps(LVecA, LVecB);
  AssertTM128SingleArray([LBase.m128_f32[0], LBase.m128_f32[1], LBase.m128_f32[2], LBase.m128_f32[3]], LAlias, 'alias unpckhps');

  LBase := sse_unpacklo_ps(LVecA, LVecB);
  LAlias := sse_unpcklps(LVecA, LVecB);
  AssertTM128SingleArray([LBase.m128_f32[0], LBase.m128_f32[1], LBase.m128_f32[2], LBase.m128_f32[3]], LAlias, 'alias unpcklps');

  LBase := sse_movehl_ps(LVecA, LVecB);
  LAlias := sse_movhl_ps(LVecA, LVecB);
  AssertTM128SingleArray([LBase.m128_f32[0], LBase.m128_f32[1], LBase.m128_f32[2], LBase.m128_f32[3]], LAlias, 'alias movhl_ps');

  LBase := sse_movelh_ps(LVecA, LVecB);
  LAlias := sse_movlh_ps(LVecA, LVecB);
  AssertTM128SingleArray([LBase.m128_f32[0], LBase.m128_f32[1], LBase.m128_f32[2], LBase.m128_f32[3]], LAlias, 'alias movlh_ps');
end;

// === 11️⃣ Cache Control 测试 ===

procedure TTestCase_TM128.Test_sse_stream_ps;
var
  src: TM128;
  dest: array[0..3] of Single;
begin
  src := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  sse_stream_ps(dest, src);

  AssertSingleEquals(1.0, dest[0], 'stream_ps[0]');
  AssertSingleEquals(2.0, dest[1], 'stream_ps[1]');
  AssertSingleEquals(3.0, dest[2], 'stream_ps[2]');
  AssertSingleEquals(4.0, dest[3], 'stream_ps[3]');
end;

procedure TTestCase_TM128.Test_sse_stream_si64;
var
  src: TM128;
  dest: UInt64;
begin
  src.m128i_u64[0] := UInt64($123456789ABCDEF0);
  src.m128i_u64[1] := UInt64($FEDCBA9876543210);
  sse_stream_si64(dest, src);
  AssertEquals('stream_si64', UInt64($123456789ABCDEF0), dest);
end;

procedure TTestCase_TM128.Test_stream_ps_unaligned_fallback;
type
  TPackedDest = packed record
    LPad: Byte;
    LData: array[0..3] of Single;
  end;
var
  LSrc: TM128;
  LDest: TPackedDest;
begin
  FillChar(LDest, SizeOf(LDest), 0);
  LSrc := sse_set_ps(40.0, 30.0, 20.0, 10.0);
  sse_stream_ps(LDest.LData[0], LSrc);

  AssertSingleEquals(10.0, LDest.LData[0], 'stream_ps unaligned[0]');
  AssertSingleEquals(20.0, LDest.LData[1], 'stream_ps unaligned[1]');
  AssertSingleEquals(30.0, LDest.LData[2], 'stream_ps unaligned[2]');
  AssertSingleEquals(40.0, LDest.LData[3], 'stream_ps unaligned[3]');
end;

procedure TTestCase_TM128.Test_stream_si64_unaligned_fallback;
type
  TPackedU64 = packed record
    LPad: Byte;
    LValue: UInt64;
  end;
var
  LSrc: TM128;
  LDest: TPackedU64;
begin
  FillChar(LDest, SizeOf(LDest), 0);
  LSrc.m128i_u64[0] := UInt64($0123456789ABCDEF);
  LSrc.m128i_u64[1] := UInt64($FEDCBA9876543210);
  sse_stream_si64(LDest.LValue, LSrc);
  AssertEquals('stream_si64 unaligned', UInt64($0123456789ABCDEF), LDest.LValue);
end;

procedure TTestCase_TM128.Test_sse_sfence;
begin
  // 测试 sfence 不会崩溃
  sse_sfence;
  AssertTrue('sfence should not crash', True);
end;

procedure TTestCase_TM128.Test_sse_prefetch;
var
  LData: array[0..15] of Byte;
  LLocality: Integer;
begin
  for LLocality := Low(LData) to High(LData) do
    LData[LLocality] := Byte(LLocality);

  sse_prefetch(nil, 0);
  for LLocality := -1 to 3 do
    sse_prefetch(@LData[0], LLocality);

  AssertTrue('prefetch should not crash', True);
end;

// === 12️⃣ Miscellaneous 测试 ===

procedure TTestCase_TM128.Test_sse_getcsr;
var
  LBefore, LAfter: Integer;
begin
  LBefore := sse_getcsr;
  AssertTrue('getcsr should return non-zero default mask', LBefore <> 0);

  // 与 setcsr 配合验证可写可读
  sse_setcsr($1F80);
  LAfter := sse_getcsr;
  AssertEquals('getcsr/setcsr roundtrip', $1F80, LAfter);
end;

procedure TTestCase_TM128.Test_sse_setcsr;
begin
  // 测试 setcsr 不会崩溃
  sse_setcsr($1F80);
  AssertTrue('setcsr should not crash', True);
end;

procedure TTestCase_TM128.Test_sse_cvtsi2ss;
var
  LBase, LResult: TM128;
begin
  LBase := sse_set_ps(40.0, 30.0, 20.0, 10.0);
  LResult := sse_cvtsi2ss(LBase, 123);
  AssertTM128SingleArray([123.0, 20.0, 30.0, 40.0], LResult, 'cvtsi2ss direct');
end;

procedure TTestCase_TM128.Test_sse_cvtss2si;
var
  LBase: TM128;
begin
  LBase := sse_set_ps(0.0, 0.0, 0.0, 3.75);
  AssertEquals('cvtss2si rounding direct', 4, sse_cvtss2si(LBase));

  LBase := sse_set_ps(0.0, 0.0, 0.0, -3.75);
  AssertEquals('cvtss2si negative rounding direct', -4, sse_cvtss2si(LBase));
end;

procedure TTestCase_TM128.Test_sse_cvttss2si;
var
  LBase: TM128;
begin
  LBase := sse_set_ps(0.0, 0.0, 0.0, 3.75);
  AssertEquals('cvttss2si trunc direct', 3, sse_cvttss2si(LBase));

  LBase := sse_set_ps(0.0, 0.0, 0.0, -3.75);
  AssertEquals('cvttss2si negative trunc direct', -3, sse_cvttss2si(LBase));
end;

procedure TTestCase_TM128.Test_convert_scalar_int_combo;
var
  LBase: TM128;
  LResult: TM128;
begin
  LBase := sse_set_ps(40.0, 30.0, 20.0, 10.0);
  LResult := sse_cvtsi2ss(LBase, 123);
  AssertTM128SingleArray([123.0, 20.0, 30.0, 40.0], LResult, 'cvtsi2ss');

  LBase := sse_set_ps(0.0, 0.0, 0.0, 3.75);
  AssertEquals('cvtss2si rounding', 4, sse_cvtss2si(LBase));
  AssertEquals('cvttss2si truncation', 3, sse_cvttss2si(LBase));

  LBase := sse_set_ps(0.0, 0.0, 0.0, -3.75);
  AssertEquals('cvtss2si negative rounding', -4, sse_cvtss2si(LBase));
  AssertEquals('cvttss2si negative truncation', -3, sse_cvttss2si(LBase));
end;

procedure TTestCase_TM128.Test_convert_rounding_mode_behavior;
var
  LBase: TM128;
  LOldMxcsr: Integer;
begin
{$IF Defined(CPUX86_64) or Defined(CPU386)}
  LOldMxcsr := sse_getcsr;
  try
    // 默认最近偶数舍入
    sse_setcsr($1F80);
    LBase := sse_set_ps(0.0, 0.0, 0.0, 2.5);
    AssertEquals('cvtss2si nearest-even 2.5', 2, sse_cvtss2si(LBase));

    // 向零舍入
    sse_setcsr($7F80);
    LBase := sse_set_ps(0.0, 0.0, 0.0, 3.75);
    AssertEquals('cvtss2si toward-zero positive', 3, sse_cvtss2si(LBase));
    LBase := sse_set_ps(0.0, 0.0, 0.0, -3.75);
    AssertEquals('cvtss2si toward-zero negative', -3, sse_cvtss2si(LBase));
  finally
    sse_setcsr(LOldMxcsr);
  end;
{$ELSE}
  AssertTrue('rounding-mode behavior is x86-specific', True);
{$ENDIF}
end;

initialization
  RegisterTest(TTestCase_TM128);

end.
