program test_deque_debug;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.lockfree.deque;

procedure TestDequeBasic;
var
  LDeque: TIntegerDeque;
  LValue: Integer;
begin
  WriteLn('测试基础双端队列操作...');
  
  try
    WriteLn('1. 创建双端队列...');
    LDeque := TIntegerDeque.Create(4); // 小容量便于调试
    
    try
      WriteLn('   容量: ', LDeque.Capacity);
      WriteLn('   是否为空: ', LDeque.IsEmpty);
      
      WriteLn('2. 推入第一个元素...');
      LDeque.push_bottom(1);
      WriteLn('   推入 1 成功');
      WriteLn('   大小: ', LDeque.size);
      
      WriteLn('3. 推入第二个元素...');
      LDeque.push_bottom(2);
      WriteLn('   推入 2 成功');
      WriteLn('   大小: ', LDeque.size);
      
      WriteLn('4. 弹出测试...');
      if LDeque.pop_bottom(LValue) then
        WriteLn('   弹出: ', LValue)
      else
        WriteLn('   弹出失败');
        
      WriteLn('   剩余大小: ', LDeque.size);
      
      WriteLn('✅ 基础测试完成');
      
    finally
      LDeque.Free;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试失败: ', E.Message);
      WriteLn('   异常类: ', E.ClassName);
      raise;
    end;
  end;
end;

begin
  WriteLn('双端队列 Debug 测试');
  WriteLn('==================');
  WriteLn;
  
  try
    TestDequeBasic;
    WriteLn;
    WriteLn('🎉 所有测试通过！');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试失败: ', E.Message);
      WriteLn('   异常类: ', E.ClassName);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
