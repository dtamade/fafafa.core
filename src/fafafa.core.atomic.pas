unit fafafa.core.atomic;

{**
 * fafafa.core.atomic - C/C++ compatible atomic operations
 *
 * @desc Atomic operations module designed to be 100% compatible with C/C++ std::atomic
 *       Provides consistent interface, naming and semantics with C/C++
 *       Designed for porting C/C++ lock-free algorithms
 *
 * @author fafafa.collections5 team
 * @version 2.0.0
 * @since 2025-08-08
 *
 * @note Design goals:
 *       - 100% compatible with C/C++ std::atomic interface
 *       - Support all standard memory orders
 *       - Ready for porting Boost.Lockfree and other libraries
 *       - Can be used as standalone component in other projects
 *}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

type
  {**
   * C/C++ standard memory order enumeration
   *
   * @desc Defined exactly according to C++11 std::memory_order standard
   *}
  memory_order = (
    memory_order_relaxed,   // Weakest: only guarantees atomicity
    memory_order_consume,   // Consume: read-dependent synchronization (deprecated, maps to acquire)
    memory_order_acquire,   // Acquire: read operation synchronization point
    memory_order_release,   // Release: write operation synchronization point
    memory_order_acq_rel,   // Acquire-release: read-modify-write operations
    memory_order_seq_cst    // Sequential consistency: strongest ordering (default)
  );

  {**
   * Tagged Pointer - ABA problem solution
   *
   * @desc Packs pointer and version tag together for lock-free data structures
   *}
  tagged_ptr = record
  {$IFDEF CPU64}
    combined: UInt64;
  {$ELSE}
    ptr: Pointer;
    tag: UInt32;
  {$ENDIF}
  end;

  // Atomic flag for basic spin primitives (0 = clear, 1 = set)
  atomic_flag = record
    v: Int32;
  end;


// === C/C++ standard compatible atomic operation functions ===

// atomic_load - atomic read
function atomic_load(var obj: Int32; order: memory_order = memory_order_seq_cst): Int32; inline;
function atomic_load_64(var obj: Int64; order: memory_order = memory_order_seq_cst): Int64; inline;
function atomic_load_ptr(var obj: Pointer; order: memory_order = memory_order_seq_cst): Pointer; inline;

// atomic_store - atomic write
procedure atomic_store(var obj: Int32; desired: Int32; order: memory_order = memory_order_seq_cst); inline;
procedure atomic_store_64(var obj: Int64; desired: Int64; order: memory_order = memory_order_seq_cst); inline;
procedure atomic_store_ptr(var obj: Pointer; desired: Pointer; order: memory_order = memory_order_seq_cst); inline;

// atomic_exchange - atomic exchange
function atomic_exchange(var obj: Int32; desired: Int32; order: memory_order = memory_order_seq_cst): Int32; inline;
function atomic_exchange_64(var obj: Int64; desired: Int64; order: memory_order = memory_order_seq_cst): Int64; inline;
function atomic_exchange_ptr(var obj: Pointer; desired: Pointer; order: memory_order = memory_order_seq_cst): Pointer; inline;

// atomic_compare_exchange_strong - strong compare exchange
function atomic_compare_exchange_strong(var obj: Int32; var expected: Int32; desired: Int32;
  order: memory_order = memory_order_seq_cst): Boolean; inline;
function atomic_compare_exchange_strong_64(var obj: Int64; var expected: Int64; desired: Int64;
  order: memory_order = memory_order_seq_cst): Boolean; inline;
function atomic_compare_exchange_strong_ptr(var obj: Pointer; var expected: Pointer; desired: Pointer;
  order: memory_order = memory_order_seq_cst): Boolean; inline;

// atomic_compare_exchange_weak - weak compare exchange
function atomic_compare_exchange_weak(var obj: Int32; var expected: Int32; desired: Int32;
  order: memory_order = memory_order_seq_cst): Boolean; inline;
function atomic_compare_exchange_weak_64(var obj: Int64; var expected: Int64; desired: Int64;
  order: memory_order = memory_order_seq_cst): Boolean; inline;
function atomic_compare_exchange_weak_ptr(var obj: Pointer; var expected: Pointer; desired: Pointer;
  order: memory_order = memory_order_seq_cst): Boolean; inline;

// atomic_fetch_add - atomic addition
function atomic_fetch_add(var obj: Int32; arg: Int32; order: memory_order = memory_order_seq_cst): Int32; inline;

  // atomic_fetch_and/or/xor - bitwise RMW operations
  function atomic_fetch_and(var obj: Int32; arg: Int32; order: memory_order = memory_order_seq_cst): Int32; inline;
  function atomic_fetch_or(var obj: Int32; arg: Int32; order: memory_order = memory_order_seq_cst): Int32; inline;
  function atomic_fetch_xor(var obj: Int32; arg: Int32; order: memory_order = memory_order_seq_cst): Int32; inline;
  function atomic_fetch_and_64(var obj: Int64; arg: Int64; order: memory_order = memory_order_seq_cst): Int64; inline;
  function atomic_fetch_or_64(var obj: Int64; arg: Int64; order: memory_order = memory_order_seq_cst): Int64; inline;
  function atomic_fetch_xor_64(var obj: Int64; arg: Int64; order: memory_order = memory_order_seq_cst): Int64; inline;

  // pointer arithmetic (byte-based)
  function atomic_fetch_add_ptr_bytes(var obj: Pointer; byteOffset: PtrInt; order: memory_order = memory_order_seq_cst): Pointer; inline;
  function atomic_fetch_sub_ptr_bytes(var obj: Pointer; byteOffset: PtrInt; order: memory_order = memory_order_seq_cst): Pointer; inline;

  // atomic_flag primitives
  function atomic_flag_test_and_set(var flag: atomic_flag; order: memory_order = memory_order_seq_cst): Boolean; inline;
  procedure atomic_flag_clear(var flag: atomic_flag; order: memory_order = memory_order_seq_cst); inline;

  // lock-free capability queries
  function atomic_is_lock_free_32: Boolean; inline;
  function atomic_is_lock_free_64: Boolean; inline;
  function atomic_is_lock_free_ptr: Boolean; inline;

  // tagged_ptr additional ops
  function atomic_exchange_tagged_ptr(var obj: tagged_ptr; desired: tagged_ptr; order: memory_order = memory_order_seq_cst): tagged_ptr; inline;
  function atomic_compare_exchange_weak_tagged_ptr(var obj: tagged_ptr; var expected: tagged_ptr; desired: tagged_ptr; order: memory_order = memory_order_seq_cst): Boolean; inline;

  // optional compiler fence placeholder
  // procedure atomic_signal_fence(order: memory_order); inline;
function atomic_fetch_add_64(var obj: Int64; arg: Int64; order: memory_order = memory_order_seq_cst): Int64; inline;

// atomic_fetch_sub - atomic subtraction
function atomic_fetch_sub(var obj: Int32; arg: Int32; order: memory_order = memory_order_seq_cst): Int32; inline;
function atomic_fetch_sub_64(var obj: Int64; arg: Int64; order: memory_order = memory_order_seq_cst): Int64; inline;

// === Tagged Pointer specific operations ===
function atomic_load_tagged_ptr(var obj: tagged_ptr; order: memory_order = memory_order_seq_cst): tagged_ptr; inline;
procedure atomic_store_tagged_ptr(var obj: tagged_ptr; desired: tagged_ptr; order: memory_order = memory_order_seq_cst); inline;
function atomic_compare_exchange_strong_tagged_ptr(var obj: tagged_ptr; var expected: tagged_ptr; desired: tagged_ptr;
  order: memory_order = memory_order_seq_cst): Boolean; inline;

// === Memory barrier operations ===
procedure atomic_thread_fence(order: memory_order); inline;

// === Convenience functions (for compatibility with existing code) ===
function atomic_increment(var obj: Int32): Int32; inline;
function atomic_decrement(var obj: Int32): Int32; inline;
function atomic_increment_64(var obj: Int64): Int64; inline;
function atomic_decrement_64(var obj: Int64): Int64; inline;

// === Tagged Pointer helper functions ===
function make_tagged_ptr(ptr: Pointer; tag: {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF}): tagged_ptr; inline;
function get_ptr(const tp: tagged_ptr): Pointer; inline;
function get_tag(const tp: tagged_ptr): {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF}; inline;
function next_tag(const tp: tagged_ptr): {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF}; inline;

implementation

// === Memory barrier implementation ===

// Portable barrier fallback: define ReadWriteBarrier if not provided by RTL/CPU
{$if not declared(ReadWriteBarrier)}
procedure ReadWriteBarrier; inline;
begin
  {$if declared(System.MemoryBarrier)}
    System.MemoryBarrier;
  {$elseif declared(MemoryBarrier)}
    MemoryBarrier;
  {$else}
    // Fallback no-op; on strong memory models this may be acceptable for our use.
    // Platforms requiring a real fence should provide MemoryBarrier in RTL.
  {$endif}
end;
{$endif}


procedure atomic_thread_fence(order: memory_order);
begin
  case order of
    memory_order_relaxed: ; // No operation
    memory_order_consume,
    memory_order_acquire,
    memory_order_release,
    memory_order_acq_rel,
    memory_order_seq_cst: ReadWriteBarrier;
  end;
end;

// === 32-bit atomic operations implementation ===

function atomic_load(var obj: Int32; order: memory_order): Int32;
begin
  Result := obj;
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;

procedure atomic_store(var obj: Int32; desired: Int32; order: memory_order);
begin
  if order in [memory_order_release, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_release);
  obj := desired;
  if order = memory_order_seq_cst then
    atomic_thread_fence(memory_order_seq_cst);
end;

function atomic_exchange(var obj: Int32; desired: Int32; order: memory_order): Int32;
begin
  Result := InterlockedExchange(obj, desired);
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;

function atomic_compare_exchange_strong(var obj: Int32; var expected: Int32; desired: Int32; order: memory_order): Boolean;
var
  LOriginal: Int32;
begin
  LOriginal := InterlockedCompareExchange(obj, desired, expected);
  Result := LOriginal = expected;
  if not Result then
    expected := LOriginal;
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;

function atomic_compare_exchange_weak(var obj: Int32; var expected: Int32; desired: Int32; order: memory_order): Boolean;
begin
  // On x86/x64, weak and strong versions are the same
  Result := atomic_compare_exchange_strong(obj, expected, desired, order);
end;

function atomic_fetch_and(var obj: Int32; arg: Int32; order: memory_order): Int32;
var
  oldValue, newValue: Int32;
begin
  repeat
    oldValue := obj;
    newValue := oldValue and arg;
  until InterlockedCompareExchange(obj, newValue, oldValue) = oldValue;
  Result := oldValue;
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;

function atomic_fetch_or(var obj: Int32; arg: Int32; order: memory_order): Int32;
var
  oldValue, newValue: Int32;
begin
  repeat
    oldValue := obj;
    newValue := oldValue or arg;
  until InterlockedCompareExchange(obj, newValue, oldValue) = oldValue;
  Result := oldValue;
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;

function atomic_fetch_xor(var obj: Int32; arg: Int32; order: memory_order): Int32;
var
  oldValue, newValue: Int32;
begin
  repeat
    oldValue := obj;
    newValue := oldValue xor arg;
  until InterlockedCompareExchange(obj, newValue, oldValue) = oldValue;
  Result := oldValue;
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;


function atomic_fetch_add(var obj: Int32; arg: Int32; order: memory_order): Int32;
begin
  Result := InterlockedExchangeAdd(obj, arg);
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;

function atomic_fetch_and_64(var obj: Int64; arg: Int64; order: memory_order): Int64;
var
  oldValue, newValue: Int64;
begin
  repeat
    oldValue := obj;
    newValue := oldValue and arg;
  until InterlockedCompareExchange64(obj, newValue, oldValue) = oldValue;
  Result := oldValue;
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;

function atomic_fetch_or_64(var obj: Int64; arg: Int64; order: memory_order): Int64;
var
  oldValue, newValue: Int64;
begin
  repeat
    oldValue := obj;
    newValue := oldValue or arg;
  until InterlockedCompareExchange64(obj, newValue, oldValue) = oldValue;
  Result := oldValue;
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;

function atomic_fetch_xor_64(var obj: Int64; arg: Int64; order: memory_order): Int64;
var
  oldValue, newValue: Int64;
begin
  repeat
    oldValue := obj;
    newValue := oldValue xor arg;
  until InterlockedCompareExchange64(obj, newValue, oldValue) = oldValue;
  Result := oldValue;
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;


function atomic_fetch_sub(var obj: Int32; arg: Int32; order: memory_order): Int32;
begin
  Result := InterlockedExchangeAdd(obj, -arg);
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;

// === 64-bit atomic operations implementation ===

function atomic_load_64(var obj: Int64; order: memory_order): Int64;
begin
{$IFDEF CPU64}
  Result := obj;
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
{$ELSE}
  // On 32-bit systems, need atomic operation
  Result := InterlockedExchange64(obj, obj);
{$ENDIF}
end;

procedure atomic_store_64(var obj: Int64; desired: Int64; order: memory_order);
begin
{$IFDEF CPU64}
  if order in [memory_order_release, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_release);
  obj := desired;
  if order = memory_order_seq_cst then
    atomic_thread_fence(memory_order_seq_cst);
{$ELSE}
  InterlockedExchange64(obj, desired);
{$ENDIF}
end;

function atomic_exchange_64(var obj: Int64; desired: Int64; order: memory_order): Int64;
begin
  Result := InterlockedExchange64(obj, desired);
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;

function atomic_compare_exchange_strong_64(var obj: Int64; var expected: Int64; desired: Int64; order: memory_order): Boolean;
var
  LOriginal: Int64;
begin
  LOriginal := InterlockedCompareExchange64(obj, desired, expected);
  Result := LOriginal = expected;
  if not Result then
    expected := LOriginal;
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;

function atomic_compare_exchange_weak_64(var obj: Int64; var expected: Int64; desired: Int64; order: memory_order): Boolean;
begin
  Result := atomic_compare_exchange_strong_64(obj, expected, desired, order);
end;


{$PUSH}{$WARN 4055 OFF}

{$IFDEF CPU64}
function PtrAsI64(p: Pointer): Int64; inline; begin Result := Int64(PtrUInt(p)); end;
function I64AsPtr(v: Int64): Pointer; inline; begin Result := Pointer(PtrUInt(v)); end;
{$ELSE}
function PtrAsI32(p: Pointer): Longint; inline; begin Result := Longint(PtrUInt(p)); end;
function I32AsPtr(v: Longint): Pointer; inline; begin Result := Pointer(PtrUInt(v)); end;
{$ENDIF}
{$POP}


function atomic_fetch_add_64(var obj: Int64; arg: Int64; order: memory_order): Int64;
begin
  Result := InterlockedExchangeAdd64(obj, arg);
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;

function atomic_fetch_sub_64(var obj: Int64; arg: Int64; order: memory_order): Int64;
begin
  Result := InterlockedExchangeAdd64(obj, -arg);
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;

// === Pointer atomic operations implementation ===

function atomic_load_ptr(var obj: Pointer; order: memory_order): Pointer;
begin
{$IFDEF CPU64}
  Result := obj;
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
{$ELSE}
  // Use alias to perform an atomic read via Exchange on 32-bit
  Result := I32AsPtr(InterlockedExchange(PLongint(@obj)^, PLongint(@obj)^));
{$ENDIF}
end;

procedure atomic_store_ptr(var obj: Pointer; desired: Pointer; order: memory_order);
begin
{$IFDEF CPU64}
  if order in [memory_order_release, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_release);
  // Use atomic exchange to store the pointer value
  InterlockedExchange64(PInt64(@obj)^, PtrAsI64(desired));
  if order = memory_order_seq_cst then
    atomic_thread_fence(memory_order_seq_cst);
{$ELSE}
  InterlockedExchange(PLongint(@obj)^, PtrAsI32(desired));
{$ENDIF}
end;

function atomic_exchange_ptr(var obj: Pointer; desired: Pointer; order: memory_order): Pointer;
begin
{$IFDEF CPU64}
  Result := I64AsPtr(InterlockedExchange64(PInt64(@obj)^, PtrAsI64(desired)));
{$ELSE}
  Result := I32AsPtr(InterlockedExchange(PLongint(@obj)^, PtrAsI32(desired)));
{$ENDIF}
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;

function atomic_compare_exchange_strong_ptr(var obj: Pointer; var expected: Pointer; desired: Pointer; order: memory_order): Boolean;
var
  LOriginal: Pointer;
begin
{$IFDEF CPU64}
  LOriginal := I64AsPtr(InterlockedCompareExchange64(PInt64(@obj)^, PtrAsI64(desired), PtrAsI64(expected)));
{$ELSE}
  LOriginal := I32AsPtr(InterlockedCompareExchange(PLongint(@obj)^, PtrAsI32(desired), PtrAsI32(expected)));
{$ENDIF}
  Result := LOriginal = expected;
  if not Result then
    expected := LOriginal;
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;

function atomic_compare_exchange_weak_ptr(var obj: Pointer; var expected: Pointer; desired: Pointer; order: memory_order): Boolean;
begin
  Result := atomic_compare_exchange_strong_ptr(obj, expected, desired, order);
end;

function atomic_fetch_add_ptr_bytes(var obj: Pointer; byteOffset: PtrInt; order: memory_order): Pointer;
var
  expected, desired: Pointer;
begin
  repeat
    expected := atomic_load_ptr(obj, memory_order_relaxed);
    desired := Pointer(PtrUInt(expected) + PtrUInt(byteOffset));
  until atomic_compare_exchange_strong_ptr(obj, expected, desired, order);
  Result := expected;
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;

function atomic_fetch_sub_ptr_bytes(var obj: Pointer; byteOffset: PtrInt; order: memory_order): Pointer;
begin
  Result := atomic_fetch_add_ptr_bytes(obj, -byteOffset, order);
end;

function atomic_flag_test_and_set(var flag: atomic_flag; order: memory_order): Boolean;
var
  prev: Int32;
begin
  prev := InterlockedExchange(flag.v, 1);
  Result := prev <> 0;
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
end;

procedure atomic_flag_clear(var flag: atomic_flag; order: memory_order);
begin
  if order in [memory_order_release, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_release);
  InterlockedExchange(flag.v, 0);
  if order = memory_order_seq_cst then
    atomic_thread_fence(memory_order_seq_cst);
end;

function atomic_is_lock_free_32: Boolean;
begin
  Result := True;
end;

function atomic_is_lock_free_64: Boolean;
begin
  {$IFDEF CPU64}
  Result := True;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function atomic_is_lock_free_ptr: Boolean;
begin
  Result := True;
end;



function atomic_exchange_tagged_ptr(var obj: tagged_ptr; desired: tagged_ptr; order: memory_order): tagged_ptr;
begin
{$IFDEF CPU64}
  Result.combined := UInt64(InterlockedExchange64(PInt64(@obj.combined)^, Int64(desired.combined)));
  if order in [memory_order_acquire, memory_order_acq_rel, memory_order_seq_cst] then
    atomic_thread_fence(memory_order_acquire);
{$ELSE}
  // Simplified non-atomic fallback on 32-bit
  Result := obj;
  obj := desired;
{$ENDIF}
end;

function atomic_compare_exchange_weak_tagged_ptr(var obj: tagged_ptr; var expected: tagged_ptr; desired: tagged_ptr; order: memory_order): Boolean;
var
  LExpectedInt64, LDesiredInt64: Int64;
begin
{$IFDEF CPU64}
  LExpectedInt64 := Int64(expected.combined);
  LDesiredInt64 := Int64(desired.combined);
  Result := atomic_compare_exchange_strong_64(PInt64(@obj.combined)^, LExpectedInt64, LDesiredInt64, order);
  if not Result then
    expected.combined := UInt64(LExpectedInt64);
{$ELSE}
  Result := (obj.ptr = expected.ptr) and (obj.tag = expected.tag);
  if Result then obj := desired else expected := obj;
{$ENDIF}
end;


// === Tagged Pointer operations implementation ===

function atomic_load_tagged_ptr(var obj: tagged_ptr; order: memory_order): tagged_ptr;
begin
{$IFDEF CPU64}
  Result.combined := UInt64(atomic_load_64(PInt64(@obj.combined)^, order));
{$ELSE}
  // On 32-bit systems, need lock protection (simplified implementation)
  Result := obj;
{$ENDIF}
end;

procedure atomic_store_tagged_ptr(var obj: tagged_ptr; desired: tagged_ptr; order: memory_order);
begin
{$IFDEF CPU64}
  atomic_store_64(PInt64(@obj.combined)^, Int64(desired.combined), order);
{$ELSE}
  // On 32-bit systems, need lock protection (simplified implementation)
  obj := desired;
{$ENDIF}
end;

function atomic_compare_exchange_strong_tagged_ptr(var obj: tagged_ptr; var expected: tagged_ptr; desired: tagged_ptr; order: memory_order): Boolean;
var
  LExpectedInt64, LDesiredInt64: Int64;
begin
{$IFDEF CPU64}
  LExpectedInt64 := Int64(expected.combined);
  LDesiredInt64 := Int64(desired.combined);
  Result := atomic_compare_exchange_strong_64(PInt64(@obj.combined)^, LExpectedInt64, LDesiredInt64, order);
  if not Result then
    expected.combined := UInt64(LExpectedInt64);
{$ELSE}
  // On 32-bit systems, need lock protection (simplified implementation)
  Result := (obj.ptr = expected.ptr) and (obj.tag = expected.tag);
  if Result then
    obj := desired
  else
    expected := obj;
{$ENDIF}
end;

// === Convenience functions implementation ===

function atomic_increment(var obj: Int32): Int32;
begin
  Result := InterlockedIncrement(obj);
end;

function atomic_decrement(var obj: Int32): Int32;
begin
  Result := InterlockedDecrement(obj);
end;

function atomic_increment_64(var obj: Int64): Int64;
begin
  Result := InterlockedIncrement64(obj);
end;

function atomic_decrement_64(var obj: Int64): Int64;
begin
  Result := InterlockedDecrement64(obj);
end;

// === Tagged Pointer helper functions implementation ===

function make_tagged_ptr(ptr: Pointer; tag: {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF}): tagged_ptr;
begin
{$IFDEF CPU64}
  Result.combined := (UInt64(tag) shl 48) or (UInt64(PtrUInt(ptr)) and $0000FFFFFFFFFFFF);
{$ELSE}
  Result.ptr := ptr;
  Result.tag := tag;
{$ENDIF}
end;

function get_ptr(const tp: tagged_ptr): Pointer;
begin
{$IFDEF CPU64}
  Result := Pointer(PtrUInt(tp.combined and $0000FFFFFFFFFFFF));
{$ELSE}
  Result := tp.ptr;
{$ENDIF}
end;

function get_tag(const tp: tagged_ptr): {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};
begin
{$IFDEF CPU64}
  Result := UInt16(tp.combined shr 48);
{$ELSE}
  Result := tp.tag;
{$ENDIF}
end;

function next_tag(const tp: tagged_ptr): {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};
begin
{$IFDEF CPU64}
  Result := UInt16(get_tag(tp) + 1);
{$ELSE}
  Result := tp.tag + 1;
{$ENDIF}
end;

end.
