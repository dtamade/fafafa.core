// =============================================================
// Missing Scalar Fallbacks for ASM-only functions
// =============================================================

function RISCVVAddU64x2(const a, b: TVecU64x2): TVecU64x2;
begin
  Result := ScalarAddU64x2(a, b);
end;

function RISCVVSubU64x2(const a, b: TVecU64x2): TVecU64x2;
begin
  Result := ScalarSubU64x2(a, b);
end;

function RISCVVAndU64x2(const a, b: TVecU64x2): TVecU64x2;
begin
  Result := ScalarAndU64x2(a, b);
end;

function RISCVVOrU64x2(const a, b: TVecU64x2): TVecU64x2;
begin
  Result := ScalarOrU64x2(a, b);
end;

function RISCVVXorU64x2(const a, b: TVecU64x2): TVecU64x2;
begin
  Result := ScalarXorU64x2(a, b);
end;

function RISCVVNotU64x2(const a: TVecU64x2): TVecU64x2;
begin
  Result := ScalarNotU64x2(a);
end;

function RISCVVCmpNeU32x4(const a, b: TVecU32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] <> b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVShiftLeftI64x2(const a: TVecI64x2; shift: Integer): TVecI64x2;
begin
  Result := ScalarShiftLeftI64x2(a, shift);
end;

function RISCVVShiftRightI64x2(const a: TVecI64x2; shift: Integer): TVecI64x2;
begin
  Result := ScalarShiftRightI64x2(a, shift);
end;

function RISCVVShiftRightArithI64x2(const a: TVecI64x2; shift: Integer): TVecI64x2;
begin
  Result := ScalarShiftRightArithI64x2(a, shift);
end;

function RISCVVShiftRightArithI64x4(const a: TVecI64x4; shift: Integer): TVecI64x4;
begin
  Result := ScalarShiftRightArithI64x4(a, shift);
end;

{$IFNDEF RISCVV_ASSEMBLY}

function RISCVVAndNotI8x16(const a, b: TVecI8x16): TVecI8x16;
begin
  Result := ScalarAndNotI8x16(a, b);
end;

function RISCVVAndNotU16x8(const a, b: TVecU16x8): TVecU16x8;
begin
  Result := ScalarAndNotU16x8(a, b);
end;

function RISCVVAndNotU8x16(const a, b: TVecU8x16): TVecU8x16;
begin
  Result := ScalarAndNotU8x16(a, b);
end;

{$ENDIF}
