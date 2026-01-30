program example_lockfree;
{$IFDEF FAFAFA_CI_MODE}{$APPTYPE CONSOLE}{$ENDIF}


{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  // 原子统一：示例不再引用 fafafa.core.sync
  fafafa.core.lockfree,
  fafafa.core.lockfree.spscQueue,
  fafafa.core.lockfree.michaelScottQueue,
  fafafa.core.lockfree.mpmcQueue,
  fafafa.core.lockfree.hashmap,
  fafafa.core.lockfree.stack;

{ 基础用法示例 }
procedure BasicUsageExamples;
var
  LSPSCQueue: TStringSPSCQueue;
  LMSQueue: TIntMPSCQueue;
  LMPMCQueue: TIntMPMCQueue;
  LTreiberStack: specialize TTreiberStack<string>;
  LPreAllocStack: specialize TPreAllocStack<Integer>;
  LHashMap: TIntStrOAHashMap;
  LValue: string;
  LIntValue: Integer;
  I: Integer;
begin
  WriteLn('=== 基础用法示例 ===');
  WriteLn;

  // 1. SPSC队列示例
  WriteLn('1. SPSC队列（单生产者单消费者）');
  LSPSCQueue := CreateStrSPSCQueue(8);
  try
    // 入队操作
    LSPSCQueue.Enqueue('Hello');
    LSPSCQueue.Enqueue('World');
    LSPSCQueue.Enqueue('Lock-Free');

    WriteLn('   队列大小: ', LSPSCQueue.Size);

    // 出队操作
    Write('   出队结果: ');
    while LSPSCQueue.Dequeue(LValue) do
      Write(LValue, ' ');
    WriteLn;
  finally
    LSPSCQueue.Free;
  end;
  WriteLn;

  // 2. MPSC（Michael-Scott）队列示例
  WriteLn('2. MPSC（Michael-Scott）队列');
  LMSQueue := CreateIntMPSCQueue;
  try
    // 入队操作
    for I := 1 to 5 do
      LMSQueue.Enqueue(I * 10);

    // 出队操作
    Write('   出队结果: ');
    while LMSQueue.Dequeue(LIntValue) do
      Write(LIntValue, ' ');
    WriteLn;
  finally
    LMSQueue.Free;
  end;
  WriteLn;

  // 3. 预分配MPMC队列示例
  WriteLn('3. 预分配MPMC队列');
  LMPMCQueue := CreateIntMPMCQueue(16);
  try
    // 入队操作
    for I := 1 to 8 do
      LMPMCQueue.Enqueue(I);

    WriteLn('   队列容量: ', LMPMCQueue.GetCapacity);
    WriteLn('   队列大小: ', LMPMCQueue.GetSize);
    WriteLn('   是否为空: ', LMPMCQueue.IsEmpty);
    WriteLn('   是否已满: ', LMPMCQueue.IsFull);

    // 出队操作
    Write('   出队结果: ');
    while LMPMCQueue.Dequeue(LIntValue) do
      Write(LIntValue, ' ');
    WriteLn;
  finally
    LMPMCQueue.Free;
  end;
  WriteLn;

  // 4. Treiber栈示例
  WriteLn('4. Treiber栈（无锁栈）');
  LTreiberStack := specialize TTreiberStack<string>.Create;
  try
    // 压栈操作
    LTreiberStack.Push('First');
    LTreiberStack.Push('Second');
    LTreiberStack.Push('Third');

    // 弹栈操作
    Write('   弹栈结果: ');
    while LTreiberStack.Pop(LValue) do
      Write(LValue, ' ');
    WriteLn;
  finally
    LTreiberStack.Free;
  end;
  WriteLn;

  // 5. 预分配栈示例
  WriteLn('5. 预分配栈（ABA安全）');
  LPreAllocStack := specialize TPreAllocStack<Integer>.Create(32);
  try
    // 压栈操作
    for I := 1 to 10 do
      LPreAllocStack.Push(I);

    WriteLn('   栈容量: ', LPreAllocStack.GetCapacity);
    WriteLn('   栈大小: ', LPreAllocStack.GetSize);

    // 弹栈操作
    Write('   弹栈结果: ');
    while LPreAllocStack.Pop(LIntValue) do
      Write(LIntValue, ' ');
    WriteLn;
  finally
    LPreAllocStack.Free;
  end;
  WriteLn;

  // 6. 无锁哈希表示例
  WriteLn('6. 无锁哈希表');
  LHashMap := CreateIntStrOAHashMap(32);
  try
    // 插入操作
    LHashMap.Put(1, 'One');
    LHashMap.Put(2, 'Two');
    LHashMap.Put(3, 'Three');

    WriteLn('   哈希表容量: ', LHashMap.GetCapacity);
    WriteLn('   哈希表大小: ', LHashMap.GetSize);

    // 查询操作
    for I := 1 to 3 do
    begin
      if LHashMap.Get(I, LValue) then
        WriteLn('   Key ', I, ' -> ', LValue)
      else
        WriteLn('   Key ', I, ' not found');
    end;

    // 删除操作
    LHashMap.Remove(2);
    WriteLn('   删除Key 2后，大小: ', LHashMap.GetSize);

  finally
    LHashMap.Free;
  end;
  WriteLn;
end;

{ 性能对比示例 }
procedure PerformanceComparison;
var
  LLockFreeStack: specialize TTreiberStack<Integer>;
  LPreAllocStack: specialize TPreAllocStack<Integer>;
  LStartTime, LEndTime: QWord;
  I: Integer;
  LValue: Integer;
  LOperations: Integer;
begin
  WriteLn('=== 性能对比示例 ===');
  WriteLn;

  LOperations := 100000;

  // 1. Treiber栈性能测试
  WriteLn('1. Treiber栈性能测试（', LOperations, '次操作）');
  LLockFreeStack := specialize TTreiberStack<Integer>.Create;
  try
    LStartTime := GetTickCount64;

    // 压栈操作
    for I := 1 to LOperations do
      LLockFreeStack.Push(I);

    // 弹栈操作
    for I := 1 to LOperations do
      LLockFreeStack.Pop(LValue);

    LEndTime := GetTickCount64;
    WriteLn('   Treiber栈耗时: ', LEndTime - LStartTime, ' ms');

  finally
    LLockFreeStack.Free;
  end;

  // 2. 预分配栈性能测试
  WriteLn('2. 预分配栈性能测试（', LOperations, '次操作）');
  LPreAllocStack := specialize TPreAllocStack<Integer>.Create(LOperations + 1000);
  try
    LStartTime := GetTickCount64;

    // 压栈操作
    for I := 1 to LOperations do
      LPreAllocStack.Push(I);

    // 弹栈操作
    for I := 1 to LOperations do
      LPreAllocStack.Pop(LValue);

    LEndTime := GetTickCount64;
    WriteLn('   预分配栈耗时: ', LEndTime - LStartTime, ' ms');

  finally
    LPreAllocStack.Free;
  end;
  WriteLn;
end;

{ 最佳实践示例 }
procedure BestPracticesExamples;
var
  LQueue: TIntMPMCQueue;
  LStack: specialize TPreAllocStack<string>;
  LHashMap: TStrIntOAHashMap;
  LValue: Integer;
  LStrValue: string;
begin
  WriteLn('=== 最佳实践示例 ===');
  WriteLn;

  // 1. 选择合适的容量
  WriteLn('1. 选择合适的容量');
  WriteLn('   - 预分配数据结构需要合理的容量设置');
  WriteLn('   - 容量过小会导致操作失败');
  WriteLn('   - 容量过大会浪费内存');

  LQueue := CreateIntMPMCQueue(64); // 2的幂次方更高效
  try
    WriteLn('   MPMC队列容量: ', LQueue.GetCapacity);
  finally
    LQueue.Free;
  end;
  WriteLn;

  // 2. 错误处理
  WriteLn('2. 正确的错误处理');
  LStack := specialize TPreAllocStack<string>.Create(3); // 小容量用于演示
  try
    WriteLn('   压栈操作结果:');
    if LStack.Push('Item1') then WriteLn('     Item1: 成功') else WriteLn('     Item1: 失败');
    if LStack.Push('Item2') then WriteLn('     Item2: 成功') else WriteLn('     Item2: 失败');
    if LStack.Push('Item3') then WriteLn('     Item3: 成功') else WriteLn('     Item3: 失败');
    if LStack.Push('Item4') then WriteLn('     Item4: 成功') else WriteLn('     Item4: 失败（栈已满）');

    WriteLn('   弹栈操作结果:');
    while LStack.Pop(LStrValue) do
      WriteLn('     弹出: ', LStrValue);

    if LStack.Pop(LStrValue) then
      WriteLn('     额外弹栈: 成功')
    else
      WriteLn('     额外弹栈: 失败（栈为空）');

  finally
    LStack.Free;
  end;
  WriteLn;

  // 3. 哈希表的键值管理
  WriteLn('3. 哈希表的键值管理');
  LHashMap := CreateStrIntOAHashMap(16);
  try
    // 插入和更新
    LHashMap.Put('apple', 100);
    LHashMap.Put('banana', 200);
    LHashMap.Put('apple', 150); // 更新现有键

    // 安全的查询
    if LHashMap.Get('apple', LValue) then
      WriteLn('   apple的价格: ', LValue)
    else
      WriteLn('   apple未找到');

    // 检查键是否存在
    if LHashMap.ContainsKey('orange') then
      WriteLn('   orange存在')
    else
      WriteLn('   orange不存在');

    // 安全的删除
    if LHashMap.Remove('banana') then
      WriteLn('   banana删除成功')
    else
      WriteLn('   banana删除失败（不存在）');

  finally
    LHashMap.Free;
  end;
  WriteLn;

  // 4. 内存管理建议
  WriteLn('4. 内存管理建议');
  WriteLn('   - 无锁数据结构通常比传统锁定结构消耗更多内存');
  WriteLn('   - 预分配结构在创建时分配所有内存，运行时无额外分配');
  WriteLn('   - 动态结构（如Treiber栈）会在运行时分配/释放内存');
  WriteLn('   - 在高频操作场景下，预分配结构通常性能更好');
  WriteLn;
end;

{ 工具函数示例 }
procedure UtilityFunctionsExample;
var
  I: Integer;
  LHash: Cardinal;
  LData: Integer;
begin
  WriteLn('=== 工具函数示例 ===');
  WriteLn;

  // 1. 2的幂次方工具函数
  WriteLn('1. 2的幂次方工具函数');
  for I := 0 to 20 do
  begin
    if I mod 5 = 0 then
      WriteLn('   NextPowerOfTwo(', I, ') = ', NextPowerOfTwo(I));
  end;
  WriteLn;

  WriteLn('2. 2的幂次方检查');
  for I := 1 to 17 do
  begin
    if IsPowerOfTwo(I) then
      WriteLn('   ', I, ' 是2的幂次方');
  end;
  WriteLn;

  // 3. 简单哈希函数
  WriteLn('3. 简单哈希函数示例');
  for I := 1 to 5 do
  begin
    LData := I * 100;
    LHash := SimpleHash(LData, SizeOf(LData));
    WriteLn('   SimpleHash(', LData, ') = ', LHash);
  end;
  WriteLn;
end;

{ 性能监控示例 }
procedure PerformanceMonitoringExample;
var
  LMonitor: TPerformanceMonitor;
  LQueue: TIntegerSPSCQueue;
  I: Integer;
  LValue: Integer;
  LStartTime, LEndTime: QWord;
  LSuccess: Boolean;
begin
  WriteLn('=== 性能监控示例 ===');
  WriteLn;

  LMonitor := TPerformanceMonitor.Create;
  LQueue := CreateIntSPSCQueue(1024);
  try
    LMonitor.Enable;
    LMonitor.Reset;
    LStartTime := GetTickCount64;

    // 执行一些操作并记录结果
    for I := 1 to 10000 do
    begin
      LSuccess := LQueue.Enqueue(I);
      LMonitor.RecordOperation(LSuccess);
    end;

    for I := 1 to 10000 do
    begin
      LSuccess := LQueue.Dequeue(LValue);
      LMonitor.RecordOperation(LSuccess);
    end;

    LEndTime := GetTickCount64;

    WriteLn('   操作完成');
    WriteLn('   耗时: ', LEndTime - LStartTime, ' ms');
    WriteLn('   总操作数: ', LMonitor.GetTotalOperations);
    WriteLn('   成功操作数: ', LMonitor.GetSuccessfulOperations);
    WriteLn('   失败操作数: ', LMonitor.GetFailedOperations);
    WriteLn('   错误率: ', LMonitor.GetErrorRate:0:2, '%');
    WriteLn('   吞吐量: ', LMonitor.GetThroughput:0:2, ' ops/sec');

    WriteLn;
    WriteLn('   详细报告:');
    WriteLn(LMonitor.GenerateReport);

  finally
    LQueue.Free;
    LMonitor.Free;
  end;
  WriteLn;
end;

begin
  WriteLn('fafafa.core.lockfree 无锁数据结构示例');
  WriteLn('=====================================');
  WriteLn;

  try
    BasicUsageExamples;
    PerformanceComparison;
    BestPracticesExamples;
    UtilityFunctionsExample;
    PerformanceMonitoringExample;

    WriteLn('🎉 所有示例运行完成！');
    WriteLn;
    WriteLn('总结：');
    WriteLn('- 无锁数据结构提供了高性能的并发访问能力');
    WriteLn('- 预分配结构适合已知容量上限的场景');
    WriteLn('- 动态结构适合容量不确定的场景');
    WriteLn('- 正确的错误处理和容量规划是关键');
    WriteLn('- 性能监控有助于优化和调试');

  except
    on E: Exception do
    begin
      WriteLn('❌ 示例运行失败: ', E.Message);
      ExitCode := 1;
    end;
  end;

  {$IFNDEF FAFAFA_CI_MODE}
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
  {$ENDIF}
end.
