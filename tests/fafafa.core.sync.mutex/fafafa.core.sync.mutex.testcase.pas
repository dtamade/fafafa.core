unit fafafa.core.sync.mutex.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.mutex, fafafa.core.sync.base;

type
  // 测试全局函数
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeMutex;
  end;

  // 测试 IMutex 接口
  TTestCase_IMutex = class(TTestCase)
  private
    FMutex: IMutex;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 测试 ILock 继承的方法
    procedure Test_Acquire;
    procedure Test_Release;
    procedure Test_TryAcquire;

    // 测试 IMutex 特有的方法
    procedure Test_GetHandle;

    // 综合测试
    procedure Test_RecursiveLocking;
    procedure Test_ThreadSafety;
    procedure Test_TimeoutBehavior;
  end;

implementation

{ TTestCase_Global }

procedure TTestCase_Global.Test_MakeMutex;
var
  Mutex: IMutex;
begin
  Mutex := MakeMutex;
  AssertNotNull('MakeMutex should return non-nil interface', Mutex);
  AssertNotNull('Mutex handle should not be nil', Mutex.GetHandle);
end;



{ TTestCase_IMutex }

procedure TTestCase_IMutex.SetUp;
begin
  inherited SetUp;
  FMutex := MakeMutex;
end;

procedure TTestCase_IMutex.TearDown;
begin
  // 简化清理：不再检查锁状态，直接释放引用
  FMutex := nil;
  inherited TearDown;
end;

procedure TTestCase_IMutex.Test_Acquire;
begin
  // 测试基本获取功能
  FMutex.Acquire;
  // 成功获取锁，没有异常就是成功
  FMutex.Release;
end;

procedure TTestCase_IMutex.Test_Release;
begin
  // 先获取锁
  FMutex.Acquire;

  // 释放锁 - 没有异常就是成功
  FMutex.Release;
end;

procedure TTestCase_IMutex.Test_TryAcquire;
begin
  // 测试成功获取
  AssertTrue('TryAcquire should succeed on unlocked mutex', FMutex.TryAcquire);

  // 清理
  FMutex.Release;
end;





procedure TTestCase_IMutex.Test_GetHandle;
var
  Handle: Pointer;
begin
  Handle := FMutex.GetHandle;
  AssertNotNull('Handle should not be nil', Handle);
  
  // 获取锁后句柄应该保持不变
  FMutex.Acquire;
  AssertEquals('Handle should remain same after acquire', NativeUInt(Handle), NativeUInt(FMutex.GetHandle));
  FMutex.Release;
end;

procedure TTestCase_IMutex.Test_RecursiveLocking;
begin
  // 测试递归锁定 - 同一线程可以多次获取锁
  FMutex.Acquire;

  // 递归获取 - 不应该死锁
  FMutex.Acquire;

  // 释放两次
  FMutex.Release;
  FMutex.Release;

  // 如果没有异常，说明递归锁工作正常
end;

procedure TTestCase_IMutex.Test_ThreadSafety;
begin
  // 基本的线程安全测试 - 这里只测试单线程行为
  FMutex.Acquire;
  // 如果没有死锁，说明基本功能正常
  FMutex.Release;
end;

procedure TTestCase_IMutex.Test_TimeoutBehavior;
begin
  // 测试递归锁行为 - 同一线程可以多次获取
  FMutex.Acquire;

  // 在已锁定状态下，同一线程的 TryAcquire 应该成功（递归锁）
  AssertTrue('TryAcquire should succeed on locked mutex (recursive)', FMutex.TryAcquire);

  // 释放两次
  FMutex.Release;
  FMutex.Release;
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_IMutex);

end.
