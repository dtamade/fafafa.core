unit fafafa.core.lockfree.ringBuffer;

{**
 * fafafa.core.lockfree.ringBuffer - 高性能无锁环形缓冲区
 *
 * @desc 针对单生产者/单消费者优化的无锁环形缓冲区
 *       使用 C/C++ 兼容的原子操作和精确的内存序
 *       基于 Disruptor 模式的内存高效设计
 *
 * @author fafafa.collections5 开发团队
 * @version 1.0.0
 * @since 2025-08-08
 *
 * @note 设计特性:
 *       - 单生产者/单消费者优化
 *       - 缓存行对齐提升性能
 *       - C/C++ std::atomic 兼容接口
 *       - 精确的内存序语义
 *       - 尽可能零拷贝操作
 *}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  fafafa.core.atomic;

const
  CACHE_LINE_SIZE = 64;  // Typical cache line size

type
  {**
   * Cache-aligned atomic counter
   *}
  TCacheAlignedCounter = record
    Value: Int64;
    {$IFDEF FAFAFA_LOCKFREE_CACHELINE_PAD}
    Padding: array[0..CACHE_LINE_SIZE - SizeOf(Int64) - 1] of Byte;
    {$ENDIF}
  end;

  {**
   * Lock-free ring buffer entry
   *}
  generic TRingBufferEntry<T> = record
    Data: T;
    Sequence: Int64;  // Sequence number for ordering
  end;

  {**
   * High-performance lock-free ring buffer
   *
   * @desc Optimized for single producer/single consumer scenarios
   *       Uses sequence numbers and memory barriers for synchronization
   *}
  generic TLockFreeRingBuffer<T> = class
  public
    type
      PEntry = ^TEntry;
      TEntry = specialize TRingBufferEntry<T>;

  private
    FBuffer: array of TEntry;       // Ring buffer entries
    FCapacity: Integer;             // Buffer capacity (power of 2)
    FMask: Integer;                 // Capacity - 1 (for fast modulo)
    
    // Cache-aligned counters to avoid false sharing
    FProducerSequence: TCacheAlignedCounter;  // Producer sequence
    FConsumerSequence: TCacheAlignedCounter;  // Consumer sequence
    FCachedConsumerSequence: TCacheAlignedCounter;  // Cached consumer sequence for producer
    FCachedProducerSequence: TCacheAlignedCounter;  // Cached producer sequence for consumer

    // Internal methods
    function IsPowerOfTwo(AValue: Integer): Boolean; inline;
    function NextPowerOfTwo(AValue: Integer): Integer;
    procedure InitializeBuffer;

  public
    constructor Create(ACapacity: Integer = 1024);
    destructor Destroy; override;

    // Core operations (producer side)
    function try_enqueue(const AItem: T): Boolean;
    function enqueue(const AItem: T): Boolean;  // Blocking version

    // Core operations (consumer side)
    function try_dequeue(out AItem: T): Boolean;
    function dequeue(out AItem: T): Boolean;    // Blocking version

    // Utility operations
    function empty: Boolean; inline;
    function full: Boolean; inline;
    function size: Int64; inline;
    function get_capacity: Integer; inline;

    // Properties
    property Count: Int64 read size;
    property IsEmpty: Boolean read empty;
    property IsFull: Boolean read full;
    property Capacity: Integer read get_capacity;
  end;

  {**
   * Convenience type aliases
   *}
  TIntegerRingBuffer = specialize TLockFreeRingBuffer<Integer>;
  TStringRingBuffer = specialize TLockFreeRingBuffer<string>;
  TPointerRingBuffer = specialize TLockFreeRingBuffer<Pointer>;

implementation

// === TLockFreeRingBuffer implementation ===

constructor TLockFreeRingBuffer.Create(ACapacity: Integer);
begin
  inherited Create;
  
  // Ensure capacity is power of 2 for efficient modulo operation
  if not IsPowerOfTwo(ACapacity) then
    ACapacity := NextPowerOfTwo(ACapacity);
  
  FCapacity := ACapacity;
  FMask := FCapacity - 1;
  
  SetLength(FBuffer, FCapacity);
  InitializeBuffer;
  
  // Initialize sequences
  atomic_store_64(FProducerSequence.Value, 0, mo_relaxed);
  atomic_store_64(FConsumerSequence.Value, 0, mo_relaxed);
  atomic_store_64(FCachedConsumerSequence.Value, 0, mo_relaxed);
  atomic_store_64(FCachedProducerSequence.Value, 0, mo_relaxed);
end;

destructor TLockFreeRingBuffer.Destroy;
begin
  inherited Destroy;
end;

function TLockFreeRingBuffer.IsPowerOfTwo(AValue: Integer): Boolean;
begin
  Result := (AValue > 0) and ((AValue and (AValue - 1)) = 0);
end;

function TLockFreeRingBuffer.NextPowerOfTwo(AValue: Integer): Integer;
begin
  Result := 1;
  while Result < AValue do
    Result := Result shl 1;
end;

procedure TLockFreeRingBuffer.InitializeBuffer;
var
  I: Integer;
begin
  for I := 0 to FCapacity - 1 do
  begin
    FillChar(FBuffer[I].Data, SizeOf(T), 0);
    atomic_store_64(FBuffer[I].Sequence, I, mo_relaxed);
  end;
end;

// === Core operations (producer side) ===

function TLockFreeRingBuffer.try_enqueue(const AItem: T): Boolean;
var
  LProducerSeq: Int64;
  LConsumerSeq: Int64;
  LCachedConsumerSeq: Int64;
  LIndex: Integer;
  LEntry: PEntry;
  LExpectedSeq: Int64;
begin
  LProducerSeq := atomic_load_64(FProducerSequence.Value, mo_relaxed);
  LIndex := LProducerSeq and FMask;
  LEntry := @FBuffer[LIndex];
  
  // Check if slot is available
  LExpectedSeq := LProducerSeq;
  if atomic_load_64(LEntry^.Sequence, mo_acquire) <> LExpectedSeq then
  begin
    // Slot not available, check if buffer is full
    LCachedConsumerSeq := atomic_load_64(FCachedConsumerSequence.Value, mo_relaxed);
    
    if LProducerSeq - LCachedConsumerSeq >= FCapacity then
    begin
      // Update cached consumer sequence
      LConsumerSeq := atomic_load_64(FConsumerSequence.Value, mo_acquire);
      atomic_store_64(FCachedConsumerSequence.Value, LConsumerSeq, mo_relaxed);
      
      if LProducerSeq - LConsumerSeq >= FCapacity then
        Exit(False); // Buffer is full
    end
    else
      Exit(False); // Slot not ready
  end;
  
  // Store data
  LEntry^.Data := AItem;
  
  // Release the slot with release semantics
  atomic_store_64(LEntry^.Sequence, LProducerSeq + 1, mo_release);

  // Advance producer sequence
  atomic_store_64(FProducerSequence.Value, LProducerSeq + 1, mo_relaxed);
  
  Result := True;
end;

function TLockFreeRingBuffer.enqueue(const AItem: T): Boolean;
begin
  // Blocking version - keep trying until successful
  while not try_enqueue(AItem) do
  begin
    // Could add yield or sleep here for better CPU usage
    // For now, just busy wait
  end;
  Result := True;
end;

// === Core operations (consumer side) ===

function TLockFreeRingBuffer.try_dequeue(out AItem: T): Boolean;
var
  LConsumerSeq: Int64;
  LProducerSeq: Int64;
  LCachedProducerSeq: Int64;
  LIndex: Integer;
  LEntry: PEntry;
  LExpectedSeq: Int64;
begin
  LConsumerSeq := atomic_load_64(FConsumerSequence.Value, mo_relaxed);
  LIndex := LConsumerSeq and FMask;
  LEntry := @FBuffer[LIndex];
  
  // Check if data is available
  LExpectedSeq := LConsumerSeq + 1;
  if atomic_load_64(LEntry^.Sequence, mo_acquire) <> LExpectedSeq then
  begin
    // Data not available, check if buffer is empty
    LCachedProducerSeq := atomic_load_64(FCachedProducerSequence.Value, mo_relaxed);

    if LConsumerSeq >= LCachedProducerSeq then
    begin
      // Update cached producer sequence
      LProducerSeq := atomic_load_64(FProducerSequence.Value, mo_acquire);
      atomic_store_64(FCachedProducerSequence.Value, LProducerSeq, mo_relaxed);
      
      if LConsumerSeq >= LProducerSeq then
        Exit(False); // Buffer is empty
    end
    else
      Exit(False); // Data not ready
  end;
  
  // Read data
  AItem := LEntry^.Data;
  
  // Release the slot with release semantics
  atomic_store_64(LEntry^.Sequence, LConsumerSeq + FCapacity, mo_release);
  
  // Advance consumer sequence
  atomic_store_64(FConsumerSequence.Value, LConsumerSeq + 1, mo_relaxed);
  
  Result := True;
end;

function TLockFreeRingBuffer.dequeue(out AItem: T): Boolean;
begin
  // Blocking version - keep trying until successful
  while not try_dequeue(AItem) do
  begin
    // Could add yield or sleep here for better CPU usage
    // For now, just busy wait
  end;
  Result := True;
end;

// === Utility operations ===

function TLockFreeRingBuffer.empty: Boolean;
var
  LProducerSeq, LConsumerSeq: Int64;
begin
  LConsumerSeq := atomic_load_64(FConsumerSequence.Value, mo_relaxed);
  LProducerSeq := atomic_load_64(FProducerSequence.Value, mo_relaxed);
  Result := LConsumerSeq >= LProducerSeq;
end;

function TLockFreeRingBuffer.full: Boolean;
var
  LProducerSeq, LConsumerSeq: Int64;
begin
  LProducerSeq := atomic_load_64(FProducerSequence.Value, mo_relaxed);
  LConsumerSeq := atomic_load_64(FConsumerSequence.Value, mo_relaxed);
  Result := (LProducerSeq - LConsumerSeq) >= FCapacity;
end;

function TLockFreeRingBuffer.size: Int64;
var
  LProducerSeq, LConsumerSeq: Int64;
begin
  LProducerSeq := atomic_load_64(FProducerSequence.Value, mo_relaxed);
  LConsumerSeq := atomic_load_64(FConsumerSequence.Value, mo_relaxed);
  Result := LProducerSeq - LConsumerSeq;
  if Result < 0 then
    Result := 0;
end;

function TLockFreeRingBuffer.get_capacity: Integer;
begin
  Result := FCapacity;
end;

end.
