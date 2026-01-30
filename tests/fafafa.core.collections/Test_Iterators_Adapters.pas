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
    // 终端组合子辅助函数
    class function IntAdd(const aAcc: Integer; const aElement: Integer; aData: Pointer): Integer; static;
    class function IntMul(const aAcc: Integer; const aElement: Integer; aData: Pointer): Integer; static;
    class function IntCompare(const aA, aB: Integer; aData: Pointer): Integer; static;
    class procedure IntCollect(const aElement: Integer; aData: Pointer); static;
    class function IsGreaterThan5(const aElement: Integer; aData: Pointer): Boolean; static;
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

    // 终端组合子测试 (Terminal Combinators)
    // IterFold 测试
    procedure Test_IterFold_Sum;
    procedure Test_IterFold_Product;
    procedure Test_IterFold_Empty;

    // IterReduce 测试
    procedure Test_IterReduce_Sum;
    procedure Test_IterReduce_Max;
    procedure Test_IterReduce_Empty;

    // IterFind 测试
    procedure Test_IterFind_Found;
    procedure Test_IterFind_NotFound;
    procedure Test_IterFind_Empty;

    // IterAny 测试
    procedure Test_IterAny_SomeMatch;
    procedure Test_IterAny_NoneMatch;
    procedure Test_IterAny_Empty;

    // IterAll 测试
    procedure Test_IterAll_AllMatch;
    procedure Test_IterAll_SomeNotMatch;
    procedure Test_IterAll_Empty;

    // IterForEach 测试
    procedure Test_IterForEach_Basic;
    procedure Test_IterForEach_Empty;

    // IterCount 测试
    procedure Test_IterCount_Basic;
    procedure Test_IterCount_Empty;

    // IterCountIf 测试
    procedure Test_IterCountIf_Basic;
    procedure Test_IterCountIf_NoneMatch;
    procedure Test_IterCountIf_Empty;

    // IterSum 测试
    procedure Test_IterSumInt_Basic;
    procedure Test_IterSumInt_Empty;

    // IterMin/IterMax 测试
    procedure Test_IterMin_Basic;
    procedure Test_IterMax_Basic;
    procedure Test_IterMin_Empty;

    // IterNth 测试
    procedure Test_IterNth_Valid;
    procedure Test_IterNth_OutOfBounds;
    procedure Test_IterNth_Empty;

    // IterLast 测试
    procedure Test_IterLast_Basic;
    procedure Test_IterLast_Single;
    procedure Test_IterLast_Empty;

    // TTakeWhileIter 测试
    procedure Test_TakeWhileIter_Basic;
    procedure Test_TakeWhileIter_AllMatch;
    procedure Test_TakeWhileIter_NoneMatch;
    procedure Test_TakeWhileIter_Empty;

    // TSkipWhileIter 测试
    procedure Test_SkipWhileIter_Basic;
    procedure Test_SkipWhileIter_AllMatch;
    procedure Test_SkipWhileIter_NoneMatch;
    procedure Test_SkipWhileIter_Empty;

    // TFlattenIter 测试
    procedure Test_FlattenIter_Basic;
    procedure Test_FlattenIter_EmptyInner;
    procedure Test_FlattenIter_EmptyOuter;
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

class function TTestIteratorAdapters.IntAdd(const aAcc: Integer; const aElement: Integer; aData: Pointer): Integer;
begin
  Result := aAcc + aElement;
end;

class function TTestIteratorAdapters.IntMul(const aAcc: Integer; const aElement: Integer; aData: Pointer): Integer;
begin
  Result := aAcc * aElement;
end;

class function TTestIteratorAdapters.IntCompare(const aA, aB: Integer; aData: Pointer): Integer;
begin
  Result := aA - aB;
end;

class procedure TTestIteratorAdapters.IntCollect(const aElement: Integer; aData: Pointer);
var
  List: ^specialize TArray<Integer>;
begin
  List := aData;
  SetLength(List^, Length(List^) + 1);
  List^[High(List^)] := aElement;
end;

class function TTestIteratorAdapters.IsGreaterThan5(const aElement: Integer; aData: Pointer): Boolean;
begin
  Result := aElement > 5;
end;

// 用于 IterReduce 的 Max 归约函数
function IntMaxReducer(const aAcc: Integer; const aElement: Integer; aData: Pointer): Integer;
begin
  if aElement > aAcc then
    Result := aElement
  else
    Result := aAcc;
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

{ Terminal Combinator Tests }

// IterFold Tests

procedure TTestIteratorAdapters.Test_IterFold_Sum;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Sum: Integer;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3, 4, 5]);

  It := Vec.Iter;
  Sum := specialize IterFold<Integer, Integer>(It, 0, @IntAdd, nil);

  AssertEquals('Sum should be 15', 15, Sum);
end;

procedure TTestIteratorAdapters.Test_IterFold_Product;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Product: Integer;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3, 4, 5]);

  It := Vec.Iter;
  Product := specialize IterFold<Integer, Integer>(It, 1, @IntMul, nil);

  AssertEquals('Product should be 120', 120, Product);
end;

procedure TTestIteratorAdapters.Test_IterFold_Empty;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Result: Integer;
begin
  Vec := specialize MakeVec<Integer>;

  It := Vec.Iter;
  Result := specialize IterFold<Integer, Integer>(It, 42, @IntAdd, nil);

  AssertEquals('Empty fold should return initial value', 42, Result);
end;

// IterReduce Tests

procedure TTestIteratorAdapters.Test_IterReduce_Sum;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Sum: Integer;
  Found: Boolean;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3, 4, 5]);

  It := Vec.Iter;
  Found := specialize IterReduce<Integer>(It, @IntAdd, nil, Sum);

  AssertTrue('Should find result', Found);
  AssertEquals('Sum should be 15', 15, Sum);
end;

procedure TTestIteratorAdapters.Test_IterReduce_Max;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  MaxVal: Integer;
  Found: Boolean;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([3, 1, 4, 1, 5, 9, 2, 6]);

  It := Vec.Iter;
  Found := specialize IterReduce<Integer>(It, @IntMaxReducer, nil, MaxVal);

  AssertTrue('Should find result', Found);
  AssertEquals('Max should be 9', 9, MaxVal);
end;

procedure TTestIteratorAdapters.Test_IterReduce_Empty;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Result: Integer;
  Found: Boolean;
begin
  Vec := specialize MakeVec<Integer>;

  It := Vec.Iter;
  Found := specialize IterReduce<Integer>(It, @IntAdd, nil, Result);

  AssertFalse('Empty reduce should return False', Found);
end;

// IterFind Tests

procedure TTestIteratorAdapters.Test_IterFind_Found;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Result: Integer;
  Found: Boolean;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 3, 5, 6, 7, 9]);

  It := Vec.Iter;
  Found := specialize IterFind<Integer>(It, @IsEven, nil, Result);

  AssertTrue('Should find even number', Found);
  AssertEquals('First even should be 6', 6, Result);
end;

procedure TTestIteratorAdapters.Test_IterFind_NotFound;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Result: Integer;
  Found: Boolean;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 3, 5, 7, 9]);

  It := Vec.Iter;
  Found := specialize IterFind<Integer>(It, @IsEven, nil, Result);

  AssertFalse('Should not find even number', Found);
end;

procedure TTestIteratorAdapters.Test_IterFind_Empty;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Result: Integer;
  Found: Boolean;
begin
  Vec := specialize MakeVec<Integer>;

  It := Vec.Iter;
  Found := specialize IterFind<Integer>(It, @IsEven, nil, Result);

  AssertFalse('Empty find should return False', Found);
end;

// IterAny Tests

procedure TTestIteratorAdapters.Test_IterAny_SomeMatch;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  HasEven: Boolean;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 3, 5, 6, 7]);

  It := Vec.Iter;
  HasEven := specialize IterAny<Integer>(It, @IsEven, nil);

  AssertTrue('Should have at least one even', HasEven);
end;

procedure TTestIteratorAdapters.Test_IterAny_NoneMatch;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  HasEven: Boolean;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 3, 5, 7, 9]);

  It := Vec.Iter;
  HasEven := specialize IterAny<Integer>(It, @IsEven, nil);

  AssertFalse('Should have no even numbers', HasEven);
end;

procedure TTestIteratorAdapters.Test_IterAny_Empty;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  HasAny: Boolean;
begin
  Vec := specialize MakeVec<Integer>;

  It := Vec.Iter;
  HasAny := specialize IterAny<Integer>(It, @IsEven, nil);

  AssertFalse('Empty any should return False', HasAny);
end;

// IterAll Tests

procedure TTestIteratorAdapters.Test_IterAll_AllMatch;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  AllEven: Boolean;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([2, 4, 6, 8, 10]);

  It := Vec.Iter;
  AllEven := specialize IterAll<Integer>(It, @IsEven, nil);

  AssertTrue('All should be even', AllEven);
end;

procedure TTestIteratorAdapters.Test_IterAll_SomeNotMatch;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  AllEven: Boolean;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([2, 4, 5, 8, 10]);

  It := Vec.Iter;
  AllEven := specialize IterAll<Integer>(It, @IsEven, nil);

  AssertFalse('Not all should be even', AllEven);
end;

procedure TTestIteratorAdapters.Test_IterAll_Empty;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  AllMatch: Boolean;
begin
  Vec := specialize MakeVec<Integer>;

  It := Vec.Iter;
  AllMatch := specialize IterAll<Integer>(It, @IsEven, nil);

  AssertTrue('Empty all should return True (vacuous truth)', AllMatch);
end;

// IterForEach Tests

procedure TTestIteratorAdapters.Test_IterForEach_Basic;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Collected: specialize TArray<Integer>;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3, 4, 5]);

  SetLength(Collected, 0);
  It := Vec.Iter;
  specialize IterForEach<Integer>(It, @IntCollect, @Collected);

  AssertEquals('Should collect 5 elements', 5, Length(Collected));
  AssertEquals('Element 0', 1, Collected[0]);
  AssertEquals('Element 4', 5, Collected[4]);
end;

procedure TTestIteratorAdapters.Test_IterForEach_Empty;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Collected: specialize TArray<Integer>;
begin
  Vec := specialize MakeVec<Integer>;

  SetLength(Collected, 0);
  It := Vec.Iter;
  specialize IterForEach<Integer>(It, @IntCollect, @Collected);

  AssertEquals('Should collect 0 elements', 0, Length(Collected));
end;

// IterCount Tests

procedure TTestIteratorAdapters.Test_IterCount_Basic;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Count: SizeUInt;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3, 4, 5]);

  It := Vec.Iter;
  Count := specialize IterCount<Integer>(It);

  AssertEquals('Count should be 5', 5, Count);
end;

procedure TTestIteratorAdapters.Test_IterCount_Empty;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Count: SizeUInt;
begin
  Vec := specialize MakeVec<Integer>;

  It := Vec.Iter;
  Count := specialize IterCount<Integer>(It);

  AssertEquals('Empty count should be 0', 0, Count);
end;

// IterCountIf Tests

procedure TTestIteratorAdapters.Test_IterCountIf_Basic;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Count: SizeUInt;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

  It := Vec.Iter;
  Count := specialize IterCountIf<Integer>(It, @IsEven, nil);

  AssertEquals('Even count should be 5', 5, Count);
end;

procedure TTestIteratorAdapters.Test_IterCountIf_NoneMatch;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Count: SizeUInt;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 3, 5, 7, 9]);

  It := Vec.Iter;
  Count := specialize IterCountIf<Integer>(It, @IsEven, nil);

  AssertEquals('Even count should be 0', 0, Count);
end;

procedure TTestIteratorAdapters.Test_IterCountIf_Empty;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Count: SizeUInt;
begin
  Vec := specialize MakeVec<Integer>;

  It := Vec.Iter;
  Count := specialize IterCountIf<Integer>(It, @IsEven, nil);

  AssertEquals('Empty countif should be 0', 0, Count);
end;

// IterSum Tests

procedure TTestIteratorAdapters.Test_IterSumInt_Basic;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Sum: Int64;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3, 4, 5]);

  It := Vec.Iter;
  Sum := IterSumInt(It);

  AssertEquals('Sum should be 15', 15, Sum);
end;

procedure TTestIteratorAdapters.Test_IterSumInt_Empty;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Sum: Int64;
begin
  Vec := specialize MakeVec<Integer>;

  It := Vec.Iter;
  Sum := IterSumInt(It);

  AssertEquals('Empty sum should be 0', 0, Sum);
end;

// IterMin/IterMax Tests

procedure TTestIteratorAdapters.Test_IterMin_Basic;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  MinVal: Integer;
  Found: Boolean;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([3, 1, 4, 1, 5, 9, 2, 6]);

  It := Vec.Iter;
  Found := specialize IterMin<Integer>(It, @IntCompare, nil, MinVal);

  AssertTrue('Should find min', Found);
  AssertEquals('Min should be 1', 1, MinVal);
end;

procedure TTestIteratorAdapters.Test_IterMax_Basic;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  MaxVal: Integer;
  Found: Boolean;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([3, 1, 4, 1, 5, 9, 2, 6]);

  It := Vec.Iter;
  Found := specialize IterMax<Integer>(It, @IntCompare, nil, MaxVal);

  AssertTrue('Should find max', Found);
  AssertEquals('Max should be 9', 9, MaxVal);
end;

procedure TTestIteratorAdapters.Test_IterMin_Empty;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  MinVal: Integer;
  Found: Boolean;
begin
  Vec := specialize MakeVec<Integer>;

  It := Vec.Iter;
  Found := specialize IterMin<Integer>(It, @IntCompare, nil, MinVal);

  AssertFalse('Empty min should return False', Found);
end;

// IterNth Tests

procedure TTestIteratorAdapters.Test_IterNth_Valid;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Val: Integer;
  Found: Boolean;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([10, 20, 30, 40, 50]);

  It := Vec.Iter;
  Found := specialize IterNth<Integer>(It, 2, Val);

  AssertTrue('Should find nth', Found);
  AssertEquals('Nth(2) should be 30', 30, Val);
end;

procedure TTestIteratorAdapters.Test_IterNth_OutOfBounds;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Val: Integer;
  Found: Boolean;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([10, 20, 30]);

  It := Vec.Iter;
  Found := specialize IterNth<Integer>(It, 10, Val);

  AssertFalse('Out of bounds nth should return False', Found);
end;

procedure TTestIteratorAdapters.Test_IterNth_Empty;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  Val: Integer;
  Found: Boolean;
begin
  Vec := specialize MakeVec<Integer>;

  It := Vec.Iter;
  Found := specialize IterNth<Integer>(It, 0, Val);

  AssertFalse('Empty nth should return False', Found);
end;

// IterLast Tests

procedure TTestIteratorAdapters.Test_IterLast_Basic;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  LastVal: Integer;
  Found: Boolean;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3, 4, 5]);

  It := Vec.Iter;
  Found := specialize IterLast<Integer>(It, LastVal);

  AssertTrue('Should find last', Found);
  AssertEquals('Last should be 5', 5, LastVal);
end;

procedure TTestIteratorAdapters.Test_IterLast_Single;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  LastVal: Integer;
  Found: Boolean;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Push(42);

  It := Vec.Iter;
  Found := specialize IterLast<Integer>(It, LastVal);

  AssertTrue('Should find last', Found);
  AssertEquals('Last should be 42', 42, LastVal);
end;

procedure TTestIteratorAdapters.Test_IterLast_Empty;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  LastVal: Integer;
  Found: Boolean;
begin
  Vec := specialize MakeVec<Integer>;

  It := Vec.Iter;
  Found := specialize IterLast<Integer>(It, LastVal);

  AssertFalse('Empty last should return False', Found);
end;

// ============================================================================
// TTakeWhileIter 测试
// ============================================================================

// 辅助函数：判断是否小于 5
function IsLessThan5(const aElement: Integer; aData: Pointer): Boolean;
begin
  Result := aElement < 5;
end;

// 辅助函数：判断是否小于 100（总是为真）
function IsLessThan100(const aElement: Integer; aData: Pointer): Boolean;
begin
  Result := aElement < 100;
end;

// 辅助函数：判断是否小于 0（总是为假）
function IsLessThan0(const aElement: Integer; aData: Pointer): Boolean;
begin
  Result := aElement < 0;
end;

procedure TTestIteratorAdapters.Test_TakeWhileIter_Basic;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  TakeWhileIt: specialize TTakeWhileIter<Integer>;
  Results: array of Integer;
begin
  // 创建 [1, 2, 3, 4, 5, 6, 7]
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3, 4, 5, 6, 7]);

  It := Vec.Iter;
  TakeWhileIt := specialize TTakeWhileIter<Integer>.Create(It, @IsLessThan5, nil);

  // 收集结果
  SetLength(Results, 0);
  while TakeWhileIt.MoveNext do
  begin
    SetLength(Results, Length(Results) + 1);
    Results[High(Results)] := TakeWhileIt.Current;
  end;

  // 应该只取 [1, 2, 3, 4]
  AssertEquals('Should take 4 elements', 4, Length(Results));
  AssertEquals('First element', 1, Results[0]);
  AssertEquals('Second element', 2, Results[1]);
  AssertEquals('Third element', 3, Results[2]);
  AssertEquals('Fourth element', 4, Results[3]);
end;

procedure TTestIteratorAdapters.Test_TakeWhileIter_AllMatch;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  TakeWhileIt: specialize TTakeWhileIter<Integer>;
  Results: array of Integer;
begin
  // 创建 [1, 2, 3]
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3]);

  It := Vec.Iter;
  TakeWhileIt := specialize TTakeWhileIter<Integer>.Create(It, @IsLessThan100, nil);

  // 收集结果
  SetLength(Results, 0);
  while TakeWhileIt.MoveNext do
  begin
    SetLength(Results, Length(Results) + 1);
    Results[High(Results)] := TakeWhileIt.Current;
  end;

  // 所有元素都满足条件，应该全部取出
  AssertEquals('Should take all 3 elements', 3, Length(Results));
  AssertEquals('First element', 1, Results[0]);
  AssertEquals('Second element', 2, Results[1]);
  AssertEquals('Third element', 3, Results[2]);
end;

procedure TTestIteratorAdapters.Test_TakeWhileIter_NoneMatch;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  TakeWhileIt: specialize TTakeWhileIter<Integer>;
  Count: Integer;
begin
  // 创建 [1, 2, 3]
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3]);

  It := Vec.Iter;
  TakeWhileIt := specialize TTakeWhileIter<Integer>.Create(It, @IsLessThan0, nil);

  // 计数
  Count := 0;
  while TakeWhileIt.MoveNext do
    Inc(Count);

  // 第一个元素就不满足条件，应该不取任何元素
  AssertEquals('Should take 0 elements', 0, Count);
end;

procedure TTestIteratorAdapters.Test_TakeWhileIter_Empty;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  TakeWhileIt: specialize TTakeWhileIter<Integer>;
  Count: Integer;
begin
  Vec := specialize MakeVec<Integer>;

  It := Vec.Iter;
  TakeWhileIt := specialize TTakeWhileIter<Integer>.Create(It, @IsLessThan5, nil);

  Count := 0;
  while TakeWhileIt.MoveNext do
    Inc(Count);

  AssertEquals('Empty source should yield 0 elements', 0, Count);
end;

// ============================================================================
// TSkipWhileIter 测试
// ============================================================================

procedure TTestIteratorAdapters.Test_SkipWhileIter_Basic;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  SkipWhileIt: specialize TSkipWhileIter<Integer>;
  Results: array of Integer;
begin
  // 创建 [1, 2, 3, 4, 5, 6, 7]
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3, 4, 5, 6, 7]);

  It := Vec.Iter;
  SkipWhileIt := specialize TSkipWhileIter<Integer>.Create(It, @IsLessThan5, nil);

  // 收集结果
  SetLength(Results, 0);
  while SkipWhileIt.MoveNext do
  begin
    SetLength(Results, Length(Results) + 1);
    Results[High(Results)] := SkipWhileIt.Current;
  end;

  // 应该跳过 [1, 2, 3, 4]，返回 [5, 6, 7]
  AssertEquals('Should have 3 elements', 3, Length(Results));
  AssertEquals('First element', 5, Results[0]);
  AssertEquals('Second element', 6, Results[1]);
  AssertEquals('Third element', 7, Results[2]);
end;

procedure TTestIteratorAdapters.Test_SkipWhileIter_AllMatch;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  SkipWhileIt: specialize TSkipWhileIter<Integer>;
  Count: Integer;
begin
  // 创建 [1, 2, 3]
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3]);

  It := Vec.Iter;
  SkipWhileIt := specialize TSkipWhileIter<Integer>.Create(It, @IsLessThan100, nil);

  // 计数
  Count := 0;
  while SkipWhileIt.MoveNext do
    Inc(Count);

  // 所有元素都满足条件，全部跳过
  AssertEquals('Should skip all elements', 0, Count);
end;

procedure TTestIteratorAdapters.Test_SkipWhileIter_NoneMatch;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  SkipWhileIt: specialize TSkipWhileIter<Integer>;
  Results: array of Integer;
begin
  // 创建 [1, 2, 3]
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3]);

  It := Vec.Iter;
  SkipWhileIt := specialize TSkipWhileIter<Integer>.Create(It, @IsLessThan0, nil);

  // 收集结果
  SetLength(Results, 0);
  while SkipWhileIt.MoveNext do
  begin
    SetLength(Results, Length(Results) + 1);
    Results[High(Results)] := SkipWhileIt.Current;
  end;

  // 第一个元素就不满足条件，不跳过任何元素
  AssertEquals('Should have all 3 elements', 3, Length(Results));
  AssertEquals('First element', 1, Results[0]);
  AssertEquals('Second element', 2, Results[1]);
  AssertEquals('Third element', 3, Results[2]);
end;

procedure TTestIteratorAdapters.Test_SkipWhileIter_Empty;
var
  Vec: specialize IVec<Integer>;
  It: specialize TIter<Integer>;
  SkipWhileIt: specialize TSkipWhileIter<Integer>;
  Count: Integer;
begin
  Vec := specialize MakeVec<Integer>;

  It := Vec.Iter;
  SkipWhileIt := specialize TSkipWhileIter<Integer>.Create(It, @IsLessThan5, nil);

  Count := 0;
  while SkipWhileIt.MoveNext do
    Inc(Count);

  AssertEquals('Empty source should yield 0 elements', 0, Count);
end;

// ============================================================================
// TFlattenIter 测试
// ============================================================================

procedure TTestIteratorAdapters.Test_FlattenIter_Basic;
var
  Outer: specialize IVec<specialize IVec<Integer>>;
  Inner1, Inner2, Inner3: specialize IVec<Integer>;
  OuterIt: specialize TIter<specialize IVec<Integer>>;
  FlattenIt: specialize TFlattenIter<Integer>;
  Results: array of Integer;
begin
  // 创建嵌套结构 [[1, 2], [3, 4, 5], [6]]
  Inner1 := specialize MakeVec<Integer>;
  Inner1.Append([1, 2]);

  Inner2 := specialize MakeVec<Integer>;
  Inner2.Append([3, 4, 5]);

  Inner3 := specialize MakeVec<Integer>;
  Inner3.Push(6);

  Outer := specialize MakeVec<specialize IVec<Integer>>;
  Outer.Push(Inner1);
  Outer.Push(Inner2);
  Outer.Push(Inner3);

  OuterIt := Outer.Iter;
  FlattenIt := specialize TFlattenIter<Integer>.Create(OuterIt);

  // 收集结果
  SetLength(Results, 0);
  while FlattenIt.MoveNext do
  begin
    SetLength(Results, Length(Results) + 1);
    Results[High(Results)] := FlattenIt.Current;
  end;

  // 应该扁平化为 [1, 2, 3, 4, 5, 6]
  AssertEquals('Should have 6 elements', 6, Length(Results));
  AssertEquals('Element 0', 1, Results[0]);
  AssertEquals('Element 1', 2, Results[1]);
  AssertEquals('Element 2', 3, Results[2]);
  AssertEquals('Element 3', 4, Results[3]);
  AssertEquals('Element 4', 5, Results[4]);
  AssertEquals('Element 5', 6, Results[5]);
end;

procedure TTestIteratorAdapters.Test_FlattenIter_EmptyInner;
var
  Outer: specialize IVec<specialize IVec<Integer>>;
  Inner1, Inner2, Inner3: specialize IVec<Integer>;
  OuterIt: specialize TIter<specialize IVec<Integer>>;
  FlattenIt: specialize TFlattenIter<Integer>;
  Results: array of Integer;
begin
  // 创建嵌套结构 [[1, 2], [], [3]]
  Inner1 := specialize MakeVec<Integer>;
  Inner1.Append([1, 2]);

  Inner2 := specialize MakeVec<Integer>;  // 空的

  Inner3 := specialize MakeVec<Integer>;
  Inner3.Push(3);

  Outer := specialize MakeVec<specialize IVec<Integer>>;
  Outer.Push(Inner1);
  Outer.Push(Inner2);
  Outer.Push(Inner3);

  OuterIt := Outer.Iter;
  FlattenIt := specialize TFlattenIter<Integer>.Create(OuterIt);

  // 收集结果
  SetLength(Results, 0);
  while FlattenIt.MoveNext do
  begin
    SetLength(Results, Length(Results) + 1);
    Results[High(Results)] := FlattenIt.Current;
  end;

  // 应该跳过空的内部向量，扁平化为 [1, 2, 3]
  AssertEquals('Should have 3 elements', 3, Length(Results));
  AssertEquals('Element 0', 1, Results[0]);
  AssertEquals('Element 1', 2, Results[1]);
  AssertEquals('Element 2', 3, Results[2]);
end;

procedure TTestIteratorAdapters.Test_FlattenIter_EmptyOuter;
var
  Outer: specialize IVec<specialize IVec<Integer>>;
  OuterIt: specialize TIter<specialize IVec<Integer>>;
  FlattenIt: specialize TFlattenIter<Integer>;
  Count: Integer;
begin
  // 创建空的外部向量
  Outer := specialize MakeVec<specialize IVec<Integer>>;

  OuterIt := Outer.Iter;
  FlattenIt := specialize TFlattenIter<Integer>.Create(OuterIt);

  Count := 0;
  while FlattenIt.MoveNext do
    Inc(Count);

  AssertEquals('Empty outer should yield 0 elements', 0, Count);
end;

initialization
  RegisterTest(TTestIteratorAdapters);

end.
