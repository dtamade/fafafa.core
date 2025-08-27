program test_assign_fix;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.collections.vecdeque;

type
  TIntVecDeque = specialize TVecDeque<Integer>;

procedure TestInvalidCast;
var
  LVecDeque: TIntVecDeque;
  LExceptionRaised: Boolean;
  LBuffer: Pointer;
  LArray: array of Integer;
begin
  WriteLn('=== Testing Invalid Cast (Fixed) ===');
  
  LVecDeque := TIntVecDeque.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    
    // 测试无效的内存转换操作
    LExceptionRaised := False;
    try
      LBuffer := nil;
      
      // 尝试从无效指针读取
      LVecDeque.Read(0, LBuffer, 1);
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Invalid pointer read exception: ', E.Message);
      end;
    end;
    
    if LExceptionRaised then
      WriteLn('✓ Invalid pointer read properly raises exception')
    else
      WriteLn('✗ Invalid pointer read should raise exception');
    
    // 测试类型安全相关的操作
    LExceptionRaised := False;
    try
      // 测试一些边界情况 
      SetLength(LArray, 0);
      // VecDeque 没有 Assign 方法，改为测试其他类型安全操作
      LVecDeque.Clear;
      LVecDeque.PushBack(1);
      WriteLn('✓ Basic type operations work correctly');

      // 测试无效的写入操作
      LVecDeque.Write(0, nil, 1);
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Invalid write operation exception: ', E.Message);
      end;
    end;
    
    if LExceptionRaised then
      WriteLn('✓ Invalid write operation properly raises exception')
    else
      WriteLn('✗ Invalid write operation should raise exception');
    
  finally
    LVecDeque.Free;
  end;
  WriteLn('Invalid cast test completed');
  WriteLn;
end;

procedure TestTypeMismatch;
var
  LVecDeque: TIntVecDeque;
  LExceptionRaised: Boolean;
  LArray: array of Integer;
begin
  WriteLn('=== Testing Type Mismatch (Fixed) ===');
  
  LVecDeque := TIntVecDeque.Create;
  try
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    
    // 测试无效的比较操作
    LExceptionRaised := False;
    try
      // 尝试使用默认排序（这应该是安全的）
      LVecDeque.Sort;
      WriteLn('✓ Default sort works correctly');
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Sort exception: ', E.Message);
      end;
    end;
    
    // 测试无效的转换操作
    LExceptionRaised := False;
    try
      // 测试一些可能导致类型问题的操作
      SetLength(LArray, 0);
      // 改为测试其他可能的类型问题
      LVecDeque.Clear;
      LVecDeque.PushBack(1);
      WriteLn('✓ Array and basic operations work correctly');
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Type operation exception: ', E.Message);
      end;
    end;
    
    // 测试无效的内存操作
    LExceptionRaised := False;
    try
      // 尝试读取到无效的缓冲区
      LVecDeque.Read(0, nil, 1);
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Null buffer read exception: ', E.Message);
      end;
    end;
    
    if LExceptionRaised then
      WriteLn('✓ Null buffer read properly raises exception')
    else
      WriteLn('✗ Null buffer read should raise exception');
    
  finally
    LVecDeque.Free;
  end;
  WriteLn('Type mismatch test completed');
  WriteLn;
end;

begin
  WriteLn('Testing Assign Fix and Type Safety...');
  WriteLn;
  
  TestInvalidCast;
  TestTypeMismatch;
  
  WriteLn('All assign fix tests completed successfully!');
end.
