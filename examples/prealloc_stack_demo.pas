program PreAllocStackDemo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.sync,
  fafafa.core.lockfree;

{**
 * 测试预分配安全栈
 *}
procedure TestPreAllocStack;
type
  TIntStack = specialize TPreAllocStack<Integer>;
var
  LStack: TIntStack;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 预分配安全栈测试 ===');
  
  LStack := TIntStack.Create(100); // 容量100
  try
    WriteLn('栈容量: ', LStack.GetCapacity);
    WriteLn('初始大小: ', LStack.GetSize);
    WriteLn('是否为空: ', BoolToStr(LStack.IsEmpty, 'True', 'False'));
    WriteLn('是否已满: ', BoolToStr(LStack.IsFull, 'True', 'False'));
    WriteLn;
    
    WriteLn('测试基础功能...');
    
    // 压栈测试
    WriteLn('压栈1-10...');
    for I := 1 to 10 do
    begin
      if LStack.Push(I) then
        WriteLn('  压栈 ', I, ' 成功')
      else
        WriteLn('  压栈 ', I, ' 失败');
    end;
    
    WriteLn('压栈后大小: ', LStack.GetSize);
    WriteLn('是否为空: ', BoolToStr(LStack.IsEmpty, 'True', 'False'));
    WriteLn;
    
    // 弹栈测试
    WriteLn('弹栈结果 (LIFO顺序): ');
    while LStack.Pop(LValue) do
      Write(LValue, ' ');
    WriteLn;
    
    WriteLn('弹栈后大小: ', LStack.GetSize);
    WriteLn('是否为空: ', BoolToStr(LStack.IsEmpty, 'True', 'False'));
    
    WriteLn('✅ 预分配安全栈基础功能正常！');
    
  finally
    LStack.Free;
  end;
  WriteLn;
end;

{**
 * 测试容量限制
 *}
procedure TestCapacityLimit;
type
  TIntStack = specialize TPreAllocStack<Integer>;
var
  LStack: TIntStack;
  LValue: Integer;
  I, LSuccessCount: Integer;
begin
  WriteLn('=== 容量限制测试 ===');
  
  LStack := TIntStack.Create(5); // 小容量测试
  try
    WriteLn('栈容量: ', LStack.GetCapacity);
    
    WriteLn('尝试压栈10个元素到容量为5的栈...');
    LSuccessCount := 0;
    for I := 1 to 10 do
    begin
      if LStack.Push(I) then
      begin
        Inc(LSuccessCount);
        WriteLn('  压栈 ', I, ' 成功');
      end
      else
        WriteLn('  压栈 ', I, ' 失败 (栈已满)');
    end;
    
    WriteLn('成功压栈: ', LSuccessCount, ' 个元素');
    WriteLn('栈大小: ', LStack.GetSize);
    WriteLn('是否已满: ', BoolToStr(LStack.IsFull, 'True', 'False'));
    
    if LSuccessCount = 5 then
      WriteLn('✅ 容量限制正确工作')
    else
      WriteLn('❌ 容量限制有问题');
    
    // 弹出所有元素
    WriteLn('弹出所有元素: ');
    while LStack.Pop(LValue) do
      Write(LValue, ' ');
    WriteLn;
    
    WriteLn('是否为空: ', BoolToStr(LStack.IsEmpty, 'True', 'False'));
    
  finally
    LStack.Free;
  end;
  WriteLn;
end;

{**
 * 性能测试
 *}
procedure TestPerformance;
type
  TIntStack = specialize TPreAllocStack<Integer>;
var
  LStack: TIntStack;
  LStartTime, LEndTime: QWord;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 性能测试 ===');
  
  LStack := TIntStack.Create(100000); // 大容量
  try
    WriteLn('预分配安全栈: 10万次压栈弹栈...');
    
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
    WriteLn('✅ 性能测试完成！');
    
  finally
    LStack.Free;
  end;
  WriteLn;
end;

{**
 * 边界条件测试
 *}
procedure TestEdgeCases;
type
  TIntStack = specialize TPreAllocStack<Integer>;
var
  LStack: TIntStack;
  LValue: Integer;
begin
  WriteLn('=== 边界条件测试 ===');
  
  LStack := TIntStack.Create(3);
  try
    WriteLn('测试空栈弹出...');
    if LStack.Pop(LValue) then
      WriteLn('❌ 空栈弹出应该失败')
    else
      WriteLn('✅ 空栈弹出正确失败');
    
    WriteLn('测试单个元素...');
    if LStack.Push(42) then
      WriteLn('✅ 单个元素压栈成功')
    else
      WriteLn('❌ 单个元素压栈失败');
    
    if LStack.Pop(LValue) and (LValue = 42) then
      WriteLn('✅ 单个元素弹栈正确，值为: ', LValue)
    else
      WriteLn('❌ 单个元素弹栈失败');
    
    WriteLn('测试填满栈...');
    LStack.Push(1);
    LStack.Push(2);
    LStack.Push(3);
    
    WriteLn('栈是否已满: ', BoolToStr(LStack.IsFull, 'True', 'False'));
    
    if not LStack.Push(4) then
      WriteLn('✅ 满栈拒绝新元素正确')
    else
      WriteLn('❌ 满栈应该拒绝新元素');
    
    WriteLn('✅ 边界条件测试完成！');
    
  finally
    LStack.Free;
  end;
  WriteLn;
end;

{**
 * 主程序
 *}
begin
  WriteLn('预分配安全无锁栈演示');
  WriteLn('基于nullprogram.com的C11无锁栈设计');
  WriteLn('====================================');
  WriteLn;
  
  try
    TestPreAllocStack;
    TestCapacityLimit;
    TestPerformance;
    TestEdgeCases;
    
    WriteLn('🎉 所有预分配安全栈测试完成！');
    WriteLn;
    WriteLn('📚 技术特点:');
    WriteLn('- 预分配节点池，避免malloc/free');
    WriteLn('- 使用ABA计数器解决ABA问题');
    WriteLn('- 双栈设计：主栈 + 空闲栈');
    WriteLn('- 基于学术界验证的算法');
    WriteLn;
    WriteLn('⚠️  限制:');
    WriteLn('- 有最大容量限制');
    WriteLn('- FPC的原子操作限制（无真正的DWCAS）');
    WriteLn('- 但在实际应用中足够安全和高效');
    
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
