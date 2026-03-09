// =============================================================
// Missing Scalar Fallbacks for ASM-only functions
// =============================================================

function RISCVVNegF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := -a.f[i];
end;

function RISCVVNegF64x2(const a: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := -a.d[i];
end;

function RISCVVAddU64x2(const a, b: TVecU64x2): TVecU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.u[i] := a.u[i] + b.u[i];
end;

function RISCVVSubU64x2(const a, b: TVecU64x2): TVecU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.u[i] := a.u[i] - b.u[i];
end;

function RISCVVAndU64x2(const a, b: TVecU64x2): TVecU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.u[i] := a.u[i] and b.u[i];
end;

function RISCVVOrU64x2(const a, b: TVecU64x2): TVecU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.u[i] := a.u[i] or b.u[i];
end;

function RISCVVXorU64x2(const a, b: TVecU64x2): TVecU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.u[i] := a.u[i] xor b.u[i];
end;

function RISCVVNotU64x2(const a: TVecU64x2): TVecU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.u[i] := not a.u[i];
end;

function RISCVVAndNotI64x2(const a, b: TVecI64x2): TVecI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.i[i] := (not a.i[i]) and b.i[i];
end;

function RISCVVMinI64x2(const a, b: TVecI64x2): TVecI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    if a.i[i] < b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVMaxI64x2(const a, b: TVecI64x2): TVecI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    if a.i[i] > b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVAndNotU64x2(const a, b: TVecU64x2): TVecU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.u[i] := (not a.u[i]) and b.u[i];
end;

function RISCVVCmpEqU64x2(const a, b: TVecU64x2): TMask2;
begin
  Result := 0;
  if a.u[0] = b.u[0] then Result := Result or 1;
  if a.u[1] = b.u[1] then Result := Result or 2;
end;

function RISCVVCmpLtU64x2(const a, b: TVecU64x2): TMask2;
const
  SIGN_MASK: QWord = QWord($8000000000000000);
var
  LAdjustedA, LAdjustedB: TVecI64x2;
begin
  LAdjustedA.i[0] := Int64(a.u[0] xor SIGN_MASK);
  LAdjustedA.i[1] := Int64(a.u[1] xor SIGN_MASK);
  LAdjustedB.i[0] := Int64(b.u[0] xor SIGN_MASK);
  LAdjustedB.i[1] := Int64(b.u[1] xor SIGN_MASK);
  Result := RISCVVCmpLtI64x2(LAdjustedA, LAdjustedB);
end;

function RISCVVCmpGtU64x2(const a, b: TVecU64x2): TMask2;
const
  SIGN_MASK: QWord = QWord($8000000000000000);
var
  LAdjustedA, LAdjustedB: TVecI64x2;
begin
  LAdjustedA.i[0] := Int64(a.u[0] xor SIGN_MASK);
  LAdjustedA.i[1] := Int64(a.u[1] xor SIGN_MASK);
  LAdjustedB.i[0] := Int64(b.u[0] xor SIGN_MASK);
  LAdjustedB.i[1] := Int64(b.u[1] xor SIGN_MASK);
  Result := RISCVVCmpGtI64x2(LAdjustedA, LAdjustedB);
end;

function RISCVVMinU64x2(const a, b: TVecU64x2): TVecU64x2;
var
  LMask: TMask2;
begin
  LMask := RISCVVCmpLtU64x2(a, b);
  if (LMask and 1) <> 0 then Result.u[0] := a.u[0] else Result.u[0] := b.u[0];
  if (LMask and 2) <> 0 then Result.u[1] := a.u[1] else Result.u[1] := b.u[1];
end;

function RISCVVMaxU64x2(const a, b: TVecU64x2): TVecU64x2;
var
  LMask: TMask2;
begin
  LMask := RISCVVCmpGtU64x2(a, b);
  if (LMask and 1) <> 0 then Result.u[0] := a.u[0] else Result.u[0] := b.u[0];
  if (LMask and 2) <> 0 then Result.u[1] := a.u[1] else Result.u[1] := b.u[1];
end;

function RISCVVCmpNeU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.u[i] <> b.u[i] then
      Result.u[i] := $FFFFFFFF
    else
      Result.u[i] := 0;
end;

function RISCVVLoadI32x4(p: Pointer): TVecI32x4;
type
  PLocalVecI32x4 = ^TVecI32x4;
begin
  Result := PLocalVecI32x4(p)^;
end;

function RISCVVLoadI64x2(p: Pointer): TVecI64x2;
type
  PLocalVecI64x2 = ^TVecI64x2;
begin
  Result := PLocalVecI64x2(p)^;
end;

procedure RISCVVStoreI32x4(p: Pointer; const a: TVecI32x4);
type
  PLocalVecI32x4 = ^TVecI32x4;
begin
  PLocalVecI32x4(p)^ := a;
end;

procedure RISCVVStoreI64x2(p: Pointer; const a: TVecI64x2);
type
  PLocalVecI64x2 = ^TVecI64x2;
begin
  PLocalVecI64x2(p)^ := a;
end;

function RISCVVSplatI32x4(value: Int32): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := value;
end;

function RISCVVSplatI64x2(value: Int64): TVecI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.i[i] := value;
end;

function RISCVVZeroI32x4: TVecI32x4;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function RISCVVZeroI64x2: TVecI64x2;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function RISCVVShiftLeftI64x2(const a: TVecI64x2; shift: Integer): TVecI64x2;
var i: Integer;
begin
  if (shift < 0) or (shift >= 64) then
  begin
    for i := 0 to 1 do
      Result.i[i] := 0;
    Exit;
  end;

  for i := 0 to 1 do
    Result.i[i] := a.i[i] shl shift;
end;

function RISCVVShiftRightI64x2(const a: TVecI64x2; shift: Integer): TVecI64x2;
var i: Integer;
begin
  if (shift < 0) or (shift >= 64) then
  begin
    for i := 0 to 1 do
      Result.i[i] := 0;
    Exit;
  end;

  for i := 0 to 1 do
    Result.i[i] := Int64(QWord(a.i[i]) shr shift);
end;

function RISCVVShiftRightArithI64x2(const a: TVecI64x2; shift: Integer): TVecI64x2;
var i: Integer;
begin
  if (shift < 0) or (shift >= 64) then
  begin
    for i := 0 to 1 do
      Result.i[i] := 0;
    Exit;
  end;

  for i := 0 to 1 do
    Result.i[i] := SarInt64(a.i[i], shift);
end;

function RISCVVShiftRightArithI64x4(const a: TVecI64x4; shift: Integer): TVecI64x4;
var i: Integer;
begin
  if (shift < 0) or (shift >= 64) then
  begin
    for i := 0 to 3 do
      Result.i[i] := 0;
    Exit;
  end;

  for i := 0 to 3 do
    Result.i[i] := SarInt64(a.i[i], shift);
end;

function RISCVVShiftLeftU64x2(const a: TVecU64x2; shift: Integer): TVecU64x2;
var i: Integer;
begin
  if (shift < 0) or (shift >= 64) then
  begin
    for i := 0 to 1 do
      Result.u[i] := 0;
    Exit;
  end;

  for i := 0 to 1 do
    Result.u[i] := a.u[i] shl shift;
end;

function RISCVVShiftRightU64x2(const a: TVecU64x2; shift: Integer): TVecU64x2;
var i: Integer;
begin
  if (shift < 0) or (shift >= 64) then
  begin
    for i := 0 to 1 do
      Result.u[i] := 0;
    Exit;
  end;

  for i := 0 to 1 do
    Result.u[i] := a.u[i] shr shift;
end;

function RISCVVReduceAddI32x4(const a: TVecI32x4): Int32;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    Result := Result + a.i[i];
end;

function RISCVVReduceMinI32x4(const a: TVecI32x4): Int32;
var i: Integer;
begin
  Result := a.i[0];
  for i := 1 to 3 do
    if a.i[i] < Result then
      Result := a.i[i];
end;

function RISCVVReduceMaxI32x4(const a: TVecI32x4): Int32;
var i: Integer;
begin
  Result := a.i[0];
  for i := 1 to 3 do
    if a.i[i] > Result then
      Result := a.i[i];
end;

function RISCVVReduceMinU32x4(const a: TVecU32x4): UInt32;
var i: Integer;
begin
  Result := a.u[0];
  for i := 1 to 3 do
    if a.u[i] < Result then
      Result := a.u[i];
end;

function RISCVVReduceMaxU32x4(const a: TVecU32x4): UInt32;
var i: Integer;
begin
  Result := a.u[0];
  for i := 1 to 3 do
    if a.u[i] > Result then
      Result := a.u[i];
end;

function RISCVVSelectI64x2(const mask: TMask2; const a, b: TVecI64x2): TVecI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    if (mask and (1 shl i)) <> 0 then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVSelectI32x8(const mask: TMask8; const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if (mask and (1 shl i)) <> 0 then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVSelectI32x16(const mask: TMask16; const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if (mask and (1 shl i)) <> 0 then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

{$ENDIF} // RISCVV_ASSEMBLY

