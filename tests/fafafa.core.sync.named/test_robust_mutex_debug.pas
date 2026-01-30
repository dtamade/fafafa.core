program test_robust_mutex_debug;

{$mode objfpc}{$H+}

// ====================================================================
// Robust Mutex 诊断测试
// 深入诊断 robust mutex 与共享内存的兼容性问题
// ====================================================================

// ★ 关键：必须链接 pthread 和 rt 库
// pthread 库的初始化代码会设置 robust futex list
{$LINKLIB pthread}
{$LINKLIB rt}

uses
  // ★ cthreads 必须是第一个 uses 的单元！
  // 它会正确初始化 pthread 运行时，包括 robust list
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, BaseUnix, Unix, UnixType;

type
  // pthread_mutex_t 结构
  PPThreadMutex = ^TPThreadMutex;
  TPThreadMutex = record
    data: array[0..39] of Byte;
  end;

  // pthread_mutexattr_t 结构
  PPThreadMutexAttr = ^TPThreadMutexAttr;
  TPThreadMutexAttr = record
    data: array[0..3] of Byte;
  end;

// pthread 函数声明 - 改为直接从 pthread 库导入
function pthread_mutex_init(mutex: PPThreadMutex; attr: PPThreadMutexAttr): cint; cdecl; external 'pthread';
function pthread_mutex_destroy(mutex: PPThreadMutex): cint; cdecl; external 'pthread';
function pthread_mutex_lock(mutex: PPThreadMutex): cint; cdecl; external 'pthread';
function pthread_mutex_unlock(mutex: PPThreadMutex): cint; cdecl; external 'pthread';
function pthread_mutex_trylock(mutex: PPThreadMutex): cint; cdecl; external 'pthread';
function pthread_mutex_timedlock(mutex: PPThreadMutex; abs_timeout: PTimeSpec): cint; cdecl; external 'pthread';
function pthread_mutexattr_init(attr: PPThreadMutexAttr): cint; cdecl; external 'pthread';
function pthread_mutexattr_destroy(attr: PPThreadMutexAttr): cint; cdecl; external 'pthread';
function pthread_mutexattr_setpshared(attr: PPThreadMutexAttr; pshared: cint): cint; cdecl; external 'pthread';
function pthread_mutexattr_setrobust(attr: PPThreadMutexAttr; robustness: cint): cint; cdecl; external 'pthread';
function pthread_mutexattr_getrobust(attr: PPThreadMutexAttr; robustness: pcint): cint; cdecl; external 'pthread';
function pthread_mutexattr_getpshared(attr: PPThreadMutexAttr; pshared: pcint): cint; cdecl; external 'pthread';
function pthread_mutex_consistent(mutex: PPThreadMutex): cint; cdecl; external 'pthread';

// C errno
function __errno_location: pcint; cdecl; external 'c';

const
  PTHREAD_PROCESS_SHARED = 1;
  PTHREAD_MUTEX_ROBUST = 1;
  EOWNERDEAD = 130;
  ENOTRECOVERABLE = 131;
  EINVAL = 22;
  ETIMEDOUT = 110;

var
  TestDir: string = '/dev/shm/';
  TestFile: string;

function GetCErrno: cint;
begin
  Result := __errno_location^;
end;

procedure PrintErr(const Msg: string; ErrCode: cint);
begin
  WriteLn(Format('  ERROR: %s (errno=%d: %s)', [Msg, ErrCode, SysErrorMessage(ErrCode)]));
end;

procedure PrintResult(RetCode: cint; const Op: string);
begin
  if RetCode = 0 then
    WriteLn(Format('  [OK] %s', [Op]))
  else
    WriteLn(Format('  [FAIL] %s: errno=%d (%s)', [Op, RetCode, SysErrorMessage(RetCode)]));
end;

// ====================================================================
// 测试 1: 验证 robust mutex 属性设置
// ====================================================================
procedure Test_RobustAttrCheck;
var
  Attr: TPThreadMutexAttr;
  AttrPtr: PPThreadMutexAttr;
  Robustness, Pshared: cint;
  Ret: cint;
begin
  WriteLn('');
  WriteLn('=== Test 1: Verify Robust Mutex Attributes ===');

  AttrPtr := @Attr;
  Ret := pthread_mutexattr_init(AttrPtr);
  PrintResult(Ret, 'pthread_mutexattr_init');
  if Ret <> 0 then Exit;

  Ret := pthread_mutexattr_setpshared(AttrPtr, PTHREAD_PROCESS_SHARED);
  PrintResult(Ret, 'pthread_mutexattr_setpshared(PROCESS_SHARED)');

  Ret := pthread_mutexattr_setrobust(AttrPtr, PTHREAD_MUTEX_ROBUST);
  PrintResult(Ret, 'pthread_mutexattr_setrobust(ROBUST)');

  // 验证属性是否正确设置
  Robustness := -1;
  Ret := pthread_mutexattr_getrobust(AttrPtr, @Robustness);
  PrintResult(Ret, 'pthread_mutexattr_getrobust');
  WriteLn(Format('  Robustness value: %d (expected %d)', [Robustness, PTHREAD_MUTEX_ROBUST]));

  Pshared := -1;
  Ret := pthread_mutexattr_getpshared(AttrPtr, @Pshared);
  PrintResult(Ret, 'pthread_mutexattr_getpshared');
  WriteLn(Format('  Pshared value: %d (expected %d)', [Pshared, PTHREAD_PROCESS_SHARED]));

  pthread_mutexattr_destroy(AttrPtr);

  if (Robustness = PTHREAD_MUTEX_ROBUST) and (Pshared = PTHREAD_PROCESS_SHARED) then
    WriteLn('  [PASS] Robust mutex attributes verified')
  else
    WriteLn('  [FAIL] Robust mutex attributes NOT correctly set');
end;

// ====================================================================
// 测试 2: 使用 mmap 共享内存测试 robust mutex
// ====================================================================
procedure Test_RobustMutexWithMmap;
var
  Attr: TPThreadMutexAttr;
  AttrPtr: PPThreadMutexAttr;
  MutexPtr: PPThreadMutex;
  Fd: cint;
  FilePath: AnsiString;
  Pid: TPid;
  Status: cint;
  Ret: cint;
  Ts: TTimeSpec;
  tv: TTimeVal;
begin
  WriteLn('');
  WriteLn('=== Test 2: Robust Mutex with mmap (File-backed) ===');

  FilePath := TestFile + '_mmap';

  // 清理可能存在的旧文件
  fpUnlink(PAnsiChar(FilePath));

  // 创建共享内存文件
  Fd := fpOpen(PAnsiChar(FilePath), O_CREAT or O_RDWR, S_IRUSR or S_IWUSR);
  if Fd < 0 then
  begin
    PrintErr('fpOpen failed', GetCErrno);
    Exit;
  end;
  WriteLn('  [OK] Created shared memory file: ', FilePath);

  // 设置文件大小
  if fpFTruncate(Fd, SizeOf(TPThreadMutex)) <> 0 then
  begin
    PrintErr('fpFTruncate failed', GetCErrno);
    fpClose(Fd);
    fpUnlink(PAnsiChar(FilePath));
    Exit;
  end;
  WriteLn('  [OK] File truncated to ', SizeOf(TPThreadMutex), ' bytes');

  // mmap
  MutexPtr := PPThreadMutex(fpMMap(nil, SizeOf(TPThreadMutex),
    PROT_READ or PROT_WRITE, MAP_SHARED, Fd, 0));
  if MutexPtr = PPThreadMutex(-1) then
  begin
    PrintErr('fpMMap failed', GetCErrno);
    fpClose(Fd);
    fpUnlink(PAnsiChar(FilePath));
    Exit;
  end;
  WriteLn('  [OK] Memory mapped at ', IntToHex(PtrUInt(MutexPtr), 16));

  // 初始化 mutex
  AttrPtr := @Attr;
  Ret := pthread_mutexattr_init(AttrPtr);
  if Ret <> 0 then
  begin
    PrintErr('pthread_mutexattr_init failed', Ret);
    fpMUnMap(MutexPtr, SizeOf(TPThreadMutex));
    fpClose(Fd);
    fpUnlink(PAnsiChar(FilePath));
    Exit;
  end;

  pthread_mutexattr_setpshared(AttrPtr, PTHREAD_PROCESS_SHARED);
  pthread_mutexattr_setrobust(AttrPtr, PTHREAD_MUTEX_ROBUST);

  Ret := pthread_mutex_init(MutexPtr, AttrPtr);
  pthread_mutexattr_destroy(AttrPtr);

  if Ret <> 0 then
  begin
    PrintErr('pthread_mutex_init failed', Ret);
    fpMUnMap(MutexPtr, SizeOf(TPThreadMutex));
    fpClose(Fd);
    fpUnlink(PAnsiChar(FilePath));
    Exit;
  end;
  WriteLn('  [OK] Mutex initialized with ROBUST + PROCESS_SHARED');

  // Fork 子进程
  Pid := FpFork;

  if Pid = 0 then
  begin
    // 子进程：获取锁然后崩溃
    WriteLn('  [Child] Attempting to acquire lock...');
    Ret := pthread_mutex_lock(MutexPtr);
    if Ret <> 0 then
    begin
      WriteLn('  [Child] Failed to lock: ', Ret);
      Halt(1);
    end;
    WriteLn('  [Child] Lock acquired, sending SIGKILL to self...');
    FpKill(FpGetpid, SIGKILL);
    // 不应该到达这里
  end
  else if Pid > 0 then
  begin
    // 父进程：等待子进程获取锁并崩溃
    Sleep(200);
    FpWaitPid(Pid, @Status, 0);
    WriteLn('  [Parent] Child terminated');

    // 尝试获取锁
    WriteLn('  [Parent] Attempting to acquire lock...');

    // 准备超时时间
    fpgettimeofday(@tv, nil);
    Ts.tv_sec := tv.tv_sec + 5;  // 5 秒超时
    Ts.tv_nsec := tv.tv_usec * 1000;

    Ret := pthread_mutex_timedlock(MutexPtr, @Ts);
    WriteLn(Format('  [Parent] pthread_mutex_timedlock returned: %d', [Ret]));

    case Ret of
      0:
        begin
          WriteLn('  [Parent] Lock acquired normally');
          pthread_mutex_unlock(MutexPtr);
        end;
      EOWNERDEAD:
        begin
          WriteLn('  [Parent] Got EOWNERDEAD - previous owner died');
          Ret := pthread_mutex_consistent(MutexPtr);
          if Ret = 0 then
          begin
            WriteLn('  [Parent] Mutex made consistent');
            pthread_mutex_unlock(MutexPtr);
            WriteLn('  [PASS] Robust mutex recovery works!');
          end
          else
            WriteLn('  [FAIL] pthread_mutex_consistent failed: ', Ret);
        end;
      EINVAL:
        begin
          WriteLn('  [FAIL] Got EINVAL - invalid argument');
          WriteLn('  Possible causes:');
          WriteLn('    1. Mutex not properly initialized');
          WriteLn('    2. Mutex corrupted');
          WriteLn('    3. Timespec invalid');
          WriteLn('    4. Robust mutex not supported on this system/configuration');
        end;
      ETIMEDOUT:
        begin
          WriteLn('  [FAIL] Got ETIMEDOUT - lock still held (robust not working?)');
        end;
    else
      WriteLn(Format('  [FAIL] Unexpected error: %d (%s)', [Ret, SysErrorMessage(Ret)]));
    end;

    // 清理
    pthread_mutex_destroy(MutexPtr);
    fpMUnMap(MutexPtr, SizeOf(TPThreadMutex));
    fpClose(Fd);
    fpUnlink(PAnsiChar(FilePath));
  end
  else
  begin
    WriteLn('  [ERROR] Fork failed');
    pthread_mutex_destroy(MutexPtr);
    fpMUnMap(MutexPtr, SizeOf(TPThreadMutex));
    fpClose(Fd);
    fpUnlink(PAnsiChar(FilePath));
  end;
end;

// ====================================================================
// 测试 3: 使用 shm_open 测试 robust mutex（POSIX 标准方式）
// ====================================================================
function shm_open(name: PAnsiChar; oflag: cint; mode: mode_t): cint; cdecl; external 'rt';
function shm_unlink(name: PAnsiChar): cint; cdecl; external 'rt';

procedure Test_RobustMutexWithShmOpen;
var
  Attr: TPThreadMutexAttr;
  AttrPtr: PPThreadMutexAttr;
  MutexPtr: PPThreadMutex;
  Fd: cint;
  ShmName: AnsiString;
  Pid: TPid;
  Status: cint;
  Ret: cint;
  Ts: TTimeSpec;
  tv: TTimeVal;
begin
  WriteLn('');
  WriteLn('=== Test 3: Robust Mutex with shm_open (POSIX standard) ===');

  ShmName := '/fafafa_robust_test_' + IntToStr(Random(100000));

  // 清理可能存在的旧共享内存
  shm_unlink(PAnsiChar(ShmName));

  // 使用 shm_open 创建共享内存
  Fd := shm_open(PAnsiChar(ShmName), O_CREAT or O_RDWR, S_IRUSR or S_IWUSR);
  if Fd < 0 then
  begin
    PrintErr('shm_open failed', GetCErrno);
    Exit;
  end;
  WriteLn('  [OK] Created POSIX shared memory: ', ShmName);

  // 设置大小
  if fpFTruncate(Fd, SizeOf(TPThreadMutex)) <> 0 then
  begin
    PrintErr('fpFTruncate failed', GetCErrno);
    fpClose(Fd);
    shm_unlink(PAnsiChar(ShmName));
    Exit;
  end;
  WriteLn('  [OK] Shared memory truncated to ', SizeOf(TPThreadMutex), ' bytes');

  // mmap
  MutexPtr := PPThreadMutex(fpMMap(nil, SizeOf(TPThreadMutex),
    PROT_READ or PROT_WRITE, MAP_SHARED, Fd, 0));
  if MutexPtr = PPThreadMutex(-1) then
  begin
    PrintErr('fpMMap failed', GetCErrno);
    fpClose(Fd);
    shm_unlink(PAnsiChar(ShmName));
    Exit;
  end;
  WriteLn('  [OK] Memory mapped at ', IntToHex(PtrUInt(MutexPtr), 16));

  // 初始化 mutex
  AttrPtr := @Attr;
  pthread_mutexattr_init(AttrPtr);
  pthread_mutexattr_setpshared(AttrPtr, PTHREAD_PROCESS_SHARED);
  pthread_mutexattr_setrobust(AttrPtr, PTHREAD_MUTEX_ROBUST);

  Ret := pthread_mutex_init(MutexPtr, AttrPtr);
  pthread_mutexattr_destroy(AttrPtr);

  if Ret <> 0 then
  begin
    PrintErr('pthread_mutex_init failed', Ret);
    fpMUnMap(MutexPtr, SizeOf(TPThreadMutex));
    fpClose(Fd);
    shm_unlink(PAnsiChar(ShmName));
    Exit;
  end;
  WriteLn('  [OK] Mutex initialized');

  // Fork
  Pid := FpFork;

  if Pid = 0 then
  begin
    // 子进程
    WriteLn('  [Child] Acquiring lock...');
    Ret := pthread_mutex_lock(MutexPtr);
    if Ret <> 0 then
    begin
      WriteLn('  [Child] Lock failed: ', Ret);
      Halt(1);
    end;
    WriteLn('  [Child] Lock acquired, crashing...');
    FpKill(FpGetpid, SIGKILL);
  end
  else if Pid > 0 then
  begin
    Sleep(200);
    FpWaitPid(Pid, @Status, 0);
    WriteLn('  [Parent] Child terminated');

    // 准备超时
    fpgettimeofday(@tv, nil);
    Ts.tv_sec := tv.tv_sec + 5;
    Ts.tv_nsec := tv.tv_usec * 1000;

    WriteLn('  [Parent] Attempting timedlock...');
    Ret := pthread_mutex_timedlock(MutexPtr, @Ts);
    WriteLn(Format('  [Parent] Result: %d', [Ret]));

    case Ret of
      0: WriteLn('  [Parent] Lock acquired normally');
      EOWNERDEAD:
        begin
          WriteLn('  [Parent] EOWNERDEAD received - attempting recovery...');
          Ret := pthread_mutex_consistent(MutexPtr);
          if Ret = 0 then
          begin
            WriteLn('  [PASS] Mutex recovered successfully!');
            pthread_mutex_unlock(MutexPtr);
          end
          else
            WriteLn('  [FAIL] Recovery failed: ', Ret);
        end;
      EINVAL: WriteLn('  [FAIL] EINVAL - mutex invalid');
      ETIMEDOUT: WriteLn('  [FAIL] ETIMEDOUT - robust not working');
    else
      WriteLn('  [FAIL] Unexpected: ', Ret, ' (', SysErrorMessage(Ret), ')');
    end;

    // 清理
    pthread_mutex_destroy(MutexPtr);
    fpMUnMap(MutexPtr, SizeOf(TPThreadMutex));
    fpClose(Fd);
    shm_unlink(PAnsiChar(ShmName));
  end
  else
  begin
    WriteLn('  [ERROR] Fork failed');
    pthread_mutex_destroy(MutexPtr);
    fpMUnMap(MutexPtr, SizeOf(TPThreadMutex));
    fpClose(Fd);
    shm_unlink(PAnsiChar(ShmName));
  end;
end;

// ====================================================================
// 测试 4: 不使用 timedlock，直接使用 trylock 轮询
// ====================================================================
procedure Test_RobustMutexWithTrylock;
var
  Attr: TPThreadMutexAttr;
  AttrPtr: PPThreadMutexAttr;
  MutexPtr: PPThreadMutex;
  Fd: cint;
  ShmName: AnsiString;
  Pid: TPid;
  Status: cint;
  Ret: cint;
  Attempts: Integer;
begin
  WriteLn('');
  WriteLn('=== Test 4: Robust Mutex with trylock (no timedlock) ===');

  ShmName := '/fafafa_robust_trylock_' + IntToStr(Random(100000));

  shm_unlink(PAnsiChar(ShmName));

  Fd := shm_open(PAnsiChar(ShmName), O_CREAT or O_RDWR, S_IRUSR or S_IWUSR);
  if Fd < 0 then
  begin
    PrintErr('shm_open failed', GetCErrno);
    Exit;
  end;

  fpFTruncate(Fd, SizeOf(TPThreadMutex));

  MutexPtr := PPThreadMutex(fpMMap(nil, SizeOf(TPThreadMutex),
    PROT_READ or PROT_WRITE, MAP_SHARED, Fd, 0));
  if MutexPtr = PPThreadMutex(-1) then
  begin
    PrintErr('fpMMap failed', GetCErrno);
    fpClose(Fd);
    shm_unlink(PAnsiChar(ShmName));
    Exit;
  end;

  AttrPtr := @Attr;
  pthread_mutexattr_init(AttrPtr);
  pthread_mutexattr_setpshared(AttrPtr, PTHREAD_PROCESS_SHARED);
  pthread_mutexattr_setrobust(AttrPtr, PTHREAD_MUTEX_ROBUST);

  Ret := pthread_mutex_init(MutexPtr, AttrPtr);
  pthread_mutexattr_destroy(AttrPtr);

  if Ret <> 0 then
  begin
    PrintErr('pthread_mutex_init failed', Ret);
    fpMUnMap(MutexPtr, SizeOf(TPThreadMutex));
    fpClose(Fd);
    shm_unlink(PAnsiChar(ShmName));
    Exit;
  end;
  WriteLn('  [OK] Setup complete');

  Pid := FpFork;

  if Pid = 0 then
  begin
    WriteLn('  [Child] Locking...');
    pthread_mutex_lock(MutexPtr);
    WriteLn('  [Child] Crashing...');
    FpKill(FpGetpid, SIGKILL);
  end
  else if Pid > 0 then
  begin
    Sleep(200);
    FpWaitPid(Pid, @Status, 0);
    WriteLn('  [Parent] Child terminated');

    // 使用 trylock 轮询
    Attempts := 0;
    while Attempts < 50 do
    begin
      Ret := pthread_mutex_trylock(MutexPtr);
      if Ret = 0 then
      begin
        WriteLn('  [PASS] trylock succeeded after ', Attempts, ' attempts');
        pthread_mutex_unlock(MutexPtr);
        Break;
      end
      else if Ret = EOWNERDEAD then
      begin
        WriteLn('  [Parent] EOWNERDEAD on trylock');
        Ret := pthread_mutex_consistent(MutexPtr);
        if Ret = 0 then
        begin
          WriteLn('  [PASS] Recovered via trylock!');
          pthread_mutex_unlock(MutexPtr);
        end
        else
          WriteLn('  [FAIL] Recovery failed');
        Break;
      end
      else if Ret = EINVAL then
      begin
        WriteLn('  [FAIL] trylock returned EINVAL');
        Break;
      end;

      Inc(Attempts);
      Sleep(100);
    end;

    if Attempts >= 50 then
      WriteLn('  [FAIL] Timeout after 50 trylock attempts');

    pthread_mutex_destroy(MutexPtr);
    fpMUnMap(MutexPtr, SizeOf(TPThreadMutex));
    fpClose(Fd);
    shm_unlink(PAnsiChar(ShmName));
  end;
end;

// ====================================================================
// 测试 5: 使用 pthread_mutex_lock（阻塞式）
// ====================================================================
procedure Test_RobustMutexWithBlockingLock;
var
  Attr: TPThreadMutexAttr;
  AttrPtr: PPThreadMutexAttr;
  MutexPtr: PPThreadMutex;
  Fd: cint;
  ShmName: AnsiString;
  Pid: TPid;
  Status: cint;
  Ret: cint;
begin
  WriteLn('');
  WriteLn('=== Test 5: Robust Mutex with blocking lock ===');

  ShmName := '/fafafa_robust_block_' + IntToStr(Random(100000));

  shm_unlink(PAnsiChar(ShmName));

  Fd := shm_open(PAnsiChar(ShmName), O_CREAT or O_RDWR, S_IRUSR or S_IWUSR);
  if Fd < 0 then
  begin
    PrintErr('shm_open failed', GetCErrno);
    Exit;
  end;

  fpFTruncate(Fd, SizeOf(TPThreadMutex));

  MutexPtr := PPThreadMutex(fpMMap(nil, SizeOf(TPThreadMutex),
    PROT_READ or PROT_WRITE, MAP_SHARED, Fd, 0));
  if MutexPtr = PPThreadMutex(-1) then
  begin
    PrintErr('fpMMap failed', GetCErrno);
    fpClose(Fd);
    shm_unlink(PAnsiChar(ShmName));
    Exit;
  end;

  AttrPtr := @Attr;
  pthread_mutexattr_init(AttrPtr);
  pthread_mutexattr_setpshared(AttrPtr, PTHREAD_PROCESS_SHARED);
  pthread_mutexattr_setrobust(AttrPtr, PTHREAD_MUTEX_ROBUST);

  Ret := pthread_mutex_init(MutexPtr, AttrPtr);
  pthread_mutexattr_destroy(AttrPtr);

  if Ret <> 0 then
  begin
    PrintErr('pthread_mutex_init failed', Ret);
    fpMUnMap(MutexPtr, SizeOf(TPThreadMutex));
    fpClose(Fd);
    shm_unlink(PAnsiChar(ShmName));
    Exit;
  end;
  WriteLn('  [OK] Setup complete');

  Pid := FpFork;

  if Pid = 0 then
  begin
    WriteLn('  [Child] Locking...');
    pthread_mutex_lock(MutexPtr);
    WriteLn('  [Child] Crashing...');
    FpKill(FpGetpid, SIGKILL);
  end
  else if Pid > 0 then
  begin
    Sleep(200);
    FpWaitPid(Pid, @Status, 0);
    WriteLn('  [Parent] Child terminated');

    WriteLn('  [Parent] Calling blocking pthread_mutex_lock...');
    Ret := pthread_mutex_lock(MutexPtr);
    WriteLn(Format('  [Parent] pthread_mutex_lock returned: %d', [Ret]));

    case Ret of
      0: WriteLn('  [Parent] Lock acquired normally');
      EOWNERDEAD:
        begin
          WriteLn('  [Parent] EOWNERDEAD - recovering...');
          Ret := pthread_mutex_consistent(MutexPtr);
          if Ret = 0 then
          begin
            WriteLn('  [PASS] Recovered successfully!');
            pthread_mutex_unlock(MutexPtr);
          end
          else
            WriteLn('  [FAIL] Recovery failed: ', Ret);
        end;
      EINVAL: WriteLn('  [FAIL] EINVAL');
    else
      WriteLn('  [FAIL] Unexpected: ', Ret);
    end;

    pthread_mutex_destroy(MutexPtr);
    fpMUnMap(MutexPtr, SizeOf(TPThreadMutex));
    fpClose(Fd);
    shm_unlink(PAnsiChar(ShmName));
  end;
end;

// ====================================================================
// 主程序
// ====================================================================
begin
  Randomize;
  TestFile := TestDir + 'test_robust_' + IntToStr(Random(100000));

  WriteLn('========================================');
  WriteLn('  Robust Mutex Diagnostic Tests');
  WriteLn('========================================');
  WriteLn('TPThreadMutex size: ', SizeOf(TPThreadMutex), ' bytes');
  WriteLn('TPThreadMutexAttr size: ', SizeOf(TPThreadMutexAttr), ' bytes');

  Test_RobustAttrCheck;
  Test_RobustMutexWithMmap;
  Test_RobustMutexWithShmOpen;
  Test_RobustMutexWithTrylock;
  Test_RobustMutexWithBlockingLock;

  WriteLn('');
  WriteLn('========================================');
  WriteLn('  Diagnostic Tests Complete');
  WriteLn('========================================');
end.
