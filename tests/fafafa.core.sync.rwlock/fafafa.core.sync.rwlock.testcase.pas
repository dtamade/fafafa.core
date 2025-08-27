unit fafafa.core.sync.rwlock.testcase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.rwlock, fafafa.core.sync.base;

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
    procedure Test_TryAcquireRead_Timeout;
    procedure Test_TryAcquireWrite;
    procedure Test_TryAcquireWrite_Timeout;
    procedure Test_GetReaderCount;
    procedure Test_IsWriteLocked;
    procedure Test_IsReadLocked;
    procedure Test_GetWriterThread;
    procedure Test_GetMaxReaders;

    // 并发测试
    procedure Test_Concurrent_MultipleReaders;
    procedure Test_Concurrent_ReaderWriter_Exclusion;
    procedure Test_Concurrent_WriterExclusion;
    procedure Test_Concurrent_ReadWrite_Performance;
  end;

implementation

{ TTestCase_Global }

procedure TTestCase_Global.Test_CreateRWLock;
var
  L: IRWLock;
begin
  L := CreateRWLock;
  AssertNotNull(L);
  AssertEquals(0, L.GetReaderCount);
  AssertFalse(L.IsWriteLocked);
  AssertFalse(L.IsReadLocked);
end;

{ TTestCase_TRWLock }

procedure TTestCase_TRWLock.SetUp;
begin
  inherited SetUp;
  FRWLock := CreateRWLock;
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

procedure TTestCase_TRWLock.Test_TryAcquireRead_Timeout;
var
  LockResult: TLockResult;
begin
  LockResult := FRWLock.TryAcquireRead(100);
  AssertEquals(Ord(lrSuccess), Ord(LockResult));
  try
    AssertEquals(1, FRWLock.GetReaderCount);
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

procedure TTestCase_TRWLock.Test_TryAcquireWrite_Timeout;
var
  LockResult: TLockResult;
begin
  LockResult := FRWLock.TryAcquireWrite(100);
  AssertEquals(Ord(lrSuccess), Ord(LockResult));
  try
    AssertTrue(FRWLock.IsWriteLocked);
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

    FRWLock.AcquireRead;
    try
      AssertEquals(2, FRWLock.GetReaderCount);
    finally
      FRWLock.ReleaseRead;
    end;

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

procedure TTestCase_TReadWriteLock.Test_Concurrent_MultipleReaders;
var
  ReaderCount: Integer;
  Thread1, Thread2, Thread3: TThreadID;
  
  function ReaderThreadProc(Data: Pointer): PtrInt;
  begin
    FRWLock.AcquireRead;
    try
      InterlockedIncrement(ReaderCount);
      Sleep(100); // 持有读锁一段时间
      InterlockedDecrement(ReaderCount);
    finally
      FRWLock.ReleaseRead;
    end;
    Result := 0;
  end;
  
begin
  ReaderCount := 0;
  
  // 启动多个读者线程
  Thread1 := BeginThread(@ReaderThreadProc, nil);
  Thread2 := BeginThread(@ReaderThreadProc, nil);
  Thread3 := BeginThread(@ReaderThreadProc, nil);
  
  // 等待一段时间，检查多个读者可以同时持有锁
  Sleep(50);
  AssertTrue(FRWLock.GetReaderCount >= 2, '多个读者应该能同时持有读锁');
  
  // 等待所有线程完成
  WaitForThreadTerminate(Thread1, 5000);
  WaitForThreadTerminate(Thread2, 5000);
  WaitForThreadTerminate(Thread3, 5000);
  
  AssertEquals(0, FRWLock.GetReaderCount);
  AssertFalse(FRWLock.IsReadLocked);
end;

procedure TTestCase_TReadWriteLock.Test_Concurrent_ReaderWriter_Exclusion;
var
  SharedValue: Integer;
  ReaderDone, WriterDone: Boolean;
  ReaderThread, WriterThread: TThreadID;
  
  function ReaderThreadProc(Data: Pointer): PtrInt;
  var
    LocalValue: Integer;
  begin
    Sleep(10); // 让写者先启动
    FRWLock.AcquireRead;
    try
      LocalValue := SharedValue;
      Sleep(50); // 持有读锁
      // 验证值没有被写者修改
      AssertEquals(LocalValue, SharedValue, '读者持有锁期间值不应被修改');
    finally
      FRWLock.ReleaseRead;
    end;
    ReaderDone := True;
    Result := 0;
  end;
  
  function WriterThreadProc(Data: Pointer): PtrInt;
  begin
    // 尝试获取写锁，应该等待读者完成
    FRWLock.AcquireWrite;
    try
      SharedValue := 42;
    finally
      FRWLock.ReleaseWrite;
    end;
    WriterDone := True;
    Result := 0;
  end;
  
begin
  SharedValue := 0;
  ReaderDone := False;
  WriterDone := False;
  
  WriterThread := BeginThread(@WriterThreadProc, nil);
  ReaderThread := BeginThread(@ReaderThreadProc, nil);
  
  // 等待线程完成
  WaitForThreadTerminate(ReaderThread, 5000);
  WaitForThreadTerminate(WriterThread, 5000);
  
  AssertTrue(ReaderDone);
  AssertTrue(WriterDone);
  AssertEquals(42, SharedValue);
end;

procedure TTestCase_TReadWriteLock.Test_Concurrent_WriterExclusion;
var
  SharedValue: Integer;
  Writer1Done, Writer2Done: Boolean;
  Writer1Thread, Writer2Thread: TThreadID;
  
  function Writer1ThreadProc(Data: Pointer): PtrInt;
  begin
    FRWLock.AcquireWrite;
    try
      SharedValue := 1;
      Sleep(50);
      SharedValue := 11;
    finally
      FRWLock.ReleaseWrite;
    end;
    Writer1Done := True;
    Result := 0;
  end;
  
  function Writer2ThreadProc(Data: Pointer): PtrInt;
  begin
    Sleep(10); // 让第一个写者先获取锁
    FRWLock.AcquireWrite;
    try
      // 此时 SharedValue 应该是 11（第一个写者完成）
      AssertTrue((SharedValue = 11) or (SharedValue = 0), '写者应该互斥执行');
      SharedValue := 22;
    finally
      FRWLock.ReleaseWrite;
    end;
    Writer2Done := True;
    Result := 0;
  end;
  
begin
  SharedValue := 0;
  Writer1Done := False;
  Writer2Done := False;
  
  Writer1Thread := BeginThread(@Writer1ThreadProc, nil);
  Writer2Thread := BeginThread(@Writer2ThreadProc, nil);
  
  // 等待线程完成
  WaitForThreadTerminate(Writer1Thread, 5000);
  WaitForThreadTerminate(Writer2Thread, 5000);
  
  AssertTrue(Writer1Done);
  AssertTrue(Writer2Done);
  AssertEquals(22, SharedValue);
end;

procedure TTestCase_TReadWriteLock.Test_Concurrent_ReadWrite_Performance;
var
  ReadCount, WriteCount: Integer;
  StartTime: QWord;
  Duration: QWord;
  i: Integer;
  Threads: array[0..9] of TThreadID;
  
  function ReaderThreadProc(Data: Pointer): PtrInt;
  var
    j: Integer;
  begin
    for j := 1 to 100 do
    begin
      FRWLock.AcquireRead;
      try
        InterlockedIncrement(ReadCount);
        // 模拟读操作
      finally
        FRWLock.ReleaseRead;
      end;
    end;
    Result := 0;
  end;
  
  function WriterThreadProc(Data: Pointer): PtrInt;
  var
    j: Integer;
  begin
    for j := 1 to 10 do
    begin
      FRWLock.AcquireWrite;
      try
        InterlockedIncrement(WriteCount);
        // 模拟写操作
        Sleep(1);
      finally
        FRWLock.ReleaseWrite;
      end;
    end;
    Result := 0;
  end;
  
begin
  ReadCount := 0;
  WriteCount := 0;
  StartTime := GetTickCount64;
  
  // 启动 8 个读者线程和 2 个写者线程
  for i := 0 to 7 do
    Threads[i] := BeginThread(@ReaderThreadProc, nil);
  for i := 8 to 9 do
    Threads[i] := BeginThread(@WriterThreadProc, nil);
  
  // 等待所有线程完成
  for i := 0 to 9 do
    WaitForThreadTerminate(Threads[i], 10000);
  
  Duration := GetTickCount64 - StartTime;
  
  AssertEquals(800, ReadCount, '应该完成 800 次读操作');
  AssertEquals(20, WriteCount, '应该完成 20 次写操作');
  
  WriteLn('读写锁性能测试完成，耗时: ', Duration, 'ms');
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_TRWLock);

end.
