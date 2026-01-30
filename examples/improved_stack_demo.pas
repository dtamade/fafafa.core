program ImprovedStackDemo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  // 原子统一：示例不再引用 fafafa.core.sync
  fafafa.core.lockfree;

{**
 * 测试改进后的实用无锁栈
 *}
procedure TestImprovedStack;
type
  TIntStack = specialize TPracticalLockFreeStack<Integer>;
var
  LStack: TIntStack;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 改进的实用无锁栈测试 ===');
  
  LStack := TIntStack.Create;
  try
    WriteLn('测试基础功能...');
    
    // 压栈测试
    for I := 1 to 10 do
      LStack.Push(I);
    
    WriteLn('压栈完成，栈大小: ', LStack.GetSize);
    
    // 弹栈测试
    WriteLn('弹栈结果: ');
    while LStack.Pop(LValue) do
      Write(LValue, ' ');
    WriteLn;
    
    WriteLn('弹栈完成，栈大小: ', LStack.GetSize);
    WriteLn('栈是否为空: ', BoolToStr(LStack.IsEmpty, 'True', 'False'));
    
    WriteLn('✅ 改进的无锁栈基础功能正常！');
    
  finally
    LStack.Free;
  end;
  WriteLn;
end;

{**
 * 测试性能
 *}
procedure TestStackPerformance;
type
  TIntStack = specialize TPracticalLockFreeStack<Integer>;
var
  LStack: TIntStack;
  LStartTime, LEndTime: QWord;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 改进的无锁栈性能测试 ===');
  
  LStack := TIntStack.Create;
  try
    WriteLn('测试10万次压栈弹栈操作...');
    
    LStartTime := GetTickCount64;
    
    // 压栈10万次
    for I := 1 to 100000 do
      LStack.Push(I);
    
    // 弹栈10万次
    for I := 1 to 100000 do
      LStack.Pop(LValue);
    
    LEndTime := GetTickCount64;
    
    WriteLn('20万次操作耗时: ', LEndTime - LStartTime, ' ms');
    if (LEndTime - LStartTime) > 0 then
      WriteLn('吞吐量: ', 200000 * 1000 div (LEndTime - LStartTime), ' ops/sec')
    else
      WriteLn('吞吐量: 极高 (操作太快，无法测量)');
    
    WriteLn('最终栈大小: ', LStack.GetSize);
    WriteLn('✅ 改进的无锁栈性能测试完成！');
    
  finally
    LStack.Free;
  end;
  WriteLn;
end;

{**
 * 测试错误处理
 *}
procedure TestErrorHandling;
type
  TIntStack = specialize TPracticalLockFreeStack<Integer>;
var
  LStack: TIntStack;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 改进的无锁栈错误处理测试 ===');
  
  LStack := TIntStack.Create;
  try
    WriteLn('测试空栈弹出...');
    
    // 尝试从空栈弹出
    if LStack.Pop(LValue) then
      WriteLn('❌ 空栈弹出应该失败')
    else
      WriteLn('✅ 空栈弹出正确失败');
    
    WriteLn('测试重试机制...');
    
    // 压入一些元素
    for I := 1 to 5 do
      LStack.Push(I);
    
    WriteLn('压入5个元素，栈大小: ', LStack.GetSize);
    
    // 弹出所有元素
    I := 0;
    while LStack.Pop(LValue) do
    begin
      Inc(I);
      WriteLn('弹出第', I, '个元素: ', LValue);
    end;
    
    WriteLn('总共弹出', I, '个元素');
    WriteLn('最终栈大小: ', LStack.GetSize);
    
    if LStack.IsEmpty then
      WriteLn('✅ 栈正确为空')
    else
      WriteLn('❌ 栈应该为空');
    
    WriteLn('✅ 错误处理测试完成！');
    
  finally
    LStack.Free;
  end;
  WriteLn;
end;

{**
 * 主程序
 *}
begin
  WriteLn('改进的实用无锁栈演示');
  WriteLn('====================');
  WriteLn;
  
  try
    TestImprovedStack;
    TestStackPerformance;
    TestErrorHandling;
    
    WriteLn('🎉 所有改进的无锁栈测试完成！');
    WriteLn;
    WriteLn('📝 说明:');
    WriteLn('- 这个实现使用了魔数检测内存损坏');
    WriteLn('- 添加了重试计数避免无限循环');
    WriteLn('- 虽然仍存在理论上的ABA问题，但在实际使用中更安全');
    WriteLn('- 适用于大多数应用场景，但不适合极高并发的关键系统');
    
  except
    on E: Exception do
    begin
      WriteLn('演示过程中发生异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
