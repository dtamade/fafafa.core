unit fafafa.core.simd.text.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.simd, fafafa.core.simd.text;

type
  TTestCase_Text = class(TTestCase)
  private
    procedure TestAsciiCaseConsistency(const input: string; const expectedLower, expectedUpper: string);
    procedure TestUtf8ValidateConsistency(const data: TBytes; expected: Boolean);
  published
    procedure Test_AsciiIEqual_NonAscii_Rejected;
    procedure Test_Utf8Validate_FastPath_And_Fallback;
    procedure Test_AsciiIEqual_SIMD_Consistency;
    procedure Test_AsciiCase_SIMD_Consistency;
    procedure Test_Utf8Validate_SIMD_Consistency;
    procedure Test_AsciiIEqual_EdgeCases;
    procedure Test_AsciiCase_EdgeCases;
    procedure Test_Utf8Validate_EdgeCases;
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

procedure TTestCase_Text.TestAsciiCaseConsistency(const input: string; const expectedLower, expectedUpper: string);
var
  data, dataLower, dataUpper: TBytes;
  refLower, refUpper: TBytes;
  i: Integer;
begin
  SetLength(data, Length(input));
  SetLength(dataLower, Length(input));
  SetLength(dataUpper, Length(input));
  SetLength(refLower, Length(expectedLower));
  SetLength(refUpper, Length(expectedUpper));

  // Convert input strings to byte arrays
  for i := 0 to Length(input) - 1 do
    data[i] := Byte(Ord(input[i + 1]));
  for i := 0 to Length(expectedLower) - 1 do
    refLower[i] := Byte(Ord(expectedLower[i + 1]));
  for i := 0 to Length(expectedUpper) - 1 do
    refUpper[i] := Byte(Ord(expectedUpper[i + 1]));

  // Test ToLowerAscii
  Move(data[0], dataLower[0], Length(data));
  ToLowerAscii(@dataLower[0], Length(dataLower));
  AssertTrue('ToLowerAscii consistency for: ' + input,
    CompareMem(@dataLower[0], @refLower[0], Length(dataLower)));

  // Test ToUpperAscii
  Move(data[0], dataUpper[0], Length(data));
  ToUpperAscii(@dataUpper[0], Length(dataUpper));
  AssertTrue('ToUpperAscii consistency for: ' + input,
    CompareMem(@dataUpper[0], @refUpper[0], Length(dataUpper)));
end;

procedure TTestCase_Text.TestUtf8ValidateConsistency(const data: TBytes; expected: Boolean);
var
  result: Boolean;
begin
  result := Utf8Validate(@data[0], Length(data));
  AssertTrue(Format('Utf8Validate consistency: expected=%s got=%s',
    [BoolToStr(expected, True), BoolToStr(result, True)]), result = expected);
end;

procedure TTestCase_Text.Test_AsciiIEqual_SIMD_Consistency;
var
  a, b: TBytes;
  resultCurrent, resultScalar: Boolean;
  i: Integer;
  testCases: array[0..4] of record
    strA, strB: string;
    expected: Boolean;
  end;
begin
  // Define test cases
  testCases[0].strA := 'Hello World'; testCases[0].strB := 'hello world'; testCases[0].expected := True;
  testCases[1].strA := 'UPPERCASE'; testCases[1].strB := 'lowercase'; testCases[1].expected := False;
  testCases[2].strA := 'MixedCase123'; testCases[2].strB := 'mixedcase123'; testCases[2].expected := True;
  testCases[3].strA := 'Same'; testCases[3].strB := 'Same'; testCases[3].expected := True;
  testCases[4].strA := 'Different'; testCases[4].strB := 'Other'; testCases[4].expected := False;

  for i := 0 to High(testCases) do
  begin
    SetLength(a, Length(testCases[i].strA));
    SetLength(b, Length(testCases[i].strB));

    Move(PAnsiChar(AnsiString(testCases[i].strA))^, a[0], Length(a));
    Move(PAnsiChar(AnsiString(testCases[i].strB))^, b[0], Length(b));

    resultCurrent := AsciiIEqual(@a[0], @b[0], Length(a));
    resultScalar := AsciiEqualIgnoreCase_Scalar(@a[0], @b[0], Length(a));

    AssertTrue(Format('AsciiIEqual SIMD consistency case %d: "%s" vs "%s"',
      [i, testCases[i].strA, testCases[i].strB]), resultCurrent = resultScalar);
    AssertTrue(Format('AsciiIEqual expected result case %d', [i]),
      resultCurrent = testCases[i].expected);
  end;
end;

procedure TTestCase_Text.Test_AsciiCase_SIMD_Consistency;
begin
  // Test various ASCII case conversion scenarios
  TestAsciiCaseConsistency('Hello World', 'hello world', 'HELLO WORLD');
  TestAsciiCaseConsistency('UPPERCASE', 'uppercase', 'UPPERCASE');
  TestAsciiCaseConsistency('lowercase', 'lowercase', 'LOWERCASE');
  TestAsciiCaseConsistency('MixedCase123!@#', 'mixedcase123!@#', 'MIXEDCASE123!@#');
  TestAsciiCaseConsistency('', '', ''); // Empty string
  TestAsciiCaseConsistency('A', 'a', 'A'); // Single character
  TestAsciiCaseConsistency('z', 'z', 'Z'); // Single character
  TestAsciiCaseConsistency('0123456789', '0123456789', '0123456789'); // Numbers
  TestAsciiCaseConsistency('!@#$%^&*()', '!@#$%^&*()', '!@#$%^&*()'); // Symbols
end;

procedure TTestCase_Text.Test_Utf8Validate_SIMD_Consistency;
var
  testData: TBytes;
  i: Integer;
begin
  // Test 1: Pure ASCII (should be valid)
  SetLength(testData, 100);
  for i := 0 to 99 do
    testData[i] := Byte(Ord('A') + (i mod 26));
  TestUtf8ValidateConsistency(testData, True);

  // Test 2: Valid UTF-8 sequences
  SetLength(testData, 6);
  testData[0] := $C3; testData[1] := $A9; // é
  testData[2] := $E2; testData[3] := $82; testData[4] := $AC; // €
  testData[5] := Ord('A');
  TestUtf8ValidateConsistency(testData, True);

  // Test 3: Invalid UTF-8 - bad continuation byte
  SetLength(testData, 3);
  testData[0] := $C3; testData[1] := $28; testData[2] := $A9;
  TestUtf8ValidateConsistency(testData, False);

  // Test 4: Invalid UTF-8 - incomplete sequence
  SetLength(testData, 2);
  testData[0] := $C3; testData[1] := Ord('A');
  TestUtf8ValidateConsistency(testData, False);

  // Test 5: Invalid UTF-8 - overlong encoding
  SetLength(testData, 2);
  testData[0] := $C0; testData[1] := $80; // Overlong encoding of NULL
  TestUtf8ValidateConsistency(testData, False);
end;

procedure TTestCase_Text.Test_AsciiIEqual_EdgeCases;
var
  a, b: TBytes;
  result: Boolean;
begin
  // Test 1: Empty strings
  SetLength(a, 0); SetLength(b, 0);
  result := AsciiIEqual(@a[0], @b[0], 0);
  AssertTrue('Empty strings should be equal', result);

  // Test 2: Different lengths (should handle gracefully)
  SetLength(a, 5); SetLength(b, 3);
  Move(PAnsiChar(AnsiString('Hello'))^, a[0], 5);
  Move(PAnsiChar(AnsiString('Hel'))^, b[0], 3);
  result := AsciiIEqual(@a[0], @b[0], 3);
  AssertTrue('Prefix match should work', result);

  // Test 3: Non-ASCII bytes (should not match even if same)
  SetLength(a, 2); SetLength(b, 2);
  a[0] := $C3; a[1] := $A9; // é in UTF-8
  b[0] := $C3; b[1] := $A9; // same é
  result := AsciiIEqual(@a[0], @b[0], 2);
  AssertTrue('Non-ASCII should not be considered equal in ASCII comparison', not result);

  // Test 4: Mixed ASCII and non-ASCII
  SetLength(a, 3); SetLength(b, 3);
  a[0] := Ord('A'); a[1] := $C3; a[2] := $A9;
  b[0] := Ord('a'); b[1] := $C3; b[2] := $A9;
  result := AsciiIEqual(@a[0], @b[0], 3);
  AssertTrue('Mixed ASCII/non-ASCII should fail', not result);
end;

procedure TTestCase_Text.Test_AsciiCase_EdgeCases;
var
  data: TBytes;
  i: Integer;
begin
  // Test 1: Empty data
  SetLength(data, 0);
  ToLowerAscii(@data[0], 0);
  ToUpperAscii(@data[0], 0);
  // Should not crash

  // Test 2: Single byte
  SetLength(data, 1);
  data[0] := Ord('A');
  ToLowerAscii(@data[0], 1);
  AssertTrue('Single A->a', data[0] = Ord('a'));

  data[0] := Ord('z');
  ToUpperAscii(@data[0], 1);
  AssertTrue('Single z->Z', data[0] = Ord('Z'));

  // Test 3: Non-ASCII bytes (should be unchanged)
  SetLength(data, 4);
  data[0] := $C3; data[1] := $A9; // é
  data[2] := Ord('A'); data[3] := Ord('b');

  ToLowerAscii(@data[0], 4);
  AssertTrue('Non-ASCII unchanged in ToLower', (data[0] = $C3) and (data[1] = $A9));
  AssertTrue('ASCII converted in ToLower', (data[2] = Ord('a')) and (data[3] = Ord('b')));

  // Reset and test upper
  data[2] := Ord('a'); data[3] := Ord('B');
  ToUpperAscii(@data[0], 4);
  AssertTrue('Non-ASCII unchanged in ToUpper', (data[0] = $C3) and (data[1] = $A9));
  AssertTrue('ASCII converted in ToUpper', (data[2] = Ord('A')) and (data[3] = Ord('B')));

  // Test 4: Large buffer with mixed content
  SetLength(data, 1000);
  for i := 0 to 999 do
  begin
    if i mod 3 = 0 then
      data[i] := Byte(Ord('A') + (i mod 26))
    else if i mod 3 = 1 then
      data[i] := Byte(Ord('a') + (i mod 26))
    else
      data[i] := Byte(128 + (i mod 128)); // Non-ASCII
  end;

  ToLowerAscii(@data[0], 1000);
  // Verify ASCII letters are converted, non-ASCII unchanged
  for i := 0 to 999 do
  begin
    if i mod 3 = 0 then
      AssertTrue(Format('Large buffer ToLower pos %d', [i]),
        data[i] = Byte(Ord('a') + (i mod 26)))
    else if i mod 3 = 2 then
      AssertTrue(Format('Large buffer non-ASCII unchanged pos %d', [i]),
        data[i] = Byte(128 + (i mod 128)));
  end;
end;

procedure TTestCase_Text.Test_Utf8Validate_EdgeCases;
var
  data: TBytes;
begin
  // Test 1: Empty data
  SetLength(data, 0);
  AssertTrue('Empty data is valid UTF-8', Utf8Validate(@data[0], 0));

  // Test 2: Single ASCII byte
  SetLength(data, 1);
  data[0] := Ord('A');
  AssertTrue('Single ASCII is valid', Utf8Validate(@data[0], 1));

  // Test 3: Invalid single byte (high bit set but not valid UTF-8 start)
  data[0] := $80;
  AssertTrue('Invalid single byte rejected', not Utf8Validate(@data[0], 1));

  // Test 4: Valid 2-byte sequence
  SetLength(data, 2);
  data[0] := $C2; data[1] := $A0; // Non-breaking space
  AssertTrue('Valid 2-byte sequence', Utf8Validate(@data[0], 2));

  // Test 5: Invalid 2-byte sequence (bad continuation)
  data[0] := $C2; data[1] := $20; // Space instead of continuation
  AssertTrue('Invalid 2-byte sequence rejected', not Utf8Validate(@data[0], 2));

  // Test 6: Valid 3-byte sequence
  SetLength(data, 3);
  data[0] := $E2; data[1] := $82; data[2] := $AC; // Euro sign
  AssertTrue('Valid 3-byte sequence', Utf8Validate(@data[0], 3));

  // Test 7: Invalid 3-byte sequence (truncated)
  SetLength(data, 2);
  data[0] := $E2; data[1] := $82; // Missing third byte
  AssertTrue('Truncated 3-byte sequence rejected', not Utf8Validate(@data[0], 2));

  // Test 8: Valid 4-byte sequence
  SetLength(data, 4);
  data[0] := $F0; data[1] := $9F; data[2] := $98; data[3] := $80; // Emoji
  AssertTrue('Valid 4-byte sequence', Utf8Validate(@data[0], 4));

  // Test 9: Large buffer with mixed valid/invalid
  SetLength(data, 100);
  FillChar(data[0], 100, Ord('A')); // Start with all ASCII
  AssertTrue('Large ASCII buffer valid', Utf8Validate(@data[0], 100));

  // Insert invalid byte in middle
  data[50] := $80;
  AssertTrue('Large buffer with invalid byte rejected', not Utf8Validate(@data[0], 100));
end;

initialization
  RegisterTest(TTestCase_Text);

end.

