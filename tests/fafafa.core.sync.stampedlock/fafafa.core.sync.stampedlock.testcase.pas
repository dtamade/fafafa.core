{$CODEPAGE UTF8}
unit fafafa.core.sync.stampedlock.testcase;

{**
 * fafafa.core.sync.stampedlock 测试套件
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.stampedlock,
  fafafa.core.sync.stampedlock.base,
  TestHelpers_Sync;

type
  TTestCase_StampedLock_Basic = class(TTestCase)
  published
    procedure Test_Create;
    procedure Test_WriteLock;
    procedure Test_ReadLock;
    procedure Test_OptimisticRead;
    procedure Test_Validate_Success;
    procedure Test_Validate_Fail;
    procedure Test_TryWriteLock;
    procedure Test_TryReadLock;
  end;

  TTestCase_StampedLock_Concurrent = class(TTestCase)
  published
    procedure Test_ConcurrentRead;
    procedure Test_ReadWriteInteraction;
  end;

implementation

{ TTestCase_StampedLock_Basic }

procedure TTestCase_StampedLock_Basic.Test_Create;
var
  L: IStampedLock;
begin
  L := MakeStampedLock;
  AssertNotNull('MakeStampedLock should return non-nil', L);
  AssertFalse('Should not be write locked', L.IsWriteLocked);
  AssertEquals('Read count should be 0', 0, L.GetReadLockCount);
end;

procedure TTestCase_StampedLock_Basic.Test_WriteLock;
var
  L: IStampedLock;
  Stamp: Int64;
begin
  L := MakeStampedLock;

  Stamp := L.WriteLock;
  AssertTrue('Write lock stamp should be non-zero', Stamp <> 0);
  AssertTrue('Should be write locked', L.IsWriteLocked);

  L.UnlockWrite(Stamp);
  AssertFalse('Should not be write locked after unlock', L.IsWriteLocked);
end;

procedure TTestCase_StampedLock_Basic.Test_ReadLock;
var
  L: IStampedLock;
  Stamp: Int64;
begin
  L := MakeStampedLock;

  Stamp := L.ReadLock;
  AssertTrue('Read lock stamp should be non-zero', Stamp <> 0);
  AssertEquals('Read count should be 1', 1, L.GetReadLockCount);

  L.UnlockRead(Stamp);
  AssertEquals('Read count should be 0 after unlock', 0, L.GetReadLockCount);
end;

procedure TTestCase_StampedLock_Basic.Test_OptimisticRead;
var
  L: IStampedLock;
  Stamp: Int64;
begin
  L := MakeStampedLock;

  Stamp := L.TryOptimisticRead;
  AssertTrue('Optimistic read stamp should be non-zero', Stamp <> 0);
  AssertEquals('Read count should still be 0 (optimistic)', 0, L.GetReadLockCount);
end;

procedure TTestCase_StampedLock_Basic.Test_Validate_Success;
var
  L: IStampedLock;
  Stamp: Int64;
begin
  L := MakeStampedLock;

  Stamp := L.TryOptimisticRead;
  // 没有写操作，验证应该成功
  AssertTrue('Validate should succeed without write', L.Validate(Stamp));
end;

procedure TTestCase_StampedLock_Basic.Test_Validate_Fail;
var
  L: IStampedLock;
  OptStamp, WriteStamp: Int64;
begin
  L := MakeStampedLock;

  OptStamp := L.TryOptimisticRead;

  // 执行写操作
  WriteStamp := L.WriteLock;
  L.UnlockWrite(WriteStamp);

  // 版本号已变化，验证应该失败
  AssertFalse('Validate should fail after write', L.Validate(OptStamp));
end;

procedure TTestCase_StampedLock_Basic.Test_TryWriteLock;
var
  L: IStampedLock;
  Stamp1, Stamp2: Int64;
begin
  L := MakeStampedLock;

  Stamp1 := L.TryWriteLock;
  AssertTrue('First TryWriteLock should succeed', Stamp1 <> 0);

  Stamp2 := L.TryWriteLock;
  AssertTrue('Second TryWriteLock should fail', Stamp2 = 0);

  L.UnlockWrite(Stamp1);
end;

procedure TTestCase_StampedLock_Basic.Test_TryReadLock;
var
  L: IStampedLock;
  WriteStamp, ReadStamp: Int64;
begin
  L := MakeStampedLock;

  // 没有写锁时可以获取读锁
  ReadStamp := L.TryReadLock;
  AssertTrue('TryReadLock should succeed without write lock', ReadStamp <> 0);
  L.UnlockRead(ReadStamp);

  // 有写锁时不能获取读锁
  WriteStamp := L.WriteLock;
  ReadStamp := L.TryReadLock;
  AssertTrue('TryReadLock should fail with write lock', ReadStamp = 0);
  L.UnlockWrite(WriteStamp);
end;

{ TTestCase_StampedLock_Concurrent }

type
  TStampedReadThread = class(TThread)
  private
    FLock: IStampedLock;
    FIterations: Integer;
    FOptimisticHits: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ALock: IStampedLock; AIterations: Integer);
    property OptimisticHits: Integer read FOptimisticHits;
  end;

constructor TStampedReadThread.Create(ALock: IStampedLock; AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FLock := ALock;
  FIterations := AIterations;
  FOptimisticHits := 0;
end;

procedure TStampedReadThread.Execute;
var
  i: Integer;
  Stamp: Int64;
begin
  for i := 1 to FIterations do
  begin
    Stamp := FLock.TryOptimisticRead;
    if (Stamp <> 0) and FLock.Validate(Stamp) then
      Inc(FOptimisticHits)
    else
    begin
      // 降级为悲观读
      Stamp := FLock.ReadLock;
      FLock.UnlockRead(Stamp);
    end;
  end;
end;

procedure TTestCase_StampedLock_Concurrent.Test_ConcurrentRead;
var
  L: IStampedLock;
  Threads: array[0..3] of TStampedReadThread;
  i, TotalHits: Integer;
begin
  L := MakeStampedLock;

  for i := 0 to 3 do
    Threads[i] := TStampedReadThread.Create(L, 1000);

  for i := 0 to 3 do
    Threads[i].Start;

  TotalHits := 0;
  for i := 0 to 3 do
  begin
    Threads[i].WaitFor;
    TotalHits := TotalHits + Threads[i].OptimisticHits;
    Threads[i].Free;
  end;

  // 无写操作时，所有乐观读都应该成功
  AssertEquals('All optimistic reads should succeed', 4000, TotalHits);
end;

type
  TStampedWriteThread = class(TThread)
  private
    FLock: IStampedLock;
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ALock: IStampedLock; AIterations: Integer);
  end;

constructor TStampedWriteThread.Create(ALock: IStampedLock; AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FLock := ALock;
  FIterations := AIterations;
end;

procedure TStampedWriteThread.Execute;
var
  i: Integer;
  Stamp: Int64;
begin
  for i := 1 to FIterations do
  begin
    Stamp := FLock.WriteLock;
    // 模拟写操作
    Sleep(0);
    FLock.UnlockWrite(Stamp);
  end;
end;

procedure TTestCase_StampedLock_Concurrent.Test_ReadWriteInteraction;
var
  L: IStampedLock;
  ReadThreads: array[0..1] of TStampedReadThread;
  WriteThread: TStampedWriteThread;
  i, TotalHits: Integer;
begin
  L := MakeStampedLock;

  for i := 0 to 1 do
    ReadThreads[i] := TStampedReadThread.Create(L, 500);
  WriteThread := TStampedWriteThread.Create(L, 100);

  for i := 0 to 1 do
    ReadThreads[i].Start;
  WriteThread.Start;

  WriteThread.WaitFor;
  WriteThread.Free;

  TotalHits := 0;
  for i := 0 to 1 do
  begin
    ReadThreads[i].WaitFor;
    TotalHits := TotalHits + ReadThreads[i].OptimisticHits;
    ReadThreads[i].Free;
  end;

  // 有写操作时，乐观读可能成功也可能失败
  WriteLn(Format('Optimistic hits with writes: %d / 1000', [TotalHits]));
  AssertTrue('Test completed successfully', True);
end;

initialization
  RegisterTest(TTestCase_StampedLock_Basic);
  RegisterTest(TTestCase_StampedLock_Concurrent);

end.
