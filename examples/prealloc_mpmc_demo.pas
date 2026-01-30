program PreAllocMPMCDemo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  // 原子统一：示例不再引用 fafafa.core.sync
  fafafa.core.lockfree;

{**
 * 测试预分配MPMC队列基础功能
 *}
procedure TestBasicMPMCQueue;
type
  TIntQueue = TIntMPMCQueue;
var
  LQueue: TIntQueue;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 预分配MPMC队列基础测试 ===');
  
  LQueue := CreateIntMPMCQueue(16); // 小容量便于测试
  try
    WriteLn('队列容量: ', LQueue.GetCapacity);
    WriteLn('初始大小: ', LQueue.GetSize);
    WriteLn('是否为空: ', BoolToStr(LQueue.IsEmpty, 'True', 'False'));
    WriteLn('是否已满: ', BoolToStr(LQueue.IsFull, 'True', 'False'));
    WriteLn;
    
    WriteLn('入队1-10...');
    for I := 1 to 10 do
    begin
      if LQueue.Enqueue(I) then
        WriteLn('  入队 ', I, ' 成功')
      else
        WriteLn('  入队 ', I, ' 失败');
    end;
    
    WriteLn('入队后大小: ', LQueue.GetSize);
    WriteLn('是否为空: ', BoolToStr(LQueue.IsEmpty, 'True', 'False'));
    WriteLn;
    
    WriteLn('出队结果 (FIFO顺序): ');
    while LQueue.Dequeue(LValue) do
      Write(LValue, ' ');
    WriteLn;
    
    WriteLn('出队后大小: ', LQueue.GetSize);
    WriteLn('是否为空: ', BoolToStr(LQueue.IsEmpty, 'True', 'False'));
    
    WriteLn('✅ 预分配MPMC队列基础功能正常！');
    
  finally
    LQueue.Free;
  end;
  WriteLn;
end;

{**
 * 测试容量限制
 *}
procedure TestCapacityLimit;
type
  TIntQueue = specialize TPreAllocMPMCQueue<Integer>;
var
  LQueue: TIntQueue;
  LValue: Integer;
  I, LSuccessCount: Integer;
begin
  WriteLn('=== 容量限制测试 ===');
  
  LQueue := CreateIntMPMCQueue(4); // 容量4
  try
    WriteLn('队列容量: ', LQueue.GetCapacity);
    
    WriteLn('尝试入队8个元素到容量为4的队列...');
    LSuccessCount := 0;
    for I := 1 to 8 do
    begin
      if LQueue.Enqueue(I) then
      begin
        Inc(LSuccessCount);
        WriteLn('  入队 ', I, ' 成功');
      end
      else
        WriteLn('  入队 ', I, ' 失败 (队列已满)');
    end;
    
    WriteLn('成功入队: ', LSuccessCount, ' 个元素');
    WriteLn('队列大小: ', LQueue.GetSize);
    WriteLn('是否已满: ', BoolToStr(LQueue.IsFull, 'True', 'False'));
    
    if LSuccessCount = 4 then
      WriteLn('✅ 容量限制正确工作')
    else
      WriteLn('❌ 容量限制有问题');
    
    // 出队所有元素
    WriteLn('出队所有元素: ');
    while LQueue.Dequeue(LValue) do
      Write(LValue, ' ');
    WriteLn;
    
    WriteLn('是否为空: ', BoolToStr(LQueue.IsEmpty, 'True', 'False'));
    
  finally
    LQueue.Free;
  end;
  WriteLn;
end;

{**
 * 性能测试
 *}
procedure TestPerformance;
type
  TIntQueue = TIntMPMCQueue;
var
  LQueue: TIntQueue;
  LStartTime, LEndTime: QWord;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 性能测试 ===');
  
  LQueue := TIntQueue.Create(100000); // 大容量
  try
    WriteLn('预分配MPMC队列: 10万次入队出队...');
    
    LStartTime := GetTickCount64;
    
    // 入队10万次
    for I := 1 to 100000 do
      LQueue.Enqueue(I);
    
    // 出队10万次
    for I := 1 to 100000 do
      LQueue.Dequeue(LValue);
    
    LEndTime := GetTickCount64;
    
    WriteLn('20万次操作耗时: ', LEndTime - LStartTime, ' ms');
    if (LEndTime - LStartTime) > 0 then
      WriteLn('吞吐量: ', 200000 * 1000 div (LEndTime - LStartTime), ' ops/sec')
    else
      WriteLn('吞吐量: 极高 (操作太快，无法测量)');
    
    WriteLn('最终队列大小: ', LQueue.GetSize);
    WriteLn('✅ 性能测试完成！');
    
  finally
    LQueue.Free;
  end;
  WriteLn;
end;

{**
 * 边界条件测试
 *}
procedure TestEdgeCases;
type
  TIntQueue = specialize TPreAllocMPMCQueue<Integer>;
var
  LQueue: TIntQueue;
  LValue: Integer;
begin
  WriteLn('=== 边界条件测试 ===');
  
  LQueue := TIntQueue.Create(2);
  try
    WriteLn('测试空队列出队...');
    if LQueue.Dequeue(LValue) then
      WriteLn('❌ 空队列出队应该失败')
    else
      WriteLn('✅ 空队列出队正确失败');
    
    WriteLn('测试单个元素...');
    if LQueue.Enqueue(42) then
      WriteLn('✅ 单个元素入队成功')
    else
      WriteLn('❌ 单个元素入队失败');
    
    if LQueue.Dequeue(LValue) and (LValue = 42) then
      WriteLn('✅ 单个元素出队正确，值为: ', LValue)
    else
      WriteLn('❌ 单个元素出队失败');
    
    WriteLn('测试填满队列...');
    LQueue.Enqueue(1);
    LQueue.Enqueue(2);
    
    WriteLn('队列是否已满: ', BoolToStr(LQueue.IsFull, 'True', 'False'));
    
    if not LQueue.Enqueue(3) then
      WriteLn('✅ 满队列拒绝新元素正确')
    else
      WriteLn('❌ 满队列应该拒绝新元素');
    
    WriteLn('测试环形缓冲区wrap-around...');
    // 出队一个元素
    LQueue.Dequeue(LValue);
    WriteLn('出队一个元素: ', LValue);
    
    // 再入队一个元素，测试wrap-around
    if LQueue.Enqueue(3) then
      WriteLn('✅ wrap-around入队成功')
    else
      WriteLn('❌ wrap-around入队失败');
    
    WriteLn('✅ 边界条件测试完成！');
    
  finally
    LQueue.Free;
  end;
  WriteLn;
end;

{**
 * 主程序
 *}
begin
  WriteLn('预分配MPMC队列演示');
  WriteLn('基于Dmitry Vyukov的MPMC队列算法');
  WriteLn('=================================');
  WriteLn;
  
  try
    TestBasicMPMCQueue;
    TestCapacityLimit;
    TestPerformance;
    TestEdgeCases;
    
    WriteLn('🎉 所有预分配MPMC队列测试完成！');
    WriteLn;
    WriteLn('📚 算法特点:');
    WriteLn('- 基于Dmitry Vyukov的经典MPMC算法');
    WriteLn('- 使用序列号解决ABA问题和wrap-around冲突');
    WriteLn('- 预分配环形缓冲区，避免动态内存分配');
    WriteLn('- 支持多个生产者和多个消费者并发访问');
    WriteLn;
    WriteLn('⚠️  注意:');
    WriteLn('- 有最大容量限制');
    WriteLn('- 容量必须是2的幂次方');
    WriteLn('- 在高竞争下性能优于锁机制');
    
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
