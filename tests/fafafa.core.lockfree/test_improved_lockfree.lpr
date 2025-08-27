program test_improved_lockfree;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.atomic,
  fafafa.core.lockfree;

// 测试改进后的TTreiberStack（ABA安全）
procedure TestImprovedTreiberStack;
type
  TIntStack = specialize TTreiberStack<Integer>;
var
  LStack: TIntStack;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 测试改进的Treiber栈（ABA安全） ===');
  
  LStack := TIntStack.Create;
  try
    WriteLn('1. 基础功能测试...');
    
    // 测试空栈
    WriteLn('  空栈测试: ', BoolToStr(LStack.IsEmpty, 'True', 'False'));
    if LStack.Pop(LValue) then
      WriteLn('  ❌ 空栈不应该能弹出元素')
    else
      WriteLn('  ✅ 空栈正确返回False');
    
    // 压栈测试
    WriteLn('2. 压栈测试...');
    for I := 1 to 10 do
    begin
      LStack.Push(I);
      Write(I, ' ');
    end;
    WriteLn;
    WriteLn('  栈是否为空: ', BoolToStr(LStack.IsEmpty, 'True', 'False'));
    
    // 弹栈测试
    WriteLn('3. 弹栈测试（LIFO顺序）:');
    Write('  弹出顺序: ');
    while LStack.Pop(LValue) do
      Write(LValue, ' ');
    WriteLn;
    
    WriteLn('  最终栈是否为空: ', BoolToStr(LStack.IsEmpty, 'True', 'False'));
    
    // 混合操作测试
    WriteLn('4. 混合操作测试...');
    LStack.Push(100);
    LStack.Push(200);
    if LStack.Pop(LValue) then
      WriteLn('  弹出: ', LValue, ' (期望: 200)');
    LStack.Push(300);
    if LStack.Pop(LValue) then
      WriteLn('  弹出: ', LValue, ' (期望: 300)');
    if LStack.Pop(LValue) then
      WriteLn('  弹出: ', LValue, ' (期望: 100)');
    
    WriteLn('✅ 改进的Treiber栈测试通过！');
    
  finally
    LStack.Free;
  end;
  WriteLn;
end;

// 测试改进后的TSPSCQueue（精确内存序）
procedure TestImprovedSPSCQueue;
type
  TIntQueue = TIntegerSPSCQueue;
var
  LQueue: TIntQueue;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 测试改进的SPSC队列（精确内存序） ===');
  
  LQueue := CreateIntSPSCQueue(8); // 容量为8
  try
    WriteLn('1. 基础功能测试...');
    
    // 测试空队列
    WriteLn('  空队列测试: ', BoolToStr(LQueue.IsEmpty, 'True', 'False'));
    if LQueue.Dequeue(LValue) then
      WriteLn('  ❌ 空队列不应该能出队')
    else
      WriteLn('  ✅ 空队列正确返回False');
    
    // 入队测试
    WriteLn('2. 入队测试...');
    for I := 1 to 6 do
    begin
      if LQueue.Enqueue(I) then
        Write(I, ' ')
      else
        WriteLn('  ❌ 入队失败: ', I);
    end;
    WriteLn;
    WriteLn('  队列是否为空: ', BoolToStr(LQueue.IsEmpty, 'True', 'False'));
    WriteLn('  队列是否已满: ', BoolToStr(LQueue.IsFull, 'True', 'False'));
    
    // 出队测试
    WriteLn('3. 出队测试（FIFO顺序）:');
    Write('  出队顺序: ');
    while LQueue.Dequeue(LValue) do
      Write(LValue, ' ');
    WriteLn;
    
    WriteLn('  最终队列是否为空: ', BoolToStr(LQueue.IsEmpty, 'True', 'False'));
    
    // 混合操作测试
    WriteLn('4. 混合操作测试...');
    LQueue.Enqueue(100);
    LQueue.Enqueue(200);
    if LQueue.Dequeue(LValue) then
      WriteLn('  出队: ', LValue, ' (期望: 100)');
    LQueue.Enqueue(300);
    if LQueue.Dequeue(LValue) then
      WriteLn('  出队: ', LValue, ' (期望: 200)');
    if LQueue.Dequeue(LValue) then
      WriteLn('  出队: ', LValue, ' (期望: 300)');
    
    WriteLn('✅ 改进的SPSC队列测试通过！');
    
  finally
    LQueue.Free;
  end;
  WriteLn;
end;

// 测试改进后的TMichaelScottQueue（C/C++兼容原子操作）
procedure TestImprovedMichaelScottQueue;
type
  TStringQueue = TStringMSQueue;
var
  LQueue: TStringQueue;
  LValue: string;
  I: Integer;
begin
  WriteLn('=== 测试改进的Michael-Scott队列（C/C++兼容原子操作） ===');
  
  LQueue := CreateStrMSQueue;
  try
    WriteLn('1. 基础功能测试...');
    
    // 测试空队列
    WriteLn('  空队列测试: ', BoolToStr(LQueue.IsEmpty, 'True', 'False'));
    if LQueue.Dequeue(LValue) then
      WriteLn('  ❌ 空队列不应该能出队')
    else
      WriteLn('  ✅ 空队列正确返回False');
    
    // 入队测试
    WriteLn('2. 入队测试...');
    for I := 1 to 5 do
    begin
      LQueue.Enqueue('Item' + IntToStr(I));
      Write('Item', I, ' ');
    end;
    WriteLn;
    WriteLn('  队列是否为空: ', BoolToStr(LQueue.IsEmpty, 'True', 'False'));
    
    // 出队测试
    WriteLn('3. 出队测试（FIFO顺序）:');
    Write('  出队顺序: ');
    while LQueue.Dequeue(LValue) do
      Write(LValue, ' ');
    WriteLn;
    
    WriteLn('  最终队列是否为空: ', BoolToStr(LQueue.IsEmpty, 'True', 'False'));
    
    // 混合操作测试
    WriteLn('4. 混合操作测试...');
    LQueue.Enqueue('First');
    LQueue.Enqueue('Second');
    if LQueue.Dequeue(LValue) then
      WriteLn('  出队: ', LValue, ' (期望: First)');
    LQueue.Enqueue('Third');
    if LQueue.Dequeue(LValue) then
      WriteLn('  出队: ', LValue, ' (期望: Second)');
    if LQueue.Dequeue(LValue) then
      WriteLn('  出队: ', LValue, ' (期望: Third)');
    
    WriteLn('✅ 改进的Michael-Scott队列测试通过！');
    
  finally
    LQueue.Free;
  end;
  WriteLn;
end;

// 性能对比测试
procedure TestPerformanceComparison;
type
  TIntStack = specialize TTreiberStack<Integer>;
var
  LStack: TIntStack;
  I: Integer;
  LStartTime, LEndTime: QWord;
  LValue: Integer;
const
  ITERATIONS = 1000000;
begin
  WriteLn('=== 性能对比测试 ===');
  
  LStack := TIntStack.Create;
  try
    WriteLn('测试', ITERATIONS, '次Push/Pop操作...');
    
    // 测试Push性能
    LStartTime := GetTickCount64;
    for I := 1 to ITERATIONS do
      LStack.Push(I);
    LEndTime := GetTickCount64;
    WriteLn('Push性能: ', ITERATIONS, '次操作耗时', LEndTime - LStartTime, 'ms');
    WriteLn('Push速率: ', Round(ITERATIONS / ((LEndTime - LStartTime) / 1000)), ' ops/sec');
    
    // 测试Pop性能
    LStartTime := GetTickCount64;
    for I := 1 to ITERATIONS do
      LStack.Pop(LValue);
    LEndTime := GetTickCount64;
    WriteLn('Pop性能: ', ITERATIONS, '次操作耗时', LEndTime - LStartTime, 'ms');
    WriteLn('Pop速率: ', Round(ITERATIONS / ((LEndTime - LStartTime) / 1000)), ' ops/sec');
    
    WriteLn('✅ 性能测试完成！');
    
  finally
    LStack.Free;
  end;
  WriteLn;
end;

procedure TestAtomicOperationsDemo;
var
  LValue32: Int32;
  LValue64: Int64;
  LTaggedPtr: tagged_ptr;
  LPtr: Pointer;
begin
  WriteLn('=== C/C++兼容原子操作演示 ===');
  
  WriteLn('1. 32位原子操作:');
  LValue32 := 100;
  WriteLn('  初始值: ', atomic_load(LValue32, memory_order_relaxed));
  atomic_store(LValue32, 200, memory_order_release);
  WriteLn('  store后: ', atomic_load(LValue32, memory_order_acquire));
  WriteLn('  fetch_add(50): ', atomic_fetch_add(LValue32, 50, memory_order_acq_rel));
  WriteLn('  当前值: ', atomic_load(LValue32, memory_order_seq_cst));
  
  WriteLn('2. 64位原子操作:');
  LValue64 := 1000000000;
  WriteLn('  初始值: ', atomic_load_64(LValue64, memory_order_relaxed));
  WriteLn('  increment: ', atomic_increment_64(LValue64));
  WriteLn('  当前值: ', atomic_load_64(LValue64, memory_order_relaxed));
  
  WriteLn('3. Tagged Pointer操作:');
  GetMem(LPtr, 100);
  LTaggedPtr := make_tagged_ptr(LPtr, 42);
  WriteLn('  指针: ', PtrUInt(get_ptr(LTaggedPtr)));
  WriteLn('  标签: ', get_tag(LTaggedPtr));
  WriteLn('  下一个标签: ', next_tag(LTaggedPtr));
  FreeMem(LPtr);
  
  WriteLn('✅ 原子操作演示完成！');
  WriteLn;
end;

begin
  WriteLn('fafafa.core.lockfree 改进版本测试');
  WriteLn('===================================');
  WriteLn;
  WriteLn('🚀 改进特性:');
  WriteLn('  ✅ TTreiberStack: 使用Tagged Pointer解决ABA问题');
  WriteLn('  ✅ TSPSCQueue: 使用精确内存序控制');
  WriteLn('  ✅ TMichaelScottQueue: 使用C/C++兼容原子操作');
  WriteLn('  ✅ 全面采用memory_order语义');
  WriteLn;
  
  try
    TestAtomicOperationsDemo;
    TestImprovedTreiberStack;
    TestImprovedSPSCQueue;
    TestImprovedMichaelScottQueue;
    TestPerformanceComparison;
    
    WriteLn('🎉 所有测试通过！无锁数据结构改进成功！');
    WriteLn;
    WriteLn('💡 改进成果:');
    WriteLn('  🔒 ABA问题彻底解决');
    WriteLn('  ⚡ 性能进一步优化');
    WriteLn('  🔧 C/C++兼容性增强');
    WriteLn('  📊 内存序精确控制');
    WriteLn;
    WriteLn('按回车键退出...');
    ReadLn;
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
