program enhanced_queue_demo;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

type
  TIntQueue = specialize TVecDeque<Integer>;
  TStringQueue = specialize TVecDeque<String>;

procedure DemoBasicQueueOperations;
var
  LQueue: TIntQueue;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 基本队列操作演示 ===');
  
  LQueue := TIntQueue.Create;
  try
    WriteLn('1. 创建空队列');
    WriteLn('   队列是否为空: ', LQueue.IsEmpty);
    WriteLn('   队列大小: ', LQueue.Count);
    WriteLn('   队列容量: ', LQueue.Capacity);
    WriteLn;
    
    WriteLn('2. 入队操作 (Enqueue/PushBack)');
    for I := 1 to 5 do
    begin
      LQueue.Enqueue(I * 10);
      WriteLn('   入队: ', I * 10, ', 当前大小: ', LQueue.Count);
    end;
    WriteLn;
    
    WriteLn('3. 查看队首和队尾元素');
    WriteLn('   队首 (Front): ', LQueue.PeekFront);
    WriteLn('   队尾 (Back): ', LQueue.PeekBack);
    WriteLn;
    
    WriteLn('4. 出队操作 (Dequeue/PopFront)');
    while not LQueue.IsEmpty do
    begin
      LValue := LQueue.Dequeue;
      WriteLn('   出队: ', LValue, ', 剩余大小: ', LQueue.Count);
    end;
    WriteLn;
    
  finally
    LQueue.Free;
  end;
end;

procedure DemoDoubleEndedOperations;
var
  LQueue: TIntQueue;
  LValue: Integer;
begin
  WriteLn('=== 双端队列操作演示 ===');
  
  LQueue := TIntQueue.Create;
  try
    WriteLn('1. 双端插入操作');
    LQueue.PushBack(20);   // 尾部插入
    LQueue.PushBack(30);   // 尾部插入
    LQueue.PushFront(10);  // 头部插入
    LQueue.PushFront(5);   // 头部插入
    
    WriteLn('   队列内容 (头->尾): ');
    Write('   ');
    for LValue in LQueue do
      Write(LValue, ' ');
    WriteLn;
    WriteLn('   队首: ', LQueue.PeekFront, ', 队尾: ', LQueue.PeekBack);
    WriteLn;
    
    WriteLn('2. 双端移除操作');
    LValue := LQueue.PopFront;
    WriteLn('   从头部移除: ', LValue);
    LValue := LQueue.PopBack;
    WriteLn('   从尾部移除: ', LValue);
    
    WriteLn('   剩余内容: ');
    Write('   ');
    for LValue in LQueue do
      Write(LValue, ' ');
    WriteLn;
    WriteLn;
    
  finally
    LQueue.Free;
  end;
end;

procedure DemoIndexedAccess;
var
  LQueue: TIntQueue;
  I: Integer;
  LValue: Integer;
begin
  WriteLn('=== 索引访问演示 ===');
  
  LQueue := TIntQueue.Create;
  try
    WriteLn('1. 填充队列');
    for I := 0 to 4 do
      LQueue.PushBack((I + 1) * 100);
    
    WriteLn('2. 索引访问 (类似数组)');
    for I := 0 to LQueue.Count - 1 do
    begin
      LValue := LQueue.Get(I);
      WriteLn('   索引 ', I, ': ', LValue);
    end;
    WriteLn;
    
    WriteLn('3. 在中间插入元素');
    LQueue.Insert(2, 250);  // 在索引2处插入250
    WriteLn('   在索引2插入250后:');
    for I := 0 to LQueue.Count - 1 do
    begin
      LValue := LQueue.Get(I);
      WriteLn('   索引 ', I, ': ', LValue);
    end;
    WriteLn;
    
    WriteLn('4. 移除中间元素');
    LValue := LQueue.Remove(1);  // 移除索引1的元素
    WriteLn('   移除索引1的元素: ', LValue);
    WriteLn('   移除后:');
    for I := 0 to LQueue.Count - 1 do
    begin
      LValue := LQueue.Get(I);
      WriteLn('   索引 ', I, ': ', LValue);
    end;
    WriteLn;
    
  finally
    LQueue.Free;
  end;
end;

procedure DemoCapacityManagement;
var
  LQueue: TIntQueue;
  I: Integer;
begin
  WriteLn('=== 容量管理演示 ===');
  
  LQueue := TIntQueue.Create;
  try
    WriteLn('1. 初始状态');
    WriteLn('   容量: ', LQueue.Capacity, ', 大小: ', LQueue.Count);
    
    WriteLn('2. 预留容量');
    LQueue.Reserve(100);
    WriteLn('   预留100个元素后容量: ', LQueue.Capacity);
    
    WriteLn('3. 添加元素');
    for I := 1 to 10 do
      LQueue.PushBack(I);
    WriteLn('   添加10个元素后 - 容量: ', LQueue.Capacity, ', 大小: ', LQueue.Count);
    
    WriteLn('4. 收缩容量');
    LQueue.ShrinkToFit;
    WriteLn('   收缩后容量: ', LQueue.Capacity, ', 大小: ', LQueue.Count);
    
    WriteLn('5. 调整大小');
    LQueue.Resize(15);
    WriteLn('   调整到15个元素后 - 容量: ', LQueue.Capacity, ', 大小: ', LQueue.Count);
    
    WriteLn('6. 截断');
    LQueue.Truncate(5);
    WriteLn('   截断到5个元素后 - 容量: ', LQueue.Capacity, ', 大小: ', LQueue.Count);
    WriteLn;
    
  finally
    LQueue.Free;
  end;
end;

procedure DemoBatchOperations;
var
  LQueue: TIntQueue;
  LArray: array[0..4] of Integer = (100, 200, 300, 400, 500);
  LValue: Integer;
begin
  WriteLn('=== 批量操作演示 ===');
  
  LQueue := TIntQueue.Create;
  try
    WriteLn('1. 批量入队 (数组)');
    LQueue.PushBack(LArray);
    WriteLn('   批量添加后大小: ', LQueue.Count);
    
    WriteLn('2. 批量头部插入');
    LQueue.PushFront(LArray);
    WriteLn('   头部批量添加后大小: ', LQueue.Count);
    
    WriteLn('3. 当前队列内容:');
    Write('   ');
    for LValue in LQueue do
      Write(LValue, ' ');
    WriteLn;
    WriteLn;
    
  finally
    LQueue.Free;
  end;
end;

procedure DemoPerformanceComparison;
var
  LQueue: TIntQueue;
  I: Integer;
  LStartTime, LEndTime: QWord;
begin
  WriteLn('=== 性能对比演示 ===');
  
  LQueue := TIntQueue.Create;
  try
    WriteLn('1. 测试大量头部插入 (PushFront)');
    LStartTime := GetTickCount64;
    for I := 1 to 100000 do
      LQueue.PushFront(I);
    LEndTime := GetTickCount64;
    WriteLn('   插入100,000个元素用时: ', LEndTime - LStartTime, ' ms');
    WriteLn('   最终大小: ', LQueue.Count);
    
    WriteLn('2. 测试大量头部移除 (PopFront)');
    LStartTime := GetTickCount64;
    while not LQueue.IsEmpty do
      LQueue.PopFront;
    LEndTime := GetTickCount64;
    WriteLn('   移除所有元素用时: ', LEndTime - LStartTime, ' ms');
    WriteLn('   最终大小: ', LQueue.Count);
    WriteLn;
    
  finally
    LQueue.Free;
  end;
end;

begin
  WriteLn('🚀 增强队列功能演示程序');
  WriteLn('基于 Rust VecDeque 优化的高性能双端队列');
  WriteLn('================================================');
  WriteLn;
  
  try
    DemoBasicQueueOperations;
    DemoDoubleEndedOperations;
    DemoIndexedAccess;
    DemoCapacityManagement;
    DemoBatchOperations;
    DemoPerformanceComparison;
    
    WriteLn('🎉 所有演示完成！');
    WriteLn;
    WriteLn('总结 - 对照 Rust VecDeque 的优化点:');
    WriteLn('✅ 双端操作: PushFront/PopFront, PushBack/PopBack');
    WriteLn('✅ 索引访问: Get(index), Insert(index), Remove(index)');
    WriteLn('✅ 容量管理: Reserve, ShrinkToFit, Resize, Truncate');
    WriteLn('✅ 批量操作: 数组和指针批量插入');
    WriteLn('✅ 高性能: O(1) 双端操作，环形缓冲区实现');
    WriteLn('✅ 内存优化: 智能容量管理和收缩策略');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
