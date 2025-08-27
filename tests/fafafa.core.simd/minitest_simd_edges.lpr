program minitest_simd_edges;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd,
  fafafa.core.simd.types;

procedure AssertTrue(cond: Boolean; const msg: string);
begin
  if not cond then
  begin
    Writeln('FAIL: ', msg);
    Halt(1);
  end;
end;

procedure TestUnaligned_MemEqual_FindByte;
var
  a,b: TBytes;
  off, len: Integer;
  idx: PtrInt;
  pa,pb: PByte;
  i: Integer;
begin
  Randomize;
  len := 128 + 37;
  SetLength(a, len+32);
  SetLength(b, len+32);
  for off := 0 to 15 do
  begin
    Writeln('DBG off=', off, ' init');
    // prepare identical slices (deterministic, ensure no $7E before target)
    for i:=0 to len-1 do begin a[off+i] := 0; b[off+i] := 0; end;
    pa := @a[off]; pb := @b[off];
    Writeln('DBG off=', off, ' memeq-eq');
    AssertTrue(MemEqual(pa, pb, len), Format('Unaligned MemEqual off=%d equal', [off]));
    // make a diff at begin/mid/end
    Writeln('DBG off=', off, ' memeq-begin');
    b[off] := b[off] xor $01; AssertTrue(not MemEqual(pa, pb, len), Format('Unaligned MemEqual off=%d diff-begin', [off])); b[off] := a[off];
    Writeln('DBG off=', off, ' memeq-mid');
    b[off+len div 2] := b[off+len div 2] xor $01; AssertTrue(not MemEqual(pa, pb, len), Format('Unaligned MemEqual off=%d diff-mid', [off])); b[off+len div 2] := a[off+len div 2];
    Writeln('DBG off=', off, ' memeq-end');
    b[off+len-1] := b[off+len-1] xor $01; AssertTrue(not MemEqual(pa, pb, len), Format('Unaligned MemEqual off=%d diff-end', [off])); b[off+len-1] := a[off+len-1];
    // find byte
    Writeln('DBG off=', off, ' find');
    a[off+73] := $7E; b[off+73] := $7E;
    idx := MemFindByte(pa, len, $7E);
    Writeln('DBG off=', off, ' idx=', idx);
    AssertTrue(idx = 73, Format('Unaligned MemFindByte off=%d idx=%d', [off, idx]));
  end;
end;

procedure TestUnaligned_MemDiffRange;
var
  a,b: TBytes; off,len: Integer; r: TDiffRange; i: Integer;
begin
  len := 160;
  SetLength(a, len+32);
  SetLength(b, len+32);
  for off := 0 to 15 do
  begin
    for i:=0 to len-1 do begin a[off+i] := i and $FF; b[off+i] := a[off+i]; end;
    // equal
    Writeln('DBG diff off=', off, ' len=', len, ' eq-call');
    r := MemDiffRange(@a[off], @b[off], len);
    Writeln('DBG diff off=', off, ' eq-ret First=', r.First, ' Last=', r.Last);
    AssertTrue((r.First=-1) and (r.Last=-1), Format('Unaligned DiffRange equal off=%d', [off]));
    // change first and last
    b[off] := b[off] xor $FF; b[off+len-1] := b[off+len-1] xor $0F;
    Writeln('DBG diff off=', off, ' len=', len, ' bounds-call');
    r := MemDiffRange(@a[off], @b[off], len);
    Writeln('DBG diff off=', off, ' bounds-ret First=', r.First, ' Last=', r.Last);
    AssertTrue((r.First=0) and (r.Last=len-1), Format('Unaligned DiffRange bounds off=%d got=(%d,%d)', [off, r.First, r.Last]));
  end;
end;

procedure TestUtf8Validate_Mixed;
var
  // ASCII + 2-byte UTF-8 + ASCII
  data: array[0..7] of Byte = (Ord('A'), Ord('B'), $C3, $A9, Ord('X'), Ord('Y'), Ord('Z'), 0);
  invalid: array[0..2] of Byte = (Ord('A'), $80, 0);
begin
  AssertTrue(Utf8Validate(@data[0], 7), 'Utf8Validate mixed ASCII+UTF8');
  AssertTrue(not Utf8Validate(@invalid[0], 2), 'Utf8Validate invalid continuation in middle');
end;

begin
  Writeln('SIMD Profile = ', SimdInfo);
  TestUnaligned_MemEqual_FindByte;
  TestUnaligned_MemDiffRange;
  TestUtf8Validate_Mixed;
  Writeln('OK: all SIMD edge tests passed.');
end.

