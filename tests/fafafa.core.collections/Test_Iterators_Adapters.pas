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
    // TEnumerateIter 测试
    procedure Test_EnumerateIter_Basic;
    procedure Test_EnumerateIter_StartOffset;
    procedure Test_EnumerateIter_Empty;
    procedure Test_EnumerateIter_SingleElement;
    procedure Test_EnumerateIter_WithFilter;
    
    // TZipIter 测试
    procedure Test_ZipIter_SameLength;
    procedure Test_ZipIter_FirstShorter;
    procedure Test_ZipIter_SecondShorter;
    procedure Test_ZipIter_Empty;
    procedure Test_ZipIter_DifferentTypes;
    
    // TChainIter 测试
    procedure Test_ChainIter_Basic;
    procedure Test_ChainIter_FirstEmpty;
    procedure Test_ChainIter_SecondEmpty;
    procedure Test_ChainIter_BothEmpty;
    
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
    
    // Collect 收集器测试
    procedure Test_CollectToVec_Basic;
    procedure Test_CollectToVec_Empty;
    procedure Test_CollectToVec_FromFilter;
    procedure Test_CollectToVec_FromTake;
    procedure Test_CollectToVec_FromChain;
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

{ TEnumerateIter Tests }

procedure TTestIteratorAdapters.Test_EnumerateIter_Basic;
var
  Vec: specialize IVec<String>;
  EnumIt: specialize TEnumerateIter<String>;
  Indices: array of SizeUInt;
  Values: array of String;
begin
  Vec := specialize MakeVec<String>;
  Vec.Append(['apple', 'banana', 'cherry']);
  
  EnumIt := specialize TEnumerateIter<String>.Create(Vec.Iter);
  
  SetLength(Indices, 0);
  SetLength(Values, 0);
  while EnumIt.MoveNext do
  begin
    SetLength(Indices, Length(Indices) + 1);
    SetLength(Values, Length(Values) + 1);
    Indices[High(Indices)] := EnumIt.Index;
    Values[High(Values)] := EnumIt.Current;
  end;
  
  AssertEquals('Should have 3 elements', 3, Length(Indices));
  AssertEquals('Index 0', 0, Indices[0]);
  AssertEquals('Index 1', 1, Indices[1]);
  AssertEquals('Index 2', 2, Indices[2]);
  AssertEquals('Value 0', 'apple', Values[0]);
  AssertEquals('Value 1', 'banana', Values[1]);
  AssertEquals('Value 2', 'cherry', Values[2]);
end;

procedure TTestIteratorAdapters.Test_EnumerateIter_StartOffset;
var
  Vec: specialize IVec<Integer>;
  EnumIt: specialize TEnumerateIter<Integer>;
  Indices: array of SizeUInt;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([10, 20, 30]);
  
  // Start from index 100
  EnumIt := specialize TEnumerateIter<Integer>.Create(Vec.Iter, 100);
  
  SetLength(Indices, 0);
  while EnumIt.MoveNext do
  begin
    SetLength(Indices, Length(Indices) + 1);
    Indices[High(Indices)] := EnumIt.Index;
  end;
  
  AssertEquals('Should have 3 elements', 3, Length(Indices));
  AssertEquals('First index', 100, Indices[0]);
  AssertEquals('Second index', 101, Indices[1]);
  AssertEquals('Third index', 102, Indices[2]);
end;

procedure TTestIteratorAdapters.Test_EnumerateIter_Empty;
var
  Vec: specialize IVec<Integer>;
  EnumIt: specialize TEnumerateIter<Integer>;
  Count: Integer;
begin
  Vec := specialize MakeVec<Integer>;
  
  EnumIt := specialize TEnumerateIter<Integer>.Create(Vec.Iter);
  
  Count := 0;
  while EnumIt.MoveNext do
    Inc(Count);
  
  AssertEquals('Empty source should produce empty result', 0, Count);
end;

procedure TTestIteratorAdapters.Test_EnumerateIter_SingleElement;
var
  Vec: specialize IVec<Integer>;
  EnumIt: specialize TEnumerateIter<Integer>;
  HasElement: Boolean;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Push(42);
  
  EnumIt := specialize TEnumerateIter<Integer>.Create(Vec.Iter);
  
  HasElement := EnumIt.MoveNext;
  AssertTrue('Should have one element', HasElement);
  AssertEquals('Index should be 0', 0, EnumIt.Index);
  AssertEquals('Value should be 42', 42, EnumIt.Current);
  
  AssertFalse('Should have no more elements', EnumIt.MoveNext);
end;

procedure TTestIteratorAdapters.Test_EnumerateIter_WithFilter;
var
  Vec: specialize IVec<Integer>;
  FilterIt: specialize TFilterIter<Integer>;
  Indices: array of SizeUInt;
  Values: array of Integer;
  Index: SizeUInt;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3, 4, 5, 6]);
  
  // First filter even numbers, then enumerate manually
  // (Enumerate cannot directly wrap FilterIter since ToIter returns source)
  FilterIt := specialize TFilterIter<Integer>.Create(Vec.Iter, @IsEven, nil);
  
  SetLength(Indices, 0);
  SetLength(Values, 0);
  Index := 0;
  while FilterIt.MoveNext do
  begin
    SetLength(Indices, Length(Indices) + 1);
    SetLength(Values, Length(Values) + 1);
    Indices[High(Indices)] := Index;
    Values[High(Values)] := FilterIt.Current;
    Inc(Index);
  end;
  
  // After filter, we have [2,4,6], manual enumerate gives indices 0,1,2
  AssertEquals('Should have 3 filtered elements', 3, Length(Indices));
  AssertEquals('Enum index 0', 0, Indices[0]);
  AssertEquals('Enum index 1', 1, Indices[1]);
  AssertEquals('Enum index 2', 2, Indices[2]);
  AssertEquals('Value 2', 2, Values[0]);
  AssertEquals('Value 4', 4, Values[1]);
  AssertEquals('Value 6', 6, Values[2]);
end;

{ TZipIter Tests }

procedure TTestIteratorAdapters.Test_ZipIter_SameLength;
var
  Vec1, Vec2: specialize IVec<Integer>;
  ZipIt: specialize TZipIter<Integer, Integer>;
  First, Second: array of Integer;
begin
  Vec1 := specialize MakeVec<Integer>;
  Vec2 := specialize MakeVec<Integer>;
  Vec1.Append([1, 2, 3]);
  Vec2.Append([10, 20, 30]);
  
  ZipIt := specialize TZipIter<Integer, Integer>.Create(Vec1.Iter, Vec2.Iter);
  
  SetLength(First, 0);
  SetLength(Second, 0);
  while ZipIt.MoveNext do
  begin
    SetLength(First, Length(First) + 1);
    SetLength(Second, Length(Second) + 1);
    First[High(First)] := ZipIt.First;
    Second[High(Second)] := ZipIt.Second;
  end;
  
  AssertEquals('Should have 3 pairs', 3, Length(First));
  AssertEquals('First[0].First', 1, First[0]);
  AssertEquals('First[0].Second', 10, Second[0]);
  AssertEquals('First[1].First', 2, First[1]);
  AssertEquals('First[1].Second', 20, Second[1]);
  AssertEquals('First[2].First', 3, First[2]);
  AssertEquals('First[2].Second', 30, Second[2]);
end;

procedure TTestIteratorAdapters.Test_ZipIter_FirstShorter;
var
  Vec1, Vec2: specialize IVec<Integer>;
  ZipIt: specialize TZipIter<Integer, Integer>;
  Count: Integer;
begin
  Vec1 := specialize MakeVec<Integer>;
  Vec2 := specialize MakeVec<Integer>;
  Vec1.Append([1, 2]);
  Vec2.Append([10, 20, 30, 40]);
  
  ZipIt := specialize TZipIter<Integer, Integer>.Create(Vec1.Iter, Vec2.Iter);
  
  Count := 0;
  while ZipIt.MoveNext do
    Inc(Count);
  
  AssertEquals('Should stop at shorter iterator (2)', 2, Count);
end;

procedure TTestIteratorAdapters.Test_ZipIter_SecondShorter;
var
  Vec1, Vec2: specialize IVec<Integer>;
  ZipIt: specialize TZipIter<Integer, Integer>;
  Count: Integer;
begin
  Vec1 := specialize MakeVec<Integer>;
  Vec2 := specialize MakeVec<Integer>;
  Vec1.Append([1, 2, 3, 4]);
  Vec2.Append([10, 20]);
  
  ZipIt := specialize TZipIter<Integer, Integer>.Create(Vec1.Iter, Vec2.Iter);
  
  Count := 0;
  while ZipIt.MoveNext do
    Inc(Count);
  
  AssertEquals('Should stop at shorter iterator (2)', 2, Count);
end;

procedure TTestIteratorAdapters.Test_ZipIter_Empty;
var
  Vec1, Vec2: specialize IVec<Integer>;
  ZipIt: specialize TZipIter<Integer, Integer>;
  Count: Integer;
begin
  Vec1 := specialize MakeVec<Integer>;
  Vec2 := specialize MakeVec<Integer>;
  Vec1.Append([1, 2, 3]);
  // Vec2 is empty
  
  ZipIt := specialize TZipIter<Integer, Integer>.Create(Vec1.Iter, Vec2.Iter);
  
  Count := 0;
  while ZipIt.MoveNext do
    Inc(Count);
  
  AssertEquals('Should produce empty result when one is empty', 0, Count);
end;

procedure TTestIteratorAdapters.Test_ZipIter_DifferentTypes;
var
  VecInt: specialize IVec<Integer>;
  VecStr: specialize IVec<String>;
  ZipIt: specialize TZipIter<Integer, String>;
  Ints: array of Integer;
  Strs: array of String;
begin
  VecInt := specialize MakeVec<Integer>;
  VecStr := specialize MakeVec<String>;
  VecInt.Append([1, 2, 3]);
  VecStr.Append(['one', 'two', 'three']);
  
  ZipIt := specialize TZipIter<Integer, String>.Create(VecInt.Iter, VecStr.Iter);
  
  SetLength(Ints, 0);
  SetLength(Strs, 0);
  while ZipIt.MoveNext do
  begin
    SetLength(Ints, Length(Ints) + 1);
    SetLength(Strs, Length(Strs) + 1);
    Ints[High(Ints)] := ZipIt.First;
    Strs[High(Strs)] := ZipIt.Second;
  end;
  
  AssertEquals('Should have 3 pairs', 3, Length(Ints));
  AssertEquals('Int 0', 1, Ints[0]);
  AssertEquals('Str 0', 'one', Strs[0]);
  AssertEquals('Int 1', 2, Ints[1]);
  AssertEquals('Str 1', 'two', Strs[1]);
  AssertEquals('Int 2', 3, Ints[2]);
  AssertEquals('Str 2', 'three', Strs[2]);
end;

{ TChainIter Tests }

procedure TTestIteratorAdapters.Test_ChainIter_Basic;
var
  Vec1, Vec2: specialize IVec<Integer>;
  ChainIt: specialize TChainIter<Integer>;
  Results: array of Integer;
begin
  Vec1 := specialize MakeVec<Integer>;
  Vec2 := specialize MakeVec<Integer>;
  Vec1.Append([1, 2, 3]);
  Vec2.Append([4, 5, 6]);
  
  ChainIt := specialize TChainIter<Integer>.Create(Vec1.Iter, Vec2.Iter);
  
  SetLength(Results, 0);
  while ChainIt.MoveNext do
  begin
    SetLength(Results, Length(Results) + 1);
    Results[High(Results)] := ChainIt.Current;
  end;
  
  AssertEquals('Should have 6 elements', 6, Length(Results));
  AssertEquals('Element 0', 1, Results[0]);
  AssertEquals('Element 1', 2, Results[1]);
  AssertEquals('Element 2', 3, Results[2]);
  AssertEquals('Element 3', 4, Results[3]);
  AssertEquals('Element 4', 5, Results[4]);
  AssertEquals('Element 5', 6, Results[5]);
end;

procedure TTestIteratorAdapters.Test_ChainIter_FirstEmpty;
var
  Vec1, Vec2: specialize IVec<Integer>;
  ChainIt: specialize TChainIter<Integer>;
  Results: array of Integer;
begin
  Vec1 := specialize MakeVec<Integer>;
  Vec2 := specialize MakeVec<Integer>;
  // Vec1 is empty
  Vec2.Append([4, 5, 6]);
  
  ChainIt := specialize TChainIter<Integer>.Create(Vec1.Iter, Vec2.Iter);
  
  SetLength(Results, 0);
  while ChainIt.MoveNext do
  begin
    SetLength(Results, Length(Results) + 1);
    Results[High(Results)] := ChainIt.Current;
  end;
  
  AssertEquals('Should have 3 elements from second', 3, Length(Results));
  AssertEquals('Element 0', 4, Results[0]);
  AssertEquals('Element 1', 5, Results[1]);
  AssertEquals('Element 2', 6, Results[2]);
end;

procedure TTestIteratorAdapters.Test_ChainIter_SecondEmpty;
var
  Vec1, Vec2: specialize IVec<Integer>;
  ChainIt: specialize TChainIter<Integer>;
  Results: array of Integer;
begin
  Vec1 := specialize MakeVec<Integer>;
  Vec2 := specialize MakeVec<Integer>;
  Vec1.Append([1, 2, 3]);
  // Vec2 is empty
  
  ChainIt := specialize TChainIter<Integer>.Create(Vec1.Iter, Vec2.Iter);
  
  SetLength(Results, 0);
  while ChainIt.MoveNext do
  begin
    SetLength(Results, Length(Results) + 1);
    Results[High(Results)] := ChainIt.Current;
  end;
  
  AssertEquals('Should have 3 elements from first', 3, Length(Results));
  AssertEquals('Element 0', 1, Results[0]);
  AssertEquals('Element 1', 2, Results[1]);
  AssertEquals('Element 2', 3, Results[2]);
end;

procedure TTestIteratorAdapters.Test_ChainIter_BothEmpty;
var
  Vec1, Vec2: specialize IVec<Integer>;
  ChainIt: specialize TChainIter<Integer>;
  Count: Integer;
begin
  Vec1 := specialize MakeVec<Integer>;
  Vec2 := specialize MakeVec<Integer>;
  // Both empty
  
  ChainIt := specialize TChainIter<Integer>.Create(Vec1.Iter, Vec2.Iter);
  
  Count := 0;
  while ChainIt.MoveNext do
    Inc(Count);
  
  AssertEquals('Should produce empty result', 0, Count);
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

{ Collect Tests }

procedure TTestIteratorAdapters.Test_CollectToVec_Basic;
var
  SrcVec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Result: specialize IVec<Integer>;
begin
  SrcVec := specialize MakeVec<Integer>;
  SrcVec.Append([1, 2, 3, 4, 5]);
  
  // Collect from TIter<T> to IVec<T>
  It := SrcVec.Iter;
  Result := specialize CollectToVec<Integer>(It);
  
  AssertEquals('Should have 5 elements', 5, Result.Count);
  AssertEquals('Element 0', 1, Result[0]);
  AssertEquals('Element 1', 2, Result[1]);
  AssertEquals('Element 2', 3, Result[2]);
  AssertEquals('Element 3', 4, Result[3]);
  AssertEquals('Element 4', 5, Result[4]);
end;

procedure TTestIteratorAdapters.Test_CollectToVec_Empty;
var
  SrcVec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Result: specialize IVec<Integer>;
begin
  SrcVec := specialize MakeVec<Integer>;
  // Empty source
  
  It := SrcVec.Iter;
  Result := specialize CollectToVec<Integer>(It);
  
  AssertEquals('Should have 0 elements', 0, Result.Count);
  AssertTrue('Should be empty', Result.IsEmpty);
end;

procedure TTestIteratorAdapters.Test_CollectToVec_FromFilter;
var
  SrcVec: specialize IVec<Integer>;
  FilterIt: specialize TFilterIter<Integer>;
  Result: specialize IVec<Integer>;
begin
  SrcVec := specialize MakeVec<Integer>;
  SrcVec.Append([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  
  // Filter even numbers, then collect
  FilterIt := specialize TFilterIter<Integer>.Create(SrcVec.Iter, @IsEven, nil);
  Result := specialize CollectFilterToVec<Integer>(FilterIt);
  
  AssertEquals('Should have 5 even numbers', 5, Result.Count);
  AssertEquals('First even', 2, Result[0]);
  AssertEquals('Second even', 4, Result[1]);
  AssertEquals('Third even', 6, Result[2]);
  AssertEquals('Fourth even', 8, Result[3]);
  AssertEquals('Fifth even', 10, Result[4]);
end;

procedure TTestIteratorAdapters.Test_CollectToVec_FromTake;
var
  SrcVec: specialize IVec<Integer>;
  TakeIt: specialize TTakeIter<Integer>;
  Result: specialize IVec<Integer>;
begin
  SrcVec := specialize MakeVec<Integer>;
  SrcVec.Append([1, 2, 3, 4, 5]);
  
  // Take first 3, then collect
  TakeIt := specialize TTakeIter<Integer>.Create(SrcVec.Iter, 3);
  Result := specialize CollectTakeToVec<Integer>(TakeIt);
  
  AssertEquals('Should have 3 elements', 3, Result.Count);
  AssertEquals('Element 0', 1, Result[0]);
  AssertEquals('Element 1', 2, Result[1]);
  AssertEquals('Element 2', 3, Result[2]);
end;

procedure TTestIteratorAdapters.Test_CollectToVec_FromChain;
var
  Vec1, Vec2: specialize IVec<Integer>;
  ChainIt: specialize TChainIter<Integer>;
  Result: specialize IVec<Integer>;
begin
  Vec1 := specialize MakeVec<Integer>;
  Vec2 := specialize MakeVec<Integer>;
  Vec1.Append([1, 2, 3]);
  Vec2.Append([4, 5, 6]);
  
  // Chain two vecs, then collect
  ChainIt := specialize TChainIter<Integer>.Create(Vec1.Iter, Vec2.Iter);
  Result := specialize CollectChainToVec<Integer>(ChainIt);
  
  AssertEquals('Should have 6 elements', 6, Result.Count);
  AssertEquals('Element 0', 1, Result[0]);
  AssertEquals('Element 1', 2, Result[1]);
  AssertEquals('Element 2', 3, Result[2]);
  AssertEquals('Element 3', 4, Result[3]);
  AssertEquals('Element 4', 5, Result[4]);
  AssertEquals('Element 5', 6, Result[5]);
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
