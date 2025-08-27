program minitest_search_neon;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd,
  fafafa.core.simd.search;

procedure AssertTrue(cond: Boolean; const msg: string);
begin
  if not cond then begin Writeln('FAIL: ', msg); Halt(1); end;
end;

procedure FillRandom(var a: TBytes);
begin
  for var i:=0 to High(a) do a[i] := Random(256);
end;

procedure TestSearch_NEON_Direct;
{$IFDEF CPUAARCH64}
var
  hay, ned: TBytes;
  pos, idx, len, nlen: Integer;
begin
  Randomize;
  // case 1: mid hit, nlen=20
  len := 4096; nlen := 20;
  SetLength(hay, len); SetLength(ned, nlen);
  FillRandom(hay); FillRandom(ned);
  pos := 1234; Move(ned[0], hay[pos], nlen);
  idx := BytesIndexOf_NEON(@hay[0], len, @ned[0], nlen);
  AssertTrue(idx = pos, 'NEON direct: mid hit nlen=20');
  // case 2: no hit
  hay[pos] := hay[pos] xor $7F; // break
  idx := BytesIndexOf_NEON(@hay[0], len, @ned[0], nlen);
  AssertTrue(idx = -1, 'NEON direct: no hit');
  // case 3: pos=0, nlen=1
  len := 128; nlen := 1; SetLength(hay, len); FillRandom(hay);
  ned := TBytes(#1); hay[0] := ned[0];
  idx := BytesIndexOf_NEON(@hay[0], len, @ned[0], nlen);
  AssertTrue(idx = 0, 'NEON direct: head, nlen=1');
  // case 4: tail hit, nlen=33
  len := 1024; nlen := 33; SetLength(hay, len); SetLength(ned, nlen);
  FillRandom(hay); FillRandom(ned);
  pos := len - nlen; Move(ned[0], hay[pos], nlen);
  idx := BytesIndexOf_NEON(@hay[0], len, @ned[0], nlen);
  AssertTrue(idx = pos, 'NEON direct: tail, nlen=33');
end;
{$ELSE}
begin
  Writeln('SKIP: CPU is not AArch64.');
end;
{$ENDIF}

procedure TestSearch_Facade;
var
  hay, ned: TBytes;
  pos, idx, len, nlen: Integer;
begin
  Randomize;
  len := 2048; nlen := 16;
  SetLength(hay, len); SetLength(ned, nlen);
  FillRandom(hay); FillRandom(ned);
  pos := 777; Move(ned[0], hay[pos], nlen);
  idx := BytesIndexOf(@hay[0], len, @ned[0], nlen);
  AssertTrue(idx = pos, 'facade: mid hit');
  // no hit
  hay[pos] := hay[pos] xor $55;
  idx := BytesIndexOf(@hay[0], len, @ned[0], nlen);
  AssertTrue(idx = -1, 'facade: no hit');
end;

begin
  Writeln('Profile = ', SimdInfo);
  TestSearch_NEON_Direct;
  TestSearch_Facade;
  Writeln('OK: minitest_search_neon passed.');
end.

