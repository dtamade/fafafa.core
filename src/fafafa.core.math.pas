{

```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.math

## Abstract 摘要

Provides a set of basic, cross-platform mathematical routines without external dependencies.
提供一组不依赖外部单元的、跨平台的基础数学函数。

## Declaration 声明

For forwarding or using it for your own project, please retain the copyright notice of this project. Thank you.
转发或者用于自己项目请保留本项目的版权声明,谢谢.

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.math;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base;

type

  Float       = Double;
  PFloat      = ^Float;
  TFloatArray = array of Float;
  PFloatArray = ^TFloatArray;


{**
 * Min
 *
 * @desc
 *   Returns the smaller of two integer values.
 *   返回两个整数中较小的一个.
 *
 * @params
 *   aA - The first integer value.
 *       第一个整数.
 *   aB - The second integer value.
 *       第二个整数.
 *}
function Min(aA, aB: Integer): Integer; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Max
 *
 * @desc
 *   Returns the larger of two integer values.
 *   返回两个整数中较大的一个.
 *
 * @params
 *   aA - The first integer value.
 *       第一个整数.
 *   aB - The second integer value.
 *       第二个整数.
 *}
function Max(aA, aB: Integer): Integer; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Ceil
 *
 * @desc
 *   Calculates the smallest integer value greater than or equal to the result of a division.
 *   计算大于或等于除法结果的最小整数值 (向上取整除法).
 *
 * @params
 *   x - The value to round up.
 *       要向上取整的值.
 *
 * @remark
 *   Example: Ceil(7, 3) = 3, Ceil(6, 3) = 2.
 *   例如: Ceil(7, 3) = 3, Ceil(6, 3) = 2.
 *}
function Ceil(x: Float): Integer; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * Ceil64
 *
 * @desc
 *   Calculates the smallest 64-bit integer value greater than or equal to the result of a division.
 *   计算大于或等于除法结果的最小64位整数值 (向上取整除法).
 *
 * @params
 *   x - The value to round up.
 *       要向上取整的值.
 *}
function Ceil64(x: Float): Int64; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * IsAddOverflow
 *
 * @desc
 *   whether the addition of unsigned integers in the frame is valid (overflow).
 *   检查框架无符号整数相加是否有效(溢出).
 *
 * @params
 *   aA  The first SizeUInt value.
 *       第一个SizeUInt值.
 *
 *   aB  The second SizeUInt value.
 *       第二个SizeUInt值.
 *}
function IsAddOverflow(aA, aB: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * IsAddOverflow
 *
 * @desc
 *   Check whether the addition of 32-bit unsigned integers is valid (overflow).
 *   检查32位无符号整数相加是否有效(溢出).
 *
 * @params
 *   aA  The first UInt32 value.
 *       第一个32位无符号整数.
 *
 *   aB  The second UInt32 value.
 *       第二个32位无符号整数.
 *}
function IsAddOverflow(aA, aB: UInt32): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

implementation

function Min(aA, aB: Integer): Integer;
begin
  if aA < aB then
    Result := aA
  else
    Result := aB;
end;

function Max(aA, aB: Integer): Integer;
begin
  if aA > aB then
    Result := aA
  else
    Result := aB;
end;

function Ceil(x : Float) : integer;
begin
  Result := Trunc(x) + ord(Frac(x) > 0);
end;

function Ceil64(x: Float): Int64;
begin
  Result := Trunc(x) + ord(Frac(x) > 0);
end;

function IsAddOverflow(aA, aB: SizeUInt): Boolean;
begin
  Result := aA > (MAX_SIZE_UINT - aB);
end;

function IsAddOverflow(aA, aB: UInt32): Boolean;
begin
  Result := aA > (MAX_UINT32 - aB);
end;

end.
