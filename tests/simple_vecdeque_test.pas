program simple_vecdeque_test;

{$mode objfpc}{$H+}
{$I ../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.mem.allocator,
  fafafa.core.collections.base,
  fafafa.core.collections.queue,
  fafafa.core.collections.deque,
  fafafa.core.collections.arr,
  fafafa.core.collections.vec,
  fafafa.core.collections.vecdeque;

type
  TIntegerVecDeque = specialize TVecDeque<Integer>;

procedure TestBasicOperations;
var
  LVecDeque: TIntegerVecDeque;
begin
  WriteLn('=== 测试基本操作 ===');
  
  { 测试构造函数 }
  LVecDeque := TIntegerVecDeque.Create;
  try
    WriteLn('✓ 默认构造函数测试通过');
    
    { 测试空队列 }
    if LVecDeque.IsEmpty then
      WriteLn('✓ 空队列检测通过')
    else
      WriteLn('✗ 空队列检测失败');
    
    if LVecDeque.GetCount = 0 then
      WriteLn('✓ 空队列计数通过')
    else
      WriteLn('✗ 空队列计数失败');
    
    { 测试 PushBack }
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);
    
    if LVecDeque.GetCount = 3 then
      WriteLn('✓ PushBack 计数测试通过')
    else
      WriteLn('✗ PushBack 计数测试失败');
    
    { 测试 PushFront }
    LVecDeque.PushFront(5);
    
    if LVecDeque.GetCount = 4 then
      WriteLn('✓ PushFront 计数测试通过')
    else
      WriteLn('✗ PushFront 计数测试失败');
    
    { 测试 Front 和 Back }
    if LVecDeque.Front = 5 then
      WriteLn('✓ Front 测试通过')
    else
      WriteLn('✗ Front 测试失败');
    
    if LVecDeque.Back = 30 then
      WriteLn('✓ Back 测试通过')
    else
      WriteLn('✗ Back 测试失败');
    
    { 测试 PopFront }
    if LVecDeque.PopFront = 5 then
      WriteLn('✓ PopFront 测试通过')
    else
      WriteLn('✗ PopFront 测试失败');
    
    { 测试 PopBack }
    if LVecDeque.PopBack = 30 then
      WriteLn('✓ PopBack 测试通过')
    else
      WriteLn('✗ PopBack 测试失败');
    
    if LVecDeque.GetCount = 2 then
      WriteLn('✓ Pop 后计数测试通过')
    else
      WriteLn('✗ Pop 后计数测试失败');
    
    { 测试 Clear }
    LVecDeque.Clear;
    
    if LVecDeque.IsEmpty then
      WriteLn('✓ Clear 测试通过')
    else
      WriteLn('✗ Clear 测试失败');
    
  finally
    LVecDeque.Free;
  end;
end;

procedure TestCapacityOperations;
var
  LVecDeque: TIntegerVecDeque;
  LInitialCapacity, LNewCapacity: SizeUInt;
  i: Integer;
begin
  WriteLn('=== 测试容量操作 ===');
  
  LVecDeque := TIntegerVecDeque.Create;
  try
    { 测试初始容量 }
    LInitialCapacity := LVecDeque.GetCapacity;
    WriteLn('初始容量: ', LInitialCapacity);
    
    { 测试 Reserve }
    LVecDeque.Reserve(100);
    LNewCapacity := LVecDeque.GetCapacity;
    
    if LNewCapacity >= LInitialCapacity + 100 then
      WriteLn('✓ Reserve 测试通过')
    else
      WriteLn('✗ Reserve 测试失败');
    
    { 测试自动增长 }
    for i := 1 to 50 do
      LVecDeque.PushBack(i);
    
    if LVecDeque.GetCount = 50 then
      WriteLn('✓ 自动增长测试通过')
    else
      WriteLn('✗ 自动增长测试失败');
    
    { 测试 ShrinkToFit }
    LVecDeque.ShrinkToFit;
    LNewCapacity := LVecDeque.GetCapacity;
    
    if LNewCapacity >= LVecDeque.GetCount then
      WriteLn('✓ ShrinkToFit 测试通过')
    else
      WriteLn('✗ ShrinkToFit 测试失败');
    
  finally
    LVecDeque.Free;
  end;
end;

procedure TestArrayOperations;
var
  LVecDeque: TIntegerVecDeque;
  LArray: array[0..2] of Integer;
  i: Integer;
begin
  WriteLn('=== 测试数组操作 ===');
  
  LVecDeque := TIntegerVecDeque.Create;
  try
    { 准备测试数组 }
    LArray[0] := 100;
    LArray[1] := 200;
    LArray[2] := 300;
    
    { 测试 PushBack 数组 }
    LVecDeque.PushBack(LArray);
    
    if LVecDeque.GetCount = 3 then
      WriteLn('✓ PushBack 数组计数测试通过')
    else
      WriteLn('✗ PushBack 数组计数测试失败');
    
    { 验证元素 }
    if (LVecDeque.Get(0) = 100) and (LVecDeque.Get(1) = 200) and (LVecDeque.Get(2) = 300) then
      WriteLn('✓ PushBack 数组元素测试通过')
    else
      WriteLn('✗ PushBack 数组元素测试失败');
    
    { 测试 PushFront 数组 }
    LArray[0] := 50;
    LArray[1] := 60;
    LArray[2] := 70;
    
    LVecDeque.PushFront(LArray);
    
    if LVecDeque.GetCount = 6 then
      WriteLn('✓ PushFront 数组计数测试通过')
    else
      WriteLn('✗ PushFront 数组计数测试失败');
    
    { 验证前端元素 }
    if (LVecDeque.Get(0) = 50) and (LVecDeque.Get(1) = 60) and (LVecDeque.Get(2) = 70) then
      WriteLn('✓ PushFront 数组元素测试通过')
    else
      WriteLn('✗ PushFront 数组元素测试失败');
    
  finally
    LVecDeque.Free;
  end;
end;

procedure TestSafeOperations;
var
  LVecDeque: TIntegerVecDeque;
  LElement: Integer;
  LResult: Boolean;
begin
  WriteLn('=== 测试安全操作 ===');
  
  LVecDeque := TIntegerVecDeque.Create;
  try
    { 测试空队列的安全操作 }
    LElement := 999;
    LResult := LVecDeque.PopFront(LElement);
    
    if (not LResult) and (LElement = 999) then
      WriteLn('✓ 空队列 PopFront 安全测试通过')
    else
      WriteLn('✗ 空队列 PopFront 安全测试失败');
    
    LResult := LVecDeque.PopBack(LElement);
    
    if (not LResult) and (LElement = 999) then
      WriteLn('✓ 空队列 PopBack 安全测试通过')
    else
      WriteLn('✗ 空队列 PopBack 安全测试失败');
    
    { 添加元素后测试安全操作 }
    LVecDeque.PushBack(42);
    LVecDeque.PushBack(84);
    
    LResult := LVecDeque.PopFront(LElement);
    
    if LResult and (LElement = 42) then
      WriteLn('✓ 非空队列 PopFront 安全测试通过')
    else
      WriteLn('✗ 非空队列 PopFront 安全测试失败');
    
    LResult := LVecDeque.PopBack(LElement);
    
    if LResult and (LElement = 84) then
      WriteLn('✓ 非空队列 PopBack 安全测试通过')
    else
      WriteLn('✗ 非空队列 PopBack 安全测试失败');
    
  finally
    LVecDeque.Free;
  end;
end;

begin
  WriteLn('开始 VecDeque 简单测试...');
  WriteLn;
  
  try
    TestBasicOperations;
    WriteLn;
    
    TestCapacityOperations;
    WriteLn;
    
    TestArrayOperations;
    WriteLn;
    
    TestSafeOperations;
    WriteLn;
    
    WriteLn('所有测试完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('测试过程中发生异常: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('测试完成，程序退出。');
end.
