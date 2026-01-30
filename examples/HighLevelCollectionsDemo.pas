program HighLevelCollectionsDemo;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.collections;

type
  // 定义一些测试类型
  TPerson = record
    Name: string;
    Age: Integer;
    constructor Create(const aName: string; aAge: Integer);
  end;

constructor TPerson.Create(const aName: string; aAge: Integer);
begin
  Name := aName;
  Age := aAge;
end;

// 比较函数
function ComparePersonByAge(const aLeft, aRight: TPerson): Integer;
begin
  Result := aLeft.Age - aRight.Age;
end;

// 谓词函数
function IsAdult(const aPerson: TPerson): Boolean;
begin
  Result := aPerson.Age >= 18;
end;

procedure DemonstrateBasicUsage;
var
  LNumbers: specialize IVec<Integer>;
  LPeople: specialize IVec<TPerson>;
  LCache: specialize ILruCache<string, string>;
  i: Integer;
  LPerson: TPerson;
begin
  WriteLn('=== 基本用法演示 ===');
  
  // 1. 极简创建
  LNumbers := specialize Vec<Integer>();
  LPeople := specialize Vec<TPerson>();
  LCache := specialize Cache<string, string>();
  
  // 2. 从数组创建
  LNumbers := specialize Vec<Integer>([1, 2, 3, 4, 5]);
  LPeople := specialize Vec<TPerson>([
    TPerson.Create('Alice', 25),
    TPerson.Create('Bob', 17),
    TPerson.Create('Charlie', 30)
  ]);
  
  // 3. 基本操作
  WriteLn('数字数量: ', LNumbers.Count);
  WriteLn('人员数量: ', LPeople.Count);
  
  // 4. 缓存使用
  LCache.Put('key1', 'value1');
  LCache.Put('key2', 'value2');
  WriteLn('缓存命中: key1 = ', LCache.Get('key1'));
  WriteLn('缓存大小: ', LCache.Count);
  
  WriteLn;
end;

procedure DemonstrateChainedOperations;
var
  LVec: specialize IVec<Integer>;
  LResult: specialize IVec<Integer>;
  LArray: array of Integer;
begin
  WriteLn('=== 链式操作演示 ===');
  
  // 使用链式构建器
  LVec := specialize TVecBuilder<Integer>.Create
    .Add(1)
    .Add(2)
    .Add(3)
    .AddRange([4, 5, 6])
    .Insert(0, 0)  // 在开头插入0
    .RemoveAt(6)   // 移除最后一个元素
    .Build;
  
  WriteLn('构建的向量: ');
  for LArray in LVec do
    Write(LArray, ' ');
  WriteLn;
  
  WriteLn;
end;

procedure DemonstrateFunctionalOperations;
var
  LPeople: specialize IVec<TPerson>;
  LAdults: specialize IVec<TPerson>;
  LPerson: TPerson;
begin
  WriteLn('=== 函数式操作演示 ===');
  
  LPeople := specialize Vec<TPerson>([
    TPerson.Create('Alice', 25),
    TPerson.Create('Bob', 17),
    TPerson.Create('Charlie', 30),
    TPerson.Create('Diana', 16)
  ]);
  
  WriteLn('所有人员:');
  for LPerson in LPeople do
    WriteLn('  ', LPerson.Name, ' (', LPerson.Age, ')');
  
  // 过滤成年人
  // LAdults := specialize Filter<TPerson>(LPeople, @IsAdult);
  // WriteLn('成年人:');
  // for LPerson in LAdults do
  //   WriteLn('  ', LPerson.Name, ' (', LPerson.Age, ')');
  
  // 检查是否所有都是成年人
  // WriteLn('都是成年人: ', specialize All<TPerson>(LPeople, @IsAdult));
  
  // 检查是否有成年人
  // WriteLn('有成年人: ', specialize Any<TPerson>(LPeople, @IsAdult));
  
  WriteLn;
end;

procedure DemonstrateDifferentContainers;
var
  LQueue: specialize IQueue<string>;
  LStack: specialize IStack<string>;
  LMap: specialize IMap<string, Integer>;
  LSet: specialize ISet<Integer>;
  LDeque: specialize IDeque<Integer>;
begin
  WriteLn('=== 不同容器演示 ===');
  
  // 队列 - FIFO
  LQueue := specialize Queue<string>(['first', 'second', 'third']);
  WriteLn('队列出队: ', LQueue.Dequeue);
  WriteLn('队列剩余: ', LQueue.Count);
  
  // 栈 - LIFO
  LStack := specialize Stack<string>(['bottom', 'middle', 'top']);
  WriteLn('栈弹出: ', LStack.Pop);
  WriteLn('栈剩余: ', LStack.Count);
  
  // 映射
  LMap := specialize Map<string, Integer>();
  LMap.Put('apples', 5);
  LMap.Put('oranges', 3);
  WriteLn('苹果数量: ', LMap.Get('apples'));
  
  // 集合
  LSet := specialize Set<Integer>([1, 2, 3, 2, 1]); // 重复会被忽略
  WriteLn('集合大小: ', LSet.Count);
  
  // 双端队列
  LDeque := specialize Deque<Integer>([2, 3, 4]);
  LDeque.PushFront(1);
  LDeque.PushBack(5);
  WriteLn('双端队列前端: ', LDeque.Front);
  WriteLn('双端队列后端: ', LDeque.Back);
  
  WriteLn;
end;

procedure DemonstratePerformanceFeatures;
var
  LVec: specialize IVec<Integer>;
  LCache: specialize ILruCache<string, Integer>;
  i: Integer;
  LStart, LEnd: QWord;
begin
  WriteLn('=== 性能特性演示 ===');
  
  // 大量数据操作
  LStart := GetTickCount64;
  LVec := specialize Vec<Integer>();
  for i := 1 to 100000 do
    LVec.Add(i);
  LEnd := GetTickCount64;
  WriteLn('添加100000个元素耗时: ', LEnd - LStart, 'ms');
  
  // 缓存性能
  LCache := specialize Cache<string, Integer>(1000);
  LStart := GetTickCount64;
  for i := 1 to 10000 do
  begin
    LCache.Put('key' + IntToStr(i), i);
    LCache.Get('key' + IntToStr(i mod 100)); // 模拟缓存命中
  end;
  LEnd := GetTickCount64;
  WriteLn('10000次缓存操作耗时: ', LEnd - LStart, 'ms');
  WriteLn('缓存命中率: ', LCache.HitRate:0:2);
  
  WriteLn;
end;

begin
  try
    WriteLn('fafafa.core.collections 高层次接口演示');
    WriteLn('========================================');
    WriteLn;
    
    DemonstrateBasicUsage;
    DemonstrateChainedOperations;
    DemonstrateFunctionalOperations;
    DemonstrateDifferentContainers;
    DemonstratePerformanceFeatures;
    
    WriteLn('演示完成！');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ReadLn;
    end;
  end;
end.
