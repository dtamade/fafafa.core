unit Test_Collections_Drain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.vec,
  fafafa.core.collections.vecdeque;

type

  { TTestVecDrain }
  TTestVecDrain = class(TTestCase)
  published
    // === 基础 Drain 测试 ===
    procedure Test_Drain_Empty_Vec;
    procedure Test_Drain_Full_Range;
    procedure Test_Drain_Partial_Start;
    procedure Test_Drain_Partial_Middle;
    procedure Test_Drain_Partial_End;
    procedure Test_Drain_Single_Element;
    
    // === Drain 后容器状态测试 ===
    procedure Test_Drain_Vec_RemainingElements;
    procedure Test_Drain_Vec_Count_After;
    
    // === 迭代测试 ===
    procedure Test_Drain_Iterate_All;
    procedure Test_Drain_Iterate_Partial;
    
    // === 边界测试 ===
    procedure Test_Drain_ZeroLength_Range;
  end;

  { TTestVecDequeDrain }
  TTestVecDequeDrain = class(TTestCase)
  published
    // === 基础 Drain 测试 ===
    procedure Test_Drain_Empty_Deque;
    procedure Test_Drain_Full_Range;
    procedure Test_Drain_Partial;
    
    // === Drain 后容器状态测试 ===
    procedure Test_Drain_Deque_RemainingElements;
  end;

implementation

{ TTestVecDrain }

procedure TTestVecDrain.Test_Drain_Empty_Vec;
var
  Vec: specialize TVec<Integer>;
  Drain: specialize TVec<Integer>.TDrainIter;
begin
  Vec := specialize TVec<Integer>.Create;
  try
    Drain := Vec.DrainRange(0, 0);
    
    AssertFalse('Empty drain has no elements', Drain.MoveNext);
    AssertEquals('Vec still empty', 0, Vec.Count);
  finally
    Vec.Free;
  end;
end;

procedure TTestVecDrain.Test_Drain_Full_Range;
var
  Vec: specialize TVec<Integer>;
  Drain: specialize TVec<Integer>.TDrainIter;
begin
  Vec := specialize TVec<Integer>.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    
    Drain := Vec.DrainRange(0, 3);
    
    // 迭代取出所有元素
    AssertTrue('First element', Drain.MoveNext);
    AssertEquals('First value', 1, Drain.Current);
    
    AssertTrue('Second element', Drain.MoveNext);
    AssertEquals('Second value', 2, Drain.Current);
    
    AssertTrue('Third element', Drain.MoveNext);
    AssertEquals('Third value', 3, Drain.Current);
    
    AssertFalse('No more elements', Drain.MoveNext);
    
    // Vec 应该为空
    AssertEquals('Vec empty after full drain', 0, Vec.Count);
  finally
    Vec.Free;
  end;
end;

procedure TTestVecDrain.Test_Drain_Partial_Start;
var
  Vec: specialize TVec<Integer>;
  Drain: specialize TVec<Integer>.TDrainIter;
begin
  Vec := specialize TVec<Integer>.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    Vec.Push(4);
    Vec.Push(5);
    
    // Drain 前两个元素 [0, 2)
    Drain := Vec.DrainRange(0, 2);
    
    AssertTrue('First', Drain.MoveNext);
    AssertEquals('First value', 1, Drain.Current);
    
    AssertTrue('Second', Drain.MoveNext);
    AssertEquals('Second value', 2, Drain.Current);
    
    AssertFalse('No more', Drain.MoveNext);
    
    // 剩余元素应为 [3, 4, 5]
    AssertEquals('Remaining count', 3, Vec.Count);
    AssertEquals('Remaining 0', 3, Vec.Get(0));
    AssertEquals('Remaining 1', 4, Vec.Get(1));
    AssertEquals('Remaining 2', 5, Vec.Get(2));
  finally
    Vec.Free;
  end;
end;

procedure TTestVecDrain.Test_Drain_Partial_Middle;
var
  Vec: specialize TVec<Integer>;
  Drain: specialize TVec<Integer>.TDrainIter;
begin
  Vec := specialize TVec<Integer>.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    Vec.Push(4);
    Vec.Push(5);
    
    // Drain 中间元素 [1, 4) -> 2, 3, 4
    Drain := Vec.DrainRange(1, 4);
    
    AssertTrue('First', Drain.MoveNext);
    AssertEquals('First value', 2, Drain.Current);
    
    AssertTrue('Second', Drain.MoveNext);
    AssertEquals('Second value', 3, Drain.Current);
    
    AssertTrue('Third', Drain.MoveNext);
    AssertEquals('Third value', 4, Drain.Current);
    
    AssertFalse('No more', Drain.MoveNext);
    
    // 剩余元素应为 [1, 5]
    AssertEquals('Remaining count', 2, Vec.Count);
    AssertEquals('Remaining 0', 1, Vec.Get(0));
    AssertEquals('Remaining 1', 5, Vec.Get(1));
  finally
    Vec.Free;
  end;
end;

procedure TTestVecDrain.Test_Drain_Partial_End;
var
  Vec: specialize TVec<Integer>;
  Drain: specialize TVec<Integer>.TDrainIter;
begin
  Vec := specialize TVec<Integer>.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    Vec.Push(4);
    Vec.Push(5);
    
    // Drain 最后两个元素 [3, 5) -> 4, 5
    Drain := Vec.DrainRange(3, 5);
    
    AssertTrue('First', Drain.MoveNext);
    AssertEquals('First value', 4, Drain.Current);
    
    AssertTrue('Second', Drain.MoveNext);
    AssertEquals('Second value', 5, Drain.Current);
    
    AssertFalse('No more', Drain.MoveNext);
    
    // 剩余元素应为 [1, 2, 3]
    AssertEquals('Remaining count', 3, Vec.Count);
    AssertEquals('Remaining 0', 1, Vec.Get(0));
    AssertEquals('Remaining 1', 2, Vec.Get(1));
    AssertEquals('Remaining 2', 3, Vec.Get(2));
  finally
    Vec.Free;
  end;
end;

procedure TTestVecDrain.Test_Drain_Single_Element;
var
  Vec: specialize TVec<Integer>;
  Drain: specialize TVec<Integer>.TDrainIter;
begin
  Vec := specialize TVec<Integer>.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    
    // Drain 单个元素 [1, 2) -> 2
    Drain := Vec.DrainRange(1, 2);
    
    AssertTrue('Has element', Drain.MoveNext);
    AssertEquals('Value', 2, Drain.Current);
    AssertFalse('No more', Drain.MoveNext);
    
    // 剩余元素应为 [1, 3]
    AssertEquals('Remaining count', 2, Vec.Count);
    AssertEquals('Remaining 0', 1, Vec.Get(0));
    AssertEquals('Remaining 1', 3, Vec.Get(1));
  finally
    Vec.Free;
  end;
end;

procedure TTestVecDrain.Test_Drain_Vec_RemainingElements;
var
  Vec: specialize TVec<Integer>;
  Drain: specialize TVec<Integer>.TDrainIter;
begin
  Vec := specialize TVec<Integer>.Create;
  try
    Vec.Push(10);
    Vec.Push(20);
    Vec.Push(30);
    Vec.Push(40);
    
    Drain := Vec.DrainRange(1, 3);  // Remove 20, 30
    
    // 消费迭代器
    while Drain.MoveNext do ;
    
    AssertEquals('Remaining count', 2, Vec.Count);
    AssertEquals('Remaining 0', 10, Vec.Get(0));
    AssertEquals('Remaining 1', 40, Vec.Get(1));
  finally
    Vec.Free;
  end;
end;

procedure TTestVecDrain.Test_Drain_Vec_Count_After;
var
  Vec: specialize TVec<Integer>;
  Drain: specialize TVec<Integer>.TDrainIter;
begin
  Vec := specialize TVec<Integer>.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    Vec.Push(4);
    Vec.Push(5);
    
    // 原始 5 个元素，drain 3 个
    Drain := Vec.DrainRange(1, 4);
    while Drain.MoveNext do ;
    
    AssertEquals('Count after drain', 2, Vec.Count);
  finally
    Vec.Free;
  end;
end;

procedure TTestVecDrain.Test_Drain_Iterate_All;
var
  Vec: specialize TVec<Integer>;
  Drain: specialize TVec<Integer>.TDrainIter;
  Sum: Integer;
begin
  Vec := specialize TVec<Integer>.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    
    Drain := Vec.DrainRange(0, 3);
    Sum := 0;
    
    while Drain.MoveNext do
      Sum := Sum + Drain.Current;
    
    AssertEquals('Sum of drained elements', 6, Sum);
    AssertEquals('Vec empty', 0, Vec.Count);
  finally
    Vec.Free;
  end;
end;

procedure TTestVecDrain.Test_Drain_Iterate_Partial;
var
  Vec: specialize TVec<Integer>;
  Drain: specialize TVec<Integer>.TDrainIter;
  Sum: Integer;
begin
  Vec := specialize TVec<Integer>.Create;
  try
    Vec.Push(10);
    Vec.Push(20);
    Vec.Push(30);
    Vec.Push(40);
    
    Drain := Vec.DrainRange(1, 3);  // Drain 20, 30
    Sum := 0;
    
    while Drain.MoveNext do
      Sum := Sum + Drain.Current;
    
    AssertEquals('Sum of drained elements', 50, Sum);
  finally
    Vec.Free;
  end;
end;

procedure TTestVecDrain.Test_Drain_ZeroLength_Range;
var
  Vec: specialize TVec<Integer>;
  Drain: specialize TVec<Integer>.TDrainIter;
begin
  Vec := specialize TVec<Integer>.Create;
  try
    Vec.Push(1);
    Vec.Push(2);
    Vec.Push(3);
    
    // 空范围 [1, 1) -> 没有元素
    Drain := Vec.DrainRange(1, 1);
    
    AssertFalse('Empty range has no elements', Drain.MoveNext);
    AssertEquals('Vec unchanged', 3, Vec.Count);
  finally
    Vec.Free;
  end;
end;

{ TTestVecDequeDrain }

procedure TTestVecDequeDrain.Test_Drain_Empty_Deque;
var
  Deque: specialize TVecDeque<Integer>;
  Drain: specialize TVecDeque<Integer>.TDrainIter;
begin
  Deque := specialize TVecDeque<Integer>.Create;
  try
    Drain := Deque.DrainRange(0, 0);
    
    AssertFalse('Empty drain has no elements', Drain.MoveNext);
    AssertEquals('Deque still empty', 0, Deque.Count);
  finally
    Deque.Free;
  end;
end;

procedure TTestVecDequeDrain.Test_Drain_Full_Range;
var
  Deque: specialize TVecDeque<Integer>;
  Drain: specialize TVecDeque<Integer>.TDrainIter;
begin
  Deque := specialize TVecDeque<Integer>.Create;
  try
    Deque.PushBack(1);
    Deque.PushBack(2);
    Deque.PushBack(3);
    
    Drain := Deque.DrainRange(0, 3);
    
    AssertTrue('First', Drain.MoveNext);
    AssertEquals('First value', 1, Drain.Current);
    
    AssertTrue('Second', Drain.MoveNext);
    AssertEquals('Second value', 2, Drain.Current);
    
    AssertTrue('Third', Drain.MoveNext);
    AssertEquals('Third value', 3, Drain.Current);
    
    AssertFalse('No more', Drain.MoveNext);
    AssertEquals('Deque empty', 0, Deque.Count);
  finally
    Deque.Free;
  end;
end;

procedure TTestVecDequeDrain.Test_Drain_Partial;
var
  Deque: specialize TVecDeque<Integer>;
  Drain: specialize TVecDeque<Integer>.TDrainIter;
begin
  Deque := specialize TVecDeque<Integer>.Create;
  try
    Deque.PushBack(1);
    Deque.PushBack(2);
    Deque.PushBack(3);
    Deque.PushBack(4);
    
    // Drain middle [1, 3) -> 2, 3
    Drain := Deque.DrainRange(1, 3);
    
    while Drain.MoveNext do ;
    
    AssertEquals('Remaining count', 2, Deque.Count);
  finally
    Deque.Free;
  end;
end;

procedure TTestVecDequeDrain.Test_Drain_Deque_RemainingElements;
var
  Deque: specialize TVecDeque<Integer>;
  Drain: specialize TVecDeque<Integer>.TDrainIter;
begin
  Deque := specialize TVecDeque<Integer>.Create;
  try
    Deque.PushBack(10);
    Deque.PushBack(20);
    Deque.PushBack(30);
    Deque.PushBack(40);
    
    Drain := Deque.DrainRange(1, 3);  // Remove 20, 30
    while Drain.MoveNext do ;
    
    AssertEquals('Remaining count', 2, Deque.Count);
    AssertEquals('Remaining 0', 10, Deque.Get(0));
    AssertEquals('Remaining 1', 40, Deque.Get(1));
  finally
    Deque.Free;
  end;
end;

initialization
  RegisterTest(TTestVecDrain);
  RegisterTest(TTestVecDequeDrain);

end.
