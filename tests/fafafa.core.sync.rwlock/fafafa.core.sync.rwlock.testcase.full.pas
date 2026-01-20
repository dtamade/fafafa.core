unit fafafa.core.sync.rwlock.testcase.full;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.math,
  fafafa.core.sync.rwlock;

type
  // 完整测试套件
  TTestCase_Full = class(TTestCase)
  private
    FRWLock: IRWLock;
    FSharedValue: Integer;
    FReadCount: Integer;
    FWriteCount: Integer;
    FErrorCount: Integer;
    FTestCompleted: Boolean;
    
    // 线程数据结构
    type
      PThreadData = ^TThreadData;
      TThreadData = record
        TestCase: TTestCase_Full;
        ThreadId: Integer;
        OperationCount: Integer;
        Success: Boolean;
      end;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基础功能测试
    procedure Test_01_CreateRWLock;
    procedure Test_02_BasicReadLock;
    procedure Test_03_BasicWriteLock;
    procedure Test_04_TryAcquire;
    procedure Test_05_StateQueries;
    
    // RAII 守卫测试
    procedure Test_06_ReadGuard;
    procedure Test_07_WriteGuard;
    procedure Test_08_GuardTimeout;
    
    // 并发测试
    procedure Test_09_MultipleReaders;
    procedure Test_10_ReaderWriterExclusion;
    procedure Test_11_WriterExclusion;
    
    // 性能测试
    procedure Test_12_ReadPerformance;
    procedure Test_13_WritePerformance;
    procedure Test_14_MixedPerformance;
    procedure Test_15_PerformanceStatistics;
  end;

implementation

{ TTestCase_Full }

procedure TTestCase_Full.SetUp;
begin
  inherited SetUp;
  FRWLock := MakeRWLock;
  FSharedValue := 0;
  FReadCount := 0;
  FWriteCount := 0;
  FErrorCount := 0;
  FTestCompleted := False;
end;

procedure TTestCase_Full.TearDown;
begin
  FTestCompleted := True;
  Sleep(10); // 等待线程结束
  FRWLock := nil;
  inherited TearDown;
end;

// ===== 基础功能测试 =====

procedure TTestCase_Full.Test_01_CreateRWLock;
var
  L: IRWLock;
begin
  L := MakeRWLock;
  AssertNotNull(L);
  AssertEquals(0, L.GetReaderCount);
  AssertFalse(L.IsWriteLocked);
  AssertFalse(L.IsReadLocked);
  AssertTrue(L.GetMaxReaders > 0);
end;

procedure TTestCase_Full.Test_02_BasicReadLock;
begin
  // 测试读锁获取和释放
  FRWLock.AcquireRead;
  try
    AssertEquals(1, FRWLock.GetReaderCount);
    AssertTrue(FRWLock.IsReadLocked);
    AssertFalse(FRWLock.IsWriteLocked);
    
    // 测试多个读锁
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
  AssertFalse(FRWLock.IsReadLocked);
end;

procedure TTestCase_Full.Test_03_BasicWriteLock;
begin
  // 测试写锁获取和释放
  FRWLock.AcquireWrite;
  try
    AssertTrue(FRWLock.IsWriteLocked);
    AssertEquals(GetCurrentThreadId, FRWLock.GetWriterThread);
    AssertFalse(FRWLock.IsReadLocked);
  finally
    FRWLock.ReleaseWrite;
  end;
  
  AssertFalse(FRWLock.IsWriteLocked);
  AssertEquals(0, FRWLock.GetWriterThread);
end;

procedure TTestCase_Full.Test_04_TryAcquire;
var
  Success: Boolean;
  LockResult: TLockResult;
begin
  // 测试非阻塞获取
  Success := FRWLock.TryAcquireRead;
  AssertTrue(Success);
  try
    AssertEquals(1, FRWLock.GetReaderCount);
  finally
    FRWLock.ReleaseRead;
  end;
  
  Success := FRWLock.TryAcquireWrite;
  AssertTrue(Success);
  try
    AssertTrue(FRWLock.IsWriteLocked);
  finally
    FRWLock.ReleaseWrite;
  end;
  
  // 测试带超时的获取
  LockResult := FRWLock.TryAcquireReadEx(100);
  AssertEquals(Ord(TLockResult.lrSuccess), Ord(LockResult));
  try
    AssertEquals(1, FRWLock.GetReaderCount);
  finally
    FRWLock.ReleaseRead;
  end;

  LockResult := FRWLock.TryAcquireWriteEx(100);
  AssertEquals(Ord(TLockResult.lrSuccess), Ord(LockResult));
  try
    AssertTrue(FRWLock.IsWriteLocked);
  finally
    FRWLock.ReleaseWrite;
  end;
end;

procedure TTestCase_Full.Test_05_StateQueries;
begin
  // 初始状态
  AssertEquals(0, FRWLock.GetReaderCount);
  AssertFalse(FRWLock.IsReadLocked);
  AssertFalse(FRWLock.IsWriteLocked);
  AssertEquals(0, FRWLock.GetWriterThread);
  
  // 读锁状态
  FRWLock.AcquireRead;
  try
    AssertEquals(1, FRWLock.GetReaderCount);
    AssertTrue(FRWLock.IsReadLocked);
    AssertFalse(FRWLock.IsWriteLocked);
  finally
    FRWLock.ReleaseRead;
  end;
  
  // 写锁状态
  FRWLock.AcquireWrite;
  try
    AssertTrue(FRWLock.IsWriteLocked);
    AssertEquals(GetCurrentThreadId, FRWLock.GetWriterThread);
    AssertFalse(FRWLock.IsReadLocked);
  finally
    FRWLock.ReleaseWrite;
  end;
end;

// ===== RAII 守卫测试 =====

procedure TTestCase_Full.Test_06_ReadGuard;
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

procedure TTestCase_Full.Test_07_WriteGuard;
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

procedure TTestCase_Full.Test_08_GuardTimeout;
var
  Guard1: IRWLockWriteGuard;
  TimeoutGuard: IRWLockWriteGuard;
begin
  WriteLn('测试: 守卫超时和可重入性');

  // 获取写锁
  WriteLn('获取第一个写锁...');
  Guard1 := FRWLock.Write;
  AssertNotNull(Guard1);
  WriteLn('第一个写锁获取成功, IsWriteLocked=', FRWLock.IsWriteLocked);

  // 在可重入锁中，同一线程可以获取第二个写锁（可重入）
  WriteLn('尝试获取第二个写锁（可重入）...');
  TimeoutGuard := FRWLock.TryWrite(50);
  WriteLn('第二个写锁结果: ', Assigned(TimeoutGuard));
  AssertNotNull(TimeoutGuard);  // 应该成功，因为可重入
  WriteLn('第二个写锁获取成功, IsWriteLocked=', FRWLock.IsWriteLocked);

  // 释放第二个锁
  WriteLn('释放第二个写锁...');
  TimeoutGuard := nil;
  WriteLn('第二个写锁已释放, IsWriteLocked=', FRWLock.IsWriteLocked);

  // 第一个锁仍然有效
  AssertTrue(FRWLock.IsWriteLocked);

  // 释放第一个锁
  Guard1 := nil;

  // 确保守卫析构完成（在接口引用计数系统中，析构可能不是立即的）
  Sleep(1);

  // 现在锁应该完全释放（因为两个守卫都已释放）
  AssertFalse(FRWLock.IsWriteLocked);

  // 现在应该能获取新的锁
  WriteLn('重新获取写锁...');
  TimeoutGuard := FRWLock.TryWrite(50);
  WriteLn('重新获取结果: ', Assigned(TimeoutGuard));
  AssertNotNull(TimeoutGuard);

  TimeoutGuard := nil;
  WriteLn('测试完成');
end;

// ===== 并发测试 =====

// 简化的线程函数
function SimpleReaderProc(Data: Pointer): PtrInt;
var
  TestCase: TTestCase_Full;
  i: Integer;
begin
  TestCase := TTestCase_Full(Data);
  Result := 0;

  for i := 1 to 20 do
  begin
    if TestCase.FTestCompleted then Break;

    TestCase.FRWLock.AcquireRead;
    try
      InterlockedIncrement(TestCase.FReadCount);
      Sleep(1);
    finally
      TestCase.FRWLock.ReleaseRead;
    end;
  end;
end;

function SimpleWriterProc(Data: Pointer): PtrInt;
var
  TestCase: TTestCase_Full;
  i: Integer;
begin
  TestCase := TTestCase_Full(Data);
  Result := 0;

  for i := 1 to 10 do
  begin
    if TestCase.FTestCompleted then Break;

    TestCase.FRWLock.AcquireWrite;
    try
      Inc(TestCase.FSharedValue);
      InterlockedIncrement(TestCase.FWriteCount);
      Sleep(1);
    finally
      TestCase.FRWLock.ReleaseWrite;
    end;
  end;
end;

procedure TTestCase_Full.Test_09_MultipleReaders;
const
  READER_COUNT = 4;
var
  Threads: array[0..READER_COUNT-1] of TThreadID;
  i: Integer;
begin
  WriteLn('测试: 多读者并发');

  // 启动读者线程
  for i := 0 to READER_COUNT-1 do
    Threads[i] := BeginThread(@SimpleReaderProc, Self);

  // 等待完成
  for i := 0 to READER_COUNT-1 do
    WaitForThreadTerminate(Threads[i], 5000);

  WriteLn('读操作总数: ', FReadCount);
  AssertEquals(READER_COUNT * 20, FReadCount);
end;

procedure TTestCase_Full.Test_10_ReaderWriterExclusion;
const
  READER_COUNT = 2;
  WRITER_COUNT = 2;
var
  ReaderThreads: array[0..READER_COUNT-1] of TThreadID;
  WriterThreads: array[0..WRITER_COUNT-1] of TThreadID;
  i: Integer;
  InitialValue: Integer;
begin
  WriteLn('测试: 读写互斥');

  InitialValue := FSharedValue;

  // 启动线程
  for i := 0 to READER_COUNT-1 do
    ReaderThreads[i] := BeginThread(@SimpleReaderProc, Self);

  for i := 0 to WRITER_COUNT-1 do
    WriterThreads[i] := BeginThread(@SimpleWriterProc, Self);

  // 等待完成
  for i := 0 to READER_COUNT-1 do
    WaitForThreadTerminate(ReaderThreads[i], 5000);

  for i := 0 to WRITER_COUNT-1 do
    WaitForThreadTerminate(WriterThreads[i], 5000);

  WriteLn('读操作: ', FReadCount, ', 写操作: ', FWriteCount);
  WriteLn('共享值: ', InitialValue, ' -> ', FSharedValue);

  AssertEquals(READER_COUNT * 20, FReadCount);
  AssertEquals(WRITER_COUNT * 10, FWriteCount);
  AssertEquals(InitialValue + FWriteCount, FSharedValue);
end;

procedure TTestCase_Full.Test_11_WriterExclusion;
const
  WRITER_COUNT = 3;
var
  Threads: array[0..WRITER_COUNT-1] of TThreadID;
  i: Integer;
  InitialValue: Integer;
begin
  WriteLn('测试: 写者互斥');

  InitialValue := FSharedValue;

  // 启动写者线程
  for i := 0 to WRITER_COUNT-1 do
    Threads[i] := BeginThread(@SimpleWriterProc, Self);

  // 等待完成
  for i := 0 to WRITER_COUNT-1 do
    WaitForThreadTerminate(Threads[i], 5000);

  WriteLn('写操作: ', FWriteCount, ', 共享值: ', InitialValue, ' -> ', FSharedValue);

  AssertEquals(WRITER_COUNT * 10, FWriteCount);
  AssertEquals(InitialValue + FWriteCount, FSharedValue);
end;

// ===== 性能测试 =====

// 性能测试线程函数
function PerfReaderProc(Data: Pointer): PtrInt;
var
  TestCase: TTestCase_Full;
  i: Integer;
begin
  TestCase := TTestCase_Full(Data);
  Result := 0;

  for i := 1 to 5000 do
  begin
    if TestCase.FTestCompleted then Break;

    TestCase.FRWLock.AcquireRead;
    try
      InterlockedIncrement(TestCase.FReadCount);
    finally
      TestCase.FRWLock.ReleaseRead;
    end;
  end;
end;

function PerfWriterProc(Data: Pointer): PtrInt;
var
  TestCase: TTestCase_Full;
  i: Integer;
begin
  TestCase := TTestCase_Full(Data);
  Result := 0;

  for i := 1 to 2000 do
  begin
    if TestCase.FTestCompleted then Break;

    TestCase.FRWLock.AcquireWrite;
    try
      InterlockedIncrement(TestCase.FWriteCount);
    finally
      TestCase.FRWLock.ReleaseWrite;
    end;
  end;
end;

procedure TTestCase_Full.Test_12_ReadPerformance;
const
  READER_COUNT = 4;
var
  Threads: array[0..READER_COUNT-1] of TThreadID;
  i: Integer;
  StartTime, EndTime: QWord;
  OpsPerSec: Double;
begin
  WriteLn('测试: 读锁性能');

  StartTime := GetTickCount64;

  // 启动读者线程
  for i := 0 to READER_COUNT-1 do
    Threads[i] := BeginThread(@PerfReaderProc, Self);

  // 等待完成
  for i := 0 to READER_COUNT-1 do
    WaitForThreadTerminate(Threads[i], 10000);

  EndTime := GetTickCount64;
  if EndTime = StartTime then Inc(EndTime);
  OpsPerSec := FReadCount * 1000.0 / (EndTime - StartTime);

  WriteLn('读锁性能: ', FReadCount, ' ops, ', EndTime - StartTime, 'ms, ', Round(OpsPerSec), ' ops/sec');

  AssertEquals(READER_COUNT * 5000, FReadCount);
  AssertTrue(OpsPerSec > 1000); // 至少 1000 ops/sec
end;

procedure TTestCase_Full.Test_13_WritePerformance;
const
  WRITER_COUNT = 2;
var
  Threads: array[0..WRITER_COUNT-1] of TThreadID;
  i: Integer;
  StartTime, EndTime: QWord;
  OpsPerSec: Double;
begin
  WriteLn('测试: 写锁性能');

  StartTime := GetTickCount64;

  // 启动写者线程
  for i := 0 to WRITER_COUNT-1 do
    Threads[i] := BeginThread(@PerfWriterProc, Self);

  // 等待完成
  for i := 0 to WRITER_COUNT-1 do
    WaitForThreadTerminate(Threads[i], 10000);

  EndTime := GetTickCount64;
  if EndTime = StartTime then Inc(EndTime);
  OpsPerSec := FWriteCount * 1000.0 / (EndTime - StartTime);

  WriteLn('写锁性能: ', FWriteCount, ' ops, ', EndTime - StartTime, 'ms, ', Round(OpsPerSec), ' ops/sec');

  AssertEquals(WRITER_COUNT * 2000, FWriteCount);
  AssertTrue(OpsPerSec > 500); // 至少 500 ops/sec
end;

procedure TTestCase_Full.Test_14_MixedPerformance;
const
  READER_COUNT = 3;
  WRITER_COUNT = 1;
var
  ReaderThreads: array[0..READER_COUNT-1] of TThreadID;
  WriterThreads: array[0..WRITER_COUNT-1] of TThreadID;
  i: Integer;
  StartTime, EndTime: QWord;
  TotalOps: Integer;
  OpsPerSec: Double;
  ReadWriteRatio: Double;
begin
  WriteLn('测试: 混合读写性能');

  StartTime := GetTickCount64;

  // 启动所有线程
  for i := 0 to READER_COUNT-1 do
    ReaderThreads[i] := BeginThread(@PerfReaderProc, Self);

  for i := 0 to WRITER_COUNT-1 do
    WriterThreads[i] := BeginThread(@PerfWriterProc, Self);

  // 等待完成
  for i := 0 to READER_COUNT-1 do
    WaitForThreadTerminate(ReaderThreads[i], 10000);

  for i := 0 to WRITER_COUNT-1 do
    WaitForThreadTerminate(WriterThreads[i], 10000);

  EndTime := GetTickCount64;
  TotalOps := FReadCount + FWriteCount;
  OpsPerSec := TotalOps * 1000.0 / (EndTime - StartTime);
  if FWriteCount > 0 then
    ReadWriteRatio := FReadCount / FWriteCount
  else
    ReadWriteRatio := FReadCount;

  WriteLn('混合性能: 读=', FReadCount, ', 写=', FWriteCount, ', 比例=', ReadWriteRatio:0:1, ':1');
  WriteLn('总性能: ', TotalOps, ' ops, ', EndTime - StartTime, 'ms, ', Round(OpsPerSec), ' ops/sec');

  AssertEquals(READER_COUNT * 5000, FReadCount);
  AssertEquals(WRITER_COUNT * 2000, FWriteCount);
  AssertTrue(OpsPerSec > 1500); // 混合场景至少 1500 ops/sec
  AssertTrue(ReadWriteRatio > 2.0); // 读多写少
end;

procedure TTestCase_Full.Test_15_PerformanceStatistics;
var
  InitialContention, InitialSpin: Integer;
  FinalContention, FinalSpin: Integer;
  i: Integer;
begin
  WriteLn('测试: 性能统计和自适应优化');

  // 获取初始统计
  InitialContention := FRWLock.GetContentionCount;
  InitialSpin := FRWLock.GetSpinCount;

  WriteLn('初始状态:');
  WriteLn('  竞争计数: ', InitialContention);
  WriteLn('  自旋次数: ', InitialSpin);

  // 执行一些操作来触发统计
  for i := 1 to 1000 do
  begin
    FRWLock.AcquireRead;
    try
      // 简单操作
    finally
      FRWLock.ReleaseRead;
    end;
  end;

  // 获取最终统计
  FinalContention := FRWLock.GetContentionCount;
  FinalSpin := FRWLock.GetSpinCount;

  WriteLn('最终状态:');
  WriteLn('  竞争计数: ', FinalContention);
  WriteLn('  自旋次数: ', FinalSpin);
  WriteLn('  竞争变化: ', FinalContention - InitialContention);

  // 验证统计功能正常
  AssertTrue(FinalContention >= InitialContention);
  AssertTrue(FinalSpin > 0);
end;

initialization
  RegisterTest(TTestCase_Full);

end.
