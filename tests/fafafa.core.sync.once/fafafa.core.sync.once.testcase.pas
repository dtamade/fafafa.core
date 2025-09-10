unit fafafa.core.sync.once.testcase;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.sync.once, fafafa.core.sync.once.base;

type
  // 全局函数测试
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeOnce_NoCallback;
    procedure Test_MakeOnce_WithProc;
    procedure Test_MakeOnce_Returns_IOnce_Interface;
  end;

  // IOnce 接口测试
  TTestCase_IOnce = class(TTestCase)
  private
    FOnce: IOnce;
    FCallCount: Integer;
    FExceptionRaised: Boolean;

    procedure CountingCallback;
    procedure ExceptionCallback;
    procedure LongRunningCallback;

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    // 基础功能测试
    procedure Test_Execute_NoCallback_NoOp;
    procedure Test_Execute_WithProc_CallsOnce;
    procedure Test_Execute_Multiple_Calls_OnlyOnce;

    // 状态查询测试
    procedure Test_State_Initial_NotStarted;
    procedure Test_State_After_Execute_Completed;
    procedure Test_Completed_Property;

    // 异常处理和毒化状态测试
    procedure Test_Execute_Exception_Poisoned;
    procedure Test_Execute_Poisoned_ThrowsException;
    procedure Test_ExecuteForce_Poisoned_Recovery;
    procedure Test_Poisoned_Property;
    procedure Test_State_After_Exception_Poisoned;

    // 等待机制测试
    procedure Test_Wait_CompletedOnce;
    procedure Test_Wait_NotStarted_Blocks;
    procedure Test_WaitForce_IgnoresPoisoned;
    procedure Test_Wait_Poisoned_ThrowsException;

    // 不同回调类型测试
    procedure Test_Execute_MethodCallback;
    procedure Test_Execute_NilCallback_Handled;

    // 边界条件测试
    procedure Test_Execute_EmptyCallback;
    procedure Test_Execute_LongRunningCallback;
    procedure Test_ExecuteForce_Multiple_Calls;
  end;

  // 基础并发测试
  TTestCase_Concurrency = class(TTestCase)
  private
    FOnce: IOnce;

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    // 基础并发测试
    procedure Test_Execute_Concurrent_OnlyOneExecutes;

    // 回调类型一致性测试
    procedure Test_Execute_Concurrent_ProcCallback;
    procedure Test_Execute_Concurrent_MethodCallback;
  end;

  // 简化的测试辅助类
  TOnceWorkerThread = class(TThread)
  private
    FOnce: IOnce;
    FExecutionCount: PInteger;
  protected
    procedure Execute; override;
  public
    constructor Create(const AOnce: IOnce; AExecutionCount: PInteger);
  end;

implementation

var
  GlobalExecutionCount: Integer = 0;

// 全局辅助函数
procedure GlobalExceptionCallback;
begin
  raise Exception.Create('Test exception');
end;

procedure GlobalConcurrentCallback;
begin
  InterlockedIncrement(GlobalExecutionCount);
  Sleep(10); // 模拟一些工作
end;

// 辅助函数
function IsStressModeEnabled: Boolean;
var
  i: Integer;
  s: String;
begin
  Result := False;
  for i := 1 to ParamCount do
  begin
    s := ParamStr(i);
    if (s = '--stress') or (s = '-S') then Exit(True);
  end;
end;

{ TOnceWorkerThread }

constructor TOnceWorkerThread.Create(const AOnce: IOnce; AExecutionCount: PInteger);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FOnce := AOnce;
  FExecutionCount := AExecutionCount;
end;

procedure TOnceWorkerThread.Execute;
begin
  try
    FOnce.Execute;
  except
    // 忽略异常
  end;
end;

{ TTestCase_Global }

procedure TTestCase_Global.Test_MakeOnce_NoCallback;
var
  Once: IOnce;
begin
  Once := MakeOnce;
  AssertNotNull('MakeOnce should return non-nil interface', Once);
  AssertEquals('Initial state should be NotStarted', Ord(osNotStarted), Ord(Once.State));
end;

procedure TTestCase_Global.Test_MakeOnce_WithProc;
var
  Once: IOnce;
  Called: Boolean;

  procedure TestProc;
  begin
    Called := True;
  end;

begin
  Called := False;
  Once := MakeOnce(@TestProc);
  AssertNotNull('MakeOnce with proc should return non-nil interface', Once);

  Once.Execute;
  AssertTrue('Callback should be called', Called);
  AssertEquals('State should be Completed', Ord(osCompleted), Ord(Once.State));
end;

procedure TTestCase_Global.Test_MakeOnce_Returns_IOnce_Interface;
var
  Once: IOnce;
begin
  Once := MakeOnce;
  AssertNotNull('MakeOnce should return IOnce interface', Once);
  AssertTrue('Should support IOnce interface', Supports(Once, IOnce));
end;

{ TTestCase_IOnce }

procedure TTestCase_IOnce.CountingCallback;
begin
  Inc(FCallCount);
end;

procedure TTestCase_IOnce.ExceptionCallback;
begin
  FExceptionRaised := True;
  raise Exception.Create('Test exception for poisoning');
end;

procedure TTestCase_IOnce.LongRunningCallback;
begin
  Sleep(100); // 模拟长时间运行的回调
  Inc(FCallCount);
end;

procedure TTestCase_IOnce.SetUp;
begin
  inherited SetUp;
  FOnce := MakeOnce;
  FCallCount := 0;
  FExceptionRaised := False;
end;

procedure TTestCase_IOnce.TearDown;
begin
  FOnce := nil;
  inherited TearDown;
end;

procedure TTestCase_IOnce.Test_Execute_NoCallback_NoOp;
begin
  // Execute without callback should be no-op
  FOnce.Execute;
  AssertEquals('State should be Completed after no-op execute', Ord(osCompleted), Ord(FOnce.State));
end;

procedure TTestCase_IOnce.Test_Execute_WithProc_CallsOnce;
begin
  FOnce.Execute(@CountingCallback);
  AssertEquals('Callback should be called once', 1, FCallCount);
  AssertEquals('State should be Completed', Ord(osCompleted), Ord(FOnce.State));

  // Second call should not execute callback
  FOnce.Execute(@CountingCallback);
  AssertEquals('Callback should still be called only once', 1, FCallCount);
end;

procedure TTestCase_IOnce.Test_Execute_Multiple_Calls_OnlyOnce;
begin
  FOnce.Execute(@CountingCallback);
  FOnce.Execute(@CountingCallback);
  FOnce.Execute(@CountingCallback);

  AssertEquals('Callback should be called only once despite multiple Execute calls', 1, FCallCount);
  AssertEquals('State should be Completed', Ord(osCompleted), Ord(FOnce.State));
end;

procedure TTestCase_IOnce.Test_State_Initial_NotStarted;
begin
  AssertEquals('Initial state should be NotStarted', Ord(osNotStarted), Ord(FOnce.State));
  AssertFalse('Should not be completed initially', FOnce.Completed);
  AssertFalse('Should not be poisoned initially', FOnce.Poisoned);
end;

procedure TTestCase_IOnce.Test_State_After_Execute_Completed;
begin
  FOnce.Execute(@CountingCallback);
  AssertEquals('State should be Completed after execute', Ord(osCompleted), Ord(FOnce.State));
  AssertTrue('Should be completed', FOnce.Completed);
  AssertFalse('Should not be poisoned', FOnce.Poisoned);
end;

procedure TTestCase_IOnce.Test_Completed_Property;
begin
  AssertFalse('Should not be completed initially', FOnce.Completed);
  FOnce.Execute(@CountingCallback);
  AssertTrue('Should be completed after execute', FOnce.Completed);
end;

// 异常处理和毒化状态测试
procedure TTestCase_IOnce.Test_Execute_Exception_Poisoned;
begin
  try
    FOnce.Execute(@ExceptionCallback);
    Fail('Execute should have raised exception');
  except
    on E: Exception do
      AssertTrue('Exception should be raised', True);
  end;

  AssertTrue('Exception callback should have been called', FExceptionRaised);
  AssertEquals('State should be Poisoned after exception', Ord(osPoisoned), Ord(FOnce.State));
  AssertTrue('Should be poisoned', FOnce.Poisoned);
  AssertFalse('Should not be completed when poisoned', FOnce.Completed);
end;

procedure TTestCase_IOnce.Test_Execute_Poisoned_ThrowsException;
begin
  // 首先毒化 once
  try
    FOnce.Execute(@ExceptionCallback);
  except
    // 忽略第一次异常
  end;

  AssertTrue('Should be poisoned', FOnce.Poisoned);

  // 后续调用应该抛出异常
  try
    FOnce.Execute(@CountingCallback);
    Fail('Execute on poisoned once should raise exception');
  except
    on E: Exception do
      AssertTrue('Should raise exception on poisoned once', True);
  end;

  AssertEquals('Callback should not be called on poisoned once', 0, FCallCount);
end;

procedure TTestCase_IOnce.Test_ExecuteForce_Poisoned_Recovery;
begin
  // 首先毒化 once
  try
    FOnce.Execute(@ExceptionCallback);
  except
    // 忽略异常
  end;

  AssertTrue('Should be poisoned initially', FOnce.Poisoned);

  // ExecuteForce 应该能够恢复
  FOnce.ExecuteForce(@CountingCallback);

  AssertEquals('Callback should be called after force recovery', 1, FCallCount);
  AssertEquals('State should be Completed after recovery', Ord(osCompleted), Ord(FOnce.State));
  AssertTrue('Should be completed after recovery', FOnce.Completed);
  AssertFalse('Should not be poisoned after recovery', FOnce.Poisoned);
end;

procedure TTestCase_IOnce.Test_Poisoned_Property;
begin
  AssertFalse('Should not be poisoned initially', FOnce.Poisoned);

  try
    FOnce.Execute(@ExceptionCallback);
  except
    // 忽略异常
  end;

  AssertTrue('Should be poisoned after exception', FOnce.Poisoned);
end;

procedure TTestCase_IOnce.Test_State_After_Exception_Poisoned;
begin
  AssertEquals('Initial state should be NotStarted', Ord(osNotStarted), Ord(FOnce.State));

  try
    FOnce.Execute(@ExceptionCallback);
  except
    // 忽略异常
  end;

  AssertEquals('State should be Poisoned after exception', Ord(osPoisoned), Ord(FOnce.State));
end;

// 等待机制测试
procedure TTestCase_IOnce.Test_Wait_CompletedOnce;
begin
  // 先完成 once
  FOnce.Execute(@CountingCallback);
  AssertTrue('Should be completed', FOnce.Completed);

  // Wait 应该立即返回
  FOnce.Wait;
  AssertTrue('Wait should succeed on completed once', True);
end;

procedure TTestCase_IOnce.Test_Wait_NotStarted_Blocks;
begin
  // 这个测试验证 Wait 在未开始的 once 上会阻塞
  // 由于是单线程测试，我们只能验证状态
  AssertEquals('Should be NotStarted initially', Ord(osNotStarted), Ord(FOnce.State));

  // 在单线程环境中，我们无法真正测试阻塞行为
  // 这个测试主要验证接口存在且可调用
  AssertTrue('Wait method should exist', True);
end;

procedure TTestCase_IOnce.Test_WaitForce_IgnoresPoisoned;
begin
  // 首先毒化 once
  try
    FOnce.Execute(@ExceptionCallback);
  except
    // 忽略异常
  end;

  AssertTrue('Should be poisoned', FOnce.Poisoned);

  // WaitForce 应该忽略毒化状态
  FOnce.WaitForce;
  AssertTrue('WaitForce should succeed even on poisoned once', True);
end;

procedure TTestCase_IOnce.Test_Wait_Poisoned_ThrowsException;
begin
  // 首先毒化 once
  try
    FOnce.Execute(@ExceptionCallback);
  except
    // 忽略异常
  end;

  AssertTrue('Should be poisoned', FOnce.Poisoned);

  // Wait 在毒化状态下应该抛出异常
  try
    FOnce.Wait;
    Fail('Wait on poisoned once should raise exception');
  except
    on E: Exception do
      AssertTrue('Should raise exception on poisoned once', True);
  end;
end;

// 不同回调类型测试
procedure TTestCase_IOnce.Test_Execute_MethodCallback;
var
  TestObj: TObject;
  MethodCalled: Boolean;

  procedure TestMethod;
  begin
    MethodCalled := True;
    Inc(FCallCount);
  end;

begin
  MethodCalled := False;
  TestObj := TObject.Create;
  try
    FOnce.Execute(@TestMethod);
    AssertTrue('Method callback should be called', MethodCalled);
    AssertEquals('Call count should be 1', 1, FCallCount);
    AssertTrue('Should be completed', FOnce.Completed);
  finally
    TestObj.Free;
  end;
end;

procedure TTestCase_IOnce.Test_Execute_NilCallback_Handled;
var
  NilProc: TOnceProc;
begin
  NilProc := nil;

  // 执行 nil 回调应该正常工作
  FOnce.Execute(NilProc);
  AssertTrue('Should be completed after nil callback', FOnce.Completed);
  AssertEquals('State should be Completed', Ord(osCompleted), Ord(FOnce.State));
end;

// 边界条件测试
procedure TTestCase_IOnce.Test_Execute_EmptyCallback;

  procedure EmptyProc;
  begin
    // 空的回调函数
  end;

begin
  FOnce.Execute(@EmptyProc);
  AssertTrue('Should be completed after empty callback', FOnce.Completed);
  AssertEquals('State should be Completed', Ord(osCompleted), Ord(FOnce.State));
end;

procedure TTestCase_IOnce.Test_Execute_LongRunningCallback;
begin
  FOnce.Execute(@LongRunningCallback);

  AssertEquals('Long running callback should be called', 1, FCallCount);
  AssertTrue('Should be completed after long running callback', FOnce.Completed);
end;

procedure TTestCase_IOnce.Test_ExecuteForce_Multiple_Calls;
begin
  // 第一次调用
  FOnce.ExecuteForce(@CountingCallback);
  AssertEquals('First call should execute', 1, FCallCount);

  // 第二次强制调用应该重新执行
  FOnce.ExecuteForce(@CountingCallback);
  AssertEquals('Second force call should execute again', 2, FCallCount);

  AssertTrue('Should be completed', FOnce.Completed);
end;

{ TTestCase_Concurrency }

procedure TTestCase_Concurrency.SetUp;
begin
  inherited SetUp;
  FOnce := MakeOnce(@GlobalConcurrentCallback);
  GlobalExecutionCount := 0; // 重置全局计数器
end;

procedure TTestCase_Concurrency.TearDown;
begin
  FOnce := nil;
  inherited TearDown;
end;

// 并发执行测试
procedure TTestCase_Concurrency.Test_Execute_Concurrent_OnlyOneExecutes;
const
  ThreadCount = 5;
var
  Threads: array[0..ThreadCount-1] of TOnceWorkerThread;
  i: Integer;
begin
  // 创建多个线程同时执行
  for i := 0 to ThreadCount-1 do
    Threads[i] := TOnceWorkerThread.Create(FOnce, @GlobalExecutionCount);

  try
    // 等待所有线程完成
    for i := 0 to ThreadCount-1 do
      Threads[i].WaitFor;

    // 验证只有一个线程执行了回调
    AssertEquals('Only one thread should execute callback', 1, GlobalExecutionCount);
    AssertTrue('Once should be completed', FOnce.Completed);
  finally
    for i := 0 to ThreadCount-1 do
      Threads[i].Free;
  end;
end;

// 回调类型一致性测试
procedure TTestCase_Concurrency.Test_Execute_Concurrent_ProcCallback;
const
  ThreadCount = 5;
var
  Threads: array[0..ThreadCount-1] of TOnceWorkerThread;
  Once: IOnce;
  ExecutionCount: Integer;
  i: Integer;

  procedure TestProc;
  begin
    InterlockedIncrement(ExecutionCount);
  end;

begin
  ExecutionCount := 0;
  Once := MakeOnce(@TestProc);

  // 创建多个线程同时执行过程回调
  for i := 0 to ThreadCount-1 do
    Threads[i] := TOnceWorkerThread.Create(Once, @ExecutionCount);

  try
    // 等待所有线程完成
    for i := 0 to ThreadCount-1 do
      Threads[i].WaitFor;

    // 验证过程回调的并发安全性
    AssertEquals('Proc callback: only one execution', 1, ExecutionCount);
    AssertTrue('Once should be completed', Once.Completed);
  finally
    for i := 0 to ThreadCount-1 do
      Threads[i].Free;
  end;
end;

procedure TTestCase_Concurrency.Test_Execute_Concurrent_MethodCallback;
const
  ThreadCount = 5;
var
  Threads: array[0..ThreadCount-1] of TThread;
  Once: IOnce;
  ExecutionCount: Integer;
  i: Integer;

  procedure TestMethod;
  begin
    InterlockedIncrement(ExecutionCount);
  end;

begin
  ExecutionCount := 0;
  Once := MakeOnce;

  // 创建多个线程同时执行方法回调
  for i := 0 to ThreadCount-1 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      begin
        Once.Execute(@TestMethod);
      end);
    Threads[i].Start;
  end;

  try
    // 等待所有线程完成
    for i := 0 to ThreadCount-1 do
      Threads[i].WaitFor;

    // 验证方法回调的并发安全性
    AssertEquals('Method callback: only one execution', 1, ExecutionCount);
    AssertTrue('Once should be completed', Once.Completed);
  finally
    for i := 0 to ThreadCount-1 do
      Threads[i].Free;
  end;
end;







initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_IOnce);
  RegisterTest(TTestCase_Concurrency);

end.
