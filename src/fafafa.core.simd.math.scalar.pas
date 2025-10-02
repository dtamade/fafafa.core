unit fafafa.core.simd.math.scalar;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.types,
  fafafa.core.simd.base;

// === 标量 SIMD 数学运算实现 ===
// 这是所有平台的回退实现，使用纯标量运算模拟 SIMD 操作

type
  // 标量向量实现
  TScalarVector = class(TInterfacedObject, ISimdVector)
  private
    FData: array of Single;
    FElementType: TSimdElementType;
    FElementCount: Integer;
  public
    constructor Create(ElementType: TSimdElementType; ElementCount: Integer);
    constructor CreateFromData(const Data: array of Single; ElementType: TSimdElementType);
    
    // ISimdVector 接口实现
    function GetSize: Integer;
    function GetElementCount: Integer;
    function GetElementType: TSimdElementType;
    function GetBackend: TSimdBackend;
    
    // 数据访问
    function GetElement(Index: Integer): Single;
    procedure SetElement(Index: Integer; Value: Single);
    function GetDataPtr: PSingle;
    
    property Elements[Index: Integer]: Single read GetElement write SetElement; default;
  end;

  // 标量数学运算实现
  TScalarMath = class(TInterfacedObject, ISimdMath)
  public
    function Add(const A, B: ISimdVector): ISimdVector;
    function Sub(const A, B: ISimdVector): ISimdVector;
    function Mul(const A, B: ISimdVector): ISimdVector;
    function Divide(const A, B: ISimdVector): ISimdVector;
    function Sqrt(const A: ISimdVector): ISimdVector;
    function Abs(const A: ISimdVector): ISimdVector;
    function Min(const A, B: ISimdVector): ISimdVector;
    function Max(const A, B: ISimdVector): ISimdVector;
  end;

  // 标量内存操作实现
  TScalarMemory = class(TInterfacedObject, ISimdMemory)
  public
    function Load(const Data: Pointer; Count: Integer): ISimdVector;
    function LoadAligned(const Data: Pointer; Count: Integer): ISimdVector;
    procedure Store(const Vector: ISimdVector; Data: Pointer);
    procedure StoreAligned(const Vector: ISimdVector; Data: Pointer);
    function Gather(const BaseAddr: Pointer; const Indices: array of Integer): ISimdVector;
    procedure Scatter(const Vector: ISimdVector; BaseAddr: Pointer; const Indices: array of Integer);
  end;

  // 标量转换操作实现
  TScalarConversion = class(TInterfacedObject, ISimdConversion)
  public
    function ConvertToFloat(const A: ISimdVector): ISimdVector;
    function ConvertToInt(const A: ISimdVector): ISimdVector;
    function ConvertToDouble(const A: ISimdVector): ISimdVector;
    function Pack(const A, B: ISimdVector): ISimdVector;
    function Unpack(const A: ISimdVector): ISimdVector;
    function Shuffle(const A: ISimdVector; const Mask: array of Integer): ISimdVector;
  end;

  // 标量后端工厂
  TScalarBackendFactory = class(TInterfacedObject, ISimdBackendFactory)
  public
    function GetBackend: TSimdBackend;
    function IsAvailable: Boolean;
    function CreateMath: ISimdMath;
    function CreateMemory: ISimdMemory;
    function CreateConversion: ISimdConversion;
    function GetCapabilities: TSimdCapabilitySet;
  end;

// 创建标量向量的便利函�?function CreateScalarVector(const Values: array of Single): ISimdVector;
function CreateScalarVectorF32x4(v0, v1, v2, v3: Single): ISimdVector;

implementation

uses
  SysUtils, Math;

// === TScalarVector 实现 ===

constructor TScalarVector.Create(ElementType: TSimdElementType; ElementCount: Integer);
begin
  inherited Create;
  FElementType := ElementType;
  FElementCount := ElementCount;
  SetLength(FData, ElementCount);
  FillChar(FData[0], ElementCount * SizeOf(Single), 0);
end;

constructor TScalarVector.CreateFromData(const Data: array of Single; ElementType: TSimdElementType);
var
  i: Integer;
begin
  inherited Create;
  FElementType := ElementType;
  FElementCount := Length(Data);
  SetLength(FData, FElementCount);
  for i := 0 to FElementCount - 1 do
    FData[i] := Data[i];
end;

function TScalarVector.GetSize: Integer;
begin
  Result := FElementCount * SizeOf(Single);
end;

function TScalarVector.GetElementCount: Integer;
begin
  Result := FElementCount;
end;

function TScalarVector.GetElementType: TSimdElementType;
begin
  Result := FElementType;
end;

function TScalarVector.GetBackend: TSimdBackend;
begin
  Result := sbScalar;
end;

function TScalarVector.GetElement(Index: Integer): Single;
begin
  if (Index < 0) or (Index >= FElementCount) then
    raise EArgumentOutOfRangeException.CreateFmt('Index %d out of range [0..%d]', [Index, FElementCount - 1]);
  Result := FData[Index];
end;

procedure TScalarVector.SetElement(Index: Integer; Value: Single);
begin
  if (Index < 0) or (Index >= FElementCount) then
    raise EArgumentOutOfRangeException.CreateFmt('Index %d out of range [0..%d]', [Index, FElementCount - 1]);
  FData[Index] := Value;
end;

function TScalarVector.GetDataPtr: PSingle;
begin
  if FElementCount > 0 then
    Result := @FData[0]
  else
    Result := nil;
end;

// === TScalarMath 实现 ===

function TScalarMath.Add(const A, B: ISimdVector): ISimdVector;
var
  scalarA, scalarB: TScalarVector;
  result: TScalarVector;
  i: Integer;
begin
  scalarA := A as TScalarVector;
  scalarB := B as TScalarVector;
  
  if scalarA.ElementCount <> scalarB.ElementCount then
    raise EArgumentException.Create('Vector element counts must match');
    
  result := TScalarVector.Create(scalarA.ElementType, scalarA.ElementCount);
  
  for i := 0 to scalarA.ElementCount - 1 do
    result[i] := scalarA[i] + scalarB[i];
    
  Result := result;
end;

function TScalarMath.Sub(const A, B: ISimdVector): ISimdVector;
var
  scalarA, scalarB: TScalarVector;
  result: TScalarVector;
  i: Integer;
begin
  scalarA := A as TScalarVector;
  scalarB := B as TScalarVector;
  
  if scalarA.ElementCount <> scalarB.ElementCount then
    raise EArgumentException.Create('Vector element counts must match');
    
  result := TScalarVector.Create(scalarA.ElementType, scalarA.ElementCount);
  
  for i := 0 to scalarA.ElementCount - 1 do
    result[i] := scalarA[i] - scalarB[i];
    
  Result := result;
end;

function TScalarMath.Mul(const A, B: ISimdVector): ISimdVector;
var
  scalarA, scalarB: TScalarVector;
  result: TScalarVector;
  i: Integer;
begin
  scalarA := A as TScalarVector;
  scalarB := B as TScalarVector;
  
  if scalarA.ElementCount <> scalarB.ElementCount then
    raise EArgumentException.Create('Vector element counts must match');
    
  result := TScalarVector.Create(scalarA.ElementType, scalarA.ElementCount);
  
  for i := 0 to scalarA.ElementCount - 1 do
    result[i] := scalarA[i] * scalarB[i];
    
  Result := result;
end;

function TScalarMath.Divide(const A, B: ISimdVector): ISimdVector;
var
  scalarA, scalarB: TScalarVector;
  result: TScalarVector;
  i: Integer;
begin
  scalarA := A as TScalarVector;
  scalarB := B as TScalarVector;
  
  if scalarA.ElementCount <> scalarB.ElementCount then
    raise EArgumentException.Create('Vector element counts must match');
    
  result := TScalarVector.Create(scalarA.ElementType, scalarA.ElementCount);
  
  for i := 0 to scalarA.ElementCount - 1 do
  begin
    if scalarB[i] = 0.0 then
      raise EDivByZero.Create('Division by zero');
    result[i] := scalarA[i] / scalarB[i];
  end;
    
  Result := result;
end;

function TScalarMath.Sqrt(const A: ISimdVector): ISimdVector;
var
  scalarA: TScalarVector;
  result: TScalarVector;
  i: Integer;
begin
  scalarA := A as TScalarVector;
  result := TScalarVector.Create(scalarA.ElementType, scalarA.ElementCount);
  
  for i := 0 to scalarA.ElementCount - 1 do
    result[i] := System.Sqrt(scalarA[i]);
    
  Result := result;
end;

function TScalarMath.Abs(const A: ISimdVector): ISimdVector;
var
  scalarA: TScalarVector;
  result: TScalarVector;
  i: Integer;
begin
  scalarA := A as TScalarVector;
  result := TScalarVector.Create(scalarA.ElementType, scalarA.ElementCount);
  
  for i := 0 to scalarA.ElementCount - 1 do
    result[i] := System.Abs(scalarA[i]);
    
  Result := result;
end;

function TScalarMath.Min(const A, B: ISimdVector): ISimdVector;
var
  scalarA, scalarB: TScalarVector;
  result: TScalarVector;
  i: Integer;
begin
  scalarA := A as TScalarVector;
  scalarB := B as TScalarVector;
  
  if scalarA.ElementCount <> scalarB.ElementCount then
    raise EArgumentException.Create('Vector element counts must match');
    
  result := TScalarVector.Create(scalarA.ElementType, scalarA.ElementCount);
  
  for i := 0 to scalarA.ElementCount - 1 do
    result[i] := Math.Min(scalarA[i], scalarB[i]);
    
  Result := result;
end;

function TScalarMath.Max(const A, B: ISimdVector): ISimdVector;
var
  scalarA, scalarB: TScalarVector;
  result: TScalarVector;
  i: Integer;
begin
  scalarA := A as TScalarVector;
  scalarB := B as TScalarVector;
  
  if scalarA.ElementCount <> scalarB.ElementCount then
    raise EArgumentException.Create('Vector element counts must match');
    
  result := TScalarVector.Create(scalarA.ElementType, scalarA.ElementCount);
  
  for i := 0 to scalarA.ElementCount - 1 do
    result[i] := Math.Max(scalarA[i], scalarB[i]);
    
  Result := result;
end;

// === TScalarMemory 实现 ===

function TScalarMemory.Load(const Data: Pointer; Count: Integer): ISimdVector;
var
  result: TScalarVector;
  src: PSingle;
  i: Integer;
begin
  if Data = nil then
    raise EArgumentNilException.Create('Data pointer cannot be nil');
    
  result := TScalarVector.Create(setFloat32, Count);
  src := PSingle(Data);
  
  for i := 0 to Count - 1 do
  begin
    result[i] := src^;
    Inc(src);
  end;
  
  Result := result;
end;

function TScalarMemory.LoadAligned(const Data: Pointer; Count: Integer): ISimdVector;
begin
  // 标量实现中，对齐和非对齐加载是相同的
  Result := Load(Data, Count);
end;

procedure TScalarMemory.Store(const Vector: ISimdVector; Data: Pointer);
var
  scalarVec: TScalarVector;
  dst: PSingle;
  i: Integer;
begin
  if Data = nil then
    raise EArgumentNilException.Create('Data pointer cannot be nil');
    
  scalarVec := Vector as TScalarVector;
  dst := PSingle(Data);
  
  for i := 0 to scalarVec.ElementCount - 1 do
  begin
    dst^ := scalarVec[i];
    Inc(dst);
  end;
end;

procedure TScalarMemory.StoreAligned(const Vector: ISimdVector; Data: Pointer);
begin
  // 标量实现中，对齐和非对齐存储是相同的
  Store(Vector, Data);
end;

function TScalarMemory.Gather(const BaseAddr: Pointer; const Indices: array of Integer): ISimdVector;
var
  result: TScalarVector;
  base: PSingle;
  i: Integer;
begin
  if BaseAddr = nil then
    raise EArgumentNilException.Create('BaseAddr cannot be nil');
    
  result := TScalarVector.Create(setFloat32, Length(Indices));
  base := PSingle(BaseAddr);
  
  for i := 0 to Length(Indices) - 1 do
    result[i] := PSingle(PByte(base) + Indices[i] * SizeOf(Single))^;
    
  Result := result;
end;

procedure TScalarMemory.Scatter(const Vector: ISimdVector; BaseAddr: Pointer; const Indices: array of Integer);
var
  scalarVec: TScalarVector;
  base: PSingle;
  i: Integer;
begin
  if BaseAddr = nil then
    raise EArgumentNilException.Create('BaseAddr cannot be nil');
    
  scalarVec := Vector as TScalarVector;
  base := PSingle(BaseAddr);
  
  for i := 0 to Min(scalarVec.ElementCount, Length(Indices)) - 1 do
    PSingle(PByte(base) + Indices[i] * SizeOf(Single))^ := scalarVec[i];
end;

// === TScalarConversion 实现 ===

function TScalarConversion.ConvertToFloat(const A: ISimdVector): ISimdVector;
var
  scalarA: TScalarVector;
  resultVec: TScalarVector;
  i: Integer;
begin
  // 标量实现中，已经是浮点数，直接返回副�?  scalarA := A as TScalarVector;
  resultVec := TScalarVector.Create(setFloat32, scalarA.ElementCount);

  for i := 0 to scalarA.ElementCount - 1 do
    resultVec[i] := scalarA[i];

  Result := resultVec;
end;

function TScalarConversion.ConvertToInt(const A: ISimdVector): ISimdVector;
var
  scalarA: TScalarVector;
  resultVec: TScalarVector;
  i: Integer;
begin
  scalarA := A as TScalarVector;
  resultVec := TScalarVector.Create(setInt32, scalarA.ElementCount);

  for i := 0 to scalarA.ElementCount - 1 do
    resultVec[i] := Trunc(scalarA[i]);

  Result := resultVec;
end;

function TScalarConversion.ConvertToDouble(const A: ISimdVector): ISimdVector;
var
  scalarA: TScalarVector;
  resultVec: TScalarVector;
  i: Integer;
begin
  scalarA := A as TScalarVector;
  resultVec := TScalarVector.Create(setFloat64, scalarA.ElementCount);

  for i := 0 to scalarA.ElementCount - 1 do
    resultVec[i] := scalarA[i];

  Result := resultVec;
end;

function TScalarConversion.Pack(const A, B: ISimdVector): ISimdVector;
var
  scalarA, scalarB: TScalarVector;
  resultVec: TScalarVector;
  i: Integer;
begin
  scalarA := A as TScalarVector;
  scalarB := B as TScalarVector;
  resultVec := TScalarVector.Create(scalarA.ElementType, scalarA.ElementCount + scalarB.ElementCount);

  for i := 0 to scalarA.ElementCount - 1 do
    resultVec[i] := scalarA[i];

  for i := 0 to scalarB.ElementCount - 1 do
    resultVec[scalarA.ElementCount + i] := scalarB[i];

  Result := resultVec;
end;

function TScalarConversion.Unpack(const A: ISimdVector): ISimdVector;
var
  scalarA: TScalarVector;
  resultVec: TScalarVector;
  halfCount: Integer;
  i: Integer;
begin
  // 简单实现：返回前半部分
  scalarA := A as TScalarVector;
  halfCount := scalarA.ElementCount div 2;
  resultVec := TScalarVector.Create(scalarA.ElementType, halfCount);

  for i := 0 to halfCount - 1 do
    resultVec[i] := scalarA[i];

  Result := resultVec;
end;

function TScalarConversion.Shuffle(const A: ISimdVector; const Mask: array of Integer): ISimdVector;
var
  scalarA: TScalarVector;
  resultVec: TScalarVector;
  i, index: Integer;
begin
  scalarA := A as TScalarVector;
  resultVec := TScalarVector.Create(scalarA.ElementType, Length(Mask));

  for i := 0 to Length(Mask) - 1 do
  begin
    index := Mask[i];
    if (index >= 0) and (index < scalarA.ElementCount) then
      resultVec[i] := scalarA[index]
    else
      resultVec[i] := 0.0;
  end;

  Result := resultVec;
end;

// === TScalarBackendFactory 实现 ===

function TScalarBackendFactory.GetBackend: TSimdBackend;
begin
  Result := sbScalar;
end;

function TScalarBackendFactory.IsAvailable: Boolean;
begin
  Result := True; // 标量后端总是可用
end;

function TScalarBackendFactory.CreateMath: ISimdMath;
begin
  Result := TScalarMath.Create;
end;

function TScalarBackendFactory.CreateMemory: ISimdMemory;
begin
  Result := TScalarMemory.Create;
end;

function TScalarBackendFactory.CreateConversion: ISimdConversion;
begin
  Result := TScalarConversion.Create;
end;

function TScalarBackendFactory.GetCapabilities: TSimdCapabilitySet;
begin
  Result := [scBasicArithmetic, scComparison, scMathFunctions, scLoadStore];
end;

// === 便利函数 ===

function CreateScalarVector(const Values: array of Single): ISimdVector;
begin
  Result := TScalarVector.CreateFromData(Values, setFloat32);
end;

function CreateScalarVectorF32x4(v0, v1, v2, v3: Single): ISimdVector;
begin
  Result := TScalarVector.CreateFromData([v0, v1, v2, v3], setFloat32);
end;

// === 自动注册 ===

initialization
  RegisterBackendFactory(sbScalar, TScalarBackendFactory.Create);

end.


