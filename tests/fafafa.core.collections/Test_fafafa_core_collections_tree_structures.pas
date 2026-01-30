unit Test_fafafa_core_collections_tree_structures;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fgl,
  fafafa.core.collections.base,
  fafafa.core.collections.treemap,
  fafafa.core.collections.treeSet;

type
  TIntList = specialize TFPGList<Integer>;

  { 针对 TTreeMap 的核心语义测试 }
  TTestCase_TreeMap = class(TTestCase)
  strict private
    class function CompareIntegers(const aLeft, aRight: Integer; aData: Pointer): SizeInt; static;
    function CreateIntMap: specialize TTreeMap<Integer, string>;
    procedure PopulateSample(const aMap: specialize TTreeMap<Integer, string>);
  published
    procedure Test_Put_Get_Remove_Workflow;
    procedure Test_LowerUpperBounds;
    procedure Test_RangeTraversal_IsSorted;
    procedure Test_FloorAndCeiling_Boundaries;
    procedure Test_Clear_RemovesAllEntries;
  end;

  { 针对 TTreeSet 的集合运算测试 }
  TTestCase_TreeSet = class(TTestCase)
  private
    procedure AssertArrayEquals(const aMsg: string; const aExpected: array of Integer; const aActual: specialize TGenericArray<Integer>);
  published
    procedure Test_AddRemove_ToArraySorted;
    procedure Test_SetOperations_UnionIntersectDifference;
  end;

implementation

{ TTestCase_TreeMap }

class function TTestCase_TreeMap.CompareIntegers(const aLeft, aRight: Integer; aData: Pointer): SizeInt;
begin
  Result := aLeft - aRight;
end;

function TTestCase_TreeMap.CreateIntMap: specialize TTreeMap<Integer, string>;
begin
  Result := specialize TTreeMap<Integer, string>.Create(nil, @CompareIntegers);
end;

procedure TTestCase_TreeMap.PopulateSample(const aMap: specialize TTreeMap<Integer, string>);
begin
  aMap.Put(5, 'v5');
  aMap.Put(10, 'v10');
  aMap.Put(15, 'v15');
  aMap.Put(20, 'v20');
  aMap.Put(30, 'v30');
end;

procedure TTestCase_TreeMap.Test_Put_Get_Remove_Workflow;
var
  LMap: specialize TTreeMap<Integer, string>;
  LValue: string;
begin
  LMap := CreateIntMap;
  try
    AssertFalse('首次插入应返回 False（旧值不存在）', LMap.Put(10, 'ten'));
    AssertFalse('第二个键同样如此', LMap.Put(5, 'five'));

    AssertTrue('Get 应命中已插入的键', LMap.Get(5, LValue));
    AssertEquals('five', LValue);

    AssertTrue('第二次 Put 相同键应返回 True（表示发生覆盖）', LMap.Put(5, 'FIVE'));
    AssertTrue('覆盖后仍应可读取', LMap.Get(5, LValue));
    AssertEquals('FIVE', LValue);

    AssertTrue('Remove 第一次应成功', LMap.Remove(10));
    AssertFalse('Remove 第二次应失败', LMap.Remove(10));
    AssertFalse('被删除的键不应再命中', LMap.Get(10, LValue));
    AssertEquals('计数应只剩 1', SizeUInt(1), LMap.GetCount);
  finally
    LMap.Free;
  end;
end;

procedure TTestCase_TreeMap.Test_LowerUpperBounds;
var
  LMap: specialize TTreeMap<Integer, string>;
  LValue: string;
begin
  LMap := CreateIntMap;
  try
    PopulateSample(LMap);

    AssertTrue('LowerBound(1) 应命中最小键', LMap.GetLowerBound(1, LValue));
    AssertEquals('v5', LValue);

    AssertTrue('LowerBound(12) 应命中 15', LMap.GetLowerBound(12, LValue));
    AssertEquals('v15', LValue);

    AssertTrue('UpperBound(15) 应命中 20', LMap.GetUpperBound(15, LValue));
    AssertEquals('v20', LValue);

    AssertFalse('UpperBound(35) 超出上界应返回 False', LMap.GetUpperBound(35, LValue));
  finally
    LMap.Free;
  end;
end;

threadvar
  GRangeCapture: TIntList;

procedure RangeCollector(const aEntry: specialize TMapEntry<Integer, string>; aData: Pointer);
begin
  if Assigned(GRangeCapture) then
    GRangeCapture.Add(aEntry.Key);
end;

procedure TTestCase_TreeMap.Test_RangeTraversal_IsSorted;
var
  LMap: specialize TTreeMap<Integer, string>;
  LKeys: TIntList;
begin
  LMap := CreateIntMap;
  try
    PopulateSample(LMap);

    LKeys := TIntList.Create;
    try
      GRangeCapture := LKeys;
      try
        AssertTrue('范围查询应成功执行', LMap.GetRange(9, 24, @RangeCollector));
      finally
        GRangeCapture := nil;
      end;
      AssertEquals('范围 [9,24] 应命中 3 个键', 3, LKeys.Count);
      AssertEquals('应按排序顺序返回 10', 10, LKeys[0]);
      AssertEquals('应按排序顺序返回 15', 15, LKeys[1]);
      AssertEquals('应按排序顺序返回 20', 20, LKeys[2]);
    finally
      LKeys.Free;
    end;
  finally
    LMap.Free;
  end;
end;

procedure TTestCase_TreeMap.Test_FloorAndCeiling_Boundaries;
var
  LMap: specialize TTreeMap<Integer, string>;
  LValue: string;
begin
  LMap := CreateIntMap;
  try
    PopulateSample(LMap);

    AssertTrue('Ceiling(4) 应命中 5', LMap.Ceiling(4, LValue));
    AssertEquals('v5', LValue);

    AssertTrue('Ceiling(15) 应返回自身', LMap.Ceiling(15, LValue));
    AssertEquals('v15', LValue);

    AssertTrue('Floor(19) 应返回 15', LMap.Floor(19, LValue));
    AssertEquals('v15', LValue);

    AssertTrue('Floor(31) 应返回最大键', LMap.Floor(31, LValue));
    AssertEquals('v30', LValue);

    AssertFalse('Floor(2) 低于最小值应返回 False', LMap.Floor(2, LValue));
    AssertFalse('Ceiling(31) 超过最大值应返回 False', LMap.Ceiling(31, LValue));
  finally
    LMap.Free;
  end;
end;

procedure TTestCase_TreeMap.Test_Clear_RemovesAllEntries;
var
  LMap: specialize TTreeMap<Integer, string>;
  LValue: string;
begin
  LMap := CreateIntMap;
  try
    PopulateSample(LMap);
    LMap.Clear;

    AssertEquals('Clear 后计数应为 0', SizeUInt(0), LMap.GetCount);
    AssertFalse('Clear 后 ContainsKey 应返回 False', LMap.ContainsKey(10));
    AssertFalse('Clear 后 Get 应失败', LMap.Get(5, LValue));
    AssertFalse('Clear 后 Floor 不应命中', LMap.Floor(5, LValue));
  finally
    LMap.Free;
  end;
end;

{ TTestCase_TreeSet }

procedure TTestCase_TreeSet.AssertArrayEquals(const aMsg: string; const aExpected: array of Integer; const aActual: specialize TGenericArray<Integer>);
var
  I: SizeInt;
begin
  AssertEquals(aMsg + string(' 长度不一致'), Length(aExpected), Length(aActual));
  for I := 0 to High(aExpected) do
    AssertEquals(
      Format('%s 索引 %d', [aMsg, I]),
      aExpected[I],
      aActual[I]
    );
end;

procedure TTestCase_TreeSet.Test_AddRemove_ToArraySorted;
var
  LSet: specialize ITreeSet<Integer>;
  LArray: specialize TGenericArray<Integer>;
begin
  LSet := specialize TTreeSet<Integer>.Create;

  AssertTrue(LSet.Add(5));
  AssertTrue(LSet.Add(1));
  AssertTrue(LSet.Add(3));
  AssertFalse('重复元素应返回 False', LSet.Add(3));

  LArray := LSet.ToArray;
  AssertArrayEquals('TreeSet ToArray', [1, 3, 5], LArray);

  AssertTrue('Contains 应命中已存在的值', LSet.Contains(3));
  AssertTrue('Remove 第一次应成功', LSet.Remove(3));
  AssertFalse('Remove 第二次应失败', LSet.Remove(3));
  AssertFalse('值已删除，不应再次命中', LSet.Contains(3));
  AssertEquals('剩余元素数量应为 2', SizeUInt(2), LSet.GetCount);
end;

procedure TTestCase_TreeSet.Test_SetOperations_UnionIntersectDifference;
var
  SetA, SetB, UnionSet, InterSet, DiffSet: specialize ITreeSet<Integer>;
begin
  SetA := specialize TTreeSet<Integer>.Create;
  SetB := specialize TTreeSet<Integer>.Create;

  SetA.Add(1); SetA.Add(2); SetA.Add(3); SetA.Add(4);
  SetB.Add(3); SetB.Add(4); SetB.Add(5);

  UnionSet := SetA.Union(SetB);
  AssertArrayEquals('Union 结果', [1, 2, 3, 4, 5], UnionSet.ToArray);

  InterSet := SetA.Intersect(SetB);
  AssertArrayEquals('Intersect 结果', [3, 4], InterSet.ToArray);

  DiffSet := SetA.Difference(SetB);
  AssertArrayEquals('Difference 结果', [1, 2], DiffSet.ToArray);

  AssertEquals('集合操作不应修改原始 SetA', SizeUInt(4), SetA.GetCount);
  AssertEquals('集合操作不应修改原始 SetB', SizeUInt(3), SetB.GetCount);
end;

initialization
  RegisterTest(TTestCase_TreeMap);
  RegisterTest(TTestCase_TreeSet);

end.
