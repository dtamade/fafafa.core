unit fafafa.core.simd.intrinsics.lasx;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  === fafafa.core.simd.intrinsics.lasx ===
  LoongArch LASX (LoongArch Advanced SIMD eXtension) 指令集支�?  
  LASX 是龙芯架构的 256-bit SIMD 指令集扩�?  提供高性能的向量运算能�?  
  特性：
  - 256-bit 向量寄存�?(xr0-xr31)
  - 整数和浮点运�?  - 向量加载/存储
  - 向量置换和重�?  
  兼容性：LoongArch 3A5000 及更新的处理�?}

interface

uses
  fafafa.core.simd.intrinsics.base;

{$IFDEF CPULOONGARCH64}

// === LASX 占位符类�?===
type
  // LASX 256-bit 向量类型
  TLASXVector = record
    case Integer of
      0: (lasx_u32: array[0..7] of UInt32);   // 8�?2位元�?      1: (lasx_i32: array[0..7] of LongInt);
      2: (lasx_f32: array[0..7] of Single);
      3: (lasx_u64: array[0..3] of UInt64);   // 4�?4位元�?      4: (lasx_i64: array[0..3] of Int64);
      5: (lasx_f64: array[0..3] of Double);
      6: (lasx_u16: array[0..15] of UInt16);  // 16�?6位元�?      7: (lasx_i16: array[0..15] of SmallInt);
      8: (lasx_u8: array[0..31] of UInt8);    // 32�?位元�?      9: (lasx_i8: array[0..31] of ShortInt);
  end;
  PLASXVector = ^TLASXVector;

// === LASX 基础函数 (占位�? ===
// Load/Store
function lasx_xvld(const Ptr: Pointer; offset: Integer): TLASXVector;
procedure lasx_xvst(var Dest; const Src: TLASXVector; offset: Integer);

// Set/Replicate
function lasx_xvreplgr2vr_w(Value: UInt32): TLASXVector;
function lasx_xvreplgr2vr_d(Value: UInt64): TLASXVector;

// Arithmetic
function lasx_xvadd_w(const a, b: TLASXVector): TLASXVector;
function lasx_xvadd_d(const a, b: TLASXVector): TLASXVector;
function lasx_xvsub_w(const a, b: TLASXVector): TLASXVector;
function lasx_xvsub_d(const a, b: TLASXVector): TLASXVector;
function lasx_xvmul_w(const a, b: TLASXVector): TLASXVector;
function lasx_xvmul_d(const a, b: TLASXVector): TLASXVector;

// Logical
function lasx_xvand_v(const a, b: TLASXVector): TLASXVector;
function lasx_xvor_v(const a, b: TLASXVector): TLASXVector;
function lasx_xvxor_v(const a, b: TLASXVector): TLASXVector;
function lasx_xvnor_v(const a, b: TLASXVector): TLASXVector;

// Compare
function lasx_xvseq_w(const a, b: TLASXVector): TLASXVector;
function lasx_xvseq_d(const a, b: TLASXVector): TLASXVector;
function lasx_xvslt_w(const a, b: TLASXVector): TLASXVector;
function lasx_xvslt_d(const a, b: TLASXVector): TLASXVector;

// Min/Max
function lasx_xvmax_w(const a, b: TLASXVector): TLASXVector;
function lasx_xvmax_d(const a, b: TLASXVector): TLASXVector;
function lasx_xvmin_w(const a, b: TLASXVector): TLASXVector;
function lasx_xvmin_d(const a, b: TLASXVector): TLASXVector;

{$ENDIF} // CPULOONGARCH64

implementation

{$IFDEF CPULOONGARCH64}

// === LASX 函数的简化实�?===
function lasx_xvld(const Ptr: Pointer; offset: Integer): TLASXVector;
var
  src: PByte;
begin
  src := PByte(Ptr);
  Inc(src, offset);
  Move(src^, Result, SizeOf(TLASXVector));
end;

procedure lasx_xvst(var Dest; const Src: TLASXVector; offset: Integer);
var
  dst: PByte;
begin
  dst := PByte(@Dest);
  Inc(dst, offset);
  Move(Src, dst^, SizeOf(TLASXVector));
end;

function lasx_xvreplgr2vr_w(Value: UInt32): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.lasx_u32[i] := Value;
end;

function lasx_xvreplgr2vr_d(Value: UInt64): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.lasx_u64[i] := Value;
end;

function lasx_xvadd_w(const a, b: TLASXVector): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.lasx_u32[i] := a.lasx_u32[i] + b.lasx_u32[i];
end;

function lasx_xvadd_d(const a, b: TLASXVector): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.lasx_u64[i] := a.lasx_u64[i] + b.lasx_u64[i];
end;

function lasx_xvsub_w(const a, b: TLASXVector): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.lasx_u32[i] := a.lasx_u32[i] - b.lasx_u32[i];
end;

function lasx_xvsub_d(const a, b: TLASXVector): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.lasx_u64[i] := a.lasx_u64[i] - b.lasx_u64[i];
end;

function lasx_xvmul_w(const a, b: TLASXVector): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.lasx_u32[i] := a.lasx_u32[i] * b.lasx_u32[i];
end;

function lasx_xvmul_d(const a, b: TLASXVector): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.lasx_u64[i] := a.lasx_u64[i] * b.lasx_u64[i];
end;

function lasx_xvand_v(const a, b: TLASXVector): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.lasx_u32[i] := a.lasx_u32[i] and b.lasx_u32[i];
end;

function lasx_xvor_v(const a, b: TLASXVector): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.lasx_u32[i] := a.lasx_u32[i] or b.lasx_u32[i];
end;

function lasx_xvxor_v(const a, b: TLASXVector): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.lasx_u32[i] := a.lasx_u32[i] xor b.lasx_u32[i];
end;

function lasx_xvnor_v(const a, b: TLASXVector): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.lasx_u32[i] := not (a.lasx_u32[i] or b.lasx_u32[i]);
end;

function lasx_xvseq_w(const a, b: TLASXVector): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 7 do
    if a.lasx_u32[i] = b.lasx_u32[i] then
      Result.lasx_u32[i] := $FFFFFFFF
    else
      Result.lasx_u32[i] := $00000000;
end;

function lasx_xvseq_d(const a, b: TLASXVector): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.lasx_u64[i] = b.lasx_u64[i] then
      Result.lasx_u64[i] := $FFFFFFFFFFFFFFFF
    else
      Result.lasx_u64[i] := $0000000000000000;
end;

function lasx_xvslt_w(const a, b: TLASXVector): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 7 do
    if a.lasx_i32[i] < b.lasx_i32[i] then
      Result.lasx_u32[i] := $FFFFFFFF
    else
      Result.lasx_u32[i] := $00000000;
end;

function lasx_xvslt_d(const a, b: TLASXVector): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.lasx_i64[i] < b.lasx_i64[i] then
      Result.lasx_u64[i] := $FFFFFFFFFFFFFFFF
    else
      Result.lasx_u64[i] := $0000000000000000;
end;

function lasx_xvmax_w(const a, b: TLASXVector): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 7 do
    if a.lasx_i32[i] > b.lasx_i32[i] then
      Result.lasx_i32[i] := a.lasx_i32[i]
    else
      Result.lasx_i32[i] := b.lasx_i32[i];
end;

function lasx_xvmax_d(const a, b: TLASXVector): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.lasx_i64[i] > b.lasx_i64[i] then
      Result.lasx_i64[i] := a.lasx_i64[i]
    else
      Result.lasx_i64[i] := b.lasx_i64[i];
end;

function lasx_xvmin_w(const a, b: TLASXVector): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 7 do
    if a.lasx_i32[i] < b.lasx_i32[i] then
      Result.lasx_i32[i] := a.lasx_i32[i]
    else
      Result.lasx_i32[i] := b.lasx_i32[i];
end;

function lasx_xvmin_d(const a, b: TLASXVector): TLASXVector;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.lasx_i64[i] < b.lasx_i64[i] then
      Result.lasx_i64[i] := a.lasx_i64[i]
    else
      Result.lasx_i64[i] := b.lasx_i64[i];
end;

{$ELSE}
// �?LoongArch 平台的空实现
{$ENDIF} // CPULOONGARCH64

end.


