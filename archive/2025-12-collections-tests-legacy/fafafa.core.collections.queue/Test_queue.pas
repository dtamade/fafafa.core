unit Test_queue;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.base,
  fafafa.core.collections.base,
  fafafa.core.collections.queue,
  fafafa.core.collections.elementManager,
  fafafa.core.mem.allocator;

type

  { TTestCase_TQueue }

  TTestCase_TQueue = class(TTestCase)
  private
    FQueue: specialize TQueue<Integer>;
    FStringQueue: specialize TQueue<string>;
    
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    
  published
    // 构造函数测试
    procedure Test_TQueue_Create;
    procedure Test_TQueue_Create_Capacity;
    procedure Test_TQueue_Create_Allocator;
    
    // IQueue 接口测试
    procedure Test_TQueue_Enqueue;
    procedure Test_TQueue_Dequeue;
    procedure Test_TQueue_TryDequeue;
    procedure Test_TQueue_Front;
    procedure Test_TQueue_TryFront;
    procedure Test_TQueue_Back;
    procedure Test_TQueue_TryBack;
    
    // ICollection 接口测试
    procedure Test_TQueue_GetCount;
    procedure Test_TQueue_IsEmpty;
    procedure Test_TQueue_Clear;
    procedure Test_TQueue_ToArray;
    procedure Test_TQueue_Clone;
    
    // 容量管理测试
    procedure Test_TQueue_GetCapacity;
    procedure Test_TQueue_SetCapacity;
    procedure Test_TQueue_Reserve;
    
    // 异常测试
    procedure Test_TQueue_Dequeue_Empty;
    procedure Test_TQueue_Front_Empty;
    procedure Test_TQueue_Back_Empty;
    
    // 边界条件测试
    procedure Test_TQueue_EmptyQueue_Operations;
    procedure Test_TQueue_SingleElement_Operations;
    procedure Test_TQueue_LargeQueue_Operations;
    
    // 性能测试
    procedure Test_TQueue_Performance_EnqueueDequeue;
    procedure Test_TQueue_Performance_Access;
  end;

implementation

{ TTestCase_TQueue }

procedure TTestCase_TQueue.SetUp;
begin
  inherited SetUp;
  FQueue := specialize TQueue<Integer>.Create;
  FStringQueue := specialize TQueue<string>.Create;
end;

procedure TTestCase_TQueue.TearDown;
begin
  FQueue.Free;
  FStringQueue.Free;
  inherited TearDown;
end;

procedure TTestCase_TQueue.Test_TQueue_Create;
begin
  AssertEquals('新建队列计数应为0', 0, Int64(FQueue.GetCount));
  AssertTrue('新建队列应为空', FQueue.IsEmpty);
  AssertTrue('新建队列容量应大于0', FQueue.GetCapacity > 0);
end;

procedure TTestCase_TQueue.Test_TQueue_Create_Capacity;
var
  LQueue: specialize TQueue<Integer>;
  LCapacity: SizeUInt;
begin
  LCapacity := 100;
  LQueue := specialize TQueue<Integer>.Create(LCapacity);
  try
    AssertEquals('指定容量创建队列计数应为0', 0, Int64(LQueue.GetCount));
    AssertTrue('指定容量创建队列应为空', LQueue.IsEmpty);
    AssertTrue('队列容量应大于等于指定容量', LQueue.GetCapacity >= LCapacity);
  finally
    LQueue.Free;
  end;
end;

procedure TTestCase_TQueue.Test_TQueue_Create_Allocator;
var
  LQueue: specialize TQueue<Integer>;
  LAllocator: IMemoryAllocator;
begin
  LAllocator := GetDefaultAllocator;
  LQueue := specialize TQueue<Integer>.Create(LAllocator);
  try
    AssertEquals('使用分配器创建队列计数应为0', 0, Int64(LQueue.GetCount));
    AssertTrue('使用分配器创建队列应为空', LQueue.IsEmpty);
    AssertEquals('分配器应正确设置', LAllocator, LQueue.GetAllocator);
  finally
    LQueue.Free;
  end;
end;

procedure TTestCase_TQueue.Test_TQueue_Enqueue;
begin
  AssertEquals('初始队列计数应为0', 0, Int64(FQueue.GetCount));
  
  FQueue.Enqueue(10);
  AssertEquals('Enqueue一个元素后计数应为1', 1, Int64(FQueue.GetCount));
  AssertEquals('Enqueue的元素应在前端', 10, FQueue.Front);
  AssertEquals('Enqueue的元素也应在后端', 10, FQueue.Back);
  
  FQueue.Enqueue(20);
  AssertEquals('Enqueue第二个元素后计数应为2', 2, Int64(FQueue.GetCount));
  AssertEquals('Front应保持为10', 10, FQueue.Front);
  AssertEquals('Back应为20', 20, FQueue.Back);
end;

procedure TTestCase_TQueue.Test_TQueue_Dequeue;
var
  LValue: Integer;
begin
  // 准备测试数据
  FQueue.Enqueue(10);
  FQueue.Enqueue(20);
  FQueue.Enqueue(30);
  
  // 测试出队元素
  LValue := FQueue.Dequeue;
  AssertEquals('Dequeue应返回10', 10, LValue);
  AssertEquals('Dequeue后计数应为2', 2, Int64(FQueue.GetCount));
  AssertEquals('新的Front应为20', 20, FQueue.Front);
  AssertEquals('Back应保持不变', 30, FQueue.Back);
end;

procedure TTestCase_TQueue.Test_TQueue_TryDequeue;
var
  LValue: Integer;
  LResult: Boolean;
begin
  // 测试空队列
  LResult := FQueue.TryDequeue(LValue);
  AssertFalse('空队列TryDequeue应返回False', LResult);
  
  // 添加元素并测试
  FQueue.Enqueue(42);
  LResult := FQueue.TryDequeue(LValue);
  AssertTrue('非空队列TryDequeue应返回True', LResult);
  AssertEquals('出队的值应为42', 42, LValue);
  AssertTrue('出队后队列应为空', FQueue.IsEmpty);
end;

procedure TTestCase_TQueue.Test_TQueue_Front;
begin
  // 添加测试数据
  FQueue.Enqueue(100);
  AssertEquals('Front应返回100', 100, FQueue.Front);
  
  FQueue.Enqueue(200);
  AssertEquals('Front应保持为100', 100, FQueue.Front);
  
  // 验证Front不会修改队列
  AssertEquals('调用Front后计数应保持不变', 2, Int64(FQueue.GetCount));
end;

procedure TTestCase_TQueue.Test_TQueue_TryFront;
var
  LValue: Integer;
  LResult: Boolean;
begin
  // 测试空队列
  LResult := FQueue.TryFront(LValue);
  AssertFalse('空队列TryFront应返回False', LResult);
  
  // 添加元素并测试
  FQueue.Enqueue(123);
  LResult := FQueue.TryFront(LValue);
  AssertTrue('非空队列TryFront应返回True', LResult);
  AssertEquals('获取的值应为123', 123, LValue);
  AssertEquals('TryFront不应修改计数', 1, Int64(FQueue.GetCount));
end;

procedure TTestCase_TQueue.Test_TQueue_Back;
begin
  // 添加测试数据
  FQueue.Enqueue(100);
  AssertEquals('Back应返回100', 100, FQueue.Back);
  
  FQueue.Enqueue(200);
  AssertEquals('Back应返回200', 200, FQueue.Back);
  
  // 验证Back不会修改队列
  AssertEquals('调用Back后计数应保持不变', 2, Int64(FQueue.GetCount));
end;

procedure TTestCase_TQueue.Test_TQueue_TryBack;
var
  LValue: Integer;
  LResult: Boolean;
begin
  // 测试空队列
  LResult := FQueue.TryBack(LValue);
  AssertFalse('空队列TryBack应返回False', LResult);
  
  // 添加元素并测试
  FQueue.Enqueue(123);
  LResult := FQueue.TryBack(LValue);
  AssertTrue('非空队列TryBack应返回True', LResult);
  AssertEquals('获取的值应为123', 123, LValue);
  AssertEquals('TryBack不应修改计数', 1, Int64(FQueue.GetCount));
end;

// ICollection 接口测试
procedure TTestCase_TQueue.Test_TQueue_GetCount;
begin
  AssertEquals('空队列计数应为0', 0, Int64(FQueue.GetCount));
  
  FQueue.Enqueue(10);
  AssertEquals('添加元素后计数应为1', 1, Int64(FQueue.GetCount));
end;

procedure TTestCase_TQueue.Test_TQueue_IsEmpty;
begin
  AssertTrue('空队列IsEmpty应为True', FQueue.IsEmpty);
  
  FQueue.Enqueue(10);
  AssertFalse('非空队列IsEmpty应为False', FQueue.IsEmpty);
end;

procedure TTestCase_TQueue.Test_TQueue_Clear;
begin
  FQueue.Enqueue(10);
  FQueue.Enqueue(20);
  
  FQueue.Clear;
  
  AssertEquals('清空后计数应为0', 0, Int64(FQueue.GetCount));
  AssertTrue('清空后应为空', FQueue.IsEmpty);
end;

procedure TTestCase_TQueue.Test_TQueue_ToArray;
begin
  FQueue.Enqueue(10);
  FQueue.Enqueue(20);
  FQueue.Enqueue(30);
  
  var LArray := FQueue.ToArray;
  
  AssertEquals('ToArray长度应正确', 3, Length(LArray));
  AssertEquals('ToArray第一个元素应正确', 10, LArray[0]);
end;

procedure TTestCase_TQueue.Test_TQueue_Clone;
begin
  FQueue.Enqueue(10);
  FQueue.Enqueue(20);
  
  var LClone := FQueue.Clone;
  try
    AssertEquals('Clone后计数应相同', Int64(FQueue.GetCount), Int64(LClone.GetCount));
    AssertEquals('Clone后元素应正确', 10, LClone.Front);
  finally
    LClone.Free;
  end;
end;

// 容量管理测试
procedure TTestCase_TQueue.Test_TQueue_GetCapacity;
begin
  var LCapacity := FQueue.GetCapacity;
  AssertTrue('容量应大于0', LCapacity > 0);
end;

procedure TTestCase_TQueue.Test_TQueue_SetCapacity;
begin
  FQueue.SetCapacity(100);
  AssertTrue('设置容量后应大于等于100', FQueue.GetCapacity >= 100);
end;

procedure TTestCase_TQueue.Test_TQueue_Reserve;
begin
  var LOriginalCapacity := FQueue.GetCapacity;
  FQueue.Reserve(LOriginalCapacity * 2);
  AssertTrue('Reserve后容量应增加', FQueue.GetCapacity >= LOriginalCapacity * 2);
end;

// 异常测试
procedure TTestCase_TQueue.Test_TQueue_Dequeue_Empty;
begin
  try
    FQueue.Dequeue;
    Fail('空队列Dequeue应该抛出异常');
  except
    on E: EInvalidOperation do
      AssertTrue('应该抛出 EInvalidOperation 异常', True);
    on E: Exception do
      Fail('应该抛出 EInvalidOperation 异常，但抛出了: ' + E.ClassName);
  end;
end;

procedure TTestCase_TQueue.Test_TQueue_Front_Empty;
begin
  try
    FQueue.Front;
    Fail('空队列Front应该抛出异常');
  except
    on E: EInvalidOperation do
      AssertTrue('应该抛出 EInvalidOperation 异常', True);
    on E: Exception do
      Fail('应该抛出 EInvalidOperation 异常，但抛出了: ' + E.ClassName);
  end;
end;

procedure TTestCase_TQueue.Test_TQueue_Back_Empty;
begin
  try
    FQueue.Back;
    Fail('空队列Back应该抛出异常');
  except
    on E: EInvalidOperation do
      AssertTrue('应该抛出 EInvalidOperation 异常', True);
    on E: Exception do
      Fail('应该抛出 EInvalidOperation 异常，但抛出了: ' + E.ClassName);
  end;
end;

// 边界条件测试
procedure TTestCase_TQueue.Test_TQueue_EmptyQueue_Operations;
begin
  AssertEquals('空队列计数应为0', 0, Int64(FQueue.GetCount));
  AssertTrue('空队列应为空', FQueue.IsEmpty);
  
  FQueue.Clear;
  AssertEquals('清空空队列后计数仍为0', 0, Int64(FQueue.GetCount));
end;

procedure TTestCase_TQueue.Test_TQueue_SingleElement_Operations;
begin
  FQueue.Enqueue(42);
  
  AssertEquals('单元素队列计数应为1', 1, Int64(FQueue.GetCount));
  AssertFalse('单元素队列不应为空', FQueue.IsEmpty);
  AssertEquals('单元素队列Front应正确', 42, FQueue.Front);
  AssertEquals('单元素队列Back应正确', 42, FQueue.Back);
  
  var LValue := FQueue.Dequeue;
  AssertEquals('出队元素应正确', 42, LValue);
  AssertEquals('出队后计数应为0', 0, Int64(FQueue.GetCount));
end;

procedure TTestCase_TQueue.Test_TQueue_LargeQueue_Operations;
const
  LARGE_SIZE = 1000;
var
  i: Integer;
begin
  // 添加大量元素
  for i := 0 to LARGE_SIZE - 1 do
    FQueue.Enqueue(i);
  
  AssertEquals('大队列计数应正确', LARGE_SIZE, Int64(FQueue.GetCount));
  AssertEquals('Front应正确', 0, FQueue.Front);
  AssertEquals('Back应正确', LARGE_SIZE - 1, FQueue.Back);
  
  FQueue.Clear;
  AssertEquals('清空后计数应为0', 0, Int64(FQueue.GetCount));
end;

// 性能测试
procedure TTestCase_TQueue.Test_TQueue_Performance_EnqueueDequeue;
const
  TEST_SIZE = 10000;
var
  i: Integer;
begin
  // 入队性能测试
  for i := 0 to TEST_SIZE - 1 do
    FQueue.Enqueue(i);
  
  AssertEquals('性能测试Enqueue元素数量应正确', TEST_SIZE, Int64(FQueue.GetCount));
  
  // 出队性能测试
  for i := 0 to TEST_SIZE - 1 do
  begin
    var LValue := FQueue.Dequeue;
    AssertEquals('出队元素应正确', i, LValue);
  end;
  
  AssertEquals('性能测试Dequeue后队列应为空', 0, Int64(FQueue.GetCount));
end;

procedure TTestCase_TQueue.Test_TQueue_Performance_Access;
const
  TEST_SIZE = 1000;
var
  i: Integer;
  LSum: Int64;
begin
  // 准备数据
  for i := 0 to TEST_SIZE - 1 do
    FQueue.Enqueue(i);
  
  // 访问性能测试
  LSum := 0;
  for i := 0 to TEST_SIZE - 1 do
    LSum := LSum + FQueue.Front;
  
  AssertTrue('访问测试应完成', LSum >= 0);
end;

initialization
  RegisterTest(TTestCase_TQueue);

end.
