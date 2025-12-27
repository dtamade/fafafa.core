unit fafafa.core.simd.dispatch;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.cpuinfo;

// === Dispatch System ===

// Initialize the dispatch system (called automatically)
procedure InitializeDispatch;

// Get current active backend
function GetActiveBackend: TSimdBackend;

// Force a specific backend (for testing)
// ✅ P1: 添加安全性检查 - 如果后端不可用则回退到 Scalar
procedure SetActiveBackend(backend: TSimdBackend);

// Try to set a specific backend, returns True if successful
// ✅ P1: 新增函数 - 允许调用者检查是否成功
function TrySetActiveBackend(backend: TSimdBackend): Boolean;

// Check if a backend is available on current CPU
function IsBackendAvailableOnCPU(backend: TSimdBackend): Boolean;

// Reset to automatic backend selection
procedure ResetToAutomaticBackend;

// === SIMD Vector ASM Feature Toggle ===
// ✅ P1-E: SIMD vector ASM implementations are enabled by default.
// To disable at compile-time, define SIMD_VECTOR_ASM_DISABLED.
// To disable at runtime, call SetVectorAsmEnabled(False).
function IsVectorAsmEnabled: Boolean;
procedure SetVectorAsmEnabled(enabled: Boolean);

// === Dispatch Change Hook ===
// Used by higher-level facades to bind a fast access path once per (re)initialization.
type
  TSimdDispatchChangedHook = procedure;

// Set a hook that will be called after dispatch (re)initialization completes.
// If dispatch is already initialized, the hook will be invoked immediately.
procedure SetDispatchChangedHook(hook: TSimdDispatchChangedHook);

// === Backend Rebuilder Registration ===
// ⚠️ DEPRECATED: The rebuilder mechanism has been removed for thread safety.
// VectorAsm setting is now only effective before dispatch initialization.
// Use compile-time {$DEFINE SIMD_VECTOR_ASM_DISABLED} to disable vector asm.
type
  TBackendRebuilder = procedure;

// DEPRECATED: This procedure is now a no-op for backward compatibility.
// Rebuilders are no longer called at runtime.
procedure RegisterBackendRebuilder(backend: TSimdBackend; rebuilder: TBackendRebuilder);

// === Function Dispatch Tables ===
type
  // Dispatch table for all SIMD operations
  TSimdDispatchTable = record
    // Backend information
    Backend: TSimdBackend;
    BackendInfo: TSimdBackendInfo;
    
    // Arithmetic operations - F32x4
    AddF32x4: function(const a, b: TVecF32x4): TVecF32x4;
    SubF32x4: function(const a, b: TVecF32x4): TVecF32x4;
    MulF32x4: function(const a, b: TVecF32x4): TVecF32x4;
    DivF32x4: function(const a, b: TVecF32x4): TVecF32x4;
    
    // Arithmetic operations - F32x8
    AddF32x8: function(const a, b: TVecF32x8): TVecF32x8;
    SubF32x8: function(const a, b: TVecF32x8): TVecF32x8;
    MulF32x8: function(const a, b: TVecF32x8): TVecF32x8;
    DivF32x8: function(const a, b: TVecF32x8): TVecF32x8;
    
    // Arithmetic operations - F64x2
    AddF64x2: function(const a, b: TVecF64x2): TVecF64x2;
    SubF64x2: function(const a, b: TVecF64x2): TVecF64x2;
    MulF64x2: function(const a, b: TVecF64x2): TVecF64x2;
    DivF64x2: function(const a, b: TVecF64x2): TVecF64x2;
    
    // Arithmetic operations - I32x4
    AddI32x4: function(const a, b: TVecI32x4): TVecI32x4;
    SubI32x4: function(const a, b: TVecI32x4): TVecI32x4;
    MulI32x4: function(const a, b: TVecI32x4): TVecI32x4;
    // Bitwise operations - I32x4
    AndI32x4: function(const a, b: TVecI32x4): TVecI32x4;
    OrI32x4: function(const a, b: TVecI32x4): TVecI32x4;
    XorI32x4: function(const a, b: TVecI32x4): TVecI32x4;
    NotI32x4: function(const a: TVecI32x4): TVecI32x4;
    AndNotI32x4: function(const a, b: TVecI32x4): TVecI32x4;
    // Shift operations - I32x4
    ShiftLeftI32x4: function(const a: TVecI32x4; count: Integer): TVecI32x4;
    ShiftRightI32x4: function(const a: TVecI32x4; count: Integer): TVecI32x4;
    ShiftRightArithI32x4: function(const a: TVecI32x4; count: Integer): TVecI32x4;
    // Comparison operations - I32x4
    CmpEqI32x4: function(const a, b: TVecI32x4): TMask4;
    CmpLtI32x4: function(const a, b: TVecI32x4): TMask4;
    CmpGtI32x4: function(const a, b: TVecI32x4): TMask4;
    CmpLeI32x4: function(const a, b: TVecI32x4): TMask4;  // ✅ P0-5: Added
    CmpGeI32x4: function(const a, b: TVecI32x4): TMask4;  // ✅ P0-5: Added
    CmpNeI32x4: function(const a, b: TVecI32x4): TMask4;  // ✅ P0-5: Added
    // Min/Max operations - I32x4
    MinI32x4: function(const a, b: TVecI32x4): TVecI32x4;
    MaxI32x4: function(const a, b: TVecI32x4): TVecI32x4;

    // Arithmetic operations - I64x2 (P1.3)
    AddI64x2: function(const a, b: TVecI64x2): TVecI64x2;
    SubI64x2: function(const a, b: TVecI64x2): TVecI64x2;
    AndI64x2: function(const a, b: TVecI64x2): TVecI64x2;
    OrI64x2: function(const a, b: TVecI64x2): TVecI64x2;
    XorI64x2: function(const a, b: TVecI64x2): TVecI64x2;
    NotI64x2: function(const a: TVecI64x2): TVecI64x2;
    // Comparison operations - I64x2 (✅ P0-5: Added)
    CmpEqI64x2: function(const a, b: TVecI64x2): TMask2;
    CmpLtI64x2: function(const a, b: TVecI64x2): TMask2;
    CmpGtI64x2: function(const a, b: TVecI64x2): TMask2;
    CmpLeI64x2: function(const a, b: TVecI64x2): TMask2;
    CmpGeI64x2: function(const a, b: TVecI64x2): TMask2;
    CmpNeI64x2: function(const a, b: TVecI64x2): TMask2;

    // Arithmetic operations - F64x4 (256-bit AVX)
    AddF64x4: function(const a, b: TVecF64x4): TVecF64x4;
    SubF64x4: function(const a, b: TVecF64x4): TVecF64x4;
    MulF64x4: function(const a, b: TVecF64x4): TVecF64x4;
    DivF64x4: function(const a, b: TVecF64x4): TVecF64x4;

    // Arithmetic operations - I32x8 (256-bit AVX)
    AddI32x8: function(const a, b: TVecI32x8): TVecI32x8;
    SubI32x8: function(const a, b: TVecI32x8): TVecI32x8;
    MulI32x8: function(const a, b: TVecI32x8): TVecI32x8;
    AndI32x8: function(const a, b: TVecI32x8): TVecI32x8;
    OrI32x8: function(const a, b: TVecI32x8): TVecI32x8;
    XorI32x8: function(const a, b: TVecI32x8): TVecI32x8;
    NotI32x8: function(const a: TVecI32x8): TVecI32x8;
    AndNotI32x8: function(const a, b: TVecI32x8): TVecI32x8;
    // Shift operations - I32x8
    ShiftLeftI32x8: function(const a: TVecI32x8; count: Integer): TVecI32x8;
    ShiftRightI32x8: function(const a: TVecI32x8; count: Integer): TVecI32x8;
    ShiftRightArithI32x8: function(const a: TVecI32x8; count: Integer): TVecI32x8;
    // Comparison operations - I32x8
    CmpEqI32x8: function(const a, b: TVecI32x8): TMask8;
    CmpLtI32x8: function(const a, b: TVecI32x8): TMask8;
    CmpGtI32x8: function(const a, b: TVecI32x8): TMask8;
    CmpLeI32x8: function(const a, b: TVecI32x8): TMask8;  // ✅ P0-5: Added
    CmpGeI32x8: function(const a, b: TVecI32x8): TMask8;  // ✅ P0-5: Added
    CmpNeI32x8: function(const a, b: TVecI32x8): TMask8;  // ✅ P0-5: Added
    // Min/Max operations - I32x8
    MinI32x8: function(const a, b: TVecI32x8): TVecI32x8;
    MaxI32x8: function(const a, b: TVecI32x8): TVecI32x8;

    // Arithmetic operations - I32x16 (512-bit AVX-512)
    AddI32x16: function(const a, b: TVecI32x16): TVecI32x16;
    SubI32x16: function(const a, b: TVecI32x16): TVecI32x16;
    MulI32x16: function(const a, b: TVecI32x16): TVecI32x16;
    AndI32x16: function(const a, b: TVecI32x16): TVecI32x16;
    OrI32x16: function(const a, b: TVecI32x16): TVecI32x16;
    XorI32x16: function(const a, b: TVecI32x16): TVecI32x16;
    NotI32x16: function(const a: TVecI32x16): TVecI32x16;
    AndNotI32x16: function(const a, b: TVecI32x16): TVecI32x16;
    // Shift operations - I32x16
    ShiftLeftI32x16: function(const a: TVecI32x16; count: Integer): TVecI32x16;
    ShiftRightI32x16: function(const a: TVecI32x16; count: Integer): TVecI32x16;
    ShiftRightArithI32x16: function(const a: TVecI32x16; count: Integer): TVecI32x16;
    // Comparison operations - I32x16
    CmpEqI32x16: function(const a, b: TVecI32x16): TMask16;
    CmpLtI32x16: function(const a, b: TVecI32x16): TMask16;
    CmpGtI32x16: function(const a, b: TVecI32x16): TMask16;
    CmpLeI32x16: function(const a, b: TVecI32x16): TMask16;  // ✅ P0-5: Added
    CmpGeI32x16: function(const a, b: TVecI32x16): TMask16;  // ✅ P0-5: Added
    CmpNeI32x16: function(const a, b: TVecI32x16): TMask16;  // ✅ P0-5: Added
    // Min/Max operations - I32x16
    MinI32x16: function(const a, b: TVecI32x16): TVecI32x16;
    MaxI32x16: function(const a, b: TVecI32x16): TVecI32x16;

    // Arithmetic operations - F32x16 (512-bit AVX-512)
    AddF32x16: function(const a, b: TVecF32x16): TVecF32x16;
    SubF32x16: function(const a, b: TVecF32x16): TVecF32x16;
    MulF32x16: function(const a, b: TVecF32x16): TVecF32x16;
    DivF32x16: function(const a, b: TVecF32x16): TVecF32x16;

    // Arithmetic operations - F64x8 (512-bit AVX-512)
    AddF64x8: function(const a, b: TVecF64x8): TVecF64x8;
    SubF64x8: function(const a, b: TVecF64x8): TVecF64x8;
    MulF64x8: function(const a, b: TVecF64x8): TVecF64x8;
    DivF64x8: function(const a, b: TVecF64x8): TVecF64x8;

    // Comparison operations
    CmpEqF32x4: function(const a, b: TVecF32x4): TMask4;
    CmpLtF32x4: function(const a, b: TVecF32x4): TMask4;
    CmpLeF32x4: function(const a, b: TVecF32x4): TMask4;
    CmpGtF32x4: function(const a, b: TVecF32x4): TMask4;
    CmpGeF32x4: function(const a, b: TVecF32x4): TMask4;
    CmpNeF32x4: function(const a, b: TVecF32x4): TMask4;

    // ✅ P1-E: F64x2 比较操作 - 修复派发缺失
    CmpEqF64x2: function(const a, b: TVecF64x2): TMask2;
    CmpLtF64x2: function(const a, b: TVecF64x2): TMask2;
    CmpLeF64x2: function(const a, b: TVecF64x2): TMask2;
    CmpGtF64x2: function(const a, b: TVecF64x2): TMask2;
    CmpGeF64x2: function(const a, b: TVecF64x2): TMask2;
    CmpNeF64x2: function(const a, b: TVecF64x2): TMask2;
    
    // Math functions
    AbsF32x4: function(const a: TVecF32x4): TVecF32x4;
    SqrtF32x4: function(const a: TVecF32x4): TVecF32x4;
    MinF32x4: function(const a, b: TVecF32x4): TVecF32x4;
    MaxF32x4: function(const a, b: TVecF32x4): TVecF32x4;
    
    // Extended math functions
    FmaF32x4: function(const a, b, c: TVecF32x4): TVecF32x4;   // a*b+c
    RcpF32x4: function(const a: TVecF32x4): TVecF32x4;          // 1/x (approximate)
    RsqrtF32x4: function(const a: TVecF32x4): TVecF32x4;        // 1/sqrt(x) (approximate)
    FloorF32x4: function(const a: TVecF32x4): TVecF32x4;
    CeilF32x4: function(const a: TVecF32x4): TVecF32x4;
    RoundF32x4: function(const a: TVecF32x4): TVecF32x4;
    TruncF32x4: function(const a: TVecF32x4): TVecF32x4;
    ClampF32x4: function(const a, minVal, maxVal: TVecF32x4): TVecF32x4;

    // ✅ P1-4: Wide vector extended math functions
    // F64x2 (128-bit)
    FmaF64x2: function(const a, b, c: TVecF64x2): TVecF64x2;
    FloorF64x2: function(const a: TVecF64x2): TVecF64x2;
    CeilF64x2: function(const a: TVecF64x2): TVecF64x2;
    RoundF64x2: function(const a: TVecF64x2): TVecF64x2;
    TruncF64x2: function(const a: TVecF64x2): TVecF64x2;
    // F32x8 (256-bit)
    FmaF32x8: function(const a, b, c: TVecF32x8): TVecF32x8;
    FloorF32x8: function(const a: TVecF32x8): TVecF32x8;
    CeilF32x8: function(const a: TVecF32x8): TVecF32x8;
    RoundF32x8: function(const a: TVecF32x8): TVecF32x8;
    TruncF32x8: function(const a: TVecF32x8): TVecF32x8;
    // F64x4 (256-bit)
    FmaF64x4: function(const a, b, c: TVecF64x4): TVecF64x4;
    FloorF64x4: function(const a: TVecF64x4): TVecF64x4;
    CeilF64x4: function(const a: TVecF64x4): TVecF64x4;
    RoundF64x4: function(const a: TVecF64x4): TVecF64x4;
    TruncF64x4: function(const a: TVecF64x4): TVecF64x4;

    // 3D/4D Vector math
    DotF32x4: function(const a, b: TVecF32x4): Single;          // Dot product (4 elements)
    DotF32x3: function(const a, b: TVecF32x4): Single;          // Dot product (3 elements)
    CrossF32x3: function(const a, b: TVecF32x4): TVecF32x4;     // Cross product (uses x,y,z)
    LengthF32x4: function(const a: TVecF32x4): Single;          // Length (4 elements)
    LengthF32x3: function(const a: TVecF32x4): Single;          // Length (3 elements)
    NormalizeF32x4: function(const a: TVecF32x4): TVecF32x4;    // Normalize (4 elements)
    NormalizeF32x3: function(const a: TVecF32x4): TVecF32x4;    // Normalize (3 elements, w=0)
    
    // Reduction operations
    ReduceAddF32x4: function(const a: TVecF32x4): Single;
    ReduceMinF32x4: function(const a: TVecF32x4): Single;
    ReduceMaxF32x4: function(const a: TVecF32x4): Single;
    ReduceMulF32x4: function(const a: TVecF32x4): Single;
    
    // Memory operations
    LoadF32x4: function(p: PSingle): TVecF32x4;
    LoadF32x4Aligned: function(p: PSingle): TVecF32x4;
    StoreF32x4: procedure(p: PSingle; const a: TVecF32x4);
    StoreF32x4Aligned: procedure(p: PSingle; const a: TVecF32x4);
    
    // Utility operations
    SplatF32x4: function(value: Single): TVecF32x4;
    ZeroF32x4: function: TVecF32x4;
    SelectF32x4: function(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4;
    ExtractF32x4: function(const a: TVecF32x4; index: Integer): Single;
    InsertF32x4: function(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;

    // ✅ P1-5: Wide vector Load/Store/Splat/Zero
    // F64x2 (128-bit)
    LoadF64x2: function(p: PDouble): TVecF64x2;
    StoreF64x2: procedure(p: PDouble; const a: TVecF64x2);
    SplatF64x2: function(value: Double): TVecF64x2;
    ZeroF64x2: function: TVecF64x2;
    // F32x8 (256-bit)
    LoadF32x8: function(p: PSingle): TVecF32x8;
    StoreF32x8: procedure(p: PSingle; const a: TVecF32x8);
    SplatF32x8: function(value: Single): TVecF32x8;
    ZeroF32x8: function: TVecF32x8;
    // F64x4 (256-bit)
    LoadF64x4: function(p: PDouble): TVecF64x4;
    StoreF64x4: procedure(p: PDouble; const a: TVecF64x4);
    SplatF64x4: function(value: Double): TVecF64x4;
    ZeroF64x4: function: TVecF64x4;

    // === Facade Functions (High-Level API) ===
    // Memory operations
    MemEqual: function(a, b: Pointer; len: SizeUInt): LongBool;
    MemFindByte: function(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
    MemDiffRange: function(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
    MemCopy: procedure(src, dst: Pointer; len: SizeUInt);
    MemSet: procedure(dst: Pointer; len: SizeUInt; value: Byte);
    MemReverse: procedure(p: Pointer; len: SizeUInt);
    
    // Statistics functions
    SumBytes: function(p: Pointer; len: SizeUInt): UInt64;
    MinMaxBytes: procedure(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
    CountByte: function(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;
    
    // Text processing functions
    Utf8Validate: function(p: Pointer; len: SizeUInt): Boolean;
    AsciiIEqual: function(a, b: Pointer; len: SizeUInt): Boolean;
    ToLowerAscii: procedure(p: Pointer; len: SizeUInt);
    ToUpperAscii: procedure(p: Pointer; len: SizeUInt);
    
    // Search functions
    BytesIndexOf: function(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;
    
    // Bitset functions
    BitsetPopCount: function(p: Pointer; byteLen: SizeUInt): SizeUInt;

    // ✅ P2-1: Saturating Arithmetic (音视频处理必需)
    // 有符号饱和 (I8: [-128, 127], I16: [-32768, 32767])
    I8x16SatAdd: function(const a, b: TVecI8x16): TVecI8x16;
    I8x16SatSub: function(const a, b: TVecI8x16): TVecI8x16;
    I16x8SatAdd: function(const a, b: TVecI16x8): TVecI16x8;
    I16x8SatSub: function(const a, b: TVecI16x8): TVecI16x8;
    // 无符号饱和 (U8: [0, 255], U16: [0, 65535])
    U8x16SatAdd: function(const a, b: TVecU8x16): TVecU8x16;
    U8x16SatSub: function(const a, b: TVecU8x16): TVecU8x16;
    U16x8SatAdd: function(const a, b: TVecU16x8): TVecU16x8;
    U16x8SatSub: function(const a, b: TVecU16x8): TVecU16x8;

    // ✅ P2-2: Mask 类型操作 (条件分支优化)
    // TMask2 操作 (2 元素)
    Mask2All: function(mask: TMask2): Boolean;
    Mask2Any: function(mask: TMask2): Boolean;
    Mask2None: function(mask: TMask2): Boolean;
    Mask2PopCount: function(mask: TMask2): Integer;
    Mask2FirstSet: function(mask: TMask2): Integer;  // -1 if none
    // TMask4 操作 (4 元素)
    Mask4All: function(mask: TMask4): Boolean;
    Mask4Any: function(mask: TMask4): Boolean;
    Mask4None: function(mask: TMask4): Boolean;
    Mask4PopCount: function(mask: TMask4): Integer;
    Mask4FirstSet: function(mask: TMask4): Integer;  // -1 if none
    // TMask8 操作 (8 元素)
    Mask8All: function(mask: TMask8): Boolean;
    Mask8Any: function(mask: TMask8): Boolean;
    Mask8None: function(mask: TMask8): Boolean;
    Mask8PopCount: function(mask: TMask8): Integer;
    Mask8FirstSet: function(mask: TMask8): Integer;  // -1 if none
    // TMask16 操作 (16 元素)
    Mask16All: function(mask: TMask16): Boolean;
    Mask16Any: function(mask: TMask16): Boolean;
    Mask16None: function(mask: TMask16): Boolean;
    Mask16PopCount: function(mask: TMask16): Integer;
    Mask16FirstSet: function(mask: TMask16): Integer;  // -1 if none

    // ✅ P2-3: F64x2 Select 操作
    SelectF64x2: function(const mask: TMask2; const a, b: TVecF64x2): TVecF64x2;
  end;

// Pointer to dispatch table
type
  PSimdDispatchTable = ^TSimdDispatchTable;

// Get current dispatch table
function GetDispatchTable: PSimdDispatchTable;

// === Backend Registration ===

// Register a backend implementation
procedure RegisterBackend(backend: TSimdBackend; const dispatchTable: TSimdDispatchTable);

// Check if backend is registered
function IsBackendRegistered(backend: TSimdBackend): Boolean;

// Get backend info
function GetBackendInfo(backend: TSimdBackend): TSimdBackendInfo;

// === Dispatch Table Helpers ===

{**
 * ValidateDispatchTable
 *
 * @desc
 *   Validates that all function pointers in a dispatch table are non-nil.
 *   This is a critical safety check to ensure no nil pointer dereferences.
 *   验证派发表中所有函数指针都非 nil。
 *   这是确保不会发生 nil 指针解引用的关键安全检查。
 *
 * @param dispatchTable
 *   The dispatch table to validate.
 *   要验证的派发表。
 *
 * @returns
 *   True if all function pointers are non-nil, False otherwise.
 *   如果所有函数指针都非 nil 返回 True，否则返回 False。
 *}
function ValidateDispatchTable(const dispatchTable: TSimdDispatchTable): Boolean;

{**
 * AssertDispatchTableValid
 *
 * @desc
 *   Asserts that all function pointers in a dispatch table are non-nil.
 *   Raises an assertion error in debug builds if validation fails.
 *   断言派发表中所有函数指针都非 nil。
 *   在调试构建中，如果验证失败则引发断言错误。
 *
 * @param dispatchTable
 *   The dispatch table to validate.
 *   要验证的派发表。
 *
 * @param backendName
 *   Name of the backend for error reporting.
 *   用于错误报告的后端名称。
 *}
procedure AssertDispatchTableValid(const dispatchTable: TSimdDispatchTable; const backendName: string);

{**
 * FillBaseDispatchTable
 *
 * @desc
 *   Fills a dispatch table with scalar reference implementations for all operations.
 *   This provides a complete baseline that SIMD backends can override selectively.
 *   填充派发表，使用标量参考实现作为所有操作的基础。
 *   为 SIMD 后端提供完整的基线，以便它们可以选择性地覆盖。
 *
 * @note
 *   Call this before setting backend-specific implementations.
 *   Backend info is NOT set by this function - caller must set it.
 *   在设置后端特定实现之前调用此函数。
 *   此函数不设置后端信息 - 调用者必须自行设置。
 *}
procedure FillBaseDispatchTable(var dispatchTable: TSimdDispatchTable);

{**
 * CloneDispatchTable
 *
 * @desc
 *   Clones a dispatch table from an already registered backend.
 *   This allows tier backends (SSE3/SSSE3/SSE4.1/SSE4.2) to inherit
 *   implementations from a lower tier (SSE2) instead of starting from scalar.
 *   从已注册的后端克隆派发表。
 *   这允许 tier 后端（SSE3/SSSE3/SSE4.1/SSE4.2）从低级后端（SSE2）
 *   继承实现，而不是从标量基线开始。
 *
 * @param fromBackend
 *   The backend to clone from. Must be already registered.
 *   要克隆的源后端。必须已注册。
 *
 * @param dispatchTable
 *   The dispatch table to fill with cloned implementations.
 *   要填充克隆实现的派发表。
 *
 * @returns
 *   True if clone succeeded (source backend was registered), False otherwise.
 *   如果克隆成功（源后端已注册）返回 True，否则返回 False。
 *
 * @note
 *   If the source backend is not registered, falls back to FillBaseDispatchTable.
 *   Backend info is NOT copied - caller must set it appropriately.
 *   如果源后端未注册，回退到 FillBaseDispatchTable。
 *   后端信息不会被复制 - 调用者必须自行设置。
 *}
function CloneDispatchTable(fromBackend: TSimdBackend; var dispatchTable: TSimdDispatchTable): Boolean;

implementation

uses
  SysUtils,
  fafafa.core.simd.scalar,
  fafafa.core.simd.sync;  // For memory barriers in thread-safe backend switching

var
  // Current active dispatch table
  g_CurrentDispatch: PSimdDispatchTable;
  
  // Registered backend dispatch tables
  g_BackendTables: array[TSimdBackend] of TSimdDispatchTable;
  g_BackendRegistered: array[TSimdBackend] of Boolean;
  
  // Initialization state
  g_DispatchInitialized: Boolean = False;
  g_DispatchState: LongInt = 0;  // ✅ 0=未初始化, 1=初始化中, 2=已完成
  g_ForcedBackend: TSimdBackend;
  g_BackendForced: Boolean = False;

  // Optional callback invoked after (re)initialization completes.
  g_DispatchChangedHook: TSimdDispatchChangedHook = nil;

  // Feature toggles
  // ✅ P1-E: 默认启用 SIMD 向量操作
  // 如需禁用，编译时定义 SIMD_VECTOR_ASM_DISABLED
  {$IFNDEF SIMD_VECTOR_ASM_DISABLED}
  g_VectorAsmEnabled: Boolean = True;
  {$ELSE}
  g_VectorAsmEnabled: Boolean = False;
  {$ENDIF}

  // ⚠️ REMOVED: g_BackendRebuilders array - rebuilder mechanism deprecated for thread safety

// === Initialization ===

const
  // Backend priority array: highest performance first
  // SSE family: SSE4.2 > SSE4.1 > SSSE3 > SSE3 > SSE2
  // Each higher version includes all previous capabilities plus new instructions
  BACKEND_PRIORITY: array[0..9] of TSimdBackend = (
    sbAVX512,   // 512-bit SIMD (highest priority for x86)
    sbAVX2,     // 256-bit SIMD
    sbSSE42,    // CRC32, string ops, PCMPGTQ
    sbSSE41,    // DPPS, ROUNDPS, PMULLD, BLENDV
    sbSSSE3,    // PSHUFB, PABS, PALIGNR
    sbSSE3,     // HADD, MOVDDUP
    sbSSE2,     // Base 128-bit SIMD for x86-64
    sbNEON,     // ARM SIMD
    sbRISCVV,   // RISC-V Vector Extension
    sbScalar    // Fallback (always available)
  );

function IsBackendAvailable(b: TSimdBackend; const backends: array of TSimdBackend): Boolean;
var
  j: Integer;
begin
  Result := False;
  for j := 0 to High(backends) do
    if backends[j] = b then
      Exit(True);
end;

// ✅ Thread-safe dispatch initialization using atomic operations
procedure DoInitializeDispatch;
var
  bestBackend: TSimdBackend;
  backends: array of TSimdBackend;
  i: Integer;
  oldState: LongInt;
begin
  // 快速路径: 已完成初始化
  if g_DispatchState = 2 then
    Exit;

  oldState := InterlockedCompareExchange(g_DispatchState, 1, 0);
  if oldState = 0 then
  begin
    // 我们是第一个初始化者
    // Note: Do NOT reset g_BackendRegistered here!
    // Backends register themselves during unit initialization,
    // and we don't want to lose that registration.

    // Find best available backend
    if g_BackendForced then
    begin
      bestBackend := g_ForcedBackend;
      if not IsBackendRegistered(bestBackend) then
        bestBackend := sbScalar;
    end
    else
    begin
      backends := GetAvailableBackends;
      bestBackend := sbScalar;

      for i := Low(BACKEND_PRIORITY) to High(BACKEND_PRIORITY) do
      begin
        if IsBackendRegistered(BACKEND_PRIORITY[i]) and
           IsBackendAvailable(BACKEND_PRIORITY[i], backends) then
        begin
          bestBackend := BACKEND_PRIORITY[i];
          Break;
        end;
      end;
    end;

    // Set active dispatch table
    if IsBackendRegistered(bestBackend) then
      g_CurrentDispatch := @g_BackendTables[bestBackend]
    else
      g_CurrentDispatch := nil;

    g_DispatchInitialized := True;
    WriteBarrier;
    InterlockedExchange(g_DispatchState, 2);

    // Notify listeners after dispatch state is fully published.
    if Assigned(g_DispatchChangedHook) then
      g_DispatchChangedHook;
  end
  else if oldState = 1 then
  begin
    // 另一个线程正在初始化，自旋等待
    while g_DispatchState <> 2 do
    begin
      ReadBarrier;
      ThreadSwitch;
    end;
  end;
  // oldState = 2: 已完成，直接返回
end;

procedure InitializeDispatch;
begin
  // Always call DoInitializeDispatch - it has its own guard
  DoInitializeDispatch;
end;

// === Public Interface ===

function GetActiveBackend: TSimdBackend;
begin
  InitializeDispatch;
  if g_CurrentDispatch <> nil then
    Result := g_CurrentDispatch^.Backend
  else
    Result := sbScalar;
end;

// ✅ P1: Check if a backend is available on current CPU
function IsBackendAvailableOnCPU(backend: TSimdBackend): Boolean;
var
  backends: array of TSimdBackend;
  i: Integer;
begin
  // Scalar is always available
  if backend = sbScalar then
    Exit(True);

  backends := GetAvailableBackends;
  for i := 0 to High(backends) do
    if backends[i] = backend then
      Exit(True);
  Result := False;
end;

// ✅ P1: TrySetActiveBackend - returns True if backend was successfully set
function TrySetActiveBackend(backend: TSimdBackend): Boolean;
begin
  // Check if backend is both registered and available on CPU
  if not IsBackendRegistered(backend) then
    Exit(False);

  if not IsBackendAvailableOnCPU(backend) then
    Exit(False);

  // Backend is valid, force it
  g_ForcedBackend := backend;
  g_BackendForced := True;
  WriteBarrier;
  g_DispatchInitialized := False;
  InterlockedExchange(g_DispatchState, 0);
  MemoryBarrier;
  InitializeDispatch;
  Result := True;
end;

// ✅ P1: SetActiveBackend - now with safety check, falls back to Scalar if unavailable
procedure SetActiveBackend(backend: TSimdBackend);
begin
  // Try to set the requested backend
  if TrySetActiveBackend(backend) then
    Exit;

  // If requested backend is not available, fall back to Scalar
  // (always available, always registered)
  g_ForcedBackend := sbScalar;
  g_BackendForced := True;
  WriteBarrier;
  g_DispatchInitialized := False;
  InterlockedExchange(g_DispatchState, 0);
  MemoryBarrier;
  InitializeDispatch;
end;

procedure ResetToAutomaticBackend;
begin
  g_BackendForced := False;
  WriteBarrier;  // Ensure write is visible before clearing initialized flag
  g_DispatchInitialized := False; // Force re-initialization
  InterlockedExchange(g_DispatchState, 0);  // ✅ Reset atomic state
  MemoryBarrier; // Full barrier before re-initialization
  InitializeDispatch;
end;

function IsVectorAsmEnabled: Boolean;
begin
  Result := g_VectorAsmEnabled;
end;

// ⚠️ THREAD SAFETY: SetVectorAsmEnabled only works BEFORE dispatch initialization.
// After initialization, the value is locked and this call is ignored.
// For compile-time control, use {$DEFINE SIMD_VECTOR_ASM_DISABLED}.
procedure SetVectorAsmEnabled(enabled: Boolean);
begin
  // Only allow changes before dispatch is initialized
  if g_DispatchState <> 0 then
  begin
    // Already initialized - ignore the call silently for backward compatibility
    // In debug builds, you could add a warning here
    Exit;
  end;

  // Safe to change before initialization
  g_VectorAsmEnabled := enabled;
end;

procedure SetDispatchChangedHook(hook: TSimdDispatchChangedHook);
begin
  g_DispatchChangedHook := hook;

  // If dispatch is already initialized, sync immediately.
  if Assigned(hook) and (g_DispatchState = 2) then
    hook;
end;

function GetDispatchTable: PSimdDispatchTable;
begin
  InitializeDispatch;
  Result := g_CurrentDispatch;
end;

// === Backend Registration ===

procedure RegisterBackend(backend: TSimdBackend; const dispatchTable: TSimdDispatchTable);
begin
  // ✅ P2-1: Validate dispatch table integrity before registration
  {$IFDEF DEBUG}
  AssertDispatchTableValid(dispatchTable, dispatchTable.BackendInfo.Name);
  {$ENDIF}

  g_BackendTables[backend] := dispatchTable;
  WriteBarrier;  // Ensure table is fully written before marking as registered
  g_BackendRegistered[backend] := True;
  WriteBarrier;  // Ensure registration is visible before clearing initialized flag

  // Always re-select best backend when a new one is registered
  g_DispatchInitialized := False;
  InterlockedExchange(g_DispatchState, 0);  // ✅ Reset atomic state
  MemoryBarrier; // Full barrier before re-initialization
  InitializeDispatch;
end;

function IsBackendRegistered(backend: TSimdBackend): Boolean;
begin
  Result := g_BackendRegistered[backend];
end;

function GetBackendInfo(backend: TSimdBackend): TSimdBackendInfo;
begin
  if g_BackendRegistered[backend] then
    Result := g_BackendTables[backend].BackendInfo
  else
  begin
    // Return empty info for unregistered backend
    FillChar(Result, SizeOf(Result), 0);
    Result.Backend := backend;
    Result.Available := False;
  end;
end;

// ⚠️ DEPRECATED: Rebuilder mechanism removed for thread safety.
// This procedure is now a no-op for backward compatibility.
// Existing calls will compile but have no effect.
procedure RegisterBackendRebuilder(backend: TSimdBackend; rebuilder: TBackendRebuilder);
begin
  // No-op: rebuilder mechanism has been removed
  // Keeping this stub for backward compatibility with existing backend code
end;

// === Dispatch Table Helpers ===

// ✅ P2-1: Dispatch table integrity validation
function ValidateDispatchTable(const dispatchTable: TSimdDispatchTable): Boolean;
type
  PPointer = ^Pointer;
var
  p: PPointer;
  i: Integer;
  fieldCount: Integer;
  startOffset: Integer;
begin
  Result := True;

  // Calculate the offset to the first function pointer (after Backend and BackendInfo)
  // Backend: TSimdBackend (enum, typically 1-4 bytes)
  // BackendInfo: TSimdBackendInfo (record with multiple fields)
  startOffset := SizeOf(TSimdBackend) + SizeOf(TSimdBackendInfo);

  // Calculate number of function pointer fields
  // Total size minus header fields, divided by pointer size
  fieldCount := (SizeOf(TSimdDispatchTable) - startOffset) div SizeOf(Pointer);

  // Check each function pointer
  p := PPointer(PByte(@dispatchTable) + startOffset);
  for i := 0 to fieldCount - 1 do
  begin
    if p^ = nil then
    begin
      Result := False;
      Exit;
    end;
    Inc(p);
  end;
end;

procedure AssertDispatchTableValid(const dispatchTable: TSimdDispatchTable; const backendName: string);
type
  PPointer = ^Pointer;
var
  p: PPointer;
  i: Integer;
  fieldCount: Integer;
  startOffset: Integer;
  nilCount: Integer;
begin
  startOffset := SizeOf(TSimdBackend) + SizeOf(TSimdBackendInfo);
  fieldCount := (SizeOf(TSimdDispatchTable) - startOffset) div SizeOf(Pointer);

  nilCount := 0;
  p := PPointer(PByte(@dispatchTable) + startOffset);
  for i := 0 to fieldCount - 1 do
  begin
    if p^ = nil then
      Inc(nilCount);
    Inc(p);
  end;

  {$IFDEF DEBUG}
  if nilCount > 0 then
    raise Exception.CreateFmt(
      'SIMD dispatch table validation failed for backend "%s": %d of %d function pointers are nil',
      [backendName, nilCount, fieldCount]);
  {$ENDIF}

  // In release builds, just assert
  Assert(nilCount = 0,
    Format('SIMD dispatch table "%s" has %d nil pointers', [backendName, nilCount]));
end;

procedure FillBaseDispatchTable(var dispatchTable: TSimdDispatchTable);
begin
  // Initialize dispatch table to zeros
  FillChar(dispatchTable, SizeOf(TSimdDispatchTable), 0);

  // Note: Backend and BackendInfo are NOT set here - caller must set them.

  // === F32x4 Arithmetic ===
  dispatchTable.AddF32x4 := @ScalarAddF32x4;
  dispatchTable.SubF32x4 := @ScalarSubF32x4;
  dispatchTable.MulF32x4 := @ScalarMulF32x4;
  dispatchTable.DivF32x4 := @ScalarDivF32x4;

  // === F32x8 Arithmetic ===
  dispatchTable.AddF32x8 := @ScalarAddF32x8;
  dispatchTable.SubF32x8 := @ScalarSubF32x8;
  dispatchTable.MulF32x8 := @ScalarMulF32x8;
  dispatchTable.DivF32x8 := @ScalarDivF32x8;

  // === F64x2 Arithmetic ===
  dispatchTable.AddF64x2 := @ScalarAddF64x2;
  dispatchTable.SubF64x2 := @ScalarSubF64x2;
  dispatchTable.MulF64x2 := @ScalarMulF64x2;
  dispatchTable.DivF64x2 := @ScalarDivF64x2;

  // === I32x4 Arithmetic ===
  dispatchTable.AddI32x4 := @ScalarAddI32x4;
  dispatchTable.SubI32x4 := @ScalarSubI32x4;
  dispatchTable.MulI32x4 := @ScalarMulI32x4;

  // === I32x4 Bitwise ===
  dispatchTable.AndI32x4 := @ScalarAndI32x4;
  dispatchTable.OrI32x4 := @ScalarOrI32x4;
  dispatchTable.XorI32x4 := @ScalarXorI32x4;
  dispatchTable.NotI32x4 := @ScalarNotI32x4;
  dispatchTable.AndNotI32x4 := @ScalarAndNotI32x4;

  // === I32x4 Shift ===
  dispatchTable.ShiftLeftI32x4 := @ScalarShiftLeftI32x4;
  dispatchTable.ShiftRightI32x4 := @ScalarShiftRightI32x4;
  dispatchTable.ShiftRightArithI32x4 := @ScalarShiftRightArithI32x4;

  // === I32x4 Comparison ===
  dispatchTable.CmpEqI32x4 := @ScalarCmpEqI32x4;
  dispatchTable.CmpLtI32x4 := @ScalarCmpLtI32x4;
  dispatchTable.CmpGtI32x4 := @ScalarCmpGtI32x4;
  dispatchTable.CmpLeI32x4 := @ScalarCmpLeI32x4;  // ✅ P0-5: Added
  dispatchTable.CmpGeI32x4 := @ScalarCmpGeI32x4;  // ✅ P0-5: Added
  dispatchTable.CmpNeI32x4 := @ScalarCmpNeI32x4;  // ✅ P0-5: Added

  // === I32x4 MinMax ===
  dispatchTable.MinI32x4 := @ScalarMinI32x4;
  dispatchTable.MaxI32x4 := @ScalarMaxI32x4;

  // === I64x2 Arithmetic ===
  dispatchTable.AddI64x2 := @ScalarAddI64x2;
  dispatchTable.SubI64x2 := @ScalarSubI64x2;

  // === I64x2 Bitwise ===
  dispatchTable.AndI64x2 := @ScalarAndI64x2;
  dispatchTable.OrI64x2 := @ScalarOrI64x2;
  dispatchTable.XorI64x2 := @ScalarXorI64x2;
  dispatchTable.NotI64x2 := @ScalarNotI64x2;

  // === I64x2 Comparison === (✅ P0-5: Added full set)
  dispatchTable.CmpEqI64x2 := @ScalarCmpEqI64x2;
  dispatchTable.CmpLtI64x2 := @ScalarCmpLtI64x2;
  dispatchTable.CmpGtI64x2 := @ScalarCmpGtI64x2;
  dispatchTable.CmpLeI64x2 := @ScalarCmpLeI64x2;
  dispatchTable.CmpGeI64x2 := @ScalarCmpGeI64x2;
  dispatchTable.CmpNeI64x2 := @ScalarCmpNeI64x2;

  // === F64x4 Arithmetic (256-bit) ===
  dispatchTable.AddF64x4 := @ScalarAddF64x4;
  dispatchTable.SubF64x4 := @ScalarSubF64x4;
  dispatchTable.MulF64x4 := @ScalarMulF64x4;
  dispatchTable.DivF64x4 := @ScalarDivF64x4;

  // === I32x8 Arithmetic (256-bit) ===
  dispatchTable.AddI32x8 := @ScalarAddI32x8;
  dispatchTable.SubI32x8 := @ScalarSubI32x8;
  dispatchTable.MulI32x8 := @ScalarMulI32x8;

  // === I32x8 Bitwise ===
  dispatchTable.AndI32x8 := @ScalarAndI32x8;
  dispatchTable.OrI32x8 := @ScalarOrI32x8;
  dispatchTable.XorI32x8 := @ScalarXorI32x8;
  dispatchTable.NotI32x8 := @ScalarNotI32x8;
  dispatchTable.AndNotI32x8 := @ScalarAndNotI32x8;

  // === I32x8 Shift ===
  dispatchTable.ShiftLeftI32x8 := @ScalarShiftLeftI32x8;
  dispatchTable.ShiftRightI32x8 := @ScalarShiftRightI32x8;
  dispatchTable.ShiftRightArithI32x8 := @ScalarShiftRightArithI32x8;

  // === I32x8 Comparison ===
  dispatchTable.CmpEqI32x8 := @ScalarCmpEqI32x8;
  dispatchTable.CmpLtI32x8 := @ScalarCmpLtI32x8;
  dispatchTable.CmpGtI32x8 := @ScalarCmpGtI32x8;
  dispatchTable.CmpLeI32x8 := @ScalarCmpLeI32x8;  // ✅ P0-5: Added
  dispatchTable.CmpGeI32x8 := @ScalarCmpGeI32x8;  // ✅ P0-5: Added
  dispatchTable.CmpNeI32x8 := @ScalarCmpNeI32x8;  // ✅ P0-5: Added

  // === I32x8 MinMax ===
  dispatchTable.MinI32x8 := @ScalarMinI32x8;
  dispatchTable.MaxI32x8 := @ScalarMaxI32x8;

  // === F32x16 Arithmetic (512-bit) ===
  dispatchTable.AddF32x16 := @ScalarAddF32x16;
  dispatchTable.SubF32x16 := @ScalarSubF32x16;
  dispatchTable.MulF32x16 := @ScalarMulF32x16;
  dispatchTable.DivF32x16 := @ScalarDivF32x16;

  // === F64x8 Arithmetic (512-bit) ===
  dispatchTable.AddF64x8 := @ScalarAddF64x8;
  dispatchTable.SubF64x8 := @ScalarSubF64x8;
  dispatchTable.MulF64x8 := @ScalarMulF64x8;
  dispatchTable.DivF64x8 := @ScalarDivF64x8;

  // === I32x16 Arithmetic (512-bit) ===
  dispatchTable.AddI32x16 := @ScalarAddI32x16;
  dispatchTable.SubI32x16 := @ScalarSubI32x16;
  dispatchTable.MulI32x16 := @ScalarMulI32x16;

  // === I32x16 Bitwise ===
  dispatchTable.AndI32x16 := @ScalarAndI32x16;
  dispatchTable.OrI32x16 := @ScalarOrI32x16;
  dispatchTable.XorI32x16 := @ScalarXorI32x16;
  dispatchTable.NotI32x16 := @ScalarNotI32x16;
  dispatchTable.AndNotI32x16 := @ScalarAndNotI32x16;

  // === I32x16 Shift ===
  dispatchTable.ShiftLeftI32x16 := @ScalarShiftLeftI32x16;
  dispatchTable.ShiftRightI32x16 := @ScalarShiftRightI32x16;
  dispatchTable.ShiftRightArithI32x16 := @ScalarShiftRightArithI32x16;

  // === I32x16 Comparison ===
  dispatchTable.CmpEqI32x16 := @ScalarCmpEqI32x16;
  dispatchTable.CmpLtI32x16 := @ScalarCmpLtI32x16;
  dispatchTable.CmpGtI32x16 := @ScalarCmpGtI32x16;
  dispatchTable.CmpLeI32x16 := @ScalarCmpLeI32x16;  // ✅ P0-5: Added
  dispatchTable.CmpGeI32x16 := @ScalarCmpGeI32x16;  // ✅ P0-5: Added
  dispatchTable.CmpNeI32x16 := @ScalarCmpNeI32x16;  // ✅ P0-5: Added

  // === I32x16 MinMax ===
  dispatchTable.MinI32x16 := @ScalarMinI32x16;
  dispatchTable.MaxI32x16 := @ScalarMaxI32x16;

  // === F32x4 Comparison ===
  dispatchTable.CmpEqF32x4 := @ScalarCmpEqF32x4;
  dispatchTable.CmpLtF32x4 := @ScalarCmpLtF32x4;
  dispatchTable.CmpLeF32x4 := @ScalarCmpLeF32x4;
  dispatchTable.CmpGtF32x4 := @ScalarCmpGtF32x4;
  dispatchTable.CmpGeF32x4 := @ScalarCmpGeF32x4;
  dispatchTable.CmpNeF32x4 := @ScalarCmpNeF32x4;

  // ✅ P1-E: F64x2 比较操作
  dispatchTable.CmpEqF64x2 := @ScalarCmpEqF64x2;
  dispatchTable.CmpLtF64x2 := @ScalarCmpLtF64x2;
  dispatchTable.CmpLeF64x2 := @ScalarCmpLeF64x2;
  dispatchTable.CmpGtF64x2 := @ScalarCmpGtF64x2;
  dispatchTable.CmpGeF64x2 := @ScalarCmpGeF64x2;
  dispatchTable.CmpNeF64x2 := @ScalarCmpNeF64x2;

  // === F32x4 Math ===
  dispatchTable.AbsF32x4 := @ScalarAbsF32x4;
  dispatchTable.SqrtF32x4 := @ScalarSqrtF32x4;
  dispatchTable.MinF32x4 := @ScalarMinF32x4;
  dispatchTable.MaxF32x4 := @ScalarMaxF32x4;

  // === F32x4 Extended Math ===
  dispatchTable.FmaF32x4 := @ScalarFmaF32x4;
  dispatchTable.RcpF32x4 := @ScalarRcpF32x4;
  dispatchTable.RsqrtF32x4 := @ScalarRsqrtF32x4;
  dispatchTable.FloorF32x4 := @ScalarFloorF32x4;
  dispatchTable.CeilF32x4 := @ScalarCeilF32x4;
  dispatchTable.RoundF32x4 := @ScalarRoundF32x4;
  dispatchTable.TruncF32x4 := @ScalarTruncF32x4;
  dispatchTable.ClampF32x4 := @ScalarClampF32x4;

  // === ✅ P1-4: Wide Vector Extended Math ===
  // F64x2
  dispatchTable.FmaF64x2 := @ScalarFmaF64x2;
  dispatchTable.FloorF64x2 := @ScalarFloorF64x2;
  dispatchTable.CeilF64x2 := @ScalarCeilF64x2;
  dispatchTable.RoundF64x2 := @ScalarRoundF64x2;
  dispatchTable.TruncF64x2 := @ScalarTruncF64x2;
  // F32x8
  dispatchTable.FmaF32x8 := @ScalarFmaF32x8;
  dispatchTable.FloorF32x8 := @ScalarFloorF32x8;
  dispatchTable.CeilF32x8 := @ScalarCeilF32x8;
  dispatchTable.RoundF32x8 := @ScalarRoundF32x8;
  dispatchTable.TruncF32x8 := @ScalarTruncF32x8;
  // F64x4
  dispatchTable.FmaF64x4 := @ScalarFmaF64x4;
  dispatchTable.FloorF64x4 := @ScalarFloorF64x4;
  dispatchTable.CeilF64x4 := @ScalarCeilF64x4;
  dispatchTable.RoundF64x4 := @ScalarRoundF64x4;
  dispatchTable.TruncF64x4 := @ScalarTruncF64x4;

  // === 3D/4D Vector Math ===
  dispatchTable.DotF32x4 := @ScalarDotF32x4;
  dispatchTable.DotF32x3 := @ScalarDotF32x3;
  dispatchTable.CrossF32x3 := @ScalarCrossF32x3;
  dispatchTable.LengthF32x4 := @ScalarLengthF32x4;
  dispatchTable.LengthF32x3 := @ScalarLengthF32x3;
  dispatchTable.NormalizeF32x4 := @ScalarNormalizeF32x4;
  dispatchTable.NormalizeF32x3 := @ScalarNormalizeF32x3;

  // === F32x4 Reduction ===
  dispatchTable.ReduceAddF32x4 := @ScalarReduceAddF32x4;
  dispatchTable.ReduceMinF32x4 := @ScalarReduceMinF32x4;
  dispatchTable.ReduceMaxF32x4 := @ScalarReduceMaxF32x4;
  dispatchTable.ReduceMulF32x4 := @ScalarReduceMulF32x4;

  // === F32x4 Memory Operations ===
  dispatchTable.LoadF32x4 := @ScalarLoadF32x4;
  dispatchTable.LoadF32x4Aligned := @ScalarLoadF32x4Aligned;
  dispatchTable.StoreF32x4 := @ScalarStoreF32x4;
  dispatchTable.StoreF32x4Aligned := @ScalarStoreF32x4Aligned;

  // === F32x4 Utility Operations ===
  dispatchTable.SplatF32x4 := @ScalarSplatF32x4;
  dispatchTable.ZeroF32x4 := @ScalarZeroF32x4;
  dispatchTable.SelectF32x4 := @ScalarSelectF32x4;
  dispatchTable.ExtractF32x4 := @ScalarExtractF32x4;
  dispatchTable.InsertF32x4 := @ScalarInsertF32x4;

  // === ✅ P1-5: Wide Vector Load/Store/Splat/Zero ===
  // F64x2
  dispatchTable.LoadF64x2 := @ScalarLoadF64x2;
  dispatchTable.StoreF64x2 := @ScalarStoreF64x2;
  dispatchTable.SplatF64x2 := @ScalarSplatF64x2;
  dispatchTable.ZeroF64x2 := @ScalarZeroF64x2;
  // F32x8
  dispatchTable.LoadF32x8 := @ScalarLoadF32x8;
  dispatchTable.StoreF32x8 := @ScalarStoreF32x8;
  dispatchTable.SplatF32x8 := @ScalarSplatF32x8;
  dispatchTable.ZeroF32x8 := @ScalarZeroF32x8;
  // F64x4
  dispatchTable.LoadF64x4 := @ScalarLoadF64x4;
  dispatchTable.StoreF64x4 := @ScalarStoreF64x4;
  dispatchTable.SplatF64x4 := @ScalarSplatF64x4;
  dispatchTable.ZeroF64x4 := @ScalarZeroF64x4;

  // === Facade Functions ===
  dispatchTable.MemEqual := @MemEqual_Scalar;
  dispatchTable.MemFindByte := @MemFindByte_Scalar;
  dispatchTable.MemDiffRange := @MemDiffRange_Scalar;
  dispatchTable.MemCopy := @MemCopy_Scalar;
  dispatchTable.MemSet := @MemSet_Scalar;
  dispatchTable.MemReverse := @MemReverse_Scalar;
  dispatchTable.SumBytes := @SumBytes_Scalar;
  dispatchTable.MinMaxBytes := @MinMaxBytes_Scalar;
  dispatchTable.CountByte := @CountByte_Scalar;
  dispatchTable.Utf8Validate := @Utf8Validate_Scalar;
  dispatchTable.AsciiIEqual := @AsciiIEqual_Scalar;
  dispatchTable.ToLowerAscii := @ToLowerAscii_Scalar;
  dispatchTable.ToUpperAscii := @ToUpperAscii_Scalar;
  dispatchTable.BytesIndexOf := @BytesIndexOf_Scalar;
  dispatchTable.BitsetPopCount := @BitsetPopCount_Scalar;

  // === ✅ P2-1: Saturating Arithmetic ===
  dispatchTable.I8x16SatAdd := @ScalarI8x16SatAdd;
  dispatchTable.I8x16SatSub := @ScalarI8x16SatSub;
  dispatchTable.I16x8SatAdd := @ScalarI16x8SatAdd;
  dispatchTable.I16x8SatSub := @ScalarI16x8SatSub;
  dispatchTable.U8x16SatAdd := @ScalarU8x16SatAdd;
  dispatchTable.U8x16SatSub := @ScalarU8x16SatSub;
  dispatchTable.U16x8SatAdd := @ScalarU16x8SatAdd;
  dispatchTable.U16x8SatSub := @ScalarU16x8SatSub;

  // === ✅ P2-2: Mask 操作 ===
  dispatchTable.Mask2All := @ScalarMask2All;
  dispatchTable.Mask2Any := @ScalarMask2Any;
  dispatchTable.Mask2None := @ScalarMask2None;
  dispatchTable.Mask2PopCount := @ScalarMask2PopCount;
  dispatchTable.Mask2FirstSet := @ScalarMask2FirstSet;
  dispatchTable.Mask4All := @ScalarMask4All;
  dispatchTable.Mask4Any := @ScalarMask4Any;
  dispatchTable.Mask4None := @ScalarMask4None;
  dispatchTable.Mask4PopCount := @ScalarMask4PopCount;
  dispatchTable.Mask4FirstSet := @ScalarMask4FirstSet;
  dispatchTable.Mask8All := @ScalarMask8All;
  dispatchTable.Mask8Any := @ScalarMask8Any;
  dispatchTable.Mask8None := @ScalarMask8None;
  dispatchTable.Mask8PopCount := @ScalarMask8PopCount;
  dispatchTable.Mask8FirstSet := @ScalarMask8FirstSet;
  dispatchTable.Mask16All := @ScalarMask16All;
  dispatchTable.Mask16Any := @ScalarMask16Any;
  dispatchTable.Mask16None := @ScalarMask16None;
  dispatchTable.Mask16PopCount := @ScalarMask16PopCount;
  dispatchTable.Mask16FirstSet := @ScalarMask16FirstSet;

  // === ✅ P2-3: F64x2 Select ===
  dispatchTable.SelectF64x2 := @ScalarSelectF64x2;
end;

// ✅ 修复 P0-1: 允许 tier 后端从 SSE2 继承实现，而非从标量基线开始
function CloneDispatchTable(fromBackend: TSimdBackend; var dispatchTable: TSimdDispatchTable): Boolean;
var
  savedBackend: TSimdBackend;
  savedInfo: TSimdBackendInfo;
begin
  // 保存当前后端信息（调用者可能已经设置）
  savedBackend := dispatchTable.Backend;
  savedInfo := dispatchTable.BackendInfo;

  if g_BackendRegistered[fromBackend] then
  begin
    // 从源后端复制整个派发表
    dispatchTable := g_BackendTables[fromBackend];
    Result := True;
  end
  else
  begin
    // 源后端未注册，回退到标量基线
    FillBaseDispatchTable(dispatchTable);
    Result := False;
  end;

  // 恢复后端信息（不复制源后端的信息）
  dispatchTable.Backend := savedBackend;
  dispatchTable.BackendInfo := savedInfo;
end;

// === Initialization ===

initialization
  // Initialize dispatch system on unit load
  InitializeDispatch;

end.


