program test_vecdeque_basic;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

var
  FVecDeque: specialize TVecDeque<Integer>;
begin
  WriteLn('=== TVecDeque 基本功能测试 ===');
  
  // 基本操作测试
  FVecDeque.PushBack(1);
  FVecDeque.PushBack(2);
  FVecDeque.PushBack(3);
  
  WriteLn('Count: ', FVecDeque.GetCount);
  WriteLn('Front: ', FVecDeque.GetFront);
  WriteLn('Back: ', FVecDeque.GetBack);
  
  FVecDeque.PopFront;
  WriteLn('After PopFront - Count: ', FVecDeque.GetCount);
  WriteLn('Front: ', FVecDeque.GetFront);
  
  FVecDeque.PopBack;
  WriteLn('After PopBack - Count: ', FVecDeque.GetCount);
  WriteLn('Back: ', FVecDeque.GetBack);
  
  FVecDeque.Clear;
  WriteLn('After Clear - Count: ', FVecDeque.GetCount);
  WriteLn('IsEmpty: ', FVecDeque.IsEmpty);
  
  WriteLn('✅ 基本功能测试通过！');
end.
