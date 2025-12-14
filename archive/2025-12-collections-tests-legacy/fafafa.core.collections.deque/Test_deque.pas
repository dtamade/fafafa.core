unit Test_deque;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.base,
  fafafa.core.collections.base,
  fafafa.core.collections.deque,
  fafafa.core.collections.vecdeque,
  fafafa.core.collections.elementManager,
  fafafa.core.mem.allocator;

type

  generic TTestDeque<T> = class(specialize TVecDeque<T>)
  public
    function TryBack(out aElement: T): Boolean;
    function TryFront(out aElement: T): Boolean;
    procedure AddRange(const aValues: array of T); reintroduce; overload;
    procedure AddRange(const aOther: specialize TVecDeque<T>); overload;
  end;

  { TTestCase_TDeque }

  TTestCase_TDeque = class(TTestCase)
  private
    FDeque: specialize TTestDeque<Integer>;
    FStringDeque: specialize TTestDeque<string>;
    
    // 测试辅助字段
    FForEachCounter: SizeInt;
    FForEachSum: SizeInt;
    
    // 测试辅助方法
    function ForEachTestMethod(const aValue: Integer; aData: Pointer): Boolean;
    function EqualsTestMethod(const aValue1, aValue2: Integer; aData: Pointer): Boolean;
    function CompareTestMethod(const aValue1, aValue2: Integer; aData: Pointer): SizeInt;
    function PredicateTestMethod(const aValue: Integer; aData: Pointer): Boolean;
    
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    
  published
    // 构造函数测试
    procedure Test_TDeque_Create;
    procedure Test_TDeque_Create_Capacity;
    procedure Test_TDeque_Create_Allocator;
    procedure Test_TDeque_Create_Collection;
    
    // IDeque 接口测试
    procedure Test_TDeque_PushBack;
    procedure Test_TDeque_PopBack;
    procedure Test_TDeque_TryPopBack;
    procedure Test_TDeque_Back;
    procedure Test_TDeque_TryBack;
    procedure Test_TDeque_PushFront;
    procedure Test_TDeque_PopFront;
    procedure Test_TDeque_TryPopFront;
    procedure Test_TDeque_Front;
    procedure Test_TDeque_TryFront;
    
    // IGenericCollection 接口测试
    procedure Test_TDeque_Add;
    procedure Test_TDeque_AddRange_Array;
    procedure Test_TDeque_AddRange_Collection;
    procedure Test_TDeque_Insert;
    procedure Test_TDeque_InsertRange_Array;
    procedure Test_TDeque_InsertRange_Collection;
    procedure Test_TDeque_Remove;
    procedure Test_TDeque_RemoveAt;
    procedure Test_TDeque_RemoveRange;
    procedure Test_TDeque_IndexOf;
    procedure Test_TDeque_LastIndexOf;
    procedure Test_TDeque_Contains;
    procedure Test_TDeque_Find;
    procedure Test_TDeque_FindLast;
    procedure Test_TDeque_FindAll;
    procedure Test_TDeque_Sort;
    procedure Test_TDeque_Reverse;
    procedure Test_TDeque_ForEach;
    
    // ICollection 接口测试
    procedure Test_TDeque_GetCount;
    procedure Test_TDeque_IsEmpty;
    procedure Test_TDeque_Clear;
    procedure Test_TDeque_ToArray;
    procedure Test_TDeque_Assign;
    procedure Test_TDeque_Clone;
    procedure Test_TDeque_Equal;
    
    // 容量管理测试
    procedure Test_TDeque_GetCapacity;
    procedure Test_TDeque_SetCapacity;
    procedure Test_TDeque_ShrinkToFit;
    procedure Test_TDeque_Reserve;
    
    // 高级功能测试
    procedure Test_TDeque_GetAllocator;
    procedure Test_TDeque_Resize;
    procedure Test_TDeque_Swap;
    procedure Test_TDeque_Append_BatchMove;
    procedure Test_TDeque_Append_SelfGuard;
    procedure Test_TDeque_Append_GenericQueue;
    
    // 异常测试
    procedure Test_TDeque_PopBack_Empty;
    procedure Test_TDeque_PopFront_Empty;
    procedure Test_TDeque_Back_Empty;
    procedure Test_TDeque_Front_Empty;
    procedure Test_TDeque_RemoveAt_OutOfRange;
    procedure Test_TDeque_Insert_OutOfRange;
    
    // 边界条件测试
    procedure Test_TDeque_EmptyDeque_Operations;
    procedure Test_TDeque_SingleElement_Operations;
    procedure Test_TDeque_LargeDeque_Operations;
    
    // 性能测试
    procedure Test_TDeque_Performance_PushBack;
    procedure Test_TDeque_Performance_PushFront;
    procedure Test_TDeque_Performance_Access;
    procedure Test_TDeque_Performance_Sort;
  end;

// 全局测试辅助函数
function ForEachTestFunc(const aValue: Integer; aData: Pointer): Boolean;
function EqualsTestFunc(const aValue1, aValue2: Integer; aData: Pointer): Boolean;
function CompareTestFunc(const aValue1, aValue2: Integer; aData: Pointer): SizeInt;
function PredicateTestFunc(const aValue: Integer; aData: Pointer): Boolean;

implementation

{ TTestDeque<T> 辅助方法，用于兼容历史测试接口 }

function TTestDeque.TryBack(out aElement: T): Boolean;
begin
  Result := TryPeekBack(aElement);
end;

function TTestDeque.TryFront(out aElement: T): Boolean;
begin
  Result := TryPeekFront(aElement);
end;

procedure TTestDeque.AddRange(const aValues: array of T);
begin
  PushBackRange(aValues);
end;

procedure TTestDeque.AddRange(const aOther: specialize TVecDeque<T>);
var
  LIndex: SizeUInt;
begin
  if aOther = nil then
    Exit;

  Reserve(aOther.GetCount);
  for LIndex := 0 to aOther.GetCount - 1 do
    PushBack(aOther.Get(LIndex));
end;

// 全局测试辅助函数实现
function ForEachTestFunc(const aValue: Integer; aData: Pointer): Boolean;
var
  LCounter: PInteger;
begin
  LCounter := PInteger(aData);
  Inc(LCounter^);
  Result := True;
end;

function EqualsTestFunc(const aValue1, aValue2: Integer; aData: Pointer): Boolean;
begin
  Result := aValue1 = aValue2;
end;

function CompareTestFunc(const aValue1, aValue2: Integer; aData: Pointer): SizeInt;
begin
  if aValue1 < aValue2 then
    Result := -1
  else if aValue1 > aValue2 then
    Result := 1
  else
    Result := 0;
end;

function PredicateTestFunc(const aValue: Integer; aData: Pointer): Boolean;
begin
  Result := (aValue mod 2) = 0; // 偶数
end;

{ TTestCase_TDeque }

procedure TTestCase_TDeque.SetUp;
begin
  inherited SetUp;
  FDeque := specialize TTestDeque<Integer>.Create;
  FStringDeque := specialize TTestDeque<string>.Create;
  FForEachCounter := 0;
  FForEachSum := 0;
end;

procedure TTestCase_TDeque.TearDown;
begin
  FDeque.Free;
  FStringDeque.Free;
  inherited TearDown;
end;

function TTestCase_TDeque.ForEachTestMethod(const aValue: Integer; aData: Pointer): Boolean;
begin
  Inc(FForEachCounter);
  FForEachSum := FForEachSum + aValue;
  Result := True;
end;

function TTestCase_TDeque.EqualsTestMethod(const aValue1, aValue2: Integer; aData: Pointer): Boolean;
begin
  Result := aValue1 = aValue2;
end;

function TTestCase_TDeque.CompareTestMethod(const aValue1, aValue2: Integer; aData: Pointer): SizeInt;
begin
  if aValue1 < aValue2 then
    Result := -1
  else if aValue1 > aValue2 then
    Result := 1
  else
    Result := 0;
end;

function TTestCase_TDeque.PredicateTestMethod(const aValue: Integer; aData: Pointer): Boolean;
begin
  Result := (aValue mod 2) = 0; // 偶数
end;

procedure TTestCase_TDeque.Test_TDeque_Create;
begin
  AssertEquals('新建双端队列计数应为0', 0, Int64(FDeque.GetCount));
  AssertTrue('新建双端队列应为空', FDeque.IsEmpty);
  AssertTrue('新建双端队列容量应大于0', FDeque.GetCapacity > 0);
end;

procedure TTestCase_TDeque.Test_TDeque_Create_Capacity;
var
  LDeque: specialize TTestDeque<Integer>;
  LCapacity: SizeUInt;
begin
  LCapacity := 100;
  LDeque := specialize TTestDeque<Integer>.Create(LCapacity);
  try
    AssertEquals('指定容量创建双端队列计数应为0', 0, Int64(LDeque.GetCount));
    AssertTrue('指定容量创建双端队列应为空', LDeque.IsEmpty);
    AssertTrue('双端队列容量应大于等于指定容量', LDeque.GetCapacity >= LCapacity);
  finally
    LDeque.Free;
  end;
end;

procedure TTestCase_TDeque.Test_TDeque_Create_Allocator;
var
  LDeque: specialize TTestDeque<Integer>;
  LAllocator: IAllocator;
begin
  LAllocator := GetCrtAllocator;
  LDeque := specialize TTestDeque<Integer>.Create(LAllocator);
  try
    AssertEquals('使用分配器创建双端队列计数应为0', 0, Int64(LDeque.GetCount));
    AssertTrue('使用分配器创建双端队列应为空', LDeque.IsEmpty);
    AssertTrue('分配器应正确设置', LDeque.GetAllocator = LAllocator);
  finally
    LDeque.Free;
  end;
end;

procedure TTestCase_TDeque.Test_TDeque_Create_Collection;
var
  LSourceDeque, LTargetDeque: specialize TTestDeque<Integer>;
begin
  LSourceDeque := specialize TTestDeque<Integer>.Create;
  try
    // 准备源数据
    LSourceDeque.PushBack(10);
    LSourceDeque.PushBack(20);
    LSourceDeque.PushBack(30);
    
    // 从集合创建
    LTargetDeque := specialize TTestDeque<Integer>.Create(LSourceDeque);
    try
      AssertEquals('从集合创建双端队列计数应正确', Int64(LSourceDeque.GetCount), Int64(LTargetDeque.GetCount));
      AssertEquals('第一个元素应正确', 10, LTargetDeque.Front);
      AssertEquals('最后一个元素应正确', 30, LTargetDeque.Back);
    finally
      LTargetDeque.Free;
    end;
  finally
    LSourceDeque.Free;
  end;
end;

procedure TTestCase_TDeque.Test_TDeque_PushBack;
begin
  AssertEquals('初始双端队列计数应为0', 0, Int64(FDeque.GetCount));

  FDeque.PushBack(10);
  AssertEquals('PushBack一个元素后计数应为1', 1, Int64(FDeque.GetCount));
  AssertEquals('PushBack的元素应在末尾', 10, FDeque.Back);
  AssertEquals('PushBack的元素也应在开头', 10, FDeque.Front);

  FDeque.PushBack(20);
  AssertEquals('PushBack第二个元素后计数应为2', 2, Int64(FDeque.GetCount));
  AssertEquals('Front应保持为10', 10, FDeque.Front);
  AssertEquals('Back应为20', 20, FDeque.Back);
end;

procedure TTestCase_TDeque.Test_TDeque_PopBack;
var
  LValue: Integer;
begin
  // 准备测试数据
  FDeque.PushBack(10);
  FDeque.PushBack(20);
  FDeque.PushBack(30);

  // 测试弹出元素
  LValue := FDeque.PopBack;
  AssertEquals('PopBack应返回30', 30, LValue);
  AssertEquals('PopBack后计数应为2', 2, Int64(FDeque.GetCount));
  AssertEquals('新的Back应为20', 20, FDeque.Back);
  AssertEquals('Front应保持不变', 10, FDeque.Front);
end;

procedure TTestCase_TDeque.Test_TDeque_TryPopBack;
var
  LValue: Integer;
  LResult: Boolean;
begin
  // 测试空双端队列
  LResult := FDeque.TryPopBack(LValue);
  AssertFalse('空双端队列TryPopBack应返回False', LResult);

  // 添加元素并测试
  FDeque.PushBack(42);
  LResult := FDeque.TryPopBack(LValue);
  AssertTrue('非空双端队列TryPopBack应返回True', LResult);
  AssertEquals('弹出的值应为42', 42, LValue);
  AssertTrue('弹出后双端队列应为空', FDeque.IsEmpty);
end;

procedure TTestCase_TDeque.Test_TDeque_Back;
begin
  // 添加测试数据
  FDeque.PushBack(100);
  AssertEquals('Back应返回100', 100, FDeque.Back);

  FDeque.PushBack(200);
  AssertEquals('Back应返回200', 200, FDeque.Back);

  // 验证Back不会修改双端队列
  AssertEquals('调用Back后计数应保持不变', 2, Int64(FDeque.GetCount));
end;

procedure TTestCase_TDeque.Test_TDeque_TryBack;
var
  LValue: Integer;
  LResult: Boolean;
begin
  // 测试空双端队列
  LResult := FDeque.TryBack(LValue);
  AssertFalse('空双端队列TryBack应返回False', LResult);

  // 添加元素并测试
  FDeque.PushBack(123);
  LResult := FDeque.TryBack(LValue);
  AssertTrue('非空双端队列TryBack应返回True', LResult);
  AssertEquals('获取的值应为123', 123, LValue);
  AssertEquals('TryBack不应修改计数', 1, Int64(FDeque.GetCount));
end;

procedure TTestCase_TDeque.Test_TDeque_PushFront;
begin
  AssertEquals('初始双端队列计数应为0', 0, Int64(FDeque.GetCount));

  FDeque.PushFront(10);
  AssertEquals('PushFront一个元素后计数应为1', 1, Int64(FDeque.GetCount));
  AssertEquals('PushFront的元素应在开头', 10, FDeque.Front);
  AssertEquals('PushFront的元素也应在末尾', 10, FDeque.Back);

  FDeque.PushFront(20);
  AssertEquals('PushFront第二个元素后计数应为2', 2, Int64(FDeque.GetCount));
  AssertEquals('新的Front应为20', 20, FDeque.Front);
  AssertEquals('Back应保持为10', 10, FDeque.Back);
end;

procedure TTestCase_TDeque.Test_TDeque_PopFront;
var
  LValue: Integer;
begin
  // 准备测试数据
  FDeque.PushBack(10);
  FDeque.PushBack(20);
  FDeque.PushBack(30);

  // 测试弹出前端元素
  LValue := FDeque.PopFront;
  AssertEquals('PopFront应返回10', 10, LValue);
  AssertEquals('PopFront后计数应为2', 2, Int64(FDeque.GetCount));
  AssertEquals('新的Front应为20', 20, FDeque.Front);
  AssertEquals('Back应保持不变', 30, FDeque.Back);
end;

procedure TTestCase_TDeque.Test_TDeque_TryPopFront;
var
  LValue: Integer;
  LResult: Boolean;
begin
  // 测试空双端队列
  LResult := FDeque.TryPopFront(LValue);
  AssertFalse('空双端队列TryPopFront应返回False', LResult);

  // 添加元素并测试
  FDeque.PushBack(42);
  LResult := FDeque.TryPopFront(LValue);
  AssertTrue('非空双端队列TryPopFront应返回True', LResult);
  AssertEquals('弹出的值应为42', 42, LValue);
  AssertTrue('弹出后双端队列应为空', FDeque.IsEmpty);
end;

procedure TTestCase_TDeque.Test_TDeque_Front;
begin
  // 添加测试数据
  FDeque.PushBack(100);
  AssertEquals('Front应返回100', 100, FDeque.Front);

  FDeque.PushFront(200);
  AssertEquals('Front应返回200', 200, FDeque.Front);

  // 验证Front不会修改双端队列
  AssertEquals('调用Front后计数应保持不变', 2, Int64(FDeque.GetCount));
end;

procedure TTestCase_TDeque.Test_TDeque_TryFront;
var
  LValue: Integer;
  LResult: Boolean;
begin
  // 测试空双端队列
  LResult := FDeque.TryFront(LValue);
  AssertFalse('空双端队列TryFront应返回False', LResult);

  // 添加元素并测试
  FDeque.PushBack(123);
  LResult := FDeque.TryFront(LValue);
  AssertTrue('非空双端队列TryFront应返回True', LResult);
  AssertEquals('获取的值应为123', 123, LValue);
  AssertEquals('TryFront不应修改计数', 1, Int64(FDeque.GetCount));
end;

// 基本集合操作测试
procedure TTestCase_TDeque.Test_TDeque_Add;
var
  LOriginalCount: SizeUInt;
begin
  LOriginalCount := FDeque.GetCount;

  // 添加元素
  FDeque.Add(42);

  AssertEquals('Add后计数应增加1', Int64(LOriginalCount + 1), Int64(FDeque.GetCount));
  AssertEquals('添加的元素应在末尾', 42, FDeque.Back);
end;

procedure TTestCase_TDeque.Test_TDeque_AddRange_Array;
var
  LSourceArray: array[0..2] of Integer;
  LOriginalCount: SizeUInt;
begin
  LSourceArray[0] := 100;
  LSourceArray[1] := 200;
  LSourceArray[2] := 300;

  LOriginalCount := FDeque.GetCount;

  // 添加数组范围
  FDeque.AddRange(LSourceArray);

  AssertEquals('AddRange后计数应正确', Int64(LOriginalCount + 3), Int64(FDeque.GetCount));
  AssertEquals('添加的最后一个元素应正确', 300, FDeque.Back);
end;

procedure TTestCase_TDeque.Test_TDeque_AddRange_Collection;
var
  LSourceDeque: specialize TTestDeque<Integer>;
  LOriginalCount: SizeUInt;
begin
  LSourceDeque := specialize TTestDeque<Integer>.Create;
  try
    LSourceDeque.PushBack(500);
    LSourceDeque.PushBack(600);

    LOriginalCount := FDeque.GetCount;

    // 添加集合范围
    FDeque.AddRange(LSourceDeque);

    AssertEquals('AddRange集合后计数应正确', Int64(LOriginalCount + 2), Int64(FDeque.GetCount));
    AssertEquals('添加的最后一个元素应正确', 600, FDeque.Back);
  finally
    LSourceDeque.Free;
  end;
end;

// 其他基本测试方法
procedure TTestCase_TDeque.Test_TDeque_Insert;
begin
  // 添加初始数据
  FDeque.PushBack(10);
  FDeque.PushBack(30);

  // 在中间插入
  FDeque.Insert(1, 20);

  AssertEquals('Insert后计数应为3', 3, Int64(FDeque.GetCount));
  AssertEquals('第一个元素应不变', 10, FDeque.Front);
  AssertEquals('最后一个元素应不变', 30, FDeque.Back);
end;

procedure TTestCase_TDeque.Test_TDeque_InsertRange_Array;
var
  LArray: array[0..1] of Integer;
begin
  // 基本插入范围测试
  FDeque.PushBack(10);
  FDeque.PushBack(30);

  LArray[0] := 15;
  LArray[1] := 25;

  FDeque.InsertRange(1, LArray);
  AssertEquals('InsertRange后计数应为4', 4, Int64(FDeque.GetCount));
end;

procedure TTestCase_TDeque.Test_TDeque_InsertRange_Collection;
var
  LSourceDeque: specialize TTestDeque<Integer>;
begin
  // 基本插入集合测试
  FDeque.PushBack(10);
  FDeque.PushBack(30);

  LSourceDeque := specialize TTestDeque<Integer>.Create;
  try
    LSourceDeque.PushBack(15);
    LSourceDeque.PushBack(25);

    FDeque.InsertRange(1, LSourceDeque);
    AssertEquals('InsertRange集合后计数应为4', 4, Int64(FDeque.GetCount));
  finally
    LSourceDeque.Free;
  end;
end;

procedure TTestCase_TDeque.Test_TDeque_Remove;
var
  LRemoved: Boolean;
begin
  FDeque.PushBack(10);
  FDeque.PushBack(20);
  FDeque.PushBack(10);

  LRemoved := FDeque.Remove(10);
  AssertTrue('Remove应返回True', LRemoved);
  AssertEquals('Remove后计数应减少', 2, Int64(FDeque.GetCount));
end;

procedure TTestCase_TDeque.Test_TDeque_RemoveAt;
begin
  FDeque.PushBack(10);
  FDeque.PushBack(20);
  FDeque.PushBack(30);

  FDeque.RemoveAt(1);
  AssertEquals('RemoveAt后计数应减少', 2, Int64(FDeque.GetCount));
end;

procedure TTestCase_TDeque.Test_TDeque_RemoveRange;
begin
  FDeque.PushBack(10);
  FDeque.PushBack(20);
  FDeque.PushBack(30);
  FDeque.PushBack(40);

  FDeque.RemoveRange(1, 2);
  AssertEquals('RemoveRange后计数应正确', 2, Int64(FDeque.GetCount));
end;

procedure TTestCase_TDeque.Test_TDeque_IndexOf;
var
  LIndex: SizeInt;
begin
  FDeque.PushBack(10);
  FDeque.PushBack(20);
  FDeque.PushBack(30);

  LIndex := FDeque.IndexOf(20);
  AssertEquals('IndexOf应返回正确索引', 1, LIndex);

  LIndex := FDeque.IndexOf(999);
  AssertEquals('IndexOf不存在元素应返回-1', -1, LIndex);
end;

procedure TTestCase_TDeque.Test_TDeque_LastIndexOf;
var
  LIndex: SizeInt;
begin
  FDeque.PushBack(10);
  FDeque.PushBack(20);
  FDeque.PushBack(20);
  FDeque.PushBack(30);

  LIndex := FDeque.LastIndexOf(20);
  AssertEquals('LastIndexOf应返回最后索引', 2, LIndex);
end;

procedure TTestCase_TDeque.Test_TDeque_Contains;
begin
  FDeque.PushBack(10);
  FDeque.PushBack(20);

  AssertTrue('Contains存在元素应返回True', FDeque.Contains(20));
  AssertFalse('Contains不存在元素应返回False', FDeque.Contains(999));
end;

procedure TTestCase_TDeque.Test_TDeque_Find;
var
  LIndex: SizeInt;
begin
  FDeque.PushBack(1);
  FDeque.PushBack(2);
  FDeque.PushBack(3);

  LIndex := FDeque.Find(@PredicateTestFunc, nil);
  AssertEquals('Find应找到第一个偶数', 1, LIndex);
end;

procedure TTestCase_TDeque.Test_TDeque_FindLast;
var
  LIndex: SizeInt;
begin
  FDeque.PushBack(1);
  FDeque.PushBack(2);
  FDeque.PushBack(3);
  FDeque.PushBack(4);

  LIndex := FDeque.FindLast(@PredicateTestFunc, nil);
  AssertEquals('FindLast应找到最后偶数', 3, LIndex);
end;

procedure TTestCase_TDeque.Test_TDeque_FindAll;
var
  LIndices: specialize TVecDeque<SizeInt>;
begin
  FDeque.PushBack(1);
  FDeque.PushBack(2);
  FDeque.PushBack(3);
  FDeque.PushBack(4);

  LIndices := FDeque.FindAll(@PredicateTestFunc, nil);
  try
    AssertEquals('FindAll应返回两个偶数索引', 2, Int64(LIndices.GetCount));
    AssertEquals('第一个偶数索引应为1', 1, LIndices.Get(0));
    AssertEquals('第二个偶数索引应为3', 3, LIndices.Get(1));
  finally
    LIndices.Free;
  end;
end;

procedure TTestCase_TDeque.Test_TDeque_Sort;
begin
  FDeque.PushBack(30);
  FDeque.PushBack(10);
  FDeque.PushBack(20);

  FDeque.Sort(@CompareTestFunc, nil);

  AssertEquals('排序后第一个元素应为10', 10, FDeque.Front);
  AssertEquals('排序后最后一个元素应为30', 30, FDeque.Back);
end;

procedure TTestCase_TDeque.Test_TDeque_Reverse;
begin
  FDeque.PushBack(10);
  FDeque.PushBack(20);
  FDeque.PushBack(30);

  FDeque.Reverse;

  AssertEquals('反转后第一个元素应为30', 30, FDeque.Front);
  AssertEquals('反转后最后一个元素应为10', 10, FDeque.Back);
end;

procedure TTestCase_TDeque.Test_TDeque_ForEach;
begin
  FDeque.PushBack(10);
  FDeque.PushBack(20);
  FDeque.PushBack(30);

  FForEachCounter := 0;
  FForEachSum := 0;

  FDeque.ForEach(@ForEachTestMethod, nil);

  AssertEquals('ForEach应遍历所有元素', 3, FForEachCounter);
  AssertEquals('ForEach应正确累加', 60, FForEachSum);
end;

// ICollection 接口测试
procedure TTestCase_TDeque.Test_TDeque_GetCount;
begin
  AssertEquals('空双端队列计数应为0', 0, Int64(FDeque.GetCount));

  FDeque.PushBack(10);
  AssertEquals('添加元素后计数应为1', 1, Int64(FDeque.GetCount));
end;

procedure TTestCase_TDeque.Test_TDeque_IsEmpty;
begin
  AssertTrue('空双端队列IsEmpty应为True', FDeque.IsEmpty);

  FDeque.PushBack(10);
  AssertFalse('非空双端队列IsEmpty应为False', FDeque.IsEmpty);
end;

procedure TTestCase_TDeque.Test_TDeque_Clear;
begin
  FDeque.PushBack(10);
  FDeque.PushBack(20);

  FDeque.Clear;

  AssertEquals('清空后计数应为0', 0, Int64(FDeque.GetCount));
  AssertTrue('清空后应为空', FDeque.IsEmpty);
end;

procedure TTestCase_TDeque.Test_TDeque_ToArray;
begin
  FDeque.PushBack(10);
  FDeque.PushBack(20);
  FDeque.PushBack(30);

  var LArray := FDeque.ToArray;

  AssertEquals('ToArray长度应正确', 3, Length(LArray));
  AssertEquals('ToArray第一个元素应正确', 10, LArray[0]);
end;

procedure TTestCase_TDeque.Test_TDeque_Assign;
begin
  var LSourceDeque := specialize TTestDeque<Integer>.Create;
  try
    LSourceDeque.PushBack(100);
    LSourceDeque.PushBack(200);

    FDeque.Assign(LSourceDeque);

    AssertEquals('Assign后计数应正确', Int64(LSourceDeque.GetCount), Int64(FDeque.GetCount));
    AssertEquals('Assign后元素应正确', 100, FDeque.Front);
  finally
    LSourceDeque.Free;
  end;
end;

procedure TTestCase_TDeque.Test_TDeque_Clone;
begin
  FDeque.PushBack(10);
  FDeque.PushBack(20);

  var LClone := FDeque.Clone;
  try
    AssertEquals('Clone后计数应相同', Int64(FDeque.GetCount), Int64(LClone.GetCount));
    AssertEquals('Clone后元素应正确', 10, LClone.Front);
  finally
    LClone.Free;
  end;
end;

procedure TTestCase_TDeque.Test_TDeque_Equal;
begin
  var LOtherDeque := specialize TTestDeque<Integer>.Create;
  try
    // 两个空双端队列应相等
    AssertTrue('两个空双端队列应相等', FDeque.Equal(LOtherDeque));

    // 添加相同数据
    FDeque.PushBack(10);
    LOtherDeque.PushBack(10);

    AssertTrue('相同数据的双端队列应相等', FDeque.Equal(LOtherDeque));
  finally
    LOtherDeque.Free;
  end;
end;

// 容量管理测试
procedure TTestCase_TDeque.Test_TDeque_GetCapacity;
begin
  var LCapacity := FDeque.GetCapacity;
  AssertTrue('容量应大于0', LCapacity > 0);
end;

procedure TTestCase_TDeque.Test_TDeque_SetCapacity;
begin
  FDeque.SetCapacity(100);
  AssertTrue('设置容量后应大于等于100', FDeque.GetCapacity >= 100);
end;

procedure TTestCase_TDeque.Test_TDeque_ShrinkToFit;
begin
  FDeque.PushBack(10);
  FDeque.SetCapacity(1000);

  FDeque.ShrinkToFit;
  AssertTrue('ShrinkToFit后容量应减少', FDeque.GetCapacity < 1000);
end;

procedure TTestCase_TDeque.Test_TDeque_Reserve;
begin
  var LOriginalCapacity := FDeque.GetCapacity;
  FDeque.Reserve(LOriginalCapacity * 2);
  AssertTrue('Reserve后容量应增加', FDeque.GetCapacity >= LOriginalCapacity * 2);
end;

// 高级功能测试
procedure TTestCase_TDeque.Test_TDeque_GetAllocator;
begin
  var LAllocator := FDeque.GetAllocator;
  AssertNotNull('GetAllocator应返回非空分配器', LAllocator);
end;

procedure TTestCase_TDeque.Test_TDeque_Resize;
begin
  FDeque.PushBack(10);
  FDeque.PushBack(20);

  FDeque.Resize(5);
  AssertEquals('Resize后计数应为5', 5, Int64(FDeque.GetCount));

  FDeque.Resize(1);
  AssertEquals('Resize后计数应为1', 1, Int64(FDeque.GetCount));
end;

procedure TTestCase_TDeque.Test_TDeque_Swap;
begin
  var LOtherDeque := specialize TTestDeque<Integer>.Create;
  try
    FDeque.PushBack(10);
    FDeque.PushBack(20);

    LOtherDeque.PushBack(100);

    FDeque.Swap(LOtherDeque);

    AssertEquals('交换后FDeque计数应为1', 1, Int64(FDeque.GetCount));
    AssertEquals('交换后FDeque元素应为100', 100, FDeque.Front);
    AssertEquals('交换后LOtherDeque计数应为2', 2, Int64(LOtherDeque.GetCount));
  finally
    LOtherDeque.Free;
  end;
end;

procedure TTestCase_TDeque.Test_TDeque_Append_BatchMove;
var
  LTargetDeque: specialize TArrayDeque<Integer>;
  LSourceDeque: specialize TArrayDeque<Integer>;
  LQueue: specialize IQueue<Integer>;
  LIndex: SizeUInt;
begin
  LTargetDeque := specialize TArrayDeque<Integer>.Create;
  try
    LTargetDeque.PushBack(-1);
    LTargetDeque.PushBack(-2);

    LSourceDeque := specialize TArrayDeque<Integer>.Create;
    try
      for LIndex := 0 to 511 do
        LSourceDeque.PushBack(LIndex);

      LQueue := LSourceDeque as specialize IQueue<Integer>;
      LTargetDeque.Append(LQueue);

      AssertEquals('Append should increase count', Int64(514), Int64(LTargetDeque.Count));
      AssertTrue('Source deque should be empty after append', LSourceDeque.IsEmpty);
      AssertEquals('Existing prefix preserved', -1, LTargetDeque.Get(0));
      AssertEquals('Appended sequence should follow original elements', 0, LTargetDeque.Get(2));
      AssertEquals('Appended tail should match last element', 511, LTargetDeque.Get(LTargetDeque.Count - 1));
    finally
      LSourceDeque.Free;
    end;
  finally
    LTargetDeque.Free;
  end;
end;

procedure TTestCase_TDeque.Test_TDeque_Append_SelfGuard;
var
  LTargetDeque: specialize TArrayDeque<Integer>;
  LQueue: specialize IQueue<Integer>;
begin
  LTargetDeque := specialize TArrayDeque<Integer>.Create;
  try
    LQueue := LTargetDeque as specialize IQueue<Integer>;
    AssertException(
      'Appending deque to itself should raise EInvalidOperation',
      EInvalidOperation,
      procedure
      begin
        LTargetDeque.Append(LQueue);
      end);
    AssertEquals('Self append guard should preserve original count', Int64(0), Int64(LTargetDeque.Count));
  finally
    LTargetDeque.Free;
  end;
end;

procedure TTestCase_TDeque.Test_TDeque_Append_GenericQueue;
var
  LTargetDeque: specialize TArrayDeque<Integer>;
  LVecSource: specialize TVecDeque<Integer>;
  LQueue: specialize IQueue<Integer>;
  LIndex: SizeUInt;
begin
  LTargetDeque := specialize TArrayDeque<Integer>.Create;
  try
    LVecSource := specialize TVecDeque<Integer>.Create(GetCrtAllocator);
    try
      for LIndex := 0 to 15 do
        LVecSource.PushBack(LIndex);

      LQueue := LVecSource as specialize IQueue<Integer>;
      LTargetDeque.Append(LQueue);

      AssertEquals('Append from generic queue should increase count', Int64(16), Int64(LTargetDeque.Count));
      AssertTrue('Source IQueue should be empty after append', LVecSource.IsEmpty);
      AssertEquals('First appended element should be 0', 0, LTargetDeque.Get(0));
      AssertEquals('Last appended element should be 15', 15, LTargetDeque.Get(LTargetDeque.Count - 1));
    finally
      LVecSource.Free;
    end;
  finally
    LTargetDeque.Free;
  end;
end;

// 异常测试
procedure TTestCase_TDeque.Test_TDeque_PopBack_Empty;
begin
  try
    FDeque.PopBack;
    Fail('空双端队列PopBack应该抛出异常');
  except
    on E: EInvalidOperation do
      AssertTrue('应该抛出 EInvalidOperation 异常', True);
    on E: Exception do
      Fail('应该抛出 EInvalidOperation 异常，但抛出了: ' + E.ClassName);
  end;
end;

procedure TTestCase_TDeque.Test_TDeque_PopFront_Empty;
begin
  try
    FDeque.PopFront;
    Fail('空双端队列PopFront应该抛出异常');
  except
    on E: EInvalidOperation do
      AssertTrue('应该抛出 EInvalidOperation 异常', True);
    on E: Exception do
      Fail('应该抛出 EInvalidOperation 异常，但抛出了: ' + E.ClassName);
  end;
end;

procedure TTestCase_TDeque.Test_TDeque_Back_Empty;
begin
  try
    FDeque.Back;
    Fail('空双端队列Back应该抛出异常');
  except
    on E: EInvalidOperation do
      AssertTrue('应该抛出 EInvalidOperation 异常', True);
    on E: Exception do
      Fail('应该抛出 EInvalidOperation 异常，但抛出了: ' + E.ClassName);
  end;
end;

procedure TTestCase_TDeque.Test_TDeque_Front_Empty;
begin
  try
    FDeque.Front;
    Fail('空双端队列Front应该抛出异常');
  except
    on E: EInvalidOperation do
      AssertTrue('应该抛出 EInvalidOperation 异常', True);
    on E: Exception do
      Fail('应该抛出 EInvalidOperation 异常，但抛出了: ' + E.ClassName);
  end;
end;

procedure TTestCase_TDeque.Test_TDeque_RemoveAt_OutOfRange;
begin
  try
    FDeque.RemoveAt(0);
    Fail('空双端队列RemoveAt应该抛出异常');
  except
    on E: EOutOfRange do
      AssertTrue('应该抛出 EOutOfRange 异常', True);
    on E: Exception do
      Fail('应该抛出 EOutOfRange 异常，但抛出了: ' + E.ClassName);
  end;
end;

procedure TTestCase_TDeque.Test_TDeque_Insert_OutOfRange;
begin
  try
    FDeque.Insert(1, 42);
    Fail('超出范围Insert应该抛出异常');
  except
    on E: EOutOfRange do
      AssertTrue('应该抛出 EOutOfRange 异常', True);
    on E: Exception do
      Fail('应该抛出 EOutOfRange 异常，但抛出了: ' + E.ClassName);
  end;
end;

// 边界条件测试
procedure TTestCase_TDeque.Test_TDeque_EmptyDeque_Operations;
begin
  AssertEquals('空双端队列计数应为0', 0, Int64(FDeque.GetCount));
  AssertTrue('空双端队列应为空', FDeque.IsEmpty);
  AssertFalse('空双端队列不应包含任何元素', FDeque.Contains(42));

  FDeque.Clear;
  AssertEquals('清空空双端队列后计数仍为0', 0, Int64(FDeque.GetCount));
end;

procedure TTestCase_TDeque.Test_TDeque_SingleElement_Operations;
begin
  FDeque.PushBack(42);

  AssertEquals('单元素双端队列计数应为1', 1, Int64(FDeque.GetCount));
  AssertFalse('单元素双端队列不应为空', FDeque.IsEmpty);
  AssertEquals('单元素双端队列Front应正确', 42, FDeque.Front);
  AssertEquals('单元素双端队列Back应正确', 42, FDeque.Back);

  FDeque.RemoveAt(0);
  AssertEquals('移除单元素后计数应为0', 0, Int64(FDeque.GetCount));
end;

procedure TTestCase_TDeque.Test_TDeque_LargeDeque_Operations;
const
  LARGE_SIZE = 1000;
var
  i: Integer;
begin
  // 添加大量元素
  for i := 0 to LARGE_SIZE - 1 do
    FDeque.PushBack(i);

  AssertEquals('大双端队列计数应正确', LARGE_SIZE, Int64(FDeque.GetCount));
  AssertEquals('Front应正确', 0, FDeque.Front);
  AssertEquals('Back应正确', LARGE_SIZE - 1, FDeque.Back);

  FDeque.Clear;
  AssertEquals('清空后计数应为0', 0, Int64(FDeque.GetCount));
end;

// 性能测试
procedure TTestCase_TDeque.Test_TDeque_Performance_PushBack;
const
  TEST_SIZE = 10000;
var
  i: Integer;
begin
  for i := 0 to TEST_SIZE - 1 do
    FDeque.PushBack(i);

  AssertEquals('性能测试PushBack元素数量应正确', TEST_SIZE, Int64(FDeque.GetCount));
end;

procedure TTestCase_TDeque.Test_TDeque_Performance_PushFront;
const
  TEST_SIZE = 10000;
var
  i: Integer;
begin
  for i := 0 to TEST_SIZE - 1 do
    FDeque.PushFront(i);

  AssertEquals('性能测试PushFront元素数量应正确', TEST_SIZE, Int64(FDeque.GetCount));
end;

procedure TTestCase_TDeque.Test_TDeque_Performance_Access;
const
  TEST_SIZE = 1000;
var
  i: Integer;
  LSum: Int64;
begin
  // 准备数据
  for i := 0 to TEST_SIZE - 1 do
    FDeque.PushBack(i);

  // 访问性能测试
  LSum := 0;
  for i := 0 to TEST_SIZE - 1 do
    LSum := LSum + FDeque.Front;  // 简化的访问测试

  AssertTrue('访问测试应完成', LSum >= 0);
end;

procedure TTestCase_TDeque.Test_TDeque_Performance_Sort;
const
  TEST_SIZE = 1000;
var
  i: Integer;
begin
  // 准备逆序数据
  for i := TEST_SIZE - 1 downto 0 do
    FDeque.PushBack(i);

  // 排序
  FDeque.Sort(@CompareTestFunc, nil);

  // 验证排序结果
  AssertEquals('排序后第一个元素应为0', 0, FDeque.Front);
  AssertEquals('排序后最后一个元素应为999', TEST_SIZE - 1, FDeque.Back);
end;

initialization
  RegisterTest(TTestCase_TDeque);

end.
