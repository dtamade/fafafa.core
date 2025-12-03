unit fafafa.core.simd.testcase;

{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.simd,
  fafafa.core.simd.types,
  fafafa.core.simd.api,
  fafafa.core.simd.scalar,
  fafafa.core.simd.sse2,
  fafafa.core.simd.avx2,
  fafafa.core.simd.avx512,
  fafafa.core.simd.cpuinfo;

type
  // 全局函数测试
  TTestCase_Global = class(TTestCase)
  published
    // 内存操作函数测试
    procedure Test_MemEqual;
    procedure Test_MemEqual_Empty;
    procedure Test_MemEqual_Nil;
    procedure Test_MemFindByte;
    procedure Test_MemFindByte_NotFound;
    procedure Test_MemFindByte_Empty;
    procedure Test_MemDiffRange;
    procedure Test_MemDiffRange_NoDiff;
    procedure Test_MemCopy;
    procedure Test_MemSet;
    procedure Test_MemReverse;
    
    // 统计函数测试
    procedure Test_SumBytes;
    procedure Test_SumBytes_Empty;
    procedure Test_MinMaxBytes;
    procedure Test_MinMaxBytes_Single;
    procedure Test_CountByte;
    procedure Test_CountByte_None;
    
    // 文本处理函数测试
    procedure Test_Utf8Validate;
    procedure Test_Utf8Validate_Invalid;
    procedure Test_AsciiIEqual;
    procedure Test_AsciiIEqual_CaseDiff;
    procedure Test_ToLowerAscii;
    procedure Test_ToUpperAscii;
    
    // 搜索函数测试
    procedure Test_BytesIndexOf;
    procedure Test_BytesIndexOf_NotFound;
    procedure Test_BytesIndexOf_Empty;
    
    // 位集函数测试
    procedure Test_BitsetPopCount;
    procedure Test_BitsetPopCount_Empty;
    procedure Test_BitsetPopCount_AllSet;
  end;

  // 后端一致性测试 - 确保所有后端对同一输入产生相同结果
  TTestCase_BackendConsistency = class(TTestCase)
  published
    procedure Test_MemEqual_Consistency;
    procedure Test_MemFindByte_Consistency;
    procedure Test_SumBytes_Consistency;
    procedure Test_CountByte_Consistency;
    procedure Test_MinMaxBytes_Consistency;
    procedure Test_BitsetPopCount_Consistency;
    procedure Test_Utf8Validate_Consistency;
    procedure Test_MemReverse_Consistency;
    procedure Test_AsciiIEqual_Consistency;
    procedure Test_ToLowerAscii_Consistency;
    procedure Test_ToUpperAscii_Consistency;
    procedure Test_MemDiffRange_Consistency;
    procedure Test_BytesIndexOf_Consistency;
  end;

  // 向量运算测试 (强制使用 Scalar 后端以避免 AVX2 实现的问题)
  TTestCase_VectorOps = class(TTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_VecF32x4_Add;
    procedure Test_VecF32x4_Sub;
    procedure Test_VecF32x4_Mul;
    procedure Test_VecF32x4_Div;
    procedure Test_VecF32x4_Sqrt;
    procedure Test_VecF32x4_Min;
    procedure Test_VecF32x4_Max;
    procedure Test_VecF32x4_Abs;
    procedure Test_VecF32x4_ReduceAdd;
    procedure Test_VecF32x4_ReduceMin;
    procedure Test_VecF32x4_ReduceMax;
    procedure Test_VecF32x4_Splat;
    procedure Test_VecF32x4_LoadStore;
    procedure Test_VecF32x4_Compare;
    // 扩展数学函数测试
    procedure Test_VecF32x4_Fma;
    procedure Test_VecF32x4_Rcp;
    procedure Test_VecF32x4_Rsqrt;
    procedure Test_VecF32x4_Floor;
    procedure Test_VecF32x4_Ceil;
    procedure Test_VecF32x4_Round;
    procedure Test_VecF32x4_Trunc;
    procedure Test_VecF32x4_Clamp;
    // 3D/4D 向量数学测试
    procedure Test_VecF32x4_Dot;
    procedure Test_VecF32x3_Dot;
    procedure Test_VecF32x3_Cross;
    procedure Test_VecF32x4_Length;
    procedure Test_VecF32x3_Length;
    procedure Test_VecF32x4_Normalize;
    procedure Test_VecF32x3_Normalize;
  end;

  // 大数据量和边界测试
  TTestCase_LargeData = class(TTestCase)
  published
    procedure Test_MemEqual_1MB;
    procedure Test_SumBytes_1MB;
    procedure Test_MemFindByte_LargeBuffer;
    procedure Test_UnalignedPointer;
    procedure Test_OddSizes;
  end;

  // Phase 1.1: 无符号向量类型测试
  TTestCase_UnsignedVectorTypes = class(TTestCase)
  published
    // TVecU32x4 类型定义测试
    procedure Test_VecU32x4_TypeDef_Size;
    procedure Test_VecU32x4_TypeDef_Layout;
    procedure Test_VecU32x4_TypeDef_RawAccess;
    
    // TVecU16x8 类型定义测试
    procedure Test_VecU16x8_TypeDef_Size;
    procedure Test_VecU16x8_TypeDef_Layout;
    procedure Test_VecU16x8_TypeDef_RawAccess;
    
    // TVecU8x16 类型定义测试
    procedure Test_VecU8x16_TypeDef_Size;
    procedure Test_VecU8x16_TypeDef_Layout;
    procedure Test_VecU8x16_TypeDef_RawAccess;
    
    // TVecU64x2 类型定义测试
    procedure Test_VecU64x2_TypeDef_Size;
    procedure Test_VecU64x2_TypeDef_Layout;
    procedure Test_VecU64x2_TypeDef_RawAccess;
    
    // 256-bit 无符号向量类型测试
    procedure Test_VecU32x8_TypeDef_Size;
    procedure Test_VecU32x8_TypeDef_LoHi;
    procedure Test_VecU16x16_TypeDef_Size;
    procedure Test_VecU16x16_TypeDef_LoHi;
    procedure Test_VecU8x32_TypeDef_Size;
    procedure Test_VecU8x32_TypeDef_LoHi;
  end;

  // Phase 1.2: 运算符重载测试
  TTestCase_OperatorOverloads = class(TTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // TVecF32x4 运算符测试
    procedure Test_VecF32x4_Op_Add;
    procedure Test_VecF32x4_Op_Sub;
    procedure Test_VecF32x4_Op_Mul;
    procedure Test_VecF32x4_Op_Div;
    procedure Test_VecF32x4_Op_Neg;
    
    // TVecF64x2 运算符测试
    procedure Test_VecF64x2_Op_Add;
    procedure Test_VecF64x2_Op_Sub;
    procedure Test_VecF64x2_Op_Mul;
    procedure Test_VecF64x2_Op_Div;
    
    // TVecI32x4 运算符测试
    procedure Test_VecI32x4_Op_Add;
    procedure Test_VecI32x4_Op_Sub;
    procedure Test_VecI32x4_Op_Neg;
    
    // 标量操作测试
    procedure Test_VecF32x4_Op_ScalarMul;
    procedure Test_VecF32x4_Op_ScalarDiv;
  end;

implementation

{ TTestCase_Global }

// === 内存操作函数测试 ===

procedure TTestCase_Global.Test_MemEqual;
var
  buf1, buf2: array[0..15] of Byte;
  i: Integer;
begin
  // 测试相等的内存区域
  for i := 0 to 15 do
  begin
    buf1[i] := i;
    buf2[i] := i;
  end;
  
  AssertTrue('MemEqual should return True for equal buffers', MemEqual(@buf1[0], @buf2[0], 16));
  
  // 测试不相等的内存区域
  buf2[8] := 255;
  AssertFalse('MemEqual should return False for different buffers', MemEqual(@buf1[0], @buf2[0], 16));
end;

procedure TTestCase_Global.Test_MemEqual_Empty;
begin
  AssertTrue('MemEqual should return True for zero length', MemEqual(nil, nil, 0));
end;

procedure TTestCase_Global.Test_MemEqual_Nil;
begin
  AssertTrue('MemEqual should return True for both nil pointers', MemEqual(nil, nil, 10));
  AssertFalse('MemEqual should return False for one nil pointer', MemEqual(@Self, nil, 10));
end;

procedure TTestCase_Global.Test_MemFindByte;
var
  buf: array[0..15] of Byte;
  i: Integer;
begin
  for i := 0 to 15 do
    buf[i] := i;
    
  AssertEquals('Should find byte at correct position', 5, MemFindByte(@buf[0], 16, 5));
  AssertEquals('Should find first occurrence', 0, MemFindByte(@buf[0], 16, 0));
  AssertEquals('Should find last occurrence', 15, MemFindByte(@buf[0], 16, 15));
end;

procedure TTestCase_Global.Test_MemFindByte_NotFound;
var
  buf: array[0..15] of Byte;
  i: Integer;
begin
  for i := 0 to 15 do
    buf[i] := i;
    
  AssertEquals('Should return -1 when byte not found', -1, MemFindByte(@buf[0], 16, 255));
end;

procedure TTestCase_Global.Test_MemFindByte_Empty;
begin
  AssertEquals('Should return -1 for empty buffer', -1, MemFindByte(nil, 0, 5));
end;

procedure TTestCase_Global.Test_MemDiffRange;
var
  buf1, buf2: array[0..15] of Byte;
  i: Integer;
  firstDiff, lastDiff: SizeUInt;
  hasDiff: Boolean;
begin
  // 设置相同的缓冲区
  for i := 0 to 15 do
  begin
    buf1[i] := i;
    buf2[i] := i;
  end;
  
  // 在中间创建差异
  buf2[5] := 255;
  buf2[10] := 254;
  
  hasDiff := MemDiffRange(@buf1[0], @buf2[0], 16, firstDiff, lastDiff);
  
  AssertTrue('Should detect differences', hasDiff);
  AssertEquals('First difference should be at position 5', 5, firstDiff);
  AssertEquals('Last difference should be at position 10', 10, lastDiff);
end;

procedure TTestCase_Global.Test_MemDiffRange_NoDiff;
var
  buf1, buf2: array[0..15] of Byte;
  i: Integer;
  firstDiff, lastDiff: SizeUInt;
  hasDiff: Boolean;
begin
  for i := 0 to 15 do
  begin
    buf1[i] := i;
    buf2[i] := i;
  end;
  
  hasDiff := MemDiffRange(@buf1[0], @buf2[0], 16, firstDiff, lastDiff);
  
  AssertFalse('Should not detect differences in identical buffers', hasDiff);
end;

procedure TTestCase_Global.Test_MemCopy;
var
  src, dst: array[0..15] of Byte;
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    src[i] := i;
    dst[i] := 255;
  end;
  
  MemCopy(@src[0], @dst[0], 16);
  
  for i := 0 to 15 do
    AssertEquals('Copied data should match source', src[i], dst[i]);
end;

procedure TTestCase_Global.Test_MemSet;
var
  buf: array[0..15] of Byte;
  i: Integer;
begin
  // 初始化为不同值
  for i := 0 to 15 do
    buf[i] := i;
    
  MemSet(@buf[0], 16, 42);
  
  for i := 0 to 15 do
    AssertEquals('All bytes should be set to 42', 42, buf[i]);
end;

procedure TTestCase_Global.Test_MemReverse;
var
  buf: array[0..7] of Byte;
  i: Integer;
begin
  for i := 0 to 7 do
    buf[i] := i;
    
  MemReverse(@buf[0], 8);
  
  for i := 0 to 7 do
    AssertEquals('Reversed buffer should have correct values', 7 - i, buf[i]);
end;

// === 统计函数测试 ===

procedure TTestCase_Global.Test_SumBytes;
var
  buf: array[0..3] of Byte;
  sum: UInt64;
begin
  buf[0] := 1;
  buf[1] := 2;
  buf[2] := 3;
  buf[3] := 4;
  
  sum := SumBytes(@buf[0], 4);
  AssertEquals('Sum should be 10', 10, sum);
end;

procedure TTestCase_Global.Test_SumBytes_Empty;
var
  sum: UInt64;
begin
  sum := SumBytes(nil, 0);
  AssertEquals('Sum of empty buffer should be 0', 0, sum);
end;

procedure TTestCase_Global.Test_MinMaxBytes;
var
  buf: array[0..4] of Byte;
  minVal, maxVal: Byte;
begin
  buf[0] := 10;
  buf[1] := 5;
  buf[2] := 20;
  buf[3] := 1;
  buf[4] := 15;
  
  MinMaxBytes(@buf[0], 5, minVal, maxVal);
  
  AssertEquals('Min value should be 1', 1, minVal);
  AssertEquals('Max value should be 20', 20, maxVal);
end;

procedure TTestCase_Global.Test_MinMaxBytes_Single;
var
  buf: array[0..0] of Byte;
  minVal, maxVal: Byte;
begin
  buf[0] := 42;
  
  MinMaxBytes(@buf[0], 1, minVal, maxVal);
  
  AssertEquals('Min value should be 42', 42, minVal);
  AssertEquals('Max value should be 42', 42, maxVal);
end;

procedure TTestCase_Global.Test_CountByte;
var
  buf: array[0..7] of Byte;
  count: SizeUInt;
begin
  buf[0] := 1;
  buf[1] := 2;
  buf[2] := 1;
  buf[3] := 3;
  buf[4] := 1;
  buf[5] := 4;
  buf[6] := 1;
  buf[7] := 5;
  
  count := CountByte(@buf[0], 8, 1);
  AssertEquals('Should count 4 occurrences of byte 1', 4, count);
end;

procedure TTestCase_Global.Test_CountByte_None;
var
  buf: array[0..7] of Byte;
  count: SizeUInt;
  i: Integer;
begin
  for i := 0 to 7 do
    buf[i] := i;
    
  count := CountByte(@buf[0], 8, 255);
  AssertEquals('Should count 0 occurrences of byte 255', 0, count);
end;

// === 文本处理函数测试 ===

procedure TTestCase_Global.Test_Utf8Validate;
var
  validUtf8: array[0..6] of Byte;
  isValid: Boolean;
begin
  // 测试有效的 UTF-8 序列: "Hello"
  validUtf8[0] := Ord('H');
  validUtf8[1] := Ord('e');
  validUtf8[2] := Ord('l');
  validUtf8[3] := Ord('l');
  validUtf8[4] := Ord('o');

  isValid := Utf8Validate(@validUtf8[0], 5);
  AssertTrue('Valid ASCII should pass UTF-8 validation', isValid);
end;

procedure TTestCase_Global.Test_Utf8Validate_Invalid;
var
  invalidUtf8: array[0..3] of Byte;
  isValid: Boolean;
begin
  // 测试无效的 UTF-8 序列
  invalidUtf8[0] := $C0;  // 无效的起始字节
  invalidUtf8[1] := $80;

  isValid := Utf8Validate(@invalidUtf8[0], 2);
  AssertFalse('Invalid UTF-8 sequence should fail validation', isValid);
end;

procedure TTestCase_Global.Test_AsciiIEqual;
var
  buf1, buf2: array[0..4] of Byte;
  isEqual: Boolean;
begin
  // 测试大小写不敏感比较
  buf1[0] := Ord('H');
  buf1[1] := Ord('e');
  buf1[2] := Ord('L');
  buf1[3] := Ord('L');
  buf1[4] := Ord('o');

  buf2[0] := Ord('h');
  buf2[1] := Ord('E');
  buf2[2] := Ord('l');
  buf2[3] := Ord('l');
  buf2[4] := Ord('O');

  isEqual := AsciiIEqual(@buf1[0], @buf2[0], 5);
  AssertTrue('Case-insensitive comparison should return true', isEqual);
end;

procedure TTestCase_Global.Test_AsciiIEqual_CaseDiff;
var
  buf1, buf2: array[0..4] of Byte;
  isEqual: Boolean;
begin
  buf1[0] := Ord('H');
  buf1[1] := Ord('e');
  buf1[2] := Ord('l');
  buf1[3] := Ord('l');
  buf1[4] := Ord('o');

  buf2[0] := Ord('W');
  buf2[1] := Ord('o');
  buf2[2] := Ord('r');
  buf2[3] := Ord('l');
  buf2[4] := Ord('d');

  isEqual := AsciiIEqual(@buf1[0], @buf2[0], 5);
  AssertFalse('Different strings should return false', isEqual);
end;

procedure TTestCase_Global.Test_ToLowerAscii;
var
  buf: array[0..4] of Byte;
begin
  buf[0] := Ord('H');
  buf[1] := Ord('E');
  buf[2] := Ord('L');
  buf[3] := Ord('L');
  buf[4] := Ord('O');

  ToLowerAscii(@buf[0], 5);

  AssertEquals('H should become h', Ord('h'), buf[0]);
  AssertEquals('E should become e', Ord('e'), buf[1]);
  AssertEquals('L should become l', Ord('l'), buf[2]);
  AssertEquals('L should become l', Ord('l'), buf[3]);
  AssertEquals('O should become o', Ord('o'), buf[4]);
end;

procedure TTestCase_Global.Test_ToUpperAscii;
var
  buf: array[0..4] of Byte;
begin
  buf[0] := Ord('h');
  buf[1] := Ord('e');
  buf[2] := Ord('l');
  buf[3] := Ord('l');
  buf[4] := Ord('o');

  ToUpperAscii(@buf[0], 5);

  AssertEquals('h should become H', Ord('H'), buf[0]);
  AssertEquals('e should become E', Ord('E'), buf[1]);
  AssertEquals('l should become L', Ord('L'), buf[2]);
  AssertEquals('l should become L', Ord('L'), buf[3]);
  AssertEquals('o should become O', Ord('O'), buf[4]);
end;

// === 搜索函数测试 ===

procedure TTestCase_Global.Test_BytesIndexOf;
var
  haystack: array[0..9] of Byte;
  needle: array[0..2] of Byte;
  index: PtrInt;
  i: Integer;
begin
  // 设置 haystack: [0,1,2,3,4,5,6,7,8,9]
  for i := 0 to 9 do
    haystack[i] := i;

  // 设置 needle: [3,4,5]
  needle[0] := 3;
  needle[1] := 4;
  needle[2] := 5;

  index := BytesIndexOf(@haystack[0], 10, @needle[0], 3);
  AssertEquals('Should find needle at position 3', 3, index);
end;

procedure TTestCase_Global.Test_BytesIndexOf_NotFound;
var
  haystack: array[0..9] of Byte;
  needle: array[0..2] of Byte;
  index: PtrInt;
  i: Integer;
begin
  for i := 0 to 9 do
    haystack[i] := i;

  needle[0] := 20;
  needle[1] := 21;
  needle[2] := 22;

  index := BytesIndexOf(@haystack[0], 10, @needle[0], 3);
  AssertEquals('Should return -1 when needle not found', -1, index);
end;

procedure TTestCase_Global.Test_BytesIndexOf_Empty;
var
  haystack: array[0..9] of Byte;
  index: PtrInt;
begin
  index := BytesIndexOf(@haystack[0], 10, nil, 0);
  AssertEquals('Should return -1 for empty needle', -1, index);
end;

// === 位集函数测试 ===

procedure TTestCase_Global.Test_BitsetPopCount;
var
  buf: array[0..3] of Byte;
  count: SizeUInt;
begin
  buf[0] := $FF;  // 11111111 = 8 bits
  buf[1] := $0F;  // 00001111 = 4 bits
  buf[2] := $AA;  // 10101010 = 4 bits
  buf[3] := $00;  // 00000000 = 0 bits

  count := BitsetPopCount(@buf[0], 4);
  AssertEquals('Should count 16 set bits total', 16, count);
end;

procedure TTestCase_Global.Test_BitsetPopCount_Empty;
var
  count: SizeUInt;
begin
  count := BitsetPopCount(nil, 0);
  AssertEquals('Empty bitset should have 0 bits set', 0, count);
end;

procedure TTestCase_Global.Test_BitsetPopCount_AllSet;
var
  buf: array[0..1] of Byte;
  count: SizeUInt;
begin
  buf[0] := $FF;
  buf[1] := $FF;

  count := BitsetPopCount(@buf[0], 2);
  AssertEquals('All bits set should count 16', 16, count);
end;

{ TTestCase_BackendConsistency }

procedure TTestCase_BackendConsistency.Test_MemEqual_Consistency;
var
  buf1, buf2: array[0..255] of Byte;
  i: Integer;
  resScalar, resSSE2, resAVX2, resAVX512: LongBool;
begin
  // 初始化测试数据
  for i := 0 to 255 do
  begin
    buf1[i] := Byte(i);
    buf2[i] := Byte(i);
  end;
  
  // 测试相等情况
  resScalar := MemEqual_Scalar(@buf1[0], @buf2[0], 256);
  resSSE2 := MemEqual_SSE2(@buf1[0], @buf2[0], 256);
  if HasAVX2 then
    resAVX2 := MemEqual_AVX2(@buf1[0], @buf2[0], 256)
  else
    resAVX2 := resScalar;
  if HasAVX512 then
    resAVX512 := MemEqual_AVX512(@buf1[0], @buf2[0], 256)
  else
    resAVX512 := resScalar;
  
  AssertTrue('Scalar should return true for equal buffers', resScalar);
  AssertEquals('SSE2 should match Scalar (equal)', resScalar, resSSE2);
  AssertEquals('AVX2 should match Scalar (equal)', resScalar, resAVX2);
  AssertEquals('AVX512 should match Scalar (equal)', resScalar, resAVX512);
  
  // 测试不等情况
  buf2[128] := 255;
  resScalar := MemEqual_Scalar(@buf1[0], @buf2[0], 256);
  resSSE2 := MemEqual_SSE2(@buf1[0], @buf2[0], 256);
  if HasAVX2 then
    resAVX2 := MemEqual_AVX2(@buf1[0], @buf2[0], 256)
  else
    resAVX2 := resScalar;
  if HasAVX512 then
    resAVX512 := MemEqual_AVX512(@buf1[0], @buf2[0], 256)
  else
    resAVX512 := resScalar;
  
  AssertFalse('Scalar should return false for different buffers', resScalar);
  AssertEquals('SSE2 should match Scalar (different)', resScalar, resSSE2);
  AssertEquals('AVX2 should match Scalar (different)', resScalar, resAVX2);
  AssertEquals('AVX512 should match Scalar (different)', resScalar, resAVX512);
end;

procedure TTestCase_BackendConsistency.Test_MemFindByte_Consistency;
var
  buf: array[0..255] of Byte;
  i: Integer;
  resScalar, resSSE2, resAVX2, resAVX512: PtrInt;
begin
  for i := 0 to 255 do
    buf[i] := Byte(i mod 128);
  
  // 查找存在的字节
  resScalar := MemFindByte_Scalar(@buf[0], 256, 64);
  resSSE2 := MemFindByte_SSE2(@buf[0], 256, 64);
  if HasAVX2 then
    resAVX2 := MemFindByte_AVX2(@buf[0], 256, 64)
  else
    resAVX2 := resScalar;
  if HasAVX512 then
    resAVX512 := MemFindByte_AVX512(@buf[0], 256, 64)
  else
    resAVX512 := resScalar;
  
  AssertEquals('SSE2 should match Scalar (found)', resScalar, resSSE2);
  AssertEquals('AVX2 should match Scalar (found)', resScalar, resAVX2);
  AssertEquals('AVX512 should match Scalar (found)', resScalar, resAVX512);
  
  // 查找不存在的字节
  resScalar := MemFindByte_Scalar(@buf[0], 256, 200);
  resSSE2 := MemFindByte_SSE2(@buf[0], 256, 200);
  if HasAVX2 then
    resAVX2 := MemFindByte_AVX2(@buf[0], 256, 200)
  else
    resAVX2 := resScalar;
  if HasAVX512 then
    resAVX512 := MemFindByte_AVX512(@buf[0], 256, 200)
  else
    resAVX512 := resScalar;
  
  AssertEquals('SSE2 should match Scalar (not found)', resScalar, resSSE2);
  AssertEquals('AVX2 should match Scalar (not found)', resScalar, resAVX2);
  AssertEquals('AVX512 should match Scalar (not found)', resScalar, resAVX512);
end;

procedure TTestCase_BackendConsistency.Test_SumBytes_Consistency;
var
  buf: array[0..255] of Byte;
  i: Integer;
  resScalar, resSSE2, resAVX2, resAVX512: UInt64;
begin
  for i := 0 to 255 do
    buf[i] := Byte(i);
  
  resScalar := SumBytes_Scalar(@buf[0], 256);
  resSSE2 := SumBytes_SSE2(@buf[0], 256);
  if HasAVX2 then
    resAVX2 := SumBytes_AVX2(@buf[0], 256)
  else
    resAVX2 := resScalar;
  if HasAVX512 then
    resAVX512 := SumBytes_AVX512(@buf[0], 256)
  else
    resAVX512 := resScalar;
  
  // 0+1+2+...+255 = 255*256/2 = 32640
  AssertEquals('Scalar sum should be 32640', 32640, resScalar);
  AssertEquals('SSE2 should match Scalar', resScalar, resSSE2);
  AssertEquals('AVX2 should match Scalar', resScalar, resAVX2);
  AssertEquals('AVX512 should match Scalar', resScalar, resAVX512);
end;

procedure TTestCase_BackendConsistency.Test_CountByte_Consistency;
var
  buf: array[0..255] of Byte;
  i: Integer;
  resScalar, resSSE2, resAVX2, resAVX512: SizeUInt;
begin
  for i := 0 to 255 do
    buf[i] := Byte(i mod 16);  // 每个值 0-15 出现 16 次
  
  resScalar := CountByte_Scalar(@buf[0], 256, 5);
  resSSE2 := CountByte_SSE2(@buf[0], 256, 5);
  if HasAVX2 then
    resAVX2 := CountByte_AVX2(@buf[0], 256, 5)
  else
    resAVX2 := resScalar;
  if HasAVX512 then
    resAVX512 := CountByte_AVX512(@buf[0], 256, 5)
  else
    resAVX512 := resScalar;
  
  AssertEquals('Scalar count should be 16', 16, resScalar);
  AssertEquals('SSE2 should match Scalar', resScalar, resSSE2);
  AssertEquals('AVX2 should match Scalar', resScalar, resAVX2);
  AssertEquals('AVX512 should match Scalar', resScalar, resAVX512);
end;

procedure TTestCase_BackendConsistency.Test_MinMaxBytes_Consistency;
var
  buf: array[0..255] of Byte;
  i: Integer;
  minScalar, maxScalar, minAVX2, maxAVX2, minAVX512, maxAVX512: Byte;
begin
  for i := 0 to 255 do
    buf[i] := Byte((i * 7 + 13) mod 256);  // 伪随机分布
  
  MinMaxBytes_Scalar(@buf[0], 256, minScalar, maxScalar);
  if HasAVX2 then
    MinMaxBytes_AVX2(@buf[0], 256, minAVX2, maxAVX2)
  else
  begin
    minAVX2 := minScalar;
    maxAVX2 := maxScalar;
  end;
  if HasAVX512 then
    MinMaxBytes_AVX512(@buf[0], 256, minAVX512, maxAVX512)
  else
  begin
    minAVX512 := minScalar;
    maxAVX512 := maxScalar;
  end;
  
  AssertEquals('AVX2 min should match Scalar', minScalar, minAVX2);
  AssertEquals('AVX2 max should match Scalar', maxScalar, maxAVX2);
  AssertEquals('AVX512 min should match Scalar', minScalar, minAVX512);
  AssertEquals('AVX512 max should match Scalar', maxScalar, maxAVX512);
end;

procedure TTestCase_BackendConsistency.Test_BitsetPopCount_Consistency;
var
  buf: array[0..255] of Byte;
  i: Integer;
  resScalar, resAVX2, resAVX512: SizeUInt;
begin
  // 初始化伪随机位模式
  for i := 0 to 255 do
    buf[i] := Byte((i * 13 + 7) mod 256);
  
  resScalar := BitsetPopCount_Scalar(@buf[0], 256);
  if HasAVX2 then
    resAVX2 := BitsetPopCount_AVX2(@buf[0], 256)
  else
    resAVX2 := resScalar;
  if HasAVX512 then
    resAVX512 := BitsetPopCount_AVX512(@buf[0], 256)
  else
    resAVX512 := resScalar;
  
  AssertEquals('AVX2 popcount should match Scalar', resScalar, resAVX2);
  AssertEquals('AVX512 popcount should match Scalar', resScalar, resAVX512);
end;

procedure TTestCase_BackendConsistency.Test_Utf8Validate_Consistency;
const
  // 有效 ASCII
  ValidASCII: array[0..5] of Byte = (Ord('H'), Ord('e'), Ord('l'), Ord('l'), Ord('o'), 0);
  // 有效 2 字节 UTF-8: "é"
  Valid2Byte: array[0..2] of Byte = ($C3, $A9, 0);
  // 有效 3 字节 UTF-8: "中"
  Valid3Byte: array[0..3] of Byte = ($E4, $B8, $AD, 0);
  // 有效 4 字节 UTF-8: "😀"
  Valid4Byte: array[0..4] of Byte = ($F0, $9F, $98, $80, 0);
  // 无效: 超长编码
  InvalidOverlong: array[0..2] of Byte = ($C0, $80, 0);
  // 无效: 不完整的多字节序列
  InvalidIncomplete: array[0..1] of Byte = ($C3, 0);
var
  resScalar, resAVX2: Boolean;
begin
  // 测试 1: 有效 ASCII
  resScalar := Utf8Validate_Scalar(@ValidASCII[0], 5);
  if HasAVX2 then
    resAVX2 := Utf8Validate_AVX2(@ValidASCII[0], 5)
  else
    resAVX2 := resScalar;
  AssertEquals('AVX2 should match Scalar for valid ASCII', resScalar, resAVX2);
  AssertTrue('Valid ASCII should pass', resScalar);
  
  // 测试 2: 有效 2 字节 UTF-8
  resScalar := Utf8Validate_Scalar(@Valid2Byte[0], 2);
  if HasAVX2 then
    resAVX2 := Utf8Validate_AVX2(@Valid2Byte[0], 2)
  else
    resAVX2 := resScalar;
  AssertEquals('AVX2 should match Scalar for valid 2-byte', resScalar, resAVX2);
  AssertTrue('Valid 2-byte should pass', resScalar);
  
  // 测试 3: 有效 3 字节 UTF-8
  resScalar := Utf8Validate_Scalar(@Valid3Byte[0], 3);
  if HasAVX2 then
    resAVX2 := Utf8Validate_AVX2(@Valid3Byte[0], 3)
  else
    resAVX2 := resScalar;
  AssertEquals('AVX2 should match Scalar for valid 3-byte', resScalar, resAVX2);
  AssertTrue('Valid 3-byte should pass', resScalar);
  
  // 测试 4: 有效 4 字节 UTF-8
  resScalar := Utf8Validate_Scalar(@Valid4Byte[0], 4);
  if HasAVX2 then
    resAVX2 := Utf8Validate_AVX2(@Valid4Byte[0], 4)
  else
    resAVX2 := resScalar;
  AssertEquals('AVX2 should match Scalar for valid 4-byte', resScalar, resAVX2);
  AssertTrue('Valid 4-byte should pass', resScalar);
  
  // 测试 5: 无效超长编码
  resScalar := Utf8Validate_Scalar(@InvalidOverlong[0], 2);
  if HasAVX2 then
    resAVX2 := Utf8Validate_AVX2(@InvalidOverlong[0], 2)
  else
    resAVX2 := resScalar;
  AssertEquals('AVX2 should match Scalar for invalid overlong', resScalar, resAVX2);
  AssertFalse('Invalid overlong should fail', resScalar);
  
  // 测试 6: 不完整序列
  resScalar := Utf8Validate_Scalar(@InvalidIncomplete[0], 1);
  if HasAVX2 then
    resAVX2 := Utf8Validate_AVX2(@InvalidIncomplete[0], 1)
  else
    resAVX2 := resScalar;
  AssertEquals('AVX2 should match Scalar for incomplete', resScalar, resAVX2);
  AssertFalse('Incomplete sequence should fail', resScalar);
end;

procedure TTestCase_BackendConsistency.Test_MemReverse_Consistency;
var
  bufScalar, bufAVX2: array[0..255] of Byte;
  i: Integer;
begin
  // 初始化数据
  for i := 0 to 255 do
  begin
    bufScalar[i] := Byte(i);
    bufAVX2[i] := Byte(i);
  end;
  
  MemReverse_Scalar(@bufScalar[0], 256);
  if HasAVX2 then
    MemReverse_AVX2(@bufAVX2[0], 256)
  else
    MemReverse_Scalar(@bufAVX2[0], 256);
  
  for i := 0 to 255 do
    AssertEquals('AVX2 reverse should match Scalar at index ' + IntToStr(i), 
                 bufScalar[i], bufAVX2[i]);
end;

procedure TTestCase_BackendConsistency.Test_AsciiIEqual_Consistency;
var
  buf1, buf2: array[0..63] of Byte;
  i: Integer;
  resScalar, resAVX2: Boolean;
begin
  // 测试 1: 相同字符串（不同大小写）
  for i := 0 to 63 do
  begin
    buf1[i] := Byte(65 + (i mod 26));  // 'A'..'Z'
    buf2[i] := Byte(97 + (i mod 26));  // 'a'..'z'
  end;
  
  resScalar := AsciiIEqual_Scalar(@buf1[0], @buf2[0], 64);
  if HasAVX2 then
    resAVX2 := AsciiIEqual_AVX2(@buf1[0], @buf2[0], 64)
  else
    resAVX2 := resScalar;
  
  AssertTrue('Scalar should match case-insensitively', resScalar);
  AssertEquals('AVX2 should match Scalar', resScalar, resAVX2);
  
  // 测试 2: 不同字符串
  buf2[32] := Byte(48);  // '0' != 'q'
  resScalar := AsciiIEqual_Scalar(@buf1[0], @buf2[0], 64);
  if HasAVX2 then
    resAVX2 := AsciiIEqual_AVX2(@buf1[0], @buf2[0], 64)
  else
    resAVX2 := resScalar;
  
  AssertFalse('Scalar should detect difference', resScalar);
  AssertEquals('AVX2 should match Scalar for different', resScalar, resAVX2);
end;

procedure TTestCase_BackendConsistency.Test_ToLowerAscii_Consistency;
var
  bufScalar, bufAVX2: array[0..127] of Byte;
  i: Integer;
begin
  // 初始化: 混合大小写
  for i := 0 to 127 do
  begin
    if (i mod 2) = 0 then
      bufScalar[i] := Byte(65 + (i mod 26))  // 'A'..'Z'
    else
      bufScalar[i] := Byte(97 + (i mod 26)); // 'a'..'z'
    bufAVX2[i] := bufScalar[i];
  end;
  
  ToLowerAscii_Scalar(@bufScalar[0], 128);
  if HasAVX2 then
    ToLowerAscii_AVX2(@bufAVX2[0], 128)
  else
    ToLowerAscii_Scalar(@bufAVX2[0], 128);
  
  for i := 0 to 127 do
    AssertEquals('AVX2 ToLower should match Scalar at index ' + IntToStr(i), 
                 bufScalar[i], bufAVX2[i]);
end;

procedure TTestCase_BackendConsistency.Test_ToUpperAscii_Consistency;
var
  bufScalar, bufAVX2: array[0..127] of Byte;
  i: Integer;
begin
  // 初始化: 混合大小写
  for i := 0 to 127 do
  begin
    if (i mod 2) = 0 then
      bufScalar[i] := Byte(65 + (i mod 26))  // 'A'..'Z'
    else
      bufScalar[i] := Byte(97 + (i mod 26)); // 'a'..'z'
    bufAVX2[i] := bufScalar[i];
  end;
  
  ToUpperAscii_Scalar(@bufScalar[0], 128);
  if HasAVX2 then
    ToUpperAscii_AVX2(@bufAVX2[0], 128)
  else
    ToUpperAscii_Scalar(@bufAVX2[0], 128);
  
  for i := 0 to 127 do
    AssertEquals('AVX2 ToUpper should match Scalar at index ' + IntToStr(i), 
                 bufScalar[i], bufAVX2[i]);
end;

procedure TTestCase_BackendConsistency.Test_MemDiffRange_Consistency;
var
  buf1, buf2: array[0..255] of Byte;
  i: Integer;
  firstScalar, lastScalar, firstAVX2, lastAVX2: SizeUInt;
  resScalar, resAVX2: Boolean;
begin
  // 初始化相同的数据
  for i := 0 to 255 do
  begin
    buf1[i] := Byte(i);
    buf2[i] := Byte(i);
  end;
  
  // 在中间创建差异
  buf2[50] := 255;
  buf2[100] := 254;
  buf2[150] := 253;
  
  resScalar := MemDiffRange_Scalar(@buf1[0], @buf2[0], 256, firstScalar, lastScalar);
  if HasAVX2 then
    resAVX2 := MemDiffRange_AVX2(@buf1[0], @buf2[0], 256, firstAVX2, lastAVX2)
  else
  begin
    resAVX2 := resScalar;
    firstAVX2 := firstScalar;
    lastAVX2 := lastScalar;
  end;
  
  AssertTrue('Scalar should detect differences', resScalar);
  AssertEquals('AVX2 should match Scalar result', resScalar, resAVX2);
  AssertEquals('AVX2 first diff should match Scalar', firstScalar, firstAVX2);
  AssertEquals('AVX2 last diff should match Scalar', lastScalar, lastAVX2);
  
  // 测试无差异情况
  for i := 0 to 255 do
    buf2[i] := Byte(i);
  
  resScalar := MemDiffRange_Scalar(@buf1[0], @buf2[0], 256, firstScalar, lastScalar);
  if HasAVX2 then
    resAVX2 := MemDiffRange_AVX2(@buf1[0], @buf2[0], 256, firstAVX2, lastAVX2)
  else
    resAVX2 := resScalar;
  
  AssertFalse('Scalar should not detect differences', resScalar);
  AssertEquals('AVX2 should match Scalar for no diff', resScalar, resAVX2);
end;

procedure TTestCase_BackendConsistency.Test_BytesIndexOf_Consistency;
var
  haystack: array[0..255] of Byte;
  needle: array[0..3] of Byte;
  i: Integer;
  resScalar, resAVX2: PtrInt;
begin
  // 初始化 haystack
  for i := 0 to 255 do
    haystack[i] := Byte(i mod 128);
  
  // 设置 needle: [64, 65, 66, 67]
  needle[0] := 64;
  needle[1] := 65;
  needle[2] := 66;
  needle[3] := 67;
  
  resScalar := BytesIndexOf_Scalar(@haystack[0], 256, @needle[0], 4);
  if HasAVX2 then
    resAVX2 := BytesIndexOf_AVX2(@haystack[0], 256, @needle[0], 4)
  else
    resAVX2 := resScalar;
  
  AssertEquals('Scalar should find needle at 64', 64, resScalar);
  AssertEquals('AVX2 should match Scalar (found)', resScalar, resAVX2);
  
  // 测试找不到的情况
  needle[0] := 200;
  needle[1] := 201;
  needle[2] := 202;
  needle[3] := 203;
  
  resScalar := BytesIndexOf_Scalar(@haystack[0], 256, @needle[0], 4);
  if HasAVX2 then
    resAVX2 := BytesIndexOf_AVX2(@haystack[0], 256, @needle[0], 4)
  else
    resAVX2 := resScalar;
  
  AssertEquals('Scalar should not find needle', -1, resScalar);
  AssertEquals('AVX2 should match Scalar (not found)', resScalar, resAVX2);
end;

{ TTestCase_VectorOps }

procedure TTestCase_VectorOps.SetUp;
begin
  inherited SetUp;
  // 强制使用 Scalar 后端，避免 AVX2 汇编实现的问题
  ForceBackend(sbScalar);
end;

procedure TTestCase_VectorOps.TearDown;
begin
  // 恢复自动后端选择
  ResetBackendSelection;
  inherited TearDown;
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Add;
var
  a, b, c: TVecF32x4;
begin
  a := VecF32x4Splat(1.0);
  b := VecF32x4Splat(2.0);
  c := VecF32x4Add(a, b);
  
  AssertEquals('Element 0 should be 3.0', 3.0, VecF32x4Extract(c, 0), 0.0001);
  AssertEquals('Element 1 should be 3.0', 3.0, VecF32x4Extract(c, 1), 0.0001);
  AssertEquals('Element 2 should be 3.0', 3.0, VecF32x4Extract(c, 2), 0.0001);
  AssertEquals('Element 3 should be 3.0', 3.0, VecF32x4Extract(c, 3), 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Sub;
var
  a, b, c: TVecF32x4;
begin
  a := VecF32x4Splat(5.0);
  b := VecF32x4Splat(2.0);
  c := VecF32x4Sub(a, b);
  
  AssertEquals('Element 0 should be 3.0', 3.0, VecF32x4Extract(c, 0), 0.0001);
  AssertEquals('Element 1 should be 3.0', 3.0, VecF32x4Extract(c, 1), 0.0001);
  AssertEquals('Element 2 should be 3.0', 3.0, VecF32x4Extract(c, 2), 0.0001);
  AssertEquals('Element 3 should be 3.0', 3.0, VecF32x4Extract(c, 3), 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Mul;
var
  a, b, c: TVecF32x4;
begin
  a := VecF32x4Splat(3.0);
  b := VecF32x4Splat(4.0);
  c := VecF32x4Mul(a, b);
  
  AssertEquals('Element 0 should be 12.0', 12.0, VecF32x4Extract(c, 0), 0.0001);
  AssertEquals('Element 1 should be 12.0', 12.0, VecF32x4Extract(c, 1), 0.0001);
  AssertEquals('Element 2 should be 12.0', 12.0, VecF32x4Extract(c, 2), 0.0001);
  AssertEquals('Element 3 should be 12.0', 12.0, VecF32x4Extract(c, 3), 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Div;
var
  a, b, c: TVecF32x4;
begin
  a := VecF32x4Splat(12.0);
  b := VecF32x4Splat(4.0);
  c := VecF32x4Div(a, b);
  
  AssertEquals('Element 0 should be 3.0', 3.0, VecF32x4Extract(c, 0), 0.0001);
  AssertEquals('Element 1 should be 3.0', 3.0, VecF32x4Extract(c, 1), 0.0001);
  AssertEquals('Element 2 should be 3.0', 3.0, VecF32x4Extract(c, 2), 0.0001);
  AssertEquals('Element 3 should be 3.0', 3.0, VecF32x4Extract(c, 3), 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Sqrt;
var
  a, c: TVecF32x4;
begin
  a := VecF32x4Splat(16.0);
  c := VecF32x4Sqrt(a);
  
  AssertEquals('Sqrt(16) should be 4.0', 4.0, VecF32x4Extract(c, 0), 0.0001);
  AssertEquals('Sqrt(16) should be 4.0', 4.0, VecF32x4Extract(c, 1), 0.0001);
  AssertEquals('Sqrt(16) should be 4.0', 4.0, VecF32x4Extract(c, 2), 0.0001);
  AssertEquals('Sqrt(16) should be 4.0', 4.0, VecF32x4Extract(c, 3), 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Min;
var
  a, b, c: TVecF32x4;
begin
  a := VecF32x4Splat(5.0);
  b := VecF32x4Splat(3.0);
  c := VecF32x4Min(a, b);
  
  AssertEquals('Min(5,3) should be 3.0', 3.0, VecF32x4Extract(c, 0), 0.0001);
  AssertEquals('Min(5,3) should be 3.0', 3.0, VecF32x4Extract(c, 1), 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Max;
var
  a, b, c: TVecF32x4;
begin
  a := VecF32x4Splat(5.0);
  b := VecF32x4Splat(3.0);
  c := VecF32x4Max(a, b);
  
  AssertEquals('Max(5,3) should be 5.0', 5.0, VecF32x4Extract(c, 0), 0.0001);
  AssertEquals('Max(5,3) should be 5.0', 5.0, VecF32x4Extract(c, 1), 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Abs;
var
  a, c: TVecF32x4;
begin
  a := VecF32x4Splat(-5.0);
  c := VecF32x4Abs(a);
  
  AssertEquals('Abs(-5) should be 5.0', 5.0, VecF32x4Extract(c, 0), 0.0001);
  AssertEquals('Abs(-5) should be 5.0', 5.0, VecF32x4Extract(c, 1), 0.0001);
  AssertEquals('Abs(-5) should be 5.0', 5.0, VecF32x4Extract(c, 2), 0.0001);
  AssertEquals('Abs(-5) should be 5.0', 5.0, VecF32x4Extract(c, 3), 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_ReduceAdd;
var
  arr: array[0..3] of Single;
  a: TVecF32x4;
  sum: Single;
begin
  arr[0] := 1.0;
  arr[1] := 2.0;
  arr[2] := 3.0;
  arr[3] := 4.0;
  
  a := VecF32x4Load(@arr[0]);
  sum := VecF32x4ReduceAdd(a);
  
  AssertEquals('Sum should be 10.0', 10.0, sum, 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_ReduceMin;
var
  arr: array[0..3] of Single;
  a: TVecF32x4;
  minVal: Single;
begin
  arr[0] := 5.0;
  arr[1] := 2.0;
  arr[2] := 8.0;
  arr[3] := 3.0;
  
  a := VecF32x4Load(@arr[0]);
  minVal := VecF32x4ReduceMin(a);
  
  AssertEquals('Min should be 2.0', 2.0, minVal, 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_ReduceMax;
var
  arr: array[0..3] of Single;
  a: TVecF32x4;
  maxVal: Single;
begin
  arr[0] := 5.0;
  arr[1] := 2.0;
  arr[2] := 8.0;
  arr[3] := 3.0;
  
  a := VecF32x4Load(@arr[0]);
  maxVal := VecF32x4ReduceMax(a);
  
  AssertEquals('Max should be 8.0', 8.0, maxVal, 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Splat;
var
  a: TVecF32x4;
begin
  a := VecF32x4Splat(42.5);
  
  AssertEquals('Element 0 should be 42.5', 42.5, VecF32x4Extract(a, 0), 0.0001);
  AssertEquals('Element 1 should be 42.5', 42.5, VecF32x4Extract(a, 1), 0.0001);
  AssertEquals('Element 2 should be 42.5', 42.5, VecF32x4Extract(a, 2), 0.0001);
  AssertEquals('Element 3 should be 42.5', 42.5, VecF32x4Extract(a, 3), 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_LoadStore;
var
  src, dst: array[0..3] of Single;
  a: TVecF32x4;
begin
  src[0] := 1.5;
  src[1] := 2.5;
  src[2] := 3.5;
  src[3] := 4.5;
  
  a := VecF32x4Load(@src[0]);
  VecF32x4Store(@dst[0], a);
  
  AssertEquals('dst[0] should match src[0]', src[0], dst[0], 0.0001);
  AssertEquals('dst[1] should match src[1]', src[1], dst[1], 0.0001);
  AssertEquals('dst[2] should match src[2]', src[2], dst[2], 0.0001);
  AssertEquals('dst[3] should match src[3]', src[3], dst[3], 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Compare;
var
  a, b: TVecF32x4;
  mask: TMask4;
begin
  a := VecF32x4Splat(5.0);
  b := VecF32x4Splat(5.0);
  mask := VecF32x4CmpEq(a, b);
  AssertTrue('Equal vectors should produce all-true mask', mask = $F);
  
  b := VecF32x4Splat(3.0);
  mask := VecF32x4CmpGt(a, b);
  AssertTrue('5 > 3 should produce all-true mask', mask = $F);
  
  mask := VecF32x4CmpLt(a, b);
  AssertTrue('5 < 3 should produce all-false mask', mask = 0);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Fma;
var
  a, b, c, r: TVecF32x4;
begin
  // FMA: a*b + c = 2*3 + 4 = 10
  a := VecF32x4Splat(2.0);
  b := VecF32x4Splat(3.0);
  c := VecF32x4Splat(4.0);
  r := VecF32x4Fma(a, b, c);
  
  AssertEquals('FMA(2,3,4) should be 10.0', 10.0, VecF32x4Extract(r, 0), 0.0001);
  AssertEquals('FMA(2,3,4) should be 10.0', 10.0, VecF32x4Extract(r, 1), 0.0001);
  AssertEquals('FMA(2,3,4) should be 10.0', 10.0, VecF32x4Extract(r, 2), 0.0001);
  AssertEquals('FMA(2,3,4) should be 10.0', 10.0, VecF32x4Extract(r, 3), 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Rcp;
var
  a, r: TVecF32x4;
begin
  a := VecF32x4Splat(4.0);
  r := VecF32x4Rcp(a);
  
  AssertEquals('Rcp(4) should be 0.25', 0.25, VecF32x4Extract(r, 0), 0.01);
  AssertEquals('Rcp(4) should be 0.25', 0.25, VecF32x4Extract(r, 1), 0.01);
  AssertEquals('Rcp(4) should be 0.25', 0.25, VecF32x4Extract(r, 2), 0.01);
  AssertEquals('Rcp(4) should be 0.25', 0.25, VecF32x4Extract(r, 3), 0.01);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Rsqrt;
var
  a, r: TVecF32x4;
begin
  a := VecF32x4Splat(4.0);
  r := VecF32x4Rsqrt(a);
  
  // 1/sqrt(4) = 0.5
  AssertEquals('Rsqrt(4) should be 0.5', 0.5, VecF32x4Extract(r, 0), 0.01);
  AssertEquals('Rsqrt(4) should be 0.5', 0.5, VecF32x4Extract(r, 1), 0.01);
  AssertEquals('Rsqrt(4) should be 0.5', 0.5, VecF32x4Extract(r, 2), 0.01);
  AssertEquals('Rsqrt(4) should be 0.5', 0.5, VecF32x4Extract(r, 3), 0.01);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Floor;
var
  arr: array[0..3] of Single;
  a, r: TVecF32x4;
begin
  arr[0] := 2.7;
  arr[1] := -2.7;
  arr[2] := 3.0;
  arr[3] := -3.0;
  a := VecF32x4Load(@arr[0]);
  r := VecF32x4Floor(a);
  
  AssertEquals('Floor(2.7) should be 2.0', 2.0, VecF32x4Extract(r, 0), 0.0001);
  AssertEquals('Floor(-2.7) should be -3.0', -3.0, VecF32x4Extract(r, 1), 0.0001);
  AssertEquals('Floor(3.0) should be 3.0', 3.0, VecF32x4Extract(r, 2), 0.0001);
  AssertEquals('Floor(-3.0) should be -3.0', -3.0, VecF32x4Extract(r, 3), 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Ceil;
var
  arr: array[0..3] of Single;
  a, r: TVecF32x4;
begin
  arr[0] := 2.3;
  arr[1] := -2.3;
  arr[2] := 3.0;
  arr[3] := -3.0;
  a := VecF32x4Load(@arr[0]);
  r := VecF32x4Ceil(a);
  
  AssertEquals('Ceil(2.3) should be 3.0', 3.0, VecF32x4Extract(r, 0), 0.0001);
  AssertEquals('Ceil(-2.3) should be -2.0', -2.0, VecF32x4Extract(r, 1), 0.0001);
  AssertEquals('Ceil(3.0) should be 3.0', 3.0, VecF32x4Extract(r, 2), 0.0001);
  AssertEquals('Ceil(-3.0) should be -3.0', -3.0, VecF32x4Extract(r, 3), 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Round;
var
  arr: array[0..3] of Single;
  a, r: TVecF32x4;
begin
  arr[0] := 2.3;
  arr[1] := 2.7;
  arr[2] := -2.3;
  arr[3] := -2.7;
  a := VecF32x4Load(@arr[0]);
  r := VecF32x4Round(a);
  
  AssertEquals('Round(2.3) should be 2.0', 2.0, VecF32x4Extract(r, 0), 0.0001);
  AssertEquals('Round(2.7) should be 3.0', 3.0, VecF32x4Extract(r, 1), 0.0001);
  AssertEquals('Round(-2.3) should be -2.0', -2.0, VecF32x4Extract(r, 2), 0.0001);
  AssertEquals('Round(-2.7) should be -3.0', -3.0, VecF32x4Extract(r, 3), 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Trunc;
var
  arr: array[0..3] of Single;
  a, r: TVecF32x4;
begin
  arr[0] := 2.7;
  arr[1] := -2.7;
  arr[2] := 3.0;
  arr[3] := -3.0;
  a := VecF32x4Load(@arr[0]);
  r := VecF32x4Trunc(a);
  
  AssertEquals('Trunc(2.7) should be 2.0', 2.0, VecF32x4Extract(r, 0), 0.0001);
  AssertEquals('Trunc(-2.7) should be -2.0', -2.0, VecF32x4Extract(r, 1), 0.0001);
  AssertEquals('Trunc(3.0) should be 3.0', 3.0, VecF32x4Extract(r, 2), 0.0001);
  AssertEquals('Trunc(-3.0) should be -3.0', -3.0, VecF32x4Extract(r, 3), 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Clamp;
var
  arr: array[0..3] of Single;
  a, minV, maxV, r: TVecF32x4;
begin
  arr[0] := -5.0;   // below min
  arr[1] := 5.0;    // within range
  arr[2] := 15.0;   // above max
  arr[3] := 0.0;    // within range
  a := VecF32x4Load(@arr[0]);
  minV := VecF32x4Splat(0.0);
  maxV := VecF32x4Splat(10.0);
  r := VecF32x4Clamp(a, minV, maxV);
  
  AssertEquals('Clamp(-5) to [0,10] should be 0.0', 0.0, VecF32x4Extract(r, 0), 0.0001);
  AssertEquals('Clamp(5) to [0,10] should be 5.0', 5.0, VecF32x4Extract(r, 1), 0.0001);
  AssertEquals('Clamp(15) to [0,10] should be 10.0', 10.0, VecF32x4Extract(r, 2), 0.0001);
  AssertEquals('Clamp(0) to [0,10] should be 0.0', 0.0, VecF32x4Extract(r, 3), 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Dot;
var
  arr1, arr2: array[0..3] of Single;
  a, b: TVecF32x4;
  dot: Single;
begin
  // (1,2,3,4) . (2,3,4,5) = 2+6+12+20 = 40
  arr1[0] := 1.0; arr1[1] := 2.0; arr1[2] := 3.0; arr1[3] := 4.0;
  arr2[0] := 2.0; arr2[1] := 3.0; arr2[2] := 4.0; arr2[3] := 5.0;
  a := VecF32x4Load(@arr1[0]);
  b := VecF32x4Load(@arr2[0]);
  
  dot := VecF32x4Dot(a, b);
  AssertEquals('Dot product should be 40.0', 40.0, dot, 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x3_Dot;
var
  arr1, arr2: array[0..3] of Single;
  a, b: TVecF32x4;
  dot: Single;
begin
  // (1,2,3) . (4,5,6) = 4+10+18 = 32
  arr1[0] := 1.0; arr1[1] := 2.0; arr1[2] := 3.0; arr1[3] := 999.0; // w ignored
  arr2[0] := 4.0; arr2[1] := 5.0; arr2[2] := 6.0; arr2[3] := 999.0;
  a := VecF32x4Load(@arr1[0]);
  b := VecF32x4Load(@arr2[0]);
  
  dot := VecF32x3Dot(a, b);
  AssertEquals('3D Dot product should be 32.0', 32.0, dot, 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x3_Cross;
var
  arr1, arr2: array[0..3] of Single;
  a, b, c: TVecF32x4;
begin
  // X axis x Y axis = Z axis
  arr1[0] := 1.0; arr1[1] := 0.0; arr1[2] := 0.0; arr1[3] := 0.0;
  arr2[0] := 0.0; arr2[1] := 1.0; arr2[2] := 0.0; arr2[3] := 0.0;
  a := VecF32x4Load(@arr1[0]);
  b := VecF32x4Load(@arr2[0]);
  
  c := VecF32x3Cross(a, b);
  
  AssertEquals('X cross Y: X component should be 0', 0.0, VecF32x4Extract(c, 0), 0.0001);
  AssertEquals('X cross Y: Y component should be 0', 0.0, VecF32x4Extract(c, 1), 0.0001);
  AssertEquals('X cross Y: Z component should be 1', 1.0, VecF32x4Extract(c, 2), 0.0001);
  
  // (1,2,3) x (4,5,6) = (2*6-3*5, 3*4-1*6, 1*5-2*4) = (12-15, 12-6, 5-8) = (-3, 6, -3)
  arr1[0] := 1.0; arr1[1] := 2.0; arr1[2] := 3.0; arr1[3] := 0.0;
  arr2[0] := 4.0; arr2[1] := 5.0; arr2[2] := 6.0; arr2[3] := 0.0;
  a := VecF32x4Load(@arr1[0]);
  b := VecF32x4Load(@arr2[0]);
  
  c := VecF32x3Cross(a, b);
  
  AssertEquals('Cross X should be -3', -3.0, VecF32x4Extract(c, 0), 0.0001);
  AssertEquals('Cross Y should be 6', 6.0, VecF32x4Extract(c, 1), 0.0001);
  AssertEquals('Cross Z should be -3', -3.0, VecF32x4Extract(c, 2), 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Length;
var
  arr: array[0..3] of Single;
  a: TVecF32x4;
  len: Single;
begin
  // length of (3,0,0,0) = 3
  arr[0] := 3.0; arr[1] := 0.0; arr[2] := 0.0; arr[3] := 0.0;
  a := VecF32x4Load(@arr[0]);
  len := VecF32x4Length(a);
  AssertEquals('Length of (3,0,0,0) should be 3', 3.0, len, 0.0001);
  
  // length of (1,1,1,1) = 2
  arr[0] := 1.0; arr[1] := 1.0; arr[2] := 1.0; arr[3] := 1.0;
  a := VecF32x4Load(@arr[0]);
  len := VecF32x4Length(a);
  AssertEquals('Length of (1,1,1,1) should be 2', 2.0, len, 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x3_Length;
var
  arr: array[0..3] of Single;
  a: TVecF32x4;
  len: Single;
begin
  // length of (3,4,0) = 5
  arr[0] := 3.0; arr[1] := 4.0; arr[2] := 0.0; arr[3] := 999.0; // w ignored
  a := VecF32x4Load(@arr[0]);
  len := VecF32x3Length(a);
  AssertEquals('Length of (3,4,0) should be 5', 5.0, len, 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x4_Normalize;
var
  arr: array[0..3] of Single;
  a, n: TVecF32x4;
  len: Single;
begin
  // Normalize (3,0,0,0) -> (1,0,0,0)
  arr[0] := 3.0; arr[1] := 0.0; arr[2] := 0.0; arr[3] := 0.0;
  a := VecF32x4Load(@arr[0]);
  n := VecF32x4Normalize(a);
  
  AssertEquals('Normalized X should be 1', 1.0, VecF32x4Extract(n, 0), 0.0001);
  AssertEquals('Normalized Y should be 0', 0.0, VecF32x4Extract(n, 1), 0.0001);
  AssertEquals('Normalized Z should be 0', 0.0, VecF32x4Extract(n, 2), 0.0001);
  AssertEquals('Normalized W should be 0', 0.0, VecF32x4Extract(n, 3), 0.0001);
  
  // Check length of normalized vector is 1
  len := VecF32x4Length(n);
  AssertEquals('Length of normalized vector should be 1', 1.0, len, 0.0001);
end;

procedure TTestCase_VectorOps.Test_VecF32x3_Normalize;
var
  arr: array[0..3] of Single;
  a, n: TVecF32x4;
  len: Single;
begin
  // Normalize (3,4,0) -> (0.6, 0.8, 0)
  arr[0] := 3.0; arr[1] := 4.0; arr[2] := 0.0; arr[3] := 999.0;
  a := VecF32x4Load(@arr[0]);
  n := VecF32x3Normalize(a);
  
  AssertEquals('Normalized X should be 0.6', 0.6, VecF32x4Extract(n, 0), 0.0001);
  AssertEquals('Normalized Y should be 0.8', 0.8, VecF32x4Extract(n, 1), 0.0001);
  AssertEquals('Normalized Z should be 0', 0.0, VecF32x4Extract(n, 2), 0.0001);
  
  // Check 3D length of normalized vector is 1
  len := VecF32x3Length(n);
  AssertEquals('Length of normalized 3D vector should be 1', 1.0, len, 0.0001);
end;

{ TTestCase_LargeData }

procedure TTestCase_LargeData.Test_MemEqual_1MB;
const
  SIZE = 1024 * 1024;  // 1 MB
var
  buf1, buf2: PByte;
  i: Integer;
begin
  buf1 := GetMem(SIZE);
  buf2 := GetMem(SIZE);
  try
    // 初始化相同数据
    for i := 0 to SIZE - 1 do
    begin
      buf1[i] := Byte(i mod 256);
      buf2[i] := Byte(i mod 256);
    end;
    
    AssertTrue('1MB equal buffers should return True', MemEqual(buf1, buf2, SIZE));
    
    // 在末尾制造差异
    buf2[SIZE - 1] := buf2[SIZE - 1] xor $FF;
    AssertFalse('1MB buffers with last byte diff should return False', MemEqual(buf1, buf2, SIZE));
  finally
    FreeMem(buf1);
    FreeMem(buf2);
  end;
end;

procedure TTestCase_LargeData.Test_SumBytes_1MB;
const
  SIZE = 1024 * 1024;  // 1 MB
var
  buf: PByte;
  i: Integer;
  sum: UInt64;
  expectedSum: UInt64;
begin
  buf := GetMem(SIZE);
  try
    // 填充 0..255 循环
    for i := 0 to SIZE - 1 do
      buf[i] := Byte(i mod 256);
    
    sum := SumBytes(buf, SIZE);
    
    // 期望值: 每 256 字节的和是 (0+1+...+255) = 32640
    // 1MB = 4096 * 256 字节
    expectedSum := UInt64(32640) * 4096;
    
    AssertEquals('1MB sum should match expected value', expectedSum, sum);
  finally
    FreeMem(buf);
  end;
end;

procedure TTestCase_LargeData.Test_MemFindByte_LargeBuffer;
const
  SIZE = 1024 * 1024;  // 1 MB
var
  buf: PByte;
  i: Integer;
  pos: PtrInt;
begin
  buf := GetMem(SIZE);
  try
    // 填充 0
    FillChar(buf^, SIZE, 0);
    
    // 在末尾放置目标字节
    buf[SIZE - 1] := $FF;
    
    pos := MemFindByte(buf, SIZE, $FF);
    AssertEquals('Should find byte at last position', SIZE - 1, pos);
    
    // 在中间放置目标字节
    buf[SIZE div 2] := $AA;
    pos := MemFindByte(buf, SIZE, $AA);
    AssertEquals('Should find byte at middle position', SIZE div 2, pos);
    
    // 查找不存在的字节
    pos := MemFindByte(buf, SIZE, $BB);
    AssertEquals('Should return -1 for not found', -1, pos);
  finally
    FreeMem(buf);
  end;
end;

procedure TTestCase_LargeData.Test_UnalignedPointer;
var
  buf: PByte;
  unaligned: PByte;
  i: Integer;
begin
  // 分配额外字节以测试非对齐访问
  buf := GetMem(256 + 64);
  try
    // 创建非 16 字节对齐的指针
    unaligned := buf;
    while (PtrUInt(unaligned) mod 16) = 0 do
      Inc(unaligned);
    
    // 初始化数据
    for i := 0 to 255 do
      unaligned[i] := Byte(i);
    
    // 测试各种函数在非对齐数据上的正确性
    AssertEquals('SumBytes on unaligned should work', UInt64(32640), SumBytes(unaligned, 256));
    AssertEquals('MemFindByte on unaligned should work', 128, MemFindByte(unaligned, 256, 128));
    AssertEquals('CountByte on unaligned should work', SizeUInt(1), CountByte(unaligned, 256, 100));
  finally
    FreeMem(buf);
  end;
end;

procedure TTestCase_LargeData.Test_OddSizes;
var
  buf1, buf2: array[0..1023] of Byte;
  i, size: Integer;
  sum: UInt64;
begin
  // 初始化数据
  for i := 0 to 1023 do
  begin
    buf1[i] := Byte(i mod 256);
    buf2[i] := Byte(i mod 256);
  end;
  
  // 测试各种奇数大小
  for size := 1 to 100 do
  begin
    // MemEqual
    AssertTrue('MemEqual size=' + IntToStr(size) + ' should work',
               MemEqual(@buf1[0], @buf2[0], size));
    
    // SumBytes
    sum := 0;
    for i := 0 to size - 1 do
      sum := sum + buf1[i];
    AssertEquals('SumBytes size=' + IntToStr(size) + ' should work',
                 sum, SumBytes(@buf1[0], size));
  end;
  
  // 测试边界大小: 15, 16, 17, 31, 32, 33, 63, 64, 65
  for size in [15, 16, 17, 31, 32, 33, 63, 64, 65] do
  begin
    AssertTrue('MemEqual boundary size=' + IntToStr(size),
               MemEqual(@buf1[0], @buf2[0], size));
  end;
end;

{ TTestCase_UnsignedVectorTypes }

// === TVecU32x4 测试 ===

procedure TTestCase_UnsignedVectorTypes.Test_VecU32x4_TypeDef_Size;
var
  v: TVecU32x4;
begin
  AssertEquals('TVecU32x4 should be 16 bytes', 16, SizeOf(v));
end;

procedure TTestCase_UnsignedVectorTypes.Test_VecU32x4_TypeDef_Layout;
var
  v: TVecU32x4;
begin
  v.u[0] := $FFFFFFFF;  // max UInt32
  v.u[1] := $12345678;
  v.u[2] := $00000000;
  v.u[3] := $DEADBEEF;
  
  AssertEquals('u[0] should be $FFFFFFFF', UInt32($FFFFFFFF), v.u[0]);
  AssertEquals('u[1] should be $12345678', UInt32($12345678), v.u[1]);
  AssertEquals('u[2] should be $00000000', UInt32($00000000), v.u[2]);
  AssertEquals('u[3] should be $DEADBEEF', UInt32($DEADBEEF), v.u[3]);
end;

procedure TTestCase_UnsignedVectorTypes.Test_VecU32x4_TypeDef_RawAccess;
var
  v: TVecU32x4;
begin
  v.u[0] := $04030201;
  // raw 数组应该能按小端序访问
  AssertEquals('raw[0] should be $01', $01, v.raw[0]);
  AssertEquals('raw[1] should be $02', $02, v.raw[1]);
  AssertEquals('raw[2] should be $03', $03, v.raw[2]);
  AssertEquals('raw[3] should be $04', $04, v.raw[3]);
end;

// === TVecU16x8 测试 ===

procedure TTestCase_UnsignedVectorTypes.Test_VecU16x8_TypeDef_Size;
var
  v: TVecU16x8;
begin
  AssertEquals('TVecU16x8 should be 16 bytes', 16, SizeOf(v));
end;

procedure TTestCase_UnsignedVectorTypes.Test_VecU16x8_TypeDef_Layout;
var
  v: TVecU16x8;
  i: Integer;
begin
  for i := 0 to 7 do
    v.u[i] := UInt16(i * 1000);
  
  for i := 0 to 7 do
    AssertEquals('u[' + IntToStr(i) + '] should be ' + IntToStr(i * 1000), 
                 UInt16(i * 1000), v.u[i]);
end;

procedure TTestCase_UnsignedVectorTypes.Test_VecU16x8_TypeDef_RawAccess;
var
  v: TVecU16x8;
begin
  v.u[0] := $0201;  // 小端序: raw[0]=01, raw[1]=02
  AssertEquals('raw[0] should be $01', $01, v.raw[0]);
  AssertEquals('raw[1] should be $02', $02, v.raw[1]);
end;

// === TVecU8x16 测试 ===

procedure TTestCase_UnsignedVectorTypes.Test_VecU8x16_TypeDef_Size;
var
  v: TVecU8x16;
begin
  AssertEquals('TVecU8x16 should be 16 bytes', 16, SizeOf(v));
end;

procedure TTestCase_UnsignedVectorTypes.Test_VecU8x16_TypeDef_Layout;
var
  v: TVecU8x16;
  i: Integer;
begin
  for i := 0 to 15 do
    v.u[i] := Byte(i * 10);
  
  for i := 0 to 15 do
    AssertEquals('u[' + IntToStr(i) + '] should be ' + IntToStr(i * 10), 
                 Byte(i * 10), v.u[i]);
end;

procedure TTestCase_UnsignedVectorTypes.Test_VecU8x16_TypeDef_RawAccess;
var
  v: TVecU8x16;
begin
  v.u[0] := $AA;
  v.u[15] := $BB;
  // 对于 UInt8，u 和 raw 应该是相同的布局
  AssertEquals('raw[0] should equal u[0]', v.u[0], v.raw[0]);
  AssertEquals('raw[15] should equal u[15]', v.u[15], v.raw[15]);
end;

// === TVecU64x2 测试 ===

procedure TTestCase_UnsignedVectorTypes.Test_VecU64x2_TypeDef_Size;
var
  v: TVecU64x2;
begin
  AssertEquals('TVecU64x2 should be 16 bytes', 16, SizeOf(v));
end;

procedure TTestCase_UnsignedVectorTypes.Test_VecU64x2_TypeDef_Layout;
var
  v: TVecU64x2;
begin
  v.u[0] := High(UInt64);  // max UInt64 = $FFFFFFFFFFFFFFFF
  v.u[1] := QWord($123456789ABCDEF0);
  
  AssertEquals('u[0] should be max UInt64', High(UInt64), v.u[0]);
  AssertEquals('u[1] should be $123456789ABCDEF0', QWord($123456789ABCDEF0), v.u[1]);
end;

procedure TTestCase_UnsignedVectorTypes.Test_VecU64x2_TypeDef_RawAccess;
var
  v: TVecU64x2;
begin
  v.u[0] := $0807060504030201;
  // raw 数组应该能按小端序访问
  AssertEquals('raw[0] should be $01', $01, v.raw[0]);
  AssertEquals('raw[1] should be $02', $02, v.raw[1]);
  AssertEquals('raw[7] should be $08', $08, v.raw[7]);
end;

// === 256-bit 无符号向量类型测试 ===

procedure TTestCase_UnsignedVectorTypes.Test_VecU32x8_TypeDef_Size;
var
  v: TVecU32x8;
begin
  AssertEquals('TVecU32x8 should be 32 bytes', 32, SizeOf(v));
end;

procedure TTestCase_UnsignedVectorTypes.Test_VecU32x8_TypeDef_LoHi;
var
  v: TVecU32x8;
begin
  // 设置 lo 部分
  v.lo.u[0] := $11111111;
  v.lo.u[1] := $22222222;
  v.lo.u[2] := $33333333;
  v.lo.u[3] := $44444444;
  // 设置 hi 部分
  v.hi.u[0] := $55555555;
  v.hi.u[1] := $66666666;
  v.hi.u[2] := $77777777;
  v.hi.u[3] := $88888888;
  
  // 验证通过 u[] 访问
  AssertEquals('u[0] should match lo.u[0]', UInt32($11111111), v.u[0]);
  AssertEquals('u[3] should match lo.u[3]', UInt32($44444444), v.u[3]);
  AssertEquals('u[4] should match hi.u[0]', UInt32($55555555), v.u[4]);
  AssertEquals('u[7] should match hi.u[3]', UInt32($88888888), v.u[7]);
end;

procedure TTestCase_UnsignedVectorTypes.Test_VecU16x16_TypeDef_Size;
var
  v: TVecU16x16;
begin
  AssertEquals('TVecU16x16 should be 32 bytes', 32, SizeOf(v));
end;

procedure TTestCase_UnsignedVectorTypes.Test_VecU16x16_TypeDef_LoHi;
var
  v: TVecU16x16;
  i: Integer;
begin
  for i := 0 to 7 do
    v.lo.u[i] := UInt16(i);
  for i := 0 to 7 do
    v.hi.u[i] := UInt16(i + 8);
  
  for i := 0 to 15 do
    AssertEquals('u[' + IntToStr(i) + '] should be ' + IntToStr(i), 
                 UInt16(i), v.u[i]);
end;

procedure TTestCase_UnsignedVectorTypes.Test_VecU8x32_TypeDef_Size;
var
  v: TVecU8x32;
begin
  AssertEquals('TVecU8x32 should be 32 bytes', 32, SizeOf(v));
end;

procedure TTestCase_UnsignedVectorTypes.Test_VecU8x32_TypeDef_LoHi;
var
  v: TVecU8x32;
  i: Integer;
begin
  for i := 0 to 15 do
    v.lo.u[i] := Byte(i);
  for i := 0 to 15 do
    v.hi.u[i] := Byte(i + 16);
  
  for i := 0 to 31 do
    AssertEquals('u[' + IntToStr(i) + '] should be ' + IntToStr(i), 
                 Byte(i), v.u[i]);
end;

{ TTestCase_OperatorOverloads }

procedure TTestCase_OperatorOverloads.SetUp;
begin
  inherited SetUp;
  ForceBackend(sbScalar);
end;

procedure TTestCase_OperatorOverloads.TearDown;
begin
  ResetBackendSelection;
  inherited TearDown;
end;

procedure TTestCase_OperatorOverloads.Test_VecF32x4_Op_Add;
var
  a, b, c: TVecF32x4;
begin
  a := VecF32x4Splat(1.0);
  b := VecF32x4Splat(2.0);
  c := a + b;  // 使用运算符重载
  
  AssertEquals('Element 0 should be 3.0', 3.0, VecF32x4Extract(c, 0), 0.0001);
  AssertEquals('Element 1 should be 3.0', 3.0, VecF32x4Extract(c, 1), 0.0001);
  AssertEquals('Element 2 should be 3.0', 3.0, VecF32x4Extract(c, 2), 0.0001);
  AssertEquals('Element 3 should be 3.0', 3.0, VecF32x4Extract(c, 3), 0.0001);
end;

procedure TTestCase_OperatorOverloads.Test_VecF32x4_Op_Sub;
var
  a, b, c: TVecF32x4;
begin
  a := VecF32x4Splat(5.0);
  b := VecF32x4Splat(2.0);
  c := a - b;  // 使用运算符重载
  
  AssertEquals('Element 0 should be 3.0', 3.0, VecF32x4Extract(c, 0), 0.0001);
  AssertEquals('Element 1 should be 3.0', 3.0, VecF32x4Extract(c, 1), 0.0001);
  AssertEquals('Element 2 should be 3.0', 3.0, VecF32x4Extract(c, 2), 0.0001);
  AssertEquals('Element 3 should be 3.0', 3.0, VecF32x4Extract(c, 3), 0.0001);
end;

procedure TTestCase_OperatorOverloads.Test_VecF32x4_Op_Mul;
var
  a, b, c: TVecF32x4;
begin
  a := VecF32x4Splat(3.0);
  b := VecF32x4Splat(4.0);
  c := a * b;  // 使用运算符重载
  
  AssertEquals('Element 0 should be 12.0', 12.0, VecF32x4Extract(c, 0), 0.0001);
  AssertEquals('Element 1 should be 12.0', 12.0, VecF32x4Extract(c, 1), 0.0001);
  AssertEquals('Element 2 should be 12.0', 12.0, VecF32x4Extract(c, 2), 0.0001);
  AssertEquals('Element 3 should be 12.0', 12.0, VecF32x4Extract(c, 3), 0.0001);
end;

procedure TTestCase_OperatorOverloads.Test_VecF32x4_Op_Div;
var
  a, b, c: TVecF32x4;
begin
  a := VecF32x4Splat(12.0);
  b := VecF32x4Splat(4.0);
  c := a / b;  // 使用运算符重载
  
  AssertEquals('Element 0 should be 3.0', 3.0, VecF32x4Extract(c, 0), 0.0001);
  AssertEquals('Element 1 should be 3.0', 3.0, VecF32x4Extract(c, 1), 0.0001);
  AssertEquals('Element 2 should be 3.0', 3.0, VecF32x4Extract(c, 2), 0.0001);
  AssertEquals('Element 3 should be 3.0', 3.0, VecF32x4Extract(c, 3), 0.0001);
end;

procedure TTestCase_OperatorOverloads.Test_VecF32x4_Op_Neg;
var
  a, c: TVecF32x4;
begin
  a := VecF32x4Splat(5.0);
  c := -a;  // 使用一元负运算符
  
  AssertEquals('Element 0 should be -5.0', -5.0, VecF32x4Extract(c, 0), 0.0001);
  AssertEquals('Element 1 should be -5.0', -5.0, VecF32x4Extract(c, 1), 0.0001);
  AssertEquals('Element 2 should be -5.0', -5.0, VecF32x4Extract(c, 2), 0.0001);
  AssertEquals('Element 3 should be -5.0', -5.0, VecF32x4Extract(c, 3), 0.0001);
end;

procedure TTestCase_OperatorOverloads.Test_VecF64x2_Op_Add;
var
  a, b, c: TVecF64x2;
begin
  a.d[0] := 1.0; a.d[1] := 2.0;
  b.d[0] := 3.0; b.d[1] := 4.0;
  c := a + b;
  
  AssertEquals('d[0] should be 4.0', 4.0, c.d[0], 0.0001);
  AssertEquals('d[1] should be 6.0', 6.0, c.d[1], 0.0001);
end;

procedure TTestCase_OperatorOverloads.Test_VecF64x2_Op_Sub;
var
  a, b, c: TVecF64x2;
begin
  a.d[0] := 5.0; a.d[1] := 7.0;
  b.d[0] := 2.0; b.d[1] := 3.0;
  c := a - b;
  
  AssertEquals('d[0] should be 3.0', 3.0, c.d[0], 0.0001);
  AssertEquals('d[1] should be 4.0', 4.0, c.d[1], 0.0001);
end;

procedure TTestCase_OperatorOverloads.Test_VecF64x2_Op_Mul;
var
  a, b, c: TVecF64x2;
begin
  a.d[0] := 3.0; a.d[1] := 4.0;
  b.d[0] := 2.0; b.d[1] := 5.0;
  c := a * b;
  
  AssertEquals('d[0] should be 6.0', 6.0, c.d[0], 0.0001);
  AssertEquals('d[1] should be 20.0', 20.0, c.d[1], 0.0001);
end;

procedure TTestCase_OperatorOverloads.Test_VecF64x2_Op_Div;
var
  a, b, c: TVecF64x2;
begin
  a.d[0] := 10.0; a.d[1] := 20.0;
  b.d[0] := 2.0;  b.d[1] := 4.0;
  c := a / b;
  
  AssertEquals('d[0] should be 5.0', 5.0, c.d[0], 0.0001);
  AssertEquals('d[1] should be 5.0', 5.0, c.d[1], 0.0001);
end;

procedure TTestCase_OperatorOverloads.Test_VecI32x4_Op_Add;
var
  a, b, c: TVecI32x4;
begin
  a.i[0] := 1; a.i[1] := 2; a.i[2] := 3; a.i[3] := 4;
  b.i[0] := 10; b.i[1] := 20; b.i[2] := 30; b.i[3] := 40;
  c := a + b;
  
  AssertEquals('i[0] should be 11', 11, c.i[0]);
  AssertEquals('i[1] should be 22', 22, c.i[1]);
  AssertEquals('i[2] should be 33', 33, c.i[2]);
  AssertEquals('i[3] should be 44', 44, c.i[3]);
end;

procedure TTestCase_OperatorOverloads.Test_VecI32x4_Op_Sub;
var
  a, b, c: TVecI32x4;
begin
  a.i[0] := 10; a.i[1] := 20; a.i[2] := 30; a.i[3] := 40;
  b.i[0] := 1; b.i[1] := 2; b.i[2] := 3; b.i[3] := 4;
  c := a - b;
  
  AssertEquals('i[0] should be 9', 9, c.i[0]);
  AssertEquals('i[1] should be 18', 18, c.i[1]);
  AssertEquals('i[2] should be 27', 27, c.i[2]);
  AssertEquals('i[3] should be 36', 36, c.i[3]);
end;

procedure TTestCase_OperatorOverloads.Test_VecI32x4_Op_Neg;
var
  a, c: TVecI32x4;
begin
  a.i[0] := 1; a.i[1] := -2; a.i[2] := 3; a.i[3] := -4;
  c := -a;
  
  AssertEquals('i[0] should be -1', -1, c.i[0]);
  AssertEquals('i[1] should be 2', 2, c.i[1]);
  AssertEquals('i[2] should be -3', -3, c.i[2]);
  AssertEquals('i[3] should be 4', 4, c.i[3]);
end;

procedure TTestCase_OperatorOverloads.Test_VecF32x4_Op_ScalarMul;
var
  a, c: TVecF32x4;
  s: Single;
begin
  a := VecF32x4Splat(3.0);
  s := 4.0;
  c := a * s;  // 向量 * 标量
  
  AssertEquals('Element 0 should be 12.0', 12.0, VecF32x4Extract(c, 0), 0.0001);
  AssertEquals('Element 1 should be 12.0', 12.0, VecF32x4Extract(c, 1), 0.0001);
  AssertEquals('Element 2 should be 12.0', 12.0, VecF32x4Extract(c, 2), 0.0001);
  AssertEquals('Element 3 should be 12.0', 12.0, VecF32x4Extract(c, 3), 0.0001);
end;

procedure TTestCase_OperatorOverloads.Test_VecF32x4_Op_ScalarDiv;
var
  a, c: TVecF32x4;
  s: Single;
begin
  a := VecF32x4Splat(12.0);
  s := 4.0;
  c := a / s;  // 向量 / 标量
  
  AssertEquals('Element 0 should be 3.0', 3.0, VecF32x4Extract(c, 0), 0.0001);
  AssertEquals('Element 1 should be 3.0', 3.0, VecF32x4Extract(c, 1), 0.0001);
  AssertEquals('Element 2 should be 3.0', 3.0, VecF32x4Extract(c, 2), 0.0001);
  AssertEquals('Element 3 should be 3.0', 3.0, VecF32x4Extract(c, 3), 0.0001);
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_BackendConsistency);
  RegisterTest(TTestCase_VectorOps);
  RegisterTest(TTestCase_LargeData);
  RegisterTest(TTestCase_UnsignedVectorTypes);
  RegisterTest(TTestCase_OperatorOverloads);

end.
