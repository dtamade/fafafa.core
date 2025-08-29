unit fafafa.core.simd.v2.types;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

// === 核心类型系统（简化版，兼容 FreePascal）===
// 设计原则：
// 1. 类型安全：编译时检查
// 2. 零开销抽象：内联优化
// 3. 统一接口：所有向量类型共享相同操作
// 4. 平台无关：在任何平台都能编译运行

type
  // === 指令集能力 ===
  TSimdISA = (
    isaScalar,
    // x86_64 指令集
    isaSSE2, isaSSE3, isaSSSE3, isaSSE41, isaSSE42,
    isaAVX, isaAVX2, 
    isaAVX512F, isaAVX512VL, isaAVX512BW, isaAVX512DQ,
    // ARM 指令集
    isaNEON, isaSVE, isaSVE2
  );

  TSimdISASet = set of TSimdISA;

  // === 错误处理 ===
  TSimdError = record
    Code: Integer;
    Message: String;
    ISA: TSimdISA;
  end;

  // === F32x4 向量类型 ===
  TF32x4 = record
  private
    FData: array[0..3] of Single;
  public
    // 构造函数
    class function Splat(const AValue: Single): TF32x4; static; inline;
    class function FromArray(const AArray: array of Single): TF32x4; static;
    class function Load(APtr: Pointer): TF32x4; static; inline;
    
    // 访问器
    function Extract(const AIndex: Integer): Single; inline;
    procedure Insert(const AIndex: Integer; const AValue: Single); inline;
    procedure Store(APtr: Pointer); inline;
    
    // 基础运算
    function Add(const AOther: TF32x4): TF32x4; inline;
    function Sub(const AOther: TF32x4): TF32x4; inline;
    function Mul(const AOther: TF32x4): TF32x4; inline;
    function Divide(const AOther: TF32x4): TF32x4; inline;
    
    // 聚合运算
    function ReduceAdd: Single; inline;
    function ReduceMin: Single; inline;
    function ReduceMax: Single; inline;
    
    // 向量操作
    function Reverse: TF32x4; inline;
    
    // 属性
    property Data[Index: Integer]: Single read Extract write Insert; default;
    class function Lanes: Integer; static; inline;
  end;

  // === F32x8 向量类型（暂时简化，只声明不实现）===
  TF32x8 = record
  private
    FData: array[0..7] of Single;
    function GetData(Index: Integer): Single; inline;
    procedure SetData(Index: Integer; const Value: Single); inline;
  public
    // 暂时只提供基础访问，完整实现将在后续添加
    property Data[Index: Integer]: Single read GetData write SetData; default;
  end;

  // === I32x4 向量类型 ===
  TI32x4 = record
  private
    FData: array[0..3] of Int32;
  public
    class function Splat(const AValue: Int32): TI32x4; static; inline;
    class function FromArray(const AArray: array of Int32): TI32x4; static;
    class function Load(APtr: Pointer): TI32x4; static; inline;
    
    function Extract(const AIndex: Integer): Int32; inline;
    procedure Insert(const AIndex: Integer; const AValue: Int32); inline;
    procedure Store(APtr: Pointer); inline;
    
    function Add(const AOther: TI32x4): TI32x4; inline;
    function Sub(const AOther: TI32x4): TI32x4; inline;
    function Mul(const AOther: TI32x4): TI32x4; inline;
    
    function ReduceAdd: Int32; inline;
    
    property Data[Index: Integer]: Int32 read Extract write Insert; default;
    class function Lanes: Integer; static; inline;
  end;

  // === I32x8 向量类型 ===
  TI32x8 = record
  private
    FData: array[0..7] of Int32;
    function GetData(Index: Integer): Int32; inline;
    procedure SetData(Index: Integer; const Value: Int32); inline;
  public
    class function Splat(const AValue: Int32): TI32x8; static; inline;
    class function FromArray(const AArray: array of Int32): TI32x8; static;
    class function Load(APtr: Pointer): TI32x8; static; inline;

    function Extract(const AIndex: Integer): Int32; inline;
    procedure Insert(const AIndex: Integer; const AValue: Int32); inline;
    procedure Store(APtr: Pointer); inline;

    function Add(const AOther: TI32x8): TI32x8; inline;
    function Sub(const AOther: TI32x8): TI32x8; inline;
    function Mul(const AOther: TI32x8): TI32x8; inline;

    function ReduceAdd: Int32; inline;

    property Data[Index: Integer]: Int32 read GetData write SetData; default;
    class function Lanes: Integer; static; inline;
  end;

  // === F64x2 向量类型（双精度浮点）===
  TF64x2 = record
  private
    FData: array[0..1] of Double;
    function GetData(Index: Integer): Double; inline;
    procedure SetData(Index: Integer; const Value: Double); inline;
  public
    class function Splat(const AValue: Double): TF64x2; static; inline;
    class function FromArray(const AArray: array of Double): TF64x2; static;
    class function Load(APtr: Pointer): TF64x2; static; inline;

    function Extract(const AIndex: Integer): Double; inline;
    procedure Insert(const AIndex: Integer; const AValue: Double); inline;
    procedure Store(APtr: Pointer); inline;

    function Add(const AOther: TF64x2): TF64x2; inline;
    function Sub(const AOther: TF64x2): TF64x2; inline;
    function Mul(const AOther: TF64x2): TF64x2; inline;
    function Divide(const AOther: TF64x2): TF64x2; inline;

    function Sqrt: TF64x2; inline;
    function MinVec(const AOther: TF64x2): TF64x2; inline;
    function MaxVec(const AOther: TF64x2): TF64x2; inline;

    function ReduceAdd: Double; inline;
    function ReduceMin: Double; inline;
    function ReduceMax: Double; inline;

    property Data[Index: Integer]: Double read GetData write SetData; default;
    class function Lanes: Integer; static; inline;
  end;

  // === F64x4 向量类型（AVX 双精度）===
  TF64x4 = record
  private
    FData: array[0..3] of Double;
    function GetData(Index: Integer): Double; inline;
    procedure SetData(Index: Integer; const Value: Double); inline;
  public
    class function Splat(const AValue: Double): TF64x4; static; inline;
    class function FromArray(const AArray: array of Double): TF64x4; static;
    class function Load(APtr: Pointer): TF64x4; static; inline;

    function Extract(const AIndex: Integer): Double; inline;
    procedure Insert(const AIndex: Integer; const AValue: Double); inline;
    procedure Store(APtr: Pointer); inline;

    function Add(const AOther: TF64x4): TF64x4; inline;
    function Sub(const AOther: TF64x4): TF64x4; inline;
    function Mul(const AOther: TF64x4): TF64x4; inline;
    function Divide(const AOther: TF64x4): TF64x4; inline;

    function Sqrt: TF64x4; inline;
    function ReduceAdd: Double; inline;

    property Data[Index: Integer]: Double read GetData write SetData; default;
    class function Lanes: Integer; static; inline;
  end;

  // === I8x16 向量类型（字节向量）===
  TI8x16 = record
  private
    FData: array[0..15] of Int8;
    function GetData(Index: Integer): Int8; inline;
    procedure SetData(Index: Integer; const Value: Int8); inline;
  public
    class function Splat(const AValue: Int8): TI8x16; static; inline;
    class function FromArray(const AArray: array of Int8): TI8x16; static;
    class function Load(APtr: Pointer): TI8x16; static; inline;

    function Extract(const AIndex: Integer): Int8; inline;
    procedure Insert(const AIndex: Integer; const AValue: Int8); inline;
    procedure Store(APtr: Pointer); inline;

    function Add(const AOther: TI8x16): TI8x16; inline;
    function Sub(const AOther: TI8x16): TI8x16; inline;

    function ReduceAdd: Int32; inline; // 返回更大类型避免溢出

    property Data[Index: Integer]: Int8 read GetData write SetData; default;
    class function Lanes: Integer; static; inline;
  end;

  // === I16x8 向量类型（短整数向量）===
  TI16x8 = record
  private
    FData: array[0..7] of Int16;
    function GetData(Index: Integer): Int16; inline;
    procedure SetData(Index: Integer; const Value: Int16); inline;
  public
    class function Splat(const AValue: Int16): TI16x8; static; inline;
    class function FromArray(const AArray: array of Int16): TI16x8; static;
    class function Load(APtr: Pointer): TI16x8; static; inline;

    function Extract(const AIndex: Integer): Int16; inline;
    procedure Insert(const AIndex: Integer; const AValue: Int16); inline;
    procedure Store(APtr: Pointer); inline;

    function Add(const AOther: TI16x8): TI16x8; inline;
    function Sub(const AOther: TI16x8): TI16x8; inline;
    function Mul(const AOther: TI16x8): TI16x8; inline;

    function ReduceAdd: Int32; inline; // 返回更大类型避免溢出

    property Data[Index: Integer]: Int16 read GetData write SetData; default;
    class function Lanes: Integer; static; inline;
  end;

  // === U32x4 向量类型（无符号整数）===
  TU32x4 = record
  private
    FData: array[0..3] of UInt32;
    function GetData(Index: Integer): UInt32; inline;
    procedure SetData(Index: Integer; const Value: UInt32); inline;
  public
    class function Splat(const AValue: UInt32): TU32x4; static; inline;
    class function FromArray(const AArray: array of UInt32): TU32x4; static;
    class function Load(APtr: Pointer): TU32x4; static; inline;

    function Extract(const AIndex: Integer): UInt32; inline;
    procedure Insert(const AIndex: Integer; const AValue: UInt32); inline;
    procedure Store(APtr: Pointer); inline;

    function Add(const AOther: TU32x4): TU32x4; inline;
    function Sub(const AOther: TU32x4): TU32x4; inline;
    function Mul(const AOther: TU32x4): TU32x4; inline;

    function ReduceAdd: UInt64; inline; // 返回更大类型避免溢出
    function ReduceMin: UInt32; inline;
    function ReduceMax: UInt32; inline;

    property Data[Index: Integer]: UInt32 read GetData write SetData; default;
    class function Lanes: Integer; static; inline;
  end;

  // === 掩码类型 ===
  TMaskF32x4 = record
  private
    FData: array[0..3] of Boolean;
    function GetData(Index: Integer): Boolean; inline;
    procedure SetData(Index: Integer; const Value: Boolean); inline;
  public
    class function All: TMaskF32x4; static; inline;
    class function None: TMaskF32x4; static; inline;

    function Any: Boolean; inline;
    function Count: Integer; inline;

    property Data[Index: Integer]: Boolean read GetData write SetData; default;
  end;

  TMaskF32x8 = record
  private
    FData: array[0..7] of Boolean;
    function GetData(Index: Integer): Boolean; inline;
    procedure SetData(Index: Integer; const Value: Boolean); inline;
  public
    class function All: TMaskF32x8; static; inline;
    class function None: TMaskF32x8; static; inline;

    function Any: Boolean; inline;
    function Count: Integer; inline;

    property Data[Index: Integer]: Boolean read GetData write SetData; default;
  end;

  // === 运行时上下文 ===
  TSimdContext = record
    Capabilities: TSimdISASet;
    ActiveISA: TSimdISA;
    DebugMode: Boolean;
    ProfileMode: Boolean;

    // 回退链
    FallbackChain: array[0..7] of TSimdISA;
  end;

// === 全局上下文 ===
var
  GSimdContext: TSimdContext;

// === 上下文管理函数 ===
function simd_init_context: TSimdContext;
procedure simd_set_context(const AContext: TSimdContext);
function simd_get_context: TSimdContext; inline;

implementation

// 简单的 Min/Max 函数实现
function Min(A, B: Single): Single; inline;
begin
  if A < B then Result := A else Result := B;
end;

function Min(A, B: Integer): Integer; inline;
begin
  if A < B then Result := A else Result := B;
end;

function SqrtDouble(A: Double): Double; inline;
begin
  // 改进的牛顿法平方根近似（双精度）
  if A <= 0 then
    Result := 0
  else
  begin
    Result := A * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5; // 额外迭代提高双精度精度
  end;
end;

// === TF32x4 实现 ===

class function TF32x4.Splat(const AValue: Single): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := AValue;
end;

class function TF32x4.FromArray(const AArray: array of Single): TF32x4;
var
  I: Integer;
begin
  for I := 0 to Min(3, High(AArray)) do
    Result.FData[I] := AArray[I];
  for I := High(AArray) + 1 to 3 do
    Result.FData[I] := 0.0;
end;

class function TF32x4.Load(APtr: Pointer): TF32x4;
var
  P: PSingle;
  I: Integer;
begin
  P := PSingle(APtr);
  for I := 0 to 3 do
    Result.FData[I] := P[I];
end;

function TF32x4.Extract(const AIndex: Integer): Single;
begin
  if (AIndex >= 0) and (AIndex <= 3) then
    Result := FData[AIndex]
  else
    Result := 0.0;
end;

procedure TF32x4.Insert(const AIndex: Integer; const AValue: Single);
begin
  if (AIndex >= 0) and (AIndex <= 3) then
    FData[AIndex] := AValue;
end;

procedure TF32x4.Store(APtr: Pointer);
var
  P: PSingle;
  I: Integer;
begin
  P := PSingle(APtr);
  for I := 0 to 3 do
    P[I] := FData[I];
end;

function TF32x4.Add(const AOther: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := FData[I] + AOther.FData[I];
end;

function TF32x4.Sub(const AOther: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := FData[I] - AOther.FData[I];
end;

function TF32x4.Mul(const AOther: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := FData[I] * AOther.FData[I];
end;

function TF32x4.Divide(const AOther: TF32x4): TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := FData[I] / AOther.FData[I];
end;

function TF32x4.ReduceAdd: Single;
var
  I: Integer;
begin
  Result := 0.0;
  for I := 0 to 3 do
    Result := Result + FData[I];
end;

function TF32x4.ReduceMin: Single;
var
  I: Integer;
begin
  Result := FData[0];
  for I := 1 to 3 do
    if FData[I] < Result then
      Result := FData[I];
end;

function TF32x4.ReduceMax: Single;
var
  I: Integer;
begin
  Result := FData[0];
  for I := 1 to 3 do
    if FData[I] > Result then
      Result := FData[I];
end;

function TF32x4.Reverse: TF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := FData[3 - I];
end;

class function TF32x4.Lanes: Integer;
begin
  Result := 4;
end;

// === TI32x4 实现 ===

class function TI32x4.Splat(const AValue: Int32): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := AValue;
end;

class function TI32x4.FromArray(const AArray: array of Int32): TI32x4;
var
  I: Integer;
begin
  for I := 0 to Min(3, High(AArray)) do
    Result.FData[I] := AArray[I];
  for I := High(AArray) + 1 to 3 do
    Result.FData[I] := 0;
end;

class function TI32x4.Load(APtr: Pointer): TI32x4;
var
  P: PInt32;
  I: Integer;
begin
  P := PInt32(APtr);
  for I := 0 to 3 do
    Result.FData[I] := P[I];
end;

function TI32x4.Extract(const AIndex: Integer): Int32;
begin
  if (AIndex >= 0) and (AIndex <= 3) then
    Result := FData[AIndex]
  else
    Result := 0;
end;

procedure TI32x4.Insert(const AIndex: Integer; const AValue: Int32);
begin
  if (AIndex >= 0) and (AIndex <= 3) then
    FData[AIndex] := AValue;
end;

procedure TI32x4.Store(APtr: Pointer);
var
  P: PInt32;
  I: Integer;
begin
  P := PInt32(APtr);
  for I := 0 to 3 do
    P[I] := FData[I];
end;

function TI32x4.Add(const AOther: TI32x4): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := FData[I] + AOther.FData[I];
end;

function TI32x4.Sub(const AOther: TI32x4): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := FData[I] - AOther.FData[I];
end;

function TI32x4.Mul(const AOther: TI32x4): TI32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := FData[I] * AOther.FData[I];
end;

function TI32x4.ReduceAdd: Int32;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to 3 do
    Result := Result + FData[I];
end;

class function TI32x4.Lanes: Integer;
begin
  Result := 4;
end;

// === TI32x8 实现 ===

function TI32x8.GetData(Index: Integer): Int32;
begin
  if (Index >= 0) and (Index <= 7) then
    Result := FData[Index]
  else
    Result := 0;
end;

procedure TI32x8.SetData(Index: Integer; const Value: Int32);
begin
  if (Index >= 0) and (Index <= 7) then
    FData[Index] := Value;
end;

class function TI32x8.Splat(const AValue: Int32): TI32x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.FData[I] := AValue;
end;

class function TI32x8.FromArray(const AArray: array of Int32): TI32x8;
var
  I: Integer;
begin
  for I := 0 to Min(7, High(AArray)) do
    Result.FData[I] := AArray[I];
  for I := High(AArray) + 1 to 7 do
    Result.FData[I] := 0;
end;

class function TI32x8.Load(APtr: Pointer): TI32x8;
var
  P: PInt32;
  I: Integer;
begin
  P := PInt32(APtr);
  for I := 0 to 7 do
    Result.FData[I] := P[I];
end;

function TI32x8.Extract(const AIndex: Integer): Int32;
begin
  if (AIndex >= 0) and (AIndex <= 7) then
    Result := FData[AIndex]
  else
    Result := 0;
end;

procedure TI32x8.Insert(const AIndex: Integer; const AValue: Int32);
begin
  if (AIndex >= 0) and (AIndex <= 7) then
    FData[AIndex] := AValue;
end;

procedure TI32x8.Store(APtr: Pointer);
var
  P: PInt32;
  I: Integer;
begin
  P := PInt32(APtr);
  for I := 0 to 7 do
    P[I] := FData[I];
end;

function TI32x8.Add(const AOther: TI32x8): TI32x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.FData[I] := FData[I] + AOther.FData[I];
end;

function TI32x8.Sub(const AOther: TI32x8): TI32x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.FData[I] := FData[I] - AOther.FData[I];
end;

function TI32x8.Mul(const AOther: TI32x8): TI32x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.FData[I] := FData[I] * AOther.FData[I];
end;

function TI32x8.ReduceAdd: Int32;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to 7 do
    Result := Result + FData[I];
end;

class function TI32x8.Lanes: Integer;
begin
  Result := 8;
end;

// === TF64x2 实现 ===

function TF64x2.GetData(Index: Integer): Double;
begin
  if (Index >= 0) and (Index <= 1) then
    Result := FData[Index]
  else
    Result := 0.0;
end;

procedure TF64x2.SetData(Index: Integer; const Value: Double);
begin
  if (Index >= 0) and (Index <= 1) then
    FData[Index] := Value;
end;

class function TF64x2.Splat(const AValue: Double): TF64x2;
var
  I: Integer;
begin
  for I := 0 to 1 do
    Result.FData[I] := AValue;
end;

class function TF64x2.FromArray(const AArray: array of Double): TF64x2;
var
  I: Integer;
begin
  for I := 0 to Min(1, High(AArray)) do
    Result.FData[I] := AArray[I];
  for I := High(AArray) + 1 to 1 do
    Result.FData[I] := 0.0;
end;

class function TF64x2.Load(APtr: Pointer): TF64x2;
var
  P: PDouble;
  I: Integer;
begin
  P := PDouble(APtr);
  for I := 0 to 1 do
    Result.FData[I] := P[I];
end;

function TF64x2.Extract(const AIndex: Integer): Double;
begin
  if (AIndex >= 0) and (AIndex <= 1) then
    Result := FData[AIndex]
  else
    Result := 0.0;
end;

procedure TF64x2.Insert(const AIndex: Integer; const AValue: Double);
begin
  if (AIndex >= 0) and (AIndex <= 1) then
    FData[AIndex] := AValue;
end;

procedure TF64x2.Store(APtr: Pointer);
var
  P: PDouble;
  I: Integer;
begin
  P := PDouble(APtr);
  for I := 0 to 1 do
    P[I] := FData[I];
end;

function TF64x2.Add(const AOther: TF64x2): TF64x2;
var
  I: Integer;
begin
  for I := 0 to 1 do
    Result.FData[I] := FData[I] + AOther.FData[I];
end;

function TF64x2.Sub(const AOther: TF64x2): TF64x2;
var
  I: Integer;
begin
  for I := 0 to 1 do
    Result.FData[I] := FData[I] - AOther.FData[I];
end;

function TF64x2.Mul(const AOther: TF64x2): TF64x2;
var
  I: Integer;
begin
  for I := 0 to 1 do
    Result.FData[I] := FData[I] * AOther.FData[I];
end;

function TF64x2.Divide(const AOther: TF64x2): TF64x2;
var
  I: Integer;
begin
  for I := 0 to 1 do
    Result.FData[I] := FData[I] / AOther.FData[I];
end;

function TF64x2.Sqrt: TF64x2;
var
  I: Integer;
begin
  for I := 0 to 1 do
    Result.FData[I] := SqrtDouble(FData[I]);
end;

function TF64x2.MinVec(const AOther: TF64x2): TF64x2;
var
  I: Integer;
begin
  for I := 0 to 1 do
    if FData[I] < AOther.FData[I] then
      Result.FData[I] := FData[I]
    else
      Result.FData[I] := AOther.FData[I];
end;

function TF64x2.MaxVec(const AOther: TF64x2): TF64x2;
var
  I: Integer;
begin
  for I := 0 to 1 do
    if FData[I] > AOther.FData[I] then
      Result.FData[I] := FData[I]
    else
      Result.FData[I] := AOther.FData[I];
end;

function TF64x2.ReduceAdd: Double;
var
  I: Integer;
begin
  Result := 0.0;
  for I := 0 to 1 do
    Result := Result + FData[I];
end;

function TF64x2.ReduceMin: Double;
var
  I: Integer;
begin
  Result := FData[0];
  for I := 1 to 1 do
    if FData[I] < Result then
      Result := FData[I];
end;

function TF64x2.ReduceMax: Double;
var
  I: Integer;
begin
  Result := FData[0];
  for I := 1 to 1 do
    if FData[I] > Result then
      Result := FData[I];
end;

class function TF64x2.Lanes: Integer;
begin
  Result := 2;
end;

// === TF64x4 实现 ===

function TF64x4.GetData(Index: Integer): Double;
begin
  if (Index >= 0) and (Index <= 3) then
    Result := FData[Index]
  else
    Result := 0.0;
end;

procedure TF64x4.SetData(Index: Integer; const Value: Double);
begin
  if (Index >= 0) and (Index <= 3) then
    FData[Index] := Value;
end;

class function TF64x4.Splat(const AValue: Double): TF64x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := AValue;
end;

class function TF64x4.FromArray(const AArray: array of Double): TF64x4;
var
  I: Integer;
begin
  for I := 0 to Min(3, High(AArray)) do
    Result.FData[I] := AArray[I];
  for I := High(AArray) + 1 to 3 do
    Result.FData[I] := 0.0;
end;

class function TF64x4.Load(APtr: Pointer): TF64x4;
var
  P: PDouble;
  I: Integer;
begin
  P := PDouble(APtr);
  for I := 0 to 3 do
    Result.FData[I] := P[I];
end;

function TF64x4.Extract(const AIndex: Integer): Double;
begin
  if (AIndex >= 0) and (AIndex <= 3) then
    Result := FData[AIndex]
  else
    Result := 0.0;
end;

procedure TF64x4.Insert(const AIndex: Integer; const AValue: Double);
begin
  if (AIndex >= 0) and (AIndex <= 3) then
    FData[AIndex] := AValue;
end;

procedure TF64x4.Store(APtr: Pointer);
var
  P: PDouble;
  I: Integer;
begin
  P := PDouble(APtr);
  for I := 0 to 3 do
    P[I] := FData[I];
end;

function TF64x4.Add(const AOther: TF64x4): TF64x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := FData[I] + AOther.FData[I];
end;

function TF64x4.Sub(const AOther: TF64x4): TF64x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := FData[I] - AOther.FData[I];
end;

function TF64x4.Mul(const AOther: TF64x4): TF64x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := FData[I] * AOther.FData[I];
end;

function TF64x4.Divide(const AOther: TF64x4): TF64x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := FData[I] / AOther.FData[I];
end;

function TF64x4.Sqrt: TF64x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := SqrtDouble(FData[I]);
end;

function TF64x4.ReduceAdd: Double;
var
  I: Integer;
begin
  Result := 0.0;
  for I := 0 to 3 do
    Result := Result + FData[I];
end;

class function TF64x4.Lanes: Integer;
begin
  Result := 4;
end;

// === TI8x16 实现 ===

function TI8x16.GetData(Index: Integer): Int8;
begin
  if (Index >= 0) and (Index <= 15) then
    Result := FData[Index]
  else
    Result := 0;
end;

procedure TI8x16.SetData(Index: Integer; const Value: Int8);
begin
  if (Index >= 0) and (Index <= 15) then
    FData[Index] := Value;
end;

class function TI8x16.Splat(const AValue: Int8): TI8x16;
var
  I: Integer;
begin
  for I := 0 to 15 do
    Result.FData[I] := AValue;
end;

class function TI8x16.FromArray(const AArray: array of Int8): TI8x16;
var
  I: Integer;
begin
  for I := 0 to Min(15, High(AArray)) do
    Result.FData[I] := AArray[I];
  for I := High(AArray) + 1 to 15 do
    Result.FData[I] := 0;
end;

class function TI8x16.Load(APtr: Pointer): TI8x16;
var
  P: PInt8;
  I: Integer;
begin
  P := PInt8(APtr);
  for I := 0 to 15 do
    Result.FData[I] := P[I];
end;

function TI8x16.Extract(const AIndex: Integer): Int8;
begin
  if (AIndex >= 0) and (AIndex <= 15) then
    Result := FData[AIndex]
  else
    Result := 0;
end;

procedure TI8x16.Insert(const AIndex: Integer; const AValue: Int8);
begin
  if (AIndex >= 0) and (AIndex <= 15) then
    FData[AIndex] := AValue;
end;

procedure TI8x16.Store(APtr: Pointer);
var
  P: PInt8;
  I: Integer;
begin
  P := PInt8(APtr);
  for I := 0 to 15 do
    P[I] := FData[I];
end;

function TI8x16.Add(const AOther: TI8x16): TI8x16;
var
  I: Integer;
begin
  for I := 0 to 15 do
    Result.FData[I] := FData[I] + AOther.FData[I];
end;

function TI8x16.Sub(const AOther: TI8x16): TI8x16;
var
  I: Integer;
begin
  for I := 0 to 15 do
    Result.FData[I] := FData[I] - AOther.FData[I];
end;

function TI8x16.ReduceAdd: Int32;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to 15 do
    Result := Result + FData[I];
end;

class function TI8x16.Lanes: Integer;
begin
  Result := 16;
end;

// === TI16x8 实现 ===

function TI16x8.GetData(Index: Integer): Int16;
begin
  if (Index >= 0) and (Index <= 7) then
    Result := FData[Index]
  else
    Result := 0;
end;

procedure TI16x8.SetData(Index: Integer; const Value: Int16);
begin
  if (Index >= 0) and (Index <= 7) then
    FData[Index] := Value;
end;

class function TI16x8.Splat(const AValue: Int16): TI16x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.FData[I] := AValue;
end;

class function TI16x8.FromArray(const AArray: array of Int16): TI16x8;
var
  I: Integer;
begin
  for I := 0 to Min(7, High(AArray)) do
    Result.FData[I] := AArray[I];
  for I := High(AArray) + 1 to 7 do
    Result.FData[I] := 0;
end;

class function TI16x8.Load(APtr: Pointer): TI16x8;
var
  P: PInt16;
  I: Integer;
begin
  P := PInt16(APtr);
  for I := 0 to 7 do
    Result.FData[I] := P[I];
end;

function TI16x8.Extract(const AIndex: Integer): Int16;
begin
  if (AIndex >= 0) and (AIndex <= 7) then
    Result := FData[AIndex]
  else
    Result := 0;
end;

procedure TI16x8.Insert(const AIndex: Integer; const AValue: Int16);
begin
  if (AIndex >= 0) and (AIndex <= 7) then
    FData[AIndex] := AValue;
end;

procedure TI16x8.Store(APtr: Pointer);
var
  P: PInt16;
  I: Integer;
begin
  P := PInt16(APtr);
  for I := 0 to 7 do
    P[I] := FData[I];
end;

function TI16x8.Add(const AOther: TI16x8): TI16x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.FData[I] := FData[I] + AOther.FData[I];
end;

function TI16x8.Sub(const AOther: TI16x8): TI16x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.FData[I] := FData[I] - AOther.FData[I];
end;

function TI16x8.Mul(const AOther: TI16x8): TI16x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.FData[I] := FData[I] * AOther.FData[I];
end;

function TI16x8.ReduceAdd: Int32;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to 7 do
    Result := Result + FData[I];
end;

class function TI16x8.Lanes: Integer;
begin
  Result := 8;
end;

// === TU32x4 实现 ===

function TU32x4.GetData(Index: Integer): UInt32;
begin
  if (Index >= 0) and (Index <= 3) then
    Result := FData[Index]
  else
    Result := 0;
end;

procedure TU32x4.SetData(Index: Integer; const Value: UInt32);
begin
  if (Index >= 0) and (Index <= 3) then
    FData[Index] := Value;
end;

class function TU32x4.Splat(const AValue: UInt32): TU32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := AValue;
end;

class function TU32x4.FromArray(const AArray: array of UInt32): TU32x4;
var
  I: Integer;
begin
  for I := 0 to Min(3, High(AArray)) do
    Result.FData[I] := AArray[I];
  for I := High(AArray) + 1 to 3 do
    Result.FData[I] := 0;
end;

class function TU32x4.Load(APtr: Pointer): TU32x4;
var
  P: PUInt32;
  I: Integer;
begin
  P := PUInt32(APtr);
  for I := 0 to 3 do
    Result.FData[I] := P[I];
end;

function TU32x4.Extract(const AIndex: Integer): UInt32;
begin
  if (AIndex >= 0) and (AIndex <= 3) then
    Result := FData[AIndex]
  else
    Result := 0;
end;

procedure TU32x4.Insert(const AIndex: Integer; const AValue: UInt32);
begin
  if (AIndex >= 0) and (AIndex <= 3) then
    FData[AIndex] := AValue;
end;

procedure TU32x4.Store(APtr: Pointer);
var
  P: PUInt32;
  I: Integer;
begin
  P := PUInt32(APtr);
  for I := 0 to 3 do
    P[I] := FData[I];
end;

function TU32x4.Add(const AOther: TU32x4): TU32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := FData[I] + AOther.FData[I];
end;

function TU32x4.Sub(const AOther: TU32x4): TU32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := FData[I] - AOther.FData[I];
end;

function TU32x4.Mul(const AOther: TU32x4): TU32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := FData[I] * AOther.FData[I];
end;

function TU32x4.ReduceAdd: UInt64;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to 3 do
    Result := Result + FData[I];
end;

function TU32x4.ReduceMin: UInt32;
var
  I: Integer;
begin
  Result := FData[0];
  for I := 1 to 3 do
    if FData[I] < Result then
      Result := FData[I];
end;

function TU32x4.ReduceMax: UInt32;
var
  I: Integer;
begin
  Result := FData[0];
  for I := 1 to 3 do
    if FData[I] > Result then
      Result := FData[I];
end;

class function TU32x4.Lanes: Integer;
begin
  Result := 4;
end;

// === TF32x8 实现 ===

function TF32x8.GetData(Index: Integer): Single;
begin
  if (Index >= 0) and (Index <= 7) then
    Result := FData[Index]
  else
    Result := 0.0;
end;

procedure TF32x8.SetData(Index: Integer; const Value: Single);
begin
  if (Index >= 0) and (Index <= 7) then
    FData[Index] := Value;
end;

// === TMaskF32x4 实现 ===

function TMaskF32x4.GetData(Index: Integer): Boolean;
begin
  if (Index >= 0) and (Index <= 3) then
    Result := FData[Index]
  else
    Result := False;
end;

procedure TMaskF32x4.SetData(Index: Integer; const Value: Boolean);
begin
  if (Index >= 0) and (Index <= 3) then
    FData[Index] := Value;
end;

class function TMaskF32x4.All: TMaskF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := True;
end;

class function TMaskF32x4.None: TMaskF32x4;
var
  I: Integer;
begin
  for I := 0 to 3 do
    Result.FData[I] := False;
end;

function TMaskF32x4.Any: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to 3 do
    if FData[I] then
    begin
      Result := True;
      Exit;
    end;
end;

function TMaskF32x4.Count: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to 3 do
    if FData[I] then
      Inc(Result);
end;

// === TMaskF32x8 实现 ===

function TMaskF32x8.GetData(Index: Integer): Boolean;
begin
  if (Index >= 0) and (Index <= 7) then
    Result := FData[Index]
  else
    Result := False;
end;

procedure TMaskF32x8.SetData(Index: Integer; const Value: Boolean);
begin
  if (Index >= 0) and (Index <= 7) then
    FData[Index] := Value;
end;

class function TMaskF32x8.All: TMaskF32x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.FData[I] := True;
end;

class function TMaskF32x8.None: TMaskF32x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.FData[I] := False;
end;

function TMaskF32x8.Any: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to 7 do
    if FData[I] then
    begin
      Result := True;
      Exit;
    end;
end;

function TMaskF32x8.Count: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to 7 do
    if FData[I] then
      Inc(Result);
end;

// === 上下文管理实现 ===

function simd_init_context: TSimdContext;
begin
  Result.Capabilities := [isaScalar];
  Result.ActiveISA := isaScalar;
  Result.DebugMode := False;
  Result.ProfileMode := False;

  // 初始化回退链（从最优到最差）
  Result.FallbackChain[0] := isaAVX512F;
  Result.FallbackChain[1] := isaAVX2;
  Result.FallbackChain[2] := isaAVX;
  Result.FallbackChain[3] := isaSSE42;
  Result.FallbackChain[4] := isaSSE41;
  Result.FallbackChain[5] := isaSSE2;
  Result.FallbackChain[6] := isaNEON;
  Result.FallbackChain[7] := isaScalar;
end;

procedure simd_set_context(const AContext: TSimdContext);
begin
  GSimdContext := AContext;
end;

function simd_get_context: TSimdContext;
begin
  Result := GSimdContext;
end;

// === 模块初始化 ===
initialization
  GSimdContext := simd_init_context;

end.
