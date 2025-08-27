program simple_test_runner;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.mem.allocator,
  fafafa.core.collections.base,
  fafafa.core.collections.queue,
  fafafa.core.collections.deque,
  fafafa.core.collections.arr,
  fafafa.core.collections.vec,
  fafafa.core.collections.vecdeque;

type
  TIntegerVecDeque = specialize TVecDeque<Integer>;
  TStringVecDeque = specialize TVecDeque<String>;

var
  GTestCount: Integer = 0;
  GPassCount: Integer = 0;
  GFailCount: Integer = 0;

procedure AssertEquals(const AMessage: String; AExpected, AActual: Integer);
begin
  Inc(GTestCount);
  if AExpected = AActual then
  begin
    Inc(GPassCount);
    WriteLn('✓ ', AMessage);
  end
  else
  begin
    Inc(GFailCount);
    WriteLn('✗ ', AMessage, ' - Expected: ', AExpected, ', Actual: ', AActual);
  end;
end;

procedure AssertEquals(const AMessage: String; AExpected, AActual: Int64);
begin
  Inc(GTestCount);
  if AExpected = AActual then
  begin
    Inc(GPassCount);
    WriteLn('✓ ', AMessage);
  end
  else
  begin
    Inc(GFailCount);
    WriteLn('✗ ', AMessage, ' - Expected: ', AExpected, ', Actual: ', AActual);
  end;
end;

procedure AssertEquals(const AMessage: String; AExpected, AActual: String);
begin
  Inc(GTestCount);
  if AExpected = AActual then
  begin
    Inc(GPassCount);
    WriteLn('✓ ', AMessage);
  end
  else
  begin
    Inc(GFailCount);
    WriteLn('✗ ', AMessage, ' - Expected: "', AExpected, '", Actual: "', AActual, '"');
  end;
end;

procedure AssertTrue(const AMessage: String; ACondition: Boolean);
begin
  Inc(GTestCount);
  if ACondition then
  begin
    Inc(GPassCount);
    WriteLn('✓ ', AMessage);
  end
  else
  begin
    Inc(GFailCount);
    WriteLn('✗ ', AMessage, ' - Expected: True, Actual: False');
  end;
end;

procedure AssertFalse(const AMessage: String; ACondition: Boolean);
begin
  Inc(GTestCount);
  if not ACondition then
  begin
    Inc(GPassCount);
    WriteLn('✓ ', AMessage);
  end
  else
  begin
    Inc(GFailCount);
    WriteLn('✗ ', AMessage, ' - Expected: False, Actual: True');
  end;
end;

procedure AssertNotNull(const AMessage: String; APointer: Pointer);
begin
  Inc(GTestCount);
  if APointer <> nil then
  begin
    Inc(GPassCount);
    WriteLn('✓ ', AMessage);
  end
  else
  begin
    Inc(GFailCount);
    WriteLn('✗ ', AMessage, ' - Expected: Not Nil, Actual: Nil');
  end;
end;

procedure Fail(const AMessage: String);
begin
  Inc(GTestCount);
  Inc(GFailCount);
  WriteLn('✗ ', AMessage);
  raise Exception.Create(AMessage);
end;

{ ===== 基础功能测试 ===== }

procedure Test_BasicOperations;
var
  LVecDeque: TIntegerVecDeque;
begin
  WriteLn('=== 测试基础操作 ===');
  
  LVecDeque := TIntegerVecDeque.Create;
  try
    { 测试空队列 }
    AssertTrue('新创建的VecDeque应该为空', LVecDeque.IsEmpty);
    AssertEquals('空VecDeque计数应为0', Int64(0), Int64(LVecDeque.GetCount));
    
    { 测试 PushBack }
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(30);
    
    AssertEquals('PushBack后计数应为3', Int64(3), Int64(LVecDeque.GetCount));
    AssertFalse('PushBack后不应为空', LVecDeque.IsEmpty);
    
    { 测试 PushFront }
    LVecDeque.PushFront(5);
    
    AssertEquals('PushFront后计数应为4', Int64(4), Int64(LVecDeque.GetCount));
    AssertEquals('Front应为最后PushFront的元素', 5, LVecDeque.Front);
    AssertEquals('Back应为最后PushBack的元素', 30, LVecDeque.Back);
    
    { 测试 PopFront }
    AssertEquals('PopFront应返回前端元素', 5, LVecDeque.PopFront);
    AssertEquals('PopFront后计数应减1', Int64(3), Int64(LVecDeque.GetCount));
    
    { 测试 PopBack }
    AssertEquals('PopBack应返回后端元素', 30, LVecDeque.PopBack);
    AssertEquals('PopBack后计数应减1', Int64(2), Int64(LVecDeque.GetCount));
    
    { 测试 Clear }
    LVecDeque.Clear;
    AssertTrue('Clear后应为空', LVecDeque.IsEmpty);
    AssertEquals('Clear后计数应为0', Int64(0), Int64(LVecDeque.GetCount));
    
  finally
    LVecDeque.Free;
  end;
end;

procedure Test_ArrayOperations;
var
  LVecDeque: TIntegerVecDeque;
  LArray: array[0..2] of Integer;
  i: Integer;
begin
  WriteLn('=== 测试数组操作 ===');
  
  LVecDeque := TIntegerVecDeque.Create;
  try
    { 准备测试数组 }
    LArray[0] := 100;
    LArray[1] := 200;
    LArray[2] := 300;
    
    { 测试 PushBack 数组 }
    LVecDeque.PushBack(LArray);
    
    AssertEquals('PushBack数组后计数应为3', Int64(3), Int64(LVecDeque.GetCount));
    for i := 0 to 2 do
      AssertEquals('数组元素应正确', LArray[i], LVecDeque.Get(i));
    
    { 测试 PushFront 数组 }
    LArray[0] := 50;
    LArray[1] := 60;
    LArray[2] := 70;
    
    LVecDeque.PushFront(LArray);
    
    AssertEquals('PushFront数组后计数应为6', Int64(6), Int64(LVecDeque.GetCount));
    for i := 0 to 2 do
      AssertEquals('前端数组元素应正确', LArray[i], LVecDeque.Get(i));
    
  finally
    LVecDeque.Free;
  end;
end;

procedure Test_SafeOperations;
var
  LVecDeque: TIntegerVecDeque;
  LElement: Integer;
  LResult: Boolean;
begin
  WriteLn('=== 测试安全操作 ===');
  
  LVecDeque := TIntegerVecDeque.Create;
  try
    { 测试空队列的安全操作 }
    LElement := 999;
    LResult := LVecDeque.PopFront(LElement);
    
    AssertFalse('空队列PopFront应返回False', LResult);
    AssertEquals('空队列PopFront不应修改元素', 999, LElement);
    
    LResult := LVecDeque.PopBack(LElement);
    AssertFalse('空队列PopBack应返回False', LResult);
    AssertEquals('空队列PopBack不应修改元素', 999, LElement);
    
    { 添加元素后测试安全操作 }
    LVecDeque.PushBack(42);
    LVecDeque.PushBack(84);
    
    LResult := LVecDeque.PopFront(LElement);
    AssertTrue('非空队列PopFront应返回True', LResult);
    AssertEquals('PopFront应返回正确元素', 42, LElement);
    
    LResult := LVecDeque.PopBack(LElement);
    AssertTrue('非空队列PopBack应返回True', LResult);
    AssertEquals('PopBack应返回正确元素', 84, LElement);
    
  finally
    LVecDeque.Free;
  end;
end;

procedure Test_StringOperations;
var
  LVecDeque: TStringVecDeque;
begin
  WriteLn('=== 测试字符串操作 ===');
  
  LVecDeque := TStringVecDeque.Create;
  try
    { 测试字符串操作 }
    LVecDeque.PushBack('Hello');
    LVecDeque.PushBack('World');
    LVecDeque.PushFront('Start');
    
    AssertEquals('字符串计数应为3', Int64(3), Int64(LVecDeque.GetCount));
    AssertEquals('前端字符串应正确', 'Start', LVecDeque.Front);
    AssertEquals('后端字符串应正确', 'World', LVecDeque.Back);
    AssertEquals('中间字符串应正确', 'Hello', LVecDeque.Get(1));
    
    { 测试空字符串 }
    LVecDeque.PushBack('');
    AssertEquals('空字符串应正确存储', '', LVecDeque.Back);
    
  finally
    LVecDeque.Free;
  end;
end;

procedure RunAllTests;
begin
  WriteLn('开始运行 VecDeque 测试...');
  WriteLn;
  
  try
    Test_BasicOperations;
    WriteLn;
    
    Test_ArrayOperations;
    WriteLn;
    
    Test_SafeOperations;
    WriteLn;
    
    Test_StringOperations;
    WriteLn;
    
  except
    on E: Exception do
    begin
      WriteLn('测试过程中发生异常: ', E.Message);
      Inc(GFailCount);
    end;
  end;
  
  WriteLn('=== 测试结果 ===');
  WriteLn('总测试数: ', GTestCount);
  WriteLn('通过: ', GPassCount);
  WriteLn('失败: ', GFailCount);
  
  if GFailCount = 0 then
    WriteLn('所有测试通过！')
  else
    WriteLn('有 ', GFailCount, ' 个测试失败。');
end;

begin
  RunAllTests;
end.
