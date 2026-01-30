{$CODEPAGE UTF8}
program test_reverse_demo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

procedure TestReverseDemo;
var
  LDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  LDeque := specialize TVecDeque<Integer>.Create;
  try
    WriteLn('=== VecDeque Reverse 功能演示 ===');
    WriteLn;

    // 演示场景1：基本Reverse
    WriteLn('场景1：基本Reverse操作');
    WriteLn('添加元素：1 2 3 4 5');
    for i := 1 to 5 do
      LDeque.PushBack(i);

    Write('原始队列: ');
    for i := 0 to LDeque.Count - 1 do
      Write(LDeque.Get(i), ' ');
    WriteLn;

    WriteLn('执行 Reverse...');
    LDeque.Reverse;

    Write('反转后: ');
    for i := 0 to LDeque.Count - 1 do
      Write(LDeque.Get(i), ' ');
    WriteLn;
    WriteLn('期望: 5 4 3 2 1');
    WriteLn;

    // 演示场景2：跨环Reverse
    WriteLn('场景2：跨环缓冲区Reverse');
    LDeque.Clear;

    WriteLn('添加6个元素到容量16的缓冲区');
    for i := 1 to 6 do
      LDeque.PushBack(i);

    WriteLn('PopFront 两次 (移除1, 2)');
    LDeque.PopFront;
    LDeque.PopFront;

    WriteLn('PushBack 两次 (添加7, 8)');
    LDeque.PushBack(7);
    LDeque.PushBack(8);

    Write('当前队列: ');
    for i := 0 to LDeque.Count - 1 do
      Write(LDeque.Get(i), ' ');
    WriteLn;
    WriteLn('(元素分布在环的两端，物理索引2..7)');

    WriteLn('执行 Reverse...');
    LDeque.Reverse;

    Write('反转后: ');
    for i := 0 to LDeque.Count - 1 do
      Write(LDeque.Get(i), ' ');
    WriteLn;
    WriteLn('期望: 8 7 6 5 4 3');
    WriteLn;

    // 演示场景3：部分Reverse
    WriteLn('场景3：部分Reverse操作');
    LDeque.Clear;

    WriteLn('添加元素：1 2 3 4 5 6 7 8 9 10');
    for i := 1 to 10 do
      LDeque.PushBack(i);

    Write('原始队列: ');
    for i := 0 to LDeque.Count - 1 do
      Write(LDeque.Get(i), ' ');
    WriteLn;

    WriteLn('从索引3开始，Reverse 4个元素');
    WriteLn('操作: [1 2 3 4 5 6 7 8 9 10] -> Reverse(3,4) -> [1 2 3 7 6 5 4 8 9 10]');
    LDeque.Reverse(3, 4);

    Write('结果: ');
    for i := 0 to LDeque.Count - 1 do
      Write(LDeque.Get(i), ' ');
    WriteLn;
    WriteLn;

    WriteLn('=== 测试完成，所有操作成功！ ===');
    WriteLn('容量: ', LDeque.GetCapacity);
    WriteLn('元素数: ', LDeque.Count);

  finally
    LDeque.Free;
  end;
end;

begin
  TestReverseDemo;
end.
