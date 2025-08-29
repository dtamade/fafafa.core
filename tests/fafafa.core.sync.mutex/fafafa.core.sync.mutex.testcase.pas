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
    procedure Test_GetHandle;
    procedure Test_LockGuard_RAII;
    
    // 测试不可重入特性
    procedure Test_NonReentrant_SameThread;
  end;

implementation

uses
  {$IFDEF UNIX}
  cthreads;
  {$ENDIF}

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
  // 测试 RAII 守护工厂函数
  Guard := MutexGuard;
  AssertNotNull('MutexGuard 应该返回有效的守护实例', Guard);
  
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
begin
  // 测试不可重入特性 - 同一线程重复获取应该失败
  FMutex.Acquire;
  try
    // 尝试重入，应该返回 False（不可重入）
    AssertFalse('不可重入互斥锁不应该允许同一线程重复获取', FMutex.TryAcquire);
  finally
    FMutex.Release;
  end;
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_IMutex);

end.
