program minitest_search_avx2;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd,
  fafafa.core.simd.search;

procedure AssertEqI(const name: string; a, b: PtrInt);
begin
  if a<>b then begin
    Writeln('FAIL ', name, ': ', a, ' <> ', b);
    Halt(1);
  end;
end;

procedure Run;
var
  prof: string;
  hay: array[0..255] of Byte;
  ned: array[0..63] of Byte;
  i, idxS, idxA: PtrInt;
begin
  prof := SimdInfo;
  if Pos('AVX2', prof) = 0 then begin
    Writeln('SKIP: profile=', prof);
    Exit;
  end;
  Writeln('CASE: short');
  FillChar(hay, SizeOf(hay), Ord('x'));
  Move(PAnsiChar(AnsiString('hello world'))^, hay[0], 11);
  FillChar(ned, SizeOf(ned), 0);
  Move(PAnsiChar(AnsiString('world'))^, ned[0], 5);
  idxS := BytesIndexOf_SSE2(@hay[0], 11, @ned[0], 5);
  idxA := BytesIndexOf_AVX2(@hay[0], 11, @ned[0], 5);
  Writeln('  idxS=', idxS, ' idxA=', idxA);
  AssertEqI('short', idxS, idxA);
  Writeln('CASE: mid');
  FillChar(hay, SizeOf(hay), Ord('a'));
  for i:=0 to 199 do hay[i] := Ord('a');
  Move(PAnsiChar(AnsiString('zzzABCDEFzzz'))^, hay[120], 12);
  FillChar(ned, SizeOf(ned), 0);
  Move(PAnsiChar(AnsiString('ABCDEF'))^, ned[0], 6);
  idxS := BytesIndexOf_SSE2(@hay[0], 200, @ned[0], 6);
  idxA := BytesIndexOf_AVX2(@hay[0], 200, @ned[0], 6);
  Writeln('  idxS=', idxS, ' idxA=', idxA);
  AssertEqI('mid', idxS, idxA);
  Writeln('CASE: unaligned+repeat');
  FillChar(hay, SizeOf(hay), Ord('b'));
  for i:=0 to 199 do hay[i] := Ord('b');
  Move(PAnsiChar(AnsiString('cccccccccccccccxyz'))^, hay[33], 18);
  FillChar(ned, SizeOf(ned), 0);
  Move(PAnsiChar(AnsiString('cccccxyz'))^, ned[0], 8);
  idxS := BytesIndexOf_SSE2(@hay[1], 230, @ned[0], 8);
  idxA := BytesIndexOf_AVX2(@hay[1], 230, @ned[0], 8);
  Writeln('  idxS=', idxS, ' idxA=', idxA);
  AssertEqI('unaligned+repeat', idxS, idxA);
  Writeln('CASE: len16');
  FillChar(hay, SizeOf(hay), Ord('q'));
  Move(PAnsiChar(AnsiString('0123456789abcdef'))^, hay[40], 16);
  Move(PAnsiChar(AnsiString('0123456789abcdef'))^, ned[0], 16);
  idxS := BytesIndexOf_SSE2(@hay[0], 200, @ned[0], 16);
  idxA := BytesIndexOf_AVX2(@hay[0], 200, @ned[0], 16);
  Writeln('  idxS=', idxS, ' idxA=', idxA);
  AssertEqI('len16', idxS, idxA);
  Writeln('CASE: len32');
  FillChar(hay, SizeOf(hay), Ord('q'));
  Move(PAnsiChar(AnsiString('0123456789abcdef0123456789abcdef'))^, hay[64], 32);
  Move(PAnsiChar(AnsiString('0123456789abcdef0123456789abcdef'))^, ned[0], 32);
  idxS := BytesIndexOf_SSE2(@hay[0], 220, @ned[0], 32);
  idxA := BytesIndexOf_AVX2(@hay[0], 220, @ned[0], 32);
  Writeln('  idxS=', idxS, ' idxA=', idxA);
  AssertEqI('len32', idxS, idxA);
  Writeln('CASE: len32-unaligned');
  FillChar(hay, SizeOf(hay), Ord('q'));
  Move(PAnsiChar(AnsiString('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'))^, hay[5], 32);
  Move(PAnsiChar(AnsiString('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'))^, hay[45], 32);
  Move(PAnsiChar(AnsiString('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'))^, ned[0], 32);
  idxS := BytesIndexOf_SSE2(@hay[1], 120, @ned[0], 32);
  idxA := BytesIndexOf_AVX2(@hay[1], 120, @ned[0], 32);
  Writeln('  idxS=', idxS, ' idxA=', idxA);
  AssertEqI('len32-unaligned', idxS, idxA);
  Writeln('CASE: notfound');
  FillChar(hay, SizeOf(hay), Ord('m'));
  Move(PAnsiChar(AnsiString('xyzxyzxyzxyz'))^, ned[0], 12);
  idxS := BytesIndexOf_SSE2(@hay[0], 180, @ned[0], 12);
  idxA := BytesIndexOf_AVX2(@hay[0], 180, @ned[0], 12);
  Writeln('  idxS=', idxS, ' idxA=', idxA);
  AssertEqI('notfound', idxS, idxA);

  Writeln('OK: minitest_search_avx2');
end;

begin
  try
    Run;
  except
    on E: Exception do begin
      Writeln('EXCEPTION: ', E.ClassName, ': ', E.Message);
      Halt(2);
    end;
  end;
end.

