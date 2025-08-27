program BasicUsageExample;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  fafafa.core.collections.vecdeque.specialized;

{ 基础使用示例 }
procedure BasicOperationsExample;
var
  LNumbers: TIntegerVecDeque;
  i: Integer;
begin
  WriteLn('=== 基础操作示例 ===');
  
  LNumbers := TIntegerVecDeque.Create;
  try
    // 添加元素
    WriteLn('添加元素...');
    LNumbers.PushBack(1);
    LNumbers.PushBack(2);
    LNumbers.PushBack(3);
    LNumbers.PushFront(0);
    
    WriteLn('当前元素数量: ', LNumbers.GetCount);
    
    // 访问元素
    WriteLn('第一个元素: ', LNumbers.Front);
    WriteLn('最后一个元素: ', LNumbers.Back);
    
    // 遍历所有元素
    Write('所有元素: ');
    for i := 0 to LNumbers.GetCount - 1 do
      Write(LNumbers.Get(i), ' ');
    WriteLn;
    
    // 移除元素
    WriteLn('移除第一个元素: ', LNumbers.PopFront);
    WriteLn('移除最后一个元素: ', LNumbers.PopBack);
    WriteLn('剩余元素数量: ', LNumbers.GetCount);
    
  finally
    LNumbers.Free;
  end;
  
  WriteLn;
end;

{ 排序示例 }
procedure SortingExample;
var
  LNumbers: TIntegerVecDeque;
  i: Integer;
begin
  WriteLn('=== 排序示例 ===');
  
  LNumbers := TIntegerVecDeque.Create;
  try
    // 添加随机数据
    LNumbers.PushBack(5);
    LNumbers.PushBack(2);
    LNumbers.PushBack(8);
    LNumbers.PushBack(1);
    LNumbers.PushBack(9);
    LNumbers.PushBack(3);
    
    Write('排序前: ');
    for i := 0 to LNumbers.GetCount - 1 do
      Write(LNumbers.Get(i), ' ');
    WriteLn;
    
    // 使用默认排序
    LNumbers.Sort;
    
    Write('排序后: ');
    for i := 0 to LNumbers.GetCount - 1 do
      Write(LNumbers.Get(i), ' ');
    WriteLn;
    
    // 使用特化功能
    WriteLn('总和: ', LNumbers.Sum);
    WriteLn('最小值: ', LNumbers.Min);
    WriteLn('最大值: ', LNumbers.Max);
    WriteLn('平均值: ', LNumbers.Average:0:2);
    
  finally
    LNumbers.Free;
  end;
  
  WriteLn;
end;

{ 字符串操作示例 }
procedure StringExample;
var
  LWords: TStringVecDeque;
  i: Integer;
begin
  WriteLn('=== 字符串操作示例 ===');
  
  LWords := TStringVecDeque.Create;
  try
    // 添加单词
    LWords.PushBack('Hello');
    LWords.PushBack('World');
    LWords.PushBack('FreePascal');
    LWords.PushBack('VecDeque');
    
    Write('原始顺序: ');
    for i := 0 to LWords.GetCount - 1 do
      Write(LWords.Get(i), ' ');
    WriteLn;
    
    // 排序
    LWords.Sort;
    
    Write('排序后: ');
    for i := 0 to LWords.GetCount - 1 do
      Write(LWords.Get(i), ' ');
    WriteLn;
    
    // 连接字符串
    WriteLn('连接结果: ', LWords.Join(' | '));
    
    // 忽略大小写排序
    LWords.Clear;
    LWords.PushBack('apple');
    LWords.PushBack('Banana');
    LWords.PushBack('cherry');
    LWords.PushBack('Date');
    
    WriteLn('忽略大小写排序前: ', LWords.Join(', '));
    LWords.SortIgnoreCase;
    WriteLn('忽略大小写排序后: ', LWords.Join(', '));
    
  finally
    LWords.Free;
  end;
  
  WriteLn;
end;

{ 队列和栈示例 }
procedure QueueStackExample;
var
  LQueue: TIntegerVecDeque;
  LStack: TIntegerVecDeque;
  i: Integer;
begin
  WriteLn('=== 队列和栈示例 ===');
  
  // 作为队列使用 (FIFO)
  WriteLn('作为队列使用 (FIFO):');
  LQueue := TIntegerVecDeque.Create;
  try
    // 入队
    for i := 1 to 5 do
    begin
      LQueue.PushBack(i);
      WriteLn('入队: ', i);
    end;
    
    // 出队
    WriteLn('出队顺序:');
    while not LQueue.IsEmpty do
      WriteLn('出队: ', LQueue.PopFront);
      
  finally
    LQueue.Free;
  end;
  
  WriteLn;
  
  // 作为栈使用 (LIFO)
  WriteLn('作为栈使用 (LIFO):');
  LStack := TIntegerVecDeque.Create;
  try
    // 入栈
    for i := 1 to 5 do
    begin
      LStack.PushBack(i);
      WriteLn('入栈: ', i);
    end;
    
    // 出栈
    WriteLn('出栈顺序:');
    while not LStack.IsEmpty do
      WriteLn('出栈: ', LStack.PopBack);
      
  finally
    LStack.Free;
  end;
  
  WriteLn;
end;

{ 性能示例 }
procedure PerformanceExample;
var
  LDeque: TIntegerVecDeque;
  i: Integer;
  LStartTime, LEndTime: QWord;
const
  TEST_SIZE = 100000;
begin
  WriteLn('=== 性能示例 ===');
  WriteLn('测试规模: ', TEST_SIZE, ' 元素');
  
  LDeque := TIntegerVecDeque.Create;
  try
    // 预留容量以获得最佳性能
    LDeque.Reserve(TEST_SIZE);
    
    // 测试插入性能
    LStartTime := GetTickCount64;
    for i := 1 to TEST_SIZE do
      LDeque.PushBack(i);
    LEndTime := GetTickCount64;
    
    WriteLn('插入 ', TEST_SIZE, ' 元素耗时: ', LEndTime - LStartTime, ' ms');
    WriteLn('插入速度: ', (TEST_SIZE * 1000) div (LEndTime - LStartTime + 1), ' ops/sec');
    
    // 测试访问性能
    LStartTime := GetTickCount64;
    for i := 0 to LDeque.GetCount - 1 do
      LDeque.Get(i);
    LEndTime := GetTickCount64;
    
    WriteLn('访问 ', TEST_SIZE, ' 元素耗时: ', LEndTime - LStartTime, ' ms');
    WriteLn('访问速度: ', (TEST_SIZE * 1000) div (LEndTime - LStartTime + 1), ' ops/sec');
    
    // 测试排序性能
    LStartTime := GetTickCount64;
    LDeque.Sort;
    LEndTime := GetTickCount64;
    
    WriteLn('排序 ', TEST_SIZE, ' 元素耗时: ', LEndTime - LStartTime, ' ms');
    
  finally
    LDeque.Free;
  end;
  
  WriteLn;
end;

{ 内存管理示例 }
procedure MemoryManagementExample;
var
  LDeque: TIntegerVecDeque;
  i: Integer;
begin
  WriteLn('=== 内存管理示例 ===');
  
  LDeque := TIntegerVecDeque.Create;
  try
    WriteLn('初始容量: ', LDeque.GetCapacity);
    WriteLn('初始内存使用: ', LDeque.GetMemoryUsage, ' bytes');
    
    // 预留容量
    LDeque.Reserve(1000);
    WriteLn('预留1000容量后: ', LDeque.GetCapacity);
    WriteLn('内存使用: ', LDeque.GetMemoryUsage, ' bytes');
    
    // 添加一些数据
    for i := 1 to 100 do
      LDeque.PushBack(i);
    
    WriteLn('添加100元素后:');
    WriteLn('  元素数量: ', LDeque.GetCount);
    WriteLn('  容量: ', LDeque.GetCapacity);
    WriteLn('  内存使用: ', LDeque.GetMemoryUsage, ' bytes');
    WriteLn('  利用率: ', (LDeque.GetCount * 100 div LDeque.GetCapacity), '%');
    
    // 收缩内存
    LDeque.ShrinkTo(LDeque.GetCount * 2);
    WriteLn('收缩后:');
    WriteLn('  容量: ', LDeque.GetCapacity);
    WriteLn('  内存使用: ', LDeque.GetMemoryUsage, ' bytes');
    WriteLn('  利用率: ', (LDeque.GetCount * 100 div LDeque.GetCapacity), '%');
    
  finally
    LDeque.Free;
  end;
  
  WriteLn;
end;

{ 主程序 }
begin
  WriteLn('FreePascal VecDeque 基础使用示例');
  WriteLn('================================');
  WriteLn;
  
  try
    BasicOperationsExample;
    SortingExample;
    StringExample;
    QueueStackExample;
    PerformanceExample;
    MemoryManagementExample;
    
    WriteLn('所有示例运行完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  {$IFDEF WINDOWS}
  WriteLn('按任意键退出...');
  ReadLn;
  {$ENDIF}
end.
