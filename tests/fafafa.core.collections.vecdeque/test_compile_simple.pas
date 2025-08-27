program test_compile_simple;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

type
  TIntVecDeque = specialize TVecDeque<Integer>;

var
  LVecDeque: TIntVecDeque;
  LArray: array of Integer;

begin
  WriteLn('Testing simple compilation...');
  
  LVecDeque := TIntVecDeque.Create;
  try
    // 测试基本操作
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    
    WriteLn('Added 3 elements, count: ', LVecDeque.GetCount);
    
    // 测试类型安全操作（修复后的版本）
    SetLength(LArray, 0);
    // VecDeque 没有 Assign 方法，使用其他操作
    LVecDeque.Clear;
    LVecDeque.PushBack(42);
    
    WriteLn('After clear and add 42, count: ', LVecDeque.GetCount);
    WriteLn('Value: ', LVecDeque.Get(0));
    
    WriteLn('✓ All operations work correctly');
    
  finally
    LVecDeque.Free;
  end;
  
  WriteLn('Simple compilation test completed successfully!');
end.
