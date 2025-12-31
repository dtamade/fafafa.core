unit fafafa.core.atomic;

{
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│          ______   ______     ______   ______     ______   ______             │
│         /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \            │
│         \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \           │
│          \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\          │
│           \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/          │
│                                                                              │
│                                   Studio                                     │
└──────────────────────────────────────────────────────────────────────────────┘

📦 项目：fafafa.core.atomic - 高性能原子操作实现
────────────────────────────────────────────────────────────────────────────────
📖 概述：
  现代化、跨平台的 FreePascal 原子操作（C++ API 外观）实现。
────────────────────────────────────────────────────────────────────────────────
🔧 特性：
  • 跨平台支持：Windows、Linux、macOS、FreeBSD 等
  • 高性能实现：使用平台原生原子指令优化
  • 无锁设计：避免传统锁的开销和竞争
  • 内存序控制：支持多种内存排序语义
  • 类型安全：泛型封装确保类型一致性
  • CAS 操作：Compare-And-Swap 原语支持
  • 移植友好：支持 Windows、Linux、macOS、FreeBSD 等平台
────────────────────────────────────────────────────────────────────────────────
⚠️ 重要说明：
  原子操作仅保证单个操作的原子性，复合操作仍需要额外的同步机制。
  请根据具体场景选择合适的内存序语义以确保正确性。
────────────────────────────────────────────────────────────────────────────────
🧵 线程安全性：
  所有原子操作都是线程安全的，可以从多个线程同时调用。
────────────────────────────────────────────────────────────────────────────────
📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。
────────────────────────────────────────────────────────────────────────────────
👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731

}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

// fafafa.core.atomic
// Tagged pointer: tag bits (low-bit tagging mode)
{$IFNDEF FAFAFA_ATOMIC_TAG_BITS_32}
  {$DEFINE FAFAFA_ATOMIC_TAG_BITS_32 := 2}
{$ENDIF}
{$IFNDEF FAFAFA_ATOMIC_TAG_BITS_64}
  {$DEFINE FAFAFA_ATOMIC_TAG_BITS_64 := 3}
{$ENDIF}

// Enable extra runtime checks for tagged pointer packing (debug only)
{$IFDEF DEBUG}
  {$DEFINE FAFAFA_ATOMIC_TAGGED_PTR_CHECKS}
{$ENDIF}

interface

type

  memory_order_t = (
    mo_relaxed,   // 只保证原子性
    mo_consume,   // 当前实现：等价 mo_acquire（更强；跨平台一致性）
    mo_acquire,   // acquire 语义
    mo_release,   // store 用
    mo_acq_rel,   // RMW 用，load 部分当 acquire
    mo_seq_cst    // 最强顺序
  );

// cpu_pause: self-spin hint (PAUSE/YIELD/no-op), useful for CAS loops.
procedure cpu_pause;

//┌────────────────────────────────────────────────────────────────────────────┐
//│                                atomic_load                                 │
//└────────────────────────────────────────────────────────────────────────────┘

function atomic_load(var aObj: Int32; aOrder: memory_order_t): Int32; overload; inline;
function atomic_load(var aObj: Int32): Int32; overload; inline;

function atomic_load(var aObj: UInt32; aOrder: memory_order_t): UInt32; overload; inline;
function atomic_load(var aObj: UInt32): UInt32; overload; inline;

{$IFDEF CPU64}
function atomic_load(var aObj: PtrUInt; aOrder: memory_order_t): PtrUInt; overload; inline;
function atomic_load(var aObj: PtrUInt): PtrUInt; overload; inline;

function atomic_load(var aObj: PtrInt; aOrder: memory_order_t): PtrInt; overload; inline;
function atomic_load(var aObj: PtrInt): PtrInt; overload; inline;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_load_64(var aObj: Int64; aOrder: memory_order_t): Int64; overload; inline;
function atomic_load_64(var aObj: Int64): Int64; overload; inline;

function atomic_load_64(var aObj: UInt64; aOrder: memory_order_t): UInt64; overload; inline;
function atomic_load_64(var aObj: UInt64): UInt64; overload; inline;
{$ENDIF}

function atomic_load(var aObj: Pointer; aOrder: memory_order_t): Pointer; overload; inline;
function atomic_load(var aObj: Pointer): Pointer; overload; inline;

function atomic_load_ptr(var aObj: Pointer; aOrder: memory_order_t): Pointer; overload; inline;
function atomic_load_ptr(var aObj: Pointer): Pointer; overload; inline;

//┌────────────────────────────────────────────────────────────────────────────┐
//│                                atomic_store                                │
//└────────────────────────────────────────────────────────────────────────────┘

procedure atomic_store(var aObj: Int32; aDesired: Int32; aOrder: memory_order_t); overload; inline;
procedure atomic_store(var aObj: Int32; aDesired: Int32); overload; inline;

procedure atomic_store(var aObj: UInt32; aDesired: UInt32; aOrder: memory_order_t); overload; inline;
procedure atomic_store(var aObj: UInt32; aDesired: UInt32); overload; inline;

{$IFDEF CPU64}
procedure atomic_store(var aObj: PtrInt; aDesired: PtrInt; aOrder: memory_order_t); overload; inline;
procedure atomic_store(var aObj: PtrInt; aDesired: PtrInt); overload; inline;

procedure atomic_store(var aObj: PtrUInt; aDesired: PtrUInt; aOrder: memory_order_t); overload; inline;
procedure atomic_store(var aObj: PtrUInt; aDesired: PtrUInt); overload; inline;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
procedure atomic_store_64(var aObj: Int64; aDesired: Int64; aOrder: memory_order_t); overload; inline;
procedure atomic_store_64(var aObj: Int64; aDesired: Int64); overload; inline;

procedure atomic_store_64(var aObj: UInt64; aDesired: UInt64; aOrder: memory_order_t); overload; inline;
procedure atomic_store_64(var aObj: UInt64; aDesired: UInt64); overload; inline;
{$ENDIF}

procedure atomic_store(var aObj: Pointer; aDesired: Pointer; aOrder: memory_order_t); overload; inline;
procedure atomic_store(var aObj: Pointer; aDesired: Pointer); overload; inline;

procedure atomic_store_ptr(var aObj: Pointer; aDesired: Pointer; aOrder: memory_order_t); overload; inline;
procedure atomic_store_ptr(var aObj: Pointer; aDesired: Pointer); overload; inline;

//┌────────────────────────────────────────────────────────────────────────────┐
//│                              atomic_exchange                               │
//└────────────────────────────────────────────────────────────────────────────┘

// ✅ Phase 3: 添加 memory_order 参数版本
function atomic_exchange(var aObj: Int32; aDesired: Int32; aOrder: memory_order_t): Int32; overload; inline;
function atomic_exchange(var aObj: Int32; aDesired: Int32): Int32; overload; inline;
function atomic_exchange(var aObj: UInt32; aDesired: UInt32; aOrder: memory_order_t): UInt32; overload; inline;
function atomic_exchange(var aObj: UInt32; aDesired: UInt32): UInt32; overload; inline;

{$IFDEF CPU64}
function atomic_exchange(var aObj: PtrInt; aDesired: PtrInt; aOrder: memory_order_t): PtrInt; overload; inline;
function atomic_exchange(var aObj: PtrInt; aDesired: PtrInt): PtrInt; overload; inline;
function atomic_exchange(var aObj: PtrUInt; aDesired: PtrUInt; aOrder: memory_order_t): PtrUInt; overload; inline;
function atomic_exchange(var aObj: PtrUInt; aDesired: PtrUInt): PtrUInt; overload; inline;
{$ENDIF}
{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_exchange_64(var aObj: Int64; aDesired: Int64; aOrder: memory_order_t): Int64; overload; inline;
function atomic_exchange_64(var aObj: Int64; aDesired: Int64): Int64; overload; inline;
function atomic_exchange_64(var aObj: UInt64; aDesired: UInt64; aOrder: memory_order_t): UInt64; overload; inline;
function atomic_exchange_64(var aObj: UInt64; aDesired: UInt64): UInt64; overload; inline;
{$ENDIF}
function atomic_exchange(var aObj: Pointer; aDesired: Pointer; aOrder: memory_order_t): Pointer; overload; inline;
function atomic_exchange(var aObj: Pointer; aDesired: Pointer): Pointer; overload; inline;

//┌────────────────────────────────────────────────────────────────────────────┐
//│                          atomic_compare_exchange                           │
//└────────────────────────────────────────────────────────────────────────────┘

function atomic_compare_exchange(var aObj: Int32; var aExpected: Int32; aDesired: Int32): Boolean; overload; inline;
function atomic_compare_exchange(var aObj: UInt32; var aExpected: UInt32; aDesired: UInt32): Boolean; overload; inline;

{$IFDEF CPU64}
function atomic_compare_exchange(var aObj: PtrInt; var aExpected: PtrInt; aDesired: PtrInt): Boolean; overload; inline;
function atomic_compare_exchange(var aObj: PtrUInt; var aExpected: PtrUInt; aDesired: PtrUInt): Boolean; overload; inline;
{$ENDIF}
{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_compare_exchange_64(var aObj: Int64; var aExpected: Int64; aDesired: Int64): Boolean; overload; inline;
function atomic_compare_exchange_64(var aObj: UInt64; var aExpected: UInt64; aDesired: UInt64): Boolean; overload; inline;
{$ENDIF}
function atomic_compare_exchange(var aObj: Pointer; var aExpected: Pointer; aDesired: Pointer): Boolean; overload; inline;

function atomic_compare_exchange_strong(var aObj: Int32; var aExpected: Int32; aDesired: Int32): Boolean; overload; inline;
function atomic_compare_exchange_strong(var aObj: UInt32; var aExpected: UInt32; aDesired: UInt32): Boolean; overload; inline;
{$IFDEF CPU64}
function atomic_compare_exchange_strong(var aObj: PtrInt; var aExpected: PtrInt; aDesired: PtrInt): Boolean; overload; inline;
function atomic_compare_exchange_strong(var aObj: PtrUInt; var aExpected: PtrUInt; aDesired: PtrUInt): Boolean; overload; inline;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_compare_exchange_strong_64(var aObj: Int64; var aExpected: Int64; aDesired: Int64): Boolean; overload; inline;
function atomic_compare_exchange_strong_64(var aObj: UInt64; var aExpected: UInt64; aDesired: UInt64): Boolean; overload; inline;
{$ENDIF}

function atomic_compare_exchange_strong(var aObj: Pointer; var aExpected: Pointer; aDesired: Pointer): Boolean; overload; inline;
function atomic_compare_exchange_strong_ptr(var aObj: Pointer; var aExpected: Pointer; aDesired: Pointer): Boolean; inline;

function atomic_compare_exchange_weak(var aObj: Int32; var aExpected: Int32; aDesired: Int32): Boolean; overload; inline;
function atomic_compare_exchange_weak(var aObj: UInt32; var aExpected: UInt32; aDesired: UInt32): Boolean; overload; inline;

{$IFDEF CPU64}
function atomic_compare_exchange_weak(var aObj: PtrInt; var aExpected: PtrInt; aDesired: PtrInt): Boolean; overload; inline;
function atomic_compare_exchange_weak(var aObj: PtrUInt; var aExpected: PtrUInt; aDesired: PtrUInt): Boolean; overload; inline;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_compare_exchange_weak_64(var aObj: Int64; var aExpected: Int64; aDesired: Int64): Boolean; overload; inline;
function atomic_compare_exchange_weak_64(var aObj: UInt64; var aExpected: UInt64; aDesired: UInt64): Boolean; overload; inline;
{$ENDIF}
function atomic_compare_exchange_weak(var aObj: Pointer; var aExpected: Pointer; aDesired: Pointer): Boolean; overload; inline;

// ✅ Phase 3: CAS 带双内存序参数 (success_order, failure_order) - 对齐 C++11/Rust API
function atomic_compare_exchange_strong(var aObj: Int32; var aExpected: Int32; aDesired: Int32;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean; overload; inline;
function atomic_compare_exchange_strong(var aObj: UInt32; var aExpected: UInt32; aDesired: UInt32;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean; overload; inline;
{$IFDEF CPU64}
function atomic_compare_exchange_strong(var aObj: PtrInt; var aExpected: PtrInt; aDesired: PtrInt;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean; overload; inline;
function atomic_compare_exchange_strong(var aObj: PtrUInt; var aExpected: PtrUInt; aDesired: PtrUInt;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean; overload; inline;
{$ENDIF}
{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_compare_exchange_strong_64(var aObj: Int64; var aExpected: Int64; aDesired: Int64;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean; overload; inline;
function atomic_compare_exchange_strong_64(var aObj: UInt64; var aExpected: UInt64; aDesired: UInt64;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean; overload; inline;
{$ENDIF}
function atomic_compare_exchange_strong(var aObj: Pointer; var aExpected: Pointer; aDesired: Pointer;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean; overload; inline;

function atomic_compare_exchange_weak(var aObj: Int32; var aExpected: Int32; aDesired: Int32;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean; overload; inline;
function atomic_compare_exchange_weak(var aObj: UInt32; var aExpected: UInt32; aDesired: UInt32;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean; overload; inline;
{$IFDEF CPU64}
function atomic_compare_exchange_weak(var aObj: PtrInt; var aExpected: PtrInt; aDesired: PtrInt;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean; overload; inline;
function atomic_compare_exchange_weak(var aObj: PtrUInt; var aExpected: PtrUInt; aDesired: PtrUInt;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean; overload; inline;
{$ENDIF}
{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_compare_exchange_weak_64(var aObj: Int64; var aExpected: Int64; aDesired: Int64;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean; overload; inline;
function atomic_compare_exchange_weak_64(var aObj: UInt64; var aExpected: UInt64; aDesired: UInt64;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean; overload; inline;
{$ENDIF}
function atomic_compare_exchange_weak(var aObj: Pointer; var aExpected: Pointer; aDesired: Pointer;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean; overload; inline;

//┌────────────────────────────────────────────────────────────────────────────┐
//│                              atomic_increment                              │
//└────────────────────────────────────────────────────────────────────────────┘

function atomic_increment(var aObj: Int32): Int32; overload; inline;
function atomic_increment(var aObj: UInt32): UInt32; overload; inline;
{$IFDEF CPU64}
function atomic_increment(var aObj: PtrInt): PtrInt; overload; inline;
function atomic_increment(var aObj: PtrUInt): PtrUInt; overload; inline;
{$ENDIF}
{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_increment_64(var aObj: Int64): Int64; overload; inline;
function atomic_increment_64(var aObj: UInt64): UInt64; overload; inline;
{$ENDIF}

//┌────────────────────────────────────────────────────────────────────────────┐
//│                              atomic_decrement                              │
//└────────────────────────────────────────────────────────────────────────────┘

function atomic_decrement(var aObj: Int32): Int32; overload; inline;
function atomic_decrement(var aObj: UInt32): UInt32; overload; inline;
{$IFDEF CPU64}
function atomic_decrement(var aObj: PtrInt): PtrInt; overload; inline;
function atomic_decrement(var aObj: PtrUInt): PtrUInt; overload; inline;
{$ENDIF}
{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_decrement_64(var aObj: Int64): Int64; overload; inline;
function atomic_decrement_64(var aObj: UInt64): UInt64; overload; inline;
{$ENDIF}

//┌────────────────────────────────────────────────────────────────────────────┐
//│                              atomic_fetch_add                              │
//└────────────────────────────────────────────────────────────────────────────┘

// ✅ Phase 3: 添加 memory_order 参数版本
function atomic_fetch_add(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32; overload; inline;
function atomic_fetch_add(var aObj: Int32; aArg: Int32): Int32; overload; inline;
function atomic_fetch_add(var aObj: UInt32; aArg: UInt32; aOrder: memory_order_t): UInt32; overload; inline;
function atomic_fetch_add(var aObj: UInt32; aArg: UInt32): UInt32; overload; inline;
{$IFDEF CPU64}
function atomic_fetch_add(var aObj: PtrInt; aArg: PtrInt; aOrder: memory_order_t): PtrInt; overload; inline;
function atomic_fetch_add(var aObj: PtrInt; aArg: PtrInt): PtrInt; overload; inline;
function atomic_fetch_add(var aObj: PtrUInt; aArg: PtrUInt; aOrder: memory_order_t): PtrUInt; overload; inline;
function atomic_fetch_add(var aObj: PtrUInt; aArg: PtrUInt): PtrUInt; overload; inline;
{$ENDIF}
function atomic_fetch_add(var aObj: Pointer; aOffset: PtrInt): Pointer; overload; inline;

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_fetch_add_64(var aObj: Int64; aArg: Int64; aOrder: memory_order_t): Int64; overload; inline;
function atomic_fetch_add_64(var aObj: Int64; aArg: Int64): Int64; overload; inline;
function atomic_fetch_add_64(var aObj: UInt64; aArg: UInt64; aOrder: memory_order_t): UInt64; overload; inline;
function atomic_fetch_add_64(var aObj: UInt64; aArg: UInt64): UInt64; overload; inline;
{$ENDIF}

//┌────────────────────────────────────────────────────────────────────────────┐
//│                              atomic_fetch_sub                              │
//└────────────────────────────────────────────────────────────────────────────┘

// ✅ Phase 3: 添加 memory_order 参数版本
function atomic_fetch_sub(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32; overload; inline;
function atomic_fetch_sub(var aObj: Int32; aArg: Int32): Int32; overload; inline;
function atomic_fetch_sub(var aObj: UInt32; aArg: UInt32; aOrder: memory_order_t): UInt32; overload; inline;
function atomic_fetch_sub(var aObj: UInt32; aArg: UInt32): UInt32; overload; inline;
{$IFDEF CPU64}
function atomic_fetch_sub(var aObj: PtrInt; aArg: PtrInt; aOrder: memory_order_t): PtrInt; overload; inline;
function atomic_fetch_sub(var aObj: PtrInt; aArg: PtrInt): PtrInt; overload; inline;
function atomic_fetch_sub(var aObj: PtrUInt; aArg: PtrUInt; aOrder: memory_order_t): PtrUInt; overload; inline;
function atomic_fetch_sub(var aObj: PtrUInt; aArg: PtrUInt): PtrUInt; overload; inline;
{$ENDIF}
function atomic_fetch_sub(var aObj: Pointer; aOffset: PtrInt): Pointer; overload; inline;

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_fetch_sub_64(var aObj: Int64; aArg: Int64; aOrder: memory_order_t): Int64; overload; inline;
function atomic_fetch_sub_64(var aObj: Int64; aArg: Int64): Int64; overload; inline;
function atomic_fetch_sub_64(var aObj: UInt64; aArg: UInt64; aOrder: memory_order_t): UInt64; overload; inline;
function atomic_fetch_sub_64(var aObj: UInt64; aArg: UInt64): UInt64; overload; inline;
{$ENDIF}

//┌────────────────────────────────────────────────────────────────────────────┐
//│                              atomic_fetch_and                              │
//└────────────────────────────────────────────────────────────────────────────┘

// ✅ Phase 3: 添加 memory_order 参数版本
function atomic_fetch_and(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32; overload; inline;
function atomic_fetch_and(var aObj: Int32; aArg: Int32): Int32; overload; inline;
function atomic_fetch_and(var aObj: UInt32; aArg: UInt32; aOrder: memory_order_t): UInt32; overload; inline;
function atomic_fetch_and(var aObj: UInt32; aArg: UInt32): UInt32; overload; inline;
{$IFDEF CPU64}
function atomic_fetch_and(var aObj: PtrInt; aArg: PtrInt; aOrder: memory_order_t): PtrInt; overload; inline;
function atomic_fetch_and(var aObj: PtrInt; aArg: PtrInt): PtrInt; overload; inline;
function atomic_fetch_and(var aObj: PtrUInt; aArg: PtrUInt; aOrder: memory_order_t): PtrUInt; overload; inline;
function atomic_fetch_and(var aObj: PtrUInt; aArg: PtrUInt): PtrUInt; overload; inline;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_fetch_and_64(var aObj: Int64; aArg: Int64; aOrder: memory_order_t): Int64; overload; inline;
function atomic_fetch_and_64(var aObj: Int64; aArg: Int64): Int64; overload; inline;
function atomic_fetch_and_64(var aObj: UInt64; aArg: UInt64; aOrder: memory_order_t): UInt64; overload; inline;
function atomic_fetch_and_64(var aObj: UInt64; aArg: UInt64): UInt64; overload; inline;
{$ENDIF}

//┌────────────────────────────────────────────────────────────────────────────┐
//│                              atomic_fetch_or                               │
//└────────────────────────────────────────────────────────────────────────────┘

// ✅ Phase 3: 添加 memory_order 参数版本
function atomic_fetch_or(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32; overload; inline;
function atomic_fetch_or(var aObj: Int32; aArg: Int32): Int32; overload; inline;
function atomic_fetch_or(var aObj: UInt32; aArg: UInt32; aOrder: memory_order_t): UInt32; overload; inline;
function atomic_fetch_or(var aObj: UInt32; aArg: UInt32): UInt32; overload; inline;
{$IFDEF CPU64}
function atomic_fetch_or(var aObj: PtrInt; aArg: PtrInt; aOrder: memory_order_t): PtrInt; overload; inline;
function atomic_fetch_or(var aObj: PtrInt; aArg: PtrInt): PtrInt; overload; inline;
function atomic_fetch_or(var aObj: PtrUInt; aArg: PtrUInt; aOrder: memory_order_t): PtrUInt; overload; inline;
function atomic_fetch_or(var aObj: PtrUInt; aArg: PtrUInt): PtrUInt; overload; inline;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_fetch_or_64(var aObj: Int64; aArg: Int64; aOrder: memory_order_t): Int64; overload; inline;
function atomic_fetch_or_64(var aObj: Int64; aArg: Int64): Int64; overload; inline;
function atomic_fetch_or_64(var aObj: UInt64; aArg: UInt64; aOrder: memory_order_t): UInt64; overload; inline;
function atomic_fetch_or_64(var aObj: UInt64; aArg: UInt64): UInt64; overload; inline;
{$ENDIF}

//┌────────────────────────────────────────────────────────────────────────────┐
//│                              atomic_fetch_xor                              │
//└────────────────────────────────────────────────────────────────────────────┘

// ✅ Phase 3: 添加 memory_order 参数版本
function atomic_fetch_xor(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32; overload; inline;
function atomic_fetch_xor(var aObj: Int32; aArg: Int32): Int32; overload; inline;
function atomic_fetch_xor(var aObj: UInt32; aArg: UInt32; aOrder: memory_order_t): UInt32; overload; inline;
function atomic_fetch_xor(var aObj: UInt32; aArg: UInt32): UInt32; overload; inline;
{$IFDEF CPU64}
function atomic_fetch_xor(var aObj: PtrInt; aArg: PtrInt; aOrder: memory_order_t): PtrInt; overload; inline;
function atomic_fetch_xor(var aObj: PtrInt; aArg: PtrInt): PtrInt; overload; inline;
function atomic_fetch_xor(var aObj: PtrUInt; aArg: PtrUInt; aOrder: memory_order_t): PtrUInt; overload; inline;
function atomic_fetch_xor(var aObj: PtrUInt; aArg: PtrUInt): PtrUInt; overload; inline;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_fetch_xor_64(var aObj: Int64; aArg: Int64; aOrder: memory_order_t): Int64; overload; inline;
function atomic_fetch_xor_64(var aObj: Int64; aArg: Int64): Int64; overload; inline;
function atomic_fetch_xor_64(var aObj: UInt64; aArg: UInt64; aOrder: memory_order_t): UInt64; overload; inline;
function atomic_fetch_xor_64(var aObj: UInt64; aArg: UInt64): UInt64; overload; inline;
{$ENDIF}

//┌────────────────────────────────────────────────────────────────────────────┐
//│                    atomic_fetch_max / min / nand (Phase 3)                 │
//└────────────────────────────────────────────────────────────────────────────┘

// ✅ Phase 3: 新增 fetch_max/min/nand 操作
function atomic_fetch_max(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32; overload; inline;
function atomic_fetch_max(var aObj: Int32; aArg: Int32): Int32; overload; inline;
function atomic_fetch_min(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32; overload; inline;
function atomic_fetch_min(var aObj: Int32; aArg: Int32): Int32; overload; inline;
function atomic_fetch_nand(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32; overload; inline;
function atomic_fetch_nand(var aObj: Int32; aArg: Int32): Int32; overload; inline;

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_fetch_max_64(var aObj: Int64; aArg: Int64; aOrder: memory_order_t): Int64; overload; inline;
function atomic_fetch_max_64(var aObj: Int64; aArg: Int64): Int64; overload; inline;
function atomic_fetch_min_64(var aObj: Int64; aArg: Int64; aOrder: memory_order_t): Int64; overload; inline;
function atomic_fetch_min_64(var aObj: Int64; aArg: Int64): Int64; overload; inline;
function atomic_fetch_nand_64(var aObj: Int64; aArg: Int64; aOrder: memory_order_t): Int64; overload; inline;
function atomic_fetch_nand_64(var aObj: Int64; aArg: Int64): Int64; overload; inline;
{$ENDIF}

//┌────────────────────────────────────────────────────────────────────────────┐
//│                               atomic_flag                                  │
//└────────────────────────────────────────────────────────────────────────────┘

type

  atomic_flag_t = type Int32;

function atomic_flag_test_and_set(var aFlag: atomic_flag_t): Boolean; inline;
function atomic_flag_test(var aFlag: atomic_flag_t): Boolean; inline;
procedure atomic_flag_clear(var aFlag: atomic_flag_t); inline;

//┌────────────────────────────────────────────────────────────────────────────┐
//│                            atomic_is_lock_free                             │
//└────────────────────────────────────────────────────────────────────────────┘

function atomic_is_lock_free_32: Boolean; inline;
{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_is_lock_free_64: Boolean; inline;
{$ENDIF}
function atomic_is_lock_free_ptr: Boolean; inline;

//┌────────────────────────────────────────────────────────────────────────────┐
//│                             atomic_tagged_ptr                              │
//└────────────────────────────────────────────────────────────────────────────┘

type
  atomic_tagged_ptr_t = type PtrUInt;

function  atomic_tagged_ptr(aPtr: Pointer; aTag: {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF}): atomic_tagged_ptr_t; inline;
function  atomic_tagged_ptr_get_ptr(const aTaggedPtr: atomic_tagged_ptr_t): Pointer; inline;
function  atomic_tagged_ptr_get_tag(const aTaggedPtr: atomic_tagged_ptr_t): {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF}; inline;

function  atomic_tagged_ptr_load(var aObj: atomic_tagged_ptr_t; aOrder: memory_order_t): atomic_tagged_ptr_t; overload; inline;
function  atomic_tagged_ptr_load(var aObj: atomic_tagged_ptr_t): atomic_tagged_ptr_t; overload; inline;
procedure atomic_tagged_ptr_store(var aObj: atomic_tagged_ptr_t; aDesired: atomic_tagged_ptr_t; aOrder: memory_order_t); overload; inline;
procedure atomic_tagged_ptr_store(var aObj: atomic_tagged_ptr_t; aDesired: atomic_tagged_ptr_t); overload; inline;
function  atomic_tagged_ptr_exchange(var aObj: atomic_tagged_ptr_t; aDesired: atomic_tagged_ptr_t; aOrder: memory_order_t): atomic_tagged_ptr_t; overload; inline;
function  atomic_tagged_ptr_exchange(var aObj: atomic_tagged_ptr_t; aDesired: atomic_tagged_ptr_t): atomic_tagged_ptr_t; overload; inline;
function  atomic_tagged_ptr_compare_exchange_strong(var aObj: atomic_tagged_ptr_t; var aExpected: atomic_tagged_ptr_t; aDesired: atomic_tagged_ptr_t; aSuccessOrder, aFailureOrder: memory_order_t): Boolean; overload; inline;
function  atomic_tagged_ptr_compare_exchange_strong(var aObj: atomic_tagged_ptr_t; var aExpected: atomic_tagged_ptr_t; aDesired: atomic_tagged_ptr_t): Boolean; overload; inline;
function  atomic_tagged_ptr_compare_exchange_weak(var aObj: atomic_tagged_ptr_t; var aExpected: atomic_tagged_ptr_t; aDesired: atomic_tagged_ptr_t; aSuccessOrder, aFailureOrder: memory_order_t): Boolean; overload; inline;
function  atomic_tagged_ptr_compare_exchange_weak(var aObj: atomic_tagged_ptr_t; var aExpected: atomic_tagged_ptr_t; aDesired: atomic_tagged_ptr_t): Boolean; overload; inline;

function  atomic_tagged_ptr_next(const aTaggedPtr: atomic_tagged_ptr_t): {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF}; inline;
procedure atomic_tagged_ptr_update(var aObj: atomic_tagged_ptr_t; aPtr: Pointer); inline;
procedure atomic_tagged_ptr_update_tag(var aObj: atomic_tagged_ptr_t; aTag: {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF}); inline;

procedure atomic_thread_fence(aOrder: memory_order_t); inline;

implementation

//┌────────────────────────────────────────────────────────────────────────────┐
//│              Phase 4: cpu_pause - 减少自旋等待开销                          │
//└────────────────────────────────────────────────────────────────────────────┘

// ✅ Phase 4: cpu_pause - x86 PAUSE 指令 (opcode F3 90)
// 在 CAS 循环中使用，减少 CPU 功耗和流水线惩罚
// - x86/x86_64: PAUSE 指令，提示 CPU 这是自旋等待
// - ARM: YIELD 指令
// - 其他平台: 空操作（编译器会优化掉）
procedure cpu_pause;
begin
  {$IF DEFINED(CPUX86_64)}
    // x86_64: PAUSE = F3 90 (REP NOP)
    asm
      pause
    end;
  {$ELSEIF DEFINED(CPUX86)}
    // x86: PAUSE = F3 90
    asm
      pause
    end;
  {$ELSEIF DEFINED(CPUAARCH64)}
    // ARM64: YIELD 指令
    asm
      yield
    end;
  {$ELSEIF DEFINED(CPUARM)}
    // ARM32: YIELD 指令 (ARMv6K+)
    asm
      yield
    end;
  {$ELSE}
    // 其他平台: 空操作
  {$ENDIF}
end;

// A lightweight compiler barrier.
// - For x86/x86_64, acquire/release for plain load/store doesn't require a CPU fence (TSO),
//   but we still want to prevent compiler reordering.
// NOTE: FPC does not inline routines containing inline assembler, so keep this as a tiny
// out-of-line stub: the *call* itself is the compiler barrier (and there's no CPU fence).
{$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86)}
procedure _compiler_barrier; assembler; nostackframe;
asm
  nop
end;
{$ELSE}
procedure _compiler_barrier; inline;
begin
  // Safe fallback if ever used on other platforms.
  ReadBarrier;
end;
{$ENDIF}

//┌────────────────────────────────────────────────────────────────────────────┐
//│       Phase 1: 32 位 x86 上的 64 位原子操作底层实现                      │
//└────────────────────────────────────────────────────────────────────────────┘

{$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}
// 32 位 x86 上使用 CMPXCHG8B 实现 64 位原子操作
// CMPXCHG8B 指令：比较 EDX:EAX 与 [mem]，相等则将 ECX:EBX 存入 [mem]
// 注意：FPC i386 使用寄存器调用约定，eax/edx/ecx 传递前三个参数

var
  // 32-bit x86: CMPXCHG8B may not exist on very old CPUs; provide runtime detection and fallback.
  gAtomic64HasCmpxchg8b: Boolean = True;
  gAtomic64FallbackLock: Int32 = 0;

procedure _atomic64_fallback_lock; inline;
begin
  // NOTE: Prefer XCHG-based acquire so the fallback doesn't implicitly require CMPXCHG.
  // This matters on very old 32-bit x86 where CMPXCHG8B/CPUID may be missing.
  while InterlockedExchange(gAtomic64FallbackLock, 1) <> 0 do
    cpu_pause;
end;

procedure _atomic64_fallback_unlock; inline;
begin
  InterlockedExchange(gAtomic64FallbackLock, 0);
end;

function _x86_has_cpuid: Boolean; inline;
var
  LCan: Byte;
begin
  LCan := 0;
  asm
    pushfd
    pop eax
    mov ecx, eax
    xor eax, $200000
    push eax
    popfd
    pushfd
    pop eax
    xor eax, ecx
    and eax, $200000
    setnz al
    mov LCan, al
    push ecx
    popfd
  end;
  Result := LCan <> 0;
end;

function _x86_has_cmpxchg8b: Boolean; inline;
var
  LEdx: UInt32;
begin
  if not _x86_has_cpuid then
    Exit(False);

  LEdx := 0;
  asm
    push ebx
    mov eax, 1
    cpuid
    mov LEdx, edx
    pop ebx
  end;

  Result := (LEdx and (UInt32(1) shl 8)) <> 0;
end;

function _atomic_load_64_x86(var aObj: Int64): Int64;
var
  LPtr: PInt64;
  LLo, LHi: UInt32;
begin
  if not gAtomic64HasCmpxchg8b then
  begin
    _atomic64_fallback_lock;
    Result := aObj;
    _atomic64_fallback_unlock;
    Exit;
  end;

  LPtr := @aObj;
  asm
    push ebx
    push edi
    mov edi, LPtr
    xor eax, eax
    xor edx, edx
    xor ebx, ebx
    xor ecx, ecx
    lock cmpxchg8b [edi]
    mov LLo, eax
    mov LHi, edx
    pop edi
    pop ebx
  end;
  Result := Int64(LHi) shl 32 or LLo;
end;

procedure _atomic_store_64_x86(var aObj: Int64; aDesired: Int64);
var
  LPtr: PInt64;
  LDesLo, LDesHi: UInt32;
begin
  if not gAtomic64HasCmpxchg8b then
  begin
    _atomic64_fallback_lock;
    aObj := aDesired;
    _atomic64_fallback_unlock;
    Exit;
  end;

  LPtr := @aObj;
  LDesLo := UInt32(aDesired);
  LDesHi := UInt32(aDesired shr 32);
  asm
    push ebx
    push edi
    mov edi, LPtr
    mov ebx, LDesLo
    mov ecx, LDesHi
    mov eax, [edi]
    mov edx, [edi + 4]
  @retry:
    lock cmpxchg8b [edi]
    jnz @retry
    pop edi
    pop ebx
  end;
end;

function _atomic_exchange_64_x86(var aObj: Int64; aDesired: Int64): Int64;
var
  LPtr: PInt64;
  LDesLo, LDesHi, LResLo, LResHi: UInt32;
begin
  if not gAtomic64HasCmpxchg8b then
  begin
    _atomic64_fallback_lock;
    Result := aObj;
    aObj := aDesired;
    _atomic64_fallback_unlock;
    Exit;
  end;

  LPtr := @aObj;
  LDesLo := UInt32(aDesired);
  LDesHi := UInt32(aDesired shr 32);
  asm
    push ebx
    push edi
    mov edi, LPtr
    mov ebx, LDesLo
    mov ecx, LDesHi
    mov eax, [edi]
    mov edx, [edi + 4]
  @retry:
    lock cmpxchg8b [edi]
    jnz @retry
    mov LResLo, eax
    mov LResHi, edx
    pop edi
    pop ebx
  end;
  Result := Int64(LResHi) shl 32 or LResLo;
end;

function _atomic_cmpxchg_64_x86(var aObj: Int64; var aExpected: Int64; aDesired: Int64): Boolean;
var
  LPtr: PInt64;
  LExpLo, LExpHi, LDesLo, LDesHi, LResLo, LResHi: UInt32;
  LSuccess: Boolean;
begin
  if not gAtomic64HasCmpxchg8b then
  begin
    _atomic64_fallback_lock;
    if aObj = aExpected then
    begin
      aObj := aDesired;
      Result := True;
    end
    else
    begin
      aExpected := aObj;
      Result := False;
    end;
    _atomic64_fallback_unlock;
    Exit;
  end;

  LPtr := @aObj;
  LExpLo := UInt32(aExpected);
  LExpHi := UInt32(aExpected shr 32);
  LDesLo := UInt32(aDesired);
  LDesHi := UInt32(aDesired shr 32);
  LSuccess := False;
  asm
    push ebx
    push edi
    mov edi, LPtr
    mov eax, LExpLo
    mov edx, LExpHi
    mov ebx, LDesLo
    mov ecx, LDesHi
    lock cmpxchg8b [edi]
    mov LResLo, eax
    mov LResHi, edx
    setz al
    mov LSuccess, al
    pop edi
    pop ebx
  end;
  if not LSuccess then
    aExpected := Int64(LResHi) shl 32 or LResLo;
  Result := LSuccess;
end;

function _atomic_fetch_add_64_x86(var aObj: Int64; aArg: Int64): Int64;
var
  LPtr: PInt64;
  LArgLo, LArgHi, LOldLo, LOldHi: UInt32;
begin
  if not gAtomic64HasCmpxchg8b then
  begin
    _atomic64_fallback_lock;
    Result := aObj;
    aObj := aObj + aArg;
    _atomic64_fallback_unlock;
    Exit;
  end;

  LPtr := @aObj;
  LArgLo := UInt32(aArg);
  LArgHi := UInt32(aArg shr 32);
  asm
    push ebx
    push edi
    mov edi, LPtr
    mov eax, [edi]
    mov edx, [edi + 4]
  @retry:
    mov LOldLo, eax
    mov LOldHi, edx
    // 计算新值
    mov ebx, eax
    add ebx, LArgLo
    mov ecx, edx
    adc ecx, LArgHi
    lock cmpxchg8b [edi]
    jnz @retry
    pop edi
    pop ebx
  end;
  Result := Int64(LOldHi) shl 32 or LOldLo;
end;
{$ENDIF}

function atomic_load(var aObj: Int32; aOrder: memory_order_t): Int32;
begin
  case aOrder of
    mo_relaxed:
      Result := aObj;

    mo_consume, mo_acquire, mo_acq_rel:
      begin
        Result := aObj;
        {$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86)}
          _compiler_barrier;    // Acquire load on x86: compiler barrier is enough
        {$ELSE}
          ReadBarrier;          // Acquire load on weakly-ordered CPUs
        {$ENDIF}
      end;

    mo_release:
      begin
        // 对 load 没意义，直接当 relaxed
        Result := aObj;
      end;

    mo_seq_cst:
      begin
        // On weakly-ordered CPUs (e.g. AArch64), make seq_cst loads fully ordered.
        // On x86/x86_64, a plain load is already strongly ordered at the CPU level;
        // use only a compiler barrier to prevent reordering.
        {$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86)}
          Result := aObj;
          _compiler_barrier;
        {$ELSE}
          ReadWriteBarrier;
          Result := aObj;
          ReadWriteBarrier;
        {$ENDIF}
      end;
  end;
end;

function atomic_load(var aObj: Int32): Int32;
begin
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86)}
    Result := atomic_load(aObj, mo_relaxed);
  {$ELSE}
    Result := atomic_load(aObj, mo_acquire);
  {$ENDIF}
end;

function atomic_load(var aObj: UInt32; aOrder: memory_order_t): UInt32;
begin
  {$PUSH}
  {$WARN 4055 OFF} // Conversion between ordinals and pointers is not portable
  Result := UInt32(atomic_load(PInt32(@aObj)^, aOrder));
  {$POP}
end;

function atomic_load(var aObj: UInt32): UInt32;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt32(atomic_load(PInt32(@aObj)^));
  {$POP}
end;


{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_load_64(var aObj: Int64; aOrder: memory_order_t): Int64;
begin
  {$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}
  // 32-bit x86: use CMPXCHG8B-based atomic load
  Result := _atomic_load_64_x86(aObj);
  case aOrder of
    mo_consume, mo_acquire, mo_acq_rel, mo_seq_cst:
      _compiler_barrier;
  else
    ; // mo_relaxed, mo_release
  end;
  {$ELSE}
  // 64-bit: simple load is atomic
  case aOrder of
    mo_relaxed:
      Result := aObj;

    mo_consume, mo_acquire, mo_acq_rel:
      begin
        Result := aObj;
        {$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86)}
          _compiler_barrier;
        {$ELSE}
          ReadBarrier;
        {$ENDIF}
      end;

    mo_release:
      Result := aObj;

    mo_seq_cst:
      begin
        {$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86)}
          Result := aObj;
          _compiler_barrier;
        {$ELSE}
          ReadWriteBarrier;
          Result := aObj;
          ReadWriteBarrier;
        {$ENDIF}
      end;
  end;
  {$ENDIF}
end;

function atomic_load_64(var aObj: Int64): Int64;
begin
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86)}
    Result := atomic_load_64(aObj, mo_relaxed);
  {$ELSE}
    Result := atomic_load_64(aObj, mo_acquire);
  {$ENDIF}
end;

function atomic_load_64(var aObj: UInt64; aOrder: memory_order_t): UInt64;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt64(atomic_load_64(PInt64(@aObj)^, aOrder));
  {$POP}
end;

function atomic_load_64(var aObj: UInt64):UInt64;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt64(atomic_load_64(PInt64(@aObj)^));
  {$POP}
end;

{$ENDIF}

function atomic_load(var aObj: Pointer; aOrder: memory_order_t): Pointer;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  {$IF sizeof(Pointer) = 4}
    Result := Pointer(atomic_load(PInt32(@aObj)^, aOrder));
  {$ELSE}
    Result := Pointer(atomic_load_64(PInt64(@aObj)^, aOrder));
  {$ENDIF}
  {$POP}
end;

function atomic_load(var aObj: Pointer): Pointer;
begin
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86)}
    Result := atomic_load(aObj, mo_relaxed);
  {$ELSE}
    Result := atomic_load(aObj, mo_acquire);
  {$ENDIF}  
end;

function atomic_load_ptr(var aObj: Pointer; aOrder: memory_order_t): Pointer;
begin
  Result := atomic_load(aObj, aOrder);
end;

function atomic_load_ptr(var aObj: Pointer): Pointer;
begin
  Result := atomic_load(aObj);
end;

{$IFDEF CPU64}
function atomic_load(var aObj: PtrInt; aOrder: memory_order_t): PtrInt;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  {$IF sizeof(PtrInt) = 4}
    Result := PtrInt(atomic_load(PInt32(@aObj)^, aOrder));
  {$ELSE}
    Result := PtrInt(atomic_load_64(PInt64(@aObj)^, aOrder));
  {$ENDIF}
  {$POP}
end;

function atomic_load(var aObj: PtrInt): PtrInt;
begin
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86)}
    Result := atomic_load(aObj, mo_relaxed);
  {$ELSE}
    Result := atomic_load(aObj, mo_acquire);
  {$ENDIF}
end;


function atomic_load(var aObj: PtrUInt; aOrder: memory_order_t): PtrUInt;
begin
  Result:= PtrUInt(atomic_load(PPtrInt(@aObj)^, aOrder));
end;

function atomic_load(var aObj: PtrUInt): PtrUInt;
begin
  Result:= PtrUInt(atomic_load(PPtrInt(@aObj)^));
end;
{$ENDIF}

procedure atomic_store(var aObj: Int32; aDesired: Int32; aOrder: memory_order_t);
begin
  case aOrder of
    mo_relaxed, mo_consume, mo_acquire:
      aObj := aDesired;  // store 不需要 acquire/consume

    mo_release, mo_acq_rel:
      begin
        {$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86)}
          _compiler_barrier; // Release store on x86: compiler barrier is enough
        {$ELSE}
          WriteBarrier;      // Release store on weakly-ordered CPUs
        {$ENDIF}
        aObj := aDesired;
      end;

    mo_seq_cst:
      // ✅ P0-2 修复: seq_cst store 需要使用 XCHG (隐含 full barrier)
      // 原实现错误地在 store 之前放置屏障，正确做法是使用 InterlockedExchange
      InterlockedExchange(aObj, aDesired);
  end;
end;

procedure atomic_store(var aObj: Int32; aDesired: Int32);
begin
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86)}
    atomic_store(aObj, aDesired, mo_relaxed);
  {$ELSE}
    atomic_store(aObj, aDesired, mo_release);
  {$ENDIF}  
end;

procedure atomic_store(var aObj: UInt32; aDesired: UInt32; aOrder: memory_order_t);
begin
  {$PUSH}
  {$WARN 4055 OFF}
  atomic_store(PInt32(@aObj)^, PInt32(@aDesired)^, aOrder);
  {$POP}
end;

procedure atomic_store(var aObj: UInt32; aDesired: UInt32);
begin
  {$PUSH}
  {$WARN 4055 OFF}
  atomic_store(PInt32(@aObj)^, PInt32(@aDesired)^);
  {$POP}
end;

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
procedure atomic_store_64(var aObj: Int64; aDesired: Int64; aOrder: memory_order_t);
begin
  {$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}
  // 32-bit x86: use CMPXCHG8B-based atomic store (LOCK CMPXCHG8B is already a full fence)
  case aOrder of
    mo_release, mo_acq_rel, mo_seq_cst:
      _compiler_barrier;
  else
    ; // mo_relaxed, mo_consume, mo_acquire
  end;
  _atomic_store_64_x86(aObj, aDesired);
  {$ELSE}
  // 64-bit: simple store is atomic
  case aOrder of
    mo_relaxed, mo_consume, mo_acquire:
      aObj := aDesired;

    mo_release, mo_acq_rel:
      begin
        {$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86)}
          _compiler_barrier;
        {$ELSE}
          WriteBarrier;
        {$ENDIF}
        aObj := aDesired;
      end;

    mo_seq_cst:
      // ✅ P0-2 修复: seq_cst store 需要使用 XCHG (隐含 full barrier)
      InterlockedExchange64(aObj, aDesired);
  end;
  {$ENDIF}
end;

procedure atomic_store_64(var aObj: Int64; aDesired: Int64);
begin
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86)}
    atomic_store_64(aObj, aDesired, mo_relaxed);
  {$ELSE}
    atomic_store_64(aObj, aDesired, mo_release);
  {$ENDIF}
end;

procedure atomic_store_64(var aObj: UInt64; aDesired: UInt64; aOrder: memory_order_t);
begin
  {$PUSH}
  {$WARN 4055 OFF}
  atomic_store_64(PInt64(@aObj)^, PInt64(@aDesired)^, aOrder);
  {$POP}
end;

procedure atomic_store_64(var aObj: UInt64; aDesired: UInt64);
begin
  {$PUSH}
  {$WARN 4055 OFF}
  atomic_store_64(PInt64(@aObj)^, PInt64(@aDesired)^);
  {$POP}
end;
{$ENDIF}

procedure atomic_store(var aObj: Pointer; aDesired: Pointer; aOrder: memory_order_t);
begin
  {$PUSH}
  {$WARN 4055 OFF}
  {$IF sizeof(Pointer) = 4}
    atomic_store(PInt32(@aObj)^, PInt32(@aDesired)^, aOrder);
  {$ELSE}
    atomic_store_64(PInt64(@aObj)^, PInt64(@aDesired)^, aOrder);
  {$ENDIF}
  {$POP}
end;

procedure atomic_store(var aObj: Pointer; aDesired: Pointer);
begin
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86)}
    atomic_store(aObj, aDesired, mo_relaxed);
  {$ELSE}
    atomic_store(aObj, aDesired, mo_release);
  {$ENDIF}  
end;

procedure atomic_store_ptr(var aObj: Pointer; aDesired: Pointer; aOrder: memory_order_t);
begin
  atomic_store(aObj, aDesired, aOrder);
end;

procedure atomic_store_ptr(var aObj: Pointer; aDesired: Pointer);
begin
  atomic_store(aObj, aDesired);
end;


{$IFDEF CPU64}
procedure atomic_store(var aObj: PtrInt; aDesired: PtrInt; aOrder: memory_order_t);
begin
  {$PUSH}
  {$WARN 4055 OFF}
  {$IF sizeof(PtrInt) = 4}
    atomic_store(PInt32(@aObj)^, PInt32(@aDesired)^, aOrder);
  {$ELSE}
    atomic_store_64(PInt64(@aObj)^, PInt64(@aDesired)^, aOrder);
  {$ENDIF}
  {$POP}
end;

procedure atomic_store(var aObj: PtrInt; aDesired: PtrInt);
begin
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86)}
    atomic_store(aObj, aDesired, mo_relaxed);
  {$ELSE}
    atomic_store(aObj, aDesired, mo_release);
  {$ENDIF}  
end;

procedure atomic_store(var aObj: PtrUInt; aDesired: PtrUInt; aOrder: memory_order_t);
begin
  atomic_store(PPtrInt(@aObj)^, PPtrInt(@aDesired)^, aOrder);
end;

procedure atomic_store(var aObj: PtrUInt; aDesired: PtrUInt);
begin
  atomic_store(PPtrInt(@aObj)^, PPtrInt(@aDesired)^);
end;
{$ENDIF}


// ✅ Phase 3: atomic_exchange 带 memory_order 参数实现
function atomic_exchange(var aObj: Int32; aDesired: Int32; aOrder: memory_order_t): Int32;
begin
  // Exchange is a RMW.
  // On x86/x86_64, InterlockedExchange is implemented via XCHG/LOCK and already provides a full fence.
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  else
    ;
  end;
  {$ENDIF}

  Result := InterlockedExchange(aObj, aDesired);

  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_consume, mo_acquire, mo_acq_rel:
      ReadBarrier;
  else
    ; // mo_relaxed, mo_release
  end;
  {$ENDIF}
end;

function atomic_exchange(var aObj: Int32; aDesired: Int32): Int32;
begin
  // Default is seq_cst.
  Result := atomic_exchange(aObj, aDesired, mo_seq_cst);
end;

function atomic_exchange(var aObj: UInt32; aDesired: UInt32; aOrder: memory_order_t): UInt32;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt32(atomic_exchange(PInt32(@aObj)^, PInt32(@aDesired)^, aOrder));
  {$POP}
end;

function atomic_exchange(var aObj: UInt32; aDesired: UInt32): UInt32;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt32(atomic_exchange(PInt32(@aObj)^, PInt32(@aDesired)^));
  {$POP}
end;

{$IFDEF CPU64}
function atomic_exchange(var aObj: PtrInt; aDesired: PtrInt; aOrder: memory_order_t): PtrInt;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  {$IF sizeof(PtrInt) = 4}
    Result := PtrInt(atomic_exchange(PInt32(@aObj)^, PInt32(@aDesired)^, aOrder));
  {$ELSE}
    Result := PtrInt(atomic_exchange_64(PInt64(@aObj)^, PInt64(@aDesired)^, aOrder));
  {$ENDIF}
  {$POP}
end;

function atomic_exchange(var aObj: PtrInt; aDesired: PtrInt): PtrInt;
begin
  // Default is seq_cst.
  Result := atomic_exchange(aObj, aDesired, mo_seq_cst);
end;

function atomic_exchange(var aObj: PtrUInt; aDesired: PtrUInt; aOrder: memory_order_t): PtrUInt;
begin
  Result := PtrUInt(atomic_exchange(PPtrInt(@aObj)^, PPtrInt(@aDesired)^, aOrder));
end;

function atomic_exchange(var aObj: PtrUInt; aDesired: PtrUInt): PtrUInt;
begin
  Result := PtrUInt(atomic_exchange(PPtrInt(@aObj)^, PPtrInt(@aDesired)^));
end;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_exchange_64(var aObj: Int64; aDesired: Int64; aOrder: memory_order_t): Int64;
begin
  // Exchange is a RMW.
  // On x86/x86_64, the underlying locked RMW already provides a full fence.
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  else
    ;
  end;
  {$ENDIF}

  {$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}
  // 32-bit x86: use CMPXCHG8B-based atomic exchange
  Result := _atomic_exchange_64_x86(aObj, aDesired);
  {$ELSE}
  Result := InterlockedExchange64(aObj, aDesired);
  {$ENDIF}

  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_consume, mo_acquire, mo_acq_rel:
      ReadBarrier;
  else
    ; // mo_relaxed, mo_release
  end;
  {$ENDIF}
end;

function atomic_exchange_64(var aObj: Int64; aDesired: Int64): Int64;
begin
  // Default is seq_cst.
  Result := atomic_exchange_64(aObj, aDesired, mo_seq_cst);
end;

function atomic_exchange_64(var aObj: UInt64; aDesired: UInt64; aOrder: memory_order_t): UInt64;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt64(atomic_exchange_64(PInt64(@aObj)^, PInt64(@aDesired)^, aOrder));
  {$POP}
end;

function atomic_exchange_64(var aObj: UInt64; aDesired: UInt64): UInt64;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt64(atomic_exchange_64(PInt64(@aObj)^, PInt64(@aDesired)^));
  {$POP}
end;
{$ENDIF}

function atomic_exchange(var aObj: Pointer; aDesired: Pointer; aOrder: memory_order_t): Pointer;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  {$IF sizeof(Pointer) = 4}
    Result := Pointer(atomic_exchange(PInt32(@aObj)^, PInt32(@aDesired)^, aOrder));
  {$ELSE}
    Result := Pointer(atomic_exchange_64(PInt64(@aObj)^, PInt64(@aDesired)^, aOrder));
  {$ENDIF}
  {$POP}
end;

function atomic_exchange(var aObj: Pointer; aDesired: Pointer): Pointer;
begin
  // Default is seq_cst.
  Result := atomic_exchange(aObj, aDesired, mo_seq_cst);
end;

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_compare_exchange_64(var aObj: Int64; var aExpected: Int64; aDesired: Int64): Boolean;
begin
  // Default is seq_cst.
  Result := atomic_compare_exchange_strong_64(aObj, aExpected, aDesired, mo_seq_cst, mo_seq_cst);
end;

function atomic_compare_exchange_64(var aObj: UInt64; var aExpected: UInt64; aDesired: UInt64): Boolean;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := atomic_compare_exchange_strong_64(PInt64(@aObj)^, PInt64(@aExpected)^, PInt64(@aDesired)^, mo_seq_cst, mo_seq_cst);
  {$POP}
end;
{$ENDIF}

function atomic_compare_exchange(var aObj: Int32; var aExpected: Int32; aDesired: Int32): Boolean;
begin
  // Default is seq_cst.
  Result := atomic_compare_exchange_strong(aObj, aExpected, aDesired, mo_seq_cst, mo_seq_cst);
end;

function atomic_compare_exchange(var aObj: UInt32; var aExpected: UInt32; aDesired: UInt32): Boolean;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := atomic_compare_exchange_strong(PInt32(@aObj)^, PInt32(@aExpected)^, PInt32(@aDesired)^, mo_seq_cst, mo_seq_cst);
  {$POP}
end;

{$IFDEF CPU64}
function atomic_compare_exchange(var aObj: PtrInt; var aExpected: PtrInt; aDesired: PtrInt): Boolean;
begin
  // Default is seq_cst.
  Result := atomic_compare_exchange_strong(aObj, aExpected, aDesired, mo_seq_cst, mo_seq_cst);
end;

function atomic_compare_exchange(var aObj: PtrUInt; var aExpected: PtrUInt; aDesired: PtrUInt): Boolean;
begin
  // Default is seq_cst.
  Result := atomic_compare_exchange_strong(aObj, aExpected, aDesired, mo_seq_cst, mo_seq_cst);
end;
{$ENDIF}

function atomic_compare_exchange(var aObj: Pointer; var aExpected: Pointer; aDesired: Pointer): Boolean;
begin
  // Default is seq_cst.
  Result := atomic_compare_exchange_strong(aObj, aExpected, aDesired, mo_seq_cst, mo_seq_cst);
end;

function atomic_compare_exchange_strong(var aObj: Int32; var aExpected: Int32; aDesired: Int32): Boolean;
begin
  Result := atomic_compare_exchange(aObj, aExpected, aDesired);
end;

function atomic_compare_exchange_strong(var aObj: UInt32; var aExpected: UInt32; aDesired: UInt32): Boolean;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := atomic_compare_exchange(PInt32(@aObj)^, PInt32(@aExpected)^, PInt32(@aDesired)^);
  {$POP}
end;

{$IFDEF CPU64}
function atomic_compare_exchange_strong(var aObj: PtrInt; var aExpected: PtrInt; aDesired: PtrInt): Boolean;
begin
  Result := atomic_compare_exchange(aObj, aExpected, aDesired);
end;

function atomic_compare_exchange_strong(var aObj: PtrUInt; var aExpected: PtrUInt; aDesired: PtrUInt): Boolean;
begin
  Result := atomic_compare_exchange(PPtrInt(@aObj)^, PPtrInt(@aExpected)^, PPtrInt(@aDesired)^);
end;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_compare_exchange_strong_64(var aObj: UInt64; var aExpected: UInt64; aDesired: UInt64): Boolean;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := atomic_compare_exchange_64(PInt64(@aObj)^, PInt64(@aExpected)^, PInt64(@aDesired)^);
  {$POP}
end;

function atomic_compare_exchange_strong_64(var aObj: Int64; var aExpected: Int64; aDesired: Int64): Boolean;
begin
  Result := atomic_compare_exchange_64(aObj, aExpected, aDesired);
end;
{$ENDIF}

function atomic_compare_exchange_strong(var aObj: Pointer; var aExpected: Pointer; aDesired: Pointer): Boolean;
begin
  Result := atomic_compare_exchange(aObj, aExpected, aDesired);
end;

function atomic_compare_exchange_strong_ptr(var aObj: Pointer; var aExpected: Pointer; aDesired: Pointer): Boolean;
begin
  Result := atomic_compare_exchange_strong(aObj, aExpected, aDesired);
end;

function atomic_compare_exchange_weak(var aObj: Int32; var aExpected: Int32; aDesired: Int32): Boolean;
begin
  Result := atomic_compare_exchange(aObj, aExpected, aDesired);
end;

function atomic_compare_exchange_weak(var aObj: UInt32; var aExpected: UInt32; aDesired: UInt32): Boolean;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := atomic_compare_exchange(PInt32(@aObj)^, PInt32(@aExpected)^, PInt32(@aDesired)^);
  {$POP}
end;

{$IFDEF CPU64}
function atomic_compare_exchange_weak(var aObj: PtrInt; var aExpected: PtrInt; aDesired: PtrInt): Boolean;
begin
  Result := atomic_compare_exchange(aObj, aExpected, aDesired);
end;

function atomic_compare_exchange_weak(var aObj: PtrUInt; var aExpected: PtrUInt; aDesired: PtrUInt): Boolean;
begin
  Result := atomic_compare_exchange(PPtrInt(@aObj)^, PPtrInt(@aExpected)^, PPtrInt(@aDesired)^);
end;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_compare_exchange_weak_64(var aObj: Int64; var aExpected: Int64; aDesired: Int64): Boolean;
begin
  Result := atomic_compare_exchange_64(aObj, aExpected, aDesired);
end;

function atomic_compare_exchange_weak_64(var aObj: UInt64; var aExpected: UInt64; aDesired: UInt64): Boolean;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := atomic_compare_exchange_64(PInt64(@aObj)^, PInt64(@aExpected)^, PInt64(@aDesired)^);
  {$POP}
end;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_increment_64(var aObj: Int64): Int64;
begin
  // Convenience API: seq_cst.
  Result := atomic_fetch_add_64(aObj, 1, mo_seq_cst) + 1;
end;

function atomic_increment_64(var aObj: UInt64): UInt64;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt64(atomic_increment_64(PInt64(@aObj)^));
  {$POP}
end;
{$ENDIF}

function atomic_compare_exchange_weak(var aObj: Pointer; var aExpected: Pointer; aDesired: Pointer): Boolean;
begin
  Result := atomic_compare_exchange(aObj, aExpected, aDesired);
end;

// ✅ Phase 3: CAS 带双内存序参数实现
  // 说明: success_order 用于 CAS 成功时的内存序，failure_order 用于 CAS 失败时的内存序
  // x86/x86_64: LOCK CMPXCHG 是全屏障；这里在非 x86 平台才需要用显式屏障补语义。

function atomic_compare_exchange_strong(var aObj: Int32; var aExpected: Int32; aDesired: Int32;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean;
var
  LOld: Int32;
begin
  // CAS is a locked RMW on x86/x86_64 and already provides a full fence.
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  // 成功路径的 release 屏障
  case aSuccessOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  else
    ; // mo_relaxed, mo_consume, mo_acquire 不需要写屏障
  end;
  {$ENDIF}

  LOld := InterlockedCompareExchange(aObj, aDesired, aExpected);
  Result := (LOld = aExpected);

  if Result then
  begin
    {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
    // 成功路径的 acquire 屏障
    case aSuccessOrder of
      mo_seq_cst:
        ReadWriteBarrier;
      mo_consume, mo_acquire, mo_acq_rel:
        ReadBarrier;
    else
      ; // mo_relaxed, mo_release 不需要读屏障
    end;
    {$ENDIF}
  end
  else
  begin
    aExpected := LOld;
    {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
    // 失败路径的 acquire 屏障
    case aFailureOrder of
      mo_seq_cst:
        ReadWriteBarrier;
      mo_consume, mo_acquire, mo_acq_rel:
        ReadBarrier;
    else
      ; // mo_relaxed, mo_release 不需要读屏障
    end;
    {$ENDIF}
  end;
end;

function atomic_compare_exchange_strong(var aObj: UInt32; var aExpected: UInt32; aDesired: UInt32;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := atomic_compare_exchange_strong(PInt32(@aObj)^, PInt32(@aExpected)^, PInt32(@aDesired)^,
    aSuccessOrder, aFailureOrder);
  {$POP}
end;

{$IFDEF CPU64}
function atomic_compare_exchange_strong(var aObj: PtrInt; var aExpected: PtrInt; aDesired: PtrInt;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean;
var
  LOld: Int64;
begin
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aSuccessOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  else
    ;
  end;
  {$ENDIF}

  // Use an explicit Int64 view to avoid var-parameter type mismatches on non-x86_64 64-bit targets.
  LOld := InterlockedCompareExchange64(PInt64(@aObj)^, Int64(aDesired), Int64(aExpected));
  Result := (LOld = Int64(aExpected));

  if Result then
  begin
    {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
    case aSuccessOrder of
      mo_seq_cst:
        ReadWriteBarrier;
      mo_consume, mo_acquire, mo_acq_rel:
        ReadBarrier;
    else
      ;
    end;
    {$ENDIF}
  end
  else
  begin
    aExpected := PtrInt(LOld);
    {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
    case aFailureOrder of
      mo_seq_cst:
        ReadWriteBarrier;
      mo_consume, mo_acquire, mo_acq_rel:
        ReadBarrier;
    else
      ;
    end;
    {$ENDIF}
  end;
end;

function atomic_compare_exchange_strong(var aObj: PtrUInt; var aExpected: PtrUInt; aDesired: PtrUInt;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := atomic_compare_exchange_strong(PPtrInt(@aObj)^, PPtrInt(@aExpected)^, PPtrInt(@aDesired)^,
    aSuccessOrder, aFailureOrder);
  {$POP}
end;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_compare_exchange_strong_64(var aObj: Int64; var aExpected: Int64; aDesired: Int64;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean;
{$IF NOT (DEFINED(CPUX86) AND NOT DEFINED(CPU64))}
var
  LOld: Int64;
{$ENDIF}
begin
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aSuccessOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  else
    ;
  end;
  {$ENDIF}

  {$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}
  if not _atomic_cmpxchg_64_x86(aObj, aExpected, aDesired) then
  begin
    Result := False;
    {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
    case aFailureOrder of
      mo_seq_cst:
        ReadWriteBarrier;
      mo_consume, mo_acquire, mo_acq_rel:
        ReadBarrier;
    else
      ;
    end;
    {$ENDIF}
    Exit;
  end;
  Result := True;
  {$ELSE}
  LOld := InterlockedCompareExchange64(aObj, aDesired, aExpected);
  Result := (LOld = aExpected);

  if not Result then
  begin
    aExpected := LOld;
    {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
    case aFailureOrder of
      mo_seq_cst:
        ReadWriteBarrier;
      mo_consume, mo_acquire, mo_acq_rel:
        ReadBarrier;
    else
      ;
    end;
    {$ENDIF}
    Exit;
  end;
  {$ENDIF}

  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aSuccessOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_consume, mo_acquire, mo_acq_rel:
      ReadBarrier;
  else
    ;
  end;
  {$ENDIF}
end;

function atomic_compare_exchange_strong_64(var aObj: UInt64; var aExpected: UInt64; aDesired: UInt64;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := atomic_compare_exchange_strong_64(PInt64(@aObj)^, PInt64(@aExpected)^, PInt64(@aDesired)^,
    aSuccessOrder, aFailureOrder);
  {$POP}
end;
{$ENDIF}

function atomic_compare_exchange_strong(var aObj: Pointer; var aExpected: Pointer; aDesired: Pointer;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  {$IF SIZEOF(Pointer) = 4}
  Result := atomic_compare_exchange_strong(PInt32(@aObj)^, PInt32(@aExpected)^, PInt32(@aDesired)^,
    aSuccessOrder, aFailureOrder);
  {$ELSE}
  Result := atomic_compare_exchange_strong_64(PInt64(@aObj)^, PInt64(@aExpected)^, PInt64(@aDesired)^,
    aSuccessOrder, aFailureOrder);
  {$ENDIF}
  {$POP}
end;

// weak 版本 - 在 x86 上与 strong 相同，但语义上允许虚假失败
function atomic_compare_exchange_weak(var aObj: Int32; var aExpected: Int32; aDesired: Int32;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean;
begin
  Result := atomic_compare_exchange_strong(aObj, aExpected, aDesired, aSuccessOrder, aFailureOrder);
end;

function atomic_compare_exchange_weak(var aObj: UInt32; var aExpected: UInt32; aDesired: UInt32;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean;
begin
  Result := atomic_compare_exchange_strong(aObj, aExpected, aDesired, aSuccessOrder, aFailureOrder);
end;

{$IFDEF CPU64}
function atomic_compare_exchange_weak(var aObj: PtrInt; var aExpected: PtrInt; aDesired: PtrInt;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean;
begin
  Result := atomic_compare_exchange_strong(aObj, aExpected, aDesired, aSuccessOrder, aFailureOrder);
end;

function atomic_compare_exchange_weak(var aObj: PtrUInt; var aExpected: PtrUInt; aDesired: PtrUInt;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean;
begin
  Result := atomic_compare_exchange_strong(aObj, aExpected, aDesired, aSuccessOrder, aFailureOrder);
end;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_compare_exchange_weak_64(var aObj: Int64; var aExpected: Int64; aDesired: Int64;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean;
begin
  Result := atomic_compare_exchange_strong_64(aObj, aExpected, aDesired, aSuccessOrder, aFailureOrder);
end;

function atomic_compare_exchange_weak_64(var aObj: UInt64; var aExpected: UInt64; aDesired: UInt64;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean;
begin
  Result := atomic_compare_exchange_strong_64(aObj, aExpected, aDesired, aSuccessOrder, aFailureOrder);
end;
{$ENDIF}

function atomic_compare_exchange_weak(var aObj: Pointer; var aExpected: Pointer; aDesired: Pointer;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean;
begin
  Result := atomic_compare_exchange_strong(aObj, aExpected, aDesired, aSuccessOrder, aFailureOrder);
end;

function atomic_increment(var aObj: Int32): Int32;
begin
  // Convenience API: seq_cst.
  Result := atomic_fetch_add(aObj, 1, mo_seq_cst) + 1;
end;

function atomic_increment(var aObj: UInt32): UInt32;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt32(atomic_increment(PInt32(@aObj)^));
  {$POP}
end;

{$IFDEF CPU64}
function atomic_increment(var aObj: PtrInt): PtrInt;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  {$IF SIZEOF(PtrInt) = 4}
    Result := PtrInt(atomic_increment(PInt32(@aObj)^));
  {$ELSE}
    Result := PtrInt(atomic_increment_64(PInt64(@aObj)^));
  {$ENDIF}
  {$POP}
end;

function atomic_increment(var aObj: PtrUInt): PtrUInt;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  {$IF SIZEOF(PtrInt) = 4}
    Result := PtrUInt(atomic_increment(PInt32(@aObj)^));
  {$ELSE}
    Result := PtrUInt(atomic_increment_64(PInt64(@aObj)^));
  {$ENDIF}
  {$POP}
end;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_decrement_64(var aObj: Int64): Int64;
begin
  // Convenience API: seq_cst.
  Result := atomic_fetch_add_64(aObj, -1, mo_seq_cst) - 1;
end;

function atomic_decrement_64(var aObj: UInt64): UInt64;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt64(atomic_decrement_64(PInt64(@aObj)^));
  {$POP}
end;
{$ENDIF}

function atomic_decrement(var aObj: Int32): Int32;
begin
  // Convenience API: seq_cst.
  Result := atomic_fetch_add(aObj, -1, mo_seq_cst) - 1;
end;

function atomic_decrement(var aObj: UInt32): UInt32;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt32(atomic_decrement(PInt32(@aObj)^));
  {$POP}
end;

{$IFDEF CPU64}
function atomic_decrement(var aObj: PtrInt): PtrInt;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  {$IF SIZEOF(PtrInt) = 4}
    Result := PtrInt(atomic_decrement(PInt32(@aObj)^));
  {$ELSE}
    Result := PtrInt(atomic_decrement_64(PInt64(@aObj)^));
  {$ENDIF}
  {$POP}
end;

function atomic_decrement(var aObj: PtrUInt): PtrUInt;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := PtrUInt(atomic_decrement(PPtrInt(@aObj)^));
  {$POP}
end;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_fetch_add_64(var aObj: Int64; aArg: Int64): Int64;
begin
  // Default is seq_cst.
  Result := atomic_fetch_add_64(aObj, aArg, mo_seq_cst);
end;

function atomic_fetch_add_64(var aObj: UInt64; aArg: UInt64): UInt64;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt64(atomic_fetch_add_64(PInt64(@aObj)^, PInt64(@aArg)^, mo_seq_cst));
  {$POP}
end;
{$ENDIF}

function atomic_fetch_add(var aObj: Int32; aArg: Int32): Int32;
begin
  // Default is seq_cst.
  Result := atomic_fetch_add(aObj, aArg, mo_seq_cst);
end;

function atomic_fetch_add(var aObj: UInt32; aArg: UInt32): UInt32;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt32(atomic_fetch_add(PInt32(@aObj)^, PInt32(@aArg)^, mo_seq_cst));
  {$POP}
end;

{$IFDEF CPU64}
function atomic_fetch_add(var aObj: PtrInt; aArg: PtrInt): PtrInt;
begin
  {$IF SIZEOF(PtrInt) = 4}
    Result := PtrInt(atomic_fetch_add(PInt32(@aObj)^, PInt32(@aArg)^, mo_seq_cst));
  {$ELSE}
    Result := PtrInt(atomic_fetch_add_64(PInt64(@aObj)^, PInt64(@aArg)^, mo_seq_cst));
  {$ENDIF}
end;

function atomic_fetch_add(var aObj: PtrUInt; aArg: PtrUInt): PtrUInt;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := PtrUInt(atomic_fetch_add(PPtrInt(@aObj)^, PPtrInt(@aArg)^, mo_seq_cst));
  {$POP}
end;
{$ENDIF}

function atomic_fetch_add(var aObj: Pointer; aOffset: PtrInt): Pointer;
begin
  {$PUSH}
  {$WARN 4055 OFF} // Conversion between ordinals and pointers is not portable
  {$IF SIZEOF(Pointer) = 4}
    Result := Pointer(atomic_fetch_add(PInt32(@aObj)^, PInt32(@aOffset)^));
  {$ELSE}
    Result := Pointer(atomic_fetch_add_64(PInt64(@aObj)^, PInt64(@aOffset)^));
  {$ENDIF}
  {$POP}
end;

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_fetch_sub_64(var aObj: Int64; aArg: Int64): Int64;
begin
  Result := atomic_fetch_add_64(aObj, -aArg);
end;

function atomic_fetch_sub_64(var aObj: UInt64; aArg: UInt64): UInt64;
begin
  Result := UInt64(atomic_fetch_sub_64(PInt64(@aObj)^, PInt64(@aArg)^));
end;
{$ENDIF}

function atomic_fetch_sub(var aObj: Int32; aArg: Int32): Int32;
begin
  Result := atomic_fetch_add(aObj, -aArg);
end;

function atomic_fetch_sub(var aObj: UInt32; aArg: UInt32): UInt32;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt32(atomic_fetch_sub(PInt32(@aObj)^, PInt32(@aArg)^));
  {$POP}
end;

{$IFDEF CPU64}
function atomic_fetch_sub(var aObj: PtrInt; aArg: PtrInt): PtrInt;
begin
  {$IF SIZEOF(PtrInt) = 4}
    Result := PtrInt(atomic_fetch_sub(PInt32(@aObj)^, PInt32(@aArg)^));
  {$ELSE}
    Result := PtrInt(atomic_fetch_sub_64(PInt64(@aObj)^, PInt64(@aArg)^));
  {$ENDIF}
end;

function atomic_fetch_sub(var aObj: PtrUInt; aArg: PtrUInt): PtrUInt;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := PtrUInt(atomic_fetch_sub(PPtrInt(@aObj)^, PPtrInt(@aArg)^));
  {$POP}
end;
{$ENDIF}

function atomic_fetch_sub(var aObj: Pointer; aOffset: PtrInt): Pointer;
begin
  Result := atomic_fetch_add(aObj, -aOffset);
end;

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_fetch_and_64(var aObj: Int64; aArg: Int64): Int64;
begin
  // Default is seq_cst.
  Result := atomic_fetch_and_64(aObj, aArg, mo_seq_cst);
end;

function atomic_fetch_and_64(var aObj: UInt64; aArg: UInt64): UInt64;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt64(atomic_fetch_and_64(PInt64(@aObj)^, PInt64(@aArg)^, mo_seq_cst));
  {$POP}
end;
{$ENDIF}

function atomic_fetch_and(var aObj: Int32; aArg: Int32): Int32;
begin
  // Keep the legacy no-order API, but route through the order-aware implementation
  // so we get consistent backoff (cpu_pause) behavior.
  Result := atomic_fetch_and(aObj, aArg, mo_seq_cst);
end;

function atomic_fetch_and(var aObj: UInt32; aArg: UInt32): UInt32;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt32(atomic_fetch_and(PInt32(@aObj)^, PInt32(@aArg)^));
  {$POP}
end;

{$IFDEF CPU64}
function atomic_fetch_and(var aObj: PtrInt; aArg: PtrInt): PtrInt;
begin
  {$IF SIZEOF(PtrInt) = 4}
    Result := PtrInt(atomic_fetch_and(PInt32(@aObj)^, PInt32(@aArg)^));
  {$ELSE}
    Result := PtrInt(atomic_fetch_and_64(PInt64(@aObj)^, PInt64(@aArg)^));
  {$ENDIF}
end;

function atomic_fetch_and(var aObj: PtrUInt; aArg: PtrUInt): PtrUInt;
begin
  Result := PtrUInt(atomic_fetch_and(PPtrInt(@aObj)^, PtrInt(aArg)));
end;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_fetch_or_64(var aObj: Int64; aArg: Int64): Int64;
begin
  // Default is seq_cst.
  Result := atomic_fetch_or_64(aObj, aArg, mo_seq_cst);
end;

function atomic_fetch_or_64(var aObj: UInt64; aArg: UInt64): UInt64;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt64(atomic_fetch_or_64(PInt64(@aObj)^, PInt64(@aArg)^, mo_seq_cst));
  {$POP}
end;
{$ENDIF}

function atomic_fetch_or(var aObj: Int32; aArg: Int32): Int32;
begin
  Result := atomic_fetch_or(aObj, aArg, mo_seq_cst);
end;

function atomic_fetch_or(var aObj: UInt32; aArg: UInt32): UInt32;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt32(atomic_fetch_or(PInt32(@aObj)^, PInt32(@aArg)^));
  {$POP}
end;

{$IFDEF CPU64}
function atomic_fetch_or(var aObj: PtrInt; aArg: PtrInt): PtrInt;
begin
  {$IF SIZEOF(PtrInt) = 4}
    Result := PtrInt(atomic_fetch_or(PInt32(@aObj)^, PInt32(@aArg)^));
  {$ELSE}
    Result := PtrInt(atomic_fetch_or_64(PInt64(@aObj)^, PInt64(@aArg)^));
  {$ENDIF}
end;

function atomic_fetch_or(var aObj: PtrUInt; aArg: PtrUInt): PtrUInt;
begin
  Result := PtrUInt(atomic_fetch_or(PPtrInt(@aObj)^, PtrInt(aArg)));
end;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_fetch_xor_64(var aObj: Int64; aArg: Int64): Int64;
begin
  // Default is seq_cst.
  Result := atomic_fetch_xor_64(aObj, aArg, mo_seq_cst);
end;

function atomic_fetch_xor_64(var aObj: UInt64; aArg: UInt64): UInt64;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt64(atomic_fetch_xor_64(PInt64(@aObj)^, PInt64(@aArg)^, mo_seq_cst));
  {$POP}
end;
{$ENDIF}

function atomic_fetch_xor(var aObj: Int32; aArg: Int32): Int32;
begin
  Result := atomic_fetch_xor(aObj, aArg, mo_seq_cst);
end;

function atomic_fetch_xor(var aObj: UInt32; aArg: UInt32): UInt32;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt32(atomic_fetch_xor(PInt32(@aObj)^, PInt32(@aArg)^));
  {$POP}
end;

{$IFDEF CPU64}
function atomic_fetch_xor(var aObj: PtrInt; aArg: PtrInt): PtrInt;
begin
  {$IF SIZEOF(PtrInt) = 4}
    Result := PtrInt(atomic_fetch_xor(PInt32(@aObj)^, PInt32(@aArg)^));
  {$ELSE}
    Result := PtrInt(atomic_fetch_xor_64(PInt64(@aObj)^, PInt64(@aArg)^));
  {$ENDIF}
end;

function atomic_fetch_xor(var aObj: PtrUInt; aArg: PtrUInt): PtrUInt;
begin
  Result := PtrUInt(atomic_fetch_xor(PPtrInt(@aObj)^, PtrInt(aArg)));
end;
{$ENDIF}

//┌────────────────────────────────────────────────────────────────────────────┐
//│              Phase 3: atomic_fetch_* 带 memory_order 参数实现              │
//└────────────────────────────────────────────────────────────────────────────┘

// ✅ Phase 3: atomic_fetch_add 带 memory_order 参数
function atomic_fetch_add(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32;
begin
  // x86/x86_64: InterlockedExchangeAdd uses LOCK XADD and already provides a full fence.
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  else
    ;
  end;
  {$ENDIF}

  Result := InterlockedExchangeAdd(aObj, aArg);

  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_consume, mo_acquire, mo_acq_rel:
      ReadBarrier;
  else
    ;
  end;
  {$ENDIF}
end;

function atomic_fetch_add(var aObj: UInt32; aArg: UInt32; aOrder: memory_order_t): UInt32;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt32(atomic_fetch_add(PInt32(@aObj)^, PInt32(@aArg)^, aOrder));
  {$POP}
end;

{$IFDEF CPU64}
function atomic_fetch_add(var aObj: PtrInt; aArg: PtrInt; aOrder: memory_order_t): PtrInt;
begin
  {$IF SIZEOF(PtrInt) = 4}
    Result := PtrInt(atomic_fetch_add(PInt32(@aObj)^, PInt32(@aArg)^, aOrder));
  {$ELSE}
    Result := PtrInt(atomic_fetch_add_64(PInt64(@aObj)^, PInt64(@aArg)^, aOrder));
  {$ENDIF}
end;

function atomic_fetch_add(var aObj: PtrUInt; aArg: PtrUInt; aOrder: memory_order_t): PtrUInt;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := PtrUInt(atomic_fetch_add(PPtrInt(@aObj)^, PPtrInt(@aArg)^, aOrder));
  {$POP}
end;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_fetch_add_64(var aObj: Int64; aArg: Int64; aOrder: memory_order_t): Int64;
begin
  // x86/x86_64: locked RMW already provides a full fence.
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  else
    ;
  end;
  {$ENDIF}

  {$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}
  Result := _atomic_fetch_add_64_x86(aObj, aArg);
  {$ELSE}
  Result := InterlockedExchangeAdd64(aObj, aArg);
  {$ENDIF}

  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_consume, mo_acquire, mo_acq_rel:
      ReadBarrier;
  else
    ;
  end;
  {$ENDIF}
end;

function atomic_fetch_add_64(var aObj: UInt64; aArg: UInt64; aOrder: memory_order_t): UInt64;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt64(atomic_fetch_add_64(PInt64(@aObj)^, PInt64(@aArg)^, aOrder));
  {$POP}
end;
{$ENDIF}

// ✅ Phase 3: atomic_fetch_sub 带 memory_order 参数
function atomic_fetch_sub(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32;
begin
  Result := atomic_fetch_add(aObj, -aArg, aOrder);
end;

function atomic_fetch_sub(var aObj: UInt32; aArg: UInt32; aOrder: memory_order_t): UInt32;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt32(atomic_fetch_sub(PInt32(@aObj)^, PInt32(@aArg)^, aOrder));
  {$POP}
end;

{$IFDEF CPU64}
function atomic_fetch_sub(var aObj: PtrInt; aArg: PtrInt; aOrder: memory_order_t): PtrInt;
begin
  {$IF SIZEOF(PtrInt) = 4}
    Result := PtrInt(atomic_fetch_sub(PInt32(@aObj)^, PInt32(@aArg)^, aOrder));
  {$ELSE}
    Result := PtrInt(atomic_fetch_sub_64(PInt64(@aObj)^, PInt64(@aArg)^, aOrder));
  {$ENDIF}
end;

function atomic_fetch_sub(var aObj: PtrUInt; aArg: PtrUInt; aOrder: memory_order_t): PtrUInt;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := PtrUInt(atomic_fetch_sub(PPtrInt(@aObj)^, PPtrInt(@aArg)^, aOrder));
  {$POP}
end;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_fetch_sub_64(var aObj: Int64; aArg: Int64; aOrder: memory_order_t): Int64;
begin
  Result := atomic_fetch_add_64(aObj, -aArg, aOrder);
end;

function atomic_fetch_sub_64(var aObj: UInt64; aArg: UInt64; aOrder: memory_order_t): UInt64;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt64(atomic_fetch_sub_64(PInt64(@aObj)^, PInt64(@aArg)^, aOrder));
  {$POP}
end;
{$ENDIF}

// ✅ Phase 3: atomic_fetch_and 带 memory_order 参数
// ✅ Phase 3 优化: x86 LOCK CMPXCHG 隐含全屏障，无需额外 barrier
function atomic_fetch_and(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32;
var
  LOld, LNew: Int32;
begin
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  else
    ;
  end;
  {$ENDIF}
  repeat
    LOld := aObj;
    LNew := LOld and aArg;
    if InterlockedCompareExchange(aObj, LNew, LOld) = LOld then
      Break;
    cpu_pause;
  until False;
  Result := LOld;
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_consume, mo_acquire, mo_acq_rel:
      ReadBarrier;
  else
    ;
  end;
  {$ENDIF}
end;

function atomic_fetch_and(var aObj: UInt32; aArg: UInt32; aOrder: memory_order_t): UInt32;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt32(atomic_fetch_and(PInt32(@aObj)^, PInt32(@aArg)^, aOrder));
  {$POP}
end;

{$IFDEF CPU64}
function atomic_fetch_and(var aObj: PtrInt; aArg: PtrInt; aOrder: memory_order_t): PtrInt;
begin
  {$IF SIZEOF(PtrInt) = 4}
    Result := PtrInt(atomic_fetch_and(PInt32(@aObj)^, PInt32(@aArg)^, aOrder));
  {$ELSE}
    Result := PtrInt(atomic_fetch_and_64(PInt64(@aObj)^, PInt64(@aArg)^, aOrder));
  {$ENDIF}
end;

function atomic_fetch_and(var aObj: PtrUInt; aArg: PtrUInt; aOrder: memory_order_t): PtrUInt;
begin
  Result := PtrUInt(atomic_fetch_and(PPtrInt(@aObj)^, PtrInt(aArg), aOrder));
end;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
// ✅ Phase 3 优化: x86 LOCK CMPXCHG 隐含全屏障
function atomic_fetch_and_64(var aObj: Int64; aArg: Int64; aOrder: memory_order_t): Int64;
var
  LOld, LNew: Int64;
begin
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  end;
  {$ENDIF}
  repeat
    LOld := {$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}_atomic_load_64_x86(aObj){$ELSE}aObj{$ENDIF};
    LNew := LOld and aArg;
    {$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}
    if _atomic_cmpxchg_64_x86(aObj, LOld, LNew) then
      Break;
    {$ELSE}
    if InterlockedCompareExchange64(aObj, LNew, LOld) = LOld then
      Break;
    {$ENDIF}
    cpu_pause;
  until False;
  Result := LOld;
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_consume, mo_acquire, mo_acq_rel:
      ReadBarrier;
  end;
  {$ENDIF}
end;

function atomic_fetch_and_64(var aObj: UInt64; aArg: UInt64; aOrder: memory_order_t): UInt64;
begin
  Result := UInt64(atomic_fetch_and_64(PInt64(@aObj)^, PInt64(@aArg)^, aOrder));
end;
{$ENDIF}

// ✅ Phase 3: atomic_fetch_or 带 memory_order 参数
// ✅ Phase 3 优化: x86 LOCK CMPXCHG 隐含全屏障
function atomic_fetch_or(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32;
var
  LOld, LNew: Int32;
begin
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  end;
  {$ENDIF}
  repeat
    LOld := aObj;
    LNew := LOld or aArg;
    if InterlockedCompareExchange(aObj, LNew, LOld) = LOld then
      Break;
    cpu_pause;
  until False;
  Result := LOld;
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_consume, mo_acquire, mo_acq_rel:
      ReadBarrier;
  end;
  {$ENDIF}
end;

function atomic_fetch_or(var aObj: UInt32; aArg: UInt32; aOrder: memory_order_t): UInt32;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt32(atomic_fetch_or(PInt32(@aObj)^, PInt32(@aArg)^, aOrder));
  {$POP}
end;

{$IFDEF CPU64}
function atomic_fetch_or(var aObj: PtrInt; aArg: PtrInt; aOrder: memory_order_t): PtrInt;
begin
  {$IF SIZEOF(PtrInt) = 4}
    Result := PtrInt(atomic_fetch_or(PInt32(@aObj)^, PInt32(@aArg)^, aOrder));
  {$ELSE}
    Result := PtrInt(atomic_fetch_or_64(PInt64(@aObj)^, PInt64(@aArg)^, aOrder));
  {$ENDIF}
end;

function atomic_fetch_or(var aObj: PtrUInt; aArg: PtrUInt; aOrder: memory_order_t): PtrUInt;
begin
  Result := PtrUInt(atomic_fetch_or(PPtrInt(@aObj)^, PtrInt(aArg), aOrder));
end;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
// ✅ Phase 3 优化: x86 LOCK CMPXCHG 隐含全屏障
function atomic_fetch_or_64(var aObj: Int64; aArg: Int64; aOrder: memory_order_t): Int64;
var
  LOld, LNew: Int64;
begin
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  end;
  {$ENDIF}
  repeat
    LOld := {$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}_atomic_load_64_x86(aObj){$ELSE}aObj{$ENDIF};
    LNew := LOld or aArg;
    {$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}
    if _atomic_cmpxchg_64_x86(aObj, LOld, LNew) then
      Break;
    {$ELSE}
    if InterlockedCompareExchange64(aObj, LNew, LOld) = LOld then
      Break;
    {$ENDIF}
    cpu_pause;
  until False;
  Result := LOld;
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_consume, mo_acquire, mo_acq_rel:
      ReadBarrier;
  end;
  {$ENDIF}
end;

function atomic_fetch_or_64(var aObj: UInt64; aArg: UInt64; aOrder: memory_order_t): UInt64;
begin
  Result := UInt64(atomic_fetch_or_64(PInt64(@aObj)^, PInt64(@aArg)^, aOrder));
end;
{$ENDIF}

// ✅ Phase 3: atomic_fetch_xor 带 memory_order 参数
// ✅ Phase 3 优化: x86 LOCK CMPXCHG 隐含全屏障
function atomic_fetch_xor(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32;
var
  LOld, LNew: Int32;
begin
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  end;
  {$ENDIF}
  repeat
    LOld := aObj;
    LNew := LOld xor aArg;
    if InterlockedCompareExchange(aObj, LNew, LOld) = LOld then
      Break;
    cpu_pause;
  until False;
  Result := LOld;
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_consume, mo_acquire, mo_acq_rel:
      ReadBarrier;
  end;
  {$ENDIF}
end;

function atomic_fetch_xor(var aObj: UInt32; aArg: UInt32; aOrder: memory_order_t): UInt32;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  Result := UInt32(atomic_fetch_xor(PInt32(@aObj)^, PInt32(@aArg)^, aOrder));
  {$POP}
end;

{$IFDEF CPU64}
function atomic_fetch_xor(var aObj: PtrInt; aArg: PtrInt; aOrder: memory_order_t): PtrInt;
begin
  {$IF SIZEOF(PtrInt) = 4}
    Result := PtrInt(atomic_fetch_xor(PInt32(@aObj)^, PInt32(@aArg)^, aOrder));
  {$ELSE}
    Result := PtrInt(atomic_fetch_xor_64(PInt64(@aObj)^, PInt64(@aArg)^, aOrder));
  {$ENDIF}
end;

function atomic_fetch_xor(var aObj: PtrUInt; aArg: PtrUInt; aOrder: memory_order_t): PtrUInt;
begin
  Result := PtrUInt(atomic_fetch_xor(PPtrInt(@aObj)^, PtrInt(aArg), aOrder));
end;
{$ENDIF}

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
// ✅ Phase 3 优化: x86 LOCK CMPXCHG 隐含全屏障
function atomic_fetch_xor_64(var aObj: Int64; aArg: Int64; aOrder: memory_order_t): Int64;
var
  LOld, LNew: Int64;
begin
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  end;
  {$ENDIF}
  repeat
    LOld := {$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}_atomic_load_64_x86(aObj){$ELSE}aObj{$ENDIF};
    LNew := LOld xor aArg;
    {$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}
    if _atomic_cmpxchg_64_x86(aObj, LOld, LNew) then
      Break;
    {$ELSE}
    if InterlockedCompareExchange64(aObj, LNew, LOld) = LOld then
      Break;
    {$ENDIF}
    cpu_pause;
  until False;
  Result := LOld;
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_consume, mo_acquire, mo_acq_rel:
      ReadBarrier;
  end;
  {$ENDIF}
end;

function atomic_fetch_xor_64(var aObj: UInt64; aArg: UInt64; aOrder: memory_order_t): UInt64;
begin
  Result := UInt64(atomic_fetch_xor_64(PInt64(@aObj)^, PInt64(@aArg)^, aOrder));
end;
{$ENDIF}

//┌────────────────────────────────────────────────────────────────────────────┐
//│              Phase 3: atomic_fetch_max / min / nand 新增操作               │
//└────────────────────────────────────────────────────────────────────────────┘

// ✅ Phase 3: atomic_fetch_max - 返回旧值，存储 max(old, arg)
// ✅ Phase 3 优化: x86 LOCK CMPXCHG 隐含全屏障
function atomic_fetch_max(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32;
var
  LOld, LNew: Int32;
begin
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  end;
  {$ENDIF}
  repeat
    LOld := aObj;
    if aArg > LOld then
      LNew := aArg
    else
      LNew := LOld;
    if InterlockedCompareExchange(aObj, LNew, LOld) = LOld then
      Break;
    cpu_pause;
  until False;
  Result := LOld;
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_consume, mo_acquire, mo_acq_rel:
      ReadBarrier;
  end;
  {$ENDIF}
end;

function atomic_fetch_max(var aObj: Int32; aArg: Int32): Int32;
begin
  Result := atomic_fetch_max(aObj, aArg, mo_seq_cst);
end;

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
// ✅ Phase 3 优化: x86 LOCK CMPXCHG 隐含全屏障
function atomic_fetch_max_64(var aObj: Int64; aArg: Int64; aOrder: memory_order_t): Int64;
var
  LOld, LNew: Int64;
begin
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  end;
  {$ENDIF}
  repeat
    LOld := {$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}_atomic_load_64_x86(aObj){$ELSE}aObj{$ENDIF};
    if aArg > LOld then
      LNew := aArg
    else
      LNew := LOld;
    {$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}
    if _atomic_cmpxchg_64_x86(aObj, LOld, LNew) then
      Break;
    {$ELSE}
    if InterlockedCompareExchange64(aObj, LNew, LOld) = LOld then
      Break;
    {$ENDIF}
    cpu_pause;
  until False;
  Result := LOld;
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_consume, mo_acquire, mo_acq_rel:
      ReadBarrier;
  end;
  {$ENDIF}
end;

function atomic_fetch_max_64(var aObj: Int64; aArg: Int64): Int64;
begin
  Result := atomic_fetch_max_64(aObj, aArg, mo_seq_cst);
end;
{$ENDIF}

// ✅ Phase 3: atomic_fetch_min - 返回旧值，存储 min(old, arg)
// ✅ Phase 3 优化: x86 LOCK CMPXCHG 隐含全屏障
function atomic_fetch_min(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32;
var
  LOld, LNew: Int32;
begin
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  end;
  {$ENDIF}
  repeat
    LOld := aObj;
    if aArg < LOld then
      LNew := aArg
    else
      LNew := LOld;
    if InterlockedCompareExchange(aObj, LNew, LOld) = LOld then
      Break;
    cpu_pause;
  until False;
  Result := LOld;
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_consume, mo_acquire, mo_acq_rel:
      ReadBarrier;
  end;
  {$ENDIF}
end;

function atomic_fetch_min(var aObj: Int32; aArg: Int32): Int32;
begin
  Result := atomic_fetch_min(aObj, aArg, mo_seq_cst);
end;

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
// ✅ Phase 3 优化: x86 LOCK CMPXCHG 隐含全屏障
function atomic_fetch_min_64(var aObj: Int64; aArg: Int64; aOrder: memory_order_t): Int64;
var
  LOld, LNew: Int64;
begin
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  end;
  {$ENDIF}
  repeat
    LOld := {$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}_atomic_load_64_x86(aObj){$ELSE}aObj{$ENDIF};
    if aArg < LOld then
      LNew := aArg
    else
      LNew := LOld;
    {$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}
    if _atomic_cmpxchg_64_x86(aObj, LOld, LNew) then
      Break;
    {$ELSE}
    if InterlockedCompareExchange64(aObj, LNew, LOld) = LOld then
      Break;
    {$ENDIF}
    cpu_pause;
  until False;
  Result := LOld;
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_consume, mo_acquire, mo_acq_rel:
      ReadBarrier;
  end;
  {$ENDIF}
end;

function atomic_fetch_min_64(var aObj: Int64; aArg: Int64): Int64;
begin
  Result := atomic_fetch_min_64(aObj, aArg, mo_seq_cst);
end;
{$ENDIF}

// ✅ Phase 3: atomic_fetch_nand - 返回旧值，存储 NOT(old AND arg)
// ✅ Phase 3 优化: x86 LOCK CMPXCHG 隐含全屏障
function atomic_fetch_nand(var aObj: Int32; aArg: Int32; aOrder: memory_order_t): Int32;
var
  LOld, LNew: Int32;
begin
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  end;
  {$ENDIF}
  repeat
    LOld := aObj;
    LNew := not (LOld and aArg);
    if InterlockedCompareExchange(aObj, LNew, LOld) = LOld then
      Break;
    cpu_pause;
  until False;
  Result := LOld;
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_consume, mo_acquire, mo_acq_rel:
      ReadBarrier;
  end;
  {$ENDIF}
end;

function atomic_fetch_nand(var aObj: Int32; aArg: Int32): Int32;
begin
  Result := atomic_fetch_nand(aObj, aArg, mo_seq_cst);
end;

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
// ✅ Phase 3 优化: x86 LOCK CMPXCHG 隐含全屏障
function atomic_fetch_nand_64(var aObj: Int64; aArg: Int64; aOrder: memory_order_t): Int64;
var
  LOld, LNew: Int64;
begin
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_release, mo_acq_rel:
      WriteBarrier;
  end;
  {$ENDIF}
  repeat
    LOld := {$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}_atomic_load_64_x86(aObj){$ELSE}aObj{$ENDIF};
    LNew := not (LOld and aArg);
    {$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}
    if _atomic_cmpxchg_64_x86(aObj, LOld, LNew) then
      Break;
    {$ELSE}
    if InterlockedCompareExchange64(aObj, LNew, LOld) = LOld then
      Break;
    {$ENDIF}
    cpu_pause;
  until False;
  Result := LOld;
  {$IF NOT (DEFINED(CPUX86_64) OR DEFINED(CPUX86))}
  case aOrder of
    mo_seq_cst:
      ReadWriteBarrier;
    mo_consume, mo_acquire, mo_acq_rel:
      ReadBarrier;
  end;
  {$ENDIF}
end;

function atomic_fetch_nand_64(var aObj: Int64; aArg: Int64): Int64;
begin
  Result := atomic_fetch_nand_64(aObj, aArg, mo_seq_cst);
end;
{$ENDIF}

function atomic_flag_test_and_set(var aFlag: atomic_flag_t): Boolean;
begin
  // C11 atomic_flag_test_and_set has seq_cst semantics by default.
  Result := (atomic_exchange(PInt32(@aFlag)^, 1, mo_seq_cst) <> 0);
end;

function atomic_flag_test(var aFlag: atomic_flag_t): Boolean;
begin
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386)}
    Result := atomic_load(PInt32(@aFlag)^, mo_relaxed) <> 0;
  {$ELSE} // ARM / ARM64 / PPC / RISC-V
    Result := atomic_load(PInt32(@aFlag)^, mo_acquire) <> 0;
  {$ENDIF}
end;

procedure atomic_flag_clear(var aFlag: atomic_flag_t);
begin
  // C11 atomic_flag_clear has seq_cst semantics by default.
  atomic_store(PInt32(@aFlag)^, 0, mo_seq_cst);
end;

function atomic_is_lock_free_32: Boolean;
begin
  {$IF DEFINED(CPUI386) OR DEFINED(CPUX86_64) 
     OR DEFINED(CPUARM) OR DEFINED(CPUAARCH64)
     OR DEFINED(CPUMIPS) OR DEFINED(CPUMIPSEL)
     OR DEFINED(CPUMIPS64) OR DEFINED(CPUMIPS64EL)
     OR DEFINED(CPURISCV32) OR DEFINED(CPURISCV64)
     OR DEFINED(CPUPPC) OR DEFINED(CPUPPC64)}
    Result := True;
  {$ELSE}
    Result := False;
  {$ENDIF}

end;

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
function atomic_is_lock_free_64: Boolean;
begin
  {$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}
    Result := gAtomic64HasCmpxchg8b;
  {$ELSEIF DEFINED(CPUX86_64) OR DEFINED(CPUAARCH64)
     OR DEFINED(CPUMIPS64) OR DEFINED(CPUMIPS64EL)
     OR DEFINED(CPURISCV64) OR DEFINED(CPUPPC64)}
    Result := True;
  {$ELSE}
    Result := False;
  {$ENDIF}
end;
{$ENDIF}

function atomic_is_lock_free_ptr: Boolean;
begin
  {$IF SIZEOF(Pointer) = 4}
    Result := atomic_is_lock_free_32;
  {$ELSE}
    Result := atomic_is_lock_free_64;
  {$ENDIF}
end;

{$IF DEFINED(CPUX86_64)}
const
  // x86_64: pointers are effectively 48-bit canonical in user-space; keep 16-bit tag in high bits.
  TAG_BITS  = 16;
  TAG_SHIFT = 48;
  PTR_MASK: PtrUInt = PtrUInt($0000FFFFFFFFFFFF); // low 48 bits pointer, high 16 bits tag
{$ELSE}
const
  // Other targets: avoid assuming 48-bit pointers (AArch64 can be 52-bit, etc.).
  // Use low TAG_BITS bits for the tag; this requires pointers to be aligned accordingly.
  {$IFDEF CPU64}
  TAG_BITS = FAFAFA_ATOMIC_TAG_BITS_64; // default=3; requires pointer alignment to 2^TAG_BITS
  {$ELSE}
  TAG_BITS = FAFAFA_ATOMIC_TAG_BITS_32; // default=2; requires pointer alignment to 2^TAG_BITS
  {$ENDIF}
  TAG_MASK: PtrUInt = (PtrUInt(1) shl TAG_BITS) - 1;
  // NOTE: Keep this expression self-contained for older FPC constant folding (e.g. 3.2.2/i386).
  // Compute a mask with low TAG_BITS cleared without producing signed intermediates (e.g. -4 on i386).
  PTR_MASK: PtrUInt = ((PtrUInt(1) shl (SizeOf(PtrUInt) * 8 - TAG_BITS)) - 1) shl TAG_BITS;
{$ENDIF}

function atomic_tagged_ptr(aPtr: Pointer; aTag: {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF}): atomic_tagged_ptr_t;
begin
  {$PUSH}
  {$WARN 4055 OFF}

  {$IFDEF FAFAFA_ATOMIC_TAGGED_PTR_CHECKS}
    {$IF DEFINED(CPUX86_64)}
      // High-tag scheme requires pointer to fit in the preserved low bits.
      Assert((PtrUInt(aPtr) and (not PTR_MASK)) = 0, 'atomic_tagged_ptr: pointer out of range for x86_64 packing');
    {$ELSE}
      // Low-tag scheme requires pointer alignment and tag to fit TAG_BITS.
      Assert((PtrUInt(aPtr) and TAG_MASK) = 0, 'atomic_tagged_ptr: pointer not aligned for low-bit tag packing');
      Assert((PtrUInt(aTag) and (not TAG_MASK)) = 0, 'atomic_tagged_ptr: tag does not fit TAG_BITS');
    {$ENDIF}
  {$ENDIF}

  {$IF DEFINED(CPUX86_64)}
  Result := (PtrUInt(aPtr) and PTR_MASK) or (PtrUInt(aTag) shl TAG_SHIFT);
  {$ELSE}
  Result := (PtrUInt(aPtr) and PTR_MASK) or (PtrUInt(aTag) and TAG_MASK);
  {$ENDIF}
  {$POP}
end;

function atomic_tagged_ptr_get_ptr(const aTaggedPtr: atomic_tagged_ptr_t): Pointer;
begin
  {$PUSH}
  {$WARN 4055 OFF} // Conversion between ordinals and pointers is not portable
  Result := Pointer(PtrUInt(aTaggedPtr) and PTR_MASK);
  {$POP}
end;

function atomic_tagged_ptr_get_tag(const aTaggedPtr: atomic_tagged_ptr_t): {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};
begin
  {$IF DEFINED(CPUX86_64)}
  Result := UInt16(PtrUInt(aTaggedPtr) shr TAG_SHIFT);
  {$ELSEIF DEFINED(CPU64)}
  Result := UInt16(PtrUInt(aTaggedPtr) and TAG_MASK);
  {$ELSE}
  Result := UInt32(PtrUInt(aTaggedPtr) and TAG_MASK);
  {$ENDIF}
end;

function atomic_tagged_ptr_load(var aObj: atomic_tagged_ptr_t; aOrder: memory_order_t): atomic_tagged_ptr_t;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  {$IF SIZEOF(Pointer) = 4}
    PInt32(@Result)^ := atomic_load(PInt32(@aObj)^, aOrder);
  {$ELSE}
    PInt64(@Result)^ := atomic_load_64(PInt64(@aObj)^, aOrder);
  {$ENDIF}
  {$POP}
end;

function atomic_tagged_ptr_load(var aObj: atomic_tagged_ptr_t): atomic_tagged_ptr_t;
begin
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86)}
    Result := atomic_tagged_ptr_load(aObj, mo_relaxed);
  {$ELSE}
    Result := atomic_tagged_ptr_load(aObj, mo_acquire);
  {$ENDIF}
end;

procedure atomic_tagged_ptr_store(var aObj: atomic_tagged_ptr_t; aDesired: atomic_tagged_ptr_t; aOrder: memory_order_t);
begin
  {$PUSH}
  {$WARN 4055 OFF}
  {$IF SIZEOF(Pointer) = 4}
    atomic_store(PInt32(@aObj)^, PInt32(@aDesired)^, aOrder);
  {$ELSE}
    atomic_store_64(PInt64(@aObj)^, PInt64(@aDesired)^, aOrder);
  {$ENDIF}
  {$POP}
end;

procedure atomic_tagged_ptr_store(var aObj: atomic_tagged_ptr_t; aDesired: atomic_tagged_ptr_t);
begin
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUX86)}
    atomic_tagged_ptr_store(aObj, aDesired, mo_relaxed);
  {$ELSE}
    atomic_tagged_ptr_store(aObj, aDesired, mo_release);
  {$ENDIF}
end;

function atomic_tagged_ptr_exchange(var aObj: atomic_tagged_ptr_t; aDesired: atomic_tagged_ptr_t; aOrder: memory_order_t): atomic_tagged_ptr_t;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  {$IF SIZEOF(Pointer) = 4}
    PInt32(@Result)^ := atomic_exchange(PInt32(@aObj)^, PInt32(@aDesired)^, aOrder);
  {$ELSE}
    PInt64(@Result)^ := atomic_exchange_64(PInt64(@aObj)^, PInt64(@aDesired)^, aOrder);
  {$ENDIF}
  {$POP}
end;

function atomic_tagged_ptr_exchange(var aObj: atomic_tagged_ptr_t; aDesired: atomic_tagged_ptr_t): atomic_tagged_ptr_t;
begin
  // Default is seq_cst.
  Result := atomic_tagged_ptr_exchange(aObj, aDesired, mo_seq_cst);
end;

function atomic_tagged_ptr_compare_exchange_strong(var aObj: atomic_tagged_ptr_t; var aExpected: atomic_tagged_ptr_t; aDesired: atomic_tagged_ptr_t;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean;
var
  LExpected32: Int32;
  LExpected64: Int64;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  {$IF SIZEOF(Pointer) = 4}
    LExpected32 := PInt32(@aExpected)^;
    Result := atomic_compare_exchange_strong(PInt32(@aObj)^, LExpected32, PInt32(@aDesired)^, aSuccessOrder, aFailureOrder);
    PInt32(@aExpected)^ := LExpected32;
  {$ELSE}
    LExpected64 := PInt64(@aExpected)^;
    Result := atomic_compare_exchange_strong_64(PInt64(@aObj)^, LExpected64, PInt64(@aDesired)^, aSuccessOrder, aFailureOrder);
    PInt64(@aExpected)^ := LExpected64;
  {$ENDIF}
  {$POP}
end;

function atomic_tagged_ptr_compare_exchange_strong(var aObj: atomic_tagged_ptr_t; var aExpected: atomic_tagged_ptr_t; aDesired: atomic_tagged_ptr_t): Boolean;
begin
  // Default is seq_cst.
  Result := atomic_tagged_ptr_compare_exchange_strong(aObj, aExpected, aDesired, mo_seq_cst, mo_seq_cst);
end;

function atomic_tagged_ptr_compare_exchange_weak(var aObj: atomic_tagged_ptr_t; var aExpected: atomic_tagged_ptr_t; aDesired: atomic_tagged_ptr_t;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean;
var
  LExpected32: Int32;
  LExpected64: Int64;
begin
  {$PUSH}
  {$WARN 4055 OFF}
  {$IF SIZEOF(Pointer) = 4}
    LExpected32 := PInt32(@aExpected)^;
    Result := atomic_compare_exchange_weak(PInt32(@aObj)^, LExpected32, PInt32(@aDesired)^, aSuccessOrder, aFailureOrder);
    PInt32(@aExpected)^ := LExpected32;
  {$ELSE}
    LExpected64 := PInt64(@aExpected)^;
    Result := atomic_compare_exchange_weak_64(PInt64(@aObj)^, LExpected64, PInt64(@aDesired)^, aSuccessOrder, aFailureOrder);
    PInt64(@aExpected)^ := LExpected64;
  {$ENDIF}
  {$POP}
end;

function atomic_tagged_ptr_compare_exchange_weak(var aObj: atomic_tagged_ptr_t; var aExpected: atomic_tagged_ptr_t; aDesired: atomic_tagged_ptr_t): Boolean;
begin
  // Default is seq_cst.
  Result := atomic_tagged_ptr_compare_exchange_weak(aObj, aExpected, aDesired, mo_seq_cst, mo_seq_cst);
end;

// ------------------- memory fence -------------------
procedure atomic_thread_fence(aOrder: memory_order_t);
begin
 case aOrder of
    mo_relaxed:;                       // 不产生任何屏障
    mo_consume: ReadBarrier;           // 当前实现：按 acquire 处理
    mo_acquire: ReadBarrier;           // 读取屏障，防止 acquire 后续读取重排到前面
    mo_release: WriteBarrier;          // 写入屏障，防止 release 前写入重排到后面
    mo_acq_rel: ReadWriteBarrier;      // 同时防止前后读取和写入重排
    mo_seq_cst: ReadWriteBarrier;      // 最强顺序，保证全序
  end;
end;

const
  {$IF DEFINED(CPUX86_64)}
  MAX_TAG: UInt16 = $FFFF;
  {$ELSEIF DEFINED(CPU64)}
  MAX_TAG: UInt16 = UInt16((PtrUInt(1) shl TAG_BITS) - 1);
  {$ELSE}
  MAX_TAG: UInt32 = UInt32((PtrUInt(1) shl TAG_BITS) - 1);
  {$ENDIF}

function atomic_tagged_ptr_next(const aTaggedPtr: atomic_tagged_ptr_t): {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};
var
  LTag: {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};
begin
  LTag := atomic_tagged_ptr_get_tag(aTaggedPtr);
  if LTag = MAX_TAG then
    Result := 1
  else
    Result := LTag + 1;
end;

procedure atomic_tagged_ptr_update(var aObj: atomic_tagged_ptr_t; aPtr: Pointer); inline;
var
  LOld, LNewV: atomic_tagged_ptr_t;
begin
  repeat
    LOld  := atomic_tagged_ptr_load(aObj);
    LNewV := atomic_tagged_ptr(aPtr, atomic_tagged_ptr_next(LOld));
    if atomic_tagged_ptr_compare_exchange_weak(aObj, LOld, LNewV) then
      Break;
    cpu_pause;
  until False;
end;

procedure atomic_tagged_ptr_update_tag(var aObj: atomic_tagged_ptr_t; aTag: {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF}); inline;
var
  LOldTagged: atomic_tagged_ptr_t;
  LNewTagged: atomic_tagged_ptr_t;
  LOldPtr: Pointer;
begin
  repeat
    LOldTagged := atomic_tagged_ptr_load(aObj);
    LOldPtr    := atomic_tagged_ptr_get_ptr(LOldTagged);
    LNewTagged := atomic_tagged_ptr(LOldPtr, aTag);
    if atomic_tagged_ptr_compare_exchange_strong(aObj, LOldTagged, LNewTagged) then
      Break;
    cpu_pause;
  until False;
end;

{$IF DEFINED(CPUX86) AND NOT DEFINED(CPU64)}
initialization
  {$IFDEF FAFAFA_ATOMIC_FORCE_NO_CMPXCHG8B}
  gAtomic64HasCmpxchg8b := False;
  {$ELSE}
  gAtomic64HasCmpxchg8b := _x86_has_cmpxchg8b;
  {$ENDIF}
{$ENDIF}

end.
