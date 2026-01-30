unit Test_SkipList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.skiplist;

type
  TIntSkipList = specialize TSkipList<Integer, string>;

  { TTestSkipList }
  TTestSkipList = class(TTestCase)
  protected
    FList: TIntSkipList;
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基本操作
    procedure Test_Empty_CountIsZero;
    procedure Test_Put_SingleElement;
    procedure Test_Put_MultipleElements;
    procedure Test_Put_UpdateExisting;
    procedure Test_Get_ExistingKey;
    procedure Test_Get_NonExistingKey;
    procedure Test_ContainsKey_True;
    procedure Test_ContainsKey_False;
    procedure Test_Remove_ExistingKey;
    procedure Test_Remove_NonExistingKey;
    procedure Test_Clear_EmptiesAll;
    
    // 有序性
    procedure Test_OrderedIteration;
    procedure Test_Min_ReturnsSmallest;
    procedure Test_Max_ReturnsLargest;
    
    // 范围查询
    procedure Test_Range_ReturnsInOrder;
  end;

implementation

{ TTestSkipList }

procedure TTestSkipList.SetUp;
begin
  FList := TIntSkipList.Create;
end;

procedure TTestSkipList.TearDown;
begin
  FList.Free;
end;

procedure TTestSkipList.Test_Empty_CountIsZero;
begin
  AssertEquals('Empty list count', 0, FList.Count);
  AssertTrue('Empty list IsEmpty', FList.IsEmpty);
end;

procedure TTestSkipList.Test_Put_SingleElement;
begin
  FList.Put(42, 'forty-two');
  AssertEquals('Count after put', 1, FList.Count);
  AssertFalse('Not empty after put', FList.IsEmpty);
end;

procedure TTestSkipList.Test_Put_MultipleElements;
begin
  FList.Put(3, 'three');
  FList.Put(1, 'one');
  FList.Put(4, 'four');
  FList.Put(1, 'ONE'); // duplicate key
  FList.Put(5, 'five');
  
  AssertEquals('Count with duplicates', 4, FList.Count);
end;

procedure TTestSkipList.Test_Put_UpdateExisting;
var
  Value: string;
begin
  FList.Put(10, 'ten');
  FList.Put(10, 'TEN');
  
  AssertEquals('Count unchanged', 1, FList.Count);
  AssertTrue('Get updated value', FList.Get(10, Value));
  AssertEquals('Value is updated', 'TEN', Value);
end;

procedure TTestSkipList.Test_Get_ExistingKey;
var
  Value: string;
begin
  FList.Put(100, 'hundred');
  
  AssertTrue('Get returns true', FList.Get(100, Value));
  AssertEquals('Value correct', 'hundred', Value);
end;

procedure TTestSkipList.Test_Get_NonExistingKey;
var
  Value: string;
begin
  FList.Put(1, 'one');
  
  AssertFalse('Get non-existing returns false', FList.Get(999, Value));
end;

procedure TTestSkipList.Test_ContainsKey_True;
begin
  FList.Put(50, 'fifty');
  AssertTrue('Contains existing key', FList.ContainsKey(50));
end;

procedure TTestSkipList.Test_ContainsKey_False;
begin
  FList.Put(50, 'fifty');
  AssertFalse('Does not contain missing key', FList.ContainsKey(51));
end;

procedure TTestSkipList.Test_Remove_ExistingKey;
begin
  FList.Put(7, 'seven');
  FList.Put(8, 'eight');
  
  AssertTrue('Remove returns true', FList.Remove(7));
  AssertEquals('Count after remove', 1, FList.Count);
  AssertFalse('Key no longer exists', FList.ContainsKey(7));
end;

procedure TTestSkipList.Test_Remove_NonExistingKey;
begin
  FList.Put(1, 'one');
  
  AssertFalse('Remove non-existing returns false', FList.Remove(999));
  AssertEquals('Count unchanged', 1, FList.Count);
end;

procedure TTestSkipList.Test_Clear_EmptiesAll;
begin
  FList.Put(1, 'one');
  FList.Put(2, 'two');
  FList.Put(3, 'three');
  
  FList.Clear;
  
  AssertEquals('Count after clear', 0, FList.Count);
  AssertTrue('IsEmpty after clear', FList.IsEmpty);
end;

procedure TTestSkipList.Test_OrderedIteration;
var
  Keys: array of Integer;
  Entries: TIntSkipList.TEntryArray;
  i: Integer;
begin
  // Insert in random order
  FList.Put(5, 'five');
  FList.Put(2, 'two');
  FList.Put(8, 'eight');
  FList.Put(1, 'one');
  FList.Put(9, 'nine');
  FList.Put(3, 'three');
  
  Entries := FList.ToArray;
  SetLength(Keys, Length(Entries));
  for i := 0 to High(Entries) do
    Keys[i] := Entries[i].Key;
  
  // Verify ascending order
  AssertEquals('First key', 1, Keys[0]);
  AssertEquals('Second key', 2, Keys[1]);
  AssertEquals('Third key', 3, Keys[2]);
  AssertEquals('Fourth key', 5, Keys[3]);
  AssertEquals('Fifth key', 8, Keys[4]);
  AssertEquals('Sixth key', 9, Keys[5]);
end;

procedure TTestSkipList.Test_Min_ReturnsSmallest;
var
  Key: Integer;
  Value: string;
begin
  FList.Put(50, 'fifty');
  FList.Put(10, 'ten');
  FList.Put(30, 'thirty');
  
  AssertTrue('Min exists', FList.Min(Key, Value));
  AssertEquals('Min key', 10, Key);
  AssertEquals('Min value', 'ten', Value);
end;

procedure TTestSkipList.Test_Max_ReturnsLargest;
var
  Key: Integer;
  Value: string;
begin
  FList.Put(50, 'fifty');
  FList.Put(10, 'ten');
  FList.Put(30, 'thirty');
  
  AssertTrue('Max exists', FList.Max(Key, Value));
  AssertEquals('Max key', 50, Key);
  AssertEquals('Max value', 'fifty', Value);
end;

procedure TTestSkipList.Test_Range_ReturnsInOrder;
var
  Entries: TIntSkipList.TEntryArray;
begin
  FList.Put(1, 'one');
  FList.Put(2, 'two');
  FList.Put(3, 'three');
  FList.Put(4, 'four');
  FList.Put(5, 'five');
  
  // Range [2, 4]
  Entries := FList.Range(2, 4);
  
  AssertEquals('Range count', 3, Length(Entries));
  AssertEquals('Range first', 2, Entries[0].Key);
  AssertEquals('Range second', 3, Entries[1].Key);
  AssertEquals('Range third', 4, Entries[2].Key);
end;

initialization
  RegisterTest(TTestSkipList);
end.
