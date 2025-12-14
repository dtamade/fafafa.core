unit Test_Vec_Dedup;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.vec,
  fafafa.core.collections.base;

type
  TIntVec = specialize TVec<Integer>;
  IIntVec = specialize IVec<Integer>;

  { TTestVecDedup }
  TTestVecDedup = class(TTestCase)
  published
    // Dedup 基本测试
    procedure Test_Dedup_RemovesConsecutiveDuplicates;
    procedure Test_Dedup_SortedArray_RemovesAllDuplicates;
    procedure Test_Dedup_NoDuplicates_NoChange;
    procedure Test_Dedup_AllSame_LeavesOne;
    procedure Test_Dedup_EmptyVec_NoChange;
    procedure Test_Dedup_SingleElement_NoChange;
    
    // DedupBy 自定义比较器测试
    procedure Test_DedupBy_CustomEquals_Works;
    procedure Test_DedupBy_IgnoreCase_Works;
    
    // 返回值测试
    procedure Test_Dedup_ReturnsRemovedCount;
  end;

implementation

{ 比较函数：判断两个整数的绝对值是否相等 }
function AbsEquals(const aLeft, aRight: Integer; aData: Pointer): Boolean;
begin
  Result := Abs(aLeft) = Abs(aRight);
end;

{ TTestVecDedup }

procedure TTestVecDedup.Test_Dedup_RemovesConsecutiveDuplicates;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    // [1, 1, 2, 2, 2, 3, 3] -> [1, 2, 3]
    V.LoadFrom([1, 1, 2, 2, 2, 3, 3]);
    V.Dedup;
    
    AssertEquals('Count after dedup', 3, V.GetCount);
    AssertEquals('[0]', 1, V.Get(0));
    AssertEquals('[1]', 2, V.Get(1));
    AssertEquals('[2]', 3, V.Get(2));
  finally
    V.Free;
  end;
end;

procedure TTestVecDedup.Test_Dedup_SortedArray_RemovesAllDuplicates;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    // 先排序再去重，可以移除所有重复
    V.LoadFrom([3, 1, 2, 1, 3, 2, 1]);
    V.Sort;  // [1, 1, 1, 2, 2, 3, 3]
    V.Dedup; // [1, 2, 3]
    
    AssertEquals('Count after sort+dedup', 3, V.GetCount);
    AssertEquals('[0]', 1, V.Get(0));
    AssertEquals('[1]', 2, V.Get(1));
    AssertEquals('[2]', 3, V.Get(2));
  finally
    V.Free;
  end;
end;

procedure TTestVecDedup.Test_Dedup_NoDuplicates_NoChange;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    V.LoadFrom([1, 2, 3, 4, 5]);
    V.Dedup;
    
    AssertEquals('Count unchanged', 5, V.GetCount);
    AssertEquals('[0]', 1, V.Get(0));
    AssertEquals('[4]', 5, V.Get(4));
  finally
    V.Free;
  end;
end;

procedure TTestVecDedup.Test_Dedup_AllSame_LeavesOne;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    V.LoadFrom([7, 7, 7, 7, 7]);
    V.Dedup;
    
    AssertEquals('Should leave one element', 1, V.GetCount);
    AssertEquals('[0]', 7, V.Get(0));
  finally
    V.Free;
  end;
end;

procedure TTestVecDedup.Test_Dedup_EmptyVec_NoChange;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    V.Dedup;
    AssertEquals('Empty vec stays empty', 0, V.GetCount);
  finally
    V.Free;
  end;
end;

procedure TTestVecDedup.Test_Dedup_SingleElement_NoChange;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    V.LoadFrom([42]);
    V.Dedup;
    
    AssertEquals('Single element unchanged', 1, V.GetCount);
    AssertEquals('[0]', 42, V.Get(0));
  finally
    V.Free;
  end;
end;

procedure TTestVecDedup.Test_DedupBy_CustomEquals_Works;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    // 使用绝对值比较：[-1, 1, -2, 2, 3] -> [-1, -2, 3]
    // 连续的 -1 和 1 绝对值相同，保留第一个
    V.LoadFrom([-1, 1, -2, 2, 3]);
    V.DedupBy(@AbsEquals, nil);
    
    AssertEquals('Count after DedupBy', 3, V.GetCount);
    AssertEquals('[0]', -1, V.Get(0));
    AssertEquals('[1]', -2, V.Get(1));
    AssertEquals('[2]', 3, V.Get(2));
  finally
    V.Free;
  end;
end;

procedure TTestVecDedup.Test_DedupBy_IgnoreCase_Works;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    // 测试连续相同绝对值的去重
    // [1, -1, -1, 2, -2] -> [1, 2]
    V.LoadFrom([1, -1, -1, 2, -2]);
    V.DedupBy(@AbsEquals, nil);
    
    AssertEquals('Count after DedupBy', 2, V.GetCount);
    AssertEquals('[0]', 1, V.Get(0));
    AssertEquals('[1]', 2, V.Get(1));
  finally
    V.Free;
  end;
end;

procedure TTestVecDedup.Test_Dedup_ReturnsRemovedCount;
var
  V: TIntVec;
  Removed: SizeUInt;
begin
  V := TIntVec.Create;
  try
    V.LoadFrom([1, 1, 2, 2, 2, 3]);
    Removed := V.Dedup;
    
    AssertEquals('Should return removed count', 3, Removed);
    AssertEquals('Final count', 3, V.GetCount);
  finally
    V.Free;
  end;
end;

initialization
  RegisterTest(TTestVecDedup);

end.
