unit Test_BitSet_Performance;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.collections.bitset;

type
  TTestBitSetPerformance = class(TTestCase)
  published
    { PopCount correctness tests }
    procedure Test_PopCount_Empty_ReturnsZero;
    procedure Test_PopCount_AllOnes_ReturnsCorrect;
    procedure Test_PopCount_Sparse_ReturnsCorrect;
    procedure Test_PopCount_PatternAA_ReturnsCorrect;
    procedure Test_PopCount_Pattern55_ReturnsCorrect;
    procedure Test_PopCount_SingleBit_ReturnsOne;
    procedure Test_PopCount_LargeSet_ReturnsCorrect;
    
    { Batch operations correctness }
    procedure Test_AndWith_Correctness;
    procedure Test_OrWith_Correctness;
    procedure Test_XorWith_Correctness;
  end;

implementation

{ PopCount tests }

procedure TTestBitSetPerformance.Test_PopCount_Empty_ReturnsZero;
var
  BS: IBitSet;
begin
  BS := TBitSet.Create(1024);
  AssertEquals('Empty set should have cardinality 0', 0, BS.Cardinality);
end;

procedure TTestBitSetPerformance.Test_PopCount_AllOnes_ReturnsCorrect;
var
  BS: IBitSet;
  i: SizeUInt;
begin
  BS := TBitSet.Create(64);
  for i := 0 to 63 do
    BS.SetBit(i);
  AssertEquals('All 64 bits set should have cardinality 64', 64, BS.Cardinality);
end;

procedure TTestBitSetPerformance.Test_PopCount_Sparse_ReturnsCorrect;
var
  BS: IBitSet;
begin
  BS := TBitSet.Create(256);
  BS.SetBit(0);
  BS.SetBit(63);
  BS.SetBit(64);
  BS.SetBit(127);
  BS.SetBit(255);
  AssertEquals('5 bits set should have cardinality 5', 5, BS.Cardinality);
end;

procedure TTestBitSetPerformance.Test_PopCount_PatternAA_ReturnsCorrect;
var
  BS: IBitSet;
  i: SizeUInt;
begin
  // Pattern 0xAA = 10101010 = 4 bits per byte, 32 bits per UInt64
  BS := TBitSet.Create(128);
  for i := 0 to 127 do
    if (i mod 2) = 1 then
      BS.SetBit(i);
  AssertEquals('Pattern 0xAA (128 bits) should have cardinality 64', 64, BS.Cardinality);
end;

procedure TTestBitSetPerformance.Test_PopCount_Pattern55_ReturnsCorrect;
var
  BS: IBitSet;
  i: SizeUInt;
begin
  // Pattern 0x55 = 01010101 = 4 bits per byte, 32 bits per UInt64
  BS := TBitSet.Create(128);
  for i := 0 to 127 do
    if (i mod 2) = 0 then
      BS.SetBit(i);
  AssertEquals('Pattern 0x55 (128 bits) should have cardinality 64', 64, BS.Cardinality);
end;

procedure TTestBitSetPerformance.Test_PopCount_SingleBit_ReturnsOne;
var
  BS: IBitSet;
  TestBits: array[0..5] of SizeUInt = (0, 1, 31, 32, 63, 64);
  i: Integer;
begin
  for i := Low(TestBits) to High(TestBits) do
  begin
    BS := TBitSet.Create(128);
    BS.SetBit(TestBits[i]);
    AssertEquals('Single bit at ' + IntToStr(TestBits[i]) + ' should have cardinality 1', 
                 1, BS.Cardinality);
  end;
end;

procedure TTestBitSetPerformance.Test_PopCount_LargeSet_ReturnsCorrect;
var
  BS: IBitSet;
  i: SizeUInt;
  Expected: SizeUInt;
begin
  BS := TBitSet.Create(10000);
  Expected := 0;
  
  // Set every 3rd bit
  for i := 0 to 9999 do
    if (i mod 3) = 0 then
    begin
      BS.SetBit(i);
      Inc(Expected);
    end;
  
  AssertEquals('Large set with every 3rd bit', Expected, BS.Cardinality);
end;

{ Batch operations tests }

procedure TTestBitSetPerformance.Test_AndWith_Correctness;
var
  A, B, R: IBitSet;
begin
  A := TBitSet.Create(128);
  B := TBitSet.Create(128);
  
  // A = bits 0-63
  // B = bits 32-95
  // A AND B = bits 32-63 (32 bits)
  
  A.SetBit(0);  A.SetBit(32); A.SetBit(63);
  B.SetBit(32); B.SetBit(63); B.SetBit(64);
  
  R := A.AndWith(B);
  
  AssertFalse('Bit 0 should NOT be in result', R.Test(0));
  AssertTrue('Bit 32 should be in result', R.Test(32));
  AssertTrue('Bit 63 should be in result', R.Test(63));
  AssertFalse('Bit 64 should NOT be in result', R.Test(64));
  AssertEquals('AND result cardinality', 2, R.Cardinality);
end;

procedure TTestBitSetPerformance.Test_OrWith_Correctness;
var
  A, B, R: IBitSet;
begin
  A := TBitSet.Create(128);
  B := TBitSet.Create(128);
  
  A.SetBit(0);  A.SetBit(32);
  B.SetBit(64); B.SetBit(96);
  
  R := A.OrWith(B);
  
  AssertTrue('Bit 0 should be in result', R.Test(0));
  AssertTrue('Bit 32 should be in result', R.Test(32));
  AssertTrue('Bit 64 should be in result', R.Test(64));
  AssertTrue('Bit 96 should be in result', R.Test(96));
  AssertEquals('OR result cardinality', 4, R.Cardinality);
end;

procedure TTestBitSetPerformance.Test_XorWith_Correctness;
var
  A, B, R: IBitSet;
begin
  A := TBitSet.Create(128);
  B := TBitSet.Create(128);
  
  A.SetBit(0);  A.SetBit(32); A.SetBit(64);
  B.SetBit(32); B.SetBit(64); B.SetBit(96);
  
  R := A.XorWith(B);
  
  AssertTrue('Bit 0 should be in result (only in A)', R.Test(0));
  AssertFalse('Bit 32 should NOT be in result (in both)', R.Test(32));
  AssertFalse('Bit 64 should NOT be in result (in both)', R.Test(64));
  AssertTrue('Bit 96 should be in result (only in B)', R.Test(96));
  AssertEquals('XOR result cardinality', 2, R.Cardinality);
end;

initialization
  RegisterTest(TTestBitSetPerformance);

end.
