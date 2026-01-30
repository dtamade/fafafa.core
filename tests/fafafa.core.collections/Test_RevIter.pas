unit Test_RevIter;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.collections.base,
  fafafa.core.collections.vec,
  fafafa.core.collections.iterators;

type
  TIntVec = specialize TVec<Integer>;
  TIntIter = specialize TIter<Integer>;
  TIntRevIter = specialize TRevIter<Integer>;

  { TTestRevIter }
  TTestRevIter = class(TTestCase)
  published
    // 基本功能
    procedure Test_RevIter_EmptyVec_NoElements;
    procedure Test_RevIter_SingleElement_ReturnsIt;
    procedure Test_RevIter_MultipleElements_ReversesOrder;
    
    // 边界条件
    procedure Test_RevIter_TwoElements_CorrectOrder;
    procedure Test_RevIter_LargeVec_CorrectReverse;
    
    // 迭代器组合
    procedure Test_RevIter_WithTake_FirstNFromEnd;
    procedure Test_RevIter_WithSkip_SkipsFromEnd;
    procedure Test_RevIter_DoubleReverse_OriginalOrder;
  end;

implementation

{ TTestRevIter }

procedure TTestRevIter.Test_RevIter_EmptyVec_NoElements;
var
  V: TIntVec;
  RevIt: TIntRevIter;
  Count: Integer;
begin
  V := TIntVec.Create;
  try
    RevIt := TIntRevIter.Create(V.Iter);
    Count := 0;
    while RevIt.MoveNext do
      Inc(Count);
    AssertEquals('Empty vec should have no elements', 0, Count);
  finally
    V.Free;
  end;
end;

procedure TTestRevIter.Test_RevIter_SingleElement_ReturnsIt;
var
  V: TIntVec;
  RevIt: TIntRevIter;
begin
  V := TIntVec.Create;
  try
    V.Push(42);
    RevIt := TIntRevIter.Create(V.Iter);
    
    AssertTrue('Should have one element', RevIt.MoveNext);
    AssertEquals('Should be 42', 42, RevIt.Current);
    AssertFalse('Should have no more elements', RevIt.MoveNext);
  finally
    V.Free;
  end;
end;

procedure TTestRevIter.Test_RevIter_MultipleElements_ReversesOrder;
var
  V: TIntVec;
  RevIt: TIntRevIter;
  Expected: array[0..4] of Integer = (5, 4, 3, 2, 1);
  I: Integer;
begin
  V := TIntVec.Create;
  try
    V.LoadFrom([1, 2, 3, 4, 5]);
    RevIt := TIntRevIter.Create(V.Iter);
    
    I := 0;
    while RevIt.MoveNext do
    begin
      AssertEquals('Element ' + IntToStr(I), Expected[I], RevIt.Current);
      Inc(I);
    end;
    AssertEquals('Should have 5 elements', 5, I);
  finally
    V.Free;
  end;
end;

procedure TTestRevIter.Test_RevIter_TwoElements_CorrectOrder;
var
  V: TIntVec;
  RevIt: TIntRevIter;
begin
  V := TIntVec.Create;
  try
    V.LoadFrom([10, 20]);
    RevIt := TIntRevIter.Create(V.Iter);
    
    AssertTrue(RevIt.MoveNext);
    AssertEquals('First should be 20', 20, RevIt.Current);
    AssertTrue(RevIt.MoveNext);
    AssertEquals('Second should be 10', 10, RevIt.Current);
    AssertFalse(RevIt.MoveNext);
  finally
    V.Free;
  end;
end;

procedure TTestRevIter.Test_RevIter_LargeVec_CorrectReverse;
var
  V: TIntVec;
  RevIt: TIntRevIter;
  I, Expected: Integer;
begin
  V := TIntVec.Create;
  try
    // 创建 0..99
    for I := 0 to 99 do
      V.Push(I);
    
    RevIt := TIntRevIter.Create(V.Iter);
    Expected := 99;
    while RevIt.MoveNext do
    begin
      AssertEquals('Element', Expected, RevIt.Current);
      Dec(Expected);
    end;
    AssertEquals('Should iterate all 100 elements', -1, Expected);
  finally
    V.Free;
  end;
end;

procedure TTestRevIter.Test_RevIter_WithTake_FirstNFromEnd;
var
  V: TIntVec;
  RevIt: TIntRevIter;
  Count: Integer;
begin
  // Test taking first 3 elements from reverse iteration manually
  // (ToIter not supported for record-based iterators)
  V := TIntVec.Create;
  try
    V.LoadFrom([1, 2, 3, 4, 5]);
    RevIt := TIntRevIter.Create(V.Iter);
    
    // Take 3 from reverse: should get 5, 4, 3
    Count := 0;
    
    AssertTrue(RevIt.MoveNext);
    AssertEquals(5, RevIt.Current);
    Inc(Count);
    
    AssertTrue(RevIt.MoveNext);
    AssertEquals(4, RevIt.Current);
    Inc(Count);
    
    AssertTrue(RevIt.MoveNext);
    AssertEquals(3, RevIt.Current);
    Inc(Count);
    
    // Manually stop at 3 (simulating Take(3))
    AssertEquals(3, Count);
  finally
    V.Free;
  end;
end;

procedure TTestRevIter.Test_RevIter_WithSkip_SkipsFromEnd;
var
  V: TIntVec;
  RevIt: TIntRevIter;
  SkipCount: Integer;
begin
  // Test skipping first 2 elements from reverse iteration manually
  // (ToIter not supported for record-based iterators)
  V := TIntVec.Create;
  try
    V.LoadFrom([1, 2, 3, 4, 5]);
    RevIt := TIntRevIter.Create(V.Iter);
    
    // Skip 2 from reverse (5, 4)
    SkipCount := 0;
    while (SkipCount < 2) and RevIt.MoveNext do
      Inc(SkipCount);
    
    // Now should get 3, 2, 1
    AssertTrue(RevIt.MoveNext);
    AssertEquals(3, RevIt.Current);
    
    AssertTrue(RevIt.MoveNext);
    AssertEquals(2, RevIt.Current);
    
    AssertTrue(RevIt.MoveNext);
    AssertEquals(1, RevIt.Current);
    
    AssertFalse(RevIt.MoveNext);
  finally
    V.Free;
  end;
end;

procedure TTestRevIter.Test_RevIter_DoubleReverse_OriginalOrder;
var
  V, V2: TIntVec;
  Rev1, Rev2: TIntRevIter;
  Expected: array[0..4] of Integer = (1, 2, 3, 4, 5);
  I: Integer;
begin
  // Test double reverse by collecting first reverse into a new Vec,
  // then reversing that (ToIter not supported for record-based iterators)
  V := TIntVec.Create;
  V2 := TIntVec.Create;
  try
    V.LoadFrom([1, 2, 3, 4, 5]);
    
    // First reverse: collect into V2
    Rev1 := TIntRevIter.Create(V.Iter);
    while Rev1.MoveNext do
      V2.Push(Rev1.Current);
    // V2 now has [5, 4, 3, 2, 1]
    
    // Second reverse
    Rev2 := TIntRevIter.Create(V2.Iter);
    
    // Double reverse should restore original order
    I := 0;
    while Rev2.MoveNext do
    begin
      AssertEquals('Element ' + IntToStr(I), Expected[I], Rev2.Current);
      Inc(I);
    end;
    AssertEquals(5, I);
  finally
    V2.Free;
    V.Free;
  end;
end;

initialization
  RegisterTest(TTestRevIter);

end.
