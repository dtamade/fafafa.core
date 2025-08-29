unit fafafa.core.simd;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  // 新架构核心模块
  fafafa.core.simd.types,
  fafafa.core.simd.core,
  fafafa.core.simd.scalar,
  fafafa.core.simd.detect,
  // 旧模块（兼容性）
  fafafa.core.simd.mem,
  fafafa.core.simd.text,
  fafafa.core.simd.search,
  fafafa.core.simd.bitset;

var
  // 全局变量：强制配置的 Profile
  ForcedProfile: String = '';

// === 重新导出核心接口 ===

// 类型定义
type
  TSimdLanes = fafafa.core.simd.types.TSimdLanes;
  TSimdElementType = fafafa.core.simd.types.TSimdElementType;
  TSimdISA = fafafa.core.simd.types.TSimdISA;
  TSimdISASet = fafafa.core.simd.types.TSimdISASet;
  TSimdError = fafafa.core.simd.types.TSimdError;
  TSimdContext = fafafa.core.simd.types.TSimdContext;
  
  // 向量类型
  TSimdF32x2 = fafafa.core.simd.types.TSimdF32x2;
  TSimdF32x4 = fafafa.core.simd.types.TSimdF32x4;
  TSimdF32x8 = fafafa.core.simd.types.TSimdF32x8;
  TSimdF32x16 = fafafa.core.simd.types.TSimdF32x16;
  
  TSimdF64x2 = fafafa.core.simd.types.TSimdF64x2;
  TSimdF64x4 = fafafa.core.simd.types.TSimdF64x4;
  TSimdF64x8 = fafafa.core.simd.types.TSimdF64x8;
  
  TSimdI32x2 = fafafa.core.simd.types.TSimdI32x2;
  TSimdI32x4 = fafafa.core.simd.types.TSimdI32x4;
  TSimdI32x8 = fafafa.core.simd.types.TSimdI32x8;
  TSimdI32x16 = fafafa.core.simd.types.TSimdI32x16;
  
  TSimdU8x16 = fafafa.core.simd.types.TSimdU8x16;
  TSimdU8x32 = fafafa.core.simd.types.TSimdU8x32;
  TSimdU8x64 = fafafa.core.simd.types.TSimdU8x64;
  
  // 掩码类型
  TSimdMask2 = fafafa.core.simd.types.TSimdMask2;
  TSimdMask4 = fafafa.core.simd.types.TSimdMask4;
  TSimdMask8 = fafafa.core.simd.types.TSimdMask8;
  TSimdMask16 = fafafa.core.simd.types.TSimdMask16;
  TSimdMask32 = fafafa.core.simd.types.TSimdMask32;

// === 重新导出核心函数 ===

// 上下文管理
function simd_init_context: TSimdContext;
procedure simd_set_context(const ctx: TSimdContext);
function simd_get_context: TSimdContext;
function simd_detect_capabilities: TSimdISASet;
function simd_get_best_isa(elementType: TSimdElementType; lanes: TSimdLanes): TSimdISA;

// 错误处理
function simd_make_error(code: Integer; const msg: String; isa: TSimdISA): TSimdError;

// 能力检测
function DetectSimdCapabilities: TSimdISASet;
function GetBestProfile: String;

// === 1. 向量算术运算 ===

// 加法运算
function simd_add_f32x4(const a, b: TSimdF32x4): TSimdF32x4; inline;
function simd_add_f32x8(const a, b: TSimdF32x8): TSimdF32x8; inline;
function simd_add_f32x16(const a, b: TSimdF32x16): TSimdF32x16; inline;
function simd_add_f64x2(const a, b: TSimdF64x2): TSimdF64x2; inline;
function simd_add_f64x4(const a, b: TSimdF64x4): TSimdF64x4; inline;
function simd_add_i32x4(const a, b: TSimdI32x4): TSimdI32x4; inline;
function simd_add_i32x8(const a, b: TSimdI32x8): TSimdI32x8; inline;
function simd_add_i32x16(const a, b: TSimdI32x16): TSimdI32x16; inline;

// 减法运算
function simd_sub_f32x4(const a, b: TSimdF32x4): TSimdF32x4; inline;
function simd_sub_f32x8(const a, b: TSimdF32x8): TSimdF32x8; inline;
function simd_sub_f32x16(const a, b: TSimdF32x16): TSimdF32x16; inline;
function simd_sub_f64x2(const a, b: TSimdF64x2): TSimdF64x2; inline;
function simd_sub_f64x4(const a, b: TSimdF64x4): TSimdF64x4; inline;
function simd_sub_i32x4(const a, b: TSimdI32x4): TSimdI32x4; inline;
function simd_sub_i32x8(const a, b: TSimdI32x8): TSimdI32x8; inline;

// 乘法运算
function simd_mul_f32x4(const a, b: TSimdF32x4): TSimdF32x4; inline;
function simd_mul_f32x8(const a, b: TSimdF32x8): TSimdF32x8; inline;
function simd_mul_f32x16(const a, b: TSimdF32x16): TSimdF32x16; inline;
function simd_mul_f64x2(const a, b: TSimdF64x2): TSimdF64x2; inline;
function simd_mul_f64x4(const a, b: TSimdF64x4): TSimdF64x4; inline;
function simd_mul_i32x4(const a, b: TSimdI32x4): TSimdI32x4; inline;
function simd_mul_i32x8(const a, b: TSimdI32x8): TSimdI32x8; inline;

// 除法运算（仅浮点）
function simd_div_f32x4(const a, b: TSimdF32x4): TSimdF32x4; inline;
function simd_div_f32x8(const a, b: TSimdF32x8): TSimdF32x8; inline;
function simd_div_f32x16(const a, b: TSimdF32x16): TSimdF32x16; inline;
function simd_div_f64x2(const a, b: TSimdF64x2): TSimdF64x2; inline;
function simd_div_f64x4(const a, b: TSimdF64x4): TSimdF64x4; inline;

// === 4. 聚合运算（Reduce Operations）===

// 求和
function simd_reduce_add_f32x4(const a: TSimdF32x4): Single; inline;
function simd_reduce_add_f32x8(const a: TSimdF32x8): Single; inline;
function simd_reduce_add_f64x2(const a: TSimdF64x2): Double; inline;
function simd_reduce_add_i32x4(const a: TSimdI32x4): Int32; inline;
function simd_reduce_add_i32x8(const a: TSimdI32x8): Int32; inline;

// === 6. 重排和混洗 ===

// 广播单个值
function simd_splat_f32x4(value: Single): TSimdF32x4; inline;
function simd_splat_f32x8(value: Single): TSimdF32x8; inline;
function simd_splat_i32x4(value: Int32): TSimdI32x4; inline;

// 提取元素
function simd_extract_f32x4(const a: TSimdF32x4; index: Integer): Single; inline;
function simd_extract_i32x4(const a: TSimdI32x4; index: Integer): Int32; inline;

// 插入元素
function simd_insert_f32x4(const a: TSimdF32x4; value: Single; index: Integer): TSimdF32x4; inline;
function simd_insert_i32x4(const a: TSimdI32x4; value: Int32; index: Integer): TSimdI32x4; inline;

// === 兼容性接口（保持向后兼容）===

// 旧的接口名称映射到新的实现
function SimdInfo: String;
function SimdGetForcedProfile: String;
procedure SimdSetForcedProfile(const profile: String);

// 内存操作函数
function MemEqual(a, b: Pointer; len: SizeUInt): Boolean; inline;
function MemFindByte(p: Pointer; len: SizeUInt; value: Byte): PtrInt; inline;
function MemDiffRange(a, b: Pointer; len: SizeUInt): TDiffRange; inline;
procedure MemCopy(src, dest: Pointer; len: SizeUInt); inline;
procedure MemSet(p: Pointer; len: SizeUInt; value: Byte); inline;
procedure MemReverse(p: Pointer; len: SizeUInt); inline;

// 统计函数
function SumBytes(p: Pointer; len: SizeUInt): QWord; inline;
procedure MinMaxBytes(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte); inline;
function CountByte(p: Pointer; len: SizeUInt; value: Byte): SizeUInt; inline;

// === 重新导出的函数（为了向后兼容）===

// 文本处理函数
function Utf8Validate(p: Pointer; len: SizeUInt): LongBool; inline;
function AsciiIEqual(a, b: Pointer; len: SizeUInt): LongBool; inline;
procedure ToLowerAscii(p: Pointer; len: SizeUInt); inline;
procedure ToUpperAscii(p: Pointer; len: SizeUInt); inline;

// 搜索函数
function BytesIndexOf(hay: Pointer; len: SizeUInt; ned: Pointer; nlen: SizeUInt): PtrInt; inline;

// 位集函数
function BitsetPopCount(p: Pointer; bitLen: SizeUInt): SizeUInt; inline;

implementation

// === 重新导出实现 ===

// 上下文管理
function simd_init_context: TSimdContext;
begin
  Result := fafafa.core.simd.types.simd_init_context;
end;

procedure simd_set_context(const ctx: TSimdContext);
begin
  fafafa.core.simd.types.simd_set_context(ctx);
end;

function simd_get_context: TSimdContext;
begin
  Result := fafafa.core.simd.types.simd_get_context;
end;

function simd_detect_capabilities: TSimdISASet;
begin
  Result := fafafa.core.simd.types.simd_detect_capabilities;
end;

function simd_get_best_isa(elementType: TSimdElementType; lanes: TSimdLanes): TSimdISA;
begin
  Result := fafafa.core.simd.types.simd_get_best_isa(elementType, lanes);
end;

function simd_make_error(code: Integer; const msg: String; isa: TSimdISA): TSimdError;
begin
  Result := fafafa.core.simd.types.simd_make_error(code, msg, isa);
end;

// 能力检测
function DetectSimdCapabilities: TSimdISASet;
begin
  Result := fafafa.core.simd.detect.DetectSimdCapabilities;
end;

function GetBestProfile: String;
begin
  Result := fafafa.core.simd.detect.GetBestProfile;
end;

// === 核心函数重新导出 ===

function simd_add_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
begin
  Result := fafafa.core.simd.core.simd_add_f32x4(a, b);
end;

function simd_reduce_add_f32x4(const a: TSimdF32x4): Single;
begin
  Result := fafafa.core.simd.core.simd_reduce_add_f32x4(a);
end;

function simd_splat_f32x4(value: Single): TSimdF32x4;
begin
  Result := fafafa.core.simd.core.simd_splat_f32x4(value);
end;

function simd_extract_f32x4(const a: TSimdF32x4; index: Integer): Single;
begin
  Result := fafafa.core.simd.core.simd_extract_f32x4(a, index);
end;

function simd_insert_f32x4(const a: TSimdF32x4; value: Single; index: Integer): TSimdF32x4;
begin
  Result := fafafa.core.simd.core.simd_insert_f32x4(a, value, index);
end;

function simd_insert_i32x4(const a: TSimdI32x4; value: Int32; index: Integer): TSimdI32x4;
begin
  Result := fafafa.core.simd.core.simd_insert_i32x4(a, value, index);
end;

// === 其他缺失的函数实现 ===

function simd_add_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
begin
  Result := fafafa.core.simd.core.simd_add_f32x8(a, b);
end;

function simd_add_f32x16(const a, b: TSimdF32x16): TSimdF32x16;
begin
  Result := fafafa.core.simd.core.simd_add_f32x16(a, b);
end;

function simd_add_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
begin
  Result := fafafa.core.simd.core.simd_add_f64x2(a, b);
end;

function simd_add_f64x4(const a, b: TSimdF64x4): TSimdF64x4;
begin
  Result := fafafa.core.simd.core.simd_add_f64x4(a, b);
end;

function simd_add_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
begin
  Result := fafafa.core.simd.core.simd_add_i32x4(a, b);
end;

function simd_add_i32x8(const a, b: TSimdI32x8): TSimdI32x8;
begin
  Result := fafafa.core.simd.core.simd_add_i32x8(a, b);
end;

function simd_add_i32x16(const a, b: TSimdI32x16): TSimdI32x16;
begin
  Result := fafafa.core.simd.core.simd_add_i32x16(a, b);
end;

function simd_sub_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
begin
  Result := fafafa.core.simd.core.simd_sub_f32x4(a, b);
end;

function simd_sub_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
begin
  Result := fafafa.core.simd.core.simd_sub_f32x8(a, b);
end;

function simd_sub_f32x16(const a, b: TSimdF32x16): TSimdF32x16;
begin
  Result := fafafa.core.simd.core.simd_sub_f32x16(a, b);
end;

function simd_sub_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
begin
  Result := fafafa.core.simd.core.simd_sub_f64x2(a, b);
end;

function simd_sub_f64x4(const a, b: TSimdF64x4): TSimdF64x4;
begin
  Result := fafafa.core.simd.core.simd_sub_f64x4(a, b);
end;

function simd_sub_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
begin
  Result := fafafa.core.simd.core.simd_sub_i32x4(a, b);
end;

function simd_sub_i32x8(const a, b: TSimdI32x8): TSimdI32x8;
begin
  Result := fafafa.core.simd.core.simd_sub_i32x8(a, b);
end;

function simd_mul_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
begin
  Result := fafafa.core.simd.core.simd_mul_f32x4(a, b);
end;

function simd_mul_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
begin
  Result := fafafa.core.simd.core.simd_mul_f32x8(a, b);
end;

function simd_mul_f32x16(const a, b: TSimdF32x16): TSimdF32x16;
begin
  Result := fafafa.core.simd.core.simd_mul_f32x16(a, b);
end;

function simd_mul_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
begin
  Result := fafafa.core.simd.core.simd_mul_f64x2(a, b);
end;

function simd_mul_f64x4(const a, b: TSimdF64x4): TSimdF64x4;
begin
  Result := fafafa.core.simd.core.simd_mul_f64x4(a, b);
end;

function simd_mul_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
begin
  Result := fafafa.core.simd.core.simd_mul_i32x4(a, b);
end;

function simd_mul_i32x8(const a, b: TSimdI32x8): TSimdI32x8;
begin
  Result := fafafa.core.simd.core.simd_mul_i32x8(a, b);
end;

function simd_div_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
begin
  Result := fafafa.core.simd.core.simd_div_f32x4(a, b);
end;

function simd_div_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
begin
  Result := fafafa.core.simd.core.simd_div_f32x8(a, b);
end;

function simd_div_f32x16(const a, b: TSimdF32x16): TSimdF32x16;
begin
  Result := fafafa.core.simd.core.simd_div_f32x16(a, b);
end;

function simd_div_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
begin
  Result := fafafa.core.simd.core.simd_div_f64x2(a, b);
end;

function simd_div_f64x4(const a, b: TSimdF64x4): TSimdF64x4;
begin
  Result := fafafa.core.simd.core.simd_div_f64x4(a, b);
end;

function simd_reduce_add_f32x8(const a: TSimdF32x8): Single;
begin
  Result := fafafa.core.simd.core.simd_reduce_add_f32x8(a);
end;

function simd_reduce_add_f64x2(const a: TSimdF64x2): Double;
begin
  Result := fafafa.core.simd.core.simd_reduce_add_f64x2(a);
end;

function simd_reduce_add_i32x4(const a: TSimdI32x4): Int32;
begin
  Result := fafafa.core.simd.core.simd_reduce_add_i32x4(a);
end;

function simd_reduce_add_i32x8(const a: TSimdI32x8): Int32;
begin
  Result := fafafa.core.simd.core.simd_reduce_add_i32x8(a);
end;

function simd_splat_f32x8(value: Single): TSimdF32x8;
begin
  Result := fafafa.core.simd.core.simd_splat_f32x8(value);
end;

function simd_splat_i32x4(value: Int32): TSimdI32x4;
begin
  Result := fafafa.core.simd.core.simd_splat_i32x4(value);
end;

function simd_extract_i32x4(const a: TSimdI32x4; index: Integer): Int32;
begin
  Result := fafafa.core.simd.core.simd_extract_i32x4(a, index);
end;

// === 兼容性实现 ===

function SimdInfo: String;
begin
  if ForcedProfile <> '' then
    Result := ForcedProfile
  else
    Result := GetBestProfile;
end;

function SimdGetForcedProfile: String;
begin
  Result := ForcedProfile;
end;

procedure SimdSetForcedProfile(const profile: String);
begin
  ForcedProfile := profile;
end;

// === 内存操作函数实现（动态派发）===

function MemEqual(a, b: Pointer; len: SizeUInt): Boolean;
begin
  {$IFDEF CPUX86_64}
  // 动态选择最佳实现
  if HasAVX2 then
    Result := simd_memequal_avx2(a, b, len)
  else
    Result := MemEqual_Scalar(a, b, len);
  {$ELSE}
  Result := MemEqual_Scalar(a, b, len);
  {$ENDIF}
end;

function MemFindByte(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
begin
  {$IFDEF CPUX86_64}
  // 动态选择最佳实现
  if HasAVX2 then
    Result := simd_memfindbyte_avx2(p, len, value)
  else
    Result := MemFindByte_Scalar(p, len, value);
  {$ELSE}
  Result := MemFindByte_Scalar(p, len, value);
  {$ENDIF}
end;

function MemDiffRange(a, b: Pointer; len: SizeUInt): TDiffRange;
begin
  Result := MemDiffRange_Scalar(a, b, len);
end;

procedure MemCopy(src, dest: Pointer; len: SizeUInt);
begin
  MemCopy_Scalar(src, dest, len);
end;

procedure MemSet(p: Pointer; len: SizeUInt; value: Byte);
begin
  MemSet_Scalar(p, len, value);
end;

procedure MemReverse(p: Pointer; len: SizeUInt);
begin
  MemReverse_Scalar(p, len);
end;

// === 统计函数实现 ===

function SumBytes(p: Pointer; len: SizeUInt): QWord;
begin
  Result := SumBytes_Scalar(p, len);
end;

procedure MinMaxBytes(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
begin
  MinMaxBytes_Scalar(p, len, minVal, maxVal);
end;

function CountByte(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;
begin
  Result := CountByte_Scalar(p, len, value);
end;

// === 重新导出的函数实现 ===

// 文本处理函数实现
function Utf8Validate(p: Pointer; len: SizeUInt): LongBool;
begin
  Result := Utf8Validate_Scalar(p, len);
end;

function AsciiIEqual(a, b: Pointer; len: SizeUInt): LongBool;
begin
  Result := AsciiEqualIgnoreCase_Scalar(a, b, len);
end;

procedure ToLowerAscii(p: Pointer; len: SizeUInt);
begin
  ToLowerAscii_Scalar(p, len);
end;

procedure ToUpperAscii(p: Pointer; len: SizeUInt);
begin
  ToUpperAscii_Scalar(p, len);
end;

// 搜索函数实现
function BytesIndexOf(hay: Pointer; len: SizeUInt; ned: Pointer; nlen: SizeUInt): PtrInt;
begin
  Result := BytesIndexOf_Scalar(hay, len, ned, nlen);
end;

// 位集函数实现
function BitsetPopCount(p: Pointer; bitLen: SizeUInt): SizeUInt;
begin
  Result := BitsetPopCount_Scalar(p, bitLen);
end;

end.
