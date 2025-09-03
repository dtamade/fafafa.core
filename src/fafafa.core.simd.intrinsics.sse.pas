unit fafafa.core.simd.intrinsics.sse;

{$I fafafa.core.settings.inc}

{
  === fafafa.core.simd.intrinsics.sse ===
  SSE (Streaming SIMD Extensions) 指令集支持
  
  SSE 是 Intel 在 1999 年引入的 128-bit SIMD 指令集
  主要用于单精度浮点运算，也包含一些整数操作
  
  特性：
  - 128-bit 向量寄存器 (xmm0-xmm7/xmm15)
  - 单精度浮点运算 (4x32-bit)
  - 预取指令
  - 流式存储
  - 缓存控制
  
  兼容性：所有现代 x86/x64 处理器都支持
}

interface

uses
  fafafa.core.simd.intrinsics.base;

// === SSE 单精度浮点函数 ===
// Load/Store
function sse_load_ps(const Ptr: Pointer): TM128;
function sse_loadu_ps(const Ptr: Pointer): TM128;
function sse_load_ss(const Ptr: Pointer): TM128;
function sse_load1_ps(const Ptr: Pointer): TM128;
procedure sse_store_ps(var Dest; const Src: TM128);
procedure sse_storeu_ps(var Dest; const Src: TM128);
procedure sse_store_ss(var Dest; const Src: TM128);
procedure sse_store1_ps(var Dest; const Src: TM128);

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

// Shuffle/Unpack
function sse_shuffle_ps(const a, b: TM128; imm8: Byte): TM128;
function sse_unpackhi_ps(const a, b: TM128): TM128;
function sse_unpacklo_ps(const a, b: TM128): TM128;

// Move
function sse_move_ss(const a, b: TM128): TM128;
function sse_movehl_ps(const a, b: TM128): TM128;
function sse_movelh_ps(const a, b: TM128): TM128;
function sse_movemask_ps(const a: TM128): Integer;

// Convert
function sse_cvtsi2ss(const a: TM128; Value: LongInt): TM128;
function sse_cvtss2si(const a: TM128): LongInt;
function sse_cvttss2si(const a: TM128): LongInt;

// Prefetch and Cache Control
procedure sse_prefetch(const Ptr: Pointer; locality: Integer);
procedure sse_sfence;

implementation

// === 基础函数实现 (Pascal 版本) ===
function sse_load_ps(const Ptr: Pointer): TM128;
begin
  Result := PTM128(Ptr)^;
end;

function sse_loadu_ps(const Ptr: Pointer): TM128;
begin
  Result := PTM128(Ptr)^;
end;

function sse_load_ss(const Ptr: Pointer): TM128;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.m128_f32[0] := PSingle(Ptr)^;
end;

function sse_load1_ps(const Ptr: Pointer): TM128;
var
  value: Single;
  i: Integer;
begin
  value := PSingle(Ptr)^;
  for i := 0 to 3 do
    Result.m128_f32[i] := value;
end;

procedure sse_store_ps(var Dest; const Src: TM128);
begin
  PTM128(@Dest)^ := Src;
end;

procedure sse_storeu_ps(var Dest; const Src: TM128);
begin
  PTM128(@Dest)^ := Src;
end;

procedure sse_store_ss(var Dest; const Src: TM128);
begin
  PSingle(@Dest)^ := Src.m128_f32[0];
end;

procedure sse_store1_ps(var Dest; const Src: TM128);
var
  arr: array[0..3] of Single absolute Dest;
  i: Integer;
begin
  for i := 0 to 3 do
    arr[i] := Src.m128_f32[0];
end;

function sse_setzero_ps: TM128;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function sse_set1_ps(Value: Single): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := Value;
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
  FillChar(Result, SizeOf(Result), 0);
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
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := a.m128_f32[i] + b.m128_f32[i];
end;

function sse_add_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := a.m128_f32[0] + b.m128_f32[0];
end;

function sse_sub_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := a.m128_f32[i] - b.m128_f32[i];
end;

function sse_sub_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := a.m128_f32[0] - b.m128_f32[0];
end;

function sse_mul_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := a.m128_f32[i] * b.m128_f32[i];
end;

function sse_mul_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := a.m128_f32[0] * b.m128_f32[0];
end;

function sse_div_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := a.m128_f32[i] / b.m128_f32[i];
end;

function sse_div_ss(const a, b: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := a.m128_f32[0] / b.m128_f32[0];
end;

function sse_sqrt_ps(const a: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := Sqrt(a.m128_f32[i]);
end;

function sse_sqrt_ss(const a: TM128): TM128;
begin
  Result := a;
  Result.m128_f32[0] := Sqrt(a.m128_f32[0]);
end;

function sse_rsqrt_ps(const a: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128_f32[i] <> 0 then
      Result.m128_f32[i] := 1.0 / Sqrt(a.m128_f32[i])
    else
      Result.m128_f32[i] := 0;
end;

function sse_rsqrt_ss(const a: TM128): TM128;
begin
  Result := a;
  if a.m128_f32[0] <> 0 then
    Result.m128_f32[0] := 1.0 / Sqrt(a.m128_f32[0])
  else
    Result.m128_f32[0] := 0;
end;

function sse_rcp_ps(const a: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128_f32[i] <> 0 then
      Result.m128_f32[i] := 1.0 / a.m128_f32[i]
    else
      Result.m128_f32[i] := 0;
end;

function sse_rcp_ss(const a: TM128): TM128;
begin
  Result := a;
  if a.m128_f32[0] <> 0 then
    Result.m128_f32[0] := 1.0 / a.m128_f32[0]
  else
    Result.m128_f32[0] := 0;
end;

function sse_min_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128_f32[i] < b.m128_f32[i] then
      Result.m128_f32[i] := a.m128_f32[i]
    else
      Result.m128_f32[i] := b.m128_f32[i];
end;

function sse_min_ss(const a, b: TM128): TM128;
begin
  Result := a;
  if a.m128_f32[0] < b.m128_f32[0] then
    Result.m128_f32[0] := a.m128_f32[0]
  else
    Result.m128_f32[0] := b.m128_f32[0];
end;

function sse_max_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128_f32[i] > b.m128_f32[i] then
      Result.m128_f32[i] := a.m128_f32[i]
    else
      Result.m128_f32[i] := b.m128_f32[i];
end;

function sse_max_ss(const a, b: TM128): TM128;
begin
  Result := a;
  if a.m128_f32[0] > b.m128_f32[0] then
    Result.m128_f32[0] := a.m128_f32[0]
  else
    Result.m128_f32[0] := b.m128_f32[0];
end;

function sse_and_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := a.m128i_u32[i] and b.m128i_u32[i];
end;

function sse_andnot_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := (not a.m128i_u32[i]) and b.m128i_u32[i];
end;

function sse_or_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := a.m128i_u32[i] or b.m128i_u32[i];
end;

function sse_xor_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := a.m128i_u32[i] xor b.m128i_u32[i];
end;

function sse_cmpeq_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128_f32[i] = b.m128_f32[i] then
      Result.m128i_u32[i] := $FFFFFFFF
    else
      Result.m128i_u32[i] := $00000000;
end;

function sse_cmpeq_ss(const a, b: TM128): TM128;
begin
  Result := a;
  if a.m128_f32[0] = b.m128_f32[0] then
    Result.m128i_u32[0] := $FFFFFFFF
  else
    Result.m128i_u32[0] := $00000000;
end;

function sse_cmplt_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128_f32[i] < b.m128_f32[i] then
      Result.m128i_u32[i] := $FFFFFFFF
    else
      Result.m128i_u32[i] := $00000000;
end;

function sse_cmplt_ss(const a, b: TM128): TM128;
begin
  Result := a;
  if a.m128_f32[0] < b.m128_f32[0] then
    Result.m128i_u32[0] := $FFFFFFFF
  else
    Result.m128i_u32[0] := $00000000;
end;

function sse_cmple_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128_f32[i] <= b.m128_f32[i] then
      Result.m128i_u32[i] := $FFFFFFFF
    else
      Result.m128i_u32[i] := $00000000;
end;

function sse_cmple_ss(const a, b: TM128): TM128;
begin
  Result := a;
  if a.m128_f32[0] <= b.m128_f32[0] then
    Result.m128i_u32[0] := $FFFFFFFF
  else
    Result.m128i_u32[0] := $00000000;
end;

function sse_cmpgt_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128_f32[i] > b.m128_f32[i] then
      Result.m128i_u32[i] := $FFFFFFFF
    else
      Result.m128i_u32[i] := $00000000;
end;

function sse_cmpgt_ss(const a, b: TM128): TM128;
begin
  Result := a;
  if a.m128_f32[0] > b.m128_f32[0] then
    Result.m128i_u32[0] := $FFFFFFFF
  else
    Result.m128i_u32[0] := $00000000;
end;

function sse_cmpge_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128_f32[i] >= b.m128_f32[i] then
      Result.m128i_u32[i] := $FFFFFFFF
    else
      Result.m128i_u32[i] := $00000000;
end;

function sse_cmpge_ss(const a, b: TM128): TM128;
begin
  Result := a;
  if a.m128_f32[0] >= b.m128_f32[0] then
    Result.m128i_u32[0] := $FFFFFFFF
  else
    Result.m128i_u32[0] := $00000000;
end;

function sse_cmpneq_ps(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128_f32[i] <> b.m128_f32[i] then
      Result.m128i_u32[i] := $FFFFFFFF
    else
      Result.m128i_u32[i] := $00000000;
end;

function sse_cmpneq_ss(const a, b: TM128): TM128;
begin
  Result := a;
  if a.m128_f32[0] <> b.m128_f32[0] then
    Result.m128i_u32[0] := $FFFFFFFF
  else
    Result.m128i_u32[0] := $00000000;
end;

// 简化的 shuffle 实现
function sse_shuffle_ps(const a, b: TM128; imm8: Byte): TM128;
begin
  // 简化实现，实际应该根据 imm8 进行复杂的重排
  Result.m128_f32[0] := a.m128_f32[imm8 and 3];
  Result.m128_f32[1] := a.m128_f32[(imm8 shr 2) and 3];
  Result.m128_f32[2] := b.m128_f32[(imm8 shr 4) and 3];
  Result.m128_f32[3] := b.m128_f32[(imm8 shr 6) and 3];
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
  i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if (a.m128i_u32[i] and $80000000) <> 0 then
      Result := Result or (1 shl i);
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
begin
  // 预取指令的占位符实现
  // 在实际实现中，这里应该执行相应的预取指令
end;

procedure sse_sfence;
begin
  // 存储栅栏指令的占位符实现
  // 在实际实现中，这里应该执行 SFENCE 指令
end;

end.
