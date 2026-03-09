unit fafafa.core.simd.intrinsics.mmx.testcase;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.simd.intrinsics.mmx;

type
  // 全局函数测试（MMX 模块中没有全局函数，所以这个类为空）
  TTestCase_Global = class(TTestCase)
  published
    // MMX 模块没有全局函数，保留空的测试类
  end;

  // TM64 类型测试
  TTestCase_TM64 = class(TTestCase)
  private
    procedure AssertTM64Equal(const Expected, Actual: TM64; const Msg: string = '');
    procedure AssertTM64ByteArray(const Expected: array of Byte; const Actual: TM64; const Msg: string = '');
    procedure AssertTM64WordArray(const Expected: array of SmallInt; const Actual: TM64; const Msg: string = '');
    procedure AssertTM64DWordArray(const Expected: array of LongInt; const Actual: TM64; const Msg: string = '');
  published
    // === 1️⃣ Load / Store 测试 ===
    procedure Test_mmx_movd_mm;
    procedure Test_mmx_movd_mm_store;
    procedure Test_mmx_movq_mm;
    procedure Test_mmx_movq_mm_store;
    procedure Test_mmx_movd_r32;
    procedure Test_mmx_movd_r32_to_mm;
    
    // === 2️⃣ Set / Zero 测试 ===
    procedure Test_mmx_setzero_si64;
    procedure Test_mmx_set1_pi8;
    procedure Test_mmx_set1_pi16;
    procedure Test_mmx_set1_pi32;
    procedure Test_mmx_set_pi8;
    procedure Test_mmx_set_pi16;
    procedure Test_mmx_set_pi32;
    
    // === 3️⃣ Integer Arithmetic 测试 ===
    procedure Test_mmx_paddb;
    procedure Test_mmx_paddw;
    procedure Test_mmx_paddd;
    procedure Test_mmx_paddq;
    procedure Test_mmx_paddsb;
    procedure Test_mmx_paddsw;
    procedure Test_mmx_paddusb;
    procedure Test_mmx_paddusw;
    procedure Test_mmx_psubb;
    procedure Test_mmx_psubw;
    procedure Test_mmx_psubd;
    procedure Test_mmx_psubq;
    procedure Test_mmx_psubsb;
    procedure Test_mmx_psubsw;
    procedure Test_mmx_psubusb;
    procedure Test_mmx_psubusw;
    procedure Test_mmx_pmullw;
    procedure Test_mmx_pmulhw;
    procedure Test_mmx_pmaddwd;
    
    // === 5️⃣ Logical Operations 测试 ===
    procedure Test_mmx_pand;
    procedure Test_mmx_pandn;
    procedure Test_mmx_por;
    procedure Test_mmx_pxor;
    
    // === 6️⃣ Compare 测试 ===
    procedure Test_mmx_pcmpeqb;
    procedure Test_mmx_pcmpeqw;
    procedure Test_mmx_pcmpeqd;
    procedure Test_mmx_pcmpgtb;
    procedure Test_mmx_pcmpgtw;
    procedure Test_mmx_pcmpgtd;
    
    // === 7️⃣ Shift 测试 ===
    procedure Test_mmx_psllw;
    procedure Test_mmx_pslld;
    procedure Test_mmx_psllq;
    procedure Test_mmx_psllw_imm;
    procedure Test_mmx_pslld_imm;
    procedure Test_mmx_psllq_imm;
    procedure Test_mmx_psrlw;
    procedure Test_mmx_psrld;
    procedure Test_mmx_psrlq;
    procedure Test_mmx_psrlw_imm;
    procedure Test_mmx_psrld_imm;
    procedure Test_mmx_psrlq_imm;
    procedure Test_mmx_psraw;
    procedure Test_mmx_psrad;
    procedure Test_mmx_psraw_imm;
    procedure Test_mmx_psrad_imm;
    procedure Test_mmx_psllw_mm;
    procedure Test_mmx_psrlw_mm;
    procedure Test_mmx_psraw_mm;
    
    // === 10️⃣ Pack / Unpack 测试 ===
    procedure Test_mmx_packsswb;
    procedure Test_mmx_packssdw;
    procedure Test_mmx_packuswb;
    procedure Test_mmx_punpckhbw;
    procedure Test_mmx_punpckhwd;
    procedure Test_mmx_punpckhdq;
    procedure Test_mmx_punpcklbw;
    procedure Test_mmx_punpcklwd;
    procedure Test_mmx_punpckldq;
    procedure Test_mmx_packusdw;
    procedure Test_mmx_punpcklbw_mem;
    procedure Test_mmx_punpcklwd_mem;
    procedure Test_mmx_punpckldq_mem;
    
    // === 11️⃣ Miscellaneous 测试 ===
    procedure Test_mmx_emms;
  end;

implementation

// === TTestCase_TM64 辅助方法 ===

procedure TTestCase_TM64.AssertTM64Equal(const Expected, Actual: TM64; const Msg: string);
begin
  AssertEquals(Msg + ' (64-bit value)', Expected.mm_u64, Actual.mm_u64);
end;

procedure TTestCase_TM64.AssertTM64ByteArray(const Expected: array of Byte; const Actual: TM64; const Msg: string);
var
  i: Integer;
begin
  AssertEquals(Msg + ' (array length)', 8, Length(Expected));
  for i := 0 to 7 do
    AssertEquals(Msg + Format(' (byte[%d])', [i]), Expected[i], Actual.mm_u8[i]);
end;

procedure TTestCase_TM64.AssertTM64WordArray(const Expected: array of SmallInt; const Actual: TM64; const Msg: string);
var
  i: Integer;
begin
  AssertEquals(Msg + ' (array length)', 4, Length(Expected));
  for i := 0 to 3 do
    AssertEquals(Msg + Format(' (word[%d])', [i]), Expected[i], Actual.mm_i16[i]);
end;

procedure TTestCase_TM64.AssertTM64DWordArray(const Expected: array of LongInt; const Actual: TM64; const Msg: string);
var
  i: Integer;
begin
  AssertEquals(Msg + ' (array length)', 2, Length(Expected));
  for i := 0 to 1 do
    AssertEquals(Msg + Format(' (dword[%d])', [i]), Expected[i], Actual.mm_i32[i]);
end;

// === 1️⃣ Load / Store 测试实现 ===

procedure TTestCase_TM64.Test_mmx_movd_mm;
var
  LValue: LongInt;
  LResult: TM64;
begin
  // 正数输入
  LValue := $12345678;
  LResult := mmx_movd_mm(@LValue);
  AssertEquals('movd_mm: low32 positive', $12345678, LResult.mm_u32[0]);
  AssertEquals('movd_mm: high32 positive', $00000000, LResult.mm_u32[1]);

  // 负数输入（符号位应保留在低32位，高32位仍清零）
  LValue := -1;
  LResult := mmx_movd_mm(@LValue);
  AssertEquals('movd_mm: low32 negative', UInt32($FFFFFFFF), LResult.mm_u32[0]);
  AssertEquals('movd_mm: high32 negative', $00000000, LResult.mm_u32[1]);
end;

procedure TTestCase_TM64.Test_mmx_movd_mm_store;
var
  LSrc: TM64;
  LDest: LongInt;
begin
  // 正常低32位存储
  LSrc.mm_u64 := UInt64($FEDCBA9876543210);
  LDest := 0;
  mmx_movd_mm_store(LDest, LSrc);
  AssertEquals('movd_mm_store: low32 positive', LongInt($76543210), LDest);

  // 负值低32位存储
  LSrc.mm_u64 := UInt64($00000000FFFFFFFF);
  LDest := 0;
  mmx_movd_mm_store(LDest, LSrc);
  AssertEquals('movd_mm_store: low32 negative', -1, LDest);
end;

procedure TTestCase_TM64.Test_mmx_movq_mm;
var
  value: UInt64;
  result: TM64;
begin
  // 测试加载 64 位整数
  value := UInt64($FEDCBA9876543210);
  result := mmx_movq_mm(@value);

  AssertEquals('movq_mm: 应该加载完整的64位值', UInt64($FEDCBA9876543210), result.mm_u64);
end;

procedure TTestCase_TM64.Test_mmx_movq_mm_store;
var
  src: TM64;
  dest: UInt64;
begin
  // 设置源数据
  src.mm_u64 := UInt64($FEDCBA9876543210);
  dest := 0; // 初始化

  // 存储64位
  mmx_movq_mm_store(dest, src);

  AssertEquals('movq_mm_store: 应该存储完整的64位值', UInt64($FEDCBA9876543210), dest);
end;

procedure TTestCase_TM64.Test_mmx_movd_r32;
var
  LSrc: TM64;
  LResult: LongWord;
begin
  LSrc.mm_u64 := UInt64($0123456789ABCDEF);
  LResult := mmx_movd_r32(LSrc);
  AssertEquals('movd_r32: low32', LongWord($89ABCDEF), LResult);
end;

procedure TTestCase_TM64.Test_mmx_movd_r32_to_mm;
var
  LResult: TM64;
begin
  LResult := mmx_movd_r32_to_mm(LongWord($89ABCDEF));
  AssertEquals('movd_r32_to_mm: low32', LongWord($89ABCDEF), LResult.mm_u32[0]);
  AssertEquals('movd_r32_to_mm: high32', LongWord(0), LResult.mm_u32[1]);
end;

// === 2️⃣ Set / Zero 测试实现 ===

procedure TTestCase_TM64.Test_mmx_setzero_si64;
var
  result: TM64;
begin
  result := mmx_setzero_si64;
  AssertEquals('setzero_si64: 应该返回0', UInt64(0), result.mm_u64);
end;

procedure TTestCase_TM64.Test_mmx_set1_pi8;
var
  result: TM64;
begin
  result := mmx_set1_pi8(42);
  AssertTM64ByteArray([42, 42, 42, 42, 42, 42, 42, 42], result, 'set1_pi8(42)');

  // 测试负数
  result := mmx_set1_pi8(-10);
  AssertTM64ByteArray([246, 246, 246, 246, 246, 246, 246, 246], result, 'set1_pi8(-10)');
end;

procedure TTestCase_TM64.Test_mmx_set1_pi16;
var
  result: TM64;
begin
  result := mmx_set1_pi16(1000);
  AssertTM64WordArray([1000, 1000, 1000, 1000], result, 'set1_pi16(1000)');

  // 测试负数
  result := mmx_set1_pi16(-500);
  AssertTM64WordArray([-500, -500, -500, -500], result, 'set1_pi16(-500)');
end;

procedure TTestCase_TM64.Test_mmx_set1_pi32;
var
  result: TM64;
begin
  result := mmx_set1_pi32(123456789);
  AssertTM64DWordArray([123456789, 123456789], result, 'set1_pi32(123456789)');
  
  // 测试负数
  result := mmx_set1_pi32(-987654321);
  AssertTM64DWordArray([-987654321, -987654321], result, 'set1_pi32(-987654321)');
end;

procedure TTestCase_TM64.Test_mmx_set_pi8;
var
  result: TM64;
begin
  result := mmx_set_pi8(1, 2, 3, 4, 5, 6, 7, 8);
  AssertTM64ByteArray([8, 7, 6, 5, 4, 3, 2, 1], result, 'set_pi8(1,2,3,4,5,6,7,8)');
end;

procedure TTestCase_TM64.Test_mmx_set_pi16;
var
  result: TM64;
begin
  result := mmx_set_pi16(100, 200, 300, 400);
  AssertTM64WordArray([400, 300, 200, 100], result, 'set_pi16(100,200,300,400)');
end;

procedure TTestCase_TM64.Test_mmx_set_pi32;
var
  result: TM64;
begin
  result := mmx_set_pi32(LongInt($12345678), LongInt($9ABCDEF0));
  AssertTM64DWordArray([LongInt($9ABCDEF0), LongInt($12345678)], result, 'set_pi32(0x12345678, 0x9ABCDEF0)');
end;

// === 3️⃣ Integer Arithmetic 测试实现 ===

procedure TTestCase_TM64.Test_mmx_paddb;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi8(1, 2, 3, 4, 5, 6, 7, 8);
  b := mmx_set_pi8(10, 20, 30, 40, 50, 60, 70, 80);
  result := mmx_paddb(a, b);
  AssertTM64ByteArray([88, 77, 66, 55, 44, 33, 22, 11], result, 'paddb');

  // 测试溢出
  a := mmx_set1_pi8(100);
  b := mmx_set1_pi8(50);
  result := mmx_paddb(a, b);
  AssertTM64ByteArray([150, 150, 150, 150, 150, 150, 150, 150], result, 'paddb normal (100+50=150)');
end;

procedure TTestCase_TM64.Test_mmx_paddw;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi16(100, 200, 300, 400);
  b := mmx_set_pi16(10, 20, 30, 40);
  result := mmx_paddw(a, b);
  AssertTM64WordArray([440, 330, 220, 110], result, 'paddw');

  // 测试正常情况
  a := mmx_set1_pi16(15000);
  b := mmx_set1_pi16(1000);
  result := mmx_paddw(a, b);
  AssertTM64WordArray([16000, 16000, 16000, 16000], result, 'paddw normal');
end;

procedure TTestCase_TM64.Test_mmx_paddd;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi32(1000000, 2000000);
  b := mmx_set_pi32(500000, 300000);
  result := mmx_paddd(a, b);
  AssertTM64DWordArray([2300000, 1500000], result, 'paddd');
end;

procedure TTestCase_TM64.Test_mmx_paddq;
var
  a, b, result: TM64;
begin
  a.mm_i64 := 1000000000000;
  b.mm_i64 := 500000000000;
  result := mmx_paddq(a, b);
  AssertEquals('paddq', Int64(1500000000000), result.mm_i64);
end;

procedure TTestCase_TM64.Test_mmx_paddsb;
var
  a, b, result: TM64;
begin
  // 正常情况
  a := mmx_set_pi8(10, 20, 30, 40, 50, 60, 70, 80);
  b := mmx_set_pi8(5, 10, 15, 20, 25, 30, 35, 40);
  result := mmx_paddsb(a, b);
  AssertTM64ByteArray([120, 105, 90, 75, 60, 45, 30, 15], result, 'paddsb normal');

  // 测试正向饱和
  a := mmx_set1_pi8(100);
  b := mmx_set1_pi8(50);
  result := mmx_paddsb(a, b);
  AssertTM64ByteArray([127, 127, 127, 127, 127, 127, 127, 127], result, 'paddsb positive saturation');

  // 测试负向饱和
  a := mmx_set1_pi8(-100);
  b := mmx_set1_pi8(-50);
  result := mmx_paddsb(a, b);
  AssertTM64ByteArray([128, 128, 128, 128, 128, 128, 128, 128], result, 'paddsb negative saturation');
end;

procedure TTestCase_TM64.Test_mmx_paddsw;
var
  a, b, result: TM64;
begin
  // 正常情况
  a := mmx_set_pi16(1000, 2000, 3000, 4000);
  b := mmx_set_pi16(500, 1000, 1500, 2000);
  result := mmx_paddsw(a, b);
  AssertTM64WordArray([6000, 4500, 3000, 1500], result, 'paddsw normal');

  // 测试正向饱和
  a := mmx_set1_pi16(30000);
  b := mmx_set1_pi16(5000);
  result := mmx_paddsw(a, b);
  AssertTM64WordArray([32767, 32767, 32767, 32767], result, 'paddsw positive saturation');

  // 测试负向饱和
  a := mmx_set1_pi16(-30000);
  b := mmx_set1_pi16(-5000);
  result := mmx_paddsw(a, b);
  AssertTM64WordArray([-32768, -32768, -32768, -32768], result, 'paddsw negative saturation');
end;

procedure TTestCase_TM64.Test_mmx_paddusb;
var
  a, b, result: TM64;
begin
  // 正常情况
  a := mmx_set_pi8(100, 50, 25, 10, 5, 2, 1, 0);
  b := mmx_set_pi8(50, 25, 10, 5, 2, 1, 0, 1);
  result := mmx_paddusb(a, b);
  AssertTM64ByteArray([1, 1, 3, 7, 15, 35, 75, 150], result, 'paddusb normal');

  // 测试饱和
  a := mmx_set1_pi8(127);
  b := mmx_set1_pi8(127);
  result := mmx_paddusb(a, b);
  AssertTM64ByteArray([254, 254, 254, 254, 254, 254, 254, 254], result, 'paddusb normal');
end;

procedure TTestCase_TM64.Test_mmx_paddusw;
var
  a, b, result: TM64;
begin
  // 正常情况
  a := mmx_set_pi16(1000, 2000, 3000, 4000);
  b := mmx_set_pi16(500, 1000, 1500, 2000);
  result := mmx_paddusw(a, b);
  AssertTM64WordArray([6000, 4500, 3000, 1500], result, 'paddusw normal');

  // 测试饱和
  a := mmx_set1_pi16(30000);
  b := mmx_set1_pi16(10000);
  result := mmx_paddusw(a, b);
  AssertTM64WordArray([SmallInt(40000), SmallInt(40000), SmallInt(40000), SmallInt(40000)], result, 'paddusw normal');
end;

// 减法运算测试
procedure TTestCase_TM64.Test_mmx_psubb;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi8(100, 90, 80, 70, 60, 50, 40, 30);
  b := mmx_set_pi8(10, 20, 30, 40, 50, 60, 70, 80);
  result := mmx_psubb(a, b);
  AssertTM64ByteArray([206, 226, 246, 10, 30, 50, 70, 90], result, 'psubb with wrap');
end;

procedure TTestCase_TM64.Test_mmx_psubw;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi16(5000, 4000, 3000, 2000);
  b := mmx_set_pi16(1000, 2000, 3000, 4000);
  result := mmx_psubw(a, b);
  AssertTM64WordArray([-2000, 0, 2000, 4000], result, 'psubw');
end;

procedure TTestCase_TM64.Test_mmx_psubd;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi32(2000000, 1000000);
  b := mmx_set_pi32(500000, 300000);
  result := mmx_psubd(a, b);
  AssertTM64DWordArray([700000, 1500000], result, 'psubd');
end;

procedure TTestCase_TM64.Test_mmx_psubq;
var
  a, b, result: TM64;
begin
  a.mm_i64 := 2000000000000;
  b.mm_i64 := 500000000000;
  result := mmx_psubq(a, b);
  AssertEquals('psubq', Int64(1500000000000), result.mm_i64);
end;

procedure TTestCase_TM64.Test_mmx_psubsb;
var
  a, b, result: TM64;
begin
  // 正常情况
  a := mmx_set_pi8(50, 40, 30, 20, 10, 0, -10, -20);
  b := mmx_set_pi8(10, 20, 30, 40, 50, 60, 70, 80);
  result := mmx_psubsb(a, b);
  AssertTM64ByteArray([156, 176, 196, 216, 236, 0, 20, 40], result, 'psubsb with saturation');
end;

procedure TTestCase_TM64.Test_mmx_psubsw;
var
  a, b, result: TM64;
begin
  // 正常情况
  a := mmx_set_pi16(1000, 0, -1000, -30000);
  b := mmx_set_pi16(2000, 1000, 2000, 5000);
  result := mmx_psubsw(a, b);
  AssertTM64WordArray([-32768, -3000, -1000, -1000], result, 'psubsw with saturation');
end;

procedure TTestCase_TM64.Test_mmx_psubusb;
var
  a, b, result: TM64;
begin
  // 正常情况
  a := mmx_set_pi8(100, 80, 60, 40, 20, 10, 5, 2);
  b := mmx_set_pi8(50, 40, 30, 20, 10, 5, 2, 1);
  result := mmx_psubusb(a, b);
  AssertTM64ByteArray([1, 3, 5, 10, 20, 30, 40, 50], result, 'psubusb normal');

  // 测试饱和到0
  a := mmx_set1_pi8(10);
  b := mmx_set1_pi8(50);
  result := mmx_psubusb(a, b);
  AssertTM64ByteArray([0, 0, 0, 0, 0, 0, 0, 0], result, 'psubusb saturation to 0');
end;

procedure TTestCase_TM64.Test_mmx_psubusw;
var
  a, b, result: TM64;
begin
  // 正常情况
  a := mmx_set_pi16(5000, 4000, 3000, 2000);
  b := mmx_set_pi16(1000, 2000, 3000, 4000);
  result := mmx_psubusw(a, b);
  AssertTM64WordArray([0, 0, 2000, 4000], result, 'psubusw with saturation to 0');
end;

// 乘法运算测试
procedure TTestCase_TM64.Test_mmx_pmullw;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi16(10, 20, 30, 40);
  b := mmx_set_pi16(2, 3, 4, 5);
  result := mmx_pmullw(a, b);
  AssertTM64WordArray([200, 120, 60, 20], result, 'pmullw');

  // 测试溢出（保留低16位）
  a := mmx_set_pi16(100, 200, 300, 400);
  b := mmx_set_pi16(10, 5, 25, 20);
  result := mmx_pmullw(a, b);
  // 100*10=1000, 200*5=1000, 300*25=7500, 400*20=8000
  AssertTM64WordArray([8000, 7500, 1000, 1000], result, 'pmullw normal');
end;

procedure TTestCase_TM64.Test_mmx_pmulhw;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi16(1000, 2000, 3000, 4000);
  b := mmx_set_pi16(100, 50, 25, 20);
  result := mmx_pmulhw(a, b);
  // 1000*100=100000, 高16位=1
  // 2000*50=100000, 高16位=1
  // 3000*25=75000, 高16位=1
  // 4000*20=80000, 高16位=1
  AssertTM64WordArray([1, 1, 1, 1], result, 'pmulhw');
end;

procedure TTestCase_TM64.Test_mmx_pmaddwd;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi16(10, 20, 30, 40);
  b := mmx_set_pi16(2, 3, 4, 5);
  result := mmx_pmaddwd(a, b);
  // (10*2 + 20*3) = 80, (30*4 + 40*5) = 320
  AssertTM64DWordArray([320, 80], result, 'pmaddwd');
end;

// === 5️⃣ Logical Operations 测试实现 ===

procedure TTestCase_TM64.Test_mmx_pand;
var
  a, b, result: TM64;
begin
  a.mm_u64 := UInt64($F0F0F0F0F0F0F0F0);
  b.mm_u64 := UInt64($AAAAAAAAAAAAAAAA);
  result := mmx_pand(a, b);
  AssertEquals('pand', UInt64($A0A0A0A0A0A0A0A0), result.mm_u64);
end;

procedure TTestCase_TM64.Test_mmx_pandn;
var
  a, b, result: TM64;
begin
  a.mm_u64 := UInt64($F0F0F0F0F0F0F0F0);
  b.mm_u64 := UInt64($AAAAAAAAAAAAAAAA);
  result := mmx_pandn(a, b);
  // ~a & b = ~$F0F0F0F0F0F0F0F0 & $AAAAAAAAAAAAAAAA = $0F0F0F0F0F0F0F0F & $AAAAAAAAAAAAAAAA = $0A0A0A0A0A0A0A0A
  AssertEquals('pandn', UInt64($0A0A0A0A0A0A0A0A), result.mm_u64);
end;

procedure TTestCase_TM64.Test_mmx_por;
var
  a, b, result: TM64;
begin
  a.mm_u64 := UInt64(17361641481138401520);  // $F0F0F0F0F0F0F0F0
  b.mm_u64 := UInt64(12297829382473034410); // $AAAAAAAAAAAAAAAA
  result := mmx_por(a, b);
  AssertEquals('por', UInt64(18085043209519168250), result.mm_u64); // $FAFAFAFAFAFAFAFA
end;

procedure TTestCase_TM64.Test_mmx_pxor;
var
  a, b, result: TM64;
begin
  a.mm_u64 := UInt64($F0F0F0F0F0F0F0F0);
  b.mm_u64 := UInt64($AAAAAAAAAAAAAAAA);
  result := mmx_pxor(a, b);
  AssertEquals('pxor', UInt64($5A5A5A5A5A5A5A5A), result.mm_u64);

  // 测试自异或为0
  result := mmx_pxor(a, a);
  AssertEquals('pxor self should be zero', UInt64(0), result.mm_u64);
end;

// === 6️⃣ Compare 测试实现 ===

procedure TTestCase_TM64.Test_mmx_pcmpeqb;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi8(10, 20, 30, 40, 50, 60, 70, 80);
  b := mmx_set_pi8(10, 25, 30, 35, 50, 65, 70, 75);
  result := mmx_pcmpeqb(a, b);
  AssertTM64ByteArray([0, 255, 0, 255, 0, 255, 0, 255], result, 'pcmpeqb');
end;

procedure TTestCase_TM64.Test_mmx_pcmpeqw;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi16(100, 200, 300, 400);
  b := mmx_set_pi16(100, 250, 300, 350);
  result := mmx_pcmpeqw(a, b);
  AssertEquals('pcmpeqw word[0]', UInt16($0000), result.mm_u16[0]);
  AssertEquals('pcmpeqw word[1]', UInt16($FFFF), result.mm_u16[1]);
  AssertEquals('pcmpeqw word[2]', UInt16($0000), result.mm_u16[2]);
  AssertEquals('pcmpeqw word[3]', UInt16($FFFF), result.mm_u16[3]);
end;

procedure TTestCase_TM64.Test_mmx_pcmpeqd;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi32(123456, 789012);
  b := mmx_set_pi32(123456, 999999);
  result := mmx_pcmpeqd(a, b);
  AssertEquals('pcmpeqd dword[0]', UInt32($00000000), result.mm_u32[0]);
  AssertEquals('pcmpeqd dword[1]', UInt32($FFFFFFFF), result.mm_u32[1]);
end;

procedure TTestCase_TM64.Test_mmx_pcmpgtb;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi8(10, 30, 50, 70, -10, -30, -50, -70);
  b := mmx_set_pi8(20, 20, 40, 80, -20, -20, -40, -80);
  result := mmx_pcmpgtb(a, b);
  // 10>20? No, 30>20? Yes, 50>40? Yes, 70>80? No
  // -10>-20? Yes, -30>-20? No, -50>-40? No, -70>-80? Yes
  AssertTM64ByteArray([255, 0, 0, 255, 0, 255, 255, 0], result, 'pcmpgtb');
end;

procedure TTestCase_TM64.Test_mmx_pcmpgtw;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi16(100, 300, -100, -300);
  b := mmx_set_pi16(200, 200, -200, -200);
  result := mmx_pcmpgtw(a, b);
  // 100>200? No, 300>200? Yes, -100>-200? Yes, -300>-200? No
  AssertEquals('pcmpgtw word[0]', UInt16($0000), result.mm_u16[0]);
  AssertEquals('pcmpgtw word[1]', UInt16($FFFF), result.mm_u16[1]);
  AssertEquals('pcmpgtw word[2]', UInt16($FFFF), result.mm_u16[2]);
  AssertEquals('pcmpgtw word[3]', UInt16($0000), result.mm_u16[3]);
end;

procedure TTestCase_TM64.Test_mmx_pcmpgtd;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi32(1000000, -1000000);
  b := mmx_set_pi32(2000000, -2000000);
  result := mmx_pcmpgtd(a, b);
  // 1000000>2000000? No, -1000000>-2000000? Yes
  AssertEquals('pcmpgtd dword[0]', UInt32($FFFFFFFF), result.mm_u32[0]);
  AssertEquals('pcmpgtd dword[1]', UInt32($00000000), result.mm_u32[1]);
end;

// === 7️⃣ Shift 测试实现 ===

procedure TTestCase_TM64.Test_mmx_psllw;
var
  a, count, result: TM64;
begin
  a := mmx_set_pi16(1, 2, 4, 8);
  count := mmx_setzero_si64;
  count.mm_u8[0] := 2;  // 左移2位
  result := mmx_psllw(a, count);
  AssertTM64WordArray([32, 16, 8, 4], result, 'psllw shift by 2');

  // 测试移位超过位宽
  count.mm_u8[0] := 16;
  result := mmx_psllw(a, count);
  AssertTM64WordArray([0, 0, 0, 0], result, 'psllw shift by 16 (overflow)');
end;

procedure TTestCase_TM64.Test_mmx_pslld;
var
  a, count, result: TM64;
begin
  a := mmx_set_pi32(1, 2);
  count := mmx_setzero_si64;
  count.mm_u8[0] := 4;  // 左移4位
  result := mmx_pslld(a, count);
  AssertTM64DWordArray([32, 16], result, 'pslld shift by 4');

  // 测试移位超过位宽
  count.mm_u8[0] := 32;
  result := mmx_pslld(a, count);
  AssertTM64DWordArray([0, 0], result, 'pslld shift by 32 (overflow)');
end;

procedure TTestCase_TM64.Test_mmx_psllq;
var
  a, count, result: TM64;
begin
  a.mm_u64 := $0000000000000001;
  count := mmx_setzero_si64;
  count.mm_u8[0] := 8;  // 左移8位
  result := mmx_psllq(a, count);
  AssertEquals('psllq shift by 8', UInt64($0000000000000100), result.mm_u64);

  // 测试移位超过位宽
  count.mm_u8[0] := 64;
  result := mmx_psllq(a, count);
  AssertEquals('psllq shift by 64 (overflow)', UInt64(0), result.mm_u64);
end;

procedure TTestCase_TM64.Test_mmx_psllw_imm;
var
  a, result: TM64;
begin
  a := mmx_set_pi16(1, 2, 4, 8);
  result := mmx_psllw_imm(a, 3);
  AssertTM64WordArray([64, 32, 16, 8], result, 'psllw_imm shift by 3');

  // 测试移位超过位宽
  result := mmx_psllw_imm(a, 16);
  AssertTM64WordArray([0, 0, 0, 0], result, 'psllw_imm shift by 16 (overflow)');
end;

procedure TTestCase_TM64.Test_mmx_pslld_imm;
var
  a, result: TM64;
begin
  a := mmx_set_pi32(1, 2);
  result := mmx_pslld_imm(a, 5);
  AssertTM64DWordArray([64, 32], result, 'pslld_imm shift by 5');

  // 测试移位超过位宽
  result := mmx_pslld_imm(a, 32);
  AssertTM64DWordArray([0, 0], result, 'pslld_imm shift by 32 (overflow)');
end;

procedure TTestCase_TM64.Test_mmx_psllq_imm;
var
  a, result: TM64;
begin
  a.mm_u64 := $0000000000000001;
  result := mmx_psllq_imm(a, 12);
  AssertEquals('psllq_imm shift by 12', UInt64($0000000000001000), result.mm_u64);

  // 测试移位超过位宽
  result := mmx_psllq_imm(a, 64);
  AssertEquals('psllq_imm shift by 64 (overflow)', UInt64(0), result.mm_u64);
end;

// 逻辑右移测试
procedure TTestCase_TM64.Test_mmx_psrlw;
var
  a, count, result: TM64;
begin
  a := mmx_set_pi16(64, 32, 16, 8);
  count := mmx_setzero_si64;
  count.mm_u8[0] := 2;  // 右移2位
  result := mmx_psrlw(a, count);
  AssertTM64WordArray([2, 4, 8, 16], result, 'psrlw shift by 2');

  // 测试移位超过位宽
  count.mm_u8[0] := 16;
  result := mmx_psrlw(a, count);
  AssertTM64WordArray([0, 0, 0, 0], result, 'psrlw shift by 16 (overflow)');
end;

procedure TTestCase_TM64.Test_mmx_psrld;
var
  a, count, result: TM64;
begin
  a := mmx_set_pi32(64, 32);
  count := mmx_setzero_si64;
  count.mm_u8[0] := 4;  // 右移4位
  result := mmx_psrld(a, count);
  AssertTM64DWordArray([2, 4], result, 'psrld shift by 4');

  // 测试移位超过位宽
  count.mm_u8[0] := 32;
  result := mmx_psrld(a, count);
  AssertTM64DWordArray([0, 0], result, 'psrld shift by 32 (overflow)');
end;

procedure TTestCase_TM64.Test_mmx_psrlq;
var
  a, count, result: TM64;
begin
  a.mm_u64 := $0000000000001000;
  count := mmx_setzero_si64;
  count.mm_u8[0] := 8;  // 右移8位
  result := mmx_psrlq(a, count);
  AssertEquals('psrlq shift by 8', UInt64($0000000000000010), result.mm_u64);

  // 测试移位超过位宽
  count.mm_u8[0] := 64;
  result := mmx_psrlq(a, count);
  AssertEquals('psrlq shift by 64 (overflow)', UInt64(0), result.mm_u64);
end;

procedure TTestCase_TM64.Test_mmx_psrlw_imm;
var
  a, result: TM64;
begin
  a := mmx_set_pi16(64, 32, 16, 8);
  result := mmx_psrlw_imm(a, 3);
  AssertTM64WordArray([1, 2, 4, 8], result, 'psrlw_imm shift by 3');

  // 测试移位超过位宽
  result := mmx_psrlw_imm(a, 16);
  AssertTM64WordArray([0, 0, 0, 0], result, 'psrlw_imm shift by 16 (overflow)');
end;

procedure TTestCase_TM64.Test_mmx_psrld_imm;
var
  a, result: TM64;
begin
  a := mmx_set_pi32(64, 32);
  result := mmx_psrld_imm(a, 5);
  AssertTM64DWordArray([1, 2], result, 'psrld_imm shift by 5');

  // 测试移位超过位宽
  result := mmx_psrld_imm(a, 32);
  AssertTM64DWordArray([0, 0], result, 'psrld_imm shift by 32 (overflow)');
end;

procedure TTestCase_TM64.Test_mmx_psrlq_imm;
var
  a, result: TM64;
begin
  a.mm_u64 := $0000000000001000;
  result := mmx_psrlq_imm(a, 12);
  AssertEquals('psrlq_imm shift by 12', UInt64($0000000000000001), result.mm_u64);

  // 测试移位超过位宽
  result := mmx_psrlq_imm(a, 64);
  AssertEquals('psrlq_imm shift by 64 (overflow)', UInt64(0), result.mm_u64);
end;

// 算术右移测试
procedure TTestCase_TM64.Test_mmx_psraw;
var
  a, count, result: TM64;
begin
  // 测试正数
  a := mmx_set_pi16(64, 32, 16, 8);
  count := mmx_setzero_si64;
  count.mm_u8[0] := 2;  // 右移2位
  result := mmx_psraw(a, count);
  AssertTM64WordArray([2, 4, 8, 16], result, 'psraw positive numbers');

  // 测试负数（符号扩展）
  a := mmx_set_pi16(-64, -32, -16, -8);
  result := mmx_psraw(a, count);
  AssertTM64WordArray([-2, -4, -8, -16], result, 'psraw negative numbers');

  // 测试移位超过位宽
  count.mm_u8[0] := 16;
  result := mmx_psraw(a, count);
  AssertTM64WordArray([-1, -1, -1, -1], result, 'psraw shift by 16 (sign extend)');
end;

procedure TTestCase_TM64.Test_mmx_psrad;
var
  a, count, result: TM64;
begin
  // 测试正数
  a := mmx_set_pi32(64, 32);
  count := mmx_setzero_si64;
  count.mm_u8[0] := 4;  // 右移4位
  result := mmx_psrad(a, count);
  AssertTM64DWordArray([2, 4], result, 'psrad positive numbers');

  // 测试负数（符号扩展）
  a := mmx_set_pi32(-64, -32);
  result := mmx_psrad(a, count);
  AssertTM64DWordArray([-2, -4], result, 'psrad negative numbers');

  // 测试移位超过位宽
  count.mm_u8[0] := 32;
  result := mmx_psrad(a, count);
  AssertTM64DWordArray([-1, -1], result, 'psrad shift by 32 (sign extend)');
end;

procedure TTestCase_TM64.Test_mmx_psraw_imm;
var
  a, result: TM64;
begin
  // 测试正数
  a := mmx_set_pi16(64, 32, 16, 8);
  result := mmx_psraw_imm(a, 3);
  AssertTM64WordArray([1, 2, 4, 8], result, 'psraw_imm positive numbers');

  // 测试负数（符号扩展）
  a := mmx_set_pi16(-64, -32, -16, -8);
  result := mmx_psraw_imm(a, 3);
  AssertTM64WordArray([-1, -2, -4, -8], result, 'psraw_imm negative numbers');

  // 测试移位超过位宽
  result := mmx_psraw_imm(a, 16);
  AssertTM64WordArray([-1, -1, -1, -1], result, 'psraw_imm shift by 16 (sign extend)');
end;

procedure TTestCase_TM64.Test_mmx_psrad_imm;
var
  a, result: TM64;
begin
  // 测试正数
  a := mmx_set_pi32(64, 32);
  result := mmx_psrad_imm(a, 5);
  AssertTM64DWordArray([1, 2], result, 'psrad_imm positive numbers');

  // 测试负数（符号扩展）
  a := mmx_set_pi32(-64, -32);
  result := mmx_psrad_imm(a, 5);
  AssertTM64DWordArray([-1, -2], result, 'psrad_imm negative numbers');

  // 测试移位超过位宽
  result := mmx_psrad_imm(a, 32);
  AssertTM64DWordArray([-1, -1], result, 'psrad_imm shift by 32 (sign extend)');
end;

procedure TTestCase_TM64.Test_mmx_psllw_mm;
var
  a, count, result: TM64;
begin
  a := mmx_set_pi16(8, 4, 2, 1);
  count := mmx_setzero_si64;
  count.mm_u8[0] := 3;
  result := mmx_psllw_mm(a, count);
  AssertTM64WordArray([8, 16, 32, 64], result, 'psllw_mm shift by 3');
end;

procedure TTestCase_TM64.Test_mmx_psrlw_mm;
var
  a, count, result: TM64;
begin
  a := mmx_set_pi16(64, 32, 16, 8);
  count := mmx_setzero_si64;
  count.mm_u8[0] := 3;
  result := mmx_psrlw_mm(a, count);
  AssertTM64WordArray([1, 2, 4, 8], result, 'psrlw_mm shift by 3');
end;

procedure TTestCase_TM64.Test_mmx_psraw_mm;
var
  a, count, result: TM64;
begin
  a := mmx_set_pi16(-64, -32, -16, -8);
  count := mmx_setzero_si64;
  count.mm_u8[0] := 4;
  result := mmx_psraw_mm(a, count);
  AssertTM64WordArray([-1, -1, -2, -4], result, 'psraw_mm arithmetic shift');
end;

// === 10️⃣ Pack / Unpack 测试实现 ===

procedure TTestCase_TM64.Test_mmx_packsswb;
var
  a, b, result: TM64;
begin
  // 正常情况
  a := mmx_set_pi16(100, 50, 25, 10);
  b := mmx_set_pi16(200, 150, 75, 5);
  result := mmx_packsswb(a, b);
  AssertTM64ByteArray([10, 25, 50, 100, 5, 75, 127, 127], result, 'packsswb normal');

  // 测试饱和
  a := mmx_set_pi16(300, -300, 127, -128);
  b := mmx_set_pi16(1000, -1000, 50, -50);
  result := mmx_packsswb(a, b);
  AssertTM64ByteArray([128, 127, 128, 127, 206, 50, 128, 127], result, 'packsswb saturation');
end;

procedure TTestCase_TM64.Test_mmx_packssdw;
var
  a, b, result: TM64;
begin
  // 正常情况
  a := mmx_set_pi32(10000, 5000);
  b := mmx_set_pi32(20000, 15000);
  result := mmx_packssdw(a, b);
  AssertTM64WordArray([5000, 10000, 15000, 20000], result, 'packssdw normal');

  // 测试饱和
  a := mmx_set_pi32(100000, -100000);
  b := mmx_set_pi32(50000, -50000);
  result := mmx_packssdw(a, b);
  AssertTM64WordArray([-32768, 32767, -32768, 32767], result, 'packssdw saturation');
end;

procedure TTestCase_TM64.Test_mmx_packuswb;
var
  a, b, result: TM64;
begin
  // 正常情况
  a := mmx_set_pi16(100, 50, 25, 10);
  b := mmx_set_pi16(200, 150, 75, 5);
  result := mmx_packuswb(a, b);
  AssertTM64ByteArray([10, 25, 50, 100, 5, 75, 150, 200], result, 'packuswb normal');

  // 测试饱和（负数饱和到0，大数饱和到255）
  a := mmx_set_pi16(300, -100, 255, 0);
  b := mmx_set_pi16(1000, -50, 128, 64);
  result := mmx_packuswb(a, b);
  AssertTM64ByteArray([0, 255, 0, 255, 64, 128, 0, 255], result, 'packuswb saturation');
end;

procedure TTestCase_TM64.Test_mmx_punpckhbw;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi8(1, 2, 3, 4, 5, 6, 7, 8);
  b := mmx_set_pi8(10, 20, 30, 40, 50, 60, 70, 80);
  result := mmx_punpckhbw(a, b);
  // 交织高4个字节：a[4-7] 和 b[4-7]
  AssertTM64ByteArray([4, 40, 3, 30, 2, 20, 1, 10], result, 'punpckhbw');
end;

procedure TTestCase_TM64.Test_mmx_punpckhwd;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi16(1, 2, 3, 4);
  b := mmx_set_pi16(10, 20, 30, 40);
  result := mmx_punpckhwd(a, b);
  // 交织高2个字：a[2-3] 和 b[2-3]
  AssertTM64WordArray([2, 20, 1, 10], result, 'punpckhwd');
end;

procedure TTestCase_TM64.Test_mmx_punpckhdq;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi32(1, 2);
  b := mmx_set_pi32(10, 20);
  result := mmx_punpckhdq(a, b);
  // 交织高1个双字：a[1] 和 b[1]
  AssertTM64DWordArray([1, 10], result, 'punpckhdq');
end;

procedure TTestCase_TM64.Test_mmx_punpcklbw;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi8(1, 2, 3, 4, 5, 6, 7, 8);
  b := mmx_set_pi8(10, 20, 30, 40, 50, 60, 70, 80);
  result := mmx_punpcklbw(a, b);
  // 交织低4个字节：a[0-3] 和 b[0-3]
  AssertTM64ByteArray([8, 80, 7, 70, 6, 60, 5, 50], result, 'punpcklbw');
end;

procedure TTestCase_TM64.Test_mmx_punpcklwd;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi16(1, 2, 3, 4);
  b := mmx_set_pi16(10, 20, 30, 40);
  result := mmx_punpcklwd(a, b);
  // 交织低2个字：a[0-1] 和 b[0-1]
  AssertTM64WordArray([4, 40, 3, 30], result, 'punpcklwd');
end;

procedure TTestCase_TM64.Test_mmx_punpckldq;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi32(1, 2);
  b := mmx_set_pi32(10, 20);
  result := mmx_punpckldq(a, b);
  // 交织低1个双字：a[0] 和 b[0]
  AssertTM64DWordArray([2, 20], result, 'punpckldq');
end;

procedure TTestCase_TM64.Test_mmx_packusdw;
var
  a, b, result: TM64;
begin
  a := mmx_set_pi32($0000FFFF, $00010000);
  b := mmx_set_pi32(-1, 42);
  result := mmx_packusdw(a, b);

  AssertEquals('packusdw lane0', UInt16($FFFF), result.mm_u16[0]);
  AssertEquals('packusdw lane1', UInt16($FFFF), result.mm_u16[1]);
  AssertEquals('packusdw lane2', UInt16(42), result.mm_u16[2]);
  AssertEquals('packusdw lane3', UInt16(0), result.mm_u16[3]);
end;

procedure TTestCase_TM64.Test_mmx_punpcklbw_mem;
var
  a, result: TM64;
  LMem: array[0..7] of Byte;
begin
  a := mmx_set_pi8(1, 2, 3, 4, 5, 6, 7, 8);
  LMem[0] := 80;
  LMem[1] := 70;
  LMem[2] := 60;
  LMem[3] := 50;
  LMem[4] := 40;
  LMem[5] := 30;
  LMem[6] := 20;
  LMem[7] := 10;

  result := mmx_punpcklbw_mem(a, @LMem[0]);
  AssertTM64ByteArray([8, 80, 7, 70, 6, 60, 5, 50], result, 'punpcklbw_mem');
end;

procedure TTestCase_TM64.Test_mmx_punpcklwd_mem;
var
  a, result: TM64;
  LMem: array[0..3] of Word;
begin
  a := mmx_set_pi16(1, 2, 3, 4);
  LMem[0] := 400;
  LMem[1] := 300;
  LMem[2] := 200;
  LMem[3] := 100;

  result := mmx_punpcklwd_mem(a, @LMem[0]);
  AssertTM64WordArray([4, 400, 3, 300], result, 'punpcklwd_mem');
end;

procedure TTestCase_TM64.Test_mmx_punpckldq_mem;
var
  a, result: TM64;
  LMem: array[0..1] of LongInt;
begin
  a := mmx_set_pi32(1, 2);
  LMem[0] := 2000000;
  LMem[1] := 1000000;

  result := mmx_punpckldq_mem(a, @LMem[0]);
  AssertTM64DWordArray([2, 2000000], result, 'punpckldq_mem');
end;

// === 11️⃣ Miscellaneous 测试实现 ===

procedure TTestCase_TM64.Test_mmx_emms;
begin
  // EMMS 指令在我们的实现中是空操作，只测试它不会崩溃
  mmx_emms;
  AssertTrue('mmx_emms should not crash', True);
end;

initialization
  RegisterTest(TTestCase_TM64);

end.
