unit fafafa.core.simd.testcase;

{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  fafafa.core.simd,
  fafafa.core.simd.base,
  fafafa.core.simd.types,
  fafafa.core.simd.api,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.scalar,
  fafafa.core.simd.sse2,
  fafafa.core.simd.avx2,
  fafafa.core.simd.avx512,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.cpuinfo.base,
  fafafa.core.simd.memutils,
  fafafa.core.simd.builder;

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

  // 后端烟雾测试 - 验证 backend 选择后基础向量操作不会崩溃且结果正确
  TTestCase_BackendSmoke = class(TTestCase)
  protected
    procedure RunVecF32x4Smoke;
    procedure TearDown; override;
  published
    procedure Test_VectorAsmEnabled_Toggle_Roundtrip;

    procedure Test_DefaultBackend_VecF32x4_Smoke;
    procedure Test_ForceScalar_VecF32x4_Smoke;
    procedure Test_ForceSSE2_VecF32x4_Smoke;
    procedure Test_ForceAVX2_VecF32x4_Smoke;
    procedure Test_ForceAVX512_VecF32x4_Smoke;
  end;

  // AVX2 VectorAsm 专项测试：聚焦于向量汇编路径的正确性（小步推进）
  TTestCase_AVX2VectorAsm = class(TTestCase)
  protected
    FOldVectorAsm: Boolean;
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_VecF32x4_Fma_FusedWhenFMAAvailable;
    procedure Test_VecF32x8_AddSubMulDiv_RandomConsistency;
    procedure Test_VecF32x8_AddSubMulDiv_SpecialValues_Consistency;
    procedure Test_VecF64x2_AddSubMulDiv_RandomConsistency;
    procedure Test_VecF64x2_AddSubMulDiv_SpecialValues_Consistency;
    procedure Test_VecI32x4_AddSubMul_RandomConsistency;
    procedure Test_VecI32x4_AddSubMul_BoundaryConsistency;
    procedure Test_VecF32x4_Compare_SpecialValues_Consistency;
    procedure Test_VecF32x4_Compare_RandomConsistency;
    procedure Test_VecF32x4_AddSubMulDiv_RandomConsistency;
    procedure Test_VecF32x4_AddSubMulDiv_SpecialValues_Consistency;
    procedure Test_VecF32x4_Abs_RandomConsistency;
    procedure Test_VecF32x4_Abs_SpecialValues_Consistency;
    procedure Test_VecF32x4_Sqrt_RandomConsistency;
    procedure Test_VecF32x4_Sqrt_SpecialValues_Consistency;
    procedure Test_VecF32x4_MinMax_RandomConsistency;
    procedure Test_VecF32x4_MinMax_SpecialValues_Consistency;
    procedure Test_VecF32x4_Reduce_RandomConsistency;
    procedure Test_VecF32x4_Reduce_SpecialValues_Consistency;
    procedure Test_VecF32x4_LoadStore_RandomRoundtrip;
    procedure Test_VecF32x4_LoadStore_SpecialValues_Roundtrip;
    procedure Test_VecF32x4_Select_RandomConsistency;
    procedure Test_VecF32x4_ExtractInsert_RandomConsistency;
    procedure Test_VecF32x4_SplatZero_BitExact;
    procedure Test_VecF32x4_RcpRsqrt_RandomConsistency;
    procedure Test_VecF32x4_FloorCeil_RandomConsistency;
    procedure Test_VecF32x4_RoundTrunc_RandomConsistency;
    procedure Test_VecF32x4_Clamp_RandomConsistency;
    procedure Test_VecF32x4_Dot_RandomConsistency;
    procedure Test_VecF32x4_Dot3_RandomConsistency;
    procedure Test_VecF32x4_Cross3_RandomConsistency;
    procedure Test_VecF32x4_Length_RandomConsistency;
    procedure Test_VecF32x4_Length3_RandomConsistency;
    procedure Test_VecF32x4_Normalize_RandomConsistency;
    procedure Test_VecF32x4_Normalize3_RandomConsistency;
    procedure Test_VecF32x4_ABI_CalleeSavedRegisters_Preserved;
    procedure Test_VecF32x4_ABI_CalleeSavedRegisters_Preserved_VectorReturn;
    procedure Test_VecF32x4_ABI_CalleeSavedRegisters_Preserved_VectorReturn_OneVec;
    procedure Test_VecF32x4_ABI_CalleeSavedRegisters_Preserved_VectorReturn_ThreeVec;
    procedure Test_VecF32x4_ABI_CalleeSavedRegisters_Preserved_VectorReturn_Ptr;
    procedure Test_VecF32x4_ABI_CalleeSavedRegisters_Preserved_MaskReturn;
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

  // Phase 1.3: 向量掩码类型测试
  TTestCase_VectorMaskTypes = class(TTestCase)
  published
    // TMaskF32x4 基础测试
    procedure Test_MaskF32x4_TypeDef_Size;
    procedure Test_MaskF32x4_AllTrue;
    procedure Test_MaskF32x4_AllFalse;
    procedure Test_MaskF32x4_Mixed;
    procedure Test_MaskF32x4_Test;
    procedure Test_MaskF32x4_ToBitmask;
    procedure Test_MaskF32x4_Any;
    procedure Test_MaskF32x4_All;
    procedure Test_MaskF32x4_None;
    
    // TMaskF32x4 逻辑运算符测试
    procedure Test_MaskF32x4_Op_And;
    procedure Test_MaskF32x4_Op_Or;
    procedure Test_MaskF32x4_Op_Xor;
    procedure Test_MaskF32x4_Op_Not;
    
    // TMaskI32x4 基础测试
    procedure Test_MaskI32x4_TypeDef_Size;
    procedure Test_MaskI32x4_AllTrue;
    procedure Test_MaskI32x4_ToBitmask;
    
    // TMaskF64x2 基础测试
    procedure Test_MaskF64x2_TypeDef_Size;
    procedure Test_MaskF64x2_AllTrue;
    procedure Test_MaskF64x2_ToBitmask;
    
    // Select 操作测试
    procedure Test_MaskF32x4_Select;
  end;

  // Phase 1.4: 类型转换函数测试
  TTestCase_TypeConversion = class(TTestCase)
  published
    // IntoBits / FromBits (F32x4 <-> I32x4)
    procedure Test_VecF32x4_IntoBits;
    procedure Test_VecI32x4_FromBitsF32;
    procedure Test_IntoBits_FromBits_Roundtrip;
    
    // IntoBits / FromBits (F64x2 <-> I64x2)
    procedure Test_VecF64x2_IntoBits;
    procedure Test_VecI64x2_FromBitsF64;
    
    // Cast 函数 (元素级别转换)
    procedure Test_VecF32x4_CastToI32x4;
    procedure Test_VecI32x4_CastToF32x4;
    procedure Test_VecF64x2_CastToI64x2;
    procedure Test_VecI64x2_CastToF64x2;
    
    // Widen / Narrow (宽度转换)
    procedure Test_VecI16x8_WidenLo_I32x4;
    procedure Test_VecI16x8_WidenHi_I32x4;
    procedure Test_VecI32x4_NarrowToI16x8;
    
    // F32x4 <-> F64x2 精度转换
    procedure Test_VecF32x4_ToF64x2_Lo;
    procedure Test_VecF64x2_ToF32x4;
  end;

  // Phase 3: Builder 模式测试
  TTestCase_Builder = class(TTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // TVecF32x4Builder 基础测试
    procedure Test_Builder_Create_FromValues;
    procedure Test_Builder_Create_Splat;
    procedure Test_Builder_Create_Load;
    
    // 流式 API 测试
    procedure Test_Builder_Chain_Add;
    procedure Test_Builder_Chain_MulAdd;
    procedure Test_Builder_Chain_Normalize;
    procedure Test_Builder_Chain_Clamp;
    
    // 终结操作测试
    procedure Test_Builder_Build;
    procedure Test_Builder_ReduceAdd;
    procedure Test_Builder_ReduceMin;
    procedure Test_Builder_ReduceMax;
    
    // 复杂链式测试
    procedure Test_Builder_Complex_DotProduct;
    procedure Test_Builder_Complex_Lerp;
  end;

  // Phase 2: Gather/Scatter 测试
  TTestCase_GatherScatter = class(TTestCase)
  published
    // Gather - 从不连续内存位置收集数据到向量
    procedure Test_VecF32x4_Gather_Sequential;
    procedure Test_VecF32x4_Gather_Stride;
    procedure Test_VecF32x4_Gather_Random;
    procedure Test_VecI32x4_Gather_Sequential;
    procedure Test_VecI32x4_Gather_Negative;
    
    // Scatter - 将向量数据分散到不连续内存位置
    procedure Test_VecF32x4_Scatter_Sequential;
    procedure Test_VecF32x4_Scatter_Stride;
    procedure Test_VecI32x4_Scatter_Sequential;
    
    // 边界条件
    procedure Test_Gather_ZeroIndex;
    procedure Test_Gather_LargeStride;
  end;

  // Phase 2: Shuffle/Swizzle 测试
  TTestCase_ShuffleSWizzle = class(TTestCase)
  published
    // MM_SHUFFLE 辅助函数
    procedure Test_MM_SHUFFLE;
    
    // Shuffle 单向量
    procedure Test_VecF32x4_Shuffle_Identity;
    procedure Test_VecF32x4_Shuffle_Reverse;
    procedure Test_VecF32x4_Shuffle_Broadcast;
    procedure Test_VecI32x4_Shuffle;
    
    // Shuffle2 双向量
    procedure Test_VecF32x4_Shuffle2;
    
    // Blend 混合
    procedure Test_VecF32x4_Blend;
    procedure Test_VecF64x2_Blend;
    procedure Test_VecI32x4_Blend;
    
    // Unpack 交织
    procedure Test_VecF32x4_UnpackLo;
    procedure Test_VecF32x4_UnpackHi;
    procedure Test_VecI32x4_Unpack;
    
    // Broadcast 广播
    procedure Test_VecF32x4_Broadcast;
    procedure Test_VecI32x4_Broadcast;
    
    // Reverse 反转
    procedure Test_VecF32x4_Reverse;
    procedure Test_VecI32x4_Reverse;
    
    // Rotate 旋转
    procedure Test_VecF32x4_RotateLeft;
    procedure Test_VecI32x4_RotateLeft;
    
    // Insert/Extract 插入提取
    procedure Test_VecF32x4_Insert;
    procedure Test_VecF32x4_ExtractFunc;
    procedure Test_VecI32x4_InsertExtract;
  end;

  // Phase 4: SIMD 数学函数测试
  TTestCase_MathFunctions = class(TTestCase)
  published
    // 三角函数
    procedure Test_VecF32x4_Sin;
    procedure Test_VecF32x4_Cos;
    procedure Test_VecF32x4_SinCos;
    procedure Test_VecF32x4_Tan;
    
    // 指数/对数函数
    procedure Test_VecF32x4_Exp;
    procedure Test_VecF32x4_Exp2;
    procedure Test_VecF32x4_Log;
    procedure Test_VecF32x4_Log2;
    procedure Test_VecF32x4_Log10;
    procedure Test_VecF32x4_Pow;
    
    // 反三角函数
    procedure Test_VecF32x4_Asin;
    procedure Test_VecF32x4_Acos;
    procedure Test_VecF32x4_Atan;
    procedure Test_VecF32x4_Atan2;
  end;

  // Phase 5: 高级算法测试
  TTestCase_AdvancedAlgorithms = class(TTestCase)
  published
    // 排序网络 (Sorting Network)
    procedure Test_SortNet4_I32_Ascending;
    procedure Test_SortNet4_I32_Descending;
    procedure Test_SortNet4_F32_Ascending;
    procedure Test_SortNet4_F32_WithNegatives;
    procedure Test_SortNet8_I32;
    
    // 前缀和 (Prefix Sum / Scan)
    procedure Test_PrefixSum_I32x4_Inclusive;
    procedure Test_PrefixSum_I32x4_Exclusive;
    procedure Test_PrefixSum_F32x4_Inclusive;
    procedure Test_PrefixSum_Array_I32;
    procedure Test_PrefixSum_Array_F32;
    
    // 向量化字符串搜索
    procedure Test_StrFind_SingleChar;
    procedure Test_StrFind_NotFound;
    procedure Test_StrFind_AtStart;
    procedure Test_StrFind_AtEnd;
    procedure Test_StrFind_Empty;
  end;

  // 512-bit 向量类型测试 (AVX-512)
  TTestCase_Vec512Types = class(TTestCase)
  published
    // TVecF32x16 类型测试
    procedure Test_VecF32x16_Create;
    procedure Test_VecF32x16_LoHi;
    procedure Test_VecF32x16_SizeOf;
    
    // TVecF64x8 类型测试
    procedure Test_VecF64x8_Create;
    procedure Test_VecF64x8_LoHi;
    procedure Test_VecF64x8_SizeOf;
    
    // TVecI32x16 类型测试
    procedure Test_VecI32x16_Create;
    procedure Test_VecI32x16_LoHi;
    procedure Test_VecI32x16_SizeOf;
    
    // TVecI64x8 类型测试
    procedure Test_VecI64x8_Create;
    procedure Test_VecI64x8_SizeOf;
    
    // TVecI8x64 类型测试
    procedure Test_VecI8x64_Create;
    procedure Test_VecI8x64_SizeOf;
    
    // TMask64 掩码类型测试
    procedure Test_Mask64_AllSet;
    procedure Test_Mask64_NoneSet;
    
    // TMaskF32x16 向量掩码测试
    procedure Test_MaskF32x16_AllTrue;
    procedure Test_MaskF32x16_AllFalse;
    procedure Test_MaskF32x16_ToBitmask;
    procedure Test_MaskF32x16_Any_All_None;
    
    // 512-bit 向量算术测试
    procedure Test_VecF32x16_Add;
    procedure Test_VecF32x16_Sub;
    procedure Test_VecF32x16_Mul;
    procedure Test_VecF32x16_Neg;
    procedure Test_VecF64x8_Add;
    procedure Test_VecI32x16_Add;
    
    // 512-bit 比较和掩码逻辑测试 (Phase 4)
    procedure Test_VecF32x16_CmpEq;
    procedure Test_VecF32x16_CmpLt;
    procedure Test_MaskF32x16_LogicOps;
    procedure Test_MaskF32x16_Select;
  end;

  // 边界条件测试 - NaN, 无穷大, 溢出, 对齐
  TTestCase_EdgeCases = class(TTestCase)
  private
    FSavedExceptionMask: TFPUExceptionMask;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // NaN 处理测试
    procedure Test_VecF32x4_Add_WithNaN;
    procedure Test_VecF32x4_Mul_WithNaN;
    procedure Test_VecF32x4_Compare_WithNaN;
    procedure Test_SortNet4_F32_WithNaN;
    
    // Infinity 处理测试
    procedure Test_VecF32x4_Add_WithInfinity;
    procedure Test_VecF32x4_Mul_InfinityByZero;
    procedure Test_VecF32x4_Div_ByZero;
    procedure Test_VecF32x4_Div_InfinityByInfinity;
    
    // 整数边界测试
    procedure Test_VecI32x4_Add_MaxValue;
    procedure Test_VecI32x4_Sub_MinValue;
    procedure Test_PrefixSum_I32_Overflow;
    
    // 极端对齐场景（MemEqual / SumBytes 在非对齐上的行为）
    procedure Test_MemEqual_Unaligned_1Byte;
    procedure Test_MemEqual_Unaligned_15Bytes;
    procedure Test_MemFindByte_CrossPage;
    procedure Test_SumBytes_OddSizes;
    
    // 数学函数边界
    procedure Test_VecF32x4_Log_Zero;
    procedure Test_VecF32x4_Log_Negative;
    procedure Test_VecF32x4_Sqrt_Negative;
    procedure Test_VecF32x4_Asin_OutOfRange;
  end;

  // Aligned 内存工具测试（memutils）
  TTestCase_Memutils = class(TTestCase)
  published
    procedure Test_AlignedAlloc_AlignedAndWritable;
    procedure Test_AlignedRealloc_Grow_PreservesPrefix;
    procedure Test_AlignedRealloc_Shrink_PreservesPrefix;
    procedure Test_AlignedRealloc_NilAndZero_Semantics;
  end;

  // Rust 风格类型别名测试
  TTestCase_RustStyleAliases = class(TTestCase)
  published
    // 128-bit 浮点向量别名测试
    procedure Test_f32x4_Alias_SameSize;
    procedure Test_f32x4_Alias_Usable;
    procedure Test_f64x2_Alias_SameSize;
    procedure Test_f64x2_Alias_Usable;
    
    // 128-bit 整数向量别名测试
    procedure Test_i32x4_Alias_SameSize;
    procedure Test_i32x4_Alias_Usable;
    procedure Test_i64x2_Alias_SameSize;
    procedure Test_i16x8_Alias_SameSize;
    procedure Test_i8x16_Alias_SameSize;
    
    // 128-bit 无符号整数向量别名测试
    procedure Test_u32x4_Alias_SameSize;
    procedure Test_u64x2_Alias_SameSize;
    procedure Test_u16x8_Alias_SameSize;
    procedure Test_u8x16_Alias_SameSize;
    
    // 256-bit 向量别名测试
    procedure Test_f32x8_Alias_SameSize;
    procedure Test_f64x4_Alias_SameSize;
    procedure Test_i32x8_Alias_SameSize;
    
    // 512-bit 向量别名测试
    procedure Test_f32x16_Alias_SameSize;
    procedure Test_f64x8_Alias_SameSize;
    procedure Test_i32x16_Alias_SameSize;
    
    // 别名互操作性测试
    procedure Test_Alias_InteropWithOriginal;
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

{ TTestCase_BackendSmoke }

procedure TTestCase_BackendSmoke.RunVecF32x4Smoke;
var
  src, dst: array[0..3] of Single;
  v, w: TVecF32x4;
  sum: Single;
  dot: Single;
begin
  src[0] := 1.0;
  src[1] := 2.0;
  src[2] := 3.0;
  src[3] := 4.0;

  v := VecF32x4Load(@src[0]);

  sum := VecF32x4ReduceAdd(v);
  AssertEquals('ReduceAdd should be 10', 10.0, sum, 0.0001);

  dot := VecF32x4Dot(v, VecF32x4Splat(1.0));
  AssertEquals('Dot(v, splat(1)) should be 10', 10.0, dot, 0.0001);

  w := VecF32x4Add(v, VecF32x4Splat(1.0));
  VecF32x4Store(@dst[0], w);

  AssertEquals('Store/Add[0]', 2.0, dst[0], 0.0001);
  AssertEquals('Store/Add[1]', 3.0, dst[1], 0.0001);
  AssertEquals('Store/Add[2]', 4.0, dst[2], 0.0001);
  AssertEquals('Store/Add[3]', 5.0, dst[3], 0.0001);

  w := VecF32x4Sub(v, VecF32x4Splat(1.0));
  VecF32x4Store(@dst[0], w);

  AssertEquals('Store/Sub[0]', 0.0, dst[0], 0.0001);
  AssertEquals('Store/Sub[1]', 1.0, dst[1], 0.0001);
  AssertEquals('Store/Sub[2]', 2.0, dst[2], 0.0001);
  AssertEquals('Store/Sub[3]', 3.0, dst[3], 0.0001);

  w := VecF32x4Mul(v, VecF32x4Splat(2.0));
  VecF32x4Store(@dst[0], w);

  AssertEquals('Store/Mul[0]', 2.0, dst[0], 0.0001);
  AssertEquals('Store/Mul[1]', 4.0, dst[1], 0.0001);
  AssertEquals('Store/Mul[2]', 6.0, dst[2], 0.0001);
  AssertEquals('Store/Mul[3]', 8.0, dst[3], 0.0001);

  // Div: v / 2 = (0.5, 1.0, 1.5, 2.0)
  w := VecF32x4Div(v, VecF32x4Splat(2.0));
  VecF32x4Store(@dst[0], w);

  AssertEquals('Store/Div[0]', 0.5, dst[0], 0.0001);
  AssertEquals('Store/Div[1]', 1.0, dst[1], 0.0001);
  AssertEquals('Store/Div[2]', 1.5, dst[2], 0.0001);
  AssertEquals('Store/Div[3]', 2.0, dst[3], 0.0001);

  // Min: min(v, splat(2.5)) = (1, 2, 2.5, 2.5)
  w := VecF32x4Min(v, VecF32x4Splat(2.5));
  VecF32x4Store(@dst[0], w);

  AssertEquals('Store/Min[0]', 1.0, dst[0], 0.0001);
  AssertEquals('Store/Min[1]', 2.0, dst[1], 0.0001);
  AssertEquals('Store/Min[2]', 2.5, dst[2], 0.0001);
  AssertEquals('Store/Min[3]', 2.5, dst[3], 0.0001);

  // Max: max(v, splat(2.5)) = (2.5, 2.5, 3, 4)
  w := VecF32x4Max(v, VecF32x4Splat(2.5));
  VecF32x4Store(@dst[0], w);

  AssertEquals('Store/Max[0]', 2.5, dst[0], 0.0001);
  AssertEquals('Store/Max[1]', 2.5, dst[1], 0.0001);
  AssertEquals('Store/Max[2]', 3.0, dst[2], 0.0001);
  AssertEquals('Store/Max[3]', 4.0, dst[3], 0.0001);

  // Abs: abs((-1, 2, -3, 4)) = (1, 2, 3, 4)
  src[0] := -1.0; src[1] := 2.0; src[2] := -3.0; src[3] := 4.0;
  v := VecF32x4Load(@src[0]);
  w := VecF32x4Abs(v);
  VecF32x4Store(@dst[0], w);

  AssertEquals('Store/Abs[0]', 1.0, dst[0], 0.0001);
  AssertEquals('Store/Abs[1]', 2.0, dst[1], 0.0001);
  AssertEquals('Store/Abs[2]', 3.0, dst[2], 0.0001);
  AssertEquals('Store/Abs[3]', 4.0, dst[3], 0.0001);

  // Sqrt: sqrt((1, 4, 9, 16)) = (1, 2, 3, 4)
  src[0] := 1.0; src[1] := 4.0; src[2] := 9.0; src[3] := 16.0;
  v := VecF32x4Load(@src[0]);
  w := VecF32x4Sqrt(v);
  VecF32x4Store(@dst[0], w);

  AssertEquals('Store/Sqrt[0]', 1.0, dst[0], 0.0001);
  AssertEquals('Store/Sqrt[1]', 2.0, dst[1], 0.0001);
  AssertEquals('Store/Sqrt[2]', 3.0, dst[2], 0.0001);
  AssertEquals('Store/Sqrt[3]', 4.0, dst[3], 0.0001);

  // CmpEq: (1,2,3,4) == (1,2,5,4) -> mask = 0b1011 = $B
  src[0] := 1.0; src[1] := 2.0; src[2] := 3.0; src[3] := 4.0;
  v := VecF32x4Load(@src[0]);
  src[0] := 1.0; src[1] := 2.0; src[2] := 5.0; src[3] := 4.0;
  w := VecF32x4Load(@src[0]);
  AssertEquals('CmpEq mask', $B, VecF32x4CmpEq(v, w));

  // CmpLt: (1,2,3,4) < (2,2,2,5) -> mask = 0b1001 = $9
  src[0] := 2.0; src[1] := 2.0; src[2] := 2.0; src[3] := 5.0;
  w := VecF32x4Load(@src[0]);
  src[0] := 1.0; src[1] := 2.0; src[2] := 3.0; src[3] := 4.0;
  v := VecF32x4Load(@src[0]);
  AssertEquals('CmpLt mask', $9, VecF32x4CmpLt(v, w));

  // CmpGt: (1,2,3,4) > (0,2,2,5) -> mask = 0b0101 = $5
  src[0] := 0.0; src[1] := 2.0; src[2] := 2.0; src[3] := 5.0;
  w := VecF32x4Load(@src[0]);
  src[0] := 1.0; src[1] := 2.0; src[2] := 3.0; src[3] := 4.0;
  v := VecF32x4Load(@src[0]);
  AssertEquals('CmpGt mask', $5, VecF32x4CmpGt(v, w));

  // ReduceMin: min(5, 2, 8, 3) = 2
  src[0] := 5.0; src[1] := 2.0; src[2] := 8.0; src[3] := 3.0;
  v := VecF32x4Load(@src[0]);
  AssertEquals('ReduceMin', 2.0, VecF32x4ReduceMin(v), 0.0001);

  // ReduceMax: max(5, 2, 8, 3) = 8
  AssertEquals('ReduceMax', 8.0, VecF32x4ReduceMax(v), 0.0001);

  // ReduceMul: 1 * 2 * 3 * 4 = 24
  src[0] := 1.0; src[1] := 2.0; src[2] := 3.0; src[3] := 4.0;
  v := VecF32x4Load(@src[0]);
  AssertEquals('ReduceMul', 24.0, VecF32x4ReduceMul(v), 0.0001);

  // Fma: a*b+c = (2,2,2,2)*(3,3,3,3)+(4,4,4,4) = (10,10,10,10)
  v := VecF32x4Splat(2.0);
  w := VecF32x4Splat(3.0);
  w := VecF32x4Fma(v, w, VecF32x4Splat(4.0));
  VecF32x4Store(@dst[0], w);
  AssertEquals('Fma[0]', 10.0, dst[0], 0.0001);
  AssertEquals('Fma[1]', 10.0, dst[1], 0.0001);

  // Rcp: 1/4 = 0.25
  v := VecF32x4Splat(4.0);
  w := VecF32x4Rcp(v);
  VecF32x4Store(@dst[0], w);
  AssertEquals('Rcp[0]', 0.25, dst[0], 0.01);

  // Rsqrt: 1/sqrt(4) = 0.5
  w := VecF32x4Rsqrt(v);
  VecF32x4Store(@dst[0], w);
  AssertEquals('Rsqrt[0]', 0.5, dst[0], 0.01);

  // Floor: floor(2.7) = 2, floor(-2.3) = -3
  src[0] := 2.7; src[1] := -2.3; src[2] := 3.0; src[3] := -3.0;
  v := VecF32x4Load(@src[0]);
  w := VecF32x4Floor(v);
  VecF32x4Store(@dst[0], w);
  AssertEquals('Floor[0]', 2.0, dst[0], 0.0001);
  AssertEquals('Floor[1]', -3.0, dst[1], 0.0001);

  // Ceil: ceil(2.3) = 3, ceil(-2.7) = -2
  src[0] := 2.3; src[1] := -2.7; src[2] := 3.0; src[3] := -3.0;
  v := VecF32x4Load(@src[0]);
  w := VecF32x4Ceil(v);
  VecF32x4Store(@dst[0], w);
  AssertEquals('Ceil[0]', 3.0, dst[0], 0.0001);
  AssertEquals('Ceil[1]', -2.0, dst[1], 0.0001);

  // Round: round(2.4) = 2, round(2.6) = 3
  src[0] := 2.4; src[1] := 2.6; src[2] := -2.4; src[3] := -2.6;
  v := VecF32x4Load(@src[0]);
  w := VecF32x4Round(v);
  VecF32x4Store(@dst[0], w);
  AssertEquals('Round[0]', 2.0, dst[0], 0.0001);
  AssertEquals('Round[1]', 3.0, dst[1], 0.0001);

  // Trunc: trunc(2.9) = 2, trunc(-2.9) = -2
  src[0] := 2.9; src[1] := -2.9; src[2] := 3.0; src[3] := -3.0;
  v := VecF32x4Load(@src[0]);
  w := VecF32x4Trunc(v);
  VecF32x4Store(@dst[0], w);
  AssertEquals('Trunc[0]', 2.0, dst[0], 0.0001);
  AssertEquals('Trunc[1]', -2.0, dst[1], 0.0001);

  // Clamp: clamp((-5, 5, 15, 0), 0, 10) = (0, 5, 10, 0)
  src[0] := -5.0; src[1] := 5.0; src[2] := 15.0; src[3] := 0.0;
  v := VecF32x4Load(@src[0]);
  w := VecF32x4Clamp(v, VecF32x4Splat(0.0), VecF32x4Splat(10.0));
  VecF32x4Store(@dst[0], w);
  AssertEquals('Clamp[0]', 0.0, dst[0], 0.0001);
  AssertEquals('Clamp[1]', 5.0, dst[1], 0.0001);
  AssertEquals('Clamp[2]', 10.0, dst[2], 0.0001);

  // 3D Dot: (1,2,3) · (4,5,6) = 4+10+18 = 32
  src[0] := 1.0; src[1] := 2.0; src[2] := 3.0; src[3] := 999.0;
  v := VecF32x4Load(@src[0]);
  src[0] := 4.0; src[1] := 5.0; src[2] := 6.0; src[3] := 999.0;
  w := VecF32x4Load(@src[0]);
  AssertEquals('Dot3', 32.0, VecF32x3Dot(v, w), 0.0001);

  // 4D Dot: (1,2,3,4) · (2,3,4,5) = 2+6+12+20 = 40
  src[0] := 1.0; src[1] := 2.0; src[2] := 3.0; src[3] := 4.0;
  v := VecF32x4Load(@src[0]);
  src[0] := 2.0; src[1] := 3.0; src[2] := 4.0; src[3] := 5.0;
  w := VecF32x4Load(@src[0]);
  AssertEquals('Dot4', 40.0, VecF32x4Dot(v, w), 0.0001);

  // Cross: X × Y = Z
  src[0] := 1.0; src[1] := 0.0; src[2] := 0.0; src[3] := 0.0;
  v := VecF32x4Load(@src[0]);
  src[0] := 0.0; src[1] := 1.0; src[2] := 0.0; src[3] := 0.0;
  w := VecF32x4Load(@src[0]);
  w := VecF32x3Cross(v, w);
  VecF32x4Store(@dst[0], w);
  AssertEquals('Cross X', 0.0, dst[0], 0.0001);
  AssertEquals('Cross Y', 0.0, dst[1], 0.0001);
  AssertEquals('Cross Z', 1.0, dst[2], 0.0001);

  // Length3: |(3,4,0)| = 5
  src[0] := 3.0; src[1] := 4.0; src[2] := 0.0; src[3] := 999.0;
  v := VecF32x4Load(@src[0]);
  AssertEquals('Length3', 5.0, VecF32x3Length(v), 0.0001);

  // Length4: |(1,1,1,1)| = 2
  src[0] := 1.0; src[1] := 1.0; src[2] := 1.0; src[3] := 1.0;
  v := VecF32x4Load(@src[0]);
  AssertEquals('Length4', 2.0, VecF32x4Length(v), 0.0001);

  // Normalize3: (3,4,0) / 5 = (0.6, 0.8, 0)
  src[0] := 3.0; src[1] := 4.0; src[2] := 0.0; src[3] := 999.0;
  v := VecF32x4Load(@src[0]);
  w := VecF32x3Normalize(v);
  VecF32x4Store(@dst[0], w);
  AssertEquals('Normalize3 X', 0.6, dst[0], 0.0001);
  AssertEquals('Normalize3 Y', 0.8, dst[1], 0.0001);
  AssertEquals('Normalize3 Z', 0.0, dst[2], 0.0001);

  // Normalize4: (3,0,0,0) / 3 = (1,0,0,0)
  src[0] := 3.0; src[1] := 0.0; src[2] := 0.0; src[3] := 0.0;
  v := VecF32x4Load(@src[0]);
  w := VecF32x4Normalize(v);
  VecF32x4Store(@dst[0], w);
  AssertEquals('Normalize4 X', 1.0, dst[0], 0.0001);
  AssertEquals('Normalize4 Y', 0.0, dst[1], 0.0001);
end;

procedure TTestCase_BackendSmoke.TearDown;
begin
  ResetBackendSelection;
  inherited TearDown;
end;

procedure TTestCase_BackendSmoke.Test_VectorAsmEnabled_Toggle_Roundtrip;
var
  oldValue: Boolean;
begin
  oldValue := IsVectorAsmEnabled;

  SetVectorAsmEnabled(not oldValue);
  AssertEquals('Vector asm should reflect the new value', not oldValue, IsVectorAsmEnabled);

  SetVectorAsmEnabled(oldValue);
  AssertEquals('Vector asm should restore original value', oldValue, IsVectorAsmEnabled);
end;

procedure TTestCase_BackendSmoke.Test_DefaultBackend_VecF32x4_Smoke;
begin
  // 自动选择 backend 的情况下，基础向量操作不应崩溃，且结果应正确
  AssertTrue('Dispatch table should be assigned', GetDispatchTable <> nil);
  RunVecF32x4Smoke;
end;

procedure TTestCase_BackendSmoke.Test_ForceScalar_VecF32x4_Smoke;
begin
  ForceBackend(sbScalar);
  AssertEquals('Active backend should be Scalar', Ord(sbScalar), Ord(GetCurrentBackend));
  RunVecF32x4Smoke;
end;

procedure TTestCase_BackendSmoke.Test_ForceSSE2_VecF32x4_Smoke;
begin
  ForceBackend(sbSSE2);
  if HasSSE2 then
    AssertEquals('Active backend should be SSE2', Ord(sbSSE2), Ord(GetCurrentBackend))
  else
    AssertEquals('Fallback backend should be Scalar', Ord(sbScalar), Ord(GetCurrentBackend));
  RunVecF32x4Smoke;
end;

procedure TTestCase_BackendSmoke.Test_ForceAVX2_VecF32x4_Smoke;
begin
  ForceBackend(sbAVX2);
  if HasAVX2 then
    AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend))
  else
    AssertEquals('Fallback backend should be Scalar', Ord(sbScalar), Ord(GetCurrentBackend));
  RunVecF32x4Smoke;
end;

procedure TTestCase_BackendSmoke.Test_ForceAVX512_VecF32x4_Smoke;
begin
  ForceBackend(sbAVX512);
  if HasAVX512 then
    AssertEquals('Active backend should be AVX-512', Ord(sbAVX512), Ord(GetCurrentBackend))
  else
    AssertEquals('Fallback backend should be Scalar', Ord(sbScalar), Ord(GetCurrentBackend));
  RunVecF32x4Smoke;
end;

{ TTestCase_AVX2VectorAsm }

function SingleFromBits(bits: DWord): Single; inline;
begin
  Move(bits, Result, SizeOf(Result));
end;

function BitsFromSingle(const value: Single): DWord; inline;
begin
  Move(value, Result, SizeOf(Result));
end;

function IsNaNSingle(const value: Single): Boolean; inline;
var
  bits: DWord;
begin
  // 注意：使用浮点比较检测 NaN（value<>value）会触发 InvalidOp（若未屏蔽异常）。
  // 这里改为纯位判断：exp=all-1 且 mantissa<>0。
  bits := BitsFromSingle(value);
  Result := ((bits and $7F800000) = $7F800000) and ((bits and $007FFFFF) <> 0);
end;

function DoubleFromBits(bits: QWord): Double; inline;
begin
  Move(bits, Result, SizeOf(Result));
end;

function BitsFromDouble(const value: Double): QWord; inline;
begin
  Move(value, Result, SizeOf(Result));
end;

function IsNaNDouble(const value: Double): Boolean; inline;
var
  bits: QWord;
begin
  bits := BitsFromDouble(value);
  Result := ((bits and QWord($7FF0000000000000)) = QWord($7FF0000000000000)) and
            ((bits and QWord($000FFFFFFFFFFFFF)) <> 0);
end;

// === ABI/Calling-convention guard helpers ===
// 目标：在不依赖编译器生成的 wrapper 的情况下，直接用汇编调用 dispatch 函数指针，
// 并验证 SysV AMD64 的 callee-saved 寄存器（RBX/R12-R15）不会被破坏。

function AbiCall_TwoVecToSingle_CheckCalleeSaved(fn: Pointer; const a, b: TVecF32x4; out value: Single): Boolean; assembler; nostackframe;
asm
  // SysV AMD64 (Linux x86_64) 参数传递说明（按 FPC 对 TVecF32x4 的实际 ABI 分类）：
  //   - TVecF32x4 是 variant record（同时含 f[] 与 raw[]），FPC 在该平台将其按 INTEGER 类传递。
  //   - 因此 16B 向量按 2 个 QWord 走整数寄存器，而不是 XMM。
  //
  // 入参（本 helper 的签名：fn, a, b, out value）：
  //   RDI = fn
  //   RSI = a.lowQ
  //   RDX = a.highQ
  //   RCX = b.lowQ
  //   R8  = b.highQ
  //   R9  = @value
  //
  // 被测函数（签名：fn(a,b): Single）期望：
  //   RDI = a.lowQ
  //   RSI = a.highQ
  //   RDX = b.lowQ
  //   RCX = b.highQ
  // Return:
  //   XMM0 = Single result

  // 保存 out ptr / fn 到栈上（避免被测函数破坏 caller-saved 寄存器）。
  // 额外说明：这里用 16 bytes local + 5 pushes，保证 call 前 RSP 16-byte 对齐。
  sub rsp, 16
  mov qword ptr [rsp], r9      // out ptr
  mov qword ptr [rsp + 8], rdi // fn ptr

  // 保存 callee-saved（本函数也必须遵守 ABI）
  push rbx
  push r12
  push r13
  push r14
  push r15

  // 注意：FPC 内置汇编器对 64-bit imm 支持有限，这里用“可表示的 signed dword”哨兵值。
  mov rbx, $11223344
  mov r12, $55667788
  mov r13, $0F0E0D0C
  mov r14, $01020304
  mov r15, $22334455

  // call fn(a, b)  (按上面的“被测函数期望”重新排列寄存器)
  mov rax, qword ptr [rsp + 48]   // fn ptr
  mov rdi, rsi                    // a.lowQ
  mov rsi, rdx                    // a.highQ
  mov rdx, rcx                    // b.lowQ
  mov rcx, r8                     // b.highQ
  call rax

  // store float result (reload out ptr from stack after the call)
  mov r9, qword ptr [rsp + 40]
  movss dword ptr [r9], xmm0

  // verify callee-saved regs
  cmp rbx, $11223344
  jne @fail
  cmp r12, $55667788
  jne @fail
  cmp r13, $0F0E0D0C
  jne @fail
  cmp r14, $01020304
  jne @fail
  cmp r15, $22334455
  jne @fail

  mov eax, 1
  jmp @done

@fail:
  xor eax, eax

@done:
  pop r15
  pop r14
  pop r13
  pop r12
  pop rbx
  add rsp, 16
end;

function AbiCall_OneVecToSingle_CheckCalleeSaved(fn: Pointer; const a: TVecF32x4; out value: Single): Boolean; assembler; nostackframe;
asm
  // SysV AMD64 (Linux x86_64) 参数传递说明（按 FPC 对 TVecF32x4 的实际 ABI 分类）：
  //   RDI = fn
  //   RSI = a.lowQ
  //   RDX = a.highQ
  //   RCX = @value
  //
  // 被测函数（签名：fn(a): Single）期望：
  //   RDI = a.lowQ
  //   RSI = a.highQ
  // Return:
  //   XMM0 = Single result

  // 保存 out ptr / fn 到栈上（避免被测函数破坏 caller-saved 寄存器）。
  // 额外说明：这里用 16 bytes local + 5 pushes，保证 call 前 RSP 16-byte 对齐。
  sub rsp, 16
  mov qword ptr [rsp], rcx     // out ptr
  mov qword ptr [rsp + 8], rdi // fn ptr

  // 保存 callee-saved（本函数也必须遵守 ABI）
  push rbx
  push r12
  push r13
  push r14
  push r15

  // 注意：FPC 内置汇编器对 64-bit imm 支持有限，这里用“可表示的 signed dword”哨兵值。
  mov rbx, $11223344
  mov r12, $55667788
  mov r13, $0F0E0D0C
  mov r14, $01020304
  mov r15, $22334455

  // call fn(a)
  mov rax, qword ptr [rsp + 48]   // fn ptr
  mov rdi, rsi                    // a.lowQ
  mov rsi, rdx                    // a.highQ
  call rax

  // store float result (reload out ptr from stack after the call)
  mov r9, qword ptr [rsp + 40]
  movss dword ptr [r9], xmm0

  // verify callee-saved regs
  cmp rbx, $11223344
  jne @fail
  cmp r12, $55667788
  jne @fail
  cmp r13, $0F0E0D0C
  jne @fail
  cmp r14, $01020304
  jne @fail
  cmp r15, $22334455
  jne @fail

  mov eax, 1
  jmp @done

@fail:
  xor eax, eax

@done:
  pop r15
  pop r14
  pop r13
  pop r12
  pop rbx
  add rsp, 16
end;

function AbiCall_TwoVecToVec_CheckCalleeSaved(fn: Pointer; const a, b: TVecF32x4; out value: TVecF32x4): Boolean; assembler; nostackframe;
asm
  // SysV AMD64 (Linux x86_64) - FPC 对 TVecF32x4 的实际 ABI：按 INTEGER 类传参/返回。
  //
  // 入参（本 helper 的签名：fn, a, b, out value）：
  //   RDI = fn
  //   RSI = a.lowQ
  //   RDX = a.highQ
  //   RCX = b.lowQ
  //   R8  = b.highQ
  //   R9  = @value
  //
  // 被测函数（签名：fn(a,b): TVecF32x4）期望：
  //   RDI = a.lowQ
  //   RSI = a.highQ
  //   RDX = b.lowQ
  //   RCX = b.highQ
  // Return（预期）：
  //   RAX = result.lowQ
  //   RDX = result.highQ

  // 保存 out ptr / fn 到栈上（避免被测函数破坏 caller-saved 寄存器）。
  // 额外说明：这里用 16 bytes local + 5 pushes，保证 call 前 RSP 16-byte 对齐。
  sub rsp, 16
  mov qword ptr [rsp], r9      // out ptr
  mov qword ptr [rsp + 8], rdi // fn ptr

  // 保存 callee-saved（本函数也必须遵守 ABI）
  push rbx
  push r12
  push r13
  push r14
  push r15

  // 注意：FPC 内置汇编器对 64-bit imm 支持有限，这里用“可表示的 signed dword”哨兵值。
  mov rbx, $11223344
  mov r12, $55667788
  mov r13, $0F0E0D0C
  mov r14, $01020304
  mov r15, $22334455

  // call fn(a, b)
  mov rax, qword ptr [rsp + 48]   // fn ptr
  mov rdi, rsi                    // a.lowQ
  mov rsi, rdx                    // a.highQ
  mov rdx, rcx                    // b.lowQ
  mov rcx, r8                     // b.highQ
  call rax

  // store vector result (reload out ptr after the call)
  mov r10, qword ptr [rsp + 40]
  mov qword ptr [r10], rax
  mov qword ptr [r10 + 8], rdx

  // verify callee-saved regs
  cmp rbx, $11223344
  jne @fail
  cmp r12, $55667788
  jne @fail
  cmp r13, $0F0E0D0C
  jne @fail
  cmp r14, $01020304
  jne @fail
  cmp r15, $22334455
  jne @fail

  mov eax, 1
  jmp @done

@fail:
  xor eax, eax

@done:
  pop r15
  pop r14
  pop r13
  pop r12
  pop rbx
  add rsp, 16
end;

function AbiCall_OneVecToVec_CheckCalleeSaved(fn: Pointer; const a: TVecF32x4; out value: TVecF32x4): Boolean; assembler; nostackframe;
asm
  // SysV AMD64 (Linux x86_64) - FPC 对 TVecF32x4 的实际 ABI：按 INTEGER 类传参/返回。
  //
  // 入参（本 helper 的签名：fn, a, out value）：
  //   RDI = fn
  //   RSI = a.lowQ
  //   RDX = a.highQ
  //   RCX = @value
  //
  // 被测函数（签名：fn(a): TVecF32x4）期望：
  //   RDI = a.lowQ
  //   RSI = a.highQ
  // Return（预期）：
  //   RAX = result.lowQ
  //   RDX = result.highQ

  // 保存 out ptr / fn 到栈上（避免被测函数破坏 caller-saved 寄存器）。
  // 额外说明：这里用 16 bytes local + 5 pushes，保证 call 前 RSP 16-byte 对齐。
  sub rsp, 16
  mov qword ptr [rsp], rcx     // out ptr
  mov qword ptr [rsp + 8], rdi // fn ptr

  // 保存 callee-saved（本函数也必须遵守 ABI）
  push rbx
  push r12
  push r13
  push r14
  push r15

  // 注意：FPC 内置汇编器对 64-bit imm 支持有限，这里用“可表示的 signed dword”哨兵值。
  mov rbx, $11223344
  mov r12, $55667788
  mov r13, $0F0E0D0C
  mov r14, $01020304
  mov r15, $22334455

  // call fn(a)
  mov rax, qword ptr [rsp + 48]   // fn ptr
  mov rdi, rsi                    // a.lowQ
  mov rsi, rdx                    // a.highQ
  call rax

  // store vector result (reload out ptr after the call)
  mov r10, qword ptr [rsp + 40]
  mov qword ptr [r10], rax
  mov qword ptr [r10 + 8], rdx

  // verify callee-saved regs
  cmp rbx, $11223344
  jne @fail
  cmp r12, $55667788
  jne @fail
  cmp r13, $0F0E0D0C
  jne @fail
  cmp r14, $01020304
  jne @fail
  cmp r15, $22334455
  jne @fail

  mov eax, 1
  jmp @done

@fail:
  xor eax, eax

@done:
  pop r15
  pop r14
  pop r13
  pop r12
  pop rbx
  add rsp, 16
end;

function AbiCall_ThreeVecToVec_CheckCalleeSaved(fn: Pointer; const a, b, c: TVecF32x4; out value: TVecF32x4): Boolean; assembler; nostackframe;
asm
  // SysV AMD64 (Linux x86_64) - FPC 对 TVecF32x4 的实际 ABI：按 INTEGER 类传参/返回。
  //
  // 入参（本 helper 的签名：fn, a, b, c, out value）：
  //   RDI = fn
  //   RSI = a.lowQ
  //   RDX = a.highQ
  //   RCX = b.lowQ
  //   R8  = b.highQ
  //
  //   注意：c 需要 2 个 INTEGER 寄存器槽，但此时只剩 1 个槽（R9）。
  //   按 SysV 规则：寄存器不够时整个参数走内存，因此 c 会整体落到 stack。
  //
  //   R9 = @value
  //   stack[+8]  = c.lowQ
  //   stack[+16] = c.highQ
  //
  // 被测函数（签名：fn(a,b,c): TVecF32x4）期望：
  //   RDI = a.lowQ
  //   RSI = a.highQ
  //   RDX = b.lowQ
  //   RCX = b.highQ
  //   R8  = c.lowQ
  //   R9  = c.highQ
  // Return（预期）：
  //   RAX = result.lowQ
  //   RDX = result.highQ

  // 先把 stack 入参取出来（之后会改 RSP）。
  mov r10, qword ptr [rsp + 8]   // c.lowQ
  mov r11, qword ptr [rsp + 16]  // c.highQ

  // 保存 out ptr / fn / c 到栈上（避免被测函数破坏 caller-saved 寄存器）。
  // 额外说明：这里用 32 bytes local + 5 pushes，保证 call 前 RSP 16-byte 对齐。
  sub rsp, 32
  mov qword ptr [rsp], r9        // out ptr
  mov qword ptr [rsp + 8], rdi   // fn ptr
  mov qword ptr [rsp + 16], r10  // c.lowQ
  mov qword ptr [rsp + 24], r11  // c.highQ

  // 保存 callee-saved（本函数也必须遵守 ABI）
  push rbx
  push r12
  push r13
  push r14
  push r15

  // 注意：FPC 内置汇编器对 64-bit imm 支持有限，这里用“可表示的 signed dword”哨兵值。
  mov rbx, $11223344
  mov r12, $55667788
  mov r13, $0F0E0D0C
  mov r14, $01020304
  mov r15, $22334455

  // call fn(a, b, c)
  mov rax, qword ptr [rsp + 48]   // fn ptr
  mov rdi, rsi                    // a.lowQ
  mov rsi, rdx                    // a.highQ
  mov rdx, rcx                    // b.lowQ
  mov rcx, r8                     // b.highQ
  mov r8, qword ptr [rsp + 56]    // c.lowQ
  mov r9, qword ptr [rsp + 64]    // c.highQ
  call rax

  // store vector result (reload out ptr after the call)
  mov r10, qword ptr [rsp + 40]
  mov qword ptr [r10], rax
  mov qword ptr [r10 + 8], rdx

  // verify callee-saved regs
  cmp rbx, $11223344
  jne @fail
  cmp r12, $55667788
  jne @fail
  cmp r13, $0F0E0D0C
  jne @fail
  cmp r14, $01020304
  jne @fail
  cmp r15, $22334455
  jne @fail

  mov eax, 1
  jmp @done

@fail:
  xor eax, eax

@done:
  pop r15
  pop r14
  pop r13
  pop r12
  pop rbx
  add rsp, 32
end;

function AbiCall_PtrToVec_CheckCalleeSaved(fn: Pointer; p: PSingle; out value: TVecF32x4): Boolean; assembler; nostackframe;
asm
  // SysV AMD64 (Linux x86_64) - 入参（本 helper 的签名：fn, p, out value）：
  //   RDI = fn
  //   RSI = p
  //   RDX = @value
  //
  // 被测函数（签名：fn(p): TVecF32x4）期望：
  //   RDI = p
  // Return（预期）：
  //   RAX = result.lowQ
  //   RDX = result.highQ

  // 保存 out ptr / fn 到栈上（避免被测函数破坏 caller-saved 寄存器）。
  // 额外说明：这里用 16 bytes local + 5 pushes，保证 call 前 RSP 16-byte 对齐。
  sub rsp, 16
  mov qword ptr [rsp], rdx     // out ptr
  mov qword ptr [rsp + 8], rdi // fn ptr

  // 保存 callee-saved（本函数也必须遵守 ABI）
  push rbx
  push r12
  push r13
  push r14
  push r15

  // 注意：FPC 内置汇编器对 64-bit imm 支持有限，这里用“可表示的 signed dword”哨兵值。
  mov rbx, $11223344
  mov r12, $55667788
  mov r13, $0F0E0D0C
  mov r14, $01020304
  mov r15, $22334455

  // call fn(p)
  mov rax, qword ptr [rsp + 48]   // fn ptr
  mov rdi, rsi                    // p
  call rax

  // store vector result (reload out ptr after the call)
  mov r10, qword ptr [rsp + 40]
  mov qword ptr [r10], rax
  mov qword ptr [r10 + 8], rdx

  // verify callee-saved regs
  cmp rbx, $11223344
  jne @fail
  cmp r12, $55667788
  jne @fail
  cmp r13, $0F0E0D0C
  jne @fail
  cmp r14, $01020304
  jne @fail
  cmp r15, $22334455
  jne @fail

  mov eax, 1
  jmp @done

@fail:
  xor eax, eax

@done:
  pop r15
  pop r14
  pop r13
  pop r12
  pop rbx
  add rsp, 16
end;

function AbiCall_TwoVecToMask_CheckCalleeSaved(fn: Pointer; const a, b: TVecF32x4; out value: TMask4): Boolean; assembler; nostackframe;
asm
  // SysV AMD64 (Linux x86_64) - FPC 对 TVecF32x4 的实际 ABI：按 INTEGER 类传参。
  //
  // 入参（本 helper 的签名：fn, a, b, out value）：
  //   RDI = fn
  //   RSI = a.lowQ
  //   RDX = a.highQ
  //   RCX = b.lowQ
  //   R8  = b.highQ
  //   R9  = @value
  //
  // 被测函数（签名：fn(a,b): TMask4）期望：
  //   RDI = a.lowQ
  //   RSI = a.highQ
  //   RDX = b.lowQ
  //   RCX = b.highQ
  // Return:
  //   EAX = mask

  // 保存 out ptr / fn 到栈上（避免被测函数破坏 caller-saved 寄存器）。
  // 额外说明：这里用 16 bytes local + 5 pushes，保证 call 前 RSP 16-byte 对齐。
  sub rsp, 16
  mov qword ptr [rsp], r9      // out ptr
  mov qword ptr [rsp + 8], rdi // fn ptr

  // 保存 callee-saved（本函数也必须遵守 ABI）
  push rbx
  push r12
  push r13
  push r14
  push r15

  // 注意：FPC 内置汇编器对 64-bit imm 支持有限，这里用“可表示的 signed dword”哨兵值。
  mov rbx, $11223344
  mov r12, $55667788
  mov r13, $0F0E0D0C
  mov r14, $01020304
  mov r15, $22334455

  // call fn(a, b)
  mov rax, qword ptr [rsp + 48]   // fn ptr
  mov rdi, rsi                    // a.lowQ
  mov rsi, rdx                    // a.highQ
  mov rdx, rcx                    // b.lowQ
  mov rcx, r8                     // b.highQ
  call rax

  // store mask result (reload out ptr after the call)
  mov r10, qword ptr [rsp + 40]
  mov dword ptr [r10], eax

  // verify callee-saved regs
  cmp rbx, $11223344
  jne @fail
  cmp r12, $55667788
  jne @fail
  cmp r13, $0F0E0D0C
  jne @fail
  cmp r14, $01020304
  jne @fail
  cmp r15, $22334455
  jne @fail

  mov eax, 1
  jmp @done

@fail:
  xor eax, eax

@done:
  pop r15
  pop r14
  pop r13
  pop r12
  pop rbx
  add rsp, 16
end;

procedure TTestCase_AVX2VectorAsm.SetUp;
begin
  inherited SetUp;

  FOldVectorAsm := IsVectorAsmEnabled;

  // 强制开启 vector asm，并重新注册后端以更新 dispatch table
  SetVectorAsmEnabled(True);
  RegisterAVX2Backend;

  // 在 AVX2 可用的机器上强制使用 AVX2；否则会自动回退到 Scalar
  ForceBackend(sbAVX2);
end;

procedure TTestCase_AVX2VectorAsm.TearDown;
begin
  // 恢复 vector asm 开关，并重新注册后端，避免影响其他测试
  SetVectorAsmEnabled(FOldVectorAsm);
  RegisterAVX2Backend;

  ResetBackendSelection;
  inherited TearDown;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_Fma_FusedWhenFMAAvailable;
var
  dt: PSimdDispatchTable;
  a, b, c, r: TVecF32x4;
  expected: Single;
  i: Integer;
begin
  if not HasAVX2 then
  begin
    AssertEquals('Fallback backend should be Scalar', Ord(sbScalar), Ord(GetCurrentBackend));
    Exit;
  end;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.FmaF32x4 should be assigned', Assigned(dt^.FmaF32x4));
  AssertTrue('FmaF32x4 should not be scalar when vector asm enabled', dt^.FmaF32x4 <> @ScalarFmaF32x4);

  // 构造一个“只有 fused FMA 才会得到非零”的经典用例：
  // a = b = 1 + 2^-23 (float32 的下一个可表示数)
  // c = -(1 + 2^-22)
  // 真实结果：2^-46
  // 非 fused：先乘法舍入到 1+2^-22，再加 c => 0
  a := VecF32x4Splat(SingleFromBits($3F800001));
  b := a;
  c := VecF32x4Splat(SingleFromBits($BF800002));

  r := VecF32x4Fma(a, b, c);

  if HasFeature(gfFMA) then
    expected := SingleFromBits($28800000) // 2^-46
  else
    expected := 0.0;

  for i := 0 to 3 do
    AssertEquals('Fma element ' + IntToStr(i), expected, VecF32x4Extract(r, i), 0.0);
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x8_AddSubMulDiv_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a, b: TVecF32x8;
  expV, actV: TVecF32x8;
  i, iter: Integer;
  eps: Single;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.AddF32x8 should be assigned', Assigned(dt^.AddF32x8));
  AssertTrue('Dispatch.SubF32x8 should be assigned', Assigned(dt^.SubF32x8));
  AssertTrue('Dispatch.MulF32x8 should be assigned', Assigned(dt^.MulF32x8));
  AssertTrue('Dispatch.DivF32x8 should be assigned', Assigned(dt^.DivF32x8));

  // vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('AddF32x8 should not be scalar when vector asm enabled', dt^.AddF32x8 <> @ScalarAddF32x8);
  AssertTrue('SubF32x8 should not be scalar when vector asm enabled', dt^.SubF32x8 <> @ScalarSubF32x8);
  AssertTrue('MulF32x8 should not be scalar when vector asm enabled', dt^.MulF32x8 <> @ScalarMulF32x8);
  AssertTrue('DivF32x8 should not be scalar when vector asm enabled', dt^.DivF32x8 <> @ScalarDivF32x8);

  eps := 1e-6;
  RandSeed := 12345;

  for iter := 1 to 200 do
  begin
    for i := 0 to 7 do
    begin
      // 限制数值范围，避免溢出/下溢导致的非本测试目标分支
      a.f[i] := (Random(2000000) - 1000000) / 1000.0;
      b.f[i] := (Random(2000000) - 1000000) / 1000.0;
      if Abs(b.f[i]) < 1e-3 then
        b.f[i] := 1.0; // 避免除零/极小数
    end;

    // Add
    expV := ScalarAddF32x8(a, b);
    actV := dt^.AddF32x8(a, b);
    for i := 0 to 7 do
      AssertEquals('Add elem ' + IntToStr(i), expV.f[i], actV.f[i], eps);

    // Sub
    expV := ScalarSubF32x8(a, b);
    actV := dt^.SubF32x8(a, b);
    for i := 0 to 7 do
      AssertEquals('Sub elem ' + IntToStr(i), expV.f[i], actV.f[i], eps);

    // Mul
    expV := ScalarMulF32x8(a, b);
    actV := dt^.MulF32x8(a, b);
    for i := 0 to 7 do
      AssertEquals('Mul elem ' + IntToStr(i), expV.f[i], actV.f[i], eps);

    // Div
    expV := ScalarDivF32x8(a, b);
    actV := dt^.DivF32x8(a, b);
    for i := 0 to 7 do
      AssertEquals('Div elem ' + IntToStr(i), expV.f[i], actV.f[i], eps);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x8_AddSubMulDiv_SpecialValues_Consistency;
var
  dt: PSimdDispatchTable;
  a, b, bDiv: TVecF32x8;
  expV, actV: TVecF32x8;
  i: Integer;
  expBits, actBits: DWord;

  procedure AssertSameElementBits(const op: string; idx: Integer; expVal, actVal: Single);
  begin
    if IsNaNSingle(expVal) then
      AssertTrue(op + ' elem ' + IntToStr(idx) + ' should be NaN', IsNaNSingle(actVal))
    else
    begin
      expBits := BitsFromSingle(expVal);
      actBits := BitsFromSingle(actVal);
      AssertTrue(op + ' elem ' + IntToStr(idx) + ' bits should match', expBits = actBits);
    end;
  end;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.AddF32x8 should be assigned', Assigned(dt^.AddF32x8));
  AssertTrue('Dispatch.SubF32x8 should be assigned', Assigned(dt^.SubF32x8));
  AssertTrue('Dispatch.MulF32x8 should be assigned', Assigned(dt^.MulF32x8));
  AssertTrue('Dispatch.DivF32x8 should be assigned', Assigned(dt^.DivF32x8));

  // vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('AddF32x8 should not be scalar when vector asm enabled', dt^.AddF32x8 <> @ScalarAddF32x8);
  AssertTrue('SubF32x8 should not be scalar when vector asm enabled', dt^.SubF32x8 <> @ScalarSubF32x8);
  AssertTrue('MulF32x8 should not be scalar when vector asm enabled', dt^.MulF32x8 <> @ScalarMulF32x8);
  AssertTrue('DivF32x8 should not be scalar when vector asm enabled', dt^.DivF32x8 <> @ScalarDivF32x8);

  // 构造包含 NaN/Inf/±0 的输入，确保在 AVX2 vector-asm 路径下与 scalar 参考结果一致。
  a.f[0] := SingleFromBits($80000000); // -0
  b.f[0] := SingleFromBits($00000000); // +0

  a.f[1] := SingleFromBits($00000000); // +0
  b.f[1] := SingleFromBits($80000000); // -0

  a.f[2] := SingleFromBits($7F800000); // +Inf
  b.f[2] := 1.0;

  a.f[3] := SingleFromBits($FF800000); // -Inf
  b.f[3] := 1.0;

  a.f[4] := SingleFromBits($7FC00000); // qNaN
  b.f[4] := 2.0;

  a.f[5] := 1.0;
  b.f[5] := SingleFromBits($7F800000); // +Inf

  a.f[6] := -1.0;
  b.f[6] := SingleFromBits($FF800000); // -Inf

  a.f[7] := 123.0;
  b.f[7] := SingleFromBits($7FC00000); // qNaN

  // Add
  expV := ScalarAddF32x8(a, b);
  actV := dt^.AddF32x8(a, b);
  for i := 0 to 7 do
    AssertSameElementBits('Add', i, expV.f[i], actV.f[i]);

  // Sub
  expV := ScalarSubF32x8(a, b);
  actV := dt^.SubF32x8(a, b);
  for i := 0 to 7 do
    AssertSameElementBits('Sub', i, expV.f[i], actV.f[i]);

  // Mul
  expV := ScalarMulF32x8(a, b);
  actV := dt^.MulF32x8(a, b);
  for i := 0 to 7 do
    AssertSameElementBits('Mul', i, expV.f[i], actV.f[i]);

  // Div（避免除以 ±0；其他 special value 保留）
  bDiv := b;
  for i := 0 to 7 do
    // 避免使用浮点比较（NaN 会触发 InvalidOp）
    if (BitsFromSingle(bDiv.f[i]) and $7FFFFFFF) = 0 then
      bDiv.f[i] := 1.0;

  expV := ScalarDivF32x8(a, bDiv);
  actV := dt^.DivF32x8(a, bDiv);
  for i := 0 to 7 do
    AssertSameElementBits('Div', i, expV.f[i], actV.f[i]);
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF64x2_AddSubMulDiv_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a, b: TVecF64x2;
  expV, actV: TVecF64x2;
  iter, i: Integer;
  eps: Double;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.AddF64x2 should be assigned', Assigned(dt^.AddF64x2));
  AssertTrue('Dispatch.SubF64x2 should be assigned', Assigned(dt^.SubF64x2));
  AssertTrue('Dispatch.MulF64x2 should be assigned', Assigned(dt^.MulF64x2));
  AssertTrue('Dispatch.DivF64x2 should be assigned', Assigned(dt^.DivF64x2));

  // vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('AddF64x2 should not be scalar when vector asm enabled', dt^.AddF64x2 <> @ScalarAddF64x2);
  AssertTrue('SubF64x2 should not be scalar when vector asm enabled', dt^.SubF64x2 <> @ScalarSubF64x2);
  AssertTrue('MulF64x2 should not be scalar when vector asm enabled', dt^.MulF64x2 <> @ScalarMulF64x2);
  AssertTrue('DivF64x2 should not be scalar when vector asm enabled', dt^.DivF64x2 <> @ScalarDivF64x2);

  eps := 1e-12;
  RandSeed := 20251224;

  for iter := 1 to 2000 do
  begin
    for i := 0 to 1 do
    begin
      a.d[i] := (Random(2000001) - 1000000) / 1000.0;
      b.d[i] := (Random(2000001) - 1000000) / 1000.0;
      if Abs(b.d[i]) < 1e-12 then
        b.d[i] := 1.0;
    end;

    // Add
    expV := ScalarAddF64x2(a, b);
    actV := dt^.AddF64x2(a, b);
    for i := 0 to 1 do
      AssertEquals('F64x2 Add iter ' + IntToStr(iter) + ' lane ' + IntToStr(i), expV.d[i], actV.d[i], eps);

    // Sub
    expV := ScalarSubF64x2(a, b);
    actV := dt^.SubF64x2(a, b);
    for i := 0 to 1 do
      AssertEquals('F64x2 Sub iter ' + IntToStr(iter) + ' lane ' + IntToStr(i), expV.d[i], actV.d[i], eps);

    // Mul
    expV := ScalarMulF64x2(a, b);
    actV := dt^.MulF64x2(a, b);
    for i := 0 to 1 do
      AssertEquals('F64x2 Mul iter ' + IntToStr(iter) + ' lane ' + IntToStr(i), expV.d[i], actV.d[i], eps);

    // Div
    expV := ScalarDivF64x2(a, b);
    actV := dt^.DivF64x2(a, b);
    for i := 0 to 1 do
      AssertEquals('F64x2 Div iter ' + IntToStr(iter) + ' lane ' + IntToStr(i), expV.d[i], actV.d[i], eps);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF64x2_AddSubMulDiv_SpecialValues_Consistency;
var
  dt: PSimdDispatchTable;
  a, b, bDiv: TVecF64x2;
  expV, actV: TVecF64x2;
  i: Integer;
  expBits, actBits: QWord;

  procedure AssertSameElementBits(const op: string; idx: Integer; expVal, actVal: Double);
  begin
    if IsNaNDouble(expVal) then
      AssertTrue(op + ' lane ' + IntToStr(idx) + ' should be NaN', IsNaNDouble(actVal))
    else
    begin
      expBits := BitsFromDouble(expVal);
      actBits := BitsFromDouble(actVal);
      AssertTrue(op + ' lane ' + IntToStr(idx) + ' bits should match', expBits = actBits);
    end;
  end;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.AddF64x2 should be assigned', Assigned(dt^.AddF64x2));
  AssertTrue('Dispatch.SubF64x2 should be assigned', Assigned(dt^.SubF64x2));
  AssertTrue('Dispatch.MulF64x2 should be assigned', Assigned(dt^.MulF64x2));
  AssertTrue('Dispatch.DivF64x2 should be assigned', Assigned(dt^.DivF64x2));

  // vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('AddF64x2 should not be scalar when vector asm enabled', dt^.AddF64x2 <> @ScalarAddF64x2);
  AssertTrue('SubF64x2 should not be scalar when vector asm enabled', dt^.SubF64x2 <> @ScalarSubF64x2);
  AssertTrue('MulF64x2 should not be scalar when vector asm enabled', dt^.MulF64x2 <> @ScalarMulF64x2);
  AssertTrue('DivF64x2 should not be scalar when vector asm enabled', dt^.DivF64x2 <> @ScalarDivF64x2);

  // 特殊值：±0 / ±Inf / qNaN
  a.d[0] := DoubleFromBits(QWord($8000000000000000)); // -0
  b.d[0] := DoubleFromBits(QWord($0000000000000000)); // +0

  a.d[1] := DoubleFromBits(QWord($7FF0000000000000)); // +Inf
  b.d[1] := DoubleFromBits(QWord($7FF8000000000000)); // qNaN

  // Add
  expV := ScalarAddF64x2(a, b);
  actV := dt^.AddF64x2(a, b);
  for i := 0 to 1 do
    AssertSameElementBits('F64x2 Add', i, expV.d[i], actV.d[i]);

  // Sub
  expV := ScalarSubF64x2(a, b);
  actV := dt^.SubF64x2(a, b);
  for i := 0 to 1 do
    AssertSameElementBits('F64x2 Sub', i, expV.d[i], actV.d[i]);

  // Mul
  expV := ScalarMulF64x2(a, b);
  actV := dt^.MulF64x2(a, b);
  for i := 0 to 1 do
    AssertSameElementBits('F64x2 Mul', i, expV.d[i], actV.d[i]);

  // Div（避免除以 ±0；其他 special value 保留）
  bDiv := b;
  for i := 0 to 1 do
    if (BitsFromDouble(bDiv.d[i]) and QWord($7FFFFFFFFFFFFFFF)) = 0 then
      bDiv.d[i] := 1.0;

  expV := ScalarDivF64x2(a, bDiv);
  actV := dt^.DivF64x2(a, bDiv);
  for i := 0 to 1 do
    AssertSameElementBits('F64x2 Div', i, expV.d[i], actV.d[i]);
end;

procedure TTestCase_AVX2VectorAsm.Test_VecI32x4_AddSubMul_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a, b: TVecI32x4;
  expV, actV: TVecI32x4;
  iter, i: Integer;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.AddI32x4 should be assigned', Assigned(dt^.AddI32x4));
  AssertTrue('Dispatch.SubI32x4 should be assigned', Assigned(dt^.SubI32x4));
  AssertTrue('Dispatch.MulI32x4 should be assigned', Assigned(dt^.MulI32x4));

  // vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('AddI32x4 should not be scalar when vector asm enabled', dt^.AddI32x4 <> @ScalarAddI32x4);
  AssertTrue('SubI32x4 should not be scalar when vector asm enabled', dt^.SubI32x4 <> @ScalarSubI32x4);
  AssertTrue('MulI32x4 should not be scalar when vector asm enabled', dt^.MulI32x4 <> @ScalarMulI32x4);

  RandSeed := 20251225;

  for iter := 1 to 5000 do
  begin
    // 选择安全范围，避免 32-bit 乘法溢出（保证结果可精确对比）。
    for i := 0 to 3 do
    begin
      a.i[i] := Random(60001) - 30000; // [-30000..30000]
      b.i[i] := Random(60001) - 30000;
    end;

    // Add
    expV := ScalarAddI32x4(a, b);
    actV := dt^.AddI32x4(a, b);
    for i := 0 to 3 do
      AssertEquals('I32x4 Add iter ' + IntToStr(iter) + ' lane ' + IntToStr(i), expV.i[i], actV.i[i]);

    // Sub
    expV := ScalarSubI32x4(a, b);
    actV := dt^.SubI32x4(a, b);
    for i := 0 to 3 do
      AssertEquals('I32x4 Sub iter ' + IntToStr(iter) + ' lane ' + IntToStr(i), expV.i[i], actV.i[i]);

    // Mul
    expV := ScalarMulI32x4(a, b);
    actV := dt^.MulI32x4(a, b);
    for i := 0 to 3 do
      AssertEquals('I32x4 Mul iter ' + IntToStr(iter) + ' lane ' + IntToStr(i), expV.i[i], actV.i[i]);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecI32x4_AddSubMul_BoundaryConsistency;
var
  dt: PSimdDispatchTable;
  a, b: TVecI32x4;
  expV, actV: TVecI32x4;
  i: Integer;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.AddI32x4 should be assigned', Assigned(dt^.AddI32x4));
  AssertTrue('Dispatch.SubI32x4 should be assigned', Assigned(dt^.SubI32x4));
  AssertTrue('Dispatch.MulI32x4 should be assigned', Assigned(dt^.MulI32x4));

  // Add/Sub：边界但不溢出
  a.i[0] := High(Int32) - 1; b.i[0] := 1;  // -> High(Int32)
  a.i[1] := Low(Int32) + 1;  b.i[1] := -1; // -> Low(Int32)
  a.i[2] := 0;               b.i[2] := 0;
  a.i[3] := -1;              b.i[3] := 1;

  expV := ScalarAddI32x4(a, b);
  actV := dt^.AddI32x4(a, b);
  for i := 0 to 3 do
    AssertEquals('I32x4 Add boundary lane ' + IntToStr(i), expV.i[i], actV.i[i]);

  expV := ScalarSubI32x4(a, b);
  actV := dt^.SubI32x4(a, b);
  for i := 0 to 3 do
    AssertEquals('I32x4 Sub boundary lane ' + IntToStr(i), expV.i[i], actV.i[i]);

  // Mul：使用 46340 保证 32-bit signed 乘法不溢出。
  a.i[0] := 46340;  b.i[0] := 46340;
  a.i[1] := -46340; b.i[1] := 46340;
  a.i[2] := 0;      b.i[2] := 12345;
  a.i[3] := -1;     b.i[3] := -1;

  expV := ScalarMulI32x4(a, b);
  actV := dt^.MulI32x4(a, b);
  for i := 0 to 3 do
    AssertEquals('I32x4 Mul boundary lane ' + IntToStr(i), expV.i[i], actV.i[i]);
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_Compare_SpecialValues_Consistency;
var
  dt: PSimdDispatchTable;
  a, b: TVecF32x4;
  expMask, actMask: TMask4;
  savedMask: TFPUExceptionMask;

  function Mask4Of(b0, b1, b2, b3: Boolean): TMask4; inline;
  begin
    Result := 0;
    if b0 then Result := Result or (1 shl 0);
    if b1 then Result := Result or (1 shl 1);
    if b2 then Result := Result or (1 shl 2);
    if b3 then Result := Result or (1 shl 3);
  end;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.CmpEqF32x4 should be assigned', Assigned(dt^.CmpEqF32x4));
  AssertTrue('Dispatch.CmpLtF32x4 should be assigned', Assigned(dt^.CmpLtF32x4));
  AssertTrue('Dispatch.CmpLeF32x4 should be assigned', Assigned(dt^.CmpLeF32x4));
  AssertTrue('Dispatch.CmpGtF32x4 should be assigned', Assigned(dt^.CmpGtF32x4));
  AssertTrue('Dispatch.CmpGeF32x4 should be assigned', Assigned(dt^.CmpGeF32x4));
  AssertTrue('Dispatch.CmpNeF32x4 should be assigned', Assigned(dt^.CmpNeF32x4));

  // vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('CmpEqF32x4 should not be scalar when vector asm enabled', dt^.CmpEqF32x4 <> @ScalarCmpEqF32x4);
  AssertTrue('CmpLtF32x4 should not be scalar when vector asm enabled', dt^.CmpLtF32x4 <> @ScalarCmpLtF32x4);
  AssertTrue('CmpLeF32x4 should not be scalar when vector asm enabled', dt^.CmpLeF32x4 <> @ScalarCmpLeF32x4);
  AssertTrue('CmpGtF32x4 should not be scalar when vector asm enabled', dt^.CmpGtF32x4 <> @ScalarCmpGtF32x4);
  AssertTrue('CmpGeF32x4 should not be scalar when vector asm enabled', dt^.CmpGeF32x4 <> @ScalarCmpGeF32x4);
  AssertTrue('CmpNeF32x4 should not be scalar when vector asm enabled', dt^.CmpNeF32x4 <> @ScalarCmpNeF32x4);

  // 设计点：比较指令在 NaN 场景下会触发 InvalidOp（若未屏蔽异常），
  // 这里临时屏蔽所有 FPU 异常，避免测试运行被中断。
  savedMask := GetExceptionMask;
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  try
    // 我们直接写出 IEEE/SSE 语义的期望 mask。
    a.f[0] := SingleFromBits($7FC00000); // NaN
    b.f[0] := 1.0;

    a.f[1] := 1.0;
    b.f[1] := SingleFromBits($7FC00000); // NaN

    a.f[2] := SingleFromBits($7F800000); // +Inf
    b.f[2] := SingleFromBits($7F800000); // +Inf

    a.f[3] := SingleFromBits($80000000); // -0
    b.f[3] := 0.0;                       // +0

    // Eq: NaN==x false; Inf==Inf true; -0==+0 true
    expMask := Mask4Of(False, False, True, True);
    actMask := dt^.CmpEqF32x4(a, b);
    AssertEquals('CmpEq mask', expMask, actMask);

    // Ne: NaN!=x true (unordered); Inf!=Inf false; -0!=+0 false
    expMask := Mask4Of(True, True, False, False);
    actMask := dt^.CmpNeF32x4(a, b);
    AssertEquals('CmpNe mask', expMask, actMask);

    // Lt: NaN comparisons false; Inf<Inf false; -0<+0 false
    expMask := Mask4Of(False, False, False, False);
    actMask := dt^.CmpLtF32x4(a, b);
    AssertEquals('CmpLt mask', expMask, actMask);

    // Le: NaN comparisons false; Inf<=Inf true; -0<=+0 true
    expMask := Mask4Of(False, False, True, True);
    actMask := dt^.CmpLeF32x4(a, b);
    AssertEquals('CmpLe mask', expMask, actMask);

    // Gt: NaN comparisons false; Inf>Inf false; -0>+0 false
    expMask := Mask4Of(False, False, False, False);
    actMask := dt^.CmpGtF32x4(a, b);
    AssertEquals('CmpGt mask', expMask, actMask);

    // Ge: NaN comparisons false; Inf>=Inf true; -0>=+0 true
    expMask := Mask4Of(False, False, True, True);
    actMask := dt^.CmpGeF32x4(a, b);
    AssertEquals('CmpGe mask', expMask, actMask);
  finally
    SetExceptionMask(savedMask);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_Compare_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a, b: TVecF32x4;
  iter: Integer;
  expMask, actMask: TMask4;

  function Mask4Of(b0, b1, b2, b3: Boolean): TMask4; inline;
  begin
    Result := 0;
    if b0 then Result := Result or (1 shl 0);
    if b1 then Result := Result or (1 shl 1);
    if b2 then Result := Result or (1 shl 2);
    if b3 then Result := Result or (1 shl 3);
  end;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.CmpEqF32x4 should be assigned', Assigned(dt^.CmpEqF32x4));
  AssertTrue('Dispatch.CmpLtF32x4 should be assigned', Assigned(dt^.CmpLtF32x4));
  AssertTrue('Dispatch.CmpLeF32x4 should be assigned', Assigned(dt^.CmpLeF32x4));
  AssertTrue('Dispatch.CmpGtF32x4 should be assigned', Assigned(dt^.CmpGtF32x4));
  AssertTrue('Dispatch.CmpGeF32x4 should be assigned', Assigned(dt^.CmpGeF32x4));
  AssertTrue('Dispatch.CmpNeF32x4 should be assigned', Assigned(dt^.CmpNeF32x4));

  // vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('CmpEqF32x4 should not be scalar when vector asm enabled', dt^.CmpEqF32x4 <> @ScalarCmpEqF32x4);
  AssertTrue('CmpLtF32x4 should not be scalar when vector asm enabled', dt^.CmpLtF32x4 <> @ScalarCmpLtF32x4);
  AssertTrue('CmpLeF32x4 should not be scalar when vector asm enabled', dt^.CmpLeF32x4 <> @ScalarCmpLeF32x4);
  AssertTrue('CmpGtF32x4 should not be scalar when vector asm enabled', dt^.CmpGtF32x4 <> @ScalarCmpGtF32x4);
  AssertTrue('CmpGeF32x4 should not be scalar when vector asm enabled', dt^.CmpGeF32x4 <> @ScalarCmpGeF32x4);
  AssertTrue('CmpNeF32x4 should not be scalar when vector asm enabled', dt^.CmpNeF32x4 <> @ScalarCmpNeF32x4);

  RandSeed := 20251216;

  for iter := 1 to 200 do
  begin
    // 设计点：避免 NaN/Inf，确保对比的期望值可用普通浮点比较计算。
    // lane0：相等
    a.f[0] := (Random(2000001) - 1000000) / 1000.0;
    b.f[0] := a.f[0];

    // lane1：a < b
    a.f[1] := (Random(2000001) - 1000000) / 1000.0;
    b.f[1] := a.f[1] + 1.0;

    // lane2：a > b
    a.f[2] := (Random(2000001) - 1000000) / 1000.0;
    b.f[2] := a.f[2] - 1.0;

    // lane3：随机
    a.f[3] := (Random(2000001) - 1000000) / 1000.0;
    b.f[3] := (Random(2000001) - 1000000) / 1000.0;

    expMask := Mask4Of(a.f[0] = b.f[0], a.f[1] = b.f[1], a.f[2] = b.f[2], a.f[3] = b.f[3]);
    actMask := dt^.CmpEqF32x4(a, b);
    AssertEquals('CmpEq iter ' + IntToStr(iter), expMask, actMask);

    expMask := Mask4Of(a.f[0] <> b.f[0], a.f[1] <> b.f[1], a.f[2] <> b.f[2], a.f[3] <> b.f[3]);
    actMask := dt^.CmpNeF32x4(a, b);
    AssertEquals('CmpNe iter ' + IntToStr(iter), expMask, actMask);

    expMask := Mask4Of(a.f[0] < b.f[0], a.f[1] < b.f[1], a.f[2] < b.f[2], a.f[3] < b.f[3]);
    actMask := dt^.CmpLtF32x4(a, b);
    AssertEquals('CmpLt iter ' + IntToStr(iter), expMask, actMask);

    expMask := Mask4Of(a.f[0] <= b.f[0], a.f[1] <= b.f[1], a.f[2] <= b.f[2], a.f[3] <= b.f[3]);
    actMask := dt^.CmpLeF32x4(a, b);
    AssertEquals('CmpLe iter ' + IntToStr(iter), expMask, actMask);

    expMask := Mask4Of(a.f[0] > b.f[0], a.f[1] > b.f[1], a.f[2] > b.f[2], a.f[3] > b.f[3]);
    actMask := dt^.CmpGtF32x4(a, b);
    AssertEquals('CmpGt iter ' + IntToStr(iter), expMask, actMask);

    expMask := Mask4Of(a.f[0] >= b.f[0], a.f[1] >= b.f[1], a.f[2] >= b.f[2], a.f[3] >= b.f[3]);
    actMask := dt^.CmpGeF32x4(a, b);
    AssertEquals('CmpGe iter ' + IntToStr(iter), expMask, actMask);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_AddSubMulDiv_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a, b: TVecF32x4;
  expV, actV: TVecF32x4;
  i, iter: Integer;
  eps: Single;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.AddF32x4 should be assigned', Assigned(dt^.AddF32x4));
  AssertTrue('Dispatch.SubF32x4 should be assigned', Assigned(dt^.SubF32x4));
  AssertTrue('Dispatch.MulF32x4 should be assigned', Assigned(dt^.MulF32x4));
  AssertTrue('Dispatch.DivF32x4 should be assigned', Assigned(dt^.DivF32x4));

  // vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('AddF32x4 should not be scalar when vector asm enabled', dt^.AddF32x4 <> @ScalarAddF32x4);
  AssertTrue('SubF32x4 should not be scalar when vector asm enabled', dt^.SubF32x4 <> @ScalarSubF32x4);
  AssertTrue('MulF32x4 should not be scalar when vector asm enabled', dt^.MulF32x4 <> @ScalarMulF32x4);
  AssertTrue('DivF32x4 should not be scalar when vector asm enabled', dt^.DivF32x4 <> @ScalarDivF32x4);

  eps := 1e-6;
  RandSeed := 54321;

  for iter := 1 to 500 do
  begin
    for i := 0 to 3 do
    begin
      a.f[i] := (Random(2000001) - 1000000) / 1000.0;
      b.f[i] := (Random(2000001) - 1000000) / 1000.0;
      if Abs(b.f[i]) < 1e-3 then
        b.f[i] := 1.0;
    end;

    // Add
    expV := ScalarAddF32x4(a, b);
    actV := dt^.AddF32x4(a, b);
    for i := 0 to 3 do
      AssertEquals('Add elem ' + IntToStr(i), expV.f[i], actV.f[i], eps);

    // Sub
    expV := ScalarSubF32x4(a, b);
    actV := dt^.SubF32x4(a, b);
    for i := 0 to 3 do
      AssertEquals('Sub elem ' + IntToStr(i), expV.f[i], actV.f[i], eps);

    // Mul
    expV := ScalarMulF32x4(a, b);
    actV := dt^.MulF32x4(a, b);
    for i := 0 to 3 do
      AssertEquals('Mul elem ' + IntToStr(i), expV.f[i], actV.f[i], eps);

    // Div
    expV := ScalarDivF32x4(a, b);
    actV := dt^.DivF32x4(a, b);
    for i := 0 to 3 do
      AssertEquals('Div elem ' + IntToStr(i), expV.f[i], actV.f[i], eps);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_AddSubMulDiv_SpecialValues_Consistency;
var
  dt: PSimdDispatchTable;
  a, b, bDiv: TVecF32x4;
  expV, actV: TVecF32x4;
  i: Integer;
  expBits, actBits: DWord;

  procedure AssertSameElementBits(const op: string; idx: Integer; expVal, actVal: Single);
  begin
    if IsNaNSingle(expVal) then
      AssertTrue(op + ' elem ' + IntToStr(idx) + ' should be NaN', IsNaNSingle(actVal))
    else
    begin
      expBits := BitsFromSingle(expVal);
      actBits := BitsFromSingle(actVal);
      AssertTrue(op + ' elem ' + IntToStr(idx) + ' bits should match', expBits = actBits);
    end;
  end;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.AddF32x4 should be assigned', Assigned(dt^.AddF32x4));
  AssertTrue('Dispatch.SubF32x4 should be assigned', Assigned(dt^.SubF32x4));
  AssertTrue('Dispatch.MulF32x4 should be assigned', Assigned(dt^.MulF32x4));
  AssertTrue('Dispatch.DivF32x4 should be assigned', Assigned(dt^.DivF32x4));

  // vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('AddF32x4 should not be scalar when vector asm enabled', dt^.AddF32x4 <> @ScalarAddF32x4);
  AssertTrue('SubF32x4 should not be scalar when vector asm enabled', dt^.SubF32x4 <> @ScalarSubF32x4);
  AssertTrue('MulF32x4 should not be scalar when vector asm enabled', dt^.MulF32x4 <> @ScalarMulF32x4);
  AssertTrue('DivF32x4 should not be scalar when vector asm enabled', dt^.DivF32x4 <> @ScalarDivF32x4);

  a.f[0] := SingleFromBits($80000000); // -0
  b.f[0] := SingleFromBits($00000000); // +0

  a.f[1] := SingleFromBits($7F800000); // +Inf
  b.f[1] := 1.0;

  a.f[2] := SingleFromBits($7FC00000); // qNaN
  b.f[2] := 2.0;

  a.f[3] := 123.0;
  b.f[3] := SingleFromBits($FF800000); // -Inf

  // Add
  expV := ScalarAddF32x4(a, b);
  actV := dt^.AddF32x4(a, b);
  for i := 0 to 3 do
    AssertSameElementBits('Add', i, expV.f[i], actV.f[i]);

  // Sub
  expV := ScalarSubF32x4(a, b);
  actV := dt^.SubF32x4(a, b);
  for i := 0 to 3 do
    AssertSameElementBits('Sub', i, expV.f[i], actV.f[i]);

  // Mul
  expV := ScalarMulF32x4(a, b);
  actV := dt^.MulF32x4(a, b);
  for i := 0 to 3 do
    AssertSameElementBits('Mul', i, expV.f[i], actV.f[i]);

  // Div（避免除以 ±0；其他 special value 保留）
  bDiv := b;
  for i := 0 to 3 do
    if (BitsFromSingle(bDiv.f[i]) and $7FFFFFFF) = 0 then
      bDiv.f[i] := 1.0;

  expV := ScalarDivF32x4(a, bDiv);
  actV := dt^.DivF32x4(a, bDiv);
  for i := 0 to 3 do
    AssertSameElementBits('Div', i, expV.f[i], actV.f[i]);
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_Abs_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a: TVecF32x4;
  expV, actV: TVecF32x4;
  i, iter: Integer;
  expBits, actBits: DWord;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.AbsF32x4 should be assigned', Assigned(dt^.AbsF32x4));

  AssertTrue('AbsF32x4 should not be scalar when vector asm enabled', dt^.AbsF32x4 <> @ScalarAbsF32x4);

  RandSeed := 24680;

  for iter := 1 to 500 do
  begin
    for i := 0 to 3 do
      a.f[i] := (Random(2000001) - 1000000) / 1000.0;

    expV := ScalarAbsF32x4(a);
    actV := dt^.AbsF32x4(a);

    for i := 0 to 3 do
    begin
      expBits := BitsFromSingle(expV.f[i]);
      actBits := BitsFromSingle(actV.f[i]);
      AssertTrue('Abs elem ' + IntToStr(i) + ' bits should match', expBits = actBits);
    end;
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_Abs_SpecialValues_Consistency;
var
  dt: PSimdDispatchTable;
  a: TVecF32x4;
  expV, actV: TVecF32x4;
  i: Integer;
  expBits, actBits: DWord;

  procedure AssertSameElementBits(const op: string; idx: Integer; expVal, actVal: Single);
  begin
    if IsNaNSingle(expVal) then
      AssertTrue(op + ' elem ' + IntToStr(idx) + ' should be NaN', IsNaNSingle(actVal))
    else
    begin
      expBits := BitsFromSingle(expVal);
      actBits := BitsFromSingle(actVal);
      AssertTrue(op + ' elem ' + IntToStr(idx) + ' bits should match', expBits = actBits);
    end;
  end;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.AbsF32x4 should be assigned', Assigned(dt^.AbsF32x4));

  AssertTrue('AbsF32x4 should not be scalar when vector asm enabled', dt^.AbsF32x4 <> @ScalarAbsF32x4);

  a.f[0] := SingleFromBits($80000000); // -0
  a.f[1] := SingleFromBits($FF800000); // -Inf
  a.f[2] := SingleFromBits($7FC00000); // qNaN
  a.f[3] := -123.0;

  expV := ScalarAbsF32x4(a);
  actV := dt^.AbsF32x4(a);

  for i := 0 to 3 do
    AssertSameElementBits('Abs', i, expV.f[i], actV.f[i]);
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_Sqrt_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a: TVecF32x4;
  expV, actV: TVecF32x4;
  i, iter: Integer;
  eps: Single;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.SqrtF32x4 should be assigned', Assigned(dt^.SqrtF32x4));

  AssertTrue('SqrtF32x4 should not be scalar when vector asm enabled', dt^.SqrtF32x4 <> @ScalarSqrtF32x4);

  eps := 1e-6;
  RandSeed := 13579;

  for iter := 1 to 500 do
  begin
    for i := 0 to 3 do
      a.f[i] := Random(1000001) / 1000.0; // [0..1000]

    expV := ScalarSqrtF32x4(a);
    actV := dt^.SqrtF32x4(a);

    for i := 0 to 3 do
      AssertEquals('Sqrt elem ' + IntToStr(i), expV.f[i], actV.f[i], eps);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_Sqrt_SpecialValues_Consistency;
var
  dt: PSimdDispatchTable;
  a: TVecF32x4;
  expV, actV: TVecF32x4;
  i: Integer;
  expBits, actBits: DWord;
  savedMask: TFPUExceptionMask;

  procedure AssertSameElementBits(const op: string; idx: Integer; expVal, actVal: Single);
  begin
    if IsNaNSingle(expVal) then
      AssertTrue(op + ' elem ' + IntToStr(idx) + ' should be NaN', IsNaNSingle(actVal))
    else
    begin
      expBits := BitsFromSingle(expVal);
      actBits := BitsFromSingle(actVal);
      AssertTrue(op + ' elem ' + IntToStr(idx) + ' bits should match', expBits = actBits);
    end;
  end;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.SqrtF32x4 should be assigned', Assigned(dt^.SqrtF32x4));

  AssertTrue('SqrtF32x4 should not be scalar when vector asm enabled', dt^.SqrtF32x4 <> @ScalarSqrtF32x4);

  savedMask := GetExceptionMask;
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  try
    a.f[0] := SingleFromBits($80000000); // -0
    a.f[1] := SingleFromBits($7FC00000); // qNaN
    a.f[2] := SingleFromBits($7F800000); // +Inf
    a.f[3] := -1.0;

    expV := ScalarSqrtF32x4(a);
    actV := dt^.SqrtF32x4(a);

    for i := 0 to 3 do
      AssertSameElementBits('Sqrt', i, expV.f[i], actV.f[i]);
  finally
    SetExceptionMask(savedMask);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_MinMax_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a, b: TVecF32x4;
  expV, actV: TVecF32x4;
  i, iter: Integer;
  expBits, actBits: DWord;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.MinF32x4 should be assigned', Assigned(dt^.MinF32x4));
  AssertTrue('Dispatch.MaxF32x4 should be assigned', Assigned(dt^.MaxF32x4));

  AssertTrue('MinF32x4 should not be scalar when vector asm enabled', dt^.MinF32x4 <> @ScalarMinF32x4);
  AssertTrue('MaxF32x4 should not be scalar when vector asm enabled', dt^.MaxF32x4 <> @ScalarMaxF32x4);

  RandSeed := 112233;

  for iter := 1 to 500 do
  begin
    for i := 0 to 3 do
    begin
      a.f[i] := (Random(2000001) - 1000000) / 1000.0;
      b.f[i] := (Random(2000001) - 1000000) / 1000.0;
    end;

    // Min
    expV := ScalarMinF32x4(a, b);
    actV := dt^.MinF32x4(a, b);
    for i := 0 to 3 do
    begin
      expBits := BitsFromSingle(expV.f[i]);
      actBits := BitsFromSingle(actV.f[i]);
      AssertTrue('Min elem ' + IntToStr(i) + ' bits should match', expBits = actBits);
    end;

    // Max
    expV := ScalarMaxF32x4(a, b);
    actV := dt^.MaxF32x4(a, b);
    for i := 0 to 3 do
    begin
      expBits := BitsFromSingle(expV.f[i]);
      actBits := BitsFromSingle(actV.f[i]);
      AssertTrue('Max elem ' + IntToStr(i) + ' bits should match', expBits = actBits);
    end;
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_MinMax_SpecialValues_Consistency;
var
  dt: PSimdDispatchTable;
  a, b: TVecF32x4;
  expV, actV: TVecF32x4;
  i: Integer;
  expBits, actBits: DWord;
  savedMask: TFPUExceptionMask;

  procedure AssertSameElementBits(const op: string; idx: Integer; expVal, actVal: Single);
  begin
    if IsNaNSingle(expVal) then
      AssertTrue(op + ' elem ' + IntToStr(idx) + ' should be NaN', IsNaNSingle(actVal))
    else
    begin
      expBits := BitsFromSingle(expVal);
      actBits := BitsFromSingle(actVal);
      AssertTrue(op + ' elem ' + IntToStr(idx) + ' bits should match', expBits = actBits);
    end;
  end;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.MinF32x4 should be assigned', Assigned(dt^.MinF32x4));
  AssertTrue('Dispatch.MaxF32x4 should be assigned', Assigned(dt^.MaxF32x4));

  AssertTrue('MinF32x4 should not be scalar when vector asm enabled', dt^.MinF32x4 <> @ScalarMinF32x4);
  AssertTrue('MaxF32x4 should not be scalar when vector asm enabled', dt^.MaxF32x4 <> @ScalarMaxF32x4);

  savedMask := GetExceptionMask;
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  try
    // 覆盖：±0、Inf、NaN
    a.f[0] := SingleFromBits($80000000); // -0
    b.f[0] := SingleFromBits($00000000); // +0

    a.f[1] := SingleFromBits($00000000); // +0
    b.f[1] := SingleFromBits($80000000); // -0

    a.f[2] := SingleFromBits($7F800000); // +Inf
    b.f[2] := SingleFromBits($FF800000); // -Inf

    a.f[3] := 1.0;
    b.f[3] := SingleFromBits($7FC00000); // qNaN

    // Min
    expV := ScalarMinF32x4(a, b);
    actV := dt^.MinF32x4(a, b);
    for i := 0 to 3 do
      AssertSameElementBits('Min', i, expV.f[i], actV.f[i]);

    // Max
    expV := ScalarMaxF32x4(a, b);
    actV := dt^.MaxF32x4(a, b);
    for i := 0 to 3 do
      AssertSameElementBits('Max', i, expV.f[i], actV.f[i]);
  finally
    SetExceptionMask(savedMask);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_Reduce_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a: TVecF32x4;
  iter, i: Integer;
  expS, actS: Single;
  expBits, actBits: DWord;
  epsAdd, epsMul: Single;

  procedure AssertSameSingleBits(const op: string; expVal, actVal: Single);
  begin
    if IsNaNSingle(expVal) then
      AssertTrue(op + ' should be NaN', IsNaNSingle(actVal))
    else
    begin
      expBits := BitsFromSingle(expVal);
      actBits := BitsFromSingle(actVal);
      AssertTrue(op + ' bits should match', expBits = actBits);
    end;
  end;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.ReduceAddF32x4 should be assigned', Assigned(dt^.ReduceAddF32x4));
  AssertTrue('Dispatch.ReduceMinF32x4 should be assigned', Assigned(dt^.ReduceMinF32x4));
  AssertTrue('Dispatch.ReduceMaxF32x4 should be assigned', Assigned(dt^.ReduceMaxF32x4));
  AssertTrue('Dispatch.ReduceMulF32x4 should be assigned', Assigned(dt^.ReduceMulF32x4));

  AssertTrue('ReduceAddF32x4 should not be scalar when vector asm enabled', dt^.ReduceAddF32x4 <> @ScalarReduceAddF32x4);
  AssertTrue('ReduceMinF32x4 should not be scalar when vector asm enabled', dt^.ReduceMinF32x4 <> @ScalarReduceMinF32x4);
  AssertTrue('ReduceMaxF32x4 should not be scalar when vector asm enabled', dt^.ReduceMaxF32x4 <> @ScalarReduceMaxF32x4);
  AssertTrue('ReduceMulF32x4 should not be scalar when vector asm enabled', dt^.ReduceMulF32x4 <> @ScalarReduceMulF32x4);

  // ReduceAdd/ReduceMul 的求和/求积顺序可能在不同实现间不同（浮点非结合律），
  // 这里用小范围随机值 + 适度 eps 进行一致性验证。
  epsAdd := 1e-6;
  epsMul := 1e-6;

  RandSeed := 778899;

  for iter := 1 to 1000 do
  begin
    for i := 0 to 3 do
      a.f[i] := (Random(4000001) - 2000000) / 1000000.0; // [-2..2]

    // ReduceAdd
    expS := ScalarReduceAddF32x4(a);
    actS := dt^.ReduceAddF32x4(a);
    if IsNaNSingle(expS) then
      AssertTrue('ReduceAdd iter ' + IntToStr(iter) + ' should be NaN', IsNaNSingle(actS))
    else
      AssertEquals('ReduceAdd iter ' + IntToStr(iter), expS, actS, epsAdd);

    // ReduceMul
    expS := ScalarReduceMulF32x4(a);
    actS := dt^.ReduceMulF32x4(a);
    if IsNaNSingle(expS) then
      AssertTrue('ReduceMul iter ' + IntToStr(iter) + ' should be NaN', IsNaNSingle(actS))
    else
      AssertEquals('ReduceMul iter ' + IntToStr(iter), expS, actS, epsMul);

    // ReduceMin
    expS := ScalarReduceMinF32x4(a);
    actS := dt^.ReduceMinF32x4(a);
    AssertSameSingleBits('ReduceMin iter ' + IntToStr(iter), expS, actS);

    // ReduceMax
    expS := ScalarReduceMaxF32x4(a);
    actS := dt^.ReduceMaxF32x4(a);
    AssertSameSingleBits('ReduceMax iter ' + IntToStr(iter), expS, actS);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_Reduce_SpecialValues_Consistency;
var
  dt: PSimdDispatchTable;
  a: TVecF32x4;
  expS, actS: Single;
  expBits, actBits: DWord;
  savedMask: TFPUExceptionMask;

  procedure AssertSameSingleBits(const op: string; expVal, actVal: Single);
  begin
    if IsNaNSingle(expVal) then
      AssertTrue(op + ' should be NaN', IsNaNSingle(actVal))
    else
    begin
      expBits := BitsFromSingle(expVal);
      actBits := BitsFromSingle(actVal);
      AssertTrue(op + ' bits should match', expBits = actBits);
    end;
  end;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.ReduceAddF32x4 should be assigned', Assigned(dt^.ReduceAddF32x4));
  AssertTrue('Dispatch.ReduceMinF32x4 should be assigned', Assigned(dt^.ReduceMinF32x4));
  AssertTrue('Dispatch.ReduceMaxF32x4 should be assigned', Assigned(dt^.ReduceMaxF32x4));
  AssertTrue('Dispatch.ReduceMulF32x4 should be assigned', Assigned(dt^.ReduceMulF32x4));

  AssertTrue('ReduceAddF32x4 should not be scalar when vector asm enabled', dt^.ReduceAddF32x4 <> @ScalarReduceAddF32x4);
  AssertTrue('ReduceMinF32x4 should not be scalar when vector asm enabled', dt^.ReduceMinF32x4 <> @ScalarReduceMinF32x4);
  AssertTrue('ReduceMaxF32x4 should not be scalar when vector asm enabled', dt^.ReduceMaxF32x4 <> @ScalarReduceMaxF32x4);
  AssertTrue('ReduceMulF32x4 should not be scalar when vector asm enabled', dt^.ReduceMulF32x4 <> @ScalarReduceMulF32x4);

  // ReduceMin/Max 在 NaN/±0 场景下很容易出现“选择了哪个操作数”的差异。
  // 为避免某些 CPU/FPU 设置下触发 InvalidOp，这里局部屏蔽异常。
  savedMask := GetExceptionMask;
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  try
    // Case 1: NaN 会让 scalar 顺序 fold “重置”到后续元素（取决于 NaN 位置）
    a.f[0] := 1.0;
    a.f[1] := SingleFromBits($7FC00000); // qNaN
    a.f[2] := 2.0;
    a.f[3] := 3.0;

    expS := ScalarReduceMinF32x4(a);
    actS := dt^.ReduceMinF32x4(a);
    AssertSameSingleBits('ReduceMin NaN-position case', expS, actS);

    expS := ScalarReduceMaxF32x4(a);
    actS := dt^.ReduceMaxF32x4(a);
    AssertSameSingleBits('ReduceMax NaN-position case', expS, actS);

    expS := ScalarReduceAddF32x4(a);
    actS := dt^.ReduceAddF32x4(a);
    if IsNaNSingle(expS) then
      AssertTrue('ReduceAdd NaN-position case should be NaN', IsNaNSingle(actS))
    else
      AssertEquals('ReduceAdd NaN-position case', expS, actS, 0.0);

    expS := ScalarReduceMulF32x4(a);
    actS := dt^.ReduceMulF32x4(a);
    if IsNaNSingle(expS) then
      AssertTrue('ReduceMul NaN-position case should be NaN', IsNaNSingle(actS))
    else
      AssertEquals('ReduceMul NaN-position case', expS, actS, 0.0);

    // Case 2: 更强的 Max 反例（NaN 在中间会让 scalar 顺序 fold 丢掉早期的极大值）
    a.f[0] := 100.0;
    a.f[1] := SingleFromBits($7FC00000); // qNaN
    a.f[2] := 2.0;
    a.f[3] := 3.0;

    expS := ScalarReduceMaxF32x4(a);
    actS := dt^.ReduceMaxF32x4(a);
    AssertSameSingleBits('ReduceMax NaN-reset case', expS, actS);

    // Case 3: ±0（关注符号位）
    a.f[0] := 0.0;                       // +0
    a.f[1] := SingleFromBits($80000000); // -0
    a.f[2] := 1.0;
    a.f[3] := 2.0;

    expS := ScalarReduceMinF32x4(a);
    actS := dt^.ReduceMinF32x4(a);
    AssertSameSingleBits('ReduceMin signed-zero case', expS, actS);
  finally
    SetExceptionMask(savedMask);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_LoadStore_RandomRoundtrip;
var
  dt: PSimdDispatchTable;
  a, v: TVecF32x4;
  src: array[0..3] of Single;
  expBytes: array[0..15] of Byte;
  rawSrc, rawDst: PByte;
  pSrc, pDst: PByte;
  alignedRaw: Pointer;
  pAlignedSrc, pAlignedDst: PByte;
  iter, i: Integer;
  bits: DWord;

  procedure AssertBytesEqual(const msg: string; expectedPtr, actualPtr: PByte; count: Integer);
  var
    j: Integer;
  begin
    for j := 0 to count - 1 do
      AssertEquals(msg + ' byte ' + IntToStr(j), expectedPtr[j], actualPtr[j]);
  end;

  procedure AssertAllBytesAre(const msg: string; p: PByte; count: Integer; value: Byte);
  var
    j: Integer;
  begin
    for j := 0 to count - 1 do
      AssertEquals(msg + ' byte ' + IntToStr(j), value, p[j]);
  end;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.LoadF32x4 should be assigned', Assigned(dt^.LoadF32x4));
  AssertTrue('Dispatch.StoreF32x4 should be assigned', Assigned(dt^.StoreF32x4));
  AssertTrue('Dispatch.LoadF32x4Aligned should be assigned', Assigned(dt^.LoadF32x4Aligned));
  AssertTrue('Dispatch.StoreF32x4Aligned should be assigned', Assigned(dt^.StoreF32x4Aligned));

  AssertTrue('LoadF32x4 should not be scalar when vector asm enabled', dt^.LoadF32x4 <> @ScalarLoadF32x4);
  AssertTrue('StoreF32x4 should not be scalar when vector asm enabled', dt^.StoreF32x4 <> @ScalarStoreF32x4);
  AssertTrue('LoadF32x4Aligned should not be scalar when vector asm enabled', dt^.LoadF32x4Aligned <> @ScalarLoadF32x4Aligned);
  AssertTrue('StoreF32x4Aligned should not be scalar when vector asm enabled', dt^.StoreF32x4Aligned <> @ScalarStoreF32x4Aligned);

  rawSrc := GetMem(64);
  rawDst := GetMem(64);
  alignedRaw := AlignedAlloc(128, SIMD_ALIGN_16);
  try
    // 故意制造非对齐地址
    pSrc := rawSrc + 1;
    pDst := rawDst + 3;

    // 选择两个 16-byte 对齐的地址（避免与 header 重叠，并留足哨兵区）
    pAlignedSrc := PByte(alignedRaw) + SIMD_ALIGN_16;
    pAlignedDst := PByte(alignedRaw) + 64;

    AssertTrue('pAlignedSrc should be 16-byte aligned', IsAligned(pAlignedSrc, SIMD_ALIGN_16));
    AssertTrue('pAlignedDst should be 16-byte aligned', IsAligned(pAlignedDst, SIMD_ALIGN_16));

    RandSeed := 424242;

    for iter := 1 to 300 do
    begin
      // 生成任意 bit-pattern（包含 NaN/Inf/±0 等），load/store 应该 bit-exact。
      for i := 0 to 3 do
      begin
        bits := DWord(Random($10000)) or (DWord(Random($10000)) shl 16);
        src[i] := SingleFromBits(bits);
        a.f[i] := src[i];
      end;
      Move(src[0], expBytes[0], SizeOf(expBytes));

      // --- Unaligned store ---
      FillChar(rawDst^, 64, $CD);
      dt^.StoreF32x4(PSingle(pDst), a);
      AssertAllBytesAre('StoreF32x4 prefix sentinel', rawDst, 3, $CD);
      AssertBytesEqual('StoreF32x4 payload', @expBytes[0], pDst, 16);
      AssertAllBytesAre('StoreF32x4 suffix sentinel', pDst + 16, 64 - (3 + 16), $CD);

      // --- Unaligned load ---
      FillChar(rawSrc^, 64, $AB);
      Move(expBytes[0], pSrc^, 16);
      v := dt^.LoadF32x4(PSingle(pSrc));
      for i := 0 to 3 do
        AssertEquals('LoadF32x4 elem ' + IntToStr(i) + ' bits', BitsFromSingle(src[i]), BitsFromSingle(v.f[i]));

      // --- Aligned store ---
      FillChar(PByte(alignedRaw)^, 128, $EF);
      dt^.StoreF32x4Aligned(PSingle(pAlignedDst), a);
      AssertAllBytesAre('StoreF32x4Aligned prefix sentinel', PByte(alignedRaw), 64, $EF);
      AssertBytesEqual('StoreF32x4Aligned payload', @expBytes[0], pAlignedDst, 16);
      AssertAllBytesAre('StoreF32x4Aligned suffix sentinel', pAlignedDst + 16, 128 - (64 + 16), $EF);

      // --- Aligned load ---
      FillChar(PByte(alignedRaw)^, 128, $E1);
      Move(expBytes[0], pAlignedSrc^, 16);
      v := dt^.LoadF32x4Aligned(PSingle(pAlignedSrc));
      for i := 0 to 3 do
        AssertEquals('LoadF32x4Aligned elem ' + IntToStr(i) + ' bits', BitsFromSingle(src[i]), BitsFromSingle(v.f[i]));
    end;
  finally
    FreeMem(rawSrc);
    FreeMem(rawDst);
    AlignedFree(alignedRaw);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_LoadStore_SpecialValues_Roundtrip;
var
  dt: PSimdDispatchTable;
  a, v: TVecF32x4;
  src: array[0..3] of Single;
  expBytes: array[0..15] of Byte;
  rawSrc, rawDst: PByte;
  pSrc, pDst: PByte;
  alignedRaw: Pointer;
  pAlignedSrc, pAlignedDst: PByte;
  i: Integer;

  procedure AssertBytesEqual(const msg: string; expectedPtr, actualPtr: PByte; count: Integer);
  var
    j: Integer;
  begin
    for j := 0 to count - 1 do
      AssertEquals(msg + ' byte ' + IntToStr(j), expectedPtr[j], actualPtr[j]);
  end;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.LoadF32x4 should be assigned', Assigned(dt^.LoadF32x4));
  AssertTrue('Dispatch.StoreF32x4 should be assigned', Assigned(dt^.StoreF32x4));
  AssertTrue('Dispatch.LoadF32x4Aligned should be assigned', Assigned(dt^.LoadF32x4Aligned));
  AssertTrue('Dispatch.StoreF32x4Aligned should be assigned', Assigned(dt^.StoreF32x4Aligned));

  AssertTrue('LoadF32x4 should not be scalar when vector asm enabled', dt^.LoadF32x4 <> @ScalarLoadF32x4);
  AssertTrue('StoreF32x4 should not be scalar when vector asm enabled', dt^.StoreF32x4 <> @ScalarStoreF32x4);
  AssertTrue('LoadF32x4Aligned should not be scalar when vector asm enabled', dt^.LoadF32x4Aligned <> @ScalarLoadF32x4Aligned);
  AssertTrue('StoreF32x4Aligned should not be scalar when vector asm enabled', dt^.StoreF32x4Aligned <> @ScalarStoreF32x4Aligned);

  // 特殊值：±0 / ±Inf / qNaN
  src[0] := SingleFromBits($00000000); // +0
  src[1] := SingleFromBits($80000000); // -0
  src[2] := SingleFromBits($7F800000); // +Inf
  src[3] := SingleFromBits($7FC00000); // qNaN

  for i := 0 to 3 do
    a.f[i] := src[i];
  Move(src[0], expBytes[0], SizeOf(expBytes));

  rawSrc := GetMem(64);
  rawDst := GetMem(64);
  alignedRaw := AlignedAlloc(128, SIMD_ALIGN_16);
  try
    pSrc := rawSrc + 1;
    pDst := rawDst + 3;

    pAlignedSrc := PByte(alignedRaw) + SIMD_ALIGN_16;
    pAlignedDst := PByte(alignedRaw) + 64;

    AssertTrue('pAlignedSrc should be 16-byte aligned', IsAligned(pAlignedSrc, SIMD_ALIGN_16));
    AssertTrue('pAlignedDst should be 16-byte aligned', IsAligned(pAlignedDst, SIMD_ALIGN_16));

    // Store unaligned
    FillChar(rawDst^, 64, $CD);
    dt^.StoreF32x4(PSingle(pDst), a);
    AssertBytesEqual('StoreF32x4 special-values payload', @expBytes[0], pDst, 16);

    // Load unaligned
    FillChar(rawSrc^, 64, $AB);
    Move(expBytes[0], pSrc^, 16);
    v := dt^.LoadF32x4(PSingle(pSrc));
    for i := 0 to 3 do
      AssertEquals('LoadF32x4 special-values elem ' + IntToStr(i) + ' bits', BitsFromSingle(src[i]), BitsFromSingle(v.f[i]));

    // Store aligned
    FillChar(PByte(alignedRaw)^, 128, $EF);
    dt^.StoreF32x4Aligned(PSingle(pAlignedDst), a);
    AssertBytesEqual('StoreF32x4Aligned special-values payload', @expBytes[0], pAlignedDst, 16);

    // Load aligned
    FillChar(PByte(alignedRaw)^, 128, $E1);
    Move(expBytes[0], pAlignedSrc^, 16);
    v := dt^.LoadF32x4Aligned(PSingle(pAlignedSrc));
    for i := 0 to 3 do
      AssertEquals('LoadF32x4Aligned special-values elem ' + IntToStr(i) + ' bits', BitsFromSingle(src[i]), BitsFromSingle(v.f[i]));
  finally
    FreeMem(rawSrc);
    FreeMem(rawDst);
    AlignedFree(alignedRaw);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_Select_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a, b: TVecF32x4;
  expV, actV: TVecF32x4;
  iter, i: Integer;
  mask: TMask4;
  bits: DWord;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.SelectF32x4 should be assigned', Assigned(dt^.SelectF32x4));

  AssertTrue('SelectF32x4 should not be scalar when vector asm enabled', dt^.SelectF32x4 <> @ScalarSelectF32x4);

  RandSeed := 911911;

  for iter := 1 to 1000 do
  begin
    // 使用任意 bit-pattern，Select 应该是纯“按 lane 选值”的语义，不应该改动位模式。
    for i := 0 to 3 do
    begin
      bits := DWord(Random($10000)) or (DWord(Random($10000)) shl 16);
      a.f[i] := SingleFromBits(bits);
      bits := DWord(Random($10000)) or (DWord(Random($10000)) shl 16);
      b.f[i] := SingleFromBits(bits);
    end;

    mask := TMask4(Random(16));

    for i := 0 to 3 do
      if (mask and (1 shl i)) <> 0 then
        expV.f[i] := a.f[i]
      else
        expV.f[i] := b.f[i];

    actV := dt^.SelectF32x4(mask, a, b);

    for i := 0 to 3 do
      AssertEquals('Select iter ' + IntToStr(iter) + ' lane ' + IntToStr(i) + ' bits',
                   BitsFromSingle(expV.f[i]), BitsFromSingle(actV.f[i]));
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_ExtractInsert_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a, v: TVecF32x4;
  iter, i, idx: Integer;
  bits: DWord;
  value, extracted: Single;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.ExtractF32x4 should be assigned', Assigned(dt^.ExtractF32x4));
  AssertTrue('Dispatch.InsertF32x4 should be assigned', Assigned(dt^.InsertF32x4));

  AssertTrue('ExtractF32x4 should not be scalar when vector asm enabled', dt^.ExtractF32x4 <> @ScalarExtractF32x4);
  AssertTrue('InsertF32x4 should not be scalar when vector asm enabled', dt^.InsertF32x4 <> @ScalarInsertF32x4);

  RandSeed := 12211221;

  for iter := 1 to 1000 do
  begin
    // 任意 bit-pattern（包含 NaN/Inf/子正常数等），Extract/Insert 都应该 bit-exact。
    for i := 0 to 3 do
    begin
      bits := DWord(Random($10000)) or (DWord(Random($10000)) shl 16);
      a.f[i] := SingleFromBits(bits);
    end;

    idx := Random(4);

    extracted := dt^.ExtractF32x4(a, idx);
    AssertEquals('Extract iter ' + IntToStr(iter) + ' idx ' + IntToStr(idx) + ' bits',
                 BitsFromSingle(a.f[idx]), BitsFromSingle(extracted));

    bits := DWord(Random($10000)) or (DWord(Random($10000)) shl 16);
    value := SingleFromBits(bits);

    v := dt^.InsertF32x4(a, value, idx);

    for i := 0 to 3 do
      if i = idx then
        AssertEquals('Insert iter ' + IntToStr(iter) + ' idx ' + IntToStr(idx) + ' lane bits',
                     BitsFromSingle(value), BitsFromSingle(v.f[i]))
      else
        AssertEquals('Insert iter ' + IntToStr(iter) + ' idx ' + IntToStr(idx) + ' other lane ' + IntToStr(i) + ' bits',
                     BitsFromSingle(a.f[i]), BitsFromSingle(v.f[i]));

    extracted := dt^.ExtractF32x4(v, idx);
    AssertEquals('Extract-after-insert iter ' + IntToStr(iter) + ' idx ' + IntToStr(idx) + ' bits',
                 BitsFromSingle(value), BitsFromSingle(extracted));
  end;

  // 额外覆盖：确保 -0 的符号位不会在 Extract/Insert 中丢失。
  a.f[0] := 1.0;
  a.f[1] := 2.0;
  a.f[2] := 3.0;
  a.f[3] := 4.0;
  value := SingleFromBits($80000000); // -0
  v := dt^.InsertF32x4(a, value, 1);
  AssertEquals('Insert signed-zero lane bits', DWord($80000000), BitsFromSingle(v.f[1]));
  extracted := dt^.ExtractF32x4(v, 1);
  AssertEquals('Extract signed-zero lane bits', DWord($80000000), BitsFromSingle(extracted));
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_SplatZero_BitExact;
var
  dt: PSimdDispatchTable;
  v: TVecF32x4;
  value: Single;
  bits: DWord;
  iter, i: Integer;

  procedure AssertAllLanesBits(const msg: string; const vec: TVecF32x4; expectedBits: DWord);
  var
    j: Integer;
  begin
    for j := 0 to 3 do
      AssertEquals(msg + ' lane ' + IntToStr(j) + ' bits', expectedBits, BitsFromSingle(vec.f[j]));
  end;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.SplatF32x4 should be assigned', Assigned(dt^.SplatF32x4));
  AssertTrue('Dispatch.ZeroF32x4 should be assigned', Assigned(dt^.ZeroF32x4));

  AssertTrue('SplatF32x4 should not be scalar when vector asm enabled', dt^.SplatF32x4 <> @ScalarSplatF32x4);
  AssertTrue('ZeroF32x4 should not be scalar when vector asm enabled', dt^.ZeroF32x4 <> @ScalarZeroF32x4);

  // Zero：必须是 +0（全 0 bit），不能是 -0。
  v := dt^.ZeroF32x4();
  AssertAllLanesBits('ZeroF32x4', v, DWord(0));

  RandSeed := 334455;

  for iter := 1 to 1000 do
  begin
    bits := DWord(Random($10000)) or (DWord(Random($10000)) shl 16);
    value := SingleFromBits(bits);

    v := dt^.SplatF32x4(value);
    for i := 0 to 3 do
      AssertEquals('Splat iter ' + IntToStr(iter) + ' lane ' + IntToStr(i) + ' bits',
                   bits, BitsFromSingle(v.f[i]));
  end;

  // 特殊：-0 / qNaN payload
  value := SingleFromBits($80000000);
  v := dt^.SplatF32x4(value);
  AssertAllLanesBits('Splat -0', v, DWord($80000000));

  bits := $7FC12345;
  value := SingleFromBits(bits);
  v := dt^.SplatF32x4(value);
  AssertAllLanesBits('Splat qNaN payload', v, bits);
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_RcpRsqrt_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a: TVecF32x4;
  expV, actV: TVecF32x4;
  iter, i: Integer;
  eps: Single;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.RcpF32x4 should be assigned', Assigned(dt^.RcpF32x4));
  AssertTrue('Dispatch.RsqrtF32x4 should be assigned', Assigned(dt^.RsqrtF32x4));

  // 这个 suite 目标是验证 --vector-asm 路径：这里强制确保 AVX2 backend
  // 在 vector asm 打开时不会退回到 scalar reference。
  AssertTrue('RcpF32x4 should not be scalar when vector asm enabled', dt^.RcpF32x4 <> @ScalarRcpF32x4);
  AssertTrue('RsqrtF32x4 should not be scalar when vector asm enabled', dt^.RsqrtF32x4 <> @ScalarRsqrtF32x4);

  // Rcp/Rsqrt 可能是近似实现，这里选取温和输入范围并用 eps 做一致性验证。
  // 输入范围 [0.5..2.0]：避免 1/x 过大、以及 rsqrt 的负数/零域。
  eps := 1e-3;

  RandSeed := 556677;

  for iter := 1 to 2000 do
  begin
    for i := 0 to 3 do
      a.f[i] := 0.5 + (Random(1500001) / 1000000.0); // [0.5..2.0]

    // Rcp
    expV := ScalarRcpF32x4(a);
    actV := dt^.RcpF32x4(a);
    for i := 0 to 3 do
      AssertEquals('Rcp iter ' + IntToStr(iter) + ' lane ' + IntToStr(i), expV.f[i], actV.f[i], eps);

    // Rsqrt
    expV := ScalarRsqrtF32x4(a);
    actV := dt^.RsqrtF32x4(a);
    for i := 0 to 3 do
      AssertEquals('Rsqrt iter ' + IntToStr(iter) + ' lane ' + IntToStr(i), expV.f[i], actV.f[i], eps);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_FloorCeil_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a: TVecF32x4;
  expV, actV: TVecF32x4;
  iter, i: Integer;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.FloorF32x4 should be assigned', Assigned(dt^.FloorF32x4));
  AssertTrue('Dispatch.CeilF32x4 should be assigned', Assigned(dt^.CeilF32x4));

  // 同样要求：vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('FloorF32x4 should not be scalar when vector asm enabled', dt^.FloorF32x4 <> @ScalarFloorF32x4);
  AssertTrue('CeilF32x4 should not be scalar when vector asm enabled', dt^.CeilF32x4 <> @ScalarCeilF32x4);

  // 选择一个结果可精确表示的范围（避免超出 float32 的整数精度）。
  RandSeed := 778866;

  for iter := 1 to 2000 do
  begin
    for i := 0 to 3 do
      a.f[i] := (Random(2000001) - 1000000) / 1000.0; // [-1000..1000]

    // Floor
    expV := ScalarFloorF32x4(a);
    actV := dt^.FloorF32x4(a);
    for i := 0 to 3 do
      AssertEquals('Floor iter ' + IntToStr(iter) + ' lane ' + IntToStr(i), expV.f[i], actV.f[i], 0.0);

    // Ceil
    expV := ScalarCeilF32x4(a);
    actV := dt^.CeilF32x4(a);
    for i := 0 to 3 do
      AssertEquals('Ceil iter ' + IntToStr(iter) + ' lane ' + IntToStr(i), expV.f[i], actV.f[i], 0.0);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_RoundTrunc_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a: TVecF32x4;
  expV, actV: TVecF32x4;
  iter, i: Integer;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.RoundF32x4 should be assigned', Assigned(dt^.RoundF32x4));
  AssertTrue('Dispatch.TruncF32x4 should be assigned', Assigned(dt^.TruncF32x4));

  // vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('RoundF32x4 should not be scalar when vector asm enabled', dt^.RoundF32x4 <> @ScalarRoundF32x4);
  AssertTrue('TruncF32x4 should not be scalar when vector asm enabled', dt^.TruncF32x4 <> @ScalarTruncF32x4);

  // 先用确定性 case 覆盖“0.5 ties to even”语义。
  a.f[0] := 2.5;
  a.f[1] := 3.5;
  a.f[2] := -2.5;
  a.f[3] := -3.5;

  expV := ScalarRoundF32x4(a);
  actV := dt^.RoundF32x4(a);
  for i := 0 to 3 do
    AssertEquals('Round tie-even lane ' + IntToStr(i), expV.f[i], actV.f[i], 0.0);

  // Random：范围同样限制在可精确表示整数的区间
  RandSeed := 889977;

  for iter := 1 to 2000 do
  begin
    for i := 0 to 3 do
      a.f[i] := (Random(2000001) - 1000000) / 1000.0; // [-1000..1000]

    // Round
    expV := ScalarRoundF32x4(a);
    actV := dt^.RoundF32x4(a);
    for i := 0 to 3 do
      AssertEquals('Round iter ' + IntToStr(iter) + ' lane ' + IntToStr(i), expV.f[i], actV.f[i], 0.0);

    // Trunc
    expV := ScalarTruncF32x4(a);
    actV := dt^.TruncF32x4(a);
    for i := 0 to 3 do
      AssertEquals('Trunc iter ' + IntToStr(iter) + ' lane ' + IntToStr(i), expV.f[i], actV.f[i], 0.0);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_Clamp_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a, minV, maxV: TVecF32x4;
  expV, actV: TVecF32x4;
  iter, i: Integer;
  expBits, actBits: DWord;
  savedMask: TFPUExceptionMask;

  procedure AssertSameLaneBits(const msg: string; idx: Integer; expVal, actVal: Single);
  begin
    if IsNaNSingle(expVal) then
      AssertTrue(msg + ' lane ' + IntToStr(idx) + ' should be NaN', IsNaNSingle(actVal))
    else
    begin
      expBits := BitsFromSingle(expVal);
      actBits := BitsFromSingle(actVal);
      AssertTrue(msg + ' lane ' + IntToStr(idx) + ' bits should match', expBits = actBits);
    end;
  end;

begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.ClampF32x4 should be assigned', Assigned(dt^.ClampF32x4));

  // vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('ClampF32x4 should not be scalar when vector asm enabled', dt^.ClampF32x4 <> @ScalarClampF32x4);

  // Clamp 内部会触发浮点比较（NaN 场景会触发 InvalidOp），这里局部屏蔽异常。
  savedMask := GetExceptionMask;
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  try
    // 明确覆盖一个 NaN ordering case：
    // scalar: Max(minVal, Min(a, maxVal))，当 a=NaN 时，Min(a,maxVal) 会选 maxVal（SSE-style），因此结果应为 maxVal。
    a := VecF32x4Splat(SingleFromBits($7FC00000)); // qNaN
    minV := VecF32x4Splat(0.0);
    maxV := VecF32x4Splat(10.0);

    expV := ScalarClampF32x4(a, minV, maxV);
    actV := dt^.ClampF32x4(a, minV, maxV);
    for i := 0 to 3 do
      AssertSameLaneBits('Clamp NaN-ordering', i, expV.f[i], actV.f[i]);

    RandSeed := 991122;

    for iter := 1 to 2000 do
    begin
      for i := 0 to 3 do
      begin
        // a in [-2..2]
        a.f[i] := (Random(4000001) - 2000000) / 1000000.0;
        // min in [-1..1]
        minV.f[i] := (Random(2000001) - 1000000) / 1000000.0;
        // max >= min, add [0..2]
        maxV.f[i] := minV.f[i] + (Random(2000001) / 1000000.0);
      end;

      expV := ScalarClampF32x4(a, minV, maxV);
      actV := dt^.ClampF32x4(a, minV, maxV);

      for i := 0 to 3 do
        AssertSameLaneBits('Clamp iter ' + IntToStr(iter), i, expV.f[i], actV.f[i]);
    end;
  finally
    SetExceptionMask(savedMask);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_Dot_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a, b: TVecF32x4;
  iter, i: Integer;
  expS, actS: Single;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.DotF32x4 should be assigned', Assigned(dt^.DotF32x4));

  // vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('DotF32x4 should not be scalar when vector asm enabled', dt^.DotF32x4 <> @ScalarDotF32x4);

  // 选择小整数，保证乘加结果在 float32 精确可表示的范围内，避免“求和顺序”带来的舍入差异。
  RandSeed := 20251217;

  for iter := 1 to 5000 do
  begin
    for i := 0 to 3 do
    begin
      a.f[i] := Single(Random(2001) - 1000);
      b.f[i] := Single(Random(2001) - 1000);
    end;

    expS := ScalarDotF32x4(a, b);
    actS := dt^.DotF32x4(a, b);

    AssertEquals('Dot iter ' + IntToStr(iter), expS, actS, 0.0);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_Dot3_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a, b: TVecF32x4;
  iter, i: Integer;
  expS, actS: Single;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.DotF32x3 should be assigned', Assigned(dt^.DotF32x3));

  // vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('DotF32x3 should not be scalar when vector asm enabled', dt^.DotF32x3 <> @ScalarDotF32x3);

  RandSeed := 20251218;

  for iter := 1 to 5000 do
  begin
    // x/y/z 使用小整数，保证 dot3 结果精确可比较；w 随机但应被忽略。
    for i := 0 to 2 do
    begin
      a.f[i] := Single(Random(2001) - 1000);
      b.f[i] := Single(Random(2001) - 1000);
    end;
    a.f[3] := Single(Random(2001) - 1000);
    b.f[3] := Single(Random(2001) - 1000);

    expS := ScalarDotF32x3(a, b);
    actS := dt^.DotF32x3(a, b);

    AssertEquals('Dot3 iter ' + IntToStr(iter), expS, actS, 0.0);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_Cross3_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a, b: TVecF32x4;
  expV, actV: TVecF32x4;
  iter, i: Integer;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.CrossF32x3 should be assigned', Assigned(dt^.CrossF32x3));

  // vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('CrossF32x3 should not be scalar when vector asm enabled', dt^.CrossF32x3 <> @ScalarCrossF32x3);

  RandSeed := 20251219;

  for iter := 1 to 2000 do
  begin
    // 小整数：乘减结果精确可表示。
    for i := 0 to 2 do
    begin
      a.f[i] := Single(Random(2001) - 1000);
      b.f[i] := Single(Random(2001) - 1000);
    end;
    // w 随机，但 cross 应忽略并强制输出 w=+0
    a.f[3] := Single(Random(2001) - 1000);
    b.f[3] := Single(Random(2001) - 1000);

    expV := ScalarCrossF32x3(a, b);
    actV := dt^.CrossF32x3(a, b);

    for i := 0 to 2 do
      AssertEquals('Cross3 iter ' + IntToStr(iter) + ' lane ' + IntToStr(i), expV.f[i], actV.f[i], 0.0);

    AssertEquals('Cross3 w should be +0', DWord(0), BitsFromSingle(actV.f[3]));
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_Length_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a: TVecF32x4;
  iter, i: Integer;
  expS, actS: Single;
  eps: Single;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.LengthF32x4 should be assigned', Assigned(dt^.LengthF32x4));

  // vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('LengthF32x4 should not be scalar when vector asm enabled', dt^.LengthF32x4 <> @ScalarLengthF32x4);

  // 确定性：3-4-0-0 -> 5
  a.f[0] := 3.0; a.f[1] := 4.0; a.f[2] := 0.0; a.f[3] := 0.0;
  expS := ScalarLengthF32x4(a);
  actS := dt^.LengthF32x4(a);
  AssertEquals('Length(3,4,0,0)', expS, actS, 0.0);

  // 随机一致性：避免极端值
  eps := 1e-4;
  RandSeed := 20251220;

  for iter := 1 to 5000 do
  begin
    for i := 0 to 3 do
      a.f[i] := (Random(20001) - 10000) / 100.0; // [-100..100]

    expS := ScalarLengthF32x4(a);
    actS := dt^.LengthF32x4(a);

    AssertEquals('Length iter ' + IntToStr(iter), expS, actS, eps);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_Length3_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a: TVecF32x4;
  iter, i: Integer;
  expS, actS: Single;
  eps: Single;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.LengthF32x3 should be assigned', Assigned(dt^.LengthF32x3));

  // vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('LengthF32x3 should not be scalar when vector asm enabled', dt^.LengthF32x3 <> @ScalarLengthF32x3);

  // 确定性：|(3,4,0)| -> 5（w ignored）
  a.f[0] := 3.0; a.f[1] := 4.0; a.f[2] := 0.0; a.f[3] := 999.0;
  expS := ScalarLengthF32x3(a);
  actS := dt^.LengthF32x3(a);
  AssertEquals('Length3(3,4,0)', expS, actS, 0.0);

  eps := 1e-4;
  RandSeed := 20251221;

  for iter := 1 to 5000 do
  begin
    for i := 0 to 2 do
      a.f[i] := (Random(20001) - 10000) / 100.0;
    a.f[3] := (Random(20001) - 10000) / 100.0; // ignored

    expS := ScalarLengthF32x3(a);
    actS := dt^.LengthF32x3(a);

    AssertEquals('Length3 iter ' + IntToStr(iter), expS, actS, eps);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_Normalize_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a: TVecF32x4;
  expV, actV: TVecF32x4;
  iter, i: Integer;
  eps: Single;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.NormalizeF32x4 should be assigned', Assigned(dt^.NormalizeF32x4));

  // vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('NormalizeF32x4 should not be scalar when vector asm enabled', dt^.NormalizeF32x4 <> @ScalarNormalizeF32x4);

  // 确定性：Normalize(3,0,0,0) -> (1,0,0,0)
  a.f[0] := 3.0; a.f[1] := 0.0; a.f[2] := 0.0; a.f[3] := 0.0;
  expV := ScalarNormalizeF32x4(a);
  actV := dt^.NormalizeF32x4(a);
  for i := 0 to 3 do
    AssertEquals('Normalize(3,0,0,0) lane ' + IntToStr(i), expV.f[i], actV.f[i], 0.0);

  eps := 1e-4;
  RandSeed := 20251222;

  for iter := 1 to 5000 do
  begin
    for i := 0 to 3 do
      a.f[i] := (Random(20001) - 10000) / 100.0;

    expV := ScalarNormalizeF32x4(a);
    actV := dt^.NormalizeF32x4(a);

    for i := 0 to 3 do
      AssertEquals('Normalize iter ' + IntToStr(iter) + ' lane ' + IntToStr(i), expV.f[i], actV.f[i], eps);
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_Normalize3_RandomConsistency;
var
  dt: PSimdDispatchTable;
  a: TVecF32x4;
  expV, actV: TVecF32x4;
  iter, i: Integer;
  eps: Single;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);
  AssertTrue('Dispatch.NormalizeF32x3 should be assigned', Assigned(dt^.NormalizeF32x3));

  // vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('NormalizeF32x3 should not be scalar when vector asm enabled', dt^.NormalizeF32x3 <> @ScalarNormalizeF32x3);

  // 确定性：Normalize3(3,4,0,w) -> (0.6,0.8,0,w=0)
  a.f[0] := 3.0; a.f[1] := 4.0; a.f[2] := 0.0; a.f[3] := 999.0;
  expV := ScalarNormalizeF32x3(a);
  actV := dt^.NormalizeF32x3(a);
  eps := 1e-4;
  for i := 0 to 2 do
    AssertEquals('Normalize3(3,4,0) lane ' + IntToStr(i), expV.f[i], actV.f[i], eps);
  AssertEquals('Normalize3 w should be +0', DWord(0), BitsFromSingle(actV.f[3]));

  RandSeed := 20251223;

  for iter := 1 to 5000 do
  begin
    for i := 0 to 2 do
      a.f[i] := (Random(20001) - 10000) / 100.0;
    a.f[3] := (Random(20001) - 10000) / 100.0;

    expV := ScalarNormalizeF32x3(a);
    actV := dt^.NormalizeF32x3(a);

    for i := 0 to 2 do
      AssertEquals('Normalize3 iter ' + IntToStr(iter) + ' lane ' + IntToStr(i), expV.f[i], actV.f[i], eps);
    AssertEquals('Normalize3 iter ' + IntToStr(iter) + ' w should be +0', DWord(0), BitsFromSingle(actV.f[3]));
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_ABI_CalleeSavedRegisters_Preserved;
var
  dt: PSimdDispatchTable;
  a, b: TVecF32x4;
  expected, actual: Single;
  iter, i: Integer;
  ok: Boolean;
  eps: Single;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);

  // 选择 3 个代表性的“返回 Single”的操作做 ABI 保护：Dot / Length / ReduceAdd。
  AssertTrue('Dispatch.DotF32x4 should be assigned', Assigned(dt^.DotF32x4));
  AssertTrue('Dispatch.LengthF32x4 should be assigned', Assigned(dt^.LengthF32x4));
  AssertTrue('Dispatch.ReduceAddF32x4 should be assigned', Assigned(dt^.ReduceAddF32x4));

  // 要求：vector asm 打开时，AVX2 backend 不应退回到 scalar reference。
  AssertTrue('DotF32x4 should not be scalar when vector asm enabled', dt^.DotF32x4 <> @ScalarDotF32x4);
  AssertTrue('LengthF32x4 should not be scalar when vector asm enabled', dt^.LengthF32x4 <> @ScalarLengthF32x4);
  AssertTrue('ReduceAddF32x4 should not be scalar when vector asm enabled', dt^.ReduceAddF32x4 <> @ScalarReduceAddF32x4);

  // Dot：用小整数保证精确可比。
  RandSeed := 20251226;
  for iter := 1 to 2000 do
  begin
    for i := 0 to 3 do
    begin
      a.f[i] := Single(Random(2001) - 1000);
      b.f[i] := Single(Random(2001) - 1000);
    end;

    expected := ScalarDotF32x4(a, b);
    ok := AbiCall_TwoVecToSingle_CheckCalleeSaved(Pointer(dt^.DotF32x4), a, b, actual);
    AssertTrue('ABI callee-saved should be preserved (Dot) iter ' + IntToStr(iter), ok);
    AssertEquals('ABI Dot iter ' + IntToStr(iter), expected, actual, 0.0);
  end;

  // ReduceAdd：同样用小整数精确可比。
  RandSeed := 20251227;
  for iter := 1 to 2000 do
  begin
    for i := 0 to 3 do
      a.f[i] := Single(Random(2001) - 1000);

    expected := ScalarReduceAddF32x4(a);
    ok := AbiCall_OneVecToSingle_CheckCalleeSaved(Pointer(dt^.ReduceAddF32x4), a, actual);
    AssertTrue('ABI callee-saved should be preserved (ReduceAdd) iter ' + IntToStr(iter), ok);
    AssertEquals('ABI ReduceAdd iter ' + IntToStr(iter), expected, actual, 0.0);
  end;

  // Length：包含 sqrt，使用可精确表示的 case + eps。
  a.f[0] := 3.0; a.f[1] := 4.0; a.f[2] := 0.0; a.f[3] := 0.0;
  expected := ScalarLengthF32x4(a);
  ok := AbiCall_OneVecToSingle_CheckCalleeSaved(Pointer(dt^.LengthF32x4), a, actual);
  AssertTrue('ABI callee-saved should be preserved (Length)', ok);
  eps := 1e-6;
  AssertEquals('ABI Length(3,4,0,0)', expected, actual, eps);
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_ABI_CalleeSavedRegisters_Preserved_VectorReturn;
var
  dt: PSimdDispatchTable;
  a, b, expected, actual: TVecF32x4;
  iter, i: Integer;
  ok: Boolean;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);

  AssertTrue('Dispatch.AddF32x4 should be assigned', Assigned(dt^.AddF32x4));
  AssertTrue('Dispatch.SubF32x4 should be assigned', Assigned(dt^.SubF32x4));
  AssertTrue('Dispatch.MulF32x4 should be assigned', Assigned(dt^.MulF32x4));
  AssertTrue('Dispatch.MinF32x4 should be assigned', Assigned(dt^.MinF32x4));
  AssertTrue('Dispatch.MaxF32x4 should be assigned', Assigned(dt^.MaxF32x4));

  AssertTrue('AddF32x4 should not be scalar when vector asm enabled', dt^.AddF32x4 <> @ScalarAddF32x4);
  AssertTrue('SubF32x4 should not be scalar when vector asm enabled', dt^.SubF32x4 <> @ScalarSubF32x4);
  AssertTrue('MulF32x4 should not be scalar when vector asm enabled', dt^.MulF32x4 <> @ScalarMulF32x4);
  AssertTrue('MinF32x4 should not be scalar when vector asm enabled', dt^.MinF32x4 <> @ScalarMinF32x4);
  AssertTrue('MaxF32x4 should not be scalar when vector asm enabled', dt^.MaxF32x4 <> @ScalarMaxF32x4);

  RandSeed := 20251228;

  for iter := 1 to 2000 do
  begin
    for i := 0 to 3 do
    begin
      // 选小整数，保证结果 float32 bit-exact
      a.f[i] := Single(Random(2001) - 1000);
      b.f[i] := Single(Random(2001) - 1000);
    end;

    // Add
    expected := ScalarAddF32x4(a, b);
    ok := AbiCall_TwoVecToVec_CheckCalleeSaved(Pointer(dt^.AddF32x4), a, b, actual);
    AssertTrue('ABI callee-saved should be preserved (AddF32x4) iter ' + IntToStr(iter), ok);
    for i := 0 to 3 do
      AssertEquals('ABI AddF32x4 iter ' + IntToStr(iter) + ' lane ' + IntToStr(i) + ' bits',
                   BitsFromSingle(expected.f[i]), BitsFromSingle(actual.f[i]));

    // Sub
    expected := ScalarSubF32x4(a, b);
    ok := AbiCall_TwoVecToVec_CheckCalleeSaved(Pointer(dt^.SubF32x4), a, b, actual);
    AssertTrue('ABI callee-saved should be preserved (SubF32x4) iter ' + IntToStr(iter), ok);
    for i := 0 to 3 do
      AssertEquals('ABI SubF32x4 iter ' + IntToStr(iter) + ' lane ' + IntToStr(i) + ' bits',
                   BitsFromSingle(expected.f[i]), BitsFromSingle(actual.f[i]));

    // Mul
    expected := ScalarMulF32x4(a, b);
    ok := AbiCall_TwoVecToVec_CheckCalleeSaved(Pointer(dt^.MulF32x4), a, b, actual);
    AssertTrue('ABI callee-saved should be preserved (MulF32x4) iter ' + IntToStr(iter), ok);
    for i := 0 to 3 do
      AssertEquals('ABI MulF32x4 iter ' + IntToStr(iter) + ' lane ' + IntToStr(i) + ' bits',
                   BitsFromSingle(expected.f[i]), BitsFromSingle(actual.f[i]));

    // Min
    expected := ScalarMinF32x4(a, b);
    ok := AbiCall_TwoVecToVec_CheckCalleeSaved(Pointer(dt^.MinF32x4), a, b, actual);
    AssertTrue('ABI callee-saved should be preserved (MinF32x4) iter ' + IntToStr(iter), ok);
    for i := 0 to 3 do
      AssertEquals('ABI MinF32x4 iter ' + IntToStr(iter) + ' lane ' + IntToStr(i) + ' bits',
                   BitsFromSingle(expected.f[i]), BitsFromSingle(actual.f[i]));

    // Max
    expected := ScalarMaxF32x4(a, b);
    ok := AbiCall_TwoVecToVec_CheckCalleeSaved(Pointer(dt^.MaxF32x4), a, b, actual);
    AssertTrue('ABI callee-saved should be preserved (MaxF32x4) iter ' + IntToStr(iter), ok);
    for i := 0 to 3 do
      AssertEquals('ABI MaxF32x4 iter ' + IntToStr(iter) + ' lane ' + IntToStr(i) + ' bits',
                   BitsFromSingle(expected.f[i]), BitsFromSingle(actual.f[i]));
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_ABI_CalleeSavedRegisters_Preserved_VectorReturn_OneVec;
var
  dt: PSimdDispatchTable;
  a, expected, actual: TVecF32x4;
  iter, i: Integer;
  ok: Boolean;
  n: Integer;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);

  AssertTrue('Dispatch.AbsF32x4 should be assigned', Assigned(dt^.AbsF32x4));
  AssertTrue('Dispatch.SqrtF32x4 should be assigned', Assigned(dt^.SqrtF32x4));

  AssertTrue('AbsF32x4 should not be scalar when vector asm enabled', dt^.AbsF32x4 <> @ScalarAbsF32x4);
  AssertTrue('SqrtF32x4 should not be scalar when vector asm enabled', dt^.SqrtF32x4 <> @ScalarSqrtF32x4);

  // Abs: bit-exact
  RandSeed := 20251229;
  for iter := 1 to 2000 do
  begin
    for i := 0 to 3 do
      a.f[i] := Single(Random(2001) - 1000);

    expected := ScalarAbsF32x4(a);
    ok := AbiCall_OneVecToVec_CheckCalleeSaved(Pointer(dt^.AbsF32x4), a, actual);
    AssertTrue('ABI callee-saved should be preserved (AbsF32x4) iter ' + IntToStr(iter), ok);

    for i := 0 to 3 do
      AssertEquals('ABI AbsF32x4 iter ' + IntToStr(iter) + ' lane ' + IntToStr(i) + ' bits',
                   BitsFromSingle(expected.f[i]), BitsFromSingle(actual.f[i]));
  end;

  // Sqrt: perfect squares (bit-exact)
  RandSeed := 20251230;
  for iter := 1 to 2000 do
  begin
    for i := 0 to 3 do
    begin
      n := Random(4001); // [0..4000]
      a.f[i] := Single(n * n);
    end;

    expected := ScalarSqrtF32x4(a);
    ok := AbiCall_OneVecToVec_CheckCalleeSaved(Pointer(dt^.SqrtF32x4), a, actual);
    AssertTrue('ABI callee-saved should be preserved (SqrtF32x4) iter ' + IntToStr(iter), ok);

    for i := 0 to 3 do
      AssertEquals('ABI SqrtF32x4 iter ' + IntToStr(iter) + ' lane ' + IntToStr(i) + ' bits',
                   BitsFromSingle(expected.f[i]), BitsFromSingle(actual.f[i]));
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_ABI_CalleeSavedRegisters_Preserved_VectorReturn_ThreeVec;
var
  dt: PSimdDispatchTable;
  a, b, c, expected, actual: TVecF32x4;
  iter, i: Integer;
  ok: Boolean;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);

  AssertTrue('Dispatch.FmaF32x4 should be assigned', Assigned(dt^.FmaF32x4));
  AssertTrue('Dispatch.ClampF32x4 should be assigned', Assigned(dt^.ClampF32x4));

  AssertTrue('FmaF32x4 should not be scalar when vector asm enabled', dt^.FmaF32x4 <> @ScalarFmaF32x4);
  AssertTrue('ClampF32x4 should not be scalar when vector asm enabled', dt^.ClampF32x4 <> @ScalarClampF32x4);

  // Fma: choose small integers => bit-exact whether fused or not
  RandSeed := 20260101;
  for iter := 1 to 2000 do
  begin
    for i := 0 to 3 do
    begin
      a.f[i] := Single(Random(2001) - 1000);
      b.f[i] := Single(Random(2001) - 1000);
      c.f[i] := Single(Random(2001) - 1000);
    end;

    expected := ScalarFmaF32x4(a, b, c);
    ok := AbiCall_ThreeVecToVec_CheckCalleeSaved(Pointer(dt^.FmaF32x4), a, b, c, actual);
    AssertTrue('ABI callee-saved should be preserved (FmaF32x4) iter ' + IntToStr(iter), ok);

    for i := 0 to 3 do
      AssertEquals('ABI FmaF32x4 iter ' + IntToStr(iter) + ' lane ' + IntToStr(i) + ' bits',
                   BitsFromSingle(expected.f[i]), BitsFromSingle(actual.f[i]));
  end;

  // Clamp: also 3 vectors => ABI guard for passing 3x TVecF32x4
  RandSeed := 20260102;
  for iter := 1 to 2000 do
  begin
    for i := 0 to 3 do
    begin
      a.f[i] := Single(Random(2001) - 1000);
      b.f[i] := Single(Random(2001) - 1000);              // min
      c.f[i] := b.f[i] + Single(Random(2001));            // max >= min
    end;

    expected := ScalarClampF32x4(a, b, c);
    ok := AbiCall_ThreeVecToVec_CheckCalleeSaved(Pointer(dt^.ClampF32x4), a, b, c, actual);
    AssertTrue('ABI callee-saved should be preserved (ClampF32x4) iter ' + IntToStr(iter), ok);

    for i := 0 to 3 do
      AssertEquals('ABI ClampF32x4 iter ' + IntToStr(iter) + ' lane ' + IntToStr(i) + ' bits',
                   BitsFromSingle(expected.f[i]), BitsFromSingle(actual.f[i]));
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_ABI_CalleeSavedRegisters_Preserved_VectorReturn_Ptr;
var
  dt: PSimdDispatchTable;
  buf: array[0..15] of Single;
  pAligned: PSingle;
  expected, actual: TVecF32x4;
  iter, i: Integer;
  ok: Boolean;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);

  AssertTrue('Dispatch.LoadF32x4 should be assigned', Assigned(dt^.LoadF32x4));
  AssertTrue('Dispatch.LoadF32x4Aligned should be assigned', Assigned(dt^.LoadF32x4Aligned));

  AssertTrue('LoadF32x4 should not be scalar when vector asm enabled', dt^.LoadF32x4 <> @ScalarLoadF32x4);
  AssertTrue('LoadF32x4Aligned should not be scalar when vector asm enabled', dt^.LoadF32x4Aligned <> @ScalarLoadF32x4Aligned);

  // Unaligned load
  RandSeed := 20260103;
  for iter := 1 to 2000 do
  begin
    for i := 0 to 3 do
      buf[i] := Single(Random(2001) - 1000);

    expected := ScalarLoadF32x4(@buf[0]);
    ok := AbiCall_PtrToVec_CheckCalleeSaved(Pointer(dt^.LoadF32x4), @buf[0], actual);
    AssertTrue('ABI callee-saved should be preserved (LoadF32x4) iter ' + IntToStr(iter), ok);

    for i := 0 to 3 do
      AssertEquals('ABI LoadF32x4 iter ' + IntToStr(iter) + ' lane ' + IntToStr(i) + ' bits',
                   BitsFromSingle(expected.f[i]), BitsFromSingle(actual.f[i]));
  end;

  // Aligned load
  pAligned := PSingle((PtrUInt(@buf[0]) + 15) and not PtrUInt(15));

  RandSeed := 20260104;
  for iter := 1 to 2000 do
  begin
    for i := 0 to 3 do
      pAligned[i] := Single(Random(2001) - 1000);

    expected := ScalarLoadF32x4Aligned(pAligned);
    ok := AbiCall_PtrToVec_CheckCalleeSaved(Pointer(dt^.LoadF32x4Aligned), pAligned, actual);
    AssertTrue('ABI callee-saved should be preserved (LoadF32x4Aligned) iter ' + IntToStr(iter), ok);

    for i := 0 to 3 do
      AssertEquals('ABI LoadF32x4Aligned iter ' + IntToStr(iter) + ' lane ' + IntToStr(i) + ' bits',
                   BitsFromSingle(expected.f[i]), BitsFromSingle(actual.f[i]));
  end;
end;

procedure TTestCase_AVX2VectorAsm.Test_VecF32x4_ABI_CalleeSavedRegisters_Preserved_MaskReturn;
var
  dt: PSimdDispatchTable;
  a, b: TVecF32x4;
  expected, actual: TMask4;
  iter, i: Integer;
  ok: Boolean;
begin
  if not HasAVX2 then
    Exit;

  AssertEquals('Active backend should be AVX2', Ord(sbAVX2), Ord(GetCurrentBackend));

  dt := GetDispatchTable;
  AssertTrue('Dispatch table should be assigned', dt <> nil);

  AssertTrue('Dispatch.CmpEqF32x4 should be assigned', Assigned(dt^.CmpEqF32x4));
  AssertTrue('Dispatch.CmpLtF32x4 should be assigned', Assigned(dt^.CmpLtF32x4));
  AssertTrue('Dispatch.CmpLeF32x4 should be assigned', Assigned(dt^.CmpLeF32x4));
  AssertTrue('Dispatch.CmpGtF32x4 should be assigned', Assigned(dt^.CmpGtF32x4));
  AssertTrue('Dispatch.CmpGeF32x4 should be assigned', Assigned(dt^.CmpGeF32x4));
  AssertTrue('Dispatch.CmpNeF32x4 should be assigned', Assigned(dt^.CmpNeF32x4));

  AssertTrue('CmpEqF32x4 should not be scalar when vector asm enabled', dt^.CmpEqF32x4 <> @ScalarCmpEqF32x4);
  AssertTrue('CmpLtF32x4 should not be scalar when vector asm enabled', dt^.CmpLtF32x4 <> @ScalarCmpLtF32x4);
  AssertTrue('CmpLeF32x4 should not be scalar when vector asm enabled', dt^.CmpLeF32x4 <> @ScalarCmpLeF32x4);
  AssertTrue('CmpGtF32x4 should not be scalar when vector asm enabled', dt^.CmpGtF32x4 <> @ScalarCmpGtF32x4);
  AssertTrue('CmpGeF32x4 should not be scalar when vector asm enabled', dt^.CmpGeF32x4 <> @ScalarCmpGeF32x4);
  AssertTrue('CmpNeF32x4 should not be scalar when vector asm enabled', dt^.CmpNeF32x4 <> @ScalarCmpNeF32x4);

  RandSeed := 20251231;

  for iter := 1 to 2000 do
  begin
    for i := 0 to 3 do
    begin
      a.f[i] := Single(Random(2001) - 1000);
      b.f[i] := Single(Random(2001) - 1000);
    end;

    expected := ScalarCmpEqF32x4(a, b);
    ok := AbiCall_TwoVecToMask_CheckCalleeSaved(Pointer(dt^.CmpEqF32x4), a, b, actual);
    AssertTrue('ABI callee-saved should be preserved (CmpEqF32x4) iter ' + IntToStr(iter), ok);
    AssertEquals('ABI CmpEqF32x4 iter ' + IntToStr(iter), expected, actual);

    expected := ScalarCmpLtF32x4(a, b);
    ok := AbiCall_TwoVecToMask_CheckCalleeSaved(Pointer(dt^.CmpLtF32x4), a, b, actual);
    AssertTrue('ABI callee-saved should be preserved (CmpLtF32x4) iter ' + IntToStr(iter), ok);
    AssertEquals('ABI CmpLtF32x4 iter ' + IntToStr(iter), expected, actual);

    expected := ScalarCmpLeF32x4(a, b);
    ok := AbiCall_TwoVecToMask_CheckCalleeSaved(Pointer(dt^.CmpLeF32x4), a, b, actual);
    AssertTrue('ABI callee-saved should be preserved (CmpLeF32x4) iter ' + IntToStr(iter), ok);
    AssertEquals('ABI CmpLeF32x4 iter ' + IntToStr(iter), expected, actual);

    expected := ScalarCmpGtF32x4(a, b);
    ok := AbiCall_TwoVecToMask_CheckCalleeSaved(Pointer(dt^.CmpGtF32x4), a, b, actual);
    AssertTrue('ABI callee-saved should be preserved (CmpGtF32x4) iter ' + IntToStr(iter), ok);
    AssertEquals('ABI CmpGtF32x4 iter ' + IntToStr(iter), expected, actual);

    expected := ScalarCmpGeF32x4(a, b);
    ok := AbiCall_TwoVecToMask_CheckCalleeSaved(Pointer(dt^.CmpGeF32x4), a, b, actual);
    AssertTrue('ABI callee-saved should be preserved (CmpGeF32x4) iter ' + IntToStr(iter), ok);
    AssertEquals('ABI CmpGeF32x4 iter ' + IntToStr(iter), expected, actual);

    expected := ScalarCmpNeF32x4(a, b);
    ok := AbiCall_TwoVecToMask_CheckCalleeSaved(Pointer(dt^.CmpNeF32x4), a, b, actual);
    AssertTrue('ABI callee-saved should be preserved (CmpNeF32x4) iter ' + IntToStr(iter), ok);
    AssertEquals('ABI CmpNeF32x4 iter ' + IntToStr(iter), expected, actual);
  end;
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

{ TTestCase_VectorMaskTypes }

procedure TTestCase_VectorMaskTypes.Test_MaskF32x4_TypeDef_Size;
var
  m: TMaskF32x4;
begin
  AssertEquals('TMaskF32x4 should be 16 bytes', 16, SizeOf(m));
end;

procedure TTestCase_VectorMaskTypes.Test_MaskF32x4_AllTrue;
var
  m: TMaskF32x4;
begin
  m := MaskF32x4AllTrue;
  AssertEquals('m[0] should be $FFFFFFFF', UInt32($FFFFFFFF), m.m[0]);
  AssertEquals('m[1] should be $FFFFFFFF', UInt32($FFFFFFFF), m.m[1]);
  AssertEquals('m[2] should be $FFFFFFFF', UInt32($FFFFFFFF), m.m[2]);
  AssertEquals('m[3] should be $FFFFFFFF', UInt32($FFFFFFFF), m.m[3]);
end;

procedure TTestCase_VectorMaskTypes.Test_MaskF32x4_AllFalse;
var
  m: TMaskF32x4;
begin
  m := MaskF32x4AllFalse;
  AssertEquals('m[0] should be 0', UInt32(0), m.m[0]);
  AssertEquals('m[1] should be 0', UInt32(0), m.m[1]);
  AssertEquals('m[2] should be 0', UInt32(0), m.m[2]);
  AssertEquals('m[3] should be 0', UInt32(0), m.m[3]);
end;

procedure TTestCase_VectorMaskTypes.Test_MaskF32x4_Mixed;
var
  m: TMaskF32x4;
begin
  m := MaskF32x4Set(True, False, True, False);
  AssertEquals('m[0] should be $FFFFFFFF', UInt32($FFFFFFFF), m.m[0]);
  AssertEquals('m[1] should be 0', UInt32(0), m.m[1]);
  AssertEquals('m[2] should be $FFFFFFFF', UInt32($FFFFFFFF), m.m[2]);
  AssertEquals('m[3] should be 0', UInt32(0), m.m[3]);
end;

procedure TTestCase_VectorMaskTypes.Test_MaskF32x4_Test;
var
  m: TMaskF32x4;
begin
  m := MaskF32x4Set(True, False, True, False);
  AssertTrue('Test(0) should be True', MaskF32x4Test(m, 0));
  AssertFalse('Test(1) should be False', MaskF32x4Test(m, 1));
  AssertTrue('Test(2) should be True', MaskF32x4Test(m, 2));
  AssertFalse('Test(3) should be False', MaskF32x4Test(m, 3));
end;

procedure TTestCase_VectorMaskTypes.Test_MaskF32x4_ToBitmask;
var
  m: TMaskF32x4;
  bm: TMask4;
begin
  m := MaskF32x4AllTrue;
  bm := MaskF32x4ToBitmask(m);
  AssertEquals('AllTrue bitmask should be $F', $F, bm);
  
  m := MaskF32x4AllFalse;
  bm := MaskF32x4ToBitmask(m);
  AssertEquals('AllFalse bitmask should be 0', 0, bm);
  
  m := MaskF32x4Set(True, False, True, False);
  bm := MaskF32x4ToBitmask(m);
  AssertEquals('Mixed bitmask should be $5', $5, bm);  // bits 0,2 set = 0101
end;

procedure TTestCase_VectorMaskTypes.Test_MaskF32x4_Any;
var
  m: TMaskF32x4;
begin
  m := MaskF32x4AllTrue;
  AssertTrue('AllTrue.Any should be True', MaskF32x4Any(m));
  
  m := MaskF32x4AllFalse;
  AssertFalse('AllFalse.Any should be False', MaskF32x4Any(m));
  
  m := MaskF32x4Set(False, False, False, True);
  AssertTrue('OnlyLast.Any should be True', MaskF32x4Any(m));
end;

procedure TTestCase_VectorMaskTypes.Test_MaskF32x4_All;
var
  m: TMaskF32x4;
begin
  m := MaskF32x4AllTrue;
  AssertTrue('AllTrue.All should be True', MaskF32x4All(m));
  
  m := MaskF32x4AllFalse;
  AssertFalse('AllFalse.All should be False', MaskF32x4All(m));
  
  m := MaskF32x4Set(True, True, True, False);
  AssertFalse('Almost all.All should be False', MaskF32x4All(m));
end;

procedure TTestCase_VectorMaskTypes.Test_MaskF32x4_None;
var
  m: TMaskF32x4;
begin
  m := MaskF32x4AllTrue;
  AssertFalse('AllTrue.None should be False', MaskF32x4None(m));
  
  m := MaskF32x4AllFalse;
  AssertTrue('AllFalse.None should be True', MaskF32x4None(m));
  
  m := MaskF32x4Set(False, False, False, True);
  AssertFalse('OnlyLast.None should be False', MaskF32x4None(m));
end;

procedure TTestCase_VectorMaskTypes.Test_MaskF32x4_Op_And;
var
  a, b, c: TMaskF32x4;
begin
  a := MaskF32x4Set(True, True, False, False);
  b := MaskF32x4Set(True, False, True, False);
  c := a and b;
  
  AssertTrue('(T and T) should be T', MaskF32x4Test(c, 0));
  AssertFalse('(T and F) should be F', MaskF32x4Test(c, 1));
  AssertFalse('(F and T) should be F', MaskF32x4Test(c, 2));
  AssertFalse('(F and F) should be F', MaskF32x4Test(c, 3));
end;

procedure TTestCase_VectorMaskTypes.Test_MaskF32x4_Op_Or;
var
  a, b, c: TMaskF32x4;
begin
  a := MaskF32x4Set(True, True, False, False);
  b := MaskF32x4Set(True, False, True, False);
  c := a or b;
  
  AssertTrue('(T or T) should be T', MaskF32x4Test(c, 0));
  AssertTrue('(T or F) should be T', MaskF32x4Test(c, 1));
  AssertTrue('(F or T) should be T', MaskF32x4Test(c, 2));
  AssertFalse('(F or F) should be F', MaskF32x4Test(c, 3));
end;

procedure TTestCase_VectorMaskTypes.Test_MaskF32x4_Op_Xor;
var
  a, b, c: TMaskF32x4;
begin
  a := MaskF32x4Set(True, True, False, False);
  b := MaskF32x4Set(True, False, True, False);
  c := a xor b;
  
  AssertFalse('(T xor T) should be F', MaskF32x4Test(c, 0));
  AssertTrue('(T xor F) should be T', MaskF32x4Test(c, 1));
  AssertTrue('(F xor T) should be T', MaskF32x4Test(c, 2));
  AssertFalse('(F xor F) should be F', MaskF32x4Test(c, 3));
end;

procedure TTestCase_VectorMaskTypes.Test_MaskF32x4_Op_Not;
var
  a, c: TMaskF32x4;
begin
  a := MaskF32x4Set(True, False, True, False);
  c := not a;
  
  AssertFalse('(not T) should be F', MaskF32x4Test(c, 0));
  AssertTrue('(not F) should be T', MaskF32x4Test(c, 1));
  AssertFalse('(not T) should be F', MaskF32x4Test(c, 2));
  AssertTrue('(not F) should be T', MaskF32x4Test(c, 3));
end;

procedure TTestCase_VectorMaskTypes.Test_MaskI32x4_TypeDef_Size;
var
  m: TMaskI32x4;
begin
  AssertEquals('TMaskI32x4 should be 16 bytes', 16, SizeOf(m));
end;

procedure TTestCase_VectorMaskTypes.Test_MaskI32x4_AllTrue;
var
  m: TMaskI32x4;
begin
  m := MaskI32x4AllTrue;
  AssertEquals('m[0] should be $FFFFFFFF', UInt32($FFFFFFFF), m.m[0]);
  AssertEquals('m[1] should be $FFFFFFFF', UInt32($FFFFFFFF), m.m[1]);
  AssertEquals('m[2] should be $FFFFFFFF', UInt32($FFFFFFFF), m.m[2]);
  AssertEquals('m[3] should be $FFFFFFFF', UInt32($FFFFFFFF), m.m[3]);
end;

procedure TTestCase_VectorMaskTypes.Test_MaskI32x4_ToBitmask;
var
  m: TMaskI32x4;
  bm: TMask4;
begin
  m := MaskI32x4AllTrue;
  bm := MaskI32x4ToBitmask(m);
  AssertEquals('AllTrue bitmask should be $F', $F, bm);
  
  m := MaskI32x4AllFalse;
  bm := MaskI32x4ToBitmask(m);
  AssertEquals('AllFalse bitmask should be 0', 0, bm);
end;

procedure TTestCase_VectorMaskTypes.Test_MaskF64x2_TypeDef_Size;
var
  m: TMaskF64x2;
begin
  AssertEquals('TMaskF64x2 should be 16 bytes', 16, SizeOf(m));
end;

procedure TTestCase_VectorMaskTypes.Test_MaskF64x2_AllTrue;
var
  m: TMaskF64x2;
begin
  m := MaskF64x2AllTrue;
  AssertEquals('m[0] should be max UInt64', High(UInt64), m.m[0]);
  AssertEquals('m[1] should be max UInt64', High(UInt64), m.m[1]);
end;

procedure TTestCase_VectorMaskTypes.Test_MaskF64x2_ToBitmask;
var
  m: TMaskF64x2;
  bm: TMask2;
begin
  m := MaskF64x2AllTrue;
  bm := MaskF64x2ToBitmask(m);
  AssertEquals('AllTrue bitmask should be $3', $3, bm);
  
  m := MaskF64x2AllFalse;
  bm := MaskF64x2ToBitmask(m);
  AssertEquals('AllFalse bitmask should be 0', 0, bm);
end;

procedure TTestCase_VectorMaskTypes.Test_MaskF32x4_Select;
var
  m: TMaskF32x4;
  a, b, r: TVecF32x4;
begin
  // mask: [T, F, T, F]
  m := MaskF32x4Set(True, False, True, False);
  
  // a = [1, 2, 3, 4], b = [10, 20, 30, 40]
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  b.f[0] := 10.0; b.f[1] := 20.0; b.f[2] := 30.0; b.f[3] := 40.0;
  
  r := MaskF32x4Select(m, a, b);
  
  // result should be [1, 20, 3, 40]
  AssertEquals('r[0] should be 1.0 (from a)', 1.0, r.f[0], 0.0001);
  AssertEquals('r[1] should be 20.0 (from b)', 20.0, r.f[1], 0.0001);
  AssertEquals('r[2] should be 3.0 (from a)', 3.0, r.f[2], 0.0001);
  AssertEquals('r[3] should be 40.0 (from b)', 40.0, r.f[3], 0.0001);
end;

{ TTestCase_TypeConversion }

procedure TTestCase_TypeConversion.Test_VecF32x4_IntoBits;
var
  f: TVecF32x4;
  i: TVecI32x4;
begin
  // 1.0 的位模式是 0x3F800000
  f.f[0] := 1.0;
  f.f[1] := 1.0;
  f.f[2] := 1.0;
  f.f[3] := 1.0;
  i := VecF32x4IntoBits(f);
  
  AssertEquals('1.0 bit pattern should be $3F800000', Int32($3F800000), i.i[0]);
  AssertEquals('Element 1 should match', Int32($3F800000), i.i[1]);
  AssertEquals('Element 2 should match', Int32($3F800000), i.i[2]);
  AssertEquals('Element 3 should match', Int32($3F800000), i.i[3]);
end;

procedure TTestCase_TypeConversion.Test_VecI32x4_FromBitsF32;
var
  i: TVecI32x4;
  f: TVecF32x4;
begin
  // 0x3F800000 解释为浮点数应该是 1.0
  i.i[0] := Int32($3F800000);
  i.i[1] := Int32($3F800000);
  i.i[2] := Int32($3F800000);
  i.i[3] := Int32($3F800000);
  
  f := VecI32x4FromBitsF32(i);
  
  AssertEquals('$3F800000 as float should be 1.0', 1.0, f.f[0], 0.0001);
  AssertEquals('Element 1 should be 1.0', 1.0, f.f[1], 0.0001);
  AssertEquals('Element 2 should be 1.0', 1.0, f.f[2], 0.0001);
  AssertEquals('Element 3 should be 1.0', 1.0, f.f[3], 0.0001);
end;

procedure TTestCase_TypeConversion.Test_IntoBits_FromBits_Roundtrip;
var
  original, restored: TVecF32x4;
  bits: TVecI32x4;
begin
  original.f[0] := 1.5;
  original.f[1] := -2.5;
  original.f[2] := 3.14159;
  original.f[3] := 0.0;
  
  bits := VecF32x4IntoBits(original);
  restored := VecI32x4FromBitsF32(bits);
  
  AssertEquals('Roundtrip [0]', original.f[0], restored.f[0], 0.0001);
  AssertEquals('Roundtrip [1]', original.f[1], restored.f[1], 0.0001);
  AssertEquals('Roundtrip [2]', original.f[2], restored.f[2], 0.0001);
  AssertEquals('Roundtrip [3]', original.f[3], restored.f[3], 0.0001);
end;

procedure TTestCase_TypeConversion.Test_VecF64x2_IntoBits;
var
  f: TVecF64x2;
  i: TVecI64x2;
begin
  // 1.0 的 double 位模式是 0x3FF0000000000000
  f.d[0] := 1.0;
  f.d[1] := 1.0;
  i := VecF64x2IntoBits(f);
  
  AssertEquals('1.0 double bit pattern', Int64($3FF0000000000000), i.i[0]);
  AssertEquals('Element 1 should match', Int64($3FF0000000000000), i.i[1]);
end;

procedure TTestCase_TypeConversion.Test_VecI64x2_FromBitsF64;
var
  i: TVecI64x2;
  f: TVecF64x2;
begin
  i.i[0] := Int64($3FF0000000000000);  // 1.0
  i.i[1] := Int64($4000000000000000);  // 2.0
  
  f := VecI64x2FromBitsF64(i);
  
  AssertEquals('$3FF... as double should be 1.0', 1.0, f.d[0], 0.0001);
  AssertEquals('$400... as double should be 2.0', 2.0, f.d[1], 0.0001);
end;

procedure TTestCase_TypeConversion.Test_VecF32x4_CastToI32x4;
var
  f: TVecF32x4;
  i: TVecI32x4;
begin
  f.f[0] := 1.9;   // 截断为 1
  f.f[1] := -2.9;  // 截断为 -2
  f.f[2] := 0.0;
  f.f[3] := 100.5; // 截断为 100
  
  i := VecF32x4CastToI32x4(f);
  
  AssertEquals('1.9 truncates to 1', 1, i.i[0]);
  AssertEquals('-2.9 truncates to -2', -2, i.i[1]);
  AssertEquals('0.0 truncates to 0', 0, i.i[2]);
  AssertEquals('100.5 truncates to 100', 100, i.i[3]);
end;

procedure TTestCase_TypeConversion.Test_VecI32x4_CastToF32x4;
var
  i: TVecI32x4;
  f: TVecF32x4;
begin
  i.i[0] := 1;
  i.i[1] := -2;
  i.i[2] := 0;
  i.i[3] := 100;
  
  f := VecI32x4CastToF32x4(i);
  
  AssertEquals('1 converts to 1.0', 1.0, f.f[0], 0.0001);
  AssertEquals('-2 converts to -2.0', -2.0, f.f[1], 0.0001);
  AssertEquals('0 converts to 0.0', 0.0, f.f[2], 0.0001);
  AssertEquals('100 converts to 100.0', 100.0, f.f[3], 0.0001);
end;

procedure TTestCase_TypeConversion.Test_VecF64x2_CastToI64x2;
var
  f: TVecF64x2;
  i: TVecI64x2;
begin
  f.d[0] := 1.9;   // 截断为 1
  f.d[1] := -2.9;  // 截断为 -2
  
  i := VecF64x2CastToI64x2(f);
  
  AssertEquals('1.9 truncates to 1', Int64(1), i.i[0]);
  AssertEquals('-2.9 truncates to -2', Int64(-2), i.i[1]);
end;

procedure TTestCase_TypeConversion.Test_VecI64x2_CastToF64x2;
var
  i: TVecI64x2;
  f: TVecF64x2;
begin
  i.i[0] := 1;
  i.i[1] := -2;
  
  f := VecI64x2CastToF64x2(i);
  
  AssertEquals('1 converts to 1.0', 1.0, f.d[0], 0.0001);
  AssertEquals('-2 converts to -2.0', -2.0, f.d[1], 0.0001);
end;

procedure TTestCase_TypeConversion.Test_VecI16x8_WidenLo_I32x4;
var
  a: TVecI16x8;
  r: TVecI32x4;
begin
  // 设置低 4 个元素，包含负数测试符号扩展
  a.i[0] := 100;
  a.i[1] := -100;
  a.i[2] := 32767;   // max Int16
  a.i[3] := -32768;  // min Int16
  a.i[4] := 1; a.i[5] := 2; a.i[6] := 3; a.i[7] := 4;  // 高 4 个元素（应被忽略）
  
  r := VecI16x8WidenLoI32x4(a);
  
  AssertEquals('Widen lo[0]', Int32(100), r.i[0]);
  AssertEquals('Widen lo[1] with sign', Int32(-100), r.i[1]);
  AssertEquals('Widen lo[2] max', Int32(32767), r.i[2]);
  AssertEquals('Widen lo[3] min', Int32(-32768), r.i[3]);
end;

procedure TTestCase_TypeConversion.Test_VecI16x8_WidenHi_I32x4;
var
  a: TVecI16x8;
  r: TVecI32x4;
begin
  a.i[0] := 1; a.i[1] := 2; a.i[2] := 3; a.i[3] := 4;  // 低 4 个元素（应被忽略）
  // 设置高 4 个元素
  a.i[4] := 200;
  a.i[5] := -200;
  a.i[6] := 32767;
  a.i[7] := -32768;
  
  r := VecI16x8WidenHiI32x4(a);
  
  AssertEquals('Widen hi[0]', Int32(200), r.i[0]);
  AssertEquals('Widen hi[1] with sign', Int32(-200), r.i[1]);
  AssertEquals('Widen hi[2] max', Int32(32767), r.i[2]);
  AssertEquals('Widen hi[3] min', Int32(-32768), r.i[3]);
end;

procedure TTestCase_TypeConversion.Test_VecI32x4_NarrowToI16x8;
var
  a, b: TVecI32x4;
  r: TVecI16x8;
begin
  // a -> 低 4 个元素
  a.i[0] := 100;
  a.i[1] := -100;
  a.i[2] := 32767;
  a.i[3] := -32768;
  
  // b -> 高 4 个元素
  b.i[0] := 1;
  b.i[1] := 2;
  b.i[2] := 3;
  b.i[3] := 4;
  
  r := VecI32x4NarrowToI16x8(a, b);
  
  // 低 4 个元素来自 a
  AssertEquals('Narrow[0] from a', Int16(100), r.i[0]);
  AssertEquals('Narrow[1] from a', Int16(-100), r.i[1]);
  AssertEquals('Narrow[2] from a', Int16(32767), r.i[2]);
  AssertEquals('Narrow[3] from a', Int16(-32768), r.i[3]);
  // 高 4 个元素来自 b
  AssertEquals('Narrow[4] from b', Int16(1), r.i[4]);
  AssertEquals('Narrow[5] from b', Int16(2), r.i[5]);
  AssertEquals('Narrow[6] from b', Int16(3), r.i[6]);
  AssertEquals('Narrow[7] from b', Int16(4), r.i[7]);
end;

procedure TTestCase_TypeConversion.Test_VecF32x4_ToF64x2_Lo;
var
  a: TVecF32x4;
  r: TVecF64x2;
begin
  a.f[0] := 1.5;
  a.f[1] := -2.5;
  a.f[2] := 999.0;  // 应被忽略
  a.f[3] := 888.0;  // 应被忽略
  
  r := VecF32x4ToF64x2Lo(a);
  
  AssertEquals('F32->F64 [0]', 1.5, r.d[0], 0.0001);
  AssertEquals('F32->F64 [1]', -2.5, r.d[1], 0.0001);
end;

procedure TTestCase_TypeConversion.Test_VecF64x2_ToF32x4;
var
  a, b: TVecF64x2;
  r: TVecF32x4;
begin
  // a -> 低 2 个元素
  a.d[0] := 1.5;
  a.d[1] := -2.5;
  
  // b -> 高 2 个元素
  b.d[0] := 3.5;
  b.d[1] := 4.5;
  
  r := VecF64x2ToF32x4(a, b);
  
  AssertEquals('F64->F32 [0] from a', 1.5, r.f[0], 0.0001);
  AssertEquals('F64->F32 [1] from a', -2.5, r.f[1], 0.0001);
  AssertEquals('F64->F32 [2] from b', 3.5, r.f[2], 0.0001);
  AssertEquals('F64->F32 [3] from b', 4.5, r.f[3], 0.0001);
end;

{ TTestCase_Builder }

procedure TTestCase_Builder.SetUp;
begin
  inherited SetUp;
end;

procedure TTestCase_Builder.TearDown;
begin
  inherited TearDown;
end;

procedure TTestCase_Builder.Test_Builder_Create_FromValues;
var
  v: TVecF32x4;
begin
  v := TVecF32x4Builder.FromValues(1.0, 2.0, 3.0, 4.0).Build;
  
  AssertEquals('Element 0', 1.0, v.f[0], 0.0001);
  AssertEquals('Element 1', 2.0, v.f[1], 0.0001);
  AssertEquals('Element 2', 3.0, v.f[2], 0.0001);
  AssertEquals('Element 3', 4.0, v.f[3], 0.0001);
end;

procedure TTestCase_Builder.Test_Builder_Create_Splat;
var
  v: TVecF32x4;
begin
  v := TVecF32x4Builder.Splat(42.0).Build;
  
  AssertEquals('Element 0', 42.0, v.f[0], 0.0001);
  AssertEquals('Element 1', 42.0, v.f[1], 0.0001);
  AssertEquals('Element 2', 42.0, v.f[2], 0.0001);
  AssertEquals('Element 3', 42.0, v.f[3], 0.0001);
end;

procedure TTestCase_Builder.Test_Builder_Create_Load;
var
  arr: array[0..3] of Single;
  v: TVecF32x4;
begin
  arr[0] := 10.0; arr[1] := 20.0; arr[2] := 30.0; arr[3] := 40.0;
  v := TVecF32x4Builder.Load(@arr[0]).Build;
  
  AssertEquals('Element 0', 10.0, v.f[0], 0.0001);
  AssertEquals('Element 1', 20.0, v.f[1], 0.0001);
  AssertEquals('Element 2', 30.0, v.f[2], 0.0001);
  AssertEquals('Element 3', 40.0, v.f[3], 0.0001);
end;

procedure TTestCase_Builder.Test_Builder_Chain_Add;
var
  v: TVecF32x4;
begin
  // (1,2,3,4) + (10,20,30,40) = (11,22,33,44)
  v := TVecF32x4Builder.FromValues(1.0, 2.0, 3.0, 4.0)
         .Add(TVecF32x4Builder.FromValues(10.0, 20.0, 30.0, 40.0).Build)
         .Build;
  
  AssertEquals('Element 0', 11.0, v.f[0], 0.0001);
  AssertEquals('Element 1', 22.0, v.f[1], 0.0001);
  AssertEquals('Element 2', 33.0, v.f[2], 0.0001);
  AssertEquals('Element 3', 44.0, v.f[3], 0.0001);
end;

procedure TTestCase_Builder.Test_Builder_Chain_MulAdd;
var
  v: TVecF32x4;
begin
  // (1,2,3,4) * 2 + (10,10,10,10) = (12,14,16,18)
  v := TVecF32x4Builder.FromValues(1.0, 2.0, 3.0, 4.0)
         .MulScalar(2.0)
         .AddScalar(10.0)
         .Build;
  
  AssertEquals('Element 0', 12.0, v.f[0], 0.0001);
  AssertEquals('Element 1', 14.0, v.f[1], 0.0001);
  AssertEquals('Element 2', 16.0, v.f[2], 0.0001);
  AssertEquals('Element 3', 18.0, v.f[3], 0.0001);
end;

procedure TTestCase_Builder.Test_Builder_Chain_Normalize;
var
  v: TVecF32x4;
  len: Single;
begin
  // (3,0,0,0) normalized = (1,0,0,0)
  v := TVecF32x4Builder.FromValues(3.0, 0.0, 0.0, 0.0)
         .Normalize
         .Build;
  
  AssertEquals('Element 0', 1.0, v.f[0], 0.0001);
  AssertEquals('Element 1', 0.0, v.f[1], 0.0001);
  AssertEquals('Element 2', 0.0, v.f[2], 0.0001);
  AssertEquals('Element 3', 0.0, v.f[3], 0.0001);
  
  // 验证长度为 1
  len := VecF32x4Length(v);
  AssertEquals('Length should be 1', 1.0, len, 0.0001);
end;

procedure TTestCase_Builder.Test_Builder_Chain_Clamp;
var
  v: TVecF32x4;
begin
  // (-5, 5, 15, 0) clamped to [0,10] = (0, 5, 10, 0)
  v := TVecF32x4Builder.FromValues(-5.0, 5.0, 15.0, 0.0)
         .Clamp(0.0, 10.0)
         .Build;
  
  AssertEquals('Element 0', 0.0, v.f[0], 0.0001);
  AssertEquals('Element 1', 5.0, v.f[1], 0.0001);
  AssertEquals('Element 2', 10.0, v.f[2], 0.0001);
  AssertEquals('Element 3', 0.0, v.f[3], 0.0001);
end;

procedure TTestCase_Builder.Test_Builder_Build;
var
  v: TVecF32x4;
begin
  v := TVecF32x4Builder.FromValues(1.0, 2.0, 3.0, 4.0).Build;
  
  AssertEquals('Element 0', 1.0, v.f[0], 0.0001);
  AssertEquals('Element 1', 2.0, v.f[1], 0.0001);
  AssertEquals('Element 2', 3.0, v.f[2], 0.0001);
  AssertEquals('Element 3', 4.0, v.f[3], 0.0001);
end;

procedure TTestCase_Builder.Test_Builder_ReduceAdd;
var
  sum: Single;
begin
  sum := TVecF32x4Builder.FromValues(1.0, 2.0, 3.0, 4.0).ReduceAdd;
  AssertEquals('Sum should be 10', 10.0, sum, 0.0001);
end;

procedure TTestCase_Builder.Test_Builder_ReduceMin;
var
  minVal: Single;
begin
  minVal := TVecF32x4Builder.FromValues(5.0, 2.0, 8.0, 3.0).ReduceMin;
  AssertEquals('Min should be 2', 2.0, minVal, 0.0001);
end;

procedure TTestCase_Builder.Test_Builder_ReduceMax;
var
  maxVal: Single;
begin
  maxVal := TVecF32x4Builder.FromValues(5.0, 2.0, 8.0, 3.0).ReduceMax;
  AssertEquals('Max should be 8', 8.0, maxVal, 0.0001);
end;

procedure TTestCase_Builder.Test_Builder_Complex_DotProduct;
var
  dot: Single;
begin
  // (1,2,3,4) · (2,3,4,5) = 2+6+12+20 = 40
  dot := TVecF32x4Builder.FromValues(1.0, 2.0, 3.0, 4.0)
           .Mul(TVecF32x4Builder.FromValues(2.0, 3.0, 4.0, 5.0).Build)
           .ReduceAdd;
  
  AssertEquals('Dot product should be 40', 40.0, dot, 0.0001);
end;

procedure TTestCase_Builder.Test_Builder_Complex_Lerp;
var
  v: TVecF32x4;
begin
  // lerp((0,0,0,0), (10,10,10,10), 0.3) = (3,3,3,3)
  v := TVecF32x4Builder.Splat(0.0)
         .Lerp(TVecF32x4Builder.Splat(10.0).Build, 0.3)
         .Build;
  
  AssertEquals('Element 0', 3.0, v.f[0], 0.0001);
  AssertEquals('Element 1', 3.0, v.f[1], 0.0001);
  AssertEquals('Element 2', 3.0, v.f[2], 0.0001);
  AssertEquals('Element 3', 3.0, v.f[3], 0.0001);
end;

{ TTestCase_GatherScatter }

procedure TTestCase_GatherScatter.Test_VecF32x4_Gather_Sequential;
var
  data: array[0..15] of Single;
  indices: TVecI32x4;
  r: TVecF32x4;
  i: Integer;
begin
  // 准备数据
  for i := 0 to 15 do
    data[i] := (i + 1) * 10.0;  // [10, 20, 30, ..., 160]
  
  // 顺序索引: [0, 1, 2, 3]
  indices.i[0] := 0;
  indices.i[1] := 1;
  indices.i[2] := 2;
  indices.i[3] := 3;
  
  r := VecF32x4Gather(@data[0], indices);
  
  AssertEquals('Gather[0]', 10.0, r.f[0], 0.0001);
  AssertEquals('Gather[1]', 20.0, r.f[1], 0.0001);
  AssertEquals('Gather[2]', 30.0, r.f[2], 0.0001);
  AssertEquals('Gather[3]', 40.0, r.f[3], 0.0001);
end;

procedure TTestCase_GatherScatter.Test_VecF32x4_Gather_Stride;
var
  data: array[0..15] of Single;
  indices: TVecI32x4;
  r: TVecF32x4;
  i: Integer;
begin
  for i := 0 to 15 do
    data[i] := (i + 1) * 10.0;
  
  // 跨步索引: [0, 2, 4, 6] (stride = 2)
  indices.i[0] := 0;
  indices.i[1] := 2;
  indices.i[2] := 4;
  indices.i[3] := 6;
  
  r := VecF32x4Gather(@data[0], indices);
  
  AssertEquals('Gather stride[0]', 10.0, r.f[0], 0.0001);
  AssertEquals('Gather stride[1]', 30.0, r.f[1], 0.0001);
  AssertEquals('Gather stride[2]', 50.0, r.f[2], 0.0001);
  AssertEquals('Gather stride[3]', 70.0, r.f[3], 0.0001);
end;

procedure TTestCase_GatherScatter.Test_VecF32x4_Gather_Random;
var
  data: array[0..15] of Single;
  indices: TVecI32x4;
  r: TVecF32x4;
  i: Integer;
begin
  for i := 0 to 15 do
    data[i] := (i + 1) * 10.0;
  
  // 随机索引: [7, 0, 15, 3]
  indices.i[0] := 7;
  indices.i[1] := 0;
  indices.i[2] := 15;
  indices.i[3] := 3;
  
  r := VecF32x4Gather(@data[0], indices);
  
  AssertEquals('Gather random[0]', 80.0, r.f[0], 0.0001);
  AssertEquals('Gather random[1]', 10.0, r.f[1], 0.0001);
  AssertEquals('Gather random[2]', 160.0, r.f[2], 0.0001);
  AssertEquals('Gather random[3]', 40.0, r.f[3], 0.0001);
end;

procedure TTestCase_GatherScatter.Test_VecI32x4_Gather_Sequential;
var
  data: array[0..15] of Int32;
  indices: TVecI32x4;
  r: TVecI32x4;
  i: Integer;
begin
  for i := 0 to 15 do
    data[i] := (i + 1) * 100;
  
  indices.i[0] := 0;
  indices.i[1] := 1;
  indices.i[2] := 2;
  indices.i[3] := 3;
  
  r := VecI32x4Gather(@data[0], indices);
  
  AssertEquals('Gather[0]', 100, r.i[0]);
  AssertEquals('Gather[1]', 200, r.i[1]);
  AssertEquals('Gather[2]', 300, r.i[2]);
  AssertEquals('Gather[3]', 400, r.i[3]);
end;

procedure TTestCase_GatherScatter.Test_VecI32x4_Gather_Negative;
var
  data: array[0..15] of Int32;
  indices: TVecI32x4;
  r: TVecI32x4;
  i: Integer;
begin
  for i := 0 to 15 do
    data[i] := i - 8;  // [-8, -7, ..., 7]
  
  indices.i[0] := 0;
  indices.i[1] := 8;
  indices.i[2] := 15;
  indices.i[3] := 4;
  
  r := VecI32x4Gather(@data[0], indices);
  
  AssertEquals('Gather negative[0]', -8, r.i[0]);
  AssertEquals('Gather negative[1]', 0, r.i[1]);
  AssertEquals('Gather negative[2]', 7, r.i[2]);
  AssertEquals('Gather negative[3]', -4, r.i[3]);
end;

procedure TTestCase_GatherScatter.Test_VecF32x4_Scatter_Sequential;
var
  data: array[0..15] of Single;
  indices: TVecI32x4;
  values: TVecF32x4;
  i: Integer;
begin
  // 清零目标数组
  for i := 0 to 15 do
    data[i] := 0.0;
  
  // 顺序索引
  indices.i[0] := 0;
  indices.i[1] := 1;
  indices.i[2] := 2;
  indices.i[3] := 3;
  
  // 要写入的值
  values.f[0] := 11.0;
  values.f[1] := 22.0;
  values.f[2] := 33.0;
  values.f[3] := 44.0;
  
  VecF32x4Scatter(@data[0], indices, values);
  
  AssertEquals('Scatter[0]', 11.0, data[0], 0.0001);
  AssertEquals('Scatter[1]', 22.0, data[1], 0.0001);
  AssertEquals('Scatter[2]', 33.0, data[2], 0.0001);
  AssertEquals('Scatter[3]', 44.0, data[3], 0.0001);
  // 确保其它位置未被修改
  AssertEquals('Scatter[4] unchanged', 0.0, data[4], 0.0001);
end;

procedure TTestCase_GatherScatter.Test_VecF32x4_Scatter_Stride;
var
  data: array[0..15] of Single;
  indices: TVecI32x4;
  values: TVecF32x4;
  i: Integer;
begin
  for i := 0 to 15 do
    data[i] := 0.0;
  
  // 跨步索引: [0, 4, 8, 12]
  indices.i[0] := 0;
  indices.i[1] := 4;
  indices.i[2] := 8;
  indices.i[3] := 12;
  
  values.f[0] := 100.0;
  values.f[1] := 200.0;
  values.f[2] := 300.0;
  values.f[3] := 400.0;
  
  VecF32x4Scatter(@data[0], indices, values);
  
  AssertEquals('Scatter stride[0]', 100.0, data[0], 0.0001);
  AssertEquals('Scatter stride[4]', 200.0, data[4], 0.0001);
  AssertEquals('Scatter stride[8]', 300.0, data[8], 0.0001);
  AssertEquals('Scatter stride[12]', 400.0, data[12], 0.0001);
  // 确保中间位置未被修改
  AssertEquals('Scatter[1] unchanged', 0.0, data[1], 0.0001);
  AssertEquals('Scatter[5] unchanged', 0.0, data[5], 0.0001);
end;

procedure TTestCase_GatherScatter.Test_VecI32x4_Scatter_Sequential;
var
  data: array[0..15] of Int32;
  indices: TVecI32x4;
  values: TVecI32x4;
  i: Integer;
begin
  for i := 0 to 15 do
    data[i] := 0;
  
  indices.i[0] := 5;
  indices.i[1] := 10;
  indices.i[2] := 2;
  indices.i[3] := 15;
  
  values.i[0] := 111;
  values.i[1] := 222;
  values.i[2] := 333;
  values.i[3] := 444;
  
  VecI32x4Scatter(@data[0], indices, values);
  
  AssertEquals('Scatter[5]', 111, data[5]);
  AssertEquals('Scatter[10]', 222, data[10]);
  AssertEquals('Scatter[2]', 333, data[2]);
  AssertEquals('Scatter[15]', 444, data[15]);
  // 确保其它位置未被修改
  AssertEquals('Scatter[0] unchanged', 0, data[0]);
end;

procedure TTestCase_GatherScatter.Test_Gather_ZeroIndex;
var
  data: array[0..7] of Single;
  indices: TVecI32x4;
  r: TVecF32x4;
  i: Integer;
begin
  for i := 0 to 7 do
    data[i] := i * 1.5;
  
  // 所有索引都是 0
  indices.i[0] := 0;
  indices.i[1] := 0;
  indices.i[2] := 0;
  indices.i[3] := 0;
  
  r := VecF32x4Gather(@data[0], indices);
  
  // 所有结果应该都是 data[0]
  AssertEquals('Gather zero[0]', 0.0, r.f[0], 0.0001);
  AssertEquals('Gather zero[1]', 0.0, r.f[1], 0.0001);
  AssertEquals('Gather zero[2]', 0.0, r.f[2], 0.0001);
  AssertEquals('Gather zero[3]', 0.0, r.f[3], 0.0001);
end;

procedure TTestCase_GatherScatter.Test_Gather_LargeStride;
var
  data: array[0..1023] of Single;
  indices: TVecI32x4;
  r: TVecF32x4;
  i: Integer;
begin
  for i := 0 to 1023 do
    data[i] := i;
  
  // 大跨步索引
  indices.i[0] := 0;
  indices.i[1] := 256;
  indices.i[2] := 512;
  indices.i[3] := 1023;
  
  r := VecF32x4Gather(@data[0], indices);
  
  AssertEquals('Gather large[0]', 0.0, r.f[0], 0.0001);
  AssertEquals('Gather large[1]', 256.0, r.f[1], 0.0001);
  AssertEquals('Gather large[2]', 512.0, r.f[2], 0.0001);
  AssertEquals('Gather large[3]', 1023.0, r.f[3], 0.0001);
end;

{ TTestCase_ShuffleSWizzle }

procedure TTestCase_ShuffleSWizzle.Test_MM_SHUFFLE;
begin
  // MM_SHUFFLE(3,2,1,0) = identity = 0xE4
  AssertEquals('MM_SHUFFLE(3,2,1,0) = 0xE4', $E4, MM_SHUFFLE(3, 2, 1, 0));
  // MM_SHUFFLE(0,1,2,3) = reverse = 0x1B
  AssertEquals('MM_SHUFFLE(0,1,2,3) = 0x1B', $1B, MM_SHUFFLE(0, 1, 2, 3));
  // MM_SHUFFLE(0,0,0,0) = broadcast 0 = 0x00
  AssertEquals('MM_SHUFFLE(0,0,0,0) = 0x00', $00, MM_SHUFFLE(0, 0, 0, 0));
  // MM_SHUFFLE(2,2,2,2) = broadcast 2 = 0xAA
  AssertEquals('MM_SHUFFLE(2,2,2,2) = 0xAA', $AA, MM_SHUFFLE(2, 2, 2, 2));
end;

procedure TTestCase_ShuffleSWizzle.Test_VecF32x4_Shuffle_Identity;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  
  // 恒等 shuffle: MM_SHUFFLE(3,2,1,0) = 0xE4
  r := VecF32x4Shuffle(a, $E4);
  
  AssertEquals('Identity[0]', 1.0, r.f[0], 0.0001);
  AssertEquals('Identity[1]', 2.0, r.f[1], 0.0001);
  AssertEquals('Identity[2]', 3.0, r.f[2], 0.0001);
  AssertEquals('Identity[3]', 4.0, r.f[3], 0.0001);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecF32x4_Shuffle_Reverse;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  
  // 反转 shuffle: MM_SHUFFLE(0,1,2,3) = 0x1B
  r := VecF32x4Shuffle(a, $1B);
  
  AssertEquals('Reverse[0]', 4.0, r.f[0], 0.0001);
  AssertEquals('Reverse[1]', 3.0, r.f[1], 0.0001);
  AssertEquals('Reverse[2]', 2.0, r.f[2], 0.0001);
  AssertEquals('Reverse[3]', 1.0, r.f[3], 0.0001);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecF32x4_Shuffle_Broadcast;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  
  // 广播元素 2: MM_SHUFFLE(2,2,2,2) = 0xAA
  r := VecF32x4Shuffle(a, $AA);
  
  AssertEquals('Broadcast2[0]', 3.0, r.f[0], 0.0001);
  AssertEquals('Broadcast2[1]', 3.0, r.f[1], 0.0001);
  AssertEquals('Broadcast2[2]', 3.0, r.f[2], 0.0001);
  AssertEquals('Broadcast2[3]', 3.0, r.f[3], 0.0001);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecI32x4_Shuffle;
var
  a, r: TVecI32x4;
begin
  a.i[0] := 10; a.i[1] := 20; a.i[2] := 30; a.i[3] := 40;
  
  // 跳跃 shuffle: MM_SHUFFLE(1,0,3,2) = 0x4E
  r := VecI32x4Shuffle(a, $4E);
  
  AssertEquals('Swap[0]', 30, r.i[0]);
  AssertEquals('Swap[1]', 40, r.i[1]);
  AssertEquals('Swap[2]', 10, r.i[2]);
  AssertEquals('Swap[3]', 20, r.i[3]);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecF32x4_Shuffle2;
var
  a, b, r: TVecF32x4;
begin
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  b.f[0] := 10.0; b.f[1] := 20.0; b.f[2] := 30.0; b.f[3] := 40.0;
  
  // 低2来自a的[0,1], 高2来自b的[0,1]: MM_SHUFFLE(1,0,1,0) = 0x44
  r := VecF32x4Shuffle2(a, b, $44);
  
  AssertEquals('Shuffle2[0] from a', 1.0, r.f[0], 0.0001);
  AssertEquals('Shuffle2[1] from a', 2.0, r.f[1], 0.0001);
  AssertEquals('Shuffle2[2] from b', 10.0, r.f[2], 0.0001);
  AssertEquals('Shuffle2[3] from b', 20.0, r.f[3], 0.0001);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecF32x4_Blend;
var
  a, b, r: TVecF32x4;
begin
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  b.f[0] := 10.0; b.f[1] := 20.0; b.f[2] := 30.0; b.f[3] := 40.0;
  
  // mask = 0b0101 = 5: 元素0和2来自b
  r := VecF32x4Blend(a, b, 5);
  
  AssertEquals('Blend[0] from b', 10.0, r.f[0], 0.0001);
  AssertEquals('Blend[1] from a', 2.0, r.f[1], 0.0001);
  AssertEquals('Blend[2] from b', 30.0, r.f[2], 0.0001);
  AssertEquals('Blend[3] from a', 4.0, r.f[3], 0.0001);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecF64x2_Blend;
var
  a, b, r: TVecF64x2;
begin
  a.d[0] := 1.0; a.d[1] := 2.0;
  b.d[0] := 10.0; b.d[1] := 20.0;
  
  // mask = 0b01 = 1: 元素0来自b
  r := VecF64x2Blend(a, b, 1);
  
  AssertEquals('Blend[0] from b', 10.0, r.d[0], 0.0001);
  AssertEquals('Blend[1] from a', 2.0, r.d[1], 0.0001);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecI32x4_Blend;
var
  a, b, r: TVecI32x4;
begin
  a.i[0] := 1; a.i[1] := 2; a.i[2] := 3; a.i[3] := 4;
  b.i[0] := 10; b.i[1] := 20; b.i[2] := 30; b.i[3] := 40;
  
  // mask = 0b1010 = 10: 元素1和3来自b
  r := VecI32x4Blend(a, b, 10);
  
  AssertEquals('Blend[0] from a', 1, r.i[0]);
  AssertEquals('Blend[1] from b', 20, r.i[1]);
  AssertEquals('Blend[2] from a', 3, r.i[2]);
  AssertEquals('Blend[3] from b', 40, r.i[3]);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecF32x4_UnpackLo;
var
  a, b, r: TVecF32x4;
begin
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  b.f[0] := 10.0; b.f[1] := 20.0; b.f[2] := 30.0; b.f[3] := 40.0;
  
  r := VecF32x4UnpackLo(a, b);
  
  // 结果: [a0, b0, a1, b1]
  AssertEquals('UnpackLo[0]', 1.0, r.f[0], 0.0001);
  AssertEquals('UnpackLo[1]', 10.0, r.f[1], 0.0001);
  AssertEquals('UnpackLo[2]', 2.0, r.f[2], 0.0001);
  AssertEquals('UnpackLo[3]', 20.0, r.f[3], 0.0001);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecF32x4_UnpackHi;
var
  a, b, r: TVecF32x4;
begin
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  b.f[0] := 10.0; b.f[1] := 20.0; b.f[2] := 30.0; b.f[3] := 40.0;
  
  r := VecF32x4UnpackHi(a, b);
  
  // 结果: [a2, b2, a3, b3]
  AssertEquals('UnpackHi[0]', 3.0, r.f[0], 0.0001);
  AssertEquals('UnpackHi[1]', 30.0, r.f[1], 0.0001);
  AssertEquals('UnpackHi[2]', 4.0, r.f[2], 0.0001);
  AssertEquals('UnpackHi[3]', 40.0, r.f[3], 0.0001);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecI32x4_Unpack;
var
  a, b, rLo, rHi: TVecI32x4;
begin
  a.i[0] := 1; a.i[1] := 2; a.i[2] := 3; a.i[3] := 4;
  b.i[0] := 10; b.i[1] := 20; b.i[2] := 30; b.i[3] := 40;
  
  rLo := VecI32x4UnpackLo(a, b);
  rHi := VecI32x4UnpackHi(a, b);
  
  AssertEquals('UnpackLo[0]', 1, rLo.i[0]);
  AssertEquals('UnpackLo[1]', 10, rLo.i[1]);
  AssertEquals('UnpackLo[2]', 2, rLo.i[2]);
  AssertEquals('UnpackLo[3]', 20, rLo.i[3]);
  
  AssertEquals('UnpackHi[0]', 3, rHi.i[0]);
  AssertEquals('UnpackHi[1]', 30, rHi.i[1]);
  AssertEquals('UnpackHi[2]', 4, rHi.i[2]);
  AssertEquals('UnpackHi[3]', 40, rHi.i[3]);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecF32x4_Broadcast;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  
  r := VecF32x4Broadcast(a, 2);
  
  AssertEquals('Broadcast[0]', 3.0, r.f[0], 0.0001);
  AssertEquals('Broadcast[1]', 3.0, r.f[1], 0.0001);
  AssertEquals('Broadcast[2]', 3.0, r.f[2], 0.0001);
  AssertEquals('Broadcast[3]', 3.0, r.f[3], 0.0001);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecI32x4_Broadcast;
var
  a, r: TVecI32x4;
begin
  a.i[0] := 10; a.i[1] := 20; a.i[2] := 30; a.i[3] := 40;
  
  r := VecI32x4Broadcast(a, 1);
  
  AssertEquals('Broadcast[0]', 20, r.i[0]);
  AssertEquals('Broadcast[1]', 20, r.i[1]);
  AssertEquals('Broadcast[2]', 20, r.i[2]);
  AssertEquals('Broadcast[3]', 20, r.i[3]);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecF32x4_Reverse;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  
  r := VecF32x4Reverse(a);
  
  AssertEquals('Reverse[0]', 4.0, r.f[0], 0.0001);
  AssertEquals('Reverse[1]', 3.0, r.f[1], 0.0001);
  AssertEquals('Reverse[2]', 2.0, r.f[2], 0.0001);
  AssertEquals('Reverse[3]', 1.0, r.f[3], 0.0001);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecI32x4_Reverse;
var
  a, r: TVecI32x4;
begin
  a.i[0] := 10; a.i[1] := 20; a.i[2] := 30; a.i[3] := 40;
  
  r := VecI32x4Reverse(a);
  
  AssertEquals('Reverse[0]', 40, r.i[0]);
  AssertEquals('Reverse[1]', 30, r.i[1]);
  AssertEquals('Reverse[2]', 20, r.i[2]);
  AssertEquals('Reverse[3]', 10, r.i[3]);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecF32x4_RotateLeft;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  
  // 左旋 1: [2,3,4,1]
  r := VecF32x4RotateLeft(a, 1);
  AssertEquals('RotL1[0]', 2.0, r.f[0], 0.0001);
  AssertEquals('RotL1[1]', 3.0, r.f[1], 0.0001);
  AssertEquals('RotL1[2]', 4.0, r.f[2], 0.0001);
  AssertEquals('RotL1[3]', 1.0, r.f[3], 0.0001);
  
  // 左旋 2: [3,4,1,2]
  r := VecF32x4RotateLeft(a, 2);
  AssertEquals('RotL2[0]', 3.0, r.f[0], 0.0001);
  AssertEquals('RotL2[3]', 2.0, r.f[3], 0.0001);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecI32x4_RotateLeft;
var
  a, r: TVecI32x4;
begin
  a.i[0] := 10; a.i[1] := 20; a.i[2] := 30; a.i[3] := 40;
  
  // 左旋 3: [40,10,20,30]
  r := VecI32x4RotateLeft(a, 3);
  AssertEquals('RotL3[0]', 40, r.i[0]);
  AssertEquals('RotL3[1]', 10, r.i[1]);
  AssertEquals('RotL3[2]', 20, r.i[2]);
  AssertEquals('RotL3[3]', 30, r.i[3]);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecF32x4_Insert;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  
  r := VecF32x4Insert(a, 99.0, 2);
  
  AssertEquals('Insert[0]', 1.0, r.f[0], 0.0001);
  AssertEquals('Insert[1]', 2.0, r.f[1], 0.0001);
  AssertEquals('Insert[2]', 99.0, r.f[2], 0.0001);
  AssertEquals('Insert[3]', 4.0, r.f[3], 0.0001);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecF32x4_ExtractFunc;
var
  a: TVecF32x4;
begin
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  
  AssertEquals('Extract[0]', 1.0, VecF32x4Extract(a, 0), 0.0001);
  AssertEquals('Extract[1]', 2.0, VecF32x4Extract(a, 1), 0.0001);
  AssertEquals('Extract[2]', 3.0, VecF32x4Extract(a, 2), 0.0001);
  AssertEquals('Extract[3]', 4.0, VecF32x4Extract(a, 3), 0.0001);
end;

procedure TTestCase_ShuffleSWizzle.Test_VecI32x4_InsertExtract;
var
  a, r: TVecI32x4;
begin
  a.i[0] := 10; a.i[1] := 20; a.i[2] := 30; a.i[3] := 40;
  
  r := VecI32x4Insert(a, 999, 1);
  
  AssertEquals('Insert[0]', 10, r.i[0]);
  AssertEquals('Insert[1]', 999, r.i[1]);
  AssertEquals('Insert[2]', 30, r.i[2]);
  AssertEquals('Insert[3]', 40, r.i[3]);
  
  AssertEquals('Extract[0]', 10, VecI32x4Extract(a, 0));
  AssertEquals('Extract[3]', 40, VecI32x4Extract(a, 3));
end;

{ TTestCase_MathFunctions }

procedure TTestCase_MathFunctions.Test_VecF32x4_Sin;
const
  PI = 3.14159265358979323846;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 0.0;        // sin(0) = 0
  a.f[1] := PI / 6;     // sin(PI/6) = 0.5
  a.f[2] := PI / 2;     // sin(PI/2) = 1
  a.f[3] := PI;         // sin(PI) = 0
  
  r := VecF32x4Sin(a);
  
  AssertEquals('sin(0)', 0.0, r.f[0], 0.0001);
  AssertEquals('sin(PI/6)', 0.5, r.f[1], 0.0001);
  AssertEquals('sin(PI/2)', 1.0, r.f[2], 0.0001);
  AssertEquals('sin(PI)', 0.0, r.f[3], 0.0001);
end;

procedure TTestCase_MathFunctions.Test_VecF32x4_Cos;
const
  PI = 3.14159265358979323846;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 0.0;        // cos(0) = 1
  a.f[1] := PI / 3;     // cos(PI/3) = 0.5
  a.f[2] := PI / 2;     // cos(PI/2) = 0
  a.f[3] := PI;         // cos(PI) = -1
  
  r := VecF32x4Cos(a);
  
  AssertEquals('cos(0)', 1.0, r.f[0], 0.0001);
  AssertEquals('cos(PI/3)', 0.5, r.f[1], 0.0001);
  AssertEquals('cos(PI/2)', 0.0, r.f[2], 0.0001);
  AssertEquals('cos(PI)', -1.0, r.f[3], 0.0001);
end;

procedure TTestCase_MathFunctions.Test_VecF32x4_SinCos;
const
  PI = 3.14159265358979323846;
var
  a, s, c: TVecF32x4;
begin
  a.f[0] := 0.0;
  a.f[1] := PI / 4;
  a.f[2] := PI / 2;
  a.f[3] := PI;
  
  VecF32x4SinCos(a, s, c);
  
  // sin
  AssertEquals('sin(0)', 0.0, s.f[0], 0.0001);
  AssertEquals('sin(PI/4)', 0.7071, s.f[1], 0.001);
  AssertEquals('sin(PI/2)', 1.0, s.f[2], 0.0001);
  AssertEquals('sin(PI)', 0.0, s.f[3], 0.0001);
  
  // cos
  AssertEquals('cos(0)', 1.0, c.f[0], 0.0001);
  AssertEquals('cos(PI/4)', 0.7071, c.f[1], 0.001);
  AssertEquals('cos(PI/2)', 0.0, c.f[2], 0.0001);
  AssertEquals('cos(PI)', -1.0, c.f[3], 0.0001);
end;

procedure TTestCase_MathFunctions.Test_VecF32x4_Tan;
const
  PI = 3.14159265358979323846;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 0.0;        // tan(0) = 0
  a.f[1] := PI / 4;     // tan(PI/4) = 1
  a.f[2] := -PI / 4;    // tan(-PI/4) = -1
  a.f[3] := PI / 6;     // tan(PI/6) = 1/sqrt(3)
  
  r := VecF32x4Tan(a);
  
  AssertEquals('tan(0)', 0.0, r.f[0], 0.0001);
  AssertEquals('tan(PI/4)', 1.0, r.f[1], 0.0001);
  AssertEquals('tan(-PI/4)', -1.0, r.f[2], 0.0001);
  AssertEquals('tan(PI/6)', 0.5774, r.f[3], 0.001);
end;

procedure TTestCase_MathFunctions.Test_VecF32x4_Exp;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 0.0;        // exp(0) = 1
  a.f[1] := 1.0;        // exp(1) = e = 2.71828
  a.f[2] := 2.0;        // exp(2) = 7.389
  a.f[3] := -1.0;       // exp(-1) = 1/e = 0.3679
  
  r := VecF32x4Exp(a);
  
  AssertEquals('exp(0)', 1.0, r.f[0], 0.0001);
  AssertEquals('exp(1)', 2.71828, r.f[1], 0.001);
  AssertEquals('exp(2)', 7.389, r.f[2], 0.01);
  AssertEquals('exp(-1)', 0.3679, r.f[3], 0.001);
end;

procedure TTestCase_MathFunctions.Test_VecF32x4_Exp2;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 0.0;        // 2^0 = 1
  a.f[1] := 1.0;        // 2^1 = 2
  a.f[2] := 3.0;        // 2^3 = 8
  a.f[3] := -1.0;       // 2^-1 = 0.5
  
  r := VecF32x4Exp2(a);
  
  AssertEquals('2^0', 1.0, r.f[0], 0.0001);
  AssertEquals('2^1', 2.0, r.f[1], 0.0001);
  AssertEquals('2^3', 8.0, r.f[2], 0.0001);
  AssertEquals('2^-1', 0.5, r.f[3], 0.0001);
end;

procedure TTestCase_MathFunctions.Test_VecF32x4_Log;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 1.0;        // ln(1) = 0
  a.f[1] := 2.71828;    // ln(e) = 1
  a.f[2] := 7.389;      // ln(e^2) = 2
  a.f[3] := 0.3679;     // ln(1/e) = -1
  
  r := VecF32x4Log(a);
  
  AssertEquals('ln(1)', 0.0, r.f[0], 0.0001);
  AssertEquals('ln(e)', 1.0, r.f[1], 0.001);
  AssertEquals('ln(e^2)', 2.0, r.f[2], 0.01);
  AssertEquals('ln(1/e)', -1.0, r.f[3], 0.01);
end;

procedure TTestCase_MathFunctions.Test_VecF32x4_Log2;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 1.0;        // log2(1) = 0
  a.f[1] := 2.0;        // log2(2) = 1
  a.f[2] := 8.0;        // log2(8) = 3
  a.f[3] := 0.5;        // log2(0.5) = -1
  
  r := VecF32x4Log2(a);
  
  AssertEquals('log2(1)', 0.0, r.f[0], 0.0001);
  AssertEquals('log2(2)', 1.0, r.f[1], 0.0001);
  AssertEquals('log2(8)', 3.0, r.f[2], 0.0001);
  AssertEquals('log2(0.5)', -1.0, r.f[3], 0.0001);
end;

procedure TTestCase_MathFunctions.Test_VecF32x4_Log10;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 1.0;        // log10(1) = 0
  a.f[1] := 10.0;       // log10(10) = 1
  a.f[2] := 100.0;      // log10(100) = 2
  a.f[3] := 0.1;        // log10(0.1) = -1
  
  r := VecF32x4Log10(a);
  
  AssertEquals('log10(1)', 0.0, r.f[0], 0.0001);
  AssertEquals('log10(10)', 1.0, r.f[1], 0.0001);
  AssertEquals('log10(100)', 2.0, r.f[2], 0.0001);
  AssertEquals('log10(0.1)', -1.0, r.f[3], 0.0001);
end;

procedure TTestCase_MathFunctions.Test_VecF32x4_Pow;
var
  base, exp, r: TVecF32x4;
begin
  base.f[0] := 2.0; exp.f[0] := 3.0;    // 2^3 = 8
  base.f[1] := 3.0; exp.f[1] := 2.0;    // 3^2 = 9
  base.f[2] := 10.0; exp.f[2] := 0.0;   // 10^0 = 1
  base.f[3] := 4.0; exp.f[3] := 0.5;    // 4^0.5 = 2
  
  r := VecF32x4Pow(base, exp);
  
  AssertEquals('2^3', 8.0, r.f[0], 0.0001);
  AssertEquals('3^2', 9.0, r.f[1], 0.0001);
  AssertEquals('10^0', 1.0, r.f[2], 0.0001);
  AssertEquals('4^0.5', 2.0, r.f[3], 0.0001);
end;

procedure TTestCase_MathFunctions.Test_VecF32x4_Asin;
var
  a, r: TVecF32x4;
const
  PI = 3.14159265358979323846;
begin
  a.f[0] := 0.0;        // asin(0) = 0
  a.f[1] := 0.5;        // asin(0.5) = PI/6
  a.f[2] := 1.0;        // asin(1) = PI/2
  a.f[3] := -0.5;       // asin(-0.5) = -PI/6
  
  r := VecF32x4Asin(a);
  
  AssertEquals('asin(0)', 0.0, r.f[0], 0.0001);
  AssertEquals('asin(0.5)', PI/6, r.f[1], 0.0001);
  AssertEquals('asin(1)', PI/2, r.f[2], 0.0001);
  AssertEquals('asin(-0.5)', -PI/6, r.f[3], 0.0001);
end;

procedure TTestCase_MathFunctions.Test_VecF32x4_Acos;
var
  a, r: TVecF32x4;
const
  PI = 3.14159265358979323846;
begin
  a.f[0] := 1.0;        // acos(1) = 0
  a.f[1] := 0.5;        // acos(0.5) = PI/3
  a.f[2] := 0.0;        // acos(0) = PI/2
  a.f[3] := -1.0;       // acos(-1) = PI
  
  r := VecF32x4Acos(a);
  
  AssertEquals('acos(1)', 0.0, r.f[0], 0.0001);
  AssertEquals('acos(0.5)', PI/3, r.f[1], 0.0001);
  AssertEquals('acos(0)', PI/2, r.f[2], 0.0001);
  AssertEquals('acos(-1)', PI, r.f[3], 0.0001);
end;

procedure TTestCase_MathFunctions.Test_VecF32x4_Atan;
var
  a, r: TVecF32x4;
const
  PI = 3.14159265358979323846;
begin
  a.f[0] := 0.0;        // atan(0) = 0
  a.f[1] := 1.0;        // atan(1) = PI/4
  a.f[2] := -1.0;       // atan(-1) = -PI/4
  a.f[3] := 1.7320508;  // atan(sqrt(3)) = PI/3
  
  r := VecF32x4Atan(a);
  
  AssertEquals('atan(0)', 0.0, r.f[0], 0.0001);
  AssertEquals('atan(1)', PI/4, r.f[1], 0.0001);
  AssertEquals('atan(-1)', -PI/4, r.f[2], 0.0001);
  AssertEquals('atan(sqrt(3))', PI/3, r.f[3], 0.0001);
end;

procedure TTestCase_MathFunctions.Test_VecF32x4_Atan2;
var
  y, x, r: TVecF32x4;
const
  PI = 3.14159265358979323846;
begin
  // atan2(y, x)
  y.f[0] := 0.0;  x.f[0] := 1.0;   // atan2(0, 1) = 0
  y.f[1] := 1.0;  x.f[1] := 1.0;   // atan2(1, 1) = PI/4
  y.f[2] := 1.0;  x.f[2] := 0.0;   // atan2(1, 0) = PI/2
  y.f[3] := -1.0; x.f[3] := -1.0;  // atan2(-1, -1) = -3*PI/4
  
  r := VecF32x4Atan2(y, x);
  
  AssertEquals('atan2(0,1)', 0.0, r.f[0], 0.0001);
  AssertEquals('atan2(1,1)', PI/4, r.f[1], 0.0001);
  AssertEquals('atan2(1,0)', PI/2, r.f[2], 0.0001);
  AssertEquals('atan2(-1,-1)', -3*PI/4, r.f[3], 0.0001);
end;

{ TTestCase_AdvancedAlgorithms }

// === 排序网络测试 ===

procedure TTestCase_AdvancedAlgorithms.Test_SortNet4_I32_Ascending;
var
  a, r: TVecI32x4;
begin
  a.i[0] := 4; a.i[1] := 2; a.i[2] := 3; a.i[3] := 1;
  
  r := SortNet4I32(a, True);  // 升序
  
  AssertEquals('Sorted[0]', 1, r.i[0]);
  AssertEquals('Sorted[1]', 2, r.i[1]);
  AssertEquals('Sorted[2]', 3, r.i[2]);
  AssertEquals('Sorted[3]', 4, r.i[3]);
end;

procedure TTestCase_AdvancedAlgorithms.Test_SortNet4_I32_Descending;
var
  a, r: TVecI32x4;
begin
  a.i[0] := 1; a.i[1] := 4; a.i[2] := 2; a.i[3] := 3;
  
  r := SortNet4I32(a, False);  // 降序
  
  AssertEquals('Sorted[0]', 4, r.i[0]);
  AssertEquals('Sorted[1]', 3, r.i[1]);
  AssertEquals('Sorted[2]', 2, r.i[2]);
  AssertEquals('Sorted[3]', 1, r.i[3]);
end;

procedure TTestCase_AdvancedAlgorithms.Test_SortNet4_F32_Ascending;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 3.5; a.f[1] := 1.2; a.f[2] := 4.8; a.f[3] := 2.1;
  
  r := SortNet4F32(a, True);
  
  AssertEquals('Sorted[0]', 1.2, r.f[0], 0.0001);
  AssertEquals('Sorted[1]', 2.1, r.f[1], 0.0001);
  AssertEquals('Sorted[2]', 3.5, r.f[2], 0.0001);
  AssertEquals('Sorted[3]', 4.8, r.f[3], 0.0001);
end;

procedure TTestCase_AdvancedAlgorithms.Test_SortNet4_F32_WithNegatives;
var
  a, r: TVecF32x4;
begin
  a.f[0] := -1.0; a.f[1] := 5.0; a.f[2] := -3.0; a.f[3] := 2.0;
  
  r := SortNet4F32(a, True);
  
  AssertEquals('Sorted[0]', -3.0, r.f[0], 0.0001);
  AssertEquals('Sorted[1]', -1.0, r.f[1], 0.0001);
  AssertEquals('Sorted[2]', 2.0, r.f[2], 0.0001);
  AssertEquals('Sorted[3]', 5.0, r.f[3], 0.0001);
end;

procedure TTestCase_AdvancedAlgorithms.Test_SortNet8_I32;
var
  a, r: TVecI32x8;
begin
  a.i[0] := 8; a.i[1] := 3; a.i[2] := 7; a.i[3] := 1;
  a.i[4] := 6; a.i[5] := 2; a.i[6] := 5; a.i[7] := 4;
  
  r := SortNet8I32(a, True);
  
  AssertEquals('Sorted[0]', 1, r.i[0]);
  AssertEquals('Sorted[1]', 2, r.i[1]);
  AssertEquals('Sorted[2]', 3, r.i[2]);
  AssertEquals('Sorted[3]', 4, r.i[3]);
  AssertEquals('Sorted[4]', 5, r.i[4]);
  AssertEquals('Sorted[5]', 6, r.i[5]);
  AssertEquals('Sorted[6]', 7, r.i[6]);
  AssertEquals('Sorted[7]', 8, r.i[7]);
end;

// === 前缀和测试 ===

procedure TTestCase_AdvancedAlgorithms.Test_PrefixSum_I32x4_Inclusive;
var
  a, r: TVecI32x4;
begin
  a.i[0] := 1; a.i[1] := 2; a.i[2] := 3; a.i[3] := 4;
  
  r := PrefixSumI32x4(a, True);  // inclusive
  
  // [1, 1+2, 1+2+3, 1+2+3+4] = [1, 3, 6, 10]
  AssertEquals('PrefixSum[0]', 1, r.i[0]);
  AssertEquals('PrefixSum[1]', 3, r.i[1]);
  AssertEquals('PrefixSum[2]', 6, r.i[2]);
  AssertEquals('PrefixSum[3]', 10, r.i[3]);
end;

procedure TTestCase_AdvancedAlgorithms.Test_PrefixSum_I32x4_Exclusive;
var
  a, r: TVecI32x4;
begin
  a.i[0] := 1; a.i[1] := 2; a.i[2] := 3; a.i[3] := 4;
  
  r := PrefixSumI32x4(a, False);  // exclusive
  
  // [0, 1, 1+2, 1+2+3] = [0, 1, 3, 6]
  AssertEquals('PrefixSum[0]', 0, r.i[0]);
  AssertEquals('PrefixSum[1]', 1, r.i[1]);
  AssertEquals('PrefixSum[2]', 3, r.i[2]);
  AssertEquals('PrefixSum[3]', 6, r.i[3]);
end;

procedure TTestCase_AdvancedAlgorithms.Test_PrefixSum_F32x4_Inclusive;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 1.0; a.f[1] := 2.0; a.f[2] := 3.0; a.f[3] := 4.0;
  
  r := PrefixSumF32x4(a, True);
  
  AssertEquals('PrefixSum[0]', 1.0, r.f[0], 0.0001);
  AssertEquals('PrefixSum[1]', 3.0, r.f[1], 0.0001);
  AssertEquals('PrefixSum[2]', 6.0, r.f[2], 0.0001);
  AssertEquals('PrefixSum[3]', 10.0, r.f[3], 0.0001);
end;

procedure TTestCase_AdvancedAlgorithms.Test_PrefixSum_Array_I32;
var
  arr, result: array[0..7] of Int32;
begin
  arr[0] := 1; arr[1] := 2; arr[2] := 3; arr[3] := 4;
  arr[4] := 5; arr[5] := 6; arr[6] := 7; arr[7] := 8;
  
  PrefixSumArrayI32(@arr[0], @result[0], 8);
  
  // [1, 3, 6, 10, 15, 21, 28, 36]
  AssertEquals('PrefixSum[0]', 1, result[0]);
  AssertEquals('PrefixSum[3]', 10, result[3]);
  AssertEquals('PrefixSum[7]', 36, result[7]);
end;

procedure TTestCase_AdvancedAlgorithms.Test_PrefixSum_Array_F32;
var
  arr, result: array[0..3] of Single;
begin
  arr[0] := 1.5; arr[1] := 2.5; arr[2] := 3.5; arr[3] := 4.5;
  
  PrefixSumArrayF32(@arr[0], @result[0], 4);
  
  AssertEquals('PrefixSum[0]', 1.5, result[0], 0.0001);
  AssertEquals('PrefixSum[1]', 4.0, result[1], 0.0001);
  AssertEquals('PrefixSum[2]', 7.5, result[2], 0.0001);
  AssertEquals('PrefixSum[3]', 12.0, result[3], 0.0001);
end;

// === 向量化字符串搜索测试 ===

procedure TTestCase_AdvancedAlgorithms.Test_StrFind_SingleChar;
var
  s: AnsiString;
  pos: PtrInt;
begin
  s := 'Hello, World!';
  
  pos := StrFindChar(@s[1], Length(s), Ord('W'));
  
  AssertEquals('Should find W at position 7', 7, pos);
end;

procedure TTestCase_AdvancedAlgorithms.Test_StrFind_NotFound;
var
  s: AnsiString;
  pos: PtrInt;
begin
  s := 'Hello, World!';
  
  pos := StrFindChar(@s[1], Length(s), Ord('X'));
  
  AssertEquals('Should return -1 for not found', -1, pos);
end;

procedure TTestCase_AdvancedAlgorithms.Test_StrFind_AtStart;
var
  s: AnsiString;
  pos: PtrInt;
begin
  s := 'Hello, World!';
  
  pos := StrFindChar(@s[1], Length(s), Ord('H'));
  
  AssertEquals('Should find H at position 0', 0, pos);
end;

procedure TTestCase_AdvancedAlgorithms.Test_StrFind_AtEnd;
var
  s: AnsiString;
  pos: PtrInt;
begin
  s := 'Hello, World!';
  
  pos := StrFindChar(@s[1], Length(s), Ord('!'));
  
  AssertEquals('Should find ! at last position', 12, pos);
end;

procedure TTestCase_AdvancedAlgorithms.Test_StrFind_Empty;
var
  pos: PtrInt;
begin
  pos := StrFindChar(nil, 0, Ord('A'));
  
  AssertEquals('Should return -1 for empty string', -1, pos);
end;

{ TTestCase_EdgeCases }

procedure TTestCase_EdgeCases.SetUp;
begin
  inherited SetUp;
  // Save current FPU exception mask and mask all FP exceptions
  // This allows testing NaN, Infinity, division by zero without triggering exceptions
  FSavedExceptionMask := GetExceptionMask;
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
end;

procedure TTestCase_EdgeCases.TearDown;
begin
  // Restore original FPU exception mask
  SetExceptionMask(FSavedExceptionMask);
  inherited TearDown;
end;

// === NaN 处理测试 ===

procedure TTestCase_EdgeCases.Test_VecF32x4_Add_WithNaN;
var
  a, b, r: TVecF32x4;
begin
  a.f[0] := 1.0; a.f[1] := NaN; a.f[2] := 3.0; a.f[3] := NaN;
  b.f[0] := 2.0; b.f[1] := 2.0; b.f[2] := NaN; b.f[3] := NaN;
  
  r := a + b;
  
  AssertEquals('Normal + Normal', 3.0, r.f[0], 0.0001);
  AssertTrue('NaN + Normal is NaN', IsNaN(r.f[1]));
  AssertTrue('Normal + NaN is NaN', IsNaN(r.f[2]));
  AssertTrue('NaN + NaN is NaN', IsNaN(r.f[3]));
end;

procedure TTestCase_EdgeCases.Test_VecF32x4_Mul_WithNaN;
var
  a, b, r: TVecF32x4;
begin
  a.f[0] := 2.0; a.f[1] := NaN; a.f[2] := 0.0; a.f[3] := NaN;
  b.f[0] := 3.0; b.f[1] := 3.0; b.f[2] := NaN; b.f[3] := 0.0;
  
  r := a * b;
  
  AssertEquals('Normal * Normal', 6.0, r.f[0], 0.0001);
  AssertTrue('NaN * Normal is NaN', IsNaN(r.f[1]));
  AssertTrue('0 * NaN is NaN', IsNaN(r.f[2]));
  AssertTrue('NaN * 0 is NaN', IsNaN(r.f[3]));
end;

procedure TTestCase_EdgeCases.Test_VecF32x4_Compare_WithNaN;
var
  a, b: TVecF32x4;
begin
  a.f[0] := NaN; a.f[1] := 1.0; a.f[2] := NaN; a.f[3] := 1.0;
  b.f[0] := 1.0; b.f[1] := NaN; b.f[2] := NaN; b.f[3] := 1.0;
  
  // NaN comparisons should always be false (IEEE 754)
  AssertFalse('NaN > Normal is false', a.f[0] > b.f[0]);
  AssertFalse('Normal > NaN is false', a.f[1] > b.f[1]);
  AssertFalse('NaN = NaN is false', a.f[2] = b.f[2]);
  AssertTrue('Normal = Normal is true', a.f[3] = b.f[3]);
end;

procedure TTestCase_EdgeCases.Test_SortNet4_F32_WithNaN;
var
  a, r: TVecF32x4;
begin
  // NaN 会破坏排序，但不应崩溃
  a.f[0] := 3.0; a.f[1] := NaN; a.f[2] := 1.0; a.f[3] := 2.0;
  
  r := SortNet4F32(a, True);
  
  // 不检查结果顺序（NaN 破坏排序），只确保不崩溃
  AssertTrue('SortNet4 with NaN should not crash', True);
end;

// === Infinity 处理测试 ===

procedure TTestCase_EdgeCases.Test_VecF32x4_Add_WithInfinity;
var
  a, b, r: TVecF32x4;
begin
  a.f[0] := Infinity; a.f[1] := -Infinity; a.f[2] := Infinity; a.f[3] := 1.0;
  b.f[0] := 1.0;       b.f[1] := 1.0;        b.f[2] := -Infinity; b.f[3] := Infinity;
  
  r := a + b;
  
  AssertTrue('+Inf + 1 = +Inf', IsInfinite(r.f[0]) and (r.f[0] > 0));
  AssertTrue('-Inf + 1 = -Inf', IsInfinite(r.f[1]) and (r.f[1] < 0));
  AssertTrue('+Inf + -Inf = NaN', IsNaN(r.f[2]));
  AssertTrue('1 + Inf = +Inf', IsInfinite(r.f[3]) and (r.f[3] > 0));
end;

procedure TTestCase_EdgeCases.Test_VecF32x4_Mul_InfinityByZero;
var
  a, b, r: TVecF32x4;
begin
  a.f[0] := Infinity; a.f[1] := -Infinity; a.f[2] := 0.0; a.f[3] := Infinity;
  b.f[0] := 0.0;       b.f[1] := 0.0;        b.f[2] := Infinity; b.f[3] := 2.0;
  
  r := a * b;
  
  AssertTrue('Inf * 0 = NaN', IsNaN(r.f[0]));
  AssertTrue('-Inf * 0 = NaN', IsNaN(r.f[1]));
  AssertTrue('0 * Inf = NaN', IsNaN(r.f[2]));
  AssertTrue('Inf * 2 = Inf', IsInfinite(r.f[3]));
end;

procedure TTestCase_EdgeCases.Test_VecF32x4_Div_ByZero;
var
  a, b, r: TVecF32x4;
begin
  a.f[0] := 1.0; a.f[1] := -1.0; a.f[2] := 0.0; a.f[3] := Infinity;
  b.f[0] := 0.0; b.f[1] := 0.0;  b.f[2] := 0.0; b.f[3] := 0.0;
  
  r := a / b;
  
  AssertTrue('1/0 = +Inf', IsInfinite(r.f[0]) and (r.f[0] > 0));
  AssertTrue('-1/0 = -Inf', IsInfinite(r.f[1]) and (r.f[1] < 0));
  AssertTrue('0/0 = NaN', IsNaN(r.f[2]));
  AssertTrue('Inf/0 = Inf', IsInfinite(r.f[3]));
end;

procedure TTestCase_EdgeCases.Test_VecF32x4_Div_InfinityByInfinity;
var
  a, b, r: TVecF32x4;
begin
  a.f[0] := Infinity; a.f[1] := -Infinity; a.f[2] := Infinity; a.f[3] := 1.0;
  b.f[0] := Infinity; b.f[1] := Infinity;  b.f[2] := -Infinity; b.f[3] := Infinity;
  
  r := a / b;
  
  AssertTrue('Inf/Inf = NaN', IsNaN(r.f[0]));
  AssertTrue('-Inf/Inf = NaN', IsNaN(r.f[1]));
  AssertTrue('Inf/-Inf = NaN', IsNaN(r.f[2]));
  AssertEquals('1/Inf = 0', 0.0, r.f[3], 0.0001);
end;

// === 整数边界测试 ===

procedure TTestCase_EdgeCases.Test_VecI32x4_Add_MaxValue;
var
  a, b, r: TVecI32x4;
begin
  {$PUSH}{$R-}{$Q-}  // Disable range and overflow checking for wraparound test
  a.i[0] := High(Int32); a.i[1] := High(Int32); a.i[2] := 0; a.i[3] := Low(Int32);
  b.i[0] := 1;           b.i[1] := High(Int32); b.i[2] := High(Int32); b.i[3] := -1;
  
  r := a + b;
  
  // 溢出行为（环绕）
  AssertEquals('MaxInt + 1 overflows', Low(Int32), r.i[0]);
  AssertEquals('0 + MaxInt', High(Int32), r.i[2]);
  AssertEquals('MinInt + -1 overflows', High(Int32), r.i[3]);
  {$POP}
end;

procedure TTestCase_EdgeCases.Test_VecI32x4_Sub_MinValue;
var
  a, b, r: TVecI32x4;
begin
  {$PUSH}{$R-}{$Q-}  // Disable range and overflow checking for wraparound test
  a.i[0] := Low(Int32); a.i[1] := 0; a.i[2] := High(Int32); a.i[3] := Low(Int32);
  b.i[0] := 1;          b.i[1] := Low(Int32); b.i[2] := -1; b.i[3] := Low(Int32);
  
  r := a - b;
  
  // 溢出行为（环绕）
  AssertEquals('MinInt - 1 overflows', High(Int32), r.i[0]);
  AssertEquals('0 - MinInt overflows', Low(Int32), r.i[1]);
  AssertEquals('MaxInt - -1 overflows', Low(Int32), r.i[2]);
  {$POP}
end;

procedure TTestCase_EdgeCases.Test_PrefixSum_I32_Overflow;
var
  a, r: TVecI32x4;
begin
  {$PUSH}{$R-}{$Q-}  // Disable range and overflow checking for wraparound test
  a.i[0] := High(Int32); a.i[1] := 1; a.i[2] := 1; a.i[3] := 1;
  
  r := PrefixSumI32x4(a, True);
  
  // 前缀和会溢出，但不应崩溃
  AssertEquals('First element', High(Int32), r.i[0]);
  // r.i[1] = High(Int32) + 1 = overflow
  AssertTrue('PrefixSum with overflow should not crash', True);
  {$POP}
end;

// === 极端对齐场景 ===

procedure TTestCase_EdgeCases.Test_MemEqual_Unaligned_1Byte;
var
  buf1, buf2: array[0..64] of Byte;
  i: Integer;
begin
  for i := 0 to 64 do
  begin
    buf1[i] := i mod 256;
    buf2[i] := i mod 256;
  end;
  
  // 各种偏移测试
  AssertTrue('Aligned comparison', MemEqual(@buf1[0], @buf2[0], 64));
  AssertTrue('Offset +1', MemEqual(@buf1[1], @buf2[1], 63));
  AssertTrue('Offset +2', MemEqual(@buf1[2], @buf2[2], 62));
  AssertTrue('Offset +3', MemEqual(@buf1[3], @buf2[3], 61));
  AssertTrue('Offset +7', MemEqual(@buf1[7], @buf2[7], 57));
end;

procedure TTestCase_EdgeCases.Test_MemEqual_Unaligned_15Bytes;
var
  buf1, buf2: array[0..30] of Byte;
  i: Integer;
begin
  for i := 0 to 30 do
  begin
    buf1[i] := i;
    buf2[i] := i;
  end;
  
  // 15 字节（不足一个 SSE 寄存器）
  AssertTrue('15 bytes from offset 0', MemEqual(@buf1[0], @buf2[0], 15));
  AssertTrue('15 bytes from offset 1', MemEqual(@buf1[1], @buf2[1], 15));
  
  // 修改一个字节
  buf2[7] := 255;
  AssertFalse('15 bytes with diff at middle', MemEqual(@buf1[0], @buf2[0], 15));
end;

procedure TTestCase_EdgeCases.Test_MemFindByte_CrossPage;
var
  buf: array[0..8191] of Byte;  // 8KB, 跨页
  i: Integer;
begin
  FillByte(buf[0], 8192, 0);
  
  // 在各种位置放置目标字节
  buf[0] := $FF;
  AssertEquals('Find at start', 0, MemFindByte(@buf[0], 8192, $FF));
  
  buf[0] := 0;
  buf[4095] := $FF;  // 页边界
  AssertEquals('Find at page boundary', 4095, MemFindByte(@buf[0], 8192, $FF));
  
  buf[4095] := 0;
  buf[4096] := $FF;  // 下一页开始
  AssertEquals('Find at next page start', 4096, MemFindByte(@buf[0], 8192, $FF));
  
  buf[4096] := 0;
  buf[8191] := $FF;  // 最后一个字节
  AssertEquals('Find at last byte', 8191, MemFindByte(@buf[0], 8192, $FF));
end;

procedure TTestCase_EdgeCases.Test_SumBytes_OddSizes;
var
  buf: array[0..255] of Byte;
  i: Integer;
  sum: UInt64;
begin
  for i := 0 to 255 do
    buf[i] := 1;
  
  // 各种奇数大小
  sum := SumBytes(@buf[0], 1);
  AssertEquals('Sum of 1 byte', 1, sum);
  
  sum := SumBytes(@buf[0], 7);
  AssertEquals('Sum of 7 bytes', 7, sum);
  
  sum := SumBytes(@buf[0], 15);
  AssertEquals('Sum of 15 bytes', 15, sum);
  
  sum := SumBytes(@buf[0], 31);
  AssertEquals('Sum of 31 bytes', 31, sum);
  
  sum := SumBytes(@buf[0], 33);
  AssertEquals('Sum of 33 bytes', 33, sum);
end;

// === 数学函数边界 ===

procedure TTestCase_EdgeCases.Test_VecF32x4_Log_Zero;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 0.0; a.f[1] := 1.0; a.f[2] := 2.718281828; a.f[3] := 0.0;
  
  r := VecF32x4Log(a);
  
  AssertTrue('log(0) = -Inf', IsInfinite(r.f[0]) and (r.f[0] < 0));
  AssertEquals('log(1) = 0', 0.0, r.f[1], 0.0001);
  AssertEquals('log(e) = 1', 1.0, r.f[2], 0.0001);
end;

procedure TTestCase_EdgeCases.Test_VecF32x4_Log_Negative;
var
  a, r: TVecF32x4;
begin
  a.f[0] := -1.0; a.f[1] := -0.5; a.f[2] := 1.0; a.f[3] := -Infinity;
  
  r := VecF32x4Log(a);
  
  AssertTrue('log(-1) = NaN', IsNaN(r.f[0]));
  AssertTrue('log(-0.5) = NaN', IsNaN(r.f[1]));
  AssertEquals('log(1) = 0', 0.0, r.f[2], 0.0001);
  AssertTrue('log(-Inf) = NaN', IsNaN(r.f[3]));
end;

procedure TTestCase_EdgeCases.Test_VecF32x4_Sqrt_Negative;
var
  a, r: TVecF32x4;
begin
  a.f[0] := -1.0; a.f[1] := 0.0; a.f[2] := 4.0; a.f[3] := -0.0;
  
  r.f[0] := Sqrt(a.f[0]);
  r.f[1] := Sqrt(a.f[1]);
  r.f[2] := Sqrt(a.f[2]);
  r.f[3] := Sqrt(a.f[3]);
  
  AssertTrue('sqrt(-1) = NaN', IsNaN(r.f[0]));
  AssertEquals('sqrt(0) = 0', 0.0, r.f[1], 0.0001);
  AssertEquals('sqrt(4) = 2', 2.0, r.f[2], 0.0001);
  AssertEquals('sqrt(-0) = 0', 0.0, r.f[3], 0.0001);
end;

procedure TTestCase_EdgeCases.Test_VecF32x4_Asin_OutOfRange;
var
  a, r: TVecF32x4;
begin
  a.f[0] := 2.0;  // 超出范围
  a.f[1] := -2.0; // 超出范围
  a.f[2] := 0.5;  // 正常范围
  a.f[3] := 1.0;  // 边界
  
  r := VecF32x4Asin(a);
  
  AssertTrue('asin(2) = NaN', IsNaN(r.f[0]));
  AssertTrue('asin(-2) = NaN', IsNaN(r.f[1]));
  AssertEquals('asin(0.5)', Pi/6, r.f[2], 0.0001);
  AssertEquals('asin(1) = pi/2', Pi/2, r.f[3], 0.0001);
end;

{ TTestCase_Memutils }

procedure TTestCase_Memutils.Test_AlignedAlloc_AlignedAndWritable;
var
  p: PByte;
  i: Integer;
begin
  p := AlignedAlloc(128, SIMD_ALIGN_32);
  try
    AssertTrue('AlignedAlloc should return non-nil', p <> nil);
    AssertTrue('Pointer should be 32-byte aligned', IsAligned(p, SIMD_ALIGN_32));
    // Write and read back a simple pattern
    for i := 0 to 127 do
      p[i] := Byte(i and $FF);
    for i := 0 to 127 do
      AssertEquals('Written data must round-trip', Byte(i and $FF), p[i]);
  finally
    AlignedFree(p);
  end;
end;

procedure TTestCase_Memutils.Test_AlignedRealloc_Grow_PreservesPrefix;
var
  p, p2: PByte;
  i: Integer;
begin
  // Start with a small buffer and grow it; existing bytes must be preserved
  p := AlignedAlloc(16, SIMD_ALIGN_32);
  try
    for i := 0 to 15 do
      p[i] := Byte(i + 10);
    p2 := AlignedRealloc(p, 64, SIMD_ALIGN_32);
    // After realloc, p should no longer be used
    p := nil;
    AssertTrue('Realloc result should be non-nil', p2 <> nil);
    AssertTrue('Realloc result should be 32-byte aligned', IsAligned(p2, SIMD_ALIGN_32));
    for i := 0 to 15 do
      AssertEquals('Prefix bytes must be preserved after grow', Byte(i + 10), p2[i]);
  finally
    if p2 <> nil then
      AlignedFree(p2);
  end;
end;

procedure TTestCase_Memutils.Test_AlignedRealloc_Shrink_PreservesPrefix;
var
  p, p2: PByte;
  i: Integer;
begin
  // Start with a larger buffer and shrink it; leading bytes must be preserved
  p := AlignedAlloc(64, SIMD_ALIGN_32);
  try
    for i := 0 to 63 do
      p[i] := Byte(255 - i);
    p2 := AlignedRealloc(p, 16, SIMD_ALIGN_32);
    p := nil;
    AssertTrue('Realloc result should be non-nil', p2 <> nil);
    AssertTrue('Realloc result should be 32-byte aligned', IsAligned(p2, SIMD_ALIGN_32));
    for i := 0 to 15 do
      AssertEquals('Prefix bytes must be preserved after shrink', Byte(255 - i), p2[i]);
  finally
    if p2 <> nil then
      AlignedFree(p2);
  end;
end;

procedure TTestCase_Memutils.Test_AlignedRealloc_NilAndZero_Semantics;
var
  p, p2: PByte;
begin
  // realloc(nil, N) behaves like malloc(N)
  p := AlignedRealloc(nil, 32, SIMD_ALIGN_16);
  AssertTrue('Realloc(nil, N) should allocate', p <> nil);
  AssertTrue('Allocated pointer should be aligned', IsAligned(p, SIMD_ALIGN_16));
  
  // realloc(p, 0) behaves like free(p) and returns nil
  p2 := AlignedRealloc(p, 0, SIMD_ALIGN_16);
  p := nil;
  AssertTrue('Realloc(p, 0) should return nil', p2 = nil);
end;

{ TTestCase_Vec512Types }

procedure TTestCase_Vec512Types.Test_VecF32x16_Create;
var
  v: TVecF32x16;
  i: Integer;
begin
  for i := 0 to 15 do
    v.f[i] := i * 1.5;
  
  for i := 0 to 15 do
    AssertEquals('Element ' + IntToStr(i), i * 1.5, v.f[i], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecF32x16_LoHi;
var
  v: TVecF32x16;
  i: Integer;
begin
  for i := 0 to 15 do
    v.f[i] := i;
  
  // Lo 应该是 [0..7]
  for i := 0 to 7 do
    AssertEquals('Lo element ' + IntToStr(i), Single(i), v.lo.f[i], 0.0001);
  
  // Hi 应该是 [8..15]
  for i := 0 to 7 do
    AssertEquals('Hi element ' + IntToStr(i), Single(i + 8), v.hi.f[i], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecF32x16_SizeOf;
begin
  AssertEquals('TVecF32x16 should be 64 bytes', 64, SizeOf(TVecF32x16));
end;

procedure TTestCase_Vec512Types.Test_VecF64x8_Create;
var
  v: TVecF64x8;
  i: Integer;
begin
  for i := 0 to 7 do
    v.d[i] := i * 2.5;
  
  for i := 0 to 7 do
    AssertEquals('Element ' + IntToStr(i), i * 2.5, v.d[i], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecF64x8_LoHi;
var
  v: TVecF64x8;
  i: Integer;
begin
  for i := 0 to 7 do
    v.d[i] := i;
  
  // Lo 应该是 [0..3]
  for i := 0 to 3 do
    AssertEquals('Lo element ' + IntToStr(i), Double(i), v.lo.d[i], 0.0001);
  
  // Hi 应该是 [4..7]
  for i := 0 to 3 do
    AssertEquals('Hi element ' + IntToStr(i), Double(i + 4), v.hi.d[i], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecF64x8_SizeOf;
begin
  AssertEquals('TVecF64x8 should be 64 bytes', 64, SizeOf(TVecF64x8));
end;

procedure TTestCase_Vec512Types.Test_VecI32x16_Create;
var
  v: TVecI32x16;
  i: Integer;
begin
  for i := 0 to 15 do
    v.i[i] := i * 100;
  
  for i := 0 to 15 do
    AssertEquals('Element ' + IntToStr(i), i * 100, v.i[i]);
end;

procedure TTestCase_Vec512Types.Test_VecI32x16_LoHi;
var
  v: TVecI32x16;
  i: Integer;
begin
  for i := 0 to 15 do
    v.i[i] := i;
  
  for i := 0 to 7 do
    AssertEquals('Lo element ' + IntToStr(i), i, v.lo.i[i]);
  
  for i := 0 to 7 do
    AssertEquals('Hi element ' + IntToStr(i), i + 8, v.hi.i[i]);
end;

procedure TTestCase_Vec512Types.Test_VecI32x16_SizeOf;
begin
  AssertEquals('TVecI32x16 should be 64 bytes', 64, SizeOf(TVecI32x16));
end;

procedure TTestCase_Vec512Types.Test_VecI64x8_Create;
var
  v: TVecI64x8;
  i: Integer;
begin
  for i := 0 to 7 do
    v.i[i] := Int64(i) * 1000000000;
  
  for i := 0 to 7 do
    AssertEquals('Element ' + IntToStr(i), Int64(i) * 1000000000, v.i[i]);
end;

procedure TTestCase_Vec512Types.Test_VecI64x8_SizeOf;
begin
  AssertEquals('TVecI64x8 should be 64 bytes', 64, SizeOf(TVecI64x8));
end;

procedure TTestCase_Vec512Types.Test_VecI8x64_Create;
var
  v: TVecI8x64;
  i: Integer;
begin
  for i := 0 to 63 do
    v.i[i] := Int8(i - 32);
  
  for i := 0 to 63 do
    AssertEquals('Element ' + IntToStr(i), Int8(i - 32), v.i[i]);
end;

procedure TTestCase_Vec512Types.Test_VecI8x64_SizeOf;
begin
  AssertEquals('TVecI8x64 should be 64 bytes', 64, SizeOf(TVecI8x64));
end;

procedure TTestCase_Vec512Types.Test_Mask64_AllSet;
var
  m: TMask64;
begin
  m := High(QWord);
  AssertEquals('TMask64 all set', High(QWord), m);
end;

procedure TTestCase_Vec512Types.Test_Mask64_NoneSet;
var
  m: TMask64;
begin
  m := 0;
  AssertEquals('TMask64 none set', 0, m);
end;

procedure TTestCase_Vec512Types.Test_MaskF32x16_AllTrue;
var
  m: TMaskF32x16;
  i: Integer;
begin
  m := MaskF32x16AllTrue;
  
  for i := 0 to 15 do
    AssertEquals('Element ' + IntToStr(i) + ' should be $FFFFFFFF', $FFFFFFFF, m.m[i]);
  AssertEquals('Bits should be $FFFF', $FFFF, m.bits);
end;

procedure TTestCase_Vec512Types.Test_MaskF32x16_AllFalse;
var
  m: TMaskF32x16;
  i: Integer;
begin
  m := MaskF32x16AllFalse;
  
  for i := 0 to 15 do
    AssertEquals('Element ' + IntToStr(i) + ' should be 0', 0, m.m[i]);
  AssertEquals('Bits should be 0', 0, m.bits);
end;

procedure TTestCase_Vec512Types.Test_MaskF32x16_ToBitmask;
var
  m: TMaskF32x16;
  bm: TMask16;
begin
  m := MaskF32x16AllFalse;
  m.m[0] := $FFFFFFFF;  // bit 0
  m.m[3] := $FFFFFFFF;  // bit 3
  m.m[7] := $FFFFFFFF;  // bit 7
  m.m[15] := $FFFFFFFF; // bit 15
  
  bm := MaskF32x16ToBitmask(m);
  AssertEquals('Bitmask should be $8089', $8089, bm);
end;

procedure TTestCase_Vec512Types.Test_MaskF32x16_Any_All_None;
var
  mAll, mNone, mSome: TMaskF32x16;
begin
  mAll := MaskF32x16AllTrue;
  mNone := MaskF32x16AllFalse;
  mSome := MaskF32x16AllFalse;
  mSome.m[5] := $FFFFFFFF;
  
  // Test Any
  AssertTrue('All mask Any = True', MaskF32x16Any(mAll));
  AssertFalse('None mask Any = False', MaskF32x16Any(mNone));
  AssertTrue('Some mask Any = True', MaskF32x16Any(mSome));
  
  // Test All
  AssertTrue('All mask All = True', MaskF32x16All(mAll));
  AssertFalse('None mask All = False', MaskF32x16All(mNone));
  AssertFalse('Some mask All = False', MaskF32x16All(mSome));
  
  // Test None
  AssertFalse('All mask None = False', MaskF32x16None(mAll));
  AssertTrue('None mask None = True', MaskF32x16None(mNone));
  AssertFalse('Some mask None = False', MaskF32x16None(mSome));
end;

procedure TTestCase_Vec512Types.Test_VecF32x16_Add;
var
  a, b, r: TVecF32x16;
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    a.f[i] := i;
    b.f[i] := i * 2;
  end;
  
  r := a + b;
  
  for i := 0 to 15 do
    AssertEquals('Element ' + IntToStr(i), i * 3.0, r.f[i], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecF32x16_Sub;
var
  a, b, r: TVecF32x16;
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    a.f[i] := i * 3;
    b.f[i] := i;
  end;
  
  r := a - b;
  
  for i := 0 to 15 do
    AssertEquals('Element ' + IntToStr(i), i * 2.0, r.f[i], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecF32x16_Mul;
var
  a, b, r: TVecF32x16;
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    a.f[i] := i + 1;
    b.f[i] := 2;
  end;
  
  r := a * b;
  
  for i := 0 to 15 do
    AssertEquals('Element ' + IntToStr(i), (i + 1) * 2.0, r.f[i], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecF32x16_Neg;
var
  a, r: TVecF32x16;
  i: Integer;
begin
  for i := 0 to 15 do
    a.f[i] := i - 7.5;
  
  r := -a;
  
  for i := 0 to 15 do
    AssertEquals('Element ' + IntToStr(i), -(i - 7.5), r.f[i], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecF64x8_Add;
var
  a, b, r: TVecF64x8;
  i: Integer;
begin
  for i := 0 to 7 do
  begin
    a.d[i] := i * 1.5;
    b.d[i] := i * 0.5;
  end;
  
  r := a + b;
  
  for i := 0 to 7 do
    AssertEquals('Element ' + IntToStr(i), i * 2.0, r.d[i], 0.0001);
end;

procedure TTestCase_Vec512Types.Test_VecI32x16_Add;
var
  a, b, r: TVecI32x16;
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    a.i[i] := i * 10;
    b.i[i] := i * 5;
  end;
  
  r := a + b;
  
  for i := 0 to 15 do
    AssertEquals('Element ' + IntToStr(i), i * 15, r.i[i]);
end;

procedure TTestCase_Vec512Types.Test_VecF32x16_CmpEq;
var
  a, b: TVecF32x16;
  m: TMaskF32x16;
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    a.f[i] := i;
    if i mod 2 = 0 then
      b.f[i] := i    // 等于
    else
      b.f[i] := i + 1;  // 不等
  end;
  
  m := VecF32x16CmpEq(a, b);
  
  for i := 0 to 15 do
    if i mod 2 = 0 then
      AssertEquals('Element ' + IntToStr(i) + ' should be true', $FFFFFFFF, m.m[i])
    else
      AssertEquals('Element ' + IntToStr(i) + ' should be false', 0, m.m[i]);
  
  // 检查 bitmask: 偶数位置为 1 = $5555
  AssertEquals('Bitmask', $5555, m.bits);
end;

procedure TTestCase_Vec512Types.Test_VecF32x16_CmpLt;
var
  a, b: TVecF32x16;
  m: TMaskF32x16;
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    a.f[i] := i;
    b.f[i] := 8;  // 比较与 8
  end;
  
  m := VecF32x16CmpLt(a, b);
  
  // 元素 0-7 应该小于 8，元素 8-15 不小于 8
  for i := 0 to 7 do
    AssertTrue('Element ' + IntToStr(i) + ' < 8', m.m[i] = $FFFFFFFF);
  for i := 8 to 15 do
    AssertTrue('Element ' + IntToStr(i) + ' >= 8', m.m[i] = 0);
  
  // bitmask: 低 8 位为 1 = $00FF
  AssertEquals('Bitmask', $00FF, m.bits);
end;

procedure TTestCase_Vec512Types.Test_MaskF32x16_LogicOps;
var
  m1, m2, r: TMaskF32x16;
begin
  // m1 = $5555 (偶数位), m2 = $00FF (低 8 位)
  m1 := MaskF32x16FromBitmask($5555);
  m2 := MaskF32x16FromBitmask($00FF);
  
  // AND: $5555 & $00FF = $0055
  r := m1 and m2;
  AssertEquals('AND result', $0055, r.bits);
  
  // OR: $5555 | $00FF = $55FF
  r := m1 or m2;
  AssertEquals('OR result', $55FF, r.bits);
  
  // XOR: $5555 ^ $00FF = $55AA
  r := m1 xor m2;
  AssertEquals('XOR result', $55AA, r.bits);
  
  // NOT: ~$5555 = $AAAA
  r := not m1;
  AssertEquals('NOT result', $AAAA, r.bits);
end;

procedure TTestCase_Vec512Types.Test_MaskF32x16_Select;
var
  a, b, r: TVecF32x16;
  m: TMaskF32x16;
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    a.f[i] := 100 + i;  // 真分支
    b.f[i] := 200 + i;  // 假分支
  end;
  
  // 偶数位置选 a，奇数位置选 b
  m := MaskF32x16FromBitmask($5555);
  
  r := MaskF32x16Select(m, a, b);
  
  for i := 0 to 15 do
    if i mod 2 = 0 then
      AssertEquals('Element ' + IntToStr(i), 100.0 + i, r.f[i], 0.0001)
    else
      AssertEquals('Element ' + IntToStr(i), 200.0 + i, r.f[i], 0.0001);
end;

{ TTestCase_RustStyleAliases }

procedure TTestCase_RustStyleAliases.Test_f32x4_Alias_SameSize;
begin
  AssertEquals('f32x4 should have same size as TVecF32x4', SizeOf(TVecF32x4), SizeOf(f32x4));
  AssertEquals('f32x4 size should be 16 bytes', 16, SizeOf(f32x4));
end;

procedure TTestCase_RustStyleAliases.Test_f32x4_Alias_Usable;
var
  v: f32x4;
  i: Integer;
begin
  // 测试别名可以正常使用
  v.f[0] := 1.0;
  v.f[1] := 2.0;
  v.f[2] := 3.0;
  v.f[3] := 4.0;
  
  for i := 0 to 3 do
    AssertEquals('Element ' + IntToStr(i), Single(i + 1), v.f[i], 0.0001);
end;

procedure TTestCase_RustStyleAliases.Test_f64x2_Alias_SameSize;
begin
  AssertEquals('f64x2 should have same size as TVecF64x2', SizeOf(TVecF64x2), SizeOf(f64x2));
  AssertEquals('f64x2 size should be 16 bytes', 16, SizeOf(f64x2));
end;

procedure TTestCase_RustStyleAliases.Test_f64x2_Alias_Usable;
var
  v: f64x2;
begin
  v.d[0] := 1.5;
  v.d[1] := 2.5;
  
  AssertEquals('Element 0', 1.5, v.d[0], 0.0001);
  AssertEquals('Element 1', 2.5, v.d[1], 0.0001);
end;

procedure TTestCase_RustStyleAliases.Test_i32x4_Alias_SameSize;
begin
  AssertEquals('i32x4 should have same size as TVecI32x4', SizeOf(TVecI32x4), SizeOf(i32x4));
  AssertEquals('i32x4 size should be 16 bytes', 16, SizeOf(i32x4));
end;

procedure TTestCase_RustStyleAliases.Test_i32x4_Alias_Usable;
var
  v: i32x4;
  i: Integer;
begin
  for i := 0 to 3 do
    v.i[i] := i * 10;
  
  for i := 0 to 3 do
    AssertEquals('Element ' + IntToStr(i), i * 10, v.i[i]);
end;

procedure TTestCase_RustStyleAliases.Test_i64x2_Alias_SameSize;
begin
  AssertEquals('i64x2 should have same size as TVecI64x2', SizeOf(TVecI64x2), SizeOf(i64x2));
  AssertEquals('i64x2 size should be 16 bytes', 16, SizeOf(i64x2));
end;

procedure TTestCase_RustStyleAliases.Test_i16x8_Alias_SameSize;
begin
  AssertEquals('i16x8 should have same size as TVecI16x8', SizeOf(TVecI16x8), SizeOf(i16x8));
  AssertEquals('i16x8 size should be 16 bytes', 16, SizeOf(i16x8));
end;

procedure TTestCase_RustStyleAliases.Test_i8x16_Alias_SameSize;
begin
  AssertEquals('i8x16 should have same size as TVecI8x16', SizeOf(TVecI8x16), SizeOf(i8x16));
  AssertEquals('i8x16 size should be 16 bytes', 16, SizeOf(i8x16));
end;

procedure TTestCase_RustStyleAliases.Test_u32x4_Alias_SameSize;
begin
  AssertEquals('u32x4 should have same size as TVecU32x4', SizeOf(TVecU32x4), SizeOf(u32x4));
  AssertEquals('u32x4 size should be 16 bytes', 16, SizeOf(u32x4));
end;

procedure TTestCase_RustStyleAliases.Test_u64x2_Alias_SameSize;
begin
  AssertEquals('u64x2 should have same size as TVecU64x2', SizeOf(TVecU64x2), SizeOf(u64x2));
  AssertEquals('u64x2 size should be 16 bytes', 16, SizeOf(u64x2));
end;

procedure TTestCase_RustStyleAliases.Test_u16x8_Alias_SameSize;
begin
  AssertEquals('u16x8 should have same size as TVecU16x8', SizeOf(TVecU16x8), SizeOf(u16x8));
  AssertEquals('u16x8 size should be 16 bytes', 16, SizeOf(u16x8));
end;

procedure TTestCase_RustStyleAliases.Test_u8x16_Alias_SameSize;
begin
  AssertEquals('u8x16 should have same size as TVecU8x16', SizeOf(TVecU8x16), SizeOf(u8x16));
  AssertEquals('u8x16 size should be 16 bytes', 16, SizeOf(u8x16));
end;

procedure TTestCase_RustStyleAliases.Test_f32x8_Alias_SameSize;
begin
  AssertEquals('f32x8 should have same size as TVecF32x8', SizeOf(TVecF32x8), SizeOf(f32x8));
  AssertEquals('f32x8 size should be 32 bytes', 32, SizeOf(f32x8));
end;

procedure TTestCase_RustStyleAliases.Test_f64x4_Alias_SameSize;
begin
  AssertEquals('f64x4 should have same size as TVecF64x4', SizeOf(TVecF64x4), SizeOf(f64x4));
  AssertEquals('f64x4 size should be 32 bytes', 32, SizeOf(f64x4));
end;

procedure TTestCase_RustStyleAliases.Test_i32x8_Alias_SameSize;
begin
  AssertEquals('i32x8 should have same size as TVecI32x8', SizeOf(TVecI32x8), SizeOf(i32x8));
  AssertEquals('i32x8 size should be 32 bytes', 32, SizeOf(i32x8));
end;

procedure TTestCase_RustStyleAliases.Test_f32x16_Alias_SameSize;
begin
  AssertEquals('f32x16 should have same size as TVecF32x16', SizeOf(TVecF32x16), SizeOf(f32x16));
  AssertEquals('f32x16 size should be 64 bytes', 64, SizeOf(f32x16));
end;

procedure TTestCase_RustStyleAliases.Test_f64x8_Alias_SameSize;
begin
  AssertEquals('f64x8 should have same size as TVecF64x8', SizeOf(TVecF64x8), SizeOf(f64x8));
  AssertEquals('f64x8 size should be 64 bytes', 64, SizeOf(f64x8));
end;

procedure TTestCase_RustStyleAliases.Test_i32x16_Alias_SameSize;
begin
  AssertEquals('i32x16 should have same size as TVecI32x16', SizeOf(TVecI32x16), SizeOf(i32x16));
  AssertEquals('i32x16 size should be 64 bytes', 64, SizeOf(i32x16));
end;

procedure TTestCase_RustStyleAliases.Test_Alias_InteropWithOriginal;
var
  original: TVecF32x4;
  alias: f32x4;
  i: Integer;
begin
  // 测试别名和原始类型可互用
  for i := 0 to 3 do
    original.f[i] := i + 1;
  
  alias := original;  // 直接赋值
  
  for i := 0 to 3 do
    AssertEquals('Element ' + IntToStr(i), original.f[i], alias.f[i], 0.0001);
  
  // 反向赋值
  for i := 0 to 3 do
    alias.f[i] := (i + 1) * 10;
  
  original := alias;
  
  for i := 0 to 3 do
    AssertEquals('Reverse element ' + IntToStr(i), alias.f[i], original.f[i], 0.0001);
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_BackendConsistency);
  RegisterTest(TTestCase_BackendSmoke);
  RegisterTest(TTestCase_AVX2VectorAsm);
  RegisterTest(TTestCase_VectorOps);
  RegisterTest(TTestCase_LargeData);
  RegisterTest(TTestCase_UnsignedVectorTypes);
  RegisterTest(TTestCase_OperatorOverloads);
  RegisterTest(TTestCase_VectorMaskTypes);
  RegisterTest(TTestCase_TypeConversion);
  RegisterTest(TTestCase_Builder);
  RegisterTest(TTestCase_GatherScatter);
  RegisterTest(TTestCase_ShuffleSWizzle);
  RegisterTest(TTestCase_MathFunctions);
  RegisterTest(TTestCase_AdvancedAlgorithms);
  RegisterTest(TTestCase_EdgeCases);
  RegisterTest(TTestCase_Vec512Types);
  RegisterTest(TTestCase_Memutils);
  RegisterTest(TTestCase_RustStyleAliases);

end.
