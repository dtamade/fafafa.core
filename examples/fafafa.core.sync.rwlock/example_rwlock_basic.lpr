program example_rwlock_basic;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.rwlock;

var
  RWLock: IRWLock;
  SharedData: Integer = 0;
  ReadCount: Integer = 0;

function ReaderThreadProc(Data: Pointer): PtrInt;
var
  i: Integer;
  LocalValue: Integer;
  ThreadNum: Integer;
begin
  ThreadNum := PtrUInt(Data);
  
  for i := 1 to 5 do
  begin
    // 获取读锁
    RWLock.AcquireRead;
    try
      LocalValue := SharedData;
      InterlockedIncrement(ReadCount);
      WriteLn('读者线程 ', ThreadNum, ' 读取到值: ', LocalValue, 
              ' (当前读者数: ', RWLock.GetReaderCount, ')');
      
      // 模拟读操作耗时
      Sleep(Random(50) + 10);
    finally
      RWLock.ReleaseRead;
      InterlockedDecrement(ReadCount);
    end;
    
    Sleep(Random(20));
  end;
  
  Result := 0;
end;

function WriterThreadProc(Data: Pointer): PtrInt;
var
  i: Integer;
  ThreadNum: Integer;
begin
  ThreadNum := PtrUInt(Data);
  
  for i := 1 to 3 do
  begin
    // 尝试获取写锁（带超时）
    if RWLock.TryAcquireWrite(100) then
    begin
      try
        Inc(SharedData);
        WriteLn('写者线程 ', ThreadNum, ' 将值更新为: ', SharedData,
                ' (写者线程ID: ', RWLock.GetWriterThread, ')');
        
        // 模拟写操作耗时
        Sleep(Random(30) + 20);
      finally
        RWLock.ReleaseWrite;
      end;
    end
    else
    begin
      WriteLn('写者线程 ', ThreadNum, ' 获取写锁超时，跳过本次写入');
    end;
    
    Sleep(Random(50));
  end;
  
  Result := 0;
end;

var
  ReaderThreads: array[1..3] of TThreadID;
  WriterThreads: array[1..2] of TThreadID;
  i: Integer;

begin
  WriteLn('=== fafafa.core.sync.rwlock 基础示例 ===');
  WriteLn;
  
  // 创建读写锁
  RWLock := CreateReadWriteLock;
  
  WriteLn('初始状态:');
  WriteLn('  共享数据: ', SharedData);
  WriteLn('  读者数量: ', RWLock.GetReaderCount);
  WriteLn('  是否有写锁: ', RWLock.IsWriteLocked);
  WriteLn('  是否有读锁: ', RWLock.IsReadLocked);
  WriteLn('  最大读者数: ', RWLock.GetMaxReaders);
  WriteLn;
  
  // 启动读者线程
  WriteLn('启动 3 个读者线程...');
  for i := 1 to 3 do
    ReaderThreads[i] := BeginThread(@ReaderThreadProc, Pointer(i));
  
  // 启动写者线程
  WriteLn('启动 2 个写者线程...');
  for i := 1 to 2 do
    WriterThreads[i] := BeginThread(@WriterThreadProc, Pointer(i));
  
  WriteLn;
  WriteLn('线程运行中，观察读写锁的行为...');
  WriteLn;
  
  // 等待所有线程完成
  for i := 1 to 3 do
    WaitForThreadTerminate(ReaderThreads[i], 10000);
  for i := 1 to 2 do
    WaitForThreadTerminate(WriterThreads[i], 10000);
  
  WriteLn;
  WriteLn('所有线程完成');
  WriteLn('最终状态:');
  WriteLn('  共享数据: ', SharedData);
  WriteLn('  读者数量: ', RWLock.GetReaderCount);
  WriteLn('  是否有写锁: ', RWLock.IsWriteLocked);
  WriteLn('  是否有读锁: ', RWLock.IsReadLocked);
  
  WriteLn;
  WriteLn('示例完成。按回车键退出...');
  ReadLn;
end.
