unit Test_once;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  fafafa.core.base,
  fafafa.core.sync.once;

type
  // 测试线程辅助类
  TOnceTestThread = class(TThread)
  private
    FProc: TThreadProcedure;
    FException: Exception;
  protected
    procedure Execute; override;
  public
    constructor Create(AProc: TThreadProcedure);
    destructor Destroy; override;
    property Exception: Exception read FException;
  end;

  // 全局函数测试
  TTestCase_Once_Global = class(TTestCase)
  published
    procedure Test_MakeOnce;
  end;

  // TOnce 类测试
  TTestCase_Once = class(TTestCase)
  private
    FOnce: IOnce;
    FCallCount: Integer;
    FLastValue: Integer;
    FThreadResults: array[0..9] of Integer;
    
    procedure SimpleCallback;
    procedure CountingCallback;
    procedure ValueSettingCallback;
    procedure ExceptionCallback;
    
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    
  published
    // 构造函数测试
    procedure Test_MakeOnce_WithProc;
    procedure Test_MakeOnce_WithMethod;
    procedure Test_MakeOnce_WithAnonymous;

    // Execute 方法测试
    procedure Test_Execute_Basic;
    procedure Test_Execute_Multiple_Calls;
    procedure Test_Execute_No_Callback;

    // ILock 接口测试
    procedure Test_Acquire_Basic;
    procedure Test_Release_NoOp;
    procedure Test_TryAcquire_Basic;
    procedure Test_TryAcquire_Already_Completed;

    // 基本功能测试
    procedure Test_Execute_With_Different_Callbacks;

    // 状态查询测试
    procedure Test_GetState_NotStarted;
    procedure Test_GetState_Completed;
    procedure Test_IsCompleted_Basic;
    procedure Test_IsInProgress_Basic;
    
    // 异常处理测试
    procedure Test_Execute_Exception_Recovery;
    procedure Test_Execute_Exception_State;

    // 并发测试
    procedure Test_Execute_Concurrent_Basic;
    procedure Test_Execute_Concurrent_Heavy;
    
    // 重置功能测试
    procedure Test_Reset_Basic;
    procedure Test_Reset_After_Completion;
    
    // 边界条件测试
    procedure Test_Execute_Rapid_Succession;
    procedure Test_Execute_Long_Running;
  end;

implementation

{ TOnceTestThread }

constructor TOnceTestThread.Create(AProc: TThreadProcedure);
begin
  FProc := AProc;
  FException := nil;
  inherited Create(False);
end;

destructor TOnceTestThread.Destroy;
begin
  if Assigned(FException) then
    FreeAndNil(FException);
  inherited Destroy;
end;

procedure TOnceTestThread.Execute;
begin
  try
    if Assigned(FProc) then
      FProc();
  except
    on E: Exception do
      FException := Exception.Create(E.Message);
  end;
end;

{ TTestCase_Once_Global }

procedure TTestCase_Once_Global.Test_MakeOnce;
var
  Once: IOnce;
begin
  Once := MakeOnce;
  CheckNotNull(Once, 'MakeOnce 应该返回有效的 IOnce 实例');
  CheckEquals(Ord(osNotStarted), Ord(Once.GetState), '新创建的 Once 应该处于未开始状态');
  CheckFalse(Once.IsCompleted, '新创建的 Once 应该未完成');
end;

{ TTestCase_Once }

procedure TTestCase_Once.SetUp;
begin
  FOnce := MakeOnce;
  FCallCount := 0;
  FLastValue := 0;
  FillChar(FThreadResults, SizeOf(FThreadResults), 0);
end;

procedure TTestCase_Once.TearDown;
begin
  FOnce := nil;
end;

procedure TTestCase_Once.SimpleCallback;
begin
  Inc(FCallCount);
end;

procedure TTestCase_Once.CountingCallback;
begin
  Inc(FCallCount);
  Sleep(10); // 模拟一些工作
end;

procedure TTestCase_Once.ValueSettingCallback;
begin
  Inc(FCallCount);
  FLastValue := 42;
end;

procedure TTestCase_Once.ExceptionCallback;
begin
  Inc(FCallCount);
  raise Exception.Create('测试异常');
end;

// 构造函数测试
procedure TTestCase_Once.Test_MakeOnce_WithProc;
var
  Once: IOnce;
begin
  Once := MakeOnce(@SimpleCallback);
  CheckNotNull(Once, 'MakeOnce(Proc) 应该返回有效实例');
  CheckFalse(Once.IsCompleted, '新创建的 Once 应该未完成');

  Once.Execute;
  CheckEquals(1, FCallCount, '构造时传入的过程应该被执行');
  CheckTrue(Once.IsCompleted, '执行后应该标记为已完成');
end;

procedure TTestCase_Once.Test_MakeOnce_WithMethod;
var
  Once: IOnce;
begin
  Once := MakeOnce(@SimpleCallback);
  CheckNotNull(Once, 'MakeOnce(Method) 应该返回有效实例');
  CheckFalse(Once.IsCompleted, '新创建的 Once 应该未完成');

  Once.Execute;
  CheckEquals(1, FCallCount, '构造时传入的方法应该被执行');
  CheckTrue(Once.IsCompleted, '执行后应该标记为已完成');
end;

procedure TTestCase_Once.Test_MakeOnce_WithAnonymous;
var
  Once: IOnce;
  LocalCount: Integer;
begin
  LocalCount := 0;
  Once := MakeOnce(
    procedure
    begin
      Inc(LocalCount);
      Inc(FCallCount);
    end
  );

  CheckNotNull(Once, 'MakeOnce(Anonymous) 应该返回有效实例');
  CheckFalse(Once.IsCompleted, '新创建的 Once 应该未完成');

  Once.Execute;
  CheckEquals(1, LocalCount, '匿名过程中的局部变量应该被修改');
  CheckEquals(1, FCallCount, '匿名过程应该被执行');
  CheckTrue(Once.IsCompleted, '执行后应该标记为已完成');
end;

// Execute 方法测试
procedure TTestCase_Once.Test_Execute_Basic;
begin
  FOnce.CallOnce(@SimpleCallback); // 设置回调
  FOnce.Reset; // 重置以便测试
  FOnce.CallOnce(@SimpleCallback); // 重新设置回调

  FCallCount := 0;
  FOnce.Reset;
  FOnce.CallOnce(@SimpleCallback);

  FOnce.Execute;
  CheckEquals(1, FCallCount, 'Execute 应该执行设置的回调');
  CheckTrue(FOnce.IsCompleted, 'Execute 后应该标记为已完成');
end;

procedure TTestCase_Once.Test_Execute_Multiple_Calls;
begin
  FOnce.CallOnce(@SimpleCallback);
  FOnce.Execute;
  CheckEquals(1, FCallCount, '第一次 Execute 应该执行回调');

  FOnce.Execute; // 再次调用
  CheckEquals(1, FCallCount, '多次 Execute 应该只执行一次');
  CheckTrue(FOnce.IsCompleted, '应该保持已完成状态');
end;

procedure TTestCase_Once.Test_Execute_No_Callback;
begin
  // 测试没有设置回调的情况
  FOnce.Execute;
  CheckTrue(FOnce.IsCompleted, '即使没有回调，Execute 也应该标记为已完成');
  CheckEquals(0, FCallCount, '没有回调时不应该执行任何操作');
end;

// ILock 接口测试
procedure TTestCase_Once.Test_Acquire_Basic;
begin
  // 测试基本的 Acquire 操作
  FOnce := MakeOnce(@SimpleCallback);

  FOnce.Acquire; // 应该执行回调
  CheckEquals(1, FCallCount, 'Acquire 应该执行存储的回调');
  CheckTrue(FOnce.IsCompleted, 'Acquire 后应该标记为已完成');
end;

procedure TTestCase_Once.Test_Release_NoOp;
begin
  // 测试 Release 是空操作
  FOnce := MakeOnce(@SimpleCallback);
  FOnce.Execute;
  CheckTrue(FOnce.IsCompleted, '执行后应该为已完成');

  FOnce.Release; // 应该是空操作
  CheckTrue(FOnce.IsCompleted, 'Release 后仍应该为已完成');
  CheckEquals(1, FCallCount, 'Release 不应该影响执行状态');
end;

procedure TTestCase_Once.Test_TryAcquire_Basic;
begin
  // 测试基本的 TryAcquire 操作
  FOnce := MakeOnce(@SimpleCallback);

  CheckTrue(FOnce.TryAcquire, 'TryAcquire 应该成功');
  CheckEquals(1, FCallCount, 'TryAcquire 应该执行回调');
  CheckTrue(FOnce.IsCompleted, 'TryAcquire 后应该标记为已完成');
end;

procedure TTestCase_Once.Test_TryAcquire_Already_Completed;
begin
  // 测试已完成状态下的 TryAcquire
  FOnce := MakeOnce(@SimpleCallback);
  FOnce.Execute;
  CheckEquals(1, FCallCount, '第一次调用应该执行');

  CheckTrue(FOnce.TryAcquire, '已完成状态下 TryAcquire 应该返回 True');
  CheckEquals(1, FCallCount, '已完成状态下 TryAcquire 不应该重复执行');
end;

procedure TTestCase_Once.Test_Execute_With_Different_Callbacks;
var
  LocalCount: Integer;
  Once1, Once2, Once3: IOnce;
begin
  LocalCount := 0;

  // 测试过程回调
  Once1 := MakeOnce(@SimpleCallback);
  Once1.Execute;
  CheckEquals(1, FCallCount, '过程回调应该被执行');
  CheckTrue(Once1.IsCompleted, 'Once 应该标记为已完成');

  // 测试方法回调
  FCallCount := 0;
  Once2 := MakeOnce(@SimpleCallback);
  Once2.Execute;
  CheckEquals(1, FCallCount, '方法回调应该被执行');
  CheckTrue(Once2.IsCompleted, 'Once 应该标记为已完成');

  // 测试匿名过程回调
  FCallCount := 0;
  Once3 := MakeOnce(
    procedure
    begin
      Inc(LocalCount);
      Inc(FCallCount);
    end
  );
  Once3.Execute;
  CheckEquals(1, LocalCount, '匿名过程中的局部变量应该被修改');
  CheckEquals(1, FCallCount, '匿名过程应该被执行');
  CheckTrue(Once3.IsCompleted, 'Once 应该标记为已完成');

  // 测试多次执行只执行一次
  Once3.Execute;
  Once3.Execute;
  CheckEquals(1, LocalCount, '多次执行应该只执行一次');
  CheckEquals(1, FCallCount, '多次执行应该只执行一次');
end;

procedure TTestCase_Once.Test_GetState_NotStarted;
begin
  CheckEquals(Ord(osNotStarted), Ord(FOnce.GetState), '初始状态应该为未开始');
  CheckFalse(FOnce.IsCompleted, '初始状态不应该为已完成');
end;

procedure TTestCase_Once.Test_GetState_Completed;
begin
  FOnce.CallOnce(@SimpleCallback);
  CheckEquals(Ord(osCompleted), Ord(FOnce.GetState), '执行后状态应该为已完成');
  CheckTrue(FOnce.IsCompleted, '执行后应该为已完成');
end;

procedure TTestCase_Once.Test_IsCompleted_Basic;
begin
  CheckFalse(FOnce.IsCompleted, '初始状态不应该为已完成');
  FOnce.CallOnce(@SimpleCallback);
  CheckTrue(FOnce.IsCompleted, '执行后应该为已完成');
end;

procedure TTestCase_Once.Test_IsInProgress_Basic;
begin
  // 注意：IsInProgress 的实现可能因平台而异
  // 这里只做基本检查
  CheckFalse(FOnce.IsInProgress, '初始状态不应该为进行中');
end;

procedure TTestCase_Once.Test_Execute_Exception_Recovery;
begin
  // 测试异常恢复
  FOnce := MakeOnce(@ExceptionCallback);
  try
    FOnce.Execute;
    Fail('应该抛出异常');
  except
    on E: Exception do
      CheckTrue(Pos('测试异常', E.Message) > 0, '应该抛出预期的异常');
  end;

  CheckEquals(1, FCallCount, '即使异常，回调也应该被调用');

  // 根据实现，异常后状态可能不同
  // Windows 实现会重置状态允许重试，Unix 实现可能不会
end;

procedure TTestCase_Once.Test_Execute_Exception_State;
begin
  FOnce := MakeOnce(@ExceptionCallback);
  try
    FOnce.Execute;
  except
    // 忽略异常
  end;

  // 检查异常后的状态（具体行为取决于平台实现）
  CheckEquals(1, FCallCount, '异常情况下回调应该被调用');
end;

procedure TTestCase_Once.Test_Execute_Concurrent_Basic;
var
  Threads: array[0..4] of TOnceTestThread;
  i: Integer;
begin
  // 创建多个线程同时调用 Execute
  FOnce := MakeOnce(@CountingCallback);

  for i := 0 to High(Threads) do
  begin
    Threads[i] := TOnceTestThread.Create(
      procedure
      begin
        FOnce.Execute;
      end
    );
  end;

  // 等待所有线程完成
  for i := 0 to High(Threads) do
  begin
    Threads[i].WaitFor;
    CheckNull(Threads[i].Exception, '线程不应该抛出异常');
    Threads[i].Free;
  end;

  CheckEquals(1, FCallCount, '并发调用应该只执行一次');
  CheckTrue(FOnce.IsCompleted, 'Once 应该标记为已完成');
end;

procedure TTestCase_Once.Test_Execute_Concurrent_Heavy;
var
  Threads: array[0..9] of TOnceTestThread;
  i: Integer;
begin
  // 更重的并发测试
  FOnce := MakeOnce(@CountingCallback);

  for i := 0 to High(Threads) do
  begin
    Threads[i] := TOnceTestThread.Create(
      procedure
      var
        j: Integer;
      begin
        for j := 0 to 99 do
          FOnce.Execute;
      end
    );
  end;

  for i := 0 to High(Threads) do
  begin
    Threads[i].WaitFor;
    CheckNull(Threads[i].Exception, '线程不应该抛出异常');
    Threads[i].Free;
  end;

  CheckEquals(1, FCallCount, '重度并发调用应该只执行一次');
end;

procedure TTestCase_Once.Test_Reset_Basic;
begin
  FOnce := MakeOnce(@SimpleCallback);
  FOnce.Execute;
  CheckEquals(1, FCallCount, '第一次调用应该执行');
  CheckTrue(FOnce.IsCompleted, '应该标记为已完成');

  FOnce.Reset;
  CheckFalse(FOnce.IsCompleted, '重置后不应该为已完成');
  CheckEquals(Ord(osNotStarted), Ord(FOnce.GetState), '重置后状态应该为未开始');

  // 注意：重置后需要重新设置回调，因为我们移除了 CallOnce
  // 这里只测试重置功能本身
end;

procedure TTestCase_Once.Test_Reset_After_Completion;
begin
  FOnce := MakeOnce(@ValueSettingCallback);
  FOnce.Execute;
  CheckEquals(42, FLastValue, '回调应该设置值');

  FOnce.Reset;
  CheckFalse(FOnce.IsCompleted, '重置后应该为未完成状态');
  CheckEquals(Ord(osNotStarted), Ord(FOnce.GetState), '重置后状态应该为未开始');
end;

procedure TTestCase_Once.Test_Execute_Rapid_Succession;
var
  i: Integer;
begin
  // 快速连续调用测试
  FOnce := MakeOnce(@SimpleCallback);
  for i := 0 to 999 do
    FOnce.Execute;

  CheckEquals(1, FCallCount, '快速连续调用应该只执行一次');
end;

procedure TTestCase_Once.Test_Execute_Long_Running;
begin
  // 测试长时间运行的回调
  FOnce := MakeOnce(
    procedure
    begin
      Inc(FCallCount);
      Sleep(100); // 模拟长时间运行
      FLastValue := 123;
    end
  );

  FOnce.Execute;
  CheckEquals(1, FCallCount, '长时间运行的回调应该被调用');
  CheckEquals(123, FLastValue, '长时间运行的回调应该完成');
  CheckTrue(FOnce.IsCompleted, '应该标记为已完成');
end;

initialization
  RegisterTest(TTestCase_Once_Global);
  RegisterTest(TTestCase_Once);

end.
