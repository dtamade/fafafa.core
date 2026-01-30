unit fafafa.core.sync.recMutex.testcase.simple;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.recMutex;

type
  // 简化的测试用例，只测试基本功能
  TTestCase_Simple = class(TTestCase)
  private
    FRecMutex: IRecMutex;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_BasicAcquireRelease;
    procedure Test_Reentrancy;
    procedure Test_TryAcquire;
    procedure Test_TryAcquire_Zero;
  end;

implementation

// ===== TTestCase_Simple =====

procedure TTestCase_Simple.SetUp;
begin
  FRecMutex := MakeRecMutex;
end;

procedure TTestCase_Simple.TearDown;
begin
  FRecMutex := nil;
end;

procedure TTestCase_Simple.Test_BasicAcquireRelease;
begin
  // 基本的获取和释放测试
  FRecMutex.Acquire;
  FRecMutex.Release;
  
  // 验证锁已释放
  AssertTrue('Lock should be available after release', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_Simple.Test_Reentrancy;
begin
  // 测试重入功能
  FRecMutex.Acquire;
  try
    // 同一线程再次获取锁应该成功
    FRecMutex.Acquire;
    try
      // 嵌套临界区
      AssertTrue('Nested acquire should succeed', True);
    finally
      FRecMutex.Release;
    end;
  finally
    FRecMutex.Release;
  end;
  
  // 验证锁已完全释放
  AssertTrue('Lock should be available after all releases', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_Simple.Test_TryAcquire;
begin
  // 测试 TryAcquire 基本功能
  AssertTrue('TryAcquire should succeed when lock is free', FRecMutex.TryAcquire);
  FRecMutex.Release;
end;

procedure TTestCase_Simple.Test_TryAcquire_Zero;
begin
  // 测试零超时的 TryAcquire
  AssertTrue('TryAcquire(0) should succeed when lock is free', FRecMutex.TryAcquire(0));
  FRecMutex.Release;
end;

initialization
  RegisterTest(TTestCase_Simple);

end.
