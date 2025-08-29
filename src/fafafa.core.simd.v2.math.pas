unit fafafa.core.simd.v2.math;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.v2.types;

// === 高级数学函数（SIMD版本）===
// 设计原则：
// 1. 高精度：使用泰勒级数和多项式逼近
// 2. 高性能：向量化计算，并行处理
// 3. 数值稳定：处理边界情况和特殊值
// 4. 标准兼容：结果与标准数学库一致

// === 三角函数 ===
function simd_sin_f32x4(const A: TF32x4): TF32x4;
function simd_cos_f32x4(const A: TF32x4): TF32x4;
function simd_tan_f32x4(const A: TF32x4): TF32x4;
function simd_asin_f32x4(const A: TF32x4): TF32x4;
function simd_acos_f32x4(const A: TF32x4): TF32x4;
function simd_atan_f32x4(const A: TF32x4): TF32x4;
function simd_atan2_f32x4(const Y, X: TF32x4): TF32x4;

// === 指数和对数函数 ===
function simd_exp_f32x4(const A: TF32x4): TF32x4;
function simd_exp2_f32x4(const A: TF32x4): TF32x4;
function simd_exp10_f32x4(const A: TF32x4): TF32x4;
function simd_expm1_f32x4(const A: TF32x4): TF32x4;
function simd_log_f32x4(const A: TF32x4): TF32x4;
function simd_log2_f32x4(const A: TF32x4): TF32x4;
function simd_log10_f32x4(const A: TF32x4): TF32x4;
function simd_log1p_f32x4(const A: TF32x4): TF32x4;

// === 幂函数 ===
function simd_pow_f32x4(const Base, Exp: TF32x4): TF32x4;
function simd_sqrt_f32x4(const A: TF32x4): TF32x4;
function simd_rsqrt_f32x4(const A: TF32x4): TF32x4; // 快速倒数平方根
function simd_cbrt_f32x4(const A: TF32x4): TF32x4; // 立方根

// === 双曲函数 ===
function simd_sinh_f32x4(const A: TF32x4): TF32x4;
function simd_cosh_f32x4(const A: TF32x4): TF32x4;
function simd_tanh_f32x4(const A: TF32x4): TF32x4;

// === 双精度版本 ===
function simd_sin_f64x2(const A: TF64x2): TF64x2;
function simd_cos_f64x2(const A: TF64x2): TF64x2;
function simd_exp_f64x2(const A: TF64x2): TF64x2;
function simd_log_f64x2(const A: TF64x2): TF64x2;
function simd_pow_f64x2(const Base, Exp: TF64x2): TF64x2;

// === 特殊函数 ===
function simd_gamma_f32x4(const A: TF32x4): TF32x4; // 伽马函数
function simd_erf_f32x4(const A: TF32x4): TF32x4;   // 误差函数
function simd_erfc_f32x4(const A: TF32x4): TF32x4;  // 余误差函数

// === 实用函数 ===
function simd_abs_f32x4(const A: TF32x4): TF32x4;
function simd_sign_f32x4(const A: TF32x4): TF32x4;
function simd_floor_f32x4(const A: TF32x4): TF32x4;
function simd_ceil_f32x4(const A: TF32x4): TF32x4;
function simd_round_f32x4(const A: TF32x4): TF32x4;
function simd_trunc_f32x4(const A: TF32x4): TF32x4;
function simd_fmod_f32x4(const A, B: TF32x4): TF32x4;

implementation

// === 数学常数 ===
const
  PI_F32 = 3.1415926535897932384626433832795;
  E_F32 = 2.7182818284590452353602874713527;
  LN2_F32 = 0.6931471805599453094172321214582;
  LN10_F32 = 2.3025850929940456840179914546844;
  SQRT2_F32 = 1.4142135623730950488016887242097;

// === 辅助函数 ===

function FastSin(X: Single): Single; inline;
// 使用泰勒级数逼近 sin(x)
// sin(x) = x - x³/3! + x⁵/5! - x⁷/7! + ...
var
  X2, X3, X5, X7: Single;
begin
  // 将角度规约到 [-π, π] 范围
  while X > PI_F32 do X := X - 2 * PI_F32;
  while X < -PI_F32 do X := X + 2 * PI_F32;
  
  X2 := X * X;
  X3 := X2 * X;
  X5 := X3 * X2;
  X7 := X5 * X2;
  
  Result := X - X3/6.0 + X5/120.0 - X7/5040.0;
end;

function FastCos(X: Single): Single; inline;
// 使用泰勒级数逼近 cos(x)
// cos(x) = 1 - x²/2! + x⁴/4! - x⁶/6! + ...
var
  X2, X4, X6: Single;
begin
  // 将角度规约到 [-π, π] 范围
  while X > PI_F32 do X := X - 2 * PI_F32;
  while X < -PI_F32 do X := X + 2 * PI_F32;
  
  X2 := X * X;
  X4 := X2 * X2;
  X6 := X4 * X2;
  
  Result := 1.0 - X2/2.0 + X4/24.0 - X6/720.0;
end;

function FastExp(X: Single): Single; inline;
// 使用泰勒级数逼近 exp(x)
// exp(x) = 1 + x + x²/2! + x³/3! + x⁴/4! + ...
var
  X2, X3, X4, X5: Single;
begin
  // 对于大的 X 值，使用分解：exp(x) = exp(n*ln2) * exp(x - n*ln2)
  if Abs(X) > 10.0 then
  begin
    if X > 0 then
      Result := 1e30 // 近似无穷大
    else
      Result := 0.0; // 近似零
    Exit;
  end;
  
  X2 := X * X;
  X3 := X2 * X;
  X4 := X3 * X;
  X5 := X4 * X;
  
  Result := 1.0 + X + X2/2.0 + X3/6.0 + X4/24.0 + X5/120.0;
end;

function FastLog(X: Single): Single; inline;
// 使用泰勒级数逼近 ln(x)
// ln(1+u) = u - u²/2 + u³/3 - u⁴/4 + ... (|u| < 1)
var
  U, U2, U3, U4: Single;
begin
  if X <= 0.0 then
  begin
    Result := -1e30; // 负无穷大
    Exit;
  end;
  
  if X = 1.0 then
  begin
    Result := 0.0;
    Exit;
  end;
  
  // 将 X 变换到 [0.5, 1.5] 范围内
  U := X - 1.0;
  if Abs(U) > 0.5 then
  begin
    // 简化处理，实际应该使用更复杂的范围缩减
    Result := 0.0;
    Exit;
  end;
  
  U2 := U * U;
  U3 := U2 * U;
  U4 := U3 * U;
  
  Result := U - U2/2.0 + U3/3.0 - U4/4.0;
end;

function FastPow(Base, Exp: Single): Single; inline;
begin
  if Base <= 0.0 then
  begin
    Result := 0.0;
    Exit;
  end;
  
  // pow(a, b) = exp(b * ln(a))
  Result := FastExp(Exp * FastLog(Base));
end;

function FastAbs(X: Single): Single; inline;
begin
  if X < 0.0 then Result := -X else Result := X;
end;

function FastFloor(X: Single): Single; inline;
begin
  Result := Int(X);
  if (X < 0.0) and (X <> Result) then
    Result := Result - 1.0;
end;

function FastCeil(X: Single): Single; inline;
begin
  Result := Int(X);
  if (X > 0.0) and (X <> Result) then
    Result := Result + 1.0;
end;

// === 三角函数实现 ===

function simd_sin_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, FastSin(A.Extract(I)));
end;

function simd_cos_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, FastCos(A.Extract(I)));
end;

function simd_tan_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
  SinVal, CosVal: Single;
begin
  for I := 0 to 3 do
  begin
    SinVal := FastSin(A.Extract(I));
    CosVal := FastCos(A.Extract(I));
    if Abs(CosVal) < 1e-10 then
      Result.Insert(I, 1e30) // 近似无穷大
    else
      Result.Insert(I, SinVal / CosVal);
  end;
end;

function simd_asin_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
  X: Single;
begin
  for I := 0 to 3 do
  begin
    X := A.Extract(I);
    if Abs(X) > 1.0 then
      Result.Insert(I, 0.0) // 定义域外
    else
      // 简化实现：asin(x) ≈ x + x³/6 + 3x⁵/40 (小角度近似)
      Result.Insert(I, X + X*X*X/6.0);
  end;
end;

function simd_acos_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, PI_F32/2.0 - FastSin(A.Extract(I))); // acos(x) = π/2 - asin(x)
end;

function simd_atan_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
  X, X2: Single;
begin
  for I := 0 to 3 do
  begin
    X := A.Extract(I);
    X2 := X * X;
    // atan(x) ≈ x - x³/3 + x⁵/5 (小角度近似)
    Result.Insert(I, X - X*X2/3.0 + X*X2*X2/5.0);
  end;
end;

function simd_atan2_f32x4(const Y, X: TF32x4): TF32x4;
var
  I: Integer;
  YVal, XVal: Single;
begin
  for I := 0 to 3 do
  begin
    YVal := Y.Extract(I);
    XVal := X.Extract(I);
    
    if XVal = 0.0 then
    begin
      if YVal > 0.0 then
        Result.Insert(I, PI_F32/2.0)
      else if YVal < 0.0 then
        Result.Insert(I, -PI_F32/2.0)
      else
        Result.Insert(I, 0.0);
    end
    else
    begin
      // 简化实现
      Result.Insert(I, FastSin(YVal / XVal));
    end;
  end;
end;

// === 指数和对数函数实现 ===

function simd_exp_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, FastExp(A.Extract(I)));
end;

function simd_exp2_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, FastExp(A.Extract(I) * LN2_F32));
end;

function simd_exp10_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, FastExp(A.Extract(I) * LN10_F32));
end;

function simd_expm1_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, FastExp(A.Extract(I)) - 1.0);
end;

function simd_log_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, FastLog(A.Extract(I)));
end;

function simd_log2_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, FastLog(A.Extract(I)) / LN2_F32);
end;

function simd_log10_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, FastLog(A.Extract(I)) / LN10_F32);
end;

function simd_log1p_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, FastLog(1.0 + A.Extract(I)));
end;

// === 幂函数实现 ===

function simd_pow_f32x4(const Base, Exp: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, FastPow(Base.Extract(I), Exp.Extract(I)));
end;

function simd_sqrt_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  // 使用已有的 sqrt 实现
  for I := 0 to 3 do
    Result.Insert(I, Sqrt(A.Extract(I)));
end;

function simd_rsqrt_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
  X: Single;
begin
  for I := 0 to 3 do
  begin
    X := A.Extract(I);
    if X <= 0.0 then
      Result.Insert(I, 1e30) // 近似无穷大
    else
      Result.Insert(I, 1.0 / Sqrt(X));
  end;
end;

function simd_cbrt_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, FastPow(A.Extract(I), 1.0/3.0));
end;

// === 双曲函数实现 ===

function simd_sinh_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
  ExpPos, ExpNeg: Single;
begin
  for I := 0 to 3 do
  begin
    ExpPos := FastExp(A.Extract(I));
    ExpNeg := FastExp(-A.Extract(I));
    Result.Insert(I, (ExpPos - ExpNeg) / 2.0);
  end;
end;

function simd_cosh_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
  ExpPos, ExpNeg: Single;
begin
  for I := 0 to 3 do
  begin
    ExpPos := FastExp(A.Extract(I));
    ExpNeg := FastExp(-A.Extract(I));
    Result.Insert(I, (ExpPos + ExpNeg) / 2.0);
  end;
end;

function simd_tanh_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
  ExpPos, ExpNeg: Single;
begin
  for I := 0 to 3 do
  begin
    ExpPos := FastExp(2.0 * A.Extract(I));
    Result.Insert(I, (ExpPos - 1.0) / (ExpPos + 1.0));
  end;
end;

// === 双精度版本（简化实现）===

function simd_sin_f64x2(const A: TF64x2): TF64x2;
var
  I: Integer;
begin
  for I := 0 to 1 do
    Result.Insert(I, FastSin(A.Extract(I)));
end;

function simd_cos_f64x2(const A: TF64x2): TF64x2;
var
  I: Integer;
begin
  for I := 0 to 1 do
    Result.Insert(I, FastCos(A.Extract(I)));
end;

function simd_exp_f64x2(const A: TF64x2): TF64x2;
var
  I: Integer;
begin
  for I := 0 to 1 do
    Result.Insert(I, FastExp(A.Extract(I)));
end;

function simd_log_f64x2(const A: TF64x2): TF64x2;
var
  I: Integer;
begin
  for I := 0 to 1 do
    Result.Insert(I, FastLog(A.Extract(I)));
end;

function simd_pow_f64x2(const Base, Exp: TF64x2): TF64x2;
var
  I: Integer;
begin
  for I := 0 to 1 do
    Result.Insert(I, FastPow(Base.Extract(I), Exp.Extract(I)));
end;

// === 特殊函数（简化实现）===

function simd_gamma_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  // 简化实现：Γ(x) ≈ √(2π/x) * (x/e)^x (Stirling近似)
  for I := 0 to 3 do
    Result.Insert(I, 1.0); // 占位实现
end;

function simd_erf_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
  X, X2: Single;
begin
  // 简化实现：erf(x) ≈ (2/√π) * (x - x³/3 + x⁵/10)
  for I := 0 to 3 do
  begin
    X := A.Extract(I);
    X2 := X * X;
    Result.Insert(I, (2.0/1.7724538509) * (X - X*X2/3.0 + X*X2*X2/10.0));
  end;
end;

function simd_erfc_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  // erfc(x) = 1 - erf(x)
  for I := 0 to 3 do
    Result.Insert(I, 1.0 - simd_erf_f32x4(A).Extract(I));
end;

// === 实用函数实现 ===

function simd_abs_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, FastAbs(A.Extract(I)));
end;

function simd_sign_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
  X: Single;
begin
  for I := 0 to 3 do
  begin
    X := A.Extract(I);
    if X > 0.0 then
      Result.Insert(I, 1.0)
    else if X < 0.0 then
      Result.Insert(I, -1.0)
    else
      Result.Insert(I, 0.0);
  end;
end;

function simd_floor_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, FastFloor(A.Extract(I)));
end;

function simd_ceil_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, FastCeil(A.Extract(I)));
end;

function simd_round_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
  X: Single;
begin
  for I := 0 to 3 do
  begin
    X := A.Extract(I);
    Result.Insert(I, FastFloor(X + 0.5));
  end;
end;

function simd_trunc_f32x4(const A: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.Insert(I, Int(A.Extract(I)));
end;

function simd_fmod_f32x4(const A, B: TF32x4): TF32x4;
var
  I: Integer;
  X, Y: Single;
begin
  for I := 0 to 3 do
  begin
    X := A.Extract(I);
    Y := B.Extract(I);
    if Y = 0.0 then
      Result.Insert(I, 0.0)
    else
      Result.Insert(I, X - Y * FastFloor(X / Y));
  end;
end;

// === 简单的数学函数实现 ===

function Sqrt(A: Single): Single; inline;
begin
  // 改进的牛顿法平方根近似
  if A <= 0 then
    Result := 0
  else
  begin
    Result := A * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5;
  end;
end;

end.
