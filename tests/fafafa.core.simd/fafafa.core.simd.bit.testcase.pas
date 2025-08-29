unit fafafa.core.simd.bit.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.simd, fafafa.core.simd.bitset;

type
  TTestCase_Bit = class(TTestCase)
  private
    procedure TestPopCountConsistency(const data: TBytes; bitLen: SizeUInt);
  published
    procedure Test_PopCount_TailBits_NotAligned;
    procedure Test_PopCount_SIMD_Consistency;
    procedure Test_PopCount_EdgeCases;
    procedure Test_PopCount_LargeBuffers;
    procedure Test_PopCount_AlignmentVariations;
  end;

implementation

procedure TTestCase_Bit.Test_PopCount_TailBits_NotAligned;
var
  buf: array[0..1] of Byte; // 16 bits
  c: SizeUInt;
begin
  // 低位优先（与实现一致）：前 3 位为 0b001 => 1 个 1
  buf[0] := $01; buf[1] := $00;
  c := BitsetPopCount(@buf[0], 3);
  AssertTrue('popcount 3 bits', c = 1);

  // 前 9 位：低 8 位含 1 个 1，下一字节最低位也为 1 => 共 2 个 1
  buf[0] := $01; buf[1] := $01;
  c := BitsetPopCount(@buf[0], 9);
  AssertTrue('popcount 9 bits', c = 2);
end;

procedure TTestCase_Bit.TestPopCountConsistency(const data: TBytes; bitLen: SizeUInt);
var
  resultCurrent, resultScalar: SizeUInt;
  {$IFDEF CPUX86_64}
  resultPopcnt: SizeUInt;
  {$ENDIF}
begin
  resultCurrent := BitsetPopCount(@data[0], bitLen);
  resultScalar := BitsetPopCount_Scalar(@data[0], bitLen);

  AssertTrue(Format('PopCount consistency: bitLen=%d current=%d scalar=%d',
    [bitLen, resultCurrent, resultScalar]), resultCurrent = resultScalar);

  {$IFDEF CPUX86_64}
  // Test POPCNT implementation directly if available
  resultPopcnt := BitsetPopCount_Popcnt(@data[0], bitLen);
  AssertTrue(Format('PopCount POPCNT consistency: bitLen=%d scalar=%d popcnt=%d',
    [bitLen, resultScalar, resultPopcnt]), resultScalar = resultPopcnt);
  {$ENDIF}
end;

procedure TTestCase_Bit.Test_PopCount_SIMD_Consistency;
var
  data: TBytes;
  i, bitLen: SizeUInt;
  testSizes: array[0..8] of SizeUInt;
  ts: Integer;
begin
  testSizes[0] := 1;
  testSizes[1] := 7;
  testSizes[2] := 8;
  testSizes[3] := 9;
  testSizes[4] := 15;
  testSizes[5] := 16;
  testSizes[6] := 17;
  testSizes[7] := 63;
  testSizes[8] := 64;

  for ts := 0 to High(testSizes) do
  begin
    bitLen := testSizes[ts];
    SetLength(data, (bitLen + 7) div 8);

    // Test pattern 1: All zeros
    FillChar(data[0], Length(data), 0);
    TestPopCountConsistency(data, bitLen);

    // Test pattern 2: All ones (with proper masking)
    FillChar(data[0], Length(data), $FF);
    TestPopCountConsistency(data, bitLen);

    // Test pattern 3: Alternating pattern
    for i := 0 to Length(data) - 1 do
      data[i] := $AA; // 10101010
    TestPopCountConsistency(data, bitLen);

    // Test pattern 4: Another alternating pattern
    for i := 0 to Length(data) - 1 do
      data[i] := $55; // 01010101
    TestPopCountConsistency(data, bitLen);

    // Test pattern 5: Random-like pattern
    for i := 0 to Length(data) - 1 do
      data[i] := Byte((i * 17 + 23) mod 256);
    TestPopCountConsistency(data, bitLen);
  end;
end;

procedure TTestCase_Bit.Test_PopCount_EdgeCases;
var
  data: TBytes;
  result: SizeUInt;
begin
  // Test 1: Empty data
  SetLength(data, 0);
  result := BitsetPopCount(@data[0], 0);
  AssertTrue('Empty data should return 0', result = 0);

  // Test 2: Single bit set
  SetLength(data, 1);
  data[0] := $01; // 00000001
  result := BitsetPopCount(@data[0], 1);
  AssertTrue('Single bit set should return 1', result = 1);

  // Test 3: Single bit not set
  data[0] := $00; // 00000000
  result := BitsetPopCount(@data[0], 1);
  AssertTrue('Single bit not set should return 0', result = 0);

  // Test 4: Partial byte - 3 bits, all set
  data[0] := $07; // 00000111
  result := BitsetPopCount(@data[0], 3);
  AssertTrue('3 bits all set should return 3', result = 3);

  // Test 5: Partial byte - 3 bits, with extra bits set but masked
  data[0] := $FF; // 11111111, but only first 3 bits count
  result := BitsetPopCount(@data[0], 3);
  AssertTrue('3 bits with masking should return 3', result = 3);

  // Test 6: Exactly 8 bits
  data[0] := $FF; // 11111111
  result := BitsetPopCount(@data[0], 8);
  AssertTrue('8 bits all set should return 8', result = 8);

  // Test 7: 9 bits spanning two bytes
  SetLength(data, 2);
  data[0] := $FF; // 11111111
  data[1] := $01; // 00000001, but only first bit counts
  result := BitsetPopCount(@data[0], 9);
  AssertTrue('9 bits spanning bytes should return 9', result = 9);
end;

procedure TTestCase_Bit.Test_PopCount_LargeBuffers;
var
  data: TBytes;
  i: SizeUInt;
  result: SizeUInt;
  expected: SizeUInt;
begin
  // Test with large buffer - 1KB
  SetLength(data, 1024);

  // Pattern 1: All zeros
  FillChar(data[0], 1024, 0);
  result := BitsetPopCount(@data[0], 1024 * 8);
  AssertTrue('Large buffer all zeros', result = 0);

  // Pattern 2: All ones
  FillChar(data[0], 1024, $FF);
  result := BitsetPopCount(@data[0], 1024 * 8);
  AssertTrue('Large buffer all ones', result = 1024 * 8);

  // Pattern 3: Alternating bytes
  for i := 0 to 1023 do
    data[i] := Byte(i mod 2) * $FF;
  result := BitsetPopCount(@data[0], 1024 * 8);
  expected := 512 * 8; // Half the bytes are $FF
  AssertTrue('Large buffer alternating', result = expected);

  // Pattern 4: Each byte has exactly 4 bits set
  for i := 0 to 1023 do
    data[i] := $0F; // 00001111
  result := BitsetPopCount(@data[0], 1024 * 8);
  expected := 1024 * 4;
  AssertTrue('Large buffer 4 bits per byte', result = expected);

  // Test with non-byte-aligned length
  result := BitsetPopCount(@data[0], 1024 * 8 - 3);
  // 8189 bits = 1023 complete bytes + 5 bits
  // Each complete byte ($0F) has 4 set bits: 1023 * 4 = 4092
  // Last byte ($0F) masked to 5 bits: $0F & $1F = $0F, still 4 set bits
  // Total: 4092 + 4 = 4096
  expected := 1023 * 4 + 4; // 正确的期望值
  AssertTrue('Large buffer non-aligned', result = expected);
end;

procedure TTestCase_Bit.Test_PopCount_AlignmentVariations;
var
  baseData: TBytes;
  data: TBytes;
  i, offset: SizeUInt;
  result: SizeUInt;
begin
  // Create base data with known pattern
  SetLength(baseData, 128);
  for i := 0 to 127 do
    baseData[i] := Byte(i mod 256);

  // Test different bit lengths to exercise alignment boundaries
  for offset := 1 to 67 do // Test various bit lengths
  begin
    SetLength(data, (offset + 7) div 8);
    Move(baseData[0], data[0], Length(data));

    // Test current implementation
    result := BitsetPopCount(@data[0], offset);

    // Verify against scalar implementation
    TestPopCountConsistency(data, offset);
  end;

  // Test specific alignment cases that are important for SIMD

  // 64-bit alignment test
  SetLength(data, 16); // 128 bits
  for i := 0 to 15 do
    data[i] := $AA; // 10101010 pattern

  // Test various bit lengths around 64-bit boundaries
  TestPopCountConsistency(data, 63);  // Just under 64 bits
  TestPopCountConsistency(data, 64);  // Exactly 64 bits
  TestPopCountConsistency(data, 65);  // Just over 64 bits
  TestPopCountConsistency(data, 127); // Just under 128 bits
  TestPopCountConsistency(data, 128); // Exactly 128 bits

  // Test with different patterns
  for i := 0 to 15 do
    data[i] := $55; // 01010101 pattern

  TestPopCountConsistency(data, 63);
  TestPopCountConsistency(data, 64);
  TestPopCountConsistency(data, 65);
  TestPopCountConsistency(data, 127);
  TestPopCountConsistency(data, 128);

  // Test with sparse pattern
  FillChar(data[0], 16, 0);
  data[0] := $01;  // 1 bit in first byte
  data[7] := $80;  // 1 bit in 8th byte (64-bit boundary)
  data[8] := $01;  // 1 bit in 9th byte (just after 64-bit boundary)
  data[15] := $80; // 1 bit in last byte

  TestPopCountConsistency(data, 128);
end;

initialization
  RegisterTest(TTestCase_Bit);

end.

