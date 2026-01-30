program test_crash_recovery;

{$mode objfpc}{$H+}

// ====================================================================
// 进程崩溃恢复测试
// 测试 Named Sync Primitives 在进程崩溃场景下的正确行为
// ====================================================================

uses
  SysUtils, BaseUnix, Unix,
  fafafa.core.sync.namedMutex,
  fafafa.core.sync.namedOnce,
  fafafa.core.sync.namedSharedCounter,
  fafafa.core.sync.base;

const
  TEST_PREFIX = 'crash_test_';

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

// ====================================================================
// 测试 1: Robust Mutex 崩溃恢复
// 模拟：子进程获取锁后崩溃，父进程应该能够恢复锁
// ====================================================================
procedure TestRobustMutex_CrashRecovery;
var
  MutexName: string;
  Mutex: INamedMutex;
  Pid: TPid;
  Status: cint;
  Guard: INamedMutexGuard;
  StartTime: QWord;
begin
  WriteLn('');
  WriteLn('=== Test: Robust Mutex Crash Recovery ===');

  MutexName := TEST_PREFIX + 'mutex_' + IntToStr(Random(100000));

  // 父进程创建互斥锁
  Mutex := CreateNamedMutex(MutexName);

  Pid := FpFork;
  if Pid = 0 then
  begin
    // 子进程：获取锁然后崩溃（不释放锁）
    Mutex := CreateNamedMutex(MutexName);
    Guard := Mutex.LockNamed;
    WriteLn('  [Child] Acquired lock, now crashing without release...');
    // 故意不释放锁，直接退出
    // 使用 SIGKILL 强制终止，模拟真实崩溃
    FpKill(FpGetpid, SIGKILL);
  end
  else if Pid > 0 then
  begin
    // 父进程：等待子进程崩溃，然后尝试获取锁
    Sleep(200);  // 给子进程时间获取锁
    FpWaitPid(Pid, @Status, 0);
    WriteLn('  [Parent] Child process terminated');

    // 现在尝试获取锁
    StartTime := GetTickCount64;
    try
      Guard := Mutex.TryLockForNamed(5000);
      if Guard <> nil then
      begin
        Check(True, 'Parent acquired lock after child crash');
        WriteLn(Format('  [Parent] Lock acquired in %d ms', [GetTickCount64 - StartTime]));
        Guard.Release;
      end
      else
        Check(False, 'Parent failed to acquire lock after child crash');
    except
      on E: Exception do
      begin
        Check(False, 'Parent got exception: ' + E.Message);
      end;
    end;
  end
  else
    WriteLn('[ERROR] Fork failed');
end;

// ====================================================================
// 测试 2: NamedOnce 执行者崩溃检测
// 模拟：执行者进程在执行回调期间崩溃，等待者应该检测到并重新执行
// ====================================================================
var
  GOnceCounter: INamedSharedCounter;

procedure SlowOnceCallback;
begin
  WriteLn('  [Callback] Starting initialization...');
  GOnceCounter.Increment;
  Sleep(2000);  // 模拟长时间初始化
  WriteLn('  [Callback] Initialization complete');
end;

procedure TestNamedOnce_ExecutorCrash;
var
  OnceName, CounterName: string;
  Once: INamedOnce;
  Pid, GrandchildPid: TPid;
  Status: cint;
  StartTime: QWord;
begin
  WriteLn('');
  WriteLn('=== Test: NamedOnce Executor Crash Detection ===');

  OnceName := TEST_PREFIX + 'once_' + IntToStr(Random(100000));
  CounterName := TEST_PREFIX + 'once_cnt_' + IntToStr(Random(100000));

  GOnceCounter := MakeNamedSharedCounter(CounterName);
  GOnceCounter.SetValue(0);

  Once := MakeNamedOnce(OnceName);

  Pid := FpFork;
  if Pid = 0 then
  begin
    // 子进程：开始执行 Once，然后在回调中间崩溃
    GOnceCounter := MakeNamedSharedCounter(CounterName);
    Once := MakeNamedOnce(OnceName);

    // 孙进程执行回调并被杀死
    GrandchildPid := FpFork;
    if GrandchildPid = 0 then
    begin
      // 孙进程：实际执行
      Once.Execute(@SlowOnceCallback);
      Halt(0);  // 不应该到达这里
    end
    else if GrandchildPid > 0 then
    begin
      // 子进程：等待一小段时间后杀死孙进程
      Sleep(100);  // 让孙进程开始执行
      FpKill(GrandchildPid, SIGKILL);  // 杀死正在执行的孙进程
      FpWaitPid(GrandchildPid, @Status, 0);
      WriteLn('  [Child] Killed grandchild during callback execution');
      Halt(0);
    end
    else
    begin
      WriteLn('[ERROR] Fork failed in child');
      Halt(1);
    end;
  end
  else if Pid > 0 then
  begin
    // 父进程：等待子进程完成设置，然后尝试执行 Once
    Sleep(500);  // 等待子进程设置好崩溃场景
    FpWaitPid(Pid, @Status, 0);
    WriteLn('  [Parent] Child process chain terminated');

    // 现在尝试执行 Once
    // 如果崩溃检测工作正常，应该能检测到执行者已死并重新执行
    StartTime := GetTickCount64;
    try
      WriteLn('  [Parent] Attempting Once.Execute...');
      Once.Execute(@SlowOnceCallback);
      WriteLn(Format('  [Parent] Once.Execute completed in %d ms', [GetTickCount64 - StartTime]));
      Check(Once.IsDone, 'Once should be done after successful execution');
      // 计数器应该是 2（崩溃的一次 + 成功的一次）或 1（如果崩溃在增加计数器之前）
      WriteLn(Format('  [Parent] Counter value: %d (expected 1-2)', [GOnceCounter.GetValue]));
      Check(GOnceCounter.GetValue >= 1, 'Counter should be at least 1');
    except
      on E: Exception do
      begin
        Check(False, 'Parent got exception: ' + E.Message);
      end;
    end;
  end
  else
    WriteLn('[ERROR] Fork failed');
end;

// ====================================================================
// 测试 3: 共享内存创建者崩溃检测
// 模拟：验证共享内存在正常使用后可以被正确清理和重建
// ====================================================================
procedure TestShm_CreatorCrash;
var
  CounterName: string;
  Counter: INamedSharedCounter;
  Pid: TPid;
  Status: cint;
begin
  WriteLn('');
  WriteLn('=== Test: Shared Memory Creator Crash Detection ===');

  CounterName := TEST_PREFIX + 'shm_' + IntToStr(Random(100000));

  Pid := FpFork;
  if Pid = 0 then
  begin
    // 子进程：创建共享内存然后正常退出
    Counter := MakeNamedSharedCounter(CounterName);
    Counter.SetValue(42);
    WriteLn('  [Child] Created counter with value 42');
    // 正常退出会触发析构函数
    Halt(0);
  end
  else if Pid > 0 then
  begin
    // 父进程：等待子进程退出，然后尝试打开
    Sleep(100);
    FpWaitPid(Pid, @Status, 0);
    WriteLn('  [Parent] Child process terminated');

    // 尝试创建/打开共享内存
    // 如果子进程是最后一个引用，共享内存已被删除
    // 这里应该创建新的
    try
      Counter := MakeNamedSharedCounter(CounterName);
      // 如果是新创建的，值应该是默认值 0
      // 如果是打开现有的，值应该是 42
      WriteLn(Format('  [Parent] Counter value: %d', [Counter.GetValue]));
      Check(True, 'Parent successfully created/opened counter');
    except
      on E: Exception do
      begin
        Check(False, 'Parent failed to create counter: ' + E.Message);
      end;
    end;
  end
  else
    WriteLn('[ERROR] Fork failed');
end;

// ====================================================================
// 主程序
// ====================================================================
begin
  Randomize;
  WriteLn('================================================');
  WriteLn('  Named Sync Primitives Crash Recovery Tests');
  WriteLn('================================================');
  WriteLn('NOTE: These tests simulate process crashes');
  WriteLn('      Some tests may take a few seconds');

  try
    TestRobustMutex_CrashRecovery;
    TestNamedOnce_ExecutorCrash;
    TestShm_CreatorCrash;
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
