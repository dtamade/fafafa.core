unit Test_Iterators_Adapters;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

{**
 * TDD 测试用例: 迭代器适配器
 * 
 * 测试目标:
 * 1. TMapIter<T, U> - 映射迭代器
 * 2. TFilterIter<T> - 过滤迭代器
 * 3. TTakeIter<T> - 取前 N 个
 * 4. TSkipIter<T> - 跳过前 N 个
 *}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.base,
  fafafa.core.collections.vec,
  fafafa.core.collections,
  fafafa.core.collections.iterators;

type
  { TTestIteratorAdapters }
  TTestIteratorAdapters = class(TTestCase)
  private
    class function IntDouble(const aElement: Integer; aData: Pointer): Integer; static;
    class function IntToStr(const aElement: Integer; aData: Pointer): String; static;
    class function IsEven(const aElement: Integer; aData: Pointer): Boolean; static;
    class function IsPositive(const aElement: Integer; aData: Pointer): Boolean; static;
  published
    // TMapIter 测试
    procedure Test_MapIter_DoubleValues;
    procedure Test_MapIter_IntToString;
    procedure Test_MapIter_Empty;
    
    // TFilterIter 测试
    procedure Test_FilterIter_EvenNumbers;
    procedure Test_FilterIter_AllMatch;
    procedure Test_FilterIter_NoneMatch;
    procedure Test_FilterIter_Empty;
    
    // TTakeIter 测试
    procedure Test_TakeIter_TakeLessThanCount;
    procedure Test_TakeIter_TakeMoreThanCount;
    procedure Test_TakeIter_TakeZero;
    procedure Test_TakeIter_Empty;
    
    // TSkipIter 测试
    procedure Test_SkipIter_SkipLessThanCount;
    procedure Test_SkipIter_SkipMoreThanCount;
    procedure Test_SkipIter_SkipZero;
    procedure Test_SkipIter_Empty;
    
    // 组合测试
    procedure Test_Filter_Then_Map;
    procedure Test_Skip_Then_Take;
    
    // 内存泄漏测试
    procedure Test_LargeScale_NoLeak;
  end;

implementation

{ Helper functions }

class function TTestIteratorAdapters.IntDouble(const aElement: Integer; aData: Pointer): Integer;
begin
  Result := aElement * 2;
end;

class function TTestIteratorAdapters.IntToStr(const aElement: Integer; aData: Pointer): String;
begin
  Result := SysUtils.IntToStr(aElement);
end;

class function TTestIteratorAdapters.IsEven(const aElement: Integer; aData: Pointer): Boolean;
begin
  Result := (aElement mod 2) = 0;
end;

class function TTestIteratorAdapters.IsPositive(const aElement: Integer; aData: Pointer): Boolean;
begin
  Result := aElement > 0;
end;

{ TMapIter Tests }

procedure TTestIteratorAdapters.Test_MapIter_DoubleValues;
var
  Vec: specialize IVec<Integer>;
  MapIt: specialize TMapIter<Integer, Integer>;
  Results: array of Integer;
  i: Integer;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3, 4, 5]);
  
  MapIt := specialize TMapIter<Integer, Integer>.Create(Vec.Iter, @IntDouble, nil);
  
  SetLength(Results, 0);
  while MapIt.MoveNext do
  begin
    SetLength(Results, Length(Results) + 1);
    Results[High(Results)] := MapIt.Current;
  end;
  
  AssertEquals('Should have 5 elements', 5, Length(Results));
  AssertEquals('First element doubled', 2, Results[0]);
  AssertEquals('Second element doubled', 4, Results[1]);
  AssertEquals('Third element doubled', 6, Results[2]);
  AssertEquals('Fourth element doubled', 8, Results[3]);
  AssertEquals('Fifth element doubled', 10, Results[4]);
end;

procedure TTestIteratorAdapters.Test_MapIter_IntToString;
var
  Vec: specialize IVec<Integer>;
  MapIt: specialize TMapIter<Integer, String>;
  Results: array of String;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([42, 100, 7]);
  
  MapIt := specialize TMapIter<Integer, String>.Create(Vec.Iter, @IntToStr, nil);
  
  SetLength(Results, 0);
  while MapIt.MoveNext do
  begin
    SetLength(Results, Length(Results) + 1);
    Results[High(Results)] := MapIt.Current;
  end;
  
  AssertEquals('Should have 3 elements', 3, Length(Results));
  AssertEquals('First as string', '42', Results[0]);
  AssertEquals('Second as string', '100', Results[1]);
  AssertEquals('Third as string', '7', Results[2]);
end;

procedure TTestIteratorAdapters.Test_MapIter_Empty;
var
  Vec: specialize IVec<Integer>;
  MapIt: specialize TMapIter<Integer, Integer>;
  Count: Integer;
begin
  Vec := specialize MakeVec<Integer>;
  
  MapIt := specialize TMapIter<Integer, Integer>.Create(Vec.Iter, @IntDouble, nil);
  
  Count := 0;
  while MapIt.MoveNext do
    Inc(Count);
  
  AssertEquals('Empty source should produce empty result', 0, Count);
end;

{ TFilterIter Tests }

procedure TTestIteratorAdapters.Test_FilterIter_EvenNumbers;
var
  Vec: specialize IVec<Integer>;
  FilterIt: specialize TFilterIter<Integer>;
  Results: array of Integer;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  
  FilterIt := specialize TFilterIter<Integer>.Create(Vec.Iter, @IsEven, nil);
  
  SetLength(Results, 0);
  while FilterIt.MoveNext do
  begin
    SetLength(Results, Length(Results) + 1);
    Results[High(Results)] := FilterIt.Current;
  end;
  
  AssertEquals('Should have 5 even numbers', 5, Length(Results));
  AssertEquals('First even', 2, Results[0]);
  AssertEquals('Second even', 4, Results[1]);
  AssertEquals('Third even', 6, Results[2]);
  AssertEquals('Fourth even', 8, Results[3]);
  AssertEquals('Fifth even', 10, Results[4]);
end;

procedure TTestIteratorAdapters.Test_FilterIter_AllMatch;
var
  Vec: specialize IVec<Integer>;
  FilterIt: specialize TFilterIter<Integer>;
  Count: Integer;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([2, 4, 6, 8]);
  
  FilterIt := specialize TFilterIter<Integer>.Create(Vec.Iter, @IsEven, nil);
  
  Count := 0;
  while FilterIt.MoveNext do
    Inc(Count);
  
  AssertEquals('All elements should match', 4, Count);
end;

procedure TTestIteratorAdapters.Test_FilterIter_NoneMatch;
var
  Vec: specialize IVec<Integer>;
  FilterIt: specialize TFilterIter<Integer>;
  Count: Integer;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 3, 5, 7]);
  
  FilterIt := specialize TFilterIter<Integer>.Create(Vec.Iter, @IsEven, nil);
  
  Count := 0;
  while FilterIt.MoveNext do
    Inc(Count);
  
  AssertEquals('No elements should match', 0, Count);
end;

procedure TTestIteratorAdapters.Test_FilterIter_Empty;
var
  Vec: specialize IVec<Integer>;
  FilterIt: specialize TFilterIter<Integer>;
  Count: Integer;
begin
  Vec := specialize MakeVec<Integer>;
  
  FilterIt := specialize TFilterIter<Integer>.Create(Vec.Iter, @IsEven, nil);
  
  Count := 0;
  while FilterIt.MoveNext do
    Inc(Count);
  
  AssertEquals('Empty source should produce empty result', 0, Count);
end;

{ TTakeIter Tests }

procedure TTestIteratorAdapters.Test_TakeIter_TakeLessThanCount;
var
  Vec: specialize IVec<Integer>;
  TakeIt: specialize TTakeIter<Integer>;
  Results: array of Integer;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3, 4, 5]);
  
  TakeIt := specialize TTakeIter<Integer>.Create(Vec.Iter, 3);
  
  SetLength(Results, 0);
  while TakeIt.MoveNext do
  begin
    SetLength(Results, Length(Results) + 1);
    Results[High(Results)] := TakeIt.Current;
  end;
  
  AssertEquals('Should take 3 elements', 3, Length(Results));
  AssertEquals('First', 1, Results[0]);
  AssertEquals('Second', 2, Results[1]);
  AssertEquals('Third', 3, Results[2]);
end;

procedure TTestIteratorAdapters.Test_TakeIter_TakeMoreThanCount;
var
  Vec: specialize IVec<Integer>;
  TakeIt: specialize TTakeIter<Integer>;
  Count: Integer;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3]);
  
  TakeIt := specialize TTakeIter<Integer>.Create(Vec.Iter, 10);
  
  Count := 0;
  while TakeIt.MoveNext do
    Inc(Count);
  
  AssertEquals('Should take all 3 elements', 3, Count);
end;

procedure TTestIteratorAdapters.Test_TakeIter_TakeZero;
var
  Vec: specialize IVec<Integer>;
  TakeIt: specialize TTakeIter<Integer>;
  Count: Integer;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3]);
  
  TakeIt := specialize TTakeIter<Integer>.Create(Vec.Iter, 0);
  
  Count := 0;
  while TakeIt.MoveNext do
    Inc(Count);
  
  AssertEquals('Take 0 should produce empty result', 0, Count);
end;

procedure TTestIteratorAdapters.Test_TakeIter_Empty;
var
  Vec: specialize IVec<Integer>;
  TakeIt: specialize TTakeIter<Integer>;
  Count: Integer;
begin
  Vec := specialize MakeVec<Integer>;
  
  TakeIt := specialize TTakeIter<Integer>.Create(Vec.Iter, 5);
  
  Count := 0;
  while TakeIt.MoveNext do
    Inc(Count);
  
  AssertEquals('Empty source should produce empty result', 0, Count);
end;

{ TSkipIter Tests }

procedure TTestIteratorAdapters.Test_SkipIter_SkipLessThanCount;
var
  Vec: specialize IVec<Integer>;
  SkipIt: specialize TSkipIter<Integer>;
  Results: array of Integer;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3, 4, 5]);
  
  SkipIt := specialize TSkipIter<Integer>.Create(Vec.Iter, 2);
  
  SetLength(Results, 0);
  while SkipIt.MoveNext do
  begin
    SetLength(Results, Length(Results) + 1);
    Results[High(Results)] := SkipIt.Current;
  end;
  
  AssertEquals('Should have 3 elements after skip 2', 3, Length(Results));
  AssertEquals('First after skip', 3, Results[0]);
  AssertEquals('Second after skip', 4, Results[1]);
  AssertEquals('Third after skip', 5, Results[2]);
end;

procedure TTestIteratorAdapters.Test_SkipIter_SkipMoreThanCount;
var
  Vec: specialize IVec<Integer>;
  SkipIt: specialize TSkipIter<Integer>;
  Count: Integer;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3]);
  
  SkipIt := specialize TSkipIter<Integer>.Create(Vec.Iter, 10);
  
  Count := 0;
  while SkipIt.MoveNext do
    Inc(Count);
  
  AssertEquals('Skip more than count should produce empty', 0, Count);
end;

procedure TTestIteratorAdapters.Test_SkipIter_SkipZero;
var
  Vec: specialize IVec<Integer>;
  SkipIt: specialize TSkipIter<Integer>;
  Count: Integer;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3]);
  
  SkipIt := specialize TSkipIter<Integer>.Create(Vec.Iter, 0);
  
  Count := 0;
  while SkipIt.MoveNext do
    Inc(Count);
  
  AssertEquals('Skip 0 should keep all elements', 3, Count);
end;

procedure TTestIteratorAdapters.Test_SkipIter_Empty;
var
  Vec: specialize IVec<Integer>;
  SkipIt: specialize TSkipIter<Integer>;
  Count: Integer;
begin
  Vec := specialize MakeVec<Integer>;
  
  SkipIt := specialize TSkipIter<Integer>.Create(Vec.Iter, 2);
  
  Count := 0;
  while SkipIt.MoveNext do
    Inc(Count);
  
  AssertEquals('Empty source should produce empty result', 0, Count);
end;

{ Composition Tests }

procedure TTestIteratorAdapters.Test_Filter_Then_Map;
var
  Vec: specialize IVec<Integer>;
  FilterIt: specialize TFilterIter<Integer>;
  Results: array of Integer;
  Val: Integer;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3, 4, 5, 6]);
  
  // Filter even numbers, then double them (manual chaining)
  FilterIt := specialize TFilterIter<Integer>.Create(Vec.Iter, @IsEven, nil);
  
  SetLength(Results, 0);
  while FilterIt.MoveNext do
  begin
    Val := FilterIt.Current * 2; // Apply map manually
    SetLength(Results, Length(Results) + 1);
    Results[High(Results)] := Val;
  end;
  
  AssertEquals('Should have 3 elements (2,4,6 doubled)', 3, Length(Results));
  AssertEquals('2 doubled', 4, Results[0]);
  AssertEquals('4 doubled', 8, Results[1]);
  AssertEquals('6 doubled', 12, Results[2]);
end;

procedure TTestIteratorAdapters.Test_Skip_Then_Take;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Results: array of Integer;
  SkipCount, TakeCount: Integer;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  
  // Skip 3, then take 4 (manual implementation)
  It := Vec.Iter;
  SkipCount := 3;
  TakeCount := 4;
  
  // Skip first 3
  while (SkipCount > 0) and It.MoveNext do
    Dec(SkipCount);
  
  // Take next 4
  SetLength(Results, 0);
  while (TakeCount > 0) and It.MoveNext do
  begin
    SetLength(Results, Length(Results) + 1);
    Results[High(Results)] := It.Current;
    Dec(TakeCount);
  end;
  
  AssertEquals('Should have 4 elements (4,5,6,7)', 4, Length(Results));
  AssertEquals('First', 4, Results[0]);
  AssertEquals('Second', 5, Results[1]);
  AssertEquals('Third', 6, Results[2]);
  AssertEquals('Fourth', 7, Results[3]);
end;

{ Memory Leak Test }

procedure TTestIteratorAdapters.Test_LargeScale_NoLeak;
var
  Vec: specialize IVec<Integer>;
  FilterIt: specialize TFilterIter<Integer>;
  i, Sum: Integer;
begin
  Vec := specialize MakeVec<Integer>;
  
  // Add 10000 elements
  for i := 1 to 10000 do
    Vec.Push(i);
  
  // Filter even, double them (inline), sum results
  FilterIt := specialize TFilterIter<Integer>.Create(Vec.Iter, @IsEven, nil);
  
  Sum := 0;
  while FilterIt.MoveNext do
    Sum := Sum + FilterIt.Current * 2;
  
  // Sum of even numbers 2..10000 doubled = 2 * (2+4+6+...+10000) = 2 * 2*(1+2+3+...+5000) = 4 * 5000*5001/2 = 50010000
  AssertEquals('Sum should be correct', 50010000, Sum);
  
  // HeapTrc will report if there are leaks
end;

initialization
  RegisterTest(TTestIteratorAdapters);

end.
