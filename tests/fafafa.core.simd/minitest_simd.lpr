program minitest_simd;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd;

function PtrOrNil(var a: TBytes): Pointer;
begin
  if Length(a) = 0 then Exit(nil);
  Result := @a[0];
end;

function CountBits(const p: PByte; bitLen: SizeUInt): SizeUInt;
var
  i: SizeUInt;
  pb: PByte;
  acc: SizeUInt;
begin
  if bitLen = 0 then Exit(0);
  pb := p;
  acc := 0;
  for i := 0 to bitLen-1 do
  begin
    if ((pb[i div 8] shr (i and 7)) and 1) <> 0 then Inc(acc);
  end;
  Result := acc;
end;

procedure AssertTrue(cond: Boolean; const msg: string);
begin
  if not cond then
  begin
    Writeln('FAIL: ', msg);
    Halt(1);
  end;
end;

procedure TestMemEqual;
var
  a,b: TBytes;
  i: Integer;
begin
  Writeln('SIMD Profile = ', SimdInfo);
  // len=0
  SetLength(a, 0); SetLength(b, 0);
  AssertTrue(MemEqual(nil, nil, 0), 'MemEqual len=0');
  // identical
  SetLength(a, 100); SetLength(b, 100);
  Randomize;
  for i:=0 to High(a) do begin a[i] := Random(256); b[i] := a[i]; end;
  AssertTrue(MemEqual(@a[0], @b[0], Length(a)), 'MemEqual identical');
  // different
  b[42] := b[42] xor $FF;
  AssertTrue(not MemEqual(@a[0], @b[0], Length(a)), 'MemEqual diff');
end;

procedure TestMemFindByte;
var
  a: TBytes;
  idx: PtrInt;
  i: Integer;
begin
  SetLength(a, 64);
  {$ifdef FPC_HAS_FEATURE_INLINEVAR}
  var i: Integer;
  {$endif}
  for i:=0 to High(a) do a[i] := $AA;
  a[10] := $7F;
  idx := MemFindByte(@a[0], Length(a), $7F);
  AssertTrue(idx = 10, 'MemFindByte hit index');
  idx := MemFindByte(@a[0], Length(a), $EE);
  AssertTrue(idx = -1, 'MemFindByte miss');
end;

procedure TestMemDiffRange;
var
  a,b: TBytes;
  r: TDiffRange;
  i: Integer;
begin
  SetLength(a, 64); SetLength(b, 64);
  {$ifdef FPC_HAS_FEATURE_INLINEVAR}
  var i: Integer;
  {$endif}
  for i:=0 to High(a) do begin a[i] := Random(256); b[i] := a[i]; end;
  r := MemDiffRange(@a[0], @b[0], Length(a));
  AssertTrue((r.First = -1) and (r.Last = -1), 'MemDiffRange equal');
  b[0] := b[0] xor 1; b[High(b)] := b[High(b)] xor 1;
  r := MemDiffRange(@a[0], @b[0], Length(a));
  AssertTrue((r.First = 0) and (r.Last = High(a)), 'MemDiffRange first/last');
end;

procedure TestBitsetPopCount;
var
  bytes: array[0..4] of Byte;
  bits: SizeUInt;
  got, expect: SizeUInt;
begin
  // 37 bits across 5 bytes
  bytes[0] := $FF; bytes[1] := $0F; bytes[2] := $55; bytes[3] := $80; bytes[4] := $7F;
  bits := 37;
  expect := CountBits(@bytes[0], bits);
  got := BitsetPopCount(@bytes[0], bits);
  Writeln('Debug Bitset: expect=', expect, ' got=', got);
  AssertTrue(got = expect, Format('BitsetPopCount expected=%d got=%d [dbg]', [PtrUInt(expect), PtrUInt(got)]));
end;

procedure TestUtf8Validate;
var
  ascii: array[0..10] of Byte = (Ord('H'),Ord('e'),Ord('l'),Ord('l'),Ord('o'),Ord(' '),Ord('1'),Ord('2'),Ord('3'),Ord('!'),0);
  utf2: array[0..2] of Byte = ($C3,$A9, 0);            // "é\0" (2-byte)
  utf3: array[0..3] of Byte = ($E2,$82,$AC, 0);        // "€\0" (3-byte)
  utf4: array[0..5] of Byte = ($F0,$9F,$98,$80, 0, 0); // "😀\0" (4-byte + pad)
  inv_lone: array[0..0] of Byte = ($80);               // lone continuation
  inv_trunc2: array[0..0] of Byte = ($C2);             // truncated 2-byte lead
  inv_trunc3: array[0..1] of Byte = ($E2,$82);         // truncated 3-byte lead
  inv_wrongcont: array[0..1] of Byte = ($C2,$20);      // wrong continuation
begin
  AssertTrue(Utf8Validate(@ascii[0], 10), 'Utf8Validate ASCII');
  AssertTrue(Utf8Validate(@utf2[0], 2), 'Utf8Validate 2-byte valid');
  AssertTrue(Utf8Validate(@utf3[0], 3), 'Utf8Validate 3-byte valid');
  AssertTrue(Utf8Validate(@utf4[0], 4), 'Utf8Validate 4-byte valid');
  AssertTrue(not Utf8Validate(@inv_lone[0], 1), 'Utf8Validate invalid lone cont');
  AssertTrue(not Utf8Validate(@inv_trunc2[0], 1), 'Utf8Validate invalid trunc 2');
  AssertTrue(not Utf8Validate(@inv_trunc3[0], 2), 'Utf8Validate invalid trunc 3');
  AssertTrue(not Utf8Validate(@inv_wrongcont[0], 2), 'Utf8Validate invalid wrong cont');
end;

begin
  try
    Writeln('Running: TestMemEqual');
    TestMemEqual;
    Writeln('Running: TestMemFindByte');
    TestMemFindByte;
    Writeln('Running: TestMemDiffRange');
    TestMemDiffRange;
    Writeln('Running: TestBitsetPopCount');
    TestBitsetPopCount;
    Writeln('Running: TestUtf8Validate');
    TestUtf8Validate;
    Writeln('OK: all SIMD minitests passed.');
  except
    on E: Exception do begin
      Writeln('EXCEPTION: ', E.ClassName, ': ', E.Message);
      Halt(2);
    end;
  end;
end.

