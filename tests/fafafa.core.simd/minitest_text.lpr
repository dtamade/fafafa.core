program minitest_text;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd;

procedure AssertTrue(cond: Boolean; const msg: string);
begin
  if not cond then begin Writeln('FAIL: ', msg); Halt(1); end;
end;

function BytesToString(const b: TBytes): string;
var i: Integer;
begin
  SetLength(Result, Length(b));
  for i:=1 to Length(b) do Result[i] := Chr(b[i-1]);
end;

procedure ToLowerRef(p: PByte; len: SizeUInt);
var i: SizeUInt;
begin
  for i:=0 to len-1 do
  begin
    if (p[i] >= Ord('A')) and (p[i] <= Ord('Z')) then p[i] := p[i] + 32;
  end;
end;

procedure ToUpperRef(p: PByte; len: SizeUInt);
var i: SizeUInt;
begin
  for i:=0 to len-1 do
  begin
    if (p[i] >= Ord('a')) and (p[i] <= Ord('z')) then p[i] := p[i] - 32;
  end;
end;

procedure TestBasic;
var
  s: AnsiString;
  a, b: TBytes;
begin
  s := 'AbC xyz @[`{ 0129';
  SetLength(a, Length(s)); Move(PAnsiChar(s)^, a[0], Length(s));
  SetLength(b, Length(a)); Move(a[0], b[0], Length(a));
  ToLowerAscii(@a[0], Length(a));
  ToLowerRef(@b[0], Length(b));
  AssertTrue(CompareByte(a[0], b[0], Length(a))=0, 'ToLowerAscii basic');

  SetLength(a, Length(s)); Move(PAnsiChar(s)^, a[0], Length(s));
  SetLength(b, Length(a)); Move(a[0], b[0], Length(a));
  ToUpperAscii(@a[0], Length(a));
  ToUpperRef(@b[0], Length(b));
  AssertTrue(CompareByte(a[0], b[0], Length(a))=0, 'ToUpperAscii basic');
end;

procedure TestUnalignedAndLengths;
var
  a, b: TBytes; i: Integer; n: Integer;
begin
  // build buffer > 64 bytes to trigger AVX2/SSE2/tail
  n := 97;
  SetLength(a, n+2);
  for i:=0 to n+1 do a[i] := Ord('A') + (i mod 26);
  SetLength(b, Length(a)); Move(a[0], b[0], Length(a));
  // unaligned start at +1
  ToLowerAscii(@a[1], n);
  ToLowerRef(@b[1], n);
  AssertTrue(CompareByte(a[1], b[1], n)=0, 'ToLowerAscii unaligned+long');

  // upper on odd length
  SetLength(a, Length(b)); Move(b[0], a[0], Length(b));
  ToUpperAscii(@a[1], n);
  ToUpperRef(@b[1], n);
  AssertTrue(CompareByte(a[1], b[1], n)=0, 'ToUpperAscii unaligned+long');
end;

procedure TestNonLettersUnchanged;
var
  a: TBytes; before: TBytes; s: AnsiString;
begin
  s := '0123456789!@#$%^&*()_+-=[]{}|;:' + #39 + '"' + #39 + ',./<>?~`';
  SetLength(a, Length(s)); Move(PAnsiChar(s)^, a[0], Length(s));
  SetLength(before, Length(a)); Move(a[0], before[0], Length(a));
  ToLowerAscii(@a[0], Length(a)); ToUpperAscii(@a[0], Length(a));
  AssertTrue(CompareByte(a[0], before[0], Length(a))=0, 'Non-letters unchanged');
end;


begin
  try
    TestBasic;
    TestUnalignedAndLengths;
    TestNonLettersUnchanged;
    Writeln('OK: minitest_text passed.');
  except
    on E: Exception do begin
      Writeln('EXCEPTION: ', E.ClassName, ': ', E.Message);
      Halt(2);
    end;
  end;
end.
