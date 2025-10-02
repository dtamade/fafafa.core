unit fafafa.core.simd.scalar;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.types,
  fafafa.core.simd.dispatch;

// === Scalar Backend Implementation ===
// This provides the reference implementation for all SIMD operations
// using pure scalar code. It serves as:
// 1. Fallback when no SIMD hardware is available
// 2. Reference for correctness testing
// 3. Performance baseline

// Register the scalar backend
procedure RegisterScalarBackend;

// === 标量门面函数声明 ===

// 内存操作函数
function MemEqual_Scalar(a, b: Pointer; len: SizeUInt): LongBool;
function MemFindByte_Scalar(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
function MemDiffRange_Scalar(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
procedure MemCopy_Scalar(src, dst: Pointer; len: SizeUInt);
procedure MemSet_Scalar(dst: Pointer; len: SizeUInt; value: Byte);
procedure MemReverse_Scalar(p: Pointer; len: SizeUInt);

// 统计函数
function SumBytes_Scalar(p: Pointer; len: SizeUInt): UInt64;
procedure MinMaxBytes_Scalar(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
function CountByte_Scalar(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;

// 文本处理函数
function Utf8Validate_Scalar(p: Pointer; len: SizeUInt): Boolean;
function AsciiIEqual_Scalar(a, b: Pointer; len: SizeUInt): Boolean;
procedure ToLowerAscii_Scalar(p: Pointer; len: SizeUInt);
procedure ToUpperAscii_Scalar(p: Pointer; len: SizeUInt);

// 搜索函数
function BytesIndexOf_Scalar(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;

// 位集函数
function BitsetPopCount_Scalar(p: Pointer; byteLen: SizeUInt): SizeUInt;

implementation

uses
  Math,
  SysUtils;

// === Vector Type Implementations ===
// These are the actual data structures for vectors

type
  // 32-bit float vectors
  TVecF32x4Data = array[0..3] of Single;
  TVecF32x8Data = array[0..7] of Single;

  // 64-bit float vectors
  TVecF64x2Data = array[0..1] of Double;
  TVecF64x4Data = array[0..3] of Double;

  // 32-bit integer vectors
  TVecI32x4Data = array[0..3] of Int32;
  TVecI32x8Data = array[0..7] of Int32;

// Redefine the vector types with actual data
{$PUSH}
{$WARNINGS OFF} // Suppress redefinition warnings
type
  TVecF32x4 = record
    Data: TVecF32x4Data;
  end;

  TVecF32x8 = record
    Data: TVecF32x8Data;
  end;

  TVecF64x2 = record
    Data: TVecF64x2Data;
  end;

  TVecF64x4 = record
    Data: TVecF64x4Data;
  end;

  TVecI32x4 = record
    Data: TVecI32x4Data;
  end;

  TVecI32x8 = record
    Data: TVecI32x8Data;
  end;
{$POP}

// === Arithmetic Operations ===

function ScalarAddF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := a.Data[i] + b.Data[i];
end;

function ScalarSubF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := a.Data[i] - b.Data[i];
end;

function ScalarMulF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := a.Data[i] * b.Data[i];
end;

function ScalarDivF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := a.Data[i] / b.Data[i];
end;

function ScalarAddF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.Data[i] := a.Data[i] + b.Data[i];
end;

function ScalarSubF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.Data[i] := a.Data[i] - b.Data[i];
end;

function ScalarMulF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.Data[i] := a.Data[i] * b.Data[i];
end;

function ScalarDivF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.Data[i] := a.Data[i] / b.Data[i];
end;

function ScalarAddF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.Data[i] := a.Data[i] + b.Data[i];
end;

function ScalarSubF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.Data[i] := a.Data[i] - b.Data[i];
end;

function ScalarMulF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.Data[i] := a.Data[i] * b.Data[i];
end;

function ScalarDivF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.Data[i] := a.Data[i] / b.Data[i];
end;

function ScalarAddI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := a.Data[i] + b.Data[i];
end;

function ScalarSubI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := a.Data[i] - b.Data[i];
end;

function ScalarMulI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := a.Data[i] * b.Data[i];
end;

// === Comparison Operations ===

function ScalarCmpEqF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.Data[i] = b.Data[i] then
      Result := Result or (1 shl i);
end;

function ScalarCmpLtF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.Data[i] < b.Data[i] then
      Result := Result or (1 shl i);
end;

function ScalarCmpLeF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.Data[i] <= b.Data[i] then
      Result := Result or (1 shl i);
end;

function ScalarCmpGtF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.Data[i] > b.Data[i] then
      Result := Result or (1 shl i);
end;

function ScalarCmpGeF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.Data[i] >= b.Data[i] then
      Result := Result or (1 shl i);
end;

function ScalarCmpNeF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.Data[i] <> b.Data[i] then
      Result := Result or (1 shl i);
end;

// === Math Functions ===

function ScalarAbsF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := Abs(a.Data[i]);
end;

function ScalarSqrtF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := Sqrt(a.Data[i]);
end;

function ScalarMinF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := Min(a.Data[i], b.Data[i]);
end;

function ScalarMaxF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := Max(a.Data[i], b.Data[i]);
end;

// === Reduction Operations ===

function ScalarReduceAddF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := 0.0;
  for i := 0 to 3 do
    Result := Result + a.Data[i];
end;

function ScalarReduceMinF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := a.Data[0];
  for i := 1 to 3 do
    Result := Min(Result, a.Data[i]);
end;

function ScalarReduceMaxF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := a.Data[0];
  for i := 1 to 3 do
    Result := Max(Result, a.Data[i]);
end;

function ScalarReduceMulF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := 1.0;
  for i := 0 to 3 do
    Result := Result * a.Data[i];
end;

// === Memory Operations ===

function ScalarLoadF32x4(p: PSingle): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := p[i];
end;

function ScalarLoadF32x4Aligned(p: PSingle): TVecF32x4;
begin
  // For scalar implementation, aligned and unaligned are the same
  Result := ScalarLoadF32x4(p);
end;

procedure ScalarStoreF32x4(p: PSingle; const a: TVecF32x4);
var i: Integer;
begin
  for i := 0 to 3 do
    p[i] := a.Data[i];
end;

procedure ScalarStoreF32x4Aligned(p: PSingle; const a: TVecF32x4);
begin
  // For scalar implementation, aligned and unaligned are the same
  ScalarStoreF32x4(p, a);
end;

// === Utility Operations ===

function ScalarSplatF32x4(value: Single): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := value;
end;

function ScalarZeroF32x4: TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.Data[i] := 0.0;
end;

function ScalarSelectF32x4(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if (mask and (1 shl i)) <> 0 then
      Result.Data[i] := a.Data[i]
    else
      Result.Data[i] := b.Data[i];
end;

function ScalarExtractF32x4(const a: TVecF32x4; index: Integer): Single;
begin
  {$IFDEF SIMD_BOUNDS_CHECK}
  if (index < 0) or (index > 3) then
    raise EArgumentOutOfRangeException.CreateFmt('Index %d out of range [0..3]', [index]);
  {$ENDIF}
  Result := a.Data[index];
end;

function ScalarInsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
begin
  {$IFDEF SIMD_BOUNDS_CHECK}
  if (index < 0) or (index > 3) then
    raise EArgumentOutOfRangeException.CreateFmt('Index %d out of range [0..3]', [index]);
  {$ENDIF}
  Result := a;
  Result.Data[index] := value;
end;

// === Backend Registration ===

procedure RegisterScalarBackend;
var
  dispatchTable: TSimdDispatchTable;
begin
  // Initialize dispatch table
  FillChar(dispatchTable, SizeOf(dispatchTable), 0);

  // Set backend info
  dispatchTable.Backend := sbScalar;
  dispatchTable.BackendInfo := GetBackendInfo(sbScalar);

  // Register arithmetic operations
  dispatchTable.AddF32x4 := @ScalarAddF32x4;
  dispatchTable.SubF32x4 := @ScalarSubF32x4;
  dispatchTable.MulF32x4 := @ScalarMulF32x4;
  dispatchTable.DivF32x4 := @ScalarDivF32x4;

  dispatchTable.AddF32x8 := @ScalarAddF32x8;
  dispatchTable.SubF32x8 := @ScalarSubF32x8;
  dispatchTable.MulF32x8 := @ScalarMulF32x8;
  dispatchTable.DivF32x8 := @ScalarDivF32x8;

  dispatchTable.AddF64x2 := @ScalarAddF64x2;
  dispatchTable.SubF64x2 := @ScalarSubF64x2;
  dispatchTable.MulF64x2 := @ScalarMulF64x2;
  dispatchTable.DivF64x2 := @ScalarDivF64x2;

  dispatchTable.AddI32x4 := @ScalarAddI32x4;
  dispatchTable.SubI32x4 := @ScalarSubI32x4;
  dispatchTable.MulI32x4 := @ScalarMulI32x4;

  // Register comparison operations
  dispatchTable.CmpEqF32x4 := @ScalarCmpEqF32x4;
  dispatchTable.CmpLtF32x4 := @ScalarCmpLtF32x4;
  dispatchTable.CmpLeF32x4 := @ScalarCmpLeF32x4;
  dispatchTable.CmpGtF32x4 := @ScalarCmpGtF32x4;
  dispatchTable.CmpGeF32x4 := @ScalarCmpGeF32x4;
  dispatchTable.CmpNeF32x4 := @ScalarCmpNeF32x4;

  // Register math functions
  dispatchTable.AbsF32x4 := @ScalarAbsF32x4;
  dispatchTable.SqrtF32x4 := @ScalarSqrtF32x4;
  dispatchTable.MinF32x4 := @ScalarMinF32x4;
  dispatchTable.MaxF32x4 := @ScalarMaxF32x4;

  // Register reduction operations
  dispatchTable.ReduceAddF32x4 := @ScalarReduceAddF32x4;
  dispatchTable.ReduceMinF32x4 := @ScalarReduceMinF32x4;
  dispatchTable.ReduceMaxF32x4 := @ScalarReduceMaxF32x4;
  dispatchTable.ReduceMulF32x4 := @ScalarReduceMulF32x4;

  // Register memory operations
  dispatchTable.LoadF32x4 := @ScalarLoadF32x4;
  dispatchTable.LoadF32x4Aligned := @ScalarLoadF32x4Aligned;
  dispatchTable.StoreF32x4 := @ScalarStoreF32x4;
  dispatchTable.StoreF32x4Aligned := @ScalarStoreF32x4Aligned;

  // Register utility operations
  dispatchTable.SplatF32x4 := @ScalarSplatF32x4;
  dispatchTable.ZeroF32x4 := @ScalarZeroF32x4;
  dispatchTable.SelectF32x4 := @ScalarSelectF32x4;
  dispatchTable.ExtractF32x4 := @ScalarExtractF32x4;
  dispatchTable.InsertF32x4 := @ScalarInsertF32x4;

  // Register the backend
  RegisterBackend(sbScalar, dispatchTable);
end;

// === 标量门面函数实现 ===

// 内存操作函数
function MemEqual_Scalar(a, b: Pointer; len: SizeUInt): LongBool;
var
  pa, pb: PByte;
  i: SizeUInt;
begin
  if len = 0 then
  begin
    Result := True;
    Exit;
  end;

  if (a = nil) or (b = nil) then
  begin
    Result := (a = b);
    Exit;
  end;

  pa := PByte(a);
  pb := PByte(b);

  for i := 0 to len - 1 do
  begin
    if pa[i] <> pb[i] then
    begin
      Result := False;
      Exit;
    end;
  end;

  Result := True;
end;

function MemFindByte_Scalar(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
var
  pb: PByte;
  i: SizeUInt;
begin
  if (len = 0) or (p = nil) then
  begin
    Result := -1;
    Exit;
  end;

  pb := PByte(p);

  for i := 0 to len - 1 do
  begin
    if pb[i] = value then
    begin
      Result := PtrInt(i);
      Exit;
    end;
  end;

  Result := -1;
end;

function MemDiffRange_Scalar(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
var
  pa, pb: PByte;
  i: SizeUInt;
  foundFirst: Boolean;
begin
  firstDiff := 0;
  lastDiff := 0;

  if len = 0 then
  begin
    Result := False;
    Exit;
  end;

  if (a = nil) or (b = nil) then
  begin
    if a <> b then
    begin
      firstDiff := 0;
      lastDiff := len - 1;
      Result := True;
    end
    else
      Result := False;
    Exit;
  end;

  pa := PByte(a);
  pb := PByte(b);
  foundFirst := False;

  for i := 0 to len - 1 do
  begin
    if pa[i] <> pb[i] then
    begin
      if not foundFirst then
      begin
        firstDiff := i;
        foundFirst := True;
      end;
      lastDiff := i;
    end;
  end;

  Result := foundFirst;
end;

procedure MemCopy_Scalar(src, dst: Pointer; len: SizeUInt);
begin
  if (len = 0) or (src = nil) or (dst = nil) then
    Exit;

  Move(src^, dst^, len);
end;

procedure MemSet_Scalar(dst: Pointer; len: SizeUInt; value: Byte);
begin
  if (len = 0) or (dst = nil) then
    Exit;

  FillChar(dst^, len, value);
end;

procedure MemReverse_Scalar(p: Pointer; len: SizeUInt);
var
  pb: PByte;
  i: SizeUInt;
  temp: Byte;
begin
  if (len <= 1) or (p = nil) then
    Exit;

  pb := PByte(p);

  for i := 0 to (len div 2) - 1 do
  begin
    temp := pb[i];
    pb[i] := pb[len - 1 - i];
    pb[len - 1 - i] := temp;
  end;
end;

// 统计函数
function SumBytes_Scalar(p: Pointer; len: SizeUInt): UInt64;
var
  pb: PByte;
  i: SizeUInt;
begin
  Result := 0;

  if (len = 0) or (p = nil) then
    Exit;

  pb := PByte(p);

  for i := 0 to len - 1 do
    Result := Result + pb[i];
end;

procedure MinMaxBytes_Scalar(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
var
  pb: PByte;
  i: SizeUInt;
begin
  minVal := 255;
  maxVal := 0;

  if (len = 0) or (p = nil) then
    Exit;

  pb := PByte(p);
  minVal := pb[0];
  maxVal := pb[0];

  for i := 1 to len - 1 do
  begin
    if pb[i] < minVal then
      minVal := pb[i];
    if pb[i] > maxVal then
      maxVal := pb[i];
  end;
end;

function CountByte_Scalar(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;
var
  pb: PByte;
  i: SizeUInt;
begin
  Result := 0;

  if (len = 0) or (p = nil) then
    Exit;

  pb := PByte(p);

  for i := 0 to len - 1 do
  begin
    if pb[i] = value then
      Inc(Result);
  end;
end;

// 文本处理函数
function Utf8Validate_Scalar(p: Pointer; len: SizeUInt): Boolean;
var
  pb: PByte;
  i: SizeUInt;
  b: Byte;
  seqLen: Integer;
  j: Integer;
begin
  Result := True;

  if (len = 0) or (p = nil) then
    Exit;

  pb := PByte(p);
  i := 0;

  while i < len do
  begin
    b := pb[i];

    // ASCII (0xxxxxxx)
    if (b and $80) = 0 then
    begin
      Inc(i);
      Continue;
    end;

    // Multi-byte sequence
    if (b and $E0) = $C0 then
      seqLen := 2
    else if (b and $F0) = $E0 then
      seqLen := 3
    else if (b and $F8) = $F0 then
      seqLen := 4
    else
    begin
      Result := False;
      Exit;
    end;

    // Check if we have enough bytes
    if i + seqLen > len then
    begin
      Result := False;
      Exit;
    end;

    // Check continuation bytes
    for j := 1 to seqLen - 1 do
    begin
      if (pb[i + j] and $C0) <> $80 then
      begin
        Result := False;
        Exit;
      end;
    end;

    Inc(i, seqLen);
  end;
end;

function AsciiIEqual_Scalar(a, b: Pointer; len: SizeUInt): Boolean;
var
  pa, pb: PByte;
  i: SizeUInt;
  ca, cb: Byte;
begin
  if len = 0 then
  begin
    Result := True;
    Exit;
  end;

  if (a = nil) or (b = nil) then
  begin
    Result := (a = b);
    Exit;
  end;

  pa := PByte(a);
  pb := PByte(b);

  for i := 0 to len - 1 do
  begin
    ca := pa[i];
    cb := pb[i];

    // Convert to lowercase for comparison
    if (ca >= Ord('A')) and (ca <= Ord('Z')) then
      ca := ca + 32;
    if (cb >= Ord('A')) and (cb <= Ord('Z')) then
      cb := cb + 32;

    if ca <> cb then
    begin
      Result := False;
      Exit;
    end;
  end;

  Result := True;
end;

procedure ToLowerAscii_Scalar(p: Pointer; len: SizeUInt);
var
  pb: PByte;
  i: SizeUInt;
begin
  if (len = 0) or (p = nil) then
    Exit;

  pb := PByte(p);

  for i := 0 to len - 1 do
  begin
    if (pb[i] >= Ord('A')) and (pb[i] <= Ord('Z')) then
      pb[i] := pb[i] + 32;
  end;
end;

procedure ToUpperAscii_Scalar(p: Pointer; len: SizeUInt);
var
  pb: PByte;
  i: SizeUInt;
begin
  if (len = 0) or (p = nil) then
    Exit;

  pb := PByte(p);

  for i := 0 to len - 1 do
  begin
    if (pb[i] >= Ord('a')) and (pb[i] <= Ord('z')) then
      pb[i] := pb[i] - 32;
  end;
end;

// 搜索函数
function BytesIndexOf_Scalar(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;
var
  ph, pn: PByte;
  i, j: SizeUInt;
  found: Boolean;
begin
  Result := -1;

  if (haystackLen = 0) or (needleLen = 0) or (haystack = nil) or (needle = nil) then
    Exit;

  if needleLen > haystackLen then
    Exit;

  ph := PByte(haystack);
  pn := PByte(needle);

  for i := 0 to haystackLen - needleLen do
  begin
    found := True;
    for j := 0 to needleLen - 1 do
    begin
      if ph[i + j] <> pn[j] then
      begin
        found := False;
        Break;
      end;
    end;

    if found then
    begin
      Result := PtrInt(i);
      Exit;
    end;
  end;
end;

// 位集函数
function BitsetPopCount_Scalar(p: Pointer; byteLen: SizeUInt): SizeUInt;
var
  pb: PByte;
  i: SizeUInt;
  b: Byte;
  count: Integer;
begin
  Result := 0;

  if (byteLen = 0) or (p = nil) then
    Exit;

  pb := PByte(p);

  for i := 0 to byteLen - 1 do
  begin
    b := pb[i];
    count := 0;

    // Count bits in byte
    while b <> 0 do
    begin
      if (b and 1) <> 0 then
        Inc(count);
      b := b shr 1;
    end;

    Result := Result + SizeUInt(count);
  end;
end;

initialization
  // Register scalar backend on unit initialization
  RegisterScalarBackend;

end.

