program test_simple_exceptions;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.collections.vecdeque;

type
  TIntVecDeque = specialize TVecDeque<Integer>;

procedure TestAccessViolation;
var
  LVecDeque: TIntVecDeque;
  LExceptionRaised: Boolean;
  LValue: Integer;
begin
  WriteLn('=== Testing Access Violation ===');
  
  LVecDeque := TIntVecDeque.Create;
  try
    // 测试空集合访问
    LExceptionRaised := False;
    try
      LValue := LVecDeque.Get(0);
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Empty access exception: ', E.Message);
      end;
    end;
    
    if LExceptionRaised then
      WriteLn('✓ Empty collection access properly raises exception')
    else
      WriteLn('✗ Empty collection access should raise exception');
    
    // 添加一些元素
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    
    // 测试越界访问
    LExceptionRaised := False;
    try
      LValue := LVecDeque.Get(10);
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Out-of-bounds exception: ', E.Message);
      end;
    end;
    
    if LExceptionRaised then
      WriteLn('✓ Out-of-bounds access properly raises exception')
    else
      WriteLn('✗ Out-of-bounds access should raise exception');
    
  finally
    LVecDeque.Free;
  end;
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
    // 添加初始数据
    for i := 1 to 5 do
      LVecDeque.PushBack(i);
    
    // 测试异常后恢复
    LExceptionRaised := False;
    try
      LValue := LVecDeque.Get(100);
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Exception caught: ', E.Message);
        
        // 验证集合仍然可用
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
    
    // 测试空集合操作异常恢复
    LVecDeque.Clear;
    LExceptionRaised := False;
    try
      LVecDeque.PopBack;
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Empty operation exception: ', E.Message);
        
        // 验证可以继续操作
        LVecDeque.PushBack(42);
        if (LVecDeque.GetCount = 1) and (LVecDeque.Get(0) = 42) then
          WriteLn('✓ Collection recoverable after empty operation exception')
        else
          WriteLn('✗ Collection not recoverable');
      end;
    end;
    
  finally
    LVecDeque.Free;
  end;
  WriteLn;
end;

procedure TestMemoryOperations;
var
  LVecDeque: TIntVecDeque;
  LExceptionRaised: Boolean;
  i: Integer;
begin
  WriteLn('=== Testing Memory Operations ===');
  
  LVecDeque := TIntVecDeque.Create;
  try
    // 测试无效内存操作
    LExceptionRaised := False;
    try
      LVecDeque.Read(0, nil, 1);
    except
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('Invalid memory operation exception: ', E.Message);
      end;
    end;
    
    if LExceptionRaised then
      WriteLn('✓ Invalid memory operation properly raises exception')
    else
      WriteLn('✗ Invalid memory operation should raise exception');
    
    // 测试大量元素添加
    try
      for i := 1 to 10000 do
        LVecDeque.PushBack(i);
      WriteLn('✓ Successfully added 10000 elements');
    except
      on E: Exception do
        WriteLn('Memory pressure exception: ', E.Message);
    end;
    
  finally
    LVecDeque.Free;
  end;
  WriteLn;
end;

procedure TestDivideByZeroSimulation;
var
  LVecDeque: TIntVecDeque;
  LExceptionRaised: Boolean;
begin
  WriteLn('=== Testing Divide By Zero Simulation ===');
  
  LVecDeque := TIntVecDeque.Create;
  try
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(0);
    LVecDeque.PushBack(5);
    
    LExceptionRaised := False;
    try
      // 模拟除零场景
      if LVecDeque.Get(1) = 0 then
      begin
        raise EDivByZero.Create('Simulated divide by zero');
      end;
    except
      on E: EDivByZero do
      begin
        LExceptionRaised := True;
        WriteLn('Divide by zero exception: ', E.Message);
      end;
      on E: Exception do
      begin
        LExceptionRaised := True;
        WriteLn('General exception: ', E.Message);
      end;
    end;
    
    if LExceptionRaised then
      WriteLn('✓ Divide by zero scenario properly handled')
    else
      WriteLn('✗ Divide by zero scenario should be handled');
    
  finally
    LVecDeque.Free;
  end;
  WriteLn;
end;

begin
  WriteLn('Testing Exception Handling Implementation...');
  WriteLn;
  
  TestAccessViolation;
  TestExceptionRecovery;
  TestMemoryOperations;
  TestDivideByZeroSimulation;
  
  WriteLn('All exception handling tests completed!');
end.
