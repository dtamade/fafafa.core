{$CODEPAGE UTF8}
program example_vecdeque;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  Classes, SysUtils,
  fafafa.core.base,
  fafafa.core.mem.allocator,
  fafafa.core.collections.base,
  fafafa.core.collections.arr,
  fafafa.core.collections.vec,
  fafafa.core.collections.queue,
  fafafa.core.collections.deque,
  fafafa.core.collections.vecdeque;

type
  { 自定义记录类型用于演示 }
  TPersonRecord = record
    Name: String;
    Age: Integer;
    Score: Double;
  end;

{ 演示基本双端队列操作 }
procedure DemoBasicDequeOperations;
var
  LDeque: specialize TVecDeque<Integer>;
  i: Integer;
  LValue: Integer;
begin
  WriteLn('=== 基本双端队列操作演示 ===');
  
  LDeque := specialize TVecDeque<Integer>.Create;
  try
    WriteLn('1. 创建空的双端队列');
    WriteLn('   队列为空: ', LDeque.IsEmpty);
    WriteLn('   元素数量: ', LDeque.GetCount);
    WriteLn;
    
    WriteLn('2. 从后端添加元素 (PushBack)');
    for i := 1 to 5 do
    begin
      LDeque.PushBack(i * 10);
      WriteLn('   添加 ', i * 10, ', 当前大小: ', LDeque.GetCount);
    end;
    WriteLn;
    
    WriteLn('3. 从前端添加元素 (PushFront)');
    for i := 1 to 3 do
    begin
      LDeque.PushFront(i);
      WriteLn('   前端添加 ', i, ', 当前大小: ', LDeque.GetCount);
    end;
    WriteLn;
    
    WriteLn('4. 查看当前队列内容:');
    Write('   [');
    for i := 0 to Integer(LDeque.GetCount) - 1 do
    begin
      if i > 0 then Write(', ');
      Write(LDeque.Get(i));
    end;
    WriteLn(']');
    WriteLn;
    
    WriteLn('5. 从前端移除元素 (PopFront)');
    while not LDeque.IsEmpty do
    begin
      LValue := LDeque.PopFront;
      WriteLn('   移除: ', LValue, ', 剩余: ', LDeque.GetCount);
      if LDeque.GetCount <= 3 then break; // 保留几个元素用于后续演示
    end;
    WriteLn;
    
    WriteLn('6. 从后端移除元素 (PopBack)');
    while not LDeque.IsEmpty do
    begin
      LValue := LDeque.PopBack;
      WriteLn('   移除: ', LValue, ', 剩余: ', LDeque.GetCount);
    end;
    WriteLn;
    
  finally
    LDeque.Free;
  end;
end;

{ 演示队列接口兼容性 }
procedure DemoQueueInterface;
var
  LDeque: specialize TVecDeque<String>;
  LValue: String;
  LSuccess: Boolean;
begin
  WriteLn('=== 队列接口兼容性演示 ===');
  
  LDeque := specialize TVecDeque<String>.Create;
  try
    WriteLn('1. 使用队列接口 (Enqueue/Dequeue)');
    LDeque.Enqueue('第一个');
    LDeque.Enqueue('第二个');
    LDeque.Enqueue('第三个');
    WriteLn('   入队3个元素，当前大小: ', LDeque.GetCount);
    
    while not LDeque.IsEmpty do
    begin
      LValue := LDeque.Dequeue;
      WriteLn('   出队: "', LValue, '"');
    end;
    WriteLn;
    
    WriteLn('2. 使用栈接口 (Push/Pop)');
    LDeque.Push('A');
    LDeque.Push('B');
    LDeque.Push('C');
    WriteLn('   压栈3个元素，当前大小: ', LDeque.GetCount);
    
    while not LDeque.IsEmpty do
    begin
      LValue := LDeque.Pop;
      WriteLn('   弹栈: "', LValue, '"');
    end;
    WriteLn;
    
    WriteLn('3. 安全操作演示');
    LSuccess := LDeque.PopFront(LValue);
    WriteLn('   空队列PopFront结果: ', LSuccess);
    
    LDeque.PushBack('测试');
    LSuccess := LDeque.PeekFront(LValue);
    WriteLn('   PeekFront成功: ', LSuccess, ', 值: "', LValue, '"');
    WriteLn;
    
  finally
    LDeque.Free;
  end;
end;

{ 演示批量操作 }
procedure DemoBatchOperations;
var
  LDeque: specialize TVecDeque<Integer>;
  LArray: array[0..4] of Integer;
  LData: array[0..2] of Integer;
  i: Integer;
begin
  WriteLn('=== 批量操作演示 ===');
  
  LDeque := specialize TVecDeque<Integer>.Create;
  try
    WriteLn('1. 批量添加数组到后端');
    for i := 0 to High(LArray) do
      LArray[i] := (i + 1) * 100;
    
    LDeque.PushBack(LArray);
    WriteLn('   添加数组后大小: ', LDeque.GetCount);
    
    Write('   内容: [');
    for i := 0 to Integer(LDeque.GetCount) - 1 do
    begin
      if i > 0 then Write(', ');
      Write(LDeque.Get(i));
    end;
    WriteLn(']');
    WriteLn;
    
    WriteLn('2. 批量添加到前端');
    LData[0] := 1;
    LData[1] := 2;
    LData[2] := 3;
    
    LDeque.PushFront(@LData[0], Length(LData));
    WriteLn('   添加指针数据后大小: ', LDeque.GetCount);
    
    Write('   内容: [');
    for i := 0 to Integer(LDeque.GetCount) - 1 do
    begin
      if i > 0 then Write(', ');
      Write(LDeque.Get(i));
    end;
    WriteLn(']');
    WriteLn;
    
  finally
    LDeque.Free;
  end;
end;

{ 演示性能特性 }
procedure DemoPerformanceFeatures;
var
  LDeque: specialize TVecDeque<Integer>;
  i: Integer;
  LStartTime, LEndTime: QWord;
  LOperationCount: Integer;
begin
  WriteLn('=== 性能特性演示 ===');
  
  LDeque := specialize TVecDeque<Integer>.Create;
  try
    LOperationCount := 100000;
    
    WriteLn('1. 容量管理');
    WriteLn('   初始容量: ', LDeque.GetCapacity);
    LDeque.Reserve(LOperationCount);
    WriteLn('   预留后容量: ', LDeque.GetCapacity);
    WriteLn;
    
    WriteLn('2. 大量前端插入性能测试');
    LStartTime := GetTickCount64;
    for i := 1 to LOperationCount do
      LDeque.PushFront(i);
    LEndTime := GetTickCount64;
    WriteLn('   插入 ', LOperationCount, ' 个元素耗时: ', LEndTime - LStartTime, ' ms');
    WriteLn('   最终大小: ', LDeque.GetCount);
    WriteLn('   最终容量: ', LDeque.GetCapacity);
    WriteLn;
    
    WriteLn('3. 大量后端移除性能测试');
    LStartTime := GetTickCount64;
    for i := 1 to LOperationCount do
      LDeque.PopBack;
    LEndTime := GetTickCount64;
    WriteLn('   移除 ', LOperationCount, ' 个元素耗时: ', LEndTime - LStartTime, ' ms');
    WriteLn('   最终大小: ', LDeque.GetCount);
    WriteLn;
    
    WriteLn('4. 内存优化');
    WriteLn('   收缩前容量: ', LDeque.GetCapacity);
    LDeque.ShrinkToFit;
    WriteLn('   收缩后容量: ', LDeque.GetCapacity);
    WriteLn;
    
  finally
    LDeque.Free;
  end;
end;

{ 演示自定义类型使用 }
procedure DemoCustomTypes;
var
  LDeque: specialize TVecDeque<TPersonRecord>;
  LPerson: TPersonRecord;
  i: Integer;
begin
  WriteLn('=== 自定义类型演示 ===');

  LDeque := specialize TVecDeque<TPersonRecord>.Create;
  try
    WriteLn('1. 添加自定义记录');

    LPerson.Name := '张三';
    LPerson.Age := 25;
    LPerson.Score := 85.5;
    LDeque.PushBack(LPerson);

    LPerson.Name := '李四';
    LPerson.Age := 30;
    LPerson.Score := 92.0;
    LDeque.PushFront(LPerson);

    LPerson.Name := '王五';
    LPerson.Age := 28;
    LPerson.Score := 78.5;
    LDeque.PushBack(LPerson);

    WriteLn('   添加了 ', LDeque.GetCount, ' 个人员记录');
    WriteLn;

    WriteLn('2. 遍历显示记录');
    for i := 0 to Integer(LDeque.GetCount) - 1 do
    begin
      LPerson := LDeque.Get(i);
      WriteLn('   [', i, '] 姓名: ', LPerson.Name,
              ', 年龄: ', LPerson.Age,
              ', 分数: ', LPerson.Score:0:1);
    end;
    WriteLn;

    WriteLn('3. 修改记录');
    LPerson := LDeque.Get(1);
    LPerson.Score := 95.0;
    LDeque.Put(1, LPerson);
    WriteLn('   修改第2个记录的分数为: ', LPerson.Score:0:1);
    WriteLn;

  finally
    LDeque.Free;
  end;
end;

{ 演示算法操作 }
procedure DemoAlgorithmOperations;
var
  LDeque: specialize TVecDeque<Integer>;
  i: Integer;
begin
  WriteLn('=== 算法操作演示 ===');

  LDeque := specialize TVecDeque<Integer>.Create;
  try
    WriteLn('1. 填充操作');
    LDeque.Resize(10);
    LDeque.Fill(0, 5, 42);  // 从索引0开始，填充5个元素为42
    LDeque.Fill(5, 5, 99);  // 从索引5开始，填充5个元素为99

    Write('   填充后内容: [');
    for i := 0 to Integer(LDeque.GetCount) - 1 do
    begin
      if i > 0 then Write(', ');
      Write(LDeque.Get(i));
    end;
    WriteLn(']');
    WriteLn;

    WriteLn('2. 反转操作');
    LDeque.Clear;
    for i := 1 to 8 do
      LDeque.PushBack(i);

    Write('   反转前: [');
    for i := 0 to Integer(LDeque.GetCount) - 1 do
    begin
      if i > 0 then Write(', ');
      Write(LDeque.Get(i));
    end;
    WriteLn(']');

    LDeque.Reverse;

    Write('   反转后: [');
    for i := 0 to Integer(LDeque.GetCount) - 1 do
    begin
      if i > 0 then Write(', ');
      Write(LDeque.Get(i));
    end;
    WriteLn(']');
    WriteLn;

    WriteLn('3. 交换操作');
    WriteLn('   交换索引0和7的元素');
    WriteLn('   交换前: 索引0=', LDeque.Get(0), ', 索引7=', LDeque.Get(7));
    LDeque.Swap(0, 7);
    WriteLn('   交换后: 索引0=', LDeque.Get(0), ', 索引7=', LDeque.Get(7));
    WriteLn;

  finally
    LDeque.Free;
  end;
end;

{ 演示实际应用场景 }
procedure DemoRealWorldUsage;
var
  LTaskQueue: specialize TVecDeque<String>;
  LUndoStack: specialize TVecDeque<String>;
  LTask: String;
  LAction: String;
  i: Integer;
begin
  WriteLn('=== 实际应用场景演示 ===');

  WriteLn('1. 任务队列 (先进先出)');
  LTaskQueue := specialize TVecDeque<String>.Create;
  try
    // 添加任务到队列
    LTaskQueue.Enqueue('发送邮件');
    LTaskQueue.Enqueue('生成报告');
    LTaskQueue.Enqueue('备份数据');
    LTaskQueue.Enqueue('清理缓存');

    WriteLn('   队列中有 ', LTaskQueue.GetCount, ' 个任务');

    // 处理任务
    while not LTaskQueue.IsEmpty do
    begin
      LTask := LTaskQueue.Dequeue;
      WriteLn('   正在处理任务: ', LTask);
      // 模拟任务处理时间
      Sleep(100);
    end;
    WriteLn('   所有任务处理完成');
    WriteLn;

  finally
    LTaskQueue.Free;
  end;

  WriteLn('2. 撤销栈 (后进先出)');
  LUndoStack := specialize TVecDeque<String>.Create;
  try
    // 记录用户操作
    LUndoStack.Push('创建文档');
    LUndoStack.Push('输入文本');
    LUndoStack.Push('设置格式');
    LUndoStack.Push('插入图片');
    LUndoStack.Push('保存文档');

    WriteLn('   撤销栈中有 ', LUndoStack.GetCount, ' 个操作');

    // 撤销最近的3个操作
    for i := 1 to 3 do
    begin
      if not LUndoStack.IsEmpty then
      begin
        LAction := LUndoStack.Pop;
        WriteLn('   撤销操作: ', LAction);
      end;
    end;

    WriteLn('   剩余操作: ', LUndoStack.GetCount, ' 个');
    WriteLn;

  finally
    LUndoStack.Free;
  end;
end;

{ 主程序 }
begin
  WriteLn('========================================');
  WriteLn('fafafa.core.collections.vecdeque 使用示例');
  WriteLn('========================================');
  WriteLn;

  try
    DemoBasicDequeOperations;
    WriteLn;

    DemoQueueInterface;
    WriteLn;

    DemoBatchOperations;
    WriteLn;

    DemoPerformanceFeatures;
    WriteLn;

    DemoCustomTypes;
    WriteLn;

    DemoAlgorithmOperations;
    WriteLn;

    DemoRealWorldUsage;
    WriteLn;

    WriteLn('========================================');
    WriteLn('示例演示完成！');
    WriteLn('VecDeque 提供了高效的双端队列实现，');
    WriteLn('支持在两端进行 O(1) 时间复杂度的插入和删除操作。');
    WriteLn('========================================');

  except
    on E: Exception do
    begin
      WriteLn('发生异常: ', E.ClassName, ' - ', E.Message);
      ExitCode := 1;
    end;
  end;

  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
