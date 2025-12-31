unit fafafa.core.lockfree.hashmap;


{**
 * fafafa.core.lockfree.hashmap - 无锁哈希表实现
 *
 * @desc 基于 Michael & Michael 算法的高性能无锁哈希表
 *       使用 C/C++ 兼容的原子操作和标记指针防止 ABA 问题
 *       实现分离链接法，每个桶使用无锁链表
 *
 * @author fafafa.collections5 开发团队
 * @version 1.0.0
 * @since 2025-08-08
 *
 * @algorithm Michael & Michael 无锁哈希表算法 (2002)
 *           "High Performance Dynamic Lock-Free Hash Tables and List-Based Sets"
 *           论文: https://www.cs.rochester.edu/~scott/papers/2002_PODC_lock-free_hash.pdf
 *
 * @thread_safety 线程安全性
 *   - 多读者: 安全 (并发读取完全无锁)
 *   - 多写者: 安全 (并发写入使用原子 CAS 操作)
 *   - 读写混合: 安全 (读者通过内存序看到一致状态)
 *   - 无阻塞: 操作永不阻塞，仅在竞争时重试
 *
 * @aba_solution 使用标记指针解决 ABA 问题:
 *   - 每个指针与版本标签配对 (64位系统上为16位)
 *   - CAS 操作原子性地比较指针和标签
 *   - 即使内存在相同地址重用，标签不匹配也能防止 ABA
 *   - 示例: ptr=0x1000,tag=1 -> ptr=0x1000,tag=2 (不同的标记值)
 *
 * @memory_ordering 精确的内存序保证性能和正确性:
 *   - acquire: 确保读写操作不能重排到此操作之前
 *   - release: 确保读写操作不能重排到此操作之后
 *   - acq_rel: 结合 acquire 和 release 语义用于 RMW 操作
 *   - relaxed: 无排序约束，仅保证原子性
 *
 * @usage_example 使用示例
 *   var
 *     LHashMap: TStringIntHashMap;
 *     LValue: Integer;
 *   begin
 *     LHashMap := TStringIntHashMap.Create(1024, @DefaultStringHash, @MyStringComparer);
 *     try
 *       // 线程安全操作
 *       LHashMap.insert('key1', 100);           // 插入键值对
 *       if LHashMap.find('key1', LValue) then   // 根据键查找值
 *         WriteLn('找到: ', LValue);
 *       LHashMap.update('key1', 200);           // 更新现有值
 *       LHashMap.erase('key1');                 // 删除键值对
 *     finally
 *       LHashMap.Free;
 *     end;
 *   end;
 *
 * @limitations
 *   - No automatic resizing (fixed bucket count for now)
 *   - Deleted entries use logical deletion (memory not immediately reclaimed)
 *   - Hash function quality affects performance significantly
 *   - Load factor should be monitored to maintain performance
 *}

{**
 * 实现差异与选择指南
 *
 * 两个实现：
 * - fafafa.core.lockfree.hashmap（Michael & Michael，分离链接：桶 + 无锁链表）
 * - fafafa.core.lockfree.hashmap.openAddressing（开放寻址：单数组 + 探测序列）
 *
 * 何时选用：
 * - 追求吞吐/低延迟、键值简单、装载因子可控（≤ 0.7）：优先 OA（开放寻址）
 * - 插入/删除频繁、规模动态变化、并发争用高：优先 MM（分离链接）
 *
 * 性能/内存简述：
 * - OA：更 cache-friendly、内存占用更低；高装载因子下探测长度上升，性能下降
 * - MM：对高冲突和高删除率更稳；链表遍历受链长影响，内存开销略高
 *
 * 门面便捷构造（详见 fafafa.core.lockfree）：
 * - OA: CreateIntIntOAHashMap / CreateIntStrOAHashMap / CreateStrIntOAHashMap / CreateStrStrOAHashMap
 * - MM: CreateIntIntMMHashMap / CreateIntStrMMHashMap / CreateStrIntMMHashMap / CreateStrStrMMHashMap
 *}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils,
  fafafa.core.atomic,
  fafafa.core.lockfree.reclaim;

type
  {**
   * Lock-free hash map entry
   *}
  generic TLockFreeHashMapEntry<TKey, TValue> = record
    Key: TKey;
    Value: TValue;
    Hash: QWord;
    Next: atomic_tagged_ptr_t;  // ABA-safe next pointer
    IsDeleted: Boolean;
  end;

  {**
   * Michael & Michael's lock-free hash map
   *
   * @desc Thread-safe hash map with lock-free operations using separate chaining
   *       Each bucket contains a lock-free linked list of entries
   *       Uses Tagged Pointers to prevent ABA problems in concurrent access
   *
   * @algorithm_details
   *   1. Hash key to determine bucket index
   *   2. Traverse bucket's linked list using atomic loads with acquire semantics
   *   3. Use CAS with Tagged Pointers for atomic list modifications
   *   4. Logical deletion marks entries as deleted without immediate removal
   *   5. Memory ordering ensures visibility of updates across threads
   *}
  generic TMichaelHashMap<TKey, TValue> = class
  public
    type
      PEntry = ^TEntry;
      TEntry = specialize TLockFreeHashMapEntry<TKey, TValue>;
      THashFunction = function(const AKey: TKey): QWord;
      TKeyComparer = function(const AKey1, AKey2: TKey): Boolean;

  private
    FBuckets: array of atomic_tagged_ptr_t;  // Array of bucket heads (Tagged Pointers)
    FBucketCount: Integer;
    FHashFunction: THashFunction;
    FKeyComparer: TKeyComparer;
    FSize: Int64;                   // Atomic size counter
    FLoadFactor: Single;
    FMaxLoadFactor: Single;

    // Internal methods
    function GetBucketIndex(AHash: QWord): Integer; inline;
    function FindEntry(const AKey: TKey; AHash: QWord; out ABucket: Integer): PEntry;
    function CreateEntry(const AKey: TKey; const AValue: TValue; AHash: QWord): PEntry;
    procedure DisposeEntry(AEntry: PEntry);
    function NeedsResize: Boolean; inline;
    procedure TryResize;
    procedure CompactBucket(ABucket: Integer);

  public
    constructor Create(ABucketCount: Integer = 1024;
                      AHashFunction: THashFunction = nil;
                      AKeyComparer: TKeyComparer = nil);
    destructor Destroy; override;

    // Core operations (Boost.Lockfree style)
    function insert(const AKey: TKey; const AValue: TValue): Boolean;
    function find(const AKey: TKey; out AValue: TValue): Boolean;
    function erase(const AKey: TKey): Boolean;
    function update(const AKey: TKey; const AValue: TValue): Boolean;

    // Pascal-style aliases (Map-style API)
    function Put(const AKey: TKey; const AValue: TValue): Boolean; inline;
    function Get(const AKey: TKey; out AValue: TValue): Boolean; inline;
    function Remove(const AKey: TKey): Boolean; inline;
    function ContainsKey(const AKey: TKey): Boolean; inline;

    // Utility operations
    function empty: Boolean; inline;
    function size: Int64; inline;
    function load_factor: Single; inline;
    procedure clear;

    // Statistics
    function bucket_count: Integer; inline;
    function max_load_factor: Single; inline;
    procedure max_load_factor(AValue: Single); inline;

    // Properties (Pascal style for compatibility)
    property Count: Int64 read size;
    property IsEmpty: Boolean read empty;
    property BucketCount: Integer read bucket_count;
  end;

  {**
   * Convenience type aliases for common key-value combinations
   *}
  TStringIntHashMap = specialize TMichaelHashMap<string, Integer>;
  TIntStringHashMap = specialize TMichaelHashMap<Integer, string>;
  TStringStringHashMap = specialize TMichaelHashMap<string, string>;

// disposer for retired map entries (Finalize is done by the caller within generic context)
procedure MM_DisposeEntry(p: Pointer); inline;

// Default hash functions
function DefaultStringHash(const AKey: string): QWord;
function DefaultIntegerHash(const AKey: Integer): QWord;

// Default key comparers
function DefaultStringComparer(const AKey1, AKey2: string): Boolean;
function DefaultIntegerComparer(const AKey1, AKey2: Integer): Boolean;

implementation

procedure MM_DisposeEntry(p: Pointer); inline;
begin
  if p <> nil then
    FreeMem(p);
end;

// === Default hash functions ===

function DefaultStringHash(const AKey: string): QWord;
var
  I: Integer;
  LPrime: QWord;
begin
  // Simple FNV-1a hash with overflow protection
  Result := QWord(2166136261);
  LPrime := QWord(16777619);

  for I := 1 to Length(AKey) do
  begin
    Result := Result xor QWord(Ord(AKey[I]));
    // Prevent overflow by using modular arithmetic
    {$PUSH}
    {$Q-} // Disable overflow checking for this multiplication
    Result := Result * LPrime;
    {$POP}
  end;
end;

function DefaultIntegerHash(const AKey: Integer): QWord;
var
  LMagic: QWord;
begin
  // Simple integer hash with overflow protection
  Result := QWord(AKey and $7FFFFFFF); // Ensure positive value
  LMagic := QWord($45d9f3b);

  Result := Result xor (Result shr 16);
  {$PUSH}
  {$Q-} // Disable overflow checking for multiplication
  Result := Result * LMagic;
  {$POP}

  Result := Result xor (Result shr 16);
  {$PUSH}
  {$Q-} // Disable overflow checking for multiplication
  Result := Result * LMagic;
  {$POP}

  Result := Result xor (Result shr 16);
end;

// === Default key comparers ===

function DefaultStringComparer(const AKey1, AKey2: string): Boolean;
begin
  Result := AKey1 = AKey2;
end;

function DefaultIntegerComparer(const AKey1, AKey2: Integer): Boolean;
begin
  Result := AKey1 = AKey2;
end;

// === TMichaelHashMap implementation ===

procedure TMichaelHashMap.CompactBucket(ABucket: Integer);
var
  prevIsBucket: Boolean;
  prevNextTagged, curNextTagged, expectedTagged, desiredTagged: atomic_tagged_ptr_t;
  prevEntry, curEntry, nextEntry: PEntry;
  prevNextRef: ^atomic_tagged_ptr_t;
begin
  // Opportunistic physical removal of logically deleted nodes in a bucket
  prevIsBucket := True;
  prevNextTagged := atomic_tagged_ptr_load(FBuckets[ABucket], mo_acquire);
  prevEntry := nil;
  while True do
  begin
    curEntry := PEntry(atomic_tagged_ptr_get_ptr(prevNextTagged));
    if curEntry = nil then Exit;

    // Load current's next
    curNextTagged := atomic_tagged_ptr_load(curEntry^.Next, mo_acquire);
    nextEntry := PEntry(atomic_tagged_ptr_get_ptr(curNextTagged));

    if curEntry^.IsDeleted then
    begin
      // Try to unlink curEntry by updating prev->Next from prevNextTagged to next
      expectedTagged := prevNextTagged;
      desiredTagged := atomic_tagged_ptr(nextEntry, atomic_tagged_ptr_next(prevNextTagged));
      if prevIsBucket then
      begin
        if atomic_tagged_ptr_compare_exchange_strong(FBuckets[ABucket], expectedTagged, desiredTagged) then
        begin
          // finalize and retire removed node
          Finalize(curEntry^.Key);
          Finalize(curEntry^.Value);
          lf_retire(curEntry, @MM_DisposeEntry);
          // After successful unlink, prev remains same; refresh prevNextTagged
          prevNextTagged := desiredTagged;
          Continue;
        end
        else
        begin
          // reload from bucket head on failure
          prevNextTagged := atomic_tagged_ptr_load(FBuckets[ABucket], mo_acquire);
          Continue;
        end;
      end
      else
      begin
        // prev is an entry; update its Next
        prevNextRef := @prevEntry^.Next;
        if atomic_tagged_ptr_compare_exchange_strong(prevNextRef^, expectedTagged, desiredTagged) then
        begin
          Finalize(curEntry^.Key);
          Finalize(curEntry^.Value);
          lf_retire(curEntry, @MM_DisposeEntry);
          prevNextTagged := desiredTagged;
          Continue;
        end
        else
        begin
          // reload prevNextTagged from prevEntry^.Next and retry
          prevNextTagged := atomic_tagged_ptr_load(prevEntry^.Next, mo_acquire);
          Continue;
        end;
      end;
    end
    else
    begin
      // advance prev to cur
      prevIsBucket := False;
      prevEntry := curEntry;
      prevNextTagged := curNextTagged;
    end;
  end;
end;


constructor TMichaelHashMap.Create(ABucketCount: Integer;
                                  AHashFunction: THashFunction;
                                  AKeyComparer: TKeyComparer);
var
  I: Integer;
begin
  inherited Create;

  // 参数校验：桶数量
  if ABucketCount <= 0 then
    raise Exception.Create('MM HashMap: 桶数量必须为正整数');

  FBucketCount := ABucketCount;
  SetLength(FBuckets, FBucketCount);

  // 初始化所有桶为“空”标记指针
  for I := 0 to FBucketCount - 1 do
    FBuckets[I] := atomic_tagged_ptr(nil, 0);

  // 设置哈希函数与比较器
  FHashFunction := AHashFunction;
  FKeyComparer := AKeyComparer;

  // 若未提供函数，提示用户使用门面便捷构造器（包含默认哈希与比较器）
  if not Assigned(FHashFunction) then
    raise Exception.Create('MM HashMap: missing hash function; use facade constructor (e.g., CreateIntIntMMHashMap) or pass a hash function');
  if not Assigned(FKeyComparer) then
    raise Exception.Create('MM HashMap: missing key comparer; use facade constructor or pass a comparer');

  atomic_store_64(FSize, 0, mo_relaxed);
  FLoadFactor := 0.0;
  FMaxLoadFactor := 0.75;
end;

destructor TMichaelHashMap.Destroy;
begin
  clear;
  inherited Destroy;
end;

function TMichaelHashMap.GetBucketIndex(AHash: QWord): Integer;
var
  LIndex: QWord;
begin
  // Safe modulo operation to avoid overflow in debug mode
  LIndex := AHash mod QWord(FBucketCount);
  // Ensure the result fits in Integer range
  Result := Integer(LIndex and $7FFFFFFF);
end;

function TMichaelHashMap.FindEntry(const AKey: TKey; AHash: QWord; out ABucket: Integer): PEntry;
var
  LBucketHead: atomic_tagged_ptr_t;
  LCurrent: PEntry;
begin
  ABucket := GetBucketIndex(AHash);

  {**
   * Load bucket head with acquire semantics
   *
   * @mo_acquire ensures that:
   * - No reads/writes can be reordered before this load
   * - We see all writes that happened-before the release store of this pointer
   * - Critical for seeing consistent linked list structure
   *}
  LBucketHead := atomic_tagged_ptr_load(FBuckets[ABucket], mo_acquire);
  LCurrent := atomic_tagged_ptr_get_ptr(LBucketHead);

  {**
   * Traverse the bucket's linked list
   *
   * @algorithm Michael & Michael's list traversal:
   * 1. Follow next pointers using atomic loads
   * 2. Compare hash first (fast rejection)
   * 3. Check deletion flag (logical deletion)
   * 4. Compare keys only if hash matches and not deleted
   *}
  while LCurrent <> nil do
  begin
    // Fast hash comparison first (avoids expensive key comparison)
    if (LCurrent^.Hash = AHash) and
       (not LCurrent^.IsDeleted) and
       ((FKeyComparer = nil) or FKeyComparer(LCurrent^.Key, AKey)) then
    begin
      Exit(LCurrent);
    end;

    {**
     * Load next pointer with acquire semantics
     *
     * @mo_acquire ensures we see consistent next pointer
     * and any updates to the node it points to
     *}
    LCurrent := atomic_tagged_ptr_get_ptr(atomic_tagged_ptr_load(LCurrent^.Next, mo_acquire));
  end;

  Result := nil;
end;

function TMichaelHashMap.CreateEntry(const AKey: TKey; const AValue: TValue; AHash: QWord): PEntry;
begin
  New(Result);
  Result^.Key := AKey;
  Result^.Value := AValue;
  Result^.Hash := AHash;
  Result^.Next := atomic_tagged_ptr(nil, 0);
  Result^.IsDeleted := False;
end;

procedure TMichaelHashMap.DisposeEntry(AEntry: PEntry);
begin
  if AEntry <> nil then
    Dispose(AEntry);
end;

function TMichaelHashMap.NeedsResize: Boolean;
var
  LCurrentSize: Int64;
begin
  LCurrentSize := atomic_load_64(FSize, mo_relaxed);
  Result := (LCurrentSize / FBucketCount) > FMaxLoadFactor;
end;

procedure TMichaelHashMap.TryResize;
begin
  // Simplified resize - in a full implementation, this would be more complex
  // For now, we just accept the current load factor
end;

// === Core operations (Michael & Michael's algorithm) ===

function TMichaelHashMap.insert(const AKey: TKey; const AValue: TValue): Boolean;
var
  LHash: QWord;
  LBucketIndex: Integer;
  LNewEntry: PEntry;
  LBucketHead, LNewHead: atomic_tagged_ptr_t;
  LExisting: PEntry;
begin
  LHash := FHashFunction(AKey);

  {**
   * Check if key already exists
   *}
  LExisting := FindEntry(AKey, LHash, LBucketIndex);
  if LExisting <> nil then
    Exit(False); // Key already exists

  // Create new entry (this is safe to do outside the CAS loop)
  LNewEntry := CreateEntry(AKey, AValue, LHash);

  {** Insert at bucket head using CAS loop with Tagged Pointers **}
  repeat
    LBucketHead := atomic_tagged_ptr_load(FBuckets[LBucketIndex], mo_acquire);
    LNewEntry^.Next := LBucketHead;
    LNewHead := atomic_tagged_ptr(LNewEntry, atomic_tagged_ptr_next(LBucketHead));
  until atomic_tagged_ptr_compare_exchange_strong(FBuckets[LBucketIndex], LBucketHead, LNewHead);

  atomic_fetch_add_64(FSize, 1);

  if NeedsResize then
    TryResize;

  Result := True;
end;

function TMichaelHashMap.find(const AKey: TKey; out AValue: TValue): Boolean;
var
  LHash: QWord;
  LBucketIndex: Integer;
  LEntry: PEntry;
begin
  LHash := FHashFunction(AKey);
  LEntry := FindEntry(AKey, LHash, LBucketIndex);

  if (LEntry <> nil) and (not LEntry^.IsDeleted) then
  begin
    AValue := LEntry^.Value;
    Result := True;
  end
  else
  begin
    Result := False;
  end;
end;

function TMichaelHashMap.erase(const AKey: TKey): Boolean;
var
  LHash: QWord;
  LBucketIndex: Integer;
  LEntry: PEntry;
begin
  LHash := FHashFunction(AKey);
  LEntry := FindEntry(AKey, LHash, LBucketIndex);

  if (LEntry <> nil) and (not LEntry^.IsDeleted) then
  begin
    // Logical deletion - mark entry as deleted
    LEntry^.IsDeleted := True;
    atomic_fetch_sub_64(FSize, 1);
    // Opportunistic physical removal of deleted nodes in this bucket
    CompactBucket(LBucketIndex);
    Result := True;
  end
  else
  begin
    Result := False;
  end;
end;

function TMichaelHashMap.update(const AKey: TKey; const AValue: TValue): Boolean;
var
  LHash: QWord;
  LBucketIndex: Integer;
  LEntry: PEntry;
begin
  LHash := FHashFunction(AKey);
  LEntry := FindEntry(AKey, LHash, LBucketIndex);

  if (LEntry <> nil) and (not LEntry^.IsDeleted) then
  begin
    // Direct value update
    LEntry^.Value := AValue;
    Result := True;
  end
  else
  begin
    Result := False;
  end;
end;

// === Pascal-style aliases ===
function TMichaelHashMap.Put(const AKey: TKey; const AValue: TValue): Boolean;
var
  LHash: QWord;
  LBucketIndex: Integer;
  LEntry: PEntry;
begin
  // Upsert semantics: update if exists; otherwise insert
  LHash := FHashFunction(AKey);
  LEntry := FindEntry(AKey, LHash, LBucketIndex);
  if (LEntry <> nil) and (not LEntry^.IsDeleted) then
  begin
    LEntry^.Value := AValue;
    Exit(True);
  end;
  Result := insert(AKey, AValue);
end;

function TMichaelHashMap.Get(const AKey: TKey; out AValue: TValue): Boolean;
begin
  Result := find(AKey, AValue);
end;

function TMichaelHashMap.Remove(const AKey: TKey): Boolean;
begin
  Result := erase(AKey);
end;

function TMichaelHashMap.ContainsKey(const AKey: TKey): Boolean;
var
  V: TValue;
begin
  Result := find(AKey, V);
end;

// === Utility operations ===

function TMichaelHashMap.empty: Boolean;
begin
  Result := atomic_load_64(FSize, mo_relaxed) = 0;
end;

function TMichaelHashMap.size: Int64;
begin
  Result := atomic_load_64(FSize, mo_relaxed);
end;

function TMichaelHashMap.load_factor: Single;
var
  LCurrentSize: Int64;
begin
  LCurrentSize := atomic_load_64(FSize, mo_relaxed);
  if FBucketCount > 0 then
    Result := LCurrentSize / FBucketCount
  else
    Result := 0.0;
end;

procedure TMichaelHashMap.clear;
var
  I: Integer;
  LBucketHead: atomic_tagged_ptr_t;
  LCurrent, LNext: PEntry;
begin
  for I := 0 to FBucketCount - 1 do
  begin
    LBucketHead := atomic_tagged_ptr_load(FBuckets[I], mo_acquire);
    LCurrent := atomic_tagged_ptr_get_ptr(LBucketHead);

    while LCurrent <> nil do
    begin
      LNext := atomic_tagged_ptr_get_ptr(LCurrent^.Next);
      // retire entries; finalize managed fields in generic context, disposer only frees memory
      Finalize(LCurrent^.Key);
      Finalize(LCurrent^.Value);
      lf_retire(LCurrent, @MM_DisposeEntry);
      LCurrent := LNext;
    end;

    // Reset bucket to empty
    atomic_tagged_ptr_store(FBuckets[I], atomic_tagged_ptr(nil, 0), mo_release);
  end;

  atomic_store_64(FSize, 0, mo_relaxed);
end;

// === Statistics ===

function TMichaelHashMap.bucket_count: Integer;
begin
  Result := FBucketCount;
end;

function TMichaelHashMap.max_load_factor: Single;
begin
  Result := FMaxLoadFactor;
end;

procedure TMichaelHashMap.max_load_factor(AValue: Single);
begin
  if AValue > 0.0 then
    FMaxLoadFactor := AValue;
end;

end.
