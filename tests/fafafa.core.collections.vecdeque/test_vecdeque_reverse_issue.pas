program test_vecdeque_reverse_issue;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.collections.vecdeque;

procedure TestReverseCircularBuffer;
var
  LDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  LDeque := specialize TVecDeque<Integer>.Create;
  try
    WriteLn('=== 测试 VecDeque 跨环场景 Reverse ===');

    // 初始化：容量16，添加6个元素
    WriteLn('Step 1: 添加元素 1..6');
    for i := 1 to 6 do
      LDeque.PushBack(i);
    WriteLn('容量: ', LDeque.GetCapacity, ', 元素数: ', LDeque.GetCount);
    Write('元素: ');
    for i := 0 to LDeque.GetCount - 1 do
      Write(LDeque.Get(i), ' ');
    WriteLn;

    // PopFront 两次，模拟跨环
    WriteLn('Step 2: PopFront 两次 (模拟跨环)');
    LDeque.PopFront;
    LDeque.PopFront;
    WriteLn('容量: ', LDeque.GetCapacity, ', 元素数: ', LDeque.GetCount);
    Write('元素: ');
    for i := 0 to LDeque.GetCount - 1 do
      Write(LDeque.Get(i), ' ');
    WriteLn;

    // PushBack 两次，使元素分布到环的两端
    WriteLn('Step 3: PushBack 两次 (元素分布在环的两端)');
    LDeque.PushBack(7);
    LDeque.PushBack(8);
    WriteLn('容量: ', LDeque.GetCapacity, ', 元素数: ', LDeque.GetCount);
    Write('元素: ');
    for i := 0 to LDeque.GetCount - 1 do
      Write(LDeque.Get(i), ' ');
    WriteLn;

    // 反转
    WriteLn('Step 4: 执行 Reverse');
    LDeque.Reverse;
    WriteLn('容量: ', LDeque.GetCapacity, ', 元素数: ', LDeque.GetCount);
    Write('反转后元素: ');
    for i := 0 to LDeque.GetCount - 1 do
      Write(LDeque.Get(i), ' ');
    WriteLn;

    WriteLn('期望: 8 7 6 5 4 3');
    Write('实际: ');
    for i := 0 to LDeque.GetCount - 1 do
      Write(LDeque.Get(i), ' ');
    WriteLn;

    WriteLn;

    // 测试部分 Reverse
    WriteLn('=== 测试部分 Reverse ===');
    LDeque.Free;
    LDeque := specialize TVecDeque<Integer>.Create;
    for i := 1 to 10 do
      LDeque.PushBack(i);
    WriteLn('初始: ');
    for i := 0 to LDeque.GetCount - 1 do
      Write(LDeque.Get(i), ' ');
    WriteLn;

    // PopFront 5 次，使索引3开始跨越环
    for i := 1 to 5 do
      LDeque.PopFront;
    WriteLn('PopFront 5 次后: ');
    for i := 0 to LDeque.GetCount - 1 do
      Write(LDeque.Get(i), ' ');
    WriteLn;

    WriteLn('从索引3开始 Reverse 4 个元素');
    LDeque.Reverse(3, 4);
    WriteLn('结果: ');
    for i := 0 to LDeque.GetCount - 1 do
      Write(LDeque.Get(i), ' ');
    WriteLn;
    WriteLn('期望: 6 7 8 9 10 3 4 5');

  finally
    LDeque.Free;
  end;
end;

begin
  TestReverseCircularBuffer;
  WriteLn('测试完成');
end.
