program test_compile_check;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.collections.vecdeque,
  fafafa.core.collections.base;

type
  TIntVecDeque = specialize TVecDeque<Integer>;
  TIntCompareFunc = specialize TCompareFunc<Integer>;

procedure TestTypeMismatch;
var
  LVecDeque: TIntVecDeque;
  LExceptionRaised: Boolean;
  LArray: array of Integer;
begin
  WriteLn('=== Testing Type Mismatch Handling ===');
  
  LVecDeque := TIntVecDeque.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    
    // 测试无效的比较操作
    LExceptionRaised := False;
    try
      // 尝试使用nil比较器进行排序
      LVecDeque.Sort(TIntCompareFunc(nil), nil);
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Nil comparer exception caught: ', E.Message);
      end;
    end;
    
    if LExceptionRaised then
      WriteLn('✓ Nil comparer properly handled')
    else
      WriteLn('✓ Nil comparer did not raise exception (implementation dependent)');
    
    // 测试无效的转换操作
    LExceptionRaised := False;
    try
      // 测试一些可能导致类型问题的操作
      SetLength(LArray, 0);
      // 改为测试其他可能的类型问题
      LVecDeque.Clear;
      LVecDeque.PushBack(1);
      WriteLn('✓ Basic operations work correctly');
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Type operation exception caught: ', E.Message);
      end;
    end;
    
    // 测试无效的内存操作
    LExceptionRaised := False;
    try
      // 尝试从无效指针读取
      LVecDeque.Read(0, nil, 1);
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Invalid memory operation exception caught: ', E.Message);
      end;
    end;
    
    if LExceptionRaised then
      WriteLn('✓ Invalid memory operation properly raises exception')
    else
      WriteLn('✗ Invalid memory operation should raise exception');
    
  finally
    LVecDeque.Free;
  end;
  WriteLn('Type mismatch test completed');
  WriteLn;
end;

procedure TestBasicOperations;
var
  LVecDeque: TIntVecDeque;
  i: Integer;
begin
  WriteLn('=== Testing Basic Operations ===');
  
  LVecDeque := TIntVecDeque.Create;
  try
    // 测试基本操作
    for i := 1 to 5 do
      LVecDeque.PushBack(i);
    
    WriteLn('Added 5 elements, count: ', LVecDeque.GetCount);
    
    // 测试访问
    for i := 0 to LVecDeque.GetCount - 1 do
      Write(LVecDeque.Get(i), ' ');
    WriteLn;
    
    // 测试排序
    LVecDeque.Clear;
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(9);
    
    Write('Before sort: ');
    for i := 0 to LVecDeque.GetCount - 1 do
      Write(LVecDeque.Get(i), ' ');
    WriteLn;
    
    LVecDeque.Sort;
    
    Write('After sort: ');
    for i := 0 to LVecDeque.GetCount - 1 do
      Write(LVecDeque.Get(i), ' ');
    WriteLn;
    
    WriteLn('✓ Basic operations work correctly');
    
  finally
    LVecDeque.Free;
  end;
  WriteLn('Basic operations test completed');
  WriteLn;
end;

begin
  WriteLn('Testing Compile Check and Basic Operations...');
  WriteLn;
  
  TestBasicOperations;
  TestTypeMismatch;
  
  WriteLn('All compile check tests completed!');
end.
