program vecdeque_examples;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.collections.base,
  fafafa.core.collections.vecdeque;

type
  TIntDeque = specialize TVecDeque<Integer>;
  TStringDeque = specialize TVecDeque<String>;

procedure BasicOperationsExample;
var
  Deque: TIntDeque;
  i: Integer;
begin
  WriteLn('=== 基本操作示例 ===');
  
  Deque := TIntDeque.Create;
  try
    // 双端插入
    WriteLn('双端插入操作:');
    Deque.PushFront(10);
    Deque.PushBack(20);
    Deque.PushFront(5);
    Deque.PushBack(25);
    
    Write('当前队列: ');
    for i := 0 to Deque.GetCount - 1 do
      Write(Deque.Get(i), ' ');
    WriteLn;
    
    // 双端弹出
    WriteLn('双端弹出操作:');
    WriteLn('PopFront: ', Deque.PopFront);
    WriteLn('PopBack: ', Deque.PopBack);
    
    Write('剩余队列: ');
    for i := 0 to Deque.GetCount - 1 do
      Write(Deque.Get(i), ' ');
    WriteLn;
    
  finally
    Deque.Free;
  end;
  WriteLn;
end;

procedure BatchOperationsExample;
var
  Deque: TIntDeque;
  Arr: array[0..4] of Integer = (1, 2, 3, 4, 5);
  i: Integer;
begin
  WriteLn('=== 批量操作示例 ===');
  
  Deque := TIntDeque.Create;
  try
    // 批量插入
    WriteLn('批量前端插入 [1,2,3,4,5]:');
    Deque.PushFront(Arr);
    
    Write('结果: ');
    for i := 0 to Deque.GetCount - 1 do
      Write(Deque.Get(i), ' ');
    WriteLn;

    WriteLn('批量后端插入 [10,20,30]:');
    Deque.PushBack([10, 20, 30]);

    Write('结果: ');
    for i := 0 to Deque.GetCount - 1 do
      Write(Deque.Get(i), ' ');
    WriteLn;
    
    // 批量移除
    WriteLn('批量前端移除 2 个元素:');
    Deque.PopFront;
    Deque.PopFront;
    WriteLn('移除了 2 个元素');
    
    Write('结果: ');
    for i := 0 to Deque.GetCount - 1 do
      Write(Deque.Get(i), ' ');
    WriteLn;
    
  finally
    Deque.Free;
  end;
  WriteLn;
end;

procedure CapacityManagementExample;
var
  Deque: TIntDeque;
  i: Integer;
begin
  WriteLn('=== 容量管理示例 ===');
  
  Deque := TIntDeque.Create;
  try
    WriteLn('初始容量: ', Deque.GetCapacity);
    
    // 预留容量
    Deque.Reserve(100);
    WriteLn('预留容量后: ', Deque.GetCapacity);
    
    // 添加一些元素
    for i := 1 to 10 do
      Deque.PushBack(i);
    
    WriteLn('添加10个元素后:');
    WriteLn('  元素数量: ', Deque.GetCount);
    WriteLn('  容量: ', Deque.GetCapacity);
    WriteLn('  负载因子: ', (Deque.GetCount / Deque.GetCapacity):0:2);
    WriteLn('  浪费空间: ', Deque.GetCapacity - Deque.GetCount);
    
    // 收缩到合适大小
    Deque.ShrinkToFit;
    WriteLn('收缩后容量: ', Deque.GetCapacity);
    
  finally
    Deque.Free;
  end;
  WriteLn;
end;

procedure AlgorithmExample;
var
  Deque, Split: TIntDeque;
  i: Integer;
begin
  WriteLn('=== 双端队列算法示例 ===');
  
  Deque := TIntDeque.Create([1, 2, 3, 4, 5, 6]);
  try
    Write('初始队列: ');
    for i := 0 to Deque.GetCount - 1 do
      Write(Deque.Get(i), ' ');
    WriteLn;

    // 插入和移除操作
    WriteLn('在索引 2 处插入元素 99:');
    Deque.Insert(2, 99);
    Write('结果: ');
    for i := 0 to Deque.GetCount - 1 do
      Write(Deque.Get(i), ' ');
    WriteLn;

    // 移除操作
    WriteLn('移除索引 1 的元素:');
    WriteLn('移除的元素: ', Deque.Remove(1));
    Write('结果: ');
    for i := 0 to Deque.GetCount - 1 do
      Write(Deque.Get(i), ' ');
    WriteLn;
    
  finally
    Deque.Free;
  end;
  WriteLn;
end;

procedure SlidingWindowExample;
var
  Data: array[0..9] of Integer = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
  Window: TIntDeque;
  i, j, Sum: Integer;
begin
  WriteLn('=== 滑动窗口示例 (窗口大小=3) ===');
  
  Window := TIntDeque.Create(3);
  try
    for i := 0 to High(Data) do
    begin
      Window.PushBack(Data[i]);
      
      if Window.GetCount > 3 then
        Window.PopFront;
      
      if Window.GetCount = 3 then
      begin
        Sum := 0;
        Write('窗口 [');
        for j := 0 to Window.GetCount - 1 do
        begin
          if j > 0 then Write(', ');
          Write(Window.Get(j));
          Sum := Sum + Window.Get(j);
        end;
        WriteLn('] 平均值: ', Sum / 3:0:1);
      end;
    end;
    
  finally
    Window.Free;
  end;
  WriteLn;
end;

procedure PerformanceDemo;
var
  Deque: TIntDeque;
  StartTime, EndTime: QWord;
  i: Integer;
const
  TEST_SIZE = 100000;
begin
  WriteLn('=== 性能演示 (', TEST_SIZE, ' 次操作) ===');
  
  Deque := TIntDeque.Create;
  try
    // 前端插入性能
    StartTime := GetTickCount64;
    for i := 1 to TEST_SIZE do
      Deque.PushFront(i);
    EndTime := GetTickCount64;
    if EndTime > StartTime then
      WriteLn('前端插入: ', EndTime - StartTime, ' ms, ',
              Round(TEST_SIZE * 1000.0 / (EndTime - StartTime)), ' ops/sec')
    else
      WriteLn('前端插入: < 1 ms, > ', TEST_SIZE * 1000, ' ops/sec');
    
    Deque.Clear;
    
    // 后端插入性能
    StartTime := GetTickCount64;
    for i := 1 to TEST_SIZE do
      Deque.PushBack(i);
    EndTime := GetTickCount64;
    if EndTime > StartTime then
      WriteLn('后端插入: ', EndTime - StartTime, ' ms, ',
              Round(TEST_SIZE * 1000.0 / (EndTime - StartTime)), ' ops/sec')
    else
      WriteLn('后端插入: < 1 ms, > ', TEST_SIZE * 1000, ' ops/sec');
    
    // 随机访问性能
    StartTime := GetTickCount64;
    for i := 1 to TEST_SIZE do
      Deque.Put(i mod Deque.GetCount, i);
    EndTime := GetTickCount64;
    if EndTime > StartTime then
      WriteLn('随机访问: ', EndTime - StartTime, ' ms, ',
              Round(TEST_SIZE * 1000.0 / (EndTime - StartTime)), ' ops/sec')
    else
      WriteLn('随机访问: < 1 ms, > ', TEST_SIZE * 1000, ' ops/sec');
    
  finally
    Deque.Free;
  end;
  WriteLn;
end;

procedure ErrorHandlingExample;
var
  Deque: TIntDeque;
  Value: Integer;
begin
  WriteLn('=== 错误处理示例 ===');
  
  Deque := TIntDeque.Create;
  try
    // 安全的弹出操作
    if Deque.PopFront(Value) then
      WriteLn('弹出值: ', Value)
    else
      WriteLn('队列为空，无法弹出');
    
    // 边界检查
    try
      Value := Deque.Get(100);  // 这会抛出异常
    except
      on E: EOutOfRange do
        WriteLn('捕获异常: ', E.Message);
    end;
    
    // 添加一些元素后再试
    Deque.PushBack(42);
    if Deque.PopFront(Value) then
      WriteLn('成功弹出值: ', Value);
    
  finally
    Deque.Free;
  end;
  WriteLn;
end;

begin
  WriteLn('TVecDeque 使用示例程序');
  WriteLn('========================');
  WriteLn;
  
  BasicOperationsExample;
  BatchOperationsExample;
  CapacityManagementExample;
  AlgorithmExample;
  SlidingWindowExample;
  PerformanceDemo;
  ErrorHandlingExample;
  
  WriteLn('所有示例执行完成！');
  WriteLn('按回车键退出...');
  ReadLn;
end.
