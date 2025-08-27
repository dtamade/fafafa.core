program consistency_simd;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd;

procedure Fail(const msg: string);
begin
  Writeln('FAIL: ', msg);
  Halt(1);
end;

procedure GenData(out a,b: TBytes; len: Integer);
begin
  SetLength(a, len); SetLength(b, len);
  for var i:=0 to len-1 do begin a[i] := Random(256); b[i] := a[i]; end;
  // introduce two diffs
  if len>0 then b[0] := b[0] xor $11;
  if len>1 then b[len-1] := b[len-1] xor $22;
end;

function RunAllAndHash(const a,b: TBytes): QWord;
var
  h: QWord = 1469598103934665603; // FNV-1a basis (64-bit)
  rBool: Boolean;
  rIdx: PtrInt;
  rRange: TDiffRange;
  bytes: array[0..3] of Byte = ($FF,$0F,$55,$80);
  bits: SizeUInt = 29;
begin
  // MemEqual
  rBool := MemEqual(@a[0], @b[0], Length(a));
  h := (h xor Ord(rBool)) * 1099511628211;
  // MemFindByte
  rIdx := MemFindByte(@a[0], Length(a), a[Length(a) div 2]);
  h := (h xor QWord(PtrUInt(rIdx))) * 1099511628211;
  // MemDiffRange
  rRange := MemDiffRange(@a[0], @b[0], Length(a));
  h := (h xor QWord(Cardinal(rRange.First))) * 1099511628211;
  h := (h xor QWord(Cardinal(rRange.Last))) * 1099511628211;
  // Utf8Validate (ASCII)
  var ascii: array[0..31] of Byte; FillByte(ascii, SizeOf(ascii), Ord('A'));
  rBool := Utf8Validate(@ascii[0], 32);
  h := (h xor Ord(rBool)) * 1099511628211;
  // BitsetPopCount
  var pc := BitsetPopCount(@bytes[0], bits);
  h := (h xor QWord(pc)) * 1099511628211;
  Result := h;
end;

procedure CheckConsistency;
var
  a,b: TBytes; hScalar,hSSE2,hAVX2: QWord;
  hasSSE2, hasAVX2: Boolean;
  prof: string;
begin
  Writeln('Base Profile = ', SimdInfo);
  GenData(a,b, 1024*3+7);

  // SCALAR
  SimdSetForcedProfile('SCALAR'); prof := SimdInfo; Writeln('Using ', prof);
  hScalar := RunAllAndHash(a,b);

  // SSE2
  SimdSetForcedProfile('SSE2'); prof := SimdInfo; hasSSE2 := Pos('SSE2', prof)>0; Writeln('Using ', prof);
  if hasSSE2 then begin
    hSSE2 := RunAllAndHash(a,b);
    if hSSE2<>hScalar then Fail('SSE2 != SCALAR');
  end else Writeln('Skip SSE2 (unavailable)');

  // AVX2
  SimdSetForcedProfile('AVX2'); prof := SimdInfo; hasAVX2 := Pos('AVX2', prof)>0; Writeln('Using ', prof);
  if hasAVX2 then begin
    hAVX2 := RunAllAndHash(a,b);
    if hAVX2<>hScalar then Fail('AVX2 != SCALAR');
  end else Writeln('Skip AVX2 (unavailable)');

  Writeln('OK: SIMD consistency check passed.');
end;

begin
  Randomize;
  try
    CheckConsistency;
  except
    on E: Exception do begin Writeln('EXCEPTION: ', E.Message); Halt(2); end;
  end;
end.

