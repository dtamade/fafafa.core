{$CODEPAGE UTF8}
unit quick_test;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.sem;

type
  TQuickTest = class(TTestCase)
  published
    procedure TestBasicSemaphore;
    procedure TestSemaphoreGuard;
  end;

implementation

procedure TQuickTest.TestBasicSemaphore;
var
  Sem: ISem;
begin
  // 测试基本创建
  Sem := MakeSem(1, 3);
  AssertNotNull('Semaphore should not be nil', Sem);
  
  // 测试基本操作
  AssertEquals('Initial count should be 1', 1, Sem.GetAvailableCount);
  AssertEquals('Max count should be 3', 3, Sem.GetMaxCount);
  
  // 测试获取和释放
  Sem.Acquire;
  AssertEquals('After acquire, count should be 0', 0, Sem.GetAvailableCount);
  
  Sem.Release;
  AssertEquals('After release, count should be 1', 1, Sem.GetAvailableCount);
end;

procedure TQuickTest.TestSemaphoreGuard;
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  Sem := MakeSem(2, 3);
  
  // 测试守卫创建
  Guard := Sem.AcquireGuard;
  AssertNotNull('Guard should not be nil', Guard);
  AssertEquals('Guard should hold 1 permit', 1, Guard.GetCount);
  AssertEquals('Semaphore should have 1 available', 1, Sem.GetAvailableCount);
  
  // 测试手动释放
  Guard.Release;
  AssertEquals('After manual release, guard should hold 0', 0, Guard.GetCount);
  AssertEquals('After manual release, semaphore should have 2', 2, Sem.GetAvailableCount);
end;

initialization
  RegisterTest(TQuickTest);

end.
