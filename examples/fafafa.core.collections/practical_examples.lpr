{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
program practical_examples;

uses
  fafafa.core.collections,
  fafafa.core.collections.vec,
  fafafa.core.collections.vecdeque,
  fafafa.core.collections.hashmap;

// ============================================================================
// 示例 1: 简单的任务队列
// ============================================================================
procedure Example_TaskQueue;
var
  Queue: specialize IDeque<string>;
begin
  WriteLn('=== 示例 1: 任务队列 ===');
  
  Queue := specialize MakeVecDeque<string>();
  
  // 添加任务
  Queue.PushBack('发送邮件');
  Queue.PushBack('生成报告');
  Queue.PushBack('备份数据');
  
  WriteLn('待处理任务数: ', Queue.GetCount);
  
  // 处理任务
  while not Queue.IsEmpty do
  begin
    WriteLn('正在处理: ', Queue.PopFront);
  end;
  
  WriteLn('所有任务已完成');
  WriteLn;
end;

// ============================================================================
// 示例 2: 栈式撤销功能
// ============================================================================
procedure Example_UndoStack;
type
  TAction = record
    Name: string;
    Timestamp: TDateTime;
  end;
var
  UndoStack: specialize IVec<TAction>;
  Action: TAction;
  i: Integer;
begin
  WriteLn('=== 示例 2: 撤销栈 ===');
  
  UndoStack := specialize MakeVec<TAction>();
  
  // 执行操作
  Action.Name := '插入文本';
  Action.Timestamp := Now;
  UndoStack.Add(Action);
  
  Action.Name := '删除文本';
  Action.Timestamp := Now;
  UndoStack.Add(Action);
  
  Action.Name := '格式化';
  Action.Timestamp := Now;
  UndoStack.Add(Action);
  
  WriteLn('操作历史:');
  for i := 0 to UndoStack.GetCount - 1 do
    WriteLn('  ', i + 1, '. ', UndoStack.Get(i).Name);
  
  // 撤销最后两个操作
  WriteLn('撤销: ', UndoStack.Get(UndoStack.GetCount - 1).Name);
  UndoStack.Remove(UndoStack.GetCount - 1);
  
  WriteLn('撤销: ', UndoStack.Get(UndoStack.GetCount - 1).Name);
  UndoStack.Remove(UndoStack.GetCount - 1);
  
  WriteLn('剩余操作: ', UndoStack.GetCount);
  WriteLn;
end;

// ============================================================================
// 示例 3: 滑动窗口统计
// ============================================================================
procedure Example_SlidingWindow;
const
  WINDOW_SIZE = 5;
var
  Window: specialize IDeque<Integer>;
  i, Sum: Integer;
  Avg: Double;
begin
  WriteLn('=== 示例 3: 滑动窗口平均值 ===');
  
  Window := specialize MakeVecDeque<Integer>();
  
  WriteLn('计算最近 ', WINDOW_SIZE, ' 个数的平均值:');
  
  for i := 1 to 10 do
  begin
    // 添加新值
    Window.PushBack(i * 10);
    
    // 保持窗口大小
    if Window.GetCount > WINDOW_SIZE then
      Window.PopFront;
    
    // 计算平均值
    Sum := 0;
    for var j := 0 to Window.GetCount - 1 do
      Sum := Sum + Window.Get(j);
    
    Avg := Sum / Window.GetCount;
    WriteLn('  值: ', i * 10:3, ' | 窗口平均: ', Avg:6:2);
  end;
  
  WriteLn;
end;

// ============================================================================
// 示例 4: 简单缓存实现
// ============================================================================
procedure Example_SimpleCache;
type
  TCacheEntry = record
    Value: string;
    HitCount: Integer;
  end;
var
  Cache: specialize IHashMap<string, TCacheEntry>;
  Entry: TCacheEntry;
  Key: string;
begin
  WriteLn('=== 示例 4: 简单缓存 ===');
  
  Cache := specialize MakeHashMap<string, TCacheEntry>();
  
  // 初始化缓存
  Entry.Value := '用户数据'; Entry.HitCount := 0;
  Cache.Insert('user:1', Entry);
  
  Entry.Value := '产品列表'; Entry.HitCount := 0;
  Cache.Insert('products', Entry);
  
  // 模拟访问
  Key := 'user:1';
  if Cache.TryGet(Key, Entry) then
  begin
    Inc(Entry.HitCount);
    Cache.InsertOrAssign(Key, Entry);
    WriteLn('缓存命中: ', Key, ' (', Entry.Value, ') - 访问次数: ', Entry.HitCount);
  end;
  
  // 再次访问
  if Cache.TryGet(Key, Entry) then
  begin
    Inc(Entry.HitCount);
    Cache.InsertOrAssign(Key, Entry);
    WriteLn('缓存命中: ', Key, ' (', Entry.Value, ') - 访问次数: ', Entry.HitCount);
  end;
  
  WriteLn('缓存总数: ', Cache.GetCount);
  WriteLn;
end;

// ============================================================================
// 示例 5: 批量数据处理
// ============================================================================
procedure Example_BatchProcessing;
var
  Data: specialize IVec<Integer>;
  Batch: array[0..99] of Integer;
  i, Sum: Integer;
begin
  WriteLn('=== 示例 5: 批量数据处理 ===');
  
  Data := specialize MakeVec<Integer>(1000);  // 预分配
  
  // 生成批量数据
  for i := Low(Batch) to High(Batch) do
    Batch[i] := i + 1;
  
  // 批量添加（高效）
  Data.Append(Batch);
  
  WriteLn('已加载 ', Data.GetCount, ' 个数据');
  
  // 批量计算
  Sum := 0;
  for i := 0 to Data.GetCount - 1 do
    Sum := Sum + Data.GetUnChecked(i);  // 跳过边界检查
  
  WriteLn('数据总和: ', Sum);
  WriteLn('数据平均: ', Sum / Data.GetCount:0:2);
  WriteLn;
end;

// ============================================================================
// 示例 6: 数据去重
// ============================================================================
procedure Example_Deduplication;
var
  Original: specialize IVec<Integer>;
  Unique: specialize IVec<Integer>;
  Seen: specialize IHashMap<Integer, Boolean>;
  i, Value: Integer;
begin
  WriteLn('=== 示例 6: 数据去重 ===');
  
  Original := specialize MakeVec<Integer>();
  Unique := specialize MakeVec<Integer>();
  Seen := specialize MakeHashMap<Integer, Boolean>();
  
  // 原始数据（有重复）
  Original.Append([1, 2, 3, 2, 4, 1, 5, 3]);
  
  WriteLn('原始数据: ', Original.GetCount, ' 个元素');
  
  // 去重
  for i := 0 to Original.GetCount - 1 do
  begin
    Value := Original.Get(i);
    if not Seen.Contains(Value) then
    begin
      Unique.Add(Value);
      Seen.Insert(Value, True);
    end;
  end;
  
  WriteLn('去重后: ', Unique.GetCount, ' 个唯一元素');
  Write('唯一值: ');
  for i := 0 to Unique.GetCount - 1 do
    Write(Unique.Get(i), ' ');
  WriteLn;
  WriteLn;
end;

// ============================================================================
// 示例 7: Top-K 查找
// ============================================================================
procedure Example_TopK;
var
  Data: specialize IVec<Integer>;
  TopK: specialize IVec<Integer>;
  i, K: Integer;
begin
  WriteLn('=== 示例 7: 查找最大的 K 个元素 ===');
  
  Data := specialize MakeVec<Integer>();
  TopK := specialize MakeVec<Integer>();
  
  // 生成随机数据
  Data.Append([45, 23, 78, 12, 67, 89, 34, 56, 90, 11]);
  K := 3;
  
  WriteLn('查找最大的 ', K, ' 个元素:');
  
  // 简单实现：排序后取前 K 个
  Data.Sort;  // 升序
  Data.Reverse;  // 降序
  
  for i := 0 to K - 1 do
    TopK.Add(Data.Get(i));
  
  Write('Top ', K, ': ');
  for i := 0 to TopK.GetCount - 1 do
    Write(TopK.Get(i), ' ');
  WriteLn;
  WriteLn;
end;

// ============================================================================
// 主程序
// ============================================================================
begin
  WriteLn;
  WriteLn('==================================================');
  WriteLn('  fafafa.core.collections 实用示例集');
  WriteLn('==================================================');
  WriteLn;
  
  Example_TaskQueue;
  Example_UndoStack;
  Example_SlidingWindow;
  Example_SimpleCache;
  Example_BatchProcessing;
  Example_Deduplication;
  Example_TopK;
  
  WriteLn('==================================================');
  WriteLn('  所有示例运行完成！');
  WriteLn('==================================================');
  WriteLn;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
