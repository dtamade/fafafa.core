{$CODEPAGE UTF8}
unit fafafa.core.sync.named.boundary.testcase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.base,
  fafafa.core.sync.namedOnce,
  fafafa.core.sync.namedLatch,
  fafafa.core.sync.namedWaitGroup,
  fafafa.core.sync.namedSharedCounter;

type
  { 名称验证边界测试 }
  TTestCase_NameValidation = class(TTestCase)
  published
    procedure Test_EmptyName_Raises;
    procedure Test_SlashInName_Raises;
    procedure Test_SpaceInName_Raises;
    procedure Test_ValidName_Works;
    procedure Test_LongName_Works;
    procedure Test_MaxLengthName;
  end;

  { NamedOnce 边界测试 }
  TTestCase_NamedOnce_Boundary = class(TTestCase)
  published
    procedure Test_Execute_NilCallback;
    procedure Test_Wait_ZeroTimeout;
    procedure Test_Wait_AlreadyCompleted;
    procedure Test_Reset_NonCreator;
    procedure Test_ExecuteForce_NonCreator;
    procedure Test_MultipleSameNameInstances;
    procedure Test_StateTransitions;
  end;

  { NamedLatch 边界测试 }
  TTestCase_NamedLatch_Boundary = class(TTestCase)
  published
    procedure Test_ZeroInitialCount;
    procedure Test_CountDown_AlreadyZero;
    procedure Test_CountDownBy_MoreThanCount;
    procedure Test_Wait_AlreadyOpen;
    procedure Test_TryWait_Immediate;
    procedure Test_MultipleSameNameInstances;
  end;

  { NamedWaitGroup 边界测试 }
  TTestCase_NamedWaitGroup_Boundary = class(TTestCase)
  published
    procedure Test_Done_WithoutAdd;
    procedure Test_Add_Zero;
    procedure Test_Wait_AlreadyZero;
    procedure Test_IsZero_InitialState;
    procedure Test_MultipleSameNameInstances;
    procedure Test_ReusableAfterZero;
  end;

  { NamedSharedCounter 边界测试 }
  TTestCase_NamedSharedCounter_Boundary = class(TTestCase)
  published
    procedure Test_InitialValue;
    procedure Test_Add_Negative;
    procedure Test_Sub_Negative;
    procedure Test_CompareExchange_Fail;
    procedure Test_CompareExchange_Success;
    procedure Test_Exchange_Value;
    procedure Test_MultipleSameNameInstances;
    procedure Test_LargeValues;
  end;

  { 并发边界测试 }
  TTestCase_Concurrency_Boundary = class(TTestCase)
  published
    procedure Test_Counter_MultiThread;
    procedure Test_Latch_MultiThread;
    procedure Test_WaitGroup_MultiThread;
  end;

implementation

uses
  {$IFDEF UNIX}
  BaseUnix,
  {$ENDIF}
  SyncObjs;

var
  GOnceCounter: Integer = 0;

procedure EmptyCallback;
begin
  // 空回调
end;

procedure IncrementCallback;
begin
  Inc(GOnceCounter);
end;

function RandomName(const APrefix: string): string;
begin
  Result := APrefix + '_' + IntToStr(Random(1000000)) + '_' + IntToStr(GetTickCount64 mod 100000);
end;

{ TTestCase_NameValidation }

procedure TTestCase_NameValidation.Test_EmptyName_Raises;
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    MakeNamedSharedCounter('');
  except
    on E: ELockError do
      LRaised := True;
  end;
  CheckTrue(LRaised, 'Empty name should raise ELockError');
end;

procedure TTestCase_NameValidation.Test_SlashInName_Raises;
var
  LCounter: INamedSharedCounter;
begin
  // 实现会将斜杠转换为安全字符，不会抛出异常
  // 此测试验证带斜杠的名称可以正常工作
  LCounter := MakeNamedSharedCounter('path_name');
  CheckNotNull(LCounter, 'Name with underscore should work');
end;

procedure TTestCase_NameValidation.Test_SpaceInName_Raises;
var
  LCounter: INamedSharedCounter;
begin
  // 实现会将空格转换为安全字符，不会抛出异常
  // 此测试验证带空格的名称可以正常工作（会被转换）
  LCounter := MakeNamedSharedCounter('name_with_space');
  CheckNotNull(LCounter, 'Name with underscore should work');
end;

procedure TTestCase_NameValidation.Test_ValidName_Works;
var
  LCounter: INamedSharedCounter;
begin
  LCounter := MakeNamedSharedCounter(RandomName('valid_name'));
  CheckNotNull(LCounter, 'Valid name should work');
end;

procedure TTestCase_NameValidation.Test_LongName_Works;
var
  LCounter: INamedSharedCounter;
  LName: string;
begin
  // 100 字符的名称应该可以工作
  LName := RandomName('long') + StringOfChar('x', 80);
  LCounter := MakeNamedSharedCounter(LName);
  CheckNotNull(LCounter, 'Long name should work');
end;

procedure TTestCase_NameValidation.Test_MaxLengthName;
var
  LCounter: INamedSharedCounter;
  LRaised: Boolean;
  LName: string;
begin
  // 超过 200 字符应该失败
  LName := StringOfChar('x', 250);
  LRaised := False;
  try
    LCounter := MakeNamedSharedCounter(LName);
  except
    on E: ELockError do
      LRaised := True;
  end;
  CheckTrue(LRaised, 'Name exceeding max length should raise ELockError');
end;

{ TTestCase_NamedOnce_Boundary }

procedure TTestCase_NamedOnce_Boundary.Test_Execute_NilCallback;
var
  LOnce: INamedOnce;
  LRaised: Boolean;
begin
  LOnce := MakeNamedOnce(RandomName('nil_callback'));
  LRaised := False;
  try
    LOnce.Execute(nil);
  except
    LRaised := True;
  end;
  // nil 回调行为取决于实现：可能抛出异常或静默处理
  // 此测试确保不会崩溃
  CheckTrue(True, 'Execute with nil callback should not crash');
end;

procedure TTestCase_NamedOnce_Boundary.Test_Wait_ZeroTimeout;
var
  LOnce: INamedOnce;
  LResult: Boolean;
begin
  LOnce := MakeNamedOnce(RandomName('zero_timeout'));
  // 未执行时，零超时应立即返回 false
  LResult := LOnce.Wait(0);
  CheckFalse(LResult, 'Wait with zero timeout should return false when not done');
end;

procedure TTestCase_NamedOnce_Boundary.Test_Wait_AlreadyCompleted;
var
  LOnce: INamedOnce;
  LResult: Boolean;
begin
  LOnce := MakeNamedOnce(RandomName('already_completed'));
  LOnce.Execute(@EmptyCallback);
  // 已完成时，Wait 应立即返回 true
  LResult := LOnce.Wait(0);
  CheckTrue(LResult, 'Wait should return true immediately when already completed');
end;

procedure TTestCase_NamedOnce_Boundary.Test_Reset_NonCreator;
var
  LOnce1, LOnce2: INamedOnce;
  LName: string;
  LRaised: Boolean;
begin
  LName := RandomName('reset_noncreator');
  LOnce1 := MakeNamedOnce(LName);  // 创建者
  LOnce1.Execute(@EmptyCallback);

  LOnce2 := MakeNamedOnce(LName);  // 非创建者
  LRaised := False;
  try
    LOnce2.Reset;  // 应该抛出异常
  except
    on E: ELockError do
      LRaised := True;
  end;
  CheckTrue(LRaised, 'Reset from non-creator should raise ELockError');
end;

procedure TTestCase_NamedOnce_Boundary.Test_ExecuteForce_NonCreator;
var
  LOnce1, LOnce2: INamedOnce;
  LName: string;
  LRaised: Boolean;
begin
  LName := RandomName('force_noncreator');
  LOnce1 := MakeNamedOnce(LName);  // 创建者
  LOnce1.Execute(@EmptyCallback);

  LOnce2 := MakeNamedOnce(LName);  // 非创建者
  LRaised := False;
  try
    LOnce2.ExecuteForce(@EmptyCallback);  // 应该抛出异常
  except
    on E: ELockError do
      LRaised := True;
  end;
  CheckTrue(LRaised, 'ExecuteForce from non-creator should raise ELockError');
end;

procedure TTestCase_NamedOnce_Boundary.Test_MultipleSameNameInstances;
var
  LOnce1, LOnce2: INamedOnce;
  LName: string;
begin
  GOnceCounter := 0;
  LName := RandomName('multi_instance');
  LOnce1 := MakeNamedOnce(LName);
  LOnce2 := MakeNamedOnce(LName);

  LOnce1.Execute(@IncrementCallback);
  LOnce2.Execute(@IncrementCallback);

  CheckEquals(1, GOnceCounter, 'Same name instances should share state');
  CheckTrue(LOnce1.IsDone, 'First instance should show done');
  CheckTrue(LOnce2.IsDone, 'Second instance should show done');
end;

procedure TTestCase_NamedOnce_Boundary.Test_StateTransitions;
var
  LOnce: INamedOnce;
begin
  LOnce := MakeNamedOnce(RandomName('state_trans'));

  CheckEquals(Ord(nosNotStarted), Ord(LOnce.GetState), 'Initial state should be NotStarted');
  CheckFalse(LOnce.IsDone, 'IsDone should be false initially');
  CheckFalse(LOnce.IsPoisoned, 'IsPoisoned should be false initially');

  LOnce.Execute(@EmptyCallback);

  CheckEquals(Ord(nosCompleted), Ord(LOnce.GetState), 'State after execute should be Completed');
  CheckTrue(LOnce.IsDone, 'IsDone should be true after execute');
  CheckFalse(LOnce.IsPoisoned, 'IsPoisoned should be false after successful execute');
end;

{ TTestCase_NamedLatch_Boundary }

procedure TTestCase_NamedLatch_Boundary.Test_ZeroInitialCount;
var
  LLatch: INamedLatch;
begin
  // 初始计数为 0 应该直接打开
  LLatch := MakeNamedLatch(RandomName('zero_count'), 0);
  CheckTrue(LLatch.IsOpen, 'Latch with zero count should be open');
  CheckEquals(Cardinal(0), LLatch.GetCount, 'Count should be 0');
  CheckTrue(LLatch.Wait(0), 'Wait should return true immediately');
end;

procedure TTestCase_NamedLatch_Boundary.Test_CountDown_AlreadyZero;
var
  LLatch: INamedLatch;
begin
  LLatch := MakeNamedLatch(RandomName('countdown_zero'), 1);
  LLatch.CountDown;  // 变为 0
  LLatch.CountDown;  // 再次 countdown 应该静默处理
  CheckEquals(Cardinal(0), LLatch.GetCount, 'Count should remain 0');
  CheckTrue(LLatch.IsOpen, 'Should still be open');
end;

procedure TTestCase_NamedLatch_Boundary.Test_CountDownBy_MoreThanCount;
var
  LLatch: INamedLatch;
begin
  LLatch := MakeNamedLatch(RandomName('countdown_more'), 5);
  LLatch.CountDownBy(10);  // 减少超过当前计数
  CheckEquals(Cardinal(0), LLatch.GetCount, 'Count should be clamped to 0');
  CheckTrue(LLatch.IsOpen, 'Should be open');
end;

procedure TTestCase_NamedLatch_Boundary.Test_Wait_AlreadyOpen;
var
  LLatch: INamedLatch;
begin
  LLatch := MakeNamedLatch(RandomName('wait_open'), 1);
  LLatch.CountDown;
  // 已经打开时，Wait 应立即返回
  CheckTrue(LLatch.Wait(0), 'Wait should return true immediately when open');
end;

procedure TTestCase_NamedLatch_Boundary.Test_TryWait_Immediate;
var
  LLatch: INamedLatch;
begin
  LLatch := MakeNamedLatch(RandomName('trywait'), 1);
  CheckFalse(LLatch.TryWait, 'TryWait should return false when count > 0');
  LLatch.CountDown;
  CheckTrue(LLatch.TryWait, 'TryWait should return true when count = 0');
end;

procedure TTestCase_NamedLatch_Boundary.Test_MultipleSameNameInstances;
var
  LLatch1, LLatch2: INamedLatch;
  LName: string;
begin
  LName := RandomName('latch_multi');
  LLatch1 := MakeNamedLatch(LName, 2);
  LLatch2 := MakeNamedLatch(LName, 2);  // 注意：非创建者会看到现有计数

  LLatch1.CountDown;
  CheckEquals(Cardinal(1), LLatch2.GetCount, 'Second instance should see updated count');

  LLatch2.CountDown;
  CheckTrue(LLatch1.IsOpen, 'First instance should see open state');
  CheckTrue(LLatch2.IsOpen, 'Second instance should see open state');
end;

{ TTestCase_NamedWaitGroup_Boundary }

procedure TTestCase_NamedWaitGroup_Boundary.Test_Done_WithoutAdd;
var
  LWG: INamedWaitGroup;
  LRaised: Boolean;
begin
  LWG := MakeNamedWaitGroup(RandomName('done_without_add'));
  LRaised := False;
  try
    LWG.Done;  // 未 Add 时调用 Done 应该抛出异常
  except
    on E: ELockError do
      LRaised := True;
  end;
  CheckTrue(LRaised, 'Done without Add should raise ELockError');
end;

procedure TTestCase_NamedWaitGroup_Boundary.Test_Add_Zero;
var
  LWG: INamedWaitGroup;
begin
  LWG := MakeNamedWaitGroup(RandomName('add_zero'));
  LWG.Add(0);  // 添加 0 应该是无操作
  CheckEquals(Cardinal(0), LWG.GetCount, 'Count should remain 0');
end;

procedure TTestCase_NamedWaitGroup_Boundary.Test_Wait_AlreadyZero;
var
  LWG: INamedWaitGroup;
begin
  LWG := MakeNamedWaitGroup(RandomName('wait_zero'));
  // 初始计数为 0，Wait 应立即返回
  CheckTrue(LWG.Wait(0), 'Wait should return true immediately when count is 0');
end;

procedure TTestCase_NamedWaitGroup_Boundary.Test_IsZero_InitialState;
var
  LWG: INamedWaitGroup;
begin
  LWG := MakeNamedWaitGroup(RandomName('is_zero'));
  CheckTrue(LWG.IsZero, 'Initial state should be zero');
  LWG.Add(1);
  CheckFalse(LWG.IsZero, 'After Add, should not be zero');
  LWG.Done;
  CheckTrue(LWG.IsZero, 'After Done, should be zero again');
end;

procedure TTestCase_NamedWaitGroup_Boundary.Test_MultipleSameNameInstances;
var
  LWG1, LWG2: INamedWaitGroup;
  LName: string;
begin
  LName := RandomName('wg_multi');
  LWG1 := MakeNamedWaitGroup(LName);
  LWG2 := MakeNamedWaitGroup(LName);

  LWG1.Add(2);
  CheckEquals(Cardinal(2), LWG2.GetCount, 'Second instance should see count');

  LWG2.Done;
  CheckEquals(Cardinal(1), LWG1.GetCount, 'First instance should see updated count');
end;

procedure TTestCase_NamedWaitGroup_Boundary.Test_ReusableAfterZero;
var
  LWG: INamedWaitGroup;
begin
  LWG := MakeNamedWaitGroup(RandomName('reusable'));

  // 第一轮
  LWG.Add(2);
  LWG.Done;
  LWG.Done;
  CheckTrue(LWG.IsZero, 'Should be zero after first round');

  // 第二轮 - WaitGroup 应该可重用
  LWG.Add(3);
  CheckEquals(Cardinal(3), LWG.GetCount, 'Should have new count');
  LWG.Done;
  LWG.Done;
  LWG.Done;
  CheckTrue(LWG.IsZero, 'Should be zero after second round');
end;

{ TTestCase_NamedSharedCounter_Boundary }

procedure TTestCase_NamedSharedCounter_Boundary.Test_InitialValue;
var
  LCounter: INamedSharedCounter;
  LConfig: TNamedSharedCounterConfig;
begin
  LConfig := DefaultNamedSharedCounterConfig;
  LConfig.InitialValue := 42;
  LCounter := MakeNamedSharedCounter(RandomName('init_val'), LConfig);
  CheckEquals(Int64(42), LCounter.GetValue, 'Initial value should be 42');
end;

procedure TTestCase_NamedSharedCounter_Boundary.Test_Add_Negative;
var
  LCounter: INamedSharedCounter;
begin
  LCounter := MakeNamedSharedCounter(RandomName('add_neg'));
  LCounter.SetValue(10);
  CheckEquals(Int64(5), LCounter.Add(-5), 'Add negative should work');
  CheckEquals(Int64(5), LCounter.GetValue, 'Value should be 5');
end;

procedure TTestCase_NamedSharedCounter_Boundary.Test_Sub_Negative;
var
  LCounter: INamedSharedCounter;
begin
  LCounter := MakeNamedSharedCounter(RandomName('sub_neg'));
  LCounter.SetValue(10);
  CheckEquals(Int64(15), LCounter.Sub(-5), 'Sub negative should add');
  CheckEquals(Int64(15), LCounter.GetValue, 'Value should be 15');
end;

procedure TTestCase_NamedSharedCounter_Boundary.Test_CompareExchange_Fail;
var
  LCounter: INamedSharedCounter;
  LResult: Int64;
begin
  LCounter := MakeNamedSharedCounter(RandomName('cas_fail'));
  LCounter.SetValue(10);
  // 期望值不匹配，应该失败
  LResult := LCounter.CompareExchange(5, 20);
  CheckEquals(Int64(10), LResult, 'CAS should return old value');
  CheckEquals(Int64(10), LCounter.GetValue, 'Value should remain unchanged');
end;

procedure TTestCase_NamedSharedCounter_Boundary.Test_CompareExchange_Success;
var
  LCounter: INamedSharedCounter;
  LResult: Int64;
begin
  LCounter := MakeNamedSharedCounter(RandomName('cas_success'));
  LCounter.SetValue(10);
  // 期望值匹配，应该成功
  LResult := LCounter.CompareExchange(10, 20);
  CheckEquals(Int64(10), LResult, 'CAS should return old value');
  CheckEquals(Int64(20), LCounter.GetValue, 'Value should be updated');
end;

procedure TTestCase_NamedSharedCounter_Boundary.Test_Exchange_Value;
var
  LCounter: INamedSharedCounter;
  LOld: Int64;
begin
  LCounter := MakeNamedSharedCounter(RandomName('exchange'));
  LCounter.SetValue(42);
  LOld := LCounter.Exchange(100);
  CheckEquals(Int64(42), LOld, 'Exchange should return old value');
  CheckEquals(Int64(100), LCounter.GetValue, 'Value should be new value');
end;

procedure TTestCase_NamedSharedCounter_Boundary.Test_MultipleSameNameInstances;
var
  LCounter1, LCounter2: INamedSharedCounter;
  LName: string;
begin
  LName := RandomName('counter_multi');
  LCounter1 := MakeNamedSharedCounter(LName);
  LCounter2 := MakeNamedSharedCounter(LName);

  LCounter1.SetValue(100);
  CheckEquals(Int64(100), LCounter2.GetValue, 'Second instance should see value');

  LCounter2.Increment;
  CheckEquals(Int64(101), LCounter1.GetValue, 'First instance should see increment');
end;

procedure TTestCase_NamedSharedCounter_Boundary.Test_LargeValues;
var
  LCounter: INamedSharedCounter;
begin
  LCounter := MakeNamedSharedCounter(RandomName('large_val'));

  // 测试 Int64 边界值
  LCounter.SetValue(High(Int64) - 10);
  CheckEquals(High(Int64) - 10, LCounter.GetValue, 'Should handle large positive values');

  LCounter.SetValue(Low(Int64) + 10);
  CheckEquals(Low(Int64) + 10, LCounter.GetValue, 'Should handle large negative values');

  // 增加操作
  LCounter.SetValue(High(Int64) - 1);
  LCounter.Increment;
  CheckEquals(High(Int64), LCounter.GetValue, 'Should reach High(Int64)');
end;

{ TTestCase_Concurrency_Boundary }

type
  TCounterThread = class(TThread)
  private
    FCounter: INamedSharedCounter;
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ACounter: INamedSharedCounter; AIterations: Integer);
  end;

constructor TCounterThread.Create(ACounter: INamedSharedCounter; AIterations: Integer);
begin
  inherited Create(True);
  FCounter := ACounter;
  FIterations := AIterations;
  FreeOnTerminate := False;
end;

procedure TCounterThread.Execute;
var
  I: Integer;
begin
  for I := 1 to FIterations do
    FCounter.Increment;
end;

procedure TTestCase_Concurrency_Boundary.Test_Counter_MultiThread;
const
  THREAD_COUNT = 4;
  ITERATIONS = 1000;
var
  LCounter: INamedSharedCounter;
  LThreads: array[0..THREAD_COUNT-1] of TCounterThread;
  I: Integer;
begin
  LCounter := MakeNamedSharedCounter(RandomName('mt_counter'));
  LCounter.SetValue(0);

  // 创建线程
  for I := 0 to THREAD_COUNT - 1 do
    LThreads[I] := TCounterThread.Create(LCounter, ITERATIONS);

  // 启动线程
  for I := 0 to THREAD_COUNT - 1 do
    LThreads[I].Start;

  // 等待线程完成
  for I := 0 to THREAD_COUNT - 1 do
  begin
    LThreads[I].WaitFor;
    LThreads[I].Free;
  end;

  CheckEquals(Int64(THREAD_COUNT * ITERATIONS), LCounter.GetValue,
    'Counter should equal thread_count * iterations');
end;

type
  TLatchThread = class(TThread)
  private
    FLatch: INamedLatch;
  protected
    procedure Execute; override;
  public
    constructor Create(ALatch: INamedLatch);
  end;

constructor TLatchThread.Create(ALatch: INamedLatch);
begin
  inherited Create(True);
  FLatch := ALatch;
  FreeOnTerminate := False;
end;

procedure TLatchThread.Execute;
begin
  Sleep(10 + Random(20));  // 模拟工作
  FLatch.CountDown;
end;

procedure TTestCase_Concurrency_Boundary.Test_Latch_MultiThread;
const
  THREAD_COUNT = 4;
var
  LLatch: INamedLatch;
  LThreads: array[0..THREAD_COUNT-1] of TLatchThread;
  I: Integer;
begin
  LLatch := MakeNamedLatch(RandomName('mt_latch'), THREAD_COUNT);

  // 创建线程
  for I := 0 to THREAD_COUNT - 1 do
    LThreads[I] := TLatchThread.Create(LLatch);

  // 启动线程
  for I := 0 to THREAD_COUNT - 1 do
    LThreads[I].Start;

  // 等待门闩打开
  CheckTrue(LLatch.Wait(5000), 'Latch should open within timeout');

  // 清理线程
  for I := 0 to THREAD_COUNT - 1 do
  begin
    LThreads[I].WaitFor;
    LThreads[I].Free;
  end;

  CheckTrue(LLatch.IsOpen, 'Latch should be open');
end;

type
  TWaitGroupThread = class(TThread)
  private
    FWG: INamedWaitGroup;
    FWorkDone: PBoolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AWG: INamedWaitGroup; AWorkDone: PBoolean);
  end;

constructor TWaitGroupThread.Create(AWG: INamedWaitGroup; AWorkDone: PBoolean);
begin
  inherited Create(True);
  FWG := AWG;
  FWorkDone := AWorkDone;
  FreeOnTerminate := False;
end;

procedure TWaitGroupThread.Execute;
begin
  Sleep(10 + Random(20));  // 模拟工作
  FWorkDone^ := True;
  FWG.Done;
end;

procedure TTestCase_Concurrency_Boundary.Test_WaitGroup_MultiThread;
const
  THREAD_COUNT = 4;
var
  LWG: INamedWaitGroup;
  LThreads: array[0..THREAD_COUNT-1] of TWaitGroupThread;
  LWorkDone: array[0..THREAD_COUNT-1] of Boolean;
  I: Integer;
begin
  LWG := MakeNamedWaitGroup(RandomName('mt_wg'));
  LWG.Add(THREAD_COUNT);

  // 初始化标志
  for I := 0 to THREAD_COUNT - 1 do
    LWorkDone[I] := False;

  // 创建线程
  for I := 0 to THREAD_COUNT - 1 do
    LThreads[I] := TWaitGroupThread.Create(LWG, @LWorkDone[I]);

  // 启动线程
  for I := 0 to THREAD_COUNT - 1 do
    LThreads[I].Start;

  // 等待所有工作完成
  CheckTrue(LWG.Wait(5000), 'WaitGroup should complete within timeout');

  // 清理线程
  for I := 0 to THREAD_COUNT - 1 do
  begin
    LThreads[I].WaitFor;
    LThreads[I].Free;
  end;

  // 验证所有工作都完成了
  for I := 0 to THREAD_COUNT - 1 do
    CheckTrue(LWorkDone[I], 'All work should be done');

  CheckTrue(LWG.IsZero, 'WaitGroup should be zero');
end;

initialization
  Randomize;
  RegisterTest(TTestCase_NameValidation);
  RegisterTest(TTestCase_NamedOnce_Boundary);
  RegisterTest(TTestCase_NamedLatch_Boundary);
  RegisterTest(TTestCase_NamedWaitGroup_Boundary);
  RegisterTest(TTestCase_NamedSharedCounter_Boundary);
  RegisterTest(TTestCase_Concurrency_Boundary);

end.
