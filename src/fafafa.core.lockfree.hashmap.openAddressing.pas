unit fafafa.core.lockfree.hashmap.openAddressing;



{**
 * fafafa.core.lockfree.hashmap.openAddressing - 无锁哈希表（开放寻址）
 *
 * 描述:
 *   - 单数组 + 探测序列（线性/二次/双散列），更 cache-friendly
 *   - 装载因子≤0.7 时性能最佳；高装载因子下探测长度上升
 *
 * 与 MM 实现（分离链接）对比与选型：
 *   - 追求吞吐/低延迟、键值简单、删除率不高：优先 OA
 *   - 插入/删除频繁、并发争用高、规模动态变化：优先 MM（详见 fafafa.core.lockfree.hashmap）
 *
 * 门面便捷构造（见 fafafa.core.lockfree）：
 *   CreateIntIntOAHashMap / CreateIntStrOAHashMap / CreateStrIntOAHashMap / CreateStrStrOAHashMap
 *}
{$mode objfpc}{$H+}

interface

uses
  SysUtils, fafafa.core.atomic, fafafa.core.lockfree.util;

// Fallback helpers used by generic templates must be declared in the interface.
// NOTE: Generic helpers must be called via `specialize`, e.g. `specialize _DefaultHashKey<K>(Key)`.
generic function _DefaultHashKey<T>(const AKey: T): Cardinal; inline;
generic function _DefaultKeysEqual<T>(const L, R: T): Boolean; inline;

type
  generic TLockFreeHashMap<K, V> = class
  public
    type
      THashFunc = function(const AKey: K): Cardinal;
      TEqualFunc = function(const L, R: K): Boolean;
      PEntry = ^TEntry;
      TEntry = record
        Key: K;
        Value: V;
        Hash: Cardinal;
        State: Integer; // 0=空(Empty), 1=写入中(WritePending), 2=已占用(Occupied), 3=已删除(Deleted)
      end;
  private
    FBuckets: array of TEntry;
    FCapacity: Integer;
    FMask: Integer;
    FSize: Integer;
    FHash: THashFunc;
    FEqual: TEqualFunc;

    function HashKey(const AKey: K): Cardinal;
    function KeysEqual(const L, R: K): Boolean;
    function FindSlot(const AKey: K; AHash: Cardinal): Integer;
    procedure Resize;
  public
    constructor Create(ACapacity: Integer = 1024); overload;
    constructor Create(ACapacity: Integer; AHash: THashFunc; AEqual: TEqualFunc); overload;
    destructor Destroy; override;

    // Strict constructor helper: require explicit hash & equality (avoid unsafe fallbacks for managed/padded types)
    class function NewStrict(ACapacity: Integer; AHash: THashFunc; AEqual: TEqualFunc): TLockFreeHashMap; static;

    { 写入：当 key 已存在时更新 value；当命中空槽位时插入 }
    function Put(const AKey: K; const AValue: V): Boolean;
    function Get(const AKey: K; out AValue: V): Boolean;
    function Remove(const AKey: K): Boolean;
    function ContainsKey(const AKey: K): Boolean;

    // STL-style aliases for API consistency with MM implementation
    function insert(const AKey: K; const AValue: V): Boolean; inline;
    function find(const AKey: K; out AValue: V): Boolean; inline;
    function erase(const AKey: K): Boolean; inline;

    function GetSize: Integer;
    function GetCapacity: Integer;
    function IsEmpty: Boolean;
    procedure Clear; // 清空哈希表（不收缩容量）
  end;

implementation

generic function _DefaultHashKey<T>(const AKey: T): Cardinal;
var
  S: AnsiString;
begin
  if TypeInfo(T) = TypeInfo(string) then
  begin
    S := PAnsiString(@AKey)^;
    if Length(S) = 0 then
      Exit(0);
    Exit(SimpleHash(S[1], Length(S)));
  end;

  Result := SimpleHash(AKey, SizeOf(T));
end;

generic function _DefaultKeysEqual<T>(const L, R: T): Boolean;
begin
  if TypeInfo(T) = TypeInfo(string) then
    Exit(PAnsiString(@L)^ = PAnsiString(@R)^);

  Result := CompareMem(@L, @R, SizeOf(T));
end;

constructor TLockFreeHashMap.Create(ACapacity: Integer);
var
  I: Integer;
begin
  inherited Create;
  if not IsPowerOfTwo(ACapacity) then
    ACapacity := NextPowerOfTwo(ACapacity);
  FCapacity := ACapacity;
  FMask := ACapacity - 1;
  SetLength(FBuckets, ACapacity);
  FSize := 0;
  FHash := nil;
  FEqual := nil;
  for I := 0 to ACapacity - 1 do
  begin
    FBuckets[I].State := 0;
    FBuckets[I].Hash := 0;
  end;
end;

constructor TLockFreeHashMap.Create(ACapacity: Integer; AHash: THashFunc; AEqual: TEqualFunc);
var
  I: Integer;
begin
  inherited Create;
  if not IsPowerOfTwo(ACapacity) then
    ACapacity := NextPowerOfTwo(ACapacity);
  FCapacity := ACapacity;
  FMask := ACapacity - 1;
  SetLength(FBuckets, ACapacity);
  FSize := 0;
  FHash := AHash;
  FEqual := AEqual;
  for I := 0 to ACapacity - 1 do
  begin
    FBuckets[I].State := 0;
    FBuckets[I].Hash := 0;
  end;
end;

destructor TLockFreeHashMap.Destroy;
var
  I: Integer;
begin
  // Finalize managed fields (if any) to avoid leaks when K/V are managed types (e.g. string)
  if Length(FBuckets) > 0 then
  begin
    {$push}
    {$warn 5057 off} // allow Finalize on generics; it's a no-op for unmanaged types
    // Note: In concurrent scenarios, Destroy should be called when no other threads access the map.
    // We finalize keys/values here which is safe at teardown.
    for I := 0 to FCapacity - 1 do
    begin
      if FBuckets[I].State <> 0 then
      begin
        System.Finalize(FBuckets[I].Key);
        System.Finalize(FBuckets[I].Value);
      end;
    end;
    {$pop}
  end;
  SetLength(FBuckets, 0);
  inherited Destroy;
end;

class function TLockFreeHashMap.NewStrict(ACapacity: Integer; AHash: THashFunc; AEqual: TEqualFunc): TLockFreeHashMap;
begin
  if (not Assigned(AHash)) or (not Assigned(AEqual)) then
    raise Exception.Create('TLockFreeHashMap.NewStrict: hash and equal must be provided');
  Result := TLockFreeHashMap.Create(ACapacity, AHash, AEqual);
end;

function TLockFreeHashMap.HashKey(const AKey: K): Cardinal;
begin
  if Assigned(FHash) then
    Exit(FHash(AKey));
  Result := specialize _DefaultHashKey<K>(AKey);
end;

function TLockFreeHashMap.KeysEqual(const L, R: K): Boolean;
begin
  if Assigned(FEqual) then
    Exit(FEqual(L, R));
  Result := specialize _DefaultKeysEqual<K>(L, R);
end;

function TLockFreeHashMap.FindSlot(const AKey: K; AHash: Cardinal): Integer;
var
  LIndex: Integer;
  LProbeCount: Integer;
  LState: Integer;
  LFirstDeleted: Integer;
begin
  LIndex := AHash and FMask;
  LProbeCount := 0;
  LFirstDeleted := -1;
  while LProbeCount < FCapacity do
  begin
    LState := atomic_load(FBuckets[LIndex].State, mo_acquire);
    case LState of
      0 {Empty}: begin
        if LFirstDeleted <> -1 then Exit(LFirstDeleted)
        else Exit(LIndex);
      end;
      2 {Occupied}: begin
        if (FBuckets[LIndex].Hash = AHash) and
           (KeysEqual(FBuckets[LIndex].Key, AKey)) then
          Exit(LIndex);
      end;
      3 {Deleted}: begin
        if LFirstDeleted = -1 then LFirstDeleted := LIndex;
      end;
      1 {Writing}: ; // 继续探测
    end;
    LIndex := (LIndex + 1) and FMask;
    Inc(LProbeCount);
  end;
  if LFirstDeleted <> -1 then Exit(LFirstDeleted);
  Result := -1;
end;

procedure TLockFreeHashMap.Resize;
begin
  // Not implemented in this simplified version
end;

function TLockFreeHashMap.Put(const AKey: K; const AValue: V): Boolean;
var
  LHash: Cardinal;
  LIndex: Integer;
  LState: Integer;
  LExpected: Integer;
  LAttempts: Integer;
begin
  LHash := HashKey(AKey);
  LAttempts := 0;
  repeat
    LIndex := FindSlot(AKey, LHash);
    if LIndex = -1 then Exit(False);

    // 读取槽位状态
    LState := atomic_load(FBuckets[LIndex].State, mo_acquire);

    if LState = 0 {Empty} then
    begin
      // 尝试从 Empty -> Writing
      LExpected := 0;
      if atomic_compare_exchange_strong(FBuckets[LIndex].State, LExpected, 1 {Writing}) then
      begin
        // 写入 Key/Value/Hash（尚未发布）
        FBuckets[LIndex].Key := AKey;
        FBuckets[LIndex].Value := AValue;
        FBuckets[LIndex].Hash := LHash;
        // 发布占用状态（release）：读侧 acquire 观察到 Occupied 后可见上述写入
        atomic_store(FBuckets[LIndex].State, 2 {Occupied}, mo_release);
        atomic_fetch_add(FSize, 1);
        Exit(True);
      end;
      // CAS 失败：继续重试
    end
    else if LState = 2 {Occupied} then
    begin
      // 可能是更新（Upsert）
      if (FBuckets[LIndex].Hash = LHash) and
         (KeysEqual(FBuckets[LIndex].Key, AKey)) then
      begin
        // 覆盖旧值：对托管类型确保释放旧值，随后写入新值
        {$push}
        {$warn 5057 off}
        System.Finalize(FBuckets[LIndex].Value);
        {$pop}
        FBuckets[LIndex].Value := AValue;
        Exit(True);
      end;
      // 不同 Key 的占用：继续重试（FindSlot 会线性探测到下一个候选槽）
    end
    else if LState = 3 {Deleted} then
    begin
      // 复用墓碑槽位
      LExpected := 3;
      if atomic_compare_exchange_strong(FBuckets[LIndex].State, LExpected, 1 {Writing}) then
      begin
        FBuckets[LIndex].Key := AKey;
        FBuckets[LIndex].Value := AValue;
        FBuckets[LIndex].Hash := LHash;
        atomic_store(FBuckets[LIndex].State, 2 {Occupied}, mo_release);
        atomic_fetch_add(FSize, 1);
        Exit(True);
      end;
    end
    else
    begin
      // LState = 1 {Writing}：让出并重试
    end;

    Inc(LAttempts);
    if (LAttempts and $3F) = 0 then
    begin
      {$IFDEF FAFAFA_LOCKFREE_BACKOFF}
      var SpinCount: Integer = 0;
      BackoffStep(SpinCount);
      {$ENDIF}
    end
  until LAttempts > 2048; // 有界重试，避免极端情况下无限循环；可能在高装载下失败

  Result := False; // 返回 False 表示未能在合理时间内完成插入，建议增大容量或降低装载因子
end;

function TLockFreeHashMap.Get(const AKey: K; out AValue: V): Boolean;
var
  LHash: Cardinal;
  LIndex: Integer;
  LProbeCount: Integer;
  LState: Integer;
begin
  LHash := HashKey(AKey);
  LIndex := LHash and FMask;
  LProbeCount := 0;
  while LProbeCount < FCapacity do
  begin
    LState := atomic_load(FBuckets[LIndex].State, mo_acquire);
    case LState of
      0 {Empty}: Exit(False);
      2 {Occupied}: begin
        if (FBuckets[LIndex].Hash = LHash) and
           (KeysEqual(FBuckets[LIndex].Key, AKey)) then
        begin
          AValue := FBuckets[LIndex].Value;
          Exit(True);
        end;
      end;
      1 {Writing},
      3 {Deleted}: ;
    end;
    LIndex := (LIndex + 1) and FMask;
    Inc(LProbeCount);
  end;
  Result := False;
end;

function TLockFreeHashMap.Remove(const AKey: K): Boolean;
var
  LHash: Cardinal;
  LIndex: Integer;
  LProbeCount: Integer;
  LState: Integer;
  LExpected: Integer;
begin
  LHash := HashKey(AKey);
  LIndex := LHash and FMask;
  LProbeCount := 0;
  while LProbeCount < FCapacity do
  begin
    LState := atomic_load(FBuckets[LIndex].State, mo_acquire);
    case LState of
      0 {Empty}: Exit(False);
      2 {Occupied}: begin
        if (FBuckets[LIndex].Hash = LHash) and
           (KeysEqual(FBuckets[LIndex].Key, AKey)) then
        begin
          LExpected := 2;
          if atomic_compare_exchange_strong(FBuckets[LIndex].State, LExpected, 3 {Deleted}) then
          begin
            {$push}
            {$warn 5057 off}
            // Release managed fields (if any) on logical deletion
            System.Finalize(FBuckets[LIndex].Key);
            System.Finalize(FBuckets[LIndex].Value);
            {$pop}
            atomic_fetch_sub(FSize, 1);
            Exit(True);
          end;
        end;
      end;
      1 {Writing},
      3 {Deleted}: ;
    end;
    LIndex := (LIndex + 1) and FMask;
    Inc(LProbeCount);
  end;
  Result := False;
end;

function TLockFreeHashMap.ContainsKey(const AKey: K): Boolean;
var
  LValue: V;
begin
  Result := Get(AKey, LValue);
end;

function TLockFreeHashMap.GetSize: Integer;
begin
  Result := atomic_load(FSize, mo_relaxed);
end;

function TLockFreeHashMap.GetCapacity: Integer;
begin
  Result := FCapacity;
end;


procedure TLockFreeHashMap.Clear;
var
  I: Integer;
begin
  // 清空所有桶并重置状态
  for I := 0 to FCapacity - 1 do
  begin
    // 对托管类型进行 Finalize 以避免泄漏，然后复位为 Empty
    {$push}
    {$warn 5057 off}
    if FBuckets[I].State = 2 {Occupied} then
    begin
      System.Finalize(FBuckets[I].Key);
      System.Finalize(FBuckets[I].Value);
    end;
    {$pop}
    atomic_store(FBuckets[I].State, 0, mo_relaxed);
    // 复位辅助字段
    FillChar(FBuckets[I].Key, SizeOf(K), 0);
    FillChar(FBuckets[I].Value, SizeOf(V), 0);
    FBuckets[I].Hash := 0;
  end;
  atomic_store(FSize, 0, mo_relaxed);
end;


// === STL-style APIs ===
function TLockFreeHashMap.insert(const AKey: K; const AValue: V): Boolean;
var
  LHash: Cardinal;
  LIndex: Integer;
  LState: Integer;
  LExpected: Integer;
  LAttempts: Integer;
begin
  // InsertOnly: do not update existing keys
  LHash := HashKey(AKey);
  LAttempts := 0;
  repeat
    LIndex := FindSlot(AKey, LHash);
    if LIndex = -1 then Exit(False);

    LState := atomic_load(FBuckets[LIndex].State, mo_acquire);

    if LState = 0 {Empty} then
    begin
      LExpected := 0;
      if atomic_compare_exchange_strong(FBuckets[LIndex].State, LExpected, 1 {Writing}) then
      begin
        FBuckets[LIndex].Key := AKey;
        FBuckets[LIndex].Value := AValue;
        FBuckets[LIndex].Hash := LHash;
        atomic_store(FBuckets[LIndex].State, 2 {Occupied}, mo_release);
        atomic_fetch_add(FSize, 1);
        Exit(True);
      end;
    end
    else if LState = 2 {Occupied} then
    begin
      if (FBuckets[LIndex].Hash = LHash) and (KeysEqual(FBuckets[LIndex].Key, AKey)) then
        Exit(False); // already exists, do not update
      // else: continue retry
    end
    else if LState = 3 {Deleted} then
    begin
      // reuse tombstone slot for insert-only
      LExpected := 3;
      if atomic_compare_exchange_strong(FBuckets[LIndex].State, LExpected, 1 {Writing}) then
      begin
        FBuckets[LIndex].Key := AKey;
        FBuckets[LIndex].Value := AValue;
        FBuckets[LIndex].Hash := LHash;
        atomic_store(FBuckets[LIndex].State, 2 {Occupied}, mo_release);
        atomic_fetch_add(FSize, 1);
        Exit(True);
      end;
    end
    else
    begin
      // Writing: yield and retry
    end;

    Inc(LAttempts);
    if (LAttempts and $3F) = 0 then
    begin
      {$IFDEF FAFAFA_LOCKFREE_BACKOFF}
      var SpinCount: Integer = 0;
      BackoffStep(SpinCount);
      {$ENDIF}
    end
  until LAttempts > 2048;

  Result := False;
end;

function TLockFreeHashMap.find(const AKey: K; out AValue: V): Boolean;
begin
  Result := Get(AKey, AValue);
end;

function TLockFreeHashMap.erase(const AKey: K): Boolean;
begin
  Result := Remove(AKey);
end;

function TLockFreeHashMap.IsEmpty: Boolean;
begin
  Result := atomic_load(FSize, mo_relaxed) = 0;
end;

end.
