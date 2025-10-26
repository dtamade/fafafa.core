program simple_reverse_test;

{$mode objfpc}{$H+}

{$I src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

var
  LDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  LDeque := specialize TVecDeque<Integer>.Create;
  try
    WriteLn('=== VecDeque Reverse 快速验证 ===');
    WriteLn;

    // 基本测试
    for i := 1 to 5 do
      LDeque.PushBack(i);
    
    Write('Before: ');
    for i := 0 to LDeque.Count - 1 do
      Write(LDeque.Get(i), ' ');
    WriteLn;
    
    LDeque.Reverse;
    
    Write('After:  ');
    for i := 0 to LDeque.Count - 1 do
      Write(LDeque.Get(i), ' ');
    WriteLn;
    
    WriteLn('Expected: 5 4 3 2 1');
    WriteLn;
    
    if (LDeque.Get(0) = 5) and (LDeque.Get(4) = 1) then
      WriteLn('✅ Reverse 测试通过！')
    else
      WriteLn('❌ Reverse 测试失败！');
    
  finally
    LDeque.Free;
  end;
end.
