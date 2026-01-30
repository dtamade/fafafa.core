unit fafafa.core.math.intutil;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

{**
 * 整数实用函数（基线实现）
 *
 * 说明：
 * - 本单元提供内存对齐、整除向上取整、2的幂次等常用整数运算。
 * - `fafafa.core.math` 作为统一入口会 re-export/转发这些 API。
 * - 所有函数均为纯函数，无副作用。
 *}

{**
 * DivRoundUp
 *
 * @desc
 *   Division that rounds up (ceiling division).
 *   向上取整除法：(a + b - 1) / b，但避免溢出。
 *
 * @params
 *   aValue - Dividend / 被除数
 *   aDivisor - Divisor (must be > 0) / 除数（必须大于0）
 *
 * @returns
 *   Ceiling of aValue / aDivisor / 向上取整的商
 *}
function DivRoundUp(aValue, aDivisor: SizeUInt): SizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * IsPowerOfTwo
 *
 * @desc
 *   Check if value is a power of two.
 *   检查值是否为2的幂。
 *
 * @params
 *   aValue - Value to check / 待检查的值
 *
 * @returns
 *   True if aValue is 2^n for some n >= 0 / 如果是2的幂返回 True
 *   Note: 0 is NOT considered a power of two / 注意：0 不是2的幂
 *}
function IsPowerOfTwo(aValue: SizeUInt): Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * NextPowerOfTwo
 *
 * @desc
 *   Returns the smallest power of two >= aValue.
 *   返回 >= aValue 的最小2的幂。
 *
 * @params
 *   aValue - Input value / 输入值
 *
 * @returns
 *   Smallest 2^n >= aValue / 最小的 2^n >= aValue
 *   Returns 1 for aValue = 0 / 当 aValue = 0 时返回 1
 *}
function NextPowerOfTwo(aValue: SizeUInt): SizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * AlignUp
 *
 * @desc
 *   Round up to the nearest multiple of alignment.
 *   向上对齐到最近的对齐边界。
 *
 * @params
 *   aValue - Value to align / 待对齐的值
 *   aAlignment - Alignment (must be power of 2) / 对齐值（必须是2的幂）
 *
 * @returns
 *   Smallest multiple of aAlignment >= aValue / 最小的 aAlignment 倍数 >= aValue
 *}
function AlignUp(aValue, aAlignment: SizeUInt): SizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * AlignDown
 *
 * @desc
 *   Round down to the nearest multiple of alignment.
 *   向下对齐到最近的对齐边界。
 *
 * @params
 *   aValue - Value to align / 待对齐的值
 *   aAlignment - Alignment (must be power of 2) / 对齐值（必须是2的幂）
 *
 * @returns
 *   Largest multiple of aAlignment <= aValue / 最大的 aAlignment 倍数 <= aValue
 *}
function AlignDown(aValue, aAlignment: SizeUInt): SizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * IsAligned
 *
 * @desc
 *   Check if value is aligned to the given alignment.
 *   检查值是否已对齐。
 *
 * @params
 *   aValue - Value to check / 待检查的值
 *   aAlignment - Alignment (must be power of 2) / 对齐值（必须是2的幂）
 *
 * @returns
 *   True if aValue is a multiple of aAlignment / 如果是对齐值的倍数返回 True
 *}
function IsAligned(aValue, aAlignment: SizeUInt): Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

implementation

function DivRoundUp(aValue, aDivisor: SizeUInt): SizeUInt;
begin
  // 使用 (a + b - 1) / b 公式，但重写以避免溢出：
  // = a / b + (a mod b <> 0 ? 1 : 0)
  if aValue = 0 then
    Result := 0
  else
    Result := ((aValue - 1) div aDivisor) + 1;
end;

// 位操作函数需要禁用范围检查，因为使用了 n-1 等技巧
{$PUSH}
{$R-}
{$Q-}

function IsPowerOfTwo(aValue: SizeUInt): Boolean;
begin
  // 2的幂有且仅有一个bit为1
  // n & (n-1) 会清除最低位的1
  // 如果结果为0，说明只有一个1
  Result := (aValue <> 0) and ((aValue and (aValue - 1)) = 0);
end;

function NextPowerOfTwo(aValue: SizeUInt): SizeUInt;
begin
  if aValue = 0 then
    Exit(1);

  if IsPowerOfTwo(aValue) then
    Exit(aValue);

  // 经典位操作算法：将最高位以下的所有位都设为1，然后+1
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
  // 假设 aAlignment 是2的幂
  // AlignUp = (aValue + aAlignment - 1) & ~(aAlignment - 1)
  if aValue = 0 then
    Exit(0);

  LMask := aAlignment - 1;
  Result := (aValue + LMask) and (not LMask);
end;

function AlignDown(aValue, aAlignment: SizeUInt): SizeUInt;
var
  LMask: SizeUInt;
begin
  // 假设 aAlignment 是2的幂
  // AlignDown = aValue & ~(aAlignment - 1)
  LMask := aAlignment - 1;
  Result := aValue and (not LMask);
end;

function IsAligned(aValue, aAlignment: SizeUInt): Boolean;
begin
  // 假设 aAlignment 是2的幂
  // 检查低位是否全为0
  Result := (aValue and (aAlignment - 1)) = 0;
end;

{$POP}

end.
