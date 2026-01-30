unit fafafa.core.sync.once.testcase;

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
  fafafa.core.sync.once, fafafa.core.sync.once.base, fafafa.core.sync.base;

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
    procedure Test_MakeOnce_Basic;

    // Call 方法测试（Go/Rust 风格）
    procedure Test_Call_WithProc;
    procedure Test_Call_WithMethod;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure Test_Call_WithAnonymous;
    {$ENDIF}
    procedure Test_Call_Multiple_Calls;
    procedure Test_Call_Different_Callbacks;

    // CallForce 方法测试（毒化恢复）
    procedure Test_CallForce_After_Exception;
    procedure Test_CallForce_Ignores_Poison;

    // 等待机制测试
    procedure Test_Wait_Completed;
    procedure Test_Wait_Poisoned;
    procedure Test_WaitForce_Ignores_Poison;

    // 毒化状态测试
    procedure Test_Poisoned_State_After_Exception;
    procedure Test_IsPoisoned_Method;
    procedure Test_Poisoned_State_Persistence;
    procedure Test_Multiple_Exception_Calls;
    procedure Test_Poisoned_State_Thread_Safety;

    // 状态查询测试
    procedure Test_GetState_Basic;
    procedure Test_Completed_Property;

    // 并发测试
    procedure Test_Call_Concurrent_Basic;

    // Reset 功能已移除 - 不安全且不符合主流语言实践

    // 性能回归测试
    procedure Test_Performance_Fast_Path;
    procedure Test_Performance_Memory_Usage;

    // 内存泄漏测试
    procedure Test_Memory_Leak_Long_Running;
    procedure Test_Memory_Leak_Repeated_Creation;

    // 递归调用测试
    procedure Test_Recursive_Call_Detection;
    procedure Test_Recursive_Call_Different_Threads;
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
  CheckFalse(Once.Completed, '新创建的 Once 应该未完成');
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
procedure TTestCase_Once.Test_MakeOnce_Basic;
var
  Once: IOnce;
begin
  Once := MakeOnce;
  CheckNotNull(Once, 'MakeOnce 应该返回有效实例');
  CheckFalse(Once.Completed, '新创建的 Once 应该未完成');
  CheckFalse(Once.Poisoned, '新创建的 Once 不应该毒化');
  CheckEquals(Ord(osNotStarted), Ord(Once.GetState), '初始状态应该为未开始');
end;

// Call 方法测试（Go/Rust 风格）
procedure TTestCase_Once.Test_Call_WithProc;
var
  Once: IOnce;
begin
  Once := MakeOnce;
  CheckFalse(Once.Completed, '新创建的 Once 应该未完成');

  Once.Execute(@SimpleCallback);
  CheckEquals(1, FCallCount, '传入的过程应该被执行');
  CheckTrue(Once.Completed, '执行后应该标记为已完成');
  CheckEquals(Ord(osCompleted), Ord(Once.GetState), '执行后状态应该为已完成');
end;

procedure TTestCase_Once.Test_Call_WithMethod;
var
  Once: IOnce;
begin
  Once := MakeOnce;
  CheckFalse(Once.Completed, '新创建的 Once 应该未完成');

  Once.Execute(@SimpleCallback);
  CheckEquals(1, FCallCount, '传入的方法应该被执行');
  CheckTrue(Once.Completed, '执行后应该标记为已完成');
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TTestCase_Once.Test_Call_WithAnonymous;
var
  Once: IOnce;
  LocalCount: Integer;
begin
  LocalCount := 0;
  Once := MakeOnce;
  CheckFalse(Once.Completed, '新创建的 Once 应该未完成');

  Once.Execute(
    procedure
    begin
      Inc(LocalCount);
      Inc(FCallCount);
    end
  );

  CheckEquals(1, LocalCount, '匿名过程中的局部变量应该被修改');
  CheckEquals(1, FCallCount, '匿名过程应该被执行');
  CheckTrue(Once.Completed, '执行后应该标记为已完成');
end;
{$ENDIF}

procedure TTestCase_Once.Test_Call_Multiple_Calls;
var
  Once: IOnce;
begin
  Once := MakeOnce;

  // 第一次调用
  Once.Execute(@SimpleCallback);
  CheckEquals(1, FCallCount, '第一次调用应该执行');
  CheckTrue(Once.Completed, '第一次调用后应该完成');

  // 后续调用应该被忽略
  Once.Execute(@SimpleCallback);
  Once.Execute(@SimpleCallback);
  CheckEquals(1, FCallCount, '后续调用应该被忽略');
  CheckTrue(Once.Completed, '状态应该保持完成');
end;

procedure TTestCase_Once.Test_Call_Different_Callbacks;
var
  Once: IOnce;
  LocalCount: Integer;
begin
  LocalCount := 0;
  Once := MakeOnce;

  // 第一次调用过程
  Once.Execute(@SimpleCallback);
  CheckEquals(1, FCallCount, '第一次调用应该执行');
  CheckTrue(Once.Completed, '第一次调用后应该完成');

  // 后续调用不同的回调应该被忽略
  Once.Execute(@ValueSettingCallback);
  CheckEquals(1, FCallCount, '后续调用应该被忽略');
  CheckEquals(0, FLastValue, '后续回调不应该执行');

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  // 匿名过程也应该被忽略
  Once.Execute(
    procedure
    begin
      Inc(LocalCount);
    end
  );
  CheckEquals(0, LocalCount, '匿名过程也应该被忽略');
  {$ENDIF}
end;

// CallForce 方法测试（毒化恢复）
procedure TTestCase_Once.Test_CallForce_After_Exception;
var
  Once: IOnce;
begin
  Once := MakeOnce;

  // 第一次调用抛出异常，应该毒化
  try
    Once.Execute(@ExceptionCallback);
    Fail('应该抛出异常');
  except
    on E: Exception do
      CheckEquals('测试异常', E.Message, '应该是预期的异常');
  end;

  CheckTrue(Once.Poisoned, '异常后应该毒化');
  CheckEquals(Ord(osPoisoned), Ord(Once.GetState), '状态应该为毒化');

  // 普通调用应该失败
  try
    Once.Execute(@SimpleCallback);
    Fail('毒化状态下普通调用应该失败');
  except
    on E: ELockError do
      CheckTrue(Pos('poisoned', E.Message) > 0, '应该提示毒化状态');
  end;

  // CallForce 应该成功
  Once.ExecuteForce(@SimpleCallback);
  CheckEquals(2, FCallCount, 'CallForce 应该执行'); // ExceptionCallback + SimpleCallback
  CheckTrue(Once.Completed, 'CallForce 后应该完成');
  CheckFalse(Once.Poisoned, 'CallForce 后不应该毒化');
end;

procedure TTestCase_Once.Test_CallForce_Ignores_Poison;
var
  Once: IOnce;
begin
  Once := MakeOnce;

  // 先毒化
  try
    Once.Execute(@ExceptionCallback);
  except
    // 忽略异常
  end;

  CheckTrue(Once.Poisoned, '应该毒化');

  // CallForce 应该忽略毒化状态
  Once.ExecuteForce(@ValueSettingCallback);
  CheckEquals(42, FLastValue, 'CallForce 应该执行回调');
  CheckTrue(Once.Completed, 'CallForce 后应该完成');
  CheckFalse(Once.Poisoned, 'CallForce 后不应该毒化');
end;

// 等待机制测试
procedure TTestCase_Once.Test_Wait_Completed;
var
  Once: IOnce;
begin
  Once := MakeOnce;

  // 先完成执行
  Once.Execute(@SimpleCallback);
  CheckTrue(Once.Completed, '应该已完成');

  // Wait 应该立即返回
  Once.Wait;
  CheckTrue(Once.Completed, 'Wait 后应该仍然完成');
end;

procedure TTestCase_Once.Test_Wait_Poisoned;
var
  Once: IOnce;
begin
  Once := MakeOnce;

  // 先毒化
  try
    Once.Execute(@ExceptionCallback);
  except
    // 忽略异常
  end;

  CheckTrue(Once.Poisoned, '应该毒化');

  // Wait 应该抛出异常
  try
    Once.Wait;
    Fail('Wait 在毒化状态下应该抛出异常');
  except
    on E: ELockError do
      CheckTrue(Pos('poisoned', E.Message) > 0, '应该提示毒化状态');
  end;
end;

procedure TTestCase_Once.Test_WaitForce_Ignores_Poison;
var
  Once: IOnce;
begin
  Once := MakeOnce;

  // 先毒化
  try
    Once.Execute(@ExceptionCallback);
  except
    // 忽略异常
  end;

  CheckTrue(Once.Poisoned, '应该毒化');

  // WaitForce 应该忽略毒化状态
  Once.WaitForce;
  CheckTrue(Once.Poisoned, 'WaitForce 不改变毒化状态');
end;

// 毒化状态测试
procedure TTestCase_Once.Test_Poisoned_State_After_Exception;
var
  Once: IOnce;
begin
  Once := MakeOnce;
  CheckFalse(Once.Poisoned, '初始状态不应该毒化');

  // 执行抛出异常的回调
  try
    Once.Execute(@ExceptionCallback);
    Fail('应该抛出异常');
  except
    on E: Exception do
      CheckEquals('测试异常', E.Message, '应该是预期的异常');
  end;

  // 检查毒化状态
  CheckTrue(Once.Poisoned, '异常后应该毒化');
  CheckEquals(Ord(osPoisoned), Ord(Once.GetState), '状态应该为毒化');
  CheckFalse(Once.Completed, '毒化状态不等于完成状态');
end;

procedure TTestCase_Once.Test_IsPoisoned_Method;
var
  Once: IOnce;
begin
  Once := MakeOnce;

  // 初始状态
  CheckFalse(Once.Poisoned, '初始状态不应该毒化');

  // 正常执行
  Once.Execute(@SimpleCallback);
  CheckFalse(Once.Poisoned, '正常执行后不应该毒化');
  CheckTrue(Once.Completed, '正常执行后应该完成');

  // 创建新实例并测试异常（替代 Reset）
  Once := MakeOnce;
  try
    Once.Execute(@ExceptionCallback);
  except
    // 忽略异常
  end;

  CheckTrue(Once.Poisoned, '异常后应该毒化');
  CheckFalse(Once.Completed, '毒化状态不等于完成状态');
end;

procedure TTestCase_Once.Test_Poisoned_State_Persistence;
var
  Once: IOnce;
begin
  Once := MakeOnce;

  // 第一次异常调用
  try
    Once.Execute(@ExceptionCallback);
  except
    // 忽略异常
  end;

  CheckTrue(Once.Poisoned, '第一次异常后应该毒化');

  // 多次检查毒化状态应该保持
  CheckTrue(Once.Poisoned, '毒化状态应该持续');
  CheckTrue(Once.Poisoned, '毒化状态应该持续');
  CheckTrue(Once.Poisoned, '毒化状态应该持续');

  // 尝试正常调用应该失败
  try
    Once.Execute(@SimpleCallback);
    Fail('毒化状态下正常调用应该失败');
  except
    on E: ELockError do
      CheckTrue(Pos('poisoned', E.Message) > 0, '应该提示毒化状态');
  end;

  // 毒化状态应该仍然保持
  CheckTrue(Once.Poisoned, '正常调用失败后毒化状态应该保持');
end;

procedure TTestCase_Once.Test_Multiple_Exception_Calls;
var
  Once: IOnce;
  ExceptionCount: Integer;
begin
  Once := MakeOnce;
  ExceptionCount := 0;

  // 第一次异常调用
  try
    Once.Execute(@ExceptionCallback);
  except
    Inc(ExceptionCount);
  end;

  CheckEquals(1, ExceptionCount, '第一次异常应该被捕获');
  CheckTrue(Once.Poisoned, '第一次异常后应该毒化');

  // 后续调用应该立即失败，不执行回调
  try
    Once.Execute(@ExceptionCallback);
    Fail('毒化状态下调用应该立即失败');
  except
    on E: ELockError do
    begin
      Inc(ExceptionCount);
      CheckTrue(Pos('poisoned', E.Message) > 0, '应该提示毒化状态');
    end;
  end;

  CheckEquals(2, ExceptionCount, '第二次调用应该抛出毒化异常');
  CheckEquals(1, FCallCount, '回调应该只执行一次（第一次）');
end;

procedure TTestCase_Once.Test_Poisoned_State_Thread_Safety;
var
  Threads: array[0..3] of TOnceTestThread;
  i: Integer;
  Once: IOnce;
  ExceptionCount: Integer;
begin
  Once := MakeOnce;
  ExceptionCount := 0;

  // 创建多个线程同时调用会抛异常的回调
  for i := 0 to High(Threads) do
  begin
    Threads[i] := TOnceTestThread.Create(
      procedure
      begin
        try
          Once.Execute(@ExceptionCallback);
        except
          InterlockedIncrement(ExceptionCount);
        end;
      end
    );
  end;

  // 等待所有线程完成
  for i := 0 to High(Threads) do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;

  // 验证结果
  CheckTrue(Once.Poisoned, '多线程异常后应该毒化');
  CheckTrue(ExceptionCount >= 1, '至少应该有一个异常');
  CheckEquals(1, FCallCount, '回调应该只执行一次');

  // 验证毒化状态在所有线程中都可见
  try
    Once.Execute(@SimpleCallback);
    Fail('毒化状态下调用应该失败');
  except
    on E: ELockError do
      CheckTrue(Pos('poisoned', E.Message) > 0, '应该提示毒化状态');
  end;
end;



// 状态查询测试
procedure TTestCase_Once.Test_GetState_Basic;
var
  Once: IOnce;
begin
  Once := MakeOnce;

  // 初始状态
  CheckEquals(Ord(osNotStarted), Ord(Once.GetState), '初始状态应该为未开始');

  // 执行后状态
  Once.Execute(@SimpleCallback);
  CheckEquals(Ord(osCompleted), Ord(Once.GetState), '执行后状态应该为已完成');

  // 创建新实例测试初始状态（替代 Reset）
  Once := MakeOnce;
  CheckEquals(Ord(osNotStarted), Ord(Once.GetState), '新实例状态应该为未开始');
end;

procedure TTestCase_Once.Test_Completed_Property;
var
  Once: IOnce;
begin
  Once := MakeOnce;

  // 初始状态
  CheckFalse(Once.Completed, '初始状态不应该为已完成');

  // 执行后状态
  Once.Execute(@SimpleCallback);
  CheckTrue(Once.Completed, '执行后应该为已完成');

  // 创建新实例测试初始状态（替代 Reset）
  Once := MakeOnce;
  CheckFalse(Once.Completed, '新实例不应该为已完成');
end;

// 并发测试
procedure TTestCase_Once.Test_Call_Concurrent_Basic;
var
  Threads: array[0..4] of TOnceTestThread;
  i: Integer;
  Once: IOnce;
begin
  Once := MakeOnce;

  for i := 0 to High(Threads) do
  begin
    Threads[i] := TOnceTestThread.Create(
      procedure
      begin
        Once.Execute(@CountingCallback);
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
  CheckTrue(Once.Completed, 'Once 应该标记为已完成');
end;

// Reset 功能测试已移除 - Reset 不安全且不符合主流语言实践
// 如需重新执行，请创建新的 Once 实例

// 性能回归测试
procedure TTestCase_Once.Test_Performance_Fast_Path;
var
  Once: IOnce;
  i: Integer;
  StartTime, EndTime: TDateTime;
  ElapsedMs: Double;
const
  ITERATIONS = 1000000; // 100万次迭代
begin
  Once := MakeOnce;

  // 先执行一次，进入快速路径状态
  Once.Execute(@SimpleCallback);
  CheckTrue(Once.Completed, '应该已完成');

  // 测试快速路径性能
  StartTime := Now;
  for i := 1 to ITERATIONS do
  begin
    Once.Execute(@SimpleCallback); // 这些调用都走快速路径
  end;
  EndTime := Now;

  ElapsedMs := (EndTime - StartTime) * 24 * 60 * 60 * 1000;

  // 性能断言：快速路径应该非常快（每次调用 < 100 纳秒）
  CheckTrue(ElapsedMs < 100, Format('快速路径性能回归：%d 次调用耗时 %.2f ms', [ITERATIONS, ElapsedMs]));

  // 验证功能正确性
  CheckEquals(1, FCallCount, '快速路径不应该重复执行回调');
  CheckTrue(Once.Completed, '状态应该保持完成');
end;

procedure TTestCase_Once.Test_Performance_Memory_Usage;
var
  OnceArray: array[0..999] of IOnce;
  i: Integer;
  MemBefore, MemAfter: PtrUInt;
  MemUsed: PtrUInt;
begin
  // 强制垃圾回收
  {$IFDEF FPC}
  // FPC 没有显式的垃圾回收，但我们可以测量内存使用
  {$ENDIF}

  MemBefore := GetHeapStatus.TotalAllocated;

  // 创建 1000 个 Once 实例
  for i := 0 to High(OnceArray) do
  begin
    OnceArray[i] := MakeOnce;
  end;

  MemAfter := GetHeapStatus.TotalAllocated;
  MemUsed := MemAfter - MemBefore;

  // 内存使用断言：每个实例应该 < 500 字节（包含缓存行对齐）
  CheckTrue(MemUsed < 500000, Format('内存使用过多：1000 个实例使用 %d 字节', [MemUsed]));

  // 验证功能正确性
  for i := 0 to High(OnceArray) do
  begin
    CheckNotNull(OnceArray[i], Format('实例 %d 应该有效', [i]));
    CheckFalse(OnceArray[i].Completed, Format('实例 %d 应该未完成', [i]));
  end;

  // 清理
  for i := 0 to High(OnceArray) do
  begin
    OnceArray[i] := nil;
  end;
end;

// 内存泄漏测试
procedure TTestCase_Once.Test_Memory_Leak_Long_Running;
var
  Once: IOnce;
  i: Integer;
  MemBefore, MemAfter: PtrUInt;
const
  LONG_ITERATIONS = 100000; // 10万次迭代
begin
  Once := MakeOnce;
  Once.Execute(@SimpleCallback); // 先执行一次

  MemBefore := GetHeapStatus.TotalAllocated;

  // 长时间运行快速路径
  for i := 1 to LONG_ITERATIONS do
  begin
    Once.Execute(@SimpleCallback);

    // 每 10000 次检查一次状态
    if (i mod 10000) = 0 then
    begin
      CheckTrue(Once.Completed, Format('第 %d 次迭代后应该仍然完成', [i]));
      CheckFalse(Once.Poisoned, Format('第 %d 次迭代后不应该毒化', [i]));
    end;
  end;

  MemAfter := GetHeapStatus.TotalAllocated;

  // 内存泄漏检查：长时间运行不应该增加内存使用
  CheckTrue(MemAfter - MemBefore < 1024,
    Format('内存泄漏：长时间运行增加了 %d 字节内存', [MemAfter - MemBefore]));

  // 功能验证
  CheckEquals(1, FCallCount, '长时间运行不应该重复执行回调');
  CheckTrue(Once.Completed, '最终状态应该完成');
end;

procedure TTestCase_Once.Test_Memory_Leak_Repeated_Creation;
var
  i: Integer;
  MemBefore, MemAfter, MemPeak, CurrentMem: PtrUInt;
  Once: IOnce;
const
  CREATION_ITERATIONS = 10000; // 1万次创建
begin
  MemBefore := GetHeapStatus.TotalAllocated;
  MemPeak := MemBefore;

  // 重复创建和销毁 Once 实例
  for i := 1 to CREATION_ITERATIONS do
  begin
    Once := MakeOnce;
    Once.Execute(@SimpleCallback);

    CheckTrue(Once.Completed, Format('第 %d 个实例应该完成', [i]));

    // 每 1000 次检查内存使用
    if (i mod 1000) = 0 then
    begin
      CurrentMem := GetHeapStatus.TotalAllocated;
      if CurrentMem > MemPeak then
        MemPeak := CurrentMem;
    end;

    Once := nil; // 显式释放
  end;

  // 强制垃圾回收（如果支持）
  {$IFDEF FPC}
  // FPC 使用引用计数，应该立即释放
  {$ENDIF}

  MemAfter := GetHeapStatus.TotalAllocated;

  // 内存泄漏检查：重复创建不应该持续增加内存
  CheckTrue(MemAfter - MemBefore < 10240,
    Format('内存泄漏：重复创建增加了 %d 字节内存', [MemAfter - MemBefore]));

  // 峰值内存检查：不应该过度增长
  CheckTrue(MemPeak - MemBefore < 100000,
    Format('内存峰值过高：峰值增加了 %d 字节', [MemPeak - MemBefore]));
end;

// 递归调用测试
procedure TTestCase_Once.Test_Recursive_Call_Detection;
var
  Once: IOnce;
  RecursiveCallDetected: Boolean;
  OuterCallExecuted: Boolean;
begin
  Once := MakeOnce;
  RecursiveCallDetected := False;
  OuterCallExecuted := False;

  // 使用过程指针而不是匿名过程，避免复杂的异常传播
  try
    Once.Execute(
      procedure
      begin
        OuterCallExecuted := True;
        Inc(FCallCount);

        // 尝试递归调用 - 应该抛出异常
        try
          Once.Execute(@SimpleCallback);
          // 如果到这里，说明递归调用没有被检测到
          Fail('递归调用应该被检测并抛出异常');
        except
          on E: EOnceRecursiveCall do
          begin
            RecursiveCallDetected := True;
            CheckTrue(Pos('Recursive call', E.Message) > 0, '异常消息应该提示递归调用');
            // 不重新抛出，让外层正常完成
          end;
        end;
      end
    );
  except
    on E: Exception do
    begin
      // 如果外层也抛出异常，记录但不失败测试
      WriteLn('外层异常: ', E.Message);
    end;
  end;

  // 验证结果
  CheckTrue(OuterCallExecuted, '外层回调应该被执行');
  CheckTrue(RecursiveCallDetected, '应该检测到递归调用');
  CheckEquals(1, FCallCount, '只有外层回调应该执行');

  // 验证 Once 最终状态
  CheckTrue(Once.Completed, '递归调用被阻止后，Once 应该正常完成');
  CheckFalse(Once.Poisoned, '递归调用检测不应该导致毒化');
end;

procedure TTestCase_Once.Test_Recursive_Call_Different_Threads;
var
  Once: IOnce;
  Thread1, Thread2: TOnceTestThread;
  Thread1Exception, Thread2Exception: Exception;
begin
  Once := MakeOnce;
  Thread1Exception := nil;
  Thread2Exception := nil;

  // 第一个线程：正常执行
  Thread1 := TOnceTestThread.Create(
    procedure
    begin
      try
        Once.Execute(@SimpleCallback);
      except
        on E: Exception do
          Thread1Exception := Exception.Create(E.Message);
      end;
    end
  );

  // 第二个线程：也尝试执行（应该被阻塞或快速返回）
  Thread2 := TOnceTestThread.Create(
    procedure
    begin
      try
        Sleep(10); // 稍微延迟，让第一个线程先开始
        Once.Execute(@SimpleCallback);
      except
        on E: Exception do
          Thread2Exception := Exception.Create(E.Message);
      end;
    end
  );

  // 等待两个线程完成
  Thread1.WaitFor;
  Thread2.WaitFor;

  // 清理
  Thread1.Free;
  Thread2.Free;

  // 验证结果
  CheckNull(Thread1Exception, '第一个线程不应该有异常');
  CheckNull(Thread2Exception, '第二个线程不应该有异常');
  CheckEquals(1, FCallCount, '回调应该只执行一次');
  CheckTrue(Once.Completed, '不同线程调用不是递归调用，应该正常完成');

  // 清理异常对象
  if Assigned(Thread1Exception) then
    Thread1Exception.Free;
  if Assigned(Thread2Exception) then
    Thread2Exception.Free;
end;

initialization
  RegisterTest(TTestCase_Once_Global);
  RegisterTest(TTestCase_Once);

end.
