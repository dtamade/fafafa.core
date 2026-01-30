unit fafafa.core.simd.intrinsics.sse.testcase;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
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
    procedure Test_sse_store_ps;
    procedure Test_sse_storeu_ps;
    procedure Test_sse_store_ss;
    procedure Test_sse_movq;
    procedure Test_sse_movq_store;
    
    // === 2️⃣ Set / Zero 测试 ===
    procedure Test_sse_setzero_ps;
    procedure Test_sse_set1_ps;
    procedure Test_sse_set_ps;
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
    procedure Test_sse_cmpord_ps;
    procedure Test_sse_cmpord_ss;
    procedure Test_sse_cmpunord_ps;
    procedure Test_sse_cmpunord_ss;
    
    // === 7️⃣ Shuffle / Unpack 测试 ===
    procedure Test_sse_shuffle_ps;
    procedure Test_sse_unpckhps;
    procedure Test_sse_unpcklps;
    
    // === 10️⃣ Data Movement 测试 ===
    procedure Test_sse_movaps;
    procedure Test_sse_movups;
    procedure Test_sse_movss;
    procedure Test_sse_movhl_ps;
    procedure Test_sse_movlh_ps;
    procedure Test_sse_movd;
    procedure Test_sse_movd_toint;
    
    // === 11️⃣ Cache Control 测试 ===
    procedure Test_sse_stream_ps;
    procedure Test_sse_stream_si64;
    procedure Test_sse_sfence;
    
    // === 12️⃣ Miscellaneous 测试 ===
    procedure Test_sse_getcsr;
    procedure Test_sse_setcsr;
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

procedure TTestCase_TM128.Test_sse_cmpord_ps;
var
  a, b, result: TM128;
  nan_val: Single;
begin
  nan_val := 0.0 / 0.0;  // 创建 NaN
  a := sse_set_ps(4.0, nan_val, 2.0, 1.0);
  b := sse_set_ps(3.0, 5.0, nan_val, 3.0);
  result := sse_cmpord_ps(a, b);
  AssertEquals('cmpord_ps[0]', $00000000, result.m128i_u32[0]);
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
  AssertEquals('cmpunord_ps[0]', $FFFFFFFF, result.m128i_u32[0]);
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

// === 7️⃣ Shuffle / Unpack 测试 ===

procedure TTestCase_TM128.Test_sse_shuffle_ps;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(8.0, 7.0, 6.0, 5.0);
  result := sse_shuffle_ps(a, b, $E4);  // 11 10 01 00
  AssertTM128SingleArray([1.0, 2.0, 7.0, 8.0], result, 'shuffle_ps');
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

procedure TTestCase_TM128.Test_sse_movss;
var
  a, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  result := sse_movss(a);
  AssertTM128SingleArray([1.0, 0.0, 0.0, 0.0], result, 'movss');
end;

procedure TTestCase_TM128.Test_sse_movhl_ps;
var
  a, b, result: TM128;
begin
  a := sse_set_ps(4.0, 3.0, 2.0, 1.0);
  b := sse_set_ps(8.0, 7.0, 6.0, 5.0);
  result := sse_movhl_ps(a, b);
  AssertTM128SingleArray([6.0, 7.0, 3.0, 4.0], result, 'movhl_ps');
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

procedure TTestCase_TM128.Test_sse_movd;
var
  result: TM128;
begin
  result := sse_movd(12345);
  AssertEquals('movd[0]', 12345, result.m128i_i32[0]);
  AssertEquals('movd[1]', 0, result.m128i_i32[1]);
  AssertEquals('movd[2]', 0, result.m128i_i32[2]);
  AssertEquals('movd[3]', 0, result.m128i_i32[3]);
end;

procedure TTestCase_TM128.Test_sse_movd_toint;
var
  a: TM128;
  result: LongInt;
begin
  a.m128i_i32[0] := 54321;
  a.m128i_i32[1] := 11111;
  a.m128i_i32[2] := 22222;
  a.m128i_i32[3] := 33333;
  result := sse_movd_toint(a);
  AssertEquals('movd_toint', 54321, result);
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

procedure TTestCase_TM128.Test_sse_sfence;
begin
  // 测试 sfence 不会崩溃
  sse_sfence;
  AssertTrue('sfence should not crash', True);
end;

// === 12️⃣ Miscellaneous 测试 ===

procedure TTestCase_TM128.Test_sse_getcsr;
var
  result: Integer;
begin
  result := sse_getcsr;
  // 在模拟实现中，应该返回 0
  AssertEquals('getcsr', 0, result);
end;

procedure TTestCase_TM128.Test_sse_setcsr;
begin
  // 测试 setcsr 不会崩溃
  sse_setcsr($1F80);
  AssertTrue('setcsr should not crash', True);
end;

initialization
  RegisterTest(TTestCase_TM128);

end.
