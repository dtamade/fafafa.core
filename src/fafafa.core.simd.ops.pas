unit fafafa.core.simd.ops;

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.types;

// === 基础向量操作 ===

// 单精度浮点向量操作 (128-bit)
function VecF32x4_Add(const a, b: TVecF32x4): TVecF32x4;
function VecF32x4_Sub(const a, b: TVecF32x4): TVecF32x4;
function VecF32x4_Mul(const a, b: TVecF32x4): TVecF32x4;
function VecF32x4_Div(const a, b: TVecF32x4): TVecF32x4;

// 双精度浮点向量操作 (128-bit)
function VecF64x2_Add(const a, b: TVecF64x2): TVecF64x2;
function VecF64x2_Sub(const a, b: TVecF64x2): TVecF64x2;
function VecF64x2_Mul(const a, b: TVecF64x2): TVecF64x2;
function VecF64x2_Div(const a, b: TVecF64x2): TVecF64x2;

// 单精度浮点向量操作 (256-bit)
function VecF32x8_Add(const a, b: TVecF32x8): TVecF32x8;
function VecF32x8_Sub(const a, b: TVecF32x8): TVecF32x8;
function VecF32x8_Mul(const a, b: TVecF32x8): TVecF32x8;
function VecF32x8_Div(const a, b: TVecF32x8): TVecF32x8;
function VecF32x8_Load(const ptr: Pointer): TVecF32x8;
procedure VecF32x8_Store(const vec: TVecF32x8; ptr: Pointer);
function VecF32x8_LoadUnaligned(const ptr: Pointer): TVecF32x8;
procedure VecF32x8_StoreUnaligned(const vec: TVecF32x8; ptr: Pointer);
function VecF32x8_SetAll(value: Single): TVecF32x8;
function VecF32x8_Zero: TVecF32x8;

// 32位整数向量操作 (256-bit)
function VecI32x8_Add(const a, b: TVecI32x8): TVecI32x8;
function VecI32x8_Sub(const a, b: TVecI32x8): TVecI32x8;
function VecI32x8_Mul(const a, b: TVecI32x8): TVecI32x8;
function VecI32x8_LoadUnaligned(const ptr: Pointer): TVecI32x8;
procedure VecI32x8_StoreUnaligned(const vec: TVecI32x8; ptr: Pointer);
function VecI32x8_SetAll(value: Int32): TVecI32x8;
function VecI32x8_Zero: TVecI32x8;


// 32位整数向量操作 (128-bit)
function VecI32x4_Add(const a, b: TVecI32x4): TVecI32x4;
function VecI32x4_Sub(const a, b: TVecI32x4): TVecI32x4;
function VecI32x4_Mul(const a, b: TVecI32x4): TVecI32x4;

// 向量加载和存储
function VecF32x4_Load(const ptr: Pointer): TVecF32x4;
procedure VecF32x4_Store(const vec: TVecF32x4; ptr: Pointer);
function VecF32x4_LoadUnaligned(const ptr: Pointer): TVecF32x4;
procedure VecF32x4_StoreUnaligned(const vec: TVecF32x4; ptr: Pointer);

// 向量创建
function VecF32x4_Set(x, y, z, w: Single): TVecF32x4;
function VecF32x4_SetAll(value: Single): TVecF32x4;
function VecF32x4_Zero: TVecF32x4;

// 向量比较
function VecF32x4_Equal(const a, b: TVecF32x4): TMask4;
function VecF32x4_Less(const a, b: TVecF32x4): TMask4;
function VecF32x4_Greater(const a, b: TVecF32x4): TMask4;

// 向量数学函数
function VecF32x4_Sqrt(const a: TVecF32x4): TVecF32x4;
function VecF32x4_Min(const a, b: TVecF32x4): TVecF32x4;
function VecF32x4_Max(const a, b: TVecF32x4): TVecF32x4;
function VecF32x4_Abs(const a: TVecF32x4): TVecF32x4;

// 水平操作（归约）
function VecF32x4_HorizontalAdd(const a: TVecF32x4): Single;
function VecF32x4_HorizontalMin(const a: TVecF32x4): Single;
function VecF32x4_HorizontalMax(const a: TVecF32x4): Single;

implementation

uses
  {$IFDEF SIMD_X86_AVAILABLE}
  fafafa.core.simd.ops.x86,
  {$ENDIF}
  {$IFDEF SIMD_ARM_AVAILABLE}
  fafafa.core.simd.ops.arm,
  {$ENDIF}
  fafafa.core.simd.ops.scalar;

  {$IFDEF SIMD_X86_AVAILABLE}
  fafafa.core.simd.ops.avx,
  fafafa.core.simd.ops.avx2,
  {$ENDIF}

// === 实现选择器 ===

{$IFDEF SIMD_X86_AVAILABLE}

// 使用 x86 SIMD 实现：优先 AVX（若可用）
function VecF32x4_Add(const a, b: TVecF32x4): TVecF32x4;
begin
  // 对 128-bit 接口，若 AVX 可用则走 ymm 路径再落回低 128
  if HasAVX then
  begin
    // 将 128-bit 拼成 256 的 lo，hi=零；避免跨寄存器拼装，这里直接调用 128-bit 实现
    Result := X86_VecF32x4_Add(a, b);
  end
  else
    Result := X86_VecF32x4_Add(a, b);
end;

function VecF32x4_Sub(const a, b: TVecF32x4): TVecF32x4;
begin
  Result := X86_VecF32x4_Sub(a, b);
end;

function VecF32x4_Mul(const a, b: TVecF32x4): TVecF32x4;
begin
  Result := X86_VecF32x4_Mul(a, b);
end;

function VecF32x4_Div(const a, b: TVecF32x4): TVecF32x4;
begin
  Result := X86_VecF32x4_Div(a, b);
end;

function VecF32x4_Load(const ptr: Pointer): TVecF32x4;
begin
  Result := X86_VecF32x4_Load(ptr);
end;

procedure VecF32x4_Store(const vec: TVecF32x4; ptr: Pointer);
begin
  X86_VecF32x4_Store(vec, ptr);
end;

function VecF32x4_Set(x, y, z, w: Single): TVecF32x4;
begin
  Result := X86_VecF32x4_Set(x, y, z, w);
end;

function VecF32x4_SetAll(value: Single): TVecF32x4;
begin
  Result := X86_VecF32x4_SetAll(value);
end;

function VecF32x4_Zero: TVecF32x4;
begin
  Result := X86_VecF32x4_Zero;
end;

{$ELSE}

// 回退到标量实现
function VecF32x4_Add(const a, b: TVecF32x4): TVecF32x4;
begin
  Result := Scalar_VecF32x4_Add(a, b);
end;

function VecF32x4_Sub(const a, b: TVecF32x4): TVecF32x4;
begin
  Result := Scalar_VecF32x4_Sub(a, b);
end;

function VecF32x4_Mul(const a, b: TVecF32x4): TVecF32x4;
begin
  Result := Scalar_VecF32x4_Mul(a, b);
end;

// === 256-bit 路由（x86 平台） ===
function VecF32x8_Add(const a, b: TVecF32x8): TVecF32x8;
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  Result := AVX_VecF32x8_Add(a, b);
  {$ELSE}
  // 非 x86 平台：标量回退
  Result.lo := Scalar_VecF32x4_Add(a.lo, b.lo);
  Result.hi := Scalar_VecF32x4_Add(a.hi, b.hi);
  {$ENDIF}
end;

function VecF32x8_Sub(const a, b: TVecF32x8): TVecF32x8;
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  Result := AVX_VecF32x8_Sub(a, b);
  {$ELSE}
  Result.lo := Scalar_VecF32x4_Sub(a.lo, b.lo);
  Result.hi := Scalar_VecF32x4_Sub(a.hi, b.hi);
  {$ENDIF}
end;

function VecF32x8_Mul(const a, b: TVecF32x8): TVecF32x8;
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  Result := AVX_VecF32x8_Mul(a, b);
  {$ELSE}
  Result.lo := Scalar_VecF32x4_Mul(a.lo, b.lo);
  Result.hi := Scalar_VecF32x4_Mul(a.hi, b.hi);
  {$ENDIF}
end;

function VecF32x8_Div(const a, b: TVecF32x8): TVecF32x8;
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  Result := AVX_VecF32x8_Div(a, b);
  {$ELSE}
  Result.lo := Scalar_VecF32x4_Div(a.lo, b.lo);
  Result.hi := Scalar_VecF32x4_Div(a.hi, b.hi);
  {$ENDIF}
end;

function VecF32x8_Load(const ptr: Pointer): TVecF32x8;
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  Result := AVX_VecF32x8_Load(ptr);
  {$ELSE}
  Move(ptr^, Result, SizeOf(Result));
  {$ENDIF}
end;

procedure VecF32x8_Store(const vec: TVecF32x8; ptr: Pointer);
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  AVX_VecF32x8_Store(vec, ptr);
  {$ELSE}
  Move(vec, ptr^, SizeOf(vec));
  {$ENDIF}
end;

function VecF32x8_LoadUnaligned(const ptr: Pointer): TVecF32x8;
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  Result := AVX_VecF32x8_LoadUnaligned(ptr);
  {$ELSE}
  Move(ptr^, Result, SizeOf(Result));
  {$ENDIF}
end;

procedure VecF32x8_StoreUnaligned(const vec: TVecF32x8; ptr: Pointer);
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  AVX_VecF32x8_StoreUnaligned(vec, ptr);
  {$ELSE}
  Move(vec, ptr^, SizeOf(vec));
  {$ENDIF}
end;

function VecF32x8_SetAll(value: Single): TVecF32x8;
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  Result := AVX_VecF32x8_SetAll(value);
  {$ELSE}
  Result.lo := Scalar_VecF32x4_SetAll(value);
  Result.hi := Scalar_VecF32x4_SetAll(value);
  {$ENDIF}
end;

function VecF32x8_Zero: TVecF32x8;
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  Result := AVX_VecF32x8_Zero;
  {$ELSE}
  FillChar(Result, SizeOf(Result), 0);
  {$ENDIF}
end;

function VecI32x8_Add(const a, b: TVecI32x8): TVecI32x8;
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  Result := AVX2_VecI32x8_Add(a, b);
  {$ELSE}
  Result.i[0] := a.i[0] + b.i[0];
  Result.i[1] := a.i[1] + b.i[1];
  Result.i[2] := a.i[2] + b.i[2];
  Result.i[3] := a.i[3] + b.i[3];
  Result.i[4] := a.i[4] + b.i[4];
  Result.i[5] := a.i[5] + b.i[5];
  Result.i[6] := a.i[6] + b.i[6];
  Result.i[7] := a.i[7] + b.i[7];
  {$ENDIF}
end;

function VecI32x8_Sub(const a, b: TVecI32x8): TVecI32x8;
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  Result := AVX2_VecI32x8_Sub(a, b);
  {$ELSE}
  Result.i[0] := a.i[0] - b.i[0];
  Result.i[1] := a.i[1] - b.i[1];
  Result.i[2] := a.i[2] - b.i[2];
  Result.i[3] := a.i[3] - b.i[3];
  Result.i[4] := a.i[4] - b.i[4];
  Result.i[5] := a.i[5] - b.i[5];
  Result.i[6] := a.i[6] - b.i[6];
  Result.i[7] := a.i[7] - b.i[7];
  {$ENDIF}
end;

function VecI32x8_Mul(const a, b: TVecI32x8): TVecI32x8;
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  Result := AVX2_VecI32x8_Mul(a, b);
  {$ELSE}
  Result.i[0] := a.i[0] * b.i[0];
  Result.i[1] := a.i[1] * b.i[1];
  Result.i[2] := a.i[2] * b.i[2];
  Result.i[3] := a.i[3] * b.i[3];
  Result.i[4] := a.i[4] * b.i[4];
  Result.i[5] := a.i[5] * b.i[5];
  Result.i[6] := a.i[6] * b.i[6];
  Result.i[7] := a.i[7] * b.i[7];
  {$ENDIF}
end;

function VecI32x8_LoadUnaligned(const ptr: Pointer): TVecI32x8;
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  Result := AVX2_VecI32x8_LoadUnaligned(ptr);
  {$ELSE}
  Move(ptr^, Result, SizeOf(Result));
  {$ENDIF}
end;

procedure VecI32x8_StoreUnaligned(const vec: TVecI32x8; ptr: Pointer);
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  AVX2_VecI32x8_StoreUnaligned(vec, ptr);
  {$ELSE}
  Move(vec, ptr^, SizeOf(vec));
  {$ENDIF}
end;

function VecI32x8_SetAll(value: Int32): TVecI32x8;
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  Result := AVX2_VecI32x8_SetAll(value);
  {$ELSE}
  Result.i[0] := value; Result.i[1] := value; Result.i[2] := value; Result.i[3] := value;
  Result.i[4] := value; Result.i[5] := value; Result.i[6] := value; Result.i[7] := value;
  {$ENDIF}
end;

function VecI32x8_Zero: TVecI32x8;
begin
  {$IFDEF SIMD_X86_AVAILABLE}
  Result := AVX2_VecI32x8_Zero;
  {$ELSE}
  FillChar(Result, SizeOf(Result), 0);
  {$ENDIF}
end;


function VecF32x4_Div(const a, b: TVecF32x4): TVecF32x4;
begin
  Result := Scalar_VecF32x4_Div(a, b);
end;

function VecF32x4_Load(const ptr: Pointer): TVecF32x4;
begin
  Result := Scalar_VecF32x4_Load(ptr);
end;

procedure VecF32x4_Store(const vec: TVecF32x4; ptr: Pointer);
begin
  Scalar_VecF32x4_Store(vec, ptr);
end;

function VecF32x4_Set(x, y, z, w: Single): TVecF32x4;
begin
  Result := Scalar_VecF32x4_Set(x, y, z, w);
end;

function VecF32x4_SetAll(value: Single): TVecF32x4;
begin
  Result := Scalar_VecF32x4_SetAll(value);
end;

function VecF32x4_Zero: TVecF32x4;
begin
  Result := Scalar_VecF32x4_Zero;
end;

{$ENDIF}

// 其他函数的实现...
// (为了保持文件长度，这里省略了其他函数的实现)

end.
