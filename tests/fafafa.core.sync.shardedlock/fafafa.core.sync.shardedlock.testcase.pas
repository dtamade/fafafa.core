{$CODEPAGE UTF8}
unit fafafa.core.sync.shardedlock.testcase;

{**
 * fafafa.core.sync.shardedlock 测试套件
 *
 * @author fafafaStudio
 * @version 1.0
 *}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.shardedlock,
  TestHelpers_Sync;

type
  // ===== 基础功能测试 =====
  TTestCase_ShardedLock_Basic = class(TTestCase)
  published
    procedure Test_Init;
    procedure Test_WriteRead;
    procedure Test_Remove;
    procedure Test_Contains;
    procedure Test_Clear;
    procedure Test_ReadDefault;
  end;

  // ===== 并发测试 =====
  TTestCase_ShardedLock_Concurrent = class(TTestCase)
  published
    procedure Test_ConcurrentRead;
    procedure Test_ConcurrentWrite;
    procedure Test_ConcurrentReadWrite;
  end;

  // ===== 压力测试 =====
  TTestCase_ShardedLock_Stress = class(TTestCase)
  published
    procedure Test_ManyKeys;
    procedure Test_RapidReadWrite;
  end;

implementation

{ TTestCase_ShardedLock_Basic }

procedure TTestCase_ShardedLock_Basic.Test_Init;
var
  Cache: TShardedLockIntInt;
begin
  Cache.Init(8);
  try
    AssertEquals('Shard count should be 8', 8, Cache.ShardCount);
  finally
    Cache.Done;
  end;
end;

procedure TTestCase_ShardedLock_Basic.Test_WriteRead;
var
  Cache: TShardedLockIntInt;
  Val: Integer;
begin
  Cache.Init(4);
  try
    Cache.Write(1, 100);
    Cache.Write(2, 200);
    Cache.Write(3, 300);

    AssertTrue('Key 1 should exist', Cache.TryRead(1, Val));
    AssertEquals('Value for key 1', 100, Val);

    AssertTrue('Key 2 should exist', Cache.TryRead(2, Val));
    AssertEquals('Value for key 2', 200, Val);

    AssertTrue('Key 3 should exist', Cache.TryRead(3, Val));
    AssertEquals('Value for key 3', 300, Val);

    AssertFalse('Key 4 should not exist', Cache.TryRead(4, Val));
  finally
    Cache.Done;
  end;
end;

procedure TTestCase_ShardedLock_Basic.Test_Remove;
var
  Cache: TShardedLockIntInt;
  Val: Integer;
begin
  Cache.Init(4);
  try
    Cache.Write(1, 100);
    AssertTrue('Key 1 should exist', Cache.Contains(1));

    AssertTrue('Remove should return True', Cache.Remove(1));
    AssertFalse('Key 1 should not exist after remove', Cache.Contains(1));

    AssertFalse('Remove non-existent should return False', Cache.Remove(1));
  finally
    Cache.Done;
  end;
end;

procedure TTestCase_ShardedLock_Basic.Test_Contains;
var
  Cache: TShardedLockIntInt;
begin
  Cache.Init(4);
  try
    AssertFalse('Key 1 should not exist', Cache.Contains(1));

    Cache.Write(1, 100);
    AssertTrue('Key 1 should exist', Cache.Contains(1));
    AssertFalse('Key 2 should not exist', Cache.Contains(2));
  finally
    Cache.Done;
  end;
end;

procedure TTestCase_ShardedLock_Basic.Test_Clear;
var
  Cache: TShardedLockIntInt;
begin
  Cache.Init(4);
  try
    Cache.Write(1, 100);
    Cache.Write(2, 200);
    Cache.Write(3, 300);

    AssertTrue('Key 1 should exist', Cache.Contains(1));
    AssertTrue('Key 2 should exist', Cache.Contains(2));

    Cache.Clear;

    AssertFalse('Key 1 should not exist after clear', Cache.Contains(1));
    AssertFalse('Key 2 should not exist after clear', Cache.Contains(2));
    AssertFalse('Key 3 should not exist after clear', Cache.Contains(3));
  finally
    Cache.Done;
  end;
end;

procedure TTestCase_ShardedLock_Basic.Test_ReadDefault;
var
  Cache: TShardedLockIntInt;
begin
  Cache.Init(4);
  try
    AssertEquals('Non-existent key should return default', -1, Cache.Read(999, -1));

    Cache.Write(1, 100);
    AssertEquals('Existing key should return value', 100, Cache.Read(1, -1));
  finally
    Cache.Done;
  end;
end;

{ TTestCase_ShardedLock_Concurrent }

type
  PShardedLockIntInt = ^TShardedLockIntInt;

  TShardedReadThread = class(TThread)
  private
    FCache: PShardedLockIntInt;
    FKeyStart, FKeyEnd: Integer;
    FIterations: Integer;
    FSuccess: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(ACache: PShardedLockIntInt; AKeyStart, AKeyEnd, AIterations: Integer);
    property Success: Boolean read FSuccess;
  end;

  TShardedWriteThread = class(TThread)
  private
    FCache: PShardedLockIntInt;
    FKeyStart, FKeyEnd: Integer;
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ACache: PShardedLockIntInt; AKeyStart, AKeyEnd, AIterations: Integer);
  end;

constructor TShardedReadThread.Create(ACache: PShardedLockIntInt; AKeyStart, AKeyEnd, AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FCache := ACache;
  FKeyStart := AKeyStart;
  FKeyEnd := AKeyEnd;
  FIterations := AIterations;
  FSuccess := True;
end;

procedure TShardedReadThread.Execute;
var
  i, Key: Integer;
  Val: Integer;
begin
  for i := 1 to FIterations do
  begin
    Key := FKeyStart + (i mod (FKeyEnd - FKeyStart + 1));
    if FCache^.TryRead(Key, Val) then
    begin
      if Val <> Key * 10 then
        FSuccess := False;
    end;
  end;
end;

constructor TShardedWriteThread.Create(ACache: PShardedLockIntInt; AKeyStart, AKeyEnd, AIterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FCache := ACache;
  FKeyStart := AKeyStart;
  FKeyEnd := AKeyEnd;
  FIterations := AIterations;
end;

procedure TShardedWriteThread.Execute;
var
  i, Key: Integer;
begin
  for i := 1 to FIterations do
  begin
    Key := FKeyStart + (i mod (FKeyEnd - FKeyStart + 1));
    FCache^.Write(Key, Key * 10);
  end;
end;

procedure TTestCase_ShardedLock_Concurrent.Test_ConcurrentRead;
var
  Cache: TShardedLockIntInt;
  Threads: array[0..3] of TShardedReadThread;
  i: Integer;
begin
  Cache.Init(8);
  try
    // 预先写入数据
    for i := 0 to 99 do
      Cache.Write(i, i * 10);

    // 创建读线程
    for i := 0 to 3 do
      Threads[i] := TShardedReadThread.Create(@Cache, 0, 99, 10000);

    // 启动
    for i := 0 to 3 do
      Threads[i].Start;

    // 等待完成
    for i := 0 to 3 do
    begin
      Threads[i].WaitFor;
      AssertTrue(Format('Thread %d should succeed', [i]), Threads[i].Success);
      Threads[i].Free;
    end;
  finally
    Cache.Done;
  end;
end;

procedure TTestCase_ShardedLock_Concurrent.Test_ConcurrentWrite;
var
  Cache: TShardedLockIntInt;
  Threads: array[0..3] of TShardedWriteThread;
  i: Integer;
begin
  Cache.Init(8);
  try
    // 创建写线程（每个线程写不同的键范围）
    for i := 0 to 3 do
      Threads[i] := TShardedWriteThread.Create(@Cache, i * 25, (i + 1) * 25 - 1, 1000);

    for i := 0 to 3 do
      Threads[i].Start;

    for i := 0 to 3 do
    begin
      Threads[i].WaitFor;
      Threads[i].Free;
    end;

    // 验证数据
    for i := 0 to 99 do
      AssertTrue(Format('Key %d should exist', [i]), Cache.Contains(i));
  finally
    Cache.Done;
  end;
end;

procedure TTestCase_ShardedLock_Concurrent.Test_ConcurrentReadWrite;
var
  Cache: TShardedLockIntInt;
  ReadThreads: array[0..3] of TShardedReadThread;
  WriteThreads: array[0..1] of TShardedWriteThread;
  i: Integer;
begin
  Cache.Init(8);
  try
    // 预先写入一些数据
    for i := 0 to 49 do
      Cache.Write(i, i * 10);

    // 创建读线程和写线程
    for i := 0 to 3 do
      ReadThreads[i] := TShardedReadThread.Create(@Cache, 0, 49, 5000);
    for i := 0 to 1 do
      WriteThreads[i] := TShardedWriteThread.Create(@Cache, 0, 49, 2000);

    // 启动所有线程
    for i := 0 to 3 do
      ReadThreads[i].Start;
    for i := 0 to 1 do
      WriteThreads[i].Start;

    // 等待完成
    for i := 0 to 1 do
    begin
      WriteThreads[i].WaitFor;
      WriteThreads[i].Free;
    end;
    for i := 0 to 3 do
    begin
      ReadThreads[i].WaitFor;
      ReadThreads[i].Free;
    end;
  finally
    Cache.Done;
  end;
end;

{ TTestCase_ShardedLock_Stress }

procedure TTestCase_ShardedLock_Stress.Test_ManyKeys;
var
  Cache: TShardedLockIntInt;
  i, KeyCount: Integer;
  StartTime, ElapsedMs: QWord;
begin
  KeyCount := 10000;
  Cache.Init(16);
  try
    StartTime := GetCurrentTimeMs;
    for i := 0 to KeyCount - 1 do
      Cache.Write(i, i * 10);
    ElapsedMs := GetCurrentTimeMs - StartTime;

    WriteLn(Format('Write %d keys in %d ms', [KeyCount, ElapsedMs]));

    // 验证
    for i := 0 to KeyCount - 1 do
      AssertEquals(Format('Key %d value', [i]), i * 10, Cache.Read(i, -1));
  finally
    Cache.Done;
  end;
end;

procedure TTestCase_ShardedLock_Stress.Test_RapidReadWrite;
var
  Cache: TShardedLockIntInt;
  i, Iterations: Integer;
  StartTime, ElapsedMs: QWord;
begin
  Iterations := 100000;
  Cache.Init(16);
  try
    // 预先写入
    for i := 0 to 99 do
      Cache.Write(i, i * 10);

    StartTime := GetCurrentTimeMs;
    for i := 1 to Iterations do
    begin
      Cache.Write(i mod 100, i);
      Cache.Read(i mod 100, -1);
    end;
    ElapsedMs := GetCurrentTimeMs - StartTime;

    WriteLn(Format('Rapid read/write: %d iterations in %d ms', [Iterations * 2, ElapsedMs]));
    AssertTrue('Should complete in reasonable time', ElapsedMs < 5000);
  finally
    Cache.Done;
  end;
end;

initialization
  RegisterTest(TTestCase_ShardedLock_Basic);
  RegisterTest(TTestCase_ShardedLock_Concurrent);
  RegisterTest(TTestCase_ShardedLock_Stress);

end.
