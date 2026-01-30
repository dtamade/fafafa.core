program collections_performance_benchmark;

{$codepage utf8}
{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}

{$PUSH}
{$WARN 5023 OFF} // 未使用的 unit
{$WARN 5024 OFF} // 未使用的参数
{$WARN 5025 OFF} // 未使用的局部变量
{$WARN 5028 OFF} // 未使用的局部过程

uses
  SysUtils, Classes,
  {$if defined(WINDOWS) or defined(MSWINDOWS)}Windows,{$endif}
  Math,
  fafafa.core.base,
  fafafa.core.collections,
  fafafa.core.collections.hashmap,
  fafafa.core.collections.vec,
  fafafa.core.collections.vecdeque,
  fafafa.core.collections.list,
  fafafa.core.collections.priorityqueue,
  fafafa.core.benchmark,
  fafafa.core.report.sink.console,
  fafafa.core.report.sink.json;

type
  {**
   * 集合类型性能基准测试套件
   * 测试 HashMap、HashSet、Vec、VecDeque、List、PriorityQueue 的性能
   *}

var
  LSuite: IBenchmarkSuite;
  LReporter: IBenchmarkReporter;
  LConfig: TBenchmarkConfig;

{ ============ HashMap 基准测试 ============ }

procedure BenchmarkHashMapCreate(aState: IBenchmarkState);
var
  LMap: specialize IHashMap<string, Integer>;
begin
  LMap := specialize MakeHashMap<string, Integer>(1000);
  while aState.KeepRunning do
  begin
    LMap.Add('key', 1);
  end;
end;

procedure BenchmarkHashMapInsert(aState: IBenchmarkState);
var
  LMap: specialize IHashMap<Integer, Integer>;
  I: Integer;
begin
  LMap := specialize MakeHashMap<Integer, Integer>(10000);
  I := 0;
  while aState.KeepRunning do
  begin
    LMap.Add(I, I * 2);
    Inc(I);
  end;
end;

procedure BenchmarkHashMapLookup(aState: IBenchmarkState);
var
  LMap: specialize IHashMap<Integer, Integer>;
  I, V: Integer;
begin
  LMap := specialize MakeHashMap<Integer, Integer>(1000);
  for I := 0 to 999 do
    LMap.Add(I, I * 2);

  I := 0;
  while aState.KeepRunning do
  begin
    LMap.TryGetValue(I, V);
    Inc(I);
    if I >= 1000 then I := 0;
  end;
end;

procedure BenchmarkHashMapRemove(aState: IBenchmarkState);
var
  LMap: specialize IHashMap<Integer, Integer>;
  I: Integer;
begin
  LMap := specialize MakeHashMap<Integer, Integer>(1000);
  for I := 0 to 999 do
    LMap.Add(I, I * 2);

  I := 0;
  while aState.KeepRunning do
  begin
    LMap.Remove(I);
    if I >= 999 then
      for I := 0 to 999 do
        LMap.Add(I, I * 2)
    else
      LMap.Add(I, I * 2);
    Inc(I);
  end;
end;

{ ============ Vec 基准测试 ============ }

procedure BenchmarkVecCreate(aState: IBenchmarkState);
var
  LVec: specialize IVec<Integer>;
begin
  LVec := specialize MakeVec<Integer>(1000);
  while aState.KeepRunning do
  begin
    LVec.Add(1);
  end;
end;

procedure BenchmarkVecInsert(aState: IBenchmarkState);
var
  LVec: specialize IVec<Integer>;
  I: Integer;
begin
  LVec := specialize MakeVec<Integer>(0);
  I := 0;
  while aState.KeepRunning do
  begin
    LVec.Add(I);
    Inc(I);
  end;
end;

procedure BenchmarkVecAccess(aState: IBenchmarkState);
var
  LVec: specialize IVec<Integer>;
  I, V: Integer;
begin
  LVec := specialize MakeVec<Integer>(1000);
  for I := 0 to 999 do
    LVec.Add(I * 2);

  I := 0;
  while aState.KeepRunning do
  begin
    V := LVec[I];
    Inc(I);
    if I >= 1000 then I := 0;
  end;
end;

procedure BenchmarkVecPop(aState: IBenchmarkState);
var
  LVec: specialize IVec<Integer>;
  I: Integer;
begin
  while aState.KeepRunning do
  begin
    LVec := specialize MakeVec<Integer>(0);
    for I := 0 to 999 do
      LVec.Add(I);
    for I := 0 to 999 do
      LVec.Pop;
  end;
end;

{ ============ VecDeque 基准测试 ============ }

procedure BenchmarkVecDequePushFront(aState: IBenchmarkState);
var
  LDeque: specialize IDeque<Integer>;
  I: Integer;
begin
  LDeque := specialize MakeVecDeque<Integer>(1000);
  I := 0;
  while aState.KeepRunning do
  begin
    LDeque.PushFront(I);
    Inc(I);
  end;
end;

procedure BenchmarkVecDequePushBack(aState: IBenchmarkState);
var
  LDeque: specialize IDeque<Integer>;
  I: Integer;
begin
  LDeque := specialize MakeVecDeque<Integer>(1000);
  I := 0;
  while aState.KeepRunning do
  begin
    LDeque.PushBack(I);
    Inc(I);
  end;
end;

procedure BenchmarkVecDequePopFront(aState: IBenchmarkState);
var
  LDeque: specialize IDeque<Integer>;
  I: Integer;
begin
  LDeque := specialize MakeVecDeque<Integer>(1000);
  for I := 0 to 999 do
    LDeque.Add(I);

  I := 0;
  while aState.KeepRunning do
  begin
    LDeque.PopFront;
    if I >= 999 then
      for I := 0 to 999 do
        LDeque.Add(I)
    else
      LDeque.Add(I);
    Inc(I);
  end;
end;

{ ============ List 基准测试 ============ }

procedure BenchmarkListPushBack(aState: IBenchmarkState);
var
  LList: specialize IList<Integer>;
  I: Integer;
begin
  LList := specialize MakeList<Integer>;
  I := 0;
  while aState.KeepRunning do
  begin
    LList.Add(I);
    Inc(I);
  end;
end;

procedure BenchmarkListPushFront(aState: IBenchmarkState);
var
  LList: specialize IList<Integer>;
  I: Integer;
begin
  LList := specialize MakeList<Integer>;
  I := 0;
  while aState.KeepRunning do
  begin
    LList.PushFront(I);
    Inc(I);
  end;
end;

{ ============ PriorityQueue 基准测试 ============ }

procedure BenchmarkPriorityQueueEnqueue(aState: IBenchmarkState);
var
  LPQ: TIntPriorityQueue;
  I: Integer;
begin
  LPQ.Initialize(@CompareIntegers, 1000);
  I := 0;
  while aState.KeepRunning do
  begin
    LPQ.Enqueue(I);
    Inc(I);
  end;
end;

procedure BenchmarkPriorityQueueDequeue(aState: IBenchmarkState);
var
  LPQ: TIntPriorityQueue;
  I, V: Integer;
begin
  LPQ.Initialize(@CompareIntegers, 1000);
  for I := 0 to 999 do
    LPQ.Enqueue(I);

  I := 0;
  while aState.KeepRunning do
  begin
    if LPQ.TryPeek(V) then
      LPQ.Dequeue;
    if I >= 999 then
      for I := 0 to 999 do
        LPQ.Enqueue(I)
    else
      LPQ.Enqueue(I);
    Inc(I);
  end;
end;

{ ============ 整数比较函数 ============ }

function CompareIntegers(const A, B: Integer): Integer;
begin
  if A < B then
    Result := -1
  else if A > B then
    Result := 1
  else
    Result := 0;
end;

var
  I: Integer;
  LStr: string;
begin
  WriteLn('===========================================');
  WriteLn('fafafa.core.collections 性能基准测试');
  WriteLn('===========================================');
  WriteLn;

  { 创建套件和报告器 }
  LSuite := CreateBenchmarkSuite;
  LReporter := CreateConsoleReporter;
  LConfig := CreateDefaultBenchmarkConfig;

  { 设置默认参数 }
  LConfig.Iterations := 1000;
  LConfig.WarmupIterations := 100;
  LConfig.TimeoutMs := 30000;

  { 解析命令行参数 }
  for I := 1 to ParamCount do
  begin
    LStr := ParamStr(I);
    if Pos('--report=json', LStr) = 1 then
    begin
      // 创建 JSON 报告器
      LReporter := CreateJSONReporter('benchmarks/fafafa.core.collections/performance_report.json');
    end;
  end;

  WriteLn('运行 HashMap 基准测试...');
  LSuite.AddFunction('HashMap_Creat1000', @BenchmarkHashMapCreate, LConfig);
  LSuite.AddFunction('HashMap_Insert_10000', @BenchmarkHashMapInsert, LConfig);
  LSuite.AddFunction('HashMap_Lookup_1000', @BenchmarkHashMapLookup, LConfig);
  LSuite.AddFunction('HashMap_Remove_1000', @BenchmarkHashMapRemove, LConfig);

  WriteLn('运行 Vec 基准测试...');
  LSuite.AddFunction('Vec_Create_1000', @BenchmarkVecCreate, LConfig);
  LSuite.AddFunction('Vec_Insert_10000', @BenchmarkVecInsert, LConfig);
  LSuite.AddFunction('Vec_Access_1000', @BenchmarkVecAccess, LConfig);
  LSuite.AddFunction('Vec_Pop_1000', @BenchmarkVecPop, LConfig);

  WriteLn('运行 VecDeque 基准测试...');
  LSuite.AddFunction('VecDeque_PushFront_10000', @BenchmarkVecDequePushFront, LConfig);
  LSuite.AddFunction('VecDeque_PushBack_10000', @BenchmarkVecDequePushBack, LConfig);
  LSuite.AddFunction('VecDeque_PopFront_1000', @BenchmarkVecDequePopFront, LConfig);

  WriteLn('运行 List 基准测试...');
  LSuite.AddFunction('List_PushBack_10000', @BenchmarkListPushBack, LConfig);
  LSuite.AddFunction('List_PushFront_10000', @BenchmarkListPushFront, LConfig);

  WriteLn('运行 PriorityQueue 基准测试...');
  LSuite.AddFunction('PriorityQueue_Enqueue_10000', @BenchmarkPriorityQueueEnqueue, LConfig);
  LSuite.AddFunction('PriorityQueue_Dequeue_1000', @BenchmarkPriorityQueueDequeue, LConfig);

  WriteLn;
  WriteLn('开始执行基准测试...');
  WriteLn('===========================================');

  { 运行所有测试 }
  LSuite.RunAllWithReporter(LReporter);

  WriteLn('===========================================');
  WriteLn('基准测试完成！');
  WriteLn('报告已生成到：benchmarks/fafafa.core.collections/');
  WriteLn('===========================================');
end.
