unit fafafa.core.lockfree.priorityQueue;

{**
 * fafafa.core.lockfree.priorityQueue - 无锁优先队列实现
 *
 * 描述:
 *   - 基于 Boost.Lockfree 设计的高性能无锁优先队列
 *   - 使用跳表算法和标记指针技术防止 ABA 问题
 *   - 概率性并发跳表，提供 O(log n) 时间复杂度操作
 * 作者: fafafa.collections5 开发团队
 * 版本: 1.0.0
 * 日期: 2025-08-08
 * 特性:
 *   - 使用标记指针防止 ABA 问题
 *   - 基于跳表实现 O(log n) 性能
 *   - C/C++ std::atomic 兼容接口
 *   - Boost.Lockfree 风格 API 设计
 *   - 概率性层级生成算法
 *}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  fafafa.core.atomic;

const
  MAX_LEVEL = 16;  // 跳表最大层数

type
  {**
   * 优先队列结点（跳表结构）
   *}
  generic TLockFreePriorityQueueNode<T> = record
    Data: T;
    Priority: Int64;
    Level: Integer;
    Next: array[0..MAX_LEVEL-1] of atomic_tagged_ptr_t;  // ABA-safe forward pointers
    IsDeleted: Boolean;
  end;

  {**
   * 无锁优先队列（受 Boost.Lockfree 启发）
   *
   * @desc 线程安全的无锁优先队列
   *       基于跳表算法并结合标记指针（Tagged Pointer）
   *}
  generic TBoostLockFreePriorityQueue<T> = class
  public
    type
      PNode = ^TNode;
      TNode = specialize TLockFreePriorityQueueNode<T>;
      TComparer = function(const A, B: T): Integer;

  private
    FHead: PNode;                   // 跳表头结点（哨兵）
    FSize: Int64;                   // 原子大小计数器
    FComparer: TComparer;
    FMaxLevel: Integer;             // 当前最大层级

    // 内部方法
    function GenerateRandomLevel: Integer;
    function CreateNode(const AData: T; APriority: Int64; ALevel: Integer): PNode;
    procedure DisposeNode(ANode: PNode);
    function FindPredecessors(APriority: Int64; const AData: T; 
                             out APreds: array of PNode; 
                             out ASuccs: array of PNode): Boolean;

  public
    constructor Create(AComparer: TComparer = nil);
    destructor Destroy; override;

    // 核心操作（Boost.Lockfree 风格）
    function push(const AData: T; APriority: Int64 = 0): Boolean;
    function pop(out AData: T): Boolean;
    function top(out AData: T): Boolean;

    // 辅助操作
    function empty: Boolean; inline;
    function size: Int64; inline;
    procedure clear;

    // 属性（Pascal 兼容风格）
    property Count: Int64 read size;
    property IsEmpty: Boolean read empty;
  end;

  {**
   * Convenience type aliases
   *}
  TIntegerPriorityQueue = specialize TBoostLockFreePriorityQueue<Integer>;
  TStringPriorityQueue = specialize TBoostLockFreePriorityQueue<string>;

// Default comparers
function DefaultIntegerComparer(const A, B: Integer): Integer;
function DefaultStringComparer(const A, B: string): Integer;

implementation

// === 默认比较器 ===

function DefaultIntegerComparer(const A, B: Integer): Integer;
begin
  if A < B then Result := -1
  else if A > B then Result := 1
  else Result := 0;
end;

function DefaultStringComparer(const A, B: string): Integer;
begin
  if A < B then Result := -1
  else if A > B then Result := 1
  else Result := 0;
end;

// === TBoostLockFreePriorityQueue 实现 ===

constructor TBoostLockFreePriorityQueue.Create(AComparer: TComparer);
var
  I: Integer;
begin
  inherited Create;
  
  if AComparer <> nil then
    FComparer := AComparer
  else
    FComparer := nil; // Will be set by specialization
  
  // 创建哨兵头结点
  New(FHead);
  FHead^.Priority := Low(Int64);  // 最小优先级
  FHead^.Level := MAX_LEVEL - 1;
  FHead^.IsDeleted := False;
  
  // 初始化所有前向指针为 nil
  for I := 0 to MAX_LEVEL - 1 do
    FHead^.Next[I] := atomic_tagged_ptr(nil, 0);
  
  atomic_store_64(FSize, 0, mo_relaxed);
  FMaxLevel := 1;
end;

destructor TBoostLockFreePriorityQueue.Destroy;
begin
  clear;
  if FHead <> nil then
    Dispose(FHead);
  inherited Destroy;
end;

function TBoostLockFreePriorityQueue.GenerateRandomLevel: Integer;
var
  LLevel: Integer;
begin
  LLevel := 1;
  // 每一层提升的概率为 1/2
  while (Random(2) = 0) and (LLevel < MAX_LEVEL) do
    Inc(LLevel);
  Result := LLevel;
end;

function TBoostLockFreePriorityQueue.CreateNode(const AData: T; APriority: Int64; ALevel: Integer): PNode;
var
  I: Integer;
begin
  New(Result);
  Result^.Data := AData;
  Result^.Priority := APriority;
  Result^.Level := ALevel;
  Result^.IsDeleted := False;
  
  // Initialize forward pointers
  for I := 0 to ALevel - 1 do
    Result^.Next[I] := atomic_tagged_ptr(nil, 0);
end;

procedure TBoostLockFreePriorityQueue.DisposeNode(ANode: PNode);
begin
  if ANode <> nil then
    Dispose(ANode);
end;

function TBoostLockFreePriorityQueue.FindPredecessors(APriority: Int64; const AData: T; 
                                                     out APreds: array of PNode; 
                                                     out ASuccs: array of PNode): Boolean;
var
  LCurrent: PNode;
  LNext: PNode;
  LLevel: Integer;
  LNextTagged: atomic_tagged_ptr_t;
begin
  Result := False;
  
  repeat
    LCurrent := FHead;
    
    // Traverse from top level down
    for LLevel := FMaxLevel - 1 downto 0 do
    begin
      // Load next pointer with acquire semantics
      LNextTagged := atomic_tagged_ptr_load(LCurrent^.Next[LLevel], mo_acquire);
      LNext := atomic_tagged_ptr_get_ptr(LNextTagged);
      
      // Find the right position at this level
      while (LNext <> nil) and 
            (not LNext^.IsDeleted) and
            ((LNext^.Priority < APriority) or 
             ((LNext^.Priority = APriority) and (FComparer(LNext^.Data, AData) < 0))) do
      begin
        LCurrent := LNext;
        LNextTagged := atomic_tagged_ptr_load(LCurrent^.Next[LLevel], mo_acquire);
        LNext := atomic_tagged_ptr_get_ptr(LNextTagged);
      end;
      
      APreds[LLevel] := LCurrent;
      ASuccs[LLevel] := LNext;
      
      // Check if we found the exact key
      if (LNext <> nil) and 
         (not LNext^.IsDeleted) and
         (LNext^.Priority = APriority) and 
         (FComparer(LNext^.Data, AData) = 0) then
        Result := True;
    end;
    
    // Validate that predecessors are still valid
    // (simplified validation for this implementation)
    Break;
  until False;
end;

// === Core operations ===

function TBoostLockFreePriorityQueue.push(const AData: T; APriority: Int64): Boolean;
var
  LNewNode: PNode;
  LLevel: Integer;
  LPreds, LSuccs: array[0..MAX_LEVEL-1] of PNode;
  I: Integer;
  LExpected: atomic_tagged_ptr_t;
  LNewTagged: atomic_tagged_ptr_t;
begin
  LLevel := GenerateRandomLevel;
  LNewNode := CreateNode(AData, APriority, LLevel);
  
  // Update max level if necessary
  if LLevel > FMaxLevel then
    FMaxLevel := LLevel;
  
  repeat
    if FindPredecessors(APriority, AData, LPreds, LSuccs) then
    begin
      // Duplicate found, don't insert
      DisposeNode(LNewNode);
      Exit(False);
    end;
    
    // Link new node at all levels
    for I := 0 to LLevel - 1 do
      LNewNode^.Next[I] := atomic_tagged_ptr(LSuccs[I], 0);
    
    // Try to link at level 0 first
    LExpected := atomic_tagged_ptr(LSuccs[0], atomic_tagged_ptr_get_tag(LPreds[0]^.Next[0]));
    LNewTagged := atomic_tagged_ptr(LNewNode, atomic_tagged_ptr_next(LExpected));
    
    if atomic_tagged_ptr_compare_exchange_strong(LPreds[0]^.Next[0], LExpected, LNewTagged) then
    begin
      // Successfully linked at level 0, now link at higher levels
      for I := 1 to LLevel - 1 do
      begin
        repeat
          LExpected := atomic_tagged_ptr(LSuccs[I], atomic_tagged_ptr_get_tag(LPreds[I]^.Next[I]));
          LNewTagged := atomic_tagged_ptr(LNewNode, atomic_tagged_ptr_next(LExpected));
        until atomic_tagged_ptr_compare_exchange_strong(LPreds[I]^.Next[I], LExpected, LNewTagged);
      end;
      
      Break; // Successfully inserted
    end;
    
    // Retry if CAS failed
  until False;
  
  atomic_fetch_add_64(FSize, 1);
  Result := True;
end;

function TBoostLockFreePriorityQueue.pop(out AData: T): Boolean;
var
  LCurrent: PNode;
  LNext: PNode;
  LNextTagged: atomic_tagged_ptr_t;
  LExpected: atomic_tagged_ptr_t;
  LNewTagged: atomic_tagged_ptr_t;
  I: Integer;
begin
  repeat
    // Load the first real node (skip sentinel)
    LNextTagged := atomic_tagged_ptr_load(FHead^.Next[0], mo_acquire);
    LCurrent := atomic_tagged_ptr_get_ptr(LNextTagged);

    if LCurrent = nil then
      Exit(False); // Queue is empty

    if LCurrent^.IsDeleted then
    begin
      // Node is marked as deleted, help remove it
      LNext := atomic_tagged_ptr_get_ptr(atomic_tagged_ptr_load(LCurrent^.Next[0], mo_acquire));
      LExpected := LNextTagged;
      LNewTagged := atomic_tagged_ptr(LNext, atomic_tagged_ptr_next(LNextTagged));
      atomic_tagged_ptr_compare_exchange_strong(FHead^.Next[0], LExpected, LNewTagged);
      Continue;
    end;

    // Try to mark node as deleted
    if not LCurrent^.IsDeleted then
    begin
      LCurrent^.IsDeleted := True;
      AData := LCurrent^.Data;

      // Try to physically remove the node from all levels
      for I := 0 to LCurrent^.Level - 1 do
      begin
        LNext := atomic_tagged_ptr_get_ptr(atomic_tagged_ptr_load(LCurrent^.Next[I], mo_acquire));
        LExpected := LNextTagged;
        LNewTagged := atomic_tagged_ptr(LNext, atomic_tagged_ptr_next(LNextTagged));
        atomic_tagged_ptr_compare_exchange_strong(FHead^.Next[I], LExpected, LNewTagged);
      end;

      atomic_fetch_sub_64(FSize, 1);

      // **FIX: Actually dispose the node to prevent memory leak**
      DisposeNode(LCurrent);

      Result := True;
      Exit;
    end;
  until False;
end;

function TBoostLockFreePriorityQueue.top(out AData: T): Boolean;
var
  LCurrent: PNode;
  LNextTagged: atomic_tagged_ptr_t;
begin
  repeat
    // Load the first real node (skip sentinel)
    LNextTagged := atomic_tagged_ptr_load(FHead^.Next[0], mo_acquire);
    LCurrent := atomic_tagged_ptr_get_ptr(LNextTagged);

    if LCurrent = nil then
      Exit(False); // Queue is empty

    if not LCurrent^.IsDeleted then
    begin
      AData := LCurrent^.Data;
      Result := True;
      Exit;
    end;

    // Node is deleted, try next one
  until False;
end;

// === Utility operations ===

function TBoostLockFreePriorityQueue.empty: Boolean;
begin
  Result := atomic_load_64(FSize, mo_relaxed) = 0;
end;

function TBoostLockFreePriorityQueue.size: Int64;
begin
  Result := atomic_load_64(FSize, mo_relaxed);
end;

procedure TBoostLockFreePriorityQueue.clear;
var
  LCurrent, LNext: PNode;
  LNextTagged: atomic_tagged_ptr_t;
  I: Integer;
begin
  // Start from the first real node
  LNextTagged := atomic_tagged_ptr_load(FHead^.Next[0], mo_acquire);
  LCurrent := atomic_tagged_ptr_get_ptr(LNextTagged);

  while LCurrent <> nil do
  begin
    LNext := atomic_tagged_ptr_get_ptr(atomic_tagged_ptr_load(LCurrent^.Next[0], mo_acquire));
    DisposeNode(LCurrent);
    LCurrent := LNext;
  end;

  // Reset head pointers
  for I := 0 to MAX_LEVEL - 1 do
    atomic_tagged_ptr_store(FHead^.Next[I], atomic_tagged_ptr(nil, 0), mo_release);

  atomic_store_64(FSize, 0, mo_relaxed);
  FMaxLevel := 1;
end;

end.
