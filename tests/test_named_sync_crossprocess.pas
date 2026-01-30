program test_named_sync_crossprocess;

{$mode objfpc}{$H+}

uses
  SysUtils, BaseUnix, Unix,
  fafafa.core.sync.namedOnce,
  fafafa.core.sync.namedLatch,
  fafafa.core.sync.namedWaitGroup,
  fafafa.core.sync.namedSharedCounter,
  fafafa.core.sync.base;

const
  TEST_NAME_PREFIX = 'crossproc_test_';
  NUM_CHILD_PROCESSES = 4;

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

// ====== NamedSharedCounter 跨进程测试 ======
procedure TestSharedCounter_CrossProcess;
var
  Counter: INamedSharedCounter;
  CounterName: string;
  Pid: TPid;
  I: Integer;
  Status: cint;
  ChildPids: array[0..NUM_CHILD_PROCESSES-1] of TPid;
begin
  WriteLn('');
  WriteLn('=== Testing NamedSharedCounter Cross-Process ===');

  CounterName := TEST_NAME_PREFIX + 'counter_' + IntToStr(Random(100000));
  Counter := MakeNamedSharedCounter(CounterName);
  Counter.SetValue(0);

  // 创建子进程，每个子进程增加计数器 100 次
  for I := 0 to NUM_CHILD_PROCESSES - 1 do
  begin
    Pid := FpFork;
    if Pid = 0 then
    begin
      // 子进程
      Counter := MakeNamedSharedCounter(CounterName);
      for Status := 1 to 100 do
        Counter.Increment;
      Halt(0);
    end
    else if Pid > 0 then
      ChildPids[I] := Pid
    else
    begin
      WriteLn('[ERROR] Fork failed');
      Exit;
    end;
  end;

  // 等待所有子进程完成
  for I := 0 to NUM_CHILD_PROCESSES - 1 do
    FpWaitPid(ChildPids[I], @Status, 0);

  // 验证结果
  Check(Counter.GetValue = NUM_CHILD_PROCESSES * 100,
    Format('Counter should be %d (got %d)', [NUM_CHILD_PROCESSES * 100, Counter.GetValue]));
end;

// ====== NamedLatch 跨进程测试 ======
procedure TestLatch_CrossProcess;
var
  Latch: INamedLatch;
  LatchName: string;
  Pid: TPid;
  I: Integer;
  Status: cint;
  ChildPids: array[0..NUM_CHILD_PROCESSES-1] of TPid;
  StartTime: QWord;
begin
  WriteLn('');
  WriteLn('=== Testing NamedLatch Cross-Process ===');

  LatchName := TEST_NAME_PREFIX + 'latch_' + IntToStr(Random(100000));
  Latch := MakeNamedLatch(LatchName, NUM_CHILD_PROCESSES);

  Check(not Latch.IsOpen, 'Latch should not be open initially');

  // 创建子进程，每个子进程执行 CountDown
  for I := 0 to NUM_CHILD_PROCESSES - 1 do
  begin
    Pid := FpFork;
    if Pid = 0 then
    begin
      // 子进程
      Sleep(50 + Random(50)); // 随机延迟
      Latch := MakeNamedLatch(LatchName, 0); // 连接到现有 latch
      Latch.CountDown;
      Halt(0);
    end
    else if Pid > 0 then
      ChildPids[I] := Pid
    else
    begin
      WriteLn('[ERROR] Fork failed');
      Exit;
    end;
  end;

  // 父进程等待 latch 打开
  StartTime := GetTickCount64;
  Check(Latch.Wait(5000), 'Latch should open within timeout');
  Check(Latch.IsOpen, 'Latch should be open after all CountDown');

  WriteLn(Format('  Latch opened in %d ms', [GetTickCount64 - StartTime]));

  // 等待所有子进程完成
  for I := 0 to NUM_CHILD_PROCESSES - 1 do
    FpWaitPid(ChildPids[I], @Status, 0);
end;

// ====== NamedWaitGroup 跨进程测试 ======
procedure TestWaitGroup_CrossProcess;
var
  WG: INamedWaitGroup;
  Counter: INamedSharedCounter;
  WGName, CounterName: string;
  Pid: TPid;
  I: Integer;
  Status: cint;
  ChildPids: array[0..NUM_CHILD_PROCESSES-1] of TPid;
begin
  WriteLn('');
  WriteLn('=== Testing NamedWaitGroup Cross-Process ===');

  WGName := TEST_NAME_PREFIX + 'wg_' + IntToStr(Random(100000));
  CounterName := TEST_NAME_PREFIX + 'wg_counter_' + IntToStr(Random(100000));

  WG := MakeNamedWaitGroup(WGName);
  Counter := MakeNamedSharedCounter(CounterName);
  Counter.SetValue(0);

  // 父进程添加任务计数
  WG.Add(NUM_CHILD_PROCESSES);

  // 创建子进程
  for I := 0 to NUM_CHILD_PROCESSES - 1 do
  begin
    Pid := FpFork;
    if Pid = 0 then
    begin
      // 子进程：执行工作并标记完成
      Sleep(50 + Random(100));
      Counter := MakeNamedSharedCounter(CounterName);
      Counter.Increment;
      WG := MakeNamedWaitGroup(WGName);
      WG.Done;
      Halt(0);
    end
    else if Pid > 0 then
      ChildPids[I] := Pid
    else
    begin
      WriteLn('[ERROR] Fork failed');
      Exit;
    end;
  end;

  // 父进程等待所有任务完成
  Check(WG.Wait(5000), 'WaitGroup should complete within timeout');
  Check(WG.IsZero, 'WaitGroup count should be zero');
  Check(Counter.GetValue = NUM_CHILD_PROCESSES,
    Format('Counter should be %d', [NUM_CHILD_PROCESSES]));

  // 等待所有子进程完成
  for I := 0 to NUM_CHILD_PROCESSES - 1 do
    FpWaitPid(ChildPids[I], @Status, 0);
end;

// ====== NamedOnce 跨进程测试 ======
var
  GOnceCounter: INamedSharedCounter;

procedure OnceCallback;
begin
  GOnceCounter.Increment;
  Sleep(100); // 模拟耗时初始化
end;

procedure TestOnce_CrossProcess;
var
  Once: INamedOnce;
  OnceName, CounterName: string;
  Pid: TPid;
  I: Integer;
  Status: cint;
  ChildPids: array[0..NUM_CHILD_PROCESSES-1] of TPid;
begin
  WriteLn('');
  WriteLn('=== Testing NamedOnce Cross-Process ===');

  OnceName := TEST_NAME_PREFIX + 'once_' + IntToStr(Random(100000));
  CounterName := TEST_NAME_PREFIX + 'once_counter_' + IntToStr(Random(100000));

  GOnceCounter := MakeNamedSharedCounter(CounterName);
  GOnceCounter.SetValue(0);

  Once := MakeNamedOnce(OnceName);

  // 创建子进程，每个都尝试执行 Once
  for I := 0 to NUM_CHILD_PROCESSES - 1 do
  begin
    Pid := FpFork;
    if Pid = 0 then
    begin
      // 子进程
      GOnceCounter := MakeNamedSharedCounter(CounterName);
      Once := MakeNamedOnce(OnceName);
      Once.Execute(@OnceCallback);
      Halt(0);
    end
    else if Pid > 0 then
      ChildPids[I] := Pid
    else
    begin
      WriteLn('[ERROR] Fork failed');
      Exit;
    end;
  end;

  // 父进程也执行一次
  Once.Execute(@OnceCallback);

  // 等待所有子进程完成
  for I := 0 to NUM_CHILD_PROCESSES - 1 do
    FpWaitPid(ChildPids[I], @Status, 0);

  // 验证只执行了一次
  Check(GOnceCounter.GetValue = 1,
    Format('Once should execute exactly once (got %d)', [GOnceCounter.GetValue]));
  Check(Once.IsDone, 'Once should be done');
end;

begin
  Randomize;
  WriteLn('================================================');
  WriteLn('  Named Sync Primitives Cross-Process Tests');
  WriteLn('================================================');

  try
    TestSharedCounter_CrossProcess;
    TestLatch_CrossProcess;
    TestWaitGroup_CrossProcess;
    TestOnce_CrossProcess;
  except
    on E: Exception do
    begin
      WriteLn('[ERROR] Unhandled exception: ', E.Message);
      Inc(GTestsFailed);
    end;
  end;

  WriteLn('');
  WriteLn('================================================');
  WriteLn('  Results: ', GTestsPassed, ' passed, ', GTestsFailed, ' failed');
  WriteLn('================================================');

  if GTestsFailed > 0 then
    ExitCode := 1
  else
    ExitCode := 0;
end.
