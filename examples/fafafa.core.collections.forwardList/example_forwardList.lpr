{$CODEPAGE UTF8}
program example_forwardList;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.base,
  fafafa.core.mem.allocator,
  fafafa.core.collections.base,
  fafafa.core.collections.forwardList;

type
  TIntForwardList = specialize TForwardList<Integer>;
  TStringForwardList = specialize TForwardList<String>;

procedure DemoBasicOperations;
var
  LList: TIntForwardList;
  LValue: Integer;
  LIter: specialize TIter<Integer>;
begin
  WriteLn('=== 基础操作演示 ===');
  
  LList := TIntForwardList.Create;
  try
    // 添加元素到头部
    WriteLn('添加元素到头部...');
    LList.PushFront(3);
    LList.PushFront(2);
    LList.PushFront(1);
    
    WriteLn('链表元素数量: ', LList.Count);
    WriteLn('头部元素: ', LList.Front);
    
    // 遍历链表
    WriteLn('遍历链表:');
    LIter := LList.Iter;
    while LIter.MoveNext do
      WriteLn('  元素: ', LIter.Current);
    
    // 弹出头部元素
    WriteLn('弹出头部元素...');
    while not LList.IsEmpty do
    begin
      LValue := LList.PopFront;
      WriteLn('弹出: ', LValue, ', 剩余: ', LList.Count);
    end;
    
  finally
    LList.Free;
  end;
  
  WriteLn;
end;

procedure DemoInsertAndErase;
var
  LList: TIntForwardList;
  LIter: specialize TIter<Integer>;
  LArray: specialize TGenericArray<Integer>;
  i: Integer;
begin
  WriteLn('=== 插入和删除演示 ===');

  LList := TIntForwardList.Create;
  try
    // 创建初始链表: 1 -> 3
    LList.PushFront(3);
    LList.PushFront(1);

    WriteLn('初始链表: 1 -> 3');

    // 在第一个元素后插入2
    LIter := LList.Iter;
    LIter.MoveNext; // 移动到第一个元素
    LList.InsertAfter(LIter, 2);

    WriteLn('插入2后: 1 -> 2 -> 3');

    // 验证结果
    LArray := LList.ToArray;
    Write('实际结果: ');
    for i := 0 to High(LArray) do
    begin
      Write(LArray[i]);
      if i < High(LArray) then
        Write(' -> ');
    end;
    WriteLn;

    // 测试 EraseAfter
    LIter := LList.Iter;
    LIter.MoveNext; // 移动到第一个元素 (1)
    LList.EraseAfter(LIter); // 删除元素2

    WriteLn('删除第一个元素后的元素后: 1 -> 3');
    LArray := LList.ToArray;
    Write('删除后结果: ');
    for i := 0 to High(LArray) do
    begin
      Write(LArray[i]);
      if i < High(LArray) then
        Write(' -> ');
    end;
    WriteLn;

  finally
    LList.Free;
  end;

  WriteLn;
end;

procedure DemoStringList;
var
  LList: TStringForwardList;
  LIter: specialize TIter<String>;
begin
  WriteLn('=== 字符串链表演示 ===');
  
  LList := TStringForwardList.Create;
  try
    // 添加字符串
    LList.PushFront('World');
    LList.PushFront('Hello');
    
    WriteLn('字符串链表:');
    LIter := LList.Iter;
    while LIter.MoveNext do
      WriteLn('  "', LIter.Current, '"');
    
    // 查找字符串
    LIter := LList.Find('Hello');
    if LIter.MoveNext then
      WriteLn('找到字符串: "', LIter.Current, '"')
    else
      WriteLn('未找到字符串');
    
  finally
    LList.Free;
  end;
  
  WriteLn;
end;

procedure DemoArrayOperations;
var
  LList: TIntForwardList;
  LArray: array[0..4] of Integer = (10, 20, 30, 40, 50);
  LResultArray: specialize TGenericArray<Integer>;
  i: Integer;
begin
  WriteLn('=== 数组操作演示 ===');
  
  LList := TIntForwardList.Create;
  try
    // 从数组加载
    WriteLn('从数组加载: [10, 20, 30, 40, 50]');
    LList.LoadFrom(LArray);
    
    WriteLn('链表元素数量: ', LList.Count);
    
    // 转换为数组
    LResultArray := LList.ToArray;
    Write('转换为数组: [');
    for i := 0 to High(LResultArray) do
    begin
      Write(LResultArray[i]);
      if i < High(LResultArray) then
        Write(', ');
    end;
    WriteLn(']');
    
    // 反转链表
    WriteLn('反转链表...');
    LList.Reverse;
    
    LResultArray := LList.ToArray;
    Write('反转后: [');
    for i := 0 to High(LResultArray) do
    begin
      Write(LResultArray[i]);
      if i < High(LResultArray) then
        Write(', ');
    end;
    WriteLn(']');
    
  finally
    LList.Free;
  end;
  
  WriteLn;
end;

procedure DemoAlgorithms;
var
  LList: TIntForwardList;
  LCount: SizeUInt;
begin
  WriteLn('=== 算法演示 ===');
  
  LList := TIntForwardList.Create;
  try
    // 创建测试数据
    LList.PushFront(2);
    LList.PushFront(1);
    LList.PushFront(2);
    LList.PushFront(3);
    LList.PushFront(2);
    
    WriteLn('测试链表: 2 -> 3 -> 2 -> 1 -> 2');
    
    // 检查是否包含元素
    WriteLn('包含元素2: ', LList.Contains(2));
    WriteLn('包含元素99: ', LList.Contains(99));
    
    // 统计元素
    WriteLn('元素2的数量: ', LList.CountOf(2));
    WriteLn('元素1的数量: ', LList.CountOf(1));
    
    // 移除所有的2
    LCount := LList.Remove(2);
    WriteLn('移除了 ', LCount, ' 个元素2');
    WriteLn('移除后链表元素数量: ', LList.Count);
    
    // 填充链表
    LList.Fill(99);
    WriteLn('填充99后，头部元素: ', LList.Front);
    
  finally
    LList.Free;
  end;
  
  WriteLn;
end;

begin
  WriteLn('fafafa.core.collections.forwardList 示例程序');
  WriteLn('================================================');
  WriteLn;
  
  try
    DemoBasicOperations;
    DemoInsertAndErase;
    DemoStringList;
    DemoArrayOperations;
    DemoAlgorithms;
    
    WriteLn('所有演示完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
