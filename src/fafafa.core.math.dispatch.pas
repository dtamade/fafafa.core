{

```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.math.dispatch

## Abstract 摘要

Backend dispatch mechanism for fafafa.core.math.
Allows switching between scalar (RTL-backed) and future SIMD implementations.
fafafa.core.math 的后端派发机制，支持在标量/RTL 实现与未来 SIMD 实现间切换。

## Declaration 声明

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.math.dispatch;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

type
  {**
   * TMathBackend
   *
   * @desc
   *   Available math backend implementations.
   *   可用的数学后端实现。
   *}
  TMathBackend = (
    mbScalar,     // Pure Pascal / RTL-backed (always available)
    mbSIMD        // SIMD-accelerated (future, optional)
  );

  {**
   * TMathBackendInfo
   *
   * @desc
   *   Information about a math backend.
   *   数学后端的信息。
   *}
  TMathBackendInfo = record
    Name: string;
    Description: string;
    Available: Boolean;
  end;

  {**
   * TMathDispatchTable
   *
   * @desc
   *   Function pointer table for dispatching math operations.
   *   Initial version: only scalar float functions.
   *   派发数学运算的函数指针表。初始版本仅包含标量浮点函数。
   *
   * @note
   *   This is a lightweight dispatch table compared to simd.dispatch.
   *   Most math functions are simple enough that direct calls suffice.
   *   The table is primarily for future SIMD batch operations.
   *}
  TMathDispatchTable = record
    Backend: TMathBackend;
    BackendInfo: TMathBackendInfo;

    // === Scalar Float (batch versions for future SIMD) ===
    // These are placeholders for future batch operations.
    // Current facade uses direct calls to fafafa.core.math.float.

    // Future: ArraySqrt, ArrayAbs, ArrayMinMax, etc.
    // ArraySqrtF64: procedure(src, dst: PDouble; count: SizeUInt);
    // ArrayAbsF64: procedure(src, dst: PDouble; count: SizeUInt);
  end;

  PMathDispatchTable = ^TMathDispatchTable;

{**
 * GetActiveBackend
 *
 * @desc
 *   Returns the currently active math backend.
 *   返回当前活动的数学后端。
 *}
function GetActiveBackend: TMathBackend;

{**
 * GetBackendInfo
 *
 * @desc
 *   Returns information about a specific backend.
 *   返回指定后端的信息。
 *}
function GetBackendInfo(aBackend: TMathBackend): TMathBackendInfo;

{**
 * SetActiveBackend
 *
 * @desc
 *   Force a specific backend (for testing or manual override).
 *   强制使用指定后端（用于测试或手动覆盖）。
 *}
procedure SetActiveBackend(aBackend: TMathBackend);

{**
 * ResetToAutomaticBackend
 *
 * @desc
 *   Reset to automatic backend selection.
 *   重置为自动后端选择。
 *}
procedure ResetToAutomaticBackend;

{**
 * IsBackendAvailable
 *
 * @desc
 *   Check if a backend is available on this platform.
 *   检查后端在当前平台是否可用。
 *}
function IsBackendAvailable(aBackend: TMathBackend): Boolean;

{**
 * GetDispatchTable
 *
 * @desc
 *   Get the current dispatch table.
 *   获取当前派发表。
 *}
function GetDispatchTable: PMathDispatchTable;

implementation

var
  g_ActiveBackend: TMathBackend = mbScalar;
  g_BackendForced: Boolean = False;
  g_DispatchTable: TMathDispatchTable;
  g_Initialized: Boolean = False;

const
  BACKEND_INFOS: array[TMathBackend] of TMathBackendInfo = (
    (Name: 'Scalar'; Description: 'Pure Pascal / RTL-backed implementation'; Available: True),
    (Name: 'SIMD';   Description: 'SIMD-accelerated implementation (future)'; Available: False)
  );

procedure InitializeDispatch;
begin
  if g_Initialized then
    Exit;

  // Setup scalar backend (always available)
  g_DispatchTable.Backend := mbScalar;
  g_DispatchTable.BackendInfo := BACKEND_INFOS[mbScalar];

  // Future: register batch function pointers here
  // g_DispatchTable.ArraySqrtF64 := @ScalarArraySqrtF64;

  g_ActiveBackend := mbScalar;
  g_Initialized := True;
end;

function GetActiveBackend: TMathBackend;
begin
  InitializeDispatch;
  Result := g_ActiveBackend;
end;

function GetBackendInfo(aBackend: TMathBackend): TMathBackendInfo;
begin
  Result := BACKEND_INFOS[aBackend];
end;

procedure SetActiveBackend(aBackend: TMathBackend);
begin
  InitializeDispatch;
  if IsBackendAvailable(aBackend) then
  begin
    g_ActiveBackend := aBackend;
    g_BackendForced := True;
    g_DispatchTable.Backend := aBackend;
    g_DispatchTable.BackendInfo := BACKEND_INFOS[aBackend];
  end;
end;

procedure ResetToAutomaticBackend;
begin
  g_BackendForced := False;
  g_Initialized := False;
  InitializeDispatch;
end;

function IsBackendAvailable(aBackend: TMathBackend): Boolean;
begin
  Result := BACKEND_INFOS[aBackend].Available;
end;

function GetDispatchTable: PMathDispatchTable;
begin
  InitializeDispatch;
  Result := @g_DispatchTable;
end;

end.
