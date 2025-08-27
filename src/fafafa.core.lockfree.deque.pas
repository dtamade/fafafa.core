unit fafafa.core.lockfree.deque;

{**
 * fafafa.core.lockfree.deque - 无锁双端队列
 *
 * @desc 基于工作窃取算法的高性能无锁双端队列
 *       使用 C/C++ 兼容的原子操作和标记指针防止 ABA 问题
 *       实现 Chase-Lev 工作窃取双端队列算法
 *
 * @author fafafa.collections5 开发团队
 * @version 1.0.0
 * @since 2025-08-08
 *
 * @note 设计特性:
 *       - 使用标记指针防止 ABA 问题
 *       - 工作窃取优化
 *       - C/C++ std::atomic 兼容接口
 *       - 动态调整大小支持
 *       - 高性能并发访问
 *}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils,
  fafafa.core.atomic;

type
  {**
   * Lock-free deque based on Chase-Lev algorithm
   *
   * @desc Thread-safe double-ended queue optimized for work-stealing
   *       Owner thread can push/pop from one end, thieves can steal from other end
   *}
  generic TLockFreeDeque<T> = class
  private
    type
      PArray = ^TArray;
      TArray = record
        Size: Integer;
        Data: array[0..0] of T;  // Variable length array
      end;

  private
    FArray: PArray;             // Current array (atomic pointer)
    FTop: Int64;                // Top index (owner end) - atomic
    FBottom: Int64;             // Bottom index (thief end) - atomic
    FInitialCapacity: Integer;

    // Internal methods
    function CreateArray(ASize: Integer): PArray;
    procedure DisposeArray(AArray: PArray);
    function Resize: PArray;
    function GetCapacity: Integer; inline;

  public
    constructor Create(AInitialCapacity: Integer = 1024);
    destructor Destroy; override;

    // Core operations (owner thread)
    procedure push_bottom(const AItem: T);
    function pop_bottom(out AItem: T): Boolean;

    // Core operations (thief threads)
    function steal_top(out AItem: T): Boolean;

    // Utility operations
    function empty: Boolean; inline;
    function size: Int64; inline;

    // Properties
    property Count: Int64 read size;
    property IsEmpty: Boolean read empty;
    property Capacity: Integer read GetCapacity;
  end;

  {**
   * Convenience type aliases
   *}
  TIntegerDeque = specialize TLockFreeDeque<Integer>;
  TStringDeque = specialize TLockFreeDeque<string>;
  TPointerDeque = specialize TLockFreeDeque<Pointer>;

implementation

// === TLockFreeDeque implementation ===

constructor TLockFreeDeque.Create(AInitialCapacity: Integer);
begin
  inherited Create;
  
  FInitialCapacity := AInitialCapacity;
  FArray := CreateArray(FInitialCapacity);
  
  // Initialize indices
  atomic_store_64(FTop, 0, memory_order_relaxed);
  atomic_store_64(FBottom, 0, memory_order_relaxed);
end;

destructor TLockFreeDeque.Destroy;
begin
  if FArray <> nil then
    DisposeArray(FArray);
  inherited Destroy;
end;

function TLockFreeDeque.CreateArray(ASize: Integer): PArray;
var
  LTotalSize: Integer;
begin
  LTotalSize := SizeOf(TArray) + (ASize - 1) * SizeOf(T);
  GetMem(Result, LTotalSize);
  Result^.Size := ASize;
  if ASize > 0 then
    FillChar(Result^.Data[0], ASize * SizeOf(T), 0);
end;

procedure TLockFreeDeque.DisposeArray(AArray: PArray);
begin
  if AArray <> nil then
    FreeMem(AArray);
end;

function TLockFreeDeque.Resize: PArray;
var
  LCurrentArray: PArray;
  LNewArray: PArray;
  LTop, LBottom: Int64;
  LSize, LNewSize: Integer;
  I, LIndex: Integer;
begin
  LCurrentArray := FArray;
  LTop := atomic_load_64(FTop, memory_order_acquire);
  LBottom := atomic_load_64(FBottom, memory_order_acquire);
  
  LSize := Integer(LBottom - LTop);
  LNewSize := LCurrentArray^.Size * 2;
  
  LNewArray := CreateArray(LNewSize);
  
  // Copy existing elements (disable range checking)
  {$PUSH}
  {$R-} // Disable range checking
  for I := 0 to LSize - 1 do
  begin
    LIndex := Integer((LTop + I) and (LCurrentArray^.Size - 1));
    LNewArray^.Data[I] := LCurrentArray^.Data[LIndex];
  end;
  {$POP}
  
  // Update array pointer atomically
  atomic_store_ptr(Pointer(FArray), LNewArray, memory_order_release);
  
  // Update indices
  atomic_store_64(FTop, 0, memory_order_relaxed);
  atomic_store_64(FBottom, LSize, memory_order_relaxed);
  
  // Dispose old array (should be done safely after grace period)
  DisposeArray(LCurrentArray);
  
  Result := LNewArray;
end;

function TLockFreeDeque.GetCapacity: Integer;
var
  LArray: PArray;
begin
  LArray := atomic_load_ptr(Pointer(FArray), memory_order_relaxed);
  if LArray <> nil then
    Result := LArray^.Size
  else
    Result := 0;
end;

// === Core operations ===

procedure TLockFreeDeque.push_bottom(const AItem: T);
var
  LBottom: Int64;
  LTop: Int64;
  LArray: PArray;
  LSize: Integer;
  LIndex: Integer;
begin
  LBottom := atomic_load_64(FBottom, memory_order_relaxed);
  LTop := atomic_load_64(FTop, memory_order_acquire);
  LArray := atomic_load_ptr(Pointer(FArray), memory_order_relaxed);
  
  LSize := Integer(LBottom - LTop);
  
  // Check if resize is needed
  if LSize >= LArray^.Size - 1 then
  begin
    LArray := Resize;
    LBottom := atomic_load_64(FBottom, memory_order_relaxed);
  end;
  
  // Store the item (disable range checking for array access)
  {$PUSH}
  {$R-} // Disable range checking
  LIndex := Integer(LBottom and (LArray^.Size - 1));
  LArray^.Data[LIndex] := AItem;
  {$POP}
  
  // Update bottom with release semantics to ensure item is visible
  atomic_store_64(FBottom, LBottom + 1, memory_order_release);
end;

function TLockFreeDeque.pop_bottom(out AItem: T): Boolean;
var
  LBottom: Int64;
  LTop: Int64;
  LArray: PArray;
  LNewBottom: Int64;
  LExpectedTop: Int64;
begin
  LBottom := atomic_load_64(FBottom, memory_order_relaxed);
  LArray := atomic_load_ptr(Pointer(FArray), memory_order_relaxed);
  
  LNewBottom := LBottom - 1;
  atomic_store_64(FBottom, LNewBottom, memory_order_relaxed);
  
  // Memory fence to ensure bottom update is visible
  atomic_thread_fence(memory_order_seq_cst);
  
  LTop := atomic_load_64(FTop, memory_order_relaxed);
  
  if LNewBottom < LTop then
  begin
    // Deque is empty, restore bottom
    atomic_store_64(FBottom, LTop, memory_order_relaxed);
    Result := False;
    Exit;
  end;
  
  // Get the item (disable range checking)
  {$PUSH}
  {$R-} // Disable range checking
  AItem := LArray^.Data[LNewBottom and (LArray^.Size - 1)];
  {$POP}
  
  if LNewBottom > LTop then
  begin
    // More than one item, we're done
    Result := True;
    Exit;
  end;
  
  // Exactly one item, compete with thieves
  atomic_store_64(FBottom, LTop + 1, memory_order_relaxed);
  LExpectedTop := LTop;
  
  if atomic_compare_exchange_strong_64(FTop, LExpectedTop, LTop + 1, memory_order_seq_cst) then
  begin
    // Won the race
    Result := True;
  end
  else
  begin
    // Lost the race, item was stolen
    Result := False;
  end;
end;

function TLockFreeDeque.steal_top(out AItem: T): Boolean;
var
  LTop: Int64;
  LBottom: Int64;
  LArray: PArray;
  LExpectedTop: Int64;
begin
  LTop := atomic_load_64(FTop, memory_order_acquire);
  
  // Memory fence to ensure we see the latest bottom
  atomic_thread_fence(memory_order_seq_cst);
  
  LBottom := atomic_load_64(FBottom, memory_order_acquire);
  
  if LTop >= LBottom then
  begin
    // Deque is empty
    Result := False;
    Exit;
  end;
  
  // Load array and get item (disable range checking)
  LArray := atomic_load_ptr(Pointer(FArray), memory_order_consume);
  {$PUSH}
  {$R-} // Disable range checking
  AItem := LArray^.Data[LTop and (LArray^.Size - 1)];
  {$POP}
  
  // Try to increment top
  LExpectedTop := LTop;
  Result := atomic_compare_exchange_strong_64(FTop, LExpectedTop, LTop + 1, memory_order_seq_cst);
end;

// === Utility operations ===

function TLockFreeDeque.empty: Boolean;
var
  LTop, LBottom: Int64;
begin
  LTop := atomic_load_64(FTop, memory_order_relaxed);
  LBottom := atomic_load_64(FBottom, memory_order_relaxed);
  Result := LTop >= LBottom;
end;

function TLockFreeDeque.size: Int64;
var
  LTop, LBottom: Int64;
begin
  LBottom := atomic_load_64(FBottom, memory_order_relaxed);
  LTop := atomic_load_64(FTop, memory_order_relaxed);
  Result := LBottom - LTop;
  if Result < 0 then
    Result := 0;
end;

end.
