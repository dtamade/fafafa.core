program test_countof_simple;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

var
  LVecDeque: specialize TVecDeque<Integer>;
  LCount: SizeUInt;
begin
  WriteLn('=== 测试 VecDeque CountOf 方法 ===');
  
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    // 添加测试数据
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(1);
    
    WriteLn('VecDeque 内容: [1, 2, 1, 3, 1]');
    
    // 测试 CountOf 方法
    LCount := LVecDeque.CountOf(1);
    WriteLn('CountOf(1) = ', LCount, ' (期望: 3)');
    
    LCount := LVecDeque.CountOf(2);
    WriteLn('CountOf(2) = ', LCount, ' (期望: 1)');
    
    LCount := LVecDeque.CountOf(3);
    WriteLn('CountOf(3) = ', LCount, ' (期望: 1)');
    
    LCount := LVecDeque.CountOf(99);
    WriteLn('CountOf(99) = ', LCount, ' (期望: 0)');
    
    WriteLn('✅ CountOf 方法测试完成');
    
  finally
    LVecDeque.Free;
  end;
end.
