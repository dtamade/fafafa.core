unit fafafa.core.simd.direct;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.dispatch;

// =============================================================
// Direct Dispatch (direct pointer)
//
// 目的：避免每次门面调用都执行 GetDispatchTable（函数调用 + init 检查），
// 直接通过一个已绑定的全局指针访问当前 dispatch table。
//
// 设计：
// - dispatch 仍然是“真相来源”（后端注册/选择/切换）。
// - direct 仅维护一个指向当前 table 的指针，并在 dispatch (re)init 后更新。
//
// 为什么不用复制整个 record：
// - 整表拷贝在多线程 backend 切换时可能出现“撕裂读取”（读到混合后端的指针）。
// - 指针更新是原子的（在主流平台上），可避免这类竞态。
// =============================================================

// Returns the bound direct dispatch table.
// The returned pointer remains valid for the lifetime of the process.
function GetDirectDispatchTable: PSimdDispatchTable; inline;

// Rebinds the direct dispatch table to the currently active dispatch table.
// Call this after backend switching (e.g., ForceBackend/ResetBackendSelection).
procedure RebindDirectDispatch;

implementation

uses
  fafafa.core.atomic;

var
  // Points to the currently active table.
  // Stored as a raw pointer so we can use fafafa.core.atomic helpers.
  g_DirectDispatchPtr: Pointer = nil;

function GetDirectDispatchTable: PSimdDispatchTable; inline;
var
  p: Pointer;
begin
  // Fast path: already bound.
  p := atomic_load_ptr(g_DirectDispatchPtr, mo_acquire);
  if p <> nil then
    Exit(PSimdDispatchTable(p));

  // Lazy bind (should be rare): make sure dispatch is initialized and bind once.
  RebindDirectDispatch;
  p := atomic_load_ptr(g_DirectDispatchPtr, mo_acquire);
  Result := PSimdDispatchTable(p);
end;

procedure RebindDirectDispatch;
var
  p: Pointer;
begin
  // GetDispatchTable performs dispatch initialization if needed.
  p := GetDispatchTable;
  atomic_store_ptr(g_DirectDispatchPtr, p, mo_release);
end;

initialization
  // Keep the direct pointer in sync with dispatch (including backend (re)registration).
  SetDispatchChangedHook(@RebindDirectDispatch);

  // Bind once at unit load (also acts as initial sync).
  RebindDirectDispatch;

end.
