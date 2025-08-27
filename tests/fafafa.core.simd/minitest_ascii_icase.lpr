program minitest_ascii_icase;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd,
  fafafa.core.simd.text;

procedure AssertTrue(cond: Boolean; const msg: string);
begin
  if not cond then begin Writeln('FAIL: ', msg); Halt(1); end;
end;

procedure FillRandomAscii(var a: TBytes);
begin
  for var i:=0 to High(a) do begin
    case i and 7 of
      0: a[i] := Ord('A') + (i mod 26);
      1: a[i] := Ord('a') + (i mod 26);
      2: a[i] := Ord('Z') - (i mod 26);
      3: a[i] := Ord('z') - (i mod 26);
      else a[i] := Ord(' ') + (i mod 64);
    end;
  end;
end;

procedure TestScalar;
var a,b: TBytes; n: Integer; ok: Boolean;
begin
  n := 257; SetLength(a,n); SetLength(b,n);
  FillRandomAscii(a); b := Copy(a,0,n);
  // flip cases
  for var i:=0 to n-1 do begin if (a[i]>=Ord('a')) and (a[i]<=Ord('z')) then a[i] := a[i]-32; end;
  ok := AsciiEqualIgnoreCase_Scalar(@a[0], @b[0], n);
  AssertTrue(ok, 'Scalar icase');
end;

procedure TestFacade;
var a,b: TBytes; n: Integer; ok: Boolean;
begin
  n := 4097; SetLength(a,n); SetLength(b,n);
  FillRandomAscii(a); b := Copy(a,0,n);
  // make half uppercase in a
  for var i:=0 to n-1 do if (i and 1)=0 then if (a[i]>=Ord('a')) and (a[i]<=Ord('z')) then a[i] := a[i]-32;
  ok := AsciiIEqual(@a[0], @b[0], n);
  AssertTrue(ok, 'Facade icase');
end;

begin
  Writeln('SIMD Profile = ', SimdInfo);
  TestScalar;
  TestFacade;
  Writeln('OK: minitest_ascii_icase passed.');
end.

