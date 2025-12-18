unit fafafa.core.sync.rwlock.testcase.concurrent;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.math,
  fafafa.core.sync.rwlock, fafafa.core.sync.base;

type
  // 并发测试用例
  TTestCase_Concurrent = class(TTestCase)
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
        TestCase: TTestCase_Concurrent;
        ThreadId: Integer;
        OperationCount: Integer;
        Success: Boolean;
      end;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基础并发测试
    procedure Test_MultipleReaders;
    procedure Test_ReaderWriterExclusion;
    procedure Test_WriterExclusion;
    procedure Test_ReadWriteStress;
    
    // RAII 守卫并发测试
    procedure Test_GuardConcurrency;
    procedure Test_GuardTimeout;
    
    // 性能测试
    procedure Test_ReadPerformance;
    procedure Test_WritePerformance;
    procedure Test_MixedPerformance;
  end;

implementation

{ TTestCase_Concurrent }

procedure TTestCase_Concurrent.SetUp;
begin
  inherited SetUp;
  FRWLock := CreateRWLock;
  FSharedValue := 0;
  FReadCount := 0;
  FWriteCount := 0;
  FErrorCount := 0;
  FTestCompleted := False;
end;

procedure TTestCase_Concurrent.TearDown;
begin
  FTestCompleted := True;
  Sleep(50); // 等待线程结束
  FRWLock := nil;
  inherited TearDown;
end;

// 读者线程函数
function ReaderThreadProc(Data: Pointer): PtrInt;
var
  ThreadData: PThreadData;
  i: Integer;
  LocalValue: Integer;
begin
  ThreadData := PThreadData(Data);
  Result := 0;
  
  try
    for i := 1 to ThreadData^.OperationCount do
    begin
      if ThreadData^.TestCase.FTestCompleted then Break;
      
      ThreadData^.TestCase.FRWLock.AcquireRead;
      try
        LocalValue := ThreadData^.TestCase.FSharedValue;
        InterlockedIncrement(ThreadData^.TestCase.FReadCount);
        
        // 模拟读操作
        Sleep(Random(5) + 1);
        
        // 验证值没有被意外修改
        if LocalValue <> ThreadData^.TestCase.FSharedValue then
          InterlockedIncrement(ThreadData^.TestCase.FErrorCount);
          
      finally
        ThreadData^.TestCase.FRWLock.ReleaseRead;
      end;
      
      // 短暂休眠
      if Random(10) = 0 then Sleep(1);
    end;
    
    ThreadData^.Success := True;
  except
    on E: Exception do
    begin
      WriteLn('Reader thread ', ThreadData^.ThreadId, ' error: ', E.Message);
      InterlockedIncrement(ThreadData^.TestCase.FErrorCount);
    end;
  end;
end;

// 写者线程函数
function WriterThreadProc(Data: Pointer): PtrInt;
var
  ThreadData: PThreadData;
  i: Integer;
  NewValue: Integer;
begin
  ThreadData := PThreadData(Data);
  Result := 0;
  
  try
    for i := 1 to ThreadData^.OperationCount do
    begin
      if ThreadData^.TestCase.FTestCompleted then Break;
      
      ThreadData^.TestCase.FRWLock.AcquireWrite;
      try
        NewValue := ThreadData^.TestCase.FSharedValue + 1;
        
        // 模拟写操作
        Sleep(Random(3) + 1);
        
        ThreadData^.TestCase.FSharedValue := NewValue;
        InterlockedIncrement(ThreadData^.TestCase.FWriteCount);
        
      finally
        ThreadData^.TestCase.FRWLock.ReleaseWrite;
      end;
      
      // 短暂休眠
      if Random(20) = 0 then Sleep(1);
    end;
    
    ThreadData^.Success := True;
  except
    on E: Exception do
    begin
      WriteLn('Writer thread ', ThreadData^.ThreadId, ' error: ', E.Message);
      InterlockedIncrement(ThreadData^.TestCase.FErrorCount);
    end;
  end;
end;

procedure TTestCase_Concurrent.Test_MultipleReaders;
const
  READER_COUNT = 5;
  OPERATIONS_PER_READER = 50;
var
  Threads: array[0..READER_COUNT-1] of TThreadID;
  ThreadData: array[0..READER_COUNT-1] of TThreadData;
  i: Integer;
  StartTime: QWord;
begin
  WriteLn('测试: 多读者并发访问');
  
  // 初始化线程数据
  for i := 0 to READER_COUNT-1 do
  begin
    ThreadData[i].TestCase := Self;
    ThreadData[i].ThreadId := i;
    ThreadData[i].OperationCount := OPERATIONS_PER_READER;
    ThreadData[i].Success := False;
  end;
  
  StartTime := GetTickCount64;
  
  // 启动读者线程
  for i := 0 to READER_COUNT-1 do
    Threads[i] := BeginThread(@ReaderThreadProc, @ThreadData[i]);
  
  // 等待所有线程完成
  for i := 0 to READER_COUNT-1 do
    WaitForThreadTerminate(Threads[i], 10000);
  
  WriteLn('耗时: ', GetTickCount64 - StartTime, 'ms');
  WriteLn('读操作总数: ', FReadCount);
  WriteLn('错误数: ', FErrorCount);
  
  // 验证结果
  AssertEquals(0, FErrorCount);
  AssertEquals(READER_COUNT * OPERATIONS_PER_READER, FReadCount);
  
  for i := 0 to READER_COUNT-1 do
    AssertTrue(ThreadData[i].Success);
end;

procedure TTestCase_Concurrent.Test_ReaderWriterExclusion;
const
  READER_COUNT = 3;
  WRITER_COUNT = 2;
  OPERATIONS_PER_THREAD = 30;
var
  ReaderThreads: array[0..READER_COUNT-1] of TThreadID;
  WriterThreads: array[0..WRITER_COUNT-1] of TThreadID;
  ReaderData: array[0..READER_COUNT-1] of TThreadData;
  WriterData: array[0..WRITER_COUNT-1] of TThreadData;
  i: Integer;
  StartTime: QWord;
  InitialValue: Integer;
begin
  WriteLn('测试: 读写互斥');
  
  InitialValue := FSharedValue;
  
  // 初始化线程数据
  for i := 0 to READER_COUNT-1 do
  begin
    ReaderData[i].TestCase := Self;
    ReaderData[i].ThreadId := i;
    ReaderData[i].OperationCount := OPERATIONS_PER_THREAD;
    ReaderData[i].Success := False;
  end;
  
  for i := 0 to WRITER_COUNT-1 do
  begin
    WriterData[i].TestCase := Self;
    WriterData[i].ThreadId := i + READER_COUNT;
    WriterData[i].OperationCount := OPERATIONS_PER_THREAD;
    WriterData[i].Success := False;
  end;
  
  StartTime := GetTickCount64;
  
  // 启动读者和写者线程
  for i := 0 to READER_COUNT-1 do
    ReaderThreads[i] := BeginThread(@ReaderThreadProc, @ReaderData[i]);
    
  for i := 0 to WRITER_COUNT-1 do
    WriterThreads[i] := BeginThread(@WriterThreadProc, @WriterData[i]);
  
  // 等待所有线程完成
  for i := 0 to READER_COUNT-1 do
    WaitForThreadTerminate(ReaderThreads[i], 15000);
    
  for i := 0 to WRITER_COUNT-1 do
    WaitForThreadTerminate(WriterThreads[i], 15000);
  
  WriteLn('耗时: ', GetTickCount64 - StartTime, 'ms');
  WriteLn('读操作总数: ', FReadCount);
  WriteLn('写操作总数: ', FWriteCount);
  WriteLn('共享值变化: ', InitialValue, ' -> ', FSharedValue);
  WriteLn('错误数: ', FErrorCount);
  
  // 验证结果
  AssertEquals(0, FErrorCount);
  AssertEquals(READER_COUNT * OPERATIONS_PER_THREAD, FReadCount);
  AssertEquals(WRITER_COUNT * OPERATIONS_PER_THREAD, FWriteCount);
  AssertEquals(InitialValue + FWriteCount, FSharedValue);
  
  for i := 0 to READER_COUNT-1 do
    AssertTrue(ReaderData[i].Success);
    
  for i := 0 to WRITER_COUNT-1 do
    AssertTrue(WriterData[i].Success);
end;

procedure TTestCase_Concurrent.Test_WriterExclusion;
const
  WRITER_COUNT = 4;
  OPERATIONS_PER_WRITER = 25;
var
  Threads: array[0..WRITER_COUNT-1] of TThreadID;
  ThreadData: array[0..WRITER_COUNT-1] of TThreadData;
  i: Integer;
  StartTime: QWord;
  InitialValue: Integer;
begin
  WriteLn('测试: 写者互斥');
  
  InitialValue := FSharedValue;
  
  // 初始化线程数据
  for i := 0 to WRITER_COUNT-1 do
  begin
    ThreadData[i].TestCase := Self;
    ThreadData[i].ThreadId := i;
    ThreadData[i].OperationCount := OPERATIONS_PER_WRITER;
    ThreadData[i].Success := False;
  end;
  
  StartTime := GetTickCount64;
  
  // 启动写者线程
  for i := 0 to WRITER_COUNT-1 do
    Threads[i] := BeginThread(@WriterThreadProc, @ThreadData[i]);
  
  // 等待所有线程完成
  for i := 0 to WRITER_COUNT-1 do
    WaitForThreadTerminate(Threads[i], 10000);
  
  WriteLn('耗时: ', GetTickCount64 - StartTime, 'ms');
  WriteLn('写操作总数: ', FWriteCount);
  WriteLn('共享值变化: ', InitialValue, ' -> ', FSharedValue);
  WriteLn('错误数: ', FErrorCount);
  
  // 验证结果
  AssertEquals(0, FErrorCount);
  AssertEquals(WRITER_COUNT * OPERATIONS_PER_WRITER, FWriteCount);
  AssertEquals(InitialValue + FWriteCount, FSharedValue);
  
  for i := 0 to WRITER_COUNT-1 do
    AssertTrue(ThreadData[i].Success);
end;

procedure TTestCase_Concurrent.Test_ReadWriteStress;
const
  READER_COUNT = 8;
  WRITER_COUNT = 2;
  OPERATIONS_PER_THREAD = 100;
var
  ReaderThreads: array[0..READER_COUNT-1] of TThreadID;
  WriterThreads: array[0..WRITER_COUNT-1] of TThreadID;
  ReaderData: array[0..READER_COUNT-1] of TThreadData;
  WriterData: array[0..WRITER_COUNT-1] of TThreadData;
  i: Integer;
  StartTime: QWord;
begin
  WriteLn('测试: 读写压力测试');

  // 初始化线程数据
  for i := 0 to READER_COUNT-1 do
  begin
    ReaderData[i].TestCase := Self;
    ReaderData[i].ThreadId := i;
    ReaderData[i].OperationCount := OPERATIONS_PER_THREAD;
    ReaderData[i].Success := False;
  end;

  for i := 0 to WRITER_COUNT-1 do
  begin
    WriterData[i].TestCase := Self;
    WriterData[i].ThreadId := i + READER_COUNT;
    WriterData[i].OperationCount := OPERATIONS_PER_THREAD div 4; // 写操作较少
    WriterData[i].Success := False;
  end;

  StartTime := GetTickCount64;

  // 启动所有线程
  for i := 0 to READER_COUNT-1 do
    ReaderThreads[i] := BeginThread(@ReaderThreadProc, @ReaderData[i]);

  for i := 0 to WRITER_COUNT-1 do
    WriterThreads[i] := BeginThread(@WriterThreadProc, @WriterData[i]);

  // 等待所有线程完成
  for i := 0 to READER_COUNT-1 do
    WaitForThreadTerminate(ReaderThreads[i], 20000);

  for i := 0 to WRITER_COUNT-1 do
    WaitForThreadTerminate(WriterThreads[i], 20000);

  WriteLn('耗时: ', GetTickCount64 - StartTime, 'ms');
  WriteLn('读操作总数: ', FReadCount);
  WriteLn('写操作总数: ', FWriteCount);
  WriteLn('读写比例: ', FReadCount div Max(1, FWriteCount), ':1');
  WriteLn('错误数: ', FErrorCount);

  // 验证结果
  AssertEquals(0, FErrorCount);
  AssertTrue(FReadCount > 0);
  AssertTrue(FWriteCount > 0);
end;

// RAII 守卫线程函数
function GuardReaderThreadProc(Data: Pointer): PtrInt;
var
  ThreadData: PThreadData;
  i: Integer;
  Guard: IRWLockReadGuard;
begin
  ThreadData := PThreadData(Data);
  Result := 0;

  try
    for i := 1 to ThreadData^.OperationCount do
    begin
      if ThreadData^.TestCase.FTestCompleted then Break;

      Guard := ThreadData^.TestCase.FRWLock.Read;
      if Assigned(Guard) then
      begin
        InterlockedIncrement(ThreadData^.TestCase.FReadCount);
        Sleep(Random(3) + 1);
      end;
      Guard := nil; // 显式释放

      if Random(10) = 0 then Sleep(1);
    end;

    ThreadData^.Success := True;
  except
    on E: Exception do
    begin
      WriteLn('Guard reader thread ', ThreadData^.ThreadId, ' error: ', E.Message);
      InterlockedIncrement(ThreadData^.TestCase.FErrorCount);
    end;
  end;
end;

function GuardWriterThreadProc(Data: Pointer): PtrInt;
var
  ThreadData: PThreadData;
  i: Integer;
  Guard: IRWLockWriteGuard;
begin
  ThreadData := PThreadData(Data);
  Result := 0;

  try
    for i := 1 to ThreadData^.OperationCount do
    begin
      if ThreadData^.TestCase.FTestCompleted then Break;

      Guard := ThreadData^.TestCase.FRWLock.Write;
      if Assigned(Guard) then
      begin
        Inc(ThreadData^.TestCase.FSharedValue);
        InterlockedIncrement(ThreadData^.TestCase.FWriteCount);
        Sleep(Random(2) + 1);
      end;
      Guard := nil; // 显式释放

      if Random(20) = 0 then Sleep(1);
    end;

    ThreadData^.Success := True;
  except
    on E: Exception do
    begin
      WriteLn('Guard writer thread ', ThreadData^.ThreadId, ' error: ', E.Message);
      InterlockedIncrement(ThreadData^.TestCase.FErrorCount);
    end;
  end;
end;

procedure TTestCase_Concurrent.Test_GuardConcurrency;
const
  READER_COUNT = 4;
  WRITER_COUNT = 2;
  OPERATIONS_PER_THREAD = 50;
var
  ReaderThreads: array[0..READER_COUNT-1] of TThreadID;
  WriterThreads: array[0..WRITER_COUNT-1] of TThreadID;
  ReaderData: array[0..READER_COUNT-1] of TThreadData;
  WriterData: array[0..WRITER_COUNT-1] of TThreadData;
  i: Integer;
  StartTime: QWord;
begin
  WriteLn('测试: RAII 守卫并发');

  // 初始化线程数据
  for i := 0 to READER_COUNT-1 do
  begin
    ReaderData[i].TestCase := Self;
    ReaderData[i].ThreadId := i;
    ReaderData[i].OperationCount := OPERATIONS_PER_THREAD;
    ReaderData[i].Success := False;
  end;

  for i := 0 to WRITER_COUNT-1 do
  begin
    WriterData[i].TestCase := Self;
    WriterData[i].ThreadId := i + READER_COUNT;
    WriterData[i].OperationCount := OPERATIONS_PER_THREAD div 2;
    WriterData[i].Success := False;
  end;

  StartTime := GetTickCount64;

  // 启动守卫线程
  for i := 0 to READER_COUNT-1 do
    ReaderThreads[i] := BeginThread(@GuardReaderThreadProc, @ReaderData[i]);

  for i := 0 to WRITER_COUNT-1 do
    WriterThreads[i] := BeginThread(@GuardWriterThreadProc, @WriterData[i]);

  // 等待所有线程完成
  for i := 0 to READER_COUNT-1 do
    WaitForThreadTerminate(ReaderThreads[i], 15000);

  for i := 0 to WRITER_COUNT-1 do
    WaitForThreadTerminate(WriterThreads[i], 15000);

  WriteLn('耗时: ', GetTickCount64 - StartTime, 'ms');
  WriteLn('读操作总数: ', FReadCount);
  WriteLn('写操作总数: ', FWriteCount);
  WriteLn('错误数: ', FErrorCount);

  // 验证结果
  AssertEquals(0, FErrorCount);
  AssertTrue(FReadCount > 0);
  AssertTrue(FWriteCount > 0);

  for i := 0 to READER_COUNT-1 do
    AssertTrue(ReaderData[i].Success);

  for i := 0 to WRITER_COUNT-1 do
    AssertTrue(WriterData[i].Success);
end;

procedure TTestCase_Concurrent.Test_GuardTimeout;
var
  Guard1, Guard2: IRWLockWriteGuard;
  TimeoutGuard: IRWLockWriteGuard;
  StartTime: QWord;
begin
  WriteLn('测试: 守卫超时');

  // 获取第一个写锁
  Guard1 := FRWLock.Write;
  AssertNotNull(Guard1);
  AssertTrue(FRWLock.IsWriteLocked);

  StartTime := GetTickCount64;

  // 尝试获取第二个写锁（应该超时）
  TimeoutGuard := FRWLock.TryWrite(100);

  WriteLn('超时测试耗时: ', GetTickCount64 - StartTime, 'ms');

  // 应该获取失败
  AssertNull(TimeoutGuard);
  AssertTrue(FRWLock.IsWriteLocked);

  // 释放第一个锁
  Guard1 := nil;
  AssertFalse(FRWLock.IsWriteLocked);

  // 现在应该能获取锁
  Guard2 := FRWLock.TryWrite(100);
  AssertNotNull(Guard2);
  AssertTrue(FRWLock.IsWriteLocked);

  Guard2 := nil;
  AssertFalse(FRWLock.IsWriteLocked);
end;

// 性能测试线程函数
function PerfReaderThreadProc(Data: Pointer): PtrInt;
var
  ThreadData: PThreadData;
  i: Integer;
begin
  ThreadData := PThreadData(Data);
  Result := 0;

  for i := 1 to ThreadData^.OperationCount do
  begin
    if ThreadData^.TestCase.FTestCompleted then Break;

    ThreadData^.TestCase.FRWLock.AcquireRead;
    try
      // 最小化操作，专注性能测试
      InterlockedIncrement(ThreadData^.TestCase.FReadCount);
    finally
      ThreadData^.TestCase.FRWLock.ReleaseRead;
    end;
  end;

  ThreadData^.Success := True;
end;

function PerfWriterThreadProc(Data: Pointer): PtrInt;
var
  ThreadData: PThreadData;
  i: Integer;
begin
  ThreadData := PThreadData(Data);
  Result := 0;

  for i := 1 to ThreadData^.OperationCount do
  begin
    if ThreadData^.TestCase.FTestCompleted then Break;

    ThreadData^.TestCase.FRWLock.AcquireWrite;
    try
      // 最小化操作，专注性能测试
      InterlockedIncrement(ThreadData^.TestCase.FWriteCount);
    finally
      ThreadData^.TestCase.FRWLock.ReleaseWrite;
    end;
  end;

  ThreadData^.Success := True;
end;

procedure TTestCase_Concurrent.Test_ReadPerformance;
const
  READER_COUNT = 8;
  OPERATIONS_PER_READER = 10000;
var
  Threads: array[0..READER_COUNT-1] of TThreadID;
  ThreadData: array[0..READER_COUNT-1] of TThreadData;
  i: Integer;
  StartTime, EndTime: QWord;
  TotalOps: Integer;
  OpsPerSec: Double;
begin
  WriteLn('测试: 读锁性能');

  // 初始化线程数据
  for i := 0 to READER_COUNT-1 do
  begin
    ThreadData[i].TestCase := Self;
    ThreadData[i].ThreadId := i;
    ThreadData[i].OperationCount := OPERATIONS_PER_READER;
    ThreadData[i].Success := False;
  end;

  StartTime := GetTickCount64;

  // 启动读者线程
  for i := 0 to READER_COUNT-1 do
    Threads[i] := BeginThread(@PerfReaderThreadProc, @ThreadData[i]);

  // 等待所有线程完成
  for i := 0 to READER_COUNT-1 do
    WaitForThreadTerminate(Threads[i], 30000);

  EndTime := GetTickCount64;
  TotalOps := FReadCount;
  OpsPerSec := TotalOps * 1000.0 / (EndTime - StartTime);

  WriteLn('读锁性能测试结果:');
  WriteLn('  总操作数: ', TotalOps);
  WriteLn('  耗时: ', EndTime - StartTime, 'ms');
  WriteLn('  吞吐量: ', Round(OpsPerSec), ' ops/sec');
  WriteLn('  平均延迟: ', (EndTime - StartTime) * 1000.0 / TotalOps:0:3, ' μs/op');

  // 验证结果
  AssertEquals(READER_COUNT * OPERATIONS_PER_READER, TotalOps);
  AssertTrue(OpsPerSec > 1000); // 至少 1000 ops/sec

  for i := 0 to READER_COUNT-1 do
    AssertTrue(ThreadData[i].Success);
end;

procedure TTestCase_Concurrent.Test_WritePerformance;
const
  WRITER_COUNT = 4;
  OPERATIONS_PER_WRITER = 5000;
var
  Threads: array[0..WRITER_COUNT-1] of TThreadID;
  ThreadData: array[0..WRITER_COUNT-1] of TThreadData;
  i: Integer;
  StartTime, EndTime: QWord;
  TotalOps: Integer;
  OpsPerSec: Double;
begin
  WriteLn('测试: 写锁性能');

  // 初始化线程数据
  for i := 0 to WRITER_COUNT-1 do
  begin
    ThreadData[i].TestCase := Self;
    ThreadData[i].ThreadId := i;
    ThreadData[i].OperationCount := OPERATIONS_PER_WRITER;
    ThreadData[i].Success := False;
  end;

  StartTime := GetTickCount64;

  // 启动写者线程
  for i := 0 to WRITER_COUNT-1 do
    Threads[i] := BeginThread(@PerfWriterThreadProc, @ThreadData[i]);

  // 等待所有线程完成
  for i := 0 to WRITER_COUNT-1 do
    WaitForThreadTerminate(Threads[i], 30000);

  EndTime := GetTickCount64;
  TotalOps := FWriteCount;
  OpsPerSec := TotalOps * 1000.0 / (EndTime - StartTime);

  WriteLn('写锁性能测试结果:');
  WriteLn('  总操作数: ', TotalOps);
  WriteLn('  耗时: ', EndTime - StartTime, 'ms');
  WriteLn('  吞吐量: ', Round(OpsPerSec), ' ops/sec');
  WriteLn('  平均延迟: ', (EndTime - StartTime) * 1000.0 / TotalOps:0:3, ' μs/op');

  // 验证结果
  AssertEquals(WRITER_COUNT * OPERATIONS_PER_WRITER, TotalOps);
  AssertTrue(OpsPerSec > 500); // 至少 500 ops/sec

  for i := 0 to WRITER_COUNT-1 do
    AssertTrue(ThreadData[i].Success);
end;

procedure TTestCase_Concurrent.Test_MixedPerformance;
const
  READER_COUNT = 6;
  WRITER_COUNT = 2;
  OPERATIONS_PER_READER = 8000;
  OPERATIONS_PER_WRITER = 2000;
var
  ReaderThreads: array[0..READER_COUNT-1] of TThreadID;
  WriterThreads: array[0..WRITER_COUNT-1] of TThreadID;
  ReaderData: array[0..READER_COUNT-1] of TThreadData;
  WriterData: array[0..WRITER_COUNT-1] of TThreadData;
  i: Integer;
  StartTime, EndTime: QWord;
  TotalOps: Integer;
  OpsPerSec: Double;
  ReadWriteRatio: Double;
begin
  WriteLn('测试: 混合读写性能 (读多写少场景)');

  // 初始化线程数据
  for i := 0 to READER_COUNT-1 do
  begin
    ReaderData[i].TestCase := Self;
    ReaderData[i].ThreadId := i;
    ReaderData[i].OperationCount := OPERATIONS_PER_READER;
    ReaderData[i].Success := False;
  end;

  for i := 0 to WRITER_COUNT-1 do
  begin
    WriterData[i].TestCase := Self;
    WriterData[i].ThreadId := i + READER_COUNT;
    WriterData[i].OperationCount := OPERATIONS_PER_WRITER;
    WriterData[i].Success := False;
  end;

  StartTime := GetTickCount64;

  // 启动所有线程
  for i := 0 to READER_COUNT-1 do
    ReaderThreads[i] := BeginThread(@PerfReaderThreadProc, @ReaderData[i]);

  for i := 0 to WRITER_COUNT-1 do
    WriterThreads[i] := BeginThread(@PerfWriterThreadProc, @WriterData[i]);

  // 等待所有线程完成
  for i := 0 to READER_COUNT-1 do
    WaitForThreadTerminate(ReaderThreads[i], 30000);

  for i := 0 to WRITER_COUNT-1 do
    WaitForThreadTerminate(WriterThreads[i], 30000);

  EndTime := GetTickCount64;
  TotalOps := FReadCount + FWriteCount;
  OpsPerSec := TotalOps * 1000.0 / (EndTime - StartTime);
  ReadWriteRatio := FReadCount / Max(1, FWriteCount);

  WriteLn('混合性能测试结果:');
  WriteLn('  读操作数: ', FReadCount);
  WriteLn('  写操作数: ', FWriteCount);
  WriteLn('  总操作数: ', TotalOps);
  WriteLn('  读写比例: ', ReadWriteRatio:0:1, ':1');
  WriteLn('  耗时: ', EndTime - StartTime, 'ms');
  WriteLn('  总吞吐量: ', Round(OpsPerSec), ' ops/sec');
  WriteLn('  读吞吐量: ', Round(FReadCount * 1000.0 / (EndTime - StartTime)), ' ops/sec');
  WriteLn('  写吞吐量: ', Round(FWriteCount * 1000.0 / (EndTime - StartTime)), ' ops/sec');

  // 验证结果
  AssertEquals(READER_COUNT * OPERATIONS_PER_READER, FReadCount);
  AssertEquals(WRITER_COUNT * OPERATIONS_PER_WRITER, FWriteCount);
  AssertTrue(OpsPerSec > 2000); // 混合场景至少 2000 ops/sec
  AssertTrue(ReadWriteRatio > 2.0); // 读多写少

  for i := 0 to READER_COUNT-1 do
    AssertTrue(ReaderData[i].Success);

  for i := 0 to WRITER_COUNT-1 do
    AssertTrue(WriterData[i].Success);
end;

initialization
  RegisterTest(TTestCase_Concurrent);

end.
