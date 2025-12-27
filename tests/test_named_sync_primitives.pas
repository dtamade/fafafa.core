program test_named_sync_primitives;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.sync.namedOnce,
  fafafa.core.sync.namedLatch,
  fafafa.core.sync.namedWaitGroup,
  fafafa.core.sync.namedSharedCounter,
  fafafa.core.sync.base;

var
  GTestsPassed: Integer = 0;
  GTestsFailed: Integer = 0;

procedure Check(ACondition: Boolean; const ATestName: string);
begin
  if ACondition then
  begin
    WriteLn('[PASS] ', ATestName);
    Inc(GTestsPassed);
  end
  else
  begin
    WriteLn('[FAIL] ', ATestName);
    Inc(GTestsFailed);
  end;
end;

var
  GOnceExecuted: Boolean = False;

procedure OnceCallback;
begin
  GOnceExecuted := True;
end;

procedure TestNamedOnce;
var
  Once: INamedOnce;
begin
  WriteLn('=== Testing NamedOnce ===');

  Once := MakeNamedOnce('test_once_' + IntToStr(Random(100000)));

  Check(not Once.IsDone, 'IsDone initially false');
  Check(Once.GetState = nosNotStarted, 'Initial state is NotStarted');

  GOnceExecuted := False;
  Once.Execute(@OnceCallback);
  Check(GOnceExecuted, 'Callback executed');
  Check(Once.IsDone, 'IsDone after Execute');
  Check(Once.GetState = nosCompleted, 'State is Completed');

  // 测试多次执行
  GOnceExecuted := False;
  Once.Execute(@OnceCallback);
  Check(not GOnceExecuted, 'Second Execute does not run callback');

  WriteLn('');
end;

procedure TestNamedLatch;
var
  Latch: INamedLatch;
begin
  WriteLn('=== Testing NamedLatch ===');

  Latch := MakeNamedLatch('test_latch_' + IntToStr(Random(100000)), 3);

  Check(Latch.GetCount = 3, 'Initial count is 3');
  Check(not Latch.IsOpen, 'Latch is not open initially');
  Check(not Latch.TryWait, 'TryWait returns false');

  Latch.CountDown;
  Check(Latch.GetCount = 2, 'Count is 2 after CountDown');

  Latch.CountDownBy(2);
  Check(Latch.GetCount = 0, 'Count is 0 after CountDownBy(2)');
  Check(Latch.IsOpen, 'Latch is open');
  Check(Latch.TryWait, 'TryWait returns true');

  // 测试初始计数为 0
  Latch := MakeNamedLatch('test_latch_zero_' + IntToStr(Random(100000)), 0);
  Check(Latch.IsOpen, 'Latch with count=0 is open');

  WriteLn('');
end;

procedure TestNamedWaitGroup;
var
  WG: INamedWaitGroup;
  ExceptionRaised: Boolean;
begin
  WriteLn('=== Testing NamedWaitGroup ===');

  WG := MakeNamedWaitGroup('test_wg_' + IntToStr(Random(100000)));

  Check(WG.GetCount = 0, 'Initial count is 0');
  Check(WG.IsZero, 'IsZero initially');

  WG.Add(3);
  Check(WG.GetCount = 3, 'Count is 3 after Add(3)');
  Check(not WG.IsZero, 'IsZero is false');

  WG.Done;
  Check(WG.GetCount = 2, 'Count is 2 after Done');

  WG.Done;
  WG.Done;
  Check(WG.GetCount = 0, 'Count is 0 after all Done calls');
  Check(WG.IsZero, 'IsZero is true');

  // 测试 Done 在 count=0 时抛异常
  ExceptionRaised := False;
  try
    WG.Done;
  except
    on E: ELockError do
      ExceptionRaised := True;
  end;
  Check(ExceptionRaised, 'Done at count=0 raises exception');

  WriteLn('');
end;

procedure TestNamedSharedCounter;
var
  Counter: INamedSharedCounter;
  Config: TNamedSharedCounterConfig;
  OldValue: Int64;
begin
  WriteLn('=== Testing NamedSharedCounter ===');

  Counter := MakeNamedSharedCounter('test_counter_' + IntToStr(Random(100000)));

  Check(Counter.GetValue = 0, 'Initial value is 0');

  Check(Counter.Increment = 1, 'Increment returns 1');
  Check(Counter.GetValue = 1, 'Value is 1');

  Check(Counter.Increment = 2, 'Increment returns 2');
  Check(Counter.Decrement = 1, 'Decrement returns 1');

  Check(Counter.Add(10) = 11, 'Add(10) returns 11');
  Check(Counter.Sub(5) = 6, 'Sub(5) returns 6');

  Counter.SetValue(100);
  Check(Counter.GetValue = 100, 'Value is 100 after SetValue');

  // 测试 Exchange
  OldValue := Counter.Exchange(200);
  Check(OldValue = 100, 'Exchange returns old value');
  Check(Counter.GetValue = 200, 'Value is 200 after Exchange');

  // 测试 CompareExchange 成功
  OldValue := Counter.CompareExchange(200, 300);
  Check(OldValue = 200, 'CAS success returns expected value');
  Check(Counter.GetValue = 300, 'Value is 300 after CAS success');

  // 测试 CompareExchange 失败
  OldValue := Counter.CompareExchange(999, 400);
  Check(OldValue = 300, 'CAS failure returns current value');
  Check(Counter.GetValue = 300, 'Value unchanged after CAS failure');

  // 测试自定义初始值
  Config := NamedSharedCounterConfigWithInitial(1000);
  Counter := MakeNamedSharedCounter('test_counter_init_' + IntToStr(Random(100000)), Config);
  Check(Counter.GetValue = 1000, 'Custom initial value is 1000');

  WriteLn('');
end;

begin
  Randomize;
  WriteLn('========================================');
  WriteLn('  Named Sync Primitives Test Suite');
  WriteLn('========================================');
  WriteLn('');

  try
    TestNamedOnce;
    TestNamedLatch;
    TestNamedWaitGroup;
    TestNamedSharedCounter;
  except
    on E: Exception do
    begin
      WriteLn('[ERROR] Unhandled exception: ', E.Message);
      Inc(GTestsFailed);
    end;
  end;

  WriteLn('========================================');
  WriteLn('  Results: ', GTestsPassed, ' passed, ', GTestsFailed, ' failed');
  WriteLn('========================================');

  if GTestsFailed > 0 then
    ExitCode := 1
  else
    ExitCode := 0;
end.
