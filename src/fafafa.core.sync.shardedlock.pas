unit fafafa.core.sync.shardedlock;

{$mode objfpc}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  IShardedLock<T> - 分片锁（提高并发读性能）

  参照 Rust parking_lot::RwLock 的分片策略：
  - 将数据分成多个分片，每个分片有独立的读写锁
  - 读操作根据键的哈希值定位到特定分片
  - 写操作需要锁定所有分片

  适用场景：
  - 读多写少的高并发场景
  - 键空间较大，可以有效分散到多个分片
  - 如：缓存、路由表、配置存储

  使用示例：
    var
      Cache: TShardedLock<string, Integer>;
    begin
      Cache.Init(16);  // 16 个分片
      Cache.Write('key1', 100);
      WriteLn(Cache.Read('key1'));  // 100
    end;

  性能特性：
  - 读操作：O(1) 哈希 + 单分片读锁
  - 写操作：O(n) 需要获取所有分片的写锁
  - 分片数建议：CPU 核心数的 2-4 倍
}

interface

uses
  SysUtils, fafafa.core.atomic;

type

  { TShardRWLock - 单个分片的读写锁 }

  TShardRWLock = record
  private
    FState: Int32;  // 高 16 位: 写锁标志, 低 16 位: 读计数
  const
    WRITE_LOCKED = Int32($10000);  // 写锁标志
    READ_MASK = Int32($FFFF);      // 读计数掩码
  public
    procedure Init;
    procedure ReadLock;
    procedure ReadUnlock;
    procedure WriteLock;
    procedure WriteUnlock;
  end;

  { generic TShardedLock<TKey, TValue> - 分片锁容器 }

  generic TShardedLock<TKey, TValue> = record
  type
    TKeyValuePair = record
      Key: TKey;
      Value: TValue;
      Used: Boolean;
    end;

    TShard = record
      Lock: TShardRWLock;
      Items: array of TKeyValuePair;
      Count: Integer;
      Capacity: Integer;
    end;
    PKeyValuePair = ^TKeyValuePair;

  private
    FShards: array of TShard;
    FShardCount: Integer;
    FHashSeed: UInt32;

    function HashKey(const AKey: TKey): UInt32;
    function GetShardIndex(const AKey: TKey): Integer; inline;
    function FindInShard(ShardIdx: Integer; const AKey: TKey): PKeyValuePair;
  public
    {** 初始化分片锁
        @param AShardCount 分片数量（建议为 CPU 核心数的 2-4 倍） *}
    procedure Init(AShardCount: Integer = 16);

    {** 释放资源 *}
    procedure Done;

    {** 读取值（线程安全）
        @return 如果键存在返回 True *}
    function TryRead(const AKey: TKey; out AValue: TValue): Boolean;

    {** 读取值，不存在时返回默认值 *}
    function Read(const AKey: TKey; const ADefault: TValue): TValue;

    {** 写入值（线程安全） *}
    procedure Write(const AKey: TKey; const AValue: TValue);

    {** 删除键（线程安全）
        @return 如果键存在并被删除返回 True *}
    function Remove(const AKey: TKey): Boolean;

    {** 检查键是否存在 *}
    function Contains(const AKey: TKey): Boolean;

    {** 清空所有数据 *}
    procedure Clear;

    {** 获取分片数量 *}
    property ShardCount: Integer read FShardCount;
  end;

  { 常用类型特化 }
  TShardedLockStrInt = specialize TShardedLock<string, Integer>;
  TShardedLockStrStr = specialize TShardedLock<string, string>;
  TShardedLockIntInt = specialize TShardedLock<Integer, Integer>;
  TShardedLockIntPtr = specialize TShardedLock<Integer, Pointer>;

implementation

{ TShardRWLock }

procedure TShardRWLock.Init;
begin
  FState := 0;
end;

procedure TShardRWLock.ReadLock;
var
  Current, Desired: Int32;
begin
  repeat
    Current := atomic_load(FState, mo_relaxed);
    // 如果写锁被持有，让出 CPU 并重试
    if Current < 0 then
    begin
      Sleep(0);
      Continue;
    end;
    Desired := Current + 1;
  until atomic_compare_exchange_weak(FState, Current, Desired, mo_acquire, mo_relaxed);
end;

procedure TShardRWLock.ReadUnlock;
begin
  atomic_fetch_sub(FState, 1, mo_release);
end;

procedure TShardRWLock.WriteLock;
var
  Current: Int32;
begin
  // 尝试将状态设为 -1（独占写锁）
  repeat
    Current := 0;  // 只有在完全空闲时才能获取写锁
    if atomic_compare_exchange_weak(FState, Current, -1, mo_acquire, mo_relaxed) then
      Exit;
    Sleep(0);  // 让出 CPU
  until False;
end;

procedure TShardRWLock.WriteUnlock;
begin
  atomic_store(FState, 0, mo_release);
end;

{ TShardedLock<TKey, TValue> }

function TShardedLock.HashKey(const AKey: TKey): UInt32;
var
  Data: PByte;
  Len: Integer;
  H: UInt32;
  i: Integer;
begin
  // 使用 FNV-1a 哈希算法
  H := 2166136261 xor FHashSeed;
  Data := @AKey;
  Len := SizeOf(TKey);

  for i := 0 to Len - 1 do
  begin
    H := H xor Data[i];
    H := H * 16777619;
  end;

  Result := H;
end;

function TShardedLock.GetShardIndex(const AKey: TKey): Integer;
begin
  Result := Integer(HashKey(AKey) mod UInt32(FShardCount));
end;

function TShardedLock.FindInShard(ShardIdx: Integer; const AKey: TKey): PKeyValuePair;
var
  i: Integer;
begin
  Result := nil;
  with FShards[ShardIdx] do
  begin
    for i := 0 to Length(Items) - 1 do
    begin
      if Items[i].Used and CompareMem(@Items[i].Key, @AKey, SizeOf(TKey)) then
        Exit(@Items[i]);
    end;
  end;
end;

procedure TShardedLock.Init(AShardCount: Integer);
var
  i: Integer;
begin
  if AShardCount < 1 then
    AShardCount := 16;

  FShardCount := AShardCount;
  FHashSeed := UInt32(GetTickCount64);
  SetLength(FShards, AShardCount);

  for i := 0 to AShardCount - 1 do
  begin
    FShards[i].Lock.Init;
    FShards[i].Count := 0;
    FShards[i].Capacity := 16;
    SetLength(FShards[i].Items, 16);
  end;
end;

procedure TShardedLock.Done;
var
  i: Integer;
begin
  for i := 0 to FShardCount - 1 do
    SetLength(FShards[i].Items, 0);
  SetLength(FShards, 0);
  FShardCount := 0;
end;

function TShardedLock.TryRead(const AKey: TKey; out AValue: TValue): Boolean;
var
  ShardIdx: Integer;
  Pair: PKeyValuePair;
begin
  ShardIdx := GetShardIndex(AKey);
  FShards[ShardIdx].Lock.ReadLock;
  try
    Pair := FindInShard(ShardIdx, AKey);
    if Pair <> nil then
    begin
      AValue := Pair^.Value;
      Result := True;
    end
    else
      Result := False;
  finally
    FShards[ShardIdx].Lock.ReadUnlock;
  end;
end;

function TShardedLock.Read(const AKey: TKey; const ADefault: TValue): TValue;
begin
  if not TryRead(AKey, Result) then
    Result := ADefault;
end;

procedure TShardedLock.Write(const AKey: TKey; const AValue: TValue);
var
  ShardIdx: Integer;
  Pair: PKeyValuePair;
  i, NewCap: Integer;
begin
  ShardIdx := GetShardIndex(AKey);
  FShards[ShardIdx].Lock.WriteLock;
  try
    // 先查找是否已存在
    Pair := FindInShard(ShardIdx, AKey);
    if Pair <> nil then
    begin
      Pair^.Value := AValue;
      Exit;
    end;

    // 查找空槽位
    with FShards[ShardIdx] do
    begin
      for i := 0 to Length(Items) - 1 do
      begin
        if not Items[i].Used then
        begin
          Items[i].Key := AKey;
          Items[i].Value := AValue;
          Items[i].Used := True;
          Inc(Count);
          Exit;
        end;
      end;

      // 需要扩容
      NewCap := Length(Items) * 2;
      SetLength(Items, NewCap);
      Capacity := NewCap;

      // 添加到新槽位
      for i := Count to NewCap - 1 do
        Items[i].Used := False;

      Items[Count].Key := AKey;
      Items[Count].Value := AValue;
      Items[Count].Used := True;
      Inc(Count);
    end;
  finally
    FShards[ShardIdx].Lock.WriteUnlock;
  end;
end;

function TShardedLock.Remove(const AKey: TKey): Boolean;
var
  ShardIdx: Integer;
  Pair: PKeyValuePair;
begin
  ShardIdx := GetShardIndex(AKey);
  FShards[ShardIdx].Lock.WriteLock;
  try
    Pair := FindInShard(ShardIdx, AKey);
    if Pair <> nil then
    begin
      Pair^.Used := False;
      Dec(FShards[ShardIdx].Count);
      Result := True;
    end
    else
      Result := False;
  finally
    FShards[ShardIdx].Lock.WriteUnlock;
  end;
end;

function TShardedLock.Contains(const AKey: TKey): Boolean;
var
  ShardIdx: Integer;
begin
  ShardIdx := GetShardIndex(AKey);
  FShards[ShardIdx].Lock.ReadLock;
  try
    Result := FindInShard(ShardIdx, AKey) <> nil;
  finally
    FShards[ShardIdx].Lock.ReadUnlock;
  end;
end;

procedure TShardedLock.Clear;
var
  i, j: Integer;
begin
  for i := 0 to FShardCount - 1 do
  begin
    FShards[i].Lock.WriteLock;
    try
      for j := 0 to Length(FShards[i].Items) - 1 do
        FShards[i].Items[j].Used := False;
      FShards[i].Count := 0;
    finally
      FShards[i].Lock.WriteUnlock;
    end;
  end;
end;

end.
