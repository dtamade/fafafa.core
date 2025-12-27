unit fafafa.core.simd.direct;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.dispatch;

// =============================================================
// Direct Dispatch (一次性绑定)
//
// 目的：避免每次门面调用都执行 GetDispatchTable，再通过表内函数指针二次派发。
// 做法：在初始化/切换后端时，将当前 dispatch table 复制到本单元的全局表中。
//
// 注意：本单元不替代 fafafa.core.simd.dispatch。
// - dispatch 仍然是“真相来源”，支持后端注册/选择。
// - direct 只是把当前选择的表快照绑定到全局变量，供门面走更快路径。
// =============================================================

// Returns the bound direct dispatch table.
// The returned pointer remains valid for the lifetime of the process.
function GetDirectDispatchTable: PSimdDispatchTable; inline;

// Rebinds the direct dispatch table to the currently active dispatch table.
// Call this after backend switching (e.g., ForceBackend/ResetBackendSelection).
procedure RebindDirectDispatch;

implementation

var
  g_DirectDispatch: TSimdDispatchTable;

function GetDirectDispatchTable: PSimdDispatchTable; inline;
begin
  Result := @g_DirectDispatch;
end;

procedure RebindDirectDispatch;
var
  dt: PSimdDispatchTable;
begin
  dt := GetDispatchTable;
  if dt = nil then
  begin
    // Should never happen (scalar backend is always registered), but keep safe.
    Finalize(g_DirectDispatch);
    FillChar(g_DirectDispatch, SizeOf(g_DirectDispatch), 0);
    Exit;
  end;

  // Copy the currently active dispatch table into a global snapshot.
  // This makes facade calls avoid the per-call GetDispatchTable overhead.
  g_DirectDispatch := dt^;
end;

initialization
  // Keep the direct snapshot in sync with dispatch (including backend (re)registration).
  SetDispatchChangedHook(@RebindDirectDispatch);

  // Bind once at unit load (and also acts as initial sync).
  RebindDirectDispatch;

end.
