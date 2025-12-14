unit Test_MultiSet;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.collections.base,
  fafafa.core.collections.multiset;

type
  TIntMultiSet = specialize TMultiSet<Integer>;

  { TTestMultiSet }
  TTestMultiSet = class(TTestCase)
  published
    // 基本操作
    procedure Test_Create_Empty;
    procedure Test_Add_SingleElement;
    procedure Test_Add_DuplicateElements;
    procedure Test_CountOf_Existing;
    procedure Test_CountOf_NotExisting;
    procedure Test_Remove_DecreasesCount;
    procedure Test_Remove_NonExisting;
    procedure Test_RemoveAll_RemovesCompletely;
    procedure Test_Contains_Existing;
    procedure Test_Contains_NotExisting;
    
    // 属性和迭代
    procedure Test_Count_ReturnsUniqueCount;
    procedure Test_TotalCount_ReturnsAllElements;
    procedure Test_Clear_RemovesAll;
    
    // 集合运算
    procedure Test_Union_MergesCounts;
    procedure Test_Intersection_TakesMinCount;
  end;

implementation

{ TTestMultiSet }

procedure TTestMultiSet.Test_Create_Empty;
var
  MS: TIntMultiSet;
begin
  MS := TIntMultiSet.Create;
  try
    AssertEquals('Empty multiset has count 0', 0, MS.Count);
    AssertEquals('Empty multiset has total count 0', 0, MS.TotalCount);
  finally
    MS.Free;
  end;
end;

procedure TTestMultiSet.Test_Add_SingleElement;
var
  MS: TIntMultiSet;
begin
  MS := TIntMultiSet.Create;
  try
    MS.Add(42);
    AssertEquals('Count is 1', 1, MS.Count);
    AssertEquals('TotalCount is 1', 1, MS.TotalCount);
    AssertEquals('CountOf(42) is 1', 1, MS.CountOf(42));
  finally
    MS.Free;
  end;
end;

procedure TTestMultiSet.Test_Add_DuplicateElements;
var
  MS: TIntMultiSet;
begin
  MS := TIntMultiSet.Create;
  try
    MS.Add(42);
    MS.Add(42);
    MS.Add(42);
    AssertEquals('Count is 1 (unique)', 1, MS.Count);
    AssertEquals('TotalCount is 3', 3, MS.TotalCount);
    AssertEquals('CountOf(42) is 3', 3, MS.CountOf(42));
  finally
    MS.Free;
  end;
end;

procedure TTestMultiSet.Test_CountOf_Existing;
var
  MS: TIntMultiSet;
begin
  MS := TIntMultiSet.Create;
  try
    MS.Add(1);
    MS.Add(2);
    MS.Add(2);
    MS.Add(3);
    MS.Add(3);
    MS.Add(3);
    AssertEquals('CountOf(1)', 1, MS.CountOf(1));
    AssertEquals('CountOf(2)', 2, MS.CountOf(2));
    AssertEquals('CountOf(3)', 3, MS.CountOf(3));
  finally
    MS.Free;
  end;
end;

procedure TTestMultiSet.Test_CountOf_NotExisting;
var
  MS: TIntMultiSet;
begin
  MS := TIntMultiSet.Create;
  try
    MS.Add(1);
    AssertEquals('CountOf(999) is 0', 0, MS.CountOf(999));
  finally
    MS.Free;
  end;
end;

procedure TTestMultiSet.Test_Remove_DecreasesCount;
var
  MS: TIntMultiSet;
begin
  MS := TIntMultiSet.Create;
  try
    MS.Add(42);
    MS.Add(42);
    MS.Add(42);
    
    AssertTrue('Remove returns true', MS.Remove(42));
    AssertEquals('CountOf(42) is 2', 2, MS.CountOf(42));
    
    AssertTrue('Remove returns true', MS.Remove(42));
    AssertEquals('CountOf(42) is 1', 1, MS.CountOf(42));
    
    AssertTrue('Remove returns true', MS.Remove(42));
    AssertEquals('CountOf(42) is 0', 0, MS.CountOf(42));
    AssertFalse('Contains returns false', MS.Contains(42));
  finally
    MS.Free;
  end;
end;

procedure TTestMultiSet.Test_Remove_NonExisting;
var
  MS: TIntMultiSet;
begin
  MS := TIntMultiSet.Create;
  try
    AssertFalse('Remove non-existing returns false', MS.Remove(999));
  finally
    MS.Free;
  end;
end;

procedure TTestMultiSet.Test_RemoveAll_RemovesCompletely;
var
  MS: TIntMultiSet;
begin
  MS := TIntMultiSet.Create;
  try
    MS.Add(42);
    MS.Add(42);
    MS.Add(42);
    
    AssertEquals('RemoveAll returns 3', 3, MS.RemoveAll(42));
    AssertEquals('CountOf(42) is 0', 0, MS.CountOf(42));
    AssertFalse('Contains returns false', MS.Contains(42));
  finally
    MS.Free;
  end;
end;

procedure TTestMultiSet.Test_Contains_Existing;
var
  MS: TIntMultiSet;
begin
  MS := TIntMultiSet.Create;
  try
    MS.Add(42);
    AssertTrue('Contains 42', MS.Contains(42));
  finally
    MS.Free;
  end;
end;

procedure TTestMultiSet.Test_Contains_NotExisting;
var
  MS: TIntMultiSet;
begin
  MS := TIntMultiSet.Create;
  try
    MS.Add(42);
    AssertFalse('Does not contain 999', MS.Contains(999));
  finally
    MS.Free;
  end;
end;

procedure TTestMultiSet.Test_Count_ReturnsUniqueCount;
var
  MS: TIntMultiSet;
begin
  MS := TIntMultiSet.Create;
  try
    MS.Add(1);
    MS.Add(1);
    MS.Add(2);
    MS.Add(3);
    MS.Add(3);
    MS.Add(3);
    AssertEquals('Count is 3 (unique elements)', 3, MS.Count);
  finally
    MS.Free;
  end;
end;

procedure TTestMultiSet.Test_TotalCount_ReturnsAllElements;
var
  MS: TIntMultiSet;
begin
  MS := TIntMultiSet.Create;
  try
    MS.Add(1);      // 1
    MS.Add(1);      // 2
    MS.Add(2);      // 3
    MS.Add(3);      // 4
    MS.Add(3);      // 5
    MS.Add(3);      // 6
    AssertEquals('TotalCount is 6', 6, MS.TotalCount);
  finally
    MS.Free;
  end;
end;

procedure TTestMultiSet.Test_Clear_RemovesAll;
var
  MS: TIntMultiSet;
begin
  MS := TIntMultiSet.Create;
  try
    MS.Add(1);
    MS.Add(2);
    MS.Add(2);
    MS.Clear;
    AssertEquals('Count is 0 after clear', 0, MS.Count);
    AssertEquals('TotalCount is 0 after clear', 0, MS.TotalCount);
  finally
    MS.Free;
  end;
end;

procedure TTestMultiSet.Test_Union_MergesCounts;
var
  MS1, MS2, Result: TIntMultiSet;
begin
  MS1 := TIntMultiSet.Create;
  MS2 := TIntMultiSet.Create;
  try
    MS1.Add(1); MS1.Add(1);  // 1->2
    MS1.Add(2);              // 2->1
    
    MS2.Add(1);              // 1->1
    MS2.Add(2); MS2.Add(2);  // 2->2
    MS2.Add(3);              // 3->1
    
    Result := MS1.Union(MS2);
    try
      // Union takes max count for each element
      AssertEquals('Union CountOf(1)', 2, Result.CountOf(1));
      AssertEquals('Union CountOf(2)', 2, Result.CountOf(2));
      AssertEquals('Union CountOf(3)', 1, Result.CountOf(3));
    finally
      Result.Free;
    end;
  finally
    MS2.Free;
    MS1.Free;
  end;
end;

procedure TTestMultiSet.Test_Intersection_TakesMinCount;
var
  MS1, MS2, Result: TIntMultiSet;
begin
  MS1 := TIntMultiSet.Create;
  MS2 := TIntMultiSet.Create;
  try
    MS1.Add(1); MS1.Add(1); MS1.Add(1);  // 1->3
    MS1.Add(2); MS1.Add(2);              // 2->2
    MS1.Add(3);                          // 3->1 (not in MS2)
    
    MS2.Add(1); MS2.Add(1);              // 1->2
    MS2.Add(2); MS2.Add(2); MS2.Add(2);  // 2->3
    MS2.Add(4);                          // 4->1 (not in MS1)
    
    Result := MS1.Intersection(MS2);
    try
      // Intersection takes min count for common elements
      AssertEquals('Intersection CountOf(1)', 2, Result.CountOf(1));
      AssertEquals('Intersection CountOf(2)', 2, Result.CountOf(2));
      AssertEquals('Intersection CountOf(3)', 0, Result.CountOf(3));
      AssertEquals('Intersection CountOf(4)', 0, Result.CountOf(4));
    finally
      Result.Free;
    end;
  finally
    MS2.Free;
    MS1.Free;
  end;
end;

initialization
  RegisterTest(TTestMultiSet);

end.
