program example_rwlock_performance;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.rwlock, fafafa.core.sync.base;

type
  TSharedCache = record
    Data: array[0..99] of Integer;
    Version: Integer;
  end;

var
  RWLock: IRWLock;
  Cache: TSharedCache;
  ReadOperations: Integer = 0;
  WriteOperations: Integer = 0;
  StartTime: QWord;

function CacheReaderProc(Data: Pointer): PtrInt;
var
  i, j: Integer;
  LocalSum: Integer;
  ThreadNum: Integer;
begin
  ThreadNum := PtrUInt(Data);
  
  for i := 1 to 1000 do
  begin
    RWLock.AcquireRead;
    try
      // 模拟复杂的读操作
      LocalSum := 0;
      for j := 0 to 99 do
        LocalSum += Cache.Data[j];
      
      InterlockedIncrement(ReadOperations);
      
      // 偶尔输出进度
      if (i mod 200) = 0 then
        WriteLn('读者 ', ThreadNum, ' 完成 ', i, ' 次读操作，当前版本: ', Cache.Version);
    finally
      RWLock.ReleaseRead;
    end;
    
    // 短暂休眠，模拟处理时间
    if Random(100) < 5 then  // 5% 概率休眠
      Sleep(1);
  end;
  
  Result := 0;
end;

function CacheWriterProc(Data: Pointer): PtrInt;
var
  i, j: Integer;
  ThreadNum: Integer;
begin
  ThreadNum := PtrUInt(Data);
  
  for i := 1 to 50 do
  begin
    if RWLock.TryAcquireWrite(10) then  // 10ms 超时
    begin
      try
        // 模拟缓存更新
        for j := 0 to 99 do
          Cache.Data[j] := Random(1000);
        Inc(Cache.Version);
        
        InterlockedIncrement(WriteOperations);
        
        WriteLn('写者 ', ThreadNum, ' 更新缓存到版本 ', Cache.Version);
        
        // 模拟写操作耗时
        Sleep(Random(5) + 1);
      finally
        RWLock.ReleaseWrite;
      end;
    end
    else
    begin
      // 写锁获取失败，跳过本次更新
      if (i mod 10) = 0 then
        WriteLn('写者 ', ThreadNum, ' 获取写锁失败，跳过更新 (', i, '/50)');
    end;
    
    // 写操作间隔
    Sleep(Random(20) + 10);
  end;
  
  Result := 0;
end;

procedure RunPerformanceTest;
const
  READER_COUNT = 8;
  WRITER_COUNT = 2;
var
  ReaderThreads: array[1..READER_COUNT] of TThreadID;
  WriterThreads: array[1..WRITER_COUNT] of TThreadID;
  i: Integer;
  Duration: QWord;
begin
  WriteLn('=== 读写锁性能测试 ===');
  WriteLn('配置: ', READER_COUNT, ' 个读者线程, ', WRITER_COUNT, ' 个写者线程');
  WriteLn('每个读者执行 1000 次读操作');
  WriteLn('每个写者执行 50 次写操作');
  WriteLn;
  
  // 初始化缓存
  for i := 0 to 99 do
    Cache.Data[i] := i;
  Cache.Version := 1;
  
  ReadOperations := 0;
  WriteOperations := 0;
  StartTime := GetTickCount64;
  
  // 启动读者线程
  WriteLn('启动读者线程...');
  for i := 1 to READER_COUNT do
    ReaderThreads[i] := BeginThread(@CacheReaderProc, Pointer(i));
  
  // 启动写者线程
  WriteLn('启动写者线程...');
  for i := 1 to WRITER_COUNT do
    WriterThreads[i] := BeginThread(@CacheWriterProc, Pointer(i));
  
  WriteLn('测试运行中...');
  WriteLn;
  
  // 等待所有线程完成
  for i := 1 to READER_COUNT do
    WaitForThreadTerminate(ReaderThreads[i], 30000);
  for i := 1 to WRITER_COUNT do
    WaitForThreadTerminate(WriterThreads[i], 30000);
  
  Duration := GetTickCount64 - StartTime;
  
  WriteLn;
  WriteLn('=== 性能测试结果 ===');
  WriteLn('总耗时: ', Duration, ' ms');
  WriteLn('读操作总数: ', ReadOperations);
  WriteLn('写操作总数: ', WriteOperations);
  WriteLn('最终缓存版本: ', Cache.Version);
  WriteLn;
  WriteLn('性能指标:');
  WriteLn('  读操作吞吐量: ', Round(ReadOperations * 1000.0 / Duration), ' ops/sec');
  WriteLn('  写操作吞吐量: ', Round(WriteOperations * 1000.0 / Duration), ' ops/sec');
  WriteLn('  总吞吐量: ', Round((ReadOperations + WriteOperations) * 1000.0 / Duration), ' ops/sec');
  WriteLn;
  
  // 计算读写比例
  if WriteOperations > 0 then
    WriteLn('读写比例: ', ReadOperations div WriteOperations, ':1')
  else
    WriteLn('读写比例: 只有读操作');
end;

procedure DemonstrateBasicFeatures;
begin
  WriteLn('=== 基础功能演示 ===');
  WriteLn;
  
  WriteLn('1. 创建读写锁');
  WriteLn('   最大读者数: ', RWLock.GetMaxReaders);
  WriteLn;
  
  WriteLn('2. 获取读锁');
  RWLock.AcquireRead;
  WriteLn('   当前读者数: ', RWLock.GetReaderCount);
  WriteLn('   是否有读锁: ', RWLock.IsReadLocked);
  WriteLn('   是否有写锁: ', RWLock.IsWriteLocked);
  
  WriteLn('3. 再次获取读锁（多读者并发）');
  RWLock.AcquireRead;
  WriteLn('   当前读者数: ', RWLock.GetReaderCount);
  
  WriteLn('4. 尝试获取写锁（应该失败，因为有读者）');
  if RWLock.TryAcquireWrite(10) then
  begin
    WriteLn('   意外：获取写锁成功！');
    RWLock.ReleaseWrite;
  end
  else
    WriteLn('   预期：获取写锁失败（有读者持有锁）');
  
  WriteLn('5. 释放读锁');
  RWLock.ReleaseRead;
  WriteLn('   当前读者数: ', RWLock.GetReaderCount);
  
  RWLock.ReleaseRead;
  WriteLn('   当前读者数: ', RWLock.GetReaderCount);
  WriteLn('   是否有读锁: ', RWLock.IsReadLocked);
  
  WriteLn('6. 获取写锁');
  RWLock.AcquireWrite;
  WriteLn('   是否有写锁: ', RWLock.IsWriteLocked);
  WriteLn('   写者线程ID: ', RWLock.GetWriterThread);
  
  WriteLn('7. 尝试获取读锁（应该失败，因为有写者）');
  if RWLock.TryAcquireRead(10) then
  begin
    WriteLn('   意外：获取读锁成功！');
    RWLock.ReleaseRead;
  end
  else
    WriteLn('   预期：获取读锁失败（有写者持有锁）');
  
  WriteLn('8. 释放写锁');
  RWLock.ReleaseWrite;
  WriteLn('   是否有写锁: ', RWLock.IsWriteLocked);
  WriteLn('   写者线程ID: ', RWLock.GetWriterThread);
  
  WriteLn;
end;

begin
  // 创建读写锁
  RWLock := CreateReadWriteLock;
  
  try
    // 演示基础功能
    DemonstrateBasicFeatures;
    
    // 运行性能测试
    RunPerformanceTest;
    
    WriteLn('示例完成。按回车键退出...');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      WriteLn('按回车键退出...');
      ReadLn;
    end;
  end;
end.
