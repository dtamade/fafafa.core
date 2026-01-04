unit fafafa.core.simd.ops;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.base;

// =============================================================
// SIMD 向量运算符重载
// - 本单元包含所有向量类型的运算符重载实现
// - 通过 dispatch 系统自动选择最佳 SIMD 后端
// - ✅ 从 fafafa.core.simd.base.pas 分离以避免循环依赖 (2025-12-24)
// =============================================================

// === 运算符重载 (Phase 1.2) ===
// TVecF32x4 运算符
operator + (const a, b: TVecF32x4): TVecF32x4; inline;
operator - (const a, b: TVecF32x4): TVecF32x4; inline;
operator * (const a, b: TVecF32x4): TVecF32x4; inline;
operator / (const a, b: TVecF32x4): TVecF32x4; inline;
operator - (const a: TVecF32x4): TVecF32x4; inline;
operator * (const a: TVecF32x4; s: Single): TVecF32x4; inline;
operator * (s: Single; const a: TVecF32x4): TVecF32x4; inline;
operator / (const a: TVecF32x4; s: Single): TVecF32x4; inline;

// TVecF64x2 运算符
operator + (const a, b: TVecF64x2): TVecF64x2; inline;
operator - (const a, b: TVecF64x2): TVecF64x2; inline;
operator * (const a, b: TVecF64x2): TVecF64x2; inline;
operator / (const a, b: TVecF64x2): TVecF64x2; inline;
operator - (const a: TVecF64x2): TVecF64x2; inline;

// TVecI32x4 运算符
operator + (const a, b: TVecI32x4): TVecI32x4; inline;
operator - (const a, b: TVecI32x4): TVecI32x4; inline;
operator - (const a: TVecI32x4): TVecI32x4; inline;

// TVecI64x2 运算符 (P1.3)
operator + (const a, b: TVecI64x2): TVecI64x2; inline;
operator - (const a, b: TVecI64x2): TVecI64x2; inline;
operator - (const a: TVecI64x2): TVecI64x2; inline;
operator and (const a, b: TVecI64x2): TVecI64x2; inline;
operator or (const a, b: TVecI64x2): TVecI64x2; inline;
operator xor (const a, b: TVecI64x2): TVecI64x2; inline;
operator not (const a: TVecI64x2): TVecI64x2; inline;

// === 256-bit 向量运算符 (Phase 2) ===
// TVecF32x8 运算符
operator + (const a, b: TVecF32x8): TVecF32x8; inline;
operator - (const a, b: TVecF32x8): TVecF32x8; inline;
operator * (const a, b: TVecF32x8): TVecF32x8; inline;
operator / (const a, b: TVecF32x8): TVecF32x8; inline;
operator - (const a: TVecF32x8): TVecF32x8; inline;

// TVecF64x4 运算符
operator + (const a, b: TVecF64x4): TVecF64x4; inline;
operator - (const a, b: TVecF64x4): TVecF64x4; inline;
operator * (const a, b: TVecF64x4): TVecF64x4; inline;
operator / (const a, b: TVecF64x4): TVecF64x4; inline;
operator - (const a: TVecF64x4): TVecF64x4; inline;

// TVecI32x8 运算符
operator + (const a, b: TVecI32x8): TVecI32x8; inline;
operator - (const a, b: TVecI32x8): TVecI32x8; inline;
operator * (const a, b: TVecI32x8): TVecI32x8; inline;
operator - (const a: TVecI32x8): TVecI32x8; inline;
operator and (const a, b: TVecI32x8): TVecI32x8; inline;
operator or (const a, b: TVecI32x8): TVecI32x8; inline;
operator xor (const a, b: TVecI32x8): TVecI32x8; inline;
operator not (const a: TVecI32x8): TVecI32x8; inline;

// === 512-bit 向量运算符 (AVX-512) ===
// TVecF32x16 运算符
operator + (const a, b: TVecF32x16): TVecF32x16; inline;
operator - (const a, b: TVecF32x16): TVecF32x16; inline;
operator * (const a, b: TVecF32x16): TVecF32x16; inline;
operator / (const a, b: TVecF32x16): TVecF32x16; inline;
operator - (const a: TVecF32x16): TVecF32x16; inline;

// TVecF64x8 运算符
operator + (const a, b: TVecF64x8): TVecF64x8; inline;
operator - (const a, b: TVecF64x8): TVecF64x8; inline;
operator * (const a, b: TVecF64x8): TVecF64x8; inline;
operator / (const a, b: TVecF64x8): TVecF64x8; inline;
operator - (const a: TVecF64x8): TVecF64x8; inline;

// TVecI32x16 运算符
operator + (const a, b: TVecI32x16): TVecI32x16; inline;
operator - (const a, b: TVecI32x16): TVecI32x16; inline;
operator * (const a, b: TVecI32x16): TVecI32x16; inline;
operator - (const a: TVecI32x16): TVecI32x16; inline;
operator and (const a, b: TVecI32x16): TVecI32x16; inline;
operator or (const a, b: TVecI32x16): TVecI32x16; inline;
operator xor (const a, b: TVecI32x16): TVecI32x16; inline;
operator not (const a: TVecI32x16): TVecI32x16; inline;

implementation

uses
  fafafa.core.simd.dispatch;

// === TVecF32x4 运算符实现 ===
// 通过 dispatch 系统调用 SIMD 实现，而非标量循环

// ✅ P2-B: 简化运算符 - GetDispatchTable 保证返回有效指针，所有槽位已填充
operator + (const a, b: TVecF32x4): TVecF32x4;
begin
  Result := GetDispatchTable^.AddF32x4(a, b);
end;

operator - (const a, b: TVecF32x4): TVecF32x4;
begin
  Result := GetDispatchTable^.SubF32x4(a, b);
end;

operator * (const a, b: TVecF32x4): TVecF32x4;
begin
  Result := GetDispatchTable^.MulF32x4(a, b);
end;

operator / (const a, b: TVecF32x4): TVecF32x4;
begin
  Result := GetDispatchTable^.DivF32x4(a, b);
end;

operator - (const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  // Unary negation - no dispatch function, use scalar
  for i := 0 to 3 do
    Result.f[i] := -a.f[i];
end;

operator * (const a: TVecF32x4; s: Single): TVecF32x4;
var dt: PSimdDispatchTable;
begin
  dt := GetDispatchTable;
  Result := dt^.MulF32x4(a, dt^.SplatF32x4(s));
end;

operator * (s: Single; const a: TVecF32x4): TVecF32x4;
var dt: PSimdDispatchTable;
begin
  dt := GetDispatchTable;
  Result := dt^.MulF32x4(dt^.SplatF32x4(s), a);
end;

operator / (const a: TVecF32x4; s: Single): TVecF32x4;
var dt: PSimdDispatchTable;
begin
  dt := GetDispatchTable;
  Result := dt^.DivF32x4(a, dt^.SplatF32x4(s));
end;

// === TVecF64x2 运算符实现 ===
// 通过 dispatch 系统调用 SIMD 实现

// ✅ P2-B: 简化运算符 - GetDispatchTable 保证返回有效指针，所有槽位已填充
operator + (const a, b: TVecF64x2): TVecF64x2;
begin
  Result := GetDispatchTable^.AddF64x2(a, b);
end;

operator - (const a, b: TVecF64x2): TVecF64x2;
begin
  Result := GetDispatchTable^.SubF64x2(a, b);
end;

operator * (const a, b: TVecF64x2): TVecF64x2;
begin
  Result := GetDispatchTable^.MulF64x2(a, b);
end;

operator / (const a, b: TVecF64x2): TVecF64x2;
begin
  Result := GetDispatchTable^.DivF64x2(a, b);
end;

operator - (const a: TVecF64x2): TVecF64x2;
begin
  // Unary negation - no dispatch function, use scalar
  Result.d[0] := -a.d[0];
  Result.d[1] := -a.d[1];
end;

// === TVecI32x4 运算符实现 ===
// Note: Integer SIMD operations should wrap around on overflow (like hardware)
// ✅ P2-B: 简化运算符 - GetDispatchTable 保证返回有效指针，所有槽位已填充

{$PUSH}{$R-}{$Q-}  // Disable range/overflow checks for wraparound semantics
operator + (const a, b: TVecI32x4): TVecI32x4;
begin
  Result := GetDispatchTable^.AddI32x4(a, b);
end;

operator - (const a, b: TVecI32x4): TVecI32x4;
begin
  Result := GetDispatchTable^.SubI32x4(a, b);
end;

operator - (const a: TVecI32x4): TVecI32x4;
begin
  // Unary negation - no dispatch function, use scalar
  Result.i[0] := -a.i[0];
  Result.i[1] := -a.i[1];
  Result.i[2] := -a.i[2];
  Result.i[3] := -a.i[3];
end;
{$POP}

// === TVecI64x2 运算符实现 (128-bit, P1.3) ===
// ✅ P2-B: 简化运算符 - GetDispatchTable 保证返回有效指针，所有槽位已填充
{$PUSH}{$R-}{$Q-}  // Disable overflow checks for wraparound semantics
operator + (const a, b: TVecI64x2): TVecI64x2;
begin
  Result := GetDispatchTable^.AddI64x2(a, b);
end;

operator - (const a, b: TVecI64x2): TVecI64x2;
begin
  Result := GetDispatchTable^.SubI64x2(a, b);
end;

operator - (const a: TVecI64x2): TVecI64x2;
begin
  Result.i[0] := -a.i[0];
  Result.i[1] := -a.i[1];
end;

operator and (const a, b: TVecI64x2): TVecI64x2;
begin
  Result.i[0] := a.i[0] and b.i[0];
  Result.i[1] := a.i[1] and b.i[1];
end;

operator or (const a, b: TVecI64x2): TVecI64x2;
begin
  Result.i[0] := a.i[0] or b.i[0];
  Result.i[1] := a.i[1] or b.i[1];
end;

operator xor (const a, b: TVecI64x2): TVecI64x2;
begin
  Result.i[0] := a.i[0] xor b.i[0];
  Result.i[1] := a.i[1] xor b.i[1];
end;

operator not (const a: TVecI64x2): TVecI64x2;
begin
  Result.i[0] := not a.i[0];
  Result.i[1] := not a.i[1];
end;
{$POP}

// === TVecF32x8 运算符实现 (256-bit) ===
// ✅ P2-B: 简化运算符 - GetDispatchTable 保证返回有效指针，所有槽位已填充

operator + (const a, b: TVecF32x8): TVecF32x8;
begin
  Result := GetDispatchTable^.AddF32x8(a, b);
end;

operator - (const a, b: TVecF32x8): TVecF32x8;
begin
  Result := GetDispatchTable^.SubF32x8(a, b);
end;

operator * (const a, b: TVecF32x8): TVecF32x8;
begin
  Result := GetDispatchTable^.MulF32x8(a, b);
end;

operator / (const a, b: TVecF32x8): TVecF32x8;
begin
  Result := GetDispatchTable^.DivF32x8(a, b);
end;

operator - (const a: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  // Unary negation - no dispatch function, use scalar
  for i := 0 to 7 do
    Result.f[i] := -a.f[i];
end;

// === TVecF64x4 运算符实现 (256-bit) ===
// ✅ P2-B: 简化运算符 - GetDispatchTable 保证返回有效指针，所有槽位已填充

operator + (const a, b: TVecF64x4): TVecF64x4;
begin
  Result := GetDispatchTable^.AddF64x4(a, b);
end;

operator - (const a, b: TVecF64x4): TVecF64x4;
begin
  Result := GetDispatchTable^.SubF64x4(a, b);
end;

operator * (const a, b: TVecF64x4): TVecF64x4;
begin
  Result := GetDispatchTable^.MulF64x4(a, b);
end;

operator / (const a, b: TVecF64x4): TVecF64x4;
begin
  Result := GetDispatchTable^.DivF64x4(a, b);
end;

operator - (const a: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := -a.d[i];
end;

// === TVecI32x8 运算符实现 (256-bit) ===
// ✅ P2-B: 简化运算符 - GetDispatchTable 保证返回有效指针，所有槽位已填充

operator + (const a, b: TVecI32x8): TVecI32x8;
begin
  Result := GetDispatchTable^.AddI32x8(a, b);
end;

operator - (const a, b: TVecI32x8): TVecI32x8;
begin
  Result := GetDispatchTable^.SubI32x8(a, b);
end;

operator - (const a: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := -a.i[i];
end;

// P1.1: 添加 I32x8 乘法运算符
operator * (const a, b: TVecI32x8): TVecI32x8;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.MulI32x8) then
    Result := dt^.MulI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := a.i[i] * b.i[i];
  end;
end;

// P1.1: 添加 I32x8 位运算符
operator and (const a, b: TVecI32x8): TVecI32x8;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.AndI32x8) then
    Result := dt^.AndI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := a.i[i] and b.i[i];
  end;
end;

operator or (const a, b: TVecI32x8): TVecI32x8;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.OrI32x8) then
    Result := dt^.OrI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := a.i[i] or b.i[i];
  end;
end;

operator xor (const a, b: TVecI32x8): TVecI32x8;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.XorI32x8) then
    Result := dt^.XorI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := a.i[i] xor b.i[i];
  end;
end;

operator not (const a: TVecI32x8): TVecI32x8;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.NotI32x8) then
    Result := dt^.NotI32x8(a)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := not a.i[i];
  end;
end;

// === TVecF32x16 运算符实现 (512-bit AVX-512) ===
// P0 修复: 通过 dispatch 系统调用 AVX-512 实现

operator + (const a, b: TVecF32x16): TVecF32x16;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.AddF32x16) then
    Result := dt^.AddF32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.f[i] := a.f[i] + b.f[i];
  end;
end;

operator - (const a, b: TVecF32x16): TVecF32x16;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.SubF32x16) then
    Result := dt^.SubF32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.f[i] := a.f[i] - b.f[i];
  end;
end;

operator * (const a, b: TVecF32x16): TVecF32x16;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.MulF32x16) then
    Result := dt^.MulF32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.f[i] := a.f[i] * b.f[i];
  end;
end;

operator / (const a, b: TVecF32x16): TVecF32x16;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.DivF32x16) then
    Result := dt^.DivF32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.f[i] := a.f[i] / b.f[i];
  end;
end;

operator - (const a: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := -a.f[i];
end;

// === TVecF64x8 运算符实现 (512-bit AVX-512) ===
// P0 修复: 通过 dispatch 系统调用 AVX-512 实现

operator + (const a, b: TVecF64x8): TVecF64x8;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.AddF64x8) then
    Result := dt^.AddF64x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.d[i] := a.d[i] + b.d[i];
  end;
end;

operator - (const a, b: TVecF64x8): TVecF64x8;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.SubF64x8) then
    Result := dt^.SubF64x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.d[i] := a.d[i] - b.d[i];
  end;
end;

operator * (const a, b: TVecF64x8): TVecF64x8;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.MulF64x8) then
    Result := dt^.MulF64x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.d[i] := a.d[i] * b.d[i];
  end;
end;

operator / (const a, b: TVecF64x8): TVecF64x8;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.DivF64x8) then
    Result := dt^.DivF64x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.d[i] := a.d[i] / b.d[i];
  end;
end;

operator - (const a: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := -a.d[i];
end;

// === TVecI32x16 运算符实现 (512-bit AVX-512) ===
// P0 修复: 通过 dispatch 系统调用 AVX-512 实现

operator + (const a, b: TVecI32x16): TVecI32x16;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.AddI32x16) then
    Result := dt^.AddI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] + b.i[i];
  end;
end;

operator - (const a, b: TVecI32x16): TVecI32x16;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.SubI32x16) then
    Result := dt^.SubI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] - b.i[i];
  end;
end;

operator - (const a: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := -a.i[i];
end;

// P1.2: 添加 I32x16 乘法运算符
operator * (const a, b: TVecI32x16): TVecI32x16;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.MulI32x16) then
    Result := dt^.MulI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] * b.i[i];
  end;
end;

// P1.2: 添加 I32x16 位运算符
operator and (const a, b: TVecI32x16): TVecI32x16;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.AndI32x16) then
    Result := dt^.AndI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] and b.i[i];
  end;
end;

operator or (const a, b: TVecI32x16): TVecI32x16;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.OrI32x16) then
    Result := dt^.OrI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] or b.i[i];
  end;
end;

operator xor (const a, b: TVecI32x16): TVecI32x16;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.XorI32x16) then
    Result := dt^.XorI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] xor b.i[i];
  end;
end;

operator not (const a: TVecI32x16): TVecI32x16;
var dt: PSimdDispatchTable;
    i: Integer;
begin
  dt := GetDispatchTable;
  if (dt <> nil) and Assigned(dt^.NotI32x16) then
    Result := dt^.NotI32x16(a)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := not a.i[i];
  end;
end;

end.
