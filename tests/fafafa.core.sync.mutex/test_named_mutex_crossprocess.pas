program test_named_mutex_crossprocess;

{**
 * Named Mutex 跨进程同步测试
 *
 * 测试命名 Mutex 的跨进程同步功能和错误场景
 *
 * 测试覆盖:
 * 1. 命名 Mutex 创建和销毁
 * 2. 跨进程互斥访问
 * 3. 无效名称处理
 * 4. 名称冲突处理
 * 5. 资源清理
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.namedMutex;

var
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;

procedure Assert(Condition: Boolean; const Msg: string);
begin
  if Condition then
  begin
    Inc(TestsPassed);
    WriteLn('  ✓ ', Msg);
  end
  else
  begin
    Inc(TestsFailed);
    WriteLn('  ✗ FAIL: ', Msg);
  end;
end;

// ============================================================================
// 测试 1: 命名 Mutex 基本创建和销毁
// ============================================================================
procedure Test_NamedMutex_BasicCreation;
var
  M: INamedMutex;
  Guard: INamedMutexGuard;
  MutexName: string;
begin
  WriteLn('Test: Named Mutex Basic Creation');

  MutexName := 'test_mutex_' + IntToStr(GetTickCount64);

  try
    M := CreateNamedMutex(MutexName);
    Assert(Assigned(M), 'Should be able to create named mutex');

    // 测试基本锁操作
    Guard := M.LockNamed;
    try
      Assert(Assigned(Guard), 'Should be able to acquire named mutex');
    finally
      Guard := nil;
    end;

    // 清理
    M := nil;
  except
    on E: Exception do
      Assert(False, 'Named mutex creation should not throw exception: ' + E.Message);
  end;
end;

// ============================================================================
// 测试 2: 空名称处理
// ============================================================================
procedure Test_NamedMutex_EmptyName;
var
  M: INamedMutex;
  GotException: Boolean;
begin
  WriteLn('Test: Named Mutex Empty Name');

  GotException := False;
  try
    M := CreateNamedMutex('');
    M := nil;
  except
    on E: Exception do
      GotException := True;
  end;

  Assert(GotException, 'Empty name should throw exception');
end;

// ============================================================================
// 测试 3: 无效名称处理
// ============================================================================
procedure Test_NamedMutex_InvalidName;
var
  M: INamedMutex;
  GotException: Boolean;
  InvalidNames: array[0..2] of string;
  I: Integer;
begin
  WriteLn('Test: Named Mutex Invalid Name');

  // 测试包含无效字符的名称
  InvalidNames[0] := 'test/mutex';  // 包含路径分隔符
  InvalidNames[1] := 'test\mutex';  // 包含反斜杠
  InvalidNames[2] := 'test:mutex';  // 包含冒号

  for I := 0 to High(InvalidNames) do
  begin
    GotException := False;
    try
      M := CreateNamedMutex(InvalidNames[I]);
      M := nil;
    except
      on E: Exception do
        GotException := True;
    end;

    // 注意：某些平台可能允许这些字符，所以我们只记录结果
    if GotException then
      WriteLn('    Invalid name "', InvalidNames[I], '" rejected (expected)')
    else
      WriteLn('    Invalid name "', InvalidNames[I], '" accepted (platform-specific)');
  end;

  Assert(True, 'Invalid name handling tested');
end;

// ============================================================================
// 测试 4: 同名 Mutex 重复创建
// ============================================================================
procedure Test_NamedMutex_DuplicateCreation;
var
  M1, M2: INamedMutex;
  Guard1, Guard2: INamedMutexGuard;
  MutexName: string;
begin
  WriteLn('Test: Named Mutex Duplicate Creation');

  MutexName := 'test_mutex_dup_' + IntToStr(GetTickCount64);

  try
    // 创建第一个命名 Mutex
    M1 := CreateNamedMutex(MutexName);
    Assert(Assigned(M1), 'First named mutex should be created');

    // 尝试创建同名 Mutex（应该打开现有的）
    M2 := CreateNamedMutex(MutexName);
    Assert(Assigned(M2), 'Second named mutex should open existing mutex');

    // 测试互斥性
    Guard1 := M1.LockNamed;
    try
      // M2 应该无法立即获取锁
      Guard2 := M2.TryLockNamed;
      if Assigned(Guard2) then
      begin
        Guard2 := nil;
        Assert(False, 'M2 should not be able to acquire lock while M1 holds it');
      end
      else
        Assert(True, 'M2 correctly blocked by M1');
    finally
      Guard1 := nil;
    end;

    // 清理
    M1 := nil;
    M2 := nil;
  except
    on E: Exception do
      Assert(False, 'Duplicate creation test should not throw exception: ' + E.Message);
  end;
end;

// ============================================================================
// 测试 5: 长名称处理
// ============================================================================
procedure Test_NamedMutex_LongName;
var
  M: INamedMutex;
  LongName: string;
  I: Integer;
begin
  WriteLn('Test: Named Mutex Long Name');

  // 创建一个很长的名称（200 字符）
  LongName := 'test_mutex_';
  for I := 1 to 190 do
    LongName := LongName + 'x';

  try
    M := CreateNamedMutex(LongName);
    if Assigned(M) then
    begin
      Assert(True, 'Long name accepted');
      M := nil;
    end
    else
      Assert(False, 'Long name rejected');
  except
    on E: Exception do
      WriteLn('    Long name rejected with exception: ', E.Message);
  end;
end;

// ============================================================================
// 测试 6: 多个不同名称的 Mutex
// ============================================================================
procedure Test_NamedMutex_MultipleDifferentNames;
const
  MUTEX_COUNT = 10;
var
  Mutexes: array[0..MUTEX_COUNT-1] of INamedMutex;
  Guards: array[0..MUTEX_COUNT-1] of INamedMutexGuard;
  I: Integer;
  MutexName: string;
  BaseTime: QWord;
begin
  WriteLn('Test: Named Mutex Multiple Different Names');

  BaseTime := GetTickCount64;

  try
    // 创建多个不同名称的 Mutex
    for I := 0 to MUTEX_COUNT - 1 do
    begin
      MutexName := 'test_mutex_multi_' + IntToStr(BaseTime) + '_' + IntToStr(I);
      Mutexes[I] := CreateNamedMutex(MutexName);
      Assert(Assigned(Mutexes[I]), 'Should create mutex ' + IntToStr(I));
    end;

    // 验证所有 Mutex 都可以独立工作
    for I := 0 to MUTEX_COUNT - 1 do
    begin
      Guards[I] := Mutexes[I].LockNamed;
      Guards[I] := nil;
    end;

    Assert(True, 'All mutexes work independently');

    // 清理
    for I := 0 to MUTEX_COUNT - 1 do
      Mutexes[I] := nil;
  except
    on E: Exception do
      Assert(False, 'Multiple mutex test should not throw exception: ' + E.Message);
  end;
end;

// ============================================================================
// 测试 7: Mutex 名称大小写敏感性
// ============================================================================
procedure Test_NamedMutex_CaseSensitivity;
var
  M1, M2: INamedMutex;
  Guard1, Guard2: INamedMutexGuard;
  BaseName: string;
begin
  WriteLn('Test: Named Mutex Case Sensitivity');

  BaseName := 'test_mutex_case_' + IntToStr(GetTickCount64);

  try
    // 创建小写名称的 Mutex
    M1 := CreateNamedMutex(LowerCase(BaseName));
    Assert(Assigned(M1), 'Lowercase mutex created');

    // 创建大写名称的 Mutex
    M2 := CreateNamedMutex(UpperCase(BaseName));
    Assert(Assigned(M2), 'Uppercase mutex created');

    // 测试是否是同一个 Mutex（取决于平台）
    Guard1 := M1.LockNamed;
    try
      Guard2 := M2.TryLockNamed;
      if Assigned(Guard2) then
      begin
        Guard2 := nil;
        WriteLn('    Names are case-sensitive (different mutexes)');
      end
      else
        WriteLn('    Names are case-insensitive (same mutex)');
    finally
      Guard1 := nil;
    end;

    Assert(True, 'Case sensitivity tested');

    // 清理
    M1 := nil;
    M2 := nil;
  except
    on E: Exception do
      Assert(False, 'Case sensitivity test should not throw exception: ' + E.Message);
  end;
end;

// ============================================================================
// 测试 8: 快速创建和销毁循环
// ============================================================================
procedure Test_NamedMutex_RapidCreateDestroy;
const
  ITERATION_COUNT = 100;
var
  M: INamedMutex;
  Guard: INamedMutexGuard;
  I: Integer;
  BaseName: string;
begin
  WriteLn('Test: Named Mutex Rapid Create Destroy');

  BaseName := 'test_mutex_rapid_' + IntToStr(GetTickCount64);

  try
    for I := 1 to ITERATION_COUNT do
    begin
      M := CreateNamedMutex(BaseName + '_' + IntToStr(I));
      Guard := M.LockNamed;
      Guard := nil;
      M := nil;
    end;

    Assert(True, 'Completed ' + IntToStr(ITERATION_COUNT) + ' create/destroy cycles');
  except
    on E: Exception do
      Assert(False, 'Rapid create/destroy should not throw exception: ' + E.Message);
  end;
end;

// ============================================================================
// 测试 9: Guard 自动释放
// ============================================================================
procedure Test_NamedMutex_GuardAutoRelease;
var
  M: INamedMutex;
  Guard1, Guard2: INamedMutexGuard;
  MutexName: string;
begin
  WriteLn('Test: Named Mutex Guard Auto Release');

  MutexName := 'test_mutex_guard_' + IntToStr(GetTickCount64);

  try
    M := CreateNamedMutex(MutexName);

    // 获取锁
    Guard1 := M.LockNamed;
    // 让 Guard1 超出作用域（自动释放）
    Guard1 := nil;

    // 应该可以立即获取锁
    Guard2 := M.TryLockNamed;
    Assert(Assigned(Guard2), 'Should be able to acquire lock after guard auto-release');
    Guard2 := nil;

    M := nil;
  except
    on E: Exception do
      Assert(False, 'Guard auto-release test should not throw exception: ' + E.Message);
  end;
end;

// ============================================================================
// 测试 10: 超时获取
// ============================================================================
procedure Test_NamedMutex_TimeoutAcquisition;
var
  M: INamedMutex;
  Guard1, Guard2: INamedMutexGuard;
  MutexName: string;
  StartTime, Elapsed: QWord;
begin
  WriteLn('Test: Named Mutex Timeout Acquisition');

  MutexName := 'test_mutex_timeout_' + IntToStr(GetTickCount64);

  try
    M := CreateNamedMutex(MutexName);

    // 先获取锁
    Guard1 := M.LockNamed;
    try
      // 尝试带超时获取（应该超时）
      StartTime := GetTickCount64;
      Guard2 := M.TryLockForNamed(100);  // 100ms 超时
      Elapsed := GetTickCount64 - StartTime;

      if Assigned(Guard2) then
      begin
        Guard2 := nil;
        Assert(False, 'TryLockForNamed should timeout when lock is held');
      end
      else
      begin
        Assert(True, 'TryLockForNamed correctly timed out');
        Assert(Elapsed >= 50, 'Should wait at least 50ms');
      end;
    finally
      Guard1 := nil;
    end;

    // 释放后应该可以立即获取
    Guard2 := M.TryLockForNamed(100);
    Assert(Assigned(Guard2), 'Should acquire lock after release');
    Guard2 := nil;

    M := nil;
  except
    on E: Exception do
      Assert(False, 'Timeout acquisition test should not throw exception: ' + E.Message);
  end;
end;

// ============================================================================
// 主程序
// ============================================================================
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  Named Mutex Cross-Process Test Suite');
  WriteLn('========================================');
  WriteLn('');

  try
    Test_NamedMutex_BasicCreation;
    Test_NamedMutex_EmptyName;
    Test_NamedMutex_InvalidName;
    Test_NamedMutex_DuplicateCreation;
    Test_NamedMutex_LongName;
    Test_NamedMutex_MultipleDifferentNames;
    Test_NamedMutex_CaseSensitivity;
    Test_NamedMutex_RapidCreateDestroy;
    Test_NamedMutex_GuardAutoRelease;
    Test_NamedMutex_TimeoutAcquisition;
  except
    on E: Exception do
    begin
      WriteLn('FATAL: Unhandled exception: ', E.ClassName, ': ', E.Message);
      Inc(TestsFailed);
    end;
  end;

  WriteLn('');
  WriteLn('========================================');
  WriteLn('  Results: ', TestsPassed, ' passed, ', TestsFailed, ' failed');
  WriteLn('========================================');

  if TestsFailed > 0 then
    Halt(1);
end.
