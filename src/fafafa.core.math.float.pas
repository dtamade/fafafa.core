unit fafafa.core.math.float;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Math;

{**
 * 标量浮点数学（基线实现）
 *
 * 说明：
 * - 该单元作为 `fafafa.core.math` 的内部实现之一。
 * - 语义以 RTL `System`/`Math` 为基准。
 * - 后续 SIMD/平台优化应通过 facade/dispatch 替换实现，但保持语义一致。
 *}

function Abs(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Min(aA, aB: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Max(aA, aB: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Clamp(x, aMin, aMax: Double): Double; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function Floor(x: Double): Int64; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Ceil(x: Double): Int64; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Trunc(x: Double): Int64; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Round(x: Double): Int64; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

function Sqrt(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{** IsNaN - Check if value is Not-a-Number *}
function IsNaN(x: Double): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{** IsInfinite - Check if value is positive or negative infinity *}
function IsInfinite(x: Double): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{** Power - Raise base to the power of exponent *}
function Power(aBase, aExponent: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{** EnsureRange - Clamp value to [aMin, aMax] *}
function EnsureRange(aValue, aMin, aMax: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function EnsureRange(aValue, aMin, aMax: Int64): Int64; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function EnsureRange(aValue, aMin, aMax: Integer): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{** RadToDeg - Convert radians to degrees *}
function RadToDeg(aRadians: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{** DegToRad - Convert degrees to radians *}
function DegToRad(aDegrees: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{** ArcTan2 - Two-argument arctangent *}
function ArcTan2(aY, aX: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// === Trigonometric Functions ===

{** Sin - Sine function *}
function Sin(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{** Cos - Cosine function *}
function Cos(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{** Tan - Tangent function *}
function Tan(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{** ArcSin - Inverse sine (arcsine) *}
function ArcSin(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{** ArcCos - Inverse cosine (arccosine) *}
function ArcCos(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{** ArcTan - Inverse tangent (arctangent) *}
function ArcTan(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// === Exponential and Logarithmic Functions ===

{** Exp - Exponential function (e^x) *}
function Exp(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{** Ln - Natural logarithm *}
function Ln(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{** Log10 - Base-10 logarithm *}
function Log10(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{** Log2 - Base-2 logarithm *}
function Log2(x: Double): Double; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

implementation

function Abs(x: Double): Double;
begin
  Result := System.Abs(x);
end;

function Min(aA, aB: Double): Double;
begin
  Result := Math.Min(aA, aB);
end;

function Max(aA, aB: Double): Double;
begin
  Result := Math.Max(aA, aB);
end;

function Clamp(x, aMin, aMax: Double): Double;
begin
  Result := Math.Max(aMin, Math.Min(x, aMax));
end;

function Floor(x: Double): Int64;
begin
  Result := Int64(Math.Floor(x));
end;

function Ceil(x: Double): Int64;
begin
  Result := Int64(Math.Ceil(x));
end;

function Trunc(x: Double): Int64;
begin
  Result := Int64(System.Trunc(x));
end;

function Round(x: Double): Int64;
begin
  Result := Int64(System.Round(x));
end;

function Sqrt(x: Double): Double;
begin
  Result := System.Sqrt(x);
end;

function IsNaN(x: Double): Boolean;
begin
  Result := Math.IsNaN(x);
end;

function IsInfinite(x: Double): Boolean;
begin
  Result := Math.IsInfinite(x);
end;

function Power(aBase, aExponent: Double): Double;
begin
  Result := Math.Power(aBase, aExponent);
end;

function EnsureRange(aValue, aMin, aMax: Double): Double;
begin
  Result := Math.EnsureRange(aValue, aMin, aMax);
end;

function EnsureRange(aValue, aMin, aMax: Int64): Int64;
begin
  Result := Math.EnsureRange(aValue, aMin, aMax);
end;

function EnsureRange(aValue, aMin, aMax: Integer): Integer;
begin
  Result := Math.EnsureRange(aValue, aMin, aMax);
end;

function RadToDeg(aRadians: Double): Double;
begin
  Result := Math.RadToDeg(aRadians);
end;

function DegToRad(aDegrees: Double): Double;
begin
  Result := Math.DegToRad(aDegrees);
end;

function ArcTan2(aY, aX: Double): Double;
begin
  Result := Math.ArcTan2(aY, aX);
end;

// === Trigonometric Functions Implementation ===

function Sin(x: Double): Double;
begin
  Result := System.Sin(x);
end;

function Cos(x: Double): Double;
begin
  Result := System.Cos(x);
end;

function Tan(x: Double): Double;
begin
  Result := Math.Tan(x);
end;

function ArcSin(x: Double): Double;
begin
  Result := Math.ArcSin(x);
end;

function ArcCos(x: Double): Double;
begin
  Result := Math.ArcCos(x);
end;

function ArcTan(x: Double): Double;
begin
  Result := System.ArcTan(x);
end;

// === Exponential and Logarithmic Functions Implementation ===

function Exp(x: Double): Double;
begin
  Result := System.Exp(x);
end;

function Ln(x: Double): Double;
begin
  Result := System.Ln(x);
end;

function Log10(x: Double): Double;
begin
  Result := Math.Log10(x);
end;

function Log2(x: Double): Double;
begin
  Result := Math.Log2(x);
end;

end.
