program minitest_text_neon;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd,
  fafafa.core.simd.text;

procedure AssertTrue(cond: Boolean; const msg: string);
begin
  if not cond then begin Writeln('FAIL: ', msg); Halt(1); end;
end;

procedure RefLower(p: PByte; len: SizeUInt);
var i: SizeUInt;
begin
  for i:=0 to len-1 do if (p[i]>=Ord('A')) and (p[i]<=Ord('Z')) then p[i] := p[i] + 32;
end;

procedure RefUpper(p: PByte; len: SizeUInt);
var i: SizeUInt;
begin
  for i:=0 to len-1 do if (p[i]>=Ord('a')) and (p[i]<=Ord('z')) then p[i] := p[i] - 32;
end;

procedure TestAsciiCase_NEON_Direct;
{$IFDEF CPUAARCH64}
var
  a, b: TBytes;
  n: Integer;
begin
  n := 101;
  SetLength(a, n);
  for var i:=0 to n-1 do a[i] := Ord('A') + (i mod 26);
  b := Copy(a,0,n);
  ToLowerAscii_NEON(@a[0], n);
  RefLower(@b[0], n);
  AssertTrue(CompareByte(a[0], b[0], n)=0, 'ToLowerAscii_NEON direct');

  a := Copy(b,0,n);
  ToUpperAscii_NEON(@a[0], n);
  RefUpper(@b[0], n);
  AssertTrue(CompareByte(a[0], b[0], n)=0, 'ToUpperAscii_NEON direct');
end;
{$ELSE}
begin
  Writeln('SKIP: CPU is not AArch64.');
end;
{$ENDIF}

procedure TestAsciiCase_Facade;
var
  a, b: TBytes;
  n: Integer;
begin
  n := 97;
  SetLength(a, n);
  for var i:=0 to n-1 do a[i] := Ord('A') + (i mod 26);
  b := Copy(a,0,n);
  ToLowerAscii(@a[0], n);
  RefLower(@b[0], n);
  AssertTrue(CompareByte(a[0], b[0], n)=0, 'ToLowerAscii facade');

  a := Copy(b,0,n);
  ToUpperAscii(@a[0], n);
  RefUpper(@b[0], n);
  AssertTrue(CompareByte(a[0], b[0], n)=0, 'ToUpperAscii facade');
end;

begin
  Writeln('Profile = ', SimdInfo);
  TestAsciiCase_NEON_Direct;
  TestAsciiCase_Facade;
  Writeln('OK: minitest_text_neon passed.');
end.

