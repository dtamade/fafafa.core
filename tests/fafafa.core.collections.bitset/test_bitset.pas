unit test_bitset;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.collections.base,
  fafafa.core.collections.bitset;

type
  TBitSetTest = class(TTestCase)
  published
    procedure TestSetClearTest;
    procedure TestDynamicExpansion;
    procedure TestFlipBit;
    procedure TestAndOperation;
    procedure TestOrOperation;
    procedure TestXorOperation;
    procedure TestNotOperation;
    procedure TestCardinality;
    procedure TestSetAllClearAll;
    procedure TestBoundaries;
    procedure TestLargeIndices;
    procedure TestEmptyBitSet;
    procedure TestCardinalityAfterOperations;
  end;

implementation

{ TBitSetTest }

procedure TBitSetTest.TestSetClearTest;
var
  LBitSet: IBitSet;
begin
  LBitSet := TBitSet.Create(128);
  
  // Initially all bits should be 0
  AssertFalse('Bit 0 should be clear initially', LBitSet.Test(0));
  AssertFalse('Bit 63 should be clear initially', LBitSet.Test(63));
  
  // Set bits
  LBitSet.SetBit(0);
  LBitSet.SetBit(10);
  LBitSet.SetBit(63);
  
  AssertTrue('Bit 0 should be set', LBitSet.Test(0));
  AssertTrue('Bit 10 should be set', LBitSet.Test(10));
  AssertTrue('Bit 63 should be set', LBitSet.Test(63));
  AssertFalse('Bit 5 should still be clear', LBitSet.Test(5));
  
  // Clear bits
  LBitSet.ClearBit(10);
  AssertFalse('Bit 10 should be cleared', LBitSet.Test(10));
  AssertTrue('Bit 0 should still be set', LBitSet.Test(0));
end;

procedure TBitSetTest.TestDynamicExpansion;
var
  LBitSet: IBitSet;
begin
  LBitSet := TBitSet.Create(64);
  
  AssertEquals('Initial capacity should be 64', 64, LBitSet.BitCapacity);
  
  // Set bit beyond initial capacity
  LBitSet.SetBit(200);
  
  AssertTrue('Bit 200 should be set', LBitSet.Test(200));
  AssertTrue('Capacity should have expanded', LBitSet.BitCapacity >= 200);
end;

procedure TBitSetTest.TestFlipBit;
var
  LBitSet: IBitSet;
begin
  LBitSet := TBitSet.Create;
  
  AssertFalse('Bit 5 initially clear', LBitSet.Test(5));
  
  LBitSet.Flip(5);
  AssertTrue('After flip, bit 5 should be set', LBitSet.Test(5));
  
  LBitSet.Flip(5);
  AssertFalse('After second flip, bit 5 should be clear', LBitSet.Test(5));
end;

procedure TBitSetTest.TestAndOperation;
var
  LSet1, LSet2, LResult: IBitSet;
begin
  LSet1 := TBitSet.Create;
  LSet2 := TBitSet.Create;
  
  // Set1: bits 0, 2, 4
  LSet1.SetBit(0);
  LSet1.SetBit(2);
  LSet1.SetBit(4);
  
  // Set2: bits 2, 4, 6
  LSet2.SetBit(2);
  LSet2.SetBit(4);
  LSet2.SetBit(6);
  
  LResult := LSet1.AndWith(LSet2);
  
  AssertFalse('AND result: bit 0 should be clear', LResult.Test(0));
  AssertTrue('AND result: bit 2 should be set', LResult.Test(2));
  AssertTrue('AND result: bit 4 should be set', LResult.Test(4));
  AssertFalse('AND result: bit 6 should be clear', LResult.Test(6));
  
  AssertEquals('AND result cardinality should be 2', 2, LResult.Cardinality);
end;

procedure TBitSetTest.TestOrOperation;
var
  LSet1, LSet2, LResult: IBitSet;
begin
  LSet1 := TBitSet.Create;
  LSet2 := TBitSet.Create;
  
  // Set1: bits 1, 3
  LSet1.SetBit(1);
  LSet1.SetBit(3);
  
  // Set2: bits 3, 5
  LSet2.SetBit(3);
  LSet2.SetBit(5);
  
  LResult := LSet1.OrWith(LSet2);
  
  AssertTrue('OR result: bit 1 should be set', LResult.Test(1));
  AssertTrue('OR result: bit 3 should be set', LResult.Test(3));
  AssertTrue('OR result: bit 5 should be set', LResult.Test(5));
  AssertFalse('OR result: bit 0 should be clear', LResult.Test(0));
  
  AssertEquals('OR result cardinality should be 3', 3, LResult.Cardinality);
end;

procedure TBitSetTest.TestXorOperation;
var
  LSet1, LSet2, LResult: IBitSet;
begin
  LSet1 := TBitSet.Create;
  LSet2 := TBitSet.Create;
  
  // Set1: bits 1, 2, 3
  LSet1.SetBit(1);
  LSet1.SetBit(2);
  LSet1.SetBit(3);
  
  // Set2: bits 2, 3, 4
  LSet2.SetBit(2);
  LSet2.SetBit(3);
  LSet2.SetBit(4);
  
  LResult := LSet1.XorWith(LSet2);
  
  AssertTrue('XOR result: bit 1 should be set', LResult.Test(1));
  AssertFalse('XOR result: bit 2 should be clear', LResult.Test(2));
  AssertFalse('XOR result: bit 3 should be clear', LResult.Test(3));
  AssertTrue('XOR result: bit 4 should be set', LResult.Test(4));
  
  AssertEquals('XOR result cardinality should be 2', 2, LResult.Cardinality);
end;

procedure TBitSetTest.TestNotOperation;
var
  LSet, LResult: IBitSet;
begin
  LSet := TBitSet.Create(128);
  
  LSet.SetBit(0);
  LSet.SetBit(63);
  
  LResult := LSet.NotBits;
  
  AssertFalse('NOT result: bit 0 should be clear', LResult.Test(0));
  AssertFalse('NOT result: bit 63 should be clear', LResult.Test(63));
  AssertTrue('NOT result: bit 1 should be set', LResult.Test(1));
  AssertTrue('NOT result: bit 62 should be set', LResult.Test(62));
end;

procedure TBitSetTest.TestCardinality;
var
  LBitSet: IBitSet;
  i: Integer;
begin
  LBitSet := TBitSet.Create;
  
  AssertEquals('Empty set cardinality should be 0', 0, LBitSet.Cardinality);
  
  // Set 10 bits
  for i := 0 to 9 do
    LBitSet.SetBit(i * 10);
  
  AssertEquals('After setting 10 bits, cardinality should be 10', 10, LBitSet.Cardinality);
  
  // Clear 3 bits
  LBitSet.ClearBit(0);
  LBitSet.ClearBit(20);
  LBitSet.ClearBit(40);
  
  AssertEquals('After clearing 3 bits, cardinality should be 7', 7, LBitSet.Cardinality);
end;

procedure TBitSetTest.TestSetAllClearAll;
var
  LBitSet: IBitSet;
begin
  LBitSet := TBitSet.Create(128);
  
  LBitSet.SetAll;
  
  AssertTrue('After SetAll, bit 0 should be set', LBitSet.Test(0));
  AssertTrue('After SetAll, bit 63 should be set', LBitSet.Test(63));
  AssertTrue('After SetAll, bit 127 should be set', LBitSet.Test(127));
  AssertEquals('After SetAll, cardinality should be 128', 128, LBitSet.Cardinality);
  
  LBitSet.ClearAll;
  
  AssertEquals('After ClearAll, cardinality should be 0', 0, LBitSet.Cardinality);
  AssertFalse('After ClearAll, bit 0 should be clear', LBitSet.Test(0));
end;

procedure TBitSetTest.TestBoundaries;
var
  LBitSet: IBitSet;
begin
  LBitSet := TBitSet.Create(128);
  
  // Test word boundaries (63, 64, 127, 128)
  LBitSet.SetBit(63);
  LBitSet.SetBit(64);
  LBitSet.SetBit(127);
  
  AssertTrue('Bit at word boundary (63) should be set', LBitSet.Test(63));
  AssertTrue('Bit at word boundary (64) should be set', LBitSet.Test(64));
  AssertTrue('Bit at word boundary (127) should be set', LBitSet.Test(127));
  
  AssertEquals('Cardinality should be 3', 3, LBitSet.Cardinality);
end;

procedure TBitSetTest.TestLargeIndices;
var
  LBitSet: IBitSet;
const
  LARGE_INDEX = 10000;
begin
  LBitSet := TBitSet.Create;
  
  LBitSet.SetBit(LARGE_INDEX);
  
  AssertTrue('Large index bit should be set', LBitSet.Test(LARGE_INDEX));
  AssertTrue('Capacity should accommodate large index', LBitSet.BitCapacity > LARGE_INDEX);
  AssertEquals('Cardinality should be 1', 1, LBitSet.Cardinality);
end;

procedure TBitSetTest.TestEmptyBitSet;
var
  LBitSet: IBitSet;
begin
  LBitSet := TBitSet.Create;
  
  AssertTrue('New BitSet should be empty', LBitSet.IsEmpty);
  AssertEquals('Empty BitSet count should be 0', 0, LBitSet.GetCount);
  
  LBitSet.SetBit(5);
  AssertFalse('BitSet with set bits should not be empty', LBitSet.IsEmpty);
  
  LBitSet.Clear;
  AssertTrue('Cleared BitSet should be empty', LBitSet.IsEmpty);
end;

procedure TBitSetTest.TestCardinalityAfterOperations;
var
  LSet1, LSet2: IBitSet;
  LAndResult, LOrResult: IBitSet;
begin
  LSet1 := TBitSet.Create;
  LSet2 := TBitSet.Create;
  
  // Set1: 5 bits
  LSet1.SetBit(0);
  LSet1.SetBit(1);
  LSet1.SetBit(2);
  LSet1.SetBit(3);
  LSet1.SetBit(4);
  
  AssertEquals('Set1 cardinality should be 5', 5, LSet1.Cardinality);
  
  // Set2: 3 bits (overlapping with Set1)
  LSet2.SetBit(2);
  LSet2.SetBit(3);
  LSet2.SetBit(5);
  
  AssertEquals('Set2 cardinality should be 3', 3, LSet2.Cardinality);
  
  // Test AND cardinality
  LAndResult := LSet1.AndWith(LSet2);
  AssertEquals('AND cardinality should be 2 (bits 2,3)', 2, LAndResult.Cardinality);
  
  // Test OR cardinality
  LOrResult := LSet1.OrWith(LSet2);
  AssertEquals('OR cardinality should be 6 (bits 0,1,2,3,4,5)', 6, LOrResult.Cardinality);
end;

initialization
  RegisterTest(TBitSetTest);

end.

