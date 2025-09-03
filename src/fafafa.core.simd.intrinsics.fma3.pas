unit fafafa.core.simd.intrinsics.fma3;

{$I fafafa.core.settings.inc}

{
  === fafafa.core.simd.intrinsics.fma3 ===
  FMA3 (Fused Multiply-Add 3-operand) 指令集支持
  
  FMA3 是 Intel 在 2012 年引入的融合乘加指令集扩展
  提供高精度的乘加运算，减少舍入误差
  
  特性：
  - 融合乘加运算 (a * b + c)
  - 融合乘减运算 (a * b - c)
  - 融合负乘加运算 (-(a * b) + c)
  - 融合负乘减运算 (-(a * b) - c)
  - 单精度和双精度支持
  
  兼容性：Intel Haswell (2013) 及更新的处理器
}

interface

uses
  fafafa.core.simd.intrinsics.base;

// === FMA3 单精度浮点指令 ===
// Fused Multiply-Add: a * b + c
function fma3_fmadd_ps(const a, b, c: TM128): TM128;
function fma3_fmadd_ss(const a, b, c: TM128): TM128;
function fma3_fmadd_ps256(const a, b, c: TM256): TM256;

// Fused Multiply-Sub: a * b - c
function fma3_fmsub_ps(const a, b, c: TM128): TM128;
function fma3_fmsub_ss(const a, b, c: TM128): TM128;
function fma3_fmsub_ps256(const a, b, c: TM256): TM256;

// Fused Negative Multiply-Add: -(a * b) + c
function fma3_fnmadd_ps(const a, b, c: TM128): TM128;
function fma3_fnmadd_ss(const a, b, c: TM128): TM128;
function fma3_fnmadd_ps256(const a, b, c: TM256): TM256;

// Fused Negative Multiply-Sub: -(a * b) - c
function fma3_fnmsub_ps(const a, b, c: TM128): TM128;
function fma3_fnmsub_ss(const a, b, c: TM128): TM128;
function fma3_fnmsub_ps256(const a, b, c: TM256): TM256;

// === FMA3 双精度浮点指令 ===
// Fused Multiply-Add: a * b + c
function fma3_fmadd_pd(const a, b, c: TM128): TM128;
function fma3_fmadd_sd(const a, b, c: TM128): TM128;
function fma3_fmadd_pd256(const a, b, c: TM256): TM256;

// Fused Multiply-Sub: a * b - c
function fma3_fmsub_pd(const a, b, c: TM128): TM128;
function fma3_fmsub_sd(const a, b, c: TM128): TM128;
function fma3_fmsub_pd256(const a, b, c: TM256): TM256;

// Fused Negative Multiply-Add: -(a * b) + c
function fma3_fnmadd_pd(const a, b, c: TM128): TM128;
function fma3_fnmadd_sd(const a, b, c: TM128): TM128;
function fma3_fnmadd_pd256(const a, b, c: TM256): TM256;

// Fused Negative Multiply-Sub: -(a * b) - c
function fma3_fnmsub_pd(const a, b, c: TM128): TM128;
function fma3_fnmsub_sd(const a, b, c: TM128): TM128;
function fma3_fnmsub_pd256(const a, b, c: TM256): TM256;

// === FMA3 交替形式 (不同操作数顺序) ===
// Fused Add-Multiply: c + a * b
function fma3_fmaddsub_ps(const a, b, c: TM128): TM128;
function fma3_fmaddsub_pd(const a, b, c: TM128): TM128;
function fma3_fmaddsub_ps256(const a, b, c: TM256): TM256;
function fma3_fmaddsub_pd256(const a, b, c: TM256): TM256;

// Fused Sub-Multiply: c - a * b
function fma3_fmsubadd_ps(const a, b, c: TM128): TM128;
function fma3_fmsubadd_pd(const a, b, c: TM128): TM128;
function fma3_fmsubadd_ps256(const a, b, c: TM256): TM256;
function fma3_fmsubadd_pd256(const a, b, c: TM256): TM256;

implementation

// === 128-bit 单精度浮点实现 ===
function fma3_fmadd_ps(const a, b, c: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := a.m128_f32[i] * b.m128_f32[i] + c.m128_f32[i];
end;

function fma3_fmadd_ss(const a, b, c: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := a.m128_f32[0] * b.m128_f32[0] + c.m128_f32[0];
end;

function fma3_fmsub_ps(const a, b, c: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := a.m128_f32[i] * b.m128_f32[i] - c.m128_f32[i];
end;

function fma3_fmsub_ss(const a, b, c: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := a.m128_f32[0] * b.m128_f32[0] - c.m128_f32[0];
end;

function fma3_fnmadd_ps(const a, b, c: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := -(a.m128_f32[i] * b.m128_f32[i]) + c.m128_f32[i];
end;

function fma3_fnmadd_ss(const a, b, c: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := -(a.m128_f32[0] * b.m128_f32[0]) + c.m128_f32[0];
end;

function fma3_fnmsub_ps(const a, b, c: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := -(a.m128_f32[i] * b.m128_f32[i]) - c.m128_f32[i];
end;

function fma3_fnmsub_ss(const a, b, c: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := -(a.m128_f32[0] * b.m128_f32[0]) - c.m128_f32[0];
end;

// === 128-bit 双精度浮点实现 ===
function fma3_fmadd_pd(const a, b, c: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128d_f64[i] := a.m128d_f64[i] * b.m128d_f64[i] + c.m128d_f64[i];
end;

function fma3_fmadd_sd(const a, b, c: TM128): TM128;
begin
  Result := a;
  Result.m128d_f64[0] := a.m128d_f64[0] * b.m128d_f64[0] + c.m128d_f64[0];
end;

function fma3_fmsub_pd(const a, b, c: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128d_f64[i] := a.m128d_f64[i] * b.m128d_f64[i] - c.m128d_f64[i];
end;

function fma3_fmsub_sd(const a, b, c: TM128): TM128;
begin
  Result := a;
  Result.m128d_f64[0] := a.m128d_f64[0] * b.m128d_f64[0] - c.m128d_f64[0];
end;

function fma3_fnmadd_pd(const a, b, c: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128d_f64[i] := -(a.m128d_f64[i] * b.m128d_f64[i]) + c.m128d_f64[i];
end;

function fma3_fnmadd_sd(const a, b, c: TM128): TM128;
begin
  Result := a;
  Result.m128d_f64[0] := -(a.m128d_f64[0] * b.m128d_f64[0]) + c.m128d_f64[0];
end;

function fma3_fnmsub_pd(const a, b, c: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128d_f64[i] := -(a.m128d_f64[i] * b.m128d_f64[i]) - c.m128d_f64[i];
end;

function fma3_fnmsub_sd(const a, b, c: TM128): TM128;
begin
  Result := a;
  Result.m128d_f64[0] := -(a.m128d_f64[0] * b.m128d_f64[0]) - c.m128d_f64[0];
end;

// === 256-bit 单精度浮点实现 ===
function fma3_fmadd_ps256(const a, b, c: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m256_f32[i] := a.m256_f32[i] * b.m256_f32[i] + c.m256_f32[i];
end;

function fma3_fmsub_ps256(const a, b, c: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m256_f32[i] := a.m256_f32[i] * b.m256_f32[i] - c.m256_f32[i];
end;

function fma3_fnmadd_ps256(const a, b, c: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m256_f32[i] := -(a.m256_f32[i] * b.m256_f32[i]) + c.m256_f32[i];
end;

function fma3_fnmsub_ps256(const a, b, c: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m256_f32[i] := -(a.m256_f32[i] * b.m256_f32[i]) - c.m256_f32[i];
end;

// === 256-bit 双精度浮点实现 ===
function fma3_fmadd_pd256(const a, b, c: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m256_f64[i] := a.m256_f64[i] * b.m256_f64[i] + c.m256_f64[i];
end;

function fma3_fmsub_pd256(const a, b, c: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m256_f64[i] := a.m256_f64[i] * b.m256_f64[i] - c.m256_f64[i];
end;

function fma3_fnmadd_pd256(const a, b, c: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m256_f64[i] := -(a.m256_f64[i] * b.m256_f64[i]) + c.m256_f64[i];
end;

function fma3_fnmsub_pd256(const a, b, c: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m256_f64[i] := -(a.m256_f64[i] * b.m256_f64[i]) - c.m256_f64[i];
end;

// === 交替形式实现 ===
function fma3_fmaddsub_ps(const a, b, c: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if (i and 1) = 0 then
      Result.m128_f32[i] := a.m128_f32[i] * b.m128_f32[i] - c.m128_f32[i]  // 偶数索引：减法
    else
      Result.m128_f32[i] := a.m128_f32[i] * b.m128_f32[i] + c.m128_f32[i]; // 奇数索引：加法
end;

function fma3_fmaddsub_pd(const a, b, c: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    if (i and 1) = 0 then
      Result.m128d_f64[i] := a.m128d_f64[i] * b.m128d_f64[i] - c.m128d_f64[i]
    else
      Result.m128d_f64[i] := a.m128d_f64[i] * b.m128d_f64[i] + c.m128d_f64[i];
end;

function fma3_fmaddsub_ps256(const a, b, c: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    if (i and 1) = 0 then
      Result.m256_f32[i] := a.m256_f32[i] * b.m256_f32[i] - c.m256_f32[i]
    else
      Result.m256_f32[i] := a.m256_f32[i] * b.m256_f32[i] + c.m256_f32[i];
end;

function fma3_fmaddsub_pd256(const a, b, c: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if (i and 1) = 0 then
      Result.m256_f64[i] := a.m256_f64[i] * b.m256_f64[i] - c.m256_f64[i]
    else
      Result.m256_f64[i] := a.m256_f64[i] * b.m256_f64[i] + c.m256_f64[i];
end;

function fma3_fmsubadd_ps(const a, b, c: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if (i and 1) = 0 then
      Result.m128_f32[i] := a.m128_f32[i] * b.m128_f32[i] + c.m128_f32[i]  // 偶数索引：加法
    else
      Result.m128_f32[i] := a.m128_f32[i] * b.m128_f32[i] - c.m128_f32[i]; // 奇数索引：减法
end;

function fma3_fmsubadd_pd(const a, b, c: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    if (i and 1) = 0 then
      Result.m128d_f64[i] := a.m128d_f64[i] * b.m128d_f64[i] + c.m128d_f64[i]
    else
      Result.m128d_f64[i] := a.m128d_f64[i] * b.m128d_f64[i] - c.m128d_f64[i];
end;

function fma3_fmsubadd_ps256(const a, b, c: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    if (i and 1) = 0 then
      Result.m256_f32[i] := a.m256_f32[i] * b.m256_f32[i] + c.m256_f32[i]
    else
      Result.m256_f32[i] := a.m256_f32[i] * b.m256_f32[i] - c.m256_f32[i];
end;

function fma3_fmsubadd_pd256(const a, b, c: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if (i and 1) = 0 then
      Result.m256_f64[i] := a.m256_f64[i] * b.m256_f64[i] + c.m256_f64[i]
    else
      Result.m256_f64[i] := a.m256_f64[i] * b.m256_f64[i] - c.m256_f64[i];
end;

end.
