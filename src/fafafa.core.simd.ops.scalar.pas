unit fafafa.core.simd.ops.scalar;

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.types;

// === 标量回退实现 ===
// 当没有 SIMD 支持时使用的纯标量实现

// 单精度浮点向量操作
function Scalar_VecF32x4_Add(const a, b: TVecF32x4): TVecF32x4;
function Scalar_VecF32x4_Sub(const a, b: TVecF32x4): TVecF32x4;
function Scalar_VecF32x4_Mul(const a, b: TVecF32x4): TVecF32x4;
function Scalar_VecF32x4_Div(const a, b: TVecF32x4): TVecF32x4;

// 双精度浮点向量操作
function Scalar_VecF64x2_Add(const a, b: TVecF64x2): TVecF64x2;
function Scalar_VecF64x2_Sub(const a, b: TVecF64x2): TVecF64x2;
function Scalar_VecF64x2_Mul(const a, b: TVecF64x2): TVecF64x2;
function Scalar_VecF64x2_Div(const a, b: TVecF64x2): TVecF64x2;

// 32位整数向量操作
function Scalar_VecI32x4_Add(const a, b: TVecI32x4): TVecI32x4;
function Scalar_VecI32x4_Sub(const a, b: TVecI32x4): TVecI32x4;
function Scalar_VecI32x4_Mul(const a, b: TVecI32x4): TVecI32x4;

// 向量加载和存储
function Scalar_VecF32x4_Load(const ptr: Pointer): TVecF32x4;
procedure Scalar_VecF32x4_Store(const vec: TVecF32x4; ptr: Pointer);

// 向量创建
function Scalar_VecF32x4_Set(x, y, z, w: Single): TVecF32x4;
function Scalar_VecF32x4_SetAll(value: Single): TVecF32x4;
function Scalar_VecF32x4_Zero: TVecF32x4;

// 向量比较
function Scalar_VecF32x4_Equal(const a, b: TVecF32x4): TMask4;
function Scalar_VecF32x4_Less(const a, b: TVecF32x4): TMask4;
function Scalar_VecF32x4_Greater(const a, b: TVecF32x4): TMask4;

// 向量数学函数
function Scalar_VecF32x4_Sqrt(const a: TVecF32x4): TVecF32x4;
function Scalar_VecF32x4_Min(const a, b: TVecF32x4): TVecF32x4;
function Scalar_VecF32x4_Max(const a, b: TVecF32x4): TVecF32x4;
function Scalar_VecF32x4_Abs(const a: TVecF32x4): TVecF32x4;

// 水平操作（归约）
function Scalar_VecF32x4_HorizontalAdd(const a: TVecF32x4): Single;
function Scalar_VecF32x4_HorizontalMin(const a: TVecF32x4): Single;
function Scalar_VecF32x4_HorizontalMax(const a: TVecF32x4): Single;

implementation

uses
  Math;

// === 单精度浮点向量操作 ===

function Scalar_VecF32x4_Add(const a, b: TVecF32x4): TVecF32x4;
begin
  Result.f[0] := a.f[0] + b.f[0];
  Result.f[1] := a.f[1] + b.f[1];
  Result.f[2] := a.f[2] + b.f[2];
  Result.f[3] := a.f[3] + b.f[3];
end;

function Scalar_VecF32x4_Sub(const a, b: TVecF32x4): TVecF32x4;
begin
  Result.f[0] := a.f[0] - b.f[0];
  Result.f[1] := a.f[1] - b.f[1];
  Result.f[2] := a.f[2] - b.f[2];
  Result.f[3] := a.f[3] - b.f[3];
end;

function Scalar_VecF32x4_Mul(const a, b: TVecF32x4): TVecF32x4;
begin
  Result.f[0] := a.f[0] * b.f[0];
  Result.f[1] := a.f[1] * b.f[1];
  Result.f[2] := a.f[2] * b.f[2];
  Result.f[3] := a.f[3] * b.f[3];
end;

function Scalar_VecF32x4_Div(const a, b: TVecF32x4): TVecF32x4;
begin
  Result.f[0] := a.f[0] / b.f[0];
  Result.f[1] := a.f[1] / b.f[1];
  Result.f[2] := a.f[2] / b.f[2];
  Result.f[3] := a.f[3] / b.f[3];
end;

// === 双精度浮点向量操作 ===

function Scalar_VecF64x2_Add(const a, b: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := a.d[0] + b.d[0];
  Result.d[1] := a.d[1] + b.d[1];
end;

function Scalar_VecF64x2_Sub(const a, b: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := a.d[0] - b.d[0];
  Result.d[1] := a.d[1] - b.d[1];
end;

function Scalar_VecF64x2_Mul(const a, b: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := a.d[0] * b.d[0];
  Result.d[1] := a.d[1] * b.d[1];
end;

function Scalar_VecF64x2_Div(const a, b: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := a.d[0] / b.d[0];
  Result.d[1] := a.d[1] / b.d[1];
end;

// === 32位整数向量操作 ===

function Scalar_VecI32x4_Add(const a, b: TVecI32x4): TVecI32x4;
begin
  Result.i[0] := a.i[0] + b.i[0];
  Result.i[1] := a.i[1] + b.i[1];
  Result.i[2] := a.i[2] + b.i[2];
  Result.i[3] := a.i[3] + b.i[3];
end;

function Scalar_VecI32x4_Sub(const a, b: TVecI32x4): TVecI32x4;
begin
  Result.i[0] := a.i[0] - b.i[0];
  Result.i[1] := a.i[1] - b.i[1];
  Result.i[2] := a.i[2] - b.i[2];
  Result.i[3] := a.i[3] - b.i[3];
end;

function Scalar_VecI32x4_Mul(const a, b: TVecI32x4): TVecI32x4;
begin
  Result.i[0] := a.i[0] * b.i[0];
  Result.i[1] := a.i[1] * b.i[1];
  Result.i[2] := a.i[2] * b.i[2];
  Result.i[3] := a.i[3] * b.i[3];
end;

// === 向量加载和存储 ===

function Scalar_VecF32x4_Load(const ptr: Pointer): TVecF32x4;
begin
  Move(ptr^, Result, SizeOf(TVecF32x4));
end;

procedure Scalar_VecF32x4_Store(const vec: TVecF32x4; ptr: Pointer);
begin
  Move(vec, ptr^, SizeOf(TVecF32x4));
end;

// === 向量创建 ===

function Scalar_VecF32x4_Set(x, y, z, w: Single): TVecF32x4;
begin
  Result.f[0] := x;
  Result.f[1] := y;
  Result.f[2] := z;
  Result.f[3] := w;
end;

function Scalar_VecF32x4_SetAll(value: Single): TVecF32x4;
begin
  Result.f[0] := value;
  Result.f[1] := value;
  Result.f[2] := value;
  Result.f[3] := value;
end;

function Scalar_VecF32x4_Zero: TVecF32x4;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

// === 向量比较 ===

function Scalar_VecF32x4_Equal(const a, b: TVecF32x4): TMask4;
var
  m: Byte;
begin
  m := 0;
  if a.f[0] = b.f[0] then m := m or (1 shl 0);
  if a.f[1] = b.f[1] then m := m or (1 shl 1);
  if a.f[2] = b.f[2] then m := m or (1 shl 2);
  if a.f[3] = b.f[3] then m := m or (1 shl 3);
  Result := TMask4(m);
end;

function Scalar_VecF32x4_Less(const a, b: TVecF32x4): TMask4;
var
  m: Byte;
begin
  m := 0;
  if a.f[0] < b.f[0] then m := m or (1 shl 0);
  if a.f[1] < b.f[1] then m := m or (1 shl 1);
  if a.f[2] < b.f[2] then m := m or (1 shl 2);
  if a.f[3] < b.f[3] then m := m or (1 shl 3);
  Result := TMask4(m);
end;

function Scalar_VecF32x4_Greater(const a, b: TVecF32x4): TMask4;
var
  m: Byte;
begin
  m := 0;
  if a.f[0] > b.f[0] then m := m or (1 shl 0);
  if a.f[1] > b.f[1] then m := m or (1 shl 1);
  if a.f[2] > b.f[2] then m := m or (1 shl 2);
  if a.f[3] > b.f[3] then m := m or (1 shl 3);
  Result := TMask4(m);
end;

// === 向量数学函数 ===

function Scalar_VecF32x4_Sqrt(const a: TVecF32x4): TVecF32x4;
begin
  Result.f[0] := Sqrt(a.f[0]);
  Result.f[1] := Sqrt(a.f[1]);
  Result.f[2] := Sqrt(a.f[2]);
  Result.f[3] := Sqrt(a.f[3]);
end;

function Scalar_VecF32x4_Min(const a, b: TVecF32x4): TVecF32x4;
begin
  Result.f[0] := Min(a.f[0], b.f[0]);
  Result.f[1] := Min(a.f[1], b.f[1]);
  Result.f[2] := Min(a.f[2], b.f[2]);
  Result.f[3] := Min(a.f[3], b.f[3]);
end;

function Scalar_VecF32x4_Max(const a, b: TVecF32x4): TVecF32x4;
begin
  Result.f[0] := Max(a.f[0], b.f[0]);
  Result.f[1] := Max(a.f[1], b.f[1]);
  Result.f[2] := Max(a.f[2], b.f[2]);
  Result.f[3] := Max(a.f[3], b.f[3]);
end;

function Scalar_VecF32x4_Abs(const a: TVecF32x4): TVecF32x4;
begin
  Result.f[0] := Abs(a.f[0]);
  Result.f[1] := Abs(a.f[1]);
  Result.f[2] := Abs(a.f[2]);
  Result.f[3] := Abs(a.f[3]);
end;

// === 水平操作（归约）===

function Scalar_VecF32x4_HorizontalAdd(const a: TVecF32x4): Single;
begin
  Result := a.f[0] + a.f[1] + a.f[2] + a.f[3];
end;

function Scalar_VecF32x4_HorizontalMin(const a: TVecF32x4): Single;
begin
  Result := Min(Min(a.f[0], a.f[1]), Min(a.f[2], a.f[3]));
end;

function Scalar_VecF32x4_HorizontalMax(const a: TVecF32x4): Single;
begin
  Result := Max(Max(a.f[0], a.f[1]), Max(a.f[2], a.f[3]));
end;

end.
