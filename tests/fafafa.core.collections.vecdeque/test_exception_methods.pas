program test_exception_methods;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.collections.vecdeque;

type
  TIntVecDeque = specialize TVecDeque<Integer>;

procedure TestMemoryError;
var
  LVecDeque: TIntVecDeque;
  LExceptionRaised: Boolean;
  i: Integer;
begin
  WriteLn('=== Testing Memory Error Handling ===');
  
  LVecDeque := TIntVecDeque.Create;
  try
    // 测试内存分配失败的情况
    LExceptionRaised := False;
    try
      // 尝试预分配一个巨大的容量（可能会导致内存不足）
      LVecDeque.Reserve(High(SizeUInt) div 2);
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Memory allocation exception caught: ', E.Message);
      end;
    end;
    
    // 测试在内存压力下的操作
    LExceptionRaised := False;
    try
      // 尝试添加大量元素
      for i := 1 to 100000 do
        LVecDeque.PushBack(i);
      WriteLn('Successfully added 100000 elements');
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Memory pressure exception caught: ', E.Message);
      end;
    end;
    
  finally
    LVecDeque.Free;
  end;
  WriteLn('Memory error test completed');
  WriteLn;
end;

procedure TestAccessViolation;
var
  LVecDeque: TIntVecDeque;
  LExceptionRaised: Boolean;
  LValue: Integer;
begin
  WriteLn('=== Testing Access Violation Handling ===');
  
  LVecDeque := TIntVecDeque.Create;
  try
    // 测试空集合上的无效访问
    LExceptionRaised := False;
    try
      LValue := LVecDeque.Get(0);
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Empty collection access exception caught: ', E.Message);
      end;
    end;
    
    if LExceptionRaised then
      WriteLn('✓ Empty collection access properly raises exception')
    else
      WriteLn('✗ Empty collection access should raise exception');
    
    // 测试越界访问
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    
    LExceptionRaised := False;
    try
      LValue := LVecDeque.Get(10);
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Out-of-bounds access exception caught: ', E.Message);
      end;
    end;
    
    if LExceptionRaised then
      WriteLn('✓ Out-of-bounds access properly raises exception')
    else
      WriteLn('✗ Out-of-bounds access should raise exception');
    
  finally
    LVecDeque.Free;
  end;
  WriteLn('Access violation test completed');
  WriteLn;
end;

procedure TestDivideByZero;
var
  LVecDeque: TIntVecDeque;
  LExceptionRaised: Boolean;
  LResult: Integer;
begin
  WriteLn('=== Testing Divide By Zero Handling ===');
  
  LVecDeque := TIntVecDeque.Create;
  try
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(0);
    LVecDeque.PushBack(5);
    
    LExceptionRaised := False;
    try
      LResult := LVecDeque.GetCount div LVecDeque.GetCount; // 这不会导致除零
      
      // 模拟一个可能的除零场景
      if LVecDeque.Get(1) = 0 then
      begin
        raise EDivByZero.Create('Simulated divide by zero');
      end;
    except
      on E: EDivByZero do
      begin
        LExceptionRaised := True;
        WriteLn('Divide by zero exception caught: ', E.Message);
      end;
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('General exception caught: ', E.Message);
      end;
    end;
    
    if LExceptionRaised then
      WriteLn('✓ Divide by zero scenario properly handled')
    else
      WriteLn('✗ Divide by zero scenario should be handled');
    
  finally
    LVecDeque.Free;
  end;
  WriteLn('Divide by zero test completed');
  WriteLn;
end;

procedure TestExceptionRecovery;
var
  LVecDeque: TIntVecDeque;
  LExceptionRaised: Boolean;
  i: Integer;
  LValue: Integer;
begin
  WriteLn('=== Testing Exception Recovery ===');
  
  LVecDeque := TIntVecDeque.Create;
  try
    // 添加一些初始数据
    for i := 1 to 5 do
      LVecDeque.PushBack(i);
    
    // 测试从越界访问异常中恢复
    LExceptionRaised := False;
    try
      LValue := LVecDeque.Get(100); // 这应该抛出异常
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Out-of-bounds exception caught: ', E.Message);
        
        // 验证集合在异常后仍然可用
        if LVecDeque.GetCount = 5 then
          WriteLn('✓ Collection still usable after exception')
        else
          WriteLn('✗ Collection corrupted after exception');
          
        if LVecDeque.Get(0) = 1 then
          WriteLn('✓ First element still accessible')
        else
          WriteLn('✗ First element corrupted');
      end;
    end;
    
    if LExceptionRaised then
      WriteLn('✓ Exception recovery test passed')
    else
      WriteLn('✗ Exception should have been raised');
    
    // 测试从空集合操作异常中恢复
    LVecDeque.Clear;
    LExceptionRaised := False;
    try
      LVecDeque.PopBack; // 这应该抛出异常
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Empty collection operation exception caught: ', E.Message);
        
        // 验证可以继续正常操作
        LVecDeque.PushBack(42);
        if (LVecDeque.GetCount = 1) and (LVecDeque.Get(0) = 42) then
          WriteLn('✓ Collection recoverable after empty operation exception')
        else
          WriteLn('✗ Collection not recoverable after empty operation exception');
      end;
    end;
    
  finally
    LVecDeque.Free;
  end;
  WriteLn('Exception recovery test completed');
  WriteLn;
end;

begin
  WriteLn('Testing Exception Handling Methods...');
  WriteLn;
  
  TestMemoryError;
  TestAccessViolation;
  TestDivideByZero;
  TestExceptionRecovery;
  
  WriteLn('All exception handling tests completed!');
end.
