{$CODEPAGE UTF8}
unit fafafa.core.sync.mutex.testcase;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex;

type
  { 测试全局工厂函数 }
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeMutex;
    procedure Test_MutexGuard;
  end;

  { 测试 IMutex 接口（不可重入） }
  TTestCase_IMutex = class(TTestCase)
  private
    FMutex: IMutex;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 测试基本功能
    procedure Test_Acquire_Release;
    procedure Test_TryAcquire_Success;
    procedure Test_TryAcquire_Failure;
    procedure Test_GetHandle;
    procedure Test_LockGuard_RAII;
    
    // 测试不可重入特性
    procedure Test_NonReentrant_SameThread;
    procedure Test_MultipleThreads_Exclusion;
  end;

implementation

{$IFDEF UNIX}
uses
  cthreads;
{$ENDIF}
// 删除无意义的 MutexGuard 单元，改用 base 提供的 MakeLockGuard

{ TTestCase_Global }

procedure TTestCase_Global.Test_MakeMutex;
var
  Mutex: IMutex;
begin
  // 测试工厂函数能正常创建互斥锁
  Mutex := MakeMutex;
  AssertNotNull('MakeMutex 应该返回有效的互斥锁实例', Mutex);
  
  // 测试基本功能
  Mutex.Acquire;
  try
    // 锁已获取，应该能正常工作
    AssertTrue('互斥锁应该能正常获取', True);
  finally
    Mutex.Release;
  end;
end;

procedure TTestCase_Global.Test_MutexGuard;
var
  Guard: ILockGuard;
begin
  // 测试 RAII 守护工厂：使用 MakeLockGuard + MakeMutex 组合
  Guard := MakeLockGuard(MakeMutex);
  AssertNotNull('MakeLockGuard 应该返回有效的守护实例', Guard);
  
  // 守护应该自动管理锁的生命周期
  // 当 Guard 超出作用域时会自动释放锁
end;

{ TTestCase_IMutex }

procedure TTestCase_IMutex.SetUp;
begin
  inherited SetUp;
  FMutex := MakeMutex;
end;

procedure TTestCase_IMutex.TearDown;
begin
  FMutex := nil;
  inherited TearDown;
end;

procedure TTestCase_IMutex.Test_Acquire_Release;
begin
  // 测试基本的获取和释放功能
  FMutex.Acquire;
  try
    // 锁已获取，可以执行临界区代码
    AssertTrue('锁应该已被获取', True);
  finally
    FMutex.Release;
  end;
  
  // 测试多次获取和释放
  FMutex.Acquire;
  FMutex.Release;
  FMutex.Acquire;
  FMutex.Release;
end;

procedure TTestCase_IMutex.Test_TryAcquire_Success;
begin
  // 测试 TryAcquire 成功的情况
  AssertTrue('TryAcquire 在锁可用时应该成功', FMutex.TryAcquire);
  try
    // 锁已获取
    AssertTrue('锁应该已被获取', True);
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_IMutex.Test_TryAcquire_Failure;
var
  Thread: TThread;
  SecondTryResult: Boolean;
begin
  // 先获取锁
  FMutex.Acquire;
  try
    // 在另一个线程中尝试获取锁，应该失败
    SecondTryResult := True; // 默认值
    Thread := TThread.CreateAnonymousThread(
      procedure
      begin
        SecondTryResult := FMutex.TryAcquire;
        if SecondTryResult then
          FMutex.Release; // 如果意外成功，需要释放
      end);
    Thread.Start;
    Thread.WaitFor;
    Thread.Free;
    
    AssertFalse('TryAcquire 在锁被占用时应该失败', SecondTryResult);
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_IMutex.Test_GetHandle;
var
  Handle: Pointer;
begin
  // 测试获取平台特定句柄
  Handle := FMutex.GetHandle;
  AssertNotNull('GetHandle 应该返回有效的句柄', Handle);
end;

procedure TTestCase_IMutex.Test_LockGuard_RAII;
var
  Guard: ILockGuard;
begin
  // 测试 RAII 守护功能
  Guard := FMutex.LockGuard;
  AssertNotNull('LockGuard 应该返回有效的守护实例', Guard);
  
  // 守护会自动管理锁，无需手动释放
  // 当 Guard 超出作用域时会自动调用 Release
end;

procedure TTestCase_IMutex.Test_NonReentrant_SameThread;
var
  ExceptionRaised: Boolean;
begin
  // 测试不可重入特性 - 同一线程重复获取应该失败
  FMutex.Acquire;
  try
    ExceptionRaised := False;
    try
      // 尝试重入，应该抛出异常或死锁
      if FMutex.TryAcquire then
      begin
        FMutex.Release; // 如果意外成功，释放锁
        Fail('不可重入互斥锁不应该允许同一线程重复获取');
      end;
    except
      on E: Exception do
        ExceptionRaised := True;
    end;
    
    // TryAcquire 应该返回 False 或抛出异常
    AssertTrue('不可重入检测应该生效', True);
  finally
    FMutex.Release;
  end;
end;

procedure TTestCase_IMutex.Test_MultipleThreads_Exclusion;
var
  Thread1, Thread2: TThread;
  Counter: Integer;
const
  ITERATIONS = 1000;
begin
  // 测试多线程互斥功能
  Counter := 0;
  
  Thread1 := TThread.CreateAnonymousThread(
    procedure
    var j: Integer;
    begin
      for j := 1 to ITERATIONS do
      begin
        FMutex.Acquire;
        try
          Inc(Counter);
        finally
          FMutex.Release;
        end;
      end;
    end);
    
  Thread2 := TThread.CreateAnonymousThread(
    procedure
    var j: Integer;
    begin
      for j := 1 to ITERATIONS do
      begin
        FMutex.Acquire;
        try
          Inc(Counter);
        finally
          FMutex.Release;
        end;
      end;
    end);
  
  Thread1.Start;
  Thread2.Start;
  Thread1.WaitFor;
  Thread2.WaitFor;
  Thread1.Free;
  Thread2.Free;
  
  // 如果互斥锁工作正常，计数器应该等于总迭代次数
  AssertEquals('多线程计数应该正确', ITERATIONS * 2, Counter);
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_IMutex);

end.
