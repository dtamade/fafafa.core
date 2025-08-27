unit fafafa.core.simd.text.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.simd;

type
  TTestCase_Text = class(TTestCase)
  published
    procedure Test_AsciiIEqual_NonAscii_Rejected;
    procedure Test_Utf8Validate_FastPath_And_Fallback;
  end;

implementation

procedure TTestCase_Text.Test_AsciiIEqual_NonAscii_Rejected;
var
  a, b: array[0..3] of Byte;
  ok: Boolean;
begin
  // non-ASCII should not be treated as equal via ASCII-icase comparator
  a[0]:=$C3; a[1]:=$A9; a[2]:=Ord('A'); a[3]:=0;       // 'éA' (utf-8)
  b[0]:=$C3; b[1]:=$A8; b[2]:=Ord('a'); b[3]:=0;       // 'èa' (utf-8)
  ok := AsciiIEqual(@a[0], @b[0], 3);
  AssertTrue('non-ascii should not pass ASCII-icase equality', not ok);
end;

procedure TTestCase_Text.Test_Utf8Validate_FastPath_And_Fallback;
var
  ascii: array[0..15] of Byte;
  bad: array[0..2] of Byte;
  ok: Boolean;
begin
  FillChar(ascii, SizeOf(ascii), Ord('A'));
  ok := Utf8Validate(@ascii[0], SizeOf(ascii));
  AssertTrue('ASCII is valid UTF-8', ok);

  // malformed: E2 28 A1 (bad continuation)
  bad[0] := $E2; bad[1] := $28; bad[2] := $A1;
  ok := Utf8Validate(@bad[0], 3);
  AssertTrue('malformed utf-8 rejected', not ok);
end;

initialization
  RegisterTest(TTestCase_Text);

end.

