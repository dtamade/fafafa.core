unit test_linkedhashmap;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.collections.base,
  fafafa.core.collections.hashmap,
  fafafa.core.collections.linkedhashmap;

type
  TLinkedHashMapTest = class(TTestCase)
  published
    procedure TestInsertionOrderMaintained;
    procedure TestRemoveMiddleElementKeepsOrder;
    procedure TestUpdateDoesNotChangeOrder;
    procedure TestFirstLastBoundaries;
    procedure TestIterationOrderMatchesInsertion;
    procedure TestTryGetFirstLast;
    procedure TestClearEmptiesMap;
    procedure TestAddOrAssignBehavior;
    procedure TestRemoveNonExistentKey;
    procedure TestEmptyMapFirstLast;
    procedure TestLargeDataSet;
    procedure TestContainsKey;
  end;

implementation

{ TLinkedHashMapTest }

procedure TLinkedHashMapTest.TestInsertionOrderMaintained;
var
  LMap: specialize ILinkedHashMap<string, Integer>;
  LFirst, LLast: specialize TPair<string, Integer>;
begin
  LMap := specialize TLinkedHashMap<string, Integer>.Create;
  
  LMap.Add('first', 1);
  LMap.Add('second', 2);
  LMap.Add('third', 3);
  
  LFirst := LMap.First;
  LLast := LMap.Last;
  
  AssertEquals('First key should be "first"', 'first', LFirst.Key);
  AssertEquals('First value should be 1', 1, LFirst.Value);
  AssertEquals('Last key should be "third"', 'third', LLast.Key);
  AssertEquals('Last value should be 3', 3, LLast.Value);
end;

procedure TLinkedHashMapTest.TestRemoveMiddleElementKeepsOrder;
var
  LMap: specialize ILinkedHashMap<string, Integer>;
  LFirst, LLast: specialize TPair<string, Integer>;
begin
  LMap := specialize TLinkedHashMap<string, Integer>.Create;
  
  LMap.Add('a', 1);
  LMap.Add('b', 2);
  LMap.Add('c', 3);
  LMap.Add('d', 4);
  
  // Remove middle elements
  LMap.Remove('b');
  LMap.Remove('c');
  
  LFirst := LMap.First;
  LLast := LMap.Last;
  
  AssertEquals('After removal, first should be "a"', 'a', LFirst.Key);
  AssertEquals('After removal, last should be "d"', 'd', LLast.Key);
  AssertEquals('Count should be 2', 2, LMap.GetCount);
end;

procedure TLinkedHashMapTest.TestUpdateDoesNotChangeOrder;
var
  LMap: specialize ILinkedHashMap<string, Integer>;
  LFirst: specialize TPair<string, Integer>;
  LValue: Integer;
begin
  LMap := specialize TLinkedHashMap<string, Integer>.Create;
  
  LMap.Add('x', 10);
  LMap.Add('y', 20);
  LMap.Add('z', 30);
  
  // Update middle element
  LMap.AddOrAssign('y', 999);
  
  LFirst := LMap.First;
  AssertEquals('Order should not change after update', 'x', LFirst.Key);
  
  // Verify value was updated
  AssertTrue('Should find updated key', LMap.TryGetValue('y', LValue));
  AssertEquals('Value should be updated', 999, LValue);
end;

procedure TLinkedHashMapTest.TestFirstLastBoundaries;
var
  LMap: specialize ILinkedHashMap<Integer, string>;
  LSingle: specialize TPair<Integer, string>;
begin
  LMap := specialize TLinkedHashMap<Integer, string>.Create;
  
  // Single element
  LMap.Add(42, 'answer');
  LSingle := LMap.First;
  
  AssertEquals('Single element: First key', 42, LSingle.Key);
  AssertEquals('Single element: First value', 'answer', LSingle.Value);
  
  LSingle := LMap.Last;
  AssertEquals('Single element: Last key', 42, LSingle.Key);
  AssertEquals('Single element: Last value', 'answer', LSingle.Value);
end;

procedure TLinkedHashMapTest.TestIterationOrderMatchesInsertion;
var
  LMap: specialize ILinkedHashMap<string, Integer>;
  LKeys: array of string;
  i: Integer;
  LFirst, LLast: specialize TPair<string, Integer>;
begin
  LMap := specialize TLinkedHashMap<string, Integer>.Create;
  
  SetLength(LKeys, 5);
  LKeys[0] := 'alpha';
  LKeys[1] := 'beta';
  LKeys[2] := 'gamma';
  LKeys[3] := 'delta';
  LKeys[4] := 'epsilon';
  
  for i := 0 to High(LKeys) do
    LMap.Add(LKeys[i], i * 10);
  
  // Verify first and last match insertion order
  LFirst := LMap.First;
  LLast := LMap.Last;
  
  AssertEquals('First should be first inserted', LKeys[0], LFirst.Key);
  AssertEquals('Last should be last inserted', LKeys[4], LLast.Key);
end;

procedure TLinkedHashMapTest.TestTryGetFirstLast;
var
  LMap: specialize ILinkedHashMap<string, Integer>;
  LPair: specialize TPair<string, Integer>;
  LSuccess: Boolean;
begin
  LMap := specialize TLinkedHashMap<string, Integer>.Create;
  
  // Empty map
  LSuccess := LMap.TryGetFirst(LPair);
  AssertFalse('TryGetFirst on empty map should return False', LSuccess);
  
  LSuccess := LMap.TryGetLast(LPair);
  AssertFalse('TryGetLast on empty map should return False', LSuccess);
  
  // Non-empty map
  LMap.Add('key1', 100);
  LMap.Add('key2', 200);
  
  LSuccess := LMap.TryGetFirst(LPair);
  AssertTrue('TryGetFirst should succeed', LSuccess);
  AssertEquals('First key', 'key1', LPair.Key);
  AssertEquals('First value', 100, LPair.Value);
  
  LSuccess := LMap.TryGetLast(LPair);
  AssertTrue('TryGetLast should succeed', LSuccess);
  AssertEquals('Last key', 'key2', LPair.Key);
  AssertEquals('Last value', 200, LPair.Value);
end;

procedure TLinkedHashMapTest.TestClearEmptiesMap;
var
  LMap: specialize ILinkedHashMap<Integer, string>;
begin
  LMap := specialize TLinkedHashMap<Integer, string>.Create;
  
  LMap.Add(1, 'one');
  LMap.Add(2, 'two');
  LMap.Add(3, 'three');
  
  AssertEquals('Should have 3 elements', 3, LMap.GetCount);
  
  LMap.Clear;
  
  AssertEquals('After clear, count should be 0', 0, LMap.GetCount);
  AssertTrue('After clear, should be empty', LMap.IsEmpty);
end;

procedure TLinkedHashMapTest.TestAddOrAssignBehavior;
var
  LMap: specialize ILinkedHashMap<string, Integer>;
  LIsNew: Boolean;
  LValue: Integer;
begin
  LMap := specialize TLinkedHashMap<string, Integer>.Create;
  
  // Add new key
  LIsNew := LMap.AddOrAssign('new', 42);
  AssertTrue('AddOrAssign with new key should return True', LIsNew);
  AssertEquals('Count should be 1', 1, LMap.GetCount);
  
  // Update existing key
  LIsNew := LMap.AddOrAssign('new', 99);
  AssertFalse('AddOrAssign with existing key should return False', LIsNew);
  AssertEquals('Count should still be 1', 1, LMap.GetCount);
  
  LMap.TryGetValue('new', LValue);
  AssertEquals('Value should be updated', 99, LValue);
end;

procedure TLinkedHashMapTest.TestRemoveNonExistentKey;
var
  LMap: specialize ILinkedHashMap<string, Integer>;
  LRemoved: Boolean;
begin
  LMap := specialize TLinkedHashMap<string, Integer>.Create;
  
  LMap.Add('exists', 123);
  
  LRemoved := LMap.Remove('nonexistent');
  AssertFalse('Removing non-existent key should return False', LRemoved);
  AssertEquals('Count should remain unchanged', 1, LMap.GetCount);
end;

procedure TLinkedHashMapTest.TestEmptyMapFirstLast;
var
  LMap: specialize ILinkedHashMap<string, Integer>;
  LExceptionRaised: Boolean;
  LDummy: specialize TPair<string, Integer>;
begin
  LMap := specialize TLinkedHashMap<string, Integer>.Create;
  
  LExceptionRaised := False;
  try
    LDummy := LMap.First;
  except
    on E: Exception do
      LExceptionRaised := True;
  end;
  AssertTrue('First on empty map should raise exception', LExceptionRaised);
  
  LExceptionRaised := False;
  try
    LDummy := LMap.Last;
  except
    on E: Exception do
      LExceptionRaised := True;
  end;
  AssertTrue('Last on empty map should raise exception', LExceptionRaised);
end;

procedure TLinkedHashMapTest.TestLargeDataSet;
var
  LMap: specialize ILinkedHashMap<Integer, Integer>;
  i: Integer;
  LFirst, LLast: specialize TPair<Integer, Integer>;
const
  COUNT = 1000;
begin
  LMap := specialize TLinkedHashMap<Integer, Integer>.Create;
  
  // Insert 1000 elements
  for i := 1 to COUNT do
    LMap.Add(i, i * 100);
  
  AssertEquals('Should have ' + IntToStr(COUNT) + ' elements', COUNT, LMap.GetCount);
  
  LFirst := LMap.First;
  LLast := LMap.Last;
  
  AssertEquals('First key should be 1', 1, LFirst.Key);
  AssertEquals('Last key should be ' + IntToStr(COUNT), COUNT, LLast.Key);
  
  // Remove every other element
  for i := 2 to COUNT do
    if (i mod 2) = 0 then
      LMap.Remove(i);
  
  AssertEquals('After removing evens, should have 500 elements', COUNT div 2, LMap.GetCount);
  
  LFirst := LMap.First;
  AssertEquals('First should still be 1', 1, LFirst.Key);
end;

procedure TLinkedHashMapTest.TestContainsKey;
var
  LMap: specialize ILinkedHashMap<string, Integer>;
begin
  LMap := specialize TLinkedHashMap<string, Integer>.Create;
  
  LMap.Add('present', 42);
  
  AssertTrue('Should contain existing key', LMap.ContainsKey('present'));
  AssertFalse('Should not contain non-existent key', LMap.ContainsKey('absent'));
end;

initialization
  RegisterTest(TLinkedHashMapTest);

end.

