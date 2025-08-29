{$CODEPAGE UTF8}
program test_fairness;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.rwlock.base, fafafa.core.sync.rwlock;

type
  TTestThread = class(TThread)
  private
    FLock: IRWLock;
    FMyThreadId: Integer;
    FIsWriter: Boolean;
    FOperationCount: Integer;
    FStartTime: QWord;
    FEndTime: QWord;
  protected
    procedure Execute; override;
  public
    constructor Create(ALock: IRWLock; AThreadId: Integer; AIsWriter: Boolean);
    property OperationCount: Integer read FOperationCount;
    property StartTime: QWord read FStartTime;
    property EndTime: QWord read FEndTime;
  end;

constructor TTestThread.Create(ALock: IRWLock; AThreadId: Integer; AIsWriter: Boolean);
begin
  inherited Create(False);
  FLock := ALock;
  FMyThreadId := AThreadId;
  FIsWriter := AIsWriter;
  FOperationCount := 0;
  FStartTime := GetTickCount64;
end;

procedure TTestThread.Execute;
var
  i: Integer;
  ReadGuard: IRWLockReadGuard;
  WriteGuard: IRWLockWriteGuard;
begin
  FStartTime := GetTickCount64;
  
  for i := 1 to 1000 do
  begin
    if FIsWriter then
    begin
      WriteGuard := FLock.Write;
      if Assigned(WriteGuard) then
      begin
        Inc(FOperationCount);
        Sleep(1); // 模拟工作
      end;
    end
    else
    begin
      ReadGuard := FLock.Read;
      if Assigned(ReadGuard) then
      begin
        Inc(FOperationCount);
        Sleep(1); // 模拟工作
      end;
    end;
  end;
  
  FEndTime := GetTickCount64;
end;

procedure TestDefaultMode;
var
  Lock: IRWLock;
  Threads: array[0..7] of TTestThread;
  i: Integer;
  WriterCount, ReaderCount: Integer;
  TotalWriterOps, TotalReaderOps: Integer;
begin
  WriteLn('=== 测试默认模式（写者优先） ===');
  
  Lock := MakeRWLock; // 默认配置
  
  // 创建 6 个读者线程和 2 个写者线程
  for i := 0 to 5 do
    Threads[i] := TTestThread.Create(Lock, i, False); // 读者
  for i := 6 to 7 do
    Threads[i] := TTestThread.Create(Lock, i, True);  // 写者
  
  // 等待所有线程完成
  for i := 0 to 7 do
    Threads[i].WaitFor;
  
  // 统计结果
  TotalReaderOps := 0;
  TotalWriterOps := 0;
  ReaderCount := 0;
  WriterCount := 0;
  
  for i := 0 to 7 do
  begin
    if Threads[i].FIsWriter then
    begin
      Inc(WriterCount);
      Inc(TotalWriterOps, Threads[i].OperationCount);
      WriteLn(Format('写者线程 %d: %d 操作, 用时 %d ms', 
        [Threads[i].FMyThreadId, Threads[i].OperationCount,
         Threads[i].EndTime - Threads[i].StartTime]));
    end
    else
    begin
      Inc(ReaderCount);
      Inc(TotalReaderOps, Threads[i].OperationCount);
      WriteLn(Format('读者线程 %d: %d 操作, 用时 %d ms', 
        [Threads[i].FMyThreadId, Threads[i].OperationCount,
         Threads[i].EndTime - Threads[i].StartTime]));
    end;
  end;
  
  WriteLn(Format('总计: 读者 %d 操作, 写者 %d 操作', [TotalReaderOps, TotalWriterOps]));
  WriteLn(Format('平均: 读者 %.1f ops/线程, 写者 %.1f ops/线程', 
    [TotalReaderOps / ReaderCount, TotalWriterOps / WriterCount]));
  
  // 清理
  for i := 0 to 7 do
    Threads[i].Free;
  
  WriteLn;
end;

procedure TestFairMode;
var
  Lock: IRWLock;
  Options: TRWLockOptions;
  Threads: array[0..7] of TTestThread;
  i: Integer;
  WriterCount, ReaderCount: Integer;
  TotalWriterOps, TotalReaderOps: Integer;
begin
  WriteLn('=== 测试公平模式 ===');
  
  Options := FairRWLockOptions;
  Lock := MakeRWLock(Options);
  
  // 创建 6 个读者线程和 2 个写者线程
  for i := 0 to 5 do
    Threads[i] := TTestThread.Create(Lock, i, False); // 读者
  for i := 6 to 7 do
    Threads[i] := TTestThread.Create(Lock, i, True);  // 写者
  
  // 等待所有线程完成
  for i := 0 to 7 do
    Threads[i].WaitFor;
  
  // 统计结果
  TotalReaderOps := 0;
  TotalWriterOps := 0;
  ReaderCount := 0;
  WriterCount := 0;
  
  for i := 0 to 7 do
  begin
    if Threads[i].FIsWriter then
    begin
      Inc(WriterCount);
      Inc(TotalWriterOps, Threads[i].OperationCount);
      WriteLn(Format('写者线程 %d: %d 操作, 用时 %d ms', 
        [Threads[i].FMyThreadId, Threads[i].OperationCount,
         Threads[i].EndTime - Threads[i].StartTime]));
    end
    else
    begin
      Inc(ReaderCount);
      Inc(TotalReaderOps, Threads[i].OperationCount);
      WriteLn(Format('读者线程 %d: %d 操作, 用时 %d ms', 
        [Threads[i].FMyThreadId, Threads[i].OperationCount,
         Threads[i].EndTime - Threads[i].StartTime]));
    end;
  end;
  
  WriteLn(Format('总计: 读者 %d 操作, 写者 %d 操作', [TotalReaderOps, TotalWriterOps]));
  WriteLn(Format('平均: 读者 %.1f ops/线程, 写者 %.1f ops/线程', 
    [TotalReaderOps / ReaderCount, TotalWriterOps / WriterCount]));
  
  // 清理
  for i := 0 to 7 do
    Threads[i].Free;
  
  WriteLn;
end;

procedure TestWriterPriorityMode;
var
  Lock: IRWLock;
  Options: TRWLockOptions;
  Threads: array[0..7] of TTestThread;
  i: Integer;
  WriterCount, ReaderCount: Integer;
  TotalWriterOps, TotalReaderOps: Integer;
begin
  WriteLn('=== 测试写者优先模式 ===');
  
  Options := WriterPriorityRWLockOptions;
  Lock := MakeRWLock(Options);
  
  // 创建 6 个读者线程和 2 个写者线程
  for i := 0 to 5 do
    Threads[i] := TTestThread.Create(Lock, i, False); // 读者
  for i := 6 to 7 do
    Threads[i] := TTestThread.Create(Lock, i, True);  // 写者
  
  // 等待所有线程完成
  for i := 0 to 7 do
    Threads[i].WaitFor;
  
  // 统计结果
  TotalReaderOps := 0;
  TotalWriterOps := 0;
  ReaderCount := 0;
  WriterCount := 0;
  
  for i := 0 to 7 do
  begin
    if Threads[i].FIsWriter then
    begin
      Inc(WriterCount);
      Inc(TotalWriterOps, Threads[i].OperationCount);
      WriteLn(Format('写者线程 %d: %d 操作, 用时 %d ms', 
        [Threads[i].FMyThreadId, Threads[i].OperationCount,
         Threads[i].EndTime - Threads[i].StartTime]));
    end
    else
    begin
      Inc(ReaderCount);
      Inc(TotalReaderOps, Threads[i].OperationCount);
      WriteLn(Format('读者线程 %d: %d 操作, 用时 %d ms', 
        [Threads[i].FMyThreadId, Threads[i].OperationCount,
         Threads[i].EndTime - Threads[i].StartTime]));
    end;
  end;
  
  WriteLn(Format('总计: 读者 %d 操作, 写者 %d 操作', [TotalReaderOps, TotalWriterOps]));
  WriteLn(Format('平均: 读者 %.1f ops/线程, 写者 %.1f ops/线程', 
    [TotalReaderOps / ReaderCount, TotalWriterOps / WriterCount]));
  
  // 清理
  for i := 0 to 7 do
    Threads[i].Free;
  
  WriteLn;
end;

begin
  WriteLn('fafafa.core.sync.rwlock 公平性测试');
  WriteLn('=====================================');
  WriteLn;
  
  TestDefaultMode;
  TestFairMode;
  TestWriterPriorityMode;
  
  WriteLn('测试完成');
end.
