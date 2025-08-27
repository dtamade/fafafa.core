program minitest_search;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd,
  fafafa.core.simd.types;

procedure AssertTrue(cond: Boolean; const msg: string);
begin
  if not cond then begin Writeln('FAIL: ', msg); Halt(1); end;
end;

procedure TestIndexOfBasic;
var
  hay, ned: TBytes; idx: PtrInt;
begin
  SetLength(hay, 11);
  Move(PAnsiChar(AnsiString('hello world'))^, hay[0], 11);
  SetLength(ned, 5);
  Move(PAnsiChar(AnsiString('world'))^, ned[0], 5);
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  Writeln('Debug IndexOf basic idx=', idx);
  AssertTrue(idx = 6, 'IndexOf basic');
end;

procedure TestIndexOfEdges;
var
  hay, ned: TBytes; idx: PtrInt;
begin
  // empty needle
  SetLength(hay, 6);
  Move(PAnsiChar(AnsiString('abcdef'))^, hay[0], 6);
  SetLength(ned, 0);
  idx := BytesIndexOf(@hay[0], Length(hay), nil, 0);
  AssertTrue(idx = 0, 'IndexOf empty needle');
  // needle longer than hay
  SetLength(hay, 3);
  Move(PAnsiChar(AnsiString('abc'))^, hay[0], 3);
  SetLength(ned, 4);
  Move(PAnsiChar(AnsiString('abcd'))^, ned[0], 4);
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue(idx = -1, 'IndexOf needle>hay');
end;

procedure TestIndexOfRandom;
var
  hay, ned: TBytes; idx: PtrInt; pos: Integer; len: Integer; i: Integer;
begin
  Randomize;
  len := 4096;
  SetLength(hay, len);

  for i:=0 to len-1 do hay[i] := Random(256);
  SetLength(ned, 8);
  for i:=0 to 7 do ned[i] := Random(256);
  // splice needle at known position
  pos := 1234; Move(ned[0], hay[pos], Length(ned));
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue(idx = pos, 'IndexOf random placed needle');
end;

begin
  TestIndexOfBasic;
  TestIndexOfEdges;
  TestIndexOfRandom;
  Writeln('OK: minitest_search passed.');
end.

