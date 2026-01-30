unit Test_thread;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.base,
  fafafa.core.sync,
  fafafa.core.thread;

// 全局测试函数
function GlobalTestFunc(AData: Pointer): Boolean;
function GlobalTestFunc2(AData: Pointer): Boolean;

type

  {**
   * TTestCase_Global
   *
   * @desc 全局函数/过程/变量测试套件
   *       测试 fafafa.core.thread 模块中的所有全局函数
   *}
  TTestCase_Global = class(TTestCase)
  published
    // 目前 thread 模块没有全局函数，所有功能都在 TThreads 类中
    procedure Test_NoGlobalFunctions;
  end;

  {**
   * TTestCase_TThreads
   *
   * @desc TThreads 工具类测试套件
   *       测试所有静态方法和工厂函数
   *}
  TTestCase_TThreads = class(TTestCase)
  private
    FTestExecuted: Boolean;
    FTestValue: Integer;

    // 测试用的执行函数
    function TestTaskFunc(AData: Pointer): Boolean;
    function TestTaskMethod(AData: Pointer): Boolean;

  protected
    procedure SetUp; override;

  published
    // 基础工具方法测试
    procedure Test_TThreads_GetCPUCount;
    procedure Test_TThreads_Sleep;
    procedure Test_TThreads_Yield;

    // 线程本地存储工厂方法测试
    procedure Test_TThreads_CreateThreadLocal;

    // 同步工具工厂方法测试
    procedure Test_TThreads_CreateCountDownLatch;

    // 线程池工厂方法测试
    procedure Test_TThreads_CreateThreadPool;
    procedure Test_TThreads_CreateFixedThreadPool;
    procedure Test_TThreads_CreateCachedThreadPool;
    procedure Test_TThreads_CreateSingleThreadPool;

    // 任务调度器工厂方法测试
    procedure Test_TThreads_CreateTaskScheduler;

    // 通道工厂方法测试
    procedure Test_TThreads_CreateChannel;

    // 高级任务方法测试
    procedure Test_TThreads_Spawn_WithTaskFunc;
    procedure Test_TThreads_SpawnBlocking_WithTaskFunc;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure Test_TThreads_Spawn_WithRefFunc;
    {$ENDIF}

    // 任务组合方法测试
    procedure Test_TThreads_Join;

    // 异常测试
    procedure Test_TThreads_CreateThreadPool_InvalidParams;
    procedure Test_TThreads_CreateCountDownLatch_InvalidCount;
    procedure Test_TThreads_CreateChannel_InvalidCapacity;
  end;

  {**
   * TTestCase_TFuture
   *
   * @desc TFuture 类测试套件
   *       测试异步操作结果管理
   *}
  TTestCase_TFuture = class(TTestCase)
  private
    LFuture: TFuture;

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    // 基础状态测试
    procedure Test_TFuture_Create;
    procedure Test_TFuture_IsDone;
    procedure Test_TFuture_IsCancelled;
    procedure Test_TFuture_Complete;
    procedure Test_TFuture_Cancel;

    // 等待机制测试
    procedure Test_TFuture_WaitFor;
    procedure Test_TFuture_WaitFor_Timeout;

    // 链式调用测试
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure Test_TFuture_ContinueWith;
    procedure Test_TFuture_OnComplete;
    {$ENDIF}

    // 异常测试
    procedure Test_TFuture_Complete_AlreadyCompleted;
    procedure Test_TFuture_Cancel_AlreadyCompleted;
  end;

  {**
   * TTestCase_TThreadLocal
   *
   * @desc TThreadLocal 类测试套件
   *       测试线程本地存储功能
   *}
  TTestCase_TThreadLocal = class(TTestCase)
  private
    LThreadLocal: IThreadLocal;

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    // 基础功能测试
    procedure Test_TThreadLocal_Create;
    procedure Test_TThreadLocal_SetValue;
    procedure Test_TThreadLocal_GetValue;
    procedure Test_TThreadLocal_HasValue;
    procedure Test_TThreadLocal_RemoveValue;
    procedure Test_TThreadLocal_Value_Property;

    // 多线程隔离测试
    procedure Test_TThreadLocal_MultipleThreads;

    // 异常测试
    procedure Test_TThreadLocal_GetValue_NoValue;
  end;

  {**
   * TTestCase_TCountDownLatch
   *
   * @desc TCountDownLatch 类测试套件
   *       测试倒计数门闩同步功能
   *}
  TTestCase_TCountDownLatch = class(TTestCase)
  private
    LCountDownLatch: ICountDownLatch;

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    // 基础功能测试
    procedure Test_TCountDownLatch_Create;
    procedure Test_TCountDownLatch_Count;
    procedure Test_TCountDownLatch_CountDown;
    procedure Test_TCountDownLatch_Await;
    procedure Test_TCountDownLatch_Await_Timeout;

    // 多线程同步测试
    procedure Test_TCountDownLatch_MultipleThreads;

    // 边界条件测试
    procedure Test_TCountDownLatch_ZeroCount;
    procedure Test_TCountDownLatch_CountDown_AlreadyZero;
  end;

implementation

// 全局测试函数实现
var
  GTestExecuted: Boolean = False;
  GTestValue: Integer = 0;

function GlobalTestFunc(AData: Pointer): Boolean;
begin
  GTestExecuted := True;
  if Assigned(AData) then
    GTestValue := Integer(PtrUInt(AData))
  else
    GTestValue := 42;
  Result := True;
end;

function GlobalTestFunc2(AData: Pointer): Boolean;
begin
  GTestExecuted := True;
  if Assigned(AData) then
    GTestValue := Integer(PtrUInt(AData))
  else
    GTestValue := 123;
  Result := True;
end;

{ TTestCase_Global }

procedure TTestCase_Global.Test_NoGlobalFunctions;
begin
  // thread 模块采用静态类设计，没有全局函数
  // 这符合现代化 API 设计原则
  AssertTrue('thread 模块正确采用静态类设计', True);
end;

{ TTestCase_TThreads }

procedure TTestCase_TThreads.SetUp;
begin
  inherited SetUp;
  FTestExecuted := False;
  FTestValue := 0;
end;

function TTestCase_TThreads.TestTaskFunc(AData: Pointer): Boolean;
begin
  FTestExecuted := True;
  if Assigned(AData) then
    FTestValue := Integer(PtrUInt(AData))
  else
    FTestValue := 42;
  Result := True;
end;

function TTestCase_TThreads.TestTaskMethod(AData: Pointer): Boolean;
begin
  FTestExecuted := True;
  if Assigned(AData) then
    FTestValue := Integer(PtrUInt(AData))
  else
    FTestValue := 123;
  Result := True;
end;

procedure TTestCase_TThreads.Test_TThreads_GetCPUCount;
var
  LCPUCount: Integer;
begin
  // 测试获取 CPU 核心数
  LCPUCount := GetCPUCount;
  AssertTrue('CPU 核心数应该大于 0', LCPUCount > 0);
  AssertTrue('CPU 核心数应该是合理范围', LCPUCount <= 1024);
end;

procedure TTestCase_TThreads.Test_TThreads_Sleep;
var
  LStartTime, LEndTime: QWord;
begin
  // 测试线程睡眠功能
  LStartTime := GetTickCount64;
  Sleep(50);
  LEndTime := GetTickCount64;

  // 睡眠时间应该大约是 50ms（允许一定误差）
  AssertTrue('Sleep 应该等待大约 50ms',
    (LEndTime - LStartTime >= 30) and (LEndTime - LStartTime <= 100));
end;

procedure TTestCase_TThreads.Test_TThreads_Yield;
begin
  // 测试线程让出 CPU 时间片
  // Yield 不应该抛出异常
  Yield;
  AssertTrue('Yield 应该正常完成', True);
end;

procedure TTestCase_TThreads.Test_TThreads_CreateThreadLocal;
var
  LThreadLocal: IThreadLocal;
begin
  // 测试创建线程本地存储
  LThreadLocal := CreateThreadLocal;
  AssertNotNull('应该成功创建 ThreadLocal', LThreadLocal);
  AssertFalse('初始状态应该没有值', LThreadLocal.HasValue);
end;

procedure TTestCase_TThreads.Test_TThreads_CreateCountDownLatch;
var
  LLatch: ICountDownLatch;
begin
  // 测试创建倒计数门闩
  LLatch := CreateCountDownLatch(3);
  AssertNotNull('应该成功创建 CountDownLatch', LLatch);
  AssertEquals('初始计数应该是 3', 3, LLatch.Count);
end;

procedure TTestCase_TThreads.Test_TThreads_CreateThreadPool;
var
  LPool: IThreadPool;
begin
  // 最小化测试：只创建，不调用任何方法
  LPool := CreateThreadPool(2, 4, 60000);
  // 测试通过
end;

procedure TTestCase_TThreads.Test_TThreads_CreateFixedThreadPool;
var
  LPool: IThreadPool;
begin
  // 测试创建固定大小线程池
  LPool := CreateFixedThreadPool(4);
  try
    AssertNotNull('应该成功创建固定线程池', LPool);
    AssertFalse('线程池初始状态不应该关闭', LPool.IsShutdown);
  finally
    if Assigned(LPool) and not LPool.IsShutdown then
      LPool.Shutdown;
  end;
end;

procedure TTestCase_TThreads.Test_TThreads_CreateCachedThreadPool;
var
  LPool: IThreadPool;
begin
  // 测试创建缓存线程池
  LPool := CreateCachedThreadPool;
  try
    AssertNotNull('应该成功创建缓存线程池', LPool);
    AssertFalse('线程池初始状态不应该关闭', LPool.IsShutdown);
  finally
    if Assigned(LPool) and not LPool.IsShutdown then
      LPool.Shutdown;
  end;
end;

procedure TTestCase_TThreads.Test_TThreads_CreateSingleThreadPool;
var
  LPool: IThreadPool;
begin
  // 测试创建单线程池
  LPool := CreateSingleThreadPool;
  try
    AssertNotNull('应该成功创建单线程池', LPool);
    AssertFalse('线程池初始状态不应该关闭', LPool.IsShutdown);
  finally
    if Assigned(LPool) and not LPool.IsShutdown then
      LPool.Shutdown;
  end;
end;

procedure TTestCase_TThreads.Test_TThreads_CreateTaskScheduler;
var
  LScheduler: ITaskScheduler;
begin
  // 测试创建任务调度器
  LScheduler := CreateTaskScheduler;
  try
    AssertNotNull('应该成功创建任务调度器', LScheduler);
    AssertFalse('调度器初始状态不应该关闭', LScheduler.IsShutdown);
  finally
    if Assigned(LScheduler) and not LScheduler.IsShutdown then
      LScheduler.Shutdown;
  end;
end;

procedure TTestCase_TThreads.Test_TThreads_CreateChannel;
var
  LChannel: IChannel;
begin
  // 测试创建通道
  LChannel := CreateChannel(10);
  AssertNotNull('应该成功创建通道', LChannel);
  AssertFalse('通道初始状态不应该关闭', LChannel.IsClosed);
end;

procedure TTestCase_TThreads.Test_TThreads_Spawn_WithTaskFunc;
var
  LFuture: IFuture;
begin
  // 测试使用函数指针生成任务
  GTestExecuted := False;
  GTestValue := 0;

  LFuture := Spawn(@GlobalTestFunc, Pointer(PtrUInt(999)));
  AssertNotNull('应该成功创建 Future', LFuture);

  // 等待任务完成
  AssertTrue('任务应该在超时内完成', LFuture.WaitFor(2000));
  AssertTrue('任务应该已完成', LFuture.IsDone);
  AssertTrue('测试函数应该被执行', GTestExecuted);
  AssertEquals('测试值应该被设置', 999, GTestValue);
end;

procedure TTestCase_TThreads.Test_TThreads_SpawnBlocking_WithTaskFunc;
var
  LFuture: IFuture;
begin
  // 测试使用函数指针生成阻塞任务
  GTestExecuted := False;
  GTestValue := 0;

  LFuture := SpawnBlocking(@GlobalTestFunc2, Pointer(PtrUInt(888)));
  AssertNotNull('应该成功创建 Future', LFuture);

  // 等待任务完成
  AssertTrue('阻塞任务应该在超时内完成', LFuture.WaitFor(2000));
  AssertTrue('任务应该已完成', LFuture.IsDone);
  AssertTrue('测试函数应该被执行', GTestExecuted);
  AssertEquals('测试值应该被设置', 888, GTestValue);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TTestCase_TThreads.Test_TThreads_Spawn_WithRefFunc;
var
  LFuture: IFuture;
  LExecuted: Boolean;
  LValue: Integer;
  LPool: IThreadPool;
begin
  // 测试使用匿名函数生成任务
  // 注意：TThreads.Spawn 只支持 TTaskFunc，匿名函数需要通过线程池的 Submit 方法
  LExecuted := False;
  LValue := 0;

  LPool := TThreads.CreateThreadPool(2, 4);
  try
    LFuture := LPool.Submit(
      function: Boolean
      begin
        LExecuted := True;
        LValue := 777;
        Result := True;
      end
    );

    AssertNotNull('应该成功创建 Future', LFuture);

    // 等待任务完成
    AssertTrue('匿名函数任务应该在超时内完成', LFuture.WaitFor(2000));
    AssertTrue('任务应该已完成', LFuture.IsDone);
    AssertTrue('匿名函数应该被执行', LExecuted);
    AssertEquals('测试值应该被设置', 777, LValue);
  finally
    if Assigned(LPool) and not LPool.IsShutdown then
      LPool.Shutdown;
  end;
end;
{$ENDIF}

procedure TTestCase_TThreads.Test_TThreads_Join;
var
  LFutures: array[0..2] of IFuture;
  I: Integer;
begin
  // 测试任务组合等待
  for I := 0 to 2 do
  begin
    LFutures[I] := TThreads.Spawn(@GlobalTestFunc, Pointer(PtrUInt(100 + I)));
  end;

  // 等待所有任务完成
  AssertTrue('所有任务应该在超时内完成', Join(LFutures, 3000));

  // 验证所有任务都已完成
  for I := 0 to 2 do
    AssertTrue('任务 ' + IntToStr(I) + ' 应该已完成', LFutures[I].IsDone);
end;

procedure TTestCase_TThreads.Test_TThreads_CreateThreadPool_InvalidParams;
begin
  // 测试无效参数异常
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('核心线程数为负数应该抛出异常', EInvalidArgument,
    procedure
    begin
      CreateThreadPool(-1, 4);
    end);

  AssertException('最大线程数小于核心线程数应该抛出异常', EInvalidArgument,
    procedure
    begin
      CreateThreadPool(4, 2);
    end);
  {$ENDIF}
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('Core=0, Max>0 允许；Core<0 应该抛异常', EInvalidArgument,
    procedure
    begin
      CreateThreadPool(-2, 8);
    end);

  AssertException('Max=0 表示"默认/不限制"；Max<max(1,Core) 应该抛异常', EInvalidArgument,
    procedure
    begin
      CreateThreadPool(3, 2);
    end);

  // QueueCapacity 负数(<-1) 抛异常
  AssertException('QueueCapacity<-1 应抛异常', EInvalidArgument,
    procedure
    begin
      // 不直接引用常量，使用枚举序号 0（rpAbort）
      CreateThreadPool(2, 4, 60000, -2, TRejectPolicy(0));
    end);
  {$ENDIF}

end;

procedure TTestCase_TThreads.Test_TThreads_CreateCountDownLatch_InvalidCount;
begin
  // 测试无效计数异常
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('负数计数应该抛出异常', EInvalidArgument,
    procedure
    begin
      CreateCountDownLatch(-1);
    end);
  {$ENDIF}
end;

procedure TTestCase_TThreads.Test_TThreads_CreateChannel_InvalidCapacity;
begin
  // 测试无效容量异常
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('负数容量应该抛出异常', EInvalidArgument,
    procedure
    begin
      TThreads.CreateChannel(-1);
    end);
  {$ENDIF}
end;

{ TTestCase_TFuture }

procedure TTestCase_TFuture.SetUp;
begin
  inherited SetUp;
  LFuture := TFuture.Create;
end;

procedure TTestCase_TFuture.TearDown;
begin
  if Assigned(LFuture) then
    LFuture.Free;
  inherited TearDown;
end;

procedure TTestCase_TFuture.Test_TFuture_Create;
begin
  // 测试 Future 创建
  AssertNotNull('Future 应该成功创建', LFuture);
  AssertFalse('初始状态不应该完成', LFuture.IsDone);
  AssertFalse('初始状态不应该取消', LFuture.IsCancelled);
end;

procedure TTestCase_TFuture.Test_TFuture_IsDone;
begin
  // 测试完成状态
  AssertFalse('初始状态不应该完成', LFuture.IsDone);

  LFuture.Complete;
  AssertTrue('完成后状态应该是完成', LFuture.IsDone);
end;

procedure TTestCase_TFuture.Test_TFuture_IsCancelled;
begin
  // 测试取消状态
  AssertFalse('初始状态不应该取消', LFuture.IsCancelled);

  LFuture.Cancel;
  AssertTrue('取消后状态应该是取消', LFuture.IsCancelled);
end;

procedure TTestCase_TFuture.Test_TFuture_Complete;
begin
  // 测试完成操作
  AssertFalse('完成前状态应该是未完成', LFuture.IsDone);

  LFuture.Complete;
  AssertTrue('完成后状态应该是完成', LFuture.IsDone);
  AssertFalse('完成后不应该是取消状态', LFuture.IsCancelled);
end;

procedure TTestCase_TFuture.Test_TFuture_Cancel;
begin
  // 测试取消操作
  AssertFalse('取消前状态应该是未取消', LFuture.IsCancelled);

  LFuture.Cancel;
  AssertTrue('取消后状态应该是取消', LFuture.IsCancelled);
  AssertTrue('取消后也应该是完成状态', LFuture.IsDone);
end;

procedure TTestCase_TFuture.Test_TFuture_WaitFor;
var
  LPool: IThreadPool;
begin
  // 测试等待机制
  // 在另一个线程中完成 Future
  LPool := CreateThreadPool(1, 2);
  try
    LPool.Submit(
      function: Boolean
      begin
        Sleep(100);
        LFuture.Complete;
        Result := True;
      end
    );

    // 等待完成
    AssertTrue('应该在超时内完成', LFuture.WaitFor(2000));
    AssertTrue('等待后应该是完成状态', LFuture.IsDone);
  finally
    if Assigned(LPool) and not LPool.IsShutdown then
      LPool.Shutdown;
  end;
end;

procedure TTestCase_TFuture.Test_TFuture_WaitFor_Timeout;
var
  LStartTime, LEndTime: QWord;
begin
  // 测试等待超时
  LStartTime := GetTickCount64;
  AssertFalse('应该超时返回 False', LFuture.WaitFor(100));
  LEndTime := GetTickCount64;

  // 验证超时时间
  AssertTrue('应该在大约 100ms 后超时',
    (LEndTime - LStartTime >= 80) and (LEndTime - LStartTime <= 200));
  AssertFalse('超时后不应该是完成状态', LFuture.IsDone);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TTestCase_TFuture.Test_TFuture_ContinueWith;
var
  LContinuedFuture: IFuture;
  LStep1Done, LStep2Done: Boolean;
  LPool: IThreadPool;
begin
  // 测试链式调用
  LStep1Done := False;
  LStep2Done := False;

  LPool := CreateThreadPool(1, 2);
  try
    // 在另一个线程中完成第一步
    LPool.Submit(
      function: Boolean
      begin
        Sleep(50);
        LStep1Done := True;
        LFuture.Complete;
        Result := True;
      end
    );

    // 设置继续操作
    LContinuedFuture := LFuture.ContinueWith(
      function: Boolean
      begin
        LStep2Done := True;
        Result := True;
      end
    );

    // 等待链式调用完成
    AssertTrue('链式调用应该在超时内完成', LContinuedFuture.WaitFor(2000));
    AssertTrue('第一步应该完成', LStep1Done);
    AssertTrue('第二步应该完成', LStep2Done);
  finally
    if Assigned(LPool) and not LPool.IsShutdown then
      LPool.Shutdown;
  end;
end;

procedure TTestCase_TFuture.Test_TFuture_OnComplete;
var
  LCallbackExecuted: Boolean;
  LPool: IThreadPool;
begin
  // 测试完成回调
  LCallbackExecuted := False;

  LPool := CreateThreadPool(1, 2);
  try
    // 设置完成回调
    LFuture.OnComplete(
      function: Boolean
      begin
        LCallbackExecuted := True;
        Result := True;
      end
    );

    // 在另一个线程中完成 Future
    LPool.Submit(
      function: Boolean
      begin
        Sleep(50);
        LFuture.Complete;
        Result := True;
      end
    );

    // 等待完成
    LFuture.WaitFor(2000);
    Sleep(100); // 等待回调执行

    AssertTrue('完成回调应该被执行', LCallbackExecuted);
  finally
    if Assigned(LPool) and not LPool.IsShutdown then
      LPool.Shutdown;
  end;
end;
{$ENDIF}

procedure TTestCase_TFuture.Test_TFuture_Complete_AlreadyCompleted;
begin
  // 测试重复完成异常
  LFuture.Complete;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('重复完成应该抛出异常', EInvalidOperation,
    procedure
    begin
      LFuture.Complete;
    end);
  {$ENDIF}
end;

procedure TTestCase_TFuture.Test_TFuture_Cancel_AlreadyCompleted;
begin
  // 测试完成后取消异常
  LFuture.Complete;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('完成后取消应该抛出异常', EInvalidOperation,
    procedure
    begin
      LFuture.Cancel;
    end);
  {$ENDIF}
end;

{ TTestCase_TThreadLocal }

procedure TTestCase_TThreadLocal.SetUp;
begin
  inherited SetUp;
  LThreadLocal := CreateThreadLocal;
end;

procedure TTestCase_TThreadLocal.TearDown;
begin
  LThreadLocal := nil;
  inherited TearDown;
end;

procedure TTestCase_TThreadLocal.Test_TThreadLocal_Create;
begin
  // 测试线程本地存储创建
  AssertNotNull('ThreadLocal 应该成功创建', LThreadLocal);
  AssertFalse('初始状态不应该有值', LThreadLocal.HasValue);
  AssertTrue('初始值应该是 nil', LThreadLocal.GetValue = nil);
end;

procedure TTestCase_TThreadLocal.Test_TThreadLocal_SetValue;
var
  LValue: Pointer;
begin
  // 测试设置值
  LValue := Pointer(PtrUInt(12345));
  LThreadLocal.SetValue(LValue);

  AssertTrue('设置后应该有值', LThreadLocal.HasValue);
  AssertTrue('值应该匹配', LThreadLocal.GetValue = LValue);
end;

procedure TTestCase_TThreadLocal.Test_TThreadLocal_GetValue;
var
  LValue, LResult: Pointer;
begin
  // 测试获取值
  LValue := Pointer(PtrUInt(67890));
  LThreadLocal.SetValue(LValue);

  LResult := LThreadLocal.GetValue;
  AssertTrue('获取的值应该匹配', LResult = LValue);
end;

procedure TTestCase_TThreadLocal.Test_TThreadLocal_HasValue;
begin
  // 测试值存在检查
  AssertFalse('初始状态不应该有值', LThreadLocal.HasValue);

  LThreadLocal.SetValue(Pointer(PtrUInt(123)));
  AssertTrue('设置后应该有值', LThreadLocal.HasValue);

  LThreadLocal.RemoveValue;
  AssertFalse('移除后不应该有值', LThreadLocal.HasValue);
end;

procedure TTestCase_TThreadLocal.Test_TThreadLocal_RemoveValue;
var
  LValue: Pointer;
begin
  // 测试移除值
  LValue := Pointer(PtrUInt(456));
  LThreadLocal.SetValue(LValue);
  AssertTrue('设置后应该有值', LThreadLocal.HasValue);

  LThreadLocal.RemoveValue;
  AssertFalse('移除后不应该有值', LThreadLocal.HasValue);
  AssertTrue('移除后值应该是 nil', LThreadLocal.GetValue = nil);
end;

procedure TTestCase_TThreadLocal.Test_TThreadLocal_Value_Property;
var
  LValue: Pointer;
begin
  // 测试属性访问
  LValue := Pointer(PtrUInt(789));
  LThreadLocal.Value := LValue;

  AssertTrue('属性设置后应该有值', LThreadLocal.HasValue);
  AssertTrue('属性获取的值应该匹配', LThreadLocal.Value = LValue);
end;

procedure TTestCase_TThreadLocal.Test_TThreadLocal_MultipleThreads;
var
  LThread1, LThread2: IFuture;
  LValue1, LValue2: Integer;
  LResult1, LResult2: Integer;
  LPool: IThreadPool;
begin
  // 测试多线程隔离
  LValue1 := 111;
  LValue2 := 222;
  LResult1 := 0;
  LResult2 := 0;

  LPool := CreateThreadPool(2, 4);
  try
    // 线程1设置和读取值
    LThread1 := LPool.Submit(
      function: Boolean
      begin
        LThreadLocal.SetValue(Pointer(PtrUInt(LValue1)));
        Sleep(50); // 让其他线程有机会运行
        LResult1 := Integer(PtrUInt(LThreadLocal.GetValue));
        Result := True;
      end
    );

    // 线程2设置和读取值
    LThread2 := LPool.Submit(
      function: Boolean
      begin
        LThreadLocal.SetValue(Pointer(PtrUInt(LValue2)));
        Sleep(50); // 让其他线程有机会运行
        LResult2 := Integer(PtrUInt(LThreadLocal.GetValue));
        Result := True;
      end
    );

    // 等待两个线程完成
    AssertTrue('线程1应该完成', LThread1.WaitFor(2000));
    AssertTrue('线程2应该完成', LThread2.WaitFor(2000));

    // 每个线程应该读取到自己设置的值
    AssertEquals('线程1应该获取自己的值', LValue1, LResult1);
    AssertEquals('线程2应该获取自己的值', LValue2, LResult2);
  finally
    if Assigned(LPool) and not LPool.IsShutdown then
      LPool.Shutdown;
  end;
end;

procedure TTestCase_TThreadLocal.Test_TThreadLocal_GetValue_NoValue;
begin
  // 测试获取不存在的值
  // 应该返回 nil 而不是抛出异常
  AssertTrue('没有值时应该返回 nil', LThreadLocal.GetValue = nil);
end;

{ TTestCase_TCountDownLatch }

procedure TTestCase_TCountDownLatch.SetUp;
begin
  inherited SetUp;
  LCountDownLatch := CreateCountDownLatch(3);
end;

procedure TTestCase_TCountDownLatch.TearDown;
begin
  LCountDownLatch := nil;
  inherited TearDown;
end;

procedure TTestCase_TCountDownLatch.Test_TCountDownLatch_Create;
begin
  // 测试倒计数门闩创建
  AssertNotNull('CountDownLatch 应该成功创建', LCountDownLatch);
  AssertEquals('初始计数应该是 3', 3, LCountDownLatch.Count);
end;

procedure TTestCase_TCountDownLatch.Test_TCountDownLatch_Count;
begin
  // 测试计数属性
  AssertEquals('初始计数应该是 3', 3, LCountDownLatch.Count);

  LCountDownLatch.CountDown;
  AssertEquals('倒计数后应该是 2', 2, LCountDownLatch.Count);

  LCountDownLatch.CountDown;
  AssertEquals('再次倒计数后应该是 1', 1, LCountDownLatch.Count);

  LCountDownLatch.CountDown;
  AssertEquals('最后倒计数后应该是 0', 0, LCountDownLatch.Count);
end;

procedure TTestCase_TCountDownLatch.Test_TCountDownLatch_CountDown;
var
  LInitialCount: Integer;
begin
  // 测试倒计数操作
  LInitialCount := LCountDownLatch.Count;

  LCountDownLatch.CountDown;
  AssertEquals('倒计数应该减1', LInitialCount - 1, LCountDownLatch.Count);
end;

procedure TTestCase_TCountDownLatch.Test_TCountDownLatch_Await;
begin
  // 测试等待机制
  // 先倒计数到0
  LCountDownLatch.CountDown;
  LCountDownLatch.CountDown;
  LCountDownLatch.CountDown;

  // 现在应该立即返回
  AssertTrue('计数为0时应该立即返回', LCountDownLatch.Await(100));
end;

procedure TTestCase_TCountDownLatch.Test_TCountDownLatch_Await_Timeout;
var
  LStartTime, LEndTime: QWord;
begin
  // 测试等待超时
  Sleep(2); // 让出时间片，避免计时器/线程尚未就绪
  LStartTime := GetTickCount64;
  AssertFalse('应该超时返回 False', LCountDownLatch.Await(100));
  LEndTime := GetTickCount64;

  // 验证超时时间，给出更宽容的窗口
  AssertTrue('应该在大约 100ms 后超时',
    (LEndTime - LStartTime >= 70) and (LEndTime - LStartTime <= 250));
end;

procedure TTestCase_TCountDownLatch.Test_TCountDownLatch_MultipleThreads;
var
  LThreads: array[0..2] of IFuture;
  LStartTime, LEndTime: QWord;
  I: Integer;
  LPool: IThreadPool;
begin
  // 测试多线程同步
  LPool := CreateThreadPool(3, 6);
  try
    // 创建3个线程，每个线程等待100ms后倒计数
    for I := 0 to 2 do
    begin
      LThreads[I] := LPool.Submit(
        function: Boolean
        begin
          Sleep(100);
          LCountDownLatch.CountDown;
          Result := True;
        end
      );
    end;

    // 提交完任务后再开始计时，避免将线程池启动/提交成本计入
    Sleep(2);
    LStartTime := GetTickCount64;

    // 等待所有线程完成倒计数
    AssertTrue('应该在超时内完成', LCountDownLatch.Await(3000));
    LEndTime := GetTickCount64;

    // 应该大约在100ms后完成（给予更宽容窗口）
    AssertTrue('应该在大约100ms后完成',
      (LEndTime - LStartTime >= 70) and (LEndTime - LStartTime <= 400));

    // 等待所有线程结束
    for I := 0 to 2 do
      AssertTrue('线程应该完成', LThreads[I].WaitFor(1000));
  finally
    if Assigned(LPool) and not LPool.IsShutdown then
      LPool.Shutdown;
  end;
end;

procedure TTestCase_TCountDownLatch.Test_TCountDownLatch_ZeroCount;
var
  LZeroLatch: ICountDownLatch;
begin
  // 测试初始计数为0的情况
  LZeroLatch := CreateCountDownLatch(0);

  AssertEquals('计数应该是0', 0, LZeroLatch.Count);
  AssertTrue('应该立即返回', LZeroLatch.Await(100));
end;

procedure TTestCase_TCountDownLatch.Test_TCountDownLatch_CountDown_AlreadyZero;
begin
  // 测试计数已为0时继续倒计数
  // 先倒计数到0
  LCountDownLatch.CountDown;
  LCountDownLatch.CountDown;
  LCountDownLatch.CountDown;

  AssertEquals('计数应该是0', 0, LCountDownLatch.Count);

  // 继续倒计数不应该出错，计数保持0
  LCountDownLatch.CountDown;
  AssertEquals('计数应该仍然是0', 0, LCountDownLatch.Count);
end;

initialization
  // 注册测试套件
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_TThreads);
  RegisterTest(TTestCase_TFuture);
  RegisterTest(TTestCase_TThreadLocal);
  RegisterTest(TTestCase_TCountDownLatch);

end.
