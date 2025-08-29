unit fafafa.core.simd.v2;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

// === fafafa.core.simd 2.0 主模块（简化版）===
// 设计目标：
// 1. 对标 Rust std::simd 的API设计
// 2. 真正的SIMD性能（不是假SIMD）
// 3. 类型安全的向量操作
// 4. 零开销抽象
// 5. 跨平台兼容性

uses
  fafafa.core.simd.v2.types,
  fafafa.core.simd.v2.detect,
  fafafa.core.simd.v2.dispatch,
  fafafa.core.simd.v2.math,
  fafafa.core.simd.v2.bitops,
  fafafa.core.simd.v2.shuffle;

// === 重新导出核心类型 ===
type
  // 单精度浮点向量
  TF32x4  = fafafa.core.simd.v2.types.TF32x4;
  TF32x8  = fafafa.core.simd.v2.types.TF32x8;

  // 双精度浮点向量
  TF64x2  = fafafa.core.simd.v2.types.TF64x2;
  TF64x4  = fafafa.core.simd.v2.types.TF64x4;

  // 有符号整数向量
  TI8x16  = fafafa.core.simd.v2.types.TI8x16;
  TI16x8  = fafafa.core.simd.v2.types.TI16x8;
  TI32x4  = fafafa.core.simd.v2.types.TI32x4;
  TI32x8  = fafafa.core.simd.v2.types.TI32x8;

  // 无符号整数向量
  TU32x4  = fafafa.core.simd.v2.types.TU32x4;

  // 掩码类型
  TMaskF32x4 = fafafa.core.simd.v2.types.TMaskF32x4;
  TMaskF32x8 = fafafa.core.simd.v2.types.TMaskF32x8;

  // 系统类型
  TSimdISA = fafafa.core.simd.v2.types.TSimdISA;
  TSimdISASet = fafafa.core.simd.v2.types.TSimdISASet;
  TSimdContext = fafafa.core.simd.v2.types.TSimdContext;
  TSimdError = fafafa.core.simd.v2.types.TSimdError;

// === 全局函数（对标 Rust std::simd API）===

// === 算术运算 ===
function simd_add_f32x4(const A, B: TF32x4): TF32x4; inline;
function simd_sub_f32x4(const A, B: TF32x4): TF32x4; inline;
function simd_mul_f32x4(const A, B: TF32x4): TF32x4; inline;
function simd_div_f32x4(const A, B: TF32x4): TF32x4; inline;

function simd_add_f32x8(const A, B: TF32x8): TF32x8; inline;
function simd_sub_f32x8(const A, B: TF32x8): TF32x8; inline;
function simd_mul_f32x8(const A, B: TF32x8): TF32x8; inline;
function simd_div_f32x8(const A, B: TF32x8): TF32x8; inline;

function simd_add_i32x4(const A, B: TI32x4): TI32x4; inline;
function simd_sub_i32x4(const A, B: TI32x4): TI32x4; inline;
function simd_mul_i32x4(const A, B: TI32x4): TI32x4; inline;

// === F64x2 双精度向量操作 ===
function simd_add_f64x2(const A, B: TF64x2): TF64x2; inline;
function simd_sub_f64x2(const A, B: TF64x2): TF64x2; inline;
function simd_mul_f64x2(const A, B: TF64x2): TF64x2; inline;
function simd_div_f64x2(const A, B: TF64x2): TF64x2; inline;
function simd_sqrt_f64x2(const A: TF64x2): TF64x2; inline;
function simd_min_f64x2(const A, B: TF64x2): TF64x2; inline;
function simd_max_f64x2(const A, B: TF64x2): TF64x2; inline;
function simd_reduce_add_f64x2(const A: TF64x2): Double; inline;
function simd_splat_f64x2(const Value: Double): TF64x2; inline;

// === I8x16 字节向量操作 ===
function simd_add_i8x16(const A, B: TI8x16): TI8x16; inline;
function simd_sub_i8x16(const A, B: TI8x16): TI8x16; inline;
function simd_reduce_add_i8x16(const A: TI8x16): Int32; inline;
function simd_splat_i8x16(const Value: Int8): TI8x16; inline;

// === I16x8 短整数向量操作 ===
function simd_add_i16x8(const A, B: TI16x8): TI16x8; inline;
function simd_sub_i16x8(const A, B: TI16x8): TI16x8; inline;
function simd_mul_i16x8(const A, B: TI16x8): TI16x8; inline;
function simd_reduce_add_i16x8(const A: TI16x8): Int32; inline;
function simd_splat_i16x8(const Value: Int16): TI16x8; inline;

// === U32x4 无符号整数向量操作 ===
function simd_add_u32x4(const A, B: TU32x4): TU32x4; inline;
function simd_sub_u32x4(const A, B: TU32x4): TU32x4; inline;
function simd_mul_u32x4(const A, B: TU32x4): TU32x4; inline;
function simd_reduce_add_u32x4(const A: TU32x4): UInt64; inline;
function simd_reduce_min_u32x4(const A: TU32x4): UInt32; inline;
function simd_reduce_max_u32x4(const A: TU32x4): UInt32; inline;
function simd_splat_u32x4(const Value: UInt32): TU32x4; inline;

// === 高级数学函数（重新导出）===

// 三角函数
function simd_sin_f32x4(const A: TF32x4): TF32x4; inline;
function simd_cos_f32x4(const A: TF32x4): TF32x4; inline;
function simd_tan_f32x4(const A: TF32x4): TF32x4; inline;
function simd_atan_f32x4(const A: TF32x4): TF32x4; inline;
function simd_atan2_f32x4(const Y, X: TF32x4): TF32x4; inline;

// 指数和对数函数
function simd_exp_f32x4(const A: TF32x4): TF32x4; inline;
function simd_log_f32x4(const A: TF32x4): TF32x4; inline;
function simd_pow_f32x4(const Base, Exp: TF32x4): TF32x4; inline;

// 双曲函数
function simd_sinh_f32x4(const A: TF32x4): TF32x4; inline;
function simd_cosh_f32x4(const A: TF32x4): TF32x4; inline;
function simd_tanh_f32x4(const A: TF32x4): TF32x4; inline;

// 实用函数
function simd_abs_f32x4(const A: TF32x4): TF32x4; inline;
function simd_floor_f32x4(const A: TF32x4): TF32x4; inline;
function simd_ceil_f32x4(const A: TF32x4): TF32x4; inline;
function simd_round_f32x4(const A: TF32x4): TF32x4; inline;

// === 位操作和逻辑运算（重新导出）===

// 基础位操作
function simd_and_i32x4(const A, B: TI32x4): TI32x4; inline;
function simd_or_i32x4(const A, B: TI32x4): TI32x4; inline;
function simd_xor_i32x4(const A, B: TI32x4): TI32x4; inline;
function simd_not_i32x4(const A: TI32x4): TI32x4; inline;

// 位移操作
function simd_shl_i32x4(const A: TI32x4; const Shift: Integer): TI32x4; inline;
function simd_shr_i32x4(const A: TI32x4; const Shift: Integer): TI32x4; inline;
function simd_sar_i32x4(const A: TI32x4; const Shift: Integer): TI32x4; inline;

// 位计数操作
function simd_popcnt_i32x4(const A: TI32x4): TI32x4; inline;
function simd_lzcnt_i32x4(const A: TI32x4): TI32x4; inline;

// 浮点数位操作
function simd_and_f32x4(const A, B: TF32x4): TF32x4; inline;
function simd_or_f32x4(const A, B: TF32x4): TF32x4; inline;
function simd_xor_f32x4(const A, B: TF32x4): TF32x4; inline;

// === 向量重排和混洗（重新导出）===

// 基础混洗操作
function simd_shuffle_f32x4(const A: TF32x4; const Mask: array of Integer): TF32x4; inline;
function simd_shuffle_i32x4(const A: TI32x4; const Mask: array of Integer): TI32x4; inline;

// 排列和广播
function simd_permute_f32x4(const A: TF32x4; const Indices: TI32x4): TF32x4; inline;
function simd_broadcast_f32x4(const A: TF32x4; const Index: Integer): TF32x4; inline;

// 反转和旋转
function simd_reverse_f32x4(const A: TF32x4): TF32x4; inline;
function simd_rotate_left_f32x4(const A: TF32x4; const Count: Integer): TF32x4; inline;

// 交错操作
function simd_interleave_low_f32x4(const A, B: TF32x4): TF32x4; inline;
function simd_interleave_high_f32x4(const A, B: TF32x4): TF32x4; inline;

// 特殊混洗
function simd_blend_f32x4(const A, B: TF32x4; const Mask: Integer): TF32x4; inline;
function simd_select_f32x4(const Condition: TMaskF32x4; const A, B: TF32x4): TF32x4; inline;

// === 聚合运算 ===
function simd_reduce_add_f32x4(const A: TF32x4): Single; inline;
function simd_reduce_add_i32x4(const A: TI32x4): Int32; inline;

// === 比较运算 ===
function simd_eq_f32x4(const A, B: TF32x4): TMaskF32x4; inline;
function simd_lt_f32x4(const A, B: TF32x4): TMaskF32x4; inline;

// === 数学函数 ===
function simd_sqrt_f32x4(const A: TF32x4): TF32x4; inline;
function simd_min_f32x4(const A, B: TF32x4): TF32x4; inline;
function simd_max_f32x4(const A, B: TF32x4): TF32x4; inline;

// === 向量操作 ===
function simd_splat_f32x4(const Value: Single): TF32x4; inline;
function simd_load_f32x4(Ptr: Pointer): TF32x4; inline;
function simd_store_f32x4(Ptr: Pointer; const A: TF32x4): Boolean; inline;
function simd_reverse_f32x4(const A: TF32x4): TF32x4; inline;

// === 系统管理函数 ===
function simd_detect_capabilities: TSimdISASet; inline;
function simd_get_cpu_info: String; inline;
function simd_get_best_profile: String; inline;
function simd_get_context: TSimdContext; inline;
procedure simd_set_context(const AContext: TSimdContext); inline;

// === 调试和性能分析 ===
procedure simd_enable_profiling(AEnable: Boolean);
function simd_get_performance_stats: String;
procedure simd_print_system_info;

implementation

// 简单的 Min/Max 函数实现
function Min(A, B: Single): Single; inline;
begin
  if A < B then Result := A else Result := B;
end;

function Max(A, B: Single): Single; inline;
begin
  if A > B then Result := A else Result := B;
end;

function Sqrt(A: Single): Single; inline;
begin
  // 改进的牛顿法平方根近似（更高精度）
  if A <= 0 then
    Result := 0
  else
  begin
    Result := A * 0.5; // 更好的初始猜测
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5; // 额外迭代提高精度
    Result := (Result + A / Result) * 0.5;
  end;
end;

function BoolToStr(A: Boolean; const TrueStr: String = 'True'): String; inline;
begin
  if A then Result := TrueStr else Result := 'False';
end;

function Format(const Fmt: String; const Args: array of const): String;
var
  I: Integer;
  ArgIndex: Integer;
  Result_: String;
  C: Char;
begin
  Result_ := '';
  ArgIndex := 0;
  I := 1;

  while I <= Length(Fmt) do
  begin
    C := Fmt[I];
    if (C = '%') and (I < Length(Fmt)) then
    begin
      Inc(I);
      C := Fmt[I];
      if (C = 's') and (ArgIndex <= High(Args)) then
      begin
        case Args[ArgIndex].VType of
          vtString: Result_ := Result_ + Args[ArgIndex].VString^;
          vtAnsiString: Result_ := Result_ + AnsiString(Args[ArgIndex].VAnsiString);
          vtPChar: Result_ := Result_ + Args[ArgIndex].VPChar;
          else Result_ := Result_ + '?';
        end;
        Inc(ArgIndex);
      end
      else
        Result_ := Result_ + C;
    end
    else
      Result_ := Result_ + C;
    Inc(I);
  end;

  Result := Result_;
end;

// === 算术运算实现 ===

function simd_add_f32x4(const A, B: TF32x4): TF32x4;
begin
  Result := simd_dispatch_f32x4_add(A, B);
end;

function simd_sub_f32x4(const A, B: TF32x4): TF32x4;
begin
  Result := simd_dispatch_f32x4_sub(A, B);
end;

function simd_mul_f32x4(const A, B: TF32x4): TF32x4;
begin
  Result := simd_dispatch_f32x4_mul(A, B);
end;

function simd_div_f32x4(const A, B: TF32x4): TF32x4;
begin
  Result := simd_dispatch_f32x4_div(A, B);
end;

function simd_add_f32x8(const A, B: TF32x8): TF32x8;
var
  I: Integer;
begin
  // 暂时使用标量实现，后续将替换为真正的SIMD
  for I := 0 to 7 do
    Result.Data[I] := A.Data[I] + B.Data[I];
end;

function simd_sub_f32x8(const A, B: TF32x8): TF32x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.Data[I] := A.Data[I] - B.Data[I];
end;

function simd_mul_f32x8(const A, B: TF32x8): TF32x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.Data[I] := A.Data[I] * B.Data[I];
end;

function simd_div_f32x8(const A, B: TF32x8): TF32x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.Data[I] := A.Data[I] / B.Data[I];
end;

function simd_add_i32x4(const A, B: TI32x4): TI32x4;
begin
  Result := simd_dispatch_i32x4_add(A, B);
end;

function simd_sub_i32x4(const A, B: TI32x4): TI32x4;
begin
  Result := simd_dispatch_i32x4_sub(A, B);
end;

function simd_mul_i32x4(const A, B: TI32x4): TI32x4;
begin
  Result := simd_dispatch_i32x4_mul(A, B);
end;

// === F64x2 双精度向量操作实现 ===

function simd_add_f64x2(const A, B: TF64x2): TF64x2;
begin
  Result := A.Add(B);
end;

function simd_sub_f64x2(const A, B: TF64x2): TF64x2;
begin
  Result := A.Sub(B);
end;

function simd_mul_f64x2(const A, B: TF64x2): TF64x2;
begin
  Result := A.Mul(B);
end;

function simd_div_f64x2(const A, B: TF64x2): TF64x2;
begin
  Result := A.Divide(B);
end;

function simd_sqrt_f64x2(const A: TF64x2): TF64x2;
begin
  Result := A.Sqrt;
end;

function simd_min_f64x2(const A, B: TF64x2): TF64x2;
begin
  Result := A.MinVec(B);
end;

function simd_max_f64x2(const A, B: TF64x2): TF64x2;
begin
  Result := A.MaxVec(B);
end;

function simd_reduce_add_f64x2(const A: TF64x2): Double;
begin
  Result := A.ReduceAdd;
end;

function simd_splat_f64x2(const Value: Double): TF64x2;
begin
  Result := TF64x2.Splat(Value);
end;

// === I8x16 字节向量操作实现 ===

function simd_add_i8x16(const A, B: TI8x16): TI8x16;
begin
  Result := A.Add(B);
end;

function simd_sub_i8x16(const A, B: TI8x16): TI8x16;
begin
  Result := A.Sub(B);
end;

function simd_reduce_add_i8x16(const A: TI8x16): Int32;
begin
  Result := A.ReduceAdd;
end;

function simd_splat_i8x16(const Value: Int8): TI8x16;
begin
  Result := TI8x16.Splat(Value);
end;

// === I16x8 短整数向量操作实现 ===

function simd_add_i16x8(const A, B: TI16x8): TI16x8;
begin
  Result := A.Add(B);
end;

function simd_sub_i16x8(const A, B: TI16x8): TI16x8;
begin
  Result := A.Sub(B);
end;

function simd_mul_i16x8(const A, B: TI16x8): TI16x8;
begin
  Result := A.Mul(B);
end;

function simd_reduce_add_i16x8(const A: TI16x8): Int32;
begin
  Result := A.ReduceAdd;
end;

function simd_splat_i16x8(const Value: Int16): TI16x8;
begin
  Result := TI16x8.Splat(Value);
end;

// === U32x4 无符号整数向量操作实现 ===

function simd_add_u32x4(const A, B: TU32x4): TU32x4;
begin
  Result := A.Add(B);
end;

function simd_sub_u32x4(const A, B: TU32x4): TU32x4;
begin
  Result := A.Sub(B);
end;

function simd_mul_u32x4(const A, B: TU32x4): TU32x4;
begin
  Result := A.Mul(B);
end;

function simd_reduce_add_u32x4(const A: TU32x4): UInt64;
begin
  Result := A.ReduceAdd;
end;

function simd_reduce_min_u32x4(const A: TU32x4): UInt32;
begin
  Result := A.ReduceMin;
end;

function simd_reduce_max_u32x4(const A: TU32x4): UInt32;
begin
  Result := A.ReduceMax;
end;

function simd_splat_u32x4(const Value: UInt32): TU32x4;
begin
  Result := TU32x4.Splat(Value);
end;

// === 高级数学函数实现（转发到数学模块）===

// 三角函数
function simd_sin_f32x4(const A: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.math.simd_sin_f32x4(A);
end;

function simd_cos_f32x4(const A: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.math.simd_cos_f32x4(A);
end;

function simd_tan_f32x4(const A: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.math.simd_tan_f32x4(A);
end;

function simd_atan_f32x4(const A: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.math.simd_atan_f32x4(A);
end;

function simd_atan2_f32x4(const Y, X: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.math.simd_atan2_f32x4(Y, X);
end;

// 指数和对数函数
function simd_exp_f32x4(const A: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.math.simd_exp_f32x4(A);
end;

function simd_log_f32x4(const A: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.math.simd_log_f32x4(A);
end;

function simd_pow_f32x4(const Base, Exp: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.math.simd_pow_f32x4(Base, Exp);
end;

// 双曲函数
function simd_sinh_f32x4(const A: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.math.simd_sinh_f32x4(A);
end;

function simd_cosh_f32x4(const A: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.math.simd_cosh_f32x4(A);
end;

function simd_tanh_f32x4(const A: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.math.simd_tanh_f32x4(A);
end;

// 实用函数
function simd_abs_f32x4(const A: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.math.simd_abs_f32x4(A);
end;

function simd_floor_f32x4(const A: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.math.simd_floor_f32x4(A);
end;

function simd_ceil_f32x4(const A: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.math.simd_ceil_f32x4(A);
end;

function simd_round_f32x4(const A: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.math.simd_round_f32x4(A);
end;

// === 位操作和逻辑运算实现（转发到位操作模块）===

// 基础位操作
function simd_and_i32x4(const A, B: TI32x4): TI32x4;
begin
  Result := fafafa.core.simd.v2.bitops.simd_and_i32x4(A, B);
end;

function simd_or_i32x4(const A, B: TI32x4): TI32x4;
begin
  Result := fafafa.core.simd.v2.bitops.simd_or_i32x4(A, B);
end;

function simd_xor_i32x4(const A, B: TI32x4): TI32x4;
begin
  Result := fafafa.core.simd.v2.bitops.simd_xor_i32x4(A, B);
end;

function simd_not_i32x4(const A: TI32x4): TI32x4;
begin
  Result := fafafa.core.simd.v2.bitops.simd_not_i32x4(A);
end;

// 位移操作
function simd_shl_i32x4(const A: TI32x4; const Shift: Integer): TI32x4;
begin
  Result := fafafa.core.simd.v2.bitops.simd_shl_i32x4(A, Shift);
end;

function simd_shr_i32x4(const A: TI32x4; const Shift: Integer): TI32x4;
begin
  Result := fafafa.core.simd.v2.bitops.simd_shr_i32x4(A, Shift);
end;

function simd_sar_i32x4(const A: TI32x4; const Shift: Integer): TI32x4;
begin
  Result := fafafa.core.simd.v2.bitops.simd_sar_i32x4(A, Shift);
end;

// 位计数操作
function simd_popcnt_i32x4(const A: TI32x4): TI32x4;
begin
  Result := fafafa.core.simd.v2.bitops.simd_popcnt_i32x4(A);
end;

function simd_lzcnt_i32x4(const A: TI32x4): TI32x4;
begin
  Result := fafafa.core.simd.v2.bitops.simd_lzcnt_i32x4(A);
end;

// 浮点数位操作
function simd_and_f32x4(const A, B: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.bitops.simd_and_f32x4(A, B);
end;

function simd_or_f32x4(const A, B: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.bitops.simd_or_f32x4(A, B);
end;

function simd_xor_f32x4(const A, B: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.bitops.simd_xor_f32x4(A, B);
end;

// === 向量重排和混洗实现（转发到混洗模块）===

// 基础混洗操作
function simd_shuffle_f32x4(const A: TF32x4; const Mask: array of Integer): TF32x4;
begin
  Result := fafafa.core.simd.v2.shuffle.simd_shuffle_f32x4(A, Mask);
end;

function simd_shuffle_i32x4(const A: TI32x4; const Mask: array of Integer): TI32x4;
begin
  Result := fafafa.core.simd.v2.shuffle.simd_shuffle_i32x4(A, Mask);
end;

// 排列和广播
function simd_permute_f32x4(const A: TF32x4; const Indices: TI32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.shuffle.simd_permute_f32x4(A, Indices);
end;

function simd_broadcast_f32x4(const A: TF32x4; const Index: Integer): TF32x4;
begin
  Result := fafafa.core.simd.v2.shuffle.simd_broadcast_f32x4(A, Index);
end;

// 反转和旋转
function simd_reverse_f32x4(const A: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.shuffle.simd_reverse_f32x4(A);
end;

function simd_rotate_left_f32x4(const A: TF32x4; const Count: Integer): TF32x4;
begin
  Result := fafafa.core.simd.v2.shuffle.simd_rotate_left_f32x4(A, Count);
end;

// 交错操作
function simd_interleave_low_f32x4(const A, B: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.shuffle.simd_interleave_low_f32x4(A, B);
end;

function simd_interleave_high_f32x4(const A, B: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.shuffle.simd_interleave_high_f32x4(A, B);
end;

// 特殊混洗
function simd_blend_f32x4(const A, B: TF32x4; const Mask: Integer): TF32x4;
begin
  Result := fafafa.core.simd.v2.shuffle.simd_blend_f32x4(A, B, Mask);
end;

function simd_select_f32x4(const Condition: TMaskF32x4; const A, B: TF32x4): TF32x4;
begin
  Result := fafafa.core.simd.v2.shuffle.simd_select_f32x4(Condition, A, B);
end;

// === 聚合运算实现 ===

function simd_reduce_add_f32x4(const A: TF32x4): Single;
begin
  Result := simd_dispatch_f32x4_reduce_add(A);
end;

function simd_reduce_add_i32x4(const A: TI32x4): Int32;
begin
  Result := simd_dispatch_i32x4_reduce_add(A);
end;

// === 比较运算实现 ===

function simd_eq_f32x4(const A, B: TF32x4): TMaskF32x4;
begin
  Result := simd_dispatch_f32x4_eq(A, B);
end;

function simd_lt_f32x4(const A, B: TF32x4): TMaskF32x4;
begin
  Result := simd_dispatch_f32x4_lt(A, B);
end;

// === 数学函数实现 ===

function simd_sqrt_f32x4(const A: TF32x4): TF32x4;
begin
  Result := simd_dispatch_f32x4_sqrt(A);
end;

function simd_min_f32x4(const A, B: TF32x4): TF32x4;
begin
  Result := simd_dispatch_f32x4_min(A, B);
end;

function simd_max_f32x4(const A, B: TF32x4): TF32x4;
begin
  Result := simd_dispatch_f32x4_max(A, B);
end;

// === 向量操作实现 ===

function simd_splat_f32x4(const Value: Single): TF32x4;
begin
  Result := simd_dispatch_f32x4_splat(Value);
end;

function simd_load_f32x4(Ptr: Pointer): TF32x4;
begin
  Result := simd_dispatch_f32x4_load(Ptr);
end;

function simd_store_f32x4(Ptr: Pointer; const A: TF32x4): Boolean;
begin
  try
    simd_dispatch_f32x4_store(Ptr, A);
    Result := True;
  except
    Result := False;
  end;
end;

function simd_reverse_f32x4(const A: TF32x4): TF32x4;
begin
  Result := A.Reverse;
end;

// === 系统管理函数实现 ===

function simd_detect_capabilities: TSimdISASet;
begin
  Result := fafafa.core.simd.v2.detect.simd_detect_capabilities;
end;

function simd_get_cpu_info: String;
begin
  Result := fafafa.core.simd.v2.detect.simd_get_cpu_info;
end;

function simd_get_best_profile: String;
begin
  Result := fafafa.core.simd.v2.detect.simd_get_best_profile;
end;

function simd_get_context: TSimdContext;
begin
  Result := fafafa.core.simd.v2.types.simd_get_context;
end;

procedure simd_set_context(const AContext: TSimdContext);
begin
  fafafa.core.simd.v2.types.simd_set_context(AContext);
end;

// === 调试和性能分析实现 ===

procedure simd_enable_profiling(AEnable: Boolean);
var
  Context: TSimdContext;
begin
  Context := simd_get_context;
  Context.ProfileMode := AEnable;
  simd_set_context(Context);
end;

function simd_get_performance_stats: String;
var
  Context: TSimdContext;
  ISAName: String;
begin
  Context := simd_get_context;

  // 简单的ISA名称映射
  case Context.ActiveISA of
    isaScalar: ISAName := 'Scalar';
    isaSSE2: ISAName := 'SSE2';
    isaAVX2: ISAName := 'AVX2';
    isaAVX512F: ISAName := 'AVX-512';
    isaNEON: ISAName := 'NEON';
    else ISAName := 'Unknown';
  end;

  Result := Format('Active ISA: %s, Profile Mode: %s',
    [ISAName, BoolToStr(Context.ProfileMode, 'True')]);
end;

procedure simd_print_system_info;
var
  Caps: TSimdISASet;
  ISA: TSimdISA;
  CapsList, ISAName: String;
begin
  WriteLn('=== SIMD System Information ===');
  WriteLn('CPU: ', simd_get_cpu_info);
  WriteLn('Best Profile: ', simd_get_best_profile);

  Caps := simd_detect_capabilities;
  CapsList := '';
  for ISA := Low(TSimdISA) to High(TSimdISA) do
  begin
    if ISA in Caps then
    begin
      if CapsList <> '' then
        CapsList := CapsList + ', ';

      // 简单的ISA名称映射
      case ISA of
        isaScalar: ISAName := 'Scalar';
        isaSSE2: ISAName := 'SSE2';
        isaSSE3: ISAName := 'SSE3';
        isaSSSE3: ISAName := 'SSSE3';
        isaSSE41: ISAName := 'SSE4.1';
        isaSSE42: ISAName := 'SSE4.2';
        isaAVX: ISAName := 'AVX';
        isaAVX2: ISAName := 'AVX2';
        isaAVX512F: ISAName := 'AVX-512F';
        isaAVX512VL: ISAName := 'AVX-512VL';
        isaAVX512BW: ISAName := 'AVX-512BW';
        isaAVX512DQ: ISAName := 'AVX-512DQ';
        isaNEON: ISAName := 'NEON';
        isaSVE: ISAName := 'SVE';
        isaSVE2: ISAName := 'SVE2';
        else ISAName := 'Unknown';
      end;

      CapsList := CapsList + ISAName;
    end;
  end;

  WriteLn('Supported ISAs: ', CapsList);
  WriteLn('Performance Stats: ', simd_get_performance_stats);
  WriteLn('================================');
end;

end.
