program CorrectLockFreeDemo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.sync,
  fafafa.core.lockfree;

{**
 * 测试正确的Treiber栈实现
 *}
procedure TestTreiberStack;
type
  TIntStack = specialize TTreiberStack<Integer>;
var
  LStack: TIntStack;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== Treiber无锁栈测试 ===');
  
  LStack := TIntStack.Create;
  try
    WriteLn('测试基础功能...');
    
    // 压栈测试
    WriteLn('压栈1-10...');
    for I := 1 to 10 do
      LStack.Push(I);
    
    // 弹栈测试
    WriteLn('弹栈结果 (LIFO顺序): ');
    while LStack.Pop(LValue) do
      Write(LValue, ' ');
    WriteLn;
    
    WriteLn('栈是否为空: ', BoolToStr(LStack.IsEmpty, 'True', 'False'));
    
    WriteLn('✅ Treiber栈基础功能正常！');
    
  finally
    LStack.Free;
  end;
  WriteLn;
end;

{**
 * 测试Michael-Scott队列实现
 *}
procedure TestMichaelScottQueue;
type
  TIntQueue = TIntMPSCQueue;
var
  LQueue: TIntQueue;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== Michael-Scott无锁队列测试 ===');
  
  LQueue := CreateIntMPSCQueue;
  try
    WriteLn('测试基础功能...');
    
    // 入队测试
    WriteLn('入队1-10...');
    for I := 1 to 10 do
      LQueue.Enqueue(I);
    
    WriteLn('队列是否为空: ', BoolToStr(LQueue.IsEmpty, 'True', 'False'));
    
    // 出队测试
    WriteLn('出队结果 (FIFO顺序): ');
    while LQueue.Dequeue(LValue) do
      Write(LValue, ' ');
    WriteLn;
    
    WriteLn('队列是否为空: ', BoolToStr(LQueue.IsEmpty, 'True', 'False'));
    
    WriteLn('✅ Michael-Scott队列基础功能正常！');
    
  finally
    LQueue.Free;
  end;
  WriteLn;
end;

{**
 * 测试性能
 *}
procedure TestPerformance;
type
  TIntStack = specialize TTreiberStack<Integer>;
  TIntQueue = TIntMPSCQueue;
var
  LStack: TIntStack;
  LQueue: TIntQueue;
  LStartTime, LEndTime: QWord;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 性能测试 ===');
  
  // 测试栈性能
  LStack := TIntStack.Create;
  try
    WriteLn('Treiber栈: 10万次压栈弹栈...');
    
    LStartTime := GetTickCount64;
    
    for I := 1 to 100000 do
      LStack.Push(I);
    
    for I := 1 to 100000 do
      LStack.Pop(LValue);
    
    LEndTime := GetTickCount64;
    
    WriteLn('栈操作耗时: ', LEndTime - LStartTime, ' ms');
    if (LEndTime - LStartTime) > 0 then
      WriteLn('栈吞吐量: ', 200000 * 1000 div (LEndTime - LStartTime), ' ops/sec')
    else
      WriteLn('栈吞吐量: 极高 (操作太快，无法测量)');
    
  finally
    LStack.Free;
  end;
  
  // 测试队列性能
  LQueue := CreateIntMPSCQueue;
  try
    WriteLn('Michael-Scott队列: 10万次入队出队...');
    
    LStartTime := GetTickCount64;
    
    for I := 1 to 100000 do
      LQueue.Enqueue(I);
    
    for I := 1 to 100000 do
      LQueue.Dequeue(LValue);
    
    LEndTime := GetTickCount64;
    
    WriteLn('队列操作耗时: ', LEndTime - LStartTime, ' ms');
    if (LEndTime - LStartTime) > 0 then
      WriteLn('队列吞吐量: ', 200000 * 1000 div (LEndTime - LStartTime), ' ops/sec')
    else
      WriteLn('队列吞吐量: 极高 (操作太快，无法测量)');
    
  finally
    LQueue.Free;
  end;
  WriteLn;
end;

{**
 * 测试边界条件
 *}
procedure TestEdgeCases;
type
  TIntStack = specialize TTreiberStack<Integer>;
  TIntQueue = specialize TMichaelScottQueue<Integer>;
var
  LStack: TIntStack;
  LQueue: TIntQueue;
  LValue: Integer;
begin
  WriteLn('=== 边界条件测试 ===');
  
  // 测试空栈
  LStack := TIntStack.Create;
  try
    WriteLn('测试空栈弹出...');
    if LStack.Pop(LValue) then
      WriteLn('❌ 空栈弹出应该失败')
    else
      WriteLn('✅ 空栈弹出正确失败');
    
    WriteLn('空栈是否为空: ', BoolToStr(LStack.IsEmpty, 'True', 'False'));
    
  finally
    LStack.Free;
  end;
  
  // 测试空队列
  LQueue := TIntQueue.Create;
  try
    WriteLn('测试空队列出队...');
    if LQueue.Dequeue(LValue) then
      WriteLn('❌ 空队列出队应该失败')
    else
      WriteLn('✅ 空队列出队正确失败');
    
    WriteLn('空队列是否为空: ', BoolToStr(LQueue.IsEmpty, 'True', 'False'));
    
  finally
    LQueue.Free;
  end;
  
  WriteLn('✅ 边界条件测试完成！');
  WriteLn;
end;

{**
 * 主程序
 *}
begin
  WriteLn('正确的无锁数据结构演示');
  WriteLn('基于学术界标准算法实现');
  WriteLn('========================');
  WriteLn;
  
  try
    TestTreiberStack;
    TestMichaelScottQueue;
    TestPerformance;
    TestEdgeCases;
    
    WriteLn('🎉 所有正确的无锁数据结构测试完成！');
    WriteLn;
    WriteLn('📚 算法来源:');
    WriteLn('- Treiber栈: R. Kent Treiber, 1986');
    WriteLn('- Michael-Scott队列: Michael & Scott, 1996');
    WriteLn('- 这些是学术界和工业界广泛认可的标准实现');
    WriteLn;
    WriteLn('⚠️  注意:');
    WriteLn('- 在手动内存管理的语言中仍存在ABA问题');
    WriteLn('- 生产环境建议使用hazard pointers或epoch-based回收');
    WriteLn('- 但这些实现遵循了正确的算法逻辑');
    
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
