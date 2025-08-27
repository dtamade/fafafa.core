unit fafafa.core.simd.search.edge.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.simd, fafafa.core.simd.types, fafafa.core.simd.search;

type
  TTestCase_SearchEdge = class(TTestCase)
  published
    procedure Test_BytesIndexOf_PowerOfTwo_Boundaries;
    procedure Test_BytesIndexOf_SIMD_Register_Boundaries;
    procedure Test_BytesIndexOf_Pathological_Cases;
    procedure Test_BytesIndexOf_Memory_Alignment;
    procedure Test_BytesIndexOf_Cross_Implementation_Validation;
  end;

implementation

procedure TTestCase_SearchEdge.Test_BytesIndexOf_PowerOfTwo_Boundaries;
var
  hay, ned: TBytes;
  idx: PtrInt;
  i, haySize, needleSize: SizeUInt;
  powerSizes: array[0..6] of SizeUInt;
  ps: Integer;
begin
  // Test around power-of-2 boundaries that are significant for SIMD
  powerSizes[0] := 16;   // SSE2 register size
  powerSizes[1] := 32;   // AVX2 register size  
  powerSizes[2] := 64;   // Cache line size
  powerSizes[3] := 128;  // Common buffer size
  powerSizes[4] := 256;  // Page boundary
  powerSizes[5] := 512;  // Larger buffer
  powerSizes[6] := 1024; // KB boundary
  
  for ps := 0 to High(powerSizes) do
  begin
    haySize := powerSizes[ps] + 16; // Slightly larger than boundary
    SetLength(hay, haySize);
    
    // Fill with predictable pattern
    for i := 0 to haySize - 1 do
      hay[i] := Byte(i mod 251); // Use prime to avoid simple patterns
    
    // Test needles of various sizes around the boundary
    for needleSize := 1 to 33 do
    begin
      if needleSize > haySize then Continue;
      
      SetLength(ned, needleSize);
      for i := 0 to needleSize - 1 do
        ned[i] := Byte((i + 200) mod 251);
      
      // Place needle at boundary - 1
      if powerSizes[ps] >= needleSize then
      begin
        Move(ned[0], hay[powerSizes[ps] - needleSize], needleSize);
        idx := BytesIndexOf(@hay[0], haySize, @ned[0], needleSize);
        AssertTrue(Format('Boundary test: haySize=%d needleSize=%d at boundary-needle', 
          [haySize, needleSize]), idx = PtrInt(powerSizes[ps] - needleSize));
        
        // Restore pattern
        for i := 0 to needleSize - 1 do
          hay[powerSizes[ps] - needleSize + i] := Byte((powerSizes[ps] - needleSize + i) mod 251);
      end;
      
      // Place needle at boundary
      if powerSizes[ps] + needleSize <= haySize then
      begin
        Move(ned[0], hay[powerSizes[ps]], needleSize);
        idx := BytesIndexOf(@hay[0], haySize, @ned[0], needleSize);
        AssertTrue(Format('Boundary test: haySize=%d needleSize=%d at boundary', 
          [haySize, needleSize]), idx = PtrInt(powerSizes[ps]));
      end;
    end;
  end;
end;

procedure TTestCase_SearchEdge.Test_BytesIndexOf_SIMD_Register_Boundaries;
var
  hay, ned: TBytes;
  idx: PtrInt;
  i: SizeUInt;
begin
  // Test specific cases that exercise SIMD register boundaries
  SetLength(hay, 100);
  
  // Case 1: 15-byte needle (just under SSE2 register size)
  SetLength(ned, 15);
  for i := 0 to 99 do hay[i] := Byte(i mod 256);
  for i := 0 to 14 do ned[i] := Byte((i + 50) mod 256);
  
  Move(ned[0], hay[30], 15);
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue('15-byte needle should be found', idx = 30);
  
  // Case 2: 16-byte needle (exactly SSE2 register size)
  SetLength(ned, 16);
  for i := 0 to 99 do hay[i] := Byte(i mod 256);
  for i := 0 to 15 do ned[i] := Byte((i + 60) mod 256);
  
  Move(ned[0], hay[40], 16);
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue('16-byte needle should be found', idx = 40);
  
  // Case 3: 17-byte needle (just over SSE2 register size)
  SetLength(ned, 17);
  for i := 0 to 99 do hay[i] := Byte(i mod 256);
  for i := 0 to 16 do ned[i] := Byte((i + 70) mod 256);
  
  Move(ned[0], hay[20], 17);
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue('17-byte needle should be found', idx = 20);
  
  // Case 4: 31-byte needle (just under AVX2 register size)
  SetLength(hay, 200);
  SetLength(ned, 31);
  for i := 0 to 199 do hay[i] := Byte(i mod 256);
  for i := 0 to 30 do ned[i] := Byte((i + 80) mod 256);
  
  Move(ned[0], hay[50], 31);
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue('31-byte needle should be found', idx = 50);
  
  // Case 5: 32-byte needle (exactly AVX2 register size)
  SetLength(ned, 32);
  for i := 0 to 199 do hay[i] := Byte(i mod 256);
  for i := 0 to 31 do ned[i] := Byte((i + 90) mod 256);
  
  Move(ned[0], hay[60], 32);
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue('32-byte needle should be found', idx = 60);
  
  // Case 6: 33-byte needle (just over AVX2 register size)
  SetLength(ned, 33);
  for i := 0 to 199 do hay[i] := Byte(i mod 256);
  for i := 0 to 32 do ned[i] := Byte((i + 100) mod 256);
  
  Move(ned[0], hay[70], 33);
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue('33-byte needle should be found', idx = 70);
end;

procedure TTestCase_SearchEdge.Test_BytesIndexOf_Pathological_Cases;
var
  hay, ned: TBytes;
  idx: PtrInt;
  i: SizeUInt;
begin
  // Case 1: All bytes the same except the last one
  SetLength(hay, 1000);
  SetLength(ned, 50);
  
  for i := 0 to 999 do hay[i] := Ord('A');
  for i := 0 to 48 do ned[i] := Ord('A');
  ned[49] := Ord('B');
  
  // Place the pattern at position 500
  hay[549] := Ord('B');
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue('Pathological case 1: should find pattern', idx = 500);
  
  // Case 2: Needle that appears to match but fails at the end
  for i := 0 to 999 do hay[i] := Ord('X');
  for i := 0 to 48 do ned[i] := Ord('X');
  ned[49] := Ord('Y');
  
  // Create false positive at position 100 (49 X's followed by X instead of Y)
  // Real match at position 200
  hay[249] := Ord('Y');
  
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue('Pathological case 2: should find real match', idx = 200);
  
  // Case 3: Overlapping patterns
  SetLength(hay, 100);
  SetLength(ned, 10);
  
  for i := 0 to 99 do hay[i] := Ord('Z');
  for i := 0 to 8 do ned[i] := Ord('Z');
  ned[9] := Ord('W');
  
  // Create pattern at position 30
  hay[39] := Ord('W');
  idx := BytesIndexOf(@hay[0], Length(hay), @ned[0], Length(ned));
  AssertTrue('Pathological case 3: overlapping patterns', idx = 30);
end;

procedure TTestCase_SearchEdge.Test_BytesIndexOf_Memory_Alignment;
var
  hay, ned: TBytes;
  idx: PtrInt;
  i, offset: SizeUInt;
  baseHay: TBytes;
begin
  // Test with different memory alignments to ensure SIMD code handles unaligned access
  SetLength(baseHay, 1024 + 64); // Extra space for alignment testing
  SetLength(ned, 20);
  
  for i := 0 to 19 do ned[i] := Byte(i + 100);
  
  // Test different alignment offsets
  for offset := 0 to 15 do
  begin
    SetLength(hay, 1024);
    
    // Fill with pattern
    for i := 0 to 1023 do
      hay[i] := Byte(i mod 256);
    
    // Place needle at position 500
    Move(ned[0], hay[500], 20);
    
    // Copy to offset position in base array to test alignment
    Move(hay[0], baseHay[offset], 1024);
    
    idx := BytesIndexOf(@baseHay[offset], 1024, @ned[0], 20);
    AssertTrue(Format('Alignment test offset=%d', [offset]), idx = 500);
  end;
end;

procedure TTestCase_SearchEdge.Test_BytesIndexOf_Cross_Implementation_Validation;
var
  hay, ned: TBytes;
  idxScalar, idxCurrent: PtrInt;
  i, testCase: Integer;
  testSizes: array[0..4] of SizeUInt;
  needleSizes: array[0..6] of SizeUInt;
  ts, ns: Integer;
begin
  testSizes[0] := 64;
  testSizes[1] := 128;
  testSizes[2] := 256;
  testSizes[3] := 512;
  testSizes[4] := 1024;
  
  needleSizes[0] := 1;
  needleSizes[1] := 8;
  needleSizes[2] := 15;
  needleSizes[3] := 16;
  needleSizes[4] := 17;
  needleSizes[5] := 32;
  needleSizes[6] := 64;
  
  for ts := 0 to High(testSizes) do
  begin
    for ns := 0 to High(needleSizes) do
    begin
      if needleSizes[ns] > testSizes[ts] then Continue;
      
      SetLength(hay, testSizes[ts]);
      SetLength(ned, needleSizes[ns]);
      
      for testCase := 0 to 2 do
      begin
        // Generate different test patterns
        case testCase of
          0: // Random-like pattern
            begin
              for i := 0 to testSizes[ts] - 1 do
                hay[i] := Byte((i * 17 + 23) mod 256);
              for i := 0 to needleSizes[ns] - 1 do
                ned[i] := Byte((i * 13 + 47) mod 256);
            end;
          1: // Mostly same with differences
            begin
              for i := 0 to testSizes[ts] - 1 do
                hay[i] := Ord('M');
              for i := 0 to needleSizes[ns] - 1 do
                ned[i] := Ord('M');
              if needleSizes[ns] > 1 then
                ned[needleSizes[ns] - 1] := Ord('N');
            end;
          2: // Alternating pattern
            begin
              for i := 0 to testSizes[ts] - 1 do
                hay[i] := Byte(Ord('A') + (i mod 2));
              for i := 0 to needleSizes[ns] - 1 do
                ned[i] := Byte(Ord('C') + (i mod 3));
            end;
        end;
        
        // Place needle at middle position
        if testSizes[ts] >= needleSizes[ns] * 2 then
        begin
          Move(ned[0], hay[testSizes[ts] div 2], needleSizes[ns]);
          
          idxScalar := BytesIndexOf_Scalar(@hay[0], testSizes[ts], @ned[0], needleSizes[ns]);
          idxCurrent := BytesIndexOf(@hay[0], testSizes[ts], @ned[0], needleSizes[ns]);
          
          AssertTrue(Format('Cross-validation: size=%d needle=%d case=%d', 
            [testSizes[ts], needleSizes[ns], testCase]), idxScalar = idxCurrent);
        end;
      end;
    end;
  end;
end;

initialization
  RegisterTest(TTestCase_SearchEdge);

end.
