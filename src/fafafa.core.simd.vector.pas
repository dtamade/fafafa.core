unit fafafa.core.simd.vector;

{$mode objfpc}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.utils;

type
  { TSimdVecF32x4 - 高级 4x Single 向量封装 }
  TSimdVecF32x4 = record
  private
    FData: TVecF32x4;
    function GetElement(index: Integer): Single; inline;
    procedure SetElement(index: Integer; value: Single); inline;
  public
    // 构造函数
    class function Create(x, y, z, w: Single): TSimdVecF32x4; static; inline;
    class function Splat(value: Single): TSimdVecF32x4; static; inline;
    class function Zero: TSimdVecF32x4; static; inline;
    class function One: TSimdVecF32x4; static; inline;
    class function Load(p: PSingle): TSimdVecF32x4; static; inline;
    
    // 存储
    procedure Store(p: PSingle); inline;
    
    // 元素访问
    property X: Single index 0 read GetElement write SetElement;
    property Y: Single index 1 read GetElement write SetElement;
    property Z: Single index 2 read GetElement write SetElement;
    property W: Single index 3 read GetElement write SetElement;
    property Elements[index: Integer]: Single read GetElement write SetElement; default;
    
    // 基础数学
    function Abs: TSimdVecF32x4; inline;
    function Sqrt: TSimdVecF32x4; inline;
    function Rcp: TSimdVecF32x4; inline;
    function Rsqrt: TSimdVecF32x4; inline;
    function Floor: TSimdVecF32x4; inline;
    function Ceil: TSimdVecF32x4; inline;
    function Round: TSimdVecF32x4; inline;
    function Trunc: TSimdVecF32x4; inline;
    
    // 向量数学
    function Dot(const other: TSimdVecF32x4): Single; inline;
    function Dot3(const other: TSimdVecF32x4): Single; inline;
    function Cross3(const other: TSimdVecF32x4): TSimdVecF32x4; inline;
    function Length: Single; inline;
    function Length3: Single; inline;
    function LengthSq: Single; inline;
    function Length3Sq: Single; inline;
    function Normalized: TSimdVecF32x4; inline;
    function Normalized3: TSimdVecF32x4; inline;
    
    // 规约
    function Sum: Single; inline;
    function Min: Single; inline;
    function Max: Single; inline;
    function Product: Single; inline;
    
    // 组件操作
    function Min(const other: TSimdVecF32x4): TSimdVecF32x4; inline;
    function Max(const other: TSimdVecF32x4): TSimdVecF32x4; inline;
    function Clamp(const minVal, maxVal: TSimdVecF32x4): TSimdVecF32x4; inline;
    function Lerp(const other: TSimdVecF32x4; t: Single): TSimdVecF32x4; inline;
    
    // Shuffle/Swizzle
    function Shuffle(imm8: Byte): TSimdVecF32x4; inline;
    function Reverse: TSimdVecF32x4; inline;
    function Broadcast(index: Integer): TSimdVecF32x4; inline;
    
    // 转换
    function ToRaw: TVecF32x4; inline;
    class function FromRaw(const v: TVecF32x4): TSimdVecF32x4; static; inline;
    
    // 运算符重载
    class operator + (const a, b: TSimdVecF32x4): TSimdVecF32x4; inline;
    class operator - (const a, b: TSimdVecF32x4): TSimdVecF32x4; inline;
    class operator * (const a, b: TSimdVecF32x4): TSimdVecF32x4; inline;
    class operator / (const a, b: TSimdVecF32x4): TSimdVecF32x4; inline;
    class operator - (const a: TSimdVecF32x4): TSimdVecF32x4; inline;
    class operator * (const a: TSimdVecF32x4; s: Single): TSimdVecF32x4; inline;
    class operator * (s: Single; const a: TSimdVecF32x4): TSimdVecF32x4; inline;
    class operator / (const a: TSimdVecF32x4; s: Single): TSimdVecF32x4; inline;
    class operator = (const a, b: TSimdVecF32x4): Boolean; inline;
  end;

  { TSimdVecI32x4 - 高级 4x Int32 向量封装 }
  TSimdVecI32x4 = record
  private
    FData: TVecI32x4;
    function GetElement(index: Integer): Int32; inline;
    procedure SetElement(index: Integer; value: Int32); inline;
  public
    // 构造函数
    class function Create(x, y, z, w: Int32): TSimdVecI32x4; static; inline;
    class function Splat(value: Int32): TSimdVecI32x4; static; inline;
    class function Zero: TSimdVecI32x4; static; inline;
    class function Load(p: PInt32): TSimdVecI32x4; static; inline;
    
    // 存储
    procedure Store(p: PInt32); inline;
    
    // 元素访问
    property X: Int32 index 0 read GetElement write SetElement;
    property Y: Int32 index 1 read GetElement write SetElement;
    property Z: Int32 index 2 read GetElement write SetElement;
    property W: Int32 index 3 read GetElement write SetElement;
    property Elements[index: Integer]: Int32 read GetElement write SetElement; default;
    
    // 规约
    function Sum: Int32; inline;
    
    // Shuffle
    function Shuffle(imm8: Byte): TSimdVecI32x4; inline;
    function Reverse: TSimdVecI32x4; inline;
    function Broadcast(index: Integer): TSimdVecI32x4; inline;
    
    // 转换
    function ToRaw: TVecI32x4; inline;
    function ToFloat: TSimdVecF32x4; inline;
    class function FromRaw(const v: TVecI32x4): TSimdVecI32x4; static; inline;
    
    // 运算符重载
    class operator + (const a, b: TSimdVecI32x4): TSimdVecI32x4; inline;
    class operator - (const a, b: TSimdVecI32x4): TSimdVecI32x4; inline;
    class operator - (const a: TSimdVecI32x4): TSimdVecI32x4; inline;
    class operator = (const a, b: TSimdVecI32x4): Boolean; inline;
  end;

  { TSimdVec3 - 3D 向量封装 (存储为 4D，W 忽略) }
  TSimdVec3 = record
  private
    FData: TVecF32x4;
    function GetX: Single; inline;
    function GetY: Single; inline;
    function GetZ: Single; inline;
    procedure SetX(value: Single); inline;
    procedure SetY(value: Single); inline;
    procedure SetZ(value: Single); inline;
  public
    class function Create(x, y, z: Single): TSimdVec3; static; inline;
    class function Zero: TSimdVec3; static; inline;
    class function UnitX: TSimdVec3; static; inline;
    class function UnitY: TSimdVec3; static; inline;
    class function UnitZ: TSimdVec3; static; inline;
    
    property X: Single read GetX write SetX;
    property Y: Single read GetY write SetY;
    property Z: Single read GetZ write SetZ;
    
    function Dot(const other: TSimdVec3): Single; inline;
    function Cross(const other: TSimdVec3): TSimdVec3; inline;
    function Length: Single; inline;
    function LengthSq: Single; inline;
    function Normalized: TSimdVec3; inline;
    function Lerp(const other: TSimdVec3; t: Single): TSimdVec3; inline;
    function Reflect(const normal: TSimdVec3): TSimdVec3; inline;
    
    class operator + (const a, b: TSimdVec3): TSimdVec3; inline;
    class operator - (const a, b: TSimdVec3): TSimdVec3; inline;
    class operator * (const a, b: TSimdVec3): TSimdVec3; inline;
    class operator - (const a: TSimdVec3): TSimdVec3; inline;
    class operator * (const a: TSimdVec3; s: Single): TSimdVec3; inline;
    class operator * (s: Single; const a: TSimdVec3): TSimdVec3; inline;
  end;

implementation

uses
  fafafa.core.simd;

{ TSimdVecF32x4 }

// ✅ Safety check: use saturation strategy for index bounds (per project spec)
function TSimdVecF32x4.GetElement(index: Integer): Single;
var
  safeIndex: Integer;
begin
  safeIndex := index;
  if safeIndex < 0 then safeIndex := 0
  else if safeIndex > 3 then safeIndex := 3;
  Result := FData.f[safeIndex];
end;

procedure TSimdVecF32x4.SetElement(index: Integer; value: Single);
var
  safeIndex: Integer;
begin
  safeIndex := index;
  if safeIndex < 0 then safeIndex := 0
  else if safeIndex > 3 then safeIndex := 3;
  FData.f[safeIndex] := value;
end;

class function TSimdVecF32x4.Create(x, y, z, w: Single): TSimdVecF32x4;
begin
  Result.FData.f[0] := x;
  Result.FData.f[1] := y;
  Result.FData.f[2] := z;
  Result.FData.f[3] := w;
end;

class function TSimdVecF32x4.Splat(value: Single): TSimdVecF32x4;
begin
  Result.FData := VecF32x4Splat(value);
end;

class function TSimdVecF32x4.Zero: TSimdVecF32x4;
begin
  Result.FData := VecF32x4Zero;
end;

class function TSimdVecF32x4.One: TSimdVecF32x4;
begin
  Result.FData := VecF32x4Splat(1.0);
end;

class function TSimdVecF32x4.Load(p: PSingle): TSimdVecF32x4;
begin
  Result.FData := VecF32x4Load(p);
end;

procedure TSimdVecF32x4.Store(p: PSingle);
begin
  VecF32x4Store(p, FData);
end;

function TSimdVecF32x4.Abs: TSimdVecF32x4;
begin
  Result.FData := VecF32x4Abs(FData);
end;

function TSimdVecF32x4.Sqrt: TSimdVecF32x4;
begin
  Result.FData := VecF32x4Sqrt(FData);
end;

function TSimdVecF32x4.Rcp: TSimdVecF32x4;
begin
  Result.FData := VecF32x4Rcp(FData);
end;

function TSimdVecF32x4.Rsqrt: TSimdVecF32x4;
begin
  Result.FData := VecF32x4Rsqrt(FData);
end;

function TSimdVecF32x4.Floor: TSimdVecF32x4;
begin
  Result.FData := VecF32x4Floor(FData);
end;

function TSimdVecF32x4.Ceil: TSimdVecF32x4;
begin
  Result.FData := VecF32x4Ceil(FData);
end;

function TSimdVecF32x4.Round: TSimdVecF32x4;
begin
  Result.FData := VecF32x4Round(FData);
end;

function TSimdVecF32x4.Trunc: TSimdVecF32x4;
begin
  Result.FData := VecF32x4Trunc(FData);
end;

function TSimdVecF32x4.Dot(const other: TSimdVecF32x4): Single;
begin
  Result := VecF32x4Dot(FData, other.FData);
end;

function TSimdVecF32x4.Dot3(const other: TSimdVecF32x4): Single;
begin
  Result := VecF32x3Dot(FData, other.FData);
end;

function TSimdVecF32x4.Cross3(const other: TSimdVecF32x4): TSimdVecF32x4;
begin
  Result.FData := VecF32x3Cross(FData, other.FData);
end;

function TSimdVecF32x4.Length: Single;
begin
  Result := VecF32x4Length(FData);
end;

function TSimdVecF32x4.Length3: Single;
begin
  Result := VecF32x3Length(FData);
end;

function TSimdVecF32x4.LengthSq: Single;
begin
  Result := VecF32x4Dot(FData, FData);
end;

function TSimdVecF32x4.Length3Sq: Single;
begin
  Result := VecF32x3Dot(FData, FData);
end;

function TSimdVecF32x4.Normalized: TSimdVecF32x4;
begin
  Result.FData := VecF32x4Normalize(FData);
end;

function TSimdVecF32x4.Normalized3: TSimdVecF32x4;
begin
  Result.FData := VecF32x3Normalize(FData);
end;

function TSimdVecF32x4.Sum: Single;
begin
  Result := VecF32x4ReduceAdd(FData);
end;

function TSimdVecF32x4.Min: Single;
begin
  Result := VecF32x4ReduceMin(FData);
end;

function TSimdVecF32x4.Max: Single;
begin
  Result := VecF32x4ReduceMax(FData);
end;

function TSimdVecF32x4.Product: Single;
begin
  Result := VecF32x4ReduceMul(FData);
end;

function TSimdVecF32x4.Min(const other: TSimdVecF32x4): TSimdVecF32x4;
begin
  Result.FData := VecF32x4Min(FData, other.FData);
end;

function TSimdVecF32x4.Max(const other: TSimdVecF32x4): TSimdVecF32x4;
begin
  Result.FData := VecF32x4Max(FData, other.FData);
end;

function TSimdVecF32x4.Clamp(const minVal, maxVal: TSimdVecF32x4): TSimdVecF32x4;
begin
  Result.FData := VecF32x4Clamp(FData, minVal.FData, maxVal.FData);
end;

function TSimdVecF32x4.Lerp(const other: TSimdVecF32x4; t: Single): TSimdVecF32x4;
var
  tVec, oneMinusT: TVecF32x4;
begin
  tVec := VecF32x4Splat(t);
  oneMinusT := VecF32x4Splat(1.0 - t);
  Result.FData := VecF32x4Add(VecF32x4Mul(FData, oneMinusT), VecF32x4Mul(other.FData, tVec));
end;

function TSimdVecF32x4.Shuffle(imm8: Byte): TSimdVecF32x4;
begin
  Result.FData := VecF32x4Shuffle(FData, imm8);
end;

function TSimdVecF32x4.Reverse: TSimdVecF32x4;
begin
  Result.FData := VecF32x4Reverse(FData);
end;

function TSimdVecF32x4.Broadcast(index: Integer): TSimdVecF32x4;
begin
  Result.FData := VecF32x4Broadcast(FData, index);
end;

function TSimdVecF32x4.ToRaw: TVecF32x4;
begin
  Result := FData;
end;

class function TSimdVecF32x4.FromRaw(const v: TVecF32x4): TSimdVecF32x4;
begin
  Result.FData := v;
end;

class operator TSimdVecF32x4.+ (const a, b: TSimdVecF32x4): TSimdVecF32x4;
begin
  Result.FData := VecF32x4Add(a.FData, b.FData);
end;

class operator TSimdVecF32x4.- (const a, b: TSimdVecF32x4): TSimdVecF32x4;
begin
  Result.FData := VecF32x4Sub(a.FData, b.FData);
end;

class operator TSimdVecF32x4.* (const a, b: TSimdVecF32x4): TSimdVecF32x4;
begin
  Result.FData := VecF32x4Mul(a.FData, b.FData);
end;

class operator TSimdVecF32x4./ (const a, b: TSimdVecF32x4): TSimdVecF32x4;
begin
  Result.FData := VecF32x4Div(a.FData, b.FData);
end;

class operator TSimdVecF32x4.- (const a: TSimdVecF32x4): TSimdVecF32x4;
begin
  Result.FData := VecF32x4Sub(VecF32x4Zero, a.FData);
end;

class operator TSimdVecF32x4.* (const a: TSimdVecF32x4; s: Single): TSimdVecF32x4;
begin
  Result.FData := VecF32x4Mul(a.FData, VecF32x4Splat(s));
end;

class operator TSimdVecF32x4.* (s: Single; const a: TSimdVecF32x4): TSimdVecF32x4;
begin
  Result.FData := VecF32x4Mul(VecF32x4Splat(s), a.FData);
end;

class operator TSimdVecF32x4./ (const a: TSimdVecF32x4; s: Single): TSimdVecF32x4;
begin
  Result.FData := VecF32x4Div(a.FData, VecF32x4Splat(s));
end;

class operator TSimdVecF32x4.= (const a, b: TSimdVecF32x4): Boolean;
begin
  Result := (a.FData.f[0] = b.FData.f[0]) and
            (a.FData.f[1] = b.FData.f[1]) and
            (a.FData.f[2] = b.FData.f[2]) and
            (a.FData.f[3] = b.FData.f[3]);
end;

{ TSimdVecI32x4 }

// ✅ Safety check: use saturation strategy for index bounds (per project spec)
function TSimdVecI32x4.GetElement(index: Integer): Int32;
var
  safeIndex: Integer;
begin
  safeIndex := index;
  if safeIndex < 0 then safeIndex := 0
  else if safeIndex > 3 then safeIndex := 3;
  Result := FData.i[safeIndex];
end;

procedure TSimdVecI32x4.SetElement(index: Integer; value: Int32);
var
  safeIndex: Integer;
begin
  safeIndex := index;
  if safeIndex < 0 then safeIndex := 0
  else if safeIndex > 3 then safeIndex := 3;
  FData.i[safeIndex] := value;
end;

class function TSimdVecI32x4.Create(x, y, z, w: Int32): TSimdVecI32x4;
begin
  Result.FData.i[0] := x;
  Result.FData.i[1] := y;
  Result.FData.i[2] := z;
  Result.FData.i[3] := w;
end;

class function TSimdVecI32x4.Splat(value: Int32): TSimdVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.FData.i[i] := value;
end;

class function TSimdVecI32x4.Zero: TSimdVecI32x4;
begin
  FillChar(Result.FData, SizeOf(Result.FData), 0);
end;

class function TSimdVecI32x4.Load(p: PInt32): TSimdVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.FData.i[i] := p[i];
end;

procedure TSimdVecI32x4.Store(p: PInt32);
var i: Integer;
begin
  for i := 0 to 3 do
    p[i] := FData.i[i];
end;

function TSimdVecI32x4.Sum: Int32;
begin
  Result := FData.i[0] + FData.i[1] + FData.i[2] + FData.i[3];
end;

function TSimdVecI32x4.Shuffle(imm8: Byte): TSimdVecI32x4;
begin
  Result.FData := VecI32x4Shuffle(FData, imm8);
end;

function TSimdVecI32x4.Reverse: TSimdVecI32x4;
begin
  Result.FData := VecI32x4Reverse(FData);
end;

function TSimdVecI32x4.Broadcast(index: Integer): TSimdVecI32x4;
begin
  Result.FData := VecI32x4Broadcast(FData, index);
end;

function TSimdVecI32x4.ToRaw: TVecI32x4;
begin
  Result := FData;
end;

function TSimdVecI32x4.ToFloat: TSimdVecF32x4;
begin
  Result.FData := VecI32x4CastToF32x4(FData);
end;

class function TSimdVecI32x4.FromRaw(const v: TVecI32x4): TSimdVecI32x4;
begin
  Result.FData := v;
end;

class operator TSimdVecI32x4.+ (const a, b: TSimdVecI32x4): TSimdVecI32x4;
begin
  Result.FData := a.FData + b.FData;
end;

class operator TSimdVecI32x4.- (const a, b: TSimdVecI32x4): TSimdVecI32x4;
begin
  Result.FData := a.FData - b.FData;
end;

class operator TSimdVecI32x4.- (const a: TSimdVecI32x4): TSimdVecI32x4;
begin
  Result.FData := -a.FData;
end;

class operator TSimdVecI32x4.= (const a, b: TSimdVecI32x4): Boolean;
begin
  Result := (a.FData.i[0] = b.FData.i[0]) and
            (a.FData.i[1] = b.FData.i[1]) and
            (a.FData.i[2] = b.FData.i[2]) and
            (a.FData.i[3] = b.FData.i[3]);
end;

{ TSimdVec3 }

function TSimdVec3.GetX: Single;
begin
  Result := FData.f[0];
end;

function TSimdVec3.GetY: Single;
begin
  Result := FData.f[1];
end;

function TSimdVec3.GetZ: Single;
begin
  Result := FData.f[2];
end;

procedure TSimdVec3.SetX(value: Single);
begin
  FData.f[0] := value;
end;

procedure TSimdVec3.SetY(value: Single);
begin
  FData.f[1] := value;
end;

procedure TSimdVec3.SetZ(value: Single);
begin
  FData.f[2] := value;
end;

class function TSimdVec3.Create(x, y, z: Single): TSimdVec3;
begin
  Result.FData.f[0] := x;
  Result.FData.f[1] := y;
  Result.FData.f[2] := z;
  Result.FData.f[3] := 0.0;
end;

class function TSimdVec3.Zero: TSimdVec3;
begin
  Result.FData := VecF32x4Zero;
end;

class function TSimdVec3.UnitX: TSimdVec3;
begin
  Result := Create(1, 0, 0);
end;

class function TSimdVec3.UnitY: TSimdVec3;
begin
  Result := Create(0, 1, 0);
end;

class function TSimdVec3.UnitZ: TSimdVec3;
begin
  Result := Create(0, 0, 1);
end;

function TSimdVec3.Dot(const other: TSimdVec3): Single;
begin
  Result := VecF32x3Dot(FData, other.FData);
end;

function TSimdVec3.Cross(const other: TSimdVec3): TSimdVec3;
begin
  Result.FData := VecF32x3Cross(FData, other.FData);
end;

function TSimdVec3.Length: Single;
begin
  Result := VecF32x3Length(FData);
end;

function TSimdVec3.LengthSq: Single;
begin
  Result := VecF32x3Dot(FData, FData);
end;

function TSimdVec3.Normalized: TSimdVec3;
begin
  Result.FData := VecF32x3Normalize(FData);
end;

function TSimdVec3.Lerp(const other: TSimdVec3; t: Single): TSimdVec3;
var
  tVec, oneMinusT: TVecF32x4;
begin
  tVec := VecF32x4Splat(t);
  oneMinusT := VecF32x4Splat(1.0 - t);
  Result.FData := VecF32x4Add(VecF32x4Mul(FData, oneMinusT), VecF32x4Mul(other.FData, tVec));
  Result.FData.f[3] := 0.0;
end;

function TSimdVec3.Reflect(const normal: TSimdVec3): TSimdVec3;
var
  dotProduct: Single;
  scaledNormal: TVecF32x4;
begin
  // r = v - 2 * dot(v, n) * n
  dotProduct := VecF32x3Dot(FData, normal.FData);
  scaledNormal := VecF32x4Mul(normal.FData, VecF32x4Splat(2.0 * dotProduct));
  Result.FData := VecF32x4Sub(FData, scaledNormal);
  Result.FData.f[3] := 0.0;
end;

class operator TSimdVec3.+ (const a, b: TSimdVec3): TSimdVec3;
begin
  Result.FData := VecF32x4Add(a.FData, b.FData);
  Result.FData.f[3] := 0.0;
end;

class operator TSimdVec3.- (const a, b: TSimdVec3): TSimdVec3;
begin
  Result.FData := VecF32x4Sub(a.FData, b.FData);
  Result.FData.f[3] := 0.0;
end;

class operator TSimdVec3.* (const a, b: TSimdVec3): TSimdVec3;
begin
  Result.FData := VecF32x4Mul(a.FData, b.FData);
  Result.FData.f[3] := 0.0;
end;

class operator TSimdVec3.- (const a: TSimdVec3): TSimdVec3;
begin
  Result.FData := VecF32x4Sub(VecF32x4Zero, a.FData);
  Result.FData.f[3] := 0.0;
end;

class operator TSimdVec3.* (const a: TSimdVec3; s: Single): TSimdVec3;
begin
  Result.FData := VecF32x4Mul(a.FData, VecF32x4Splat(s));
  Result.FData.f[3] := 0.0;
end;

class operator TSimdVec3.* (s: Single; const a: TSimdVec3): TSimdVec3;
begin
  Result.FData := VecF32x4Mul(VecF32x4Splat(s), a.FData);
  Result.FData.f[3] := 0.0;
end;

end.
