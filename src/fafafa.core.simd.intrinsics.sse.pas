unit fafafa.core.simd.intrinsics.sse;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  === fafafa.core.simd.intrinsics.sse ===
  SSE (Streaming SIMD Extensions) 指令集支�?  
  SSE �?Intel �?1999 年引入的 128-bit SIMD 指令�?  主要用于单精度浮点运算，也包含一些整数操�?  
  特性：
  - 128-bit 向量寄存�?(xmm0-xmm7/xmm15)
  - 单精度浮点运�?(4x32-bit)
  - 预取指令
  - 流式存储
  - 缓存控制
  
  兼容性：所有现�?x86/x64 处理器都支持
}

interface

uses
  fafafa.core.simd.intrinsics.base;

// === SSE 单精度浮点函�?===
// Load/Store
function sse_load_ps(const Ptr: Pointer): TM128;
function sse_loadu_ps(const Ptr: Pointer): TM128;
function sse_load_ss(const Ptr: Pointer): TM128;
function sse_load1_ps(const Ptr: Pointer): TM128;
procedure sse_store_ps(var Dest; const Src: TM128);
procedure sse_storeu_ps(var Dest; const Src: TM128);
procedure sse_store_ss(var Dest; const Src: TM128);
procedure sse_store1_ps(var Dest; const Src: TM128);
function sse_movq(const Ptr: Pointer): TM128;
procedure sse_movq_store(var Dest; const Src: TM128);

// Set/Zero
function sse_setzero_ps: TM128;
function sse_set1_ps(Value: Single): TM128;
function sse_set_ps(e3, e2, e1, e0: Single): TM128;
function sse_set_ss(Value: Single): TM128;
function sse_setr_ps(e0, e1, e2, e3: Single): TM128;

// Arithmetic
function sse_add_ps(const a, b: TM128): TM128;
function sse_add_ss(const a, b: TM128): TM128;
function sse_sub_ps(const a, b: TM128): TM128;
function sse_sub_ss(const a, b: TM128): TM128;
function sse_mul_ps(const a, b: TM128): TM128;
function sse_mul_ss(const a, b: TM128): TM128;
function sse_div_ps(const a, b: TM128): TM128;
function sse_div_ss(const a, b: TM128): TM128;

// Math Functions
function sse_sqrt_ps(const a: TM128): TM128;
function sse_sqrt_ss(const a: TM128): TM128;
function sse_rsqrt_ps(const a: TM128): TM128;  // 平方根倒数近似
function sse_rsqrt_ss(const a: TM128): TM128;
function sse_rcp_ps(const a: TM128): TM128;    // 倒数近似
function sse_rcp_ss(const a: TM128): TM128;

// Min/Max
function sse_min_ps(const a, b: TM128): TM128;
function sse_min_ss(const a, b: TM128): TM128;
function sse_max_ps(const a, b: TM128): TM128;
function sse_max_ss(const a, b: TM128): TM128;

// Logical
function sse_and_ps(const a, b: TM128): TM128;
function sse_andnot_ps(const a, b: TM128): TM128;
function sse_andn_ps(const a, b: TM128): TM128;  // 别名
function sse_or_ps(const a, b: TM128): TM128;
function sse_xor_ps(const a, b: TM128): TM128;

// Compare
function sse_cmpeq_ps(const a, b: TM128): TM128;
function sse_cmpeq_ss(const a, b: TM128): TM128;
function sse_cmplt_ps(const a, b: TM128): TM128;
function sse_cmplt_ss(const a, b: TM128): TM128;
function sse_cmple_ps(const a, b: TM128): TM128;
function sse_cmple_ss(const a, b: TM128): TM128;
function sse_cmpgt_ps(const a, b: TM128): TM128;
function sse_cmpgt_ss(const a, b: TM128): TM128;
function sse_cmpge_ps(const a, b: TM128): TM128;
function sse_cmpge_ss(const a, b: TM128): TM128;
function sse_cmpneq_ps(const a, b: TM128): TM128;
function sse_cmpneq_ss(const a, b: TM128): TM128;
function sse_cmpord_ps(const a, b: TM128): TM128;
function sse_cmpord_ss(const a, b: TM128): TM128;
function sse_cmpunord_ps(const a, b: TM128): TM128;
function sse_cmpunord_ss(const a, b: TM128): TM128;

// Shuffle/Unpack
function sse_shuffle_ps(const a, b: TM128; imm8: Byte): TM128;
function sse_unpackhi_ps(const a, b: TM128): TM128;
function sse_unpacklo_ps(const a, b: TM128): TM128;
function sse_unpckhps(const a, b: TM128): TM128;  // 别名
function sse_unpcklps(const a, b: TM128): TM128;  // 别名

// Move
function sse_move_ss(const a, b: TM128): TM128;
function sse_movehl_ps(const a, b: TM128): TM128;
function sse_movelh_ps(const a, b: TM128): TM128;
function sse_movemask_ps(const a: TM128): Integer;
function sse_movaps(const a: TM128): TM128;
function sse_movups(const a: TM128): TM128;
function sse_movss(const a: TM128): TM128;
function sse_movhl_ps(const a, b: TM128): TM128;  // 别名
function sse_movlh_ps(const a, b: TM128): TM128;  // 别名
function sse_movd(Value: LongInt): TM128;
function sse_movd_toint(const a: TM128): LongInt;

// Convert
function sse_cvtsi2ss(const a: TM128; Value: LongInt): TM128;
function sse_cvtss2si(const a: TM128): LongInt;
function sse_cvttss2si(const a: TM128): LongInt;

// Prefetch and Cache Control
procedure sse_prefetch(const Ptr: Pointer; locality: Integer);
procedure sse_sfence;
procedure sse_stream_ps(var Dest; const Src: TM128);
procedure sse_stream_si64(var Dest; const Src: TM128);

// Miscellaneous
function sse_getcsr: Integer;
procedure sse_setcsr(Value: Integer);

implementation

function IsNaNValue(aValue: Single): Boolean; inline;
var
  LBits: LongWord absolute aValue;
begin
  Result := ((LBits and $7F800000) = $7F800000) and ((LBits and $007FFFFF) <> 0);
end;

function Mask32(aCondition: Boolean): DWord; inline;
begin
  if aCondition then
    Result := $FFFFFFFF
  else
    Result := 0;
end;

function LoadTM128(const Ptr: Pointer): TM128; inline;
begin
  Result := Default(TM128);
  if Ptr <> nil then
    Result := PTM128(Ptr)^;
end;

procedure StoreTM128(var Dest; const Src: TM128); inline;
begin
  PTM128(@Dest)^ := Src;
end;

function sse_load_ps(const Ptr: Pointer): TM128;
begin
  Result := LoadTM128(Ptr);
end;

function sse_loadu_ps(const Ptr: Pointer): TM128;
begin
  Result := LoadTM128(Ptr);
end;

function sse_load_ss(const Ptr: Pointer): TM128;
begin
  Result := Default(TM128);
  if Ptr <> nil then
    Result.m128_f32[0] := PSingle(Ptr)^;
end;

function sse_load1_ps(const Ptr: Pointer): TM128;
var
  LValue: Single;
  LIndex: Integer;
begin
  LValue := 0.0;
  if Ptr <> nil then
    Move(PByte(Ptr)^, LValue, SizeOf(Single));
  for LIndex := 0 to 3 do
    Result.m128_f32[LIndex] := LValue;
end;

procedure sse_store_ps(var Dest; const Src: TM128);
begin
  StoreTM128(Dest, Src);
end;

procedure sse_storeu_ps(var Dest; const Src: TM128);
begin
  StoreTM128(Dest, Src);
end;

procedure sse_store_ss(var Dest; const Src: TM128);
begin
  PSingle(@Dest)^ := Src.m128_f32[0];
end;

procedure sse_store1_ps(var Dest; const Src: TM128);
var
  LValue: Single;
  LIndex: Integer;
  LDest: PSingle;
begin
  LValue := Src.m128_f32[0];
  LDest := @Dest;
  for LIndex := 0 to 3 do
    LDest[LIndex] := LValue;
end;

function sse_movq(const Ptr: Pointer): TM128;
begin
  Result := Default(TM128);
  if Ptr <> nil then
    Result.m128i_u64[0] := PUInt64(Ptr)^;
end;

procedure sse_movq_store(var Dest; const Src: TM128);
begin
  PUInt64(@Dest)^ := Src.m128i_u64[0];
end;

function sse_setzero_ps: TM128;
begin
  Result := Default(TM128);
end;

function sse_set1_ps(Value: Single): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128_f32[LIndex] := Value;
end;

function sse_set_ps(e3, e2, e1, e0: Single): TM128;
begin
  Result.m128_f32[0] := e0;
  Result.m128_f32[1] := e1;
  Result.m128_f32[2] := e2;
  Result.m128_f32[3] := e3;
end;

function sse_set_ss(Value: Single): TM128;
begin
  Result := Default(TM128);
  Result.m128_f32[0] := Value;
end;

function sse_setr_ps(e0, e1, e2, e3: Single): TM128;
begin
  Result.m128_f32[0] := e0;
  Result.m128_f32[1] := e1;
  Result.m128_f32[2] := e2;
  Result.m128_f32[3] := e3;
end;

function sse_add_ps(const a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128_f32[LIndex] := a.m128_f32[LIndex] + b.m128_f32[LIndex];
end;

function sse_add_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := a.m128_f32[0] + b.m128_f32[0];
end;

function sse_sub_ps(const a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128_f32[LIndex] := a.m128_f32[LIndex] - b.m128_f32[LIndex];
end;

function sse_sub_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := a.m128_f32[0] - b.m128_f32[0];
end;

function sse_mul_ps(const a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128_f32[LIndex] := a.m128_f32[LIndex] * b.m128_f32[LIndex];
end;

function sse_mul_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := a.m128_f32[0] * b.m128_f32[0];
end;

function sse_div_ps(const a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128_f32[LIndex] := a.m128_f32[LIndex] / b.m128_f32[LIndex];
end;

function sse_div_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := a.m128_f32[0] / b.m128_f32[0];
end;

function sse_sqrt_ps(const a: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128_f32[LIndex] := Sqrt(a.m128_f32[LIndex]);
end;

function sse_sqrt_ss(const a: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := Sqrt(a.m128_f32[0]);
end;

function sse_rsqrt_ps(const a: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128_f32[LIndex] := 1.0 / Sqrt(a.m128_f32[LIndex]);
end;

function sse_rsqrt_ss(const a: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := 1.0 / Sqrt(a.m128_f32[0]);
end;

function sse_rcp_ps(const a: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128_f32[LIndex] := 1.0 / a.m128_f32[LIndex];
end;

function sse_rcp_ss(const a: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := 1.0 / a.m128_f32[0];
end;

function sse_min_ps(const a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    if a.m128_f32[LIndex] <= b.m128_f32[LIndex] then
      Result.m128_f32[LIndex] := a.m128_f32[LIndex]
    else
      Result.m128_f32[LIndex] := b.m128_f32[LIndex];
end;

function sse_min_ss(const a, b: TM128): TM128;
begin
  Result := a;
  if a.m128_f32[0] <= b.m128_f32[0] then
    Result.m128_f32[0] := a.m128_f32[0]
  else
    Result.m128_f32[0] := b.m128_f32[0];
end;

function sse_max_ps(const a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    if a.m128_f32[LIndex] >= b.m128_f32[LIndex] then
      Result.m128_f32[LIndex] := a.m128_f32[LIndex]
    else
      Result.m128_f32[LIndex] := b.m128_f32[LIndex];
end;

function sse_max_ss(const a, b: TM128): TM128;
begin
  Result := a;
  if a.m128_f32[0] >= b.m128_f32[0] then
    Result.m128_f32[0] := a.m128_f32[0]
  else
    Result.m128_f32[0] := b.m128_f32[0];
end;

function sse_and_ps(const a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128i_u32[LIndex] := a.m128i_u32[LIndex] and b.m128i_u32[LIndex];
end;

function sse_andnot_ps(const a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128i_u32[LIndex] := (not a.m128i_u32[LIndex]) and b.m128i_u32[LIndex];
end;

function sse_andn_ps(const a, b: TM128): TM128;
begin
  Result := sse_andnot_ps(a, b);
end;

function sse_or_ps(const a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128i_u32[LIndex] := a.m128i_u32[LIndex] or b.m128i_u32[LIndex];
end;

function sse_xor_ps(const a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128i_u32[LIndex] := a.m128i_u32[LIndex] xor b.m128i_u32[LIndex];
end;

function sse_cmpeq_ps(const a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128i_u32[LIndex] := Mask32(a.m128_f32[LIndex] = b.m128_f32[LIndex]);
end;

function sse_cmpeq_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128i_u32[0] := Mask32(a.m128_f32[0] = b.m128_f32[0]);
end;

function sse_cmplt_ps(const a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128i_u32[LIndex] := Mask32(a.m128_f32[LIndex] < b.m128_f32[LIndex]);
end;

function sse_cmplt_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128i_u32[0] := Mask32(a.m128_f32[0] < b.m128_f32[0]);
end;

function sse_cmple_ps(const a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128i_u32[LIndex] := Mask32(a.m128_f32[LIndex] <= b.m128_f32[LIndex]);
end;

function sse_cmple_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128i_u32[0] := Mask32(a.m128_f32[0] <= b.m128_f32[0]);
end;

function sse_cmpgt_ps(const a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128i_u32[LIndex] := Mask32(a.m128_f32[LIndex] > b.m128_f32[LIndex]);
end;

function sse_cmpgt_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128i_u32[0] := Mask32(a.m128_f32[0] > b.m128_f32[0]);
end;

function sse_cmpge_ps(const a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128i_u32[LIndex] := Mask32(a.m128_f32[LIndex] >= b.m128_f32[LIndex]);
end;

function sse_cmpge_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128i_u32[0] := Mask32(a.m128_f32[0] >= b.m128_f32[0]);
end;

function sse_cmpneq_ps(const a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128i_u32[LIndex] := Mask32(a.m128_f32[LIndex] <> b.m128_f32[LIndex]);
end;

function sse_cmpneq_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128i_u32[0] := Mask32(a.m128_f32[0] <> b.m128_f32[0]);
end;

function sse_cmpord_ps(const a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128i_u32[LIndex] := Mask32((not IsNaNValue(a.m128_f32[LIndex])) and (not IsNaNValue(b.m128_f32[LIndex])));
end;

function sse_cmpord_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128i_u32[0] := Mask32((not IsNaNValue(a.m128_f32[0])) and (not IsNaNValue(b.m128_f32[0])));
end;

function sse_cmpunord_ps(const a, b: TM128): TM128;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    Result.m128i_u32[LIndex] := Mask32(IsNaNValue(a.m128_f32[LIndex]) or IsNaNValue(b.m128_f32[LIndex]));
end;

function sse_cmpunord_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128i_u32[0] := Mask32(IsNaNValue(a.m128_f32[0]) or IsNaNValue(b.m128_f32[0]));
end;

function sse_shuffle_ps(const a, b: TM128; imm8: Byte): TM128;
begin
  Result.m128_f32[0] := a.m128_f32[imm8 and $03];
  Result.m128_f32[1] := a.m128_f32[(imm8 shr 2) and $03];
  Result.m128_f32[2] := b.m128_f32[(imm8 shr 4) and $03];
  Result.m128_f32[3] := b.m128_f32[(imm8 shr 6) and $03];
end;

function sse_unpackhi_ps(const a, b: TM128): TM128;
begin
  Result.m128_f32[0] := a.m128_f32[2];
  Result.m128_f32[1] := b.m128_f32[2];
  Result.m128_f32[2] := a.m128_f32[3];
  Result.m128_f32[3] := b.m128_f32[3];
end;

function sse_unpacklo_ps(const a, b: TM128): TM128;
begin
  Result.m128_f32[0] := a.m128_f32[0];
  Result.m128_f32[1] := b.m128_f32[0];
  Result.m128_f32[2] := a.m128_f32[1];
  Result.m128_f32[3] := b.m128_f32[1];
end;

function sse_unpckhps(const a, b: TM128): TM128;
begin
  Result := sse_unpackhi_ps(a, b);
end;

function sse_unpcklps(const a, b: TM128): TM128;
begin
  Result := sse_unpacklo_ps(a, b);
end;

function sse_move_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := b.m128_f32[0];
end;

function sse_movehl_ps(const a, b: TM128): TM128;
begin
  Result.m128_f32[0] := b.m128_f32[2];
  Result.m128_f32[1] := b.m128_f32[3];
  Result.m128_f32[2] := a.m128_f32[2];
  Result.m128_f32[3] := a.m128_f32[3];
end;

function sse_movelh_ps(const a, b: TM128): TM128;
begin
  Result.m128_f32[0] := a.m128_f32[0];
  Result.m128_f32[1] := a.m128_f32[1];
  Result.m128_f32[2] := b.m128_f32[0];
  Result.m128_f32[3] := b.m128_f32[1];
end;

function sse_movemask_ps(const a: TM128): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to 3 do
    if (a.m128i_u32[LIndex] and $80000000) <> 0 then
      Result := Result or (1 shl LIndex);
end;

function sse_movaps(const a: TM128): TM128;
begin
  Result := a;
end;

function sse_movups(const a: TM128): TM128;
begin
  Result := a;
end;

function sse_movss(const a: TM128): TM128;
begin
  Result := Default(TM128);
  Result.m128_f32[0] := a.m128_f32[0];
end;

function sse_movhl_ps(const a, b: TM128): TM128;
begin
  Result := sse_movehl_ps(a, b);
end;

function sse_movlh_ps(const a, b: TM128): TM128;
begin
  Result := sse_movelh_ps(a, b);
end;

function sse_movd(Value: LongInt): TM128;
begin
  Result := Default(TM128);
  Result.m128i_i32[0] := Value;
end;

function sse_movd_toint(const a: TM128): LongInt;
begin
  Result := a.m128i_i32[0];
end;

function sse_cvtsi2ss(const a: TM128; Value: LongInt): TM128;
begin
  Result := a;
  Result.m128_f32[0] := Value;
end;

function sse_cvtss2si(const a: TM128): LongInt;
begin
  Result := Round(a.m128_f32[0]);
end;

function sse_cvttss2si(const a: TM128): LongInt;
begin
  Result := Trunc(a.m128_f32[0]);
end;

procedure sse_prefetch(const Ptr: Pointer; locality: Integer);
var
  LPtr: Pointer;
  LLocality: Integer;
begin
  LPtr := Ptr;
  LLocality := locality;
  if (LPtr = nil) and (LLocality = Low(Integer)) then
    Exit;
end;

procedure sse_sfence;
begin
end;

procedure sse_stream_ps(var Dest; const Src: TM128);
begin
  PTM128(@Dest)^ := Src;
end;

procedure sse_stream_si64(var Dest; const Src: TM128);
begin
  PUInt64(@Dest)^ := Src.m128i_u64[0];
end;

function sse_getcsr: Integer;
begin
  Result := 0;
end;

procedure sse_setcsr(Value: Integer);
var
  LValue: Integer;
begin
  LValue := Value;
  if LValue = Low(Integer) then
    Exit;
end;

end.
