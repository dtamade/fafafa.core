unit fafafa.core.bits;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

{**
 * 整数位运算与对齐辅助函数。
 *
 * 这个单元只承载 L0 级别的纯 helper：
 * - 不依赖上层模块
 * - 只处理 SizeUInt 级整数与对齐语义
 * - 适合作为 math/layout/lockfree 等模块的共同底座
 *}

function DivRoundUp(aValue, aDivisor: SizeUInt): SizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsPowerOfTwo(aValue: SizeUInt): Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function NextPowerOfTwo(aValue: SizeUInt): SizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function AlignUp(aValue, aAlignment: SizeUInt): SizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function AlignDown(aValue, aAlignment: SizeUInt): SizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsAligned(aValue, aAlignment: SizeUInt): Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

implementation

function DivRoundUp(aValue, aDivisor: SizeUInt): SizeUInt;
begin
  if aValue = 0 then
    Result := 0
  else
    Result := ((aValue - 1) div aDivisor) + 1;
end;

{$PUSH}
{$R-}
{$Q-}

function IsPowerOfTwo(aValue: SizeUInt): Boolean;
begin
  Result := (aValue <> 0) and ((aValue and (aValue - 1)) = 0);
end;

function NextPowerOfTwo(aValue: SizeUInt): SizeUInt;
begin
  if aValue = 0 then
    Exit(1);

  if IsPowerOfTwo(aValue) then
    Exit(aValue);

  Result := aValue - 1;
  Result := Result or (Result shr 1);
  Result := Result or (Result shr 2);
  Result := Result or (Result shr 4);
  Result := Result or (Result shr 8);
  Result := Result or (Result shr 16);
  {$IFDEF CPU64}
  Result := Result or (Result shr 32);
  {$ENDIF}
  Inc(Result);
end;

function AlignUp(aValue, aAlignment: SizeUInt): SizeUInt;
var
  LMask: SizeUInt;
begin
  if aValue = 0 then
    Exit(0);

  LMask := aAlignment - 1;
  Result := (aValue + LMask) and (not LMask);
end;

function AlignDown(aValue, aAlignment: SizeUInt): SizeUInt;
var
  LMask: SizeUInt;
begin
  LMask := aAlignment - 1;
  Result := aValue and (not LMask);
end;

function IsAligned(aValue, aAlignment: SizeUInt): Boolean;
begin
  Result := (aValue and (aAlignment - 1)) = 0;
end;

{$POP}

end.
