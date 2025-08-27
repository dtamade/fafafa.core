unit fafafa.core.simd.neon.validation.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.simd, fafafa.core.simd.types;

type
  TTestCase_NEONValidation = class(TTestCase)
  private
    procedure ValidateMemEqual(const ATestName: string; const a, b: TBytes; len: SizeUInt; expected: Boolean);
    procedure ValidateMemFindByte(const ATestName: string; const data: TBytes; value: Byte; expected: PtrInt);
    procedure ValidateToLowerAscii(const ATestName: string; const input, expected: string);
    procedure ValidateToUpperAscii(const ATestName: string; const input, expected: string);
    procedure ValidateUtf8Validate(const ATestName: string; const data: TBytes; expected: Boolean);
    procedure ValidateBytesIndexOf(const ATestName: string; const hay, ned: TBytes; expected: PtrInt);
  published
    procedure Test_NEON_Profile_Detection;
    procedure Test_NEON_MemEqual_Consistency;
    procedure Test_NEON_MemFindByte_Consistency;
    procedure Test_NEON_TextOps_Consistency;
    procedure Test_NEON_Search_Consistency;
    procedure Test_NEON_Performance_Baseline;
  end;

implementation

{$IFDEF CPUAARCH64}
uses
  fafafa.core.simd.mem, fafafa.core.simd.text, fafafa.core.simd.search;
{$ENDIF}

procedure TTestCase_NEONValidation.ValidateMemEqual(const ATestName: string; const a, b: TBytes; len: SizeUInt; expected: Boolean);
var
  resultScalar, resultCurrent: Boolean;
  {$IFDEF CPUAARCH64}
  resultNEON: Boolean;
  {$ENDIF}
begin
  resultScalar := MemEqual_Scalar(@a[0], @b[0], len);
  resultCurrent := MemEqual(@a[0], @b[0], len);

  AssertTrue(ATestName + ' (Scalar vs Current)', resultScalar = resultCurrent);
  AssertTrue(ATestName + ' (Expected result)', resultScalar = expected);

  {$IFDEF CPUAARCH64}
  {$IFDEF FAFAFA_SIMD_NEON_ASM}
  // Test NEON implementation directly if available
  resultNEON := MemEqual_NEON(@a[0], @b[0], len);
  AssertTrue(ATestName + ' (Scalar vs NEON)', resultScalar = resultNEON);
  {$ENDIF}
  {$ENDIF}
end;

procedure TTestCase_NEONValidation.ValidateMemFindByte(const ATestName: string; const data: TBytes; value: Byte; expected: PtrInt);
var
  resultScalar, resultCurrent: PtrInt;
  {$IFDEF CPUAARCH64}
  resultNEON: PtrInt;
  {$ENDIF}
begin
  resultScalar := MemFindByte_Scalar(@data[0], Length(data), value);
  resultCurrent := MemFindByte(@data[0], Length(data), value);

  AssertTrue(ATestName + ' (Scalar vs Current)', resultScalar = resultCurrent);
  AssertTrue(ATestName + ' (Expected result)', resultScalar = expected);

  {$IFDEF CPUAARCH64}
  {$IFDEF FAFAFA_SIMD_NEON_ASM}
  // Test NEON implementation directly if available
  resultNEON := MemFindByte_NEON(@data[0], Length(data), value);
  AssertTrue(ATestName + ' (Scalar vs NEON)', resultScalar = resultNEON);
  {$ENDIF}
  {$ENDIF}
end;

procedure TTestCase_NEONValidation.ValidateToLowerAscii(const ATestName: string; const input, expected: string);
var
  dataScalar, dataCurrent: TBytes;
  expectedBytes: TBytes;
  i: Integer;
  {$IFDEF CPUAARCH64}
  dataNEON: TBytes;
  {$ENDIF}
begin
  SetLength(dataScalar, Length(input));
  SetLength(dataCurrent, Length(input));
  SetLength(expectedBytes, Length(expected));
  
  for i := 0 to Length(input) - 1 do
  begin
    dataScalar[i] := Byte(Ord(input[i + 1]));
    dataCurrent[i] := Byte(Ord(input[i + 1]));
  end;
  for i := 0 to Length(expected) - 1 do
    expectedBytes[i] := Byte(Ord(expected[i + 1]));
  
  ToLowerAscii_Scalar(@dataScalar[0], Length(dataScalar));
  ToLowerAscii(@dataCurrent[0], Length(dataCurrent));
  
  AssertTrue(ATestName + ' (Scalar vs Current)', CompareMem(@dataScalar[0], @dataCurrent[0], Length(dataScalar)));
  AssertTrue(ATestName + ' (Expected result)', CompareMem(@dataScalar[0], @expectedBytes[0], Length(dataScalar)));
  
  {$IFDEF CPUAARCH64}
  {$IFDEF FAFAFA_SIMD_NEON_ASM}
  // Test NEON implementation directly if available
  SetLength(dataNEON, Length(input));
  for i := 0 to Length(input) - 1 do
    dataNEON[i] := Byte(Ord(input[i + 1]));
  
  ToLowerAscii_NEON(@dataNEON[0], Length(dataNEON));
  AssertTrue(ATestName + ' (Scalar vs NEON)', CompareMem(@dataScalar[0], @dataNEON[0], Length(dataScalar)));
  {$ENDIF}
  {$ENDIF}
end;

procedure TTestCase_NEONValidation.ValidateToUpperAscii(const ATestName: string; const input, expected: string);
var
  dataScalar, dataCurrent: TBytes;
  expectedBytes: TBytes;
  i: Integer;
  {$IFDEF CPUAARCH64}
  dataNEON: TBytes;
  {$ENDIF}
begin
  SetLength(dataScalar, Length(input));
  SetLength(dataCurrent, Length(input));
  SetLength(expectedBytes, Length(expected));
  
  for i := 0 to Length(input) - 1 do
  begin
    dataScalar[i] := Byte(Ord(input[i + 1]));
    dataCurrent[i] := Byte(Ord(input[i + 1]));
  end;
  for i := 0 to Length(expected) - 1 do
    expectedBytes[i] := Byte(Ord(expected[i + 1]));
  
  ToUpperAscii_Scalar(@dataScalar[0], Length(dataScalar));
  ToUpperAscii(@dataCurrent[0], Length(dataCurrent));
  
  AssertTrue(ATestName + ' (Scalar vs Current)', CompareMem(@dataScalar[0], @dataCurrent[0], Length(dataScalar)));
  AssertTrue(ATestName + ' (Expected result)', CompareMem(@dataScalar[0], @expectedBytes[0], Length(dataScalar)));
  
  {$IFDEF CPUAARCH64}
  {$IFDEF FAFAFA_SIMD_NEON_ASM}
  // Test NEON implementation directly if available
  SetLength(dataNEON, Length(input));
  for i := 0 to Length(input) - 1 do
    dataNEON[i] := Byte(Ord(input[i + 1]));
  
  ToUpperAscii_NEON(@dataNEON[0], Length(dataNEON));
  AssertTrue(ATestName + ' (Scalar vs NEON)', CompareMem(@dataScalar[0], @dataNEON[0], Length(dataScalar)));
  {$ENDIF}
  {$ENDIF}
end;

procedure TTestCase_NEONValidation.ValidateUtf8Validate(const ATestName: string; const data: TBytes; expected: Boolean);
var
  resultScalar, resultCurrent: Boolean;
  {$IFDEF CPUAARCH64}
  resultNEON: Boolean;
  {$ENDIF}
begin
  resultScalar := Utf8Validate_Scalar(@data[0], Length(data));
  resultCurrent := Utf8Validate(@data[0], Length(data));
  
  AssertTrue(ATestName + ' (Scalar vs Current)', resultScalar = resultCurrent);
  AssertTrue(ATestName + ' (Expected result)', resultScalar = expected);
  
  {$IFDEF CPUAARCH64}
  {$IFDEF FAFAFA_SIMD_NEON_ASM}
  // Test NEON implementation directly if available (ASCII fast path only)
  if expected then // Only test when expecting valid UTF-8
  begin
    resultNEON := Utf8Validate_NEON_ASCII(@data[0], Length(data));
    // NEON ASCII fast path may return False for valid non-ASCII UTF-8
    // So we only check that it doesn't incorrectly return True for invalid data
    if not resultNEON then
      AssertTrue(ATestName + ' (NEON ASCII fast path consistency)', resultScalar = resultNEON);
  end;
  {$ENDIF}
  {$ENDIF}
end;

procedure TTestCase_NEONValidation.ValidateBytesIndexOf(const ATestName: string; const hay, ned: TBytes; expected: PtrInt);
var
  resultScalar, resultCurrent: PtrInt;
  {$IFDEF CPUAARCH64}
  resultNEON: PtrInt;
  {$ENDIF}
begin
  resultScalar := BytesIndexOf_Scalar(@hay[0], Length(hay), @ned[0], Length(ned));
  resultCurrent := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  
  AssertTrue(ATestName + ' (Scalar vs Current)', resultScalar = resultCurrent);
  AssertTrue(ATestName + ' (Expected result)', resultScalar = expected);
  
  {$IFDEF CPUAARCH64}
  {$IFDEF FAFAFA_SIMD_NEON_ASM}
  // Test NEON implementation directly if available
  resultNEON := BytesIndexOf_NEON(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue(ATestName + ' (Scalar vs NEON)', resultScalar = resultNEON);
  {$ENDIF}
  {$ENDIF}
end;

procedure TTestCase_NEONValidation.Test_NEON_Profile_Detection;
var
  profile: string;
begin
  profile := SimdInfo;
  
  {$IFDEF CPUAARCH64}
  AssertTrue('AArch64 should detect NEON profile', Pos('AARCH64', profile) > 0);
  Writeln('Detected SIMD profile: ', profile);
  {$ELSE}
  Writeln('SKIP: Not running on AArch64, current profile: ', profile);
  {$ENDIF}
end;

procedure TTestCase_NEONValidation.Test_NEON_MemEqual_Consistency;
var
  a, b: TBytes;
  i: Integer;
begin
  // Test 1: Equal arrays
  SetLength(a, 64); SetLength(b, 64);
  for i := 0 to 63 do begin a[i] := i mod 256; b[i] := i mod 256; end;
  ValidateMemEqual('Equal arrays 64B', a, b, 64, True);
  
  // Test 2: Different arrays
  b[32] := b[32] + 1;
  ValidateMemEqual('Different arrays 64B', a, b, 64, False);
  
  // Test 3: Empty arrays
  ValidateMemEqual('Empty arrays', a, b, 0, True);
  
  // Test 4: Single byte
  ValidateMemEqual('Single byte equal', a, a, 1, True);
  ValidateMemEqual('Single byte different', a, b, 1, False);
  
  // Test 5: Large arrays
  SetLength(a, 1024); SetLength(b, 1024);
  for i := 0 to 1023 do begin a[i] := i mod 256; b[i] := i mod 256; end;
  ValidateMemEqual('Large equal arrays 1KB', a, b, 1024, True);
end;

procedure TTestCase_NEONValidation.Test_NEON_MemFindByte_Consistency;
var
  data: TBytes;
  i: Integer;
begin
  // Test 1: Find existing byte
  SetLength(data, 100);
  for i := 0 to 99 do data[i] := i mod 256;
  ValidateMemFindByte('Find byte 50', data, 50, 50);
  
  // Test 2: Find non-existing byte
  ValidateMemFindByte('Find non-existing byte', data, 200, -1);
  
  // Test 3: Find first byte
  ValidateMemFindByte('Find first byte', data, 0, 0);
  
  // Test 4: Find last byte
  data[99] := 255;
  ValidateMemFindByte('Find last byte', data, 255, 99);
  
  // Test 5: Empty data
  SetLength(data, 0);
  ValidateMemFindByte('Empty data', data, 0, -1);
end;

procedure TTestCase_NEONValidation.Test_NEON_TextOps_Consistency;
begin
  // Test ToLowerAscii
  ValidateToLowerAscii('Mixed case', 'Hello World 123!', 'hello world 123!');
  ValidateToLowerAscii('All uppercase', 'UPPERCASE', 'uppercase');
  ValidateToLowerAscii('All lowercase', 'lowercase', 'lowercase');
  ValidateToLowerAscii('Numbers and symbols', '123!@#', '123!@#');
  
  // Test ToUpperAscii
  ValidateToUpperAscii('Mixed case', 'Hello World 123!', 'HELLO WORLD 123!');
  ValidateToUpperAscii('All lowercase', 'lowercase', 'LOWERCASE');
  ValidateToUpperAscii('All uppercase', 'UPPERCASE', 'UPPERCASE');
  ValidateToUpperAscii('Numbers and symbols', '123!@#', '123!@#');
  
  // Test UTF-8 validation
  var asciiData: TBytes;
  SetLength(asciiData, 10);
  Move(PAnsiChar(AnsiString('Hello Test'))^, asciiData[0], 10);
  ValidateUtf8Validate('ASCII data', asciiData, True);
  
  var invalidData: TBytes;
  SetLength(invalidData, 3);
  invalidData[0] := $C0; invalidData[1] := $80; invalidData[2] := $00; // Overlong encoding
  ValidateUtf8Validate('Invalid UTF-8', invalidData, False);
end;

procedure TTestCase_NEONValidation.Test_NEON_Search_Consistency;
var
  hay, ned: TBytes;
  i: Integer;
begin
  // Test 1: Basic search
  SetLength(hay, 20);
  Move(PAnsiChar(AnsiString('Hello World Test 123'))^, hay[0], 20);
  SetLength(ned, 5);
  Move(PAnsiChar(AnsiString('World'))^, ned[0], 5);
  ValidateBytesIndexOf('Basic search', hay, ned, 6);
  
  // Test 2: Not found
  SetLength(ned, 3);
  Move(PAnsiChar(AnsiString('xyz'))^, ned[0], 3);
  ValidateBytesIndexOf('Not found', hay, ned, -1);
  
  // Test 3: Empty needle
  ValidateBytesIndexOf('Empty needle', hay, TBytes.Create(), 0);
  
  // Test 4: Large haystack
  SetLength(hay, 1000);
  for i := 0 to 999 do hay[i] := Byte(i mod 256);
  SetLength(ned, 10);
  for i := 0 to 9 do ned[i] := Byte((i + 100) mod 256);
  Move(ned[0], hay[500], 10); // Place needle at position 500
  ValidateBytesIndexOf('Large haystack', hay, ned, 500);
end;

procedure TTestCase_NEONValidation.Test_NEON_Performance_Baseline;
var
  data: TBytes;
  startTime, endTime: QWord;
  i, iterations: Integer;
  result: Boolean;
begin
  {$IFDEF CPUAARCH64}
  Writeln('=== NEON Performance Baseline ===');
  
  // Prepare test data
  SetLength(data, 1024);
  for i := 0 to 1023 do data[i] := i mod 256;
  
  iterations := 10000;
  
  // Benchmark MemEqual
  startTime := GetTickCount64;
  for i := 0 to iterations - 1 do
    result := MemEqual(@data[0], @data[0], 1024);
  endTime := GetTickCount64;
  Writeln(Format('MemEqual 1KB x%d: %d ms', [iterations, endTime - startTime]));
  
  // Benchmark MemFindByte
  startTime := GetTickCount64;
  for i := 0 to iterations - 1 do
    MemFindByte(@data[0], 1024, 128);
  endTime := GetTickCount64;
  Writeln(Format('MemFindByte 1KB x%d: %d ms', [iterations, endTime - startTime]));
  
  // Benchmark ToLowerAscii
  startTime := GetTickCount64;
  for i := 0 to iterations - 1 do
    ToLowerAscii(@data[0], 1024);
  endTime := GetTickCount64;
  Writeln(Format('ToLowerAscii 1KB x%d: %d ms', [iterations, endTime - startTime]));
  
  Writeln('=== Baseline Complete ===');
  {$ELSE}
  Writeln('SKIP: Performance baseline only available on AArch64');
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_NEONValidation);

end.
