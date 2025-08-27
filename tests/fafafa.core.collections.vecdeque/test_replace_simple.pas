program test_replace_simple;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

var
  LVecDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  WriteLn('=== 测试 VecDeque Replace 方法 ===');
  
  LVecDeque := specialize TVecDeque<Integer>.Create;
  try
    // 添加测试数据: [1, 2, 1, 3, 1, 2]
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    
    WriteLn('原始数据: [1, 2, 1, 3, 1, 2]');
    
    // 替换所有的1为99
    LVecDeque.Replace(1, 99);
    
    WriteLn('替换1为99后的结果:');
    Write('[');
    for i := 0 to LVecDeque.Count - 1 do
    begin
      Write(LVecDeque.Get(i));
      if i < LVecDeque.Count - 1 then
        Write(', ');
    end;
    WriteLn(']');
    
    WriteLn('期望结果: [99, 2, 99, 3, 99, 2]');
    
    // 验证结果
    if (LVecDeque.Count = 6) and
       (LVecDeque.Get(0) = 99) and
       (LVecDeque.Get(1) = 2) and
       (LVecDeque.Get(2) = 99) and
       (LVecDeque.Get(3) = 3) and
       (LVecDeque.Get(4) = 99) and
       (LVecDeque.Get(5) = 2) then
      WriteLn('✅ Replace 方法测试通过')
    else
      WriteLn('❌ Replace 方法测试失败');
    
  finally
    LVecDeque.Free;
  end;
end.
