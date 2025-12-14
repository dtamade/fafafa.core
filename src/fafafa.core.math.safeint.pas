unit fafafa.core.math.safeint;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base;

{**
 * 安全整数算术（基线实现）
 *
 * 说明：
 * - 本单元提供 overflow/underflow 检测与 saturating 运算。
 * - `fafafa.core.math` 作为统一入口会 re-export/转发这些 API。
 * - 后续若引入 SIMD/平台优化，应保持语义不变，并以测试为准。
 *}

function IsAddOverflow(aA, aB: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsAddOverflow(aA, aB: UInt32): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function IsSubUnderflow(aA, aB: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsSubUnderflow(aA, aB: UInt32): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function IsMulOverflow(aA, aB: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsMulOverflow(aA, aB: UInt32): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function SaturatingAdd(aA, aB: SizeUInt): SizeUInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingAdd(aA, aB: UInt32): UInt32; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function SaturatingSub(aA, aB: SizeUInt): SizeUInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingSub(aA, aB: UInt32): UInt32; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function SaturatingMul(aA, aB: SizeUInt): SizeUInt; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function SaturatingMul(aA, aB: UInt32): UInt32; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

implementation

function IsAddOverflow(aA, aB: SizeUInt): Boolean;
begin
  Result := aA > (MAX_SIZE_UINT - aB);
end;

function IsAddOverflow(aA, aB: UInt32): Boolean;
begin
  Result := aA > (MAX_UINT32 - aB);
end;

function IsSubUnderflow(aA, aB: SizeUInt): Boolean;
begin
  Result := aA < aB;
end;

function IsSubUnderflow(aA, aB: UInt32): Boolean;
begin
  Result := aA < aB;
end;

function IsMulOverflow(aA, aB: SizeUInt): Boolean;
begin
  if (aA = 0) or (aB = 0) then
    Result := False
  else
    Result := aA > (MAX_SIZE_UINT div aB);
end;

function IsMulOverflow(aA, aB: UInt32): Boolean;
begin
  if (aA = 0) or (aB = 0) then
    Result := False
  else
    Result := aA > (MAX_UINT32 div aB);
end;

function SaturatingAdd(aA, aB: SizeUInt): SizeUInt;
begin
  if IsAddOverflow(aA, aB) then
    Result := MAX_SIZE_UINT
  else
    Result := aA + aB;
end;

function SaturatingAdd(aA, aB: UInt32): UInt32;
begin
  if IsAddOverflow(aA, aB) then
    Result := MAX_UINT32
  else
    Result := aA + aB;
end;

function SaturatingSub(aA, aB: SizeUInt): SizeUInt;
begin
  if IsSubUnderflow(aA, aB) then
    Result := 0
  else
    Result := aA - aB;
end;

function SaturatingSub(aA, aB: UInt32): UInt32;
begin
  if IsSubUnderflow(aA, aB) then
    Result := 0
  else
    Result := aA - aB;
end;

function SaturatingMul(aA, aB: SizeUInt): SizeUInt;
begin
  if IsMulOverflow(aA, aB) then
    Result := MAX_SIZE_UINT
  else
    Result := aA * aB;
end;

function SaturatingMul(aA, aB: UInt32): UInt32;
begin
  if IsMulOverflow(aA, aB) then
    Result := MAX_UINT32
  else
    Result := aA * aB;
end;

end.
