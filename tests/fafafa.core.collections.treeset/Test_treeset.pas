unit Test_treeset;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections,
  fafafa.core.collections.treeSet;

type
  TTestTreeSet = class(TTestCase)
  published
    procedure TestBasicOperations;
    procedure TestContains;
    procedure TestDelete;
    procedure TestClear;
    procedure TestOrdered;
    procedure TestEdgeCases;
    procedure TestLargeDataSet;
    procedure TestFactoryFunction;
  end;

implementation

type
  TIntTreeSet = specialize TTreeSet<Integer>;
  IIntTreeSet = specialize ITreeSet<Integer>;

procedure TTestTreeSet.TestBasicOperations;
var
  LTreeSet: TIntTreeSet;
begin
  LTreeSet := TIntTreeSet.Create;
  try
    AssertTrue('New TreeSet should be empty', LTreeSet.IsEmpty);
    AssertEquals('New TreeSet should have count 0', 0, LTreeSet.GetCount());
    
    // Test Add
    AssertTrue('Should add 5', LTreeSet.Add(5));
    AssertEquals('Count should be 1 after add', 1, LTreeSet.GetCount());
    AssertTrue('Should contain 5', LTreeSet.Contains(5));
    AssertFalse('Should not add duplicate 5', LTreeSet.Add(5));
    AssertEquals('Count should still be 1', 1, LTreeSet.GetCount());
    
    // Test multiple adds
    LTreeSet.Add(3);
    LTreeSet.Add(7);
    LTreeSet.Add(1);
    LTreeSet.Add(9);
    AssertEquals('Count should be 5', 5, LTreeSet.GetCount());
  finally
    LTreeSet.Free;
  end;
end;

procedure TTestTreeSet.TestContains;
var
  LTreeSet: TIntTreeSet;
begin
  LTreeSet := TIntTreeSet.Create;
  try
    LTreeSet.Add(10);
    LTreeSet.Add(20);
    LTreeSet.Add(30);
    
    AssertTrue('Should contain 10', LTreeSet.Contains(10));
    AssertTrue('Should contain 20', LTreeSet.Contains(20));
    AssertTrue('Should contain 30', LTreeSet.Contains(30));
    AssertFalse('Should not contain 15', LTreeSet.Contains(15));
    AssertFalse('Should not contain 0', LTreeSet.Contains(0));
  finally
    LTreeSet.Free;
  end;
end;

procedure TTestTreeSet.TestDelete;
var
  LTreeSet: TIntTreeSet;
begin
  LTreeSet := TIntTreeSet.Create;
  try
    LTreeSet.Add(5);
    LTreeSet.Add(3);
    LTreeSet.Add(7);
    LTreeSet.Add(1);
    LTreeSet.Add(9);
    
    AssertEquals('Initial count should be 5', 5, LTreeSet.GetCount());
    
    // Delete existing element
    AssertTrue('Should delete 3', LTreeSet.Remove(3));
    AssertEquals('Count should be 4 after delete', 4, LTreeSet.GetCount());
    AssertFalse('Should not contain 3 after delete', LTreeSet.Contains(3));
    
    // Try to delete non-existing element
    AssertFalse('Should not delete non-existing element', LTreeSet.Remove(100));
    AssertEquals('Count should still be 4', 4, LTreeSet.GetCount());
    
    // Delete all elements
    LTreeSet.Remove(5);
    LTreeSet.Remove(7);
    LTreeSet.Remove(1);
    LTreeSet.Remove(9);
    AssertTrue('TreeSet should be empty after deleting all', LTreeSet.IsEmpty);
  finally
    LTreeSet.Free;
  end;
end;

procedure TTestTreeSet.TestClear;
var
  LTreeSet: TIntTreeSet;
begin
  LTreeSet := TIntTreeSet.Create;
  try
    LTreeSet.Add(1);
    LTreeSet.Add(2);
    LTreeSet.Add(3);
    LTreeSet.Add(4);
    LTreeSet.Add(5);
    
    AssertEquals('Count should be 5 before clear', 5, LTreeSet.GetCount());
    LTreeSet.Clear;
    AssertTrue('TreeSet should be empty after clear', LTreeSet.IsEmpty);
    AssertEquals('Count should be 0 after clear', 0, LTreeSet.GetCount());
    
    // Test adding after clear
    LTreeSet.Add(10);
    AssertEquals('Count should be 1 after add post-clear', 1, LTreeSet.GetCount());
    AssertTrue('Should contain 10 after clear and add', LTreeSet.Contains(10));
  finally
    LTreeSet.Free;
  end;
end;

procedure TTestTreeSet.TestOrdered;
var
  LTreeSet: TIntTreeSet;
  LArr: array of Integer;
  LI: Integer;
begin
  LTreeSet := TIntTreeSet.Create;
  try
    // Add in random order
    LTreeSet.Add(5);
    LTreeSet.Add(2);
    LTreeSet.Add(8);
    LTreeSet.Add(1);
    LTreeSet.Add(9);
    LTreeSet.Add(3);
    
    LArr := LTreeSet.ToArray;
    
    // Check if array is sorted
    for LI := 0 to High(LArr) - 1 do
      AssertTrue('Array should be sorted', LArr[LI] < LArr[LI + 1]);
    
    AssertEquals('First element should be 1', 1, LArr[0]);
    AssertEquals('Last element should be 9', 9, LArr[High(LArr)]);
  finally
    LTreeSet.Free;
  end;
end;

procedure TTestTreeSet.TestEdgeCases;
var
  LTreeSet: TIntTreeSet;
begin
  LTreeSet := TIntTreeSet.Create;
  try
    // Test with single element
    LTreeSet.Add(42);
    AssertEquals('Count should be 1', 1, LTreeSet.GetCount());
    AssertTrue('Should contain 42', LTreeSet.Contains(42));
    LTreeSet.Remove(42);
    AssertTrue('Should be empty after deleting only element', LTreeSet.IsEmpty);
    
    // Test delete from empty
    AssertFalse('Should return false when deleting from empty set', LTreeSet.Remove(1));
    
    // Test contains on empty
    AssertFalse('Empty set should not contain any element', LTreeSet.Contains(1));
  finally
    LTreeSet.Free;
  end;
end;

procedure TTestTreeSet.TestLargeDataSet;
var
  LTreeSet: TIntTreeSet;
  LI: Integer;
begin
  LTreeSet := TIntTreeSet.Create;
  try
    // Add 1000 elements
    for LI := 1 to 1000 do
      LTreeSet.Add(LI);
    
    AssertEquals('Count should be 1000', 1000, LTreeSet.GetCount());
    
    // Check all elements exist
    for LI := 1 to 1000 do
      AssertTrue(Format('Should contain %d', [LI]), LTreeSet.Contains(LI));
    
    // Delete half
    for LI := 1 to 500 do
      LTreeSet.Remove(LI);
    
    AssertEquals('Count should be 500 after deleting half', 500, LTreeSet.GetCount());
    
    // Check deleted elements don't exist
    for LI := 1 to 500 do
      AssertFalse(Format('Should not contain %d', [LI]), LTreeSet.Contains(LI));
    
    // Check remaining elements exist
    for LI := 501 to 1000 do
      AssertTrue(Format('Should still contain %d', [LI]), LTreeSet.Contains(LI));
  finally
    LTreeSet.Free;
  end;
end;

procedure TTestTreeSet.TestFactoryFunction;
var
  LTreeSet: IIntTreeSet;
  LArr: array of Integer;
begin
  LTreeSet := specialize MakeTreeSet<Integer>();
  
  AssertTrue('New TreeSet should be empty', LTreeSet.IsEmpty);
  
  // Test basic operations through interface
  AssertTrue('Should add 5', LTreeSet.Add(5));
  AssertTrue('Should add 3', LTreeSet.Add(3));
  AssertTrue('Should add 7', LTreeSet.Add(7));
  
  AssertEquals('Count should be 3', 3, LTreeSet.GetCount());
  AssertTrue('Should contain 5', LTreeSet.Contains(5));
  
  LArr := LTreeSet.ToArray;
  AssertEquals('First element should be 3', 3, LArr[0]);
  AssertEquals('Second element should be 5', 5, LArr[1]);
  AssertEquals('Third element should be 7', 7, LArr[2]);
end;

initialization
  RegisterTest(TTestTreeSet);

end.

