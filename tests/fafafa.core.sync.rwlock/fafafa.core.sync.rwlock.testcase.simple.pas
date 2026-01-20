unit fafafa.core.sync.rwlock.testcase.simple;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.rwlock;

type
  // 全局函数测试
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_CreateRWLock;
  end;

  // TRWLock 类测试
  TTestCase_TRWLock = class(TTestCase)
  private
    FRWLock: IRWLock;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基础功能测试
    procedure Test_AcquireRead;
    procedure Test_ReleaseRead;
    procedure Test_AcquireWrite;
    procedure Test_ReleaseWrite;
    procedure Test_TryAcquireRead;
    procedure Test_TryAcquireWrite;
    procedure Test_GetReaderCount;
    procedure Test_IsWriteLocked;
    procedure Test_IsReadLocked;
    procedure Test_GetWriterThread;
    procedure Test_GetMaxReaders;
    
    // 现代化 API 测试
    procedure Test_ReadGuard;
    procedure Test_WriteGuard;
  end;

implementation

{ TTestCase_Global }

procedure TTestCase_Global.Test_CreateRWLock;
var
  L: IRWLock;
begin
  L := MakeRWLock;
  AssertNotNull(L);
  AssertEquals(0, L.GetReaderCount);
  AssertFalse(L.IsWriteLocked);
  AssertFalse(L.IsReadLocked);
end;

{ TTestCase_TRWLock }

procedure TTestCase_TRWLock.SetUp;
begin
  inherited SetUp;
  FRWLock := MakeRWLock;
end;

procedure TTestCase_TRWLock.TearDown;
begin
  FRWLock := nil;
  inherited TearDown;
end;

procedure TTestCase_TRWLock.Test_AcquireRead;
begin
  FRWLock.AcquireRead;
  try
    AssertEquals(1, FRWLock.GetReaderCount);
    AssertTrue(FRWLock.IsReadLocked);
    AssertFalse(FRWLock.IsWriteLocked);
  finally
    FRWLock.ReleaseRead;
  end;
end;

procedure TTestCase_TRWLock.Test_ReleaseRead;
begin
  FRWLock.AcquireRead;
  AssertEquals(1, FRWLock.GetReaderCount);
  
  FRWLock.ReleaseRead;
  AssertEquals(0, FRWLock.GetReaderCount);
  AssertFalse(FRWLock.IsReadLocked);
end;

procedure TTestCase_TRWLock.Test_AcquireWrite;
begin
  FRWLock.AcquireWrite;
  try
    AssertTrue(FRWLock.IsWriteLocked);
    AssertEquals(GetCurrentThreadId, FRWLock.GetWriterThread);
    AssertFalse(FRWLock.IsReadLocked);
  finally
    FRWLock.ReleaseWrite;
  end;
end;

procedure TTestCase_TRWLock.Test_ReleaseWrite;
begin
  FRWLock.AcquireWrite;
  AssertTrue(FRWLock.IsWriteLocked);
  
  FRWLock.ReleaseWrite;
  AssertFalse(FRWLock.IsWriteLocked);
  AssertEquals(0, FRWLock.GetWriterThread);
end;

procedure TTestCase_TRWLock.Test_TryAcquireRead;
var
  Success: Boolean;
begin
  Success := FRWLock.TryAcquireRead;
  AssertTrue(Success);
  try
    AssertEquals(1, FRWLock.GetReaderCount);
    AssertTrue(FRWLock.IsReadLocked);
  finally
    FRWLock.ReleaseRead;
  end;
end;

procedure TTestCase_TRWLock.Test_TryAcquireWrite;
var
  Success: Boolean;
begin
  Success := FRWLock.TryAcquireWrite;
  AssertTrue(Success);
  try
    AssertTrue(FRWLock.IsWriteLocked);
    AssertEquals(GetCurrentThreadId, FRWLock.GetWriterThread);
  finally
    FRWLock.ReleaseWrite;
  end;
end;

procedure TTestCase_TRWLock.Test_GetReaderCount;
begin
  AssertEquals(0, FRWLock.GetReaderCount);
  
  FRWLock.AcquireRead;
  try
    AssertEquals(1, FRWLock.GetReaderCount);
  finally
    FRWLock.ReleaseRead;
  end;
  
  AssertEquals(0, FRWLock.GetReaderCount);
end;

procedure TTestCase_TRWLock.Test_IsWriteLocked;
begin
  AssertFalse(FRWLock.IsWriteLocked);
  
  FRWLock.AcquireWrite;
  try
    AssertTrue(FRWLock.IsWriteLocked);
  finally
    FRWLock.ReleaseWrite;
  end;
  
  AssertFalse(FRWLock.IsWriteLocked);
end;

procedure TTestCase_TRWLock.Test_IsReadLocked;
begin
  AssertFalse(FRWLock.IsReadLocked);
  
  FRWLock.AcquireRead;
  try
    AssertTrue(FRWLock.IsReadLocked);
  finally
    FRWLock.ReleaseRead;
  end;
  
  AssertFalse(FRWLock.IsReadLocked);
end;

procedure TTestCase_TRWLock.Test_GetWriterThread;
begin
  AssertEquals(0, FRWLock.GetWriterThread);
  
  FRWLock.AcquireWrite;
  try
    AssertEquals(GetCurrentThreadId, FRWLock.GetWriterThread);
  finally
    FRWLock.ReleaseWrite;
  end;
  
  AssertEquals(0, FRWLock.GetWriterThread);
end;

procedure TTestCase_TRWLock.Test_GetMaxReaders;
begin
  AssertTrue(FRWLock.GetMaxReaders > 0);
end;

procedure TTestCase_TRWLock.Test_ReadGuard;
var
  Guard: IRWLockReadGuard;
begin
  Guard := FRWLock.Read;
  AssertNotNull(Guard);
  AssertEquals(1, FRWLock.GetReaderCount);
  AssertTrue(FRWLock.IsReadLocked);
  
  Guard := nil; // 释放守卫
  AssertEquals(0, FRWLock.GetReaderCount);
  AssertFalse(FRWLock.IsReadLocked);
end;

procedure TTestCase_TRWLock.Test_WriteGuard;
var
  Guard: IRWLockWriteGuard;
begin
  Guard := FRWLock.Write;
  AssertNotNull(Guard);
  AssertTrue(FRWLock.IsWriteLocked);
  AssertEquals(GetCurrentThreadId, FRWLock.GetWriterThread);
  
  Guard := nil; // 释放守卫
  AssertFalse(FRWLock.IsWriteLocked);
  AssertEquals(0, FRWLock.GetWriterThread);
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_TRWLock);

end.
