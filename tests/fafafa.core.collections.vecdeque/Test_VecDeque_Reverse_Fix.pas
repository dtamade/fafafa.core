unit Test_VecDeque_Reverse_Fix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.collections.base,
  fafafa.core.collections.arr,
  fafafa.core.collections.vec,
  fafafa.core.collections.deque,
  fafafa.core.collections.queue,
  fafafa.core.collections.vecdeque,
  fafafa.core.mem.allocator;

type
  TTestCase_VecDeque_ReverseFix = class(TTestCase)
  published
    procedure Test_Reverse_CircularBuffer_Scenario1;
    procedure Test_Reverse_CircularBuffer_Scenario2;
    procedure Test_Reverse_Partial_CircularBuffer;
  end;

implementation

{ 测试场景1：元素分布在环的两端 }
procedure TTestCase_VecDeque_ReverseFix.Test_Reverse_CircularBuffer_Scenario1;
var
  LDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  LDeque := specialize TVecDeque<Integer>.Create;
  try
    { 初始：添加6个元素到容量16的缓冲区 }
    for i := 1 to 6 do
      LDeque.PushBack(i);

    { PopFront 两次，使 FHead 移动到索引2 }
    LDeque.PopFront;  // 移除1
    LDeque.PopFront;  // 移除2

    { 现在元素是 [3,4,5,6]，FHead=2 }
    AssertEquals('Count should be 4', 4, LDeque.GetCount);
    AssertEquals('Element 0 should be 3', 3, LDeque.Get(0));
    AssertEquals('Element 1 should be 4', 4, LDeque.Get(1));
    AssertEquals('Element 2 should be 5', 5, LDeque.Get(2));
    AssertEquals('Element 3 should be 6', 6, LDeque.Get(3));

    { PushBack 两次，使元素分布在环的两端 }
    LDeque.PushBack(7);  // 添加到FTail=6
    LDeque.PushBack(8);  // 添加到FTail=7

    { 现在元素是 [3,4,5,6,7,8]，分布在物理索引2..7上 }
    AssertEquals('Count should be 6', 6, LDeque.GetCount);
    for i := 0 to 5 do
      AssertEquals(Format('Element %d should be %d', [i, i+3]), i+3, LDeque.Get(i));

    { 执行完整 Reverse }
    LDeque.Reverse;

    { 验证：应该是 [8,7,6,5,4,3] }
    AssertEquals('Count should remain 6', 6, LDeque.GetCount);
    AssertEquals('Element 0 should be 8', 8, LDeque.Get(0));
    AssertEquals('Element 1 should be 7', 7, LDeque.Get(1));
    AssertEquals('Element 2 should be 6', 6, LDeque.Get(2));
    AssertEquals('Element 3 should be 5', 5, LDeque.Get(3));
    AssertEquals('Element 4 should be 4', 4, LDeque.Get(4));
    AssertEquals('Element 5 should be 3', 3, LDeque.Get(5));
  finally
    LDeque.Free;
  end;
end;

{ 测试场景2：更复杂的跨环 }
procedure TTestCase_VecDeque_ReverseFix.Test_Reverse_CircularBuffer_Scenario2;
var
  LDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  LDeque := specialize TVecDeque<Integer>.Create;
  try
    { 初始：添加8个元素 }
    for i := 1 to 8 do
      LDeque.PushBack(i);

    { PopFront 4次，FHead移动到中间 }
    for i := 1 to 4 do
      LDeque.PopFront;

    { 现在元素是 [5,6,7,8]，FHead=4 }
    AssertEquals('Count should be 4', 4, LDeque.GetCount);

    { PushBack 8次，填满缓冲区并触发扩容 }
    for i := 9 to 16 do
      LDeque.PushBack(i);

    { 现在所有12个元素分布在整个环中 }
    AssertEquals('Count should be 12', 12, LDeque.GetCount);

    { Reverse 整个队列 }
    LDeque.Reverse;

    { 验证：应该是 [16,15,14,13,12,11,10,9,8,7,6,5] }
    AssertEquals('Count should remain 12', 12, LDeque.GetCount);
    AssertEquals('Element 0 should be 16', 16, LDeque.Get(0));
    AssertEquals('Element 11 should be 5', 5, LDeque.Get(11));
  finally
    LDeque.Free;
  end;
end;

{ 测试场景3：部分 Reverse 在跨环情况下 }
procedure TTestCase_VecDeque_ReverseFix.Test_Reverse_Partial_CircularBuffer;
var
  LDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  LDeque := specialize TVecDeque<Integer>.Create;
  try
    { 初始：添加10个元素 }
    for i := 1 to 10 do
      LDeque.PushBack(i);

    { PopFront 5次，创建跨环情况 }
    for i := 1 to 5 do
      LDeque.PopFront;

    { 现在元素是 [6,7,8,9,10]，FHead=5 }
    AssertEquals('Count should be 5', 5, LDeque.GetCount);

    { 从索引2开始 Reverse 3个元素 }
    { 当前：[6,7,8,9,10] -> Reverse(2,3) -> [6,7,10,9,8] }
    LDeque.Reverse(2, 3);

    { 验证 }
    AssertEquals('Count should remain 5', 5, LDeque.GetCount);
    AssertEquals('Element 0 should be 6', 6, LDeque.Get(0));
    AssertEquals('Element 1 should be 7', 7, LDeque.Get(1));
    AssertEquals('Element 2 should be 10', 10, LDeque.Get(2));
    AssertEquals('Element 3 should be 9', 9, LDeque.Get(3));
    AssertEquals('Element 4 should be 8', 8, LDeque.Get(4));
  finally
    LDeque.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_VecDeque_ReverseFix);
end.
