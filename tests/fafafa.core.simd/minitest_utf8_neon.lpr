program minitest_utf8_neon;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd,
  fafafa.core.simd.text;

procedure AssertTrue(cond: Boolean; const msg: string);
begin
  if not cond then begin Writeln('FAIL: ', msg); Halt(1); end;
end;

procedure TestUtf8AsciiFastPath_Direct;
{$IFDEF CPUAARCH64}
var
  ascii: TBytes;
  ok: Boolean;
begin
  SetLength(ascii, 4096);
  for var i:=0 to High(ascii) do ascii[i] := Ord('A') + (i and 15);
  ok := Utf8Validate_NEON_ASCII(@ascii[0], Length(ascii));
  AssertTrue(ok, 'Utf8Validate_NEON_ASCII should be true for ASCII');
end;
{$ELSE}
begin
  Writeln('SKIP: CPU is not AArch64.');
end;
{$ENDIF}

procedure TestUtf8AsciiFastPath_Facade;
var
  ascii: TBytes;
  ok: Boolean;
begin
  SetLength(ascii, 1024);
  for var i:=0 to High(ascii) do ascii[i] := Ord('a') + (i mod 26);
  ok := Utf8Validate(@ascii[0], Length(ascii));
  AssertTrue(ok, 'Utf8Validate facade should be true for ASCII');
end;

begin
  Writeln('Profile = ', SimdInfo);
  TestUtf8AsciiFastPath_Direct;
  TestUtf8AsciiFastPath_Facade;
  Writeln('OK: minitest_utf8_neon passed.');
end.

