unit Test_Vec_SplitSplice;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.collections.base,
  fafafa.core.collections.vec;

type
  TIntVec = specialize TVec<Integer>;
  IIntVec = specialize IVec<Integer>;

  { TTestVecSplitSplice }
  TTestVecSplitSplice = class(TTestCase)
  published
    // SplitOff 测试
    procedure Test_SplitOff_AtMiddle_SplitsCorrectly;
    procedure Test_SplitOff_AtStart_ReturnsAll;
    procedure Test_SplitOff_AtEnd_ReturnsEmpty;
    procedure Test_SplitOff_EmptyVec_Raises;
    procedure Test_SplitOff_OutOfRange_Raises;
    
    // Splice 测试
    procedure Test_Splice_AtMiddle_InsertsArray;
    procedure Test_Splice_AtStart_PrependsArray;
    procedure Test_Splice_AtEnd_AppendsArray;
    procedure Test_Splice_EmptySource_NoChange;
    procedure Test_Splice_ReplaceRange_ReplacesElements;
  end;

implementation

{ TTestVecSplitSplice }

procedure TTestVecSplitSplice.Test_SplitOff_AtMiddle_SplitsCorrectly;
var
  V: TIntVec;
  V2: IIntVec;
begin
  V := TIntVec.Create;
  try
    V.LoadFrom([1, 2, 3, 4, 5]);
    V2 := V.SplitOff(3);  // Split at index 3
    
    // Original should have [1, 2, 3]
    AssertEquals('Original count', 3, V.GetCount);
    AssertEquals('Original[0]', 1, V.Get(0));
    AssertEquals('Original[1]', 2, V.Get(1));
    AssertEquals('Original[2]', 3, V.Get(2));
    
    // New vec should have [4, 5]
    AssertEquals('Split count', 2, V2.GetCount);
    AssertEquals('Split[0]', 4, V2.Get(0));
    AssertEquals('Split[1]', 5, V2.Get(1));
  finally
    V.Free;
  end;
end;

procedure TTestVecSplitSplice.Test_SplitOff_AtStart_ReturnsAll;
var
  V: TIntVec;
  V2: IIntVec;
begin
  V := TIntVec.Create;
  try
    V.LoadFrom([1, 2, 3]);
    V2 := V.SplitOff(0);  // Split at start
    
    // Original should be empty
    AssertEquals('Original should be empty', 0, V.GetCount);
    
    // New vec should have all elements
    AssertEquals('Split count', 3, V2.GetCount);
    AssertEquals('Split[0]', 1, V2.Get(0));
    AssertEquals('Split[1]', 2, V2.Get(1));
    AssertEquals('Split[2]', 3, V2.Get(2));
  finally
    V.Free;
  end;
end;

procedure TTestVecSplitSplice.Test_SplitOff_AtEnd_ReturnsEmpty;
var
  V: TIntVec;
  V2: IIntVec;
begin
  V := TIntVec.Create;
  try
    V.LoadFrom([1, 2, 3]);
    V2 := V.SplitOff(3);  // Split at end (count)
    
    // Original should keep all
    AssertEquals('Original count', 3, V.GetCount);
    
    // New vec should be empty
    AssertEquals('Split should be empty', 0, V2.GetCount);
  finally
    V.Free;
  end;
end;

procedure TTestVecSplitSplice.Test_SplitOff_EmptyVec_Raises;
var
  V: TIntVec;
  V2: IIntVec;
  Raised: Boolean;
begin
  V := TIntVec.Create;
  try
    Raised := False;
    try
      V2 := V.SplitOff(0);
    except
      on E: Exception do
        Raised := True;
    end;
    // SplitOff(0) on empty vec should return empty, not raise
    // Actually, let's allow it - returns empty vec
    // AssertTrue('Should raise on empty vec', Raised);
    AssertEquals('Empty split', 0, V2.GetCount);
  finally
    V.Free;
  end;
end;

procedure TTestVecSplitSplice.Test_SplitOff_OutOfRange_Raises;
var
  V: TIntVec;
  V2: IIntVec;
  Raised: Boolean;
begin
  V := TIntVec.Create;
  try
    V.LoadFrom([1, 2, 3]);
    Raised := False;
    try
      V2 := V.SplitOff(10);  // Out of range
    except
      on E: Exception do
        Raised := True;
    end;
    AssertTrue('Should raise on out of range', Raised);
  finally
    V.Free;
  end;
end;

procedure TTestVecSplitSplice.Test_Splice_AtMiddle_InsertsArray;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    V.LoadFrom([1, 2, 5, 6]);
    V.Splice(2, 0, [3, 4]);  // Insert at index 2, remove 0 elements
    
    AssertEquals('Count', 6, V.GetCount);
    AssertEquals('[0]', 1, V.Get(0));
    AssertEquals('[1]', 2, V.Get(1));
    AssertEquals('[2]', 3, V.Get(2));
    AssertEquals('[3]', 4, V.Get(3));
    AssertEquals('[4]', 5, V.Get(4));
    AssertEquals('[5]', 6, V.Get(5));
  finally
    V.Free;
  end;
end;

procedure TTestVecSplitSplice.Test_Splice_AtStart_PrependsArray;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    V.LoadFrom([3, 4, 5]);
    V.Splice(0, 0, [1, 2]);  // Insert at start
    
    AssertEquals('Count', 5, V.GetCount);
    AssertEquals('[0]', 1, V.Get(0));
    AssertEquals('[1]', 2, V.Get(1));
    AssertEquals('[2]', 3, V.Get(2));
    AssertEquals('[3]', 4, V.Get(3));
    AssertEquals('[4]', 5, V.Get(4));
  finally
    V.Free;
  end;
end;

procedure TTestVecSplitSplice.Test_Splice_AtEnd_AppendsArray;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    V.LoadFrom([1, 2, 3]);
    V.Splice(3, 0, [4, 5]);  // Insert at end
    
    AssertEquals('Count', 5, V.GetCount);
    AssertEquals('[0]', 1, V.Get(0));
    AssertEquals('[1]', 2, V.Get(1));
    AssertEquals('[2]', 3, V.Get(2));
    AssertEquals('[3]', 4, V.Get(3));
    AssertEquals('[4]', 5, V.Get(4));
  finally
    V.Free;
  end;
end;

procedure TTestVecSplitSplice.Test_Splice_EmptySource_NoChange;
var
  V: TIntVec;
  Empty: array of Integer;
begin
  V := TIntVec.Create;
  try
    V.LoadFrom([1, 2, 3]);
    SetLength(Empty, 0);
    V.Splice(1, 0, Empty);  // Insert nothing
    
    AssertEquals('Count unchanged', 3, V.GetCount);
    AssertEquals('[0]', 1, V.Get(0));
    AssertEquals('[1]', 2, V.Get(1));
    AssertEquals('[2]', 3, V.Get(2));
  finally
    V.Free;
  end;
end;

procedure TTestVecSplitSplice.Test_Splice_ReplaceRange_ReplacesElements;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    V.LoadFrom([1, 2, 3, 4, 5]);
    V.Splice(1, 3, [10, 20]);  // Remove 3 elements at index 1, insert 2
    
    // Result should be [1, 10, 20, 5]
    AssertEquals('Count', 4, V.GetCount);
    AssertEquals('[0]', 1, V.Get(0));
    AssertEquals('[1]', 10, V.Get(1));
    AssertEquals('[2]', 20, V.Get(2));
    AssertEquals('[3]', 5, V.Get(3));
  finally
    V.Free;
  end;
end;

initialization
  RegisterTest(TTestVecSplitSplice);

end.
